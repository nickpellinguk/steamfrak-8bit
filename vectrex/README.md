# Frak! for the Vectrex: feasibility

Not a port yet: tools for deciding what a Vectrex version could draw, line art, and tests of drawing
by vectors and by raster. The plan for a rasterised port is in `PLAN.md`.

## How the Vectrex draws, and what that costs

The beam is steered by two integrators. The 6809 sets an X and a Y speed (signed 8-bit DACs) and
starts a timer (the "scale"); the beam moves in a straight line until the timer runs out. So:

* A line's time is set by the scale, and its length is speed x time.
* Its brightness goes as intensity / speed: the energy the beam leaves on each bit of it. So at a
  given brightness, a line's time is proportional to its length.
* Each vector, drawn or blank, also costs the CPU's time to set it up, and the beam has to be
  reset to the centre now and then, because the integrators drift.

At 50 Hz a frame is 30000 cycles of the 1.5 MHz 6809.

## The tools

| | |
|---|---|
| `tools/vconvert.py` | Milestone 2's converter: the sprites to raster data (`gen/sprites.asm`, preview `preview/sprites.png`), the 36 sideways levels to the ROM format (`gen/levels.asm`, each decoded again and checked against `../tools/convert.py`'s `build_level`), and the raster budget of each level's busiest window (`gen/budget.txt`). `test/gen_check.asm` assembles both files. |
| `tools/half_rules.py` | Ways of halving sprites for half resolution, side by side (`preview/half_rules.png`). |
| `test/m1h_test.asm` | Half resolution against full: every kind of object drawn both ways (`M1_HALF=1 python3 vectrex/tools/m1_gen.py` writes its `m1h_engine.asm` and `m1h_data.asm`; `preview/m1_half.png`, `preview/m1_half_zoom.png`). |
| `test/dagger.asm`, `tools/dagger.py` | A vector dagger (a sharp V, a crossguard, a handle) pointing four ways, beside the raster one (`preview/dagger.png`). |
| `test/m1s_test.asm` | Columns swept at the fastest speed (127) against full resolution (`M1_STRETCH=1 python3 vectrex/tools/m1_gen.py`; `preview/m1_fast.png`). |
| `test/m1t_test.asm`, `tools/m1_trim_gen.py` | Trimmed columns (each swept only as far as it needs) against full ones (`preview/m1_trim.png`). |
| `test/m1c_test.asm`, `tools/m1_cave_gen.py` | Cave platforms (the ledges) as 8 rows against milestone 1's 2-row strip (`preview/m1_cave.png`). |
| `test/m1z_test.asm`, `tools/m1_zig_gen.py` | Zigzag sprites (the beam drifting down, X flipping every row) beside full columns (`preview/m1_zigzag.png`). |
| `tools/budget.py` | For every level, slides a 320x256 and a 256x256 window across it, and estimates the drawing cost of the busiest window position (platforms as one line, ladders as two, the line art's real vector counts, standing meanies, gems and keys, and moving things whose range is in view). |
| `tools/beam.py` | A model of the beam: renders lines (end points, intensity, time) with brightness from intensity x time / length, a brighter dot at each end where the beam dwells, a Gaussian spot, phosphor saturation and a little bloom. Its constants aren't measured: they're for comparing lines with each other. |
| `art/shapes.py` | The line art, as polylines over the BBC sprites' pixels: Trogg standing (37 vectors), the Scrubbly (52), a gem and a key. |
| `tools/artsheet.py` | Each shape next to its sprite, the polylines over it, and the shape through the beam model (`preview/artsheet.png`). |
| `tools/scene.py` | A level's window through the beam model, with a cycle estimate (`preview/A_1.png`, `preview/A_6.png`). |
| `emu/` | `beam.patch` for vecx (an open-source Vectrex emulator, GPL v3) so it reports how long the beam took over each line and the cycle it ended on (and so it compiles with current GCC); `beamshot.c`, a front end that runs it without a window and writes the lines down; and `build.sh`, which fetches vecx at a fixed commit, patches it and builds `emu/vecx/beamshot`. |
| `tools/render_capture.py` | Renders what beamshot wrote down through the beam model (`preview/timing_vecx.png`), or with `--plain` as vecx and MAME show it; `--view` zooms in. |
| `tools/timing.py` | For each run of vectors in a capture: how many, cycles from one start to the next, cycles moving, and cycles of the spot standing still before and after. |
| `test/timing.asm` | A cartridge that draws with the BIOS's routines and with a polling loop of its own, for measuring what each costs. |
| `test/chain.asm` | `chain16`: a polyline drawn at scale 16 by counting cycles instead of polling, against the BIOS's `Draw_VLc` (`preview/chain_vs_bios.png`). |
| `test/vlist.asm` | `vlist`: a vector list where each vector has its own scale (18-255), waited for exactly in software, each vector carrying its wait's address (`preview/vlist_vecx.png`). |
| `test/vlist_a.asm` | `vlist_a`: the same, with the wait worked out from the scale as it draws (`LSRA`, `LBCS` to the next instruction for the odd cycle, `NEGA`, `JMP A,U` into a page-aligned run of NOPs): 4 bytes a vector. |
| `test/vlist_c.asm` | `vlist_c`: vlist_a for scales of 28 and over, and the timer polled (as the BIOS does) for scales under 28 (`SUBA #28` sets the carry, `BLO` picks the path before the timer starts): any scale from 1 to 255. |
| `test/vlist_d.asm` | `vlist_d`: every scale exact. 28 and over as vlist_a; under 28, a table gives each scale its own block: a fixed delay (spot on, NOPs and BRNs, spot off), or where there's time, the timer polled with the reads lined up (a delay of 0-8 cycles by scale mod 7, then the `BIT` loop). |
| `test/raster_test.asm` | Vectors and raster together (`preview/raster_test.png`, `preview/raster_columns.png`): Trogg and the Scrubbly from `art/frak-graphics-v001.svg` drawn with vlist_d (`test/vlist_d_routine.asm`), with Trogg's head and the Scrubbly's eyes as raster patches from the BBC sprites; Trogg and the Scrubbly wholly as raster columns from the sprites; and a row of ledges as two raster lines (the top two rows of `sLedge1_Beeb`, repeated). |
| `tools/raster_test.py` | Makes its data: the vector lists (each vector's rounding carried into the next) and the raster code, straight-line, with every write at a counted cycle. |
| `tools/svg_shapes.py` | Reads line art drawn in Inkscape over the tracing sheets (`art/frak-graphics-v001.svg`) into polylines in each sprite's pixels. |
| `tools/vlist_d_short.py` | Makes vlist_d's table and blocks (`test/vlist_d_short.asm`), choosing polling for each scale where the loop's first read can come early enough. |
| `tools/vlist_data.py` | Makes the test lists (`--computed` for vlist_a, `--short` for vlist_c, `--all` for vlist_d), working out each vector's wait for vlist. |

asm6809 is built in `/opt/frak-tools/asm6809/bin/` by the Frak ports environment's setup script.

```sh
vectrex/emu/build.sh
(cd vectrex/test && /opt/frak-tools/asm6809/bin/asm6809 -B -o timing.bin timing.asm)
vectrex/emu/vecx/beamshot vectrex/emu/vecx/rom.dat vectrex/test/timing.bin 1000 1 capture.txt
python3 vectrex/tools/timing.py capture.txt
python3 vectrex/tools/render_capture.py capture.txt timing.png
python3 vectrex/tools/budget.py ../steamfrak
python3 vectrex/tools/artsheet.py ../steamfrak vectrex/preview/artsheet.png
python3 vectrex/tools/scene.py --steamfrak ../steamfrak --level room_A_1 --scenery-speed 127 --out a1.png
```

## What the emulators do about brightness

vecx and MAME both set a line's brightness from the intensity register alone, not the beam's
speed, and neither shows the dots where the beam dwells. Hence `beam.py`, and the patch to vecx.

## The analogue lag

In MAME's Vectrex the analogue side lags the VIA by 8.5 microseconds (`ANALOG_DELAY`): the ramp
starting and stopping, the integrators being zeroed, and the DAC's values (X, Y and intensity)
all reach the integrators about 13 cycles after the 6809 writes them, while the blanking (spot
on or off) doesn't lag. Its comment says getting this right matters for where text and mazes
come out in real games. vecx has no lag; `beam.patch` adds it (`beamshot -d CYCLES`, 13 by
default, 0 for vecx as it was, which gives exactly the captures it gave before).

So when timer 1 runs out the beam goes on moving for about 13 cycles: the NOP after the BIOS's
polling loop keeps the spot on until it stops. A routine that counts cycles needs the same
offset, but not idle time: it turns the spot on 13 cycles after starting the timer, and off 13
after the timer runs out, and meanwhile can put the next vector's values on the DAC, as they
arrive after the beam has stopped.

## What drawing costs (measured in vecx, with the 13-cycle lag)

vecx's beam units are DAC value x cycles: a vector with dx = 16 at scale 8 is 128 units long.

| | cycles per vector, start to start | moving | spot on, standing: before / after |
|---|---|---|---|
| BIOS `Draw_VLc` at scale 8 | 81 | 8 | 17 / 2 |
| BIOS `Draw_VLc` at scale 16 | 88 | 16 | 17 / 1 |
| BIOS `Draw_VLc` at scale 32 | 102 | 31 | 17 / 0 |
| `draw16` (timing.asm: the BIOS's steps, polling, without its extras) | 78 | 8 | 17 / 3 |
| `chain16` (chain.asm: counting cycles, scale 16 only) | 67 | 16 | 0 / 1 |
| `vlist` (vlist.asm: exact software wait from an address in the data, any scale 18-255) | scale + 51 | scale - 1 | 0 / 0 |
| **`vlist_a`** (vlist_a.asm: exact software wait worked out from the scale, 28-255) | **scale + 51** | scale | **1 / 0** |
| `vlist_c`, scales 28-255 (exact, as vlist_a; the branch to the polling path costs 3) | scale + 54 | scale | 1 / 0 |
| `vlist_c`, scales 1-16 (polling) | 93 | scale | 1 / 16 at scale 1, falling to 1 / 1 at 16 |
| `vlist_c`, scales 17-27 (polling) | 100-107 | scale | 1 / 1-7 (polling sees the timer only every 7 cycles) |
| **`vlist_d`**, scales 4-27 (fixed delay: 4-10, 12; lined-up polling: 11, 13-27) | **scale + 98** | scale | **0 / 0** |
| `vlist_d`, scales 1-3 (drawn as 4) | 102 | scale | 0 / 4 - scale |
| `vlist_d`, scales 28-255 (as vlist_c) | scale + 54 | scale | 1 / 0 |
| a separate dot: `Reset0Ref`, `Moveto_d` at scale $7F, `Draw_Line_d` | about 390 | | |

(Without the lag, vecx shows the BIOS's standing time as 4 before and 15 after: the same in all,
in different places.)

* A long line (`Draw_Line_d` at scale $FF) comes out as one line: vecx doesn't break lines up.
  (The BIOS's start-up screen is drawn dashed.)
* `chain16` costs 51 cycles a vector more than its movement, against the BIOS's 72, and the spot
  hardly stands still at all: no bright dots at the vertices. Of the 51, 36 are the writes to the
  VIA that every vector needs (dy, mux on, mux off, dx, timer, spot on, spot off); the rest are
  the loop and the gap the BIOS leaves for Y's sample-and-hold to settle (kept, to be safe on
  real hardware). Shapes compiled into straight-line code could save perhaps 10 more.
* `vlist` gives every vector its own scale, so a shape can be drawn at one speed (one
  brightness) whatever its segments' lengths: scale = length / speed. The wait is a jump into a
  run of NOPs, with two copies whose exits differ by a cycle, so it's exact to the cycle; each
  vector carries the address to jump to (worked out when the list is made), so finding it costs
  nothing at run time. Measured in vecx for scales 18 to 255: every vector exactly scale + 51
  cycles from the one before, the spot never standing still.
* `vlist_a` works the wait out from the scale instead (on the 6809 a short branch takes 3 cycles
  whether or not it branches, so the odd cycle comes from `LBCS`: 5 cycles, 6 if it branches;
  and `JMP A,U` jumps with A as a signed offset, so A is negated and U is the end of the NOPs).
  That costs about 9 more cycles, which go inside the wait, so they raise the shortest scale
  (28) rather than costing time; in return it's 4 bytes a vector (scale, dy, dx, spot), the
  list ends with a scale of 0, and its NOPs are one 128-byte page. It's the one to use.
* `vlist_c` draws any scale, but polling brings back the BIOS's problems for scales under 28:
  after the timer runs out the spot has to stay on another 13 cycles (the lag), and polling
  only notices every 7 cycles, so the fewest NOPs after the loop that never cut a line short (3)
  leave the spot standing 1-7 cycles at the end; and below scale 16 it can't turn the spot off
  any sooner, so it stands 16 - scale cycles. A polled vector also costs 93-107 cycles, more than
  an exact one at scale 28 (82).
* `vlist_d` puts that right: the polling blocks are timed so that one read lands exactly when
  the timer runs out (a read that starts at the cycle the timer runs out sees its flag, in vecx),
  so the loop ends at a known cycle, and the shortest scales, where the loop's first read can't
  come early enough, use a fixed delay instead. Every scale from 4 to 255 is lit exactly while
  the beam moves; 1-3 can't be (the spot-on and spot-off are two stores, at least 4 cycles
  apart), but a line that short can be drawn at scale 4 with a smaller DAC value. Its table and
  blocks are about 310 bytes. Short vectors still cost 44 cycles more than long ones (scale + 98
  against scale + 54): their next vector's setup doesn't overlap the beam's last 13 cycles, and
  they go through the table and two long branches.
* `vlist`'s costs: 6 bytes a vector (scale, dy, dx, spot on/off, wait address) against the BIOS's 2,
  and about 480 bytes for the runs of NOPs. Vectors need a scale of at least 18 (shorter ones
  at a lower speed, which is brighter). The spot comes on a cycle late (lit for scale - 1):
  writing it a cycle earlier costs 3 cycles a vector, which didn't seem worth it.
* (The 13-cycle lag and the spot's on/off timing are MAME's and vecx's: a real Vectrex could
  need these offsets adjusted, which in vlist means moving a NOP or two.)

## Raster patches (test/raster_test.asm)

As the BIOS's text routine does (see the RUM source, `RASTER`): the ramp switched by port B
(ACR = $18) rather than timer 1, the beam sweeping steadily along a row while the shift register
sends a byte of pixels out a bit at a time (a lit bit is a short dash), rewritten every 16 cycles
so the bits run on without a break. Rows go back and forth (the bits reversed going left), a
pixel apart: between rows Y's sample-and-hold is set to a small speed for a 4-cycle ramp, then
back to 0. With the screen 256 BBC pixels tall (160 beam units a pixel), a pixel a bit is a sweep
speed of 80.

* **The shift register shifts a bit every 2 cycles** in that mode (a 6522 shifts on CB1's
  falling edges and CB1 toggles every cycle; MAME does this), not every cycle as vecx did:
  `beam.patch` fixes it (`beamshot -s 1` for vecx as it was). This moves every routine's spot
  timing by a cycle: vlist_d's vectors now stand a cycle at the end, and need their spot-off
  writes moving a cycle earlier.
* Measured in vecx, the bits start 12 cycles after the ramp goes on (the model said 11), and
  the ramp must be on exactly 2 cycles a pixel, or a row going right ends half a pixel out and
  the row back is shifted. With both right, every row's pixels land exactly on the grid, both
  ways, a pixel apart.
* Costs (from the code's cycle counts): Trogg's head, 9 rows of 24 pixels, 1241 cycles (about
  the same as the ~20 vectors it replaces); the Scrubbly's eyes, 6 rows of 16, 725 (about half
  the vectors'); the ledges, 2 rows of 192, 933. About 90 cycles a row are the turn: two trips
  through the sample-and-hold to step Y and zero it again. That's what to make cheaper.
* **Whole sprites as columns** (`preview/raster_columns.png`): sweeping down and up rather than
  across turns out much better, as the axes aren't alike: Y goes through the sample-and-hold, X
  comes straight from the DAC. So a column's turn is one trip through the sample-and-hold (the Y
  speed reversed), and the step across is the DAC at X speed 40 for the ramp's first 4 cycles (a
  pixel), through 2 blank pixels at each end of the column. In vecx every column lands exactly a
  pixel from the last, and every lit run starts and ends on a whole pixel, down and up.
  * Trogg (26 columns of 40 pixels, the black pixels lit): **3,455 cycles**, against about
    6,400 for the traced vectors (48 vectors, 5,168 cycles: most are short, so they take
    vlist_d's slower path) with the raster head (1,241). The Scrubbly (33 columns of 48):
    about 4,900, against about 6,400. They look like the BBC sprites drawn in light; for the
    Scrubbly, lighting only the black pixels keeps its eyes' crescents (lighting the yellow too
    fills them in).
  * Every frame comes straight from the sprite (no tracing), facing left is the columns the
    other way round, and an object at the screen's edge can lose whole columns, a pixel at a
    time. The code here is generated straight-line (about 2KB for Trogg); as data for a loop,
    a frame is about 130 bytes.
  * Still to do: sweep only each column's occupied part (most of the cost is blank pixels at
    the top and bottom of narrow columns), and a data-driven loop.
