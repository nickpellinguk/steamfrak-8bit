# readrows.py PNG: the glyph line shown on each scanline: A<n> (a pair's first row), B<n> (second),
# N<n> (the normal row at the top); runs printed as row lengths too
import sys
from PIL import Image
im=Image.open(sys.argv[1]).convert('L'); W,H=im.size; px=im.load()
lit=lambda x,y: px[x,y]>128
ys=range(0,H,2)
first=next(y for y in ys if any(lit(x,y) for x in range(W)))
x0=next(x for x in range(W) if lit(x,first))
# the marker (column 36) on A rows gives the cell width
mx=None
for y in ys:
    xs=[x for x in range(W) if lit(x,y)]
    if xs and xs[-1]-x0>W/2: mx=min(x for x in xs if x-x0>W/2); break
cw=(mx-x0)/36
seq=[]
for y in ys:
    a=[k for k in range(8) if lit(int(x0+(k+0.5)*cw),y)]
    b=[k for k in range(8) if lit(int(x0+(16+k+0.5)*cw),y)]
    m=lit(int(x0+36.5*cw),y)
    if a: seq.append(('A' if m else 'N')+(str(a[0]) if len(a)==1 else '?'))
    elif b: seq.append('B'+(str(b[0]) if len(b)==1 else '?'))
    else: seq.append(None)
while seq and seq[0] is None: seq.pop(0)
while seq and seq[-1] is None: seq.pop()
# group into rows: a new row when the kind changes or the line number doesn't follow on
rows=[]; 
for s in seq:
    k=s[0] if s else '.'
    if rows and rows[-1][0]==k and s and rows[-1][1][-1] is not None and s[1:]!='?' and rows[-1][1][-1]!='?' and int(s[1:])==int(rows[-1][1][-1])+1: rows[-1][1].append(s[1:])
    else: rows.append([k,[s[1:] if s else None]])
print(' '.join(f"{k}:{''.join(x or '.' for x in v)}" for k,v in rows))
