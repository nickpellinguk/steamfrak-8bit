# Plan: rasterised Frak! on the Vectrex

Status: **milestone 1 under way** (the raster engine: see `README.md`, "Milestone 1"). The
tools and the tests behind it are in `README.md`.

The exit goal is the game as the CPC and BBC versions play it, for the levels that scroll
sideways and fit in a frame, with the menus and records, on a Vectrex cartridge, aiming at 32KB
(but ready for 64KB, bank-switched, if it won't fit). No music or sound effects yet.

## Scope

* **The 36 levels that scroll sideways** (256 pixels tall): training (room_0), A_1-A_9, B_1-B_9,
  D_1, D_3, D_4, D_6, E_1-E_4, E_8, E_9, F_1-F_4, F_7-F_9. The 19 that scroll up and down (all of
  C, D_2, D_5, D_7-D_9, E_5-E_7, F_5, F_6) are left out, so the view only ever moves sideways and
  the renderer only clips at the left and right edges.
* **Levels too busy to draw in a frame are left out too**, for now: which, is measured
  (milestone 3), not guessed. The menus show only the levels that are in.
* No music or sound effects, no typed commands (no keyboard).

## What it looks like

* **Everything raster, from the BBC sprites, except the yoyo's string** (one vector from Trogg's
  hand). One bit a pixel: each sprite's lit pixels are chosen once (for Trogg and the Scrubbly,
  the black ones: outlines and hair; see `preview/raster_columns.png`).
* **Columns** (sweeping down and up, stepping across): Trogg, the meanies (Scrubbly, Poglet,
  Hooter), ladders and chains (as they are, rungs and all), gems, balloons, daggers, bulbs.
* **Rows** (sweeping across, stepping down): platforms (their top two rows: `preview/raster_test.png`),
  keys, the yoyo itself, and the timer and rating.
* **The screen is 256 BBC pixels tall** (160 beam units a pixel, a pixel 2 cycles at a sweep
  speed of 80), so 206 wide: a level's full height, and a window 206 pixels wide (the BBC shows
  320).
* **Clipping at the left and right edges, by the column** (by the pixel for rows): what's off
  the window isn't drawn, a column at a time, so things slide off and on without popping.

## The budget

A frame at 50 Hz is 30,000 cycles: drawing, the game logic (50 ticks a second, as on the CPC,
the BBC and the original) and the BIOS's frame wait. The Vectrex has no frame buffer, so
everything is drawn every frame.

Estimated costs (columns: 53 cycles a turn + 2 a pixel; rows: 90 a turn + 2 a pixel; from the
tests), now and with milestone 1's cheaper turns (35 a column, 15 a row):

| | size | as | now | improved |
|---|---|---|---|---|
| Trogg walking | 26 × 34 | columns | 3,450 | 3,000 |
| Trogg climbing | 20 × 34 | columns | 2,660 | 2,300 |
| Scrubbly | 33 × 42 | columns | 4,920 | 4,320 |
| Poglet | 23 × 33 | columns | 3,060 | 2,650 |
| Hooter | 19 × 23 | columns | 2,220 | 1,880 |
| gem | 11 × 9 | columns | 940 | 740 |
| key | 22 × 10 | rows | 1,380 | 630 |
| balloon, dagger | ~12 × 10 | columns | ~1,000 | ~800 |
| ladder, 70 tall | 12 × 70 | columns | 2,560 | 2,340 |
| platforms on one line, 2 rows | up to 206 | rows | ~950 | ~800 |

