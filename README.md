# Frak! for the BBC Master 128

A back-port of the Steam/HTML5 version of **Frak!** to the BBC Master 128, written in 6502
assembly for [BeebAsm](https://github.com/stardot/beebasm) (using the 65C02 instructions the
Master's 65SC12 has: STZ, BRA, PHX/PLX, INC A and so on, but not Rockwell's bit instructions). It works from the data and logic of
the web version (the `steamfrak` repository).

**Status: milestone 7.** All 55 levels are in memory at once and can be played, one after
another, including the 19 that scroll vertically:

* Trogg walks, jumps, falls (dying from long falls) and climbs.
* The screen scrolls smoothly at a steady 25 frames a second, with the game logic at 50 ticks a second.
* Gems and keys can be collected.
* Touching a meanie kills Trogg, with the "FRAK!" speech bubble.
* The yoyo (Space or P): it goes out about 80 pixels while the key is held, on a string drawn
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
* The first attract screen ("The Cast", as in the Steam version), in the Master's own font,
  read straight from the MOS ROM (sideways ROM 15, `&B900`). Space, Return, P or Y goes on to:
* The menus, simplified from the Steam version's 3x3 button grids: Replay (the last level),
  Difficulty (Easy, Hard, Harder, Insane), Training and the six groups of levels, each a 3x3
  grid of levels with the column's meanie and the level's name. Z X O K (or the cursor keys)
  move, Space, Return, P or Y choose, Escape goes back (and, while playing, back to the menus).
* The level timer (top left, while Trogg is alive) and his rating (bottom right: gold, silver,
  bronze or a tick, for 0, 1, 2 or more restarts from a checkpoint), as in the Steam version.
  Completing a level shows its time (to a thousandth of a second), whether all the gems were
  collected, the medal and a trophy over Trogg, for 4-7 seconds, then the next level starts.
* Records: each level's best time, gem medal (completed with all the gems), and best rating at
  each difficulty. The level buttons show the level's target time, the best time, and the three
  medals (rating, gems, stopwatch: beating the target time). There's nowhere to save them, so
  they last until the machine is switched off.
