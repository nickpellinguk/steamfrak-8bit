# Checks collide (src/collide.asm: boxes, then spans) against a reference in Python: thousands of random
# situations, Trogg (any frame) near a random Scrubbly, gem, key, balloon or dagger, some Scrubblies
# yo-yoed off, some balloons and daggers out; the program's collide run in a 6502 emulator (py65) on each, and whether he
# dies and which gem or key he's touching compared with the reference's: its boxes from the same
# tables (build/collide.inc), its spans from the images themselves. Also counts the hits of each
# kind (so the test is seen to reach them), the boxes that touch with no spans meeting, and the
# situations where spans and an exact pixel test disagree (what the spans approximate).
#   python3 collidetest.py [N]      (the build as last made, with the balls: not --noballs)
import os, random, re, sys
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__))); import c64img   # (the level unpacked: loadlevel)
from py65.devices.mpu6502 import MPU
DIR = os.path.dirname(os.path.abspath(__file__)); B = os.path.join(DIR, '..', 'build')
N = int(sys.argv[1]) if len(sys.argv) > 1 else 5000
lbl = {}
for line in open(os.path.join(B, 'frak64.lbl')):
    m = re.match(r'^(\w+)\s*=\s*(\$?)([0-9a-fA-F]+)', line)
    if m: lbl[m.group(1)] = int(m.group(3), 16 if m.group(2) else 10)
tab, const = {}, {}
for line in [l for f in ('collide.inc', 'lvtab.inc') for l in open(os.path.join(B, f))]:
    m = re.match(r'^(\w+)\s+\.byte (.*)', line)
    if m and re.fullmatch(r'[\d, ]+', m.group(2).strip()): tab[m.group(1)] = [int(v) for v in m.group(2).split(',')]
    m = re.match(r'^(\w+)\s*=\s*(\d+)', line)
    if m: const[m.group(1)] = int(m.group(2))
s8 = lambda v: v - 256 if v > 127 else v
NS, NP = len(tab['scbt']), const['NP']
NB = int(re.search(r'^NB\s*=\s*(\d+)', open(os.path.join(DIR, '..', 'src', 'frak64.asm')).read(), re.M).group(1))
scrub = [(tab['scbll'][i] | tab['scblh'][i] << 8, tab['scbrl'][i] | tab['scbrh'][i] << 8, tab['scbt'][i], tab['scbb'][i]) for i in range(NS)]
picks = [(tab['pkll'][i] | tab['pklh'][i] << 8, tab['pkrl'][i] | tab['pkrh'][i] << 8, tab['pkt'][i], tab['pkb'][i]) for i in range(NP)]
ov = lambda a, b: a[0] <= b[1] and b[0] <= a[1] and a[2] <= b[3] and b[2] <= a[3]
# the second stage, from the images themselves (not the build's tables): Trogg's frames as the C64
# shows them, the Scrubbly, gem and key as the mock-up draws them, the ball sprite
import json
TJ = json.load(open(os.path.join(B, 'trogg.json'))); PJ = json.load(open(os.path.join(B, 'picks.json')))
SJ = json.load(open(os.path.join(B, 'scrub.json')))
HZ = [PJ['hazards']['IMG_Balloon'], PJ['hazards']['IMG_DaggerLR']]     # (kinds 1 and 2)
def solid(g):                                   # (each row's solid columns)
    return [[x for x, p in enumerate(r) if p >= 0] for r in g]
TS = [solid(fr['shown']) for fr in TJ]; SS = solid(PJ['grids']['IMG_Scrubbly']); HS = [solid(h['grid']) for h in HZ]
def hbox(h):                                     # (a kind's tight box, from its image's corner)
    xs = [x for r in h['grid'] for x, p in enumerate(r) if p >= 0]; ys = [y for y, r in enumerate(h['grid']) if any(p >= 0 for p in r)]
    return min(xs), max(xs), min(ys), max(ys)
HB = [hbox(h) for h in HZ]
KS = {k: solid(v) for k, v in PJ['grids'].items()}
def hit(f, tx, ty, os_, ol, ot, exact=False):  # spans (or, exact: pixels) of his frame f and the object's image at (ol, ot)
    hl, ht = tx - TJ[f]['left'], ty - 34
    for r, xs in enumerate(TS[f]):
        orow = ht + r - ot
        if not xs or not (0 <= orow < len(os_)) or not os_[orow]: continue
        if exact:
            if set(x + hl for x in xs) & set(x + ol for x in os_[orow]): return True
        elif xs[0] + hl <= os_[orow][-1] + ol and os_[orow][0] + ol <= xs[-1] + hl: return True
    return False
scrimg = [(p['ax'], p['ay'] + 24) for p in SJ['placed']]
pkimg = [(p['left'], p['top'], KS[p['name']]) for p in PJ['picks']]

