#!/usr/bin/env python3
"""Render a schematic / wiring-diagram SVG from a sheet spec plus a shared
circuit file, after checking that the drawing connects exactly what the circuit
file says.

Usage:  python schsvg.py sheet.json out.svg [--check-only]

The circuit file (parts + nets) is the single source of truth and can be shared
with the breadboard-layout-svg skill. The sheet only says where things are drawn:
symbols, wires, net tags, panels and notes. See ../SKILL.md and
../references/sheet.md.

Exit status 0 = drawing matches the circuit (warnings may still print),
1 = mismatch or spec error.
"""
import json, math, os, re, sys, html

INK, MUTED = '#1F2937', '#6B7280'
STYLES = {  # block styles: fill, stroke, title colour
    'ic': ('#FCE7F3', '#9D174D', INK), 'module': ('#1F2937', '#111827', '#F9FAFB'),
    'device': ('#E1F5EE', '#0F6E56', '#085041'), 'grey': ('#F1EFE8', '#5F5E5A', INK),
    'blue': ('#DBEAFE', '#1D4ED8', '#1E3A8A'), 'amber': ('#FEF3C7', '#92400E', '#78350F'),
    'purple': ('#EEEDFE', '#534AB7', '#3C3489'), 'red': ('#FAECE7', '#993C1D', '#712B13'),
    'pink': ('#FCE7F3', '#9D174D', '#72243E'),
}
TWO_PIN = {'resistor': ('1', '2'), 'cap': ('1', '2'), 'film': ('1', '2'), 'elec': ('+', '-'), 'diode': ('A', 'K')}
DIRS = {'right': 0, 'down': 90, 'left': 180, 'up': 270}


class SpecError(Exception):
    pass


def load_json(path):
    with open(path) as f:
        return json.load(f)


