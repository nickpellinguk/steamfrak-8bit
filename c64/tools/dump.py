# Runs the demo in VICE for SECONDS, then prints memory at labels from build/frak64.lbl:
#   python3 dump.py SECONDS label:length [label:length ...]      (or an address in hex: $1234:8)
import os, re, subprocess, sys
DIR = os.path.dirname(os.path.abspath(__file__))
lbl = {}
for line in open(os.path.join(DIR, '..', 'build', 'frak64.lbl')):
    m = re.match(r'^(\w+)\s*=\s*(\$?)([0-9a-fA-F]+)', line)
    if m: lbl[m.group(1)] = int(m.group(3), 16 if m.group(2) else 10)
cmds, names = [], []
for a in sys.argv[2:]:
    name, n = a.split(':')
    addr = int(name[1:], 16) if name.startswith('$') else lbl[name]
    cmds.append('m %04x %04x' % (addr, addr + int(n) - 1)); names.append(name)
out = subprocess.run(['python3', os.path.join(DIR, 'vice.py'), sys.argv[1]] + cmds, capture_output=True, text=True).stdout
blocks = out.split('> m ')[1:]
for name, b in zip(names, blocks):
    vals = []
    for line in b.splitlines():
        m = re.match(r'.*>C:[0-9a-f]+\s+((?:[0-9a-f]{2}\s+)+)', line)
        if m: vals += m.group(1).split()
    print('%-8s %s' % (name, ' '.join(str(int(v, 16)) for v in vals)))
