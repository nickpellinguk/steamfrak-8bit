#!/usr/bin/env python3
"""
Double-sled 'ladder - coloured object - ladder' inside the full row skeleton (Trogg on player 0,
the yoyo on missile 0), to measure the design range.

    python3 atarivcs/test/sled2_test.py [OUT_DIR]

Row (two lines). Even line:
    sta WSYNC
    inc TrogPtr              ; 5    row skeleton
    ldy Ladder,x / sty GRP1 / sta RESP1     ; 15   left ladder (in the blank: x = 19)
    lda MidCol / ldy Middle,x               ; 22
    jmp (P1e)                ; sled d1
    sta RESP1 / sta COLUP1 / sty GRP1        ; the middle object, its colour, its graphics
    jmp (P2e)                ; sled D - d1 (variant A only)
    lda #0 / sta COLUP1      ; black again
    ldy Ladder,x / sty GRP1 / sta RESP1     ; right ladder (variant A only)
    ldy #0 / lda (TrogPtr),y / sta GRP0     ; row skeleton: Trogg's row, kept in A
Odd line:
    sta WSYNC
    asl / sta ENAM0          ; 5    row skeleton: the yoyo, from Trogg's front pixel
    (the same block, with its own sleds P1o / P2o)
    dec Count / beq out / jmp <row>     (a BNE can't reach back over the inline sleds)
Variant A (both ladders) has the sled total D = 6 (the even line is then full); variant B (no right
ladder: one sled) can use a long sled.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tiatest  # noqa: E402
from PIL import Image  # noqa: E402

BG, MAG, TROGG_COL = 0xAA, 0x58, 0x1C
ROWS = 6
SLED_LEN = 20                            # $C9 bytes: delays 2..23
# Trogg's rows (single width): row 2 has its front pixel (bit 0) set, which switches the yoyo on
TROGG = [0x18, 0x3C, 0x7F, 0x3C, 0x24, 0x66]
TROGG_X, YOYO_X = 100, 112


def sled(n):
    return [0xC9] * n + [0xC5, 0xEA]


def delay(n, e):
    s, p, c = sled(n), e, 0
    while p < len(s):
        if s[p] == 0xC9:
            c, p = c + 2, p + 2
        elif s[p] == 0xC5:
            c, p = c + 3, p + 2
        else:
            c, p = c + 2, p + 1
    return c


def entry(n, d):
    for e in range(n + 2):
        if delay(n, e) == d:
            return e
    raise ValueError(d)


def sections():
    out = []
    D = 6
    for d1 in (2, 3, 4):
        out.append(('A', d1, D - d1))
    for d1 in (2, 6, 10, 14, 18, 21):
        out.append(('B', d1, None))
    return out


def build(base):
    secs = sections()
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['GRP0 = $1B', 'COLUP0 = $06', 'RESM0 = $12', 'ENAM0 = $1D', 'NUSIZ0 = $04',
          'TrogPtr = $80', 'Count = $82', 'MidCol = $83', 'P1e = $84', 'P2e = $86', 'P1o = $88', 'P2o = $8A']
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
        sta COLUP1
        lda #1
        sta NUSIZ1           ; two copies close
        lda #$30
        sta NUSIZ0           ; Trogg single width, missile 0 (the yoyo) 8 px
        lda #$%02X
        sta MidCol
        lda #>TroggStrip
        sta TrogPtr+1
        lda #>Sleds
        sta P1e+1
        sta P2e+1
        sta P1o+1
        sta P2o+1''' % (BG, TROGG_COL, MAG))
    for reg, xx in (('RESP0', TROGG_X), ('RESM0', YOYO_X)):
        c = (xx + 68) // 3 if reg == 'RESM0' else (xx + 63) // 3
        o.append('        sta WSYNC\n        ' + tiatest.pad(c - 3).replace('\n', '\n        ') + '\n        sta %s' % reg)
    o.append('''        ldx #33
VB:     sta WSYNC
        dex
        bne VB
        sta WSYNC
        lda #0
        sta VBLANK''')
    used = 1
    sled_blocks = []
    for i, (var, d1, d2) in enumerate(secs):
        o.append('; --- section %d: variant %s, sleds %s / %s' % (i, var, d1, d2))
        o.append('        sta WSYNC')
        for nm, sl, d in (('P1e', 'S1e_%d' % i, d1), ('P1o', 'S1o_%d' % i, d1),
                          ('P2e', 'S2e_%d' % i, d2), ('P2o', 'S2o_%d' % i, d2)):
            if d is None:
                continue
            e = entry(SLED_LEN, d)
            o.append('        lda #<(%s+%d)\n        sta %s\n        lda #>(%s+%d)\n        sta %s+1' % (sl, e, nm, sl, e, nm))
        o.append('        lda #<(TroggStrip-1)\n        sta TrogPtr\n        lda #%d\n        sta Count\n        ldx #0\n        lda #0' % ROWS)
        o.append('        jmp R%d\n        align 128' % i)

        def block(line):
            P1, P2 = ('P1e', 'P2e') if line == 'e' else ('P1o', 'P2o')
            b = ['        ldy Ladder,x', '        sty GRP1', '        sta RESP1',
                 '        lda MidCol', '        ldy Middle,x', '        jmp (%s)' % P1,
                 'C1%s_%d:' % (line, i),
                 '        sta RESP1', '        sta COLUP1', '        sty GRP1']
            if var == 'A':
                b += ['        jmp (%s)' % P2, 'C2%s_%d:' % (line, i)]
            b += ['        lda #0', '        sta COLUP1']
            if var == 'A':
                b += ['        ldy Ladder,x', '        sty GRP1', '        sta RESP1']
            return b
        o.append('R%d:     sta WSYNC          ; even line' % i)
        o.append('        inc TrogPtr')
        o += block('e')
        o.append('        ldy #0\n        lda (TrogPtr),y\n        sta GRP0\n        sta WSYNC          ; odd line')
        o.append('        asl\n        sta ENAM0')
        o += block('o')
        o.append('        dec Count\n        beq X%d\n        jmp R%d\nX%d:' % (i, i, i))   # (BNE can't reach over the sleds)
        o.append('        sta WSYNC\n        lda #0\n        sta GRP0\n        sta GRP1\n        sta ENAM0')
        sled_blocks.append(i)
        used += 1 + 2 * ROWS + 1
    o.append('        ldy #%d\nRest:   sta WSYNC\n        dey\n        bne Rest' % (192 - used))
    o.append('''        lda #2
        sta VBLANK
        ldx #30
OS:     sta WSYNC
        dex
        bne OS
        jmp Frame''')
    # the sleds: each falls through into its continuation with a JMP (a 3-cycle cost already
    # counted in the sled's own total? no: the JMP is extra), so instead each sled is followed by
    # its continuation code directly: see below
    o.append('        align 256\nSleds:')
    o.append('        align 256\nTroggStrip:')
    o.append('        .byte ' + ','.join('$%02X' % v for v in TROGG + [0] * 4))
    o.append('Ladder: .byte $81\nMiddle: .byte $3C')
    o.append('        org $FFFC\n        .word Start\n        .word Start')
    src = '\n'.join(o) + '\n'
    # put each sled directly before its continuation label, so the sled falls through into it
    sb = ','.join('$%02X' % v for v in sled(SLED_LEN))
    for i, (var, d1, d2) in enumerate(secs):
        for line in 'eo':
            src = src.replace('C1%s_%d:' % (line, i), 'S1%s_%d: .byte %s\nC1%s_%d:' % (line, i, sb, line, i))
            if var == 'A':
                src = src.replace('C2%s_%d:' % (line, i), 'S2%s_%d: .byte %s\nC2%s_%d:' % (line, i, sb, line, i))
    src = src.replace('        lda #>Sleds\n        sta P1e+1\n        sta P2e+1\n        sta P1o+1\n        sta P2o+1\n', '')
    open(base + '.asm', 'w').write(src)
    r = subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if r.returncode:
        print(r.stdout[-1500:])
        sys.exit('dasm failed')
    return secs


def even_cycles(var, d1, d2):
    pre = 3 + 5 + 10 + 7 + 5          # STA WSYNC... (from 0) INC, left ladder, loads, JMP
    mid = 9
    second = (5 + d2) if var == 'A' else 0
    tail = 5 + (10 if var == 'A' else 0) + 10 + 3
    return pre - 3 + d1 + mid + second + tail


if __name__ == '__main__':
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out', 'sled2'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'sled2')
    secs = build(base)
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png').convert('RGB')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    sx = im.width / 160
    bg = im.getpixel((im.width - 2, im.height // 2))
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg) + 1
    MAG_RGB = (192, 78, 170)                   # NTSC $58 in Stella's palette
    y = 1
    for var, d1, d2 in secs:
        y += 1
        for k in (4, 5, 6):                    # around Trogg's hand row
            row = [im.getpixel((int((x + 0.5) * sx), first + y + k)) for x in range(160)]
            runs, x = [], 0
            while x < 160:
                if row[x] != bg:
                    j = x
                    while j < 160 and row[j] == row[x]:
                        j += 1
                    c = row[x]
                    tag = 'k' if c == (0, 0, 0) else ('M' if c == MAG_RGB else 'T')
                    runs.append('%d-%d%s' % (x, j - 1, tag))
                    x = j
                else:
                    x += 1
            print('variant %s sled %2s/%-4s line %d: %s' % (var, d1, d2, k, '  '.join(runs)))
        print('   even line ends at cycle %d (STA WSYNC must land by 75)' % even_cycles(var, d1, d2))
        y += 2 * ROWS + 1
