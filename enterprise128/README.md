# Frak! for the Enterprise 128

A port of the CPC 6128 version ([`../cpc6128`](../cpc6128/README.md)), which is itself a Z80 port
of the BBC Master version, to the Enterprise 128. The plan, phase by phase, is in
[`PLAN.md`](PLAN.md).

**Status: phase 0** (the toolchain and the test harness). The program loads, asks EXOS which
RAM segments it will give out, takes the machine over and tells the test harness it's ready.
The harness runs it on a headless build of ep128emu (or MAME); running it on the real EXOS and
EXDOS ROMs is still to come.

## Building

You need [RASM](https://github.com/EdouardBERGE/rasm), built from its source (v3.3.1, as for
the CPC version), and Python 3.

```sh
gcc -O2 -DNO_3RD_PARTIES -o rasm rasm.c -lm
RASM=/path/to/rasm ./build.sh
```

That makes `build/FRAK.COM`, an EXOS type 5 program (a 16-byte header, then the code, which
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

Both need the Enterprise's ROMs, from a directory named by `EP_ROMS`, as MAME names them:

| File | |
|---|---|
| `ep128/9256ds-0019_enter08-45-a.u2` | EXOS 2.1 and the word processor (32K) |
| `ep64_exdos/exdos13.rom` | EXDOS 1.3 (32K) |

```sh
apt install g++ libsndfile1-dev portaudio19-dev zlib1g-dev
tools/ephl/build.sh
EP_ROMS=/path/to/roms node tools/emu/boot.mjs
EP_EMU=mame EP_ROMS=/path/to/roms node tools/emu/boot.mjs      # (apt install mame)
```

Until the disk starts the program by itself (phase 8), the harness waits for EXOS to start up
(`EP_EXOS_FRAMES`, 400 frames by default), puts `FRAK.COM` at `&0100` in the segment at page 0,
where EXOS would load it, and jumps to it.

`boot.mjs` is phase 0's test: the program must take the machine over, set `ready` and idle in
its own code. It prints the segments EXOS ran it with and the ones it gave out, which decides
where the program's data can be loaded.
