# Checks the balloons and daggers (hazards, src/hazards.asm) against the BBC version's own code: its
# BANK6 (from ../build/frak.ssd, the labels from ../build/labels.txt) run in a 65C02 emulator
# (py65), spawn_hazards then update_movers each tick, and the C64's hazards in a 6502 emulator,
# from the same random seed, Trogg wandering the same way; each tick, every balloon's and dagger's
# kind (the BBC version's MV_BALLOON 2 and MV_DAGGER 3, the C64's 1 and 2), place (16.8, its
# image's origin) and pause compared. The difficulty is the BBC table's
# entry with the C64's numbers (Hard: 2). The BBC version has 12 slots, the C64 6: the most out at
# once is reported (more than 6 and the C64 would have missed one).
#   python3 hazardtest.py [RUNS [TICKS]]      (the C64 build as last made; the BBC one, ../build.sh)
import ast, os, random, re, sys
from py65.devices.mpu6502 import MPU
from py65.devices.mpu65c02 import MPU as MPU65C02
DIR = os.path.dirname(os.path.abspath(__file__)); B = os.path.join(DIR, '..', 'build'); BB = os.path.join(DIR, '..', '..', 'build')
RUNS = int(sys.argv[1]) if len(sys.argv) > 1 else 20; TICKS = int(sys.argv[2]) if len(sys.argv) > 2 else 600
lbl = {}
for line in open(os.path.join(B, 'frak64.lbl')):
    m = re.match(r'^(\w+)\s*=\s*(\$?)([0-9a-fA-F]+)', line)
    if m: lbl[m.group(1)] = int(m.group(3), 16 if m.group(2) else 10)
bl = ast.literal_eval(open(os.path.join(BB, 'labels.txt')).read().replace('L,', ',').replace('L}', '}'))[0]
ssd = open(os.path.join(BB, 'frak.ssd'), 'rb').read()
def dfs(name):                                  # a file from the disk image: (load address, bytes)
    for i in range(ssd[0x105] // 8):
        if ssd[8 + i * 8:15 + i * 8].decode('latin1').strip() == name:
            e = ssd[0x108 + i * 8:0x110 + i * 8]
            load = e[0] | e[1] << 8; ln = e[4] | e[5] << 8 | ((e[6] >> 4) & 3) << 16; sec = e[7] | (e[6] & 3) << 8
            return load, ssd[sec * 256:sec * 256 + ln]
    raise SystemExit(f'{name} not on the disk')
load6, bank6 = dfs('BANK6')
prg = open(os.path.join(B, 'frak64.prg'), 'rb').read()
NB = int(re.search(r'^NB\s*=\s*(\d+)', open(os.path.join(DIR, '..', 'src', 'frak64.asm')).read(), re.M).group(1))
MAXM = 12; DIFF = 2

def call(mpu_class, mem, addrs):
    stub = 0x033c; code = b''.join(bytes([0x20, a & 255, a >> 8]) for a in addrs)
    mem[stub:stub + len(code)] = code
    mpu = mpu_class(memory=mem); mpu.pc = stub; mpu.sp = 0xf0
    while mpu.pc != stub + len(code): mpu.step()
w16 = lambda mem, a, v: (mem.__setitem__(a, v & 255), mem.__setitem__(a + 1, (v >> 8) & 255))
bad = 0; most = 0
random.seed(5)
for run in range(RUNS):
    seed = random.randrange(1, 65536)
    bm = bytearray(65536); bm[load6:load6 + len(bank6)] = bank6
    bm[bl['difficulty']] = DIFF; bm[bl['is_vert']] = 0; w16(bm, bl['level_h'], 256); w16(bm, bl['rng'], seed)
    bm[bl['bal_timer']] = bm[bl['dag_timer']] = 0
    for i in range(MAXM): bm[bl['mv_active'] + i] = 0
    cm = bytearray(65536); cm[0x0801:0x0801 + len(prg) - 2] = prg[2:]
    w16(cm, lbl['hrng'], seed); cm[lbl['btim']] = cm[lbl['dtim']] = 0
    for i in range(NB): cm[lbl['oact'] + i] = 0
    tx, ty = random.randrange(20, 720), random.randrange(30, 240)
    for t in range(TICKS):
        if random.random() < 0.05: tx = max(10, min(730, tx + random.randrange(-40, 41))); ty = max(20, min(250, ty + random.randrange(-30, 31)))
        for m, labels in ((bm, bl), (cm, lbl)): w16(m, labels['tx'], tx); w16(m, labels['ty'], ty)
        call(MPU65C02, bm, [bl['spawn_hazards'], bl['update_movers']])
        call(MPU, cm, [lbl['hazards']])
        bb = sorted((bm[bl['mv_active'] + i] - 1, bm[bl['mv_xh'] + i] << 16 | bm[bl['mv_xl'] + i] << 8 | bm[bl['mv_xf'] + i],
                     bm[bl['mv_yh'] + i] << 16 | bm[bl['mv_yl'] + i] << 8 | bm[bl['mv_yf'] + i], bm[bl['mv_pause'] + i]) for i in range(MAXM) if bm[bl['mv_active'] + i])
        cc = sorted((cm[lbl['oact'] + i], cm[lbl['oxh'] + i] << 16 | cm[lbl['oxl'] + i] << 8 | cm[lbl['oxf'] + i],
                     cm[lbl['oyh'] + i] << 16 | cm[lbl['oy'] + i] << 8 | cm[lbl['oyf'] + i], cm[lbl['opause'] + i]) for i in range(NB) if cm[lbl['oact'] + i])
        most = max(most, len(bb))
        if bb != cc:
            bad += 1
            if bad <= 5: print(f'run {run} (seed {seed}), tick {t}, Trogg ({tx}, {ty}):\n  BBC {bb}\n  C64 {cc}')
            break
print(f'{RUNS} runs of {TICKS} ticks: {bad} runs differ; at most {most} balloons and daggers out at once (the C64 has {NB} slots)')
