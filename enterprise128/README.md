# Frak! for the Enterprise 128

A port of the CPC 6128 version ([`../cpc6128`](../cpc6128/README.md)), which is itself a Z80 port
of the BBC Master version, to the Enterprise 128. The plan, phase by phase, is in
[`PLAN.md`](PLAN.md).

**Status: phase 0** (the toolchain and the test harness). The program loads, asks EXOS which
RAM segments it will give out, takes the machine over and tells the test harness it's ready.

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

`tools/emu` runs the program on [MAME](https://www.mamedev.org/)'s `ep128` driver with an EXDOS
card, headless and unthrottled, as the CPC version's harness does: `mame.mjs` writes a list of
steps for `steps.lua`, runs MAME, and returns what they printed and the screenshots. As well as
the CPC harness's steps (on the Z80's 64K as it's paged), steps can read, write, fill, load and
dump any segment directly (`speek`, `spoke`, `fill`, `sload`, `sdump`), through Dave's own
address space, without paging anything.

MAME needs the Enterprise's ROMs, from a directory named by `EP_ROMS`:

| File | |
|---|---|
| `ep128/9256ds-0019_enter08-45-a.u2` | EXOS 2.1 and the word processor (32K) |
| `ep64_exdos/exdos13.rom` | EXDOS 1.3 (32K) |

```sh
apt install mame
EP_ROMS=/path/to/roms node tools/emu/boot.mjs
```

Until the disk starts the program by itself (phase 8), the harness waits for EXOS to start up
(`EP_EXOS_FRAMES`, 400 frames by default), puts `FRAK.COM` at `&0100` in the segment at page 0,
where EXOS would load it, and jumps to it.

`boot.mjs` is phase 0's test: the program must take the machine over, set `ready` and idle in
its own code. It prints the segments EXOS ran it with and the ones it gave out, which decides
where the program's data can be loaded.
