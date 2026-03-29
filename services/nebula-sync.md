# Nebula Sync

Automated synchronization service for maintaining identical configurations across multiple PiHole instances.

## Overview

| Property | Value |
|----------|-------|
| Node | TMG (tmg) |
| Type | Docker Container |
| Host Container | PiHole LXC 103 |
| Port | N/A (internal only) |
| Status | ✅ Active |

## Purpose

Nebula Sync keeps blocklists, whitelists, blacklists, local DNS records, client groups, and DHCP static assignments synchronized between the primary PiHole (TMG) and backup PiHole (Pi3). This ensures consistent ad-blocking behavior regardless of which DNS server handles a query.

**Why synchronization is necessary:**
In an active-active DNS setup, modern clients (iOS/Android/macOS) query both DNS servers simultaneously. Without synchronization, blocklists could differ between servers, causing inconsistent blocking—sometimes blocked, sometimes not—which is confusing to troubleshoot.

## Architecture

**Deployment**: Runs as a Docker container inside the TMG PiHole LXC container (103)

**Sync Direction**: Primary (TMG) → Replica (Pi3)
- TMG at 10.0.0.10 is the source of truth
- Pi3 at 10.0.0.229 receives updates
- One-way sync prevents conflicts

**Schedule**: Hourly via cron (`0 * * * *`)

## Installation

Installed on 2025-12-26 inside PiHole LXC container 103.

### Prerequisites

Docker must be installed in the LXC container:

```bash
# Enter PiHole container
pct enter 103

# Install Docker
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker
```

### Deploy Nebula Sync

```bash
# Create directory
mkdir -p /opt/nebula-sync
cd /opt/nebula-sync

# Create docker-compose.yml
nano docker-compose.yml
```

**docker-compose.yml:**

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

**Important notes:**
- `network_mode: host` is required for the container to access PiHole on localhost
- Replace `your_tmg_pihole_password` and `your_pi3_pihole_password` with actual passwords
- PRIMARY uses `127.0.0.1` since it's running inside the same LXC as PiHole

**Start the service:**

```bash
docker compose up -d
```

## Configuration

### What Gets Synchronized

- ✅ Adlists (blocklists)
- ✅ Whitelists
- ✅ Blacklists (exact and regex)
- ✅ Local DNS records
- ✅ Client groups
- ✅ DHCP static assignments

### What Doesn't Sync

- ❌ Upstream DNS settings (configured separately on each PiHole)
- ❌ Admin passwords (set independently)
- ❌ Interface/network settings
- ❌ Query logs and statistics

These are intentionally not synced because they're instance-specific.

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| PRIMARY | http://127.0.0.1\|password | Source PiHole (TMG) |
| REPLICAS | http://10.0.0.229\|password | Target PiHole(s) (Pi3) |
| FULL_SYNC | true | Sync all configuration types |
| RUN_GRAVITY | true | Update blocklists after sync |
| CRON | 0 * * * * | Hourly at top of hour |

**CRON schedule options:**
- Hourly: `0 * * * *` (current)
- Every 5 minutes: `*/5 * * * *` (if frequently changing blocklists)
- Daily: `0 0 * * *` (if very static configuration)

## Usage

### Check Sync Status

```bash
# From TMG host
pct enter 103

# View logs
docker logs nebula-sync

# Check if container is running
docker ps
```

**Successful sync output looks like:**
```
2025-12-26T08:08:02Z INF Starting nebula-sync v0.11.1
2025-12-26T08:08:02Z INF Running sync mode=full replicas=1
2025-12-26T08:08:02Z INF Authenticating clients...
2025-12-26T08:08:03Z INF Syncing teleporters...
2025-12-26T08:08:03Z INF Syncing configs...
2025-12-26T08:08:03Z INF Running gravity...
2025-12-26T08:08:03Z INF Invalidating sessions...
2025-12-26T08:08:03Z INF Sync completed
```

### Manual Sync Trigger

To trigger an immediate sync without waiting for the hourly schedule:

```bash
# From inside PiHole container
docker exec nebula-sync python3 /app/nebula_sync.py
```

This is useful after making blocklist changes and wanting them to propagate immediately.

### Verify Synchronization

**Method 1 - Compare blocklists:**
1. Check TMG: http://10.0.0.10/admin → Settings → Adlists
2. Check Pi3: http://10.0.0.229/admin → Settings → Adlists
3. Lists should match exactly

**Method 2 - Check group counts:**
Both PiHoles should show the same number of:
- Blocklist entries
- Whitelist entries
- Local DNS records
- Client groups

