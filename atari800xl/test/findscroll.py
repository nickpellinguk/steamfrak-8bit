# findscroll.py CAPTURE.png EXPECT.png: the scroll position a capture of the moving demo matches,
# by trying every one (checkscreen.py's test); exit 1 if none matches exactly
import sys, subprocess, re
best = None
for x in range(0, 229):
    r = subprocess.run([sys.executable, __file__.replace('findscroll', 'checkscreen'), sys.argv[1], sys.argv[2], str(x)], capture_output=True, text=True)
    if r.returncode == 0: print(f'{sys.argv[1]}: matches x {x} exactly'); sys.exit(0)
    m = re.search(r"(\d+) differ", r.stdout); n = int(m.group(1)) if m else 10**9
    if best is None or n < best[1]: best = (x, n)
print(f'{sys.argv[1]}: no exact match (nearest x {best[0]}, {best[1]} pixels differ)'); sys.exit(1)
