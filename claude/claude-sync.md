# claude-sync

Render script that turns MCP configuration templates into the real configs Claude Desktop and Claude Code read at launch, with secret substitution from `.env`. Also bootstraps any missing runtime prerequisites so a freshly provisioned Mac is usable after one invocation.

## Overview

| Property | Value |
|----------|-------|
| Location | `~/claude-config/claude-sync` (executable shell script) |
| Aliased to | `claude-sync` via `~/.zshrc` (`alias claude-sync='~/claude-config/claude-sync'`) |
| Repo | [alex/claude-config](http://10.0.0.181:3000/anon/claude-config) on Forgejo |
| Idempotent? | Yes — re-running with everything installed is a no-op on the bootstrap step |
| Status | ✅ Active |

## What it does

On every run, in order:

1. `git pull --quiet` the repo, re-exec itself if the pull updated the script
2. Source `.env` for token values
3. Install missing runtime prerequisites (jq, node, uv, go, docker) via Homebrew
4. Install MCPs not covered by Homebrew (forgejo-mcp from source, ProxmoxMCP-Plus in a venv)
5. Resolve absolute paths for commands referenced in templates
6. Run a template sanity check — every MCP's `command` must be resolvable
7. Check network reachability for MCP endpoints that require Tailscale
8. Render templates and write them into place:
   - `~/Library/Application Support/Claude/claude_desktop_config.json` (Desktop — merges the `mcpServers` block, preserving preferences)
   - `~/.claude/settings.json` (Claude Code — full overwrite, template contains only `mcpServers`)
   - `~/.local/share/ProxmoxMCP-Plus/proxmox-config/config.json` (chmod 600, rendered from `proxmox-config.template.json`)
9. Symlink skills in `~/claude-config/.claude/skills/` into `~/.claude/skills/` so they're available globally

After a successful run it prints `Done. Cmd+Q Claude Desktop and reopen for changes to take effect.`

## Bootstrap patterns

`claude-sync` covers five install styles. Each is wrapped in a `command -v` or file-existence check so re-running is safe.

### Homebrew runtimes

```bash
ensure_brew() {
  local pkg="$1" test_cmd="${2:-$1}"
  if command -v "$test_cmd" >/dev/null 2>&1; then
    # already present — skip
  else
    brew install "$pkg"
  fi
}

ensure_brew jq
ensure_brew node npx
ensure_brew uv uvx
ensure_brew go
ensure_brew docker
```

These five runtimes cover the vast majority of MCP install patterns: `npx` (Node packages), `uvx` (Python packages via uv), `docker run` (containerized MCPs), and `jq` for the sync script itself.

### Source install via `go install`

```bash
if command -v forgejo-mcp >/dev/null 2>&1 || [ -x "$GO_BIN/forgejo-mcp" ]; then
  # already present — skip
else
  tmp=$(mktemp -d)
  git clone --quiet https://codeberg.org/goern/forgejo-mcp.git "$tmp"
  (cd "$tmp" && go install .)
  rm -rf "$tmp"
fi
```

Used for the `forgejo-mcp` binary. Installs to `$(go env GOPATH)/bin/`, typically `~/go/bin/`.

### Python venv install from source

```bash
PROXMOXMCP_DIR="$HOME/.local/share/ProxmoxMCP-Plus"
PROXMOXMCP_PYTHON="$PROXMOXMCP_DIR/.venv/bin/python"
if [ -x "$PROXMOXMCP_PYTHON" ]; then
  # already present — skip
else
  git clone --quiet https://github.com/RekklesNA/ProxmoxMCP-Plus.git "$PROXMOXMCP_DIR"
  (cd "$PROXMOXMCP_DIR" && uv venv --quiet && uv pip install -e . --quiet)
fi
```

Used for ProxmoxMCP-Plus — the MCP is a Python package that needs its dependencies installed in an isolated environment. The rendered config points at `.venv/bin/python` directly (no PATH fallback — system Python doesn't have the package).

### Template rendering

All rendered configs go through `render()`, a single `sed` pipeline that substitutes placeholders:

```bash
render() {
  sed \
    -e "s|__HOME__|$HOME|g" \
    -e "s|__UVX__|$UVX_PATH|g" \
    -e "s|__FORGEJO_MCP__|$FORGEJO_MCP_PATH|g" \
    -e "s|__PROXMOXMCP_PYTHON__|$PROXMOXMCP_PYTHON_PATH|g" \
    -e "s|__HOMEASSISTANT_TOKEN__|$HOMEASSISTANT_TOKEN|g" \
    -e "s|__FORGEJO_ACCESS_TOKEN__|$FORGEJO_ACCESS_TOKEN|g" \
    -e "s|__PROXMOX_TOKEN__|$PROXMOX_TOKEN|g" \
    "$1"
}
```

Path placeholders (`__UVX__`, `__FORGEJO_MCP__`, `__PROXMOXMCP_PYTHON__`) exist because Claude Desktop's GUI launch PATH doesn't always include Homebrew or `~/go/bin`, so bare command names can fail at runtime. `resolve_cmd()` picks a known install path first, falls back to `command -v`, and aborts with a diagnostic if both fail.

### Config-template rendering (for MCPs that need a secondary config file)

Most MCPs get everything from `command`, `args`, and `env`. A few (ProxmoxMCP-Plus being the reference case) need a standalone JSON or YAML config file on disk referenced by an env var. For those, `claude-sync` renders an additional template alongside the MCP configs:

```bash
PROXMOXMCP_CFG="$PROXMOXMCP_DIR/proxmox-config/config.json"
if [ -d "$PROXMOXMCP_DIR" ]; then
  mkdir -p "$(dirname "$PROXMOXMCP_CFG")"
  render "$REPO_DIR/proxmox-config.template.json" > "$PROXMOXMCP_CFG"
  chmod 600 "$PROXMOXMCP_CFG"
fi
```

`chmod 600` is important — this file contains the Proxmox API token.

## Sanity check

After rendering resolves, the script walks both templates with `jq`, expands placeholders the same way `render()` does, and verifies every MCP `command` either exists as an absolute path or resolves via `command -v`:

```
==> Running template sanity check...
  Home Assistant: `__UVX__` → /opt/homebrew/bin/uvx (ok)
  forgejo: `__FORGEJO_MCP__` → /Users/alex-m4mini/go/bin/forgejo-mcp (ok)
  proxmox: `__PROXMOXMCP_PYTHON__` → /Users/alex-m4mini/.local/share/ProxmoxMCP-Plus/.venv/bin/python (ok)
```

Reads templates only — never touches rendered configs, so no secret exposure in sanity-check output. Missing commands get flagged at the end of the run with a hint pointing at which MCP needs an install step added.

## `--audit` flag

```bash
claude-sync --audit
```

Reports drift between rendered configs and templates — any MCP present in one but not the other. Reads `.mcpServers | keys` only, so no secret exposure. Useful after someone adds an MCP via Claude Desktop's "Edit Config" UI or `claude mcp add` — both write to rendered configs that `claude-sync` will overwrite, and the audit catches them before the next sync.

## add-mcp skill

`~/claude-config/.claude/skills/add-mcp/SKILL.md` walks Claude through adding a new MCP without exposing `.env`. `claude-sync` symlinks it into `~/.claude/skills/` so it's available globally on each machine.

The skill's 5-step flow:

1. **Gather** — MCP name, source (npm package / repo URL / docker image / PyPI package / absolute path), docs URL. Fetches the source's README to extract the exact `command`, `args`, and env-variable names.
2. **Edit both templates** — identical entries in `desktop.template.json` and `code.template.json`. Decision tree for install style (npx/uvx/docker/python-system → no work needed; Python venv from source → venv binary + bootstrap branch; standalone binary → `__FOO_MCP__` placeholder + bootstrap branch).
3. **Update `.env.example` and README** — placeholder lines for new env vars, new row in the Active MCPs table.
4. **Never touch `.env`** — the deny rules prevent it. Hand off clearly with a message listing exactly which variables the user needs to add.
5. **Optional verification** — suggest `./claude-sync --audit` after the user runs the sync.

### Patches applied 2026-04-23

- **Python-venv install pattern added** — the decision tree previously only covered system Python. The new row directs Claude to treat a venv's `.venv/bin/python` as the binary: add a `__FOO_PYTHON__` placeholder, a `resolve_cmd` call, a sed line in `render()`, and an install step (`git clone` → `uv venv` → `uv pip install -e .`).
- **Config-file-vs-env-var guidance** — when an MCP supports both, prefer env vars (they slot into the existing `env` block and `render()` flow). Only fall back to a secondary config template if env vars aren't available. Cross-references `proxmox-config.template.json` as the reference implementation.

## Troubleshooting

**"Missing .env" error.** The `.env` file isn't present. Check that it got committed and pushed. The file is intentionally tracked in git (LAN-only repo); if it's missing, restore it from the other machine's clone.

**MCPs don't show up after sync.** Fully quit Claude Desktop (Cmd+Q, not just close window) and reopen — it only reads the config at launch.

**`forgejo` MCP shows "no route to host" or "Server disconnected".** The MCP points at `http://forgejo:3000/`, which requires Tailscale running (MagicDNS). `claude-sync` prints a Tailscale-specific warning when the endpoint can't be reached during the reachability check. Start Tailscale, then quit and reopen Claude Desktop.

**`jq` error on first run.** Means the Claude Desktop config doesn't exist yet and the fallback branch didn't catch it. Check `~/Library/Application Support/Claude/claude_desktop_config.json` exists; if not, launch Claude Desktop once to create it, then re-run sync.

**`proxmox` MCP fails with "config file not found".** `claude-sync` only renders `proxmox-config.template.json` if `~/.local/share/ProxmoxMCP-Plus/` exists. If the earlier clone + venv build failed you'll see a yellow "skipped" line in the sync output. Fix the install first (usually `rm -rf ~/.local/share/ProxmoxMCP-Plus` and re-run), then the config render works.

**Git pull fails when away from home.** Expected — Forgejo is LAN-only. Connect via Tailscale. If the git remote still uses the LAN IP, update it to the MagicDNS name: `git -C ~/claude-config remote set-url origin http://forgejo:3000/anon/claude-config`.

## Related

- [Claude Tooling](claude-setup.md) — high-level overview
- [MCP Servers](mcp-servers.md) — per-MCP details
- [Forgejo](../services/forgejo.md) — where `claude-config` is hosted
