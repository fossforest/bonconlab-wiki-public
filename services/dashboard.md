# BonConLab Dashboard

Custom start page for BonConLab with service links, bookmarks, quick-launch search, favorites, and drag-and-drop organization.

## Overview

| Property | Value |
|----------|-------|
| Node | TMG (tmg) |
| Type | LXC Container (unprivileged) |
| Container ID | 114 |
| IP | 10.0.0.123 (reserved in Unifi as "tmg-dashboard") |
| Port | 8080 |
| Storage | local-zfs |
| Status | ✅ Active |
| Tailscale hostname | dashboard |
| Stack | Python 3 (Debian 13 native) + stdlib http.server |

## Access

| Method | URL |
|--------|-----|
| Local | http://10.0.0.123:8080 |
| Remote (Tailscale) | https://dashboard.tail-scale.ts.net |
| SSH | `ssh root@dashboard` (via Tailscale SSH) |

## Features

- Service cards organized by category (Apps, Tools, Home, Media, Network, Nodes)
- Favorites section for starred services
- Quick-launch search (press `/` to focus)
- Drag-and-drop reorder for cards, categories, and bookmarks (SortableJS)
- Edit mode (Shift+E) for adding/editing/deleting services and categories
- Bookmark section with quick links
- Dark/light theme toggle
- App icons from [Dashboard Icons CDN](https://github.com/walkxcode/dashboard-icons) or Lucide icons
- Config export for backups

## Architecture

- **Server**: `server.py` — Python stdlib HTTP server with a single POST endpoint for saving config
- **Frontend**: `index.html` — Single-file vanilla JS app (no build step), uses Lucide icons and SortableJS from CDN
- **Data**: `config.json` — All dashboard content (services, bookmarks, metadata)

The server does two things: serves static files and accepts POST to `/config.json` to persist edits. No frameworks, no dependencies, no pip packages.

## Configuration

| Path | Purpose |
|------|---------|
| `/opt/dashboard/` | Working directory |
| `/opt/dashboard/config.json` | Dashboard content (source of truth — NOT tracked in git) |
| `/opt/dashboard/server.py` | Python HTTP server |
| `/opt/dashboard/index.html` | Frontend SPA |
| `/etc/systemd/system/dashboard.service` | Systemd unit |

### Data Management

`config.json` is the live data file edited through the dashboard UI. It is **excluded from git** via `.gitignore` to prevent webhook pulls from overwriting live data. A `config.example.json` is kept in the repo as a starting template for fresh deploys.

To back up the current config:

```bash
# From any machine with Tailscale
scp root@dashboard:/opt/dashboard/config.json ./config-backup.json
# scp — Secure copy over Tailscale SSH
```

Or use the "Export Backup" button in the dashboard footer (in edit mode).

## GitOps / Auto-Deploy

The `bonconlab-dashboard` repo on Forgejo has a push-event webhook that triggers a pull + restart on this container:

| Setting | Value |
|---------|-------|
| Payload URL | http://10.0.0.123:9000/hooks/dashboard-deploy |
| Events | Push |

**Webhook receiver on LXC 114**:
- Package: `webhook` (installed during container provisioning)
- Config: `/etc/webhook.conf`
- Listening port: 9000
- Deploy script: `/opt/dashboard/pull-and-deploy.sh`

This deploys code changes (`index.html`, `server.py`) automatically on push. `config.json` is not affected because it's in `.gitignore`.

## Installation

First container deployed using the `deploy-container` script from the [bonconlab-scripts](http://10.0.0.181:3000/anon/bonconlab-scripts) repo. See [LXC Deploy Workflow](lxc-deploy-workflow.md) for the full process.

```bash
deploy-container --vmid 114 --hostname dashboard --port 8080 --repo bonconlab-dashboard
```

This created the container, installed all packages (Node.js, Python, Tailscale, webhook), set up Tailscale with SSH, cloned the repo, created the systemd service, and configured the webhook receiver.

`config.json` was manually copied into the container after deployment since it is excluded from git:

```bash
scp config.json root@dashboard:/opt/dashboard/config.json
# Copy the live config into the container via Tailscale SSH
```

## Maintenance

### Container Management

From TMG host:

```bash
pct status 114
# Check if the container is running

pct start 114
pct stop 114
pct reboot 114
# Start, stop, or restart the container

pct enter 114
# Open a shell inside the container
```

### Service Management

Inside the container (or via `pct exec 114 --`):

```bash
systemctl status dashboard
# Check service status

systemctl restart dashboard
# Restart after manual changes

journalctl -u dashboard -n 50
# journalctl — Query systemd journal logs
# -u dashboard — Filter by the dashboard service unit
# -n 50 — Show the last 50 lines
```

### Adding a Service to the Dashboard

Use the dashboard UI:
1. Press Shift+E to enter edit mode
2. Click the + button next to a category header
3. Fill in the service details (name, URL, description, icon, color)
4. Click Save — changes are written to `config.json` immediately

### Updates

Code updates are deployed automatically via the Forgejo webhook. To manually pull:

```bash
ssh root@dashboard
cd /opt/dashboard
git pull origin main
systemctl restart dashboard
```

## Troubleshooting

### Dashboard not loading

```bash
systemctl status dashboard
# Check if the service is running

journalctl -u dashboard -xe
# -x — Add explanatory help text
# -e — Jump to end of logs
```

### Config changes not saving

```bash
# Check that config.json exists and is writable
ls -la /opt/dashboard/config.json
# ls -la — Lists file with permissions and ownership

# Check server logs for POST errors
journalctl -u dashboard -n 20
```

### Webhook not deploying

```bash
# Test the webhook locally
curl -X POST http://localhost:9000/hooks/dashboard-deploy
# Should trigger git pull and service restart

# Check webhook service
systemctl status webhook
journalctl -u webhook -n 20
```

## Source

- Repo: `alex/bonconlab-dashboard` on Forgejo

## Related

- [LXC Deploy Workflow](lxc-deploy-workflow.md) (how this container was provisioned)
- [bonconlab-scripts](http://10.0.0.181:3000/anon/bonconlab-scripts) (deploy-container, ts-init, svc-init)
- [Mirror Manager](mirror-manager.md) (webhook bootstrap)
- [Services Index](_services-index.md)
- [Network Configuration](../network.md)
