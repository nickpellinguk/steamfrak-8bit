; ---- Collisions, gems and keys
; collide: Trogg's box (his frame's solid pixels' extent, tbx0 ... from geom.py) against each
; Scrubbly's, balloon's and dagger's (kills him) and each gem's and key's not yet picked up (picks it up), in level
; coordinates (x pixels, y the C64's: gy), as the first stage of the C64's collide (its second,
; the spans, is still to come). A key picked up, not the last, makes a checkpoint due; the last
; completes the level.
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
        #cedge tbx0, tx, ctl
        #cedge tbx1, tx, ctr
        #cedge tby0, gy, ctt
        #cedge tby1, gy, ctb
        ldx #NSCR - 1               ; the Scrubblies
cslp    lda scbll,x                 ; (off if its left > his right, its right < his left, its top
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
        jsr overlap
        bcs +
        stx cpk
        jsr trogg_dies
        ldx cpk
+       dex
        bpl cslp
      .if !NOHAZ
        ldx #NHZ - 1                ; the balloons and daggers: each one's box from its origin
chlp    lda oact,x                  ; (hbx0 ..., by its kind: geom.py)
        beq chn
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
        jsr trogg_dies
        ldx cpk
chn     dex
        bpl chlp
      .endif
        ldx #NPK - 1                ; the gems and keys
cplp    lda pkbitl,x
        and pkgone
        bne cpnext
        lda pkbith,x
        and pkgone+1
        bne cpnext
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
        jsr overlap
        bcs cpnext
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
        bpl cplp
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
hbt     .byte 0
cbr     .word 0
cbt     .word 0                     ; (high bytes 0)
cbb     .word 0
