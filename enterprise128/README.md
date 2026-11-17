# Frak! for the Enterprise 128

A port of the CPC 6128 version ([`../cpc6128`](../cpc6128/README.md)), which is itself a Z80 port
of the BBC Master version, to the Enterprise 128. The plan, phase by phase, is in
[`PLAN.md`](PLAN.md).

**Status: phase 7 done:** the whole game runs, the attract screen, menus, levels,
level-complete screen and records, with no music yet (see [`PLAN.md`](PLAN.md)). Phase 6: the
game plays, every level, at 9.3 frames a second on average. Phase 5: the game logic. Phase 4: the levels and the background. Phase 3: the plotter. Phase 2: the memory map, measured, fits. Phase 1: the machine layer and the
screen. Phase 0
(the toolchain and the test harness): The program loads, asks EXOS
which RAM segments it will give out, takes the machine over and tells the test harness it's
ready, on EXOS 2.1 and EXDOS 1.3, in a headless build of ep128emu and in MAME. On an
Enterprise 128 with EXDOS, EXOS gives out every segment but page 0's (`&F8`) and its own
(`&FF`): `&F9-&FE`.

## Building

You need [RASM](https://github.com/EdouardBERGE/rasm), built from its source (v3.3.1, as for
the CPC version), and Python 3.

```sh
gcc -O2 -DNO_3RD_PARTIES -o rasm rasm.c -lm
RASM=/path/to/rasm ./build.sh
```

`build.sh` first runs `tools/memmap.py` (when the CPC version has changed), which measures the
memory map from the CPC version's own build, so the BBC version must be built first
(`../build.sh`), as for the CPC version. It writes `src/gen/sizes.asm`, the front end and level
loader packed (`build/*.lz`), and the map (`build/memmap.txt`).

Assembling takes two passes: the first makes `build/FRONT.BIN`, the front end, which `build.sh`
packs (`build/FRONT.lz`) for the second to put in segment `&FF`'s file. That makes
`build/TOP.BIN` (the levels and the front end, packed, for segment `&FF`), `build/LOADER.BIN` (the
level loader, for `&FE`), and `build/FRAK.COM`, an EXOS type 5 program (a 16-byte header, then the code, which
EXOS loads to `&0100`), and `build/frak.img`, a 720K EXDOS disk (FAT12) holding it, made by
`tools/mkdisk.py`. `build/frak.sym` has the program's symbols, for the tests.

## Testing headlessly

`tools/emu` runs the program on an emulated Enterprise 128, headless and as fast as it can, as
the CPC version's harness does: `harness.mjs` writes a list of steps, runs the emulator, and
returns what the steps printed and the screenshots. As well as the CPC harness's steps (on the
Z80's 64K as it's paged), steps can read, write, fill, load and dump any segment directly
(`speek`, `spoke`, `fill`, `sload`, `sdump`), without paging anything. There are two emulators,
which take the same steps:

- **`ephl`** (the default): [ep128emu](https://github.com/istvan-v/ep128emu)'s emulation, with
  no window and no sound (`tools/ephl`). ep128emu is the Enterprise emulator the Enterprise's
  own developers use: it emulates the wait states the Z80 gets in video RAM, and Nick's whole
  312-line frame, so its frame rates and timings are the real machine's. `tools/ephl/build.sh`
  fetches ep128emu's source at a fixed commit, compiles only its emulation, and links it with
  `ephl.cpp` into `build/ephl`. ep128emu is under the GNU GPL (version 2), and so is `ephl.cpp`;
  ep128emu's source isn't kept in this repository.
- **MAME**'s `ep128` driver with an EXDOS card (`EP_EMU=mame`), running `tools/emu/steps.lua`.
  It doesn't emulate the wait states, and its screen is only 280 lines, starting where an LPB
  with VINT ends; it's kept as a second opinion.

Both need the Enterprise's ROMs, from a directory named by `EP_ROMS`, as MAME names them.
`tools/ephl/getroms.sh DIRECTORY` fetches ep128emu's ROM package (from `ep128.hu`, as
ep128emu's installer does), unpacks it with `build/unpackroms` and puts the two there. They
aren't the dumps MAME lists, so MAME warns that their checksums are wrong, and runs them anyway.

| File | |
|---|---|
| `ep128/9256ds-0019_enter08-45-a.u2` | EXOS 2.1 and the word processor (32K) |
| `ep64_exdos/exdos13.rom` | EXDOS 1.3 (32K) |

```sh
apt install g++ libsndfile1-dev portaudio19-dev zlib1g-dev
tools/ephl/build.sh
tools/ephl/getroms.sh /path/to/roms
EP_ROMS=/path/to/roms node tools/emu/boot.mjs
EP_EMU=mame EP_ROMS=/path/to/roms node tools/emu/boot.mjs      # (apt install mame)
```

ep128emu starts the machine in a random state, seeded from the clock, as a real Enterprise might
power up; `ephl` seeds it from `EP_SEED` (1 by default) instead, so every run of a test is the
same. Running the tests with other seeds tries other power-up states (and so other timings):

```sh
for s in 1 2 3 4 5; do EP_SEED=$s EP_ROMS=/path/to/roms node tools/emu/screens.mjs; done
```

`connections.mjs` and `logic.mjs` are the CPC version's, and need what they need: the steamfrak
repository alongside this one (`STEAMFRAK=...` otherwise), with its `tools/connections.js` (on its
`ccr-c7940764-hxv6sv` branch) and the GameMaker project alongside that; and the BBC version built,
with jsbeeb installed in `../tools/emu` (`npm install` there). They import the CPC version's Z80
and 6502 interpreters from `../cpc6128/tools/emu`.

`ephl`'s `lines` step says how many lines Nick drew between each of the last 16 vertical syncs
(312 for a whole frame).

Until the disk starts the program by itself (phase 8), the harness waits for EXOS to start up
(`EP_EXOS_FRAMES`, 400 frames by default), puts `FRAK.COM` at `&0100` in the segment at page 0,
where EXOS would load it, and jumps to it.

```sh
EP_ROMS=/path/to/roms node tools/emu/screens.mjs       # phase 1: every pixel, scrolled and flipped (ephl only)
EP_ROMS=/path/to/roms node tools/emu/machine.mjs       # phase 1: ticks, segments, keys
EP_ROMS=/path/to/roms node tools/emu/unpack.mjs        # phase 2: the Z80 unpacker
EP_ROMS=/path/to/roms node tools/emu/plot.mjs [seed]   # phase 3: the plotter, byte for byte
EP_ROMS=/path/to/roms node tools/emu/levels.mjs        # phase 4: all 55 levels' tables, caches and windows
EP_ROMS=/path/to/roms node tools/emu/connections.mjs   # phase 5: Trogg moves as in GameMaker
EP_ROMS=/path/to/roms node tools/emu/logic.mjs         # phase 5: the logic, tick for tick, against the BBC version's
EP_ROMS=/path/to/roms node tools/emu/frames.mjs        # phase 6: every frame drawn, byte for byte
EP_ROMS=/path/to/roms node tools/emu/fps.mjs           # phase 6: the frame rate on every level
EP_ROMS=/path/to/roms node tools/emu/front.mjs         # phase 7: the attract screen, menus, a level won, the records
```

`boot.mjs` is phase 0's test: the program must take the machine over, set `ready` and idle in
its own code. It prints the segments EXOS ran it with and the ones it gave out, which decides
where the program's data can be loaded.