* Caveat: vecx makes each write as its instruction starts; a real 6809 writes in an
  instruction's last cycle. Exact offsets like these (and vlist_d's) are vecx's, and need
  checking against MAME (which times writes within instructions) or a real Vectrex.

## Milestone 1: the raster engine (test/m1_test.asm, tools/m1_gen.py)

`tools/m1_gen.py` writes `test/raster_engine.asm` (the routines) and `test/m1_data.asm` (a test
scene: every kind of object, two of them partly off the edges, a strip of ledges wider than the
screen; `preview/m1_scene.png`). `M1_CHAIN=1` chains the moves between objects.

* **Columns, data-driven:** one routine per column height (bytes), two columns a pass, the
  sprite's columns stored in sweep order. The turn is cheaper: one `STY` turns the ramp off,
  switches the mux on and puts the next Y speed on the DAC; the count, the next first byte and
  the next Y speed are loaded while the sample-and-hold settles; one `STU` (U constant) switches
  the mux off and sets the slide's speed; no spot-off (columns end blank). **35 cycles a turn**
  (38 after the loop's branch), against 53: measured in vecx, the Scrubbly's columns exactly 131
  and 134 cycles apart (16 x 6 + 35, + 3).
* **Clipping by the column:** any first column (with its parity) and count; a Scrubbly and a
  Poglet half off the left and right edges are cut there.
* **Rows:** keys and the yoyo as *drifting* rows: Y's sample-and-hold holds a small speed down,
  the ramp stays on, each turn is one store flipping the X speed (each row slopes by a pitch,
  slight on the key, more on the 1-byte yoyo; the drift is 10 / bytes, so a 3-byte key's rows are
  0.9 pixels apart). Platforms as a strip: two rows of any length, a 16-cycle byte loop, trimmed
  to the window by the byte (the up-to-7 pixels past the screen's edge can't be seen).
* Costs (cycles, in vecx): Trogg 3,026 (was 3,455), Trogg climbing 2,327, Scrubbly 4,371 (was
  4,917), Poglet 2,678, Hooter 1,908, ladder (12 x 70) 2,365, chain 1,575, gem 752, balloon 819,
  dagger 752, bulb 842, key 540 (was ~1,380), yoyo 156, ledges (2 rows of 26 bytes) 972.
* **Moves between objects:** the test scene (16 objects, ~27,000 cycles of drawing) repeats every
  35,460 cycles with the BIOS's reset and move before each object, 32,924 chained (a move straight
  from where the last object left the beam; a move's rounding left uncorrected up to a quarter of
  a pixel, as a second vector costs ~100 cycles). vecx doesn't model the integrators' drift, so
  how far moves can be chained before a reset needs a real Vectrex.

