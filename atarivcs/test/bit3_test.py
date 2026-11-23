#!/usr/bin/env python3
"""
The structural block 'ladder - object - ladder': fixed ladders at the left and right, and an object
in the middle placed by a three-bit BIT delay (bits 7, 6, 5 of a RAM byte: N, V, and Z via the mask
A = $20), with the mirrored branches after it so the right ladder is at a fixed cycle.

    python3 atarivcs/test/bit3_test.py [OUT_DIR]

    sta WSYNC
    ldy Ladder,x        ; 4   ladder graphics (Y), before any BIT (LDY sets flags)
    sta RESP1           ; 7   left ladder, in the blank: its copy is at x = 19
    sty GRP1            ; 10
    lda Middle,x        ; 14  the middle object's graphics (there is no LDX abs,X)
    tax                 ; 16  (X: the index's last use)
    lda #$20            ; 18  mask for bit 5
    <pad>
    bit Pos             ;     N = bit 7, V = bit 6, Z = bit 5 clear
    bpl *+5             ; +4 if bit 7 set   (skips BIT Pos / NOP when clear)
    bit Pos
    nop
    bvc *+4             ; +2 if bit 6 set   (skips BIT Pos when clear)
    bit Pos
    bne *+2             ; +1 if bit 5 set   (to the next instruction)
    sta RESP1           ; the middle object: delay = Pos >> 5
    nop
    stx GRP1
    bmi *+5             ; the mirror: +4 if bit 7 clear
    bit Pos
    nop
    bvs *+4             ; +2 if bit 6 clear
    bit Pos
    beq *+2             ; +1 if bit 5 clear
    sta RESP1           ; right ladder: the same cycle for every Pos
    sty GRP1
    dec Count
    bne <line>
Stores and NOPs don't change the flags, so one BIT serves both halves; the repeated BIT Pos
re-reads the same flags (A is still $20). Every branch that skips bytes, and the loop branch, is
checked against page boundaries from the listing.
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
LINES = 4
PAD = 4                              # (with LDX #0 and TAX) middle object at x = 67 + 3d
LADDER, MIDDLE = 0x81, 0x3C


def delay_of(pos):
    # binary weights: bit 7 = 4 (BPL over BIT Pos / NOP), bit 6 = 2 (BVC over BIT Pos),
    # bit 5 = 1 (BNE to the next instruction; Z is clear when bit 5 is set): delay = Pos >> 5
    return pos >> 5


def build(base):
    pats = [d << 5 for d in range(8)]
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['Pos      = $80', 'Count    = $81']
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
        lda #1
        sta NUSIZ1
        ldx #36
VB:     sta WSYNC
        dex
        bne VB
        sta WSYNC
        lda #0
        sta VBLANK''' % BG)
    used = 1
    for i, pos in enumerate(pats):
        o.append('; --- section %d: Pos = $%02X (delay %d)' % (i, pos, delay_of(pos)))
        o.append('        sta WSYNC\n        lda #$%02X\n        sta Pos\n        lda #%d\n        sta Count' % (pos, LINES))
        o.append('        jmp L%d\n        align 64' % i)
        o.append('L%d:     sta WSYNC' % i)
        o.append('        ldx #0')              # the band's table index (0 here); counted below
        o.append('''        ldy Ladder,x
        sta RESP1
        sty GRP1
        lda Middle,x
        tax
        lda #$20''')
        o.append('        ' + pad(PAD).replace('\n', '\n        '))
        o.append('''        bit Pos
        bpl *+5            ; +4 if bit 7 set
        bit Pos
        nop
        bvc *+4            ; +2 if bit 6 set
        bit Pos
        bne *+2            ; +1 if bit 5 set
        sta RESP1
        nop
        stx GRP1
        bmi *+5            ; the mirror: +4 if bit 7 clear
        bit Pos
        nop
        bvs *+4            ; +2 if bit 6 clear
        bit Pos
        beq *+2            ; +1 if bit 5 clear
        sta RESP1
        sty GRP1
        dec Count
        bne L%d''' % i)
        o.append('        sta WSYNC\n        lda #0\n        sta GRP1')
        o.append('E%d:' % i)
        used += 1 + LINES + 1
    o.append('        ldy #%d\nRest:   sta WSYNC\n        dey\n        bne Rest' % (192 - used))
    o.append('''        lda #2
        sta VBLANK
        ldx #30
OS:     sta WSYNC
        dex
        bne OS
        jmp Frame
        align 256
Ladder: .byte $%02X
Middle: .byte $%02X
        org $FFFC
        .word Start
        .word Start''' % (LADDER, MIDDLE))
    open(base + '.asm', 'w').write('\n'.join(o) + '\n')
    subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                   check=True, stdout=subprocess.DEVNULL)
    # page check: any taken branch whose target isn't the next instruction
    labels, lines = {}, []
    for line in open(base + '.lst'):
        f = line.split()
        if len(f) >= 3 and f[2].isidentifier() and len(f) == 3:
            labels[f[2]] = int(f[1], 16)
        lines.append(f)
    crossing = []
    for f in lines:
        if len(f) >= 6 and f[4] in ('bvs', 'bvc', 'bmi', 'bpl', 'beq', 'bne'):
            addr = int(f[1], 16)
            arg = f[5]
            if arg.startswith('*+'):
                target = addr + int(arg[2:])
            elif arg in labels:
                target = labels[arg]
            else:
                continue
            if (addr + 2) >> 8 != target >> 8:
                crossing.append(' '.join(f))
    return pats, crossing


if __name__ == '__main__':
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out', 'bit3'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'bit3')
    pats, crossing = build(base)
    print('branches crossing a page:', crossing or 'none')
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png').convert('RGB')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    sx = im.width / 160
    bg = im.getpixel((im.width - 2, im.height // 2))
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg) + 1
    y = 1
    for pos in pats:
        y += 1
        row = [im.getpixel((int((x + 0.5) * sx), first + y + 2)) for x in range(160)]
        runs, x = [], 0
        while x < 160:
            if row[x] != bg:
                j = x
                while j < 160 and row[j] != bg:
                    j += 1
                runs.append('%d-%d' % (x, j - 1))
                x = j
            else:
                x += 1
        print('Pos $%02X (delay %d): %s' % (pos, delay_of(pos), '  '.join(runs)))
        y += LINES + 1
