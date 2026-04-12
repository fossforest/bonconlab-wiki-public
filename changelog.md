# **Changelog**

Running log of changes, configurations, and decisions for BonConLab.

## **April 2026**
### 2026-04-11

<<<<<<< Updated upstream
**Local LLM Backend — Ollama on Mac Mini M4**

- Configured Ollama (Homebrew) on Mac Mini M4 (10.0.0.148) as the local LLM inference backend
- Added `OLLAMA_HOST=0.0.0.0` to LaunchAgent for LAN/Tailscale access
- Pulled `gemma4:e4b` (~4.5B effective, 8B with embeddings) — serves as HA conversation agent and Obsidian assistant
- Open WebUI installed on SB (LXC 204, 10.0.0.126) — native systemd service, Tailscale serve at https://openwebui.tail-scale.ts.net
- 4 cores, 8GB RAM, 50GB disk, Debian 13 (trixie)
- HA integration: gemma4:e4b as conversation agent via direct Ollama connection (not through Open WebUI), Claude+MCP for complex tasks (automations, entity management)

**Documentation**:
- Added [Ollama](services/ollama.md) and [Open WebUI](services/open-webui.md) service docs
- Added Mac Mini M4 to network.md and services index

**Deploy Scripts Updated**

- `deploy-container` step 6: static site fallback — repos without `server.js` or `server.py` are now served directly via `tailscale serve --bg --https=443 /opt/<hostname>/` instead of requiring a systemd service
- Removed `package.json`-only Node.js detection (only `server.js` triggers Node.js mode now)
- Changed all script install paths from `/usr/local/bin/` to `/usr/bin/` — fixes `command not found` on community-script containers where `/usr/local/bin` isn't in PATH
- `ts-init`: added `--accept-risk=lose-ssh` and `--accept-routes` flags to skip interactive prompts
- `ts-init`: added error handling — exits with a diagnostic message if Tailscale install fails (e.g., DNS not working)
- `quickref`: added self-update — re-downloads itself from Forgejo on each run if a newer version exists

**New Script: wiki-info**

- Lightweight info-gathering script for wiki documentation
- Run on any container via `curl -fsSL .../wiki-info | bash` — outputs hostname, IPs, Tailscale status, specs, ports, and systemd services
- Added to quickref menu

**PVE Scripts Local Installed (LXC 116)**

- Web-based management interface for Proxmox VE community helper scripts
- Deployed on TMG via community helper script, Tailscale added via `ts-init`
- IP: 10.0.0.152, Tailscale: https://pve-scripts-local.tail-scale.ts.net

**Documentation**:
- Added [PVE Scripts Local](services/pve-scripts-local.md)
- Updated [LXC Deploy Workflow](services/lxc-deploy-workflow.md) — /usr/bin paths, static fallback, quickref, wiki-info
- Updated [Services Index](services/_services-index.md), [Network](network.md)
=======
**Jellyfin Deployed**

- Deployed Jellyfin media server on DB as LXC 311 (10.0.0.127)
- Ubuntu 24.04 LTS, 2 CPU cores, 2GB RAM
- Tailscale Serve configured for HTTPS access at https://jellyfin.tail-scale.ts.net
- Media served from mergerfs virtual pool via bind mount (same pool as Plex)
- Added [Jellyfin documentation](services/jellyfin.md)
- Updated services index, network IP table
>>>>>>> Stashed changes

### 2026-04-05

**BonConLab Dashboard Deployed**

- Deployed custom dashboard on TMG as LXC 114 (10.0.0.123) via `deploy-container` script
- Stack: Python 3 stdlib http.server + vanilla JS frontend, no dependencies
- Features: service cards, favorites, quick-launch search, drag-and-drop reorder, dark/light theme
- Tailscale Serve configured for HTTPS access at https://dashboard.tail-scale.ts.net
- GitOps webhook configured: push to Forgejo → `http://10.0.0.123:9000/hooks/dashboard-deploy` → pull + restart
- `config.json` excluded from git (`.gitignore`) to prevent webhook pulls from overwriting live dashboard data

**LXC Deploy Workflow Established**

Created `bonconlab-scripts` repo on Forgejo (not mirrored to GitHub — contains Tailscale OAuth secret) with three provisioning scripts:

- **`deploy-container`**: Runs on the Proxmox host. Creates a Debian 13 LXC from scratch, installs all packages (Node.js, Python, git, curl, Tailscale, webhook), runs `ts-init` and `svc-init`, clones the app repo, and optionally sets up a GitOps webhook. One command to go from nothing to a running service.
- **`ts-init`**: Runs inside a container. One-command Tailscale setup with SSH using a permanent OAuth client secret. All containers get `tag:server` automatically. Optional `--tags` flag for additional ACL tags.
- **`svc-init`**: Runs inside a container. Creates a systemd service unit — auto-detects Node.js or Python from repo contents, or prompts interactively.

Scripts are hosted on Forgejo and curled fresh at deploy time, so they always carry the current OAuth secret and latest logic. No LXC template needed.

**Tailscale OAuth Authentication**

- Created an OAuth client for headless node registration (replaces 90-day auth keys)
- OAuth client secret does not expire — no more key rotation cycle
- Scopes: `auth_keys` (read/write), `devices:core` (read/write), tag: `tag:server`
- `ts-init` passes `ephemeral=false&preauthorized=true` to register persistent, auto-approved nodes

**Decisions Made**:

- One container per service maintained — LXC containers share the host kernel and have negligible overhead, while bundling services would create a single point of failure
- No LXC template — `deploy-container` provisions from scratch each time, eliminating template staleness and maintenance
- OAuth over auth keys — permanent secret removes the 90-day rotation burden
- Scripts in Forgejo, not baked into a template — always curled fresh for latest version
- `bonconlab-scripts` repo NOT mirrored to GitHub — contains Tailscale OAuth client secret
- Python stdlib for simple utilities (dashboard), Node.js/Express for complex ones (CV Updater, Mirror Manager) — both installed in every container for flexibility
- `config.json` excluded from git for all apps with UI-editable data (same pattern as CV Updater)

**Issues Encountered**:

- `pct exec` does not load the full shell PATH — scripts in `/usr/local/bin/` must be called by absolute path, not by name. Fixed in `deploy-container`.
- First deploy attempt failed because scripts hadn't been pushed to the Forgejo repo yet. Added verification checks to `deploy-container` that exit with a clear error if a script fails to download.

