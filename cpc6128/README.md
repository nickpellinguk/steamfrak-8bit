# Frak! for the Amstrad CPC 6128

A port of the BBC Master version (in the rest of this repository) to an unmodified Amstrad CPC
6128, in Z80 assembly. It follows the BBC code routine by routine and reuses its converter, data
and tests. Levels that scroll sideways use a 256x256 screen, levels that scroll up and down
320x200, and both are double-buffered.

**Status: phase 5 of 9** (the game logic, all but the typed commands). The program so far
loads the graphics, the levels and the game's logic, takes the machine over from the firmware,
and has the BBC version's plotter, draw log, yoyo string and compiled meanie, its level loader,
background unroller and repainting, and its game logic (Trogg, the yoyo, the moving platforms
and meanies, balloons and daggers, collisions and checkpoints), ported to the CPC. The tests
check every byte drawn, Trogg's movement against GameMaker's, and the game logic against the
BBC version's, tick for tick.

| Phase | | Test that must pass |
| --- | --- | --- |
| 1 | Toolchain and harness | `screens.mjs`: both screen modes flip at vsync — **passes** |
| 2 | Machine layer: interrupts and ticks, bank paging, keyboard, screen tables | `machine.mjs`: 50 ticks a second, every key, the extra banks — **passes** |
| 3 | Plotter and drawing | `plot.mjs`: every image, clipped, saved and put back, the yoyo string, the compiled meanie, matching byte for byte — **passes** |
| 4 | Levels and background | `levels.mjs`: all 55 levels' tables, background caches and repainted windows match the converter — **passes** |
| 5 | Game logic | `connections.mjs`: Trogg moves as in GameMaker on all 55 levels; `logic.mjs`: the game logic does what the BBC version's does, tick for tick — **both pass** (the typed commands to come) |
| 6 | Main loop and scrolling | levels play, with no flicker |
| 7 | Sound (AY-3-8912) | the notes match the web version's player |
| 8 | Front end | menus, a level, then the next level |
| 9 | Release | plays on a real 6128 |

## Building

You need [RASM](https://github.com/EdouardBERGE/rasm), built from its source (v3.3.1 is the
version used), and the BBC version built first: the CPC version uses its graphics.

```sh
gcc -O2 -DNO_3RD_PARTIES -o rasm rasm.c -lm
(cd .. && BEEBASM=/path/to/beebasm ./build.sh)
RASM=/path/to/rasm ./build.sh
```

This writes `build/frak.dsk` (and `build/frak.sym`, the symbols, for the tests). In an emulator,
choose a CPC 6128, insert the disc and type `RUN"FRAK.BIN`.

