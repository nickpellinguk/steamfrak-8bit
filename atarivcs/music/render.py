#!/usr/bin/env python3
"""
Listen to the music driver without a 2600: run the assembled test ROM's MusicInit and MusicTick
(once per frame) on a 6502 emulator (py65), log its writes to the TIA's audio registers, and
synthesise the sound from them with a model of the TIA's two sound generators.

    python3 atarivcs/music/render.py [SECONDS] [OUT.wav] [--only=0|1]

--only=0 plays the bass channel alone, --only=1 the lead alone.

Needs musictest.bin and musictest.sym (dasm musictest.asm -f3 -omusictest.bin -smusictest.sym).

TIA model: the audio clock runs at 31399.5 Hz (two per scanline, 524 per 262-line frame). Each
channel's frequency divider counts AUDF+1 audio clocks and then steps its waveform: AUDC 4/5 a
square wave (divide by 2), 12/13 divide by 6 (3 high, 3 low), 6/10 divide by 31 (18 high, 13 low),
1 the 4-bit polynomial (15 steps), 0/11 always high (silent). Output = bit x AUDV.
"""
import os
import sys
import wave
from array import array

from py65.devices.mpu6502 import MPU
from py65.memory import ObservableMemory

HERE = os.path.dirname(os.path.abspath(__file__))
TIA_HZ = 3579545 / 114.0
CLOCKS_PER_FRAME = 524
AUD = {0x15: ('C', 0), 0x16: ('C', 1), 0x17: ('F', 0), 0x18: ('F', 1), 0x19: ('V', 0), 0x1A: ('V', 1)}
POLY4 = [1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0]
WAVE = {4: [1, 0], 5: [1, 0], 12: [1, 1, 1, 0, 0, 0], 13: [1, 1, 1, 0, 0, 0],
        6: [1] * 18 + [0] * 13, 10: [1] * 18 + [0] * 13, 1: POLY4, 0: [1], 11: [1]}


def symbols():
    out = {}
    for line in open(os.path.join(HERE, 'musictest.sym')):
        f = line.split()
        if len(f) >= 2:
            try:
                out[f[0]] = int(f[1], 16)
            except ValueError:
                pass
    return out


def run(frames):
    """The driver's audio register values at the end of each frame."""
    sym = symbols()
    mem = ObservableMemory()
    rom = open(os.path.join(HERE, 'musictest.bin'), 'rb').read()
    for i, b in enumerate(rom):
        mem[0xF000 + i] = b
    regs = {'C': [0, 0], 'F': [0, 0], 'V': [0, 0]}

    def write(addr, value):
        k, ch = AUD[addr]
        regs[k][ch] = value
    mem.subscribe_to_write(list(AUD), write)
    mpu = MPU(memory=mem)

    def call(addr):
        mpu.sp = 0xFD                                # as if called: RTS pulls $FFEF and goes to $FFF0
        mem[0x01FE], mem[0x01FF] = 0xEF, 0xFF
        mpu.pc = addr
        steps = 0
        while mpu.pc != 0xFFF0:
            mpu.step()
            steps += 1
            assert steps < 20000, 'driver did not return'
        return mpu.processorCycles
    call(sym['MusicInit'])
    log, worst = [], 0
    for _ in range(frames):
        c0 = mpu.processorCycles
        call(sym['MusicTick'])
        worst = max(worst, mpu.processorCycles - c0)
        log.append(tuple(regs['C']) + tuple(regs['F']) + tuple(regs['V']))
    return log, worst


def synth(log, only=None):
    out = array('h')
    phase, div = [0, 0], [0, 0]
    hp, last = 0.0, 0.0
    for c0, c1, f0, f1, v0, v1 in log:
        C, F, V = (c0 & 15, c1 & 15), (f0 & 31, f1 & 31), (v0 & 15, v1 & 15)
        for _ in range(CLOCKS_PER_FRAME):
            s = 0.0
            for ch in (0, 1):
                w = WAVE.get(C[ch], [1])
                div[ch] += 1
                if div[ch] > F[ch]:
                    div[ch] = 0
                    phase[ch] = (phase[ch] + 1) % len(w)
                if only is None or ch == only:
                    s += w[phase[ch] % len(w)] * V[ch] / 15.0
            hp = 0.995 * (hp + s - last)           # remove the DC level
            last = s
            out.append(int(max(-1, min(1, hp * 0.45)) * 32767))
    return out


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    only = next((int(a.split('=')[1]) for a in sys.argv if a.startswith('--only=')), None)
    secs = float(args[0]) if args else 95
    path = args[1] if len(args) > 1 else os.path.join(HERE, 'out', 'frak_theme_2600.wav')
    frames = int(secs * 60)
    log, worst = run(frames)
    notes = [sum(1 for i in range(1, len(log)) if log[i][2 + ch] != log[i - 1][2 + ch] or
                 (log[i][4 + ch] > log[i - 1][4 + ch])) for ch in (0, 1)]
    print('%d frames; MusicTick takes at most %d cycles (%.1f scanlines)' % (frames, worst, worst / 76))
    print('pitch changes or attacks: bass %d, lead %d' % tuple(notes))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(int(round(TIA_HZ)))
        w.writeframes(synth(log, only).tobytes())
    print('wrote', path)