## Maintenance

### Update Nebula Sync

```bash
# From TMG host
pct enter 103
cd /opt/nebula-sync

# Pull latest image
docker compose pull

# Restart with new image
docker compose up -d
```

### Restart Container

```bash
pct enter 103
cd /opt/nebula-sync
docker compose restart
```

### Change Sync Password

If PiHole password changes:

```bash
# Edit compose file
nano /opt/nebula-sync/docker-compose.yml

# Update the password in PRIMARY or REPLICAS line
# Save and exit

# Restart container to apply
docker compose up -d
```

### Change Sync Schedule

```bash
# Edit compose file
nano /opt/nebula-sync/docker-compose.yml

# Change CRON value (e.g., to every 5 minutes: */5 * * * *)
# Save and exit

# Restart container
docker compose up -d
```

### View Detailed Logs

```bash
# Real-time logs
docker logs -f nebula-sync

# Last 50 lines
docker logs --tail 50 nebula-sync

# Logs since specific time
docker logs --since 1h nebula-sync
```

## Troubleshooting

### Sync Failing - Authentication Error

**Symptoms:** Logs show "authenticate: Post: connection refused" or authentication failures

**Causes:**
1. Wrong password in docker-compose.yml
2. PiHole API not accessible

**Fix:**
```bash
# Test PiHole API access from container
pct enter 103
curl http://127.0.0.1/admin/api.php
curl http://10.0.0.229/admin/api.php

# If curl fails, check PiHole is running
pihole status

# Verify passwords in compose file
nano /opt/nebula-sync/docker-compose.yml

# Restart after fixing
docker compose restart
```

### Container Constantly Restarting

**Check logs for error:**
```bash
docker logs nebula-sync
```

**Common causes:**
- Network configuration issue (missing `network_mode: host`)
- Invalid CRON syntax
- Corrupted image

**Fix:**
```bash
# Stop and remove container
docker compose down

# Pull fresh image
docker compose pull

# Recreate container
docker compose up -d
```

### Pi3 PiHole Unreachable

**Symptoms:** Logs show connection timeout to 10.0.0.229

**Causes:**
1. Pi3 is offline
2. Network connectivity issue
3. PiHole service not running on Pi3

**Fix:**
```bash
# From TMG, test connectivity
ping 10.0.0.229

# SSH to Pi3 and check PiHole
ssh pi@10.0.0.229
sudo pihole status

# Restart PiHole if needed
sudo pihole restartdns
```

### Blocklists Not Syncing

**Symptoms:** Added blocklist on TMG doesn't appear on Pi3 after sync

**Debugging steps:**

1. Check sync logs show success
2. Trigger manual sync and watch output
3. Verify both PiHoles are on same version: Settings → System
4. Check if gravity ran: `docker logs nebula-sync | grep gravity`

**Force full resync:**
```bash
# Stop container
docker compose down

# Clear any cached state (if needed)
docker compose up -d

# Trigger manual sync
docker exec nebula-sync python3 /app/nebula_sync.py
```

### Container Not Found

**Symptoms:** `docker ps` doesn't show nebula-sync

**Fix:**
```bash
# Check if it exited
docker ps -a

# View why it stopped
docker logs nebula-sync

# Restart
cd /opt/nebula-sync
docker compose up -d
```

## Performance Impact

**Resource Usage:**
- CPU: Negligible (only active during hourly sync, <1% spike)
- RAM: ~50-100MB
- Network: Minimal (only API calls during sync)
- Sync Duration: 5-10 seconds typically

**Impact on PiHole:**
- No performance degradation
- Brief API activity during sync
- Gravity update may briefly increase DNS response time (1-2 seconds)

## Security Considerations

**Passwords in Compose File:**
- Stored in plain text in docker-compose.yml
- File permissions: Readable only by root (container runs in root context)
- Consider using Docker secrets for production (overkill for homelab)

**Network Access:**
- Container can access both PiHole instances
- Uses `network_mode: host` to reach localhost
- No ports exposed outside container

## Related

- [PiHole](pihole.md) - Primary service being synchronized
- [Services Index](_services-index.md)
- [Maintenance Procedures](../maintenance.md)

## Additional Resources

- **Nebula Sync GitHub**: https://github.com/lovelaze/nebula-sync
- **Docker Documentation**: https://docs.docker.com/compose/
- **PiHole Teleporter**: Built-in backup/restore (Settings → Teleporter)
