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
| `tools/render_capture.py` | Renders what beamshot wrote down through the beam model (`preview/timing_vecx.png`), or with `--plain` as vecx and MAME show it. |
| `test/timing.asm` | A cartridge that draws with the BIOS's routines and with a loop of its own, for measuring what each costs (`asm6809 -B -o timing.bin timing.asm`). |

asm6809 is built in `/opt/frak-tools/asm6809/bin/` by the Frak ports environment's setup script.

```sh
vectrex/emu/build.sh
(cd vectrex/test && /opt/frak-tools/asm6809/bin/asm6809 -B -o timing.bin timing.asm)
vectrex/emu/vecx/beamshot vectrex/emu/vecx/rom.dat vectrex/test/timing.bin 1000 1 capture.txt
python3 vectrex/tools/render_capture.py capture.txt timing.png
python3 vectrex/tools/budget.py ../steamfrak
python3 vectrex/tools/artsheet.py ../steamfrak vectrex/preview/artsheet.png
python3 vectrex/tools/scene.py --steamfrak ../steamfrak --level room_A_1 --scenery-speed 127 --out a1.png
```

## What the emulators do about brightness

vecx and MAME both set a line's brightness from the intensity register alone, not the beam's
speed, and neither shows the dots where the beam dwells. Hence `beam.py`, and the patch to vecx.

## What drawing costs (measured in vecx with test/timing.asm)

vecx's beam units are DAC value x cycles: a vector with dx = 16 at scale 8 is 128 units long.

| | cycles per vector, start to start | spot on, standing still |
|---|---|---|
| BIOS `Draw_VLc` at scale $08 | 81 = 8 moving + 73 | 19 (4 before moving, 15 after) |
| BIOS `Draw_VLc` at scale $20 | 102 = 32 moving + 70 | 16 |
| `draw16` (timing.asm: the same steps, without the BIOS's extras) | 78 | 20 |
| a separate dot: `Reset0Ref`, `Moveto_d` at scale $7F, `Draw_Line_d` | about 390 | |

* A long line (`Draw_Line_d` at scale $FF) comes out as one line: vecx doesn't break lines up.
  (The BIOS's start-up screen is drawn dashed.)
* Most of a vector's cost is setting it up and waiting for the timer by polling it, so a loop
  that polls, like `draw16`, saves almost nothing. Saving time means code that counts cycles
  instead (and does the next vector's work while the beam moves, where it can).
* The spot stays on, standing still, for about 19 cycles at each vertex: the bright dots at the
  ends of lines. With short vectors (5-10 cycles of movement) the vertices get more energy than
  the lines between them, which `beam.py` shows as beads. Faster code that only turns the spot on
  while the beam moves would also look better.

## Findings so far

* **The number of vectors costs much more than their length.** Drawing the scenery fast (dim) or
  slowly (bright) makes only a few percent difference: platforms and ladders are few, long lines.
* **With the BIOS's routines and the current art, about three quarters of the levels go over a
  20000-cycle drawing budget at their busiest** (A_1's start is about 133% of a whole frame).
  The worst are the ones with rows of standing meanies (A_6: 23 Hooters; A_9: 13 Hooters, 26 gems
  and 15 keys; E_7: 9 Scrubblies).
* **With faster drawing code** (an estimated 35 cycles a vector and 120 a shape, not yet written
  or measured) the median level fits; **with that and meanies of about 20 vectors**, all but 5
  levels fit (A_6 is still about 150%). Other ways out: plainer art for meanies that stand still,
  moving from one shape to the next without going back to the centre, or 25 Hz on busy screens.
* **The levels fit in a cartridge.** All 55 pack to 11.8KB in the BBC format.

Still to find out: which speeds look right, which needs a real Vectrex.
