# Custom carrier PCB: plan (fully assembled, zero soldering)

> The earlier solder-it-yourself version of this plan is kept in `PLAN-self-solder.md`.

A low-voltage carrier board that replaces the CircuitSetup protoboard and all its hand wiring. The board arrives from the factory **with every part already soldered**. You plug the ESP32-DevKitC into its headers, push the OLED cable on, and screw each sensor's wires into a plug. No soldering iron.

Mains (relay shield, SSR, inlet, outlet) stays off this board, in the mains bay, exactly as in `BUILD.md`. The firmware doesn't change: every GPIO stays the same.

Source of truth for every connection: `diagrams/circuit.json` (including the two soil probes on GPIO34/35). The board adds no new nets, only the pull-up resistors and filter capacitors listed below.

## 1. How the ESP32 is attached

| Option | What it is | Verdict |
|---|---|---|
| **A. DevKit on factory-soldered female headers** | The factory solders two 1×19 female headers. Your ESP32-DevKitC (WROOM-32U) plugs straight in. | **Recommended.** It's the board you already have and have dry-fitted. If it ever dies, a new $10 DevKit plugs in. USB, the reset/boot buttons and the antenna connector all stay as they are. |
| B. Bare ESP32 module soldered onto the board | The factory solders an ESP32-WROOM-32UE module plus its own USB-C, USB-serial chip, regulator and auto-reset circuit. | Neater, but it's a whole dev board designed from scratch. More can go wrong on a first revision, and a dead module means a dead board. Worth it only for a round 3. |

The rest of this plan assumes **A**.

## 2. Connectors: pluggable terminal blocks

Every sensor lands on a **pluggable terminal block** (3.81 mm pitch). The factory solders the socket half to the board. The plug half is loose: you clamp each wire in it with a small screwdriver, then push the plug into its socket. That means:
- No soldering, and no crimping.
- Any sensor unplugs in a second without touching its wires, for example to lift the board out or swap a probe.
- Plugs are keyed by pin count, and every socket is labelled, so it's hard to plug the wrong sensor in.

The IR sensor keeps its Cat6 run, so it gets a real **RJ45 jack**. The OLED keeps a **4-pin header** for the Dupont cable it already uses.

## 3. What goes on the board

Everything is soldered by the factory. Small parts are surface-mount on the top side only. The connectors and headers are through-hole.

