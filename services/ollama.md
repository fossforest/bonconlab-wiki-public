# Ollama

Local LLM inference server running on the Mac Mini M4. Serves as the backend for Open WebUI and Home Assistant voice assistant.

## Overview

| Property | Value |
|----------|-------|
| Node | BonCon Mac Mini M4 |
| Type | macOS LaunchAgent (Homebrew) |
| IP | 10.0.0.148 |
| Tailscale IP | 100.120.249.9 |
| Port | 11434 |
| Status | ✅ Active |

## Model

| Model | Parameters | Quantization | Use Case |
|-------|-----------|--------------|----------|
| gemma4:e4b | ~4.5B effective (8B with embeddings) | Q4_K_M | HA conversation agent, Obsidian assistant |

## Installation

Installed via Homebrew:

```bash
brew install ollama
```

Model pulled with:

```bash
ollama pull gemma4:e4b
```

## Configuration

### LaunchAgent

Managed by Homebrew at `~/Library/LaunchAgents/homebrew.mxcl.ollama.plist`.

Key environment variables:

| Variable | Value | Purpose |
|----------|-------|---------|
| `OLLAMA_HOST` | `0.0.0.0` | Listen on all interfaces (required for LAN/Tailscale access) |
| `OLLAMA_FLASH_ATTENTION` | `1` | Enable flash attention for faster inference |
| `OLLAMA_KV_CACHE_TYPE` | `q8_0` | Quantized KV cache to reduce memory usage |

Logs: `/opt/homebrew/var/log/ollama.log`

### Restart Service

```bash
launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.ollama.plist
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.ollama.plist
```

## Maintenance

### Update Ollama

```bash
brew upgrade ollama
```

Then restart the LaunchAgent.

### Update Model

```bash
ollama pull gemma4:e4b
```

### Check Status

```bash
curl http://localhost:11434/api/tags
```

## Troubleshooting

**Ollama not reachable from other machines**
- Verify `OLLAMA_HOST=0.0.0.0` is in the LaunchAgent plist
- Restart the LaunchAgent after any plist changes
- Test: `curl http://10.0.0.148:11434/api/tags`

**High memory usage**
- gemma4:e4b (~8B with embeddings) should use ~5-6GB RAM at Q4_K_M. If memory pressure is high, check if multiple models are loaded: `ollama ps`
- Unload unused models: `ollama stop <model>`

## Related

- [Open WebUI](open-webui.md) — frontend that connects to this Ollama instance
