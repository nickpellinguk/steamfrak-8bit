#!/usr/bin/env python3
"""
A calibration cartridge for the raster engine's timing (test/calib_data.asm, for test/calib.asm):
patterns whose misalignment shows plainly in a screenshot, for comparing emulators (and a real
Vectrex):

  A  24 columns (5 bytes), each lit at one pixel, the same in all: in line, if the bits and the
     beam agree; down and up columns at two heights, if not (the difference: twice the error)
  B  24 columns lit at their first and last content pixels: a column swept too long or short
     makes the zig-zag drift up or down from column to column
  C  10 drifting rows (3 bytes), each lit at its first and last pixel
  D  a strip (2 rows of 12 bytes), lit at every 8th pixel: row 1 under row 0, if they agree

    python3 vectrex/tools/calib_gen.py
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import m1_gen as g  # noqa: E402

TEST = os.path.join(HERE, '..', 'test')


def cols_from_spatial(spatial_cols, nb):
    """Columns given top-down as bit lists (content rows only), to sweep-order bytes."""
    out = []
    for c, content in enumerate(spatial_cols):
        bits = [0] * (8 * nb)
        for r, b in enumerate(content):
            bits[g.COL_PAD + r] = b
        if c % 2:
            bits = bits[::-1]
        out.append([int(''.join(map(str, bits[i * 8:i * 8 + 8])), 2) for i in range(nb)])
    return out


def main():
    nb, h, w = 5, 36, 24
    a = cols_from_spatial([[1 if r == 18 else 0 for r in range(h)] for _ in range(w)], nb)
    b = cols_from_spatial([[1 if r in (0, h - 1) else 0 for r in range(h)] for _ in range(w)], nb)
    # C: 10 rows of 24 pixels (3 bytes), lit at both ends, in sweep order
    crow = []
    for r in range(10):
        bits = [1] + [0] * 22 + [1]
        crow.append([int(''.join(map(str, bits[i * 8:i * 8 + 8])), 2) for i in range(3)])
    # D: a strip of 12 bytes, lit at every 8th pixel (row 1 reversed: swept left)
    d0 = [0x80] * 12
    d1 = [0x01] * 12

    eng = ['; made by vectrex/tools/calib_gen.py', ''] + g.column_routine(nb) + [''] + \
        g.drift_rows_routine(3, 10) + [''] + g.strip_routine() + ['']
    open(os.path.join(TEST, 'calib_engine.asm'), 'w').write('\n'.join(eng) + '\n')

    out = ['; made by vectrex/tools/calib_gen.py', '', 'draw_calib']
    moves = []
    U = g.UNIT
    hs = 8 * nb
    for label, x, y in (('pat_a', -80, -70), ('pat_b', 10, -70)):
        sx, sy = (x - 0.5) * U, -(y - g.COL_PAD) * U
        code, mv = g.start_move(label, sx, sy)
        out += ['; %s' % label] + code + ['                ldx     #%s' % label,
                                         '                lda     #%d' % (w + 1),
                                         '                sta     %s' % g.COUNT,
                                         '                jsr     col%d_down' % nb]
        moves += mv
    code, mv = g.start_move('pat_c', -80 * U, -10 * U)
    out += ['; pat_c'] + code + ['                ldx     #pat_c', '                jsr     rows3_10']
    moves += mv
    code, mv = g.start_move('pat_d', 10 * U, -(10.5) * U)
    out += ['; pat_d'] + code + ['                ldx     #pat_d1', '                stx     %s' % g.ROW1,
                                '                ldx     #pat_d0', '                ldb     #12',
                                '                jsr     strip']
    moves += mv
    out += ['                rts', ''] + moves + ['']
    for name, data in (('pat_a', a), ('pat_b', b), ('pat_c', crow)):
        out.append(name)
        for col in data:
            out.append('                fcb     ' + ','.join('$%02X' % v for v in col))
    out.append('pat_d0')
    out.append('                fcb     ' + ','.join('$%02X' % v for v in d0))
    out.append('pat_d1')
    out.append('                fcb     ' + ','.join('$%02X' % v for v in d1))
    open(os.path.join(TEST, 'calib_data.asm'), 'w').write('\n'.join(out) + '\n')
    print('written')


if __name__ == '__main__':
    main()
