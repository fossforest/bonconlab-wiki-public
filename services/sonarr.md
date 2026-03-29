# Sonarr

Automated TV show management. Searches indexers, sends downloads to qBittorrent, and organizes completed files into the Plex library.

## Overview

| Property | Value |
|----------|-------|
| Node | DB (db) |
| Type | LXC Container |
| Container ID | 308 |
| IP | 10.0.0.163 |
| Port | 8989 |
| Storage | /data (18TB ext4 via bind mount) |
| Status | ✅ Active |

## Access

| Method | URL |
|--------|-----|
| Local | http://10.0.0.163:8989 |

## Storage Architecture

Two mount points provide access to both new and existing media:

| Mount | Host Path | Container Path | Purpose |
|-------|-----------|----------------|---------|
| mp0 | /mnt/external-18tb-hdd | /data | New downloads and library (primary) |
| mp1 | /mnt/virtual-media | /media | Existing Plex library (mergerfs pool, read access) |

**Root Folders**:
- `/data/plex-media/TV` — new shows land here (18TB drive)
- `/media/TV` — imported existing library from mergerfs pool

New downloads go to `/data/arr-downloads/sonarr/`, then hardlink to `/data/plex-media/TV` on import.

## Quality Profiles

| Profile | Upgrade Until | Use Case |
|---------|--------------|----------|
| Uncompressed | Bluray-2160p Remux | Prestige/cinematic shows (reference quality) |
| 2160p/1080p | Bluray-2160p | Prestige shows — 4K preferred, 1080p fallback |
| 1080p/720p | Bluray-1080p | Casual/comedy shows (30 Rock, Bob's Burgers, etc.) |

Profile is assigned per-series when adding a show, allowing different quality targets for different types of content.

## Download Client

| Setting | Value |
|---------|-------|
| Client | qBittorrent |
| Host | 10.0.0.164 |
| Port | 8090 |
| Category | sonarr |
| Authentication | Bypassed (IP whitelist on qBit) |

## Configuration

| Setting | Value |
|---------|-------|
| Rename Episodes | ✅ Enabled |
| Naming Format | Default (Show Name - S01E01 - Episode Title.mkv) |
| Indexer | MoreThanTV (synced via Prowlarr) |

## Maintenance

### Container Management

From DB host:

```bash
# Check status
pct status 308

# Start/stop/restart
pct start 308
pct stop 308
pct reboot 308

# Access shell
pct enter 308
```

### Importing Existing Media

1. Go to **Library** → **Library Import**
2. Select the `/media/TV` root folder
3. Review auto-matched series, fix any mismatches
4. Import

### Monitoring Behavior

- **Monitored** series: Sonarr actively searches for missing episodes and quality upgrades
- **Unmonitored**: Sonarr tracks the series but doesn't search or download
- **Continuing** shows (e.g., Bob's Burgers): Sonarr auto-grabs new episodes as they air

## Troubleshooting

### Root folder not writable

Same as Radarr — unprivileged container UID mapping. Target directories need `chmod 777` on the host.

### Episode grabbed but not imported

1. Check **Activity → Queue** for error messages
2. Verify hardlink path: download and library on same filesystem
3. Check file permissions inside container:
   ```bash
   pct enter 308
   touch /data/plex-media/TV/test && rm /data/plex-media/TV/test
   ```

### Missing episodes not downloading

1. Verify series is set to **Monitored**
2. Check the specific season — individual seasons can be unmonitored
3. Try manual search: click series → season → search icon
4. Check Prowlarr indexer status

## Related

- [Prowlarr](prowlarr.md)
- [Radarr](radarr.md)
- [qBittorrent](qbittorrent.md)
- [Plex](plex.md)
- [Storage Configuration](../storage.md)
- [Services Index](_services-index.md)
