#!/usr/bin/env python3
"""
A scrolling tower: the FR screen stacked on the A/K screen (192 rows of 2 scanlines), drawn by a
two-line kernel that scrolls in whole rows.

    python3 atarivcs/test/tower.py [--scroll N ...] [--auto] [OUT_DIR]

Kernel
  * Y is the level row (0-191). The screen shows 96 rows starting at the scroll row.
  * The level is cut into BLOCKS: runs of rows with the same structure (playfield registers and
    player-1 copy positions on the even and odd lines). One routine per block:
        Bk:     ldx #rows-1
        BkRow:  sta WSYNC
                ...even line...      (scheduled; includes the yoyo and Trogg reads)
                sta WSYNC
                ...odd line...       (scheduled; includes the balloon read)
                dey                  ; Y: screen rows left (96..1), counting down
                beq BkEx             ; the screen is finished, wherever we are
                dex                  ; rows left in this block; X also indexes the block's
                bpl BkRow            ;   per-row tables (colours, graphics): lda Table,x
                jmp <next block>     ; directly, or through a bank-switch stub
        BkEx:   jmp <overscan>
    Values that change from row to row within a block come from small tables indexed by X
    (laid out counting down, so entering a block partway gives the right row); values that don't
    are immediates. X is never used by the scheduled code for anything else.
  * Trogg (player 0), the yoyo (missile 0, even lines) and the balloon (the ball, odd lines) come
    from LDA (ptr),Y reads of page-safe strip tables (four pages per strip, the pointer's low
    byte 0-64, so a read never crosses a page). The pointers are in level rows, so they don't
    change with the scroll. Trogg's graphics are written on the even line and kept for the odd.
  * Scroll entry: for each scroll row a table gives the block, its bank and X; the frame code
    sets Rows = 96, Y = scroll, and jumps through an entry stub that is the same in every bank:
        Entry:  lda HotBase,x        ; select the block's bank
                ldx EntryX
                jmp (EntryPtr)
  * Bank switching (F6: 4 banks, or F4: 8): stubs at fixed addresses in $F010-$F0FF, each with
    the LDA of the target bank's hotspot in the source bank and a JMP in the target bank.
    Every bank has the strip pages at $F700-$FEFF; blocks and their tables fill $F100-$F6FF.

Budgets (cycle by which the scheduled part's last store must end): even line 72 (then STA WSYNC);
odd line 75 - 9 (lda/beq/iny/dex) - the worse of the loop (bpl taken, +1 if it crosses a page,
STA WSYNC) and the exit to the next block (bpl, jmp, [bank switch 7], ldx, STA WSYNC).

The snapshot for each fixed scroll is checked against the model, line by line, with Trogg's,
the yoyo's and the balloon's columns left out.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tiatest  # noqa: E402
import fr_screen as fr  # noqa: E402
from platforms import pf_regs  # noqa: E402
from trogg_rows import TROGG, bits  # noqa: E402
from PIL import Image  # noqa: E402

pad = tiatest.pad
ROWS_ON_SCREEN = 96
STRIP_OFFSETS = (0, 65, 130, 195)

TROGG_X, TROGG_TOP_ROW = 48, 75                  # standing on the F's floor
YOYO_X, YOYO_TOP_ROW, YOYO_ROWS = 72, 79, 4
BALLOON_X, BALLOON_TOP_ROW, BALLOON_ROWS = 118, 120, 4
BALLOON_LINE = os.environ.get('BALLOON_LINE', 'odd')      # which line of a row reads its enable

RAM = {'Rows': 0x80, 'Scroll': 0x81, 'Dir': 0x82, 'EntryX': 0x83, 'EntryPtr': 0x84,
       'YoPtr': 0x86, 'BalPtr': 0x88, 'TrogPtr': 0x8A, 'Tick': 0x8C}


# ---- the level model --------------------------------------------------------------------------
_LEVEL = []


def level_lines():
    """384 lines: [{'pf': set, 'pcol': value, 'objs': [(x, gfx value, colour value)]}].
    Cached: ak_screen sets fr's layout when first imported, and an import only runs once."""
    if not _LEVEL:
        _LEVEL.append(_level_lines())
    return _LEVEL[0]


