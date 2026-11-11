; Frak! on the C64: display demo. Level A_1 ("FRAK!") in ECM with a forced bad line at line 4
; of every character row (4-line FLI), so every 8x4 half has its own glyph (tops from the first
; screen, bottoms from the second) and its own ECM background; two character sets, switched at
; the forced bad lines; the level scrolling left and right. Sprite 0 covers the FLI bug's
; garbage at the left of every row; sprites 3-7 are the Scrubblies' bodies.
;
; VIC bank 1 ($4000-$7fff):
;   $4000/$4400  screen pair 0 (tops, bottoms)     $4800/$4c00  screen pair 1
;   $5000        character set 0 (64 characters)   $5800        character set 1
;   $5400        the cover sprite                 $5440        the Scrubblies' sprite
; Colour RAM is black throughout (every cell's foreground is black). ECM backgrounds: cyan,
; yellow, purple (Frak's magenta), black.
;
; Timing (PAL, 63 cycles a line): character row n starts at raster 51 + 8n (YSCROLL 3, a normal
; bad line, the tops' screen). At raster 55 + 8n, just after cycle 14, YSCROLL 7: a bad line the
; VIC didn't expect, which fetches the bottoms' screen's codes without resetting its row counter,
; so lines 4-7 show rows 4-7 of the new codes' characters. On line 3's cycle 55, $d018 switches
; to the bottoms' screen and to the character set for the band from there to line 3 of the next
; row (the set changes only there). After the bad line, YSCROLL 3 again and the tops' screen for
; the next row's bad line.
;
; Only those writes in a row need timing, so the display is an interrupt a row: CIA 1's timer B
; runs with a period of 504 cycles (8 lines; a PAL frame is exactly 39 of them) and interrupts in
; line 2 of each row. It reads the timer to see how late it was taken and skips that much of a
; slide of cmp #$c9s; then, reading only, it goes through the VIC's fetches of the sprites shown
; on lines 3 and 4, which stop the CPU for a few cycles each (see rowirq): the slide skips line
; 3's too, and a tail with a delay to suit line 4's leads to the forced bad line's write. Which
; sprites are shown where (masks3, masks) picks both, from tables made by tools/build.mjs from a
; model of the fetches, checked in VICE for every mask of sprites. The other 14 ticks fall in the
; border; the first of them does the frame's bookkeeping, the last sets row 0 up.
;
; Built by ../build.sh (64tass, with tools/build.mjs), which sets TS (when the timer starts, the
; earliest that works). MEASURE=1 replaces the foreground with a counting loop that measures the
; free cycles (in last: cycles a frame = last * 8 + (last >> 8) * 8); HIST=1 counts the slide's
; skips (in hist); TEST=1 puts sprites 1-7 in the left border (unseen, but fetched).

        .include "level.inc"        ; NC (columns), ROWS

SCR0    = $4000                     ; pair 0: tops
SCR1    = $4400                     ;          bottoms
SCR2    = $4800                     ; pair 1: tops
SCR3    = $4c00                     ;          bottoms
CS0     = $5000
CS1     = $5800
IRQLINE = 44                        ; the raster interrupt that starts the timer (stable on 46)
TICK    = 504                       ; the timer's period: 8 lines
EARLY   = 160                        ; (its first period that much shorter: see irq2)
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
sprites = zp + 25                   ; ($d015, once the timer's going)
msb     = zp + 26                   ; (the sprites' x's bit 8)
savy    = zp + 27
bufoff  = zp + 28                   ; the multiplexer's buffer being shown (0, 32), and being made
nb      = zp + 29
muxreq  = zp + 30                   ; (a frame's multiplexing wanted; done)
muxready = zp + 31
mi      = zp + 32                   ; (the multiplexer's)
mcur    = zp + 33
mkey    = zp + 34
mo      = zp + 35
mv      = zp + 36
my      = zp + 37
ml      = zp + 38
mk      = zp + 39
mlim    = zp + 40
ni      = zp + 41
ment    = zp + 42
mt      = zp + 43
mh      = zp + 44
mbit    = zp + 45
mfl     = zp + 46
mlo     = zp + 47
mhi     = zp + 48
acnt    = zp + 49
s010    = zp + 50
s017    = zp + 51
s01d    = zp + 52
s01b    = zp + 53
NS      = 5                         ; the Scrubblies
NB      = 6                         ; the balloons and daggers (at most)
SPRBALL = $5480                     ; the balls' sprite
flippend = zp + 54                  ; (the next frame's scroll, decided in the main program:
targpend = zp + 55                  ;  a pair flip and a new target for the border to make)
ntarget = zp + 56
muxbusy = zp + 57
dtmp    = zp + 58                   ; (2)
mt0     = zp + 60
mte     = zp + 61                   ; (the multiplexer's)
mk2     = zp + 62
mj      = zp + 63
mnv     = zp + 64
shx     = zp + 65                   ; the scroll position shown (its low byte: scrx is the next frame's)
SPRSCRUB = $5440                    ; the Scrubblies' sprite
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

        ; Sprite 0: the cover over the FLI bug's columns at the left (4 characters: 16 pixels
        ; set, expanded both ways), cyan like the border, in front of the characters and of
        ; every other sprite; down the screen in 42-line pieces (covery)
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
        sta SCR0 + $3f8
        sta SCR1 + $3f8
        sta SCR2 + $3f8
        sta SCR3 + $3f8
        lda #3
        sta $d027
        lda #COVERY0
        sta $d001
        lda #COVERX + 7
        sta $d000
        lda #0
        sta $d010
        sta $d01c                   ; (all hi-res)
        .if !TEST
        ; Sprites 3-7: shared out by the multiplexer (mux.asm) among the virtual sprites: the
        ; Scrubblies' bodies (expanded both ways, magenta, behind the characters, so their black
        ; and the eyes' and teeth's yellow are in front, their x following the scroll) and some
        ; balls bouncing about
        ldx #62
-       lda sprscrub,x
        sta SPRSCRUB,x
        lda sprball,x
        sta SPRBALL,x
        dex
        bpl -
        ldx #NS - 1
-       lda scruby,x
        sta vy,x
        lda #(SPRSCRUB & $3fff) / 64
        sta vptr,x
        lda #4
        sta vcol,x
        lda #VHIDE
        sta vfl,x
        dex
        bpl -
        ldx #NB - 1
-       lda #(SPRBALL & $3fff) / 64
        sta vptr + NS,x
        lda #1
        sta vcol + NS,x
        lda #VHIDE
        sta vfl + NS,x
        dex
        bpl -
        lda #255                    ; (parked below the screen until set up)
        sta $d007
        sta $d009
        sta $d00b
        sta $d00d
        sta $d00f
        lda #1
        sta $d017
        sta $d01d
        lda #0
        sta $d01b
        sta bufoff
        sta muxready
        sta muxreq
        sta muxbusy
        sta flippend
        sta targpend
        lda #$f9
        .else
        ; (the test: sprites 1-7 in the left border, where they can't be seen, but are fetched)
        ldx #2
        ldy #0
-       lda testy,y
        sta $d001,x
        lda #0
        sta $d000,x
        iny
        inx
        inx
        cpx #16
        bne -
        lda #(SPRCOVER & $3fff) / 64
        ldx #6
-       sta SCR0 + $3f9,x
        sta SCR1 + $3f9,x
        sta SCR2 + $3f9,x
        sta SCR3 + $3f9,x
        dex
        bpl -
        lda #TESTEXP
        sta $d017
        lda #1
        sta $d01d
        lda #0
        sta $d01b
        lda #$ff
        .endif
        sta sprites                 ; (shown once the timer has started: their fetches would upset
        lda #0                      ; the stable raster that starts it)
        sta $d015

        ; each row's sprites on its lines 3 and 4 (buffer 0, until the multiplexer's first frame)
        ldx #ROWS - 1
-       ldy masks,x
        lda masktl,y
        sta rowtl,x
        lda maskth,y
        sta rowth,x
        ldy masks3,x
        lda maskjm,y
        sta rowimm,x
        dex
        bpl -
        .if !TEST
        jsr muxinit                 ; (the multiplexer's: no sprites yet, in either buffer)
        .endif

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
        sta shx
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
measure lda muxreq                  ; (the scroll and the multiplexer still run)
        beq +
        jsr nextframe
+       inc cnt                     ; (8 cycles a count, 16 every 256th)
        bne measure
        inc cnt+1
        jmp measure
        .endif

; The foreground: keep the hidden pair filled for the column the interrupt wants next
        .if MUXTIME
        lda #$ff                    ; (debug: CIA 2's timer A free running, for muxframe's stamps)
        sta $dd04
        sta $dd05
        lda #$11
        sta $dd0e
        .endif
main    .if !TEST
        lda muxreq                  ; once a frame: the next frame's scroll, the game's sprites
        beq +                       ; and the multiplexer
        jsr nextframe
+
        .endif
        lda target
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

; Once a frame (after the border's switched to the last): the next frame's scroll, the game's
; sprites and the multiplexer
nextframe
        lda #1                      ; (busy before the request's gone: the border mustn't ask again)
        sta muxbusy
        lda #0
        sta muxreq
        jsr decide
        jsr muxframe
        lda #0
        sta muxbusy
        rts

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
        sta rlc+1
        lda #>d18b0
        sta rlb+2
        sta rlc+2
        lda #>(SCR0 + $3f8)         ; (the multiplexed sprites' pointers: this pair's)
        sta aps0+2
        sta apt0+2
        lda #>(SCR1 + $3f8)
        sta aps1+2
        sta apt1+2
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
        sta rlc+1
        lda #>d18b1
        sta rlb+2
        sta rlc+2
        lda #>(SCR2 + $3f8)
        sta aps0+2
        sta apt0+2
        lda #>(SCR3 + $3f8)
        sta aps1+2
        sta apt1+2
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
        lda sprites                 ; the sprites on
        sta $d015
        lda #0                      ; the raster interrupt done with
        sta $d01a
        lda #1
        sta $d019
        ldx #0                      ; row 0's interrupt
        jsr prep
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

; ---- A row's tick: line 2 of character row n (ticks 0-24). From the timer read to the $d018
; write the CPU only reads (but for the slide's operand, written before the sprite fetches): the
; VIC's fetches of the sprites shown on line 3 (from line 2's cycle 55 to line 3's 10) and on
; line 4 (from line 3's 55 to line 4's 10) each stop it for a few cycles, so where the writes
; land depends on which sprites are shown there. Line 3's: the slide skips that many more cycles
; (rjm, from this row's mask of sprites on line 3), so the $d018 write still lands on line 3's
; cycle 55. Line 4's: the tail (rtj, from the mask on line 4) has a delay to suit before the
; forced bad line's write on line 4's cycle 14. Everything a row needs is set by the row before
; (prep), as operands.
        .align $100
        .page
rowirq  sta sava
        stx savx
rjm     lda #0                      ; (JM, and line 3's fetches: see prep)
        sec                         ; how late this was taken, the timer's low bits counting
        sbc $dc06                   ; down, and line 3's fetches yet to come: 0-31 cycles ...
        and #31
        .if HIST
        tax
        inc hist,x
        txa
        .endif
        sta _br+1
_br     bpl _sl                     ; ... that many bytes of the slide skipped (a cycle each)
_sl     .fill 31, $c9               ; (cmp #$c9 ... cmp #$c5, nop; or ... cmp $ea)
        .byte $c5, $ea
        .rept 8                     ; (so the read and that write come well before line 3's
        nop                         ; fetches, however late this was taken)
        .endrept
        ; (line 3's cycle 11 or later: the same cycle every time)
        lda $dc0d                   ; (acknowledged)
rcy     lda #0                      ; the cover sprite's next place down the screen
        sta $d001
rx      ldx #0                      ; the bottoms' screen, the next band's set
        lda #D011B
rtj     jmp tailend                   ; (the tail for line 4's fetches)
        .endpage

; The tails (tails.inc, made by build.mjs): $d018 written on line 3's cycle 55, a delay, and the
; forced bad line written on line 4's cycle 14 (or 15, where no delay can reach 14). Then:
tailend lda #D011A                  ; (the CPU has waited out the bad line) YSCROLL back
        sta $d011
        sty savy
        ldx row
rla     lda d18a0+1,x               ; the next row's tops' screen (the same set)
        sta $d018
        inx
        stx row
        txa                         ; (x: the next row, in the buffer shown)
        clc
        adc bufoff
        tax
        .if !TEST
        ldy u_n,x                   ; this tick's sprite set-up, if any (list row + 1: one at
        bmi tnosu                   ; most), inline, as there's little time before the next
        lda trch,x                  ; row's interrupt; the registers only if they change
        beq tnreg
        lda t010,x
        sta $d010
        lda t017,x
        sta $d017
        lda t01d,x
        sta $d01d
        lda t01b,x
        sta $d01b
tnreg   lda u_ptr,x
apt0    sta SCR0 + $3f8,y
apt1    sta SCR1 + $3f8,y
        lda u_col,x
        sta $d027,y
        ldy u_reg,x
        lda u_x,x
        sta $d000,y
        lda u_y,x
        sta $d001,y
tnosu
        .endif
        lda row
        cmp #ROWS
        bcs +
        lda rowtl,x                 ; the next row's interrupt's operands (prep, inline)
        sta rtj+1
        lda rowth,x
        sta rtj+2
        lda rowimm,x
        sta rjm+1
        ldx row
        lda covery,x
        sta rcy+1
rlc     lda d18b0,x
        sta rx+1
        .if SLACK
        ldx row                     ; (debug: each row's least slack before the next tick, and
        lda $dc07                   ; how often there was none)
        bne _sov
        lda $dc06
        cmp slacklo,x
        bcs _sdn
        sta slacklo,x
        bcc _sdn
_sov    lda $dc06                   ; (256-399 left: plenty; 400 on: the next tick's come)
        cmp #400 - 256
        bcc _sdn
        inc slackhi,x
_sdn
        .endif
        ldy savy
        ldx savx
        lda sava
        rti
+       lda #<bordirq               ; (the rows done: the border's ticks)
        sta $fffe
        lda #>bordirq
        sta $ffff
        ldy savy
        ldx savx
        lda sava
        rti

; Row x's interrupt: the operands it uses
prep    lda covery,x
        sta rcy+1
rlb     lda d18b0,x
        sta rx+1
        txa
        clc
        adc bufoff
        tay
        lda rowtl,y                 ; (its tail, for its sprites on line 4)
        sta rtj+1
        lda rowth,y
        sta rtj+2
        lda rowimm,y                ; (its slide's constant, for those on line 3)
        sta rjm+1
        rts

; ---- A border tick (25-38): the first does the frame's bookkeeping, the last sets row 0 up
bordirq sta sava
        stx savx
        sty savy                    ; (the frame's bookkeeping uses y)
        lda $dc0d
        ldx row
        cpx #ROWS
        bne +
        lda #COVERY0                ; (the cover sprite back to the top, for the next frame)
        sta $d001
        inc frames
        .if !TEST
        lda muxready                ; the next frame's scroll and sprites, together, once the
        beq _nmux                   ; multiplexer has made them; and then the frame after wanted
        lda bufoff                  ; (or, if it's not working on one, this one again)
        eor #32
        sta bufoff
        lda #0
        sta muxready
        .if SLACK
        inc nswap
        .endif
        jsr frame
        jmp _wmux
_nmux   .if SLACK
        inc nhold                   ; (debug: frames the multiplexer wasn't ready)
        .endif
        jsr setx
        lda muxbusy
        bne _dmux
_wmux   lda #1
        sta muxreq
_dmux
        .else
        jsr frame
        .endif
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
        bcs +
        stx row
        .if !TEST
        cpx #38                     ; tick 37 (line 37): sprites 3-7 parked below the screen, then
        bne t37n                    ; those set up before the frame (tick 0's slots), and the
        lda #255                    ; registers (in time for sprites from line 47, and leaving
        sta $d007                   ; tick 38 little to do before row 0's)
        sta $d009
        sta $d00b
        sta $d00d
        sta $d00f
        ldy bufoff
        lda t010,y
        sta $d010
        lda t017,y
        sta $d017
        lda t01d,y
        sta $d01d
        lda t01b,y
        sta $d01b
        jsr apply0
t37n
        .endif
        ldy savy
        ldx savx
        lda sava
        rti
+
rl0     lda d18a0                   ; tick 38 (line 45): row 0's screen and set
        sta $d018
        ldx #0
        stx row
        jsr prep
        .if SLACK
        lda $dc07                   ; (debug: tick 38's least slack before row 0's tick)
        bne +
        lda $dc06
        cmp slacklo
        bcs +
        sta slacklo
+
        .endif
        lda #<rowirq
        sta $fffe
        lda #>rowirq
        sta $ffff
        ldy savy
        ldx savx
        lda sava
        rti

        .include "tails.inc"

; The next frame's scroll (in the main program, with the multiplexer, during the frame before):
; a pixel on (holding at the ends; holding if the next column isn't ready). A new column's pair
; flip, and the column the hidden pair should be filled for next, are left for the border to make
; (flippend, targpend), and $d016 for it to write
decide  lda pause
        beq +
        dec pause
        rts
+       lda scrx                    ; the next position
        clc
        adc dir
        sta dtmp
        lda dir
        bpl +
        lda #$ff
        .byte $2c
+       lda #0
        adc scrx+1
        sta dtmp+1
        lsr                         ; its column
        lda dtmp
        ror
        lsr
        lsr
        cmp curc
        beq _move
        cmp prepared                ; a new column: is the hidden pair ready for it?
        bne _hold                   ; (no: hold)
        sta curc
        clc                         ; (the flip, and the next column wanted)
        adc dir
        sta ntarget
        lda #1
        sta targpend
        sta flippend
_move   lda dtmp
        sta scrx
        lda dtmp+1
        sta scrx+1
        ora scrx                    ; at an end: turn round, hold, and want the column the
        beq _turn                   ; other way
        lda scrx
        cmp #<MAXX
        bne _hold
        lda scrx+1
        cmp #>MAXX
        bne _hold
_turn   lda dir
        eor #$fe
        sta dir
        lda #PAUSE
        sta pause
        lda curc
        clc
        adc dir
        sta ntarget
        lda #1
        sta targpend
_hold   rts

; In the border: the scroll decided (the flip, the target, $d016 and the cover sprite's x)
frame   lda scrx                    ; (the position the multiplexer's frame was made for)
        sta shx
        lda flippend
        beq +
        lda #0
        sta flippend
        lda front
        eor #1
        sta front
        jsr usefront
        .if SLACK
        lda curc
        sta frontc
        .endif
+       lda targpend
        beq +
        lda #0
        sta targpend
        lda ntarget
        sta target
+
setx    lda shx
        and #7
        eor #7                      ; (38 columns)
        sta $d016
        clc                         ; the cover sprite follows the fine scroll
        adc #COVERX
        sta $d000
        rts

        .include "mux.asm"

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
hist    .fill 32
sprscrub .binary "scrubspr.bin"
; the cover sprite's y for each row's tick: the next piece's, once this one has started
covery  .for i = 0, i < ROWS, i += 1
_y      := COVERY0 + 42 * (1 + ((54 + 8 * i) - (COVERY0 + 1)) / 42)
        .byte _y > COVERY0 + 4 * 42 ? COVERY0 + 4 * 42 : _y   ; (the last piece runs past the bottom)
        .endfor
        .include "masks.inc"
charsets .binary "charsets.bin"
tops    .binary "tops.bin"
bottoms .binary "bottoms.bin"
end
        .cerror end > SCR0, "the program runs into the screens"
        ; (then the VIC bank: the screens, character sets, sprites and the multiplexer's RAM, all
        ; set up at the start; and what's loaded straight into it)
        .fill $6800 - *, 0
TROGG   .binary "trogg.bin"         ; Trogg's sprites: per frame outline P1-P3, infill P1-P3
        .cerror * > $8000, "Trogg's sprites run out of the VIC bank"
