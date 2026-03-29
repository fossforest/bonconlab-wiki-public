# CV Updater

Web app for editing and generating a CV as a .docx file. Runs as a private LXC container on TMG.

## Overview

| Property | Value |
|----------|-------|
| Node | TMG (tmg) |
| Type | LXC Container (unprivileged) |
| Container ID | 112 |
| IP | 10.0.0.171 |
| Port | 3737 |
| Storage | local-zfs |
| Status | ✅ Active |
| Tailscale hostname | cv-updater |
| Stack | Node.js + Express |

## Access

| Method | URL |
|--------|-----|
| Local | http://10.0.0.171:3737 |
| Remote (Tailscale) | https://cv-updater.tail-scale.ts.net |
| SSH | `ssh root@cv-updater` (via Tailscale SSH) |

## Features

- Edit CV content and generate a .docx file for download
- Quick Add scratchpad: markdown-compatible persistent text area with auto-save (debounced 1.5s + Cmd+Enter), rendered preview below editor
- Dark mode toggle (system preference aware, localStorage persisted)

## Configuration

| Path | Purpose |
|------|---------|
| `/opt/cv-updater/` | Working directory |
| `/opt/cv-updater/data/` | Live CV data (not version controlled — .gitignored) |
| `/etc/systemd/system/cv-updater.service` | Systemd unit |

The `data/` directory is excluded from git tracking to prevent webhook pulls from overwriting live CV data. File ownership is maintained by the deploy script (see below).

**Service runs as**: `cvmanager` user

## GitOps / Self-Deploy

The `cv-updater` repo on Forgejo has a push-event webhook that triggers a pull + restart on this container:

| Setting | Value |
|---------|-------|
| Payload URL | http://10.0.0.171:9000/hooks/cv-updater-deploy |
| Events | Push |

**Webhook receiver on LXC 112**:
- Package: `webhook` (installed via `apt`)
- Listening port: 9000
- Deploy script: `/opt/cv-updater/pull-and-deploy.sh`

The deploy script includes `chown -R cvmanager:cvmanager /opt/cv-updater/data` after `git pull` to maintain correct file ownership — the webhook runs as root, but the app runs as `cvmanager`.

## History

- Originally named `cv-manager`; renamed to `cv-updater` (systemd unit, working directory `/opt/cv-manager` → `/opt/cv-updater`)
- `data/` removed from git tracking to prevent webhook pulls from overwriting live data

## Related

- [Forgejo](forgejo.md)
- [Mirror Manager](mirror-manager.md)
- [Services Index](_services-index.md)
