#!/usr/bin/env python3
"""
Write vectrex/test/raster_test_data.asm for test/raster_test.asm: Trogg and the Scrubbly as
vectors (from art/frak-graphics-v001.svg) with Trogg's head and the Scrubbly's eyes as raster
patches (from the BBC sprites), and a row of ledges as two raster lines.

    python3 vectrex/tools/raster_test.py [../steamfrak]

Scale: the screen is 256 BBC pixels tall (41000 beam units in vecx), so a pixel is 160 units.

Vectors: vlist_d's format (scale, dy, dx, mode), drawn at speed (DAC magnitude) DRAW_SPEED,
moves at MOVE_SPEED. Each vector's rounding goes into the next, so the corners stay within a
fraction of a pixel of where they should be. Y is up for the DAC, down in the sprites.

Raster: the ramp switched by port B (ACR = $18, as the BIOS's text routine does), the X speed
80 (a pixel in 2 cycles, the shift register's rate), the shift register written every 16
cycles, so the bits run on without a break. The rows go back and forth, a pixel apart. The code
is straight-line, generated with every write at a counted cycle. Times in vecx (beam.patch):
writes take effect as their instruction starts, the ramp and the DAC 13 cycles later, the spot
(the shift register's output) 2 cycles after a write to it and then a bit every 2 cycles. So,
from the ramp going on at t = 0: the first byte is written at SR0 (its first bit shows 2 later,
as the beam starts moving: the model says 11, vecx measures 12), each next at 16 more, the ramp
goes off after exactly 2 cycles a pixel (16 x bytes, measured: the beam starts and stops a cycle
later than the model's 13), and the spot off at 16 after the last byte.
"""
import math
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import svg_shapes  # noqa: E402

OUT = os.path.join(HERE, '..', 'test', 'raster_test_data.asm')
UNIT = 41000 / 256              # beam units a BBC pixel
DRAW_SPEED, MOVE_SPEED = 64, 127
RASTER_SPEED = 80               # = UNIT / 2: a pixel per bit, 2 cycles a bit
Y_STEP_SPEED, Y_STEP_TIME = 40, 4   # 40 x 4 = 160: a pixel down between raster rows
SR0 = 12                        # when the first byte is written, from the ramp going on: measured
                                # in vecx (11 puts the bits a cycle ahead of the beam)


class Encoder:
    """Vectors from the current beam position (in beam units, X right, Y up)."""

    def __init__(self):
        self.pos = (0.0, 0.0)
        self.out = []

    def to(self, target, on, speed):
        dx_t, dy_t = target[0] - self.pos[0], target[1] - self.pos[1]
        length = math.hypot(dx_t, dy_t)
        if length < 1:
            return
        scale = max(1, round(length / speed))
        scale = max(scale, math.ceil(max(abs(dx_t), abs(dy_t)) / 127))
        while scale > 255:                      # too long for one vector: half, then the rest
            mid = (self.pos[0] + dx_t / 2, self.pos[1] + dy_t / 2)
            self.to(mid, on, speed)
            dx_t, dy_t = target[0] - self.pos[0], target[1] - self.pos[1]
            scale = max(1, round(math.hypot(dx_t, dy_t) / speed),
                        math.ceil(max(abs(dx_t), abs(dy_t)) / 127))
        dx, dy = round(dx_t / scale), round(dy_t / scale)
        if dx == 0 and dy == 0:
            return
        self.out.append((scale, dy, dx, 0xFF if on else 0))
        self.pos = (self.pos[0] + dx * scale, self.pos[1] + dy * scale)

    def polylines(self, polys, origin):
        for poly in polys:
            pts = [screen(p, origin) for p in poly]
            self.to(pts[0], False, MOVE_SPEED)
            for p in pts[1:]:
                self.to(p, True, DRAW_SPEED)


def screen(p, origin):
    return ((p[0] - origin[0]) * UNIT, -(p[1] - origin[1]) * UNIT)


def vector_list(label, vectors):
    out = [label]
    for scale, dy, dx, mode in vectors:
        out.append('                fcb     %d,%d,%d,$%02X' % (scale, dy, dx, mode))
    out.append('                fcb     0,0')
    return out


# --- raster code ---------------------------------------------------------------------------------

