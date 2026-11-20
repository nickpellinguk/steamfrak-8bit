#!/usr/bin/env python3
"""
Upsampling pixel art before sampling it on a renderer's own grid (zigzags, multi-pass zigzags,
anything whose dots fall between the original pixels).

* upsample(): the lit pixels upscaled 2x at a time by Scale2x (EPX: thin lines kept, diagonal
  steps rounded into slopes) to UP (8x by default).
* coverage(): how much of a dot's patch (centred on the dot, W pixels along its row, H across)
  is lit in the upsampled image: 0 to 1.

    python3 vectrex/tools/resample.py [../steamfrak]   -> preview/resample.png: the sprites, 8x
"""
import os
import sys

UP = 8


def scale2x(m):
    """Scale2x (EPX) on a 0/1 grid."""
    h, w = len(m), len(m[0])
    out = [[0] * (2 * w) for _ in range(2 * h)]
    for y in range(h):
        for x in range(w):
            p = m[y][x]
            a = m[y - 1][x] if y > 0 else 0
            b = m[y][x + 1] if x + 1 < w else 0
            c = m[y][x - 1] if x > 0 else 0
            d = m[y + 1][x] if y + 1 < h else 0
            e0 = a if (c == a and c != d and a != b) else p
            e1 = b if (a == b and a != c and b != d) else p
            e2 = c if (d == c and d != b and c != a) else p
            e3 = d if (b == d and b != a and d != c) else p
            out[2 * y][2 * x], out[2 * y][2 * x + 1] = e0, e1
            out[2 * y + 1][2 * x], out[2 * y + 1][2 * x + 1] = e2, e3
    return out


def upsample(grid, lit='#', times=3):
    m = [[1 if ch in lit else 0 for ch in row] for row in grid]
    for _ in range(times):
        m = scale2x(m)
    return m


def coverage(up, x, y, w=1.0, h=1.0, factor=UP):
    """The lit fraction of the patch centred on (x, y) (original pixels), w across, h down."""
    H, W = len(up), len(up[0])
    x0, x1 = int(round((x - w / 2) * factor)), int(round((x + w / 2) * factor))
    y0, y1 = int(round((y - h / 2) * factor)), int(round((y + h / 2) * factor))
    tot = lit = 0
    for yy in range(y0, max(y1, y0 + 1)):
        for xx in range(x0, max(x1, x0 + 1)):
            tot += 1
            if 0 <= yy < H and 0 <= xx < W and up[yy][xx]:
                lit += 1
    return lit / tot if tot else 0.0


def main():
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import m1_gen as g
    from PIL import Image
    steamfrak = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                                   '..', '..', '..', 'steamfrak')
    tiles = []
    for name, fr in (('sTrogg_wr_Beeb', 4), ('sScrubbly_Beeb', 1), ('sPoglet_Beeb', 1), ('sHooter_Beeb', 1)):
        up = upsample(g.sprite_grid(steamfrak, name, 0, fr))
        im = Image.new('L', (len(up[0]), len(up)), 0)
        im.putdata([255 if v else 0 for row in up for v in row])
        tiles.append(im)
    out = Image.new('L', (sum(t.width for t in tiles) + 10 * len(tiles), max(t.height for t in tiles)), 0)
    x = 0
    for t in tiles:
        out.paste(t, (x, 0))
        x += t.width + 10
    out.save(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'preview', 'resample.png'))


if __name__ == '__main__':
    main()
