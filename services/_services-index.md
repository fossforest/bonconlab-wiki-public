# **Services Index**

Index of all services running in BonConLab. Each service has its own documentation page.

## **Active Services**

| Service | Node | Type | Port | Status | Docs |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Zensical | DB | Docker (Sidecar) | 8000 | ✅ Active | [Zensical](zensical.md) |
| Home Assistant | DP (VM 401) | VM | 8123 | ✅ Active | [Home Assistant](../home-assistant.md) |
| Zigbee2MQTT | DP (HA add-on) | Add-on | — | ✅ Active | [Zigbee2MQTT](zigbee2mqtt.md) |
| Unifi Controller | SB (LXC 100\) | Container | 8443 | ✅ Active | [Unifi](unifi.md) |
| Manyfold | SB (LXC 203\) | Container | 3214 | ✅ Active | [Manyfold](manyfold.md) |
| Paperless-ngx | SB (LXC 202\) | Container | 8000 | ✅ Active | [Paperless-ngx](paperless-ngx.md) |
| Actual Budget | SB (LXC 201\) | Container | 5006 | ✅ Active | [Actual Budget](actual-budget.md) |
| Tailscale | TMG (LXC 102\) | Container | — | ✅ Active | [Tailscale](tailscale.md) |
| PiHole Primary | TMG (LXC 103\) | Container | 80, 53 | ✅ Active | [PiHole](pihole.md) |
| Forgejo | TMG (LXC 104\) | Container | 3000 | ✅ Active | [Forgejo](forgejo.md) |
| Homepage | TMG (LXC 107\) | Container | 3000 | ✅ Active | [Homepage](homepage.md) |
| Label Icon Generator | TMG (LXC 105\) | Container | — | ✅ Active | — |
| APT Cacher NG | TMG (LXC 106\) | Container | — | ✅ Active | — |
| RustDesk Server | TMG (LXC 108\) | Container | 21114, 21115–21117 | ✅ Active | [RustDesk Server](rustdesk-server.md) |
| Vaultwarden | TMG (LXC 109\) | Container | — | ✅ Active | — |
| IT Tools | TMG (LXC 110\) | Container | — | ✅ Active | [IT Tools](it-tools.md) |
| Mirror Manager | TMG (LXC 111\) | Container | 3850 | ✅ Active | [Mirror Manager](mirror-manager.md) |
| CV Updater | TMG (LXC 112\) | Container | 3737 | ✅ Active | [CV Updater](cv-updater.md) |
| PVE Scripts Local | TMG (LXC 116\) | Container | 3000 | ✅ Active | [PVE Scripts Local](pve-scripts-local.md) |
| Nebula Sync | TMG (Docker in LXC 103\) | Docker | — | ✅ Active | [Nebula Sync](nebula-sync.md) |
| PiHole Backup | Pi 3 | Bare metal | 80, 53 | ✅ Active | [PiHole](pihole.md) |
| Proxmox Backup Server | DB (LXC 301\) | Container | 8007 | ✅ Active | [Proxmox Backup Server](proxmox-backup-server.md) |
| Plex | DB (LXC 302\) | Container | 32400 | ✅ Active | [Plex](plex.md) |
| Copyparty | DB (LXC 304\) | Container | 3923 | ✅ Active | [Copyparty](copyparty.md) |
| Prowlarr | DB (LXC 306) | Container | 9696 | ✅ Active | [Prowlarr](prowlarr.md) |
| Radarr | DB (LXC 307) | Container | 7878 | ✅ Active | [Radarr](radarr.md) |
| Sonarr | DB (LXC 308) | Container | 8989 | ✅ Active | [Sonarr](sonarr.md) |
| qBittorrent | DB (LXC 309) | Container | 8090 | ✅ Active | [qBittorrent](qbittorrent.md) |
| NAS / Fileserver | DB | Container | — | ✅ Active | [NAS / Fileshare](nas-fileshare.md) |
| Ollama | Mac Mini M4 | macOS LaunchAgent | 11434 | ✅ Active | [Ollama](ollama.md) |
| Open WebUI | SB (LXC 204) | Docker in LXC | 3000 | 🔧 Planned | [Open WebUI](open-webui.md) |

