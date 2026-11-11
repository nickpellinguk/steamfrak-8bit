# Frak! for the Commodore 64 (experimental)

An experiment in showing Frak's graphics on an unexpanded C64 (and a C128 in C64 mode) at their
own resolution, without doubling the pixels' width. So far it's a display demo: level A_1
("FRAK!") scrolling left and right, with no Trogg, no sprites and no game.

**Status: first demo working in VICE (x64sc, PAL); not yet tried on a real machine.**

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
- **A character set per row**: two sets of 64, switched between rows. Each character holds a top
  glyph and a bottom glyph, so a set holds 64 of each.

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
| `tools/pack.mjs` | Packs the glyphs into two character sets and writes the screen codes (glyph + background) for the 94 x 25 level |
| `src/frak64.asm` | The demo: the stable raster, the timed display loop, double-buffered screens, scrolling |
| `tools/build.mjs` | Assembles it and the stand-in ROMs, and runs VICE headless for a screenshot |
| `tools/compare.py` | Checks a VICE screenshot against the mock-up, pixel by pixel, character row by row |
| `tools/vice.py` | Drives VICE through its remote monitor (screenshots while it runs, breakpoints, memory) |

## How the display works

PAL, 63 cycles a line. Character row *n* starts at raster 51 + 8*n* with a normal bad line (the
tops' screen). A double raster interrupt gives a stable start, then one loop of exactly 504
cycles a row draws the screen:

- after the row's bad line, `$d018` switches to the bottoms' screen;
- on line 4, `$d011` is written just after cycle 14 (YSCROLL 7): a bad line the VIC didn't
  expect, which fetches the bottoms' codes without resetting its row counter;
- YSCROLL goes back to 3, and in the horizontal blank after line 7, `$d018` switches to the next
  row's tops' screen and character set.

The CPU always comes back from a bad line on the same cycle, so the loop stays in step by
itself. The delays were found by sweeping them in VICE and checking every row against the
mock-up. The forced write lands on the earliest cycle that works: one cycle earlier breaks the
whole picture, one later widens the FLI bug to 4 characters.

Scrolling is a pixel a frame: `$d016`'s fine scroll, and at each whole character a flip to the
other pair of screens, which the main program fills from the level map in the borders. The
display loop takes the CPU for all 200 lines, so everything else (the game, later) has the
borders: about 104 lines, roughly 6,500 cycles a frame. Most of each row's loop is spare
cycles in delay loops, which cycle-counted work could use instead.

Memory (VIC bank 1): screen pairs at `$4000`/`$4400` and `$4800`/`$4c00`, character sets at
`$5000` and `$5800`, the program and level from `$0801`.

## Next

The Scrubblies' magenta sprites, a sprite over the FLI bug's columns, then Trogg.
