# Build Guide

ESPHome-based thermostat and monitor for a 4×2×2 ft bioactive corn snake enclosure. The ESP32 pulse-controls an 80 W radiant heat panel (RHP) through an SSR, monitors hot/cool/humidity, and reports to Home Assistant. A mechanical cutoff relay in series with the SSR opens on any fault, so a shorted SSR can't overheat the enclosure. An upstream Z-Wave plug failsafe is optional.

See `README.md` for the file list and `ENTITIES.md` for Home Assistant entities.

---

## Design principles

- **Control runs locally on the ESP32.** PID and safety logic never depend on Home Assistant or Wi-Fi.
- **Control input = max(stone DS18B20, MLX90614 IR).** The thermostat regulates on whichever hot-zone reading is hottest.
- **Fail off.** Any NaN, stale (>60 s), implausible, or >92°F hot-zone reading forces the heater off. The heater also boots off and enables only once sensors are valid.
- **Two switches in series.** The SSR pulses the heat; a mechanical relay (SRD-05VDC-SL-C relay shield) is closed only while heating is allowed. Any fault, over-limit reading, Heater Enable off, ESP32 reboot, or ESP32 power loss opens it, so a shorted SSR is still cut off. This matches or exceeds a standalone reptile thermostat.
- **Known limit: one controller.** The relay and SSR share the ESP32's sensors and firmware. A sensor that reads low but plausible (e.g. a stone probe that has come loose) or a bad config change can hold both closed. Mount the probes securely and keep the IR sensor aimed; the control input uses the hotter of the two. For protection against that too, add the optional upstream failsafe.
- **Optional failsafe upstream.** A ZEN04 plug (via Home Assistant) or a plug-in thermostat such as an Inkbird ITC-308 with its own probe can cut the whole heater circuit independently of the ESP32.
- **Settings persist locally.** Setpoints, the day/night schedule, alert limits, and Heater Enable are stored in the ESP32's flash and restored on boot, so control continues unchanged if Home Assistant is offline.
- **ESP32 powered separately.** It runs on its own USB supply on a different outlet, so monitoring and alerts survive an upstream failsafe trip.
- **No mains wiring inside the enclosure.** Only low-voltage sensor cables and the panel's own cord enter the tank.

## Target temperatures (corn snake)

| Zone | Target |
|---|---|
| Warm surface (stone top) | 85–88°F (default day setpoint 87°F) |
| Cool side | 72–75°F |
| Night | Upper 60s ambient OK (default night setpoint 75°F) |
| Humidity | ~40% (30s tolerated) |
| Software hard limit | 92°F, heater forced off (re-enables below 90°F) |
| Optional upstream failsafe trip | ~95°F |

---

## Parts inventory

