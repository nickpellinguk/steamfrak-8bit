#!/usr/bin/env python3
"""
LEAF VERSION: the left ladder's position is chosen per section call by BIT Pos (bits 7, 6) and two
branches into one of four leaves; each leaf strobes the ladder at its own cycle, writes GRP1 between
P1's main copy and the ladder's copy (strobe + 5), and does the centre colour switch itself, landing
on cycle 49, then jumps to the shared join (the last leaf falls through). The stripe colour is
loaded in the prefixes (filling the odd prefix's pad), so both paths reach the shared block at 16:
    Shared: lda #BG / sta COLUPF       ; 21   left half invisible (before the playfield starts)
            lda Ladder                 ; 25
            bit Pos                    ; 28
            bmi N1 / bvs L1 ...        ; leaves entered at 32, 33, 33, 34
    Ln:     <pad> sta RESP1 / nop / sta GRP1 <pad> sty COLUPF (49) / jmp Join
    Join:   lda #0 / sta GRP1          ; blank again for the next line's main copy
            bcc OddEnd ...
The section is a subroutine called once per test band, each with a different Pos.

The original (fixed-ladder) description follows.

A carry-shared one-sided platform section: a right-side platform (playfield registers hold the right
half's pattern, set once on entry; COLUPF is the background colour for the left half and switches to
the platform colour at the centre, cycle 49), 4 rows = 8 lines with per-line stripe colours (black,
magenta, magenta, black, dark cyan x4), inside the row skeleton with Trogg and the yoyo. One copy of
the line code serves both lines; the carry flag says which line it is, and X counts lines so the
stripe colour comes from one per-line table.

    python3 atarivcs/test/carry_plat_test.py [OUT_DIR]

    Row:    sta WSYNC          ; even line
            inc TrogPtr        ; 5
            inx                ; 7    next line's colour
            sec                ; 9
            jmp Shared         ; 12
    Odd:    sta WSYNC          ; odd line
            asl                ; 2    yoyo enable (changes carry)
            sta ENAM0          ; 5
            inx                ; 7
            clc                ; 9
            bit $80            ; 12   pad (carry-safe)
    Shared: lda #BG / sta COLUPF        ; 17   left half invisible (before the playfield starts)
            ldy PCol,x                  ; 21   this line's stripe colour
            <pad 25>
            sty COLUPF                  ; 49   the right half appears
            bcc OddEnd                  ; 51 / 52
            ldy #0 / lda (TrogPtr),y / sta GRP0 / jmp Odd    ; 64 (even tail)
    OddEnd: dec Count / bne Row                             ; 60
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tiatest  # noqa: E402
from platforms import pf_regs  # noqa: E402
from PIL import Image  # noqa: E402

pad = tiatest.pad
BG, MAG, DARK, TROGG_COL = 0xAA, 0x58, 0xA4, 0x1C
STRIPES = [0x00, MAG, MAG, 0x00, DARK, DARK, DARK, DARK]
ROWS = 4
PLATFORM = set(range(84, 136))          # right half, blocks 21-33
TROGG = [0x18, 0x3C, 0x7F, 0x3C]        # original placeholder; row 2's front pixel = the yoyo
TROGG_X, YOYO_X = 100, 112
CARRY_SAFE = ('ldy', 'sty', 'sta', 'sta.w', 'lda', 'nop', 'bit', 'ldx', 'stx', 'bmi', 'bvs', 'jmp')


LADDER = True
LEAF_STROBES = [35, 37, 39, 41]          # strobe-end cycles of the four leaves: x = 3c - 47
LEAF_ENTRY = [32, 33, 33, 34]            # cycle each leaf is entered (BIT at 28, two branches)


def leaf(i, n):
    entry, st = LEAF_ENTRY[i], LEAF_STROBES[i]
    a = st - 3 - entry
    assert a >= 0, (i, a)
    strobe = 'sta RESP1'
    if a == 1:
        strobe, a = 'sta.w RESP1', 0
    grp = st + 5                        # NOP then STA GRP1: after the main copy, before the copy
    b = 46 - grp                        # then STY COLUPF lands on 49
    gwrite = 'sta GRP1'
    if b == 1:
        gwrite, b = 'sta.w GRP1', 0     # lands at strobe + 6: still before the copy (strobe + 7)
    assert b >= 0, (i, b)
    out = ['L%d_%s:' % (i, n)] + ([pad(a)] if a else []) + [strobe, 'nop', gwrite] + ([pad(b)] if b else [])
    out.append('sty COLUPF')
    if i < 3:
        out.append('jmp Join_%s' % n)
    return out


def shared_block(n='e'):
    return (['lda #$%02X' % BG, 'sta COLUPF', 'lda Ladder', 'bit Pos', 'bmi N1_%s' % n, 'bvs L1_%s' % n]
            + leaf(0, n) + leaf(1, n) + ['N1_%s:' % n, 'bvs L3_%s' % n] + leaf(2, n) + leaf(3, n)
            + ['Join_%s:' % n, 'lda #0', 'sta GRP1'])


def build(base):
    (l0, l1, l2), (r0, r1, r2) = pf_regs(PLATFORM)
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['GRP0 = $1B', 'COLUP0 = $06', 'RESM0 = $12', 'ENAM0 = $1D', 'NUSIZ0 = $04', 'COLUPF = $08',
          'PF0 = $0D', 'PF1 = $0E', 'PF2 = $0F', 'TrogPtr = $80', 'Count = $82', 'Pos = $83', 'BandNo = $84']
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
        sta COLUPF
        lda #$%02X
        sta COLUP0
        lda #0
        sta CTRLPF           ; repeat mode
        sta COLUP1           ; the ladder is black
        sta GRP1
        lda #1
        sta NUSIZ1           ; two copies close: the strobe's copy is the ladder
        lda #$30
        sta NUSIZ0
        lda #>TroggStrip
        sta TrogPtr+1''' % (BG, TROGG_COL))
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
        ; section entry: the right half's pattern, once
        lda #$%02X
        sta PF0
        lda #$%02X
        sta PF1
        lda #$%02X
        sta PF2
        ldy #0
Bands:  sty BandNo
        lda PosTab,y
        sta Pos
        lda #<(TroggStrip-1)
        sta TrogPtr
        lda #%d
        sta Count
        ldx #$FF             ; X counts lines: INX makes it 0 on the first line
        lda #0
        jsr Section
        sta WSYNC
        lda #$%02X
        sta COLUPF           ; on exit the playfield colour goes back to the background colour,
        lda #0               ; or the repeated left half shows on the following lines
        sta GRP0
        sta GRP1
        sta ENAM0
        sta WSYNC
        ldy BandNo
        iny
        cpy #4
        bne Bands
        jmp AfterBands
        align 256
SectionStart:
Section: jmp Row
Row:    sta WSYNC
        inc TrogPtr
        inx
        ldy PCol,x           ; this line's stripe colour (Y, kept for the centre switch)
        sec
        jmp Shared
Odd:    sta WSYNC
        asl
        sta ENAM0
        inx
        ldy PCol,x
        clc
        bit $80
Shared:''' % (r0, r1, r2, ROWS, BG))
    for ins in shared_block():
        if ins.endswith(':'):
            o.append(ins)
        else:
            o += ['        ' + s for s in ins.split('\n') if s.strip()]
    o.append('''        bcc OddEnd
        ldy #0
        lda (TrogPtr),y
        sta GRP0
        jmp Odd
OddEnd: dec Count
        bne Row
        rts
SectionEnd:
AfterBands:
        sta WSYNC
        lda #0
        sta GRP0
        sta ENAM0
        sta PF0
        sta PF1
        sta PF2
        sta GRP1''')
    used = 1 + 4 * (2 * ROWS + 2) + 1
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
    o.append('PCol:   .byte ' + ','.join('$%02X' % v for v in STRIPES))
    o.append('Ladder: .byte $81')
    o.append('PosTab: .byte $00,$40,$80,$C0')
    o.append('        org $FFFC\n        .word Start\n        .word Start')
    open(base + '.asm', 'w').write('\n'.join(o) + '\n')
    subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                   check=True, stdout=subprocess.DEVNULL)
    for ins in shared_block():
        for s in ins.split('\n'):
            assert s.endswith(':') or s.split()[0] in CARRY_SAFE, s
    addr, labels = {}, {}
    for line in open(base + '.lst'):
        f = line.split()
        if len(f) == 3 and f[2][0].isalpha():
            labels[f[2]] = int(f[1], 16)
        if len(f) == 3 and f[2] in ('SectionStart', 'SectionEnd', 'Row', 'OddEnd'):
            addr[f[2]] = int(f[1], 16)
    for line in open(base + '.lst'):
        f = line.split()
        if len(f) >= 6 and f[4] in ('bcc', 'bne', 'bmi', 'bvs') and f[5] in labels:
            assert (int(f[1], 16) + 2) >> 8 == labels[f[5]] >> 8, 'page crossing: ' + line
    return addr['SectionEnd'] - addr['SectionStart']


if __name__ == '__main__':
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out', 'leafplat'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'leafplat')
    size = build(base)
    print('section code: %d bytes for both lines of a row' % size)
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png').convert('RGB')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    sx = im.width / 160
    bg = im.getpixel((im.width - 2, im.height // 2))
    names = {(0, 0, 0): 'k', (192, 78, 170): 'M', (36, 98, 141): 'D', (230, 230, 62): 'T'}
    allrows = []
    for r in range(im.height):
        allrows.append([im.getpixel((int((x + 0.5) * sx), r)) for x in range(160)])
    # a band's lines are those with the platform (x 84-135) lit; separators have nothing at x 4-55
    bands, cur = [], []
    for r, row in enumerate(allrows):
        lit = row[110] != (90, 176, 212) and row[2] == (90, 176, 212)   # (not the black border)
        if lit:
            cur.append(r)
        elif cur:
            bands.append(cur)
            cur = []
    for band, rs in enumerate(bands[:4]):
        print('band %d (Pos $%02X, strobe at %d, x=%d): %d lines' % (band, band << 6, LEAF_STROBES[band],
                                                                    3 * LEAF_STROBES[band] - 47, len(rs)))
        for r in rs:
            row = allrows[r]
            runs, x = [], 0
            while x < 160:
                if row[x] != (90, 176, 212):
                    k = x
                    while k < 160 and row[k] == row[x]:
                        k += 1
                    runs.append('%d-%d%s' % (x, k - 1, names.get(row[x], '?')))
                    x = k
                else:
                    x += 1
            print('   %s' % '  '.join(runs))
