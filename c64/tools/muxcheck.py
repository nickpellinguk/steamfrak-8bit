# Checks the multiplexer's work, frame by frame, independently of it: breaks in VICE where each
# frame's buffer is finished (muxdone), reads it, and checks that each set-up is early enough for
# its sprite, that no hardware sprite is set up while it's shown, that each row's slide constant
# and tail suit the sprites on its lines 3 and 4 (Trogg's included, and his rows' own tails), that
# the registers in force fit every sprite on every line it's shown, that nothing is set up in the
# ticks left to Trogg, and that the cover sprite is expanded.
#   python3 muxcheck.py [FRAMES [SECONDS]]     (defaults 8 frames, from 6 s; on the last build)
import os, re, subprocess, sys
C64=os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
lbl={}
for line in open(C64+'/build/frak64.lbl'):
    m=re.match(r'^(\w+)\s*=\s*(\$?)([0-9a-fA-F]+)',line)
    if m: lbl[m.group(1)]=int(m.group(3),16 if m.group(2) else 10)
N=int(sys.argv[1]) if len(sys.argv)>1 else 8
NV=lbl["vt"]-lbl["vh"]          # (the virtual sprites: vh is NV long, vt follows)
BL=lbl["t017"]-lbl["t010"]     # (each buffer array's length: 32 a buffer)
per=[('nb',1),('t010',BL*20),('vh',NV*15),('vy',NV*6),('tpen',9),('tmsbb',5)]   # contiguous blocks
# addresses: buffers are contiguous from t010 (20 arrays x BL); model from vh; virtual sprites from vy
const=[('maskjm',256),('masktl',256),('maskth',256),('masktla',256),('masktha',256),('masktlb',256),('maskthb',256)]
cmds=['m %04x %04x'%(lbl[n],lbl[n]+l-1) for n,l in const]+['break %04x'%lbl['muxdone']]
for i in range(N):
    cmds.append('x')
    for n,l in per: cmds.append('m %04x %04x'%(lbl[n],lbl[n]+l-1))
out=subprocess.run(['python3',C64+'/tools/vice.py',sys.argv[2] if len(sys.argv)>2 else '6']+cmds,capture_output=True,text=True).stdout
bl=out.split('> m ')[1:]
def vals(b):
    v=[]
    for line in b.splitlines():
        m=re.match(r'.*>C:[0-9a-f]+\s+((?:[0-9a-f]{2}\s+)+)',line)
        if m: v+=[int(x,16) for x in m.group(1).split()]
    return v
