# Checks checkpoints (checkcp, restart, cprestore: src/play.asm, src/yoyo.asm) in a 6502 emulator
# (py65): a key (not the last) picked up, Trogg standing: the checkpoint saved; then a gem picked up
# and a Scrubbly knocked off, the timers moved, Trogg moved; then he dies (restart): back where he
# was, the key still gone (its cells as patched), the gem and Scrubbly back (their cells as built),
# the counts and timers as saved, a restart counted, the camera to jump to him in the middle. Then
# the level complete: the pause a second shorter; and after it, the level from the start, no
# checkpoint. Random keys, gems, Scrubblies and places, a few rounds.
#   python3 cptest.py [ROUNDS]      (the build as last made)
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
const = {m.group(1): int(m.group(2)) for m in re.finditer(r'^(\w+)\s*=\s*(\d+)', open(os.path.join(B, 'geometry.inc')).read(), re.M)}
NP, NS = len(tab['pkkind']), len(tab['scrpn'])
NC = int(re.search(r'^NC\s*=\s*(\d+)', open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'build', 'level.inc')).read(), re.M).group(1)); MAPN = 25 * NC     # (the level map's size: build/level.inc)
prg = open(os.path.join(B, 'frak64.prg'), 'rb').read()
base = bytearray(65536); base[0x0801:0x0801 + len(prg) - 2] = prg[2:]
def call(mem, label, x=0):
    stub = 0x033c; mem[stub:stub + 5] = bytes([0xa2, x, 0x20, lbl[label] & 255, lbl[label] >> 8])
    mpu = MPU(memory=mem); mpu.pc = stub; mpu.sp = 0xf0
    while mpu.pc != stub + 5: mpu.step()
def cells(i, n): return [tab['scrplo'][j] | tab['scrphi'][j] << 8 for j in range(i, i + n)]
w16 = lambda m, a, v: (m.__setitem__(a, v & 255), m.__setitem__(a + 1, v >> 8))
r16 = lambda m, a: m[a] | m[a + 1] << 8
keys = [k for k in range(NP) if tab['pkkind'][k] == 2]; gems = [k for k in range(NP) if tab['pkkind'][k] == 1]
random.seed(9); bad = 0
rounds = int(sys.argv[1]) if len(sys.argv) > 1 else 6
for rnd in range(rounds):
    mem = bytearray(base); mem[lbl['pvw']] = mem[lbl['pvw'] + 1] = 0xff
    tops0, bot0 = bytes(mem[lbl['tops']:lbl['tops'] + MAPN]), bytes(mem[lbl['bottoms']:lbl['bottoms'] + MAPN])
    k, gm, sc = random.choice(keys), random.choice(gems), random.randrange(NS)
    tx, ty, face, bt, dt = random.randrange(20, 720), random.randrange(40, 230), random.randrange(2), random.randrange(1, 100), random.randrange(1, 100)
    call(mem, 'pickup', k)
    w16(mem, lbl['tx'], tx); w16(mem, lbl['ty'], ty); mem[lbl['tface']] = face; mem[lbl['tstate']] = 0; mem[lbl['dead']] = 0
    mem[lbl['btim']] = bt; mem[lbl['dtim']] = dt
    due = mem[lbl['savecp']]
    call(mem, 'checkcp')
    saved = (due, mem[lbl['havecp']], mem[lbl['savecp']])
    after = bytes(mem[lbl['tops']:lbl['tops'] + MAPN])            # (the map at the checkpoint)
    call(mem, 'pickup', gm); call(mem, 'knock', sc)
    w16(mem, lbl['tx'], 41); w16(mem, lbl['ty'], 207); mem[lbl['btim']] = 3; mem[lbl['dtim']] = 4
    mem[lbl['dead']] = 1
    call(mem, 'restart')
    got = dict(tx=r16(mem, lbl['tx']), ty=r16(mem, lbl['ty']), face=mem[lbl['tface']], btim=mem[lbl['btim']], dtim=mem[lbl['dtim']],
               keys=mem[lbl['keysgot']], gems=mem[lbl['gemsgot']], restarts=mem[lbl['restarts']], jumping=mem[lbl['jumping']],
               jumpx=r16(mem, lbl['jumpx']), jumpw=mem[lbl['jumpw']], key_gone=mem[lbl['picked'] + k], gem_gone=mem[lbl['picked'] + gm], scrub_gone=mem[lbl['knocked'] + sc])
    jx = max(0, min((NC - 40) * 8, tx - 152))
    want = dict(tx=tx, ty=ty, face=face, btim=bt, dtim=dt, keys=1, gems=0, restarts=1, jumping=1, jumpx=jx, jumpw=jx >> 3, key_gone=1, gem_gone=0, scrub_gone=0)
    mapok = bytes(mem[lbl['tops']:lbl['tops'] + MAPN]) == after
    if saved != (1, 1, 0) or got != want or not mapok:
        bad += 1
        print(f'round {rnd} (key {k}, gem {gm}, Scrubbly {sc}): checkpoint (due, saved, still due) {saved}; map as at the checkpoint {mapok}')
        for n in want:
            if got[n] != want[n]: print(f'   {n}: {got[n]}, want {want[n]}')
    # the level complete now: the pause a second shorter; then the level from the start
    for kk in keys:
        if not mem[lbl['picked'] + kk]: call(mem, 'pickup', kk)
    pause = r16(mem, lbl['wint'])
    for t in range(pause): mem[0xdc00] = mem[0xdc01] = 0xff; call(mem, 'gametick')
    fresh = (mem[lbl['havecp']], mem[lbl['restarts']], r16(mem, lbl['tx']), bytes(mem[lbl['tops']:lbl['tops'] + MAPN]) == tops0)
    if pause != 300 or fresh != (0, 0, const['TSTARTX'], True):
        bad += 1; print(f'round {rnd}: the level complete: pause {pause} (want 300); after it (checkpoint, restarts, his x, the map as built) {fresh}')
print(f'{rounds} rounds: {bad} problems')
