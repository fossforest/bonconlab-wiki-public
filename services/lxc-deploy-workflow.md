# LXC Deploy Workflow

One-command provisioning for BonConLab LXC containers using scripts hosted on Forgejo. No templates, no manual steps — `deploy-container` handles everything from container creation through Tailscale setup and systemd service creation.

## Overview

| Property | Value |
|----------|-------|
| Scripts repo | [alex/bonconlab-scripts](http://10.0.0.181:3000/anon/bonconlab-scripts) on Forgejo |
| Not mirrored to GitHub | Repo contains Tailscale OAuth client secret |
| Base OS | Debian 13 (Trixie) |
| Default Specs | 1 core, 512MB RAM, 4GB disk |
| Packages installed | Node.js 20, npm, Python 3, git, curl, Tailscale, webhook |

## How It Works

A single script (`deploy-container`) runs on the Proxmox host and does everything the community helper scripts do — but tailored for BonConLab utilities. It creates a Debian 13 container, installs all packages, sets up Tailscale with SSH and ACL tags, clones your app repo from Forgejo, auto-detects the runtime, and creates a systemd service.

Two helper scripts do the inside-the-container work. They're not pre-installed anywhere — `deploy-container` curls them fresh from Forgejo each time, so they always carry the current OAuth secret and latest logic.

| Script | Runs on | Purpose |
|--------|---------|---------|
| `deploy-container` | Proxmox host | Orchestrates the full container lifecycle |
| `ts-init` | Inside container | Tailscale + SSH + tag:server + optional extra tags |
| `svc-init` | Inside container | Systemd service creation (auto-detects Node.js or Python) |
| `quickref` | Proxmox host | Interactive command reference — self-updates on each run |
| `wiki-info` | Inside container | Gathers container info for wiki documentation (curl and pipe, no install) |

## Setup

### 1. Create the bonconlab-scripts repo

Create `alex/bonconlab-scripts` on Forgejo with three scripts: `deploy-container`, `ts-init`, `svc-init`. Do NOT set up a GitHub mirror — the repo contains a Tailscale OAuth client secret.

### 2. Create a Tailscale OAuth client

`ts-init` uses a permanent OAuth client secret for authentication. Unlike auth keys, this does not expire.

1. Go to https://login.tailscale.com/admin/settings/oauth
2. Create a new OAuth client with:
   - **Scopes**: `auth_keys` (read/write), `devices:core` (read/write)
   - **Tags**: `tag:server`
3. Copy the **Client Secret** (starts with `tskey-client-`)
4. Paste it into the `OAUTH_SECRET` variable in `ts-init` in the repo
5. Push to Forgejo

All containers get `tag:server` automatically. For containers that need additional tags (e.g., `tag:media`), pass `--tags media` to `deploy-container` or `ts-init`.

### 3. Install deploy-container on Proxmox nodes

Run this on each Proxmox node you want to deploy from:

```bash
curl -fsSL http://10.0.0.181:3000/anon/bonconlab-scripts/raw/branch/main/deploy-container \
  -o /usr/bin/deploy-container && chmod +x /usr/bin/deploy-container
# curl -fsSL — Fetch from Forgejo raw file endpoint silently, fail on errors, follow redirects
# -o — Write output to this file path instead of stdout
# && chmod +x — Make executable (only runs if download succeeded)
# /usr/bin/ — On the system PATH, callable as just `deploy-container`
```

To update later (e.g., after changing defaults), re-run the same command.

## Deploying a New Service

### One command

```bash
deploy-container --vmid 113 --hostname dashboard --port 8080 --repo dashboard
# --vmid 113 — Container ID (follow conventions: 1xx TMG, 2xx SB, 3xx DB, 4xx Datto)
# --hostname dashboard — Container hostname (also used for /opt/dashboard/ and the systemd service name)
# --port 8080 — Service port: used for both Tailscale Serve HTTPS and the systemd Environment=PORT
# --repo dashboard — Forgejo repo name: clones alex/dashboard.git into /opt/dashboard/
# tag:server is applied automatically via the OAuth client — no --tags needed for the default case
```

With additional tags:

```bash
deploy-container --vmid 305 --hostname myapp --tags media --port 3000 --repo myapp
# --tags media — Applies tag:server (always) + tag:media (additional)
```

Interactive mode (prompts for each value):

```bash
deploy-container
```

### What it does

1. **Downloads Debian 13 template** if not already cached on the node
2. **Creates the container** via `pct create` — unprivileged, nesting enabled, TUN device passthrough, auto-start on boot
3. **Installs base packages** — curl, git, nodejs, npm, webhook, tailscale
4. **Sets up Tailscale** — curls `ts-init` from Forgejo, authenticates with the permanent OAuth client secret, applies `tag:server` and any additional tags, enables SSH, optionally starts HTTPS serve
5. **Clones the app repo** from Forgejo into `/opt/<hostname>/`, runs `npm install` if a `package.json` is found
6. **Creates the systemd service** — curls `svc-init` from Forgejo, auto-detects Node.js (`server.js`) or Python (`server.py`) from repo contents, prompts for confirmation, starts the service. If neither is found, falls back to serving the directory as a static site via `tailscale serve --bg --https=443`

### After deploy-container finishes

The script prints a summary with the container's local IP, Tailscale IP, SSH command, and HTTPS URL. Two manual steps remain:

**Reserve the IP in Unifi:**

1. The summary shows the container's MAC — or find it with `pct exec <VMID> -- ip link show eth0`
2. Unifi: Settings → Networks → DHCP → Static IP assignment
3. Naming convention: `<node>-<servicename>` (e.g., `tmg-dashboard`)

**Update the wiki:**

1. Create `services/<servicename>.md` using the service documentation template in `_services-index.md`
2. Add a row to the Active Services table in `_services-index.md`
3. Add the IP to `network.md`
4. Add a changelog entry

### Optional: GitOps webhook

If the service has a Forgejo repo (which it does if you used `--repo`), set up auto-deploy on push via Mirror Manager:

```bash
curl -s http://10.0.0.140:3850/setup-webhook.sh?repo=<reponame>&hook=<hookname> | bash
# Downloads and runs a setup script from Mirror Manager that configures
# a webhook receiver for auto-pull-and-restart on git push
# The webhook package is already installed by deploy-container
```

Then add the webhook URL in Forgejo (repo → Settings → Webhooks).

### Overriding defaults

```bash
# More resources for a heavier service
deploy-container --vmid 203 --hostname immich --cores 4 --memory 2048 --disk 16

# Additional tags beyond tag:server
deploy-container --vmid 305 --hostname myapp --tags media,arr --port 3000 --repo myapp

# Different storage pool
deploy-container --vmid 305 --hostname myapp --storage db-2tb-nvme

# Skip optional steps
deploy-container --vmid 113 --hostname myapp --skip-tailscale --skip-repo --skip-service
```

Default specs (1 core, 512MB RAM, 4GB disk on local-zfs) can be changed by editing the `DEFAULT_*` variables at the top of the `deploy-container` script.

## Using Scripts on Non-Template Containers

`ts-init` and `svc-init` work on any container — community script installs, existing services, anything with curl and Tailscale. This is useful for bringing older containers into the BonConLab tooling.

**Install Tailscale (if not already present):**

```bash
curl -fsSL https://tailscale.com/install.sh | sh
# Adds the Tailscale apt repo and installs the package
```

**Install and run ts-init:**

```bash
curl -fsSL http://10.0.0.181:3000/anon/bonconlab-scripts/raw/branch/main/ts-init \
  -o /usr/bin/ts-init && chmod +x /usr/bin/ts-init
# Fetches the latest version from Forgejo (with current OAuth secret)

ts-init 8080
# Authenticates with the OAuth client secret, applies tag:server, enables SSH, serves port 8080
# Add extra tags: ts-init --tags media 8080
```

**Install and run svc-init:**

```bash
curl -fsSL http://10.0.0.181:3000/anon/bonconlab-scripts/raw/branch/main/svc-init \
  -o /usr/bin/svc-init && chmod +x /usr/bin/svc-init

svc-init --name myservice --exec "/usr/bin/node server.js" --port 3000
# Or just: svc-init (interactive prompts)
```

**Gather container info for wiki updates:**

```bash
curl -fsSL http://10.0.0.181:3000/anon/bonconlab-scripts/raw/branch/main/wiki-info | bash
# No install needed — outputs hostname, IPs, Tailscale status, specs, ports, etc.
# Copy the output and paste to Claude for wiki documentation
```

## OAuth Client Maintenance

The OAuth client secret embedded in `ts-init` does **not expire**. Unlike auth keys (90-day maximum), the secret is permanent unless the OAuth client is revoked.

**When you'd need to update the secret:**

- If you revoke the OAuth client in the Tailscale admin console and create a new one
- If you believe the secret has been compromised

**Update process:**

1. Create a new OAuth client at https://login.tailscale.com/admin/settings/oauth
2. Edit the `OAUTH_SECRET` value in `ts-init` in the `bonconlab-scripts` repo
3. `git commit -m "Update OAuth client secret" && git push`

`deploy-container` curls `ts-init` fresh from Forgejo every time, so new deploys automatically get the updated secret. Existing running containers are unaffected — they authenticated when `ts-init` first ran and maintain their own identity.

## Quick Reference

### New service checklist

1. `deploy-container --vmid <V> --hostname <n> --port <port> --repo <repo>`
2. Reserve IP in Unifi as `<node>-<servicename>`
3. Update wiki: service doc, services index, network table, changelog
4. Optional: set up GitOps webhook via Mirror Manager

### deploy-container flags

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--vmid` | Yes | — | Container ID |
| `--hostname` | Yes | — | Container hostname |
| `--tags` | No | — | Additional ACL tags beyond tag:server (comma-separated) |
| `--port` | No | prompted | Service port + Tailscale Serve |
| `--repo` | No | prompted | Forgejo repo name to clone |
| `--storage` | No | `local-zfs` | Proxmox storage pool |
| `--cores` | No | `1` | CPU cores |
| `--memory` | No | `512` | RAM in MB |
| `--disk` | No | `4` | Root disk in GB |
| `--skip-tailscale` | No | — | Skip Tailscale setup |
| `--skip-service` | No | — | Skip systemd service |
| `--skip-repo` | No | — | Skip repo clone |

### Packages installed by deploy-container

| Package | Version | Source |
|---------|---------|--------|
| Node.js | 20 LTS | Debian 13 repos (native) |
| Python | 3.x | Debian 13 repos (native) |
| npm | ships with Node.js | Debian 13 repos |
| git | latest | Debian 13 repos |
| curl | latest | Debian 13 repos |
| Tailscale | latest | Tailscale apt repo |
| webhook | latest | Debian 13 repos |

## Maintenance

### Updating deploy-container on Proxmox hosts

Re-run the install command:

```bash
curl -fsSL http://10.0.0.181:3000/anon/bonconlab-scripts/raw/branch/main/deploy-container \
  -o /usr/bin/deploy-container && chmod +x /usr/bin/deploy-container
```

### Updating ts-init or svc-init on existing containers

Only needed if the script logic changes (the OAuth secret doesn't expire, so no routine rotation):

```bash
curl -fsSL http://10.0.0.181:3000/anon/bonconlab-scripts/raw/branch/main/ts-init \
  -o /usr/bin/ts-init && chmod +x /usr/bin/ts-init
```

## Future: Infrastructure as Code

A `bonconlab-infra` repo is planned to hold reproducible setup scripts for every container in the cluster — one `setup.sh` per service that can recreate a container from scratch. This would extend the `deploy-container` pattern to cover services that aren't simple Node.js/Python utilities (arr stack, Plex, Home Assistant, etc.) and serve as both documentation and disaster recovery.

## Related

- [bonconlab-scripts repo](http://10.0.0.181:3000/anon/bonconlab-scripts)
- [Tailscale](tailscale.md)
- [Forgejo](forgejo.md)
- [Mirror Manager](mirror-manager.md) (GitOps bootstrap)
- [Services Index](_services-index.md)
- [Network Configuration](../network.md)
