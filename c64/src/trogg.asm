; ---- Trogg on the screen: sprites 1 (his black outline, hi-res, in front) and 2 (his infill,
; multicolour: yellow and magenta), 24 wide. He's 34 lines high, a sprite 21, so each is used twice
; down him (tools/trogg.mjs): the first instances (y, blocks P1) set up in border tick 37; then in
; the tick of the row whose tick falls in his lines 13-20 (row (y - 35) / 8: its tail's write
; reaches the VIC from line 56 or 57 of the row), the second instances (y + 21) and the pointers to
; P2 (the same as P1 in rows 13-20, then his lines 21-33); and in the next row's tick, the pointers
; to P3 (P2 without its rows 13-20, which would show again below his feet). Those two rows have
; tails of their own (tails.inc's a and b kinds, chosen by the multiplexer's row tables). The
; multiplexer sets nothing up in the ticks of the rows whose tails run while he's drawn (his
; sprites take the time).
;
; The main program works out the settings for the frame after (tpen), and the border makes them
; Trogg's (tact) when it switches to that frame (with the multiplexer's buffer, and the scroll).

        .include "trogg.inc"        ; TFRAMES, trleft
TROGGP  = (TROGG & $3fff) / 64      ; (frame f's blocks: TROGGP + 6f + 0-2 outline, 3-5 infill)
TY1     = 0                         ; (tpen, tact: his sprites' y,
TY2     = 1                         ;  the second instances' y,
TXL     = 2                         ;  x (bit 8: tmsbb, in the multiplexer's registers),
TP1O    = 3                         ;  the pointers: outline P1-P3,
TP1I    = 6                         ;  infill P1-P3)
TSET    = 9

; His sprites' settings for the frame after, from his place (tx: x in the level, ty: his feet's y
; in the level, as the BBC and CPC versions keep them) and frame (tfr), and the scroll; and for the
; multiplexer, the rows of his ticks (tra; trb the next), the ticks it's to leave alone (lists
; tres1 to tres2: the rows whose tails, lines 55 + 8r to 61 + 8r, run while he's drawn, lines y + 1
; to y + 42), and bit 8 of his x
trogset lda ty+1                    ; y = the line before his top: (ty - 34) + 27 - 1
        beq +
        lda #255                    ; (fallen off the bottom: under the screen)
        .byte $2c
+       lda ty
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
        lda mh
        sbc scrx+1
        and #1
        beq +
        lda #6                      ; (sprites 1 and 2)
+       sta tmsbb
        txa                         ; the pointers
        asl
        sta mt
        asl
        clc
        adc mt
        adc #TROGGP
        ldx #0
-       sta tpen + TP1O,x
        clc
        adc #1
        inx
        cpx #6
        bne -
        lda #$ff                    ; his rows' ticks
        sta tra
        sta trb
        lda tpen + TY1
        sec
        sbc #35
        bcc +
        lsr
        lsr
        lsr
        cmp #ROWS
        bcs +
        sta tra
        tax
        inx
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

; The tails of his rows (after the forced bad line, before the rest of the row's tail): the
; second instances and P2; then P3
trogga  lda tact + TY2
        sta $d003
        sta $d005
        lda tact + TP1O + 1
ta0     sta SCR0 + $3f9
ta1     sta SCR1 + $3f9
        lda tact + TP1I + 1
ta2     sta SCR0 + $3fa
ta3     sta SCR1 + $3fa
        jmp tailend
troggb  lda tact + TP1O + 2
tb0     sta SCR0 + $3f9
tb1     sta SCR1 + $3f9
        lda tact + TP1I + 2
tb2     sta SCR0 + $3fa
tb3     sta SCR1 + $3fa
        jmp tailend

; The pair shown's screens, for the pointers (from usefront: a, the high byte of the tops' screen's
; pointers; x, the bottoms')
tpair   sta tq0+2
        sta tq2+2
        sta ta0+2
        sta ta2+2
        sta tb0+2
        sta tb2+2
        stx tq1+2
        stx tq3+2
        stx ta1+2
        stx ta3+2
        stx tb1+2
        stx tb3+2
        rts

; ---- Data
tx      .word TROGGX ? TROGGX : TSTARTX     ; (his place in the level: x, and his feet's y;
ty      .word TROGGY ? TROGGY : TSTARTY     ;  the start, from geometry.json)
tfr     .byte TROGGF
tpen    .fill TSET
tact    .fill TSET, 255             ; (parked below the screen until the first frame)
tmsbb   .byte 0
tra     .byte $ff
trb     .byte $ff
tres1   .byte $ff
tres2   .byte $ff
