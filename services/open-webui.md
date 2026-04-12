# Open WebUI

Web-based chat interface for interacting with local LLMs. Frontend for the Ollama backend running on the Mac Mini.

## Overview

| Property | Value |
|----------|-------|
| Node | SB (LXC 204) |
| Type | Native (systemd) in LXC |
| IP | 10.0.0.126 |
| Tailscale IP | 100.76.254.39 |
| Tailscale URL | https://openwebui.tail-scale.ts.net |
| Port | 8080 |
| Storage | sb-1tb-ssd |
| Status | ✅ Active |

## Architecture

```
Open WebUI (SB LXC 204)  ──HTTP──▶  Ollama (Mac Mini 10.0.0.148:11434)
       ▲                                        │
       │                                   gemma4:e4b
  Browser / Obsidian
```

## Installation

### 1. Create LXC on SB

- VMID: 204
- Hostname: openwebui
- Template: Debian 13 (trixie)
- Resources: 4 cores, 8GB RAM, 50GB disk
- Storage: sb-1tb-ssd
- Network: 10.0.0.126

### 2. Install Open WebUI

Installed natively (not Docker). Runs as a systemd service (`open-webui`).

### 3. Add Tailscale

Added via `ts-init`. Tailscale serve proxies `https://openwebui.tail-scale.ts.net` → `http://127.0.0.1:8080`.

## Configuration

### Ollama Connection

Points to the Mac Mini's LAN IP at `http://10.0.0.148:11434`.

### Home Assistant

HA does **not** route through Open WebUI. See [Ollama](ollama.md) for the direct HA → Ollama conversation agent setup.

## Maintenance

### Update

Check Open WebUI docs for native update procedure. Data is stored locally in the LXC.

### Service Management

```bash
systemctl status open-webui
systemctl restart open-webui
journalctl -u open-webui -f
```

## Troubleshooting

**Open WebUI can't see models**
- Verify Ollama is reachable: `curl http://10.0.0.148:11434/api/tags`
- Check Ollama connection settings in the Open WebUI admin panel

**Service won't start**
- Check logs: `journalctl -u open-webui -e`
- Verify port 8080 isn't in use: `ss -tlnp | grep 8080`

## Related

- [Ollama](ollama.md) — backend LLM inference server
