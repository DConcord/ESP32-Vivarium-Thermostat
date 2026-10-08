#!/usr/bin/env python3
"""Render a hole-by-hole solderable-breadboard layout SVG from a JSON spec,
after verifying its connectivity against an expected netlist.

Usage:  python bbsvg.py layout.json out.svg [--check-only]

Board model (ElectroCookie-style solderable breadboard, same as a plain
breadboard): columns 1..N; rows a-e are joined within each column, rows f-j are
joined within each column; four rails run the full length: T+ (top outer),
T- (top inner), B- (bottom inner), B+ (bottom outer). Rail names are fixed; what
they carry (5V, 3V3, GND...) is set by "rails" in the spec.

Hole notation: "e9" = row e, column 9.  "T+@8" = top + rail hole at column 8.

Exit status: 0 = netlist OK (warnings may still be printed), 1 = netlist or
spec error. See ../SKILL.md and ../references/spec.md for the spec format.
"""
import json, math, re, sys, html

# ---------------------------------------------------------------- geometry
P = 30                                    # px per 0.1" hole pitch
ROW_OFF = {'T+': 0, 'T-': 28, 'a': 76, 'b': 106, 'c': 136, 'd': 166, 'e': 196,
           'f': 256, 'g': 286, 'h': 316, 'i': 346, 'j': 376, 'B-': 424, 'B+': 452}
RAILS = ('T+', 'T-', 'B-', 'B+')
UPPER, LOWER = 'abcde', 'fghij'

DEFAULT_COLORS = {'5v': '#DC2626', '3v3': '#DC2626', 'gnd': '#111827', 'sig1': '#D97706',
                  'sig2': '#2563EB', 'sig3': '#7C3AED', 'sig4': '#C026D3', 'sig5': '#059669',
                  'sda': '#0EA5E9', 'scl': '#65A30D', 'mains': '#B91C1C'}
BAND = ['#111111', '#8B4513', '#DC2626', '#F97316', '#EAB308', '#16A34A', '#2563EB',
        '#7C3AED', '#6B7280', '#F9FAFB']
INK, MUTED = '#1F2937', '#6B7280'


class SpecError(Exception):
    pass


def parse_hole(s):
    m = re.fullmatch(r'([a-j])(\d+)', s)
    if m:
        return (m.group(1), int(m.group(2)))
    m = re.fullmatch(r'(T\+|T-|B\+|B-)@(\d+)', s)
    if m:
        return (m.group(1), int(m.group(2)))
    raise SpecError(f'bad hole "{s}" (use e.g. "e9" or "T+@8")')


def hole_name(h, rails):
    if h[0] in RAILS:
        top = 'top' if h[0][0] == 'T' else 'bottom'
        return f'{top} {rails.get(h[0], {}).get("label", h[0])} rail @ {h[1]}'
    return f'{h[0]}{h[1]}'


def strip_of(h):
    r, c = h
    if r in UPPER:
        return f'U{c}'
    if r in LOWER:
        return f'L{c}'
    return r


