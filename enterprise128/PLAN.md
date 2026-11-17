# Plan: Frak! for the Enterprise 128

Status: **the first milestone, but for a real machine;** then two speed-ups (see "After the first
milestone: speed"): 10.0 frames a second on average.

Phase 8 done, but for a real machine: the disk image runs the whole game on an
emulated Enterprise 128 with EXDOS and BASIC (`LOAD` at BASIC's prompt), from memory full of
garbage too (`disk.mjs`). What's left of the first milestone is playing it on a real one.

Phase 7 done: the whole game runs, from the attract screen through the menus, the
levels and the level-complete screen to the records (`front.mjs`), with no music yet. Only
phase 8 is left of the first milestone: the disk image starting by itself, and a real machine.

Phase 6 done: the game plays, on every level: the frame loop, scrolling and drawing
(`src/play.asm`) pass the CPC version's `frames.mjs`, every one of 6,600 frames byte for byte,
and `fps.mjs` measures 9.3 frames a second on average on ephl (the CPC version 10.3, the BBC
version 14.4). Next: phase 7, the front end.

Phase 5 done: the game logic (`src/logic.asm`, with the CPC version's `trogg.asm`
and `commands.asm` as they are) moves Trogg as GameMaker does on all 55 levels
(`connections.mjs`, but for D_9's half-pixel ladder, as for the BBC and CPC versions), and does
what the BBC version's does, tick for tick (`logic.mjs`: 440,000 ticks). Next: phase 6.

Phase 4 done: the level loader and the background (`src/level.asm`, `src/loader.asm`,
`src/bg.asm`) pass the CPC version's `levels.mjs` on all 55 levels: their tables, their
background caches, and the window repainted from the cache, byte for byte. Next: phase 5.

Phase 3 done: the plotter, the draw log and the compiled meanie, for the ring
buffers (`src/plot.asm`), pass the CPC version's `plot.mjs`, byte for byte, with cases across
the ring's end added. Next: phase 4.

Phase 2 done: the memory map, measured, fits (see "Memory"), and the Z80 unpacker
works (`unpack.mjs`). Next: phase 3.

Phase 1 done: The machine layer (paging, VINT interrupts, the keyboard) and the
screen (two 320x256 ring buffers, each shown through its own line parameter table, split
where the ring wraps, with a mirror line; flipped at VINT) work: `screens.mjs` checks every
pixel of 24 frames at six scroll positions, either side of the wrap, and `machine.mjs` the
ticks, every segment and every key. Next: phase 2.

Phase 0: the build (RASM, an EXOS type 5 program on an EXDOS disk image) and the harness,
on a headless build of ep128emu (`tools/ephl`) and on MAME. EXOS gives out segments
`&F9-&FE`: every one but page 0's and its own, so EXDOS leaves the whole memory map free.

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

Facts about Nick and Dave marked *(check)* are still to be confirmed. Each is settled by the
phase that first relies on it, with a test, before anything is built on it. Those marked
*(MAME)* are as MAME's Enterprise driver has them (`src/mame/enterprise/nick.cpp` and
`ep64.cpp`, `src/devices/sound/dave.cpp`), which is as far as the tests can check them until a
real machine does.

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
  Nick at the other buffer's table (ports `&82`/`&83` *(MAME: the table is 16-byte aligned, with
  its address's bits 4-11 in `&82` and bits 12-15 in `&83`'s low bits)*) or by rewriting the LPBs.
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
pages *(MAME: ports `&B0-&B3`, which read back too)*, so this keeps the CPC's arrangement:

| Z80 page | CPC | Enterprise |
|---|---|---|
| `&0000-&3FFF` | low RAM: code, tables, save areas, level tables, stack | segment `&F8`, with the same contents |
| `&4000-&7FFF` | the window: base RAM (levels) or extra banks 0-3 | the window: segment `&F9` (graphics), `&FA` (logic), `&FB` (background cache and slow save areas), `&FF` or `&FE` |
| `&8000-&FFFF` | the two screen buffers, side by side | the buffer being drawn: `&FC`+`&FD` (buffer 0's ring at `&8000-&CFFF`) or `&FD`+`&FE` (buffer 1's at `&9100-&E0FF`) |

Only the buffer being drawn needs to be visible, so pages 2 and 3 are paged with it. The same
segment (`&FD`, or `&FE` for the window) can be paged in twice.

The CPC's banks, and where they go, as phase 2 measured them (`tools/memmap.py`, from the CPC
version's own build; `src/layout.asm` ASSERTs it all):

