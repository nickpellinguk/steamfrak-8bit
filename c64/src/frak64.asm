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

; (--profile: CIA 2's timer A, free running, read at each stage of a frame's work into pstage;
; each frame's record (32 bytes) then copied into a ring at $e000-$fdff (tools/frameprof.py))
pst     .macro
        .if PROFILE
-       lda $dd05
        ldx $dd04
        cmp $dd05
        bne -
        sta pstage + \1 + 1
        stx pstage + \1
        .endif
        .endm
scrx    = zp + 0                    ; scroll position, pixels (16 bits)
dir     = zp + 2                    ; +1 or -1 ($ff)
pause   = zp + 3
curc    = zp + 4                    ; the coarse position (map column at screen column 0) shown
front   = zp + 5                    ; the pair shown (0/1)
lfront  = zp + 6                    ; the pair shown from the next frame on (front: now)
working = zp + 7                    ; the window the foreground is filling the hidden pair for
fsh     = zp + 8                    ; ... its VSP offset there
prow    = zp + 9                    ; the next row to fill
back    = zp + 10                   ; the hidden pair (lfront's other)
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
SPRBALLOON = $5480                  ; the balloon's sprite (hazards.asm)
SPRDAGGER = $55c0                   ; the dagger's
SPRFRAK = $5600                     ; the FRAK! bubble's 2 (its black, its yellow)
SPRBLANK = $5680                    ; a blank sprite (zeros: for a Scrubbly knocked off, yoyo.asm)
SPRBINF = $56c0                     ; the balloon's infill's 2 (top-justified, bottom-justified)
SPRBMC  = $5740                     ; the balloon in multicolour (the fallback, mux.asm)
SPRTIMER = $5780                    ; the timer (tmdraw)
flippend = zp + 54                  ; (the next frame's scroll, decided in the main program: a pair
wanto   = zp + 55                   ;  flip for the border to make; the hidden pair's origin wanted;
nvs     = zp + 56                   ;  the VSP offset)
muxbusy = zp + 57
qn      = zp + 119                  ; (frames made and waiting to be shown: 0-2; mux.asm)
nlast   = zp + 120                  ; (the buffer made last)
nf      = zp + 121                  ; (the buffer a frame's being copied from: nlast, as it was)
fliphere = zp + 122                 ; (the frame being made flips the pairs: cstep, camera)
MUXRAM  = $c000                     ; (the multiplexer's model and buffers: mux.asm)
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
COVERY0 = 49                        ; its first piece's y (lines 50-91; then 92, 134, 176, 218): from
                                    ; line 50, to hide the VSP line's garbage there (vspcov)

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
        .if FRONT
        jsr attract                 ; (the attract screen, till a key: front.asm)
        .endif
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
        lda #0                      ; Trogg (trogg.asm): sprite 1 his black outline, sprite 2 his
        sta $d028                   ; infill (multicolour: yellow, magenta)
        lda #4
        sta $d01c
        lda #7
        sta $d025
        lda #4
        sta $d026
        lda #255                    ; (parked below the screen until the first frame)
        sta $d003
        sta $d005
        .endif
        .if !TEST
        ; Sprites 3-7: shared out by the multiplexer (mux.asm) among the virtual sprites: the
        ; Scrubblies' bodies (expanded both ways, magenta, behind the characters, so their black
        ; and the eyes' and teeth's yellow are in front, their x following the scroll), the
        ; balloons and daggers (hazards.asm: their sprites made by build.mjs) and the yoyo
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
        ldx #1
-       lda #(SPRFRAK & $3fff) / 64
        clc
        adc fkblk,x
        sta vptr + FV,x
        lda fkcol,x
        sta vcol + FV,x
        lda #VHIDE | VFIRST | VEXPX
        sta vfl + FV,x
        dex
        bpl -
        lda #0
        sta vcol + YV
        lda #VHIDE | VFIRST
        sta vfl + YV
        ldx #NB - 1
-       lda #VHIDE
        sta vfl + NS,x
        lda #(SPRBINF & $3fff) / 64 ; (the balloons' infill: magenta, low priority, mux.asm)
        sta vptr + BIV,x
        lda #4
        sta vcol + BIV,x
        lda #VLOW | VHIDE
        sta vfl + BIV,x
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
        sta nlast
        sta qn
        sta muxready
        sta muxreq
        sta muxbusy
        sta flippend
        sta fliphere
        lda #$ff
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
        jsr fresh                   ; (and what it keeps from frame to frame)
        jsr tmreset                 ; (the timer at 0:00)
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

        ; pair 0 filled for window 0 with origin -8 (VSP offset 8) and shown; pair 1 then filled
        ; the same in the background (po, pvw: scroll.asm)
        lda #0
        sta scrx
        sta scrx+1
        sta shx
        sta curc
        sta front
        sta lfront
        sta frames
        lda #1
        sta dir
        lda #PAUSE
        sta pause
        lda #0
        sta back
        sta working
        sta prow
        lda #8
        sta fsh
        sta nvs
-       jsr fillrow
        lda prow
        cmp #ROWS
        bne -
        jsr usefront
        jsr setvsp
        lda #1
        sta back
        lda #$f8
        sta wanto
        lda #0
        sta prow
        .if !TEST
        ; the multiplexer's first frames made before anything's shown (it places 4 sprites a
        ; frame at most): until every Scrubbly on the screen has its sprite (4 frames at most),
        ; the last of them the first frame shown, so the characters never show without them
        lda #4
        sta pre
-       jsr nextframe
        dec pre
        beq +
        ldx #NS - 1
_pr     lda vfl,x
        bmi _pn
        lda vy,x
        cmp #47
        bcc _pn
        cmp #251
        bcs _pn
        lda vh,x
        bmi -
_pn     dex
        bpl _pr
+       lda nlast
        sta bufoff
        lda #0
        sta qn
        jsr qapply
        .endif

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
measure lda qn                      ; (the scroll and the multiplexer still run)
        cmp #2
        bcs +
        jsr nextframe
+       inc cnt                     ; (8 cycles a count, 16 every 256th)
        bne measure
        inc cnt+1
        jmp measure
        .endif

; The foreground: the hidden pair kept filled and up to date for the next swap (bgwork)
        .if MUXTIME || PROFILE
        lda #$ff                    ; (debug: CIA 2's timer A free running, for muxframe's stamps)
        sta $dd04
        sta $dd05
        lda #$11
        sta $dd0e
        .endif
main    .if !TEST
        lda qn                      ; a frame (the next frame's scroll, the game's sprites and the
        cmp #2                      ; multiplexer) whenever there's a buffer for it: up to two
        bcs +                       ; ahead of the one shown, so a quick frame's time is kept for
        jsr nextframe               ; a slow one
+
        .endif
        jsr bgwork                  ; the hidden pair's work, a piece
        bcc main
; (nothing to do: a mix of long instructions and taken branches, as the game will have, to
; give the interrupt every lateness it can meet)
idle    ldx #8
-       inc junk,x
        lsr junk+8
        dex
        bne -
        jmp main

; A frame made (up to two ahead of the one shown): the next frame's scroll, the game's sprites
; and the multiplexer; then its settings for the border (qsave), and it's waiting to be shown
nextframe
        lda #0
        sta fliphere
        #pst 0
        #pst 2
        jsr gametick                ; (a game tick: the keys, Trogg)
        #pst 4
        jsr decide
        #pst 6
        jsr trogset                 ; (Trogg's sprites, for the next frame's scroll)
        #pst 8
        jsr yoyoset                 ; (the yoyo's sprite, and its string)
        #pst 10
        jsr frakset                 ; (the FRAK! bubble)
        #pst 12
        jsr strset
        #pst 14
        jsr muxframe
        jsr qsave
        .if PROFILE
        jmp precord
        .else
        rts
        .endif

; The frame made (in buffer nb): what the border needs to show it (qapply), kept by buffer: the
; scroll, a flip of the pairs, the VSP offset, the yoyo's string, Trogg's settings
qsave   lda nb
        lsr
        lsr
        lsr
        lsr
        lsr
        tax
        lda scrx
        sta q_shx,x
        lda fliphere
        sta q_flip,x
        lda nvs
        sta q_nvs,x
        lda sp_on
        sta q_on,x
        lda sp_r
        sta q_r,x
        lda sp_h
        sta q_h,x
        lda sp_ch
        sta q_ch,x
        lda sp_c0
        sta q_c0,x
        lda sp_c1
        sta q_c1,x
        ldy qtoff,x
        ldx #0
-       lda tpen,x
        sta q_t,y
        iny
        inx
        cpx #TSET
        bne -
        lda nb                      ; (then it's there to be shown)
        sta nlast
        inc qn
        rts

; In the border, the next frame made shown (bufoff its buffer): its settings in force
qapply  lda bufoff
        lsr
        lsr
        lsr
        lsr
        lsr
        tax
        lda q_shx,x
        sta shx
        lda q_nvs,x                 ; (the VSP offset)
        jsr setvspa
        lda q_on,x                  ; (the yoyo's string, at the next tick: strapply)
        sta sq_on
        lda q_r,x
        sta sq_r
        lda q_h,x
        sta sq_h
        lda q_ch,x
        sta sq_ch
        lda q_c0,x
        sta sq_c0
        lda q_c1,x
        sta sq_c1
        lda #1
        sta strpend
        lda q_flip,x
        pha
        ldy qtoff,x                 ; (Trogg's settings)
        ldx #0
-       lda q_t,y
        sta tact,x
        iny
        inx
        cpx #TSET
        bne -

        pla                         ; (and the pairs flipped)
        beq +
        lda #0
        sta flippend
        lda front
        eor #1
        sta front
        jsr usefront
+       jmp setx
q_shx   .fill 3
q_flip  .fill 3
q_nvs   .fill 3
q_on    .fill 3
q_r     .fill 3
q_h     .fill 3
q_ch    .fill 3
q_c0    .fill 3
q_c1    .fill 3
qtoff   .byte 0, TSET, 2 * TSET
q_t     .fill 3 * TSET
sq_on   .byte 0                     ; (the string shown: strapply's)
sq_r    .byte 0
sq_h    .byte 0
sq_ch   .byte 0
sq_c0   .byte 0
sq_c1   .byte 0

        .if PROFILE
; (--profile: the frame's record into the ring: its stamps, the frame count, held frames so far,
; some of the game's state, and its number)
precord lda frames
        sta pstage + 24
        lda pheld
        sta pstage + 25
        lda tstate
        sta pstage + 26
        lda dead
        sta pstage + 27
        lda won
        sta pstage + 28
        lda yo_len
        sta pstage + 29
        lda pseq + 1
        sta pstage + 30
        lda pseq
        sta pstage + 31
        inc pseq
        bne +
        inc pseq + 1
+
        ldx #31
-       lda pstage,x
_pd     sta $e000,x
        dex
        bpl -
        lda _pd+1
        clc
        adc #32
        sta _pd+1
        bcc +
        inc _pd+2
        lda _pd+2
        cmp #$fe
        bcc +
        lda #$e0
        sta _pd+2
+       rts
pstage  .fill 32
pheld   .byte 0
pseq    .word 0
        .endif

; Fill row prow of pair back for window working at VSP offset fsh (tops and bottoms), then prow+1:
; screen columns 2-39 (0-2 are the FLI bug's, never seen, under the cover sprite; 2 is filled too
; so the loop, unrolled once, takes the columns in twos), from tables of each row's addresses
fillrow ldx prow
        lda fstlo,x                 ; source: the level's row, from the column
        clc
        adc working
        sta _sa+1
        sta _sb+1
        lda fsthi,x
        adc #0
        sta _sa+2
        sta _sb+2
        lda fsblo,x
        clc
        adc working
        sta _ba+1
        sta _bb+1
        lda fsbhi,x
        adc #0
        sta _ba+2
        sta _bb+2
        lda fdlo,x                  ; destination: the pair's screens, the row, the offset (tops and
        clc                         ; bottoms the same but for the high byte)
        adc fsh
        sta _ta+1
        sta _tb+1
        sta _ua+1
        sta _ub+1
        lda #0
        rol
        sta tmp
        lda back
        bne _p1
        lda fdt0,x
        adc tmp                     ; (carry clear)
        sta _ta+2
        sta _tb+2
        lda fdb0,x
        adc tmp
        sta _ua+2
        sta _ub+2
        bne _go                     ; (always)
_p1     lda fdt1,x
        adc tmp
        sta _ta+2
        sta _tb+2
        lda fdb1,x
        adc tmp
        sta _ua+2
        sta _ub+2
_go     ldx #37
_sa     lda $ffff,x
_ta     sta $ffff,x
_ba     lda $ffff,x
_ua     sta $ffff,x
        dex
_sb     lda $ffff,x
_tb     sta $ffff,x
_bb     lda $ffff,x
_ub     sta $ffff,x
        dex
        bpl _sa
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
        sta rlat+1
        lda #>d18a0
        sta rla+2
        sta rlat+2
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
        sta apb0+2
        lda #>(SCR1 + $3f8)
        sta aps1+2
        sta apt1+2
        sta apb1+2
        lda #>(SCR0 + $3f8)         ; (and Trogg's)
        ldx #>(SCR1 + $3f8)
        jmp tpair
+       lda #<d18a1
        sta rl0+1
        lda #<(d18a1+1)
        sta rla+1
        sta rlat+1
        lda #>d18a1
        sta rla+2
        sta rlat+2
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
        sta apb0+2
        lda #>(SCR3 + $3f8)
        sta aps1+2
        sta apt1+2
        sta apb1+2
        lda #>(SCR2 + $3f8)
        ldx #>(SCR3 + $3f8)
        jmp tpair

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
        lda t01c,x
        sta $d01c
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
tpr     lda rowtl,x                 ; the next row's interrupt's operands (prep, inline)
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
+                                   ; (the rows done) the borders opened: 24 rows (RSEL 0) on lines
-       lda $d012                   ; 248-250, past line 247 (24 rows' end) and before 251 (25
        cmp #248                    ; rows'), so the vertical border never starts; the rows' next
        bcc -                       ; $d011 writes (25 rows) put RSEL back before row 0
        lda #D011A & $f7
        sta $d011
        lda #<bordirq               ; (the border's ticks)
        sta $fffe
        lda #>bordirq
        sta $ffff
        ldy savy
        ldx savx
        lda sava
        rti

; Trogg's x's-move row's tail, after troggc: tailend without the set-up (his ticks have none) or
; the last row's check (his row before is never the last), so it's done sooner
tailcx  lda #D011A
        sta $d011
        sty savy
        ldx row
rlat    lda d18a0+1,x
        sta $d018
        inx
        stx row
        txa
        clc
        adc bufoff
        tax
        jmp tpr

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
        inc frames
        .if !TEST
        lda qn                      ; the next frame made, if there is one: its buffer, and its
        beq _nmux                   ; scroll and settings (qapply); else this one again
        lda bufoff
        clc
        adc #32
        cmp #96
        bcc _nbuf
        lda #0
_nbuf   sta bufoff
        dec qn
        .if SLACK
        inc nswap
        .endif
        jsr qapply
        jmp _dmux
_nmux   .if SLACK
        inc nhold                   ; (debug: frames none was ready)
        .endif
        .if PROFILE
        inc pheld
        .endif
        jsr setx
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
        bcc +
        jmp rl0                     ; (tick 38)
+       stx row
        cpx #ROWS + 2               ; tick 26: the yoyo's string, if the frame's changed (strapply:
        bne t26n                    ; not at tick 25, whose work, with it, could take over two
        lda strpend                 ; ticks, and one would be lost)
        beq t26n
        jsr strapply                ; (the old string put back; the new one at tick 27)
t26n    ldx row                     ; (strapply leaves x changed)
        cpx #ROWS + 3
        bne t27n
        lda strpend
        beq t27n
        lda #0
        sta strpend
        jsr strdraw
t27n    ldx row
        cpx #ROWS + 4               ; tick 28 (line 277): any sprite whose y is under 56 moved to
        bne t28n                    ; y 100 (a line passed), as on line 256 + y (303-311, the VIC
        ldy #14                     ; comparing y with the line's low byte) it would start again,
-       lda $d001,y                 ; its fetches running on into the next frame's top border, now
        cmp #56                     ; open (its set-up puts its y back before it's next shown)
        bcs t28k
        lda #100
        sta $d001,y
t28k    dey
        dey
        bne -
t28n
        .if !TEST
        cpx #ROWS + 5               ; tick 29 (line 285): sprite 0, the cover, done for the frame,
        bne t29n                    ; made the timer in the top border till tick 37 (tmset)
        jsr tmset
        ldx row
t29n
        cpx #37                     ; tick 36 (line 29): sprites 3-7 parked below the screen, their
        bne t36n                    ; pointers blank (there, lines 256-276, they're in the open
        lda #255                    ; border), before tick 37 sets up those before the frame
        sta $d007
        sta $d009
        sta $d00b
        sta $d00d
        sta $d00f
        jsr park
        ldx row
t36n
        .endif
        .if !TEST
        cpx #38                     ; tick 37 (line 37): sprites 3-7 parked below the screen, then
        bne t37n                    ; those set up before the frame (tick 0's slots), and the
        lda $d012                   ; registers (in time for sprites from line 47, and leaving
        cmp #41                     ; tick 38 little to do before row 0's). (On line 45, not
        bcc t37o                    ; 37: a tick was lost, a handler having taken over two; this
        jsr tmcov                   ; is tick 38's, and the count in step again from it)
        jmp rl0
t37o    jsr tmcov                   ; (sprite 0 the cover again, the timer done: from line 50)
        ldy bufoff
        lda t010,y
        sta $d010
        lda t017,y
        sta $d017
        lda t01d,y
        sta $d01d
        lda t01b,y
        sta $d01b
        lda t01c,y
        sta $d01c
        lda #0                      ; (Trogg's outline black: sprite 1 may have been another's)
        sta $d028
        jsr apply0
        jsr tick37                  ; (Trogg's sprites' first instances)
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
        .if !TEST
        jsr vspcov                  ; (the cover sprite over line 50's garbage)
        .endif
        .if SLACK
        lda $dc07                   ; (debug: tick 38's least slack before row 0's tick)
        bne +
        lda $dc06
        cmp slacklo
        bcs +
        sta slacklo
+
        .endif
        jsr vspline                 ; (VSP: the screen shown from offset s)
        lda #<rowirq
        sta $fffe
        lda #>rowirq
        sta $ffff
        ldy savy
        ldx savx
        lda sava
        rti

; VSP: a bad line forced on line 50 (in the top border, before row 0's at 51), n = 40 - s cycles
; after cycle 14: the VIC fetches 40 - n = s characters fewer in it, and every row after starts s
; on: the screen shown from offset s (vson; 0: no VSP). The timer polled until line 50, then read
; once more, and a slide to land the write on cycle 54 - s (Bauer's numbering, from 1). The read
; comes on cycle 9-17, or, if sprites 3-7 are fetched on line 50 (cycles 1-10), up to cycle 21,
; but always after their fetches: nothing stops the CPU between it and the write (sprites 0-2's
; are at the line's end). From the read to the write is 11 cycles and the slide's (3 at the
; least), so offset 16 (the write on cycle 38) can be reached from a read as late as 21: hence X
; for the write, and no sec (the poll leaves carry clear). (VSPT: the timer at line 50's cycle 0,
; as VICE's monitor counts cycles, from 0; measured. The slide's constant VSPT - 7 + s: from the
; offset seen, measured.)
VSPT    = 200
VSPB    = VSPT + 2
        .align $80
        .page
vspline lda vson
        beq vspx
        ldy v010r                   ; (the cover sprite's x back after the write: $d010)
        ldx #(D011A & $f8) | 2      ; (YSCROLL 2: line 50 a bad line, from the write)
-       lda $dc07                   ; (the timer under 256: line 49)
        bne -
-       lda $dc06                   ; (until line 50: read on its cycle -1 to 7)
        cmp #VSPB
        bcs -
vsk     lda #0                      ; (VSPT - 7 + s, less the timer and the carry (clear): the
        sbc $dc06                   ; slide's bytes skipped, 2 + s to 13 + s)
        sta _br+1
_br     bpl _sl
_sl     .fill 31, $c9               ; (a cycle for each byte skipped)
        .byte $c5, $ea
        stx $d011
        lda #D011A                  ; (back, before line 51)
        sta $d011
        lda #COVERX + 7             ; (the cover sprite back over columns 0-2, before line 51's
        sta $d000                   ; bad line stops the CPU: 16 cycles from the write on cycle
        sty $d010                   ; 53 at the latest, so by line 51's cycle 6)
vspx    rts
        .endpage
vson    .byte 0

; The VSP line's garbage, now the border's open: line 50 shows 3 characters of the DMA delay's
; fetches (the FLI bug's $ff, with whatever colour) at columns 40 - s to 42 - s, moved by the fine
; scroll. The cover sprite (32 wide, from line 50) moved there for line 50: x = 24 + 8 (40 - s) +
; ($d016 & 7) = $158 + ($d016 & 7) - 8s, and back after the write (vspline)
        .if !TEST
        .section high
vspcov  lda vson
        beq _x
        asl
        asl
        asl
        sta vtmp
        lda $d016
        and #7
        ora #$58
        sec
        sbc vtmp
        sta $d000
        lda #0                      ; (x's bit 8: 1 unless that borrowed)
        adc #0
        sta vtmp
        ldy bufoff
        lda t010,y                  ; ($d010 as tick 37 left it, the cover's bit clear: then)
        and #$fe
        sta v010r
        ora vtmp
        sta $d010
_x      rts
        .send high
        .endif
        .if !TEST
; ---- The timer, M:SS, at the top left in the top border: sprite 0 (the cover, from line 50 on),
; hi-res, black, from tick 29 (line 285, the cover's last piece done, and past line 271, where y
; TMY would start it again) to tick 37 (line 37): lines TMY + 1 to TMY + 21 (16-36), done by
; then, its digits on its rows TROW to TROW + 6 (lines 26-32); x at the screen's left edge (the
; cover's right). (Tick 38 has no time to spare before line 50's VSP write.) Counted in frames,
; 50 a second, from the level's start (newlevel) till it's won, 9:59 at the most; redrawn when it
; changes from the three shifted digit sets (timer.inc, build.mjs)
TMY     = 15
TMX     = COVERX + 7 + 32
TROW    = 10
        .section high
tmset   lda #(SPRTIMER & $3fff) / 64
        sta SCR0 + $3f8
        sta SCR1 + $3f8
        sta SCR2 + $3f8
        sta SCR3 + $3f8
        lda #0
        sta $d027
        lda $d017
        and #$fe
        sta $d017
        lda $d01d
        and #$fe
        sta $d01d
        lda $d010
        and #$fe
        sta $d010
        lda #TMX
        sta $d000
        lda #TMY
        sta $d001
        lda won                     ; (the count: stopped once the level's won)
        bne _x
        inc tmf
        lda tmf
        cmp #50
        bcc _x
        lda #0
        sta tmf
        inc tms2
        lda tms2
        cmp #10
        bcc tmdraw
        lda #0
        sta tms2
        inc tms1
        lda tms1
        cmp #6
        bcc tmdraw
        lda #0
        sta tms1
        inc tmm
        lda tmm
        cmp #10
        bcc tmdraw
        lda #9                      ; (9:59, held)
        sta tmm
        sta tms2
        lda #5
        sta tms1
        bne tmdraw
_x      rts
tmdraw  .for r = 0, r < 7, r += 1
        ldx tmm
        lda tmA + r * 10,x
        sta SPRTIMER + (TROW + r) * 3
        ldx tms1
        lda tmB1 + r * 10,x
        ora tmcol + r
        sta SPRTIMER + (TROW + r) * 3 + 1
        lda tmB2 + r * 10,x
        ldx tms2
        ora tmC + r * 10,x
        sta SPRTIMER + (TROW + r) * 3 + 2
        .endfor
        rts
tmreset lda #0
        sta tmf
        sta tms2
        sta tms1
        sta tmm
        jmp tmdraw
tmcov   lda #(SPRCOVER & $3fff) / 64 ; (and back: the cover)
        sta SCR0 + $3f8
        sta SCR1 + $3f8
        sta SCR2 + $3f8
        sta SCR3 + $3f8
        lda #3
        sta $d027
        lda $d017
        ora #1
        sta $d017
        lda $d01d
        ora #1
        sta $d01d
        lda #COVERX + 7
        sta $d000
        lda #COVERY0
        sta $d001
        rts
tmf     .byte 0
tms2    .byte 0
tms1    .byte 0
tmm     .byte 0
        .include "timer.inc"
        .send high
        .endif

        .section high
; What the multiplexer keeps from frame to frame, as when loaded: a start after Escape finds it as
; the last game left it
fresh   lda #$ff
        sta gscx
        sta gscx+1
        sta traw
        sta trcw
        sta tres1w
        sta tres2w
        lda #1
        sta scrchg
        lda #0
        sta tmsbw
        rts
vtmp    .byte 0
v010r   .byte 0                     ; ($d010 with the cover's bit clear, for vspline)
        .send high

; The VSP offset from nvs (in the border, or at the start)
setvsp  lda nvs
setvspa sta vson
        clc
        adc #VSPT - 7
        sta vsk+1
        rts

        .include "tails.inc"

; The next frame's scroll (in the main program, with the multiplexer, during the frame before):
; a pixel on (holding at the ends; holding if a new column can't be had yet: cstep). The scroll
; and the VSP offset, and any pair flip, are left for the border to make (frame)
decide  .if !SCROLLDEMO
        jmp camera
        .endif
        lda dir                     ; (the hidden pair for a swap the way it's going)
        jsr wantdir
        lda pause
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
        jsr cstep                   ; a new column (if it can't be had yet: hold)
        bcs _hold
_move   lda dtmp
        sta scrx
        lda dtmp+1
        sta scrx+1
        ora scrx                    ; at an end: turn round, and hold
        beq _turn
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
_hold   rts

; The camera (for the next frame, in the main program, with the multiplexer): Trogg kept between
; VL and VR across the screen (his x less the scroll), the scroll moving a pixel a frame (his
; walking speed) when he's past one; the hidden pair filled for a swap on the side of the middle
; he's on (wantdir), so it's ready when the scroll gets there (if it isn't, the scroll waits).
; After a restart (jumping), it jumps to the scroll the restart chose (jumpx: 0 for the level's
; start, him in the middle for a checkpoint): the hidden pair filled for its window at offset 8,
; then that shown.
VL      = 112
VR      = 192
MAXC    = MAXX / 8
camera  lda jumping
        beq _go
        lda curc                    ; (a restart: to the scroll jumpx, window jumpw, play.asm)
        cmp jumpw
        bne +
        lda jumpx                   ; (in that window already: only the fine scroll)
        sta scrx
        lda jumpx+1
        sta scrx+1
        lda #0
        sta jumping
        rts
+       lda jumpw                   ; (else the hidden pair filled for it, at offset 8, then shown)
        sec
        sbc #8
        sta wanto
        ldx back
        cmp po,x
        bne _x
        lda pvw,x
        cmp jumpw
        bne _x
        sta curc
        lda jumpx
        sta scrx
        lda jumpx+1
        sta scrx+1
        lda #0
        sta jumping
        lda #8
        sta nvs
        stx lfront
        txa
        eor #1
        sta back
        lda #1
        sta flippend
        sta fliphere                ; (the frame being made flips them)
_x      rts
_go     lda tx                      ; where he is on the screen
        sec
        sbc scrx
        sta dtmp
        lda tx+1
        sbc scrx+1
        sta dtmp+1
        bmi _wl                     ; the hidden pair for a swap on his side of the middle
        bne _wr
        lda dtmp
        cmp #(VL + VR) / 2
        bcc _wl
_wr     lda #1
        .byte $2c
_wl     lda #$ff
        jsr wantdir
        lda dtmp+1                  ; past one end of the zone: a pixel that way
        bmi _ml
        bne _mr
        lda dtmp
        cmp #VR + 1
        bcs _mr
        cmp #VL
        bcc _ml
        rts
_mr     lda scrx
        cmp #<MAXX
        lda scrx+1
        sbc #>MAXX
        bcs _x
        lda #1
        bne _step
_ml     lda scrx
        ora scrx+1
        beq _x
        lda #$ff
_step   sta dir
        clc
        adc scrx
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
        beq _same
        jsr cstep                   ; a new column (if it can't be had yet: wait)
        bcc _same
        .if SLACK
        inc cwait                   ; (debug: frames the camera waited for the hidden pair)
        .endif
        rts
_same   lda dtmp
        sta scrx
        lda dtmp+1
        sta scrx+1
        rts
jumping .byte 0
pre     .byte 0                     ; (the frames made before the start)

; In the border: the scroll decided (the flip, the VSP offset, $d016)
frame   lda scrx                    ; (the position the multiplexer's frame was made for)
        sta shx
        jsr tswitch                 ; (and Trogg's settings)
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
+       jsr setvsp                  ; (the VSP offset)
        lda #1                      ; (and the yoyo's string, at the next tick: strapply)
        sta strpend
setx    lda shx
        and #7
        eor #7                      ; (38 columns)
        sta $d016                   ; (the cover sprite stays at COVERX + 7, hiding columns 0-2 at
        rts                         ; any fine scroll: the screen's left edge still, the
                                    ; characters scrolling in under it smoothly)

        .include "scroll.asm"
        .include "yoyo.asm"
        .include "collide.asm"
        .include "hazards.asm"
        .include "mux.asm"
        .include "trogg.asm"
        .if FRONT
        .include "front.asm"
        .endif
        .include "play.asm"

        .align $100
d18a0   .fill ROWS + 1
d18b0   .fill ROWS + 1
d18a1   .fill ROWS + 1
d18b1   .fill ROWS + 1
csbits  .byte ((CS0 & $3800) >> 10), ((CS1 & $3800) >> 10)
fstlo   .for i = 0, i < ROWS, i += 1   ; (fillrow's: each row's source and destination, from column 2)
        .byte <(tops + 2 + i * NC)
        .endfor
fsthi   .for i = 0, i < ROWS, i += 1
        .byte >(tops + 2 + i * NC)
        .endfor
fsblo   .for i = 0, i < ROWS, i += 1
        .byte <(bottoms + 2 + i * NC)
        .endfor
fsbhi   .for i = 0, i < ROWS, i += 1
        .byte >(bottoms + 2 + i * NC)
        .endfor
fdlo    .for i = 0, i < ROWS, i += 1
        .byte <(i * 40 + 2)
        .endfor
fdt0    .for i = 0, i < ROWS, i += 1
        .byte >(SCR0 + i * 40 + 2)
        .endfor
fdb0    .for i = 0, i < ROWS, i += 1
        .byte >(SCR1 + i * 40 + 2)
        .endfor
fdt1    .for i = 0, i < ROWS, i += 1
        .byte >(SCR2 + i * 40 + 2)
        .endfor
fdb1    .for i = 0, i < ROWS, i += 1
        .byte >(SCR3 + i * 40 + 2)
        .endfor
bandset .binary "bandset.bin"
junk    .fill 16
hist    .fill 32
; the cover sprite's y for each row's tick: the next piece's, once this one has started
covery  .for i = 0, i < ROWS, i += 1
_y      := COVERY0 + 42 * (1 + ((54 + 8 * i) - (COVERY0 + 1)) / 42)
        .byte _y > COVERY0 + 4 * 42 ? COVERY0 + 4 * 42 : _y   ; (the last piece runs past the bottom)
        .endfor
        .include "masks.inc"
end
        .cerror end > SCR0, "the program runs into the screens"
        ; (then the VIC bank: the screens, the cover sprite and the multiplexer's RAM, set up at
        ; the start; and what's loaded straight into it: the character sets, the other sprites)
        .fill CS0 - *, 0
        .binary "charsets.bin", 0, 512
        .fill SPRSCRUB - *, 0
        .binary "scrubspr.bin"      ; (the Scrubblies' bodies)
        .binary "hazspr.bin", 0, 64 ; (SPRBALLOON: hazards.asm's, from build.mjs)
        .cerror * != SPRYOYO
        .dsection yoyospr           ; (the yoyo's frames: yoyo.asm)
        .cerror * != SPRDAGGER
        .binary "hazspr.bin", 64, 64
        .cerror * != SPRFRAK
        .binary "frakspr.bin"       ; (the FRAK! bubble's black, its yellow: build.mjs)
        .fill 64, 0                 ; (SPRBLANK)
        .cerror * != SPRBINF
        .binary "hazspr.bin", 128, 128  ; (the balloon's infill, top- and bottom-justified)
        .cerror * != SPRBMC
        .binary "hazspr.bin", 256, 64   ; (the balloon in multicolour)
        .cerror * != SPRTIMER
        .fill 64, 0                 ; (the timer: drawn by tmdraw)
        .fill CS1 - *, 0
        .binary "charsets.bin", 512, 512
        .if FRONT
        .cerror * > FRSPR
        .fill FRSPR - *, 0
        .binary "frontspr.bin"      ; (the front end's cast: front.asm)
        .endif
        .fill $6800 - *, 0
TROGG   .binary "trogg.bin"         ; Trogg's sprites: per frame outline P1-P3, infill P1-P3
        .cerror * > $79ff, "Trogg's sprites run into $79ff"
        .fill $7a00 - *, 0          ; ($79ff zero: the byte the VIC shows in the open borders, its
                                    ; idle fetch in ECM)
tops    .binary "tops.bin"          ; (the level map, past the VIC bank)
bottoms .binary "bottoms.bin"
        .dsection high              ; (tables that needn't be low: mux.asm's, play.asm's)
