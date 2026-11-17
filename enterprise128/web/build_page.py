# build_page.py: the web page (build/frak-ep128.html): web/page.html with the emulator (build/ep.js,
# the single file that web/build_emulator.sh makes) and the game put in: the program and its four
# files, from build/disk (made by ../build.sh), each with the segment and offset web.cpp loads it
# at (from build/frak.sym: where the program's load_files would put it), and the font (font.py)
# where EXOS keeps its own.
#   python3 web/build_page.py
import base64, json, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.join(HERE, '..'); B = os.path.join(ROOT, 'build')
sys.path.insert(0, HERE)
from font import nick_font

sym = {}
for line in open(os.path.join(B, 'frak.sym')):
    m = re.match(r'(\S+)\s+#([0-9A-F]+)\s', line)
    if m: sym[m.group(1).lower()] = int(m.group(2), 16)
disk = lambda name: open(os.path.join(B, 'disk', name), 'rb').read()
start = disk('START')
assert start[0] == 0 and start[1] == 5, 'build/disk/START is not an EXOS type 5 file'
files = [
    ('START', 0xF8, 0x0100, start[16:16 + (start[2] | start[3] << 8)]),   # (EXOS loads it at #0100)
    ('GFX.BIN', sym['seg_gfx'], 0, disk('GFX.BIN')),
    ('LOGIC.BIN', sym['seg_logic'], 0, disk('LOGIC.BIN')),
    ('LOADER.BIN', sym['seg_jit'], sym['fe_spare'], disk('LOADER.BIN')),
    ('TOP.BIN', sym['seg_video'], 0, disk('TOP.BIN')),                   # (copy_top copies it to #FF)
    ('font', 0xFF, sym['font_nick'] - 0xC000, nick_font()),              # (#FF at page 3: copy_font)
]
FILES = [{'name': n, 'seg': s, 'off': o, 'data': base64.b64encode(d).decode()} for n, s, o, d in files]
epjs = open(os.path.join(B, 'ep.js')).read()
page = open(os.path.join(HERE, 'page.html')).read()
page = page.replace('/*EPJS*/', epjs.replace('</script', '<\\/script')).replace('/*FILES*/', json.dumps(FILES))
open(os.path.join(B, 'frak-ep128.html'), 'w').write(page)
print(f'build/frak-ep128.html: {len(page) // 1024}KB')
