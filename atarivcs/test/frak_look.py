#!/usr/bin/env python3
"""
Test kernel: a screen closer to the Frak! look. Cyan background; Trogg once, double width, on
player 0; platforms 8 lines tall (1 black, 2 magenta, 1 black, 4 dark cyan), the body from the
asymmetric playfield and the ends from player-1 copies, both coloured per line from a table;
Frak-style ladders (a pole with short rungs), outline gems, and a Scrubbly (magenta, 8x16), all
player-1 copies retriggered on each line.

    python3 atarivcs/test/frak_look.py [OUT_DIR]

One-line kernel, Y = line 0-191; graphics and colours from page-aligned 256-byte tables.
Object lines: COLUP1 from Col1,y; GRP0 from Trogg,y; two object graphics in A and X; one
RESP1 strobe per object, then GRP1 from A or X. Platform lines (a fixed schedule; values are
immediates per row): GRP1 and a strobe in the blank (end copy at x=19); left PF0; COLUPF and
COLUP1 from PCol,y; left PF1 (by cycle 27), PF2; right PF0, PF1; a strobe (end copy at x=97);
right PF2; then GRP0 (Trogg is at x=124). Object lines clear GRP1 after the last copy, then strobe
RESP1 once more far right so P1's main copy is never drawn.
An object segment starts with one line that clears the playfield.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tiatest  # noqa: E402
from trogg_rows import TROGG, bits  # noqa: E402
from platforms import pf_regs, end_bits, cycles  # noqa: E402
from PIL import Image  # noqa: E402

pad = tiatest.pad

BG, DARK, MAGENTA, BLACK = 0xAA, 0xA4, 0x58, 0x00    # NTSC colours
TROGG_RESP0_END = 62                                  # Trogg at about x = 124 (double width)
TROGG_LINES = (150, 176)                              # standing on the floor (row at 176)

LADDER_POLE, LADDER_RUNG = 0x18, 0x7E                 # a pole with short rungs, every 8 lines
GEM = ['...XX...', '..X..X..', '.X....X.', 'X......X', '.X....X.', '..X..X..', '...XX...']
SCRUBBLY = ['.X....X.', '..X..X..', '.XXXXXX.', 'XXXXXXXX', 'XX.XX.XX', 'XX.XX.XX', 'XXXXXXXX',
            'XXXXXXXX', 'XX....XX', 'X.X..X.X', 'XXXXXXXX', 'XXXXXXXX', 'XXXXXXXX', '.XXXXXX.',
            '.XX..XX.', 'XXX..XXX']
PLATFORM_COLOURS = [BLACK, MAGENTA, MAGENTA, BLACK, DARK, DARK, DARK, DARK]

C1, C2 = 20, 48               # the platform rows' two end strobes: copies at x = 19 and 97

# Platform rows: (first line, (end 1 first, last) or None, (end 2 first, last) or None, body set)
ROWS = {
    'P1': (24, (21, 26), (99, 104), set(range(24, 76)) | set(range(100, 152))),
    'P2': (96, (23, 26), (102, 104), set(range(24, 60)) | set(range(104, 136))),
    'P3': (176, (19, 26), None, set(range(20, 156))),
}
# Object segments: (first line, last line + 1, A table, X table, [(object, strobe end cycle)])
# The strobe cycle c puts the copy at x = 3c - 47.
SEGMENTS = [
    ('obj', 0, 24, 'Scrub', 'Zero', [('a', 29)]),                  # Scrubbly at x=40 on P1
    ('row', 'P1'),
    ('obj', 32, 96, 'Ladder', 'Gem', [('a', 29), ('x', 53)]),      # ladder x=40, gem x=112
    ('row', 'P2'),
    ('obj', 104, 176, 'Ladder', 'Gem', [('a', 31), ('x', 39)]),    # ladder x=46, gem x=70
    ('row', 'P3'),
    ('obj', 184, 192, 'Zero', 'Zero', []),
]


def tables():
    t = {name: [0] * 256 for name in ('Trogg', 'Scrub', 'Ladder', 'Gem', 'Zero', 'Col1', 'PCol')}
    a, b = TROGG_LINES
    for y in range(a, b):
        t['Trogg'][y] = bits(TROGG[(y - a) // 2])
    for i, row in enumerate(SCRUBBLY):
        t['Scrub'][8 + i] = bits(row)
    for y in list(range(32, 96)) + list(range(104, 176)):
        t['Ladder'][y] = LADDER_RUNG if y % 8 == 4 else LADDER_POLE
    for top in (89, 169):
        for i, row in enumerate(GEM):
            t['Gem'][top + i] = bits(row)
    for y in range(256):
        t['Col1'][y] = MAGENTA if y < 24 else BLACK
    for first, *_ in ROWS.values():
        for i, c in enumerate(PLATFORM_COLOURS):
            t['PCol'][first + i] = c
    return t


def row_code(name):
    first, e1, e2, body = ROWS[name]
    (l0, l1, l2), (r0, r1, r2) = pf_regs(body)
    g1 = end_bits(19, *e1) if e1 else 0
    g2 = end_bits(97, *e2) if e2 else 0
    # GRP1 can be written before the first strobe: nothing else of P1 is drawn before x=19.
    # Left PF1 must land by cycle 27: at 28 the first 3 pixels of block 4 (x 16-18) still show
    # the previous line's right-half PF1 (seen in the first run).
    code = ['lda #$%02X' % g1, 'sta GRP1', 'sta RESP1',    # 5, 8 (in the blank: copy x=19)
            'ldx #$%02X' % l1,                             # 10
            'lda #$%02X' % l0, 'sta PF0',                  # 15 (left PF0 <= 22)
            'lda PCol,y', 'sta COLUPF',                    # 22 (before the playfield starts)
            'stx PF1', 'sta COLUP1',                       # 25 (left PF1 <= 27), 28 (before x=19)
            'lda #$%02X' % l2, 'sta PF2',                  # 33 (left PF2 <= 38)
            'lda #$%02X' % r0, 'sta PF0',                  # 38 (right PF0 29-49)
            'lda #$%02X' % r1, 'sta PF1',                  # 43 (right PF1 39-54)
            'lda #$%02X' % g2, 'sta RESP1', 'sta GRP1',    # 48 (copy x=97), 51
            'lda #$%02X' % r2, 'sta PF2',                  # 56 (right PF2 50-65)
            'lda Trogg,y', 'sta GRP0']                     # 63 (Trogg from x=124)
    return code, 63


def obj_code(ta, tx, objs):
    code = ['lda Col1,y', 'sta COLUP1', 'lda Trogg,y', 'sta GRP0',   # 7 14
            'lda %s,y' % ta, 'ldx %s,y' % tx]                         # 22
    cyc = 22
    last_x = None
    for reg, c in objs:
        assert c - 3 >= cyc and (c - 3 - cyc == 0 or c - 3 - cyc >= 2), (c, cyc)
        if c - 3 > cyc:
            code.append(pad(c - 3 - cyc))
        code += ['sta RESP1', 'st%s GRP1' % reg]
        cyc = c + 3
        last_x = 3 * c - 47
    if len(objs) == 1:
        # (Only needed with one object: with two or more, the next line's first strobe resets
        # P1 before the main copy, 16 px left of the last copy, comes round.)
        # Clear GRP1 once the last copy is drawn, or the next line draws P1's main copy (16 px
        # left of the last copy) with whatever is left in GRP1 (seen in the first run).
        done = -(-(68 + last_x + 8) // 3)          # cycle by which the last copy is finished
        code.append('lda #0')
        cyc += 2
        if done - 3 > cyc:
            code.append(pad(max(2, done - 3 - cyc)))
            cyc += max(2, done - 3 - cyc)
        code.append('sta GRP1')
        cyc += 3
        # ...and a spare strobe far right, so P1's main copy waits at the right-hand side and the
        # next line's first strobe resets it before it's drawn (seen in the second run: GRP1
        # written while the main copy, 16 px left of the copy, was still being drawn)
        code.append('sta RESP1')
        cyc += 3
    return code, cyc


def count(code):
    return sum(cycles(i.strip()) for chunk in code for i in chunk.split('\n') if i.strip())


def build(base):
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['GRP0     = $1B', 'COLUPF   = $08', 'PF0      = $0D', 'PF1      = $0E', 'PF2      = $0F']
    o.append('''        seg code
        org $F000
Start:  sei
        cld
        ldx #$FF
        txs
        lda #0
Clear:  sta $00,x
        dex
        bne Clear
Frame:  lda #2
        sta VSYNC
        sta WSYNC
        sta WSYNC
        sta WSYNC
        lda #0
        sta VSYNC
        lda #2
        sta VBLANK
        lda #$%02X
        sta COLUBK
        lda #$%02X
        sta COLUP0
        lda #0
        sta CTRLPF        ; repeat mode, players in front of the playfield
        lda #5
        sta NUSIZ0        ; Trogg double width
        lda #1
        sta NUSIZ1        ; two copies close (each RESP1 strobe gives one copy 16 px on)
        sta WSYNC''' % (BG, MAGENTA))
    o.append('        ' + pad(TROGG_RESP0_END - 3).replace('\n', '\n        '))
    o.append('''        sta RESP0
        ldx #34
VB:     sta WSYNC
        dex
        bne VB
        ldy #0
        sta WSYNC
        lda #0
        sta VBLANK''')
    y = 0
    for i, seg in enumerate(SEGMENTS):
        if seg[0] == 'row':
            first = ROWS[seg[1]][0]
            assert first == y, (seg, y)
            end = first + 8
            code, expect = row_code(seg[1])
            o.append('; --- platform row %s, lines %d-%d' % (seg[1], first, end - 1))
            label = 'S%d' % i
        else:
            _, first, end, ta, tx, objs = seg
            assert first == y, (seg, y)
            code, expect = obj_code(ta, tx, objs)
            o.append('; --- objects, lines %d-%d' % (first, end - 1))
            # first line: clear the playfield (and draw nothing new); counts as a line
            o.append('''        sta WSYNC
        lda #0
        sta PF0
        sta PF1
        sta PF2
        sta GRP1
        iny''')
            label = 'S%d' % i
        assert count(code) == expect, (seg, count(code), expect)
        # the loop (iny, cpy, bne: 7, +1 if bne crosses a page) and the next STA WSYNC (3) must
        # land on or before cycle 75, or each pass takes two scanlines (seen in the third run)
        assert expect + 7 + 1 + 3 <= 76, (seg, expect)
        o.append('%s:     sta WSYNC' % label)
        o += ['        ' + s for chunk in code for s in chunk.split('\n') if s.strip()]
        o.append('        iny\n        cpy #%d\n        bne %s' % (end % 256, label))
        y = end
    assert y == 192, y
    o.append('''        sta WSYNC
        lda #0
        sta GRP0
        sta GRP1
        sta PF0
        sta PF1
        sta PF2
        lda #2
        sta VBLANK
        ldx #29
OS:     sta WSYNC
        dex
        bne OS
        jmp Frame''')
    o.append('        org $F800')
    for name, t in tables().items():
        o.append('%s:' % name)
        for k in range(0, 256, 16):
            o.append('        .byte ' + ','.join('$%02X' % v for v in t[k:k + 16]))
    o.append('        org $FFFC\n        .word Start\n        .word Start')
    open(base + '.asm', 'w').write('\n'.join(o) + '\n')
    subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                   check=True, stdout=subprocess.DEVNULL)


if __name__ == '__main__':
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'frak_look')
    build(base)
    png = tiatest.snapshot(base + '.bin', outdir)
    if not png:
        sys.exit('no snapshot')
    os.replace(png, base + '.png')
    im = Image.open(base + '.png')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    print('snapshot', base + '.png', im.size)
