#!/usr/bin/env python3
"""
Checks that musicdrv_c.asm (the compact driver, frakmusic_c.inc) sounds exactly like musicdrv.asm
(frakmusic.inc): both are run in py65, a MusicTick per frame, and the six audio registers (AUDC,
AUDF, AUDV for both channels) compared after every frame. Also reports each one's size.

    python3 atarivcs/music/equiv_test.py [FRAMES]
"""
import os
import subprocess
import sys
import tempfile
from py65.devices.mpu6502 import MPU

HERE = os.path.dirname(os.path.abspath(__file__))
HARNESS = """        processor 6502
AUDC0 = $15
AUDC1 = $16
AUDF0 = $17
AUDF1 = $18
AUDV0 = $19
AUDV1 = $1A
MUSRAM = $80
        seg code
        org $F000
Start:  jsr MusicInit
Loop:   jsr MusicTick
Back:   jmp Loop
DrvStart:
        include "%s"
DrvEnd:
        org $FFFC
        .word Start
        .word Start
"""


def build(driver, tmp):
    asm = os.path.join(tmp, driver + '.asm')
    open(asm, 'w').write(HARNESS % driver)
    out = os.path.join(tmp, driver)
    subprocess.run(['dasm', asm, '-I' + HERE, '-f3', '-o' + out + '.bin', '-s' + out + '.sym'],
                   check=True, stdout=subprocess.DEVNULL)
    sym = {}
    for line in open(out + '.sym'):
        p = line.split()
        if len(p) >= 2:
            try:
                sym[p[0]] = int(p[1], 16)
            except ValueError:
                pass
    m = MPU()
    for i, b in enumerate(open(out + '.bin', 'rb').read()):
        m.memory[0xF000 + i] = b
    m.pc = 0xF000
    return m, sym


def frames(m, sym, n):
    regs = []
    for _ in range(n):
        while True:
            m.step()
            if m.pc == sym['Back']:
                break
        regs.append(tuple(m.memory[a] for a in range(0x15, 0x1B)))
    return regs


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 6000
    with tempfile.TemporaryDirectory() as tmp:
        old, so = build('musicdrv.asm', tmp)
        new, sn = build('musicdrv_c.asm', tmp)
        print('musicdrv.asm   (driver + tune): %d bytes' % (so['DrvEnd'] - so['DrvStart']))
        print('musicdrv_c.asm (driver + tune): %d bytes' % (sn['DrvEnd'] - sn['DrvStart']))
        a, b = frames(old, so, n), frames(new, sn, n)
    bad = [i for i in range(n) if a[i] != b[i]]
    for i in bad[:5]:
        print('  frame %d: old %s new %s' % (i, a[i], b[i]))
    print('%d frames (%.0f s): %s' % (n, n / 60, 'identical' if not bad else '%d differ' % len(bad)))
    return not bad


if __name__ == '__main__':
    sys.exit(0 if main() else 1)
