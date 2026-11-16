# geom.py [LEVEL]: a level's platforms and ladders for Trogg's movement (src/move.asm, the C64's
# play.asm), from the C64 build's geometry.json (c64/build/<level>/: level.mjs), as the C64's
# lvldata.mjs makes them: each platform's x, y (its top) and width, each ladder's x, top, height
# and invisible part above its visible top (ext), and for each 8-pixel column the platforms (the
# last first) and ladders (within 6 pixels) over it. Level pixels: x across, y down from 24 above
# the C64 screen's top (Y0: the C64 map's line 0 is y 24; the Atari's map line is the same as
# the C64's). Also the collision boxes and spans. Writes build/<level>_geom.json (the level's own,
# for levels.py) and build/common_geom.inc (what's the same in every level).
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
LV = sys.argv[1] if len(sys.argv) > 1 else 'A_1'
g = json.load(open(os.path.join(HERE, '..', '..', 'c64', 'build', LV, 'geometry.json')))
P, L = g['plats'], g['lads']
lo, hi = (lambda v: v & 255), (lambda v: (v >> 8) & 255)
def cols(items):
    ncol = -(-g['w'] // 8) + 2; idx, lst = [], []
    for c in range(ncol):
        idx.append(len(lst))
        lst += [i for a, b, i in items if a <= c * 8 + 7 and b >= c * 8]
    idx.append(len(lst)); assert len(lst) <= 255
    return ncol, idx, lst
pn, pcol, plist = cols(sorted([(p['x'], p['x'] + p['w'] - 1, i) for i, p in enumerate(P)], key=lambda t: -t[2]))
_, lcol, llist = cols([(l['x'] - 6, l['x'] + 6, i) for i, l in enumerate(L)])
# Trogg's boxes (collide.asm): each frame's solid pixels' extent from his origin (build/sprites.json:
# sprites.py's first 17 graphics, his frames); each Scrubbly's (picks.json's scrubBox at its place)
SP = json.load(open(os.path.join(HERE, '..', 'build', 'sprites.json')))['graphics'][:17]
def tbox(gr):
    pts = [(x, y) for y, r in enumerate(gr['grid']) for x, c in enumerate(r) if c != 'T']
    return (min(x for x, _ in pts) - gr['xo'], max(x for x, _ in pts) - gr['xo'], min(y for _, y in pts) - gr['yo'], max(y for _, y in pts) - gr['yo'])
tb = [tbox(gr) for gr in SP]
cdir = os.path.join(HERE, '..', '..', 'c64', 'build', LV)
SCJ = json.load(open(os.path.join(cdir, 'scrub.json'))); E = SCJ['placed']
sbx = json.load(open(os.path.join(cdir, 'picks.json'))).get('scrubBox') or {'x0': 0, 'x1': 0, 'y0': 0, 'y1': 0}
# the balloon's and dagger's boxes (kinds 1 and 2): their images' solid pixels from the origin
HZ = json.load(open(os.path.join(cdir, 'picks.json')))['hazards']
def hbox(h):
    pts = [(x, y) for y, r in enumerate(h['grid']) for x, c in enumerate(r) if c >= 0]
    return (min(x for x, _ in pts) - h['xo'], max(x for x, _ in pts) - h['xo'], min(y for _, y in pts) - h['yo'], max(y for _, y in pts) - h['yo'])
hb = [hbox(HZ['IMG_Balloon']), hbox(HZ['IMG_DaggerLR'])]
# The second stage's spans (pick.asm's spans, the C64's): each row's leftmost and rightmost solid
# pixel (255, 255 for an empty row), from the image's left: Trogg's frames (as the Atari draws
# them: sprites.json), the Scrubbly, a gem, a key (picks.json), the balloon, the dagger; and each
# object's image's corner in the level (x, y the C64's: + 24)
def spans(rows, solid):
    out = []
    for r in rows:
        xs = [x for x, c in enumerate(r) if solid(c)]
        out += [xs[0], xs[-1]] if xs else [255, 255]
    return out
PJ = json.load(open(os.path.join(cdir, 'picks.json')))
PK, GR = PJ['picks'], PJ['grids']
sb = lambda n, v: f'{n:<10}.byte ' + ', '.join(str(x) for x in v)
spanout = []
TU = [2, 6] + list(range(2, len(SP)))       # (frames 0 and 1, standing, never shown: walking's first instead)
for i, gr in enumerate(SP):
    if i >= 2: spanout.append(sb(f'tsp{i}', spans(gr['grid'], lambda c: c != 'T')))
spanout += ['tspl      .byte ' + ', '.join(f'<tsp{i}' for i in TU),
            'tsph      .byte ' + ', '.join(f'>tsp{i}' for i in TU)]
solid = lambda c: c >= 0
spanout += [sb('scrsp', spans(GR['IMG_Scrubbly'], solid) if 'IMG_Scrubbly' in GR else [255, 255]),
            f'SCRH = {len(GR["IMG_Scrubbly"]) if "IMG_Scrubbly" in GR else 1}',
            sb('gemsp', spans(GR['IMG_Gem'], solid) if 'IMG_Gem' in GR else [255, 255]),
            sb('keysp', spans(GR['IMG_Key'], solid) if 'IMG_Key' in GR else [255, 255]),
            sb('balsp', spans(HZ['IMG_Balloon']['grid'], solid)), sb('dagsp', spans(HZ['IMG_DaggerLR']['grid'], solid)),
            'kspl      .byte <balsp, <dagsp     ; (the balloon\'s, the dagger\'s: their spans, height, corner from the origin)',
            'ksph      .byte >balsp, >dagsp',
            sb('khz', [len(HZ['IMG_Balloon']['grid']), len(HZ['IMG_DaggerLR']['grid'])]),
            sb('kw', [len(HZ['IMG_Balloon']['grid'][0]), len(HZ['IMG_DaggerLR']['grid'][0])]),
            f"ENW = {SCJ['w']}", f"ENH = {SCJ['h']}",
            sb('kxo', [HZ['IMG_Balloon']['xo'], HZ['IMG_DaggerLR']['xo']]), sb('kyo', [HZ['IMG_Balloon']['yo'], HZ['IMG_DaggerLR']['yo']]),
            sb('scil', [lo(p['ax']) for p in E] or [0]), sb('scih', [hi(p['ax']) for p in E] or [0]), sb('scit', [p['ay'] + 24 for p in E] or [0]),
            sb('pkil', [lo(p['left']) for p in PK] or [0]), sb('pkih', [hi(p['left']) for p in PK] or [0]), sb('pkit', [p['top'] for p in PK] or [0]),
            sb('pkh', [len(GR[p['name']]) for p in PK] or [0]),
            'pkspl     .byte ' + (', '.join('<keysp' if p['name'] == 'IMG_Key' else '<gemsp' for p in PK) or '0'),
            'pksph     .byte ' + (', '.join('>keysp' if p['name'] == 'IMG_Key' else '>gemsp' for p in PK) or '0')]
B = lambda name, v: f'{name:<10}.byte ' + ', '.join(str(x) for x in v)
xmax, levh = g['w'] - 10, g['h']
# the level's own (build/<level>_geom.json: levels.py packs each level's into its block) ...
w2 = lambda v: [lo(v), hi(v)]
T = {'plat_xl': [lo(p['x']) for p in P], 'plat_xh': [hi(p['x']) for p in P], 'plat_yl': [lo(p['y']) for p in P],
     'plat_yh': [hi(p['y']) for p in P], 'plat_w': [p['w'] for p in P],
     'lad_xl': [lo(l['x']) for l in L], 'lad_xh': [hi(l['x']) for l in L], 'lad_yl': [lo(l['y']) for l in L],
     'lad_yh': [hi(l['y']) for l in L], 'lad_hl': [lo(l['h']) for l in L], 'lad_hh': [hi(l['h']) for l in L], 'lad_ext': [l['ext'] for l in L],
     'pcol': pcol, 'plist': plist, 'lcol': lcol, 'llist': llist,
     'scbll': [lo(p['ax'] + sbx['x0']) for p in E], 'scblh': [hi(p['ax'] + sbx['x0']) for p in E],
     'scbrl': [lo(p['ax'] + sbx['x1']) for p in E], 'scbrh': [hi(p['ax'] + sbx['x1']) for p in E],
     'scbt': [p['ay'] + 24 + sbx['y0'] for p in E], 'scbb': [p['ay'] + 24 + sbx['y1'] for p in E],
     'scrsp': spans(GR['IMG_Scrubbly'], solid) if 'IMG_Scrubbly' in GR else [],
     'scil': [lo(p['ax']) for p in E], 'scih': [hi(p['ax']) for p in E], 'scit': [p['ay'] + 24 for p in E],
     'pkil': [lo(p['left']) for p in PK], 'pkih': [hi(p['left']) for p in PK], 'pkit': [p['top'] for p in PK],
     'pkh': [len(GR[p['name']]) for p in PK]}
S = {'lv_pcoln': [pn], 'lv_xmax': w2(xmax), 'lv_levh': w2(levh), 'lv_levh1': w2(levh - 1), 'lv_nscr': [len(E)],
     'lv_scrhh': [len(GR['IMG_Scrubbly']) if 'IMG_Scrubbly' in GR else 0], 'lv_enw': [SCJ['w']], 'lv_enh': [SCJ['h']],
     'lv_tsx': w2(g['trogg'][0]), 'lv_tsy': w2(g['trogg'][1])}
json.dump({'T': T, 'S': S}, open(os.path.join(HERE, '..', 'build', f'{LV}_geom.json'), 'w'))
# ... and what's the same in every level (build/common_geom.inc: Trogg's boxes and spans, the
# balloon's and dagger's, a gem's and a key's spans)
out = ['; made by tools/geom.py: what\'s the same in every level',
       B('tbx0', [b[0] & 255 for b in tb]), B('tbx1', [b[1] & 255 for b in tb]),
       B('tby0', [b[2] & 255 for b in tb]), B('tby1', [b[3] & 255 for b in tb]),
       B('hbx0', [h[0] & 255 for h in hb]), B('hbx1', [h[1] & 255 for h in hb]),
       B('hby0', [h[2] & 255 for h in hb]), B('hby1', [h[3] & 255 for h in hb]),
       *[l for l in spanout if l.split()[0] in ('gemsp', 'keysp', 'balsp', 'dagsp', 'kspl', 'ksph', 'khz', 'kw', 'kxo', 'kyo', 'tspl', 'tsph') or l.startswith('tsp')]]
open(os.path.join(HERE, '..', 'build', 'common_geom.inc'), 'w').write('\n'.join(out) + '\n')
print(f'{LV}: {len(P)} platforms, {len(L)} ladders')
