; A stand-in for the C64's ROMs, for testing in VICE (which comes without them here). The demo's
; PRG (less its load address) is in a cartridge image (build/frak64.crt: Magic Desk, 8K banks at
; $8000, chosen by writing $de00); the "KERNAL" copies it, page by page, bank by bank, to $0801 at
; reset, switches the cartridge off and starts it. The "BASIC ROM" is empty. The demo needs no
; ROM routines.
        .include "rom.inc"          ; START, PAGES
        * = $a000
        .fill $2000, 0
        .logical $e000
reset   sei
        cld
        ldx #$ff
        txs
        lda #$37                    ; (the port's data first, then its direction, or the ROMs vanish)
        sta $01
        lda #$2f
        sta $00
        lda #<$0801
        sta $fd
        lda #>$0801
        sta $fe
        lda #PAGES
        sta $02
        ldx #0                      ; (the bank)
_bank   stx $de00
        lda #0
        sta $fb
        lda #$80
        sta $fc
        ldy #0
-       lda ($fb),y
        sta ($fd),y
        iny
        bne -
        inc $fe
        dec $02
        beq _done
        inc $fc
        lda $fc
        cmp #$a0
        bne -
        inx
        bne _bank
_done   lda #$80                    ; (the cartridge off)
        sta $de00
        jmp START
irq     rti
        .fill $fffa - *, 0
        .word irq, reset, irq
        .endlogical
