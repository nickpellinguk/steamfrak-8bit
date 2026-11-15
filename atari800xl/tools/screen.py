# screen.py [LEVEL]: a level's screen data for the 8x4 display, from the C64 build's picture of it
# (c64/build/<level>/chars.bin: "node c64/tools/level.mjs A_1 --out A_1" first), black pixels only.
#
# The display is pairs of 4-line rows: the first of a pair shows glyph lines 4-7 of its
# characters (a "bottoms" row), the second lines 0-3 (a "tops" row). So a character holds two
# glyphs: its tops glyph in bytes 0-3, its bottoms glyph in bytes 4-7, numbered independently.
# The C64's character row n is tops(n) then bottoms(n); the Atari's rows, top to bottom, are
#   bottoms(-1) tops(0) | bottoms(0) tops(1) | ... | bottoms(24) tops(25)
# (bottoms(-1) and tops(25) blank), 52 rows, 26 pairs. One character set for the whole level
# (A_1 needs 46 codes; more levels may need bands).
#
# Writes atari800xl/build/<level>_font.bin (1KB), <level>_map.bin (52 rows of 128 bytes: 4 bytes
# of blank, the level's columns, blank after: the scroll's LMS arithmetic wants the 4 in front),
# <level>.inc (NCOLS, NROWS) and <level>_expect.png (the picture the Atari should show, for checks).
import os, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
LV = sys.argv[1] if len(sys.argv) > 1 else 'A_1'
SRC = os.path.join(HERE, '..', '..', 'c64', 'build', LV, 'chars.bin')
OUT = os.path.join(HERE, '..', 'build')
H = 200
px = open(SRC, 'rb').read(); W = len(px) // H; NC = W // 8
STRIDE, PAD, NROWS = 128, 4, 52
assert PAD + NC <= STRIDE

def half(hr, c):                      # the C64's half row hr (2n tops, 2n+1 bottoms), column c: 4 bytes
    if hr < 0 or hr >= 2 * 25: return (0, 0, 0, 0)
    return tuple(sum(0x80 >> x for x in range(8) if px[(hr * 4 + l) * W + c * 8 + x] == 3) for l in range(4))

tops, bottoms = {(0, 0, 0, 0): 0}, {(0, 0, 0, 0): 0}
mp = bytearray(STRIDE * NROWS)
for r in range(NROWS):
    pair, second = divmod(r, 2)
    hr = 2 * pair if second else 2 * (pair - 1) + 1          # tops(pair), or bottoms(pair - 1)
    table = tops if second else bottoms
    for c in range(NC):
        g = half(hr, c)
        if g not in table: table[g] = len(table)
        mp[r * STRIDE + PAD + c] = table[g]
n = max(len(tops), len(bottoms))
assert n <= 128, f'{LV}: {len(tops)} tops and {len(bottoms)} bottoms glyphs: over 128 codes'
font = bytearray(1024)
for g, i in tops.items(): font[i * 8:i * 8 + 4] = bytes(g)
for g, i in bottoms.items(): font[i * 8 + 4:i * 8 + 8] = bytes(g)
os.makedirs(OUT, exist_ok=True)
open(os.path.join(OUT, f'{LV}_font.bin'), 'wb').write(font)
open(os.path.join(OUT, f'{LV}_map.bin'), 'wb').write(mp)
open(os.path.join(OUT, f'{LV}.inc'), 'w').write(f'NCOLS = {NC}\nNROWS = {NROWS}\nNCODES = {n}\n')
# what the Atari should show: every row through the font, the whole level's width
img = Image.new('L', (NC * 8, NROWS * 4), 255)
for r in range(NROWS):
    for c in range(NC):
        code = mp[r * STRIDE + PAD + c]
        for l in range(4):
            b = font[code * 8 + (l if r % 2 else 4 + l)]
            for x in range(8):
                if b & 0x80 >> x: img.putpixel((c * 8 + x, r * 4 + l), 0)
img.save(os.path.join(OUT, f'{LV}_expect.png'))
print(f'{LV}: {NC} columns, {len(tops)} tops glyphs, {len(bottoms)} bottoms glyphs: {n} codes')

