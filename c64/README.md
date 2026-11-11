# Frak! for the Commodore 64 (experimental)

An experiment in showing Frak's graphics on an unexpanded C64 (and a C128 in C64 mode) at their
own resolution, without doubling the pixels' width. So far it's a display demo: level A_1
("FRAK!") scrolling left and right, with the Scrubblies' sprites and balloons and daggers shared
out by a sprite multiplexer, but no Trogg and no game.

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
    ./build.sh [--run]     # build/frak64.prg (LOAD"FRAK64.PRG",8,1 and RUN)

It needs node and [64tass](https://sourceforge.net/projects/tass64/); `--run` needs VICE's
`x64sc` and `xvfb-run`. VICE's Debian package comes without Commodore's ROMs, so `--run` boots a
stand-in ROM (`src/rom.asm`) that copies the program into memory and starts it. The demo uses no
ROM routines.

| File | |
| --- | --- |
| `tools/mockup.mjs` | Redraws A_1 for the 8x4 grid and works out what ECM + 4-line FLI shows: `build/mockup.png`, and the data for `pack.mjs` |
| `tools/trogg.mjs` | Trogg's frames as sprites: a hi-res black outline over a multicolour infill, 24 wide, each sprite used twice down his 34 lines (`build/trogg.png`, `trogg.txt`, `trogg.bin`) |
| `tools/pack.mjs` | Packs the glyphs into two character sets (by band: a row's bottoms and the next row's tops) and writes the screen codes (glyph + background) for the 94 x 25 level |
| `src/frak64.asm` | The demo: the timer interrupt a row, double-buffered screens, scrolling |
| `src/mux.asm` | The sprite multiplexer, and the demo's "game" (the Scrubblies following the scroll, the balls) |
| `tools/build.mjs` | Assembles it and the stand-in ROMs, and runs VICE headless for a screenshot |
| `tools/compare.py` | Checks a VICE screenshot against the mock-up, pixel by pixel, character row by row |
| `tools/vice.py` | Drives VICE through its remote monitor (screenshots while it runs, breakpoints, memory) |
| `tools/dump.py` | Runs the demo in VICE a while and prints memory at labels |
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
`$5000` and `$5800`, the program and level from `$0801`.

## Sprites and the critical write

| Sprite | |
| --- | --- |
| 0 | The cover over the FLI bug's columns: X- and Y-expanded with 16 pixels set (32 wide, so it also hides a fourth character when the write lands a cycle late), cyan, following the fine scroll, moved down the screen every 42 lines from the row ticks. In front of every other sprite |
| 1, 2 | (Trogg: `tools/trogg.mjs`) |
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

## Next

A playable A_1: Trogg walking, climbing, jumping and falling, the scroll following him, and
the yoyo (knocking Scrubblies off). The plan: [`PLAN.md`](PLAN.md).
