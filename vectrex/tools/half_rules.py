#!/usr/bin/env python3
"""
Halving rules for half-resolution sprites (columns 2 pixels apart), side by side:
preview/half_rules.png. python3 vectrex/tools/half_rules.py [../steamfrak]
"""
import os
import sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import m1_gen as g
from PIL import Image, ImageDraw
SF=sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'steamfrak')
names=['sTrogg_wr_Beeb','sScrubbly_Beeb','sPoglet_Beeb','sHooter_Beeb','sLadder5_Beeb','sGem_Beeb','sChain4_Beeb']
def lit(gr,ch='#'): return [[c in ch for c in r] for r in gr]
def outline(gr):
    h,w=len(gr),len(gr[0]); op=[[c!='.' for c in r] for r in gr]
    return [[op[y][x] and any(not(0<=y+dy<h and 0<=x+dx<w and op[y+dy][x+dx]) for dy,dx in ((0,1),(0,-1),(1,0),(-1,0))) for x in range(w)] for y in range(h)]
def half_or(b): return [[any(r[x] for x in (2*c,2*c+1) if x<len(r)) for c in range((len(r)+1)//2)] for r in b]
def half_even(b): return [[r[2*c] for c in range((len(r)+1)//2)] for r in b]
rules=[('full black',lambda gr: lit(gr),1),('half: OR black',lambda gr: half_or(lit(gr)),2),
       ('half: even cols',lambda gr: half_even(lit(gr)),2),('half: OR outline',lambda gr: half_or(outline(gr)),2),
       ('full outline',lambda gr: outline(gr),1)]
S=3; cw=40*S; im=Image.new('RGB',(len(rules)*cw*1+20, sum(80*S for _ in names)+40),(0,0,0))
d=ImageDraw.Draw(im); y0=20
for i,(t,_,_) in enumerate(rules): d.text((i*cw+5,4),t,fill=(200,200,200))
for n in names:
    fr=4 if '_wr' in n else 1
    gr=g.sprite_grid(SF,n,0,fr)
    for i,(t,f,st) in enumerate(rules):
        b=f(gr)
        for y,row in enumerate(b):
            for c,on in enumerate(row):
                if on:
                    x=i*cw+10+(c*st+ (st-1)/2)*S; yy=y0+y*S
                    d.ellipse([x,yy,x+S-1,yy+S-1],fill=(150,255,170))
    y0+=len(gr)*S+12
im=im.crop((0,0,im.width,y0)); im.save(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'preview', 'half_rules.png'))
