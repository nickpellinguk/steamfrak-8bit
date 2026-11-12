; ---- Collisions, by box (the first stage of the BBC version's check_collisions): Trogg's box (his
; frame's solid pixels' extent, as shown) against each object's, in the level's coordinates, all
; from the build (collide.inc). A Scrubbly (not yoyoed off) or a balloon or dagger kills him; a gem
; or key touched is noted (ptouch: picking them up is to come). Only the Scrubblies, gems and keys
; in his columns are looked at (a mask a column, from the build), the balloons and daggers by y
; first. The comparisons are signed: his box can reach above the level's top, jumping.
        .section high
        .include "collide.inc"      ; tbx0 ... (Trogg's frames), scbll ... (the Scrubblies), pkll ...
                                    ; (the gems and keys), BBX0 ... (the ball sprite)
collide lda dead
        beq +
        rts
+       ldx tfr                     ; his box: x tx + tbx0 to tx + tbx1, y ty + tby0 to ty + tby1
        lda tbx0,x
        bpl +
        clc
        adc tx
        sta ctl
        lda tx+1
        adc #$ff
        jmp ++
+       clc
        adc tx
        sta ctl
        lda tx+1
        adc #0
+       sta ctl+1
        lda tbx1,x
        bpl +
        clc
        adc tx
        sta ctr
        lda tx+1
        adc #$ff
        jmp ++
+       clc
        adc tx
        sta ctr
        lda tx+1
        adc #0
+       sta ctr+1
        lda tby0,x
        bpl +
        clc
        adc ty
        sta ctt
        lda ty+1
        adc #$ff
        jmp ++
+       clc
        adc ty
        sta ctt
        lda ty+1
        adc #0
+       sta ctt+1
        lda ctl+1                   ; (and his columns, for a quick first test: ctl / 8 to ctr / 8,
        bpl +                       ; from 0)
        lda #0
        sta tc0
        beq ++
+       ldy ctl
        jsr _c8
        sta tc0
+       lda ctr+1
        ldy ctr
        jsr _c8
        sta tc1
        lda tby1,x
        bpl +
        clc
        adc ty
        sta ctb
        lda ty+1
        adc #$ff
        jmp ++
+       clc
        adc ty
        sta ctb
        lda ty+1
        adc #0
+       sta ctb+1
        .if !NOBALLS
        ldx #NB - 1                 ; the balloons and daggers: x from their sprite's left (oxl, oxh),
_b      lda oact,x                  ; y from its top (oy - 26): first, as a byte goes further
        bne +
        jmp _bn
+       lda oy,x
        sec
        sbc #26 - BBY0
        sta obt
        lda #0
        sbc #0
        sta obt+1
        lda ctb                     ; (its top <= his bottom)
        sec
        sbc obt
        lda ctb+1
        sbc obt+1
        bmi _bn
        lda oy,x
        sec
        sbc #26 - BBY1
        sta obb
        lda #0
        sbc #0
        sta obb+1
        lda obb                     ; (its bottom >= his top)
        sec
        sbc ctt
        lda obb+1
        sbc ctt+1
        bmi _bn
        lda oxl,x                   ; then x
        clc
        adc #BBX0
        sta obl
        lda oxh,x
        adc #0
        sta obl+1
        lda ctr                     ; (its left <= his right)
        sec
        sbc obl
        lda ctr+1
        sbc obl+1
        bmi _bn
        lda oxl,x
        clc
        adc #BBX1
        sta obr
        lda oxh,x
        adc #0
        sta obr+1
        lda obr                     ; (its right >= his left)
        sec
        sbc ctl
        lda obr+1
        sbc ctl+1
        bmi _bn
        jmp trogg_dies
_bn     dex
        bmi +
        jmp _b
+
        .endif
        lda #0                      ; the Scrubblies, gems and keys in his columns (colml, colmh:
        sta cml                     ; each column's, bit k Scrubbly k, then gem or key k - NS)
        sta cmh
        ldy tc0
-       lda colml,y
        ora cml
        sta cml
        lda colmh,y
        ora cmh
        sta cmh
        cpy tc1
        iny
        bcc -
        lda cml
        ora cmh
        bne +
_none   rts                         ; (none)
+       lda ctb+1                   ; and in his bands of 32 lines (bandml, bandmh), his y kept to
        bmi _none                   ; the level's 0-255
        beq +
        lda #7
        bne ++
+       lda ctb
        lsr
        lsr
        lsr
        lsr
        lsr
+       sta cband1
        lda ctt+1
        beq +
        bpl _none
        lda #0
        beq ++
+       lda ctt
        lsr
        lsr
        lsr
        lsr
        lsr
+       tay
        lda #0
        sta bml
        sta bmh
-       lda bandml,y
        ora bml
        sta bml
        lda bandmh,y
        ora bmh
        sta bmh
        cpy cband1
        iny
        bcc -
        lda cml
        and bml
        sta cml
        lda cmh
        and bmh
        sta cmh
        ora cml
        bne +
        rts                         ; (none: the usual)
+       ldx #0
_k      lsr cmh
        ror cml
        bcc _kn
        stx ck
        cpx #NS
        bcs _pk
        lda knocked,x               ; a Scrubbly (not yoyoed off): deadly
        bne _kr
        lda scbll,x
        sta obl
        lda scblh,x
        sta obl+1
        lda scbrl,x
        sta obr
        lda scbrh,x
        sta obr+1
        lda scbt,x
        sta obt
        lda scbb,x
        sta obb
        lda #0
        sta obt+1
        sta obb+1
        jsr overlap
        bcc _kr
        jmp trogg_dies
_pk     txa                         ; a gem or key: touched
        sec
        sbc #NS
        tax
        lda pkll,x
        sta obl
        lda pklh,x
        sta obl+1
        lda pkrl,x
        sta obr
        lda pkrh,x
        sta obr+1
        lda pkt,x
        sta obt
        lda pkb,x
        sta obb
        lda #0
        sta obt+1
        sta obb+1
        jsr overlap
        bcc _kr
        stx ptouch
        inc ptouchn
_kr     ldx ck
_kn     inx
        lda cml
        ora cmh
        beq +
        jmp _k
+       rts
_c8     sty tc1                     ; ((a, y) / 8: a column)
        lsr
        ror tc1
        lsr
        ror tc1
        lsr
        ror tc1
        lda tc1
        rts
; Do [obl, obr] x [obt, obb] and Trogg's box overlap? Carry set if so (x kept)
overlap lda ctr                     ; obl <= ctr
        sec
        sbc obl
        lda ctr+1
        sbc obl+1
        bmi _no
        lda obr                     ; obr >= ctl
        sec
        sbc ctl
        lda obr+1
        sbc ctl+1
        bmi _no
        lda ctb                     ; obt <= ctb
        sec
        sbc obt
        lda ctb+1
        sbc obt+1
        bmi _no
        lda obb                     ; obb >= ctt
        sec
        sbc ctt
        lda obb+1
        sbc ctt+1
        bmi _no
        sec
        rts
_no     clc
        rts

ctl     .word 0                     ; (Trogg's box)
ctr     .word 0
ctt     .word 0
ctb     .word 0
obl     .word 0                     ; (an object's)
obr     .word 0
obt     .word 0
obb     .word 0
cml     .byte 0                     ; (the objects in his columns)
cmh     .byte 0
ck      .byte 0
bml     .byte 0                     ; (the objects in his bands)
bmh     .byte 0
cband1     .byte 0
tc0     .byte 0                     ; (his columns)
tc1     .byte 0
ptouch  .byte $ff                   ; (the gem or key last touched; $ff: none yet)
ptouchn .byte 0                     ; (ticks touching one)
        .send high
