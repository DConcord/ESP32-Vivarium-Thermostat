---
name: schematic-svg
description: Draw clear, colour-coded schematic / wiring-diagram SVGs for electronics projects (microcontrollers like ESP32, Arduino and Pico, sensors, relays, ICs, power and mains wiring), machine-checked against a shared circuit file so the drawing provably connects what the circuit says. Use this whenever someone wants a schematic, wiring diagram, hookup diagram, "how do I connect X to Y" picture, or a component-level drawing of a board, or wants to document or review a circuit visually, even if they don't say "SVG". It pairs with breadboard-layout-svg, and both read the same circuit.json, so schematics and breadboard layouts stay in sync.
---

# Schematic SVGs

You produce a schematic a hobbyist can build from: every part and pin labelled,
colour-coded signal wires, power/ground as tags instead of long wires, a legend,
a parts table that says how to identify each part, and a checklist of what to
verify before power-up. Two files drive it:

- **circuit.json**: the parts and the nets (which pins are connected). It's the
  single source of truth, shared with the `breadboard-layout-svg` skill.
  Format: `references/circuit.md`.
- **sheet.json**: where each symbol, wire and tag is drawn. Format:
  `references/sheet.md`.

`scripts/schsvg.py sheet.json out.svg` checks the drawing against the circuit
file and only renders if they match. That check is the point. It caught a
capacitor drawn the wrong way round on the very first real sheet. Don't
hand-write SVG.

## Workflow

1. **Write or update circuit.json first.** Get the nets right from the user's
   design, firmware pin map, or datasheets. If the project already has one (for
   example from a breadboard layout), reuse it; never fork a second copy. Off-board
   devices (sensors, SSRs, a header on another board) are parts too.
2. **Plan the sheet on a 10 px grid.** Typical layout: controller block on the
   left, the main IC centre-left, signal flowing left→right, outputs and
   actuators right, mains in a separate red panel at the far right. Give each
   panel its own region.
3. **Draw with as few long wires as possible.** Wire signals between nearby pins
   (that's what makes a schematic readable). Use **tags** for power, ground and
   any net that would otherwise cross the page or the sheet (a bus like SDA/SCL,
   or a signal going to another board). A dense schematic full of crossing wires
   is worse than one with more tags.
4. **Check:** `python scripts/schsvg.py sheet.json out.svg --check-only`.
   - `ERROR` = the drawing and the circuit disagree. Decide which one is wrong
     (sometimes it really is the circuit file) and fix that one.
   - `WARNING` = readability problems (crossings, loose ends, pins going nowhere).
     Fix them unless there's a reason not to.
5. **Render and look:** `python scripts/schsvg.py sheet.json out.svg`, then
   screenshot with `python <breadboard-layout-svg>/scripts/preview.py out.svg out.png`
   (or any headless Chrome) and view it. Zoom into dense spots
   (`--zoom X Y W H`). Look for text running into lines, labels on top of other
   labels, a symbol hiding a wire. The checker can't see those, and users notice them.
6. **Deliver** the SVG plus the sheet and circuit files so it can be edited later.

## Drawing guidance

- **Labels carry the build information.** Pin numbers and names on ICs, GPIO
  names on wires ("GPIO25 · PERMIT"), values beside every passive, polarity
  marks. The parts table (generated from `type`/`identify`/`connects` in the
  circuit file) tells a builder how to find each part in their parts bin.
- **Consistent colour per net** (set in `net_styles`), and reuse the same
  colours in the breadboard layout so the two drawings read as a pair.
- **Unused pins:** leave them out of every net; mark IC pins with `nc` so the
  builder knows they're intentionally empty. Unused module pins draw grey
  automatically.
- **Mains:** draw it in a `"style": "mains"` panel, with the relay's coil and its
  contacts as separate symbols (a block for the coil side, a `switch` for COM/NO/NC)
  joined by a dashed `decor` line, so the isolation boundary is obvious.
- **Modules on the sheet** (ESP32, relay shields): a `block` with every pin in
  silkscreen order, so the drawing matches the physical board when someone
  holds it next to the page.
- **Checklist:** include the mistakes that destroy parts or create hazards:
  IC orientation, diode/electrolytic polarity, live metal tabs, supply voltage
  under load, testing relay contacts before mains.

## Example

`examples/` holds a complete project: `thermostat-circuit.json` (two boards, external
devices and the mains path) with `heater-cutoff-schematic.json` (an IC
watchdog, timing parts, divider, relay module, mains panel) and
`esp32-schematic.json` (a 38-pin module with buses as tags and six
peripheral blocks). Copy the structure that fits the user's circuit.
