"""Mock-up of Frak! level A_1's first screen under Atari 2600 rules.
160x192 visible, playfield in 4-px cells (40 across, asymmetric), two 8-bit players
(one colour per player per line), a ball/missiles for gems, NTSC palette."""
import sys
import os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import convert
from PIL import Image, ImageDraw

SF = os.environ.get('STEAMFRAK', os.path.join(HERE, '..', '..', '..', 'steamfrak'))
data = convert.Data(SF)
lev = convert.build_level(data, 'room_A_1')

# a few NTSC 2600 palette entries (hue/lum codes)
NTSC = {0x00: (0, 0, 0), 0x0E: (236, 236, 236), 0x1E: (252, 252, 104), 0x1C: (236, 236, 92),
        0x56: (184, 64, 168), 0x58: (208, 92, 192), 0x5A: (220, 116, 208), 0x48: (232, 92, 136),
        0x84: (64, 64, 172), 0x86: (92, 92, 196), 0x34: (184, 80, 32), 0x38: (216, 124, 72),
        0x26: (184, 120, 52), 0x08: (136, 136, 136)}
BG, PF_TOP, PF_BODY, LADDER = 0x00, 0x1E, 0x56, 0x38
W, H = 160, 192
X0, XS = 0, 160 / 256          # level window x 0..256 -> 160 px
YS = 0.8
def ly(y): return int(round((y - 18) * YS))   # level y -> scanline
PLAY_H = 172                   # scanlines 0..171 for the level, the rest for the HUD

fb = [[BG] * W for _ in range(H)]
pf = [[False] * 40 for _ in range(H)]
pfcol = [PF_BODY] * H

# --- playfield: ledges (4 lines thick, yellow top line) and ladders (one 4-px column, rungs)
for (px, py, pw, ph) in lev['plats']:
    a, b = int(px * XS) // 4, int((px + pw) * XS + 3) // 4
    if a >= 40: continue
    t = ly(py)
    for line in range(t, t + 5):
        for c in range(a, min(b, 40)):
            pf[line][c] = True
    pfcol[t] = PF_TOP
