; ---- The sprite multiplexer. Sprites 3-7 are shared out among the virtual sprites each frame
; (0 is the cover; 1 and 2 are kept for Trogg).
;
; The game sets the virtual sprites (vy ... vfl) and the main program, once a frame, sorts them
; down the screen and gives each a hardware sprite: one whose last use this frame has ended
; before the row tick that will set it up. A row tick (the row interrupt's tail, from line 4's
; cycle 55) can set a sprite whose y is 62 + 8k or more (row k's tick: then it's ready by line
; y, where the VIC looks for it) and whose hardware sprite was last shown no later than line
; 54 + 8k; a sprite above line 62 is set up before the frame, by the last border tick. If none
; is free, a sprite kept before others (vfl $40) takes one from a sprite that isn't, if it can.
;
; The result, for the frame after: which sprite each tick sets up, the registers that changes
; ($d010, $d017, $d01d, $d01b, whole), and from which sprites each row shows on its lines 3 and
; 4, the row interrupt's slide constant and tail. It goes to the buffer not being shown (bufoff
; is 0 or 32), which the last border tick switches to once it's ready (muxready).

NV      = NS + NB               ; virtual sprites: the Scrubblies, the balls
NI      = 16                    ; at most this many shown a frame
VEXPY   = 1                     ; (vfl: expanded down,
VEXPX   = 2                     ;  ... across,
VBEHIND = 4                     ;  ... behind the characters,
VFIRST  = $40                   ;  ... kept before others,
VHIDE   = $80                   ;  ... not shown)

