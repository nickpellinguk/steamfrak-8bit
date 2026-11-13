; ---- Trogg on the screen: sprites 1 (his black outline, hi-res, in front) and 2 (his infill,
; multicolour: yellow and magenta), 24 wide. He's 34 lines high, a sprite 21, so each is used twice
; down him (tools/trogg.mjs): the first instances (y, blocks P1) set up in border tick 37; then in
; the tick of the row whose tick falls in his lines 13-20 (row (y - 35) / 8: its tail's write
; reaches the VIC from line 56 or 57 of the row), the second instances (y + 21) and the pointers to
; P2 (the same as P1 in rows 13-20, then his lines 21-33); and in the next row's tick, the pointers
; to P3 (P2 without its rows 13-20, which would show again below his feet). His 26-wide frames
; (standing, walking) have their snout and their back at opposite ends: his head (lines 0-16) is cut
; 2 pixels toward the snout from his body (lines 6-33), and his x moves those 2 pixels (trdx) in
; the tick of the row before (trc: from his lines 6-13), with the pointers to P1b (P1 cut as the
; body); not at all if there's no row before (his top above line 43, which he never reaches).
; Those rows have tails of their own
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
TM2     = 4                         ;  its bit 8's change ($d010's bits 1 and 2 to flip),
TP1O    = 5                         ;  the pointers: outline P1, P1b, P2, P3,
TP1I    = 9                         ;  infill likewise,
TXK     = 13                        ;  the timer's low byte when the x can move on line 5,
TSET    = 14                        ;  plus 1)

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
        lda mh                      ; (the x's move on line 5 once the beam's at cycle 17 + (x +
        beq _tx0                    ; 27) / 8, past his right edge: measured, from his left, to x
        cmp #1                      ; 230. The timer's low byte then 54 - (x + 27) / 8: TXK, 8 or
        bne _txn                    ; more to x 343. Far right, past line 5's end: the CPU held
        lda mt                      ; over the fetches, line 6's first cycles, before the beam
        cmp #344 - 256              ; reaches him there. Right of x 343, or left of 0, he's out
        bcs _txn                    ; of sight: no waiting, TXK 255)
_tx0    lda mt
        clc
        adc #27
        sta ttmp
        lda mh
        adc #0
        lsr
        lda ttmp
        ror
        lsr
        lsr
        eor #$ff
        sec
        adc #54
        .byte $2c
_txn    lda #255
        sta tpen + TXK
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
+       eor tmsbb                   ; (as a change)
        sta tpen + TM2
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
+       lda tpen + TY1              ; the ticks left alone: lists from ceil((y - 60) / 8) + 1
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
; for tailend): the x's move and P1b; the second instances and P2; then P3. The tail runs on line 5
; of the row (the CPU held through line 4 by the forced bad line and the sprites' fetches, back
; at cycle 1-20 or so), and must be quick: the next row's interrupt comes 5 lines on, and takes
; only 31 cycles' lateness. A pointer reaches his sprites from the line after it's written (their
; fetches at the line's end), an x on the line it's written, from where the beam is. So: the
; pointers in the bottoms' screen (lines 4-7's: the ones the fetches at line 5's end read); then
; the x, on line 5 once the beam's past him (the timer: on line 5, cycle c, it reads 326 - c, its
; low byte 70 - c; TXK, from trogset, that byte then, plus 1), at once if it's past already: far
; right, that's late enough that the writes can be held over the fetches into line 6's first
; cycles, still before the beam reaches him there; bit 8 flipped if it changes (TM2); then the
; tops' screen's pointers (the next row's). All from line 6
troggc  lda tact + TP1O + 1
tw1     sta SCR1 + $3f9
        lda tact + TP1I + 1
tw3     sta SCR1 + $3fa
        ldx tact + TXL2
-       lda $dc06                   ; (the low byte past TXK; or the high byte 0, line 6 begun)
        cmp tact + TXK
        bcc +
        lda $dc07
        bne -
+       stx $d002
        stx $d004
        lda tact + TM2
        beq +
        eor $d010
        sta $d010
+       lda tact + TP1O + 1
tw0     sta SCR0 + $3f9
        lda tact + TP1I + 1
tw2     sta SCR0 + $3fa
        jmp tailend
trogga  lda tact + TY2
        sta $d003
        sta $d005
        lda tact + TP1O + 2
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
ttmp    .byte 0                     ; (trogset's)
