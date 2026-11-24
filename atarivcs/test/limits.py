#!/usr/bin/env python3
"""Limits of reusable (all-table) renderers: sweeps object positions through the adapted scheduler (screens2) with a 55 fall-through budget. Run from atarivcs/test."""
import sys, itertools
sys.path.insert(0,'.'); sys.argv=['x']
import screens2 as s
src=s._src.replace("            for r in (('y',) if ins == 'Y' else ('a',)):     # X is the row index\n                held = 'Y' if r == 'y' else ha\n",
 "            for r in (('y',) if ins == 'Y' else (('a','x') if FREEY else ('a',))):\n                held = 'Y' if ins == 'Y' else (ha if r == 'a' else hx)\n")
src=src.replace("ins_l = ins if r == 'a' else ins.replace('lda', 'ldx')","ins_l = ins if r == 'a' else ins.replace('lda', 'ldy')")
src=src.replace("ins_s = 'st%s%s %s' % (r, '.w' if st == 4 else '', reg)","ins_s = 'st%s%s %s' % ({'a':'a','x':'y','y':'y'}[r], '.w' if st == 4 else '', reg)")
ns=dict(s._ns); ns['FREEY']=False; exec(src,ns); sched=ns['schedule']
none=((0,0,0),(0,0,0)); BG=0xAA
LAD=('tbl','Lad'); BLK=('imm',0)
def fits(objs,extra,t0,freey):
    ns['FREEY']=freey
    try: sched(none,none,objs,BLK,True,objs[-1][0] if objs else None,t0=t0,end_limit=53,extra=extra); return True
    except ValueError: return False
X=[x for x in range(19,113) if (x+47)%3==0]
def sweep(name,n,mk,stripe):
    for freey in ((False,) if stripe else (False,True)):
        ok=[];tot=0
        for xs in itertools.combinations(X,n):
            if any(b-a<9 for a,b in zip(xs,xs[1:])): continue
            if n>1 and xs[0]%2==0 and len(X)>0 and n>2 and (xs[1]-xs[0])%6: continue  # thin the 3-object sweep
            tot+=1
            objs,extra=mk(xs)
            if fits(objs,extra,14 if stripe else 10,freey): ok.append(xs)
        print('%-55s %s %4d/%4d fit  e.g. %s'%(name,'A+Y' if freey else 'A  ',len(ok),tot,ok[:4]),flush=True)
def obj(x,i): return (x,('tbl','G%d'%i),('tbl','C%d'%i))
def pf(regs): 
    e=[(0,27,('lda #$%02X'%BG,2),'COLUPF'),(49,49,('Y',0),'COLUPF')]
    return e+[(0,53,('lda R%s,x'%r,4),r) for r in regs]
sweep('1 object',1,lambda xs:([obj(xs[0],0)],[]),False)
sweep('2 objects',2,lambda xs:([obj(x,i) for i,x in enumerate(xs)],[]),False)
sweep('3 objects',3,lambda xs:([obj(x,i) for i,x in enumerate(xs)],[]),False)
sweep('ladder, ladder',2,lambda xs:([(x,LAD,BLK) for x in xs],[]),False)
sweep('ladder, object, ladder',3,lambda xs:([(xs[0],LAD,BLK),obj(xs[1],0),(xs[2],LAD,BLK)],[]),False)
sweep('ladder, ladder, object',3,lambda xs:([(xs[0],LAD,BLK),(xs[1],LAD,BLK),obj(xs[2],0)],[]),False)
sweep('object, ladder, ladder',3,lambda xs:([obj(xs[0],0),(xs[1],LAD,BLK),(xs[2],LAD,BLK)],[]),False)
sweep('ladder + right PF2 + stripe',1,lambda xs:([(xs[0],LAD,BLK)],pf(['PF2'])),True)
sweep('ladder + right PF1,PF2 + stripe',1,lambda xs:([(xs[0],LAD,BLK)],pf(['PF1','PF2'])),True)
sweep('ladder + right PF0,PF1,PF2 + stripe',1,lambda xs:([(xs[0],LAD,BLK)],pf(['PF0','PF1','PF2'])),True)
sweep('object + right PF2 + stripe',1,lambda xs:([obj(xs[0],0)],pf(['PF2'])),True)
sweep('object + right PF1,PF2 + stripe',1,lambda xs:([obj(xs[0],0)],pf(['PF1','PF2'])),True)
sweep('ladder, ladder + right PF2 + stripe',2,lambda xs:([(x,LAD,BLK) for x in xs],pf(['PF2'])),True)
sweep('ladder, ladder + right PF1,PF2 + stripe',2,lambda xs:([(x,LAD,BLK) for x in xs],pf(['PF1','PF2'])),True)
sweep('ladder, object + right PF2 + stripe',2,lambda xs:([(xs[0],LAD,BLK),obj(xs[1],0)],pf(['PF2'])),True)
