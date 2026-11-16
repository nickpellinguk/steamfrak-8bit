# hzstate.py DIR [LBL]: the balloons and daggers in each memory dump saved by tour.mjs (kind,
# x, y with their fractions, pause), and Trogg's dying, from the labels
import sys, os, glob
B = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'build')
L = {}
for l in open(sys.argv[2] if len(sys.argv) > 2 else os.path.join(B, 'trogg8x4.lbl')):
    f = l.split()
    if len(f) >= 3 and f[1] == '=':
        try: L[f[0]] = int(f[2][1:], 16) if f[2].startswith('$') else int(f[2])
        except ValueError: pass
for p in sorted(glob.glob(os.path.join(sys.argv[1], '*.mem'))):
    m = open(p, 'rb').read(); g = lambda n, i: m[L[n] + i]
    hz = []
    for i in range(6):
        k = g('oact', i)
        if k:
            x = (g('oxh', i) << 8 | g('oxl', i)) + g('oxf', i) / 256; x -= 65536 if x >= 32768 else 0
            y = (g('oyh', i) << 8 | g('oy', i)) + g('oyf', i) / 256; y -= 65536 if y >= 32768 else 0
            hz.append(f"{'BD'[k - 1]}{i} {x:6.1f},{y:6.1f}" + (f" p{g('opause', i)}" if g('opause', i) else ''))
    print(os.path.basename(p)[:-4], f"btim {g('btim', 0):3} dtim {g('dtim', 0):3} dead {g('dead', 0):2} tx {m[L['tx']] | m[L['tx'] + 1] << 8}", ' | '.join(hz))
