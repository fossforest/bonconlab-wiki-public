# Plex

Media server for streaming movies and TV. Lifetime Plex Pass owned.

## Overview

| Property | Value |
|----------|-------|
| Node | DB (db) |
| LXC | 302 |
| IP | 10.0.0.194 |
| Tailscale IP | 100.77.192.67 |
| Port | 32400 |
| Storage | db-2tb-nvme (container OS), mergerfs virtual pool (media) |
| Status | ✅ Active |

## Access

| Method | URL |
|--------|-----|
| Local | http://10.0.0.194:32400/web |
| Tailscale | http://100.77.192.67:32400/web |

## Storage Architecture

Media is served from a mergerfs virtual pool combining three external drives:

| Drive | Filesystem | Mount |
|-------|-----------|-------|
| external-18tb-hdd | ext4 | Host: `/mnt/external-18tb-hdd/plex-media` |
| external-4tb-hdd-1 | exFAT | Host: `/mnt/external-4tb-hdd-1/plex-media` |
| external-4tb-hdd-2 | exFAT | Host: `/mnt/external-4tb-hdd-2/plex-media` |

- **Virtual pool**: Host `/mnt/virtual-media`, container mount `/mnt/media/all-content` (mp0)
- **Creation policy**: `mfs` (most free space) for automatic load balancing
- Only `plex-media` subdirectories are included in the pool; other data on these drives is out-of-pool
- **fstab source paths** (explicit, updated 2026-03-19): `/mnt/external-18tb-hdd/plex-media:/mnt/external-4tb-hdd-1/plex-media:/mnt/external-4tb-hdd-2/plex-media`
- **Boot resilience**: `nofail` flag and `x-systemd.requires=` dependencies on USB drive mount units prevent container startup failure if drives aren't ready at boot

## Future

- iGPU passthrough for hardware transcoding
- Jellyfin evaluation as an alternative/complement

## Related

- [Services Index](_services-index.md)
- [Storage Configuration](../storage.md)
- [Copyparty](copyparty.md)
