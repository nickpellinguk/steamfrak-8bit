; ---- The column renderer. Each map column is compiled, when it's first needed, into code that
; writes it to a column of a screen pair (x: the screen column): a value at a time, lda #value
; and then sta to every cell with that value, so each value is loaded once (A_1's columns have 9
; values on average; 3 cells in 4 are 0). The code's kept in a cache of JCOLS slots (map column
; c in slot c mod JCOLS), a page each for each pair, both made at once. A column that changes
; (jdirty) is compiled again when it's next needed.
JCOLS   = 40                        ; (a fill needs 38 columns at once; turning, 2 more)
JPAGE   = (hiend + 255) >> 8        ; (the first page of the code)
jsp     = zp + 88                   ; (2: the column's cells)
jp0     = zp + 90                   ; (2: the code being made, pair 0's)
jp1     = zp + 92                   ; (2: pair 1's)
jnd     = zp + 94                   ; (the column's values found)
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

; Compile column a into slot x, both pairs' code (x kept)
jcomp   stx jk
        sta jcol,x
        tay
        lda jclo,y                  ; (its 50 cells: rows 0-24's tops, then their bottoms)
        sta jsp
        lda jchi,y
        sta jsp+1
        lda jpg0,x
        sta jp0+1
        lda jpg1,x
        sta jp1+1
        lda #0
        sta jp0
        sta jp1
        sta jnd
        ldy #49                     ; each cell, last to first, chained to the next with its value
_g      lda (jsp),y
        tax
        lda jhead,x
        bpl _old
        txa                         ; (a value not seen yet: listed)
        ldx jnd
        sta jdl,x
        inc jnd
        tax
        lda #$ff
_old    sta jnxt,y
        tya
        sta jhead,x
        dey
        bpl _g
        ldy #0                      ; then the code: each value, and its cells
_v      ldx jnd
        dex
        bmi _end
        stx jnd
        lda #$a9                    ; lda #value
        sta (jp0),y
        sta (jp1),y
        iny
        lda jdl,x
        sta (jp0),y
        sta (jp1),y
        iny
        tax
        lda jhead,x                 ; (its first cell; the head cleared for the next column)
        sta jt
        lda #$ff
        sta jhead,x
        ldx jt
_s      lda #$9d                    ; sta cell,x
        sta (jp0),y
        sta (jp1),y
        iny
        lda jdlo,x
        sta (jp0),y
        sta (jp1),y
        iny
        lda jdhi,x
        sta (jp0),y
        ora #8                      ; (pair 1's screens are $800 on)
        sta (jp1),y
        iny
        lda jnxt,x
        tax
        bpl _s
        bmi _v                      ; (always)
_end    lda #$60                    ; rts (at most 251 bytes: 50 stores, 50 values)
        sta (jp0),y
        sta (jp1),y
        ldx jk
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
jcol    .fill JCOLS, $ff            ; the map column in each slot ($ff: none)
jhead   .fill 256, $ff              ; (jcomp's: each value's first cell, $ff: none)
jnxt    .fill 50                    ; (each cell's next with its value)
jdl     .fill 50                    ; (the values found)
        .send
