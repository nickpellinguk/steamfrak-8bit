; Test ROM: the Frak theme over a plain screen whose colour follows the lead channel's volume.
;   dasm musictest.asm -f3 -omusictest.bin -smusictest.sym
        processor 6502
VSYNC = $00
VBLANK = $01
WSYNC = $02
COLUBK = $09
AUDC0 = $15
AUDC1 = $16
AUDF0 = $17
AUDF1 = $18
AUDV0 = $19
AUDV1 = $1A
MUSRAM = $80

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
        jsr MusicInit
Frame:  lda #2
        sta VSYNC
        sta WSYNC
        sta WSYNC
        sta WSYNC
        lda #0
        sta VSYNC
        lda #2
        sta VBLANK
        jsr MusicTick
        ldx #36
VB:     sta WSYNC
        dex
        bne VB
        lda #0
        sta VBLANK
        lda MusVol+1
        asl
        ora #$A0
        sta COLUBK
        ldx #192
Pic:    sta WSYNC
        dex
        bne Pic
        lda #2
        sta VBLANK
        ldx #30
OS:     sta WSYNC
        dex
        bne OS
        jmp Frame

        include "musicdrv.asm"

        org $FFFC
        .word Start
        .word Start
