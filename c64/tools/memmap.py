# The program's memory, by source file and by item: each label's address from build/frak64.lbl,
# its file from where it's defined in src/ (and the build's generated .inc files), and its size the
# distance to the next label up; the VIC bank's set-up areas and the gaps shown as they are.
#   python3 memmap.py [N]      (the N biggest items; the build as last made)
import collections, glob, os, re, sys
DIR = os.path.dirname(os.path.abspath(__file__)); B = os.path.join(DIR, '..', 'build'); SRC = os.path.join(DIR, '..', 'src')
N = int(sys.argv[1]) if len(sys.argv) > 1 else 30
lbl = {}
for line in open(os.path.join(B, 'frak64.lbl')):
    m = re.match(r'^(\w+)\s*=\s*\$([0-9a-fA-F]+)', line)
    if m: lbl[m.group(1)] = int(m.group(2), 16)
where = {}
for f in glob.glob(os.path.join(SRC, '*.asm')) + glob.glob(os.path.join(B, '*.inc')):
    for line in open(f, errors='replace'):
        m = re.match(r'^(\w+)\b', line)
        if m and m.group(1) in lbl and m.group(1) not in where and not re.match(r'^\w+\s*=', line): where[m.group(1)] = os.path.basename(f)
prg = open(os.path.join(B, 'frak64.prg'), 'rb').read(); top = 0x0801 + len(prg) - 2
items = sorted((a, n) for n, a in lbl.items() if n in where and 0x0801 <= a < top)
# (the VIC bank: set up at the start, but for the character sets and sprites loaded straight into it)
fill_from, fill_to = lbl['end'], lbl['TROGG']
sizes, byfile = [], collections.Counter()
for (a, n), nxt in zip(items, items[1:] + [(top, None)]):
    b = nxt[0]
    if a <= fill_from < b: b = fill_from                  # (the item before the gap ends at it)
    sizes.append((b - a, n, where[n], a)); byfile[where[n]] += b - a
print(f'program file: $0801-${top - 1:04x}, {top - 0x0801} bytes; of them ${fill_from:04x}-${fill_to - 1:04x} ({fill_to - fill_from} bytes) the VIC bank (zeros in the file but for the character sets and sprites)')
print('\nby file (bytes):')
for f, s in byfile.most_common(): print(f'  {f:16} {s:6}')
print(f'\nthe {N} biggest items:')
for s, n, f, a in sorted(sizes, reverse=True)[:N]: print(f'  {s:6}  ${a:04x}  {n:16} {f}')
