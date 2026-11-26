#!/usr/bin/env python3
"""
Feasibility table (REPEAT-MODE playfield; superseded: the game now uses the mirrored playfield and
the editor runs the scheduler live, see PLAN.md): which rows the reusable renderer families can draw.

    python3 atarivcs/tools/feasibility.py [OUT_JSON]

For every playfield variant (which half or halves carry a platform, and in which registers) and
every mix of up to three P1 objects (L = black ladder, rungs from a per-line table; O = coloured
item, graphics and colour from per-line tables), plus up to five ladders on rows without
platforms, it runs the same scheduler the Stella-verified tests use (test/screens2.py: shared
block from cycle 10, last store ending by 55 (two entry points per renderer), A and Y as working registers, X the line index;
strobes at least 21 px apart; the ghost rule; one GRP1 write for consecutive same-graphic
objects) over every position x = 19, 22, ..., 118 and records the layouts that fit, each with its
first and last strobe cycle (for the ghost rule at renderer changes).

Playfield deadlines (repeat mode, PF0 = 0 except where noted):
  left platform:  COLUPF = stripe by the leftmost used register's deadline (PF0 22, PF1 27,
                  PF2 38), left registers by theirs, COLUPF = background after the platform's last
                  register has been shown and before the right half's repeat;
                  'L01' writes PF0 one line ahead (late in the line, for the next line)
  right platform: COLUPF = background before the left copy shows, registers any time up to 53,
                  COLUPF = stripe from cycle 49 (after pixel 79) to 53
  both halves:    COLUPF = stripe by the leftmost left register's deadline; each register used on
                  either side is written for the left (by its deadline) and for the right (PF1
                  39-53, PF2 50-53), with 0 on the side that doesn't use it
"""
import itertools
import json
import os
import sys
from multiprocessing import Pool

HERE = os.path.dirname(os.path.abspath(__file__))
TEST = os.path.join(HERE, '..', 'test')
sys.path.insert(0, TEST)
sys.argv = sys.argv[:1] + ['--lines', '--buffer', '--nomidsync'] + sys.argv[1:]

BG = 0xAA
X = [x for x in range(19, 119) if (x + 47) % 3 == 0]          # to x 118: a strobe ending at 55
SPACING = 21
T0, LIMIT = 10, 55                # two entry points: the last store may end by 55


def _setup():
    global schedule, strobe_cycles
    import screens2 as s2
    # the spare strobe stays: a single-object row parks P1 after its copy (GRP1 is already 0), so
    # its last strobe is late and the next renderer's first strobe cancels the ghost
    # a 'fake' object: an invisible copy (GRP1 = 0) strobed at its own x, colour left alone
    src = s2._src.replace("        if col[0] == 'none':\n            need = False",
                          "        if col[0] in ('none', 'fake'):\n            need = False")
    assert src != s2._src
    ns = dict(s2._ns)
    exec(src, ns)
    ns['FREEY'] = True
    ns2 = dict(s2._ns)
    exec(src.replace("        tasks.append(('spare', prev_end + 3))\n", ""), ns2)
    ns2['FREEY'] = True
    parked, unparked = ns['schedule'], ns2['schedule']

    def schedule(*a, yzero=False, **k):
        # (yzero: Y must hold 0 at the block's end; see screens2)
        ns['YZERO'] = ns2['YZERO'] = yzero
        # park a single object (the spare strobe) where there is room; otherwise unparked
        try:
            return parked(*a, **k)
        except ValueError:
            pass
        try:
            return unparked(*a, **k)
        except ValueError:
            objs = a[2]
            if len(objs) != 1:
                raise
        # a single object that still doesn't fit (e.g. a far-right one beside a left platform,
        # whose writes leave no room for the x 19 copy's early GRP1 clear): an invisible copy
        # strobed further right, at the first x (19 up to the object's x - 21) that fits
        x = objs[0][0]
        for fx in range(19, x - 20, 3):
            try:
                return unparked(a[0], a[1], [(fx, ('imm', 0), ('fake', 0))] + list(objs), *a[3:], **k)
            except ValueError:
                pass
        raise ValueError('no fit')
    strobe_cycles = s2.strobe_cycles


def T(name, lo, hi, reg):
    return (lo, hi, ('lda %s,x' % name, 4), reg)


IMM = lambda v, lo, hi, reg: (lo, hi, ('lda #$%02X' % v, 2), reg)
DEAD = {'PF0': 22, 'PF1': 27, 'PF2': 38}


