# Custom carrier PCB: plan (option 1, bare board, self-soldered)

A low-voltage-only carrier board that replaces the CircuitSetup protoboard and its hand wiring. The ESP32-DevKitC plugs into female headers; everything else lands on labelled screw terminals. Mains (relay shield, SSR, C14, outlet) stays off this board, in the mains bay, exactly as in `BUILD.md`.

Source of truth for every connection: `diagrams/circuit.json` (including the two soil moisture probes on GPIO34/35). The board adds no new nets except optional pull-ups and filter caps (below).

## 1. What goes on the board

| Ref | Part | Net / pins | Notes |
|---|---|---|---|
| U1 | 2× 1×19 female header, 2.54 mm, rows 22.86 mm (0.9") apart | ESP32-DevKitC 38-pin | Same spacing as the dry-fit (rows a and i). USB end at the board edge, facing the enclosure's USB opening. |
| R1 | 10k, 1/4 W axial | GPIO19 → GND | SSR off at boot (as today) |
| R2 | 10k, 1/4 W axial | GPIO18 → GND | Relay off at boot (as today) |
| R3 | 4.7k, 1/4 W axial | GPIO4 → 3V3 | Stone DS18B20 pull-up. **Fit only if the probe wires straight to J1**; leave empty if you keep the DROK adapter board (it has its own 4.7k). |
| R4 | 4.7k, 1/4 W axial | GPIO16 → 3V3 | Cool DS18B20 pull-up, same rule as R3 |
| R5, R6 | 4.7k, 1/4 W axial (normally **not fitted**) | SDA/SCL → 3V3 | Spare I2C pull-ups. The OLED and GY-906 boards already have them; fit only if the I2C scan fails. |
| C2 | 10 µF, 2.54 mm lead pitch (optional) | 3V3 → GND | Bulk cap near the sensor terminals |
| J1 | 3-pos screw terminal, 3.5 mm | 3V3 · GPIO4 · GND | Stone DS18B20 (red · yellow · black) |
| J2 | 3-pos screw terminal, 3.5 mm | 3V3 · GPIO16 · GND | Cool DS18B20 |
| J3 | 4-pos screw terminal, 3.5 mm | 3V3 · GND · SDA · SCL | SHT30 probe |
| J4 | RJ45 8P8C jack, through-hole, unshielded | T568B map from `BUILD.md`: 2 = SDA, 6 = SCL, 4 = 3V3, 1/3/5/7/8 = GND | Cat6 to the GY-906. C1 (100 nF) stays at the sensor end. |
| J5 | 1×4 male header, 2.54 mm | GND · VCC(3V3) · SCL · SDA | OLED, in the OLED's own pin order, so a straight 4-wire Dupont cable works |
| J6 | 2-pos screw terminal, 3.5 mm | GPIO19 (+) · GND (−) | SSR input terminals 3 (+) and 4 (−) |
| J7 | 3-pos screw terminal, 3.5 mm | 5V · GND · GPIO18 | Relay shield 5V · GND · D1 |
| J8 | 3-pos screw terminal, 3.5 mm | 3V3 · GPIO34 · GND | Soil moisture 1 (cool side), capacitive analog probe |
| J9 | 3-pos screw terminal, 3.5 mm | 3V3 · GPIO35 · GND | Soil moisture 2 (warm side) |
| C3, C4 | 100 nF ceramic, 2.54 mm (optional) | GPIO34 → GND, GPIO35 → GND | Smooths the analog soil readings; fit right at J8/J9 |
| H1–H4 | M3 mounting holes, 3.2 mm | GND-free (isolated) | Same 87 × 47.7 mm pattern as the CircuitSetup board, so the enclosure standoffs don't change |

Power stays as it is now: USB into the ESP32. 5V reaches J7 from the DevKit's 5V/VIN pin.

## 2. Board rules

- **Size:** 95 × 56 mm (same footprint as the CircuitSetup board, so the enclosure model is unchanged). 2 layers, 1.6 mm FR-4, 1 oz copper.
- **Layout:** the ESP32 runs along the USB edge. All screw terminals sit along the back edge, toward the grommets: J1, J2, J3, J8 and J9 together, then J4 (RJ45), then J6 and J7 at the divider end so the SSR and relay wires take the shortest path to the floor notch. J5 (OLED) sits on the front edge, toward the OLED.
- **Traces:** 0.3 mm for signals and 0.6 mm for 3V3, 5V and GND, with a ground pour on both layers. I2C runs SDA and SCL side by side over solid ground. Keep the GPIO34/35 analog traces short and away from the 5V relay line.
- **Antenna:** the WROOM-32**U** in your photo uses an external antenna on its u.FL connector, so the board needs no copper keep-out under it. You do need a u.FL-to-SMA pigtail with a small antenna; route it out of the enclosure or tape it to the lid, because the box walls and the mains wiring shield it. (A WROOM-32**D/E** with a PCB antenna would need a keep-out instead, and the antenna end hanging past the board edge.)
- **Silkscreen:** label every terminal pin with net name and wire colour. Mark "LOW VOLTAGE ONLY, NO MAINS", plus the R3/R4 and R5/R6 fit rules.
- **Checks before ordering:** compare the KiCad netlist against `diagrams/circuit.json`, pass DRC with JLCPCB's default rules, and print a 1:1 copy on paper to dry-fit the headers, terminals and standoff holes.

## 3. How the design gets made

1. **Schematic + netlist** in KiCad, built from `circuit.json` (plus R3–R6, C2).
2. **Placement:** fixed positions for the headers, terminals and holes from section 2.
3. **Routing:** autorouted with Freerouting, then cleaned up by hand. The board is simple, with about 10 nets.
4. **DRC + netlist check** against `circuit.json`.
5. **Outputs** in `pcb/`: the KiCad project, `gerbers.zip` (copper, mask, silk, outline, drill), the BOM, and a 3D render PNG.

## 4. Where to view it

| What | Where |
|---|---|
| KiCad project | **KiCad** (free, kicad.org) on your computer: open `pcb/*.kicad_pro`; the 3D viewer is under View → 3D Viewer |
| In a browser, no install | **KiCanvas** (kicanvas.org): paste the GitHub URL of the `.kicad_pcb` file once it's pushed |
| Gerbers | **Upload preview at JLCPCB** (shows both sides before you pay), or **tracespace.io** |

## 5. Where to order

| Fab | Cost for this board (approx.) | Notes |
|---|---|---|
| **JLCPCB** (jlcpcb.com) | ~$2–5 for 5 boards + $15–30 shipping. Tariffs/duties may add. | Upload `gerbers.zip` → keep defaults (2 layers, 1.6 mm, HASL lead-free, 5 pcs) → pick a colour → checkout. Ships from China in ~1–2 weeks. |
| **PCBWay** (pcbway.com) | Similar to JLCPCB | Same upload flow |
| **OSH Park** (oshpark.com) | ~$41 for 3 boards ($5/sq in × 8.25 sq in), free US shipping | Made in the US, no import duties, purple boards, ~2 weeks. Accepts the `.kicad_pcb` file directly. |

### Parts to buy (to solder yourself)

| Qty | Part |
|---|---|
| 2 | 1×19 female header, 2.54 mm (or cut from 1×40 strips) |
| 1 | 1×4 male header, 2.54 mm |
| 5 | 3-pos screw terminal, 3.5 mm pitch |
| 1 | 4-pos screw terminal, 3.5 mm pitch |
| 1 | 2-pos screw terminal, 3.5 mm pitch |
| 1 | RJ45 8P8C through-hole jack (unshielded, no LEDs) |
| 2 | 10k 1/4 W (you have these) |
| 2–4 | 4.7k 1/4 W |
| 1 | 10 µF electrolytic or ceramic (optional) |
| 2 | 100 nF ceramic (optional, soil inputs) |
| 1 | u.FL → SMA pigtail + 2.4 GHz antenna (for the WROOM-32U) |

Order the exact terminal and jack part numbers from the BOM in step 5, so their footprints match the board.

## 6. Open decisions

1. **DS18B20 wiring:** probes straight to J1/J2 with on-board R3/R4 (fewer parts), or keep the DROK adapter boards (leave R3/R4 empty)?
2. **Screw terminals vs plugs:** plain 3.5 mm screw terminals (default), or pluggable terminal blocks so each sensor unplugs without a screwdriver (a few dollars more)?
3. **OLED connection:** a 4-pin header and Dupont cable (default), or a screw terminal like the sensors?
4. **Antenna:** confirm the DevKit is the WROOM-32U, with the u.FL connector seen in the photo.
