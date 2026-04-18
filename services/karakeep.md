# Karakeep

Self-hosted bookmark, note, and article archival app (formerly Hoarder). Auto-tags and summarizes saved content via AI, with full-text search across everything.

## Overview

| Property | Value |
|----------|-------|
| Node | SB (sb) |
| Type | LXC Container |
| Container ID | 205 |
| IP | 10.0.0.134 |
| Port | 3000 |
| Tailscale IP | 100.98.142.124 |
| Tailscale URL | https://karakeep.tail-scale.ts.net |
| Storage | sb-1tb-ssd |
| Status | ✅ Active |

## Access

| Method | URL |
|--------|-----|
| Local | http://10.0.0.134:3000 |
| Tailscale (serve) | https://karakeep.tail-scale.ts.net |

## Architecture

Karakeep runs as four native systemd services inside the LXC, all installed from source at `/opt/karakeep`:

| Service | Port | Purpose |
|---------|------|---------|
| `karakeep-web` | 3000 | Next.js frontend (the only user-facing port) |
| `karakeep-workers` | 34345 (local) | Python workers for crawling, tagging, summarization |
| `karakeep-browser` | 9222 (local) | Headless Chromium for page rendering and screenshotting |
| `meilisearch` | 7700 (local) | Full-text search index |

Only port 3000 is exposed externally; the workers, browser, and meilisearch bind to `127.0.0.1`.

## Installation

- VMID: 205
- Hostname: karakeep
- Template: Debian 13 (trixie)
- Resources: 2 cores, 4GB RAM, 20GB disk
- Storage: sb-1tb-ssd
- Network: 10.0.0.134

Installed natively from source at `/opt/karakeep`. Tailscale added via `ts-init`; `tailscale serve` proxies `https://karakeep.tail-scale.ts.net` → `http://127.0.0.1:3000`.

## Configuration

- **App directory**: `/opt/karakeep`
- **Environment file**: `/etc/karakeep/karakeep.env` (community-script layout — older/upstream native installs use `/opt/karakeep/.env`). Confirm with `systemctl cat karakeep-web | grep EnvironmentFile`.

## AI / Ollama Integration

Karakeep uses [Ollama](ollama.md) on the Mac Mini M4 (10.0.0.148) as its local inference backend for auto-tagging and summarization. No OpenAI key is needed — presence of `OLLAMA_BASE_URL` switches Karakeep into Ollama mode.

### Relevant env vars (in `/etc/karakeep/karakeep.env`)

```bash
# Ollama connection
OLLAMA_BASE_URL=http://10.0.0.148:11434
OLLAMA_KEEP_ALIVE=30m              # keep gemma4:e4b resident between bookmarks

# Model selection — gemma4:e4b is multimodal (handles both text and images)
INFERENCE_TEXT_MODEL=gemma4:e4b
INFERENCE_IMAGE_MODEL=gemma4:e4b

# Inference limits
INFERENCE_CONTEXT_LENGTH=8192      # how much of the scraped article the model sees
INFERENCE_MAX_OUTPUT_TOKENS=2048   # caps summary length
INFERENCE_JOB_TIMEOUT_SEC=180      # default 30s is too short for local inference
INFERENCE_FETCH_TIMEOUT_SEC=600    # timeout for HTTP calls to Ollama
INFERENCE_ENABLE_AUTO_TAGGING=true
INFERENCE_ENABLE_AUTO_SUMMARIZATION=true

# Crawler — default 60s timeout trips on pages with slow archive steps,
# which triggers duplicate inference work on each retry. 180s gives headroom.
CRAWLER_JOB_TIMEOUT_SEC=180
```

### Expected performance

On the Mac Mini M4 with `gemma4:e4b` (8B params, Q4_K_M, ~5 GB resident):

- Tag generation: ~5–6s per bookmark (~1,680 tokens context)
- Summary generation: ~25–35s per bookmark (~2,100 tokens)
- First bookmark after idle is slow while the model loads; subsequent bookmarks are fast while `OLLAMA_KEEP_ALIVE` holds.

Tagging/summarization runs in the worker queue, so it doesn't block saving bookmarks in real time — new additions appear immediately and get tags/summary attached a minute or two later.

### Smoke test

```bash
# From inside LXC 205, confirm Ollama is reachable
curl -s http://10.0.0.148:11434/api/tags | head

# Watch inference jobs run
journalctl -u karakeep-workers -f
```

Add/regenerate a bookmark and look for `[inference][N] Inferring tag for ...` and `[inference][N] Generated summary for ...` lines.

## Maintenance

### Container Management

From SB host:

```bash
pct status 205
pct start 205
pct stop 205
pct reboot 205
pct enter 205
```

### Service Management

Inside the container:

```bash
systemctl status karakeep-web karakeep-workers karakeep-browser meilisearch
systemctl restart karakeep-web
journalctl -u karakeep-web -f
```

## Troubleshooting

### Web UI unreachable

- Check the web service: `systemctl status karakeep-web`
- Verify port 3000 is listening: `ss -tlnp | grep 3000`

### Bookmarks never finish processing (stuck "pending")

- Check workers and browser: `systemctl status karakeep-workers karakeep-browser`
- Chromium must be running on `127.0.0.1:9222` for page crawling to succeed

### Search returns no results

- Verify meilisearch is running: `systemctl status meilisearch`
- Confirm it's bound to `127.0.0.1:7700`: `ss -tlnp | grep 7700`

### Repeated `[Crawler][N] Crawling job failed: Error: Timeout` lines, each bookmark gets tagged multiple times

Crawler job is hitting the default 60-second timeout on the page-archive step, and every retry re-queues the inference jobs. Bump `CRAWLER_JOB_TIMEOUT_SEC=180` in `/etc/karakeep/karakeep.env` and restart `karakeep-workers`.

### AI tags/summaries never appear

- Confirm Ollama is reachable from inside the LXC: `curl -s http://10.0.0.148:11434/api/tags`
- Verify the model tag matches exactly what `ollama list` shows on the Mac Mini — Ollama returns 404 on a typo'd tag and Karakeep marks the job failed
- Check for inference errors: `journalctl -u karakeep-workers -e | grep -i inference`

## Related

- [Ollama](ollama.md) — local inference backend (gemma4:e4b) used for tagging and summarization
- [Services Index](_services-index.md)
