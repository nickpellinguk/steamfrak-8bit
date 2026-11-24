#!/usr/bin/env python3
"""Read the Frak tunes from the BBC version's generated data (src/gen/music.asm, made by
tools/music.py from the Steam version's js/audio.js) and expand a tune's tracks into notes.

Pattern tokens (see tools/music.py): dd ssssss = semitone s (0-59) for dd (1-3) quarter beats;
00 ssssss + e ddddd = semitone s for d+1 quarter beats with pitch envelope e; s = 63 rest,
62 carry on; 61 (&3D) ends the pattern."""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, '..', '..', 'src', 'gen', 'music.asm')
END, EXTEND, REST = 61, 62, 63


def load():
    tables, cur = {}, None
    for line in open(SRC):
        line = line.split('\\')[0].strip()
        m = re.match(r'^\.(\w+)', line)
        if m:
            cur = m.group(1); tables[cur] = []
            continue
        if line.startswith('EQUB') and cur:
            for v in line[4:].split(','):
                v = v.strip()
                tables[cur].append(v if v.startswith(('LO(', 'HI(')) else int(v))
    return tables


def pattern(t, k):
    d, out, i = t['pat%d' % k], [], 0
    while True:
        b = d[i]; i += 1
        if b == END:
            return out
        dur, s = b >> 6, b & 63
        env = 0
        if dur == 0:
            e = d[i]; i += 1
            env, dur = e >> 5, (e & 31) + 1
        out.append((s, dur, env))


def tune(t, n):
    """Tune n (from 1): its tracks as dicts with the expanded note list (semitone or None, quarter beats)."""
    first, ntr = t['tune_first'][n], t['tune_ntracks'][n]
    tracks = []
    for k in range(first, first + ntr):
        order = t['order%d' % k]
        notes, pats = [], []
        for p in order:
            pn = pattern(t, p)
            notes += pn
            pats += [p] * len(pn)
        tracks.append(dict(index=k, ins=t['trk_ins'][k], chan=t['trk_chan'][k], loop=t['trk_loop'][k],
                           raised=t['trk_raised'][k], order=order, notes=notes, pats=pats))
    total = t['tune_total_lo'][n] + 256 * t['tune_total_hi'][n]
    intro = t['tune_intro_lo'][n] + 256 * t['tune_intro_hi'][n]
    k = t['tune_k_lo'][n] + 256 * t['tune_k_hi'][n]
    return dict(total=total, intro=intro, k=k, tracks=tracks)


if __name__ == '__main__':
    t = load()
    T = tune(t, 1)
    print('FRAK: %d quarter beats, intro %d, tempo k %d (65536/k = %.2f ticks per quarter beat at 50 Hz)' % (
        T['total'], T['intro'], T['k'], 65536 / T['k']))
    for tr in T['tracks']:
        ss = [s for s, d, e in tr['notes'] if s < 60]
        beats = sum(d for s, d, e in tr['notes'])
        print('track %d: ins %d chan %d raised %d loop %d  %d notes, %d quarter beats, semitones %s-%s, order %s' % (
            tr['index'], tr['ins'], tr['chan'], tr['raised'], tr['loop'], len(ss), beats,
            min(ss) if ss else '-', max(ss) if ss else '-', tr['order']))
        print('    first notes:', tr['notes'][:16])
