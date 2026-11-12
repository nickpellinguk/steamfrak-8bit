# Plays a key script (build.mjs --keys) and checks where it leaves Trogg: the program's own
# gametick run in a 6502 emulator (py65) for the script's ticks and a second more, against the
# build run in VICE (his state read from its memory once the script's long done, and a screenshot
# then, checked with troggshot.py: he's still by then, so the two agree exactly or not at all).
#   python3 keytest.py 60:-,150:U,30:- [build options]      (keys: L R U D Y, or - for none)
import os, re, subprocess, sys
from py65.devices.mpu6502 import MPU
DIR = os.path.dirname(os.path.abspath(__file__))
B = os.path.join(DIR, '..', 'build')
keys = sys.argv[1]
subprocess.run(['node', os.path.join(DIR, 'build.mjs'), '--nopack', '--keys', keys] + sys.argv[2:], check=True, capture_output=True)
lbl = {}
for line in open(os.path.join(B, 'frak64.lbl')):
    m = re.match(r'^(\w+)\s*=\s*(\$?)([0-9a-fA-F]+)', line)
    if m: lbl[m.group(1)] = int(m.group(3), 16 if m.group(2) else 10)
NAMES = ['tx', 'ty', 'tyf', 'tstate', 'tfr', 'dead'] + [n for n in ('knocked', 'ptouch', 'gemsgot', 'keysgot', 'havecp', 'restarts') if re.search(r'^' + n + r'\b', open(os.path.join(B, 'frak64.lbl')).read(), re.M)]
SIZE = {'tx': 2, 'ty': 2}
def state(rd):
    v = {n: rd(lbl[n]) | (rd(lbl[n] + 1) << 8 if SIZE.get(n) == 2 else 0) for n in NAMES}
    return v
ticks = sum(int(s.split(':')[0]) for s in keys.split(',')) + 50 + 60   # (a restart, and settling)

# ---- py65: the program's gametick, tick after tick
prg = open(os.path.join(B, 'frak64.prg'), 'rb').read()
mem = bytearray(65536); mem[0x0801:0x0801 + len(prg) - 2] = prg[2:]
mem[0xdc00] = mem[0xdc01] = 0xff                    # (no keys, no joystick)
stub = 0x033c; mem[stub:stub + 3] = bytes([0x20, lbl['gametick'] & 255, lbl['gametick'] >> 8])
for t in range(ticks):
    mpu = MPU(memory=mem); mpu.pc = stub; mpu.sp = 0xf0
    n = 0
    while mpu.pc != stub + 3 and n < 200000: mpu.step(); n += 1
    mem[0xdc00] = mem[0xdc01] = 0xff
emu = state(lambda a: mem[a])

# ---- VICE: long after the script, his state, and a screenshot
shot = os.path.join(B, 'keytest.png')
if os.path.exists(shot): os.remove(shot)
secs = 2 + ticks / 45                                # (a game tick a frame, most frames)
cmds = ['m %04x %04x' % (lbl[n], lbl[n] + SIZE.get(n, 1) - 1) for n in NAMES] + ['screenshot "%s" 2' % shot]
out = subprocess.run(['python3', os.path.join(DIR, 'vice.py'), '%.1f' % secs] + cmds, capture_output=True, text=True).stdout
vals = []
for b in out.split('> m ')[1:]:
    v = []
    for line in b.splitlines():
        m = re.match(r'.*>C:[0-9a-f]+\s+((?:[0-9a-f]{2}\s+)+)', line)
        if m: v += [int(x, 16) for x in m.group(1).split()]
    vals.append(v[0] | (v[1] << 8 if len(v) > 1 else 0))
vice = dict(zip(NAMES, vals))
print(f'keys {keys}: py65 {emu}')
print(f'{" " * len("keys " + keys)}  VICE {vice}' + ('  (the same)' if emu == vice else '  DIFFERENT'))
if os.path.exists(shot):
    r = subprocess.run(['python3', os.path.join(DIR, 'troggshot.py'), shot, str(vice['tx']), str(vice['ty']), str(vice['tfr'])], capture_output=True, text=True)
    print('  screenshot: ' + (r.stdout.strip() or r.stderr.strip()[-300:]))
else:
    print('  (no screenshot)')
