; ---- Collisions, gems and keys
; collide: the C64's two stages. First Trogg's box (his frame's solid pixels' extent, tbx0 ...
; from geom.py) against each Scrubbly's, balloon's and dagger's (deadly) and each gem's and key's
; not yet picked up, in level coordinates (x pixels, y the C64's: gy). Where the boxes touch, the
; spans (each image's rows' leftmost and rightmost solid pixels: geom.py, from the images as the
; Atari draws them) decide: a hit if on some row they share his extent and its overlap (the BBC
; version's hit_test, as GameMaker's precise collisions). A key picked up, not the last, makes a
; checkpoint due; the last completes the level.
;
; The patch objects (screen.py: the gems and keys, then the Scrubblies; NPO, at most 24) gone
; (pgone: picked up, or knocked off by the yoyo; a bit each, object k's in byte pby,k, mask pbm,k)
; and those the map shows gone (pshow) are put together an object a frame: pkpatch, as the frame's
; built, puts its cells' codes (screen.py's, at most PMAX) into the clean map, before anything's
; drawn on them; pkprog, once it's built, makes the VBI's patch program (PROGP, run after the
; frame's program) write them on the screen, all but those something's drawn in this frame (their
; spare characters were started from the clean map's new codes, and their putting back writes
; those). So restarting (pkreset: pgone from pgone0) needs nothing more.
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
        ldy pby + NPK,x             ; (knocked off: not looked at)
        lda pbm + NPK,x
        and pgone,y
        bne csn
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
+
csn     ldx cpk
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
cplp    ldy pby,x                   ; (gone already: not looked at)
        lda pbm,x
        and pgone,y
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
        bcc +
        jmp cpnext
+
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
        bcs +
        jmp cpnext
+
        ldy pby,x                   ; picked up
        lda pbm,x
        ora pgone,y
        sta pgone,y
        lda pkkey,x
        beq cpnext
        stx cpk                     ; a key: the last? (all the keys' bits gone)
        lda pgone
        and #<KEYBITS
        cmp #<KEYBITS
        bne +
        lda pgone+1
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

; pkpatch: the first patch object whose gone-ness the map doesn't show, put right (one a frame):
; its cells' codes into the clean map, and it noted (ppn cells from ppp, gone or not: ppg) for
; pkprog. Run before anything's drawn.
pkpatch ldx #0
-       ldy pby,x
        lda pgone,y
        eor pshow,y
        and pbm,x
        bne +
        inx
        cpx #NPO
        bcc -
        lda #0                      ; (none)
        sta ppn
        rts
+       lda pshow,y                 ; (the map shows it as it is now)
        eor pbm,x
        sta pshow,y
        and pbm,x
        sta ppg                     ; (gone now: the gone codes, else those with it)
        lda pkpl,x
        sta ppp
        sta sp1
        lda pkph,x
        sta ppp+1
        sta sp1+1
        lda pkn,x
        sta ppn
        beq ppx
        tax
ppl     ldy #0                      ; each cell: its address in the clean map
        lda (sp1),y
        sta tmp
        iny
        lda (sp1),y
        sec
        sbc #(>SCREEN) - (>CLEAN)
        sta tmp+1
        ldy #4
        lda ppg
        bne +
        iny
+       lda (sp1),y
        ldy #0
        sta (tmp),y
        jsr ppnext
        dex
        bne ppl
ppx     rts
ppnext  lda sp1                     ; (the next cell's record: 6 bytes on)
        clc
        adc #6
        sta sp1
        bcc +
        inc sp1+1
+       rts

; pkprog: the VBI's patch program (PROGP: lda #code, sta cell, ..., rts) for the object pkpatch
; noted: each of its cells but those claimed this frame (in view, something drawn there). Run once
; the frame's drawn, before its claims are cleared.
pkprog  lda #<PROGP
        sta sp2
        lda #>PROGP
        sta sp2+1
        ldx ppn
        beq pgend
        lda ppp
        sta sp1
        lda ppp+1
        sta sp1+1
pgl     ldy #3                      ; in view? (its column less the first in view, 0-40)
        lda (sp1),y
        sec
        sbc leftc
        cmp #41
        bcs pgw
        sta stmp                    ; claimed? (the claims' row: clrl, clrh)
        dey
        lda (sp1),y
        tay
        lda clrl,y
        sta tmp
        lda clrh,y
        sta tmp+1
        ldy stmp
        lda (tmp),y
        bne pgn
pgw     ldy #0                      ; lda #code, sta cell
        lda #$a9
        sta (sp2),y
        ldy #4
        lda ppg
        bne +
        iny
+       lda (sp1),y
        ldy #1
        sta (sp2),y
        iny
        lda #$8d
        sta (sp2),y
        ldy #0
        lda (sp1),y
        ldy #3
        sta (sp2),y
        ldy #1
        lda (sp1),y
        ldy #4
        sta (sp2),y
        lda sp2
        clc
        adc #5
        sta sp2
        bcc pgn
        inc sp2+1
pgn     jsr ppnext
        dex
        bne pgl
pgend   lda #$60
        ldy #0
        sta (sp2),y
        rts

; pkreset: the patch objects gone as pgone0 (the restart's), the map put right a frame at a time
pkreset ldx #2
-       lda pgone0,x
        sta pgone,x
        dex
        bpl -
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
        ldy pby,x
        lda pbm,x
        and pshow,y
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

pby     .for i = 0, i < NPO, i += 1 ; (patch object i's bit: its byte, its mask)
        .byte i >> 3
        .endfor
pbm     .for i = 0, i < NPO, i += 1
        .byte 1 << (i & 7)
        .endfor
        .cerror NPO > 24, "more than 24 gems, keys and Scrubblies"
pgone   .fill 3                     ; (the patch objects picked up or knocked off: a bit each)
pshow   .fill 3                     ; (those the map shows gone)
pgone0  .fill 3                     ; (those gone at the restart: the checkpoint's)
ppn     .byte 0                     ; (the object pkpatch put right this frame: its cells, how many,
ppp     .word 0                     ;  where, gone or not)
ppg     .byte 0
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
