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
; There are three buffers (0, 32, 64), used in turn: one shown (bufoff), up to two finished and
; waiting to be shown (qn of them; the newest nlast), and so a frame can be made up to two ahead
; of the one shown (frak64.asm's nextframe, the border's tick 25). A frame is made in the buffer
; after nlast (nb), last made three frames ago: it starts by copying across from nlast what the
; two frames since changed, so the three keep step.

NV      = NS + NB + 1 + 2 + NB  ; virtual sprites: the Scrubblies, the balls, the yoyo, the FRAK!
                                ; bubble, the balloons' infill (BIV)
BIV     = NS + NB + 3
VEXPY   = 1                     ; (vfl: expanded down,
VEXPX   = 2                     ;  ... across,
VBEHIND = 4                     ;  ... behind the characters,
VLOW    = $20                   ;  ... placed after all others, and dropped for any of them,
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
matt    = zp + 85
mcm     = zp + 86
mbm     = zp + 87

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
        lda nlast               ; (the frame made last: copied from; the buffer after it: made)
        sta nf
        clc
        adc #32
        cmp #96
        bcc +
        lda #0
+       sta nb
        jsr replay
        #pst 16
        .if MUXTIME
        jsr stamp
        .endif
        jsr game
        #pst 18
        .if MUXTIME
        jsr stamp
        .endif
        jsr sort
        #pst 20
        .if MUXTIME
        jsr stamp
        .endif
        jsr update
        #pst 22
        .if MUXTIME
        jsr stamp
        lda rdn
        sta cnt0+5
        lda tdn
        sta cnt0+6
        cli
        .endif
muxdone rts

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

; At the start: the model with no sprites shown, and all three buffers with none (the cover's
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
        dex
        bpl -
        ldx #NV
        lda #NONE
-       sta v3lo,x
        sta v4lo,x
        dex
        bpl -
        lda #$ff
        ldx #95
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
        sta rowimm + 64,x
        lda masktl,y
        sta rowtl,x
        sta rowtl + 32,x
        sta rowtl + 64,x
        lda maskth,y
        sta rowth,x
        sta rowth + 32,x
        sta rowth + 64,x
        dex
        bpl -
        lda #1
        sta t017
        sta t017 + 32
        sta t017 + 64
        sta t01d
        sta t01d + 32
        sta t01d + 64
        lda #0
        sta t010
        sta t010 + 32
        sta t010 + 64
        sta t01b
        sta t01b + 32
        sta t01b + 64
        rts

; The two frames since this buffer was made: their changes, from the newest (nf) to it (nb):
; ticks (with what changed: 1 x and y, 2 the whole record, 4 the registers), and rows. The last
; frame's are in tdl (tdf), the one's before in tgl (tdg); then the last frame's become the one
; before's, for the next
replay  ldy #0                  ; ticks: the last frame's, what changed in either
-       cpy tdn
        bcs +
        sty mj
        ldx tdl,y
        lda tdf,x
        ora tdg,x
        jsr rtick
        ldy mj
        iny
        bne -
+       ldy #0                  ; then the frame before's, those not done already
-       cpy tgn
        bcs +
        sty mj
        ldx tgl,y
        lda tdf,x
        bne _tn
        lda tdg,x
        jsr rtick
_tn     ldy mj
        iny
        bne -
+       ldy tgn                 ; (the frame before's forgotten; the last frame's in its place)
-       dey
        bmi +
        ldx tgl,y
        lda #0
        sta tdg,x
        beq -
+       ldy #0
-       cpy tdn
        bcs +
        ldx tdl,y
        lda tdf,x
        sta tdg,x
        lda #0
        sta tdf,x
        txa
        sta tgl,y
        iny
        bne -
+       sty tgn
        lda #0
        sta tdn
        ldy #0                  ; rows: the last frame's
-       cpy rdn
        bcs +
        ldx rdl,y
        jsr rrow
        iny
        bne -
+       ldy #0                  ; then the frame before's, those not done already
-       cpy rgn
        bcs +
        ldx rgl,y
        lda rdf,x
        bne _rn
        jsr rrow
_rn     iny
        bne -
+       ldy rgn                 ; (and the generations moved on)
-       dey
        bmi +
        ldx rgl,y
        lda #0
        sta rdg,x
        beq -
+       ldy #0
-       cpy rdn
        bcs +
        ldx rdl,y
        lda #1
        sta rdg,x
        lda #0
        sta rdf,x
        txa
        sta rgl,y
        iny
        bne -
+       sty rgn
        lda #0
        sta rdn
        rts

; (row x's operands, from nf to nb; y kept)
rrow    sty mj
        txa
        ora nf
        tay
        txa
        ora nb
        tax
        lda rowimm,y
        sta rowimm,x
        lda rowtl,y
        sta rowtl,x
        lda rowth,y
        sta rowth,x
        ldy mj
        rts

; (tick x's changes a, from nf to nb)
rtick   sta mflg
        txa
        bne _u
        ldx #3                  ; tick 0: its four slots
_s      stx mt
        txa
        ora nf
        tay
        txa
        ora nb
        tax
        lda mflg
        and #2
        beq +
        lda e_x,y
        sta e_x,x
        lda e_y,y
        sta e_y,x
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
        beq _x
        ldy nf
        ldx nb
        jmp cpregs
_u      ora nf
        tay                     ; (from)
        txa
        ora nb
        tax                     ; (to)
        lda mflg
        lsr
        lsr
        bcc +
        lda u_x,y
        sta u_x,x
        lda u_y,y
        sta u_y,x
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
        beq _x
        jmp cpregs
_x      rts

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
game    lda scrx                ; (the Scrubblies: again only if the scroll's changed, or one's
        cmp gscx                ; been knocked off or put back: scrchg)
        bne +
        lda scrx+1
        cmp gscx+1
        bne +
        lda scrchg
        beq _bal
+       lda scrx
        sta gscx
        lda scrx+1
        sta gscx+1
        lda #0
        sta scrchg
        ldx #NS - 1
-       lda knocked,x           ; (yoyoed off: gone)
        bne _hide
        lda sxlo,x              ; (the Scrubbly's place in the level, as sprite x at scroll 0)
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
        ; the balloons and daggers (hazards.asm moves them): their sprites, the image's corner at
        ; its origin less (kxo, kyo), x 31 + that - the scroll, y 26 + that: x = its x - bx (each
        ; kind's: the scroll + kxo - 31, made here once), y = its y + kyc (each kind's: 26 - kyo)
_bal    ldy #2
-       lda scrx
        clc
        adc kxo,y
        sta mt
        lda scrx+1
        adc #0
        sta mh
        lda mt
        sec
        sbc #31
        sta bxl,y
        lda mh
        sbc #0
        sta bxh,y
        dey
        bne -
        ldx #NB - 1
        bne _m
_hid    lda #VHIDE
        sta vfl + NS,x
_ih     lda #VLOW | VHIDE
        sta vfl + BIV,x
_nm     dex
        bpl _m
        rts
_m      ldy oact,x
        beq _hid
        lda oxl,x
        sec
        sbc bxl,y
        sta vxlo + NS,x
        lda oxh,x
        sbc bxh,y
        bmi _hid
        beq _on
        cmp #1
        bne _hid
        lda vxlo + NS,x
        cmp #344 - 256
        bcs _hid
        lda #1
_on     sta vxhi + NS,x
        lda oy,x                    ; (y: 26 + its top, on the screen's lines 0-255)
        clc
        adc kyc,y
        sta vy + NS,x
        lda oyh,x
        adc kych,y
        bne _hid
        lda kptr,y                  ; (its sprite; its colour black, as all start)
        sta vptr + NS,x
        .if BALLTEST
        lda #0                      ; (BALLTEST: in the left border, unseen but fetched)
        sta vxlo + NS,x
        sta vxhi + NS,x
        .endif
        .if NOBALLS
        lda #VHIDE
        sta vfl + NS,x
        bne _ih
        .else
        lda #0
        sta vfl + NS,x
        .endif
        ; a balloon's infill (its magenta, hi-res: in front, as the outline is; their pixels
        ; don't meet), low priority, in one of two images: the pixels at the sprite's top (at the
        ; outline's y), or at its bottom (BIDY lines up), so there's a second place to try: place
        ; tries both at once, the first preferred; once placed, the one it took
        dey
        bne _ih
        lda vxlo + NS,x
        sta vxlo + BIV,x
        lda vxhi + NS,x
        sta vxhi + BIV,x
        lda vh + BIV,x              ; (not placed: shown as the first, for place to try both)
        bpl +
        lda #0
        sta bivar,x
+       lda vy + NS,x
        ldy bivar,x
        beq +
        sec
        sbc #BIDY
        bcs +
        lda #0                      ; (off the top: the first)
        sta bivar,x
        lda vy + NS,x
+       sta vy + BIV,x
        lda #(SPRBINF & $3fff) / 64
        clc
        adc bivar,x
        sta vptr + BIV,x
        lda #VLOW
        sta vfl + BIV,x
        jmp _nm
bxl     .fill 3
bxh     .fill 3
gscx    .word $ffff
scrchg  .byte 1
kptr    .byte 0, (SPRBALLOON & $3fff) / 64, (SPRDAGGER & $3fff) / 64   ; (each kind's sprite: 1 balloon, 2 dagger)

; ---- Sort: the virtual sprites down the screen (order, kept from frame to frame, so nearly in
; order already: an insertion sort)
sort    ldy order               ; (in order, mostly: each compared with the one before, and only
        lda vy,y                ; one that's out of order moved back to its place)
        sta mkey
        ldx #1
_next   cpx #NV
        bcs _done
        ldy order,x
        lda vy,y
        cmp mkey
        bcc _ins
        sta mkey
        inx
        bne _next
_ins    stx mi                  ; (higher than the one before: back to its place)
        sty mcur
        sta mlo
        ldy mi
_shift  dey
        bmi _first
        ldx order,y
        lda vy,x
        cmp mlo
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
_on     ldx mi                  ; (the one now here is the highest so far)
        ldy order,x
        lda vy,y
        sta mkey
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
        jsr troggmux
_v
        .if MUXTIME
        jsr stamp2
        .endif
        ldx mo
_vx     cpx #NV
        bcc +
        jmp pplace
+       ldy order,x
        lda vh,y
        bpl _shown
        lda vfl,y               ; (not shown, and hidden: nothing to do, quickly)
        bmi _skip
        stx mo
        sty mv
        jmp _un
_skip   inx
        bne _vx
_shown  stx mo
        sty mv
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
_un     jsr wadd                ; (not shown: waiting to be placed?)
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
        tax                     ; (its tick still early enough: if not, an earlier one)
        lda mktab,x
        cmp vt,y
        bcs +
        jsr retick
        bcs +
        jmp _rm
+       jsr calcl
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
        jsr wadd
_nx     inc mo
        jmp _v
_ok     ldy mv                  ; kept: its rows, and what's changed (its settings only if they
        lda ml                  ; could have: its flags or x's bit 8)
        sta vl,y
        jsr rngs
        ldy mv
        lda vfl,y
        cmp vflp,y
        bne +
        lda vxhi,y
        cmp vxhp,y
        beq _chg
+       jsr attrof
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
        lda vy,y                ; x and y: into the buffer being made, where it differs (so it's
        sta vyp,y               ; always up to date there: nothing to note, or copy across after)
        ldx vt,y
        bne _xu
        lda vs,y
        ora nb
        tax
        lda vy,y
        cmp e_y,x
        beq +
        sta e_y,x
+       lda vxlo,y
        sta vxp,y
        cmp e_x,x
        beq _nxj
        sta e_x,x
_nxj    jmp _nx
_xu     txa
        ora nb
        tax
        lda vy,y
        cmp u_y,x
        beq +
        sta u_y,x
+       lda vxlo,y
        sta vxp,y
        cmp u_x,x
        beq _nxj
        sta u_x,x
        jmp _nx
_full   jsr writerec
        jmp _nx
_clash  ldy mv                  ; sprite mv and mi clash: mi goes if it ranks below mv (kept
        lda vfl,y               ; before others, then the rest, then the low), else mv; then mv
        and #VFIRST | VLOW      ; again (the rank: the flags, VLOW flipped)
        eor #VLOW
        sta mrank
        ldx mi
        lda vfl,x
        and #VFIRST | VLOW
        eor #VLOW
        cmp mrank
        bcc +
        jmp _rm
+       lda mv
        pha
        stx mv
        jsr remove
        pla
        sta mv
        jmp _v

; Trogg's sprites (trogg.asm), for the multiplexer: nothing set up in the ticks of his rows
; (lists tres1 to tres2: anything there dropped, to be placed again); his lines (y + 1 to y + 42) in the rows' masks, as a virtual
; sprite of its own (NV, on hardware sprite "8": bits 1 and 2), only the rows that change; his
; rows' tails (rowsfin) when they move; bit 8 of his x in the registers
troggmux
        lda tres1                   ; (only when his rows change: nothing's set up there after)
        cmp tres1w
        bne +
        lda tres2
        cmp tres2w
        beq _kept
+       lda tres1
        sta tres1w
        lda tres2
        sta tres2w
        ldx tres1
-       cpx tres2
        beq +
        bcs _kept
+       jsr _free
        inx
        bne -
_kept
        lda #NV
        sta mv
        lda #8
        sta mh
        lda tpen + TY1
        clc
        adc #42
        bcc +
        lda #255
+       sta ml
        lda tpen + TY1              ; (his top above line 47, jumping from the top platform: from
        cmp #47                     ; row 0 still, not none, as r4lo and r3lo have it there for a
        bcs +                       ; sprite removed: his lines 3 and 4 there are his)
        lda #47
+       sta my
        jsr rngs
        lda tra                     ; (his rows' tails: the old ones and the new ones redone, the
        cmp traw                    ; row before for the x's move too)
        bne _rd
        lda trc
        cmp trcw
        beq +
_rd     ldy traw
        dey
        jsr _row
        ldy traw
        jsr _row
        ldy traw
        iny
        jsr _row
        lda trc
        sta trcw
        ldy tra
        sty traw
        dey
        jsr _row
        ldy tra
        jsr _row
        ldy tra
        iny
        jsr _row
+       lda tmsbb
        cmp tmsbw
        beq +
        sta tmsbw
        lda #1
        sta regdirty
+       rts
_free   cpx #1                      ; (not tick 0's slots: before the frame, nothing's drawn)
        bcc +
        lda tinst,x
        bmi +
        sta mv
        stx mt
        jsr remove
        ldx mt
+       rts
_row    cpy #ROWS
        bcs +
        jmp rdirty
+       rts
traw    .byte $ff                   ; (the rows and bit 8 last frame)
trcw    .byte $ff
tres1w  .byte $ff
tres2w  .byte $ff
tmsbw   .byte 0

; Sprite mv on the list of those waiting to be placed (wlist, mwait long), if it can be shown
wadd    ldy mv
        lda vfl,y
        bmi +
        lda vy,y
        cmp #47
        bcc +
        cmp #251
        bcs +
        ldx mwait
        tya
        sta wlist,x
        inc mwait
+       rts

; The settings (a) of the sprite before mv on its hardware sprite (0 if none): what the
; registers hold for that hardware sprite where mv is set up (kept so: the registers are swept
; whenever something would change that)
prevattr
        ldy mv
        ldx vprv,y
        bmi +
        lda va,x
        rts
+       lda #0
        rts

; Sprite mv moved up past its tick (a: the latest it may have now): moved to the latest free
; tick that's early enough, and after its hardware sprite's last use before it, keeping its
; hardware sprite (c set if it can be; not to tick 0: then it's dropped and placed again). If its
; set-up changes the registers, the new tick's are those in force there with its settings, and
; those set at the ticks it now comes before take its settings too
retick  sta mk
        lda vt,y
        sta mlim                ; (its tick now)
        lda #0
        ldx vprv,y
        bmi +
        lda vl,x
+       sta ms                  ; (the line the sprite before it ends on)
        ldx mk
_t      beq _no
        lda lim,x
        cmp ms
        bcc _no
        lda tinst,x
        bpl +
        cpx tres1
        bcc _yes
        cpx tres2
        beq +
        bcs _yes
+       dex
        jmp _t
_no     clc
        rts
_yes    stx mt
        lda mlim
        ora nb
        tax
        lda trch,x
        sta mcur                ; (whether its set-up changes the registers)
        ldx mlim                ; the old tick freed
        lda #$ff
        sta tinst,x
        txa
        ora nb
        tay
        lda #$ff
        sta u_n,y
        lda #2
        jsr dirtyt
        ldy mv                  ; the new one
        lda mt
        sta vt,y
        tax
        tya
        sta tinst,x
        lda mcur
        bne _regs
        txa                     ; (no register change)
        ora nb
        tax
        lda #0
        sta trch,x
        jmp _fin
_regs   ldx mh                  ; (its hardware sprite's bits, and its settings)
        lda bits,x
        sta mbit
        eor #$ff
        sta mkey
        lda va,y
        sta mfl
        ldx mt                  ; the registers in force before the new tick: the latest
-       dex                     ; set-up before it that sets them, or tick 0's
        beq +
        lda tinst,x
        bmi -
        txa
        ora nb
        tay
        lda trch,y
        beq -
        jmp ++
+       ldy nb
+       lda mt
        ora nb
        tax
        lda t010,y
        sta t010,x
        lda t017,y
        sta t017,x
        lda t01d,y
        sta t01d,x
        lda t01b,y
        sta t01b,x
        jsr setbits
        lda #1
        sta trch,x
        lda mt                  ; the ticks between: their registers with its settings
        sta mj
_b      inc mj
        ldx mj
        cpx mlim
        bcs _fin
        lda tinst,x
        bmi _b
        txa
        ora nb
        tax
        lda trch,x
        beq _b
        jsr setbits
        ldx mj
        lda #4
        jsr dirtyt
        jmp _b
_fin    ldx mt
        lda #4
        jsr dirtyt
        jsr writerec
        ldy mv
        sec
        rts

; List x's registers with sprite mv's settings (mfl) for its hardware sprite (mbit, mkey)
setbits lda mfl
        sta mcur
        lda t017,x
        and mkey
        lsr mcur
        bcc +
        ora mbit
+       sta t017,x
        lda t01d,x
        and mkey
        lsr mcur
        bcc +
        ora mbit
+       sta t01d,x
        lda t01b,x
        and mkey
        lsr mcur
        bcc +
        ora mbit
+       sta t01b,x
        lda t010,x
        and mkey
        lsr mcur
        bcc +
        ora mbit
+       sta t010,x
        rts

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
        lda #VFIRST | VLOW      ; (the passes, by rank: kept before others ($60), the rest ($20),
        sta mpass               ; the low (0), which evict nothing)
_p      lda #0
        sta mo
_pv     ldx mo
        cpx mwait
        bcs _pe
        ldy wlist,x
        sty mv
        lda vh,y
        bpl _pn
        lda vfl,y
        and #VFIRST | VLOW
        eor #VLOW
        cmp mpass
        bne _pn
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
        cmp #VLOW + 1           ; (the next rank down; the low get one try a frame, at most)
        lda #VLOW
        bcs +
        lda mbud
        beq _done
        lda #1
        sta mbud
        lda #0
+       sta mpass
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
        lda #0                  ; (pyb: the second image's y, for a balloon's infill; 0: none)
        sta pyb
        lda vfl,y
        and #VLOW
        beq +
        lda my                  ; (the low: a balloon's infill, shown as its first image; its
        sec                     ; second BIDY lines up, if that's on the screen)
        sbc #BIDY
        bcc +
        cmp #47
        bcc +
        sta pyb
+       jsr calcl               ; (ml: the first's last line)
        ldx mk
        jsr ftick
        lda #0
        rol
        sta pvt                 ; (the first's tick found)
        stx mt
        lda ms
        sta pmst
        lda #0
        sta pvb
        lda pyb
        beq _nb
        lda my                  ; the second's: its last line, its tick (the first's, if that's
        pha                     ; early enough for it too; else the next one free up the
        lda pyb                 ; screen from its own)
        sta my
        jsr calcl
        lda ml
        sta pmlb
        pla
        sta my
        jsr calcl
        ldx pyb
        lda mktab,x
        tax
        lda pvt
        beq +
        cpx mt
        bcc +
        ldx mt                  ; (the same tick, and slot)
        lda pmst
        sta ms
        sec
        bcs ++
+       jsr ftick
+       lda #0
        rol
        sta pvb
        stx ptb
        lda ms
        sta pmsb
_nb     lda pvt
        ora pvb
        bne +
        clc
        rts
+       jsr attrof              ; (its settings: a hardware sprite whose sprite before it has the
        sta matt                ; same is preferred, so its set-up changes no registers)
        lda #$ff
        sta mbest
        sta bbest
        lda mt
        sta ptt
        lda ml
        sta pmlt
        ldx #3
_h      stx mh
        lda #$ff                ; (its neighbours down this hardware sprite: for the first, and
        sta mp                  ; for the second, pmpb)
        sta pmpb
        ldy hwhead,x
_w      bmi _wd
        lda vy,y
        cmp my
        bcs _wd
        cmp pyb
        bcs +
        sty pmpb
+       sty mp
        lda vnxt,y
        tay
        jmp _w
_wd     sty mn
        lda pvt
        beq _hb2
        jsr hfit                ; (the first here)
        bcc _hb2
        ldx mbest
        bmi _hb
        ldx mcm
        cpx mbm
        bcc _hb2
        bne _hb
        cmp mbl
        bcc _hb2
_hb     sta mbl
        lda mcm
        sta mbm
        lda mh
        sta mbest
        lda mp
        sta bp
        lda mn
        sta bn
_hb2    lda pvb                 ; (the second here, unless the first fits somewhere already)
        beq _hn
        lda mbest
        bpl _hn
        ldy pmpb
        bmi +
        lda vnxt,y
        tay
        jmp ++
+       ldx mh
        ldy hwhead,x
+       sty mn
        sty pmnb
        lda pmpb
        sta mp
        lda ptb
        sta mt
        lda pmlb
        sta ml
        jsr hfit
        php
        pha
        lda ptt
        sta mt
        lda pmlt
        sta ml
        pla
        plp
        bcc _hn
        ldx bbest
        bmi _hbb
        ldx mcm
        cpx bbm
        bcc _hn
        bne _hbb
        cmp bbl
        bcc _hn
_hbb    sta bbl
        lda mcm
        sta bbm
        lda mh
        sta bbest
        lda pmpb
        sta bbp
        lda pmnb
        sta bbn
_hn     ldx mh
        inx
        cpx #8
        beq +
        jmp _h
+       lda mbest
        bpl _take
        lda bbest               ; (the first fits nowhere: the second, if it fits)
        bpl +
        clc
        rts
+       ldy mv                  ; (the second: its y, last line, tick, slot, image)
        lda pyb
        sta my
        sta vy,y
        lda pmlb
        sta ml
        lda ptb
        sta mt
        lda pmsb
        sta ms
        lda bbp
        sta bp
        lda bbn
        sta bn
        ldx mv
        lda #1
        sta bivar - BIV,x
        lda vptr,x
        clc
        adc #1
        sta vptr,x
        lda bbest
        jmp _tk2
_take   lda pmst                ; (the first: its slot)
        sta ms
        lda mbest
_tk2
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
        jsr prevattr            ; its settings those in force there already: no register
        ldy mv                  ; change (and none for the sprite after it), so no sweep
        cmp va,y
        beq +
        lda #1
        sta regdirty
        jmp ++
+       ldx mt
        beq +
        txa
        ora nb
        tax
        lda #0
        sta trch,x
        ldx mt
        lda #4
        jsr dirtyt
+       jsr writerec
        sec
        rts

; The first free tick from x up the screen (not one of Trogg's), else tick 0 with a free slot
; (ms): x, carry set; carry clear if none
ftick   cpx #0
        beq _t0
-       lda tinst,x
        bpl +
        cpx tres1
        bcc _f
        cpx tres2
        beq +
        bcs _f
+       dex
        bne -
_t0     ldy #3
-       lda slotv,y
        bmi _s0
        dey
        bpl -
        clc
        rts
_s0     sty ms
_f      sec
        rts

; Whether sprite mv fits on hardware sprite mh between mp and mn, set up at tick mt, ending on
; line ml: carry set if so, then mcm (1: the sprite before has its settings) and a (the line the
; sprite before ends on, 0 if none)
hfit    ldy mp
        bmi _p1
        lda mt
        beq _no
        ldx mt
        lda lim,x
        cmp vl,y
        bcc _no
_p1     ldy mn
        bmi _p2
        ldx vt,y
        lda lim,x
        cmp ml
        bcc _no
_p2     lda #0                  ; (the settings before it there: the same as its own?)
        ldy mp
        bmi +
        lda va,y
+       cmp matt
        beq +
        lda #0
        .byte $2c
+       lda #1
        sta mcm
        lda #0
        ldy mp
        bmi +
        lda vl,y
+       sec
        rts
_no     clc
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
        lda vfl,x               ; (only one ranking below the pass's)
        and #VFIRST | VLOW
        eor #VLOW
        cmp mpass
        bcs _en
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
        jsr prevattr            ; (its set-up changed the registers: the sprite after it may
        ldy mv                  ; have relied on that)
        cmp va,y
        beq +
        lda #1
        sta regdirty
+       ldy mv
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

; Sprite mv's record (hardware sprite, pointer, colour, x, y) written for its tick
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

; The registers down the ticks (only when a hardware sprite's settings changed): before the
; frame (tick 0's slots), then at each tick, whole, where they change (trch)
sweep
        .if MUXTIME
        inc cnt0+4
        .endif
        lda tmsbb                   ; (Trogg's x's bit 8)
        sta s010
        lda #0
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
        cmp trch,x
        bne +
        cmp #0                  ; (no writes there, before or now: nothing changed, nothing
        beq _tn                 ; for replay to copy)
+       sta trch,x
        cmp #0
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
        cpx tra
        beq _ta
        cpx trb
        beq _tb
        cpx trc
        beq _tc
        lda mk4,x
        tax
        lda masktl,x
        sta rowtl,y
        lda maskth,x
        sta rowth,y
_rn     ldy mj
        iny
        bne -
+       rts
_ta     lda mk4,x                   ; (Trogg's rows: their tails then change his sprites)
        tax
        lda masktla,x
        sta rowtl,y
        lda masktha,x
        sta rowth,y
        jmp _rn
_tb     lda mk4,x
        tax
        lda masktlb,x
        sta rowtl,y
        lda maskthb,x
        sta rowth,y
        jmp _rn
_tc     lda mk4,x
        tax
        lda masktlc,x
        sta rowtl,y
        lda maskthc,x
        sta rowth,y
        jmp _rn

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

bits    .byte 1, 2, 4, 8, 16, 32, 64, 128, 6     ; ("8": Trogg's, sprites 1 and 2)
mux0    .fill 32
        .if SLACK
slackhi .fill 32
slacklo .fill 32, 255
frontc  .byte 0
nswap   .byte 0
cwait   .byte 0
nhold   .byte 0
        .endif

; ---- The virtual sprites
vy      .fill NV
vxlo    .fill NV
vxhi    .fill NV
vptr    .fill NV
vcol    .fill NV
vfl     .fill NV
mrank   .byte 0
bivar   .fill NB                ; (each balloon's infill's image: 0 top, 1 bottom)
pyb     .byte 0                 ; (place's, for the infill's two images: the second's y, last
pmlb    .byte 0                 ;  line, tick, slot; whether each has a tick; the first's tick,
ptb     .byte 0                 ;  slot, last line; the second's neighbours; its best)
pmsb    .byte 0
pvt     .byte 0
pvb     .byte 0
ptt     .byte 0
pmst    .byte 0
pmlt    .byte 0
pmpb    .byte 0
pmnb    .byte 0
bbest   .byte 0
bbl     .byte 0
bbm     .byte 0
bbp     .byte 0
bbn     .byte 0
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
oyh     .fill NB
oyf     .fill NB
opause  .fill NB
btim    .byte 0                 ; (the balloons' and daggers' timers: 0, one at the next tick)
dtim    .byte 0
rnd     .byte 1
        .section high               ; (placed past the level map: frak64.asm)
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
        .send high
        .virtual MUXRAM            ; (RAM only, set up by muxinit)
mdata
; (the multiplexer's model: for each virtual sprite, its hardware sprite ($ff: not shown), tick,
; slot (tick 0), last line, rows, settings as set up, and the sprites before and after it on its
; hardware sprite, down the screen)
vh      .fill NV
vt      .fill NV
vs      .fill NV
vl      .fill NV
v3lo    .fill NV + 1               ; (NV: Trogg's)
v3hi    .fill NV + 1
v4lo    .fill NV + 1
v4hi    .fill NV + 1
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
tdg     .fill 26                ; (changed the frame before: ticks, and what; rows)
tgl     .fill 26
tgn     .byte 0
rdg     .fill ROWS
rgl     .fill ROWS
rgn     .byte 0
wlist   .fill NV
; (the three buffers: 32 each, by tick: tick 0's slots (e_*), each later tick's set-up (u_*:
; u_n $ff for none) and registers where they change (trch); and the rows' operands)
t010    .fill 96
t017    .fill 96
t01d    .fill 96
t01b    .fill 96
trch    .fill 96
e_n     .fill 96
e_reg   .fill 96
e_x     .fill 96
e_y     .fill 96
e_ptr   .fill 96
e_col   .fill 96
u_n     .fill 96
u_reg   .fill 96
u_y     .fill 96
u_x     .fill 96
u_ptr   .fill 96
u_col   .fill 96
rowimm  .fill 96
rowtl   .fill 96
rowth   .fill 96
mdend
        .endv