| Part | Qty | ~Price | Source / notes |
|---|---|---|---|
| ESP32-DevKitC, 38-pin, **WROOM-32U** | 1 | $8–10 | Pin rows 0.9" apart; the -32U has no built-in antenna |
| 2.4 GHz antenna with U.FL (IPEX) pigtail | 1 | $5 | Required for the WROOM-32U |
| CircuitSetup Project Box Breadboard | 1 | $10 | 30-row solderable breadboard; layout in `diagrams/breadboard.svg` |
| 19-pin female headers (0.1") | 2 | $2 | The ESP32 plugs into these |
| DROK DS18B20 waterproof probe 2-pack (adapter boards, 4.7k resistors) | 1–2 | $10–12/pack | [Amazon B0FLDQJ71M](https://www.amazon.com/dp/B0FLDQJ71M) |
| GY-906-DCI (MLX90614ESF-DCI) IR sensor, 5° FOV | 1 | $30–40 | [Amazon B0B63N57CS](https://www.amazon.com/dp/B0B63N57CS) |
| SHT30 enclosed probe, 2 m cable | 1 | $8–12 | Amazon "SHT30 probe waterproof" |
| HiLetgo 1.3" SH1106 OLED (4-pin I2C) | 1 | $12 | [Amazon B07BHHV844](https://www.amazon.com/dp/B07BHHV844) |
| Cat6 stranded patch cable (cut in half) | 1 | $5–8 | Any; solid-core bulk cable not recommended |
| RJ45 jack for the main board | 1 | $1–2 | Through-hole RJ45 or a second screw adapter |
| RJ45 screw-terminal adapter (sensor end) | 1 | $10–15 | XUGERIP 4-pack [Amazon B0FQJTKCZZ](https://www.amazon.com/dp/B0FQJTKCZZ) or [SchmalzTech mini](https://www.robotshop.com/products/schmalztech-rj45-mini-screw-terminal-breakout-board) |
| 10k resistors (GPIO19/GPIO18 pull-downs), 100 nF capacitors | few | $1 | Any |
| Inkbird SSR-40DA (budget) **or** genuine Crydom D2410 | 1 | $10 / $48–57 | Inkbird [Amazon B00HV974KC](https://www.amazon.com/dp/B00HV974KC); Crydom via [Digi-Key](https://www.digikey.com/en/products/result?keywords=Crydom%20D2410) |
| Wemos D1 mini relay shield (SRD-05VDC-SL-C, 5V coil, 10A) | 1 | $3–5 | Amazon "D1 mini relay shield"; cutoff relay in series with the SSR |
| *Optional:* Zooz ZEN04 Z-Wave plug **or** Inkbird ITC-308 | 1 | $35–40 | Independent upstream failsafe; [getzooz.com](https://www.getzooz.com) |
| C14 fused inlet, 5×20 mm (no switch) | 1 | $8–10 | [Amazon search](https://www.amazon.com/s?k=IEC+C14+inlet+fuse+holder+panel+mount) |
| 2A slow-blow 5×20 mm fuses | 1 pack | $6 | [Amazon search](https://www.amazon.com/s?k=2A+250V+slow+blow+5x20mm+fuse) |
| C13 power cord, 18 AWG, 3-prong | 1 | $7 | Any computer cord |
| NEMA 5-15R pigtail outlet (black/white/green leads) | 1 | $5–10 | Amazon |
| Project box: 3D-printed ASA/PETG (not PLA) or purchased, + cable glands | 1 | $15–20 | |
| USB 5V supply + cable (ESP32) | 1 | $8 | On a separate outlet |
| 18 AWG stranded wire, insulated 0.187" quick-connects, heat shrink | — | $10 | Any |

**Verify on arrival**
- [ ] SH1106 is the **4-pin I2C** version (header: GND VCC SCL SDA).
- [ ] MLX90614 has the **tall canned lens** (GY-906-DCI, narrow FOV).
- [ ] C14 inlet: identify the **fused L**, N, and E tabs with a continuity test.
- [ ] SHT30 probe: confirm which of yellow/white is SDA vs SCL from the seller listing.

---

## Low-voltage wiring

Full schematic: [`diagrams/schematic.svg`](diagrams/schematic.svg). Hole-by-hole protoboard layout: [`diagrams/breadboard.svg`](diagrams/breadboard.svg).

All sensors on **3V3**, never 5V/VIN.

| Device | Address | ESP32 pin | Wire colors / pins |
|---|---|---|---|
| Stone DS18B20 (hot zone) | 1-Wire | GPIO4 | Probe → adapter: yellow DAT, red VCC, black GND |
| Cool-side DS18B20 | 1-Wire | GPIO16 | Same as above |
| SHT30 probe | 0x44 | SDA GPIO21 / SCL GPIO22 | Red VCC, black GND, yellow/white = SDA/SCL (verify) |
| SH1106 OLED | 0x3C | SDA GPIO21 / SCL GPIO22 | Header: GND VCC SCL SDA |
| GY-906-DCI (MLX90614) | 0x5A | SDA GPIO21 / SCL GPIO22 | Via Cat6 + RJ45 (map below) |
| SSR input | — | GPIO19 → terminal 3 (+), GND → terminal 4 (−) | **10k pull-down GPIO19 → GND** |
| Cutoff relay shield | — | GPIO18 → shield **D1**, ESP32 5V/VIN → shield **5V**, GND → shield **GND** | **10k pull-down GPIO18 → GND**. Coil is 5V (~70–90 mA from USB); 3.3V logic drives the shield's transistor |

**Cat6 (T568B) pair map to the GY-906**

| Pair | Signal | Return |
|---|---|---|
| Orange: pin 2 / white-orange pin 1 | SDA | GND |
| Green: pin 6 / white-green pin 3 | SCL | GND |
| Blue: pin 4 / white-blue pin 5 | 3V3 → VIN | GND |
| Brown: pins 7, 8 | Unused or GND | |

Notes:
- Each DS18B20 has its own GPIO because the adapter boards have built-in pull-ups. The OLED and GY-906 boards supply I2C pull-ups, so don't add more unless the I2C scan fails.
- I2C runs at 50 kHz for the Cat6 run. Add a 100 nF capacitor across VIN/GND at the sensor-end adapter.
- If the SSR triggers unreliably at 3.3V, drive it from 5V through an NPN transistor (1k base resistor) or a logic-level MOSFET (100 Ω gate, 10k pull-down).
- For a possible second channel: GPIO17/23 (DS18B20s), GPIO32/33 (second I2C bus for a second MLX), SHT30 at 0x45, GPIO26 (second SSR), GPIO27 (second cutoff relay). Avoid GPIO0, 2, 12, 15 and 34–39.

## Mains-side wiring

Path: wall outlet → *(optional ZEN04 / ITC-308)* → C13 cord → **C14 fused inlet (2A)** → cutoff relay → SSR → pigtail outlet → RHP.

| From | To | Conductor |
|---|---|---|
| C14 L (fused) | Relay **COM** (middle screw terminal) | Hot |
| Relay **NO** (screw terminal marked NO) | SSR terminal 1 | Hot |
| SSR terminal 2 | Outlet black lead | Hot |
| C14 N | Outlet white lead | Neutral |
| C14 E | Outlet green ring lug (+ box chassis if metal) | Ground |

- Only hot passes through the relay and SSR. Leave the relay's NC terminal empty.
- Use slow-blow fuses and insulated quick-connects with heat shrink.
- The inlet has no switch. Unplug it for maintenance; turning off Heater Enable opens the relay but leaves the inlet, relay, and SSR terminals live.
- Keep SSR mains terminals physically separated from the ESP32 and low-voltage wiring.
- The relay shield carries mains on the same small PCB as its logic pins. Mount it in the mains compartment on standoffs, insulate it from the ESP32 side, and run only its 5V/GND/D1 jumpers across. Don't stack it on a D1 mini or the ESP32 board.

---

## Sensor placement

- **Stone probe:** on **top** of the basking stone (radiant heat comes from above), recessed in a shallow masonry-cut groove sealed with aquarium-safe silicone, near an edge but still under the panel.
- **Cool probe:** cool-side floor.
- **GY-906-DCI:** ~12" above the stone (reads ~1" spot), beside the panel rather than under it. The RJ45 adapter and Cat6 jacket are rated only to ~70°C.
- **SHT30 probe:** mid-height toward the cool side, away from the water bowl and panel, above the substrate.
- **OLED + ESP32:** in the project box **outside** the enclosure.
- Route sensor cables through a sealed grommet; keep cable jackets away from the panel.
- **Never** use electric heat rocks; the stone is passive thermal mass only.

## ESPHome config summary (`snake-thermostat.yaml`)

- `slow_pwm` output on GPIO19 (15 s period) driven by a `pid` climate entity.
- Control sensor "Hot Zone (Control)" = max(stone, IR), NaN if either is invalid.
- Day/night setpoints and schedule hours are number entities (persisted in flash). The active setpoint is pushed to the thermostat every 30 s and on any change. Time comes from SNTP, then Home Assistant; with no valid time, the day setpoint is used.
- Safety loop (2 s): forces heat off on any fault, clears once readings are valid and below 90°F, and only heats while **Heater Enable** is on. The 92°F hard limit is fixed in firmware.
- Cutoff relay (GPIO18) is closed only while the safety loop allows heat, and boots open. If the SSR shorts, the hot zone reaches the 92°F limit, the relay opens, and it recloses below 90°F. The heater then cycles on the relay around 90–92°F until you replace the SSR. The first trip latches the **Alarm**.
- MLX emissivity set to 0.95 for stone.
- OLED shows Hot / Cool / RH / heater % / setpoint, shifts pixels every few minutes, and turns off during night hours.
- After autotune, paste the suggested `kp/ki/kd` from the logs into `control_parameters`.
- Full entity list: `ENTITIES.md`.

## Alerts (Home Assistant)

The ESP32 exposes a latched **Alarm** (`binary_sensor.snake_enclosure_alarm`, device class *problem*) with the cause in **Alarm Reason**. It turns on when:

| Cause | Alarm Reason |
|---|---|
| Hot zone hits the 92°F hard limit | `Over temperature limit` (adds `; SSR may be stuck on` if the PID was asking for <10% heat) |
| Any sensor fault (no reading, stale, implausible) lasting >2 min | `Sensor fault: <reason>` |
| Hot zone above 95°F while the relay is open | `Hot zone above 95F with heater cut off` (relay or external heat problem) |

It stays on, including through reboots, until you press **Clear Alarm**. If the condition still holds, it re-raises. The OLED shows `ALARM` while it's latched.

Set up two Home Assistant notifications:

1. `binary_sensor.snake_enclosure_alarm` turns **on** → phone alert, including the state of `sensor.snake_enclosure_alarm_reason`.
2. `binary_sensor.snake_enclosure_status` is **off** for 5 min → "thermostat offline" alert. The ESP32 can't report its own crash or power loss, so this one has to come from HA. The heater is already off in that case, because the relay opens.

`Cool Side Low` and `Humidity Out of Range` are separate, non-latching warnings for husbandry alerts.

## Optional upstream failsafe

Not required: the cutoff relay already covers a shorted SSR. Add one only to also cover a sensor or firmware mistake on the ESP32.

**Inkbird ITC-308 (no HA dependency):** plug it in upstream, put its probe at the basking surface, and set the heating setpoint to ~95°F. It cuts power only if the ESP32's own sensors are wrong.

**ZEN04 (via HA):** an automation turns off the ZEN04 and sends a phone alert when any of these fire:

1. Either hot-zone reading > ~95°F (catches a stuck SSR).
2. ESP32 `Status` offline for more than a few minutes (catches a crash).
3. ZEN04 reads > ~20–30 W while `Heater Duty` = 0% (or `Heater Active` is off) for 60 s (direct stuck-SSR detection; threshold allows for SSR off-state leakage).

Optional: alert if `Heater Duty` > 0 for several minutes but the ZEN04 reads ~0 W (fuse blown, plug off).

The ZEN04 failsafe depends on HA being up. A 4 ft gradient gives the snake room to retreat.

---

## Bring-up and test checklist

- [ ] Fit the U.FL antenna, then flash the ESP32 over USB; confirm the I2C scan in logs shows 0x3C, 0x44, 0x5A.
- [ ] Both DS18B20s read sensibly; compare to a reference thermometer.
- [ ] Unplug a probe: Heater Fault turns on and heater duty goes to 0; after 2 min, Alarm turns on with `Sensor fault: …`. Reconnect, press Clear Alarm.
- [ ] Both HA notifications fire (Alarm on; ESP32 USB unplugged for 5 min).
- [ ] Multimeter: ground continuity from the plug's ground pin to the outlet ground (unplugged).
- [ ] Lamp in the outlet: ESP32 pulses it; lamp stays off during boot and flashing.
- [ ] Relay clicks closed once sensors are valid and `Cutoff Relay Closed` turns on; it opens (lamp off) when you turn off Heater Enable, unplug a probe, or unplug the ESP32's USB.
- [ ] Simulate a shorted SSR: jumper SSR terminals 1–2 (unplugged first), power up, warm the stone probe past 92°F; the relay must open, the lamp go off, and Alarm turn on. Remove the jumper afterwards.
- [ ] If fitted: each upstream failsafe trigger kills the lamp.
- [ ] RHP connected: run autotune with the stone installed (1–2 hr), update PID values, then watch a full day/night cycle, including the night setpoint switch.
- [ ] Cool side holds ≥ 72°F in the enclosure's room for a week before the animal moves in.
- [ ] Transfer to the CircuitSetup protoboard per [`diagrams/breadboard.svg`](diagrams/breadboard.svg). The ESP32 headers go in rows a and i, columns 11–29 (dry-fit confirmed).

## Open items

- [ ] Home Assistant notifications on `Alarm` and `Status` offline
- [ ] Confirm Wi-Fi reaches the enclosure location
- [ ] Optional: upstream failsafe (ITC-308, or ZEN04 + HA automation)
