# Seerr

Media request and discovery tool. Provides a clean UI for users to request movies and TV shows, which are automatically sent to Radarr/Sonarr for download.

## Overview

| Property | Value |
|----------|-------|
| Node | DB (db) |
| Type | LXC Container |
| Container ID | 310 |
| IP | 10.0.0.165 |
| Port | 5055 |
| Tailscale IP | 100.76.248.106 |
| Storage | db-2tb-nvme (container OS) |
| Status | ✅ Active |

## Access

| Method | URL |
|--------|-----|
| Local | http://10.0.0.165:5055 |
| Tailscale (serve) | https://seerr.tail-scale.ts.net |

## Installation

Installed from source at `/opt/seerr` on Debian 13 (trixie). Runs as a Node.js app via systemd unit `seerr`.

## Configuration

Seerr connects to the arr stack to fulfill requests:

| Integration | Host | Port |
|-------------|------|------|
| Radarr | 10.0.0.162 | 7878 |
| Sonarr | 10.0.0.163 | 8989 |
| Plex | 10.0.0.194 | 32400 |

- **Plex integration**: Used for user authentication and library sync (shows what's already available)
- **Radarr/Sonarr**: Receives approved requests and triggers downloads
- **Config directory**: `/opt/seerr/config`

## Maintenance

### Container Management

From DB host:

```bash
# Check status
pct status 310

# Start/stop/restart
pct start 310
pct stop 310
pct reboot 310

# Access shell
pct enter 310
```

### Service Management

Inside container:

```bash
# Check Seerr status
systemctl status seerr

# Restart
systemctl restart seerr

# View logs
journalctl -u seerr -f
```

## Troubleshooting

### Requests not reaching Radarr/Sonarr

1. Verify Radarr/Sonarr are running and reachable from the Seerr container:
   ```bash
   pct enter 310
   curl -s http://10.0.0.162:7878/api/v3/system/status -H "X-Api-Key: <key>" | head
   ```
2. Check API keys in Seerr settings match the Radarr/Sonarr API keys

### Plex library not syncing

1. Verify Plex is reachable: `curl -s http://10.0.0.194:32400/identity`
2. Re-sync library in Seerr settings

## Related

- [Radarr](radarr.md) — receives movie requests
- [Sonarr](sonarr.md) — receives TV show requests
- [Plex](plex.md) — library sync and user auth
- [Jellyfin](jellyfin.md) — alternative media server
- [Services Index](_services-index.md)
