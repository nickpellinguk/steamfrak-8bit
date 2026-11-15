# state.py DIR: Trogg's state in each memory dump saved by tour.mjs (tx, gy, tyf, tstate, dead, the
# gems and keys gone, won), from build/trogg8x4.lbl
import sys, os, glob
B = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'build')
L = {}
for l in open(os.path.join(B, 'trogg8x4.lbl')):
    f = l.split()
    if len(f) >= 3 and f[1] == '=':
        try: L[f[0]] = int(f[2][1:], 16) if f[2].startswith('$') else int(f[2])
        except ValueError: pass
w = lambda m, n: m[L[n]] | m[L[n] + 1] << 8
for p in sorted(glob.glob(os.path.join(sys.argv[1], '*.mem'))):
    m = open(p, 'rb').read()
    print(os.path.basename(p)[:-4], f"x {w(m, 'tx')} y {w(m, 'gy')}.{m[L['tyf']]:02d} st {m[L['tstate']]} tv {m[L['tv']] - (256 if m[L['tv']] > 127 else 0)} dead {m[L['dead']]} gone {w(m, 'pkgone'):03x} won {m[L['won']]} scroll {m[L['nscrx']]}")
