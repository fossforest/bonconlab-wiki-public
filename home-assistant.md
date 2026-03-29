# Home Assistant

Home automation hub for BonConLab. Runs as a Proxmox VM on DP with Zigbee as the primary IoT protocol.

## Overview

| Property | Value |
|----------|-------|
| Host | DP (Proxmox node, 10.0.0.5) |
| Install Type | Home Assistant OS (Proxmox VM, ID 401) |
| IP | DHCP (homeassistant.local) |
| Port | 8123 |
| Status | Active |

## Access

- **Web UI**: http://homeassistant.local:8123

## VM Specs (VM 401 — haos-vm)

| Setting | Value |
|---------|-------|
| VM ID | 401 |
| Hostname | haos-vm |
| Machine Type | q35 |
| BIOS | OVMF (UEFI) |
| CPU Model | KVM64 (for cross-node migration compatibility) |
| CPU Cores | 2 |
| RAM | 10240 MiB (10GB) |
| Disk | 64GB on local-zfs |
| Network | VirtIO on vmbr0 |
| MAC | 02:AE:1A:58:C1:91 |
| Start at boot | Yes |
| Storage | local-zfs (on DP) |

## Migration History

**2026-03-01**: Migrated from bare metal (old Datto hardware) to Proxmox VM on DP.

Migration steps:
1. Created HAOS VM on SB using community helper script (advanced settings)
2. Created full backup from existing bare metal HAOS on old Datto
3. Started VM on SB, restored backup via HAOS onboarding wizard
4. Installed Proxmox on DP (NUC7i5DNBE board), joined cluster
5. Migrated VM to DP: `qm migrate 401 dp --targetstorage local-zfs`
6. Verified HA and all integrations/add-ons working after migration

All add-ons (Zigbee2MQTT, File Editor) and integrations (Broadlink, Z2M) migrated intact via backup/restore.

## Add-ons

| Add-on | Purpose | Status |
|--------|---------|--------|
| Zigbee2MQTT | Zigbee device management | ✅ Active |
| File Editor | Edit config files in browser | ✅ Active |

## Integrations

| Integration | Purpose | Devices |
|-------------|---------|---------|
| Broadlink | IR control | RM4 Mini (living room AC) |
| Zigbee2MQTT | Zigbee devices | Various sensors, lights |

## Automations

### Living Room AC Control

Controls living room AC via Broadlink RM4 Mini IR blaster.

**Scripts**:
- `ac_on` — Turn AC on
- `ac_off` — Turn AC off
- Additional scripts as needed for temperature/mode control

## WiFi Network

IoT devices connect to dedicated 2.4GHz network:
- **SSID**: (your IoT network name)
- **Band**: 2.4GHz only
- **Compatibility**: Legacy support enabled

This prevents issues with devices that don't handle dual-band networks well.

## Backup

Home Assistant backups are managed through the UI:
1. Settings → System → Backups
2. Create backup before major changes
3. Download backups periodically to external storage

## Maintenance

### Updates

1. Settings → System → Updates
2. Review release notes before updating
3. Create backup before major updates

### Restart

Settings → System → Restart

Or via SSH:
```bash
ha core restart
```

## Troubleshooting

### Device not connecting

1. Verify device is on correct WiFi network (IoT 2.4GHz network)
2. Check integration logs: Settings → System → Logs
3. Restart the integration or Home Assistant

### Zigbee device not pairing

1. Put device in pairing mode
2. In Zigbee2MQTT, enable "Permit Join"
3. Check Zigbee2MQTT logs for errors
4. Try moving device closer to coordinator during pairing

## Related

- [Hardware Inventory](hardware.md)
- [Network Configuration](network.md)
- [Services Index](services/_services-index.md)
