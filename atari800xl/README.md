# Frak! for the Atari 800XL (experimental)

The start of an Atari 800XL (PAL, 64K) version: ANTIC mode 2 with character rows 4 lines high,
on the C64 port's 8x4 grid, so the C64's levels carry over cell for cell. The plan:
[`PLAN.md`](PLAN.md).

**Status: an 8x4 screen demo.** `build/screen8x4.xex` shows the C64 port's A_1 ("FRAK!") on 52
rows of 4 lines, scrolling back and forth across the level 2 pixels a frame. It's black outlines
on one background colour: no infills, Trogg or game yet. Checked in atari800 against the C64's
picture of the level: every pixel the same at 11 scroll positions (each fine-scroll phase, both
ends) and in captures while it moves; A_2 and A_3 too. Not yet tried in Altirra or on a real
machine.

## Building and running

    ./build.sh                 # build/screen8x4.xex (and build/rows4.xex, the row test)
    LEVEL=A_2 ./build.sh       # another of the C64 port's levels (A_1, A_2, A_3 so far)
    STILLX=100 ./build.sh      # held at a scroll position (colour clocks) instead of moving

It needs node (the C64 port's `tools/level.mjs` makes the level's picture), Python 3 with Pillow,
and [64tass](https://sourceforge.net/projects/tass64/). Run the `.xex` on a PAL 800XL (or any XL/XE
with 64K), or in an emulator set to PAL: `atari800 -xl -pal -run build/screen8x4.xex`.

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
| `tools/budget.py` | Codes the static graphics need per set: 8x8 against 8x4, by bands of rows |
| `test/rows4.asm`, `readrows.py` | The 4-line row test, and its reader |
| `test/shot.sh` | Runs a program in atari800 (PAL 800XL) under Xvfb and captures its window |
| `test/checkscreen.py` | A capture against `<level>_expect.png` at a scroll position, pixel by pixel |
| `test/findscroll.py` | The scroll position a capture of the moving demo matches exactly, if any |
