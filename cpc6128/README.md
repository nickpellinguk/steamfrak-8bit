# Frak! for the Amstrad CPC 6128

A port of the BBC Master version (in the rest of this repository) to an unmodified Amstrad CPC
6128, in Z80 assembly. It follows the BBC code routine by routine and reuses its converter, data
and tests. Levels that scroll sideways use a 256x256 screen, levels that scroll up and down
320x200, and both are double-buffered.

**Status: phase 6 of 9 done** (the game plays, with its HUD and level-complete screen; the
level-complete screen's text comes with the front end). The program loads the graphics, the levels and the game's logic, takes the machine
over from the firmware, and has the BBC version's plotter, draw log and compiled meanie, its
level loader and background, its game logic (the keys and typed commands, Trogg, the yoyo, the
moving platforms and meanies, balloons and daggers, collisions and checkpoints), and its frame
loop, scrolling and drawing, ported to the CPC. The test harness's command 13 plays from a
level; there's no front end yet. The tests
check every byte drawn, Trogg's movement against GameMaker's, and the game logic against the
BBC version's, tick for tick.

| Phase | | Test that must pass |
| --- | --- | --- |
| 1 | Toolchain and harness | `screens.mjs`: both screen modes flip at vsync — **passes** |
| 2 | Machine layer: interrupts and ticks, bank paging, keyboard, screen tables | `machine.mjs`: 50 ticks a second, every key, the extra banks — **passes** |
| 3 | Plotter and drawing | `plot.mjs`: every image, clipped, saved and put back, the yoyo string, the compiled meanie, matching byte for byte — **passes** |
| 4 | Levels and background | `levels.mjs`: all 55 levels' tables, background caches and repainted windows match the converter — **passes** |
| 5 | Game logic | `connections.mjs`: Trogg moves as in GameMaker on all 55 levels; `logic.mjs`: the game logic does what the BBC version's does, tick for tick — **both pass** |
| 6 | Main loop and scrolling | `frames.mjs`: every frame drawn is what the game's state says it should be — **passes**; `fps.mjs`: the frame rates below |
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
CPC_ROMS=/path/to/roms node tools/emu/frames.mjs [room ...] [--frames=N] [--seed=N]
CPC_ROMS=/path/to/roms node tools/emu/fps.mjs [room ...]
```

Steps a test can give (`steps.lua`): `wait` frames, `waitfor` a byte to have a value, `type`
text, `poke` and `peek` the base 64K, `load` a file into it and `dump` some of it to a file,
`bank` and `bankpoke` (an extra bank, by paging it in and then back), `key` (press or let go of
a key by its row and bit in the keyboard matrix), `time` (the emulated clock), `regs` (the
Z80's PC and SP), and `snap` (a screenshot). Every test starts by waiting for the program to
set `ready`, once it has loaded and taken the machine over.

`frames.mjs` is phase 6's test: every frame the game draws is what it should be. The program
plays levels with `t_lock` set, so it holds each frame once it's drawn, before showing it: the
buffer is copied with the low RAM and the logic bank, keys are pressed (random but purposeful,
as in `logic.mjs`), and the game goes on, two ticks a frame. Each frame must be, byte for byte,
what a reference renderer (`render.mjs`, written from the data formats, not from the Z80) makes
of the game's state: the window's background from the converter's background data, the scenery
not yet collected, each moving platform and meanie where the buffer says it drew it, then the
buffer's draw log in order (balloons, daggers, meanies flying off, the yoyo and its string,
springs and movable platforms' yellow lines, Trogg, the timer and rating, the FRAK! bubble); or,
once the level is complete, its screen. So anything left behind, erased wrongly, drawn in the wrong place or
not repainted shows up. Eleven levels, both kinds, are each played twice for 300 frames, the
second time with Trogg unable to die so that he gets about, and finishing the level a second
or so in (with a short wait), so that the level-complete screen and the next level are drawn
too: all 6,600 frames are right, with the view scrolling, the yoyo out, moving platforms and
meanies, balloons and daggers, things collected, deaths and level-complete screens among them.

`fps.mjs` measures the frame rate on every level, with Trogg unable to die: standing still for
10 seconds (the meanies, balloons and daggers still moving), then walking right for 10.

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
and `cpuz80.mjs`) with the same keys pressed, the same difficulty and the same random seed. The
keys are random but mostly purposeful: walking on, jumping, climbing, throwing the yoyo, and
typing commands (a count, then L, R, U, D, J or Y). They're pressed on both keyboards: the CPC's
key matrix is set as its interrupt handler sets it, and the BBC version's two key readers read a
table instead of the keyboard. Its interpreter follows ROMSEL, so its typed commands run in its
bank 5, as on a BBC. After every tick
everything the logic keeps must be the same: Trogg, the yoyo, the platforms, the slow sprites,
the balloons, daggers and meanies flying off, what's been collected, the timers, the random
number and the checkpoint; a death goes back to the checkpoint, and finishing the level starts
it again. Each level is run twice, the second time with Trogg unable to die and two keys short
of finishing, so that he gets about. The whole run (5,000 ticks a run, about 9 minutes) covers
about 2,600 typed commands, 1,400 deaths, 60 keys, 40 meanies knocked off and 25 platforms
carried, checkpoints and finished levels: all 110 runs match.

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
| `&0040-&29FF` | the code and its variables |
| `&2A00-&3D3F` | the line and row tables, the draw log's two save areas (1K each, the first also where a level is unpacked from), the level tables |
| `&3F00-&3FFF` | the stack |
| `&4000-&7FFF` | the base RAM here: the levels, packed (12K, the BBC version's `PACK` as it is). The window the extra banks are paged into: bank 0 the graphics (as the BBC's sideways RAM bank 4, sprites and code tables), bank 1 the compiled meanie, bank 2 the game's logic, frame loop and their variables (as the BBC's bank 6), bank 3 the background cache (as the BBC's bank 7), with the two buffers' slow save areas above it, from `&6A00` and `&7500` |
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

A port of the BBC version's `game_tick` and everything it does: the keys (Z or cursor left, X
or right, O or up, K or down, P or Space for the yoyo, Esc for the menus) with their debounces,
and the typed commands (`src/commands.asm`, the BBC version's `commands.asm`); Trogg's movement (below) and riding platforms, the yoyo and the
platforms it moves, the moving platforms, Scrubblies (only while they're relevant to Trogg),
Poglets and Hooters, balloons and daggers, meanies knocked flying, collisions by the BBC
version's spans, checkpoints, and the start and end of a level. The bank starts with the
collision spans (`gfx.py` rebases the BBC version's tables to them), then the code and its
variables. The slow sprites' state while the level plays is in records of their own (IY), one
for each of the level's slow sprite records (IX); the moving objects are records too. The sound
it asks for goes in the BBC version's request bytes, for phase 7's player.

### Playing (`src/play.asm`)

A port of the BBC version's frame loop, in the logic bank. Each frame, in the buffer that isn't
on show: erase everything drawn there last time (`restore_log`); scroll, repainting the columns
(or rows) that come into view, and repaint collected things' columns (`do_pending`); bring the
moving platforms and meanies up to date (`draw_slow`: each buffer remembers where it drew each
one, erases only those that moved, from the background cache, and draws again those that moved
or were painted over, in order); then draw the moving things into the draw log. Then show it
once two vertical syncs have passed since the last flip (the CRTC's start address, R12 and R13:
the buffer and the scroll position), and run a tick of game logic for each vertical sync since.
A death goes back to the checkpoint and redraws both buffers; finishing a level loads the next.

The CRTC starts the screen on a word (2 bytes), so sideways the view moves 8 pixels at a time
where the BBC version's moves 4, scrolling in bands as the BBC version does (it stays put while
Trogg is between 96 and 160 pixels across the 256-pixel window; up and down, while his feet are
between 72 and 136 lines down the 200-line one). For the same reason the view's sideways
position is always even, so on a level whose width in byte columns is odd, the last 4 pixels on
the right never come into view.

**The HUD.** The timer (top left) is drawn as the BBC version draws it: an image made each
second from the font (the CPC's own, in its lower ROM at `&3800`: `copy_font` copies the digits
and the colon to the logic bank at start-up), whose bytes are nibbles of 4 black pixels, which
the plotter looks up in two tables of its own (in spare pages of the graphics bank) rather than
the 5-pixel code tables. The rating is at the bottom right of the window. The springs on moving
bouncy platforms and the yellow line under platforms Trogg can move are drawn each frame, as in
the BBC version. The level-complete screen is drawn once in each buffer: Trogg (and his trophy)
on the background colour; its text (the time, the gems and the medal) comes with the front end.

**Speed.** The table below is `fps.mjs`'s. The game logic runs at 50 ticks a second, a tick for
each vertical sync since the last frame, up to 8 a frame (the BBC version's limit is 4: the CPC
draws more slowly, so 8 keeps the game at its speed down to 6.25 frames a second). The CPC's
Z80, with the gate array's wait states, does about as much work in a frame as the BBC's 6502,
and the game logic still takes more instructions a tick than the BBC version's (it's at about
1.6 times, from 3 times at first: `logic.mjs` reports both), so the frame rates are well below
the BBC version's for now; making them faster is the next job.

<details><summary>Frame rates on every level (Easy)</summary>

| Level | Window | Frames a second, standing | Walking right |
| --- | --- | --- | --- |
| 0 | 256x256 | 10.2 | 9.0 |
| A_1 | 256x256 | 9.3 | 8.9 |
| A_2 | 256x256 | 8.7 | 8.8 |
| A_3 | 256x256 | 9.4 | 10.0 |
| A_4 | 256x256 | 9.2 | 9.0 |
| A_5 | 256x256 | 9.1 | 8.1 |
| A_6 | 256x256 | 7.5 | 8.1 |
| A_7 | 256x256 | 8.6 | 9.3 |
| A_8 | 256x256 | 10.0 | 10.5 |
| A_9 | 256x256 | 6.2 | 4.5 |
| B_1 | 256x256 | 4.1 | 3.6 |
| B_2 | 256x256 | 4.8 | 4.9 |
| B_3 | 256x256 | 5.1 | 4.3 |
| B_4 | 256x256 | 5.1 | 4.2 |
| B_5 | 256x256 | 5.2 | 4.6 |
| B_6 | 256x256 | 4.4 | 4.4 |
| B_7 | 256x256 | 5.4 | 4.8 |
| B_8 | 256x256 | 4.3 | 3.6 |
| B_9 | 256x256 | 4.3 | 3.9 |
| C_1 | 320x200 | 3.8 | 4.4 |
| C_2 | 320x200 | 4.4 | 2.7 |
| C_3 | 320x200 | 4.2 | 3.6 |
| C_4 | 320x200 | 3.9 | 5.4 |
| C_5 | 320x200 | 4.2 | 3.8 |
| C_6 | 320x200 | 4.0 | 3.0 |
| C_7 | 320x200 | 4.7 | 3.8 |
| C_8 | 320x200 | 5.8 | 5.2 |
| C_9 | 320x200 | 4.9 | 3.5 |
| D_1 | 256x256 | 6.5 | 6.4 |
| D_2 | 320x200 | 4.7 | 3.3 |
| D_3 | 256x256 | 3.9 | 3.9 |
| D_4 | 256x256 | 5.4 | 5.5 |
| D_5 | 320x200 | 3.9 | 3.8 |
| D_6 | 256x256 | 5.6 | 5.5 |
| D_7 | 320x200 | 4.8 | 3.0 |
| D_8 | 320x200 | 3.7 | 3.3 |
| D_9 | 320x200 | 3.7 | 3.7 |
| E_1 | 256x256 | 8.2 | 6.5 |
| E_2 | 256x256 | 7.5 | 7.7 |
| E_3 | 256x256 | 5.5 | 5.5 |
| E_4 | 256x256 | 9.3 | 8.6 |
| E_5 | 320x200 | 5.6 | 3.9 |
| E_6 | 320x200 | 4.9 | 4.8 |
| E_7 | 320x200 | 7.2 | 6.9 |
| E_8 | 256x256 | 6.2 | 5.6 |
| E_9 | 256x256 | 6.3 | 6.5 |
| F_1 | 256x256 | 5.4 | 5.6 |
| F_2 | 256x256 | 7.4 | 6.0 |
| F_3 | 256x256 | 6.5 | 6.9 |
| F_4 | 256x256 | 5.4 | 6.9 |
| F_5 | 320x200 | 6.0 | 4.4 |
| F_6 | 320x200 | 5.1 | 4.9 |
| F_7 | 256x256 | 5.7 | 5.7 |
| F_8 | 256x256 | 9.0 | 6.1 |
| F_9 | 256x256 | 6.6 | 6.3 |
| average | | 6.0 | 5.6 |
| average | 256x256 | 6.7 | 6.4 |
| average | 320x200 | 4.7 | 4.1 |

</details>

The yoyo string's ends are compared signed: at the left edge of a level the yoyo can be a
pixel or two left of it, which made `hline`, comparing them unsigned, draw the string right
across the window for a frame (in the BBC version too, which now compares them signed as well).

The palette is the BBC version's (the level's background colour, yellow, magenta and black),
but a Mode 1 pixel's two bits are the other way round in a CPC byte from a BBC one, so the
BBC's colour 1 (yellow) is the CPC's pen 2, and its colour 2 (magenta) pen 1.

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
