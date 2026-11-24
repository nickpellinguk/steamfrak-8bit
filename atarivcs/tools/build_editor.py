#!/usr/bin/env python3
"""Build atarivcs/editor/index.html (a complete page) and artifact.html (for the artifact host) from index.src.html, inserting Stella's NTSC palette
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
for ph, f in (('__SCHEDULER__', 'scheduler.js'), ('__MIRROR__', 'mirrorrows.js')):
    out = out.replace(ph, open(os.path.join(ED, f)).read())
# artifact.html: the fragment the Claude artifact host wraps in its own document skeleton
open(os.path.join(ED, 'artifact.html'), 'w').write(out)
# index.html: a complete page for GitHub Pages or any web server (self-contained: the scheduler and
# the row model are built in)
head, sep, body = out.partition('</style>')
page = ('<!doctype html>\n<html lang="en">\n<head>\n<meta name="viewport" content="width=device-width, '
        'initial-scale=1, viewport-fit=cover">\n' + head + sep + '\n</head>\n<body>\n' + body + '\n</body>\n</html>\n')
open(os.path.join(ED, 'index.html'), 'w').write(page)
print('wrote index.html (%d bytes) and artifact.html (%d bytes)' % (len(page), len(out)))