def _level_lines():
    gem8 = fr.GEM + ['........']
    key6 = fr.KEY + ['........']
    saved = (fr.PLATFORMS, fr.STEPS, fr.LADDERS, fr.ITEMS, fr.GEM, fr.KEY)
    out = []
    screens = [
        (saved[0], saved[1], saved[2],
         [('gem', 64, 16), ('gem', 55, 80), ('gem', 133, 80), ('key', 118, 170)]),
    ]
    import ak_screen  # noqa: F401  (sets fr's layout to the A/K screen)
    screens.append((fr.PLATFORMS, fr.STEPS, fr.LADDERS,
                    [('gem', 40, 16), ('gem', 112, 80), ('gem', 148, 168)]))
    for plats, steps, ladders, items in screens:
        fr.PLATFORMS, fr.STEPS, fr.LADDERS, fr.ITEMS = plats, steps, ladders, items
        fr.GEM, fr.KEY = gem8, key6
        lines, t = fr.model()
        for y, ln in enumerate(lines):
            objs = []
            for x, g, c in ln['objs']:
                gv = g[1] if g[0] == 'imm' else t[g[1]][y]
                cv = c[1] if c[0] == 'imm' else t[c[1]][y]
                objs.append((x, gv, cv))
            out.append({'pf': ln['pf'], 'pcol': t['PCol'][y], 'objs': objs})
    fr.PLATFORMS, fr.STEPS, fr.LADDERS, fr.ITEMS, fr.GEM, fr.KEY = saved
    return out


def line_struct(ln):
    return (tuple(map(tuple, pf_regs(ln['pf']))), tuple(x for x, _, _ in ln['objs']))


