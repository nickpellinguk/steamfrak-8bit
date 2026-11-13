; ---- Trogg on the screen: sprites 1 (his black outline, hi-res, in front) and 2 (his infill,
; multicolour: yellow and magenta), 24 wide. He's 34 lines high, a sprite 21, so each is used twice
; down him (tools/trogg.mjs): the first instances (y, blocks P1) set up in border tick 37; then in
; the tick of the row whose tick falls in his lines 13-20 (row (y - 35) / 8: its tail's write
; reaches the VIC from line 56 or 57 of the row), the second instances (y + 21) and the pointers to
; P2 (the same as P1 in rows 13-20, then his lines 21-33); and in the next row's tick, the pointers
; to P3 (P2 without its rows 13-20, which would show again below his feet). His 26-wide frames
; (standing, walking) have their snout and their back at opposite ends: his head (lines 0-16) is cut
; 2 pixels toward the snout from his body (lines 6-33), and his x moves those 2 pixels (trdx) in
; the tick of the row before (trc: from his lines 7-14), with the pointers to P1b (P1 cut as the
; body); or, if there's no row before (at the top of the screen), in P2's own. Those rows have
; tails of their own
; (tails.inc's a, b and c kinds, chosen by the multiplexer's row tables). The
; multiplexer sets nothing up in the ticks of the rows whose tails run while he's drawn (his
; sprites take the time).
;
; The main program works out the settings for the frame after (tpen), and the border makes them
; Trogg's (tact) when it switches to that frame (with the multiplexer's buffer, and the scroll).

        .include "trogg.inc"        ; TFRAMES, trleft
