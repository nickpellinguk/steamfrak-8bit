# Plan: a vertical-scrolling Frak! for the Atari VCS (2600)

Status: **planning only.** Nothing is built yet. This is a design for a new game in the spirit of
Frak!, made for the 2600's strengths. It is not a port of the Steam levels.

## Current direction (revised)

The experiments in `test/` (see the scripts' docstrings) showed that vertical scrolling, compiled
per-row code, retriggered multi-object rows and per-line pointer reads all together run about 30%
past what the 2600 can do, and only work as a one- or two-screen demo: the tower test
(`test/tower.py`) needed 16K for two screens and still had unschedulable rows. So the design is
being scaled back:

* **Single-screen rooms, no vertical scrolling.** Everything below about towers, scrolling, tiles
  and the 256-row level format is the earlier design, kept for reference until this plan is
  rewritten.
* **A screen is a list of calls to reusable sections** (band routines), each customised by a
  parameter and small tables, e.g.
      LDX #0 : JSR Section1
      LDX #0 : JSR Section2
      LDX #4 : JSR Section3
      LDX #4 : JSR Section3
  so a room costs a few bytes of calls and a level type (sections, graphics, rooms, game logic)
  fits in a 4K bank.
* Sections place objects with **sleds** (`JMP (ptr)` into runs of `CMP #$C9`, ending `$C5 $EA`,
  one cycle per entry byte, using no registers) and one-sided platform rows by switching `COLUPF`
  at the centre of the line (`test/halfpf_test.py`).
* The dagger is dropped (missile 1 follows NUSIZ1's copies, so it would be doubled).

## Row skeleton

Every row is two scanlines, with the same fixed frame in every section. Trogg is player 0, read
through a pointer that is advanced once per row; the yoyo is missile 0, switched on by the front
pixel (bit 0) of Trogg's row, so it needs no table of its own.

    ; even line
            sta WSYNC
            inc TrogPtr          ; 5   next row of Trogg (in the horizontal blank)
            ...section...
            ldy #0               ; 2   (only if the section used Y)
            lda (TrogPtr),y      ; 5
            sta GRP0             ; 3   Trogg's graphics, shown from the odd line on
    ; odd line
            sta WSYNC            ;     (doesn't change A)
            asl                  ; 2   bit 0 (front pixel) -> bit 1
            sta ENAM0            ; 3   yoyo enable, in the horizontal blank
            ...section...
            ...right-hand side free: the section's loop, or RTS / LDX #n / JSR to the next section

What it costs and gives:

* **About 20 cycles per row** for Trogg and the yoyo: 5 at the start of the even line, 8-10 at
  its end, 5 at the start of the odd line.
* **X and Y are free for sections** (Y is reset to 0 before the even line's Trogg read if the
  section used it). A is only held across the odd line's `STA WSYNC`, so the section must not use
  A between the Trogg read and that `WSYNC`.
* **The odd line's right-hand side is free** for flow control: the section's loop branch, or the
  transition to the next section (`RTS` 6 + `LDX #n` 2 + `JSR` 6 = 14 cycles, plus the next
  section's entry setup).
* **The yoyo enable lands in the horizontal blank,** so the yoyo's row is never cut partway across
  wherever it is horizontally. Missile 0 is positioned once per frame; when the yoyo isn't out,
  `RESMP0` parks it inside Trogg (in his colour).

Rules that follow:

* **Trogg's graphics change between the even and odd lines,** so each of his 2-line rows is drawn
  on an odd line and the following even line: a consistent one-line offset.
* **The even line's `GRP0` store comes late,** so it must land after Trogg has been drawn on that
  line; otherwise his row splits partway across. That is fine unless he is at the far right (about
  x > 120 for a double-width Trogg), where a section has to make the store earlier or accept a
  one-line split.
* **The `INC` uses 5 cycles of the even line's horizontal blank,** competing with left-half
  playfield writes (left `PF0` by cycle 22, `PF1` by 27, `PF2` by 38) and early strobes.
* **Trogg's pointer must not wrap:** `INC` only changes the low byte, so his strip is laid out in
  one page with the pointer's low byte starting low enough (0-159) that 96 rows never pass $FF.
* **Only the walking frame's hand row may have its front pixel (bit 0) lit;** the climbing frame
  keeps bit 0 clear on every row (no yoyo on ladders).
* **Any other per-row pointer object** (a balloon enable, a vertical mover) needs its own advance,
  5 cycles per row each, so they are kept few.

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
* **About 12 towers**, each 64 bytes of tile numbers, plus its objects and Trogg's start.
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
* **An asymmetric background, from one set of tables for both halves**: the background is used
  in "repeat" mode (not mirrored), where the right half is drawn from PF0/PF1/PF2 in the same bit
  order as the left. So one 20-bit **half-row pattern** looks the same on either side. Each row
  writes PF0/PF1/PF2 for the left half, then rewrites them mid-line for the right half, each write
  in its window of cycles.
* **A dictionary of half-row patterns**: up to 256, stored as three page-aligned tables (PF0, PF1,
  PF2: 768 bytes), so one index in X reads all three with `lda Table,x` and never crosses a page.
  The kernel loads X with the left index, does the left writes, reloads X with the right index
  (from RAM, 3 cycles) and does the right writes. Pattern 0 is empty. Half-patterns recur a lot in
  Frak!-style layouts (short ledges, on either side), so far fewer are needed than whole rows.
* **Tiles**: a tile is **4 rows**, each with a left and a right half-pattern index: 8 bytes. Up to
  about 64 tiles (512 bytes), shared by all the towers.
* **A tower is 64 tile numbers** (256 rows / 4): **64 bytes**, whatever the layout. The kernel
  points at the next tile every 4 rows and reads each row's two indices by the row's place in the
  tile. Scrolling starts the screen partway into a tile, which the fixed 4-row rhythm makes easy.
* **Vertical positions are not rounded off.** Every row in a tile has its own indices, so a ledge
  can start on any row and be any number of rows thick; a ledge that crosses a tile boundary is
  just two tiles. Odd offsets only cost more distinct tiles. This matters: the C64 and 800XL ports
  showed that part of Frak!'s spatial charm is platforms not on character boundaries (even half a
  character was enough), and rows here (2 scanlines) are finer than that.
* **Horizontally the background is a grid** of 4-pixel blocks, 20 per half: the same width as a
  C64 multicolour character, with no half-blocks. To keep the off-grid feel anyway: stagger ledges
  vertically (free), offset neighbouring ledges by a block, use the ball or a missile for a fine
  ledge end at a special moment, and draw moving platforms with player 1 (any pixel). A ledge
  across the centre line is two half-patterns that meet.
* **The converter** (a Python tool, as for the other ports) takes each tower drawn at full row
  resolution (from a text or image source), splits each row into its two halves, collects the
  unique half-rows into the dictionary, cuts the rows into 4-row tiles, collects the unique tiles,
  and emits the tables, the tiles and each tower's 64 tile numbers. The designer never thinks in
  tiles.
* **Graphics data in all**: about 1.3K (patterns and tiles) plus 64 bytes per tower.

## Objects and sprites

A **strip** below is a horizontal stretch of the screen in which a sprite keeps one position
(sprites are repositioned between strips).

* **Trogg** is player 0 in every strip, single width, one colour per line.
* **Meanies** are player 1, repositioned per strip, double width. **The rule is one meanie per
  strip**, by level design. If two things want player 1 in a strip, they flicker on alternate frames.
* **Gems and keys** are the ball (or player 1 where it's free), colour-cycled.
* **Daggers** are a missile stretched a few lines tall. **Balloons** are player 1 in empty strips,
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
| Kernel temporaries | ~12 | Sprite pointers, tile pointer, row in the tile, right index |
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

1. **The kernel**: a static screen from a tower's tile numbers, with the asymmetric background, Trogg drawn in
   it, in Stella.
2. **Scrolling**: a 256-row test tower, with the camera following a joystick-driven Trogg.
3. **Movement**: Trogg walks, jumps, falls (dying from long falls) and climbs, with ledge
   collisions from the TIA.
4. **Meanies and pickups**: patterned Scrubblies, Poglets and Hooters, one per strip; gems, the key
   and the checkpoint.
5. **The yoyo**: missile, flickering string, knocking meanies away; no yoyo on ladders.
6. **Daggers, balloons, "FRAK!", the timer and medals.**
7. **The FRAK tower and the other towers**, the converter, sound and music.
