# Plan: rasterised Frak! on the Vectrex

Status: **proposed, not started.** The tools and the tests behind it are in `README.md`.

The exit goal is the whole game as the BBC version plays it (all 55 levels, the menus, the
records), on a Vectrex cartridge, aiming at 32KB (but ready for 64KB, bank-switched, if it won't
fit). No music or sound effects yet.

## What it looks like

* **Everything raster, from the BBC sprites, except the yoyo's string** (one vector from Trogg's
  hand). One bit a pixel: each sprite's lit pixels are chosen once (for Trogg and the Scrubbly,
  the black ones: outlines and hair; see `preview/raster_columns.png`).
* **Columns** (sweeping down and up, stepping across): Trogg, the meanies (Scrubbly, Poglet,
  Hooter), ladders and chains, gems, balloons, daggers, bulbs.
* **Rows** (sweeping across, stepping down): platforms (their top two rows: `preview/raster_test.png`),
  keys, the yoyo itself, and the timer and rating.
* **The screen is 256 BBC pixels tall** (160 beam units a pixel, a pixel 2 cycles at a sweep
  speed of 80), so 206 wide: a portrait window, narrower than the BBC's 320.
* **Anything partly off the window isn't drawn.** Things will pop in and out at the edges unless
  the overlay hides a margin as wide as the widest thing (the Scrubbly, 33 pixels): see
  decision 1.

## Decisions to make early

1. **The window and the overlay.** With partly-off things skipped, either they pop at the edges
   or an overlay frame hides a 33-pixel margin each side, leaving a window 140 pixels wide (the
   BBC shows 320, the Steam version scales). Alternatives: a smaller pixel (more of the level in
   view, smaller characters), or clipping to the column (skip only the columns outside: the
   column routine makes this cheap, and nothing pops). My suggestion: clip by column for the
   column-drawn things, skip whole for rows (platforms are clipped exactly anyway, see 3.2).
2. **Which pixels are lit**, sprite by sprite: an art pass, in a preview tool (milestone 1).
3. **Controls.** Joystick left/right walk, up/down climb, button 1 jump (or up, as the BBC's O),
   button 4 yoyo, button 2 back (Escape); typed commands dropped (no keyboard).

## The budget (the main risk)

A frame at 50 Hz is 30,000 cycles: drawing, the game logic (50 ticks a second, as the BBC and
the original) and the BIOS's frame wait. The Vectrex has no frame buffer, so everything is drawn
every frame, or it flickers.

Estimated costs now (columns: 53 cycles a turn + 2 a pixel; rows: 90 a turn + 2 a pixel; from
the tests), and with the improvements in milestone 1 (35 a column turn, 15 a row turn):

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

Plus positioning each object (the BIOS's reset and move: ~300 cycles), the timer and rating
(~1,000), and the game logic (unmeasured on the 6809: guess 3,000-6,000 a tick).

A screen like A_1's start (Trogg, two Scrubblies, platforms on 6 lines, 4 ladders, 3 gems,
~20 objects to position) comes to about 34,000 now: over a frame before the logic. With the
improvements and ladders drawn more cheaply (below), about 22,000, plus the logic: tight, but
inside. The busiest screens (A_6's 23 Hooters, A_9's 26 gems and 15 keys) won't fit by these
means alone. Ways out, in order of preference:

* make turns and positioning cheaper (milestone 1);
* ladders as their pole in 2 columns plus a short row per rung (~800 instead of ~2,400);
* gems, keys and bulbs drawn on alternate frames when there are many (flicker at 25 Hz, on
  things that don't move: worth trying on a real screen);
* the game logic on alternate frames, two ticks at once, on screens that need it (the BBC
  version draws at 25 frames a second with the logic at 50);
* plainer sprites for meanies when several are in view.

Milestone 3 measures this on every level before the game logic is ported, so the choice is
made with real numbers.

## The memory

* **ROM (32KB):** level data ~12-15KB (55 levels; see 2.2), raster sprites ~6KB (one bit a
  pixel, columns and rows, both directions from the same data), code ~10KB (the BBC's game
  logic is ~11KB of 65C02; 6809 code is usually smaller), front end and level names ~2KB. Tight:
  if it won't fit, 64KB with bank switching (the cartridge port's spare line, as homebrew does;
  to be checked, and vecx would need it too).
* **RAM (1KB, ~870 bytes free of the BIOS):** the BBC version unpacks each level into RAM; here
  the level stays in ROM in a form the game reads directly, with what the BBC works out at a
  level's start (ladders' extensions, moving platforms' and meanies' ranges) worked out by the
  converter instead. RAM holds only what changes: Trogg, the meanies and moving platforms, the
  balloons and daggers, the gems collected (bits), the checkpoint, the timer, the records, the
  stack.

