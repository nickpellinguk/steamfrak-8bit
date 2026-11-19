#!/usr/bin/env python3
"""
Cave platforms (the ledges) drawn as rows: more of each ledge than milestone 1's two-row strip.
Writes test/m1c_engine.asm and test/m1c_data.asm for test/m1c_test.asm, which draws runs of ledges
with the two-row strip and with ROWS (no clipping yet).

    python3 vectrex/tools/m1_cave_gen.py [../steamfrak]

The routine (cave_rows): the rows one after another, back and forth (even rows to the right, odd
rows to the left, from reversed data), each a byte loop as milestone 1's strip (LDA ,X+ /
STA >shift_reg / DECB / BNE: 16 cycles a byte); between rows, a step down: Y's sample-and-hold
set to 40 x the step (pixels), the ramp on for 4 cycles, then back to 0 and the next row's X
speed. in: U = the rows' data pointers (in drawing order), COUNT = bytes a row, the beam at the
first row's left end.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEST = os.path.join(HERE, '..', 'test')
sys.path.insert(0, HERE)
import m1_gen as g  # noqa: E402
import vconvert  # noqa: E402

ROWS = [0, 1, 4, 5, 7, 9, 11, 13]       # the ledge's rows drawn (black pixels): two, the blank
                                        # rows skipped, two, then every other row
TILE = 'sLedge1_Beeb'
SPEED = g.SPEED
LEDGES = [(-100, -90, 64), (-100, -40, 128), (-103, 20, 206)]     # x, y (top), length: 2 rows
LEDGES_N = [(-100, -70, 64), (-100, -10, 128), (-103, 60, 206)]   # the same with ROWS


def rows_routine(name, rows):
    c = g.Code()
    c.comment('%d rows (%s of the ledge) of any length: %d x bytes + turns' % (len(rows), rows, 16 * len(rows)))
    c.label(name)
    c.ins('lda     #$81', 2)
    c.ins('sta     <VIA_port_b', 4, 'ramp off, mux off, before port B takes over the ramp')
    c.ins('lda     #$18', 2)
    c.ins('sta     <VIA_aux_cntl', 4, 'ACR')
    c.ins('ldy     #$8000', 4)
    c.ins('sty     <VIA_port_b', 6, 'mux on: Y speed 0')
    c.ins('ldy     #$81%02X' % SPEED, 4)
    c.ins('nop', 2)
    c.ins('nop', 2)
    c.ins('nop', 2)
    c.ins('sty     <VIA_port_b', 6, 'mux off, X speed %d' % SPEED)
    for k, r in enumerate(rows):
        if k > 0:
            step = r - rows[k - 1]
            xs = SPEED if k % 2 == 0 else -SPEED
            c.ins('ldy     #$80%02X' % (-40 * step & 0xFF), 4)
            c.ins('sty     <VIA_port_b', 6, 'mux on: Y speed %d (a step of %d)' % (-40 * step, step))
            c.ins('ldy     #$8100', 4, '(the sample-and-hold settles)')
            c.ins('nop', 2)
            c.ins('nop', 2)
            c.ins('nop', 2)
            c.ins('sty     <VIA_port_b', 6, 'mux off, X speed 0')
            c.ins('lda     #$01', 2)
            c.ins('ldb     #$81', 2)
            c.ins('sta     <VIA_port_b', 4, 'ramp on...')
            c.ins('stb     <VIA_port_b', 4, '...for 4 cycles: %d pixel(s) down' % step)
            c.ins('ldy     #$8000', 4)
            c.ins('sty     <VIA_port_b', 6, 'mux on: Y speed 0')
            c.ins('ldy     #$81%02X' % (xs & 0xFF), 4)
            c.ins('nop', 2)
            c.ins('nop', 2)
            c.ins('nop', 2)
            c.ins('sty     <VIA_port_b', 6, 'mux off, X speed %d' % xs)
        lab = '%s_%d' % (name, k)
        c.ins('ldx     ,u++', 8, 'row %d\'s bytes' % r)
        c.ins('ldb     %s' % g.COUNT, 5)
        c.ins('decb', 2, '(bytes - 1 in the loop)')
        c.ins('ldy     #$8100', 4, '(for the ramp off)')
        c.ins('lda     #$01', 2)
        c.ins('sta     <VIA_port_b', 4, 't = 0: ramp on')
        c.ins('nop', 2)
        c.label(lab)
        c.ins('lda     ,x+', 6, 't = 6 + 16i')
        c.ins('sta     >$D000+VIA_shift_reg', 5, 't = 12 + 16i')
        c.ins('decb', 2)
        c.ins('bne     %s' % lab, 3)
        c.ins('lda     ,x+', 6, 't = 16n - 10: the last byte')
        c.ins('sta     <VIA_shift_reg', 4, 't = 16n - 4')
        c.ins('sty     <VIA_port_b', 6, 't = 16n: ramp off')
        for op, cyc in g.delay(6):
            c.ins(op, cyc)
        c.ins('clr     <VIA_shift_reg', 6, 't = 16n + 12: spot off')
    c.ins('lda     #$98', 2)
    c.ins('sta     <VIA_aux_cntl', 4, 'ACR back')
    c.ins('rts', 5)
    return c.out


def row_bytes(grid, r, length, reverse, lit):
    nb = -(-length // 8)
    bits = [1 if x < length and grid[r][x % len(grid[0])] in lit else 0 for x in range(8 * nb)]
    b = [int(''.join(map(str, bits[i:i + 8])), 2) for i in range(0, 8 * nb, 8)]
    if reverse:
        b = [int('{:08b}'.format(v)[::-1], 2) for v in reversed(b)]
    return b


def main():
    steamfrak = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    grid = vconvert.grid_of(steamfrak, TILE)
    two = [0, 1]
    eng = ['; made by vectrex/tools/m1_cave_gen.py', ''] + rows_routine('cave_2', two) + [''] + \
        rows_routine('cave_n', ROWS) + ['']
    open(os.path.join(TEST, 'm1c_engine.asm'), 'w').write('\n'.join(eng) + '\n')
    out = ['; made by vectrex/tools/m1_cave_gen.py: the test scene', '', 'draw_scene']
    moves, data, table = [], [], []
    g._beam[0] = None
    for i, ((x, y, length), rows, routine) in enumerate(
            [(l, two, 'cave_2') for l in LEDGES] + [(l, ROWS, 'cave_n') for l in LEDGES_N]):
        nb = -(-length // 8)
        lit = {0: '#', 1: '#'}
        code, mv = g.start_move('c%d' % i, x * g.UNIT, -(y + 0.5) * g.UNIT)
        out.append('; ledges at (%d, %d), %d pixels: rows %s' % (x, y, length, rows))
        out += code + ['dc_%d_start' % i,
                       '                ldu     #rows_%d' % i,
                       '                lda     #%d' % nb,
                       '                sta     %s' % g.COUNT,
                       '                jsr     %s' % routine,
                       'dc_%d_end' % i]
        moves += mv
        data.append('rows_%d' % i)
        data.append('                fdb     ' + ','.join('row_%d_%d' % (i, k) for k in range(len(rows))))
        for k, r in enumerate(rows):
            # (the black pixels; the top row's lit as milestone 1's strip: row 1 also the magenta)
            litk = 'm' if (rows is two and k == 1) else '#'
            data.append('row_%d_%d' % (i, k))
            data += g_bytes(row_bytes(grid, r, length, k % 2 == 1, litk))
        last = len(rows) - 1
        g._beam[0] = ((x + (8 * nb if last % 2 == 0 else 0)) * g.UNIT, -(y + rows[-1] + 0.5) * g.UNIT)
        table.append((i, '%s, %d pixels' % (routine, length)))
    out.append('                rts')
    out += [''] + moves + [''] + data
    open(os.path.join(TEST, 'm1c_data.asm'), 'w').write('\n'.join(out) + '\n')
    for i, name in table:
        print(i, name)


def g_bytes(b):
    return ['                fcb     ' + ','.join('$%02X' % v for v in b[i:i + 16]) for i in range(0, len(b), 16)]


if __name__ == '__main__':
    main()
