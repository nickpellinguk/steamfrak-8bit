# screen.py [LEVEL]: a level's screen data for the 8x4 display, from the C64 build's picture of it
# (c64/build/<level>/chars.bin: "node c64/tools/level.mjs A_1 --out A_1" first), black pixels only.
#
# The display is pairs of 4-line rows: the first of a pair shows glyph lines 4-7 of its
# characters (a "bottoms" row, by the display's mechanics), the second lines 0-3 (a "tops" row).
# So a character holds two glyphs, bytes 0-3 for the tops rows and 4-7 for the bottoms rows,
# numbered independently. The screen is 240 lines (ANTIC's most: scanlines 8-247), 60 rows,
# showing the original's level lines 16-255; the C64 shows lines 24-223, its 25 character rows
# (chars.bin), each its half rows 2n (lines 0-3) and 2n + 1 (4-7). So the Atari's row r shows
# the C64's half row r - 2, its rows top to bottom
#   [-2 -1] [0 1] ... [48 49] [50 51] ... [56 57]
# (the C64's half rows outside 0-49 blank: the C64's level files hold its 200 lines' worth; the
# rows above and below are the original's empty margins on A_1). An even half row (the C64's
# tops) goes in a pair's first row, its glyph in bytes 4-7. One character set for the whole level
# (A_1 needs 46 codes; more levels may need bands). Map line = the C64's map line (level line -
# 24); display line = map line + 8; scanline (the players' memory's line) = map line + 16.
#
# Writes atari800xl/build/<level>_font.bin (1KB), <level>_map.bin (60 rows of 128 bytes: 4 bytes
# of blank, the level's columns, blank after: the scroll's LMS arithmetic wants the 4 in front)
# and <level>_map.lz (it packed, for trogg8x4.asm),
# <level>.inc (NCOLS, NROWS) and <level>_expect.png (the picture the Atari should show, for checks).
import os, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
LV = sys.argv[1] if len(sys.argv) > 1 else 'A_1'
SRC = os.path.join(HERE, '..', '..', 'c64', 'build', LV, 'chars.bin')
OUT = os.path.join(HERE, '..', 'build')
H = 200
px = open(SRC, 'rb').read(); W = len(px) // H; NC = W // 8
STRIDE, PAD, NROWS, HR0 = 128, 4, 60, -2   # (HR0: the C64's half row in the Atari's row 0)
assert PAD + NC <= STRIDE

gone = open(os.path.join(os.path.dirname(SRC), 'chars_gone.bin'), 'rb').read()   # (the gems and keys gone)
off = open(os.path.join(os.path.dirname(SRC), 'chars_off.bin'), 'rb').read()     # (the Scrubblies knocked off)
def half(hr, c, pic=px):              # the C64's half row hr (2n tops, 2n+1 bottoms), column c: 4 bytes
    if hr < 0 or hr >= 2 * 25: return (0, 0, 0, 0)
    return tuple(sum(0x80 >> x for x in range(8) if pic[(hr * 4 + l) * W + c * 8 + x] == 3) for l in range(4))

tops, bottoms = {(0, 0, 0, 0): 0}, {(0, 0, 0, 0): 0}
mp = bytearray(STRIDE * NROWS)
mpg = bytearray(STRIDE * NROWS)       # (the map with the gems and keys gone: their glyphs in the set too)
mpo = bytearray(STRIDE * NROWS)       # (... with the Scrubblies knocked off)
for m, pic in ((mp, px), (mpg, gone), (mpo, off)):
    for r in range(NROWS):
        second = r & 1
        hr = r + HR0                                             # (the C64's half row)
        table = tops if second else bottoms
        for c in range(NC):
            g = half(hr, c, pic)
            if g not in table: table[g] = len(table)
            m[r * STRIDE + PAD + c] = table[g]
