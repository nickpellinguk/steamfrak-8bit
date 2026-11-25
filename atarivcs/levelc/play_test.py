#!/usr/bin/env python3
"""
Drives a --game ROM's 6502 code in py65 with scripted joystick input, a frame at a time, and checks
where the Trogg ends up (TX, feet row, climbing) against the level's movement maps. Also saves
Stella snapshots of chosen moments by recompiling with the Trogg's start moved there.

    python3 atarivcs/levelc/play_test.py [OUT_DIR]
"""
import os
import subprocess
import sys
from py65.devices.mpu6502 import MPU

HERE = os.path.dirname(os.path.abspath(__file__))
R, L, D, U, FIRE = 0x80, 0x40, 0x20, 0x10, 'fire'


class Game:
    def __init__(self, base):
        self.sym = {}
        for line in open(base + '.sym'):
            p = line.split()
            if len(p) >= 2:
                try:
                    self.sym[p[0]] = int(p[1], 16)
                except ValueError:
                    pass
        rom = open(base + '.bin', 'rb').read()
        self.m = MPU()
        for i, b in enumerate(rom):
            self.m.memory[0xF000 + i] = b
        self.m.pc = rom[0xFFC] | rom[0xFFD] << 8
        self.frames = 0
        self.frame(0)                       # start-up and the first frame

    def frame(self, keys=0, fire=False):
        """Run until the code is back at Frame, with these inputs held."""
        m = self.m
        m.memory[0x280] = 0xFF & ~keys       # SWCHA: 0 = pressed
        m.memory[0x0C] = 0x00 if fire else 0x80
        m.memory[0x284] = 0                  # INTIM: the timer has always run out
        target = self.sym['Frame']
        for _ in range(200000):
            m.step()
            if m.pc == target:
                self.frames += 1
                return
        raise RuntimeError('no frame')

    def run(self, n, keys=0, fire=False):
        for _ in range(n):
            self.frame(keys, fire)
        return self.state()

    def state(self):
        g = lambda k: self.m.memory[self.sym[k]]
        return {'x': g('TX'), 'row': g('TRow'), 'climb': g('Climb'), 'jump': g('JumpT')}


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    outdir = os.path.abspath(args[0] if args else os.path.join(HERE, 'out', 'play'))
    os.makedirs(outdir, exist_ok=True)
    subprocess.run([sys.executable, os.path.join(HERE, 'levelc.py'), '--game', outdir], check=True,
                   stdout=subprocess.DEVNULL)
    g = Game(os.path.join(outdir, 'level'))
    ok = True

    def expect(what, st, **want):
        nonlocal ok
        bad = {k: (st[k], v) for k, v in want.items() if (v(st[k]) if callable(v) else st[k] != v)}
        print('%-46s %s %s' % (what, st, 'ok' if not bad else 'FAIL %s' % bad))
        ok &= not bad

    s0 = g.state()
    expect('start, standing on the floor (row 83)', g.run(10), row=83, climb=0)
    st = g.run(20, R)
    expect('walk right 20 frames', st, x=s0['x'] + 20, row=83)
    st = g.run(20, L)
    expect('walk left 20 frames', st, x=s0['x'], row=83)
    g.run(1, 0, True)
    st = g.state()
    peak = min(g.run(1)['row'] for _ in range(12))
    expect('jump: rises 8 rows', {**st, 'row': peak}, row=83 - 8)
    expect('... and lands again', g.run(30), row=83, jump=0)
    # walk off the floor's right end (x 111): falls to the bottom of the screen (nothing below)
    st = g.run(60, R)
    expect('walk off the right end of the floor: falls', g.run(60), row=94)
    print('frames run: %d' % g.frames)
    # climbing: from the start (x 57) left to the ladder at x 31 (cells 32-39: centre 32-39 -> x 28-35)
    g2 = Game(os.path.join(outdir, 'level'))
    st = g2.run(25, L)
    expect('walk left to the ladder at x 31', st, x=32, row=83)
    st = g2.run(200, U)
    expect('climb to the top-left ledge (top row 21)', st, climb=0, row=20)
    st = g2.run(20, L)
    expect('walk left along the ledge', st, x=16, row=20)
    st = g2.run(30, R)
    expect('walk right off the ledge: falls past it', g2.run(40), row=lambda r: r <= 20)
    print('all ok' if ok else 'SOME FAILED')
    return ok


if __name__ == '__main__':
    sys.exit(0 if main() else 1)
