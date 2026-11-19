#!/usr/bin/env python3
"""
The cheapest chain of trimmed columns for a sprite, by dynamic programming over where the beam is
between columns (tools/m1_trim_gen.py has the routine's timing).

A column: n bytes; a lead-in of l pixels (entering the run part way through a slot's padding:
LEADS); a delay of q pixels (2q cycles) before its closing stores (the slide, the ramp off),
one of DELAYS (a copy of the runs for each). With the beam starting it at row S (y down; half
pixels: a down column's first bit is at S + 0.5 + l, an up column's at S - 1.5 - l), it sweeps
8n + 3 + l + q pixels, costs 16n + 41 + 2l + 2q cycles, shows bits from its first for 8n - 1
pixels (its last bit blank), and ends where the next column starts.

    python3 vectrex/tools/trim_plan.py [../steamfrak]
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import m1_gen as g  # noqa: E402

MAXN = 14


def plan(grid, leads, delays, lit='#'):
    """(cycles, [(n, l, q, first bit's row)...], [each column's start row, and where the last ends])
    for the cheapest chain."""
    h, w = len(grid), len(grid[0])
    rows = [[r for r in range(h) if grid[r][c] in lit] for c in range(w)]
    a = [min(r) if r else None for r in rows]
    b = [max(r) if r else None for r in rows]
    # positions doubled (half pixels as integers): S2 = 2S
    lo, hi = -40, 2 * h + 40
    INF = 10 ** 9
    # best[S2] = (cost, back-pointer)
    best = {s2: (0, None) for s2 in range(lo, hi + 1) if s2 % 2 != 0}     # S is a half-integer
    history = []
    for k in range(w):
        down = k % 2 == 0
        nxt = {}
        for s2, (cost, _) in best.items():
            S = s2 / 2
            for l in leads:
                first = S + 0.5 + l if down else S - 1.5 - l
                if a[k] is not None:
                    if down and first > a[k]:
                        continue
                    if not down and first < b[k]:
                        continue
                    span = (b[k] - first) if down else (first - a[k])
                    nmin = max(1, math.ceil((span + 2) / 8))
                else:
                    nmin = 1
                for n in range(nmin, MAXN + 1):
                    for q in delays:
                        travel = 8 * n + 3 + l + q
                        e2 = s2 + 2 * travel if down else s2 - 2 * travel
                        if not lo <= e2 <= hi:
                            continue
                        c = cost + 16 * n + 41 + 2 * l + 2 * q
                        if c < nxt.get(e2, (INF,))[0]:
                            nxt[e2] = (c, (s2, n, l, q, first))
        history.append(nxt)
        best = nxt
    # back out
    e2 = min(best, key=lambda s: best[s][0])
    total = best[e2][0]
    chain, starts = [], [e2 / 2]
    for k in range(w - 1, -1, -1):
        s2, n, l, q, first = history[k][e2][1]
        chain.append((n, l, q, first))
        starts.append(s2 / 2)
        e2 = s2
    chain.reverse()
    starts.reverse()
    return total, chain, starts


SPRITES = [('trogg', 'sTrogg_wr_Beeb', 4), ('trogg_climb', 'sTrogg_cu_Beeb', 2), ('scrubbly', 'sScrubbly_Beeb', 1),
           ('poglet', 'sPoglet_Beeb', 1), ('hooter', 'sHooter_Beeb', 1), ('gem', 'sGem_Beeb', 1),
           ('balloon', 'sBalloon_Beeb', 1), ('dagger', 'sDagger_Beeb', 1), ('bulb', 'sBulb_Beeb', 1),
           ('ladder', 'sLadder5_Beeb', 1), ('chain', 'sChain4_Beeb', 1)]
OPTIONS = [('1 run, no lead-ins', [0], [0]), ('1 run, lead-ins', [0, 1, 2, 3, 6], [0]),
           ('4 runs, lead-ins', [0, 1, 2, 3, 6], [0, 2, 4, 6]),
           ('8 runs, lead-ins', [0, 1, 2, 3, 6], list(range(8))),
           ('8 runs, no lead-ins', [0], list(range(8)))]


def main():
    steamfrak = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', '..', 'steamfrak')
    print('%-12s %6s ' % ('', 'full') + ''.join('%22s' % o[0] for o in OPTIONS))
    for label, name, frames in SPRITES:
        grid = g.sprite_grid(steamfrak, name, 0, frames)
        nb = math.ceil((len(grid) + 4) / 8)
        w = len(grid[0])
        full = sum(16 * nb + 35 + (3 if k % 2 == 0 and k > 0 else 0) for k in range(w))
        cells = []
        for _, leads, delays in OPTIONS:
            c = plan(grid, leads, delays)[0]
            cells.append('%15d (%+3d%%)' % (c, round(100 * (c - full) / full)))
        print('%-12s %6d ' % (label, full) + ''.join('%22s' % x for x in cells))


if __name__ == '__main__':
    main()
