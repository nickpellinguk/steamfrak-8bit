# Frak! for the Atari 800XL (experimental)

The start of an Atari 800XL (PAL, 64K) version: ANTIC mode 2 with character rows 4 lines high,
on the C64 port's 8x4 grid, so the C64's levels carry over cell for cell. The plan:
[`PLAN.md`](PLAN.md).

**Status: the game starting to run, on a sprite multiplexer, graphics first** (`build/trogg8x4.xex`, without the OS).
It starts on a front end like the C64 port's: "The Cast", the FRAK! bubble, Trogg, a Scrubbly, a
Hooter and a Poglet with their names, then "Collect all the keys to win!" (`src/front.asm`,
`tools/front.py`): a hi-res bitmap, the text from the machine's ROM font, every infill on players
and exact; fire, Start, Space, Return, P or Y plays, 1, 2 or 3 chooses the level, and Escape in the
game comes back to it. **Three levels**, one of each type, as the C64 port has: A_1 (Scrubblies,
on cyan), A_2 (Poglets, on green), A_3 (Hooters, on red). As the C64's loader does, each level's
own tables and numbers sit at fixed places in a block, as long as the longest level's
(`tools/levels.py`), so the code is the same for any; each level's block, character set and map
are packed in the program and unpacked at the start (`levelset`); what follows from the rest
isn't stored but worked out then (`lvderive`: each column's platforms and ladders, the gems', keys'
and enemies' boxes and players' places, each patch cell's code with its object there, read from
the map just unpacked), 1.5K less packed. The code that runs only at the start (the front end, the
level's start) is an overlay (`src/overlay.asm`, `tools/game.sh`): packed at the program's end,
unpacked over the VBI's programs (unused till the game sets up). The Poglets' and Hooters'
infill is their magenta (from the C64's multicolour sprite), on players as the Scrubblies' is;
their yellow is still to come. Only the enemies near the view are listed each frame (A_2 has 9).
Every
outline is drawn in software at full resolution (players are 2 hires pixels a block at their
finest, so an outline on one would be at half resolution), and the four players carry the
infills, given out band by band in this order: Trogg's (yellow and magenta, on P0 and P1 and
their missiles); the Scrubblies' bodies (one double-width player each, then two normal-width
where a second is free: exact for the C64's); the balloons' (magenta); last, the keys' yellow
(one double-width player each, P3 or P0: 2 of a key's yellow pixels wrong). Daggers have no
infill.
`-D HWOUT=1` puts outlines on players too where they're free (Trogg's from one of his bands
down, a balloon's with its infill, a dagger's), for when speed has to win. On A_1, Trogg moves as in
the game: the C64 port's movement code (`src/move.asm`, from `c64/src/play.asm`: walking,
climbing, jumping, falling, on the C64's platforms and ladders, in its coordinates), on the
joystick in port 1. Landing too hard, falling off the bottom or touching a Scrubbly kills him
(`src/pick.asm`: box collisions); a gem or key touched is picked up, and goes from the map; a
key makes a checkpoint, the last completes the level (7 seconds' pause, then it starts again).
The balloons and daggers are the game's (`src/hazards.asm`, the C64 port's, itself the BBC
version's): Hard's timings and speeds (`-D INSANE=1` Insane's; `-D STRESS=1`, a test, six out
all the time), a balloon rising from the level's bottom about Trogg, a dagger aimed to arrive
where he is, each held still a moment first; touching one kills him. Collisions are the C64's
two stages: boxes, then where they touch each image's spans (every row's leftmost and rightmost
solid pixel, from the images as drawn) must meet on a row both have, as the BBC version's
hit_test and GameMaker's precise collisions; checked against a Python reference
(`test/collcheck.py`: no disagreement over 2,790 memory dumps of a STRESS run, 7 deaths). Fire
throws the yoyo (`src/yoyo.asm`, the C64 port's): out 1.3 pixels a tick while it's held, to 80,
then back; it knocks a Scrubbly off (its cells changed to what's behind it, its infill and
collisions gone, back after a restart or at an earlier checkpoint) and pops balloons and daggers.
It's drawn as the BBC version draws it: the string a line from his hand to the yoyo, exact to the
pixel (the C64 has to draw it a character at a time), then the yoyo, then Trogg on top (he's now
drawn last, over the hazards too). Gems, keys and Scrubblies are one list of patch objects (24-bit
masks: A_2 has 17); their cells reach the screen through a patch program the VBI runs after the
frame's, built once the frame's drawn so it leaves out cells something's drawn in (a Scrubbly
changes about 48 cells, more than a frame's program has room for). Still to come: the FRAK!
bubble when he dies, and sound. Checked in the WebAssembly atari800, colour for colour: 893 screens of six joystick
tours (`test/tours.sh`), with gems and keys going and coming back, and a Scrubbly knocked off; and the front end's screen.

**What's still short of the original's look:** Trogg's infill is in 2-pixel blocks (at most 10 of
his 200-250 infill pixels wrong); a Scrubbly on one double-width player has 21 of its 540
magenta pixels wrong; the balloon's yellow highlight, the dagger's yellow blade and the
Scrubbly's yellow eyes and teeth aren't coloured; something partly off the screen across has
no infill (a player would show over the border); Poglets and Hooters have none yet.

**Speed:** the game runs at 50 ticks a second whatever the drawing takes (the VBI counts fields;
each frame made runs a tick for each field since the last, up to 4, as the C64 version makes up
for late frames). Frames, measured standing at A_1's start: 16.7 a second with Trogg alone (3
fields a frame; 25 before the game's logic and the keys' yellow came in), about 10 with the
stand-in balloons and daggers out (every outline in software; 12.5 at 208 lines: the taller
screen costs about 1,900 cycles a field in ANTIC's fetches and 8 more DLIs, and keeps each
hazard on the screen longer). With Trogg alone the 240 lines cost no frames. With the game's
balloons and daggers (more of them out at once than the stand-ins had), about 9.
The players' strips take 127-134 lines a frame, from 213-236: the Scrubblies' strips are kept
in each set while their players don't change, and of Trogg's only the old lines his new ones
don't cover are cleared. Next: the software drawing (Trogg about 180 lines; each hazard's
outline the rest) and the multiplexer (60-170 lines).

