#!/usr/bin/env python3
"""Convert the Steam version's music and sound effects for the BBC Master's sound chip.

The Steam (and HTML5) version synthesises its tunes from BBC Micro-style note strings and
ENVELOPE parameters (js/audio.js); this reads them from there and writes src/gen/music_main.asm
(constants, instruments and the pitch and loudness tables, in main RAM) and src/gen/music.asm
(the tunes and pitch envelopes, in bank 5) for the player, src/sound.asm.

    music.py STEAMFRAK_DIR GEN_DIR

The sound effects are samples in the Steam version (js/data/sounds.js); here each is a note
on one of the synthesiser's voices, its pitch, envelope and loudness taken from the sample.

Tunes are kept as patterns (the Steam version's sub-tracks) and, for each track, the order
they're played in. A pattern is a list of tokens:
    dd ssssss          dd = 1-3: a note of semitone s (0-59) lasting dd quarter beats
                       (s = 63: a rest, 62: carry on with the note that's playing)
    00 ssssss, e ddddd the same, lasting d + 1 quarter beats (1-32), with pitch envelope e
    &3D                the end of the pattern
In a drum track the "semitone" is the drum (0-4: drum, snare, open and closed hi-hat, cymbal).
"""
import base64
import io
import json
import math
import os
import re
import sys
import wave
from array import array

SN_CLOCK = 4000000
BASE_HZ = 100.0             # the Steam version's square wave: one cycle in 0.01s at pitch 0
TICK_HZ = 50                # the player's rate (the Steam version stepped at 60Hz)
MAX_TRACKS = 7
TONE_SFX_CHANNEL = 2        # (sound effects take over this tone channel, or the noise channel)
END, EXTEND, REST = 61, 62, 63

TUNES = [  # (our name, the Steam version's MUSIC_ constant); 0 is silence
    ('FRAK', 'MUSIC_FRAKTHEME'), ('WEED', 'MUSIC_ALITTLEBAGOFWEED'), ('MAN', 'MUSIC_THEMANWHOONCEWASI'),
    ('VICTORY', 'MUSIC_VICTORYTHEME'), ('INTRO', 'MUSIC_INTROSCREEN'), ('SELECT', 'MUSIC_SELECTSCREEN'),
    ('LEVELS', 'MUSIC_LEVELSCREEN'),
]
DRUM_VOICES = ['DRUM', 'SNARE', 'HIHAT_OPEN', 'HIHAT_CLOSED', 'CYMBAL']
NOISE_RATE = {'sfxBeebNoise4': 0, 'sfxBeebNoise5': 1, 'sfxBeebNoise6': 2}     # BBC SOUND 0, pitch 4-6

