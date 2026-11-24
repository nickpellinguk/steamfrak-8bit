#!/usr/bin/env python3
"""
A small harness for TIA timing experiments: builds a ROM from a list of sections, runs it in
Stella (under a virtual X display), takes a 1x TIA snapshot and prints where player 1 / missile 1
are drawn on each line, in TIA pixels (0-159).

    python3 atarivcs/test/tiatest.py EXPERIMENT_FILE.py OUT_DIR

An experiment file defines SECTIONS = [(label, setup_asm, line_asm, lines), ...]:
  setup_asm runs once (outside the visible lines' timing), line_asm runs at the start of each of
  `lines` scanlines, from cycle 0 (straight after WSYNC). Each section is followed by 6 lines with
  no code (to see where things ended up) and 3 blank lines. Use pad(n) for an exact n-cycle delay.
Needs dasm, stella, xvfb-run and xdotool.
"""
import os
import subprocess
import sys
import time

from PIL import Image

EQU = dict(VSYNC=0x00, VBLANK=0x01, WSYNC=0x02, NUSIZ0=0x04, NUSIZ1=0x05, COLUP0=0x06, COLUP1=0x07,
           COLUBK=0x09, CTRLPF=0x0A, REFP1=0x0C, RESP0=0x10, RESP1=0x11, RESM1=0x13, RESBL=0x14,
           GRP1=0x1C, ENAM1=0x1E, ENABL=0x1F, HMP1=0x21, HMM1=0x23, HMBL=0x24, VDELP1=0x26,
           HMOVE=0x2A, HMCLR=0x2B)


def pad(n):
    """Exactly n cycles (n >= 2) of nops; uses one 3-cycle 'bit $80' for odd counts."""
    assert n >= 2 or n == 0
    out = []
    if n % 2:
        out.append('bit $80')
        n -= 3
    out += ['nop'] * (n // 2)
    return '\n'.join(out)


def build(sections, path):
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in EQU.items()]
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
        ldx #36
VB:     sta WSYNC
        dex
        bne VB
        lda #$0C
        sta COLUBK
        lda #$00
        sta COLUP1
        sta WSYNC
        sta WSYNC
        lda #0
        sta VBLANK''')
    used = 0
    for i, (label, setup, line, n) in enumerate(sections):
        o.append('; --- section %d: %s' % (i, label))
        o.append('        sta WSYNC')
        o += ['        ' + s for s in setup.strip().split('\n') if s.strip()]
        o.append('        lda #$FF\n        sta GRP1\n        ldy #%d' % n)
        o.append('L%da:    sta WSYNC' % i)
        o += ['        ' + s for s in line.strip().split('\n') if s.strip()]
        o.append('        dey\n        bne L%da' % i)
        o.append('        ldy #6\nL%db:    sta WSYNC\n        dey\n        bne L%db' % (i, i))
        o.append('        sta WSYNC\n        lda #0\n        sta GRP1\n        sta ENAM1\n        sta ENABL\n'
                 '        sta HMCLR\n        sta REFP1\n        sta WSYNC\n        sta WSYNC')
        used += 1 + n + 6 + 3
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
    open(path + '.asm', 'w').write('\n'.join(o) + '\n')
    subprocess.run(['dasm', path + '.asm', '-f3', '-o' + path + '.bin', '-l' + path + '.lst'],
                   check=True, stdout=subprocess.DEVNULL)


def snapshot(rom, outdir):
    env = dict(os.environ, XDG_RUNTIME_DIR=os.path.join(outdir, '.xdg'))
    os.makedirs(env['XDG_RUNTIME_DIR'], mode=0o700, exist_ok=True)
    for f in os.listdir(outdir):
        if f.endswith('.png') and f.startswith('snap'):
            os.remove(os.path.join(outdir, f))
    script = ('stella -uimessages 0 -fullscreen 0 -ss1x 1 -sssingle 1 -snapname int -snapsavedir %s %s '
              '>/dev/null 2>&1 & sleep 4; W=$(xdotool search --name Stella | head -1); xdotool windowfocus $W; '
              'xdotool key --window $W F12 >/dev/null 2>&1; sleep 2; kill %%1') % (outdir, rom)
    subprocess.run(['xvfb-run', '-a', '-s', '-screen 0 1280x1024x24', 'bash', '-c', script], env=env)
    pngs = [f for f in os.listdir(outdir) if f.endswith('.png') and not f.startswith('result')]
    pngs.sort(key=lambda f: os.path.getmtime(os.path.join(outdir, f)))
    return os.path.join(outdir, pngs[-1]) if pngs else None


ALL = False


def analyse(png, sections):
    im = Image.open(png).convert('RGB')
    w, h = im.size
    sx = w / 160
    bg = im.getpixel((w - 2, h // 2))
    # find the first visible line: first row that is background-coloured
    rows = []
    for y in range(h):
        row = [im.getpixel((int((i + 0.5) * sx), y)) for i in range(160)]
        rows.append(row)
    first = next(y for y in range(h) if rows[y][159] == bg)
    def runs(row):
        r, i = [], 0
        while i < 160:
            if row[i] != bg:
                j = i
                while j < 160 and row[j] != bg:
                    j += 1
                r.append((i, j - i))
                i = j
            else:
                i += 1
        return r
    y = first + 1                          # the WSYNC before section 0's setup
    for i, (label, _, _, n) in enumerate(sections):
        print('== %d: %s' % (i, label))
        y += 1                             # setup line
        prev = None
        for k in range(n + 6):
            rr = runs(rows[y + k])
            tag = 'L%-2d' % k if k < n else 'A%-2d' % (k - n)
            if rr != prev or ALL:
                print('   %s %s' % (tag, ' '.join('%d+%d' % r for r in rr) or '-'))
            prev = rr
        y += n + 6 + 3


if __name__ == '__main__':
    exp, outdir = sys.argv[1], os.path.abspath(sys.argv[2])
    os.makedirs(outdir, exist_ok=True)
    g = {'pad': pad}
    exec(open(exp).read(), g)
    globals()['ALL'] = g.get('ALL', False)
    base = os.path.join(outdir, os.path.splitext(os.path.basename(exp))[0])
    build(g['SECTIONS'], base)
    png = snapshot(base + '.bin', outdir)
    if not png:
        sys.exit('no snapshot')
    os.replace(png, base + '.png')
    print('snapshot', base + '.png', Image.open(base + '.png').size)
    analyse(base + '.png', g['SECTIONS'])
