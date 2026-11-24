#!/usr/bin/env python3
"""Cross-check the editor's JavaScript scheduler (editor/scheduler.js) and row model (editor/mirrorrows.js)
against the Python ones:
random mirrored rows (8-pixel platform segments from tools/mirrorrows.py, ladders, coloured items)
are scheduled in Python, then by the JS port under Node; every answer must agree.

    python3 atarivcs/tools/checkScheduler.py [CASES]"""
import json, os, random, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import feasibility as F
import mirrorrows as M
F._setup()
random.seed(2600)
N = int(sys.argv[1]) if len(sys.argv) > 1 and not sys.argv[1].startswith('--') else 2000
G = [x for x in range(19, 119, 3)]
cases = []
for n in range(N):
    lit = set()
    for _ in range(random.choice((0, 1, 1, 2))):
        a = random.randrange(2, 18); w = random.randrange(1, 5)
        for u in range(a, min(18, a + w)):
            lit |= {2 * u, 2 * u + 1}
    prev = random.choice([None, {'col': 'stripe', 'PF1': random.randrange(256), 'PF2': random.randrange(256)}, {'col': 'bg', 'PF1': 0, 'PF2': 0}])
    xs = sorted(random.sample(G, random.choice((0, 1, 2, 2, 3))))
    if any(b - a < 21 for a, b in zip(xs, xs[1:])):
        continue
    objs = []
    oi = 0
    for x in xs:
        if random.random() < 0.25:
            objs.append({'x': x, 'gfx': ['tbl', 'G%d' % oi], 'col': ['tbl', 'C%d' % oi]}); oi += 1
        else:
            objs.append({'x': x, 'gfx': ['tbl', 'Lad'], 'col': ['imm', 0]})
    for way, tk, endst in M.tasks(lit, prev):
        try:
            code, end = F.schedule(((0, 0, 0), (0, 0, 0)), ((0, 0, 0), (0, 0, 0)),
                                   [(o['x'], tuple(o['gfx']), tuple(o['col'])) for o in objs], ('imm', 0), True,
                                   xs[-1] if xs else None, t0=10, end_limit=55, extra=list(tk))
            py = {'end': end, 'strobes': F.strobe_cycles(code, 10)}
        except ValueError:
            py = None
        cases.append({'objs': objs, 'extra': [[lo, hi, list(ld), reg] for lo, hi, ld, reg in tk], 'py': py,
                      'lit': sorted(lit), 'prev': prev, 'way': way})
path = os.path.join(HERE, 'scheduler_cases.json')
json.dump(cases, open(path, 'w'))
js = r'''
const { schedule } = require(process.argv[1]);
const M = require(process.argv[3]);
const norm = tk => JSON.stringify(tk.map(([lo, hi, ld, reg]) => [lo, hi, ld[0], reg]).sort());
let taskAgree = 0;
const cases = JSON.parse(require('fs').readFileSync(process.argv[2], 'utf8'));
let agree = 0, bad = [];
for (const c of cases) {
  const xs = c.objs.map(o => o.x);
  const r = schedule(c.objs, ['imm', 0], true, xs.length ? xs[xs.length - 1] : null, 10, 55, c.extra);
  if ((r === null) === (c.py === null) && (!r || JSON.stringify(r.strobes) === JSON.stringify(c.py.strobes))) agree++; else bad.push({ c, js: r });
  const ways = M.tasks(new Set(c.lit), c.prev);
  const mine = ways.filter(w => w[0] === c.way).map(w => norm(w[1]));
  if (mine.includes(norm(c.extra))) taskAgree++; else if (bad.length < 3) bad.push({ taskMismatch: c, js: ways });
}
console.log(JSON.stringify({ n: cases.length, agree, taskAgree, fits: cases.filter(c => c.py).length, bad: bad.slice(0, 3) }));
'''
out = subprocess.run(['node', '-e', js, os.path.join(HERE, '..', 'editor', 'scheduler.js'), path,
                      os.path.join(HERE, '..', 'editor', 'mirrorrows.js')], capture_output=True, text=True)
print(out.stdout or out.stderr)
os.remove(path)