TROGGP  = (TROGG & $3fff) / 64      ; (the blocks; tblk: frame f's, 6f + 0-2 outline, 3-5 infill)
TY1     = 0                         ; (tpen, tact: his sprites' y,
TY2     = 1                         ;  the second instances' y,
TXL     = 2                         ;  x (bit 8: tmsbb, in the multiplexer's registers),
TXL2    = 3                         ;  x from the move (trdx) partway down him,
TM2     = 4                         ;  its bit 8 ($d010's bits 1 and 2),
TP1O    = 5                         ;  the pointers: outline P1, P1b, P2, P3,
TP1I    = 9                         ;  infill likewise,
TXK     = 13                        ;  the timer's reading when the x can move on line 6; 0:
                                    ;  on line 7, he's too far right;
TXA     = 14                        ;  the x to move in P2's tick: no row before)
TSET    = 15

; His sprites' settings for the frame after, from his place (tx: x in the level, ty: his feet's y
; in the level, as the BBC and CPC versions keep them) and frame (tfr), and the scroll; and for the
; multiplexer, the rows of his ticks (tra; trb the next), the ticks it's to leave alone (lists
; tres1 to tres2: the rows whose tails, lines 55 + 8r to 61 + 8r, run while he's drawn, lines y + 1
; to y + 42), and bit 8 of his x
trogset lda jumping                 ; (hidden while the camera jumps back to the start: y 255)
        beq +
        lda #7
        bne ++
+       lda ty+1                    ; y = the line before his top: (ty - 34) + 27 - 1
        beq +
        lda #255                    ; (fallen off the bottom: under the screen)
        .byte $2c
+       lda ty
+
        sec
        sbc #8
        sta tpen + TY1
        clc
        adc #21
        sta tpen + TY2
        ldx tfr                     ; x = 31 + (tx - his frame's left) - the scroll
        lda tx
        sec
        sbc trleft,x
        sta mt
        lda tx+1
        sbc #0
        sta mh
        lda mt
        clc
        adc #31
        sta mt
        lda mh
        adc #0
        sta mh
        lda mt
        sec
        sbc scrx
        sta tpen + TXL
        sta mt
        lda mh
        sbc scrx+1
        sta mh
        and #1
        beq +
        lda #6                      ; (sprites 1 and 2)
+       sta tmsbb
        ldy mh                      ; (the x's move on line 6 for x 240 or less, once the beam's at
        bne _txr                    ; cycle 17 + (x + 27) / 8, the reading 246 - (x + 27) / 8: at
        lda mt                      ; most a few cycles into line 7 at x 240, still before him. The
        cmp #241                    ; move from line 7's start, measured, misses him only from x
        bcs _txr                    ; 180 on)
        adc #27
        ror
        lsr
        lsr
        eor #$ff
        sec
        adc #246
        bne _txk                    ; (always: 213 or more)
_txr    lda #0
_txk    sta tpen + TXK
        ldy #0                      ; and from the move partway down him: x + trdx (signed)
        lda trdx,x
        bpl +
        dey
+       clc
        adc mt
        sta tpen + TXL2
        tya
        adc mh
        and #1
        beq +
        lda #6
+       sta tpen + TM2
        cpx tfrw                    ; the pointers (when his frame changes)
        beq +
        stx tfrw
        txa
        asl
        asl
        asl
        tay
        ldx #0
-       lda tblk,y                  ; (trogg.inc: frame f's eight blocks)
        sta tpen + TP1O,x
        iny
        inx
        cpx #8
        bne -
+
        lda #$ff                    ; his rows' ticks
        sta tra
        sta trb
        sta trc
        lda tpen + TY1
        sec
        sbc #35
        bcc +
        tay
        lsr
        lsr
        lsr
        cmp #ROWS
        bcs +
        sta tra
        tax
        beq _nb                     ; (the row before, for the x's move, his line 14 - (y - 35) mod
        dex                         ; 8 on: unless there's none)
        stx trc
        inx
_nb     inx
        cpx #ROWS
        bcs +
        stx trb
+       lda trc                     ; (the x moved in P2's tick if there's no row before for it)
        cmp #$ff
        lda #0
        rol
        sta tpen + TXA
        lda tpen + TY1              ; the ticks left alone: lists from ceil((y - 60) / 8) + 1
        sec                         ; to (y - 13) / 8 + 1 (0 to 25)
        sbc #45
        bcs +
        lda #0
+       lsr
        lsr
        lsr
        sta tres1
        lda tpen + TY1
        sec
        sbc #5
        bcs +
        lda #0
+       lsr
        lsr
        lsr
        cmp #26
        bcc +
        lda #25
+       sta tres2
        rts

; In the border, at the switch to the next frame: its settings his
tswitch ldx #TSET - 1
-       lda tpen,x
        sta tact,x
        dex
        bpl -
        rts

; Tick 37: his sprites' first instances (the pointers into the pair shown: usefront)
tick37  lda tact + TY1
        sta $d003
        sta $d005
        lda tact + TXL
        sta $d002
        sta $d004
        lda tact + TP1O
tq0     sta SCR0 + $3f9
tq1     sta SCR1 + $3f9
        lda tact + TP1I
tq2     sta SCR0 + $3fa
tq3     sta SCR1 + $3fa
        rts

; The tails of his rows (after the forced bad line, before the rest of the row's tail; y kept,
; for tailend): the x's move and P1b; the second instances and P2 (and the x again: the move, if
; there was no row before for it); then P3
troggc  ldx #1
        jsr tmove
        jmp tailend
trogga  lda tact + TY2
        sta $d003
        sta $d005
        lda tact + TXA              ; (the x not moved yet: no row before, at the top of the screen)
        beq +
        ldx #2
        jsr tmove
        jmp tailend
+       lda tact + TP1O + 2         ; (else P2 at once: the second instances can start his line 21)
ta0     sta SCR0 + $3f9
ta1     sta SCR1 + $3f9
        lda tact + TP1I + 2
ta2     sta SCR0 + $3fa
ta3     sta SCR1 + $3fa
        jmp tailend
troggb  lda tact + TP1O + 3
tb0     sta SCR0 + $3f9
tb1     sta SCR1 + $3f9
        lda tact + TP1I + 3
tb2     sta SCR0 + $3fa
tb3     sta SCR1 + $3fa
        jmp tailend

; The pointers to block x (1 P1b, 2 P2) and the x's move, both from line 7 of the row (the tail
; runs on line 5, the CPU held through line 4 by the forced bad line and the sprites' fetches): a
; pointer reaches his sprites from the line after it's written, the x on the line it's written,
; from where the beam is. So: line 6 begun, the pointers; then the x, on line 6 once the beam's past
; him (the timer: on line 6, cycle c, it reads 263 - c; TXK, from trogset, the reading then), or,
; when he's too far right for that to come before the line's end, on line 7 before the beam reaches
; him. Bit 8 ($d010, but for his bits as the multiplexer's set-ups left it: they leave his ticks
; alone) can only change far right
tmove   lda tact + TXK
        sta tmk+1
        lda $d010
        and #$f9
        ora tact + TM2
        sta tm010
        lda $d012
-       cmp $d012
        beq -
        lda tact + TP1O,x
tw0     sta SCR0 + $3f9
tw1     sta SCR1 + $3f9
        lda tact + TP1I,x
tw2     sta SCR0 + $3fa
tw3     sta SCR1 + $3fa
        ldx tact + TXL2
        lda tmk+1
        beq tmr
-       lda $dc06
tmk     cmp #0
        bcs -
        stx $d002
        stx $d004
        rts
tmr     lda $d012
-       cmp $d012
        beq -
        lda tm010                   ; (bit 8 first: from 254 to 256 he's at 510 meanwhile, still to
        sta $d010                   ; come; from 256 to 254, at 0, gone by)
        stx $d002
        stx $d004
        rts
tm010   .byte 0

; The pair shown's screens, for the pointers (from usefront: a, the high byte of the tops' screen's
; pointers; x, the bottoms')
tpair   sta tq0+2
        sta tq2+2
        sta tw0+2
        sta tw2+2
        sta ta0+2
        sta ta2+2
        sta tb0+2
        sta tb2+2
        stx tq1+2
        stx tq3+2
        stx tw1+2
        stx tw3+2
        stx ta1+2
        stx ta3+2
        stx tb1+2
        stx tb3+2
        rts

; ---- Data
tx      .word TROGGX ? TROGGX : TSTARTX     ; (his place in the level: x, and his feet's y;
ty      .word TROGGY ? TROGGY : TSTARTY     ;  the start, from geometry.json)
tfr     .byte TROGGF
tfrw    .byte $ff                   ; (the frame whose pointers are in tpen)
tpen    .fill TSET
tact    .fill TSET, 255             ; (parked below the screen until the first frame)
tmsbb   .byte 0
tra     .byte $ff
trb     .byte $ff
tres1   .byte $ff
tres2   .byte $ff
trc     .byte $ff                   ; (the row for the x's move; $ff: P2's)
