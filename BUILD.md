# Build Guide

ESPHome-based thermostat and monitor for a 4×2×2 ft bioactive corn snake enclosure. The ESP32 pulse-controls an 80 W radiant heat panel (RHP) through an SSR, monitors hot/cool/humidity, and reports to Home Assistant. A watchdog-controlled relay in series with the SSR cuts heater power on any fault, a stalled loop, or a stuck-on SSR.

See `README.md` for the file list and `ENTITIES.md` for Home Assistant entities.

---

## Design principles

- **Control runs locally on the ESP32.** PID and safety logic never depend on Home Assistant or Wi-Fi.
- **Control input = max(stone DS18B20, MLX90614 IR).** The thermostat regulates on whichever hot-zone reading is hottest.
- **Fail off.** Any NaN, stale (>60 s), implausible, or >92°F hot-zone reading forces the heater off. The heater also boots off and enables only once sensors are valid.
- **Cross-check the two hot-zone sensors.** The stone probe and the IR sensor read the same stone, so sustained disagreement, or full heat with no warming, is treated as a fault. See "Plausibility checks".
- **Second actuator in hardware.** Relay K1 sits in series with the SSR and is held closed by a hardware watchdog only while the firmware asserts PERMIT and keeps a heartbeat going. A shorted SSR is cut off within seconds of the 92°F limit, and a stalled loop opens K1 in about 2 s, with no dependence on Home Assistant or Wi-Fi.
- **Settings persist locally.** Setpoints, the day/night schedule, alert limits, and Heater Enable are stored in the ESP32's flash and restored on boot, so control continues unchanged if Home Assistant is offline.
- **ESP32 powered separately.** It runs on its own USB supply on a different outlet, so monitoring and alerts continue when K1 cuts the heater.
- **No mains wiring inside the enclosure.** Only low-voltage sensor cables and the panel's own cord enter the tank.

## Target temperatures (corn snake)

| Zone | Target |
|---|---|
| Warm surface (stone top) | 85–88°F (default day setpoint 87°F) |
| Cool side | 72–75°F |
| Night | Upper 60s ambient OK (default night setpoint 75°F) |
| Humidity | ~40% (30s tolerated) |
| Software hard limit | 92°F, heater and K1 forced off (re-enables below 90°F) |

---

## Parts inventory

