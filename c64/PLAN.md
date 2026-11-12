# Plan: a playable A_1

Status: **milestones 1-4 done** (the data; Trogg shown; his movement and the keys; the camera),
with the CPU budget trimmed to 96% ready on Hard while the screen scrolls (see milestone 4). Each milestone is checked before the next, and this
file is updated as they're done.

## Scope

In:

- Trogg controlled from the keyboard (and joystick 2): walking, climbing, jumping and falling,
  with the BBC and CPC versions' physics.
- Trogg drawn on sprites 1 and 2.
- The yoyo, its string made of characters.
- A Scrubbly hit by the yoyo disappears (for now), what's behind it showing.
- The scroll follows Trogg.
- Death (landing at 1.6 pixels a tick or faster, or falling off the bottom) restarts the level:
  Trogg back at the start, the scroll back to the left, every Scrubbly back, the balloons and
  daggers gone. No checkpoints.

Not yet: collisions with balloons, daggers, gems and keys; checkpoints; sound.

## 1. The level's geometry, as the C64 draws it

The physics needs the platforms and ladders where the C64 shows them, not where the original
has them: the mock-up snapped platform pieces across to 8 pixels and their tops by up to 2 lines
onto the 4-line grid, and re-centred the ladders. `tools/mockup.mjs` exports A_1's 41 platforms
(x, y, width) and 19 ladders (x, y, height, extension) in the C64's coordinates, in the CPC
port's form, and Trogg's start (level (38, 208)).

Check: the exported rectangles drawn over the mock-up.

## 2. Trogg's movement

A port of the BBC version's `trogg_standing`, `trogg_falling` and `trogg_climbing`, with
`platform_find` and `ladder_find` (`../src/frak.asm`: 65C02, so mostly its few 65C02
instructions replaced), with the same exact arithmetic in twentieths of a pixel (a jump 25,
terminal speed 80, a ladder grabbed only while slower than 25) and the same debouncing.

Keys, read once a frame from CIA 1's keyboard matrix: Z / X walk, O / K climb and jump, Space
or P yoyo; joystick 2 as well.

Checked without VICE as the BBC version is (`../tools/emu/connections8.mjs`): the steamfrak
repository's transcription of the original's scripts, on the original's own room with its
objects moved to the C64's places, against the 6502 code itself on an interpreter, from every
start, holding every key.

Its cost is measured with `tools/profile.py`, not guessed. `platform_find` scans 41 platforms
and `ladder_find` 19 ladders; if that's too slow, tables by column (there's memory to spare).

## 3. The scroll follows Trogg

The demo's back-and-forth scroll is replaced by a camera with a dead zone, moving at most a
pixel a frame (Trogg's walking speed, so he can't outrun it). The pair flip and the fill stay
as they are. Turning round means filling the hidden pair for the other direction: the dead zone
must leave the fill time for that, so the refill time is measured and the dead zone sized from
it.

## 4. Trogg's sprites

Sprites 1 (hi-res black outline, in front) and 2 (multicolour infill, behind), 24 wide, 34 lines
high, so each used twice down him (`tools/trogg.mjs`):

- tick 37 sets up the first instance of each;
- one row tick in his lines 13-20 sets up the second (y + 21; the pointer to the lower block,
  written into the screen not being shown). The multiplexer reserves that tick.

His lines go into the rows' masks (bits 1 and 2), through the same edge-only row updates as the
multiplexed sprites. His frames (15 x 4 blocks x 64 bytes, about 3.8KB) go at `$6800`-`$76ff`
in the VIC bank. The pose follows his state (standing, walking, climbing, falling, yoyo) as the
CPC port chooses it. The 2-pixel snout trim stays for now.

Risk: two more sprites on 34 lines take time from the row tails, which have 21 cycles to spare
at the least now. Measured (`--slack`) before anything is built on it.

## 5. The yoyo

