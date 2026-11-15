# Plan: Frak! for the Atari 800XL

Status: **milestone 0 under way: 4-line rows work in atari800** (exactly 4 + 4 lines a pair of
rows, with and without horizontal scrolling and players: [`test/README.md`](test/README.md));
to be confirmed in Altirra and on a real PAL 800XL. **An 8x4 screen demo** (ahead of milestones
1-2: [`README.md`](README.md)): A_1 on 52 rows of 4 lines, two glyphs a character (46 codes),
scrolling, pixel-exact against the C64's picture in atari800, as are A_2 and A_3. Target: PAL, normal (40-column) width.
This is the first port to start from the C64 port
(`../c64`) rather than from the BBC version alone. The aim is a largely monochrome game in
ANTIC mode 2, with colour infills from players and missiles, and without the C64 port's
row-by-row interrupt and multiplexer machinery. The C64's levels, data tools, game logic and
tests are reused wherever they fit.

The exit milestone matches the C64 port's first one: A_1 playable on a PAL 800XL (64K), from a
disk image (`build/frak.atr`) or an executable (`build/frak.xex`). After that come A_2 and A_3,
then the remaining levels.

## The idea

- **ANTIC mode 2** (40 columns, hi-res, one colour plus a luminance), with every character row
  only **4 lines high**. That gives the C64 port's 8x4 grid: 40 columns by 50 rows, 200 lines.
  The C64's map (a tops screen and a bottoms screen, each 97 x 25) becomes one 50-row map, a
  tops row then a bottoms row. Its levels, geometry and collision data carry over cell for cell,
  and so does the physics that was checked against the original with `conn64.mjs`.
