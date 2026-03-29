# Forgejo Mirror Manager

Web UI for managing Forgejo → GitHub push mirrors, creating repos, and configuring deploy webhooks with bootstrap scripts.

## Overview

| Property | Value |
|----------|-------|
| Node | TMG (tmg) |
| Type | LXC Container (unprivileged) |
| Container ID | 111 |
| IP | 10.0.0.140 (reserved in Unifi as "tmg-mirror-manager") |
| Port | 3850 |
| Storage | local-zfs |
| Status | ✅ Active |
| Tailscale hostname | mirror-manager |
| Stack | Node.js 20 (Debian 13 native) + Express |

## Access

| Method | URL |
|--------|-----|
| Local | http://10.0.0.140:3850 |
| Remote (Tailscale) | https://mirror-manager.tail-scale.ts.net |
| SSH | `ssh root@mirror-manager` (via Tailscale SSH) |

## Features

- One-click repo creation with GitHub mirror
- Push mirror management (sync-on-commit) via Forgejo API
- Deploy webhook creation for GitOps setup on target containers
- Bootstrap script endpoint (`/setup-webhook.sh`) — generates a container-side webhook receiver setup script for any container

## Configuration

| Path | Purpose |
|------|---------|
| `/opt/forgejo-mirror-manager/` | Working directory / data dir |
| `/opt/forgejo-mirror-manager/.env` | Forgejo + GitHub API tokens |
| `/etc/systemd/system/mirror-manager.service` | Systemd unit |

The `.env` file contains Forgejo and GitHub API tokens — keep this out of version control.

## GitOps / Self-Deploy

The `forgejo-mirror-manager` repo on Forgejo has a push-event webhook that triggers a pull + restart on this container:

| Setting | Value |
|---------|-------|
| Payload URL | http://10.0.0.140:9000/hooks/mirror-manager-deploy |
| Events | Push |

**Webhook receiver on LXC 111**:
- Package: `webhook` (installed via `apt`)
- Listening port: 9000
- Deploy script: `/opt/forgejo-mirror-manager/pull-and-deploy.sh`

## Installation Notes

- Container created via community Debian LXC helper script (Debian 13 Trixie)
- TUN device enabled during creation to allow Tailscale installation
- Node.js 20 installed from Debian 13 default repos (no NodeSource needed — Debian 13 ships Node.js 20 LTS natively)
- Tailscale installed and `tailscale serve --bg 3850` configured for HTTPS access
- `webhook` package installed via `apt` for GitOps deploy receiver

## Source

- Repo: `alex/forgejo-mirror-manager` on Forgejo

## Related

- [Forgejo](forgejo.md)
- [Services Index](_services-index.md)
- [Network Configuration](../network.md)
