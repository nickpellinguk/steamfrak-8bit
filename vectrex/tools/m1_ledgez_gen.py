#!/usr/bin/env python3
"""
Ledges as a textured top line and a drift zigzag for each block. Writes test/m1lz_engine.asm and
test/m1lz_data.asm for test/m1lz_test.asm: 128-pixel runs of ledges as milestone 1's 8-row strip,
and as the top line (one raster row: the ledge's row 0) with each 16-pixel block's rows 4-13
(the band and the stalactite) drawn as a zigzag (tools/m1_zig_gen.py: rows turning at the
stalactite's edges) at each of DRIFTS. Each block is reached with a chained move.

    python3 vectrex/tools/m1_ledgez_gen.py [../steamfrak]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEST = os.path.join(HERE, '..', 'test')
sys.path.insert(0, HERE)
import m1_gen as g  # noqa: E402
import m1_zig_gen as z  # noqa: E402
import m1_cave_gen as cave  # noqa: E402
import vconvert  # noqa: E402

LENGTH = 128
DRIFTS = [2, 3, 4, 5]
X = -100
YS = [-104, -76, -48, -20, 8]          # the strip, then the zigzag at each drift


def main():
    steamfrak = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    tile = vconvert.grid_of(steamfrak, 'sLedge1_Beeb')
    block = tile[4:14]
    eng = ['; made by vectrex/tools/m1_ledgez_gen.py', ''] + cave.rows_routine('cave_n', cave.ROWS) + [''] + \
        cave.rows_routine('cave_top', [0]) + ['']
    out, moves, data, info = ['; made by vectrex/tools/m1_ledgez_gen.py: the test scene', '', 'draw_scene'], [], [], []
    g._beam[0] = None
    nb = LENGTH // 8
    zz = {d: z.zigzag(block, force_drift=d) for d in DRIFTS}
    for d, b in zz.items():
        eng += z.emit('zig_blk_%d' % d, b) + ['']
        data.append('blk_%d' % d)
        data += ['                fcb     ' + ','.join('$%02X' % v for v in b['data'][k:k + 16])
                 for k in range(0, len(b['data']), 16)]
        info.append('drift %d: a block %d rows (pitch %.2f), ramp on %d cycles' % (d, b['rows'], b['pitch'], b['off']))
    for i, y in enumerate(YS):
        if i == 0:
            code, mv = g.start_move('s', X * g.UNIT, -(y + 0.5) * g.UNIT)
            out += ['; ledges: the 8-row strip'] + code + \
                ['dc_0_start', '                ldu     #rows_s', '                lda     #%d' % nb,
                 '                sta     %s' % g.COUNT, '                jsr     cave_n', 'dc_0_end']
            moves += mv
            data.append('rows_s')
            data.append('                fdb     ' + ','.join('row_s_%d' % k for k in range(len(cave.ROWS))))
            for k, r in enumerate(cave.ROWS):
                data.append('row_s_%d' % k)
                data += cave.g_bytes(cave.row_bytes(tile, r, LENGTH, k % 2 == 1, '#'))
            last = len(cave.ROWS) - 1
            g._beam[0] = ((X + (8 * nb if last % 2 == 0 else 0)) * g.UNIT, -(y + cave.ROWS[-1] + 0.5) * g.UNIT)
            continue
        d = DRIFTS[i - 1]
        code, mv = g.start_move('t%d' % i, X * g.UNIT, -(y + 0.5) * g.UNIT)
        out += ['; ledges: the top line, then each block as a zigzag, drift %d' % d] + code + \
            ['dc_%d_start' % i, '                ldu     #rows_t', '                lda     #%d' % nb,
             '                sta     %s' % g.COUNT, '                jsr     cave_top']
        moves += mv
        g._beam[0] = ((X + 8 * nb) * g.UNIT, -(y + 0.5) * g.UNIT)
        for k in range(LENGTH // 16):
            bx, by = X + 16 * k, y + 4
            code, mv = g.start_move('b%d_%d' % (i, k), bx * g.UNIT, -by * g.UNIT)
            out += code + ['                ldx     #blk_%d' % d, '                jsr     zig_blk_%d' % d]
            moves += mv
            ex, ey = zz[d]['end']
            g._beam[0] = ((bx + ex) * g.UNIT, -(by + ey) * g.UNIT)
        out.append('dc_%d_end' % i)
    data.append('rows_t')
    data.append('                fdb     row_t_0')
    data.append('row_t_0')
    data += cave.g_bytes(cave.row_bytes(tile, 0, LENGTH, False, '#'))
    out.append('                rts')
    open(os.path.join(TEST, 'm1lz_engine.asm'), 'w').write('\n'.join(eng) + '\n')
    open(os.path.join(TEST, 'm1lz_data.asm'), 'w').write('\n'.join(out + [''] + moves + [''] + data) + '\n')
    print('\n'.join(info))


if __name__ == '__main__':
    main()
