# Plan: Frak! for the MSX2+

Status: **planning.** Nothing built yet. Facts marked *(measure)* are believed true but must be
confirmed in milestone 0 before anything is built on them.

Target: an unmodified **64K MSX2+** (Z80A at 3.58 MHz, V9958 with 128K VRAM, AY-3-8910 PSG),
**60Hz**, loading from a **720K floppy** (`build/frak.dsk`), so that it later runs on a real
Japanese MSX2+ (Panasonic FS-A1WX/WSX/FX, Sanyo PHC-70FD, Sony HB-F1XDJ/XV). The 5.37 MHz turbo
of some Panasonic and Sanyo models is not relied on.

The exit milestone matches the CPC port's: the whole game (attract screen, menus, all 55 levels,
music and sound effects) on a real MSX2+, from floppy.

## The idea

The CPC port is the starting point: it is Z80, follows the BBC version routine by routine, and
its game logic, sound player, tests and harness carry over. What does not carry over is its
drawing, because the MSX2+'s screen is not in the Z80's memory: the V9958 has its own 128K, read
and written through I/O ports (`#98` data, `#99` address/registers). Instead the V9958 gives:

- **Hardware sprites** (sprite mode 2): 32 sprites of 16x16, at most 8 on a line, one colour
  per sprite line. With the CC bit, overlapping sprites OR their colour numbers together. The
  BBC version's logical colours are 1 yellow, 2 magenta, 3 black, so **any Frak image is exactly
  two sprite layers**: one of colour 1 holding the pixels with bit 0 set (yellow and black), one
  of colour 2 holding those with bit 1 (magenta and black). Black, the outline, comes out where
  they overlap.
- **A blitter** (VDP commands): `HMMM` copies bytes VRAM to VRAM, `LMMM` with `TIMP` copies
  pixels skipping colour 0 (masked drawing), `HMMV` fills, `LINE` draws lines. The Z80 runs
  game logic while the VDP works.
- **Hardware scrolling on both axes**: R#23 vertical (wrapping within a 256-line page) and,
  new in the V9958, R#26/R#27 horizontal to the pixel, with R#25's MSK hiding the leftmost 8
  pixels so that a column can be drawn there out of sight.
- **SCREEN 5**: 256x212, 16 colours from a palette of 512, 4 bits a pixel, 128 bytes a line, a
  page (256x256) per 32K, so four pages in 128K. R#2 chooses the page on show.

So the plan splits the drawing three ways:

| What | How | Why |
| --- | --- | --- |
| Trogg (26x34), the yoyo (7x6), balloons and daggers (12x10) | Hardware sprites, two layers each | Small, numerous, move every tick; on the BBC, erasing and drawing Trogg alone is 21-24K cycles a frame |
| Moving meanies (Scrubbly 33x42, Poglet 23x33, Hooter 19x23), moving and movable platforms (up to 140x15), springs, meanies flying off, the yoyo string, the FRAK! bubble, the HUD | Blitter: `HMMM` from a clean background page to erase, `LMMM`+`TIMP` from a graphics page to draw | Too big for sprites: a Scrubbly would be 3x3x2 = 18 sprites and 6 on a line; a Log4 9 columns |
| Scenery (platforms, ladders), keys, gems, static meanies | Drawn into the clean background page as it scrolls in, copied to the screen buffers | As in the BBC version |

### Sprite budget

| Object | Sprites | On one line |
| --- | --- | --- |
| Trogg | 2 columns x 3 rows x 2 layers = 12 (the third row only 2 lines) | 4 |
| Yoyo | 2 (1 where a line is one colour) | 2 |
| Each balloon or dagger | 2 | 2 |

Trogg and the yoyo take 14, which leaves 18 for **9 balloons and daggers**: Insane's 8-9 on
screen. On lines away from Trogg, 4 hazards can share a line. On his lines, only one hazard can
share (4 + 2 + 2). A hazard that would make a 9th sprite on any line falls back to the blitter,
as the Atari port falls back to software when its players are taken, so nothing flickers or
vanishes. The converter can also note lines of an image that are a single colour, which need
only one layer.

The pattern table holds 64 16x16 patterns at once (2K). Trogg's frames need 180, so his current
frame's 12 patterns are copied into the table when his pose changes. The pattern table is part of
page 3's pixel space, so an `HMMM` from where his frames are kept does it. Hazards' patterns stay
put.