def blocks_of(lines):
    """Blocks of rows: [(first row, rows)] with the same even/odd line structure."""
    out = []
    for r in range(len(lines) // 2):
        key = (line_struct(lines[2 * r]), line_struct(lines[2 * r + 1]))
        if out and out[-1][2] == key and out[-1][1] < 64:
            out[-1][1] += 1
        else:
            out.append([r, 1, key])
    return out


# ---- the scheduler (fr_screen's, for this kernel) ---------------------------------------------
def load(src):
    kind, v = src
    if kind == 'imm':
        return ('lda #$%02X' % v, 2)
    return ('lda %s,x' % v, 4)                      # a block table indexed by X


def schedule(pf, prevs_pf, objs, start_cols, prev_had_objs, prev_xs, end_limit, extra,
             trogg, pcol):
    """Like fr_screen.schedule, but: values come from immediates or X-indexed block tables;
    only A is used (X is the block counter); `prevs_pf`, `start_cols` and `prev_xs` list what the
    line before may have left (several, because a block can be reached from more than one place);
    `extra` tasks may have no register (an instruction that just takes cycles)."""
    L, R = pf
    tasks = []
    if trogg:
        # after Trogg (16 px from TROGG_X) has been drawn on this line: his graphics change from
        # the odd line on, i.e. he is drawn one line lower (each of his rows is two lines anyway)
        tasks.append((-(-(68 + TROGG_X + 16) // 3), end_limit, trogg, 'GRP0'))
    names = ('PF0', 'PF1', 'PF2')
    left_hi, right_win = (22, 27, 38), ((29, 49), (39, 54), (50, 65))
    any_pf = any(L) or any(R) or any(any(p[0]) or any(p[1]) for p in prevs_pf)
    if any(L) or any(R):
        tasks.append((0, 22, load(pcol), 'COLUPF'))
    if any_pf:
        for i in range(3):
            if L[i] != R[i] or any(pR[i] != L[i] for pL, pR in prevs_pf):
                tasks.append((0, left_hi[i], ('lda #$%02X' % L[i], 2), names[i]))
            if R[i] != L[i]:
                lo, hi = right_win[i]
                tasks.append((lo, hi, ('lda #$%02X' % R[i], 2), names[i]))
    if len(objs) == 1 and -(-(68 + objs[0][0] + 8) // 3) > end_limit - 3:
        objs = [(19, ('imm', 0), ('none', 0))] + list(objs)
    after_main = 0
    if objs:
        c0 = 3 if objs[0][2][0] == 'none' else (objs[0][0] + 47) // 3
        for px in prev_xs:
            if px is None:
                continue
            main = px - 16
            if 3 * c0 - 68 > main - 21 and main >= 0:
                tasks.append((0, (68 + main) // 3, ('lda #0', 2), 'GRP1'))
                after_main = max(after_main, -(-(68 + main + 8) // 3))
    strobes = []
    prev_end, prev_col = 0, None
    for k, (x, gfx, col) in enumerate(objs):
        assert x >= 19 and (x + 47) % 3 == 0, x
        c = 3 if col[0] == 'none' else (x + 47) // 3
        start = (68 + x) / 3
        hi = int(start) - (1 if int(start) == start else 0)
        strobes.append(c)
        lo = prev_end
        if after_main and start > after_main - 1:
            lo = max(lo, after_main)
        tasks.append((lo, hi, load(gfx), 'GRP1'))
        if col[0] == 'none':
            need = False
        elif k == 0 or prev_col is None:
            need = col[0] != 'imm' or any(sc != col for sc in start_cols)
        else:
            need = col[0] != 'imm' or col != prev_col
        if need:
            tasks.append((prev_end, hi, load(col), 'COLUP1'))
        prev_end = -(-(68 + x + 8) // 3)
        prev_col = col if col[0] != 'none' else prev_col
    spare = []
    if len(objs) == 1:
        tasks.append((prev_end, end_limit, ('lda #0', 2), 'GRP1'))
        spare.append(prev_end + 3)
    if not objs and prev_had_objs:
        tasks.append((0, end_limit, ('lda #0', 2), 'GRP1'))
    tasks += list(extra)
    T = [(lo, hi, ins, ln, reg) for lo, hi, (ins, ln), reg in tasks]
    fail = set()

    def search(t, rem, si, ha):
        key = (t, rem, si, ha)
        if key in fail:
            return None
        if not rem and si == len(strobes):
            return [], t
        nxt = strobes[si] if si < len(strobes) else None
        limit = nxt - 3 if nxt is not None else end_limit
        for i in rem:
            lo, hi, ins, ln, reg = T[i]
            need = (3 if ins == ha else ln + 3) if reg else ln
            if max(t + need, lo) > hi:
                fail.add(key)
                return None

        def ok(e):
            return e <= limit and (nxt is None or limit - e != 1)
        opts, loads = [], set()
        for i in rem:
            lo, hi, ins, ln, reg = T[i]
            if reg is None:                          # an instruction that just takes cycles
                if t + ln >= lo and t + ln <= hi and ok(t + ln):
                    opts.append((hi, 0, t + ln, 0, i, 'op'))
                continue
            if ha == ins:
                for st in (3, 4):
                    land = max(t + st, lo)
                    if land - st - t == 1 or land > hi or not ok(land):
                        continue
                    opts.append((hi, 0, land, st, i, 'store'))
            elif ins not in loads and ok(t + ln):
                loads.add(ins)
                opts.append((hi, 1, t + ln, 0, i, 'load'))
        for hi, _, e, st, i, what in sorted(opts):
            lo, _, ins, ln, reg = T[i]
            if what == 'op':
                res = search(e, rem - {i}, si, ha)
                if res is not None:
                    return [ins] + res[0], res[1]
            elif what == 'store':
                res = search(e, rem - {i}, si, ha)
                if res is not None:
                    gap = e - st - t
                    return ([pad(gap)] if gap else []) + ['sta%s %s' % ('.w' if st == 4 else '', reg)] + res[0], res[1]
            else:
                res = search(e, rem, si, ins)
                if res is not None:
                    return [ins] + res[0], res[1]
        if nxt is not None and nxt - 3 - t >= 0:
            gap = nxt - 3 - t
            st = 'sta RESP1'
            if gap == 1:
                gap, st = 0, 'sta.w RESP1'
            res = search(nxt, rem, si + 1, ha)
            if res is not None:
                return ([pad(gap)] if gap else []) + [st] + res[0], res[1]
        fail.add(key)
        return None

    res = search(0, frozenset(range(len(T))), 0, None)
    if res is None:
        raise ValueError('no schedule fits: %s' % ([(lo, hi, ins, reg) for lo, hi, ins, ln, reg in T],))
    out, t = res
    for at in spare:
        g = max(0, at - 3 - t)
        if g == 1:
            g = 2
        if g:
            out.append(pad(g))
        out.append('sta RESP1')
        t += g + 3
    if t > end_limit:
        raise ValueError('line ends at cycle %d (> %d)' % (t, end_limit))
    return out, t


CYC = {'nop': 2, 'iny': 2, 'dex': 2, 'bit': 3}


def cycles(ins):
    op = ins.split()[0]
    if op in CYC:
        return CYC[op]
    arg = ins.split()[1] if len(ins.split()) > 1 else ''
    if op == 'dec':
        return 5
    if op.endswith('.w'):
        return 4
    if arg.startswith('#'):
        return 2
    if arg.startswith('('):
        return 5
    if ',x' in arg or ',y' in arg:
        return 4
    return 3


def nbytes(ins):
    op = ins.split()[0]
    if op in ('nop', 'iny', 'dex'):
        return 1
    arg = ins.split()[1] if len(ins.split()) > 1 else ''
    if op.endswith('.w') or op == 'jmp' or ((',x' in arg or ',y' in arg) and not arg.startswith('(')):
        return 3
    return 2


def flat(code):
    return [i.strip() for chunk in code for i in chunk.split('\n') if i.strip()]


# ---- building the ROM -------------------------------------------------------------------------
def strip_page(rows_data, top):
    """One page: Y counts screen rows down (96..1), so row j of the screen reads offset
    L + 96 - j, where L = K + top - 96 - scroll is the pointer's low byte. The strip is stored
    upside down ending at offset K, which is chosen so L stays 0-159 (no page crossing, and the
    96-byte window stays in the page) for every scroll 0-96. Returns (page, K)."""
    H = len(rows_data)
    for K in range(H - 1, 256):
        if K + top - 96 - 96 >= 0 and K + top - 96 <= 159:
            p = [0] * 256
            for i, v in enumerate(rows_data):
                p[K - i] = v
            return p, K
    raise ValueError('no layout for a strip at row %d' % top)


def pointer(name, top_row):
    """(page label + offset expression, low byte) so that row `top_row` reads the strip's first byte."""
    for k, off in enumerate(STRIP_OFFSETS):
        if 0 <= off - top_row <= 64:
            return '%s%d+%d' % (name, k, off - top_row)
    raise ValueError(top_row)


def build(base, scroll, auto):
    lines = level_lines()
    blks = blocks_of(lines)
    nb = len(blks)

    # per block: values for each row, structure, schedule both line types
    def line_values(r, parity):
        return lines[2 * r + parity]

    sched = []                       # per block: dict(even=code, odd=code, tables={name: [values]})
    failures = []
    prev_odd = None                  # previous block's odd-line context
    for k, (r0, n, key) in enumerate(blks):
        tables = {}

        def src(name, vals):
            if all(v == vals[0] for v in vals):
                return ('imm', vals[0])
            # X counts down: X = n-1-i for row i of the block
            tables[name] = [vals[n - 1 - x] for x in range(n)]
            return ('tblx', name)

        out = {}
        for parity in (0, 1):
            lns = [line_values(r0 + i, parity) for i in range(n)]
            pf = pf_regs(lns[0]['pf'])
            pf = (tuple(pf[0]), tuple(pf[1]))
            objs = []
            for j, (x, _, _) in enumerate(lns[0]['objs']):
                g = src('B%d%s_g%d' % (k, 'eo'[parity], j), [ln['objs'][j][1] for ln in lns])
                c = src('B%d%s_c%d' % (k, 'eo'[parity], j), [ln['objs'][j][2] for ln in lns])
                objs.append((x, g, c))
            pcol = src('B%d%s_pc' % (k, 'eo'[parity]), [ln['pcol'] for ln in lns]) if any(pf[0]) or any(pf[1]) else None
            out[parity] = (pf, objs, pcol)

        e_pf, e_objs, e_pcol = out[0]
        o_pf, o_objs, o_pcol = out[1]
        # contexts: the even line follows this block's odd line, the previous block's odd line,
        # or the frame setup (scroll entry: playfield and GRP1 clear, COLUP1 unknown)
        zero = ((0, 0, 0), (0, 0, 0))
        o_last_col = o_objs[-1][2] if o_objs else None
        e_prevs = [o_pf, zero] + ([prev_odd['pf']] if prev_odd else [])
        # (on a scroll entry the frame code sets COLUP1 to this line's first colour: EntCol)
        e_cols = [o_last_col] + ([prev_odd['col']] if prev_odd else [])
        if not e_objs or e_objs[0][2][0] != 'imm':
            e_cols.append(None)
        e_xs = [o_objs[-1][0] if o_objs else None] + ([prev_odd['x']] if prev_odd else [])
        e_had = bool(o_objs) or bool(prev_odd and prev_odd['had'])
        even_extra = [(0, 72, ('lda (YoPtr),y', 5), 'ENAM0')]
        if BALLOON_LINE == 'even':
            even_extra.append((0, 72, ('lda (BalPtr),y', 5), 'ENABL'))
        trogg = ('lda (TrogPtr),y', 5)
        res = {}
        try:
            res[0] = schedule(e_pf, e_prevs, e_objs, e_cols, e_had, e_xs, 72, even_extra, trogg, e_pcol)
        except ValueError as e:
            failures.append((r0, n, 'even', str(e)[:150]))
            res[0] = None
        e_last_col = e_objs[-1][2] if e_objs else None
        switch_after = None                          # filled in after bank packing (worst case here)
        for exit_cost in (7, 10, 17):                # fall through / jmp / bank switch after
            odd_limit = 75 - 6 - exit_cost           # dey, beq, dex; then bpl or the exit
            try:
                res[(1, exit_cost)] = schedule(o_pf, [e_pf], o_objs, [e_last_col], bool(e_objs),
                                               [e_objs[-1][0] if e_objs else None], odd_limit,
                                               [(0, odd_limit, ('lda (BalPtr),y', 5), 'ENABL')]
                                               if BALLOON_LINE == 'odd' else [], None, o_pcol)
            except ValueError as e:
                res[(1, exit_cost)] = None
        sched.append(dict(r0=r0, n=n, even=res[0], odd7=res[(1, 7)], odd10=res[(1, 10)],
                          odd17=res[(1, 17)], tables=tables, e_objs=e_objs))
        prev_odd = dict(pf=o_pf, col=o_last_col, x=o_objs[-1][0] if o_objs else None, had=bool(o_objs))

    # ---- pack blocks into banks ----
    def block_bytes(b, odd):
        code = flat(b['even'][0] if b['even'] else []) + flat(odd[0] if odd else [])
        return sum(nbytes(i) for i in code) + 30, sum(len(v) for v in b['tables'].values())
    CAP = 0x600 - 8                                  # $F100-$F6FF
    bank_of, used = [], [0x320]                      # bank 0 also holds the frame code and entry tables
    bank = 0
    for k, b in enumerate(sched):
        cb, tb = block_bytes(b, b['odd17'] or b['odd10'] or b['odd7'])
        need = cb + tb + 16
        if used[bank] + need > CAP:
            bank += 1
            used.append(0)
        bank_of.append(bank)
        used[bank] += need
    nbanks = bank + 1
    scheme = 'F6' if nbanks <= 4 else 'F4'
    hot = 0xFFF6 if scheme == 'F6' else 0xFFF4
    total_banks = 4 if scheme == 'F6' else 8
    assert nbanks <= total_banks, nbanks

    # choose each block's exit and odd-line version. Blocks that fall through to the next form a
    # chain sharing one exit stub (JMP <overscan>) just before the chain's first block; a block can
    # join a chain only while every BEQ in it can still reach that stub (backwards, < 128 bytes).
    # Otherwise the block exits with a JMP (its own exit stub after it, which also serves as the
    # next chain's stub) or a bank switch.
    def est(b, odd):
        return sum(nbytes(i) for i in flat((b['even'] or [[]])[0]) + flat((odd or [[]])[0])) + 12
    chain_bytes = 0
    for k, b in enumerate(sched):
        if k == 0 or sched[k - 1]['exit'] != 'fall' or bank_of[k] != bank_of[k - 1]:
            b['ex_label'] = 'B%dEx' % k                 # a new chain: its stub goes before it
            b['stub_before'] = True
            chain_bytes = 3
        else:
            b['ex_label'] = sched[k - 1]['ex_label']
            b['stub_before'] = False
        switching = k + 1 < nb and bank_of[k + 1] != bank_of[k]
        if switching:
            b['exit'], b['odd'] = 'switch', b['odd17']
        else:
            mine = est(b, b['odd7'])
            nxt_size = max(est(sched[k + 1], v) for v in (sched[k + 1]['odd7'], sched[k + 1]['odd10'],
                                                          sched[k + 1]['odd17'])) if k + 1 < nb else 999
            if k + 1 < nb and b['odd7'] is not None and chain_bytes + mine + nxt_size < 118:
                b['exit'], b['odd'] = 'fall', b['odd7']
            else:
                b['exit'], b['odd'] = 'jmp', b['odd10']
        chain_bytes += est(b, b['odd'])
        if b['odd'] is None:
            failures.append((b['r0'], b['n'], 'odd (%s after)' % b['exit'], 'no schedule fits'))

    # ---- stubs ----
    stubs = []                                       # (address, source bank, dest bank, target)
    addr = 0xF010
    def stub(src_b, dst_b, target):
        nonlocal addr
        stubs.append((addr, src_b, dst_b, target))
        a = addr
        addr += 6
        assert addr <= 0xF100
        return a
    next_jump = {}
    for k in range(nb - 1):
        if bank_of[k + 1] != bank_of[k]:
            next_jump[k] = '$%04X' % stub(bank_of[k], bank_of[k + 1], 'B%d' % (k + 1))
        else:
            next_jump[k] = 'B%d' % (k + 1)
    exit_jump = {}
    for b in range(nbanks):
        exit_jump[b] = 'Overscan' if b == 0 else '$%04X' % stub(b, 0, 'Overscan')

    # ---- assembly ----
    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['GRP0     = $1B', 'COLUPF   = $08', 'PF0      = $0D', 'PF1      = $0E', 'PF2      = $0F',
          'RESM0    = $12', 'ENAM0    = $1D', 'HotBase  = $%04X' % hot]
    o += ['%-8s = $%02X' % (k, v) for k, v in RAM.items()]
    trogg_rows = [bits(r) for r in TROGG]
    pages = {'Trog': strip_page(trogg_rows, TROGG_TOP_ROW),
             'YoEn': strip_page([2] * YOYO_ROWS, YOYO_TOP_ROW - 1),
             'BaEn': strip_page([2] * BALLOON_ROWS, BALLOON_TOP_ROW - 1)}

    # entry table (bank 0): for each scroll row, the block, its X and bank
    ent = []
    for s in range(len(lines) // 2 - ROWS_ON_SCREEN + 1):
        k = max(i for i, b in enumerate(sched) if b['r0'] <= s)
        b = sched[k]
        e0 = lines[2 * s]['objs']
        ent.append((k, b['n'] - 1 - (s - b['r0']), bank_of[k], e0[0][2] if e0 else 0))

    def frame_code():
        out = ['''Init:   sei
        cld
        ldx #$FF
        txs
        lda #0
Clear:  sta $00,x
        dex
        bne Clear
        lda #%d
        sta Scroll
        lda #1
        sta Dir
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
        lda #$20
        sta CTRLPF        ; ball 4 px, repeat mode, players in front of the playfield
        lda #0
        sta PF0
        sta PF1
        sta PF2
        sta GRP0
        sta GRP1
        sta ENAM0
        sta ENABL
        lda #$35
        sta NUSIZ0        ; Trogg double width, missile 0 (the yoyo) 8 px
        lda #$01
        sta NUSIZ1        ; two copies close: each RESP1 strobe gives one copy''' % (scroll, fr.BG, fr.MAGENTA)]
        for nm, ptr, top in (('Trog', 'TrogPtr', TROGG_TOP_ROW), ('YoEn', 'YoPtr', YOYO_TOP_ROW - 1),
                             ('BaEn', 'BalPtr', BALLOON_TOP_ROW - 1)):
            K = pages[nm][1]
            out.append('        lda #%d\n        sec\n        sbc Scroll        ; low byte = K + top - 96 - scroll\n'
                       '        sta %s\n        lda #>%sPage\n        sta %s+1' % (K + top - 96, ptr, nm, ptr))
        for reg, xx, k in (('RESP0', TROGG_X, 63), ('RESM0', YOYO_X, 68), ('RESBL', BALLOON_X, 68)):
            out.append('        sta WSYNC\n        ' + pad((xx + k) // 3 - 3).replace('\n', '\n        ')
                       + '\n        sta %s' % reg)
        out.append('''        ldx #28
VB:     sta WSYNC
        dex
        bne VB
        ldy Scroll
        lda EntLo,y
        sta EntryPtr
        lda EntHi,y
        sta EntryPtr+1
        lda EntX,y
        sta EntryX
        lda EntCol,y
        sta COLUP1
        lda EntBank,y
        tax
        ldy #%d           ; Y: screen rows left, counting down
        sta WSYNC
        lda #0
        sta VBLANK
        jmp Entry
Overscan:
        sta WSYNC
        lda #0
        sta GRP0
        sta GRP1
        sta PF0
        sta PF1
        sta PF2
        sta ENAM0
        sta ENABL
        lda #2
        sta VBLANK''' % ROWS_ON_SCREEN)
        if auto:
            out.append('''        inc Tick
        lda Tick
        and #3
        bne NoMove
        lda Scroll
        clc
        adc Dir
        sta Scroll
        beq Flip
        cmp #%d
        bne NoMove
Flip:   lda #0
        sec
        sbc Dir
        sta Dir
NoMove:''' % (len(lines) // 2 - ROWS_ON_SCREEN))
        out.append('''        ldx #28
OS:     sta WSYNC
        dex
        bne OS
        jmp Frame''')
        for nm, idx in (('EntLo', 0), ('EntHi', 1), ('EntX', 2), ('EntBank', 3), ('EntCol', 4)):
            vals = []
            for k, x, bk, col in ent:
                vals.append({0: '<B%dRow' % k, 1: '>B%dRow' % k, 2: '%d' % x, 3: '%d' % bk,
                             4: '$%02X' % col}[idx])
            out.append('%s:' % nm)
            for j in range(0, len(vals), 12):
                out.append('        .byte ' + ','.join(vals[j:j + 12]))
        return out

    def block_code(k):
        b = sched[k]
        out = []
        if b['stub_before'] and not (k > 0 and bank_of[k - 1] == bank_of[k] and sched[k - 1]['exit'] == 'jmp'):
            out.append('B%dEx:   jmp %s' % (k, exit_jump[bank_of[k]]))
        elif b['stub_before']:
            out.append('B%dEx = %s' % (k, sched[k - 1]['own_ex']))   # the previous block's stub, right here
        out += ['B%d:     ldx #%d' % (k, b['n'] - 1), 'B%dRow:  sta WSYNC' % k]
        if b['even'] is None:
            out += ['        lda #0', '        sta GRP1', '        sta PF0',
                    '        sta PF1', '        sta PF2']
        else:
            out += ['        ' + i for i in flat(b['even'][0])]
        out.append('        sta WSYNC')
        if b['odd'] is None:
            out += ['        lda #0', '        sta GRP1']
        else:
            out += ['        ' + i for i in flat(b['odd'][0])]
        out += ['        dey                ; screen rows left', '        beq %s' % (b['ex_label'] if b['exit'] == 'fall' or not b['stub_before'] else 'B%dEx' % k),
                '        dex',
                '        bpl B%dRow' % k]
        if b['exit'] != 'fall':
            out.append('        jmp %s' % (next_jump.get(k, exit_jump[bank_of[k]])))
            # this block's own exit stub (and the next chain's, if it follows in this bank)
            lbl = 'B%dEx' % k if not b['stub_before'] else 'B%dExA' % k
            out.append('%s:  jmp %s' % (lbl, exit_jump[bank_of[k]]))
            b['own_ex'] = lbl
        return out

    def table_area(bk):
        """Block tables for bank bk, packed so none crosses a page; returns lines and size."""
        out, off = [], 0
        for k, b in enumerate(sched):
            if bank_of[k] != bk:
                continue
            for name, vals in b['tables'].items():
                if (0xF100 + off) // 256 != (0xF100 + off + len(vals) - 1) // 256:
                    skip = 256 - (0xF100 + off) % 256
                    out.append('        ds %d, 0' % skip)
                    off += skip
                out.append('%s:' % name)
                out.append('        .byte ' + ','.join('$%02X' % v for v in vals))
                off += len(vals)
        return out

    for bk in range(total_banks):
        org = bk * 0x1000
        o += ['        seg bank%d' % bk, '        org $%04X' % org, '        rorg $F000']
        o.append('        lda HotBase        ; $F000: reset: to bank 0, continuing at $F003')
        o.append('        jmp Init' if bk == 0 else '        nop\n        nop\n        nop')
        o.append('        org $%04X\n        rorg $F008' % (org + 8))
        o.append('Entry%s: lda HotBase,x      ; $F008: the same in every bank' % ('' if bk == 0 else '_%d' % bk))
        o.append('        ldx EntryX\n        jmp (EntryPtr)')
        for a, sb, db, target in stubs:
            if sb == bk:
                o.append('        org $%04X\n        rorg $%04X\n        lda HotBase+%d' % (org + a - 0xF000, a, db))
            if db == bk:
                o.append('        org $%04X\n        rorg $%04X\n        jmp %s' % (org + a + 3 - 0xF000, a + 3, target))
        o.append('        org $%04X\n        rorg $F100' % (org + 0x100))
        o += table_area(bk)
        if bk == 0:
            o += frame_code()
        for k in range(nb):
            if bank_of[k] == bk:
                o += block_code(k)
        o.append('        org $%04X\n        rorg $F700' % (org + 0x700))
        for nm in ('Trog', 'YoEn', 'BaEn'):
            o.append('%sPage%s:' % (nm, '' if bk == 0 else '_%d' % bk))
            pg = pages[nm][0]
            for q in range(0, 256, 32):
                o.append('        .byte ' + ','.join('$%02X' % v for v in pg[q:q + 32]))
        o.append('        org $%04X\n        rorg $FF00' % (org + 0xF00))
        o.append('        org $%04X\n        rorg $FFFC\n        .word $F000\n        .word $F000' % (org + 0xFFC))
    asm = '\n'.join(o) + '\n'
    open(base + '.asm', 'w').write(asm)
    r = subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if r.returncode:
        print(r.stdout[-2000:])
        sys.exit('dasm failed')
    # independent cycle check of every scheduled line
    worst = {}
    for k, b in enumerate(sched):
        for nm in ('even', 'odd'):
            if b[nm]:
                n = sum(cycles(i) for i in flat(b[nm][0]))
                assert n == b[nm][1], (k, nm, n, b[nm][1])
                worst[nm] = max(worst.get(nm, 0), n)
    return lines, sched, failures, nbanks, scheme, worst


def compare(png, lines, scroll):
    im = Image.open(png).convert('RGB')
    sx = im.width / 160
    bg = im.getpixel((im.width - 2, im.height // 2))
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg) + 1
    bad, first_bad = 0, []
    for j in range(2 * ROWS_ON_SCREEN):
        y = 2 * scroll + j
        ln = lines[y]
        want = set()
        for b in range(40):
            if all(x in ln['pf'] for x in range(4 * b, 4 * b + 4)):
                want |= set(range(4 * b, 4 * b + 4))
        for x, gv, cv in ln['objs']:
            want |= {x + i for i in range(8) if gv & (0x80 >> i)}
        got = {x for x in range(160) if im.getpixel((int((x + 0.5) * sx), first + j)) != bg}
        skip = set()
        row = y // 2
        if TROGG_TOP_ROW - 1 <= row <= TROGG_TOP_ROW + len(TROGG):
            skip |= set(range(TROGG_X - 2, TROGG_X + 18))
        if YOYO_TOP_ROW - 2 <= row <= YOYO_TOP_ROW + YOYO_ROWS + 1:
            skip |= set(range(YOYO_X - 4, YOYO_X + 14))
        if BALLOON_TOP_ROW - 2 <= row <= BALLOON_TOP_ROW + BALLOON_ROWS + 1:
            skip |= set(range(BALLOON_X - 4, BALLOON_X + 10))
        if (want - skip) != (got - skip):
            bad += 1
            if len(first_bad) < 6:
                first_bad.append('  screen line %3d (level line %3d): missing %s extra %s' % (
                    j, y, sorted(want - got - skip)[:8], sorted(got - want - skip)[:8]))
    return bad, first_bad


if __name__ == '__main__':
    args = sys.argv[1:]
    auto = '--auto' in args
    scrolls = []
    while '--scroll' in args:
        i = args.index('--scroll')
        scrolls.append(int(args[i + 1]))
        del args[i:i + 2]
    args = [a for a in args if a != '--auto']
    outdir = os.path.abspath(args[0] if args else os.path.join(HERE, 'out'))
    os.makedirs(outdir, exist_ok=True)
    if not scrolls:
        scrolls = [0, 1, 24, 48, 73, 96]
    for s in scrolls:
        base = os.path.join(outdir, 'tower_%d' % s)
        lines, sched, failures, nbanks, scheme, worst = build(base, s, False)
        png = tiatest.snapshot(base + '.bin', outdir)
        if not png:
            sys.exit('no snapshot')
        os.replace(png, base + '.png')
        im = Image.open(base + '.png')
        im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
        bad, detail = compare(base + '.png', lines, s)
        print('scroll %3d: %d blocks in %d banks (%s), busiest even line %d, odd %d; '
              '%d of 192 lines differ' % (s, len(sched), nbanks, scheme, worst.get('even', 0),
                                          worst.get('odd', 0), bad))
        for d in detail:
            print(d)
    if failures:
        print('%d block line versions could not be scheduled:' % len(failures))
        for r0, n, what, e in failures:
            print('  rows %d-%d %s: %s' % (r0, r0 + n - 1, what, e))
    if auto:
        base = os.path.join(outdir, 'tower_auto')
        build(base, 0, True)
        print('auto-scrolling ROM:', base + '.bin')
