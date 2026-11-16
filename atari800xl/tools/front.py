# front.py [LEVEL]: the front end's screen (src/front.asm), as the C64 port's (c64/src/front.asm,
# its layout from c64/tools/build.mjs): "The Cast", the FRAK! bubble at the top, Trogg, a
# Scrubbly, a Hooter and a Poglet down the middle with their names, then the closing lines. One
# 320 x 220 hi-res bitmap (ANTIC mode F, scanlines 8-227: the bubble in the first 19 lines, the
# C64's 25 text rows from line 20, its positions kept), the cast's outlines (black) in it, the
# text drawn into it by front.asm from the machine's ROM font (as the C64 uses its own); the
# infills (yellow, magenta) on players, re-used down the screen band by band (a DLI between each
# picture), fitted as the game's are: 2-pixel blocks, a block on where more of its visible pixels
# are the colour than aren't. Trogg's from the game's (sprites.json: his standing frame, the
# first walking one, as the game shows him: P0 yellow, P1 magenta and their missiles).
# Writes build/front.inc (the display list, the bitmap's line addresses, the text, the players'
# graphics and each band's registers), build/front_bm.lz (the bitmap, packed: unpacked under the
# OS, where the game's screen goes later) and build/front.json (for test/frontcheck.py).
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
from pack import compress, decompress
LV = sys.argv[1] if len(sys.argv) > 1 else 'A_1'
OUT = os.path.join(HERE, '..', 'build')
H = json.load(open(os.path.join(HERE, '..', '..', 'c64', 'build', LV, 'picks.json')))['hazards']
G = {g['name']: g for g in json.load(open(os.path.join(OUT, 'sprites.json')))['graphics']}
W, NL, TOP, BASE, FRDL = 320, 220, 20, 0xd800, 0xaf00     # (width, lines, text row 0's line, the bitmap, the display list)
TOPL = 8                                                  # (line 0's scanline)
YEL, MAG = 0x1e, 0x58

# the cast: each picture's grid (-1 transparent, 0 background, 1 yellow, 2 magenta, 3 black), its
# left (screen pixels) and top (bitmap line): the C64's sprites' places (x - 24; y - 50 + 20)
tr = G['WR0']
tgrid = [[-1 if c == 'T' else 3 if c == 'S' else 1 if c == 'Y' else 2 if c == 'M' else 0 for c in r] for r in tr['grid']]
CAST = [('FRAK', H['IMG_Frak']['grid'], 134, 0), ('TROGG', tgrid, 92, TOP + 16), ('SCRUBBLY', H['IMG_Scrubbly']['grid'], 90, TOP + 66),
        ('HOOTER', H['IMG_Hooter']['grid'], 96, TOP + 111), ('POGLET', H['IMG_Poglet']['grid'], 94, TOP + 137)]
for c in CAST: assert c[2] % 2 == 0, c[0]       # (lefts even: players are in 2-pixel steps)
bm = [[0] * W for _ in range(NL)]
for _, g, x0, y0 in CAST:
    for y, r in enumerate(g):
        for x, v in enumerate(r):
            if v == 3: bm[y0 + y][x0 + x] = 1