n = max(len(tops), len(bottoms))
assert n <= 128, f'{LV}: {len(tops)} tops and {len(bottoms)} bottoms glyphs: over 128 codes'
font = bytearray(1024)
for g, i in tops.items(): font[i * 8:i * 8 + 4] = bytes(g)
for g, i in bottoms.items(): font[i * 8 + 4:i * 8 + 8] = bytes(g)
os.makedirs(OUT, exist_ok=True)
open(os.path.join(OUT, f'{LV}_font.bin'), 'wb').write(font)
open(os.path.join(OUT, f'{LV}_map.bin'), 'wb').write(mp)
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))   # (the BBC version's packer: the map packed,
from pack import compress, decompress                          #  unpacked into the screen's at the start)
lz = compress(bytes(mp)); assert decompress(lz) == bytes(mp)
open(os.path.join(OUT, f'{LV}_map.lz'), 'wb').write(lz)
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
# top (scanline: map line + 16). Poglets and Hooters (two colours) are for later.
import json as _json
json = _json
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
            'scr_pd  .byte ' + ', '.join(str(p['sy'] + y0 + 16) for p in sc['placed']),
            f'SCR_DX = {dbl[1] - two[1]}                  ; the double-width player\'s left, from theirs',
            'scr_l   .byte ' + ', '.join(str(v >> 8) for v in two[2]) + '     ; two players: left',
            'scr_r   .byte ' + ', '.join(str(v & 255) for v in two[2]) + '     ; right',
            'scr_d   .byte ' + ', '.join(map(str, dbl[2])) + '     ; one double-width']
    scr_json = {'n': len(sc['placed']), 'x': [p['sx'] + two[1] for p in sc['placed']], 'pd': [p['sy'] + y0 + 16 for p in sc['placed']],
                'dx': dbl[1] - two[1], 'l': [v >> 8 for v in two[2]], 'r': [v & 255 for v in two[2]], 'd': dbl[2]}
    print(f'{LV}: {len(sc["placed"])} Scrubblies: infill {two[0]} pixels wrong with two players, {dbl[0]} with one double-width')
else:
    inc += ['SCR_N = 0', 'SCR_H = 1', 'scr_xl  .byte 0', 'scr_xh  .byte 0', 'scr_pd  .byte 0', 'SCR_DX = 0',
            'scr_l   .byte 0', 'scr_r   .byte 0', 'scr_d   .byte 0']
open(os.path.join(OUT, f'{LV}_scrub.inc'), 'w').write('\n'.join(inc) + '\n')
_json.dump(scr_json, open(os.path.join(OUT, f'{LV}_scrub.json'), 'w'))

