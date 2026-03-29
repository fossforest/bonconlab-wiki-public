# PiHole

Network-wide ad blocking and DNS filtering with active-active redundancy.

## Overview

| Property | Value |
|----------|-------|
| Primary Node | TMG (tmg) |
| Backup Node | Raspberry Pi 3 Model B |
| Type | LXC Container (TMG), Bare metal (Pi) |
| Primary IP | 10.0.0.10 |
| Backup IP | 10.0.0.229 |
| Port | 80/tcp (web UI), 53/udp (DNS) |
| Container ID | 103 (TMG) |
| Storage | local-zfs (TMG) |
| Status | ✅ Active |

## Access

- **Primary Web UI**: http://10.0.0.10/admin
- **Backup Web UI**: http://10.0.0.229/admin

## Architecture

**Active-Active Configuration**: Both PiHole instances handle DNS queries simultaneously. Clients are configured via Tailscale with both DNS IPs, providing automatic failover.

**Why active-active over active-passive?**
- Simpler configuration (no VRRP/keepalived required)
- Modern clients (iOS/Android/macOS) query all DNS servers in parallel
- Automatic load distribution
- Zero downtime during maintenance windows
- Adequate for homelab scale (20-30 devices)

**Unbound Configuration:**
- **TMG**: Full recursive DNS resolver - queries root servers directly
- **Pi 3**: Forwarding resolver via DNS-over-TLS to Quad9 - lighter resource usage

## Installation

### Primary (TMG LXC Container)

Installed via community helper script on 2025-12-25:

```bash
# On TMG Proxmox host
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/pihole.sh)"
```

**Container specifications:**
- CPU: 1 core
- RAM: 512 MB
- Disk: 4 GB
- Type: Unprivileged
- Features: nesting=1
- Network: Static IP 10.0.0.10/24
- Container ID: 103
- Hostname: pihole-tmg