**Future: bonconlab-infra**

A `bonconlab-infra` repo is planned to hold reproducible setup scripts for every container in the cluster, extending the `deploy-container` pattern to non-utility services (arr stack, Plex, Home Assistant, etc.).

**Documentation**:

- Added [Dashboard documentation](services/dashboard.md)
- Added [LXC Deploy Workflow](services/lxc-deploy-workflow.md)
- Updated services index
- Updated network IP table with 10.0.0.123


## **March 2026**

### 2026-03-31

**go2rtc Camera Stream Setup**

Deployed go2rtc add-on in Home Assistant to handle camera streams with rotation support for sideways-mounted doorbell.

**Problem Solved**:
- Reolink doorbell has 180° horizontal FoV, designed for landscape orientation
- Mounted sideways to get vertical head-to-toe coverage of visitors
- Reolink app only offers flip/mirror, not 90° rotation
- Solution: go2rtc add-on with FFmpeg transpose filter

**go2rtc Configuration**:
- Installed default go2rtc add-on (AlexxIT repository, includes Intel VAAPI)
- Doorbell stream: RTSP ingested, rotated 90° CW via FFmpeg, served as `doorbell_rotated`
- Driveway stream: RTSP passthrough (no processing), served as `driveway`
- Web UI at `http://homeassistant.local:1984`

**Home Assistant Integration**:
- Added cameras via Generic Camera integration (UI method, not YAML)
- Stream source: `rtsp://127.0.0.1:8554/{stream_name}`
- Still image: `http://127.0.0.1:1984/api/frame.jpeg?src={stream_name}`
- Entities: `camera.doorbell`, `camera.driveway`

**Prusa Buddy3D Camera**: Not integrated — requires WebRTC mode for PrusaConnect app/web, which go2rtc can't easily ingest. Monitoring via PrusaConnect only.

**Documentation**:
- Created `home-assistant/` subfolder for HA-specific documentation
- Added [go2rtc](home-assistant/go2rtc.md) — stream configuration and rotation
- Added [cameras](home-assistant/cameras.md) — camera entities and dashboard setup
- Moved Zigbee2MQTT documentation from `services/` to `home-assistant/`
- Updated services index to reflect Zigbee2MQTT move

### **2026-03-29**
 
**NAS/Fileshare Documentation Complete**
 
- Created comprehensive service documentation for LXC 303 (db-nas-fileshare) at `services/nas-fileshare.md`
- Documents both NFS server (exports to cluster containers) and Samba/SMB server (shares for macOS clients)
- Consolidated existing partial documentation from `nas-fileserver-samba.md`
 
**Documentation Updates**:
 
- Updated services index: changed NAS/Fileserver link from `nas.md` to `nas-fileshare.md`, status from 🚧 Pending to ✅ Active
- Removed `nas-fileserver-samba.md` (superseded by `nas-fileshare.md`)
 
**Key Details Documented**:
 
- Bind mounts: mp0 (media-pool), mp1 (cold), mp2 (warm)
- NFS exports: media-pool (fsid=1), cold (fsid=2), per-service exports for Paperless-ngx (fsid=202) and Manyfold (fsid=203)
- Samba config: vfs_fruit for macOS compatibility, three shares (Warm_Storage, Cold_Storage, Media_Pool)
- Proxmox NFS storage integrations: db-nas-media-pool, db-nas-cold-pool, db-nas-paperless-ngx
 

### 2026-03-29
 
**Arr Media Stack Deployed**
 
- Deployed full *arr media automation stack on DB (db):
  - Prowlarr (LXC 306, 10.0.0.161) — indexer manager
  - Radarr (LXC 307, 10.0.0.162) — movie management
  - Sonarr (LXC 308, 10.0.0.163) — TV show management
  - qBittorrent (LXC 309, 10.0.0.164) — torrent client
- All containers mount `/mnt/external-18tb-hdd` at `/data`; downloads and library on same ext4 filesystem for hardlink support
- Added mergerfs pool mount (`/mnt/virtual-media` → `/media`) to Radarr (LXC 307) and Sonarr (LXC 308) for importing existing Plex library
- MoreThanTV (MTV) private tracker configured as Torznab indexer in Prowlarr, synced to both Radarr and Sonarr
- Three quality profiles created: Uncompressed (remux), 2160p/1080p (encoded 4K with 1080p fallback), 1080p/720p (standard HD)
- Imported existing Plex library: 12 movies (251 GB), 7 TV series / 1189 episodes (1.9 TiB)
- Cleaned up duplicate directories: removed empty lowercase `movies` and `tv` folders from `/mnt/external-18tb-hdd/plex-media/`, retained capitalized `Movies` and `TV` with correct permissions (777 for unprivileged container access)
 
**qBittorrent Configuration**:
 
- DHT, PeX, and Local Peer Discovery disabled globally (private tracker requirement)
- Seeding limit: ratio ≥ 2.0, then stop torrent
- Torrent queueing: 5 downloads / 8 uploads / 15 total, slow torrents excluded from limits
- WebUI auth bypass for LAN (10.0.0.0/24) and Tailscale (100.64.0.0/10) subnets
- Anonymous mode disabled (private trackers verify client identity)
- Incomplete downloads isolated to `/data/arr-downloads/incomplete/`
- Categories `radarr` and `sonarr` for automatic download sorting
 
**Decisions Made**:
 
- Hardlink strategy over copy: all arr paths on same ext4 filesystem eliminates duplicate storage
- Per-series quality profiles in Sonarr: prestige shows get 4K, casual shows get 1080p
- Remux excluded from 1080p/720p profile — quality difference at 1080p doesn't justify 3x file size
- BR-DISK and Raw-HD tiers disabled — not playable by Plex without remuxing, and impractical for automated management
- Movie Only import (not Movie and Collection) to prevent Radarr from auto-downloading entire franchises
- `/24` subnet whitelist on qBit over per-IP `/32` entries for convenience; will revisit when VLANs are implemented
 
**Documentation**:
 
- Added service documentation: [Prowlarr](services/prowlarr.md), [Radarr](services/radarr.md), [Sonarr](services/sonarr.md), [qBittorrent](services/qbittorrent.md)
- Updated services index with all four arr containers
- Updated network IP table with 10.0.0.161–164

### **2026-03-26**

