# Sheet spec reference

A sheet says where things are drawn. Connectivity comes from the circuit file
(`references/circuit.md`), and the checker proves the drawing matches it.

## Contents
- Top level
- Symbols
- Wires
- Tags
- Decoration, panels, text
- Tables
- Checker messages

## Top level

| Field | Meaning |
|---|---|
| `circuit` | Path to the circuit file, relative to the sheet |
| `title`, `subtitle` | Heading; subtitle may be a list of lines |
| `canvas.w` | Width in px (height is automatic) |
| `symbols` | Parts to draw |
| `wires` | Orthogonal polylines between pins/points |
| `tags` | Net labels (+5V, GND, SDA...) attached to pins or points |
| `nc` | Pins to mark with an ✕ (must not be in any net) |
| `panels`, `decor`, `texts` | Non-electrical regions, shapes and notes |
| `parts_table` | List of refs in table order (`[]` = no table); default = drawn order |
| `parts_table_exclude` | Refs to leave out |
| `checklist`, `checklist_title` | Right-hand panel of check items |
| `notes` | Grey lines under the tables |
| `colors` | Extra named colours |

Coordinates are SVG px, y down. Snap to a 10 px grid. Pins must sit exactly
on wire ends or wire segments to connect.

## Symbols

All have `ref` (a part in the circuit file; the same ref may appear on several
symbols for multi-part devices, such as a relay's coil block and its contact switch).

**Two-pin** (`resistor`, `cap`, `film`, `elec`, `diode`): `at` = first pin,
`dir` = `down|up|left|right`, `len` (default 80 resistor, 60 others). Pins are
`1`/`2`, or `+`/`-` (elec), or `A`/`K` (diode). The first pin is at `at`. `value`
overrides the printed value; `label_side` (`right|left|above|below`) or
`label_at` [x, y] places the ref/value text.

**nmos**: `at` = gate pin; D is 60 right / 60 up, S is 60 right / 60 down
(`mirror: true` flips left). Optional `sub` lines.

**switch** (relay contacts): `at` = COM; NO at (+80, −30), NC at (+80, +35).
`mirror`, `closed`.

**block** (ICs, modules, connectors, devices): `at` = top-left of the box,
`w`, optional `h`; `left`/`right`/`top`/`bottom` = lists of pin names. Each
entry is a pin name, `null` (gap), or `{"pin": "FB", "y": 36}` (left/right)
/ `{"pin": "L", "x": 20}` (top/bottom) for exact offsets from the box edge.
Evenly spaced entries use `pad_top` (30) + i × `pitch` (40); top/bottom use
`pad_left` (40). Stubs are `stub` px long (20); the pin point is the stub's
outer end. `style`: `ic` (pin numbers + names, notch, title under the box),
`module` (dark, used pins highlighted), `device`, `grey`, `blue`, `amber`,
`purple`, `red`, `pink`. `title`, `sub`, `title_y`, `title_rotate` (e.g. -90
for a tall narrow module), `labels` {pin: text} (on top of the circuit's
`pin_names`), `numbers`, `hide_pin_labels`. Pins not in any net draw grey.

## Wires

`{"from": "U1.p13", "to": "K1.IN", "via": [[770, 540], [770, 700]],
"label": "1Q = RELAY ON", "label_at": [735, 432], "color": "...", "w": 3,
"dash": false}`. `from`/`to` are pins or [x, y]. Colour defaults to the net's
style. Keep segments horizontal/vertical (diagonals warn).

Connection rules (standard schematic convention):
- a wire end on a pin, on another wire's end, or on another wire's segment joins them
- a pin touching a wire's middle joins it (T-junction)
- two pins drawn at the same point are joined
- dots are drawn automatically at T-junctions and wherever 3+ things meet
- wires that cross without an end at the crossing are *not* joined (and warn,
  because crossings are hard to read)

## Tags

`{"pin": "R1.2", "net": "GND", "side": "down", "len": 0}` or
`{"at": [800, 320], "net": "+5V", "side": "right"}` (on a wire end).
`side` is where the pill sits; `len` draws a stub first (default 20 on pins).
All tags with the same net name are one connection, and the name must be a net
in the circuit file that the pin really belongs to.

## Decoration, panels, text

- `panels`: `{"rect": [x, y, w, h], "label": "...", "sub": [...], "style": "mains"}`
  (mains = red dashed).
- `decor`: `{"line": [[x, y], ...], "color", "w", "dash"}`,
  `{"rect": [x, y, w, h], "fill", "stroke", "rx", "dash", "opacity"}`,
  `{"circle": [cx, cy, r], "fill", "stroke"}`; add `"front": true` to draw it
  over the symbols (e.g. the RF module drawn on a dev board). Decor never
  affects connectivity: use it for mechanical links, antennas, cables to
  things that aren't parts.
- `texts`: `{"at": [x, y], "text", "size", "color", "anchor", "weight"}`.

## Tables

Under the drawing: wire-colour legend (nets drawn with wires, deduplicated by
colour + label), tag legend, parts table from the circuit file, and checklist.

## Checker messages

`ERROR` (exit 1): a net SPLIT in the drawing (its pins aren't all joined), a net
SHORTED to pins of another net, tags of two nets joined, a tag naming an
unknown net or placed on a pin of a different net, an NC pin that belongs to a
net, an unknown pin reference.
`WARNING`: loose wire ends, unattached tags, wire crossings, diagonal segments,
a pin drawn but going nowhere when its net continues elsewhere (tag or wire it).
