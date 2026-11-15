# checktrogg.py DIR LEVEL: each screen saved by tour.mjs against what it should show: the level
# (build/<level>_expect.png) at the scroll, with each thing drawn (Trogg, then balloons and
# daggers: graphic, top left x, top line) drawn on in order, from the records the VBI turns
# round: a frame's VBI comes after its picture, so the picture shows the frame before's record
# (pvi) when that VBI showed a new frame ("fresh"), else still the one shown (shi). Every pixel of the 320 x 208 play area, black or not.
import sys, os, json, glob
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); B = os.path.join(HERE, '..', 'build')
d, lv = sys.argv[1], sys.argv[2]
exp = Image.open(os.path.join(B, f'{lv}_expect.png')).load()
graphics = json.load(open(os.path.join(B, 'sprites.json')))['graphics']
L = dict((l.split()[0], int(l.split()[-1].lstrip('$'), 16)) for l in open(os.path.join(B, 'trogg8x4.lbl')) if '= $' in l or '= 1536' in l)
X0, Y0, BG = 32, 24, 0x9a
bad_shots = 0; shifts = set(); names = {}; partial = 0; most = 0
for scr in sorted(glob.glob(os.path.join(d, '*.scr'))):
    s = open(scr, 'rb').read(); m = open(scr[:-4] + '.mem', 'rb').read()
    r = L['OBJS'] + m[L['pvi' if m[L['fresh']] else 'shi']]       # the record the picture shows
    n, sx = m[r + 33], m[r + 32]
    objs = [(m[r + i], (m[r + 8 + i] | m[r + 16 + i] << 8) - (65536 if m[r + 16 + i] & 0x80 else 0), m[r + 24 + i] - 32) for i in range(n)]
    most = max(most, n)
    img = [[exp[2 * sx + x, y] < 128 for x in range(320)] for y in range(208)]
    for g, x, top in objs:
        fr = graphics[g]; names[fr['name']] = names.get(fr['name'], 0) + 1; shifts.add(x % 8)
        sxp = x - 2 * sx
        if sxp < 0 or sxp + fr['w'] > 320 or top < 0 or top + fr['h'] > 208: partial += 1
        for gy, row in enumerate(fr['grid']):
            y = top + gy
            if not 0 <= y < 208: continue
            for gx, c in enumerate(row):
                xx = sxp + gx
                if 0 <= xx < 320 and c != 'T': img[y][xx] = c == 'S'
    bad = sum((s[(Y0 + y) * 384 + X0 + x] != BG) != img[y][x] for y in range(208) for x in range(320))
    if bad:
        bad_shots += 1
        print(f'{os.path.basename(scr)}: {bad} pixels differ; things: ' + ', '.join(f'{graphics[g]["name"]}@{x},{t}' for g, x, t in objs) + f'; scroll {sx}')
n = len(glob.glob(os.path.join(d, '*.scr')))
drops = m[L['drops']] | m[L['drops'] + 1] << 8
print(f'{n} screens, {n - bad_shots} exact; frames not made in time: {drops}; most things on a screen {most}, '
      f'partly off the screen {partial} times; shifts {sorted(shifts)}; drawn: ' + ', '.join(f'{k} {v}' for k, v in sorted(names.items())))
sys.exit(1 if bad_shots else 0)
