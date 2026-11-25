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
    out += ['bcs %s_e' % name, 'rts', '%s_e:' % name] + tail
    if n > 1:
        out += pad(n).split('\n')
    out += ['asl', 'sta ENAM0', 'clc', 'jmp %s_s' % name]
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


def compile_screen(plan, outdir):
    errs = [(r['r'], e) for r in plan['runs'] for e in r['errors']]
    if errs:
        raise SystemExit('the screen has rows the editor flags; fix them first:\n' +
                         '\n'.join('  row %d: %s' % (r, e) for r, e in errs[:10]))
    # bodies: one per distinct (row key, timed writes)
    bodies, run_body = {}, []
    for run in plan['runs']:
        bk = run['key'] + json.dumps(run['tasks'])
        if bk not in bodies:
            name = 'B%d' % len(bodies)
            code, tables = body(name, run)
            bodies[bk] = (name, code, tables)
        run_body.append(bodies[bk])
    # lines: runs with the same body and the same per-line data (in the tables it reads) share them
    seen, run_x, nlines, data = {}, [], 0, {}
    for run, (name, code, tables) in zip(plan['runs'], run_body):
        sig = name + json.dumps([[L.get(t, 0) for t in tables] for L in run['lines']])
        if sig not in seen:
            seen[sig] = nlines
            for k, L in enumerate(run['lines']):
                for t in tables:
                    data.setdefault(t, {})[nlines + k] = L.get(t, 0)
            nlines += len(run['lines'])
        run_x.append(seen[sig])
    if nlines > 256:
        raise SystemExit('line index overflow: %d lines' % nlines)
    # data area from $F000, packed: each block is placed at the first address where every byte it
    # defines is free or already holds the same value (tables only define the lines their runs read,
    # so they overlap freely); an indexed table's label must be in the same page as every line it
    # reads (label offset + max line <= 255), so no read crosses a page
    mem, labels = {}, {}

    def place(name, vals, indexed):
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
    place('TroggFrame', dict(enumerate(frame)), False)
    # Trogg pointer: the first body call increments it before reading, so row k reads ptr0 + k + 1;
    # rows feet-h+1 .. feet show frame rows 1..h (strip index 96 .. 95+h)
    ptr0 = labels['TroggStrip'] + 95 - (tr['row'] - h + 1)
    tx = tr['x']

    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['HMP0 = $20', 'HMM0 = $22']
    o += ['GRP0 = $1B', 'COLUP0 = $06', 'RESM0 = $12', 'ENAM0 = $1D', 'COLUPF = $08',
          'PF0 = $0D', 'PF1 = $0E', 'PF2 = $0F', 'TrogPtr = $80', 'Buffer = $82']
    o += ['%-12s = $%04X' % (k, v) for k, v in labels.items()]
    o.append('        seg code\n        org $F000')
    addrs = sorted(mem)
    a = 0xF000
    while a <= addrs[-1]:
        chunk = [mem.get(a + i, 0) for i in range(min(16, addrs[-1] - a + 1))]
        o.append('        .byte ' + ','.join('$%02X' % v for v in chunk))
        a += len(chunk)
    code_start = len(o)
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
    calls = []
    for run, (name, code, tables), x0 in zip(plan['runs'], run_body, run_x):
        calls.append('        ldx #%d' % x0)
        calls += ['        jsr %s' % name] + ['        jsr %s_i' % name] * (run['n'] - 1)
    o += calls
    o.append('''        sta WSYNC
        lda #0
        sta PF1
        sta PF2
        sta GRP1
        sta GRP0
        sta ENAM0
        lda #2
        sta VBLANK
        ldx #29
OS:     sta WSYNC
        dex
        bne OS
        jmp Frame''')
    for name, code, tables in bodies.values():
        o += [c if c.endswith(':') else '        ' + c for c in code]
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
    first_body = sym.get(list(bodies.values())[0][0] + '_i')
    cost['frame code'] = sym['Start'] and (first_body - sym['Start'] - cost['call list'])
    cost['total code+data'] = first_body - 0xF000 + body_bytes
    info = {'bodies': len(bodies), 'runs': len(plan['runs']), 'lines': nlines, 'tables': sorted(data), 'cost': cost}
    json.dump(info, open(base + '.json', 'w'), indent=1)
    return base, info, labels, data, run_x, run_body


def model(plan, palette):
    """Expected colour index (or None for background) of every pixel of the 192 lines."""
    img = [[None] * 160 for _ in range(192)]
    for run in plan['runs']:
        for k, L in enumerate(run['lines']):
            y = 2 * run['r'] + k
            for b in run['lit']:
                for x in range(4 * b, 4 * b + 4):
                    img[y][x] = L['Stripe']
            gi = 0
            for ob in run['objs']:
                v, c = (L.get('Lad', 0), 0) if ob['t'] == 'L' else (L.get('G%d' % gi, 0), L.get('C%d' % gi, 0))
                if ob['t'] != 'L':
                    gi += 1
                for b in range(8):
                    if v & (0x80 >> b):
                        img[y][ob['x'] + b] = c
    tr = plan['trogg']
    rows = tr['frames'][0]['rows']
    for i, v in enumerate(rows):
        # the Trogg's GRP0 / ENAM0 are stored late in a row's first line (the tail, after the shared
        # block), so each of his rows shows on that row's second line and the next row's first
        top = 2 * (tr['row'] - len(rows) + 1 + i) + 1
        for y in (top, top + 1):
            for b in range(8):
                if v & (0x80 >> b):
                    img[y][tr['x'] + b] = tr['colour']
            if v & 1:                                   # the yoyo (M0, 4 px)
                for x in range(tr['x'] + 8, tr['x'] + 12):
                    img[y][x] = tr['colour']
    return img


def check(base, plan, outdir):
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
    want = model(plan, pal)
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
    base, info, *_ = compile_screen(plan, outdir)
    print('%s: %d runs, %d bodies, %d lines, tables %s' % (plan['name'], info['runs'], info['bodies'], info['lines'], ' '.join(info['tables'])))
    for k, v in info['cost'].items():
        print('  %-28s %5d' % (k, v))
    if '--check' in sys.argv:
        check(base, plan, outdir)


if __name__ == '__main__':
    main()
