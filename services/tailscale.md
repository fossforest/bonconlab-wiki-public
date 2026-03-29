# Tailscale

Secure mesh VPN with subnet routing for remote access to BonConLab.

## Overview

| Property | Value |
|----------|-------|
| Node | TMG (tmg) |
| Type | LXC Container |
| IP | DHCP |
| Container ID | 102 |
| Storage | local-zfs |
| Status | Active |

## Access

- **Tailscale Admin Console**: https://login.tailscale.com/admin/machines

## Purpose

Provides secure remote access to the entire `10.0.0.0/24` network via subnet routing. When connected to Tailscale from any device, you can reach:
- All three Proxmox nodes
- Home Assistant
- All VMs and containers
- Any other device on the local network

## Installation

Installed on 2025-11-25 using community helper script.

**Steps:**

1. Downloaded Debian 12 template:
```bash
pveam download local debian-12-standard_12.12-1_amd64.tar.zst
```

2. Created unprivileged LXC container:
```bash
pct create 102 local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst \
  --hostname tailscale \
  --memory 512 \
  --cores 1 \
  --rootfs local-zfs:2 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --unprivileged 1 \
  --onboot 1 \
  --features nesting=1
```

3. Started container and installed curl:
```bash
pct start 102
pct enter 102
apt update && apt install -y curl
exit
```

4. Ran Tailscale addon script:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/add-tailscale-lxc.sh)"
```

5. Enabled IP forwarding for subnet routing:
```bash
pct enter 102
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
sysctl -p
exit
```

6. Configured Tailscale with subnet routes:
```bash
pct enter 102
tailscale up --advertise-routes=10.0.0.0/24 --accept-routes
```

7. Approved subnet routes in Tailscale admin console

## Configuration

### Subnet Routes

The container advertises `10.0.0.0/24` to the Tailscale network. This must be approved in the admin console:
1. Go to https://login.tailscale.com/admin/machines
2. Find the `bonconlab-tmg` machine
3. Approve the subnet route in the "Subnets" section

### Key Expiry

**Recommended**: Disable key expiry to prevent periodic re-authentication.

In Tailscale admin console:
1. Click on the `bonconlab-tmg` machine
2. Machine settings
3. Disable key expiry

### IP Forwarding

IP forwarding is enabled via `/etc/sysctl.conf`:
```
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
```

## Usage

**From any device with Tailscale installed:**

1. Connect to your Tailscale network
2. Access homelab resources via their local IPs:
   - SB Proxmox: https://10.0.0.2:8006
   - TMG Proxmox: https://10.0.0.3:8006
   - DB Proxmox: https://10.0.0.4:8006
   - Home Assistant: http://10.0.0.x:8123

## Maintenance

### Container Management

From TMG shell:

```bash
# Check container status
pct status 102

# Start/stop/restart
pct start 102
pct stop 102
pct reboot 102

# Access container shell
pct enter 102
```

### Check Tailscale Status

Inside the container:

```bash
pct enter 102
tailscale status
```

### Re-authenticate

If authentication expires (only if key expiry wasn't disabled):

```bash
pct enter 102
tailscale up --advertise-routes=10.0.0.0/24 --accept-routes
```

## Troubleshooting

### Can't reach homelab from Tailscale

1. Check container is running: `pct status 102`
2. Verify Tailscale is connected:
   ```bash
   pct enter 102
   tailscale status
   ```
3. Confirm subnet routes are approved in admin console
4. Verify IP forwarding is enabled:
   ```bash
   pct enter 102
   sysctl net.ipv4.ip_forward
   # Should return: net.ipv4.ip_forward = 1
   ```

### Container won't start

```bash
# Check for errors
pct start 102
journalctl -xe

# If TUN device issues, verify container features
pct config 102 | grep features
# Should show: features: nesting=1
```

### Subnet routes not working

1. Verify routes are advertised:
   ```bash
   pct enter 102
   tailscale status
   ```
   Should show `offering 10.0.0.0/24`

2. Check admin console shows routes as "Approved" not "Awaiting Approval"

3. Verify IP forwarding is enabled (see above)

## Notes

- Container uses ~50MB RAM at idle
- Auto-starts with TMG node (`--onboot 1`)
- Unprivileged container for security
- Previous Tailscale installation on Datto (Home Assistant) was removed to avoid conflicts

## Related

- [Network Configuration](../network.md)
- [Services Index](_services-index.md)
- [Maintenance Procedures](../maintenance.md)
