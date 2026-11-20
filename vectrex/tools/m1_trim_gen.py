#!/usr/bin/env python3
"""
Trimmed columns: each column swept only as far as it needs (its lit pixels, and its neighbours':
columns going down and up share their ends), by one data-driven routine for every sprite. Writes
test/m1t_engine.asm and test/m1t_data.asm for test/m1t_test.asm, which draws every column sprite
both ways: milestone 1's full columns, then trimmed (labels ending _t).

    python3 vectrex/tools/m1_trim_gen.py [../steamfrak]

The routine (trim_down, trim_up): an unrolled run of byte slots for each direction, each column
jumping into it by an address in its data, so its length is its own. A column's data:

    fcb the first byte; fdb where in the run to start (its length); fcb the rest of the bytes

Timing, with t = 0 when the ramp goes on and n the column's bytes (writes as instructions start,
as vecx makes them; the ramp and the DAC 13 cycles late, the shift register not):

    0        STB <port_b      ramp on
    4        JMP [,X++]       into the run (9 cycles)
    13+16j   STA <shift_reg   byte j (the slots: STA, LDA ,X+, NOP NOP NOP)
    16n+1    STU <port_b      DAC = +-32 (U: the slide across, a pixel in its 5 cycles), after
                              the last bit
    16n+6=e  STY <port_b      ramp off, mux on, DAC = the next column's Y speed
    e+6      DEC <$06         the column count, in timer 1's latch (free while columns are drawn)
    e+12     BEQ (out)
    e+15     LDY #            the Y speed after the next column
    e+19     LDD #$8100, STD  mux off, DAC (X) = 0 (the sample-and-hold settled 22 cycles)
    e+27     LDA ,X+          the next column's first byte
    e+33     LDB #$01
    e+35=0   STB <port_b      the next column's ramp on

So a column costs 16n + 41 cycles (milestone 1's full columns: 16 x bytes + 35, + 3 every other
column). The first byte at 13 (not 12) puts down columns' bits half a pixel lower and up columns'
half a pixel higher than milestone 1's: the converter puts up columns' bits a pixel lower to match.

The chain (rows of the sprite, y down; D: a down column's first bit's row, U: an up column's):
an up column after a down one starts where it ended, U = D + 8n + 1, and a down column after an
up one, D = U - 8n - 1. The beam starts a down column at row D - 0.5, an up column at U + 1.5
(pixels from the sprite's top). Each column's last bit is blank (the shift register keeps its
last bit while the beam turns). Its n is the least that covers its own lit pixels and reaches
the next column's.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEST = os.path.join(HERE, '..', 'test')
sys.path.insert(0, HERE)
import m1_gen as g  # noqa: E402
import trim_plan  # noqa: E402

MAXN = 14                   # the longest column, bytes (112 pixels: sQiana4 is 104 tall)
SLIDE = 32                  # the slide's DAC: 5 cycles x 32 = 160 units, a pixel
SPEED = g.SPEED
T1_LATCH_LO = '$06'         # (VIA register, direct page: the column count)


def trim_routine():
    c = g.Code()
    c.comment('trimmed columns, any length (1-%d bytes): 16n + 41 cycles a column' % MAXN)
    c.comment('in: X = the first column\'s data, timer 1\'s latch low ($D006) = the number of columns,')
    c.comment('U = $01%02X (facing right) or $01%02X (left): the slide, the beam at the first column\'s start'
              % (SLIDE, -SLIDE & 0xFF))

    def prologue():
        c.ins('lda     #$81', 2)
        c.ins('sta     <VIA_port_b', 4, 'ramp off, mux off, before port B takes over the ramp')
        c.ins('lda     #$18', 2)
        c.ins('sta     <VIA_aux_cntl', 4, 'ACR: ramp from port B, shift register out on the clock')

    c.label('trim_down')
    prologue()
    c.ins('ldy     #$80%02X' % (-SPEED & 0xFF), 4, 'Y speed down')
    c.ins('sty     <VIA_port_b', 6, 'mux on')
    c.ins('jmp     tu_next', 3, '(the up run\'s turn: a down column next)')
    c.label('trim_up')
    prologue()
    c.ins('ldy     #$80%02X' % (SPEED & 0xFF), 4, 'Y speed up')
    c.ins('sty     <VIA_port_b', 6, 'mux on')
    c.ins('jmp     td_next', 3, '(the down run\'s turn: an up column next)')

    def run(d):
        name = 'td' if d == 'down' else 'tu'
        nxt_after = -SPEED if d == 'down' else SPEED      # the speed after the next column
        c.comment('the %s run: slot k for a column of %d - k bytes' % (d, MAXN))
        c.comment('(a prefix, for entering slot 0 with a lead-in)')
        c.ins('lda     ,x+', 6)
        c.ins('nop', 2)
        c.ins('nop', 2)
        c.ins('nop', 2)
        c.label('%s_slots' % name)
        for k in range(MAXN - 1):
            c.ins('sta     <VIA_shift_reg', 4)
            c.ins('lda     ,x+', 6)
            c.ins('nop', 2)
            c.ins('nop', 2)
            c.ins('nop', 2)
        c.ins('sta     <VIA_shift_reg', 4, 't = 16n - 3: the last byte')
        c.ins('stu     <VIA_port_b', 5, 't = 16n + 1: the slide (after the last bit)')
        c.ins('sty     <VIA_port_b', 6, 't = 16n + 6 = e: ramp off, mux on, the next Y speed')
        c.ins('dec     <%s' % T1_LATCH_LO, 6, 'e+6: the count')
        c.ins('beq     %s_out' % name, 3)
        c.label('%s_next' % name)
        c.ins('ldy     #$80%02X' % (nxt_after & 0xFF), 4, 'e+15: the speed after the next column')
        c.ins('ldd     #$8100', 3)
        c.ins('std     <VIA_port_b', 5, 'e+22: mux off, X speed 0')
        c.ins('lda     ,x+', 6, 'the first byte')
        c.ins('ldb     #$01', 2)
        c.ins('stb     <VIA_port_b', 4, 'e+35 = t = 0: ramp on')
        c.ins('jmp     [,x++]', 9, 't = 4: into the %s run' % ('up' if d == 'down' else 'down'))
        c.label('%s_out' % name)
        c.ins('lbra    trim_out', 5)

    run('down')
    run('up')
    c.label('trim_out')
    c.ins('lda     #$81', 2)
    c.ins('sta     <VIA_port_b', 4, 'mux off')
    c.ins('lda     #$98', 2)
    c.ins('sta     <VIA_aux_cntl', 4, 'ACR back')
    c.ins('rts', 5)
    return c.out


LEADS = [0, 1, 2, 3, 6]      # pixels: entering a slot's padding 0, 2, 4, 6 or 12 cycles before its store


def trim_columns(grid, lit='#'):
    """
    The cheapest chain (tools/trim_plan.py): [(n, lead, [bytes])...] for each column, and each
    column's start row (beam, pixels from the top, y down) with one more for where the last ends.
    """
    total, chain, starts = trim_plan.plan(grid, LEADS, [0], lit)
    h, w = len(grid), len(grid[0])
    cols = []
    for k, (n, l, q, first) in enumerate(chain):
        bits = [0] * (8 * n)
        for r in range(h):
            if grid[r][k] in lit:
                i = int(r - first) if k % 2 == 0 else int(first - r)
                assert 0 <= i < 8 * n - 1, (k, r, first, n)
                bits[i] = 1
        cols.append((n, l, [int(''.join(map(str, bits[i:i + 8])), 2) for i in range(0, 8 * n, 8)]))
    return cols, starts


ENTRY_BACK = {0: 0, 1: 1, 2: 2, 3: 3, 6: 5}     # bytes back from a slot's STA for each lead-in


def column_asm(label, cols):
    """The data: each column's first byte, its entry into the run, the rest (with a lead-in of 6,
    entering at a slot's LDA ,X+, the first byte again before the rest)."""
    out = ['%s_data' % label]
    for k, (n, l, data) in enumerate(cols):
        run = 'td' if k % 2 == 0 else 'tu'
        out.append('                fcb     $%02X' % data[0])
        out.append('                fdb     %s_slots+%d             ; %d bytes, lead-in %d'
                   % (run, 7 * (MAXN - n) - ENTRY_BACK[l], n, l))
        rest = data if l == 6 else data[1:]
        if rest:
            out.append('                fcb     ' + ','.join('$%02X' % v for v in rest))
    return out


