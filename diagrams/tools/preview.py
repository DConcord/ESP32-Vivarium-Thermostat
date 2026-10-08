#!/usr/bin/env python3
"""Screenshot an SVG to PNG with headless Chromium so you can look at it.

Usage:
  python preview.py layout.svg out.png                 # whole drawing
  python preview.py layout.svg zoom.png --zoom X Y W H # one region, 2x size

Zoom renders are how you catch small collisions (a part body sitting on a wire,
a label over a hole); full renders at screen size hide them.
"""
import glob, os, re, shutil, subprocess, sys, tempfile


def chrome():
    for c in [os.environ.get('CHROME', '')] + sorted(glob.glob('/opt/pw-browsers/chromium-*/chrome-linux/chrome')) + \
             [shutil.which(n) or '' for n in ('chromium', 'chromium-browser', 'google-chrome', 'google-chrome-stable')] + \
             ['/Applications/Google Chrome.app/Contents/MacOS/Google Chrome']:
        if c and os.path.exists(c):
            return c
    sys.exit('No Chromium/Chrome found; set CHROME=/path/to/chrome')


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    src, out = sys.argv[1], sys.argv[2]
    svg = open(src).read()
    m = re.search(r'width="(\d+)" height="(\d+)"', svg)
    w, h = int(m.group(1)), int(m.group(2))
    if '--zoom' in sys.argv:
        i = sys.argv.index('--zoom')
        x, y, zw, zh = map(float, sys.argv[i + 1:i + 5])
        w, h = int(zw * 2), int(zh * 2)
        svg = re.sub(r'viewBox="[^"]*"', f'viewBox="{x} {y} {zw} {zh}"', svg, count=1)
        svg = re.sub(r'width="\d+" height="\d+"', f'width="{w}" height="{h}"', svg, count=1)
    with tempfile.NamedTemporaryFile('w', suffix='.svg', delete=False) as f:
        f.write(svg)
    # headless window chrome eats ~90px of height: pad so nothing is clipped
    subprocess.run([chrome(), '--headless', '--no-sandbox', '--disable-gpu', '--hide-scrollbars',
                    f'--screenshot={os.path.abspath(out)}', f'--window-size={w},{h + 120}', 'file://' + f.name],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=120)
    os.unlink(f.name)
    print('wrote', out) if os.path.exists(out) else sys.exit('screenshot failed')


if __name__ == '__main__':
    main()
