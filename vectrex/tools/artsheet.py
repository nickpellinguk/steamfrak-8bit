#!/usr/bin/env python3
"""
A sheet comparing each piece of line art with the sprite it's drawn from:

    python3 vectrex/tools/artsheet.py [../steamfrak] [OUT.png]

For each shape: the BBC sprite, enlarged; the polylines over it (each polyline its own colour,
dots as rings); and the shape through the beam model (beam.py) at about its size on the screen and
enlarged. Under each: how many vectors it takes, drawn and blank.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', 'art'))
import beam      # noqa: E402
import shapes    # noqa: E402

K = 12              # enlargement of the sprite
SHAPES = [('trogg', 'sTrogg_sr_Beeb', shapes.TROGG_SR), ('scrubbly', 'sScrubbly_Beeb', shapes.SCRUBBLY)]
POLY_COLOURS = [(255, 80, 80), (80, 220, 255), (120, 255, 120), (255, 200, 60), (230, 120, 255),
                (255, 255, 255), (255, 140, 200), (140, 160, 255)]
# beam units a level pixel, with a 256-pixel-wide window across the screen
UNIT = beam.SCREEN_X / 256


def panel(web, name, sprite, polys, speed):
    im = Image.open(os.path.join(web, 'assets', 'sprites', sprite + '.png')).convert('RGBA')
    if im.width > 40:                                   # (animation strips: the first frame)
        n = {'sTrogg_wr_Beeb': 4}.get(sprite, 1)
        im = im.crop((0, 0, im.width // n, im.height))
    w, h = im.size
    big = Image.new('RGBA', (w * K, h * K), (40, 40, 52, 255))
    big.alpha_composite(im.resize((w * K, h * K), Image.NEAREST))
    over = Image.new('RGBA', (w * K, h * K), (20, 20, 28, 255))
    faint = im.resize((w * K, h * K), Image.NEAREST)
    faint.putalpha(faint.getchannel('A').point(lambda a: a * 45 // 255))
    over.alpha_composite(faint)
    d = ImageDraw.Draw(over)
    c = lambda p: (p[0] * K + K // 2, p[1] * K + K // 2)
    for i, poly in enumerate(polys):
        col = POLY_COLOURS[i % len(POLY_COLOURS)]
        if len(poly) == 1:
            x, y = c(poly[0])
            d.ellipse((x - 5, y - 5, x + 5, y + 5), outline=col, width=3)
        else:
            d.line([c(p) for p in poly], fill=col, width=3)
            x, y = c(poly[0])
            d.ellipse((x - 3, y - 3, x + 3, y + 3), fill=col)
    # through the beam model: the shape at its real size in a small patch of screen, enlarged
    margin = 6
    lines, cycles, drawn, blanks = beam.polylines_to_lines(polys, margin * UNIT, margin * UNIT, UNIT, speed)
    view = (0, 0, (w + 2 * margin) * UNIT, (h + 2 * margin) * UNIT)
    # the screen is about 14 cm wide: a 660-pixel-wide picture of it is ~ 1:1 on a monitor
    real = beam.render(lines, width=int(round((w + 2 * margin) * 660 / 256)), view=view)
    zoom = beam.render(lines, width=(w + 2 * margin) * K // 2 * 2, view=view)
    info = '%s: %d drawn vectors, %d blank moves, %d polylines; beam time %.0f cycles at speed %d' % (
        name, drawn, blanks, len(polys), cycles, speed)
    return [big, over, zoom.convert('RGBA'), real.convert('RGBA')], info


def main():
    args = [a for a in sys.argv[1:]]
    web = args[0] if args else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    out = args[1] if len(args) > 1 else 'artsheet.png'
    speed = 32
    rows = [panel(web, *s, speed) for s in SHAPES]
    gap = 16
    W = max(sum(p.width for p in ims) + gap * (len(ims) + 1) for ims, _ in rows)
    H = sum(max(p.height for p in ims) + 40 + gap for ims, _ in rows) + gap
    sheet = Image.new('RGBA', (W, H), (0, 0, 0, 255))
    d = ImageDraw.Draw(sheet)
    y = gap
    for ims, info in rows:
        x = gap
        for p in ims:
            sheet.alpha_composite(p, (x, y))
            x += p.width + gap
        y += max(p.height for p in ims) + 6
        d.text((gap, y), info, fill=(220, 220, 220))
        y += 34 + gap
    sheet.convert('RGB').save(out)
    print(out)
    for _, info in rows:
        print(info)


if __name__ == '__main__':
    main()
