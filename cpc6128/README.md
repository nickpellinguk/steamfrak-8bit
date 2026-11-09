# Frak! for the Amstrad CPC 6128

A port of the BBC Master version (in the rest of this repository) to an unmodified Amstrad CPC
6128, in Z80 assembly. It follows the BBC code routine by routine and reuses its converter, data
and tests. Levels that scroll sideways use a 256x256 screen, levels that scroll up and down
320x200, and both are double-buffered.

**Status: phase 1 of 9** (the toolchain and the test harness). The program so far takes the
machine over from the firmware, sets up both screen modes, and shows a test card in each of the
two screen buffers in turn, swapping them at vertical sync.

| Phase | | Test that must pass |
| --- | --- | --- |
| 1 | Toolchain and harness | `screens.mjs`: both screen modes flip at vsync — **passes** |
| 2 | Machine layer: interrupts and ticks, bank paging, keyboard, screen tables | 50 ticks a second, every key, both modes |
| 3 | Plotter and drawing | every image matches byte for byte |
| 4 | Levels and background | all 55 levels' tables and backgrounds match the converter |
| 5 | Game logic | Trogg moves exactly as in GameMaker |
| 6 | Main loop and scrolling | levels play, with no flicker |
| 7 | Sound (AY-3-8912) | the notes match the web version's player |
| 8 | Front end | menus, a level, then the next level |
| 9 | Release | plays on a real 6128 |

## Building

You need [RASM](https://github.com/EdouardBERGE/rasm), built from its source (v3.3.1 is the
version used):

```sh
gcc -O2 -DNO_3RD_PARTIES -o rasm rasm.c -lm
RASM=/path/to/rasm ./build.sh
```

This writes `build/frak.dsk` (and `build/frak.sym`, the symbols, for the tests). In an emulator,
choose a CPC 6128, insert the disc and type `RUN"FRAK.BIN`.

## Testing headlessly

`tools/emu` runs the disc on [MAME](https://www.mamedev.org/)'s `cpc6128` driver, headless and
unthrottled (about 20 times real speed): `mame.mjs` writes a list of steps for `steps.lua`
(wait, type, poke, peek, screenshot), runs MAME, and returns what they printed and the
screenshots. MAME needs the CPC 6128's ROMs (Amstrad allows them to be distributed with
emulators; the copies in [Caprice32](https://github.com/ColinPitrat/caprice32)'s `rom`
directory match MAME's checksums): a directory holding `cpc6128/cpc6128.rom` (the OS and BASIC)
and `cpc6128/cpcados.rom` (AMSDOS, Caprice32's `amsdos.rom`).

```sh
apt install mame
CPC_ROMS=/path/to/roms node tools/emu/screens.mjs
```

`screens.mjs` is phase 1's test. For each mode it measures the test card's white outline in
the screenshots (MAME draws a Mode 1 pixel 2 pixels wide, so 256x256 is 512x256 there and
320x200 is 640x200, centred and all on show), then swaps the buffers every frame for 10 frames
and checks that each frame shows one buffer whole and that they alternate.

## How it works (so far)

### Memory map

| Address | Contents |
|---|---|
| `&0000-&003F` | Z80 restart vectors; the interrupt handler's jump at `&0038` |
| `&0040-&3FFF` | the code, its variables and tables, the stack (from `&4000` down) |
| `&4000-&7FFF` | (later: the packed levels, and the window the extra 64K is paged into) |
| `&8000-&BFFF` | screen buffer 0 |
| `&C000-&FFFF` | screen buffer 1 |

The code sits below `&4000` so that it stays visible whichever extra bank is paged in at
`&4000-&7FFF`, as the BBC version's sits in main RAM below its sideways RAM.

### The machine

The program disables interrupts, turns both ROMs off (so `&0000-&3FFF` and `&C000-&FFFF` read
RAM), and puts a jump to its own interrupt handler at `&0038` (interrupt mode 1). The gate array
interrupts 300 times a second; the one 2 lines into vertical sync is the one that sees PPI port
B's bit 0 set, so the handler counts vertical syncs (`vsyncs`).

### The two screen modes

| | Sideways levels | Up-and-down levels |
| --- | --- | --- |
| Picture | 256 x 256 | 320 x 200 |
| Bytes a line | 64 | 80 |
| CRTC R1 x R6 | 32 x 32 | 40 x 25 (the firmware's) |
| R2 / R7 (position) | 42 / 34 | 46 / 30 |

Both are 39 character rows of 8 lines a frame (R4 = 38: 312 lines, 50Hz) and fit a 16K page.
Line y of a buffer is at `(y / 8) * width + (y MOD 8) * &800` (`make_lines` builds a table of
them). A buffer is shown by setting CRTC R12/R13 just after vertical sync; the CRTC takes a new
start address at the start of the next frame, so the swap is always a whole frame.