Before that, **an 8x4 screen demo.** `build/screen8x4.xex` shows the C64 port's A_1 ("FRAK!") on 60
rows of 4 lines (240 lines: 52 at first, 208), scrolling back and forth across the level 2 pixels a frame. It's black outlines
on one background colour: no infills, Trogg or game yet. Checked in atari800 against the C64's
picture of the level: every pixel the same at 11 scroll positions (each fine-scroll phase, both
ends) and in captures while it moves; A_2 and A_3 too. Not yet tried in Altirra or on a real
machine.

## Building and running

    ./build.sh                 # build/screen8x4.xex (and build/rows4.xex, the row test)
    LEVEL=A_2 ./build.sh       # the screen demo on another level (the game carries all three)
    STILLX=100 ./build.sh      # held at a scroll position (colour clocks) instead of moving

Trogg's sprites come from the steamfrak repository's `assets/sprites` (alongside this one, or
`STEAMFRAK=...`). Checking Trogg (after building the emulator, see "In a browser"):

    node test/tour.mjs build/a8.js build/trogg8x4.xex /tmp/tour "30:0 100:1 50:8 100:0"
    python3 test/checktrogg.py /tmp/tour A_1     # every screen, colour for colour
    python3 test/state.py /tmp/tour              # Trogg's place and state in each
    python3 test/hzstate.py /tmp/tour            # the balloons and daggers in each
    python3 test/scr2png.py /tmp/tour/0012.scr shot.png
    test/tours.sh build/a8.js                    # all the checks: tours on the builds, the front end

The program starts on the front end; `-D FRONTEND=0` leaves it out (the tests: the game at once).