def variants():
    v = {'none': []}
    for key, regs in (('L1', ['PF1']), ('L12', ['PF1', 'PF2']), ('L2', ['PF2'])):
        first = min(DEAD[r] for r in regs)
        sw = (39, 49) if regs == ['PF1'] else (49, 53)
        v[key] = [T('Stripe', 0, first, 'COLUPF')] + [T('L' + r, 0, DEAD[r], r) for r in regs] + \
                 [IMM(BG, sw[0], sw[1], 'COLUPF')]
    v['L01'] = v['L1'] + [T('LPF0next', 29, 53, 'PF0')]
    for key, regs in (('R1', ['PF1']), ('R12', ['PF1', 'PF2']), ('R2', ['PF2'])):
        hide = min(DEAD[r] for r in regs)
        v[key] = [IMM(BG, 0, hide, 'COLUPF')] + [T('R' + r, 0, 53, r) for r in regs] + \
                 [T('Stripe', 49, 53, 'COLUPF')]
    sides = {'1': ['PF1'], '2': ['PF2'], '12': ['PF1', 'PF2']}
    for lk, lr in sides.items():
        for rk, rr in sides.items():
            used = sorted(set(lr) | set(rr))
            e = [T('Stripe', 0, min(DEAD[r] for r in lr), 'COLUPF')]
            for r in used:
                e.append(T('L' + r, 0, DEAD[r], r) if r in lr else IMM(0, 0, DEAD[r], r))
                win = (39, 53) if r == 'PF1' else (50, 53)
                e.append(T('R' + r, win[0], win[1], r) if r in rr else IMM(0, win[0], win[1], r))
            v['B%s_%s' % (lk, rk)] = e
    # the right half's PF0 (x 80-95): written after the left half's PF0 area has been drawn (29-49)
    # and cleared again by a store ending at exactly 55 (just after pixel 95), so the next line
    # starts with PF0 = 0 and nothing shows at the left edge; nothing in the horizontal blank
    pf0 = [T('RPF0', 29, 49, 'PF0'), IMM(0, 55, 55, 'PF0')]
    for rk, rr in (('', []), ('1', ['PF1']), ('2', ['PF2']), ('12', ['PF1', 'PF2'])):
        e = list(pf0) + [T('R' + r, 0, 53, r) for r in rr]
        if rr:                             # the left copies of PF1/PF2 hidden by the background colour
            e.append(IMM(BG, 0, min(DEAD[r] for r in rr), 'COLUPF'))
            e.append(T('Stripe', 49 if 'PF2' in rr else 39, 49, 'COLUPF'))
        else:                              # PF0 alone: nothing shows on the left, the stripe any time
            e.append(T('Stripe', 0, 49, 'COLUPF'))
        v['R0' + rk] = e
        for lk, lr in sides.items():
            used = sorted(set(lr) | set(rr))
            e = [T('Stripe', 0, min(DEAD[r] for r in lr), 'COLUPF')] + list(pf0)
            for r in used:
                e.append(T('L' + r, 0, DEAD[r], r) if r in lr else IMM(0, 0, DEAD[r], r))
                win = (39, 53) if r == 'PF1' else (50, 53)
                e.append(T('R' + r, win[0], win[1], r) if r in rr else IMM(0, win[0], win[1], r))
            v['B%s_0%s' % (lk, rk)] = e
    return v


def patterns(vkey):
    if vkey == 'none':
        return ['L', 'LL', 'LLL', 'LLLL', 'LLLLL', 'O', 'OO', 'OL', 'LO', 'OLL', 'LOL', 'LLO',
                'OOL', 'OLO', 'LOO']
    return ['', 'L', 'LL', 'LLL', 'O', 'OO', 'OL', 'LO', 'OLL', 'LOL', 'LLO']


def job(args):
    vkey, extra, pat = args
    out = []
    combos = [()] if pat == '' else itertools.combinations(X, len(pat))
    for xs in combos:
        if any(b - a < SPACING for a, b in zip(xs, xs[1:])):
            continue
        objs, oi = [], 0
        for x, k in zip(xs, pat):
            if k == 'L':
                objs.append((x, ('tbl', 'Lad'), ('imm', 0)))
            else:
                objs.append((x, ('tbl', 'G%d' % oi), ('tbl', 'C%d' % oi)))
                oi += 1
        try:
            code, end = schedule(((0, 0, 0), (0, 0, 0)), ((0, 0, 0), (0, 0, 0)), objs, ('imm', 0),
                                 True, xs[-1] if xs else None, t0=T0, end_limit=LIMIT, extra=list(extra))
        except ValueError:
            continue
        st = strobe_cycles(code, T0)
        out.append('%s:%d:%d' % (','.join(map(str, xs)), st[0] if st else 0, st[-1] if st else 0))
    return vkey, pat, out


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    out_path = args[0] if args else os.path.join(HERE, 'feasibility_repeatmode.json')
    vs = variants()
    jobs = [(k, e, p) for k, e in vs.items() for p in patterns(k)]
    with Pool(initializer=_setup) as pool:
        res = pool.map(job, jobs, chunksize=1)
    fits = {}
    for vkey, pat, out in res:
        fits.setdefault(vkey, {})[pat] = out
    data = {
        'grid': X, 'spacing': SPACING, 't0': T0, 'limit': LIMIT,
        'note': 'layouts that fit, as "x1,x2,...:first strobe cycle:last strobe cycle"; '
                'L = ladder, O = coloured item; generated by atarivcs/tools/feasibility.py',
        'fits': fits,
    }
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, 'w') as f:
        json.dump(data, f, separators=(',', ':'))
    for vkey in vs:
        print('%-8s ' % vkey + '  '.join('%s:%d' % (p or '-', len(fits[vkey][p])) for p in patterns(vkey)))
    print('wrote', out_path, os.path.getsize(out_path), 'bytes')
