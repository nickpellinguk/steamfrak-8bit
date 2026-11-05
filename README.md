# Frak! for the BBC Master 128

A back-port of the Steam/HTML5 version of **Frak!** to the BBC Master 128, written in 6502
assembly for [BeebAsm](https://github.com/stardot/beebasm). It works from the data and logic of
the web version (the `steamfrak` repository).

**Status: milestone 5.** One level (Read&Weep) is playable from start to finish, and the
moving meanies and platforms of other levels work too:

* Trogg walks, jumps, falls (dying from long falls) and climbs.
* The screen scrolls smoothly at a steady 25 frames a second, with the game logic at 50 ticks a second.
* Gems and keys can be collected.
* Touching a meanie kills Trogg, with the "FRAK!" speech bubble.
* The yoyo (Space or P): it goes out up to 80 pixels while the key is held, on a string drawn
  as a line of black pixels, and knocks meanies flying off the screen. A flying meanie can
  still kill Trogg, as in the Steam version.
* Balloons float up from the bottom and daggers fly down from the top, aimed ahead of Trogg,
  using the Steam version's timings, speeds and spreads for the chosen difficulty. Both are
  deadly; the yoyo pops balloons and knocks daggers away.
* Collecting a key sets a checkpoint, as in the Steam version: dying returns Trogg there, and
  gems collected since come back.
* Moving meanies: Scrubblies patrol their platform, Poglets climb up and down their ladder, and
  Hooters jump. Their ranges, speeds and start directions come from the Steam version's object
  settings. The yoyo knocks them flying.
* Moving platforms go back and forth (or up and down) and pause at each end. Trogg rides them.
  Standing on a moving platform doesn't set a checkpoint.
* Collecting every key completes the level. For now the background just flashes and the level
  restarts; there is no text drawing yet.

Not done yet: Trogg-movable platforms, springs, a difficulty menu, timer and medals, sound, menus,
the other 54 levels, and vertically scrolling levels.

## Building

You need BeebAsm and Python 3 with Pillow, and the `steamfrak` repository alongside this one:

```sh
pip install pillow
BEEBASM=/path/to/beebasm ./build.sh                # STEAMFRAK=../steamfrak, LEVEL=room_A_1
LEVEL=room_B_1 BEEBASM=/path/to/beebasm ./build.sh # Scrubblies (B_2 Poglets, B_3 Hooters, D_1 lifts)
DIFFICULTY=6 BEEBASM=/path/to/beebasm ./build.sh   # 0 none, 1 Easy (default), 2 Hard, 4 Harder, 6 Insane
```

This writes `build/frak.ssd`, a bootable disc image. In an emulator (jsbeeb, b2, BeebEm)
choose a **Master 128**, load the disc and press Shift+Break.

Keys: **Z** / **X** (or ← / →) walk, **O** / **K** (or ↑ / ↓) climb and jump, **Space** or
**P** yoyo.

### Testing headlessly

`tools/emu` boots the disc on [jsbeeb](https://github.com/mattgodbolt/jsbeeb), presses keys and
saves screenshots:

```sh
cd tools/emu && npm install
node run.mjs "wait:1500 shot:start down:KeyX wait:100 up:KeyX shot:walked" screenshots
```

`INVINCIBLE=1 ./build.sh` builds a version where Trogg can't die, for testing.

## How it works

| Part | Where |
|---|---|
| Data converter: sprites, levels, jump table, background cache | `tools/convert.py` |
| Main loop, double buffering, scrolling | `src/frak.asm` (top) |
| Sprite plotter (masked, with save/restore) | `plot`, `col_plot` / `col_save` / `col_restore` |
| Draw log (erasing moving things), lines, moving objects | `log_sprite`, `log_line`, `restore_log`, `hline`, `update_movers` |
| Yoyo | `start_yoyo`, `yoyo_out`, `yoyo_back`, `yoyo_collide` |
| Balloons and daggers | `spawn_hazards`, `spawn_balloon`, `spawn_dagger`, `update_movers` |
| Moving meanies and platforms | `update_slow`, `move_platform`, `move_scrubbly`, `move_poglet`, `move_hooter`, `collide_slow`, `yoyo_slow` |
| Drawing them | `commit_slow`, `draw_slow`, `slow_rect`, `erase_drawn`, `repaint_rect`, `raw_setup`, `col_rawplot`, `add_damage` |
| Riding platforms | `trogg_update`, `platform_under` |
| Collisions, pickups, checkpoints | `check_collisions`, `hit_test`, `collide`, `check_checkpoint` |
| Platform and ladder queries | `platform_find`, `ladder_find` (ports of `PlatformFind` / `LadderFind`) |
| Trogg movement | `trogg_standing`, `trogg_falling`, `trogg_climbing` (ports of `TroggStanding` etc.) |
| Generated data | `src/gen/*`, `build/GFX4-5`, `build/SPANS`, `build/CACHE` (the assembler also writes `LEVEL` and `LOGIC` for bank 6) |

### Memory map (Master 128)

| Address | Contents |
|---|---|
| `&0000-&008F` | zero page: pointers and the plotter's variables |
| `&0400-&07FF` | save area for main-RAM screen buffer (BASIC's workspace, unused) |
| `&0900-&0CFF` | save area for shadow screen buffer (RS423/cassette buffers, soft keys, UDGs) |
| `&0E00-&10FF` | other variables: object states, checkpoint, draw logs, moving objects |
| `&1100-&2FFF` | drawing code and its tables (about 2.9KB free) |
| `&3000-&7FFF` | MODE 1 screen, **double buffered**: main RAM and shadow RAM |
| SWRAM banks 4-5 | sprites, pre-shifted (27KB) |
| SWRAM bank 6 | collision spans (`&8000`), level data, jump table and collision tables (`&9000`), and the **game logic** (`&A000`): Trogg's movement, platforms and ladders, collisions, the yoyo, balloons, daggers, moving meanies and platforms. Stays paged in while playing |
| SWRAM bank 7 | the level's platforms and ladders, pre-rendered (8KB for level 1), then save space for moving sprites |
| top of SWRAM bank 4 or 5 | more save space for moving sprites (whichever bank the sprites leave emptiest) |

### Sprites

A MODE 1 byte holds 4 pixels, so a sprite drawn at an arbitrary x needs one copy for each of the
four pixel positions within a byte. The plotter picks the copy from the low two bits of x. The
converter only stores the copies the game can use:

* everything that moves (Trogg, meanies, balloons, daggers, the yoyo, moving or movable
  platforms, springs) gets all four;
* static keys, gems and meanies get only the pixel positions that some level places them at;
* static platforms and ladders get none, because they are drawn from the pre-rendered
  background.

The build stops with an error if a level places something at a position with no stored copy.

### Screen and scrolling

* MODE 1 (320×256, 4 colours): background (cyan/green/red per level), black, magenta, yellow.
  That is exactly the Steam version's palette, and its 256-pixel-high playfield maps 1:1.
* Horizontal scrolling uses the CRTC start address, in 4-pixel steps. Screen memory is
  addressed in **level coordinates**: level byte-column C on character row R is always at
  `&3000 + ((C + R*80) MOD 2560) * 8`, however far the screen has scrolled. So a scroll only
  needs the newly exposed column drawing, and sprites are drawn and erased in level coordinates.
* The game draws into whichever of main and shadow RAM is not on display, then flips them at
  vertical sync, so there is no flicker or tearing. Each buffer remembers its own scroll
  position and the background saved under Trogg.
* Repainting a column copies it from the pre-rendered background in bank 7. That holds 8 bytes
  for each non-empty character cell plus a 32-bit mask per column. Keys, gems and meanies are
  then plotted on top.

### Drawing moving things

Everything that moves is drawn after the scenery, in the screen buffer that is not on display,
and recorded in that buffer's **draw log**. This covers meanies flying off, the yoyo and its
string, Trogg, and the FRAK! bubble. The background under each is saved in the buffer's 1KB
save area. Next time the buffer is drawn, the log is played back in reverse to erase them.
Sprites and lines (the yoyo string is a run of black pixels, colour 1) share the same
mechanism.

Each sprite's save record is self-describing: a header with the row layout, then each byte
column's screen address and saved bytes. That way erasing just replays it, without redoing the
sprite's geometry. Part of the save area is kept for Trogg, the yoyo and the FRAK! bubble, so
he is always drawn even when the screen is busy.

Meanies flying off are too big for the 1KB save area, so their background is saved in spare
sideways RAM instead (`LOG_SPRITE7`): the plotter pages in the save bank to save, then the
sprite bank to draw.

### Drawing moving meanies and platforms

Moving meanies and platforms ("slow sprites") are not in the draw log. They stay drawn in each
screen buffer, which remembers where it drew each one, and are only redrawn when they've moved
since that buffer last drew them, or something painted over them:

* The converter leaves them out of the pre-rendered background in bank 7, so erasing one just
  repaints its character cells from there (`repaint_rect`), then re-plots any keys, gems and
  static meanies in them.
* Everything repainted in a frame (newly scrolled-in columns, the columns of a collected
  object, erased slow sprites and the scenery over them) goes in a **damage list**. Every slow
  sprite overlapping damage is plotted again, in order, and each one plotted is damage for the
  ones after it, so overlaps come out right.
* Most moving meanies never have anything else drawn where they go, apart from platforms and
  ladders (the converter checks, in `slow_simple_flags`). When one of those moves, the character
  cells it will completely cover over empty background aren't erased first, and the sprite is
  copied into them without masking (`raw_setup`, `PM_RAWPLOT`).
* What is drawn, and what Trogg and the yoyo collide with, is each sprite's display position.
  Scrubblies near the screen take turns to catch up with where they really are, at most two a
  drawn frame (`SCRUB_MOVES`), so they move in steps of several pixels. Everything else is
  shown where it is every frame.

Moving objects have 16.8 fixed-point positions and
8.8 velocities, so they move at the Steam version's fractional speeds. Spawn positions use a
16-bit xorshift random number generator.

### Collisions

GameMaker tested Trogg against keys, gems and meanies pixel by pixel. Here the converter stores
each image's leftmost and rightmost solid pixel on every row (its "spans", in bank 6). Each
frame:

1. A quick test compares Trogg's byte columns with each object's column range (two byte compares).
2. For objects beside him, a test of the solid pixels' bounding boxes follows.
3. Finally, Trogg and the object collide if their spans overlap on any row they share.

That is exact for convex shapes and very close for these sprites.

Collected objects are erased by repainting their columns from the background cache. That is
queued separately for each screen buffer, so it happens after Trogg's saved background has been
put back.

### Moving meanies and platforms

These are ported from the Steam objects' step code: `oPlatform`, `oScrubbly`, `oPoglet` and
`oHooter`. The converter does the work that GameMaker did at room start: it finds each
platform's range (by scanning for obstructions, as `oPlatform` does on its first step), the
platform each Scrubbly walks on and the ladder each Poglet climbs, and writes their ranges and
speeds as tables. Positions are 16.8 fixed point and velocities 8.8. A checkpoint saves all of
their positions, so dying puts them back where they were when the key was collected.

Trogg rides a platform by being moved, at the start of each tick, by however far it moved since
the last one, as in GameMaker.

### Movement and physics

Positions are whole pixels. The Steam version's sub-pixel jumping and falling (gravity 0.05
pixels/tick², rounded to 1/20 pixel) is reproduced by `fall_dy`, a table of whole-pixel steps
generated by the converter. Index 0 is the start of a jump, 25 is walking off a ledge and 45
is dropping off the bottom of a ladder. `fall_flags` marks where Trogg can still grab a ladder
and where landing would kill him, using the same thresholds as the Steam code.

The game logic runs at 50 ticks a second (5/6 of the Steam version's 60): one tick per
vertical sync. The screen is redrawn at 25 frames a second (`FRAMES_PER_DRAW`), so normally
two ticks run per drawn frame. A vertical-sync event handler counts syncs. If drawing a busy
frame overruns, that frame simply runs three ticks, so the game speed never changes. Timers
such as the death pause count game ticks, not drawn frames.

Measured frame rates on Read&Weep: Easy holds 25fps. Hard dips to 24 and Harder to 21 at their busiest,
with 7 balloons and daggers on screen. Insane, with 8-9 on screen, runs at 21-22fps.

Levels with lots of moving meanies are still slow. A Scrubbly is 33×42 pixels: redrawing one
that has moved costs about 18,000 cycles in each buffer (8,000 to erase, 10,000 to plot), so
each move costs about 36,000. B_1 (16 Scrubblies) runs at about 12fps with two moves a frame,
or 19-20fps with one. B_2's Poglets and B_3's Hooters don't take turns yet and run at
11-14fps, and D_3 at about 10fps. D_1 (moving platforms) holds 23-25fps. The game speed stays right however slow the drawing gets.

### Timing

A drawn frame (1/25 s) is 80,000 cycles. Measured in jsbeeb, walking and scrolling uses about
31,000-34,000 of them, leaving about 45,000 for moving meanies, balloons, daggers and music:

| Step | Cycles |
|---|---|
| Erasing Trogg | about 8,500 |
| Drawing him (fully transparent bytes are skipped) | 13,000-15,500 |
| Game logic, including collisions (per tick, two ticks per frame) | about 3,500 |
| Repainting a newly scrolled-in column | 8,000-11,000 |