def resistor_bands(value):
    m = re.fullmatch(r'\s*([\d.]+)\s*([kKmMrR]?)\s*(?:Ω|ohm)?\s*', value.replace('Ω', ''))
    if not m:
        return None
    ohms = float(m.group(1)) * {'': 1, 'r': 1, 'k': 1e3, 'm': 1e6}[m.group(2).lower()]
    if ohms <= 0:
        return None
    exp = int(math.floor(math.log10(ohms))) - 1
    digits = int(round(ohms / 10 ** exp))
    if digits >= 100:
        digits //= 10
        exp += 1
    exp = max(exp, 0)
    return [BAND[digits // 10], BAND[digits % 10], BAND[min(exp, 9)]]


# ---------------------------------------------------------------- model
class Layout:
    def __init__(self, spec):
        self.spec = spec
        self.cols = spec.get('board', {}).get('cols', 30)
        self.rails = spec.get('rails', {})
        self.colors = dict(DEFAULT_COLORS, **spec.get('colors', {}))
        self.devices = spec.get('devices', {})
        self.parts = []          # dicts with ref, kind, pins{name: hole}, ...
        self.jumpers = []        # (h1, h2, color, under)
        self.offboard = []       # dicts device, signal, hole, dir
        self.ties = spec.get('internal_ties', [])
        self.warnings, self.errors = [], []
        self._build()

    def color(self, key):
        return self.colors.get(key, key)

    def _build(self):
        for p in self.spec.get('parts', []):
            p = dict(p)
            kind = p['kind']
            if kind == 'dip':
                n, c0 = p['pin_count'], p['col']
                half = n // 2
                lo, up = p.get('rows', ['f', 'e'])
                pins = {}
                for k in range(1, half + 1):
                    pins[f'p{k}'] = (lo, c0 + k - 1)
                for k in range(half + 1, n + 1):
                    pins[f'p{k}'] = (up, c0 + n - k)
                p['pins'] = pins
            elif kind == 'module':
                pins, seen = {}, {}
                p['pin_rows'] = []
                for row in p['rows']:
                    r, c, step = row['row'], row['start_col'], row.get('step', 1)
                    for i, name in enumerate(row['names']):
                        seen[name] = seen.get(name, 0) + 1
                        key = name if seen[name] == 1 else f'{name}_{seen[name]}'
                        pins[key] = (r, c + i * step)
                    p['pin_rows'].append((r, c, c + (len(row['names']) - 1) * step))
                p['pins'] = pins
            else:
                p['pins'] = {k: parse_hole(v) for k, v in p['pins'].items()}
            self.parts.append(p)
        for j in self.spec.get('jumpers', []):
            self.jumpers.append((parse_hole(j['from']), parse_hole(j['to']),
                                 self.color(j.get('color', 'sig1')), j.get('under', False)))
        for o in self.spec.get('offboard', []):
            o = dict(o)
            o['hole'] = parse_hole(o['hole'])
            o.setdefault('dir', 'up' if o['hole'][0] in UPPER or o['hole'][0][0] == 'T' else 'down')
            self.offboard.append(o)

    # ------------------------------------------------------------ checks
    def check(self):
        used = {}

        def use(h, who):
            r, c = h
            if not (1 <= c <= self.cols) or r not in ROW_OFF:
                self.errors.append(f'{who}: hole {h} is off the board')
            if h in used:
                self.errors.append(f'hole {hole_name(h, self.rails)} used twice: {used[h]} and {who}')
            used[h] = who
        for p in self.parts:
            for k, h in p['pins'].items():
                use(h, f'{p["ref"]}.{k}')
        for h1, h2, _, _ in self.jumpers:
            use(h1, 'jumper')
            use(h2, 'jumper')
        for o in self.offboard:
            use(o['hole'], f'{o["device"]}.{o["signal"]}')
        self.used = used

        par = {}

        def f(x):
            par.setdefault(x, x)
            while par[x] != x:
                par[x] = par[par[x]]
                x = par[x]
            return x

        def u(a, b):
            par[f(a)] = f(b)
        for h1, h2, _, _ in self.jumpers:
            u(strip_of(h1), strip_of(h2))
        pin_hole = {f'{p["ref"]}.{k}': h for p in self.parts for k, h in p['pins'].items()}
        for o in self.offboard:
            pin_hole[f'{o["device"]}.{o["signal"]}'] = o['hole']
        for tie in self.ties:
            for a in tie[1:]:
                if tie[0] not in pin_hole or a not in pin_hole:
                    self.errors.append(f'internal_ties: unknown pin in {tie}')
                    continue
                u(strip_of(pin_hole[tie[0]]), strip_of(pin_hole[a]))
        net = {k: f(strip_of(h)) for k, h in pin_hole.items()}
        groups = {}
        for k, v in net.items():
            groups.setdefault(v, set()).add(k)
        exp = self.spec.get('expected_nets')
        if exp is None:
            self.warnings.append('no expected_nets given: connectivity NOT verified')
        else:
            seen = set()
            for name, members in exp.items():
                seen |= set(members)
                missing = [m for m in members if m not in net]
                if missing:
                    self.errors.append(f'net {name}: unknown pins {missing}')
                    continue
                roots = {net[m] for m in members}
                if len(roots) != 1:
                    split = {}
                    for m in members:
                        split.setdefault(net[m], []).append(m)
                    self.errors.append(f'net {name} is SPLIT into {list(split.values())}')
                    continue
                extra = groups[roots.pop()] - set(members)
                if extra:
                    self.errors.append(f'net {name} has EXTRA pins shorted to it: {sorted(extra)}')
            for k in net:
                if k not in seen and len(groups[net[k]]) > 1:
                    self.errors.append(f'pin {k} is not in expected_nets but connects to {sorted(groups[net[k]] - {k})}')
        self._geometry_checks()
        return not self.errors

    def _segments(self):
        """Straight segments drawn on the board top: (p1, p2, owner, endpoints)."""
        segs = []
        for h1, h2, _, under in self.jumpers:
            segs.append((self.XY(h1), self.XY(h2), f'jumper {hole_name(h1, self.rails)}→{hole_name(h2, self.rails)}', {h1, h2}))
        for p in self.parts:
            if p['kind'] in ('resistor', 'cap', 'film', 'diode'):
                hs = list(p['pins'].values())
                segs.append((self.XY(hs[0]), self.XY(hs[1]), p['ref'], set(hs)))
        for o in self.offboard:
            x, y = self.XY(o['hole'])
            end = {'up': (x, self.by0 - 12), 'down': (x, self.by1 + 12), 'left': (self.bx0 - 12, y), 'right': (self.bx1 + 12, y)}[o['dir']]
            segs.append(((x, y), end, f'{o["device"]} {o["signal"]} wire', {o['hole']}))
        return segs

    def _geometry_checks(self):
        self._layout_frame()
        segs = self._segments()
        occupied = {h: who for h, who in self.used.items()}
        for (p1, p2, who, ends) in segs:
            for h, owner in occupied.items():
                if h in ends:
                    continue
                q = self.XY(h)
                if _dist_point_seg(q, p1, p2) < 7:
                    self.warnings.append(f'{who} passes over occupied hole {hole_name(h, self.rails)} ({owner}): looks connected')
        for i in range(len(segs)):
            for k in range(i + 1, len(segs)):
                a, b = segs[i], segs[k]
                if a[3] & b[3]:
                    continue
                if _seg_cross(a[0], a[1], b[0], b[1]):
                    self.warnings.append(f'{a[2]} crosses {b[2]}')
        boxes = []
        for p in self.parts:
            lb = self.label_box(p)
            if lb:
                boxes.append((lb, p['ref']))
        for i in range(len(boxes)):
            for k in range(i + 1, len(boxes)):
                if _overlap(boxes[i][0], boxes[k][0]):
                    self.warnings.append(f'labels {boxes[i][1]} and {boxes[k][1]} overlap')
        for (bx, ref) in boxes:
            for h, owner in occupied.items():
                x, y = self.XY(h)
                if bx[0] - 4 < x < bx[2] + 4 and bx[1] - 4 < y < bx[3] + 4 and not owner.startswith(ref + '.'):
                    self.warnings.append(f'label {ref} covers hole {hole_name(h, self.rails)} ({owner})')

    # ------------------------------------------------------------ frame
    def _layout_frame(self):
        if hasattr(self, 'X0'):
            return
        up = any(o['dir'] == 'up' for o in self.offboard)
        down = any(o['dir'] == 'down' for o in self.offboard)
        left = any(o['dir'] == 'left' for o in self.offboard)
        self.top = 110 + (150 if up else 30)
        self.X0 = 150 + (80 if left else 0)
        self.RY = {k: self.top + v for k, v in ROW_OFF.items()}
        self.bx0, self.bx1 = self.X(1) - 48, self.X(self.cols) + 48
        self.by0, self.by1 = self.RY['T+'] - 32, self.RY['B+'] + 34
        right = any(o['dir'] == 'right' for o in self.offboard)
        self.W = max(1000, int(self.bx1 + (260 if right else 60)))
        self.board_bottom = self.by1 + (150 if down else 40)

    def X(self, c):
        return self.X0 + (c - 1) * P

    def XY(self, h):
        return self.X(h[1]), self.RY[h[0]]

    def label_box(self, p):
        if p['kind'] in ('module', 'dip', 'header') or p.get('label') is False:
            return None
        x, y = self.label_pos(p)
        w = len(p['ref']) * 8 + 12
        return (x - w / 2, y - 12, x + w / 2, y + 4)

    def label_pos(self, p):
        hs = [self.XY(h) for h in p['pins'].values()]
        if 'label_at' in p:
            la = p['label_at']
            if isinstance(la, str):
                return self.XY(parse_hole(la))
            mx = sum(h[0] for h in hs) / len(hs)
            my = sum(h[1] for h in hs) / len(hs)
            return (mx + la[0], my + la[1])
        mx = sum(h[0] for h in hs) / len(hs)
        my = sum(h[1] for h in hs) / len(hs)
        if p['kind'] == 'to220':
            return (mx, my - 24)
        (x1, y1), (x2, y2) = hs[0], hs[-1]
        if abs(x2 - x1) >= abs(y2 - y1):         # horizontal-ish: label above
            return (mx, my - 16)
        return (mx + 26, my + 4)                  # vertical-ish: label to the right


def _dist_point_seg(q, a, b):
    ax, ay = a
    bx, by = b
    qx, qy = q
    dx, dy = bx - ax, by - ay
    L2 = dx * dx + dy * dy
    if L2 == 0:
        return math.dist(q, a)
    t = max(0, min(1, ((qx - ax) * dx + (qy - ay) * dy) / L2))
    return math.dist(q, (ax + t * dx, ay + t * dy))


def _seg_cross(p1, p2, p3, p4):
    def orient(a, b, c):
        v = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
        return 0 if abs(v) < 1e-9 else (1 if v > 0 else -1)
    o1, o2, o3, o4 = orient(p1, p2, p3), orient(p1, p2, p4), orient(p3, p4, p1), orient(p3, p4, p2)
    return o1 * o2 < 0 and o3 * o4 < 0


def _overlap(a, b):
    return a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]


# ---------------------------------------------------------------- render
class Renderer:
    def __init__(self, L):
        self.L = L
        self.o = []

    def a(self, s):
        self.o.append(s)

    def text(self, x, y, t, size=12, c=INK, anchor='start', weight='normal', rot=None):
        tr = f' transform="rotate({rot} {x} {y})"' if rot is not None else ''
        self.a(f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" fill="{c}" text-anchor="{anchor}" '
               f'font-weight="{weight}"{tr}>{html.escape(str(t))}</text>')

    def solder(self, p, ring='#6B7280'):
        self.a(f'<circle cx="{p[0]:.1f}" cy="{p[1]:.1f}" r="4.2" fill="#D1D5DB" stroke="{ring}" stroke-width="1"/>')

    def lead(self, p1, p2, c='#9CA3AF', w=3):
        self.a(f'<line x1="{p1[0]:.1f}" y1="{p1[1]:.1f}" x2="{p2[0]:.1f}" y2="{p2[1]:.1f}" stroke="{c}" '
               f'stroke-width="{w}" stroke-linecap="round"/>')

    def body_along(self, p1, p2, length, thick, fill, stroke):
        ang = math.degrees(math.atan2(p2[1] - p1[1], p2[0] - p1[0]))
        mx, my = (p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2
        self.a(f'<g transform="translate({mx:.1f},{my:.1f}) rotate({ang:.1f})">'
               f'<rect x="{-length / 2:.1f}" y="{-thick / 2}" width="{length:.1f}" height="{thick}" rx="{thick / 2.2:.1f}" '
               f'fill="{fill}" stroke="{stroke}" stroke-width="1.2"/>')

    def render(self):
        L = self.L
        L._layout_frame()
        S = L.spec
        rows = self.build_rows()
        H = int(L.board_bottom + 60 + len(rows) * 19 + 40 + 18 * len(S.get('notes', [])) + 40)
        self.a(f'<svg xmlns="http://www.w3.org/2000/svg" width="{L.W}" height="{H}" viewBox="0 0 {L.W} {H}" '
               f'font-family="Helvetica, Arial, sans-serif">')
        self.a(f'<rect width="{L.W}" height="{H}" fill="#FFFFFF"/>')
        self.text(40, 42, S.get('title', 'Breadboard layout'), 22, INK, weight='bold')
        for i, line in enumerate(S.get('subtitle', [
                'Top (component side) view. Rows a–e are joined in each column, as are f–j. Rails run the full length.'])
                if isinstance(S.get('subtitle'), list) else [S['subtitle']]):
            self.text(40, 66 + i * 18, line, 13, MUTED)
        self.board()
        under = [j for j in L.jumpers if j[3]]
        for j in under:
            self.jumper(*j)
        for p in L.parts:
            if p['kind'] not in ('module',) and p.get('under_module'):
                self.part(p)
        for o in L.offboard:
            if o.get('under_module'):
                self.offwire(o)
        for p in L.parts:
            if p['kind'] == 'module':
                self.module(p)
        for j in L.jumpers:
            if not j[3]:
                self.jumper(*j)
        for p in L.parts:
            if p['kind'] != 'module' and not p.get('under_module'):
                self.part(p)
        for o in L.offboard:
            if not o.get('under_module'):
                self.offwire(o)
        for p in L.parts:
            if L.label_box(p):
                self.label(p)
        self.build_list(rows)
        self.a('</svg>')
        return '\n'.join(self.o)

    # -- board
    def board(self):
        L = self.L
        X, RY = L.X, L.RY
        self.a(f'<rect x="{L.bx0}" y="{L.by0}" width="{L.bx1 - L.bx0}" height="{L.by1 - L.by0}" rx="14" fill="#2F6B4F" stroke="#1E4D38" stroke-width="2"/>')
        for c in range(1, L.cols + 1):
            for r0, r1 in (('a', 'e'), ('f', 'j')):
                self.a(f'<rect x="{X(c) - 9}" y="{RY[r0] - 11}" width="18" height="{RY[r1] - RY[r0] + 22}" rx="8" fill="#B87333" opacity="0.55"/>')
        for r in RAILS:
            info = L.rails.get(r, {})
            col = info.get('color', '#DC2626' if '+' in r else '#2563EB')
            self.a(f'<rect x="{X(1) - 12}" y="{RY[r] - 9}" width="{X(L.cols) - X(1) + 24}" height="18" rx="9" fill="#B87333" opacity="0.55"/>')
            sym = '+' if '+' in r else '−'
            self.text(X(1) - 30, RY[r] + 5, sym, 16, col, 'middle', 'bold')
            self.text(X(L.cols) + 30, RY[r] + 5, sym, 16, col, 'middle', 'bold')
            if info.get('label'):
                self.text(L.bx0 - 8, RY[r] + 4, info['label'], 11, col, 'end', 'bold')
        self.a(f'<rect x="{X(1) - 14}" y="{RY["e"] + 18}" width="{X(L.cols) - X(1) + 28}" height="{RY["f"] - RY["e"] - 36}" fill="#24563F"/>')
        for c in range(1, L.cols + 1):
            for r in RY:
                x, y = X(c), RY[r]
                self.a(f'<circle cx="{x}" cy="{y}" r="5.5" fill="#E8C9A0"/><circle cx="{x}" cy="{y}" r="2.6" fill="#1E3A2D"/>')
            if c == 1 or c % 5 == 0:
                self.text(X(c), RY['a'] - 20, c, 10, '#E5E7EB', 'middle', 'bold')
                self.text(X(c), RY['j'] + 27, c, 10, '#E5E7EB', 'middle', 'bold')
        for r in 'abcdefghij':
            self.text(X(1) - 26, RY[r] + 4, r, 11, '#E5E7EB', 'middle', 'bold')
            self.text(X(L.cols) + 26, RY[r] + 4, r, 11, '#E5E7EB', 'middle', 'bold')

    def jumper(self, h1, h2, col, under):
        L = self.L
        (x1, y1), (x2, y2) = L.XY(h1), L.XY(h2)
        dash = ' stroke-dasharray="9,5"' if under else ''
        if math.dist((x1, y1), (x2, y2)) > 80 and y1 == y2:
            self.a(f'<path d="M{x1},{y1} Q{(x1 + x2) / 2},{y1 - 14} {x2},{y2}" fill="none" stroke="{col}" stroke-width="5" stroke-linecap="round"{dash}/>')
        else:
            self.a(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{col}" stroke-width="5" stroke-linecap="round"{dash}/>')
        self.solder((x1, y1))
        self.solder((x2, y2))

    def part(self, p):
        L = self.L
        k = p['kind']
        hs = [L.XY(h) for h in p['pins'].values()]
        if k == 'resistor':
            p1, p2 = hs
            self.lead(p1, p2)
            bl = min(40, math.dist(p1, p2) - 14)
            self.body_along(p1, p2, bl, 11, '#E8D3A9', '#8D6E4A')
            for i, bc in enumerate(resistor_bands(p.get('value', '')) or []):
                self.a(f'<rect x="{-bl / 2 + 7 + i * 6:.1f}" y="-5.5" width="3.5" height="11" fill="{bc}"/>')
            self.a(f'<rect x="{bl / 2 - 10:.1f}" y="-5.5" width="3.5" height="11" fill="#C9A227"/></g>')
            self.solder(p1)
            self.solder(p2)
        elif k == 'cap':
            p1, p2 = hs
            self.lead(p1, p2)
            mx, my = (p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2
            self.a(f'<ellipse cx="{mx}" cy="{my}" rx="9" ry="7" fill="#F59E0B" stroke="#92400E"/>')
            self.solder(p1)
            self.solder(p2)
        elif k == 'film':
            p1, p2 = hs
            self.lead(p1, p2)
            mx, my = (p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2
            self.a(f'<rect x="{mx - 30}" y="{my - 11}" width="60" height="22" rx="3" fill="#FDE047" stroke="#A16207" stroke-width="1.5"/>')
            self.text(mx, my + 4, p.get('marking', ''), 10, '#713F12', 'middle', 'bold')
            self.solder(p1)
            self.solder(p2)
        elif k == 'elec':
            p1, p2 = L.XY(p['pins']['+']), L.XY(p['pins']['-'])
            self.solder(p1)
            self.solder(p2)
            mx, my = (p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2
            self.a(f'<circle cx="{mx}" cy="{my}" r="14" fill="#1E3A8A" stroke="#0F172A" stroke-width="1.5" opacity="0.92"/>')
            # stripe on the minus side
            ang = math.atan2(p2[1] - p1[1], p2[0] - p1[0])
            sx, sy = mx + 10 * math.cos(ang), my + 10 * math.sin(ang)
            self.a(f'<circle cx="{sx:.1f}" cy="{sy:.1f}" r="4" fill="#CBD5E1"/>')
            self.text(mx - 4 * math.cos(ang), my - 4 * math.sin(ang) + 4, '+', 12, '#FCA5A5', 'middle', 'bold')
        elif k == 'diode':
            pA, pK = L.XY(p['pins']['A']), L.XY(p['pins']['K'])
            self.lead(pA, pK)
            self.body_along(pA, pK, 26, 11, '#111827', '#000')
            self.a('<rect x="7" y="-5.5" width="4" height="11" fill="#D1D5DB"/></g>')
            self.solder(pA)
            self.solder(pK)
        elif k == 'to220':
            xs = [h[0] for h in hs]
            y = hs[0][1]
            for h in hs:
                self.solder(h)
            tab_down = p.get('tab', 'down') == 'down'
            self.a(f'<rect x="{min(xs) - 16}" y="{y - 9}" width="{max(xs) - min(xs) + 32}" height="16" fill="#111827"/>')
            ty = y + 7 if tab_down else y - 16
            self.a(f'<rect x="{min(xs) - 16}" y="{ty}" width="{max(xs) - min(xs) + 32}" height="7" fill="#9CA3AF" stroke="#4B5563"/>')
            for n, h in p['pins'].items():
                self.text(L.XY(h)[0], y + 4, n, 10, '#FFFFFF', 'middle', 'bold')
        elif k == 'header':
            xs = [h[0] for h in hs]
            ys = [h[1] for h in hs]
            if max(ys) - min(ys) < 2:
                y = ys[0]
                self.a(f'<rect x="{min(xs) - 12}" y="{y - 11}" width="{max(xs) - min(xs) + 24}" height="22" fill="#111827" rx="2"/>')
            for n, h in p['pins'].items():
                x, y = L.XY(h)
                self.a(f'<rect x="{x - 3.5}" y="{y - 3.5}" width="7" height="7" fill="#EAB308"/>')
                self.text(x + 4, y - 16, n, 10, '#FFFFFF', 'start', 'bold', rot=-55)
        elif k == 'dip':
            pins = p['pins']
            n = len(pins)
            half = n // 2
            c0 = p['col']
            x0, x1 = L.X(c0) - 14, L.X(c0 + half - 1) + 14
            lo, up = p.get('rows', ['f', 'e'])
            y0, y1 = L.RY[up] - 8, L.RY[lo] + 8
            for h in pins.values():
                self.solder(L.XY(h))
            self.a(f'<rect x="{x0}" y="{y0 + 6}" width="{x1 - x0}" height="{y1 - y0 - 12}" rx="4" fill="#111827"/>')
            self.a(f'<path d="M{x0},{(y0 + y1) / 2 - 9} A9,9 0 0,1 {x0},{(y0 + y1) / 2 + 9}" fill="#4B5563"/>')
            self.a(f'<circle cx="{x0 + 10}" cy="{y1 - 16}" r="3" fill="#6B7280"/>')
            self.text((x0 + x1) / 2, (y0 + y1) / 2 + 4, f'{p["ref"]}  {p.get("value", "")}', 11, '#F9FAFB', 'middle', 'bold')
            for key, h in pins.items():
                x, y = L.XY(h)
                self.text(x, y + (-12 if h[0] == up else 20), key[1:], 9, '#FDE68A', 'middle', 'bold')

    def module(self, p):
        L = self.L
        o = p.get('outline', {})
        c_lo, c_hi = o.get('cols', [min(h[1] for h in p['pins'].values()) - 1.5, max(h[1] for h in p['pins'].values()) + 1.5])
        rows = sorted({h[0] for h in p['pins'].values()}, key=lambda r: L.RY[r])
        ex0, ex1 = L.X(1) + (c_lo - 1) * P, L.X(1) + (c_hi - 1) * P
        ey0, ey1 = L.RY[rows[0]] - o.get('pad', 20), L.RY[rows[-1]] + o.get('pad', 20)
        raised = p.get('raised', True)
        fill_op = 0.38 if raised else 0.9
        self.a(f'<rect x="{ex0}" y="{ey0}" width="{ex1 - ex0}" height="{ey1 - ey0}" rx="6" fill="{p.get("fill", "#111827")}" fill-opacity="{fill_op}" stroke="#111827" stroke-width="2.5"/>')
        self.text((ex0 + ex1) / 2, (ey0 + ey1) / 2 + 5, p.get('label', p['ref']) + ('  (raised on female headers)' if raised else ''), 13, '#F9FAFB', 'middle', 'bold')
        for r, ca, cb in p['pin_rows']:
            lo, hi = min(ca, cb), max(ca, cb)
            self.a(f'<rect x="{L.X(lo) - 13}" y="{L.RY[r] - 9}" width="{L.X(hi) - L.X(lo) + 26}" height="18" rx="2" fill="#030712" fill-opacity="0.8"/>')
        used = set(p.get('used', []))
        for key, h in p['pins'].items():
            x, y = L.XY(h)
            name = key.split('_')[0] if re.fullmatch(r'.+_\d+', key) else key
            u = (key in used) or (name in used)
            self.a(f'<rect x="{x - 3.5}" y="{y - 3.5}" width="7" height="7" fill="{"#EAB308" if u else "#6B7280"}"/>')
            above = h[0] == rows[-1]
            self.text(x, y - 13 if above else y + 20, name, 9, '#FDE68A' if u else '#D1D5DB', 'middle', 'bold' if u else 'normal')

    def offwire(self, o):
        L = self.L
        dev = L.devices.get(o['device'], {})
        col = dev.get('color', '#DB2777')
        x, y = L.XY(o['hole'])
        lab = f'{o["device"]} {o["signal"]}'
        dash = ' stroke-dasharray="9,5"' if o.get('under_module') else ''
        if o['dir'] in ('up', 'down'):
            ye = L.by0 - 12 if o['dir'] == 'up' else L.by1 + 12
            self.a(f'<line x1="{x}" y1="{y}" x2="{x}" y2="{ye}" stroke="{col}" stroke-width="4" stroke-linecap="round"{dash}/>')
            self.a(f'<circle cx="{x}" cy="{ye}" r="4" fill="{col}"/>')
            if o['dir'] == 'up':
                self.text(x + 4, ye - 8, lab, 10, col, 'start', 'bold', rot=-60)
            else:
                self.text(x + 4, ye + 12, lab, 10, col, 'start', 'bold', rot=60)
        else:
            xe = L.bx0 - 12 if o['dir'] == 'left' else L.bx1 + 12
            self.a(f'<line x1="{x}" y1="{y}" x2="{xe}" y2="{y}" stroke="{col}" stroke-width="4" stroke-linecap="round"{dash}/>')
            self.text(xe - 6 if o['dir'] == 'left' else xe + 6, y + 4, lab, 10, col, 'end' if o['dir'] == 'left' else 'start', 'bold')
        self.solder((x, y), col)

    def label(self, p):
        x0, y0, x1, y1 = self.L.label_box(p)
        self.a(f'<rect x="{x0:.1f}" y="{y0:.1f}" width="{x1 - x0:.1f}" height="{y1 - y0 + 2:.1f}" rx="4" fill="#FFFFFF" opacity="0.92"/>')
        self.text((x0 + x1) / 2, y1 - 2, p['ref'], 11, INK, 'middle', 'bold')

    # -- build list
    def build_rows(self):
        L = self.L
        hn = lambda h: hole_name(h, L.rails)
        rows = []
        step = 0
        mods = [p for p in L.parts if p['kind'] in ('module', 'dip')]
        if mods:
            step += 1
            for p in mods:
                if p['kind'] == 'dip':
                    n = len(p['pins'])
                    h1, hh = p['pins']['p1'], p['pins'][f'p{n // 2}']
                    top1, toph = p['pins'][f'p{n}'], p['pins'][f'p{n // 2 + 1}']
                    rows.append((step, f'{p["ref"]} socket ({n}-pin)', f'pins 1–{n // 2} in {hn(h1)}–{hn(hh)}, pins {n}–{n // 2 + 1} in {hn(top1)}–{hn(toph)}', p.get('note', 'notch toward column 1; chip goes in last')))
                else:
                    for r, ca, cb in p['pin_rows']:
                        rows.append((step, f'{p["ref"]} header row', f'row {r}, columns {min(ca, cb)}–{max(ca, cb)}', p.get('note', 'female headers; plug the module in last')))
        und = [j for j in L.jumpers if j[3]] + [p for p in L.parts if p.get('under_module')]
        if und:
            step += 1
            for j in [j for j in L.jumpers if j[3]]:
                rows.append((step, 'Jumper (under module)', f'{hn(j[0])} → {hn(j[1])}', 'solder before the module goes on; keep it flat'))
            for p in [p for p in L.parts if p.get('under_module')]:
                rows.append((step, f'{p["ref"]} {p.get("value", "")} (under module)', ' ↔ '.join(hn(h) for h in p['pins'].values()), p.get('note', 'lying flat')))
        outj = [j for j in L.jumpers if not j[3]]
        if outj:
            step += 1
            for j in outj:
                rows.append((step, 'Jumper', f'{hn(j[0])} → {hn(j[1])}', ''))
        order = ['resistor', 'cap', 'film', 'diode', 'elec', 'to220', 'header']
        names = {'resistor': 'resistor', 'cap': 'ceramic cap', 'film': 'film cap', 'diode': 'diode', 'elec': 'electrolytic', 'to220': '', 'header': 'header'}
        for kind in order:
            ps = [p for p in L.parts if p['kind'] == kind and not p.get('under_module')]
            if not ps:
                continue
            step += 1
            for p in ps:
                if kind == 'header':
                    holes = ' · '.join(f'{hn(h)} {n}' for n, h in p['pins'].items())
                else:
                    holes = ' ↔ '.join(f'{n} {hn(h)}' if kind in ('to220', 'diode', 'elec') else hn(h) for n, h in p['pins'].items())
                default = {'diode': 'band = cathode (K)', 'elec': 'stripe = −'}.get(kind, '')
                rows.append((step, f'{p["ref"]}  {p.get("value", "")} {names[kind]}'.strip(), holes, p.get('note', default)))
        if L.offboard:
            step += 1
            devs = []
            for o in L.offboard:
                if o['device'] not in devs:
                    devs.append(o['device'])
            for d in devs:
                items = ' · '.join(f'{o["signal"]} {hn(o["hole"])}' for o in L.offboard if o['device'] == d)
                rows.append((step, f'Wires to {L.devices.get(d, {}).get("name", d)}', items, ''))
        return rows

    def build_list(self, rows):
        L = self.L
        ty = L.board_bottom + 40
        self.text(40, ty, 'Build list (hole = row + column, e.g. e9 = row e, column 9; rail holes are given by the column they line up with)', 13, INK, weight='bold')
        cols = [40, 72, 330, 860]
        for j, h in enumerate(['Step', 'Part', 'Holes', 'Notes']):
            self.text(cols[j], ty + 26, h, 11, MUTED, weight='bold')
        self.a(f'<line x1="40" y1="{ty + 32}" x2="{L.W - 40}" y2="{ty + 32}" stroke="#D1D5DB"/>')
        last = None
        for i, r in enumerate(rows):
            yy = ty + 50 + i * 19
            if i % 2 == 0:
                self.a(f'<rect x="36" y="{yy - 14}" width="{L.W - 72}" height="19" fill="#F3F4F6"/>')
            self.text(cols[0], yy, r[0] if r[0] != last else '', 11, INK, weight='bold')
            last = r[0]
            self.text(cols[1], yy, r[1], 11, INK, weight='bold')
            self.text(cols[2], yy, r[2], 11)
            self.text(cols[3], yy, r[3], 11, MUTED)
        yy = ty + 50 + len(rows) * 19 + 14
        for i, n in enumerate(L.spec.get('notes', [])):
            self.text(40, yy + i * 18, '• ' + n, 11, MUTED)


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(2)
    spec = json.load(open(sys.argv[1]))
    try:
        L = Layout(spec)
        ok = L.check()
    except SpecError as e:
        print('SPEC ERROR:', e)
        sys.exit(1)
    for w in L.warnings:
        print('WARNING:', w)
    for e in L.errors:
        print('ERROR:', e)
    print('NETLIST OK' if ok and spec.get('expected_nets') is not None else ('NETLIST NOT CHECKED' if ok else 'NETLIST FAIL'))
    if not ok:
        sys.exit(1)
    if '--check-only' not in sys.argv:
        open(sys.argv[2], 'w').write(Renderer(L).render())
        print('wrote', sys.argv[2])


if __name__ == '__main__':
    main()
