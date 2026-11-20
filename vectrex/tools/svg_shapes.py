#!/usr/bin/env python3
"""
Read line art drawn in Inkscape over the sprite sheets (art/frak-graphics-v001.svg):

    python3 vectrex/tools/svg_shapes.py [SVG]      # lists what's in it

The SVG has the two sprite sheets made for tracing embedded as images: Trogg and the Scrubbly at
6x (the first image) and the scenery at 4x (the second), and the line art as paths of straight
lines (M, L, H, V, Z; no curves). shapes(svg) returns {(sprite, frame): [polyline, ...]}, each
polyline a list of (x, y) in that sprite's pixels, from its top left. Each polyline goes to the
sprite (and frame) its middle is over on the sheet.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_SVG = os.path.join(HERE, '..', 'art', 'frak-graphics-v001.svg')

import base64
import io
import re
import xml.etree.ElementTree as ET

from PIL import Image

NS = {'svg': 'http://www.w3.org/2000/svg', 'xlink': 'http://www.w3.org/1999/xlink'}


def parse_path(d):
    """Polylines (lists of (x, y)) from path data with M/L/H/V/Z, absolute or relative."""
    toks = re.findall(r'[MmLlHhVvZzCcSsQqTtAa]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?', d)
    polys, cur, start = [], None, None
    x = y = 0.0
    i, cmd = 0, None
    def num():
        nonlocal i
        v = float(toks[i]); i += 1
        return v
    while i < len(toks):
        t = toks[i]
        if re.match(r'[A-Za-z]', t):
            cmd = t; i += 1
            if cmd in 'Zz':
                if cur:
                    cur.append(start)
                x, y = start
                cur = None
                continue
            if cmd in 'CcSsQqTtAa':
                raise ValueError('curve in path: %s' % d[:60])
        if cmd in 'Mm':
            dx, dy = num(), num()
            # (a path's first m is from 0,0, which is the same as absolute)
            x, y = (x + dx, y + dy) if cmd == 'm' else (dx, dy)
            cur = [(x, y)]
            start = (x, y)
            polys.append(cur)
            cmd = 'l' if cmd == 'm' else 'L'
        elif cmd in 'Ll':
            dx, dy = num(), num()
            x, y = (x + dx, y + dy) if cmd == 'l' else (dx, dy)
            if cur is None:
                cur = [start]; polys.append(cur)
            cur.append((x, y))
        elif cmd in 'Hh':
            v = num(); x = x + v if cmd == 'h' else v
            if cur is None:
                cur = [start]; polys.append(cur)
            cur.append((x, y))
        elif cmd in 'Vv':
            v = num(); y = y + v if cmd == 'v' else v
            if cur is None:
                cur = [start]; polys.append(cur)
            cur.append((x, y))
    return polys


def read(path):
    root = ET.parse(path).getroot()
    images, paths = [], []
    for el in root.iter():
        tag = el.tag.split('}')[1]
        if tag == 'image':
            href = el.get('{http://www.w3.org/1999/xlink}href')
            data = base64.b64decode(re.sub(r'\s', '', href.split(',', 1)[1]))
            images.append({'id': el.get('id'), 'x': float(el.get('x')), 'y': float(el.get('y')),
                           'w': float(el.get('width')), 'h': float(el.get('height')),
                           'img': Image.open(io.BytesIO(data)).convert('RGBA')})
        elif tag == 'path':
            paths.append({'id': el.get('id'), 'polys': parse_path(el.get('d'))})
    return images, paths


MM_PER_IMGPX = 0.2645833

# the two sheets I made earlier: (scale, gap, [(name, sprite width, frames, height)])
SHEET1 = (6, 12, [('sTrogg_wr_Beeb', 104, 4), ('sTrogg_sr_Beeb', 26, 1), ('sTrogg_cn_Beeb', 20, 1),
                  ('sTrogg_cu_Beeb', 40, 2), ('sTrogg_yr_Beeb', 24, 1), ('sScrubbly_Beeb', 33, 1),
                  ('sScrubbly_Vector', 25, 1)])
SHEET2 = (4, 10, [('sLadder1_Beeb', 12, 1), ('sLadder2_Beeb', 12, 1), ('sLadder3_Beeb', 12, 1),
                  ('sLadder4_Beeb', 12, 1), ('sLadder5_Beeb', 12, 1), ('sChain1_Beeb', 8, 1),
                  ('sChain2_Beeb', 8, 1), ('sChain3_Beeb', 8, 1), ('sChain4_Beeb', 8, 1),
                  ('sLedge1_Beeb', 16, 1), ('sGirder1_Beeb', 12, 1), ('sLog1_Beeb', 68, 1),
                  ('sGem_Beeb', 11, 1), ('sKey_Beeb', 22, 1)])


def locate(images):
    """For each sheet: (image placement, scale, [(name, frame, x offset in sprite px, frame width)])."""
    out = []
    for im, (k, gap, items) in zip(images, (SHEET1, SHEET2)):
        x = 0
        cells = []
        for name, w, n in items:
            fw = w // n
            for f in range(n):
                cells.append((name, f, x / k + f * fw, fw))
            x += w * k + gap
        out.append((im, k, cells))
    return out



def shapes(svg=DEFAULT_SVG):
    images, paths = read(svg)
    sheets = locate(images)
    found = {}
    for path in paths:
        for poly in path['polys']:
            cx = sum(p[0] for p in poly) / len(poly)
            cy = sum(p[1] for p in poly) / len(poly)
            for im, k, cells in sheets:
                if not (im['y'] - 5 <= cy <= im['y'] + im['h'] + 5):
                    continue
                px = (cx - im['x']) / MM_PER_IMGPX / k
                name, f, off, fw = min(cells, key=lambda c: abs(px - (c[2] + c[3] / 2)))
                pts = [((x - im['x']) / MM_PER_IMGPX / k - off, (y - im['y']) / MM_PER_IMGPX / k)
                       for x, y in poly]
                # (dropping the zero-length steps Inkscape leaves, e.g. "v 0")
                clean = [pts[0]] + [b for a, b in zip(pts, pts[1:]) if math.dist(a, b) > 1e-6]
                found.setdefault((name, f), []).append(clean)
                break
    return found


if __name__ == '__main__':
    for (name, f), polys in sorted(shapes(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SVG).items()):
        n = sum(len(p) - 1 for p in polys)
        print('%-18s frame %d: %d polylines, %d vectors' % (name, f, len(polys), n))
