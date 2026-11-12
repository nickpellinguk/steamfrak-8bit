# Checks picking up gems and keys (pickup, src/yoyo.asm) and putting them back (unknock), in a 6502
# emulator (py65): every gem and key picked up, in random orders; after each, the counts, the level
# complete exactly when the last key is, each picked object's cells in the level map holding its
# patch's codes (build/scrpatch.inc); then the restart's unknock, and every cell back as built.
#   python3 picktest.py [ROUNDS]      (the build as last made)
import os, random, re, sys
from py65.devices.mpu6502 import MPU
DIR = os.path.dirname(os.path.abspath(__file__)); B = os.path.join(DIR, '..', 'build')
lbl = {}
for line in open(os.path.join(B, 'frak64.lbl')):
    m = re.match(r'^(\w+)\s*=\s*(\$?)([0-9a-fA-F]+)', line)
    if m: lbl[m.group(1)] = int(m.group(3), 16 if m.group(2) else 10)
tab = {}
for f in ('scrpatch.inc', 'collide.inc'):
    for line in open(os.path.join(B, f)):
        m = re.match(r'^(\w+)\s+\.byte ([\d, ]+)$', line.strip())
        if m: tab[m.group(1)] = [int(v) for v in m.group(2).split(',')]
NP, NKEYS = len(tab['pkkind']), tab['pkkind'].count(2)
prg = open(os.path.join(B, 'frak64.prg'), 'rb').read()
base = bytearray(65536); base[0x0801:0x0801 + len(prg) - 2] = prg[2:]
def call(mem, label, x=0):
    stub = 0x033c; mem[stub:stub + 5] = bytes([0xa2, x, 0x20, lbl[label] & 255, lbl[label] >> 8])
    mpu = MPU(memory=mem); mpu.pc = stub; mpu.sp = 0xf0
    while mpu.pc != stub + 5: mpu.step()
def cells(k):                                  # gem or key k's cells: map offsets, new codes
    i, n = tab['pkpi'][k], tab['pkpn'][k]
    return [(tab['scrplo'][j] | tab['scrphi'][j] << 8, tab['scrpt'][j], tab['scrpb'][j]) for j in range(i, i + n)]
rounds = int(sys.argv[1]) if len(sys.argv) > 1 else 5
random.seed(3); bad = 0
for r in range(rounds):
    mem = bytearray(base)
    for a in ('pvw',): mem[lbl[a]] = mem[lbl[a] + 1] = 0xff     # (no pair up to date: the map alone)
    tops0, bot0 = bytes(mem[lbl['tops']:lbl['tops'] + 2350]), bytes(mem[lbl['bottoms']:lbl['bottoms'] + 2350])
    order = random.sample(range(NP), NP); gems = keys = 0
    for n, k in enumerate(order):
        call(mem, 'pickup', k)
        if tab['pkkind'][k] == 2: keys += 1
        else: gems += 1
        got = (mem[lbl['gemsgot']], mem[lbl['keysgot']], mem[lbl['allkeys']])
        want = (gems, keys, int(keys == NKEYS))
        wrong = [q for k2 in order[:n + 1] for q, t, b in cells(k2) if mem[lbl['tops'] + q] != t or mem[lbl['bottoms'] + q] != b]
        if got != want or wrong:
            bad += 1; print(f'round {r}, after {n + 1} ({"key" if tab["pkkind"][k] == 2 else "gem"} {k}): counts {got}, want {want}; cells wrong {wrong[:5]}')
    call(mem, 'unknock')
    back = mem[lbl['tops']:lbl['tops'] + 2350] == tops0 and mem[lbl['bottoms']:lbl['bottoms'] + 2350] == bot0
    zero = (mem[lbl['gemsgot']], mem[lbl['keysgot']], mem[lbl['allkeys']]) == (0, 0, 0) and not any(mem[lbl['picked']:lbl['picked'] + NP])
    if not (back and zero): bad += 1; print(f'round {r}: after the restart, map back {back}, counts and flags cleared {zero}')
print(f'{rounds} rounds of all {NP} gems and keys ({NKEYS} keys) picked up in random orders, then put back: {bad} problems')
