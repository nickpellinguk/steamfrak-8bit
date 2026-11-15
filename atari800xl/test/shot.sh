#!/bin/sh
# shot.sh XEX OUT.png: run in atari800 (PAL 800XL), capture the window at 2x after 4s
X=$1; O=$2
export SDL_AUDIODRIVER=dummy
pgrep -f "Xvfb :77" >/dev/null || { (setsid Xvfb :77 -screen 0 1024x768x24 >/dev/null 2>&1 &); sleep 1; }
(DISPLAY=:77 setsid timeout 12 atari800 -xl -pal -nobasic -pal-artif none -horiz-area full -vert-area full -win-width 768 -win-height 624 -run "$X" >/dev/null 2>&1 &)
sleep 5
DISPLAY=:77 timeout 5 xwd -root -silent > ${TMPDIR:-/tmp}/rows4_root.xwd
pkill -f "atari800 -xl" ; sleep 1
python3 - "$O" <<'P'
import struct,sys,os
from PIL import Image
d=open(os.environ.get('TMPDIR','/tmp')+'/rows4_root.xwd','rb').read()
f=struct.unpack('>25I',d[:100]); hs=f[0]; w,h=f[4],f[5]; bpl=f[12]; ncol=f[19]
img=Image.frombytes('RGBX',(w,h),d[hs+ncol*12:hs+ncol*12+bpl*h],'raw','BGRX',bpl).convert('RGB')
img=img.crop(img.getbbox()); img.save(sys.argv[1]); print(sys.argv[1], img.size)
P
