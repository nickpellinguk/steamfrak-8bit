; ---- Balloons and daggers: a port of the BBC version's spawn_hazards, spawn_balloon, spawn_dagger,
; random_x, random, find_mover and update_movers, with the numbers for Hard (or Insane): a balloon
; every BTIME ticks at the level's bottom, at a random x within half the spread of Trogg's, rising
; BV a tick; a dagger every DTIME at the top, aimed ahead of him (x + h * 4/3, h his height above
; it: it arrives about where he is), going left DX and down DY a tick; each held still MPAUSE ticks
; first. A balloon's gone off the top, a dagger off the bottom or the left. Run each tick while
; he's alive. Their places as the BBC version's: the image's origin (oxl/oxh/oxf, oy/oyh/oyf, 16.8),
; in the level's coordinates; mux.asm's game makes their sprites from them.
SPREAD  = INSANE ? 300 : 280
LEVH    = 256                       ; (A_1's height)

        .section high
hazards lda btim                    ; (the timers: 0, one now; the restart sets them so)
        beq +
        dec btim
        bne ++
+       jsr spawnb
        lda #BTIME
        sta btim
+       lda dtim
        beq +
        dec dtim
        bne ++
+       jsr spawnd
        lda #DTIME
        sta dtim
+       ldx #NB - 1                 ; then each moves
_m      lda oact,x
        bne +
        jmp _n
+       lda opause,x
        beq +
        dec opause,x
        jmp _n
+       lda oact,x
        cmp #2
        beq _dag
        lda oyf,x                   ; a balloon: up BV
        sec
        sbc #<BV
        sta oyf,x
        lda oy,x
        sbc #>BV
        sta oy,x
        lda oyh,x
        sbc #0
        sta oyh,x
        bmi _gone                   ; (off the top: y < 0)
        bpl _n
_dag    lda oxf,x                   ; a dagger: left DX, down DY
        sec
        sbc #<DX
        sta oxf,x
        lda oxl,x
        sbc #>DX
        sta oxl,x
        lda oxh,x
        sbc #0
        sta oxh,x
        lda oyf,x
        clc
        adc #<DY
        sta oyf,x
        lda oy,x
        adc #>DY
        sta oy,x
        lda oyh,x
        adc #0
        sta oyh,x
        lda oy,x                    ; (off the bottom: y >= the level's height, signed)
        cmp #<LEVH
        lda oyh,x
        sbc #>LEVH
        bvc +
        eor #$80
+       bpl _gone
        lda oxl,x                   ; (off the left: x <= -11, signed)
        cmp #<-10
        lda oxh,x
        sbc #>-10
        bvc +
        eor #$80
+       bmi _gone
        jmp _n
_gone   lda #0
        sta oact,x
_n      dex
        bmi +
        jmp _m
+       rts

; A free slot: y (carry clear), its fractions and pause cleared; or carry set if there's none
hfind   ldy #NB - 1
-       lda oact,y
        beq +
        dey
        bpl -
        sec
        rts
+       lda #0
        sta oxf,y
        sta oyf,y
        clc
        rts

; A balloon at the level's bottom (y LEVH - 4), at a random x within half the spread of his
spawnb  jsr hfind
        bcs _x
        sty hslot
        lda tx
        sta hmid
        lda tx+1
        sta hmid+1
        jsr randx
        ldy hslot
        lda #1
        sta oact,y
        lda hx
        sta oxl,y
        lda hx+1
        sta oxh,y
        lda #<(LEVH - 4)
        sta oy,y
        lda #>(LEVH - 4)
        sta oyh,y
        lda #MPAUSE
        sta opause,y
_x      rts

; A dagger at the top (y 4), aimed ahead of him: the middle of its range x + h + h * 85 / 256
; (h * 4/3), h = max(0, y - 4) (a byte: the level's 256 high)
spawnd  jsr hfind
        bcs _x
        sty hslot
        lda ty
        sec
        sbc #4
        tax
        lda ty+1
        sbc #0
        beq _hok
        bmi _hneg
        ldx #255                    ; (below 255: as far as it goes)
        bne _hok
_hneg   ldx #0                      ; (above 4: 0)
_hok    stx hh
        lda #0                      ; h * 85 / 256 (its high byte)
        sta hm
        lda #85
        sta hm+1
        lda #0
        ldy #8
-       lsr hm+1
        bcc +
        clc
        adc hh
+       ror
        dey
        bne -
        clc                         ; + h, + his x
        adc hh
        sta hmid
        lda #0
        adc #0
        sta hmid+1
        lda hmid
        clc
        adc tx
        sta hmid
        lda hmid+1
        adc tx+1
        sta hmid+1
        jsr randx
        ldy hslot
        lda #2
        sta oact,y
        lda hx
        sta oxl,y
        lda hx+1
        sta oxh,y
        lda #4
        sta oy,y
        lda #0
        sta oyh,y
        lda #MPAUSE
        sta opause,y
_x      rts

; hx = hmid - SPREAD / 2 + a random 0 to SPREAD
randx
-       jsr random
        lda hrng+1
        and #1
        sta hx+1
        lda hrng
        sta hx
        lda #<SPREAD                ; (more than the spread: again)
        cmp hx
        lda #>SPREAD
        sbc hx+1
        bcc -
        lda hx
        clc
        adc hmid
        sta hx
        lda hx+1
        adc hmid+1
        sta hx+1
        lda hx
        sec
        sbc #<(SPREAD / 2)
        sta hx
        lda hx+1
        sbc #>(SPREAD / 2)
        sta hx+1
        rts

; 16-bit xorshift random numbers (John Metcalf's 7/9/8 version, as the BBC version)
random  lda hrng+1
        lsr
        lda hrng
        ror
        eor hrng+1
        sta hrng+1
        ror
        eor hrng
        sta hrng
        eor hrng+1
        sta hrng+1
        rts

hrng     .byte $01, $5a              ; (the BBC version seeds it from the frame count; this, fixed)
hslot   .byte 0
hmid    .word 0
hx      .word 0
hh      .byte 0
hm      .word 0
        .send high