**Arr Stack Infrastructure Deployed**

**Containers Deployed**

Four new LXC containers created on DB (db) via community helper scripts, all on `db-2tb-nvme`, unprivileged, with Tailscale installed and IPs reserved in Unifi:

| Service | LXC | IP | Port |
|---------|-----|----|------|
| Prowlarr | 306 | 10.0.0.161 | 9696 |
| Radarr | 307 | 10.0.0.162 | 7878 |
| Sonarr | 308 | 10.0.0.163 | 8989 |
| qBittorrent | 309 | 10.0.0.164 | 8090 |

**Directory Structure Created**

New directories created on the 18TB ext4 drive (`/mnt/external-18tb-hdd`):

```
arr-downloads/
├── movies/
└── tv/
plex-media/
├── movies/   (existing, now also managed by Radarr)
└── tv/       (existing, now also managed by Sonarr)
```

`plex-media/` subdirectories already existed as part of the mergerfs pool. `arr-downloads/` is new — used as download staging, outside the mergerfs pool and invisible to Plex.

**Bind Mounts**

The full 18TB ext4 drive is bind-mounted into Radarr, Sonarr, and qBittorrent at `/data`. Prowlarr has no storage mount (metadata only).

```bash
pct set 307 -mp0 /mnt/external-18tb-hdd,mp=/data  # Radarr
pct set 308 -mp0 /mnt/external-18tb-hdd,mp=/data  # Sonarr
pct set 309 -mp0 /mnt/external-18tb-hdd,mp=/data  # qBittorrent
```

**Hardlink Architecture**

All arr containers and the download staging directory share the same underlying ext4 filesystem. This enables hardlinks — when a download completes, Radarr/Sonarr create an instant zero-cost hardlink in `plex-media/` while the torrent continues seeding from `arr-downloads/`. The mergerfs pool (and therefore Plex) sees new content automatically.

The 4TB exFAT drives are intentionally excluded from arr management — exFAT does not support hardlinks.

**Decisions Made**

- One container per service (not bundled) — consistent with existing pattern, allows independent restarts/updates, no Tailscale serve port conflict
- All containers on DB — hardlink requirement mandates same filesystem as media storage
- 18TB ext4 drive only for arr-managed content — exFAT drives do not support hardlinks
- Container naming: hostname = service name only (e.g. `prowlarr`); Unifi reservation retains node prefix (e.g. `db-prowlarr`)
- qBittorrent kept on DB rather than SB — hardlink requirement outweighs any CPU advantage of SB

**Status**

Infrastructure complete. Web UI configuration (indexers, quality profiles, download client connections) pending — to be completed in follow-up session.

**Documentation**

- Added `services/prowlarr.md`
- Added `services/radarr.md`
- Added `services/sonarr.md`
- Added `services/qbittorrent.md`
- Updated `services/_services-index.md`
- Updated `network.md`

### **2026-03-24**

**Zensical Documentation Service Deployed**
- Deployed Zensical on DB (db) using a Tailscale Sidecar architecture for secure, isolated networking.
- Service is accessible via Tailnet at `https://wiki.tail-scale.ts.net`.
- Configured Zensical to serve on `0.0.0.0:8000` to resolve container loopback issues.

**GitOps Expansion: Zensical Auto-Updates**
- Installed `webhook` package on the Docker host VM and configured a `wiki-deploy` hook on port 9000.
- Created `/home/anon/zensical/pull-and-deploy.sh` to automate `git pull` operations.
- Modified the `webhook` systemd service to run as the `alex` user to resolve "dubious ownership" and SSH credential issues.
- Verified end-to-end flow: Push to Forgejo → Webhook → Script Execution → Zensical Live Reload.

**Forgejo Mirror Manager Deployed**

- Deployed Mirror Manager on TMG as LXC 111 (10.0.0.140) via community Debian LXC helper script (Debian 13 Trixie)
- Node.js 20 installed from Debian 13 default repos — no NodeSource needed (Debian 13 ships Node.js 20 LTS natively)
- Tailscale installed with SSH enabled; `tailscale serve --bg 3850` configured for HTTPS access
- Web UI for managing Forgejo → GitHub push mirrors, repo creation, and deploy webhook configuration
- Bootstrap script endpoint (`/setup-webhook.sh`) generates container-side webhook receiver setup scripts
- Self-updating via Forgejo webhook → `http://10.0.0.140:9000/hooks/mirror-manager-deploy` → pull + restart on push

**CV Updater Renamed and Enhanced**

- Renamed service from cv-manager to cv-updater (systemd unit, working directory `/opt/cv-manager` → `/opt/cv-updater`)
- Added dark mode toggle (system preference aware, localStorage persisted)
- Added Quick Add scratchpad: markdown-compatible persistent text area with auto-save (debounced 1.5s + Cmd+Enter), rendered preview below editor
- Removed `data/` from git tracking to prevent webhook pulls from overwriting live CV data; `.gitignore` updated accordingly
- Deploy webhook configured: push to Forgejo → `http://10.0.0.171:9000/hooks/cv-updater-deploy` → pull + restart
- Deploy script (`/opt/cv-updater/pull-and-deploy.sh`) runs `chown -R cvmanager:cvmanager /opt/cv-updater/data` after pull to maintain correct ownership (webhook runs as root, app runs as `cvmanager`)

**Webhook GitOps Pattern Expanded**

- Three services now use the webhook-based GitOps pattern: Homepage (LXC 107), Mirror Manager (LXC 111), CV Updater (LXC 112)
- All use the same stack: `adnanh/webhook` package on port 9000, Forgejo push-event webhooks, `pull-and-deploy.sh` scripts
- Mirror Manager can bootstrap this pattern on any container via its `/setup-webhook.sh` endpoint

**Decisions Made**

- Debian 13 (Trixie) ships Node.js 20 LTS natively — NodeSource no longer needed for new Node.js deployments
- Community Debian LXC script preferred over manual `pct create` for new containers (handles TUN device, nesting, template download)
- `data/` directories with user-generated content should be `.gitignore`d to prevent webhook pulls from overwriting live data
- Mirror Manager serves as the central tool for repo creation, GitHub mirroring, and webhook GitOps setup

**Documentation**

