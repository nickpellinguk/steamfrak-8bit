#!/usr/bin/env python3
"""
Zigzag sprites: the beam drifting down slowly and steadily (Y's sample-and-hold set once) while X
flips back and forth every row (one store each: X is fed straight from the DAC), the shift
register written every 16 cycles all the way through. No turns: the whole sprite is one sweep.
Writes test/m1z_engine.asm (straight-line code for each sprite's size) and test/m1z_data.asm for
test/m1z_test.asm, which draws each sprite as full columns and as a zigzag.

    python3 vectrex/tools/m1_zig_gen.py [../steamfrak]

Timing (as milestone 1's drifting rows, measured in vecx): t = 0 the ramp on; byte j of the
stream written at 12 + 16j; bit b of byte j belongs to the beam's position at T = 16j + 2b, and a
speed change written at t applies from T = t. The rows' speeds are in U ($0150: ramp on, mux
off, X +80) and Y ($01B0: X -80), so a flip is STU or STY to port B; the bytes go through A and B
in turn (byte j + 2 loaded after byte j is written), so loads have slack. A flip that can't be
written on its cycle (it would overlap a write, or leave a 1-cycle gap) moves a cycle or two: the
converter follows the beam's real path, where every bit is, and takes the sprite's pixel there.

The sweep lasts the sprite's height x 160 / the drift (units a cycle down, set once in Y's
sample-and-hold), so the drift is what sets the time; each sprite gets the largest drift that keeps
its rows at most MAX_PITCH pixels apart. A row only goes as far as the lit pixels of the sprite's
rows it crosses (shorter rows, so a higher drift), and its flip comes as soon after as the writes
allow (schedule(): flip by flip, backtracking). Each lit pixel then lights the bit whose dot lands
nearest it, so none is lost where neighbouring rows fan apart (they meet at one end and are up to
2 pixels apart at the other).
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEST = os.path.join(HERE, '..', 'test')
sys.path.insert(0, HERE)
import m1_gen as g  # noqa: E402

SPEED = 80
TOL = 3                     # cycles a flip may move
SR0 = 12


LATE = 12                   # cycles a flip (or the ramp off) may come after the beam reaches the edge


def schedule(w, rows, max_bytes, drift=None, h=None, extents=None, end_right=False,
             start_left=False, x_start=None, y_start=0.0, y_target=None, end_frac=1.0):
    # (start_left: the first row goes left, from x_start (pixels; the left edge by default, the
    # right going left); y_start: where the beam starts down the sprite; y_target: the pass ends
    # once the beam is past it, going down or (drift < 0) up; default h, from the top)
    """
    The instructions in time order [(t, op, cycles, arg)], the flips' times and the ramp-off's.
    Each flip comes once the beam has reached the sprite's edge (x = w going right, 0 going left),
    as soon after as the writes allow (up to LATE cycles: the row going on past the edge, blank),
    so a row never falls short. Flip by flip: the least lateness that can be reached.
    """
    stores = [SR0 + 16 * j for j in range(max_bytes)]
    out = []
    t, j, jl, f_last = 5, 0, 2, 0                # t = 0: STU (ramp on), bytes 0 and 1 loaded before
    if x_start is None:
        x_start = w if start_left else 0
    x2 = int(round(2 * x_start))
    if y_target is None and h is not None:
        y_target = h if drift > 0 else 0

    def seg(t, j, jl, T, ln, acc, loads_ok, dead=None):
        """Instructions from t to exactly T (then ln cycles of the event), or None."""
        if dead is None:
            dead = set()
        if (t, j, jl) in dead:
            return None
        r = seg1(t, j, jl, T, ln, acc, loads_ok, dead)
        if r is None:
            dead.add((t, j, jl))
        return r

    def seg1(t, j, jl, T, ln, acc, loads_ok, dead):
        if j < max_bytes and t == stores[j]:
            if jl <= j:
                return None
            return seg(t + 4, j + 1, jl, T, ln, acc + [(t, 'sta' if j % 2 == 0 else 'stb', 4, j)], loads_ok, dead)
        if t == T:
            if j < max_bytes and T + ln > stores[j]:
                return None
            return acc, j, jl
        if t > T:
            return None
        nxt = min(stores[j] if j < max_bytes else 10 ** 9, T)
        if loads_ok and jl < max_bytes and j >= jl - 1 and t + 6 <= nxt:
            r = seg(t + 6, j, jl + 1, T, ln, acc + [(t, 'lda' if jl % 2 == 0 else 'ldb', 6, jl)], loads_ok, dead)
            if r:
                return r
        for d in (2, 3, 4, 5):
            if t + d <= nxt:
                r = seg(t + d, j, jl, T, ln, acc + [(t, 'delay', d, None)], loads_ok, dead)
                if r:
                    return r
        return None

    def edge_of(k, x2, f_last):
        going_right = (k % 2 == 0) != start_left
        edge2 = 2 * w if going_right else 0
        if extents is not None:
            # only as far as the lit pixels of the sprite's rows near this pass need
            # (the rows this pass crosses, from where it starts to where it ends: worked out
            # again with the end found, twice)
            y0 = y_start + drift * f_last / g.UNIT
            for _ in range(3):
                y1 = y0 + drift * abs(edge2 - x2) / g.UNIT
                band = [extents[r] for r in range(int(y0 - 0.5), int(y1 + 0.5) + 1)
                        if 0 <= r < len(extents) and extents[r]]
                if band:
                    edge2 = 2 * (max(e[1] for e in band) + 1) if going_right else 2 * min(e[0] for e in band)
                else:
                    edge2 = 2 * w if going_right else 0
                edge2 = max(edge2, x2) if going_right else min(edge2, x2)
        return edge2

    failed = set()

    def solve(k, t, j, jl, x2, f_last):
        """The rest from flip k on: (instructions, off time, j, jl) or None."""
        key = (k, t, j, jl, x2, f_last)
        if key in failed:
            return None
        going_right = (k % 2 == 0) != start_left
        earliest = f_last + abs(edge_of(k, x2, f_last) - x2)
        if h is not None:
            y_e = y_start + drift * earliest / g.UNIT
            last = y_e >= y_target if drift > 0 else y_e <= y_target
        else:
            last = k == rows - 1
        if end_right and not going_right:
            last = False                                # (the last row ends at the right edge)
        ln = 8 if last else (6 if k % 2 == 0 else 5)
        if last and end_frac < 1:
            # (the ramp off part way along the last row: the next pass's phase)
            earliest = f_last + int(round(end_frac * abs(edge_of(k, x2, f_last) - x2)))
        start = max(earliest - (3 if last else 0), t)   # (the ramp off: LDX, then STX at T + 3)
        for d in range(LATE + 1):
            T = start + d
            r = seg(t, j, jl, T, ln, [], True)
            if not r:
                continue
            acc, j2, jl2 = r
            if last:
                if 16 * jl2 < T + 3:
                    continue                            # (every byte before the ramp off loaded)
                if 16 * j2 < T + 3 and j2 < max_bytes and stores[j2] - (T + 8) == 1:
                    continue                            # (a 1-cycle gap can't be filled)
                return acc + [(T, 'off', 8, None)], T + 3, j2, jl2, T + 8
            nx2 = x2 + (T - f_last) * (1 if going_right else -1)
            rest = solve(k + 1, T + ln, j2, jl2, nx2, T)
            if rest:
                return (acc + [(T, 'flip', ln, k)] + rest[0],) + rest[1:]
        failed.add(key)
        return None

    import threading
    result = []
    threading.stack_size(256 * 1024 * 1024)
    sys.setrecursionlimit(100000)
    th = threading.Thread(target=lambda: result.append(solve(0, t, j, jl, x2, f_last)))
    th.start()
    th.join()
    if not result or not result[0]:
        raise AssertionError('no schedule')
    out, off_time, j, jl, t = result[0]
    # the writes still due (bytes with bits before the ramp off)
    while 16 * j < off_time:
        if t < stores[j]:
            d = stores[j] - t
            out.append((t, 'delay', d, None))
            t = stores[j]
        assert t == stores[j] and jl > j
        out.append((t, 'sta' if j % 2 == 0 else 'stb', 4, j))
        t += 4
        j += 1
    flip_times = [t for t, op, _, _ in out if op == 'flip']
    return out, flip_times, off_time, j


def path(flip_times, off_time, drift, nbits, start_left=False, x_start=0.0, y_start=0.0):
    """Each bit's beam position (x, y: pixels from the start, y down), at the middle of its 2 cycles."""
    def x_at(T):
        x, v, last = x_start, (-1 if start_left else 1) * SPEED / g.UNIT, 0
        for f in flip_times:
            if f >= T:
                break
            x += v * (f - last)
            v, last = -v, f
        return x + v * (T - last)
    return [(x_at(2 * i + 1), y_start + drift * (2 * i + 1) / g.UNIT) for i in range(nbits)], \
        (x_at(off_time), y_start + drift * off_time / g.UNIT)