def delay(n):
    assert n == 0 or n >= 2, n
    out = []
    if n % 2:
        out.append(('brn     *', 3))
        n -= 3
    return out + [('nop', 2)] * (n // 2)


def raster_rows(label, rows, comment):
    """
    Code for a raster patch: rows of bits (lists of 0/1, all the same length, a multiple of 8),
    starting with the beam at the top row's left end, the spot off, DP = $D0, ACR = $98. Ends
    with ACR = $98 and the beam at the last row's far end.
    """
    nb = len(rows[0]) // 8
    out = ['; %s: %d rows of %d pixels (%d bytes)' % (comment, len(rows), 8 * nb, nb), label]

    def ins(op, c, note=''):
        out.append('                %-31s ;%3d %s' % (op, c, note))

    def ysh(value):                     # Y's sample-and-hold := value (with the ramp off)
        if value:
            ins('lda     #%d' % value, 2)
            ins('sta     <VIA_port_a', 4, 'DAC')
        else:
            ins('clr     <VIA_port_a', 6, 'DAC = 0')
        ins('lda     #$80', 2)
        ins('sta     <VIA_port_b', 4, 'mux on: to Y (ramp off)')
        ins('nop', 2)
        ins('nop', 2)
        ins('nop', 2, '(settling)')
        ins('lda     #$81', 2)
        ins('sta     <VIA_port_b', 4, 'mux off, ramp off')

    ins('lda     #$81', 2)
    ins('sta     <VIA_port_b', 4, 'ramp off, before port B takes over the ramp')
    ins('lda     #$18', 2)
    ins('sta     <VIA_aux_cntl', 4, 'ACR: ramp from port B, shift register out on the clock')
    ysh(0)
    for r, bits in enumerate(rows):
        right = r % 2 == 0
        if not right:
            bits = bits[::-1]
        byts = [int(''.join(map(str, bits[i * 8:i * 8 + 8])), 2) for i in range(nb)]
        out.append('; row %d, %s: %s' % (r, 'right' if right else 'left',
                                          ' '.join('%02X' % b for b in byts)))
        ins('lda     #%d' % (RASTER_SPEED if right else -RASTER_SPEED), 2)
        ins('sta     <VIA_port_a', 4, 'X speed')
        ins('ldb     #$01', 2)
        # t = 0: the ramp on
        ins('stb     <VIA_port_b', 4, 't = 0: ramp on (the beam moves from 13)')
        t = 4
        ins('ldb     #$81', 2, '(for the ramp off)')
        t += 2
        for j, b in enumerate(byts):
            s = SR0 + 16 * j
            ins('lda     #$%02X' % b, 2)
            t += 2
            for op, c in delay(s - t):
                ins(op, c)
            t = s
            # the ramp is on for exactly 2 cycles a pixel, going off at 16 x bytes + SR0 - 12;
            # the last byte's store is long enough to end just then (4 or 5 cycles)
            e = SR0 + 16 * nb - 12
            if j == nb - 1 and e - s == 5:
                ins('sta     >$D000+VIA_shift_reg', 5, 't = %d: last byte (5 cycles: the ramp off at %d)' % (s, e))
                t += 5
            else:
                assert j < nb - 1 or e - s == 4, (e, s)
                ins('sta     <VIA_shift_reg', 4, 't = %d' % s)
                t += 4
        assert t == e, (t, e)
        ins('stb     <VIA_port_b', 4, 't = %d: ramp off (the beam stops at %d)' % (e, e + 13))
        t += 4
        off = SR0 + 16 * nb
        for op, c in delay(off - t):
            ins(op, c)
        ins('clr     <VIA_shift_reg', 6, 't = %d: spot off (shows at %d)' % (off, off + 2))
        if r < len(rows) - 1:
            # a pixel down, for the next row
            ysh(-Y_STEP_SPEED)
            ins('clr     <VIA_port_a', 6, 'X speed 0')
            ins('ldb     #$01', 2)
            ins('lda     #$81', 2)
            ins('stb     <VIA_port_b', 4, 'ramp on ...')
            ins('sta     <VIA_port_b', 4, '... for %d cycles: a pixel down' % Y_STEP_TIME)
            ysh(0)
    ins('lda     #$98', 2)
    ins('sta     <VIA_aux_cntl', 4, 'ACR back: the ramp from timer 1 (run out: off)')
    ins('rts', 5)
    return out


def sprite_bits(steamfrak, name, frame, x0, y0, w, h, lit, width8=None):
    im = Image.open(os.path.join(steamfrak, 'assets', 'sprites', name + '.png')).convert('RGBA')
    n = {'sTrogg_wr_Beeb': 4}.get(name, 1)
    fw = im.width // n
    rows = []
    for y in range(y0, y0 + h):
        bits = []
        for x in range(x0, x0 + w):
            r, g, b, a = im.getpixel((frame * fw + x, y))
            kind = '.' if a < 128 else '#' if (r, g, b) == (0, 0, 0) else \
                'y' if (r > 200 and g > 200 and b < 100) else 'm'
            bits.append(1 if kind in lit else 0)
        w8 = width8 or 8 * math.ceil(w / 8)
        rows.append(bits + [0] * (w8 - len(bits)))
    return rows


def main():
    steamfrak = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    art = svg_shapes.shapes()
    out = ['; made by vectrex/tools/raster_test.py', '']

    # Trogg: the body as vectors (the tracing without the head: polylines wholly above row 9),
    # the head as a raster patch: rows 0-8, columns 5-25, the black pixels lit
    trogg_o = (13, 33)
    body = [p for p in art[('sTrogg_wr_Beeb', 0)] if max(y for _, y in p) > 9]
    e = Encoder()
    e.polylines(body, trogg_o)
    hx, hy, hw, hh = 5, 0, 21, 9
    e.to(screen((hx, hy + 0.5), trogg_o), False, MOVE_SPEED)
    out += ['; Trogg (sTrogg_wr_Beeb frame 0): body, then a move to the head\'s top left (%d polylines)'
            % len(body)] + vector_list('trogg_body', e.out) + ['']
    out += raster_rows('trogg_head', sprite_bits(steamfrak, 'sTrogg_wr_Beeb', 0, hx, hy, hw, hh, '#'),
                       "Trogg's head, the black pixels") + ['']
    n_trogg = len(e.out)

    # The Scrubbly: the body as vectors (without the eye polylines), the eyes as a raster patch:
    # rows 16-21, columns 10-24, the yellow pixels lit
    scrub_o = (16, 41)

    def is_eye(p):
        return min(y for _, y in p) > 15 and max(y for _, y in p) < 23 and \
            min(x for x, _ in p) > 8 and max(x for x, _ in p) < 26
    body = [p for p in art[('sScrubbly_Beeb', 0)] if not is_eye(p)]
    e = Encoder()
    e.polylines(body, scrub_o)
    ex, ey, ew, eh = 10, 16, 15, 6
    e.to(screen((ex, ey + 0.5), scrub_o), False, MOVE_SPEED)
    out += ['; The Scrubbly: body, then a move to the eyes\' top left (%d polylines)' % len(body)]
    out += vector_list('scrub_body', e.out) + ['']
    out += raster_rows('scrub_eyes', sprite_bits(steamfrak, 'sScrubbly_Beeb', 0, ex, ey, ew, eh, 'y'),
                       "the Scrubbly's eyes, the yellow pixels") + ['']
    n_scrub = len(e.out)

    # A row of ledges: the ledge's top two rows (row 0's black pixels, row 1's magenta), repeated
    # every 16 pixels, in three ledges: 64, 48 and 48 pixels long, 16 apart (192 pixels in all)
    tile = sprite_bits(steamfrak, 'sLedge1_Beeb', 0, 0, 0, 16, 1, '#') + \
        sprite_bits(steamfrak, 'sLedge1_Beeb', 0, 0, 1, 16, 1, 'm')
    spans = [(0, 64), (80, 128), (144, 192)]
    rows = []
    for t in tile:
        rows.append([t[x % 16] if any(a <= x < b for a, b in spans) else 0 for x in range(192)])
    out += raster_rows('ledges', rows, 'three ledges, the top two rows of sLedge1_Beeb repeated') + ['']

    open(OUT, 'w').write('\n'.join(out) + '\n')
    print('%s: Trogg %d vectors, the Scrubbly %d' % (OUT, n_trogg, n_scrub))


if __name__ == '__main__':
    main()