It needs node (the C64 port's `tools/level.mjs` makes the level's picture), Python 3 with Pillow,
and [64tass](https://sourceforge.net/projects/tass64/). Run the `.xex` on a PAL 800XL (or any XL/XE
with 64K), or in an emulator set to PAL: `atari800 -xl -pal -run build/screen8x4.xex`.

## In a browser

`build/frak800.html` is a PAL 800XL in one web page: atari800 5.0 (GPL-2.0) built as libatari800,
compiled to WebAssembly, with its own AltirraOS (no Atari ROMs needed), and the programs above
built in (the demo on A_1, A_2 and A_3, and the row test). Open it in a browser, locally or from
any web host; it can also load another `.xex` or `.atr` (a button, or drop the file on the screen).
Not inside a host whose security policy forbids compiling WebAssembly (claude.ai's artifact
viewer, for one): there the page says so instead. (An asm.js build, `-s WASM=0`, compiled with
emscripten 3.1.6 but didn't run atari800's CPU, so there's no fallback yet.)
Arrow keys are joystick 1, Space or Ctrl fire, F2-F4 Start, Select and Option.

    ATARI800_SRC=/path/to/atari800-5.0.0 web/build_emulator.sh   # build/a8.js (needs emscripten)
    python3 web/build_page.py build/a8.js                          # build/frak800.html

| File | |
| --- | --- |
| `web/web.c` | The emulator's side: start a PAL 800XL with a program, run a frame with the joystick, keys and console keys, and hand over the screen, palette and sound |
| `web/page.html` | The page: the canvas (the emulator's 336 x 240 picture at 50 frames a second), the controls, keys, sound |
| `web/build_emulator.sh` | libatari800 and `web.c` through emscripten into one `a8.js` with the WebAssembly inside |
| `web/build_page.py` | `page.html` with `a8.js` and the programs put in: `build/frak800.html` |

## How things are drawn

- **10-bit graphics** (`tools/sprites.py`): each of his frames, at each of 4 shift positions (0,
  2, 4 and 6 pixels: the colour clocks that the scroll, and later his infill, move in), is a byte
  for each 8-pixel window, an index into that shift's 256-byte AND and OR tables. A pixel is set
  (the outline), clear or transparent; AND has a 1 where transparent, OR a 1 where set. All the
  moving graphics (Trogg, balloons, daggers, the yoyo, the FRAK! bubble) share the tables: 250,
  233, 236 and 252 windows of 256 (the build stops if a shift has more). Each column of a graphic
  is stored top to bottom with 3 transparent bytes above and below (shared with the next column's
  above), so a character row's 4 lines are 4 bytes in a row wherever he starts in it. The data is
  5,326 bytes (from 9,544): his walking frames are compiled as two parts, his body (rows 0-23, the
  same in all four of a direction, as the BBC version found) and each frame's legs (rows 24-33),
  drawn one after the other (`swone`); a graphic the same as another (the climbing frames are 2
  different of 5) shares its data; only the graphics the game draws are compiled, numbered apart
  (`gcix`) so the side masks' tables hold them all. The empty space is at the sides (45% of his
  first and last columns' cells are all transparent, 3% of the middle ones'), so for the first
  and last columns, for each of the 4 lines a character row can start on relative to the
  graphic's top, a bitmask with a bit for each character row: 1 where that cell's all
  transparent, and skipped (shifted out a row at a time).
- **A cell's cost:** its 4 lines unrolled (`lda (dp),y` `tax` `lda (sp),y` `and andtab,x`
  `ora ortab,x` `sta (cp),y`, 28 cycles a line; the OR alone, 19), and around them the cell's
  spare character, claim and the VBI programs' entries. The programs are prefilled with
  `lda #` `sta abs` entries, so a cell writes only their operands (an `rts` ends each frame's,
  put back to `lda` when the program's next built); the programs are page-aligned, so one
  pointer step does both; the characters' addresses come from tables chosen once a frame (the
  set) and once a row (the half) instead of adds. Trogg's software drawing: 136 lines a frame
  on average, from 187 (194 before the side masks).
