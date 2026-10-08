# Circuit file format (shared)

One JSON file describes the circuit: its parts and which pins are connected.
It is the single source of truth for every diagram of the project. Both the
`schematic-svg` and `breadboard-layout-svg` skills read the same file, and each
drawing is checked against it, so a schematic and a breadboard layout can never
silently disagree.

```json
{
  "name": "ESP32 vivarium thermostat",
  "parts": {
    "U1":  {"type": "CD74HCT123E", "identify": "DIP-16, must say HCT", "board": "cutoff",
            "pin_names": {"p1": "1A", "p2": "1B"}, "connects": "see pin labels"},
    "R1":  {"type": "10k", "identify": "brown-black-orange", "board": "cutoff", "connects": "GPIO23 to GND"},
    "ESP": {"type": "ESP32-DevKitC", "board": "esp32", "table": false,
            "internal_ties": [["GND", "GND_2", "GND_3"]]}
  },
  "nets": {
    "+5V": ["ESP.5V", "U1.p16", "R3.2"],
    "HB":  ["ESP.23", "U1.p2", "R1.1"]
  },
  "net_styles": {
    "+5V": {"color": "#DC2626", "fill": "#FEE2E2", "label": "+5V", "tag_note": "= wire to ESP32 5V/VIN"},
    "HB":  {"color": "#D97706", "label": "HEARTBEAT (GPIO23)"}
  }
}
```

## parts
Keyed by reference designator. Every field is optional:

| Field | Used for |
|---|---|
| `type` | Part name in parts tables (for passives, also the value: "10k", "100 nF ceramic") |
| `value` | Overrides `type` as the value printed beside a symbol |
| `identify` | How to recognise it: colour bands, markings, package |
| `connects` | Human summary for the parts table ("GPIO23 to GND"); otherwise generated from nets |
| `board` | Which physical board it lives on (`"cutoff"`, `"esp32"`, `"offboard"`). The breadboard checker warns if a part assigned to its board isn't placed |
| `pin_names` | Display names for pins (`"p13": "1Q"`) |
| `internal_ties` | Groups of pins joined inside the part (a dev board's several GND pins) |
| `table` | `false` keeps it out of parts tables (modules, external devices) |

## nets
Net name → list of `REF.PIN`. Every connection appears exactly once: a pin may
belong to only one net. Pin names are free-form but can't contain `.`. Use the
same names everywhere: `U1.p13` (DIP pins `p1..pN`), `R4.1`/`R4.2`,
`C3.+`/`C3.-`, `D1.A`/`D1.K`, `Q1.G/D/S`, modules by silkscreen name with
duplicates numbered (`GND`, `GND_2`). Leave genuinely unused pins out of every
net. The checkers then confirm they stay unconnected.

Off-board devices (sensors, SSRs, connectors on another board) are parts too.
That way a wire leaving one board for a header on another is the same named
pin (`J1.HB`) in both layouts.

## net_styles
Per net: `color` (wire colour), `fill` (tag background), `label` (legend text),
`tag_label` (text inside the tag, default = net name), `tag_note` (legend
explanation for tags). Nets without a style draw in dark grey.
