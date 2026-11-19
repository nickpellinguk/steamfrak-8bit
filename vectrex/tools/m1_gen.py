#!/usr/bin/env python3
"""
Milestone 1, the raster engine: write test/raster_engine.asm (the column routines) and
test/m1_data.asm (the test scene: sprites as column data, and the code that draws them).

    python3 vectrex/tools/m1_gen.py [../steamfrak]

The column routines (one for each column height, in bytes) are data-driven: a sprite is its
columns of bytes, one bit a pixel, each column padded with COL_PAD blank pixels at each end and
stored in the order it's swept (even columns down, odd columns up, so an odd column's bits are
reversed). Drawn left to right, back and forth.

Each routine's timing, with t = 0 when the ramp goes on (a column's start) and e = 16 x bytes
when it goes off (its end), as measured in vecx (beam.patch: writes as instructions start, the
ramp and DAC 13 cycles late, the shift register's bits 2 cycles after a write, then 2 cycles a
bit):

    e       STY <port_b     ramp off, mux on (to Y), DAC = the next column's Y speed: one store
    e+6     DEC count, LBEQ out, LDA ,X+ (the next column's first byte), LDB #$01 (the ramp on),
            LDY #(the Y speed for the column after)      (the sample-and-hold settles meanwhile)
    e+30    STU <port_b     mux off, DAC = 40 (the slide across): U = $8128 throughout
    e+35=0  STB <port_b     ramp on
    4       CLR <port_a     X speed 0: the beam slid a pixel across in the 4 cycles
    12      STA <shift_reg  the first byte, then a byte every 16 cycles: LDA ,X+ / pad / STA
    16n-4   the last byte, ending at e = 16n

So a column costs 16 x bytes + 35 cycles (38 when the loop goes back to its start: the BRA
after an up column). Nothing turns the spot off: each column ends in blank pixels, and the shift
register keeps its last bit.
"""
import math
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
TEST = os.path.join(HERE, '..', 'test')
sys.path.insert(0, HERE)

UNIT = 41000 / 256              # beam units a BBC pixel
SPEED = 80                      # sweep speed: a pixel in 2 cycles
COL_PAD = 2                     # blank pixels at each end of a column (the slide crosses 2)
COUNT = '$C880'                 # the column count, in RAM the BIOS doesn't use
TURN = 35                       # cycles from a column's end to the next's start (38 after the BRA)
DRIFT_COLUMNS = os.environ.get('M1_DRIFT_COLUMNS') == '1'
SR0 = int(os.environ.get('M1_SR0', '12'))
                                # when a column's first byte is written, from the ramp going on:
                                # 12 lines the bits up with the beam in vecx; MAME needs them about
                                # 1.7 cycles earlier (10)
                                # a constant X speed through each column (a pixel across in a
                                # column's time) instead of the slide at its start: MAME applies a
                                # DAC value 13 cycles late, reading it then, so it loses the slide's
                                # 4-cycle pulse


