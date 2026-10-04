# ESPHome Reptile Enclosure Thermostat

An ESP32 + ESPHome controller for a reptile enclosure heated by a radiant heat panel. It replaces a commercial proportional thermostat with a local PID loop, monitors the enclosure, and integrates with Home Assistant.

Built for a corn snake, but the setpoints are adjustable for other species.

## Goals

- **Precise heat:** pulse-proportional (PID) control of a radiant heat panel through a solid-state relay, regulating on the hottest of a surface probe and an IR sensor.
- **Safe by default:** heat turns off on any sensor fault, stale or implausible reading, or over-temperature (fixed hard limit). Designed to be paired with an independent upstream failsafe plug.
- **Local first:** control and all settings live on the ESP32 and persist through reboots and Home Assistant outages.
- **Visible:** an on-device OLED plus Home Assistant entities for every reading, setting, and status.

## Hardware (summary)

ESP32 · 2× DS18B20 (stone surface, cool side) · MLX90614ESF-DCI IR sensor (over Cat6) · SHT30 humidity probe · SH1106 OLED · SSR · radiant heat panel. Full parts list and wiring are in `BUILD.md`.

## Files

| File | Purpose |
|---|---|
| `snake-thermostat.yaml` | ESPHome firmware config |
| `secrets.example.yaml` | Template for `secrets.yaml` (Wi-Fi, API, OTA) |
| `snake-thermostat-wiring.drawio` | Wiring diagrams: low-voltage and mains pages (open at diagrams.net) |
| `BUILD.md` | Parts, wiring tables, sensor placement, failsafe design, bring-up checklist |
| `ENTITIES.md` | Home Assistant entities and an example dashboard card |

## Quick start

1. Copy `secrets.example.yaml` to `secrets.yaml` and fill it in.
2. Wire per `BUILD.md` and the diagram. Bench-test with a lamp, not the heat panel.
3. Flash with ESPHome and confirm the I2C scan finds 0x3C, 0x44, 0x5A.
4. Adopt the device in Home Assistant and add the controls from `ENTITIES.md` to a dashboard.
5. Run **PID Autotune** with the enclosure assembled, then copy the tuned values into the YAML.
6. Set up and test the upstream failsafe before an animal goes in.

## Safety

This project switches mains power to a heater near a live animal. Use a fused, grounded enclosure for mains wiring, an independent failsafe, and test every fault path before use. Use at your own risk.