* Music and sound effects, from the Steam version's own (see "Sound" below): the Frak! theme,
  "A Little Bag of Weed" (levels with Poglets) and "The Man Who Once Was I" (levels with
  Hooters), the victory tune, the attract, menu and level-select tunes, and Ching, Squeal, Pop,
  the dagger hit and Trogg's footsteps. M switches the music between all its tracks, just the
  first (as the Steam version's "mono") and off; S switches the sound effects off and on.
  Footsteps are heard only when the music isn't playing all its tracks, as in the Steam version.

* Bouncing platforms (the Bouncing levels), with their springs (see "Movement and physics").
* Movable platforms (the Placing levels, with a yellow line under them): the yoyo picks one
  up, Trogg carries it above his head, and letting go of the yoyo key while the yoyo is
  going out drops it there (see "Movement and physics").

Not done yet: the Pugwash tune (an easter egg in a settings screen that isn't here).

## Building

You need BeebAsm and Python 3 with Pillow, and the `steamfrak` repository alongside this one:

```sh
pip install pillow
BEEBASM=/path/to/beebasm ./build.sh                # STEAMFRAK=../steamfrak
LEVEL=room_B_1 BEEBASM=/path/to/beebasm ./build.sh # the level Replay starts with (default room_A_1)
DIFFICULTY=6 BEEBASM=/path/to/beebasm ./build.sh   # starting difficulty: 0 none, 1 Easy (default), 2 Hard, 4 Harder, 6 Insane
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

`node check_levels.mjs` (in `tools/emu`, after `./build.sh`) checks the level loader: it visits
every playable level and compares what the 6502 built (the platform, ladder, object and moving
sprite tables, and every byte of the unrolled background) with what the converter expects.

`node connections8.mjs` (also in `tools/emu`) checks that the 6502 code moves Trogg exactly as
the GameMaker original does. It's the platform-and-ladder connection finder from the steamfrak
repository (`tools/connections.js`: the original's unused `GraphFind` search, and the
original's scripts transcribed with GameMaker's epsilon comparisons, on the GameMaker project's
rooms), with the 6502 version as the other side: for each level, jsbeeb loads it, then
`trogg_standing`, `trogg_falling` and `trogg_climbing` themselves are run, on a small 6502
interpreter (`cpu6502.mjs`) against that memory, from every pixel of every platform and every
point of every ladder, holding every key. It needs the steamfrak repository alongside this one
(`STEAMFRAK=...` otherwise) and the GameMaker project alongside that. All 55 levels come out the
same as the original: every start (about 520,000) ends the same way at the same tick and
position, and every connection (about 4,100) is the same. (Three things in the original's rooms are off by half a pixel or worse, which were bugs: a
ladder in D_9 at x = 48.5, a key in B_6 at y = 40.5 and a Hooter in C_6 at x = 74.5. The
converter rounds them down to whole pixels, so the D_9 ladder catches Trogg one pixel further
left than the original's, and that level's search shows it, under the ladder's two names, L(48)
and L(48.5). A platform 368,215 pixels off to the side of Jungled Up is left out altogether,
and is listed: Trogg can never get near it.)
`--trace=room_A_1,572,83,1` shows one jump, tick by tick, in both.

## How it works

| Part | Where |
|---|---|
| Data converter: sprites, the level pack | `tools/convert.py` |
| Level loader: unpacking a level, ladders' extensions, moving platforms' ranges | `fetch_level`, `load_level`, `meanie_settings`, `moving_platform`, `scan_left` etc. |
| Music and sound effects | `snd_tick`, `snd_quarter_beat`, `snd_voice`, `snd_output` (`src/sound.asm`, bank 5); `play_music`, `play_sfx`, `level_music`, `footsteps`; data: `tools/music.py` |
| Attract screen and menus | `fe_main`, `fe_attract`, `fe_menus`, `fe_grid` (packed in bank 5, unpacked to bank 7 by `fe_stage` and `fe_unpack`); records: `fe_record`; text: `print_inline`, `print_char` |
| Unrolling the background into bank 7 | `bg_items`, `unroll_bg`, `unroll_item`, `store_column`, `dict_find` |
| Copying it back to the screen | `repaint_column`, `repaint_rect`, `cache_seek`, `copy_cell` |
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
| Generated data | `src/gen/*`, `build/GFX4-5`, `build/SPANS`, `build/PACK`, `build/FRONT.lz` and `build/OVERLAY.lz` (by `tools/pack.py`) |

### Memory map (Master 128)

| Address | Contents |
|---|---|
| `&0000-&008F` | zero page: pointers and the plotter's variables |
| `&0400-&07FF` | save area for the main-RAM screen buffer (BASIC's workspace, unused); while a level loads, the packed level |
| `&0900-&0CFF` | save area for the shadow screen buffer (RS423/cassette buffers, soft keys, UDGs); while a level loads, a column of the background and the list of things in it |
| `&0E00-&10FF` | other variables: object states, checkpoint, draw logs, moving objects |
| `&1100-&2FFF` | drawing code and its tables, each image's size and origin, the sound player's variables, instruments and pitch and loudness tables (231 bytes free) |
| `&3000-&7FFF` | MODE 1 screen, **double buffered**: main RAM and shadow RAM. While a level loads (with the screen blanked) it holds the loader's workspace (`&3000-&4FFF`: the dictionary's hash table, a row of the background, the lines being built) and the loader itself (`&6000`) |
| SWRAM banks 4-5 | sprites, pre-shifted, including unshifted copies of the platforms and ladders to unroll backgrounds from (23.1KB); in bank 5 after the sprites, the music and sound effects player and the tunes (4.2KB at `&9F58`, see "Sound"), then the front end, packed (2.5KB, see below), then where shift 3 of each image is (`img_bank3`, `img_lo3`, `img_hi3`, 240 bytes at `&BB10`), then a save area for meanies flying off (the top 1KB); 184 bytes free |
| SWRAM bank 6 | collision spans and tables (from `&8000`), the **game logic** (to `&AE00`), then the current level's tables and the second save area for meanies flying off (368 bytes free). Stays paged in while playing |
| SWRAM bank 7 | the current level's background, unrolled when it starts (`&8000-&A9FF`, see below), or, while the menus or the level-complete screen are up, the front end (unpacked to `&8000`); the front end's records and the unpacker (`&AA00`); the code that paints the background; where shifts 0-2 of each image are (`img_bank0-2`, `img_lo0-2`, `img_hi0-2`, 720 bytes: `plot` and the background unroller page bank 7 in to read them); the level loader, the code that starts a level and the boot code, packed (3.2KB at the top, unpacked to `&6000` when a level loads); 167 bytes free |
| HAZEL (`&C000-&DFFF`) and ANDY (`&8000-&8FFF`) | **all 55 levels**, packed: 11.8KB, about 215 bytes each. `&8800-&88FF` of ANDY is left to the MOS |

### The packed front end

The attract screen and the menus (their code, the level names and target times, and the
menu icons) are only needed while the menus are up, and at that point the level's unrolled
background in bank 7 isn't. So the front end is assembled to run at `&8000` in bank 7 and kept
packed in bank 5. Each time the menus come up, `fe_stage` (in bank 5) copies the packed data to
the screen buffer that isn't being shown, and `fe_unpack` (in bank 7) unpacks it to `&8000`.
The records (best times, gems and ratings) sit just above, at `&AA00`, with `fe_record`, so
they stay put. The next level's background replaces the front end when a level starts.

The level-complete screen's text (`fe_win`) is in the front end too: when a level is won,
`win_screen` unpacks the front end into bank 7 (the level's background isn't needed any
more), clears the screen and draws Trogg and his trophy (`win_sprites`, in bank 6), then the
time, the gems and the medal.

The code that's only needed when a level starts (`level_init`, `slow_init`, `spring_item`)
and at boot (`boot`, `install_vsync_counter`) is in the packed loader. A level's start is saved
as a checkpoint when it's loaded, so a death before the first key goes back there like any
other (`restore_checkpoint`), but as GameMaker's room restart does: the restarts and the timer
go back to 0.

`build.sh` assembles twice: the first pass's `FRONT` (and the level loader, `OVERLAY`) is
packed by `tools/pack.py`, and the second pass puts the packed data in place.

The packing is LZ77 with bit-level lengths, in the style of ZX0: blocks of literal bytes and
copies from earlier in the output, the lengths and distances as Elias gamma codes read a bit
at a time, and a copy straight after literals can reuse the last distance (code tends to use
the same addresses over and over). The compressor picks the cheapest encoding by dynamic
programming, and checks it by unpacking it the way the 6502 does. The unpacker (`unpack`, in
bank 7) is about 120 bytes. The front end packs to 72% (3,124 bytes to 2,250) and the loader,
with the tables only it needs (where each level is in the pack, and the moving meanies'
settings), to 66% (4,470 to 2,968). The unpacked
front end can grow to 10.75KB (`&8000-&A9FF`) without needing more of bank 5 than its packed size.

All 55 levels stay in memory, so nothing is loaded from disc after the start. At boot, `!BOOT`
loads the level pack at `&3000` and `copy_pack` copies it into HAZEL and ANDY with interrupts
off. HAZEL is normally the filing system's workspace, so the game closes the `!BOOT` file first
and never uses the disc again. When a level starts, `bring_overlay` blanks the screen and unpacks the level
loader into screen memory (it's packed like the front end, by `tools/pack.py`), `fetch_level` copies the level out (again with interrupts off) and
`load_level` unpacks it.

### Sound

The Steam (and HTML5) version synthesises its music the way a BBC Micro would: each tune is a
handful of tracks of note strings (`'c3 G3 A2 -2 e2? +4'`: pitch, length in quarter beats, an
optional pitch envelope), each note played with an instrument whose loudness follows BBC
Micro style ENVELOPE parameters (attack, decay, sustain, release). `tools/music.py` reads those
straight from its `js/audio.js` (parsing the note strings as its `NotesToArray` does) and
writes them for the player, `src/sound.asm`:

* Each tune keeps the Steam version's structure: its patterns (sub-tracks), stored once, and for
  each track the order they're played in. A note is usually one byte (pitch and a length of
  1-3 quarter beats), else two (any length up to 32, and a pitch envelope). All seven tunes take
  2.4KB.
* The player runs 50 times a second, from the vertical sync event, with bank 5 paged in. On
  each quarter beat (a 16-bit tempo accumulator keeps the Steam version's tempo exactly) each
  track starts its next note; every tick each note's loudness envelope (the Steam version's
  ramps, as straight lines at 50Hz) and pitch envelope (resampled from 60Hz) move on, and the
  pitch becomes the sound chip's 10-bit divider (a table for one octave of eighth-semitones,
  shifted for higher octaves).
* The chip's lowest note is about 122Hz (a divider of 1023). The bass lines of four tunes (A
  Little Bag of Weed, The Man Who Once Was I, the victory tune and the select screen's) go
  lower, so those tracks are played an octave up all through (rather than only their lowest
  notes, which broke the tune up).
* The chip has three tone channels and a noise channel, and the tunes have up to six tone
  tracks, though rarely more than three sound at once. The channels are given out each tick
  (`snd_output`): a voice that's sounding keeps its channel; one that starts takes a free
  channel, else the channel of a voice at least 8dB quieter (the tail of a note, say); the tone
  sound effect takes a free channel, else the quietest, so it no longer cuts out the tune.
  Drums are noise (the Steam version's drums are recordings of the BBC's own white noise at its
  three rates, so they map straight back). Only changes are written to the chip.
* Loudness: the chip has 16 levels, 2dB apart. The Steam version's drums are about 20dB louder
  than its tunes (its noise samples are quiet, so it turned them up), which here would leave the
  tunes barely audible, so each instrument is set against the loudest of its kind instead.
* Sound effects are notes on two more voices, one on a tone channel and one taking over the
  noise channel while it sounds: their pitches, pitch sweeps and loudness come from the Steam
  version's samples (Ching rises from about 450 to 650Hz as it fades; Squeal goes up and down
  a minor third; Pop, the dagger hit and footsteps are bursts of noise).
* The game asks for tunes and sound effects by setting a byte in main RAM (`play_music`,
  `play_sfx`); the player picks them up on its next tick. M and S are read by the player too,
  so they work everywhere.
* `tools/emu/music8.mjs` checks the player against the Steam version: it runs the web
  version's `js/audio.js` itself (its WebAudio calls caught) and the game's own player (on a
  6502 interpreter, catching the sound chip writes, or with `--live` as jsbeeb hears it in a
  level), and reports, for each track, the notes and drum hits that aren't on the chip, how much
  of the time it sounds it's there, and how loud. With `--sfx`, sound effects interrupt.
  Everything is there but a few clashing note tails (and the raised bass lines). One known
  difference: when a tune loops, the original fast-forwards through its introduction with the
  sound on, so a note left sounding at the end of it carries on; here it's cut off.

### Levels

A packed level is a 14-byte header, a palette of the (up to 16) sprites it uses, then 3 bytes
for each platform, ladder, object and moving meanie: its x and y in 10 bits each, and which
palette entry it is. Moving meanies then have a byte of settings each (an index into a table of
speeds, sleeps and ranges shared by all levels), and moving platforms two bytes: which platform,
and which way it scans and starts moving.

Everything else is worked out when the level starts, as GameMaker did when a room started:

* each ladder's hidden extension up to a platform just above it (`LadderAdd`);
* each moving platform's range, from the nearest platforms to each side (`oPlatform`'s scan,
  done here by one pass over the platforms for each direction, not pixel by pixel);
* the platform each Scrubbly walks and the ladder each Poglet climbs;
* the background: the static platforms and then the ladders are drawn, shifted to their pixel
  positions, one byte column at a time into a buffer, and each column is stored in bank 7 (see
  below).

### The background

Each level's background is held in bank 7 as a **dictionary of character cells**, and a list of
cell numbers for each column (a horizontally scrolling level) or each row of character cells
(a vertically scrolling one, 80 cells wide) - "lines", either way:

* The dictionary holds each distinct non-empty character cell (8 bytes) once, numbered 0-1023
  in order of first use, in pages of 256 cells. A page is 8 tables of 256 bytes, one for each
  line of a cell, so copying a cell to the screen is just 8 indexed loads. A level uses as many
  pages as it needs (1-3).
* Each line has three masks - which of its cells aren't empty (bit 7 of the first byte is the
  top one, or the leftmost), and bits 8 and 9 of their numbers - 4 bytes each for a column, 10
  for a row, then one byte for each non-empty cell: the low 8 bits of its number.
* `&8000` and `&8100` hold each line's address; the lines follow the dictionary.

The levels have 156-549 distinct cells each, a lot more than the handful of platform tiles,
because a tile lands in its cells at whatever vertical offset its platform has, at any of four
pixel shifts, and overlapping ladders add more. Backgrounds take 4.0-8.7KB.

`paint_line` (in bank 7) paints any run of cells along a line: a column for a horizontal scroll,
a row for a vertical one, and part of either when a moving sprite is erased.

While unrolling, `store_line` looks each cell up in the dictionary with a hash table (the sum of
its 8 bytes) and chains, in screen memory. The lines are built in screen memory too, then copied
to just after the dictionary once its size is known. Loading takes 1.9 seconds for Read&Weep,
3 seconds for the busiest level (C_4).

### Sprites

A MODE 1 byte holds 4 pixels, so a sprite drawn at an arbitrary x needs one copy for each of the
four pixel positions within a byte. The plotter picks the copy from the low two bits of x. The
converter only stores the copies the game can use:

* everything that moves (Trogg, meanies, balloons, daggers, the yoyo, moving or movable
  platforms, springs) gets all four;
* static keys, gems and meanies get only the pixel positions that some level places them at;
* static platforms and ladders get just the unshifted copy, which the background is unrolled
  from.

The build stops with an error if a level places something at a position with no stored copy.

Identical images share their data: Trogg's five climbing frames are only two different pictures.
And Trogg's standing and walking frames are drawn in two parts: his **body** (the top 24 rows,
the same in all of them) and one of four sets of **legs** (the bottom 10 rows); standing is just
the first walking frame. The full frames are kept only as collision outlines (their spans). That
halves Trogg's sprites, from 15.6KB to 7.1KB, for about 700 cycles a frame (two plots instead of
one).

### Screen and scrolling

* MODE 1 (320×256, 4 colours): background (cyan/green/red per level), black, magenta, yellow.
  That is exactly the Steam version's palette, and its 256-pixel-high playfield maps 1:1.
* Scrolling uses the CRTC start address: horizontally in 4-pixel steps, vertically a character
  row (8 lines) at a time. Following Trogg exactly, as the Steam version does, would jump the
  view back 4 (or 8) pixels for every 4 (or 8) he moves, so it scrolls in bands
  (`band_scroll`, `band_scroll_v`): the view stays put while he's between 120 and 200 pixels
  across the window (his feet between 96 and 176 down it); once he's past one end, it
  scrolls until he's at the other end (but not past it), or the level's. Horizontally that's a
  column a frame, or more when a frame takes more than two ticks (twice his walking speed);
  vertically a row a tick, at most 4 a frame (twice his fastest fall). A level starts (and
  restarts) with him in the middle. Screen memory is addressed in **level coordinates**: level byte-column C on
  character row R is always at `&3000 + ((C + R*80) MOD 2560) * 8`, however far the screen has
  scrolled, either way. So a scroll only needs the newly exposed column or row drawing, and
  sprites are drawn and erased in level coordinates.
* Since column C and C+80 (or row R and R+32) share screen memory, everything is clipped to the
  window: the plotter clips to its columns and rows (or to the band being repainted).
* The game draws into whichever of main and shadow RAM is not on display, then flips them at
  vertical sync, so there is no flicker or tearing. Each buffer remembers its own scroll
  position and the background saved under Trogg.
* Repainting a column or row copies its cells from the unrolled background in bank 7 (see "The
  background" above). Keys, gems and meanies are then plotted on top.
* In vertically scrolling levels, as in the Steam version, balloons still start at the bottom
  of the level and daggers at the top; daggers are the up-and-down ones, falling faster than
  they move sideways, and both spread wider.

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

* The converter leaves them out of the unrolled background in bank 7, so erasing one just
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
  Meanies near the screen take turns to catch up with where they really are, so they move in
  steps of several pixels. Each drawn frame moves at most one Scrubbly, two Poglets and three
  Hooters (`turn_quota`). Moving platforms, and Scrubblies riding them, are shown where they are
  every frame.

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

Trogg's x is whole pixels, as in the original (he only ever moves a pixel at a time). His y is
kept in pixels and twentieths of a pixel (`ty`, `tyf`), and his y velocity in twentieths of a
pixel a tick (`tv`, + = up): in the original, gravity is 0.05, a jump starts at 1.25, a bounce
adds 0.10, and y is rounded to a multiple of 0.05 every tick, so everything its y and velocity
can be is a whole number of twentieths. So `trogg_standing`, `trogg_falling` and
`trogg_climbing` are straight ports of TroggStanding, TroggFalling and TroggClimbing, with
exact arithmetic, and the original's tests come out the same: PlatformFind's `ceil(y1) <= top <
y2` is the platforms at whole pixels in `[ceil(y1), ceil(y2))` (`platform_find_f`), LadderFind
compares fractional y with whole-pixel ladder ends (`ladder_find`), a jump from 1.25, terminal
velocity 4, a ladder grabbed only while not falling faster than 1.275, a landing at 1.6 or
faster deadly. (GameMaker compares reals with an epsilon, so its own floating-point errors in
these never matter; whole numbers don't have any.)

That includes the original's warts. A fall that crosses a platform's top between pixels stops
Trogg where he was, above it; then, as in the original, he's put on the next whole pixel down
(onto the platform, if it was less than a pixel below). Grabbing a ladder from a fall rounds
him to the nearest pixel (halves to the even one, as GameMaker's `round`). If two platforms
are at the same height in the same place, the first in the level counts.

Bouncy platforms (the Bouncing levels, with a spring under them): as in the original, Trogg
leaves a bouncy platform's top as fast as he was falling before that tick's gravity, plus twice
gravity, so each bounce goes a little higher than the last. A bouncy platform is marked by
bit 7 of its palette entry in the level pack. Springs under platforms that stay put are part
of the background (the loader adds them as background items, `spring_item`); the three under
moving platforms are drawn each frame with Trogg (`draw_springs`), so they show over meanies
where the Steam version had them under.

Movable platforms (the Placing levels, and two of the Bouncing ones): each is a slow sprite
that doesn't move by itself (`plat_moving` is 2 for them, 1 for platforms that move by
themselves), marked by bit 6 of its flags in the level pack, and drawn with a yellow line
under it (`draw_springs`, with `hline` in yellow). As in the original:

* The yoyo's length is 1.3 pixels a tick out, from 0, so it's kept in pixels and tenths
  (`yo_len`), which is exact. It goes out until it's 80 pixels or more.
* If the yoyo hits nothing else, isn't carrying a platform, and hasn't dropped one on this
  throw, it picks up the first movable platform it's in (`pick_up`), and turns back.
* A carried platform rides on the yoyo, 3 pixels in from it (rounded to the nearest pixel,
  halves to even), and otherwise sits centred above Trogg, its top 14 pixels above his feet
  (`carry_on_yoyo`, `carry_above`).
* Letting go of the yoyo key while it's going out (or it reaching full length) drops the
  platform where it is. It can then be stood on like any other platform.
* Standing on a movable platform still sets a checkpoint; the checkpoint keeps where the
  movable platforms are and what Trogg is carrying.

The game logic runs at 50 ticks a second (5/6 of the Steam version's 60): one tick per
vertical sync. The screen is redrawn at 25 frames a second (`FRAMES_PER_DRAW`), so normally
two ticks run per drawn frame. A vertical-sync event handler counts syncs. If drawing a busy
frame overruns, that frame simply runs three ticks, so the game speed never changes. Timers
such as the death pause count game ticks, not drawn frames.

Measured frame rates on Read&Weep: Easy holds 25fps. Hard dips to 24 and Harder to 21 at their busiest,
with 7 balloons and daggers on screen. Insane, with 8-9 on screen, runs at 21-22fps.

Levels with lots of moving meanies are still slow. A Scrubbly is 33×42 pixels: redrawing one
that has moved costs about 18,000 cycles in each buffer (8,000 to erase, 10,000 to plot), so
each move costs about 36,000. On Easy, B_1 (16 Scrubblies) runs at 17-19fps, B_2 (Poglets) at
16-18fps and B_3 (Hooters) at 12-15fps. D_3, with many moving platforms, runs at about 10fps.
D_1 holds 23-25fps. Of the vertically scrolling levels, C_1 and C_4 run at 13-17fps and D_2
at 9-13fps. The game speed stays right however slow the drawing gets.

### Timing

A drawn frame (1/25 s) is 80,000 cycles. Measured in jsbeeb, walking and scrolling uses about
31,000-34,000 of them, leaving about 45,000 for moving meanies, balloons, daggers and music:

| Step | Cycles |
|---|---|
| Erasing Trogg | about 8,500 |
| Drawing him (fully transparent bytes are skipped) | 13,000-15,500 |
| Game logic, including collisions (per tick, two ticks per frame) | about 3,500 |
| Repainting a newly scrolled-in column | 8,000-11,000 |
