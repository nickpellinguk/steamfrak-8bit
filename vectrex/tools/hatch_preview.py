#!/usr/bin/env python3
"""
A crosshatch renderer, previewed (not yet 6809 code): passes down and up a sprite, the beam going
across at 0.5 pixel a cycle (X speed 80) and down or up at 0.25 (Y speed 40), so each row is a
diagonal of slope 1/2; it flips at the sprite's edges (a zigzag of diagonals), and each pass
reverses Y (one sample-and-hold write, ~50 cycles with the stores around it). The passes' lines
cross; going a little past the top or bottom before turning (a few pixels: 4 cycles each)
shifts where the next pass's lines fall, chosen so the lines spread evenly. A shift-register bit
every 2 cycles; each lit pixel lights the bit nearest it.

    python3 vectrex/tools/hatch_preview.py [../steamfrak]   -> preview/hatch.png

Flips are taken as exactly at the edges here: the real code's flips come a few cycles late (as in
tools/m1_zig_gen.py), so the cycles are a little low.
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import m1_gen as g  # noqa: E402

VX, VY = 0.5, 0.25          # pixels a cycle
TURN = 50                   # cycles for each pass's turn


def passes(w, h, n):
    """n passes: [(list of dots (x, y), cycles)], the overshoots chosen so the lines spread out."""
    out = []
    x, y, dx = 0.0, 0.0, 1
    cycles = 0
    fam = {'a': [], 'b': []}          # lines' y - x/2 and y + x/2 (the two directions)
    for p in range(n):
        down = p % 2 == 0
        best = None
        for e2, k in [(e2, k) for e2 in range(0, int(w) + 1, 2) for k in range(0, 33, 2)]:
            # e2: overshoot (half pixels) past the top or bottom; k: cycles the turn holds the ramp
            # on while the sample-and-hold takes the new Y speed: X moves at that value meanwhile
            # (40: a quarter of a pixel a cycle; to the right turning up, to the left turning down)
            e = e2 / 2
            target = h + e if down else -e
            dots, xx, yy, ddx, t = [], x + (k / 4 if (p % 2 == 1) else -k / 4) * (1 if p else 0), y, dx, 0
            segs = []
            seg_start = (xx, yy)
            while (yy < target) if down else (yy > target):
                # move 1 cycle
                xx += ddx * VX
                yy += VY if down else -VY
                t += 1
                if t % 2 == 1:
                    dots.append((xx, yy))
                if (ddx > 0 and xx >= w) or (ddx < 0 and xx <= 0):
                    segs.append((seg_start, (xx, yy), ddx))
                    seg_start = (xx, yy)
                    ddx = -ddx
            segs.append((seg_start, (xx, yy), ddx))
            # the lines this pass adds, and how evenly they fill each direction
            new = {'a': list(fam['a']), 'b': list(fam['b'])}
            for (sx, sy), _, sdx in segs:
                going_down_right = (sdx > 0) == down
                if going_down_right:
                    new['a'].append(sy - sx / 2)
                else:
                    new['b'].append(sy + sx / 2)

            def gaps(vals, lo, hi):
                v = sorted([lo] + [u for u in vals if lo <= u <= hi] + [hi])
                return sum((b - a) ** 2 for a, b in zip(v, v[1:]))
            score = gaps(new['a'], -w / 2, h) + gaps(new['b'], 0, h + w / 2) + 0.01 * e + 0.01 * k
            if best is None or score < best[0]:
                best = (score, dots, xx, yy, ddx, t + k, new)
        _, dots, x, y, dx, t, fam = best
        out.append(dots)
        cycles += t + TURN
    return out, cycles


def render(grid, n, scale, lit='#'):
    h, w = len(grid), len(grid[0])
    ps, cycles = passes(w, h, n)
    dots = [d for p in ps for d in p]
    on = set()
    for r in range(h):
        for c in range(w):
            if grid[r][c] in lit:
                i = min(range(len(dots)), key=lambda i: (dots[i][0] - c - 0.5) ** 2 + (dots[i][1] - r - 0.5) ** 2)
                on.add(i)
    im = Image.new('L', ((w + 6) * scale, (h + 6) * scale), 0)
    d = ImageDraw.Draw(im)
    k = 0
    for p in ps:
        for j, (x, y) in enumerate(p):
            if k in on:
                # a bit: the beam's travel over its 2 cycles
                prev = p[j - 1] if j else (x, y)
                x0, y0 = (x + prev[0]) / 2, (y + prev[1]) / 2
                nxt = p[j + 1] if j + 1 < len(p) else (x, y)
                x1, y1 = (x + nxt[0]) / 2, (y + nxt[1]) / 2
                d.line([((x0 + 3) * scale, (y0 + 3) * scale), ((x1 + 3) * scale, (y1 + 3) * scale)],
                       fill=255, width=max(2, scale // 3))
            k += 1
    return im.filter(ImageFilter.GaussianBlur(scale / 5)), cycles


def columns(grid, scale, lit='#'):
    h, w = len(grid), len(grid[0])
    im = Image.new('L', ((w + 6) * scale, (h + 6) * scale), 0)
    d = ImageDraw.Draw(im)
    for c in range(w):
        for r in range(h):
            if grid[r][c] in lit:
                d.line([((c + 3.5) * scale, (r + 3) * scale), ((c + 3.5) * scale, (r + 4) * scale)],
                       fill=255, width=max(2, scale // 3))
    return im.filter(ImageFilter.GaussianBlur(scale / 5))


def main():
    steamfrak = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    scale = 8
    rows = []
    for name, ns, lit, what in (('sScrubbly_Beeb', (8, 12, 16, 20), '#', 'outline'),
                                ('sScrubbly_Beeb', (6, 8, 10, 12), 'm', 'body'),
                                ('sScrubbly_Beeb', (6, 8, 10, 12), 'my', 'body and eyes'),
                                ('sPoglet_Beeb', (8, 12, 16), '#', 'outline'),
                                ('sTrogg_wr_Beeb', (8, 12, 16), '#', 'outline')):
        frames = 4 if 'wr' in name else 1
        grid = g.sprite_grid(steamfrak, name, 0, frames)
        tiles = [(columns(grid, scale), 'columns (outline)')]
        for n in ns:
            im, cyc = render(grid, n, scale, lit)
            tiles.append((im, '%s, %d passes: ~%d' % (what, n, cyc)))
        rows.append(tiles)
    tw = max(t.width for r in rows for t, _ in r)
    th = [max(t.height for t, _ in r) + 24 for r in rows]
    out = Image.new('RGB', (tw * max(len(r) for r in rows), sum(th)), (0, 0, 0))
    dr = ImageDraw.Draw(out)
    try:
        font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 16)
    except OSError:
        font = None
    y = 0
    for r, hh in zip(rows, th):
        for i, (t, label) in enumerate(r):
            out.paste(Image.merge('RGB', (t.point(lambda v: v * 0.6), t, t.point(lambda v: v * 0.7))), (i * tw, y + 24))
            dr.text((i * tw + 8, y + 4), label, fill=(200, 200, 200), font=font)
        y += hh
    path = os.path.join(HERE, '..', 'preview', 'hatch.png')
    out.save(path)
    print(path)


if __name__ == '__main__':
    main()
