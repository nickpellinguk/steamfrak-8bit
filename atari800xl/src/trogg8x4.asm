; Trogg on the 8x4 screen: his outline drawn into spare characters, AND then OR, a byte (8
; pixels) at a time from the 10-bit graphics (tools/sprites.py: for each of 4 shift positions,
; a byte a window, an index into that shift's AND and OR tables), at any position: the joystick
; walks him (left, right), climbs him (up, down), fire shows his yoyo pose; the screen follows.
;
; The display is screen8x4.asm's: 52 rows of 4 lines, a bottoms row (glyph lines 4-7) then a
; tops row (0-3), so each character holds two 4-line glyphs. Spare characters: codes POOL0 on,
; one for each column of his and each pair of rows (its bottoms half for the pair's first row,
; its tops half for the second).
;
; Each frame (the main program, while the frame before is shown): for each cell he covers, the
; level's half glyph there (from the clean map) copied into a spare character of the character
; set not shown, his lines in that cell ANDed and ORed on, and the cell's new code listed. Then
; the VBI, all at once: last frame's cells put back from the clean map, this frame's codes
; written to the screen's map, the character sets swapped (the static glyphs are in both), and
; the scroll set. So nothing he covers is ever seen half drawn.
;   64tass --atari-xex -D STARTX=x -D STARTY=y: where he starts (his origin, level pixels)
        .weak
DELAY   = 1
LEVEL   = "A_1"
STARTX  = 65
STARTY  = 187
        .endweak
        .include "../build/" .. LEVEL .. ".inc"
XMAX    = (NCOLS - 40) * 4          ; the scroll's range, in colour clocks (2 pixels)
POOL0   = 64                        ; the first spare character
        .cerror NCODES > POOL0, "the level's glyphs reach the spare characters"

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
SETVBV  = $e45c
XITVBV  = $e462

FONTA   = $6000                     ; the two character sets (the static glyphs in both)
FONTB   = $6400
DLIST   = $6800
SCREEN  = $7000                     ; the map shown: 52 rows of 128 bytes
CLEAN   = $9000                     ; the level's map, never drawn on (SCREEN + $2000)

; zero page
scrx    = $80                       ; the scroll shown (colour clocks)
nscrx   = $81                       ; the scroll for the frame being made
lmsoff  = $82
tx      = $84                       ; his origin: x (2 bytes), y (map lines), frame
ty      = $86
tf      = $87
tdir    = $88                       ; 0 facing right, 1 left
tick    = $89                       ; frames made (for the animations)
front   = $8a                       ; the character set shown: 0 A, 1 B
ready   = $8b                       ; a frame is made, for the VBI to show
xtl     = $8e                       ; his top left, x (2 bytes, even), y (map line)
ytl     = $90
d0      = $91                       ; his top line's display line (ytl + 4)
row     = $92                       ; the display row being drawn, and the last
rlast   = $93
col0    = $94                       ; his first column, the shift (0-3), bytes across, height
si      = $95
nb      = $96
ht      = $97
pair0   = $98                       ; his first row's pair
cstep   = $99                       ; a column of his graphic: his height + 6
half    = $9a                       ; 4 on a bottoms row, 0 on a tops row
jj      = $9b
dp      = $9c                       ; (2 bytes) his column's indices at the row's first line
code    = $c4
ncell   = $9e                       ; cells listed this frame, and last frame's
ocell   = $9f
dptr    = $a0                       ; his graphic's indices, at the row being drawn
cp      = $a2                       ; the spare character's half being drawn
sp      = $a4                       ; the level's glyph's half
mp      = $a6                       ; the row's first cell of his, in the screen's map
tp      = $a8                       ; ... in the clean map
bfhi    = $aa                       ; the character set not shown (high byte)
vp      = $ac                       ; (the VBI's)
vq      = $ae
shown   = $b0                       ; what the screen shows: x (2), y, frame, scroll
prev    = $b8                       ; ... and the frame before (what a frame's picture shows,
                                    ; when the VBI ends a frame already drawn)
fresh   = $bd                       ; 1 when the last VBI showed a new frame, else 0 (a frame
                                    ; not made in time: the picture is still "shown")
drops   = $be                       ; frames not made in time (2 bytes)
idle    = $c6                       ; times round the wait for the VBI (2 bytes)
nl_lo   = $0600                     ; this frame's cells: address, code
nl_hi   = $0630
nl_code = $0660
ol_lo   = $0690                     ; last frame's cells
ol_hi   = $06c0

        * = $2000
start   lda #0
        sta NMIEN
        ldx #0                      ; the screen's map from the clean one, the second set
        lda #>CLEAN                 ; from the first
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
        lda #0
        sta front
        sta ready
        sta ocell
        sta drops
        sta drops+1
        sta idle
        sta idle+1
        sta tdir
        sta tick
        sta scrx
        sta nscrx
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
+
        jsr input
        jsr prepare
        jsr camera
        jsr draw
        inc tick
        lda #1
        sta ready
        jmp main

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

; ---- Where he is drawn: his top left (x even), columns, shift, rows
prepare ldx tf
        lda tf_h,x
        sta ht
        lda tx                      ; xtl = (tx - xo) & ~1
        sec
        sbc tf_xo,x
        and #$fe
        sta xtl
        lda tx+1
        sbc #0
        sta xtl+1
        lda xtl+1                   ; col0 = xtl / 8
        lsr a
        lda xtl
        ror a
        lsr a
        lsr a
        sta col0
        lda xtl                     ; si = (xtl / 2) & 3
        lsr a
        and #3
        sta si
        lda ty                      ; ytl = ty - yo, d0 = ytl + 4
        sec
        sbc tf_yo,x
        sta ytl
        clc
        adc #4
        sta d0
        lsr a
        lsr a
        sta row
        lsr a
        sta pair0
        lda d0
        clc
        adc ht
        sec
        sbc #1
        lsr a
        lsr a
        sta rlast
        txa                         ; his graphic at this shift: frame * 4 + shift
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
        lda ht                      ; a column of his graphic: his height + 6
        clc
        adc #6
        sta cstep
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
        lda front                   ; draw in the set not shown
        eor #1
        tax
        lda fonthi,x
        sta bfhi
        rts
fonthi  .byte >FONTA, >FONTB

; ---- The scroll follows him: his x on the screen kept between 100 and 200 pixels
camera  lda xtl+1                   ; his x in colour clocks, less the scroll (16 bits)
        lsr a
        sta vq+1
        lda xtl
        ror a
        sec
        sbc nscrx
        sta vq
        lda vq+1
        sbc #0
        bmi left                    ; (left of the screen's edge: only after a jump)
        bne right                   ; (256 or more)
        lda vq
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

; ---- Drawing him into the spare characters of the set not shown, listing the cells
; For each row he's on, for each of his columns: skipped if he's all transparent there; else the
; level's half glyph there (sp), his 4 lines' indices (dp: his graphics have 3 transparent lines
; above and below each column, so a row's 4 lines are always 4 bytes in a row), the spare
; character's half (cp), all at the same y.
draw    lda #0
        sta ncell
rowlp   lda row                     ; dp = his column 0 at the row's first line: dptr + row * 4 - d0
        asl a
        asl a
        sec
        sbc d0                      ; (-3 to his height: within the padding)
        ldx #0
        cmp #$80
        bcc +
        dex                         ; (negative: the high byte's -1)
+       clc
        adc dptr
        sta dp
        txa
        adc dptr+1
        sta dp+1
        lda row                     ; the row's cells in the maps: row * 128 + 4 + col0
        lsr a
        tax
        lda #0
        ror a
        sta half                    ; (bottoms rows, even: the glyph's lines 4-7; set below)
        ora #4
        clc
        adc col0
        sta mp
        sta tp
        txa
        clc
        adc #>SCREEN
        sta mp+1
        adc #>(CLEAN - SCREEN)
        sta tp+1
        lda half                    ; half = 4 on bottoms rows (row even), 0 on tops rows
        eor #$80
        lsr a
        lsr a
        lsr a
        lsr a
        lsr a
        sta half
        lda row                     ; the spare character for his column 0 on this row
        lsr a
        sec
        sbc pair0
        clc
        adc #POOL0
        sta code
        tax                         ; cp = the set not shown + code * 8 + half
        lda glo,x
        ora half
        sta cp
        lda ghi,x
        clc
        adc bfhi
        sta cp+1
        lda #0
        sta jj
celllp  ldy #3                      ; all transparent here?
        lda (dp),y
        dey
        ora (dp),y
        dey
        ora (dp),y
        dey
        ora (dp),y
        beq next
        ldy jj                      ; sp = the level's glyph there, its half
        lda (tp),y
        tax
        lda glo,x
        ora half
        sta sp
        lda ghi,x
        clc
        adc #>FONTA
        sta sp+1
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
        ldx ncell                   ; the cell listed
        lda mp
        clc
        adc jj                      ; (no carry: a row's cells are within its 128 bytes)
        sta nl_lo,x
        lda mp+1
        sta nl_hi,x
        lda code
        sta nl_code,x
        inc ncell
next    inc jj                      ; his next column: dp + his height + 6, the spare
        lda jj                      ; character 6 on (cp + 48)
        cmp nb
        bcs rowend
        lda dp
        clc
        adc cstep
        sta dp
        bcc +
        inc dp+1
+       lda cp
        clc
        adc #48
        sta cp
        bcc +
        inc cp+1
+       lda code
        adc #6                      ; (carry clear)
        sta code
        jmp celllp
rowend  lda row
        cmp rlast
        inc row
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
vshow   ldx ocell                   ; last frame's cells back from the clean map
        beq vnew
-       dex
        lda ol_lo,x
        sta vp
        sta vq
        lda ol_hi,x
        sta vp+1
        clc
        adc #>(CLEAN - SCREEN)
        sta vq+1
        ldy #0
        lda (vq),y
        sta (vp),y
        txa
        bne -
vnew    ldx ncell                   ; this frame's codes in
        stx ocell
        beq vset
-       dex
        lda nl_lo,x
        sta vp
        sta ol_lo,x
        lda nl_hi,x
        sta vp+1
        sta ol_hi,x
        ldy #0
        lda nl_code,x
        sta (vp),y
        txa
        bne -
vset    lda front                   ; the sets swapped
        eor #1
        sta front
        tax
        lda fonthi,x
        sta CHBASE
        sta CHBAS
        ldx #4                      ; what's shown, for the checks
-       lda shown,x
        sta prev,x
        dex
        bpl -
        lda xtl
        sta shown
        lda xtl+1
        sta shown+1
        lda ytl
        sta shown+2
        lda tf
        sta shown+3
        lda nscrx
        sta shown+4
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
        lda #0
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
