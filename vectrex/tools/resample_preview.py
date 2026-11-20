#!/usr/bin/env python3
"""
The multi-pass zigzags (tools/m1_zigp_gen.py) with their bits chosen two ways, drawn from the
beam's modelled path (which vecx matches to within half a pixel): each lit pixel lighting its
nearest bit, against the sprite upsampled 8x (Scale2x) and each bit lit by how much of its patch
is lit. -> preview/resample_zigzag.png

    python3 vectrex/tools/resample_preview.py [../steamfrak]
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import m1_gen as g  # noqa: E402
import m1_zigp_gen as P  # noqa: E402

S = 8


def render(grid, npass, method):
    wp = -(-len(grid[0]) // 8) * 8
    drift = max(1, round(npass * P.SPACING * g.UNIT / (2 * wp)))
    passes, data, _ = P.plan_sprite(grid, drift, npass, regular=True, method=method)
    im = Image.new('L', ((wp + 4) * S, (len(grid) + 4) * S), 0)
    d = ImageDraw.Draw(im)
    k = 0
    for p in passes:
        nb = p['loads']
        bits = [int(c) for b in data[k:k + nb] for c in '{:08b}'.format(b)]
        k += nb
        dots = p['dots']
        for i, (x, y) in enumerate(dots):
            if bits[i]:
                a = dots[i - 1] if i else (x, y)
                b = dots[i + 1] if i + 1 < len(dots) else (x, y)
                x0, y0 = (x + a[0]) / 2, (y + a[1]) / 2
                x1, y1 = (x + b[0]) / 2, (y + b[1]) / 2
                d.line([((x0 + 2) * S, (y0 + 2) * S), ((x1 + 2) * S, (y1 + 2) * S)], fill=255, width=3)
    return im.filter(ImageFilter.GaussianBlur(1.6)), sum(p['off'] for p in passes)


def main():
    steamfrak = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    rows = []
    for name, fr in (('sTrogg_wr_Beeb', 4), ('sScrubbly_Beeb', 1), ('sPoglet_Beeb', 1), ('sHooter_Beeb', 1)):
        grid = g.sprite_grid(steamfrak, name, 0, fr)
        row = []
        for npass in (1, 2, 3):
            for method in ('nearest', 'scale2x'):
                im, cyc = render(grid, npass, method)
                row.append((im, '%d pass%s, %s' % (npass, '' if npass == 1 else 'es', method)))
        rows.append(row)
    tw = max(t.width for r in rows for t, _ in r)
    th = [max(t.height for t, _ in r) + 20 for r in rows]
    out = Image.new('RGB', (tw * 6, sum(th)), (0, 0, 0))
    dr = ImageDraw.Draw(out)
    try:
        font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 14)
    except OSError:
        font = None
    y = 0
    for r, hh in zip(rows, th):
        for i, (t, label) in enumerate(r):
            out.paste(Image.merge('RGB', (t.point(lambda v: v * 0.6), t, t.point(lambda v: v * 0.7))), (i * tw, y + 20))
            dr.text((i * tw + 6, y + 3), label, fill=(200, 200, 200), font=font)
        y += hh
    out.save(os.path.join(HERE, '..', 'preview', 'resample_zigzag.png'))


if __name__ == '__main__':
    main()
