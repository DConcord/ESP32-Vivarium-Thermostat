# Layout spec reference

The spec is one JSON object, rendered by `scripts/bbsvg.py`.

## Contents
- Top-level fields
- Holes
- Parts (by kind)
- Jumpers
- Off-board wires
- Netlist: expected_nets and internal_ties
- What the checker reports

## Top-level fields

| Field | Type | Meaning |
|---|---|---|
| `circuit` | path | Shared circuit file (see `circuit.md`); its nets, restricted to pins on this board, become the expected netlist, and its parts' `internal_ties` apply |
| `board_id` | string | With `circuit`: warn about circuit parts whose `board` equals this but aren't placed |
| `title` | string | Heading at the top of the drawing |
| `subtitle` | string or list of strings | Grey lines under the title |
| `board.cols` | int | Number of columns (half-size ElectroCookie = 30; full-size = 60+) |
| `rails` | object | Per rail `T+`, `T-`, `B-`, `B+`: `label` (e.g. "+5V", "3V3", "GND") and optional `color` |
| `colors` | object | Extra named colours for jumpers (`{"hb": "#D97706"}`); defaults include `5v`, `3v3`, `gnd`, `sda`, `scl`, `mains`, `sig1`–`sig5` |
| `devices` | object | Off-board destinations: `{"OLED": {"name": "SH1106 OLED", "color": "#7C3AED"}}`. Add `"box": true` (plus optional `"warning"` and `"lines"`) to draw the device as a box beside the board with non-crossing routed wires instead of rotated edge labels |
| `parts` | list | Components placed on the board |
| `jumpers` | list | Wire links between holes |
| `offboard` | list | Wires leaving the board to other devices |
| `internal_ties` | list of lists | Pins joined inside a module (see below) |
| `expected_nets` | object | The netlist to verify against. Omit only for a sketch; the script warns that nothing was verified |
| `notes` | list of strings | Bullet notes under the build list |

## Holes

- `"e9"`: row `a`–`j`, column number. Rows a–e of a column are one node; rows f–j are another.
- `"T+@8"`, `"T-@8"`, `"B-@8"`, `"B+@8"`: rail hole lined up with column 8. T+ is the top
  outer rail, T− top inner, B− bottom inner, B+ bottom outer.

## Parts

Common fields: `ref` (unique, e.g. "R1"), `kind`, `value` (shown in build list),
`pins` (name → hole) unless the kind generates them, optional `note`, `label_at`
(`[dx, dy]` offset in px from the part's centre, or a hole name; `false` hides the
label), `under_module` (draw dashed and list before the module is mounted).

| kind | pins | notes |
|---|---|---|
| `resistor` | `"1"`, `"2"` | Bands drawn from `value` ("10k", "4.7k", "1M", "220") |
| `cap` | `"1"`, `"2"` | Small ceramic |
| `film` | `"1"`, `"2"` | Box body; `marking` text (e.g. "475") |
| `elec` | `"+"`, `"-"` | Electrolytic; stripe drawn on the − side |
| `diode` | `"A"`, `"K"` | Band on K |
| `to220` | any 3 names (e.g. G, D, S) | Same row, consecutive columns; `tab`: `"down"` or `"up"` |
| `header` | any names | Pin labels drawn rotated above the row |
| `dip` | auto `p1`…`pN` | `pin_count`, `col` (column of pin 1). Pin 1 in row f at `col`, pins count up rightward; pin N in row e above pin 1. Override rows with `"rows": ["f", "e"]` |
| `module` | auto from `rows` | `rows`: list of `{"row": "a", "start_col": 19, "step": -1, "names": [...]}`; duplicate names become `NAME_2`, `NAME_3`; `outline.cols` `[lo, hi]` (fractional columns, include board overhang), `outline.pad` px; `raised` (default true: translucent, female-header walls drawn); `used`: pin names to highlight; `label` |

## Jumpers

`{"from": "a9", "to": "T+@8", "color": "5v", "under": false}`. Long horizontal
jumpers are drawn with a slight arch. `"under": true` = soldered beneath a raised
module (dashed, built first).

## Off-board wires

`{"pin": "OLED.SDA", "hole": "j23", "dir": "down"}` (or the older
`{"device": "OLED", "signal": "SDA", ...}`). `dir` is
`up`, `down`, `left` or `right` (default: up for the upper half and top rails, down
otherwise). The wire is drawn straight to the board edge and labelled
"DEVICE SIGNAL". It counts as pin `DEVICE.SIGNAL` in the netlist. `under_module: true`
draws it dashed (a wire soldered under a module and led out of its channel).

## Netlist

With `circuit` set, the expected netlist comes from the circuit file and the
fields below are unnecessary. Otherwise `expected_nets` maps a net name to every pin on it, written `REF.PIN`
(`U1.p13`, `R4.1`, `ESP.GND_2`) or `DEVICE.SIGNAL` (`OLED.SDA`). The checker
unions strips via jumpers and fails if any expected net is split, if extra pins are
shorted onto it, or if a pin outside every expected net is connected to anything.

`internal_ties`: `[["ESP.GND", "ESP.GND_2", "ESP.GND_3"]]` tells the checker those
pins are joined inside the part, so a design may use one GND pin for one thing and
another for something else.

## What the checker reports

- `ERROR` (exit 1): bad hole, hole used twice, hole off the board, unknown pin in a
  net, split net, extra pins on a net, unexpected connection.
- `WARNING` (exit 0): a jumper, lead or off-board wire passes over an occupied hole;
  two drawn segments cross; reference labels overlap each other or cover a hole.
  These are drawing-clarity problems that make builders misread the layout, so fix
  them unless there's a good reason not to.
