# BonConLab

Personal homelab documentation and wiki.

## Overview

BonConLab is a 4-node Proxmox cluster with supporting infrastructure for self-hosting, home automation, and media management. This wiki documents hardware, network topology, services, and operational procedures.

## Quick Links

- [Hardware Inventory](hardware.md)
- [Network & IP Assignments](network.md)
- [Storage Configuration](storage.md)
- [Home Assistant](home-assistant.md)
- [Services Index](services/_services-index.md)
- [Maintenance Procedures](maintenance.md)
- [Changelog](changelog.md)

### Tools

- [Button Automation Generator](services/button-automation-generator.md) - Generate YAML templates for HA button automations

## Infrastructure Summary

| Component | Details |
|-----------|---------|
| Cluster | 4-node Proxmox (SB, TMG, DB, DP) |
| Home Automation | Home Assistant OS (VM 401 on DP) |
| IoT Protocol | Zigbee via PoE coordinator + Zigbee2MQTT |
| Gateway | Ubiquiti USG-3P |
| DNS | PiHole active-active (TMG LXC + Pi 3) with Unbound |
| VPN | Tailscale subnet routing on TMG |
| Storage | ~3TB fast (NVMe/SSD), ~4TB internal HDD, ~26TB external backup |

## Guiding Principles

- **Local-first**: Self-host where practical, minimize cloud dependencies
- **Simplicity over cleverness**: Prefer well-documented, community-supported tools
- **Document as you go**: If it's not documented, it didn't happen

## Node Quick Reference

| Node | Hostname | IP | Role |
|------|----------|-----|------|
| SB | sb.local | 10.0.0.2 | Proxmox (primary) |
| TMG | tmg.local | 10.0.0.3 | Proxmox (lightweight services) |
| DB | db.local | 10.0.0.4 | Proxmox (storage-heavy workloads) |
| DP | dp.local | 10.0.0.5 | Proxmox + HAOS VM (VM 401) |
| Pi 3 | — | 10.0.0.229 | PiHole backup DNS |

## Web UIs

- **SB Proxmox**: https://10.0.0.2:8006
- **TMG Proxmox**: https://10.0.0.3:8006
- **DB Proxmox**: https://10.0.0.4:8006
- **DP Proxmox**: https://10.0.0.5:8006
- **Home Assistant**: http://homeassistant.local:8123 (VM 401 on DP)
- **Unifi Controller**: https://10.0.0.250:8443
- **Nginx Proxy Manager**: http://10.0.0.238:81
- **Local Tools**: http://10.0.0.238/tools/
- **PiHole Primary**: http://10.0.0.10/admin
- **PiHole Backup**: http://10.0.0.229/admin
