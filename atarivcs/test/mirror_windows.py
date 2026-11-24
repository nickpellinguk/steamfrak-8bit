#!/usr/bin/env python3
"""
Mirrored playfield (CTRLPF bit 0): when do mid-line writes take effect?

    python3 atarivcs/test/mirror_windows.py [OUT_DIR]

In mirrored mode the right half shows PF2 (x 80-111, bit 7 first), PF1 (x 112-143, bit 0 first),
PF0 (x 144-159). Each line here sets PF2 = A (and PF1 = A) early, then rewrites PF2 (or PF1) = B
with a store ending at cycle T, where A and B differ only in bit K. The left copy must show A and
the right copy B; the line is 'ok' only if both are right. A second set of lines switches COLUPF
at cycle T to find the pixel each switch takes effect from.

Measured: for each register and bit, the range of T that works.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tiatest  # noqa: E402
from PIL import Image  # noqa: E402

pad = tiatest.pad
BG, FG, FG2 = 0xAA, 0x00, 0x58
T_RANGE = list(range(44, 57))     # (unrolled lines: the ROM must stay within 4K)
CASES = [('PF2', 7), ('PF2', 6), ('PF2', 5), ('PF2', 3), ('PF2', 0), ('PF1', 0), ('PF1', 3), ('PF1', 7)]


def line_code(reg, k, t):
    """A line: PF1 = PF2 = $FF... no: A = all bits set except bit k cleared; rewrite to all set."""
    a = 0xFF & ~(1 << k)
    code = ['sta WSYNC', 'lda #$%02X' % a, 'sta PF1', 'sta PF2', 'lda #$FF']   # PF1 by 8, PF2 by 10, A=$FF at 12
    used = 2 + 3 + 3 + 2
    gap = t - 3 - used
    assert gap >= 0 and gap != 1, (reg, k, t, gap)
    if gap:
        code += pad(gap).split('\n')
    return code + ['sta %s' % reg]


def colour_line(t):
    code = ['sta WSYNC', 'lda #$FF', 'sta PF1', 'sta PF2', 'lda #$%02X' % FG, 'sta COLUPF', 'lda #$%02X' % FG2]
    used = 2 + 3 + 3 + 2 + 3 + 2
    gap = t - 3 - used
    assert gap >= 0 and gap != 1
    if gap:
        code += pad(gap).split('\n')
    return code + ['sta COLUPF']


def build(base):
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['COLUPF = $08', 'PF0 = $0D', 'PF1 = $0E', 'PF2 = $0F']
    o.append('''        seg code
        org $F000
Start:  sei
        cld
        ldx #$FF
        txs
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
        lda #1
        sta CTRLPF          ; mirrored
        lda #0
        sta PF0
        ldx #36
VB:     sta WSYNC
        dex
        bne VB
        lda #0
        sta VBLANK''' % (BG, FG))
    lines = []
    for reg, k in CASES:
        for t in T_RANGE:
            if t - 13 < 0 or t - 13 == 1:
                continue
            lines.append((reg, k, t))
            o += ['        ' + c for c in line_code(reg, k, t)]
    for t in T_RANGE:
        if t - 18 < 0 or t - 18 == 1:
            continue
        lines.append(('COLUPF', None, t))
        o += ['        ' + c for c in colour_line(t)]
    o.append('        sta WSYNC\n        lda #0\n        sta PF1\n        sta PF2\n        lda #$%02X\n        sta COLUPF' % FG)
    rest = 192 - len(lines) - 1
    assert rest > 0, len(lines)
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
        jmp Frame
        org $FFFC
        .word Start
        .word Start''' % rest)
    open(base + '.asm', 'w').write('\n'.join(o) + '\n')
    subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin'], check=True, stdout=subprocess.DEVNULL)
    return lines


def main():
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out', 'mirror'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'mirror')
    lines = build(base)
    png = tiatest.snapshot(base + '.bin', outdir)
    im = Image.open(png).convert('RGB')
    sx = im.width / 160
    bg = (90, 176, 212)
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg)
    # find the first drawn line (lots of lit playfield)
    lit = lambda r: sum(1 for q in range(160) if im.getpixel((int((q + 0.5) * sx), r)) != bg)
    y0 = next(r for r in range(first, im.height) if lit(r) > 40)
    res = {}
    for i, (reg, k, t) in enumerate(lines):
        row = [im.getpixel((int((q + 0.5) * sx), y0 + i)) for q in range(160)]
        if reg == 'COLUPF':
            # the first pixel in the second colour
            c2 = next((q for q in range(16, 144) if row[q] == (192, 78, 170)), None)
            res.setdefault('COLUPF', []).append((t, c2))
            continue
        on = lambda q: row[q] != bg
        # left copy of bit k must be off (A), right copy on (B)
        if reg == 'PF2':
            xl, xr = 48 + 4 * k, 80 + 4 * (7 - k)
        else:
            xl, xr = 16 + 4 * (7 - k), 112 + 4 * k
        okl = not any(on(q) for q in range(xl, xl + 4))
        okr = all(on(q) for q in range(xr, xr + 4))
        res.setdefault((reg, k), []).append((t, okl, okr))
    for key, v in res.items():
        if key == 'COLUPF':
            print('COLUPF switch: store ending at cycle T -> first pixel in the new colour:',
                  ', '.join('%d->%s' % (t, c) for t, c in v))
            continue
        good = [t for t, a, b in v if a and b]
        print('%s bit %d (left block x %d, right block x %d): works for T = %s' % (
            key[0], key[1], 48 + 4 * key[1] if key[0] == 'PF2' else 16 + 4 * (7 - key[1]),
            80 + 4 * (7 - key[1]) if key[0] == 'PF2' else 112 + 4 * key[1],
            '%d-%d' % (min(good), max(good)) if good else 'never'))


if __name__ == '__main__':
    main()
