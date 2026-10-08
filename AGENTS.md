# AGENTS.md

ESPHome firmware and build docs for an ESP32 reptile-enclosure thermostat. It pulse-controls a radiant heat panel through an SSR, with a series cutoff relay and a latched alarm, and reports to Home Assistant.

## Tour

| File | What it is |
|---|---|
| `snake-thermostat.yaml` | ESPHome config: sensors, PID, safety loop, cutoff relay, alarm, OLED |
| `BUILD.md` | Parts, wiring tables, safety design, alerts, bring-up checklist |
| `ENTITIES.md` | Home Assistant entities and example dashboard card |
| `README.md` | Project overview |
| `diagrams/circuit.json` | Parts and nets: single source of truth for the schematic (and breadboard layout) |
| `diagrams/schematic.json`, `diagrams/schematic.svg` | Schematic sheet and rendered SVG, machine-checked against `circuit.json` (schematic-svg skill) |
| `diagrams/breadboard.json`, `diagrams/breadboard.svg` | Protoboard layout, checked against `circuit.json`. Render with `python3 diagrams/tools/bbsvg.py diagrams/breadboard.json diagrams/breadboard.svg` (patched copy of the breadboard-layout-svg skill script: mirrored column numbering and per-rail polarity labels for the CircuitSetup board) |
| `snake-thermostat-wiring.drawio` | Older hand-drawn wiring diagrams (low-voltage and mains pages) |
| `secrets.example.yaml` | Template for `secrets.yaml` (never commit the real one) |

When firmware behavior or wiring changes, keep `BUILD.md`, `ENTITIES.md`, `diagrams/circuit.json` (then re-render the schematic), and the drawio diagram in sync.

This controls mains heat near a live animal. Don't weaken the fail-off safety logic (hard limit, sensor-fault cutoff, relay boot state) without being asked.

## Git rules

- **Never commit or push to `main`.** Always work on a feature branch (`git checkout -b <short-description>`) and push that branch.
- Validate with `esphome config snake-thermostat.yaml` (needs a `secrets.yaml` copied from the example, with `api_key` set to any valid base64 32-byte key) before committing.
