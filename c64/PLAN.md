# Plan: a playable A_1

Status: **part 1 done, part 2 under way (milestones 7-12 done)** (milestones 1-5: the data; Trogg shown; his movement and the keys; the
camera, scrolling by VSP; the yoyo and knocking Scrubblies off): 95.7% of frames ready on Hard
scrolling all the time, the camera never waiting; packed onto `build/frak64.d64`. **Part 2**
(below): A_1 played as the BBC version plays it. Each milestone is checked before the next, and
this file is updated as they're done.

The exit milestone is A_1 playable on a PAL C64: in VICE's `x64sc` (the reference: the other
accurate emulators, Hoxs64, Denise and Micro64, and FPGA machines should do, untested), from
`build/frak64.d64`.

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

Not yet (part 2, below): collisions with balloons, daggers, gems and keys; sound. No
checkpoints.

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
     (Tried and taken out: a column renderer, each map column compiled into a cache of 40 slots
     of code, lda #value, sta cell,x for each cell, a copy per screen pair. A screen's fill about
     17,100 cycles against 23,900, the camera waiting in 10% of frames, but 20.9K of RAM: the
     cache can't be smaller than a screen's 38 columns, and the pairs, $800 apart, can't share code.)
   - **VSP** (see VSP.md): the screen scrolled by whole characters by DMA delay on line 50, a
     column written a step and the other pair refilled in the background for swaps. Camera test:
     the camera waits in 0% of frames, the multiplexer ready for 96.6%.
5. **Yoyo** (done: src/yoyo.asm): the BBC version's start_yoyo, yoyo_out, yoyo_back, yoyo_longer,
   yoyo_position and yoyo_collide ported (A_1 has no movable platforms: no carrying; only the
   Scrubblies are hit). Trogg in his yoyo pose; the yoyo a virtual sprite (YV, kept before
   others), hi-res black, its 4 frames turning with the length (its yellow highlight shows as
   the background: multicolour would need $d01c in the multiplexer's register writes); the
   string a line of string characters (60-63) on map line ty - 36, from his hand to the yoyo's
   near edge, in the pair shown, the last frame's cells put back from the map first (strset in
   the main program, strapply in border tick 26: at tick 25, with the frame's other work, it
   could take over two ticks, a tick was lost and every row after was a tick late). A Scrubbly
   hit: its sprite hidden, its cells patched (scrpatch.inc, now with rows and columns) in the
   map and in each pair up to date for a window they're in (a pair being filled starts again);
   a restart puts them back. Checked in VICE: a throw's yoyo and string where they should be;
   Scrubbly 3 knocked off from the top of the F (screenshot against the yoyoed-off mock-up;
   both pairs against the map in memory, tools/scrcheck.py), and back after Trogg dies; key
   scripts the same in py65 and VICE. Camera test: multiplexer ready 95.7%, the camera never
   waits; the frame checker (now taking the virtual sprites' number from the labels) finds no
   problems.
6. **Budget**: moved to part 2 (milestone 12), to be done with everything running.

## Part 2: A_1 as the BBC version plays it

The levels stay static, as in the BBC original: the Scrubblies stand where they are (the 65C02
code here ports the Steam version, whose Scrubblies patrol; that part is left out). The
reference for everything else is that code (`../src/frak.asm`): `check_collisions`, `hit_test`,
`collide`, `spawn_balloon`, `spawn_dagger`, `trogg_dies`, `level_complete`, `draw_hud`,
`check_checkpoint`, `save_checkpoint`, `restore_checkpoint`.

7. **Collisions, by box** (done: src/collide.asm). Trogg's box (his frame's solid pixels' extent
   as shown, from trogg.json) against each object's in the level's coordinates, all made by the
   build (`build/collide.inc`): the Scrubblies (deadly, unless yoyoed off) and the gems and keys
   (touched: `ptouch`, for milestone 9) as the mock-up drew them (`mockup.mjs` now writes
   `picks.json`: A_1's 4 keys and 7 gems, and the Scrubbly's box), the balloons and daggers by
   the ball sprite's box (deadly). Run each tick after his movement, until he dies. Signed
   comparisons (his box reaches above the level when he jumps). Cost: first 1,900-2,400 cycles a
   tick on average; now only the objects both in his columns and in his 32-line bands (a mask a
   column and a mask a band, from the build, ANDed) are tested, and a ball by y first: 770 on
   average with no balls out, 1,160 with six (`tools/collidecost.py`). In play (a key script,
   invincible, so the game goes the same): the multiplexer ready for 94.3% of frames (96.9%
   without the check). Checked: `tools/collidetest.py` runs collide in py65 on 5,000 random
   situations near every kind of object against a Python reference from the same tables: none
   differ (647 Scrubbly deaths, 378 balls, 425 gems or keys); key scripts walking into the
   Scrubbly at the top of the F (he dies, the level restarts) and onto the gem on its middle
   platform (touched), the same in py65 and VICE; in VICE, the balloons and daggers kill him
   standing at the start (4 times in 25 s).
8. **Collisions, by pixel** (done: `spans` in src/collide.asm). After the boxes touch, the BBC
   version's `hit_test`: on each row the two images share, his solid pixels' extent (leftmost to
   rightmost) against the object's; positions biased by 128 so the comparisons are unsigned. The
   spans made by the build from the images as the C64 shows them: Trogg's 15 frames (trogg.json),
   the Scrubbly, gem and key as the mock-up draws them (`picks.json` now carries their grids),
   the ball sprite. Checked: `tools/collidetest.py`, its reference now taking the spans from the
   images themselves (not the build's tables), on 5,000 random situations: none differ; the boxes
   touched without the spans meeting in 285 of them; spans and an exact pixel test disagree in 1.
   Key scripts as in 7, the same in py65 and VICE (walking into the Scrubbly on top of the F, he
   now dies at x 64, not 62). Cost: 880 cycles a tick on average with no balls out, 1,430 with
   six, at worst about 3,700 (several objects' rows compared); in play, invincible (so balloons
   pass through him, compared every tick; in a real game the first touch kills him), 92.1% of
   frames ready (94.3% with boxes alone). For the budget pass.
9. **Gems and keys** (done). One Trogg touches is picked up (`pickup`, src/yoyo.asm): its cells
   patched to what's behind it in the level map and in each pair that shows them, as the
   Scrubblies are knocked off (one routine now: `patchon`, `patchoff`), counted (`gemsgot`,
   `keysgot`), and the last key noted (`allkeys`, for milestone 11); a restart puts them back.
   The data: `mockup.mjs`'s `GONE=1` variant (the gems and keys left out, what's behind them
   showing), packed with the others: the two sets still do, with not a glyph more (60 tops and
   60 bottoms, 46 and 38: what's behind them was in the sets already); the packer's patch
   tables now hold the Scrubblies' cells then the gems' and keys' (8, 8, 8, 7 for the keys, 4
   for each gem; 192 in all). Checked: in py65 and VICE, Trogg picks up the gem on the F's middle
   platform (the map in memory changed in its 6 cells, both pairs as the map, the screenshot as
   the picked-up mock-up there), and dying puts it back; `tools/picktest.py` picks up all 11 in
   random orders in py65 (the counts, the level complete exactly at the last key, every cell's
   new codes) and puts them back (every cell as built): no problems. (The py65 harnesses' call
   stub moved from $7f00, inside the level map, to $033c.)
10. **Balloons and daggers, properly** (done: src/hazards.asm). The BBC version's spawn_hazards,
    spawn_balloon, spawn_dagger, random_x, random (xorshift) and update_movers ported, Hard's
    numbers, run each tick in the game tick while Trogg's alive (and in the camera test, for the
    multiplexer's load); their places kept as the BBC version keeps them (the image's origin, 16.8,
    in the level), mux.asm's `game` only making sprites of them. Their own sprites (`mockup.mjs`
    exports the BBC's IMG_Balloon and IMG_DaggerLR; the build makes the sprites, `hazspr`), for now
    hi-res silhouettes: the balloon magenta, the dagger black (each is 3 colours in the original:
    see below). Trogg against them by each kind's box and spans; the yoyo pops them (its square
    against their whole image, as yoyo_collide) and comes back. Checked: `tools/hazardtest.py` runs
    the BBC version's own BANK6 (from frak.ssd) in a 65C02 emulator beside the C64's hazards, the
    same seed, Trogg wandering: 12 runs of 800 ticks, every balloon and dagger the same (kind,
    place to the fraction, pause) every tick; at most 6 out at once (the C64's slots: none missed,
    but no margin). `tools/collidetest.py` (now with both kinds): 4,000 situations, none differ.
    `tools/poptest.py`: 3,000, none differ. In VICE, the daggers drawn where they are (42 of 42
    pixels, a tick behind the state read). Camera test (now with them spawning about Trogg, as
    the original): the multiplexer ready for 91.2% of frames (95.7% with the balls spread across
    the screen); the frame checker finds no problems. For the budget pass.
    Colour: the original's balloon is magenta with a black outline and a yellow highlight, the
    dagger black with a yellow blade. Faithful would need multicolour for sprites 3-7 (`$d01c` in
    the multiplexer's register writes, which the row tails may not have the time for) or two
    sprites each (twice the multiplexer's load): a decision to make.
11. **Death and the level's end** (done). Dying: the game still (as the BBC version's game_tick:
    nothing moves, nothing spawns) for the 50 ticks before the restart, and the FRAK! bubble at
    its place (its image's corner at (x + 12, y - 44)). The bubble is 52 wide in the original,
    black on yellow; the C64's is redrawn at half width, 24 x 19 (`build/frak.txt`), shown as 2
    x-expanded virtual sprites (FV): its black, and its yellow only where the black isn't (so
    either can be in front: the multiplexer chooses the hardware sprites). The letters come from
    the BBC's image, each 2-pixel stroke one pixel (its F on even columns, the rest on odd ones), the
    F 3 wide so the bubble fits 24; the outline, corners and tail drawn in build.mjs. Kept before
    others, shown while he's dead (`frakset`). The last key: the level complete (`won`), as
    `level_complete`: nothing kills him, everything still for 7 seconds, then A_1 from the start.
    The timer and rating (`draw_hud`) left for later. Checked: in
    py65 (picktest.py), the level complete at the last key, Trogg still through the pause (a key
    held), then the level from the start, everything back; key scripts the same in py65 and VICE.
    (Found on the way and fixed: adding the level-complete state had made a dead Trogg walk on.)
    In VICE, the bubble exactly as frak.txt (each pixel 2 wide), black and yellow, both for a
    death on the top row beside a Scrubbly (674 of 674 pixels; two sprites and the two Scrubblies'
    bodies fit the 5) and after a fall at the bottom (604 of 604). Camera test: 90.1% ready.
12. **Checkpoints** (done). A key picked up that isn't the last makes one due (`savecp`); it's
    saved (`checkcp`, each tick after the collisions) once Trogg is standing or walking (on a
    platform: A_1's don't move) and not dying, as `check_checkpoint`: his place and facing, the
    balloons' and daggers' timers, what's gone (Scrubblies knocked off, gems and keys picked up)
    and the counts. Dying goes back to it (`restart`, as `restore_checkpoint`): the cells of
    anything gone since put back (`cprestore`; those gone before kept), the counts and timers as
    saved, no balloons or daggers, his movement reset, a restart counted (the level complete's
    pause a second shorter for each, to 4); with none yet, the level from the start as before.
    The camera jumps to the scroll with him in the middle (x - 152, kept to 0-MAXX: `jumpx`,
    `jumpw`), the hidden pair filled for that window at offset 8. The level complete starts A_1
    afresh, no checkpoint (`newlevel`). Checked: `tools/cptest.py` in py65 (a key, standing, the
    checkpoint; then a gem and a Scrubbly; dying: him back, the key still gone, the gem and
    Scrubbly back, the map as at the checkpoint, the counts, timers, restart and camera's scroll;
    then the level complete: the pause 300, and after it the level from the start): no
    problems in 6 rounds. In py65 and VICE alike, Trogg starting beside the key on the R's bottom
    platform (`--troggx 255 --troggy 207`) picks it up, walks into the Scrubbly and dies, and comes
    back where he picked it up, the key still gone; in VICE the camera's at scroll 103 (window
    12), Trogg drawn exactly there, both pairs as the map. (Found on the way: `level_complete`'s
    pause by the restarts used x, which `pickup` still needed; it uses y.)