| Segment | Z80 address | Size | Contents |
|---|---|---|---|
| `&F8` (page 0) | `&0000-&00FF` | 256 | restart vectors (EXOS's type 5 files load at `&0100`) |
| | `&0100-&3A2B` | 14,636 | the CPC version's low RAM, code and tables, moved up from `&0040` |
| | `&3A2C-&3BAC` | 385 | the records (moved out of the front end, which is unpacked afresh) |
| | `&3BAD-&3EFF` | 851 | *free*; the stack is at `&3F00-&3FFF` |
| `&F9` | `&4000-&7FFF` | 16,384 | the graphics (the CPC version's bank 0, as it is) |
| `&FA` | `&4000-&7CBC` | 15,549 | the game logic and its variables (its bank 2); 835 *free* |
| `&FB` | `&4000-&69FF` | 10,752 | the background cache (its bank 3), or, while the menus or the level-complete screen are up, the front end (4,800 bytes), unpacked to `&4000`, as the BBC version unpacks its front end into its bank 7 |
| | `&6A00-&7FFF` | 5,632 | the two slow save areas |
| `&FC-&FE` | (screens) | 41,280 | the two buffers, their rings and mirrors (above) |
| `&FE`, in the window | `&61A0-&7125` | 3,974 | the level loader, run where it is, with `&FE` at page 3 (`&E1A0`); while a level loads, `&FC` is at page 2, so the unroller's workspace (`&8A00` up) is where it is on the CPC |
| | `&7126-&7CA5` | 2,944 | the compiled meanie (the biggest, the Scrubbly's, is 2,927); 858 *free* |
| `&FF`, in the window | `&4000-&6FFC` | 12,285 | the levels, packed (the CPC version's base RAM, at the same address) |
| | `&7000-&7A4A` | 2,635 | the front end, packed (from 4,800, with the BBC version's packer) |
| | `&7A4B-&7EFF` | 1,205 | *free* |
| | `&7F00-&7FFF` | 256 | the two line parameter tables (Nick's `&FF00`) |

So segment `&FF` has 1.2K to spare, not the 100 bytes feared: the CPC's front end packs to 55%.
The level loader packs from 3,974 to 2,544, if more room is needed. The music player and its
tunes (5,956 bytes, 3,676 packed) have no room yet: they come back after the first milestone,
and will want the free pieces gathered together (2.9K in all), or something else packed.

Waiting for Nick costs time in `&FC-&FF`: the screens (unavoidable), the loader and levels (only
while a level loads), and the compiled meanie (each frame). The meanie is the only one that
matters to the frame rate, and moving it can wait for the optimisation pass.

## Phases

Each phase has a test that must pass before the next starts, as in the CPC version. The tests are the CPC version's, adapted, on a headless build of ep128emu (`tools/ephl`),
which emulates the video RAM's wait states and Nick's whole frame, so the frame rates it
measures are the real machine's. MAME's Enterprise 128 driver can run them too, as a second
opinion.

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
  the low RAM, and later data files for the segments, on an EXDOS disk image (`tools/mkdisk.py`:
  720K, FAT12; MAME's `ep128` driver reads it as a `.img`). *(Check: how EXDOS starts a program
  from a disk at power-on.)*
- **Harness:** `tools/emu` from the CPC version. `harness.mjs` runs `ephl` (ep128emu's
  emulation, headless: `tools/ephl`) or MAME's `ep128` driver (`steps.lua`), with steps that
  peek and poke by segment rather than bank. Both need the Enterprise's ROMs (EXOS, and EXDOS
  for the disk), from a directory in `EP_ROMS` as `CPC_ROMS` is for the CPC. Until the disk loads, the harness can load the files straight into their segments, as
  the CPC harness's `load` step does, so phases 1-7 don't wait on EXDOS.
- **Test:** the program loads, takes the machine from EXOS (interrupts off, its own handler at
  `&0038`, its own stack), and sets `ready` — **passes** (`boot.mjs`). It also asks EXOS for every
  segment it will give out: `&F9-&FE`, on a 128 with EXDOS.

### Phase 1: machine layer and screen (`src/machine.asm`)

- **Paging:** `bank_select` pages a segment into the window (port `&B1`), keeping a
  copy as `ga_ram` does; `screen_select` pages a buffer's two segments into pages 2 and 3.
  `bank_test` checks every segment at start-up.
- **Interrupts and ticks:** 50 a second from Nick's VINT through Dave (port `&B4`: bit 4
  enables it, bit 5 resets its latch), from a 12-line border LPB with VINT straight after the
  playfield. ep128emu's Dave latches the interrupt as VINT ends (MAME's as it starts), so it
  comes 44 lines before the table starts again: time to point Nick at the other buffer's
  table. The main loop runs a game tick for each vertical sync since it last looked, as now.
  **Done.**
- **Where the raster is:** `restore_chase` needs to know where the raster is, which the CPC
  works out from the gate array's six interrupts a frame, 52 lines apart. Here, the playfield's
  LPBs are split into bands about 52 lines apart, alternately with and without VINT, so the
  handler can count them (not done yet: it's for phase 6's `restore_chase`). ep128emu's Dave
  latches the interrupt as an LPB with VINT ends, MAME's as one starts *(check on a real
  machine)*. Every LPB loads its own LD1 at its first line
  *(MAME)*, so each band's address is worked out from the scroll position. Bit 0 of the mode
  byte marks the table's last LPB, after which Nick starts the table again.
- **Keyboard:** 10 rows of 8 keys, a row selected and read through port `&B5` (a key down reads 0)
  *(MAME)*, read in
  the interrupt handler into `keys[]` as now. The `KEY_` constants become the Enterprise's
  matrix positions; the keys are the same (Z X O K, cursor keys, Space, Return, Escape, P, Y, M,
  S, and L R U D J and the digits for typed commands). Joystick: the internal one is in the keyboard matrix; the external one's J, K and L
  lines are bits 0-2 of port `&B6` *(MAME)*.
- **The screen:** the line parameter table (two of them, one for each buffer, at Nick's
  `&C000` and `&C080`), built from the view's scroll position: the playfield's two LPBs (split
  where the ring wraps), a 12-line bottom border with VINT, the vertical sync's four LPBs as
  EXOS makes them (12 lines), and a 32-line top border that ends the table: 312 lines. The
  picture is 40 slots, margins 11 and 51, as EXOS's. Writing port `&83` with bits 6 and 7 set,
  as EXOS leaves them, only changes the table's address, and Nick takes it when it next starts
  the table, so a flip is always a whole frame *(ep128emu)*. **Done** (`src/screen.asm`).
  **Never rewrite the table on show:** Nick reads a block's line count once, as it starts the
  block, but the rest of the table as it goes, so changing the table it's drawing can make a
  frame the wrong length (566 lines, seen in phase 3: a TV would roll). The game only sets the
  table of the buffer it's drawing, which isn't on show; the test harness's `t_apply` sets the
  hidden one, flips, waits for Nick to start that table, then sets the other. (MAME's screen is 280 lines, and it starts a
  frame as an LPB with VINT ends, so the playfield must come within 280 lines of that for the
  tests' screenshots to show it.)
- **Pixels:** Nick packs 4 pixels into a byte as the CPC's Mode 1 and the BBC's MODE 1 do
  (pixel 0 in bits 7 and 3, bit 3 the high bit of its colour) *(MAME)*, so the graphics bank's
  code tables are the screen's bytes as they are. `screens.mjs` confirms it.
- **Colours:** a palette byte has 3 bits of red (bits 0, 3 and 6, strongest first), 3 of green
  (1, 4, 7) and 2 of blue (2, 5) *(MAME)*: black `&00`, red `&49`, green `&92`, yellow `&DB`,
  magenta `&6D`, cyan `&B6`.
- **Tests:** `screens.mjs`: random bytes in both buffers, shown from six scroll positions (the
  ring's start, either side of its end, lines running into the mirror), flipping every frame:
  every pixel of every frame is right, and the buffers alternate — **passes** (on ephl: MAME's
  Nick moves on an LPB when port `&83` is written, so it can't flip cleanly).
  `machine.mjs`: 50 ticks a second, every segment, every key, the `KEY_` constants —
  **passes** (ephl and MAME). Still to do here: the external joystick (port `&B6`).

### Phase 2: memory map — done

Lay the segments out as above and measure everything that has to fit, with the front end packed.
Pack it with the BBC version's packer (`tools/pack.py`: LZ77 in the style of ZX0) and port its
unpacker to the Z80, since the loader may want packing too. ASSERTs in the build check every
region, as the CPC version's do. If segment `&FF` doesn't fit, take the fallbacks in order.
**Done:** `tools/memmap.py` (run by `build.sh` when the CPC version changes) measures it,
`src/layout.asm` ASSERTs it, and `unpack.mjs` checks the Z80 unpacker (`src/unpack.asm`)
unpacks the front end and the loader byte for byte, from `&FF` into `&FB` (the front end in
about 0.2 seconds).

### Phase 3: plotter and drawing (`src/plot.asm`) — done

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

**Done**, as planned, with these details settled:
- A level's byte column `c` of line `y` is at `((y MOD 256) * 80 + c) MOD 20480` in the ring.
  With `c = 80q + r`, that's byte `r` of ring row `(y + q) MOD 256`, so each column's first line
  says how many lines it has before the ring's end (`256 - row`). The column routines do those
  (what's over 8 in a loop, then 8 at a time unrolled), then, if there are more, subtract
  `&5000` once and carry on: no test on any line.
- A line down is `80` on (`ld a,c : add a,80 : ld c,a : adc a,b : sub c : ld b,a`, 27 T-states
  against the CPC's 15 for `&800`), and there's no character row to cross.
- A save record keeps each column's ring row and byte (2 bytes, as the CPC's address did), so
  putting it back works out the wrap again; the save areas' sizes are the CPC version's.
- The compiled meanie steps `LD DE,80 - n : ADD HL,DE` between lines, with no `jit_row`;
  `plot_slow` uses it wherever none of the meanie is past the ring's end.
- `restore_chase` waits for phase 6.

`plot.mjs` passes (on ephl and MAME): 408 images at every shift, 400 clipped at random, 210
across the ring's end (rows 255 to 0, and columns across 80, 160 and 240), 120 saved and put
back, 150 yoyo strings and their restores, 240 compiled meanies (the compiled code used in each
of the 77 places it can be), 40 frames of the draw log, and nothing written over the code. A
plotter stepping 81 bytes a line fails 652 of them.

### Phase 4: levels and background (`src/level.asm`, `src/bg.asm`) — done

The level loader and unroller as they are (the cache's format doesn't depend on the screen's
layout). `repaint_column` steps 80 bytes a line and `repaint_row` paints 8 lines of 80 bytes,
both wrapping at the end of the ring. Both level kinds now use the one window, 320x256.
**Test:** `levels.mjs`: all 55 levels' tables, background caches and repainted windows match
the converter.

**Done**, as planned:
- `level.asm` and `loader.asm` are the CPC version's, with the paging renamed and the window
  the BBC version's for both kinds of level (80 byte columns and 32 character rows: `row_max`
  and `scroll_max` follow). The loader (3,965 bytes) is assembled to run at `&E1A0`, in segment
  `&FE` at page 3, where it's kept (`build/LOADER.BIN`), so it isn't copied; `load_level` pages
  `&FE` in there and `&FC` at page 2, where the unroller's workings are, as on the CPC. The
  compiled meanie goes after it, at `&7180` in the window (`build/frak.asm` ASSERTs they don't
  meet). The levels are the CPC version's, as they are (`build/LEVELS.BIN`, for `&FF` at `&4000`).
- `bg.asm`'s unroller is the CPC version's; its painter is new. Down a sideways level's byte
  column, each of 32 cells is 8 lines of 80 bytes on, wrapping at the ring's end (which only the
  last cell of a column past 80 can reach); along an up-and-down level's character row, each of
  80 cells is a byte on, its 8 lines 80 apart, never wrapping (the ring is 256 lines, a row 8).
- Every sideways level is at least 580 pixels wide and every up-and-down one exactly 320, so the
  window is always within the level.

`levels.mjs` passes on all 55 levels (ephl, MAME, and other power-up seeds). A painter stepping
81 bytes a line fails all 55; one putting each row a line low fails the 19 that scroll up and
down.

### Phase 5: game logic (`src/logic.asm`, `src/trogg.asm`, `src/commands.asm`) — done

Unchanged, except for the window's size: the CPC's two window shapes become the BBC version's
one, so the view's bands and clipping come from the BBC version.
**Tests:** `connections.mjs` (Trogg moves as in GameMaker on all 55 levels) and `logic.mjs` (the
logic does what the BBC version's does, tick for tick).

**Done.** `src/logic.asm` is the CPC version's, in segment `&FA` at `&4000` (`build/LOGIC.BIN`),
with its window variables the BBC version's (80 columns, 256 lines, 32 rows) and `play.asm`
left out until phase 6 (the logic only mentions it in comments; the few constants of it the
logic's variables use are in `logic.asm` until then). `trogg.asm` and `commands.asm` are the
CPC version's files, included as they are. The CPC's joystick keys are the Enterprise's built-in
joystick (the cursor keys, Space to fire). `src/sound.asm` is the sound stubs: the interrupt
takes each request as the player would, and M and S change the options, as the logic's
footsteps depend on them.

- `connections.mjs`: 54 levels exactly as GameMaker; D_9 differs only by its ladder at x = 48.5,
  which the converter rounds down, as the BBC and CPC versions' notes say (about 10,000 starts
  in each level, 8.3 billion Z80 instructions). It needs `tools/connections.js` from the
  steamfrak repository: it's on that repository's `ccr-c7940764-hxv6sv` branch, not on `main`.
- `logic.mjs`: all 55 levels, mortal and immortal, 4,000 ticks each, the same as the BBC
  version's (on jsbeeb) after every tick, with deaths, wins, keys, gems, meanies knocked off,
  platforms carried, checkpoints, balloons and daggers among them; and again with other keys
  on six of them.

### Phase 6: main loop and scrolling (`src/play.asm`) — done

The CPC's frame loop. Scrolling sets the playfield's LPBs (and the mirror line) rather than
CRTC R12/R13, and the flip happens at the vertical interrupt, at most every two vertical syncs.
Scrolling is one mode, the BBC version's, with the CPC's 8-pixel steps sideways.
**Tests:** `frames.mjs`: every frame drawn is what the game's state says it should be, with
`render.mjs`'s window made 320x256 for both kinds of level. `fps.mjs`: the frame rates, to
compare with the CPC version's and the BBC version's (not a pass or fail yet).

**Done.** `src/play.asm` is the CPC version's, in the logic segment, with:
- the BBC version's window and bands for both kinds of level: 320x256, the view still between
  120 and 200 pixels across and 96 and 176 lines down, centred on (x - 160, y - 128); sideways
  the view moves 8 pixels (a Nick slot) a step, as the CPC version's;
- `flag_flip` setting the back buffer's table from its scroll position (it isn't on show), and
  the interrupt pointing Nick at it, no sooner than 2 vertical syncs since the last
  (`flip_min`, 0 for the phase 1 test);
- a blank table on show while a level loads and both buffers are drawn afresh (as the CPC
  version blacks its palette), with the same VINTs, so no table on show is ever rewritten;
- the level's palette in each table's LPBs: the background, magenta, yellow, black (Nick, as
  the CPC, takes a pixel's bits the other way round from the BBC);
- `restore_chase` (in `plot.asm`) knowing how far down the raster is from the interrupts at
  the playfield's lines 64, 128 and 192 (1-line VINT blocks in every table; `sync_bands`
  starts the count in step), as the CPC version's knows from the gate array's six;
- the timer's digits copied from EXOS's own font, which EXOS leaves in video RAM (Nick's
  `&F480`, 9 rows a character, row by row), when the program starts; kept in the low RAM;
- the front end's calls stubbed until phase 7 (and so the level-complete screen without its
  text).

`frames.mjs` passes on its 11 levels, both kinds, mortal and immortal, 300 frames each: 6,600
frames right, with the view scrolled, the yoyo out, moving platforms and meanies, balloons,
daggers and meanies flying off, things collected, deaths and level-complete screens among them.

`fps.mjs`, on ephl (with the video RAM's wait states: the real machine's timing), Trogg unable
to die, standing for 10 seconds then walking right for 10:

<details><summary>Frame rates on every level</summary>

| Level | Scrolls | Frames a second, standing | Walking right |
| --- | --- | --- | --- |
| 0 | sideways | 16.1 | 14.5 |
| A_1 | sideways | 14.6 | 14.8 |
| A_2 | sideways | 14.5 | 13.8 |
| A_3 | sideways | 14.7 | 15.3 |
| A_4 | sideways | 14.5 | 13.7 |
| A_5 | sideways | 14.2 | 13.1 |
| A_6 | sideways | 14.5 | 16.0 |
| A_7 | sideways | 13.7 | 15.0 |
| A_8 | sideways | 15.5 | 16.0 |
| A_9 | sideways | 14.2 | 10.4 |
| B_1 | sideways | 6.2 | 5.3 |
| B_2 | sideways | 6.4 | 6.3 |
| B_3 | sideways | 5.9 | 5.6 |
| B_4 | sideways | 8.9 | 6.5 |
| B_5 | sideways | 7.4 | 5.9 |
| B_6 | sideways | 6.6 | 6.4 |
| B_7 | sideways | 8.6 | 7.3 |
| B_8 | sideways | 4.9 | 4.5 |
| B_9 | sideways | 5.4 | 5.2 |
| C_1 | up and down | 5.3 | 6.0 |
| C_2 | up and down | 6.6 | 4.6 |
| C_3 | up and down | 5.9 | 5.1 |
| C_4 | up and down | 5.9 | 10.6 |
| C_5 | up and down | 5.2 | 4.7 |
| C_6 | up and down | 5.3 | 4.6 |
| C_7 | up and down | 7.8 | 7.1 |
| C_8 | up and down | 8.1 | 7.7 |
| C_9 | up and down | 7.4 | 5.6 |
| D_1 | sideways | 10.1 | 10.1 |
| D_2 | up and down | 6.1 | 4.8 |
| D_3 | sideways | 5.3 | 5.3 |
| D_4 | sideways | 8.2 | 8.5 |
| D_5 | up and down | 5.0 | 5.2 |
| D_6 | sideways | 8.8 | 8.8 |
| D_7 | up and down | 7.5 | 5.9 |
| D_8 | up and down | 5.7 | 5.3 |
| D_9 | up and down | 5.0 | 5.1 |
| E_1 | sideways | 12.8 | 9.9 |
| E_2 | sideways | 10.4 | 10.5 |
| E_3 | sideways | 7.6 | 7.8 |
| E_4 | sideways | 12.7 | 13.7 |
| E_5 | up and down | 9.6 | 6.5 |
| E_6 | up and down | 8.2 | 7.8 |
| E_7 | up and down | 13.3 | 12.7 |
| E_8 | sideways | 8.5 | 8.0 |
| E_9 | sideways | 9.4 | 9.7 |
| F_1 | sideways | 8.7 | 8.5 |
| F_2 | sideways | 11.3 | 10.2 |
| F_3 | sideways | 9.5 | 9.9 |
| F_4 | sideways | 8.1 | 9.8 |
| F_5 | up and down | 9.3 | 7.3 |
| F_6 | up and down | 8.5 | 8.1 |
| F_7 | sideways | 10.4 | 9.9 |
| F_8 | sideways | 14.1 | 10.3 |
| F_9 | sideways | 10.9 | 11.3 |
| average | | 9.3 | 8.8 |
| average | sideways | 10.4 | 9.9 |
| average | up and down | 7.1 | 6.6 |

</details>

That's 90% of the CPC version's 10.3 on average (and 65% of the BBC version's 14.4), with a
bigger window (the CPC's is 256x256 or 320x200) and every screen byte waiting for Nick. Below
12.5 frames a second the game slows (at most 4 ticks a frame, as the BBC version), so on most
levels it does for now: the optimisation pass after the first milestone starts from here.

### Phase 7: front end (`src/front.asm`) — done

The CPC's front end, packed, unpacked into segment `&FB` when the menus come up (the level's
background is rebuilt when a level starts anyway), with its records kept in low RAM. It's drawn
in the 320x256 screen with the BBC version's layout (256 pixels wide, 32 pixels in). The font:
the Enterprise's own, copied from the EXOS ROM at start-up, as the CPC version copies its own
from its lower ROM *(check: where it is)*.
**Test:** `front.mjs`: from the attract screen through the menus into a level, won, then the next
level, and back to the menus with its record.

**Done**, as planned, with these details:
- `src/front.asm` is the CPC version's, assembled at `&4000` (`build/FRONT.BIN`, 3,524 bytes:
  its variables moved out), packed by `build.sh` between two passes of the assembler (2,591
  bytes) into segment `&FF`'s file (`build/TOP.BIN`, the levels and it), and unpacked by
  `front_call` into `&FB` when it's called, unless it's still there since it last was (the
  loader clears `fe_unpacked`, as it builds the background cache there).
- Its variables, the records (440 bytes) and the font (EXOS's, characters 32-127, 768 bytes,
  copied from video RAM at the start, as the timer's digits were) are in the low RAM, so they
  last. That leaves the low RAM 148 bytes before the stack (`&3E6C`).
- It draws the BBC version's 256-pixel-wide layout in byte columns 0-63 of buffer 0's ring,
  shown from 8 bytes before the ring's start (`FE_SCROLL`), so it's 32 pixels in, as on the
  BBC's 320-pixel screen; while it sets a screen up, the blank table is on show.
- The game starts by itself a second after the program does, unless the test harness says it's
  there (`t_harness`), as the CPC version's.

`front.mjs` (the CPC version's) passes, on several power-up seeds; and `frames.mjs` checks the
level-complete screen's text again, in EXOS's font. Two waits in `front.mjs` are longer than the
CPC version's, as the Enterprise is slower: Escape is held for half a second (playing, the keys
are read once a drawn frame), and the next level is given longer to load and be drawn before
it's pressed (drawing both buffers afresh is slow: `paint_line` calls a routine for each line,
one for the optimisation pass).

### Phase 8: release — done, but for a real machine

The disk image boots by itself on an Enterprise 128 with EXDOS; the program loads its segments
through EXOS before it takes the machine over. It can't load the levels straight into `&FF`
while EXOS is using that segment, so it loads them into a screen buffer first and copies them
across afterwards.
**Tests:** `front.mjs` and `frames.mjs` with `EP_COLD=1` (memory filled with garbage first), and
playing on a real Enterprise 128.

**Done**, but for the real machine, with these details settled:
- **Starting it.** EXDOS (1.3 and 1.4) takes `START` as the file name when none is given, so the
  program is `START` on the disk, and `LOAD` (with no name) at BASIC's prompt loads and runs it.
  Nothing found runs it at power-on by itself: EXOS's logo waits for a key, which starts BASIC
  (or, with no BASIC cartridge, the word processor). The disk (`build/frak.img`) holds `START`,
  `GFX.BIN`, `LOGIC.BIN`, `LOADER.BIN` and `TOP.BIN`.
- **EXOS starts a type 5 program** at `&0100` with its own stack (`&B217`, in page 2), so the
  program first sets its own, at the top of page 0.
- **Loading.** While EXOS still runs, the program reads the pages EXOS ran it with, loads its
  four files (opening each on a channel and reading it as one block) into their segments, and
  only then takes every segment EXOS will give out: EXOS needs a little RAM to open a channel
  (status `&F7` otherwise). Segment `&FF` is EXOS's own until the takeover, so `TOP.BIN` goes into
  `&FC` first; once the machine is the program's, `copy_font` takes EXOS's font from `&FF`, and
  then `copy_top` copies `TOP.BIN` there. A file that can't be loaded turns the border red.
- The loading code runs once, so it's in the first save area (also `STAGE`), which nothing uses
  until a level loads: the low RAM has no room otherwise.
- The test harness, which puts the files in their segments itself, says so (`t_noload`).

`disk.mjs` passes on ep128emu's own Enterprise 128 with EXDOS (EXOS 2.1, BASIC 2.1, EXDOS 1.4),
with nothing put in memory for it: `LOAD`, the four files in their segments byte for byte, the
game starting by itself at the attract screen, and the menus choosing Read&Weep, which plays;
with `EP_COLD=1` (the program's segments full of garbage first) too, on several power-up seeds.
About 14 seconds from power-on in the emulator, most of it the disk. On MAME it isn't run (its
ROM set has no BASIC cartridge).

## After the first milestone: speed

`tools/emu/profile.mjs` plays levels on ephl (Trogg unable to die, standing then walking, as
`fps.mjs`) and samples where the Z80 is every 32 microseconds, with the video RAM's wait states,
putting each sample down to its routine. On the first profile, the slowest levels (B_8, C_5,
D_9: 5 frames a second) spent about 27% of their time in `paint_line` and the `pl_step` it
called for every line (repainting the background: erasing the moving platforms and meanies,
and the columns or rows scrolled into view), and the faster ones 4-6% in `lpt_set`, whose
loop to find where the ring wraps could go round 256 times a flip. So far:

- `paint_line` paints a cell's 8 lines unrolled, 80 bytes apart (`ADD HL,BC`: 29 T-states a
  line, against about 65), unless the cell is within 3 pages of the ring's end, where it still
  goes a line at a time, wrapping.
- `lpt_set` finds where the ring wraps by division: the lines that start before the ring's end
  are 256 less the ring row of the scroll position, and that row is the position / 80 (8 steps
  of shift and subtract).
- (To make room in the low RAM for the first, EXOS's font moved out of it, to segment `&FE`
  after the compiled meanie's room: `front_call` copies it beside the front end as it unpacks
  it. Only the timer's digits stay in the low RAM.)

Frame rates now (`fps.mjs`), 3% to 17% up on each level (8% the median):

<details><summary>Frame rates on every level, after the first speed-ups</summary>

| Level | Scrolls | Frames a second, standing | Walking right |
| --- | --- | --- | --- |
| 0 | sideways | 16.9 | 15.5 |
| A_1 | sideways | 15.5 | 15.9 |
| A_2 | sideways | 15.3 | 15.2 |
| A_3 | sideways | 15.6 | 16.3 |
| A_4 | sideways | 15.4 | 15.0 |
| A_5 | sideways | 14.9 | 14.6 |
| A_6 | sideways | 15.3 | 16.7 |
| A_7 | sideways | 14.5 | 16.0 |
| A_8 | sideways | 16.2 | 16.4 |
| A_9 | sideways | 15.0 | 12.0 |
| B_1 | sideways | 7.1 | 6.2 |
| B_2 | sideways | 7.2 | 7.1 |
| B_3 | sideways | 6.5 | 6.4 |
| B_4 | sideways | 9.4 | 7.4 |
| B_5 | sideways | 8.0 | 6.7 |
| B_6 | sideways | 7.2 | 7.2 |
| B_7 | sideways | 9.4 | 8.2 |
| B_8 | sideways | 5.6 | 5.2 |
| B_9 | sideways | 6.1 | 5.9 |
| C_1 | up and down | 6.1 | 7.3 |
| C_2 | up and down | 7.2 | 5.1 |
| C_3 | up and down | 6.6 | 6.0 |
| C_4 | up and down | 6.9 | 11.5 |
| C_5 | up and down | 5.8 | 5.5 |
| C_6 | up and down | 5.9 | 4.9 |
| C_7 | up and down | 8.9 | 8.2 |
| C_8 | up and down | 8.8 | 8.6 |
| C_9 | up and down | 8.1 | 6.4 |
| D_1 | sideways | 10.8 | 11.1 |
| D_2 | up and down | 6.8 | 5.8 |
| D_3 | sideways | 5.9 | 5.9 |
| D_4 | sideways | 9.1 | 9.5 |
| D_5 | up and down | 5.8 | 5.7 |
| D_6 | sideways | 9.5 | 9.3 |
| D_7 | up and down | 8.3 | 6.3 |
| D_8 | up and down | 6.5 | 6.4 |
| D_9 | up and down | 5.5 | 5.6 |
| E_1 | sideways | 13.4 | 11.1 |
| E_2 | sideways | 11.1 | 11.1 |
| E_3 | sideways | 8.3 | 8.7 |
| E_4 | sideways | 13.4 | 14.3 |
| E_5 | up and down | 10.2 | 8.1 |
| E_6 | up and down | 8.8 | 8.2 |
| E_7 | up and down | 13.7 | 13.4 |
| E_8 | sideways | 9.4 | 8.7 |
| E_9 | sideways | 10.1 | 10.0 |
| F_1 | sideways | 9.4 | 10.3 |
| F_2 | sideways | 12.1 | 11.8 |
| F_3 | sideways | 10.1 | 10.3 |
| F_4 | sideways | 9.1 | 11.0 |
| F_5 | up and down | 10.2 | 8.8 |
| F_6 | up and down | 9.1 | 8.3 |
| F_7 | sideways | 10.9 | 10.5 |
| F_8 | sideways | 14.9 | 11.8 |
| F_9 | sideways | 11.5 | 11.7 |
| average | | 10.0 | 9.7 |
| average | sideways | 11.1 | 10.9 |
| average | up and down | 7.9 | 7.4 |

</details>

That's 10.0 frames a second on average (9.3 before; the CPC version 10.3, the BBC version 14.4),
7.9 on the levels that scroll up and down (the CPC version 8.2, on its smaller 320x200 window).
The slowest levels are slow on every version (B_8: the BBC version 7.8, the CPC 6.6, the
Enterprise 5.6): they're full of moving platforms and meanies, each erased every frame by
repainting its character cells from the background cache. Much more would need that changed:
saving the background under each as it's drawn, and putting it back, as the draw log does for
the things that move every frame.

### Keeping the game's speed

Those frame rates flattered it: as in the BBC and CPC versions, each frame ran a tick of logic
for every vertical sync since the last, but at most 4 (`MAX_TICKS_PER_FRAME`), so below 12.5
frames a second the game slowed down. Measured (`fps.mjs`'s last column: the ticks run walking,
against 50 a second), it ran at 72% of its speed on average, 58% on the levels that scroll up and
down, and 39% on the slowest (C_6). The Atari version keeps its speed whatever the drawing takes
(its VBI counts fields; each frame made runs a tick for each since the last), and now so does
this one:

- `MAX_TICKS_PER_FRAME` is 12: the game slows only below 4.2 frames a second, which no level
  comes to (C_2, walking, is the slowest, at 3.4, for a moment). `redraw` starts the count again
  after a full redraw, so its pause doesn't make the game jump ahead.
- Sideways, the view scrolled a step (8 pixels) a frame, however many ticks the frame took (the
  CPC version's `frame_ticks / 4`, at least 1), so it fell behind Trogg when the frames were
  slow. Now it takes a step for every 4 ticks, the ticks over carried to the next frame
  (`bs_acc`), and still a step a frame when there are fewer: at 25 frames a second it's as
  before. Walking right on B_8 and B_5, Trogg stays between 72 and 207 pixels across the window.
- Up and down, the view scrolls a row a tick, at most 6 a frame (`MAX_ROWS_PER_FRAME`; 4 before):
  Trogg falls at most 4 lines a tick, 48 in 12.
- For the test harness, `t_lock` is the ticks each held frame runs (1 for 2, as before), and
  `frames.mjs --ticks=N` checks every frame at N ticks a frame: right at 5, 7 and 12.

The game now runs at 98% of its speed on average (100% on the levels that scroll sideways, 94% up
and down; the lowest, C_2, 79%, where a frame took more than 12 ticks). The frame rates are lower,
9.0 a second on average (6.3 up and down): the logic now runs 50 times a second, not 25 to 40,
and on the slow levels it's costly (on C_6, `check_collisions` 10% of the time, `move_hooter`
8%, the multiplies and `update_slow` another 10%). Making a tick cheaper is the next speed-up.

<details><summary>Frame rates and the game's speed on every level, keeping its speed</summary>

| Level | Scrolls | Frames a second, standing | Walking right | Game speed walking (%) |
| --- | --- | --- | --- | --- |
| 0 | sideways | 16.9 | 15.5 | 100 |
| A_1 | sideways | 15.5 | 15.8 | 100 |
| A_2 | sideways | 15.3 | 15.1 | 100 |
| A_3 | sideways | 15.6 | 16.3 | 100 |
| A_4 | sideways | 15.4 | 14.9 | 100 |
| A_5 | sideways | 15.0 | 14.6 | 100 |
| A_6 | sideways | 15.3 | 16.7 | 100 |
| A_7 | sideways | 14.5 | 16.0 | 100 |
| A_8 | sideways | 16.3 | 16.3 | 100 |
| A_9 | sideways | 15.0 | 11.2 | 100 |
| B_1 | sideways | 4.7 | 4.6 | 96 |
| B_2 | sideways | 5.9 | 6.1 | 100 |
| B_3 | sideways | 5.0 | 5.4 | 100 |
| B_4 | sideways | 8.1 | 6.2 | 100 |
| B_5 | sideways | 6.7 | 4.7 | 97 |
| B_6 | sideways | 5.7 | 5.7 | 100 |
| B_7 | sideways | 8.3 | 6.9 | 100 |
| B_8 | sideways | 4.2 | 4.1 | 97 |
| B_9 | sideways | 4.7 | 4.8 | 98 |
| C_1 | up and down | 4.0 | 7.6 | 98 |
| C_2 | up and down | 5.1 | 3.4 | 79 |
| C_3 | up and down | 4.8 | 5.3 | 97 |
| C_4 | up and down | 5.5 | 11.4 | 101 |
| C_5 | up and down | 4.1 | 4.2 | 92 |
| C_6 | up and down | 4.0 | 3.9 | 85 |
| C_7 | up and down | 7.5 | 8.4 | 96 |
| C_8 | up and down | 7.7 | 6.5 | 99 |
| C_9 | up and down | 7.6 | 5.2 | 93 |
| D_1 | sideways | 10.4 | 10.6 | 100 |
| D_2 | up and down | 5.1 | 3.8 | 83 |
| D_3 | sideways | 4.2 | 4.2 | 98 |
| D_4 | sideways | 8.2 | 8.9 | 100 |
| D_5 | up and down | 4.0 | 4.0 | 97 |
| D_6 | sideways | 8.5 | 8.5 | 101 |
| D_7 | up and down | 6.3 | 4.9 | 88 |
| D_8 | up and down | 4.3 | 5.8 | 91 |
| D_9 | up and down | 3.8 | 3.8 | 91 |
| E_1 | sideways | 13.4 | 10.6 | 99 |
| E_2 | sideways | 10.6 | 10.6 | 100 |
| E_3 | sideways | 7.2 | 7.6 | 100 |
| E_4 | sideways | 13.4 | 14.3 | 100 |
| E_5 | up and down | 8.9 | 7.6 | 94 |
| E_6 | up and down | 7.3 | 6.7 | 100 |
| E_7 | up and down | 13.7 | 13.4 | 100 |
| E_8 | sideways | 8.6 | 7.7 | 100 |
| E_9 | sideways | 9.6 | 9.6 | 100 |
| F_1 | sideways | 8.6 | 10.6 | 101 |
| F_2 | sideways | 12.1 | 11.4 | 100 |
| F_3 | sideways | 9.3 | 9.7 | 100 |
| F_4 | sideways | 8.1 | 11.0 | 101 |
| F_5 | up and down | 9.6 | 8.7 | 98 |
| F_6 | up and down | 7.3 | 6.8 | 100 |
| F_7 | sideways | 10.1 | 10.3 | 101 |
| F_8 | sideways | 14.9 | 11.2 | 100 |
| F_9 | sideways | 11.2 | 11.5 | 100 |
| average | | 9.0 | 8.9 | 98 |
| average | sideways | 10.5 | 10.3 | 100 |
| average | up and down | 6.3 | 6.4 | 94 |

</details>

## Sound

`src/sound.asm` is replaced by stubs with the same interface: `snd_tick` (called from the
interrupt) and `snd_keys` do nothing, and the requests the logic makes (`snd_music_req`,
`snd_sfx_req`, `snd_sfx_req2`, `snd_cur`, `snd_music_opt`) are plain variables in low RAM, so
the logic bank is unchanged. Later, the player is ported to Dave. It has three tone channels
and a separate noise channel, like the BBC Master's sound chip, so the BBC version's voices may
map onto it more directly than onto the CPC's AY. It also needs about 6K, which has to come
from re-optimising the memory map.

## Risks

- ~~**Segment `&FF` is nearly full.**~~ It isn't: 1.2K to spare (phase 2).
- ~~**EXDOS and EXOS may keep RAM** that the loader needs.~~ They don't: EXOS gives out `&F9-&FE`
  on a 128 with EXDOS (phase 0), keeping only page 0's segment and its own `&FF`.
- **The ROMs:** MAME's `ep128` driver needs the Enterprise's ROMs, which this repository can't
  include.
- **Waiting for Nick:** the plotter writes only to video RAM, and the CPC's measurements of
  where the time goes won't carry over. `fps.mjs` and a port of `profile.mjs` measure it, for
  the optimisation pass after the first milestone.
