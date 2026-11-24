#!/usr/bin/env python3
"""
The FR and AK screens rebuilt in the current framework: 96 two-line rows, Trogg (P0, double
width, via TrogPtr) and the yoyo (M0, enabled by Trogg's front pixel) in the row skeleton, and
every distinct row structure drawn by a carry-shared two-line body ending INX / RTS. The screen
is a call list: LDX #row / JSR body per row.

    python3 atarivcs/test/screens2.py fr|ak [OUT_DIR]

Per row, X indexes row tables (Ladder, Item: one byte per row, so gems are 2 lines per pixel
row). The only per-line value is the platform stripe colour (single-block steps share it): the
prefixes load it into Y from EvenCol,x / OddCol,x, and the shared block stores it with STY.

Each body's shared block is scheduled by fr_screen's search (adapted: starts at cycle 14, uses A
only, since X is the row index; Trogg's GRP0 write moved to the even tail), with its last store
ending by cycle 53, so the odd line falls through its BCS by 55: the budget rule that lets any
body follow any other, even with LDX zp. Rows that only fit with a later limit are reported.
"""
import inspect
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tiatest  # noqa: E402
import fr_screen as fr  # noqa: E402
from trogg_rows import TROGG, bits  # noqa: E402
from platforms import pf_regs, cycles  # noqa: E402
from PIL import Image  # noqa: E402

pad = tiatest.pad
BG, DARK, MAGENTA, BLACK, YELLOW, TROGG_COL = 0xAA, 0xA4, 0x58, 0x00, 0x1E, 0x58
STRIPES = [BLACK, MAGENTA, MAGENTA, BLACK, DARK, DARK, DARK, DARK]
LADDER_POLE, LADDER_RUNG = 0x18, 0x7E
GEM = ['...XX...', '..X..X..', '.X....X.', 'X......X', '.X....X.', '..X..X..', '...XX...']
KEY = ['.XX.....', 'X..X....', 'X..XXXXX', 'X..X.X.X', '.XX.....']
T0, LIMIT = 14, 53
MAXX = 112                         # a strobe ending at 53
CHANGES = []
DROPPED = []

SCREENS = {
    'fr': dict(
        platforms=[(24, 12, 71), (88, 12, 63), (176, 8, 67), (24, 92, 139), (88, 100, 139),
                   (176, 88, 127), (176, 140, 155)],
        steps=[(36, 145), (52, 148), (68, 145), (104, 130), (120, 136), (136, 145), (152, 148)],
        ladders=[(28, 32, 176), (97, 32, 176)],
        items=[('gem', 64, 24), ('gem', 55, 88), ('gem', 133, 88), ('key', 118, 176)],  # (kind, x, bottom line)
        trogg_x=48),
    'ak': dict(
        platforms=[(24, 24, 59), (104, 24, 59), (176, 16, 67), (24, 84, 103), (88, 92, 119),
                   (176, 84, 107), (176, 140, 155)],
        steps=[(40, 145), (56, 136), (72, 127), (120, 130), (136, 139), (152, 148)],
        ladders=[(28, 32, 176), (55, 32, 176), (88, 32, 176)],
        items=[('gem', 40, 24), ('gem', 112, 88), ('gem', 148, 176)],
        trogg_x=32),
}

# ---- the scheduler, adapted from fr_screen.schedule -------------------------------------------
_src = inspect.getsource(fr.schedule)
for a, b in [
        ("    tasks.append((0, (68 + TROGG_X) // 3 - 1, ('lda Trogg,y', 4), 'GRP0'))\n", ""),
        ("('lda PCol,y', 4)", "('Y', 0)"),
        ("            c = 3              # any strobe", "            c = t0 + 3         # any strobe"),
        ("            need = 3 if ins in (ha, hx) else ln + 3",
         "            need = 3 if ins in (ha, hx, 'Y') else ln + 3"),
        ("            for r in (('a',) if '(' in ins else ('a', 'x')):   # no LDX (zp),y\n"
         "                held = ha if r == 'a' else hx\n",
         "            for r in (('y',) if ins == 'Y' else ('a',)):     # X is the row index\n"
         "                held = 'Y' if r == 'y' else ha\n"),
        ("                res = search(end, rem - {i}, si, ha, hx)",
         "                res = search(end, rem - {i}, si, ha, hx)"),
]:
    assert a in _src, a
    _src = _src.replace(a, b)
