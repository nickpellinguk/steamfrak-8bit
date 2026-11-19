#!/usr/bin/env python3
"""
Zigzag cave platforms (ledges) and ladders. Writes test/m1cz_engine.asm and test/m1cz_data.asm for
test/m1cz_test.asm, which draws runs of ledges as milestone 1's 8-row strip (tools/m1_cave_gen.py)
and as zigzag bands, and the cave ladder as columns and as a zigzag.

    python3 vectrex/tools/m1_cavez_gen.py [../steamfrak]

Ledges as bands: a run of ledges is cut into bands BAND pixels wide (whole tiles), each a zigzag
(tools/m1_zig_gen.py: the beam drifting, X flipping every row, the shift register written all the
way through) sweeping the ledge's 14 rows, the bands going down and up in turn; each band's last
row ends at its right edge, where the next band starts, and between bands Y's sample-and-hold
is reversed (with the ramp off). Rows a band wide, the drift chosen for rows about PITCH apart.

The ladder as a zigzag: its rows squared off to 16 pixels (2 blank either side: 32 cycles, two
bytes' time, so every flip falls on the same beat), the drift chosen for rows a pixel apart.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEST = os.path.join(HERE, '..', 'test')
sys.path.insert(0, HERE)
import m1_gen as g  # noqa: E402
import m1_zig_gen as z  # noqa: E402
import m1_cave_gen as cave  # noqa: E402
import vconvert  # noqa: E402

BAND = 64
PITCH = 1.6
LEDGES = [(-100, -100, 64), (-100, -70, 128), (-104, -26, 208)]      # x, y (top), length: 8-row strip
LEDGES_Z = [(-100, -10, 64), (-100, 20, 128), (-104, 50, 208)]      # the same as zigzag bands
LADDERS = [('ladder', 0, 60, -100), ('ladder', 1, 80, -100)]        # 0: columns, 1: zigzag


def band_widths(length):
    out = []
    while length > 0:
        out.append(min(BAND, length))
        length -= out[-1]
    return out


def plan_band(run, x0, y0, w, h, down, lit='#'):
    """A band of a ledge run: start (x0, y0) in the run's pixels (x0: where the beam is, near the
    band's left edge), w wide; the schedule, the data, where it ends."""
    drift = max(1, round(PITCH * 80 / w))
    target = (h - y0) if down else y0
    sdrift = drift if down else -drift
    max_bytes = math.ceil(target * g.UNIT / drift / 16) + 2 * w + 16
    sched, flips, off, nbytes = z.schedule(w, 0, max_bytes, sdrift, target, None, end_right=True)
    pos, (ex, ey) = z.path(flips, off, sdrift, 8 * nbytes)
    pos = [(x0 + x, y0 + y) for x, y in pos]
    n_on = off // 2
    bits = [0] * len(pos)
    left = int(round(x0))
    for r in range(h):
        for c in range(left, left + w):
            if 0 <= c < len(run[0]) and run[r][c] in lit:
                i = min(range(n_on), key=lambda i: (pos[i][0] - c - 0.5) ** 2 + (pos[i][1] - r - 0.5) ** 2)
                bits[i] = 1
    data = [int(''.join(map(str, bits[i:i + 8])), 2) for i in range(0, len(bits), 8)]
    return {'drift': sdrift, 'sched': sched, 'data': data, 'end': (x0 + ex, y0 + ey), 'off': off,
            'w': w, 'h': h, 'rows': len(flips) + 1, 'nbytes': nbytes}


def emit_band(name, b):
    """A band's routine (the ACR already $18): X loaded inside; the ramp off with U (free after
    the last flip, a flip to the right)."""
    c = g.Code()
    c.comment('a zigzag band %d x %d, drift %d, %d rows: ramp on %d cycles' % (b['w'], b['h'], b['drift'],
                                                                             b['rows'], b['off']))
    c.label(name)
    c.ins('ldx     #%s_d' % name, 3)
    c.ins('ldy     #$80%02X' % (-b['drift'] & 0xFF), 4)
    c.ins('sty     <VIA_port_b', 6, 'ramp off, mux on: Y speed %d' % -b['drift'])
    c.ins('ldu     #$01%02X' % z.SPEED, 3, '(the sample-and-hold settles)')
    c.ins('ldy     #$01%02X' % (-z.SPEED & 0xFF), 4)
    c.ins('ldd     #$81%02X' % z.SPEED, 3)
    c.ins('std     <VIA_port_b', 5, 'mux off, X speed %d' % z.SPEED)
    c.ins('lda     ,x+', 6)
    c.ins('ldb     ,x+', 6)
    c.ins('stu     <VIA_port_b', 5, 't = 0: ramp on')
    for t, op, ln, arg in b['sched']:
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
    c.ins('rts', 5)
    data = ['%s_d' % name] + ['                fcb     ' + ','.join('$%02X' % v for v in b['data'][i:i + 16])
                              for i in range(0, len(b['data']), 16)]
    return c.out, data


