# sprites.py: the moving graphics for the 8x4 screen, from the Steam version's BBC sprites
# (steamfrak/assets/sprites, STEAMFRAK or ../steamfrak), as build/sprites.inc for 64tass.
#
# Outlines are drawn into spare characters a byte (8 pixels) at a time with no shifting: every
# graphic is stored, for each of 4 shift positions (0, 2, 4, 6 pixels: the colour clocks that
# HSCROL and the players move in), as one byte per 8-pixel window, an index into that shift's
# 256-byte AND and OR tables (so 10 bits: the index and the shift). A pixel is set (black: the
# outline), clear (yellow or magenta: the infill shows through) or transparent; a window is 8 of
# them, and AND has a 1 where transparent, OR a 1 where set. All the graphics share the tables,
# so each shift must have no more than 256 windows: checked here.
#
# Each graphic at each shift is stored a column (8 pixels across) at a time, top to bottom, with
# 3 bytes of index 0 (all transparent) above and below each column (each column's below shared with
# the next's above: a column every height + 3 bytes): a character row's 4 lines then come from 4
# bytes in a row, wherever he starts in it, with nothing to check. Where the
# empty space is, at the sides: for the first and last columns, for each of the 4 lines a
# character row can start on relative to the graphic's top (its top display line & 3), a bit
# for each character row it covers (bit 0 the first), 1 where that column's cell is all
# transparent (skipped).
#
# Player graphics (normal width: 8 two-pixel blocks a byte, for the hardware sprites):
#  - balloons and daggers: an outline (a block on where either pixel is black, so the outline stays
#    closed) and, for balloons, an infill (on where more of its pixels are coloured than
#    transparent; black doesn't count, as the outline is in front); daggers have none;
#  - Trogg's infill: yellow from one player and its missile, magenta from another and its missile
#    (normal width: 8 blocks and 2), each placed where it gets most of his pixels right, a block on
#    where more of its visible (not black) pixels are that colour than aren't (as the C64's
#    tools/infill.mjs); and, for the bands where his outline is on players, his outline in two
#    halves (blocks 0-7 and 8-15 from his left: a block on where either pixel is black) and his
#    infill with holes where the outline's blocks are (the outline's players are behind).
import json, re, os, sys, itertools
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
SF = os.environ.get('STEAMFRAK') or os.path.join(HERE, '..', '..', '..', 'steamfrak')
meta = json.loads(re.search(r'const SPRITE_DATA = (\{.*\});', open(os.path.join(SF, 'js', 'data', 'sprites.js')).read(), re.S).group(1))

def frame(k, f):
    if '|' in k:                      # (a part of a frame: "sprite|first row:end row")
        base, rows = k.split('|'); r0, r1 = map(int, rows.split(':'))
        return frame(base, f)[r0:r1]
    m = meta[k]; im = Image.open(os.path.join(SF, 'assets', 'sprites', k + '.png')).convert('RGBA')
    g = []
    for y in range(m['h']):
        r = []
        for x in range(m['w']):
            R, G, B, A = im.getpixel((f * m['w'] + x, y))
            r.append('T' if A < 128 else 'S' if R + G + B < 100 else 'Y' if (R, G, B) == (255, 255, 0) else 'M' if (R, G, B) == (255, 0, 255) else 'C')
        g.append(r)
    return g

# Trogg's frames, in the order the game numbers them
TROGG = [('SR', 'sTrogg_sr_Beeb', 0), ('SL', 'sTrogg_sl_Beeb', 0)] + \
        [(f'WR{i}', 'sTrogg_wr_Beeb', i) for i in range(4)] + [(f'WL{i}', 'sTrogg_wl_Beeb', i) for i in range(4)] + \
        [('CU0', 'sTrogg_cu_Beeb', 0), ('CU1', 'sTrogg_cu_Beeb', 1), ('CD0', 'sTrogg_cd_Beeb', 0), ('CD1', 'sTrogg_cd_Beeb', 1),
         ('CN', 'sTrogg_cn_Beeb', 0), ('YR', 'sTrogg_yr_Beeb', 0), ('YL', 'sTrogg_yl_Beeb', 0)]
