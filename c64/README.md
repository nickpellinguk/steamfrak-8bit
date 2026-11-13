# Frak! for the Commodore 64 (experimental)

An experiment in showing Frak's graphics on an unexpanded C64 (and a C128 in C64 mode) at their
own resolution, without doubling the pixels' width. So far it's level A_1 ("FRAK!"), on its way
to being playable ([`PLAN.md`](PLAN.md)): Trogg walks, climbs, jumps and falls to the keys (Z / X,
O / K, or joystick 2), as in the original, and dies and starts again; the Scrubblies, balloons and
daggers are shared out among sprites by a multiplexer. The screen doesn't follow him yet (it's held
at the left: `--scrolldemo` for the old scrolling demo), and there's no yoyo yet.

**Status: demo working in VICE (x64sc, PAL), with a sprite multiplexer; the display an
interrupt a row that stays on time whatever sprites are shown, leaving the main program about
45% of the CPU. With Frak's balloons and daggers the multiplexer is ready for more than 90% of
frames (Hard or Insane), and the scroll waits for it the rest: see the multiplexer's section. Not yet tried on a real machine.**

## The idea

The VIC-II's hi-res character mode gives each 8x8 character two colours. Frak needs four, often
three in one 8x8 area, so the demo uses:

- **Extended Colour Mode (ECM)**: each character's background is one of four colours, picked
  by the top two bits of its screen code (here Frak's cyan, yellow, magenta and black), from a
  set of 64 characters. The foreground comes from colour RAM.
- **4-line FLI**: a bad line forced at line 4 of every character row, which makes the VIC read
  a second screen's codes without starting the character again. Each 8x4 half then has its own
  glyph and its own background: the tops (rows 0-3 of a character) come from one screen, the
  bottoms (rows 4-7) from another. The price is the "FLI bug": the 3 characters at the left of
  every row show garbage. A sprite will cover them later.
- **Two character sets**, switched at the forced bad lines, so a set serves a band: one row's
  bottoms and the next row's tops. Each character holds a top glyph and a bottom glyph, so a
  set holds 64 of each.

The BBC art is redrawn to suit: platforms snapped to the 8x4 grid (8 across, 4 down) with a
black top line, a magenta band, black lattice on yellow for the next 4 lines and on cyan for the
4 below, ending on the grid;
ladders and objects black on cyan, lined up with the 16-pixel platform units. Every 8x8 cell's
foreground came out black, so colour RAM is filled once and never scrolled. The Scrubblies are a
black outline with yellow eyes and teeth in the characters, and a magenta sprite behind each
(expanded both ways, behind the characters, with holes over the eyes and teeth) makes the body.

## Building and testing

    ../build.sh            # the BBC version first: the levels and graphics come from it
    ./build.sh [--run]     # build/frak64.prg, and build/frak64.d64 (packed: see below)

**To play it**: `build/frak64.d64` in VICE (drag it onto the window, or `x64sc build/frak64.d64`),
or on a C64: `LOAD"FRAK64",8` and `RUN`. It's the program packed by
[Exomizer](https://bitbucket.org/magli143/exomizer) (`sfx sys`: 40,143 bytes to 11,300, 45 blocks),
unpacking itself when run; unpacked it runs from `$0801` to `$a4cf`, past BASIC's memory, which
packing keeps out of BASIC's way. The build makes the disk image when Exomizer is at
`/opt/frak-tools/exomizer-src/src/exomizer` (or `$EXOMIZER`): built from its source (here,
commit `ba91318`, `make` in `src`). `build.mjs --packtest` puts the packed program in the test
cartridge (below), so a run in VICE checks the unpacking.

It needs node and [64tass](https://sourceforge.net/projects/tass64/); `--run` needs VICE's
`x64sc` and `xvfb-run`. VICE's Debian package comes without Commodore's ROMs, so `--run` boots a
stand-in ROM (`src/rom.asm`) that copies the program into memory from a cartridge image of it
(`build/frak64.crt`, made by `build.mjs`) and starts it. The demo uses no
ROM routines.

| File | |
| --- | --- |
| `tools/mockup.mjs` | Redraws A_1 for the 8x4 grid and works out what ECM + 4-line FLI shows: `build/mockup.png`, the data for `pack.mjs`, and the platforms and ladders where it draws them, for Trogg's physics (`build/geometry.json`) |
| `tools/trogg.mjs` | Trogg's frames as sprites: a hi-res black outline over a multicolour infill, 24 wide, each sprite used twice down his 34 lines (`build/trogg.png`, `trogg.txt`, `trogg.bin`) |
| `tools/pack.mjs` | Packs the glyphs into two character sets (by band: a row's bottoms and the next row's tops), with the level's yo-yoed-off variant and 4 characters per set kept for the yoyo's string, and writes the screen codes (glyph + background) for the 94 x 25 level and each Scrubbly's patch knocking it off |
| `src/frak64.asm` | The demo: the timer interrupt a row, double-buffered screens, scrolling |
| `src/mux.asm` | The sprite multiplexer, and the demo's "game" (the Scrubblies following the scroll, the balls) |
| `tools/build.mjs` | Assembles it and the stand-in ROMs, and runs VICE headless for a screenshot |
| `tools/compare.py` | Checks a VICE screenshot against the mock-up, pixel by pixel, character row by row |
| `tools/vice.py` | Drives VICE through its remote monitor (screenshots while it runs, breakpoints, memory) |
| `tools/dump.py` | Runs the demo in VICE a while and prints memory at labels |
| `src/play.asm` | Playing: Trogg's movement (the BBC version's, as plain 6502), the keys, a game tick a frame, the level restarted when he dies |
| `tools/conn64.mjs` | Checks Trogg's movement against the original's, from every start holding every key, on A_1 as the C64 has it |
| `tools/keytest.py` | Plays a key script in py65 and in VICE and checks where Trogg ends up, and that he's drawn there |
| `tools/troggshot.py` | Finds Trogg in a screenshot and checks his place and every pixel, and nothing below his feet |
| `tools/muxcheck.py` | Checks the multiplexer's buffer, frame by frame, in VICE: set-ups, hardware sprites, rows' operands, registers, Trogg's ticks |
| `tools/profile.py` | Exact CPU cycles of the multiplexer, by routine and source line: VICE memory snapshots at its start, run in a 6502 emulator (py65) |

## How the display works

PAL, 63 cycles a line. Character row *n* starts at raster 51 + 8*n* with a normal bad line (the
tops' screen). On line 4 of the row, three writes:

- `$d018`: the bottoms' screen, and the character set for the band from here to line 3 of the
  next row (so the set only ever changes here, and nothing else needs timing);
- `$d011` just after cycle 14 (YSCROLL 7): a bad line the VIC didn't expect, which fetches the
  bottoms' codes without resetting its row counter;
- after the CPU has waited out that bad line, YSCROLL 3 again and `$d018` the tops' screen for
  the next row's bad line (the same set).

Only the `$d011` write has to land on an exact cycle, so the display is one short interrupt a
row rather than a loop that holds the CPU. CIA 1's timer B runs with a period of 504 cycles (8
lines; a PAL frame is exactly 39 of them) and interrupts at line 3 of each row. The interrupt
reads the timer to see how late it was taken (it waits for the instruction it interrupted to
finish: 0-7 cycles seen, up to 15 allowed) and jumps that many bytes into a slide of `cmp #$c9`s,
each byte a cycle shorter, so the writes land on the same cycle every time. The other 14 ticks
fall in the border; the first of them does the frame's bookkeeping. A double raster interrupt
starts the timer in step, once.

The timer's start and the lateness constant were found by sweeping them in VICE and checking
every row against the mock-up, with the main program running a mix of 7-cycle instructions and
taken branches to give the interrupt every lateness it can meet. The forced write lands on the
earliest cycle that works: one cycle earlier breaks the whole picture, one later widens the FLI
bug.

Scrolling is a pixel a frame: `$d016`'s fine scroll, and at each whole character a flip to the
other pair of screens, which the main program fills from the level map.

| Free CPU time for the main program (measured, `tools/build.mjs --measure`) | Cycles a frame |
| --- | --- |
| The first demo: one timed loop for the whole display | 6,464 |
| Now: an interrupt a row | 13,808 |
| With the cover sprite, and the interrupt proof against sprite fetches | 10,432 |

Of a frame's 19,656 cycles, the VIC takes about 2,100 (50 bad lines); the interrupts take the
rest. The border ticks could be switched off to save about 600 more.

Memory (VIC bank 1): screen pairs at `$4000`/`$4400` and `$4800`/`$4c00`, character sets at
`$5000` and `$5800`, the multiplexer's RAM at `$6000`, Trogg's sprites at `$6800`; the program
from `$0801` (below `$4000`), and the level map from `$7e80`. The program file runs on through the
VIC bank (what's there set up at the start), so the stand-in ROMs carry it as a cartridge image
(`build/frak64.crt`).

## Sprites and the critical write

| Sprite | |
| --- | --- |
| 0 | The cover over the FLI bug's columns: X- and Y-expanded with 16 pixels set (32 wide, so it also hides a fourth character when the write lands a cycle late), cyan, following the fine scroll, moved down the screen every 42 lines from the row ticks. In front of every other sprite |
| 1, 2 | Trogg (`src/trogg.asm`): his black outline (hi-res) and his infill (multicolour, yellow and magenta), each used three times down him (`tools/trogg.mjs`) |
| 3-7 | Multiplexed: the Scrubblies' bodies (their x following the scroll, wrapped round when part off at the left), balloons and daggers |

Other sprites move the critical write. The VIC fetches the sprites shown on a line at the end of
the line before (sprites 0-2) and the start of the line (3-7), holding BA low from 3 cycles
before each sprite's first fetch to its last, and the CPU stops at its next read while it's low.
The row interrupt meets two rounds of these: line 3's (end of line 2, start of line 3) and line
4's (end of line 3, start of line 4). So:

- it reads the timer in line 2, before line 3's fetches, and from there until the forced bad
  line's write it only reads: the slide, padding, and a tail of `nop`s and `bit`s. (Everything a
  row needs is set by the row before, as operands.) So the fetches cost exactly the cycles BA is
  low, which a model of them in `tools/build.mjs` counts;
- the slide skips line 3's cost as well as the interrupt's lateness, so `$d018` is written on
  line 3's cycle 55 whatever sprites are there;
- the tail's delay suits line 4's sprites, so the `$d011` write lands on line 4's cycle 14 (or 15
  where none can, the extra garbage character under the cover sprite).

Each row's masks (the sprites on its lines 3 and 4) pick the slide constant and the tail from
tables of all 256 masks of sprites (0 always on). The model was checked in VICE for every mask
(`--probemask`: the write's cycle read off where the garbage lands, `tools/garbage.py`) and
predicts all 128 exactly (measured with the cover as sprite 7; it's now sprite 0, and 24
layouts were checked again); and 30 layouts of sprites at random heights (`--test`), 72 of their
rows with a sprite starting or ending between lines 3 and 4, match the mock-up on every row.

The timer is started (once, from a stable raster) before any sprite is shown: their fetches
would upset the stable raster.

| Free CPU time with sprites | Cycles a frame |
| --- | --- |
| The cover sprite only | 10,432 |
| ... and seven more sprites on screen (a test layout) | 9,816 |
| The cover sprite and the five Scrubblies' (the demo) | 8,968 |

## The sprite multiplexer

`src/mux.asm` shares sprites 3-7 out among virtual sprites (`vy`, `vxlo`/`vxhi`, `vptr`, `vcol`,
`vfl`: expanded down or across, behind the characters, kept before others, hidden). The display
sets the constraints:

- A sprite can only be set up (pointer, colour, x, y, and the whole of `$d010`, `$d017`,
  `$d01d`, `$d01b`) where the CPU has time: in a row interrupt's tail, after the forced bad line
  (the row's *tick*), or before the frame (the last border tick, up to 4 there). A tail has room
  for one set-up before the next row's interrupt, so each tick sets up at most one sprite.
- Row *k*'s tick can set up a sprite whose y is 62 + 8*k* or more (it's ready by line y, where
  the VIC looks for it), on a hardware sprite last shown no later than line 54 + 8*k*.
- Every row interrupt must know which sprites are shown on its lines 3 and 4 (its masks), for
  its slide constant and tail.

It's incremental. A sprite keeps its hardware sprite and tick from frame to frame while they
still work (its tick early enough for its y; the sprites before and after it on its hardware
sprite out of its way), and only what changes is written: its x and y, its record, the rows
whose masks change (only the rows at the ends that moved), and the registers (swept down the
ticks only when a hardware sprite's settings change). A sprite whose place stops working is
dropped (the Scrubblies win against balls) and placed again with new ones, at most four a frame,
the Scrubblies first. The results go to the buffer not shown, which the border switches to,
with the scroll it was made for, once it's ready; each frame starts by copying the last frame's
changes across, so the two buffers keep step. The four set-ups before the frame are made in
border tick 37, leaving tick 38 time for row 0.

Checked in VICE: the balls put in the left border (`--balltest`: fetched, so they move the
critical writes, but unseen), and every row compared with the mock-up while it scrolls (all
match but for a few pixels where a ladder meets the lower Scrubbly's antenna, as before the
multiplexer); and a breakpoint after each frame checks the buffer made against the sprites:
each set-up early enough, no hardware sprite set up while shown, each row's slide constant and
tail, and the registers in force for every sprite on every line.

Measuring: `--muxtime` times its stages in VICE with interrupts off, and counts what happened;
`--slack` records each tick's least time to spare before the next (21 cycles at the least) and
how many frames the multiplexer was ready. For exact CPU cycles, memory snapshots taken in VICE
at the multiplexer's start are run in a 6502 emulator (py65), counting cycles by routine and
by source line (`tools/profile.py [FRAMES [SECONDS [LINES]]]`, on the last build).

The demo's load is Frak's: besides the five Scrubblies (only their x moves, with the scroll),
balloons and daggers at the CPC port's speeds and timings, a game tick a frame (`--insane` for
Insane, else Hard): a balloon every 120 frames (60) rising 1.3 pixels a frame (1.5), a dagger
every 132 (75) falling 0.66 (0.78) and going left 0.88 (1.04), each held still 55 frames (45)
first, in the level's x. (An earlier test, six balls bouncing 1 to 3 pixels a frame up and down,
cost 9,400 cycles a frame on average: most of it rows, as every ball crossed a row's line 3 or 4
most frames.)

A sprite moving up needs an earlier tick every 8 lines (a balloon, every 5 or 6 frames): it's
moved there in place, keeping its hardware sprite, and if its set-up changes the registers, the
new tick's are those in force there with its settings (and those set at the ticks it now comes
before take them too). A sprite placed with the settings already in force on its hardware sprite
(the sprite before it there has the same, or there's none and it has none) changes no registers;
nor does dropping one. Otherwise the registers are swept down the ticks: so mostly when a sprite
of another kind comes onto a hardware sprite, or a sprite crosses x 256.

| The multiplexer's CPU time (`tools/profile.py`, 2 x 24 frames) | Hard | Insane |
| --- | --- | --- |
| Average | 3,100 to 4,200 | 3,200 to 5,900 |
| Most frames | 2,600 to 4,400 | 2,250 to 7,000 |
| Frames that place a new sprite (a sweep, mostly) | 5,400 to 7,800 | 6,000 to 10,100 |
| Frames the multiplexer was ready (the display) | 92-98% | 91-92% |

In most frames the cost is game (600-850), sort (630-850), copying the last frame's changes
(500-1,100) and the update pass (850-950); a new sprite (placing it, about 700, and a sweep,
about 1,500) makes the expensive frames.

## Memory map

As built now (`tools/build.mjs` prints the program's extent; the labels are in `build/frak64.lbl`;
`tools/memmap.py` sizes each item). The program file loads from `$0801` to `$accf` (42,191 bytes;
13,736 packed on the disk image); the start sets `$01` to `$35` (RAM everywhere but I/O), so the
KERNAL's and BASIC's areas are RAM.

| From | To | What | Free |
| --- | --- | --- | --- |
| `$0002` | `$0063` | Zero page: the scroll, the row interrupt, the multiplexer, the yoyo and collisions' pointers | `$64`-`$ff` |
| `$0100` | `$01ff` | Stack | |
| `$0200` | `$07ff` | Unused (BASIC's and the KERNAL's areas) | 1.5K |
| `$0801` | `$35fe` | Low: code and tables that must be below the VIC bank or are timing-critical: the row interrupt and its tails (`$0d00`), the border ticks, VSP (`vspline`, `$0f00`), the fill, the column writes (`colw0`, `colw1`), the scroll (`scroll.asm`), the camera, the multiplexer (`mux.asm`), Trogg (`trogg.asm`), his physics (`play.asm`); the `$d018` tables (`$34e7`) | `$35ff`-`$3fff`, 2.5K |
| `$4000` | `$4fff` | VIC bank 1: the 4 screens, pair 0 (`$4000` tops, `$4400` bottoms) and pair 1 (`$4800`, `$4c00`); `$3f8`-`$3ff` of each the sprite pointers | |
| `$5000` | `$51ff` | Character set 0 (64 characters; loaded in place) | `$5200`-`$53ff`, 0.5K |
| `$5400` | `$567f` | Sprites: the cover (`$5400`, made at the start), the Scrubbly (`$5440`), the balloon (`$5480`), the yoyo's 4 (`$54c0`), the dagger (`$55c0`), the FRAK! bubble's 2 (`$5600`); all but the cover loaded in place | `$5680`-`$57ff`, 0.4K |
| `$5800` | `$59ff` | Character set 1 (loaded in place) | `$5a00`-`$5fff`, 1.5K |
| `$6000` | `$66c9` | The multiplexer's RAM (`.virtual`: its model, lists and both buffers, cleared at the start) | `$66ca`-`$67ff`, 0.3K |
| `$6800` | `$76ff` | Trogg's sprites: 60 different blocks, shared among his 15 frames (`tblk`: each frame's 6) | |
| `$7700` | `$895b` | The level map: `tops`, then `bottoms` (94 x 25 each; changed in place for what's knocked off and picked up) | |
| `$895c` | `$accf` | High (`.section high`): the yoyo and its string, knocking off and picking up (`yoyo.asm`), collisions (`collide.asm`, `$9d4b`, and its tables `collide.inc`), the balloons and daggers (`hazards.asm`, `$a214`), the multiplexer's and the physics' tables (`mktab` `$a500`, `lim` `$aa00`, `geometry.inc`), the patches' save areas | |
| `$acd0` | `$cfff` | | 8.8K |
| `$d000` | `$dfff` | I/O (the RAM under it unused) | |
| `$e000` | `$fff9` | RAM under the KERNAL (`$fffa`-`$ffff`: the NMI, reset and IRQ vectors) | 8K |

Free in all: about 17K in the large pieces (`$acd0`-`$cfff`, `$e000`-`$fff9`), 2.5K below `$4000`,
and about 2.7K in the VIC bank's gaps (usable for sprites or tables, not code the VIC would see).

The budget pass (milestone 13) took 2.5K off the program file and freed 1.8K below `$4000`: each
pair of row-tail tables shares a block (every row's mask has the cover's bit 0, so only odd entries
are read: one table in the odd bytes, the other in the even), Trogg's repeated sprite blocks and
collision spans once each, the character sets and sprites loaded where the VIC reads them instead
of copied there, and the patches' save areas cut to the cells there are (192).

## Next

A playable A_1: Trogg walking, climbing, jumping and falling, the scroll following him, and
the yoyo (knocking Scrubblies off). The plan: [`PLAN.md`](PLAN.md).
