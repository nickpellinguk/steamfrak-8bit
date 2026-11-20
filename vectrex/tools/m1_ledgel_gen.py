#!/usr/bin/env python3
"""
Ledges as a textured top line and steep parallel lines under it. Writes test/m1ll_engine.asm and
test/m1ll_data.asm for test/m1ll_test.asm: a 128-pixel run of ledges as milestone 1's 8-row strip,
and as the top line (one raster row: the ledge's row 0) with the undersides (rows 4-13: the band
and the stalactites, their shape from the ledge's pixels) hatched with lines LINES_PER_TILE to a
16-pixel tile.

    python3 vectrex/tools/m1_ledgel_gen.py [../steamfrak]

The lines: Y at 80 (half a pixel a cycle), X at -8 going down and +8 going up (leaning a tenth of a
pixel a pixel: 84 degrees), down one line and up the next, solid: the spot on along each line (the
shift register written $FF) and off at its ends ($00). Those writes go 12 cycles after the beam
position they're for (milestone 1's calibration: a byte written at 12 belongs to the beam at 0).

* The bottom turn: STY $0050 (ramp on, mux on, DAC +80: Y's sample-and-hold takes "up", and the
  DAC drives X at +80 meanwhile: the beam goes up and to the right), k cycles, then STU $0108 (mux
  off, X +8). k = 2.22 x the spacing puts the beam on the next line (at least 6: STY's time).
* The top turn: STX $0150 (X +80: a jog up and to the right), j cycles, STY $80B0 (ramp off, mux
  on, DAC -80: "down"), m cycles for the sample-and-hold, STU $01F8 (ramp on, mux off, X -8); the
  spot back on once the beam is down at the underside's top again. j = 2.22 x the spacing too.
* The registers: A = $FF, B = 0 (the spot); X, Y, U reloaded during the lines, which are only
  waits otherwise. The tile's code is the same for every tile (an even number of lines: each tile
  ends with a top turn into the next tile's first line).
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEST = os.path.join(HERE, '..', 'test')
sys.path.insert(0, HERE)
import m1_gen as g  # noqa: E402
import m1_cave_gen as cave  # noqa: E402
import vconvert  # noqa: E402

LENGTH = 128
VARIANTS = [5, 4]               # lines to a tile
LEAN = 0.1                      # pixels across a pixel down (X 8 against Y 80)
TOP, BOTTOM = 4, 14
SPOT_ON, SPOT_OFF = 12, 12      # (not used: spot_writes() places the writes)
                                # (12 by milestone 1's calibration: the spot on a little late and
                                # off a little early, so it's never on where the beam stops)
M_SETTLE = 6                    # cycles for the sample-and-hold at the top turn (the ramp off)
K_MIN = J_MIN = 6               # (STY and STS take 6 cycles; never 7: a 1-cycle gap after them)


def turn_cycles(want):
    c = max(K_MIN, int(round(want)))
    return 8 if c == 7 else c
SAVE_S = '$C8C8'
MARGIN = 2                      # pixels: each line's spot off this far before its turn, so the
                                # write has room before the turn's stores


def depths(tile, length, xs):
    """Each line's depth below the underside's top (pixels), the line through (x, TOP)."""
    out = []
    for x in xs:
        y = TOP + 0.05
        while TOP <= y + 0.25 < BOTTOM and tile[int(y + 0.25)][int(x - LEAN * (y + 0.25 - TOP)) % 16] != '.':
            y += 0.25
        out.append(max(1.0, y + 0.2 - TOP))
    return out


def plan(tile, n, length):
    """
    The run's events [(cycle, kind, value)]: 'beam' stores at exact cycles ('sty' the bottom
    turn's mux on, 'stu' its mux off, 'stx' the top turn's ramp off, 'sts' its ramp on, 'stb' the
    down line's X), 'spot' on/off wanted for the beam at that cycle; and the lines drawn (for the
    record). Positions in pixels; line i through (s (i + 0.5), TOP), leaning LEAN.
    """
    s = 16 / n
    nl = int(length / s)
    nl -= nl % 2
    xs = [s * (i + 0.5) for i in range(nl)]
    d = depths(tile, length, xs)
    ev, drawn = [], []
    t = 0
    x_top = xs[0]                                  # the beam: at line 0's top, going down
    y_start = TOP
    ev.append((0, 'spot', 1))
    for i in range(0, nl, 2):
        # down line i, from (x_s, y_start)
        k = turn_cycles((xs[i + 1] - x_top) / 0.45)
        D = max(d[i] + MARGIN, d[i + 1] + k / 2, (y_start - TOP) + 1)
        t_end = t + int(round(2 * (D - (y_start - TOP))))
        ev.append((t + int(round(2 * max(0, d[i] - (y_start - TOP)))), 'spot', 0))
        drawn.append((x_top, d[i]))
        # the bottom turn: up and to the right for k cycles
        t = t_end
        ev.append((t, 'beam', 'sty'))
        ev.append((t + k, 'beam', 'stu'))
        x_up = x_top + 0.45 * k                    # the up line's top
        y_turn = D - k / 2                         # its start, below the top
        t += k
        ev.append((t + int(round(2 * max(0, y_turn - d[i + 1]))), 'spot', 1))
        t += int(round(2 * y_turn))
        ev.append((t - int(2 * MARGIN), 'spot', 0))    # (off a little before the top turn)
        drawn.append((x_up, d[i + 1]))
        if i + 2 >= nl:
            ev.append((t, 'beam', 'end'))
            break
        # the top turn: ramp off, the sample-and-hold to "down", then down and to the right
        j = turn_cycles((xs[i + 2] - x_up) / 0.55)
        ev.append((t, 'beam', 'stx'))
        ev.append((t + 5 + M_SETTLE, 'beam', 'sts'))
        ev.append((t + 5 + M_SETTLE + j, 'beam', 'stb'))
        t += 5 + M_SETTLE + j
        x_top = x_up + 0.55 * j
        y_start = TOP + 0.5 * j
        ev.append((t, 'spot', 1))
    return ev, drawn, s


LEN = {'sty': 6, 'stu': 5, 'stx': 5, 'sts': 6, 'stb': 4, 'end': 5}
SR_LEAD = 12                    # a byte written at w: its bit i belongs to the beam at w - 12 + 2i


def spot_writes(changes, alone=()):
    """
    The spot's changes [(cycle, level)] (for the beam at that cycle) grouped into shift-register
    writes: each byte's 8 bits cover the beam from w - 12 to w + 4 (2 cycles a bit), so a write
    anywhere in a window before a change makes it to within a bit. [(lo, hi, changes)]: the
    window for the write's cycle and the changes it carries.
    """
    ch = sorted(changes)
    groups = []
    for t, lev in ch:
        if groups and t - groups[-1][0][0] <= 12 and t not in alone and groups[-1][0][0] not in alone:
            groups[-1].append((t, lev))
        else:
            groups.append([(t, lev)])
    out = []
    prev_last = -100
    for gch in groups:
        first, last = gch[0][0], gch[-1][0]
        lo = max(last - 2 + 1, prev_last + SR_LEAD + 1)  # (the byte reaches the last change; it
        hi = first + SR_LEAD + (4 if len(gch) == 1 else 0)  # doesn't cut the last byte's changes;
                                                        # alone, up to 4 cycles late)
        out.append([lo, hi, gch])
        prev_last = last
    return out


def mask_for(w, level_at):
    """The byte written at w: bit i (from the top) is the spot for the beam at w - 12 + 2i + 1."""
    bits = [level_at(w - SR_LEAD + 2 * i + 1) for i in range(8)]
    return int(''.join(str(b) for b in bits), 2)


def schedule(ev):
    """Instructions in time order [(t, op, cycles, value)]: the beam stores at their cycles; the
    spot writes (LDA #mask, STA shift register) each in a wait inside its window, its mask worked
    out for where it lands. A store that would leave a 1-cycle gap moves a cycle later (and the
    next line the other way grows by a cycle too, so they cancel)."""
    fixed = [[t, a, LEN[a]] for t, kind, a in sorted(ev, key=lambda e: e[0]) if kind == 'beam']
    changes = [list(c) for c in sorted((t, a) for t, kind, a in ev if kind == 'spot')]

    def level_at(c):
        lev = 0
        for t, a in changes:
            if t <= c:
                lev = a
            else:
                break
        return lev
    alone = set()
    for _ in range(400):
        writes = spot_writes([tuple(c) for c in changes], alone)
        waits, prev_end = [], 5
        for f in fixed:
            waits.append([prev_end, f[0]])
            prev_end = f[0] + f[2]
        waits.append([prev_end, prev_end + 100])
        room = [w[1] - w[0] for w in waits]
        items = [[] for _ in waits]
        # each write: LDA #m (2) then STA (4) at w, in the wait holding the most of its window
        for lo, hi, gch in writes:
            best = None
            for wi, (ws, we) in enumerate(waits):
                if room[wi] < 6:
                    continue
                a, b = max(lo, ws + 2), min(hi, we - 4)
                dist = 0 if a <= b else min(abs(lo - (we - 4)), abs(hi - (ws + 2)))
                if best is None or dist < best[0]:
                    best = (dist, wi)
            if best is None:
                raise AssertionError('no room for a spot write')
            items[best[1]].append((lo, hi))
            room[best[1]] -= 6
        out, bad = [], None
        for wi, (ws, we) in enumerate(waits):
            t = ws
            its = sorted(items[wi])
            placed = []
            for ix, (lo, hi) in enumerate(its):
                rest = 6 * (len(its) - ix)
                latest = we - rest + 2                  # (the STA's cycle, the rest still fitting)
                w = min(max(t + 2, lo), hi, latest)
                w = max(w, t + 2)
                if w - 2 - t == 1:
                    w = w + 1 if w + 1 <= latest else w - 1
                    if w - 2 < t:
                        w = t + 2
                placed.append(w)
                t = w + 4
            if wi < len(fixed) and placed and we - t == 1:
                # (shift the last write a cycle to close the gap)
                if placed[-1] + 1 + 4 <= we and placed[-1] + 1 - 2 - (placed[-2] + 4 if len(placed) > 1 else ws) != 1:
                    placed[-1] += 1
                    t += 1
            t = ws
            for (lo, hi), w in zip(its, placed):
                if not lo - 1 <= w <= hi + 1:
                    split = [g for g in writes if g[0] == lo and g[1] == hi]
                    if split and len(split[0][2]) > 1:
                        bad = ('split', split[0][2])
                if w - 2 > t:
                    out.append((t, 'delay', w - 2 - t, None))
                out.append((w - 2, 'lda', 2, mask_for(w, level_at)))
                out.append((w, 'spot', 4, None))
                t = w + 4
            if bad is not None:
                break
            if wi < len(fixed):
                left = we - t
                if left == 1 or left < 0:
                    bad = wi
                    break
                if left >= 2:
                    out.append((t, 'delay', left, None))
                f = fixed[wi]
                out.append((f[0], f[1], f[2], None))
        if bad is None:
            return out
        if isinstance(bad, tuple):
            for t, lev in bad[1]:
                alone.add(t)
            continue
        ender = fixed[bad][1]
        other = 'stx' if ender == 'sty' else 'sty' if ender == 'stx' else None
        later = next((i for i in range(bad + 1, len(fixed)) if fixed[i][1] == other), None)
        t_bad = fixed[bad][0]
        t_later = fixed[later][0] if later is not None else None
        for i in range(bad, len(fixed)):
            fixed[i][0] += 1 + (1 if later is not None and i >= later else 0)
        # the spot's changes move with the beam: a cycle from the moved store on, two from the
        # next line the other way on
        for c in changes:
            if c[0] >= t_bad:
                c[0] += 1 + (1 if t_later is not None and c[0] >= t_later else 0)
    raise AssertionError('no schedule')


def emit(name, sched):
    c = g.Code()
    regs = {'sty': 'sty', 'stu': 'stu', 'stx': 'stx', 'sts': 'sts'}
    for t, op, ln, val in sched:
        if op in regs:
            c.ins('%s     <VIA_port_b' % op, ln, 't = %d' % t)
        elif op == 'stb':
            c.ins('stb     <VIA_port_a', 4, 't = %d: X -8 (down)' % t)
        elif op == 'lda':
            c.ins('lda     #%%%s' % format(val, '08b'), 2)
        elif op == 'spot':
            c.ins('sta     <VIA_shift_reg', 4, 't = %d: the spot\'s next 8 bits' % t)
        elif op == 'end':
            c.ins('stx     <VIA_port_b', 5, 't = %d: ramp off' % t)
        else:
            for o, cy in g.delay(ln):
                c.ins(o, cy)
    c.ins('clr     <VIA_shift_reg', 6, 'spot off')
    c.ins('lds     %s' % SAVE_S, 6, 'the stack back')
    c.ins('lda     #$98', 2)
    c.ins('sta     <VIA_aux_cntl', 4, 'ACR back')
    c.ins('rts', 5)
    return c.out


def prologue(name):
    c = g.Code()
    c.comment('the lines: Y = $0050 and U = $0108 (the bottom turn), X = $80B0 and S = $0150 (the top')
    c.comment('turn), B = $F8 (X -8), A for the spot\'s bytes; the beam at the first line\'s top')
    c.label(name)
    c.ins('sts     %s' % SAVE_S, 7, '(S: a value for the top turn while the lines are drawn)')
    c.ins('lda     #$81', 2)
    c.ins('sta     <VIA_port_b', 4, 'ramp off, mux off')
    c.ins('lda     #$18', 2)
    c.ins('sta     <VIA_aux_cntl', 4, 'ACR')
    c.ins('ldy     #$80B0', 4)
    c.ins('sty     <VIA_port_b', 6, 'mux on: Y speed -80 (down)')
    c.ins('ldy     #$81F8', 4, '(the sample-and-hold settles)')
    c.ins('nop', 2)
    c.ins('nop', 2)
    c.ins('sty     <VIA_port_b', 6, 'mux off, X speed -8')
    c.ins('ldy     #$0050', 4)
    c.ins('ldu     #$0108', 3)
    c.ins('ldx     #$80B0', 3)
    c.ins('lds     #$0150', 4)
    c.ins('ldd     #$FFF8', 3)
    c.ins('stb     <VIA_port_a', 4, '(X -8)')
    c.ins('lda     #$01', 2)
    c.ins('sta     <VIA_port_b', 4, 't = 0: ramp on')
    return c.out


def main():
    steamfrak = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    tile = vconvert.grid_of(steamfrak, 'sLedge1_Beeb')
    eng = ['; made by vectrex/tools/m1_ledgel_gen.py', ''] + cave.rows_routine('cave_n', cave.ROWS) + [''] + \
        cave.rows_routine('cave_top', [0]) + ['']
    out, moves, data = ['; made by vectrex/tools/m1_ledgel_gen.py: the test scene', '', 'draw_scene'], [], []
    g._beam[0] = None
    nb = LENGTH // 8
    X = -100
    # the strip
    y = -100
    code, mv = g.start_move('s', X * g.UNIT, -(y + 0.5) * g.UNIT)
    out += ['; ledges: the 8-row strip'] + code + \
        ['dc_0_start', '                ldu     #rows_s', '                lda     #%d' % nb,
         '                sta     %s' % g.COUNT, '                jsr     cave_n', 'dc_0_end']
    moves += mv
    data.append('rows_s')
    data.append('                fdb     ' + ','.join('row_s_%d' % k for k in range(len(cave.ROWS))))
    for k, r in enumerate(cave.ROWS):
        data.append('row_s_%d' % k)
        data += cave.g_bytes(cave.row_bytes(tile, r, LENGTH, k % 2 == 1, '#'))
    last = len(cave.ROWS) - 1
    g._beam[0] = ((X + (8 * nb if last % 2 == 0 else 0)) * g.UNIT, -(y + cave.ROWS[-1] + 0.5) * g.UNIT)
    info = []
    for vi, n in enumerate(VARIANTS):
        i = vi + 1
        y = -70 + 30 * vi
        ev, drawn, sp = plan(tile, n, LENGTH)
        sched = schedule(ev)
        name = 'hatch_%d' % n
        eng += prologue(name) + emit(name + '_body', sched) + ['']
        ramp = sched[-1][0] + sched[-1][2]
        moved = sum(1 for (t, op, ln, v) in sched if op in LEN) - sum(1 for e in ev if e[1] == 'beam')
        info.append('%d lines a tile (%.1f pixels apart): %d lines, ramp on %d cycles'
                    % (n, sp, len(drawn), ramp))
        # the top line, then the hatch from the first line's top
        code, mv = g.start_move('t%d' % i, X * g.UNIT, -(y + 0.5) * g.UNIT)
        out += ['; ledges: the top line, then the lines, %d a tile' % n] + code + \
            ['dc_%d_start' % i, '                ldu     #rows_t', '                lda     #%d' % nb,
             '                sta     %s' % g.COUNT, '                jsr     cave_top']
        moves += mv
        g._beam[0] = ((X + 8 * nb) * g.UNIT, -(y + 0.5) * g.UNIT)
        code, mv = g.start_move('h%d' % i, (X + 16 / n / 2) * g.UNIT, -(y + TOP) * g.UNIT)
        # (the start: the beam at the first line's top)
        out += code + ['                jsr     %s' % name, 'dc_%d_end' % i]
        moves += mv
        g._beam[0] = None
    data.append('rows_t')
    data.append('                fdb     row_t_0')
    data.append('row_t_0')
    data += cave.g_bytes(cave.row_bytes(tile, 0, LENGTH, False, '#'))
    out.append('                rts')
    open(os.path.join(TEST, 'm1ll_engine.asm'), 'w').write('\n'.join(eng) + '\n')
    open(os.path.join(TEST, 'm1ll_data.asm'), 'w').write('\n'.join(out + [''] + moves + [''] + data) + '\n')
    print('\n'.join(info))


if __name__ == '__main__':
    main()
