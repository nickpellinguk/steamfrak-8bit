#!/usr/bin/env python3
"""
The Frak main theme for the 2600's two sound channels: the bass (looping all through) on channel 0
and one channel for everything else on channel 1; no drums.

    python3 atarivcs/music/build_music.py

Reads the tune from src/gen/music.asm (frakmusic.py) and writes atarivcs/music/frakmusic.inc for
the driver (musicdrv.asm), plus a tuning report.

  * Bass: track 0, whose four 32-beat patterns repeat through the tune.
  * Lead: tracks 2-6 merged. Each mostly rests outside its own section; where they overlap, a new
    note in a later track wins, and when the playing note ends a track still sounding takes over.
  * Timing: a quarter beat is 0.1333 s in the original (6.67 ticks at 50 Hz): 8 frames at 60 Hz.
  * Pitch: semitone 0 is 100 Hz (the Steam version's square wave). The TIA has a 5-bit divider
    (AUDF) under a few waveforms (AUDC); for each note the closest pitch is chosen from the allowed
    waveforms, and the whole tune is transposed (and each channel moved by octaves) to minimise
    the total error in cents, weighted by how often each note is played.
  * Data: per channel, patterns of 2-byte notes (code, length in frames) and an order list; the
    lead is split into 32-beat blocks so repeated sections are stored once. Codes: 0-60 note
    (index into the channel's AUDC/AUDF tables), 61 tie (carry on, no new attack), 62 end of
    pattern, 63 rest.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import frakmusic  # noqa: E402

TIA_HZ = 3579545 / 114.0           # NTSC audio clock (two per scanline): 31399.5 Hz
FRAMES_PER_Q = 8
BLOCK = 32                          # quarter beats per lead pattern
TIE, END, REST = 61, 62, 63
WAVES = {                           # AUDC: (divisor, name)
    4: (2, 'square, high'), 12: (6, 'square, low'), 6: (31, 'div 31 (buzzy square)'), 1: (15, '4-bit poly (buzz)'),
}
BASS_WAVES = (12, 6)
LEAD_WAVES = (4, 12)


def freq(audc, audf):
    return TIA_HZ / WAVES[audc][0] / (audf + 1)


def note_hz(s):
    return 100.0 * 2 ** (s / 12.0)


def best(hz, waves):
    c = min(((abs(1200 * math.log2(freq(w, f) / hz)), w, f) for w in waves for f in range(32)))
    return c[1], c[2], 1200 * math.log2(freq(c[1], c[2]) / hz)


def grid(track, n):
    """Per quarter beat: (semitone or None, onset)."""
    out, cur = [], None
    for s, d, e in track['notes']:
        for k in range(d):
            if s == frakmusic.REST:
                cur = None; out.append((None, False))
            elif s == frakmusic.EXTEND:
                out.append((cur, False))
            else:
                cur = s; out.append((s, k == 0))
    return out[:n]


def merge(grids, n):
    """One channel from several: a new note in a later track wins; when the playing note ends a
    track still sounding takes over (as a new note)."""
    out, cur = [], None
    for i in range(n):
        ons = [k for k, g in enumerate(grids) if g[i][1]]
        if ons:
            cur = ons[-1]; out.append((grids[cur][i][0], True))
        elif cur is not None and grids[cur][i][0] is not None:
            out.append((grids[cur][i][0], False))
        else:
            live = [k for k, g in enumerate(grids) if g[i][0] is not None]
            if live:
                cur = live[-1]; out.append((grids[cur][i][0], True))
            else:
                cur = None; out.append((None, False))
    return out


def events(steps):
    """(semitone or None, quarter beats, attack?) runs; a block boundary inside a note becomes a tie."""
    ev = []
    for i, (s, on) in enumerate(steps):
        if ev and not on and ev[-1][0] == s and i % BLOCK:
            ev[-1][1] += 1
        else:
            ev.append([s, 1, on or s is None])
    return ev


def blocks(steps, n):
    return [events(steps[i:i + BLOCK]) for i in range(0, n, BLOCK)]


def main():
    t = frakmusic.load()
    T = frakmusic.tune(t, 1)
    n, intro = T['total'], T['intro']
    tr = T['tracks']
    bass_steps = grid(tr[0], n)
    assert all(bass_steps[i] == bass_steps[i % 128] for i in range(n)), 'bass does not loop every 128 beats'
    lead_steps = merge([grid(x, n) for x in tr[2:7]], n)

    bass_blocks = blocks(bass_steps, 128)
    lead_blocks = blocks(lead_steps, n)

    # transposition: one for the whole tune, plus an octave move per channel
    def usage(bl):
        u = {}
        for b in bl:
            for s, d, a in b:
                if s is not None:
                    u[s] = u.get(s, 0) + d
        return u
    bu, lu = usage(bass_blocks), usage(lead_blocks)
    best_cfg = None
    for tp in range(-12, 13):
        for bo in (-12, 0, 12):
            for lo in (-12, 0, 12):
                err = sum(w * abs(best(note_hz(s + tp + bo), BASS_WAVES)[2]) for s, w in bu.items()) + \
                      sum(w * abs(best(note_hz(s + tp + lo), LEAD_WAVES)[2]) for s, w in lu.items())
                if best_cfg is None or err < best_cfg[0]:
                    best_cfg = (err, tp, bo, lo)
    _, tp, bo, lo = best_cfg

    def tables(u, shift, waves):
        notes = sorted(u)
        idx = {s: i for i, s in enumerate(notes)}
        rows = [(s, s + shift) + best(note_hz(s + shift), waves) for s in notes]
        return idx, rows
    bidx, brows = tables(bu, tp + bo, BASS_WAVES)
    lidx, lrows = tables(lu, tp + lo, LEAD_WAVES)
    assert len(brows) <= 60 and len(lrows) <= 60

    def encode(b, idx):
        out = []
        for s, d, attack in b:
            code = REST if s is None else (idx[s] if attack else TIE)
            fr = d * FRAMES_PER_Q
            while fr > 0:
                f = min(fr, 248)
                out += [code, f]
                fr -= f
                if code != REST:
                    code = TIE
        return out + [END]

    def patterns(bl, idx):
        pats, order = [], []
        for b in bl:
            e = encode(b, idx)
            if e not in pats:
                pats.append(e)
            order.append(pats.index(e))
        return pats, order
    bpats, border = patterns(bass_blocks, bidx)
    lpats, lorder = patterns(lead_blocks, lidx)
    lloop = intro // BLOCK                           # after the end, back to the end of the intro

    o = ['; GENERATED by atarivcs/music/build_music.py from src/gen/music.asm: the Frak theme',
         '; transposed %+d semitones; bass %+d, lead %+d octaves' % (tp, bo // 12, lo // 12)]
    for name, rows in (('Bass', brows), ('Lead', lrows)):
        o.append('%sC: .byte %s' % (name, ','.join(str(r[2]) for r in rows)))
        o.append('%sF: .byte %s' % (name, ','.join(str(r[3]) for r in rows)))
    for name, pats, order, loop in (('Bass', bpats, border, 0), ('Lead', lpats, lorder, lloop)):
        o.append('%sOrder: .byte %s,$FF' % (name, ','.join(map(str, order))))
        o.append('%sLoop = %d' % (name, loop))
        o.append('%sPatLo: .byte %s' % (name, ','.join('<%sPat%d' % (name, i) for i in range(len(pats)))))
        o.append('%sPatHi: .byte %s' % (name, ','.join('>%sPat%d' % (name, i) for i in range(len(pats)))))
        for i, p in enumerate(pats):
            o.append('%sPat%d: .byte %s' % (name, i, ','.join(map(str, p))))
    path = os.path.join(HERE, 'frakmusic.inc')
    open(path, 'w').write('\n'.join(o) + '\n')

    size = sum(len(p) for p in bpats + lpats) + len(border) + len(lorder) + 2 + 4 * (len(bpats) + len(lpats)) // 2 + 2 * (len(brows) + len(lrows))
    print('transposition %+d semitones, bass octave %+d, lead octave %+d' % (tp, bo // 12, lo // 12))
    print('bass: %d patterns (order %s), lead: %d patterns of %d (order %s, loops to %d)' % (
        len(bpats), border, len(lpats), len(lead_blocks), lorder, lloop))
    print('music data about %d bytes' % size)
    for name, rows, u in (('bass', brows, bu), ('lead', lrows, lu)):
        print('%s tuning (semitone: AUDC/AUDF, Hz, cents off, quarter beats played):' % name)
        for s, s2, w, f, c in rows:
            print('   %2d -> %2d: AUDC %2d AUDF %2d  %7.1f Hz (want %7.1f)  %+5.0f c  %s' % (
                s, s2, w, f, freq(w, f), note_hz(s2), c, u[s]))
        werr = sum(abs(c) * u[s] for s, s2, w, f, c in rows) / sum(u.values())
        print('   average error %.0f cents (weighted by use)' % werr)


if __name__ == '__main__':
    main()
