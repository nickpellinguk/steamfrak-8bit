#!/usr/bin/env python3
"""
What each run of vectors in a beamshot capture cost:

    python3 vectrex/tools/timing.py CAPTURE.txt

A capture line is (end cycle, x0, y0, x1, y1, intensity, cycles). This joins each moving line
with the spot standing still just before and after it into a vector, and splits the vectors into
runs wherever the time from one vector's start to the next jumps (a different routine, or a move
with the spot off). For each run: how many vectors, the time from start to start, how long the
beam moved, and how long the spot stood still before and after each.
"""
import statistics
import sys


def vectors(path):
    rows = []
    for line in open(path):
        end, x0, y0, x1, y1, z, cyc = (int(v) for v in line.split())
        rows.append((end - cyc, end, (x0, y0) == (x1, y1), cyc, (x0, y0, x1, y1)))
    rows.sort()
    out = []
    i = 0
    while i < len(rows):
        if rows[i][2]:                      # standing: belongs to the next moving line, if adjacent
            if i + 1 < len(rows) and not rows[i + 1][2] and rows[i + 1][0] - rows[i][1] <= 1:
                before = rows[i][3]
                i += 1
            else:
                out.append({'start': rows[i][0], 'move': 0, 'before': rows[i][3], 'after': 0, 'line': rows[i][4]})
                i += 1
                continue
        else:
            before = 0
        start, end, _, cyc, line = rows[i]
        after = 0
        if i + 1 < len(rows) and rows[i + 1][2] and rows[i + 1][0] - end <= 1:
            after = rows[i + 1][3]
            i += 1
        out.append({'start': start - before, 'move': cyc, 'before': before, 'after': after, 'line': line})
        i += 1
    return out


def main():
    vs = vectors(sys.argv[1])
    runs, run = [], []
    for v in vs:
        if run and len(run) >= 2:
            last = run[-1]['start'] - run[-2]['start']
            gap = v['start'] - run[-1]['start']
            if abs(gap - last) > 12:
                runs.append(run)
                run = []
        elif run and v['start'] - run[-1]['start'] > 400:
            runs.append(run)
            run = []
        run.append(v)
    if run:
        runs.append(run)
    print('%5s %8s %10s %8s %8s %8s  %s' % ('vecs', 'start', 'per vec', 'moving', 'before', 'after', 'first line (x0 y0 x1 y1)'))
    for r in runs:
        periods = [b['start'] - a['start'] for a, b in zip(r, r[1:])]
        per = '%.1f' % statistics.mean(periods) if periods else '-'
        print('%5d %8d %10s %8.1f %8.1f %8.1f  %s' % (
            len(r), r[0]['start'], per, statistics.mean(v['move'] for v in r),
            statistics.mean(v['before'] for v in r), statistics.mean(v['after'] for v in r), r[0]['line']))


if __name__ == '__main__':
    main()
