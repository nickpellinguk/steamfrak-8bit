# Frak! for the Atari 800XL (experimental)

The start of an Atari 800XL (PAL, 64K) version: ANTIC mode 2 with character rows 4 lines high,
on the C64 port's 8x4 grid, so the C64's levels carry over cell for cell. The plan:
[`PLAN.md`](PLAN.md).

**Status: a sprite multiplexer, graphics first** (`build/trogg8x4.xex`, without the OS). Every
outline is drawn in software at full resolution (players are 2 hires pixels a block at their
finest, so an outline on one would be at half resolution), and the four players carry the
infills, given out band by band in this order: Trogg's (yellow and magenta, on P0 and P1 and
their missiles); the Scrubblies' bodies (one double-width player each, then two normal-width
where a second is free: exact for the C64's); the balloons' (magenta). Daggers have no infill.
`-D HWOUT=1` puts outlines on players too where they're free (Trogg's from one of his bands
down, a balloon's with its infill, a dagger's), for when speed has to win. On A_1, the joystick
walking and climbing Trogg (no physics yet), fire his yoyo pose, the screen following him;
balloons and daggers about him (stand-ins: about Hard's rate, `-D STRESS=1` six all the time).
Checked in the WebAssembly atari800, colour for colour: 501 screens of three joystick tours.

**What's still short of the original's look:** Trogg's infill is in 2-pixel blocks (at most 10 of
his 200-250 infill pixels wrong); a Scrubbly on one double-width player has 21 of its 540
magenta pixels wrong; the balloon's yellow highlight, the dagger's yellow blade and the
Scrubbly's yellow eyes and teeth aren't coloured; something partly off the screen across has
no infill (a player would show over the border); Poglets and Hooters have none yet.

**Speed:** the game runs at 50 ticks a second whatever the drawing takes (the VBI counts fields;
each frame made runs a tick for each field since the last, up to 4, as the C64 version makes up
for late frames). Frames: 25 a second with Trogg alone (a frame takes about 400 lines: 1.3
fields), about 17 with balloons and daggers out (every outline in software: about 2.3 fields).
The players' strips take 127-134 lines a frame, from 213-236: the Scrubblies' strips are kept
in each set while their players don't change, and of Trogg's only the old lines his new ones
don't cover are cleared. Next: the software drawing (Trogg about 180 lines; each hazard's
outline the rest) and the multiplexer (60-170 lines).

Before that, **an 8x4 screen demo.** `build/screen8x4.xex` shows the C64 port's A_1 ("FRAK!") on 52
rows of 4 lines, scrolling back and forth across the level 2 pixels a frame. It's black outlines
on one background colour: no infills, Trogg or game yet. Checked in atari800 against the C64's
picture of the level: every pixel the same at 11 scroll positions (each fine-scroll phase, both
ends) and in captures while it moves; A_2 and A_3 too. Not yet tried in Altirra or on a real
machine.

## Building and running

    ./build.sh                 # build/screen8x4.xex (and build/rows4.xex, the row test)
    LEVEL=A_2 ./build.sh       # another of the C64 port's levels (A_1, A_2, A_3 so far)
    STILLX=100 ./build.sh      # held at a scroll position (colour clocks) instead of moving

Trogg's sprites come from the steamfrak repository's `assets/sprites` (alongside this one, or
`STEAMFRAK=...`). Checking Trogg (after building the emulator, see "In a browser"):

    node test/tour.mjs build/a8.js build/trogg8x4.xex /tmp/tour "120:8 40:1 60:8:1 50:2 150:4"
    python3 test/checktrogg.py /tmp/tour A_1

It needs node (the C64 port's `tools/level.mjs` makes the level's picture), Python 3 with Pillow,
and [64tass](https://sourceforge.net/projects/tass64/). Run the `.xex` on a PAL 800XL (or any XL/XE
with 64K), or in an emulator set to PAL: `atari800 -xl -pal -run build/screen8x4.xex`.

## In a browser

