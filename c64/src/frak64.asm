; Frak! on the C64: display demo. Level A_1 ("FRAK!") in ECM with a forced bad line at line 4
; of every character row (4-line FLI), so every 8x4 half has its own glyph (tops from the first
; screen, bottoms from the second) and its own ECM background; two character sets, switched at
; the forced bad lines; the level scrolling left and right. No sprites yet, so the FLI bug's 3
; garbage characters show at the left of every row.
;
; VIC bank 1 ($4000-$7fff):
;   $4000/$4400  screen pair 0 (tops, bottoms)     $4800/$4c00  screen pair 1
;   $5000        character set 0 (64 characters)   $5800        character set 1
; Colour RAM is black throughout (every cell's foreground is black). ECM backgrounds: cyan,
; yellow, purple (Frak's magenta), black.
;
; Timing (PAL, 63 cycles a line): character row n starts at raster 51 + 8n (YSCROLL 3, a normal
; bad line, the tops' screen). At raster 55 + 8n, just after cycle 14, YSCROLL 7: a bad line the
; VIC didn't expect, which fetches the bottoms' screen's codes without resetting its row counter,
; so lines 4-7 show rows 4-7 of the new codes' characters. Just before it, $d018 switches to the
; bottoms' screen and to the character set for the band from here to line 3 of the next row (the
; set changes only here, so nothing else needs timing). After it, YSCROLL 3 again and the tops'
; screen for the next row's bad line.
;
; Only that one write in a row has to land on an exact cycle, so the display is an interrupt a
; row, not a loop that holds the CPU: CIA 1's timer B runs with a period of 504 cycles (8 lines;
; a PAL frame is exactly 39 of them) and interrupts at line 3 of each row. The interrupt reads
; the timer to see how late it was taken (the instruction it waited for: 0-15 cycles) and skips
; that much of a slide of cmp #$c9s, so the writes land on the same cycle every time. The other
; 14 ticks fall in the border; the first of them does the frame's bookkeeping.
;
; Built by ../build.sh (64tass, with tools/build.mjs); TS (when the timer starts: 24, the
; earliest that works), JM (what the timer's low nibble reads when the interrupt isn't late: 5)
; and RD (a delay before the interrupt reads it: none) are set there. MEASURE=1 replaces the foreground with a counting
; loop that measures the free cycles (in last: cycles a frame = last * 8 + (last >> 8) * 8);
; HIST=1 counts the timer's low nibble as the interrupt sees it (in hist).

        .include "level.inc"        ; NC (columns), ROWS

SCR0    = $4000                     ; pair 0: tops
SCR1    = $4400                     ;          bottoms
SCR2    = $4800                     ; pair 1: tops
SCR3    = $4c00                     ;          bottoms
CS0     = $5000
CS1     = $5800
IRQLINE = 44                        ; the raster interrupt that starts the timer (stable on 46)
TICK    = 504                       ; the timer's period: 8 lines
EARLY   = 96                        ; (its first period that much shorter: see irq2)
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
tmp     = zp + 12                   ; (2: the foreground's)
row     = zp + 14                   ; the timer's tick: 0-24 the rows, 25-38 the border
sava    = zp + 15
savx    = zp + 16
ftmp    = zp + 17                   ; (2: the interrupt's)
cnt     = zp + 19                   ; (2: MEASURE's count)
last    = zp + 21                   ; (2: ... a frame's)
jv      = zp + 23                   ; (2: the row's tail)
stall0  = zp + 25
SPRCOVER = $5400                    ; the cover sprite's data
COVERX  = 24                        ; its x at fine scroll 0
COVERY0 = 50                        ; its first piece's y (lines 51-92; then 93, 135, 177, 219)

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
        lda #0                      ; timer B stopped, its latch the first, short period
        sta $dc0f
        lda #<(TICK - 1 - EARLY)
        sta $dc06
        lda #>(TICK - 1 - EARLY)
        sta $dc07
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

        ; Sprite 7: the cover over the FLI bug's columns at the left (4 characters: 16 pixels
        ; set, expanded both ways), cyan like the border, in front; down the screen in 42-line
        ; pieces (covery), so the VIC fetches it on line 4 of every row
        ldx #62
-       lda #0
        sta SPRCOVER,x
        dex
        bpl -
        ldx #60
-       lda #$ff
        sta SPRCOVER,x
        sta SPRCOVER+1,x
        dex
        dex
        dex
        bpl -
        lda #(SPRCOVER & $3fff) / 64
        sta SCR0 + $3ff
        sta SCR1 + $3ff
        sta SCR2 + $3ff
        sta SCR3 + $3ff
        lda #3
        sta $d02e
        lda #COVERY0
        sta $d00f
        lda #COVERX + 7
        sta $d00e
        lda #$80
        sta $d017                   ; (expanded down)
        sta $d01d                   ; (... and across)
        lda #0
        sta $d010
        sta $d01b                   ; (in front of the characters)
        sta $d01c                   ; (hi-res)
        lda #$80
        .if TEST
        ; (the test: sprites 0-6 in the left border, where they can't be seen, but are fetched)
        ldx #0
        ldy #0
-       lda testy,y
        sta $d001,x
        lda #0
        sta $d000,x
        iny
        inx
        inx
        cpx #14
        bne -
        lda #(SPRCOVER & $3fff) / 64
        ldx #6
-       sta SCR0 + $3f8,x
        sta SCR1 + $3f8,x
        sta SCR2 + $3f8,x
        sta SCR3 + $3f8,x
        dex
        bpl -
        lda #TESTEXP
        sta $d017
        lda #$ff
        .endif
        sta $d015

        ; the tail for each row, from which sprites are on its line 4 (masks)
        ldx #ROWS - 1
-       ldy masks,x
        lda masktl,y
        sta rowtl,x
        lda maskth,y
        sta rowth,x
        dex
        bpl -

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

        ; the $d018 tables for each pair: for row n, a: the tops' screen and band n's set (from
        ; the forced bad line of row n-1); b: the bottoms' screen and band n+1's
        ldx #0
-       ldy bandset,x
        lda csbits,y
        ora #(SCR0 & $3c00) >> 6
        sta d18a0,x
        lda csbits,y
        ora #(SCR2 & $3c00) >> 6
        sta d18a1,x
        ldy bandset+1,x
        lda csbits,y
        ora #(SCR1 & $3c00) >> 6
        sta d18b0,x
        lda csbits,y
        ora #(SCR3 & $3c00) >> 6
        sta d18b1,x
        inx
        cpx #ROWS + 1
        bne -

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
        lda #0
        sta row
        sta cnt
        sta cnt+1
        lda #1                      ; a raster interrupt, once, to start the timer in step
        sta $d01a
        sta $d019
        cli
        .if MEASURE
measure inc cnt                     ; (8 cycles a count, 16 every 256th)
        bne measure
        inc cnt+1
        jmp measure
        .endif

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
        beq idle
        lda prow
        cmp #ROWS
        bcc +
        lda working                 ; done
        sta prepared
        jmp idle
+       jsr fillrow
        jmp main
; (nothing to do: a mix of long instructions and taken branches, as the game will have, to
; give the interrupt every lateness it can meet)
idle    ldx #8
-       inc junk,x
        lsr junk+8
        dex
        bne -
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

; The pair shown: point the interrupt at its $d018 tables
usefront
        lda front
        bne +
        lda #<d18a0
        sta rl0+1
        lda #<(d18a0+1)
        sta rla+1
        lda #>d18a0
        sta rla+2
        sta rl0+2
        lda #<d18b0
        sta rlb+1
        lda #>d18b0
        sta rlb+2
        rts
+       lda #<d18a1
        sta rl0+1
        lda #<(d18a1+1)
        sta rla+1
        lda #>d18a1
        sta rla+2
        sta rl0+2
        lda #<d18b1
        sta rlb+1
        lda #>d18b1
        sta rlb+2
        rts

nmi     rti

; ---- Starting: a double raster interrupt for a stable raster, then the timer started on a
; known cycle (its first period EARLY cycles short, so TS can't need to be negative)
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
        .if TSK
        ldy #TSK
-       dey
        bne -
        .endif
        .rept TSN
        nop
        .endrept
        .if TSB
        bit $ea
        .endif
        lda #%00010001              ; timer B: start, continuous, the latch loaded
        sta $dc0f
        lda #<(TICK - 1)            ; ... and every period after the first, 504 cycles
        sta $dc06
        lda #>(TICK - 1)
        sta $dc07
        lda d18a0                   ; row 0's screen and set
        sta $d018
        lda #0                      ; the raster interrupt done with
        sta $d01a
        lda #1
        sta $d019
        lda #<rowirq
        sta $fffe
        lda #>rowirq
        sta $ffff
        lda $dc0d
        lda #$82                    ; timer B's interrupts
        sta $dc0d
        pla
        tay
        pla
        tax
        pla
        rti
        .endpage

; ---- A tick: line 3 of a character row (ticks 0-24), or the border (25-38)
        .align $100
        .page
rowirq  sta sava
        .rept RDN
        nop
        .endrept
        .if RDB
        bit $ea
        .endif
        lda #JM                     ; how late this was taken (0-15 cycles): the timer's low
        sec                         ; nibble, counting down, from what it reads when the
        sbc $dc06                   ; interrupt is taken at once (JM)
        and #15
        .if HIST
        stx savx
        tax
        inc hist,x
        txa
        ldx savx
        .endif
        sta _br+1
_br     bpl _sl                     ; ... that many bytes of the slide skipped (a cycle each)
_sl     .fill 15, $c9               ; (cmp #$c9 ... cmp #$c5, nop; or ... cmp $ea)
        .byte $c5, $ea
        ; the same cycle every time
        lda $dc0d                   ; (acknowledged first, so a tick due during this one isn't lost)
        stx savx
        ldx row
        cpx #ROWS
        bcs border
        lda covery,x                ; the cover sprite's next place down the screen
        sta $d00f
        lda rowtl,x                 ; the tail for this row's sprites on line 4
        sta jv
        lda rowth,x
        sta jv+1
rlb     lda d18b0,x                 ; the bottoms' screen, the next band's set
        tax
        .if STALL
        lda $dc06                   ; (STALL: the timer before the tail ...)
        sta stall0
        lda #D011A                  ; (... and no forced bad line, whose wait would hide the rest)
        .else
        lda #D011B
        .endif
        jmp (jv)
        .endpage

; The tails (tails.inc, made by build.mjs): $d018 written on line 3's cycle 55, then a delay
; that depends on which sprites the VIC fetches for line 4 (sprites 0-2 at the end of line 3,
; 3-7 at the start of line 4, each stopping the CPU for a few cycles), then the forced bad line
; written on line 4's cycle 14 (or 15, where no delay can reach 14). Then:
tailend lda #D011A                  ; (the CPU has waited out the bad line) YSCROLL back
        sta $d011
        ldx row
        .if MASKTEST
        ; (MASKTEST: the test sprites' y for the next test row, row by row)
        lda mty0,x
        sta $d001
        lda mty1,x
        sta $d003
        lda mty2,x
        sta $d005
        lda mty3,x
        sta $d007
        lda mty4,x
        sta $d009
        lda mty5,x
        sta $d00b
        lda mty6,x
        sta $d00d
        .endif
        .if STALL
        lda $dc06                   ; (... and after: their difference, row by row)
        sec
        sbc stall0
        eor #$ff
        sta stalls,x
        .endif
rla     lda d18a0+1,x               ; the next row's tops' screen (the same set)
        sta $d018
        inx
        stx row
        ldx savx
        lda sava
        rti

border  bne +                       ; tick 25: the frame's bookkeeping
        lda #COVERY0                ; (the cover sprite back to the top, for the next frame)
        sta $d00f
        inc frames
        jsr frame
        .if MEASURE
        lda cnt
        sta last
        lda cnt+1
        sta last+1
        lda #0
        sta cnt
        sta cnt+1
        .endif
        ldx #ROWS
+       inx
        cpx #39
        bcc +
rl0     lda d18a0                   ; tick 38 (line 46): row 0's screen and set
        sta $d018
        ldx #0
+       stx row
        ldx savx
        lda sava
        rti

        .include "tails.inc"

; Move the scroll on a pixel (holding at the ends; holding if the next column isn't ready)
frame   lda pause
        beq +
        dec pause
        jmp setx
+       lda scrx                    ; the next position
        clc
        adc dir
        sta ftmp
        lda dir
        bpl +
        lda #$ff
        .byte $2c
+       lda #0
        adc scrx+1
        sta ftmp+1
        lda ftmp+1                   ; its column
        lsr
        lda ftmp
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
move    lda ftmp
        sta scrx
        lda ftmp+1
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
        clc                         ; the cover sprite follows the fine scroll
        adc #COVERX
        sta $d00e
        rts

        .align $100
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
bandset .binary "bandset.bin"
junk    .fill 16
hist    .fill 16
stalls  .fill ROWS
rowtl   .fill ROWS
rowth   .fill ROWS
; the cover sprite's y for each row's tick: the next piece's, once this one has started
covery  .for i = 0, i < ROWS, i += 1
_y      := COVERY0 + 42 * (1 + ((54 + 8 * i) - (COVERY0 + 1)) / 42)
        .byte _y > COVERY0 + 4 * 42 ? COVERY0 + 4 * 42 : _y   ; (the last piece runs past the bottom)
        .endfor
        .include "masks.inc"
        .include "mty.inc"
charsets .binary "charsets.bin"
tops    .binary "tops.bin"
bottoms .binary "bottoms.bin"
end
        .cerror end > SCR0, "the program runs into the screens"
