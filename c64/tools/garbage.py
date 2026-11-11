# Where the FLI bug's garbage lands in a VICE screenshot of the demo: for each character row,
# the first column (4 or more: 0-3 are under the cover sprite) starting three characters whose
# bottom halves are (nearly) all black, the $ff codes the VIC reads before it has the bus. Its
# column, less 0, is how many cycles after the earliest the forced bad line's write landed.
#   python3 garbage.py shot.png [rows]      (XSCROLL 7, as the demo starts)
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert('RGB'); px = im.load()
rows = [int(r) for r in sys.argv[2].split(',')] if len(sys.argv) > 2 else range(25)
X0, Y0 = 32 + 7, 35
def black(r, c):
    return sum(1 for y in range(4) for x in range(8) if px[X0 + 8 * c + x, Y0 + 8 * r + 4 + y] == (0, 0, 0))
for r in rows:
    b = [black(r, c) for c in range(39)]
    start = next((c for c in range(4, 37) if all(b[c + k] >= 24 for k in range(3))), -1)
    print(r, start, ' '.join(str(v) for v in b[:30]))
