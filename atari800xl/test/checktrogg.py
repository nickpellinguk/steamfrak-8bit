# checktrogg.py DIR LEVEL: each screen saved by tour.mjs against what it should show, colour for
# colour: the level (build/<level>_expect.png) at the scroll; each thing listed (Trogg, then
# Scrubblies, balloons and daggers) as the program's record says it's drawn: its outline in the
# characters (software) or on players (Trogg's band by band), its infill on players (and Trogg's
# on missiles 0 and 1 too; a Scrubbly's on two, or on one double-width); players
# in front of the playfield, P0/M0 first; a set character pixel shows its colour's luminance 0
# (COLPF1) in the hue of whatever is under it (PF2, or a player). The record: a frame's VBI comes
# after its picture, so the picture shows the frame before's (pvi) when that VBI showed a new
# frame ("fresh"), else still the one shown (shi). The things are drawn in their order, Trogg last
# (on top), then the FRAK! bubble (its yellow on one quad-width player), the yoyo's string (from the record) just before the yoyo. Every pixel of the 320 x 240 play area.
import sys, os, json, glob
from collections import Counter
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); B = os.path.join(HERE, '..', 'build')
d, lv = sys.argv[1], sys.argv[2]
exp = Image.open(os.path.join(B, f'{lv}_expect.png')).load()
SP = json.load(open(os.path.join(B, 'sprites.json'))); graphics, FRAK = SP['graphics'], SP['frak']
L = {}
for l in open(os.path.join(B, 'trogg8x4.lbl')):
    f = l.split()
    if len(f) >= 3 and f[1] == '=':
        v = f[2]
        try: L[f[0]] = int(v[1:], 16) if v.startswith('$') else int(v)
        except ValueError: pass
X0, Y0 = 32, 0                                     # (the play area's place in the saved screen)
H, TOPL = 240, L['TOPL']
YEL, MAG, BLK = L['COL_YEL'], L['COL_MAG'], L['COL_BLK']
bad_shots = 0; levels = Counter(); partial = 0; most = 0; shifts = set()
SCR = json.load(open(os.path.join(B, f'{lv}_scrub.json')))
GR_SCRUB, GR_KEY = L['GR_N'], L['GR_N'] + 1
PK = json.load(open(os.path.join(B, f'{lv}_picks.json')))
BG = PK['bg']; OUT = BG & 0xf0                     # (the level type's background; a set pixel's luminance 0)
FONT = open(os.path.join(B, f'{lv}_font.bin'), 'rb').read()
def lvpix(gone):                                   # the level's pixels with the gems and keys gone
    px = {}                                        # (bits of gone) changed: {(x, y): set}
    for i, cs in enumerate(PK['cells']):
        if gone >> i & 1:
            for r, c, g, f in cs:
                for l in range(4):
                    b = FONT[g * 8 + (l if r % 2 else 4 + l)]
                    for x in range(8): px[(c * 8 + x, r * 4 + l)] = bool(b & 0x80 >> x)
    return px
