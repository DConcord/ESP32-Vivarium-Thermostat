# Mains (120 V) wiring diagram, terminal by terminal. A hand-placed drawing, not generated from
# circuit.json: keep it in sync with the mains table in BUILD.md.
# Usage: python3 diagrams/tools/mainssvg.py diagrams/mains.svg
import sys

W, H = 1900, 1300
C = {"txt": "#1F2937", "mute": "#6B7280", "steel": "#C7CCD3", "lv": "#7C3AED",
     "red": "#DC2626", "blue": "#1D4ED8", "blk": "#111827", "wht": "#E5E7EB", "grn": "#16A34A", "yel": "#EAB308"}
o = []
def add(s): o.append(s)
def text(x, y, s, size=18, fill=C["txt"], anchor="start", weight="normal"):
    add(f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}" text-anchor="{anchor}" font-weight="{weight}" font-family="Inter,Helvetica,Arial,sans-serif">{s}</text>')
def wire(pts, col, w=9, dash=None, stripe=None):
    d = "M " + " L ".join(f"{x} {y}" for x, y in pts)
    add(f'<path d="{d}" fill="none" stroke="#374151" stroke-width="{w+4}" stroke-linejoin="round" stroke-linecap="round"/>')
    da = f' stroke-dasharray="{dash}"' if dash else ""
    add(f'<path d="{d}" fill="none" stroke="{col}" stroke-width="{w}" stroke-linejoin="round" stroke-linecap="round"{da}/>')
    if stripe: add(f'<path d="{d}" fill="none" stroke="{stripe}" stroke-width="{w}" stroke-dasharray="12 12" stroke-linejoin="round"/>')
def term(x, y, label, side="left", size=17):  # screw/tab terminal
    add(f'<circle cx="{x}" cy="{y}" r="13" fill="{C["steel"]}" stroke="#6B7280" stroke-width="2"/><path d="M {x-7} {y} L {x+7} {y}" stroke="#4B5563" stroke-width="3"/>')
    dx = {"left": -22, "right": 22, "up": 0, "down": 0}[side]; dy = {"up": -22, "down": 34}.get(side, 6)
    text(x + dx, y + dy, label, size, C["txt"], {"left": "end", "right": "start"}.get(side, "middle"), "bold")
def splice(x, y, label):
    add(f'<rect x="{x-26}" y="{y-12}" width="52" height="24" rx="8" fill="#93C5FD" stroke="#1E40AF" stroke-width="2" opacity="0.95"/>')
    text(x, y + 38, label, 14, C["mute"], "middle")

