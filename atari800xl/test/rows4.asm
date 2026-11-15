; 4-line rows test: which glyph line ANTIC shows on each scanline.
; Characters 1-8: character k+1 is solid on glyph line k only, so on any scanline the lit one of
; columns 0-7 says which glyph line ANTIC is showing. The first row of each pair shows them in
; columns 0-7 and a solid block (character 9) in column 36; the second in columns 16-23.
; The display list: a normal mode 2 row, then pairs of rows (vertical scroll bit on, then off).
;   MODE 0: no DLIs, VSCROL constant = VS
;   MODE 1: DLIs: the first row of a pair sets VSCROL = VB; the second waits on WSYNC, then
;           DELAY nops, then VSCROL = VA (for the next pair's start)
;   REFLECT: CHACTL bit 2 on the second rows of pairs (MODE 1 only)
        .weak
MODE    = 0
VS      = 4
VA      = 4
VB      = 3
DELAY   = 0
NOWSYNC = 0
REFLECT = 0
PMDMA   = 0                 ; players and missiles fetched every line (1-line resolution)
HSC     = 0                 ; horizontal scrolling on (the wide fetch), HSCROL = HSC - 1
        .endweak
NPAIRS  = 20
VDSLST  = $0200
SDLSTL  = $0230
CHACT   = $02f3
CHBAS   = $02f4
COLOR1  = $02c5
COLOR2  = $02c6
COLOR4  = $02c8
CHACTL  = $d401
VSCROL  = $d405
WSYNC   = $d40a
NMIEN   = $d40e
SDMCTL  = $022f
GRACTL  = $d01d
PMBASE  = $d407
HSCROL  = $d404
HPOSP0  = $d000
SETVBV  = $e45c
XITVBV  = $e462

        * = $2000
start   sei
        lda #0
        sta NMIEN
        lda #<dl
        sta SDLSTL
        lda #>dl
        sta SDLSTL+1
        lda #>font
        sta CHBAS
        lda #$0f
        sta COLOR1
        lda #$00
        sta COLOR2
        lda #$06
        sta COLOR4
        lda #0
        sta CHACT
        lda #<dlia
        sta VDSLST
        lda #>dlia
        sta VDSLST+1
        cli
        lda #7
        ldx #>vbi
        ldy #<vbi
        jsr SETVBV
      .if PMDMA
        lda #$3e
        sta SDMCTL
        lda #3
        sta GRACTL
        lda #>pm
        sta PMBASE
        ldx #7
-       lda #100
        sta HPOSP0,x
        dex
        bpl -
      .endif
      .if HSC
        lda #HSC - 1
        sta HSCROL
      .endif
        lda #$c0
        sta NMIEN
loop    jmp loop

vbi     lda #<dlia
        sta VDSLST
        lda #>dlia
        sta VDSLST+1
      .if MODE == 0
        lda #VS
      .else
        lda #VA
      .endif
        sta VSCROL
        lda #0
        sta CHACTL
        jmp XITVBV

dlia    pha                         ; end of a pair's first row: VSCROL for the second's end
        lda #VB
        sta VSCROL
      .if REFLECT
        lda #4
        sta CHACTL
      .endif
        lda #<dlib
        sta VDSLST
        lda #>dlib
        sta VDSLST+1
        pla
        rti

dlib    pha                         ; end of a pair's second row: VSCROL for the next's start
        lda #VA
      .if !NOWSYNC
        sta WSYNC
      .endif
      .rept DELAY
        nop
      .endrept
        sta VSCROL
      .if REFLECT
        lda #0
        sta CHACTL
      .endif
        lda #<dlia
        sta VDSLST
        lda #>dlia
        sta VDSLST+1
        pla
        rti

        .align $400
font    .fill 8, 0
        .for k = 0, k < 8, k += 1
        .for r = 0, r < 8, r += 1
        .byte r == k ? $ff : 0
        .endfor
        .endfor
        .fill 8, $ff
        .fill $400 - 80, 0

        .align $100
SKEW    = HSC ? 4 : 0               ; the wide fetch shows bytes 4-43 of the 48 at HSCROL 0
row1    .fill SKEW, 0
        .byte 1, 2, 3, 4, 5, 6, 7, 8
        .fill 28, 0
        .byte 9, 0, 0, 0
        .fill 8 - SKEW, 0
row2    .fill SKEW, 0
        .fill 16, 0
        .byte 1, 2, 3, 4, 5, 6, 7, 8
        .fill 16, 0
        .fill 8 - SKEW, 0
row0    .byte 1, 2, 3, 4, 5, 6, 7, 8
        .fill 28, 0
        .byte 9, 0, 0, 0

DLIBIT  = (MODE == 1 ? $80 : 0) | (HSC ? $10 : 0)
dl      .byte $70, $70, $70
        .byte $42
        .word row0
        .for i = 0, i < NPAIRS, i += 1
        .byte $62 | DLIBIT
        .word row1
        .byte $42 | DLIBIT
        .word row2
        .endfor
        .byte $41
        .word dl

        .align $800
pm      .fill $800, $55             ; every player and missile showing a pattern on every line

        * = $02e0
        .word start
