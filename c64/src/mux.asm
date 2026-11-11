; ---- The sprite multiplexer. Sprites 3-7 are shared out among the virtual sprites (0 is the
; cover; 1 and 2 are kept for Trogg).
;
; A sprite can be set up (pointer, colour, x, y, and $d010, $d017, $d01d, $d01b whole) in a row
; interrupt's tail, after the forced bad line: row k's *tick* (k + 1 here), one sprite a tick, for
; a sprite whose y is 62 + 8k or more, on a hardware sprite last shown no later than line 54 + 8k;
; or before the frame, in the last border tick (tick 0, four slots). Each row's interrupt must
; know which sprites are shown on its lines 3 and 4 (its masks), for its slide and tail.
;
; It's incremental: a sprite keeps its hardware sprite and tick from frame to frame while they
; still work (its tick early enough for its y; the sprites before and after it on its hardware
; sprite out of its way), and then only what's changed is written: its x and y, its record, the
; rows whose masks change (when it crosses a row's line 3 or 4), and the registers (when a
; hardware sprite changes kind, or a sprite crosses x 256). A sprite whose place stops working
; is dropped (a sprite kept before others, VFIRST, wins against one that isn't), and placed again
; with the new ones: at most four a frame, those kept before others first; the rest wait.
;
; The results go to the buffer not being shown (bufoff is 0 or 32), which the border switches to
; once it's ready (muxready). Each frame starts by copying the last frame's changes across from the
; buffer now shown, so the two keep step.

NV      = NS + NB               ; virtual sprites: the Scrubblies, the balls
VEXPY   = 1                     ; (vfl: expanded down,
VEXPX   = 2                     ;  ... across,
VBEHIND = 4                     ;  ... behind the characters,
VFIRST  = $40                   ;  ... kept before others,
VHIDE   = $80                   ;  ... not shown)
        .if INSANE              ; (the CPC port's settings: Hard, or Insane)
BTIME   = 60
DTIME   = 75
MPAUSE  = 45
BV      = 384                   ; (8.8 fixed point, a frame)
DX      = 266
DY      = 200
        .else
BTIME   = 120
DTIME   = 132
MPAUSE  = 55
BV      = 333
DX      = 225
DY      = 169
        .endif
PLACES  = 4                     ; sprites placed a frame, at most
NONE    = 25                    ; (rows: none, from 25 to 0)

oa      = zp + 66               ; (the multiplexer's: rows old and new)
ob      = zp + 67
nc      = zp + 68
nd      = zp + 69
mp      = zp + 70               ; (the hardware sprite's sprite before, after)
mn      = zp + 71
mbest   = zp + 72
mbl     = zp + 73
mbud    = zp + 74
mflg    = zp + 75
mptr    = zp + 76               ; (2)
ms      = zp + 78
bp      = zp + 79
bn      = zp + 80
mpass   = zp + 81
n3c     = zp + 82
n3d     = zp + 83
mwait   = zp + 84

; Once a frame, in the main program
muxframe
        .if MUXTIME
        sei                     ; (debug: the multiplexer's own cycles; the display suffers)
        lda #0
        sta stampi
        sta it
        ldx #7
-       sta cnt0,x
        dex
        bpl -
        jsr stamp
        .endif
        lda bufoff
        eor #32
        sta nb
        jsr replay
        .if MUXTIME
        jsr stamp
        .endif
        jsr game
        .if MUXTIME
        jsr stamp
        .endif
        jsr sort
        .if MUXTIME
        jsr stamp
        .endif
        jsr update
        .if MUXTIME
        jsr stamp
        lda rdn
        sta cnt0+5
        lda tdn
        sta cnt0+6
        cli
        .endif
muxdone lda #1
        sta muxready
        rts

        .if MUXTIME
stamp   ldx stampi              ; (debug: CIA 2's timer A, free running, at each stage)
        lda $dd04
        ldy $dd05
        sta mux0,x
        tya
        sta mux0+16,x
        inc stampi
        rts
stampi  .byte 0
stamp2  ldx it                  ; (debug: the time at each sprite of update's)
        lda $dd04
        ldy $dd05
        sta itlo,x
        tya
        sta ithi,x
        lda #0
        sta itp,x
        inc it
        rts
it      .byte 0
itlo    .fill 24
ithi    .fill 24
itp     .fill 24
cnt0    .fill 8
        .endif

; At the start: the model with no sprites shown, and both buffers with none (the cover's
; registers; each row the cover alone)
muxinit lda #<mdata             ; (all 0 first)
        sta mptr
        lda #>mdata
        sta mptr+1
        ldx #>(mdend - mdata + 255)
        ldy #0
        tya
-       sta (mptr),y
        iny
        bne -
        inc mptr+1
        dex
        bne -
        ldx #NV - 1
-       lda #$ff
        sta vh,x
        sta vprv,x
        sta vnxt,x
        lda #NONE
        sta v3lo,x
        sta v4lo,x
        dex
        bpl -
        lda #$ff
        ldx #63
-       sta e_n,x
        sta u_n,x
        dex
        bpl -
        ldx #25
-       sta tinst,x
        dex
        bpl -
        ldx #7
-       sta hwhead,x
        dex
        bpl -
        ldx #3
-       sta slotv,x
        dex
        bpl -
        lda #1
        ldx #ROWS - 1
-       sta mk3,x
        sta mk4,x
        dex
        bpl -
        ldx #ROWS - 1
-       ldy #1
        lda maskjm,y
        sta rowimm,x
        sta rowimm + 32,x
        lda masktl,y
        sta rowtl,x
        sta rowtl + 32,x
        lda maskth,y
        sta rowth,x
        sta rowth + 32,x
        dex
        bpl -
        lda #1
        sta t017
        sta t017 + 32
        sta t01d
        sta t01d + 32
        lda #0
        sta t010
        sta t010 + 32
        sta t01b
        sta t01b + 32
        rts

; The last frame's changes, from the buffer shown to the one being made: ticks (tdl, with what
; changed: 1 x and y, 2 the whole record, 4 the registers), and rows (rdl)
replay  ldy #0
_t      cpy tdn
        bcc +
        jmp _r
+       sty mj
        ldx tdl,y
        lda tdf,x
        sta mflg
        lda #0
        sta tdf,x
        txa
        bne _u
        ldx #3                  ; tick 0: its four slots
_s      stx mt
        txa
        ora bufoff
        tay
        txa
        ora nb
        tax
        lda e_x,y
        sta e_x,x
        lda e_y,y
        sta e_y,x
        lda mflg
        and #2
        beq +
        lda e_n,y
        sta e_n,x
        lda e_reg,y
        sta e_reg,x
        lda e_ptr,y
        sta e_ptr,x
        lda e_col,y
        sta e_col,x
+       ldx mt
        dex
        bpl _s
        lda mflg
        and #4
        beq _nx
        ldy bufoff
        ldx nb
        jsr cpregs
        jmp _nx
_u      ora nb
        tax                     ; (to)
        eor #32
        tay                     ; (from)
        lda u_x,y
        sta u_x,x
        lda u_y,y
        sta u_y,x
        lda mflg
        lsr
        beq _nx                 ; (x and y only)
        lsr
        bcc +
        lda u_n,y
        sta u_n,x
        lda u_reg,y
        sta u_reg,x
        lda u_ptr,y
        sta u_ptr,x
        lda u_col,y
        sta u_col,x
+       lda mflg
        and #4
        beq _nx
        jsr cpregs
_nx     ldy mj
        iny
        jmp _t
_r      ldy #0
_rl     cpy rdn
        bcs _rd
        ldx rdl,y
        lda #0
        sta rdf,x
        txa
        ora bufoff
        sta mt
        txa
        ora nb
        tax
        sty mj
        ldy mt
        lda rowimm,y
        sta rowimm,x
        lda rowtl,y
        sta rowtl,x
        lda rowth,y
        sta rowth,x
        ldy mj
        iny
        bne _rl
_rd     lda #0
        sta tdn
        sta rdn
        rts

cpregs  lda trch,y              ; (a tick's registers, list y to list x)
        sta trch,x
        lda t010,y
        sta t010,x
        lda t017,y
        sta t017,x
        lda t01d,y
        sta t01d,x
        lda t01b,y
        sta t01b,x
        rts

; ---- The game, such as it is: the Scrubblies follow the scroll; the balls bounce
game    ldx #NS - 1
-       lda sxlo,x              ; (the Scrubbly's place in the level, as sprite x at scroll 0)
        sec
        sbc scrx
        sta vxlo,x
        lda sxhi,x
        sbc scrx+1
        bmi _neg
        bne _hi
        lda #0                  ; 0-255
        beq _show
_hi     cmp #1                  ; 256-343: on the screen
        bne _hide
        lda vxlo,x
        cmp #344 - 256
        bcs _hide
        lda #1
        bne _show
_neg    cmp #$ff                ; -47 to -1: part on the screen, as 457-503 (PAL)
        bne _hide
        lda vxlo,x
        cmp #256 - 47
        bcc _hide
        clc
        adc #<504
        sta vxlo,x
        lda #1
_show   sta vxhi,x
        lda #VEXPY | VEXPX | VBEHIND | VFIRST
        bne _fl
_hide   lda #VEXPY | VEXPX | VBEHIND | VFIRST | VHIDE
_fl     sta vfl,x
        dex
        bpl -
        ; balloons and daggers (the CPC port's speeds and timings: one tick a frame): a balloon
        ; every BTIME frames at the bottom, rising; a dagger every DTIME at the top, falling and
        ; going left; each held still PAUSE frames first; in the level's x, scrolling with it
        dec btim
        bne +
        lda #BTIME
        sta btim
        lda #1
        jsr spawn
+       dec dtim
        bne +
        lda #DTIME
        sta dtim
        lda #2
        jsr spawn
+       ldx #NB - 1
_m      lda oact,x
        bne +
        jmp _hid
+       lda opause,x
        beq +
        dec opause,x
        jmp _pos
+       lda oact,x
        cmp #2
        beq _dag
        lda oyf,x               ; a balloon: up
        sec
        sbc #<BV
        sta oyf,x
        lda oy,x
        sbc #>BV
        sta oy,x
        cmp #20
        bcs _pos
        bcc _gone
_dag    lda oyf,x               ; a dagger: down, and left
        clc
        adc #<DY
        sta oyf,x
        lda oy,x
        adc #>DY
        sta oy,x
        cmp #251
        bcs _gone
        lda oxf,x
        sec
        sbc #<DX
        sta oxf,x
        lda oxl,x
        sbc #>DX
        sta oxl,x
        lda oxh,x
        sbc #0
        sta oxh,x
_pos    lda oxl,x               ; its sprite x: 31 + x - the scroll
        sec
        sbc scrx
        sta mt
        lda oxh,x
        sbc scrx+1
        sta mh
        lda mt
        clc
        adc #31
        sta vxlo + NS,x
        lda mh
        adc #0
        bmi _left
        beq _on
        cmp #1
        bne _hid
        lda vxlo + NS,x
        cmp #344 - 256
        bcs _hid
        lda #1
        bne _on
_left   lda oact,x              ; (off at the left: a dagger's gone, a balloon hidden)
        cmp #2
        beq _gone
        bne _hid
_on     sta vxhi + NS,x
        lda oy,x
        sta vy + NS,x
        .if BALLTEST
        lda #0                  ; (BALLTEST: in the left border, unseen but fetched)
        sta vxlo + NS,x
        sta vxhi + NS,x
        .endif
        lda #0
        .if NOBALLS
        lda #VHIDE
        .endif
        sta vfl + NS,x
        jmp _nm
_gone   lda #0
        sta oact,x
_hid    lda #VHIDE
        sta vfl + NS,x
_nm     dex
        bmi +
        jmp _m
+       rts

; A balloon (a = 1) or dagger (2) in a free slot, if there is one: x somewhere across the screen
spawn   ldx #NB - 1
-       ldy oact,x
        beq +
        dex
        bpl -
        rts
+       sta oact,x
        lda rnd                 ; (a random 0-255: an 8-bit Galois LFSR)
        asl
        bcc +
        eor #$1d
+       sta rnd
        clc
        adc #16
        sta mt
        lda #0
        adc #0
        sta mh
        lda scrx
        clc
        adc mt
        sta oxl,x
        lda scrx+1
        adc mh
        sta oxh,x
        lda #0
        sta oxf,x
        sta oyf,x
        lda #MPAUSE
        sta opause,x
        lda oact,x
        cmp #2
        beq +
        lda #250                ; a balloon: at the bottom, red
        sta oy,x
        lda #2
        sta vcol + NS,x
        rts
+       lda #47                 ; a dagger: at the top, white
        sta oy,x
        lda #1
        sta vcol + NS,x
        rts

; ---- Sort: the virtual sprites down the screen (order, kept from frame to frame, so nearly in
; order already: an insertion sort)
sort    ldx #1
_next   cpx #NV
        bcs _done
        stx mi
        lda order,x
        sta mcur
        tay
        lda vy,y
        sta mkey
        ldy mi
_shift  dey
        bmi _first
        ldx order,y
        lda vy,x
        cmp mkey
        bcc _put
        beq _put
        lda order,y
        sta order+1,y
        jmp _shift
_first  lda mcur
        sta order
        jmp _on
_put    lda mcur
        sta order+1,y
_on     ldx mi
        inx
        bne _next
_done   rts

; ---- Down the screen: each sprite shown, kept where it is if it still can be (and what's changed
; written), or dropped; then those not shown placed, as many as there's time for; then the
; registers if a hardware sprite's settings changed, and the rows' operands where they changed
update  lda #0
        sta regdirty
        sta mwait
        sta mo
_v
        .if MUXTIME
        jsr stamp2
        .endif
        ldx mo
        cpx #NV
        bcc +
        jmp pplace
+       ldy order,x
        sty mv
        lda vh,y
        bmi _un
        sta mh
        .if MUXTIME
        lda #1                  ; (debug: the path taken, 1 unchanged, 2 checked)
        ldx it
        sta itp-1,x
        ldy mv
        .endif
        lda vfl,y               ; y and settings as they were: nothing to check, only x, x's bit 8,
        cmp vflp,y              ; the pointer and the colour to see to (a clash with the sprites
        bne _ck                 ; around it is caught by theirs)
        lda vy,y
        cmp vyp,y
        bne _ck
        lda vxhi,y
        cmp vxhp,y
        beq +
        sta vxhp,y
        jsr attrof
        ldy mv
        sta va,y
        lda #1
        sta regdirty
+       jmp _chg
_un     lda vfl,y               ; (not shown: waiting to be placed?)
        bmi _nx
        lda vy,y
        cmp #47
        bcc _nx
        cmp #251
        bcs _nx
        inc mwait
        jmp _nx
_ck
        .if MUXTIME
        lda #2
        ldx it
        sta itp-1,x
        ldy mv
        .endif
        lda vfl,y
        bmi _rm
        lda vy,y
        cmp #47
        bcc _rm
        cmp #251
        bcs _rm
        sta my
        tax                     ; (its tick still early enough)
        lda mktab,x
        cmp vt,y
        bcc _rm
        jsr calcl
        ldy mv                  ; the sprite before it on its hardware sprite ends in time
        ldx vprv,y
        bmi _np
        lda vt,y
        beq _cf
        tay
        lda lim,y
        cmp vl,x
        bcs _np
_cf     stx mi                  ; (no: one of them goes)
        jmp _clash
_np     ldy mv                  ; it ends before the one after it is set up
        ldx vnxt,y
        bmi _ok
        lda vt,x
        tay
        lda lim,y
        cmp ml
        bcs _ok
        stx mi
        jmp _clash
_rm     jsr remove
        inc mwait
_nx     inc mo
        jmp _v
_ok     ldy mv                  ; kept: its rows, and what's changed
        lda ml
        sta vl,y
        jsr rngs
        jsr attrof
        ldy mv
        cmp va,y
        beq +
        sta va,y
        lda #1
        sta regdirty
+       lda vfl,y
        sta vflp,y
        lda vxhi,y
        sta vxhp,y
_chg    lda vptr,y
        cmp vpp,y
        bne _full
        lda vcol,y
        cmp vcp,y
        bne _full
        lda vy,y
        cmp vyp,y
        bne _xy
        lda vxlo,y
        cmp vxp,y
        beq _nx
_xy     jsr writexy
        jmp _nx
_full   jsr writerec
        jmp _nx
_clash  ldy mv                  ; sprite mv and mi clash: mi goes if it isn't kept before others
        lda vfl,y               ; and mv is, else mv; then mv again
        and #VFIRST
        beq _rm
        ldx mi
        lda vfl,x
        and #VFIRST
        bne _rm
        lda mv
        pha
        stx mv
        jsr remove
        pla
        sta mv
        jmp _v

; Those not shown placed (at most PLACES), kept before others first; a sprite kept before others
; that can't be may drop the nearest that isn't
pplace
        .if MUXTIME
        jsr stamp
        .endif
        lda mwait
        bne +
        jmp _done
+       lda #PLACES
        sta mbud
        lda #VFIRST
        sta mpass
_p      lda #0
        sta mo
_pv     ldx mo
        cpx #NV
        bcs _pe
        ldy order,x
        sty mv
        lda vh,y
        bpl _pn
        lda vfl,y
        bmi _pn
        and #VFIRST
        cmp mpass
        bne _pn
        lda vy,y
        cmp #47
        bcc _pn
        cmp #251
        bcs _pn
        lda mbud
        beq _done
        dec mbud
        jsr place
        bcs _pn
        lda mpass
        beq _pn
        jsr evict
        bcc _pn
        jsr place
_pn     inc mo
        jmp _pv
_pe     lda mpass
        beq _done
        lda #0
        sta mpass
        jmp _p
_done
        .if MUXTIME
        jsr stamp
        .endif
        lda regdirty
        beq +
        jsr sweep
+
        .if MUXTIME
        jsr stamp
        .endif
        jmp rowsfin

; Place sprite mv (c set if it is): the latest tick without a set-up, from the latest early
; enough for it up the screen (tick 0's slots last); then of the hardware sprites whose sprite
; before it there ends in time, and that it ends in time for the one after, the one whose sprite
; before ends latest
place
        .if MUXTIME
        inc cnt0+2
        .endif
        ldy mv
        lda vy,y
        sta my
        tax
        lda mktab,x
        sta mk
        jsr calcl
        ldx mk
        beq _t0
-       lda tinst,x
        bmi _tk
        dex
        bne -
_t0     ldy #3
-       lda slotv,y
        bmi _s0
        dey
        bpl -
        clc
        rts
_s0     sty ms
_tk     stx mt
        lda #$ff
        sta mbest
        ldx #3
_h      stx mh
        lda #$ff                ; (its neighbours down this hardware sprite)
        sta mp
        ldy hwhead,x
_w      bmi _wd
        lda vy,y
        cmp my
        bcs _wd
        sty mp
        lda vnxt,y
        tay
        jmp _w
_wd     sty mn
        ldy mp
        bmi _p1
        lda mt
        beq _hn
        ldx mt
        lda lim,x
        ldx mh
        cmp vl,y
        bcc _hn
_p1     ldy mn
        bmi _p2
        ldx vt,y
        lda lim,x
        ldx mh
        cmp ml
        bcc _hn
_p2     lda #0
        ldy mp
        bmi +
        lda vl,y
+       ldx mbest
        bmi _hb
        cmp mbl
        bcc _hn
_hb     sta mbl
        lda mh
        sta mbest
        lda mp
        sta bp
        lda mn
        sta bn
_hn     ldx mh
        inx
        cpx #8
        bne _h
        lda mbest
        bpl +
        clc
        rts
+
        .if MUXTIME
        inc cnt0+1
        .endif
        sta mh                  ; take it
        lda bp
        sta mp
        lda bn
        sta mn
        ldy mv
        lda mh
        sta vh,y
        lda mt
        sta vt,y
        lda ms
        sta vs,y
        lda ml
        sta vl,y
        lda mp
        sta vprv,y
        lda mn
        sta vnxt,y
        ldx mp
        bmi +
        tya
        sta vnxt,x
        jmp ++
+       ldx mh
        tya
        sta hwhead,x
+       ldx mn
        bmi +
        tya
        sta vprv,x
+       ldx mt
        bne +
        ldx ms
        tya
        sta slotv,x
        jmp ++
+       tya
        sta tinst,x
+       jsr rngs
        jsr attrof
        ldy mv
        sta va,y
        lda vfl,y
        sta vflp,y
        lda vxhi,y
        sta vxhp,y
        lda #1
        sta regdirty
        jsr writerec
        sec
        rts

; Sprite mv not placed: drop the nearest shown that isn't kept before others (c set if one is)
evict
        .if MUXTIME
        inc cnt0+3
        .endif
        lda #$ff
        sta mi
        sta mkey
        ldx #NV - 1
_e      lda vh,x
        bmi _en
        lda vfl,x
        and #VFIRST
        bne _en
        lda vy,x
        sec
        sbc my
        bcs +
        eor #$ff
        adc #1
+       cmp mkey
        bcs _en
        sta mkey
        stx mi
_en     dex
        bpl _e
        lda mi
        bpl +
        clc
        rts
+       lda mv
        pha
        lda mi
        sta mv
        jsr remove
        pla
        sta mv
        sec
        rts

; Drop sprite mv: off its hardware sprite's list, its tick freed, its rows cleared
remove
        .if MUXTIME
        inc cnt0
        .endif
        ldy mv
        ldx vprv,y
        lda vnxt,y
        cpx #$ff
        beq +
        sta vnxt,x
        jmp ++
+       ldx vh,y
        sta hwhead,x
+       ldx vnxt,y
        bmi +
        lda vprv,y
        sta vprv,x
+       ldx vt,y
        bne _u
        ldx vs,y
        lda #$ff
        sta slotv,x
        txa
        ora nb
        tax
        lda #$ff
        sta e_n,x
        ldx #0
        lda #2
        jsr dirtyt
        jmp _m
_u      lda #$ff
        sta tinst,x
        txa
        ora nb
        tay
        lda #$ff
        sta u_n,y
        lda #2
        jsr dirtyt
_m      ldy mv
        lda vh,y
        sta mh
        lda #0                  ; (rows: none)
        sta my
        sta ml
        jsr rngs
        ldy mv
        lda #$ff
        sta vh,y
        rts

; Sprite mv's last line (ml), from its y (my)
calcl   ldy mv
        lda vfl,y
        lsr
        lda my
        bcc +
        adc #42 - 1
        bcc ++
        lda #255
        bne ++
+       adc #21
        bcc +
        lda #255
+       sta ml
        rts

; Sprite mv's settings, for the registers: expanded down, across, behind, x's bit 8 (a)
attrof  ldy mv
        lda vxhi,y
        lsr
        lda vfl,y
        and #VEXPY | VEXPX | VBEHIND
        bcc +
        ora #8
+       rts

; Sprite mv's rows (on hardware sprite mh), from its rows before (v3lo ... v4hi) to those from my
; to ml: only the rows that change touched
rngs    ldy mv
        ldx my
        lda r4lo,x
        sta nc
        lda r3lo,x
        sta n3c
        ldx ml
        lda r4hi,x
        sta nd
        lda r3hi,x
        sta n3d
        lda nc
        cmp v4lo,y
        bne _ch
        lda nd
        cmp v4hi,y
        bne _ch
        lda n3c
        cmp v3lo,y
        bne _ch
        lda n3d
        cmp v3hi,y
        bne _ch
        rts
_ch     ldx mh
        lda bits,x
        sta mbit
        eor #$ff
        sta mkey
        lda v4lo,y
        sta oa
        lda v4hi,y
        sta ob
        lda nc
        sta v4lo,y
        lda nd
        sta v4hi,y
        lda oa
        cmp nc
        bne +
        lda ob
        cmp nd
        beq _l3
+       lda #<mk4
        sta mptr
        lda #>mk4
        sta mptr+1
        jsr rng
_l3     ldy mv
        lda v3lo,y
        sta oa
        lda v3hi,y
        sta ob
        lda n3c
        sta nc
        sta v3lo,y
        lda n3d
        sta nd
        sta v3hi,y
        lda oa
        cmp nc
        bne +
        lda ob
        cmp nd
        beq _x
+       lda #<mk3
        sta mptr
        lda #>mk3
        sta mptr+1
        jmp rng
_x      rts

; Rows oa to ob (before) to nc to nd (now), bit mbit in mptr's rows (mk3 or mk4): when they
; overlap, only the ends that moved (a row or so); else the old cleared and the new set
rng     lda oa
        cmp #NONE
        bne +
        lda nc                  ; (none before)
        sta mlo
        lda nd
        sta mhi
        jmp rset
+       lda nc
        cmp #NONE
        bne +
        lda oa                  ; (none now)
        sta mlo
        lda ob
        sta mhi
        jmp rclr
+       lda nc
        cmp ob
        beq +
        bcs _dis
+       lda nd
        cmp oa
        bcc _dis
        lda oa                  ; the top: down (cleared), or up (set)
        cmp nc
        bcs +
        sta mlo
        ldx nc
        dex
        stx mhi
        jsr rclr
+       lda nc
        cmp oa
        bcs +
        sta mlo
        ldx oa
        dex
        stx mhi
        jsr rset
+       lda nd                  ; the bottom: up (cleared), or down (set)
        cmp ob
        bcs +
        tax
        inx
        stx mlo
        lda ob
        sta mhi
        jsr rclr
+       lda ob
        cmp nd
        bcs +
        tax
        inx
        stx mlo
        lda nd
        sta mhi
        jmp rset
+       rts
_dis    lda oa
        sta mlo
        lda ob
        sta mhi
        jsr rclr
        lda nc
        sta mlo
        lda nd
        sta mhi
        jmp rset

rclr    ldy mlo                 ; (rows mlo to mhi: bit mbit cleared, and marked as changed)
-       cpy mhi
        beq +
        bcs ++
+       lda (mptr),y
        and mkey
        sta (mptr),y
        jsr rdirty
        iny
        bne -
+       rts

rset    ldy mlo                 ; (... set)
-       cpy mhi
        beq +
        bcs ++
+       lda (mptr),y
        ora mbit
        sta (mptr),y
        jsr rdirty
        iny
        bne -
+       rts

rdirty  lda rdf,y               ; (row y changed)
        bne +
        lda #1
        sta rdf,y
        ldx rdn
        tya
        sta rdl,x
        inc rdn
+       rts

dirtyt  sta mflg                ; (tick x changed: a, what)
        lda tdf,x
        bne +
        ldy tdn
        txa
        sta tdl,y
        inc tdn
        lda #0
+       ora mflg
        sta tdf,x
        rts

; Sprite mv's record (hardware sprite, pointer, colour, x, y) written for its tick; or just its
; x and y
writerec
        ldy mv
        lda vy,y
        sta vyp,y
        lda vxlo,y
        sta vxp,y
        lda vptr,y
        sta vpp,y
        lda vcol,y
        sta vcp,y
        ldx vt,y
        bne _u
        lda vs,y
        ora nb
        tax
        lda vh,y
        sta e_n,x
        asl
        sta e_reg,x
        lda vy,y
        sta e_y,x
        lda vxlo,y
        sta e_x,x
        lda vptr,y
        sta e_ptr,x
        lda vcol,y
        sta e_col,x
        ldx #0
        lda #3
        jmp dirtyt
_u      txa
        ora nb
        tax
        lda vh,y
        sta u_n,x
        asl
        sta u_reg,x
        lda vy,y
        sta u_y,x
        lda vxlo,y
        sta u_x,x
        lda vptr,y
        sta u_ptr,x
        lda vcol,y
        sta u_col,x
        ldx vt,y
        lda #3
        jmp dirtyt

writexy ldy mv
        lda vy,y
        sta vyp,y
        lda vxlo,y
        sta vxp,y
        ldx vt,y
        bne _u
        lda vs,y
        ora nb
        tax
        lda vy,y
        sta e_y,x
        lda vxlo,y
        sta e_x,x
        ldx #0
        lda #1
        jmp dirtyt
_u      txa
        ora nb
        tax
        lda vy,y
        sta u_y,x
        lda vxlo,y
        sta u_x,x
        ldx vt,y
        lda #1
        jmp dirtyt

; The registers down the ticks (only when a hardware sprite's settings changed): before the
; frame (tick 0's slots), then at each tick, whole, where they change (trch)
sweep
        .if MUXTIME
        inc cnt0+4
        .endif
        lda #0
        sta s010
        sta s01b
        ldx #7
-       sta hattr,x
        dex
        bpl -
        lda #1
        sta s017
        sta s01d
        lda #0
        sta ms
_s      ldx ms
        ldy slotv,x
        bmi +
        sty mv
        jsr setattr
+       inc ms
        lda ms
        cmp #4
        bne _s
        ldx nb
        jsr putregs
        ldx #0
        lda #4
        jsr dirtyt
        lda #1
        sta mt
_t      ldx mt
        ldy tinst,x
        bmi _tn
        sty mv
        jsr setattr
        lda mt
        ora nb
        tax
        lda mcur
        sta trch,x
        beq +
        jsr putregs
+       ldx mt
        lda #4
        jsr dirtyt
_tn     inc mt
        lda mt
        cmp #26
        bne _t
        rts

putregs lda s010
        sta t010,x
        lda s017
        sta t017,x
        lda s01d
        sta t01d,x
        lda s01b
        sta t01b,x
        rts

setattr jsr attrof              ; (sprite mv's settings into the registers: mcur, if they change)
        ldy mv
        ldx vh,y
        cmp hattr,x
        bne +
        lda #0
        sta mcur
        rts
+       sta hattr,x
        sta mfl
        lda bits,x
        sta mbit
        eor #$ff
        sta mkey
        lda s017
        and mkey
        lsr mfl
        bcc +
        ora mbit
+       sta s017
        lda s01d
        and mkey
        lsr mfl
        bcc +
        ora mbit
+       sta s01d
        lda s01b
        and mkey
        lsr mfl
        bcc +
        ora mbit
+       sta s01b
        lda s010
        and mkey
        lsr mfl
        bcc +
        ora mbit
+       sta s010
        lda #1
        sta mcur
        rts

; The rows whose masks changed: their slide constants and tails
rowsfin ldy #0
-       cpy rdn
        bcs +
        sty mj
        ldx rdl,y
        stx mi
        txa
        ora nb
        tay
        lda mk3,x
        tax
        lda maskjm,x
        sta rowimm,y
        ldx mi
        lda mk4,x
        tax
        lda masktl,x
        sta rowtl,y
        lda maskth,x
        sta rowth,y
        ldy mj
        iny
        bne -
+       rts

; ---- In the last border tick: the set-ups before the frame (tick 0's four slots)
apply0  ldx bufoff
        lda #4
        sta acnt
-       ldy e_n,x
        bmi +
        lda e_ptr,x             ; (the pointer: in the pair shown, set by usefront)
aps0    sta SCR0 + $3f8,y
aps1    sta SCR1 + $3f8,y
        lda e_col,x
        sta $d027,y
        ldy e_reg,x
        lda e_x,x
        sta $d000,y
        lda e_y,x
        sta $d001,y
+       inx
        dec acnt
        bne -
        rts

bits    .byte 1, 2, 4, 8, 16, 32, 64, 128
mux0    .fill 32
        .if SLACK
slackhi .fill 32
slacklo .fill 32, 255
frontc  .byte 0
nswap   .byte 0
nhold   .byte 0
        .endif

; ---- The virtual sprites
vy      .fill NV
vxlo    .fill NV
vxhi    .fill NV
vptr    .fill NV
vcol    .fill NV
vfl     .fill NV
order   .for i = 0, i < NV, i += 1
        .byte i
        .endfor
; (the balloons and daggers: kind (0 none, 1 balloon, 2 dagger), x in the level (and a fraction),
; y (and a fraction), frames still to wait at the start)
oact    .fill NB
oxl     .fill NB
oxh     .fill NB
oxf     .fill NB
oy      .fill NB
oyf     .fill NB
opause  .fill NB
btim    .byte 1
dtim    .byte 30
rnd     .byte 1
; (tables: the latest tick for a y; the line a hardware sprite's last use must end by, for a
; tick; the first and last rows shown on line 4 and line 3, for a y and a last line)
        .align $100
mktab   .for i = 0, i < 256, i += 1
        .byte i < 62 ? 0 : ((i - 62) >> 3) + 1
        .endfor
r4lo    .for i = 0, i < 256, i += 1
        .byte i < 47 ? NONE : (i - 47) >> 3
        .endfor
r3lo    .for i = 0, i < 256, i += 1
        .byte i < 47 ? NONE : (i - 46) >> 3
        .endfor
r4hi    .for i = 0, i < 256, i += 1
        .byte i < 55 ? 0 : ((i - 55) >> 3 > 24 ? 24 : (i - 55) >> 3)
        .endfor
r3hi    .for i = 0, i < 256, i += 1
        .byte i < 54 ? 0 : ((i - 54) >> 3 > 24 ? 24 : (i - 54) >> 3)
        .endfor
lim     .for i = 0, i < 26, i += 1
        .byte 46 + 8 * i
        .endfor
        .virtual $6000             ; (RAM only, set up by muxinit)
mdata
; (the multiplexer's model: for each virtual sprite, its hardware sprite ($ff: not shown), tick,
; slot (tick 0), last line, rows, settings as set up, and the sprites before and after it on its
; hardware sprite, down the screen)
vh      .fill NV
vt      .fill NV
vs      .fill NV
vl      .fill NV
v3lo    .fill NV
v3hi    .fill NV
v4lo    .fill NV
v4hi    .fill NV
va      .fill NV
vflp    .fill NV
vxhp    .fill NV
vyp     .fill NV
vxp     .fill NV
vpp     .fill NV
vcp     .fill NV
vprv    .fill NV
vnxt    .fill NV
hwhead  .fill 8
hattr   .fill 8
tinst   .fill 26           ; (each tick's sprite)
slotv   .fill 4            ; (tick 0's)
mk3     .fill ROWS           ; (each row's sprites on lines 3 and 4)
mk4     .fill ROWS
regdirty .byte 0
tdf     .fill 26                ; (changed this frame: ticks, and what; rows)
tdl     .fill 26
tdn     .byte 0
rdf     .fill ROWS
rdl     .fill ROWS
rdn     .byte 0
; (the two buffers: 32 each, by tick: tick 0's slots (e_*), each later tick's set-up (u_*:
; u_n $ff for none) and registers where they change (trch); and the rows' operands)
t010    .fill 64
t017    .fill 64
t01d    .fill 64
t01b    .fill 64
trch    .fill 64
e_n     .fill 64
e_reg   .fill 64
e_x     .fill 64
e_y     .fill 64
e_ptr   .fill 64
e_col   .fill 64
u_n     .fill 64
u_reg   .fill 64
u_y     .fill 64
u_x     .fill 64
u_ptr   .fill 64
u_col   .fill 64
rowimm  .fill 64
rowtl   .fill 64
rowth   .fill 64
mdend
        .endv
sprball .byte $00, $7e, $00, $01, $ff, $80, $07, $ff, $e0, $0f, $ff, $f0, $1f, $ff, $f8, $1f, $ff, $f8
        .byte $3f, $ff, $fc, $3f, $ff, $fc, $7f, $ff, $fe, $7f, $ff, $fe, $7f, $ff, $fe, $7f, $ff, $fe
        .byte $7f, $ff, $fe, $3f, $ff, $fc, $3f, $ff, $fc, $1f, $ff, $f8, $1f, $ff, $f8, $0f, $ff, $f0
        .byte $07, $ff, $e0, $01, $ff, $80, $00, $7e, $00, 0