MAX_PITCH = 1.05            # pixels between rows (on average)


def zigzag(grid, lit='#', force_drift=None, track=True):
    """Plan a sprite: the largest drift whose rows (late flips and all) are at most MAX_PITCH
    apart; the schedule, the data, where the beam ends."""
    h, w = len(grid), len(grid[0])
    extents = []
    for r in range(h):
        xs = [x for x in range(w) if grid[r][x] in lit]
        extents.append((min(xs), max(xs)) if xs else None)
    best = None
    for drift in ([force_drift] if force_drift else range(1, 16)):
        max_bytes = math.ceil(h * g.UNIT / drift / 16) + 2 * w + 16
        try:
            sched, flip_times, off_time, nbytes = schedule(w, 0, max_bytes, drift, h, extents if track else None)
        except (AssertionError, IndexError):
            continue
        rows = len(flip_times) + 1
        pitch = drift * off_time / g.UNIT / rows
        if pitch <= MAX_PITCH or force_drift:
            best = (drift, sched, flip_times, off_time, nbytes, rows, pitch)
    drift, sched, flip_times, off_time, nbytes, rows, pitch = best
    pos, end = path(flip_times, off_time, drift, 8 * nbytes)
    # each lit pixel lights the bit whose dot is nearest its middle (so none is lost where the rows
    # fan apart), the dots up to the ramp off
    n_on = off_time // 2
    bits = [0] * len(pos)
    for r in range(h):
        for c in range(w):
            if grid[r][c] in lit:
                i = min(range(n_on), key=lambda i: (pos[i][0] - c - 0.5) ** 2 + (pos[i][1] - r - 0.5) ** 2)
                bits[i] = 1
    data = [int(''.join(map(str, bits[i:i + 8])), 2) for i in range(0, len(bits), 8)]
    return {'drift': drift, 'pitch': pitch, 'rows': rows, 'nbytes': nbytes, 'sched': sched, 'data': data,
            'end': end, 'off': off_time, 'w': w, 'h': h, 'ideal': 2 * w * rows}


