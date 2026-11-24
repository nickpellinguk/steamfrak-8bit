#!/usr/bin/env python3
"""
Mirrored playfield (CTRLPF bit 0, PF0 never written): rows scheduled from tools/mirrorrows.py's
exact per-row tasks (from the platforms' actual blocks, with the timing measured by
test/mirror_windows.py), trying its ways to draw a row ('rewrite' the register mid-line, or 'hide'
the unwanted copy with COLUPF), in the current kernel.

    python3 atarivcs/test/mirror_test.py [OUT_DIR]

Each section: (name, lit blocks, ladder x positions); 6 rows, per-line stripe and rung tables.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
import feasibility as F  # noqa: E402
import mirrorrows as M  # noqa: E402
import tiatest  # noqa: E402
from trogg_rows import TROGG, bits  # noqa: E402
from PIL import Image  # noqa: E402

F._setup()
pad = tiatest.pad
BG, MAG, DARK, BLACK, TROGG_COL = 0xAA, 0x58, 0xA4, 0x00, 0x1E
ROWS = 6
STRIPES = [BLACK, MAG, MAG, BLACK, DARK, DARK, DARK, DARK]
TX = 126                     # Trogg x 126-141, his yoyo at 142 (both skipped by the checker)
# (variant, ladders, {table: [value per line, 12 lines]}); PF0 uses its high nibble (x 80-95)
FULL, PART = [0xFF] * 12, [0xFF, 0xFF, 0xFF, 0xFF, 0x0F, 0x0F, 0xF0, 0xF0, 0x3C, 0x3C, 0xFF, 0xFF]
SECTIONS = []          # filled from the feasibility table in main()


def body(name, extra, xs):
    objs = [(x, ('tbl', 'Lad'), ('imm', BLACK)) for x in xs]
    code, end = F.schedule(((0, 0, 0), (0, 0, 0)), ((0, 0, 0), (0, 0, 0)), objs, ('imm', BLACK), True,
                           xs[-1] if xs else None, t0=10, end_limit=55, extra=list(extra))
    flat = [i.strip() for c in code for i in c.split('\n') if i.strip()]
    tail = ['ldy #0', 'lda (TrogPtr),y', 'tay', 'lda Buffer,y', 'sta GRP0', 'inx']
    import screens2
    n = 76 - (end + 3 + screens2.ncycles(tail))
    assert n >= 0, (name, end)
    if n == 1:
        tail[4] = 'sta.w GRP0'
    out = ['%s_i:' % name, 'inx', '%s:' % name, 'sta WSYNC', 'inc TrogPtr', 'sec', 'bit $80', '%s_s:' % name] + flat
    out += ['bcs %s_e' % name, 'rts', '%s_e:' % name] + tail
    if n > 1:
        out += pad(n).split('\n')
    out += ['asl', 'sta ENAM0', 'clc', 'jmp %s_s' % name]
    return out, end, flat


def build(base):
    tabs = {}
    for sec, (v, xs, lit) in enumerate(SECTIONS):
        for k in range(2 * ROWS):
            y = 16 * sec + k
            tabs.setdefault('Stripe', [0] * 256)[y] = STRIPES[k % 8]
            tabs.setdefault('Lad', [0] * 256)[y] = 0x7E if k % 4 == 0 else 0x42
            for r in M.REGS:
                for side in 'LR':
                    tabs.setdefault(side + r, [0] * 256)[y] = M.value(lit, r, side)
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['GRP0 = $1B', 'COLUP0 = $06', 'RESM0 = $12', 'ENAM0 = $1D', 'COLUPF = $08',
          'PF0 = $0D', 'PF1 = $0E', 'PF2 = $0F', 'TrogPtr = $80', 'Buffer = $82']
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
        lda #1
        sta CTRLPF          ; mirrored playfield
        lda #0
        sta COLUP1
        sta GRP1
        sta GRP0
        sta PF0
        sta PF1
        sta PF2
        lda #1
        sta NUSIZ1
        lda #$25
        sta NUSIZ0
        ldy #%d
CopyF:  lda TroggFrame-1,y
        sta Buffer,y
        dey
        bne CopyF
        lda #>TroggStrip
        sta TrogPtr+1
        lda #<(TroggStrip-1)
        sta TrogPtr''' % (BG, TROGG_COL, len(TROGG)))
    for reg, xx in (('RESP0', TX), ('RESM0', TX + 16)):
        c = (xx + 68) // 3 if reg == 'RESM0' else (xx + 63) // 3
        o.append('        sta WSYNC\n        ' + pad(c - 3).replace('\n', '\n        ') + '\n        sta %s' % reg)
    o.append('        sta WSYNC\n        ' + pad(57).replace('\n', '\n        ') + '\n        sta RESP1')
    o.append('''        ldx #32
VB:     sta WSYNC
        dex
        bne VB
        lda #0
        sta VBLANK''')
    bodies, lines = [], 0
    prev = None
    for sec, (v, xs, lit) in enumerate(SECTIONS):
        name = 'P%d' % sec
        res = None
        chained = sec + 1 < len(SECTIONS) and SECTIONS[sec + 1][0].startswith('+')
        ways = M.tasks(lit, prev if v.startswith('+') else None)
        if os.environ.get('PREFER_HIDE'):
            ways = sorted(ways, key=lambda w: w[0] != 'hide')
        for way, tk, endst in ways:
            try:
                res = body(name, tk, xs) + (way,)
                prev = endst
                break
            except (ValueError, AssertionError):
                continue
        assert res, ('no way fits', v)
        code, end, flat, way = res
        print('%s: drawn by %s' % (v, way))
        bodies.append((name, v, xs, code, end, flat))
        o.append('        ldx #%d' % (16 * sec))
        o += ['        jsr %s' % name] + ['        jsr %s_i' % name] * (ROWS - 1)
        if chained:                       # the next section follows straight on: a renderer change
            lines += 2 * ROWS
            continue
        o += ['        sta WSYNC', '        lda #0', '        sta PF1', '        sta PF2', '        sta GRP1',
              '        sta GRP0', '        sta ENAM0', '        lda #$%02X' % BG, '        sta COLUPF']
        o += ['        sta WSYNC'] * 3
        lines += 2 * ROWS + 4
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
        jmp Frame''' % (192 - lines))
    for name, v, xs, code, end, flat in bodies:  # noqa
        o.append('        align 128')
        o += [c if c.endswith(':') else '        ' + c for c in code]
    for t, vals in tabs.items():
        o.append('        align 256\n%s:' % t)
        for k in range(0, 256, 16):
            o.append('        .byte ' + ','.join('$%02X' % x for x in vals[k:k + 16]))
    strip = [0] * 96
    for i in range(len(TROGG)):
        strip[1 + i] = i + 1
    o.append('        align 256\nTroggStrip:')
    for k in range(0, 96, 16):
        o.append('        .byte ' + ','.join('$%02X' % x for x in strip[k:k + 16]))
    o.append('TroggFrame: .byte ' + ','.join('$%02X' % bits(r) for r in TROGG))
    o.append('        org $FFFC\n        .word Start\n        .word Start')
    open(base + '.asm', 'w').write('\n'.join(o) + '\n')
    r = subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if r.returncode:
        print(r.stdout[-1500:])
        sys.exit('dasm failed')
    return tabs, bodies


def expected(lit, tabs, y, xs):
    want = {}
    col = {BLACK: (0, 0, 0), MAG: (192, 78, 170), DARK: (36, 98, 141)}[tabs['Stripe'][y]]
    for k in lit:
        for q in range(4 * k, 4 * k + 4):
            want[q] = col
    for x in xs:
        for b in range(8):
            if tabs['Lad'][y] & (0x80 >> b):
                want[x + b] = (0, 0, 0)
    return want


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    outdir = os.path.abspath(args[0] if args else os.path.join(HERE, 'out', 'mirrortest'))
    os.makedirs(outdir, exist_ok=True)
    rng = lambda a, b: set(range(a // 4, (b + 1) // 4))
    SECTIONS.extend([
        ('centre-crossing x48-111', (19, 118), rng(48, 111)),
        ('left only x48-71', (82, 118), rng(48, 71)),
        ('right only x96-111', (19, 52), rng(96, 111)),
        ('both halves, PF1 differs', (61,), rng(16, 39) | rng(112, 135)),
        ('symmetric x56-79 + x80-103', (19, 112), rng(56, 103)),
        # a single object then, straight on, two objects whose first strobe is at the same cycle:
        # the single row parks P1 after its copy, so the next renderer's first strobe cancels the ghost
        ('single ladder x49', (49,), set()),
        ('+ then ladders x49, x118', (49, 118), set()),
        # single far-right objects: no room to park, so an invisible copy at x 19 comes first
        ('single ladder x106', (106,), set()),
        ('+ then ladder x118', (118,), set()),
        ('+ then ladders x61, x106', (61, 106), set()),
    ])
    base = os.path.join(outdir, 'mirror')
    tabs, bodies = build(base)
    for name, v, xs, code, end, flat in bodies:  # noqa
        print('%s %s ladders %s: shared block ends %d: %s' % (name, v, xs, end, ' / '.join(flat)))
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png').convert('RGB')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    sx = im.width / 160
    bg = (90, 176, 212)
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg) + 1
    bad, y0 = 0, 0
    skip = set(range(TX - 1, TX + 24))
    for sec, (v, xs, lit) in enumerate(SECTIONS):
        for k in range(2 * ROWS):
            yv = 16 * sec + k
            want = {q: c for q, c in expected(lit, tabs, yv, xs).items() if q not in skip}
            got = {q: im.getpixel((int((q + 0.5) * sx), first + y0 + k)) for q in range(160)}
            got = {q: c for q, c in got.items() if c != bg and q not in skip}
            if want != got:
                bad += 1
                print('  %s line %2d: wrong/missing %s extra %s' % (v, k, sorted(q for q in want if got.get(q) != want[q])[:10],
                                                                   sorted(q for q in got if q not in want)[:10]))
        y0 += 2 * ROWS + (0 if sec + 1 < len(SECTIONS) and SECTIONS[sec + 1][0].startswith('+') else 4)
    print('%d of %d lines differ from the model' % (bad, 2 * ROWS * len(SECTIONS)))


if __name__ == '__main__':
    main()
