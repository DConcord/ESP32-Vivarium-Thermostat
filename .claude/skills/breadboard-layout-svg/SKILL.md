---
name: breadboard-layout-svg
description: Design hole-by-hole layouts for solderable breadboards (ElectroCookie-style, or any board wired like a plain breadboard with a–e / f–j column strips and four power rails) and render them as a clear, illustrated SVG with a build list, after machine-checking every connection against the circuit's netlist. Use this whenever someone wants to move a circuit, schematic, or wiring diagram onto a solderable breadboard, perfboard-style strip board, or protoboard; asks "what would this look like on a breadboard", "which holes do the parts go in", or "can this fit on a half-size board"; or wants a build/assembly diagram for an ESP32, Arduino, Raspberry Pi Pico, relay, sensor or IC circuit, even if they never say "SVG" or "layout".
---

# Breadboard layout SVGs

You turn a circuit into a picture of a real solderable breadboard: every part in
specific holes, colour-coded jumpers, labelled off-board wires, and a step-by-step
build list underneath. The picture is only worth something if it is **electrically
right** and **unambiguous to a hobbyist holding a soldering iron**, so the workflow is
built around two checks: a netlist check (does the layout connect exactly what the
schematic connects?) and a visual check (could anything be misread?).

Everything is driven by a JSON spec rendered by `scripts/bbsvg.py`. Don't hand-draw
SVG: the script owns the board drawing, part artwork, build list and all checks, so
your effort goes into placement decisions.

## Workflow

1. **Pin down the circuit as a netlist.** List every net and the part pins on it
   (`"GND": ["U1.p8", "R2.2", "J1.GND", ...]`). Take it from the user's schematic,
   firmware pin map, or your own design; if you're unsure what a pin does, ask
   rather than guess. Unused IC pins each get their own one-pin net so the checker
   proves they stay unconnected.
2. **Pin down the hardware.** Board size (half-size ElectroCookie = 30 columns),
   what each rail carries, and the exact modules involved. For dev boards, get the
   pin order from the silkscreen (a photo is ideal) and the row spacing in holes:
   measure it or derive it from pitch. The row spacing decides which rows the module
   can occupy, and getting it wrong invalidates the whole layout.
3. **Place parts** in a spec (format below; full reference in
   `references/spec.md`; worked examples in `examples/`). Follow the placement rules
   in the next section.
