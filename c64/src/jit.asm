; ---- The column renderer. Each slot of a cache of JCOLS (map column c in slot c mod JCOLS) holds
; code that writes a map column to a column of a screen pair (x: the screen column): lda #value,
; sta cell,x, for each of the column's 50 cells, then rts; a page each for each pair. Compiling a
; column is just writing its values into the lda #s. A column that changes (jdirty) is compiled
; again when it's next drawn.
JCOLS   = 40                        ; (a fill needs 38 columns at once; turning, 2 more)
JPAGE   = (hiend + 255) >> 8        ; (the first page of the code)
jp0     = zp + 90                   ; (2: the code being made, pair 0's)
jp1     = zp + 92                   ; (2: pair 1's)
jk      = zp + 95                   ; (the slot)
jt      = zp + 96

; Fill screen column prow of pair back for column working, then prow+1
fillcol lda prow
        clc
        adc working
        tay                         ; the map column
        ldx jmod,y                  ; its slot
        tya
        cmp jcol,x
        beq +
        jsr jcomp                   ; (not compiled yet, or changed: compile it)
+       lda back
        bne +
        lda jpg0,x
        bne _call                   ; (always)
+       lda jpg1,x
_call   sta _j+2
        ldx prow
_j      jsr $ff00
        inc prow
        rts

; Column a changed: compile it again when it's next drawn
jdirty  tay
        ldx jmod,y
        lda #$ff
        sta jcol,x
        rts

; Compile column a into slot x, both pairs' code: its 50 values into the lda #s (x kept)
jcomp   stx jk
        sta jcol,x
        tay
        lda jclo,y                  ; (its 50 cells: rows 0-24's tops, then their bottoms)
        sta _src+1
        lda jchi,y
        sta _src+2
        lda jpg0,x
        sta jp0+1
        lda jpg1,x
        sta jp1+1
        ldx #49
-       ldy joff,x
_src    lda $ffff,x
        sta (jp0),y
        sta (jp1),y
        dex
        bpl -
        ldx jk
        rts

; At the start: every slot's code, for both pairs: lda #0, sta cell,x for each cell, then rts
jinit   lda #0
        sta jp0
        sta jp1
        ldx #JCOLS - 1
_slot   lda jpg0,x
        sta jp0+1
        lda jpg1,x
        sta jp1+1
        ldy #0
        sty jt                      ; (the cell)
_cell   lda #$a9                    ; lda #0
        sta (jp0),y
        sta (jp1),y
        iny
        lda #0
        sta (jp0),y
        sta (jp1),y
        iny
        lda #$9d                    ; sta cell,x
        sta (jp0),y
        sta (jp1),y
        iny
        stx jk
        ldx jt
        lda jdlo,x
        sta (jp0),y
        sta (jp1),y
        iny
        lda jdhi,x
        sta (jp0),y
        ora #8                      ; (pair 1's screens are $800 on)
        sta (jp1),y
        iny
        ldx jk
        inc jt
        lda jt
        cmp #50
        bne _cell
        lda #$60                    ; rts
        sta (jp0),y
        sta (jp1),y
        dex
        bpl _slot
        rts

        .section high
jmod    .for i = 0, i < NC, i += 1  ; each map column's slot
        .byte i % JCOLS
        .endfor
jclo    .for i = 0, i < NC, i += 1  ; each map column's cells
        .byte <(colmap + 50 * i)
        .endfor
jchi    .for i = 0, i < NC, i += 1
        .byte >(colmap + 50 * i)
        .endfor
jdlo    .for i = 0, i < 50, i += 1  ; each cell's place in pair 0 (screen column 0)
        .byte <(i < 25 ? SCR0 + 40 * i : SCR1 + 40 * (i - 25))
        .endfor
jdhi    .for i = 0, i < 50, i += 1
        .byte >(i < 25 ? SCR0 + 40 * i : SCR1 + 40 * (i - 25))
        .endfor
jpg0    .for i = 0, i < JCOLS, i += 1   ; each slot's code: pair 0's, pair 1's (the pages from
        .byte JPAGE + i                 ; the program's end to $cf, then from $e0, under the KERNAL)
        .endfor
jpg1    .for i = 0, i < JCOLS, i += 1
        .byte JPAGE + JCOLS + i < $d0 ? JPAGE + JCOLS + i : $e0 + (JCOLS + i - ($d0 - JPAGE))
        .endfor
joff    .for i = 0, i < 50, i += 1  ; each cell's value in a slot's code (its lda #'s operand)
        .byte 5 * i + 1
        .endfor
jcol    .fill JCOLS, $ff            ; the map column in each slot ($ff: none)
        .send