Plus positioning each object (the BIOS's reset and move: ~300 cycles; less, chained), the timer
and rating (~1,000), and the game logic (unmeasured on the 6809: guess 3,000-6,000 a tick).

A screen like A_1's start (Trogg, two Scrubblies, platforms on 6 lines, 4 ladders, 3 gems) comes
to about 34,000 now and about 26,000 improved, plus the logic: over, so the cheaper turns and
positioning come first (milestone 1), and milestone 3 measures every level's busiest view to
see which levels are in.

## The memory

* **ROM (32KB):** level data ~8-10KB (36 levels; see 2.2), raster sprites ~6KB (one bit a
  pixel, columns and rows, facing both ways from the same data), code ~10KB (the CPC's game
  logic, `../cpc6128/src/`, is ~7,000 lines of Z80 for everything; 6809 code is usually a little
  smaller), front end and level names ~2KB. Tight: if it won't fit, 64KB with bank switching
  (the cartridge port's spare line, as homebrew does; to be checked, and vecx would need it too).
* **RAM (1KB, ~870 bytes free of the BIOS):** the CPC and BBC versions unpack each level into
  RAM; here the level stays in ROM in a form the game reads directly, with what their level
  loaders work out at a level's start (ladders' extensions, moving platforms' and meanies'
  ranges) worked out by the converter instead. RAM holds only what changes: Trogg, the meanies
  and moving platforms, the balloons and daggers, the gems collected (bits), the checkpoint, the
  timer, the records, the stack.

## The code to port: the CPC version's

The CPC version (`../cpc6128/src/`, Z80) follows the BBC version routine by routine, and its
tests check its logic against the BBC's tick for tick; the Vectrex version follows the CPC's,
in 6809:

| CPC | what | Vectrex |
|---|---|---|
| `trogg.asm` | Trogg: `trogg_standing`, `trogg_falling`, `trogg_climbing`, `platform_find_f`, `ladder_find` | ported as it is |
| `level.asm` | `platform_find`, `load_level` (unpacking into RAM) | `platform_find` ported; the loading done by the converter |
| `logic.asm` | the moving things: `update_slow`, `move_scrubbly`, `move_poglet`, `move_hooter`, collisions, the yoyo, balloons and daggers, checkpoints; `level_init` | ported |
| `play.asm` | the frame loop, the camera and scrolling | rewritten: the Vectrex's frame (`Wait_Recal`, then draw everything) |
| `plot.asm`, `bg.asm` | the plotter and the background | replaced by the raster engine |
| `front.asm` | the attract screen, menus, records, level-complete screen | ported, drawn with the row routine |
| `machine.asm` | the CPC's interrupts, banks, keyboard | replaced: the BIOS's joystick and buttons |
| `sound.asm` | music and sound | later |

The Z80's registers map onto the 6809's well enough (A, B / D; HL, DE / X, Y, U), and the
arithmetic (twentieths of a pixel, the debouncing) stays exactly as it is.

## Milestones

Each is checked before the next, and this file is updated as they're done.

### 1. The raster engine

Done so far (`README.md`, "Milestone 1"): data-driven columns with a 35-cycle turn, drifting rows,
the platform strip, clipping by the column, chained moves, the check against MAME (which found
two timing questions only a real Vectrex can settle: the slide across, and the spot's timing).
Still to do: rows clipped by the pixel (they're trimmed by the byte), facing left (columns drawn
right to left), and moving from object to object at run time (positions computed by the 6809,
not the generator).

* Data-driven column and row routines (not generated code): a sprite is columns (or rows) of
  bytes; the same data drawn facing either way.
* Clipping at the left and right edges: columns outside the window skipped, rows trimmed.
* Cheaper turns: no spot-off at a column's end (it ends blank), the sample-and-hold's settling
  time used for the next column's loads, constants in registers. Target ~35 cycles.
* Rows without the two sample-and-hold trips: Y's speed held at a pixel per row's time, so the
  beam drifts down as it goes back and forth (each row slopes by a pixel: to be seen whether
  that shows), leaving a turn of ~15 cycles.
* Moving from one object to the next without the BIOS's reset to the centre (a reset every few
  objects, for the drift); measure how far chains of moves can go.
* **Check the timings against MAME** (and if possible a real Vectrex): vecx makes each write as
  its instruction starts, a 6809 in its last cycle, and every offset here is tuned in vecx.
* Check: a test cartridge drawing every kind of object, partly off each edge too; a table of
  measured cycles for each.

### 2. The converter

* **2.1 Sprites:** from the steamfrak repository's sprites, to raster data: the lit pixels
  chosen per sprite (an art pass, with a preview sheet through the beam model,
  `tools/beam.py`), in columns or rows.
* **2.2 Levels:** from `../tools/convert.py`'s `build_level` (the same platforms, ladders,
  objects and moving things as the BBC and CPC versions), for the 36 sideways levels, to a ROM
  format the game reads in place: their 3-byte records plus what the level loader works out,
  with platforms sorted and grouped by line for drawing, and everything sorted by x so the
  renderer finds what's in the window quickly.