Sprites are positioned on the screen, not in the level. Horizontal scroll (R#26/27) doesn't move
them, so their x is level x minus the scroll. Whether R#23 moves them with the picture is
*(measure)*. The EC bit lets a sprite go off the left edge.

## The display

### One scheme for both kinds of level

The Steam playfield is 256 high, but SCREEN 5 shows 212 lines. The CPC's up-and-down levels are
320 wide, but SCREEN 5 is 256. So **every level scrolls on both axes** in a 248x212 view (256
minus the 8 masked pixels), within a page that wraps at 256x256:

- **Sideways levels** are exactly 256 high, so the whole height is in the page: vertical
  scrolling is just R#23, free, with nothing to repaint. Horizontally, a newly exposed 8-pixel
  column is drawn in the masked strip, as the BBC version repaints a column.
- **Up-and-down levels** repaint rows in the 44 lines not on show, as the BBC version repaints
  rows. Horizontally they scroll across their 320 pixels as sideways levels do.
- The BBC version's band scrolling (`band_scroll`, `band_scroll_v`) works on both axes, with
  the bands reworked for a 248x212 view. Following Trogg exactly costs nothing with pixel
  scrolling, but band scrolling keeps the repainting down.

Level coordinates map to a page as on the BBC: level pixel (x, y) is always at page pixel
(x mod 256, y mod 256), however far the view has scrolled. So scrolling repaints only what's
new, and everything is drawn in level coordinates.

### Double buffering

Pages 0 and 1 are the screen buffers. Page 2 is the **clean background**: scenery, keys, gems and
static meanies, in the same wrapped coordinates, with no moving things on it. Each frame:

1. Erase last time's blitted objects in the hidden buffer by `HMMM` from page 2 (the draw log
   becomes a list of rectangles, no saved bytes: page 2 is the save area).
2. Repaint newly scrolled-in columns and rows: draw them into page 2 (from the level's cells,
   below), then `HMMM` them into the hidden buffer.
3. Draw the blitted objects, in the BBC version's order, with its damage list for moving meanies
   and platforms.
