# frontcheck.py DIR: each screen saved by tour.mjs while the front end is up, against what it
# should show (build/front.json, tools/front.py's): the bitmap (the cast's outlines) with the text
# drawn in from the font the program copied (FONTB, in the saved memory), players in front of the
# playfield (P0 first, a missile with its player), a set pixel showing luminance 0 in the hue under
# it. Every pixel of the 320 x 220 lines, in every screen saved (so run it on a tour that stays on
# the front end).
import sys, os, glob, json
HERE = os.path.dirname(os.path.abspath(__file__)); B = os.path.join(HERE, '..', 'build')
J = json.load(open(os.path.join(B, 'front.json')))
L = {}
for l in open(os.path.join(B, 'trogg8x4.lbl')):
    f = l.split()
    if len(f) >= 3 and f[1] == '=':
        try: L[f[0]] = int(f[2][1:], 16) if f[2].startswith('$') else int(f[2])
        except ValueError: pass
X0, BG, OUT, NL = 32, 0x9a, 0x90, J['lines']
pl = [[None] * 320 for _ in range(NL)]
def put(prio, col, rows, x0, top, bits=8, shift=0):
    for y, v in enumerate(rows):
        for b in range(bits):
            if v >> (shift + bits - 1 - b) & 1:
                for k in range(2):
                    x = x0 + 2 * b + k
                    if 0 <= x < 320 and 0 <= top + y < NL and (pl[top + y][x] is None or pl[top + y][x][0] > prio): pl[top + y][x] = (prio, col)
for p, c, x, y, rows in J['players']: put(p, c, rows, x, y)
for mx0, mx1, y, rows in J['missiles']:
    put(0, J['yel'], rows, mx0, y, 2, 0); put(1, J['mag'], rows, mx1, y, 2, 2)
n = good = 0
for scr in sorted(glob.glob(os.path.join(sys.argv[1], '*.scr'))):
    s = open(scr, 'rb').read(); m = open(scr[:-4] + '.mem', 'rb').read()
    font = m[L['FONTB']:L['FONTB'] + 1024]
    px = [row[:] for row in J['bitmap']]
    for line, col, codes in J['text']:
        for k, c in enumerate(codes):
            for l in range(8):
                g = font[c * 8 + l]
                for x in range(8):
                    if g & 0x80 >> x: px[line + l][(col + k) * 8 + x] = 1
    bad = 0
    for y in range(NL):
        for x in range(320):
            q = pl[y][x]
            want = ((q[1] & 0xf0) if q else OUT) if px[y][x] else (q[1] if q else BG)
            bad += s[y * 384 + X0 + x] != want
    n += 1
    if bad: print(f'{os.path.basename(scr)}: {bad} pixels differ')
    else: good += 1
print(f'{n} screens, {good} exact')
sys.exit(0 if n and good == n else 1)
