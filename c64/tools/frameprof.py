# Profiles a whole frame's work in play, in VICE: a --profile build (CIA 2's timer A stamped at
# each stage of nextframe, from the border's request on: frak64.asm's pst) playing a key script
# (build.mjs --keys; tools/autoplay.py makes one), its records (a ring at $e000) saved every couple
# of seconds and joined up. Times are as the frame sees them: the interrupts and the VIC's stolen
# cycles included. The budget: the work must be done a frame (19,656 cycles) after the request, or
# the frame is shown again (held).
#   python3 frameprof.py KEYS [SECONDS [X Y]]   (KEYS: a script, or @file holding one; X Y:
#                                                Trogg's start, build.mjs --troggx/--troggy)
# (RAW=file: also each frame's stages, one line each, to that file)
import os, re, subprocess, sys, glob, statistics
DIR = os.path.dirname(os.path.abspath(__file__)); B = os.path.join(DIR, '..', 'build')
keys = sys.argv[1]
if keys.startswith('@'): keys = open(keys[1:]).read().strip()
SECS = float(sys.argv[2]) if len(sys.argv) > 2 else 30
opts = ['--troggx', sys.argv[3], '--troggy', sys.argv[4]] if len(sys.argv) > 4 else []
subprocess.run(['node', os.path.join(DIR, 'build.mjs'), '--nopack', '--profile', '--keys', keys] + opts, check=True, capture_output=True)
snap = os.path.join(B, 'snap'); os.makedirs(snap, exist_ok=True)
for f in glob.glob(os.path.join(snap, 'p*.bin')): os.remove(f)
cmds = []
for i in range(int(SECS / 2)): cmds += ['wait 2', 'save "%s" 0 e000 fdff' % os.path.join(snap, 'p%03d.bin' % i)]
subprocess.run(['python3', os.path.join(DIR, 'vice.py'), '2'] + cmds, capture_output=True)
STAGES = ['wait', 'gametick', 'decide', 'trogset', 'yoyoset', 'frakset', 'strset', 'replay', 'game', 'sort', 'update']
recs = {}
for f in sorted(glob.glob(os.path.join(snap, 'p*.bin'))):
    d = open(f, 'rb').read()[2:]
    for k in range(0, len(d) - 31, 32):
        r = d[k:k + 32]
        if not any(r): continue
        st = [r[i] | r[i + 1] << 8 for i in range(0, 24, 2)]
        seq = r[31] | r[30] << 8
        recs[seq] = dict(dt=[(st[i] - st[i + 1]) & 0xffff for i in range(11)], tot=(st[0] - st[11]) & 0xffff,
                         frames=r[24], held=r[25], tstate=r[26], dead=r[27], won=r[28], yolen=r[29])
if not recs: sys.exit('no records (VICE, or the build?)')
seqs = sorted(recs)
lo, hi = seqs[0], seqs[-1]
frames = sum((recs[b]['frames'] - recs[a]['frames']) & 255 for a, b in zip(seqs, seqs[1:]) if b == a + 1)
print(f'{len(seqs)} frames recorded (game ticks {lo}-{hi}: {hi - lo + 1 - len(seqs)} missed between saves)')
tot = [recs[s]['tot'] for s in seqs]
held = sum((recs[b]['held'] - recs[a]['held']) & 255 for a, b in zip(seqs, seqs[1:]) if b == a + 1)
BUDGET = 19656
over = sum(t > BUDGET for t in tot)
print(f'request to done: average {statistics.mean(tot):.0f} cycles, median {statistics.median(tot):.0f}, worst {max(tot)}; '
      f'over a frame {over} ({100 * over / len(tot):.1f}%)')
print(f'frames shown {frames} for {len(seqs) - 1} game ticks: {frames - len(seqs) + 1} held ({100 * (frames - len(seqs) + 1) / frames:.1f}%; the held counter: {held})')
q = sorted(tot)
print('  percentiles: ' + ', '.join(f'{p}% {q[min(len(q) - 1, len(q) * p // 100)]}' for p in (50, 75, 90, 95, 99)))
print('by stage (cycles, as the frame sees them): average, worst')
for i, n in enumerate(STAGES):
    v = [recs[s]['dt'][i] for s in seqs]
    print(f'  {n:9} {statistics.mean(v):7.0f} {max(v):7}')
print('the costliest frames:')
for s in sorted(seqs, key=lambda s: -recs[s]['tot'])[:12]:
    r = recs[s]
    print(f'  tick {s}: {r["tot"]} (state {r["tstate"]}, dead {r["dead"]}, won {r["won"]}, yoyo {r["yolen"]}): ' +
          ', '.join(f'{n} {r["dt"][i]}' for i, n in enumerate(STAGES) if r['dt'][i] > 300))
if os.environ.get('RAW'):
    with open(os.environ['RAW'], 'w') as o:
        o.write('tick total ' + ' '.join(STAGES) + ' state dead won yoyo\n')
        for s in seqs:
            r = recs[s]; o.write(f'{s} {r["tot"]} ' + ' '.join(map(str, r['dt'])) + f' {r["tstate"]} {r["dead"]} {r["won"]} {r["yolen"]}\n')
