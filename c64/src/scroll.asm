; ---- Scrolling by whole characters with VSP (see VSP.md). Each screen pair p has an origin
; po[p]: map cell (row r, column m) is kept at 40r + (m - po[p]) in its screens, and the pair
; shows the window from map column w (at screen column 0) with the VSP offset s = w - po[p], 0 to
; SMAX. A step of the window is one new column written, where it can't be seen (under the cover
; sprite: walking right, the cells shown as column 0 of the row below; left, as column 1); a step
; that would take s out of range swaps to the other pair, filled in the background for an origin
; 8 columns that way and kept up to date. pvw[p]: the window pair p is up to date for ($ff: being
; filled, for window working with offset fsh, from row prow).
SMAX    = 16                        ; (from 17 on, the sprite pointers would be shown)

; Pair x's window stepped from pvw[x] one column, to a: the new column written (x kept)
colstep sta cnw
        sec
        sbc po,x
        sta cns                     ; (the new offset)
        lda cnw
        cmp pvw,x                   ; (carry: to the right)
        sta pvw,x
        stx cpr
        bcc _l
        adc #39 - 1                 ; right: column w + 39, at the new offset + 39
        tax
        lda cns
        adc #39                     ; (carry clear: w + 39 < 256)
        tay
        jmp _go
_l      adc #2                      ; left: column w + 2, at the new offset + 2 (carry clear)
        tax
        lda cns
        adc #2
        tay
_go     lda cpr
        bne +
        jsr colw0
        ldx cpr
        rts
+       jsr colw1
        ldx cpr
        rts

; Map column x written to pair 0's (1's) screens, at y on each row: tops, then bottoms
colw0   .for r = 0, r < ROWS, r += 1
        lda tops + r * NC,x
        sta SCR0 + 40 * r,y
        lda bottoms + r * NC,x
        sta SCR1 + 40 * r,y
        .endfor
        rts
colw1   .for r = 0, r < ROWS, r += 1
        lda tops + r * NC,x
        sta SCR2 + 40 * r,y
        lda bottoms + r * NC,x
        sta SCR3 + 40 * r,y
        .endfor
        rts

; The window to go to column a, a step from curc (the camera's): carry clear if done (the column
; written into the pair shown, or the step made in the hidden pair and a flip to it left for the
; border), set if it can't be yet (the hidden pair not ready for it)
cstep   sta cnw
        ldx lfront
        sec
        sbc po,x
        cmp #SMAX + 1
        bcs _swap
        sta nvs                     ; (the offset, for the border)
        lda cnw
        jsr colstep
        lda cnw
        sta curc
        clc
        rts
_swap   ldx back                    ; out of the pair shown's range: the other's, if it's up to
        lda pvw,x                   ; date and the step keeps it in range
        cmp curc
        bne _wait
        lda cnw
        sec
        sbc po,x
        cmp #SMAX + 1
        bcs _wait
        sta nvs
        lda cnw
        jsr colstep
        lda cnw
        sta curc
        stx lfront
        txa
        eor #1
        sta back
        lda #1
        sta flippend
        clc
        rts
_wait   sec
        rts

; The origin wanted for the hidden pair, for a swap on the side a's sign says (+: right): 8
; columns on (or 9 back) from the shown pair's, unless that pair reaches the level's end anyway
wantdir ldx lfront
        tay
        bmi _l
        lda po,x
        clc
        adc #SMAX
        cmp #MAXC
        bcs _x
        lda po,x
        adc #8                      ; (carry clear)
        sta wanto
_x      rts
_l      lda po,x
        beq _x
        bmi _x
        sec
        sbc #9
        sta wanto
        rts

; The foreground's work for the hidden pair, a piece at a time: filled for the origin wanted (for
; the window nearest the one shown, or the restart's), a row at a time; then kept up to date, a
; column at a time. Carry set if there was nothing to do.
bgwork  lda flippend                ; (a flip pending: the pair leaving the screen is still shown)
        bne _idle
        ldx back
        lda wanto
        cmp po,x
        beq _have
        sta po,x                    ; a new origin: the window nearest the one wanted, in its range
        lda #$ff
        sta pvw,x
        jsr _tw
        sec
        sbc po,x
        cmp #SMAX + 1
        bcc _in
        cmp #$80
        lda #0                      ; (before the range: its start)
        bcs +
        lda #SMAX                   ; (after it: its end)
+
_in     sta fsh
        clc
        adc po,x
        sta working
        lda #0
        sta prow
        clc
        rts
_have   lda pvw,x
        cmp #$ff
        bne _valid
        lda prow
        cmp #ROWS
        bcs _done
        jsr fillrow
        clc
        rts
_done   lda working
        sta pvw,x
        clc
        rts
_valid  jsr _tw                     ; up to date: a step towards the window wanted, if it's in range
        cmp pvw,x
        beq _idle
        lda pvw,x
        bcc +
        adc #0                      ; (carry set: + 1)
        bne ++
+       sbc #0                      ; (carry clear: - 1)
+       sta cnw
        sec
        sbc po,x
        cmp #SMAX + 1
        bcs _idle
        lda cnw
        jsr colstep
        clc
        rts
_idle   sec
        rts
_tw     lda jumping                 ; (the window wanted: the restart's, jumpw, or the one shown)
        beq +
        lda jumpw
        rts
+       lda curc
        rts

po      .byte $f8, $f8              ; each pair's origin (signed)
pvw     .byte 0, $ff                ; the window each is up to date for ($ff: being filled)
cnw     .byte 0
cns     .byte 0
cpr     .byte 0
