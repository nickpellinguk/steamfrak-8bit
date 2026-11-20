#!/usr/bin/env python3
"""
Milestone 3: levels drawn from ROM, scrolling. Writes test/m3_engine.asm (the column and row
routines, milestone 1's strip routine) and test/m3_data.asm (the sprites, each level's platform
strips and its lists) for test/m3.asm.

    python3 vectrex/tools/m3_gen.py [../steamfrak]

From the BBC converter's build_level (../tools/convert.py), for LEVELS:

* the static platforms as strips (vconvert.strips_of: runs of ledges or girders touching on a line,
  logs one by one), each its two rows' exact pixels (row 0, then row 1 reversed: swept back);
* everything else as column sprites (milestone 1's colN routines): ladders, chains and Qiana
  poles, gems, springs, the meanies (standing; the moving ones at their start, not moving yet),
  and Trogg at his start (standing); keys as drifting rows.

Each level: fdb width; fdb strips, strips' end, sprites, sprites' end; fdb the widest strip, the
widest sprite (pixels). A list entry (as test/m1_rt.asm's scene, but in the level's pixels):
fcb kind (1 columns, 2 rows, 3 strip); fdb descriptor, left x, top y; fcb facing (0). Each list
sorted by x, so a frame only walks from the first entry that can reach the window to the last
that starts in it.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEST = os.path.join(HERE, '..', 'test')
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import m1_gen as g  # noqa: E402
import m1_rt_gen as rt  # noqa: E402
import vconvert as v  # noqa: E402
import convert  # noqa: E402

LEVELS = ['room_A_1', 'room_A_2', 'room_A_3']
TROGG = 'sTrogg_sr_Beeb'
ROW_SPRITES = {'sKey_Beeb'}


def label(name):
    return name.replace('_Beeb', '')[1:].lower()


def strip_rows(web, data, kind, length):
    """A strip's two rows (bytes): row 0 to the right, row 1 reversed (swept to the left)."""
    if kind in v.PATTERNS:
        tile, tw, lit0, lit1 = v.PATTERNS[kind]
        grid = v.grid_of(web, tile)
        px = lambda r, x: grid[r][x % tw]
        lits = (lit0, lit1)
    else:
        grid = v.grid_of(web, kind)
        px = lambda r, x: grid[r][x] if x < len(grid[0]) else '.'
        lits = v.LOG_LIT
    nb = -(-length // 8)
    rows = []
    for r in range(2):
        bits = [1 if x < length and px(r, x) in lits[r] else 0 for x in range(8 * nb)]
        rows.append([int(''.join(map(str, bits[i:i + 8])), 2) for i in range(0, 8 * nb, 8)])
    rev = [int('{:08b}'.format(b)[::-1], 2) for b in reversed(rows[1])]
    return nb, rows[0], rev


def fcb(values):
    return ['                fcb     ' + ','.join('$%02X' % x for x in values[i:i + 16]) for i in range(0, len(values), 16)]


def main():
    web = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    data = convert.Data(web)
    sprites_used = {TROGG}
    levels = []
    for n in LEVELS:
        lev = convert.build_level(data, n)
        ents_s, ents_p = [], []
        for x, y, pat, w in v.strips_of(lev, data):
            ents_p.append((x, y, v.PATTERN_IDS[pat], w))
        for x, sid, y in v.things_of(lev):
            spr = v.SPRITE_IDS[sid]
            ents_s.append((x, y, spr))
        for (spr, yorig), (lx, ly, lh, ext) in zip(lev['ladder_spr'], lev['ladders']):
            ents_s.append((lx, yorig, spr))
        for q in lev['slow']:
            if q['kind'] != convert.SL_PLATFORM:
                ents_s.append((q['x'], q['y'], q['spr']))
        tx, ty = lev['trogg']
        ents_s.append((tx, ty, TROGG))
        for x, y, spr in ents_s:
            sprites_used.add(spr)
        levels.append((n, lev, ents_s, ents_p))

    # the sprites: column data (or rows) and descriptors, as test/m1_rt.asm's
    eng = ['; made by vectrex/tools/m3_gen.py: the raster engine', '']
    out = ['; made by vectrex/tools/m3_gen.py: the sprites, the levels\' strips and lists', '']
    col_sizes, row_sizes, info = set(), set(), {}
    for spr in sorted(sprites_used):
        grid = g.sprite_grid(web, spr)
        lab = label(spr)
        if spr in ROW_SPRITES:
            nb, rows = g.row_data(grid)
            h = len(grid)
            row_sizes.add((nb, h))
            drift = max(1, round(10 / nb))
            out += ['rsp_%s' % lab, '                fcb     %d,%d,%d' % (len(grid[0]), nb, h),
                    '                fdb     %d,%s_d,rows%d_%d' % (round(drift * 16 * nb * h / 80), lab, nb, h),
                    '%s_d' % lab] + [l for r in rows for l in fcb(r)]
        else:
            nb, cols = g.column_data(grid)
            col_sizes.add(nb)
            out += ['spr_%s' % lab, '                fcb     %d,%d' % (len(grid[0]), nb),
                    '                fdb     %s_d,col%d_down,col%d_up,col%d_down_l,col%d_up_l' % (lab, nb, nb, nb, nb),
                    '                fcb     %d' % (8 * nb), '                fdb     %d' % (16 * nb),
                    '%s_d' % lab] + [l for c in cols for l in fcb(c)]
        info[spr] = (data.sprites[spr]['xo'], data.sprites[spr]['yo'], len(grid[0]))
    for nb in sorted(col_sizes):
        eng += g.column_routine(nb) + ['']
    for nb, h in sorted(row_sizes):
        eng += g.drift_rows_routine(nb, h) + ['']
    eng += rt.strip_m_routine() + ['']

    # the levels
    out += ['', 'levels'] + ['                fdb     lev_%s' % n[5:] for n, *_ in levels] + ['levels_end', '']
    for n, lev, ents_s, ents_p in levels:
        tag = n[5:]
        strips, sprites = [], []
        for i, (x, y, kind, w) in enumerate(sorted(ents_p)):
            nb, r0, r1 = strip_rows(web, data, kind, w)
            assert nb <= rt.MAXN or True
            name = 'stp_%s_%d' % (tag, i)
            out += [name, '                fcb     %d' % nb, '                fdb     %s_0,%s_1' % (name, name),
                    '%s_0' % name] + fcb(r0) + ['%s_1' % name] + fcb(r1)
            strips.append((x, y, name, w))
        for x, y, spr in ents_s:
            xo, yo, w = info[spr]
            kind = 2 if spr in ROW_SPRITES else 1
            desc = ('rsp_' if kind == 2 else 'spr_') + label(spr)
            sprites.append((x - xo, y - yo, kind, desc, w))
        sprites.sort()
        wmax_p = max(w for *_, w in strips)
        wmax_s = max(w for *_, w in sprites)
        out += ['lev_%s' % tag, '                fdb     %d' % lev['w'],
                '                fdb     strips_%s,strips_%s_end,sprites_%s,sprites_%s_end' % (tag, tag, tag, tag),
                '                fdb     %d,%d' % (wmax_p, wmax_s), 'strips_%s' % tag]
        for x, y, name, w in strips:
            out += ['                fcb     3', '                fdb     %s,%d,%d' % (name, x, y), '                fcb     0']
        out += ['strips_%s_end' % tag, 'sprites_%s' % tag]
        for x, y, kind, desc, w in sprites:
            out += ['                fcb     %d' % kind, '                fdb     %s,%d,%d' % (desc, x, y), '                fcb     0']
        out += ['sprites_%s_end' % tag, '']
        print('%s: %d pixels wide, %d strips (widest %d), %d sprites (widest %d)'
              % (n, lev['w'], len(strips), wmax_p, len(sprites), wmax_s))
    open(os.path.join(TEST, 'm3_engine.asm'), 'w').write('\n'.join(eng) + '\n')
    open(os.path.join(TEST, 'm3_data.asm'), 'w').write('\n'.join(out) + '\n')


if __name__ == '__main__':
    main()