- Added [Mirror Manager](services/mirror-manager.md) service documentation
- Added [CV Updater](services/cv-updater.md) service documentation (renamed from cv-manager)
- Updated services index: added LXC 111 and 112, webhook listener notes
- Updated network IP table: added 10.0.0.140 (tmg-mirror-manager)
- Updated Forgejo hosted repos list: added forgejo-mirror-manager and cv-updater
- Replaced placeholder zensical.md with complete service documentation
- Added docker-host-vm.md for VM 305 (first dedicated Docker VM in the cluster)
- Added 10.0.0.173 to network IP table
- Updated services index: nested Zensical under Docker Host VM in DB section

### **2026-03-21**

**DB NVMe Disappearance — BIOS Reset & CMOS Battery Replacement**

**What Happened**:

- Rebooted all nodes for routine maintenance. All booted fine except DB.
- All four containers (301-304) failed to start with: "zfs error: cannot open 'db-2tb-nvme': no such pool available"
- `zpool status` showed `db-2tb-warm` and `rpool` healthy, but `db-2tb-nvme` completely missing
- `lsblk` showed no NVMe device at all — the 2TB Samsung 970 EVO Plus was invisible to the kernel
- `dmesg` revealed: "Found 1 remapped NVMe devices" and "Switch your BIOS from RAID to AHCI mode to use them"
- Root cause: dead CMOS battery (CR2032) caused BIOS to reset to factory defaults after the power outage on 2026-03-19. Dell OptiPlex 7060 SFF defaults to RAID mode, which remaps NVMe through the AHCI controller instead of presenting it natively on PCIe — Linux sees the drive exists but can't create `/dev/nvme*` device nodes.
- The BIOS had silently reset after the 3/19 power outage but the node wasn't rebooted until 3/21, which is when the reset settings took effect.

**Fix Applied**:

- Entered BIOS (F2 during POST), confirmed SATA Operation was set to RAID On, changed to AHCI
- Drives screen in BIOS confirmed all hardware detected including "M.2 PCIe SSD-0 = Samsung SSD 970 EVO Plus 2TB"
- Replaced dead CR2032 CMOS battery on the motherboard to prevent future BIOS resets
- On first reboot after BIOS change, got "No bootable devices found" because boot entries had been disabled during a cleanup attempt. Re-enabled all boot entries except Windows Boot Manager, rebooted successfully.
- After successful boot, ethernet cable was in wrong physical port (built-in Intel NIC instead of 2.5G USB adapter). Moved cable to correct port, network came up at 2.5Gbps, all four containers auto-started.

**BIOS Settings Verified/Set**:

- **SATA Operation**: AHCI (was RAID On due to factory reset)
- **Boot List Option**: UEFI
- **Drives detected**: SATA-0 & SATA-2 (Samsung 870 EVO 500GB ×2, boot mirror), SATA-3 (CT2000BX500SSD1, one leg of db-2tb-warm mirror), M.2 PCIe SSD-0 (Samsung 970 EVO Plus 2TB, db-2tb-nvme)
- **Boot Sequence**: Multiple entries present including two "proxmox" entries for the Samsung 870 EVO boot mirror. Stale entries (Linux Boot Manager ×4, Windows Boot Manager, PCIEmaybe) to be cleaned up later via `efibootmgr`.

**Decisions Made**:

- Replaced CMOS battery immediately as the permanent fix — without this, every power outage would reset BIOS to RAID mode
- Left stale UEFI boot entries for now — safer to clean up from Linux using `efibootmgr` than editing in BIOS directly
- Confirmed the Glotrends PCIe SATA card hosts the second Crucial BX500 (not visible in BIOS drive list, but detected by Linux). This split across controllers is intentional for redundancy.

**Lessons Learned**:

- A dead CMOS battery can cause silent BIOS resets that don't manifest until the next full reboot
- NVMe drives on Intel platforms can be remapped through AHCI when BIOS is in RAID mode, making them invisible to Linux as native NVMe devices
- `dmesg` is essential for diagnosing storage detection issues — the "remapped NVMe" message directly pointed to the fix
- The 3/19 power outage was the trigger, but the BIOS reset didn't cause problems until the 3/21 reboot because the old settings were still in volatile memory

### **2026-03-19**

**Power Outage Recovery, fstab Hardening & Warm Storage Activation**

**Power Outage Recovery**

- Power outage caused all DB containers to fail to start on reboot
- Containers 301 (PBS) and 304 (Copyparty) started fine; containers 302 (Plex) and 303 (NAS) failed with: "Failed to run lxc.hook.pre-start" / exit status 2
- Root cause: stale FUSE mount on `/mnt/virtual-media` — the mergerfs Plex pool used a glob pattern (`/mnt/external-*-hdd*/plex-media`) that failed during boot because USB drives hadn't mounted yet when the glob expanded
- Fix: `fusermount -uz /mnt/virtual-media` to clear the stale mount, then remount

**fstab Hardening**

- Replaced mergerfs glob pattern with explicit colon-separated paths: `/mnt/external-18tb-hdd/plex-media:/mnt/external-4tb-hdd-1/plex-media:/mnt/external-4tb-hdd-2/plex-media`
- Added `nofail` flag for boot resilience (system continues booting even if mount fails)
- Added `x-systemd.requires=` dependencies for all three external drive mount units so mergerfs waits for USB drives before mounting
- Created timestamped backup `fstab.bak.20260319` before editing
- Old glob line preserved as a comment in fstab for reference

**Warm Storage Activation**

- Discovered LXC 303 (NAS) was missing the bind mount for `db-2tb-warm → /srv/warm`
- The Samba `[Warm_Storage]` share was already configured in `smb.conf` but had no backing storage — this is why warm storage "never worked"
- Fixed with: `pct set 303 -mp2 /db-2tb-warm,mp=/srv/warm`
- Confirmed `Warm_Storage` share now appears in Finder and is accessible on both Macs
- Warm pool status: 2x 2TB Crucial BX500 in ZFS mirror, 1.70TB available, 54GB used by PBS backups

**smb.conf Cleanup**

- Merged duplicate `[global]` sections (Debian boilerplate + custom config)
- Removed unused shares: `[homes]`, `[printers]`, `[print$]`
- Added `create mask = 0664` and `directory mask = 0775` to `[Cold_Storage]` (was missing)
- Created timestamped backup `smb.conf.bak.20260319` before editing

**SSH Fix**

- Added `SetEnv TERM=xterm-256color` to Mac SSH config for all Proxmox nodes to fix Ghostty terminal compatibility

