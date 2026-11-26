#!/usr/bin/env python3
"""
Level compiler: one editor screen -> a runnable 4K ROM with the current kernel, and a byte count
of what it really costs (the editor's ROM meter is an estimate).

    python3 atarivcs/levelc/levelc.py [--project=P.json] [--type=N] [--screen=N] [--check] [OUT_DIR]

The row plan comes from the editor itself (levelc/plan.js runs its analysis), so the ROM draws
exactly the rows the editor checked: each run of identical rows is one renderer body (two-line,
carry-shared, X counting lines), scheduled by the same scheduler (tools/feasibility.py) with the
row's timed playfield writes (tools/mirrorrows.py, chosen by the editor). --check runs it in
Stella and compares every line with a model built from the plan.

Layout (v1, before the optimisation pass): data first from $F000 (per-line tables packed so no
indexed read crosses a page, the Trogg strip and frame), then the frame code, the row call list
and the bodies. Runs whose bodies and per-line data are identical share their lines.
"""
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
sys.path.insert(0, os.path.join(ROOT, 'test'))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import feasibility as F  # noqa: E402
import tiatest  # noqa: E402
import screens2  # noqa: E402
import mirrorrows as M  # noqa: E402
import front  # noqa: E402
import timer  # noqa: E402

F._setup()
pad = tiatest.pad
TAIL = ['ldy #0', 'lda (TrogPtr),y', 'tay', 'lda (TroggGfx),y', 'sta GRP0', 'inx']
# a body's timing, tried in turn: the shared block from t0, its last store ending by the limit (less
# the given amount), and whether Y must hold 0 at its end (then the tail needs no LDY #0: 17 cycles,
# else 19, so the block ends a cycle earlier or starts a cycle later)
TIMINGS = ((10, 0, True), (10, 1, False), (11, 0, False))


def opt(name, default=None):
    return next((a.split('=', 1)[1] for a in sys.argv[1:] if a.startswith('--%s=' % name)), default)


def get_plan(outdir):
    path = os.path.join(outdir, 'plan.json')
    cmd = ['node', os.path.join(HERE, 'plan.js'), os.path.join(ROOT, 'editor', 'index.html'), path,
           opt('project', ''), opt('type', '0'), opt('screen', '0')]
    if opt('mover'):                         # --mover=MODE,ROW,X0,X1[,SPEED] (MODE two, lr or rl): a test's
        m = opt('mover').split(',')
        cmd.append(json.dumps(dict(mode=m[0], row=int(m[1]), x0=int(m[2]), x1=int(m[3]), speed=int(m[4]) if len(m) > 4 else 128)))
    subprocess.run(cmd, check=True)
    return json.load(open(path))


def body(name, run):
    """A two-line renderer body for a run (as test/mirror_test.py's), or raise ValueError."""
    objs, k = [], 0
    for o in run['objs']:
        if o['t'] == 'L':
            objs.append((o['x'], ('tbl', 'Lad'), ('imm', 0)))
        else:
            objs.append((o['x'], ('tbl', 'G%d' % k), ('tbl', 'C%d' % k)))
            k += 1
    extra = [(lo, hi, (ld[0], ld[1]), reg) for lo, hi, ld, reg in (run['tasks'] or [])]
    prevcol = tuple(run.get('prevcol') or ('imm', 0))     # P1's colour as the run above left it
    # (the run before the moving platform's first, and before the one below it, ends earlier: the
    # call list writes ENABL after it, before the next run's first line)
    lim = run.get('end_limit', 55)
    for t0, less, yzero in TIMINGS:
        try:
            code, end = F.schedule(((0, 0, 0), (0, 0, 0)), ((0, 0, 0), (0, 0, 0)), objs, prevcol, True,
                                   objs[-1][0] if objs else None, t0=t0, end_limit=lim - less, extra=extra,
                                   yzero=yzero)
            break
        except ValueError:
            continue
    else:
        raise ValueError('no fit')
    flat = [i.strip() for c in code for i in c.split('\n') if i.strip()]
    tail = list(TAIL[1:] if yzero else TAIL)
    n = 66 + t0 - (end + 3 + screens2.ncycles(tail))     # (t0 11: the GRP0 store a cycle later)
    if n < 0:
        raise ValueError('tail does not fit')
    if n == 1:
        tail[-2] = 'sta.w GRP0'
    out = ['%s_i:' % name, 'inx', '%s:' % name, 'sta WSYNC', 'inc TrogPtr', '%s_c:' % name, 'sec',
           'bit $80' if t0 == 10 else 'nop\nnop', '%s_s:' % name] + flat
    # the padding goes before the GRP0 store, so the store always ends at the same late cycle (about
    # 66, pixel 130) whatever the body: every Trogg row then shows on its row's second line and the
    # next row's first, the same for any x up to about 122
    # (a body before the moving platform's ENABL write returns at a fixed cycle (50, or 49 where a
    # 1-cycle pad would be needed), so the call list's write lands at 65-67: pixel 130 or later)
    ret = ['rts']
    if run.get('end_limit'):
        p = 50 - end if 50 - end != 1 else 0
        ret = (pad(p).split('\n') if p > 1 else []) + ['rts']
    out += ['bcs %s_e' % name] + ret + ['%s_e:' % name] + tail[:-2] + ['inx']
    if n > 1:
        out += pad(n).split('\n')
    out += [tail[-2], 'asl', 'sta ENAM0', 'clc', 'jmp %s_s' % name]   # (clc after asl: the carry marks line 2)
    tables = sorted({i.split()[1][:-2] for i in flat if i.startswith(('lda ', 'ldy ')) and i.endswith(',x')})
    return out, tables


