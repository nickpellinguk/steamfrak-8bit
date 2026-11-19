#!/usr/bin/env python3
"""
A vector dagger: a sharp V for the blade, a crossguard and a handle, drawn with vlist_d in one
continuous path (6 vectors, no blank moves) and pointed any way from the same shape. Writes
test/dagger_data.asm for test/dagger.asm, which draws the raster dagger (milestone 1's columns)
beside vector daggers pointing right, left, up and down.

    python3 vectrex/tools/dagger.py

The shape is in pixels along the dagger's axis (u, from the tip towards the pommel) and across
it (v). The vectors' speed is capped at SPEED (DAC units: 80 is the raster's sweep speed, so the
lines come out as bright as the raster's pixels), and each vector's rounding is carried into
the next so the path closes where it should.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEST = os.path.join(HERE, '..', 'test')
sys.path.insert(0, HERE)
import m1_gen as g  # noqa: E402

LENGTH = 13.0           # tip to pommel, pixels (the BBC sprite's diagonal is about 13.5)
GUARD_AT = 8.5          # tip to the crossguard
GUARD_HALF = 3.0        # the crossguard's half-width
BLADE_HALF = 1.3        # the blade's half-width at the guard (the V's opening)
SPEED = int(os.environ.get('DAGGER_SPEED', '80'))
FIXED_SCALE = int(os.environ.get('DAGGER_SCALE', '28'))
                        # every vector at DAGGER_SCALE (28; 0 for speed SPEED instead) at that scale (its speed from its length):
                        # vlist_d's long path (scale + 54 cycles a vector) instead of its short one
                        # for scales under 28, but slower lines are brighter

# the path, (u, v): pommel, guard centre, one end of the guard, back along it to the blade's
# edge, the tip, the blade's other edge, the guard's other end
PATH = [(LENGTH, 0), (GUARD_AT, 0), (GUARD_AT, GUARD_HALF), (GUARD_AT, BLADE_HALF), (0, 0),
        (GUARD_AT, -BLADE_HALF), (GUARD_AT, -GUARD_HALF)]

# pointing: the tip's direction (x right, y down, pixels) and where the tip is
DAGGERS = [('right', (1, 0), (-20, 0)), ('left', (-1, 0), (0, 0)),
           ('up', (0, -1), (30, -10)), ('down', (0, 1), (50, 10))]
RASTER_AT = (-90, -5)   # the raster dagger's top left


def points(direction, tip):
    """The path in screen pixels (x right, y down) for a dagger pointing that way."""
    dx, dy = direction
    n = math.hypot(dx, dy)
    ax, ay = -dx / n, -dy / n            # u: from the tip back towards the pommel
    px, py = -ay, ax                     # v: across
    return [(tip[0] + u * ax + v * px, tip[1] + u * ay + v * py) for u, v in PATH]


def vectors(pts, speed):
    """vlist_d vectors (scale, dy, dx, mode) along the points (beam units, y up)."""
    out = []
    pos = (pts[0][0] * g.UNIT, -pts[0][1] * g.UNIT)
    for x, y in pts[1:]:
        tx, ty = x * g.UNIT - pos[0], -y * g.UNIT - pos[1]
        scale = FIXED_SCALE or max(1, math.ceil(max(abs(tx), abs(ty)) / speed))
        vx, vy = round(tx / scale), round(ty / scale)
        out.append((scale, vy, vx, 0xFF))
        pos = (pos[0] + vx * scale, pos[1] + vy * scale)
    return out


def main():
    code, data = ['; made by vectrex/tools/dagger.py', '', 'draw_daggers'], []
    # the raster dagger
    rx, ry = RASTER_AT
    c, mv = g.start_move('raster', (rx - 0.5) * g.UNIT, -(ry - g.COL_PAD) * g.UNIT)
    code += c + ['dg_raster_start',
                 '                ldx     #dagger_data',
                 '                lda     #%d' % (11 + 1),
                 '                sta     %s' % g.COUNT,
                 '                jsr     col2_down',
                 'dg_raster_end']
    data += mv
    for name, d, tip in DAGGERS:
        pts = points(d, tip)
        sx, sy = pts[0][0] * g.UNIT, -pts[0][1] * g.UNIT
        c, mv = g.start_move(name, sx, sy)
        vec = vectors(pts, SPEED)
        code += c + ['dg_%s_start' % name,
                     '                ldx     #shape_%s' % name,
                     '                jsr     vlist_d',
                     'dg_%s_end' % name]
        data += mv + ['shape_%s                              ; pointing %s: %d vectors' % (name, name, len(vec))]
        data += ['                fcb     %d,%d,%d,$%02X' % v for v in vec] + ['                fcb     0,0']
    code.append('                rts')
    # the raster dagger's columns (as milestone 1's test has them)
    grid = g.sprite_grid(os.path.join(HERE, '..', '..', '..', 'steamfrak') if len(sys.argv) < 2 else sys.argv[1],
                         'sDagger_Beeb')
    nb, cols = g.column_data(grid)
    assert nb == 2
    data.append('dagger_data')
    data += ['                fcb     ' + ','.join('$%02X' % b for b in col) for col in cols]
    open(os.path.join(TEST, 'dagger_data.asm'), 'w').write('\n'.join(code + [''] + data) + '\n')
    for name, d, tip in DAGGERS:
        v = vectors(points(d, tip), SPEED)
        print('%-6s %d vectors, scales %s, speeds %s' % (name, len(v), [s for s, _, _, _ in v],
                                                         [max(abs(a), abs(b)) for _, a, b, _ in v]))


if __name__ == '__main__':
    main()