**Decisions Made**:

- Explicit paths over glob patterns for fstab/mergerfs entries — globs are unreliable at boot
- Samba (not NFS) for macOS network shares — native Finder support, `vfs_fruit` compatibility
- `db-2tb-warm` intended as Google Drive replacement: network share first, Syncthing for local sync later, remote backup TBD
- Timestamped config backups before editing critical files is now standard practice

**Documentation**:

- Updated `storage.md` (mergerfs source paths, boot resilience notes)
- Updated `services/nas-fileserver-samba.md` (bind mounts, storage tiers, smb.conf cleanup)
- Updated `services/plex.md` (explicit source paths, boot resilience note)
- Added Standard Practices section to `maintenance.md`

### **2026-03-16**

**Forgejo Git Server Deployed**

- Deployed Forgejo (v14.0.3) on TMG as LXC 104 (10.0.0.181) via community helper script
- Database: SQLite; data at `/var/lib/forgejo`; config at `/etc/forgejo/app.ini`
- TUN device enabled during advanced setup to allow Tailscale installation inside the container
- Tailscale installed in container; `tailscale serve --bg 3000` provides HTTPS access at https://forgejo.tail-scale.ts.net
- `ROOT_URL` set to local IP (`http://10.0.0.181:3000`) so clone URLs and webhook deliveries work on the LAN without Tailscale dependency

**Repo Migration from GitHub**

- Migrated two repos using Forgejo's built-in GitHub migration tool with a temporary fine-grained PAT (Contents + Metadata, read-only); full commit history preserved:
  - `bonconlab-wiki` (from anon-user/bonconlab-wiki)
  - `homepage-config` (from anon-user/homepage-config)
- Reconfigured local git remotes on the Mac: `origin` now points to Forgejo; GitHub preserved as remote named `github`

**Webhook-based GitOps for Homepage**

- Added `[webhook] ALLOWED_HOST_LIST = 10.0.0.0/24` to `app.ini` to allow Forgejo to deliver webhooks to LAN hosts (blocked by default)
- `homepage-config` repo webhook POSTs to `http://10.0.0.197:9000/hooks/homepage-deploy` on push
- LXC 107 (Homepage): `webhook` package installed via apt, listening port 9000; config at `/etc/webhook.conf`; deploy script at `/opt/homepage-config/pull-and-deploy.sh` does `git pull` then copies YAML configs to `/opt/homepage/config/`
- Homepage hot-reloads config changes — no container restart needed

**Decisions Made**:

- Local IP chosen for ROOT_URL over tailnet URL so GitOps automations work independently of Tailscale
- Both repos set to public on the Forgejo instance; access control is network-level only (LAN / Tailscale)
- Webhook package config at `/etc/webhook.conf` (Debian package default path, not `/etc/webhook/hooks.json`)

**Documentation**:

- Added [Forgejo documentation](services/forgejo.md)
- Updated services index (moved Forgejo from Planned to Active; noted webhook listener on LXC 107)
- Updated network IP table (added 10.0.0.181 for Forgejo, 10.0.0.197 for Homepage)

### **2026-03-10**

**Homepage Dashboard Deployed (replacing Homarr)**

- Switched from Homarr to Homepage for homelab dashboard
- Homepage runs on TMG (LXC 107), accessible via Tailscale at https://homepage.tail-scale.ts.net/
- YAML-based configuration for easy version control and LLM-assisted editing
- Configured service links for all active services across all nodes
- Widget integrations prepared (commented out) for Proxmox, PiHole, Home Assistant, PBS, Plex, Paperless-ngx
- Deleted Homarr container (LXC 104 on DB)

**Wiki Documentation Catchup**

- Added service documentation for: Paperless-ngx, Actual Budget, Manyfold, Plex, Homepage
- Updated services index with all active services
- Updated network IP assignments table
- Moved Plex and Paperless-ngx from Planned to Active

**Decisions Made**:

- Homepage chosen over Homarr for YAML-based config (better for version control and LLM collaboration)
- Homepage config to be stored in its own git repo for versioned management

### **2026-03-08**

**IT Tools Alpine LXC Deployed (TMG LXC 110)**

- Deployed IT Tools Alpine LXC on TMG (LXC 110, 10.0.0.185), accessible via Tailscale at https://it-tools-alpine.tail-scale.ts.net

**NPM Container Removed (TMG LXC 101)**

- Removed NPM container (LXC 101) — never configured; can be redeployed if needed

**Manyfold Admin Credentials Recovered**

- Recovered Manyfold admin credentials via Rails console: `su - manyfold`, then `RAILS_ENV=production bin/rails console` from `/opt/manyfold/app`

**Manyfold Library Storage Created**

- Created Manyfold local library storage at `/opt/manyfold/app/storage/libraries` on sb-1tb-ssd

**Manyfold Upload Failures Fixed**

- Fixed Manyfold upload failures via Tailscale URL by adding `client_max_body_size 500M;` to `/etc/nginx/sites-available/manyfold.conf` and reloading nginx

### **2026-03-07**

**DP: ZFS Boot Mirror Added**

- Added 256GB Samsung SSD 840 PRO via onboard SATA 6Gb/s port as the second device in `rpool`, completing the planned ZFS mirror on DP's boot drive.
- HA VM (401) remained online throughout the operation — no downtime.
- Ran `zpool upgrade rpool` after mirror completed.

**Non-obvious steps required (for future reference)**:

1. **Whole-disk attach breaks EFI**: Attaching the new disk as a whole device (`sdb`) causes ZFS to consume the entire disk, leaving no room for the EFI partition. Workaround: detach the failed attach, clone the partition table from the existing disk with `sgdisk -R /dev/sdb /dev/sda`, then reattach explicitly using the partition (`sdb3`, not `sdb`).
2. **`proxmox-boot-tool init` fails if disk has children**: Even after cloning the partition table, `proxmox-boot-tool init /dev/sdb2` fails because the kernel sees existing child partitions. Workaround: manually append the new ESP's UUID to `/etc/kernel/proxmox-boot-uuids` instead of running `init`.
3. **`proxmox-boot-tool refresh` skips ESP without `/EFI/proxmox`**: The tool silently skips copying kernels if the `/EFI/proxmox` directory doesn't exist on the ESP. Workaround: `mkdir -p /boot/efi/EFI/proxmox` (or equivalent mount path) before running `proxmox-boot-tool refresh`.

