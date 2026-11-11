; Frak! on the C64: first display demo. Level A_1 ("FRAK!") in ECM with a forced bad line at
; line 4 of every character row (4-line FLI), so every 8x4 half has its own glyph (tops from the
; first screen, bottoms from the second) and its own ECM background; a character set per row (two
; sets); the level scrolling left and right. No sprites yet, so the FLI bug's 3 garbage characters
; show at the left of every row.
;
; VIC bank 1 ($4000-$7fff):
;   $4000/$4400  screen pair 0 (tops, bottoms)     $4800/$4c00  screen pair 1
;   $5000        character set 0 (64 characters)   $5800        character set 1
; Colour RAM is black throughout (every cell's foreground is black). ECM backgrounds: cyan,
; yellow, purple (Frak's magenta), black.
;
; Timing (PAL, 63 cycles a line): character row n starts at raster 51 + 8n (YSCROLL 3, a normal
; bad line). At raster 55 + 8n the loop writes YSCROLL 7 just after cycle 14, a bad line the VIC
; didn't expect: it fetches the second screen's codes without resetting its row counter, so lines
; 4-7 show rows 4-7 of the new codes' characters. YSCROLL goes back to 3 for the next row, and
; $d018 switches screens (and character sets) between the halves. The whole display is one timed
; loop of 504 cycles a row, run from a stable raster interrupt; everything else (scrolling, the
; frame's bookkeeping, filling the hidden screens) happens in the borders.
;
; Built by ../build.sh (64tass, with tools/build.mjs); PRE, D1 and D2 are the loop's delays in
; cycles, set there.

        .include "level.inc"        ; NC (columns), ROWS

SCR0    = $4000                     ; pair 0: tops
SCR1    = $4400                     ;          bottoms
SCR2    = $4800                     ; pair 1: tops
SCR3    = $4c00                     ;          bottoms
CS0     = $5000
CS1     = $5800
IRQLINE = 44                        ; the first interrupt (the second at 45; stable on 46)
D011A   = $5b                       ; ECM, display on, 25 rows, YSCROLL 3 (rows start at 51+8n)
D011B   = $5f                       ; ... YSCROLL 7 (the forced bad line at 55+8n)
MAXX    = (NC - 40) * 8             ; the furthest scroll, in pixels
PAUSE   = 50                        ; frames held at each end

; zero page
zp      = $02
scrx    = zp + 0                    ; scroll position, pixels (16 bits)
dir     = zp + 2                    ; +1 or -1 ($ff)
pause   = zp + 3
curc    = zp + 4                    ; the coarse position (column) shown
front   = zp + 5                    ; the pair shown (0/1)
target  = zp + 6                    ; the column the hidden pair should show ($ff: none)
working = zp + 7                    ; the column the foreground is filling the hidden pair for
prepared = zp + 8                   ; the column the hidden pair is ready for ($ff: not ready)
prow    = zp + 9                    ; the next row to fill
back    = zp + 10                   ; the hidden pair being filled
frames  = zp + 11
tmp     = zp + 12

        * = $0801
        .word (+), 10
        .null $9e, format("%d", start)
+       .word 0

start   sei
        cld
        ldx #$ff
        txs
        lda #$35                    ; RAM everywhere but I/O
        sta $01
        lda #$7f                    ; no CIA interrupts
        sta $dc0d
        sta $dd0d
        lda $dc0d
        lda $dd0d
        lda #<nmi
        sta $fffa
        lda #>nmi
        sta $fffb
        lda #<irq1
        sta $fffe
        lda #>irq1
        sta $ffff

        lda #$0b                    ; the display off while setting up
        sta $d011
        lda #0
        sta $d015                   ; no sprites
        lda $dd02                   ; VIC bank 1
        ora #3
        sta $dd02
        lda $dd00
        and #$fc
        ora #2
        sta $dd00
        lda #3                      ; cyan border
        sta $d020
        lda #3                      ; ECM backgrounds: cyan, yellow, purple, black
        sta $d021
        lda #7
        sta $d022
        lda #4
        sta $d023
        lda #0
        sta $d024

        ldx #0                      ; colour RAM black
-       lda #0
        sta $d800,x
        sta $d900,x
        sta $da00,x
        sta $db00,x
        ; ... and the character sets in place
        lda charsets,x
        sta CS0,x
        lda charsets+$100,x
        sta CS0+$100,x
        lda charsets+$200,x
        sta CS1,x
        lda charsets+$300,x
        sta CS1+$100,x
        inx
        bne -

        ; the $d018 tables for each pair: the tops' screen and the bottoms', the row's set
        ldx #0
-       lda rowset,x
        tay
        lda csbits,y
        sta tmp
        ora #(SCR0 & $3c00) >> 6
        sta d18a0,x
        lda tmp
        ora #(SCR1 & $3c00) >> 6
        sta d18b0,x
        lda tmp
        ora #(SCR2 & $3c00) >> 6
        sta d18a1,x
        lda tmp
        ora #(SCR3 & $3c00) >> 6
        sta d18b1,x
        inx
        cpx #ROWS
        bne -
        lda d18a0                   ; (after the last row: the first row's, harmlessly)
        sta d18a0+ROWS
        lda d18a1
        sta d18a1+ROWS

        ; pair 0 filled for column 0 and shown; pair 1 to be filled for column 1
        lda #0
        sta scrx
        sta scrx+1
        sta curc
        sta front
        sta frames
        lda #1
        sta dir
        lda #PAUSE
        sta pause
        lda #0
        sta back
        sta working
        sta prow
-       jsr fillrow
        lda prow
        cmp #ROWS
        bne -
        jsr usefront
        lda #1
        sta target
        lda #$ff
        sta working
        sta prepared

        lda #IRQLINE
        sta $d012
        lda #D011A & $7f            ; (bit 7: raster line's bit 8, 0)
        sta $d011
        lda #7                      ; 38 columns, XSCROLL 7
        sta $d016
        lda #1                      ; raster interrupts
        sta $d01a
        sta $d019
        cli

; The foreground: keep the hidden pair filled for the column the interrupt wants next
main    lda target
        cmp working
        beq +
        sta working                 ; a new column: start again
        ldx #$ff
        stx prepared
        ldx #0
        stx prow
        lda front
        eor #1
        sta back
+       lda working
        cmp #$ff
        beq main
        lda prow
        cmp #ROWS
        bcc +
        lda working                 ; done
        sta prepared
        jmp main
+       jsr fillrow
        jmp main

; Fill row prow of pair back for column working (tops and bottoms), then prow+1
fillrow ldx prow
        lda mul94lo,x               ; source: the level's row, from the column
        clc
        adc working
        sta tmp
        lda mul94hi,x
        adc #0
        sta tmp+1
        lda tmp
        clc
        adc #<tops
        sta _st+1
        lda tmp+1
        adc #>tops
        sta _st+2
        lda tmp
        clc
        adc #<bottoms
        sta _sb+1
        lda tmp+1
        adc #>bottoms
        sta _sb+2
        lda back                    ; destination: the pair's screens, the row
        asl
        tay
        lda mul40lo,x
        sta _dt+1
        sta _db+1
        lda mul40hi,x
        clc
        adc pairhi,y
        sta _dt+2
        lda mul40hi,x
        clc
        adc pairhi+1,y
        sta _db+2
        ldx #39
_st     lda $ffff,x
_dt     sta $ffff,x
_sb     lda $ffff,x
_db     sta $ffff,x
        dex
        bpl _st
        inc prow
        rts

; The pair shown: its $d018 values into the loop's tables
usefront
        ldx #ROWS
        lda front
        bne +
-       lda d18a0,x
        sta d018a,x
        lda d18b0,x
        sta d018b,x
        dex
        bpl -
        rts
+
-       lda d18a1,x
        sta d018a,x
        lda d18b1,x
        sta d018b,x
        dex
        bpl -
        rts

nmi     rti

; ---- The display: a double interrupt for a stable raster, then the timed loop
irq1    pha
        txa
        pha
        tya
        pha
        lda #<irq2
        sta $fffe
        lda #>irq2
        sta $ffff
        inc $d012
        lda #1
        sta $d019
        tsx
        cli
        .rept 14
        nop
        .endrept
        brk                         ; (never reached)

        .align $100
        .page
irq2    txs
        ldx #8
-       dex
        bne -
        bit $00
        lda $d012
        cmp $d012
        beq +
+       ; stable: the same cycle of line 46 every frame
        lda d018a                   ; row 0's screen and set
        sta $d018
        ldx #0
        ; to row 0's line 0, cycle 8 (where the loop's first instruction is every row)
        .if PREK
        ldy #PREK
-       dey
        bne -
        .endif
        .rept PREN
        nop
        .endrept
        .if PREB
        bit $ea
        .endif

; One row: 504 cycles. (Where each write lands, counting from the forced bad line's write.)
row     ldy d018b,x                 ; the bottoms' screen ...
        sty $d018                   ; ... (lands after the row's bad line, cycle 58)
        .if D1K
        ldy #D1K
-       dey
        bne -
        .endif
        .rept D1N
        nop
        .endrept
        .if D1B
        bit $ea
        .endif
        lda #D011B                  ; the forced bad line: line 4, just after cycle 14
        sta $d011
        lda #D011A                  ; (the CPU waits out the bad line) YSCROLL back
        sta $d011
        .if D2K
        ldy #D2K
-       dey
        bne -
        .endif
        .rept D2N
        nop
        .endrept
        .if D2B
        bit $ea
        .endif
        ldy d018a+1,x               ; the next row's tops' screen and set, in the
        sty $d018                   ; horizontal blank between line 7 and line 0
        inx
        cpx #ROWS
        bne row
        .endpage

        ; the border: the frame's bookkeeping
        inc frames
        jsr frame
        lda #<irq1
        sta $fffe
        lda #>irq1
        sta $ffff
        lda #IRQLINE
        sta $d012
        lda #1
        sta $d019
        pla
        tay
        pla
        tax
        pla
        rti

; Move the scroll on a pixel (holding at the ends; holding if the next column isn't ready)
frame   lda pause
        beq +
        dec pause
        jmp setx
+       lda scrx                    ; the next position
        clc
        adc dir
        sta tmp
        lda dir
        bpl +
        lda #$ff
        .byte $2c
+       lda #0
        adc scrx+1
        sta tmp+1
        lda tmp+1                   ; its column
        lsr
        lda tmp
        ror
        lsr
        lsr
        cmp curc
        beq move
        cmp prepared                ; a new column: is the hidden pair ready for it?
        bne setx                    ; (no: hold)
        sta curc
        lda front
        eor #1
        sta front
        jsr usefront
        lda curc                    ; ... and the next one wanted
        clc
        adc dir
        sta target
move    lda tmp
        sta scrx
        lda tmp+1
        sta scrx+1
        ; at an end: turn round, hold, and want the column the other way
        lda scrx
        ora scrx+1
        beq turn
        lda scrx
        cmp #<MAXX
        bne setx
        lda scrx+1
        cmp #>MAXX
        bne setx
turn    lda dir
        eor #$fe
        sta dir
        lda #PAUSE
        sta pause
        lda curc
        clc
        adc dir
        sta target
setx    lda scrx
        and #7
        eor #7                      ; (38 columns)
        sta $d016
        rts

        .align $100
d018a   .fill ROWS + 1
d018b   .fill ROWS + 1
d18a0   .fill ROWS + 1
d18b0   .fill ROWS + 1
d18a1   .fill ROWS + 1
d18b1   .fill ROWS + 1
csbits  .byte ((CS0 & $3800) >> 10), ((CS1 & $3800) >> 10)
pairhi  .byte >SCR0, >SCR1, >SCR2, >SCR3
mul94lo .for i = 0, i < ROWS, i += 1
        .byte <(i * NC)
        .endfor
mul94hi .for i = 0, i < ROWS, i += 1
        .byte >(i * NC)
        .endfor
mul40lo .for i = 0, i < ROWS, i += 1
        .byte <(i * 40)
        .endfor
mul40hi .for i = 0, i < ROWS, i += 1
        .byte >(i * 40)
        .endfor
rowset  .binary "rowset.bin"
charsets .binary "charsets.bin"
tops    .binary "tops.bin"
bottoms .binary "bottoms.bin"
end
        .cerror end > SCR0, "the program runs into the screens"
