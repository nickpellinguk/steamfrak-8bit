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
  * Pitch slides: the original's pitch envelopes 1-3 (a scoop up from a semitone below, over
    26, 18 or 8 ticks at 50 Hz) become per-frame sequences of the nearest TIA pitches (the two
    square waves, AUDC 4 and 12, sound alike and fall on different pitches, so together they give
    finer steps); the vibratos (envelopes 4-7, 1/8 to 1/4 semitone) are finer than any TIA step
    and are left out.
  * Tuning: the transposition is searched in 1/8-semitone steps (nothing else fixes the key);
    errors are weighted by how long each note plays, flat errors count 1.5x (they sound worse)
    and the bass counts 1.5x (it never stops).
  * Data: per channel, patterns of 2-byte notes (code, length in frames) and an order list; the
    lead is split into 32-beat blocks so repeated sections are stored once. Codes: 0-47 a pitch
    (index into the channel's AUDC/AUDF table), 48-60 a slide (index into SlideStart: a list of
    pitches, one per frame, ended by $FF, after which the last is held), 61 tie (carry on, no new
    attack), 62 end of pattern, 63 rest.
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
BASS_WAVE_SETS = ((12, 4),)        # one timbre all through: the two square waves (the buzzy 4-bit poly,
                                   # AUDC 1, made C and B flat stand out, and its pitch sounded off)
DITHER = next((float(a.split('=')[1]) for a in sys.argv if a.startswith('--dither=')), None)
DITHER_LEN = 8                     # a dithered note: a repeating pattern of this many frames
COLLIDE_CENTS = 100                # two different notes on one pitch: counted as this error, for as
                                   # long as the rarer of the two plays
BASS_NOTE_WEIGHT = {10: 4, 12: 4, 17: 4, 19: 4}   # notes heard as out of tune (B flat, C, F, G): extra weight
LEAD_WAVES = (4, 12)
BASS_OCTAVES = (0,)                 # both channels stay in the original's register
LEAD_OCTAVES = (0,)
# the lead's parts an octave up where they lie low (the slides work better higher) and tune better
# there; the high parts stay put (an octave up they fall where the TIA's steps are coarse)
TRACK_OCTAVE = {2: 0, 3: 12, 4: 0, 5: 0, 6: 0}    # slide guitar, ukulele, male voice, violin, female voice
PATTERN_OCTAVE = {(2, 13): 12}     # (track, pattern): extra shift for its plain notes (not its slides):
                                   # the slide guitar's C B flat A A flat G F sharp G phrase, an octave up
CUT_SHORT = {2: (8, 4)}            # track: (long note, cut): the slide guitar's held notes of 8+ quarter
                                   # beats stop 4 quarter beats (one beat) sooner (they were too loud
                                   # for too long)
GRACE_TRACKS = {2}                 # the slide guitar: a slide becomes a short note a semitone below
GRACE_FRAMES = 16                  # (a quaver: 2 quarter beats of 8 frames), then the note; never more
                                   # than half the note
FIXED_TRANSPOSE = 4.625            # pinned: the bass at this transposition was judged acceptable
FLAT_WEIGHT, BASS_WEIGHT = 1.5, 1.5
SLIDE_ENVS = (1, 2, 3)
SLIDE_BASE = 48


def freq(audc, audf):
    return TIA_HZ / WAVES[audc][0] / (audf + 1)


def note_hz(s):
    return 100.0 * 2 ** (s / 12.0)


def best(hz, waves):
    c = min(((abs(1200 * math.log2(freq(w, f) / hz)), w, f) for w in waves for f in range(32)))
    return c[1], c[2], 1200 * math.log2(freq(c[1], c[2]) / hz)


def cost(cents):
    return abs(cents) * (FLAT_WEIGHT if cents < 0 else 1.0)