### **2026-03-01**

**DP Node Commissioned & HAOS Migrated to VM**

**Hardware Swap**:

* Replaced internals of the Datto ALTO 3 V2 enclosure with an Intel NUC Board NUC7i5DNBE
* **Old**: Intel Celeron 3865U, 16GB DDR4, 128GB NVMe (Toshiba)
* **New**: Intel Core i5-7300U (2C/4T, 3.5GHz boost, 15W TDP), 16GB DDR4 (2x Samsung 8GB, downclocked to 2133MHz by board), 256GB M.2 SATA SSD (Intel SSDSCKKF256GB)
* Hostname: dp.local, IP: 10.0.0.5 (static, reserved in Unifi)

**Proxmox Installation on DP**:

* Installed Proxmox VE on the NUC board with ZFS RAID0 (single disk) — ZFS chosen over ext4 for future replication capability
* Ran community post-install script
* Joined DP to the BonConLab cluster as the 4th node: `pvecm add 10.0.0.2`
* Installed Tailscale on bare metal with `--ssh` flag

**HAOS VM Migration (VM 401)**:

* Created HAOS VM (ID 401) on SB using the community helper script (advanced settings)
* Created full backup from existing bare metal HAOS on old Datto hardware
* Started VM on SB, restored backup via HAOS onboarding wizard
* Shut down old Datto HAOS, then migrated VM to DP: `qm migrate 401 dp --targetstorage local-zfs`
* Verified HA and all integrations/add-ons working on DP
* VM ID range 4xx designated for DP VMs/containers

**Decisions Made**:

* **ZFS over ext4**: Chosen for future ZFS replication capability, even as single disk
* **KVM64 CPU model**: Selected for cross-node live migration compatibility between different CPU generations (i5-10500 on SB vs i5-7300U on DP)
* **4xx VM ID range**: Designated for all DP VMs and containers

**Issues Encountered**:

* **ZFS pool creation failed on first install**: Stale partition table on the SSD; fixed by zeroing the drive with `dd` in Proxmox debug mode before reinstalling
* **RAM showing 8GB instead of 16GB**: One stick not properly seated; fixed by reseating both DIMMs

**Backup**:

* Existing cluster-wide PBS backup job (pbs-db) should automatically pick up VM 401 on DP
* Verify pbs-db storage is visible on dp node and backup job includes VM 401

**Documentation**:

* Updated hardware.md, network.md, storage.md, README.md, home-assistant.md, services index, maintenance.md

## **February 2026**

### **2026-02-21**

**RustDesk Server Deployed**

* Deployed RustDesk Server on TMG as LXC 108 via community helper script
* Services running in container: `rustdesk-hbbs` (ID/rendezvous), `rustdesk-hbbr` (relay), `rustdesk-api` (web admin panel)
* Reserved IP 10.0.0.179 in Unifi as "tmg-rustdeskserver"
* Tailscale installed in container for remote admin access (IP: 100.71.227.113)
* Admin panel accessible at http://10.0.0.179:21114

**Decisions Made**:
* Deployed on TMG alongside other lightweight network services
* Used local IP intentionally — accessible on LAN directly and remotely via Tailscale subnet routing
* Tailscale installed in container as a fallback access method for the admin panel

**Documentation**:
* Added [RustDesk Server documentation](services/rustdesk-server.md)
* Updated services index and network IP table

### **2026-02-06**

**Copyparty File Server Deployed**

* Created LXC container 304 on DB node
* Container specs: 2 cores, 1GB RAM, 8GB storage on db-2tb-nvme
* Installed Copyparty via community helper script
* Configured three volumes:
  - `/db-2tb-warm` (Backup storage)
  - `/db-nas-cold-pool` (Cold storage mergerfs pool)
  - `/db-nas-media-pool` (Media storage mergerfs pool)
* Disabled authentication for trusted network use
* Configured Tailscale with serve on port 3923
* Reserved IP 10.0.0.191 in Unifi as "Copyparty_DB"

**Decisions Made**:
* Deployed on DB for direct access to storage pools
* Used privileged container for simplified mount point access
* Chose Tailscale Serve over Nginx reverse proxy for simplicity
* Disabled authentication since access is restricted to trusted network/Tailscale

**Access**:
* Local: http://10.0.0.191:3923
* Remote: https://db-copyparty.tail-scale.ts.net/
* SSH: `ssh root@db-copyparty` (via Tailscale)

**Documentation**:
* Added [Copyparty documentation](services/copyparty.md)
* Updated services index

### **2026-02-03**

**Tailscale Mesh Expansion & DNS Granularity**

**Architecture Shift: Direct Mesh DNS**

* **Goal**: Enable per-client logging in PiHole for remote devices (previously, all traffic appeared as coming from the Subnet Router).  
* **Action**: Installed Tailscale directly on the PiHole LXC (pihole-tmg) and the backup Pi 3\.  
* **Config**: Updated global Tailscale Nameservers to use the new 100.x.y.z addresses.  
* **PiHole**: Changed interface listening behavior to "Permit all origins" to accept traffic from the tailscale0 interface.

**LXC & Proxmox Improvements**

* **TUN Passthrough**: Standardized process for enabling Tailscale on unprivileged containers. Added /dev/net/tun to Resources \> Devices on all relevant LXCs.  
* **UDP Optimization**: Applied ethtool rx-udp-gro-forwarding fix to the Subnet Router (LXC 102\) to maximize throughput for 2.5GbE. Created persistent systemd service tailscale-ethtool.service.

**Troubleshooting & Fixes**

* **Apt-Cacher-NG**: Fixed installation failure by removing self-referencing proxy config (00aptproxy.conf) to allow HTTPS tunnels to Tailscale repos.  
* **Minimal Containers**: Installed curl on Samba/File Server containers to facilitate install scripts.  
* **Physical Recovery**: Reset root password on Backup Pi 3 using the init=/bin/sh boot flag method.

**Decisions Made**:

* **Mesh over Routing**: While Subnet Routing works for connectivity, installing the Tailscale client on every node allows for better ACL control and logs.  
* **Systemd for Persistence**: Used a systemd oneshot service for network optimizations instead of networkd-dispatcher (not present in minimal images) or crontab.

### **2026-02-01**

