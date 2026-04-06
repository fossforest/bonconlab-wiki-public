# Wiki Anonymization Pipeline

Automated pipeline that generates a public, anonymized version of the BonConLab wiki. Runs as part of Mirror Manager on LXC 111.

## Overview

| Property | Value |
|----------|-------|
| Trigger | Push to `bonconlab-wiki` on Forgejo |
| Handler | Mirror Manager (`POST /api/anonymize/wiki`) |
| Output | `bonconlab-wiki-public` on Forgejo → GitHub (public mirror) |
| Rules file | `/opt/forgejo-mirror-manager/anonymize.sed` |
| Working directory | `/opt/forgejo-mirror-manager/anon-work/` |

## Flow

```
Push to bonconlab-wiki (Forgejo)
  │
  ├── [existing] Push mirror → GitHub private (anon-user/bonconlab-wiki)
  ├── [existing] Webhook → Zensical (wiki hot-reload)
  │
  └── [new] Webhook → Mirror Manager /api/anonymize/wiki
              │
              ├── git pull private wiki
              ├── rsync files to public working copy
              ├── sed -f anonymize.sed on all .md and .yaml files
              ├── git commit + push to bonconlab-wiki-public (Forgejo)
              │
              └── Push mirror → GitHub public (bonconlab-wiki-public)
```

## What Gets Anonymized

| Original | Replacement | Reason |
|----------|-------------|--------|
|  /  | (removed) | Personal name |
| ah@gmail.com | user@example.com | Email |
| anon-user | anon-user | GitHub username |
| tail-scale | tail-scale | Tailscale tailnet ID |
| sb / SB | sb / SB | Node hostname |
| tmg / TMG | tmg / TMG | Node hostname |
| db / DB | db / DB | Node hostname |
| dp / DP | dp / DP | Node hostname |
| 10.0.0.x | 10.0.0.x | LAN subnet (last octet preserved) |
| /anon/ (Forgejo paths) | /anon/ | Forgejo username in URLs |
| alex (filesystem) | anonuser | macOS home directory paths |

## Files

| File | Location | Purpose |
|------|----------|---------|
| `anonymize.sed` | Mirror Manager repo root | sed replacement rules |
| `anonymize-wiki.sh` | Mirror Manager repo root | Shell script — clone, sed, commit, push |
| Server route | `server.js` (`POST /api/anonymize/wiki`) | Webhook handler, calls the shell script |

## Working Directory Layout

```
/opt/forgejo-mirror-manager/anon-work/
  private/    ← clone of bonconlab-wiki (pulled on each trigger)
  public/     ← clone of bonconlab-wiki-public (anonymized output)
```

Created automatically on first run. The private clone is read-only (pull only); the public clone is the commit/push target.

## Webhook Configuration

| Setting | Value |
|---------|-------|
| Forgejo repo | bonconlab-wiki |
| Event | Push |
| Payload URL | http://10.0.0.140:3850/api/anonymize/wiki |
| Content type | application/json |

**Note:** This webhook points directly to the Mirror Manager Express app (port 3850), not to the `webhook` package on port 9000. The anonymize route is part of the Mirror Manager application.

## Adding New Anonymization Rules

Edit `anonymize.sed` in the Mirror Manager repo. Rules use standard sed substitution syntax:

```
s/PATTERN/REPLACEMENT/g
```

Push to Forgejo and the Mirror Manager will self-update via its own GitOps webhook. The next wiki push will use the updated rules.

## Troubleshooting

### Check logs

```bash
# journalctl flags:
#   -u mirror-manager    filter to the mirror-manager systemd unit
#   -f                   follow (stream new log lines in real time)
#   --no-pager           don't pipe through less, print directly
journalctl -u mirror-manager -f --no-pager
```

Then trigger a push to the wiki and watch for `[anonymize]` log lines.

### Test the script manually

```bash
# Run the anonymization script directly on LXC 111.
# Source .env first to load FORGEJO_TOKEN into the environment.
# source (or .) reads a file and executes it in the current shell,
# which makes the exported variables available to child processes.
cd /opt/forgejo-mirror-manager
source .env
bash anonymize-wiki.sh
```

### Test the webhook endpoint

```bash
# curl flags:
#   -X POST              send a POST request (matching what Forgejo sends)
#   -H 'Content-Type...' set the request header to JSON
#   -d '{}'              send an empty JSON body (the handler doesn't
#                        inspect the payload — it just triggers the script)
curl -X POST -H 'Content-Type: application/json' -d '{}' \
  http://10.0.0.140:3850/api/anonymize/wiki
```

### First run takes longer

The initial run clones both repos from scratch. Subsequent runs do `git pull` which is near-instant for a repo of markdown files.

### Script permissions

The script must be executable:

```bash
# chmod +x: adds execute permission to the file
chmod +x /opt/forgejo-mirror-manager/anonymize-wiki.sh
```

## Related

- [Mirror Manager](mirror-manager.md)
- [Forgejo](forgejo.md)
- [Services Index](_services-index.md)
