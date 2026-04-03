# LXC Utility Template

Reusable Proxmox LXC template pre-loaded with Node.js, Python, Tailscale, and webhook tooling for deploying lightweight self-hosted utilities.

## Overview

| Property | Value |
|----------|-------|
| Base OS | Debian 13 (Trixie) |
| Template VMID | TBD — assign during creation |
| Node | Any (create on TMG for lightweight services, DB for storage-heavy) |
| Storage | local-zfs |
| Default Specs | 1 core, 512MB RAM, 4GB disk |
| Pre-installed | Node.js 20, npm, Python 3, git, curl, Tailscale, webhook, ts-init |

## Purpose

Most BonConLab utilities follow the same pattern: a small web app (Node.js/Express or Python) with an HTML frontend, a JSON data file, and Tailscale for remote access. Rather than repeating the same setup for each new service, this template provides a pre-configured base that can be cloned and customized in minutes.

**What's included:**

- Node.js 20 + npm (Debian 13 native — no NodeSource)
- Python 3 (Debian 13 native)
- Tailscale (installed, not yet authenticated — each clone gets its own identity)
- `webhook` package for GitOps deploy receivers
- `git` and `curl`
- `ts-init` helper script for one-command Tailscale setup with SSH and ACL tags
- Systemd service template at `/etc/systemd/system/app.service.template`

**What's NOT included (set up per-clone):**

- Tailscale authentication (each clone runs `ts-init`)
- App code (clone your repo or copy files into `/opt/<servicename>/`)
- Systemd service unit (copy and customize the template)
- Unifi IP reservation
- npm dependencies (run `npm install` per-project if needed)

## Prerequisites

### Tailscale Auth Keys

The `ts-init` script uses reusable auth keys with ACL tags baked in. These must be created before building the template.

**Generate keys at:** https://login.tailscale.com/admin/settings/keys

For each tag you want to support, generate a key with these settings:

- **Reusable**: Yes (same key works for every clone)
- **Ephemeral**: No (containers are persistent, not throwaway)
- **Expiration**: 90 days (maximum)
- **Tags**: Assign the appropriate ACL tag (e.g., `tag:server`, `tag:media`)

Also generate a **default** key with no tag (or your general-purpose tag) for containers that don't need a specific role.

**Key expiry note:** When a key expires after 90 days, generate a new one, update it in the `bonconlab-scripts` repo, and push. Existing containers are unaffected — only new `ts-init` runs need the fresh key.

### bonconlab-scripts Repository

