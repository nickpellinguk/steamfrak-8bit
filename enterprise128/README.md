# Frak! for the Enterprise 128

A port of the CPC 6128 version ([`../cpc6128`](../cpc6128/README.md)), which is itself a Z80 port
of the BBC Master version, to the Enterprise 128. The plan, phase by phase, is in
[`PLAN.md`](PLAN.md).

**Status: the first milestone, but for playing it on a real machine.** The whole game runs
from its disk image: the attract screen, the menus, all 55 levels, the level-complete screen and
the records, with no music yet. The plan, phase by phase, and what was found on the way, is in
[`PLAN.md`](PLAN.md).

## Playing it

You need an Enterprise 128 (or 64: not tried) with EXDOS and a disk drive, and the BASIC
cartridge. Write `build/frak.img` (a 720K, 3.5-inch, double-sided MS-DOS disk: `dd` it to a
floppy, or copy its five files, `START`, `GFX.BIN`, `LOGIC.BIN`, `LOADER.BIN` and `TOP.BIN`, onto
one) and put it in drive A. Switch on, press a key at the Enterprise logo, and at BASIC's prompt
type

    LOAD

and press ENTER: `START` loads, loads the rest, and the game starts. Keys: Z X O K or the
joystick (the cursor keys) to move, Space or P for the yoyo, Escape for the menus; M and S switch
the music and sound effects (there's no sound yet).

The game runs at 50 ticks a second whatever the drawing takes, as the Atari version does: each
frame drawn runs a tick of logic for every vertical sync since the last (up to 12), and the view
keeps up with Trogg however few frames there are (see [`PLAN.md`](PLAN.md), "Keeping the game's
speed").

## In a browser

`build/frak-ep128.html` is an Enterprise 128 in one web page: [ep128emu](https://github.com/istvan-v/ep128emu)'s
emulation (GPL-2.0), as `ephl` runs it, compiled to WebAssembly, with the game built in. Open it in
a browser, locally or from any web host. It needs none of the Enterprise's ROMs: the page starts
the machine as EXOS and EXDOS would leave it once they'd loaded the game from its disk, as the
test harness's quick start does, and the program takes the machine over from there as it always
does. The page puts the program (`START`) at `&0100` in segment `&F8` and its four files where its
`load_files` would put them, a stand-in for EXOS's calls at `RST &30` (the program makes only four:
open, read a block and close a file, which it answers "done", the files being there already, and
allocate a segment, which gives out `&F9`-`&FE` as EXOS does), and a font in video RAM where EXOS
keeps its own, for the front end's text: Daniel Hepper's public-domain
[font8x8](https://github.com/dhepper/font8x8), not EXOS's. There's no sound (the game has none
yet). As for the Atari version's page, not inside a host whose security policy forbids compiling
WebAssembly (claude.ai's artifact viewer, for one): there the page says so instead.

    web/build_emulator.sh            # build/ep.js (needs emscripten: 3.1.6, Ubuntu's, was used)
    python3 web/build_page.py        # build/frak-ep128.html (after ./build.sh)
    node tools/emu/web.mjs           # the page in headless Chromium (Playwright): through the menus into a level

| File | |
| --- | --- |
| `web/web.cpp` | The emulator's side: switch on with no ROMs, load the files, run a frame, keys, and hand over the screen (768 x 288 palette indices, as `ephl`'s) and palette |
| `web/page.html` | The page: the canvas (shown at 4:3) at 50 frames a second, the keys (each held at least 3 frames, so a quick tap isn't missed), Reset and Pause |
| `web/build_emulator.sh` | ep128emu's emulation (at `ephl`'s commit) and `web.cpp` through emscripten into one `ep.js` with the WebAssembly inside |
| `web/build_page.py` | `page.html` with `ep.js`, the game's files (from `build/disk`, each with its segment and offset, from `build/frak.sym`) and the font put in |
| `web/font.py` | The font, as EXOS keeps its own in video RAM |
| `web/audio.cpp`, `web/stubs/` | Stand-ins for ep128emu's sound output, and libsndfile's and PortAudio's headers, which its emulation includes (the page plays no sound and reads no sound files) |
| `tools/ephl/headless.hpp` | The display both `ephl` and the page use: Nick's lines decoded into palette indices |

Building it found one thing ep128emu assumes: its Z80 lays its register pairs out low byte
first only on x86 and ARM, and high byte first on anything else, WebAssembly included (which is
little-endian), so `build_emulator.sh` defines `CPC_LSB_FIRST`. Without it, `IN A,(C)` reads the
port in B, and the game never gets past waiting for its first vertical sync.

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
EXOS loads to `&0100`), and `build/frak.img`, a 720K EXDOS disk (FAT12) holding the program, as `START`, and the four files
it loads (`GFX.BIN`, `LOGIC.BIN`, `LOADER.BIN`, `TOP.BIN`), made by `tools/mkdisk.py`. `build/frak.sym` has the program's symbols, for the tests.

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

For most tests the harness waits for EXOS to start up (`EP_EXOS_FRAMES`, 400 frames by default),
puts `FRAK.COM` at `&0100` in the segment at page 0, where EXOS would load it, and jumps to it,
saying it will put the program's files in their segments itself (`t_noload`): that's quicker
than the disk. `disk.mjs` runs the disk as a real machine would.

```sh
EP_ROMS=/path/to/roms node tools/emu/screens.mjs       # phase 1: every pixel, scrolled and flipped (ephl only)
EP_ROMS=/path/to/roms node tools/emu/machine.mjs       # phase 1: ticks, segments, keys
EP_ROMS=/path/to/roms node tools/emu/unpack.mjs        # phase 2: the Z80 unpacker
EP_ROMS=/path/to/roms node tools/emu/plot.mjs [seed]   # phase 3: the plotter, byte for byte
EP_ROMS=/path/to/roms node tools/emu/levels.mjs        # phase 4: all 55 levels' tables, caches and windows
EP_ROMS=/path/to/roms node tools/emu/connections.mjs   # phase 5: Trogg moves as in GameMaker
EP_ROMS=/path/to/roms node tools/emu/logic.mjs         # phase 5: the logic, tick for tick, against the BBC version's
EP_ROMS=/path/to/roms node tools/emu/frames.mjs        # phase 6: every frame drawn, byte for byte (--ticks=N: N ticks a frame)
EP_ROMS=/path/to/roms node tools/emu/fps.mjs           # phase 6: the frame rate, and the game's speed, on every level
EP_ROMS=/path/to/roms node tools/emu/front.mjs         # phase 7: the attract screen, menus, a level won, the records
EP_ROMS=/path/to/roms node tools/emu/disk.mjs          # phase 8: the disk, LOADed from BASIC (EP_COLD=1: from garbage)
EP_ROMS=/path/to/roms node tools/emu/profile.mjs       # where the time goes, playing (ephl's profile step)
node tools/emu/web.mjs                                 # the web page, in headless Chromium (see "In a browser")
```

`boot.mjs` is phase 0's test: the program must take the machine over, set `ready` and idle in
its own code. It prints the segments EXOS ran it with and the ones it gave out, which decides
where the program's data can be loaded.
