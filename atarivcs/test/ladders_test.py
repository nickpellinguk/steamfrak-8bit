#!/usr/bin/env python3
"""
Reusable renderer family: ladders only (one, two or three black ladders, rungs from a per-line
table, no playfield), in the current kernel: two-line rows,
carry-shared body, X counts lines (INX in the even tail), no WSYNC between a row's lines (the even
line is padded to 76), Trogg from a ROM index strip and a RAM frame buffer, the yoyo on M0.

    python3 atarivcs/test/leftpf1_test.py [OUT_DIR]

Sections are ordered so each one's first strobe is earlier than the previous one's last (the
ghost rule from park_test.py); single-ladder bodies clear GRP1 after the copy and write the rung
pattern after the old main copy has passed. The shared block is scheduled by the adapted search
(screens2), from cycle 10, its last store ending by 53, with the ghost rule for the ladders.
Sections (4 rows each): 31 58 85 112 | 19 40 61 82 103 | 19 40 61 82 | 112 | 58 82 103 | 46 100 | 61 | 19 43 64 | 19 40 | 19; Trogg at x 130.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.argv = sys.argv[:1] + ['--lines', '--buffer', '--nomidsync'] + sys.argv[1:]
import screens2 as s2  # noqa: E402
import tiatest  # noqa: E402
from trogg_rows import TROGG, bits  # noqa: E402
from PIL import Image  # noqa: E402

pad = tiatest.pad
BG, MAG, DARK, BLACK, TROGG_COL = 0xAA, 0x58, 0xA4, 0x00, 0x1E
PAIRS = [(31, 52, 73, 94, 115), (34, 61, 88, 115), (118,), (31, 58, 85, 112), (19, 40, 61, 82, 103), (19, 40, 61, 82), (112,), (58, 82, 103), (46, 100), (61,), (19, 43, 64), (19, 40), (19,)]   # strobes >= 21 px apart
ROWS = 4
TX = 130                     # Trogg (double width) at x 130-145, right of every ladder

src = s2._src.replace("        tasks.append(('spare', prev_end + 3))\n", "").replace(
    "            for r in (('y',) if ins == 'Y' else (('a', 'x') if FREEY else ('a',))):",
    "            for r in (('a', 'x')):")
ns = dict(s2._ns)
exec(src, ns)
schedule = ns['schedule']

# per-line tables (192 entries; each section uses lines 0..11 of its own range)
STRIPES = [BLACK, MAG, MAG, BLACK, DARK, DARK, DARK, DARK]
SHAPES = [0xFF, 0xFF, 0xFF, 0xFF, 0x3F, 0x3F, 0x3F, 0x3F, 0xFC, 0xFC, 0x0F, 0x0F]   # PF1 per line


def tables():
    t = {'PCol': [0] * 256, 'PF1T': [0] * 256, 'Lad': [0] * 256}
    for sec in range(len(PAIRS)):
        for k in range(2 * ROWS):
            y = 16 * sec + k
            t['PCol'][y] = STRIPES[k % 8]
            t['PF1T'][y] = SHAPES[k]
            t['Lad'][y] = 0x7E if k % 4 == 0 else 0x42
    return t


def body(name, xs):
    extra = []
    objs = [(x, ('tbl', 'Lad'), ('imm', BLACK)) for x in xs]
    code, end = schedule(((0, 0, 0), (0, 0, 0)), ((0, 0, 0), (0, 0, 0)), objs, ('imm', BLACK), True,
                         xs[-1], t0=10, end_limit=55, extra=extra)
    flat = [i.strip() for c in code for i in c.split('\n') if i.strip()]
    tail = ['ldy #0', 'lda (TrogPtr),y', 'tay', 'lda Buffer,y', 'sta GRP0', 'inx']
    n = 76 - (end + 3 + s2.ncycles(tail))
    assert n >= 0 and end + 2 <= 57, (name, end, n)
    if n == 1:
        tail[4] = 'sta.w GRP0'
    # two entry points: 'name_i: inx' falls into 'name:'; the body ends 'bcs even / rts'
    out = ['%s_i:' % name, 'inx', '%s:' % name, 'sta WSYNC', 'inc TrogPtr', 'sec', 'bit $80', '%s_s:' % name] + flat
    out += ['bcs %s_e' % name, 'rts', '%s_e:' % name] + tail
    if n > 1:
        out += pad(n).split('\n')
    out += ['asl', 'sta ENAM0', 'clc', 'jmp %s_s' % name]
    return out, end, flat


def build(base):
    t = tables()
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
        lda #0
        sta CTRLPF
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
    # park P1 in vertical blank: a strobe later than any renderer's first strobe, so the frame's
    # first renderer cancels its main copy (the ghost rule from park_test.py)
    o.append('        sta WSYNC\n        ' + pad(57).replace('\n', '\n        ') + '\n        sta RESP1')
    o.append('''        ldx #32
VB:     sta WSYNC
        dex
        bne VB
        lda #0
        sta VBLANK''')
    lines = 0
    bodies = []
    for sec, xs in enumerate(PAIRS):
        name = 'L%d' % sec
        code, end, flat = body(name, xs)
        bodies.append((name, xs, code, end, flat))
        o.append('        ldx #%d' % (16 * sec))
        o += ['        jsr %s' % name] + ['        jsr %s_i' % name] * (ROWS - 1)
        o += ['        sta WSYNC', '        lda #0', '        sta PF1', '        sta GRP1', '        sta GRP0',
              '        sta ENAM0', '        lda #$%02X' % BG, '        sta COLUPF']
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
    for name, xs, code, end, flat in bodies:
        o.append('        align 128')
        o += [c if c.endswith(':') else '        ' + c for c in code]
    for n in ('PCol', 'PF1T', 'Lad'):
        o.append('        align 256\n%s:' % n)
        for k in range(0, 256, 16):
            o.append('        .byte ' + ','.join('$%02X' % v for v in t[n][k:k + 16]))
    strip = [0] * 96
    for i in range(len(TROGG)):
        strip[1 + i] = i + 1             # Trogg's 13 rows from the first section's second row on
    o.append('        align 256\nTroggStrip:')
    for k in range(0, 96, 16):
        o.append('        .byte ' + ','.join('$%02X' % v for v in strip[k:k + 16]))
    o.append('TroggFrame: .byte ' + ','.join('$%02X' % bits(r) for r in TROGG))
    o.append('        org $FFFC\n        .word Start\n        .word Start')
    open(base + '.asm', 'w').write('\n'.join(o) + '\n')
    r = subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if r.returncode:
        print(r.stdout[-1500:])
        sys.exit('dasm failed')
    return t, bodies


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    outdir = os.path.abspath(args[0] if args else os.path.join(HERE, 'out', 'ladders'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'ladders')
    t, bodies = build(base)
    for name, xs, code, end, flat in bodies:
        print('%s: ladders %s, shared block ends %d (odd falls through at %d), %d instructions:' % (
            name, xs, end, end + 2, len(flat)))
        print('    ' + ' / '.join(flat))
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png').convert('RGB')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    sx = im.width / 160
    bg = (90, 176, 212)
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg) + 1
    rgb = {BLACK: (0, 0, 0), MAG: (192, 78, 170), DARK: (36, 98, 141)}
    bad, y0 = 0, 0
    for sec, xs in enumerate(PAIRS):
        for k in range(2 * ROWS):
            yv = 16 * sec + k
            want = {}
            for x in xs:
                for b in range(8):
                    if t['Lad'][yv] & (0x80 >> b):
                        want[x + b] = (0, 0, 0)
            got = {q: im.getpixel((int((q + 0.5) * sx), first + y0 + k)) for q in range(160)}
            got = {q: c for q, c in got.items() if c != bg}
            trogg = set(range(TX - 1, TX + 24))            # Trogg and his yoyo
            w = {q: c for q, c in want.items() if q not in trogg}
            g = {q: c for q, c in got.items() if q not in trogg}
            if w != g:
                bad += 1
                miss = sorted(q for q in w if g.get(q) != w[q])[:8]
                extra = sorted(q for q in g if q not in w)[:8]
                print('  section %d line %2d: wrong/missing %s extra %s' % (sec, k, miss, extra))
        y0 += 2 * ROWS + 4
    print('%d of %d lines differ from the model (Trogg and yoyo columns excluded)' % (bad, 2 * ROWS * len(PAIRS)))
