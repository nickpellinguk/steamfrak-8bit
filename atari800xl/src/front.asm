; ---- The front end (FRONTEND builds): the attract screen, as the C64 port's (c64/src/front.asm) and
; the BBC Master's and the CPC's first screen ("The Cast"), shown at the start till fire, Start,
; Space, Return, P or Y (a key let go first). tools/front.py makes it: a 320 x 220 hi-res bitmap
; (mode F from scanline 8, the C64's layout: the FRAK! bubble, then its 25 text rows), the cast's
; outlines in it, packed (unpacked here under the OS, where the game's screen goes later); the
; text drawn into it from the machine's ROM font (copied to FONTB by start, while the OS ROM's
; in: as the C64 uses its own font); the infills on players (every one exact), set again for each
; picture by a DLI after the one before (frdli: 10 registers from the bands' tables). Escape in
; the game comes back here (move.asm).
KBCODE  = $d209
SKSTAT  = $d20f
CONSOL  = $d01f
frp     = tmp                       ; (2: the text's and the players' graphics' records)
frg     = $b4                       ; (2: a glyph)
frd     = $b6                       ; (2: where it goes)

attract lda #<frbmz                 ; the bitmap
        sta usrc
        lda #>frbmz
        sta usrc+1
        lda #<FRBM
        sta udp
        lda #>FRBM
        sta udp+1
        jsr unpack
        lda #<frtext                ; the text: each character's 8 lines from the ROM font
        sta frp
        lda #>frtext
        sta frp+1
frt     ldy #0
        lda (frp),y
        cmp #255
        beq frtd
        sta frl
        iny
        lda (frp),y
        sta frc
        iny
        lda (frp),y
        sta frn
        lda frp
        clc
        adc #3
        sta frp
        bcc +
        inc frp+1
+       lda #0
        sta frk
frch    ldy frk                     ; (character k: its glyph, FONTB + code * 8)
        lda (frp),y
        sta frg
        lda #0
        asl frg
        rol a
        asl frg
        rol a
        asl frg
        rol a
        adc #>FONTB
        sta frg+1
        ldx frl
        ldy #0
-       lda frlal,x                 ; (its 8 lines, each in the bitmap's line x, column c + k)
        clc
        adc frc
        sta frd
        lda frlah,x
        adc #0
        sta frd+1
        tya
        pha
        lda (frg),y
        ldy frk
        sta (frd),y
        pla
        tay
        inx
        iny
        cpy #8
        bne -
        inc frk
        lda frk
        cmp frn
        bne frch
        lda frp                     ; (the next record)
        clc
        adc frn
        sta frp
        bcc frt
        inc frp+1
        bne frt
frtd    lda #<(PMG0 + $300)         ; the players' graphics: clear, then each record's
        sta frd
        lda #>(PMG0 + $300)
        sta frd+1
        ldx #5
        lda #0
        tay
-       sta (frd),y
        iny
        bne -
        inc frd+1
        dex
        bne -
        lda #<frpm
        sta frp
        lda #>frpm
        sta frp+1
frpl    ldy #0
        lda (frp),y
        sta frd
        iny
        lda (frp),y
        beq frpd                    ; (address 0: the end)
        sta frd+1
        iny
        lda (frp),y
        tax
        lda frp
        clc
        adc #3
        sta frp
        bcc +
        inc frp+1
+       ldy #0
-       lda (frp),y
        sta (frd),y
        iny
        dex
        bne -
        tya
        clc
        adc frp
        sta frp
        bcc frpl
        inc frp+1
        bne frpl
frpd    ldx #frdlend - frdlist - 1  ; the display list to its place
-       lda frdlist,x
        sta FRDL,x
        dex
        cpx #$ff
        bne -
        .cerror frdlend - frdlist > 256, "the front end's display list is over a page"
        lda #$00                    ; the colours and players: as the game's (outlines black, the
        sta COLPF1                  ; background cyan, players in front)
        sta COLBK
        lda #$9a
        sta COLPF2
        lda #1
        sta PRIOR
        ldx #4
        lda #0
-       sta SIZEP0,x
        dex
        bpl -
        lda #>PMG0
        sta PMBASE
        lda #3
        sta GRACTL
        ldx #0                      ; band 0's registers (the bubble's); the DLIs then each set the
        jsr frregs                  ; next's
        lda #1
        sta frdi
        lda #<FRDL
        sta DLISTL
        lda #>FRDL
        sta DLISTL+1
        lda #<frdli
        sta dliv
        lda #>frdli
        sta dliv+1
-       lda VCOUNT                  ; the display on from a vertical blank
        cmp #124
        bcc -
        lda #$3e                    ; normal width, playfield, players and missiles (1-line)
        sta DMACTL
        lda #$80                    ; (the DLIs alone: not the game's VBI)
        sta NMIEN
-       jsr frkey                   ; a key let go, then one pressed
        bne -
-       jsr frkey
        beq -
        lda #0                      ; off again for the game's setting up
        sta NMIEN
        sta DMACTL
        sta GRACTL
        ldx #7
-       sta HPOSP0,x
        dex
        bpl -
        rts

; fire, Start, Space, Return, P or Y down: a not 0
frkey   lda TRIG0
        and #1
        beq _y
        lda CONSOL
        and #1
        beq _y
        lda SKSTAT                  ; (a key down: bit 2 0)
        and #4
        bne _n
        lda KBCODE
        and #$3f
        cmp #$21                    ; (Space)
        beq _y
        cmp #$0c                    ; (Return)
        beq _y
        cmp #$0a                    ; (P)
        beq _y
        cmp #$2b                    ; (Y)
        beq _y
_n      lda #0
        rts
_y      lda #1
        rts

; band x's registers: the players' positions and colours, the missiles' positions
frregs  lda frhp0,x
        sta HPOSP0
        lda frhp1,x
        sta HPOSP0+1
        lda frhp2,x
        sta HPOSP0+2
        lda frhp3,x
        sta HPOSP0+3
        lda frcl0,x
        sta COLPM0
        lda frcl1,x
        sta COLPM0+1
        lda frcl2,x
        sta COLPM0+2
        lda frcl3,x
        sta COLPM0+3
        lda frhm0,x
        sta HPOSM0
        lda frhm1,x
        sta HPOSM0+1
        rts

; the DLI after each picture: the next band's registers (after the last, the bubble's, for the
; next frame)
frdli   pha
        txa
        pha
        ldx frdi
        jsr frregs
        inx
        cpx #FRNB
        bcc +
        ldx #0
+       stx frdi
        pla
        tax
        pla
        rti

frl     .byte 0                     ; (the text's: the line, column, length, character)
frc     .byte 0
frn     .byte 0
frk     .byte 0
frdi    .byte 0                     ; (the next band whose registers the next DLI sets)
        .include "../build/front.inc"
frbmz   .binary "../build/front_bm.lz"
