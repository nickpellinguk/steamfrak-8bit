#!/usr/bin/env python3
"""
The first big test: an "FR" screen using all the tricks so far, with F on the left half of the
screen and R on the right. Route: Trogg starts at the bottom of the F, climbs the F's stem, goes
along the top bar, jumps from the F's top right to the R's top left, takes the key at the R's
bottom left, goes up and round the R's bowl and down its leg to the bottom right.

    python3 atarivcs/test/fr_screen.py [OUT_DIR]

Drawing:
  * Long platforms: the asymmetric playfield (4-pixel blocks), coloured per line from a table
    (1 black, 2 magenta, 1 black, 4 dark cyan).
  * A ladder that crosses a long platform isn't drawn on the platform's lines, so it seems to
    pass behind it (the background writes leave no room for it there).
  * Ladders, gems, the key and single-block cascade steps: player-1 copies (NUSIZ1 = two close,
    one RESP1 strobe each). Each copy gets its own GRP1 and, where the colour changes, its own
    COLUP1, written after the previous copy has finished and before this one starts. Steps take
    the platform colours line by line; ladders and gems are black; the key is yellow.
  * Trogg: player 0, double width, once.

A scheduler builds each run of lines (consecutive lines with the same structure; per-line values
come from tables indexed by Y) from timing rules measured in Stella:
  * a strobe ending at cycle c puts a copy at x = 3c - 47 (no copy left of x = 19);
  * a copy is drawn from cycle (68 + x) / 3 for 8/3 cycles;
  * playfield writes, by the cycle the STA ends: left PF0 <= 22, PF1 <= 27, PF2 <= 38;
    right PF0 29-49, PF1 39-54, PF2 50-65; COLUPF <= 22;
  * a line's last store must end by cycle 65 (then iny/cpy/bne and the next STA WSYNC);
  * with only one copy on a line, GRP1 is cleared after it and RESP1 strobed again far right;
    if the copy is too far right for that, an invisible copy (GRP1 = 0) at x=19 is added first.
After the snapshot it compares every line with the model (Trogg's columns excluded).
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tiatest  # noqa: E402
from trogg_rows import TROGG, bits  # noqa: E402
from platforms import pf_regs, cycles  # noqa: E402
from PIL import Image  # noqa: E402

pad = tiatest.pad
BG, DARK, MAGENTA, BLACK, YELLOW = 0xAA, 0xA4, 0x58, 0x00, 0x1E
PLATFORM_COLOURS = [BLACK, MAGENTA, MAGENTA, BLACK, DARK, DARK, DARK, DARK]

TROGG_X = 48                       # double width: 48-63, standing on the F's floor
TROGG_RESP0_END = 37
TROGG_TOP = 176 - 2 * len(TROGG)   # his feet on line 175

LADDER_POLE, LADDER_RUNG = 0x18, 0x7E
GEM = ['...XX...', '..X..X..', '.X....X.', 'X......X', '.X....X.', '..X..X..', '...XX...']
KEY = ['.XX.....', 'X..X....', 'X..XXXXX', 'X..X.X.X', '.XX.....']

# ---- the screen -----------------------------------------------------------------------------
# Long platforms (playfield): (top line, first x, last x); 8 lines each. x on 4-pixel blocks.
PLATFORMS = [
    (24, 12, 71),      # F top bar
    (88, 12, 63),      # F middle bar
    (176, 8, 67),      # F floor (Trogg starts here)
    (24, 92, 139),     # R top bar
    (88, 100, 139),    # R middle bar (the bottom of the bowl)
    (176, 88, 127),    # R floor at the bottom left (the key is here)
    (176, 140, 155),   # R bottom right (end of the leg)
]
# Single-block steps (P1 copies, 8 px): (top line, x); 8 lines each; x = 3c - 47.
STEPS = [
    (36, 145), (52, 148), (68, 145),                  # R bowl: out and back in
    (104, 130), (120, 136), (136, 145), (152, 148),   # R leg: down to the right (not 133 or 142: see notes)
]
LADDERS = [(28, 32, 176), (97, 32, 176)]              # (x, first line, last line + 1): F stem, R stem
ITEMS = [('gem', 64, 17), ('gem', 55, 81), ('gem', 133, 81), ('key', 118, 171)]   # (kind, x, top)


def model():
    """Per line: PF lit pixels, P1 objects [(x, gfx table, colour source)], tables."""
    t = {n: [0] * 256 for n in ('PCol', 'SCol', 'Trogg', 'Ladder', 'Item')}
    lines = [{'pf': set(), 'objs': []} for _ in range(192)]
    for top, a, b in PLATFORMS:
        for i in range(8):
            lines[top + i]['pf'] |= set(range(a, b + 1))
            t['PCol'][top + i] = PLATFORM_COLOURS[i]
    for top, x in STEPS:
        for i in range(8):
            lines[top + i]['objs'].append((x, ('imm', 0xFF), ('tbl', 'SCol')))
            t['SCol'][top + i] = PLATFORM_COLOURS[i]
    for x, a, b in LADDERS:
        for y in range(a, b):
            if any(px in lines[y]['pf'] for px in range(x, x + 8)):
                continue                  # passes behind a long platform: not drawn on its lines
            lines[y]['objs'].append((x, ('tbl', 'Ladder'), ('imm', BLACK)))
            t['Ladder'][y] = LADDER_RUNG if y % 8 == 4 else LADDER_POLE
    for kind, x, top in ITEMS:
        rows = GEM if kind == 'gem' else KEY
        for i, r in enumerate(rows):
            lines[top + i]['objs'].append((x, ('tbl', 'Item'), ('imm', BLACK if kind == 'gem' else YELLOW)))
            t['Item'][top + i] = bits(r)
    for i in range(2 * len(TROGG)):
        t['Trogg'][TROGG_TOP + i] = bits(TROGG[i // 2])
    for ln in lines:
        ln['objs'].sort()
    return lines, t


# ---- the scheduler --------------------------------------------------------------------------
def load(src):
    kind, v = src
    return ('lda #$%02X' % v, 2) if kind == 'imm' else ('lda %s,y' % v, 4)


def schedule(pf, prev_pf, objs, prev_last_colour, prev_had_objs, prev_last_x=None):
    """Returns (instructions, end cycle) or raises ValueError. pf = (L0,L1,L2),(R0,R1,R2)."""
    (L, R), (pL, pR) = pf, prev_pf
    tasks = []                                   # (lo, hi, load, store-register, note)
    tasks.append((0, (68 + TROGG_X) // 3 - 1, ('lda Trogg,y', 4), 'GRP0'))
    names = ('PF0', 'PF1', 'PF2')
    left_hi, right_win = (22, 27, 38), ((29, 49), (39, 54), (50, 65))
    any_pf = any(L) or any(R) or any(pL) or any(pR)
    if any(L) or any(R):
        tasks.append((0, 22, ('lda PCol,y', 4), 'COLUPF'))
    if any_pf:
        for i in range(3):
            if L[i] != R[i] or pR[i] != L[i]:
                tasks.append((0, left_hi[i], ('lda #$%02X' % L[i], 2), names[i]))
            if R[i] != L[i]:
                lo, hi = right_win[i]
                tasks.append((lo, hi, ('lda #$%02X' % R[i], 2), names[i]))
    if len(objs) == 1 and -(-(68 + objs[0][0] + 8) // 3) > 62:
        # One copy, too far right to clear GRP1 after it and strobe again: add an invisible copy
        # at x=19 first, so the line has two and the next line's first strobe resets P1 before
        # its main copy comes round.
        objs = [(19, ('imm', 0), ('none', 0))] + list(objs)
    # P1's main copy from the line before waits 16 px left of that line's last copy. On a run's
    # first line, the line before belongs to the previous run; unless this line's first strobe
    # comes well before it (21 px: a strobe 5 px before it was not enough), keep GRP1 at 0 while
    # it's drawn and write this line's graphics only after it.
    after_main = 0
    if prev_last_x is not None and objs:
        main = prev_last_x - 16
        c0 = 3 if objs[0][2][0] == 'none' else (objs[0][0] + 47) // 3
        if 3 * c0 - 68 > main - 21:
            tasks.append((0, (68 + main) // 3, ('lda #0', 2), 'GRP1'))
            after_main = -(-(68 + main + 8) // 3)
    strobes = []
    prev_end, prev_col = 0, None
    for k, (x, gfx, col) in enumerate(objs):
        assert x >= 19 and (x + 47) % 3 == 0, x
        c = (x + 47) // 3
        if col[0] == 'none':
            c = 3              # any strobe in the blank gives a copy at x=19: do it first
        start = (68 + x) / 3                         # the copy starts being drawn
        hi = int(start)                              # stores must END by then (start is not whole)
        if hi == start:
            hi -= 1
        strobes.append(c)
        lo = prev_end
        if after_main and (68 + x) / 3 > after_main - 1:
            lo = max(lo, after_main)                 # only after the old main copy is drawn
        tasks.append((lo, hi, load(gfx), 'GRP1'))
        # colour at the start of a line: the last object's colour on the line before (this run's
        # last object, or for the run's first line the previous run's); skip if it's already right
        if col[0] == 'none':
            need = False                             # the invisible copy: colour doesn't matter
        elif k == 0 or prev_col == ('none', 0):
            start_col = objs[-1][2]
            need = (col[0] == 'tbl' or col != start_col or col != prev_last_colour)
        else:
            need = col[0] == 'tbl' or col != prev_col
        if need:
            tasks.append((prev_end, hi, load(col), 'COLUP1'))
        prev_end = -(-(68 + x + 8) // 3)             # cycle by which this copy is finished
        prev_col = col if col[0] != 'none' else prev_col
    if len(objs) == 1:
        tasks.append((prev_end, 65, ('lda #0', 2), 'GRP1'))
        tasks.append(('spare', prev_end + 3))
    if not objs and prev_had_objs:
        tasks.append((0, 65, ('lda #0', 2), 'GRP1'))
    spare = [tk for tk in tasks if tk[0] == 'spare']
    tasks = [tk for tk in tasks if tk[0] != 'spare']

    # Search over orders. Each task is a value (loaded with a given instruction) to be stored to
    # a register so the store ENDS in [lo, hi]. Loads are separate steps: a value can be loaded
    # into A or X early and stored later (strobes don't disturb A or X). Stores can be 3 cycles
    # (zero page) or 4 (absolute, .w) to make up odd gaps. State: (t, tasks left, strobes done,
    # task held in A, task held in X).
    T = [(lo, hi, ins, ln, reg) for lo, hi, (ins, ln), reg in tasks]
    fail = set()

    def search(t, rem, si, ha, hx):
        # ha, hx: the load instruction whose value A / X holds (so equal values are reused)
        key = (t, rem, si, ha, hx)
        if key in fail:
            return None
        if not rem and si == len(strobes):
            return [], t
        nxt = strobes[si] if si < len(strobes) else None
        limit = nxt - 3 if nxt is not None else 65
        for i in rem:                                # prune: a store that can no longer make it
            lo, hi, ins, ln, reg = T[i]
            need = 3 if ins in (ha, hx) else ln + 3
            if max(t + need, lo) > hi:
                fail.add(key)
                return None
        def ok(end):                                 # can we still reach the next strobe exactly?
            return end <= limit and (nxt is None or limit - end != 1)
        opts = []
        loads = set()
        for i in rem:
            lo, hi, ins, ln, reg = T[i]
            for r in ('a', 'x'):
                held = ha if r == 'a' else hx
                if held == ins:                      # store it from this register
                    for st in (3, 4):
                        land = max(t + st, lo)
                        if land - st - t == 1 or land > hi or not ok(land):
                            continue
                        opts.append((hi, 0, land, st, i, r, 'store'))
                elif ins not in (ha, hx) and (ins, r) not in loads and ok(t + ln):
                    loads.add((ins, r))
                    opts.append((hi, 1, t + ln, 0, i, r, 'load'))
        for hi, _, end, st, i, r, what in sorted(opts):
            lo, _, ins, ln, reg = T[i]
            if what == 'store':
                gap = end - st - t
                ins_s = 'st%s%s %s' % (r, '.w' if st == 4 else '', reg)
                res = search(end, rem - {i}, si, ha, hx)
                if res is not None:
                    return ([pad(gap)] if gap else []) + [ins_s] + res[0], res[1]
            else:
                ins_l = ins if r == 'a' else ins.replace('lda', 'ldx')
                res = search(end, rem, si, ins if r == 'a' else ha, ins if r == 'x' else hx)
                if res is not None:
                    return [ins_l] + res[0], res[1]
        if nxt is not None and nxt - 3 - t >= 0:
            gap = nxt - 3 - t
            st = 'sta RESP1'
            if gap == 1:
                gap, st = 0, 'sta.w RESP1'           # a 4-cycle strobe ending on the same cycle
            res = search(nxt, rem, si + 1, ha, hx)
            if res is not None:
                return ([pad(gap)] if gap else []) + [st] + res[0], res[1]
        fail.add(key)
        return None

    res = search(0, frozenset(range(len(T))), 0, None, None)
    if res is None:
        raise ValueError('no schedule fits (tasks %s, strobes %s)' % (T, strobes))
    out, t = res

    def emit_pad(n):
        nonlocal t
        if n:
            out.append(pad(n))
            t += n
    for _, at in spare:
        emit_pad(max(0, at - 3 - t) if max(0, at - 3 - t) != 1 else 2)
        out.append('sta RESP1')
        t += 3
    if t > 65:
        raise ValueError('line ends at cycle %d (> 65)' % t)
    return out, t


# ---- the ROM ----------------------------------------------------------------------------------
def runs(lines):
    """Group lines with the same structure: (first, end, pf regs, objs)."""
    out = []
    for y, ln in enumerate(lines):
        key = (tuple(map(tuple, pf_regs(ln['pf']))), tuple((x, g, c) for x, g, c in ln['objs']))
        if out and out[-1][2] == key:
            out[-1][1] = y + 1
        else:
            out.append([y, y + 1, key])
    return out


def build(base):
    lines, tables = model()
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['GRP0     = $1B', 'COLUPF   = $08', 'PF0      = $0D', 'PF1      = $0E', 'PF2      = $0F']
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
        lda #$%02X
        sta COLUP0
        lda #0
        sta CTRLPF
        sta PF0
        sta PF1
        sta PF2
        sta GRP1
        lda #5
        sta NUSIZ0
        lda #1
        sta NUSIZ1
        sta WSYNC''' % (BG, MAGENTA))
    o.append('        ' + pad(TROGG_RESP0_END - 3).replace('\n', '\n        '))
    o.append('''        sta RESP0
        ldx #34
VB:     sta WSYNC
        dex
        bne VB
        ldy #0
        sta WSYNC
        lda #0
        sta VBLANK''')
    prev_pf, prev_col, prev_objs, prev_x = ((0, 0, 0), (0, 0, 0)), None, False, None
    worst = 0
    rs = runs(lines)
    for i, (a, b, (pf, objs)) in enumerate(rs):
        try:
            code, end = schedule(pf, prev_pf, list(objs), prev_col, prev_objs, prev_x)
        except ValueError as e:
            sys.exit('lines %d-%d: %s\n  objects %s' % (a, b - 1, e, objs))
        n = sum(4 if i.startswith(('sta.w', 'stx.w')) else cycles(i) for chunk in code
                for i in (x.strip() for x in chunk.split('\n')) if i)
        assert n == end, ('cycle count mismatch', a, n, end, code)
        worst = max(worst, end)
        o.append('; --- lines %d-%d: %d objects, ends at cycle %d' % (a, b - 1, len(objs), end))
        o.append('R%d:     sta WSYNC' % i)
        o += ['        ' + s for chunk in code for s in chunk.split('\n') if s.strip()]
        o.append('        iny\n        cpy #%d\n        bne R%d' % (b % 256, i))
        prev_pf, prev_objs = pf, bool(objs)
        prev_x = objs[-1][0] if objs else None
        if objs:
            prev_col = objs[-1][2]
    o.append('''        sta WSYNC
        lda #0
        sta GRP0
        sta GRP1
        sta PF0
        sta PF1
        sta PF2
        lda #2
        sta VBLANK
        ldx #29
OS:     sta WSYNC
        dex
        bne OS
        jmp Frame''')
    o.append('        org $FB00')
    for name in ('PCol', 'SCol', 'Trogg', 'Ladder', 'Item'):
        o.append('%s:' % name)
        for k in range(0, 192, 16):
            o.append('        .byte ' + ','.join('$%02X' % v for v in tables[name][k:k + 16]))
        o.append('        ds 64, 0' if name != 'Item' else '')
    o.append('        org $FFFC\n        .word Start\n        .word Start')
    open(base + '.asm', 'w').write('\n'.join(o) + '\n')
    subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                   check=True, stdout=subprocess.DEVNULL)
    return lines, len(rs), worst


def compare(png, lines):
    im = Image.open(png).convert('RGB')
    sx = im.width / 160
    bg = im.getpixel((im.width - 2, im.height // 2))
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg) + 1
    tables = model()[1]
    bad = 0
    for y, ln in enumerate(lines):
        want = set()
        for b in range(40):
            if all(x in ln['pf'] for x in range(4 * b, 4 * b + 4)):
                want |= set(range(4 * b, 4 * b + 4))
        for x, g, c in ln['objs']:
            v = g[1] if g[0] == 'imm' else tables[g[1]][y]
            want |= {x + i for i in range(8) if v & (0x80 >> i)}
        got = {x for x in range(160) if im.getpixel((int((x + 0.5) * sx), first + y)) != bg}
        skip = set(range(TROGG_X - 2, TROGG_X + 18)) if tables['Trogg'][y] else set()
        if (want - skip) != (got - skip):
            bad += 1
            if bad <= 12:
                print('line %3d: missing %s extra %s' % (y, sorted(want - got - skip)[:12],
                                                          sorted(got - want - skip)[:12]))
    print('%d of 192 lines differ from the model' % bad)


if __name__ == '__main__':
    outdir = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'out'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'fr_screen')
    lines, nruns, worst = build(base)
    print('%d runs, busiest line ends at cycle %d' % (nruns, worst))
    png = tiatest.snapshot(base + '.bin', outdir)
    if not png:
        sys.exit('no snapshot')
    os.replace(png, base + '.png')
    im = Image.open(base + '.png')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    print('snapshot', base + '.png', im.size)
    compare(base + '.png', lines)
