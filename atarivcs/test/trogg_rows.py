#!/usr/bin/env python3
"""
Test kernel: a Trogg-like sprite on player 0, repeated all the way down the screen, with six
bands of ladders (L) and gems (G) drawn by retriggering player 1 on every line (NUSIZ1 = two
close; each RESP1 strobe gives one copy 16 pixels later, and GRP1 is rewritten straight after
each strobe so each copy can be a ladder or a gem).

    python3 atarivcs/test/trogg_rows.py OUT_DIR

One-line kernel, Y = line 0-191, all graphics from page-aligned 256-byte tables indexed by Y:
    sta WSYNC / lda Trogg,y / sta GRP0 / lda Ladder,y / ldx Gem,y / [pad] /
    per object: sta RESP1 / sta|stx GRP1 / [pad] / iny / cpy #end / bne
Writes trogg_rows.asm/.bin and a 1x Stella snapshot trogg_rows.png (plus a 4x3 scaled copy).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tiatest  # noqa: E402
from PIL import Image  # noqa: E402

# (label, objects, strobe gap in cycles)
BANDS = [("L L, gap 8", "LL", 8),
         ("L G L, gap 8", "LGL", 8),
         ("G G G G, gap 8", "GGGG", 8),
         ("L L L, gap 8", "LLL", 8),
         ("G L G L, gap 8", "GLGL", 8),
         ("L G, gap 12", "LG", 12)]
BAND_LINES = 32
FIRST_STROBE_END = 26          # cycle; its copy lands at x = 31 (measured)
TROGG_X_CYCLE = 38             # RESP0 strobe cycle in VBLANK: puts Trogg among the objects

TROGG = ['...XX...', '..XXXX..', '.XXXXX..', '.XX.XXXX', '.XXXXXXX', '..XXX...', '.XXXXX..',
         'XXXXXXX.', 'X.XXXX.X', '..XXXX..', '..X..X..', '..X..X..', '.XX..XX.']
GEM = ['...XX...', '..XXXX..', '.XXXXXX.', '..XXXX..', '...XX...']


def bits(row):
    return int(row.replace('X', '1').replace('.', '0'), 2)


def tables():
    trogg, ladder, gem = [], [], []
    for y in range(256):
        p = y % 32
        trogg.append(bits(TROGG[p // 2]) if p < 2 * len(TROGG) else 0)
        ladder.append(0xFF if y % 8 in (0, 1) else 0x81)          # rails, a rung every 8 lines
        q = (y + 16) % 32
        gem.append(bits(GEM[q // 2]) if q < 2 * len(GEM) else 0)
    return trogg, ladder, gem


def build(base):
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o.append('GRP0     = $1B')
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
        lda #$58          ; Trogg: magenta
        sta COLUP0
        lda #$00          ; scenery: black
        sta COLUP1
        lda #0
        sta NUSIZ0
        lda #1
        sta NUSIZ1
        sta WSYNC''')
    o.append('        ' + tiatest.pad(TROGG_X_CYCLE - 3).replace('\n', '\n        '))
    o.append('''        sta RESP0
        ldx #34
VB:     sta WSYNC
        dex
        bne VB
        ldy #0
        sta WSYNC
        lda #0
        sta VBLANK''')
    end = 0
    for b, (label, objs, gap) in enumerate(BANDS):
        end += BAND_LINES
        o.append('; --- band %d: %s' % (b, label))
        o.append('B%d:     sta WSYNC' % b)
        o.append('        lda Trogg,y\n        sta GRP0\n        lda Ladder,y\n        ldx Gem,y')
        o.append('        ' + tiatest.pad(FIRST_STROBE_END - 3 - 15).replace('\n', '\n        '))
        cyc = FIRST_STROBE_END
        for k, ob in enumerate(objs):
            o.append('        sta RESP1')
            o.append('        %s GRP1' % ('sta' if ob == 'L' else 'stx'))
            cyc += 3
            if k < len(objs) - 1:
                if gap - 6:
                    o.append('        ' + tiatest.pad(gap - 6).replace('\n', '\n        '))
                cyc += gap - 3
        cyc += 2 + 2 + 3 + 1
        assert cyc <= 76, (label, cyc)
        o.append('        iny\n        cpy #%d\n        bne B%d' % (end % 256, b))
    o.append('''        sta WSYNC
        lda #0
        sta GRP0
        sta GRP1
        lda #2
        sta VBLANK
        ldx #29
OS:     sta WSYNC
        dex
        bne OS
        jmp Frame''')
    names = ('Trogg', 'Ladder', 'Gem')
    o.append('        org $FC00')
    for name, t in zip(names, tables()):
        o.append('%s:' % name)
        for i in range(0, 256, 16):
            o.append('        .byte ' + ','.join('$%02X' % v for v in t[i:i + 16]))
    o.append('        org $FFFC\n        .word Start\n        .word Start')
    open(base + '.asm', 'w').write('\n'.join(o) + '\n')
    import subprocess
    subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                   check=True, stdout=subprocess.DEVNULL)


if __name__ == '__main__':
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'trogg_rows')
    build(base)
    png = tiatest.snapshot(base + '.bin', outdir)
    if not png:
        sys.exit('no snapshot')
    os.replace(png, base + '.png')
    im = Image.open(base + '.png')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    print('snapshot', base + '.png', im.size)