# The gems and keys (c64/build/<level>/picks.json; chars.bin's pixels are level pixels across, and
# level lines less 24 down): each one's box (level pixels, as the C64's collide.inc). The patch
# objects: the gems and keys, then the Scrubblies (NPO in all, at most 24: a bit each in pick.asm's
# masks); each one's cells that change when it's picked up (the map with it gone, chars_gone.bin)
# or knocked off by the yoyo (chars_off.bin): row, column, SCREEN's address and the code each way,
# at most PMAX (the VBI's patch program's room). And the keys' yellow (their grid's 1s, chars.bin's colour 1) for players,
# fitted as the Scrubblies' magenta is: two normal-width players (left and right) or one
# double-width; the players' line of the top (scanline: level line - 8).
PJ = json.load(open(os.path.join(os.path.dirname(SRC), 'picks.json')))
pk = PJ['picks']
PMAX = 76
cells = []
for p in pk:
    b = p['box']; x0, x1 = p['left'] + b['x0'], p['left'] + b['x1']
    y0, y1 = p['top'] - 24 + b['y0'], p['top'] - 24 + b['y1']          # (chars.bin lines)
    cs = []
    for r in range(NROWS):
        hr = r + HR0
        if hr * 4 + 3 < y0 - 4 or hr * 4 > y1 + 4: continue
        for c in range(x0 // 8 - 1, x1 // 8 + 2):
            o = r * STRIDE + PAD + c
            if 0 <= c < NC and mp[o] != mpg[o]: cs.append((r, c, mpg[o], mp[o]))
    assert len(cs) <= PMAX, f'{p}: {len(cs)} cells'
    cells.append(cs)
for e in sc['placed']:                # (the Scrubblies: their shapes' boxes)
    x0, x1, y0, y1 = e['ax'], e['ax'] + sc.get('w', 40) - 1, e['ay'], e['ay'] + sc.get('h', 42) - 1
    cs = []
    for r in range(NROWS):
        hr = r + HR0
        if hr * 4 + 3 < y0 - 4 or hr * 4 > y1 + 4: continue
        for c in range(x0 // 8 - 1, x1 // 8 + 2):
            o = r * STRIDE + PAD + c
            if 0 <= c < NC and mp[o] != mpo[o]: cs.append((r, c, mpo[o], mp[o]))
    assert len(cs) <= PMAX, f'{e}: {len(cs)} cells'
    cells.append(cs)
NPO = len(cells)
assert NPO <= 24, f'{LV}: {NPO} gems, keys and Scrubblies, over 24'
allc = [(r, c) for cs in cells for r, c, _, _ in cs]
assert len(allc) == len(set(allc)), 'two gems, keys or Scrubblies share a cell'
kg = PJ['grids']['IMG_Key']; KW = len(kg[0])
krows = [y for y in range(len(kg)) if 1 in kg[y]]; ky0, ky1 = krows[0], krows[-1]
def kfit(bw, nb):
    best = None
    for o in range(-8, 8, 2):
        data, bad = [], 0
        for y in range(ky0, ky1 + 1):
            v = 0; on = set()
            for b_ in range(nb):
                xs = [x for x in range(o + b_ * bw, o + b_ * bw + bw) if 0 <= x < KW]
                if sum(kg[y][x] == 1 for x in xs) > sum(kg[y][x] == -1 for x in xs): v |= 1 << (nb - 1 - b_); on.update(xs)
            bad += sum((kg[y][x] == 1) != (x in on) for x in range(KW) if kg[y][x] != 3)
            data.append(v)
        if best is None or bad < best[0]: best = (bad, o, data)
    return best
ktwo, kdbl = kfit(2, 16), kfit(4, 8)
L = lambda v: ', '.join(str(x) for x in v)
pinc = [f'NPK = {len(pk)}', f'KEYBITS = {sum(1 << i for i, p in enumerate(pk) if p["name"] == "IMG_Key")}', f'NKEYS = {sum(p["name"] == "IMG_Key" for p in pk)}', f'PMAX = {PMAX}', f'NPO = {NPO}',
        'pkll    .byte ' + L((p['left'] + p['box']['x0']) & 255 for p in pk) + '     ; boxes (level pixels)',
        'pklh    .byte ' + L((p['left'] + p['box']['x0']) >> 8 for p in pk),
        'pkrl    .byte ' + L((p['left'] + p['box']['x1']) & 255 for p in pk),
        'pkrh    .byte ' + L((p['left'] + p['box']['x1']) >> 8 for p in pk),
        'pkt     .byte ' + L(p['top'] + p['box']['y0'] for p in pk),
        'pkb     .byte ' + L(p['top'] + p['box']['y1'] for p in pk),
        'pkkey   .byte ' + L(int(p['name'] == 'IMG_Key') for p in pk) + '     ; 1 a key',
        'pkxl    .byte ' + L((p['left'] + ktwo[1]) & 255 for p in pk) + '     ; a key\'s players\' left',
        'pkxh    .byte ' + L(((p['left'] + ktwo[1]) >> 8) & 255 for p in pk),
        'pkpd    .byte ' + L(p['top'] - 8 + ky0 for p in pk),
        'pkn     .byte ' + L(len(cs) for cs in cells) + '     ; each patch object\'s cells: how many, where',
        'pkpl    .byte ' + L(f'<pkc{i}' for i in range(NPO)),
        'pkph    .byte ' + L(f'>pkc{i}' for i in range(NPO)),
        *[f'pkc{i:<4}.byte ' + (L(v for r, c, g, f_ in cs for v in ((0xd800 + r * STRIDE + PAD + c) & 255, (0xd800 + r * STRIDE + PAD + c) >> 8, r, c, g, f_)) or '0')
          + ('     ; (each: SCREEN\'s address, row, column, the code gone, there)' if i == 0 else '') for i, cs in enumerate(cells)],
        f'KEY_H = {ky1 - ky0 + 1}', f'KEY_DX = {kdbl[1] - ktwo[1]}',
        'key_l   .byte ' + L(v >> 8 for v in ktwo[2]),
        'key_r   .byte ' + L(v & 255 for v in ktwo[2]),
        'key_d   .byte ' + L(kdbl[2])]
open(os.path.join(OUT, f'{LV}_picks.inc'), 'w').write('\n'.join(pinc) + '\n')
_json.dump({'n': len(pk), 'key': [int(p['name'] == 'IMG_Key') for p in pk], 'x': [p['left'] + ktwo[1] for p in pk],
            'pd': [p['top'] - 8 + ky0 for p in pk], 'dx': kdbl[1] - ktwo[1], 'l': [v >> 8 for v in ktwo[2]],
            'r': [v & 255 for v in ktwo[2]], 'd': kdbl[2], 'cells': [[[r, c, g, f] for r, c, g, f in cs] for cs in cells]},
           open(os.path.join(OUT, f'{LV}_picks.json'), 'w'))
print(f'{LV}: {len(pk)} gems and keys, {NPO - len(pk)} Scrubblies, their cells {[len(c) for c in cells]}; key infill {ktwo[0]} pixels wrong with two players, {kdbl[0]} with one double-width')