**Cluster-wide 2.5GbE Upgrade & Node Maintenance**

**Network Upgrade (SB & TMG)**

* **Hardware**: Installed USB 3.0 to 2.5GbE adapters on both SB and TMG nodes to eliminate the 1G bottleneck.  
* **Configuration**: Switched vmbr0 bridge ports from onboard NICs to new USB interfaces.  
* **Power Management**: Applied persistent ethtool fix to disable Wake-on-LAN/autosuspend, preventing the USB adapters from dropping offline.  
* **Result**: All three cluster nodes (SB, TMG, DB) are now operating on 2.5GbE.

**Softbutch (SB) Drive Replacement**

* **Issue**: nvme1n1 (SK Hynix 256GB) reached 59% wearout.  
* **Action**: Hot-swapped with fresh 256GB NVMe drive.  
* **Process**: Offlined drive in ZFS, physically swapped, cloned partition table from healthy drive, and resilvered rpool.  
* **Bootloader**: Re-initialized proxmox-boot-tool on the new drive partition.

**Service Migration**

* Temporarily migrated Unifi Controller (LXC 100\) to TMG during SB maintenance, then migrated back to SB once stable.

**Decisions Made**:

* **USB vs PCIe**: Used USB adapters for SB/TMG (Micro form factor limitation).  
* **Static IP Strategy**: Configured the "Static" IP on the Linux Bridge level, allowing the underlying physical interface (enx...) to be swapped without breaking the node's static IP.

**Commands Used**:

\# Partition Cloning (SB)  
sgdisk /dev/nvme0n1 \-R /dev/nvme1n1  
sgdisk \-G /dev/nvme1n1  
proxmox-boot-tool format /dev/nvme1n1p2 \--force  
proxmox-boot-tool init /dev/nvme1n1p2

\# Network Persistence Fix (/etc/network/interfaces)  
post-up /usr/sbin/ethtool \-s \[interface\_id\] wol d  

## **January 2026**

### **2026-01-31**

**Storage Virtualization & Organization**

- **Media Consolidation**: Standardized all external drives with a `/plex-media` subdirectory; moved and organized loose movie files into individual folders for better metadata matching.
- **MergerFS Deployment**: Configured a union filesystem on the host to aggregate three disparate media folders into one 26TB virtual mount at `/mnt/virtual-media`.
- **LXC Optimization**: Simplified Plex LXC (302) configuration by replacing multiple drive mounts with a single unified pass-through at `/mnt/media/all-content`.
- **Storage Tiering**: Utilized the 18TB ext4 drive as the primary anchor for the pool while maintaining exFAT on 4TB drives for easy data transfer.

**Decisions Made**:
- Kept non-media storage "Out-of-Pool" by targeting specific subdirectories in the mergerfs config.
- Adopted the `mfs` (most free space) creation policy to automatically balance data across physical disks.

### **2026-01-31**
**Storage Virtualization with mergerfs**
- **Unified Pool**: Implemented `mergerfs` to pool 18TB (ext4) and 2x 4TB (exFAT) drives into a single `/mnt/virtual-media` mount point.
- **LXC Simplification**: Reduced Plex LXC (302) pass-throughs from three separate mounts to a single unified mount at `/mnt/media/all-content`.
- **Policy**: Set `mfs` (most free space) as the creation policy to balance drive wear and capacity automatically.

### **2026-01-30 (Evening)**

**Plex Storage Optimization & Organization**

- **Media Consolidation**: Cleaned up the root directories of all external drives by moving loose media into dedicated `plex-media` subfolders.
- **Automated Organization**: Ran a bash loop to automatically create folders for loose `.mkv` files to ensure better Plex metadata matching.
- **Permissions Fix**: Updated `/etc/fstab` for **exFAT** drives to include `uid=1000,gid=1000`; maintained standard permissions for the **ext4** 18TB drive.
- **Persistence**: Configured UUID-based mounting with the `nofail` flag to prevent boot hangs.
- **LXC Bind Mounts**: Passed through all three external media folders to the Plex LXC (ID 302) with the 18TB drive prioritized as `mp0`.

**Decisions Made**:
- Standardized on a `/mnt/media/` structure inside the container for easier Plex library management.
- Chose `mp0` for the 18TB drive as the primary anchor for the media library.
- Used a tiered filesystem approach: ext4 for the primary archive and exFAT for portable expansion drives.

### **2026-01-30**

**Daddybear Node Rebuild & Backup Architecture**

**Hardware Changes (Node DB)**:

* **Issue**: SMART failure detected on original 1TB boot drive (OfflineUncorrectableSector).  
* **Action**: Replaced failing drive with **2x 500GB Samsung 870 EVO** configured as a ZFS Boot Mirror.  
* **Expansion**: Added **2x 2TB Crucial BX500** SATA SSDs for "Warm" storage (ZFS Mirror).  
* **Adapter**: Installed Glotrends PCIe x4 SATA expansion card.  
* **Cleanup**: Removed internal 4TB HDD to accommodate new SSD density.

**Storage Configuration**:

* **Boot**: ZFS Mirror on Samsung EVOs (SATA 0 & 2).  
* **Fast Tier**: Imported existing db-2tb-nvme pool.  
* **Warm Tier**: Created new db-2tb-warm pool on Crucial SSDs.  
* **Redundancy**: Split "Warm" drives between Motherboard and PCIe card to prevent controller single-point-of-failure.

**Service Deployment: Proxmox Backup Server (PBS)**:

* Deployed as Privileged LXC (ID 301\) on Node DB.  
* IP: 10.0.0.202 (reserved).  
* Storage: Bind mount from host (/db-2tb-warm/backups mapped to /mnt/backups).  
* Enabled daily Garbage Collection.

**Automation**:

* Configured cluster-wide backup job.  
* **Schedule**: Daily @ 04:00 AM.  
* **Retention**: Keep 3 Last, 7 Daily, 4 Weekly, 1 Monthly.  
* **Mode**: Snapshot (Zero downtime).

**Decisions Made**:

* **All-Flash DB**: Converted Daddybear to an all-flash node. NVMe for active VMs, SATA SSDs for backups/NAS.  
* **LXC for PBS**: Chose LXC over VM to utilize Bind Mounts for direct ZFS performance on the host.  
* **Retention Policy**: Adopted Grandfather-Father-Son (GFS) rotation to balance history with the 2TB storage limit.