def env_frames(t, e, frames):
    """Pitch envelope e as offsets in semitones for each 60 Hz frame (non-repeating ones hold
    their last value)."""
    sg = lambda v: v - 256 if v > 127 else v
    seq = [sg(v) for v in t['env_data'][t['env_start'][e]:t['env_end'][e]]]
    return [seq[min(len(seq) - 1, f * 50 // 60)] / 8.0 for f in range(frames)]


def grid(track, n, shift=0, grace=False):
    """Per quarter beat: (semitone or None, onset, slide envelope)."""
    out, cur = [], None
    for (s, d, e), pat in zip(track['notes'], track['pats']):
        extra = PATTERN_OCTAVE.get((track['index'], pat), 0) if not e else 0
        for k in range(d):
            if s == frakmusic.REST:
                cur = None; out.append((None, False, 0))
            elif s == frakmusic.EXTEND:
                out.append((cur, False, 0))
            else:
                env = e if k == 0 and e in SLIDE_ENVS else 0
                cur = s + shift + extra; out.append((cur, k == 0, 'grace' if env and grace else env))
    out = out[:n]
    if track['index'] in CUT_SHORT:
        long_, cut = CUT_SHORT[track['index']]
        i = 0
        while i < len(out):
            if out[i][1]:                       # an attack: how long is the note, ties included?
                j = i + 1
                while j < len(out) and not out[j][1] and out[j][0] == out[i][0]:
                    j += 1
                if j - i >= long_:
                    for k in range(j - cut, j):
                        out[k] = (None, False, 0)
                i = j
            else:
                i += 1
    return out


def merge(grids, n):
    """One channel from several: a new note in a later track wins; when the playing note ends a
    track still sounding takes over (as a new note)."""
    out, cur = [], None
    for i in range(n):
        ons = [k for k, g in enumerate(grids) if g[i][1]]
        if ons:
            cur = ons[-1]; out.append(grids[cur][i])
        elif cur is not None and grids[cur][i][0] is not None:
            out.append((grids[cur][i][0], False, 0))
        else:
            live = [k for k, g in enumerate(grids) if g[i][0] is not None]
            if live:
                cur = live[-1]; out.append((grids[cur][i][0], True, 0))
            else:
                cur = None; out.append((None, False, 0))
    return out


def events(steps):
    """(semitone or None, quarter beats, attack?) runs; a block boundary inside a note becomes a tie."""
    ev = []
    for i, (s, on, e) in enumerate(steps):
        if ev and not on and ev[-1][0] == s and i % BLOCK:
            ev[-1][1] += 1
        else:
            ev.append([s, 1, on or s is None, e])
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
    lead_steps = merge([grid(x, n, TRACK_OCTAVE.get(x['index'], 0), x['index'] in GRACE_TRACKS) for x in tr[2:7]], n)
    bass_blocks = blocks(bass_steps, 128)
    lead_blocks = blocks(lead_steps, n)

    def usage(bl):
        u = {}
        for b in bl:
            for s, d, a, e in b:
                if s is not None:
                    u[s] = u.get(s, 0) + d
        return u
    bu, lu = usage(bass_blocks), usage(lead_blocks)

    # tuning: a fractional transposition for the whole tune, plus an octave move per channel
    cache = {}

    def err(u, shift, waves, weight):
        tot, used = 0.0, {}
        for s, w in u.items():
            k = (s + shift, waves)
            if k not in cache:
                cache[k] = best(note_hz(s + shift), waves)
            pick = cache[k]
            tot += weight * w * cost(pick[2]) * (BASS_NOTE_WEIGHT.get(s, 1) if weight == BASS_WEIGHT else 1)
            used.setdefault(pick[:2], []).append(w)
        for ws in used.values():           # notes that share a pitch
            if len(ws) > 1:
                tot += weight * COLLIDE_CENTS * sum(sorted(ws)[:-1])
        return tot
    best_cfg = None
    for bw in BASS_WAVE_SETS:
        for tp8 in ([round(FIXED_TRANSPOSE * 8)] if FIXED_TRANSPOSE is not None else range(-96, 97)):
            tp = tp8 / 8.0
            for bo in BASS_OCTAVES:
                eb = err(bu, tp + bo, bw, BASS_WEIGHT)
                for lo in LEAD_OCTAVES:
                    e = eb + err(lu, tp + lo, LEAD_WAVES, 1.0)
                    if best_cfg is None or e < best_cfg[0]:
                        best_cfg = (e, tp, bo, lo, bw)
    _, tp, bo, lo, BASS_WAVES = best_cfg

    # pitch tables: every (AUDC, AUDF) a channel uses, for its notes and its slides' frames
    def build_channel(bl, shift, waves, dither=None):  # noqa: C901
        points, slides = [], []

        def point(hz):
            w, f, c = best(hz, waves)
            if (w, f) not in points:
                points.append((w, f))
            return points.index((w, f))
        note_pt = {}
        for b in bl:
            for s, d, a, e in b:
                if s is not None and s not in note_pt:
                    note_pt[s] = point(note_hz(s + shift))
        # pitch alternation: a held note further than `dither` cents from any TIA pitch alternates
        # between the two around it, frame by frame, in proportion (a looping pitch sequence)
        dith = {}
        if dither is not None:
            for s in sorted(note_pt):
                hz = note_hz(s + shift)
                if abs(best(hz, waves)[2]) <= dither:
                    continue
                lo_c = max(((w, f) for w in waves for f in range(32) if freq(w, f) <= hz), key=lambda p: freq(*p), default=None)
                hi_c = min(((w, f) for w in waves for f in range(32) if freq(w, f) >= hz), key=lambda p: freq(*p), default=None)
                if lo_c is None or hi_c is None:
                    continue
                a = math.log(hz / freq(*lo_c)) / math.log(freq(*hi_c) / freq(*lo_c))
                seq, acc = [], 0.0
                for _ in range(DITHER_LEN):
                    acc += a
                    if acc >= 0.5:
                        acc -= 1.0; seq.append(point(freq(*hi_c)))
                    else:
                        seq.append(point(freq(*lo_c)))
                seq.append('loop')
                if seq not in slides:
                    slides.append(seq)
                dith[s] = slides.index(seq)
        slide_id = {}
        flat = [ev for b in bl for ev in b]
        k = 0
        for b in bl:                       # each grace note's length: from its note's full held length
            for ev in b:                   # (ties, also across blocks, included)
                s, d, a, e = ev
                if a and s is not None and e == 'grace':
                    tot, j = d, k + 1
                    while j < len(flat) and not flat[j][2] and flat[j][0] == s:
                        tot += flat[j][1]; j += 1
                    g = min(GRACE_FRAMES, tot * FRAMES_PER_Q // 2)
                    ev[3] = ('grace', g)       # (events are lists: the length travels with the note)
                k += 1
        for b in bl:
            for s, d, a, e in b:
                if s is not None and a and isinstance(e, tuple) and (s, e, d) not in slide_id:
                    g = e[1]
                    seq = [point(note_hz(s + shift - 1))] * g + [point(note_hz(s + shift))]
                    if seq not in slides:
                        slides.append(seq)
                    slide_id[(s, e, d)] = slides.index(seq)
                elif s is not None and a and e and (s, e, d) not in slide_id:
                    frames = min(d * FRAMES_PER_Q, 30)
                    seq, acc = [], 0.0
                    for o in env_frames(t, e, frames):
                        hz = note_hz(s + shift + o)
                        lo_c = max(((w, f) for w in waves for f in range(32) if freq(w, f) <= hz), key=lambda p: freq(*p), default=None)
                        hi_c = min(((w, f) for w in waves for f in range(32) if freq(w, f) >= hz), key=lambda p: freq(*p), default=None)
                        if lo_c is None or hi_c is None or lo_c == hi_c or o == 0:
                            seq.append(point(hz)); acc = 0.0
                            continue
                        a = math.log(hz / freq(*lo_c)) / math.log(freq(*hi_c) / freq(*lo_c))   # 0 = lower, 1 = upper
                        acc += a
                        if acc >= 0.5:
                            acc -= 1.0; seq.append(point(freq(*hi_c)))
                        else:
                            seq.append(point(freq(*lo_c)))
                    target = point(note_hz(s + shift))
                    while len(seq) > 1 and seq[-1] == seq[-2] == target:
                        seq.pop()
                    if seq[-1] != target:
                        seq.append(target)               # the driver holds the last entry
                    if len(set(seq)) == 1:
                        slide_id[(s, e, d)] = None          # too fine to show: a plain note
                    else:
                        if seq not in slides:
                            slides.append(seq)
                        slide_id[(s, e, d)] = slides.index(seq)
        assert len(points) <= SLIDE_BASE and len(slides) <= 61 - SLIDE_BASE, (len(points), len(slides))
        assert sum(len(x) + 2 for x in slides) < 256, 'slides must fit in one indexed table'
        return points, note_pt, slides, slide_id, dith

    bpoints, bnote, bslides, bslide, bdith = build_channel(bass_blocks, tp + bo, BASS_WAVES, DITHER)
    lpoints, lnote, lslides, lslide, ldith = build_channel(lead_blocks, tp + lo, LEAD_WAVES)

    def encode(b, note_pt, slide_id, dith):
        out = []
        for s, d, attack, e in b:
            if s is None:
                code = REST
            elif not attack:
                code = TIE
            elif e and slide_id.get((s, e, d)) is not None:
                code = SLIDE_BASE + slide_id[(s, e, d)]
            elif s in dith:
                code = SLIDE_BASE + dith[s]
            else:
                code = note_pt[s]
            fr = d * FRAMES_PER_Q
            while fr > 0:
                f = min(fr, 248)
                out += [code, f]
                fr -= f
                if code != REST:
                    code = TIE
        return out + [END]

    def patterns(bl, note_pt, slide_id, dith):
        pats, order = [], []
        for b in bl:
            e = encode(b, note_pt, slide_id, dith)
            if e not in pats:
                pats.append(e)
            order.append(pats.index(e))
        return pats, order
    bpats, border = patterns(bass_blocks, bnote, bslide, bdith)
    lpats, lorder = patterns(lead_blocks, lnote, lslide, ldith)
    lloop = intro // BLOCK

    o = ['; GENERATED by atarivcs/music/build_music.py from src/gen/music.asm: the Frak theme',
         '; transposed %+.3f semitones; bass %+d, lead %+d octaves; bass waveforms %s' % (tp, bo // 12, lo // 12, BASS_WAVES)]
    for name, pts, slides in (('Bass', bpoints, bslides), ('Lead', lpoints, lslides)):
        o.append('%sC: .byte %s' % (name, ','.join(str(w) for w, f in pts)))
        o.append('%sF: .byte %s' % (name, ','.join(str(f) for w, f in pts)))
        if slides:
            o.append('%sSlide: .byte %s' % (name, ','.join('%s-%sSlides' % (lbl, name) for lbl in
                                                          ['%sSl%d' % (name, i) for i in range(len(slides))])))
            o.append('%sSlides:' % name)
            for i, sq in enumerate(slides):
                if sq[-1] == 'loop':           # $FE, then where to go back to
                    o.append('%sSl%d: .byte %s,$FE,%sSl%d-%sSlides' % (name, i, ','.join(map(str, sq[:-1])), name, i, name))
                else:
                    o.append('%sSl%d: .byte %s,$FF' % (name, i, ','.join(map(str, sq))))
        else:
            o.append('%sSlide:\n%sSlides: .byte $FF' % (name, name))
    for name, pats, order, loop in (('Bass', bpats, border, 0), ('Lead', lpats, lorder, lloop)):
        o.append('%sOrder: .byte %s,$FF' % (name, ','.join(map(str, order))))
        o.append('%sLoop = %d' % (name, loop))
        o.append('%sPatLo: .byte %s' % (name, ','.join('<%sPat%d' % (name, i) for i in range(len(pats)))))
        o.append('%sPatHi: .byte %s' % (name, ','.join('>%sPat%d' % (name, i) for i in range(len(pats)))))
        for i, p in enumerate(pats):
            o.append('%sPat%d: .byte %s' % (name, i, ','.join(map(str, p))))
    open(os.path.join(HERE, 'frakmusic.inc'), 'w').write('\n'.join(o) + '\n')

    size = sum(len(p) for p in bpats + lpats) + len(border) + len(lorder) + 2 + 2 * (len(bpats) + len(lpats)) + \
        2 * (len(bpoints) + len(lpoints)) + sum(len(x) + 2 for x in bslides + lslides)
    if bdith:
        print('bass notes played by pitch alternation (further than %g cents from a TIA pitch): %s' % (DITHER, sorted(bdith)))
    print('transposition %+.3f semitones, bass octave %+d, lead octave %+d, bass waveforms %s' % (tp, bo // 12, lo // 12, BASS_WAVES))
    print('bass: %d patterns, %d pitches; lead: %d patterns (order %s, loops to %d), %d pitches, %d slides' % (
        len(bpats), len(bpoints), len(lpats), lorder, lloop, len(lpoints), len(lslides)))
    print('music data about %d bytes' % size)
    for name, u, note_pt, pts in (('bass', bu, bnote, bpoints), ('lead', lu, lnote, lpoints)):
        shift = tp + (bo if name == 'bass' else lo)
        print('%s tuning (semitone: AUDC/AUDF, Hz, cents off, quarter beats played):' % name)
        tot = 0
        for s in sorted(u):
            w, f = pts[note_pt[s]]
            c = 1200 * math.log2(freq(w, f) / note_hz(s + shift))
            tot += abs(c) * u[s]
            print('   %2d: AUDC %2d AUDF %2d  %7.1f Hz (want %7.1f)  %+5.0f c  %s' % (
                s, w, f, freq(w, f), note_hz(s + shift), c, u[s]))
        print('   average error %.0f cents (weighted by use)' % (tot / sum(u.values())))
    for i, sq in enumerate(lslides):
        print('lead slide %d: %s' % (i, ' '.join('%d/%d' % lpoints[p] for p in sq)))


if __name__ == '__main__':
    main()
    import compact                      # the compact form the game uses (musicdrv_c.asm)
    compact.main()
