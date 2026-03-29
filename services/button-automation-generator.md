# Button Automation Generator

Local HTML tool for quickly generating Home Assistant button automation YAML templates.

## Overview

| Property | Value |
|----------|-------|
| Type | Static HTML page |
| Hosted On | Nginx Proxy Manager (TMG LXC 101) |
| URL | http://10.0.0.238/tools/ |
| File Location | `/var/www/html/tools/index.html` (in container) |
| Status | ✅ Active |

## Access

**Web Interface**: http://10.0.0.238/tools/

## Purpose

This tool streamlines the process of creating Home Assistant automations for smart buttons (like Zigbee buttons via MQTT). Instead of manually writing or copying YAML for each new button, this generates the complete template structure with proper trigger IDs and a choose/option framework.

## Automation Framework

The generated automations use a structured approach:
- **Named triggers** with IDs: Single press, Double press, Long press, Release after long press
- **Choose/option blocks** that route based on trigger ID
- **Clear placeholders** for adding actions and additional conditions

This framework keeps all button functionality in a single automation, making it easy to see at a glance what each press type does.

## Usage

1. Open http://10.0.0.238/tools/ in any browser
2. (Optional) Enter a name for the button
3. Paste the device ID
4. Click "Generate YAML"
5. Copy the output
6. In Home Assistant: Settings → Automations → Create Automation → Skip → Edit in YAML
7. Paste the generated YAML
8. Fill in the action sequences for each press type

## Finding Device IDs

**Method 1 - From Device Page:**
1. Settings → Devices & Services → Devices tab
2. Click the button device
3. Copy the device ID from the URL:
   - Example: `http://homeassistant.local:8123/config/devices/device/de9cf92aac6292fd20f56e2cdc9a9ae4`
   - Device ID: `de9cf92aac6292fd20f56e2cdc9a9ae4`

**Method 2 - From Existing Automation:**
1. Open an automation that uses the button
2. Edit in YAML
3. Look for `device_id:` under any trigger
4. Copy that value

## Example Output

```yaml
alias: Kitchen button
description: ""
triggers:
  - alias: Single press
    domain: mqtt
    device_id: de9cf92aac6292fd20f56e2cdc9a9ae4
    type: action
    subtype: single
    trigger: device
    id: Single press
  - alias: Double press
    domain: mqtt
    device_id: de9cf92aac6292fd20f56e2cdc9a9ae4
    type: action
    subtype: double
    trigger: device
    id: Double press
  - alias: Long press
    domain: mqtt
    device_id: de9cf92aac6292fd20f56e2cdc9a9ae4
    type: action
    subtype: hold
    trigger: device
    id: Long press
  - alias: Release after long press
    domain: mqtt
    device_id: de9cf92aac6292fd20f56e2cdc9a9ae4
    type: action
    subtype: release
    trigger: device
    id: Release after long press

conditions: []

actions:
  - choose:
      - conditions:
          - condition: trigger
            id: Single press
        sequence: []
      - conditions:
          - condition: trigger
            id: Double press
        sequence: []
      - conditions:
          - condition: trigger
            id: Long press
        sequence: []
      - conditions:
          - condition: trigger
            id: Release after long press
        sequence: []

mode: single
```

## Why Not Use Blueprints?

Blueprints were initially considered but ultimately abandoned in favor of this template approach. While blueprints provide convenience, they sacrifice flexibility:

- Can't easily add complex conditions beyond what's exposed as inputs
- UI feels limiting compared to full automation editor
- Adding extra logic requires modifying the blueprint itself

This tool provides the structured starting point of a blueprint while maintaining full automation flexibility in the Home Assistant UI.

## Updating the Tool

To update the HTML file:

```bash
# From TMG host
pct push 101 /path/to/updated-file.html /var/www/html/tools/index.html
```

Or edit directly in the container:

```bash
pct enter 101
nano /var/www/html/tools/index.html
```

## Notes

- Accessible from any device on the local network
- No internet connection required
- Dark theme matches Home Assistant UI
- Copy-to-clipboard function for quick workflow

## Related

- [Nginx Proxy Manager](nginxproxymanager.md)
- [Home Assistant](../home-assistant.md)
- [Zigbee2MQTT](zigbee2mqtt.md)
