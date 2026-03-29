# RustDesk Server

Self-hosted RustDesk relay and rendezvous server for faster, private remote desktop connections.

## Overview

| Property | Value |
|----------|-------|
| Node | TMG (tmg) |
| Type | LXC Container |
| Container ID | 108 |
| IP | 10.0.0.179 (reserved in Unifi as "tmg-rustdeskserver") |
| Tailscale IP | 100.71.227.113 |
| Tailscale Hostname | rustdeskserver.tail-scale.ts.net |
| OS | Debian 13 (Trixie) |
| Storage | local-zfs |
| Status | ✅ Active |

## Services

Three systemd services run in the container:

| Service | Binary | Purpose | Port |
|---------|--------|---------|------|
| rustdesk-hbbs | hbbs | ID/rendezvous server — helps clients find each other | 21115, 21116 |
| rustdesk-hbbr | hbbr | Relay server — proxies traffic when direct connection isn't possible | 21117 |
| rustdesk-api | rustdesk-api | Web admin panel — manage users, address books, devices | 21114 |

## Access

- **Admin Web UI**: http://10.0.0.179:21114
- **Admin Username**: admin

## Public Key

Required when configuring RustDesk clients:

```
6+z3naLXVUNWXzw96s6b8dfKPDgOyaRcmaS37YUwN6M=
```

## Client Configuration

On each RustDesk client (Settings → Network → ID/Relay Server):

| Field | Value |
|-------|-------|
| ID Server | 10.0.0.179 |
| Relay Server | 10.0.0.179 |
| API Server | http://10.0.0.179:21114 |
| Key | 6+z3naLXVUNWXzw96s6b8dfKPDgOyaRcmaS37YUwN6M= |

**Note**: Local IP (10.0.0.179) is used intentionally — works on the local network without Tailscale, and works remotely when connected to the tailnet via subnet routing.

## Installation

Installed 2026-02-21 via community helper script on TMG:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/rustdesk-server.sh)"
```

Installed versions:
- rustdesk-server-hbbs: 1.1.15
- rustdesk-server-hbbr: 1.1.15
- rustdesk-server-utils: 1.1.15
- rustdesk-api-server: 2.7

**Note**: The community script sets services as enabled but does not start them (runs in a chroot where systemd is unavailable). Start them manually after install:

```bash
systemctl start rustdesk-hbbs
systemctl start rustdesk-hbbr
systemctl start rustdesk-api
```

The public key is generated on first start of `hbbs` and stored at:
`/var/lib/rustdesk-server/id_ed25519.pub`

## Tailscale

Tailscale is installed in the container for remote access to the admin panel and as a fallback access method.

```bash
# Check Tailscale status
tailscale status

# Get Tailscale IP
tailscale ip -4
```

## Maintenance

### Container Management

From TMG host:

```bash
# Check status
pct status 108

# Start/stop/reboot
pct start 108
pct stop 108
pct reboot 108

# Enter container shell
pct enter 108
```

### Check Service Status

Inside the container:

```bash
systemctl status rustdesk-hbbs rustdesk-hbbr rustdesk-api
```

### Reset Admin Password

If locked out of the web UI (avoid special shell characters like `;`, `'`, `"`):

```bash
pct enter 108
rustdesk-api reset-admin-pwd yournewpassword
```

### View Key

```bash
pct enter 108
cat /var/lib/rustdesk-server/id_ed25519.pub
```

### Update

```bash
pct enter 108
apt update && apt upgrade -y
```

## Troubleshooting

### Services not running after reboot

The install script doesn't start services in the chroot environment. Check and start manually:

```bash
pct enter 108
systemctl status rustdesk-hbbs
systemctl start rustdesk-hbbs rustdesk-hbbr rustdesk-api
```

### Web UI not accessible

1. Check container is running: `pct status 108`
2. Check `rustdesk-api` service: `systemctl status rustdesk-api`
3. Verify port 21114 is listening: `ss -tlnp | grep 21114`

### Client can't connect

1. Verify all three services are running
2. Confirm client has correct IP and key
3. Test connectivity: `ping 10.0.0.179` from client device
4. Check firewall: `iptables -L` (should be open by default in LXC)

### Captcha lockout on web UI

Triggered by multiple failed login attempts. Reboot the container to clear:

```bash
pct reboot 108
```

## File Locations

| Path | Purpose |
|------|---------|
| /var/lib/rustdesk-server/ | Key files (id_ed25519, id_ed25519.pub) |
| /var/lib/rustdesk-api/data/rustdeskapi.db | API server SQLite database |
| /usr/lib/systemd/system/rustdesk-hbbs.service | hbbs service definition |
| /usr/lib/systemd/system/rustdesk-hbbr.service | hbbr service definition |
| /usr/lib/systemd/system/rustdesk-api.service | API service definition |

## Related

- [Tailscale](tailscale.md)
- [Network Configuration](../network.md)
- [Services Index](_services-index.md)
