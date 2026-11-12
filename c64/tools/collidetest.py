# Checks collide (src/collide.asm, the box test) against a reference in Python: thousands of random
# situations, Trogg (any frame) near a random Scrubbly, gem, key or ball, some Scrubblies yo-yoed
# off, some balls out; the program's collide run in a 6502 emulator (py65) on each, and whether he
# dies and which gem or key he's touching compared with the reference's, from the same tables
# (build/collide.inc). Also counts the hits of each kind, so the test is seen to reach them.
#   python3 collidetest.py [N]      (the build as last made, with the balls: not --noballs)
import os, random, re, sys
from py65.devices.mpu6502 import MPU
DIR = os.path.dirname(os.path.abspath(__file__)); B = os.path.join(DIR, '..', 'build')
N = int(sys.argv[1]) if len(sys.argv) > 1 else 5000
lbl = {}
for line in open(os.path.join(B, 'frak64.lbl')):
    m = re.match(r'^(\w+)\s*=\s*(\$?)([0-9a-fA-F]+)', line)
    if m: lbl[m.group(1)] = int(m.group(3), 16 if m.group(2) else 10)
tab, const = {}, {}
for line in open(os.path.join(B, 'collide.inc')):
    m = re.match(r'^(\w+)\s+\.byte (.*)', line)
    if m: tab[m.group(1)] = [int(v) for v in m.group(2).split(',')]
    m = re.match(r'^(\w+)\s*=\s*(\d+)', line)
    if m: const[m.group(1)] = int(m.group(2))
s8 = lambda v: v - 256 if v > 127 else v
NS, NP = len(tab['scbt']), const['NP']
NB = int(re.search(r'^NB\s*=\s*(\d+)', open(os.path.join(DIR, '..', 'src', 'frak64.asm')).read(), re.M).group(1))
scrub = [(tab['scbll'][i] | tab['scblh'][i] << 8, tab['scbrl'][i] | tab['scbrh'][i] << 8, tab['scbt'][i], tab['scbb'][i]) for i in range(NS)]
picks = [(tab['pkll'][i] | tab['pklh'][i] << 8, tab['pkrl'][i] | tab['pkrh'][i] << 8, tab['pkt'][i], tab['pkb'][i]) for i in range(NP)]
ov = lambda a, b: a[0] <= b[1] and b[0] <= a[1] and a[2] <= b[3] and b[2] <= a[3]

prg = open(os.path.join(B, 'frak64.prg'), 'rb').read()
base = bytearray(65536); base[0x0801:0x0801 + len(prg) - 2] = prg[2:]
stub = 0x7f00; base[stub:stub + 3] = bytes([0x20, lbl['collide'] & 255, lbl['collide'] >> 8])
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
            by = o[2] + random.randrange(-20, 20) if kind == 'b' and i == 0 else random.randrange(20, 250)
            balls.append((i, max(0, bx), max(0, min(255, by))))
    for name, v in (('tx', tx), ('ty', ty)): mem[lbl[name]] = v & 255; mem[lbl[name] + 1] = v >> 8
    mem[lbl['tfr']] = f; mem[lbl['dead']] = 0; mem[lbl['ptouch']] = 0xff; mem[lbl['ptouchn']] = 0
    for i in range(NS): mem[lbl['knocked'] + i] = int(knocked[i])
    for i in range(NB): mem[lbl['oact'] + i] = 0
    for i, bx, by in balls:
        mem[lbl['oact'] + i] = 1; mem[lbl['oxl'] + i] = bx & 255; mem[lbl['oxh'] + i] = bx >> 8; mem[lbl['oy'] + i] = by
    mpu = MPU(memory=mem); mpu.pc = stub; mpu.sp = 0xf0; k = 0
    while mpu.pc != stub + 3 and k < 100000: mpu.step(); k += 1
    got = (mem[lbl['dead']] != 0, mem[lbl['ptouch']], mem[lbl['ptouchn']])
    # the reference
    t = (tx + s8(tab['tbx0'][f]), tx + s8(tab['tbx1'][f]), ty + s8(tab['tby0'][f]), ty + s8(tab['tby1'][f]))
    dies = any(not knocked[i] and ov(t, scrub[i]) for i in range(NS))
    if not dies: dies = any(ov(t, (bx + const['BBX0'], bx + const['BBX1'], by - 26 + const['BBY0'], by - 26 + const['BBY1'])) for i, bx, by in balls)
    touched = [] if dies else [i for i in range(NP) if ov(t, picks[i])]           # (the last noted: the highest)
    want = (dies, touched[-1] if touched else 0xff, len(touched))
    hits['scrubbly' if dies and any(not knocked[i] and ov(t, scrub[i]) for i in range(NS)) else 'ball' if dies else 'pick' if touched else 'none'] += 1
    if got != want:
        bad += 1
        if bad <= 10: print(f'tx {tx} ty {ty} frame {f} knocked {knocked} balls {balls}: program {got}, reference {want}')
print(f'{N} situations: {bad} differ; the reference: {hits}')