for (spr, _), (lx, lyy, lh, ext) in zip(lev['ladder_spr'], lev['ladders']):
    info = data.sprites[spr]
    cx = int((lx - info['xo'] + info['w'] // 2) * XS) // 4
    if cx >= 40: continue
    top, bot = ly(lyy + ext), ly(lyy + lh)
    for line in range(top, bot):
        if (line - top) % 6 < 2:          # rungs: the whole cell lit every 6 lines
            pf[line][cx] = True
            if pfcol[line] == PF_BODY: pfcol[line] = LADDER
for y in range(H):
    for c in range(40):
        if pf[y][c]:
            for x in range(c * 4, c * 4 + 4): fb[y][x] = pfcol[y]

# --- players: sprites squeezed to 8 bits, one colour per line
def squeeze(name, lines, colour_map):
    im = Image.open(f'{SF}/assets/sprites/{name}.png').convert('RGBA')
    bb = im.getbbox(); im = im.crop(bb)
    w, h = im.size
    rows = []
    for r in range(lines):
        y0, y1 = int(r * h / lines), max(int((r + 1) * h / lines), int(r * h / lines) + 1)
        bits, votes = [], {}
        for b in range(8):
            x0, x1 = int(b * w / 8), max(int((b + 1) * w / 8), int(b * w / 8) + 1)
            lit = 0; tot = 0
            for yy in range(y0, y1):
                for xx in range(x0, x1):
                    p = im.getpixel((xx, yy)); tot += 1
                    if p[3] and p[:3] != (0, 0, 0):
                        lit += 1; votes[p[:3]] = votes.get(p[:3], 0) + 1
            bits.append(lit * 2 >= tot)
        col = colour_map[max(votes, key=votes.get)] if votes else 0
        rows.append((bits, col))
    return rows

CM = {(255, 0, 255): 0x58, (255, 255, 0): 0x1E}
def art(rows, rep=2):
    out = []
    for txt, col in rows:
        out += [([ch == 'X' for ch in txt], col)] * rep
    return out
M, Y, P = 0x58, 0x1E, 0x48
TROGG = art([('...XX...', Y), ('..XXXX..', Y), ('.XXXXX..', P), ('.XX.XXXX', P), ('.XXXXXXX', P),
             ('..XXX...', P), ('.XXXXX..', P), ('XXXXXXX.', P), ('X.XXXX.X', P), ('..XXXX..', P),
             ('..X..X..', Y), ('..X..X..', Y), ('.XX..XX.', Y)])
SCRUB = art([('.X....X.', Y), ('..X..X..', Y), ('.XXXXXX.', M), ('XXXXXXXX', M), ('X..XX..X', M),
             ('X..XX..X', M), ('XXXXXXXX', M), ('XX....XX', M), ('X.X..X.X', M), ('XXXXXXXX', M),
             ('XXXXXXXX', M), ('.XXXXXX.', M), ('.XX..XX.', M), ('XXX..XXX', M)])
GEM = [([False, True, True, True, True, True, True, False], 0x0E)]  # unused

def put(rows, x, bottom, wide):
    top = bottom - len(rows) + 1
    for r, (bits, col) in enumerate(rows):
        y = top + r
        if not (0 <= y < PLAY_H): continue
        for b, on in enumerate(bits):
            if on:
                for k in range(wide):
                    xx = x + b * wide + k
                    if 0 <= xx < W: fb[y][xx] = col

players = 0
tx, ty = lev['trogg']
put(TROGG, int(tx * XS) - 4, ly(ty), 1)                       # P0, single width
for _, _, spr, x, y, _ in lev['draw']:
    if x >= 256: continue
    if 'Scrubbly' in spr:
        put(SCRUB, int(x * XS) - 8, ly(y), 2)                  # P1 (or P0), double width
    elif 'Gem' in spr:                                          # the ball, 4 px wide, 3 lines
        gx, gy = int(x * XS) - 2, ly(y)
        for yy in range(gy - 3, gy):
            for xx in range(gx, gx + 4): fb[yy][xx] = 0x0E if yy != gy - 3 else 0x86
    elif 'Key' in spr:                                          # a missile, 2 px + playfield-ish
        kx, kyy = int(x * XS) - 3, ly(y)
        for yy in range(kyy - 3, kyy):
            for xx in range(kx, kx + 6): fb[yy][xx] = 0x1E if (yy == kyy - 2 or xx < kx + 2) else BG

# --- HUD: timer with a crude 3x5 font in the playfield (score-mode style, 4px cells)
FONT = {'0': ['111', '101', '101', '101', '111'], '1': ['010', '110', '010', '010', '111'],
        ':': ['0', '1', '0', '1', '0'], '.': ['0', '0', '0', '0', '1'],
        '2': ['111', '001', '111', '100', '111'], '3': ['111', '001', '111', '001', '111'],
        '7': ['111', '001', '010', '010', '010'], '4': ['101', '101', '111', '001', '001'], '9': ['111', '101', '111', '001', '111']}
def text(s, cx, top, col):
    for ch in s:
        g = FONT[ch]
        for r, row in enumerate(g):
            for c, v in enumerate(row):
                if v == '1':
                    for yy in range(top + r * 3, top + r * 3 + 3):
                        for xx in range((cx + c) * 4, (cx + c) * 4 + 4): fb[yy][xx] = col
        cx += len(g[0]) + 1
text('0:17', 1, 175, 0x1E)
# lives/rating pip on the right
for yy in range(178, 187):
    for xx in range(148, 156): fb[yy][xx] = 0x26

# --- output, with Stella-ish pixel aspect (each colour clock ~ 2:1)
img = Image.new('RGB', (W, H))
img.putdata([NTSC[c] for row in fb for c in row])
big = img.resize((W * 5, H * 3), Image.NEAREST)
# faint scanlines
d = ImageDraw.Draw(big, 'RGBA')
for y in range(0, H * 3, 3): d.line([(0, y + 2), (W * 5, y + 2)], fill=(0, 0, 0, 70))
big.save(sys.argv[1] if len(sys.argv) > 1 else 'vcs_A_1.png')
