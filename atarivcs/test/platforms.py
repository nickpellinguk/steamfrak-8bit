#!/usr/bin/env python3
"""
Test kernel: hybrid platforms. The body of each platform is the (asymmetric, repeat-mode)
playfield in 4-pixel blocks; the ragged ends are player-1 copies (NUSIZ1 = two close, one RESP1
strobe each, GRP1 rewritten straight after) whose 1-pixel bits put the end on an exact pixel.
Trogg is player 0, repeated down the screen; two ladders (P1 copies) run down the screen.

    python3 atarivcs/test/platforms.py [OUT_DIR]

Copy positions: a RESP1 strobe ending at cycle c gives a copy at x = 3c - 47 (measured).
Playfield write windows (repeat mode), by the cycle the STA ends:
  left PF0 <= 22, left PF1 <= 28, left PF2 <= 38;
  right PF0 29-49, right PF1 39-54, right PF2 50-65.

Row A (4 lines): platform 21-69 (P1 left end, PF body, P1 right end), platform 135-155 (P1 left
end, PF body and right end); ladder x=40 is under platform 1; ladder x=100 is in the gap but
there is no strobe for it on these lines, so it is interrupted (deliberately, to see it).
Row B (4 lines): platform 8-31 (PF only), ladder x=40 in the gap (P1 copy), platform 97-147 (P1
left end, PF body); ladder x=100 is under platform 2.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tiatest  # noqa: E402
from trogg_rows import TROGG, bits  # noqa: E402
from PIL import Image  # noqa: E402

pad = tiatest.pad
TROGG_RESP0_END = 62           # Trogg at about x = 123


def copy_x(c):
    # measured (exp9_edge.py): a strobe ending at cycle 22 or earlier (in the horizontal blank)
    # puts the main copy at x = 3, so the 'close' copy is at 19: no copy can start left of 19
    return max(19, 3 * c - 47)


def pf_regs(lit):
    """lit: set of pixels 0-159 -> ((L0, L1, L2), (R0, R1, R2)) for blocks fully lit."""
    blocks = [all(x in lit for x in range(4 * b, 4 * b + 4)) for b in range(40)]
    out = []
    for h in (0, 20):
        b = blocks[h:h + 20]
        pf0 = sum(1 << (4 + i) for i in range(4) if b[i])
        pf1 = sum(1 << (7 - (i - 4)) for i in range(4, 12) if b[i])
        pf2 = sum(1 << (i - 12) for i in range(12, 20) if b[i])
        out.append((pf0, pf1, pf2))
    return out


def end_bits(copy, first, last):
    """GRP1 value lighting pixels first..last (inclusive) of a copy starting at `copy`."""
    v = 0
    for x in range(first, last + 1):
        off = x - copy
        if 0 <= off < 8:
            v |= 0x80 >> off
    return v


def row_a():
    plat = set(range(24, 64)) | set(range(136, 156))          # PF body (whole blocks)
    (l0, l1, l2), (r0, r1, r2) = pf_regs(plat)
    c1, c2, c3 = 19, 37, 60
    g1 = end_bits(copy_x(c1), 21, 23)       # left end of platform 1: pixels 21-23
    g2 = end_bits(copy_x(c2), 64, 69)       # right end of platform 1: pixels 64-69
    g3 = end_bits(copy_x(c3), 135, 135)     # left end of platform 2: pixel 135
    code = ['lda #$%02X' % l0, 'sta PF0',            # 5
            'lda Trogg,y', 'sta GRP0',               # 12
            'lda #$%02X' % g1, pad(2),               # 16
            'sta RESP1', 'sta GRP1',                 # 19, 22
            'lda #$%02X' % l1, 'sta PF1',            # 27 (left PF1 <= 28)
            'lda #$%02X' % l2, 'sta PF2',            # 32 (left PF2 <= 38)
            'lda #$%02X' % g2, 'sta RESP1', 'sta GRP1',   # 37, 40
            'lda #$%02X' % r0, 'sta PF0',            # 45 (right PF0 29-49)
            'lda #$%02X' % r1, 'sta PF1',            # 50 (right PF1 39-54)
            'lda #$%02X' % r2, 'sta PF2',            # 55 (right PF2 50-65)
            'lda #$%02X' % g3, 'sta RESP1', 'sta GRP1']   # 60, 63
    return code, 63


def row_b():
    plat = set(range(8, 32)) | set(range(100, 148))
    (l0, l1, l2), (r0, r1, r2) = pf_regs(plat)
    c3 = 47
    g3 = end_bits(copy_x(c3), 97, 99)       # left end of platform 2: pixels 97-99
    code = ['lda #$%02X' % l0, 'sta PF0',            # 5
            'lda Trogg,y', 'sta GRP0',               # 12
            'lda #$%02X' % l1, 'sta PF1',            # 17
            'lda #$%02X' % l2, 'sta PF2',            # 22
            'lda Ladder,y',                          # 26
            ]
    code += ['sta RESP1', 'sta GRP1',                # 29 (x = 40), 32
             'lda #$%02X' % r0, 'sta PF0',           # 37 (right PF0 29-49)
             'lda #$%02X' % r1, 'sta PF1',           # 42 (right PF1 39-54)
             'lda #$%02X' % g3, 'sta RESP1', 'sta GRP1',  # 47, 50
             'lda #$%02X' % r2, 'sta PF2']           # 55 (right PF2 50-65)
    return code, 55


def ladder_line():
    code = ['lda Trogg,y', 'sta GRP0',               # 7
            'lda #0', 'sta PF0', 'sta PF1', 'sta PF2',   # 18
            'lda Ladder,y', pad(4),                  # 22, 26
            'sta RESP1', 'sta GRP1',                 # 29 (x = 40), 32
            pad(14),                                 # 46
            'sta RESP1', 'sta GRP1']                 # 49 (x = 100), 52
    return code, 52


SEGMENTS = [('ladder', 40), ('A', 4), ('ladder', 56), ('B', 4), ('ladder', 56), ('A', 4), ('ladder', 28)]


def cycles(ins):
    """Cycle counts for the instructions used here (no page crossings: tables are aligned)."""
    if ins.startswith('nop'):
        return 2
    if ins.startswith('bit'):
        return 3
    op, arg = ins.split()[0], ins.split()[1] if len(ins.split()) > 1 else ''
    if arg.startswith('#'):
        return 2
    if ',y' in arg:
        return 4
    return 3


def check(code, expect):
    total = 0
    for chunk in code:
        for ins in chunk.split('\n'):
            if ins.strip():
                total += cycles(ins.strip())
    assert total == expect, (total, expect, code)


def build(base):
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['GRP0     = $1B', 'COLUPF   = $08', 'PF0      = $0D', 'PF1      = $0E', 'PF2      = $0F']
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
        lda #$0C
        sta COLUBK
        lda #$58
        sta COLUP0
        lda #$00
        sta COLUP1
        sta COLUPF
        sta CTRLPF        ; repeat mode, players in front of the playfield
        sta NUSIZ0
        lda #1
        sta NUSIZ1
        sta WSYNC''')
    o.append('        ' + pad(TROGG_RESP0_END - 3).replace('\n', '\n        '))
    o.append('''        sta RESP0
        ldx #34
VB:     sta WSYNC
        dex
        bne VB
        ldy #0
        sta WSYNC
        lda #0
        sta VBLANK''')
    makers = {'ladder': ladder_line, 'A': row_a, 'B': row_b}
    y = 0
    for i, (kind, n) in enumerate(SEGMENTS):
        y += n
        code, expect = makers[kind]()
        check(code, expect)
        assert expect + 7 <= 76, (kind, expect)
        o.append('; --- segment %d: %s, to line %d' % (i, kind, y))
        o.append('S%d:     sta WSYNC' % i)
        for chunk in code:
            o += ['        ' + s for s in chunk.split('\n') if s.strip()]
        o.append('        iny\n        cpy #%d\n        bne S%d' % (y, i))
    assert y == 192, y
    o.append('''        sta WSYNC
        lda #0
        sta GRP0
        sta GRP1
        sta PF0
        sta PF1
        sta PF2
        lda #2
        sta VBLANK
        ldx #29
OS:     sta WSYNC
        dex
        bne OS
        jmp Frame''')
    trogg, ladder = [], []
    for yy in range(256):
        p = yy % 32
        trogg.append(bits(TROGG[p // 2]) if p < 2 * len(TROGG) else 0)
        ladder.append(0xFF if yy % 8 in (0, 1) else 0x81)
    o.append('        org $FC00')
    for name, t in (('Trogg', trogg), ('Ladder', ladder)):
        o.append('%s:' % name)
        for i in range(0, 256, 16):
            o.append('        .byte ' + ','.join('$%02X' % v for v in t[i:i + 16]))
    o.append('        org $FFFC\n        .word Start\n        .word Start')
    open(base + '.asm', 'w').write('\n'.join(o) + '\n')
    subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                   check=True, stdout=subprocess.DEVNULL)


def report(png):
    """Print the black runs on the first line of each platform row and one ladder line."""
    im = Image.open(png).convert('RGB')
    sx = im.width / 160
    bg = im.getpixel((im.width - 2, im.height // 2))
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg) + 1
    def runs(line):
        r, i = [], 0
        row = [im.getpixel((int((x + 0.5) * sx), first + line)) for x in range(160)]
        while i < 160:
            if row[i] == (0, 0, 0):
                j = i
                while j < 160 and row[j] == (0, 0, 0):
                    j += 1
                r.append('%d-%d' % (i, j - 1))
                i = j
            else:
                i += 1
        return ' '.join(r)
    y = 0
    for kind, n in SEGMENTS:
        for k in range(n) if kind != 'ladder' else (2,):
            print('line %3d (%s): %s' % (y + k, kind, runs(y + k)))
        y += n


if __name__ == '__main__':
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'platforms')
    build(base)
    png = tiatest.snapshot(base + '.bin', outdir)
    if not png:
        sys.exit('no snapshot')
    os.replace(png, base + '.png')
    im = Image.open(base + '.png')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    print('snapshot', base + '.png', im.size)
    report(base + '.png')
