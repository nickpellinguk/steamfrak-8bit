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
BUFFER = '--buffer' in sys.argv             # Trogg: index strip in ROM + frame copied to a RAM buffer
ODDINX = '--oddinx' in sys.argv             # the line INX in the odd prefix (shared block from 12)
EXACT = next((int(a.split('=')[1]) for a in sys.argv if a.startswith('--exact=')), None)
# --exact=E: no WSYNC in the kernel; every odd line falls through its BCS at cycle E, then
# INX + RTS + 4 call-list cycles + JSR = 18, so every body starts at S0 = E - 58 on both lines
S0 = EXACT - 58 if EXACT is not None else 0
NOMIDSYNC = '--nomidsync' in sys.argv or EXACT is not None       # no STA WSYNC between a row's lines: the even line is padded to 76
if BUFFER:
    LIMIT = (EXACT - 3) if EXACT is not None else 53 if ODDINX or NOMIDSYNC else 51                                # odd line falls through by 53: the longer even tail
LINES = '--lines' in sys.argv               # X counts lines: tables per line, INX in the even tail
ROWSTRIPES = '--rowstripes' in sys.argv or LINES     # one stripe colour per row (from a row table)
ROW_STRIPES = [BLACK, MAGENTA, DARK, DARK]
# Two entry points (the current kernel): 'name_i: inx' falls into 'name:'; a run's first row is
# 'ldx #line / jsr name', its other rows 'jsr name_i', and bodies end 'bcs even / rts'. The INX is
# then off the odd line's path at a renderer change, so the odd line may fall through by 57
# (LDX zp) and the last store end by 55; the even line agrees (Trogg tail 18, no mid-row WSYNC).
TWOENTRY = LINES and BUFFER and NOMIDSYNC and EXACT is None and '--oneentry' not in sys.argv
if TWOENTRY:
    LIMIT = 55
MAXX = 3 * LIMIT - 47                # the furthest-right copy: a strobe ending at LIMIT
CHANGES = []
DROPPED = []
MIDSYNC = []
GUARDS = []

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
        # ghost rule measured in park_test.py: the old main copy is cancelled if this line's first
        # strobe ends at least one cycle before the strobe that made it
        ("        if 3 * c0 - 68 > main - 21:", "        if c0 >= (prev_last_x + 47) // 3:"),
        # consecutive objects with the same graphics need no GRP1 rewrite (GRP1 keeps its value)
        ("        tasks.append((lo, hi, load(gfx), 'GRP1'))\n",
         "        if k == 0 or gfx != objs[k - 1][1] or objs[k - 1][2][0] == 'none':\n"
         "            tasks.append((lo, hi, load(gfx), 'GRP1'))\n"),
        ("    tasks.append((0, (68 + TROGG_X) // 3 - 1, ('lda Trogg,y', 4), 'GRP0'))\n", ""),
        ("('lda PCol,y', 4)", "load(('stripe', 0))"),
        ("            c = 3              # any strobe", "            c = t0 + 3         # any strobe"),
        ("            need = 3 if ins in (ha, hx) else ln + 3",
         "            need = 3 if ins in (ha, hx, 'Y') else ln + 3"),
        ("            for r in (('a',) if '(' in ins else ('a', 'x')):   # no LDX (zp),y\n"
         "                held = ha if r == 'a' else hx\n",
         "            for r in (('y',) if ins == 'Y' else (('a', 'x') if FREEY else ('a',))):   # X is the row index; 'x' here means Y\n"
         "                held = 'Y' if ins == 'Y' else (ha if r == 'a' else hx)\n"),
        ("ins_l = ins if r == 'a' else ins.replace('lda', 'ldx')", "ins_l = ins if r == 'a' else ins.replace('lda', 'ldy')"),
        ("ins_s = 'st%s%s %s' % (r, '.w' if st == 4 else '', reg)",
         "ins_s = 'st%s%s %s' % ({'a': 'a', 'x': 'y', 'y': 'y'}[r], '.w' if st == 4 else '', reg)"),
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
        return ('lda Stripe,x', 4) if ROWSTRIPES else ('Y', 0)   # (in LINES mode Stripe is per line)
    return ('lda %s,x' % v, 4)


_ns['load'] = _load
_ns['FREEY'] = False
exec(_src, _ns)
schedule = _ns['schedule']


