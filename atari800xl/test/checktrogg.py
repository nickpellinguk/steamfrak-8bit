# checktrogg.py DIR LEVEL: each screen saved by tour.mjs against what it should show: the level
# (build/<level>_expect.png) at the scroll, with Trogg's outline drawn on at his top left, in his
# frame (build/sprites.json), as the VBI recorded them: a frame's VBI comes after its picture, so
# the picture shows "prev" when that VBI showed a new frame ("fresh"), else still "shown". Every
# pixel of the 320 x 208 play area, black or not.
import sys, os, json, glob
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); B = os.path.join(HERE, '..', 'build')
d, lv = sys.argv[1], sys.argv[2]
exp = Image.open(os.path.join(B, f'{lv}_expect.png')).load()
frames = json.load(open(os.path.join(B, 'sprites.json')))['trogg']
lbl = dict((l.split()[0], int(l.split()[-1].lstrip('$'), 16)) for l in open(os.path.join(B, 'trogg8x4.lbl')) if '= $' in l)
PREV, SHOWN, FRESH, DROPS = lbl['prev'], lbl['shown'], lbl['fresh'], lbl['drops']
X0, Y0, BG = 32, 24, 0x9a
bad_shots = 0; seen = set()
for scr in sorted(glob.glob(os.path.join(d, '*.scr'))):
    s = open(scr, 'rb').read(); m = open(scr[:-4] + '.mem', 'rb').read()
    def want(st):
        xtl, ytl, f, sx = m[st] | m[st + 1] << 8, m[st + 2], m[st + 3], m[st + 4]
        fr = frames[f]; bad = 0
        for l in range(208):
            for p in range(320):
                lx = 2 * sx + p; black = exp[lx, l] < 128
                gx, gy = lx - xtl, l - (ytl + 4)
                if 0 <= gy < fr['h'] and 0 <= gx < fr['w']:
                    c = fr['grid'][gy][gx]
                    if c == 'S': black = True
                    elif c != 'T': black = False
                got = s[(Y0 + l) * 384 + X0 + p] != BG
                bad += got != black
        return bad, (xtl, ytl, fr['name'], sx)
    bad, st = want(PREV if m[FRESH] else SHOWN)
    seen.add((st[0] % 8, st[2])); drops = m[DROPS] | m[DROPS + 1] << 8
    if bad:
        bad_shots += 1
        print(f'{os.path.basename(scr)}: {bad} pixels differ (x {st[0]}, y {st[1]}, {st[2]}, scroll {st[3]})')
n = len(glob.glob(os.path.join(d, '*.scr')))
print(f'{n} screens, {n - bad_shots} exact; frames not made in time: {drops}; shifts seen {sorted({x for x, _ in seen})}, frames seen {sorted({f for _, f in seen})}')
sys.exit(1 if bad_shots else 0)
