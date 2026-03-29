# Copyparty

Fast, lightweight file server for network file transfers and sharing.

## Overview

| Property | Value |
|----------|-------|
| Node | DB (db) |
| Type | LXC Container |
| Container ID | 304 |
| Local IP | 10.0.0.191 |
| Local Port | 3923 |
| Tailscale URL | https://db-copyparty.tail-scale.ts.net/ |
| Storage | db-2tb-nvme (8GB) |
| Status | ✅ Active |

## Access

- **Local Network**: http://10.0.0.191:3923
- **Remote (Tailscale)**: https://db-copyparty.tail-scale.ts.net/
- **SSH**: `ssh root@db-copyparty` (via Tailscale)

## Served Volumes

| Volume | Mount Point | Description |
|--------|-------------|-------------|
| /db-2tb-warm-zfs-mirror/ | /db-2tb-warm | Backup storage (ZFS mirror) |
| /db-nas-cold-pool/ | /db-nas-cold-pool | Cold storage (mergerfs pool) |
| /db-nas-media-pool/ | /db-nas-media-pool | Media storage (mergerfs pool) |

## Installation

Deployed via community helper script on 2026-02-06:

```bash
# Created container with bind mounts
pct create 304 local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst \
  --hostname db-copyparty \
  --memory 1024 \
  --cores 2 \
  --rootfs db-2tb-nvme:8 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --onboot 1 \
  --features nesting=1

# Installed Copyparty via community script
# Configured Tailscale with serve
```

**Container Configuration:**

Added mount points for storage pools in `/etc/pve/lxc/304.conf`:
- `mp0`: /db-2tb-warm → /db-2tb-warm (Backup storage)
- `mp1`: /mnt/pve/db-nas-cold-pool → /db-nas-cold-pool (Cold storage)
- `mp2`: /mnt/pve/db-nas-media-pool → /db-nas-media-pool (Media storage)

## Configuration

**Config file**: `/etc/copyparty.conf`

Authentication is disabled (`rw: *` for all volumes) for ease of use on trusted network.

```ini
[global]
  p: 3923
  ansi
  e2dsa
  e2ts
  theme: 2
  grid
  no-robots
  force-js
  lo: /var/log/copyparty/cpp-%Y-%m%d.txt.xz

[/]
  /var/lib/copyparty
  accs:
    rw: *

[/warm]
  /db-2tb-warm
  accs:
    rw: *

[/cold]
  /db-nas-cold-pool
  accs:
    rw: *

[/media]
  /db-nas-media-pool
  accs:
    rw: *
```

**Edit configuration:**
```bash
pct enter 304
nano /etc/copyparty.conf
```

**Restart after changes:**
```bash
systemctl restart copyparty
```

## Tailscale Serve

Copyparty is exposed via Tailscale's HTTPS proxy:

```bash
tailscale serve --bg 3923
# tailscale serve — Proxies local port through Tailscale with automatic HTTPS
# --bg — Runs in background, persists across reboots
# 3923 — Local Copyparty port
```

**Check serve status:**
```bash
tailscale serve status
```

## Maintenance

### Container Management

From DB host:

```bash
# Check status
pct status 304

# Start/stop/restart
pct start 304
pct stop 304
pct reboot 304

# Access shell
pct enter 304
```

### Service Management

Inside container:

```bash
# Check Copyparty status
systemctl status copyparty

# Restart service
systemctl restart copyparty

# View logs
journalctl -u copyparty -n 50
# journalctl — Query systemd journal logs
# -u [service] — Filter by service unit
# -n [count] — Show last N lines
```

### Updates

```bash
pct enter 304

# Update Copyparty
pip3 install --upgrade --break-system-packages copyparty
# pip3 install --upgrade — Updates package to latest version
# --break-system-packages — Required flag on Debian 12 to install outside venv

# Restart service
systemctl restart copyparty
```

## Troubleshooting

### Service won't start

```bash
# Check logs
journalctl -u copyparty -xe
# -x — Add explanatory help text
# -e — Jump to end of logs

# Verify config syntax
copyparty --test-config /etc/copyparty.conf
```

### Can't access volumes

Verify bind mounts are accessible:
```bash
ls -la /db-2tb-warm
ls -la /db-nas-cold-pool
ls -la /db-nas-media-pool
# ls -la — Lists all files with detailed permissions
# -l — Long format with permissions
# -a — Shows hidden files
```

If mounts are empty, check host paths exist:
```bash
# From DB host
ls -la /db-2tb-warm
ls -la /mnt/pve/db-nas-cold-pool
ls -la /mnt/pve/db-nas-media-pool
```

### Tailscale serve not working

```bash
# Check serve status
tailscale serve status

# Restart serve
tailscale serve off
tailscale serve --bg 3923
```

### Upload fails

Check disk space:
```bash
df -h
# df -h — Shows disk usage in human-readable format
```

Verify write permissions on mount points.

## Related

- [Storage Configuration](../storage.md)
- [Services Index](_services-index.md)
- [Tailscale](tailscale.md)
