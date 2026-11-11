; A stand-in for the C64's ROMs, for testing in VICE (which comes without them here): the
; "BASIC ROM" holds the demo's PRG (less its load address), the "KERNAL" copies it to $0801 at
; reset and starts it. The demo needs no ROM routines.
        .include "rom.inc"          ; START, LENGTH
        * = $a000
basic   .binary "frak64.prg", 2
        .fill $c000 - *, 0
        .logical $e000
reset   sei
        cld
        ldx #$ff
        txs
        lda #$37                    ; (the port's data first, then its direction, or the ROMs vanish)
        sta $01
        lda #$2f
        sta $00
        lda #<basic
        sta $fb
        lda #>basic
        sta $fc
        lda #<$0801
        sta $fd
        lda #>$0801
        sta $fe
        ldx #>(LENGTH + 255)
        ldy #0
-       lda ($fb),y
        sta ($fd),y
        iny
        bne -
        inc $fc
        inc $fe
        dex
        bne -
        jmp START
irq     rti
        .fill $fffa - *, 0
        .word irq, reset, irq
        .endlogical
