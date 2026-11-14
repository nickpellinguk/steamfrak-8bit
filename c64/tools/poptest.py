# Checks the yoyo popping balloons and daggers (yoyo_collide, src/yoyo.asm) in a 6502 emulator (py65)
# against the BBC version's rule: the yoyo's square (x yo_x - 3 to yo_x + 3, y yo_y - 7 to yo_y)
# against the object's whole image (its origin less its offset, its width and height, from
# picks.json): random places near each other, a balloon or a dagger; whether it's gone and the yoyo
# hit, compared. (No Scrubbly in reach: they're all yoyoed off first.)
#   python3 poptest.py [N]      (the build as last made, with the balloons and daggers)
import json, os, random, re, sys
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__))); import c64img   # (the level unpacked: loadlevel)
from py65.devices.mpu6502 import MPU
DIR = os.path.dirname(os.path.abspath(__file__)); B = os.path.join(DIR, '..', 'build')
N = int(sys.argv[1]) if len(sys.argv) > 1 else 3000
lbl = {}
for line in open(os.path.join(B, 'frak64.lbl')):
    m = re.match(r'^(\w+)\s*=\s*(\$?)([0-9a-fA-F]+)', line)
    if m: lbl[m.group(1)] = int(m.group(3), 16 if m.group(2) else 10)
HZ = [json.load(open(os.path.join(B, 'picks.json')))['hazards'][n] for n in ('IMG_Balloon', 'IMG_DaggerLR')]
NS = 5; NB = int(re.search(r'^NB\s*=\s*(\d+)', open(os.path.join(DIR, '..', 'src', 'frak64.asm')).read(), re.M).group(1))
prg = open(os.path.join(B, 'frak64.prg'), 'rb').read()
base = c64img.image(prg)
for i in range(NS): base[lbl['knocked'] + i] = 1
stub = 0x033c; base[stub:stub + 3] = bytes([0x20, lbl['yoyo_collide'] & 255, lbl['yoyo_collide'] >> 8])
random.seed(7); bad = 0; hits = 0
for n in range(N):
    mem = bytearray(base)
    yx, yy = random.randrange(0, 740), random.randrange(10, 250)
    k = random.choice([1, 2]); h = HZ[k - 1]
    ox, oy = yx + random.randrange(-25, 26), yy + random.randrange(-25, 26)
    for a, v in (('yo_x', yx), ('yo_y', yy)): mem[lbl[a]] = v & 255; mem[lbl[a] + 1] = (v >> 8) & 255
    for i in range(NB): mem[lbl['oact'] + i] = 0
    mem[lbl['oact']] = k; mem[lbl['oxl']] = ox & 255; mem[lbl['oxh']] = (ox >> 8) & 255; mem[lbl['oy']] = oy & 255; mem[lbl['oyh']] = (oy >> 8) & 255
    mpu = MPU(memory=mem); mpu.pc = stub; mpu.sp = 0xf0
    while mpu.pc != stub + 3: mpu.step()
    got = (mem[lbl['oact']] == 0, mem[lbl['yo_hit']] == 1)
    l, t = ox - h['xo'], oy - h['yo']; r, b = l + len(h['grid'][0]) - 1, t + len(h['grid']) - 1
    want = not (yx + 3 < l or yx - 3 > r or yy < t or yy - 7 > b)
    hits += want
    if got != (want, want):
        bad += 1
        if bad <= 5: print(f'yoyo ({yx}, {yy}), kind {k} at ({ox}, {oy}): program {got}, rule {want}')
print(f'{N} situations: {bad} differ ({hits} popped)')