- **Spare characters** from code 64, given out a cell at a time, bottoms halves (for the first
  row of a pair) and tops halves (the second) separately: 64 of each, so a code serves a cell of
  each kind of row.
- **`plot`** (`src/trogg8x4.asm`) draws a graphic at a top left x (level pixels, signed) and a
  top line (its scanline, the screen 8-247, so things can start above or below it), for each cell
  in the screen's 60 rows and the 41 columns in view where it isn't all transparent: a spare
  character's half in the character set not shown, started from the level's half glyph there
  or, if something has the cell already this frame (a table of the cells in view), from that.
  The level's code there comes from the screen's map: a code below 64 is the level's; a spare
  character there was drawn the frame before, and that frame noted what it was over (a page a
  frame, by turns); a cell a gem's, key's or Scrubbly's patch is changing this frame has its new
  code (its rows are flagged, so only those look). So there's no second, clean copy of the map
  (7.5K): the level's map is packed in the program (the BBC version's packer: A_1's 7,680
  bytes in 774) and unpacked into the screen's at the start; its 4 lines ANDed and ORed on
  (`lda (dp),y` `tax` `lda (sp),y` `and andtab,x` `ora ortab,x` `sta (cp),y`, the shift's table
  page patched in once a graphic; over blank background, `lda ortab,x` `sta (cp),y` alone).
