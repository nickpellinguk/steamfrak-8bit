; A stand-in for the C64's ROMs, for testing in VICE (which comes without them here): the
; "BASIC ROM" holds the demo's PRG (less its load address) from $0801, the "KERNAL" whatever
; doesn't fit, and copies both to $0801 at reset and starts it. The demo needs no ROM routines.
        .include "rom.inc"          ; START, LENGTH
PART1   = LENGTH < $2000 ? LENGTH : $2000
PART2   = LENGTH - PART1
        * = $a000
basic   .binary "frak64.prg", 2, PART1
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
        lda #<$0801
        sta $fd
        lda #>$0801
        sta $fe
        lda #<basic
        ldx #>basic
        ldy #>PART1
        jsr copy
        .if PART2
        lda #<more
        ldx #>more
        ldy #>(PART2 + 255)
        jsr copy
        .endif
        jmp START
; copy y pages from (x a) on to ($fd), where the last copy finished (from $0801)
copy    sta $fb
        stx $fc
        sty $02
        ldy #0
-       lda ($fb),y
        sta ($fd),y
        iny
        bne -
        inc $fc
        inc $fe
        dec $02
        bne -
        rts
irq     rti
        .if PART2
more    .binary "frak64.prg", 2 + PART1
        .endif
        .fill $fffa - *, 0
        .word irq, reset, irq
        .endlogical
