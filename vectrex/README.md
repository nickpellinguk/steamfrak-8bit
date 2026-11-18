# Frak! for the Vectrex: feasibility

Not a port yet: tools for deciding what a Vectrex version could draw, and first line art.

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
| **`chain16`** (chain.asm: counting cycles, scale 16) | **67** | 16 | **0 / 1** |
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
* A routine that counts cycles works for one scale. At a fixed scale a vector's speed, and so its
  brightness, goes with its length: long segments come out dimmer than short ones. Line art
  for it should keep its segments similar lengths, or long ones split.

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
