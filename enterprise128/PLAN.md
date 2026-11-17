# Plan: Frak! for the Enterprise 128

Status: **planning.** Nothing is built yet.

The CPC 6128 version (`../cpc6128`) is a Z80 port of the BBC Master version, and it has already
solved most of the problems this port will meet: the BBC's 6502 code turned into Z80 routine by
routine, a 128K machine paged 16K at a time, two screen buffers, the background cache, the draw
log and the compiled meanie. So this port starts from the CPC version and changes only what the
Enterprise's hardware makes different. Those changes are:

- the **screen**: Nick's line parameter table replaces the CPC's 6845 CRTC;
- the **machine layer**: Dave's paging, interrupts and keyboard replace the CPC's gate array and
  PPI;
- **loading**: EXOS and EXDOS replace AMSDOS.

The first milestone is **the whole game running without music**: the attract screen, the
menus, all 55 levels and the level-complete screen, on an Enterprise 128 from a disk image,
checked by the CPC version's tests (adapted). The music and sound effects player is replaced by
stubs, and the front end is packed if it's needed to make room. Retuning (Dave's sound) and
re-optimising come after that milestone.

Facts about Nick and Dave marked *(check)* are from memory. Each is settled by the phase that
first relies on it, with a test, before anything is built on it.

## The idea

### One screen shape: the BBC version's

The CPC can only show a 16K screen, so its version uses two shapes: 256x256 for sideways levels
and 320x200 for up-and-down ones. Nick can show anything, so the Enterprise uses **320x256 in
4 colours for both kinds of level**. That's the BBC version's MODE 1 screen, so the view's
bands, clipping and HUD positions come from the BBC version, with the code from the CPC version.

- **80 bytes a line, 256 lines: 20,480 bytes a buffer.** It's double-buffered, as on the CPC.
- **The layout is linear.** Line y follows line y-1, 80 bytes on, with no `&800` steps between
  the lines of a character row.
- **Each buffer is a ring** in level coordinates, as on the BBC and CPC. Level byte column `c`
  on line `y` is always at `base + (y * 80 + c) MOD 20480`, however far the view has scrolled.
  So a scroll only needs the newly exposed column or row painting, and the draw log, save
  records and repainting keep working as they do now.
- **Scrolling moves the start address.** Sideways it moves 2 bytes (one Nick slot, 8 pixels) a
  step, the same as the CPC's step. Up and down it moves 640 bytes (a character row), the same as
  the BBC's step. The view scrolls in the BBC version's bands: it stays put while Trogg is between
  120 and 200 pixels across the window, and while his feet are between 96 and 176 lines down it.
- **Nick doesn't wrap**, so the line parameter table does it. The playfield is split into two
  line parameter blocks (LPBs) at the line where the ring wraps, the second starting at `base`.
  Whatever line crosses the wrap point reads on past the end of the ring, into **a mirror line**
  (80 bytes): the ring's first 0-80 bytes are copied there before each flip. That's at most one
  LDIR a frame, and the plotter never has to know about it.
- **Each ring ends on a page boundary**, so the plotter's wrap test is a compare of the address's
  high byte.
