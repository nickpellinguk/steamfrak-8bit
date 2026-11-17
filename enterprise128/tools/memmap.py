#!/usr/bin/env python3
"""Phase 2: measure the Enterprise 128's memory map from the CPC version, and check it fits.

Until phases 3-7 bring the CPC version's code over, the sizes of what goes in each segment are the
CPC version's own. This assembles the CPC version (../../cpc6128/src, as it is, with RASM) into raw
files, packs its front end and level loader with the BBC version's packer (../../tools/pack.py),
checks each unpacks to what was packed, and writes:

    build/cpc/*.BIN            the CPC version's files, raw
    build/cpc/FRONT.bin, .lz   the CPC version's front end, and packed
    build/cpc/LOADER.bin, .lz  its level loader, and packed
    src/gen/sizes.asm          their sizes, for src/layout.asm's ASSERTs

then prints the memory map, segment by segment, with what's free.

    RASM=/path/to/rasm python3 tools/memmap.py

It needs the BBC version built first (../build.sh), as the CPC version does.
"""
import importlib.util
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
REPO = os.path.dirname(ROOT)
CPC = os.path.join(REPO, 'cpc6128')
BUILD = os.path.join(ROOT, 'build')

spec = importlib.util.spec_from_file_location('pack', os.path.join(REPO, 'tools', 'pack.py'))
pack = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pack)

# Where things go (see PLAN.md, "Memory", and src/layout.asm)
RING = 20480
FE_SPARE = 0xA1A0 - 0x8000          # segment #FE's offset after buffer 1's ring and mirror
LOADER_RUN = 0xC000 + FE_SPARE      # the loader runs there, with #FE paged in at page 3
FRONT_PACKED_ORG = 0x7000           # in #FF, in the window, after the levels
LPT_WIN = 0x7F00                    # the line parameter tables, at the top of #FF
FRONT_ORG = 0x4000                  # the front end, unpacked into #FB when the menus are up
JIT_MAX = 0xB80                     # the compiled meanie's room (the CPC version's ASSERT)
JIT_ORG = 0x7180                    # where it goes in #FE (in the window), after the loader
RECORDS = 55 * 7                    # the records, moved out of the front end into the low RAM


def cpc_raw():
    """Assemble the CPC version with its SAVEs writing raw files; return them and its symbols"""
    rasm = os.environ.get('RASM', 'rasm')
    work = os.path.join(BUILD, 'cpc')
    shutil.rmtree(work, ignore_errors=True)
    shutil.copytree(os.path.join(CPC, 'src'), os.path.join(work, 'src'))
    os.makedirs(os.path.join(work, 'build'))
    gfx = os.path.join(REPO, 'build', 'GFX4')
    if not os.path.exists(gfx):
        sys.exit('Build the BBC version first (../build.sh): the CPC version uses its graphics')
    # (the CPC version's graphics bank and image directory: its tools/gfx.py makes them)
    if not os.path.exists(os.path.join(CPC, 'build', 'GFX')):
        subprocess.run([sys.executable, os.path.join('tools', 'gfx.py')], cwd=CPC, check=True)
    for name in os.listdir(os.path.join(CPC, 'build')):
        if name != 'frak.dsk':
            shutil.copy(os.path.join(CPC, 'build', name), os.path.join(work, 'build'))
    main = os.path.join(work, 'src', 'frak.asm')
    src = open(main).read()
    src = src.replace(",DSK,'build/frak.dsk'", '')
    open(main, 'w').write(src)
    r = subprocess.run([rasm, 'src/frak.asm', '-o', 'build/x', '-s', '-sa', '-os', 'build/frak.sym'],
                       cwd=work, capture_output=True, text=True)
    if r.returncode:
        sys.exit('The CPC version did not assemble:\n' + r.stdout + r.stderr)
    files = {n: open(os.path.join(work, n), 'rb').read()
             for n in ('FRAK.BIN', 'GFX.BIN', 'PACK.BIN', 'LOGIC.BIN', 'SOUND.BIN')}
    sym = {}
    for line in open(os.path.join(work, 'build', 'frak.sym')):
        m = re.match(r'(\S+)\s+#([0-9A-F]+)', line)
        if m:
            sym[m.group(1).lower()] = int(m.group(2), 16)
    return files, sym


def packed(name, data):
    lz = pack.compress(data)
    if pack.decompress(lz) != data:
        sys.exit(f'{name}: the packer did not give back what it packed')
    open(os.path.join(BUILD, 'cpc', name + '.bin'), 'wb').write(data)
    open(os.path.join(BUILD, 'cpc', name + '.lz'), 'wb').write(lz)
    return lz