The logic is a port of `start_yoyo`, `yoyo_out`, `yoyo_back` and `yoyo_position` (1.3 pixels a
tick out, to 80, at y - 11). The yoyo itself is a virtual sprite in the multiplexer, first in
priority.

The string runs along one line of one 8x4 half, so it takes 4 string characters, a black line on
cyan at line 0, 1, 2 or 3, the same in both halves of the character (so one works in the tops'
screen and the bottoms'). The cells from Trogg's hand to the yoyo get the string character; the
part-cells at the ends are under his body and the yoyo sprite. Each frame's cells are put back
from the level map (`tops` / `bottoms`), so nothing is saved. The writes go to the pair shown, as
a short list applied in the border tick with the sprite buffers, so the string doesn't tear and
a pair flip moves it across. While it's out, what was in its cells (a ladder piece, a platform's
edge) shows as cyan.

Risk: room in the character sets. Set 0 is full (64 tops, 63 bottoms), set 1 has room (34, 25).
The packer reserves the 4 string characters in every set; if the bands then can't be shared out
between two sets, a third goes at `$7000` (each band can use any set).

## 6. Yoyoing a Scrubbly

The yoyo's square (as `yoyo_collide` makes it) against each Scrubbly's rectangle
(`build/scrub.json`). One that's hit has its virtual sprite hidden, and its cells changed to the
yoyoed-off version (what's behind it: the mock-up's `OFF=1`) in the level map, so later fills
use it, and in both screen pairs. Its glyphs must be in the character sets too: more of the
risk in 5. A restart puts the Scrubblies back.

## 7. A frame, and the budget

Keys, Trogg, the yoyo, the camera, the game (balloons, daggers, Scrubblies), sort, multiplexer;
then the border applies the string's cells, the scroll and the sprite buffers together.

The main program has about 9,000 cycles a frame: the multiplexer takes 3,100-4,200 on average
(Hard), the fill about 2,600, which leaves roughly 2,000-3,000 for the keys, Trogg and the yoyo.
`tools/profile.py` is extended to profile the whole frame, and the swap counter measures how
often everything is ready in time.

## Milestones

1. **Data** (done): the geometry exported, the string characters reserved, the yoyoed-off
   glyphs included, everything repacked. Check: the screenshots still match the mock-up.
   - `build/geometry.json` (by `mockup.mjs`): each platform at its piece's snapped place (each of
     the 41 is exactly one piece; its y is the piece's top line); each ladder's x the redrawn
     ladder's middle less 2, its top a line below its platform's top, its bottom as far from the
     top of the platform under it as in the original (8 above to 7 below); Trogg's start moved
     with his platform, (38, 208) to (41, 207). Moves: platforms by up to 4 across and -1 to +2
     down, ladders by -3 to +5 across. Drawn over the mock-up: the platforms' tops on their black
     top lines, the ladders on the drawn ladders.
   - `pack.mjs` packs the level and its yoyoed-off variant (`OFF=1 mockup.mjs`, now in
     `build.sh`) into the same sets, keeping characters 60-63 of each for the string (a black
     line at line 0-3 of both halves). Two sets still do: set 0 60 tops and 60 bottoms (full),
     set 1 46 and 38. Every cell of both variants is read back through its band's set as a
     check. `build/scrpatch.inc`: each Scrubbly's patch (27, 26, 26, 27, 27 cells: the 133 that
     differ, one to one).
   - The screenshots, scrolling, still match the mock-up on every row but the known ladder
     pixels (rows 17-19).
