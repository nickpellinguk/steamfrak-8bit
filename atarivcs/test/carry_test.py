#!/usr/bin/env python3
"""
A first carry-shared section: 'black ladder - coloured object - black ladder' at fixed positions,
inside the row skeleton (Trogg on player 0, the yoyo on missile 0), with one copy of the line code
run for both lines of each row; the carry flag says which line it is.

    python3 atarivcs/test/carry_test.py [OUT_DIR]

    Row:    sta WSYNC                   ; even line
            inc TrogPtr                 ; 5
            sec                         ; 7
            jmp Shared                  ; 10
    Odd:    sta WSYNC                   ; odd line
            asl                         ; 2   yoyo enable from Trogg's front pixel (changes carry)
            sta ENAM0                   ; 5
            clc                         ; 7
            bit $80                     ; 10  pad (carry-safe)
    Shared: ldy Ladder,x / sty GRP1 / sta RESP1     ; 20   left ladder (in the blank: x = 19)
            lda Middle,x                            ; 24
            <pad 5> sta GRP1                        ; 32   after the left ladder's copy
            lda MidCol / sta COLUP1                 ; 38   the object's colour
            sta RESP1                               ; 41   the object: x = 76
            lda #0 / <pad 5> / sta COLUP1           ; 51   black, after the object's copy
            sty GRP1 / sta RESP1                    ; 57   right ladder: x = 124
            bcc OddEnd                              ; 59 (even) / 60 (odd)
            ldy #0 / lda (TrogPtr),y / sta GRP0     ; 69   even tail: Trogg's read
            jmp Odd                                 ; 72   (Odd's STA WSYNC lands on 75)
    OddEnd: dec Count / bne Row                     ; 68   (Row's STA WSYNC lands on 71)
Nothing in the shared block changes carry (loads, stores, NOP and BIT $80 only).
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tiatest  # noqa: E402
from PIL import Image  # noqa: E402

pad = tiatest.pad
BG, MAG, TROGG_COL = 0xAA, 0x58, 0x1C
ROWS = 8
TROGG = [0x18, 0x3C, 0x7F, 0x3C, 0x24, 0x66, 0x00, 0x00]   # original placeholder; row 2 = yoyo
TROGG_X, YOYO_X = 100, 112
CARRY_SAFE = ('ldy', 'sty', 'sta', 'lda', 'nop', 'bit', 'ldx', 'stx', 'inc', 'dec', 'bcc', 'bcs',
              'bne', 'beq', 'bmi', 'bpl', 'bvs', 'bvc', 'jmp')


def shared_block():
    return ['ldy Ladder,x', 'sty GRP1', 'sta RESP1',
            'lda Middle,x', pad(5), 'sta GRP1',
            'lda MidCol', 'sta COLUP1',
            'sta RESP1',
            'lda #0', pad(5), 'sta COLUP1',
            'sty GRP1', 'sta RESP1']


def build(base):
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['GRP0 = $1B', 'COLUP0 = $06', 'RESM0 = $12', 'ENAM0 = $1D', 'NUSIZ0 = $04',
          'TrogPtr = $80', 'Count = $82', 'MidCol = $83']
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
        sta NUSIZ1
        lda #$30
        sta NUSIZ0
        lda #$%02X
        sta MidCol
        lda #>TroggStrip
        sta TrogPtr+1''' % (BG, TROGG_COL, MAG))
    for reg, xx in (('RESP0', TROGG_X), ('RESM0', YOYO_X)):
        c = (xx + 68) // 3 if reg == 'RESM0' else (xx + 63) // 3
        o.append('        sta WSYNC\n        ' + pad(c - 3).replace('\n', '\n        ') + '\n        sta %s' % reg)
    o.append('''        ldx #33
VB:     sta WSYNC
        dex
        bne VB
        sta WSYNC
        lda #0
        sta VBLANK
        lda #<(TroggStrip-1)
        sta TrogPtr
        lda #%d
        sta Count
        ldx #0               ; the section's table index
        lda #0
        jmp Row
        align 256
SectionStart:
Row:    sta WSYNC
        inc TrogPtr
        sec
        jmp Shared
Odd:    sta WSYNC
        asl
        sta ENAM0
        clc
        bit $80
Shared:''' % ROWS)
    for ins in shared_block():
        o += ['        ' + s for s in ins.split('\n') if s.strip()]
    o.append('''        bcc OddEnd
        ldy #0
        lda (TrogPtr),y
        sta GRP0
        jmp Odd
OddEnd: dec Count
        bne Row
SectionEnd:
        sta WSYNC
        lda #0
        sta GRP0
        sta GRP1
        sta ENAM0''')
    used = 1 + 2 * ROWS + 1
    o.append('        ldy #%d\nRest:   sta WSYNC\n        dey\n        bne Rest' % (192 - used))
    o.append('''        lda #2
        sta VBLANK
        ldx #30
OS:     sta WSYNC
        dex
        bne OS
        jmp Frame
        align 256
TroggStrip:''')
    o.append('        .byte ' + ','.join('$%02X' % v for v in TROGG + [0] * 4))
    o.append('Ladder: .byte $81\nMiddle: .byte $3C')
    o.append('        org $FFFC\n        .word Start\n        .word Start')
    open(base + '.asm', 'w').write('\n'.join(o) + '\n')
    subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                   check=True, stdout=subprocess.DEVNULL)
    # the shared block must not change carry
    for ins in shared_block():
        for s in ins.split('\n'):
            assert s.split()[0] in CARRY_SAFE, s
    # section size, and page crossings for its branches
    addr = {}
    for line in open(base + '.lst'):
        f = line.split()
        if len(f) == 3 and f[2] in ('SectionStart', 'SectionEnd', 'Row', 'OddEnd'):
            addr[f[2]] = int(f[1], 16)
    for line in open(base + '.lst'):
        f = line.split()
        if len(f) >= 6 and f[4] in ('bcc', 'bne') and f[5] in addr:
            assert (int(f[1], 16) + 2) >> 8 == addr[f[5]] >> 8, 'page crossing: ' + line
    return addr['SectionEnd'] - addr['SectionStart']


if __name__ == '__main__':
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out', 'carry'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'carry')
    size = build(base)
    print('section code: %d bytes for both lines of a row' % size)
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png').convert('RGB')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    sx = im.width / 160
    bg = im.getpixel((im.width - 2, im.height // 2))
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg) + 1
    MAG_RGB = (192, 78, 170)
    for j in range(2, 2 + 2 * ROWS):
        row = [im.getpixel((int((x + 0.5) * sx), first + j)) for x in range(160)]
        runs, x = [], 0
        while x < 160:
            if row[x] != bg:
                k = x
                while k < 160 and row[k] == row[x]:
                    k += 1
                c = row[x]
                runs.append('%d-%d%s' % (x, k - 1, 'k' if c == (0, 0, 0) else ('M' if c == MAG_RGB else 'T')))
                x = k
            else:
                x += 1
        print('line %2d (%s): %s' % (j - 2, 'even' if j % 2 == 0 else 'odd', '  '.join(runs)))
