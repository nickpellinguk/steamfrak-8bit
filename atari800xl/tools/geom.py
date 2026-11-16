# geom.py [LEVEL]: a level's platforms and ladders for Trogg's movement (src/move.asm, the C64's
# play.asm), from the C64 build's geometry.json (c64/build/<level>/: level.mjs), as the C64's
# lvldata.mjs makes them: each platform's x, y (its top) and width, each ladder's x, top, height
# and invisible part above its visible top (ext), and for each 8-pixel column the platforms (the
# last first) and ladders (within 6 pixels) over it. Level pixels: x across, y down from 24 above
# the C64 screen's top (Y0: the C64 map's line 0 is y 24; the Atari's map line is the same as
# the C64's). Also Trogg's and the Scrubblies' collision boxes. Writes atari800xl/build/<level>_geom.inc.
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
E = json.load(open(os.path.join(cdir, 'scrub.json')))['placed']
sbx = json.load(open(os.path.join(cdir, 'picks.json'))).get('scrubBox') or {'x0': 0, 'x1': 0, 'y0': 0, 'y1': 0}
B = lambda name, v: f'{name:<10}.byte ' + ', '.join(str(x) for x in v)
xmax, levh = g['w'] - 10, g['h']
out = ['; made by tools/geom.py from c64/build/' + LV + '/geometry.json',
       B('plat_xl', [lo(p['x']) for p in P]), B('plat_xh', [hi(p['x']) for p in P]),
       B('plat_yl', [lo(p['y']) for p in P]), B('plat_yh', [hi(p['y']) for p in P]), B('plat_w', [p['w'] for p in P]),
       B('lad_xl', [lo(l['x']) for l in L]), B('lad_xh', [hi(l['x']) for l in L]),
       B('lad_yl', [lo(l['y']) for l in L]), B('lad_yh', [hi(l['y']) for l in L]),
       B('lad_hl', [lo(l['h']) for l in L]), B('lad_hh', [hi(l['h']) for l in L]), B('lad_ext', [l['ext'] for l in L]),
       B('pcol', pcol), B('plist', plist or [0]), B('lcol', lcol), B('llist', llist or [0]),
       B('lv_pcoln', [pn]), B('lv_xmax', [lo(xmax), hi(xmax)]), B('lv_levh', [lo(levh), hi(levh)]),
       B('lv_levh1', [lo(levh - 1), hi(levh - 1)]),
       B('tbx0', [b[0] & 255 for b in tb]), B('tbx1', [b[1] & 255 for b in tb]),
       B('tby0', [b[2] & 255 for b in tb]), B('tby1', [b[3] & 255 for b in tb]),
       f'NSCR = {len(E)}', B('scbll', [lo(p['ax'] + sbx['x0']) for p in E] or [0]), B('scblh', [hi(p['ax'] + sbx['x0']) for p in E] or [0]),
       B('scbrl', [lo(p['ax'] + sbx['x1']) for p in E] or [0]), B('scbrh', [hi(p['ax'] + sbx['x1']) for p in E] or [0]),
       B('scbt', [p['ay'] + 24 + sbx['y0'] for p in E] or [0]), B('scbb', [p['ay'] + 24 + sbx['y1'] for p in E] or [0]),
       f'TSTARTX = {g["trogg"][0]}', f'TSTARTY = {g["trogg"][1]}']
open(os.path.join(HERE, '..', 'build', f'{LV}_geom.inc'), 'w').write('\n'.join(out) + '\n')
print(f'{LV}: {len(P)} platforms, {len(L)} ladders')