- **Two glyphs in every character:** the first row of each pair of rows shows glyph lines 4-7
  of its characters, the second lines 0-3 (measured: see "4-line rows"). So each of the 128
  codes holds a 4-line glyph for the "bottoms" rows and another for the "tops" rows: 256 glyphs
  a set, in character sets chosen per band of rows as on the C64. (The C64's glyphs are
  orthogonal, the same picture in both halves; that would waste half of each set, see "Glyph
  budget".)
- **Meanies (Scrubblies, Poglets, Hooters), gems and keys are drawn into the map** as outlines,
  as on the C64. They are knocked off or picked up by the C64's patches (`patchon`/`patchoff`),
  which swap a few cells' codes for what's behind.
- **Moving outlines (Trogg, the yoyo, balloons, daggers) are drawn in software into spare
  characters.** Each covered cell's glyph is copied out of the map into a pool character, the
  object is ANDed and ORed on, and the pool code is written into the map. Next frame the cell is
  put back. This is the C64's yoyo string (characters 1-4, put back from the map each frame)
  made general. It replaces the multiplexer: `mux.asm` (2,530 lines), the row tails, the masks
  and the slack checks have no counterpart here.
- **Colour infills are players and missiles behind the outlines**, with double or quadruple
  width so a few bytes cover a meanie. Trogg's infill is a multicolour pair of players, as his
  C64 infill is a multicolour sprite.

## What carries over from the C64 port, and what doesn't

| C64 | Atari |
| --- | --- |
| `levels/*.json`, `levels/A_*.txt`, `tools/level.mjs`: pieces on the 8x4 grid, band sets, patches, `geometry.json`, `picks.json` | Reused. `level.mjs` gains an Atari output: monochrome glyphs (see "Colour"), 128 per set, the map as 50 rows of 128 bytes |
| `src/play.asm` (movement, keys, ticks), `collide.asm`, `yoyo.asm`, `hazards.asm`, `loader.asm` (LZ unpacking) | Plain 6502, almost no hardware references (only the keyboard reading in `play.asm`). Shared source if the Atari port also uses 64tass. The drawing hooks (`strset`/`strapply`, the virtual sprites `vxlo`/`vptr`) are rewritten for overlays and players |
| `tools/conn64.mjs`, `collidetest.py`, `picktest.py`, `cptest.py`, `hazardtest.py`, `poptest.py`, `keytest.py` | Reused against the Atari build's labels: same logic, same py65 harnesses |
| `tools/infill.mjs` (choosing a sprite's 2x2 blocks against the BBC's pixels) | Generalised to player resolutions: 2, 4 or 8 pixels wide (normal, double, quad), 1 or 2 lines high, scored the same way |
| `tools/lz.py` / `../tools/pack.py` packing | Reused |
| 4-line FLI, the cover sprite, the timer-lateness slide | Not needed: ANTIC fetches each row's codes itself. One DLI a row (see below) |
| VSP, column fills, screen pairs, the frame buffer | Not needed: ANTIC scrolls by changing the display list's addresses (LMS) and `HSCROL`. Nothing is copied when the screen scrolls |
| `mux.asm`, `trogg.asm` (sprite blocks, row tails) | Replaced by the overlay engine and a small table of player positions |
| SID sound (milestone 14, not done) | The BBC version's player (`../src/sound.asm`) suits POKEY better: 4 channels and noise from distortion, closer to the BBC's chip than the SID is |

Lessons from the C64's PLAN that shape this plan:

- **Measure before building on it** ("Unknowns, measured early"). The 4-line row trick is the
  Atari's one real unknown, so it is milestone 0.
- **The game tick must not wait for drawing.** The C64 ran one tick per frame it drew, so each
  held frame was a lost tick and the game ran slow. The BBC version runs a tick per vertical
  sync and catches up (`MAX_TICKS_PER_FRAME`). The Atari follows the BBC: ticks from the
  vertical blank interrupt (VBI), drawing whenever a frame is ready. PAL gives 50 ticks a
  second, 5/6 of the Steam version's speed, as the C64 accepted.
- **Every check is automated**, with py65 for logic and the emulator for the screen.

## The display

### 4-line rows: milestone 0 (working in atari800)

ANTIC's mode 2 rows are 8 lines. A DLI only fires at the end of a row, so a row 4 lines high is
made by misusing vertical scrolling:

- A row with the vertical-scroll bit set, after one without, *starts* at glyph line `VSCROL`.
- A row without the bit, after one with, *ends* at glyph line `VSCROL`.
- So alternating rows (bit on, bit off) give pairs of rows, glyph lines `VSCROL..7` then
  `0..VSCROL`. With `VSCROL` 4 at the start of the first row of a pair and 3 at the end of the
  second, each pair is glyph lines 4-7 (bottoms) then 0-3 (tops): a C64 band, one row's bottoms
  and the next row's tops, under one character set.
- `VSCROL` must read 3 at the end of a pair and 4 at the start of the next. The first row's DLI
  sets 3 (any time); the second's does `sta WSYNC`, one `nop`, `sta VSCROL` with 4, and the write
  lands between ANTIC's end-of-row check and its next row's start.

Measured in atari800 5.0 (`test/rows4.asm`, `test/README.md`): exactly 4 + 4 lines, all 20 pairs
of the test, glyph lines 4-7 then 0-3, with 1-3 `nop`s without horizontal scrolling and 0-2 with
it (the wide fetch takes a little more of the next line), players fetched or not; 1 `nop` is
inside both. Held constant at 4, `VSCROL` gives pairs of 4 + 5 lines. To confirm in Altirra and
on a real machine, as the window is only 2-3 cycles wide.

Consequences:

- `CHACTL` isn't needed and nothing is stored upside down: the row's half chooses the glyph.
- The display starts with a first row of a pair, showing bottoms: it shows a blank row's (or is
  1 line, with `VSCROL` 7 at the top), then the pairs follow the C64's bands.
- The second row's DLI waits on `WSYNC`, about 90 cycles a pair, 2,250 a frame. Its register
  writes for the next band (`CHBASE`, player positions) go before the `WSYNC`, in time that would
  be waited out anyway.
- The rows' DLIs must reach the `WSYNC` before the line ends, so nothing else may hold up the
  NMI: no other code waits on `WSYNC`, and the VBI is short enough to end before the first DLI.

### Glyph budget

Measured on the C64's A_1-A_3 (`tools/budget.py`: their pictures, black pixels only, the
knocked-off and picked-up versions too): the codes the static graphics need in a set.

| | 8x8, one set | 8x8, 4 bands | 8x4, a glyph in each half, one set | 4 bands | 8x4 orthogonal, one set |
| --- | --- | --- | --- | --- | --- |
| A_1 | 62 | 33 | 46 | 26 | 78 |
| A_2 | 93 | 61 | 57 | 44 | 70 |
| A_3 | 60 | 41 | 41 | 34 | 52 |