def column_size(n, l):
    return 3 + n - 1 + (1 if l == 6 else 0)


SPRITES = [  # (label, sprite, frames)
    ('trogg', 'sTrogg_wr_Beeb', 4), ('trogg_climb', 'sTrogg_cu_Beeb', 2), ('scrubbly', 'sScrubbly_Beeb', 1),
    ('poglet', 'sPoglet_Beeb', 1), ('hooter', 'sHooter_Beeb', 1), ('gem', 'sGem_Beeb', 1),
    ('balloon', 'sBalloon_Beeb', 1), ('dagger', 'sDagger_Beeb', 1), ('bulb', 'sBulb_Beeb', 1),
    ('ladder', 'sLadder5_Beeb', 1), ('chain', 'sChain4_Beeb', 1),
]
SCENE = [   # (label, trimmed?, x, y): full then trimmed
    ('trogg', 0, -100, -100), ('trogg', 1, -72, -100), ('scrubbly', 0, -44, -108), ('scrubbly', 1, -9, -108),
    ('ladder', 0, 44, -100), ('ladder', 1, 58, -100), ('chain', 0, 72, -100), ('chain', 1, 84, -100),
    ('trogg_climb', 0, -100, -50), ('trogg_climb', 1, -78, -50), ('poglet', 0, -56, -49), ('poglet', 1, -31, -49),
    ('hooter', 0, -6, -39), ('hooter', 1, 15, -39),
    ('gem', 0, -100, 0), ('gem', 1, -87, 0), ('balloon', 0, -66, 0), ('balloon', 1, -52, 0),
    ('dagger', 0, -36, 0), ('dagger', 1, -22, 0), ('bulb', 0, -6, 0), ('bulb', 1, 8, 0),
    ('scrubbly', 1, -112, 54), ('poglet', 1, 94, 60),          # partly off the left and right edges
]


