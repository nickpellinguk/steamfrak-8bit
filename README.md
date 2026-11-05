# Frak! for the BBC Master 128

A back-port of the Steam/HTML5 version of **Frak!** to the BBC Master 128, written in 6502
assembly for [BeebAsm](https://github.com/stardot/beebasm). It works from the data and logic of
the web version (the `steamfrak` repository).

**Status: milestone 2.** One level (Read&Weep) is playable from start to finish:

* Trogg walks, jumps, falls (dying from long falls) and climbs.
* The screen scrolls smoothly at a steady 25 frames a second, with the game logic at 50 ticks a second.
* Gems and keys can be collected.
* Touching a meanie kills Trogg, with the "FRAK!" speech bubble.
* Collecting a key sets a checkpoint, as in the Steam version: dying returns Trogg there, and
  gems collected since come back.
* Collecting every key completes the level. For now the background just flashes and the level
  restarts; there is no text drawing yet.

Not done yet: moving meanies, the yoyo, balloons and daggers, timer and medals, sound, menus,
the other 54 levels, and vertically scrolling levels.

## Building

You need BeebAsm and Python 3 with Pillow, and the `steamfrak` repository alongside this one:

```sh
pip install pillow
BEEBASM=/path/to/beebasm ./build.sh                # STEAMFRAK=../steamfrak, LEVEL=room_A_1
```

This writes `build/frak.ssd`, a bootable disc image. In an emulator (jsbeeb, b2, BeebEm)
choose a **Master 128**, load the disc and press Shift+Break.

Keys: **Z** / **X** (or ← / →) walk, **O** / **K** (or ↑ / ↓) climb and jump.

### Testing headlessly

`tools/emu` boots the disc on [jsbeeb](https://github.com/mattgodbolt/jsbeeb), presses keys and
saves screenshots:

```sh
cd tools/emu && npm install
node run.mjs "wait:1500 shot:start down:KeyX wait:100 up:KeyX shot:walked" screenshots
```

## How it works

| Part | Where |
|---|---|
| Data converter: sprites, levels, jump table, background cache | `tools/convert.py` |
| Main loop, double buffering, scrolling | `src/frak.asm` (top) |
| Sprite plotter (masked, with save/restore) | `plot`, `col_plot` / `col_save` / `col_restore` |
| Collisions, pickups, checkpoints | `check_collisions`, `hit_test`, `collide`, `check_checkpoint` |
| Platform and ladder queries | `platform_find`, `ladder_find` (ports of `PlatformFind` / `LadderFind`) |
| Trogg movement | `trogg_standing`, `trogg_falling`, `trogg_climbing` (ports of `TroggStanding` etc.) |
| Generated data | `src/gen/*`, `build/GFX4-5`, `build/SPANS`, `build/CACHE` |

### Memory map (Master 128)

| Address | Contents |
|---|---|
| `&0000-&008F` | zero page variables |
| `&1100-&2FFF` | code, tables, Trogg's save buffers (about 500 bytes free) |
| `&3000-&7FFF` | MODE 1 screen, **double buffered**: main RAM and shadow RAM |
| SWRAM banks 4-5 | sprites, pre-shifted (27KB) |
| SWRAM bank 6 | collision spans (`&8000`), level data (`&A000`); stays paged in while playing |
| SWRAM bank 7 | the level's platforms and ladders, pre-rendered (8KB for level 1) |

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

### Movement and physics

Positions are whole pixels. The Steam version's sub-pixel jumping and falling (gravity 0.05
pixels/tick², rounded to 1/20 pixel) is reproduced by `fall_dy`, a table of whole-pixel steps
generated by the converter. Index 0 is the start of a jump, 25 is walking off a ledge and 45
is dropping off the bottom of a ladder. `fall_flags` marks where Trogg can still grab a ladder
and where landing would kill him, using the same thresholds as the Steam code.

The game logic runs at 50 ticks a second (5/6 of the Steam version's 60). The screen is
redrawn at a steady 25 frames a second, with two ticks per frame (`FRAMES_PER_DRAW`,
`TICKS_PER_FRAME`). A vertical-sync event handler counts frames, so the buffers flip on every
second sync even if drawing a frame takes more than one sync's worth of time. Timers such as
the death pause count game ticks, not drawn frames.

### Timing

A drawn frame (1/25 s) is 80,000 cycles. Measured in jsbeeb, walking and scrolling uses about
31,000-34,000 of them, leaving about 45,000 for moving meanies, balloons, daggers and music:

| Step | Cycles |
|---|---|
| Erasing Trogg | about 8,500 |
| Drawing him (fully transparent bytes are skipped) | 13,000-15,500 |
| Game logic, including collisions (per tick, two ticks per frame) | about 3,500 |
| Repainting a newly scrolled-in column | 8,000-11,000 |