That leaves 71-87 codes in one set for the overlay pool (below), which needs about 31 on a typical
screen and 64 at the worst (Trogg, the yoyo and 6 balloons and daggers). 8x8 in 128 codes would
leave 35-68, against about 44 and 89. Later levels are wider and will need more: `budget.py` is
run on each as the C64 gets it.

### The row DLI

One fixed-length interrupt a row, everything taken from tables made in the VBI:

```
row DLI:  VSCROL (per pair) · CHBASE[band] · HPOSP2[row], HPOSP3[row] (optional: meanie infills)
```

- `CHBASE` per band gives the C64's band sets (`bandset.bin`) unchanged.
- The two player positions let P2/P3 infill meanies at different x down the screen. A player's
  graphics are a full-height strip, so this is the whole of the Atari's multiplexing: two stores
  in an interrupt that runs anyway. A meanie's infill must not share rows with another on the
  same player; `level.mjs` checks that for every scroll position.
- The HUD (the timer, M:SS) is a few ordinary mode-2 lines above the play area, in the OS font's
  shapes.

### Scrolling

- Horizontal: each row's LMS points into the map, plus `HSCROL` for 2-pixel steps, so a scroll
  is a few bytes of display list. There is no fill, and the C64's camera dead zone is no longer
  sized by how fast a fill can go.
- The map is 50 rows of 128 bytes (6.25KB). A row's address is the row number shifted left 7
  times, no row crosses a 4K boundary, and 128 columns hold the widest Steam level (1020
  pixels).
- The C64's map starts 3 columns in, to sit under its cover sprite. The Atari keeps the same map
  (so the geometry stays identical) and starts the scroll at column 3.
- Vertical levels (later): coarse steps by moving every row's LMS by one row, fine steps by 0-3
  blank lines at the top of the display list, with `COLBK` = `COLPF2` so the blank lines look
  like background and the moving edge can't be seen. `VSCROL` is busy making rows.

### Colour

- In mode 2 the whole playfield is `COLPF2`, the 0 bits and the 1 bits alike. With playfield in
  front of players, the infills would vanish everywhere. Instead, players go **in front** of
  `PF2` (`PRIOR` `$01`, or `$08`, with `$20` for multicolour pairs). GTIA shows a hi-res 1 pixel
  with `COLPF1`'s luminance and the hue of whatever is under it, players included. With `COLPF1`
  luminance 0 the outlines stay black over the infills: the C64's black outlines over coloured
  sprites, with no priority tricks.
- `COLPF2` is the level type's background, as the C64's ECM register 0 is (cyan for the
  Scrubbly, green for the Poglet, red for the Hooter).
- Monochrome glyphs: the C64's pieces are black on one of four ECM backgrounds. Black stays
  black. The coloured areas with no black in them would become blank: the platforms' magenta
  band, the yellow lattice's ground, the chains' yellow and magenta halves. The Atari output of
  `level.mjs` maps each colour to a pattern per level type (e.g. cyan empty, yellow a sparse dot,
  magenta a dither), and the preview PNG is for judging that. In A_1-A_3 each 4-line pattern of
  black only ever has one background colour, so patterns fixed to the grid add no glyphs.
- NTSC: hi-res pixels fringe with artefact colours on composite video. PAL first.

### Overlays: moving outlines in characters

- **The pool:** a block of codes at the same place in every set (the common glyphs first, then
  the pool). Trogg covers at most 4-5 x 10 cells (24-26 pixels wide, 34 lines); the yoyo and up
  to 6 balloons and daggers (3 x 4 cells at most each) share the rest. A code serves a tops row's
  cell through its glyph lines 0-3 and a bottoms row's through lines 4-7: about 25 codes for
  Trogg at the worst, 64 for everything.
- **A frame:** for each object, for each cell it covers, the background's 4 bytes from the
  band's set, AND the mask, OR the image (shifted with 8 shift tables), into a pool character.
  Overlapping objects share a cell.
