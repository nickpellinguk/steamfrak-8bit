#!/usr/bin/env python3
"""
Ledges as a textured top line and a hatch for each block, previewed (not yet 6809 code):

* the top line: one raster row (the ledge's row 0's black pixels) across the
  whole run: 16 cycles a byte + ~70;
* a gap (rows 2 and 3, blank in the ledge anyway);
* each block (a 16-pixel tile's rows 4-13: the band and the stalactite, a trapezoid 16 pixels
  wide narrowing to 8) filled by a zigzag of lines at +-22.5 degrees: X at 0.5 pixel a cycle, Y
  at 0.207 (speed 33), flipping at the trapezoid's edges; passes down and up the block in turn,
  Y reversed without stopping (one sample-and-hold write: X moves at the Y speed for its ~10
  cycles, ~2 pixels sideways); the last pass ends at the top, where the next block starts.

    python3 vectrex/tools/ledge_hatch_preview.py [../steamfrak]   -> preview/ledge_hatch.png
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import vconvert  # noqa: E402
import m1_cave_gen as cave  # noqa: E402

VX = 0.5                        # pixels a cycle across
VY = VX * math.tan(math.radians(22.5))      # down or up
SETTLE = 10                     # cycles of each reversal (X moving at the Y speed)
NUDGE = SETTLE * VY             # (the DAC's Y value drives X while the sample-and-hold settles)
TOP, BOTTOM = 4, 14             # the block's rows (4 to 13)


def extents(tile):
    out = {}
    for r in range(TOP, BOTTOM):
        xs = [x for x, ch in enumerate(tile[r]) if ch != '.']
        out[r] = (min(xs), max(xs) + 1)
    return out


def block_path(ext, x0, passes):
    """The beam's path through one block from its top left: [(x, y)] a cycle apart, and the
    cycles."""
    x, y = x0, float(TOP)
    dx = 1
    pts = [(x, y)]
    for p in range(passes):
        down = p % 2 == 0
        while (y < BOTTOM) if down else (y > TOP):
            x += dx * VX
            y += VY if down else -VY
            pts.append((x, y))
            r = min(BOTTOM - 1, max(TOP, int(y)))
            lo, hi = ext[r]
            if (dx > 0 and x >= x0 + hi) or (dx < 0 and x <= x0 + lo):
                dx = -dx
        if p < passes - 1:
            for _ in range(SETTLE):     # the reversal: X moves at the Y speed meanwhile
                x += (VY if down else -VY)
                pts.append((x, y))
    # the last pass ends at the top; then on to the next block's top left (x0 + 16)
    return pts


def render_run(tile, length, passes, scale):
    ext = extents(tile)
    W, H = length + 8, 18
    im = Image.new('L', (W * scale, H * scale), 0)
    d = ImageDraw.Draw(im)
    lw = max(2, scale // 3)
    # the top line
    for x in range(length):
        if tile[0][x % 16] == '#':
            d.line([((x + 4) * scale, 1.5 * scale), ((x + 5) * scale, 1.5 * scale)], fill=255, width=lw)
    cycles = 16 * math.ceil(length / 8) + 70
    # the blocks
    x_beam = 0.0
    for b in range(length // 16):
        x0 = 16 * b
        cycles += max(0, 2 * abs(x0 - x_beam))           # (a short move if the last block ended short)
        pts = block_path(ext, x0, passes)
        for (xa, ya), (xb, yb) in zip(pts, pts[1:]):
            r = min(BOTTOM - 1, max(TOP, int((ya + yb) / 2)))
            lo, hi = ext[r]
            on = abs(xb - xa) > 0.4 and x0 + lo - 0.25 <= (xa + xb) / 2 <= x0 + hi + 0.25
            if on:
                d.line([((xa + 4) * scale, (ya + 1) * scale), ((xb + 4) * scale, (yb + 1) * scale)],
                       fill=255, width=lw)
        cycles += len(pts) - 1 + 16 * (passes - 1) + 20
        x_beam = pts[-1][0]
    return im.filter(ImageFilter.GaussianBlur(scale / 5)), cycles


def render_strip(tile, length, scale):
    """Milestone 1's 8-row strip, for comparison."""
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
    tiles = [(render_strip(tile, length, scale), '8-row strip (measured: 2,875 cycles)')]
    for passes in (2, 4, 6):
        im, cyc = render_run(tile, length, passes, scale)
        tiles.append((im, 'top line + hatch, %d passes a block: ~%d cycles' % (passes, cyc)))
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
    path = os.path.join(HERE, '..', 'preview', 'ledge_hatch.png')
    out.save(path)
    for passes in (2, 4, 6):
        for L in (64, 128, 208):
            print('%d passes, %d pixels: ~%d cycles' % (passes, L, render_run(tile, L, passes, 2)[1]))


if __name__ == '__main__':
    main()
