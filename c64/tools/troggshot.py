# Checks Trogg in a VICE screenshot: finds the scroll (as compare.py does), then where his frame
# matches best near where he should be (his place in the level: x, y as trogg.asm keeps them),
# and reports how far that is from where he should be, the pixels of him that differ, and anything
# but the background in the 8 lines below his feet (where the second instances' rows 13-20 would
# show without the change to P3). Only what's in the display window, and not under the cover
# sprite at the left, counts; the scroll is the one
# that fits the rows round him.
#   python3 troggshot.py shot.png X Y FRAME
import json, os, re, subprocess, sys
from PIL import Image
DIR = os.path.dirname(os.path.abspath(__file__))
B = os.path.join(DIR, '..', 'build')
shot, tx, ty, fr = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])
out = subprocess.run(['python3', os.path.join(DIR, 'compare.py'), shot, '-1'], capture_output=True, text=True,
                     env=dict(os.environ, SPRITES='1')).stdout.split('\n')
scroll = int(out[0].split()[-1]); dx = int(out[1].split()[2])
frames = json.load(open(os.path.join(B, 'trogg.json')))
f = frames[fr]; shown = f['shown']
exp = open(os.path.join(B, 'charsspr.bin'), 'rb').read(); W = 8 * int(re.search(r'^NC\s*=\s*(\d+)', open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'build', 'level.inc')).read(), re.M).group(1))
PAL = {(145, 245, 220): 0, (255, 255, 92): 1, (184, 85, 246): 2, (0, 0, 0): 3, (160, 70, 220): 2}
im = Image.open(shot).convert('RGB'); px = im.load()
X0, Y0 = 32, 35
def at(x, y):                       # (a level pixel's place in the screenshot)
    return X0 + x - scroll + dx, Y0 + y - 24
def cls(x, y):
    sx, sy = at(x, y)
    return PAL.get(px[sx, sy], 9) if 0 <= sx < im.width and 0 <= sy < im.height else -2
left, top = tx - f['left'], ty - 34
# (the scroll in the rows round him: a screenshot can catch a frame being drawn, the rows above
# the raster's a scroll step on from those below)
def bgmatch(s):
    global scroll
    keep, scroll = scroll, s
    n = sum(1 for y in range(max(24, top), min(224, top + 42), 2) for x in range(scroll - dx + 8, scroll - dx + 300, 3)
            if 0 <= x < W and cls(x, y) == exp[(y - 24) * W + x])
    scroll = keep
    return n
scroll = max(range(max(0, scroll - 64), scroll + 65), key=bgmatch)     # (compare.py's can be thrown by him)
best = None
for oy in range(-6, 7):
    for ox in range(-12, 13):
        bad = sum(1 for r in range(34) for c in range(len(shown[r])) if shown[r][c] >= 0 and 0 <= top + oy + r - 24 < 200
                  and at(left + ox + c, 0)[0] >= X0 + dx + 32
                  and cls(left + ox + c, top + oy + r) != shown[r][c])     # (in the display window, not under the cover)
        if best is None or bad < best[0]: best = (bad, ox, oy)
bad, ox, oy = best
below = 0
for r in range(34, 42):
    for c in range(len(shown[0])):
        x, y = left + ox + c, top + oy + r
        if 0 <= y - 24 < 200 and 0 <= x < W and cls(x, y) != exp[(y - 24) * W + x]: below += 1
print(f'scroll {scroll}: Trogg found {ox:+d} across, {oy:+d} down from where he should be; '
      f'{bad} of his pixels differ; {below} pixels below his feet not the background')
