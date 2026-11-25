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

F._setup()
pad = tiatest.pad
TAIL = ['ldy #0', 'lda (TrogPtr),y', 'tay', 'lda Buffer,y', 'sta GRP0', 'inx']


def opt(name, default=None):
    return next((a.split('=', 1)[1] for a in sys.argv[1:] if a.startswith('--%s=' % name)), default)


def get_plan(outdir):
    path = os.path.join(outdir, 'plan.json')
    cmd = ['node', os.path.join(HERE, 'plan.js'), os.path.join(ROOT, 'editor', 'index.html'), path,
           opt('project', ''), opt('type', '0'), opt('screen', '0')]
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
    code, end = F.schedule(((0, 0, 0), (0, 0, 0)), ((0, 0, 0), (0, 0, 0)), objs, ('imm', 0), True,
                           objs[-1][0] if objs else None, t0=10, end_limit=55, extra=extra)
    flat = [i.strip() for c in code for i in c.split('\n') if i.strip()]
    tail = list(TAIL)
    n = 76 - (end + 3 + screens2.ncycles(tail))
    if n < 0:
        raise ValueError('tail does not fit')
    if n == 1:
        tail[4] = 'sta.w GRP0'
    out = ['%s_i:' % name, 'inx', '%s:' % name, 'sta WSYNC', 'inc TrogPtr', 'sec', 'bit $80', '%s_s:' % name] + flat
    # the padding goes before the GRP0 store, so the store always ends at the same late cycle (about
    # 66, pixel 130) whatever the body: every Trogg row then shows on its row's second line and the
    # next row's first, the same for any x up to about 122
    out += ['bcs %s_e' % name, 'rts', '%s_e:' % name] + tail[:4] + ['inx']
    if n > 1:
        out += pad(n).split('\n')
    out += [tail[4], 'asl', 'sta ENAM0', 'clc', 'jmp %s_s' % name]   # (clc after asl: the carry marks line 2)
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
                    v |= 1 << (15 - ((k - 4) >> 1))
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
        pidx.append(2 * ppool.index(v))
    for c in range(36):                # 3 px columns on the P1 grid, x 19 + 3c
        v = ladder_bits(c)
        if v not in lpool:
            lpool.append(v)
        lidx.append(4 * lpool.index(v))
    pb = [b for v in ppool for b in (v >> 8, v & 255)]
    lb = [b for v in lpool for b in (v >> 24, (v >> 16) & 255, (v >> 8) & 255, v & 255)]
    return pidx, pb, lidx, lb




def front_runs():
    """The front screen (front.py) as runs like the editor's plan, its per-line tables named with an
    F prefix (their own line indexes): each run drawn the first way its body fits."""
    lit_at = front.lit_rows()
    runs, prev, r = [], None, 0
    while r < 96:
        lit = lit_at.get(r, set())
        e = r
        while e < 96 and lit_at.get(e, set()) == lit:
            e += 1
        L = {'FStripe': front.INK if lit else 0}
        for reg in M.REGS:
            L['FL' + reg] = M.value(lit, reg, 'L')
            L['FR' + reg] = M.value(lit, reg, 'R')
        run = None
        for way, tk, end in M.tasks(lit, prev):
            tk = [(lo, hi, (ld[0].replace('lda ', 'lda F', 1) if ld[0].endswith(',x') else ld[0], ld[1]), reg)
                  for lo, hi, ld, reg in tk]
            cand = {'r': r, 'n': e - r, 'key': 'F' + ','.join(map(str, sorted(lit))), 'way': way, 'tasks': tk,
                    'errors': [], 'objs': [], 'lit': sorted(lit), 'lines': [dict(L) for _ in range(2 * (e - r))]}
            try:
                body('Ftest', cand)
            except (ValueError, AssertionError):
                continue
            run, prev = cand, end
            break
        if run is None:
            raise SystemExit('front screen row %d does not fit' % r)
        runs.append(run)
        r = e
    return runs


