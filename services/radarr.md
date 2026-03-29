# Radarr

Automated movie management. Searches indexers, sends downloads to qBittorrent, and organizes completed files into the Plex library.

## Overview

| Property | Value |
|----------|-------|
| Node | DB (db) |
| Type | LXC Container |
| Container ID | 307 |
| IP | 10.0.0.162 |
| Port | 7878 |
| Storage | /data (18TB ext4 via bind mount) |
| Status | ✅ Active |

## Access

| Method | URL |
|--------|-----|
| Local | http://10.0.0.162:7878 |

## Storage Architecture

Two mount points provide access to both new and existing media:

| Mount | Host Path | Container Path | Purpose |
|-------|-----------|----------------|---------|
| mp0 | /mnt/external-18tb-hdd | /data | New downloads and library (primary) |
| mp1 | /mnt/virtual-media | /media | Existing Plex library (mergerfs pool, read access) |

**Root Folders**:
- `/data/plex-media/Movies` — new movies land here (18TB drive)
- `/media/Movies` — imported existing library from mergerfs pool

New downloads go to `/data/arr-downloads/radarr/`, then hardlink to `/data/plex-media/Movies` on import. Hardlinks work because both paths are on the same ext4 filesystem.

## Quality Profiles

| Profile | Upgrade Until | Use Case |
|---------|--------------|----------|
| Uncompressed | Bluray-2160p Remux | Reference-quality films |
| 2160p/1080p | Bluray-2160p | Everyday quality — 4K preferred, 1080p fallback |
| 1080p/720p | Bluray-1080p | Older or casual films |

## Download Client

| Setting | Value |
|---------|-------|
| Client | qBittorrent |
| Host | 10.0.0.164 |
| Port | 8090 |
| Category | radarr |
| Authentication | Bypassed (IP whitelist on qBit) |

## Configuration

| Setting | Value |
|---------|-------|
| Rename Movies | ✅ Enabled |
| Naming Format | Default (Movie Name (Year)/Movie Name (Year).mkv) |
| Indexer | MoreThanTV (synced via Prowlarr) |

## Maintenance

### Container Management

From DB host:

```bash
# Check status
pct status 307

# Start/stop/restart
pct start 307
pct stop 307
pct reboot 307

# Access shell
pct enter 307
```

### Importing Existing Media

1. Go to **Library** → **Library Import**
2. Select the `/media/Movies` root folder
3. Review auto-matched titles, fix any mismatches
4. Select **Movie Only** (not "Movie and Collection" — avoids auto-downloading entire franchises)
5. Import

## Troubleshooting

### Root folder not writable

Container is unprivileged — root inside maps to a high UID on the host. Target directories need `chmod 777` or correct UID mapping. The `/data/plex-media/Movies` directory should already have open permissions.

### Download completes but doesn't import

1. Check **Activity → Queue** for error messages
2. Verify hardlink path: both download and library must be on the same filesystem
3. Check container can write to `/data/plex-media/Movies`:
   ```bash
   pct enter 307
   touch /data/plex-media/Movies/test && rm /data/plex-media/Movies/test
   # touch — creates an empty file (tests write permission)
   # rm — removes the test file
   ```

### Movie not found on indexer

1. Check Prowlarr: Indexers → test MTV connection
2. Try manual search in Radarr: click movie → Search icon
3. Verify the movie exists on MTV (some older/niche titles may not be available)

## Related

- [Prowlarr](prowlarr.md)
- [Sonarr](sonarr.md)
- [qBittorrent](qbittorrent.md)
- [Plex](plex.md)
- [Storage Configuration](../storage.md)
- [Services Index](_services-index.md)
