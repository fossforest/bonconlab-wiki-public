# Unifi Network Controller

Centralized management for Ubiquiti network devices (USG, switches, APs).

## Overview

| Property | Value |
|----------|-------|
| Node | SB (sb) |
| Type | LXC Container |
| IP | 10.0.0.250 |
| Port | 8443 (HTTPS) |
| Storage | local-zfs |
| Status | Active |

## Access

- **Web UI**: https://10.0.0.250:8443
- **Inform URL**: http://10.0.0.250:8080/inform

## Managed Devices

| Device | Model | Location |
|--------|-------|----------|
| Gateway | USG-3P | 1st Floor |
| Main Switch | USW-Flex-2.5G-5-PoE | 1st Floor |
| Homelab Switch | USW-Flex-2.5G-8-PoE | Upstairs closet |
| Garage Switch | USW-Flex-2.5G-5-PoE | Garage |
| Upstairs AP | Unifi AC Pro | Homelab closet |
| Garage AP | Unifi AC Pro | Garage |

## Installation

Installed via community helper script:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/unifi.sh)"
```

This created a Debian LXC container with MongoDB and the Unifi Network Application.

## Migration History

Migrated from macOS laptop to Proxmox LXC on 2024-11-23:

1. Exported backup from laptop controller (Settings → System → Backup)
2. Created LXC on SB using community script
3. Restored backup on new controller
4. Used built-in migration function to re-adopt devices
5. Reserved IP (10.0.0.250) in DHCP settings

## Maintenance

### Updates

Updates are applied through the Unifi web UI:
Settings → System → Updates

### Backup

Automatic backups are enabled by default. Manual backups:
Settings → System → Backup → Download Backup

Backups are stored in the container at:
`/var/lib/unifi/backup/`

### Container Management

From SB shell:

```bash
# Check container status
pct status 100

# Start/stop/restart
pct start 100
pct stop 100
pct reboot 100

# Access container shell
pct enter 100
```

## Troubleshooting

### Devices not adopting

SSH to the device and set inform URL manually:

```bash
ssh ubnt@<device-ip>
set-inform http://10.0.0.250:8080/inform
```

### Controller not accessible

1. Check container is running: `pct status 100`
2. Check network: `pct enter 100` then `ip a`
3. Check service: `pct enter 100` then `systemctl status unifi`

### MongoDB issues

The Unifi controller depends on MongoDB. If having issues:

```bash
pct enter 100
systemctl status mongod
journalctl -u mongod -n 50
```

## Related

- [Network Configuration](../network.md)
- [Hardware Inventory](../hardware.md)