# then the other moving graphics: all of them numbered, compiled and sharing the tables
OTHERS = [('BALLOON', 'sBalloon_Beeb', 0), ('DAGGERLR', 'sDaggerLR_Beeb', 0), ('DAGGERUD', 'sDaggerUD_Beeb', 0),
          ('DAGGER', 'sDagger_Beeb', 0)] + [(f'YOYO{i}', 'sYoyo_Beeb', i) for i in range(4)] + [('FRAK', 'sFrak_Beeb', 0)]
# then the walking frames in parts: his body (rows 0-23, the same in all four of a direction, as the
# BBC version found) and each frame's legs (rows 24-33); the walking frames themselves are drawn as
# the two (trogg8x4.asm's swone), so only the parts are compiled: 2,000 bytes less
PARTS = [(f'W{d}B', f'sTrogg_w{d.lower()}_Beeb|0:24', 0) for d in 'RL'] + \
        [(f'W{d}{i}L', f'sTrogg_w{d.lower()}_Beeb|24:34', i) for d in 'RL' for i in range(4)]
for _, k, _ in PARTS:
    base, rows = k.split('|'); r0, r1 = map(int, rows.split(':'))
    meta[k] = {**meta[base], 'yo': meta[base]['yo'] - r0, 'h': r1 - r0}
GRAPHICS = TROGG + OTHERS + PARTS
# compiled now (the rest counted in the tables, so they'll fit when the game draws them)
USED = ({n for n, _, _ in TROGG} - {'SR', 'SL'} - {f'W{d}{i}' for d in 'RL' for i in range(4)}) | \
       {'BALLOON', 'DAGGERLR', 'YOYO0', 'YOYO1', 'YOYO2', 'YOYO3', 'FRAK'} | {n for n, _, _ in PARTS}
# (the FRAK! bubble: at two shifts only, 0 and 4 pixels, its x a multiple of 4 (trogg8x4.asm's
# fraklist): shifts 2 and 6 share their data, half the bytes; nothing moves while it's up)
HALF = {'FRAK'}
# (standing shows the first walking frame, as in the C64 and BBC versions: SR and SL are only listed)
# (a graphic the same as one before it, pixel for pixel and origin, shares its data: the climbing
# frames are 2 different of 5)
SHOWN = USED | {f'W{d}{i}' for d in 'RL' for i in range(4)}   # (shown: their players' graphics needed)
SAME = {}
for i, (n, k, f) in enumerate(GRAPHICS):
    for m, k2, f2 in GRAPHICS[:i]:
        if m in SHOWN and m not in SAME and frame(k, f) == frame(k2, f2) and (meta[k]['xo'], meta[k]['yo']) == (meta[k2]['xo'], meta[k2]['yo']):
            SAME[n] = m; break
COMP = [n for n, _, _ in GRAPHICS if n in USED and n not in SAME]   # (the compiled: their own numbers, gcix)
assert len(COMP) <= 32, f'{len(COMP)} compiled graphics: the masks\' tables hold 32'
SHIFTS = (0, 2, 4, 6)

def windows(g, s):
    """the graphic at shift s: rows of 8-pixel windows (tuples of 'T', 'S', 'C')"""
    w = len(g[0]); nb = (w + s + 7) // 8
    out = []
    for row in g:
        line = ['T'] * s + ['C' if p in 'YMC' else p for p in row] + ['T'] * 8
        out.append([tuple(line[b * 8:b * 8 + 8]) for b in range(nb)])
    return out

graphics = [frame(k, f) for _, k, f in GRAPHICS]
tables = []
for s in SHIFTS:
    seen = {('T',) * 8: 0}                       # index 0: all transparent
    for g in graphics:
        for row in windows(g, s):
            for wdw in row: seen.setdefault(wdw, len(seen))
    if len(seen) > 256: sys.exit(f'shift {s}: {len(seen)} windows, over 256')
    tables.append(seen)

def blocks(g, on):
    """a byte a line: bit 7 - b set where on(pixel 2b, pixel 2b + 1)"""
    w = len(g[0]); out = []
    for row in g:
        v = 0
        for b in range(8):
            px = [row[x] if x < w else 'T' for x in (2 * b, 2 * b + 1)]
            if on(px): v |= 0x80 >> b
        out.append(v)
    return out