def compile_screen(plan, outdir, game=False):
    errs = [(r['r'], e) for r in plan['runs'] for e in r['errors']]
    if errs:
        raise SystemExit('the screen has rows the editor flags; fix them first:\n' +
                         '\n'.join('  row %d: %s' % (r, e) for r, e in errs[:10]))
    # bodies: one per distinct (row key, timed writes)
    bodies, run_body = {}, []
    fronts = front_runs() if game else []
    for run in plan['runs'] + fronts:
        bk = run['key'] + json.dumps(run['tasks'])
        if bk not in bodies:
            name = 'B%d' % len(bodies)
            code, tables = body(name, run)
            bodies[bk] = (name, code, tables)
        run_body.append(bodies[bk])
    # collectable items (gems and keys): a bit each in Collected
    coll = [i for i, it in enumerate(plan['items']) if it['kind'] in ('gem', 'key')] if game else []
    if len(coll) > 8:
        raise SystemExit('more than 8 gems and keys on a screen')
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
    for ri, (run, (name, code, tables)) in enumerate(zip(plan['runs'], run_body)):
        slots, k = [], 0
        for o in run['objs']:
            if o['t'] != 'L':
                if o.get('ref') and o['ref'][0] == 'item' and o['ref'][1] in bit:
                    slots.append((k, bit[o['ref'][1]]))
                k += 1
        run_x.append(lines_at(name, tables, run['lines']))
        if slots:
            xs = []
            for v in range(1 << len(slots)):
                gone = {'G%d' % kk for j, (kk, _) in enumerate(slots) if v >> j & 1}
                xs.append(lines_at(name, tables, [{t: (0 if t in gone else val) for t, val in L.items()} for L in run['lines']]))
            item_runs.append((ri, [b for _, b in slots], xs))
    if nlines > 256:
        raise SystemExit('line index overflow: %d lines' % nlines)
    # the front screen's runs: their own tables (F...), so their own line indexes from 0
    front_x, fseen, fl = [], {}, 0
    for run, (name, code, tables) in zip(fronts, run_body[len(plan['runs']):]):
        sig = name + json.dumps([[L.get(t, 0) for t in tables] for L in run['lines']])
        if sig not in fseen:
            fseen[sig] = fl
            for k, L in enumerate(run['lines']):
                for t in tables:
                    data.setdefault(t, {})[fl + k] = L.get(t, 0)
            fl += len(run['lines'])
        front_x.append(fseen[sig])
    run_body = run_body[:len(plan['runs'])] + [None] * 0 + run_body[len(plan['runs']):]
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
    for t in sorted(data, key=lambda t: -len(data[t])):
        place(t, data[t], True)
    table_bytes = sum(len(d) for d in data.values())
    tr = plan['trogg']
    frame = tr['frames'][0]['rows']
    h = len(frame)
    strip = [0] * 96 + list(range(1, h + 1)) + [0] * 96
    place('TroggStrip', dict(enumerate(strip)), True)    # one page: inc TrogPtr only steps the low byte
    place('TroggFrame', dict(enumerate(frame)), False, 0 if game else 1)
    nlad = 0
    if game:
        pidx, pb, lidx, lb = move_maps(plan)
        fr = [f['rows'] for f in tr['frames'][:2]]
        fr += [fr[0]] * (2 - len(fr))
        hh = max(len(f) for f in fr)
        frames = [b for f in fr for b in [0] * (hh - len(f)) + f]
        fb = [(r + 1) // 3 if (r + 1) % 3 == 0 else 0xFF for r in range(97)]
        for name, vals in (('PIdx', pidx), ('PPool', pb), ('LIdx', lidx), ('LPool', lb), ('FB', fb), ('Band3', [r // 3 for r in range(128)]),
                           ('Mask8', [0x80 >> i for i in range(8)]), ('TroggFrames', frames)):
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
                           ('ItBit', [1 << b for b in range(len(its))])):
            place(name, dict(enumerate(vals or [0])), False, 0)
        place('HMTab', {r: (-(r - 6) & 15) << 4 for r in range(15)}, True, 0)   # PosObj's fine move
        maps_bytes = len(pidx) + len(pb) + len(lidx) + len(lb)
        h = hh
    # Trogg pointer: the first body call increments it before reading, so row k reads ptr0 + k + 1;
    # rows feet-h+1 .. feet show frame rows 1..h (strip index 96 .. 95+h)
    ptr0 = labels['TroggStrip'] + 95 - (tr['row'] - h + 1)
    tx = tr['x']

    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['HMP0 = $20', 'HMM0 = $22', 'REFP0 = $0B', 'INPT4 = $0C', 'SWCHA = $280', 'INTIM = $284',
          'TIM64T = $296', 'H = %d' % h,
          'START_X = %d' % tr['x'], 'START_ROW = %d' % tr['row'], 'NLAD = %d' % nlad,
          'NIR = %d' % len(item_runs), 'NITEM = %d' % len(coll), 'RunX = $C0', 'FRONT_BG = $%02X' % front.BG]
    if game and (('--check' in sys.argv and '--front' not in sys.argv) or plan.get('skipfront')):
        o.append('SKIPFRONT = 1')       # (picture checks of the level start in it)
    assert len(item_runs) <= 40, 'too many runs with items for RunX'
    if game and plan.get('collected'):
        o.append('START_COLL = %d' % sum(bit[i] for i in plan['collected'] if i in bit))
    if game and plan.get('yotest'):
        o += ['YOTEST = %d' % plan['yotest'][0], 'YOFACE = %d' % plan['yotest'][1]]
    o += ['GRP0 = $1B', 'COLUP0 = $06', 'RESM0 = $12', 'ENAM0 = $1D', 'COLUPF = $08',
          'PF0 = $0D', 'PF1 = $0E', 'PF2 = $0F', 'TrogPtr = $80', 'Buffer = $82']
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
    fcalls = []
    for run, (name, code, tables), x0 in zip(fronts, run_body[len(plan['runs']):], front_x):
        fcalls.append('        ldx #%d' % x0)
        fcalls += ['        jsr %s' % name] + ['        jsr %s_i' % name] * (run['n'] - 1)
    for ri, (run, (name, code, tables), x0) in enumerate(zip(plan['runs'], run_body, run_x)):
        calls.append('        ldx RunX+%d' % irun[ri] if ri in irun else '        ldx #%d' % x0)
        calls += ['        jsr %s' % name] + ['        jsr %s_i' % name] * (run['n'] - 1)
    body_code = []
    for name, code, tables in bodies.values():
        # a body must not straddle a page: its taken branch would cost an extra cycle there
        body_code += ['        IF (<.) + %d > 256' % (nbytes(code) + 2), '        ALIGN 256', '        ENDIF']
        body_code += [c if c.endswith(':') else '        ' + c for c in code]
    kernel_end = '''        sta WSYNC
        lda #0
        sta PF1
        sta PF2
        sta GRP1
        sta GRP0
        sta ENAM0'''
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
        o.append(overscan)
        o.append('        include "%s"' % os.path.join(HERE, 'game.asm'))
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
        o.append('KFront:')
        o += fcalls
        o.append('        jmp KEnd')
        o.append('KLevel:')
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
    r = subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst', '-s' + base + '.sym'],
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
        ldy #%d
CopyF:  lda TroggFrame-1,y
        sta Buffer,y
        dey
        bne CopyF
        lda #>$%04X
        sta TrogPtr+1
        lda #<$%04X
        sta TrogPtr''' % (plan['background'], tr['colour'], h, ptr0, ptr0))
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
        lda #FRONT_BG       ; the front screen: green, no Trogg, fire starts
        sta COLUBK
        jsr FrontLogic
        jmp Shown
InGame: jsr Logic
        jsr RunVars         ; the item runs' line indexes, from the collected bits
Shown:
        lda #$FE            ; the frame's bit 0 (the hand row's yoyo, M0) only while it's out
        ldx State
        cpx #ST_YOYO
        bne CFm
        lda #$FF
CFm:    ldx Mode
        bne CFm2
        lda #0              ; (front screen: an empty Trogg buffer)
CFm2:   sta Tmp
        ldx #0              ; the Trogg's frame (walking, or climbing) into the buffer
        lda State
        cmp #ST_CLIMB
        bne CF0
        ldx #H
CF0:    ldy #1
CopyF:  lda TroggFrames,x
        and Tmp
        sta Buffer,y
        inx
        iny
        cpy #H+1
        bne CopyF
        lda Facing
        sta REFP0
        lda #<(TroggStrip+94+H)
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
WaitVB: lda INTIM
        bne WaitVB
        sta WSYNC
        lda #0
        sta VBLANK''' % (plan['background'], tr['colour'], pad(57).replace('\n', '\n        '))


def front_model():
    img = [[None] * 160 for _ in range(192)]
    for r, lit in front.lit_rows().items():
        for y in (2 * r, 2 * r + 1):
            for b in lit:
                for x in range(4 * b, 4 * b + 4):
                    img[y][x] = front.INK
    return img


def model(plan, palette, yoyo=True):
    """(plan['yotest'] = (length, facing): the yoyo held out, as a --yotest build draws it)"""
    """Expected colour index (or None for background) of every pixel of the 192 lines."""
    img = [[None] * 160 for _ in range(192)]
    for run in plan['runs']:
        for k, L in enumerate(run['lines']):
            y = 2 * run['r'] + k
            for b in run['lit']:
                for x in range(4 * b, 4 * b + 4):
                    img[y][x] = L['Stripe']
            gi = 0
            gone = set(plan.get('collected', ()))
            for ob in run['objs']:
                v, c = (L.get('Lad', 0), 0) if ob['t'] == 'L' else (L.get('G%d' % gi, 0), L.get('C%d' % gi, 0))
                if ob['t'] != 'L':
                    gi += 1
                if ob.get('ref') and ob['ref'][0] == 'item' and ob['ref'][1] in gone:
                    continue
                for b in range(8):
                    if v & (0x80 >> b):
                        img[y][ob['x'] + b] = c
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
