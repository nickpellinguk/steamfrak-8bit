; ---- The front end (FRONT builds): the attract screen, as the BBC Master's and the CPC's first
; screen ("The Cast"), shown at the start till Space, Return, P, Y or a fire button. Text in the
; C64's own font, copied from its character ROM (the lower/upper-case set's first 128 characters)
; to FECHR, in an ordinary text screen (SCR0, free till the game sets up its screens); the cast in
; sprites (build.mjs: frontspr.bin, at FRSPR), each as hi-res outlines (black) in front of
; multicolour infills (yellow, magenta), in bands down the screen, the 8 hardware sprites set up
; again for each band by a raster interrupt (fesprs), once the band before has done with them (or
; is showing only their blank rows): the FRAK! bubble in the top border (opened, as in the game),
; Trogg (his top sprites' x moved 2 left between his head and his body), the Scrubbly (2 sprites
; across), then the Hooter and the Poglet side by side in the sprites' use. The text: front.inc.
FRSPR   = $5a00                     ; (the cast's sprite blocks, FEBLOCKS of them)
FECHR   = $4800                     ; (the font: SCR2's place, the game's later)
FEP     = (FRSPR & $3fff) / 64      ; (the first block's pointer)
TX      = 117                       ; (Trogg's body's x; his head's 2 more; the Scrubbly's, the
SX      = 114                       ;  Hooter's and the Poglet's: about x 130 down the middle of
HX      = 121                       ;  each, their names from column 22)
PX      = 119
fep     = $fb                       ; (zero page: free before the game starts)
fed     = $fd

        .section high
attract lda #$32                    ; the font, from the character ROM (seen at $d000 with the
        sta $01                     ; I/O off, $a000-$bfff, where this is, still RAM; interrupts
                                    ; are off)
        ldx #0
-       lda $d800,x
        sta FECHR,x
        lda $d900,x
        sta FECHR + $100,x
        lda $da00,x
        sta FECHR + $200,x
        lda $db00,x
        sta FECHR + $300,x
        inx
        bne -
        lda #$35
        sta $01
        lda $dd02                   ; VIC bank 1
        ora #3
        sta $dd02
        lda $dd00
        and #$fc
        ora #2
        sta $dd00
        ldx #0                      ; the screen blank, the text black
-       lda #32
        sta SCR0,x
        sta SCR0 + $100,x
        sta SCR0 + $200,x
        sta SCR0 + $2e8,x
        lda #0
        sta $d800,x
        sta $d900,x
        sta $da00,x
        sta $dae8,x
        inx
        bne -
        lda #<fetext                ; the text (front.inc: address, length, screen codes)
        sta fep
        lda #>fetext
        sta fep+1
_t      ldy #0
        lda (fep),y
        sta fed
        iny
        lda (fep),y
        beq _td
        sta fed+1
        iny
        lda (fep),y
        tax
        lda fep                     ; (past the address and length)
        clc
        adc #3
        sta fep
        bcc +
        inc fep+1
+       ldy #0
-       lda (fep),y
        sta (fed),y
        iny
        dex
        bne -
        tya
        clc
        adc fep
        sta fep
        bcc _t
        inc fep+1
        bne _t
_td     lda #3                      ; cyan, as the game
        sta $d020
        sta $d021
        lda #$1b                    ; text, 25 rows, the display on
        sta $d011
        lda #$08                    ; 40 columns
        sta $d016
        lda #((SCR0 & $3fff) / $400) << 4 | ((FECHR & $3fff) / $800) << 1
        sta $d018
        lda #7                      ; (the infills' shared colours: yellow, magenta)
        sta $d025
        lda #4
        sta $d026
        lda #0
        sta $d017
        sta $d01b
        sta $d010
        lda #$ff
        sta $d015
        lda #<feirq                 ; the raster interrupts
        sta $fffe
        lda #>feirq
        sta $ffff
        lda #0
        sta fei
        jsr feline
        lda #1
        sta $d01a
        sta $d019
        cli
-       jsr fekey                   ; (a key let go, then one pressed)
        bne -
-       jsr fekey
        beq -
        sei
        lda #0
        sta $d01a
        sta $d015
        lda #1
        sta $d019
        lda #0                      ; (the screens' memory, the text's and the font's, zero again,
        tax                         ; as the game finds it otherwise: it doesn't write every byte)
-       .for p = 0, p < 16, p += 1
        sta SCR0 + p * $100,x
        .endfor
        inx
        bne -
        rts

; Space, Return, P, Y or either fire button down: a not 0
fekey   lda #$7f
        sta $dc00
        lda $dc01
        and #$10
        beq _y
        lda #$fe
        sta $dc00
        lda $dc01
        and #$02
        beq _y
        lda #$df
        sta $dc00
        lda $dc01
        and #$02
        beq _y
        lda #$f7
        sta $dc00
        lda $dc01
        and #$02
        beq _y
        lda #$ff
        sta $dc00
        lda $dc00
        and #$10
        beq _y
        lda $dc01
        and #$10
        beq _y
        lda #0
        rts
_y      lda #1
        rts

; The raster interrupts, in turn (fei): each its band's work, then the next's line
feirq   pha
        txa
        pha
        tya
        pha
        lda #1
        sta $d019
        ldx fei
        lda fejl,x
        sta _j+1
        lda fejh,x
        sta _j+2
_j      jsr $0000
        ldx fei
        inx
        cpx #6
        bcc +
        ldx #0
+       stx fei
        jsr feline
        pla
        tay
        pla
        tax
        pla
        rti
feline  lda felo,x                  ; (the line for stage x: its bit 8 in $d011)
        sta $d012
        lda $d011
        and #$7f
        ora fehi,x
        sta $d011
        rts
felo    .byte <249, <292, 52, 72, 109, 157
fehi    .byte (249 >> 1) & $80, (292 >> 1) & $80, 0, 0, 0, 0
fejl    .byte <feopen, <febub, <fetrg, <fetx, <fescr, <fehp
fejh    .byte >feopen, >febub, >fetrg, >fetx, >fescr, >fehp

feopen  lda $d011                   ; (line 249: 24 rows, so the vertical border never starts)
        and #$f7
        sta $d011
        rts
febub   lda $d011                   ; (line 292, past 286, where y 30 would start it: 25 rows
        ora #$08                    ; again; the bubble, its black and its yellow, x-expanded)
        sta $d011
        lda #3
        sta $d01d
        lda #0
        sta $d01c
        ldx #<fsbub
        jmp fesprs
fetrg   lda #0                      ; (line 52: the bubble done; Trogg, his infills multicolour)
        sta $d01d
        lda #$0c
        sta $d01c
        ldx #<fstrg
        jmp fesprs
fetx    ldx #9                      ; (line 72, his line 5: once the beam's past him, his top
-       dex                         ; sprites' x to his body's, before line 73 reaches him)
        bne -
        lda #TX
        sta $d000
        sta $d004
        rts
fescr   lda #$f0                    ; (line 109: Trogg done (his bottom sprites till line 108: a
        sta $d01c                   ; pointer changed before then shows on their blank rows); the
                                    ; Scrubbly)
        ldx #<fsscr
        jmp fesprs
