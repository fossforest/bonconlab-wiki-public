# Nginx Proxy Manager

Web-based reverse proxy manager with SSL certificate management. Also serves local HTML tools.

## Overview

| Property | Value |
|----------|-------|
| Node | TMG (tmg) |
| Type | LXC Container |
| IP | 10.0.0.238 (reserved) |
| Port | 81 (management UI), 80 (HTTP), 443 (HTTPS) |
| Container ID | 101 |
| Storage | local-zfs |
| Status | Active |

## Access

- **Management UI**: http://10.0.0.238:81
- **Local Tools**: http://10.0.0.238/tools/

**Default Login** (change on first login):
- Email: `admin@example.com`
- Password: `changeme`

## Installation

Installed via community helper script:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/nginx.sh)"
```

This created a Debian LXC container with Nginx Proxy Manager pre-configured.

## Current Uses

### Local Tool Hosting

Static HTML tools are served from `/var/www/html/tools/`:
- [Button Automation Generator](button-automation-generator.md) - http://10.0.0.238/tools/

**Adding new tools:**
```bash
# From TMG host
pct push 101 /path/to/tool.html /var/www/html/tools/tool-name.html
```

### Future: Reverse Proxy

NPM will be used to set up reverse proxies for services like:
- Plex/Jellyfin (media streaming)
- Immich (photo management)
- Paperless-ngx (document management)
- Any other web services that need external access or custom domains

## Configuration

### Proxy Hosts

Configured through the web UI at http://10.0.0.238:81:
1. Proxy Hosts → Add Proxy Host
2. Enter domain name, forward hostname/IP, and port
3. Optionally configure SSL certificate (Let's Encrypt or custom)

### SSL Certificates

NPM can automatically obtain and renew Let's Encrypt certificates:
1. SSL Certificates → Add SSL Certificate
2. Choose "Let's Encrypt"
3. Enter domain names
4. Agree to terms of service

**Note**: Requires ports 80 and 443 forwarded from your router if using public domains.

## Maintenance

### Updates

Updates are applied through the NPM web UI:
Settings → Check for Updates

### Container Management

From TMG shell:

```bash
# Check container status
pct status 101

# Start/stop/restart
pct start 101
pct stop 101
pct reboot 101

# Access container shell
pct enter 101
```

### Backup

Backup the entire container from Proxmox UI or via command:

```bash
vzdump 101 --storage external-18tb-hdd --mode snapshot
```

## Troubleshooting

### Can't access management UI

1. Check container is running: `pct status 101`
2. Check network: `pct enter 101` then `ip a`
3. Check NPM service: `pct enter 101` then `systemctl status npm`

### Proxy host not working

1. Verify the backend service is accessible from the NPM container
2. Check NPM logs: Settings → Error Logs or Access Logs in UI
3. Test direct connection from NPM container:
   ```bash
   pct enter 101
   curl http://backend-ip:port
   ```

### SSL certificate issues

1. Verify DNS points to your public IP
2. Check ports 80/443 are forwarded to NPM container
3. Review certificate logs in NPM UI

## File Locations

Inside the container:

| Path | Purpose |
|------|---------|
| `/var/www/html/` | Default web root |
| `/var/www/html/tools/` | Local HTML tools |
| `/data/` | NPM configuration and database |
| `/data/logs/` | NPM logs |

## Related

- [Network Configuration](../network.md)
- [Services Index](_services-index.md)
- [Button Automation Generator](button-automation-generator.md)
