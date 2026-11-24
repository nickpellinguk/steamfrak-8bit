#!/usr/bin/env python3
"""
Two-line renderers whose bodies end INX / RTS; a level's call list is LDX then one JSR per row:

        ldx #PLAT   (or ldx zp)
        jsr B_2     ; row 1
        jsr B_2     ; row 2 ...

Odd-line budget: the body falls through BCS at cycle c, then INX 2 + RTS 6 [+ LDX 2/3] + JSR 6 and
the next body's STA WSYNC must write by cycle 75: c <= 58 between rows, c <= 55 into a new renderer
with LDX zp (56 with LDX #).

    python3 atarivcs/test/chain_test.py [OUT_DIR]

B: right platform x 96-135 + left ladder x 19; odd line falls through at 51.
A: ladder x 19 - object x 64 (Mid/MidCol,x) - ladder x 112; odd line falls through at 55.
Row index ranges: platform 0-3, gem 4-7, empty 8-11. Call list: B x4, A x4 (gem), LDX zp B x1,
A x4 (gem removed), LDX zp B x2 - so A -> B with LDX zp is tested twice.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tiatest  # noqa: E402
from platforms import pf_regs  # noqa: E402
from PIL import Image  # noqa: E402

BG, MAG, DARK, TROGG_COL, KEYCOL = 0xAA, 0x58, 0xA4, 0x1C, 0x58
PLATFORM = set(range(96, 136))
TROGG = [0x18, 0x3C, 0x7F, 0x3C, 0x24, 0x66, 0x00, 0x00, 0x18, 0x3C, 0x7F, 0x3C, 0x24]   # placeholder
TROGG_X, YOYO_X = 140, 150
CARRY_SAFE = {'ldy', 'sty', 'sta', 'lda', 'nop', 'bit', 'ldx', 'stx', 'jmp', 'bcs', 'inx'}


def chain(name, rows):
    out = []
    for n in range(rows, 1, -1):
        out += ['%s_%d:  jsr %s_2' % (name, 2 * n, name), '        inx']
    return out


def build(base):
    _, (r0, r1, r2) = pf_regs(PLATFORM)
    assert r0 == 0
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['GRP0 = $1B', 'COLUP0 = $06', 'RESM0 = $12', 'ENAM0 = $1D', 'NUSIZ0 = $04', 'COLUPF = $08',
          'PF0 = $0D', 'PF1 = $0E', 'PF2 = $0F', 'TrogPtr = $80', 'GemState = $82', 'PlatIdx = $83', 'PLAT = 0', 'GEM = 4', 'EMPTY = 8']
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
        sta PF0
        sta PF1
        sta PF2
        lda #1
        sta NUSIZ1
        lda #$30
        sta NUSIZ0
        lda #EMPTY
        sta GemState
        lda #PLAT
        sta PlatIdx          ; the second gem has been collected: its rows are the empty ones
        lda #>TroggStrip
        sta TrogPtr+1
        lda #<(TroggStrip-1)
        sta TrogPtr''' % (BG, TROGG_COL))
    for reg, xx in (('RESP0', TROGG_X), ('RESM0', YOYO_X)):
        c = (xx + 68) // 3 if reg == 'RESM0' else (xx + 63) // 3
        o.append('        sta WSYNC\n        ' + tiatest.pad(c - 3).replace('\n', '\n        ') + '\n        sta %s' % reg)
    o.append('''        ldx #33
VB:     sta WSYNC
        dex
        bne VB
        lda #0
        sta VBLANK
        ; ---- the level's call list ----
        ldx #PLAT
        jsr B_2
        jsr B_2
        jsr B_2
        jsr B_2
        ldx #GEM
        jsr A_2
        jsr A_2
        jsr A_2
        jsr A_2
        ldx PlatIdx      ; A -> B with LDX zp
        jsr B_2
        ldx GemState
        jsr A_2
        jsr A_2
        jsr A_2
        jsr A_2
        ldx PlatIdx      ; A -> B, two rows
        jsr B_2
        jsr B_2
        sta WSYNC
        lda #0
        sta GRP0
        sta GRP1
        sta ENAM0
        sta PF1
        sta PF2
        lda #$%02X
        sta COLUPF
        ldy #%d
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

; ===== renderer B: right-side platform with a left ladder =====
        align 256''' % (BG, 192 - (8 + 8 + 2 + 8 + 4) - 1))
    o.append('''B_2:    sta WSYNC          ; even line
        inc TrogPtr        ; 5
        ldy EvenCol,x      ; 9    this line's stripe colour
        sec                ; 11
        jmp B_sh           ; 14
B_odd:  sta WSYNC          ; odd line
        asl                ; 2    yoyo enable (changes carry)
        sta ENAM0          ; 5
        ldy OddCol,x       ; 9
        clc                ; 11
        bit $80            ; 14
B_sh:   sta RESP1          ; 17   left ladder (in the blank: x = 19)
        lda #$%02X
        sta COLUPF         ; 22   left half invisible (its pattern starts at x 16)
        lda #$81
        sta GRP1           ; 27   after P1's main copy (x 3), before the ladder's copy
        lda #$%02X
        sta PF1            ; 32   the right half's pattern (invisible on the left)
        lda #$%02X
        sta PF2            ; 37
        lda #0
        sta GRP1           ; 42   blank, for the next line's main copy
        nop
        nop                ; 46
        sty COLUPF         ; 49   the right half appears
        bcs B_even         ; 51 (odd: falls through) / 52 (even)
        inx                ; 53   next row
        rts                ; odd: back to the chain (INX, JSR) or the call list
B_even: ldy #0
        lda (TrogPtr),y
        sta GRP0           ; 61   Trogg's row (he is drawn by then)
        jmp B_odd          ; 64
B_end:

; ===== renderer A: black ladder - coloured object - black ladder =====
        align 256''' % (BG, r1, r2))
    o.append('''A_2:    sta WSYNC          ; even line
        inc TrogPtr        ; 5
        sec                ; 7
        jmp A_sh           ; 10
A_odd:  sta WSYNC          ; odd line
        asl                ; 2
        sta ENAM0          ; 5
        clc                ; 7
        bit $80            ; 10
A_sh:   lda #$%02X
        sta COLUPF         ; 15   no playfield on these lines
        sta RESP1          ; 18   left ladder (x = 19)
        ldy Mid,x          ; 22   the object's graphics for this row
        lda #$81
        sta GRP1           ; 27   after P1's main copy (x 3), before the ladder's copy
        lda MidCol,x       ; 31   and its colour
        sta COLUP1         ; 34   after the left ladder's copy
        sta RESP1          ; 37   the object: x = 64
        sty GRP1           ; 40
        lda #0             ; 42
        ldy #$81           ; 44
        sta COLUP1         ; 47   black again, after the object's copy
        sty GRP1           ; 50   the ladder graphic (the object is drawn by 47)
        sta RESP1          ; 53   right ladder: x = 112
        bcs A_even         ; 55 (odd: falls through) / 56
        inx                ; 57   next row
        rts
A_even: ldy #0
        lda (TrogPtr),y
        sta GRP0           ; 66
        jmp A_odd          ; 69
A_end:

        align 256
; row index ranges: platform rows 0-3, gem rows 4-7, empty rows 8-11
EvenCol:''' % BG)
    o.append('        .byte $00,$%02X,$%02X,$%02X, 0,0,0,0, 0,0,0,0' % (MAG, DARK, DARK))
    o.append('OddCol: .byte $%02X,$00,$%02X,$%02X, 0,0,0,0, 0,0,0,0' % (MAG, DARK, DARK))
    o.append('Mid:    .byte 0,0,0,0, $3C,$7E,$7E,$3C, 0,0,0,0')
    o.append('MidCol: .byte 0,0,0,0, $%02X,$%02X,$%02X,$%02X, 0,0,0,0' % ((KEYCOL,) * 4))
    o.append('''        align 256
TroggStrip:''')
    o.append('        .byte ' + ','.join('$%02X' % v for v in TROGG + [0] * 20))
    o.append('        org $FFFC\n        .word Start\n        .word Start')
    src = '\n'.join(o) + '\n'
    open(base + '.asm', 'w').write(src)
    r = subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if r.returncode:
        print(r.stdout[-1500:])
        sys.exit('dasm failed')
    # carry check on the shared blocks
    for blk in ('B_sh:', 'A_sh:'):
        seg = src.split(blk)[1].split('rts')[0]
        for line in seg.split('\n'):
            t = line.split(';')[0].split()
            if t and not t[0].endswith(':'):
                assert t[0] in CARRY_SAFE, line
    labels, rows = {}, []
    for line in open(base + '.lst'):
        f = line.split()
        if len(f) == 3 and f[2][0].isalpha():
            labels[f[2]] = int(f[1], 16)
        m = __import__('re').match(r'\s*\d+\s+([0-9a-f]{4})\s+(?:[0-9a-f]{2}\s)+\s*([A-Za-z_]\w*)\s', line)
        if m:
            labels[m.group(2)] = int(m.group(1), 16)
        rows.append(f)
    for f in rows:
        if len(f) >= 6 and f[4] in ('bcs', 'bne') and f[5] in labels:
            assert (int(f[1], 16) + 2) >> 8 == labels[f[5]] >> 8, 'page crossing: %s' % f
    return labels


if __name__ == '__main__':
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out', 'chain'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'chain')
    lab = build(base)
    print('B body %d bytes, A body %d bytes' % (lab['B_end'] - lab['B_2'], lab['A_end'] - lab['A_2']))
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png').convert('RGB')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    sx = im.width / 160
    bg = (90, 176, 212)
    names = {(0, 0, 0): 'k', (192, 78, 170): 'M', (36, 98, 141): 'D', (230, 230, 62): 'T'}
    start = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg)
    for j in range(32):
        row = [im.getpixel((int((x + 0.5) * sx), start + j)) for x in range(160)]
        runs, x = [], 0
        while x < 160:
            if row[x] != bg:
                k = x
                while k < 160 and row[k] == row[x]:
                    k += 1
                runs.append('%d-%d%s' % (x, k - 1, names.get(row[x], '?')))
                x = k
            else:
                x += 1
        print('%2d %s' % (j, '  '.join(runs) or '-'))