fehp    ldx #<fshp                  ; (line 157: the Hooter, in the Scrubbly's top sprites, done
                                    ; at 137; then the Poglet, in its bottom ones, done at 158)

; Sprites from list x (in fslists' page): a count, then each's sprite, x, y, pointer, colour
fesprs  lda fslists,x
        sta fen
        inx
-       ldy fslists,x               ; (its sprite)
        lda fslists + 3,x
        sta SCR0 + $3f8,y
        lda fslists + 4,x
        sta $d027,y
        tya
        asl
        tay
        lda fslists + 1,x
        sta $d000,y
        lda fslists + 2,x
        sta $d001,y
        txa
        clc
        adc #5
        tax
        dec fen
        bne -
        rts
fen     .byte 0
fei     .byte 0
        .align $100
fslists
fsbub   = * - fslists
        .byte 2
        .byte 0, 160, 30, (SPRFRAK & $3fff) / 64, 0
        .byte 1, 160, 30, (SPRFRAK & $3fff) / 64 + 1, 7
fstrg   = * - fslists
        .byte 4
        .byte 0, TX + 2, 66, FEP + 0, 0
        .byte 1, TX, 87, FEP + 1, 0
        .byte 2, TX + 2, 66, FEP + 2, 0
        .byte 3, TX, 87, FEP + 3, 0
fsscr   = * - fslists
        .byte 8
        .byte 0, SX, 116, FEP + 4, 0
        .byte 1, SX + 24, 116, FEP + 5, 0
        .byte 2, SX, 137, FEP + 6, 0
        .byte 3, SX + 24, 137, FEP + 7, 0
        .byte 4, SX, 116, FEP + 8, 0
        .byte 5, SX + 24, 116, FEP + 9, 0
        .byte 6, SX, 137, FEP + 10, 0
        .byte 7, SX + 24, 137, FEP + 11, 0
fshp    = * - fslists
        .byte 8
        .byte 0, HX, 161, FEP + 12, 0
        .byte 4, HX, 161, FEP + 14, 0
        .byte 1, HX, 182, FEP + 13, 0
        .byte 5, HX, 182, FEP + 15, 0
        .byte 2, PX, 187, FEP + 16, 0
        .byte 6, PX, 187, FEP + 18, 0
        .byte 3, PX, 208, FEP + 17, 0
        .byte 7, PX, 208, FEP + 19, 0
        .cerror * - fslists > 255
        .include "front.inc"
        .send high