def main():
    steamfrak = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    full, trim = {}, {}
    for label, name, frames in SPRITES:
        grid = g.sprite_grid(steamfrak, name, 0, frames)
        full[label] = (g.column_data(grid), len(grid), len(grid[0]))
        trim[label] = trim_columns(grid)

    eng = ['; made by vectrex/tools/m1_trim_gen.py: milestone 1\'s column routines and the trimmed one', '']
    for nb in sorted({f[0][0] for f in full.values()}):
        eng += g.column_routine(nb) + ['']
    eng += trim_routine() + ['']
    open(os.path.join(TEST, 'm1t_engine.asm'), 'w').write('\n'.join(eng) + '\n')

    out = ['; made by vectrex/tools/m1_trim_gen.py: the test scene', '', 'draw_scene']
    moves, table = [], []
    g._beam[0] = None
    for i, (label, trimmed, x, y) in enumerate(SCENE):
        (nb, fcols), h, w = full[label]
        c0, c1 = max(0, g.WINDOW[0] - x), min(w, g.WINDOW[1] - x)
        if c0 >= c1:
            continue
        if not trimmed:
            hs = 8 * nb
            sx = (x + c0 - 0.5) * g.UNIT
            sy = -((y - g.COL_PAD) + (hs if c0 % 2 else 0)) * g.UNIT
            code, mv = g.start_move(i, sx, sy)
            out.append('; %s at (%d, %d): full columns %d-%d of %d, %d bytes each' % (label, x, y, c0, c1 - 1, w, nb))
            out += code + ['dc_%d_start' % i,
                           '                ldx     #%s_data+%d' % (label, c0 * nb),
                           '                lda     #%d' % (c1 - c0 + 1),
                           '                sta     %s' % g.COUNT,
                           '                jsr     col%d_%s' % (nb, 'up' if c0 % 2 else 'down'),
                           'dc_%d_end' % i]
            last = c1 - 1
            g._beam[0] = ((x + last + 0.5) * g.UNIT, -((y - g.COL_PAD) + (0 if last % 2 else hs)) * g.UNIT)
            table.append((i, '%s, full' % label, sum(16 * nb + 35 + (3 if k % 2 == 0 and k > c0 else 0)
                                                     for k in range(c0, c1))))
        else:
            cols, starts = trim[label]
            offset = sum(column_size(n, l) for n, l, _ in cols[:c0])
            sx = (x + c0 + 0.5) * g.UNIT                   # (the slide comes after each column)
            sy = -(y + starts[c0]) * g.UNIT
            code, mv = g.start_move(i, sx, sy)
            out.append('; %s at (%d, %d): trimmed columns %d-%d of %d' % (label, x, y, c0, c1 - 1, w))
            out += code + ['dc_%d_start' % i,
                           '                ldx     #%s_t_data+%d' % (label, offset),
                           '                lda     #%d' % (c1 - c0),
                           '                sta     <%s' % T1_LATCH_LO,
                           '                ldu     #$01%02X' % SLIDE,
                           '                jsr     trim_%s' % ('up' if c0 % 2 else 'down'),
                           'dc_%d_end' % i]
            g._beam[0] = ((x + c1 + 0.5) * g.UNIT, -(y + starts[c1]) * g.UNIT)
            table.append((i, '%s, trimmed' % label, sum(16 * n + 41 + 2 * l for n, l, _ in cols[c0:c1])))
        moves += mv
    out.append('                rts')
    out += [''] + moves + ['']
    for label, ((nb, fcols), h, w) in full.items():
        out.append('%s_data' % label)
        out += ['                fcb     ' + ','.join('$%02X' % v for v in col) for col in fcols]
    for label, (cols, starts) in trim.items():
        out += column_asm(label + '_t', cols)
    open(os.path.join(TEST, 'm1t_data.asm'), 'w').write('\n'.join(out) + '\n')
    for i, name, cyc in table:
        print('%3d %-24s %5d cycles (worked out)' % (i, name, cyc))


if __name__ == '__main__':
    main()
