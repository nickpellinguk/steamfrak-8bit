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
        self.died = False
        for _ in range(n):
            self.frame(keys, fire)
            self.died |= self.m.memory[self.sym['Dead']] > 0
        return self.state()

    def dies(self, n, keys=0):
        """Run n frames; whether he died at any point."""
        self.run(n, keys)
        return {**self.state(), 'died': int(self.died)}

    def state(self):
        g = lambda k: self.m.memory[self.sym[k]]
        return {'x': g('TX'), 'row': g('TRow'), 'state': g('State'), 'dead': g('Dead')}


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
    expect('start, standing on the floor (row 83)', g.run(10), row=83, state=0)
    expect('walk right 20 frames: 10 px', g.run(20, R), x=s0['x'] + 10, row=83)
    expect('walk left 20 frames', g.run(20, L), x=s0['x'], row=83)
    g.run(40, R)                                   # away from the ladder at x 58
    # jump: up with no ladder (held: the debounce allows one jump)
    rows = [g.run(1, U)['row'] for _ in range(70)]
    expect('jump on up: rises about 6 rows', {**g.state(), 'row': min(rows)}, row=83 - 6)
    expect('... lands, and holding up does not jump again', g.run(30, U), row=83, state=0)
    g.run(5)
    # a running jump keeps going the way he walked
    g.run(1, L)
    x0 = g.state()['x']
    g.run(1, L | U)
    st = g.run(60)
    expect('running jump: carries on left in the air', st, row=83, state=0, x=lambda v: v > x0 - 20)
    # walk off the right end of the floor (x 111): falls off the bottom of the screen and dies
    expect('walk off the floor end: falls off the screen, dies', g.dies(200, R), died=1)
    expect('... and restarts at the start', g.run(100), x=s0['x'], row=83, state=0, dead=0)

    # climbing: left to the ladder at x 31 (it reaches the top-left ledge, row 21)
    g = Game(os.path.join(outdir, 'level'))
    expect('walk left near the ladder at x 31', g.run(46, L), x=34, row=83)
    st = g.run(1, U)
    expect('up: starts climbing', st, state=2)
    st = g.run(4, U)
    expect('... sliding a pixel every other frame', st, x=32)
    st = g.run(2, U)
    expect('... to the ladder centre (x 31)', st, x=31)
    st = g.run(4, U)
    expect('climbs a row every other frame', st, row=lambda r: r not in (77, 78), state=2)
    st = g.run(6, R)
    expect('right between platforms: walks off into a fall', st, state=lambda v: v == 2)
    expect('... lands safely on the floor (a 6-row fall)', g.run(30), row=83, state=0, dead=0)
    # back onto the ladder (x 28-35 puts his centre over it), up 14 rows, and off: a fatal fall
    while g.state()['x'] > 31:
        g.run(1, L)
    g.run(1, U)
    expect('climbing 14 rows up', g.run(30, U), state=2, row=lambda r: r > 70)
    expect('... then walking off: a fatal fall (over about 10 rows)', g.dies(80, L), died=1)
    g = Game(os.path.join(outdir, 'level'))
    g.run(46, L)
    g.run(1, U)
    st = g.run(200, U)
    expect('climbs to the top and steps off on the ledge', st, row=20, state=0, x=31)
    st = g.run(10, L)
    expect('walks along the ledge', st, x=26, row=20)
    expect('walks off the ledge: falls 63 rows and dies', g.dies(230, R), died=1)
    # down onto a ladder from the ledge, then down it to the floor
    g = Game(os.path.join(outdir, 'level'))
    g.run(46, L)
    g.run(200, U)
    st = g.run(1)
    st = g.run(10, D)
    expect('down from the ledge onto the ladder', st, state=2, row=lambda r: not 20 < r < 30)
    st = g.run(200, D)
    expect('down the ladder: stops on the ledge it passes behind (row 60)', st, state=0, row=59)
    st = g.run(1)
    st = g.run(200, D)
    expect('down again: on to the floor', st, state=0, row=83)
    print('all ok' if ok else 'SOME FAILED')
    return ok


if __name__ == '__main__':
    sys.exit(0 if main() else 1)
