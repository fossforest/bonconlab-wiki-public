# Forgejo

Self-hosted Git server. Primary remote for private repositories, replacing GitHub for local-first workflows. Enables LAN webhook-based GitOps — push to repo → services auto-update — which isn't practical with GitHub since webhooks can't reach LAN hosts.

## Overview

| Property | Value |
|----------|-------|
| Node | TMG (tmg) |
| Type | LXC Container (unprivileged) |
| Container ID | 104 |
| IP | 10.0.0.181 (reserved in Unifi as "tmg-forgejo") |
| Port | 3000 |
| Storage | local-zfs |
| Status | ✅ Active |
| Forgejo Version | 14.0.3 |
| Database | SQLite |
| Git System User | git |
| Data Directory | /var/lib/forgejo |
| Config File | /etc/forgejo/app.ini |

## Access

| Method | URL |
|--------|-----|
| Local | http://10.0.0.181:3000 |
| Remote (Tailscale) | https://forgejo.tail-scale.ts.net |
| SSH into container | `ssh root@forgejo` (via Tailscale) |

**Note on ROOT_URL**: `app.ini` sets `ROOT_URL = http://10.0.0.181:3000` (local IP, not the tailnet URL). This ensures clone URLs and webhook deliveries work on the LAN without requiring Tailscale to be active. When accessing via the tailnet URL, Forgejo shows a cosmetic banner warning about the URL mismatch — this is expected and harmless. Forgejo only supports a single ROOT_URL; local IP was chosen intentionally.

## Hosted Repositories

Both repositories are public on this instance. Access control relies on network-level restrictions (LAN / Tailscale only).

| Repository | Description | Migrated From |
|------------|-------------|---------------|
| bonconlab-wiki | Homelab documentation | GitHub (anon-user/bonconlab-wiki) |
| bonconlab-scripts | Shared provisioning and utility scripts (contains secrets — **not mirrored to GitHub**) | — (new) |
| homeassistant-config | HA config version control and backup | — (new, pushed from HAOS) |
| forgejo-mirror-manager | Mirror manager web app | — (new) |
| cv-updater | CV editing and .docx generation | GitHub (secondary remote retained) |
| claude-config | Shared Claude Desktop + Claude Code MCP configuration across both Macs (contains MCP tokens in `.env` — **not mirrored to GitHub**) | — (new) |

### Migration

Repos were migrated using Forgejo's built-in GitHub migration tool with a temporary fine-grained GitHub PAT (Contents + Metadata, read-only). Full commit history was preserved.

Local git remotes on the Mac were reconfigured after migration:
- `origin` → Forgejo (default push target)
- `github` → GitHub (preserved as secondary remote)

## Webhook Configuration

### app.ini webhook allowlist

To allow Forgejo to deliver webhooks to LAN hosts (blocked by default as a security measure), a `[webhook]` section was added to `/etc/forgejo/app.ini`:

```ini
[webhook]
ALLOWED_HOST_LIST = 10.0.0.0/24
```

Restart Forgejo after editing app.ini:

```bash
systemctl restart forgejo
```

## Installation

Installed 2026-03-16 via community helper script on TMG:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/forgejo.sh)"
```

During the advanced setup prompt, **TUN device was enabled** to allow Tailscale installation inside the container.

### Tailscale setup inside container

```bash
# Install Tailscale (community addon script or manual)
curl -fsSL https://tailscale.com/install.sh | sh

# Authenticate and bring up
tailscale up

# Serve port 3000 over HTTPS via Tailscale
tailscale serve --bg 3000
```

## Configuration

Key file: `/etc/forgejo/app.ini`

Relevant sections beyond defaults:

```ini
[server]
ROOT_URL = http://10.0.0.181:3000

[webhook]
ALLOWED_HOST_LIST = 10.0.0.0/24
```

## Maintenance

### Update Forgejo

Run the community script update pattern from the LXC console:

```bash
update
```

### Restart service

```bash
systemctl restart forgejo
```

### Check status

```bash
systemctl status forgejo
```

### Container management (from TMG host)

```bash
pct status 104
pct start 104
pct stop 104
pct enter 104
```

## File Locations

| Path | Purpose |
|------|---------|
| /etc/forgejo/app.ini | Main configuration file |
| /var/lib/forgejo/ | Data directory (repos, attachments, DB) |
| /var/lib/forgejo/forgejo.db | SQLite database |

## Related

- [Home Assistant](../home-assistant.md) (webhook consumer — GitOps config pull)
- [Mirror Manager](mirror-manager.md) (webhook consumer — LXC 111)
- [CV Updater](cv-updater.md) (webhook consumer — LXC 112)
- [Tailscale](tailscale.md)
- [Network Configuration](../network.md)
- [Services Index](_services-index.md)