_ns = dict(fr.__dict__)


def _load(src):
    kind, v = src
    if kind == 'imm':
        return ('lda #$%02X' % v, 2)
    if kind == 'stripe':
        return ('Y', 0)
    return ('lda %s,x' % v, 4)


_ns['load'] = _load
exec(_src, _ns)
schedule = _ns['schedule']


# ---- the screen as rows ---------------------------------------------------------------------
def model(scr):
    rows = [{'pf': set(), 'objs': []} for _ in range(96)]
    t = {n: [0] * 96 for n in ('EvenCol', 'OddCol', 'Ladder', 'Item')}
    phase = [None] * 96

    def stripe(r, top):
        k = 2 * r - top
        p = (STRIPES[k], STRIPES[k + 1])
        assert phase[r] in (None, p), ('stripe clash at row', r)
        phase[r] = p
        t['EvenCol'][r], t['OddCol'][r] = p
    for top, a, b in scr['platforms']:
        for r in range(top // 2, top // 2 + 4):
            rows[r]['pf'] |= set(range(a, b + 1))
            stripe(r, top)
    for top, x in scr['steps']:
        if x > MAXX:
            px = 4 * round(x / 4)
            CHANGES.append('step x %d -> playfield %d-%d' % (x, px, px + 7))
        for r in range(top // 2, top // 2 + 4):
            if x > MAXX:
                rows[r]['pf'] |= set(range(px, px + 8))
            else:
                rows[r]['objs'].append((x, ('imm', 0xFF), ('stripe', 0)))
            stripe(r, top)
    for x, a, b in scr['ladders']:
        for r in range(a // 2, b // 2):
            if any(px in rows[r]['pf'] for px in range(x, x + 8)):
                continue
            rows[r]['objs'].append((x, ('tbl', 'Ladder'), ('imm', BLACK)))
            t['Ladder'][r] = LADDER_RUNG if (2 * r) % 8 == 4 else LADDER_POLE
    for kind, x, bottom in scr['items']:
        if x > MAXX:
            CHANGES.append('%s x %d -> %d' % (kind, x, MAXX))
            x = MAXX
        g = GEM if kind == 'gem' else KEY
        for i, s in enumerate(g):
            r = bottom // 2 - len(g) + i
            rows[r]['objs'].append((x, ('tbl', 'Item'), ('imm', BLACK if kind == 'gem' else YELLOW)))
            t['Item'][r] = bits(s)
    for r in rows:
        r['objs'].sort()
    return rows, t


def body_code(name, code, uses_y):
    ld = ['ldy EvenCol,x'] if uses_y else []
    lo = ['ldy OddCol,x'] if uses_y else []
    out = ['%s:' % name, 'sta WSYNC', 'inc TrogPtr'] + ld + ['sec', 'jmp %s_s' % name]
    out += ['%s_o:' % name, 'sta WSYNC', 'asl', 'sta ENAM0'] + lo + ['clc', 'bit $80']
    out += ['%s_s:' % name] + code + ['bcs %s_e' % name, 'inx', 'rts']
    out += ['%s_e:' % name, 'ldy #0', 'lda (TrogPtr),y', 'sta GRP0', 'jmp %s_o' % name]
    return out


def ncycles(code):
    return sum(4 if i.startswith(('sta.w', 'stx.w', 'sty.w')) or i.endswith(',x') else cycles(i)
               for chunk in code for i in (x.strip() for x in chunk.split('\n')) if i)


def build(which, base):
    scr = SCREENS[which]
    rows, t = model(scr)
    # runs of rows with the same structure
    runs = []
    for r, row in enumerate(rows):
        key = (tuple(map(tuple, pf_regs(row['pf']))), tuple(row['objs']))
        if runs and runs[-1][2] == key:
            runs[-1][1] = r + 1
        else:
            runs.append([r, r + 1, key])
    bodies, calls, report = {}, [], []
    prev = (((0, 0, 0), (0, 0, 0)), None, False, None)
    for a, b, (pf, objs) in runs:
        prev_pf, prev_col, prev_objs, prev_x = prev
        key = (pf, objs, prev)
        if key not in bodies:
            res, keep = None, list(objs)
            uses_y = any(pf[0]) or any(pf[1]) or any(o[2][0] == 'stripe' for o in objs)
            t0 = T0 if uses_y else T0 - 4
            while res is None:
                try:
                    res = schedule(pf, prev_pf, keep, prev_col, prev_objs, prev_x, t0=t0, end_limit=LIMIT)
                except ValueError:
                    if not keep:
                        sys.exit('rows %d-%d: even the playfield alone does not fit' % (a, b - 1))
                    DROPPED.append((a, b - 1, keep.pop()))
            code, end = res
            assert ncycles(code) == end - t0, (a, ncycles(code), end)
            name = 'R%d' % len(bodies)
            bodies[key] = (name, body_code(name, code, uses_y), end + 2)
            report.append((name, a, b, len(objs), end + 2))
        name = bodies[key][0]
        calls.append('ldx #%d' % a)
        calls += ['jsr %s' % name] * (b - a)
        prev = (pf, (objs[-1][2] if objs else prev_col), bool(objs), objs[-1][0] if objs else None)

    trogg_strip = [0] * 96
    top = 176 // 2 - len(TROGG)
    for i, s in enumerate(TROGG):
        trogg_strip[top + i] = bits(s)
    tx = scr['trogg_x']
    yoyo_x = tx + 16

    def assemble(aligned):
        o = ['        processor 6502']
        o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
        o += ['GRP0 = $1B', 'COLUP0 = $06', 'RESM0 = $12', 'ENAM0 = $1D', 'COLUPF = $08',
              'PF0 = $0D', 'PF1 = $0E', 'PF2 = $0F', 'TrogPtr = $80']
        o.append('''        seg code
        org $F000
Start:  sei
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
        lda #0
        sta CTRLPF
        sta COLUP1
        sta GRP1
        sta GRP0
        sta PF0
        sta PF1
        sta PF2
        lda #1
        sta NUSIZ1
        lda #$25
        sta NUSIZ0             ; double-width Trogg, 4-pixel yoyo
        lda #>TroggStrip
        sta TrogPtr+1
        lda #<(TroggStrip-1)
        sta TrogPtr''' % (BG, TROGG_COL))
        for reg, xx in (('RESP0', tx), ('RESM0', yoyo_x)):
            c = (xx + 68) // 3 if reg == 'RESM0' else (xx + 63) // 3
            o.append('        sta WSYNC\n        ' + pad(c - 3).replace('\n', '\n        ') + '\n        sta %s' % reg)
        o.append('''        ldx #33
VB:     sta WSYNC
        dex
        bne VB
        lda #0
        sta VBLANK''')
        o += ['        ' + c for c in calls]
        o.append('''        sta WSYNC
        lda #0
        sta GRP0
        sta GRP1
        sta ENAM0
        sta PF0
        sta PF1
        sta PF2
        lda #2
        sta VBLANK
        ldx #30
OS:     sta WSYNC
        dex
        bne OS
        jmp Frame''')
        o.append('Bodies:')
        for key, (name, code, _) in bodies.items():
            if name in aligned:
                o.append('        align 256')
            for c in code:
                if c.endswith(':'):
                    o.append(c)
                else:
                    o += ['        ' + s for s in c.split('\n') if s.strip()]
        o.append('BodiesEnd:\n        align 256')
        for n in ('EvenCol', 'OddCol', 'Ladder', 'Item'):
            o.append('        align 128      ; 96-byte row tables never cross a page (a crossing costs a cycle)')
            o.append('%s: .byte %s' % (n, ','.join('$%02X' % v for v in t[n])))
        o.append('        align 256\nTroggStrip: .byte ' + ','.join('$%02X' % v for v in trogg_strip))
        o.append('        org $FFFC\n        .word Start\n        .word Start')
        open(base + '.asm', 'w').write('\n'.join(o) + '\n')
        r = subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        if r.returncode:
            print(r.stdout[-2000:])
            sys.exit('dasm failed')
        import re
        labels, brs = {}, []
        for line in open(base + '.lst'):
            m = re.match(r'\s*\d+\s+([0-9a-f]{4})\s+(?:[0-9a-f]{2}\s)*\s*([A-Za-z_]\w*)\s', line)
            if m:
                labels[m.group(2)] = int(m.group(1), 16)
            m = re.match(r'\s*\d+\s+([0-9a-f]{4})\s+[0-9a-f]{2} [0-9a-f]{2}\s+(?:\w+\s+)?bcs\s+(\w+)', line)
            if m:
                brs.append((int(m.group(1), 16), m.group(2)))
        cross = {lab.split('_')[0] for at, lab in brs if (at + 2) >> 8 != labels[lab] >> 8}
        return cross, labels
    aligned = set()
    while True:
        cross, labels = assemble(aligned)
        if not cross:
            break
        aligned |= cross
    return rows, t, runs, bodies, report, calls, labels


def compare(png, rows, t, tx):
    im = Image.open(png).convert('RGB')
    sx = im.width / 160
    bg = (90, 176, 212)
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg) + 1
    bad = []
    for y in range(192):
        row = rows[y // 2]
        want = set()
        for b in range(40):
            if all(x in row['pf'] for x in range(4 * b, 4 * b + 4)):
                want |= set(range(4 * b, 4 * b + 4))
        for x, g, c in row['objs']:
            v = g[1] if g[0] == 'imm' else t[g[1]][y // 2]
            want |= {x + i for i in range(8) if v & (0x80 >> i)}
        got = {x for x in range(160) if im.getpixel((int((x + 0.5) * sx), first + y)) != bg}
        skip = set(range(tx - 1, tx + 22))           # Trogg and the yoyo
        if (want - skip) != (got - skip):
            bad.append((y, sorted(want - got - skip)[:10], sorted(got - want - skip)[:10]))
    return bad


if __name__ == '__main__':
    which = sys.argv[1] if len(sys.argv) > 1 else 'fr'
    outdir = os.path.abspath(sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, 'out', 'screens2'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, which)
    rows, t, runs, bodies, report, calls, labels = build(which, base)
    print('%s: %d runs, %d bodies' % (which, len(runs), len(bodies)))
    print('layout changes:', '; '.join(CHANGES))
    for a, b, o in DROPPED:
        print('  dropped on rows %d-%d (lines %d-%d): %s at x %d' % (a, b, 2 * a, 2 * b + 1, o[1][1] if o[1][0] == 'tbl' else 'step', o[0]))
    over = [r for r in report if r[4] > 55]
    for name, a, b, n, fall in report:
        print('  %-4s rows %2d-%2d  %d objects  odd falls through at %d%s' % (
            name, a, b - 1, n, fall, '' if fall <= 55 else '   <-- over the 55 budget'))
    calls_bytes = sum(2 if c.startswith('ldx') else 3 for c in calls)
    print('bodies %d bytes, call list %d bytes, row tables %d bytes, Trogg strip 96' % (
        labels['BodiesEnd'] - labels['Bodies'], calls_bytes, 4 * 96))
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    bad = compare(base + '.png', rows, t, SCREENS[which]['trogg_x'])
    print('%d of 192 lines differ from the model (Trogg/yoyo columns excluded)' % len(bad))
    for y, m, e in bad[:15]:
        print('  line %3d: missing %s extra %s' % (y, m, e))
