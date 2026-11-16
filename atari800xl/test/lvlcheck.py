# lvlcheck.py DIR LBL LEVEL: the level's block in a memory dump saved by tour.mjs once the level's
# started, against the tools' tables (build/<level>_geom.json, _screen.json): every table, the
# ones lvderive works out included, and the patch cells with their codes both ways
import sys, os, json, glob
B = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'build')
d, lbl, lv = sys.argv[1:4]
L = {}
for l in open(lbl):
    f = l.split()
    if len(f) >= 3 and f[1] == '=':
        try: L[f[0]] = int(f[2][1:], 16) if f[2].startswith('$') else int(f[2])
        except ValueError: pass
m = open(sorted(glob.glob(os.path.join(d, '*.mem')))[-1], 'rb').read()
g, s = json.load(open(os.path.join(B, f'{lv}_geom.json'))), json.load(open(os.path.join(B, f'{lv}_screen.json')))
bad = 0
for n, v in {**g['T'], **s['T'], **g['S'], **s['S']}.items():
    got = list(m[L[n]:L[n] + len(v)])
    if got != v: bad += 1; print(f'{n}: {got[:12]}... want {v[:12]}...')
p = L['pkc']
for k, c in enumerate(s['cells']):
    ptr = m[L['pkpl'] + k] | m[L['pkph'] + k] << 8
    if c and ptr != p: bad += 1; print(f'object {k}: pointer {ptr:04x}, want {p:04x}')
    if list(m[p:p + len(c)]) != c: bad += 1; print(f'object {k}: cells differ')
    p += len(c)
print(f'{lv}: {"all tables as the tools make them" if not bad else f"{bad} differ"}')
sys.exit(1 if bad else 0)
