#!/usr/bin/env python3
"""
Multi-pass zigzags: a sprite drawn as N constant-Y zigzags (tools/m1_zig_gen.py), going down and
up in turn, each with a fast drift (rows far apart), their rows interleaving: the right-going rows
of all the passes make one family of parallel lines and the left-going rows another, evenly
spaced (a shallow crosshatch) instead of one zigzag's fan. Each pass's overshoot past the bottom
(or top) is chosen so the next pass's rows fall between the others (180 degrees for two passes,
120 for three, as near as the timing allows). Between passes, Y's sample-and-hold is reversed with
the ramp off. One stream of bits for all the passes; each lit pixel lights the nearest bit.

Writes test/m1zp_engine.asm and test/m1zp_data.asm for test/m1zp_test.asm: sprites as columns,
as one zigzag (drift 3), and as 2 and 3 passes (drift 6 and 9: about the same time).

    python3 vectrex/tools/m1_zigp_gen.py [../steamfrak]
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEST = os.path.join(HERE, '..', 'test')
sys.path.insert(0, HERE)
import m1_gen as g  # noqa: E402
import m1_zig_gen as z  # noqa: E402


def extents_of(grid, lit):
    out = []
    for r in range(len(grid)):
        xs = [x for x in range(len(grid[0])) if grid[r][x] in lit]
        out.append((min(xs), max(xs)) if xs else None)
    return out


def plan_pass(w, h, ext, drift, down, x_start, y_start, overshoot, start_left=None, end_frac=1.0):
    """One pass: (schedule, flips, off, stores, loads, dots, end, the last row's direction)."""
    if start_left is None:
        start_left = x_start > w / 2
    sd = drift if down else -drift
    target = h + overshoot if down else -overshoot
    span = abs(target - y_start)
    max_bytes = math.ceil(span * g.UNIT / drift / 16) + 2 * w + 16
    sched, flips, off, nstores = z.schedule(w, 0, max_bytes, sd, h, ext, start_left=start_left,
                                            x_start=x_start, y_start=y_start, y_target=target,
                                            end_frac=end_frac)
    nloads = 2 + sum(1 for t, op, ln, a in sched if op in ('lda', 'ldb'))
    dots, end = z.path(flips, off, sd, off // 2, start_left=start_left, x_start=x_start, y_start=y_start)
    return {'sched': sched, 'flips': flips, 'off': off, 'stores': nstores, 'loads': nloads, 'dots': dots,
            'end': end, 'down': down, 'drift': sd, 'start_left': start_left, 'x_start': x_start,
            'y_start': y_start, 'last_left': (len(flips) % 2 == 0) == start_left}


def coverage(grid, lit, dots):
    """Mean squared distance from each lit pixel's middle to the nearest dot."""
    tot, n = 0.0, 0
    for r in range(len(grid)):
        for c in range(len(grid[0])):
            if grid[r][c] in lit:
                tot += min((x - c - 0.5) ** 2 + (y - r - 0.5) ** 2 for x, y in dots)
                n += 1
    return tot / max(1, n)


def plan_sprite(grid, drift, passes, lit='#', regular=False):
    """regular: the sprite padded to a whole number of bytes wide and every row its full width,
    so every row is a whole number of 16-cycle beats, every flip on time and the passes in step;
    the drift then set for rows SPACING apart over all the passes."""
    if regular:
        w0 = len(grid[0])
        wp = -(-w0 // 8) * 8
        left = (wp - w0) // 2
        grid = ['.' * left + row + '.' * (wp - w0 - left) for row in grid]
    h, w = len(grid), len(grid[0])
    ext = None if regular else extents_of(grid, lit)
    pitch = drift * 2 * w / g.UNIT
    out = []
    x, y, sl = 0.0, 0.0, False
    for j in range(passes):
        down = j % 2 == 0
        if j == passes - 1:
            out.append(plan_pass(w, h, ext, drift, down, x, y, 0, start_left=sl))
            break
        best = None
        for step in range(1, 9):
            for turn_back in (False, True):
                p = plan_pass(w, h, ext, drift, down, x, y, 0, start_left=sl, end_frac=step / 8)
                nl = p['last_left'] != turn_back          # (the next pass: on the same way, or back)
                nxt = plan_pass(w, h, ext, drift, not down, p["end"][0], p["end"][1], 0, start_left=nl)
                dots = [d for q in out for d in q['dots']] + p['dots'] + nxt['dots']
                score = coverage(grid, lit, dots) + 0.0005 * (p['off'] + nxt['off'])
                if best is None or score < best[0]:
                    best = (score, p, nl)
        _, p, sl = best
        out.append(p)
        x, y = p["end"]
    # the bits: each lit pixel lights the nearest dot of any pass
    flat = [(pi, i) for pi, p in enumerate(out) for i in range(len(p['dots']))]
    bits = [[0] * (8 * p['loads']) for p in out]
    for r in range(h):
        for c in range(w):
            if grid[r][c] in lit:
                pi, i = min(flat, key=lambda q: (out[q[0]]['dots'][q[1]][0] - c - 0.5) ** 2 +
                            (out[q[0]]['dots'][q[1]][1] - r - 0.5) ** 2)
                bits[pi][i] = 1
    data = []
    for b in bits:
        data += [int(''.join(map(str, b[i:i + 8])), 2) for i in range(0, len(b), 8)]
    return out, data, (len(grid[0]) - len(grid[0].strip('.')) if False else 0)


def emit_sprite(name, passes):
    c = g.Code()
    c.comment('a multi-pass zigzag: %d passes, drift %d' % (len(passes), abs(passes[0]['drift'])))
    c.label(name)
    c.ins('lda     #$81', 2)
    c.ins('sta     <VIA_port_b', 4, 'ramp off, mux off')
    c.ins('lda     #$18', 2)
    c.ins('sta     <VIA_aux_cntl', 4, 'ACR')
    for pi, p in enumerate(passes):
        sp_first = -z.SPEED if p['start_left'] else z.SPEED
        c.comment('pass %d: %s, starting %s' % (pi, 'down' if p['down'] else 'up', 'left' if p['start_left'] else 'right'))
        c.ins('ldy     #$80%02X' % (-p['drift'] & 0xFF), 4)
        c.ins('sty     <VIA_port_b', 6, 'ramp off, mux on: Y speed %d' % -p['drift'])
        c.ins('ldu     #$01%02X' % (sp_first & 0xFF), 3, '(the sample-and-hold settles)')
        c.ins('ldy     #$01%02X' % (-sp_first & 0xFF), 4)
        c.ins('ldd     #$81%02X' % (sp_first & 0xFF), 3)
        c.ins('std     <VIA_port_b', 5, 'mux off, X speed %d' % sp_first)
        c.ins('lda     ,x+', 6)
        c.ins('ldb     ,x+', 6)
        c.ins('stu     <VIA_port_b', 5, 't = 0: ramp on')
        for t, op, ln, arg in p['sched']:
            if op in ('sta', 'stb'):
                c.ins('%s     <VIA_shift_reg' % op, 4, 't = %d: byte %d' % (t, arg))
            elif op in ('lda', 'ldb'):
                c.ins('%s     ,x+' % op, 6, 't = %d: byte %d' % (t, arg))
            elif op == 'flip':
                c.ins('%s     <VIA_port_b' % ('sty' if arg % 2 == 0 else 'stu'), ln, 't = %d: row %d' % (t, arg + 1))
            elif op == 'off':
                c.ins('ldu     #$8100', 3)
                c.ins('stu     <VIA_port_b', 5, 't = %d: ramp off' % (t + 3))
            else:
                for o, cy in g.delay(ln):
                    c.ins(o, cy)
        c.ins('clr     <VIA_shift_reg', 6, 'spot off')
        # (bytes loaded ahead but not written are skipped: the data has them)
    c.ins('lda     #$98', 2)
    c.ins('sta     <VIA_aux_cntl', 4, 'ACR back')
    c.ins('rts', 5)
    return c.out


SPRITES = [('trogg', 'sTrogg_wr_Beeb', 4), ('scrubbly', 'sScrubbly_Beeb', 1), ('poglet', 'sPoglet_Beeb', 1),
           ('hooter', 'sHooter_Beeb', 1)]
MODES = [('columns', 0, 0), ('1 pass', None, 1), ('2 passes', None, 2), ('3 passes', None, 3)]
SPACING = 1.0               # pixels between rows, over all the passes (regular rows)
LAYOUT = {'trogg': (-100, -104), 'scrubbly': (-100, -60), 'poglet': (-100, -10), 'hooter': (-100, 34)}
STEP = {'trogg': 34, 'scrubbly': 44, 'poglet': 28, 'hooter': 26}


def main():
    steamfrak = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    eng = ['; made by vectrex/tools/m1_zigp_gen.py', '']
    out, moves, data, info = ['; made by vectrex/tools/m1_zigp_gen.py: the test scene', '', 'draw_scene'], [], [], []
    g._beam[0] = None
    col_sizes = set()
    i = 0
    for label, name, frames in SPRITES:
        grid = g.sprite_grid(steamfrak, name, 0, frames)
        nb, cols = g.column_data(grid)
        col_sizes.add(nb)
        data.append('%s_cols' % label)
        data += ['                fcb     ' + ','.join('$%02X' % v for v in col) for col in cols]
        x0, y0 = LAYOUT[label]
        for mi, (mname, drift, npass) in enumerate(MODES):
            x = x0 + mi * STEP[label]
            if npass == 0:
                hs = 8 * nb
                code, mv = g.start_move('m%d' % i, (x - 0.5) * g.UNIT, -(y0 - g.COL_PAD) * g.UNIT)
                out += ['; %s: columns' % label] + code + \
                    ['dc_%d_start' % i, '                ldx     #%s_cols' % label,
                     '                lda     #%d' % (len(grid[0]) + 1), '                sta     %s' % g.COUNT,
                     '                jsr     col%d_down' % nb, 'dc_%d_end' % i]
                last = len(grid[0]) - 1
                g._beam[0] = ((x + last + 0.5) * g.UNIT, -((y0 - g.COL_PAD) + (0 if last % 2 else hs)) * g.UNIT)
            else:
                wp = -(-len(grid[0]) // 8) * 8
                drift = max(1, round(npass * SPACING * g.UNIT / (2 * wp)))
                passes, d, _ = plan_sprite(grid, drift, npass, regular=True)
                x -= (wp - len(grid[0])) // 2           # (the padding: the sprite where it was)
                rname = 'zp_%s_%d' % (label, npass)
                eng += emit_sprite(rname, passes) + ['']
                data.append('%s_d' % rname)
                data += ['                fcb     ' + ','.join('$%02X' % v for v in d[k:k + 16]) for k in range(0, len(d), 16)]
                code, mv = g.start_move('m%d' % i, x * g.UNIT, -y0 * g.UNIT)
                out += ['; %s: %s' % (label, mname)] + code + \
                    ['dc_%d_start' % i, '                ldx     #%s_d' % rname, '                jsr     %s' % rname, 'dc_%d_end' % i]
                ex, ey = passes[-1]['end']
                g._beam[0] = ((x + ex) * g.UNIT, -(y0 + ey) * g.UNIT)
                info.append('%2d %-9s %-9s drift %2d, padded to %d: ramp on %d cycles over the passes'
                            % (i, label, mname, drift, wp, sum(p['off'] for p in passes)))
            moves += mv
            i += 1
    for nb in sorted(col_sizes):
        eng += g.column_routine(nb) + ['']
    out.append('                rts')
    open(os.path.join(TEST, 'm1zp_engine.asm'), 'w').write('\n'.join(eng) + '\n')
    open(os.path.join(TEST, 'm1zp_data.asm'), 'w').write('\n'.join(out + [''] + moves + [''] + data) + '\n')
    print('\n'.join(info))


if __name__ == '__main__':
    main()
