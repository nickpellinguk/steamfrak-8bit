; Trogg, balloons and daggers on the 8x4 screen: their outlines drawn into spare characters, AND
; then OR, a byte (8 pixels) at a time from the 10-bit graphics (tools/sprites.py: for each of 4
; shift positions, a byte a window, an index into that shift's AND and OR tables), at any
; position, partly or wholly off the screen. The joystick walks Trogg (left, right), climbs him
; (up, down), fire shows his yoyo pose; the screen follows him. Balloons rise from below the
; screen and daggers fly in from above it, about him (stand-ins for the game's, for now).
;
; The display is screen8x4.asm's: 52 rows of 4 lines, a bottoms row (glyph lines 4-7) then a
; tops row (0-3), so each character holds two 4-line glyphs. Spare characters: codes POOL0 on,
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
; 8k + 6, and a thing on a player must end by line 8k + 2 for another to start there in band k
; (4 lines before the band starts). A thing's registers can be written in any band from the one
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
; each cell it covers on the screen (in the 52 rows, and the 41 columns in view) where it isn't
; all transparent: a spare character's half of the set not shown, started from the level's half
; glyph there (from the clean map) or, if something drawn before this frame has the cell, from
; that; its 4 lines ANDed and ORed on; and for the cell, an "lda #code, sta cell" in a program
; for the VBI, and an "lda #level's code, sta cell" in a program for the VBI after (putting it
; back). Then the VBI, all at once: last frame's putting back program and this frame's program
; run (6 cycles a cell), the character sets swapped (the static glyphs are in both), the scroll
; set.
;   64tass --atari-xex -D STARTX=x -D STARTY=y: where Trogg starts (his origin, level pixels)
;   -D NOHAZ=1: no balloons or daggers; -D STRESS=1: one every 40 frames (6 out all the time)
;   -D HWOUT=1: outlines on players too (2-pixel resolution: Trogg's from a band down, a balloon's
;   with its infill, a dagger's), where they're free; else (the default) outlines are always
;   drawn in software, at full resolution, and players only carry infills
        .weak
DELAY   = 1
LEVEL   = "A_1"
STARTX  = 65
STARTY  = 187
NOHAZ   = 0
STRESS  = 0
HWOUT   = 0
        .endweak
SPAWN   = STRESS ? 40 : 63          ; frames between balloons and daggers (63: a balloon every
                                    ; 126 and a dagger every 126, about Hard's 120 and 132)
        .include "../build/" .. LEVEL .. ".inc"
XMAX    = (NCOLS - 40) * 4          ; the scroll's range, in colour clocks (2 pixels)
POOL0   = 64                        ; the first spare character
NPOOL   = 128 - POOL0
        .cerror NCODES > POOL0, "the level's glyphs reach the spare characters"
NHAZ    = 6                         ; balloons and daggers at once
NOBJ    = 15                        ; things: Trogg, the Scrubblies, the balloons and daggers (16th:
                                    ; the multiplexer's, for Trogg's outline's bands)
GR_SCRUB = GR_N                     ; (a Scrubbly: no graphic, only its infill)

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
;   $0800-$8fff the program;  $9000 the level's map;  $ac00, $b000 the character sets;  $b400 the
;   display list;  $b500, $b800, $bb00 the VBI's programs;  under the OS: $c000, $c800 the players'
;   graphics, $d800 the screen's map, $f200 the bands' registers, $f580 the claims
CLEAN   = $9000                     ; the level's map, never drawn on (loaded)
FONTA   = $ac00                     ; the two character sets (the static glyphs in both)
FONTB   = $b000
DLIST   = $b400
PROGW   = $b500                     ; the VBI's programs: this frame's codes in, and putting each
PROGR1  = $b800                     ; frame's cells back (two: built a frame, run the next)
PROGR0  = $bb00                     ; (each 128 x "lda #, sta abs" and an rts: $281 bytes)
PMG0    = $c000                     ; the players' and missiles' graphics, two (2K each, 1-line
PMG1    = $c800                     ; resolution: missiles at + $300, player n at + $400 + n * $100)
SCREEN  = $d800                     ; the map shown: 52 rows of 128 bytes (to $f1ff)
CLAIM   = $f580                     ; the cells drawn this frame: 52 rows of 42 (the 41 columns in
                                    ; view), the spare character's code there or 0 (to $fde7)
BT      = $f200                     ; the bands' registers, both frames' (interleaved: band j's at
                                    ; (j + 1) * 2 + set; the top 4 lines', set by the VBI, at set):
BT_HP   = BT                        ; HPOSP0-3 (4 x 64)
BT_C    = BT + $100                 ; COLPM0-3 (4 x 64: P0's and P3's used)
BT_S    = BT + $200                 ; SIZEP0-3 (4 x 64: P1's and P3's used)
BT_M    = BT + $300                 ; which change in the band: bit n player n (only those are
                                    ; written: registers hold down the screen)
BT_W    = BT + $340                 ; the register writes in the band, so far (5 at most)
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
px      = $8d                       ; its top line's display line + 32
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
tp      = $aa                       ; ... in the clean map
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
spawnt  = $cb                       ; frames to the next balloon or dagger
spawnk  = $cc                       ; which comes next: 1 balloon, 2 dagger
hslot   = $cd
rcur    = $ce                       ; the putting back programs: being built (high byte), to run
rprev   = $cf
lastoff = $c5                       ; the LMS offset in the display list
dliv    = $d0                       ; the next DLI's handler (2 bytes)
stick   = $d2                       ; the joystick this frame
pmshow  = $d3                       ; the players' graphics and bands' set shown (0, 1)
bandx   = $d4                       ; the next band's registers (the DLIs')
; the multiplexer's, per thing this frame (16 each): its top and bottom line on the screen
; (display line + 32: the players' memory's line, clipped to the screen's 32-239), the line
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
foff    = $f3                       ; plot's: the flags' offset from the indices (tg_fo)
cfull   = $f4                       ; plot's: 1 if the cell's covered (no transparent pixel)                       ; chooseb's: 1 to keep the thing's band (a second player)
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
; the balloons and daggers: kind (0 none, 1 balloon, 2 dagger), x (2), top line + 32, fraction
hk      = $0680
hxl     = $0688
hxh     = $0690
hy      = $0698
hfr     = $06a0

        * = $0800                   ; (no DOS: low memory is ours from here)
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
        ldx #0                      ; the screen's map from the clean one, the second set
        lda #>CLEAN                 ; from the first, the claims clear
        sta tp+1
        lda #>SCREEN
        sta mp+1
        stx tp
        stx mp
        ldy #0
-       lda (tp),y
        sta (mp),y
        iny
        bne -
        inc tp+1
        inc mp+1
        lda mp+1
        cmp #>(SCREEN + NROWS * 128)
        bne -
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
        lda #<BT                    ; the bands' registers and the claims clear
        sta mp
        lda #>BT
        sta mp+1
        lda #0
        ldx #(CLAIM + NROWS * 42 - BT + 255) >> 8
        .cerror BT + (CLAIM + NROWS * 42 - BT + 255) & $ff00 > $ff00, "the clear reaches the vectors"
-       sta (mp),y
        iny
        bne -
        inc mp+1
        dex
        bne -
        ldx #NHAZ - 1
-       sta hk,x
        dex
        bpl -
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
        lda #$60                    ; the VBI's programs: nothing to do yet
        sta PROGW
        sta PROGR0
        sta PROGR1
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
        lda #<PMG0                  ; both graphics and the bands clear
        sta mdst
        lda #>PMG0
        sta mdst+1
        ldx #(PMG1 + $800 - PMG0) >> 8
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
        lda #40
        sta spawnt
        lda #1
        sta spawnk
        lda #<STARTX
        sta tx
        lda #>STARTX
        sta tx+1
        lda #STARTY
        sta ty
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
+       jsr input
        jsr troggpos                ; his graphic and top left: pg, px, pd
        jsr camera
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
        sta wp                      ; the programs started
        sta rp
        lda #>PROGW
        sta wp+1
        lda rcur
        sta rp+1
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
        jsr addobj
        ldx hslot
        inx
        bne -
+
      .if !NOHAZ
        jsr hazards                 ; the balloons and daggers moved, started, listed
      .endif
        jsr mux                     ; hardware sprites given out
        jsr pmdraw                  ; ... their graphics and bands' registers
        ldx #0                      ; the rest drawn in software
swlp    cpx nob
        bcs swend
        stx hslot
        txa
        clc
        adc obi
        tay
        lda OB_LV,y
        beq swnext                  ; (hardware outline: nothing here)
        lda OB_G,y
        cmp #GR_SCRUB
        beq swnext                  ; (a Scrubbly: in the map)
        sta pg
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
        jsr plot
swnext  ldx hslot
        inx
        bne swlp
swend
        lda #$60                    ; the programs ended (rts)
        ldy #0
        sta (wp),y
        sta (rp),y
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
+       inc tick
        lda #1
        sta ready
        jmp main
fonthi  .byte >FONTA, >FONTB

; ---- The joystick: walking, climbing, the yoyo pose
XLO     = 16                        ; his origin's range
XHI     = NCOLS * 8 - 16
YLO     = 34
YHI     = 199
input   lda PORTA                   ; (the joystick's bits as the OS's STICK0: 0 when pushed)
        and #15
        sta stick
        lda stick
        and #8                      ; right (0 when pushed)
        bne +
        lda #0
        sta tdir
        lda tx
        cmp #<XHI
        lda tx+1
        sbc #>XHI
        bcs walk
        inc tx
        bne walk
        inc tx+1
        jmp walk
+       lda stick
        and #4                      ; left
        bne still
        lda #1
        sta tdir
        lda tx
        cmp #<(XLO + 1)
        lda tx+1
        sbc #>(XLO + 1)
        bcc walk
        lda tx
        bne +
        dec tx+1
+       dec tx
walk    lda tick                    ; walking frames, 4 frames each
        lsr a
        lsr a
        and #3
        ldx tdir
        clc
        adc wframe,x
        sta tf
        jmp updown
still   ldx tdir
        lda sframe,x
        sta tf
updown  lda stick
        and #1                      ; up
        bne +
        lda ty
        cmp #YLO + 1
        bcc climb
        dec ty
        bcs climb                   ; (always)
+       lda stick
        and #2                      ; down
        bne fire
        lda ty
        cmp #YHI
        bcs climb
        inc ty
climb   lda stick
        and #1
        tax                         ; 0 going up, 1 down
        lda tick
        lsr a
        lsr a
        lsr a
        and #1
        clc
        adc cframe,x
        sta tf
fire    lda TRIG0                   ; (0 when pressed)
        bne +
        ldx tdir
        lda yframe,x
        sta tf
+       rts
wframe  .byte TF_WR0, TF_WL0
sframe  .byte TF_SR, TF_SL
cframe  .byte TF_CU0, TF_CD0
yframe  .byte TF_YR, TF_YL

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
        lda ty                      ; pd = ty - yo + 4 + 32
        sec
        sbc gr_yo,x
        clc
        adc #36
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

; ---- The balloons and daggers: moved, started, drawn (stand-ins for the game's)
; A balloon starts below the screen and rises a line a frame till it's above it; a dagger starts
; above the screen and flies left, a pixel a frame, and down, 11/16 of a line a frame, till it's
; below it or off the level's left. One starts every SPAWN frames, a balloon then a dagger, about
; Trogg (a balloon -64 to +63 pixels across from him, a dagger 40 to 167 to his right).
hazards ldx #NHAZ - 1
hzlp    lda hk,x
        beq hznext
        cmp #1
        bne hzdag
        dec hy,x                    ; a balloon: up a line
        lda hy,x
        cmp #32 - 10 + 1            ; gone when its bottom's above the screen's top
        bcs hzdraw
        bcc hzgone
hzdag   lda hxl,x                   ; a dagger: left a pixel
        bne +
        dec hxh,x
+       dec hxl,x
        lda hfr,x                   ; down 11/16 of a line
        clc
        adc #11
        cmp #16
        and #15
        sta hfr,x
        bcc +
        inc hy,x
+       lda hy,x
        cmp #32 + 208               ; gone when its top's below the screen's bottom
        bcs hzgone
        lda hxh,x                   ; or it's off the level's left (x < -12)
        bpl hzdraw
        lda hxl,x
        cmp #<-12
        bcs hzdraw
hzgone  lda #0
        sta hk,x
        beq hznext
hzdraw  stx hslot                   ; listed
        lda hk,x
        tay
        lda hzgr - 1,y
        sta pg
        lda hxl,x
        and #$fe
        sta px
        lda hxh,x
        sta px+1
        lda hy,x
        sta pd
        jsr addobj
        ldx hslot
hznext  dex
        bpl hzlp
        dec spawnt                  ; a new one?
        bne hzend
        lda #SPAWN
        sta spawnt
        ldx #NHAZ - 1               ; a free slot
-       lda hk,x
        beq +
        dex
        bpl -
        rts
+       lda spawnk
        sta hk,x
        eor #3
        sta spawnk
        lda #0
        sta hfr,x
        lda RANDOM
        and #127
        ldy hk,x
        cpy #1
        bne +
        sec                         ; a balloon: -64 to +63 from him, below the screen
        sbc #64
        sta tmp
        and #$80                    ; (its sign)
        beq ++
        lda #$ff
        bne ++
+       clc                         ; a dagger: 40 to 167 to his right, above the screen
        adc #40
        sta tmp
        lda #0
+       sta tmp+1
        lda hk,x
        tay
        lda hzy0 - 1,y
        sta hy,x
        lda tmp                     ; x = his x + the offset
        clc
        adc tx
        sta hxl,x
        lda tmp+1
        adc tx+1
        sta hxh,x
hzend   rts
hzgr    .byte GR_BALLOON, GR_DAGGERLR
hzy0    .byte 32 + 208, 32 - 10     ; where they start: below the screen, above it

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
        cpx #54
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
        bne +
        lda #SCR_H
        sta stmp
        lda #32
        bne ++
+       lda gr_h,x
        sta stmp
        lda gr_w,x
+       sta mcnt
        lda OB_D,y                  ; its top, clipped to the screen's (32)
        cmp #32
        bcs +
        lda #32
+       sta mp2
        lda OB_D,y                  ; its bottom, clipped to the screen's (239)
        clc
        adc stmp
        bcs mxbig
        sbc #0                      ; (carry clear: - 1)
        cmp #240
        bcc +
mxbig   lda #239
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

bstart  cmp #38                     ; the band holding at line a: its start (32 above line 38,
        bcs +                       ; else 38 + 8k)
        lda #32
        rts
+       sec
        sbc #38
        and #$f8
        clc
        adc #38
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
        bcs mxend
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
        beq mxhn
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
; with room for the writes (the VBI's, line 32, always has room). Carry clear if one: oWB and
; oBS the band's line, its writes counted
chooseb ldx mk
        lda #32                     ; mlast: the earliest line it can be
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
        cmp #38
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
        cmp #38
        bcs cblp
        lda #32
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
pmcd    ldx mset
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
        cmp #GR_SCRUB
        bne +
        jsr pmscr
        jmp pmnext
+       lda mk
        bne +
        jsr pmtrog
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

pmscr   lda OB_LV,y                 ; a Scrubbly: two players, or one double-width
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
strip   ldy mset
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
        sbc oT,x                    ; (lines - 1)
        pha
        clc
        adc #1
        sta pc_n,y
        pla
        tay
-       lda (msrc),y
        sta (mdst),y
        dey
        bpl -
        rts

bidx    cmp #38                     ; the band holding at line a: its index in this set's tables
        bcs +
        lda mset
        rts
+       sec
        sbc #38
        lsr a
        lsr a
        and #$fe
        clc
        adc #2
        adc mset
        rts



; ---- plot: graphic pg at top left (px: level pixels, even, signed; pd: display line + 32),
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
        lda tg_fo,x
        sta foff
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
        lda pd                      ; its rows, + 8: pd / 4 to (pd + ht - 1) / 4
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
rowlp   lda rq                      ; rows above the screen skipped, below it the end
        cmp #8
        bcs +
        jmp rownext
+       cmp #8 + NROWS
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
        lda rq                      ; the row: rq - 8
        sec
        sbc #8
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
        sta tp
        txa
        clc
        adc #>SCREEN
        sta mp+1
        adc #((CLEAN - SCREEN) >> 8) & $ff
        sta tp+1
        pla                         ; the claims: CLAIM + row * 42
        tax
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
+       ldy foff                    ; the cell's flag: 2 all transparent (skipped), 1 covered (the
        lda (dp),y                  ; OR alone: no background), 0 mixed
        cmp #2
        bne +
        jmp next
+       sta cfull
        ldy scol                    ; drawn already this frame?
        lda (cl),y
        beq new
        tax                         ; then on from what's there: sp = cp
        lda glo,x
        ora half
        sta cp
        sta sp
        lda ghi,x
        clc
        adc bfhi
        sta cp+1
        sta sp+1
        lda cfull                   ; (covered: the OR alone)
        beq +
        jmp orpath
+       jmp draw4
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
        lda glo,x
        ora half
        sta cp
        lda ghi,x
        clc
        adc bfhi
        sta cp+1
        lda (tp),y                  ; sp = the level's glyph there, its half
        sta orig
        beq +                       ; (blank, or the cell's covered: drawn with OR alone, below)
        ldx cfull
        bne +
        tax
        lda glo,x
        ora half
        sta sp
        lda ghi,x
        clc
        adc #>FONTA
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
        tya                         ; the programs' entries: lda #code / lda #orig, sta cell
        clc
        adc mp                      ; (likewise its 128)
        sta tmp
        ldy #0
        lda #$a9
        sta (wp),y
        sta (rp),y
        iny
        lda code
        sta (wp),y
        lda orig
        sta (rp),y
        iny
        lda #$8d
        sta (wp),y
        sta (rp),y
        iny
        lda tmp
        sta (wp),y
        sta (rp),y
        iny
        lda mp+1
        sta (wp),y
        sta (rp),y
        lda wp
        clc
        adc #5
        sta wp
        bcc +
        inc wp+1
+       lda rp
        clc
        adc #5
        sta rp
        bcc +
        inc rp+1
+       inc ncell
        lda orig
        beq orpath
        lda cfull
        beq draw4
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

clrl    .for r = 0, r < NROWS, r += 1   ; the claims' rows
        .byte <(CLAIM + r * 42)
        .endfor
clrh    .for r = 0, r < NROWS, r += 1
        .byte >(CLAIM + r * 42)
        .endfor
glo     .for c = 0, c < 128, c += 1 ; a character's offset in its set
        .byte <(c * 8)
        .endfor
ghi     .for c = 0, c < 128, c += 1
        .byte >(c * 8)
        .endfor

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

        .align $100
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

        .align $100
dltab   .word dlb0, dlb1, dlb2, dlb3, dlb4, dlb5, dlb6, dlb7, dlb8, dlb9, dlb10, dlb11, dlb12, dlb13, dlb14, dlb15
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
        .cerror * > CLEAN, "the program reaches the level's map: ", * - CLEAN, " over"

        * = FONTA
        .binary "../build/" .. LEVEL .. "_font.bin"

        * = DLIST
        .byte $70, $70, $70
dlrows  .for r = 0, r < NROWS, r += 1
        .byte (r & 1) ? $d2 : $f2   ; DLI, LMS, HSCROL, (VSCROL on the bottoms rows), mode 2
        .word SCREEN + r * 128
        .endfor
        .byte $41
        .word DLIST

        * = CLEAN
        .binary "../build/" .. LEVEL .. "_map.bin"

        * = $02e0
        .word start
