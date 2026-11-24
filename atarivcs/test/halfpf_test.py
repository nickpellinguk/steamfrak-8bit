#!/usr/bin/env python3
"""
One-sided platform rows with a sled-placed ladder: the playfield registers hold one half's
pattern (repeat mode, so both halves show it) and COLUPF is switched at the centre of the line
(cycle 49, pixel ~80) between the background colour and the platform colour, so only one half is
visible. The ladder (a player-1 copy, NUSIZ1 = two close) is placed by a CMP #$C9 sled.

    python3 atarivcs/test/halfpf_test.py [OUT_DIR]

Variations (A, X, Y on entry to each line: A = ladder graphics $18, X = platform colour,
Y = line counter):
  A  right platform, left ladder:  restore COLUPF=bg; JMP (S1); sled d; RESP1; GRP1; JMP (S2);
                                   sled D-d; STX COLUPF (lands at 49)
  B  right platform, right ladder: restore COLUPF=bg; ...; STX COLUPF at 49; JMP (S1); sled d;
                                   RESP1; GRP1
  C  left platform, left ladder:   STX COLUPF (platform colour from the start); JMP (S1); sled d;
                                   RESP1; GRP1; JMP (S2); sled D-d; LDA #bg / STA COLUPF at 49
  D  left platform, right ladder:  STX COLUPF; ...; bg at 49; JMP (S1); sled d; RESP1; GRP1
Plus edge sections: a full right half switched on at 49 and at 50, and a full left half switched
off at 49 and at 50, to see which centre pixels are right.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tiatest  # noqa: E402
from platforms import pf_regs  # noqa: E402
from PIL import Image  # noqa: E402

pad = tiatest.pad
BG, PLAT = 0xAA, 0x58
LINES = 4


def sled_bytes(n):
    return [0xC9] * n + [0xC5, 0xEA]


def sled_delay(n, entry):
    s, p, c = sled_bytes(n), entry, 0
    while p < len(s):
        if s[p] == 0xC9:
            c, p = c + 2, p + 2
        elif s[p] == 0xC5:
            c, p = c + 3, p + 2
        else:
            c, p = c + 2, p + 1
    return c


def entry_for(n, delay):
    for e in range(n + 2):
        if sled_delay(n, e) == delay:
            return e
    raise ValueError((n, delay))


RIGHT = set(range(84, 136))            # right-side platform (blocks 21-33)
LEFT = set(range(24, 64))              # left-side platform (blocks 6-15)
FULL_R = set(range(80, 160))
FULL_L = set(range(0, 80))


def regs(lit, side):
    L, R = pf_regs(lit)
    return R if side == 'R' else L


# Each section: (label, variant, pf pattern side+set, sled delays (d1, d2 or None), colour-write cycle)
def sections():
    out = []
    # every line: GRP1 cleared in the blank (so P1's main copy, 16 px left of the copy, is drawn
    # blank) and the ladder's GRP1 written 2 cycles after its strobe (after the main copy has gone
    # past, before the copy starts)
    # A: clear (5), restore bg (5), lda #$18 (2), JMP 5, d, RESP1 3, NOP 2, GRP1 3, JMP 5, D-d, STX 3 = 49
    DA = 49 - (5 + 5 + 2 + 5 + 3 + 2 + 3 + 5 + 3)
    for d in (2, 5, 8, 11, DA - 2):
        out.append(('A right pf, left ladder, sled %d+%d' % (d, DA - d), 'A', ('R', RIGHT), (d, DA - d), 49))
    for d in (2, 3, 4, 5):
        out.append(('B right pf, right ladder, sled %d' % d, 'B', ('R', RIGHT), (d, None), 49))
    # C: STX 3, clear 5, lda #$18 2, JMP 5, d, RESP1 3, NOP 2, GRP1 3, JMP 5, D-d, LDA 2, STA 3 = 49
    DC = 49 - (3 + 5 + 2 + 5 + 3 + 2 + 3 + 5 + 2 + 3)
    for d in (2, 5, 8, 11, DC - 2):
        out.append(('C left pf, left ladder, sled %d+%d' % (d, DC - d), 'C', ('L', LEFT), (d, DC - d), 49))
    for d in (2, 3):
        out.append(('D left pf, right ladder, sled %d' % d, 'D', ('L', LEFT), (d, None), 49))
    for at in (49, 50):
        out.append(('edge: full right half on at %d' % at, 'B0', ('R', FULL_R), None, at))
    for at in (49, 50):
        out.append(('edge: full left half off at %d' % at, 'D0', ('L', FULL_L), None, at))
    return out


def line_code(i, var, sleds, at):
    """Returns (asm lines, cycles to the end of the line before DEY/BNE)."""
    c = []
    if var in ('A', 'B', 'B0'):
        c += ['lda #0', 'sta GRP1', 'lda #$%02X' % BG, 'sta COLUPF', 'lda #$18']    # 12
        t = 12
    else:
        c += ['stx COLUPF', 'lda #0', 'sta GRP1', 'lda #$18']                        # 10
        t = 10
    ladder = ['sta RESP1', 'nop', 'sta GRP1']
    if var == 'A':
        c += ['jmp (Sled1)', 'R1_%d:' % i] + ladder + ['jmp (Sled2)', 'R2_%d:' % i, 'stx COLUPF']
        t = 49
    elif var == 'C':
        c += ['jmp (Sled1)', 'R1_%d:' % i] + ladder + ['jmp (Sled2)', 'R2_%d:' % i,
                                                      'lda #$%02X' % BG, 'sta COLUPF']
        t = 49
    elif var in ('B', 'B0'):
        c += [pad(at - 3 - t), 'stx COLUPF']
        t = at
        if var == 'B':
            c += ['jmp (Sled1)', 'R1_%d:' % i] + ladder
            t += 5 + sleds[0] + 8
    else:                                                              # D, D0
        c += [pad(at - 5 - t), 'lda #$%02X' % BG, 'sta COLUPF', 'lda #$18']
        t = at + 2
        if var == 'D':
            c += ['jmp (Sled1)', 'R1_%d:' % i] + ladder
            t += 5 + sleds[0] + 8
    return c, t


def build(base):
    secs = sections()
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['COLUPF   = $08', 'PF0      = $0D', 'PF1      = $0E', 'PF2      = $0F', 'Sled1 = $80', 'Sled2 = $82']
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
        sta CTRLPF
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
    sledlen = 30
    for i, (label, var, (side, lit), sleds, at) in enumerate(secs):
        r0, r1, r2 = regs(lit, side)
        o.append('; --- section %d: %s' % (i, label))
        o.append('        sta WSYNC\n        lda #$%02X\n        sta COLUPF\n        lda #$%02X\n        sta PF0\n'
                 '        lda #$%02X\n        sta PF1\n        lda #$%02X\n        sta PF2' % (BG, r0, r1, r2))
        if sleds:
            e1 = entry_for(sledlen, sleds[0])
            o.append('        lda #<(Sl1_%d+%d)\n        sta Sled1\n        lda #>(Sl1_%d+%d)\n        sta Sled1+1' % (i, e1, i, e1))
            if sleds[1] is not None:
                e2 = entry_for(sledlen, sleds[1])
                o.append('        lda #<(Sl2_%d+%d)\n        sta Sled2\n        lda #>(Sl2_%d+%d)\n        sta Sled2+1' % (i, e2, i, e2))
        o.append('        lda #$18\n        ldx #$%02X\n        ldy #%d' % (PLAT, LINES))
        code, t = line_code(i, var, sleds, at)
        assert t + 2 + 3 + 3 <= 75, (label, t)          # DEY, BNE, the next STA WSYNC
        o.append('L%d:     sta WSYNC          ; every line starts here, at cycle 0' % i)
        for ins in code:
            if ins.startswith('R1_'):
                o.append('        jmp *+3+%d' % 0) if False else None
                o.append('Sl1_%d: .byte %s' % (i, ','.join('$%02X' % b for b in sled_bytes(sledlen))))
                o.append(ins)
            elif ins.startswith('R2_'):
                o.append('Sl2_%d: .byte %s' % (i, ','.join('$%02X' % b for b in sled_bytes(sledlen))))
                o.append(ins)
            else:
                o += ['        ' + s for s in ins.split('\n') if s.strip()]
        o.append('        dey\n        bne L%d\n        sta WSYNC' % i)
        o.append('        lda #0\n        sta GRP1\n        sta PF0\n        sta PF1\n        sta PF2\n        sta WSYNC')
        used += 1 + LINES + 2
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
    r = subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if r.returncode:
        print(r.stdout[-1500:])
        sys.exit('dasm failed')
    return secs


if __name__ == '__main__':
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out', 'halfpf'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'halfpf')
    secs = build(base)
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png').convert('RGB')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    sx = im.width / 160
    bg = im.getpixel((im.width - 2, im.height // 2))
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg) + 1
    y = 1
    for label, var, (side, lit), sleds, at in secs:
        y += 1
        row = [im.getpixel((int((x + 0.5) * sx), first + y + 2)) for x in range(160)]
        runs, x = [], 0
        while x < 160:
            if row[x] != bg:
                j = x
                while j < 160 and row[j] == row[x]:
                    j += 1
                runs.append('%d-%d %s' % (x, j - 1, 'pf' if row[x][0] > 120 else 'ladder'))
                x = j
            else:
                x += 1
        print('%-44s %s' % (label, '; '.join(runs)))
        y += LINES + 2
