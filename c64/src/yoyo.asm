; ---- The yoyo: a port of the BBC version's start_yoyo, yoyo_out, yoyo_back, yoyo_longer,
; yoyo_position and yoyo_collide. A_1 has no movable platforms, so the carrying is left out; the
; yoyo knocks Scrubblies off and pops balloons and daggers. yo_len is the string's
; length, tenths of a pixel then pixels: 1.3 a tick out while the key's held, to 80, then back at
; the same rate. The yoyo is virtual sprite YV (hi-res black: its yellow highlight shows the
; background); its string is a line of characters in the pair shown (strset works it out in the
; main program, strapply writes it in the border, putting the last frame's cells back first).
; A Scrubbly hit is knocked off: its sprite hidden, and its cells changed to what's behind it
; (scrpatch.inc) in the level map and in each pair that shows them; a restart puts them back.
YOYO_MAX = 80
YV      = NS + NB                   ; (the yoyo's virtual sprite)
SPRYOYO = $54c0                     ; (its 4 frames' sprites)
yp      = zp + 88                   ; (2: the main program's)
ip0     = zp + 90                   ; (2: strapply's, in the border)
ip1     = zp + 92                   ; (2)

        .section high
start_yoyo
        lda #ST_YOYO_OUT
        sta tstate
        lda #0
        sta yo_len
        lda #1                      ; (length 1 for this tick's position)
        sta yo_len+1
        jsr yoyo_position
        jsr yoyo_collide
        bcc +
        lda #ST_YOYO_BACK
        sta tstate
        lda #1
        sta yo_db
+       lda #0                      ; (then it starts from 0)
        sta yo_len+1
        rts

yoyo_out
        lda #0
        sta yo_turn
        lda doyoyo
        beq _change
        lda yo_len+1
        cmp #YOYO_MAX
        bcs _change
        jsr yoyo_longer
        jmp _moved
_change lda #1                      ; (let go, or as long as it goes)
        sta yo_turn
_moved  jsr yoyo_position
        jsr yoyo_collide
        bcs _back
        lda yo_turn
        bne _back
        lda yo_x+1                  ; (the level's left edge: yo_x < 2, signed)
        bmi _back
        bne _done
        lda yo_x
        cmp #2
        bcs _done
_back   lda #ST_YOYO_BACK
        sta tstate
        lda #1
        sta yo_db
_done   rts

yoyo_back
        lda yo_len                  ; length - 1.3; home if that's 0 or less
        sec
        sbc #3
        bcs +
        adc #10
        clc
+       sta yo_len
        lda yo_len+1
        sbc #1
        sta yo_len+1
        bcc _home
        bmi _home
        ora yo_len
        beq _home
        jsr yoyo_position
        jmp yoyo_collide            ; (still knocks Scrubblies off on the way back)
_home   lda #ST_STAND
        sta tstate
        lda #0
        sta yo_len
        sta yo_len+1
        rts

yoyo_longer                         ; length + 1.3
        lda yo_len
        clc
        adc #3
        cmp #10
        bcc +
        sbc #10
+       sta yo_len
        lda yo_len+1
        adc #1
        sta yo_len+1
        rts

; yo_x = tx + (length + 12) * direction (rounded down), yo_y = ty - 11
yoyo_position
        lda yo_len+1
        clc
        adc #12
        sta ytmp
        lda tface
        bne _l
        lda tx
        clc
        adc ytmp
        sta yo_x
        lda tx+1
        adc #0
        sta yo_x+1
        jmp _y
_l      lda #0
        cmp yo_len                  ; (carry clear if there are tenths: one further)
        lda tx
        sbc ytmp
        sta yo_x
        lda tx+1
        sbc #0
        sta yo_x+1
_y      lda ty
        sec
        sbc #11
        sta yo_y
        lda ty+1
        sbc #0
        sta yo_y+1
        rts

; Did the yoyo hit a Scrubbly? The yoyo's square, x yo_x - 3 to yo_x + 3, y yo_y - 7 to yo_y
; (as the BBC version makes it), against each Scrubbly's 40 x 42 (its characters: scl, sct). A
; Scrubbly hit is knocked off. Carry set if one was.
yoyo_collide
        lda #0
        sta yo_hit
        lda yo_x
        sec
        sbc #3
        sta yb_l
        lda yo_x+1
        sbc #0
        sta yb_l+1
        lda yo_x
        clc
        adc #3
        sta yb_r
        lda yo_x+1
        adc #0
        sta yb_r+1
        lda yo_y
        sec
        sbc #7
        sta yb_t
        lda yo_y+1
        sbc #0
        sta yb_t+1
        ldx #NS - 1
_lp     lda knocked,x
        bne _nx
        lda scl,x                   ; yoyo left < its left + 40 ?
        clc
        adc #40
        sta ytmp
        lda sch,x
        adc #0
        sta ytmp+1
        lda yb_l
        cmp ytmp
        lda yb_l+1
        sbc ytmp+1
        bcs _nx
        lda yb_r                    ; yoyo right >= its left ?
        cmp scl,x
        lda yb_r+1
        sbc sch,x
        bcc _nx
        lda sct,x                   ; yoyo top < its top + 42 ?
        clc
        adc #42
        sta ytmp
        lda #0
        adc #0
        sta ytmp+1
        lda yb_t
        cmp ytmp
        lda yb_t+1
        sbc ytmp+1
        bcs _nx
        lda yo_y                    ; yoyo bottom >= its top ?
        cmp sct,x
        lda yo_y+1
        sbc #0
        bcc _nx
        lda #1                      ; hit
        sta yo_hit
        stx ysi
        jsr knock
        ldx ysi
_nx     dex
        bpl _lp
        .if !NOBALLS
        ldx #NB - 1                 ; the balloons and daggers: popped (their images' boxes)
_m      lda oact,x
        bne +
        jmp _mn
+
        tay
        lda oxl,x                   ; (left: its origin less kxo; right: + kw - 1)
        sec
        sbc kxo,y
        sta yhl
        lda oxh,x
        sbc #0
        sta yhl+1
        lda yb_r                    ; yoyo right >= its left ?
        sec
        sbc yhl
        lda yb_r+1
        sbc yhl+1
        bpl +
        jmp _mn
+
        lda yhl
        clc
        adc kw,y
        sta yhl
        lda yhl+1
        adc #0
        sta yhl+1                   ; (its right + 1)
        lda yb_l                    ; yoyo left < its right + 1 ?
        sec
        sbc yhl
        lda yb_l+1
        sbc yhl+1
        bmi +
        jmp _mn
+
        lda oy,x                    ; (top: its origin less kyo; bottom: + kh - 1)
        sec
        sbc kyo,y
        sta yhl
        lda oyh,x
        sbc #0
        sta yhl+1
        lda yo_y                    ; yoyo bottom >= its top ?
        sec
        sbc yhl
        lda yo_y+1
        sbc yhl+1
        bpl +
        jmp _mn
+
        lda yhl
        clc
        adc kh,y
        sta yhl
        lda yhl+1
        adc #0
        sta yhl+1
        lda yb_t                    ; yoyo top < its bottom + 1 ?
        sec
        sbc yhl
        lda yb_t+1
        sbc yhl+1
        bmi +
        jmp _mn
+
        lda #0                      ; popped
        sta oact,x
        lda #1
        sta yo_hit
_mn     dex
        bmi +
        jmp _m
+
        .endif
        lda yo_hit
        cmp #1                      ; (carry set if hit)
        rts

; Scrubbly x knocked off: its cells' codes saved and changed to what's behind it
knock   lda #1
        sta knocked,x
        lda scrpi,x
        ldy scrpn,x
        jmp patchon

; Gem or key x picked up: the same (its cells: what's behind it); counted, and the last key noted
pickup  lda #1
        sta picked,x
        lda pkkind,x
        cmp #2
        bne +
        inc keysgot
        lda keysgot
        cmp #NKEYS
        bne ++
        lda #1                      ; (all the keys: the level complete)
        sta allkeys
        jsr level_complete
        jmp ++
+       inc gemsgot
+       lda pkpi,x
        ldy pkpn,x

; Patch cells a to a + y - 1 (scrplo ...): the codes there saved (scrsvt, scrsvb), the new ones in
patchon sta yk
        sty ytmp
        clc
        adc ytmp
        sta yke
-       ldx yk
        lda scrplo,x                ; (the codes there now saved)
        clc
        adc #<tops
        sta yp
        lda scrphi,x
        adc #>tops
        sta yp+1
        ldy #0
        lda (yp),y
        sta scrsvt,x
        lda scrplo,x
        clc
        adc #<bottoms
        sta yp
        lda scrphi,x
        adc #>bottoms
        sta yp+1
        lda (yp),y
        sta scrsvb,x
        lda scrpt,x
        sta ytop
        lda scrpb,x
        sta ybot
        jsr pcell
        inc yk
        lda yk
        cmp yke
        bne -
        rts

; ... and back: the codes saved put back
patchoff
        sta yk
        sty ytmp
        clc
        adc ytmp
        sta yke
-       ldx yk
        lda scrsvt,x
        sta ytop
        lda scrsvb,x
        sta ybot
        jsr pcell
        inc yk
        lda yk
        cmp yke
        bne -
        rts

; Every Scrubbly, gem and key back (at a restart)
unknock ldx #NS - 1
_s      lda knocked,x
        beq _n
        lda #0
        sta knocked,x
        stx ysi
        lda scrpi,x
        ldy scrpn,x
        jsr patchoff
        ldx ysi
_n      dex
        bpl _s
        ldx #NP - 1
_g      lda picked,x
        beq _gn
        lda #0
        sta picked,x
        stx ysi
        lda pkpi,x
        ldy pkpn,x
        jsr patchoff
        ldx ysi
_gn     dex
        bpl _g
        lda #0
        sta gemsgot
        sta keysgot
        sta allkeys
        rts

; Patch cell yk to ytop, ybot: in the level map, and in each pair up to date for a window it's in
; (a pair being filled starts again, so the rows it's done have it too)
pcell   ldx yk
        lda scrplo,x
        clc
        adc #<tops
        sta yp
        lda scrphi,x
        adc #>tops
        sta yp+1
        ldy #0
        lda ytop
        sta (yp),y
        lda scrplo,x
        clc
        adc #<bottoms
        sta yp
        lda scrphi,x
        adc #>bottoms
        sta yp+1
        lda ybot
        sta (yp),y
        ldx #1
_p      lda pvw,x
        cmp #$ff
        bne +
        cpx back                    ; (being filled: again)
        bne _np
        lda #0
        sta prow
        beq _np
+       ldy yk
        lda scrpc,y
        sec
        sbc pvw,x
        cmp #40
        bcs _np                     ; (not in its window: it'll be written when it is)
        lda scrpr,y
        sta yr
        lda scrpc,y
        sec
        sbc po,x
        sta yj                      ; (its place in the row: column - origin)
        lda #0
        jsr rowptr
        ldy yj
        lda ytop
        sta (yp),y
        lda #1
        jsr rowptr
        ldy yj
        lda ybot
        sta (yp),y
_np     dex
        bpl _p
        rts

; yp = the start of row yr in pair x's tops' (a 0) or bottoms' (1) screen (x kept)
rowptr  ldy yr
        cpx #0
        bne _1
        cmp #0
        bne _0b
        lda fdlo,y                  ; (fdlo, fdt0, ...: the rows' column 2: fillrow's)
        sec
        sbc #2
        sta yp
        lda fdt0,y
        sbc #0
        sta yp+1
        rts
_0b     lda fdlo,y
        sec
        sbc #2
        sta yp
        lda fdb0,y
        sbc #0
        sta yp+1
        rts
_1      cmp #0
        bne _1b
        lda fdlo,y
        sec
        sbc #2
        sta yp
        lda fdt1,y
        sbc #0
        sta yp+1
        rts
_1b     lda fdlo,y
        sec
        sbc #2
        sta yp
        lda fdb1,y
        sbc #0
        sta yp+1
        rts

; The yoyo's sprite, for the next frame: at (yo_x - 3, yo_y - 5) in the level (its image's
; corner), one of 4 frames as the length goes (the BBC version's yoyo_image)
yoyoset lda tstate
        cmp #ST_YOYO_OUT
        bcc _hide
        lda yo_x                    ; x: (yo_x - 3) + 31 - the scroll
        clc
        adc #28
        sta ytmp
        lda yo_x+1
        adc #0
        sta ytmp+1
        lda ytmp
        sec
        sbc scrx
        sta vxlo + YV
        lda ytmp+1
        sbc scrx+1
        bmi _hide
        beq +
        cmp #1                      ; (256-343: on the screen)
        bne _hide
        lda vxlo + YV
        cmp #344 - 256
        bcs _hide
        lda #1
+       sta vxhi + YV
        lda yo_y+1                  ; y: (yo_y - 5) - 24 + 50
        bne _hide
        lda yo_y
        cmp #256 - 21
        bcs _hide
        adc #21
        sta vy + YV
        lda yo_len+1                ; the frame: (length / 8) & 3, the other way round facing left
        ldx tface
        beq +
        eor #$ff
        clc
        adc #1
        cmp #$80
        ror
        cmp #$80
        ror
        cmp #$80
        ror
        jmp ++
+       lsr
        lsr
        lsr
+       and #3
        clc
        adc #(SPRYOYO & $3fff) / 64
        sta vptr + YV
        lda #VFIRST
        sta vfl + YV
        rts
_hide   lda #VFIRST | VHIDE
        sta vfl + YV
        rts

; The string, for the next frame: a line on map line ty - 36 (level y yo_y - 1), from the
; character under his hand (tx + 12, or tx - 12) to the one under the yoyo's near edge, in the
; tops' screen if it's on lines 0-3 of its row, else the bottoms', as string character 60-63
; (the line at line 0-3 of both halves); only the columns in the window (curc + 2 to curc + 39)
strset  lda #0
        sta sp_on
        lda tstate
        cmp #ST_YOYO_OUT
        bcc _xj
        lda ty
        sec
        sbc #36
        sta ytmp
        lda ty+1
        sbc #0
        bne _xj                     ; (above the map, or past it)
        lda ytmp
        cmp #200
        bcc +
_xj     rts
+       lsr
        lsr
        lsr
        sta sp_r
        lda ytmp
        and #7
        cmp #4                      ; (lines 4-7: the bottoms')
        lda #0
        rol
        sta sp_h
        lda ytmp
        and #3
        ora #STRING
        sta sp_ch
        lda tface
        bne _l
        lda tx                      ; right: from (tx + 12) / 8 to (yo_x - 3) / 8
        clc
        adc #12
        sta ytmp
        lda tx+1
        adc #0
        jsr shr3
        sta sp_c0
        lda yo_x
        sec
        sbc #3
        sta ytmp
        lda yo_x+1
        sbc #0
        jsr shr3
        sta sp_c1
        jmp _clip
_l      lda yo_x                    ; left: from (yo_x + 3) / 8 to (tx - 12) / 8
        clc
        adc #3
        sta ytmp
        lda yo_x+1
        adc #0
        bpl +
        lda #0                      ; (past the level's left edge: from 0)
        sta ytmp
+       jsr shr3
        sta sp_c0
        lda tx
        sec
        sbc #12
        sta ytmp
        lda tx+1
        sbc #0
        jsr shr3
        sta sp_c1
_clip   lda curc                    ; the window's columns only
        clc
        adc #2
        cmp sp_c0
        bcc +
        sta sp_c0
+       lda curc
        clc
        adc #39
        cmp sp_c1
        bcs +
        sta sp_c1
+       lda sp_c1
        cmp sp_c0
        bcc _x
        lda #1
        sta sp_on
_x      rts
shr3    lsr                         ; ((a, ytmp) >> 3)
        ror ytmp
        lsr
        ror ytmp
        lsr
        ror ytmp
        lda ytmp
        rts

; In the border, with the scroll: the last frame's string cells put back from the level map (in
; the pair they were written to, those in its window), then this frame's written into the pair
; shown
strapply
        lda sa_on
        beq _new
        ldx sa_p
        lda pvw,x
        cmp #$ff
        beq _new                    ; (being filled: from the map anyway)
        jsr _ptrs
        lda sa_h                    ; (the map's row: ip1)
        bne +
        ldy sa_r
        lda fstlo,y                 ; (fstlo ...: fillrow's, the rows' column 2)
        sec
        sbc #2
        sta ip1
        lda fsthi,y
        sbc #0
        sta ip1+1
        jmp ++
+       ldy sa_r
        lda fsblo,y
        sec
        sbc #2
        sta ip1
        lda fsbhi,y
        sbc #0
        sta ip1+1
+       lda pvw,x                   ; (the columns in its window)
        clc
        adc #2
        cmp sa_c0
        bcs +
        lda sa_c0
+       tay
        lda pvw,x
        clc
        adc #39
        cmp sa_c1
        bcc +
        lda sa_c1
+       sta iend
        cpy iend
        beq +
        bcs _new
+
-       lda (ip1),y
        sta (ip0),y
        cpy iend
        iny
        bcc -
_new    lda sp_on
        sta sa_on
        beq _x
        lda front
        sta sa_p
        lda sp_r
        sta sa_r
        lda sp_h
        sta sa_h
        lda sp_c0
        sta sa_c0
        lda sp_c1
        sta sa_c1
        ldx front
        jsr _ptrs
        ldy sa_c0
        lda sp_ch
-       sta (ip0),y
        cpy sa_c1
        iny
        bcc -
_x      rts
; ip0 = pair x's screen (sa_h: tops or bottoms), row sa_r, less its origin: (ip0),y is column y
_ptrs   ldy sa_r
        lda sa_h
        bne _b
        cpx #0
        bne +
        lda fdlo,y
        sta ip0
        lda fdt0,y
        jmp _o
+       lda fdlo,y
        sta ip0
        lda fdt1,y
        jmp _o
_b      cpx #0
        bne +
        lda fdlo,y
        sta ip0
        lda fdb0,y
        jmp _o
+       lda fdlo,y
        sta ip0
        lda fdb1,y
_o      sta ip0+1
        lda ip0                     ; (less 2,
        sec
        sbc #2
        sta ip0
        bcs +
        dec ip0+1
+       ldy #0                      ;  and less the origin, signed)
        lda po,x
        bpl +
        dey
+       sty iend
        lda ip0
        sec
        sbc po,x
        sta ip0
        lda ip0+1
        sbc iend
        sta ip0+1
        rts

; The yoyo's 4 frames (the BBC version's IMG_Yoyo_0-3, its black; 7 x 6)
        .include "scrpatch.inc"     ; STRING; each Scrubbly's patch (pack.mjs)

yoyospr .byte $7c, 0, 0, $c6, 0, 0, $f2, 0, 0, $fa, 0, 0, $fe, 0, 0, $7c, 0, 0
        .fill 46
        .byte $7c, 0, 0, $fe, 0, 0, $fa, 0, 0, $f2, 0, 0, $c6, 0, 0, $7c, 0, 0
        .fill 46
        .byte $7c, 0, 0, $fe, 0, 0, $be, 0, 0, $9e, 0, 0, $c6, 0, 0, $7c, 0, 0
        .fill 46
        .byte $7c, 0, 0, $c6, 0, 0, $9e, 0, 0, $be, 0, 0, $fe, 0, 0, $7c, 0, 0
        .fill 46

yo_len  .word 0
yo_turn .byte 0
yo_x    .word 0
yo_y    .word 0
yb_l    .word 0
yb_r    .word 0
yb_t    .word 0
yo_hit  .byte 0
yhl     .word 0                     ; (a balloon's or dagger's edge)
ytmp    .word 0
ysi     .byte 0
yk      .byte 0
yke     .byte 0
ytop    .byte 0
ybot    .byte 0
yr      .byte 0
yj      .byte 0
knocked .fill NS
picked  .fill NP                    ; (each gem and key: picked up)
gemsgot .byte 0
keysgot .byte 0
allkeys .byte 0                     ; (all the keys picked up: the level complete)
scrsvt  .fill 256                   ; (the knocked-off cells' codes before)
scrsvb  .fill 256
sp_on   .byte 0                     ; (the string for the next frame: strset's)
sp_r    .byte 0
sp_h    .byte 0
sp_ch   .byte 0
sp_c0   .byte 0
sp_c1   .byte 0
sa_on   .byte 0                     ; (the string shown: strapply's)
sa_p    .byte 0
sa_r    .byte 0
sa_h    .byte 0
sa_c0   .byte 0
sa_c1   .byte 0
iend    .byte 0
strpend .byte 0                     ; (a frame's been switched to: its string to apply)
        .send high