# ---- the screen as rows ---------------------------------------------------------------------
def model(scr):
    rows = [{'pf': set(), 'objs': []} for _ in range(96)]
    t = {n: [0] * 96 for n in ('EvenCol', 'OddCol', 'Ladder', 'Item', 'Stripe')}
    L = {n: [0] * 192 for n in ('Ladder', 'Item', 'Stripe')}
    phase = [None] * 96

    def stripe(r, top):
        k = 2 * r - top
        p = (STRIPES[k], STRIPES[k + 1])
        assert phase[r] in (None, p), ('stripe clash at row', r)
        phase[r] = p
        t['EvenCol'][r], t['OddCol'][r] = p
        t['Stripe'][r] = ROW_STRIPES[k // 2]
        L['Stripe'][2 * r], L['Stripe'][2 * r + 1] = p
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
            for y in (2 * r, 2 * r + 1):
                L['Ladder'][y] = LADDER_RUNG if y % 8 == 4 else LADDER_POLE
    for kind, x, bottom in scr['items']:
        if x > MAXX:
            CHANGES.append('%s x %d -> %d' % (kind, x, MAXX))
            x = MAXX
        g = GEM if kind == 'gem' else KEY
        if LINES:                       # single-line pixel rows, bottom on the given line
            for i, s in enumerate(g):
                y = bottom - len(g) + i
                o = (x, ('tbl', 'Item'), ('imm', BLACK if kind == 'gem' else YELLOW))
                if o not in rows[y // 2]['objs']:
                    rows[y // 2]['objs'].append(o)
                L['Item'][y] = bits(s)
            continue
        for i, s in enumerate(g):
            r = bottom // 2 - len(g) + i
            rows[r]['objs'].append((x, ('tbl', 'Item'), ('imm', BLACK if kind == 'gem' else YELLOW)))
            t['Item'][r] = bits(s)
    for r in rows:
        r['objs'].sort()
    if LINES:
        t = L
    return rows, t


def body_code(name, code, uses_y, end=None):
    ld = ['ldy EvenCol,x'] if uses_y else []
    lo = ['ldy OddCol,x'] if uses_y else []
    # even prefix falls into the shared block; the even tail falls into the odd line, whose prefix
    # jumps back to the shared block (the JMP replaces the odd prefix's 3-cycle pad)
    look = ['tay', 'lda Buffer,y'] if BUFFER else []
    odd = ODDINX and LINES
    out = (['%s_i:' % name, 'inx'] if TWOENTRY else []) + ['%s:' % name] + ([] if EXACT is not None else ['sta WSYNC']) + ['inc TrogPtr'] + ld + ['sec', 'bit $80'] + (['nop'] if odd else [])
    oddpad = []
    if EXACT is not None:
        k = EXACT - (end + 2)
        assert k >= 0 and k != 1, ('odd line', name, k)
        oddpad = [pad(k)] if k else []
    out += ['%s_s:' % name] + code + ['bcs %s_e' % name] + oddpad + ([] if TWOENTRY else ['inx']) + ['rts']
    out += ['%s_e:' % name, 'ldy #0', 'lda (TrogPtr),y'] + look + ['sta GRP0'] + (['inx'] if LINES and not odd else [])
    tail = out[out.index('%s_e:' % name) + 1:]
    # STA WSYNC between the row's lines wherever it still writes by cycle 75 (2 bytes, resyncs the
    # line); only bodies whose shared block ends too late pad the even line to exactly 76 instead
    if NOMIDSYNC and (EXACT is not None or end + 3 + ncycles(tail) + 3 > 75):
        MIDSYNC.append((name, 'padded'))
        n = 76 + S0 - (end + 3 + ncycles(tail))
        assert n >= 0, ('even line too long', name, n)
        if n == 1:
            out[out.index('sta GRP0')] = 'sta.w GRP0'
        elif n:
            out.append(pad(n))
        out += ['asl', 'sta ENAM0'] + lo + (['inx'] if odd else []) + ['clc', 'jmp %s_s' % name]
        return out
    MIDSYNC.append((name, 'wsync'))
    out += ['sta WSYNC', 'asl', 'sta ENAM0'] + lo + (['inx'] if odd else []) + ['clc', 'jmp %s_s' % name]
    return out


def strobe_cycles(code, t0):
    t, out = t0, []
    for i in (x.strip() for c in code for x in c.split('\n') if x.strip()):
        t += ncycles([i])
        if 'RESP1' in i:
            out.append(t)
    return out


def ncycles(code):
    return sum(2 if len(i.split()) == 1 else 5 if '),y' in i else 4 if i.startswith(('sta.w', 'stx.w', 'sty.w')) or i.endswith(',x') else cycles(i)
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
            uses_y = not ROWSTRIPES and (any(pf[0]) or any(pf[1]) or any(o[2][0] == 'stripe' for o in objs))
            t0 = (T0 if uses_y else T0 - 4) + (2 if ODDINX and LINES else 0) + S0
            while res is None:
                _ns['FREEY'] = not uses_y        # Y is a second working register unless it holds the stripe
                try:
                    res = schedule(pf, prev_pf, keep, prev_col, prev_objs, prev_x, t0=t0, end_limit=LIMIT)
                except ValueError:
                    if not keep:
                        sys.exit('rows %d-%d: even the playfield alone does not fit' % (a, b - 1))
                    DROPPED.append((a, b - 1, keep.pop()))
            code, end = res
            assert ncycles(code) == end - t0, (a, ncycles(code), end)
            name = 'R%d' % len(bodies)
            strobes = strobe_cycles(code, t0)
            bodies[key] = (name, body_code(name, code, uses_y, end), end + 2, strobes, keep)
            report.append((name, a, b, len(objs), end + 2))
        name, _, _, strobes, keep = bodies[key]
        if prev_x is not None and strobes:
            cprev = 22 if prev_x == 19 else (prev_x + 47) // 3
            GUARDS.append((a, name, strobes[0], cprev, strobes[0] >= cprev))
        calls.append('ldx #%d' % (2 * a if LINES else a))
        if EXACT is not None:            # every return path takes 4 call-list cycles
            calls.append('nop')
            calls += ['jsr %s' % name, 'nop', 'nop'] * (b - a)
            calls = calls[:-2]
            calls.append('PADNEXT')
        else:
            calls += ['jsr %s' % name] + ['jsr %s_i' % name] * (b - a - 1) if TWOENTRY else ['jsr %s' % name] * (b - a)
        last_x = None
        if strobes:                      # the body's real last strobe (a spare one included)
            last_x = 19 if strobes[-1] <= 22 else 3 * strobes[-1] - 47
        prev = (pf, (keep[-1][2] if keep else prev_col), bool(keep),
                last_x if strobes else prev_x)

    trogg_strip = [0] * 96
    top = 176 // 2 - len(TROGG)
    for i, s in enumerate(TROGG):
        trogg_strip[top + i] = (i + 1) if BUFFER else bits(s)
    tx = scr['trogg_x']
    yoyo_x = tx + 16

    def assemble(aligned):
        o = ['        processor 6502']
        o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
        o += ['GRP0 = $1B', 'COLUP0 = $06', 'RESM0 = $12', 'ENAM0 = $1D', 'COLUPF = $08',
              'PF0 = $0D', 'PF1 = $0E', 'PF2 = $0F', 'TrogPtr = $80', 'Buffer = $82']
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
        if BUFFER:                       # copy the current frame into the RAM buffer (Buffer+0 stays 0)
            o.append('''        ldy #%d
CopyF:  lda TroggFrame-1,y
        sta Buffer,y
        dey
        bne CopyF''' % len(TROGG))
        for reg, xx in (('RESP0', tx), ('RESM0', yoyo_x)):
            c = (xx + 68) // 3 if reg == 'RESM0' else (xx + 63) // 3
            o.append('        sta WSYNC\n        ' + pad(c - 3).replace('\n', '\n        ') + '\n        sta %s' % reg)
        vb = 33
        o.append('''        ldx #%d
VB:     sta WSYNC''' % vb + '''
        dex
        bne VB
        lda #0
        sta VBLANK''')
        if EXACT is not None:
            p0 = (S0 - 19) % 76          # 9 cycles since the last VB WSYNC, 10 for ldx/nop/jsr
            p0 = p0 + 76 if p0 == 1 else p0
            if p0:
                o += ['        ' + q for q in pad(p0).split('\n')]
            cl = []
            for c in calls:                  # between runs the LDX path: 'ldx #n / nop' (4 cycles)
                cl.append(c)
            cl = [c for c in cl if c != 'PADNEXT']
            # within a run: jsr / nop / nop; the last row of a run returns into the next 'ldx / nop'
            o += ['        ' + c for c in cl]
        else:
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
        for key, (name, code, *_) in bodies.items():
            if name in aligned:
                o.append('        align 256')
            for c in code:
                if c.endswith(':'):
                    o.append(c)
                else:
                    o += ['        ' + s for s in c.split('\n') if s.strip()]
        o.append('BodiesEnd:\n        align 256')
        for n in t:
            o.append('        align %d      ; tables never cross a page (a crossing costs a cycle)' % (256 if LINES else 128))
            o.append('%s:' % n)
            for k in range(0, len(t[n]), 16):
                o.append('        .byte ' + ','.join('$%02X' % v for v in t[n][k:k + 16]))
        o.append('        align 256\nTroggStrip:')
        for k in range(0, 96, 16):
            o.append('        .byte ' + ','.join('$%02X' % v for v in trogg_strip[k:k + 16]))
        if BUFFER:
            o.append('TroggFrame: .byte ' + ','.join('$%02X' % bits(r) for r in TROGG))
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
            v = g[1] if g[0] == 'imm' else t[g[1]][y if LINES else y // 2]
            want |= {x + i for i in range(8) if v & (0x80 >> i)}
        got = {x for x in range(160) if im.getpixel((int((x + 0.5) * sx), first + y)) != bg}
        skip = set(range(tx - 1, tx + 24))           # Trogg and the yoyo
        if (want - skip) != (got - skip):
            bad.append((y, sorted(want - got - skip)[:10], sorted(got - want - skip)[:10]))
    return bad


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    which = args[0] if args else 'fr'
    outdir = os.path.abspath(args[1] if len(args) > 1 else os.path.join(HERE, 'out', 'screens2'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, which + ('_lines' if LINES else '_rows' if ROWSTRIPES else '') + ('_buf' if BUFFER else '') + ('_oddinx' if ODDINX else '') + ('_nms' if NOMIDSYNC else '') + ('_e%d' % EXACT if EXACT is not None else ''))
    rows, t, runs, bodies, report, calls, labels = build(which, base)
    print('%s: %d runs, %d bodies' % (which, len(runs), len(bodies)))
    print('layout changes:', '; '.join(CHANGES))
    print('between a row\'s lines: %d bodies use STA WSYNC, %d are padded to 76 cycles' % (
        sum(1 for b in MIDSYNC if b[1] == 'wsync'), sum(1 for b in MIDSYNC if b[1] == 'padded')))
    g = [x for x in GUARDS if x[4]]
    print('renderer changes with a P1 predecessor: %d; first strobe not earlier than the previous last (GRP1 held at 0 past the ghost): %d %s' % (
        len(GUARDS), len(g), ['row %d %s (first %d, previous last %d)' % x[:4] for x in g]))
    for a, b, o in DROPPED:
        print('  dropped on rows %d-%d (lines %d-%d): %s at x %d' % (a, b, 2 * a, 2 * b + 1, o[1][1] if o[1][0] == 'tbl' else 'step', o[0]))
    over = [r for r in report if r[4] > 55]
    for name, a, b, n, fall in report:
        print('  %-4s rows %2d-%2d  %d objects  odd falls through at %d%s' % (
            name, a, b - 1, n, fall, '' if fall <= 55 else '   <-- over the 55 budget'))
    calls_bytes = sum(0 if c == 'PADNEXT' else 1 if c == 'nop' else 2 if c.startswith('ldx') else 3 for c in calls)
    print('bodies %d bytes, call list %d bytes, tables %d bytes, Trogg strip 96' % (
        labels['BodiesEnd'] - labels['Bodies'], calls_bytes, sum(len(v) for v in t.values())))
    png = tiatest.snapshot(base + '.bin', outdir)
    os.replace(png, base + '.png')
    im = Image.open(base + '.png')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    bad = compare(base + '.png', rows, t, SCREENS[which]['trogg_x'])
    print('%d of 192 lines differ from the model (Trogg/yoyo columns excluded)' % len(bad))
    for y, m, e in bad[:15]:
        print('  line %3d: missing %s extra %s' % (y, m, e))