(RASM works out expressions in floating point and rounds them, so `label/256` of an address
that isn't page-aligned can come out one too high: the source takes high bytes with `>>8`.)

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
CPC_ROMS=/path/to/roms node tools/emu/machine.mjs
CPC_ROMS=/path/to/roms node tools/emu/plot.mjs [seed]
CPC_ROMS=/path/to/roms node tools/emu/levels.mjs [room ...]
CPC_ROMS=/path/to/roms node tools/emu/connections.mjs [room ...] [--detail]
CPC_ROMS=/path/to/roms node tools/emu/logic.mjs [room ...] [--ticks=N] [--seed=N]
```

Steps a test can give (`steps.lua`): `wait` frames, `waitfor` a byte to have a value, `type`
text, `poke` and `peek` the base 64K, `load` a file into it and `dump` some of it to a file,
`bank` and `bankpoke` (an extra bank, by paging it in and then back), `key` (press or let go of
a key by its row and bit in the keyboard matrix), `time` (the emulated clock), `regs` (the
Z80's PC and SP), and `snap` (a screenshot). Every test starts by waiting for the program to
set `ready`, once it has loaded and taken the machine over.

`connections.mjs` is phase 5's test, the CPC version of the BBC version's `connections8.mjs`.
It needs the steamfrak repository alongside this one (`STEAMFRAK` names it otherwise), for
its `tools/connections.js`: a port of the original's GraphFind search, and a transcription of
the original's TroggStanding, TroggFalling, TroggClimbing, PlatformFind and LadderFind run on
the GameMaker project's rooms. The program loads each level on MAME and the low RAM and the
logic bank are copied; then the Z80's `trogg_standing`, `trogg_falling` and `trogg_climbing` run on
a small Z80 interpreter (`cpuz80.mjs`) against that copy, from every start the search asks
about, and every way Trogg can get from one platform or ladder to another is compared with
GameMaker's. All 55 levels match, but for D_9's ladder at x = 48.5, which the converter rounds
down a pixel, as it does for the BBC version.

`logic.mjs` is phase 5's other test: the game logic against the BBC version's, tick for tick.
It needs the BBC version built (`../build.sh` writes its symbols to `build/labels.txt`). For
each level, both versions' memory is copied once the level has loaded (the BBC version's from
jsbeeb), both start the level, and both run `game_tick` on the two interpreters (`cpu6502.mjs`
and `cpuz80.mjs`) with the same keys held, random but mostly purposeful (walking on, jumping,
climbing, throwing the yoyo), the same difficulty and the same random seed. After every tick
everything the logic keeps must be the same: Trogg, the yoyo, the platforms, the slow sprites,
the balloons, daggers and meanies flying off, what's been collected, the timers, the random
number and the checkpoint; a death goes back to the checkpoint, and finishing the level starts
it again. Each level is run twice, the second time with Trogg unable to die and two keys short
of finishing, so that he gets about. The whole run (5,000 ticks a run, about 6 minutes) covers
about 1,600 deaths, 70 keys, 35 meanies knocked off and 25 platforms carried, checkpoints and
finished levels: all 110 runs match.

`levels.mjs` is phase 4's test. For every level it has the program load it, then compares,
with what the BBC version's converter expects (`../build/levels.json`, as its
`check_levels.mjs` does): every table the loader built; the background cache (line tables,
cell dictionary and lines, read out of bank 3); and the whole window repainted from the cache,
byte for byte, against the screen the converter's background bytes describe.

`plot.mjs` is phase 3's test, about 1,600 cases a run (`seed` picks them). Each loads the same
random background into screen buffer 1, has the program draw something through its command
mailbox (`t_cmd`), and compares all 16K with a reference renderer written from the data format
(pixel by pixel, not from the Z80): every image at every shift, in both modes; random images,
places and clip windows (all four edges, and the 2K wrap); `PM_SAVE` and `restore_saved`; the
yoyo string, black and yellow; the compiled meanies drawn by `plot_slow` (and the compiled code
used exactly where it should be); and a frame's worth of the draw log undone by `restore_log`.
It also checks that nothing wrote over the program's code.

`machine.mjs` is phase 2's test. It counts game ticks against the emulated clock over 20
seconds (1,000 in 19.968 seconds: a CPC frame is 312 lines of 64µs, so 50.08 a second); checks
the program's own test of the extra 64K and reads each bank back itself (a different signature
at `&4000` and `&7FFF` in the base RAM and each of the four extra banks); and presses each of
the keyboard's 79 keys in turn, checking that the program sees that key and no other, and that
the `KEY_` constants agree with what MAME calls each key.

`screens.mjs` is phase 1's test. For each mode it measures the test card's white outline in
the screenshots (MAME draws a Mode 1 pixel 2 pixels wide, so 256x256 is 512x256 there and
320x200 is 640x200, centred and all on show), then swaps the buffers every frame for 10 frames
and checks that each frame shows one buffer whole and that they alternate.

## How it works (so far)

### Memory map

| Address | Contents |
|---|---|
| `&0000-&003F` | Z80 restart vectors; the interrupt handler's jump at `&0038` |
| `&0040-&28FF` | the code and its variables |
| `&2900-&3C3F` | the line and row tables, the draw log's two save areas (1K each, the first also where a level is unpacked from), the level tables |
| `&3F00-&3FFF` | the stack |
| `&4000-&7FFF` | the base RAM here: the levels, packed (12K, the BBC version's `PACK` as it is). The window the extra banks are paged into: bank 0 the graphics (as the BBC's sideways RAM bank 4, sprites and code tables), bank 1 the compiled meanie, bank 2 the game's logic and its variables (as the BBC's bank 6), bank 3 the background cache (as the BBC's bank 7), with the slow save areas above it from `&6A00` |
| `&8000-&BFFF` | while a level loads, the unroller's and the meanie compiler's workings |
| `&8000-&BFFF` | screen buffer 0 |
| `&C000-&FFFF` | screen buffer 1 |

The code sits below `&4000` so that it stays visible whichever extra bank is paged in at
`&4000-&7FFF`, as the BBC version's sits in main RAM below its sideways RAM. The game's logic
is in extra bank 2 (`LOGIC.BIN`), as the BBC version's is in its bank 6, and runs with that
bank paged in: whatever it calls in the low RAM that pages another bank in (the plotter, say)
puts bank 2 back before it returns.

### The machine (`src/machine.asm`)

`machine_init` turns both ROMs off (so `&0000-&3FFF` and `&C000-&FFFF` read RAM), pages in the
base 64K, and puts a jump to the program's own interrupt handler at `&0038` (interrupt mode 1).

**Interrupts and ticks.** The gate array interrupts 300 times a second; the one 2 lines into
vertical sync is the only one that sees PPI port B's bit 0 set. At that one the handler counts
the vertical sync (`vsyncs`) and reads the keyboard. The main loop runs a game tick for each
vertical sync since it last looked, so the game runs at 50 ticks a second however long a frame
takes to draw, as the BBC version does.

**Bank paging.** `bank_select` pages a RAM configuration in: `RAM_BASE`, or `RAM_BANK + n` for
extra bank n (0-3) at `&4000-&7FFF`. It keeps a copy in `ga_ram`, as the BBC version keeps
`ROMSEL_COPY`, so that anything that pages another bank in (the music player, later) can put
the right one back. `bank_test` checks all five configurations at start-up (`bank_errors`).

**The keyboard.** The CPC reads its keyboard matrix (10 rows of 8 keys) through the sound
chip's port A, with the row on PPI port C. Because the music player will drive the sound chip
from the interrupt handler too, the handler reads all 10 rows there, once a frame, into
`keys[]` (a bit set while a key is down). `key_pressed` takes a key as `row * 8 + bit`, the
`KEY_` constants, like the BBC version's INKEY numbers, and returns 1 if it's down.

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

### Graphics (`tools/gfx.py`)

Every coded sprite, and the code tables, are in the BBC version's sideways RAM bank 4 (its
converter's `build/GFX4`, 16K at `&8000`). That becomes the CPC's extra bank 0 at `&4000`,
unchanged; `gfx.py` only rebases the image directory (`src/gen/images.asm`: each image's size,
origin and, for each shift, where its data is) and writes `build/images.json` for the tests.
Images and the 5-pixel codes are as in the BBC version: a byte column is the image's height in
codes, each looked up in the code tables (`&7C00-&7FFF`) for its shift's half. The CPC's Mode 1
packs pixels into bytes exactly as the BBC's MODE 1 does, so the tables' bytes are the screen's.

The loader runs while the firmware still does: it restarts AMSDOS (`RUN"` resets the firmware
to the cassette, so it calls `KL INIT BACK` for ROM 7), then loads `GFX.BIN` into bank 0 with the
firmware's `CAS IN` routines, and only then takes the machine over.

