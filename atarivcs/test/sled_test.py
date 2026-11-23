#!/usr/bin/env python3
"""
Test: ladder - sled - Scrubbly - sled - ladder on one line.

    python3 atarivcs/test/sled_test.py [OUT_DIR]

Each section of the screen uses a different sled delay d for the Scrubbly (first sled) and D - d
for the second sled, so the two ladders should stay put while the Scrubbly moves 3 px per cycle.
The line, after STA WSYNC (all copies are player-1 copies, NUSIZ1 = two close, one RESP1 each):

        lda #$18           ; ladder graphics (a pole)
        ldx #<scrubbly row>
        <pad>
        sta RESP1          ; left ladder, fixed
        sta GRP1
        lda #MAGENTA
        sta COLUP1         ; after the left ladder's copy has finished
        jmp (Sled1)        ; delay d
        <sled 1>
        sta RESP1          ; the Scrubbly
        stx GRP1
        ldx #0
        stx COLUP1         ; black again, after the Scrubbly's copy (A still holds the ladder)
        jmp (Sled2)        ; delay D - d
        <sled 2>
        sta RESP1          ; right ladder, fixed
        sta GRP1
        dey
        bne <line>

A sled is CMP #$C9 bytes ($C9 ...) ending in $C5 $EA: entering at successive bytes gives
delays one cycle apart (the last instruction is either CMP zp $EA, 3 cycles, or NOP, 2).
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tiatest  # noqa: E402
from PIL import Image  # noqa: E402

pad = tiatest.pad
SLED_LEN = 5                        # $C9 bytes before $C5 $EA: delays 2-8
LADDER_STROBE_END = 19              # in the blank: the left ladder's copy is at x = 19
MAGENTA = 0x58
SCRUB = 0x7E                        # one row of the Scrubbly (enough to see its position)
LINES = 6


def sled_delay(entry):
    """Cycles from entering the sled at byte `entry` to reaching the byte after it."""
    s = [0xC9] * SLED_LEN + [0xC5, 0xEA]
    p, c = entry, 0
    while p < len(s):
        if s[p] == 0xC9:
            c, p = c + 2, p + 2
        elif s[p] == 0xC5:
            c, p = c + 3, p + 2
        else:
            c, p = c + 2, p + 1
    assert p == len(s)
    return c


def entries():
    """{delay: entry byte} for every delay the sled can give."""
    out = {}
    for e in range(SLED_LEN + 2):
        out.setdefault(sled_delay(e), e)
    return dict(sorted(out.items()))


def build(base):
    ent = entries()
    delays = list(ent)
    dmin, dmax = delays[0], delays[-1]
    total = dmin + dmax                 # first sled d, second D - d: D = dmin + dmax
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['Sled1    = $80', 'Sled2    = $82', 'LinesLeft = $84']
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
        lda #$AA
        sta COLUBK
        lda #1
        sta NUSIZ1
        ldx #36
VB:     sta WSYNC
        dex
        bne VB
        sta WSYNC
        lda #0
        sta VBLANK''')
    used = 1
    sections = []
    for i, d in enumerate(delays):
        e1, e2 = ent[d], ent[total - d]
        sections.append((d, total - d))
        o.append('; --- section %d: first sled %d cycles, second %d' % (i, d, total - d))
        o.append('        sta WSYNC')
        o.append('        lda #<(Sled1Code+%d)\n        sta Sled1\n        lda #>(Sled1Code+%d)\n        sta Sled1+1' % (e1, e1))
        o.append('        lda #<(Sled2Code+%d)\n        sta Sled2\n        lda #>(Sled2Code+%d)\n        sta Sled2+1' % (e2, e2))
        o.append('        lda #0\n        sta COLUP1\n        ldy #%d' % LINES)
        o.append('S%d:     sta WSYNC' % i)
        o.append('        lda #$18\n        ldx #$%02X' % SCRUB)            # 4 cycles
        o.append('        ' + pad(LADDER_STROBE_END - 3 - 4).replace('\n', '\n        '))
        o.append('        sta RESP1\n        sta GRP1\n        jmp (Sled1)')
        o.append('R%d:     lda #$%02X\n        sta COLUP1\n        sta RESP1\n        stx GRP1\n        ldx #0\n        lda #$18\n        jmp (Sled2)' % (i, MAGENTA))
        o.append('T%d:     stx COLUP1\n        sta RESP1\n        sta GRP1\n        dey\n        bne S%d' % (i, i))
        # (each section's sleds jump back into its own code: done with per-section sled copies)
        o.append('        lda #0\n        sta GRP1\n        sta WSYNC\n        sta WSYNC')
        used += 1 + LINES + 3       # (the clean-up after the loop spills into a line)
    assert used <= 190, used
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
    return sections, total


def build_with_sleds(base):
    """The sleds have to return to each section's own code, so give every section its own pair of
    sleds (Sled1Code_i / Sled2Code_i), placed right before R_i and T_i."""
    sections, total = build(base)
    src = open(base + '.asm').read()
    sled_bytes = ','.join(['$C9'] * SLED_LEN + ['$C5', '$EA'])
    for i in range(len(sections)):
        src = src.replace('Sled1Code+', 'Sled1Code%d+' % i, 2).replace('Sled2Code+', 'Sled2Code%d+' % i, 2)
        src = src.replace('R%d:     lda' % i, 'Sled1Code%d: .byte %s\nR%d:     lda' % (i, sled_bytes, i))
        src = src.replace('T%d:     stx' % i, 'Sled2Code%d: .byte %s\nT%d:     stx' % (i, sled_bytes, i))
    open(base + '.asm', 'w').write(src)
    subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                   check=True, stdout=subprocess.DEVNULL)
    return sections, total


def cycles_per_line(d1, d2):
    # to the left strobe; GRP1, colour, JMP; sled; strobe, GRP1, colour, JMP; sled;
    # strobe, GRP1, DEY, BNE; then the next line's STA WSYNC must land by 75
    # left strobe; GRP1, JMP (8); sled; colour, strobe, GRP1, LDX, LDA, JMP (20); sled;
    # colour, strobe, GRP1, DEY, BNE (14); then the next line's STA WSYNC must land by 75
    return LADDER_STROBE_END + 8 + d1 + 20 + d2 + 14 + 3


if __name__ == '__main__':
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'sled_test')
    sections, total = build_with_sleds(base)
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png').convert('RGB')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    sx = im.width / 160
    bg = im.getpixel((im.width - 2, im.height // 2))
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg) + 1
    y = 1
    print('sled delays: first + second = %d cycles; line uses %d-%d cycles' % (
        total, cycles_per_line(*sections[0]), cycles_per_line(*sections[-1])))
    for i, (d1, d2) in enumerate(sections):
        y += 1
        row = [im.getpixel((int((x + 0.5) * sx), first + y + 2)) for x in range(160)]
        runs, x = [], 0
        while x < 160:
            if row[x] != bg:
                j = x
                while j < 160 and row[j] == row[x]:
                    j += 1
                runs.append('%d-%d %s' % (x, j - 1, 'magenta' if row[x][0] > 120 else 'black'))
                x = j
            else:
                x += 1
        print('section %2d (sleds %2d + %2d): %s' % (i, d1, d2, '; '.join(runs)))
        y += LINES + 3