## **Planned Services**

| Service | Target Node | Purpose | Priority |
| :---- | :---- | :---- | :---- |
| Jellyfin | DB | Media streaming (alternative to Plex) | Low |
| Syncthing | TBD | File synchronization | Medium |
| Immich | DB | Photo management | Medium |

## **Tools**

| Tool | Location | Purpose | Docs |
| :---- | :---- | :---- | :---- |
| Button Automation Generator | http://10.0.0.238/tools/ | Generate YAML templates for HA button automations | [Documentation](button-automation-generator.md) |
| wiki-info | bonconlab-scripts (Forgejo) | Gather container info for wiki documentation | [LXC Deploy Workflow](lxc-deploy-workflow.md) |

## **Service Documentation Template**

When adding a new service, create a file in /services/ using this template:

\# Service Name

Brief description of what this service does.

\#\# Overview

| Property | Value |  
|----------|-------|  
| Node | Where it runs |  
| Type | VM / LXC / Docker / Add-on |  
| IP | If static |  
| Port | Web UI or service port |  
| Storage | Which datastore |  
| Status | Active / Stopped / Testing |

\#\# Installation

Steps taken to install, including commands.

\#\# Configuration

Key configuration files and settings.

\#\# Maintenance

Update procedures, backup notes.

\#\# Troubleshooting

Common issues and fixes.

\#\# Related

\- \[Other relevant docs\](other-doc.md)

## **Services by Node**

### **DP**

* [Home Assistant](../home-assistant.md) (VM 401)
* [Zigbee2MQTT](zigbee2mqtt.md) (HA add-on)

### **SB (sb)**

* [Unifi Controller](unifi.md) (LXC 100\)
* [Actual Budget](actual-budget.md) (LXC 201\)
* [Paperless-ngx](paperless-ngx.md) (LXC 202\)
* [Manyfold](manyfold.md) (LXC 203\)

### **TMG (tmg)**

* [Tailscale](tailscale.md) (LXC 102\)
* [PiHole Primary](pihole.md) (LXC 103\)
* [Nebula Sync](nebula-sync.md) (Docker in LXC 103\)
* [Forgejo](forgejo.md) (LXC 104\)
* Label Icon Generator (LXC 105\)
* APT Cacher NG (LXC 106\)
* [Homepage](homepage.md) (LXC 107\) — webhook listener on port 9000 for GitOps deploys
* [RustDesk Server](rustdesk-server.md) (LXC 108\)
* Vaultwarden (LXC 109\)
* [IT Tools](it-tools.md) (LXC 110\)
* [Mirror Manager](mirror-manager.md) (LXC 111\) — webhook listener on port 9000 for GitOps deploys
* [CV Updater](cv-updater.md) (LXC 112\) — webhook listener on port 9000 for GitOps deploys
* [PVE Scripts Local](pve-scripts-local.md) (LXC 116\)

### **DB (db)**

* [Proxmox Backup Server](proxmox-backup-server.md) (LXC 301\)
* [Plex](plex.md) (LXC 302\)
* [Copyparty](copyparty.md) (LXC 304\)
* [NAS / Fileserver](nas.md) (*Pending Setup*)
* [Zensical](zensical.md) (Docker Sidecar) — webhook listener on port 9000 for GitOps
* [Prowlarr](prowlarr.md) (LXC 306)
* [Radarr](radarr.md) (LXC 307)
* [Sonarr](sonarr.md) (LXC 308)
* [qBittorrent](qbittorrent.md) (LXC 309)   

### **Mac Mini M4**

* [Ollama](ollama.md) — local LLM inference (gemma4:e4b)

### **Raspberry Pi 3**

* [PiHole Backup](pihole.md)

## **Notes**

* Prefer LXC containers over full VMs for Linux services (lower overhead)  
* Use Docker within LXC sparingly — native LXC or VM is often cleaner  
* Document every service as it's deployed
