# Milestone 0: 4-line rows

`rows4.asm` shows, scanline by scanline, which glyph line ANTIC is showing. Characters 1-8 are
each solid on one glyph line only (character k+1 on line k), so on any scanline the one of
columns 0-7 that's lit names the glyph line. The display list is a normal mode 2 row, then 20
pairs of rows: the first of each pair with the vertical scroll bit set (`$62`), the second
without (`$42`). The first rows show characters 1-8 in columns 0-7 and a marker in column 36,
the second in columns 16-23.

    64tass --atari-xex -D MODE=1 -D DELAY=1 -D HSC=1 -D PMDMA=1 rows4.asm -o rows4.xex
    ./shot.sh rows4.xex rows4.png     # atari800 (PAL 800XL) under Xvfb, a capture of its window
    python3 readrows.py rows4.png     # A:4567 B:0123 ...: each row's glyph lines, in order

| Option | |
| --- | --- |
| `MODE=0` | No DLIs: `VSCROL` held at `VS` |
| `MODE=1` | A DLI on every row. The first row of a pair sets `VSCROL` = `VB` (3) at once; the second waits on `WSYNC`, then `DELAY` nops, then sets `VSCROL` = `VA` (4) for the next pair's start |
| `NOWSYNC=1` | ...without the `WSYNC` |
| `PMDMA=1` | Players and missiles fetched on every line (1-line resolution), all showing |
| `HSC=n` | Horizontal scrolling on (the wide, 48-byte fetch), `HSCROL` = n - 1 |

It needs `64tass`, `atari800` (5.0: it has AltirraOS built in, so no Atari ROMs), `Xvfb`, `xwd`
and Pillow. atari800 offers no headless screenshot, so `shot.sh` captures its window, which it
draws 1.5 times as wide (hence glyphs as solid 8-pixel blocks, not single pixels).

## Results (atari800 5.0, PAL 800XL)

| | Rows, in glyph lines |
| --- | --- |
| `MODE=0`, `VS=4` | 4-7, then 0-4: pairs of 4 + 5 lines, as expected |
| `MODE=1`, no `WSYNC`, or `DELAY=0` without horizontal scrolling | broken: rows of 8 lines and blank rows |
| `MODE=1`, `DELAY` 1-3, no horizontal scrolling (with or without players) | **4-7, then 0-3: exactly 4 + 4**, all 20 pairs |
| `MODE=1`, `DELAY` 0-2, horizontal scrolling (`HSCROL` 0-2, with or without players) | **exactly 4 + 4** |
| `MODE=1`, `DELAY` 4 or more (3 or more with horizontal scrolling) | the first row of a pair starts a line early: 3-7, then 0-3 |

So `sta WSYNC`, one or two `nop`s, `sta VSCROL` gives 4-line rows in every case tried: the write
lands after ANTIC's end-of-row check for the second row of a pair and before it reads `VSCROL`
for the next row's start. The wide fetch takes a cycle or two more of the next line before the
CPU's write, which is why the window moves one `nop` earlier with horizontal scrolling. `DELAY=1`
is inside both windows. (With `HSCROL` 3 the readout is garbled: its 6-pixel shift moves
`readrows.py`'s samples into the next column. That's the reader, not ANTIC.)

Each row shows a known half of the character: the first row of a pair glyph lines 4-7 (the
"bottoms"), the second lines 0-3 (the "tops"). So a character holds two 4-line glyphs, one for
each kind of row, with neither stored upside down and `CHACTL` not needed.

**Still to do:** the same in Altirra (the accurate emulator; its site isn't reachable from where
this was run) and on a real PAL 800XL, as the window is only 2-3 cycles wide.