| Part | Qty | ~Price | Source / notes |
|---|---|---|---|
| ESP32 dev board (WROOM-32) | 1 | $8 | Check pin-row spacing fits the protoboard |
| ElectroCookie solderable protoboard (5 + 1 mini) | 1 pack | $12–15 | Amazon; mount the ESP32 on female headers |
| DROK DS18B20 waterproof probe 2-pack (adapter boards, 4.7k resistors) | 1–2 | $10–12/pack | [Amazon B0FLDQJ71M](https://www.amazon.com/dp/B0FLDQJ71M) |
| GY-906-DCI (MLX90614ESF-DCI) IR sensor, 5° FOV | 1 | $30–40 | [Amazon B0B63N57CS](https://www.amazon.com/dp/B0B63N57CS) |
| SHT30 enclosed probe, 2 m cable | 1 | $8–12 | Amazon "SHT30 probe waterproof" |
| HiLetgo 1.3" SH1106 OLED (4-pin I2C) | 1 | $12 | [Amazon B07BHHV844](https://www.amazon.com/dp/B07BHHV844) |
| Cat6 stranded patch cable (cut in half) | 1 | $5–8 | Any; solid-core bulk cable not recommended |
| RJ45 jack for the main board | 1 | $1–2 | Through-hole RJ45 or a second screw adapter |
| RJ45 screw-terminal adapter (sensor end) | 1 | $10–15 | XUGERIP 4-pack [Amazon B0FQJTKCZZ](https://www.amazon.com/dp/B0FQJTKCZZ) or [SchmalzTech mini](https://www.robotshop.com/products/schmalztech-rj45-mini-screw-terminal-breakout-board) |
| 10k resistor (GPIO26 pull-down), 100 nF capacitors | few | $1 | Any |
| Inkbird SSR-40DA (budget) **or** genuine Crydom D2410 | 1 | $10 / $48–57 | Inkbird [Amazon B00HV974KC](https://www.amazon.com/dp/B00HV974KC); Crydom via [Digi-Key](https://www.digikey.com/en/products/result?keywords=Crydom%20D2410) |
| **Heater cutoff** (see "Heater cutoff" below) | | | |
| CD74HCT123E retriggerable one-shot, DIP-16 (+ socket) | 1 | $1 | [Digi-Key](https://www.digikey.com/en/products/detail/texas-instruments/CD74HCT123E/38252). Must be **HCT**, not HC (3.3 V inputs) |
| K1: D1 mini relay shield with Songle SRD-05VDC-SL-C (5 V coil, 10 A contacts) | 1 | $2–4 | Has its own transistor, flyback diode and LED; driven from its D1 pin. Use COM and NO. An Omron G5LE-1-E DC5 with its own driver is the higher-margin alternative |
| 1 MΩ 1% resistor + 4.7 µF low-leakage film capacitor | 1 each | $2 | Watchdog timing (~2.1 s) |
| Resistors: 10k ×5, 100k; capacitors: 100 nF, 100 µF | — | $1 | 10k: 2 pull-downs + 3 for the feedback divider (1 top, 2 in series bottom); 100k holds the relay input low; decoupling |
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

Component-level diagrams for the ESP32 board (DevKitC 38-pin, WROOM-32U): [`esp32-wiring.svg`](esp32-wiring.svg) and the hole-by-hole ElectroCookie layout [`esp32-breadboard.svg`](esp32-breadboard.svg). The WROOM-32U has no antenna of its own: fit a 2.4 GHz U.FL antenna.

All sensors on **3V3**, never 5V/VIN. Only the heater cutoff (U1 and the K1 relay shield) runs on 5V.

| Device | Address | ESP32 pin | Wire colors / pins |
|---|---|---|---|
| Stone DS18B20 (hot zone) | 1-Wire | GPIO4 | Probe → adapter: yellow DAT, red VCC, black GND |
| Cool-side DS18B20 | 1-Wire | GPIO16 | Same as above |
| SHT30 probe | 0x44 | SDA GPIO21 / SCL GPIO22 | Red VCC, black GND, yellow/white = SDA/SCL (verify) |
| SH1106 OLED | 0x3C | SDA GPIO21 / SCL GPIO22 | Header: GND VCC SCL SDA |
| GY-906-DCI (MLX90614) | 0x5A | SDA GPIO21 / SCL GPIO22 | Via Cat6 + RJ45 (map below) |
| SSR input | — | GPIO26 → terminal 3 (+), GND → terminal 4 (−) | **10k pull-down GPIO26 → GND** |
| Cutoff PERMIT | — | GPIO25 → U1 pin 3 (1/CLR) | **10k pull-down GPIO25 → GND** |
| Cutoff HEARTBEAT | — | GPIO23 → U1 pin 2 (1B) | **10k pull-down GPIO23 → GND** |
| Cutoff feedback | — | GPIO34 ← U1 pin 13 (1Q) via divider | 10k from 1Q to GPIO34, 2×10k (20k) GPIO34 → GND (5 V → 3.3 V) |
| Cutoff board power | — | ESP32 **5V/VIN** pin and GND | U1 and the relay shield. The only 5 V parts |

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
- For a possible second channel: GPIO17/18 (DS18B20s), GPIO32/33 (second I2C bus for a second MLX), SHT30 at 0x45, GPIO27 (second SSR), GPIO35 (second cutoff feedback). Avoid GPIO0, 2, 12 and 15, and use GPIO34–39 only as inputs.

## Mains-side wiring

Path: wall outlet → C13 cord → **C14 fused inlet (2A)** → **K1 (COM → NO)** → SSR → pigtail outlet → RHP.

| From | To | Conductor |
|---|---|---|
| C14 L (fused) | K1 COM | Hot |
| K1 NO | SSR terminal 1 | Hot |
| SSR terminal 2 | Outlet black lead | Hot |
| C14 N | Outlet white lead | Neutral |
| C14 E | Outlet green ring lug (+ box chassis if metal) | Ground |

- Only hot passes through K1 and the SSR. K1's NC contact is unused.
- Use slow-blow fuses and insulated quick-connects with heat shrink.
- The inlet has no switch. **Heater Enable** off opens K1, but unplug the cord before touching mains wiring.
- Keep SSR and K1 mains terminals physically separated from the ESP32 and low-voltage wiring. Mount the relay shield on its own (standoffs or a small carrier), at least 6 mm (¼") from any other board, with nothing touching its underside. Only the mains wires go in its screw terminal; strain-relieve them. Don't plug the shield onto the cutoff breadboard: its relay pins and terminal would sit over the 5 V copper. Have the mains side reviewed before it carries the heater.

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

- `slow_pwm` output on GPIO26 (15 s period) driven by a `pid` climate entity.
- Control sensor "Hot Zone (Control)" = max(stone, IR), NaN if either is invalid.
- Day/night setpoints and schedule hours are number entities (persisted in flash). The active setpoint is pushed to the thermostat every 30 s and on any change. Time comes from SNTP, then Home Assistant; with no valid time, the day setpoint is used.
- Safety loop (250 ms): forces heat off on any fault, clears once readings are valid and below 90°F, and only heats while **Heater Enable** is on. The 92°F hard limit is fixed in firmware. It also drives the cutoff: PERMIT (GPIO25) follows "heat allowed", and HEARTBEAT (GPIO23) toggles at the end of each passing run.
- Plausibility checks latch heat off until **Clear Heater Fault** is pressed or the ESP32 restarts. Thresholds are substitutions at the top of the YAML.
- PERMIT, HEARTBEAT and the SSR are switched off before OTA and on shutdown.
- MLX emissivity set to 0.95 for stone.
- OLED shows Hot / Cool / RH / heater % / setpoint, shifts pixels every few minutes, and turns off during night hours.
- After autotune, paste the suggested `kp/ki/kd` from the logs into `control_parameters`.
- Full entity list: `ENTITIES.md`.

## Heater cutoff (watchdog relay)

A second, independent actuator in series with the SSR. Full component-level wiring: [`heater-cutoff-wiring.svg`](heater-cutoff-wiring.svg). Hole-by-hole layout for a half-size ElectroCookie board, with the K1 relay shield mounted separately: [`heater-cutoff-breadboard.svg`](heater-cutoff-breadboard.svg). The SSR still does all the regulating. K1 stays closed during normal operation and opens only on a fault.

```text
Fused L ──> K1 COM/NO ──> SSR ──> outlet ──> heat panel

GPIO25 PERMIT ────> U1 1/CLR ┐
GPIO23 HEARTBEAT ─> U1 1B    ├─> U1 1Q ──> relay shield IN (D1) ──> K1 coil
                   U1 1A=GND ┘         └─> divider ──> GPIO34 (feedback)
```

**How it works.** U1 is a retriggerable one-shot. Each rising edge on HEARTBEAT (every 500 ms) restarts a ~2.1 s timer, and its Q output, which drives K1, stays high while edges keep arriving. PERMIT is wired to the one-shot's clear input, so pulling it low drops Q immediately. So K1 is closed only when **PERMIT is high AND HEARTBEAT is toggling**:

| Condition | K1 |
|---|---|
| Power-up, reset, flashing, sensors not yet valid | Open (pull-downs hold PERMIT and HEARTBEAT low) |
| Healthy, Heater Enable on | Closed; SSR regulates |
| Any fault, including over 92°F with a shorted SSR | Opens at once (PERMIT low) |
| Heater Enable off | Opens |
| OTA update | Opens (PERMIT dropped in `on_begin`; timeout backs it up) |
| Loop stalls or the ESP32 hangs with pins stuck | Opens after ~2.1 s (heartbeat stops) |
| 5 V lost | Opens (coil unpowered) |
| Fault clears or power returns | Closes again on its own once the firmware allows heat. No button press |

**U1 (CD74HCT123E) connections**

| Pin | Name | Connect to |
|---|---|---|
| 1 | 1A | GND |
| 2 | 1B | HEARTBEAT (GPIO23), 10k to GND |
| 3 | 1/CLR | PERMIT (GPIO25), 10k to GND |
| 13 | 1Q | relay shield IN (D1 pin); 100k to GND; 10k to GPIO34 (GPIO34 has 20k to GND) |
| 14 | 1Cext | 4.7 µF film capacitor to pin 15 |
| 15 | 1Rext/Cext | 4.7 µF to pin 14; 1 MΩ to 5V |
| 16 | VCC | 5V, 100 nF to GND at the pin |
| 8 | GND | GND |
| 9, 10, 11 | 2A, 2B, 2/CLR | 9 to 5V; 10 and 11 to GND (unused channel held cleared) |
| 4, 5, 6, 7, 12 | | No connection |

**Relay shield.** Three wires: shield D1 pin ← U1 pin 13, shield 5V ← +5V, shield GND ← GND. The shield's own transistor, flyback diode and LED drive the coil. 100k from pin 13 to GND keeps the relay off if U1 is out of its socket. 100 µF across 5V/GND where the shield wires leave the board. Before wiring it, power the shield's 5V/GND and touch D1 to 5V: the relay should click and its LED light (some shields let you move the control pin with a solder jumper; it must be D1).

**Notes**
- Timeout ≈ 0.45 × R × C = 0.45 × 1 MΩ × 4.7 µF ≈ 2.1 s. Tolerance and capacitor leakage shift it, so measure it (see checklist). Use a film capacitor; a leaky electrolytic lengthens or breaks the timer.
- HCT (not HC) is required so the 3.3 V GPIO levels register at 5 V.
- U1 and K1 run from the ESP32's 5V/VIN pin. Many dev boards drop USB 5 V through a diode, so measure that pin with the relay energized; U1 needs at least 4.5 V.
- The feedback input (**Heat Cutoff Closed**) reports that U1 is commanding K1 closed. It cannot detect welded contacts.
- Latching is done in firmware, not hardware: plausibility faults stay latched until cleared, and the 92°F fault clears below 90°F.

**What it does not cover.** Both hot-zone sensors reading falsely low at the same time is caught only by the "not warming" check below, not by the hardware. A welded K1 together with a shorted SSR leaves the heater on. Firmware that keeps running but decides wrongly is not detected by the watchdog.

## Plausibility checks

The two hot-zone sensors measure the same stone, so they cross-check each other. Both checks latch heat off (and open K1) until **Clear Heater Fault** is pressed or the ESP32 restarts.

| Check | Trips when | Catches |
|---|---|---|
| Disagreement | \|stone − IR\| > 4°C (~7°F) for 10 min | Probe out of its groove, IR knocked off the stone, a failing sensor |
| Not warming | Heater duty ≥ 95% for 30 min without the hot zone rising 1°C (~2°F), **and** the hot zone is within 3°C (~5°F) of enclosure air | Both sensors no longer reading the stone; also a dead panel, blown fuse or K1 not closing |

The air comparison (SHT30, or the cool probe if the SHT30 fails) stops a panel that is simply maxed out in a cold room from tripping: the stone stays warm relative to the air even when it stops rising.

The thresholds (`disagree_c`, `disagree_min`, `no_rise_c`, `no_rise_min`, `near_air_c`) are substitutions at the top of the YAML. During bring-up, log stone and IR through a full day/night cycle, including warm-up from cold, and set the disagreement threshold comfortably above the largest normal gap.

## Home Assistant alerts

Home Assistant only notifies; the heater cutoff never depends on it. Suggested phone alerts:

1. **Heater Fault** on for more than a minute (includes the fault reason in `Heater Status`).
2. **Heat Cutoff Problem** on: heat is permitted but the cutoff is not closing (check 5 V, U1, K1).
3. **Status** offline for more than a few minutes.
4. **Cool Side Low** on.

Accepted trade-off: with the ZEN04 removed, there is no independent power measurement confirming that the panel is actually off. The "not warming" check and the hot-zone readings are the only evidence of what the panel is doing. A 4 ft gradient gives the snake room to retreat.

---

## Bring-up and test checklist

- [ ] Flash the ESP32 over USB; confirm the I2C scan in logs shows 0x3C, 0x44, 0x5A.
- [ ] Both DS18B20s read sensibly; compare to a reference thermometer.
- [ ] Unplug a probe: Heater Fault turns on and heater duty goes to 0.
- [ ] Multimeter: ground continuity from the plug's ground pin to the outlet ground (unplugged).
- [ ] Lamp in the outlet: ESP32 pulses it; lamp stays off during boot and flashing.
- [ ] Cutoff on the bench first (low-voltage load or meter on K1 COM/NO, no mains): K1 stays open at power-up, during flashing, and with GPIO23 or GPIO25 disconnected. It closes once sensors are valid and opens when Heater Enable is turned off.
- [ ] Measure the watchdog timeout: hold HEARTBEAT steady (stop the loop, or disconnect GPIO23) and time how long K1 takes to open. Expect ~2 s; it must stay under 3 s. Repeat warm, after the box has run for an hour.
- [ ] Measure the ESP32 5V/VIN pin with K1 energized: at least 4.5 V.
- [ ] Simulate a stuck-on SSR: jumper the SSR's AC terminals with the lamp connected, then warm the stone probe past 92°F. K1 must open and the lamp go out.
- [ ] Start an OTA update while heating: K1 opens before the upload starts.
- [ ] Unplug one hot-zone sensor while heating (fault in < 60 s), and pull the stone probe out of its groove (disagreement fault after ~10 min). Press **Clear Heater Fault** and confirm heat resumes.
- [ ] Heat Cutoff Closed follows K1, and Heat Cutoff Problem turns on if U1 is removed from its socket while heat is permitted.
- [ ] No nuisance trips over 24 h of normal running with the display, Wi-Fi and sensors active.
- [ ] RHP connected: run autotune with the stone installed (1–2 hr), update PID values, then watch a full day/night cycle, including the night setpoint switch.
- [ ] Cool side holds ≥ 72°F in the enclosure's room for a week before the animal moves in.
- [ ] Transfer from breadboard to the ElectroCookie protoboard for permanent install.

## Open items

- [ ] Home Assistant notification automations (see "Home Assistant alerts")
- [ ] Confirm Wi-Fi reaches the enclosure location
- [ ] Tune the plausibility thresholds from a logged day/night cycle
