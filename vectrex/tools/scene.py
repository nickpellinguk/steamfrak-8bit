#!/usr/bin/env python3
"""
A picture of a level as the Vectrex version might draw it, through the beam model (beam.py):

    python3 vectrex/tools/scene.py [--steamfrak DIR] [--level room_A_1] [--x0 0] [--y0 0]
                                   [--scenery-speed 127] [--actor-speed 32] [--out scene.png]

The window is 256 level pixels square, across the width of the (portrait) screen, with room above
and below it for the timer and so on. Platforms are a line along their tops, ladders a pole with
a rung every 14 pixels, chains a zigzag; gems, keys and the meanies are the line art in
vectrex/art/shapes.py (meanies other than the Scrubbly are drawn as Scrubblies for now). The
scenery is drawn at one speed and the actors at another, both at full intensity, so the
difference in brightness is the difference in speed.

It also prints the beam time, the vector counts and a cycle estimate with budget.py's overheads.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', 'art'))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import beam      # noqa: E402
import budget    # noqa: E402
import convert   # noqa: E402
import shapes    # noqa: E402

WINDOW = 256
UNIT = beam.SCREEN_X / WINDOW
TOP = (beam.SCREEN_Y - WINDOW * UNIT) / 2          # the window's top, centred on the screen


def scenery_polys(lev, data, x0, y0):
    """Polylines (level pixels) for the platforms and ladders in the window."""
    polys = []
    inside = lambda x, y: x0 - 8 <= x < x0 + WINDOW + 8 and y0 - 8 <= y < y0 + WINDOW + 8
    moving = {v['plat'] for v in lev['slow'] if v['kind'] == convert.SL_PLATFORM}
    for i, (px, py, pw, ph) in enumerate(lev['plats']):
        a, b = max(px, x0), min(px + pw, x0 + WINDOW)
        if a < b and y0 <= py < y0 + WINDOW and i not in moving:
            polys.append([(a, py), (b, py)])
    for (spr, _), (lx, ly, lh, ext) in zip(lev['ladder_spr'], lev['ladders']):
        info = data.sprites[spr]
        cx = lx - info['xo'] + info['w'] // 2
        top, bottom = ly + ext, ly + lh                 # (the drawn part, not the hidden extension)
        top_c, bottom_c = max(top, y0), min(bottom, y0 + WINDOW)
        if top_c >= bottom_c or not inside(cx, top_c):
            continue
        if 'Chain' in spr:
            zig, y, side = [], top_c, -2
            while y < bottom_c:
                zig.append((cx + side, y))
                y, side = y + 7, -side
            zig.append((cx, bottom_c))
            polys.append(zig)
        else:
            polys.append([(cx, top_c), (cx, bottom_c)])
            for ry in range(top + 6, bottom, 14):
                if top_c <= ry < bottom_c:
                    polys.append([(cx - 5, ry), (cx + 5, ry)])
    return polys


def actor_polys(lev, data, x0, y0):
    """(polylines, origin) for each actor in the window: Trogg, the meanies, gems and keys."""
    out = []

    def place(polys, origin, x, y):
        return [[(x + px - origin[0], y + py - origin[1]) for px, py in p] for p in polys]

    def near(x, y):
        return x0 - 32 <= x < x0 + WINDOW + 32 and y0 - 48 <= y < y0 + WINDOW + 48

    tx, ty = lev['trogg']
    out.append(place(shapes.TROGG_SR, shapes.ORIGIN['trogg'], tx, ty))
    for depth, _, spr, x, y, obj in lev['draw']:
        if depth in convert.CACHE_BG_DEPTHS or not near(x, y):
            continue
        info = data.sprites[spr]
        if 'Gem' in spr:
            out.append(place(shapes.GEM, (info['xo'], info['yo']), x, y))
        elif 'Key' in spr:
            out.append(place(shapes.KEY, (info['xo'], info['yo']), x, y))
        else:
            out.append(place(shapes.SCRUBBLY, shapes.ORIGIN['scrubbly'], x, y))
    for v in lev['slow']:
        if v['kind'] == convert.SL_PLATFORM:
            info = data.sprites[v['spr']]
            out.append([[(v['x'], v['y']), (v['x'] + info['w'], v['y'])]])
        elif near(v['x'], v['y']):
            out.append(place(shapes.SCRUBBLY, shapes.ORIGIN['scrubbly'], v['x'], v['y']))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--steamfrak', default=os.path.join(HERE, '..', '..', '..', 'steamfrak'))
    ap.add_argument('--level', default='room_A_1')
    ap.add_argument('--x0', type=int, default=0)
    ap.add_argument('--y0', type=int, default=0)
    ap.add_argument('--scenery-speed', type=float, default=127)
    ap.add_argument('--actor-speed', type=float, default=32)
    ap.add_argument('--out', default='scene.png')
    ap.add_argument('--width', type=int, default=660)
    a = ap.parse_args()

    data = convert.Data(a.steamfrak)
    lev = convert.build_level(data, a.level)
    ox, oy = -a.x0 * UNIT, TOP - a.y0 * UNIT

    lines, beam_time, vectors, blanks, objects = [], 0.0, 0, 0, 0
    l, c, d, b = beam.polylines_to_lines(scenery_polys(lev, data, a.x0, a.y0), ox, oy, UNIT, a.scenery_speed)
    lines += l
    beam_time += c
    vectors += d
    blanks += b
    scenery = (d, b, c)
    for polys in actor_polys(lev, data, a.x0, a.y0):
        l, c, d, b = beam.polylines_to_lines(polys, ox, oy, UNIT, a.actor_speed)
        lines += l
        beam_time += c
        vectors += d
        blanks += b
        objects += 1
    # (clip to the window, roughly: drop lines entirely outside it)
    wy0, wy1 = TOP, TOP + WINDOW * UNIT
    lines = [ln for ln in lines if max(ln[1], ln[3]) >= wy0 - 3 * UNIT and min(ln[1], ln[3]) < wy1 + 3 * UNIT
             and max(ln[0], ln[2]) >= 0 and min(ln[0], ln[2]) < beam.SCREEN_X]
    # the window's edges, faintly (drawn fast)
    edge = beam.SCREEN_X
    lines += [(0, wy0, edge, wy0, 40, edge / 127), (0, wy1, edge, wy1, 40, edge / 127)]
    beam.render(lines, a.out, width=a.width)

    overhead = (vectors + blanks) * budget.VEC_OVERHEAD + (objects + (vectors // budget.RESET_EVERY)) * budget.RESET
    print('%s at %d,%d: scenery %d vectors + %d blank moves (beam time %.0f cycles at speed %g); '
          'everything %d vectors + %d blank moves in %d objects' % (
              a.level, a.x0, a.y0, scenery[0], scenery[1], scenery[2], a.scenery_speed, vectors, blanks, objects))
    print('beam time %.0f cycles + overheads ~%d = ~%.0f cycles (%.0f%% of a 50 Hz frame)' % (
        beam_time, overhead, beam_time + overhead, 100 * (beam_time + overhead) / budget.FRAME))
    print(a.out)


if __name__ == '__main__':
    main()