def emit(name, z):
    """The routine, with the ramp off as LDD/STD (the schedule leaves 5 cycles for STD; the LDD
    goes in the gap before it)."""
    c = g.Code()
    c.comment('a zigzag sprite, %d x %d: %d rows (pitch %.2f pixels), drift %d, %d bytes: ramp on %d cycles'
              % (z['w'], z['h'], z['rows'], z['pitch'], z['drift'], z['nbytes'], z['off']))
    c.comment('in: X = the data, the beam at the sprite\'s top left')
    c.label(name)
    c.ins('lda     #$81', 2)
    c.ins('sta     <VIA_port_b', 4, 'ramp off, mux off, before port B takes over the ramp')
    c.ins('lda     #$18', 2)
    c.ins('sta     <VIA_aux_cntl', 4, 'ACR')
    c.ins('ldy     #$80%02X' % (-z['drift'] & 0xFF), 4)
    c.ins('sty     <VIA_port_b', 6, 'mux on: Y speed %d (the drift down)' % -z['drift'])
    c.ins('ldu     #$01%02X' % SPEED, 3, '(the sample-and-hold settles)')
    c.ins('ldy     #$01%02X' % (-SPEED & 0xFF), 4)
    c.ins('ldd     #$81%02X' % SPEED, 3)
    c.ins('std     <VIA_port_b', 5, 'mux off, X speed %d' % SPEED)
    c.ins('lda     ,x+', 6, 'bytes 0 and 1')
    c.ins('ldb     ,x+', 6)
    c.ins('stu     <VIA_port_b', 5, 't = 0: ramp on')
    sched = z['sched']
    for idx, (t, op, ln, arg) in enumerate(sched):
        if op in ('sta', 'stb'):
            c.ins('%s     <VIA_shift_reg' % op, 4, 't = %d: byte %d' % (t, arg))
        elif op in ('lda', 'ldb'):
            c.ins('%s     ,x+' % op, 6, 't = %d: byte %d' % (t, arg))
        elif op == 'flip':
            c.ins('%s     <VIA_port_b' % ('sty' if arg % 2 == 0 else 'stu'), ln,
                  't = %d: row %d, X speed %s' % (t, arg + 1, '-80' if arg % 2 == 0 else '+80'))
        elif op == 'off':
            c.ins('ldx     #$8100', 3)
            c.ins('stx     <VIA_port_b', 5, 't = %d: ramp off' % (t + 3))
        else:
            for o, cy in g.delay(ln):
                c.ins(o, cy)
    c.ins('clr     <VIA_shift_reg', 6, 'spot off')
    c.ins('lda     #$98', 2)
    c.ins('sta     <VIA_aux_cntl', 4, 'ACR back')
    c.ins('rts', 5)
    return c.out