class Sheet:
    def __init__(self, spec, base):
        self.spec = spec
        cpath = spec.get('circuit')
        if not cpath:
            raise SpecError('sheet needs "circuit": path to the circuit file')
        self.circuit = load_json(os.path.join(base, cpath))
        self.nets = self.circuit.get('nets', {})
        self.styles = self.circuit.get('net_styles', {})
        self.cparts = self.circuit.get('parts', {})
        self.pin_net = {}
        for n, members in self.nets.items():
            for m in members:
                if m in self.pin_net:
                    raise SpecError(f'circuit: pin {m} is in nets {self.pin_net[m]} and {n}')
                self.pin_net[m] = n
        self.colors = spec.get('colors', {})
        self.pins = {}          # "REF.PIN" -> (x, y)
        self.symbols = spec.get('symbols', [])
        self.warnings, self.errors = [], []
        for s in self.symbols:
            if s['ref'] not in self.cparts:
                self.warnings.append(f'symbol {s["ref"]} is not a part in the circuit file')
            for name, pt in self.symbol_pins(s).items():
                key = f'{s["ref"]}.{name}'
                if key in self.pins:
                    raise SpecError(f'pin {key} defined twice')
                self.pins[key] = pt
        self.wires = []
        for i, w in enumerate(spec.get('wires', [])):
            pts = [self.point(w['from'])] + [tuple(p) for p in w.get('via', [])] + [self.point(w['to'])]
            self.wires.append(dict(w, pts=pts, id=i))
        self.tags = []
        for t in spec.get('tags', []):
            t = dict(t)
            base_pt = self.point(t['pin']) if 'pin' in t else tuple(t['at'])
            side = t.get('side', 'right')
            ln = t.get('len', 20 if 'pin' in t else 0)
            dx, dy = {'right': (1, 0), 'left': (-1, 0), 'up': (0, -1), 'down': (0, 1)}[side]
            t['base'] = base_pt
            t['end'] = (base_pt[0] + dx * ln, base_pt[1] + dy * ln)
            self.tags.append(t)

    # ------------------------------------------------------------ geometry
    def point(self, ref):
        if isinstance(ref, str):
            if ref not in self.pins:
                raise SpecError(f'unknown pin "{ref}" (is its symbol on the sheet?)')
            return self.pins[ref]
        return tuple(ref)

    def symbol_pins(self, s):
        k = s['kind']
        x, y = s['at']
        if k in TWO_PIN:
            names = s.get('pins', TWO_PIN[k])
            ln = s.get('len', 80 if k == 'resistor' else 60)
            a = math.radians(DIRS[s.get('dir', 'down')])
            return {names[0]: (x, y), names[1]: (round(x + ln * math.cos(a)), round(y + ln * math.sin(a)))}
        if k == 'nmos':
            m = -1 if s.get('mirror') else 1
            return {'G': (x, y), 'D': (x + 60 * m, y - 60), 'S': (x + 60 * m, y + 60)}
        if k == 'switch':
            m = -1 if s.get('mirror') else 1
            return {'COM': (x, y), 'NO': (x + 80 * m, y - 30), 'NC': (x + 80 * m, y + 35)}
        if k == 'block':
            g = self.block_geom(s)
            return g['pins']
        if k == 'note':
            return {}
        raise SpecError(f'{s["ref"]}: unknown symbol kind {k}')

    def block_geom(self, s):
        x, y = s['at']
        w = s.get('w', 160)
        pitch = s.get('pitch', 40)
        stub = s.get('stub', 20)
        top_pad = s.get('pad_top', 30)
        n = max(len(s.get('left', [])), len(s.get('right', [])), 1)
        n = max([n] + [int((p['y'] - top_pad) / pitch) + 1 for side in ('left', 'right') for p in s.get(side, []) if isinstance(p, dict) and 'y' in p])
        h = s.get('h', top_pad + (n - 1) * pitch + s.get('pad_bottom', 30))
        pins, sides = {}, {}
        lp = s.get('pad_left', 40)

        def place(side, i, p):
            if not p:
                return
            name = p['pin'] if isinstance(p, dict) else p
            if side in ('left', 'right'):
                off = p['y'] if isinstance(p, dict) and 'y' in p else top_pad + i * pitch
                pins[name] = (x - stub if side == 'left' else x + w + stub, y + off)
            else:
                off = p['x'] if isinstance(p, dict) and 'x' in p else lp + i * pitch
                pins[name] = (x + off, y - stub if side == 'top' else y + h + stub)
            sides[name] = side
        for side in ('left', 'right', 'top', 'bottom'):
            for i, p in enumerate(s.get(side, [])):
                place(side, i, p)
        return {'x': x, 'y': y, 'w': w, 'h': h, 'stub': stub, 'pins': pins, 'sides': sides}

    def net_color(self, net, default=INK):
        return self.styles.get(net, {}).get('color', default)

    def color(self, key, default=INK):
        if key is None:
            return default
        if key in self.colors:
            return self.colors[key]
        if key in self.styles:
            return self.styles[key].get('color', default)
        return key

    def wire_color(self, w):
        if 'color' in w:
            return self.color(w['color'])
        for end in (w['from'], w['to']):
            if isinstance(end, str) and end in self.pin_net:
                return self.net_color(self.pin_net[end])
        return INK

    # ------------------------------------------------------------ check
    def check(self):
        par = {}

        def f(a):
            par.setdefault(a, a)
            while par[a] != a:
                par[a] = par[par[a]]
                a = par[a]
            return a

        def u(a, b):
            par[f(a)] = f(b)
        by_point = {}
        self.junctions = set()
        for k, pt in self.pins.items():
            f(('pin', k))
            if pt in by_point:          # two pins drawn touching = joined
                u(('pin', k), ('pin', by_point[pt]))
            by_point[pt] = k
        segs = []
        for w in self.wires:
            f(('wire', w['id']))
            for a, b in zip(w['pts'], w['pts'][1:]):
                if a[0] != b[0] and a[1] != b[1]:
                    self.warnings.append(f'wire {self.wdesc(w)} has a diagonal segment {a}→{b}')
                segs.append((a, b, w['id']))

        def on_seg(p, a, b, interior=False):
            if min(a[0], b[0]) - .5 <= p[0] <= max(a[0], b[0]) + .5 and min(a[1], b[1]) - .5 <= p[1] <= max(a[1], b[1]) + .5:
                cross = (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])
                if abs(cross) <= .5 * max(1, math.dist(a, b)):
                    return not interior or (p != a and p != b)
            return False
        for w in self.wires:
            for end in (w['pts'][0], w['pts'][-1]):
                attached = False
                if end in by_point:
                    u(('wire', w['id']), ('pin', by_point[end]))
                    attached = True
                for (a, b, wid) in segs:
                    if wid == w['id']:
                        continue
                    if on_seg(end, a, b):
                        u(('wire', w['id']), ('wire', wid))
                        attached = True
                        if on_seg(end, a, b, interior=True):
                            self.junctions.add(end)
                for t in self.tags:
                    if t['end'] == end and 'pin' not in t:
                        attached = True
                if not attached:
                    self.warnings.append(f'wire {self.wdesc(w)} has a loose end at {end}')
            # a pin touching the middle of a wire is a T-junction: joined, with a dot
            for k, pt in self.pins.items():
                for a, b in zip(w['pts'], w['pts'][1:]):
                    if on_seg(pt, a, b, interior=True):
                        u(('wire', w['id']), ('pin', k))
                        self.junctions.add(pt)
        # count endpoints for dots
        ends = {}
        for w in self.wires:
            for e in (w['pts'][0], w['pts'][-1]):
                ends[e] = ends.get(e, 0) + 1
        pin_count = {}
        for k, pt in self.pins.items():
            pin_count[pt] = pin_count.get(pt, 0) + 1
        for pt in set(ends) | set(pin_count):
            if ends.get(pt, 0) + pin_count.get(pt, 0) >= 3:
                self.junctions.add(pt)
        for t in self.tags:
            node = ('tagnet', t['net'])
            if t['net'] not in self.nets:
                self.errors.append(f'tag {t["net"]} names a net that is not in the circuit file')
            if 'pin' in t:
                u(('pin', t['pin']), node)
            else:
                hit = False
                if t['base'] in by_point:
                    u(('pin', by_point[t['base']]), node)
                    hit = True
                for (a, b, wid) in segs:
                    if on_seg(t['base'], a, b):
                        u(('wire', wid), node)
                        hit = True
                if not hit:
                    self.warnings.append(f'tag {t["net"]} at {t["base"]} is not attached to a wire or pin')
        for (i, s1) in enumerate(segs):
            for s2 in segs[i + 1:]:
                if s1[2] != s2[2] and _cross(s1[0], s1[1], s2[0], s2[1]):
                    self.warnings.append(f'wires {self.wdesc(self.wires[s1[2]])} and {self.wdesc(self.wires[s2[2]])} cross')
        # compare with circuit
        groups = {}
        for k in self.pins:
            groups.setdefault(f(('pin', k)), set()).add(k)
        tagnets = {}
        for t in self.tags:
            tagnets.setdefault(f(('tagnet', t['net'])), set()).add(t['net'])
        for root, names in tagnets.items():
            if len(names) > 1:
                self.errors.append(f'tags {sorted(names)} are joined in the drawing (short between nets)')
        for net, members in self.nets.items():
            drawn = [m for m in members if m in self.pins]
            if not drawn:
                continue
            roots = {f(('pin', m)) for m in drawn}
            linked = {f(('tagnet', net))} if ('tagnet', net) in par else set()
            if len(roots) > 1:
                split = {}
                for m in drawn:
                    split.setdefault(f(('pin', m)), []).append(m)
                parts = list(split.values())
                if len(drawn) > 1:
                    self.errors.append(f'net {net} is SPLIT in the drawing: {parts}')
            for r in roots:
                extra = {p for p in groups.get(r, set()) if self.pin_net.get(p) != net}
                if extra:
                    self.errors.append(f'net {net} is SHORTED to {sorted(extra)} in the drawing')
                wrong = tagnets.get(r, set()) - {net}
                if wrong:
                    self.errors.append(f'net {net} carries tag(s) {sorted(wrong)}')
            if len(drawn) == 1 and len(members) > 1:
                r = f(('pin', drawn[0]))
                if len(groups.get(r, set())) == 1 and r not in tagnets:
                    others = [m for m in members if m not in self.pins]
                    self.warnings.append(f'pin {drawn[0]} (net {net}) is drawn but goes nowhere; tag it or wire it (other end: {others[:3]})')
        nc = set(self.spec.get('nc', []))
        for k in self.pins:
            if k not in self.pin_net:
                g = groups.get(f(('pin', k)), {k})
                if len(g) > 1 or f(('pin', k)) in tagnets:
                    self.errors.append(f'pin {k} is not in any circuit net but is connected in the drawing to {sorted(g - {k})}')
        for k in nc:
            if k in self.pin_net:
                self.errors.append(f'pin {k} is marked NC on the sheet but is in net {self.pin_net[k]}')
        return not self.errors

    def wdesc(self, w):
        fmt = lambda e: e if isinstance(e, str) else f'({e[0]},{e[1]})'
        return f'{fmt(w["from"])}→{fmt(w["to"])}'