### The plotter (`src/plot.asm`)

A port of the BBC version's `plot`, column routines, `restore_saved`, `hline` and draw log. A
level's byte column `c` and line `y` are always at the same place in a screen buffer:

    page + (y MOD 8) * &800 + ((y / 8) * width + c) MOD &800

(`rowoff[y / 8]` holds the `(y / 8) * width MOD &800`). The CRTC wraps each line's 2K block the
same way, so scrolling will just move the CRTC's start over it, as the BBC version scrolls over
a screen that wraps at `&8000`. The plotter walks each byte column down: the next line is
`&800` on; past a character row's 8th line, the next row's first line is `width` on from its
first, wrapping within the 2K (`next_row`: back `&4000`, on `width`, and clear address bit 11).
In the column routines BC is the screen address, DE the image data, H the code tables' page
(`and (hl)` the mask, then `or (hl)` the pixels from the page before), IXL the lines left, and
the save record goes through HL' in the other register set.

A save record is the number of columns and rows, then each column's screen address and saved
bytes, so `restore_saved` puts the background back without redoing the image's geometry.
`log_sprite`, `log_line` and `log_sprite7` (whose record is in another bank, for big images such
as meanies flying off) draw things and log them; `restore_log` undoes them, newest first.

### The compiled meanie

As in the BBC version, the level's moving meanie is compiled (`jit_build`, into bank 1) into
code that draws it a line at a time, at shifts 0 and 2, with HL at its first byte and B the
lines left in that character row:

    a solid byte:     LD (HL),pixels
    a partial one:    LD A,(HL) : AND mask : OR pixels : LD (HL),A
    between bytes:    INC HL                      (a line can cross a 256-byte page)
    between lines:    LD DE,&800 - n : ADD HL,DE : DJNZ same : CALL jit_row : .same

