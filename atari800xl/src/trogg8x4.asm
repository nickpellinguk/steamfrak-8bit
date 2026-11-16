; Trogg, balloons and daggers on the 8x4 screen: their outlines drawn into spare characters, AND
; then OR, a byte (8 pixels) at a time from the 10-bit graphics (tools/sprites.py: for each of 4
; shift positions, a byte a window, an index into that shift's AND and OR tables), at any
; position, partly or wholly off the screen. Trogg moves as in the game (move.asm, the C64's
; movement), the screen following him; balloons rise from the level's bottom and daggers fly in
; from its top, as in the game (hazards.asm, the C64's).
;
; The display is screen8x4.asm's: 60 rows of 4 lines (240 lines, ANTIC's most: scanlines 8-247,
; the level's lines 16-255), a bottoms row (glyph lines 4-7) then a tops row (0-3), so each
; character holds two 4-line glyphs. Spare characters: codes POOL0 on,
; given out a cell at a time, their bottoms halves and tops halves separately (so a code serves
; a cell of a bottoms row and one of a tops row), 64 of each.
;
; Hardware sprites where they can be had (mux), in this order:
;  1. Trogg's infill: P0 yellow and P1 magenta, with missiles 0 and 1 (his outline, 26 wide, is
;     too wide for a player: it's drawn in software, or on players band by band, 3 below);
;  2. the Scrubblies' bodies (magenta): first one double-width player each (P3, P1 or P0: 21 of
;     540 pixels wrong), then two normal-width players side by side where a second is free
;     (exact for the C64's), else none;
;  3. (HWOUT only) Trogg's outline from a band of his on down (not his first), on P2 and P3
;     (black: his left and right 16 pixels), his infill there with holes where the outline is;
;  4. balloons and daggers: (HWOUT only) a balloon's outline and infill on a pair (P0 and P1, or P2
;     and P3: the outline the first, in front); else its infill alone on P3, P1 or P0 with its
;     outline in software, else software; (HWOUT only) a dagger's outline on P2 or P0, else
;     software. Players are 2 hires pixels a block at their finest, so outlines on them are at
;     half resolution: by default outlines are always drawn in software, players carry infills.
; Colours: P1 always magenta, P2 always black; P0 black, Trogg's yellow or magenta and P3 magenta
; or black, set band by band, with P0's, P1's and P3's widths. Things not wholly on the screen across are left to
; software (a player would show over the border); above and below, the players' graphics are
; clipped. A player serves several things down the screen: each pair of rows' first DLI sets the
; registers that change for the next band of 8 lines. The DLI fires on the bottoms row's last
; line (display line 8k + 3) and, with ANTIC fetching the character codes on the next line, its
; writes are only done during the line after that: so band k's registers hold from display line
; 8k + 6 (scanline BAND0 + 8k), and a thing on a player must end by line 8k + 2 for another to
; start there in band k (4 lines before the band starts). A thing's registers can be written in any band from the one
; after the thing above it on its player has ended (by line 8k + 2) down to its top's, or by the
; VBI if nothing's above it: the latest with room is chosen. The DLI must be done before the tops row's DLI 4 lines on
; (an NMI would interrupt it, and it would leave the rows' order the wrong way round): with
; ANTIC's fetches that's about 150 cycles, so a band gets at most 5 register writes, which the
; allocator keeps to: a player's change writes its position, and P0's colour and width, P1's
; width, P3's colour and width (3, 2, 1, 3). The missiles (Trogg's alone) are set once a frame by the VBI.
; Measured in atari800, colour by colour (test/checktrogg.py).
;
; Each frame (the main program, while the frame before is shown), plot draws each thing in
; software (Trogg; balloons and daggers without a hardware outline): for
; each cell it covers on the screen (in the 60 rows, and the 41 columns in view) where it isn't
; all transparent: a spare character's half of the set not shown, started from the level's half
; glyph there or, if something drawn before this frame has the cell, from that. The level's code
; comes from the screen's map (the frame shown): below POOL0 it's the level's; a spare character
; there was drawn the frame before, and that frame's table (ORIGA or ORIGB, by turns) says what
; it was over; and a cell a gem's, key's or Scrubbly's patch is changing this frame has its new
; code (pick.asm: pkorig). So there's no second, clean copy of the map: the level's map is
; packed in the program (screen.py) and unpacked into the screen's at the start; its 4 lines ANDed and ORed on; and for the cell, an "lda #code, sta cell" in a program
; for the VBI, and an "lda #level's code, sta cell" in a program for the VBI after (putting it
; back). Then the VBI, all at once: last frame's putting back program and this frame's program
; run (6 cycles a cell), the character sets swapped (the static glyphs are in both), the scroll
; set.
;   -D INVINCIBLE=1: nothing kills Trogg; -D STARTX=x -D STARTY=y: a test's start instead of the
;   level's (his origin: level pixels, y the C64's, 24 below the map's line)
;   -D NOHAZ=1: no balloons or daggers; -D STRESS=1: one every 20 ticks or so (6 out all the time);
;   -D INSANE=1: Insane's numbers (Hard's by default)
;   -D HWOUT=1: outlines on players too (2-pixel resolution: Trogg's from a band down, a balloon's
;   with its infill, a dagger's), where they're free; else (the default) outlines are always
;   drawn in software, at full resolution, and players only carry infills
        .weak
DELAY   = 1
LEVEL   = "A_1"
INVINCIBLE = 0
STARTX  = 0                         ; (0: the level's start)
STARTY  = 0
NOHAZ   = 0
STRESS  = 0
INSANE  = 0
HWOUT   = 0
        .endweak
        .include "../build/" .. LEVEL .. ".inc"
XMAX    = (NCOLS - 40) * 4          ; the scroll's range, in colour clocks (2 pixels)
POOL0   = 64                        ; the first spare character
NPOOL   = 128 - POOL0
        .cerror NCODES > POOL0, "the level's glyphs reach the spare characters"
NOBJ    = 15                        ; things: Trogg, the Scrubblies, the balloons and daggers (16th:
                                    ; the multiplexer's, for Trogg's outline's bands)
GR_SCRUB = GR_N                     ; (a Scrubbly: no graphic, only its infill)
GR_KEY  = GR_N + 1                  ; (a key: likewise, its yellow)

; the hardware (the OS is switched out: no shadow registers, our own NMI handler)
HPOSP0  = $d000
HPOSM0  = $d004
SIZEP0  = $d008
SIZEM   = $d00c
TRIG0   = $d010
COLPM0  = $d012
COLPF1  = $d017
COLPF2  = $d018
COLBK   = $d01a
PRIOR   = $d01b
GRACTL  = $d01d
RANDOM  = $d20a
SKCTL   = $d20f
PORTA   = $d300
PORTB   = $d301
DMACTL  = $d400
DLISTL  = $d402
HSCROL  = $d404
VSCROL  = $d405
PMBASE  = $d407
CHBASE  = $d409
WSYNC   = $d40a
VCOUNT  = $d40b
NMIEN   = $d40e
NMIST   = $d40f
NMIRES  = $d40f

; memory (64K, the OS and BASIC switched out: ANTIC sees the RAM under it as the CPU does)
;   $0800-$abff the program (the level's map packed in it);  $ac00, $ad00 what's under the spare
;   characters drawn, a frame's and the one before's;  $ae00 the display list;  $b000, $b400 the
;   character sets;  $b800, $bb00, $c000 the VBI's programs (the last in the first players'
;   graphics' unused first $300);  under the OS: $c000, $c800 the players' graphics, $d800 the
;   screen's map, $f600 the bands' registers;  the claims in three parts, $f980, $c800 (the
;   second players' graphics' unused $300) and $be00
TOPL    = 8                         ; the screen's first scanline (the players' memory's line)
LASTL   = TOPL + NROWS * 4 - 1      ; ... and its last (247)
BAND0   = TOPL + 6                  ; band 0's first line (above it, the VBI's registers)
ORIGA   = $ac00                     ; what's under each spare character drawn (the level's code),
ORIGB   = $ad00                     ; a frame's and the frame before's, by turns (code | $80 on
                                    ; bottoms rows)
DLIST   = $ae00
FONTA   = $b000                     ; the two character sets (the static glyphs in both)
FONTB   = $b400
PROGW   = $b800                     ; the VBI's programs: this frame's codes in, and putting each
PROGR1  = $bb00                     ; frame's cells back (two: built a frame, run the next)
PROGR0  = $c000                     ; (each 150 x "lda #, sta abs" and an rts: $2ef bytes)
PMG0    = $c000                     ; the players' and missiles' graphics, two (2K each, 1-line
PMG1    = $c800                     ; resolution: missiles at + $300, player n at + $400 + n * $100)
SCREEN  = $d800                     ; the map shown: 60 rows of 128 bytes (to $f5ff)
CLAIMA     = $f980                     ; the cells drawn this frame: 60 rows of 42 (the 41 columns in
NCLAIMA    = 39                        ; view), the spare character's code there or 0; rows 0-38 at
CLAIMB     = $c800                     ; CLAIMA, the next 18 at CLAIMB, the rest at CLAIMC (clrl, clrh: each
NCLAIMB    = 18                        ; row's address)
CLAIMC  = $be00
PROGP   = $be80                     ; the VBI's patch program (pkprog: PMAX x lda #, sta abs, rts)
        .cerror PROGP + PMAX * 5 + 1 > PROGR0, "the patch program reaches PROGR0"
        .cerror CLAIMA + NCLAIMA * 42 > $fffa, "the claims reach the vectors"
        .cerror CLAIMB + NCLAIMB * 42 > PMG1 + $300, "the claims reach the missiles"
        .cerror CLAIMC + (NROWS - NCLAIMA - NCLAIMB) * 42 > PROGP, "the claims reach the programs"
        .cerror PROGR1 + 751 > CLAIMC, "the program reaches the claims"
BT      = $f600                     ; the bands' registers, both frames' (interleaved: band j's at
                                    ; (j + 1) * 2 + set; the top 4 lines', set by the VBI, at set):
BT_HP   = BT                        ; HPOSP0-3 (4 x 64)
BT_C    = BT + $100                 ; COLPM0-3 (4 x 64: P0's and P3's used)
BT_S    = BT + $200                 ; SIZEP0-3 (4 x 64: P1's and P3's used)
BT_M    = BT + $300                 ; which change in the band: bit n player n (only those are
                                    ; written: registers hold down the screen)
BT_W    = BT + $340                 ; the register writes in the band, so far (5 at most)
        .cerror BT + $380 > CLAIMA, "the bands' registers reach the claims"
        .cerror (NROWS / 2 + 1) * 2 > 64, "too many bands for the registers' tables"
WMAX    = 5
COL_BLK = $00                       ; outlines
COL_MAG = $58                       ; balloons', Trogg's magenta
COL_YEL = $1e                       ; Trogg's yellow

; zero page
scrx    = $80                       ; the scroll shown (colour clocks)
nscrx   = $81                       ; the scroll for the frame being made
lmsoff  = $82
leftc   = $83                       ; the level's first column in view, this frame
tx      = $84                       ; Trogg's origin: x (2 bytes), y (map lines), frame
ty      = $86
tf      = $87
tdir    = $88                       ; 0 facing right, 1 left
tick    = $89                       ; frames made (for the animations)
front   = $8a                       ; the character set shown: 0 A, 1 B
ready   = $8b                       ; a frame is made, for the VBI to show
pg      = $8c                       ; plot's: the graphic, its top left x (2 bytes, even, signed),
px      = $8d                       ; its top line's scanline
pd      = $8f
rq      = $90                       ; the row being drawn + 8, and the last
rqlast  = $91
scol0   = $92                       ; its first column less the first in view (signed)
scol    = $93
si      = $94                       ; the shift (0-3), bytes across, height
nb      = $95
ht      = $96
cstep   = $97                       ; a column of the graphic: its height + 6
half    = $98                       ; 4 on a bottoms row, 0 on a tops row
jj      = $99
code    = $9a
ncell   = $9b                       ; cells this frame
orig    = $9c                       ; the level's code in the cell being drawn
nbot    = $9d                       ; spare characters' halves given out this frame
ntop    = $9e
bfhi    = $9f                       ; the character set not shown (high byte)
dptr    = $a0                       ; the graphic's indices, column 0's first line
dp      = $a2                       ; ... its column at the row's first line
cp      = $a4                       ; the spare character's half being drawn
sp      = $a6                       ; what it starts from (the level's glyph, or itself)
mp      = $a8                       ; the row in view in the screen's map
cl      = $ac                       ; ... in the claims
wp      = $ae                       ; the next entry of this frame's program
rp      = $b0                       ; ... of its putting back program
tmp     = $b2                       ; (2 bytes)
fresh   = $bd                       ; 1 when the last VBI showed a new frame, else 0 (a frame
                                    ; not made in time: the picture is still "shown")
drops   = $be                       ; frames not made in time (2 bytes)
idle    = $c6                       ; times round the wait for the VBI (2 bytes)
nob    = $c8                       ; things drawn this frame
obi     = $c9                       ; the three records of things drawn (OBJS + 0, 40, 80): the
shi     = $ca                       ; frame being made's, the one shown's, the one before's
pvi     = $c3
hslot   = $cd
rcur    = $ce                       ; the putting back programs: being built (high byte), to run
rprev   = $cf
lastoff = $c5                       ; the LMS offset in the display list
dliv    = $d0                       ; the next DLI's handler (2 bytes)
stick   = $d2                       ; the joystick this frame
pmshow  = $d3                       ; the players' graphics and bands' set shown (0, 1)
bandx   = $d4                       ; the next band's registers (the DLIs')
; the multiplexer's, per thing this frame (16 each): its top and bottom line on the screen
; (scanline: the players' memory's line, clipped to the screen's TOPL-LASTL), the line
; its band starts (the band of its top: a player's position can change there), its position
; for a player, whether it's wholly on the screen across, and the things in order down
oT      = $00
oB      = $10
oBS     = $20
oHP     = $30
oIn     = $40
order   = $50
ivn     = $60                       ; things on each player (4)
mk      = $64                       ; (the multiplexer's scratch)
mp2     = $65
mcol    = $66
moff    = $67
msrc    = $68                       ; (2)
mdst    = $6a                       ; (2)
mcnt    = $6c
mset    = $6d                       ; the set being made
midx    = $6e
mlast   = $6f
stmp    = $70
msize   = $71
hwl     = $72                       ; the line Trogg's outline goes onto players from (255: not)
rqmax   = $73                       ; plot's: rows from this on (+ 8) not drawn
hsrc    = $74                       ; (2: Trogg's holed infill)
tgr     = $76
snum    = $77
cnum    = $f0
cfix    = $f1
uidx    = $f2
eml     = $f3                       ; plot's: the left and right columns' empty cells, a bit a row
emr     = $f5                       ; (2 each: shifted out a row at a time)
eb      = $f7                       ; this row's: bit 0 the left column's empty, bit 1 the right's
lastj   = $f8                       ; the last column (nb - 1)
vbcnt   = $d5                       ; fields counted by the VBI, and as of the last frame made
lastvb  = $d6
nticks  = $d7
norec   = $d8                       ; strip's: 1 not to list the strip for clearing (kept apart)
sold    = $d9                       ; (scratch: a Scrubbly's old key)
nocopy  = $da                       ; strip's: 1 to skip the copy (the strip's there already)
mk2     = $db                       ; (keepclr's: lines)
mk3     = $dc
mk4     = $dd
mk5     = $de
mk3s    = $df
scrk    = $06b0                     ; each set's Scrubblies' strips there: lv | pa << 2 | pb << 4
                                    ; (255 none) (set * 8 + s)
scrw    = $06c0                     ; this frame's: 1 if a Scrubbly's strips are to be written
trT     = $06c8                     ; each set's Trogg's strips' lines there (top, bottom; top 0 none)
trB     = $06ca
wend    = $f9                       ; (2) where this frame's program's rts went (for its lda back)
rend    = $fb                       ; (4: low 0, 1, high 0, 1) likewise each putting back program's                       ; chooseb's: 1 to keep the thing's band (a second player)
oWB     = $e0                       ; (16) the line of the band each thing's registers are written
                                    ; for: its top's band, or an earlier one with room (the VBI's
                                    ; for the top, 32, if nothing's above it on its players)
cl_lo   = $0200                     ; this frame's cells' claims, to clear (128 at most)
cl_hi   = $0280
iv_T    = $0300                     ; things on each player: top, bottom, band start (p * 16 + k)
iv_B    = $0340
iv_BS   = $0380
pc_cnt  = $03c0                     ; each set's player strips, to clear (2)
pc_lo   = $0400                     ; (set * 32 + k)
pc_hi   = $0440
pc_n    = $0480

; the things drawn: three records (r = 0, 1, 2) of, per thing (16: at OB_x + 16 r + i), graphic, x
; (2), top line + 32, how it's drawn (0 hardware outline and infill, or for a Scrubbly two
; players; 1 software outline and hardware infill, or for a Scrubbly one double-width; 2
; software, or no infill), its players (outline, yellow or left; infill, magenta or right; $ff
; none); and (at OB_x + r) the line Trogg's outline is on players from, the scroll, how many, the
; missiles' positions. obi, shi, pvi (16 r): the frame being made, the frame shown, the one before
; (what a frame's picture shows, when its VBI shows a new frame)
OBJS    = $0500
OB_G    = OBJS
OB_XL   = OBJS + $30
OB_XH   = OBJS + $60
OB_D    = OBJS + $90
OB_LV   = OBJS + $c0
OB_PA   = OBJS + $f0
OB_PB   = OBJS + $120
OB_HW   = OBJS + $150
OB_SCR  = OBJS + $153
OB_N    = OBJS + $156
OB_M0   = OBJS + $159
OB_M1   = OBJS + $15c
OB_PK   = OBJS + $15f               ; the patch objects the map shows gone (pshow), per record (3
                                    ; bytes: + 0, 3, 6)
OB_S0   = OBJS + $168               ; the yoyo's string: its left end (+ 0 low, 3 high), right end
OB_S1   = OBJS + $16e               ; (likewise), scanline (0: none), per record
OB_SY   = OBJS + $174
; the balloons and daggers: kind (0 none, 1 balloon, 2 dagger), x (2), top line + 32, fraction

        * = $0800                   ; (no DOS: low memory is ours from here)
        .include "../build/sprites_tab.inc"   ; the page-aligned tables first, so no gaps between
                                    ; them (plot's masks, the AND and OR tables, the characters'
                                    ; offsets, the DLIs' jump table and the DLIs, in one page)
        .align $100                 ; (glo and glo4 in one page: only the low byte's patched)
glo     .for c = 0, c < 128, c += 1 ; a character's offset in its set (low), and with the bottoms
        .byte <(c * 8)              ; half (+ 4)
        .endfor
glo4    .for c = 0, c < 128, c += 1
        .byte <(c * 8 + 4)
        .endfor
ghiA    .for c = 0, c < 128, c += 1 ; its address's high byte in each set
        .byte >(FONTA + c * 8)
        .endfor
ghiB    .for c = 0, c < 128, c += 1
        .byte >(FONTB + c * 8)
        .endfor
        .align $100
dltab   .word dlb0, dlb1, dlb2, dlb3, dlb4, dlb5, dlb6, dlb7, dlb8, dlb9, dlb10, dlb11, dlb12, dlb13, dlb14, dlb15
dlia    pha                         ; a bottoms row's last line: VSCROL 3 for the tops row's end;
        txa                         ; the next band's players' registers, those that change
        pha                         ; (written while this line and the ones after are drawn:
        lda #3                      ; things ending on a player end before)
        sta VSCROL
        ldx bandx
        lda BT_M,x
        asl a
        sta dlj+1                   ; (16 blocks by the band's mask)
dlj     jmp (dltab)
dlend   inx
        inx
        stx bandx
        lda #<dlib
        sta dliv
        pla
        tax
        pla
        rti

dlib    pha                         ; a tops row's last line: VSCROL 4 for the next row's start
        lda #4
        sta WSYNC
      .rept DELAY
        nop
      .endrept
        sta VSCROL
        lda #<dlia
        sta dliv
        pla
        rti
        .cerror (>dlia) != (>dlib), "the DLIs must share a page (only dliv's low byte changes)"

start   sei                         ; the OS switched out: no interrupts till ours are set
        lda #0
        sta NMIEN
        sta DMACTL
        lda PORTB
        and #$fe                    ; OS ROM off
        ora #$82                    ; BASIC off, self-test off
        sta PORTB
        lda #<nmi
        sta $fffa
        lda #>nmi
        sta $fffb
        lda #<start
        sta $fffc
        lda #>start
        sta $fffd
        lda #<irq
        sta $fffe
        lda #>irq
        sta $ffff
        lda #3
        sta SKCTL                   ; (POKEY running: RANDOM)
        lda #<lvmap                 ; the screen's map unpacked (unpack.asm: the level's, packed
        sta usrc                    ; by screen.py), the second set from the first, the claims
        lda #>lvmap                 ; clear
        sta usrc+1
        lda #<SCREEN
        sta udp
        lda #>SCREEN
        sta udp+1
        jsr unpack
        ldx #0
-       lda FONTA,x
        sta FONTB,x
        lda FONTA+$100,x
        sta FONTB+$100,x
        lda FONTA+$200,x
        sta FONTB+$200,x
        lda FONTA+$300,x
        sta FONTB+$300,x
        inx
        bne -
        lda #<BT                    ; the bands' registers and the claims clear (CLAIMB's with the
        sta mp                      ; players' graphics, below)
        lda #>BT
        sta mp+1
        lda #0
        tay
        ldx #>($ff00 - BT)
-       sta (mp),y
        iny
        bne -
        inc mp+1
        dex
        bne -
-       sta $ff00,y                 ; (up to the vectors)
        iny
        cpy #$fa
        bne -
        ldy #(NROWS - NCLAIMA - NCLAIMB) * 42
-       dey
        sta CLAIMC,y
        bne -
        lda #<DLIST
        sta DLISTL
        lda #>DLIST
        sta DLISTL+1
        lda #>FONTA
        sta CHBASE
        lda #$00                    ; the outlines: luminance 0
        sta COLPF1
        lda #$9a                    ; the background (PF2)
        sta COLPF2
        lda #$00
        sta COLBK
        lda #<dlia
        sta dliv
        lda #>dlia
        sta dliv+1
        ldx #>PROGW                 ; the VBI's programs: entries prefilled (lda #, sta abs: only
        jsr prefill                 ; the operands are written), nothing to do yet
        ldx #>PROGR0
        jsr prefill
        ldx #>PROGR1
        jsr prefill
        lda #$60                    ; (each ends at once: an rts in its first entry's place)
        sta PROGW
        sta PROGR0
        sta PROGR1
        lda #<PROGW
        sta wend
        sta rend
        sta rend+1
        lda #>PROGW
        sta wend+1
        lda #>PROGR0
        sta rend+2
        lda #>PROGR1
        sta rend+3
        lda #>PROGR0
        sta rcur
        lda #>PROGR1
        sta rprev
        lda #0
        sta obi
        lda #16
        sta shi
        lda #32
        sta pvi
        lda #0
        sta OB_N + 1
        sta OB_N + 2
        sta OB_M0 + 1
        sta OB_M1 + 1
        sta OB_M0 + 2
        sta OB_M1 + 2
        sta pmshow
        sta pc_cnt
        sta pc_cnt+1
        sta norec
        sta trT
        sta trT+1
        ldx #15
        lda #255
-       sta scrk,x
        dex
        bpl -
        lda #0
        lda #2
        sta bandx
        ldx #7                      ; the players: normal width, in front of the playfield
        lda #0
-       sta SIZEP0,x                ; (and SIZEM, HPOS of all off the screen)
        sta HPOSP0,x
        dex
        bpl -
        sta SIZEM
        lda #COL_MAG                ; P1 magenta (infills), P2 black (outlines)
        sta COLPM0 + 1
        lda #COL_BLK
        sta COLPM0 + 2
        lda #1
        sta PRIOR
        lda #3
        sta GRACTL
        lda #>PMG0
        sta PMBASE
        lda #<(PMG0 + $300)         ; both graphics clear (not PROGR0, in PMG0's first $300)
        sta mdst
        lda #>(PMG0 + $300)
        sta mdst+1
        ldx #(PMG1 + $800 - PMG0 - $300) >> 8
        lda #0
        tay
-       sta (mdst),y
        iny
        bne -
        inc mdst+1
        dex
        bne -
        lda #$ff
        sta lastoff
        lda #0
        sta front
        sta ready
        sta tdir
        sta tick
        sta scrx
        sta nscrx
        sta drops
        sta drops+1
        sta idle
        sta idle+1
        lda #0
        sta pshow                   ; (a = 0: the map shows every gem, key and Scrubbly)
        sta pshow+1
        sta pshow+2
        sta ppn
        lda #$60                    ; (the patch program: nothing)
        sta PROGP
        lda #0
        jsr newlevel                ; Trogg at the start
        lda nscrx
        sta scrx
-       lda VCOUNT                  ; the display on from a vertical blank
        cmp #124
        bcc -
        lda #$3e                    ; normal width, playfield, players and missiles (1-line)
        sta DMACTL
        lda #4
        sta VSCROL
        lda #$c0
        sta NMIEN

main    lda ready                   ; wait for the VBI to show the last frame made
        beq +
        inc idle                    ; (counting the time to spare: 13 cycles a time round)
        bne main
        inc idle+1
        jmp main
+       lda vbcnt                   ; game ticks: one for each field since the last frame made (1
        tax                         ; to 4: as the C64 version makes up for late frames, and the
        sec                         ; BBC version runs more ticks a frame when drawing's slow)
        sbc lastvb
        stx lastvb
        bne +
        lda #1
+       cmp #5
        bcc +
        lda #4
+       sta nticks
tklp    jsr gametick                ; a tick: the joystick, Trogg, the balloons and daggers
        jsr troggpos                ; (move.asm, hazards.asm), the camera (his graphic and top
                                    ; left: pg, px, pd)
        jsr camera
        inc tick
        dec nticks
        bne tklp
        jsr troggpos                ; (his, for the frame)
        lda nscrx                   ; the frame's first column in view, the set to draw in
        lsr a
        lsr a
        sta leftc
        lda front
        eor #1
        tax
        lda fonthi,x
        sta bfhi
        lda #0
        sta ncell
        sta nbot
        sta ntop
        sta nob
        sta wp                      ; the programs started (page-aligned: their low bytes go
        sta rp                      ; together), the last ends' lda put back
        lda #>PROGW
        sta wp+1
        lda rcur
        sta rp+1
        ldy #0
        lda #$a9
        sta (wend),y
        ldx #0
        lda rcur
        cmp #>PROGR1
        bcc +
        cmp #>PROGR0
        bcs +
        inx
+       lda rend,x
        sta tmp
        lda rend+2,x
        sta tmp+1
        lda #$a9
        sta (tmp),y
        lda front                   ; the set not shown's table of characters' high bytes
        eor #1
        tax
        lda ghit_lo,x
        sta cphi+1
        sta clmhi+1
        lda ghit_hi,x
        sta cphi+2
        sta clmhi+2
        lda ofr                     ; the tables of what's under the spare characters turned
        eor #1                      ; round: this frame's, the frame before's
        sta ofr
        clc
        adc #>ORIGA
        sta origc+2
        sta origc2+2
        eor #1                      ; (ORIGA's page even: ORIGB's the next)
        sta origp+2
        sta origp2+2
        jsr pkpatch                 ; a gem, key or Scrubbly gone (or back) (pick.asm)
        jsr addobj                  ; Trogg
        ldx #0                      ; the Scrubblies (their infill)
-       cpx #SCR_N
        bcs +
        stx hslot
        lda #GR_SCRUB
        sta pg
        lda scr_xl,x
        sta px
        lda scr_xh,x
        sta px+1
        lda scr_pd,x
        sta pd
        ldy pby + NPK,x             ; (knocked off, as the map shows: below the screen, unseen)
        lda pbm + NPK,x
        and pshow,y
        beq skn
        lda #250
        sta pd
skn     jsr addobj
        ldx hslot
        inx
        bne -
+
      .if !NOHAZ
        jsr hzlist                  ; the balloons and daggers listed
      .endif
        jsr yolist                  ; the yoyo and its string
        jsr pklist                  ; the keys (their yellow)
        jsr mux                     ; hardware sprites given out
        jsr pmdraw                  ; ... their graphics and bands' registers
        ldx #1                      ; the rest drawn in software: each thing in order, then
swlp    cpx nob                     ; Trogg on top (as the BBC version: the hazards, the string,
        bcs swtr                    ; the yoyo, him)
        stx hslot
        jsr swone
        ldx hslot
        inx
        bne swlp
swtr    ldx #0
        stx hslot
        jsr swone
        jmp swend
swone   txa                         ; thing x
        clc
        adc obi
        tay
        lda OB_G,y
        cmp #GR_YOYO0               ; (the yoyo: its string first)
        bcc +
        cmp #GR_YOYO3 + 1
        bcs +
        lda stry
        beq +
        tya
        pha
        jsr strline
        pla
        tay
        ldx hslot
+       lda OB_LV,y
        bne +
        rts                         ; (hardware outline: nothing here)
+       lda OB_G,y
        cmp #GR_SCRUB
        bcc +
        rts                         ; (a Scrubbly or a key: in the map)
+       sta pg
        lda #255                    ; plot's row limit: Trogg's from where his outline's on
        cpx #0                      ; players (rows starting on or after that line not drawn)
        bne +
        lda hwl
        clc
        adc #3
        bcc +
        lda #255
+       lsr a
        lsr a
        cpx #0
        beq +
        lda #63
+       sta rqmax
        lda OB_XL,y
        sta px
        lda OB_XH,y
        sta px+1
        lda OB_D,y
        sta pd
        jmp plot
swend   jsr pkprog                  ; the patch program (pick.asm: before the claims are cleared)
        lda #$60                    ; the programs ended (an rts over the next entry's lda: put back
        ldy #0                      ; when the program's next built)
        sta (wp),y
        sta (rp),y
        lda wp
        sta wend
        lda wp+1
        sta wend+1
        ldx #0                      ; (which putting back program: 0 PROGR0, 1 PROGR1)
        lda rp+1
        cmp #>PROGR1
        bcc +
        cmp #>PROGR0
        bcs +
        inx
+       lda rp
        sta rend,x
        lda rp+1
        sta rend+2,x
        lda obi                     ; the record: the scroll, how many (r = obi / 16)
        lsr a
        lsr a
        lsr a
        lsr a
        tax
        lda nscrx
        sta OB_SCR,x
        lda nob
        sta OB_N,x
        lda pshow
        sta OB_PK,x
        lda pshow+1
        sta OB_PK + 3,x
        lda pshow+2
        sta OB_PK + 6,x
        lda stx0
        sta OB_S0,x
        lda stx0+1
        sta OB_S0 + 3,x
        lda stx1
        sta OB_S1,x
        lda stx1+1
        sta OB_S1 + 3,x
        lda stry
        sta OB_SY,x
        ldx ncell                   ; the claims cleared for the next frame
        beq +
        lda #0
        sta tmp+1
-       dex
        lda cl_lo,x
        sta tmp
        lda cl_hi,x
        sta tmp+1
        ldy #0
        tya
        sta (tmp),y
        txa
        bne -
+       lda #1
        sta ready
        jmp main
fonthi  .byte >FONTA, >FONTB

; ---- Trogg's graphic and top left (x even): pg, px, pd
troggpos ldx tf
        stx pg
        lda tx                      ; px = (tx - xo) & ~1
        sec
        sbc gr_xo,x
        and #$fe
        sta px
        lda tx+1
        sbc #0
        sta px+1
        lda gy                      ; pd = the scanline: the map's line (gy - 24) + 16 - yo, so
        sec                         ; gy - yo - 8, kept to 0-255
        sbc gr_yo,x
        tay
        lda gy+1
        sbc #0
        tax
        tya
        sec
        sbc #8
        tay
        txa
        sbc #0
        bmi tpneg                   ; (above the screen's top by 8 or more: 0)
        beq +
        ldy #255
+       sty pd
        rts
tpneg   lda #0
        sta pd
        rts

; ---- The scroll follows him: his x on the screen kept between 100 and 200 pixels
camera  lda px+1                    ; his x in colour clocks, less the scroll (16 bits)
        lsr a
        sta tmp+1
        lda px
        ror a
        sec
        sbc nscrx
        sta tmp
        lda tmp+1
        sbc #0
        bmi left                    ; (left of the screen's edge: only after a jump)
        bne right                   ; (256 or more)
        lda tmp
        cmp #50
        bcc left
        cmp #101
        bcs right
        rts
left    lda nscrx
        beq +
        dec nscrx
+       rts
right   lda nscrx
        cmp #XMAX
        bcs +
        inc nscrx
+       rts

; ---- The balloons and daggers (hazards.asm) listed for the frame: each from its origin (level
; pixels, y the C64's) less its graphic's: px = (x - xo) & ~1, pd = y - yo - 8 (the scanline).
; One whose top is above the players' memory's (pd < 0: its bottom at most a line into the
; screen) isn't drawn
hzlist  ldx #NHZ - 1
hzl     lda oact,x
        beq hzln
        stx hslot
        tay
        lda hzgr - 1,y
        sta pg
        tay
        lda oxl,x
        sec
        sbc gr_xo,y
        and #$fe
        sta px
        lda oxh,x
        sbc #0
        sta px+1
        lda oy,x
        sec
        sbc gr_yo,y
        sta tmp
        lda oyh,x
        sbc #0
        sta tmp+1
        lda tmp
        sec
        sbc #8
        sta pd
        lda tmp+1
        sbc #0
        bne +                       ; (above the players' memory: not drawn)
        jsr addobj
+       ldx hslot
hzln    dex
        bpl hzl
        rts
hzgr    .byte GR_BALLOON, GR_DAGGERLR

; ---- The yoyo (yoyo.asm) listed for the frame, after the balloons and daggers (so drawn after
; them, before Trogg), from its origin (yo_x, yo_y) as they are; and its string (the BBC version's):
; from his hand (tx + 12, or tx - 12 facing left) to yo_x, its left end kept to the level's, on
; level line yo_y - 1 (stx0, stx1, stry: its scanline, 0 for none), drawn just before the yoyo
yolist  lda #0
        sta stry
        lda tstate
        cmp #ST_YOYO_OUT
        bcs +
        rts
+       jsr yoframe
        sta pg
        tay
        lda yo_x
        sec
        sbc gr_xo,y
        and #$fe
        sta px
        lda yo_x+1
        sbc #0
        sta px+1
        lda yo_y
        sec
        sbc gr_yo,y
        sta tmp
        lda yo_y+1
        sbc #0
        sta tmp+1
        lda tmp
        sec
        sbc #8
        sta pd
        lda tmp+1
        sbc #0
        bne +                       ; (above the players' memory: not drawn)
        jsr addobj
+       lda tface
        bne yol
        lda tx                      ; facing right: his hand to the yoyo
        clc
        adc #12
        sta stx0
        lda tx+1
        adc #0
        sta stx0+1
        lda yo_x
        sta stx1
        lda yo_x+1
        sta stx1+1
        jmp yoy
yol     lda yo_x                    ; facing left: the yoyo to his hand
        sta stx0
        lda yo_x+1
        sta stx0+1
        lda tx
        sec
        sbc #12
        sta stx1
        lda tx+1
        sbc #0
        sta stx1+1
yoy     lda stx1+1                  ; (wholly left of the level: none)
        bmi yon
        lda stx0+1
        bpl +
        lda #0
        sta stx0
        sta stx0+1
+       lda yo_y                    ; its scanline: yo_y - 1 - 8, on the screen
        sec
        sbc #9
        tay
        lda yo_y+1
        sbc #0
        bne yon
        cpy #TOPL
        bcc yon
        cpy #LASTL + 1
        bcs yon
        sty stry
yon     rts

; ---- strline: the string, set pixels stx0 to stx1 (level pixels) on scanline stry, ORed into the
; cells in view (spare characters, as plot's: one claimed this frame, or one started from the
; level's glyph)
strline lda stry
        sec
        sbc #TOPL
        pha
        and #3
        sta stln                    ; (the line in the row)
        pla
        lsr a
        lsr a
        pha                         ; (the row)
        lsr a                       ; the maps: row * 128 + 4 + leftc
        tax
        lda #0
        ror a
        ora #4
        clc
        adc leftc
        sta mp
        txa
        clc
        adc #>SCREEN
        sta mp+1
        pla
        tax
        stx prow
        lda pprow,x
        sta prf
        lda clrl,x                  ; the claims' row
        sta cl
        lda clrh,x
        sta cl+1
        txa                         ; the half: 4 on bottoms rows (row even), 0 on tops rows
        and #1
        eor #1
        asl a
        asl a
        sta sthalf
        asl a
        asl a
        asl a
        asl a
        asl a
        sta hb80
        lda stx0                    ; its columns (x / 8: the level's under 2048 pixels)
        sta tmp
        lda stx0+1
        ldx #3
-       lsr a
        ror tmp
        dex
        bne -
        lda tmp
        sta stc0
        lda stx1
        sta tmp
        lda stx1+1
        ldx #3
-       lsr a
        ror tmp
        dex
        bne -
        lda tmp
        sta stc1
        cmp leftc                   ; (in view at all?)
        bcc strx
        lda leftc
        clc
        adc #40
        cmp stc0
        bcc strx
        lda stx0                    ; the end cells' masks: from x0's pixel, to x1's
        and #7
        tax
        lda rmask,x
        sta stm0
        lda stx1
        and #7
        tax
        lda lmask,x
        sta stm1
        lda stc0                    ; clipped to the view (a whole cell where it's cut)
        cmp leftc
        bcs +
        lda leftc
        sta stc0
        lda #$ff
        sta stm0
+       lda leftc
        clc
        adc #40
        cmp stc1
        bcs +
        sta stc1
        lda #$ff
        sta stm1
+       lda stc1
        sec
        sbc leftc
        sta stse
        lda stc0
        sec
        sbc leftc
        sta stsc
        sta stfst
stlp    lda #$ff
        ldy stsc
        cpy stfst
        bne +
        and stm0
+       cpy stse
        bne +
        and stm1
+       jsr stcell
        lda stsc
        cmp stse
        beq strx
        inc stsc
        bne stlp
strx    rts
rmask   .byte $ff, $7f, $3f, $1f, $0f, $07, $03, $01
lmask   .byte $80, $c0, $e0, $f0, $f8, $fc, $fe, $ff

stfl    rts                         ; (no spare character left: not drawn)

; mask a ORed into line stln of the cell at column y in view (its spare character's half)
stcell  sta stmk
        lda (cl),y
        beq stnew
        jsr stcp                    ; (claimed: on from what's there)
        jmp stor
stnew   ldx sthalf                  ; a spare character's half (none left: not drawn)
        bne +
        lda ntop
        cmp #NPOOL
        bcs stfl
        inc ntop
        bcc ++
+       lda nbot
        cmp #NPOOL
        bcs stfl
        inc nbot
+       adc #POOL0                  ; (carry clear)
        sta code
        sta (cl),y                  ; claimed
        jsr stcp
        lda (mp),y                  ; started from the level's glyph there (FONTA's): as plot finds
        cmp #POOL0                  ; it
        bcc st1
        ora hb80
        tax
origp2  lda ORIGA,x
st1     ldx prf
        beq st2
        jsr pkorig
st2     sta orig
        lda code
        ora hb80
        tax
        lda orig
origc2  sta ORIGB,x
        sta sp
        lda #0
        asl sp
        rol a
        asl sp
        rol a
        asl sp
        rol a
        adc #>FONTA                 ; (carry clear)
        sta sp+1
        lda sp
        ora sthalf
        sta sp
        sty stsc2
        ldy #3
-       lda (sp),y
        sta (cp),y
        dey
        bpl -
        ldx ncell                   ; its claim, to clear
        lda stsc2
        clc
        adc cl
        sta cl_lo,x
        lda cl+1
        adc #0
        sta cl_hi,x
        lda stsc2                   ; the programs' entries: the code / the level's code, the cell
        clc
        adc mp
        ldy #3
        sta (wp),y
        sta (rp),y
        iny
        lda mp+1
        sta (wp),y
        sta (rp),y
        ldy #1
        lda code
        sta (wp),y
        lda orig
        sta (rp),y
        lda wp
        clc
        adc #5
        sta wp
        sta rp
        bcc +
        inc wp+1
        inc rp+1
+       inc ncell
stor    ldy stln
        lda (cp),y
        ora stmk
        sta (cp),y
stfull  rts
stcp    pha                         ; cp = code a's half in the set not shown
        lsr a
        lsr a
        lsr a
        lsr a
        lsr a
        clc
        adc bfhi
        sta cp+1
        pla
        asl a
        asl a
        asl a
        ora sthalf
        sta cp
        rts
prow    .byte 0                     ; (plot's and strline's: the row, whether a patch changes cells
prf     .byte 0                     ;  in it, $80 on bottoms rows)
hb80    .byte 0
ofr     .byte 0                     ; (which table of what's under spare characters is this frame's)
stx0    .word 0                     ; (the string)
stx1    .word 0
stry     .byte 0
stln    .byte 0
sthalf  .byte 0
stc0    .byte 0
stc1    .byte 0
stm0    .byte 0
stm1    .byte 0
stsc    .byte 0
stse    .byte 0
stfst   .byte 0
stmk    .byte 0
stsc2   .byte 0

; ---- addobj: the thing pg at px, pd listed for this frame
addobj  lda nob
        cmp #NOBJ
        bcs +
        clc
        adc obi
        tax
        lda pg
        sta OB_G,x
        lda px
        sta OB_XL,x
        lda px+1
        sta OB_XH,x
        lda pd
        sta OB_D,x
        lda #2
        sta OB_LV,x
        lda #$ff
        sta OB_PA,x
        sta OB_PB,x
        inc nob
+       rts

; ---- mux: hardware sprites given out for this frame's things
; Each thing's lines on the screen (oT-oB, display line + 32: the players' memory's lines), its
; band start (oBS), its player position (oHP) and whether it's wholly on the screen across (oIn);
; the things put in order down (order). Then, in this order: Trogg's infill; the Scrubblies'; a
; band of Trogg's on down for his outline; the balloons and daggers (see the top of the file).
mux     lda #0
        sta ivn
        sta ivn+1
        sta ivn+2
        sta ivn+3
        lda #255
        sta hwl
        lda #0
        sta cfix
        lda pmshow                  ; the set being made: its bands' masks and writes clear
        eor #1
        sta mset
        tax
        lda #0
-       sta BT_M,x
        sta BT_W,x
        inx
        inx
        cpx #(NROWS / 2 + 1) * 2
        bcc -
        lda nscrx                   ; 2 * the scroll: the screen's left in level pixels
        asl a
        sta mdst
        lda #0
        rol a
        sta mdst+1
        ldx #0
mxinit  cpx nob
        bcc +
        jmp mxsort
+       stx mk
        txa
        clc
        adc obi
        tay
        lda OB_G,y                  ; its height and width (a Scrubbly's infill's)
        tax
        cpx #GR_SCRUB
        bcc +
        lda #SCR_H
        cpx #GR_KEY
        bne kh
        lda #KEY_H
kh      sta stmp
        lda #32
        bne ++
+       lda gr_h,x
        sta stmp
        lda gr_w,x
+       sta mcnt
        lda OB_D,y                  ; its top, clipped to the screen's (TOPL)
        cmp #TOPL
        bcs +
        lda #TOPL
+       sta mp2
        lda OB_D,y                  ; its bottom, clipped to the screen's (LASTL)
        clc
        adc stmp
        bcs mxbig
        sbc #0                      ; (carry clear: - 1)
        cmp #LASTL + 1
        bcc +
mxbig   lda #LASTL
+       ldx mk
        sta oB,x
        lda mp2
        sta oT,x
        jsr bstart                  ; its band's start
        sta oBS,x
        lda #0                      ; wholly on the screen across? (and seen at all)
        sta oIn,x
        lda oT,x
        cmp oB,x
        beq +
        bcs mxnext                  ; (not on the screen's lines)
+       lda OB_XL,y                 ; its x on the screen: x - 2 * scroll
        sec
        sbc mdst
        sta msrc
        lda OB_XH,y
        sbc mdst+1
        bmi mxnext                  ; (off the left)
        sta msrc+1
        lda #<320                   ; on the screen if x <= 320 - its width
        sec
        sbc mcnt
        sta mlast
        lda #>320
        sbc #0
        cmp msrc+1
        bcc mxnext
        bne +
        lda mlast
        cmp msrc
        bcc mxnext
+       lda msrc+1                  ; its player position: 48 + x / 2
        lsr a
        lda msrc
        ror a
        clc
        adc #48
        sta oHP,x
        lda #1
        sta oIn,x
mxnext  inx
        jmp mxinit

bstart  cmp #BAND0                  ; the band holding at line a: its start (TOPL above BAND0,
        bcs +                       ; else BAND0 + 8k)
        lda #TOPL
        rts
+       sec
        sbc #BAND0
        and #$f8
        clc
        adc #BAND0
        rts

mxsort  ldx #0                      ; in order down: an insertion sort by top
-       cpx nob
        bcs +
        txa
        sta order,x
        inx
        bne -
+       ldx #1
srt1    cpx nob
        bcs srtd
        lda order,x
        sta mk                      ; (the thing being placed, its top)
        tay
        lda oT,y
        sta mp2
        stx mlast
        txa
        tay                         ; y: where it goes
srt2    cpy #0
        beq srt3
        ldx order-1,y
        lda oT,x
        cmp mp2
        bcc srt3
        beq srt3
        txa
        sta order,y
        dey
        bne srt2
srt3    lda mk
        sta order,y
        ldx mlast
        inx
        bne srt1
srtd    lda nob
        bne +
        rts
+       lda oIn                     ; 1. Trogg's infill: P0 and P1
        beq mxscr
        lda #0
        sta mk
        sta mp2
        lda #1
        sta msize
        jsr chooseb                 ; (his band: P0 3, P1 2; nothing's on them yet)
        lda #0
        jsr reserve
        lda #1
        jsr reserve
        ldy obi
        lda #1
        sta OB_LV,y
        lda #0
        sta OB_PA,y
        lda #1
        sta OB_PB,y

mxscr   ldx #0                      ; 2. the Scrubblies, in order down: a double-width player each
mxs     cpx nob
        bcs mxs2
        stx midx
        jsr scrthing
        bcs mxsn
        lda #3                      ; P3, else P1, else P0
        jsr one
        bcc +
        lda #1
        jsr one
        bcc +
        lda #0
        jsr one
        bcs mxsn
+       ldy mcnt
        sta OB_PB,y
        lda #1
        sta OB_LV,y
mxsn    ldx midx
        inx
        bne mxs
mxs2    ldx #0                      ; then a second player (normal width, both) where one's free
mxt     cpx nob
        bcs mxtrog
        stx midx
        jsr scrthing
        bcs mxtn
        ldy mcnt
        lda OB_LV,y
        cmp #1
        bne mxtn
        ldx #2                      ; the others of P3, P1, P0
-       lda scrp,x
        ldy mcnt
        cmp OB_PB,y
        beq ++
        stx uidx
        ldy #1                      ; (in the band it has: its first player's set there)
        sty cfix
        jsr one
        ldy #0
        sty cfix
        bcs +
        ldy mcnt                    ; (the first the left, this the right)
        sta OB_PA,y
        lda OB_PA,y
        pha
        lda OB_PB,y
        sta OB_PA,y
        pla
        sta OB_PB,y
        lda #0
        sta OB_LV,y
        beq mxtn
+       ldx uidx
+       dex
        bpl -
mxtn    ldx midx
        inx
        bne mxt
scrp    .byte 3, 1, 0

scrthing lda order,x                ; the thing x down: mk, its record mcnt; carry clear if it's a
        sta mk                      ; Scrubbly wholly on the screen across
        tay
        lda oIn,y
        beq +
        tya
        clc
        adc obi
        sta mcnt
        tay
        lda OB_G,y
        cmp #GR_SCRUB
        bne +
        clc
        rts
+       sec
        rts

mxtrog
      .if !HWOUT
        jmp mxhaz
      .endif
        lda oIn                     ; 3. Trogg's outline on P2 and P3 from a band of his on down
        beq mxhaz                   ; (not his first: its writes are P0's and P1's)
        lda oT
        jsr bstart
        clc
        adc #8                      ; (his second band's start)
-       cmp oB
        beq +
        bcs mxhaz                   ; (none of his bands left)
+       sta oT + 15                 ; (thing 15: those lines of his)
        sta oBS + 15
        sta mp2
        lda oB
        sta oB + 15
        lda #15
        sta mk
        lda #2
        jsr free
        bcs +
        lda #3
        jsr free
        bcs +
        ldx #15                     ; (writes: P2 1, P3 3)
        jsr tband
        lda BT_W,y
        clc
        adc #4
        cmp #WMAX + 1
        bcs +
        sta BT_W,y
        lda #2
        jsr reserve
        lda #3
        jsr reserve
        lda mp2
        sta hwl
        jmp mxhaz
+       lda mp2                     ; the next band of his
        clc
        adc #8
        bcc -

mxhaz   ldx #0                      ; 4. the balloons and daggers, in order down
mxh     cpx nob
        bcs mxkey
        stx midx
        lda order,x
        beq mxhn                    ; (Trogg: done)
        sta mk
        tay
        lda oIn,y
        beq mxhn
        tya
        clc
        adc obi
        sta mcnt                    ; (its record)
        tay
        ldx OB_G,y
        cpx #GR_SCRUB
        bcs mxhn
        lda gp_ok,x
        beq mxhn
        cpx #GR_BALLOON
        bne mxdag
      .if HWOUT
        lda #0                      ; a balloon: a pair, outline and infill (P0 and P1, P2 and P3)
        ldx #1
        jsr pair2
        bcc mxhn
        lda #2
        ldx #3
        jsr pair2
        bcc mxhn
      .endif
        lda #3                      ; or a player for its infill: P3, else P1, else P0
        jsr one
        bcc +
        lda #1
        jsr one
        bcc +
        lda #0
        jsr one
        bcs mxhn
+       ldy mcnt
        sta OB_PB,y
        lda #1
        sta OB_LV,y
        bne mxhn
mxdag
      .if !HWOUT
        jmp mxhn                    ; (a dagger: software)
      .endif
        lda #2                      ; a dagger: a player for its outline: P2, else P0
        jsr one
        bcc +
        lda #0
        jsr one
        bcs mxhn
+       ldy mcnt
        sta OB_PA,y
        lda #0
        sta OB_LV,y
mxhn    ldx midx
        inx
        bne mxh
mxkey   ldx #0                      ; 5. the keys, in order down: a double-width player each, P3
mxk     cpx nob                     ; else P0 (yellow; two normal-width players, P0 and P3, would
        bcs mxend                   ; be 6 writes in a band, over its 5)
        stx midx
        lda order,x
        sta mk
        tay
        lda oIn,y
        beq mxkn
        tya
        clc
        adc obi
        sta mcnt
        tay
        lda OB_G,y
        cmp #GR_KEY
        bne mxkn
        lda #3
        jsr one
        bcc +
        lda #0
        jsr one
        bcs mxkn
+       ldy mcnt
        sta OB_PB,y
        lda #1
        sta OB_LV,y
mxkn    ldx midx
        inx
        bne mxk
mxend   lda hwl                     ; (Trogg's record: his outline's line)
        pha
        lda obi
        lsr a
        lsr a
        lsr a
        lsr a
        tax
        pla
        sta OB_HW,x
        rts

pair2   sta mp2                     ; players a and x for thing mk (record mcnt), if both free and
        stx mlast+0                 ; its band has room for their writes: carry clear if so
        stx msize                   ; (msize: the second)
        jsr free
        bcs ++
        lda msize
        jsr free
        bcs ++
        jsr chooseb
        bcs ++
        lda mp2
        jsr reserve
        ldy mcnt
        sta OB_PA,y
        lda msize
        jsr reserve
        ldy mcnt
        sta OB_PB,y
        lda #0
        sta OB_LV,y
        clc
+
+       rts

one     sta mp2                     ; player a for thing mk, if free and a band has room for the
        jsr free                    ; writes: carry clear if so (a kept)
        bcs +
        lda #$ff
        sta msize
        jsr chooseb
        bcs +
        lda mp2
        jsr reserve
        clc
        rts
+       lda mp2
        sec
        rts
wcost   .byte 3, 2, 1, 3            ; register writes for a player's change (position; P0's colour
                                    ; and width, P1's width, P3's colour and width)

tband   lda oT,x                    ; y: the band holding at thing x's top (this set's index)
        jsr bidx
        tay
        rts

; chooseb: the band for thing mk's registers on player mp2 (and msize, unless $ff): the latest from
; its top's band up, after the things above it on those players (4 lines after their bottoms),
; with room for the writes (the VBI's, line TOPL, always has room). Carry clear if one: oWB and
; oBS the band's line, its writes counted
chooseb ldx mk
        lda #TOPL                   ; mlast: the earliest line it can be
        sta mlast
        lda mp2
        jsr above
        lda msize
        bmi +
        jsr above
+       ldy mp2                     ; cnum: the writes
        lda wcost,y
        ldy msize
        bmi +
        clc
        adc wcost,y
+       sta cnum
        lda oBS,x
cblp    cmp mlast
        bcc cbno
        ldy cfix                    ; (keeping its band: that one or none)
        beq +
        cmp oBS,x
        bne cbno
+
        cmp #BAND0
        bcc cbyes                   ; (the VBI's: always room)
        pha
        jsr bidx
        tay
        lda BT_W,y
        clc
        adc cnum
        cmp #WMAX + 1
        bcs +
        sta BT_W,y
        pla
        jmp cbyes
+       pla
        sec                         ; the band before
        sbc #8
        cmp #BAND0
        bcs cblp
        lda #TOPL
        bcc cblp
cbyes   sta oWB,x
        sta oBS,x
        clc
        rts
cbno    sec
        rts

above   stx stmp                    ; mlast raised to 4 past the bottoms of things on player a above
        tay                         ; thing x (x kept)
        lda ivn,y
        beq abend
        sta mdst
        tya
        asl a
        asl a
        asl a
        asl a
        tay
-       lda iv_B,y
        cmp oT,x
        bcs +                       ; (not above)
        clc
        adc #4
        cmp mlast
        bcc +
        sta mlast
+       iny
        dec mdst
        bne -
abend   ldx stmp
        rts

free    stx stmp                    ; player a free for thing mk? carry clear if so (x kept)
        pha
        tay
        lda ivn,y
        beq frok
        sta mdst                    ; (the count; mdst is free here)
        pla
        pha
        asl a
        asl a
        asl a
        asl a
        tay
        ldx mk
-       lda iv_B,y                  ; ok if the other ends 4 lines before this one's band,
        clc
        adc #4
        cmp oBS,x
        beq +
        bcc +
        lda oB,x                    ; or this one ends 4 lines before the other's band
        clc
        adc #4
        cmp iv_BS,y
        beq +
        bcc +
        pla
        ldx stmp
        sec
        rts
+       iny
        dec mdst
        bne -
frok    pla
        ldx stmp
        clc
        rts

reserve pha                         ; player a to thing mk (a kept)
        tay
        lda ivn,y
        sta mlast
        clc
        adc #1
        sta ivn,y
        tya
        asl a
        asl a
        asl a
        asl a
        adc mlast
        tay
        ldx mk
        lda oT,x
        sta iv_T,y
        lda oB,x
        sta iv_B,y
        lda oBS,x
        sta iv_BS,y
        pla
        rts

; ---- pmdraw: the hardware sprites' graphics (into the set not shown: the strips written there
; two frames ago cleared first) and the bands' registers, the things in order down
pmdraw  ldx mset
        lda pc_cnt,x
        beq pmcd
        sta mlast
        txa
        asl a
        asl a
        asl a
        asl a
        asl a
        tax
-       lda pc_lo,x
        sta mdst
        lda pc_hi,x
        sta mdst+1
        ldy pc_n,x
        dey
        lda #0
-       sta (mdst),y
        dey
        bpl -
        inx
        dec mlast
        bne --
pmcd    jsr keepclr                 ; the Scrubblies' and Trogg's: only what's changed
        ldx mset
        lda #0
        sta pc_cnt,x
        sta midx
        lda obi                     ; (the missiles off the screen unless Trogg's on it)
        lsr a
        lsr a
        lsr a
        lsr a
        tax
        lda #0
        sta OB_M0,x
        sta OB_M1,x
pmlp    ldx midx
        cpx nob
        bcc +
        rts
+       lda order,x
        sta mk
        clc
        adc obi
        sta mcnt
        tay
        lda OB_LV,y
        cmp #2
        bcs pmnext
        lda OB_G,y
        cmp #GR_KEY
        bne +
        jsr pmkey
        jmp pmnext
+       cmp #GR_SCRUB
        bne +
        jsr pmscr
        lda #0
        sta norec
        sta nocopy
        jmp pmnext
+       lda mk
        bne +
        lda #1                      ; (Trogg's infill's strips kept apart: their old lines
        sta norec                   ; cleared by keepclr)
        jsr pmtrog
        lda #0
        sta norec
        jmp pmnext
+       lda OB_PA,y                 ; a balloon's or dagger's outline (black)
        bmi +
        sta mp2
        ldx OB_G,y
        lda gp_a_lo,x
        sta msrc
        lda gp_a_hi,x
        sta msrc+1
        lda #0
        sta moff
        sta msize
        lda #COL_BLK
        sta mcol
        jsr pstrip
+       ldy mcnt                    ; its infill (magenta)
        lda OB_PB,y
        bmi pmnext
        sta mp2
        ldx OB_G,y
        lda gp_b_lo,x
        sta msrc
        lda gp_b_hi,x
        sta msrc+1
        lda #0
        sta moff
        sta msize
        lda #COL_MAG
        sta mcol
        jsr pstrip
pmnext  inc midx
        jmp pmlp
pmhi    .byte >PMG0, >PMG1

pmkey   lda OB_PB,y                 ; a key: its yellow, double width
        sta mp2
        lda #<key_d
        sta msrc
        lda #>key_d
        sta msrc+1
        lda #KEY_DX / 2
        sta moff
        lda #1
        sta msize
        lda #COL_YEL
        sta mcol
        jmp pstrip

pmscr   ldx mk                      ; a Scrubbly: two players, or one double-width (its strips kept
        lda scrw - 1,x              ; apart, written only if they've changed in this set: else only
        eor #1                      ; its registers)
        sta nocopy
        lda #1
        sta norec
        lda OB_LV,y
        bne +
        lda OB_PA,y                 ; (the left)
        sta mp2
        lda #<scr_l
        sta msrc
        lda #>scr_l
        sta msrc+1
        lda #0
        sta moff
        sta msize
        lda #COL_MAG
        sta mcol
        jsr pstrip
        ldy mcnt                    ; (the right, 16 pixels on)
        lda OB_PB,y
        sta mp2
        lda #<scr_r
        sta msrc
        lda #>scr_r
        sta msrc+1
        lda #8
        sta moff
        jmp pstrip
+       lda OB_PB,y
        sta mp2
        lda #<scr_d
        sta msrc
        lda #>scr_d
        sta msrc+1
        lda #SCR_DX / 2
        sta moff
        lda #1
        sta msize
        lda #COL_MAG
        sta mcol
        jmp pstrip

pmtrog  ldx OB_G,y                  ; Trogg: his infill, P0 yellow and P1 magenta (holed from his
        stx tgr                     ; outline's line on), the missiles; his outline on P2 and P3
        lda #0                      ; from that line
        sta mp2
        sta msize
        lda gp_a_lo,x
        sta msrc
        lda gp_a_hi,x
        sta msrc+1
      .if HWOUT
        lda go_ah_lo,x
        sta hsrc
        lda go_ah_hi,x
        sta hsrc+1
      .endif
        lda gp_ax,x
        sta moff
        lda #COL_YEL
        sta mcol
        jsr pstrip2
        ldx tgr
        lda #1
        sta mp2
        lda gp_b_lo,x
        sta msrc
        lda gp_b_hi,x
        sta msrc+1
      .if HWOUT
        lda go_bh_lo,x
        sta hsrc
        lda go_bh_hi,x
        sta hsrc+1
      .endif
        lda gp_bx,x
        sta moff
        lda #COL_MAG
        sta mcol
        jsr pstrip2
        ldx tgr                     ; the missiles: their strip, their positions in the record
        lda gp_m_lo,x
        sta msrc
        lda gp_m_hi,x
        sta msrc+1
      .if HWOUT
        lda go_mh_lo,x
        sta hsrc
        lda go_mh_hi,x
        sta hsrc+1
      .endif
        lda #$ff                    ; (no player: the missiles' memory)
        sta mp2
        jsr pstrip2
        ldx tgr
        lda obi
        lsr a
        lsr a
        lsr a
        lsr a
        tay
        lda oHP
        clc
        adc gp_max,x
        sta OB_M0,y
        lda oHP
        clc
        adc gp_mbx,x
        sta OB_M1,y
      .if HWOUT
        lda hwl                     ; his outline on P2 (left 16) and P3 (right 16)
        cmp #255
        beq +
        lda #0                      ; (his outline's strips listed as usual)
        sta norec
        lda #2
        sta mp2
        lda go_l_lo,x
        sta msrc
        lda go_l_hi,x
        sta msrc+1
        lda #0
        sta moff
        sta msize
        lda #COL_BLK
        sta mcol
        jsr hwstrip
        ldx tgr
        lda #3
        sta mp2
        lda go_r_lo,x
        sta msrc
        lda go_r_hi,x
        sta msrc+1
        lda #8
        sta moff
        jsr hwstrip
+
      .endif
        rts

; a strip of thing mk's graphic (msrc) on player mp2, from its top line on the screen; in the band
; holding at its top, the player's position (oHP + moff), colour (mcol), width (msize), its bit
pstrip  ldy mcnt
        ldx mk
        lda oT,x                    ; (lines above the screen skipped)
        sec
        sbc OB_D,y
        clc
        adc msrc
        sta msrc
        bcc +
        inc msrc+1
+       lda oT,x
        jsr pdest
        jsr strip
        lda oWB,x
regs    jsr bidx                    ; (the band holding at line a)
        sta mdst
        ldy mp2
        lda pbit,y
        ldy mdst
        ora BT_M,y
        sta BT_M,y
        lda mp2                     ; (each register's table: 64 bytes)
        lsr a
        ror a
        ror a
        ora mdst                    ; (p * 64 + the band)
        tay
        lda oHP,x
        clc
        adc moff
        sta BT_HP,y
        lda mcol
        sta BT_C,y
        lda msize
        sta BT_S,y
        rts
pbit    .byte 1, 2, 4, 8

; Trogg's infill's strip on player mp2 (or the missiles, $ff): msrc from his top, and from his
; outline's line on (hwl) the holed graphic (mlast, midx: low and high); his band's registers
pstrip2 ldy obi                     ; (his record)
        lda oT                      ; (lines above the screen skipped)
        sec
        sbc OB_D,y
        clc
        adc msrc
        sta msrc
        bcc +
        inc msrc+1
+       lda oT
        jsr pdest
        ldx #0
        jsr strip
        lda hwl                     ; the holed lines over them, from hwl
        cmp #255
        beq +
        ldy obi
        sec
        sbc OB_D,y                  ; (hwl - his top: the graphic's line)
        clc
        adc hsrc
        sta msrc
        lda hsrc+1
        adc #0
        sta msrc+1
        lda hwl
        sta oT + 15                 ; (thing 15: those lines)
        jsr pdest
        lda oB
        sta oB + 15
        ldx #15
        jsr strip
+       lda mp2
        bmi +
        ldx #0
        lda oWB
        jmp regs
+       rts

; Trogg's outline's strip on player mp2 (msrc: from his top): from his outline's line (hwl) to his
; bottom, and its band's registers
hwstrip ldy mcnt
        lda hwl
        sec
        sbc OB_D,y
        clc
        adc msrc
        sta msrc
        bcc +
        inc msrc+1
+       lda hwl
        sta oT + 15
        jsr pdest
        lda oB
        sta oB + 15
        ldx #15
        jsr strip
        lda hwl
        ldx #0
        jmp regs

; mdst: line a of player mp2's memory in the set being made (mp2 $ff: the missiles')
pdest   sta mdst
        lda mp2
        clc
        adc #4                      ; (players at + $400, missiles at + $300: $ff + 4 = 3)
        ldy mset
        clc
        adc pmhi,y
        sta mdst+1
        rts

; copy thing x's lines from msrc to mdst, and list the strip for clearing (x kept)
strip   lda norec                   ; (kept apart: not listed for clearing)
        bne strnr
        ldy mset
        lda pc_cnt,y
        sta snum
        clc
        adc #1
        sta pc_cnt,y
        tya
        asl a
        asl a
        asl a
        asl a
        asl a
        adc snum
        tay
        lda mdst
        sta pc_lo,y
        lda mdst+1
        sta pc_hi,y
        lda oB,x
        sec
        sbc oT,x
        clc
        adc #1
        sta pc_n,y
strnr   lda nocopy                  ; (there already: not copied)
        beq +
        rts
+       lda oB,x
        sec
        sbc oT,x                    ; (lines - 1)
        tay
-       lda (msrc),y
        sta (mdst),y
        dey
        bpl -
        rts

; keepclr: the strips kept apart, in the set being made. Each Scrubbly's this frame (its key:
; lv | pa << 2 | pb << 4, or 255 for none) against that set's: if they differ, the old strips
; cleared and the new to be written (scrw), else left as they are. Trogg's infill's: of the
; lines his strips had in that set, those his new ones don't cover cleared (P0, P1, missiles).
keepclr ldx #0
kcs     cpx #SCR_N
        bcc +
        jmp kctr
+       stx stmp
        txa
        sec                         ; (its record: thing s + 1)
        adc obi
        tay
        lda #255
        sta mlast
        lda OB_LV,y
        cmp #2
        bcs ++
        lda OB_PB,y
        asl a
        asl a
        asl a
        asl a
        ora OB_LV,y
        sta mlast
        lda OB_LV,y
        bne ++
        lda OB_PA,y
        asl a
        asl a
        ora mlast
        sta mlast
+
+       lda mset
        asl a
        asl a
        asl a
        ora stmp
        tax
        lda scrk,x
        ldy stmp
        cmp mlast
        bne +
        lda #0                      ; (the same: left)
        sta scrw,y
        beq kcn
+       sta sold
        lda mlast
        sta scrk,x
        lda #1
        sta scrw,y
        lda sold                    ; the old strips cleared
        cmp #255
        beq kcn
        ldx stmp                    ; (its lines: thing s + 1's)
        inx
        lda oT,x
        sta mk2
        lda oB,x
        sta mk3
        lda sold
        lsr a
        lsr a
        lsr a
        lsr a
        and #3
        jsr zplayer                 ; (pb)
        lda sold
        and #3
        bne kcn                     ; (one double-width: done)
        lda sold
        lsr a
        lsr a
        and #3
        jsr zplayer                 ; (pa)
kcn     ldx stmp
        inx
        jmp kcs

kctr    lda #0                      ; Trogg: his new lines (none: 0 and 0)
        sta mk3
        sta mk4
        ldy obi
        lda nob
        beq +
        lda OB_LV,y
        cmp #1
        bne +
        lda oT
        sta mk3
        lda oB
        sta mk4
+       ldx mset
        lda trT,x
        beq kcdone                  ; (none there)
        sta mk2                     ; the old lines above his new top (or all, if none)
        lda trB,x
        sta sold
        lda mk3
        beq +
        sec
        sbc #1
        cmp sold
        bcc ++
+       lda sold
+       sta mk5                     ; (old top to min(old bottom, new top - 1))
        jsr zrange
        lda mk4                     ; and below his new bottom
        beq kcdone
        clc
        adc #1
        cmp mk2
        bcs +
        lda mk2
+       sta mk2                     ; (max(old top, new bottom + 1) to old bottom)
        lda sold
        sta mk5
        jsr zrange
kcdone  ldx mset
        lda mk3
        sta trT,x
        lda mk4
        sta trB,x
        rts

zrange  lda mk2                     ; lines mk2-mk5 cleared in P0, P1 and the missiles (if any)
        cmp mk5
        beq +
        bcs ++
+       lda mk5
        sta mk3s
        lda #0
        jsr zp1
        lda #1
        jsr zp1
        lda #$ff
        jsr zp1
+       rts
zp1     sta mp2
        jsr zbase
        lda mk3s
        sec
        sbc mk2
        tay
        lda #0
-       sta (mdst),y
        dey
        cpy #$ff
        bne -
        rts

zplayer sta mp2                     ; player a's lines mk2-mk3 cleared (a Scrubbly's old strip)
        jsr zbase
        lda mk3
        sec
        sbc mk2
        tay
        lda #0
-       sta (mdst),y
        dey
        cpy #$ff
        bne -
        rts

zbase   lda mk2                     ; mdst: line mk2 of player mp2's memory ($ff: the missiles')
        sta mdst
        lda mp2
        clc
        adc #4
        ldy mset
        clc
        adc pmhi,y
        sta mdst+1
        rts

bidx    cmp #BAND0                  ; the band holding at line a: its index in this set's tables
        bcs +
        lda mset
        rts
+       sec
        sbc #BAND0
        lsr a
        lsr a
        and #$fe
        clc
        adc #2
        adc mset
        rts



; ---- plot: graphic pg at top left (px: level pixels, even, signed; pd: its scanline),
; drawn into the spare characters of the set not shown (bfhi), clipped to the screen's rows
; and the columns in view (leftc on)
plot    ldx pg
        lda gr_h,x
        sta ht
        clc
        adc #6
        sta cstep
        lda px                      ; the shift: (px / 2) & 3
        lsr a
        and #3
        sta si
        lda px+1                    ; its first column (px / 8, signed) less leftc
        sta tmp+1
        lda px
        sta tmp
        ldy #3
-       lda tmp+1
        cmp #$80                    ; (the sign into the carry, shifted in)
        ror tmp+1
        ror tmp
        dey
        bne -
        lda tmp
        sec
        sbc leftc
        sta scol0
        lda tmp+1
        sbc #0
        beq +                       ; 0 to 255 columns on: in view if 40 or fewer
        cmp #$ff
        bne plotx                   ; far off: not drawn
        lda scol0                   ; to the left: in view if its 4 columns can reach
        cmp #$fc
        bcs ++
plotx   rts
+       lda scol0
        cmp #41
        bcs plotx
+       txa                         ; the graphic at this shift: graphic * 4 + shift
        asl a
        asl a
        ora si
        tax
        lda tg_nb,x
        sta nb
        sec
        sbc #1
        sta lastj
        lda pd                      ; the side columns' empty cells for its phase (pd & 3): the
        and #3                      ; tables' blocks of 128 (tmp: the block's offset), by x
        lsr a
        sta tmp+1
        lda #0
        ror a
        sta tmp
        txa
        ora tmp
        tay
        lda tmp+1
        clc
        adc #>tel_lo
        sta tmsk+2
        adc #>(ter_lo - tel_lo)
        sta tmsk3+2
        lda tmp+1
        clc
        adc #>tel_hi
        sta tmsk2+2
        adc #>(ter_hi - tel_hi)
        sta tmsk4+2
tmsk    lda tel_lo & $ff00,y
        sta eml
tmsk2   lda tel_hi & $ff00,y
        sta eml+1
tmsk3   lda ter_lo & $ff00,y
        sta emr
tmsk4   lda ter_hi & $ff00,y
        sta emr+1
        lda tg_lo,x
        sta dptr
        lda tg_hi,x
        sta dptr+1
        lda #>andtab                ; the shift's tables, in the drawing's 4 lines
        clc
        adc si
        sta and0+2
        sta and1+2
        sta and2+2
        sta and3+2
        lda #>ortab
        clc
        adc si
        sta or0+2
        sta or1+2
        sta or2+2
        sta or3+2
        sta orb0+2
        sta orb1+2
        sta orb2+2
        sta orb3+2
        lda pd                      ; its rows, + TOPL / 4: pd / 4 to (pd + ht - 1) / 4
        lsr a
        lsr a
        sta rq
        lda pd
        clc
        adc ht
        bcs +                       ; (past 255: the rows to the bottom, clipped below)
        sbc #0                      ; (carry clear: - 1)
        lsr a
        lsr a
        sta rqlast
        jmp rowlp
+       lda #63
        sta rqlast
rowlp   lda #0                      ; this row's side cells: empty?
        lsr emr+1
        ror emr
        rol a
        lsr eml+1
        ror eml
        rol a
        sta eb                      ; (bit 0 the left, bit 1 the right)
        lda rq                      ; rows above the screen skipped, below it the end
        cmp #TOPL / 4
        bcs +
        jmp rownext
+       cmp #TOPL / 4 + NROWS
        bcc +
        rts
+       cmp rqmax                   ; (and from the row limit on)
        bcc +
        rts
+       asl a                       ; dp = column 0 at the row's first line: dptr + rq * 4 - pd
        asl a                       ; (-3 to its height: within the padding)
        sec
        sbc pd
        ldx #0
        cmp #$80
        bcc +
        dex
+       clc
        adc dptr
        sta dp
        txa
        adc dptr+1
        sta dp+1
        lda rq                      ; the row: rq - TOPL / 4
        sec
        sbc #TOPL / 4
        pha
        lsr a                       ; the maps: row * 128 + 4 + leftc
        tax
        lda #0
        ror a
        sta half                    ; ($80 on tops rows, for now)
        ora #4
        clc
        adc leftc
        sta mp
        txa
        clc
        adc #>SCREEN
        sta mp+1
        pla                         ; the claims: CLAIM + row * 42
        tax
        stx prow                    ; (and whether a patch is changing cells in the row: pick.asm)
        lda pprow,x
        sta prf
        lda clrl,x
        sta cl
        lda clrh,x
        sta cl+1
        lda half                    ; half = 4 on bottoms rows (row even), 0 on tops rows
        eor #$80
        lsr a
        lsr a
        lsr a
        lsr a
        lsr a
        sta half
        asl a                       ; (hb80: $80 on bottoms rows, for the tables of what's under
        asl a                       ; each spare character)
        asl a
        asl a
        asl a
        sta hb80
        ldx half                    ; (the characters' offsets with it: glo or glo4)
        lda glht,x
        sta cplo+1
        sta splo+1
        sta clmlo+1
        lda #0
        sta jj
        lda scol0
        sta scol
celllp  lda scol                    ; columns left of the view skipped, right of it the end
        bpl +
        jmp next
+
        cmp #41
        bcc +
        jmp rownext
+       lda jj                      ; a side column's cell all transparent? (skipped)
        bne +
        lda eb
        lsr a
        bcs ++
        lda jj
+       cmp lastj
        bne ++
        lda eb
        and #2
        beq ++
+       jmp next
+       ldy scol                    ; drawn already this frame?
        lda (cl),y
        beq new
        tax                         ; then on from what's there: sp = cp
clmlo   lda glo,x
        sta cp
        sta sp
clmhi   lda ghiA,x
        sta cp+1
        sta sp+1
        jmp draw4
full    jmp next                    ; (no spare character left: not drawn)
new     ldx half                    ; a spare character's half
        bne +
        lda ntop
        cmp #NPOOL
        bcs full                    ; (none left: not drawn)
        inc ntop
        bcc ++
+       lda nbot
        cmp #NPOOL
        bcs full
        inc nbot
+       adc #POOL0                  ; (carry clear)
        sta code
        sta (cl),y                  ; claimed
        tax                         ; cp = the set not shown + code * 8 + half
cplo    lda glo,x
        sta cp
cphi    lda ghiA,x
        sta cp+1
        lda (mp),y                  ; the level's code there: the screen's map's (the frame shown),
        cmp #POOL0                  ; unless that's a spare character drawn the frame before (what
        bcc pl1                     ; it was over: that frame's table), or a patch is changing it
        ora hb80
        tax
origp   lda ORIGA,x
pl1     ldx prf
        beq pl2
        jsr pkorig
pl2     sta orig
        lda code                    ; (noted for the next frame)
        ora hb80
        tax
        lda orig
origc   sta ORIGB,x
        beq +                       ; sp = the level's glyph there, its half (blank: drawn with OR
        tax                         ; alone, below)
splo    lda glo,x
        sta sp
        lda ghiA,x                  ; (FONTA)
        sta sp+1
+
        ldx ncell                   ; its claim, to clear
        tya
        clc
        adc cl                      ; (a row of claims can cross a page: the carry kept)
        sta cl_lo,x
        lda cl+1
        adc #0
        sta cl_hi,x
        tya                         ; the programs' entries (prefilled lda #, sta abs): the code /
        clc                         ; the level's code, and the cell
        adc mp                      ; (no carry: a row's cells are within its 128)
        ldy #3
        sta (wp),y
        sta (rp),y
        iny
        lda mp+1
        sta (wp),y
        sta (rp),y
        ldy #1
        lda code
        sta (wp),y
        lda orig
        sta (rp),y
        lda wp                      ; the next entries (the low bytes together)
        clc
        adc #5
        sta wp
        sta rp
        bcc +
        inc wp+1
        inc rp+1
+       inc ncell
        lda orig
        bne draw4
orpath
        ldy #0                      ; over blank: OR alone
        lda (dp),y
        tax
orb0    lda ortab,x
        sta (cp),y
        ldy #1                      ; over blank: OR alone
        lda (dp),y
        tax
orb1    lda ortab,x
        sta (cp),y
        ldy #2                      ; over blank: OR alone
        lda (dp),y
        tax
orb2    lda ortab,x
        sta (cp),y
        ldy #3                      ; over blank: OR alone
        lda (dp),y
        tax
orb3    lda ortab,x
        sta (cp),y
        jmp next
draw4
        ldy #0
        lda (dp),y
        tax
        lda (sp),y
and0    and andtab,x
or0     ora ortab,x
        sta (cp),y
        ldy #1
        lda (dp),y
        tax
        lda (sp),y
and1    and andtab,x
or1     ora ortab,x
        sta (cp),y
        ldy #2
        lda (dp),y
        tax
        lda (sp),y
and2    and andtab,x
or2     ora ortab,x
        sta (cp),y
        ldy #3
        lda (dp),y
        tax
        lda (sp),y
and3    and andtab,x
or3     ora ortab,x
        sta (cp),y
next    inc jj                      ; its next column: dp + its height + 6
        inc scol
        lda jj
        cmp nb
        bcs rownext
        lda dp
        clc
        adc cstep
        sta dp
        bcc +
        inc dp+1
+       jmp celllp
rownext lda rq
        cmp rqlast
        inc rq
        bcs +
        jmp rowlp
+       rts

clrl    .for r = 0, r < NROWS, r += 1   ; the claims' rows (CLAIMA, then CLAIMB, then CLAIMC)
        .byte <(r < NCLAIMA ? CLAIMA + r * 42 : r < NCLAIMA + NCLAIMB ? CLAIMB + (r - NCLAIMA) * 42 : CLAIMC + (r - NCLAIMA - NCLAIMB) * 42)
        .endfor
clrh    .for r = 0, r < NROWS, r += 1
        .byte >(r < NCLAIMA ? CLAIMA + r * 42 : r < NCLAIMA + NCLAIMB ? CLAIMB + (r - NCLAIMA) * 42 : CLAIMC + (r - NCLAIMA - NCLAIMB) * 42)
        .endfor
glht    .byte <glo, 0, 0, 0, <glo4  ; (by the half)
ghit_lo .byte <ghiA, <ghiB          ; (by the set not shown: 0 A, 1 B... indexed by front ^ 1)
ghit_hi .byte >ghiA, >ghiB
        .cerror (>glo) != (>glo4), "glo and glo4 must share a page"
        .cerror (>ORIGA) & 1, "ORIGA's page must be even"
        .cerror (<PROGW) | (<PROGR0) | (<PROGR1), "the programs must be page-aligned"

; prefill: the program at page x, 150 entries of lda #0, sta $0000
prefill stx tmp+1
        lda #0
        sta tmp
        ldx #150
-       ldy #0
        lda #$a9
        sta (tmp),y
        iny
        lda #0
        sta (tmp),y
        iny
        lda #$8d
        sta (tmp),y
        iny
        lda #0
        sta (tmp),y
        iny
        sta (tmp),y
        lda tmp
        clc
        adc #5
        sta tmp
        bcc +
        inc tmp+1
+       dex
        bne -
        rts

; ---- NMIs: the row DLIs, and the VBI
nmi     bit NMIST
        sta NMIRES
        bpl vbi
        jmp (dliv)
irq     rti

; ---- The VBI: the frame made shown, all at once
vbi     pha
        txa
        pha
        tya
        pha
        lda #<DLIST                 ; the display list from its start (with 240 lines, ANTIC
        sta DLISTL                  ; reaches line 248, the vertical blank, before fetching its
        lda #>DLIST                 ; JVB: left alone, it would fetch it at the next frame's top
        sta DLISTL+1                ; and wait out that whole frame, blank)
        inc vbcnt                   ; (fields, for the game's ticks)
        lda ready
        sta fresh
        bne vshow
        inc drops                   ; no frame made in time: the same one again
        bne +
        inc drops+1
+       jmp vbiend
vshow   lda rprev                   ; last frame's cells put back, this frame's written
        sta vrun+2
vrun    jsr PROGR0
        jsr PROGW
        jsr PROGP                   ; (and a gem's, key's or Scrubbly's cells: pick.asm)
        lda rprev                   ; this frame's putting back program runs next time
        ldx rcur
        stx rprev
        sta rcur
vset    lda front                   ; the sets swapped
        eor #1
        sta front
        tax
        lda fonthi,x
        sta CHBASE
        lda pvi                     ; the records turned round: the frame made is shown
        ldx shi
        stx pvi
        ldx obi
        stx shi
        sta obi
        lda nscrx
        sta scrx
        lda scrx                    ; the scroll: HSCROL = -x & 3, LMS = row + (x + 3) / 4
        eor #$ff
        clc
        adc #1
        and #3
        sta HSCROL
        lda scrx
        clc
        adc #3
        lsr a
        lsr a
        cmp lastoff                 ; the rows' LMS, when they change
        beq vdone
        sta lastoff
        sta lmsoff
        ldx #0
-       lda lmsoff
        sta dlrows + 1,x
        ora #$80
        sta dlrows + 4,x
        txa
        clc
        adc #6
        tax
        cpx #NROWS * 3
        bne -
vdone   lda pmshow              ; the players' graphics and bands of the frame made
        eor #1
        sta pmshow
        tax
        lda pmhi,x
        sta PMBASE
        lda #0
        sta ready
vbiend  ldx pmshow                  ; the top band's players' registers, every frame
        lda BT_HP,x
        sta HPOSP0
        lda BT_HP + 64,x
        sta HPOSP0 + 1
        lda BT_HP + 128,x
        sta HPOSP0 + 2
        lda BT_HP + 192,x
        sta HPOSP0 + 3
        lda BT_C,x
        sta COLPM0
        lda BT_C + 192,x
        sta COLPM0 + 3
        lda BT_S,x
        sta SIZEP0
        lda BT_S + 64,x
        sta SIZEP0 + 1
        lda BT_S + 192,x
        sta SIZEP0 + 3
        lda shi                     ; the missiles, as the frame shown has them
        lsr a
        lsr a
        lsr a
        lsr a
        tax
        lda OB_M0,x
        sta HPOSM0
        lda OB_M1,x
        sta HPOSM0 + 1
        ldx pmshow
        inx
        inx
        stx bandx
        lda #4
        sta VSCROL
        lda #<dlia
        sta dliv
        lda #>dlia
        sta dliv+1
        pla
        tay
        pla
        tax
        pla
        rti


dlb0
        jmp dlend
dlb1
        lda BT_HP,x
        sta HPOSP0
        lda BT_C,x
        sta COLPM0
        lda BT_S,x
        sta SIZEP0
        jmp dlend
dlb2
        lda BT_HP + 64,x
        sta HPOSP0 + 1
        lda BT_S + 64,x
        sta SIZEP0 + 1
        jmp dlend
dlb3
        lda BT_HP,x
        sta HPOSP0
        lda BT_C,x
        sta COLPM0
        lda BT_S,x
        sta SIZEP0
        lda BT_HP + 64,x
        sta HPOSP0 + 1
        lda BT_S + 64,x
        sta SIZEP0 + 1
        jmp dlend
dlb4
        lda BT_HP + 128,x
        sta HPOSP0 + 2
        jmp dlend
dlb5
        lda BT_HP,x
        sta HPOSP0
        lda BT_C,x
        sta COLPM0
        lda BT_S,x
        sta SIZEP0
        lda BT_HP + 128,x
        sta HPOSP0 + 2
        jmp dlend
dlb6
        lda BT_HP + 64,x
        sta HPOSP0 + 1
        lda BT_S + 64,x
        sta SIZEP0 + 1
        lda BT_HP + 128,x
        sta HPOSP0 + 2
        jmp dlend
dlb7
        lda BT_HP,x
        sta HPOSP0
        lda BT_C,x
        sta COLPM0
        lda BT_S,x
        sta SIZEP0
        lda BT_HP + 64,x
        sta HPOSP0 + 1
        lda BT_S + 64,x
        sta SIZEP0 + 1
        lda BT_HP + 128,x
        sta HPOSP0 + 2
        jmp dlend
dlb8
        lda BT_HP + 192,x
        sta HPOSP0 + 3
        lda BT_C + 192,x
        sta COLPM0 + 3
        lda BT_S + 192,x
        sta SIZEP0 + 3
        jmp dlend
dlb9
        lda BT_HP,x
        sta HPOSP0
        lda BT_C,x
        sta COLPM0
        lda BT_S,x
        sta SIZEP0
        lda BT_HP + 192,x
        sta HPOSP0 + 3
        lda BT_C + 192,x
        sta COLPM0 + 3
        lda BT_S + 192,x
        sta SIZEP0 + 3
        jmp dlend
dlb10
        lda BT_HP + 64,x
        sta HPOSP0 + 1
        lda BT_S + 64,x
        sta SIZEP0 + 1
        lda BT_HP + 192,x
        sta HPOSP0 + 3
        lda BT_C + 192,x
        sta COLPM0 + 3
        lda BT_S + 192,x
        sta SIZEP0 + 3
        jmp dlend
dlb11
        lda BT_HP,x
        sta HPOSP0
        lda BT_C,x
        sta COLPM0
        lda BT_S,x
        sta SIZEP0
        lda BT_HP + 64,x
        sta HPOSP0 + 1
        lda BT_S + 64,x
        sta SIZEP0 + 1
        lda BT_HP + 192,x
        sta HPOSP0 + 3
        lda BT_C + 192,x
        sta COLPM0 + 3
        lda BT_S + 192,x
        sta SIZEP0 + 3
        jmp dlend
dlb12
        lda BT_HP + 128,x
        sta HPOSP0 + 2
        lda BT_HP + 192,x
        sta HPOSP0 + 3
        lda BT_C + 192,x
        sta COLPM0 + 3
        lda BT_S + 192,x
        sta SIZEP0 + 3
        jmp dlend
dlb13
        lda BT_HP,x
        sta HPOSP0
        lda BT_C,x
        sta COLPM0
        lda BT_S,x
        sta SIZEP0
        lda BT_HP + 128,x
        sta HPOSP0 + 2
        lda BT_HP + 192,x
        sta HPOSP0 + 3
        lda BT_C + 192,x
        sta COLPM0 + 3
        lda BT_S + 192,x
        sta SIZEP0 + 3
        jmp dlend
dlb14
        lda BT_HP + 64,x
        sta HPOSP0 + 1
        lda BT_S + 64,x
        sta SIZEP0 + 1
        lda BT_HP + 128,x
        sta HPOSP0 + 2
        lda BT_HP + 192,x
        sta HPOSP0 + 3
        lda BT_C + 192,x
        sta COLPM0 + 3
        lda BT_S + 192,x
        sta SIZEP0 + 3
        jmp dlend
dlb15
        lda BT_HP,x
        sta HPOSP0
        lda BT_C,x
        sta COLPM0
        lda BT_S,x
        sta SIZEP0
        lda BT_HP + 64,x
        sta HPOSP0 + 1
        lda BT_S + 64,x
        sta SIZEP0 + 1
        lda BT_HP + 128,x
        sta HPOSP0 + 2
        lda BT_HP + 192,x
        sta HPOSP0 + 3
        lda BT_C + 192,x
        sta COLPM0 + 3
        lda BT_S + 192,x
        sta SIZEP0 + 3
        jmp dlend

        .include "../build/" .. LEVEL .. "_scrub.inc"   ; the Scrubblies' infill and places
        .include "../build/sprites.inc"
        .include "../build/" .. LEVEL .. "_geom.inc"    ; the platforms and ladders (geom.py)
        .include "../build/" .. LEVEL .. "_picks.inc"   ; the gems and keys (screen.py)
        .include "move.asm"         ; Trogg's movement (the C64's)
        .include "pick.asm"         ; collisions, gems and keys
        .include "hazards.asm"      ; the balloons and daggers (the C64's)
        .include "yoyo.asm"         ; the yoyo (the C64's)
        .include "unpack.asm"       ; the BBC version's unpacker (the C64's)
lvmap   .binary "../build/" .. LEVEL .. "_map.lz"   ; the level's map, packed (screen.py)
        .cerror * > ORIGA, "the program reaches ORIGA: ", * - ORIGA, " over"

        * = FONTA
        .binary "../build/" .. LEVEL .. "_font.bin"

        * = DLIST                   ; (no blank lines: the rows from scanline 8, ANTIC's first)
dlrows  .for r = 0, r < NROWS, r += 1
        .byte (r & 1) ? (r == NROWS - 1 ? $52 : $d2) : $f2   ; DLI (not the last row: the VBI
                                    ; follows), LMS, HSCROL, (VSCROL on the bottoms rows), mode 2
        .word SCREEN + r * 128
        .endfor
        .byte $41
        .word DLIST


        * = $02e0
        .word start
