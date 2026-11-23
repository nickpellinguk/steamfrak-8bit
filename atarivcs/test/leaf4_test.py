#!/usr/bin/env python3
"""
Four-leaf placement: 'black ladder - coloured object - black ladder' where BIT Pos and two branches
choose one of four separate code paths ('leaves'), each with its own STA RESP1 at a freely chosen
cycle, all rejoining at the same cycle. Inside the full row skeleton (Trogg on player 0, the yoyo on
missile 0).

    python3 atarivcs/test/leaf4_test.py [OUT_DIR]

Line (both lines of a row; the even line ends with Trogg's read, the odd line with the loop):
    sta WSYNC
    inc TrogPtr  /  asl + sta ENAM0         ; 5   row skeleton
    ldx #0                                  ; 7   the band's table index
    ldy Ladder,x / sty GRP1 / sta RESP1     ; 17  left ladder (in the blank: x = 19)
    lda Middle,x                            ; 21  A = the middle object's graphics
    ldx MidCol                              ; 24  X = its colour (zero page)
    bit Pos                                 ; 27  N = bit 7, V = bit 6
    bmi N1
    bvs L1
L0: <pad> sta RESP1 / stx COLUP1 / sta GRP1 <pad> jmp J
L1: <pad> sta RESP1 / stx COLUP1 / sta GRP1 <pad> jmp J
N1: bvs L3
L2: <pad> sta RESP1 / stx COLUP1 / sta GRP1 <pad> jmp J
L3: <pad> sta RESP1 / stx COLUP1 / sta GRP1 <pad>        (falls through)
J:  (cycle 51 on every path)
    lda #0 / sta COLUP1                     ; black again
    sty GRP1 / sta RESP1                    ; right ladder
    even: ldy #0 / lda (TrogPtr),y / sta GRP0      odd: dec Count / beq out / jmp row
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
ROWS = 6
TROGG = [0x18, 0x3C, 0x7F, 0x3C, 0x24, 0x66]       # original placeholder; row 2's front pixel = yoyo
TROGG_X, YOYO_X = 100, 112
J = 51                                             # the join cycle
# leaf: (entry cycle after the branches, chosen strobe-end cycle, falls through?)
LEAVES = [(31, 34, False), (32, 36, False), (32, 38, False), (33, 40, True)]   # 2-cycle (6 px) steps; JMP leaves by 39, the last by 42


def leaf_code(entry, strobe, last, name):
    a = strobe - 3 - entry
    b = J - strobe - 9 - (0 if last else 3)
    assert a >= 0 and b >= 0, (name, a, b)
    # an odd pad of 1 is made with a 4-cycle absolute store (STA.W / STX.W) instead of a NOP;
    # odd pads of 3 or more use pad()'s 3-cycle BIT (the flags aren't needed after the decision)
    strobe_ins, writes = 'sta RESP1', ['stx COLUP1', 'sta GRP1']
    if a == 1:
        strobe_ins, a = 'sta.w RESP1', 0
    if b == 1:
        # GRP1 first (it must land well before the copy starts, 7 cycles after the strobe), then the
        # colour as a 4-cycle store landing exactly as the copy's first pixel is drawn. (With the
        # colour first, GRP1 landed as the copy started and its first pixel used the old graphics.)
        writes, b = ['sta GRP1', 'stx.w COLUP1'], 0
    out = ['%s:' % name] + ([pad(a)] if a else []) + [strobe_ins] + writes + ([pad(b)] if b else [])
    if not last:
        out.append('jmp J_%s' % name.split('_', 1)[1])
    return out


def row_line(i, line):
    tag = '%s_%d' % (line, i)
    c = ['sta WSYNC']
    c += ['inc TrogPtr'] if line == 'e' else ['asl', 'sta ENAM0']
    c += ['ldx #0', 'ldy Ladder,x', 'sty GRP1', 'sta RESP1', 'lda Middle,x', 'ldx MidCol',
          'bit Pos', 'bmi N1_%s' % tag, 'bvs L1_%s' % tag]
    c += leaf_code(*LEAVES[0], 'L0_%s' % tag)
    c += leaf_code(*LEAVES[1], 'L1_%s' % tag)
    c += ['N1_%s:' % tag, 'bvs L3_%s' % tag]
    c += leaf_code(*LEAVES[2], 'L2_%s' % tag)
    c += leaf_code(*LEAVES[3], 'L3_%s' % tag)
    c += ['J_%s:' % tag, 'lda #0', 'sta COLUP1', 'sty GRP1', 'sta RESP1']
    if line == 'e':
        c += ['ldy #0', 'lda (TrogPtr),y', 'sta GRP0']
    else:
        c += ['dec Count', 'beq X_%d' % i, 'jmp R_%d' % i]
    return c


def build(base):
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['GRP0 = $1B', 'COLUP0 = $06', 'RESM0 = $12', 'ENAM0 = $1D', 'NUSIZ0 = $04',
          'TrogPtr = $80', 'Count = $82', 'MidCol = $83', 'Pos = $84']
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
        sta VBLANK''')
    used = 1
    for i, pos in enumerate((0x00, 0x40, 0x80, 0xC0)):
        o.append('; --- section %d: Pos = $%02X (leaf %d)' % (i, pos, pos >> 6))
        o.append('        sta WSYNC\n        lda #$%02X\n        sta Pos\n        lda #<(TroggStrip-1)\n'
                 '        sta TrogPtr\n        lda #%d\n        sta Count\n        lda #0\n        jmp R_%d\n'
                 '        align 256' % (pos, ROWS, i))
        o.append('R_%d:' % i)
        for line in 'eo':
            for ins in row_line(i, line):
                if ins.endswith(':'):
                    o.append(ins)
                else:
                    o += ['        ' + s for s in ins.split('\n') if s.strip()]
        o.append('X_%d:    sta WSYNC\n        lda #0\n        sta GRP0\n        sta GRP1\n        sta ENAM0' % i)
        used += 1 + 2 * ROWS + 1
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
    r = subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if r.returncode:
        print(r.stdout[-1500:])
        sys.exit('dasm failed')
    # page check on every conditional branch
    labels, rows = {}, []
    for line in open(base + '.lst'):
        f = line.split()
        if len(f) == 3 and f[2][0].isalpha():
            labels[f[2]] = int(f[1], 16)
        rows.append(f)
    cross = []
    for f in rows:
        if len(f) >= 6 and f[4] in ('bmi', 'bpl', 'bvs', 'bvc', 'beq', 'bne') and f[5] in labels:
            if (int(f[1], 16) + 2) >> 8 != labels[f[5]] >> 8:
                cross.append(' '.join(f[1:6]))
    return cross


if __name__ == '__main__':
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out', 'leaf4'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'leaf4')
    cross = build(base)
    print('branches crossing a page:', cross or 'none')
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png').convert('RGB')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    sx = im.width / 160
    bg = im.getpixel((im.width - 2, im.height // 2))
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg) + 1
    MAG_RGB = (192, 78, 170)
    y = 1
    for i in range(4):
        y += 1
        for k in (4, 5):
            row = [im.getpixel((int((x + 0.5) * sx), first + y + k)) for x in range(160)]
            runs, x = [], 0
            while x < 160:
                if row[x] != bg:
                    j = x
                    while j < 160 and row[j] == row[x]:
                        j += 1
                    c = row[x]
                    runs.append('%d-%d%s' % (x, j - 1, 'k' if c == (0, 0, 0) else ('M' if c == MAG_RGB else 'T')))
                    x = j
                else:
                    x += 1
            print('leaf %d (strobe at %d, x=%d) line %d: %s' % (i, LEAVES[i][1], 3 * LEAVES[i][1] - 47, k, '  '.join(runs)))
        y += 2 * ROWS + 1
