; RESP1 strobe test: does repeated RESP1 draw repeated player-1 copies on the same line?
; Each section: 8 lines with the strobes (from cycle 26), then 8 lines without, then a gap.
; Built with:  dasm resp_test.asm -f3 -oresp_test.bin
        processor 6502
VSYNC = $00
VBLANK = $01
WSYNC = $02
NUSIZ1 = $05
COLUP1 = $07
COLUBK = $09
RESP1 = $11
GRP1 = $1C
        seg code
        org $F000
Start:  sei
        cld
        ldx #$FF
        txs
        lda #0
Clear:  sta $00,x
        dex
        bne Clear
Frame:  lda #2
        sta VSYNC
        sta WSYNC
        sta WSYNC
        sta WSYNC
        lda #0
        sta VSYNC
        lda #2
        sta VBLANK
        ldx #37
VB:     sta WSYNC
        dex
        bne VB
        lda #$0C          ; light grey background
        sta COLUBK
        lda #$00          ; black player 1
        sta COLUP1
        sta WSYNC
        lda #0
        sta VBLANK
; --- section 0: NUSIZ0 x8 every 3
        lda #0
        sta NUSIZ1
        lda #$FF
        sta GRP1
        ldx #8
S0a:   sta WSYNC
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta RESP1
        sta RESP1
        sta RESP1
        sta RESP1
        sta RESP1
        sta RESP1
        sta RESP1
        sta RESP1
        dex
        bne S0a
        ldx #8
S0b:   sta WSYNC
        dex
        bne S0b
        sta WSYNC
        lda #0
        sta GRP1
        ldx #3
S0c:   sta WSYNC
        dex
        bne S0c
; --- section 1: NUSIZ1 x8 every 3
        lda #1
        sta NUSIZ1
        lda #$FF
        sta GRP1
        ldx #8
S1a:   sta WSYNC
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta RESP1
        sta RESP1
        sta RESP1
        sta RESP1
        sta RESP1
        sta RESP1
        sta RESP1
        sta RESP1
        dex
        bne S1a
        ldx #8
S1b:   sta WSYNC
        dex
        bne S1b
        sta WSYNC
        lda #0
        sta GRP1
        ldx #3
S1c:   sta WSYNC
        dex
        bne S1c
; --- section 2: NUSIZ3 x8 every 3
        lda #3
        sta NUSIZ1
        lda #$FF
        sta GRP1
        ldx #8
S2a:   sta WSYNC
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta RESP1
        sta RESP1
        sta RESP1
        sta RESP1
        sta RESP1
        sta RESP1
        sta RESP1
        sta RESP1
        dex
        bne S2a
        ldx #8
S2b:   sta WSYNC
        dex
        bne S2b
        sta WSYNC
        lda #0
        sta GRP1
        ldx #3
S2c:   sta WSYNC
        dex
        bne S2c
; --- section 3: NUSIZ0 x4 every 6
        lda #0
        sta NUSIZ1
        lda #$FF
        sta GRP1
        ldx #8
S3a:   sta WSYNC
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta RESP1
        bit $80
        sta RESP1
        bit $80
        sta RESP1
        bit $80
        sta RESP1
        dex
        bne S3a
        ldx #8
S3b:   sta WSYNC
        dex
        bne S3b
        sta WSYNC
        lda #0
        sta GRP1
        ldx #3
S3c:   sta WSYNC
        dex
        bne S3c
; --- section 4: NUSIZ1 x4 every 6
        lda #1
        sta NUSIZ1
        lda #$FF
        sta GRP1
        ldx #8
S4a:   sta WSYNC
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta RESP1
        bit $80
        sta RESP1
        bit $80
        sta RESP1
        bit $80
        sta RESP1
        dex
        bne S4a
        ldx #8
S4b:   sta WSYNC
        dex
        bne S4b
        sta WSYNC
        lda #0
        sta GRP1
        ldx #3
S4c:   sta WSYNC
        dex
        bne S4c
; --- section 5: NUSIZ1 x4 every 9
        lda #1
        sta NUSIZ1
        lda #$FF
        sta GRP1
        ldx #8
S5a:   sta WSYNC
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta RESP1
        bit $80
        bit $80
        sta RESP1
        bit $80
        bit $80
        sta RESP1
        bit $80
        bit $80
        sta RESP1
        dex
        bne S5a
        ldx #8
S5b:   sta WSYNC
        dex
        bne S5b
        sta WSYNC
        lda #0
        sta GRP1
        ldx #3
S5c:   sta WSYNC
        dex
        bne S5c
; --- section 6: NUSIZ1 single
        lda #1
        sta NUSIZ1
        lda #$FF
        sta GRP1
        ldx #8
S6a:   sta WSYNC
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta RESP1
        dex
        bne S6a
        ldx #8
S6b:   sta WSYNC
        dex
        bne S6b
        sta WSYNC
        lda #0
        sta GRP1
        ldx #3
S6c:   sta WSYNC
        dex
        bne S6c
; --- section 7: NUSIZ0 single
        lda #0
        sta NUSIZ1
        lda #$FF
        sta GRP1
        ldx #8
S7a:   sta WSYNC
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta RESP1
        dex
        bne S7a
        ldx #8
S7b:   sta WSYNC
        dex
        bne S7b
        sta WSYNC
        lda #0
        sta GRP1
        ldx #3
S7c:   sta WSYNC
        dex
        bne S7c
        ldx #31
Rest:   sta WSYNC
        dex
        bne Rest
        lda #2
        sta VBLANK
        ldx #30
OS:     sta WSYNC
        dex
        bne OS
        jmp Frame
        org $FFFC
        .word Start
        .word Start
