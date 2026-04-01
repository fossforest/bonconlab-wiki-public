# Cameras

Camera setup in Home Assistant using go2rtc for stream handling.

## Overview

| Camera | Location | IP | Processing | Status |
|--------|----------|-----|------------|--------|
| Doorbell | Front door | 10.0.0.254 | 90° rotation via FFmpeg | ✅ Active |
| Driveway | Driveway | 10.0.0.243 | Passthrough (none) | ✅ Active |

## Hardware

### Reolink Doorbell

- **Model**: Reolink Video Doorbell (180° FoV)
- **IP**: 10.0.0.254
- **Mounting**: Sideways (to get vertical FoV for head-to-toe coverage)
- **Stream rotation**: Handled by go2rtc via FFmpeg transpose filter

The doorbell's wide-angle lens is designed for horizontal mounting, but mounting it sideways gives better vertical coverage of visitors. The 90° rotation is applied in software via go2rtc.

### Reolink Driveway Camera

- **IP**: 10.0.0.243
- **Mounting**: Standard
- **Processing**: None (passthrough)

## Camera Entities

Cameras are added via the **Generic Camera** integration, pulling streams from go2rtc.

### Adding a Camera

1. Settings → Devices & Services → Add Integration
2. Search "Generic Camera"
3. Fill in:
   - **Stream source URL**: `rtsp://127.0.0.1:8554/{stream_name}`
   - **Still image URL**: `http://127.0.0.1:1984/api/frame.jpeg?src={stream_name}`
   - **Username/Password**: Leave blank (go2rtc handles auth to the camera)
4. Submit

### Current Entities

| Entity | Stream Name | go2rtc Processing |
|--------|-------------|-------------------|
| `camera.doorbell` | doorbell_rotated | FFmpeg rotation |
| `camera.driveway` | driveway | None (passthrough) |

## Dashboard Cards

### Picture Glance Card

Good for showing camera with overlaid entity states:

```yaml
type: picture-glance
camera_image: camera.doorbell
camera_view: auto
entities: []
```

### Camera Card (Simple)

```yaml
type: picture-entity
entity: camera.doorbell
camera_view: auto
show_name: true
show_state: false
```

## Stream Architecture

```
Reolink Camera (RTSP)
        │
        ▼
    go2rtc Add-on
   ┌────┴────┐
   │ Process │ (rotation, if needed)
   └────┬────┘
        │
        ▼
  RTSP @ 127.0.0.1:8554
        │
        ▼
 Generic Camera Integration
        │
        ▼
   HA Dashboard (WebRTC)
```

## Excluded Camera

### Prusa Buddy3D Camera

- **IP**: 10.0.0.107
- **Status**: Not integrated with HA
- **Reason**: Camera only supports WebRTC or RTSP streaming (mutually exclusive in settings). WebRTC is needed for PrusaConnect web/app monitoring. go2rtc can't easily ingest Prusa's WebRTC implementation.
- **Viewing**: Use PrusaConnect app or web interface

## Troubleshooting

### Camera shows "Unavailable"

1. Check go2rtc web UI: `http://homeassistant.local:1984`
2. Verify the stream is working there first
3. If go2rtc works but HA doesn't, restart the Generic Camera integration

### Low framerate or stuttering

- Check if camera is being accessed by multiple clients (Reolink app, NVR, etc.)
- go2rtc should be the single client to the camera; other viewers connect to go2rtc

### Snapshot not updating

The still image URL (`/api/frame.jpeg`) grabs a single frame on demand. If it's stale:
1. Check go2rtc is running
2. Try accessing the URL directly in browser

## Related

- [go2rtc](go2rtc.md) — Stream configuration and rotation setup
- [Home Assistant Overview](../home-assistant.md)
