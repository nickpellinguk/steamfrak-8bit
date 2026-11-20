# Plan: a vertical-scrolling Frak! for the Atari VCS (2600)

Status: **planning only.** Nothing is built yet. This is a design for a new game in the spirit of
Frak!, made for the 2600's strengths. It is not a port of the Steam levels.

## The idea

The 2600 can't hold Frak!'s levels: 128 bytes of RAM, no frame buffer, a 20-bit background
mirrored or repeated across the screen, and two 8-pixel sprites. Converting the levels as they
are is out of the question. What the console does well, and cheaply, is **smooth vertical
scrolling**. So this version is a game of **tall towers**, each climbed from the bottom to the top,
built from Frak!'s mechanics as intricate spatial puzzles:

* Ladders you can't use the yoyo from.
* Meanies you can reach from one side but not the other.
* Timing puzzles: patrols, climbers, jumpers, moving platforms, falling daggers.
* Long falls kill, so a tall tower makes every drop a decision.

It should be surprising, fun and still obviously Frak!: Trogg, gems, the key, the meanies, the
yoyo, the "FRAK!" on death, the timer and medals.

`preview/mock_A_1.png` (made by `tools/mock.py` from the Steam data for room_A_1) shows the look:
a 160x192 screen, blocky background ledges with a yellow top line, ladders as rungs, and
hand-drawn 8-bit Trogg and Scrubblies. Its layout is a horizontal level and is for the look only.

## Levels

* **A level is 256 rows of 2 scanlines** (512 scanlines). Every height in the game (Trogg, meanies,
  pickups, daggers, the camera) is one byte, 0-255.
* **The screen shows 96 rows** (192 scanlines), so a tower is about 2⅔ screens. The camera runs
  from row 0 (top) to row 160 and follows Trogg one row at a time, leading slightly in the direction
  he's moving so the next puzzle is seen before he reaches it.
* **Trogg starts at the bottom and climbs to an exit at the top.** A key partway up is the
  checkpoint, as in the Steam version (gems collected since come back on death).
* **About 12 towers**, each around 60-100 bytes of band data.
* Medals for time, gems and rating, with the timer on a score line at the bottom.

### Level 1: FRAK, spelled vertically

The letters are made of ledges, stacked from F at the bottom (rows 192-255, where Trogg starts) to
K at the top (rows 0-63), 64 rows each. The screen shows about one and a half letters, so the word
reveals itself as the player climbs. Each letter introduces a mechanic:

* **F:** climbing and gems.
* **R:** a Scrubbly you have to come at from its reachable side.
* **A:** a ladder up the middle where the yoyo can't be used, with a Poglet on it.
* **K:** a Hooter on the diagonal, the key, and the exit at the top.

## The kernel

* **A two-line kernel**: each row is a pair of scanlines (152 cycles). One line updates the sprites,
  the other the background.
* **An asymmetric background**: PF0/PF1/PF2 are written for the left half and rewritten mid-line
  for the right half, each write in its window of cycles. Bands that don't reach the screen's
  edges skip the PF0 writes.
* **A dictionary of row patterns**: up to 256 patterns, stored as six page-aligned tables
  (LeftPF0, LeftPF1, LeftPF2, RightPF0, RightPF1, RightPF2), so one index in X reads all six with
  `lda Table,x` and never crosses a page.
* **Each tower is a list of bands**: (pattern index, row count). The kernel loads X once per band.
  Scrolling is just starting partway into the band list, so it costs nothing extra.
* **The converter** (a Python tool, as for the other ports) draws each tower from a text or
  image source, collects the unique rows into the dictionary and emits the band lists.

## Objects and sprites

* **Trogg** is player 0 in every band, single width, one colour per line.
* **Meanies** are player 1, repositioned per band, double width. **The rule is one meanie per
  band**, by level design. If two things want player 1 in a band, they flicker on alternate frames.
* **Gems and keys** are the ball (or player 1 where it's free), colour-cycled.
* **Daggers** are a missile stretched a few lines tall. **Balloons** are player 1 in empty bands,
  or the ball.
* **The yoyo** is missile 0 (Trogg's colour). **Its string** is drawn on Trogg's hand line,
  either as background blocks out to the yoyo or as a stretched missile and its copies. **The yoyo
  and its string flicker on alternate frames** (30Hz each), so the hand line never has to draw both.
* **Collisions come from the TIA's collision registers**: yoyo against meanie, meanie against
  Trogg, Trogg's feet against the background.

## RAM (128 bytes)

Almost nothing is stored. State is either one bit or worked out each frame from ROM and the frame
counter.

| What | Bytes | How |
|---|---|---|
| Stack | 4-6 | Shallow calls only |
| Kernel temporaries | ~12 | Sprite pointers, band pointer, rows left in the band |
| Frame counter, camera, level number | 3 | All one byte |
| Trogg | 4 | X, row, state, vertical speed |
| Yoyo | 2 | Length out, going out or coming back |
| Gems and keys | 4 | A bitfield: up to 32 pickups per tower |
| Meanies | 4-8 | A "knocked away" bit each, plus 1-2 bytes for one flying off |
| Daggers and balloons | 6 | At most two at once: X, row, type |
| Timer | 3 | |
| Sound and music | 4-6 | |
| Checkpoint | 6 | Trogg's position and a copy of the gem bits |
| **Total** | **~65-70** | About 60 bytes to spare |

* **Meanies have no stored position.** Their movement is a fixed pattern, worked out each frame
  from ROM (start, range, speed) and the frame counter, e.g. `x = start + triangle(frame * speed)`.
  So their rhythms stay in step forever, and timing puzzles are reliable and learnable.
* **Only on-screen objects are processed.** ROM lists each object's row. Each frame the code
  walks the list and handles the two or three on screen.
* **Pickups are bits.** Positions are in ROM. A checkpoint copies the bits, so gems coming back on
  death is a 4-byte copy.
* **Daggers and balloons are capped at two.** A new one appears only when a slot frees up.

## The console

* The **difficulty switches** pick Easy and Insane.
* The **Colour/B&W switch** could give an outline-only "Vectrex mode", as a nod to that port.
* **"FRAK!"** on death: a big chunky background word for a second and a harsh TIA noise.

## Tools and target

* **Assembler:** `dasm`. **Emulator:** Stella, whose debugger shows the cycle and scanline of
  every instruction.
* **Cartridge:** 4K to start, 8K (F8 bank switching) for the full set of towers and music.

## Milestones

1. **The kernel**: a static screen from a band list with an asymmetric background, Trogg drawn in
   it, in Stella.
2. **Scrolling**: a 256-row test tower, with the camera following a joystick-driven Trogg.
3. **Movement**: Trogg walks, jumps, falls (dying from long falls) and climbs, with ledge
   collisions from the TIA.
4. **Meanies and pickups**: patterned Scrubblies, Poglets and Hooters, one per band; gems, the key
   and the checkpoint.
5. **The yoyo**: missile, flickering string, knocking meanies away; no yoyo on ladders.
6. **Daggers, balloons, "FRAK!", the timer and medals.**
7. **The FRAK tower and the other towers**, the converter, sound and music.
