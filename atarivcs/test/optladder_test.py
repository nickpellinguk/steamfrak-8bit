#!/usr/bin/env python3
"""
Optional ladders: one renderer body whose ladders can be switched off line by line from a table,
by aiming the strobe with Y:

        ldy LadEn,x        ; 0 = shown, $1C = hidden
        ...
        sta RESP1,y        ; absolute,Y (5 cycles, constant): RESP1 ($11) or $2D (no TIA register)

All ladders share one graphic (GRP1 written once per line from the rung table), so a ladder can't be
hidden by its graphics; skipping its strobe hides it. Current kernel: carry-shared two-line rows, X
counts lines (INX in the even tail), no WSYNC between a row's lines, Trogg from the RAM buffer,
P1 parked in vertical blank.

    python3 atarivcs/test/optladder_test.py [OUT_DIR]

Sections (6 rows each), each with an irregular on/off pattern per line for its optional ladder:
  0: ladders 31 58 85, middle optional
  1: ladders 31 58 85, last optional
  2: ladders 31 58 85, first optional
  3: ladders 31 58, second optional (when it is off the row has one strobe: the ghost case)
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
BG, TROGG_COL = 0xAA, 0x1E
SECTIONS = [((31, 58, 85), 1), ((31, 58, 85), 2), ((31, 58, 85), 0), ((31, 58), 1)]
ROWS = 6
EN = [1, 1, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1]          # optional ladder on (1) / off (0) per line
TX = 130
HIDE = 0x1C


def cycles(ins):
    i = ins.split()
    if len(i) == 1:
        return 2
    if i[0] == 'bit':
        return 3
    if i[1].startswith('#'):
        return 2
    if i[1].endswith(',y') and i[0] == 'sta':
        return 5
    if i[1].endswith(',x') or i[1].endswith(',y') or i[0].endswith('.w'):
        return 4
    return 3


def shared(xs, opt):
    """Hand-scheduled shared block from cycle 10: one GRP1 write, the enable in Y, the strobes."""
    out, t = ['lda Lad,x', 'sta GRP1', 'ldy LadEn,x'], 10 + 4 + 3 + 4
    for k, x in enumerate(xs):
        c = 22 if x == 19 else (x + 47) // 3
        ins = 'sta RESP1,y' if k == opt else 'sta RESP1'
        gap = c - cycles(ins) - t
        assert gap >= 0 and gap != 1, (xs, opt, k, gap)
        if gap:
            out += pad(gap).split('\n')
        out.append(ins)
        t = c
    return out, t


def body(name, xs, opt):
    code, end = shared(xs, opt)
    tail = ['ldy #0', 'lda (TrogPtr),y', 'tay', 'lda Buffer,y', 'sta GRP0', 'inx']
    n = 76 - (end + 3 + sum(cycles(i) if '(' not in i else 5 for i in tail))
    assert n >= 0 and n != 1 and end + 2 <= 55, (name, end, n)
    out = ['%s:' % name, 'sta WSYNC', 'inc TrogPtr', 'sec', 'bit $80', '%s_s:' % name] + code
    out += ['bcs %s_e' % name, 'inx', 'rts', '%s_e:' % name] + tail
    if n:
        out += pad(n).split('\n')
    out += ['asl', 'sta ENAM0', 'clc', 'jmp %s_s' % name]
    return out, end, code


def build(base):
    lad = [0] * 256
    en = [0] * 256
    for sec in range(len(SECTIONS)):
        for k in range(2 * ROWS):
            y = 32 * sec + k
            lad[y] = 0x7E if k % 4 == 0 else 0x42
            en[y] = 0 if EN[k] else HIDE
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['GRP0 = $1B', 'COLUP0 = $06', 'RESM0 = $12', 'ENAM0 = $1D', 'TrogPtr = $80', 'Buffer = $82']
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
        sta COLUP0
        lda #0
        sta COLUP1
        sta GRP1
        sta GRP0
        lda #1
        sta NUSIZ1
        lda #$20
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
    for reg, xx in (('RESP0', TX), ('RESM0', TX + 8)):
        c = (xx + 68) // 3 if reg == 'RESM0' else (xx + 63) // 3
        o.append('        sta WSYNC\n        ' + pad(c - 3).replace('\n', '\n        ') + '\n        sta %s' % reg)
    o.append('        sta WSYNC\n        ' + pad(57).replace('\n', '\n        ') + '\n        sta RESP1   ; park P1')
    o.append('''        ldx #32
VB:     sta WSYNC
        dex
        bne VB
        lda #0
        sta VBLANK''')
    bodies, lines = [], 0
    for sec, (xs, opt) in enumerate(SECTIONS):
        name = 'B%d' % sec
        code, end, sh = body(name, xs, opt)
        bodies.append((name, xs, opt, code, end, sh))
        o.append('        ldx #%d' % (32 * sec))
        o += ['        jsr %s' % name] * ROWS
        o += ['        sta WSYNC', '        lda #0', '        sta GRP1', '        sta GRP0', '        sta ENAM0']
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
    for name, xs, opt, code, end, sh in bodies:
        o.append('        align 128')
        o += [c if c.endswith(':') else '        ' + c for c in code]
    for nm, tb in (('Lad', lad), ('LadEn', en)):
        o.append('        align 256\n%s:' % nm)
        for k in range(0, 256, 16):
            o.append('        .byte ' + ','.join('$%02X' % v for v in tb[k:k + 16]))
    strip = [0] * 96
    for i in range(len(TROGG)):
        strip[1 + i] = i + 1
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
    # the indexed strobe must assemble as absolute,Y (opcode $99) with base $0011
    lst = open(base + '.lst').read()
    assert '99 11 00' in lst, 'sta RESP1,y did not assemble as STA $0011,Y'
    return lad, en, bodies


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
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out', 'optladder'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'optladder')
    lad, en, bodies = build(base)
    for name, xs, opt, code, end, sh in bodies:
        print('%s: ladders %s, optional x %d: shared block ends %d (odd falls through at %d): %s' % (
            name, xs, xs[opt], end, end + 2, ' / '.join(sh)))
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png').convert('RGB')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    sx = im.width / 160
    bg = (90, 176, 212)
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg) + 1
    bad, y0 = 0, 0
    skip = set(range(TX - 1, TX + 16))
    for sec, (xs, opt) in enumerate(SECTIONS):
        print('section %d (optional x %d):' % (sec, xs[opt]))
        for k in range(2 * ROWS):
            yv = 32 * sec + k
            want = set()
            for j, x in enumerate(xs):
                if j == opt and en[yv]:
                    continue
                want |= {x + b for b in range(8) if lad[yv] & (0x80 >> b)}
            got = {q for q in range(160) if im.getpixel((int((q + 0.5) * sx), first + y0 + k)) != bg} - skip
            ok = got == want
            bad += not ok
            print('   line %2d  %-3s %-34s %s' % (k, 'on' if EN[k] else 'off', runs(sorted(got)),
                                                 'ok' if ok else 'expected ' + runs(sorted(want))))
        y0 += 2 * ROWS + 4
    print('%d of %d lines differ from the model' % (bad, 2 * ROWS * len(SECTIONS)))
