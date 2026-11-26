#!/usr/bin/env python3
"""
Renders the game's music (musicdrv_c.asm, the compact driver the ROM uses) to a WAV file: the driver
runs in py65, a MusicTick per frame, and its audio register writes drive a TIA model: the 31.4 kHz
audio clock (two ticks per scanline, 262 lines a frame), each channel's frequency divider (AUDF + 1),
then its waveform (AUDC 4/5: a pure tone, divide by 2; 12/13: divide by 6), at volume AUDV (0-15).
Resampled to 44.1 kHz.

    python3 atarivcs/music/render_wav.py [SECONDS] [OUT.wav]
"""
import os
import sys
import tempfile
import wave
import numpy as np
import equiv_test

TIA_HZ = 3579545 / 114          # the audio clock: two ticks per scanline
PER_FRAME = 262 * 2             # ticks per frame


def render(regs):
    out = np.zeros(len(regs) * PER_FRAME)
    div = [0, 0]                # the frequency dividers
    stage = [0, 0]              # the waveform's position (pure tone: 0-1; div 6: 0-5)
    k = 0
    for c0, c1, f0, f1, v0, v1 in regs:
        for ch, (c, f, v) in enumerate(((c0, f0, v0), (c1, f1, v1))):
            period = 2 if (c & 0x0F) in (4, 5) else 6 if (c & 0x0F) in (12, 13) else 2
            d, s = div[ch], stage[ch]
            buf = np.empty(PER_FRAME)
            for t in range(PER_FRAME):
                d += 1
                if d > f:
                    d = 0
                    s = (s + 1) % period
                buf[t] = v if s < period // 2 else 0
            div[ch], stage[ch] = d, s
            out[k:k + PER_FRAME] += buf
        k += PER_FRAME
    return out


def main():
    secs = float(sys.argv[1]) if len(sys.argv) > 1 else 100
    path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(equiv_test.HERE, 'frak_music.wav')
    with tempfile.TemporaryDirectory() as tmp:
        m, sym = equiv_test.build('musicdrv_c.asm', tmp)
        regs = equiv_test.frames(m, sym, int(secs * 60))
    raw = render(regs)
    raw -= raw.mean()                                   # (no DC offset)
    t_out = np.arange(int(len(raw) / TIA_HZ * 44100)) / 44100
    pcm = np.interp(t_out, np.arange(len(raw)) / TIA_HZ, raw) / 30 * 0.9
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(44100)
        w.writeframes((pcm * 32767).astype('<i2').tobytes())
    print('%s: %.0f s' % (path, len(pcm) / 44100))


if __name__ == '__main__':
    main()