add(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="{W}" height="{H}" fill="#fff"/>')
text(60, 60, "Mains (120 V) wiring, terminal by terminal", 34, weight="bold")
text(60, 96, "Mains bay of the enclosure. Only hot (L) passes through the relay and the SSR; neutral and ground run straight from the inlet to the outlet.", 19, C["mute"])

# mains bay outline
add(f'<rect x="40" y="130" width="1820" height="900" rx="22" fill="#FEF2F2" stroke="#DC2626" stroke-width="3" stroke-dasharray="14 10"/>')
text(60, 160, "MAINS BAY, 120 V AC: unplug the cord before touching anything here", 18, "#B91C1C", weight="bold")

# ---------- inlet ----------
ix, iy = 90, 250
add(f'<rect x="{ix}" y="{iy}" width="230" height="420" rx="14" fill="#1F2937"/>')
text(ix + 115, iy - 18, "Inlet AC-14-F16A (back view)", 18, C["txt"], "middle", "bold")
add(f'<rect x="{ix+60}" y="{iy+30}" width="110" height="60" rx="8" fill="#B91C1C"/>'); text(ix + 115, iy + 68, "rocker", 15, "#fff", "middle")
add(f'<rect x="{ix+60}" y="{iy+110}" width="110" height="40" rx="6" fill="#374151"/>'); text(ix + 115, iy + 137, "fuse 2 A T", 15, "#fff", "middle")
tabs = {"L": (ix + 230, iy + 220), "N": (ix + 230, iy + 300), "⏚": (ix + 230, iy + 380)}
for k, (x, y) in tabs.items():
    add(f'<rect x="{x-12}" y="{y-9}" width="24" height="18" fill="{C["steel"]}"/>'); text(x - 20, y + 6, k, 20, "#fff", "end", "bold")
text(ix + 110, iy + 470, "L = fused + switched hot", 14, C["mute"], "middle")
text(ix + 110, iy + 492, "red L · blue N · yel/grn ⏚", 14, C["mute"], "middle")
text(ix + 110, iy + 514, "C13 cord plugs into the front", 14, C["mute"], "middle")

# ---------- K1 relay shield ----------
kx, ky = 560, 210
add(f'<rect x="{kx}" y="{ky}" width="300" height="250" rx="12" fill="#1D4ED8"/>')
add(f'<rect x="{kx+140}" y="{ky+40}" width="140" height="150" rx="6" fill="#2563EB" stroke="#93C5FD"/>')
text(kx + 210, ky + 110, "SRD-05VDC", 17, "#fff", "middle", "bold"); text(kx + 210, ky + 134, "relay", 16, "#DBEAFE", "middle")
add(f'<rect x="{kx+18}" y="{ky+40}" width="110" height="170" rx="6" fill="#3B82F6"/>')
k = {"NO": (kx + 53, ky + 70), "COM": (kx + 53, ky + 125), "NC": (kx + 53, ky + 180)}
for n, (x, y) in k.items(): term(x, y, n, "right")
text(kx + 150, ky - 18, "K1 cutoff relay shield (on its riser)", 18, C["txt"], "middle", "bold")
text(kx + 320, ky + 84, "NO / COM / NC take bare", 15, C["mute"]); text(kx + 320, ky + 106, "stripped wire, no lugs", 15, C["mute"])
text(kx + 320, ky + 60, "NC: leave empty", 15, C["mute"])
# low-voltage pins
for i, n in enumerate(["5V", "GND", "D1"]):
    x = kx + 140 + i*55; y = ky + 215
    add(f'<rect x="{x-9}" y="{y-9}" width="18" height="18" fill="#111"/><rect x="{x-3}" y="{y-3}" width="6" height="6" fill="#F5C542"/>')
    text(x, y - 16, n, 13, "#fff", "middle", "bold")

# ---------- SSR ----------
sx, sy = 560, 600
add(f'<rect x="{sx}" y="{sy}" width="380" height="240" rx="12" fill="#E5E7EB" stroke="#9CA3AF" stroke-width="3"/>')
text(sx + 190, sy - 18, "SSR Inkbird SSR-40DA (top view)", 18, C["txt"], "middle", "bold")
s = {"1": (sx + 60, sy + 70), "2": (sx + 60, sy + 170), "3 (+)": (sx + 320, sy + 70), "4 (−)": (sx + 320, sy + 170)}
term(*s["1"], "1", "right"); term(*s["2"], "2", "right"); term(*s["3 (+)"], "3 (+)", "left"); term(*s["4 (−)"], "4 (−)", "left")
text(sx + 60, sy + 225, "AC load side", 15, C["mute"], "middle"); text(sx + 320, sy + 225, "DC input side", 15, C["mute"], "middle")
text(sx + 190, sy + 125, "#8 (M4) forks or bare wire", 14, C["mute"], "middle")

# ---------- outlet ----------
ox, oy = 1490, 330
add(f'<rect x="{ox}" y="{oy}" width="230" height="300" rx="14" fill="#111827"/>')
text(ox + 115, oy - 18, "Outlet NEMA 5-15R (snap-in)", 18, C["txt"], "middle", "bold")
add(f'<rect x="{ox+70}" y="{oy+70}" width="22" height="70" rx="4" fill="#4B5563"/><rect x="{ox+138}" y="{oy+70}" width="22" height="60" rx="4" fill="#4B5563"/>')
add(f'<path d="M {ox+100} {oy+200} a 15 15 0 0 1 30 0 l 0 22 l -30 0 z" fill="#4B5563"/>')
text(ox + 115, oy + 270, "heat panel plugs in here", 15, "#D1D5DB", "middle")
leads = {"black (hot)": (ox, oy + 90), "white (neutral)": (ox, oy + 160), "green (ground)": (ox, oy + 230)}

# ---------- wires ----------
# L (red harness) -> K1 COM
wire([tabs["L"], (440, tabs["L"][1]), (440, k["COM"][1]), (k["COM"][0] - 13, k["COM"][1])], C["red"])
text(345, tabs["L"][1] - 14, "red (L)", 15, C["red"], weight="bold")
# K1 NO -> SSR 1 (your hot jumper)
wire([(k["NO"][0] - 13, k["NO"][1]), (490, k["NO"][1]), (490, s["1"][1]), (s["1"][0] - 13, s["1"][1])], C["blk"])
text(480, 640, "hot jumper", 15, C["txt"], "end", "bold"); text(480, 660, "18 AWG, black", 14, C["mute"], "end")
# SSR 2 -> outlet black
wire([(s["2"][0] - 13, s["2"][1]), (520, s["2"][1]), (520, 890), (1080, 890), (1080, leads["black (hot)"][1]), leads["black (hot)"]], C["blk"])
# N (blue) along the bottom -> splice -> outlet white
wire([tabs["N"], (365, tabs["N"][1]), (365, 925), (1225, 925)], C["blue"]); splice(1250, 925, "splice")
wire([(1276, 925), (1400, 925), (1400, leads["white (neutral)"][1]), leads["white (neutral)"]], C["wht"])
text(372, tabs["N"][1] - 12, "blue (N)", 15, C["blue"], weight="bold")
# Ground (yellow/green) along the bottom -> splice -> outlet green
wire([tabs["⏚"], (340, tabs["⏚"][1]), (340, 955), (1225, 955)], C["grn"], stripe=C["yel"]); splice(1250, 955, "")
wire([(1276, 955), (1440, 955), (1440, leads["green (ground)"][1]), leads["green (ground)"]], C["grn"])
text(1250, 990, "splices", 14, C["mute"], "middle")
text(350, 1000, "yellow/green (⏚)", 15, "#15803D", weight="bold")
for n, (x, y) in leads.items(): text(x - 14, y - 12, n, 15, C["txt"], "end", "bold")
text(1090, 878, "to outlet black lead", 15, C["txt"], weight="bold")

# low-voltage links: short stubs with tags; they run to the main board through the divider notch
def tag(x, y, label, col, anchor="start"):
    w = 9 * len(label) + 18
    x0 = x if anchor == "start" else x - w
    add(f'<rect x="{x0}" y="{y-14}" width="{w}" height="28" rx="14" fill="#F5F3FF" stroke="{col}" stroke-width="2"/>')
    text(x0 + w/2, y + 5, label, 14, col, "middle", "bold")
wire([(s["3 (+)"][0] + 13, s["3 (+)"][1]), (1000, s["3 (+)"][1])], "#EA580C", 5, "8 6"); tag(1004, s["3 (+)"][1], "to GPIO19", "#EA580C")
wire([(s["4 (−)"][0] + 13, s["4 (−)"][1]), (1000, s["4 (−)"][1])], C["blk"], 5, "8 6"); tag(1004, s["4 (−)"][1], "to GND", C["blk"])
for i, (n, col) in enumerate([("5V", "#DC2626"), ("GND", C["blk"]), ("D1", "#C026D3")]):
    x = kx + 140 + i*55
    wire([(x, ky + 224), (x, ky + 330 + i*0)], col, 4, "6 5")
tag(kx + 300, ky + 330, "to main board: 5V · GND · GPIO18", C["lv"])

# ---------- low-voltage box ----------
add(f'<rect x="700" y="1070" width="460" height="150" rx="16" fill="#F5F3FF" stroke="{C["lv"]}" stroke-width="3"/>')
text(930, 1105, "Low-voltage bay: main board", 19, C["lv"], "middle", "bold")
text(930, 1135, "SSR 3 (+) → GPIO19 · SSR 4 (−) → GND", 16, C["txt"], "middle")
text(930, 1160, "K1 5V → 5V · K1 GND → GND · K1 D1 → GPIO18", 16, C["txt"], "middle")
text(930, 1185, "(dashed stubs = low-voltage jumpers, via the divider notch)", 14, C["mute"], "middle")

# ---------- legend ----------
lx, ly = 60, 1090
text(lx, ly, "Wire colours", 20, weight="bold")
for i, (col, t, st) in enumerate([(C["red"], "hot, inlet L to relay COM", None), (C["blk"], "hot, relay NO to SSR 1, SSR 2 to outlet", None),
                                (C["blue"], "neutral (white at the outlet)", None), (C["grn"], "ground (yellow/green harness)", C["yel"])]):
    y = ly + 30 + i*30
    add(f'<rect x="{lx}" y="{y-10}" width="44" height="10" fill="{col}"/>')
    if st: add(f'<rect x="{lx+11}" y="{y-10}" width="11" height="10" fill="{st}"/><rect x="{lx+33}" y="{y-10}" width="11" height="10" fill="{st}"/>')
    text(lx + 56, y, t, 16)
text(1220, 1100, "Joins (blue blocks): heat-shrink butt splices, or a fully", 15, C["mute"])
text(1220, 1122, "insulated male/female quick-connect pair with the female", 15, C["mute"])
text(1220, 1144, "on the inlet side. Ratcheting crimper; tug-test every crimp.", 15, C["mute"])
text(1220, 1180, "Before mains: continuity checks in BUILD.md (fuse in L,", 15, C["mute"])
text(1220, 1202, "rocker on/off, ground from the plug pin to the outlet).", 15, C["mute"])
add('</svg>')
open(sys.argv[1] if len(sys.argv) > 1 else 'diagrams/mains.svg', 'w').write("\n".join(o))
