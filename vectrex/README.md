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
