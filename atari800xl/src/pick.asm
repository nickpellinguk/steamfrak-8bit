; ---- Collisions, gems and keys
; collide: the C64's two stages. First Trogg's box (his frame's solid pixels' extent, tbx0 ...
; from geom.py) against each Scrubbly's, balloon's and dagger's (deadly) and each gem's and key's
; not yet picked up, in level coordinates (x pixels, y the C64's: gy). Where the boxes touch, the
; spans (each image's rows' leftmost and rightmost solid pixels: geom.py, from the images as the
; Atari draws them) decide: a hit if on some row they share his extent and its overlap (the BBC
; version's hit_test, as GameMaker's precise collisions). A key picked up, not the last, makes a
; checkpoint due; the last completes the level.
;
; The gems and keys gone (pkgone, a bit each) and those the map shows gone (pkshow) are put
; together a gem or key a frame (pkpatch, while the frame's programs are built): its cells' codes
; (screen.py: at most PKMAX) into the clean map, and as entries in the frame's VBI program (and its
; putting back program, as their low bytes go together), before anything's drawn on them. So
; restarting (pkreset: pkgone from pkgone0) needs nothing more.
ctl     = tmp                       ; (2 each: Trogg's box)
ctr     = mdst
ctt     = msrc
ctb     = mlast                     ; (mlast, midx)
cpk     = mk
sp1     = $b4                       ; (2: his spans, from the row shared)
sp2     = $b6                       ; (2: its)

; the box's edge: a signed byte from table \tab (by his graphic, x) added to word \src
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
; carry clear if word \a > word \b (unsigned)
cgt     .macro a, b
        lda \b
        cmp \a
        lda \b+1
        sbc \a+1
        .endm

collide lda dead
        beq +
        rts
+       ldx tfr                     ; (his frame: the C64's numbering to the graphic)
        lda c2a,x
        tax
        stx tgfx
        #cedge tbx0, tx, ctl
        #cedge tbx1, tx, ctr
        #cedge tby0, gy, ctt
        #cedge tby1, gy, ctb
        ldx #NSCR - 1               ; the Scrubblies
cslp    stx cpk
        lda scbll,x                 ; (off if its left > his right, its right < his left, its top
        sta cbl                     ; > his bottom or its bottom < his top)
        lda scblh,x
        sta cbl+1
        lda scbrl,x
        sta cbr
        lda scbrh,x
        sta cbr+1
        lda scbt,x
        sta cbt
        lda scbb,x
        sta cbb
        lda #0
        sta cbt+1
        sta cbb+1
        jsr overlap
        bcs +
        lda scil,x                  ; (the boxes touch: the spans)
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
        bcc ++
        jsr trogg_dies
+
+       ldx cpk
        dex
        bpl cslp
      .if !NOHAZ
        ldx #NHZ - 1                ; the balloons and daggers: each one's box from its origin
chlp    lda oact,x                  ; (hbx0 ..., by its kind: geom.py)
        bne +
        jmp chn
+
        stx cpk
        tay
        dey
        lda oxl,x
        sta hb
        lda oxh,x
        sta hb+1
        lda hbx0,y
        jsr hbadd
        sta cbl
        stx cbl+1
        lda hbx1,y
        jsr hbadd
        sta cbr
        stx cbr+1
        ldx cpk
        lda oy,x
        sta hb
        lda oyh,x
        sta hb+1
        lda hby0,y
        jsr hbadd
        sta cbt
        stx cbt+1
        lda hby1,y
        jsr hbadd
        sta cbb
        stx cbb+1
        ldx cpk
        jsr overlap
        bcs chn
        ldy oact,x                  ; (the boxes touch: the spans, its image's corner the origin
        dey                         ; less kxo, kyo)
        lda oxl,x
        sec
        sbc kxo,y
        sta oil
        lda oxh,x
        sbc #0
        sta oil+1
        lda oy,x
        sec
        sbc kyo,y
        sta oit
        lda oyh,x
        sbc #0
        sta oit+1
        lda kspl,y
        sta osp
        lda ksph,y
        sta osp+1
        lda khz,y
        sta oh
        jsr spans
        bcc +
        jsr trogg_dies
+       ldx cpk
chn     dex
        bmi +
        jmp chlp
+
      .endif
        ldx #NPK - 1                ; the gems and keys
cplp    lda pkbitl,x                ; (gone already: not looked at)
        and pkgone
        sta cbl
        lda pkbith,x
        and pkgone+1
        ora cbl
        beq +
        jmp cpnext
+
        lda pkll,x
        sta cbl
        lda pklh,x
        sta cbl+1
        lda pkrl,x
        sta cbr
        lda pkrh,x
        sta cbr+1
        lda pkt,x
        sta cbt
        lda pkb,x
        sta cbb
        lda #0
        sta cbt+1
        sta cbb+1
        jsr overlap
        bcs cpnext
        stx cpk
        lda pkil,x                  ; (the boxes touch: the spans)
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
        jsr spans
        ldx cpk
        bcc cpnext
        lda pkbitl,x                ; picked up
        ora pkgone
        sta pkgone
        lda pkbith,x
        ora pkgone+1
        sta pkgone+1
        lda pkkey,x
        beq cpnext
        stx cpk                     ; a key: the last? (all the keys' bits gone)
        lda pkgone
        and #<KEYBITS
        cmp #<KEYBITS
        bne +
        lda pkgone+1
        and #>KEYBITS
        cmp #>KEYBITS
        bne +
        jsr level_complete
        ldx cpk
        jmp cpnext
+       lda #1                      ; (else a checkpoint due)
        sta savecp
        ldx cpk
cpnext  dex
        bmi +
        jmp cplp
+
        rts

; hb + a (signed): a low, x high (y kept)
hbadd   sta hbt
        clc
        adc hb
        pha
        lda hbt
        and #$80
        beq +
        lda #$ff
+       adc hb+1
        tax
        pla
        rts

; The second stage (the C64's spans): his frame's spans (tsp, by his graphic tgfx: his image's
; corner tx - xo, gy - yo, gr_h rows) and the object's (osp, oh rows, its image's corner oil,
; oit): carry set if on some row they share, his extent and its overlap. (The boxes touching, the
; images are within 64 of each other: positions biased by 128, so the comparisons are unsigned.)
spno    clc                         ; (no: the images too far apart, or no rows shared)
        rts
spans   ldx tgfx
        lda tspl,x
        sta sp1
        lda tsph,x
        sta sp1+1
        lda oil                     ; dx = its left - his: oil - tx + xo
        sec
        sbc tx
        sta sdx
        lda oil+1
        sbc tx+1
        sta sdy                     ; (the high byte, for now)
        lda sdx
        clc
        adc gr_xo,x
        sta sdx
        tay
        lda sdy
        adc #0
        jsr r64
        bne spno
        lda oit                     ; dy = its top - his: oit - gy + yo
        sec
        sbc gy
        sta sdy
        lda oit+1
        sbc gy+1
        sta srs                     ; (the high byte, for now)
        lda sdy
        clc
        adc gr_yo,x
        sta sdy
        tay
        lda srs
        adc #0
        jsr r64
        beq +
spn2    clc
        rts
+       lda gr_h,x                  ; the shared rows, his: max(0, dy) to min(his height, dy + oh)
        sta shh
        lda sdy
        bpl +
        lda #0
+       sta srs
        lda sdy
        clc
        adc oh
        bmi spn2
        beq spn2
        cmp shh
        bcc +
        lda shh
+       sec
        sbc srs
        beq spn2
        bcc spn2
        sta srows
        lda srs                     ; his spans from his row srs, its from its row srs - dy
        asl a
        clc
        adc sp1
        sta sp1
        bcc +
        inc sp1+1
+       lda srs
        sec
        sbc sdy
        asl a
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
sprow   lda (sp1),y
        cmp #$ff
        beq spskip                  ; (his row empty)
        sta stl
        lda (sp2),y
        cmp #$ff
        beq spskip                  ; (its)
        clc
        adc sdxb
        sta sto                     ; (its left)
        iny
        lda (sp1),y
        ora #$80
        cmp sto
        bcc spmiss                  ; (his right < its left)
        lda (sp2),y
        clc
        adc sdxb
        sta sto                     ; (its right)
        lda stl
        ora #$80
        sta stl
        lda sto
        cmp stl
        bcs sphit                   ; (its right >= his left: they meet)
spmiss  iny
        bne spnr
spskip  iny
        iny
spnr    dec srows
        bne sprow
        clc
        rts
sphit   sec
        rts

; (a, y: a signed 16-bit number, high, low) -64 to 63? Z set if so
r64     cmp #0
        beq r64p
        cmp #$ff
        bne r64no
        cpy #$c0
        bcc r64no
        lda #0
        rts
r64p    cpy #$40
        bcs r64no
        lda #0
        rts
r64no   lda #1
        rts

; carry clear if the box cbl-cbr, cbt-cbb overlaps his (x kept)
overlap #cgt cbl, ctr               ; its left > his right: off
        bcc ovno
        #cgt ctl, cbr               ; his left > its right
        bcc ovno
        #cgt cbt, ctb               ; its top > his bottom
        bcc ovno
        #cgt ctt, cbb               ; his top > its bottom
        bcc ovno
        clc
        rts
ovno    sec
        rts

; pkpatch: a gem or key whose gone-ness the map doesn't show yet, put right (one a frame): its cells
; into the clean map and this frame's programs. Run while the programs are empty.
pkpatch ldx #NPK - 1
-       lda pkbitl,x
        and pkgone
        sta cbl
        lda pkbitl,x
        and pkshow
        cmp cbl
        bne +
        lda pkbith,x
        and pkgone+1
        sta cbl
        lda pkbith,x
        and pkshow+1
        cmp cbl
        bne +
        dex
        bpl -
        rts
+       lda pkbitl,x                ; (the map shows it as it is now)
        eor pkshow
        sta pkshow
        lda pkbith,x
        eor pkshow+1
        sta pkshow+1
        lda pkbitl,x                ; gone now? (the gone codes, else the codes with it)
        and pkgone
        bne +
        lda pkbith,x
        and pkgone+1
+       sta cbt
        lda pkci+1,x
        sta cbb
        lda pkci,x
        tax
ppl     cpx cbb
        bcs ppend
        lda pkcl,x                  ; the cell's address, in the screen and the clean map
        ldy #3
        sta (wp),y
        sta (rp),y
        sta tmp
        lda pkch,x
        iny
        sta (wp),y
        sta (rp),y
        sec
        sbc #(>SCREEN) - (>CLEAN)
        sta tmp+1
        lda pkcg,x
        ldy cbt
        bne +
        lda pkcf,x
+       ldy #1
        sta (wp),y
        sta (rp),y
        ldy #0
        sta (tmp),y
        lda wp
        clc
        adc #5
        sta wp
        sta rp
        bcc +
        inc wp+1
        inc rp+1
+       inx
        bne ppl
ppend   rts

; pkreset: the gems and keys gone as pkgone0 (the restart's), the map put right a frame at a time
pkreset lda pkgone0
        sta pkgone
        lda pkgone0+1
        sta pkgone+1
        rts

; pklist: the keys not gone (as the map shows), in view or nearly, listed for their infill
pklist  lda nscrx                   ; (the view's left, less 32, and right, in level pixels)
        asl a
        sta cbl
        lda #0
        rol a
        sta cbl+1
        lda cbl
        sec
        sbc #32
        sta cbl
        bcs +
        dec cbl+1
+       lda cbl
        clc
        adc #<(320 + 32)
        sta cbr
        lda cbl+1
        adc #>(320 + 32)
        sta cbr+1
        ldx #NPK - 1
pkl     lda pkkey,x
        beq pkln
        lda pkbitl,x
        and pkshow
        bne pkln
        lda pkbith,x
        and pkshow+1
        bne pkln
        lda pkxl,x                  ; (left of the view's right, right of its left - 32)
        cmp cbr
        lda pkxh,x
        sbc cbr+1
        bcs pkln
        lda cbl
        cmp pkxl,x
        lda cbl+1
        sbc pkxh,x
        bpl pkln
        stx cpk
        lda #GR_KEY
        sta pg
        lda pkxl,x
        sta px
        lda pkxh,x
        sta px+1
        lda pkpd,x
        sta pd
        jsr addobj
        ldx cpk
pkln    dex
        bpl pkl
        rts

pkbitl  .for i = 0, i < NPK, i += 1
        .byte <(1 << i)
        .endfor
pkbith  .for i = 0, i < NPK, i += 1
        .byte >(1 << i)
        .endfor
        .cerror NPK > 16, "more than 16 gems and keys"
pkgone  .word 0                     ; (the gems and keys picked up: bit i)
pkshow  .word 0                     ; (those the map shows gone)
pkgone0 .word 0                     ; (those gone at the restart: the checkpoint's)
cbl     .word 0                     ; (an object's box)
hb      .word 0                     ; (hbadd's)
tgfx    .byte 0                     ; (his graphic)
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
shh     .byte 0
hbt     .byte 0
cbr     .word 0
cbt     .word 0                     ; (high bytes 0)
cbb     .word 0
