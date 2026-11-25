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
    def __init__(self, base, no_meanie=False):
        self.sym = {}
        for line in open(base + '.sym'):
            p = line.split()
            if len(p) >= 2:
                try:
                    self.sym[p[0]] = int(p[1], 16)
                except ValueError:
                    pass
        rom = open(base + '.bin', 'rb').read()
        # 4K banks; an 8K ROM is F8: reading $FFF8 / $FFF9 selects bank 0 / 1
        self.banks = [rom[i:i + 4096] for i in range(0, len(rom), 4096)]
        if len(self.banks) > 1:
            from py65.memory import ObservableMemory
            mem = ObservableMemory()
            self.m = MPU(memory=mem)

            def switch(addr):
                self.select(addr - 0xFFF8)
            mem.subscribe_to_read([0xFFF8, 0xFFF9], switch)
        else:
            self.m = MPU()
        self.select(len(self.banks) - 1)       # (power-on: any bank; the reset stub copes)
        self.m.pc = self.banks[-1][0xFFC] | self.banks[-1][0xFFD] << 8
        self.frames = 0
        self.frame(0)                       # start-up, then a frame of the front screen (fire up)
        self.frame(0)
        self.mode0 = self.m.memory[self.sym['Mode']]
        self.frame(0, True)                 # fire starts the game
        self.frame(0)
        self.mode1 = self.m.memory[self.sym['Mode']]
        self.yoyo1 = self.m.memory[self.sym['State']]
        if no_meanie:                       # (the Scrubbly on the floor already yoyoed away)
            self.m.memory[self.sym['Collected']] |= 4

    def select(self, n):
        mem = getattr(self.m.memory, '_subject', self.m.memory)
        mem[0xF000:0x10000] = list(self.banks[n])

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
    g = Game(os.path.join(outdir, 'level'), no_meanie=True)
    ok = True

    def expect(what, st, **want):
        nonlocal ok
        bad = {k: (st[k], v) for k, v in want.items() if (v(st[k]) if callable(v) else st[k] != v)}
        print('%-46s %s %s' % (what, st, 'ok' if not bad else 'FAIL %s' % bad))
        ok &= not bad

    expect('the front screen first, fire starts the game (no yoyo)', g.state(),
           x=lambda v: (g.mode0, g.mode1, g.yoyo1) != (0, 1, 0))
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
    expect('... sliding a pixel every fourth frame', st, x=33)
    st = g.run(8, U)
    expect('... to the ladder centre (x 31)', st, x=31)
    st = g.run(4, U)
    expect('climbs a row every other frame (17 frames: about 8 rows)', st, row=lambda r: r not in (74, 75, 76), state=2)
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
    # the case reported: from the middle-left ledge (row 60, x 16-47), a running jump right catches
    # the top-right ladder (x 61, rows 24-59) and slides to its centre (not to x 58, the ladder
    # below it in the same column)
    g = Game(os.path.join(outdir, 'level'))
    g.run(46, L)
    g.run(1, U)
    while g.state()['row'] > 59:
        g.run(1, U)
    expect('climb to the middle-left ledge', g.run(4, R), row=59, state=0)
    while g.state()['x'] < 40:
        g.run(1, R)
    g.run(1, R | U)
    for _ in range(80):
        if g.run(1, R | U)['state'] == 2:
            break
    st = g.state()
    expect('running jump right catches the top-right ladder', st, state=2)
    expect('... and slides to its centre (x 61)', g.run(40), x=61, state=2)
    # Frak's ladders stop above the platform below: down off the bottom drops onto it
    g = Game(os.path.join(outdir, 'level'))
    states = [g.run(1, U)['state'] for _ in range(6)]
    expect('up from the floor under it: jumps (no ladder at the feet)', {**g.state(), 'state': states[0]}, state=1)
    expect('... and catches its bottom on the way up', g.run(20, U), state=2)
    trace = [g.run(1, D) for _ in range(60)]
    air = [t['row'] for t in trace if t['state'] == 1]
    expect('down off its bottom (row 81): in the air for rows 81-83', {**g.state(), 'air': air[:1] + air[-1:]}, air=[81, 83])
    expect('... and lands on the floor', g.state(), state=0, row=83, dead=0)
    # the yoyo: fire throws it the way he faces, out while held (to 40 px), back on release
    g = Game(os.path.join(outdir, 'level'), no_meanie=True)
    g.run(40, R)
    x0 = g.state()['x']
    yo = lambda: {**g.state(), 'len': g.m.memory[g.sym['YoLen']], 'yox': g.m.memory[g.sym['YoX']]}
    g.run(1, 0, True)
    expect('fire: throws the yoyo', yo(), state=3)
    g.run(30, R, True)
    expect('held: out at 0.65 px a frame, and he stands still', yo(), x=x0, len=lambda v: v not in (19, 20))
    peak = max((g.run(1, 0, True), yo())[1]['len'] for _ in range(40))
    expect('held: goes out to 40 px at most', {**yo(), 'len': peak}, len=40)
    g.run(1, 0, True)
    st = yo()
    expect('... then comes back by itself', st, len=lambda v: v >= 40)
    g.run(80, 0, True)
    expect('back in his hand: standing (fire still held)', yo(), state=0)
    expect('fire still held: no new throw', g.run(20, 0, True), state=0)
    g.run(1)
    g.run(1, L)
    g.run(1, 0, True)
    g.run(10, 0, True)
    expect('released, then fire facing left: out to the left', yo(), state=3, yox=lambda v: v >= g.state()['x'])
    g.run(3)
    expect('released early: comes back', yo(), len=lambda v: not v < 7)
    expect('... and he can walk again', g.run(40, R), state=0, x=lambda v: v <= x0)
    # items (Collected bits): gem x34 = 1, gem x88 = 2, Scrubbly x94 (a meanie) = 4, key x118 = 8
    g = Game(os.path.join(outdir, 'level'))
    col = lambda: {**g.state(), 'coll': g.m.memory[g.sym['Collected']], 'runx': list(g.m.memory[g.sym['RunX']:g.sym['RunX'] + 5])}
    st = col()
    died = False
    for _ in range(120):
        g.run(1, R)
        died |= g.died
        if died:
            break
    expect('walking right into the Scrubbly (x 94): he dies', {**g.state(), 'died': int(died)}, died=1, x=lambda v: not 86 <= v <= 90)
    expect('... it is still there', col(), coll=0)
    g.run(100)                                     # (restarted at x 57)
    g.run(20, R)                                   # x 67, facing right
    for _ in range(60):
        g.run(1, 0, True)
        if col()['coll']:
            break
    st2 = col()
    expect('the yoyo reaches it: the Scrubbly is gone', st2, coll=4, state=3, dead=0)
    expect('... its runs use their empty datasets', st2, runx=lambda r: r == st['runx'])
    expect('... and the yoyo comes back', g.run(40), state=0)
    expect('now he walks past where it was', g.dies(80, R), died=0, x=lambda v: v <= 100)
    # gems and keys
    g = Game(os.path.join(outdir, 'level'))
    g.run(46, L)
    g.run(200, U)
    expect('climbing to the top-left ledge collects its gem (x 34)', col(), coll=1, row=20)
    g.m.memory[g.sym['TX']] = 135                 # (onto the right ledge, x 112-143 at row 45: the key's,
    g.m.memory[g.sym['TRow']] = 44                # facing left, the key at x 118 between him and the edge)
    g.m.memory[g.sym['Facing']] = 8
    g.run(2)
    g.run(1, 0, True)
    g.run(60, 0, True)
    expect('the yoyo over the key: no effect on it', col(), coll=1, row=44)
    g.run(60)
    for _ in range(40):
        g.run(1, L)
    expect('walking into the key collects it', col(), coll=1 | 8)
    # the last key completes the level: a pause with the clock stopped, then the level again (for
    # now) with everything back and the time so far its checkpoint
    tm = lambda: (g.m.memory[g.sym['TMin']], g.m.memory[g.sym['TSec']], g.m.memory[g.sym['TFr']])
    won = g.m.memory[g.sym['Won']]
    t0 = tm()
    g.run(10)
    expect('the last key: the level-complete pause, clock stopped',
           {**col(), 'won': won, 'clock': int(tm() == t0)}, won=lambda v: v == 0, clock=1)
    g.run(90)
    ck = (g.m.memory[g.sym['CkMin']], g.m.memory[g.sym['CkSec']])
    expect('... then the level again: items back, at the start', col(), coll=0, x=s0['x'], row=83)
    expect('... the time when it was reached is the checkpoint', {**g.state(), 'ck': ck}, ck=t0[:2])
    # death sets the clock back to the checkpoint
    g = Game(os.path.join(outdir, 'level'))
    g.run(200)                                     # (3 s or so on the clock)
    g.m.memory[g.sym['CkSec']] = 2                 # (as if this level was reached at 0:02)
    t1 = tm()
    g.dies(200, R)                                 # off the floor's end, and the restart
    expect('a death: the clock goes back to the checkpoint (0:02)',
           {**g.state(), 'clock': tm()[:2], 'was': t1[:2]}, clock=lambda v: v[0] != 0 or not 2 <= v[1] <= 4)
    print('all ok' if ok else 'SOME FAILED')
    return ok


if __name__ == '__main__':
    sys.exit(0 if main() else 1)