| Ref | Part | Net / pins | Notes |
|---|---|---|---|
| U1 | 2× 1×19 female header, 2.54 mm, rows 22.86 mm (0.9") apart | ESP32-DevKitC 38-pin | Spacing confirmed by the dry-fit. USB end toward the enclosure's +X wall, at the same spot as now, so the right-angle USB cable path doesn't change. |
| R1 | 10k | GPIO19 → GND | SSR off at boot |
| R2 | 10k | GPIO18 → GND | Relay off at boot |
| R3 | 4.7k | GPIO4 → 3V3 | Stone DS18B20 pull-up. The probe wires go straight to J1, so the DROK adapter boards aren't needed. |
| R4 | 4.7k | GPIO16 → 3V3 | Cool DS18B20 pull-up |
| R5, R6 | 4.7k, **pads only (not fitted)** | SDA/SCL → 3V3 | Spare I2C pull-ups. The OLED and GY-906 boards already have theirs. |
| C1 | 10 µF | 3V3 → GND | Bulk capacitor by the sensor connectors |
| C2–C5 | 100 nF | 3V3 → GND at J1, J2, J3, J4 | Local decoupling at each sensor connector |
| C6, C7 | 100 nF | GPIO34 → GND, GPIO35 → GND | Smooths the analog soil readings |
| D1 | Green LED + 1k | 3V3 → GND | Power indicator |
| J1 | 3-pin pluggable terminal | 3V3 · GPIO4 · GND | Stone DS18B20: red · yellow · black |
| J2 | 3-pin pluggable terminal | 3V3 · GPIO16 · GND | Cool DS18B20: red · yellow · black |
| J3 | 4-pin pluggable terminal | 3V3 · GND · SDA · SCL | SHT30 probe |
| J4 | RJ45 8P8C jack, unshielded, no LEDs | T568B: 2 = SDA, 6 = SCL, 4 = 3V3, 1/3/5/7/8 = GND | Cat6 to the GY-906. The 100 nF capacitor stays at the sensor end, as now. |
| J5 | 1×4 male header, 2.54 mm | GND · VCC (3V3) · SCL · SDA | OLED, in the OLED's own pin order, so a straight 4-wire Dupont cable fits |
| J6 | 2-pin pluggable terminal | GPIO19 (+) · GND (−) | SSR input terminals 3 (+) and 4 (−) |
| J7 | 3-pin pluggable terminal | 5V · GND · GPIO18 | Relay shield 5V · GND · D1 |
| J8 | 3-pin pluggable terminal | 3V3 · GPIO34 · GND | Soil probe 1 (cool side) |
| J9 | 3-pin pluggable terminal | 3V3 · GPIO35 · GND | Soil probe 2 (warm side) |
| H1–H4 | M3 mounting holes, 3.2 mm | Isolated | **87.5 × 48.5 mm** pattern, as measured on the CircuitSetup board, so the enclosure's standoffs fit unchanged |
| TP1–TP4 | Test pads | 3V3, 5V, GND, SDA | For a meter probe while troubleshooting |

Power stays as it is now: USB into the DevKit. J7 gets 5V from the DevKit's 5V/VIN pin. Only the relay coil uses 5V; everything else is 3.3V.

## 4. Board layout

- **Size:** 95 × 56 mm, the same footprint as the CircuitSetup board, so the enclosure needs no changes. 2 layers, 1.6 mm FR-4, 1 oz copper.
- **Back edge (toward the grommets):** J1, J2, J3, J8 and J9 side by side, then J4 (RJ45). The sensor cables come through the grommets straight into their connectors.
- **Divider end:** J6 and J7, so the SSR and relay wires take the shortest path to the divider's floor notch.
- **Front edge (toward the OLED):** J5.
- **Underside:** only the short through-hole leads of the connectors, well under the 9 mm standoff height.
- **Traces:** 0.3 mm for signals, 0.6 mm for 3V3, 5V and GND, with a ground pour on both layers. SDA and SCL run side by side over solid ground. The GPIO34/35 analog traces stay short and away from the relay line.
- **Antenna:** the WROOM-32**U** has no antenna of its own; it uses its u.FL connector. Keep the small antenna on its pigtail fitted, as now.
- **Silkscreen:** every terminal pin labelled with its net and the wire colour. Plus "LOW VOLTAGE ONLY, NO MAINS", the board name and the revision.

## 5. What I produce

All in `pcb/`, from KiCad (it can be installed in this session):

1. **Schematic**, generated from `circuit.json`, plus the parts in section 3.
2. **Board layout** with the fixed positions from section 4, autorouted with Freerouting, then cleaned up.
3. **Checks:**
   - Design-rule check against JLCPCB's rules.
   - The board's netlist compared against `circuit.json`, so every connection is proven to match the diagrams.
   - A 1:1 PDF to print on paper and lay over the enclosure, to check hole positions before ordering.
4. **Order files:**
   - `gerbers.zip`: copper, mask, silkscreen, outline and drill files.
   - `bom.csv`: every part with its LCSC part number, so the factory stocks it.
   - `cpl.csv`: where each part sits on the board.
5. **A 3D render** of the assembled board, plus a mockup of it in the enclosure.

## 6. How you order it (JLCPCB)

1. Upload `gerbers.zip` at jlcpcb.com. Keep the defaults: 2 layers, 1.6 mm, lead-free HASL, quantity 5. Pick a colour.
2. Turn on **PCB Assembly**. Choose **Standard** assembly, because the connectors are through-hole. Assemble **2** boards, which gives you a spare.
3. Upload `bom.csv` and `cpl.csv`, then check the parts preview. Every part should show on the board where the render shows it.
4. In the same order, add the **loose plug halves** for the terminal blocks from LCSC (listed in the BOM). Plugs need no soldering, so they ship loose with the boards.
5. Pay, and wait about 1–2 weeks for build and shipping.

**Rough cost:** about $60–110 for 2 assembled boards, plus $20–35 shipping, plus any import duties. Most of that is fixed setup and part-loading fees, so 2 boards cost about the same as 1. The quote page shows the exact price before you pay.

## 7. When it arrives

1. Screw the board onto the existing standoffs with the 4 M3 self-tapping screws you have now.
2. Plug the DevKit into U1, USB end toward the side wall.
3. Wire each sensor into its plug, following the silkscreen, and push the plugs in:

| Plug | Wires |
|---|---|
| J1 / J2 (DS18B20) | red → 3V3, yellow → DATA, black → GND. Wire the probe directly; the DROK adapters aren't needed. |
| J3 (SHT30) | red → 3V3, black → GND, then SDA and SCL as the listing says |
| J4 (RJ45) | The existing Cat6 cable plugs straight in |
| J5 (OLED) | The existing 4-wire Dupont cable |
| J6 (SSR) | GPIO19 (+) → SSR 3, GND (−) → SSR 4 |
| J7 (relay) | 5V, GND and D1 → the relay shield's 5V, GND and D1 pins. Cut one end off your existing Dupont jumpers and clamp the bare ends in the plug. |
| J8 / J9 (soil probes) | VCC → 3V3, AOUT → signal, GND → GND |

4. Power up over USB. The power LED lights, and the firmware runs unchanged.

## 8. Open decisions

1. **Soil probe cables:** check the probe end of your soil probe cables. Many capacitive probes come with a small 3-pin JST-PH plug. If yours do, I can put matching JST-PH sockets on the board so the probe cables plug straight in, with no stripping at all.
2. **Relay connection:** cut the Dupont jumpers and clamp the bare ends in J7 (default), or use a 3-pin male header so the jumpers plug in unchanged?
3. **Assembled quantity:** 2 boards (default), or 1 to save a little?
