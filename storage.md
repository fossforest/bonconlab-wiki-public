# **Storage Configuration**

ZFS pools, mount points, and storage strategy for BonConLab.

## **Storage Strategy**

**Principle**: Tiered storage architecture.

1. **Boot**: Redundant ZFS mirrors for OS reliability.  
2. **Fast Tier (NVMe)**: OS/Databases for VMs and Containers (High IOPS).  
3. **Warm Tier (SATA SSD)**: Bulk storage, NAS, and Backup Targets (High Capacity, Redundant).  
4. **Cold Tier (USB HDD)**: Media archives and offsite backup rotation.

**Backup approach**: Automated nightly snapshots via Proxmox Backup Server (PBS) with deduplication.

## **Proxmox Storage Summary**

| ID | Type | Node | Capacity | Purpose |
| :---- | :---- | :---- | :---- | :---- |
| sb-1tb-ssd | ZFS | SB | 1TB | VM/container storage |
| db-2tb-nvme | ZFS | DB | 2TB | VM/container storage (Fast Tier) |
| db-2tb-warm | ZFS | DB | 2TB | NAS & Backup storage (Warm Tier) |
| pbs-db | PBS | All | \~2TB | Centralized Backup Target (backed by db-2tb-warm) |
| external-18tb-hdd | Directory | DB | 18TB | Media Archive (Passthrough to NAS) |
| external-4tb-hdd-1 | Directory | DB | 4TB | Media (Passthrough to NAS) |
| external-4tb-hdd-2 | Directory | DB | 4TB | Media (Passthrough to NAS) |
| local | Directory | All | varies | Default, boot drive overflow |
| local-zfs | ZFS | All | varies | Default boot drive pool |

## **ZFS Pools**

### **SB (sb)**

| Pool | Devices | Type | Mount | Notes |
| :---- | :---- | :---- | :---- | :---- |
| rpool | 2x 256GB NVMe | mirror | / | Boot pool |
| sb-1tb-ssd | 1TB SATA SSD | single | — | Proxmox datastore |

### **TMG (tmg)**

| Pool | Devices | Type | Mount | Notes |
| :---- | :---- | :---- | :---- | :---- |
| rpool | 256GB NVMe \+ 256GB SATA | mirror | / | Boot pool |

### **DP**

| Pool | Devices | Type | Mount | Notes |
| :---- | :---- | :---- | :---- | :---- |
| rpool | 256GB Intel SSDSCKKF256G8 + 256GB Samsung SSD 840 PRO | mirror | / | Boot pool |

### **DB (db) \- *Updated 2026-01-30***

| Pool | Devices | Type | Mount | Notes |
| :---- | :---- | :---- | :---- | :---- |
| rpool | 2x 500GB SATA SSD (Samsung) | mirror | / | Redundant Boot pool |
| db-2tb-nvme | 1x 2TB Samsung 970 EVO Plus NVMe | single | — | Fast VM storage. **BIOS must be AHCI** (not RAID) or drive won't appear as `/dev/nvme*`. |
| db-2tb-warm | 2x 2TB SATA SSD (Crucial) | mirror | /db-2tb-warm | ZFS default mountpoint; backs the PBS datastore |

## **External Drives (Directory Storage)**

Physical drives are mounted via UUID in `/etc/fstab`. The 18TB drive uses **ext4** for the primary archive, while the 4TB drives use **exFAT** for portability.

| Mount Point | Device | Filesystem | Role | UUID |
| :--- | :--- | :--- | :--- | :--- |
| /mnt/external-18tb-hdd | sdf | ext4 | Primary Archive | 03ba879e-a730-4dcc-9bef-e1272665a380 |
| /mnt/external-4tb-hdd-1 | sdf2 | exfat | Expansion 1 | 697B-F155 |
| /mnt/external-4tb-hdd-2 | sdg2 | exfat | Expansion 2 | 697C-2A62 |

## **Virtual Storage Pool (mergerfs)**

A virtual pool aggregates only the `plex-media` subdirectories. This allows for "Out-of-Pool" storage (e.g., backups) on the same physical disks that remain invisible to Plex.

- **Virtual Mount**: `/mnt/virtual-media`
- **Source Paths**: `/mnt/external-18tb-hdd/plex-media:/mnt/external-4tb-hdd-1/plex-media:/mnt/external-4tb-hdd-2/plex-media`
- **LXC 302 Mapping**: `/mnt/media/all-content` (mp0)
- **fstab**: Uses explicit colon-separated paths (not glob) with `nofail` and `x-systemd.requires=` dependencies on all three USB drive mount units for boot resilience (updated 2026-03-19)

## **LXC Pass-through (Plex Container ID: 302)**

| Host Path | Container Path (MP) | Description |
| :--- | :--- | :--- |
| `/mnt/virtual-media` | `/mnt/media/all-content` (mp0) | Unified mergerfs pool (18TB ext4 + 2x 4TB exFAT) |

## **MergerFS Configuration**
- **Pool Path**: `/mnt/virtual-media`
- **Options**: `category.create=mfs` (Writes to drive with most free space)

## **Storage Content Types**

Proxmox restricts what can be stored on each storage location based on configured content types.

| Storage | Disk Image | Container | Backup | ISO | Template |
| :---- | :---- | :---- | :---- | :---- | :---- |
| sb-1tb-ssd | ✓ | ✓ | — | — | — |
| db-2tb-nvme | ✓ | ✓ | — | — | — |
| db-2tb-warm | ✓ | ✓ | — | — | — |
| pbs-db | — | — | ✓ (PBS) | — | — |
| local (on DB) | — | — | — | ✓ | ✓ |

## **Naming Conventions**

**Internal storage**: \[node\]-\[size\]-\[type\]

* Examples: sb-1tb-ssd, db-2tb-nvme, db-2tb-warm

**External storage**: external-\[size\]-\[type\]-\[number\]

* Examples: external-18tb-hdd

## **SMR Drive Warning**

The external drives (WD Elements 18TB, WD40EDAZ 4TB) use Shingled Magnetic Recording (SMR). This is fine for:

* Media storage (write-once, read-many)  
* Cold Archives

**Avoid using SMR drives for**:

* ZFS pools (resilvering is extremely slow)  
* VM/container OS drives  
* Databases

## **Future Considerations**

* \[x\] Set up automated backup jobs (Completed via PBS 2026-01-30)  
* \[ \] Configure nas-fileserver container for SMB sharing of external drives  
* \[ \] Setup Plex/Jellyfin with iGPU passthrough on DB  
* \[ \] Migrate external USB HDDs to internal SATA (via Glotrends PCIe card) — **deferred 2026-04-16**. Evaluated and declined: boot-race already solved via `nofail` + `x-systemd.requires=` (2026-03-19); no throughput or SMART gain that matters for SMR media; OptiPlex 7060 SFF has no free 3.5" bay. Revisit if DB moves to a chassis with proper drive bays, or if the USB enclosure starts misbehaving.