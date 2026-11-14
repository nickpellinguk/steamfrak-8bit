# The program's memory as the game sees it once started: build/frak64.prg loaded at $0801, the
# streams that go under the I/O moved there (undercp), then the level's own data unpacked by the program's own loader (loadlevel, loader.asm), run in py65 (its
# glyphs, sprites and map aren't in the program as loaded, but packed). For the py65 tests.
#   import c64img; mem = c64img.image(prg)
import os, re
from py65.devices.mpu6502 import MPU
B = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'build')
def labels():
    L = {}
    for line in open(os.path.join(B, 'frak64.lbl')):
        m = re.match(r'(\w+)\s*=\s*(\$?)([0-9a-fA-F]+)', line)
        if m: L[m.group(1)] = int(m.group(3), 16 if m.group(2) else 10)
    return L
def image(prg=None, level=0):
    if prg is None: prg = open(os.path.join(B, 'frak64.prg'), 'rb').read()
    mem = bytearray(65536); mem[0x0801:0x0801 + len(prg) - 2] = prg[2:]
    L = labels()
    def call(name, a=0):
        cpu = MPU(memory=mem)
        HALT = 0xfff0
        cpu.sp = 0xff; cpu.memory[0x1ff], cpu.memory[0x1fe] = (HALT - 1) >> 8, (HALT - 1) & 255; cpu.sp = 0xfd
        cpu.a = a; cpu.pc = L[name]
        for _ in range(5_000_000):
            if cpu.pc == HALT: return
            cpu.step()
        raise RuntimeError(name + ' did not return')
    if 'undercp' in L: call('undercp')              # (the cold start's: the streams under the I/O)
    call('loadlevel', level)
    return mem
