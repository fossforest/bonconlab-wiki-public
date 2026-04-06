# NAS / Fileshare

Central file server providing NFS exports to cluster containers and SMB shares for macOS clients.

## Overview

| Property | Value |
|----------|-------|
| Node | DB (db) |
| Type | Privileged LXC |
| Container ID | 303 |
| Hostname | db-nas-fileshare |
| IP | 10.0.0.206 (DHCP Reserved) |
| Storage | db-2tb-nvme (container OS) |
| Status | ✅ Active |

## Purpose

This container acts as the storage gateway for the cluster:

- **NFS Server**: Exports mergerfs pools and subdirectories to other LXC containers (Plex, Paperless-ngx, Manyfold, etc.)
- **Samba/SMB Server**: Provides network shares for Mac Mini and MacBook Pro with macOS-optimized compatibility

## Storage Architecture

### Bind Mounts (Host → Container)

| Mount | Host Path | Container Path | Description |
|-------|-----------|----------------|-------------|
| mp0 | /mnt/virtual-media | /srv/media-pool | mergerfs pool of `plex-media` subdirs |
| mp1 | /mnt/db-26tb-cold | /srv/cold | mergerfs pool of full external drives |
| mp2 | /db-2tb-warm | /srv/warm | ZFS mirror (fast SSD storage) |

### Pool Architecture

The DB host runs two concurrent mergerfs pools on the same physical disks:

**Plex Pool** (`/mnt/virtual-media`)
- **Scope**: Restricted to media directories only
- **Source**: `/mnt/external-18tb-hdd/plex-media:/mnt/external-4tb-hdd-1/plex-media:/mnt/external-4tb-hdd-2/plex-media`
- **Used by**: Plex LXC (302), NAS LXC (303) via `/srv/media-pool`
- **Purpose**: Prevents Plex from scanning non-media files

**Cold Root Pool** (`/mnt/db-26tb-cold`)
- **Scope**: Full drive access (26TB total)
- **Source**: `/mnt/external-18tb-hdd:/mnt/external-4tb-hdd-1:/mnt/external-4tb-hdd-2`
- **Used by**: NAS LXC (303) via `/srv/cold`
- **Purpose**: Full management of all external drive content via NFS/SMB

## NFS Configuration

NFS exports allow other containers on the subnet to mount storage directly.

### Exports

Current exports (`/etc/exports`):

```bash
# MergerFS Media Pool
/srv/media-pool  10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash,fsid=1)

# Cold Storage (full external drive pool)
/srv/cold   10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash,fsid=2)

# Per-service exports
/srv/cold/paperless_data  10.0.0.0/24(rw,sync,no_subtree_check,all_squash,anonuid=202,anongid=202,fsid=202)
/srv/cold/manyfold_data   10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash,fsid=203)
```

### Per-Service Export Pattern

For unprivileged containers that need write access, create dedicated exports with UID squashing:

```bash
# Example: adding a new service
mkdir -p /srv/cold/[service-name]
chown -R [uid]:[uid] /srv/cold/[service-name]

# Add to /etc/exports:
/srv/cold/[service-name]  10.0.0.0/24(rw,sync,no_subtree_check,all_squash,anonuid=[uid],anongid=[uid],fsid=[container-id])

# Apply changes
exportfs -ra
# exportfs — manages NFS export table
# -r — re-export all directories (reloads /etc/exports)
# -a — apply to all exports
```

### Proxmox Storage Integration

NFS exports are registered as Proxmox storage backends:

| Storage ID | Export | Mount Path | Nodes |
|------------|--------|------------|-------|
| db-nas-media-pool | /srv/media-pool | /mnt/pve/db-nas-media-pool | All |
| db-nas-cold-pool | /srv/cold | /mnt/pve/db-nas-cold-pool | All |
| db-nas-paperless-ngx | /srv/cold/paperless_data | /mnt/pve/db-nas-paperless-ngx | sb |
| db-nas-manyfold-storage | /srv/cold/manyfold_data | /mnt/pve/db-nas-manyfold-storage | sb |

## SMB/Samba Configuration

Samba provides network shares for macOS clients with `vfs_fruit` modules for Finder compatibility.

### Shares

| Share Name | Container Path | Description |
|------------|----------------|-------------|
| Media_Pool | /srv/media-pool | mergerfs plex-media pool |
| Warm_Storage | /srv/warm | Fast SSD (ZFS mirror) — active projects, documents |
| Cold_Storage | /srv/cold | Mass storage (26TB HDD pool) — archives, media |

### Authentication

- **User**: boncon (UID 1000)
- **Guest Access**: Disabled

### Config File

`/etc/samba/smb.conf`:

```ini
[global]
   workgroup = WORKGROUP
   server string = db-nas-fileserver
   security = user
   map to guest = Bad User
   min protocol = SMB2
   logging = file
   log file = /var/log/samba/log.%m
   max log size = 1000

   # macOS compatibility (Finder metadata, .DS_Store handling)
   vfs objects = fruit streams_xattr
   fruit:metadata = stream
   fruit:model = MacSamba
   fruit:posix_rename = yes
   fruit:veto_appledouble = no
   fruit:nfs_aces = no
   fruit:wipe_intentionally_left_blank_rfork = yes
   fruit:delete_empty_adfiles = yes

[Warm_Storage]
   comment = Fast SSD Storage (ZFS Mirror)
   path = /srv/warm
   browsable = yes
   writable = yes
   guest ok = no
   valid users = boncon
   create mask = 0664
   directory mask = 0775
   force user = root

[Cold_Storage]
   comment = 26TB External Pool (db-26tb-cold)
   path = /srv/cold
   browsable = yes
   writable = yes
   guest ok = no
   valid users = boncon
   create mask = 0664
   directory mask = 0775
   force user = root

[Media_Pool]
   comment = MergerFS Plex-Media pool
   path = /srv/media-pool
   browsable = yes
   writable = yes
   guest ok = no
   valid users = boncon
   create mask = 0664
   directory mask = 0775
   force user = root
```

### Connecting from macOS

1. **Finder → Go → Connect to Server** (Cmd+K)
2. Enter: `smb://10.0.0.206`
3. Authenticate as `boncon`
4. Select the share to mount

## Maintenance

### Container Management

From DB host:

```bash
# Check status
pct status 303
# pct status — shows if the container is running or stopped

# Start/stop/restart
pct start 303
pct stop 303
pct reboot 303
# pct start/stop/reboot — controls container power state

# Access shell
pct enter 303
# pct enter — opens an interactive shell inside the container
```

### Service Management

Inside container:

```bash
# NFS server status
systemctl status nfs-server
# systemctl status — shows whether a service is running, stopped, or failed

# Samba status
systemctl status smbd

# Restart services
systemctl restart nfs-server smbd

# View active NFS exports
exportfs -v
# exportfs -v — shows currently exported directories with options
```

### Adding a New SMB User

```bash
# Create system user (no login shell)
useradd -M -s /usr/sbin/nologin [username]
# useradd — creates a new user
# -M — no home directory
# -s /usr/sbin/nologin — cannot log in interactively

# Set Samba password
smbpasswd -a [username]
# smbpasswd -a — adds a new Samba user and sets password

# Enable the account
smbpasswd -e [username]
# smbpasswd -e — enables a Samba user account
```

## Troubleshooting

### NFS: Mount fails on client container

```bash
# Verify NFS server is running
pct enter 303
systemctl status nfs-server

# Check exports are active
exportfs -v

# Test mount from client side (from Proxmox host)
mount -t nfs 10.0.0.206:/srv/cold /mnt/test
# mount -t nfs — mounts a remote NFS share
```

### NFS: Permission denied on unprivileged container

The container's root UID maps to 100000+, which NFS doesn't recognize. Solutions:

1. **Preferred**: Create a per-service export with `all_squash,anonuid=X,anongid=X`
2. **Alternative**: Make the container privileged

### SMB: Share not appearing in Finder

```bash
# Verify Samba is running
pct enter 303
systemctl status smbd

# Test config syntax
testparm -s
# testparm — validates smb.conf syntax

# Check share is defined
testparm -s 2>/dev/null | grep -A5 "\[Warm_Storage\]"
```

### SMB: Can't write to share

1. Check user is in `valid users` for the share
2. Verify bind mount is working: `ls -la /srv/warm`
3. Check permissions on underlying host path

### Services won't start after reboot

Usually caused by bind mounts not being ready. From DB host:

```bash
# Check container config
cat /etc/pve/lxc/303.conf | grep mp

# Verify host paths exist
ls -la /mnt/virtual-media
ls -la /mnt/db-26tb-cold
ls -la /db-2tb-warm
```

## History

- **Initial setup**: NFS + Samba configured for media pool and cold storage
- **2026-03-19**: Added mp2 bind mount for warm storage, cleaned up smb.conf (merged duplicate `[global]` sections, removed boilerplate shares)

## Related

- [Plex](plex.md) — uses media-pool via NFS
- [Paperless-ngx](paperless-ngx.md) — uses per-service NFS export
- [Manyfold](manyfold.md) — uses per-service NFS export
- [Copyparty](copyparty.md) — alternative file access (web-based)
- [Storage Configuration](../storage.md)
- [Services Index](_services-index.md)
