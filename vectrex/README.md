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
| `emu/` | `beam.patch` for vecx (an open-source Vectrex emulator, GPL v3) so it reports how long the beam took over each line; `beamshot.c`, a front end that runs it without a window and writes the lines down for `beam.py` to render; and `build.sh`, which fetches vecx at a fixed commit, patches it and builds it. **Not built or tested yet.** |

```sh
python3 vectrex/tools/budget.py ../steamfrak
python3 vectrex/tools/artsheet.py ../steamfrak vectrex/preview/artsheet.png
python3 vectrex/tools/scene.py --steamfrak ../steamfrak --level room_A_1 --scenery-speed 127 --out a1.png
```

## What the emulators do about brightness

vecx and MAME both set a line's brightness from the intensity register alone, not the beam's
speed, and neither shows the dots where the beam dwells. Hence `beam.py`, and the patch to vecx.

## Findings so far (estimates)

* **The number of vectors costs more than their length.** With a guessed 40 cycles of setup per
  vector, the setup is most of the cost; drawing the scenery fast (dim) or slowly (bright) makes
  only a few percent difference, as platforms and ladders are few, long lines.
* **What's expensive is many small detailed things on screen at once.** With the current art,
  about half the levels go over a 20000-cycle drawing budget at their busiest window; the worst
  are the ones with rows of standing meanies (A_6: 23 Hooters; A_9: 13 Hooters, 26 gems and 15
  keys; E_7: 9 Scrubblies). Ways out: simpler art for meanies that stand still (or a
  plainer version when many are on screen), fewer vectors per shape, sharing one reset between
  neighbouring shapes, faster drawing code than the BIOS's, or dropping to 25 Hz on busy screens.
* **The levels fit in a cartridge.** All 55 pack to 11.8KB in the BBC format.

The next things to pin down are the real per-vector and reset costs (a timed test program), and
which speeds look right (which needs a real Vectrex).