# The Scrubblies' infill (their bodies, magenta), on hardware sprites: where the C64 shows its
# Scrubbly sprite's magenta (c64/build/<level>/charsspr.bin against chars.bin), fitted to two
# normal-width players side by side (8 two-pixel blocks each: exact for the C64's) and to one
# double-width player (8 four-pixel blocks), a block on where more of its visible (not black)
# pixels are magenta than aren't. Positions: level pixels, and the players' memory's line of the
# top (display line + 32: map line + 36). Poglets and Hooters (two colours) are for later.
import json as _json
SJ = os.path.join(HERE, '..', '..', 'c64', 'build', LV, 'scrub.json')
sc = _json.load(open(SJ)) if os.path.exists(SJ) else {'placed': [], 'mc': True}
spr = open(os.path.join(os.path.dirname(SRC), 'charsspr.bin'), 'rb').read()
inc = []
scr_json = {'n': 0}
if sc['placed'] and not sc['mc']:
    p0 = sc['placed'][0]; SX, SY = p0['sx'], p0['sy']
    g = [[('S' if px[(SY + y) * W + SX + x] == 3 else 'M' if spr[(SY + y) * W + SX + x] == 2 else 'T') for x in range(48)] for y in range(42)]
    rows = [y for y in range(42) if 'M' in g[y]]; y0, y1 = rows[0], rows[-1]
    def fitw(bw, nb):
        best = None
        for o in range(0, 16, 2):
            data, bad = [], 0
            for y in range(y0, y1 + 1):
                v = 0; on = set()
                for b in range(nb):
                    xs = [x for x in range(o + b * bw, o + b * bw + bw) if 0 <= x < 48]
                    if sum(g[y][x] == 'M' for x in xs) > sum(g[y][x] == 'T' for x in xs): v |= 1 << (nb - 1 - b); on.update(xs)
                bad += sum((g[y][x] == 'M') != (x in on) for x in range(48) if g[y][x] != 'S')
                data.append(v)
            if best is None or bad < best[0]: best = (bad, o, data)
        return best
    two, dbl = fitw(2, 16), fitw(4, 8)
    for s_ in sc['placed']: assert all(px[(s_['sy'] + y) * W + s_['sx'] + x] == px[(SY + y) * W + SX + x] for y in range(42) for x in range(48))
    inc += [f'SCR_N = {len(sc["placed"])}', f'SCR_H = {y1 - y0 + 1}',
            'scr_xl  .byte ' + ', '.join(str((p['sx'] + two[1]) & 255) for p in sc['placed']) + '     ; the two players\' left',
            'scr_xh  .byte ' + ', '.join(str((p['sx'] + two[1]) >> 8) for p in sc['placed']),
            'scr_pd  .byte ' + ', '.join(str(p['sy'] + y0 + 36) for p in sc['placed']),
            f'SCR_DX = {dbl[1] - two[1]}                  ; the double-width player\'s left, from theirs',
            'scr_l   .byte ' + ', '.join(str(v >> 8) for v in two[2]) + '     ; two players: left',
            'scr_r   .byte ' + ', '.join(str(v & 255) for v in two[2]) + '     ; right',
            'scr_d   .byte ' + ', '.join(map(str, dbl[2])) + '     ; one double-width']
    scr_json = {'n': len(sc['placed']), 'x': [p['sx'] + two[1] for p in sc['placed']], 'pd': [p['sy'] + y0 + 36 for p in sc['placed']],
                'dx': dbl[1] - two[1], 'l': [v >> 8 for v in two[2]], 'r': [v & 255 for v in two[2]], 'd': dbl[2]}
    print(f'{LV}: {len(sc["placed"])} Scrubblies: infill {two[0]} pixels wrong with two players, {dbl[0]} with one double-width')
else:
    inc += ['SCR_N = 0', 'SCR_H = 1', 'scr_xl  .byte 0', 'scr_xh  .byte 0', 'scr_pd  .byte 0', 'SCR_DX = 0',
            'scr_l   .byte 0', 'scr_r   .byte 0', 'scr_d   .byte 0']
open(os.path.join(OUT, f'{LV}_scrub.inc'), 'w').write('\n'.join(inc) + '\n')
_json.dump(scr_json, open(os.path.join(OUT, f'{LV}_scrub.json'), 'w'))
