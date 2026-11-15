# checktrogg.py DIR LEVEL: each screen saved by tour.mjs against what it should show, colour for
# colour: the level (build/<level>_expect.png) at the scroll; each thing listed (Trogg, then
# balloons and daggers) as the program's record says it's drawn: its outline in the characters
# (software) or on a player, its infill on players (and Trogg's on missiles 0 and 1 too); players
# in front of the playfield, P0/M0 first; a set character pixel shows its colour's luminance 0
# (COLPF1) in the hue of whatever is under it (PF2, or a player). The record: a frame's VBI comes
# after its picture, so the picture shows the frame before's (pvi) when that VBI showed a new
# frame ("fresh"), else still the one shown (shi). Every pixel of the 320 x 208 play area.
import sys, os, json, glob
from collections import Counter
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); B = os.path.join(HERE, '..', 'build')
d, lv = sys.argv[1], sys.argv[2]
exp = Image.open(os.path.join(B, f'{lv}_expect.png')).load()
graphics = json.load(open(os.path.join(B, 'sprites.json')))['graphics']
L = {}
for l in open(os.path.join(B, 'trogg8x4.lbl')):
    f = l.split()
    if len(f) >= 3 and f[1] == '=':
        v = f[2]
        try: L[f[0]] = int(v[1:], 16) if v.startswith('$') else int(v)
        except ValueError: pass
X0, Y0, BG, OUT = 32, 24, 0x9a, 0x90
YEL, MAG, BLK = L['COL_YEL'], L['COL_MAG'], L['COL_BLK']
bad_shots = 0; levels = Counter(); partial = 0; most = 0; shifts = set()
for scr in sorted(glob.glob(os.path.join(d, '*.scr'))):
    s = open(scr, 'rb').read(); m = open(scr[:-4] + '.mem', 'rb').read()
    r = L['OBJS'] + m[L['pvi' if m[L['fresh']] else 'shi']]
    n, sx = m[r + 57], m[r + 56]
    most = max(most, n)
    chars = [[exp[2 * sx + x, y] < 128 for x in range(320)] for y in range(208)]
    pl = [[None] * 320 for _ in range(208)]       # (priority, colour) of the player in front
    desc = []
    for i in range(n):
        g = m[r + i]; fr = graphics[g]
        x = (m[r + 8 + i] | m[r + 16 + i] << 8) - (65536 if m[r + 16 + i] & 0x80 else 0)
        top = m[r + 24 + i] - 32; lvl, pa, pb = m[r + 32 + i], m[r + 40 + i], m[r + 48 + i]
        sxp = x - 2 * sx; shifts.add(x % 8)
        kind = fr['name']; levels[(kind if i else 'TROGG', lvl)] += 1
        desc.append(f'{kind}@{x},{top} L{lvl} P{pa if pa < 4 else "-"}{pb if pb < 4 else "-"}')
        if sxp < 0 or sxp + fr['w'] > 320 or top < 0 or top + fr['h'] > 208: partial += 1
        if lvl >= 1:                               # its outline in the characters
            for gy, row in enumerate(fr['grid']):
                y = top + gy
                if 0 <= y < 208:
                    for gx, c in enumerate(row):
                        xx = sxp + gx
                        if 0 <= xx < 320 and c != 'T': chars[y][xx] = c == 'S'
        p = fr['players']
        def put(prio, colour, data, off, bits, shift):
            for gy, v in enumerate(data):
                y = top + gy
                if not 0 <= y < 208: continue
                for b in range(bits):
                    if v >> (shift + bits - 1 - b) & 1:
                        for k in (0, 1):
                            xx = sxp + 2 * (off + b) + k
                            if 0 <= xx < 320 and (pl[y][xx] is None or pl[y][xx][0] > prio): pl[y][xx] = (prio, colour)
        if pa < 4: put(pa, YEL if i == 0 else BLK, p['a'], p['ax'], 8, 0)
        if pb < 4: put(pb, MAG, p['b'], p['bx'], 8, 0)
        if i == 0 and lvl == 1:                     # Trogg's missiles: M0 (bits 0-1), M1 (bits 2-3)
            put(0, YEL, p['m'], p['max'], 2, 0)
            put(1, MAG, p['m'], p['mbx'], 2, 2)
    bad = 0
    for y in range(208):
        for x in range(320):
            q = pl[y][x]
            want = ((q[1] & 0xf0) if q else OUT) if chars[y][x] else (q[1] if q else BG)
            bad += s[(Y0 + y) * 384 + X0 + x] != want
    if bad:
        bad_shots += 1
        print(f'{os.path.basename(scr)}: {bad} pixels differ; scroll {sx}; ' + ', '.join(desc))
n = len(glob.glob(os.path.join(d, '*.scr')))
drops = m[L['drops']] | m[L['drops'] + 1] << 8
print(f'{n} screens, {n - bad_shots} exact; frames not made in time: {drops}; most things on a screen {most}, '
      f'partly off the screen {partial} times; shifts {sorted(shifts)}')
print('drawn (thing, 0 hardware / 1 software outline + hardware infill / 2 software): ' + ', '.join(f'{k}/{l} {v}' for (k, l), v in sorted(levels.items())))
sys.exit(1 if bad_shots else 0)