13. **Budget**, with everything running: the whole frame profiled, readiness and slack measured
    in the camera test and in play, and whatever that shows fixed.
    - **Memory first** (done): `tools/memmap.py` sizes every item; the waste found and taken out,
      2.5K off the program file, 1.8K more free below `$4000` (the README's memory map): the
      row-tail tables in pairs, interleaved (only odd masks are read: the cover's bit 0 is always
      set); Trogg's sprite blocks once each (60 of 90, `tblk` each frame's 6), his collision
      spans likewise (12 of 15); the character sets and sprites loaded where the VIC reads them,
      not copied; the patches' save areas cut to 192 cells. Checked: the tail tables the same
      for every odd mask, each frame's blocks the same bytes, collisions, pickups, checkpoints,
      hazards and pops as before (py65), the frame checker (30 frames, no problems), the screen
      pixel for pixel the same as before in VICE (3 frames sooner: the start does less), the
      packed program unpacking; readiness in the camera test 90.0% (90.2% before: noise).
      Left: the alignment padding (0.45K), and `colw0`/`colw1` as a loop (0.55K, slower).
    - **The frame in play** (measured): `build.mjs --profile` stamps CIA 2's timer at each stage
      of a frame's work, from the border's request to the multiplexer done, into a ring at
      `$e000`; `tools/frameprof.py` plays a key script in VICE and reads it back
      (`tools/autoplay.py` makes the scripts: the game's own tick in py65, choosing key segments
      that go somewhere new, pick things up and knock Scrubblies off). Six starts across A_1,
      1,500 ticks of play each, then standing: **7.6-33.4% of frames held** (35.7% in a normal
      `--slack` build of the first, so not the stamps' doing); playing 36-68% over, standing
      13-27%. The work averages 7,600-9,200 CPU cycles (py65; 6,800-13,900), but where it runs
      matters: `gametick` runs first, in the border, at about 90% (3,300 CPU cycles take
      3,600); the multiplexer's stages run on into the picture, at about 29% (3,500 take about
      12,000: the row interrupts' waits, 4-line FLI's bad lines and the sprites' fetches take
      the rest). So the budget is about 7,000 cycles in the border, then a third of a cycle per
      cycle. CPU by routine: `collide` 1,700 (its mask loop shifts a bit at a time: about 440),
      `update` 1,300-1,600, `game` 1,000, `hazards` 570, `yoyo_collide` 0-540, `sort` 360,
      `rngs` 330-470, `read_keys` 270.
    - **Found**: the BBC version runs a game tick per vertical sync (50 a second) however slowly
      it draws (more ticks after a slow frame, capped at `MAX_TICKS_PER_FRAME`); the C64 runs one
      per frame made, so each held frame is a tick lost and the game runs slow.
14. **Sound.** The sound effects on the SID (`SFX_CHING` for a pickup, `SFX_SQUEAL`, `SFX_DAGGER`,
    `SFX_POP`, `SFX_THUD`), from the BBC version's definitions, played in the border; the music
    (the victory tune) after. Its time measured against the budget from 13.

Loose ends, not in the way of the exit milestone: the yoyo's yellow highlight (multicolour, so
`$d01c` in the multiplexer's register writes); a PAL check at the start, with a message on an
NTSC machine instead of a garbled screen; the VSP crash test on hardware (VSP.md, step 2).

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
