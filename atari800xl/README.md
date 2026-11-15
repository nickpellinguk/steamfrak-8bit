# Frak! for the Atari 800XL (experimental)

The start of an Atari 800XL (PAL, 64K) version: ANTIC mode 2 with character rows 4 lines high,
on the C64 port's 8x4 grid, so the C64's levels carry over cell for cell. The plan:
[`PLAN.md`](PLAN.md).

**Status: Trogg drawn into spare characters** (`build/trogg8x4.xex`): his outline (monochrome:
no infill yet) on A_1 at any even x and any y, the joystick walking and climbing him (no physics
yet: he goes through platforms), fire his yoyo pose, the screen following him, at 50 frames a
second with 4,200-6,200 cycles a frame to spare. Checked in the WebAssembly atari800: 128 screens
of a joystick tour (all 4 shift positions, all 16 frames it reaches, scrolling), every pixel
the same as the level's picture with his frame drawn on where the program says he is.

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
Arrow keys are joystick 1, Space or Ctrl fire, F2-F4 Start, Select and Option.

    ATARI800_SRC=/path/to/atari800-5.0.0 web/build_emulator.sh   # build/a8.js (needs emscripten)
    python3 web/build_page.py build/a8.js                          # build/frak800.html

| File | |
| --- | --- |
| `web/web.c` | The emulator's side: start a PAL 800XL with a program, run a frame with the joystick, keys and console keys, and hand over the screen, palette and sound |
| `web/page.html` | The page: the canvas (the emulator's 336 x 240 picture at 50 frames a second), the controls, keys, sound |
| `web/build_emulator.sh` | libatari800 and `web.c` through emscripten into one `a8.js` with the WebAssembly inside |
| `web/build_page.py` | `page.html` with `a8.js` and the programs put in: `build/frak800.html` |

## How Trogg is drawn

- **10-bit graphics** (`tools/sprites.py`): each of his frames, at each of 4 shift positions (0,
  2, 4 and 6 pixels: the colour clocks that the scroll, and later his infill, move in), is a byte
  for each 8-pixel window, an index into that shift's 256-byte AND and OR tables. A pixel is set
  (the outline), clear or transparent; AND has a 1 where transparent, OR a 1 where set. All the
  moving graphics (Trogg, balloons, daggers, the yoyo, the FRAK! bubble) share the tables: 250,
  233, 236 and 252 windows of 256 (the build stops if a shift has more). Each column of a graphic
  is stored top to bottom with 3 transparent bytes above and below, so a character row's 4 lines
  are 4 bytes in a row wherever he starts in it.
- **Spare characters** from code 64: one for each column of his and pair of rows (its bottoms
  half for the pair's first row, its tops half for the second): 24 at most.
- **A frame** (`src/trogg8x4.asm`, `draw`), made while the one before is shown: for each cell he
  covers that isn't all transparent, the level's half glyph there (read through the clean map,
  which is never drawn on) copied into a spare character of the character set not shown, his 4
  lines ANDed and ORed on (`lda (dp),y` `tax` `lda (sp),y` `and andtab,x` `ora ortab,x`
  `sta (cp),y`: the shift's table page patched in once a frame), the cell's code listed.
- **The VBI**, all at once: last frame's cells put back from the clean map, this frame's codes
  written, the two character sets swapped (the level's glyphs are in both), the scroll set. So
  double buffering costs a character set, not spare characters, and nothing he covers is seen
  half drawn.

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
| `src/trogg8x4.asm` | The same with Trogg: the joystick, the camera, drawing him into spare characters, the VBI showing a frame |
| `tools/sprites.py` | The moving graphics as 10-bit graphics (`build/sprites.inc`) and the AND and OR tables; `build/sprites.json` for the checks |
| `test/tour.mjs` | A program on the WebAssembly atari800 with a joystick script, saving the screen and memory every few frames |
| `test/checktrogg.py` | Each saved screen against the level with Trogg drawn on where the program's VBI says he is, pixel by pixel |
| `tools/budget.py` | Codes the static graphics need per set: 8x8 against 8x4, by bands of rows |
| `test/rows4.asm`, `readrows.py` | The 4-line row test, and its reader |
| `test/shot.sh` | Runs a program in atari800 (PAL 800XL) under Xvfb and captures its window |
| `test/checkscreen.py` | A capture against `<level>_expect.png` at a scroll position, pixel by pixel |
| `test/findscroll.py` | The scroll position a capture of the moving demo matches exactly, if any |
