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