def fit(g, col):
    """player (8 blocks) and missile (2 blocks) offsets for a colour, and each line's bits"""
    w = len(g[0]); nbk = (w + 1) // 2
    def gain(b, row):
        px = [row[x] if 0 <= x < w else 'T' for x in (2 * b, 2 * b + 1)]
        return sum(p == col for p in px) - sum(p not in (col, 'S') for p in px)
    G = {b: [gain(b, row) for row in g] for b in range(-10, nbk + 10)}
    best = None
    for po, mo in itertools.product(range(-8, nbk + 1), repeat=2):
        if set(range(po, po + 8)) & {mo, mo + 1}: continue
        sc = sum(max(0, v) for b in list(range(po, po + 8)) + [mo, mo + 1] for v in G[b])
        if best is None or sc > best[0]: best = (sc, po, mo)
    _, po, mo = best
    pl = [sum(0x80 >> i for i in range(8) if G[po + i][y] > 0) for y in range(len(g))]
    ms = [(2 if G[mo][y] > 0 else 0) | (1 if G[mo + 1][y] > 0 else 0) for y in range(len(g))]
    return po, mo, pl, ms

players = []          # per graphic: (bytes A, bytes B, missile bytes, offset A, offset B, offset MA, offset MB)
outlines = []         # Trogg's: (left half, right half, A holed, B holed, missiles holed)
def holes(bytes_, off, bits, outline_blocks):
    out = []
    for v, ob in zip(bytes_, outline_blocks):
        for i in range(bits):
            if ob >> (15 - (off + i)) & 1 if 0 <= off + i < 16 else False: v &= ~(1 << (bits - 1 - i))
        out.append(v)
    return out
for i, (n, k, f) in enumerate(GRAPHICS):
    g = frame(k, f)
    if i < len(TROGG):
        y = fit(g, 'Y'); m = fit(g, 'M')
        players.append((y[2], m[2], [a | b << 2 for a, b in zip(y[3], m[3])], y[0], m[0], y[1], m[1]))
        w = len(g[0])
        ob = [sum(0x8000 >> b for b in range(16) if 'S' in [row[x] if x < w else 'T' for x in (2 * b, 2 * b + 1)]) for row in g]
        ya, mb = holes(y[2], y[0], 8, ob), holes(m[2], m[0], 8, ob)
        ym, mm = holes(y[3], y[1], 2, ob), holes(m[3], m[1], 2, ob)
        outlines.append(([v >> 8 for v in ob], [v & 255 for v in ob], ya, mb, [a | b << 2 for a, b in zip(ym, mm)]))
    elif len(g[0]) <= 16:
        outline = blocks(g, lambda px: 'S' in px)
        infill = blocks(g, lambda px: sum(p in 'YMC' for p in px) > sum(p == 'T' for p in px)) if n == 'BALLOON' else [0] * len(g)
        players.append((outline, infill, [0] * len(g), 0, 0, 0, 0))
    else:
        players.append(None)   # (too wide for a player: drawn by software only)

# the FRAK! bubble's yellow: one quad-width player (8 blocks of 8 pixels), placed where the fewest
# pixels are wrong, a block on where more of its pixels are yellow than transparent (over its black
# it doesn't show: the outline's in front)
def quad(g):
    w = len(g[0]); best = None
    for o in range(-8, 9, 2):
        rows, wrong = [], 0
        for row in g:
            v = 0
            for b in range(8):
                px = [row[x] if 0 <= x < w else 'T' for x in range(o + 8 * b, o + 8 * b + 8)]
                y, t = sum(p == 'Y' for p in px), sum(p == 'T' for p in px)
                if y > t: v |= 0x80 >> b; wrong += t
                else: wrong += y
            rows.append(v)
        if best is None or wrong < best[0]: best = (wrong, o, rows)
    return best