def delay(n):
    assert n == 0 or n >= 2, n
    out = []
    if n % 2:
        out.append(('brn     *', 3))
        n -= 3
    return out + [('nop', 2)] * (n // 2)


class Code:
    def __init__(self):
        self.out = []

    def ins(self, op, c, note=''):
        self.out.append('                %-31s ;%3d %s' % (op, c, note))

    def label(self, name):
        self.out.append(name)

    def comment(self, text):
        self.out.append('; ' + text)


def column_routine(nb):
    """
    The column routine for columns of nb bytes: entries colN_down and colN_up (facing right:
    the first column at the left, the next a pixel to the right), colN_down_l and colN_up_l
    (facing left: the same data, the first column at the right, the next a pixel to the left,
    so the sprite comes out mirrored).
    """
    c = Code()
    n = nb
    c.comment('columns of %d bytes (%d pixels): %d cycles a column (%d after an up column)'
              % (n, 8 * n, 16 * n + TURN, 16 * n + TURN + 3))
    c.comment('in: X = the first column\'s data, %s = the number of columns + 1, the beam at the' % COUNT)
    c.comment('first column\'s start (half a pixel left of it, at the top for _down, the bottom for _up)')

    def across(left):
        if DRIFT_COLUMNS:
            v = max(1, round(10 / n))
            c.ins('ldu     #$81%02X' % ((-v if left else v) & 0xFF), 3,
                  'port B = mux off, DAC = the drift across (%s)' % ('left' if left else 'right'))
        else:
            c.ins('ldu     #$81%02X' % ((-40 if left else 40) & 0xFF), 3,
                  'port B = mux off, DAC = %d: the slide across' % (-40 if left else 40))

    def prologue():
        c.ins('lda     #$81', 2)
        c.ins('sta     <VIA_port_b', 4, 'ramp off, mux off, before port B takes over the ramp')
        c.ins('lda     #$18', 2)
        c.ins('sta     <VIA_aux_cntl', 4, 'ACR: ramp from port B, shift register out on the clock')

    def half(down):
        name = 'col%d_%s_loop' % (n, 'd' if down else 'u')
        c.label(name)
        t = 6                                               # (after the STY at e)
        c.ins('dec     %s' % COUNT, 7, 'the sample-and-hold settles from here...')
        c.ins('lbeq    col%d_out' % n, 5, '(5 not branching)')
        c.ins('lda     ,x+', 6, 'the first byte')
        c.ins('ldb     #$01', 2, 'port B = ramp on')
        c.ins('ldy     #$80%02X' % ((SPEED if down else -SPEED) & 0xFF), 4,
              'the Y speed after this column (%s)' % ('up' if down else 'down'))
        t += 7 + 5 + 6 + 2 + 4
        c.ins('stu     <VIA_port_b', 5, 'e+%d: ...to here: mux off, DAC = the slide' % t)
        t += 5
        assert t == TURN, t
        c.ins('stb     <VIA_port_b', 4, 't = 0: ramp on')
        if DRIFT_COLUMNS:
            for op, cyc in delay(SR0 - 4):
                c.ins(op, cyc)
        else:
            assert SR0 >= 12, SR0
            c.ins('clr     <VIA_port_a', 6, 't = 4: X speed 0 (the slide: a pixel across)')
            for op, cyc in delay(SR0 - 10):
                c.ins(op, cyc)
        c.ins('sta     <VIA_shift_reg', 4, 't = %d: byte 0' % SR0)
        tt = SR0 + 4
        for j in range(1, n):
            c.ins('lda     ,x+', 6)
            tt += 6
            s = SR0 + 16 * j
            for op, cyc in delay(s - tt):
                c.ins(op, cyc)
            c.ins('sta     <VIA_shift_reg', 4, 't = %d: byte %d' % (s, j))
            tt = s + 4
        for op, cyc in delay(16 * n - tt):                  # (the ramp stays on 16 x bytes)
            c.ins(op, cyc)
        tt = 16 * n
        c.ins('sty     <VIA_port_b', 6, 't = %d = e: ramp off, mux on, DAC = the next Y speed' % tt)

    c.comment('facing left: the same columns, drawn from the right, the slide going left')
    c.label('col%d_down_l' % n)
    across(True)
    c.ins('lbra    col%d_down_c' % n, 5, '(not timed)')
    c.label('col%d_up_l' % n)
    across(True)
    c.ins('lbra    col%d_up_c' % n, 5, '(not timed)')
    c.label('col%d_down' % n)
    across(False)
    c.label('col%d_down_c' % n)
    prologue()
    c.ins('ldy     #$80%02X' % (-SPEED & 0xFF), 4, 'Y speed down')
    c.ins('sty     <VIA_port_b', 6, 'mux on, DAC = the first Y speed')
    half(True)
    half(False)
    if n <= 6:
        c.ins('bra     col%d_d_loop' % n, 3, '(in the settling time)')
    else:
        c.ins('lbra    col%d_d_loop' % n, 5, '(in the settling time; too far for BRA)')
    c.label('col%d_up' % n)
    across(False)
    c.label('col%d_up_c' % n)
    prologue()
    c.ins('ldy     #$80%02X' % (SPEED & 0xFF), 4, 'Y speed up')
    c.ins('sty     <VIA_port_b', 6, 'mux on, DAC = the first Y speed')
    c.ins('bra     col%d_u_loop' % n, 3)
    c.label('col%d_out' % n)
    c.ins('lda     #$81', 2)
    c.ins('sta     <VIA_port_b', 4, 'mux off')
    c.ins('lda     #$98', 2)
    c.ins('sta     <VIA_aux_cntl', 4, 'ACR back: the ramp from timer 1 (run out: off)')
    c.ins('rts', 5)
    return c.out


# --- sprites -------------------------------------------------------------------------------------

def sprite_grid(steamfrak, name, frame=0, frames=1):
    im = Image.open(os.path.join(steamfrak, 'assets', 'sprites', name + '.png')).convert('RGBA')
    fw = im.width // frames
    grid = []
    for y in range(im.height):
        row = ''
        for x in range(frame * fw, frame * fw + fw):
            r, g, b, a = im.getpixel((x, y))
            row += '.' if a < 128 else '#' if (r, g, b) == (0, 0, 0) else \
                'y' if (r > 200 and g > 200 and b < 100) else 'm'
        grid.append(row)
    return grid


def column_data(grid, lit='#'):
    """(bytes per column, [column bytes...]) in sweep order (even down, odd up)."""
    h, w = len(grid), len(grid[0])
    nb = math.ceil((h + 2 * COL_PAD) / 8)
    cols = []
    for c in range(w):
        bits = [0] * (8 * nb)
        for r in range(h):
            bits[COL_PAD + r] = 1 if grid[r][c] in lit else 0
        if c % 2:
            bits = bits[::-1]
        cols.append([int(''.join(map(str, bits[i * 8:i * 8 + 8])), 2) for i in range(nb)])
    return nb, cols


def drift_rows_routine(nb, nrows):
    """
    Rows for small things (keys, the yoyo), nb bytes a row, back and forth without stopping:
    Y's sample-and-hold holds a small speed down for the whole thing (the drift: a row's pitch
    in a row's time), the ramp stays on, and each turn is just the X speed flipped, so each row
    slopes down a pitch as it goes. t = 0: the ramp on; row r starts at 16 x nb x r.
    """
    c = Code()
    drift = max(1, round(10 / nb))          # 160 units a pixel / (16 nb cycles a row)
    c.comment('drifting rows of %d bytes, %d of them: %d cycles; drift %d (rows %d units apart)'
              % (nb, nrows, 16 * nb * nrows, drift, drift * 16 * nb))
    c.comment('in: X = the rows\' data (in sweep order), the beam at the first row\'s left end')
    c.label('rows%d_%d' % (nb, nrows))
    c.ins('lda     #$81', 2)
    c.ins('sta     <VIA_port_b', 4, 'ramp off, mux off, before port B takes over the ramp')
    c.ins('lda     #$18', 2)
    c.ins('sta     <VIA_aux_cntl', 4, 'ACR: ramp from port B, shift register out on the clock')
    c.ins('ldu     #$8150', 3, '(for the ramp off at the end)')
    c.ins('ldy     #$80%02X' % (-drift & 0xFF), 4)
    c.ins('sty     <VIA_port_b', 6, 'mux on: Y speed = the drift')
    c.ins('lda     ,x+', 6, 'the first byte (the sample-and-hold settles...)')
    c.ins('ldb     #$%02X' % (-SPEED & 0xFF), 2, '(X speed for row 1)')
    c.ins('ldy     #$0150', 4, '...')
    c.ins('sty     <VIA_port_b', 6, 't = 0: ramp on, mux off, X speed 80 (one store)')
    c.ins('nop', 2)
    c.ins('nop', 2)
    c.ins('nop', 2)
    c.ins('sta     <VIA_shift_reg', 4, 't = 12: byte 0')
    t = 16
    for r in range(nrows):
        R = 16 * nb * r
        if r > 0:
            assert t == R, (t, R)
            c.ins('stb     <VIA_port_a', 4, 't = %d: row %d: X speed %s' % (R, r, '-80' if r % 2 else '+80'))
            c.ins('lda     ,x+', 6)
            c.ins('ldb     #$%02X' % ((SPEED if r % 2 else -SPEED) & 0xFF), 2, '(X speed for the next row)')
            c.ins('sta     <VIA_shift_reg', 4, 't = %d' % (R + 12))
            t = R + 16
        for j in range(1, nb):
            c.ins('lda     ,x+', 6)
            t += 6
            s = R + 12 + 16 * j
            for op, cyc in delay(s - t):
                c.ins(op, cyc)
            c.ins('sta     <VIA_shift_reg', 4, 't = %d' % s)
            t = s + 4
    end = 16 * nb * nrows
    assert t == end, (t, end)
    c.ins('stu     <VIA_port_b', 5, 't = %d: ramp off' % end)
    for op, cyc in delay(7):
        c.ins(op, cyc)
    c.ins('clr     <VIA_shift_reg', 6, 't = %d: spot off (the last bits are shown)' % (end + 12))
    c.ins('lda     #$98', 2)
    c.ins('sta     <VIA_aux_cntl', 4, 'ACR back')
    c.ins('rts', 5)
    return c.out


def strip_routine():
    """
    Two rows of any length (platforms on a line): row 0 to the right, a pixel down, row 1 back
    to the left. A data-driven byte loop: LDA ,X+ / STA >shift_reg / DECB / BNE, 16 cycles.
    in: X = row 0's bytes, ROW1 = row 1's (in its sweep order), B = bytes a row (2 or more),
    the beam at row 0's left end.
    """
    c = Code()
    c.comment('two rows of any length: 32 x bytes + ~140 cycles')
    c.label('strip')
    c.ins('stb     %s' % COUNT, 5)
    c.ins('lda     #$81', 2)
    c.ins('sta     <VIA_port_b', 4, 'ramp off, mux off, before port B takes over the ramp')
    c.ins('lda     #$18', 2)
    c.ins('sta     <VIA_aux_cntl', 4, 'ACR')
    c.ins('ldu     #$8100', 3, '(the ramp off)')

    def ysh(value, then):
        c.ins('ldy     #$80%02X' % (value & 0xFF), 4)
        c.ins('sty     <VIA_port_b', 6, 'mux on: Y speed %d' % value)
        c.ins('ldy     #$81%02X' % (then & 0xFF), 4, '(the sample-and-hold settles)')
        c.ins('nop', 2)
        c.ins('nop', 2)
        c.ins('nop', 2)
        c.ins('sty     <VIA_port_b', 6, 'mux off, DAC (X speed) %d' % then)

    def row(label):
        c.ins('ldb     %s' % COUNT, 5)
        c.ins('decb', 2, '(bytes - 1 in the loop)')
        c.ins('lda     #$01', 2)
        c.ins('sta     <VIA_port_b', 4, 't = 0: ramp on')
        c.ins('nop', 2)
        c.label(label)
        c.ins('lda     ,x+', 6, 't = 6 + 16i')
        c.ins('sta     >$D000+VIA_shift_reg', 5, 't = 12 + 16i')
        c.ins('decb', 2)
        c.ins('bne     %s' % label, 3)
        c.ins('lda     ,x+', 6, 't = 16n - 10: the last byte')
        c.ins('sta     <VIA_shift_reg', 4, 't = 16n - 4')
        c.ins('stu     <VIA_port_b', 5, 't = 16n: ramp off')
        for op, cyc in delay(7):
            c.ins(op, cyc)
        c.ins('clr     <VIA_shift_reg', 6, 't = 16n + 12: spot off')

    ysh(0, SPEED)
    row('strip_0')
    # a pixel down: Y speed -40 for 4 cycles, X speed 0
    ysh(-40, 0)
    c.ins('lda     #$01', 2)
    c.ins('ldb     #$81', 2)
    c.ins('sta     <VIA_port_b', 4, 'ramp on...')
    c.ins('stb     <VIA_port_b', 4, '...for 4 cycles: a pixel down')
    c.ins('ldx     %s' % ROW1, 6, 'row 1\'s bytes')
    ysh(0, -SPEED)
    row('strip_1')
    c.ins('lda     #$98', 2)
    c.ins('sta     <VIA_aux_cntl', 4, 'ACR back')
    c.ins('rts', 5)
    return c.out


def row_data(grid, lit='#'):
    """(bytes a row, [row bytes...]) in sweep order (even rows right, odd rows left)."""
    w = len(grid[0])
    nb = math.ceil(w / 8)
    rows = []
    for r, line in enumerate(grid):
        bits = [1 if ch in lit else 0 for ch in line] + [0] * (8 * nb - w)
        if r % 2:
            bits = bits[::-1]
        rows.append([int(''.join(map(str, bits[i * 8:i * 8 + 8])), 2) for i in range(nb)])
    return nb, rows


# --- the scene -----------------------------------------------------------------------------------

class Encoder:
    """A move in vlist_d's format, from the current position (beam units, Y up)."""

    def __init__(self, pos=(0.0, 0.0)):
        self.pos = pos
        self.out = []

    def to(self, target, speed=127):
        dx_t, dy_t = target[0] - self.pos[0], target[1] - self.pos[1]
        while abs(dx_t) > MOVE_TOLERANCE or abs(dy_t) > MOVE_TOLERANCE:
            scale = max(1, min(255, round(math.hypot(dx_t, dy_t) / speed),
                               ), math.ceil(max(abs(dx_t), abs(dy_t)) / 127))
            scale = min(scale, 255)
            # (a move longer than one vector can reach goes on in the next: clamp to the DAC)
            dx = max(-127, min(127, round(dx_t / scale)))
            dy = max(-127, min(127, round(dy_t / scale)))
            if dx == 0 and dy == 0:
                break
            self.out.append((scale, dy, dx, 0))
            self.pos = (self.pos[0] + dx * scale, self.pos[1] + dy * scale)
            dx_t, dy_t = target[0] - self.pos[0], target[1] - self.pos[1]


SPRITES = [  # (label, sprite, frames, columns or rows)
    ('trogg', 'sTrogg_wr_Beeb', 4, 'cols'), ('trogg_climb', 'sTrogg_cu_Beeb', 2, 'cols'),
    ('scrubbly', 'sScrubbly_Beeb', 1, 'cols'), ('poglet', 'sPoglet_Beeb', 1, 'cols'),
    ('hooter', 'sHooter_Beeb', 1, 'cols'), ('gem', 'sGem_Beeb', 1, 'cols'),
    ('balloon', 'sBalloon_Beeb', 1, 'cols'), ('dagger', 'sDagger_Beeb', 1, 'cols'),
    ('bulb', 'sBulb_Beeb', 1, 'cols'), ('ladder', 'sLadder5_Beeb', 1, 'cols'),
    ('chain', 'sChain4_Beeb', 1, 'cols'), ('key', 'sKey_Beeb', 1, 'rows'), ('yoyo', 'sYoyo_Beeb', 4, 'rows'),
]
ROW1 = '$C882'                  # the strip's row 1 pointer, in RAM
MOVE_TOLERANCE = 40             # beam units (a quarter of a pixel): a move's rounding isn't corrected
                                # by a second vector (~100 cycles) if it's no more than this

# the scene: (sprite label, x of the sprite's left edge, y of its top), in pixels from the
# middle of the screen (x right, y down); the window is the whole screen's width
WINDOW = (-103, 103)
SCENE = [
    ('trogg', -95, -60), ('trogg_climb', -64, -60), ('scrubbly', -38, -68), ('poglet', 1, -59),
    ('hooter', 30, -49), ('ladder', 56, -96), ('chain', 76, -100),
    ('gem', -95, 10), ('balloon', -78, 10), ('dagger', -60, 10), ('bulb', -44, 8),
    ('key', -25, 10), ('yoyo', 5, 12),
    ('scrubbly', -118, 40), ('poglet', 90, 40),          # partly off the left and right edges
]
LEDGES = (-120, 30, [(0, 64), (80, 128), (144, 192), (208, 240)])   # x, y, spans: wider than the screen


CHAIN = os.environ.get('M1_CHAIN') == '1'
_beam = [None]                  # where the last object left the beam (chained moves)


def start_move(label_i, sx, sy):
    """
    Reset0Ref, Moveto_d (scale $7F) close, then a vlist_d move the rest of the way; or, with
    M1_CHAIN=1, one vlist_d move straight from where the last object left the beam.
    """
    if CHAIN and _beam[0] is not None:
        e = Encoder(_beam[0])
        e.to((sx, sy))
        code = ['                ldx     #move_%s' % label_i,
                '                jsr     vlist_d']
        data = ['move_%s' % label_i] + ['                fcb     %d,%d,%d,$%02X' % v for v in e.out] + \
            ['                fcb     0,0']
        return code, data
    cx, cy = max(-127, min(127, int(sx / 127))), max(-127, min(127, int(sy / 127)))
    e = Encoder((cx * 127.0, cy * 127.0))
    e.to((sx, sy))
    code = ['                jsr     Reset0Ref',
            '                lda     #$7F',
            '                sta     <VIA_t1_cnt_lo',
            '                ldd     #$%02X%02X' % (cy & 0xFF, cx & 0xFF),
            '                jsr     Moveto_d',
            '                ldx     #move_%s' % label_i,
            '                jsr     vlist_d']
    data = ['move_%s' % label_i] + ['                fcb     %d,%d,%d,$%02X' % v for v in e.out] + \
        ['                fcb     0,0']
    return code, data


def main():
    steamfrak = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    data = {}
    for label, name, frames, how in SPRITES:
        g = sprite_grid(steamfrak, name, 0, frames)
        nb, items = (column_data if how == 'cols' else row_data)(g)
        data[label] = (how, nb, items, len(g), len(g[0]))
    col_sizes = sorted({nb for how, nb, _, _, _ in data.values() if how == 'cols'})
    row_sizes = sorted({(nb, h) for how, nb, _, h, _ in data.values() if how == 'rows'})

    eng = ['; made by vectrex/tools/m1_gen.py: the raster engine', '']
    for nb in col_sizes:
        eng += column_routine(nb) + ['']
    for nb, h in row_sizes:
        eng += drift_rows_routine(nb, h) + ['']
    eng += strip_routine() + ['']
    open(os.path.join(TEST, 'raster_engine.asm'), 'w').write('\n'.join(eng) + '\n')

    out = ['; made by vectrex/tools/m1_gen.py: the test scene', '', 'draw_scene']
    moves = []
    table = []
    for i, (label, x, y) in enumerate(SCENE):
        how, nb, items, h, w = data[label]
        if how == 'cols':
            c0, c1 = max(0, WINDOW[0] - x), min(w, WINDOW[1] - x)
            if c0 >= c1:
                continue
            hs = 8 * nb
            sx = (x + c0 - 0.5) * UNIT
            sy = -((y - COL_PAD) + (hs if c0 % 2 else 0)) * UNIT
            code, mv = start_move(i, sx, sy)
            out.append('; %s at (%d, %d): columns %d-%d of %d, %d bytes each' % (label, x, y, c0, c1 - 1, w, nb))
            out += code
            out += ['                ldx     #%s_data+%d' % (label, c0 * nb),
                    '                lda     #%d' % (c1 - c0 + 1),
                    '                sta     %s' % COUNT,
                    '                jsr     col%d_%s' % (nb, 'up' if c0 % 2 else 'down')]
            cyc = sum(16 * nb + TURN + ((3 if nb <= 6 else 5) if k % 2 == 0 and k > c0 else 0)
                      for k in range(c0, c1))
            table.append(('%s, columns %d-%d of %d' % (label, c0, c1 - 1, w), cyc))
            last = c1 - 1                                 # ends at its last column's far end
            _beam[0] = ((x + last + 0.5) * UNIT, -((y - COL_PAD) + (0 if last % 2 else hs)) * UNIT)
        else:
            if x < WINDOW[0] or x + w > WINDOW[1]:
                continue                                  # (partly off: not drawn)
            sx, sy = x * UNIT, -y * UNIT
            code, mv = start_move(i, sx, sy)
            out.append('; %s at (%d, %d): %d drifting rows of %d bytes' % (label, x, y, h, nb))
            out += code
            out += ['                ldx     #%s_data' % label,
                    '                jsr     rows%d_%d' % (nb, h)]
            table.append(('%s, %d rows' % (label, h), 16 * nb * h + 60))
            drift = max(1, round(10 / nb))
            _beam[0] = ((x + (8 * nb if h % 2 else 0)) * UNIT, -y * UNIT - drift * 16 * nb * h)
        moves += mv
    # the ledges: the top two rows of sLedge1_Beeb, repeated, over the spans; trimmed to the
    # window by the byte (up to 7 pixels past the screen's edge, where they can't be seen)
    lx, ly, spans = LEDGES
    tile = sprite_grid(steamfrak, 'sLedge1_Beeb')[:2]
    width = max(b for _, b in spans)
    full = []
    for r in range(2):
        bits = [1 if any(a <= px < b for a, b in spans) and tile[r][px % 16] in ('#' if r == 0 else 'm')
                else 0 for px in range(width)]
        full.append([int(''.join(map(str, bits[i * 8:i * 8 + 8])), 2) for i in range(width // 8)])
    nfull = width // 8
    b0 = max(0, (WINDOW[0] - lx) // 8)
    b1 = min(nfull, -(-(WINDOW[1] - lx) // 8))
    n = b1 - b0
    sx, sy = (lx + 8 * b0) * UNIT, -(ly + 0.5) * UNIT
    code, mv = start_move('ledges', sx, sy)
    out.append('; ledges at (%d, %d): bytes %d-%d of %d' % (lx, ly, b0, b1 - 1, nfull))
    out += code
    out += ['                ldx     #ledges_row1+%d' % (nfull - b1),
            '                stx     %s' % ROW1,
            '                ldx     #ledges_row0+%d' % b0,
            '                ldb     #%d' % n,
            '                jsr     strip']
    table.append(('ledges, 2 rows of %d bytes' % n, 32 * n + 140))
    moves += mv
    out.append('                rts')
    out.append('')
    out += moves + ['']
    for label, (how, nb, items, h, w) in data.items():
        out.append('%s_data                                  ; %d %s of %d bytes' % (label, len(items), 'columns' if how == 'cols' else 'rows', nb))
        for it in items:
            out.append('                fcb     ' + ','.join('$%02X' % b for b in it))
    out.append('ledges_row0')
    for i in range(0, nfull, 16):
        out.append('                fcb     ' + ','.join('$%02X' % b for b in full[0][i:i + 16]))
    out.append('ledges_row1                             ; (reversed: swept to the left)')
    rev = [int('{:08b}'.format(b)[::-1], 2) for b in reversed(full[1])]
    for i in range(0, nfull, 16):
        out.append('                fcb     ' + ','.join('$%02X' % b for b in rev[i:i + 16]))
    open(os.path.join(TEST, 'm1_data.asm'), 'w').write('\n'.join(out) + '\n')
    for name, cyc in table:
        print('%-34s %5d cycles' % (name, cyc))


if __name__ == '__main__':
    main()
