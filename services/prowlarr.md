# Prowlarr

Indexer manager for the *arr stack. Centralizes tracker/indexer configuration and syncs to Radarr and Sonarr.

## Overview

| Property | Value |
|----------|-------|
| Node | DB (db) |
| Type | LXC Container |
| Container ID | 306 |
| IP | 10.0.0.161 |
| Port | 9696 |
| Storage | /data (18TB ext4 via bind mount) |
| Status | ✅ Active |

## Access

| Method | URL |
|--------|-----|
| Local | http://10.0.0.161:9696 |

## Purpose

Prowlarr acts as a single management point for indexers. Instead of configuring tracker credentials in both Radarr and Sonarr individually, Prowlarr holds the indexer definitions and syncs them to connected apps automatically.

## Indexers

| Indexer | Type | Protocol |
|---------|------|----------|
| MoreThanTV (MTV) | Private Tracker | Torznab |

MTV is configured using Prowlarr's built-in MoreThanTV definition with API credentials from the tracker.

## Connected Apps

| App | URL | Sync |
|-----|-----|------|
| Radarr | http://10.0.0.162:7878 | ✅ Auto |
| Sonarr | http://10.0.0.163:8989 | ✅ Auto |

Indexers are pushed to both apps via **Settings → Apps → Sync App Indexers**.

## Maintenance

### Container Management

From DB host:

```bash
# Check status
pct status 306
# pct status — shows if the container is running or stopped

# Start/stop/restart
pct start 306
pct stop 306
pct reboot 306

# Access shell
pct enter 306
# pct enter — opens an interactive shell inside the container
```

## Troubleshooting

### Indexer test fails

1. Verify MTV credentials are correct in the indexer config
2. Check container has internet access: `pct enter 306` then `ping google.com`
3. Check Prowlarr logs: System → Logs

### Sync not pushing to Radarr/Sonarr

1. Verify API keys are correct in Settings → Apps
2. Confirm Radarr/Sonarr containers are running
3. Click **Sync App Indexers** manually

## Related

- [Radarr](radarr.md)
- [Sonarr](sonarr.md)
- [qBittorrent](qbittorrent.md)
- [Services Index](_services-index.md)
