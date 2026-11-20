#!/usr/bin/env python3
"""
The rows' real spacing in a multi-pass zigzag (tools/m1_zigp_gen.py): for each column of the
sprite, where every row of every pass crosses it, and the gaps between neighbouring rows (over
the sprite's height). gaps(passes, w, h) -> (mean gap, 90th percentile, largest).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)


def crossings(passes, x):
    ys = []
    for p in passes:
        d = p['dots']
        for (x0, y0), (x1, y1) in zip(d, d[1:]):
            if min(x0, x1) <= x < max(x0, x1):        # (each crossing once)
                ys.append(y0 + (y1 - y0) * (x - x0) / (x1 - x0))
    return sorted(ys)


def gaps(passes, w, h):
    allg = []
    for xi in range(1, 2 * w):
        x = xi / 2
        ys = [y for y in crossings(passes, x) if 0 <= y <= h]
        allg += [b - a for a, b in zip(ys, ys[1:])]
    allg.sort()
    if not allg:
        return 0, 0, 0
    return sum(allg) / len(allg), allg[int(0.9 * len(allg))], allg[-1]


def mean_square(passes, w, h, margin=2):
    """The mean of the gaps squared (the big gaps counting most), the top and bottom margins left
    out (where passes end)."""
    tot, n = 0.0, 0
    for xi in range(1, 2 * w):
        ys = [y for y in crossings(passes, xi / 2) if margin <= y <= h - margin]
        for a, b in zip(ys, ys[1:]):
            tot += (b - a) ** 2
            n += 1
    return tot / max(1, n)
