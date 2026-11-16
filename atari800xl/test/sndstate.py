# sndstate.py DIR [LBL]: the player's state (sound.asm) in a tour's memory dumps: the tune, the
# quarter beat, each POKEY channel's voice, divider and control as last written, and each voice's
# phase, attenuation and clock count. Checks the dividers written match the voices' pitches.
import glob, os, re, sys
d = sys.argv[1]; lbl = sys.argv[2] if len(sys.argv) > 2 else 'build/trogg8x4.lbl'
L = {}
for l in open(lbl):
    m = re.match(r'(\w+)\s*=\s*(\$[0-9a-fA-F]+|\d+)\s*$', l)
    if m: L.setdefault(m.group(1), int(m.group(2)[1:], 16) if m.group(2)[0] == '$' else int(m.group(2)))
NV = 9; bad = 0; tunes = set(); sounding = 0
for f in sorted(glob.glob(os.path.join(d, '*.mem'))):
    m = open(f, 'rb').read()
    g = lambda n, i=0: m[L[n] + i]
    own = [g('snd_owner', c) for c in range(3)]; nch = g('snd_nch')
    fl = [g('last_fl', c) for c in range(3)]; fh = g('last_fh'); ct = [g('last_c', c) for c in range(3)]
    tunes.add(g('snd_tune'))
    line = []
    for c in range(3):
        v = own[c]
        if v == 255: line.append(f'ch{c} -'); continue
        n = g('v_nl', v) | g('v_nh', v) << 8
        if c != nch:
            if c == 0: ok = (fl[0] | fh << 8) == (n - 7) & 0xffff
            else:
                q = (n + 14) // 28
                while q > 255: q >>= 1
                ok = fl[c] == q - 1
            bad += not ok
        sounding += (ct[c] & 15) > 0
        line.append(f'ch{c} v{v}{"N" if c == nch else ""} c${ct[c]:02x} f{fl[c] | (fh << 8 if c == 0 else 0)}')
    if f.endswith(('0010.mem', '0040.mem', '0070.mem')) or len(sys.argv) > 3:
        print(os.path.basename(f), 'tune', g('snd_tune'), 'qb', g('snd_qb') | g('snd_qb', 1) << 8, ' | '.join(line))
print(f'tunes seen {sorted(tunes)}; channels sounding (summed over dumps) {sounding}; dividers not matching their voices {bad}')
sys.exit(1 if bad else 0)