# The sound effects: (name, sample, noise rate or None for a tone, semitone, pitch envelope
# (offsets in 1/8 semitones, one per tick; the last is held), attack ticks, decay ticks, length)
SFX = [
    ('CHING', 'sfxChing', None, 26, [2 * i for i in range(25)], 3, 27, 30),
    ('SQUEAL', 'sfxSqueal', None, 34, [-3 + 25 * i // 7 for i in range(8)] + [22 - 25 * i // 7 for i in range(8)], 7, 8, 16),
    ('DAGGER', 'sfxDaggerHit', 1, 0, [0], 0, 8, 8),
    ('POP', 'sfxPop', 2, 0, [0], 0, 3, 3),
    ('THUD', 'sfxThud', 2, 0, [0], 0, 2, 2),
]


def gml_round(v):
    r = math.floor(v + 0.5)
    return r - 1 if abs(v % 1) == 0.5 and r % 2 else r


def js_eval(expr, consts):
    expr = re.sub(r'[A-Z_][A-Z_0-9]*', lambda m: str(consts[m.group(0)]), expr)
    return eval(expr, {'__builtins__': {}}, {'true': True, 'false': False})


def parse_audio(src):
    consts = {}
    for line in re.findall(r'^const ([A-Z_][A-Z_0-9]* = -?\d+(?:, [A-Z_][A-Z_0-9]* = -?\d+)*);', src, re.M):
        for part in line.split(','):
            k, v = part.split('=')
            consts[k.strip()] = int(v)
    consts.update(true=1, false=0)
    pitchenvs = {}
    for name, args in re.findall(r'M\.pitchenvs\[(\w+)\] = MakePitchEnv\(([^)]*)\)', src):
        a = [x.strip() for x in args.split(',')]
        pitchenvs[consts[name]] = dict(zip(['doRepeat', 'o1', 'r1', 'd1', 'o2', 'r2', 'd2', 'o3', 'r3', 'd3'],
                                           [a[0] == 'true'] + [float(eval(x, {'__builtins__': {}})) for x in a[1:]]))
    sounds = {}
    for name, sfx, args in re.findall(r"S\[(\w+)\] = MakeEnvelope\((sq|'\w+'), ([^)]*)\)", src):
        a = [float(eval(x, {'__builtins__': {}})) for x in args.split(',')]
        sounds[name] = dict(zip(['volume', 'octave', 'step', 'aa', 'ad', 'as', 'ar', 'ala', 'ald'], a),
                            sfx='sfxPureSquare' if sfx == 'sq' else sfx.strip("'"))
    parts = {}
    for name, body in re.findall(r'M\.(\w+) = \[(.*?)\];', src, re.S):
        items = []
        for m in re.finditer(r"N\((\w+),\s*((?:'[^']*'\s*\+?\s*)+)\)|undefined", body):
            if m.group(1):
                items.append(notes_to_array(m.group(1), ''.join(re.findall(r"'([^']*)'", m.group(2))), consts))
            else:
                items.append(None)
        parts[name] = items
    tunes = {}
    start = src.index('function StartMusic')
    for case in src[start:src.index('M.tracks = T;', start)].split('case ')[1:]:
        name = case.split(':')[0].strip()
        t = {'tempo': 100, 'cpb': 4, 'intro': 0, 'tracks': []}
        if re.search(r'tempo = (\d+)', case):
            t['tempo'] = int(re.search(r'tempo = (\d+)', case).group(1))
        if re.search(r'clicksPerBeat = (\d+)', case):
            t['cpb'] = int(re.search(r'clicksPerBeat = (\d+)', case).group(1))
        t['total'] = js_eval(re.search(r'totalBeats = ([^;]*);', case).group(1), consts)
        if re.search(r'introBeats = ([^;]*);', case):
            t['intro'] = js_eval(re.search(r'introBeats = ([^;]*);', case).group(1), consts)
        t['tracks'] = re.findall(r"TrackSetup\(M\.(\w+), \w+, '(\w+)'\)", case)
        tunes[name] = t
    return consts, pitchenvs, sounds, parts, tunes


def notes_to_array(voice, s, consts):
    """The Steam version's NotesToArray: (pitch, voice, duration, envelope) for each note"""
    s = s + ' '
    pitch_of = {'-': 0, '+': 1, 'C': 2, 'D': 4, 'E': 6, 'F': 7, 'G': 9, 'A': 11, 'B': 13,
                'c': 14, 'd': 16, 'e': 18, 'f': 19, 'g': 21, 'a': 23, 'b': 25}
    env_of = {'^': 1, '?': 2, '!': 3, '@': 4, '~': 5, '*': 6, '%': 7}
    out, j, slen = [], 0, len(s) - 1
    while j < slen:
        ch = s[j]; j += 1
        pitch = pitch_of.get(ch, -1)
        if s[j] == '#': pitch += 1; j += 1
        if s[j] == 'b': pitch -= 1; j += 1
        duration = 0
        while j < slen and s[j].isdigit():
            duration = duration * 10 + int(s[j]); j += 1
        env = 0
        if s[j] in env_of: env = env_of[s[j]]; j += 1
        v = voice
        if voice == 'DRUM' and pitch in (2, 4, 6, 7, 9):
            v = {2: 'DRUM', 4: 'SNARE', 6: 'HIHAT_OPEN', 7: 'HIHAT_CLOSED', 9: 'CYMBAL'}[pitch]
            pitch = 2
        while j < slen and s[j] == ' ': j += 1
        out.append((pitch, v, duration, env))
    return out


def sample_level(sounds_js, name, volume=1.0):
    """The loudest 20ms of a sample (RMS, 0-1), times its volume"""
    data = json.loads(sounds_js[sounds_js.index('{'):sounds_js.rindex('}') + 1])[name]
    w = wave.open(io.BytesIO(base64.b64decode(data['data'])))
    a = array('h', w.readframes(w.getnframes()))
    if w.getnchannels() == 2: a = a[::2]
    seg = max(1, min(len(a), w.getframerate() // 50))
    best = max(sum(x * x for x in a[i:i + seg]) / seg for i in range(0, max(1, len(a) - seg + 1), seg // 2 or 1))
    return math.sqrt(best) / 32768 * volume * data['volume']


def pitch_env_table(pe):
    """Offsets (1/8 semitones) at 50Hz for a note with pitch envelope pe, and where it loops"""
    web = []
    state, start, off = 1, 0, pe['o1']
    for tick in range(720):
        if tick > 0:
            t = tick - start
            if state == 1:
                if t < pe['d1']: off = pe['o1'] + gml_round(pe['r1'] * t)
                else: state, start, off = 2, tick, pe['o2']
            elif state == 2:
                if t < pe['d2']: off = pe['o2'] + gml_round(pe['r2'] * t)
                else:
                    if pe['d3'] > 0: state, off = 3, pe['o3']
                    else: state, off = 1, pe['o1']
                    start = tick
            elif state == 3:
                if t < pe['d3']: off = pe['o3'] + gml_round(pe['r3'] * t)
                elif pe['doRepeat']: state, start, off = 1, tick, pe['o1']
                else: state, off = 0, 0
            else:
                off = 0
        web.append(int(off))
    if not pe['doRepeat']:
        seq = [web[n * 60 // TICK_HZ] for n in range(600)]
        n = len(seq)
        while n > 1 and seq[n - 1] == seq[n - 2]: n -= 1
        return seq[:n], n - 1
    # a repeating one: one period, from where it starts repeating, squeezed to 50Hz
    for loop in range(0, 60):
        for period in range(1, 60):
            if all(web[i] == web[i + period] for i in range(loop, 600)):
                head = [web[n * 60 // TICK_HZ] for n in range(loop * TICK_HZ // 60)]
                cycle = [web[loop + n * period // max(1, round(period * TICK_HZ / 60))]
                         for n in range(max(1, round(period * TICK_HZ / 60)))]
                return head + cycle, len(head)
    raise SystemExit('pitch envelope does not repeat')


def att_for(level):
    """The sound chip's attenuation (2dB steps, 15 = off) for a linear level 0-1"""
    if level <= 0: return 15
    return max(0, min(15, int(round(-20 * math.log10(level) / 2))))


def asm_bytes(label, values):
    out = ['.%s' % label] if label else []
    for i in range(0, len(values), 16):
        out.append('    EQUB ' + ', '.join(str(v) for v in values[i:i + 16]))
    if not values: out.append('    \\ (none)')
    return '\n'.join(out)


def main():
    web, gen = sys.argv[1], sys.argv[2]
    src = open(os.path.join(web, 'js/audio.js')).read()
    sounds_js = open(os.path.join(web, 'js/data/sounds.js')).read()
    consts, pitchenvs, sounds, parts, tunes = parse_audio(src)

    # Instruments: the tone ones used, then the drum kit, then the sound effects
    used = []
    for _, mname in TUNES:
        for part, _ in tunes[mname]['tracks']:
            v = next(n[1] for p in parts[part] if p for n in p)
            if v not in used and v not in DRUM_VOICES: used.append(v)
    ins_names = used + DRUM_VOICES + ['SFX_' + s[0] for s in SFX]
    drum_base = len(used)
    # Loudness. The Steam version's noise samples are quiet and its drums turned up to make up
    # for it, so its drums end up about 20dB louder than its tunes; on the sound chip's one
    # scale of 16 levels that would leave the tunes barely audible. So: each tone instrument by
    # its volume against the loudest, the drums likewise (2 levels down), and the sound effects
    # by how loud their samples are, against the loudest
    tone_vol = max(sounds[n]['volume'] for n in used)
    drum_vol = max(sounds[n]['volume'] for n in DRUM_VOICES)
    level = {n: sounds[n]['volume'] / tone_vol for n in used}
    level.update({n: sounds[n]['volume'] / drum_vol * 10 ** (-4 / 20) for n in DRUM_VOICES})
    sfx_level = {s[0]: sample_level(sounds_js, s[1]) for s in SFX}
    level.update({'SFX_' + n: v / max(sfx_level.values()) for n, v in sfx_level.items()})
    loudest = 1.0

    ins = []        # (attack, ala, decay, ald, sustain, release (amplitude units a tick, 8.8), att, noise)
    for name in used + DRUM_VOICES:
        snd = sounds[name]
        per_tick = 100.0 / TICK_HZ           # (BBC envelopes count centiseconds)
        ins.append((snd['aa'] / snd['step'] * per_tick, int(snd['ala']), -snd['ad'] / snd['step'] * per_tick,
                    int(snd['ald']), -snd['as'] / snd['step'] * per_tick, -snd['ar'] * per_tick,
                    att_for(level[name] / loudest),
                    0 if snd['sfx'] == 'sfxPureSquare' else 0xE4 | NOISE_RATE[snd['sfx']]))
    for name, sample, noise, semi, env, attack, decay, length in SFX:
        ins.append((127.0 / max(1, attack) if attack else 127.0, 127, 0, 127, 127.0 / decay, 127.0 / decay,
                    att_for(level['SFX_' + name] / loudest), 0 if noise is None else 0xE4 | noise))

    # Pitch envelopes: the Steam version's 8, then one for each sound effect
    envs = [pitch_env_table(pitchenvs[i]) for i in range(8)]
    sfx_env = []
    for s in SFX:
        sfx_env.append(len(envs))
        envs.append((s[4], len(s[4]) - 1))
    env_data, env_start, env_end, env_loop = [], [], [], []
    for seq, loop in envs:
        env_start.append(len(env_data)); env_loop.append(len(env_data) + loop)
        env_data += [v & 0xFF for v in seq]
        env_end.append(len(env_data))
    assert len(env_data) < 256

    # Patterns
    patterns, pattern_id = [], {}

    def pattern(part, index, tail_rest):
        key = (part, index, tail_rest)
        if key in pattern_id: return pattern_id[key]
        notes = parts[part][index] if index < len(parts[part]) and parts[part][index] else []
        drums = parts[part] and next(n[1] for p in parts[part] if p for n in p) in DRUM_VOICES
        octave = 0 if drums else int(sounds[next(n[1] for p in parts[part] if p for n in p)]['octave'])
        out, length = [], 0
        for k, (pitch, voice, dur, env) in enumerate(notes):
            if dur == 0:
                # (a note of no length stops the track until the tune restarts: rest instead)
                rest = sum(n[2] for n in notes[k:])
                assert pitch <= 0 and tail_rest, (part, index)
                while rest > 0:
                    d = min(rest, 32); out += [REST, d - 1] if d > 3 else [d << 6 | REST]; rest -= d; length += d
                break
            if pitch == 1: s = EXTEND
            elif pitch <= 0: s, env = REST, 0
            elif drums: s = DRUM_VOICES.index(voice)
            else:
                s = octave * 12 + pitch - 2
                assert 0 <= s < 60, (part, index, s)
            length += dur
            while dur > 0:
                d = min(dur, 32)
                if 1 <= d <= 3 and env == 0: out.append(d << 6 | s)
                else: out += [s, (d - 1) | env << 5]
                dur -= d
                if s != REST: s, env = EXTEND, 0      # (the rest of a long note)
        out.append(END)
        pattern_id[key] = len(patterns)
        patterns.append((out, length))
        return pattern_id[key]

    tune_rows, track_rows, orders = [], [], []
    for name, mname in TUNES:
        t = tunes[mname]
        tpq = math.ceil(60 * 60 / (t['tempo'] * t['cpb']))
        total, intro = t['total'] * t['cpb'], t['intro'] * t['cpb']
        first = len(track_rows)
        sounding = []
        for part, idx in t['tracks']:
            voice = next(n[1] for p in parts[part] if p for n in p)
            stalled = any(n[2] == 0 for p in parts[part] if p for n in p)
            ids = [pattern(part, int(c, 36), stalled) for c in idx]
            ids = [i for i in ids if patterns[i][1] > 0]
            pos, loop = 0, None
            for k, i in enumerate(ids):
                if pos == intro and loop is None: loop = k
                pos += patterns[i][1]
            assert pos == total, (name, part, pos, total)
            assert loop is not None, (name, part)
            # when each quarter beat sounds (for sharing out the sound chip's three tone channels)
            on = [False] * (total + 4)
            q = 0
            for i in ids:
                toks = patterns[i][0]; k = 0
                while toks[k] != END:
                    b = toks[k]; k += 1
                    if b >> 6: d, s = b >> 6, b & 63
                    else: s, d = b, (toks[k] & 31) + 1; k += 1
                    if s != REST:
                        for qq in range(q, min(q + d + 1, total)): on[qq] = True
                    q += d
            sounding.append(on)
            drums = voice in DRUM_VOICES
            track_rows.append({'ins': 255 if drums else used.index(voice), 'chan': 3 if drums else None,
                               'order': len(orders), 'loop': loop, 'on': on})
            orders.append(ids)
        # tone channels: the first track gets channel 0, the rest whichever clashes least
        chans = [[], [], []]
        for r in track_rows[first:]:
            if r['chan'] == 3: continue
            def clash(c): return sum(sum(a and b for a, b in zip(r['on'], o['on'])) for o in chans[c])
            c = min(range(3), key=lambda c: (clash(c), c == TONE_SFX_CHANNEL, c))
            r['chan'] = c; chans[c].append(r)
        k16 = int(round(65536 * 60 / (TICK_HZ * tpq)))
        tune_rows.append((k16, total, intro, len(t['tracks']), first))
        assert len(t['tracks']) <= MAX_TRACKS

    # SN76489 dividers for one octave of 1/8 semitones from BASE_HZ (shifted right for higher octaves)
    ntab = [int(round(SN_CLOCK / 32 / (BASE_HZ * 2 ** (r / 96.0)))) for r in range(96)]
    amptab = [att_for(2 * k / 127.0) for k in range(64)]

    def w16(v): v = min(65535, int(round(v * 256))); return v & 0xFF, v >> 8
    out = ['\\ Music and sound effects - GENERATED by tools/music.py, do not edit', '']
    out += ['NUM_TUNES = %d' % (len(TUNES) + 1), 'MAX_TRACKS = %d' % MAX_TRACKS,
            'TONE_SFX_CHANNEL = %d' % TONE_SFX_CHANNEL, 'DRUM_INS = %d' % drum_base,
            'NUM_SFX = %d' % len(SFX), 'PAT_END = %d' % END, 'PAT_EXTEND = %d' % EXTEND, 'PAT_REST = %d' % REST]
    out += ['TUNE_%s = %d' % (n, i + 1) for i, (n, _) in enumerate(TUNES)]
    out += ['SFX_%s = %d' % (s[0], i) for i, s in enumerate(SFX)]
    out.append('')
    main = out          # (constants and the tables the player reads most go in main RAM)
    main.append('\\ instruments: %s' % ', '.join(ins_names))
    for k, f in enumerate(['atk', 'ala', 'dec', 'ald', 'sus', 'rel', 'att', 'noise']):
        if f in ('ala', 'ald', 'att', 'noise'):
            out.append(asm_bytes('ins_' + f, [int(i[k]) for i in ins]))
        else:
            out.append(asm_bytes('ins_%s_lo' % f, [w16(i[k])[0] for i in ins]))
            out.append(asm_bytes('ins_%s_hi' % f, [w16(i[k])[1] for i in ins]))
    out.append(asm_bytes('ntab_lo', [n & 0xFF for n in ntab]))
    out.append(asm_bytes('ntab_hi', [n >> 8 for n in ntab]))
    out.append(asm_bytes('amptab', amptab))
    open(os.path.join(gen, 'music_main.asm'), 'w').write('\n'.join(main) + '\n')
    out = ['\\ Music and sound effects (the bank 5 part) - GENERATED by tools/music.py, do not edit', '']
    out.append(asm_bytes('env_start', env_start))
    out.append(asm_bytes('env_end', env_end))
    out.append(asm_bytes('env_loop', env_loop))
    out.append(asm_bytes('env_data', env_data))
    out.append('\\ tunes (from 1): tempo (65536 / ticks per quarter beat), length and intro (quarter beats), tracks')
    for k, f in enumerate(['k', 'total', 'intro']):
        out.append(asm_bytes('tune_%s_lo' % f, [0] + [r[k] & 0xFF for r in tune_rows]))
        out.append(asm_bytes('tune_%s_hi' % f, [0] + [r[k] >> 8 for r in tune_rows]))
    out.append(asm_bytes('tune_ntracks', [0] + [r[3] for r in tune_rows]))
    out.append(asm_bytes('tune_first', [0] + [r[4] for r in tune_rows]))
    out.append('\\ tracks: instrument (255: the drum kit), channel (3: noise), order list, where it loops')
    out.append(asm_bytes('trk_ins', [r['ins'] for r in track_rows]))
    out.append(asm_bytes('trk_chan', [r['chan'] for r in track_rows]))
    out.append(asm_bytes('trk_order_lo', ['LO(order%d)' % r['order'] for r in track_rows]))
    out.append(asm_bytes('trk_order_hi', ['HI(order%d)' % r['order'] for r in track_rows]))
    out.append(asm_bytes('trk_loop', [r['loop'] for r in track_rows]))
    out.append('\\ sound effects: instrument, semitone, pitch envelope, length (ticks)')
    out.append(asm_bytes('sfx_ins', [drum_base + len(DRUM_VOICES) + i for i in range(len(SFX))]))
    out.append(asm_bytes('sfx_semi', [s[3] for s in SFX]))
    out.append(asm_bytes('sfx_env', sfx_env))
    out.append(asm_bytes('sfx_len', [s[7] for s in SFX]))
    out.append(asm_bytes('pat_lo', ['LO(pat%d)' % i for i in range(len(patterns))]))
    out.append(asm_bytes('pat_hi', ['HI(pat%d)' % i for i in range(len(patterns))]))
    for i, ids in enumerate(orders):
        out.append(asm_bytes('order%d' % i, ids))
    for i, (toks, _) in enumerate(patterns):
        out.append(asm_bytes('pat%d' % i, toks))
    open(os.path.join(gen, 'music.asm'), 'w').write('\n'.join(out) + '\n')
    size = sum(len(p[0]) for p in patterns) + sum(len(o) for o in orders)
    print('Music: %d tunes, %d tracks, %d patterns, %d bytes of tunes; %d instruments, %d sound effects'
          % (len(TUNES), len(track_rows), len(patterns), size, len(ins), len(SFX)))


if __name__ == '__main__':
    main()
