# scr2png.py DIR/NNNN.scr OUT.png [SCALE]: a screen saved by tour.mjs as a picture (its palette.bin)
import sys, os, struct
from PIL import Image
scr = open(sys.argv[1], 'rb').read()
pal = struct.unpack('<256i', open(os.path.join(os.path.dirname(sys.argv[1]), 'palette.bin'), 'rb').read())
im = Image.new('RGB', (384, 240))
im.putdata([((pal[c] >> 16) & 255, (pal[c] >> 8) & 255, pal[c] & 255) for c in scr])
k = int(sys.argv[3]) if len(sys.argv) > 3 else 2
im.resize((384 * k, 240 * k), Image.NEAREST).save(sys.argv[2])