and `RET` at the end. `plot_slow` uses it where the meanie is at an even pixel, wholly in the
window, and none of its lines crosses the end of a 2K block, and `plot` everywhere else.

### Levels (`src/level.asm`)

A port of the BBC version's `fetch_level` and `load_level` with `platform_find`,
`ladder_below`, `meanie_settings`, `moving_platform` and its four scans. All the levels are
kept packed in the base RAM at `&4000`: the BBC version's `PACK` (its HAZEL segment, then ANDY's
two) as it is, so `gfx.py` only rebases each level's address. A level is copied to `STAGE` (save
area 0) and unpacked into tables of records (platforms, ladders, things to draw, slow sprites):
IX points at one and `(ix+PLT_YL)` and so on are its fields, which suits the Z80 better than the
BBC version's separate arrays per field.

### The game's logic (`src/logic.asm`)

A port of the BBC version's `game_tick` and everything it does, but for the keyboard (phase 6)
and the typed commands: Trogg's movement (below) and riding platforms, the yoyo and the
platforms it moves, the moving platforms, Scrubblies (only while they're relevant to Trogg),
Poglets and Hooters, balloons and daggers, meanies knocked flying, collisions by the BBC
version's spans, checkpoints, and the start and end of a level. The bank starts with the
collision spans (`gfx.py` rebases the BBC version's tables to them), then the code and its
variables. The slow sprites' state while the level plays is in records of their own (IY), one
for each of the level's slow sprite records (IX); the moving objects are records too. The sound
it asks for goes in the BBC version's request bytes, for phase 7's player.

### Trogg's movement (`src/trogg.asm`)

A port of the BBC version's `trogg_standing`, `trogg_falling` and `trogg_climbing`, with
`ladder_find` (and level.asm's `platform_find`): ports of GameMaker's TroggStanding,
TroggFalling, TroggClimbing, LadderFind and PlatformFind. Trogg's y is in pixels and twentieths
of a pixel, and his y velocity in twentieths of a pixel a tick, as in the BBC version: all the
values the original's y and velocity can take (gravity 0.05, a jump 1.25), as whole numbers. The
comparisons are unsigned where the BBC version's are, so the two always move him the same.

### The background (`src/bg.asm`)

A port of the BBC version's unroller and repainting. The cache in extra bank 3 is in the same
format, at the same offsets, as the BBC version's bank 7: a dictionary of the level's different
character cells (8 lines of one byte column each, so the format doesn't depend on the screen's
layout), and for each line of the level (a byte column of a sideways level, a character row of
an up-and-down one) three bit-masks and the low byte of each non-empty cell's number. While a
level loads, the unroller's hash table, chains and buffers are in screen buffer 0; it pages the
graphics bank in to read the images and the cache bank in to build the dictionary, as the BBC
version pages its banks 4 and 7 in turn. `repaint_column` and `repaint_row` paint from it: down
a column the next cell is a line width on, along a row one byte on, each wrapping within its
line's 2K block.
