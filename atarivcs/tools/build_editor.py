#!/usr/bin/env python3
"""Build atarivcs/editor/index.html from index.src.html, inserting Stella's NTSC palette
(editor/palette.json, sampled from a Stella snapshot of all 128 colours).

    python3 atarivcs/tools/build_editor.py

The page loads editor/feasibility.json (from tools/feasibility.py) at runtime, so serve the
editor folder over HTTP to use it locally:  python3 -m http.server -d atarivcs/editor
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ED = os.path.join(HERE, '..', 'editor')
pal = json.load(open(os.path.join(ED, 'palette.json')))
src = open(os.path.join(ED, 'index.src.html')).read()
out = src.replace('__PALETTE__', ','.join("'%s'" % c[1:] for c in pal))
open(os.path.join(ED, 'index.html'), 'w').write(out)
print('wrote', os.path.join(ED, 'index.html'), len(out), 'bytes')
