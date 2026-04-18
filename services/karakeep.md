# Karakeep

Self-hosted bookmark, note, and article archival app (formerly Hoarder). Auto-tags and summarizes saved content via AI, with full-text search across everything.

## Overview

| Property | Value |
|----------|-------|
| Node | SB (sb) |
| Type | LXC Container |
| Container ID | 205 |
| IP | 10.0.0.134 |
| Port | 3000 |
| Tailscale IP | 100.98.142.124 |
| Tailscale URL | https://karakeep.tail-scale.ts.net |
| Storage | sb-1tb-ssd |
| Status | ✅ Active |

## Access

| Method | URL |
|--------|-----|
| Local | http://10.0.0.134:3000 |
| Tailscale (serve) | https://karakeep.tail-scale.ts.net |

## Architecture

Karakeep runs as four native systemd services inside the LXC, all installed from source at `/opt/karakeep`:

| Service | Port | Purpose |
|---------|------|---------|
| `karakeep-web` | 3000 | Next.js frontend (the only user-facing port) |
| `karakeep-workers` | 34345 (local) | Python workers for crawling, tagging, summarization |
| `karakeep-browser` | 9222 (local) | Headless Chromium for page rendering and screenshotting |
| `meilisearch` | 7700 (local) | Full-text search index |

Only port 3000 is exposed externally; the workers, browser, and meilisearch bind to `127.0.0.1`.

## Installation

- VMID: 205
- Hostname: karakeep
- Template: Debian 13 (trixie)
- Resources: 2 cores, 4GB RAM, 20GB disk
- Storage: sb-1tb-ssd
- Network: 10.0.0.134

Installed natively from source at `/opt/karakeep`. Tailscale added via `ts-init`; `tailscale serve` proxies `https://karakeep.tail-scale.ts.net` → `http://127.0.0.1:3000`.

## Configuration

- **App directory**: `/opt/karakeep`
- **Environment**: `.env` in `/opt/karakeep` (copied from `.env.sample` during setup)
- **AI tagging**: Can point at Ollama on the Mac Mini (`http://10.0.0.148:11434`) as an OpenAI-compatible backend for auto-tagging and summarization

## Maintenance

### Container Management

From SB host:

```bash
pct status 205
pct start 205
pct stop 205
pct reboot 205
pct enter 205
```

### Service Management

Inside the container:

```bash
systemctl status karakeep-web karakeep-workers karakeep-browser meilisearch
systemctl restart karakeep-web
journalctl -u karakeep-web -f
```

## Troubleshooting

### Web UI unreachable

- Check the web service: `systemctl status karakeep-web`
- Verify port 3000 is listening: `ss -tlnp | grep 3000`

### Bookmarks never finish processing (stuck "pending")

- Check workers and browser: `systemctl status karakeep-workers karakeep-browser`
- Chromium must be running on `127.0.0.1:9222` for page crawling to succeed

### Search returns no results

- Verify meilisearch is running: `systemctl status meilisearch`
- Confirm it's bound to `127.0.0.1:7700`: `ss -tlnp | grep 7700`

## Related

- [Ollama](ollama.md) — can serve as the AI backend for auto-tagging
- [Services Index](_services-index.md)