## Milestones

Each is checked before the next, and this file is updated as they're done.

### 1. The raster engine

* Data-driven column and row routines (not generated code): a sprite is columns (or rows) of
  bytes; the same data drawn facing either way.
* Cheaper turns: no spot-off at a column's end (it ends blank), the sample-and-hold's settling
  time used for the next column's loads, constants in registers. Target ~35 cycles.
* Rows without the two sample-and-hold trips: sweep with Y's speed held at a pixel per row's
  time, so the beam drifts down as it goes back and forth (each row slopes by a pixel: to be
  seen whether that shows), leaving a turn of ~15 cycles.
* Clipping by column (decision 1).
* Moving from one object to the next without the BIOS's reset to the centre (a reset every few
  objects, for the drift); measure how far chains of moves can go.
* **Check the timings against MAME** (and if possible a real Vectrex): vecx makes each write as
  its instruction starts, a 6809 in its last cycle, and every offset here is tuned in vecx.
* Check: a test cartridge drawing every kind of object; a table of measured cycles for each.

### 2. The converter

* **2.1 Sprites:** from the steamfrak repository's sprites, to raster data: the lit pixels
  chosen per sprite (decision 2), in columns or rows, with a preview sheet through the beam
  model (`tools/beam.py`).
* **2.2 Levels:** from `../tools/convert.py`'s `build_level` (the same platforms, ladders,
  objects and moving things as the BBC version), to a ROM format the game reads in place: the
  BBC's 3-byte records plus what the level loader works out, with platforms sorted and grouped
  by line for drawing.
* **2.3 The budget:** `tools/budget.py` with raster costs, for every level's busiest view.
* Check: every level's data back out against `build_level`; the budget table.

### 3. A level on screen, scrolling

* A level drawn from ROM, the view moved by the joystick: platforms grouped by line, ladders,
  gems, keys, meanies standing still; the timer.
* A frame-time meter (cycles left in the frame, on screen and in beamshot's capture).
* Check: every level's busiest view measured in vecx; the budget's ways out chosen and tried.

### 4. Trogg

* A port of the BBC version's `trogg_standing`, `trogg_falling`, `trogg_climbing`,
  `platform_find` and `ladder_find` (`../src/frak.asm`) to the 6809, with the same arithmetic
  in twentieths of a pixel, the same debouncing; the camera following him as the BBC's does.
* Checked as the BBC and C64 versions are: `../tools/emu/connections8.mjs`'s search, on a 6809
  interpreter (or vecx's own 6809, driven from a test harness), against the original's scripts,
  from every start, holding every key.
* Check: A_1 walked, climbed and jumped through in vecx; the search passing on every level.

### 5. Playing a level

* Gems and keys collected, checkpoints, death (the long fall, the meanies, falling off; "FRAK!"
  as a raster speech bubble), the level complete (its time, the gems, the medal), the timer and
  rating.
* Check: A_1 played to the end.

### 6. Meanies, platforms, balloons and daggers

* Scrubblies, Poglets and Hooters moving as on the BBC; moving platforms (Trogg riding them);
  balloons and daggers by difficulty; the yoyo (raster yoyo, vector string) knocking meanies
  flying.
* Check: groups A-D played.

### 7. Bouncing and placing

* Bouncing platforms and their springs; movable platforms carried with the yoyo.
* Check: groups E and F played; all 55 levels completed in vecx.

### 8. The front end

* The Cast, the menus (Replay, Difficulty, Training, the six groups' 3x3 grids with the level
  names, target and best times, medals), the level-complete screen, the records (in RAM, lost
  at power off, as on the BBC), in raster text (the BIOS's `RASTER` routine, or our row routine).
* Check: everything reachable from the menus, as on the BBC.

### 9. Fitting

* Measure the ROM; pack what's needed (level data that can still be read in place, sprite data
  shared between frames, mirrored frames at run time); if it won't fit, 64KB bank-switched.
* Check: the cartridge image built by `build.sh`, run in vecx and MAME.

### Later

* Music and sound effects on the AY-3-8912 (the CPC port's tune conversion, `../cpc6128/`, is
  for the same chip family).
* A real Vectrex: brightness, the analogue lag, the shift register's timing, the integrators'
  drift, the overlay.

## Risks

* **The frame budget** (above): measured early (milestones 1 and 3), before the logic.
* **Timings checked only in vecx:** MAME early in milestone 1; a real Vectrex when one's
  available.
* **32KB:** the estimate is tight; 64KB is the fallback.
* **The narrow window** (decision 1) changes how much of a level is in view, and so how it
  plays.