for scr in sorted(glob.glob(os.path.join(d, '*.scr'))):
    s = open(scr, 'rb').read(); m = open(scr[:-4] + '.mem', 'rb').read()
    ri = m[L['pvi' if m[L['fresh']] else 'shi']]; rr = ri // 16       # the record the picture shows
    F = lambda name, i: m[L['OB_' + name] + ri + i]
    n, sx, hw = m[L['OB_N'] + rr], m[L['OB_SCR'] + rr], m[L['OB_HW'] + rr]
    most = max(most, n)
    gone = m[L['OB_PK'] + rr] | m[L['OB_PK'] + 3 + rr] << 8 | m[L['OB_PK'] + 6 + rr] << 16
    gp = lvpix(gone)
    chars = [[gp.get((2 * sx + x, y), exp[2 * sx + x, y] < 128) for x in range(320)] for y in range(H)]
    pl = [[None] * 320 for _ in range(H)]       # (priority, colour) of the player in front
    desc = []
    def put(prio, colour, data, x0, top, bits, shift, bw=2, lines=None):
        for gy, v in enumerate(data):
            y = top + gy
            if not 0 <= y < H or (lines and not lines(y)): continue
            for b in range(bits):
                if v >> (shift + bits - 1 - b) & 1:
                    for k in range(bw):
                        xx = x0 + bw * b + k
                        if 0 <= xx < 320 and (pl[y][xx] is None or pl[y][xx][0] > prio): pl[y][xx] = (prio, colour)
    rest = [i for i in range(1, n) if F('G', i) != L['GR_FRAK']]   # (in order, then Trogg on top, then
    for i in rest + [0] + [i for i in range(1, n) if i not in rest] if n else []:   # the FRAK! bubble: the BBC version's)
        g = F('G', i)
        if L['GR_YOYO0'] <= g <= L['GR_YOYO3'] and m[L['OB_SY'] + rr]:     # (the yoyo: its string first)
            s0 = m[L['OB_S0'] + rr] | m[L['OB_S0'] + 3 + rr] << 8; s1 = m[L['OB_S1'] + rr] | m[L['OB_S1'] + 3 + rr] << 8
            y = m[L['OB_SY'] + rr] - TOPL
            for xl in range(max(s0, 2 * sx), min(s1, 2 * sx + 319) + 1): chars[y][xl - 2 * sx] = True
            desc.append(f'STRING {s0}-{s1},{y}')
        x = (F('XL', i) | F('XH', i) << 8) - (65536 if F('XH', i) & 0x80 else 0)
        top = F('D', i) - TOPL; lvl, pa, pb = F('LV', i), F('PA', i), F('PB', i)
        sxp = x - 2 * sx
        if g == GR_SCRUB:                          # a Scrubbly's infill (counted when on the screen)
            if sxp + 32 > 0 and sxp < 320: levels[('SCRUBBLY' if sxp >= 0 and sxp + 32 <= 320 else 'SCRUBBLY partly off', lvl)] += 1
            desc.append(f'SCRUB@{x},{top} L{lvl}')
            if lvl == 0:
                put(pa, MAG, SCR['l'], sxp, top, 8, 0); put(pb, MAG, SCR['r'], sxp + 16, top, 8, 0)
            elif lvl == 1:
                put(pb, MAG, SCR['d'], sxp + SCR['dx'], top, 8, 0, bw=4)
            continue
        if g == GR_KEY:                            # a key's yellow (double width, or none)
            levels[('KEY', lvl)] += 1
            desc.append(f'KEY@{x},{top} L{lvl}')
            if lvl == 1: put(pb, YEL, PK['d'], sxp + PK['dx'], top, 8, 0, bw=4)
            continue
        fr = graphics[g]; shifts.add(x % 8)
        kind = fr['name']; levels[(kind if i else 'TROGG', lvl)] += 1
        desc.append(f'{kind}@{x},{top} L{lvl} P{pa if pa < 4 else "-"}{pb if pb < 4 else "-"}' + (f' hw{hw - TOPL}' if i == 0 and hw != 255 else ''))
        if sxp < 0 or sxp + fr['w'] > 320 or top < 0 or top + fr['h'] > H: partial += 1
        if i == 0: levels[('TROGG outline on players', 'from a band' if hw != 255 else 'no')] += 1
        if lvl >= 1:                               # its outline in the characters (Trogg's: rows
            for gy, row in enumerate(fr['grid']):  # starting above his outline's line)
                y = top + gy
                if 0 <= y < H and (i or 4 * ((y + TOPL) >> 2) < hw):
                    for gx, c in enumerate(row):
                        xx = sxp + gx
                        if 0 <= xx < 320 and c != 'T': chars[y][xx] = c == 'S'
        p = fr['players']
        if i == 0 and lvl == 1:                    # Trogg: infill (holed from his outline's line),
            o = fr['outline']                      # missiles, outline on P2 and P3
            above, below = (lambda y: y + TOPL < hw), (lambda y: y + TOPL >= hw)
            put(0, YEL, p['a'], sxp + 2 * p['ax'], top, 8, 0, lines=above); put(0, YEL, o['ah'], sxp + 2 * p['ax'], top, 8, 0, lines=below)
            put(1, MAG, p['b'], sxp + 2 * p['bx'], top, 8, 0, lines=above); put(1, MAG, o['bh'], sxp + 2 * p['bx'], top, 8, 0, lines=below)
            put(0, YEL, p['m'], sxp + 2 * p['max'], top, 2, 0, lines=above); put(0, YEL, o['mh'], sxp + 2 * p['max'], top, 2, 0, lines=below)
            put(1, MAG, p['m'], sxp + 2 * p['mbx'], top, 2, 2, lines=above); put(1, MAG, o['mh'], sxp + 2 * p['mbx'], top, 2, 2, lines=below)
            if hw != 255:
                put(2, BLK, o['l'], sxp, top, 8, 0, lines=below); put(3, BLK, o['r'], sxp + 16, top, 8, 0, lines=below)
            continue
        if g == L['GR_FRAK']:                      # the bubble's yellow: one quad-width player
            if pb < 4: put(pb, YEL, FRAK['y'], sxp + FRAK['x'], top, 8, 0, bw=8)
            continue
        if pa < 4: put(pa, BLK, p['a'], sxp, top, 8, 0)
        if pb < 4: put(pb, MAG, p['b'], sxp, top, 8, 0)
    bad = 0; wh = []
    for y in range(H):
        for x in range(320):
            q = pl[y][x]
            want = ((q[1] & 0xf0) if q else OUT) if chars[y][x] else (q[1] if q else BG)
            if s[(Y0 + y) * 384 + X0 + x] != want:
                bad += 1
                if os.environ.get('WHERE'): wh.append((x, y, s[(Y0 + y) * 384 + X0 + x], want))
    if bad:
        bad_shots += 1
        print(f'{os.path.basename(scr)}: {bad} pixels differ; scroll {sx}; ' + ', '.join(desc))
        if wh: print('  (x, y, shown, wanted):', wh[:6], '... x', min(w[0] for w in wh), '-', max(w[0] for w in wh), 'y', min(w[1] for w in wh), '-', max(w[1] for w in wh))
n = len(glob.glob(os.path.join(d, '*.scr')))
drops = m[L['drops']] | m[L['drops'] + 1] << 8
print(f'{n} screens, {n - bad_shots} exact; frames not made in time: {drops}; most things on a screen {most}, '
      f'partly off the screen {partial} times; shifts {sorted(shifts)}')
print('drawn (thing, 0 hardware / 1 software outline + hardware infill / 2 software; Scrubblies 0 two players / 1 one double-width / 2 none; keys 1 double-width / 2 none): ' + ', '.join(f'{k}/{l} {v}' for (k, l), v in sorted(levels.items())))
sys.exit(1 if bad_shots else 0)
