# Checks the screen memory the VIC shows against the map, in VICE: after SECONDS (each given),
# the pair shown (front), its origin (po), the coarse position (curc) and the VSP offset (vson)
# read from memory, and every cell of screen columns 2-39 of both screens compared with the level
# as it is in memory (tops, bottoms: changed where a Scrubbly's been yo-yoed off). Also the hidden
# pair, against the window it says it's up to date for.
#   python3 scrcheck.py SECONDS...      (the build as last made)
import os, re, subprocess, sys
DIR = os.path.dirname(os.path.abspath(__file__)); B = os.path.join(DIR, '..', 'build')
lbl = {}
for line in open(os.path.join(B, 'frak64.lbl')):
    m = re.match(r'^(\w+)\s*=\s*(\$?)([0-9a-fA-F]+)', line)
    if m: lbl[m.group(1)] = int(m.group(3), 16 if m.group(2) else 10)
t = open(os.path.join(B, 'tops.bin'), 'rb').read(); b = open(os.path.join(B, 'bottoms.bin'), 'rb').read()
NC = len(t) // 25
def run(secs):
    cmds = ['m %04x %04x' % (a, a + n - 1) for a, n in ((0x4000, 0x1000), (lbl['po'], 2), (lbl['pvw'], 2), (lbl['vson'], 1), (2, 128), (lbl['tops'], len(t)), (lbl['bottoms'], len(b)))]
    out = subprocess.run(['python3', os.path.join(DIR, 'vice.py'), str(secs)] + cmds, capture_output=True, text=True).stdout
    blocks = []
    for blk in out.split('> m ')[1:]:
        v = []
        for line in blk.splitlines():
            mm = re.match(r'.*>C:[0-9a-f]+\s+((?:[0-9a-f]{2}\s+)+)', line)
            if mm: v += [int(x, 16) for x in mm.group(1).split()]
        blocks.append(v)
    return blocks
for secs in sys.argv[1:]:
    mem, po, pvw, vson, zp, tm, bm = run(secs)          # (the map as it is in memory: Scrubblies yo-yoed off changed)
    if tm != list(t) or bm != list(b): print(f'  (the map in memory differs from the files in {sum(x != y for x, y in zip(tm + bm, list(t) + list(b)))} cells: Scrubblies yo-yoed off, gems or keys picked up)')
    z = lambda name: zp[lbl[name] - 2]
    front, lfront, curc = z('front'), z('lfront'), z('curc')
    sgn = lambda v: v - 256 if v > 127 else v
    msgs = []
    for p, w in ((front, curc), (front ^ 1, pvw[front ^ 1])):
        if w == 255: msgs.append(f'pair {p}: being filled'); continue
        o = sgn(po[p]); s = w - o; bad = []
        for scr, src in ((0, tm), (1, bm)):
            base = (p * 2 + scr) * 0x400
            for r in range(25):
                for c in range(2, 40):
                    a = 40 * r + s + c
                    if a >= 1016: continue
                    if mem[base + a] != src[r * NC + w + c]: bad.append((scr, r, c))
        msgs.append(f'pair {p} ({"shown" if p == front else "hidden"}) window {w} origin {o} offset {s}: ' + (f'{len(bad)} cells wrong, e.g. {bad[:6]}' if bad else 'all cells right'))
    print(f'{secs} s: front {front} (next {lfront}), curc {curc}, VSP offset {vson[0]}; ' + '; '.join(msgs))
