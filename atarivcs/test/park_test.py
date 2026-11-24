#!/usr/bin/env python3
"""
Exit parking strobe: can a renderer leave P1's main copy (the ghost of its last strobe) where the
next renderer's first strobe cancels it?

    python3 atarivcs/test/park_test.py [OUT_DIR]

Each section (6 lines, WSYNC per line, NUSIZ1 = two close):
  2 exit lines:  GRP1 = $FF at cycle 5, RESP1 strobe ending at cycle CP (the parking strobe):
                 its copy is at 3*CP - 47, its main copy (the ghost on later lines) at 3*CP - 63
  2 entry lines: GRP1 = $FF at cycle 5 (before any ghost is drawn), the next renderer's first
                 strobe ending at cycle CB (copy at 3*CB - 47, or x 19 for CB <= 22)
  2 blank lines: GRP1 = 0
On the first entry line, is anything drawn at the parked main copy's position?
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
PARKS = [44, 47, 50, 53]
ENTRY_X = [19, 37, 55, 73]                      # plus entry strobes 0-4 cycles before the park strobe
NEAR = [4, 3, 2, 1, 0]                          # (28 sections: the frame must stay at 192 lines)


def cycle_for(x):
    return 22 if x == 19 else (x + 47) // 3


def line(c):
    out = ['sta WSYNC', 'lda #$FF', 'sta GRP1']          # GRP1 lands at 5
    gap = c - 3 - 5
    if gap == 1:
        out[-1] = 'sta.w GRP1'
    elif gap:
        out += pad(gap).split('\n')
    return out + ['sta RESP1']


def build(base):
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
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
        lda #1
        sta NUSIZ1
        ldx #36
VB:     sta WSYNC
        dex
        bne VB
        lda #0
        sta VBLANK''' % BG)
    secs = []
    for cp in PARKS:
        for xb in ENTRY_X + [3 * (cp - d) - 47 for d in NEAR if 3 * (cp - d) - 47 not in ENTRY_X]:
            secs.append((cp, xb))
            for c in (cp, cp, cycle_for(xb), cycle_for(xb)):
                o += ['        ' + i for i in line(c)]
            o += ['        sta WSYNC', '        lda #0', '        sta GRP1', '        sta WSYNC']
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
        jmp Frame''' % (192 - 6 * len(secs)))
    o.append('        org $FFFC\n        .word Start\n        .word Start')
    open(base + '.asm', 'w').write('\n'.join(o) + '\n')
    subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                   check=True, stdout=subprocess.DEVNULL)
    return secs


def runs(px):
    out, k = [], 0
    while k < len(px):
        m = k
        while m + 1 < len(px) and px[m + 1] == px[m] + 1:
            m += 1
        out.append('%d-%d' % (px[k], px[m]))
        k = m + 1
    return ' '.join(out) or '-'


if __name__ == '__main__':
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out', 'park'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'park')
    secs = build(base)
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png').convert('RGB')
    sx = im.width / 160
    bg = im.getpixel((im.width - 2, im.height // 2))
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg)
    # locate the first exit line: the first row with anything drawn
    lit = lambda r: [q for q in range(160) if im.getpixel((int((q + 0.5) * sx), r)) != bg]
    y0 = next(r for r in range(first, im.height) if lit(r))
    print('%-6s %-9s %-9s %-10s  %-24s %s' % ('park', 'ghost x', 'entry x', 'cycles', 'first entry line', 'result'))
    table = {}
    for i, (cp, xb) in enumerate(secs):
        r = y0 + 6 * i
        exit2, entry1 = lit(r + 1), lit(r + 2)
        g = 3 * cp - 63
        ghost = any(g <= q < g + 8 and not (xb <= q < xb + 8) for q in entry1)   # not the entry copy itself
        table.setdefault(cp, []).append((xb, ghost))
        print('%-6d %-9d %-9d %-10s  %-24s %s' % (cp, g, xb, 'cb=%d' % cycle_for(xb), runs(entry1),
                                                  'GHOST' if ghost else 'clean'))
    print()
    for cp, row in table.items():
        clean = [xb for xb, gh in row if not gh]
        print('park strobe at cycle %d (ghost at x %d): clean when the entry strobe is at x %s' % (
            cp, 3 * cp - 63, clean))
