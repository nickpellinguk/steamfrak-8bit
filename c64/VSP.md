# Design: scrolling with VSP (DMA delay), designed against the VSP crash

Status: **design**, nothing built yet. Replaces the column fill as the way the screen scrolls by
whole characters. Sources: Christian Bauer's VIC-II article (sections 3.7.2, 3.14.6) and Linus
Åkesson's "Safe VSP" (2013).

## 1. The mechanism

If a bad line is forced (YSCROLL made equal to the raster line's low 3 bits) in cycles 15-53 of a
line while the VIC is idle, the VIC starts fetching n cycles late (n = write cycle - 14), so VC
(the video counter) counts only 40 - n in that line. If RC (the row counter) is 7 then, as it is
before the first bad line of the frame, VCBASE takes that value at cycle 58, and every row after
it starts from it: the whole screen shows memory from 40 - n on. Nothing is copied.

For us:

- **Where:** raster line 50, in the top border, one line before row 0's bad line at 51. Its
  garbage is never seen; row 0's bad line then starts at VC = VCBASE = 40 - n.
- **The FLI is unaffected:** the forced bad line at line 4 of each row reuses the row's VC, so the
  bottoms screens shift with the tops. The FLI bug's $ff stays in screen columns 0-2 (VMLI 0-2),
  under the cover sprite.
- **Colour RAM** is all black, so its shift doesn't matter.

## 2. The range: 17 positions, 25 rows kept

The VIC shows 1,000 bytes from offset s = 40 - n. Bytes $3f8-$3ff are the sprite pointers, written
by the multiplexer; they'd be shown (in row 24) once s ≥ 17. So s runs 0-16: no DMA delay for 0,
n = 39 down to 24 (the $d011 write on cycle 53 down to 38) for 1-16. Bytes $3e8-$3f7 become
ordinary screen cells.

A 24-row screen would allow all 40 positions (0-39), but A_1's rows 0 and 24 both have content
(12 and 24 of 94 columns), and the wider range only makes re-centring (below) rarer: about 150
cycles a frame while walking instead of about 375. **Keep 25 rows.**

## 3. The screen as a sliding window

With the screen at map column w and offset s, map cell (row r, column m) is shown from address
s + 40r + (m - w) in each screen of the pair. Keeping K = s - w fixed, each cell has a fixed
address, K + 40r + m: a coarse step is just s ± 1, and one new column to write:

- **Walking right** (s + 1): the new right-hand column. Before the step its cells are shown as
  column 0 of the row below, under the cover sprite, so they can be written before the step with
  nothing seen. 25 cells in the tops screen, 25 in the bottoms.
- **Walking left** (s - 1): the new left-hand column. Before the step its cells are shown as
  column 39 of the row above; in 38-column mode that column is under the right border at the
  step's XSCROLL (**to check in VICE**). If it isn't, the writes go in after the raster's passed.

**Re-centring.** When s would leave 0-16, the display swaps to the other pair, filled for the
same view with s = 8, and the pair it leaves is refilled in the background for the next swap.
That's today's full fill (about 24,000 cycles), but spread over the 8 steps to the next possible
swap, about 3,000 cycles a step, while the shown pair takes only its columns. Turning round
doesn't force a swap; a swap at an edge always lands in the middle, so swaps are at least 8
steps apart.

**Cost while walking** (estimates, to be measured): new columns about 100 writes a step (both
pairs), re-centring about 3,000 a step, so roughly 4,500 a step or 560 a frame, against about
3,000 a frame now. Standing still costs only the VSP wait (section 4).

## 4. Timing

- The `$d011` write must land on cycle 14 + n of line 50, n varying each frame. The nearest tick
  of the row timer is tick 38 at line 45; from there, after its usual lateness correction, a
  variable delay (a jump into a slide) reaches the write. About 5 lines, 320 cycles, of waiting
  a frame, less whatever of tick 38's work can be moved into it.
- Sprite DMA on lines 45-50 (sprites shown at the top) steals cycles; the delay allows for it as
  the row tails do now (from the sprites shown on those lines).
- Afterwards, YSCROLL back to 3 before line 51's cycle 12, so row 0's bad line happens as now.
- The DMA-delay line takes 43 - n cycles (at most 19) from the CPU.
- `scrx`'s coarse part becomes s and K; XSCROLL as now; the change of s goes with the scroll's
  other changes at tick 25, so it's seen from the next frame's line 50.

## 5. The VSP crash

**The cause** (Åkesson): at the trigger, the VIC first puts the idle fetch's address on the bus
(low byte $ff), then switches to the display fetch's. If the low byte changes, the DRAM can latch
it while it's in between; the row latch goes metastable and connects several rows to the sense
lines. Bits of "fragile" bytes (any address ending in 7 or f, in any page of RAM, banked in or
not) can then take the value of the same bit in another fragile byte of the same page. It depends
on the machine, its temperature and its power-on state; many machines never do it.

**The design: make the address not change.** The display fetch after the switch is a character
fetch: in ECM text mode, its low byte is ((char & 31) << 3) | RC. At line 50, RC is 7 (idle since
row 24), and the character is the first in the VIC's line buffer (VMLI is cleared at cycle 14 and
doesn't move while idle). In our display that character is always $ff: the last bad line before
line 50 is row 24's forced FLI line, whose first three fetches read $ff (the FLI bug), and the
DMA-delay line's own first fetches read $ff too. So the display fetch's low byte is
((63 & 31) << 3) | 7 = $ff, the same as the idle fetch's ($39ff in ECM): no bit of the row address
changes, nothing to latch in between. This also fits history: in plain character-mode VSP (as in
the games that crashed), the first character is whatever the screen holds, usually not $xf.

This is a deduction from Åkesson's explanation, not something VICE can show (it emulates the
VSP, not the crash). So:

1. **Proof on real hardware.** A test program that does VSP every frame with every fragile byte
   of a few test pages holding different patterns, and counts changes. Two variants: the
   ordinary one (first character 0: the address changes), to show the machine is prone, and ours
   (first character $ff). Overnight runs on a machine the first variant corrupts. If no machine
   to hand is prone, this stays unproven, and we say so.
2. **Kept true in the code.** A check in the frame code (debug builds) that line 50 is reached
   with the conditions met: ECM on, RC 7 (no bad line since row 24), the first fetch of row 24's
   last bad line made by the FLI bug.
3. **Fallback if it fails:** Åkesson's discipline, every page's fragile bytes identical or
   unused at the trigger: zero page and variables allocated around them, the stack saved and
   evened out around the trigger (about 600 cycles, partly in the wait), code laid out with a
   `nop` (or a skipped operand) on every fragile byte, and the graphics restored from safe
   copies. Estimated at 15-25% more memory and 2,500-3,000 cycles a frame, about what VSP
   saves, so if it comes to that, VSP isn't worth it here.

## 6. Steps

1. **VICE proof of the mechanism:** a build option (`--vsp N`) that applies a fixed offset s,
   0-16, to the current display; screenshots checked against the screen memory shown from
   offset s, all 17 offsets, with sprites. Also check column 39 under the right border.
2. **Hardware crash test** (section 5.1), as a separate small program, for whoever has a prone
   machine.
3. **The scroller:** fixed-address cells, column writes, re-centring between the pairs, the
   camera's coarse position as s and K.
4. **Measure** against the current fill (readiness and camera waits in the camera test).
