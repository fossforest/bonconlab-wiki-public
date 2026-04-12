# Open WebUI

Web-based chat interface for interacting with local LLMs. Frontend for the Ollama backend running on the Mac Mini.

## Overview

| Property | Value |
|----------|-------|
| Node | SB (LXC 204) |
| Type | Docker in LXC |
| IP | TBD |
| Port | 3000 |
| Storage | sb-1tb-ssd |
| Status | 🔧 Planned |

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
- Template: Debian 12
- Resources: 2 cores, 2GB RAM, 8GB disk
- Storage: sb-1tb-ssd
- Network: static IP on 10.0.0.x

### 2. Install Docker

```bash
apt update && apt install -y docker.io
systemctl enable --now docker
```

### 3. Run Open WebUI

```bash
docker run -d \
  --name open-webui \
  --restart always \
  -p 3000:8080 \
  -e OLLAMA_BASE_URL=http://10.0.0.148:11434 \
  -v open-webui:/app/backend/data \
  ghcr.io/open-webui/open-webui:main
```

### 4. Add Tailscale

Use `ts-init` to add Tailscale to the container.

## Configuration

### Ollama Connection

Set via `OLLAMA_BASE_URL` environment variable in the Docker run command. Points to the Mac Mini's LAN IP.

### Home Assistant Integration

Two-tier integration:

- **Conversation agent** (local, via Open WebUI): gemma4:e4b serves as the HA conversation agent via the OpenAI-compatible API at `http://<lxc-ip>:3000/api/`. Handles voice commands and quick Q&A with low latency.
- **Complex tasks** (cloud, via Claude MCP): Claude Code with the HA MCP server handles writing automations, organizing entities, and other tasks requiring stronger reasoning.

## Maintenance

### Update

```bash
docker pull ghcr.io/open-webui/open-webui:main
docker stop open-webui && docker rm open-webui
# Re-run the docker run command above
```

Data persists in the `open-webui` Docker volume.

## Troubleshooting

**Open WebUI can't see models**
- Verify Ollama is reachable: `curl http://10.0.0.148:11434/api/tags`
- Check `OLLAMA_BASE_URL` is set correctly in the container

**Container won't start**
- Check Docker logs: `docker logs open-webui`
- Verify port 3000 isn't in use: `ss -tlnp | grep 3000`

## Related

- [Ollama](ollama.md) — backend LLM inference server