2. **Trogg shown, standing** (done): sprites, the second instance and pointer change, his rows in
   the masks. Check: against his mock-up; the row tails' slack measured; the frame checker
   covering his sprites.
   - Found on the way: the second instances show all 21 rows, so P2's rows 13-20 would show
     again below his feet. Now a third block per frame (P3: P2's rows 0-12, then blank),
     switched to in the next row's tick; `trogg.mjs` checks all 42 lines with both changes at
     every line they can fall on. 15 frames, 90 blocks, 5,760 bytes.
   - Memory: the program now runs on into the VIC bank (Trogg's blocks loaded straight to
     `$6800`) and past it (the level map from `$7e80`): fine from disk, too long for the stand-in
     ROMs, so tests attach `build/frak64.crt`, a Magic Desk cartridge image of the program that
     the stand-in KERNAL copies to RAM (which takes about 560,000 cycles, so the demo starts
     about 0.6s later in VICE than before).
   - `src/trogg.asm`: his settings worked out in the main program for the next frame and made
     his at the switch to it; tick 37 sets the first instances; his two rows have tails of their
     own (each tail in three kinds, from `build.mjs`), chosen by the multiplexer's row tables.
   - The multiplexer: his lines in the masks (as a virtual sprite of its own on bits 1 and 2), bit
     8 of his x in the registers, and no set-ups in the ticks of the rows whose tails run while
     he's drawn (five or six ticks): with only his own two kept free, a set-up just above him that
     changed the registers left a tail 2 cycles to spare and overran. Placing a sprite now also
     prefers a hardware sprite whose sprite before has the same settings (so its set-up changes no
     registers).
   - Checked: `tools/troggshot.py` finds him in a screenshot: exact (place and every pixel, and
     nothing below his feet) at all 8 phases of a row and near the top and bottom, in 15 cases
     (frames and heights), still and scrolling. The screen with him fetched in the right border
     (bit 8 set): all 24 shots match the mock-up. `tools/muxcheck.py` (the frame checker, now with
     Trogg): no problems in 30 frames at three heights. The row tails' least time to spare with
     him mid-screen on Insane: 12 cycles (the interrupt allows for up to 15 late; before him, 21).
     The multiplexer with him standing: Hard 4,000-4,200 cycles a frame on average, Insane
     3,700-5,600.
3. **Movement and keys** (done): the 6502 physics checked against the original's; a build with
   scripted keys for VICE runs. Restarting the level on death.
   - `src/play.asm`: the BBC version's movement as plain 6502 (A_1 has no moving or bouncy
     platforms, so those parts are left out; the yoyo's key is read but not used yet); the keys
     from the keyboard matrix (Z / X, O / K, P / Space) and joystick 2; a game tick a frame;
     death restarts the level after a second. The scroll is held at the left till the camera
     (`--scrolldemo` for the old back and forth).
   - The geometry: each ladder now moves with the platform it hangs from, keeping the original's
     height (its bottom moves up to 3 pixels against the platform below it; every one that ended
     above or below it still does), so the physics sees the original's objects moved.
   - `tools/conn64.mjs`: the steamfrak repository's `connections.js` (the original's scripts
     transcribed, with GameMaker's epsilon comparisons) on a copy of A_1's room with every
     platform and ladder moved to the C64's place, against the C64's 6502 code on the BBC
     version's 6502 interpreter: all 10,484 starts end the same way, all 140 connections the same
     (and a jump speed of 24 instead of 25 shows up as 852 starts that differ).
   - `tools/keytest.py`: a key script (`build.mjs --keys`) played by the program's own game tick
     in py65 and in VICE: the same place and state in both, and `troggshot.py` finds him drawn
     exactly there; five scripts (climbing up, stopping halfway, walking, a jump, two deaths and
     restarts).
   - Cost of a game tick: `platform_find` looked at all 41 platforms, 1,700 of 2,600 cycles; now
     only those over his 8-pixel column (tables by column from `build.mjs`, and the ladders too),
     the same results: a tick 1,100-1,450 cycles (437 of them reading the keyboard). With him
     climbing up and down the row tails' least time to spare is 36 cycles, and the frame checker
     finds no problems.
4. **Camera** (done, but see the budget): the scroll following him, turning round included, with
   the fill keeping up.
   - `frak64.asm`'s `camera`: Trogg kept between 112 and 192 across the screen, the scroll a pixel
     a frame when he's past one end; the hidden pair filled for the next column on his side of the
     middle (and refilled when he turns); the scroll waiting if it isn't ready. A restart jumps
     back to the start (column 0 filled, then shown; Trogg hidden meanwhile). The old scrolling
     demo: `--scrolldemo`.
   - Space below `$4000` ran out: the multiplexer's and the physics' tables now go past the level
     map (a 64tass section, `high`).
   - Checked: key scripts walking him right (the scroll to 31) and back (a fall, a restart, the
     camera back to 0): the same in py65 and VICE, him exact on the screen, and every row but his
     matching the mock-up. `--camtest` walks him across the level and back, turning ten times
     (his movement still worked out each tick, for its cost): over 720 frames the scroll goes 0 to
     165, back to 144 and on, every row but his matching the mock-up in 24 shots; the frame checker
     finds no problems; no row tail overran (21 cycles to spare at the least).
   - **The budget**: scrolling all the time, the multiplexer is ready for 80% of frames on Hard
     (61% on Insane), and the camera waits for the fill in 16% of frames on Hard. Measured: the
     main program gets roughly 6,000-7,000 cycles a frame (the rows' interrupts take most of the
     frame, about 330 cycles a row); a frame's work is about 5,200 (Hard: the multiplexer about
     2,800, keys and movement about 1,300, Trogg's settings and his part of the multiplexer about
     600, the camera 100) and the fill another 3,300 (1,055 cycles a row, 25 rows a column, a
     column every 8 frames).
   - **Main-program trims** (budget option 1): the sort's in-order fast path, the keys read once
     into a byte, hidden sprites skipped quickly, x and y written straight into the buffer being
     made, Trogg's part of the multiplexer and his pointers only redone when they change, and the
     fill starting at column 3 (the columns the border covers left out). Measured on Hard,
     scrolling all the time: the multiplexer ready for **96.1%** of frames (was 80.2%), the camera
     waiting for the fill in 20.7% of frames (it moves on sooner, so asks more often); a frame's
     work about 4,800 cycles (3,800-6,300), the fill 989 cycles a row. The frame checker finds no
     problems. What's left is the fill's rate when he walks without stopping; skipping empty rows
     would hardly help (1.35 of a window's 25 rows are empty on average, 4 at most).
     The fill's loop unrolled once (columns 2-39 taken in twos) with its addresses from tables:
     956 cycles a row (was 989); the camera waits in 19.4% of frames; the screenshots the same.
   - **The column renderer** (src/jit.asm): each map column compiled, when first needed, into
     code that writes it to a screen column, a value at a time (lda #value, then sta to each cell
     with it; A_1's columns have 9 values on average, and 3 cells in 4 are 0), kept in a cache of
     40 columns with both pairs' code (80 pages: from the program's end, and under the KERNAL).
     Measured: a column drawn in about 340 cycles (279 the code, 59 the call), a compile about
     4,900, one a column the screen moves; a screen's fill about 12,800 cycles plus the compile,
     against 23,900. A compile gives way to a frame's work between values. Hard, scrolling all
     the time: the multiplexer ready for 95.5% of frames, the camera waiting in 10.9% (was 19.4%).
     A changed column (jdirty) is compiled again when next drawn.
5. **Yoyo**: the string and the yoyo, then knocking a Scrubbly off.
6. **Budget**: the whole frame profiled, readiness and slack measured with everything running,
   and whatever that shows fixed.

## Unknowns, measured early rather than guessed

- The budget with the screen scrolling (milestone 4): after the trims, the multiplexer is ready
  for 96% of frames on Hard scrolling all the time; the camera lags the fill about a fifth of
  the time then. Insane is taken to be out of the C64's reach.

- The row tails' slack with Trogg's sprites: 12 cycles at the least, with his rows' ticks left
  alone (milestone 2). Little margin: to watch when he moves.
- Whether two character sets still do, with the string and yoyoed-off glyphs: yes, but set 0 is
  full again, so any more glyphs would mean a third set.
- What the physics costs: 1,100-1,450 cycles a tick (milestone 3).
- How long the fill takes after turning round, and so the dead zone (milestone 4).