def main():
    os.makedirs(BUILD, exist_ok=True)
    files, sym = cpc_raw()
    snd, pk = files['SOUND.BIN'], files['PACK.BIN']
    levels = pk[:sym['pack_size']]
    loader = pk[sym['loader_store'] - 0x4000:]
    front = snd[sym['front_org'] - 0x4000:]
    music = snd[:sym['end_sound_bank'] - 0x4000]
    front_lz, loader_lz = packed('FRONT', front), packed('LOADER', loader)
    low = sym['end_ram'] - sym['start']                 # the CPC's low RAM, code and tables
    logic = len(files['LOGIC.BIN'])
    sizes = {
        'CPC_LOW_SIZE': low, 'GFX_SIZE': len(files['GFX.BIN']), 'LOGIC_SIZE': logic,
        'LEVELS_SIZE': len(levels), 'FRONT_SIZE': len(front), 'FRONT_PACKED_SIZE': len(front_lz),
        'LOADER_SIZE': len(loader), 'LOADER_PACKED_SIZE': len(loader_lz), 'MUSIC_SIZE': len(music),
        'RECORDS_SIZE': RECORDS, 'JIT_MAX': JIT_MAX,
    }
    os.makedirs(os.path.join(ROOT, 'src', 'gen'), exist_ok=True)
    with open(os.path.join(ROOT, 'src', 'gen', 'sizes.asm'), 'w') as f:
        f.write('; The sizes of what goes in each segment (tools/memmap.py, from the CPC version)\n')
        for k, v in sizes.items():
            f.write(f'{k} = {v}\n')

    # the map, segment by segment: (what, from, size) in the Z80's view of the segment
    jit_org = JIT_ORG
    segs = [
        ('#F8 (page 0)', 0x0000, [('restart vectors, EXOS header', 0x0000, 0x100),
                                  ('the CPC low RAM\'s code and tables (moved up from #0040)', 0x100, low),
                                  ('the records (out of the front end)', 0x100 + low, RECORDS)], 0x3F00),
        ('#F9 graphics', 0x4000, [('sprites and code tables (CPC bank 0)', 0x4000, len(files['GFX.BIN']))], 0x8000),
        ('#FA logic', 0x4000, [('the game logic and its variables (CPC bank 2)', 0x4000, logic)], 0x8000),
        ('#FB background', 0x4000, [('the background cache (CPC bank 3), or the front end, unpacked', 0x4000, 0x2A00),
                                     ('the slow save areas', 0x6A00, 0x1600)], 0x8000),
        ('#FC-#FE screens', 0x0000, [('buffer 0: ring and mirror (Nick #0000)', 0x0000, RING + 160),
                                     ('buffer 1: ring and mirror (Nick #5100)', 0x5100, RING + 160)], 0xA1A0),
        ('#FE spare (window)', 0x4000 + FE_SPARE, [('the level loader (run at #%04X, at page 3)' % LOADER_RUN, 0x4000 + FE_SPARE, len(loader)),
                                                   ('the compiled meanie (room for the biggest)', jit_org, JIT_MAX)], 0x8000),
        ('#FF levels', 0x4000, [('the levels, packed (CPC base RAM, as it is)', 0x4000, len(levels)),
                                ('the front end, packed', FRONT_PACKED_ORG, len(front_lz)),
                                ('the line parameter tables (Nick #FF00)', LPT_WIN, 0x100)], 0x8000),
    ]
    ok = True
    print(f'{"":20} {"from":>6} {"to":>6} {"bytes":>6}')
    for name, start, parts, end in segs:
        print(name)
        top, free = start, 0
        for what, frm, size in parts:
            if frm < top:
                print(f'  OVERLAP: {what} starts at #{frm:04X}, before #{top:04X}')
                ok = False
            elif frm > top:
                print(f'  {"(free)":58} #{top:04X}  #{frm - 1:04X}  {frm - top:6}')
                free += frm - top
            print(f'  {what:58} #{frm:04X}  #{frm + size - 1:04X}  {size:6}')
            top = frm + size
        if top > end:
            print(f'  OVERFLOW: past #{end - 1:04X} by {top - end}')
            ok = False
        elif top < end:
            print(f'  {"(free)":58} #{top:04X}  #{end - 1:04X}  {end - top:6}')
            free += end - top
        print(f'  {"free in all":58} {"":13} {free:6}')
    print(f'\nThe front end packs from {len(front)} to {len(front_lz)} bytes, the loader from '
          f'{len(loader)} to {len(loader_lz)}; the music player and tunes ({len(music)} bytes, to come '
          f'back after the first milestone) have no room yet.')
    print('All of it fits.' if ok else 'IT DOES NOT FIT.')
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