* **2.3 The budget:** `tools/budget.py` with raster costs, for every level's busiest view.
* Check: every level's data back out against `build_level`; the budget table.

### 3. A level on screen, scrolling

* A level drawn from ROM, the view moved by the joystick: platforms grouped by line, ladders
  and chains, gems, keys, meanies standing still; the timer.
* A frame-time meter (cycles left in the frame, on screen and in beamshot's capture).
* Check: every level's busiest view measured in vecx, with a margin for the game logic; the
  levels that don't fit are listed and left out.

### 4. Trogg

* A port of the CPC version's `trogg.asm` (and `platform_find`) to the 6809, with the same
  arithmetic in twentieths of a pixel and the same debouncing; the camera following him as the
  CPC's does (sideways only).
* Joystick left/right walk, up/down climb, button 1 jump, button 4 yoyo, button 2 back.
* Checked as the CPC version is (`../cpc6128/tools/emu/`, `connections.mjs`): Trogg's movement
  against the original's scripts, from every start, holding every key, with the 6809 code run
  on vecx's 6809 (or an interpreter) from a test harness.
* Check: A_1 walked, climbed and jumped through in vecx; the search passing on every level in.

### 5. Playing a level

* Gems and keys collected, checkpoints, death (the long fall, the meanies, falling off; "FRAK!"
  as a raster speech bubble), the level complete (its time, the gems, the medal), the timer and
  rating.
* Check: A_1 played to the end.

### 6. Meanies, platforms, balloons and daggers

* A port of `logic.asm`: Scrubblies, Poglets and Hooters moving; moving platforms (Trogg riding
  them); balloons and daggers by difficulty; the yoyo (raster yoyo, vector string) knocking
  meanies flying.
* Checked as the CPC version's `logic.mjs` checks it: the game logic doing what the BBC (and
  CPC) version does, tick for tick.
* Check: the A, B and D levels that are in, played.

### 7. Bouncing and placing

* Bouncing platforms and their springs; movable platforms carried with the yoyo.
* Check: the E and F levels that are in, played; every level in completed in vecx.

### 8. The front end

* A port of `front.asm`: the Cast, the menus (Replay, Difficulty, Training, the groups' 3x3
  grids with the level names, target and best times, medals, showing only the levels that are
  in), the level-complete screen, the records (in RAM, lost at power off, as on the BBC and
  CPC), in raster text (the row routine).
* Check: everything reachable from the menus, as on the CPC.

### 9. Fitting

* Measure the ROM; pack what's needed (level data that can still be read in place, sprite data
  shared between frames); if it won't fit, 64KB bank-switched.
* Check: the cartridge image built by `build.sh`, run in vecx and MAME.

### Later

* The levels left out (the busy ones, then the ones that scroll up and down, which need
  clipping at the top and bottom too).
* Music and sound effects on the AY-3-8912 (the CPC version's player, `../cpc6128/src/sound.asm`,
  is for the same chip family).
* A real Vectrex: brightness, the analogue lag, the shift register's timing, the integrators'
  drift, the overlay.

## Risks

* **The frame budget** (above): measured early (milestones 1 and 3); levels that don't fit are
  left out.
* **Timings checked only in vecx:** MAME early in milestone 1; a real Vectrex when one's
  available.
* **32KB:** the estimate is tight; 64KB is the fallback.
* **The narrow window** (206 pixels, against the BBC's 320) changes how much of a level is in
  view, and so how it plays.