The `ts-init` script is maintained in the `alex/bonconlab-scripts` repo on Forgejo. This is where auth keys are updated and where all shared utility scripts live. See [bonconlab-scripts on Forgejo](http://10.0.0.181:3000/anon/bonconlab-scripts) for the repo and README.

## Creating the Template

Only needs to be done once. Run these steps from any Proxmox node.

### Step 1: Create the base container

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"
# Downloads and runs the community helper script for creating a Debian LXC
# Walks through an interactive setup wizard
```

During the prompts, choose:

- **Debian 13 (Trixie)**
- **Enable TUN device** — required for Tailscale
- **Enable nesting** — required for Tailscale
- **VMID**: Pick a number you'll remember as the template (e.g., 900)
- **Specs**: 1 core, 512MB RAM, 4GB disk (overridable per-clone)

### Step 2: Install shared tooling

```bash
pct enter <VMID>
# pct enter — Opens an interactive shell inside the specified container
```

Inside the container:

```bash
# Update package lists and install base tools
apt update && apt install -y curl git nodejs npm webhook
# apt update — Refreshes the list of available packages from repos
# apt install -y — Installs packages, -y auto-confirms prompts
# curl — HTTP client, needed for install scripts and API calls
# git — Version control, needed for GitOps deploys and cloning repos
# nodejs — JavaScript runtime (v20 LTS, ships natively in Debian 13)
# npm — Node.js package manager
# webhook — Lightweight webhook receiver (adnanh/webhook), used for GitOps deploy triggers

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
# curl -fsSL — Fetch URL silently (-s), fail on HTTP errors (-f), follow redirects (-L)
# | sh — Pipes the downloaded script into the shell for execution
# Adds the Tailscale apt repo and installs tailscale + tailscaled packages
```

### Step 3: Install `ts-init` from the bonconlab-scripts repo

```bash
curl -fsSL http://10.0.0.181:3000/anon/bonconlab-scripts/raw/branch/main/ts-init \
  -o /usr/local/bin/ts-init && chmod +x /usr/local/bin/ts-init
# curl -fsSL — Fetch from Forgejo raw file endpoint
# -o — Write output to this file path instead of stdout
# && chmod +x — Make executable (only runs if download succeeded)
# /usr/local/bin/ — On the system PATH, callable from anywhere as just `ts-init`
```

Verify it installed:

```bash
ts-init --help
# Should list available tags (default, server, media, etc.)
```

### Step 4: Create the systemd service template

```bash
cat > /etc/systemd/system/app.service.template << 'EOF'
# ── Systemd service template for BonConLab utilities ──
# To use: copy and rename this file for your service, then fill in the CHANGEME values.
#   cp /etc/systemd/system/app.service.template /etc/systemd/system/myapp.service
#   nano /etc/systemd/system/myapp.service
#   systemctl daemon-reload && systemctl enable --now myapp

[Unit]
Description=CHANGEME — app description
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/CHANGEME
ExecStart=CHANGEME
# Node.js example:  /usr/bin/node server.js
# Python example:   /usr/bin/python3 server.py
Restart=on-failure
RestartSec=5
Environment=PORT=CHANGEME

[Install]
WantedBy=multi-user.target
EOF
# cat > [file] << 'EOF' — Writes everything between the two EOF markers into the file
# Single quotes around 'EOF' prevent variable expansion in the heredoc
# .template extension — systemd ignores this file; it's just a reference copy
```

### Step 5: Clean up before templating

```bash
# Remove machine-specific identity so each clone generates its own
rm -f /etc/machine-id
# rm -f — Remove file, -f suppresses errors if file doesn't exist
# /etc/machine-id — Unique machine identifier; a new one is generated on first boot

# Clear hostname (pct clone --hostname sets this per-clone)
truncate -s 0 /etc/hostname
# truncate -s 0 — Sets file size to 0 bytes (empties the file)

# Clear Tailscale state so each clone authenticates independently
systemctl stop tailscaled
# systemctl stop — Stops the Tailscale daemon before we wipe its data

rm -rf /var/lib/tailscale/
# rm -rf — Recursively remove directory and all contents
# /var/lib/tailscale/ — Contains keys, node identity, and config
# Each clone needs its own identity via ts-init

# Shrink the template by clearing cached packages
apt clean
# apt clean — Removes downloaded .deb files from the local cache

exit
```

### Step 6: Convert to template

Back on the Proxmox host:

```bash
pct stop <VMID>
# pct stop — Gracefully shuts down the container

pct template <VMID>
# pct template — Converts the container into a read-only template
# After this it cannot be started — only cloned
# It appears with a template icon in the Proxmox web UI
```

## Deploying a New Service

### Clone and start

From the Proxmox host:

```bash
pct clone <TEMPLATE_VMID> <NEW_VMID> --hostname <n> --full
# pct clone — Creates a new container from the template
# <TEMPLATE_VMID> — The template container ID (e.g., 900)
# <NEW_VMID> — ID for the new container (follow node conventions: 1xx for TMG, 2xx for SB, etc.)
# --hostname — Sets the container hostname (e.g., "dashboard", "my-tool")
# --full — Full independent copy, not a linked clone

pct start <NEW_VMID>
# pct start — Boots the new container

pct enter <NEW_VMID>
# pct enter — Opens a shell inside the container
```

### Set up Tailscale (one command)

```bash
ts-init --tag server 8080
# ts-init — Custom helper script (pre-installed in the template)
# --tag server — Uses the auth key associated with the "server" ACL tag
# 8080 — Optional: port to expose via Tailscale Serve HTTPS
# Omit --tag to use the default key
# Omit the port to skip Tailscale Serve
```

### Deploy app code

For a git-hosted project:

```bash
git clone <repo-url> /opt/<servicename>
# Clone your app repo into /opt/

cd /opt/<servicename>
npm install --production
# Only needed for Node.js projects — installs dependencies
# --production — Skips devDependencies to save space
```

For a simple file copy (e.g., from the Proxmox host):

```bash
# From the Proxmox host
pct push <VMID> /path/to/server.py /opt/myapp/server.py
pct push <VMID> /path/to/index.html /opt/myapp/index.html
pct push <VMID> /path/to/config.json /opt/myapp/config.json
# pct push — Copies a file from the host into the container
# <VMID> — Target container ID
# Source path on host, then destination path inside container
```

### Create the systemd service

Inside the container:

```bash
# Copy the template and name it for your service
cp /etc/systemd/system/app.service.template /etc/systemd/system/myapp.service
# cp — Copy file; replace "myapp" with your actual service name

# Edit and fill in the CHANGEME values
nano /etc/systemd/system/myapp.service
# nano — Terminal text editor; Ctrl+O to save, Ctrl+X to exit

# Enable and start
systemctl daemon-reload
# daemon-reload — Tells systemd to re-scan unit files after adding/changing one

systemctl enable --now myapp
# enable — Starts the service automatically on boot
# --now — Also starts it immediately (combines enable + start)
```

### Reserve the IP in Unifi

1. Find the container's MAC: `ip link show eth0` inside the container
2. In Unifi: Settings → Networks → DHCP → Static IP assignment
3. Naming convention: `<node>-<servicename>` (e.g., `tmg-dashboard`)

### Optional: GitOps webhook

If the service has a Forgejo repo, use Mirror Manager's bootstrap endpoint to set up auto-deploy:

```bash
curl -s http://10.0.0.140:3850/setup-webhook.sh?repo=<reponame>&hook=<hookname> | bash
# Downloads and runs a setup script from Mirror Manager that:
#   - Creates /etc/webhook.conf with a deploy hook
#   - Creates a pull-and-deploy.sh script
#   - Enables the webhook systemd service
#   - webhook package is already installed from the template
```

Then add the webhook URL in Forgejo (repo → Settings → Webhooks).

## Using ts-init on Non-Template Containers

`ts-init` is not limited to containers cloned from this template. It can be installed on any container on the LAN — community script installs, existing containers, anything with `curl` and Tailscale.

**Install Tailscale (if not already present):**

```bash
curl -fsSL https://tailscale.com/install.sh | sh
# Installs Tailscale from the official repo
```

**Install ts-init:**

```bash
curl -fsSL http://10.0.0.181:3000/anon/bonconlab-scripts/raw/branch/main/ts-init \
  -o /usr/local/bin/ts-init && chmod +x /usr/local/bin/ts-init
# Fetches the latest version from Forgejo and places it on the PATH
```

**Run it:**

```bash
ts-init --tag server 8080
```

The `curl` always fetches the current version from Forgejo, so if auth keys have been updated in the repo, you get the fresh ones automatically. Containers that already ran `ts-init` previously are unaffected — they're already authenticated.

## Auth Key Renewal

Auth keys expire every 90 days (Tailscale maximum). Renewal process:

1. Generate new reusable keys at https://login.tailscale.com/admin/settings/keys (one per tag)
2. Edit the `AUTHKEYS` block in `ts-init` in the `bonconlab-scripts` repo
3. `git commit -m "Rotate Tailscale auth keys" && git push`
4. Done — future installs and re-installs get the new keys

**Containers that are already running are not affected.** They authenticated when `ts-init` first ran and maintain their own Tailscale identity in `/var/lib/tailscale/`. Key rotation only matters for new deployments.

**To update ts-init on the template itself**, clone the template to a temporary container, re-run the `curl` install from Step 3, clean up, and re-template (see [Maintenance > Updating the Template](#updating-the-template)).

## Quick Reference

### New service checklist

1. `pct clone <TEMPLATE> <VMID> --hostname <n> --full`
2. `pct start <VMID> && pct enter <VMID>`
3. `ts-init --tag <tag> [port]`
4. Deploy app files to `/opt/<servicename>/`
5. Copy and customize systemd service from `app.service.template`
6. `systemctl daemon-reload && systemctl enable --now <servicename>`
7. Reserve IP in Unifi as `<node>-<servicename>`
8. Update wiki: add service doc, update services index and network table
9. Optional: set up GitOps webhook via Mirror Manager

### ts-init usage

```
ts-init [--tag TAG] [serve-port]

  --tag TAG     Use auth key for the specified ACL tag (default: "default")
  serve-port    Local port to expose via Tailscale Serve HTTPS (optional)
  --help        Show available tags
```

### Specs adjustment (before starting)

If a service needs more resources than the 1 core / 512MB / 4GB defaults:

```bash
pct set <VMID> --cores 2 --memory 1024 --rootfs local-zfs:8
# pct set — Modifies container configuration
# --cores — Number of CPU cores
# --memory — RAM in MB
# --rootfs — Root filesystem storage and size in GB
```

### What's where in the template

| Path | Purpose |
|------|---------|
| `/usr/local/bin/ts-init` | One-command Tailscale setup with ACL tags |
| `/etc/systemd/system/app.service.template` | Systemd unit template to copy per-service |
| `/usr/bin/node` | Node.js 20 (Debian 13 native) |
| `/usr/bin/python3` | Python 3 (Debian 13 native) |
| `/usr/bin/webhook` | GitOps webhook receiver |

### Related repos

| Repo | Purpose |
|------|---------|
| `alex/bonconlab-scripts` | Shared utility scripts (`ts-init`, etc.) — auth keys maintained here |
| Per-service repos | App code for each utility (e.g., `alex/dashboard`, `alex/cv-updater`) |

## Maintenance

### Updating the template

Templates are immutable. To update the base tooling:

1. Clone the template to a temporary container
2. Make changes (e.g., `apt upgrade`, re-curl `ts-init`, install new packages)
3. Clean up (same as Step 5 above)
4. Convert the new container to a template
5. Optionally delete the old template

Existing clones are not affected — they're independent copies.

### Updating ts-init across existing containers

If `ts-init` gains new features (not just key rotation), re-run the install on any container that needs the update:

```bash
curl -fsSL http://10.0.0.181:3000/anon/bonconlab-scripts/raw/branch/main/ts-init \
  -o /usr/local/bin/ts-init && chmod +x /usr/local/bin/ts-init
```

This is only needed if the script logic changes. For auth key rotation, only new runs of `ts-init` are affected — existing containers keep their authentication.

### Verifying installed versions

Inside any cloned container:

```bash
node -v            # Node.js version
npm -v             # npm version
python3 --version  # Python version
tailscale version  # Tailscale version
webhook -version   # Webhook version
ts-init --help     # ts-init available tags
```

## Related

- [bonconlab-scripts repo](http://10.0.0.181:3000/anon/bonconlab-scripts) (ts-init source and auth keys)
- [Tailscale](tailscale.md)
- [Forgejo](forgejo.md) (source repos)
- [Mirror Manager](mirror-manager.md) (GitOps bootstrap)
- [Services Index](_services-index.md)
- [Network Configuration](../network.md)
