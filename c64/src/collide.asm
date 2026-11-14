; ---- Collisions, by box (the first stage of the BBC version's check_collisions): Trogg's box (his
; frame's solid pixels' extent, as shown) against each object's, in the level's coordinates, all
; from the build (collide.inc). A Scrubbly (not yoyoed off) or a balloon or dagger kills him; a gem
; or key touched is picked up. Only the Scrubblies, gems and keys
; in his columns are looked at (a mask a column, from the build), the balloons and daggers by y
; first. The comparisons are signed: his box can reach above the level's top, jumping.
sp1     = zp + 94                   ; (2: his spans, the second stage's)
sp2     = zp + 96                   ; (2: its)
ctl     = zp + 98                   ; (2 each: Trogg's box)
ctr     = zp + 100
ctt     = zp + 102
ctb     = zp + 104
obl     = zp + 106                  ; (2 each: an object's)
obr     = zp + 108
obt     = zp + 110
obb     = zp + 112
cml     = zp + 114                  ; (the objects in his columns, then also his bands)
cmh     = zp + 115
cbits   = zp + 116                  ; (the bits still to look at)
cdl     = zp + 117                  ; (a balloon's or dagger's dx or dy, low)
bmh     = zp + 118                  ; (his bands' objects, high)
cmx     = zp + 123                  ; (the third bytes: objects 16-23)
bmx     = zp + 124
        .section high
        .include "collide.inc"      ; tbx0 ... (Trogg's frames), scbll ... (the Scrubblies), pkll ...
                                    ; (the gems and keys), BBX0 ... (the ball sprite)
; (his box's edges from his place: a signed byte added to a word)
cedge   .macro tab, src, dst
        ldy #0
        lda \tab,x
        bpl +
        dey
+       clc
        adc \src
        sta \dst
        tya
        adc \src+1
        sta \dst+1
        .endm
collide lda dead
        beq +
        rts
+       ldx tfr                     ; his box: x tx + tbx0 to tx + tbx1, y ty + tby0 to ty + tby1
        #cedge tbx0, tx, ctl
        #cedge tbx1, tx, ctr
        #cedge tby0, ty, ctt
        #cedge tby1, ty, ctb
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
        .if !NOBALLS
        ; The balloons and daggers: the box test by its origin less his (dx, dy), against his
        ; frame's limits for its kind (collide.inc's cbxn1 ...; biased by $80, the max plus 1)
        ldy tfr
        lda cbxn1,y
        sta cbxn+1
        lda cbxn2,y
        sta cbxn+2
        lda cbxx1,y
        sta cbxx+1
        lda cbxx2,y
        sta cbxx+2
        lda cbyn1,y
        sta cbyn+1
        lda cbyn2,y
        sta cbyn+2
        lda cbyx1,y
        sta cbyx+1
        lda cbyx2,y
        sta cbyx+2
        ldx #NB - 1
_b      ldy oact,x                  ; (its kind: 1 balloon, 2 dagger)
        beq _bn
        lda oy,x                    ; dy, -128 to 127 or not near
        sec
        sbc ty
        sta cdl
        lda oyh,x
        sbc ty+1
        bne _yh
        lda cdl
        bpl _yt
_bn     dex
        bpl _b
        jmp _bdone
_yh     cmp #$ff
        bne _bn
        lda cdl
        bpl _bn
_yt     eor #$80
        cmp cbyn,y
        bcc _bn
        cmp cbyx,y
        bcs _bn
        lda oxl,x                   ; dx likewise (x from its sprite's left)
        sec
        sbc tx
        sta cdl
        lda oxh,x
        sbc tx+1
        bne _xh
        lda cdl
        bpl _xt
        bmi _bn
_xh     cmp #$ff
        bne _bn
        lda cdl
        bpl _bn
_xt     eor #$80
        cmp cbxn,y
        bcc _bn
        cmp cbxx,y
        bcs _bn
        lda oy,x                    ; the boxes touch: then the spans, from its image's corner,
        sec                         ; its origin less (kxo, kyo)
        sbc kyo,y
        sta oit
        lda oyh,x
        sbc #0
        sta oit+1
        lda oxl,x
        sec
        sbc kxo,y
        sta oil
        lda oxh,x
        sbc #0
        sta oil+1
        lda kspl,y
        sta osp
        lda ksph,y
        sta osp+1
        lda kh,y
        sta oh
        stx ck
        jsr spans
        ldx ck
        bcs +
        jmp _bn
+       jmp trogg_dies
_bdone
        .endif
        lda #0                      ; the enemies, gems and keys in his columns (colml, colmh, colmx:
        sta cmh                     ; each column's, bit k enemy k, then gem or key k - NS)
        sta cmx
        ldy tc0
-       ora colml,y
        tax
        lda colmh,y
        ora cmh
        sta cmh
        lda colmx,y
        ora cmx
        sta cmx
        txa
        cpy tc1
        iny
        bcc -
        sta cml
        ora cmh
        ora cmx
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
        sta bmh
        sta bmx
-       ora bandml,y
        tax
        lda bandmh,y
        ora bmh
        sta bmh
        lda bandmx,y
        ora bmx
        sta bmx
        txa
        cpy cband1
        iny
        bcc -
        and cml
        sta cml
        lda bmh
        and cmh
        sta cmh
        lda bmx
        and cmx
        sta cmx
        ora cmh
        ora cml
        bne +
        rts                         ; (none: the usual)
+       ldx #0                      ; each object whose bit is set, in A (cml, then cmh), shifted
        lda cml                     ; out a bit at a time, x its number
_k      lsr
        bcs _hit
        beq _kz
        inx
        bne _k
_kz     cpx #8                      ; (the rest of this byte clear: the next byte, or done)
        bcs _kz2
        ldx #8
        lda cmh
        bne _k
_kz2    cpx #16
        bcs +
        ldx #16
        lda cmx
        bne _k
+       rts
_hit    sta cbits                   ; (the bits left)
        stx ck
        cpx #NS
        bcs _pk
        lda knocked,x               ; a Scrubbly (not yoyoed off): deadly
        beq +
        jmp _kr
+
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
        bcs +
        jmp _kr
+
        lda scil,x                  ; (then the spans)
        sta oil
        lda scih,x
        sta oil+1
        lda scit,x
        sta oit
        lda #0
        sta oit+1
        lda #<scrsp
        sta osp
        lda #>scrsp
        sta osp+1
        lda lv_scrh                 ; (the level's enemy's height)
        sta oh
        jsr spans
        bcs +
        jmp _kr
+
        jmp trogg_dies
_pk     txa                         ; a gem or key (not picked up yet): touched, picked up
        sec
        sbc #NS
        tax
        lda picked,x
        beq +
        jmp _kr
+
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
        bcs +
        jmp _kr
+
        lda pkil,x                  ; (then the spans)
        sta oil
        lda pkih,x
        sta oil+1
        lda pkit,x
        sta oit
        lda #0
        sta oit+1
        ldy pkkind,x                ; (its kind's spans: 1 a gem's, 2 a key's)
        lda pkspk,y
        sta osp
        lda pkspkh,y
        sta osp+1
        lda pkh,x
        sta oh
        stx ckp
        jsr spans
        ldx ckp
        bcs +
        jmp _kr
+
        stx ptouch
        inc ptouchn
        jsr pickup
_kr     ldx ck
        lda cbits
        bne +
        jmp _kz
+       inx
        jmp _k
_c8     sty tc1                     ; ((a, y) / 8: a column)
        lsr
        ror tc1
        lsr
        ror tc1
        lsr
        ror tc1
        lda tc1
        rts
; The second stage (the BBC version's hit_test, as GameMaker's precise collisions): his frame's
; spans (each row's leftmost and rightmost solid pixel, as the C64 shows him) and the object's
; (osp, oh rows), its image's corner (oil, oit) against his (tx - tleft, ty - 34): carry set if on
; some row they share, his extent and its overlap. (The boxes touching, the images are within 64
; of each other; positions biased by 128, so the comparisons are unsigned.)
spno    clc                         ; (no: the images too far apart, or no rows shared)
        rts
spans   ldx tfr
        lda tspl,x
        sta sp1
        lda tsph,x
        sta sp1+1
        lda oil                     ; dx = its left - his: oil - tx + tleft
        sec
        sbc tx
        sta sdx
        lda oil+1
        sbc tx+1
        sta sdy                     ; (the high byte, for now)
        lda sdx
        clc
        adc tleft,x
        sta sdx
        tax
        lda sdy
        adc #0
        jsr r64
        bne spno
        lda oit                     ; dy = its top - his: oit - ty + 34
        sec
        sbc ty
        sta sdy
        lda oit+1
        sbc ty+1
        sta srs                     ; (the high byte, for now)
        lda sdy
        clc
        adc #34
        sta sdy
        tax
        lda srs
        adc #0
        jsr r64
        beq _sh
_e      clc                         ; (no)
        rts
_sh     lda sdy                     ; the shared rows, his: max(0, dy) to min(34, dy + oh)
        bpl +
        lda #0
+       sta srs
        lda sdy
        clc
        adc oh
        bmi _e
        beq _e
        cmp #34
        bcc +
        lda #34
+       sec
        sbc srs
        beq _e
        bcc _e
        sta srows
        lda srs                     ; his spans from his row srs, its from its row srs - dy
        asl
        clc
        adc sp1
        sta sp1
        bcc +
        inc sp1+1
+       lda srs
        sec
        sbc sdy
        asl
        clc
        adc osp
        sta sp2
        lda osp+1
        adc #0
        sta sp2+1
        lda sdx
        eor #$80
        sta sdxb
        ldy #0
_row    lda (sp1),y
        cmp #$ff
        beq _skip                   ; (his row empty)
        sta stl
        lda (sp2),y
        cmp #$ff
        beq _skip                   ; (its)
        clc
        adc sdxb
        sta sto                     ; (its left)
        iny
        lda (sp1),y
        ora #$80
        cmp sto
        bcc _miss                   ; (his right < its left)
        lda (sp2),y
        clc
        adc sdxb
        sta sto                     ; (its right)
        lda stl
        ora #$80
        sta stl
        lda sto
        cmp stl
        bcs _shit                   ; (its right >= his left: they meet)
_miss   iny
        bne _nr
_skip   iny
        iny
_nr     dec srows
        bne _row
_sno    clc
        rts
_shit   sec
        rts

; (a, x: a signed 16-bit number, high, low) -64 to 63? Z set if so
r64     cmp #0
        beq _p
        cmp #$ff
        bne _bad
        cpx #$c0
        bcc _bad
        lda #0
        rts
_p      cpx #$40
        bcs _bad
        lda #0
        rts
_bad    lda #1
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

cbxn    .fill 3                     ; (his frame's limits for the balloon (1), the dagger (2))
cbxx    .fill 3
cbyn    .fill 3
cbyx    .fill 3
ck      .byte 0
cband1     .byte 0
ckp     .byte 0
oil     .word 0                     ; (the second stage: the object's image's corner, spans, rows)
oit     .word 0
osp     .word 0
oh      .byte 0
sdx     .byte 0                     ; (its image from his: x, y, signed)
sdy     .byte 0
sdxb    .byte 0
srs     .byte 0
srows   .byte 0
stl     .byte 0
sto     .byte 0
tc0     .byte 0                     ; (his columns)
tc1     .byte 0
ptouch  .byte $ff                   ; (the gem or key last touched; $ff: none yet)
ptouchn .byte 0                     ; (ticks touching one)
        .send high