mjm,mtl,mth,mtla,mtha,mtlb,mthb=[vals(bl[i]) for i in range(7)]
bufnames=['t010','t017','t01d','t01b','trch','e_n','e_reg','e_x','e_y','e_ptr','e_col','u_n','u_reg','u_y','u_x','u_ptr','u_col','rowimm','rowtl','rowth']
vnames=['vy','vxlo','vxhi','vptr','vcol','vfl']
probs=0; k=7
for f in range(N):
    if k+len(per)>len(bl): break
    nb=vals(bl[k])[0]; buf=vals(bl[k+1]); vm=vals(bl[k+3]); tp=vals(bl[k+4]); tm=vals(bl[k+5]); k+=len(per)
    TYv=tp[0]; tmsb,tra,trb,tres1,tres2=tm[:5]; TL=min(255,TYv+42)
    B={n:buf[i*BL:(i+1)*BL] for i,n in enumerate(bufnames)}
    V={n:vm[i*NV:(i+1)*NV] for i,n in enumerate(vnames)}
    # set-ups in the buffer
    ins=[]
    for s in range(4):
        n=B['e_n'][nb+s]
        if n!=255: ins.append(dict(t=0,h=n,y=B['e_y'][nb+s],x=B['e_x'][nb+s],ptr=B['e_ptr'][nb+s],reg=B['e_reg'][nb+s]))
    for t in range(1,26):
        n=B['u_n'][nb+t]
        if n!=255: ins.append(dict(t=t,h=n,y=B['u_y'][nb+t],x=B['u_x'][nb+t],ptr=B['u_ptr'][nb+t],reg=B['u_reg'][nb+t]))
    # match to virtual sprites by (y, x)
    shownv=0
    for i in ins:
        c=[v for v in range(NV) if V['vy'][v]==i['y'] and V['vxlo'][v]==i['x'] and not V['vfl'][v]&0x80]
        if not c: print(f'f{f}: set-up {i} matches no virtual sprite'); probs+=1; i['l']=i['y']+21; i['fl']=0; i['msb']=0; continue
        v=c[0]; fl=V['vfl'][v]; i['fl']=fl; i['msb']=V['vxhi'][v]&1
        i['l']=min(255,i['y']+(42 if fl&1 else 21))
        if i['reg']!=2*i['h']: print(f'f{f}: reg {i}'); probs+=1
        if i['h']<3 or i['h']>7: print(f'f{f}: hw {i}'); probs+=1
    vis=[v for v in range(NV) if not V['vfl'][v]&0x80 and 47<=V['vy'][v]<251]
    # timing: early enough, hardware sprite free
    for i in ins:
        if i['t']>0 and i['y']<62+8*(i['t']-1): print(f'f{f}: too late {i}'); probs+=1
    for h in range(3,8):
        seq=sorted([i for i in ins if i['h']==h],key=lambda i:(i['t'],i['y']))
        for a,b in zip(seq,seq[1:]):
            if b['t']==0 or a['l']>46+8*b['t']: print(f'f{f}: hw {h} clash {a} {b}'); probs+=1
    # rows
    for r in range(25):
        m3=1; m4=1
        if TYv+1<=54+8*r<=TL: m3|=6
        if TYv+1<=55+8*r<=TL: m4|=6
        for i in ins:
            if i['y']+1<=54+8*r<=i['l']: m3|=1<<i['h']
            if i['y']+1<=55+8*r<=i['l']: m4|=1<<i['h']
        tl,th=(mtla,mtha) if r==tra else (mtlb,mthb) if r==trb else (mtl,mth)
        if B['rowimm'][nb+r]!=mjm[m3] or B['rowtl'][nb+r]!=tl[m4] or B['rowth'][nb+r]!=th[m4]:
            print(f'f{f}: row {r} operands wrong (masks {m3:02x}/{m4:02x})'); probs+=1
    # registers in force on each line
    def regs_at(line):
        cur=(B['t010'][nb],B['t017'][nb],B['t01d'][nb],B['t01b'][nb])
        for t in range(1,26):
            if 56+8*(t-1)<=line and B['u_n'][nb+t]!=255 and B['trch'][nb+t]:
                cur=(B['t010'][nb+t],B['t017'][nb+t],B['t01d'][nb+t],B['t01b'][nb+t])
        return cur
    for i in ins:
        want=(i['fl']&1,(i['fl']>>1)&1,(i['fl']>>2)&1,i['msb'])
        for line in range(i['y']+1,i['l']+1):
            r=regs_at(line); h=i['h']
            got=((r[1]>>h)&1,(r[2]>>h)&1,(r[3]>>h)&1,(r[0]>>h)&1)
            if got!=want: print(f'f{f}: regs wrong for {i} on line {line}: {got} want {want}'); probs+=1; break
    if (B['t017'][nb]&1)!=1 or (B['t01d'][nb]&1)!=1: print(f'f{f}: cover not expanded'); probs+=1
    # Trogg: his ticks left alone; his sprites' bits in the registers on his lines
    for t in range(max(1,tres1),min(25,tres2)+1):
        if B['u_n'][nb+t]!=255: print(f'f{f}: a set-up in Trogg\'s tick {t}'); probs+=1
    for line in range(TYv+1,TL+1):
        rg=regs_at(line)
        if (rg[0]&6)!=tmsb or (rg[1]&6) or (rg[2]&6) or (rg[3]&6): print(f'f{f}: Trogg\'s register bits wrong on line {line}: {rg}'); probs+=1; break
    exp_tra = (TYv-35)>>3 if TYv>=35 and (TYv-35)>>3 < 25 else 255
    if tra!=exp_tra: print(f'f{f}: Trogg\'s row {tra}, not {exp_tra}'); probs+=1
    print(f'frame {f}: {len(ins)} set-ups, {len(vis)} visible; Trogg y {TYv}, rows {tra}/{trb}, ticks {tres1}-{tres2} left alone')
print('problems:',probs)
