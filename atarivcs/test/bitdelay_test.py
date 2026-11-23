#!/usr/bin/env python3
"""
Compensated BIT-ladder delay: a P1 ladder positioned by the top two bits of a RAM byte, between
fixed left-half and right-half playfield writes.

    python3 atarivcs/test/bitdelay_test.py [OUT_DIR]

The delay uses branches to the very next instruction (2 cycles not taken, 3 taken); such a branch
can never cross a page, because its target is the next instruction's own address.
    bit Pos        ; 3   N = bit 7, V = bit 6
    bmi *+2        ; +1 if N
    bmi *+2        ; +1 if N   (bit 7 is worth 2 cycles)
    bvs *+2        ; +1 if V   (bit 6 is worth 1)
    sta RESP1 / nop / sta GRP1      ; the ladder (GRP1 2 cycles after the strobe: see below)
    bit Pos
    bpl *+2        ; +1 if not N
    bpl *+2
    bvc *+2        ; +1 if not V: the two ladders together always take 18 + 3 cycles
The line (A, Y: A = ladder graphics, Y = line counter):
    sta WSYNC
    lda #L1 / sta PF1 / lda #L2 / sta PF2     left half (PF0 is 0 on both halves: set once)
    lda #0 / sta GRP1                          P1's main copy (16 px left) is drawn blank
    lda #$18
    <ladder, delayed 0-3 cycles> <mirror>     everything after is at fixed cycles again
    lda #R1 / sta PF1    (right PF1: 39-54)
    lda #R2 / sta PF2    (right PF2: 50-65)
    dey / bne <line>     (checked not to cross a page)
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tiatest  # noqa: E402
from platforms import pf_regs  # noqa: E402
from PIL import Image  # noqa: E402

BG, PLAT = 0xAA, 0x58
LINES = 6
LEFT = set(range(24, 64))          # blocks 6-15: PF1, PF2 on the left
RIGHT = set(range(96, 136))        # blocks 24-33: PF1, PF2 on the right
POS = [0x00, 0x40, 0x80, 0xC0]


def build(base):
    (l0, l1, l2), (r0, r1, r2) = pf_regs(LEFT | RIGHT)
    assert l0 == 0 and r0 == 0
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['COLUPF   = $08', 'PF0      = $0D', 'PF1      = $0E', 'PF2      = $0F', 'Pos      = $80']
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
        sta COLUPF
        lda #0
        sta CTRLPF
        sta COLUP1
        sta PF0
        lda #1
        sta NUSIZ1
        ldx #36
VB:     sta WSYNC
        dex
        bne VB
        sta WSYNC
        lda #0
        sta VBLANK''' % (BG, PLAT))
    used = 1
    for i, pos in enumerate(POS):
        o.append('; --- section %d: Pos = $%02X' % (i, pos))
        o.append('        sta WSYNC\n        lda #$%02X\n        sta Pos\n        ldy #%d' % (pos, LINES))
        o.append('''L%d:     sta WSYNC          ; 0
        lda #$%02X
        sta PF1            ; 5    left PF1 by 27
        lda #$%02X
        sta PF2            ; 10   left PF2 by 38
        lda #0
        sta GRP1           ; 15   blank main copy
        lda #$18           ; 17
        bit Pos            ; 20
        bmi *+2            ; 22/23
        bmi *+2            ; 24/25
        bvs *+2            ; 26..29 (+0..3)
        sta RESP1          ; 29..32: ladder copy at x = 3c - 47 = 40..49
        nop
        sta GRP1           ; 2 cycles after the strobe (after the blank main copy)
        bit Pos
        bpl *+2
        bpl *+2
        bvc *+2            ; 46 for every Pos
        lda #$%02X
        sta PF1            ; 51   right PF1: 39-54
        lda #$%02X
        sta PF2            ; 56   right PF2: 50-65
        dey
        bne L%d            ; 61 (taken 3; must not cross a page)''' % (i, l1, l2, r1, r2, i))
        o.append('        sta WSYNC\n        lda #0\n        sta GRP1\n        sta PF1\n        sta PF2')
        used += 1 + LINES + 1
    o.append('        ldy #%d\nRest:   sta WSYNC\n        dey\n        bne Rest' % (192 - used))
    o.append('''        lda #2
        sta VBLANK
        ldx #30
OS:     sta WSYNC
        dex
        bne OS
        jmp Frame
        org $FFFC
        .word Start
        .word Start''')
    open(base + '.asm', 'w').write('\n'.join(o) + '\n')
    subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                   check=True, stdout=subprocess.DEVNULL)
    # every taken branch must stay in its page: the loop BNEs are the only ones that could cross
    for line in open(base + '.lst'):
        f = line.split()
        if len(f) >= 5 and f[3] == 'bne' and f[4].startswith('L'):
            addr = int(f[1], 16)
            target = None
            for l2_ in open(base + '.lst'):
                g = l2_.split()
                if len(g) >= 3 and g[2] == f[4]:
                    target = int(g[1], 16)
            assert (addr + 2) >> 8 == target >> 8, 'loop branch crosses a page: %s' % line
    return LEFT | RIGHT


if __name__ == '__main__':
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out', 'bitdelay'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'bitdelay')
    build(base)
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png').convert('RGB')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    sx = im.width / 160
    bg = im.getpixel((im.width - 2, im.height // 2))
    prev = None
    for r in range(im.height):
        row = [im.getpixel((int((x + 0.5) * sx), r)) for x in range(160)]
        runs, x = [], 0
        while x < 160:
            if row[x] != bg:
                j = x
                while j < 160 and row[j] == row[x]:
                    j += 1
                runs.append('%d-%d %s' % (x, j - 1, 'pf' if row[x][0] > 120 else 'ladder'))
                x = j
            else:
                x += 1
        sig = '; '.join(runs)
        if sig != prev:
            print('row %3d: %s' % (r, sig))
            prev = sig