**Post-installation configuration:**
1. Set static IP via Proxmox: `pct set 103 -net0 name=eth0,bridge=vmbr0,ip=10.0.0.10/24,gw=10.0.0.1`
2. Reserved IP in Unifi as "PiHole_TMG"
3. Changed hostname to `pihole-tmg`
4. Configured upstream DNS to point to Unbound (127.0.0.1#5335)
5. Unbound installed with default recursive configuration

### Backup (Raspberry Pi 3)

Installed on 2025-12-25.

**Prerequisites:**
- Raspberry Pi OS Lite (Bookworm)
- Quality SD card (32GB recommended)
- Official Raspberry Pi 2.5A power supply

**Install Log2Ram first** (reduces SD card wear by 90%):

```bash
echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ bookworm main" | sudo tee /etc/apt/sources.list.d/azlux.list
wget -O- https://azlux.fr/repo.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/azlux-archive-keyring.gpg
sudo apt update && sudo apt install log2ram
sudo reboot
```

**Install PiHole:**

```bash
curl -sSL https://install.pi-hole.net | bash
```

Configure during installation:
- Accept default blocklists
- Enable web interface
- Static IP: 10.0.0.229 (reserved in Unifi as "PiHole_Pi3")

**Install and Configure Unbound (DNS-over-TLS forwarding):**

```bash
# Install Unbound
sudo apt update && sudo apt install unbound

# Create configuration
sudo nano /etc/unbound/unbound.conf.d/pi-hole.conf
```

Unbound configuration for DoT forwarding:

```yaml
server:
    # Listen on localhost for PiHole
    interface: 127.0.0.1
    port: 5335
    
    # Performance - lighter for Pi 3
    num-threads: 1
    msg-cache-size: 25m
    rrset-cache-size: 50m
    
    # Privacy
    hide-identity: yes
    hide-version: yes
    
    # DNSSEC
    auto-trust-anchor-file: "/var/lib/unbound/root.key"
    
    # TLS certificate bundle
    tls-cert-bundle: /etc/ssl/certs/ca-certificates.crt
    
    # Performance tuning
    prefetch: yes
    serve-expired: yes

# Forward to Quad9 via DNS-over-TLS
forward-zone:
    name: "."
    forward-tls-upstream: yes
    forward-addr: 9.9.9.9@853#dns.quad9.net
    forward-addr: 149.112.112.112@853#dns.quad9.net
```

Start Unbound:

```bash
sudo systemctl start unbound
sudo systemctl enable unbound
```

**Configure PiHole to use Unbound:**

In PiHole web UI (Settings → DNS):
- Uncheck all default upstream DNS servers
- Add custom DNS: `127.0.0.1#5335`

**Optimize for SD card longevity:**

```bash
sudo nano /etc/pihole/pihole-FTL.conf
```

Add:
```
MAXDBDAYS=7
```

Restart PiHole:
```bash
sudo pihole restartdns
```

## Blocklist Synchronization

Using **Nebula Sync** to keep blocklists identical across both instances. Deployed on TMG LXC container 103.

### Deploy Nebula Sync (on TMG)

```bash
# Enter TMG PiHole container
pct enter 103

# Install Docker
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# Create directory and compose file
mkdir -p /opt/nebula-sync
cd /opt/nebula-sync
nano docker-compose.yml
```

Docker Compose configuration:

```yaml
services:
  nebula-sync:
    image: ghcr.io/lovelaze/nebula-sync:latest
    container_name: nebula-sync
    network_mode: host
    environment:
      - PRIMARY=http://127.0.0.1|your_tmg_pihole_password
      - REPLICAS=http://10.0.0.229|your_pi3_pihole_password
      - FULL_SYNC=true
      - RUN_GRAVITY=true
      - CRON=0 * * * *
    restart: unless-stopped
```

Start Nebula Sync:

```bash
docker compose up -d
```

**What gets synchronized:**
- Adlists (blocklists)
- Whitelist/blacklist entries
- Local DNS records
- Client groups
- DHCP static assignments

**What doesn't sync:**
- Upstream DNS settings (configured separately on each instance)
- Admin passwords (set separately)
- Interface/network settings

### Sync Schedule

Hourly sync (`0 * * * *`). Adjust if needed in docker-compose.yml.

**Manual sync trigger:**
```bash
pct enter 103
docker exec nebula-sync python3 /app/nebula_sync.py
```

**Check sync status:**
```bash
pct enter 103
docker logs nebula-sync
```

## Tailscale Integration

DNS is configured via Tailscale for devices connected to the tailnet. Local network devices do NOT use PiHole by default.

**Tailscale DNS Configuration:**
- Nameserver 1: 10.0.0.10 (TMG primary)
- Nameserver 2: 10.0.0.229 (Pi3 backup)
- Override local DNS: Enabled

**Behavior:**
- Devices connected to Tailscale use PiHole for ad-blocking and recursive DNS
- Devices NOT on Tailscale use ISP/default DNS (no ad-blocking)
- Provides easy toggle for troubleshooting and guest mode

## Maintenance

### Container Management (TMG)

```bash
# Check container status
pct status 103

# Start/stop/restart
pct start 103
pct stop 103
pct reboot 103

# Access container shell
pct enter 103
```

### Updates

**TMG LXC Container:**
```bash
pct enter 103
pihole -up
```

**Raspberry Pi 3:**
```bash
ssh pi@10.0.0.229
sudo pihole -up
```

Updates are typically released monthly. Check release notes before updating.

### Nebula Sync Maintenance

**Update Nebula Sync:**
```bash
pct enter 103
cd /opt/nebula-sync
docker compose pull
docker compose up -d
```

**View logs:**
```bash
docker logs nebula-sync
```

**Restart sync container:**
```bash
docker compose restart
```

### Backup

**TMG Container:**
- Backup entire container via Proxmox UI: Select container 103 → Backup → Backup now
- Store on external drives for redundancy

**Raspberry Pi 3:**
- Create SD card image backup periodically
- Use PiHole Teleporter for settings backup

**Both instances - PiHole settings:**
- Settings → Teleporter → Backup
- Download and store in external backup location
- Includes all blocklists, whitelist/blacklist, local DNS, and settings

### Log Rotation

Both instances configured to limit log retention:
- Query logs: 24 hours (default)
- Database history: 7 days (via `MAXDBDAYS=7`)
- Log2Ram syncs to SD card daily (Pi 3 only)

## Performance Expectations

**TMG LXC:**
- Response time: <2ms (local network)
- Queries/second: 1000+
- CPU usage: <5%
- RAM usage: ~200MB with standard blocklists

**Raspberry Pi 3:**
- Response time: 3-5ms
- Queries/second: 2700+
- CPU usage: <5%
- RAM usage: ~200MB with standard blocklists
- Temperature: 40-55°C (no heatsink needed)

Both instances handle 20-30 devices with ease. The Pi 3 has headroom for 100+ devices.

## Troubleshooting

### DNS not resolving

1. Check PiHole service status:
   ```bash
   pihole status
   ```

2. Verify DNS port is listening:
   ```bash
   netstat -tulpn | grep :53
   ```

3. Test direct query:
   ```bash
   dig @10.0.0.10 google.com
   ```

### Unbound not working

**TMG (recursive):**
```bash
pct enter 103
dig @127.0.0.1 -p 5335 google.com
systemctl status unbound
```

**Pi3 (DoT forwarding):**
```bash
ssh pi@10.0.0.229
dig @127.0.0.1 -p 5335 google.com
sudo systemctl status unbound
```

### Nebula Sync not working

```bash
pct enter 103
docker logs nebula-sync

# Check if container is running
docker ps

# Restart if needed
cd /opt/nebula-sync
docker compose restart
```

Common issues:
- Wrong passwords in docker-compose.yml
- Network connectivity between containers
- One PiHole instance unreachable

### Client not using PiHole

1. Verify client is connected to Tailscale
2. Check Tailscale DNS settings in admin console
3. On client, verify DNS: `nslookup pi.hole`
4. Check query logs on both PiHole instances

### Blocklists not syncing

1. Check Nebula Sync logs: `docker logs nebula-sync`
2. Trigger manual sync: `docker exec nebula-sync python3 /app/nebula_sync.py`
3. Verify passwords in docker-compose.yml are correct
4. Check network connectivity: `ping 10.0.0.229` from TMG

### Pi 3 not accessible

1. Check power supply (LED indicators)
2. Connect monitor/keyboard for local access
3. Verify network cable connection
4. Check DHCP lease or static IP configuration
5. Verify Log2Ram isn't causing issues: `df -h | grep log2ram`

### High memory usage

Standard with large blocklists (1M+ domains). If approaching limits:
1. Review blocklist count: Settings → Adlists
2. Remove duplicate or unnecessary lists
3. Consider reducing cache sizes in Unbound config
4. For TMG: Increase container RAM to 1GB if needed

## Network Integration Notes

### Conditional Forwarding

Both PiHole instances have conditional forwarding enabled:
- IP: 10.0.0.1 (USG)
- Local domain: local

This allows PiHole to resolve local hostnames by querying the USG's DNS.

### Client Failover Behavior

**Windows**: 1-second timeout before trying secondary DNS
**macOS/iOS/Android**: Parallel queries to all DNS servers, accepts fastest response
**Linux**: Varies by resolver; systemd-resolved uses parallel queries

Average failover time when primary is down: 1-5 seconds (imperceptible for web browsing).

### Testing Failover

```bash
# Stop TMG PiHole
pct stop 103

# Keep browsing - should automatically use Pi3
# Check Pi3 query logs to verify

# Restart TMG
pct start 103
```

## Related

- [Network Configuration](../network.md)
- [Services Index](_services-index.md)
- [Maintenance Procedures](../maintenance.md)
- [Hardware Inventory](../hardware.md) (Pi 3 specs)
- [Tailscale](tailscale.md)

## Additional Resources

- **PiHole Documentation**: https://docs.pi-hole.net/
- **Nebula Sync GitHub**: https://github.com/lovelaze/nebula-sync
- **Unbound Documentation**: https://nlnetlabs.nl/documentation/unbound/
- **Community Scripts**: https://github.com/community-scripts/ProxmoxVE
- **Log2Ram**: https://github.com/azlux/log2ram