- **Double buffering by character set:** every set comes twice, the static glyphs the same in
  both and the pool's codes the same, and the frame is drawn into the pool of the copy not
  shown; the VBI flips `CHBASE` (the row DLIs' table) to it. So double buffering costs 1KB a set,
  not codes: the pool is one frame's cells. Each copy's pool is two frames old when it's drawn
  into, so everything moving is drawn every frame, and anything that changes static glyphs
  (animated meanies) writes both copies.
- **The VBI:** the last frame's cells put back (a list of address and old code, kept as they
  were written), patches applied (knocked-off meanies, picked-up gems), the new frame's codes
  written (all of these together with the flip, as the map is shared by both copies: about
  60-120 bytes written, 1,000 cycles), the set copies flipped, `HSCROL`, the LMS addresses and the player positions set, all
  together. This is the C64's border tick that applies the string, the scroll and the sprite
  buffers at once, so outlines and infills never part.
- Trogg's frames are drawn from the bitmap, so his head 2 pixels from his body costs nothing
  (on the C64 it needed a third kind of row tail).
- Cost, roughly: 32 cells x 4 bytes, with copying, masking and shifting, about 3,000-4,000
  cycles a frame for Trogg. To be measured.

### Infills: players and missiles

| | For | Width |
| --- | --- | --- |
| P0 + P1 (multicolour pair) | Trogg: yellow and magenta, as his C64 infill | normal or double, chosen by `infill.mjs` |
| P2 + P3 (multicolour pair) | Meanies: the Scrubbly's magenta body, the Poglet's and Hooter's yellow and magenta, moved down the screen by the row DLI | double or quad |
| Missiles (fifth player, `PRIOR` `$10`, `COLPF3`) | The balloons' magenta, the gems' and keys' yellow | per missile, up to quad |

1-line player resolution (2KB at `PMBASE`) to begin with. `infill.mjs` chooses each meanie's
width and blocks by how many of its visible pixels match the BBC's, as for the C64's Scrubbly.

## Time and memory

**CPU, PAL (estimates for milestone 0 to measure).** 114 cycles a line. A 4-line row costs
ANTIC about 260 cycles of its 456: 40 for the codes, 160 for the glyph lines, refresh, players,
the display list. With `HSCROL` on, the wide fetch (48 codes) adds about 40. So:

- About 8,000-10,000 cycles a frame free in the 200 lines shown.
- About 10,000 in the 112 lines that aren't.
- Less the DLIs: 25 short ones and 25 that wait on `WSYNC` (about 3,000 in all).

That is about 15,000-18,000 cycles a frame for the game, against the C64's 6,000-7,000. There is
also no multiplexer (C64: 3,100-4,200) and no fill (C64: about 3,300). NTSC has fewer spare
lines and comes later.

**Memory (64K, the OS switched out through `PORTB`, our own NMI and IRQ vectors).** A sketch,
to be laid out by a `memmap.py` like the C64's:

| | |
| --- | --- |
| Zero page | All ours with the OS out |
| Character sets | 1-4 bands, each twice (double buffering): 2-8KB, each on a 1KB boundary |
| Players and missiles | 2KB on a 2KB boundary (1-line resolution) |
| Display list | about 160 bytes (50 LMS rows, HUD), within one 1KB block |
| Map | 6.25KB (50 x 128) |
| Code | the shared logic (about 3,300 lines of the C64's), the overlay engine, the display, sound |
| Levels | packed, about 2.2-2.7KB each as on the C64. All of them from disk eventually, as the C64 expects to |

## Keys

POKEY's keyboard gives one key at a time (the last pressed, and whether a key is held). Walking
and jumping at once (X and O on the BBC and C64) can't be done from the keyboard. So the
joystick is the main control: left/right walk, up/down climb and jump, fire is the yoyo. The
keyboard gives Escape, the menu keys and, later, the typed commands (`L R U D J Y`), which need
one key at a time anyway. `read_keys` is the only part of `play.asm` to rewrite.

## Tools and tests

- **Assembler: 64tass**, as the C64 port uses, so `play.asm`, `collide.asm`, `yoyo.asm`,
  `hazards.asm` and `loader.asm` can be shared rather than copied. A `build.mjs` writes the XEX
  segments and the ATR.
- **Emulators:** atari800 5.0 (it has AltirraOS built in, so no Atari ROMs, the way the C64
  tests use a stand-in ROM), under Xvfb: `test/shot.sh` captures its window, as it has no
  headless screenshot. Altirra (the accurate one, under Wine) for the timing-critical checks,
  where it can be downloaded. An `atari.py` will drive atari800 as `vice.py` drives VICE.
- **Checks reused:** `conn64.mjs` (movement, from every start holding every key), the py65 logic
  tests, `troggshot.py`-style pixel checks of Trogg, and `compare.py`-style row checks of the
  screen against `level.mjs`'s preview.
- **New:** an overlay checker (after each frame, every map cell is either the level's code or a
  pool code whose 4 bytes are the background's ANDed and ORed correctly; nothing left behind
  after a restore, like `tidy8.mjs` on the BBC), and the infill conflict check in `level.mjs`.

## Milestones

Each is checked before the next, and this file is updated as they're done.

0. **The display, measured.** Small test programs in atari800, Altirra, then on a real 800XL:
   - 4-line rows (**done in atari800**: `test/rows4.asm`; Altirra and the real machine to do).
   - Players in front of `PF2` under black hi-res pixels: the luminance rule as described.
   - The cycles free, with and without `HSCROL`'s wide fetch, with 50 DLIs.
   - Blank-line fine vertical scrolling.
   - Check: a photo of the real machine's screen, and the numbers in this file.
1. **Data:** `level.mjs`'s Atari output for A_1. Monochrome glyphs with the colour patterns,
   128-character band sets, the pool and common glyphs reserved, the 50 x 128 map, the patches,
   a preview PNG with the infills drawn. Check: every cell read back through its band's set, as
   `pack.mjs` does.
2. **A_1 shown, scrolling:** display list, row DLI, VBI, the joystick moving the scroll. Check:
   screenshots against the preview, row by row, at many scroll positions.
3. **Movement:** the shared `play.asm`, ticks from the VBI with catch-up, the joystick. Trogg
   as a box at first. Check: `conn64.mjs` and `keytest.py` against the Atari build.
4. **Trogg drawn:** the overlay engine and his P0/P1 infill, the camera following him. Check:
   pixel-exact at every phase of a cell, still and scrolling; the overlay checker; cycles a
   frame measured.
5. **Yoyo, Scrubblies knocked off, gems and keys, collisions:** the shared `yoyo.asm` and
   `collide.asm`, the string as overlay cells, the patches. P2/P3 infills on the Scrubblies.
   Check: `collidetest.py`, `picktest.py`, the infill conflict check.
6. **Balloons and daggers:** the shared `hazards.asm` as overlays, missiles for the balloons'
   infill. Check: `hazardtest.py` and `poptest.py`; the frame's cycles on Insane.
7. **Death, the level's end, checkpoints, the timer:** as the C64's milestones 11-13. Check:
   `cptest.py`.
8. **Sound:** the BBC player's design on POKEY (4 channels at 8 bits, or 2 joined at 16 bits for
   the bass), the tunes from `../tools/music.py`. Check: a `music8.mjs`-style comparison with
   the Steam version.
9. **The front end** (the attract screen, the level selection) and **A_2, A_3:** the Poglet's and
   Hooter's multicolour infills on P2/P3. Check: as for A_1.
10. **The other levels**, as the C64 gets them, and vertical scrolling. NTSC.

## Unknowns, to measure early

- **4-line rows on real hardware.** They work in atari800 with a window of 2-3 cycles. If a real
  machine disagrees: 8x8 rows with 4 bands and the pool capped (the glyph budget shows how tight).
- The overlay engine's cost with Trogg, the yoyo and six hazards out (milestone 4, then 6).
- Whether two players are enough for the meanies' infills on every screen of a level: `level.mjs`
  reports the worst row. If not: the missiles, or a meanie without infill there.
- Whether the monochrome patterns read well enough without the C64's colour bands (milestone 1's
  preview).
- Glyph budgets on the later, wider levels (`tools/budget.py` on each).

## Decisions for you

- The C64's map as is (the levels as squeezed into 200 lines), or the BBC's own heights? This
  plan assumes the C64's, for the reuse.
- Sharing the logic source with the C64 (moving it to a common directory) or copying it here.
- Are the per-row meanie positions (two stores in the row DLI) within "not too crazy"?
