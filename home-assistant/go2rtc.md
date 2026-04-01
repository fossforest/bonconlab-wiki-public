# go2rtc

Lightweight camera stream handler for Home Assistant. Ingests RTSP streams and serves them efficiently to HA dashboards with optional transcoding/rotation.

## Overview

| Property | Value |
|----------|-------|
| Type | Home Assistant Add-on |
| Add-on Repo | AlexxIT addons repository |
| Version | Default (includes Intel VAAPI) |
| Web UI | http://homeassistant.local:1984 |
| RTSP Output | rtsp://127.0.0.1:8554/{stream_name} |
| Status | ✅ Active |

## Why go2rtc?

- **Efficient stream handling** — Converts camera streams to WebRTC for low-latency playback in HA dashboards
- **Single stream source** — Camera only needs to serve one stream; go2rtc distributes to multiple viewers
- **Transcoding when needed** — Can rotate, resize, or re-encode streams via FFmpeg
- **Passthrough when possible** — No CPU overhead for streams that don't need processing

## Installation

1. Settings → Add-ons → Add-on Store
2. Search "go2rtc" (from AlexxIT repository)
3. Install the **default** version (includes Intel VAAPI for hardware acceleration if needed)
4. Start the add-on

## Configuration

Configuration is done in the add-on's Configuration tab. The config uses YAML format.

### Current Stream Configuration

```yaml
streams:
  # Doorbell camera - mounted sideways, requires 90° clockwise rotation
  doorbell_raw:
    - rtsp://USERNAME:PASSWORD@10.0.0.254:554/h264Preview_01_main
  
  doorbell_rotated:
    - "ffmpeg:doorbell_raw#video=h264#raw=-vf transpose=1"
  
  # Driveway camera - straight passthrough, no processing
  driveway:
    - rtsp://USERNAME:PASSWORD@10.0.0.243:554/h264Preview_01_main
```

### Configuration Explained

**Passthrough streams** (no processing):
```yaml
stream_name:
  - rtsp://user:pass@IP:554/h264Preview_01_main
```
Just proxies the RTSP stream with no CPU overhead.

**Processed streams** (rotation, resize, etc.):
```yaml
source_stream:
  - rtsp://user:pass@IP:554/h264Preview_01_main

processed_stream:
  - "ffmpeg:source_stream#video=h264#raw=-vf transpose=1"
```
- First stream defines the raw source
- Second stream references the first and processes it through FFmpeg
- `#video=h264` — Re-encode as h264
- `#raw=-vf transpose=1` — Pass `-vf transpose=1` to FFmpeg (90° clockwise rotation)

### FFmpeg Transpose Values

| Value | Rotation |
|-------|----------|
| 0 | 90° counter-clockwise + vertical flip |
| 1 | 90° clockwise |
| 2 | 90° counter-clockwise |
| 3 | 90° clockwise + vertical flip |

## Accessing Streams

### go2rtc Web UI

Browse to `http://homeassistant.local:1984` to:
- View all configured streams
- Test stream playback
- Check stream status and errors

### Stream URLs for Home Assistant

| Format | URL Pattern |
|--------|-------------|
| RTSP | `rtsp://127.0.0.1:8554/{stream_name}` |
| Snapshot | `http://127.0.0.1:1984/api/frame.jpeg?src={stream_name}` |
| WebRTC | Available via HA frontend automatically |

## Reolink RTSP URLs

Reolink cameras use this RTSP URL format:

| Stream | URL |
|--------|-----|
| Main (high res) | `rtsp://user:pass@IP:554/h264Preview_01_main` |
| Sub (low res) | `rtsp://user:pass@IP:554/h264Preview_01_sub` |

RTSP must be enabled in the Reolink app/web UI under Device Settings → Network → Advanced → Port Settings.

## Troubleshooting

### Stream not loading

1. Check go2rtc web UI (`http://homeassistant.local:1984`) for errors
2. Verify RTSP is enabled on the camera
3. Test RTSP URL directly with VLC: `vlc rtsp://user:pass@IP:554/h264Preview_01_main`
4. Check credentials

### FFmpeg filter errors

If you see errors like "Unable to choose output format for 'transpose=1'":
- Ensure you're using the two-stream approach (raw source + processed stream)
- The processed stream must reference the source stream name, not the RTSP URL directly
- Use `#raw=-vf transpose=1` syntax (with `-vf` flag)

### High CPU usage

- Passthrough streams use minimal CPU
- FFmpeg processing (rotation, transcoding) uses significant CPU
- For multiple processed streams, consider the go2rtc (hardware) add-on variant for Intel Quick Sync

## Related

- [Cameras](cameras.md) — Camera entity setup in Home Assistant
- [Home Assistant Overview](../home-assistant.md)