def _cross(p1, p2, p3, p4):
    def o(a, b, c):
        v = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
        return 0 if abs(v) < 1e-9 else (1 if v > 0 else -1)
    return o(p1, p2, p3) * o(p1, p2, p4) < 0 and o(p3, p4, p1) * o(p3, p4, p2) < 0


# ---------------------------------------------------------------- render
class Renderer:
    def __init__(self, S):
        self.S = S
        self.o = []
        self.maxy = 0

    def a(self, s):
        self.o.append(s)

    def text(self, x, y, t, size=12, c=INK, anchor='start', weight='normal', rot=None):
        tr = f' transform="rotate({rot} {x} {y})"' if rot is not None else ''
        self.a(f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" fill="{c}" text-anchor="{anchor}" font-weight="{weight}"{tr}>{html.escape(str(t))}</text>')
        self.maxy = max(self.maxy, y)

    def poly(self, pts, c=INK, w=2.5, dash=None):
        d = f' stroke-dasharray="{dash}"' if dash else ''
        self.a(f'<polyline points="{" ".join(f"{x},{y}" for x, y in pts)}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linejoin="round" stroke-linecap="round"{d}/>')
        self.maxy = max([self.maxy] + [p[1] for p in pts])

    def render(self):
        S = self.S
        sp = S.spec
        W = sp.get('canvas', {}).get('w', 1500)
        body = []
        self.o = body
        for pnl in sp.get('panels', []):
            self.panel(pnl)
        for d in sp.get('decor', []):
            if not d.get('front'):
                self.decor(d)
        for w in S.wires:
            self.wire(w)
        for s in S.symbols:
            self.symbol(s)
        for d in sp.get('decor', []):
            if d.get('front'):
                self.decor(d)
        for t in S.tags:
            self.tag(t)
        for j in S.junctions:
            self.a(f'<circle cx="{j[0]}" cy="{j[1]}" r="4" fill="{INK}"/>')
        for k in sp.get('nc', []):
            x, y = S.pins[k]
            self.a(f'<path d="M{x - 5},{y - 5} L{x + 5},{y + 5} M{x - 5},{y + 5} L{x + 5},{y - 5}" stroke="{MUTED}" stroke-width="2"/>')
        for t in sp.get('texts', []):
            self.text(t['at'][0], t['at'][1], t['text'], t.get('size', 11), self.S.color(t.get('color'), MUTED), t.get('anchor', 'start'), t.get('weight', 'normal'))
        content_bottom = max(self.maxy, *(S.pins[k][1] for k in S.pins)) + 40 if S.pins else self.maxy + 40
        footer = []
        self.o = footer
        y = sp.get('tables_at', content_bottom + 20)
        h_tables = self.tables(y, W)
        H = int(y + h_tables + 40)
        head = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" font-family="Helvetica, Arial, sans-serif">',
                f'<rect width="{W}" height="{H}" fill="#FFFFFF"/>']
        self.o = head
        self.text(40, 42, sp.get('title', 'Schematic'), 22, INK, weight='bold')
        subs = sp.get('subtitle', [])
        for i, line in enumerate(subs if isinstance(subs, list) else [subs]):
            self.text(40, 66 + i * 18, line, 13, MUTED)
        return '\n'.join(head + body + footer + ['</svg>'])

    def panel(self, p):
        x, y, w, h = p['rect']
        mains = p.get('style') == 'mains'
        fill, stroke = ('#FEF2F2', '#B91C1C') if mains else ('#F9FAFB', '#D1D5DB')
        dash = ' stroke-dasharray="8,5"' if mains else ''
        self.a(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="{fill}" stroke="{stroke}" stroke-width="1.5"{dash}/>')
        if p.get('label'):
            self.text(x + 16, y + 22, p['label'], 12, stroke if mains else MUTED, weight='bold')
        for i, line in enumerate(p.get('sub', [])):
            self.text(x + 16, y + 38 + i * 14, line, 10, stroke if mains else MUTED)
        self.maxy = max(self.maxy, y + h)

    def decor(self, d):
        S = self.S
        if 'line' in d:
            self.poly([tuple(p) for p in d['line']], S.color(d.get('color'), MUTED), d.get('w', 1.5), '6,5' if d.get('dash') else None)
        if 'rect' in d:
            x, y, w, h = d['rect']
            dash = ' stroke-dasharray="4,3"' if d.get('dash') else ''
            self.a(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{d.get("rx", 4)}" fill="{d.get("fill", "none")}" fill-opacity="{d.get("opacity", 1)}" stroke="{d.get("stroke", MUTED)}" stroke-width="{d.get("sw", 1.5)}"{dash}/>')
        if 'circle' in d:
            cx, cy, rr = d['circle']
            self.a(f'<circle cx="{cx}" cy="{cy}" r="{rr}" fill="{d.get("fill", "#fff")}" stroke="{d.get("stroke", INK)}" stroke-width="1.5"/>')

    def wire(self, w):
        c = self.S.wire_color(w)
        self.poly(w['pts'], c, w.get('w', 2.5), '7,4' if w.get('dash') else None)
        if w.get('label'):
            if 'label_at' in w:
                lx, ly = w['label_at']
            else:
                segs = list(zip(w['pts'], w['pts'][1:]))
                a, b = max(segs, key=lambda s: math.dist(*s))
                lx, ly = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2 - 8
            self.text(lx, ly, w['label'], 10.5, c, 'middle', 'bold')

    def tag(self, t):
        S = self.S
        st = S.styles.get(t['net'], {})
        c, fill = st.get('color', '#374151'), st.get('fill', '#E5E7EB')
        label = st.get('tag_label', t['net'])
        if t['base'] != t['end']:
            self.poly([t['base'], t['end']], c, 2.5)
        wd = max(46, 8 * len(label) + 14)
        hh = 20
        x, y = t['end']
        side = t.get('side', 'right')
        bx = {'right': x, 'left': x - wd, 'up': x - wd / 2, 'down': x - wd / 2}[side]
        by = {'right': y - hh / 2, 'left': y - hh / 2, 'up': y - hh, 'down': y}[side]
        self.a(f'<rect x="{bx}" y="{by}" width="{wd}" height="{hh}" rx="10" fill="{fill}" stroke="{c}" stroke-width="1.5"/>')
        self.text(bx + wd / 2, by + 14, label, 11, c, 'middle', 'bold')
        self.maxy = max(self.maxy, by + hh)

    def symbol(self, s):
        k = s['kind']
        S = self.S
        part = S.cparts.get(s['ref'], {})
        val = s.get('value', part.get('value', part.get('type', '') if k in TWO_PIN else ''))
        if k in TWO_PIN:
            pins = S.symbol_pins(s)
            names = s.get('pins', TWO_PIN[k])
            p1, p2 = pins[names[0]], pins[names[1]]
            c = s.get('color') and S.color(s['color']) or S.net_color(S.pin_net.get(f'{s["ref"]}.{names[0]}', ''), INK)
            self.two_pin(k, p1, p2, c)
            mx, my = (p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2
            vertical = abs(p2[1] - p1[1]) > abs(p2[0] - p1[0])
            side = s.get('label_side', 'right' if vertical else 'above')
            if 'label_at' in s:
                lx, ly = s['label_at']
                an = s.get('label_anchor', 'start')
                self.text(lx, ly, s['ref'], 12, INK, an, 'bold')
                if val:
                    self.text(lx, ly + 15, val, 11, MUTED, an)
            elif side in ('right', 'left'):
                off = 18 if k in ('cap', 'film', 'elec') else 14
                lx = mx + off if side == 'right' else mx - off
                an = 'start' if side == 'right' else 'end'
                self.text(lx, my - 2, s['ref'], 12, INK, an, 'bold')
                if val:
                    self.text(lx, my + 13, val, 11, MUTED, an)
            else:
                ly = my - 16 if side == 'above' else my + 26
                self.text(mx, ly, f'{s["ref"]}  {val}'.strip(), 12, INK, 'middle', 'bold')
        elif k == 'nmos':
            self.nmos(s, val)
        elif k == 'switch':
            self.switch(s)
        elif k == 'block':
            self.block(s, part)
        elif k == 'note':
            pass

    def two_pin(self, k, p1, p2, c):
        L = math.dist(p1, p2)
        ang = math.degrees(math.atan2(p2[1] - p1[1], p2[0] - p1[0]))
        g = f'<g transform="translate({p1[0]},{p1[1]}) rotate({ang:.1f})">'
        if k == 'resistor':
            z0, z1, n = L * 0.2, L * 0.8, 6
            st = (z1 - z0) / n
            pts = [(0, 0), (z0, 0)] + [(z0 + st * (i + .5), -8 if i % 2 == 0 else 8) for i in range(n)] + [(z1, 0), (L, 0)]
            self.a(g + f'<polyline points="{" ".join(f"{x:.1f},{y}" for x, y in pts)}" fill="none" stroke="{c}" stroke-width="2.5" stroke-linejoin="round"/></g>')
        elif k in ('cap', 'film', 'elec'):
            m = L / 2
            self.a(g + f'<line x1="0" y1="0" x2="{m - 5}" y2="0" stroke="{c}" stroke-width="2.5"/>'
                   f'<line x1="{m + 5}" y1="0" x2="{L}" y2="0" stroke="{c}" stroke-width="2.5"/>'
                   f'<line x1="{m - 5}" y1="-14" x2="{m - 5}" y2="14" stroke="{INK}" stroke-width="3"/>')
            if k == 'elec':
                self.a(f'<path d="M{m + 9},-14 Q{m + 1},0 {m + 9},14" fill="none" stroke="{INK}" stroke-width="3"/>'
                       f'<text x="{m - 14}" y="-10" font-size="13" fill="#DC2626" font-weight="bold" text-anchor="middle">+</text></g>')
            else:
                self.a(f'<line x1="{m + 5}" y1="-14" x2="{m + 5}" y2="14" stroke="{INK}" stroke-width="3"/></g>')
        elif k == 'diode':
            m = L / 2
            self.a(g + f'<line x1="0" y1="0" x2="{m - 14}" y2="0" stroke="{c}" stroke-width="2.5"/>'
                   f'<line x1="{m + 14}" y1="0" x2="{L}" y2="0" stroke="{c}" stroke-width="2.5"/>'
                   f'<path d="M{m - 14},-12 L{m - 14},12 L{m + 12},0 Z" fill="{INK}"/>'
                   f'<line x1="{m + 14}" y1="-13" x2="{m + 14}" y2="13" stroke="{INK}" stroke-width="3"/></g>')
        self.maxy = max(self.maxy, p1[1], p2[1])

    def nmos(self, s, val):
        x, y = s['at']
        m = -1 if s.get('mirror') else 1
        gx = x + 20 * m
        cx = x + 30 * m
        self.a(f'<line x1="{x}" y1="{y}" x2="{gx}" y2="{y}" stroke="{INK}" stroke-width="2.5"/>')
        self.a(f'<line x1="{gx}" y1="{y - 22}" x2="{gx}" y2="{y + 22}" stroke="{INK}" stroke-width="3"/>')
        for yy in (-22, -5, 12):
            self.a(f'<line x1="{cx}" y1="{y + yy}" x2="{cx}" y2="{y + yy + 10}" stroke="{INK}" stroke-width="3"/>')
        px = x + 60 * m
        self.poly([(cx, y - 17), (px, y - 17), (px, y - 60)], INK)
        self.poly([(cx, y + 17), (px, y + 17), (px, y + 60)], INK)
        self.poly([(cx, y), (px, y), (px, y + 17)], INK)
        self.a(f'<path d="M{cx + 2 * m},{y} l{10 * m},-5 l0,10 z" fill="{INK}"/>')
        tx = px + 12 * m
        an = 'start' if m > 0 else 'end'
        self.text(tx, y + 32, f'{s["ref"]}  {val}'.strip(), 12, INK, an, 'bold')
        if s.get('sub'):
            for i, line in enumerate(s['sub']):
                self.text(tx, y + 47 + i * 13, line, 10, MUTED, an)

    def switch(self, s):
        x, y = s['at']
        m = -1 if s.get('mirror') else 1
        no, nc = (x + 80 * m, y - 30), (x + 80 * m, y + 35)
        for p, col in (((x, y), INK), (no, INK), (nc, MUTED)):
            self.a(f'<circle cx="{p[0]}" cy="{p[1]}" r="5" fill="#fff" stroke="{col}" stroke-width="2"/>')
        closed = s.get('closed', False)
        tip = (no[0] - 6 * m, no[1] + 3) if closed else (no[0] - 12 * m, no[1] + 14)
        self.a(f'<line x1="{x + 4 * m}" y1="{y - 2}" x2="{tip[0]}" y2="{tip[1]}" stroke="{INK}" stroke-width="3"/>')
        an_out = 'start' if m > 0 else 'end'
        self.text(x - 8 * m, y + 18, 'COM', 10, INK, 'end' if m > 0 else 'start', 'bold')
        self.text(no[0] + 10 * m, no[1] - 6, 'NO', 10, INK, an_out, 'bold')
        self.text(nc[0] + 10 * m, nc[1] + 4, 'NC', 10, MUTED, an_out)
        if s.get('title'):
            self.text(x + 40 * m, y - 52, s['title'], 11, INK, 'middle', 'bold')

    def block(self, s, part):
        S = self.S
        g = S.block_geom(s)
        x, y, w, h = g['x'], g['y'], g['w'], g['h']
        style = s.get('style', 'grey')
        fill, stroke, tc = STYLES.get(style, STYLES['grey'])
        fill, stroke, tc = s.get('fill', fill), s.get('stroke', stroke), s.get('text_color', tc)
        self.a(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{6 if style == "ic" else 10}" fill="{fill}" stroke="{stroke}" stroke-width="{2 if style in ("ic", "module") else 1.5}"/>')
        if style == 'ic':
            self.a(f'<path d="M{x + w / 2 - 12},{y} A12,12 0 0,0 {x + w / 2 + 12},{y}" fill="#FFFFFF" stroke="{stroke}" stroke-width="2"/>')
            self.a(f'<circle cx="{x + 14}" cy="{y + 16}" r="4" fill="{stroke}"/>')
        labels = dict(part.get('pin_names', {}), **s.get('labels', {}))
        numbers = s.get('numbers', style == 'ic')
        dark = style == 'module'
        for pin, (px, py) in g['pins'].items():
            side = g['sides'][pin]
            key = f'{s["ref"]}.{pin}'
            used = key in S.pin_net
            col = INK if used else '#9CA3AF'
            name = labels.get(pin, re.sub(r'_\d+$', '', pin))
            if s.get('hide_pin_labels'):
                name = ''
            if side == 'left':
                self.poly([(px, py), (x, py)], col, 2)
                if numbers:
                    self.text(x + 6, py + 4, re.sub(r'^p', '', pin), 10, stroke, 'start', 'bold')
                    self.text(x + 22, py + 4, name, 11, INK)
                else:
                    self.text(x + 8, py + 4, name, 11, ('#FDE68A' if used else '#9CA3AF') if dark else (tc if used else '#9CA3AF'), 'start', 'bold' if used else 'normal')
            elif side == 'right':
                self.poly([(x + w, py), (px, py)], col, 2)
                if numbers:
                    self.text(x + w - 6, py + 4, re.sub(r'^p', '', pin), 10, stroke, 'end', 'bold')
                    self.text(x + w - 22, py + 4, name, 11, INK, 'end')
                else:
                    self.text(x + w - 8, py + 4, name, 11, ('#FDE68A' if used else '#9CA3AF') if dark else (tc if used else '#9CA3AF'), 'end', 'bold' if used else 'normal')
            elif side == 'top':
                self.poly([(px, py), (px, y)], col, 2)
                self.text(px, y + 16, name, 10, tc, 'middle', 'bold')
            else:
                self.poly([(px, y + h), (px, py)], col, 2)
                self.text(px, y + h - 8, name, 10, tc, 'middle', 'bold')
        title = s.get('title', f'{s["ref"]}  {part.get("type", "")}'.strip())
        subs = s.get('sub', [])
        if style == 'ic':
            self.text(x + w / 2, y + h + 22, title, 13, INK, 'middle', 'bold')
            for i, line in enumerate(subs):
                self.text(x + w / 2, y + h + 38 + i * 13, line, 10, MUTED, 'middle')
        else:
            ty = s.get('title_y', y + 20)
            if s.get('title_rotate'):
                cy = s.get('title_y', y + h / 2)
                self.text(x + w / 2 + 5, cy, title, 15, tc, 'middle', 'bold', rot=s['title_rotate'])
                subs = []
            else:
                self.text(x + w / 2, ty, title, 13, tc, 'middle', 'bold')
            for i, line in enumerate(subs):
                self.text(x + w / 2, ty + 16 + i * 14, line, 10, '#D1D5DB' if dark else MUTED, 'middle')
        self.maxy = max(self.maxy, y + h)

    # -- tables
    def tables(self, y0, W):
        S = self.S
        sp = S.spec
        drawn = [s['ref'] for s in S.symbols if s['kind'] != 'note']
        legend_nets = []
        for w in S.wires:
            for e in (w['from'], w['to']):
                n = S.pin_net.get(e) if isinstance(e, str) else None
                if n and n not in legend_nets and n in S.styles:
                    legend_nets.append(n)
        tag_nets = []
        for t in S.tags:
            if t['net'] not in tag_nets:
                tag_nets.append(t['net'])
        # legend column
        x = 40
        self.text(x, y0, 'Wire colours', 13, INK, weight='bold')
        yy = y0 + 22
        shown = set()
        for n in legend_nets:
            c = S.net_color(n)
            lab = S.styles[n].get('label', n)
            if (c, lab) in shown:
                continue
            shown.add((c, lab))
            self.poly([(x, yy - 4), (x + 30, yy - 4)], c, 3)
            self.text(x + 40, yy, lab, 11)
            yy += 20
        yy += 8
        for n in tag_nets:
            st = S.styles.get(n, {})
            c, fill = st.get('color', '#374151'), st.get('fill', '#E5E7EB')
            lab = st.get('tag_label', n)
            wd = max(46, 8 * len(lab) + 14)
            self.a(f'<rect x="{x}" y="{yy - 14}" width="{wd}" height="20" rx="10" fill="{fill}" stroke="{c}" stroke-width="1.5"/>')
            self.text(x + wd / 2, yy, lab, 11, c, 'middle', 'bold')
            self.text(x + wd + 10, yy, st.get('tag_note', f'= every {lab} tag is one connection'), 11)
            yy += 26
        legend_h = yy - y0
        # parts table
        tx = sp.get('parts_table_x', 330)
        rows = []
        order = sp.get('parts_table', [r for r in dict.fromkeys(drawn)])
        for ref in order:
            p = S.cparts.get(ref, {})
            if p.get('table') is False or ref in sp.get('parts_table_exclude', []):
                continue
            pins_on = sorted({m.split('.', 1)[1] for m in S.pin_net if m.split('.', 1)[0] == ref})
            if p.get('connects'):
                conn = p['connects']
            elif len(pins_on) <= 3:
                conn = ' · '.join(f'{pn}: {S.pin_net[f"{ref}.{pn}"]}' for pn in pins_on)
            else:
                conn = 'see pin labels'
            rows.append((ref, p.get('type', ''), p.get('identify', p.get('value', '')), conn))
        if rows:
            cols = [0, 70, 300, 520]
            self.text(tx, y0, 'Parts', 13, INK, weight='bold')
            for j, hd in enumerate(['Ref', 'Part', 'Value / how to identify', 'Connects']):
                self.text(tx + cols[j], y0 + 22, hd, 11, MUTED, weight='bold')
            twidth = sp.get('parts_table_w', 780)
            self.a(f'<line x1="{tx}" y1="{y0 + 28}" x2="{tx + twidth}" y2="{y0 + 28}" stroke="#D1D5DB"/>')
            for i, r in enumerate(rows):
                ry = y0 + 44 + i * 18
                if i % 2 == 0:
                    self.a(f'<rect x="{tx - 4}" y="{ry - 13}" width="{twidth + 8}" height="18" fill="#F3F4F6"/>')
                for j, cell in enumerate(r):
                    self.text(tx + cols[j], ry, cell, 11, INK, weight='bold' if j == 0 else 'normal')
        table_h = 44 + len(rows) * 18
        # checklist
        ck = sp.get('checklist', [])
        ck_h = 0
        if ck:
            cx = sp.get('checklist_x', W - 380)
            self.text(cx, y0, sp.get('checklist_title', 'Check before power-up'), 13, INK, weight='bold')
            lines = []
            for item in ck:
                lines += _wrap(item, sp.get('checklist_wrap', 46))
            for i, line in enumerate(lines):
                self.text(cx, y0 + 22 + i * 17, line, 11)
            ck_h = 22 + len(lines) * 17
        notes = sp.get('notes', [])
        base = max(legend_h, table_h, ck_h) + 20
        for i, n in enumerate(notes):
            self.text(40, y0 + base + i * 18, n, 11, MUTED)
        return base + len(notes) * 18


def _wrap(s, n):
    words, lines, cur = s.split(), [], ''
    for w in words:
        if len(cur) + len(w) + 1 > n and cur:
            lines.append(cur)
            cur = '  ' + w
        else:
            cur = (cur + ' ' + w).strip() if not cur.startswith('  ') else cur + ' ' + w
    if cur:
        lines.append(cur)
    return lines


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(2)
    path = sys.argv[1]
    try:
        S = Sheet(load_json(path), os.path.dirname(os.path.abspath(path)))
        ok = S.check()
    except SpecError as e:
        print('SPEC ERROR:', e)
        sys.exit(1)
    for w in S.warnings:
        print('WARNING:', w)
    for e in S.errors:
        print('ERROR:', e)
    print('DRAWING MATCHES CIRCUIT' if ok else 'DRAWING DOES NOT MATCH CIRCUIT')
    if not ok:
        sys.exit(1)
    if '--check-only' not in sys.argv:
        with open(sys.argv[2], 'w') as f:
            f.write(Renderer(S).render())
        print('wrote', sys.argv[2])


if __name__ == '__main__':
    main()
