; ---- Collisions, by box (the first stage of the BBC version's check_collisions): Trogg's box (his
; frame's solid pixels' extent, as shown) against each object's, in the level's coordinates, all
; from the build (collide.inc). A Scrubbly (not yoyoed off) or a balloon or dagger kills him; a gem
; or key touched is picked up. Only the Scrubblies, gems and keys
; in his columns are looked at (a mask a column, from the build), the balloons and daggers by y
; first. The comparisons are signed: his box can reach above the level's top, jumping.
sp1     = zp + 94                   ; (2: his spans, the second stage's)
sp2     = zp + 96                   ; (2: its)
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
_b      lda oact,x                  ; (its kind: 1 balloon, 2 dagger)
        bne +
        jmp _bn
+       tay
        lda oy,x                    ; its image's corner: its origin less (kxo, kyo)
        sec
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
        lda oit                     ; its box: y first
        clc
        adc kby0,y
        sta obt
        lda oit+1
        adc #0
        sta obt+1
        lda ctb                     ; (its top <= his bottom)
        sec
        sbc obt
        lda ctb+1
        sbc obt+1
        bpl +
        jmp _bn
+       lda oit
        clc
        adc kby1,y
        sta obb
        lda oit+1
        adc #0
        sta obb+1
        lda obb                     ; (its bottom >= his top)
        sec
        sbc ctt
        lda obb+1
        sbc ctt+1
        bpl +
        jmp _bn
+       lda oil                     ; then x
        clc
        adc kbx0,y
        sta obl
        lda oil+1
        adc #0
        sta obl+1
        lda ctr                     ; (its left <= his right)
        sec
        sbc obl
        lda ctr+1
        sbc obl+1
        bpl +
        jmp _bn
+       lda oil
        clc
        adc kbx1,y
        sta obr
        lda oil+1
        adc #0
        sta obr+1
        lda obr                     ; (its right >= his left)
        sec
        sbc ctl
        lda obr+1
        sbc ctl+1
        bpl +
        jmp _bn
+       lda kspl,y                  ; the boxes touch: then the spans
        sta osp
        lda ksph,y
        sta osp+1
        lda kh,y
        sta oh
        stx ck
        jsr spans
        ldx ck
        bcc _bn
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
        bcs +
        jmp _kn
+
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
        lda #SCRH
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
        lda pkspl,x
        sta osp
        lda pksph,x
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
