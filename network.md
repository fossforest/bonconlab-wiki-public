# Network Configuration

Network topology, IP assignments, and device locations for BonConLab.

## IP Assignments

**Subnet**: 10.0.0.0/24  
**Gateway**: 10.0.0.1  
**DHCP Range**: 10.0.0.16 - 10.0.0.254  
**Static Range**: 10.0.0.2 - 10.0.0.15

| IP | Hostname | Device | Location |
|----|----------|--------|----------|
| 10.0.0.1 | — | USG-3P (Gateway) | 1st Floor |
| 10.0.0.2 | sb.local | SB (Proxmox) | Homelab closet |
| 10.0.0.3 | tmg.local | TMG (Proxmox) | Homelab closet |
| 10.0.0.4 | db.local | DB (Proxmox) | Homelab closet |
| 10.0.0.5 | dp.local | DP (Proxmox) | Homelab closet |
| 10.0.0.10 | pihole-tmg | PiHole Primary (TMG LXC 103) | TMG |
| 10.0.0.140 | tmg-mirror-manager | Mirror Manager (LXC 111) | TMG |
| 10.0.0.152 | pve-scripts-local | PVE Scripts Local (LXC 116) | TMG |
| 10.0.0.160 | sb-manyfold | Manyfold (LXC 203) | SB |
| 10.0.0.192 | sb-actualbudget | Actual Budget (LXC 201) | SB |
| 10.0.0.194 | db-plex | Plex (LXC 302) | DB |
| 10.0.0.196 | sb-paperless | Paperless-ngx (LXC 202) | SB |
| 10.0.0.197 | tmg-homepage | Homepage (LXC 107) | TMG |
| 10.0.0.179 | rustdeskserver | RustDesk Server (LXC 108) | TMG |
| 10.0.0.181 | forgejo | Forgejo Git Server (LXC 104) | TMG |
| 10.0.0.185 | tmg-it-tools-alpine | IT Tools (LXC 110) | TMG |
| 10.0.0.229 | — | PiHole Backup (Pi 3) | Homelab closet |
| 10.0.0.250 | — | Unifi Controller (LXC 100) | SB |
| 10.0.0.161 | db-prowlarr | Prowlarr (LXC 306) | DB |
| 10.0.0.162 | db-radarr | Radarr (LXC 307) | DB |
| 10.0.0.163 | db-sonarr | Sonarr (LXC 308) | DB |
| 10.0.0.164 | db-qbittorrent | qBittorrent (LXC 309) | DB |
---

## DNS Configuration

**DNS Servers**: PiHole active-active with Unbound recursive resolution  
**Access Method**: Via Tailscale only (opt-in ad-blocking)

### PiHole Deployment

Primary and backup DNS servers for network-wide ad-blocking:

| Role | IP | Hardware | Location | Status |
|------|-----|----------|----------|--------|
| Primary DNS | 10.0.0.10 | TMG LXC Container 103 | TMG node | ✅ Active |
| Backup DNS | 10.0.0.229 | Raspberry Pi 3 Model B | Homelab closet | ✅ Active |

**Architecture**: Active-active configuration where both servers handle queries simultaneously. Configured via Tailscale DNS for automatic failover.

**Unbound Configuration:**
- **Primary (TMG)**: Full recursive DNS resolver - queries root servers directly
- **Backup (Pi3)**: DNS-over-TLS forwarding to Quad9 - lighter resource usage

**Upstream DNS** (when not using PiHole):
- USG uses 1.1.1.1 (Cloudflare) and 8.8.8.8 (Google) for its own queries
- Local devices not on Tailscale use ISP/default DNS

**Tailscale Integration:**
- Nameservers configured in Tailscale admin console: 10.0.0.10, 10.0.0.229
- Override local DNS enabled
- Only devices connected to Tailscale use PiHole
- Easy toggle for troubleshooting and guest mode

**See**: [PiHole Documentation](services/pihole.md) for full setup details.

---

## Network Topology

```
Internet
    │
Comcast Modem (bridge mode)
    │
USG-3P (Gateway) ─────────────────────────── 10.0.0.1
    │
USW-Flex-2.5G-5-PoE ─────────────────────── 1st Floor
    ├── PlayStation 5
    ├── Apple TV
    ├── Television
    ├── Zigbee PoE Coordinator
    │
    ├── USW-Flex-2.5G-8-PoE ─────────────── Upstairs (Homelab Closet)
    │       ├── SB (Proxmox) ─────────────── 10.0.0.2
    │       ├── TMG (Proxmox) ────────────── 10.0.0.3
    │       ├── DB (Proxmox, 2.5G) ───────── 10.0.0.4
    │       ├── DP (Proxmox + HAOS VM) ─ 10.0.0.5
    │       ├── JetKVM
    │       ├── Unifi AC Pro
    │       ├── Desk (hardwire)
    │       │
    │       └── Netgear GS208
    │               ├── Pi 4 (Packing Assistant)
    │               ├── Pi 3 (PiHole Backup) ─ 10.0.0.229
    │               └── Philips Hue Bridge
    │
    └── USW-Flex-2.5G-5-PoE ─────────────── Garage
            ├── Unifi AC Pro
            ├── Desk (hardwire)
            ├── Doorbell Camera (PoE)
            ├── Garage Camera (PoE)
            └── Prusa Core One
```

---

## VLANs

*Not currently configured. Future consideration for IoT isolation.*

---

## Switch Details

| Switch | Model | Ports | Location | Uplink To |
|--------|-------|-------|----------|-----------|
| Main | USW-Flex-2.5G-5-PoE | 5x 2.5G PoE | 1st Floor | USG-3P |
| Homelab | USW-Flex-2.5G-8-PoE | 8x 2.5G PoE | Upstairs closet | Main switch |
| Garage | USW-Flex-2.5G-5-PoE | 5x 2.5G PoE | Garage | Main switch |
| Overflow | Netgear GS208 | 8x 1G | Upstairs closet | Homelab switch |

---

## Wireless

| AP | Model | Location | SSID |
|----|-------|----------|------|
| Upstairs | Unifi AC Pro | Homelab closet | *TBD* |
| Garage | Unifi AC Pro | Garage | *TBD* |

### IoT WiFi Network

Dedicated 2.4GHz-only network for IoT devices:
- **Band**: 2.4GHz only
- **Legacy support**: Enabled
- **Purpose**: Compatibility with devices that don't handle dual-band networks well

---

## Cabling Notes

- All RJ45 runs are Cat6 or better
- No cable run exceeds 100ft
- **Full 2.5G Backbone**: SB, TMG, and DB are linked at 2.5GbE. DP is 1GbE only (NUC board limitation).

---

## **Known Limitations**

- **USG-3P throughput**: Tops out ~850Mbps (less with IDS/IPS enabled). This is now the primary bottleneck in the system.
- **USB Network Adapters**: SB and TMG rely on USB 3.0 adapters for 2.5G speeds. These require `ethtool` persistence scripts to prevent power-saving disconnects.