- **The VBI's programs:** for each cell, plot writes `lda #code` `sta cell` into this frame's
  program and `lda #level's code` `sta cell` into a putting-back program. The VBI runs last
  frame's putting-back program and this frame's (6 cycles a cell), swaps the character sets (the
  level's glyphs are in both) and sets the scroll (the rows' LMS only when it changes coarsely).
  So double buffering costs a character set, not spare characters, nothing is seen half drawn,
  and the VBI stays short (a first version, putting cells back from lists, took about 9,000
  cycles with 6 hazards out and ran into the first row's DLI).
- **Cost:** about 330 cycles a cell, about 650 more a hazard (its rows' pointers, the set-up),
  a hazard 6-12 cells: about 4,000 cycles each. Trogg alone leaves 4,200-6,200 cycles a frame to
  spare (with the OS's VBI still running). Ways on: running the game a tick a VBI and drawing a
  frame every other one (as the BBC version does: 25 frames a second, 50 ticks), switching the
  OS out, and trimming the per-cell work (the programs' entries prefilled; the claims).

## The multiplexer

- **Players** (normal width: 8 two-pixel blocks, unless double-width: 4-pixel blocks;
  `tools/sprites.py` and `tools/screen.py` make their graphics):
  - Trogg's infill on P0 (yellow) and P1 (magenta), each with its missile (a player and a
    missile per colour: at most 10 of his 200-250 infill pixels wrong); his outline in two halves
    (P2 his left 16 pixels, P3 his right), a block on where either pixel is black, and his infill
    with holes there (the outline's players are behind it);
  - a Scrubbly's body from the C64's (where its magenta sprite shows): two normal-width players
    side by side (exact) or one double-width (21 of 540 pixels wrong);
  - a balloon's outline (a block on where either pixel is black) and infill; a dagger's outline.
- **Colours and widths:** P1 always magenta, P2 always black; P0 black, Trogg's yellow or
  magenta, and P3 magenta or black, set band by band with P0's, P1's and P3's widths. Players are
  in front of the playfield (`PRIOR` 1): mode 2's set pixels show luminance 0 in the hue under
  them, so outlines drawn in characters stay black over the infills.
- **Each frame** (`mux`), in this order: Trogg's infill; the Scrubblies (a double-width player
  each, P3, P1 or P0, then a second for two normal-width where one's free); the balloons'
  infills (P3, P1 or P0). With `HWOUT=1`, also Trogg's outline from one of his bands down (not
  his first: its writes are his infill's), a balloon's outline with its infill on a pair, and a
  dagger's outline.
- **Which band writes a thing's registers:** any from the one after the thing above it on its
  player has ended (by line 8k + 2) down to its top's, or the VBI if nothing's above it: the
  latest with room in its 5 writes is chosen (a Scrubbly's second player keeps its first's).
  Something not wholly on the screen across gets no player (it would show over the border);
  above and below, the players' graphics are clipped. Trogg's rows from his outline's band on
  aren't drawn in software.
- **Bands:** each pair of rows' first DLI (display line 8k + 3) writes the registers that change
  for the next 8 lines, through a table of 16 blocks by the band's mask. With ANTIC fetching the
  character codes on the line after, the writes finish two lines later, so a band's registers
  hold from line 8k + 6; two things share a player if the first ends by line 8k + 2. The DLI
  must end before the tops row's DLI (or that NMI interrupts it and the rows' order is left the
  wrong way round): about 150 cycles, so at most 5 register writes a band (P0 3, P1 2, P2 1, P3 3),
  which `mux` keeps to. The missiles (Trogg's alone) are set by the VBI. All measured colour by
  colour in atari800.
- **Double buffering:** two sets of player graphics (`PMBASE` swapped by the VBI with the
  characters) and of band tables; each frame clears the strips written to its set two frames
  before.
- **Cost:** `mux` about 54 lines, the strips most of a frame. To do: keep the Scrubblies' strips
  where they haven't changed (they're static: only their players change), write Trogg's infill
  once (plain above his outline's line, holed below), and draw every other frame with the game
  ticking every frame (the BBC version's 25 frames and 50 ticks).

## How the screen works

- **4-line rows:** the display list alternates mode 2 rows with vertical scrolling on and off.
  Each row's DLI sets `VSCROL` for what comes next: 3 on a first row (so the second ends after
  glyph line 3), and 4 on a second row, written after `sta WSYNC` and one `nop` (so the next pair
  starts at line 4). Each pair is then glyph lines 4-7 then 0-3. Why and how it was measured:
  [`test/README.md`](test/README.md).
- **Two glyphs a character:** the first row of a pair shows its characters' bytes 4-7 (a
  "bottoms" row), the second bytes 0-3 (a "tops" row), so each code holds two 4-line glyphs,
  numbered independently. A_1 needs 46 codes, A_2 57, A_3 41: one character set each.
- **240 lines:** ANTIC's most (scanlines 8-247, on PAL as on NTSC: it forces the vertical blank
  at 248). 60 rows show the original's level lines 16-255 (it's 256 high; the top 16 were its
  HUD's margin), against the C64's 200 (lines 24-223). The Atari's row r shows the C64's half
  row r - 2 (its character row n's halves are 2n and 2n + 1), so the rows above and below the
  C64's are blank: the C64's level files hold its 200 lines' worth, and on A_1 the original's
  margins are empty too. The display list has no blank lines, and its last row no DLI (the VBI
  follows). The VBI reloads `DLISTL` every field: with 240 lines ANTIC reaches the vertical blank
  before fetching the list's JVB, and left alone would fetch it at the top of the next frame and
  wait out that whole frame, blank (found when every other screen came out empty).
- **Scrolling:** every row has its own LMS into the map (60 rows of 128 bytes, the level from
  byte 4), and `HSCROL` is on for the fine steps. The deferred VBI sets `HSCROL` = -x & 3 and each
  row's LMS to row + (x + 3) / 4, for a scroll position x in colour clocks.

| File | |
| --- | --- |
| `tools/screen.py` | A level's character set and map for the 8x4 screen, from the C64 build's picture of it (`c64/build/<level>/chars.bin`); `build/<level>_expect.png`, the picture the Atari should show; the Scrubblies' and keys' infill fitted to players; each gem's and key's cells with it gone (`_picks.inc`) |
| `src/screen8x4.asm` | The demo: display list, row DLIs, scrolling VBI (with the OS, for now) |
| `src/trogg8x4.asm` | (memory: the program `$0800-$abff`, its page-aligned tables first, the three levels and the overlay packed at its end (5.6K free after them; 3.4K with `HWOUT=1`), the level's block below `$ac00` (`LVL`, 2.6K), what's under the spare characters drawn `$ac00` and `$ad00`, the display list `$ae00`, the character sets `$b000` and `$b400`, the VBI's programs `$b800`, `$bb00` and `$c000` (the last in the first players' graphics' unused `$300`), its patch program `$be80`; under the OS, which ANTIC sees as the CPU does: the players' graphics `$c000` and `$c800`, the screen's map `$d800-$f5ff`, the bands' registers `$f600`; the claims in three parts, `$f980`, `$c800` (the second players' graphics' unused `$300`) and `$be00`) |
| `src/trogg8x4.asm` | The same with Trogg: the game's ticks, the camera, drawing into spare characters, the multiplexer, the VBI showing a frame |
| `src/move.asm` | Trogg's movement: the C64 port's (`c64/src/play.asm`), on the joystick; dying, checkpoints, the level complete |
| `src/pick.asm` | Collisions (Scrubblies, gems, keys); gems and keys going from the map (and coming back) through the VBI's programs; the keys listed for their yellow |
| `src/overlay.asm`, `src/lvset.asm`, `tools/game.sh`, `tools/packfile.py` | The overlay (the front end, the level's start: `levelset`, `lvderive`), assembled against the program's labels and packed; `game.sh` builds the game with it |
| `test/lvlcheck.py` | A level's block in memory, once it's started, against the tools' tables (the worked-out ones too) |
| `tools/levels.py` | The levels' blocks: each level's tables and numbers (`<level>_geom.json`, `_screen.json`) at fixed places, packed with its character set and map: `build/levels.inc` |
| `tools/geom.py` | A level's platforms and ladders (the C64 build's `geometry.json`), Trogg's and the Scrubblies' collision boxes: `build/<level>_geom.inc` |
| `tools/sprites.py` | The moving graphics as 10-bit graphics (`build/sprites.inc`) and the AND and OR tables; `build/sprites.json` for the checks |
| `test/tour.mjs` | A program on the WebAssembly atari800 with a joystick script, saving the screen and memory every few frames |
| `test/checktrogg.py` | Each saved screen against the level (with the gems and keys gone that the program's record says) and the things drawn on as it says, pixel by pixel |
| `src/unpack.asm` | The BBC version's unpacker (as the C64 port's loader has it): the level's map into the screen's at the start |
| `src/front.asm`, `tools/front.py` | The front end: its screen (a 320 x 220 hi-res bitmap, the cast's outlines packed, the text drawn from the ROM font, the infills on players re-set by a DLI between pictures), the keys to play |
| `test/frontcheck.py` | The front end's screen, colour for colour, against `front.json` and the font the program copied |
| `src/yoyo.asm` | The yoyo: the C64 port's, thrown, drawn (with its string, by `yolist` and `strline` in `trogg8x4.asm`), knocking Scrubblies off and popping balloons and daggers |
| `src/hazards.asm` | The balloons and daggers: the C64 port's, spawned, moved and gone as in the game |
| `test/state.py`, `hzstate.py`, `scr2png.py`, `tours.sh` | Trogg's state, and the balloons' and daggers', in each saved memory; a saved screen as a picture; all the checks |
| `test/collcheck.py` | The collisions in each saved memory against a reference: nothing deadly or a gem or key not picked up touching him while he's alive, and what killed him at each death |
| `tools/budget.py` | Codes the static graphics need per set: 8x8 against 8x4, by bands of rows |
| `test/rows4.asm`, `readrows.py` | The 4-line row test, and its reader |
| `test/shot.sh` | Runs a program in atari800 (PAL 800XL) under Xvfb and captures its window |
| `test/checkscreen.py` | A capture against `<level>_expect.png` at a scroll position, pixel by pixel |
| `test/findscroll.py` | The scroll position a capture of the moving demo matches exactly, if any |