4. Write the sprite attribute and colour tables (the next frame's hardware sprites).
5. At the next vertical blank, set R#2 (page), R#23, R#26 and R#27 together, and switch the
   sprite attribute table (two copies, chosen by R#5/R#11) so the sprites change with the page.

Collected keys and gems, and meanies knocked off, are repainted into page 2 and then copied to
both buffers, as the BBC version queues them for each buffer.

### VRAM map (128K)

| Page | Contents |
| --- | --- |
| 0 (`#00000`) | screen buffer 0 |
| 1 (`#08000`) | screen buffer 1 |
| 2 (`#10000`) | clean background (wrapped 256x256) |
| 3 (`#18000`) | graphics sheet (every blitted image at 4 bits a pixel, about 14K before deduplicating the girders, ledges, ladders and chains, which repeat one piece), the level's background cells, Trogg's sprite frames (about 6K), the sprite pattern table (2K), two sprite colour+attribute tables (2 x 640 bytes), the font |

Blitted images need only one copy, not one per shift (the blitter places them to the pixel), so
the BBC version's 5-pixel codes and code tables aren't needed.

### Background cells

The BBC converter already builds each level's background as a cell dictionary and line tables
(its bank 7). Here the cells become 4-bit-a-pixel tiles in page 3, uploaded when the level
loads. Repainting a column or row is an `HMMM` per cell, and the dictionary stays the converter's.
*(measure: whether a cell is better at 8x8 or as the BBC's 4-pixel-wide byte columns, given the
cost of starting a VDP command.)*

## Memory

### Main RAM (64K)

The disc is read once, at start-up, through Disk BASIC's BDOS. After that, the program takes the
machine over: the BIOS and BASIC are paged out (all four pages RAM), the interrupt handler goes
at `#0038`, and nothing is loaded from disc again.

| Address | Contents (estimated from the CPC version's sizes) |
| --- | --- |
| `#0000-#00FF` | restart vectors, interrupt handler |
| `#0100-...` | machine layer, VDP routines, frame loop, game logic (the CPC's logic bank, ~16K, and its low code without the plotter) |
| | music player and tunes (~10K) |
| | front end and records |
| | levels, packed (~12K, the BBC version's `PACK` as it is) |
| up to `#FFFF` | level tables, stack |

The CPC version's 5 x 16K becomes about 64K once its graphics bank (16K), background cache (16K),
code tables, compiled meanie and draw-log save areas go to VRAM or disappear. It's tight, so the
packed levels or the front end's pictures can live in VRAM page 3 and be read back through the
ports when needed. A memory map with real sizes is the first output of milestone 2.

There's no bank paging, so the CPC's `bank_select` calls go, and with them the rule that low
code puts the logic bank back.

## Machine layer

- **Loader.** `AUTOEXEC.BAS` runs `BLOAD"LOADER.BIN",R` (BLOAD only reaches page 2/3 RAM while
  BASIC is in). The loader reads the program and data files through BDOS (`CALL #F37D`, FCB
  functions) into a buffer, sends graphics and cells to VRAM through the ports, and copies code
  into pages 0 and 1 once they're switched to RAM.
- **Slots.** A 64K MSX2+ has its RAM in one slot or subslot, but which one varies by model. The
  loader finds it from the slot of page 3 (port `#A8`, and the subslot register at `#FFFF`, read
  inverted) and confirms page 0 and 1 are RAM there before switching.
- **The disc motor.** Disk ROMs stop the motor from the timer interrupt (H.TIMI) a few seconds
  after the last access. Take the interrupts over before that and the motor runs forever on a
  real machine (emulators may not show it). So the loader waits for it to stop, or stops it,
  before taking over.
- **Interrupts and ticks.** VDP vertical-blank interrupt (R#1 IE0), IM 1. Each one is a tick:
  60 a second, the Steam version's own rate (the PAL ports ran at 5/6 of it), with the BBC
  version's catching up (`MAX_TICKS_PER_FRAME`). The handler acknowledges by reading S#0, flips
  the page if asked, reads the keyboard and runs the music. If the frame loop needs the raster
  position (the BBC's `tidy` chasing the raster), a line interrupt (R#0 IE1, R#19) gives it.
- **Keyboard.** The PPI: the row on port `#AA`'s low 4 bits, read on `#A9`. Z, X, O, K, P, Space,
  Return, Esc and the cursor keys are in the same matrix places on Japanese (JIS) keyboards as
  on international ones. Joysticks are read through PSG register 14 (port select in register 15).
- **VDP access.** Writing VRAM through `#98` needs a gap between writes: in active display about
  29 T-states, so `OUTI : JP NZ`, not `OTIR` *(measure)*. Most bulk work goes through VDP
  commands instead. Register writes are two `OUT`s to `#99` with interrupts off.

Budget: 3.58 MHz / 60 = 59,659 T-states a field, less one wait state per opcode fetch (about
50,000 effective). At 30 frames a second, a drawn frame has about 100,000 for two ticks of logic,
music and the VDP set-up, against the BBC's 80,000 cycles per 25fps frame. But the VDP now does
most of the drawing, and Trogg costs almost nothing.

## Sound

The CPC's `sound.asm` drives an AY-3-8912 through the PPI. Here it's an AY-3-8910 written
directly: register on `#A0`, data on `#A1`. The clock is 1.7897725 MHz rather than 1 MHz, so
`tools/music.py` writes new period tables. The player runs at 60Hz, which is the rate the web
version's `js/audio.js` steps at, so tempos need no conversion. Many MSX2+ machines have MSX-MUSIC
(YM2413) built in: a later option, not a requirement.

## What carries over from the CPC port

| CPC | MSX2+ |
| --- | --- |
| `logic.asm`, `level.asm` (tables), `commands.asm` | Reused, minus bank paging. Same tests |
| `play.asm` | Structure reused (ticks, scrolling bands, damage list, draw order). Drawing calls become VDP command queueing and sprite table updates |
| `sound.asm` | Reused, with port writes and new period tables |
| `front.asm` | Logic reused; its drawing rewritten for SCREEN 5 and the blitter |
| `loader.asm` (LZ unpacking, the level loader) | Unpacking reused; the meanie compiler and background unroller go |
| `machine.asm` | Rewritten (VDP interrupt, slots, PPI keyboard) |
| `plot.asm`, `bg.asm`, `trogg.asm`, `gfx.py` (5-pixel codes, code tables, compiled meanie, line tables, draw-log save areas) | Not needed: sprites and the blitter replace them |
| The BBC converter's data: image pixels, spans (collisions), cell dictionary, level tables, `build/levels.json` | Reused; a new `tools/msxgfx.py` writes the sprite layers, the graphics sheet and the palette |
| `tools/emu/cpuz80.mjs`, `logic.mjs`, `connections.mjs`, `music.mjs` | Reused: the logic and the player run on the interpreter, with I/O hooks for `#A0`/`#A1` |
| `mame.mjs`, `steps.lua` | Replaced by an openMSX harness (below), with the same steps |
| `levels.mjs`, `plot.mjs`, `frames.mjs`, `render.mjs` | Same idea, new reference: VRAM pages and sprite tables read out of openMSX, compared with a renderer written from the data formats |

## Tools

- **RASM**, as for the CPC, so shared source stays shared. A raw binary for the loader to read;
  the BLOAD header (`#FE`, start, end, exec) is 7 bytes the build script can add.
- **openMSX** (`apt install openmsx`): the reference emulator. It's accurate in VDP timing and
  scriptable through `-control stdio` (Tcl commands: `debug read/write` on memory, VRAM and VDP
  registers, `keymatrixdown`/`keymatrixup`, `screenshot`, `set throttle off`, breakpoints and
  watchpoints). `tools/emu/msx.mjs` replaces `mame.mjs` and `steps.lua`.
  - Most tests run on **C-BIOS** (`-machine C-BIOS_MSX2+`, free and shipped with openMSX), with
    the program poked into RAM and started, as the CPC tests `load` files. C-BIOS has no Disk
    BASIC, so it can't boot the floppy.
  - The **disc boot test** needs a real MSX2+'s system ROMs (main, sub, disk, kanji; for example
    from a Panasonic FS-A1WSX, ideally dumped from a machine you own) under openMSX's
    `share/systemroms`.
- **Disc image**: openMSX's own `diskmanipulator create build/frak.dsk 720k` and
  `diskmanipulator import`, run from the harness. A short Python FAT12 writer would remove
  the dependency.
- **MAME** has MSX2+ drivers too (`fsa1wsx`, `hbf1xdj`), but openMSX is the timing reference.
- **For a real machine**: a Gotek-style drive with FlashFloppy, or a 720K DD disc written from
  the image (on a PC USB floppy drive, with a raw write).

## Reference material

- Yamaha, *V9958 MSX-VIDEO Technical Data Book*, and the *V9938 Technical Data Book* it extends
  (registers, VDP commands and their timing, sprite mode 2).
- ASCII, *MSX2 Technical Handbook* (transcribed on GitHub) and the *MSX2+ Technical Handbook*:
  slots, BIOS, Disk BASIC and BDOS, the keyboard matrix.
- The MSX Assembly Page (map.grauw.nl): VRAM access timing, VDP command speeds, slot
  selection, interrupt handling, the disc motor.
- The msx.org wiki: per-model memory and slot layouts of the MSX2+ machines.
- General Instrument, *AY-3-8910 data sheet*.
- A Z80 timing table, adding 1 T-state for each M1 cycle.

## Milestones

Each one is checked before the next, as in the other ports.

| | Milestone | Test that must pass |
| --- | --- | --- |
| 0 | **Unknowns, measured** in openMSX: VDP command speeds (`HMMM`, `LMMM`+`TIMP`, `HMMV`, with sprites on and off, 4bpp, 60Hz); VRAM write timing through the ports; R#23 and sprites; R#26/27 with MSK and the left edge; a flip of R#2, R#23, R#26/27 and the sprite tables in one vertical blank; the 9th-sprite behaviour | `vdp.mjs`: a test card scrolled on both axes and double-buffered, every frame whole; a table of measured speeds in this file. Later confirmed on a real machine |
| 1 | Toolchain and harness: RASM, the disc image, `msx.mjs` on C-BIOS and on a real-ROM machine | The disc boots to a test card on the real-ROM machine; C-BIOS runs the injected program |
| 2 | Machine layer: loader, slot takeover, disc motor, interrupts and ticks, keyboard, joystick, VDP routines | `machine.mjs`: 60 ticks a second against the emulated clock, every key, the RAM map |
| 3 | Graphics: `msxgfx.py` (graphics sheet, sprite layers, palette per level) | `gfx.mjs`: every image blitted and every sprite shown, compared pixel for pixel with the converter's pixels |
| 4 | Levels, background and scrolling: cells, page 2, column and row repainting, the bands on both axes | `levels.mjs`: every level's tables as the converter's; page 2 and the view, scrolled about, against the converter's background |
| 5 | Game logic | `connections.mjs` and `logic.mjs`, as for the CPC, all 55 levels |
| 6 | Frame loop and drawing: sprites with the blitter fallback, blitted objects with the damage list, string, HUD | `frames.mjs`: every frame (VRAM page and sprite tables) as a reference renderer makes of the game's state; `fps.mjs` |
| 7 | Sound | `music.mjs`: every note as `js/audio.js` plays it, at 60Hz |
| 8 | Front end | `front.mjs`: attract screen, menus, a level won, records |
| 9 | Release | Every test with RAM and VRAM filled with garbage first; the game played on a real MSX2+ from floppy |

## Risks

- **Blitter speed.** Moving meanies and platforms, the string and the repainting all go through
  the VDP. If milestone 0 shows `LMMM` too slow for a Scrubbly level, the options are a
  `HMMM` with pre-masked rectangles where the background behind is plain, and the BBC version's
  "relevant" Scrubblies, which cut how many move.
- **Main RAM.** 64K with no extra banks. Moving the packed levels to VRAM is the fallback.
- **The 8-sprites-a-line limit** on Insane levels: handled by the blitter fallback, at a cost in
  frame rate measured by `fps.mjs`.
- **Real machines differ** (slots, disc ROMs, the motor). Test on at least two models' ROMs in
  openMSX before the real machine.
