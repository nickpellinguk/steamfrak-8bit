#!/usr/bin/env python3
"""
Ghost check for single-object rows in the two-line carry-shared kernel. A row with one P1 copy
(NUSIZ1 = two close, one RESP1 strobe ending at cycle c gives a copy at x = 3c - 47) leaves P1's
main copy 16 px left of it; on the next line, if GRP1 already holds the ladder graphic when that
main copy comes round, a ghost would show at x - 16. Does the next line's strobe (at the same
cycle, before the main copy is drawn) cancel it?

    python3 atarivcs/test/ghost_test.py [OUT_DIR]

Body (per row, line-shared by carry, X counts lines, INX in the even tail):
    even: sta WSYNC / inc TrogPtr / sec / bit $80                 -> shared at 10
    odd:  sta WSYNC / asl / sta ENAM0 / clc / jmp shared          -> shared at 10
    shared: lda Lad,x / sta GRP1 (17, early: before any ghost) / pad / sta RESP1 (c) /
            bcs even tail / inx / rts
    even tail: ldy #0 / lda (TrogPtr),y / sta GRP0 / VARIANT / inx / jmp odd
Variants: A nothing; B sty GRP1 (GRP1 = 0 at the odd line's start); C sty RESP1 (late strobe).
Sections: for each variant, ladders at x 28, 64, 100, 4 rows each, then a blank-row separator.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tiatest  # noqa: E402
from PIL import Image  # noqa: E402

pad = tiatest.pad
BG = 0xAA
XS = (28, 64, 100)
VARIANTS = {'A': [], 'B': ['sty GRP1'], 'C': ['sty RESP1'], 'D': [], 'E': ['sty GRP1']}
ROWS = 4


def body(name, x, variant):
    c = (x + 47) // 3
    assert 3 * c - 47 == x
    gap = c - 3 - 17
    out = ['%s:' % name, 'sta WSYNC', 'inc TrogPtr', 'sec', 'bit $80', '%s_s:' % name]
    if variant in 'DE':
        # D: GRP1 = 0 while the old main copy is drawn (c+2..c+4); the ladder lands at c+5, then
        #    GRP1 is cleared after the copy (c+10 on), so every line starts with GRP1 = 0.
        # E: as D, but the clear after the copy is left out (only the even tail's STY GRP1).
        out += ['lda Lad,x'] + pad(c - 3 - 14).split('\n') if c - 3 - 14 > 1 else ['lda Lad,x']
        assert c - 17 >= 2 or c == 17, c
        out += ['sta RESP1', 'nop', 'sta GRP1']                  # strobe ends c, GRP1 at c+5
        if variant == 'D':
            out += ['lda #0', 'sta GRP1']                        # c+10
        out += ['bcs %s_e' % name, 'inx', 'rts',
            '%s_e:' % name, 'ldy #0', 'lda (TrogPtr),y', 'sta GRP0'] + VARIANTS[variant] + [
            'inx', 'sta WSYNC', 'asl', 'sta ENAM0', 'clc', 'jmp %s_s' % name]
        return out
    out += ['lda Lad,x', 'sta GRP1']
    if gap == 1:
        out[-1] = 'sta.w GRP1'
    elif gap:
        out += pad(gap).split('\n')
    out += ['sta RESP1', 'bcs %s_e' % name, 'inx', 'rts',
            '%s_e:' % name, 'ldy #0', 'lda (TrogPtr),y', 'sta GRP0'] + VARIANTS[variant] + [
            'inx', 'sta WSYNC', 'asl', 'sta ENAM0', 'clc', 'jmp %s_s' % name]
    return out


def build(base):
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['GRP0 = $1B', 'COLUP0 = $06', 'ENAM0 = $1D', 'TrogPtr = $80']
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
        lda #0
        sta COLUP1
        sta GRP1
        sta GRP0
        sta ENAM0
        lda #1
        sta NUSIZ1
        lda #>Zero
        sta TrogPtr+1
        lda #<Zero
        sta TrogPtr
        ldx #36
VB:     sta WSYNC
        dex
        bne VB
        lda #0
        sta VBLANK''' % BG)
    names, lines = [], 0
    for v in VARIANTS:
        for x in XS:
            n = 'B%s%d' % (v, x)
            names.append((n, v, x))
            o.append('        ldx #0')
            o += ['        jsr %s' % n] * ROWS
            o += ['        sta WSYNC', '        lda #0', '        sta GRP1', '        sta WSYNC']   # separator
            lines += 2 * ROWS + 2
    o.append('''        ldy #%d
Rest:   sta WSYNC
        dey
        bne Rest
        lda #2
        sta VBLANK
        ldx #30
OS:     sta WSYNC
        dex
        bne OS
        jmp Frame''' % (192 - lines))
    for n, v, x in names:
        o.append('        align 64')
        for c in body(n, x, v):
            o.append(c if c.endswith(':') else '        ' + c)
    o.append('        align 256\nLad:    .byte ' + ','.join('$%02X' % (0x7E if k % 4 == 0 else 0x42) for k in range(16)))
    o.append('        align 256\nZero:   ds 256, 0')
    o.append('        org $FFFC\n        .word Start\n        .word Start')
    open(base + '.asm', 'w').write('\n'.join(o) + '\n')
    r = subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if r.returncode:
        print(r.stdout[-1500:])
        sys.exit('dasm failed')
    return names


if __name__ == '__main__':
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out', 'ghost'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'ghost')
    names = build(base)
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png').convert('RGB')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    sx = im.width / 160
    bg = im.getpixel((im.width - 2, im.height // 2))
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg)
    y = 0
    for n, v, x in names:
        print('variant %s, ladder x %d:' % (v, x))
        for j in range(2 * ROWS + 1):
            row = [im.getpixel((int((q + 0.5) * sx), first + y + j)) for q in range(160)]
            px = [q for q in range(160) if row[q] != bg]
            runs, k = [], 0
            while k < len(px):
                m = k
                while m + 1 < len(px) and px[m + 1] == px[m] + 1:
                    m += 1
                runs.append('%d-%d' % (px[k], px[m]))
                k = m + 1
            ghost = any(x - 16 <= q < x - 8 for q in px)
            print('   line %d: %s%s' % (j, ' '.join(runs) or '-', '   <-- GHOST' if ghost else ''))
        y += 2 * ROWS + 2