def main():
    steamfrak = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    tile = vconvert.grid_of(steamfrak, 'sLedge1_Beeb')
    h = len(tile)
    eng = ['; made by vectrex/tools/m1_cavez_gen.py', ''] + cave.rows_routine('cave_n', cave.ROWS) + ['']
    data, out, moves, table = [], ['; made by vectrex/tools/m1_cavez_gen.py: the test scene', '', 'draw_scene'], [], []
    g._beam[0] = None
    i = 0
    # the 8-row strips
    for x, y, length in LEDGES:
        nb = -(-length // 8)
        code, mv = g.start_move('s%d' % i, x * g.UNIT, -(y + 0.5) * g.UNIT)
        out += ['; ledges at (%d, %d), %d pixels: 8 rows' % (x, y, length)] + code + \
            ['dc_%d_start' % i, '                ldu     #rows_%d' % i, '                lda     #%d' % nb,
             '                sta     %s' % g.COUNT, '                jsr     cave_n', 'dc_%d_end' % i]
        moves += mv
        data.append('rows_%d' % i)
        data.append('                fdb     ' + ','.join('row_%d_%d' % (i, k) for k in range(len(cave.ROWS))))
        for k, r in enumerate(cave.ROWS):
            data.append('row_%d_%d' % (i, k))
            data += cave.g_bytes(cave.row_bytes(tile, r, length, k % 2 == 1, '#'))
        last = len(cave.ROWS) - 1
        g._beam[0] = ((x + (8 * nb if last % 2 == 0 else 0)) * g.UNIT, -(y + cave.ROWS[-1] + 0.5) * g.UNIT)
        table.append((i, 'ledges, %d pixels, 8 rows' % length))
        i += 1
    # the zigzag bands
    for x, y, length in LEDGES_Z:
        run = [''.join(tile[r][c % len(tile[0])] for c in range(length)) for r in range(h)]
        code, mv = g.start_move('z%d' % i, x * g.UNIT, -y * g.UNIT)
        out += ['; ledges at (%d, %d), %d pixels: zigzag bands' % (x, y, length)] + code + \
            ['dc_%d_start' % i, '                lda     #$18', '                sta     <VIA_aux_cntl']
        bx, by, down, left = 0.0, 0.0, True, 0
        for k, w in enumerate(band_widths(length)):
            b = plan_band(run, bx, by, w, h, down)
            name = 'band_%d_%d' % (i, k)
            code_b, data_b = emit_band(name, b)
            eng += code_b + ['']
            data += data_b
            out.append('                jsr     %s' % name)
            bx, by = b['end']
            down = not down
        out += ['                lda     #$98', '                sta     <VIA_aux_cntl', 'dc_%d_end' % i]
        moves += mv
        g._beam[0] = ((x + bx) * g.UNIT, -(y + by) * g.UNIT)
        table.append((i, 'ledges, %d pixels, zigzag bands' % length))
        i += 1
    # the ladder: columns, and a zigzag with its rows squared off to 16 pixels
    grid = g.sprite_grid(steamfrak, 'sLadder5_Beeb')
    nb, cols = g.column_data(grid)
    eng += g.column_routine(nb) + ['']
    padded = ['..' + row + '..' for row in grid]
    best = None
    for drift in range(1, 12):
        try:
            zz = z.zigzag(padded, force_drift=drift, track=False)
        except Exception:
            continue
        if zz['pitch'] <= 1.05:
            best = zz
    zl = best
    for lab, mode, x, y in LADDERS:
        if mode == 0:
            hs = 8 * nb
            code, mv = g.start_move('l%d' % i, (x - 0.5) * g.UNIT, -(y - g.COL_PAD) * g.UNIT)
            out += ['; the ladder at (%d, %d): columns' % (x, y)] + code + \
                ['dc_%d_start' % i, '                ldx     #ladder_cols', '                lda     #%d' % (len(grid[0]) + 1),
                 '                sta     %s' % g.COUNT, '                jsr     col%d_down' % nb, 'dc_%d_end' % i]
            last = len(grid[0]) - 1
            g._beam[0] = ((x + last + 0.5) * g.UNIT, -((y - g.COL_PAD) + (0 if last % 2 else hs)) * g.UNIT)
            table.append((i, 'ladder, columns'))
        else:
            code, mv = g.start_move('l%d' % i, (x - 2) * g.UNIT, -y * g.UNIT)
            out += ['; the ladder at (%d, %d): zigzag, rows 16 pixels' % (x, y)] + code + \
                ['dc_%d_start' % i, '                ldx     #ladder_z', '                jsr     zig_ladder', 'dc_%d_end' % i]
            ex, ey = zl['end']
            g._beam[0] = ((x - 2 + ex) * g.UNIT, -(y + ey) * g.UNIT)
            table.append((i, 'ladder, zigzag (drift %d, %d rows)' % (zl['drift'], zl['rows'])))
        moves += mv
        i += 1
    eng += z.emit('zig_ladder', zl) + ['']
    data.append('ladder_cols')
    data += ['                fcb     ' + ','.join('$%02X' % v for v in col) for col in cols]
    data.append('ladder_z')
    data += ['                fcb     ' + ','.join('$%02X' % v for v in zl['data'][k:k + 16]) for k in range(0, len(zl['data']), 16)]
    out.append('                rts')
    open(os.path.join(TEST, 'm1cz_engine.asm'), 'w').write('\n'.join(eng) + '\n')
    open(os.path.join(TEST, 'm1cz_data.asm'), 'w').write('\n'.join(out + [''] + moves + [''] + data) + '\n')
    for k, name in table:
        print(k, name)


if __name__ == '__main__':
    main()