- **Flipping buffers** is done in the vertical interrupt (Nick's VINT through Dave), by pointing
  Nick at the other buffer's table (ports `&82`/`&83` *(check)*) or by rewriting the LPBs.
- **The four colours are each LPB's palette entries**: the level's background colour, black,
  magenta and yellow, as on the BBC and CPC.

### Memory

Video RAM is segments `&FC-&FF` (Nick addresses `&0000-&FFFF`); segments `&F8-&FB` are the
128's ordinary RAM. When the Z80 uses video RAM it has to wait for Nick, so the code and data
used most often stay in `&F8-&FB` *(check: Dave's wait-state settings, port `&BF`)*.

Where the screens go, as Nick sees it:

| Nick address | Size | Contents |
|---|---|---|
| `&0000-&4FFF` | 20,480 | buffer 0's ring |
| `&5000-&509F` | 160 | buffer 0's mirror (one line is needed; the second is spare) |
| `&50A0-&50FF` | 96 | spare |
| `&5100-&A0FF` | 20,480 | buffer 1's ring |
| `&A100-&A19F` | 160 | buffer 1's mirror |
| `&A1A0-&BFFF` | 7,776 | spare: in segment `&FE` |
| `&C000-&FFFF` | 16,384 | segment `&FF` |

How the Z80 sees memory while a level plays. Dave pages any segment into any of the four
pages *(check: ports `&B0-&B3`)*, so this keeps the CPC's arrangement:

| Z80 page | CPC | Enterprise |
|---|---|---|
| `&0000-&3FFF` | low RAM: code, tables, save areas, level tables, stack | segment `&F8`, with the same contents |
| `&4000-&7FFF` | the window: base RAM (levels) or extra banks 0-3 | the window: segment `&F9` (graphics), `&FA` (logic), `&FB` (background cache and slow save areas), `&FF` or `&FE` |
| `&8000-&FFFF` | the two screen buffers, side by side | the buffer being drawn: `&FC`+`&FD` (buffer 0's ring at `&8000-&CFFF`) or `&FD`+`&FE` (buffer 1's at `&9100-&E0FF`) |

Only the buffer being drawn needs to be visible, so pages 2 and 3 are paged with it. The same
segment (`&FD`, or `&FE` for the window) can be paged in twice.

The CPC's banks, and where they go:

| CPC | Size | Enterprise |
|---|---|---|
| low RAM `&0040-&3FFF` | 14.6K used, 1.4K free | segment `&F8`: the same. The program loads at `&0100` (EXOS's type 5 files) rather than `&0040` |
| bank 0: graphics | 16,384 | segment `&F9`: the same (the code tables are converted if Nick packs its pixels differently) |
| bank 2: logic | 15,549 | segment `&FA`: the same |
| bank 3: background cache, slow save areas | 16,384 | segment `&FB`: the same |
| base RAM: the levels, packed | 12,285 | segment `&FF` (after the program takes the machine from EXOS, which keeps its own variables there) |
| base RAM: the level loader | 3,974 | segment `&FE`'s spare, at Nick `&A1A0`. It runs where it is, with `&FE` paged in at `&C000`, so it isn't copied; while a level loads, `&FC` is paged in at `&8000`, so the unroller's workspace (`&8A00` up) is where it is on the CPC |
| bank 1: the music player and tunes | 5,956 | **stubs for now** (see "Sound") |
| bank 1: the compiled meanie | up to 3,260 | segment `&FE`'s spare, after the loader (542 bytes to spare) |
| bank 1: the front end and records | 4,800 | **packed** in segment `&FF`, above the levels and the LPTs. It's unpacked into the background cache's segment `&FB` when the menus come up, as the BBC version unpacks its front end into bank 7; the records (440 bytes) move out to low RAM, which must keep them |
| the screens | 32,768 | 41,280 (above) |

Segment `&FF` would hold 12,285 (levels) + about 512 (two LPTs) + the packed front end. The BBC
version's front end packs to 72% of its size, and if the CPC's does too, it's about 3.5K, which
leaves about 100 bytes. That's too close to plan on, so phase 2 measures it, and the fallbacks
are, in order: pack the level loader too (as the BBC version does: about 1.2K saved), move the
packed front end to low RAM's spare 1.4K plus `&FE`, or move the slow save areas.

Waiting for Nick costs time in `&FC-&FF`: the screens (unavoidable), the loader and levels (only
while a level loads), and the compiled meanie (each frame). The meanie is the only one that
matters to the frame rate, and moving it can wait for the optimisation pass.

## Phases

Each phase has a test that must pass before the next starts, as in the CPC version. The tests
are the CPC version's, adapted, on MAME's Enterprise 128 driver.

| Phase | | Test that must pass |
| --- | --- | --- |
| 0 | Toolchain and harness | `boot.mjs`: the program loads, takes the machine over and sets `ready` |
| 1 | Machine layer and screen | `screens.mjs`, `machine.mjs` |
| 2 | Memory map | the build's ASSERTs, and a table of what each segment holds |
| 3 | Plotter and drawing | `plot.mjs` |
| 4 | Levels and background | `levels.mjs` |
| 5 | Game logic | `connections.mjs`, `logic.mjs` |
| 6 | Main loop and scrolling | `frames.mjs`, `fps.mjs` |
| 7 | Front end | `front.mjs` |
| 8 | Release: the disk image, from cold, on a real machine | `front.mjs` and `frames.mjs` with `EP_COLD=1`; plays on a real Enterprise 128 |

### Phase 0: toolchain and harness

- **Assembler:** RASM 3.3.1, as the CPC version, with the same `build.sh` shape. It needs the
  BBC version built first, for its graphics and levels.
- **Output:** an EXOS type 5 program (a 16-byte header, then code that loads at `&0100`) for
  the low RAM, and data files for the segments, on an EXDOS (FAT, 720K) disk image. *(Check: how
  EXDOS starts a program from a disk at power-on.)*
- **Harness:** `tools/emu` from the CPC version, with `mame.mjs` running MAME's `ep128` driver
  and `steps.lua` peeking and poking by segment rather than bank. MAME needs the Enterprise's
  ROMs (EXOS, and EXDOS for the disk), from a directory in `EP_ROMS` as `CPC_ROMS` is for the
  CPC. Until the disk loads, the harness can load the files straight into their segments, as
  the CPC harness's `load` step does, so phases 1-7 don't wait on EXDOS.
- **Test:** the program loads, takes the machine from EXOS (interrupts off, its own handler at
  `&0038`, its own stack), and sets `ready`.

### Phase 1: machine layer and screen (`src/machine.asm`)

- **Paging:** `bank_select` pages a segment into the window (port `&B1` *(check)*), keeping a
  copy as `ga_ram` does; `screen_select` pages a buffer's two segments into pages 2 and 3.
  `bank_test` checks every segment at start-up.
- **Interrupts and ticks:** 50 a second from Nick's VINT through Dave (port `&B4`: enable and
  reset the latch *(check)*), with the vertical sync's LPB marked for it. The main loop runs a
  game tick for each vertical sync since it last looked, as now.
- **Where the raster is:** `restore_chase` needs to know where the raster is, which the CPC
  works out from the gate array's six interrupts a frame, 52 lines apart. Here, the playfield's
  LPBs are split into bands about 52 lines apart, alternately with and without VINT, so the
  handler can count them *(check: which edge of VINT Dave interrupts on)*. LPBs after the first
  can carry on from the last one's address, without reloading it *(check: Nick's RELOAD bit)*.
- **Keyboard:** 10 rows of 8 keys, a row selected and read through port `&B5` *(check)*, read in
  the interrupt handler into `keys[]` as now. The `KEY_` constants become the Enterprise's
  matrix positions; the keys are the same (Z X O K, cursor keys, Space, Return, Escape, P, Y, M,
  S, and L R U D J and the digits for typed commands). Joystick: the internal one and the
  external port *(check)*.
- **The screen:** the line parameter table (two of them, one for each buffer), built from the
  view's scroll position: the border and sync LPBs as EXOS makes them, then the playfield's
  bands with the wrap split, all 312 lines.
- **Pixels:** settle how Nick packs 4 pixels into a byte. The CPC's Mode 1 and the BBC's MODE 1
  pack them the same way, so the graphics bank's code tables are the screen's bytes as they
  are. If Nick packs them differently, `gfx.py` converts the 1K of code tables and the HUD's
  nibble tables; the sprites, as 5-pixel codes, stay as they are.
- **Tests:** `screens.mjs`: a test pattern shown in both buffers, scrolled both ways across the
  wrap point, flipped at the vertical sync, and every line of the screenshot is what it should
  be. `machine.mjs`: 50 ticks a second, every key, every segment.

### Phase 2: memory map

Lay the segments out as above and measure everything that has to fit, with the front end packed.
Pack it with the BBC version's packer (`tools/pack.py`: LZ77 in the style of ZX0) and port its
unpacker to the Z80, since the loader may want packing too. ASSERTs in the build check every
region, as the CPC version's do. If segment `&FF` doesn't fit, take the fallbacks in order.

### Phase 3: plotter and drawing (`src/plot.asm`)

This is the CPC's plotter with a new screen layout. The CPC version works out a level position
as `page + (y MOD 8) * &800 + ((y / 8) * width + c) MOD &800`; here it's `base + (y * 80 + c) MOD
20480`.

- `make_lines` and `rowoff` become one table of line offsets.
- The column routines step 80 bytes a line, and lose `next_row`. They keep the CPC version's
  unrolled character cells. An image whose column crosses the end of the ring takes a slower
  path that tests each line, so the unrolled path never has to. The compiled meanie already
  works this way on the CPC (it's only used where none of its lines crosses the end of a 2K
  block).
- The compiled meanie emits `LD DE,80 - n : ADD HL,DE` between lines.
- The draw log, save records and `restore_saved` are unchanged.
- **Test:** `plot.mjs`: every image, clipped, saved and put back, the yoyo string and the
  compiled meanie, matching the reference byte for byte, with the reference's addressing
  changed to the linear ring.

### Phase 4: levels and background (`src/level.asm`, `src/bg.asm`)

The level loader and unroller as they are (the cache's format doesn't depend on the screen's
layout). `repaint_column` steps 80 bytes a line and `repaint_row` paints 8 lines of 80 bytes,
both wrapping at the end of the ring. Both level kinds now use the one window, 320x256.
**Test:** `levels.mjs`: all 55 levels' tables, background caches and repainted windows match
the converter.

### Phase 5: game logic (`src/logic.asm`, `src/trogg.asm`, `src/commands.asm`)

Unchanged, except for the window's size: the CPC's two window shapes become the BBC version's
one, so the view's bands and clipping come from the BBC version.
**Tests:** `connections.mjs` (Trogg moves as in GameMaker on all 55 levels) and `logic.mjs` (the
logic does what the BBC version's does, tick for tick).

### Phase 6: main loop and scrolling (`src/play.asm`)

The CPC's frame loop. Scrolling sets the playfield's LPBs (and the mirror line) rather than
CRTC R12/R13, and the flip happens at the vertical interrupt, at most every two vertical syncs.
Scrolling is one mode, the BBC version's, with the CPC's 8-pixel steps sideways.
**Tests:** `frames.mjs`: every frame drawn is what the game's state says it should be, with
`render.mjs`'s window made 320x256 for both kinds of level. `fps.mjs`: the frame rates, to
compare with the CPC version's and the BBC version's (not a pass or fail yet).

### Phase 7: front end (`src/front.asm`)

The CPC's front end, packed, unpacked into segment `&FB` when the menus come up (the level's
background is rebuilt when a level starts anyway), with its records kept in low RAM. It's drawn
in the 320x256 screen with the BBC version's layout (256 pixels wide, 32 pixels in). The font:
the Enterprise's own, copied from the EXOS ROM at start-up, as the CPC version copies its own
from its lower ROM *(check: where it is)*.
**Test:** `front.mjs`: from the attract screen through the menus into a level, won, then the next
level, and back to the menus with its record.

### Phase 8: release

The disk image boots by itself on an Enterprise 128 with EXDOS; the program loads its segments
through EXOS before it takes the machine over. It can't load the levels straight into `&FF`
while EXOS is using that segment, so it loads them into a screen buffer first and copies them
across afterwards.
**Tests:** `front.mjs` and `frames.mjs` with `EP_COLD=1` (memory filled with garbage first), and
playing on a real Enterprise 128.

## Sound

`src/sound.asm` is replaced by stubs with the same interface: `snd_tick` (called from the
interrupt) and `snd_keys` do nothing, and the requests the logic makes (`snd_music_req`,
`snd_sfx_req`, `snd_sfx_req2`, `snd_cur`, `snd_music_opt`) are plain variables in low RAM, so
the logic bank is unchanged. Later, the player is ported to Dave. It has three tone channels
and a separate noise channel, like the BBC Master's sound chip, so the BBC version's voices may
map onto it more directly than onto the CPC's AY. It also needs about 6K, which has to come
from re-optimising the memory map.

## Risks

- **Segment `&FF` is nearly full** (above). The fallbacks are known, and phase 2 settles it.
- **EXDOS and EXOS may keep RAM** that the loader needs while it reads the files. Load into
  segments EXOS gives out (EXOS's segment allocation), and check that a 128K machine with EXDOS
  gives out enough.
- **The ROMs:** MAME's `ep128` driver needs the Enterprise's ROMs, which this repository can't
  include.
- **Waiting for Nick:** the plotter writes only to video RAM, and the CPC's measurements of
  where the time goes won't carry over. `fps.mjs` and a port of `profile.mjs` measure it, for
  the optimisation pass after the first milestone.
