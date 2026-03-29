# **Maintenance Procedures**

Common maintenance tasks, update procedures, and recovery steps for BonConLab.

## **Routine Updates**

### **Proxmox Nodes**

Run on each node (SB, TMG, DB, DP):

\# Update package lists and upgrade all packages  
apt update && apt dist-upgrade \-y

\# Clean up old packages  
apt autoremove \-y

**Recommended frequency**: Weekly, or before deploying new services.

### **Home Assistant**

Updates are managed through the HA web UI:

1. Settings → System → Updates  
2. Review release notes before updating  
3. Create a snapshot before major updates

## **Standard Practices**

### **Config File Backups**

Always create a timestamped backup before editing critical system config files:

```
cp <file> <file>.bak.$(date +%Y%m%d)
```

Applies to: `/etc/fstab`, `/etc/samba/smb.conf`, container configs (`/etc/pve/lxc/<id>.conf`), and any system-level configuration.

## **Service Management**

### **Restart a Proxmox Node**

\# Graceful reboot  
reboot

\# If unresponsive, from another machine or via JetKVM  
\# Hold power button or use IPMI/KVM

### **Check Node Status**

\# System uptime and load  
uptime

\# Memory usage  
free \-h

\# Disk usage  
df \-h

\# ZFS pool status  
zpool status

### **Check Cluster Status**

From any Proxmox node:

\# Cluster membership  
pvecm status

\# Node list  
pvecm nodes

## **ZFS Maintenance**

### **Check Pool Health**

\# Status of all pools  
zpool status

\# Detailed pool info  
zpool list \-v

### **Scrub Pools**

Scrubs check data integrity. Run monthly.

\# Start scrub on a pool  
zpool scrub \<pool-name\>

\# Examples
zpool scrub sb-1tb-ssd
zpool scrub rpool  \# Run on dp for its boot pool

\# Check scrub progress  
zpool status

### **Check for Errors**

\# Show any ZFS errors  
zpool status \-x

## **Backup Procedures**

### **Automated Backups (Proxmox Backup Server)**

The cluster is configured for automated nightly backups to the pbs-db target.

* **Schedule**: Daily at 04:00 AM  
* **Target**: db-proxmox-backup-server (LXC 301 on DB)  
* **Mode**: Snapshot (Zero downtime)  
* **Retention**: Keep 3 Last, 7 Daily, 4 Weekly, 1 Monthly  
* **Garbage Collection**: Runs daily on PBS to free space

**To verify backups:**

1. Log into PBS: https://10.0.0.202:8007  
2. Go to Datastore \> Content to see list of snapshots  
3. Check "Verify Jobs" tab to ensure data integrity

### **Manual VM Backup**

Use for "Pre-Change" snapshots or ad-hoc saves.

From Proxmox UI:

1. Select VM/container  
2. Backup → Backup now  
3. Storage: db-proxmox-backup-server  
4. Mode: Snapshot  
5. Notes: Use \!backup-pre or \!backup-wip snippet format

### **Verify External Drives Are Mounted**

On DB (for media/NAS use):

df \-h | grep external

Should show all three external drives (18TB, 4TB, 4TB).

## **Recovery Procedures**

### **Node Won't Boot**

1. Connect via JetKVM or local monitor  
2. Check BIOS settings (Secure Boot disabled?)  
3. Boot from Proxmox installer USB → Rescue mode  
4. Check ZFS pool: zpool import \-f rpool

### **VM Won't Start**

\# Check VM status  
qm status \<vmid\>

\# View recent logs  
journalctl \-u pve-guests \-n 50

\# Force stop if stuck  
qm stop \<vmid\> \--skiplock

### **Cluster Communication Issues**

\# Check corosync status  
systemctl status corosync

\# View cluster logs  
journalctl \-u corosync \-n 100

\# If a node needs to be re-added  
\# From working node:  
pvecm delnode \<nodename\>  
\# Then rejoin from the removed node

### **External Drive Not Mounting**

\# Check if drive is detected
lsblk

\# Check for filesystem issues
fsck /dev/sdX

\# Manual mount for testing
mount /dev/sdX /mnt/external-18tb-hdd

### **Missing ZFS Pool (NVMe Remapping)**

If a ZFS pool backed by NVMe is missing after reboot and `lsblk` shows no `/dev/nvme*` device:

1\. Check dmesg for NVMe remapping messages:

\# Look for "Found N remapped NVMe devices"
dmesg | grep \-i nvme

2\. If remapping is reported → BIOS is in RAID mode. Reboot into BIOS (F2 on Dell OptiPlex), change **SATA Operation** from "RAID On" to "AHCI".
3\. On next boot the NVMe will appear as `/dev/nvme0n1` and ZFS will auto-import the pool.

### **Post-Power Outage: Verify BIOS Settings**

After any power outage or CMOS battery replacement, verify BIOS settings on affected nodes before assuming a hardware failure:

1\. Enter BIOS (F2 during POST on Dell OptiPlex)
2\. Confirm **SATA Operation = AHCI** (not RAID On). RAID mode on the OptiPlex 7060 SFF remaps NVMe through the AHCI controller, making it invisible to Linux.
3\. Confirm boot sequence includes Proxmox entries and Boot List Option is set to **UEFI**.
4\. Check **Drives screen** to verify all physical drives are detected.

Note: DB (Dell OptiPlex 7060 SFF) is particularly vulnerable — its factory default is RAID mode. A dead CMOS battery will reset BIOS to this default silently; the effect only appears after the next full reboot.

## **Network Troubleshooting**

### **Check Connectivity**

\# Ping gateway  
ping 10.0.0.1

\# Ping external  
ping 1.1.1.1

\# DNS resolution  
nslookup google.com

### **Check Network Interface**

\# Interface status  
ip a

\# Routing table  
ip route

## **Useful Paths**

| Path | Purpose |
| :---- | :---- |
| /etc/pve/ | Proxmox cluster config |
| /etc/fstab | Filesystem mount table |
| /var/log/ | System logs |
| /mnt/external-\* | External drive mounts (on DB) |
| /mnt/backups | PBS Bind Mount (on DB) |

## **Emergency Contacts / Resources**

* **Proxmox Forums**: https://forum.proxmox.com/  
* **Proxmox Docs**: https://pve.proxmox.com/wiki/  
* **Home Assistant Community**: https://community.home-assistant.io/  
* **ZFS Docs**: https://openzfs.github.io/openzfs-docs/

## **Scheduled Maintenance Checklist**

**Weekly**:

* \[ \] Check Proxmox node updates  
* \[ \] Review HA logs for errors  
* \[ \] Verify PBS dashboard (Datastore usage & recent tasks)

**Monthly**:

* \[ \] Run ZFS scrub on all pools  
* \[ \] Review storage usage (Proxmox & PBS)  
* \[ \] Test one backup restoration (restore to a new ID, boot, verify, delete)  
* \[ \] Check PBS Garbage Collection logs to ensure pruning is working

**Quarterly**:

* \[ \] Review and prune old backups
* \[ \] Check for Proxmox major version updates
* \[ \] Audit running services and disable unused ones
* \[ \] Check CMOS battery on older nodes (especially DB — Dell OptiPlex 7060 SFF). Keep spare CR2032 batteries on hand.