; Once a frame, in the main program: the game's sprites, then the multiplexer
muxframe
        .if MUXTIME
        sei                         ; (debug: the multiplexer's own cycles; the display suffers)
        lda #0
        sta stampi
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
        jsr alloc
        .if MUXTIME
        jsr stamp
        .endif
        jsr build
        .if MUXTIME
        jsr stamp
        cli
        .endif
muxdone lda #1
        sta muxready
        rts

        .if MUXTIME
stamp   ldx stampi                  ; (debug: CIA 2's timer A, free running, at each stage)
        lda $dd04
        ldy $dd05
        sta mux0,x
        tya
        sta mux0+8,x
        inc stampi
        rts
stampi  .byte 0
        .endif

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
        ; the balls: across between 24 and 320 (sprite x), down between 48 and 229 (y)
        ldx #NB - 1
-       lda bdx,x
        bmi _left
        clc
        adc bxlo,x
        sta bxlo,x
        lda bxhi,x
        adc #0
        sta bxhi,x
        beq _y
        lda bxlo,x
        cmp #320 - 256
        bcc _y
        bcs _turnx
_left   clc
        adc bxlo,x
        sta bxlo,x
        lda bxhi,x
        adc #$ff
        sta bxhi,x
        bne _y
        lda bxlo,x
        cmp #24
        bcs _y
_turnx  lda bdx,x
        eor #$ff
        clc
        adc #1
        sta bdx,x
_y      lda by,x
        clc
        adc bdy,x
        sta by,x
        cmp #229
        bcs _turny
        cmp #48
        bcs _put
_turny  lda bdy,x
        eor #$ff
        clc
        adc #1
        sta bdy,x
_put    lda by,x
        sta vy + NS,x
        .if NOBALLS
        lda #VHIDE              ; (NOBALLS: the balls not shown)
        sta vfl + NS,x
        .endif
        .if BALLTEST
        lda #0                  ; (BALLTEST: in the left border, unseen but fetched)
        sta vxlo + NS,x
        sta vxhi + NS,x
        .else
        lda bxlo,x
        sta vxlo + NS,x
        lda bxhi,x
        sta vxhi + NS,x
        .endif
        dex
        bpl -
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

; ---- Allocate: down the screen, each sprite shown a hardware sprite and a tick to set it up
; (instances: iv ... iok): the latest tick without a set-up, from the latest that's early enough
; for it (mk) up the screen (tick 0, before the frame, takes 4), and of the hardware sprites free
; by then (hwmte: the first tick after a hardware sprite's last use), the one free latest. If
; none is, a sprite kept before others (VFIRST) takes the hardware sprite and tick of one that
; isn't, if it can.
alloc   ldx #25
        lda #$ff
-       sta tinst,x
        dex
        bpl -
        ldx #7
-       sta hwinst,x
        dex
        cpx #2
        bne -
        lda #0
        ldx #7
-       sta hwmte,x
        dex
        cpx #2
        bne -
        sta t0n
        sta ni
        sta mo
        jmp _v
_sk     jmp _skip               ; (not shown)
_v      ldx mo
        cpx #NV
        bcc +
        rts
+       ldy order,x
        sty mv
        lda vfl,y
        bmi _sk
        lda vy,y
        cmp #47
        bcc _sk
        cmp #251
        bcs _sk
        sta my
        lda vfl,y               ; its last line
        lsr                     ; (VEXPY)
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
        lda my                  ; the latest tick early enough: (y - 62) / 8 + 1 (0 above 62)
        sec
        sbc #62
        bcc +
        lsr
        lsr
        lsr
        clc
        adc #1
        bne ++
+       lda #0
+       sta mk
        tax                     ; the latest tick from there up without a set-up
        beq _t0
-       ldy tinst,x
        bmi _tok
        dex
        bne -
_t0     ldy t0n
        cpy #4
        bcs _evict
_tok    stx mt
        ldy #0                  ; the hardware sprite free by then, latest (y; 0: none)
        ldx #3
_h      lda hwmte,x
        cmp mt
        beq +
        bcs _hn
+       cpy #0
        beq _hb
        cmp hwmte,y
        bcc _hn
_hb     txa
        tay
_hn     inx
        cpx #8
        bne _h
        tya
        beq _evict
        tax
        jmp _take
_evict  ldy mv                  ; none: one from a sprite not kept before others, if this one is,
        lda vfl,y               ; at that one's tick, if this one can be set up then
        and #VFIRST
        beq _skip
        ldx #3
_e      ldy hwinst,x
        bmi _en
        lda iv,y
        sty mi
        tay
        lda vfl,y
        and #VFIRST
        bne _en
        ldy mi
        lda ik,y
        cmp mk
        beq +
        bcs _en
+       sta mt
        lda hwpmte,x
        cmp mt
        beq +
        bcs _en
+       lda #0                  ; (that one isn't shown)
        sta iok,y
        lda hwpmte,x
        sta hwmte,x
        ldy mt
        bne +
        dec t0n
        jmp _take
+       lda #$ff
        sta tinst,y
        jmp _take
_en     inx
        cpx #8
        bne _e
_skip   inc mo
        jmp _v
_take   ldy ni                  ; (x: the hardware sprite, mt: the tick)
        cpy #NI
        bcs _skip
        lda mv
        sta iv,y
        txa
        sta ih,y
        lda mt
        sta ik,y
        lda my
        sta iy,y
        lda ml
        sta il,y
        lda #1
        sta iok,y
        tya
        sta hwinst,x
        lda hwmte,x
        sta hwpmte,x
        lda ml                  ; (free from the tick (l - 46 + 7) / 8)
        sec
        sbc #39
        lsr
        lsr
        lsr
        sta hwmte,x
        ldx mt
        beq +
        tya
        sta tinst,x
        jmp ++
+       inc t0n
+       inc ni
        jmp _skip

; ---- Build, for the buffer not shown (nb): the registers and set-ups before the frame (tick 0;
; for the last border tick, apply: e_* from nb, tcount and tfirst), each later tick's set-up (u_*:
; at most one; and the registers, whole, where they change: trch), and the rows' operands from
; the sprites on their lines 3 and 4
build   lda bufoff
        eor #32
        sta nb
        lda #0                  ; (the registers: the cover only)
        sta s010
        sta s01b
        ldx #7
-       sta hattr,x
        dex
        bpl -
        lda #1
        sta s017
        sta s01d
        ldx nb                  ; before the frame
        stx ment
        lda #0
        sta mj
_z      ldy mj
        cpy ni
        bcs _zd
        lda iok,y
        beq _zn
        lda ik,y
        bne _zn
        sty mi
        jsr prepi
        ldx ment
        ldy mi
        lda ih,y
        sta e_n,x
        asl
        sta e_reg,x
        lda iy,y
        sta e_y,x
        ldy mv
        lda vxlo,y
        sta e_x,x
        lda vptr,y
        sta e_ptr,x
        lda vcol,y
        sta e_col,x
        inc ment
_zn     inc mj
        jmp _z
_zd     ldx nb
        lda ment
        sec
        sbc nb
        sta tcount,x
        txa
        sta tfirst,x
        lda s010
        sta t010,x
        lda s017
        sta t017,x
        lda s01d
        sta t01d,x
        lda s01b
        sta t01b,x
        ldx #1                  ; the ticks in order (x), and their lists (y)
        ldy nb
        iny
_tl     lda tinst,x
        bpl _tu
        sta u_n,y               ; ($ff: none)
        iny
        inx
        cpx #26
        bne _tl
        jmp _rows
_tu     sta mi
        stx mt
        sty ment
        jsr prepi
        ldx ment
        lda mcur
        sta trch,x
        beq +
        lda s010
        sta t010,x
        lda s017
        sta t017,x
        lda s01d
        sta t01d,x
        lda s01b
        sta t01b,x
+       ldy mi
        lda ih,y
        sta u_n,x
        asl
        sta u_reg,x
        lda iy,y
        sta u_y,x
        ldy mv
        lda vxlo,y
        sta u_x,x
        lda vptr,y
        sta u_ptr,x
        lda vcol,y
        sta u_col,x
        ldx mt
        ldy ment
        iny
        inx
        cpx #26
        bne _tl
_rows   ldx #0                  ; each row's slide constant and tail (unless it's the cover's
        ldy nb                  ; alone, and the buffer has those already); the rows' sprites
_r      lda mk3,x               ; reset for next time
        ora mk4,x
        cmp #1
        bne _rf
        lda rclean,y
        bne _rx
        lda #1
        bne +
_rf     lda #0
+       sta rclean,y
        stx mt
        lda mk3,x
        tax
        lda maskjm,x
        sta rowimm,y
        ldx mt
        lda mk4,x
        tax
        lda masktl,x
        sta rowtl,y
        lda maskth,x
        sta rowth,y
        ldx mt
        lda #1
        sta mk3,x
        sta mk4,x
_rx     iny
        inx
        cpx #ROWS
        bne _r
        rts

; Instance mi: the registers after it's set up (s010 ... s01b; mcur: whether they change, from
; its hardware sprite's last settings, hattr), and the rows it's shown on, on line 3 (54 + 8r)
; and line 4 (55 + 8r), from y + 1 to its last (mk3, mk4)
prepi   ldy mi
        ldx iv,y
        stx mv
        lda vxhi,x
        lsr
        lda vfl,x
        and #VEXPY | VEXPX | VBEHIND
        bcc +
        ora #8
+       sta mfl
        ldx ih,y
        stx mh
        lda bits,x
        sta mbit
        lda mfl
        cmp hattr,x
        bne +
        lda #0
        sta mcur
        jmp _marks
+       sta hattr,x
        lda mbit
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
_marks  ldy mi                  ; line 4 from row (y - 47) / 8, line 3 from (y - 46) / 8
        lda iy,y
        sec
        sbc #47
        lsr
        lsr
        lsr
        sta mlo
        lda iy,y
        sec
        sbc #46
        lsr
        lsr
        lsr
        tax
        lda il,y                ; line 4 to row (l - 55) / 8
        sec
        sbc #55
        lsr
        lsr
        lsr
        cmp #ROWS
        bcc +
        lda #ROWS - 1
+       sta mhi
        cpx mlo
        beq _mb
        ldy mlo                 ; (a row with line 4 only, at the top)
        cpy #ROWS
        bcs _mx
        lda mk4,y
        ora mbit
        sta mk4,y
_mb     cpx mhi                 ; rows with both
        beq +
        bcs _m3
+       lda mk3,x
        ora mbit
        sta mk3,x
        lda mk4,x
        ora mbit
        sta mk4,x
        inx
        bne _mb
_m3     ldy mi                  ; line 3 to row (l - 54) / 8: one more, with line 3 only?
        lda il,y
        sec
        sbc #54
        lsr
        lsr
        lsr
        cmp #ROWS
        bcs _mx
        cmp mhi
        beq _mx
        bcc _mx
        tax
        lda mk3,x
        ora mbit
        sta mk3,x
_mx     rts

; ---- In the interrupts: a tick's set-ups (y: the list, a: how many), and its registers
apply   sta acnt
        lda t010,y
        sta $d010
        lda t017,y
        sta $d017
        lda t01d,y
        sta $d01d
        lda t01b,y
        sta $d01b
        ldx tfirst,y
-       ldy e_n,x
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
        inx
        dec acnt
        bne -
        rts

bits    .byte 1, 2, 4, 8, 16, 32, 64, 128
mux0    .fill 16
        .if SLACK
slackhi .fill 32
slacklo .fill 32, 255
frontc  .byte 0
nswap   .byte 0
nhold   .byte 0
dbgn    .byte 0
dbgcol  .fill 256
dbgfc   .fill 256
dbgcc   .fill 256
dbgpr   .fill 256
dbgwk   .fill 256
dbgfr   .fill 256
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
; (the balls)
bxlo    .byte 40, 90, 140, 190, 240, 30
bxhi    .byte 0, 0, 0, 0, 0, 1
by      .byte 60, 100, 140, 180, 220, 80
bdx     .byte 1, $ff, 2, $fe, 1, $ff
bdy     .byte 1, 2, $ff, 1, $fe, 3
; (allocation)
iv      .fill NI
ih      .fill NI
ik      .fill NI
iy      .fill NI
il      .fill NI
iok     .fill NI
hwinst  .fill 8
hwmte   .fill 8
hwpmte  .fill 8
hattr   .fill 8
tinst   .fill 26
t0n     .byte 0
mk3     .fill ROWS, 1
mk4     .fill ROWS, 1
; (the two buffers: 32 each; the set-up lists by tick + 1, the set-ups, the rows' operands)
tcount  .fill 64
tfirst  .fill 64
t010    .fill 64
t017    .fill 64
t01d    .fill 64
t01b    .fill 64
e_n     .fill 64
e_reg   .fill 64
e_x     .fill 64
e_y     .fill 64
e_ptr   .fill 64
e_col   .fill 64
rowimm  .fill 64
u_n     .fill 64, $ff
u_reg   .fill 64
u_y     .fill 64
u_x     .fill 64
u_ptr   .fill 64
u_col   .fill 64
trch    .fill 64
rclean  .fill 64
rowtl   .fill 64
rowth   .fill 64
sprball .byte $00, $7e, $00, $01, $ff, $80, $07, $ff, $e0, $0f, $ff, $f0, $1f, $ff, $f8, $1f, $ff, $f8
        .byte $3f, $ff, $fc, $3f, $ff, $fc, $7f, $ff, $fe, $7f, $ff, $fe, $7f, $ff, $fe, $7f, $ff, $fe
        .byte $7f, $ff, $fe, $3f, $ff, $fc, $3f, $ff, $fc, $1f, $ff, $f8, $1f, $ff, $f8, $0f, $ff, $f0
        .byte $07, $ff, $e0, $01, $ff, $80, $00, $7e, $00, 0
