# Compares a VICE screenshot of the demo with the mock-up's characters (../build/chars.bin, sprites left
# out), at scroll position SCROLL (pixels): finds where the picture sits, then reports for each
# character row the cells that differ (the FLI bug's columns at the left left out).
#   python3 compare.py shot.png [SCROLL]     (SCROLL -1: find it; 0 if left out)
import sys
from PIL import Image
W, HS = 752, 200
import os
# (SPRITES=1: against the picture with the Scrubblies' sprites, charsspr.bin; OFF=1: the Scrubblies
# yo-yoed off, chars_off.bin, charsspr_off.bin)
exp = open(__file__.rsplit('/', 1)[0] + ('/../build/charsspr' if os.environ.get('SPRITES') else '/../build/chars') + ('_off' if os.environ.get('OFF') else '') + '.bin', 'rb').read()
im = Image.open(sys.argv[1]).convert('RGB')
scroll = int(sys.argv[2]) if len(sys.argv) > 2 else 0
PAL = {(145, 245, 220): 0, (255, 255, 92): 1, (184, 85, 246): 2, (0, 0, 0): 3, (160, 70, 220): 2}
px = im.load()
def cls(x, y):
    return PAL.get(px[x, y], 9)
# the display window: x 32-351, y 35-234 in VICE's 384 x 272 screenshot
X0, Y0 = 32, 35
best = None
if scroll < 0:          # (unknown: search every position, then refine)
    for sc in range(0, 440):
        m = 0
        for y in range(0, 200, 4):
            for x in range(40, 300, 4):
                mx = x - 7 + sc
                if 0 <= mx < W and cls(X0 + x, Y0 + y) == exp[y * W + mx]: m += 1
        if not best or m > best[0]: best = (m, sc)
    scroll = best[1]; best = None
    print(f'scroll position {scroll}')
for dx in range(-24, 25):
    m = 0
    for y in range(0, 200, 3):
        for x in range(40, 300, 3):
            mx = x - dx + scroll
            if 0 <= mx < W and cls(X0 + x, Y0 + y) == exp[y * W + mx]: m += 1
    if not best or m > best[0]: best = (m, dx)
dx = best[1]
print(f'picture offset {dx} pixels (XSCROLL 7 would be 7)')
bad = 0
base = scroll
for r in range(25):
  # (a screenshot can catch the frame being drawn: rows above the raster one scroll step on)
  tried = []
  for scroll in (base, base + 1, base - 1, base + 2, base - 2):
    cells = []
    for c in range(4, 39):     # (columns 0-3: under the cover sprite)
        diff = 0
        for y in range(r * 8, r * 8 + 8):
            for x in range(c * 8, c * 8 + 8):
                sx = x + dx
                if sx < 7 or sx >= 311: continue        # (the 38-column border)
                mx = x + scroll - base + base
                if mx >= W: continue
                if cls(X0 + sx, Y0 + y) != exp[y * W + mx]: diff += 1
        if diff: cells.append(f'{c}({diff})')
    tried.append((len(cells), scroll, cells))
    if not cells: break
  n, sc, cells = min(tried)
  bad += n
  if cells: print(f'row {r:2}: {n} cells differ (at scroll {sc}): ' + ' '.join(cells))
  elif sc != base: print(f'row {r:2}: matches at scroll {sc}')
print('all rows match' if not bad else f'{bad} cells differ')
