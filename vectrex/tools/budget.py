#!/usr/bin/env python3
"""
Estimate the Vectrex drawing cost of every Frak! level.

    python3 vectrex/tools/budget.py [../steamfrak] [--csv]

For each level it slides a window the size of the Vectrex's view across the level (8 pixels at a
time, both ways for the vertically scrolling levels) and, for the busiest window position, counts
what has to be drawn and estimates how many CPU cycles it takes, with platforms and ladders
simplified to lines:

* a platform: one horizontal line along its top, its width;
* a ladder: two upright rails, its height (with the hidden extension up to the platform above);
* gems, keys, bulbs and meanies that stand still: a small shape each (a fixed number of vectors);
* the moving meanies and platforms, wherever they are in their range (counted as if all on screen).

The cycle model is vecx's: the beam moves (DAC value) units a cycle, and the screen is 33000
units wide and 41000 high, so at full speed (127) it crosses the width in about 260 cycles. A line
of length L at speed s takes L / s cycles plus a fixed overhead per vector (setting the DACs and
starting the timer). Brightness goes as intensity / speed, so drawing the scenery at a higher
speed than the actors makes it dimmer, and cheaper. Blank moves between pieces of scenery are
made at full speed, and the beam is reset to the centre every RESET_EVERY vectors (drift).

Everything here is a parameter (top of the file); the numbers are estimates until a test program
has been timed.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import convert  # noqa: E402  (the BBC converter: build_level, LEVELS)

# --- the screen ----------------------------------------------------------------------------------
SCREEN_UNITS_X = 33000          # vecx's beam units across the screen ...
SCREEN_UNITS_Y = 41000          # ... and down it (the screen is portrait, about 4:5 in vecx)
WINDOWS = {                     # level pixels shown (w x h); the window fills the screen's width
    'wide': (320, 256),         # the BBC's view: 320 wide, using 256/320*33/41 = 64% of the height
    'narrow': (256, 256),       # the Steam rooms' 256 x 256: 79% of the height
}

# --- costs, in cycles ----------------------------------------------------------------------------
FRAME = 30000                   # 50 Hz at 1.5 MHz
DRAW_SHARE = 20000              # what's left for drawing after game logic, sound and the BIOS
VEC_OVERHEAD = 40               # per vector, drawn or blank (DACs, timer start, loop)
RESET = 150                     # beam back to the centre, plus the wait for it to settle
RESET_EVERY = 12                # vectors between resets in a chain of scenery
BLANK_SPEED = 127               # moves with the beam off: as fast as possible

# vectors and total length (in level pixels) of each small shape, drawn at the actor speed
SHAPES = {
    'trogg': (20, 110), 'scrubbly': (22, 120), 'poglet': (20, 110), 'hooter': (20, 110),
    'gem': (5, 24), 'key': (7, 30), 'bulb': (6, 26), 'meanie': (20, 110),
    'balloon': (8, 40), 'dagger': (4, 26),
}

# the shapes that have line art: their real counts (drawn vectors + blank moves, beam length)
sys.path.insert(0, os.path.join(HERE, '..', 'art'))
import shapes  # noqa: E402


def _measure(polys):
    n = sum(max(1, len(p) - 1) for p in polys) + len(polys) - 1
    length = sum(math.dist(a, b) for p in polys for a, b in zip(p, p[1:]))
    return n, length


for _name, _polys in (('trogg', shapes.TROGG_SR), ('scrubbly', shapes.SCRUBBLY), ('gem', shapes.GEM),
                      ('key', shapes.KEY)):
    SHAPES[_name] = _measure(_polys)
for _name in ('poglet', 'hooter', 'meanie'):          # (no art yet: as big as a Scrubbly)
    SHAPES[_name] = SHAPES['scrubbly']

FLYING = 3                      # balloons and daggers on screen at once, worst case (difficulty)

SPEEDS = (127, 64, 32)          # scenery speeds to report (actor speed: ACTOR_SPEED)
ACTOR_SPEED = 32


def window_cost(lev, x0, y0, w, h, scenery_speed, unit):
    """Cycles to draw what's in the window (x0, y0, w, h), and the counts."""
    lines = []
    for (px, py, pw, ph) in lev['plats']:
        a, b = max(px, x0), min(px + pw, x0 + w)
        if a < b and y0 <= py < y0 + h:
            lines.append(((a, py), (b, py)))
    for (lx, ly, lh, ext) in lev['ladders']:
        a, b = max(ly, y0), min(ly + lh, y0 + h)
        if a < b and x0 <= lx < x0 + w:
            for rail in (lx + 3, lx + 12):              # the ladder art's rails are 9 pixels apart
                lines.append(((rail, a), (rail, b)))
    # scenery: a chain from the window's top left, nearest piece next (either end first)
    cycles, vectors, length = 0, 0, 0.0
    pos = (x0, y0)
    todo = lines[:]
    since_reset = 0
    while todo:
        best = min(range(len(todo)), key=lambda i: min(math.dist(pos, todo[i][0]), math.dist(pos, todo[i][1])))
        p, q = todo.pop(best)
        if math.dist(pos, q) < math.dist(pos, p):
            p, q = q, p
        if since_reset >= RESET_EVERY:
            cycles += RESET
            pos, since_reset = (x0 + w / 2, y0 + h / 2), 0
        cycles += VEC_OVERHEAD + math.dist(pos, p) * unit / BLANK_SPEED
        seg = math.dist(p, q)
        cycles += VEC_OVERHEAD + seg * unit / scenery_speed
        length += seg
        vectors += 2
        since_reset += 2
        pos = q
    n_lines = len(lines)
    # things that stand still
    things = 0
    for depth, _, spr, x, y, obj in lev['draw']:
        if depth in convert.CACHE_BG_DEPTHS or not (x0 - 16 <= x < x0 + w + 16 and y0 - 16 <= y < y0 + h + 16):
            continue
        kind = ('gem' if 'Gem' in spr else 'key' if 'Key' in spr else 'bulb' if 'Bulb' in spr
                else 'meanie')
        things += 1
        nv, ln = SHAPES[kind]
        cycles += RESET + nv * VEC_OVERHEAD + ln * unit / ACTOR_SPEED
        vectors += nv
    # things that move, if their range overlaps the window; and Trogg, balloons and daggers
    def near(xa, xb, ya, yb):
        return xa < x0 + w + 16 and xb > x0 - 16 and ya < y0 + h + 16 and yb > y0 - 16
    movers = ['trogg'] + ['balloon'] * FLYING
    for v in lev['slow']:
        k, x, y = v['kind'], v['x'], v['y']
        if k == convert.SL_PLATFORM:
            pw = 48
            if near(v['amin'], v['amax'] + pw, v['bmin'], v['bmax'] + 8):
                movers.append(None)
        elif k == convert.SL_SCRUBBLY:
            if near(v['amin'] - 16, v['amax'] + 16, y - 42, y):
                movers.append('scrubbly')
        elif k == convert.SL_POGLET:
            if near(x - 16, x + 16, v['amin'] - 40, v['amax']):
                movers.append('poglet')
        elif near(x - 16, x + 16, y - 120, y):                  # a Hooter jumps up to ~100 pixels
            movers.append('hooter')
    return cycles, {'lines': n_lines, 'length': length, 'things': things, 'movers': len(movers),
                    'vectors': vectors}