fq = quad(frame('sFrak_Beeb', 0))
out = ['; GENERATED by tools/sprites.py from the Steam version\'s sprites: do not edit', '']
out += [f'FRAK_YX = {fq[1]}                     ; the bubble\'s yellow: its player\'s left (pixels, from the bubble\'s)',
        'frak_y  .byte ' + ', '.join(map(str, fq[2])) + f'     ; (one quad-width player: {fq[0]} pixels wrong)']
out.append(f'GR_N = {len(GRAPHICS)}')
for i, (n, _, _) in enumerate(GRAPHICS): out.append(f'{"TF" if i < len(TROGG) else "GR"}_{n} = {i}')
out.append('')
for name, per in (('gr_w', lambda k, f, g: len(g[0])), ('gr_h', lambda k, f, g: len(g)),
                  ('gr_xo', lambda k, f, g: meta[k]['xo']), ('gr_yo', lambda k, f, g: meta[k]['yo'])):
    out.append(f'{name:8s}.byte ' + ', '.join(str(per(k, f, frame(k, f))) for _, k, f in GRAPHICS))
# the player graphics: A (a hazard's outline, Trogg's yellow), B (its infill, his magenta), the
# missiles (his: M0 in bits 0-1 yellow, M1 in bits 2-3 magenta), offsets in colour clocks
out.append('gp_ok   .byte ' + ', '.join('1' if p else '0' for p in players) + '     ; 1: has player graphics')
for nm, idx in (('gp_ax', 3), ('gp_bx', 4), ('gp_max', 5), ('gp_mbx', 6)):
    out.append(f'{nm:8s}.char ' + ', '.join(str(p[idx]) if p else '0' for p in players))
for nm, idx in (('gp_a', 0), ('gp_b', 1), ('gp_m', 2)):
    out.append(f'{nm}_lo .byte ' + ', '.join(f'<gp_{SAME.get(n, n)}_{idx}' if p and n in SHOWN else '<gp_none' for (n, _, _), p in zip(GRAPHICS, players)))
    out.append(f'{nm}_hi .byte ' + ', '.join(f'>gp_{SAME.get(n, n)}_{idx}' if p and n in SHOWN else '>gp_none' for (n, _, _), p in zip(GRAPHICS, players)))
out.append('      .if HWOUT                   ; (only when outlines go on players)')
for nm, idx in (('go_l', 0), ('go_r', 1), ('go_ah', 2), ('go_bh', 3), ('go_mh', 4)):
    out.append(f'{nm}_lo .byte ' + ', '.join(f'<go_{SAME.get(n, n)}_{idx}' if n in SHOWN else '<gp_none' for n, _, _ in TROGG) + '     ; Trogg\'s outline on players: halves, holed infill')
    out.append(f'{nm}_hi .byte ' + ', '.join(f'>go_{SAME.get(n, n)}_{idx}' if n in SHOWN else '>gp_none' for n, _, _ in TROGG))
for (n, _, _), o in zip(TROGG, outlines):
    if n not in SHOWN or n in SAME: continue
    for idx in range(5): out.append(f'go_{n}_{idx} .byte ' + ', '.join(map(str, o[idx])))
out.append('      .endif')
out.append('gp_none .byte 0')
for (n, _, _), p in zip(GRAPHICS, players):
    if not p or n not in SHOWN or n in SAME: continue
    for idx in range(3): out.append(f'gp_{n}_{idx} .byte ' + ', '.join(map(str, p[idx])))
# the index data
data, nbs, labels = [], [], []
masks = {'l': [], 'r': []}
for i, (n, k, f) in enumerate(GRAPHICS):
    if n not in USED or n in SAME: continue
    g = frame(k, f)
    for si, s in enumerate(SHIFTS):
        if n in HALF and si & 1:                        # (as the shift before)
            nbs.append(nbs[-1]); labels.append(labels[-1])
            masks['l'] += masks['l'][-4:]; masks['r'] += masks['r'][-4:]
            continue
        ws = windows(g, s); nbs.append(len(ws[0])); labels.append(f'tg_{n}_{si}')
        H = len(ws); nb = len(ws[0])
        assert tables[si][('T',) * 8] == 0
        cols = [0] * 3                                  # (3 transparent bytes above each column and below
        for j in range(nb):                             #  it: each column's below the next's above)
            cols += [tables[si][row[j]] for row in ws] + [0] * 3
        for ph in range(4):
            for side, j in (('l', 0), ('r', nb - 1)):
                m = 0
                for k, r0 in enumerate(range(-ph, H, 4)):
                    px = [p for r in range(r0, r0 + 4) for p in (ws[r][j] if 0 <= r < H else ('T',) * 8)]
                    if all(p == 'T' for p in px): m |= 1 << k
                masks[side].append(m)
        data.append((labels[-1], cols))