### At run time (test/m1_rt.asm, tools/m1_rt_gen.py)

`test/m1_rt.asm` is the engine driven by the 6809 itself: a scene table (column sprites facing
either way, a key, the yoyo, a strip of ledges) that scrolls 40 pixels each way, everything
clipped, positioned and moved between as it runs (`preview/m1_runtime.png`: three frames).

* **Facing left:** the same column data, drawn from the right with the slide going left
  (`colN_down_l`, `colN_up_l`): the sprite comes out mirrored, at no extra cost.
* **Clipping:** columns by the column, at both edges, facing either way. Strips by the pixel: the
  bytes in the window, the first and last masked; the strip's rows are an unrolled run of byte
  slots entered by a table according to the length (the last slot ANDs the last byte with its
  mask), so every write keeps its 16-cycle beat. Keys and the yoyo, partly off the window, are
  drawn whole (the part outside is past the screen's edge: up to 22 pixels); wholly off, not drawn.
* **Moves:** `move_to` from where the beam is (tracked in RAM) to where it's wanted, at a fixed
  speed of 80 on each axis that moves: a diagonal leg as long as the shorter axis, then a leg
  along the longer axis. Positions are kept in half pixels (80 beam units: the beam's travel in a
  cycle at speed 80), so each leg lasts as many cycles as the half pixels it covers: no
  divisions or multiplications, and the beam lands exactly (no correction vector). `draw_cols`
  starts the diagonal, sets up the columns while it runs, then finishes the move. (Milestone 1
  first had a coarse vector at scale 128, the distance / 128, then one at scale 1 for the rest,
  left out within a quarter of a pixel: 128 cycles however short the move, and corrections. A
  first try at the legs at speed 127 spent 413 cycles converting beam units to cycles and back,
  more than the travel saved; at speed 80 that's 168.) Note: the BIOS's `Reset0Ref` leaves the
  integrators held at zero (`Moveto_d` lets them go): after it, the VIA's control register needs
  $CE.
* **Costs, measured** (`beamshot -p`, which prints the cycle whenever the 6809 reaches given
  addresses): per object, clipping 118 cycles, positions ~220, the move and set-up ~460 (~900 for
  a long move), the end ~80: **~900 cycles an object** besides its drawing. The scene (12 things,
  ~25,000 cycles of drawing) takes ~35,700 a frame. With the moves in legs at speed 80, 35,578 a
  frame on average over the whole scroll, against 37,067 with the scale-128 moves: ~115 cycles
  saved an object. Static scenery (platforms, ladders, gems)
  doesn't move relative to itself, so in milestone 3 its moves can be worked out by the converter
  and chained (~200 each, nothing computed), leaving run-time moves for the things that move.

### Against MAME (tools/calib_gen.py, test/calib.asm)

MAME 0.264, run without a window, a snapshot taken by a Lua script; calibration patterns whose
misalignment reads off a screenshot (`preview/m1_calib_vecx_mame.png`: vecx above, MAME below):

* **MAME loses the slide across:** it applies a DAC value 8.5 microseconds (12.75 cycles) after
  it's written, but reads the DAC then, so a value replaced within 13 cycles never takes effect.
  That looks like a simplification of MAME's (a real analogue lag passes a short pulse on, late),
  but it can't be settled without hardware. With `M1_DRIFT_COLUMNS=1` the columns don't slide:
  the DAC holds a small X speed through each column (a pixel across in a column's time: 10 /
  bytes), and MAME steps across, but ~8% too far: a speed of 2 is so small that any offset in
  the DAC (MAME's model has one; a real DAC may, which is what the BIOS's zero reference is for)
  is a large error. The slide at 40 isn't sensitive to that.
* **The spot runs ~1.7 cycles later against the beam in MAME than in vecx:** with drifting
  columns, MAME's down and up columns' dots are 1.67 pixels apart with the first byte written 12
  cycles after the ramp goes on (vecx's value), 0.17 apart at 10 (`M1_SR0=10`). Drifting rows and
  the strip line up in MAME as they are.
* So the engine keeps both the slide and the drift, and the first byte's time, as settings; vecx's
  values are the defaults. Which is right needs a real Vectrex.

## Milestone 2: the converter (tools/vconvert.py)

`python3 vectrex/tools/vconvert.py ../steamfrak` writes `gen/sprites.asm`, `gen/levels.asm`,
`gen/budget.txt` and `preview/sprites.png`. The formats are in the script's docstring.

* **Sprites** (`preview/sprites.png`: each BBC frame beside its lit pixels, which are decoded back out
  of the bytes and checked against the sprite): Trogg's frames, the three meanies, gem, balloon,
  the daggers, spring, ladders, chains and Qiana poles as columns; key, yoyo and "FRAK!" as rows.
  The lit pixels are the black ones everywhere for now. **Trogg's left frames aren't mirror images
  of his right ones** (a third of his black pixels differ: the shading is lit from one side), so
  they're stored too, not drawn mirrored: 44 frames, 3,530 bytes.
* **Platforms:** ledges and girders repeat a tile, so a run of them touching on one line is one
  strip from a repeating buffer (ledges 2-byte period, girders 3), 382 bytes with the logs' own
  rows. The 36 levels have 263 strips where they have 1,020 platform pieces.
* **Levels:** 11,757 bytes for the 36 (326 a level): the pieces in the original order (for
  `platform_find`'s ties), the ladders with their extensions worked out, the things standing still
  (gems, keys, meanies that don't move, springs) sorted by x, the moving meanies and platforms
  with their ranges worked out, and the drawing strips sorted by x. Every level decodes back to
  what `build_level` gives (positions, sizes, sprites, bounciness, ladder extensions, every moving
  thing's parameters), and the strips cover exactly the static platforms' top pixels.
* All of it assembles (`test/gen_check.asm`): 16,145 bytes. More than the plan's 9-10KB for the
  levels; packing is milestone 9's.

### The budget (gen/budget.txt)

Each level's busiest 206-pixel window, from milestone 1's measured costs: columns 16 a byte + 35
a turn, strips 32 a byte + 150, 250 a move for scenery (chained by the converter, milestone 3's
plan), 900 for things that move; plus a fixed 15,095 (Trogg 3,029 + his move, three balloons or
daggers, the HUD at 1,000 and the game logic guessed at 5,000).

**No level fits in a 30,000-cycle frame.** The closest are F_9 (30,925) and E_9 (31,451); the
median is 47,432 and the worst B_4 at 77,429. Split up (A_1 at its worst, x = 304: 54,374):
platforms 8,240, ladders 15,712, things 15,327 (three Scrubblies 11,700 with moves), fixed 15,095.
The B levels are worst for moving meanies (B_4: 39,783, eleven Scrubblies' ranges), the A levels
for ladders and standing meanies.

### Half resolution, 1x2 (test/m1h_test.asm)

Columns 2 pixels apart at full height (a column sweep is already at the sweep speed the shift
register allows, so the height can't halve), rows 2 pixels apart, platforms one row. The routines
are milestone 1's with the slide across doubled (DAC 80 for its 4 cycles: `colNh_*`), the rows'
drift doubled (`rowsN_Mh`), and `strip1` for one row. Same cost a column, half the columns:
Trogg 1,513 cycles (3,026), the Scrubbly 2,251 (4,371), a ladder 1,180 (2,365), the ledges 486
(972).

* **It draws correctly** (`preview/m1_half_zoom.png`: full and half side by side, half also
  clipped at both edges), **but it looks poor with the sprites halved automatically**: each
  column covering two pixels' worth (lit if either is) turns shading lines into hatching and the
  ladders' hollow rungs into dots; every other column loses details; outlines alone lose the eyes
  and fangs (`preview/half_rules.png`). Half-resolution sprites would need drawing for it (13
  columns for Trogg, 17 for the Scrubbly), and the gaps between columns show (on a real Vectrex
  too, probably: a pixel is about 0.9mm, the spot narrower).
* **The budget at half resolution** (Trogg always at full resolution): 9 of the 36 fit; median
  35,184. (`gen/budget.txt` now shows fast columns instead: below.)
* **Moves are now the biggest cost**: with free moves, 34 of the 36 would fit at half resolution
  (median 23,024); with chained moves at 100 cycles instead of 250, 14 fit; without balloons and
  daggers, 15. So the next saving is moving between objects, before any more resolution.

### Fast columns (test/m1s_test.asm)

Columns swept at 127, the DAC's fastest, instead of 80: the shift register can't go faster than
a bit every 2 cycles, so each bit is 1.59 pixels tall (not 2: that would need a speed of 160). The
sprites are resampled so every row of pixels goes into exactly one bit (lit if any of its rows
is: no thin line is lost). The routines are milestone 1's with the Y speed changed (`colNs_*`).

* **Looks:** much better than halving the width (`preview/m1_fast.png`, full then fast for each):
  everything recognisable, small details merging (Trogg's eye, the Hooter's eyes), and dimmer, as
  the beam moves faster (the intensity could be turned up for them).
* **Costs** (cycles, full then fast): Trogg 3,026 / 2,610, Scrubbly 4,371 / 3,315, Poglet 2,678 /
  2,310, Hooter 1,908 / 1,604, ladder 2,365 / 1,789, chain 1,575 / 1,191; gems, balloons and
  daggers save nothing (their columns stay 2 bytes: a column's time goes by whole bytes).
* **The budget** (`gen/budget.txt`'s last column, every column sprite but Trogg fast): 2 of the 36
  fit, median 44,016 (from 47,432). Adding the cheaper run-time moves (measured), chained scenery
  moves at 120, platforms swept at 127 too and one balloon or dagger at a time instead of three:
  8 fit, median 36,610. The turns (35 cycles a column, a third of a typical column's cost) and the
  number of objects in view are what's left.

### Trimmed columns (test/m1t_test.asm, tools/m1_trim_gen.py)

Each column swept only as far as it needs, by one data-driven routine for every sprite (the
timing is in `tools/m1_trim_gen.py`): an unrolled run of byte slots for each direction, each
column's data holding the address to jump into it (`JMP [,X++]`), so its length is its own;
columns going down and up share their ends, so the beam never jumps; the column count in timer
1's latch (`DEC <$06`); the slide across after each column's last bit. The first byte at 13 cycles
(not 12) puts up columns a pixel out against down ones, made up for in the data.

* **Choosing the lengths:** with whole bytes, a column's sweep is 8 x bytes + 3 pixels whichever
  way it goes, so where the ends fall is tied from column to column; picking each column's length
  greedily, left to right, left ~3.5 pixels of overshoot at each end and barely paid (Trogg -6%).
  `tools/trim_plan.py` instead finds the cheapest chain for a sprite by dynamic programming over
  where the beam is between columns, with **lead-ins**: entering the run part way through a slot's
  padding (0, 2, 4, 6 or 12 cycles before its store) starts a column's bits 0, 1, 2, 3 or 6 pixels
  later, free where a column has blank room at its start (a lead-in of 6 enters at the slot's
  `LDA ,X+`, so its first byte is in the data twice).
* **More runs don't help:** copies of the runs with a delay before the closing stores (4 copies,
  or 8 for any number of cycles: ~0.9KB and ~1.7KB of code) come out exactly as cheap as one run
  with lead-ins, by the same search: a delay is blank sweep at a column's end, a lead-in at its
  start, where columns often have room anyway.
* **Measured in vecx** (cycles with the call, full then trimmed; `preview/m1_trim.png`: the same
  pixel for pixel): Trogg 3,102 / 2,524 (-19%), Trogg climbing 2,403 / 2,056 (-14%), bulb 918 / 800
  (-13%), Poglet 2,751 / 2,441 (-11%), dagger 825 / 733 (-11%), Scrubbly 4,444 / 4,101 (-8%),
  Hooter 1,981 / 1,843 (-7%), gem 825 / 771 (-7%), ladder 2,443 / 2,292 (-6%), balloon 895 / 886,
  chain 1,653 / 1,676 (+1%). Exactly as worked out.
* **ROM:** the column sprites' data 3,812 bytes trimmed (with each column's entry address) against
  3,343; for clipping at the left edge, a start row (690 bytes) and a data offset (1,304) a column,
  or none if a sprite clipped at the left steps through the columns it skips (~25 cycles each).
  One routine (~160 lines) instead of one for each column height.
* **The budget** (`gen/budget.txt`'s last column): the median level 45,123 cycles (from 47,432), 1
  of 36 fitting; with the measured run-time moves, scenery moves at 120 and one balloon or dagger
  at a time, 38,315 and 5.

### Cave platforms as rows (test/m1c_test.asm, tools/m1_cave_gen.py)

The ledges drawn as more of their rows (black pixels): rows 0 and 1, the blank rows 2 and 3
skipped, rows 4 and 5, then every other row of the stalactites (7, 9, 11, 13). Back and forth, a
step down between rows (the sample-and-hold to 40 x the step, the ramp on for 4 cycles, back to 0
and the next row's speed). No clipping yet.

* **Looks:** like the ledges (`preview/m1_cave.png`: 2 rows, then 8, for 64, 128 and 206 pixels).
* **Costs, measured** (cycles, 2 rows then 8): 64 pixels 465 / 1,851; 128 pixels 721 / 2,875; 206
  pixels 1,041 / 4,155: 4 times as much, each row 16 cycles a byte + ~100 for its turn and set-up.
* **The budget:** 13 of the 36 levels have ledges; with them at 8 rows, the median level goes from
  45,123 to 49,295 (trimmed columns), the most on A_7 (+21,815), A_1 (+15,658), B_7 (+14,660).

### Zigzag sprites (test/m1z_test.asm, tools/m1_zig_gen.py)

The beam drifting down slowly and steadily (Y's sample-and-hold set once) while X flips back and
forth every row: one store each, as X is fed straight from the DAC. The shift register is written
every 16 cycles all the way through, so there are no turns: a sprite is one sweep, its time its
height x 160 / the drift. Straight-line code for each sprite's size (bytes through A and B in
turn, so loads have slack; the rows' speeds in U and Y, so a flip is `STU` or `STY` to port B).
Rows only as long as the lit pixels they cross; each flip as soon as the writes allow; each lit
pixel lighting the nearest bit (the converter follows the beam's real path).

* **Measured** (cycles with the call, columns then zigzag): Trogg 3,102 / 1,485 (-52%), Poglet
  2,751 / 1,437 (-48%), gem 825 / 397 (-52%), bulb 918 / 525 (-43%), Hooter 1,981 / 1,373 (-31%),
  Scrubbly 4,444 / 3,469 (-22%: a whole drift of 2, as 3 spreads its rows too far), ladder 2,443 /
  2,333 (-5%).
* **The model holds:** vecx's lit segments fit the converter's beam path best with the flips as
  modelled (mean distance under half a pixel).
* **But it looks rougher** (`preview/m1_zigzag.png`, columns then zigzag): neighbouring rows slant
  opposite ways (meeting at one end, up to 2 pixels apart at the other), so horizontal lines come
  out as chevrons (a herringbone: the ladder's rungs, Trogg's outline).
* **On a real Vectrex:** the drift is a small DAC value (2-6), so an offset in the DAC would change
  each sprite's height by a noticeable fraction (MAME's DAC offset changed drifting columns' width
  by ~8%); to be checked.

### A vector dagger (test/dagger.asm, tools/dagger.py)

A sharp V for the blade, a crossguard and a handle: one path of 6 vectors with vlist_d, no
blank moves, pointed any way from the same shape (`preview/dagger.png`: the raster dagger, then
vector daggers pointing right, left, up and down). Measured in vecx, not counting the move to it:

| | cycles |
|---|---|
| raster dagger (11 columns of 2 bytes, as drawn) | 825 |
| vector, speed 80 like the raster (scales 4-18: vlist_d's short path, ~115 a vector) | 692 (`preview/dagger_speed80.png`) |
| vector, every vector at scale 28 (vlist_d's long path, 82 a vector) | **533** |

At scale 28 the short lines (the guard) are drawn slowly, so they come out brighter than the
blade; the intensity could be turned down for daggers if that shows on a real Vectrex.

## Findings so far

* **The number of vectors costs much more than their length.** Drawing the scenery fast (dim) or
  slowly (bright) makes only a few percent difference: platforms and ladders are few, long lines.
* **Levels over a 20000-cycle drawing budget at their busiest window (of 55), 256-pixel window:**

  | | over budget | median |
  |---|---|---|
  | BIOS routines, current art (Trogg 37 vectors, Scrubbly 52) | 41 | 28106 |
  | `chain16` (51 a vector), BIOS reset and move (310 a shape) | 34 | 22342 |
  | ... and meanies of about 20 vectors | 23 | 18577 |
  | ... and moving between shapes for about 150 cycles instead of 310 | 13 | 16177 |

  The worst are the ones with rows of standing meanies (A_6: 23 Hooters; A_9: 13 Hooters, 26
  gems and 15 keys; E_7: 9 Scrubblies). Other ways out: plainer art for meanies that stand
  still, or 25 Hz on busy screens.
* **So next: cheaper moves between shapes** (from one shape to the next without going back to
  the centre each time, or with a cheaper reset), and line art in about 20 vectors.
* **The levels fit in a cartridge.** All 55 pack to 11.8KB in the BBC format.

Still to find out: whether the lag and the settling time are right (MAME's figures, not
measured), and which speeds look right, which needs a real Vectrex.