def level_worst(lev, w, h, scenery_speed):
    unit = SCREEN_UNITS_X / w                           # beam units per level pixel
    xs = range(0, max(1, lev['w'] - w + 1), 8) or [0]
    ys = range(0, max(1, lev['h'] - h + 1), 8) or [0]
    best = None
    for y0 in ys:
        for x0 in xs:
            c, info = window_cost(lev, x0, y0, w, h, scenery_speed, unit)
            if best is None or c > best[0]:
                best = (c, (x0, y0), info)
    return best


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    web = args[0] if args else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    data = convert.Data(web)
    levels = [(name, convert.build_level(data, name)) for name in convert.LEVELS]
    csv = '--csv' in sys.argv
    for wname, (w, h) in WINDOWS.items():
        print('\n== window %s: %d x %d level pixels; actors at speed %d; drawing budget %d cycles (of %d)'
              % (wname, w, h, ACTOR_SPEED, DRAW_SHARE, FRAME))
        print('%-10s %5s %5s %6s %6s %6s %7s  ' % ('level', 'lines', 'len', 'things', 'movers', 'vecs', 'at')
              + '  '.join('cyc@%-3d' % s for s in SPEEDS))
        totals = {s: [] for s in SPEEDS}
        for name, lev in levels:
            row = None
            costs = []
            for s in SPEEDS:
                c, at, info = level_worst(lev, w, h, s)
                costs.append(c)
                totals[s].append((c, name))
                if row is None:
                    row = (info, at)
            info, at = row
            print('%-10s %5d %5d %6d %6d %6d %7s  ' % (name[5:], info['lines'], info['length'], info['things'],
                                                       info['movers'], info['vectors'], '%d,%d' % at)
                  + '  '.join('%7d' % c for c in costs))
        print('worst:     ' + '  '.join('%s %d at speed %d (%.0f%% of budget)' % (n[5:], c, s, 100 * c / DRAW_SHARE)
                                         for s in SPEEDS for c, n in [max(totals[s])]))
        for s in SPEEDS:
            over = sum(1 for c, _ in totals[s] if c > DRAW_SHARE)
            print('  scenery at speed %3d: %2d of %d levels over budget at their busiest; median %d cycles'
                  % (s, over, len(levels), sorted(c for c, _ in totals[s])[len(levels) // 2]))


if __name__ == '__main__':
    main()