4. **Check:** `python scripts/bbsvg.py layout.json out.svg --check-only`.
   `NETLIST FAIL` means the layout is wrong: fix it. Treat every `WARNING` as a
   probable defect too (a lead passing over an occupied hole looks like a connection
   even when it isn't; crossings and label overlaps confuse builders). Iterate until
   it prints `NETLIST OK` with no warnings, or with only warnings you've decided are
   acceptable and can explain.
5. **Render and look at it.** `python scripts/bbsvg.py layout.json out.svg`, then
   `python scripts/preview.py out.svg out.png`, and view the PNG. Also zoom into busy
   regions: `python scripts/preview.py out.svg zoom.png --zoom X Y W H` (SVG pixel
   coordinates). The automated checks don't see everything. Users notice things like
   "why does this red wire go to that orange dot?", and those come from two parts
   drawn on top of each other. Fix such cases by moving parts, not by explaining them.
6. **Deliver** the SVG (and the spec, so it can be edited later). Summarise the
   placement decisions that aren't obvious from the picture: why a part sits off the
   board, which wires go in before a module is mounted, anything to verify on the
   real parts (rail hole positions, module pinouts).

If the user also wants a schematic-style wiring diagram, draw that separately; this
skill covers the physical layout. Use the same reference designators in both.

## Placement rules (the lessons behind them)

- **Strips are the wiring.** Every hole in a–e of one column is one node; same for
  f–j. An IC straddling the centre gap gives each pin its own strip with four free
  holes, which is why DIPs go across the gap with the notch toward column 1.
- **One thing per hole.** The checker enforces this.
- **Nothing drawn over an occupied hole.** A jumper or lead that passes over another
  joint looks connected. Re-route, or move the joint. When two parts compete for a
  spot, there is usually an electrically identical alternative. For example, a
  decoupling cap can sit straight across two adjacent rails right next to the IC.
- **No crossing wires** where you can avoid them. Order nested routes (outermost
  horizontal run goes furthest out and ends highest) so they don't cross.
- **Off-board wires exit straight up/down/left/right in their own lane.** A wire from
  a T− rail hole passes over the T+ hole in the same column, so keep that hole empty
  (the checker warns if you don't).
- **Raised modules (dev boards on female headers):** the two header strips are walls
  on the board surface. Holes between them are usable but must be soldered *before*
  the module is plugged in. Wires there can only leave through the open ends of that
  channel, past the first or last header pin. Mark such parts/jumpers `under_module`
  / `"under": true` so they draw dashed and are listed first in the build order. When
  one header row has no free outside holes, plan its escapes deliberately.
- **Module pins that are internally joined** (an ESP32's several GND pins) go in
  `internal_ties`, so the netlist check knows about connections made inside the module.
- **Metal tabs are live.** A TO-220 tab is usually the drain/collector. Point it
  toward empty space and keep other nets' leads away from it.
- **Mains never goes on the breadboard.** Relays switching mains, and relay modules
  or shields with screw terminals, mount separately (≥ 6 mm from low-voltage copper)
  and connect with a few low-voltage wires drawn as `offboard`. Don't plug a relay
  shield onto the board, even if it fits. Also check whether a shield is driven
  directly by a microcontroller pin, which might bypass a safety circuit or clash
  with a bus pin.
- **Real part sizes matter.** Film capacitors often have 5 mm (2-hole) or wider lead
  spacing; electrolytics sit across adjacent rails nicely; ¼ W resistors span ~4
  holes flat, or stand up for 1–2 holes. If a part can't reach its pins, add a short
  jumper rather than pretending it fits.
- **Rail holes are approximate** on real boards (often grouped in fives). Say so in
  the notes so builders use the nearest hole in that column.

## Spec at a glance

```json
{
  "title": "...", "subtitle": "...",
  "board": {"cols": 30},
  "rails": {"T+": {"label": "+5V"}, "T-": {"label": "GND"}, "B-": {"label": "GND"}, "B+": {"label": "+5V"}},
  "colors": {"hb": "#D97706"},
  "devices": {"OLED": {"name": "SH1106 OLED", "color": "#7C3AED"}},
  "parts": [
    {"ref": "U1", "kind": "dip", "pin_count": 16, "col": 9, "value": "CD74HCT123E"},
    {"ref": "R1", "kind": "resistor", "value": "10k", "pins": {"1": "j10", "2": "B-@10"}},
    {"ref": "ESP", "kind": "module", "rows": [{"row": "a", "start_col": 19, "step": -1, "names": ["3V3", "EN", "..."]}]}
  ],
  "jumpers": [{"from": "a9", "to": "T+@8", "color": "5v"}],
  "offboard": [{"device": "OLED", "signal": "SDA", "hole": "j23", "dir": "down"}],
  "internal_ties": [["ESP.GND", "ESP.GND_2"]],
  "expected_nets": {"5V": ["U1.p16", "R3.2", "..."]},
  "notes": ["..."]
}
```

Holes: `"e9"` (row e, column 9) or `"T+@8"` (rail T+, at column 8). Part kinds:
`resistor` (colour bands drawn from `value`), `cap`, `film`, `elec` (pins `+`/`-`),
`diode` (pins `A`/`K`), `to220` (any 3 pin names, `tab`), `header`, `dip` (auto pins
`p1..pN`), `module` (named pin rows; duplicate names become `GND`, `GND_2`, …).
Netlist names are `REF.PIN` for parts and `DEVICE.SIGNAL` for off-board wires.
Optional per-part `label_at` (`[dx, dy]` px or a hole) moves the reference label,
and `note` adds a build-list note. Read `references/spec.md` for every field.

## Examples

- `examples/watchdog-cutoff.json`: a DIP one-shot with pull-downs, timing parts,
  a divider straddling the gap, and a relay shield wired off-board.
- `examples/esp32-devkitc-main.json`: a 38-pin ESP32 on female headers with
  under-module jumpers, bus columns for I2C, and ~25 labelled off-board wires.

Start from whichever is closer to the user's circuit.
