# Jellyfin

Open-source media server for streaming movies, TV shows, and music. Self-hosted alternative/complement to Plex with no account or subscription required.

## Overview

| Property | Value |
|----------|-------|
| Node | DB (db) |
| Type | LXC Container |
| Container ID | 311 |
| IP | 10.0.0.127 |
| Port | 8096 |
| Tailscale IP | 100.127.206.115 |
| Storage | db-2tb-nvme (container OS), mergerfs virtual pool (media) |
| Status | ✅ Active |

## Access

| Method | URL |
|--------|-----|
| Local | http://10.0.0.127:8096 |
| Tailscale (serve) | https://jellyfin.tail-scale.ts.net |

## Storage Architecture

Media is served from the same mergerfs virtual pool used by Plex, mounted into the container via a Proxmox bind mount.

| Mount | Host Path | Container Path | Purpose |
|-------|-----------|----------------|---------|
| mp0 | /mnt/virtual-media | /media | mergerfs pool (Movies, TV, Music) |

**Library paths** (configure in Jellyfin dashboard):
- `/media/Movies`
- `/media/TV`
- `/media/Music`

The mergerfs pool combines three external drives on the DB host:
- external-18tb-hdd (ext4)
- external-4tb-hdd-1 (exFAT)
- external-4tb-hdd-2 (exFAT)

See [Plex](plex.md) and [Storage Configuration](../storage.md) for full pool details.

## Installation

Installed via [official Jellyfin repository](https://jellyfin.org/docs/general/installation/linux) on Ubuntu 24.04 LXC.

## Configuration

- **Transcoding**: Software transcoding by default. Hardware transcoding requires iGPU passthrough (future).
- **Networking**: Listens on port 8096 (HTTP). Tailscale Serve provides HTTPS.
- **Users**: Create accounts in Dashboard → Users (no external auth service required).

## Maintenance

### Container Management

From DB host:

```bash
# Check status
pct status 311

# Start/stop/restart
pct start 311
pct stop 311
pct reboot 311

# Access shell
pct enter 311
```

### Service Management

Inside container:

```bash
# Check Jellyfin status
systemctl status jellyfin

# Restart
systemctl restart jellyfin

# View logs
journalctl -u jellyfin -f
```

## Troubleshooting

### Libraries empty or media not found

1. Verify the bind mount is active:
   ```bash
   pct enter 311
   ls /media/Movies
   ```
2. If empty, check the host mergerfs pool:
   ```bash
   ls /mnt/virtual-media/Movies
   ```
3. Verify the mount point in LXC config:
   ```bash
   cat /etc/pve/lxc/311.conf | grep mp
   ```

### Permission denied on media files

Container is unprivileged — root inside maps to a high UID on the host. If needed:
```bash
# On DB host, set open permissions on media directories
chmod -R 755 /mnt/virtual-media
```

### Transcoding failures

Software transcoding requires sufficient CPU. Check container resource allocation:
```bash
pct config 311 | grep -E 'cores|memory'
```

## Related

- [Plex](plex.md) — primary media server, shares the same media pool
- [Radarr](radarr.md) — automated movie downloads
- [Sonarr](sonarr.md) — automated TV downloads
- [NAS / Fileshare](nas-fileshare.md) — central storage gateway
- [Storage Configuration](../storage.md)
- [Services Index](_services-index.md)
