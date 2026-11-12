# The collision check's cost (src/collide.asm), in a 6502 emulator (py65): Trogg at random places,
# with 0, 3 and 6 balloons and daggers out at random; cycles per call, least, most and mean.
#   python3 collidecost.py      (the build as last made)
import os, random, re
from py65.devices.mpu6502 import MPU
B = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'build')
lbl = {}
for line in open(os.path.join(B, 'frak64.lbl')):
    m = re.match(r'^(\w+)\s*=\s*(\$?)([0-9a-fA-F]+)', line)
    if m: lbl[m.group(1)] = int(m.group(3), 16 if m.group(2) else 10)
prg = open(os.path.join(B, 'frak64.prg'), 'rb').read(); base = bytearray(65536); base[0x801:0x801 + len(prg) - 2] = prg[2:]
stub = 0x7f00; base[stub:stub + 3] = bytes([0x20, lbl['collide'] & 255, lbl['collide'] >> 8])
random.seed(2)
for nb in (0, 3, 6):
    v = []
    for t in range(200):
        mem = bytearray(base); tx = random.randrange(20, 700); ty = random.randrange(60, 230)
        mem[lbl['tx']] = tx & 255; mem[lbl['tx'] + 1] = tx >> 8; mem[lbl['ty']] = ty; mem[lbl['ty'] + 1] = 0
        mem[lbl['tfr']] = random.randrange(15); mem[lbl['dead']] = 0
        for i in range(6):
            mem[lbl['oact'] + i] = 1 if i < nb else 0; x = random.randrange(0, 740)
            mem[lbl['oxl'] + i] = x & 255; mem[lbl['oxh'] + i] = x >> 8; mem[lbl['oy'] + i] = random.randrange(20, 250)
        mpu = MPU(memory=mem); mpu.pc = stub; mpu.sp = 0xf0; c0 = mpu.processorCycles
        while mpu.pc != stub + 3: mpu.step()
        v.append(mpu.processorCycles - c0)
    print(f'{nb} balls out: {min(v)}-{max(v)} cycles, mean {sum(v) // len(v)}')