out.append('gcix    .byte ' + ', '.join(str(COMP.index(SAME.get(n, n))) if n in USED else '0' for n, _, _ in GRAPHICS) + '     ; each graphic\'s compiled number')
out.append('tg_nb   .byte ' + ', '.join(map(str, nbs)) + '     ; bytes across, by compiled number * 4 + shift')
# (the masks: 4 tables, left and right, low and high bytes, each 4 blocks of 128 by phase, then
# compiled number * 4 + shift)
tab = ['; GENERATED by tools/sprites.py: the page-aligned tables (trogg8x4.asm puts them first, at $0800,', '; so there are no gaps before them)']
for side in 'lr':
    for half, sh in (('lo', 0), ('hi', 8)):
        tab.append(f'        .align $100')
        tab.append(f'te{side}_{half}')
        for ph in range(4):
            vals = [masks[side][gs * 4 + ph] >> sh & 255 for gs in range(len(masks[side]) // 4)]
            vals += [0] * (128 - len(vals))
            tab.append('        .byte ' + ', '.join(map(str, vals)))
out.append('tg_lo   .byte ' + ', '.join(f'<({l} + 3)' for l in labels) + '     ; (column 0\'s first line)')
out.append('tg_hi   .byte ' + ', '.join(f'>({l} + 3)' for l in labels))
out.append('')
for lbl, b in data:
    out.append(f'{lbl}')
    for i in range(0, len(b), 32): out.append('        .byte ' + ', '.join(map(str, b[i:i + 32])))
out.append('')
tab.append('        .align $100')
for nm, bit in (('andtab', 'T'), ('ortab', 'S')):
    tab.append(nm)
    for si, t in enumerate(tables):
        vals = [0] * 256
        for wdw, i in t.items(): vals[i] = sum(0x80 >> x for x in range(8) if wdw[x] == bit)
        if nm == 'andtab':
            for i in range(len(t), 256): vals[i] = 0xff
        tab.append(f'        ; shift {SHIFTS[si]}: {len(t)} windows')
        for i in range(0, 256, 32): tab.append('        .byte ' + ', '.join(map(str, vals[i:i + 32])))
os.makedirs(os.path.join(HERE, '..', 'build'), exist_ok=True)
open(os.path.join(HERE, '..', 'build', 'sprites.inc'), 'w').write('\n'.join(out) + '\n')
open(os.path.join(HERE, '..', 'build', 'sprites_tab.inc'), 'w').write('\n'.join(tab) + '\n')
# and the same as JSON, for the checks
json.dump({'graphics': [{'name': n, 'w': len(frame(k, f)[0]), 'h': len(frame(k, f)), 'xo': meta[k]['xo'], 'yo': meta[k]['yo'],
                      'grid': [''.join(r) for r in frame(k, f)],
                      'players': None if not p else {'a': p[0], 'b': p[1], 'm': p[2], 'ax': p[3], 'bx': p[4], 'max': p[5], 'mbx': p[6]},
                      'outline': None if i >= len(TROGG) else {'l': outlines[i][0], 'r': outlines[i][1], 'ah': outlines[i][2], 'bh': outlines[i][3], 'mh': outlines[i][4]}}
                     for i, ((n, k, f), p) in enumerate(zip(GRAPHICS, players))], 'frak': {'x': fq[1], 'y': fq[2], 'wrong': fq[0]}},
          open(os.path.join(HERE, '..', 'build', 'sprites.json'), 'w'))
print(f'sprites: the same as another: {SAME}')
print('sprites: windows per shift ' + ', '.join(str(len(t)) for t in tables) + f' (of 256); {len(GRAPHICS)} graphics, '
      f'{sum(len(b) for _, b in data)} index bytes')
