# Profiles the multiplexer exactly: runs the demo (as last built) in VICE, snapshots memory each
# time muxframe starts, then runs muxframe from each snapshot in a 6502 emulator (py65), counting
# CPU cycles (the VIC's stolen cycles not included) by routine and by source line.
#   python3 profile.py [FRAMES [SECONDS [LINES]]]    (defaults 12 frames, from 10 s, 30 lines)
# (WORST=n: also each routine's cycles in the n costliest frames; ENTRY=label: that routine, each
# time it's called, instead of muxframe)
# Needs py65 (pip install py65); build.mjs writes the listing (build/frak64.lst) it maps cycles to.
import bisect, collections, glob, os, re, subprocess, sys
from py65.devices.mpu6502 import MPU
DIR = os.path.dirname(os.path.abspath(__file__))
B = os.path.join(DIR, '..', 'build')
FRAMES = int(sys.argv[1]) if len(sys.argv) > 1 else 12
START = sys.argv[2] if len(sys.argv) > 2 else '10'
SHOW = int(sys.argv[3]) if len(sys.argv) > 3 else 30

lbl = {}
for line in open(os.path.join(B, 'frak64.lbl')):
    m = re.match(r'^(\w+)\s*=\s*(\$?)([0-9a-fA-F]+)', line)
    if m: lbl[m.group(1)] = int(m.group(3), 16 if m.group(2) else 10)
src, labels = {}, []                     # (the listing: each instruction's source; the labels)
for l in open(os.path.join(B, 'frak64.lst')):
    l = l.rstrip('\n')
    if not l.startswith('.'): continue
    f = l.split('\t')
    try: a = int(f[0][1:], 16)
    except ValueError: continue
    if len(f) > 1 and f[1].strip(): src[a] = f[-1].strip()
    m = re.match(r'^([A-Za-z]\w*)', f[-1])
    if m and not f[-1].startswith('.'): labels.append((a, m.group(1)))
labels.sort()
la = [a for a, _ in labels]
entry = {a: r for a, r in labels}
def routine(pc):
    i = bisect.bisect_right(la, pc) - 1
    return labels[i][1] if i >= 0 else '?'

snap = os.path.join(B, 'snap')
os.makedirs(snap, exist_ok=True)
for f in glob.glob(os.path.join(snap, 'm*.bin')): os.remove(f)
ENTRY = os.environ.get('ENTRY', 'muxframe')
cmds = ['break %04x' % lbl[ENTRY]]
for i in range(FRAMES): cmds += ['x', 'save "%s" 0 0000 ffff' % os.path.join(snap, 'm%02d.bin' % i)]
subprocess.run(['python3', os.path.join(DIR, 'vice.py'), START] + cmds, capture_output=True)

byr, byl, tot, each = collections.Counter(), collections.Counter(), [], []
for f in sorted(glob.glob(os.path.join(snap, 'm*.bin'))):
    mem = bytearray(open(f, 'rb').read()[2:])
    stub = 0x7f00                        # (jsr muxframe, in memory nothing else uses)
    mem[stub:stub + 3] = bytes([0x20, lbl[ENTRY] & 255, lbl[ENTRY] >> 8])
    mpu = MPU(memory=mem); mpu.pc = stub; mpu.sp = 0xf0
    c0, n, fr, calls = mpu.processorCycles, 0, collections.Counter(), collections.Counter()
    while mpu.pc != stub + 3 and n < 500000:
        pc, c = mpu.pc, mpu.processorCycles
        if pc in entry: calls[entry[pc]] += 1
        mpu.step()
        d = mpu.processorCycles - c
        byr[routine(pc)] += d; byl[pc] += d; fr[routine(pc)] += d; n += 1
    tot.append(mpu.processorCycles - c0); each.append((fr, calls))
N = len(tot)
if not N: sys.exit('no snapshots (is the build current, and VICE working?)')
print(f'{N} frames: {sum(tot) // N} cycles a frame on average ({min(tot)} to {max(tot)}): {tot}')
print('By routine (a frame, on average):')
for r, c in byr.most_common(25): print(f'  {r:10} {c / N:7.0f}')
for k in sorted(range(N), key=lambda k: -tot[k])[:int(os.environ.get('WORST', 0))]:
    fr, calls = each[k]
    print(f'Frame {k}: {tot[k]} cycles: ' + ', '.join(f'{r} {c}' for r, c in fr.most_common(14)))
    print('  calls: ' + ', '.join(f'{r} {c}' for r, c in sorted(calls.items()) if r in ('place', 'remove', 'sweep', 'evict', 'writerec', 'rng', 'rset', 'rclr')))
print('Busiest lines (a frame, on average):')
for pc, c in byl.most_common(SHOW): print(f'  {pc:04x} {routine(pc):10} {c / N:6.0f}  {src.get(pc, "")[:70]}')
