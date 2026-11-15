# checkscreen.py CAPTURE.png EXPECT.png X: the screen captured by shot.sh against the level's
# picture (tools/screen.py's <level>_expect.png) at scroll position X (colour clocks: level pixel
# 2X at the screen's left). Each Atari pixel is sampled at its middle (the window is drawn 1.5
# times as wide, 2 times as high); black (an outline) or not. Prints the rows that differ.
import sys
from PIL import Image
cap = Image.open(sys.argv[1]).convert('L'); exp = Image.open(sys.argv[2]).convert('L'); X = int(sys.argv[3])
cw, ch = cap.size; cp = cap.load(); ep = exp.load()
# the playfield: the first and last scanline and column not border-black (COLBK 0)
bright = lambda v: v > 60
rows = [y for y in range(0, ch, 2) if sum(bright(cp[x, y]) for x in range(cw)) > cw // 4]
y0 = rows[0]
cols = [x for x in range(cw) if bright(cp[x, y0 + 1])]
x0, x1 = cols[0], cols[-1] + 1
sx = (x1 - x0) / 320
nlines = min((rows[-1] - y0) // 2 + 1, exp.size[1])
bad, badrows = 0, set()
for l in range(nlines):
    y = y0 + l * 2
    for p in range(320):
        got = not bright(cp[int(x0 + (p + 0.5) * sx), y])
        want = ep[2 * X + p, l] < 128
        if got != want: bad += 1; badrows.add(l // 4)
print(f'{sys.argv[1]}: x {X}, {nlines} lines x 320 pixels checked (scale {sx:.3f}), {bad} differ'
      + (f' in rows {sorted(badrows)}' if bad else ''))
sys.exit(1 if bad else 0)
