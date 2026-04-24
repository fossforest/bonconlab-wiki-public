# Claude Tooling

Conversational and agentic AI assistance for BonConLab infrastructure — chat planning, desktop file operations, and terminal-driven code work. All three surfaces share a single MCP configuration so any one of them can reach Home Assistant, Forgejo, and Proxmox with the same scopes.

## Overview

| Property | Value |
|----------|-------|
| Machines | Mac Mini M4 (10.0.0.148), MacBook Pro (roaming, no static IP) |
| Shared configuration repo | [claude-config](http://10.0.0.181:3000/anon/claude-config) on Forgejo |
| Synced by | [claude-sync](claude-sync.md) on each machine |
| Active MCPs | home-assistant, forgejo, irs-taxpayer, proxmox — see [mcp-servers](mcp-servers.md) |
| Status | ✅ Active |

Both Macs run macOS with identical Claude Desktop + Claude Code installations and identical rendered MCP configs. Divergence between the two machines is limited to Claude Desktop preferences (theme, window state, etc.), which `claude-sync` deliberately leaves alone.

## Tool surfaces

| Surface | Client | Used for |
|---------|--------|----------|
| Chat | claude.ai web + iOS app | Planning, research, long-form reasoning before touching files. No file access. |
| Cowork | Claude Desktop (macOS) | Agentic desktop work — reads/writes files in an allowed directory, runs shell commands, drives MCPs interactively. |
| Claude Code | Terminal CLI | Conversational code work — file edits, git, tests, longer autonomous tool runs. Reads the same MCPs as Cowork. |

The typical arc for a meaningful piece of work is: sketch it in chat → promote to Cowork or Claude Code for execution → document the result back in this wiki.

## claude-config repo

Shared MCP configuration for Desktop + Code across both Macs. Lives at [alex/claude-config](http://10.0.0.181:3000/anon/claude-config) on the internal Forgejo (`10.0.0.181:3000` on-LAN, `http://forgejo:3000/` over Tailscale).

Contents:

| Path | Purpose |
|------|---------|
| `desktop.template.json`, `code.template.json` | MCP block templates for Claude Desktop and Claude Code |
| `proxmox-config.template.json` | Standalone config file for the ProxmoxMCP-Plus server (rendered separately) |
| `.env` | Real tokens (HomeAssistant, Forgejo, Proxmox) — committed |
| `.env.example` | Placeholder reference |
| `claude-sync` | The render + bootstrap script — see [claude-sync](claude-sync.md) |
| `.claude/settings.json` | Tool-level deny rule blocking Read/Write/Edit on `.env` |
| `.claude/skills/add-mcp/SKILL.md` | Skill that walks Claude through adding a new MCP without touching `.env` |

### Why it's not mirrored to GitHub

`.env` is committed so the two Macs can stay in sync without a separate secret channel. This is safe only because the repo never leaves the LAN + Tailscale perimeter — Forgejo isn't internet-exposed and the machines connect over local network or Tailscale. Mirroring this repo to GitHub would immediately leak three MCP tokens; the same principle applies to the `bonconlab-scripts` repo, which is also intentionally Forgejo-only.

## Security model

Three layers keep MCP tokens contained:

1. **Tool-layer deny** — `.claude/settings.json` in the repo blocks `Read`, `Write`, and `Edit` on `.env` and `.env.*`. Claude physically cannot read these files through any tool regardless of intent. Shell workarounds (`cat`, `echo >>`, `sed -i`) to read or write `.env` contents are also out of scope — the rule's purpose is to keep secrets out of model context, not just out of one tool.
2. **Network isolation** — Forgejo is LAN + Tailscale only. A compromised laptop away from the tailnet can't even pull the repo.
3. **Token scoping** — each MCP gets a purpose-scoped token. The Proxmox token is the most interesting case: it's bound to a dedicated `mcp@pve` user with a custom read-heavy role (see [mcp-servers](mcp-servers.md#proxmox)) and cannot create, delete, or reconfigure anything.

## Related

- [claude-sync](claude-sync.md) — script reference
- [mcp-servers](mcp-servers.md) — per-MCP details and token scoping
- [Forgejo](../services/forgejo.md) — where `claude-config` is hosted
- [Home Assistant](../home-assistant.md) — target of the `home-assistant` MCP
