# BonConLab Memory

## Overview
**BonConLab** is Alex's 4-node Proxmox homelab on the `10.0.0.0/24` subnet. Self-hosts home automation, media, productivity, and dev infrastructure. Guiding principles:

- **Local-first** — self-host where practical, minimize cloud dependencies
- **Simplicity over cleverness** — prefer well-documented, community-supported tools
- **Document as you go** — "if it's not documented, it didn't happen"

Wiki lives at `alex/bonconlab-wiki` on internal Forgejo (`10.0.0.181:3000` on-LAN, `http://forgejo:3000/` over Tailscale). Query it on demand for specs, IPs, runbooks.

## Nodes
| Short | Hostname | Role | Intentional quirks |
|-------|----------|------|--------------------|
| **SB** | sb | Primary Proxmox — newest hardware, best CPU. Hosts Unifi, Open WebUI, Karakeep, Paperless, Actual Budget, Manyfold | — |
| **TMG** | tmg | Lightweight services — lowest power draw. Hosts Forgejo, PiHole Primary, Tailscale subnet router, Vaultwarden, IT Tools, Mirror Manager, RustDesk | — |
| **DB** | db | Storage/media — OptiPlex 7060 SFF. Hosts PBS, *arr stack, Plex, Jellyfin, NAS. Connects external 26TB of USB media | **BIOS must be AHCI, not RAID** — RAID mode hides the NVMe. CMOS battery failure silently resets to RAID default. Keep spare CR2032s. |
| **DP** | dp | Repurposed Datto ALTO 3 V2 with NUC7i5DNBE board. **Dedicated to HAOS VM** (VM 401) | **Memory ~80%+ by design** — HAOS VM pre-allocated 10GB of 16GB plus ZFS ARC + Proxmox overhead. High memory use is expected and healthy. Do not flag. |
| **Pi 3** | 10.0.0.229 | Raspberry Pi 3B, backup PiHole DNS | Handles 2700+ queries/sec easily |

## Workstations
- **Mac Mini M4** (10.0.0.148) — runs **Ollama** with `gemma4:e4b` for local inference. Currently powers Karakeep auto-tagging (works well). **When recommending solutions, consider whether a simple task could use local gemma4:e4b via Ollama** instead of a remote model — good fit for tagging, classification, short summarization. Paperless integration is a candidate future project.
- **MacBook Pro** — primary workstation. Both Macs stay in sync via `claude-config` repo + `claude-sync` script.

## Conventions
- **Node shorthand**: SB, TMG, DB, DP — used interchangeably with full hostnames in conversation.
- **Storage naming**: `<node>-<size>-<type>` internal (`db-2tb-nvme`), `external-<size>-<type>-<n>` external.
- **ZFS tiering**: rpool (boot) → NVMe (VMs) → SATA SSD mirror (warm) → USB HDD (cold/media). External HDDs are **SMR** — fine for media, never for ZFS pools or databases.
- **mergerfs** pools three external drives at `/mnt/virtual-media` for Plex; only `plex-media/` subdirectories are aggregated.
- **Tailscale Serve is the preferred remote-access pattern**, using real Let's Encrypt certs. Tailnet: `tail-scale.ts.net`. **Prefer full Tailnet addresses** (e.g., `sb.tail-scale.ts.net`) over bare MagicDNS hostnames (e.g., just `sb`) — more reliable across DNS quirks. Forgejo's current use of bare `forgejo` is an exception inherited from earlier config, not the rule.
- **LXC > VM** for Linux services (lower overhead). Docker-in-LXC used sparingly.
- **GitOps**: HA config, wiki, scripts all in Forgejo. Several services auto-deploy on Forgejo push via port-9000 webhook listeners.
- **Home Assistant**: VM 401 on DP, HAOS-based. **Zigbee (not Z-Wave, not Matter)** via PoE coordinator + Zigbee2MQTT. MCP (`ha-mcp`) is primary editing tool; nightly git auto-commit to `alex/homeassistant-config` is the safety net.
- **PiHole is active-active**: TMG LXC 103 (Unbound recursive) + Pi 3 (DoT to Quad9). **Only Tailscale-connected devices use PiHole** — non-Tailscale LAN devices use ISP DNS, by design.

## Gotchas — looks wrong but isn't
- **DP memory ~80%+**: HAOS VM pre-allocated + ZFS overhead. Not a problem.
- **PiHole only affects Tailscale clients**: Opt-in design, not a bug.
- **Forgejo unreachable off-LAN**: Intentional. Start Tailscale.
- **DB's NVMe vanished after reboot**: Check BIOS — must be AHCI. Dead CMOS battery resets to RAID default.
- **USG-3P tops out ~850Mbps**: Primary WAN bottleneck, known limitation.
- **`.env` in claude-config is committed**: Intentional (LAN-only repo). Tool-level deny rules block Claude from reading it. **Never mirror claude-config or bonconlab-scripts to GitHub** — would leak tokens.

## Quick node-role reminders
- Heavy storage/disk question → **DB**
- Light service / DNS / VPN / git → **TMG**
- Main compute / AI frontends → **SB**
- Anything HA or Zigbee → **DP** (via the HAOS VM, not the node itself)
- Simple local inference task → **Mac Mini (Ollama/gemma4:e4b)**