`build/frak800.html` is a PAL 800XL in one web page: atari800 5.0 (GPL-2.0) built as libatari800,
compiled to WebAssembly, with its own AltirraOS (no Atari ROMs needed), and the programs above
built in (the demo on A_1, A_2 and A_3, and the row test). Open it in a browser, locally or from
any web host; it can also load another `.xex` or `.atr` (a button, or drop the file on the screen).
Not inside a host whose security policy forbids compiling WebAssembly (claude.ai's artifact
viewer, for one): there the page says so instead. (An asm.js build, `-s WASM=0`, compiled with
emscripten 3.1.6 but didn't run atari800's CPU, so there's no fallback yet.)
Arrow keys are joystick 1, Space or Ctrl fire, F2-F4 Start, Select and Option.

    ATARI800_SRC=/path/to/atari800-5.0.0 web/build_emulator.sh   # build/a8.js (needs emscripten)
    python3 web/build_page.py build/a8.js                          # build/frak800.html

| File | |
| --- | --- |
| `web/web.c` | The emulator's side: start a PAL 800XL with a program, run a frame with the joystick, keys and console keys, and hand over the screen, palette and sound |
| `web/page.html` | The page: the canvas (the emulator's 336 x 240 picture at 50 frames a second), the controls, keys, sound |
| `web/build_emulator.sh` | libatari800 and `web.c` through emscripten into one `a8.js` with the WebAssembly inside |
| `web/build_page.py` | `page.html` with `a8.js` and the programs put in: `build/frak800.html` |

## How things are drawn

- **10-bit graphics** (`tools/sprites.py`): each of his frames, at each of 4 shift positions (0,
  2, 4 and 6 pixels: the colour clocks that the scroll, and later his infill, move in), is a byte
  for each 8-pixel window, an index into that shift's 256-byte AND and OR tables. A pixel is set
  (the outline), clear or transparent; AND has a 1 where transparent, OR a 1 where set. All the
  moving graphics (Trogg, balloons, daggers, the yoyo, the FRAK! bubble) share the tables: 250,
  233, 236 and 252 windows of 256 (the build stops if a shift has more). Each column of a graphic
  is stored top to bottom with 3 transparent bytes above and below, so a character row's 4 lines
  are 4 bytes in a row wherever he starts in it. The empty space is at the sides (45% of his
  first and last columns' cells are all transparent, 3% of the middle ones'), so for the first
  and last columns, for each of the 4 lines a character row can start on relative to the
  graphic's top, a bitmask with a bit for each character row: 1 where that cell's all
  transparent, and skipped (shifted out a row at a time).
- **A cell's cost:** its 4 lines unrolled (`lda (dp),y` `tax` `lda (sp),y` `and andtab,x`
  `ora ortab,x` `sta (cp),y`, 28 cycles a line; the OR alone, 19), and around them the cell's
  spare character, claim and the VBI programs' entries. The programs are prefilled with
  `lda #` `sta abs` entries, so a cell writes only their operands (an `rts` ends each frame's,
  put back to `lda` when the program's next built); the programs are page-aligned, so one
  pointer step does both; the characters' addresses come from tables chosen once a frame (the
  set) and once a row (the half) instead of adds. Trogg's software drawing: 136 lines a frame
  on average, from 187 (194 before the side masks).
- **Spare characters** from code 64, given out a cell at a time, bottoms halves (for the first
  row of a pair) and tops halves (the second) separately: 64 of each, so a code serves a cell of
  each kind of row.
- **`plot`** (`src/trogg8x4.asm`) draws a graphic at a top left x (level pixels, signed) and a
  top line (display line + 32, so things can start above or below the screen), for each cell
  in the screen's 52 rows and the 41 columns in view where it isn't all transparent: a spare
  character's half in the character set not shown, started from the level's half glyph there
  (read through the clean map, which is never drawn on) or, if something has the cell already
  this frame (a table of the cells in view), from that; its 4 lines ANDed and ORed on
  (`lda (dp),y` `tax` `lda (sp),y` `and andtab,x` `ora ortab,x` `sta (cp),y`, the shift's table
  page patched in once a graphic; over blank background, `lda ortab,x` `sta (cp),y` alone).
- **The VBI's programs:** for each cell, plot writes `lda #code` `sta cell` into this frame's
  program and `lda #level's code` `sta cell` into a putting-back program. The VBI runs last
  frame's putting-back program and this frame's (6 cycles a cell), swaps the character sets (the
  level's glyphs are in both) and sets the scroll (the rows' LMS only when it changes coarsely).
  So double buffering costs a character set, not spare characters, nothing is seen half drawn,
  and the VBI stays short (a first version, putting cells back from lists, took about 9,000
  cycles with 6 hazards out and ran into the first row's DLI).
- **Cost:** about 330 cycles a cell, about 650 more a hazard (its rows' pointers, the set-up),
  a hazard 6-12 cells: about 4,000 cycles each. Trogg alone leaves 4,200-6,200 cycles a frame to
  spare (with the OS's VBI still running). Ways on: running the game a tick a VBI and drawing a
  frame every other one (as the BBC version does: 25 frames a second, 50 ticks), switching the
  OS out, and trimming the per-cell work (the programs' entries prefilled; the claims).

## The multiplexer

- **Players** (normal width: 8 two-pixel blocks, unless double-width: 4-pixel blocks;
  `tools/sprites.py` and `tools/screen.py` make their graphics):
  - Trogg's infill on P0 (yellow) and P1 (magenta), each with its missile (a player and a
    missile per colour: at most 10 of his 200-250 infill pixels wrong); his outline in two halves
    (P2 his left 16 pixels, P3 his right), a block on where either pixel is black, and his infill
    with holes there (the outline's players are behind it);
  - a Scrubbly's body from the C64's (where its magenta sprite shows): two normal-width players
    side by side (exact) or one double-width (21 of 540 pixels wrong);
  - a balloon's outline (a block on where either pixel is black) and infill; a dagger's outline.
- **Colours and widths:** P1 always magenta, P2 always black; P0 black, Trogg's yellow or
  magenta, and P3 magenta or black, set band by band with P0's, P1's and P3's widths. Players are
  in front of the playfield (`PRIOR` 1): mode 2's set pixels show luminance 0 in the hue under
  them, so outlines drawn in characters stay black over the infills.
- **Each frame** (`mux`), in this order: Trogg's infill; the Scrubblies (a double-width player
  each, P3, P1 or P0, then a second for two normal-width where one's free); the balloons'
  infills (P3, P1 or P0). With `HWOUT=1`, also Trogg's outline from one of his bands down (not
  his first: its writes are his infill's), a balloon's outline with its infill on a pair, and a
  dagger's outline.
- **Which band writes a thing's registers:** any from the one after the thing above it on its
  player has ended (by line 8k + 2) down to its top's, or the VBI if nothing's above it: the
  latest with room in its 5 writes is chosen (a Scrubbly's second player keeps its first's).
  Something not wholly on the screen across gets no player (it would show over the border);
  above and below, the players' graphics are clipped. Trogg's rows from his outline's band on
  aren't drawn in software.
- **Bands:** each pair of rows' first DLI (display line 8k + 3) writes the registers that change
  for the next 8 lines, through a table of 16 blocks by the band's mask. With ANTIC fetching the
  character codes on the line after, the writes finish two lines later, so a band's registers
  hold from line 8k + 6; two things share a player if the first ends by line 8k + 2. The DLI
  must end before the tops row's DLI (or that NMI interrupts it and the rows' order is left the
  wrong way round): about 150 cycles, so at most 5 register writes a band (P0 3, P1 2, P2 1, P3 3),
  which `mux` keeps to. The missiles (Trogg's alone) are set by the VBI. All measured colour by
  colour in atari800.
- **Double buffering:** two sets of player graphics (`PMBASE` swapped by the VBI with the
  characters) and of band tables; each frame clears the strips written to its set two frames
  before.
- **Cost:** `mux` about 54 lines, the strips most of a frame. To do: keep the Scrubblies' strips
  where they haven't changed (they're static: only their players change), write Trogg's infill
  once (plain above his outline's line, holed below), and draw every other frame with the game
  ticking every frame (the BBC version's 25 frames and 50 ticks).

## How the screen works

- **4-line rows:** the display list alternates mode 2 rows with vertical scrolling on and off.
  Each row's DLI sets `VSCROL` for what comes next: 3 on a first row (so the second ends after
  glyph line 3), and 4 on a second row, written after `sta WSYNC` and one `nop` (so the next pair
  starts at line 4). Each pair is then glyph lines 4-7 then 0-3. Why and how it was measured:
  [`test/README.md`](test/README.md).
- **Two glyphs a character:** the first row of a pair shows its characters' bytes 4-7 (a
  "bottoms" row), the second bytes 0-3 (a "tops" row), so each code holds two 4-line glyphs,
  numbered independently. The C64's character row n (tops then bottoms) becomes Atari rows
  bottoms(n-1), tops(n) paired: 52 rows from the C64's 25, the first and last blank. A_1 needs
  46 codes (41 tops glyphs, 46 bottoms), A_2 57, A_3 41: one character set each.
- **Scrolling:** every row has its own LMS into the map (52 rows of 128 bytes, the level from
  byte 4), and `HSCROL` is on for the fine steps. The deferred VBI sets `HSCROL` = -x & 3 and each
  row's LMS to row + (x + 3) / 4, for a scroll position x in colour clocks.

| File | |
| --- | --- |
| `tools/screen.py` | A level's character set and map for the 8x4 screen, from the C64 build's picture of it (`c64/build/<level>/chars.bin`); `build/<level>_expect.png`, the picture the Atari should show |
| `src/screen8x4.asm` | The demo: display list, row DLIs, scrolling VBI (with the OS, for now) |
| `src/trogg8x4.asm` | (memory: the program `$0800-$8fff`, the level's map `$9000`, the character sets `$ac00` and `$b000`, the display list `$b400`, the VBI's programs `$b500-$bd80`; under the OS, which ANTIC sees as the CPU does: the players' graphics `$c000` and `$c800`, the screen's map `$d800`, the bands' registers `$f200`, the claims `$f580`) |
| `src/trogg8x4.asm` | The same with Trogg: the joystick, the camera, drawing him into spare characters, the VBI showing a frame |
| `tools/sprites.py` | The moving graphics as 10-bit graphics (`build/sprites.inc`) and the AND and OR tables; `build/sprites.json` for the checks |
| `test/tour.mjs` | A program on the WebAssembly atari800 with a joystick script, saving the screen and memory every few frames |
| `test/checktrogg.py` | Each saved screen against the level with Trogg drawn on where the program's VBI says he is, pixel by pixel |
| `tools/budget.py` | Codes the static graphics need per set: 8x8 against 8x4, by bands of rows |
| `test/rows4.asm`, `readrows.py` | The 4-line row test, and its reader |
| `test/shot.sh` | Runs a program in atari800 (PAL 800XL) under Xvfb and captures its window |
| `test/checkscreen.py` | A capture against `<level>_expect.png` at a scroll position, pixel by pixel |
| `test/findscroll.py` | The scroll position a capture of the moving demo matches exactly, if any |
