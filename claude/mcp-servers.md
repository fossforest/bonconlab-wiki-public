# MCP Servers

Reference for every Model Context Protocol server configured across Claude Desktop and Claude Code. Both clients use identical MCP lists, synced from [claude-config](http://10.0.0.181:3000/anon/claude-config) by [claude-sync](claude-sync.md).

## Overview

| MCP | Purpose | Install pattern | Transport | Token required |
|-----|---------|-----------------|-----------|----------------|
| Home Assistant | Query and control HA entities, call services, inspect history | `uvx` | stdio | Yes — HA long-lived access token |
| forgejo | Interact with Forgejo repos — issues, PRs, files, commits | `go install` from source | stdio | Yes — Forgejo API token |
| irs-taxpayer | US tax-code reference queries | `npx` | stdio | No |
| proxmox | Read and act on the Proxmox cluster — audit everything, power-cycle/snapshot/backup VMs and LXCs | Python venv, source install | stdio | Yes — Proxmox API token (`mcp@pve!mcp-claude`) |

All runtimes (`uvx`, `node`/`npx`, `go`, Python via the venv) are auto-installed by `claude-sync`; no manual prerequisites on a fresh Mac.

## home-assistant

Queries HA entities, calls services, inspects history, and drives entity/area/automation changes.

| Property | Value |
|----------|-------|
| Package | [`ha-mcp`](https://pypi.org/project/ha-mcp/) (PyPI) |
| Transport | stdio |
| Install | `uvx --python 3.13 --refresh ha-mcp@latest` |
| Endpoint | `http://homeassistant.local:8123/` |
| Auth | Long-lived access token (`HOMEASSISTANT_TOKEN` in `.env`) |

`uvx` is auto-installed by `claude-sync` via `brew install uv`. The template uses the `__UVX__` placeholder, resolved at sync time to the absolute Homebrew path so Claude Desktop's GUI launch PATH can find it.

Token scoping: create the long-lived access token under the HA user that has the operations you want Claude to perform. For this setup the token covers read entities, call services, manage automations, edit dashboards — the same account Claude Code uses through the editing flow documented in [Home Assistant](../home-assistant.md).

## forgejo

Interacts with the internal Forgejo instance — reads repos, opens issues and PRs, creates branches, commits files.

| Property | Value |
|----------|-------|
| Source | [`codeberg.org/goern/forgejo-mcp`](https://codeberg.org/goern/forgejo-mcp) |
| Transport | stdio |
| Install | `git clone` + `go install .` (auto-built from source by `claude-sync`) |
| Endpoint | `http://forgejo:3000/` (Tailscale MagicDNS) |
| Auth | Forgejo API token (`FORGEJO_ACCESS_TOKEN` in `.env`) |

Built from source on each Mac because there's no Homebrew package. `claude-sync` installs Go (if missing), clones the repo to `/tmp`, runs `go install .`, and cleans up — the binary lands in `~/go/bin/forgejo-mcp`. The template uses the `__FORGEJO_MCP__` placeholder; rendered to the absolute install path at sync time.

Endpoint uses the Tailscale MagicDNS name `forgejo`, not the LAN IP. This works on-LAN (via tailnet DNS) and off-LAN (via Tailscale) as long as Tailscale is up; `claude-sync` prints a reachability warning if the endpoint doesn't respond.

Transport is currently stdio. `forgejo-mcp` also supports `--transport sse|http`, which would allow a single long-running instance on the Mac mini shared across both clients. Flagged as a future option — stdio works fine today.

## irs-taxpayer

Reference tool for US tax code questions. Stateless, no auth.

| Property | Value |
|----------|-------|
| Package | `irs-taxpayer-mcp` (npm) |
| Transport | stdio |
| Install | `npx -y irs-taxpayer-mcp` |
| Auth | None |

`npx` is auto-installed by `claude-sync` via `brew install node`. The `-y` flag auto-confirms the package install on first run.

## proxmox

Reads and acts on the Proxmox cluster — inventories VMs/LXCs/storage, checks system health, starts/stops/snapshots/backs up guests. Intentionally cannot create, delete, reconfigure, or touch Proxmox hosts themselves.

| Property | Value |
|----------|-------|
| Source | [`github.com/RekklesNA/ProxmoxMCP-Plus`](https://github.com/RekklesNA/ProxmoxMCP-Plus) |
| Transport | stdio |
| Install | `git clone` → `uv venv` → `uv pip install -e .` (auto by `claude-sync`) |
| Install location | `~/.local/share/ProxmoxMCP-Plus/` |
| Endpoint | `https://sb.tail-scale.ts.net` (Tailscale Serve → Proxmox 8006) |
| SSL verify | `true` (Tailscale Serve provides a real Let's Encrypt cert) |
| Auth | Proxmox API token (`PROXMOX_TOKEN` in `.env`) |
| Config file | `~/.local/share/ProxmoxMCP-Plus/proxmox-config/config.json` (chmod 600, rendered by `claude-sync`) |

### Config file, not env vars

ProxmoxMCP-Plus reads its config from a JSON file referenced by `PROXMOX_MCP_CONFIG`, not from env vars. `claude-sync` renders `proxmox-config.template.json` from the repo into `~/.local/share/ProxmoxMCP-Plus/proxmox-config/config.json` and `chmod 600`s it because it contains the API token. See [claude-sync](claude-sync.md#config-template-rendering-for-mcps-that-need-a-secondary-config-file) for the rendering pattern.

### Endpoint

Proxmox's web UI normally lives at `https://10.0.0.2:8006` with a self-signed cert. The MCP instead talks to `https://sb.tail-scale.ts.net` on port 443 — Tailscale Serve on the SB host proxies that name to localhost:8006 internally, terminating TLS with a real Let's Encrypt cert. That's why `verify_ssl: true` works without importing a custom CA.

### Proxmox permissions model

The MCP's capabilities are bounded at the Proxmox side, not trusted to the client. The setup:

#### Dedicated user

`mcp@pve` in the `pve` realm — **not** `pam`. The `pve` realm is Proxmox's internal auth database, so this user has no shell/SSH access; it exists only to hold API tokens.

#### Custom role `MCPUser`

Built in **Datacenter → Permissions → Roles → Create** with these privileges:

**Audit everywhere (read-only across the cluster):**

- `Datastore.Audit`
- `Mapping.Audit`
- `Pool.Audit`
- `SDN.Audit`
- `Sys.Audit`
- `VM.Audit`
- `VM.GuestAgent.Audit`

**Syslog read:**

- `Sys.Syslog`

**Write operations, scoped to running guests:**

- `VM.PowerMgmt` — start/stop/reboot
- `VM.Backup` — trigger vzdump backups
- `VM.Snapshot` — create/delete snapshots
- `VM.Snapshot.Rollback` — roll back to a snapshot

**Deliberately excluded:**

| Privilege | Why excluded |
|-----------|--------------|
| `VM.Allocate` | Prevents creating or destroying VMs/LXCs |
| `VM.Clone` | Prevents cloning (also a creation path) |
| `VM.Config.*` (the whole family) | Prevents reconfiguring hardware, network, cloud-init, options, etc. |
| `VM.Migrate` | Prevents moving guests between nodes |
| `VM.Console` | Neutralizes the QEMU guest-agent command-exec tool — without console access the MCP can't run arbitrary shell commands inside guests |
| `Sys.PowerMgmt` | Prevents rebooting Proxmox hosts themselves |
| `Sys.Modify` | Prevents host-level config changes |
| `SDN.*` (beyond Audit), `Mapping.*` (beyond Audit), `Realm.*`, `User.*`, `Group.*`, `Permissions.*` | Prevents any change to networks, PCI/USB mappings, auth realms, users, groups, or the permission system itself |

Net effect: read-only audit across the entire cluster, ability to power-cycle/snapshot/back up guests, **no** ability to create/delete/reconfigure anything, **no** arbitrary command execution inside guests, **no** access to the Proxmox hosts themselves.

#### Pool `mcp-managed`

Created under **Datacenter → Permissions → Pools** but currently **unused** — intentionally. The reasoning:

- The `MCPUser` role is already tight enough that cluster-wide grants are safe — there's no destructive privilege in the role to scope away.
- Scoping by pool would blind the MCP to infrastructure it needs to reason about (PiHole, Forgejo, storage inventories, etc.) without adding meaningful protection.
- The pool exists as a future option if a specific subset ever needs to be carved off (e.g., handing a narrower token to a less-trusted workflow).

#### Grant

`mcp@pve` granted `MCPUser` role on path `/` with **propagate on** via **Datacenter → Permissions → Add → User Permission**.

#### Token

**Datacenter → Permissions → API Tokens → Add**:

- Token ID: `mcp@pve!mcp-claude`
- **Privilege Separation: unchecked** — the token inherits the user's full permissions directly. This is the number-one Proxmox API gotcha: with Privilege Separation checked, the token has *no* privileges unless you also grant the role to the `!mcp-claude` token itself. Leaving it unchecked means the token = the user's permissions.

The token secret is shown **once** at creation and can't be re-displayed — Proxmox rotates it if lost. Stored as `PROXMOX_TOKEN` in `~/claude-config/.env` and substituted into the rendered config by `claude-sync`.

### Upgrade path for container command execution

ProxmoxMCP-Plus can run shell commands inside LXCs via SSH to the Proxmox host + `pct exec`. This is currently **disabled** two ways:

1. No `ssh` block in `proxmox-config.template.json` — no SSH credentials available.
2. `command_policy.mode` is `deny_all` with an empty `allow_patterns` list — every command would be blocked even if SSH were configured.

To enable later:

1. Add an `ssh` block to `proxmox-config.template.json` with the container-user SSH key path and target host.
2. Switch `command_policy` to an allow-list mode with specific safe `allow_patterns`.
3. Keep the existing `deny_patterns` entries (`rm -rf`, fork bomb) as a belt-and-suspenders backstop.

Revisit once the current read + power-cycle + backup workflow is well-exercised and a specific need for in-container commands shows up.

## Related

- [Claude Tooling](claude-setup.md) — high-level overview
- [claude-sync](claude-sync.md) — render + bootstrap script
- [Forgejo](../services/forgejo.md) — target of the `forgejo` MCP
- [Home Assistant](../home-assistant.md) — target of the `home-assistant` MCP
- [Network](../network.md) — IP assignments for cluster endpoints
