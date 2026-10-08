# AGENTS.md

ESPHome firmware and build docs for an ESP32 reptile-enclosure thermostat. It pulse-controls a radiant heat panel through an SSR, with a series cutoff relay and a latched alarm, and reports to Home Assistant.

## Tour

| File | What it is |
|---|---|
| `snake-thermostat.yaml` | ESPHome config: sensors, PID, safety loop, cutoff relay, alarm, OLED |
| `BUILD.md` | Parts, wiring tables, safety design, alerts, bring-up checklist |
| `ENTITIES.md` | Home Assistant entities and example dashboard card |
| `README.md` | Project overview |
| `snake-thermostat-wiring.drawio` | Wiring diagrams (low-voltage and mains pages) |
| `secrets.example.yaml` | Template for `secrets.yaml` (never commit the real one) |

When firmware behavior or wiring changes, keep `BUILD.md`, `ENTITIES.md`, and the diagram in sync.

This controls mains heat near a live animal. Don't weaken the fail-off safety logic (hard limit, sensor-fault cutoff, relay boot state) without being asked.

## Git rules

- **Never commit or push to `main`.** Always work on a feature branch (`git checkout -b <short-description>`) and push that branch.
- Validate with `esphome config snake-thermostat.yaml` (needs a `secrets.yaml` copied from the example, with `api_key` set to any valid base64 32-byte key) before committing.
