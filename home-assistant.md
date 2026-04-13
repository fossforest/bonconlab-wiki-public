# Home Assistant

Home automation hub for BonConLab. Runs as a Proxmox VM on DP with Zigbee as the primary IoT protocol.

## Overview

| Property | Value |
|----------|-------|
| Host | DP (Proxmox node, 10.0.0.5) |
| Install Type | Home Assistant OS (Proxmox VM, ID 401) |
| IP | 10.0.0.159 (homeassistant.local) |
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
| go2rtc | Camera stream handling | ✅ Active |
| Advanced SSH & Web Terminal | SSH access to HAOS | ✅ Active |
| Git pull | Pull config from Forgejo on webhook | ✅ Active |

## Detailed Documentation
 
| Topic | Description |
|-------|-------------|
| [go2rtc](home-assistant/go2rtc.md) | Camera stream handling, rotation, RTSP proxy |
| [Cameras](home-assistant/cameras.md) | Camera entities, dashboard cards, hardware |
| [Zigbee2MQTT](home-assistant/zigbee2mqtt.md) | Zigbee device management via MQTT |

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

## Version Control (GitOps)

HA config is tracked in git and backed up to Forgejo (`alex/homeassistant-config`). MCP is the primary editing tool — git serves as a safety net and backup, not the source of truth.

### Architecture

Two directions:

1. **HAOS → Forgejo (primary)**: Nightly auto-commit + push at 2 AM via `ha-git-push` script. Can also be run manually before/after MCP sessions for snapshots.
2. **Forgejo → HAOS (secondary)**: A push to the Forgejo repo triggers a webhook → HA automation → Git pull add-on → config check → auto-restart. Used for the occasional Mac-side YAML edit.

### Components

| Component | Purpose |
|-----------|---------|
| `ha-git-push` | Script in bonconlab-scripts. Auto-commits and pushes `/config` to Forgejo. Self-updates from Forgejo, fetches credentials at runtime from `secrets/forgejo.env` |
| Git pull add-on (`core_git_pull`) | Pulls from Forgejo, validates config, restarts HA if valid. Webhook-triggered (no polling) |
| Automation: "GitOps: Pull config on Forgejo push" | Webhook trigger (`forgejo_git_pull`, local_only). Starts the Git pull add-on |
| Automation: "GitOps: Nightly auto-commit and push config" | 2 AM daily. Calls `shell_command.git_commit_and_push` |
| Forgejo webhook | On `homeassistant-config` push, POSTs to `http://10.0.0.159:8123/api/webhook/forgejo_git_pull` |

### Manual snapshot workflow

```bash
ssh hassio@homeassistant.local
ha-git-push "Pre-session snapshot"   # before MCP work
# ... do work ...
ha-git-push "Post-session: added X"  # after MCP work
```

### Mac clone

A clone of the repo exists at `/Users/alex-m4mini/homeassistant-config` for Mac-side edits. Push from Mac → Forgejo webhook → HA pulls and reloads.

### What's tracked vs. ignored

See `.gitignore` in the repo. Key exclusions: `secrets.yaml`, databases (`*.db`), `.storage/`, `.cloud/`, `.cache/`, `backups/`, HACS-managed files (`custom_components/`, `hacs_frontend/`, `www/community/`), logs. Key inclusions: all YAML config, `image/` (area pictures), `zigbee2mqtt/configuration.yaml`, `blueprints/`, `scripts/`.

## Claude Code + MCP

Home Assistant is connected to Claude Code via [ha-mcp](https://github.com/homeassistant-ai/ha-mcp). This allows Claude to directly manage HA entities, automations, dashboards, scripts, add-ons, and more without SSH.

MCP is the primary tool for config changes. Git version control (above) provides the safety net.

## Backup

Home Assistant backups are managed through the UI:
1. Settings → System → Backups
2. Create backup before major changes
3. Download backups periodically to external storage

Git version control to Forgejo provides a secondary backup of all YAML configuration (see Version Control section above).

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
