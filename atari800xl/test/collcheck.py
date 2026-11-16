# collcheck.py DIR [LBL]: the collisions against a reference, in each memory dump saved by tour.mjs
# (EVERY=1 best; only those where the main program's waiting for the VBI, ready 1: mid-tick, he
# may have moved and not yet been tested; for a death, any once he's been dead a tick: nothing
# moves while he's dead). The reference: Trogg's image (his frame as drawn, sprites.json, its corner his
# origin less xo, yo) against each Scrubbly's, balloon's, dagger's and gem's and key's not yet
# picked up, row by row: a hit if on a row both have, their solid extents (leftmost to rightmost
# solid pixel) meet (the C64's second stage, which the box test only filters for). After a tick
# the program has acted on every hit: so in a dump where he's alive no deadly thing may hit him
# and no gem or key not picked up may touch him. Each death is listed with what hit him (in the
# dump where he's just died he and the hazards are still from then), or none: a fall.
import sys, os, glob, json
HERE = os.path.dirname(os.path.abspath(__file__)); B = os.path.join(HERE, '..', 'build')
C = os.path.join(HERE, '..', '..', 'c64', 'build')
L = {}
for l in open(sys.argv[2] if len(sys.argv) > 2 else os.path.join(B, 'trogg8x4.lbl')):
    f = l.split()
    if len(f) >= 3 and f[1] == '=':
        try: L[f[0]] = int(f[2][1:], 16) if f[2].startswith('$') else int(f[2])
        except ValueError: pass
lv = os.environ.get('LEVEL', 'A_1')
G = json.load(open(os.path.join(B, 'sprites.json')))['graphics']
PJ = json.load(open(os.path.join(C, lv, 'picks.json'))); SC = json.load(open(os.path.join(C, lv, 'scrub.json')))['placed']
def ext(grid, solid):        # each row's (left, right) or None
    out = []
    for r in grid:
        xs = [x for x, c in enumerate(r) if solid(c)]
        out.append((xs[0], xs[-1]) if xs else None)
    return out
TS = [ext(g['grid'], lambda c: c != 'T') for g in G[:17]]
SOL = lambda c: c >= 0
SCR = ext(PJ['grids'].get('IMG_Scrubbly', [[-1]]), SOL)
PKS = {n: ext(PJ['grids'][n], SOL) for n in ('IMG_Key', 'IMG_Gem') if n in PJ['grids']}
HZ = [PJ['hazards']['IMG_Balloon'], PJ['hazards']['IMG_DaggerLR']]
HZS = [ext(h['grid'], SOL) for h in HZ]
C2A = [12, 13, 14, 10, 11, 16, 15, 2, 3, 4, 5, 6, 7, 8, 9]      # (the C64's frame numbers to sprites.py's)
def box(a, ax, ay, b, bx, by):   # (the first stage alone: the extents' boxes)
    ra = [r for r in a if r]; rb = [r for r in b if r]
    ya = [i for i, r in enumerate(a) if r]; yb = [i for i, r in enumerate(b) if r]
    return (ax + min(r[0] for r in ra) <= bx + max(r[1] for r in rb) and bx + min(r[0] for r in rb) <= ax + max(r[1] for r in ra)
            and ay + ya[0] <= by + yb[-1] and by + yb[0] <= ay + ya[-1])
def hit(a, ax, ay, b, bx, by):
    for i, ra in enumerate(a):
        j = ay + i - by
        if ra and 0 <= j < len(b) and b[j]:
            if ax + ra[0] <= bx + b[j][1] and bx + b[j][0] <= ax + ra[1]: return True
    return False
bad = deaths = picks = near = 0
prev = None; pdead = 0; pending = False
for p in sorted(glob.glob(os.path.join(sys.argv[1], '*.mem'))):
    m = open(p, 'rb').read(); w = lambda n: m[L[n]] | m[L[n] + 1] << 8
    tx, gy, dead = w('tx'), w('gy'), m[L['dead']]
    idle = m[L['ready']]                   # (else the main program's mid-frame, maybe mid-tick)
    if dead and not pdead: pending = True     # (a death: checked once he's been dead a tick, all still)
    pdead = dead
    if not idle and not (pending and 0 < dead < 50): continue
    if gy >= 32768: gy -= 65536
    g = C2A[m[L['tfr']]]; me = (TS[g], tx - G[g]['xo'], gy - G[g]['yo'])
    deadly = [f'SCRUB{k}' for k, s in enumerate(SC) if hit(*me, SCR, s['ax'], s['ay'] + 24)]
    boxed = [k for k, s in enumerate(SC) if box(*me, SCR, s['ax'], s['ay'] + 24)]
    for i in range(6):
        k = m[L['oact'] + i]
        if k:
            x = m[L['oxl'] + i] | m[L['oxh'] + i] << 8; y = m[L['oy'] + i] | m[L['oyh'] + i] << 8
            x -= 65536 if x >= 32768 else 0; y -= 65536 if y >= 32768 else 0
            if hit(*me, HZS[k - 1], x - HZ[k - 1]['xo'], y - HZ[k - 1]['yo']): deadly.append(f"{'BD'[k - 1]}{i}")
            if box(*me, HZS[k - 1], x - HZ[k - 1]['xo'], y - HZ[k - 1]['yo']): boxed.append(i)
    gone = w('pkgone')
    touch = [i for i, q in enumerate(PJ['picks']) if not gone >> i & 1 and hit(*me, PKS[q['name']], q['left'], q['top'])]
    name = os.path.basename(p)[:-4]
    if prev is not None and gone & ~prev[1]: picks += bin(gone & ~prev[1]).count('1')
    if idle and dead == 0 and boxed and not deadly: near += 1
    if idle and dead == 0 and m[L['won']] == 0 and (deadly or touch):
        bad += 1; print(f'{name}: alive but hit by {deadly} / touching picks {touch} (x {tx} y {gy})')
    if pending and 0 < dead < 50:
        deaths += 1; pending = False
        print(f'{name}: died, ' + (f'hit by {deadly}' if deadly else f'nothing deadly touching: a fall (x {tx} y {gy} state {m[L["tstate"]]})'))
    prev = (dead, gone)
print(f'{len(glob.glob(os.path.join(sys.argv[1], "*.mem")))} dumps: {deaths} deaths, {picks} gems or keys picked up; {near} idle dumps alive where the boxes alone would have killed him; {bad} disagreements')
sys.exit(1 if bad else 0)