**Related**:

* [Hardware Inventory](http://docs.google.com/hardware.md)  
* [Storage Configuration](https://www.google.com/search?q=storage.md)  
* [Maintenance Procedures](https://www.google.com/search?q=maintenance.md)

## **November 2025**

### **2025-11-25**

**Tailscale VPN Deployed**

* Created unprivileged LXC container on TMG using Debian 12 template  
* Container ID: 102, Storage: local-zfs, 512MB RAM, 2GB disk  
* Installed Tailscale via community addon script  
* Configured as subnet router for 10.0.0.0/24  
* Enabled IP forwarding in container for routing functionality  
* Approved subnet routes in Tailscale admin console

**Decisions Made**:

* Deployed on TMG (lightweight service, low power node)  
* Used unprivileged container for security  
* Single subnet router approach (simple, effective for homelab)  
* Removed previous Tailscale installation from Home Assistant to avoid conflicts

**Commands Used**:

\# Created container  
pct create 102 local:vztmpl/debian-12-standard\_12.12-1\_amd64.tar.zst \\  
  \--hostname tailscale \--memory 512 \--cores 1 \--rootfs local-zfs:2 \\  
  \--net0 name=eth0,bridge=vmbr0,ip=dhcp \--unprivileged 1 \--onboot 1 \\  
  \--features nesting=1

\# Installed Tailscale  
bash \-c "$(curl \-fsSL \[https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/add-tailscale-lxc.sh\](https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/add-tailscale-lxc.sh))"

\# Enabled IP forwarding  
echo 'net.ipv4.ip\_forward \= 1' \>\> /etc/sysctl.conf  
echo 'net.ipv6.conf.all.forwarding \= 1' \>\> /etc/sysctl.conf  
sysctl \-p

\# Configured subnet routing  
tailscale up \--advertise-routes=10.0.0.0/24 \--accept-routes

**Documentation**:

* Added [Tailscale documentation](https://www.google.com/search?q=services/tailscale.md)  
* Updated services index

### **2025-11-24**

**Nginx Proxy Manager Deployed**

* Created LXC container on TMG using community helper script  
* Container ID: 101, IP: 10.0.0.238 (reserved in Unifi)  
* Currently serving local HTML tools at /tools/  
* Management UI accessible at http://10.0.0.238:81  
* Will be used for reverse proxy configuration in the future

**Button Automation Generator Tool**

* Created local HTML tool for generating Home Assistant button automation YAML templates  
* Tool hosted at http://10.0.0.238/tools/  
* Provides structured framework for multi-action button automations (single, double, long press, release)  
* Uses named trigger IDs and choose/option blocks for clear action routing

**Design Decisions**:

* Chose template generator over Home Assistant blueprints for better flexibility  
* Blueprints were too limiting for adding complex conditions and custom logic  
* Template approach provides structure while maintaining full automation editor functionality  
* Deployed NPM on TMG (low-power node) since it's a lightweight service  
* NPM chosen over plain nginx for future reverse proxy needs with web UI management

**Documentation**:

* Added tool documentation to services section  
* Added Nginx Proxy Manager documentation  
* [Button Automation Generator](https://www.google.com/search?q=services/button-automation-generator.md)  
* [Nginx Proxy Manager](https://www.google.com/search?q=services/nginxproxymanager.md)

### **2025-11-23**

**IoT WiFi Network Created**

* Created dedicated 2.4GHz-only WiFi network for IoT devices  
* Enabled legacy support for compatibility with older devices  
* Purpose: Prevent issues with devices that don't handle dual-band networks

**Broadlink RM4 Mini Added**

* Added Broadlink RM4 Mini IR blaster to Home Assistant  
* Location: Living room  
* Purpose: Control AC unit via IR  
* Created scripts for AC on/off control

**Unifi Controller Migrated to Proxmox**

* Created LXC container on SB using community helper script  
* Migrated from macOS laptop to self-hosted  
* Restored backup from laptop controller  
* Used built-in migration function to re-adopt all devices  
* Reserved IP 10.0.0.250 in DHCP settings  
* Container ID: 100, Storage: local-zfs

**DHCP Range Updated**

* Changed DHCP range from .6-.254 to .16-.254  
* Freed .2-.15 for static IP assignments  
* Disabled Auto-Scale Network to allow manual control

**Proxmox Cluster Established**

* Installed Proxmox VE on all three nodes  
* Cluster name: BonConLab  
* Ran community post-install script on all nodes (removed subscription nag, added no-subscription repo)

**Node Configuration**:

* **SB** (10.0.0.2): Boot mirror on 2x 256GB NVMe, added sb-1tb-ssd datastore  
* **TMG** (10.0.0.3): Boot mirror on 256GB NVMe \+ 256GB SATA SSD  
* **DB** (10.0.0.4): Reinstalled with 1TB SSD as boot, freeing 2TB NVMe for VM storage

**Storage Configured on DB**:

* Created ZFS pools: db-2tb-nvme, db-4tb-hdd-internal  
* Formatted and mounted external drives:  
  * external-18tb-hdd at /mnt/external-18tb-hdd  
  * external-4tb-hdd-1 at /mnt/external-4tb-hdd-1  
  * external-4tb-hdd-2 at /mnt/external-4tb-hdd-2  
* Added all external drives as Directory storage in Proxmox

**Decisions Made**:

* Disabled HA services (no shared storage for automatic failover)  
* Kept Corosync enabled for cluster communication  
* Storage naming convention: \[node\]-\[size\]-\[type\] for internal, external-\[size\]-\[type\] for external  
* External drives formatted as ext4, not ZFS (USB \+ SMR limitations)

**Notes**:

* DB's 500GB HDD retired to make room for DVD drive (media ripping)  
* 18TB external drive was wiped — previously had movies on it (lesson learned: check before wiping)

**Documentation**:

* Created BonConLab wiki and pushed to GitHub  
* Set up Claude project with wiki as reference  
* Added Home Assistant documentation at root level

## **Template for New Entries**

\#\#\# YYYY-MM-DD

\*\*Summary of Change\*\*

\- Bullet points of what was done  
\- Commands run or configs changed  
\- Any issues encountered and how they were resolved

\*\*Decisions Made\*\*:  
\- Reasoning for choices

\*\*Related\*\*: \[link-to-relevant-doc\](relevant-doc.md)  
