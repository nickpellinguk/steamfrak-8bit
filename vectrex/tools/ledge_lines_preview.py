#!/usr/bin/env python3
"""
Ledges as a textured top line and steep parallel hatching under it, previewed (not yet 6809
code):

* the top line: one raster row (the ledge's row 0) across the whole run: 16 cycles a byte + ~70;
* the undersides (rows 4-13: the band and the stalactites, the shape taken from the ledge's
  pixels) filled with parallel lines ANGLE degrees from the horizontal, SPACING pixels apart, solid
  (the spot simply on along each line, off at the turns: no data), drawn down one line and up the
  next: the beam 0.5 pixel a cycle along Y (speed 80) and 0.5 x cot(ANGLE) along X, both turning
  at each line's end. The turns: the sample-and-hold rewritten for the new Y speed, the DAC driving
  X at that value meanwhile, which steps the beam sideways onto the next line (at the top, a jog
  first, as the new Y speed would push X the wrong way): ~TURN cycles each.

    python3 vectrex/tools/ledge_lines_preview.py [../steamfrak]   -> preview/ledge_lines.png
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import vconvert  # noqa: E402
import m1_cave_gen as cave  # noqa: E402

ANGLE = 75
TURN = 15
TOP, BOTTOM = 4, 14


def underside(tile):
    """For each x of the tile, the rows of the underside: (first, last + 1)."""
    out = []
    for x in range(16):
        rows = [r for r in range(TOP, BOTTOM) if tile[r][x] != '.']
        out.append((min(rows), max(rows) + 1) if rows else None)
    return out


def lines(tile, length, spacing, angle=ANGLE):
    """The hatch lines [(x_top, y_top, x_bottom, y_bottom)], each from the underside's top down
    to where it leaves the ledge's shape, and the cycles they take."""
    lean = 1 / math.tan(math.radians(angle))         # pixels across a pixel down
    inside = lambda x, y: 0 <= x < length and TOP <= y < BOTTOM and tile[int(y)][int(x) % 16] != '.'
    out, cycles = [], 0
    x = 0.5
    while x < length:
        if inside(x, TOP + 0.1):
            y = TOP + 0.1
            while inside(x - lean * (y - TOP), y + 0.25):
                y += 0.25
            yb = y + 0.15
            out.append((x, TOP, x - lean * (yb - TOP), yb))
            cycles += 2 * (yb - TOP) + TURN
        x += spacing
    return out, cycles


def render(tile, length, spacing, scale, angle=ANGLE):
    W, H = length + 8, 18
    im = Image.new('L', (W * scale, H * scale), 0)
    d = ImageDraw.Draw(im)
    lw = max(2, scale // 3)
    for x in range(length):
        if tile[0][x % 16] == '#':
            d.line([((x + 4) * scale, 1.5 * scale), ((x + 5) * scale, 1.5 * scale)], fill=255, width=lw)
    ls, cyc = lines(tile, length, spacing, angle)
    for xt, yt, xb, yb in ls:
        d.line([((xt + 4) * scale, (yt + 1) * scale), ((xb + 4) * scale, (yb + 1) * scale)], fill=255, width=lw)
    cyc += 16 * math.ceil(length / 8) + 70
    return im.filter(ImageFilter.GaussianBlur(scale / 5)), cyc


def strip(tile, length, scale):
    W, H = length + 8, 18
    im = Image.new('L', (W * scale, H * scale), 0)
    d = ImageDraw.Draw(im)
    for r in cave.ROWS:
        for x in range(length):
            if tile[r][x % 16] == '#':
                d.line([((x + 4) * scale, (r + 1.5) * scale), ((x + 5) * scale, (r + 1.5) * scale)],
                       fill=255, width=max(2, scale // 3))
    return im.filter(ImageFilter.GaussianBlur(scale / 5))


def main():
    steamfrak = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    tile = vconvert.grid_of(steamfrak, 'sLedge1_Beeb')
    scale, length = 8, 128
    tiles = [(strip(tile, length, scale), '8-row strip (measured: 2,875 cycles)')]
    for sp, ang in ((2, 75), (3, 75), (4, 75), (2, 84), (3, 84)):
        im, cyc = render(tile, length, sp, scale, ang)
        tiles.append((im, 'top line + parallel lines at %d degrees, %d pixels apart: ~%d cycles' % (ang, sp, cyc)))
    tw = max(t.width for t, _ in tiles)
    th = max(t.height for t, _ in tiles) + 26
    out = Image.new('RGB', (tw, th * len(tiles)), (0, 0, 0))
    dr = ImageDraw.Draw(out)
    try:
        font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 16)
    except OSError:
        font = None
    for i, (t, label) in enumerate(tiles):
        out.paste(Image.merge('RGB', (t.point(lambda v: v * 0.6), t, t.point(lambda v: v * 0.7))), (0, i * th + 26))
        dr.text((8, i * th + 4), label, fill=(200, 200, 200), font=font)
    out.save(os.path.join(HERE, '..', 'preview', 'ledge_lines.png'))
    for sp, ang in ((2, 75), (3, 75), (4, 75), (2, 84), (3, 84)):
        print('%d degrees, spacing %d: %s' % (ang, sp, ', '.join('%d pixels ~%d' % (L, render(tile, L, sp, 2, ang)[1])
                                                                   for L in (64, 128, 208))))


if __name__ == '__main__':
    main()
