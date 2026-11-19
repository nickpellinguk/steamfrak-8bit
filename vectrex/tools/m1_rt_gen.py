#!/usr/bin/env python3
"""
Milestone 1, run time: write test/m1_rt_engine.asm (the routines) and test/m1_rt_data.asm (the
sprites, a strip of ledges and a scene table) for test/m1_rt.asm, whose 6809 code works out
everything at run time: the clipping, the moves and the start and end of each thing drawn.

    python3 vectrex/tools/m1_rt_gen.py [../steamfrak]

Descriptors (for test/m1_rt.asm):

  column sprite  spr_NAME:  fcb width, bytes a column
                            fdb data, (routines:) down, up, down_l, up_l
                            fcb the padded column's height in pixels
                            fdb the same in beam units
  row sprite     rsp_NAME:  fcb width, bytes a row, rows
                            fdb how far down it ends (beam units), data, routine
  strip          stp_NAME:  fcb bytes a row
                            fdb row 0's data, row 1's (reversed: swept to the left)

  scene: fcb kind (1 columns, 2 rows, 3 strip, 0 the end); fdb descriptor, x, y (pixels: the
  left edge and the top, from the middle of the screen, y down); fcb facing (0 right, 1 left)

The strip routine (strip_m) masks the first and last bytes of each row (pixel-exact clipping):
its rows are an unrolled run of byte slots entered according to the length (from a table), the
last slot ANDing the last byte with its mask, so every write stays on its 16-cycle beat.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEST = os.path.join(HERE, '..', 'test')
sys.path.insert(0, HERE)
import m1_gen as g  # noqa: E402

MAXN = 28                       # a strip row's most bytes on screen (206 pixels + the edges)
RAM = {'STRIP_N': '$C899', 'M0F': '$C89A', 'M0L': '$C89B', 'M1F': '$C89C', 'M1L': '$C89D'}


def strip_m_routine():
    c = g.Code()
    c.comment('two rows of 2-%d bytes, the first and last bytes of each masked: 32 x bytes + ~150' % MAXN)
    c.comment('in: X = row 0\'s first byte, %s = row 1\'s, STRIP_N = bytes a row (2 or more),' % g.ROW1)
    c.comment('M0F, M0L, M1F, M1L = the masks for rows 0 and 1\'s first and last bytes, the beam at')
    c.comment('row 0\'s left end')
    c.label('strip_m')
    c.ins('lda     #$81', 2)
    c.ins('sta     <VIA_port_b', 4, 'ramp off, mux off, before port B takes over the ramp')
    c.ins('lda     #$18', 2)
    c.ins('sta     <VIA_aux_cntl', 4, 'ACR')

    def ysh(value, then):
        c.ins('ldy     #$80%02X' % (value & 0xFF), 4)
        c.ins('sty     <VIA_port_b', 6, 'mux on: Y speed %d' % value)
        c.ins('ldy     #$81%02X' % (then & 0xFF), 4, '(the sample-and-hold settles)')
        c.ins('nop', 2)
        c.ins('nop', 2)
        c.ins('nop', 2)
        c.ins('sty     <VIA_port_b', 6, 'mux off, DAC (X speed) %d' % then)

    def row(r):
        c.ins('ldy     #strip_entries', 4)
        c.ins('ldb     %s' % RAM['STRIP_N'], 5)
        c.ins('aslb', 2)
        c.ins('ldu     b,y', 6, 'where in the run of slots to start')
        c.ins('ldy     #%s' % RAM['M%dL' % r], 4, 'the last byte\'s mask')
        c.ins('lda     ,x+', 6)
        c.ins('anda    %s' % RAM['M%dF' % r], 5, 'the first byte, masked')
        c.ins('ldb     #$01', 2)
        c.ins('stb     >$D000+VIA_port_b', 5, 't = 0: ramp on')
        c.ins('jsr     ,u', 7, 't = 5: the slots (the first store at 12)')
        c.ins('brn     *', 3, 't = 16n + 9 (back)')
        c.ins('clr     <VIA_shift_reg', 6, 't = 16n + 12: spot off')

    ysh(0, g.SPEED)
    row(0)
    ysh(-40, 0)
    c.ins('lda     #$01', 2)
    c.ins('ldb     #$81', 2)
    c.ins('sta     <VIA_port_b', 4, 'ramp on...')
    c.ins('stb     <VIA_port_b', 4, '...for 4 cycles: a pixel down')
    c.ins('ldx     %s' % g.ROW1, 6, 'row 1\'s bytes')
    ysh(0, -g.SPEED)
    row(1)
    c.ins('lda     #$98', 2)
    c.ins('sta     <VIA_aux_cntl', 4, 'ACR back')
    c.ins('rts', 5)
    c.comment('the slots: each stores the byte in A (t = 12 + 16k) and loads the next')
    c.label('strip_slots')
    for k in range(MAXN - 2):
        c.ins('sta     <VIA_shift_reg', 4)
        c.ins('lda     ,x+', 6)
        c.ins('nop', 2)
        c.ins('nop', 2)
        c.ins('nop', 2)
    c.label('strip_and')
    c.ins('sta     <VIA_shift_reg', 4)
    c.ins('lda     ,x+', 6, 'the last byte...')
    c.ins('anda    ,y', 4, '...masked')
    c.ins('ldb     #$81', 2)
    c.ins('sta     <VIA_shift_reg', 4, 't = 12 + 16(n - 1): the last byte')
    c.ins('stb     <VIA_port_b', 4, 't = 16n: ramp off')
    c.ins('rts', 5)
    c.label('strip_entries')
    for n in range(MAXN + 1):
        c.out.append('                fdb     strip_and-%d          ; %d bytes' % (7 * max(0, n - 2), n))
    return c.out


SPRITES = [  # (label, sprite, frames, columns or rows)
    ('trogg', 'sTrogg_wr_Beeb', 4, 'cols'), ('scrubbly', 'sScrubbly_Beeb', 1, 'cols'),
    ('poglet', 'sPoglet_Beeb', 1, 'cols'), ('hooter', 'sHooter_Beeb', 1, 'cols'),
    ('gem', 'sGem_Beeb', 1, 'cols'), ('ladder', 'sLadder5_Beeb', 1, 'cols'),
    ('key', 'sKey_Beeb', 1, 'rows'), ('yoyo', 'sYoyo_Beeb', 4, 'rows'),
]
# kind, label, x, y, facing: x scrolls by -40..40 at run time, so things cross both edges
SCENE = [
    (1, 'trogg', -20, -60, 0), (1, 'trogg', 10, -60, 1),
    (1, 'scrubbly', -100, -70, 0), (1, 'scrubbly', 70, -70, 1),
    (1, 'poglet', -60, 20, 1), (1, 'hooter', 40, 30, 0), (1, 'ladder', -5, 0, 0),
    (1, 'gem', -90, 60, 0), (1, 'gem', 80, 60, 0), (2, 'key', -40, 80, 0), (2, 'yoyo', 30, 80, 0),
    (3, 'ledges', -130, 100, 0),
]
LEDGE_SPANS = [(0, 64), (80, 128), (144, 192), (208, 260)]


def main():
    steamfrak = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    data = {}
    for label, name, frames, how in SPRITES:
        grid = g.sprite_grid(steamfrak, name, 0, frames)
        nb, items = (g.column_data if how == 'cols' else g.row_data)(grid)
        data[label] = (how, nb, items, len(grid), len(grid[0]))
    col_sizes = sorted({nb for how, nb, _, _, _ in data.values() if how == 'cols'})
    row_sizes = sorted({(nb, h) for how, nb, _, h, _ in data.values() if how == 'rows'})

    eng = ['; made by vectrex/tools/m1_rt_gen.py: the raster engine', '']
    for nb in col_sizes:
        eng += g.column_routine(nb) + ['']
    for nb, h in row_sizes:
        eng += g.drift_rows_routine(nb, h) + ['']
    eng += strip_m_routine() + ['']
    open(os.path.join(TEST, 'm1_rt_engine.asm'), 'w').write('\n'.join(eng) + '\n')

    out = ['; made by vectrex/tools/m1_rt_gen.py: sprites, a strip and the scene', '']
    for label, (how, nb, items, h, w) in data.items():
        if how == 'cols':
            out += ['spr_%s                                  ; %d columns of %d bytes' % (label, w, nb),
                    '                fcb     %d,%d' % (w, nb),
                    '                fdb     %s_data,col%d_down,col%d_up,col%d_down_l,col%d_up_l'
                    % (label, nb, nb, nb, nb),
                    '                fcb     %d' % (8 * nb),
                    '                fdb     %d' % round(8 * nb * g.UNIT)]
        else:
            drift = max(1, round(10 / nb))
            out += ['rsp_%s                                  ; %d rows of %d bytes' % (label, h, nb),
                    '                fcb     %d,%d,%d' % (w, nb, h),
                    '                fdb     %d,%s_data,rows%d_%d' % (drift * 16 * nb * h, label, nb, h)]
    out.append('')
    for label, (how, nb, items, h, w) in data.items():
        out.append('%s_data' % label)
        for it in items:
            out.append('                fcb     ' + ','.join('$%02X' % b for b in it))
    # the ledges: the top two rows of sLedge1_Beeb, repeated, over the spans
    tile = g.sprite_grid(steamfrak, 'sLedge1_Beeb')[:2]
    width = max(b for _, b in LEDGE_SPANS)
    width += -width % 8
    rows = []
    for r in range(2):
        bits = [1 if any(a <= px < b for a, b in LEDGE_SPANS) and tile[r][px % 16] in ('#' if r == 0 else 'm')
                else 0 for px in range(width)]
        rows.append([int(''.join(map(str, bits[i * 8:i * 8 + 8])), 2) for i in range(width // 8)])
    rev = [int('{:08b}'.format(b)[::-1], 2) for b in reversed(rows[1])]
    nfull = width // 8
    out += ['', 'stp_ledges                              ; %d bytes a row' % nfull,
            '                fcb     %d' % nfull, '                fdb     ledges_row0,ledges_row1',
            'ledges_row0']
    for i in range(0, nfull, 16):
        out.append('                fcb     ' + ','.join('$%02X' % b for b in rows[0][i:i + 16]))
    out.append('ledges_row1')
    for i in range(0, nfull, 16):
        out.append('                fcb     ' + ','.join('$%02X' % b for b in rev[i:i + 16]))
    out += ['', 'scene']
    for kind, label, x, y, facing in SCENE:
        desc = {1: 'spr_', 2: 'rsp_', 3: 'stp_'}[kind] + label
        out.append('                fcb     %d' % kind)
        out.append('                fdb     %s,%d,%d' % (desc, x, y))
        out.append('                fcb     %d' % facing)
    out.append('                fcb     0')
    open(os.path.join(TEST, 'm1_rt_data.asm'), 'w').write('\n'.join(out) + '\n')
    print('written: %d column routines, %d row routines, strip_m' % (len(col_sizes), len(row_sizes)))


if __name__ == '__main__':
    main()