def nbytes(code):
    """Assembled size of a body (labels excluded)."""
    total = 0
    for i in code:
        if i.endswith(':'):
            continue
        op = i.split()
        if len(op) == 1:
            total += 1
        elif op[1].startswith('#') or op[1].startswith('('):
            total += 2
        elif op[0] in ('jmp', 'jsr') or op[0].endswith('.w') or op[1].endswith(',x') or op[1].endswith(',y'):
            total += 3 if not op[1].startswith('$8') else 2
        elif op[0] in ('bcs', 'bcc', 'bne', 'beq', 'bpl', 'bmi'):
            total += 2
        else:
            total += 2                       # zero page (TIA registers, RAM)
    return total


def move_maps(plan):
    """The movement maps (as the editor's moveMaps, for one level): index + pool per map."""
    def floor_bits(i):
        v = 0
        for p in plan['platforms']:
            if p['top'] // 3 == i:
                for k in range(max(4, p['b0']), min(35, p['b1']) + 1):
                    v |= 1 << (35 - k)          # 32 cells of 4 px (playfield blocks), x 16-143
        return v

    def ladder_bits(c):
        v = 0
        for l in plan['ladders']:
            if l['x'] <= 19 + 3 * c + 1 < l['x'] + 8 and l['bottom'] > l['top']:
                for b in range(l['top'] // 3, (l['bottom'] - 1) // 3 + 1):
                    v |= 1 << (31 - b)
        return v
    ppool, lpool, pidx, lidx = [0], [0], [], []
    for i in range(32):
        v = floor_bits(i)
        if v not in ppool:
            ppool.append(v)
        pidx.append(4 * ppool.index(v))
    for c in range(36):                # 3 px columns on the P1 grid, x 19 + 3c
        v = ladder_bits(c)
        if v not in lpool:
            lpool.append(v)
        lidx.append(4 * lpool.index(v))
    pb = [b for v in ppool for b in (v >> 24, (v >> 16) & 255, (v >> 8) & 255, v & 255)]
    lb = [b for v in lpool for b in (v >> 24, (v >> 16) & 255, (v >> 8) & 255, v & 255)]
    return pidx, pb, lidx, lb




GHOST = 0x0C                           # the returning meanie's outline: light grey


MV_MODES = {'two': 1, 'lr': 2, 'rl': 3}     # the moving platform: two-way, left to right, right to left
MV_PAUSE, MV_HIDE = 60, 60                  # frames: its pause at each end, and hidden (one-way)


def mover_runs(plan):
    """The moving platform (the ball, 8 px, 6 lines from row mv['row']): the editor gives its rows
    (and the rows just before its first and its last, whose bodies end by cycle 49) runs of their own,
    with the stripe colour and the registers planned for it. The call list writes ENABL before its
    first run's first line (MvOn: 0 while a one-way platform is away) and before the run below it."""
    mv = plan['mover']
    r0, r1 = mv['row'], mv['row'] + 3
    for q in plan['runs']:
        if r0 <= q['r'] < r1:
            q['enabl'] = 'MvOn'
            assert q['r'] + q['n'] <= r1, 'the editor splits runs at the moving platform'
        elif q['r'] == r1:
            q['enabl'] = '#0'
        if q['r'] + q['n'] in (r0, r1):
            q['end_limit'] = 50              # (ldx RunX 3, lda MvOn 3, sta ENABL 3: still WSYNC by 73)


def compile_screen(plan, outdir, game=False):
    if game and plan.get('mover'):
        mover_runs(plan)
    errs = [(r['r'], e) for r in plan['runs'] for e in r['errors']]
    if game:
        errs += [(r['r'], 'rows 0-%d are the timer\'s band: keep them empty' % (timer.TOPROWS - 1))
                 for r in plan['runs'] if r['r'] < timer.TOPROWS and (r['lit'] or r['objs'])]
    if errs:
        raise SystemExit('the screen has rows the editor flags; fix them first:\n' +
                         '\n'.join('  row %d: %s' % (r, e) for r, e in errs[:10]))
    # bodies: one per distinct (row key, timed writes)
    bodies, run_body = {}, []
    for run in plan['runs']:
        bk = run['key'] + json.dumps(run['tasks']) + json.dumps(run.get('prevcol')) + str(run.get('end_limit'))
        if bk not in bodies:
            name = 'B%d' % len(bodies)
            code, tables = body(name, run)
            bodies[bk] = (name, code, tables)
        run_body.append(bodies[bk])
    # collectable items (gems and keys): a bit each in Collected
    # every item can go: gems and keys are collected, the rest are meanies (yoyoed away; touching
    # one kills the Trogg)
    coll = list(range(len(plan['items']))) if game else []
    if len(coll) > 8:
        raise SystemExit('more than 8 items (gems, keys and meanies) on a screen')
    bit = {i: 1 << b for b, i in enumerate(coll)}
    # lines: runs with the same body and the same per-line data (in the tables it reads) share them.
    # A run showing collectable items gets a dataset per combination of them collected (their
    # graphics zeroed); the call list loads its X from RunX+k, set before the kernel from the bits.
    seen, run_x, nlines, data = {}, [], 0, {}
    item_runs = []                         # (run index, [bit per slot], [x per variant])

    def lines_at(name, tables, lines):
        nonlocal nlines
        sig = name + json.dumps([[L.get(t, 0) for t in tables] for L in lines])
        if sig not in seen:
            seen[sig] = nlines
            for k, L in enumerate(lines):
                for t in tables:
                    data.setdefault(t, {})[nlines + k] = L.get(t, 0)
            nlines += len(lines)
        return seen[sig]
    # a yoyoed meanie shows as a dotted outline in light grey until it returns: per item, its graphic
    # by line, then the edge pixels (set, with a clear neighbour), every other one kept
    ghost = {}
    if game:
        shape = {}
        for run in plan['runs']:
            k = 0
            for o in run['objs']:
                if o['t'] != 'L':
                    if o.get('ref') and o['ref'][0] == 'item' and plan['items'][o['ref'][1]]['kind'] not in ('gem', 'key'):
                        for j, L in enumerate(run['lines']):
                            shape.setdefault(o['ref'][1], {})[2 * run['r'] + j] = L.get('G%d' % k, 0)
                    k += 1
        for i, g in shape.items():
            px = lambda y, b: 0 <= b < 8 and g.get(y, 0) >> (7 - b) & 1
            ghost[i] = {y: sum(1 << (7 - b) for b in range(8)
                               if px(y, b) and (b + y // 2) % 2 == 0
                               and not (px(y - 1, b) and px(y + 1, b) and px(y, b - 1) and px(y, b + 1)))
                        for y in g}
    plan['ghost'] = ghost
    for ri, (run, (name, code, tables)) in enumerate(zip(plan['runs'], run_body)):
        slots, k = [], 0
        for o in run['objs']:
            if o['t'] != 'L':
                if o.get('ref') and o['ref'][0] == 'item' and o['ref'][1] in bit:
                    slots.append((k, bit[o['ref'][1]], o['ref'][1]))
                k += 1
        run_x.append(lines_at(name, tables, run['lines']))
        if slots:
            xs = []
            for v in range(1 << len(slots)):
                gone = {kk: it for j, (kk, _, it) in enumerate(slots) if v >> j & 1}
                ls = []
                for j, L in enumerate(run['lines']):
                    L = dict(L)
                    for kk, it in gone.items():
                        gh = ghost.get(it, {}).get(2 * run['r'] + j, 0)
                        L['G%d' % kk] = gh
                        if gh:
                            L['C%d' % kk] = GHOST
                    ls.append(L)
                xs.append(lines_at(name, tables, ls))
            item_runs.append((ri, [b for _, b, _ in slots], xs))
    if nlines > 256:
        raise SystemExit('line index overflow: %d lines' % nlines)
    # data area from $F000, packed: each block is placed at the first address where every byte it
    # defines is free or already holds the same value (tables only define the lines their runs read,
    # so they overlap freely); an indexed table's label must be in the same page as every line it
    # reads (label offset + max line <= 255), so no read crosses a page
    # (--game: two 4K banks, F8. Bank 1, the display: the per-line tables, the Trogg strip, the call
    # list and the bodies. Bank 0, the game: the movement maps, item tables, frames, the game code.)
    mems, labels = {0: {}, 1: {}}, {}
    mem = mems[1]

    def place(name, vals, indexed, bank=1):
        mem = mems[bank]
        xs = sorted(vals)
        lo, hi = xs[0], xs[-1]
        for page in range(0xF000, 0x10000, 0x100):
            for off in (range(0, 256 - hi) if indexed else range(-lo, 256)):
                a = page + off
                if all(mem.get(a + x) in (None, vals[x]) for x in xs):
                    for x in xs:
                        mem[a + x] = vals[x]
                    labels[name] = a
                    return
        raise SystemExit('no room for ' + name)
    # the Trogg strip first (a page's worth, mostly zeros: the tables fill in around it)
    tr = plan['trogg']
    frame = tr['frames'][0]['rows']
    h = len(frame)
    assert h <= 16, 'the Trogg is at most 16 rows (his buffer, $82-$92, is followed by other RAM)'
    strip = [0] * 96 + list(range(1, h + 1)) + [0] * 96
    place('TroggStrip', dict(enumerate(strip)), True)    # one page: inc TrogPtr only steps the low byte
    for t in sorted(data, key=lambda t: -len(data[t])):
        place(t, data[t], True)
    table_bytes = sum(len(d) for d in data.values())
    if game:                               # the timer's font, and P0's fine moves, for the band
        for t, vals in timer.tables().items():   # the labels' and the time's 3 x 7 glyphs
            place(t, dict(enumerate(vals)), True)
        place('HMTab1', {r: (-(r - 6) & 15) << 4 for r in range(15)}, True)
    if game:                               # the front screen's per-line tables (its own loop)
        for t, vals in front.tables().items():
            place(t, dict(enumerate(vals)), True)
    # the Trogg's frames, in the display bank, each a blank byte then its rows (the strip's row
    # indices, 1..h, read them through TroggGfx; no read crosses a page): walking (the hand row's bit
    # 0, the yoyo, off), walking with the yoyo out, climbing
    by = lambda k: next((f for f in tr['frames'] if f.get('set') == k), None)
    fw = (by('walk') or tr['frames'][0])['rows']
    fc = (by('climb') or by('walk') or tr['frames'][0])['rows']
    fy = (by('yoyo') or by('walk') or tr['frames'][0])['rows']
    for name, rws in (('TGfxW', [v & 0xFE for v in fw]), ('TGfxY', fy if game else fw), ('TGfxC', [v & 0xFE for v in fc])):
        place(name, dict(enumerate([0] + [0] * (h - len(rws)) + rws)), True, 1)
    nlad, handup = 0, 0
    if game:
        f0 = tr['frames'][0]
        hand = [i for i, v in enumerate(f0['rows']) if v & 1]
        handup = len(f0['rows']) - 1 - (hand[0] if hand else len(f0['rows']) - 1)   # rows above the feet
        pidx, pb, lidx, lb = move_maps(plan)
        # the game's two frames for now: the first walking one and the first climbing one (the
        # editor keeps the frames in set order: walking, climbing, yoyoing)
        fb = [(r + 1) // 3 if (r + 1) % 3 == 0 else 0xFF for r in range(97)]
        for name, vals in (('PIdx', pidx), ('PPool', pb), ('LIdx', lidx), ('LPool', lb), ('FB', fb), ('Band3', [r // 3 for r in range(128)]),
                           ('Mask8', [0x80 >> i for i in range(8)])):
            place(name, dict(enumerate(vals)), False, 0)
        lad = [b for l in plan['ladders'] if l['bottom'] > l['top']
               for b in (l['x'], l['top'], l['bottom'] - 1)]
        nlad = len(lad) // 3
        place('LadL', dict(enumerate(lad or [0])), False, 0)
        # the runs showing collectable items: their item bits (two slots) and X per variant
        rm1 = [b[0] for _, b, _ in item_runs]
        rm2 = [b[1] if len(b) > 1 else 0 for _, b, _ in item_runs]
        rxv = [x for _, _, xs in item_runs for x in (xs + xs[-1:] * 4)[:4]]
        its = [plan['items'][i] for i in coll]
        for name, vals in (('RM1', rm1), ('RM2', rm2), ('RXV', rxv), ('ItX', [it['x'] for it in its]),
                           ('ItTop', [it['top'] >> 1 for it in its]), ('ItBot', [(it['bottom'] - 1) >> 1 for it in its]),
                           ('ItBit', [1 << b for b in range(len(its))]),
                           ('ItKind', [0 if it['kind'] in ('gem', 'key') else 1 for it in its])):
            place(name, dict(enumerate(vals or [0])), False, 0)
        place('HMTab', {r: (-(r - 6) & 15) << 4 for r in range(15)}, True, 0)   # PosObj's fine move
        maps_bytes = len(pidx) + len(pb) + len(lidx) + len(lb)
    # Trogg pointer: the first body call increments it before reading, so row k reads ptr0 + k + 1;
    # rows feet-h+1 .. feet show frame rows 1..h (strip index 96 .. 95+h)
    ptr0 = labels['TroggStrip'] + 95 - (tr['row'] - h + 1)
    tx = tr['x']

    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['HMP0 = $20', 'HMM0 = $22', 'REFP0 = $0B', 'INPT4 = $0C', 'SWCHA = $280', 'INTIM = $284',
          'TIM64T = $296', 'H = %d' % h,
          'START_X = %d' % tr['x'], 'START_ROW = %d' % tr['row'], 'NLAD = %d' % nlad,
          'NIR = %d' % len(item_runs), 'NITEM = %d' % len(coll), 'KEYMASK = %d' % sum(1 << b for b, i in enumerate(coll) if plan['items'][i]['kind'] == 'key'), 'HANDUP = %d' % handup, 'RunX = $C0', 'FRONT_BG = $%02X' % front.BG, 'FRONT_BG1 = $%02X' % front.BGS[0], 'FRONT_BG2 = $%02X' % front.BGS[1], 'FRONT_BG3 = $%02X' % front.BGS[2], 'FRONT_INK = $%02X' % front.INK,
          'FRONT_FILL = $%02X' % front.FILL, 'TOPROWS = %d' % timer.TOPROWS, 'MUSRAM = $DB', 'AUDC0 = $15', 'AUDC1 = $16', 'AUDF0 = $17',
          'AUDF1 = $18', 'AUDV0 = $19', 'AUDV1 = $1A', 'TWHITE = $%02X' % timer.WHITE, 'TAIL_X = %d' % front.TAIL_P1_X, 'ENABL = $1F', 'RESBL = $14', 'HMBL = $24', 'HMK = %d' % timer.HMK, 'SWCHB = $282', 'HMP1 = $21', 'VDELP0 = $25', 'VDELP1 = $26']
    mv = plan.get('mover') if game else None
    if mv:
        a, b = (mv['x1'], mv['x0']) if mv['mode'] == 'rl' else (mv['x0'], mv['x1'])
        o += ['MV_MODE = %d' % MV_MODES[mv['mode']], 'MV_ROW = %d' % mv['row'], 'MV_A = %d' % a, 'MV_B = %d' % b,
              'MV_DIR = %d' % (1 if b > a else 255), 'MV_SPD = %d' % mv.get('speed', 128),
              'MV_PAUSE = %d' % MV_PAUSE, 'MV_HIDE = %d' % MV_HIDE]
    else:
        o += ['MV_MODE = 0', 'MV_A = 0']
    if game and (('--check' in sys.argv and '--front' not in sys.argv) or plan.get('skipfront')):
        o.append('SKIPFRONT = 1')       # (picture checks of the level start in it)
    assert len(item_runs) <= 40, 'too many runs with items for RunX'
    if game and plan.get('collected'):
        o.append('START_COLL = %d' % sum(bit[i] for i in plan['collected'] if i in bit))
    if game and opt('level'):
        o.append('START_LEVEL = %d' % (int(opt('level')) - 1))   # (checks: SELECT can't be pressed)
    if game and '--hard' in sys.argv:
        o.append('START_HARD = 1')
    if game and '--check' in sys.argv:
        o.append('NOTIMER = 1')         # (picture checks: the time stays 0:00)
    if game and plan.get('yotest'):
        o += ['YOTEST = %d' % plan['yotest'][0], 'YOFACE = %d' % plan['yotest'][1]]
    o += ['GRP0 = $1B', 'COLUP0 = $06', 'RESM0 = $12', 'ENAM0 = $1D', 'COLUPF = $08',
          'PF0 = $0D', 'PF1 = $0E', 'PF2 = $0F', 'TrogPtr = $80', 'TroggGfx = $82']
    o += ['%-12s = $%04X' % (k, v) for k, v in labels.items()]
    def data_bytes(mem):
        out, a = [], 0xF000
        top = max(mem) if mem else 0xEFFF
        while a <= top:
            chunk = [mem.get(a + i, 0) for i in range(min(16, top - a + 1))]
            out.append('        .byte ' + ','.join('$%02X' % v for v in chunk))
            a += len(chunk)
        return out
    calls = []
    irun = {ri: k for k, (ri, _, _) in enumerate(item_runs)}
    for ri, (run, (name, code, tables), x0) in enumerate(zip(plan['runs'], run_body, run_x)):
        skip = max(0, timer.TOPROWS - run['r']) if game else 0     # (the timer's band rows)
        if run['n'] <= skip:
            continue
        calls.append('        ldx RunX+%d' % irun[ri] if ri in irun else '        ldx #%d' % (x0 + 2 * skip))
        if run.get('enabl') and (ri == 0 or plan['runs'][ri - 1].get('enabl') != run['enabl']):
            calls += ['        lda %s' % run['enabl'], '        sta ENABL      ; the moving platform (at cycle 65-67)']
        first = 'jsr %s' % name
        if game and not any(c.strip().startswith('jsr') for c in calls):
            # the band's late HMOVE: its write at cycle 73 (from 57: ldx 2 or 3, the pad, sta HMOVE), a
            # nop, then into the first body after its WSYNC and inc TrogPtr (at cycle 5: _s at 10)
            assert not run.get('enabl')
            n = 70 - 57 - (3 if ri in irun else 2)
            calls += ['        ' + l for l in pad(n).split('\n')] + ['        sta HMOVE      ; (written at cycle 73)', '        nop', '        jsr %s_c' % name]
        else:
            calls.append('        ' + first)
        calls += ['        jsr %s_i' % name] * (run['n'] - 1 - skip)
    body_code = []
    for name, code, tables in bodies.values():
        # a body must not straddle a page: its taken branch would cost an extra cycle there
        body_code += ['        IF (<.) + %d > 256' % (nbytes(code) + 2), '        ALIGN 256', '        ENDIF']
        body_code += [c if c.endswith(':') else '        ' + c for c in code]
    kernel_end = '''        sta WSYNC
        lda #2              ; blank at once (in the horizontal blank), not part-way along the line
        sta VBLANK
        lda #0
        sta PF1
        sta PF2
        sta GRP1
        sta GRP0
        sta ENAM0
        sta ENABL'''
    overscan = '''        lda #2
        sta VBLANK
        ldx #29
OS:     sta WSYNC
        dex
        bne OS
        jmp Frame'''
    if game:
        # bank switching (F8: reading $FFF8 selects bank 0, $FFF9 bank 1): stubs at the same
        # addresses in both banks, so the instruction after the switch comes from the other bank
        o.append('        seg bank0\n        org $0000\n        rorg $F000')
        o += data_bytes(mems[0])
        o.append(game_frame(plan, tr, h, labels, tx))
        o.append('        jmp $FFE0           ; to the display bank: the kernel')
        o.append('Overscan:')
        o.append('''        lda #2
        sta VBLANK
        lda #33             ; the overscan's 29 lines, timed (the music's time varies)
        sta TIM64T
        lda Mode
        beq OSWait
        jsr MusicTick       ; the tune, a frame on (while playing)
OSWait: lda INTIM
        bne OSWait
        sta WSYNC
        jmp Frame''')
        o.append('        include "%s"' % os.path.join(HERE, 'game.asm'))
        o.append("        include \"musicdrv_c.asm\"   ; the Frak tune, compact (atarivcs/music), 13 bytes of RAM at MUSRAM")
        o.append('LogicEnd:')
        o.append('''        org $0FE0
        rorg $FFE0
        bit $FFF9           ; $FFE0: -> bank 1 (which carries on at $FFE3: jmp Kernel)
        .byte 0,0,0
        .byte 0,0,0         ; $FFE6: (bank 1: bit $FFF8)
        jmp Overscan        ; $FFE9: back from the kernel
        bit $FFF8           ; $FFEC: reset, in either bank -> bank 0
        jmp Start           ; $FFEF
        org $0FFC
        rorg $FFFC
        .word $FFEC
        .word $FFEC''')
        o.append('        seg bank1\n        org $1000\n        rorg $F000')
        o += data_bytes(mems[1])
        o.append('Kernel: lda Mode         ; 0: the front screen')
        o.append('        beq KFront')
        o.append('        jmp KLevel')
        o.append('KFront: lda #0')
        o.append('        sta VBLANK')
        o.append(front.kernel())
        o.append('        jmp KEnd')
        o.append('KLevel:')
        o.append(timer.band(plan['background'], tr['colour']))
        o += calls
        o.append('KEnd:')
        o.append(kernel_end)
        o.append('        jmp $FFE6           ; back to the game bank: overscan')
        o += body_code
        o.append('CodeEnd:')
        o.append('''        org $1FE0
        rorg $FFE0
        .byte 0,0,0         ; $FFE0: (bank 0: bit $FFF9)
        jmp Kernel          ; $FFE3
        bit $FFF8           ; $FFE6: -> bank 0 (which carries on at $FFE9: jmp Overscan)
        .byte 0,0,0
        bit $FFF8           ; $FFEC: reset -> bank 0 (jmp Start at $FFEF there)
        org $1FFC
        rorg $FFFC
        .word $FFEC
        .word $FFEC''')
    else:
        o.append('        seg code\n        org $F000')
        o += data_bytes(mems[1])
        o += static_frame(plan, tr, h, ptr0, tx)
        o += calls
        o.append(kernel_end)
        o.append(overscan)
        o += body_code
        o.append('CodeEnd:')
        o.append('        org $FFFC\n        .word Start\n        .word Start')
    base = os.path.join(outdir, 'level')
    open(base + '.asm', 'w').write('\n'.join(o) + '\n')
    r = subprocess.run(['dasm', base + '.asm', '-I' + os.path.join(ROOT, 'music'), '-f3', '-o' + base + '.bin', '-l' + base + '.lst', '-s' + base + '.sym'],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if r.returncode:
        print(r.stdout[-2000:])
        raise SystemExit('dasm failed')
    sym = {}
    for line in open(base + '.sym'):
        p = line.split()
        if len(p) >= 2 and all(c in '0123456789abcdefABCDEF' for c in p[1]):
            sym[p[0]] = int(p[1], 16)
    body_bytes = sum(nbytes(c) for _, c, _ in bodies.values())
    cost = {
        'tables (bytes read)': table_bytes, 'data area (packed)': max(mem) + 1 - 0xF000,
        'trogg strip + frame': len(strip) + h,
        'bodies': body_bytes, 'call list': 2 * len(plan['runs']) + 3 * 96,
        'frame code': None, 'total code+data': None,
    }
    if game:
        cost['frame code'] = None
        cost['total code+data'] = None
        cost['game code'] = sym['LogicEnd'] - sym['Floor']
        cost['bank 0 (game) used'] = sym['LogicEnd'] - 0xF000
        cost['bank 1 (display) used'] = sym['CodeEnd'] - 0xF000
    else:
        first_body = sym.get(list(bodies.values())[0][0] + '_i')
        cost['frame code'] = first_body - sym['Start'] - cost['call list']
        cost['total code+data'] = first_body - 0xF000 + body_bytes
        cost['ROM used (to the last byte)'] = sym['CodeEnd'] - 0xF000
    info = {'bodies': len(bodies), 'runs': len(plan['runs']), 'lines': nlines, 'tables': sorted(data), 'cost': cost}
    json.dump(info, open(base + '.json', 'w'), indent=1)
    return base, info, labels, data, run_x, run_body


def static_frame(plan, tr, h, ptr0, tx):
    """Start-up and the frame up to the kernel, Trogg standing still (the picture check)."""
    o = []
    o.append('''Start:  sei
        cld
        ldx #$FF
        txs
        lda #0
Clear:  sta $00,x
        dex
        bne Clear
Frame:  lda #2
        sta VSYNC
        sta WSYNC
        sta WSYNC
        sta WSYNC
        lda #0
        sta VSYNC
        lda #2
        sta VBLANK
        lda #$%02X
        sta COLUBK
        sta COLUPF
        lda #$%02X
        sta COLUP0
        lda #1
        sta CTRLPF          ; mirrored playfield
        lda #0
        sta COLUP1
        sta GRP1
        sta GRP0
        sta PF0
        sta PF1
        sta PF2
        lda #1
        sta NUSIZ1
        lda #$20
        sta NUSIZ0          ; single-width Trogg, 4 px yoyo
        lda #<TGfxY         ; the frame as it is
        sta TroggGfx
        lda #>TGfxY
        sta TroggGfx+1
        lda #>$%04X
        sta TrogPtr+1
        lda #<$%04X
        sta TrogPtr''' % (plan['background'], tr['colour'], ptr0, ptr0))
    # coarse position with RESP0 / RESM0 (measured: a strobe ending at cycle c puts P0 at 3c - 63 and
    # M0 at 3c - 64), then HMOVE moves each right by the remaining 0-2 px (HM values: negative = right)
    hm = {}
    for reg, xx, k in (('RESP0', tx, 63), ('RESM0', tx + 8, 64)):
        c = (xx + k) // 3
        hm[reg] = xx - (3 * c - k)
        o.append('        sta WSYNC\n        ' + pad(c - 3).replace('\n', '\n        ') + '\n        sta %s' % reg)
    o.append('''        lda #$%02X
        sta HMP0
        lda #$%02X
        sta HMM0
        sta WSYNC
        sta HMOVE''' % ((-hm['RESP0'] & 15) << 4, (-hm['RESM0'] & 15) << 4))
    o.append('        sta WSYNC\n        ' + pad(57).replace('\n', '\n        ') + '\n        sta RESP1')
    o.append('''        sta HMCLR
        ldx #30
VB:     sta WSYNC
        dex
        bne VB
        lda #0
        sta VBLANK''')
    return o


def game_frame(plan, tr, h, labels, tx):
    """Start-up and the frame up to the kernel, with the Trogg moved by the game logic."""
    return '''Start:  sei
        cld
        ldx #$FF
        txs
        lda #0
Clear:  sta $00,x
        dex
        bne Clear
        lda #START_X
        sta TX
        lda #START_ROW
        sta TRow
        IFCONST YOTEST
        lda #ST_YOYO
        sta State
        lda #YOFACE
        sta Facing
        ENDIF
        jsr MvInit
        IFCONST START_LEVEL
        lda #START_LEVEL
        sta Level
        ENDIF
        IFCONST START_HARD
        lda #1
        sta Diff
        ENDIF
        ldx #2              ; the best times: 9:59 to start with
BInit:  lda #9
        sta BestM,x
        lda #$59
        sta BestS,x
        dex
        bpl BInit
        jsr Labels          ; the labels' pointers and the front screen's colour
        IFCONST SKIPFRONT
        lda #1
        sta Mode
        ENDIF
        IFCONST START_COLL
        lda #START_COLL
        sta Collected
        ENDIF
        lda #1
        sta Repos           ; position P0 in the first frame
        sta CTRLPF          ; mirrored playfield
        sta NUSIZ1
        IFCONST SKIPFRONT
        lda #$31
        sta CTRLPF          ; (the game's: the ball 8 px)
        ENDIF
        lda #$20
        sta NUSIZ0          ; single-width Trogg
Frame:  lda #2
        sta VSYNC
        sta WSYNC
        sta WSYNC
        sta WSYNC
        lda #0
        sta VSYNC
        lda #43
        sta TIM64T
        lda #2
        sta VBLANK
        sta HMCLR
        lda #$%02X
        sta COLUBK
        sta COLUPF
        lda #$%02X
        sta COLUP0
        lda #0
        sta COLUP1
        sta GRP1
        sta GRP0
        sta PF1
        sta PF2
        inc Frm
        lda Mode
        bne InGame
        lda FBg             ; the front screen: the level's colour, black blocks, no Trogg, fire starts
        sta COLUBK
        lda #FRONT_INK
        sta COLUPF
        jsr FrontLogic
        jmp Shown
InGame: jsr Timer
        jsr Logic
        jsr Mover           ; the moving platform (carrying him: after his move)
        jsr RunVars         ; the item runs' line indexes, from the collected bits
Shown:  ldx #<TGfxW          ; the Trogg's frame: walking, the yoyo out, climbing, or (the front
        ldy #>TGfxW         ; screen) none: the strip's zeros
        lda State
        cmp #ST_YOYO
        bne CF1
        ldx #<TGfxY
        ldy #>TGfxY
CF1:    cmp #ST_CLIMB
        bne CF2
        ldx #<TGfxC
        ldy #>TGfxC
CF2:    lda Mode
        bne CF3
        ldx #<TroggStrip
        ldy #>TroggStrip
CF3:    stx TroggGfx
        sty TroggGfx+1
        lda Facing
        sta REFP0
        lda #<(TroggStrip+94+H+TOPROWS)   ; (the kernel's first body is row TOPROWS)
        sec
        sbc TRow
        sta TrogPtr
        lda #>TroggStrip
        sta TrogPtr+1
        lda Repos           ; a new position (start, restart): RESP0 and HMOVE from TX
        beq NoRep
        lda #0
        sta Repos
        lda TX
        ldx #0
        jsr PosObj
        jmp Moved
NoRep:  lda HMV             ; otherwise this frame's pixel of movement
        sta HMP0
        sta WSYNC
        sta HMOVE
        sta WSYNC
        sta HMCLR
Moved:  lda State           ; the yoyo: M0 to YoX
        cmp #ST_YOYO
        bne NoYo
        ldx YoX
        inx
        txa
        ldx #2
        jsr PosObj
NoYo:   sta WSYNC
        %s
        sta RESP1
        sta HMCLR
        lda Mode            ; playing: P0 and P1 for the timer (the band puts P0 back)
        beq NoTime
        lda #40
        ldx #0
        jsr PosObj
        lda #48
        ldx #1
        jsr PosObj
        lda #4
        sta NUSIZ0          ; two copies wide: x 40 and 104 (P1: 48 and 112), as on the front screen
        sta NUSIZ1
        lda #TWHITE
        sta COLUP0
        sta COLUP1
        lda #0
        sta REFP0
NoTime: lda Mode            ; the front screen: the labels first (P0 at 40, P1 at 48, two copies
        bne NoTail          ; wide, black); the kernel then moves P1 to the tail's fill
        lda #40
        ldx #0
        jsr PosObj
        lda #48
        ldx #1
        jsr PosObj
        lda #4
        sta NUSIZ0
        sta NUSIZ1
        lda #5
        sta CTRLPF          ; mirrored playfield, over the players
        lda #FRONT_INK
        sta COLUP0
        sta COLUP1
        lda #0
        sta VDELP0          ; (the copyright's lines turn it on)
        sta VDELP1
NoTail: lda TX              ; for the band: P0 and the ball HMK right (its HMOVE is late)
        clc
        adc #HMK
        sta Tmp
        lda MvX
        clc
        adc #HMK + 1
        sta Tmp2
WaitVB: lda INTIM
        bne WaitVB
        sta WSYNC           ; (the kernel turns VBLANK off: the band after writing ahead)''' % (plan['background'], tr['colour'], pad(57).replace('\n', '\n        '))


def front_model():
    return front.model(int(opt('level', '1')), '--hard' in sys.argv)


def model(plan, palette, yoyo=True):
    """(plan['yotest'] = (length, facing): the yoyo held out, as a --yotest build draws it)"""
    """Expected colour index (or None for background) of every pixel of the 192 lines."""
    img = [[None] * 160 for _ in range(192)]
    for run in plan['runs']:
        for k, L in enumerate(run['lines']):
            y = 2 * run['r'] + k
            for b in L.get('Lit', run['lit']):          # (a dashed platform's middle lines: their own)
                for x in range(4 * b, 4 * b + 4):
                    img[y][x] = L['Stripe']
            gi = 0
            gone = set(plan.get('collected', ()))
            for ob in run['objs']:
                v, c = (L.get('Lad', 0), 0) if ob['t'] == 'L' else (L.get('G%d' % gi, 0), L.get('C%d' % gi, 0))
                if ob['t'] != 'L':
                    gi += 1
                if ob.get('ref') and ob['ref'][0] == 'item' and ob['ref'][1] in gone:
                    gh = plan.get('ghost', {}).get(ob['ref'][1])
                    if gh is None:
                        continue
                    v, c = gh.get(y, 0), GHOST
                for b in range(8):
                    if v & (0x80 >> b):
                        img[y][ob['x'] + b] = c
    mv = plan.get('mover')                  # the moving platform at its start (checks hold it there)
    if mv and not yoyo:
        a = mv['x1'] if mv['mode'] == 'rl' else mv['x0']
        for k in range(6):
            for x in range(a, a + 8):
                img[2 * mv['row'] + k][x] = plan['stripes'][min(k, len(plan['stripes']) - 1)]
    tr = plan['trogg']
    rows = tr['frames'][0]['rows']
    yt = plan.get('yotest')
    face = yt[1] if yt else 0
    for i, v in enumerate(rows):
        hand = v & 1
        if not yoyo:
            v &= 0xFE                                   # --game copies the frame with bit 0 off
        if yt:
            v = rows[i]                                 # (yoyo out: the frame as it is)
        if face:
            v = int('{:08b}'.format(v)[::-1], 2)        # REFP0
        # the Trogg's GRP0 / ENAM0 are stored late in a row's first line (the tail, after the shared
        # block), so each of his rows shows on that row's second line and the next row's first
        top = 2 * (tr['row'] - len(rows) + 1 + i) + 1
        for y in (top, top + 1):
            for b in range(8):
                if v & (0x80 >> b):
                    img[y][tr['x'] + b] = tr['colour']
            if hand and yoyo and not yt:                # the yoyo (M0, 4 px) beside his hand
                for x in range(tr['x'] + 8, tr['x'] + 12):
                    img[y][x] = tr['colour']
            if hand and yt:                             # held out: TX + 8 + len, or TX - 4 - len
                x0 = tr['x'] + 8 + yt[0] if not face else tr['x'] - 4 - yt[0]
                for x in range(x0, x0 + 4):
                    img[y][x] = tr['colour']
    return img


def check(base, plan, outdir, game=False):
    from PIL import Image
    palette = json.load(open(os.path.join(ROOT, 'editor', 'palette.json')))
    rgb = lambda h: tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))
    pal = [rgb(h) for h in palette]
    if '--hard' in sys.argv:               # (the right difficulty switch at A)
        os.environ['STELLA_ARGS'] = os.environ.get('STELLA_ARGS', '') + ' -rd A'
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png').convert('RGB')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    sx = im.width / 160
    bgc = plan['background']
    near = lambda c: min(range(128), key=lambda i: sum((a - b) ** 2 for a, b in zip(pal[i], c))) * 2
    bgrgb = im.getpixel((im.width - 2, im.height // 2))
    # the first kernel line: the background shows from the top of the visible picture
    # (VBLANK goes off part-way through the line before the first body's WSYNC)
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bgrgb) + 1
    want = front_model() if '--front' in sys.argv else model(plan, pal, yoyo=not game)
    if game and '--front' not in sys.argv:
        want[:timer.TOPROWS * 2] = timer.model_lines(hard='--hard' in sys.argv)
    bad = []
    for y in range(192):
        got = [im.getpixel((int((x + 0.5) * sx), first + y)) for x in range(160)]
        g = [None if c == bgrgb else near(c) for c in got]
        w = want[y]
        diff = [x for x in range(160) if (w[x] is None) != (g[x] is None) or (w[x] is not None and (w[x] & 0xFE) != g[x])]
        if diff:
            bad.append((y, diff[:8]))
    for y, d in bad[:int(os.environ.get("SHOW", 12))]:
        print('  line %3d differs at x %s' % (y, d))
    print('%d of 192 lines differ from the plan' % len(bad))
    return bad


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    outdir = os.path.abspath(args[0] if args else os.path.join(HERE, 'out'))
    os.makedirs(outdir, exist_ok=True)
    plan = get_plan(outdir)
    if opt('collected'):                   # --collected=I,J: those items start collected
        plan['collected'] = [int(v) for v in opt('collected').split(',')]
    if opt('yotest'):                      # --yotest=LEN,FACING (0 right, 8 left): yoyo held out
        plan['yotest'] = tuple(int(v) for v in opt('yotest').split(','))
    if opt('trogg'):                       # --trogg=X,ROW: move his start (checks other positions)
        plan['trogg']['x'], plan['trogg']['row'] = (int(v) for v in opt('trogg').split(','))
    base, info, *_ = compile_screen(plan, outdir, game='--game' in sys.argv)
    print('%s: %d runs, %d bodies, %d lines, tables %s' % (plan['name'], info['runs'], info['bodies'], info['lines'], ' '.join(info['tables'])))
    for k, v in info['cost'].items():
        if v is not None:
            print('  %-28s %5d' % (k, v))
    if '--check' in sys.argv:
        check(base, plan, outdir, game='--game' in sys.argv)


if __name__ == '__main__':
    main()
