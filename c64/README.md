# Frak! for the Commodore 64 (experimental)

An experiment in showing Frak's graphics on an unexpanded C64 (and a C128 in C64 mode) at their
own resolution, without doubling the pixels' width. So far it's a display demo: level A_1
("FRAK!") scrolling left and right, with no Trogg, no sprites and no game.

**Status: demo working in VICE (x64sc, PAL), the display an interrupt a row that stays on time
whatever sprites are shown, leaving the main program about half the CPU; not yet tried on a
real machine.**

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

The BBC art is redrawn to suit: platforms snapped to the 8x4 grid (8 across, 4 down), ladders
and objects black on cyan, lined up with the 16-pixel platform units. Every 8x8 cell's
foreground came out black, so colour RAM is filled once and never scrolled. The Scrubblies are a
black outline with yellow eyes and teeth in the characters; a magenta sprite behind each will
make the body (in the mock-up, not yet in the demo).

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
| `tools/build.mjs` | Assembles it and the stand-in ROMs, and runs VICE headless for a screenshot |
| `tools/compare.py` | Checks a VICE screenshot against the mock-up, pixel by pixel, character row by row |
| `tools/vice.py` | Drives VICE through its remote monitor (screenshots while it runs, breakpoints, memory) |

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

Sprite 7 covers the FLI bug's columns: X- and Y-expanded with 16 pixels set (32 wide, so it also
hides a fourth character when the write lands a cycle late), cyan, following the fine scroll,
and moved down the screen every 42 lines from the row ticks so the VIC fetches it on every row.

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
  where none can: 33 of the 128 masks, the extra garbage character under the cover sprite).

Each row's masks (the sprites on its lines 3 and 4) pick the slide constant and the tail from
tables of all 128 masks of sprites 0-6. The model was checked in VICE for every mask
(`--probemask`: the write's cycle read off where the garbage lands, `tools/garbage.py`) and
predicts all 128 exactly; and 30 layouts of sprites at random heights (`--test`), 72 of their
rows with a sprite starting or ending between lines 3 and 4, match the mock-up on every row.

The timer is started (once, from a stable raster) before any sprite is shown: their fetches
would upset the stable raster.

| Free CPU time with sprites | Cycles a frame |
| --- | --- |
| The cover sprite only | 10,432 |
| ... and sprites 0-6 on screen (a test layout) | 9,816 |

## Next

The Scrubblies' magenta sprites, a sprite over the FLI bug's columns, then Trogg.