SPRITES = [('trogg', 'sTrogg_wr_Beeb', 4), ('scrubbly', 'sScrubbly_Beeb', 1), ('poglet', 'sPoglet_Beeb', 1),
           ('hooter', 'sHooter_Beeb', 1), ('gem', 'sGem_Beeb', 1), ('ladder', 'sLadder5_Beeb', 1),
           ('bulb', 'sBulb_Beeb', 1)]
SCENE = [   # (label, 0 for columns or the zigzag's drift, x, y)
    ('trogg', 0, -100, -104), ('trogg', 1, -72, -104), ('trogg', 2, -44, -104), ('trogg', 3, -16, -104),
    ('trogg', 4, 12, -104),
    ('poglet', 0, -100, -56), ('poglet', 2, -74, -56), ('poglet', 3, -48, -56), ('poglet', 4, -22, -56),
    ('hooter', 0, 8, -50), ('hooter', 2, 30, -50), ('hooter', 3, 52, -50), ('hooter', 4, 74, -50),
    ('scrubbly', 0, -100, -8), ('scrubbly', 1, -64, -8), ('scrubbly', 2, -28, -8),
    ('gem', 0, 14, 0), ('gem', 3, 30, 0), ('gem', 5, 46, 0), ('bulb', 0, 64, -4), ('bulb', 3, 78, -4),
    ('bulb', 6, 92, -4),
]


def main():
    steamfrak = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    full, zig, grids = {}, {}, {}
    for label, name, frames in SPRITES:
        grid = g.sprite_grid(steamfrak, name, 0, frames)
        grids[label] = grid
        full[label] = (g.column_data(grid), len(grid), len(grid[0]))
    for label, mode, x, y in SCENE:
        if mode and (label, mode) not in zig:
            zig[(label, mode)] = zigzag(grids[label], force_drift=mode)
    eng = ['; made by vectrex/tools/m1_zig_gen.py', '']
    for nb in sorted({f[0][0] for f in full.values()}):
        eng += g.column_routine(nb) + ['']
    for (label, drift), z in zig.items():
        eng += emit('zig_%s_%d' % (label, drift), z) + ['']
    open(os.path.join(TEST, 'm1z_engine.asm'), 'w').write('\n'.join(eng) + '\n')

    out = ['; made by vectrex/tools/m1_zig_gen.py: the test scene', '', 'draw_scene']
    moves = []
    g._beam[0] = None
    for i, (label, mode, x, y) in enumerate(SCENE):
        (nb, fcols), h, w = full[label]
        if not mode:
            hs = 8 * nb
            code, mv = g.start_move(i, (x - 0.5) * g.UNIT, -(y - g.COL_PAD) * g.UNIT)
            out += ['; %s at (%d, %d): full columns' % (label, x, y)] + code + \
                ['dc_%d_start' % i, '                ldx     #%s_data' % label,
                 '                lda     #%d' % (w + 1), '                sta     %s' % g.COUNT,
                 '                jsr     col%d_down' % nb, 'dc_%d_end' % i]
            last = w - 1
            g._beam[0] = ((x + last + 0.5) * g.UNIT, -((y - g.COL_PAD) + (0 if last % 2 else hs)) * g.UNIT)
        else:
            z = zig[(label, mode)]
            code, mv = g.start_move(i, x * g.UNIT, -y * g.UNIT)
            out += ['; %s at (%d, %d): zigzag, drift %d' % (label, x, y, mode)] + code + \
                ['dc_%d_start' % i, '                ldx     #%s_%d_z_data' % (label, mode),
                 '                jsr     zig_%s_%d' % (label, mode), 'dc_%d_end' % i]
            ex, ey = z['end']
            g._beam[0] = ((x + ex) * g.UNIT, -(y + ey) * g.UNIT)
        moves += mv
    out.append('                rts')
    out += [''] + moves + ['']
    for label, ((nb, fcols), h, w) in full.items():
        out.append('%s_data' % label)
        out += ['                fcb     ' + ','.join('$%02X' % v for v in col) for col in fcols]
    for (label, drift), z in zig.items():
        out.append('%s_%d_z_data' % (label, drift))
        d = z['data']
        out += ['                fcb     ' + ','.join('$%02X' % v for v in d[i:i + 16]) for i in range(0, len(d), 16)]
    open(os.path.join(TEST, 'm1z_data.asm'), 'w').write('\n'.join(out) + '\n')
    for (label, drift), z in zig.items():
        print('%-9s drift %d: %2d x %2d, pitch %.2f, %d rows, %d bytes, ramp on %d cycles'
              % (label, drift, z['w'], z['h'], z['pitch'], z['rows'], z['nbytes'], z['off']))


if __name__ == '__main__':
    main()