prg = open(os.path.join(B, 'frak64.prg'), 'rb').read()
base = c64img.image(prg)
stub = 0x033c; base[stub:stub + 3] = bytes([0x20, lbl['collide'] & 255, lbl['collide'] >> 8])
random.seed(1)
bad = 0; hits = {'scrubbly': 0, 'ball': 0, 'pick': 0, 'none': 0}
for n in range(N):
    mem = bytearray(base)
    f = random.randrange(15)
    kind = random.choice(['s', 'p', 'b'])
    if kind == 's': o = scrub[random.randrange(NS)]
    elif kind == 'p': o = picks[random.randrange(NP)]
    else: o = (random.randrange(0, 700), 0, random.randrange(30, 240), 0)
    tx = random.randrange(max(0, o[0] - 40), o[0] + 60); ty = random.randrange(max(0, o[2] - 20), o[2] + 90)
    knocked = [random.random() < 0.3 for _ in range(NS)]
    balls = []
    for i in range(NB):
        if random.random() < 0.4 or (kind == 'b' and i == 0):
            bx = o[0] + random.randrange(-30, 30) if kind == 'b' and i == 0 else random.randrange(0, 740)
            by = o[2] + random.randrange(-20, 20) if kind == 'b' and i == 0 else random.randrange(0, 256)
            balls.append((i, random.choice([1, 2]), max(0, bx), max(0, min(255, by))))
    for name, v in (('tx', tx), ('ty', ty)): mem[lbl[name]] = v & 255; mem[lbl[name] + 1] = v >> 8
    mem[lbl['tfr']] = f; mem[lbl['dead']] = 0; mem[lbl['ptouch']] = 0xff; mem[lbl['ptouchn']] = 0
    for i in range(NS): mem[lbl['knocked'] + i] = int(knocked[i])
    for i in range(NB): mem[lbl['oact'] + i] = 0
    for i, k, bx, by in balls:
        mem[lbl['oact'] + i] = k; mem[lbl['oxl'] + i] = bx & 255; mem[lbl['oxh'] + i] = bx >> 8; mem[lbl['oy'] + i] = by; mem[lbl['oyh'] + i] = 0
    mpu = MPU(memory=mem); mpu.pc = stub; mpu.sp = 0xf0; k = 0
    while mpu.pc != stub + 3 and k < 100000: mpu.step(); k += 1
    got = (mem[lbl['dead']] != 0, mem[lbl['ptouch']], mem[lbl['ptouchn']])
    # the reference
    t = (tx + s8(tab['tbx0'][f]), tx + s8(tab['tbx1'][f]), ty + s8(tab['tby0'][f]), ty + s8(tab['tby1'][f]))
    sd = [i for i in range(NS) if not knocked[i] and ov(t, scrub[i])]
    corner = lambda k, bx, by: (bx - HZ[k - 1]['xo'], by - HZ[k - 1]['yo'])
    bd = [(k,) + corner(k, bx, by) for i, k, bx, by in balls if ov(t, (corner(k, bx, by)[0] + HB[k - 1][0], corner(k, bx, by)[0] + HB[k - 1][1], corner(k, bx, by)[1] + HB[k - 1][2], corner(k, bx, by)[1] + HB[k - 1][3]))]
    pd = [i for i in range(NP) if ov(t, picks[i])]
    boxed = bool(sd or bd or pd)
    sh = [i for i in sd if hit(f, tx, ty, SS, *scrimg[i])]
    dies = bool(sh) or any(hit(f, tx, ty, HS[k - 1], cx, cy) for k, cx, cy in bd)
    touched = [] if dies else [i for i in pd if hit(f, tx, ty, pkimg[i][2], pkimg[i][0], pkimg[i][1])]   # (the last noted: the highest)
    want = (dies, touched[-1] if touched else 0xff, len(touched))
    hits['scrubbly' if sh else 'ball' if dies else 'pick' if touched else 'none'] += 1
    if boxed and not (dies or touched): hits['boxes only'] = hits.get('boxes only', 0) + 1
    xd = [i for i in sd if hit(f, tx, ty, SS, *scrimg[i], True)] or [1 for k, cx, cy in bd if hit(f, tx, ty, HS[k - 1], cx, cy, True)]
    xt = [] if xd else [i for i in pd if hit(f, tx, ty, pkimg[i][2], pkimg[i][0], pkimg[i][1], True)]
    if (bool(xd), xt[-1] if xt else 0xff) != want[:2]: hits['spans not pixels'] = hits.get('spans not pixels', 0) + 1
    if got != want:
        bad += 1
        if bad <= 10: print(f'tx {tx} ty {ty} frame {f} knocked {knocked} balls {balls}: program {got}, reference {want}')
print(f'{N} situations: {bad} differ; the reference: {hits}')
