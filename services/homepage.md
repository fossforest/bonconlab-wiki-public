# Homepage

YAML-configured homelab dashboard with service links and optional live-stats widgets.

## Overview

| Property | Value |
|----------|-------|
| Node | TMG (tmg) |
| LXC | 107 |
| IP | DHCP |
| Port | 3000 |
| Storage | local |
| Status | ✅ Active |

## Access

| Method | URL |
|--------|-----|
| Tailscale HTTPS | https://homepage.tail-scale.ts.net/ |

## Configuration

Config files live at `/app/config/` inside the container:

| File | Purpose |
|------|---------|
| `services.yaml` | Service links grouped by category |
| `settings.yaml` | Global dashboard settings |
| `widgets.yaml` | Info widgets (date/time, search, etc.) |
| `bookmarks.yaml` | Bookmark groups |

Config hot-reloads on save — no container restart needed.

Config is maintained in a separate git repository for version control.

## Notes

- Replaced Homarr (LXC 104, deleted)
- Widget integrations prepared (commented out) for Proxmox, PiHole, Home Assistant, PBS, Plex, Paperless-ngx
- YAML-based config is well-suited to version control and LLM-assisted editing

## Related

- [Services Index](_services-index.md)
- [Tailscale](tailscale.md)
