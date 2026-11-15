# budget.py [LEVEL...]: character codes the static graphics need per set, 8x8 against 8x4, by row
# bands, from the C64 build's pictures of each level (c64/build/<level>/chars*.bin: run
# "node c64/tools/level.mjs A_1 --out A_1" first). Black pixels only (what mode 2 shows); the
# knocked-off and picked-up versions included. "8x4 paired halves": a code holds a different
# 4-line glyph in each half (one for tops rows, one for bottoms rows).
import os, sys, functools
H=200
def load(lv):
    d=os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'c64', 'build', lv, '')
    vs=[open(d+f,'rb').read() for f in ('chars.bin','chars_off.bin','chars_gone.bin')]
    return vs, len(vs[0])//H
def rowsets(lv, ch, phase):
    vs,W=load(lv); nr=(H-phase)//ch; rs=[set() for _ in range(nr)]
    for b in vs:
        for r in range(nr):
            for c in range(W//8):
                rs[r].add(tuple(b[(phase+r*ch+l)*W+c*8+x]==3 for l in range(ch) for x in range(8)))
    return rs
def best_bands(cost, n, k):
    # partition rows 0..n-1 into k contiguous bands minimising the max cost(i,j)
    @functools.lru_cache(None)
    def f(i,k):
        if k==1: return cost(i,n)
        return min(max(cost(i,j), f(j,k-1)) for j in range(i+1, n-k+2))
    return f(0,k)
for lv in (sys.argv[1:] or ['A_1','A_2','A_3']):
    out=[lv]
    for ph in (0,4):
        rs=rowsets(lv,8,ph); n=len(rs)
        cost=lambda i,j: len(set().union(*rs[i:j]))
        out.append(f"8x8 phase {ph}: " + ", ".join(f"{k} set{'s' if k>1 else ''} {best_bands(cost,n,k)}" for k in (1,2,3,4)))
    hr=rowsets(lv,4,0)   # half rows: even = tops, odd = bottoms
    n=len(hr)
    def cost4(i,j):
        t=set().union(*[hr[r] for r in range(i,j) if r%2==0]); b=set().union(*[hr[r] for r in range(i,j) if r%2==1])
        return max(len(t),len(b))   # codes: one top slot + one bottom slot each
    def cost4o(i,j): return len(set().union(*hr[i:j]))  # orthogonal (C64 style)
    out.append("8x4 paired halves: " + ", ".join(f"{k} sets {best_bands(cost4,n,k)}" for k in (1,2,3,4)))
    out.append("8x4 orthogonal:    " + ", ".join(f"{k} sets {best_bands(cost4o,n,k)}" for k in (1,2,3,4)))
    print("\n  ".join(out))
