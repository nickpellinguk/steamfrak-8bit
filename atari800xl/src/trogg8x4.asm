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
; Each frame (the main program, while the frame before is shown), plot draws each thing: for
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
        .weak
DELAY   = 1
LEVEL   = "A_1"
STARTX  = 65
STARTY  = 187
NOHAZ   = 0
STRESS  = 0
        .endweak
SPAWN   = STRESS ? 40 : 63          ; frames between balloons and daggers (63: a balloon every
                                    ; 126 and a dagger every 126, about Hard's 120 and 132)
        .include "../build/" .. LEVEL .. ".inc"
XMAX    = (NCOLS - 40) * 4          ; the scroll's range, in colour clocks (2 pixels)
POOL0   = 64                        ; the first spare character
NPOOL   = 128 - POOL0
        .cerror NCODES > POOL0, "the level's glyphs reach the spare characters"
NHAZ    = 6                         ; balloons and daggers at once
NOBJ    = NHAZ + 1                  ; things drawn: Trogg, then them

VDSLST  = $0200
SDLSTL  = $0230
SDMCTL  = $022f
STICK0  = $0278
STRIG0  = $0284
CHBAS   = $02f4
COLOR1  = $02c5
COLOR2  = $02c6
COLOR4  = $02c8
HSCROL  = $d404
VSCROL  = $d405
CHBASE  = $d409
WSYNC   = $d40a
NMIEN   = $d40e
RANDOM  = $d20a
SETVBV  = $e45c
XITVBV  = $e462

FONTA   = $6000                     ; the two character sets (the static glyphs in both)
FONTB   = $6400
DLIST   = $6800
SCREEN  = $7000                     ; the map shown: 52 rows of 128 bytes
PROGW   = $8a00                     ; the VBI's programs: this frame's codes in, and putting each
PROGR0  = $8d00                     ; frame's cells back (two: built a frame, run the next)
PROGR1  = $b700                     ; (each 128 x "lda #, sta abs" and an rts: $281 bytes)
CLEAN   = $9000                     ; the level's map, never drawn on (SCREEN + $2000)
CLAIM   = $aa00                     ; the cells drawn this frame: 52 rows of 64 (the 41 columns in
                                    ; view), the spare character's code there or 0

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

; the things drawn, for the checks: three records of graphic, x (2), top line + 32 (8 each),
; the scroll and how many, at OBJS + obi, shi, pvi: the frame being made, the frame shown, and
; the one before (what a frame's picture shows, when its VBI shows a new frame)
OBJS    = $0600
OB_G    = OBJS
OB_XL   = OBJS + 8
OB_XH   = OBJS + 16
OB_D    = OBJS + 24
OB_SCR  = OBJS + 32
OB_N    = OBJS + 33
; the balloons and daggers: kind (0 none, 1 balloon, 2 dagger), x (2), top line + 32, fraction
hk      = $06a0
hxl     = $06a8
hxh     = $06b0
hy      = $06b8
hfr     = $06c0
; this frame's cells' claims, to clear (128 at most: 64 of each half)
cl_lo   = $0480
cl_hi   = $0500

        * = $2000
start   lda #0
        sta NMIEN
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
        lda #<CLAIM
        sta mp
        lda #>CLAIM
        sta mp+1
        lda #0
        ldx #>(NROWS * 64)
-       sta (mp),y
        iny
        bne -
        inc mp+1
        dex
        bpl -
        ldx #NHAZ - 1
-       sta hk,x
        dex
        bpl -
        lda #<DLIST
        sta SDLSTL
        lda #>DLIST
        sta SDLSTL+1
        lda #>FONTA
        sta CHBAS
        lda #$00                    ; the outlines: luminance 0
        sta COLOR1
        lda #$9a                    ; the background (PF2)
        sta COLOR2
        lda #$00
        sta COLOR4
        lda #$22                    ; normal width, playfield DMA
        sta SDMCTL
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
        lda #40
        sta shi
        lda #80
        sta pvi
        lda #0
        sta OBJS + 40 + 33
        sta OBJS + 80 + 33
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
        lda #7
        ldx #>vbi
        ldy #<vbi
        jsr SETVBV
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
        jsr plotrec                 ; Trogg
      .if !NOHAZ
        jsr hazards                 ; the balloons and daggers moved, started, drawn
      .endif
        lda #$60                    ; the programs ended (rts)
        ldy #0
        sta (wp),y
        sta (rp),y
        ldx obi                     ; the record: the scroll, how many
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
input   lda STICK0
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
+       lda STICK0
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
updown  lda STICK0
        and #1                      ; up
        bne +
        lda ty
        cmp #YLO + 1
        bcc climb
        dec ty
        bcs climb                   ; (always)
+       lda STICK0
        and #2                      ; down
        bne fire
        lda ty
        cmp #YHI
        bcs climb
        inc ty
climb   lda STICK0
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
fire    lda STRIG0                  ; (0 when pressed)
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
hzdraw  stx hslot                   ; drawn
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
        jsr plotrec
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

; ---- plotrec: plot, and the thing listed for the checks
plotrec lda nob
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
        inc nob
+       ; (on into plot)

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
        adc #>(CLEAN - SCREEN)
        sta tp+1
        pla                         ; the claims: CLAIM + row * 64
        sta cl+1
        lda #0
        lsr cl+1
        ror a
        lsr cl+1
        ror a
        sta cl
        lda cl+1
        clc
        adc #>CLAIM
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
+       ldy #3                      ; all transparent here?
        lda (dp),y
        dey
        ora (dp),y
        dey
        ora (dp),y
        dey
        ora (dp),y
        bne +
        jmp next
+       ldy scol                    ; drawn already this frame?
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
        lda glo,x
        ora half
        sta cp
        lda ghi,x
        clc
        adc bfhi
        sta cp+1
        lda (tp),y                  ; sp = the level's glyph there, its half
        sta orig
        beq +                       ; (blank: drawn with OR alone, below)
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
        adc cl                      ; (no carry: a row's cells are within its 64)
        sta cl_lo,x
        lda cl+1
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
        bne draw4
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

glo     .for c = 0, c < 128, c += 1 ; a character's offset in its set
        .byte <(c * 8)
        .endfor
ghi     .for c = 0, c < 128, c += 1
        .byte >(c * 8)
        .endfor

; ---- The deferred VBI: the frame made shown, all at once
vbi     lda ready
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
        sta CHBAS
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
vdone   lda #0
        sta ready
vbiend  lda #4
        sta VSCROL
        lda #<dlia
        sta VDSLST
        lda #>dlia
        sta VDSLST+1
        jmp XITVBV

dlia    pha                         ; a bottoms row's last line: VSCROL 3 for the tops row's end
        lda #3
        sta VSCROL
        lda #<dlib
        sta VDSLST
        lda #>dlib
        sta VDSLST+1
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
        sta VDSLST
        lda #>dlia
        sta VDSLST+1
        pla
        rti

        .include "../build/sprites.inc"
        .cerror * > FONTA, "the program reaches the character sets"

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
