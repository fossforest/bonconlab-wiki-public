# qBittorrent

Torrent client for the *arr stack. Handles downloads from private trackers and seeds to maintain ratio.

## Overview

| Property | Value |
|----------|-------|
| Node | DB (db) |
| Type | LXC Container |
| Container ID | 309 |
| IP | 10.0.0.164 |
| WebUI Port | 8090 |
| Peer Port | 59788 |
| Storage | /data (18TB ext4 via bind mount) |
| Status | ✅ Active |

## Access

| Method | URL |
|--------|-----|
| Local | http://10.0.0.164:8090 |

## Download Paths

| Path | Purpose |
|------|---------|
| /data/arr-downloads/ | Default save path |
| /data/arr-downloads/incomplete/ | In-progress downloads |
| /data/arr-downloads/radarr/ | Completed movies (auto-created by category) |
| /data/arr-downloads/sonarr/ | Completed TV (auto-created by category) |

Radarr and Sonarr hardlink completed files from the category directories to `/data/plex-media/Movies` and `/data/plex-media/TV` respectively. Hardlinks work because all paths are on the same ext4 filesystem.

## Configuration

### Downloads

| Setting | Value |
|---------|-------|
| Default Save Path | /data/arr-downloads/ |
| Keep incomplete torrents in | ✅ /data/arr-downloads/incomplete/ |

### Connection

| Setting | Value |
|---------|-------|
| Listening Port | 59788 |
| Global max connections | 500 |
| Max connections per torrent | 100 |
| Global upload slots | 20 |
| Upload slots per torrent | 4 |

### BitTorrent

| Setting | Value |
|---------|-------|
| DHT | ❌ Disabled (prohibited by private trackers) |
| PeX | ❌ Disabled |
| Local Peer Discovery | ❌ Disabled |
| Anonymous Mode | ❌ Disabled (private trackers verify client identity) |
| Max active downloads | 5 |
| Max active uploads | 8 |
| Max active torrents | 15 |
| Do not count slow torrents | ✅ Enabled |
| Seeding limit | Ratio ≥ 2.0, then stop torrent |

**Privacy settings note**: DHT, PeX, and Local Peer Discovery are disabled globally because private trackers like MTV prohibit them. Torrents with the "private" flag disable these per-torrent anyway, but disabling globally is best practice.

### WebUI Authentication

| Setting | Value |
|---------|-------|
| Username | (custom, changed from default) |
| Bypass localhost | ❌ Disabled |
| Whitelisted subnets | 10.0.0.0/24, 100.64.0.0/10 |

The `/24` whitelist covers all LAN devices (including Radarr/Sonarr). The `100.64.0.0/10` range covers Tailscale CGNAT addresses for remote access without login prompts.

### Advanced

| Setting | Value |
|---------|-------|
| Network Interface | Any |

## Private Tracker Notes

**MoreThanTV (MTV)**:
- qBittorrent is an allowed client
- No hard ratio minimum, but community etiquette encourages seeding
- Current seeding limit set to ratio 2.0 (generous — gives back 2x what you download)
- **Do not enable**: Anonymous Mode, DHT, PeX, Local Peer Discovery
- Consider port forwarding peer port (59788) on USG for better connectivity

**Comcast data cap**: Seeding counts toward the ~1.28TB monthly cap. Monitor usage if downloading/seeding large volumes.

## Maintenance

### Container Management

From DB host:

```bash
# Check status
pct status 309

# Start/stop/restart
pct start 309
pct stop 309
pct reboot 309

# Access shell
pct enter 309
```

## Troubleshooting

### Downloads stuck / no peers

1. Check if the torrent has seeders on the tracker
2. Verify peer port (59788) — consider port forwarding on USG
3. Check container has internet: `pct enter 309` then `ping google.com`

### Radarr/Sonarr can't connect

1. Verify container is running: `pct status 309`
2. Check WebUI is accessible: `curl http://10.0.0.164:8090` from another container
3. Confirm IP whitelist includes the arr app IPs

### Disk space issues

```bash
pct enter 309
df -h /data
# df -h — shows disk usage in human-readable format
```

If space is low, check for completed+imported torrents that can be removed from qBit (Radarr/Sonarr hardlink the files, so deleting from qBit's download directory doesn't affect the library copy — unless it's actually the same inode, in which case the library file remains as long as one hardlink exists).

## Related

- [Prowlarr](prowlarr.md)
- [Radarr](radarr.md)
- [Sonarr](sonarr.md)
- [Plex](plex.md)
- [Storage Configuration](../storage.md)
- [Services Index](_services-index.md)
