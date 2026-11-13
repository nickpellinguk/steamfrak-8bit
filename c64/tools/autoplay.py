# Makes a key script (build.mjs --keys) that plays A_1 like a busy player, for profiling a frame's
# work in play: the program's own gametick run in a 6502 emulator (py65), greedily choosing, segment
# by segment, among random key segments the one that goes somewhere new, picks things up and knocks
# Scrubblies off (dying now and then is allowed: restarts are part of play).
#   python3 autoplay.py [TICKS [SEED [X Y]]]   (defaults 4000, 1, the level's start; on the build as
#                                     last made: a --keys build, any script; prints the script.
#                                     X Y: Trogg's start, as build.mjs --troggx X --troggy Y)
import os, random, re, sys
from py65.devices.mpu6502 import MPU
DIR = os.path.dirname(os.path.abspath(__file__)); B = os.path.join(DIR, '..', 'build')
lbl = {}
for line in open(os.path.join(B, 'frak64.lbl')):
    m = re.match(r'^(\w+)\s*=\s*(\$?)([0-9a-fA-F]+)', line)
    if m: lbl[m.group(1)] = int(m.group(3), 16 if m.group(2) else 10)
TICKS = int(sys.argv[1]) if len(sys.argv) > 1 else 4000
random.seed(int(sys.argv[2]) if len(sys.argv) > 2 else 1)
prg = open(os.path.join(B, 'frak64.prg'), 'rb').read()
mem = bytearray(65536); mem[0x0801:0x0801 + len(prg) - 2] = prg[2:]
mem[0xdc00] = mem[0xdc01] = 0xff
stub = 0x033c; mem[stub:stub + 3] = bytes([0x20, lbl['gametick'] & 255, lbl['gametick'] >> 8])
KS = lbl['kscrk']; NSC = 5
if len(sys.argv) > 4:
    for n, v in (('tx', int(sys.argv[3])), ('ty', int(sys.argv[4]))): mem[lbl[n]] = v & 255; mem[lbl[n] + 1] = v >> 8
BIT = {'L': 1, 'R': 2, 'U': 4, 'D': 8, 'Y': 16}
def run(m, keys, n):
    # the script's keys come through keytest: one step of n ticks, held from the start
    deaths = 0
    for t in range(n):
        m[lbl['kstep']] = 0; m[lbl['kticks']] = 0
        m[KS] = sum(BIT[c] for c in keys if c in BIT)
        m[lbl['kscrn']] = 255
        d0 = m[lbl['dead']]
        mpu = MPU(memory=m); mpu.pc = stub; mpu.sp = 0xf0
        k = 0
        while mpu.pc != stub + 3 and k < 100000: mpu.step(); k += 1
        if not d0 and m[lbl['dead']]: deaths += 1
    return deaths
r16 = lambda m, a: m[a] | m[a + 1] << 8
seen = set(); far = [0]
def score(m, deaths):
    cell = (r16(m, lbl['tx']) >> 4, r16(m, lbl['ty']) >> 4)
    x = r16(m, lbl['tx'])
    return (0 if cell in seen or deaths else 3) + (0 if deaths else max(0, x - far[0]) / 4) + 20 * (m[lbl['gemsgot']] + m[lbl['keysgot']]) + 12 * sum(m[lbl['knocked']:lbl['knocked'] + NSC]) - 100 * deaths
ACTS = ['R', 'L', 'R', 'L', 'U', 'D', 'RU', 'LU', 'Y', 'RY', 'LY', '-']
script, t = [], 0
while t < TICKS:
    best = None
    for c in range(24):
        a, n = random.choice(ACTS), random.choice([6, 12, 24, 48])
        m = bytearray(mem); d = run(m, a, n)
        d += run(m, '-', 12)                      # (and a while after: the yoyo back, and any
        for k in range(15):                       # fall to its end)
            if m[lbl['tstate']] != 2 or m[lbl['dead']] or d: break
            d += run(m, '-', 10)
        s = score(m, d) + random.random()
        if best is None or s > best[0]: best = (s, a, n)
    _, a, n = best
    run(mem, a, n); script.append(f'{n}:{a}'); t += n
    seen.add((r16(mem, lbl['tx']) >> 4, r16(mem, lbl['ty']) >> 4)); far[0] = max(far[0], r16(mem, lbl['tx']))
    if len(script) % 20 == 0:
        print(f'  {t} ticks: at {r16(mem, lbl["tx"])},{r16(mem, lbl["ty"])}, gems {mem[lbl["gemsgot"]]}, keys {mem[lbl["keysgot"]]}, knocked {sum(mem[lbl["knocked"]:lbl["knocked"] + NSC])}, restarts {mem[lbl["restarts"]]}, places {len(seen)}, furthest {far[0]}', file=sys.stderr)
# (merge repeats)
out = []
for s in script:
    n, a = s.split(':')
    if out and out[-1][1] == a and out[-1][0] + int(n) <= 255: out[-1][0] += int(n)
    else: out.append([int(n), a])
print(','.join(f'{n}:{a}' for n, a in out))
