# Checks a VICE screenshot of a VSP build (build.mjs --vsp S) at scroll 0: the screen should show
# its memory from offset S, so cell (r, c) shows map cell (r, c + S), or, past the row's end,
# (r + 1, c + S - 40), the next row's start. Compared with the mock-up's characters
# (../build/chars.bin, no sprites); cells whose source is unknown (the next row's columns 0-1,
# which the fill doesn't write, and past row 24) and the cover sprite's columns are left out.
# Prints the cells that differ; the sprites' cells differ at every offset alike (compare with S 0).
#   python3 vspcheck.py shot.png S
import os, sys
from PIL import Image
W = 752
exp = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'build', 'chars.bin'), 'rb').read()
im = Image.open(sys.argv[1]).convert('RGB'); px = im.load()
S = int(sys.argv[2])
PAL = {(145, 245, 220): 0, (255, 255, 92): 1, (184, 85, 246): 2, (0, 0, 0): 3, (160, 70, 220): 2}
cls = lambda x, y: PAL.get(px[x, y], 9)
X0, Y0 = 32, 35                         # (the display window in VICE's 384 x 272 screenshot)
def source(r, c):                       # the map cell shown at (r, c), or None if unknown
    m = c + S
    if m < 40: return r, m
    if r == 24 or m - 40 < 2: return None
    return r + 1, m - 40
best = None                             # where the picture sits (XSCROLL 7: 7 pixels on)
for dx in range(-24, 25):
    n = 0
    for y in range(0, 200, 3):
        for p in range(32, 240, 3):     # (p: the screen's pixel column, shown at p + dx)
            src = source(y // 8, p // 8)
            if not src: continue
            if cls(X0 + p + dx, Y0 + y) == exp[(src[0] * 8 + y % 8) * W + src[1] * 8 + p % 8]: n += 1
    if not best or n > best[0]: best = (n, dx)
dx = best[1]
bad = []
for r in range(25):
    for c in range(4, 39):              # (0-3: under the cover sprite)
        src = source(r, c)
        if not src: continue
        diff = 0
        for y in range(8):
            for x in range(8):
                sx = c * 8 + x + dx
                if sx < 7 or sx >= 311: continue        # (the 38-column border)
                if cls(X0 + sx, Y0 + r * 8 + y) != exp[(src[0] * 8 + y) * W + src[1] * 8 + x]: diff += 1
        if diff: bad.append((r, c, diff))
print(f'offset {S}: picture offset {dx}; ' + (f'{len(bad)} cells differ: ' + ' '.join(f'{r}/{c}({d})' for r, c, d in bad) if bad else 'all cells match'))
