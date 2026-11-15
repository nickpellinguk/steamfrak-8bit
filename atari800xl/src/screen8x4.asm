; The 8x4 screen demo: a level (A_1) on 52 rows of 4 lines, scrolling back and forth.
; Pairs of mode 2 rows, the first with vertical scrolling on (glyph lines 4-7: bottoms), the
; second off (glyph lines 0-3: tops); each row's DLI sets VSCROL for what comes next: the first
; row's 3 (for the second's end), the second's 4 (for the next pair's start), the latter after
; WSYNC and DELAY nops (test/README.md). Horizontal scrolling: HSCROL and every row's LMS, set
; in the VBI. Uses the OS (for now): its VBI, a deferred VBI of ours.
;   64tass --atari-xex -D STILLX=n: held at scroll position n (colour clocks) instead of moving
        .weak
DELAY   = 1
STILLX  = -1
LEVEL   = "A_1"
        .endweak
        .include "../build/" .. LEVEL .. ".inc"
XMAX    = (NCOLS - 40) * 4          ; the scroll's range, in colour clocks (2 pixels)

VDSLST  = $0200
SDLSTL  = $0230
SDMCTL  = $022f
CHBAS   = $02f4
COLOR1  = $02c5
COLOR2  = $02c6
COLOR4  = $02c8
HSCROL  = $d404
VSCROL  = $d405
WSYNC   = $d40a
NMIEN   = $d40e
SETVBV  = $e45c
XITVBV  = $e462

scrx    = $80                       ; the scroll position, colour clocks from the level's left
scrd    = $81                       ; its direction, 1 or -1
lmsoff  = $82                       ; (the VBI's)

        * = $2000
start   lda #0
        sta NMIEN
        lda #<dl
        sta SDLSTL
        lda #>dl
        sta SDLSTL+1
        lda #>font
        sta CHBAS
        lda #$00                    ; the outlines: luminance 0
        sta COLOR1
        lda #$9a                    ; the background (PF2)
        sta COLOR2
        lda #$00
        sta COLOR4
        lda #$22                    ; normal width, playfield DMA
        sta SDMCTL
      .if STILLX >= 0
        lda #STILLX
      .else
        lda #0
      .endif
        sta scrx
        lda #1
        sta scrd
        lda #7
        ldx #>vbi
        ldy #<vbi
        jsr SETVBV
        lda #$c0
        sta NMIEN
-       jmp -

; The deferred VBI: move the scroll, set HSCROL and the rows' LMS, the DLIs back to the start
vbi   .if STILLX < 0
        lda scrx
        clc
        adc scrd
        sta scrx
        beq turn
        cmp #XMAX
        bne +
turn    lda scrd
        eor #$fe                    ; 1 <-> -1 ($01 <-> $ff)
        sta scrd
+
      .endif
        lda scrx                    ; HSCROL = -x & 3, LMS = row + (x + 3) / 4
        eor #$ff
        clc
        adc #1
        and #3
        sta HSCROL
        lda scrx
        clc
        adc #3
        lsr a
        lsr a
        sta lmsoff
        ldx #0
-       lda lmsoff
        sta dlrows + 1,x            ; even rows: their low byte is the offset
        ora #$80
        sta dlrows + 4,x            ; odd rows: + $80
        txa
        clc
        adc #6
        tax
        cpx #NROWS * 3
        bne -
        lda #4
        sta VSCROL
        lda #<dlia
        sta VDSLST
        lda #>dlia
        sta VDSLST+1
        jmp XITVBV

dlia    pha                         ; a bottoms row's last line: VSCROL 3 for the tops row's end
        lda #3
        sta VSCROL
        lda #<dlib
        sta VDSLST
        lda #>dlib
        sta VDSLST+1
        pla
        rti

dlib    pha                         ; a tops row's last line: VSCROL 4 for the next row's start
        lda #4
        sta WSYNC
      .rept DELAY
        nop
      .endrept
        sta VSCROL
        lda #<dlia
        sta VDSLST
        lda #>dlia
        sta VDSLST+1
        pla
        rti

        .align $400
dl      .byte $70, $70, $70
dlrows  .for r = 0, r < NROWS, r += 1
        .byte (r & 1) ? $d2 : $f2   ; DLI, LMS, HSCROL, (VSCROL on the bottoms rows), mode 2
        .word map + r * 128
        .endfor
        .byte $41
        .word dl

        .align $400
font    .binary "../build/" .. LEVEL .. "_font.bin"

        .align $1000
map     .binary "../build/" .. LEVEL .. "_map.bin"

        * = $02e0
        .word start