# the infills: each colour's pixels in 16-pixel players (8 blocks of 2), as few as cover it, their
# left the best of the even places (fewest pixels wrong)
def fit(g, col):
    xs = [x for r in g for x, v in enumerate(r) if v == col]
    if not xs: return [], 0
    best = None
    for o in range((min(xs) - 14) & ~1, min(xs) + 1, 2):     # (even: the players' steps are 2 pixels)
        n = -(-(max(xs) + 1 - o) // 16)
        plays, bad = [], 0
        for k in range(n):
            rows = []
            for r in g:
                v = 0
                for b in range(8):
                    px = [r[x] for x in (o + 16 * k + 2 * b, o + 16 * k + 2 * b + 1) if 0 <= x < len(r)]
                    if sum(p == col for p in px) > sum(p != col and p != 3 for p in px): v |= 0x80 >> b
                rows.append(v)
            plays.append((o + 16 * k, rows))
        on = set()
        for x, rows in plays:
            for y, v in enumerate(rows):
                for b in range(8):
                    if v & 0x80 >> b: on.update(((x + 2 * b, y), (x + 2 * b + 1, y)))
        for y, r in enumerate(g):
            for x, v in enumerate(r):
                if v != 3: bad += (v == col) != ((x, y) in on)
        if best is None or (len(plays), bad) < (len(best[0]), best[1]): best = (plays, bad)
    return best
bands = []                  # (each: its pictures' players: (player, colour, left, top, rows), missiles)
report = []
for name, g, x0, y0 in CAST:
    if name == 'TROGG':     # (the game's: P0 yellow, P1 magenta, M0 and M1)
        p = tr['players']
        bands.append({'name': name, 'players': [(0, YEL, x0 + 2 * p['ax'], y0, p['a']), (1, MAG, x0 + 2 * p['bx'], y0, p['b'])],
                      'missiles': (x0 + 2 * p['max'], x0 + 2 * p['mbx'], y0, p['m']), 'top': y0, 'bottom': y0 + len(g) - 1})
        continue
    pl, n = [], 0
    for col, c in ((2, MAG), (1, YEL)):
        f, bad = fit(g, col)
        report.append(f'{name} {"yellow" if col == 1 else "magenta"}: {len(f)} players, {bad} pixels wrong')
        for x, rows in f: pl.append((n, c, x0 + x, y0, rows)); n += 1
    assert n <= 4, f'{name}: {n} players'
    bands.append({'name': name, 'players': pl, 'missiles': None, 'top': y0, 'bottom': y0 + len(g) - 1})
# the DLIs: a line after each picture (its writes done before the next begins: 3 lines at least)
for a, b in zip(bands, bands[1:]): assert b['top'] - a['bottom'] >= 4, (a['name'], b['name'])
dlis = [b['bottom'] + 1 for b in bands]          # (after band k: band k + 1's registers; after the last, band 0's)

# the bitmap's lines in memory: 40 bytes each from BASE, none across a 4K boundary (ANTIC's)
addr, a = [], BASE
for i in range(NL):
    if (a & 0xfff) + 40 > 0x1000: a = (a | 0xfff) + 1
    addr.append(a); a += 40
END = a
assert END <= 0xfffa
flat = bytearray(END - BASE)
for i in range(NL):
    for c in range(40):
        flat[addr[i] - BASE + c] = sum(0x80 >> x for x in range(8) if bm[i][c * 8 + x])
lz = compress(bytes(flat)); assert decompress(lz) == bytes(flat)
open(os.path.join(OUT, 'front_bm.lz'), 'wb').write(lz)

# the text: the C64's rows and columns (its last line, the levels, here how to start: A_1 alone)
TEXT = [(0, 16, 'The Cast'), (1, 16, '--------'), (4, 22, 'Trogg'), (7, 17, 'vs.'), (10, 22, 'Scrubbly'), (15, 22, 'Hooter'),
        (19, 22, 'Poglet'), (22, 6, 'Collect all the keys to win!'), (23, 7, '(C) 1984-2026 Nick Pelling'),
        (24, 6, 'Fire, Space or Start to play')]
def internal(ch):           # (ATASCII to the ROM font's order)
    c = ord(ch)
    return c - 32 if 32 <= c < 96 else c if 96 <= c < 128 else 64 + c if c < 32 else c
B = lambda v: ', '.join(str(x) for x in v)
inc = ['; GENERATED by tools/front.py: the front end\'s screen (front.asm)', f'FRBM = ${BASE:04x}', f'FRDL = ${FRDL:04x}', f'FRNL = {NL}']
dl = []
for i in range(NL):
    lms = i == 0 or addr[i] != addr[i - 1] + 40
    dl.append(f'        .byte ${0x0f | (0x40 if lms else 0) | (0x80 if i in dlis else 0):02x}' + (f'\n        .word ${addr[i]:04x}' if lms else ''))
inc += ['frdlist                             ; (its display list: 220 lines of mode F, from scanline 8)'] + dl + ['        .byte $41', '        .word FRDL',
        'frdlend']
inc += ['frlal   .byte ' + B(x & 255 for x in addr), 'frlah   .byte ' + B(x >> 8 for x in addr)]
inc.append('frtext                              ; (each: the line, the column, the length, the characters)')
for r, c, t in TEXT: inc.append(f'        .byte {TOP + 8 * r}, {c}, {len(t)}, ' + B(internal(ch) for ch in t))
inc.append('        .byte 255')
# the players' graphics (each: its address in the players' memory, length, rows) and each band's
# registers (HPOSP0-3, COLPM0-3, HPOSM0-1: band k's set by the DLI after band k - 1)
inc.append('frpm                                ; (the players\' graphics: address, length, rows)')
regs = []
for b in bands:
    hp, cl = [0] * 4, [0] * 4
    for p, c, x, y, rows in b['players']:
        inc.append(f'        .word PMG0 + $400 + {p} * $100 + {TOPL + y}\n        .byte {len(rows)}, ' + B(rows))
        hp[p], cl[p] = 48 + x // 2, c
    m = (0, 0)
    if b['missiles']:
        mx0, mx1, y, rows = b['missiles']
        inc.append(f'        .word PMG0 + $300 + {TOPL + y}\n        .byte {len(rows)}, ' + B(rows))
        m = (48 + mx0 // 2, 48 + mx1 // 2)
    regs.append(hp + cl + list(m))
inc.append('        .word 0')
for k, nm in enumerate(['frhp0', 'frhp1', 'frhp2', 'frhp3', 'frcl0', 'frcl1', 'frcl2', 'frcl3', 'frhm0', 'frhm1']):
    inc.append(f'{nm:8s}.byte ' + B(r[k] for r in regs) + ('     ; (by band: the bubble, Trogg, the Scrubbly, the Hooter, the Poglet)' if k == 0 else ''))
inc.append(f'FRNB = {len(bands)}')
open(os.path.join(OUT, 'front.inc'), 'w').write('\n'.join(inc) + '\n')
json.dump({'lines': NL, 'topl': TOPL, 'bitmap': [[bm[y][x] for x in range(W)] for y in range(NL)],
           'text': [[TOP + 8 * r, c, [internal(ch) for ch in t]] for r, c, t in TEXT],
           'players': [[p, c, x, y, rows] for b in bands for p, c, x, y, rows in b['players']],
           'missiles': [list(b['missiles']) for b in bands if b['missiles']], 'yel': YEL, 'mag': MAG},
          open(os.path.join(OUT, 'front.json'), 'w'))
print(f'front: bitmap {len(flat)} bytes packed in {len(lz)}; ' + '; '.join(report))
