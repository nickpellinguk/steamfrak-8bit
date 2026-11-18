#!/usr/bin/env python3
"""
Render what beamshot (vectrex/emu) recorded through the beam model:

    python3 vectrex/tools/render_capture.py CAPTURE.txt OUT.png [--plain] [--width 660]
                                           [--view X0,Y0,X1,Y1]

--view shows only that part of the screen (vecx's beam units: 33000 x 41000, y down).

--plain draws every line at its intensity alone, the way vecx and MAME do, for comparison.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import beam  # noqa: E402


def load(path):
    lines = []
    for row in open(path):
        _, x0, y0, x1, y1, z, cyc = (int(v) for v in row.split())
        lines.append((x0, y0, x1, y1, z, cyc))
    return lines


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('capture')
    ap.add_argument('out')
    ap.add_argument('--plain', action='store_true')
    ap.add_argument('--width', type=int, default=660)
    ap.add_argument('--view')
    a = ap.parse_args()
    view = tuple(float(v) for v in a.view.split(',')) if a.view else None
    lines = load(a.capture)
    if a.plain:
        # every line as if drawn at the reference speed: brightness from the intensity alone
        lines = [(x0, y0, x1, y1, z, max(1.0, ((x1 - x0) ** 2 + (y1 - y0) ** 2) ** 0.5 / beam.REF_SPEED))
                 for x0, y0, x1, y1, z, _ in lines]
        lines = [ln for ln in lines if (ln[0], ln[1]) != (ln[2], ln[3])]   # (no dots where it stands)
        beam.render(lines, a.out, width=a.width, view=view)
    else:
        beam.render(lines, a.out, width=a.width, view=view)
    print(a.out)


if __name__ == '__main__':
    main()
