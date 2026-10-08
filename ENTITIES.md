# Home Assistant Entities

Entity IDs below assume the default `friendly_name: "Snake Enclosure"`. If you change it, the `snake_enclosure_` prefix changes to match. Temperatures are reported in °C and shown in °F automatically if Home Assistant uses imperial units.

All controls are stored on the ESP32 and restored after a reboot or Home Assistant outage.

## Controls

| Entity | Type | Description |
|---|---|---|
| `switch.snake_enclosure_heater_enable` | Switch | Master heat on/off; off also opens the cutoff relay (safety limits still apply when on) |
| `number.snake_enclosure_hot_zone_day_setpoint` | Number | Hot-zone target during the day (default 87°F) |
| `number.snake_enclosure_hot_zone_night_setpoint` | Number | Hot-zone target at night (default 75°F) |
| `number.snake_enclosure_night_start_hour` | Number | Hour night mode starts (0–23, default 21) |
| `number.snake_enclosure_night_end_hour` | Number | Hour night mode ends (0–23, default 7) |
| `number.snake_enclosure_cool_side_low_alert` | Number | Cool-side low alert threshold (default 70°F) |
| `number.snake_enclosure_humidity_low_alert` | Number | Humidity low alert threshold (default 30%) |
| `number.snake_enclosure_humidity_high_alert` | Number | Humidity high alert threshold (default 70%) |
| `climate.snake_enclosure_hot_zone_thermostat` | Climate | PID thermostat. Its target follows the setpoint numbers, so set targets there rather than on this card |

## Readings

| Entity | Description |
|---|---|
| `sensor.snake_enclosure_hot_zone_control` | Control input: hotter of stone probe and IR |
| `sensor.snake_enclosure_stone_temperature` | DS18B20 on the basking stone |
| `sensor.snake_enclosure_stone_surface_ir` | MLX90614 IR reading of the stone |
| `sensor.snake_enclosure_ir_sensor_ambient` | MLX90614 housing temperature |
| `sensor.snake_enclosure_cool_side_temperature` | DS18B20 on the cool side |
| `sensor.snake_enclosure_enclosure_air_temperature` | SHT30 air temperature |
| `sensor.snake_enclosure_enclosure_humidity` | SHT30 relative humidity |
| `sensor.snake_enclosure_active_setpoint` | Setpoint currently in effect (day or night) |
| `sensor.snake_enclosure_heater_duty` | Heater output, 0–100% |

## Status

| Entity | Description |
|---|---|
| `sensor.snake_enclosure_heater_status` | Text: Heating, Idle, Disabled, or "Fault: reason" |
| `binary_sensor.snake_enclosure_heater_fault` | On when heat is forced off by a fault |
| `binary_sensor.snake_enclosure_heater_active` | On while the heater is pulsing |
| `binary_sensor.snake_enclosure_cutoff_relay_closed` | On while the series cutoff relay is closed (heating allowed) |
| `binary_sensor.snake_enclosure_night_mode` | On during night hours |
| `binary_sensor.snake_enclosure_cool_side_low` | On when cool side is below its alert threshold |
| `binary_sensor.snake_enclosure_humidity_out_of_range` | On when humidity is outside its alert range |
| `binary_sensor.snake_enclosure_status` | Device connectivity (use for an "offline" alert) |

## Diagnostics and maintenance

| Entity | Description |
|---|---|
| `sensor.snake_enclosure_wifi_signal` | Wi-Fi RSSI |
| `sensor.snake_enclosure_uptime` | Seconds since boot |
| `button.snake_enclosure_pid_autotune` | Start PID autotune (results appear in device logs) |
| `button.snake_enclosure_pid_reset_integral` | Clear the PID integral term |
| `button.snake_enclosure_restart` | Reboot the ESP32 |

## Example dashboard card

```yaml
type: vertical-stack
cards:
  - type: glance
    title: Enclosure
    entities:
      - entity: sensor.snake_enclosure_hot_zone_control
        name: Hot
      - entity: sensor.snake_enclosure_cool_side_temperature
        name: Cool
      - entity: sensor.snake_enclosure_enclosure_humidity
        name: Humidity
      - entity: sensor.snake_enclosure_heater_duty
        name: Heater
  - type: entities
    title: Heat control
    entities:
      - switch.snake_enclosure_heater_enable
      - sensor.snake_enclosure_heater_status
      - sensor.snake_enclosure_active_setpoint
      - number.snake_enclosure_hot_zone_day_setpoint
      - number.snake_enclosure_hot_zone_night_setpoint
      - number.snake_enclosure_night_start_hour
      - number.snake_enclosure_night_end_hour
  - type: entities
    title: Alerts
    entities:
      - binary_sensor.snake_enclosure_heater_fault
      - binary_sensor.snake_enclosure_cool_side_low
      - binary_sensor.snake_enclosure_humidity_out_of_range
      - binary_sensor.snake_enclosure_status
      - number.snake_enclosure_cool_side_low_alert
      - number.snake_enclosure_humidity_low_alert
      - number.snake_enclosure_humidity_high_alert
  - type: history-graph
    title: Last 24 hours
    hours_to_show: 24
    entities:
      - sensor.snake_enclosure_hot_zone_control
      - sensor.snake_enclosure_active_setpoint
      - sensor.snake_enclosure_cool_side_temperature
```
