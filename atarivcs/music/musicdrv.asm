; Frak music driver for the 2600: two channels, called once per frame (in vertical blank or
; overscan). Channel 0 plays the bass, channel 1 the lead (tables and patterns in frakmusic.inc).
;
;   jsr MusicInit       ; once
;   jsr MusicTick       ; every frame
;
; A pattern is a list of 2-byte notes: code, length in frames. Codes: 0-47 a note (index into
; the channel's AUDC/AUDF tables), 48-60 a pitch slide (code - 48 indexes {Bass,Lead}Slide, an
; offset into {Bass,Lead}Slides: one pitch index per frame, ended by $FF, after which the last
; pitch is held, or by $FE and an offset to go back to, for a repeating pattern), 61 tie (carry on with no new attack), 62 end of pattern, 63 rest.
; Each channel has an order list of patterns, ended by $FF, and a loop position.
; The envelope: a new note starts at the channel's top volume and falls by one every 4 frames
; to its floor; a rest is silent.
;
; RAM (MUSRAM must be defined by the includer, 13 bytes):
MusFrame = MUSRAM           ; frame counter (for the envelope)
MusOrd   = MUSRAM + 1       ; 2: position in each channel's order list
MusTim   = MUSRAM + 3       ; 2: frames left of each channel's note
MusVol   = MUSRAM + 5       ; 2: each channel's volume
MusPtr0  = MUSRAM + 7       ; 2: bass pattern pointer
MusPtr1  = MUSRAM + 9       ; 2: lead pattern pointer
MusSl    = MUSRAM + 11      ; 2: each channel's position in its slide table ($FF: none)

BASS_TOP = 10
BASS_FLOOR = 6
LEAD_TOP = 12
LEAD_FLOOR = 5

MusicInit:
        lda #0
        sta MusFrame
        sta MusVol
        sta MusVol+1
        lda #$FF
        sta MusOrd
        sta MusOrd+1
        sta MusSl
        sta MusSl+1
        lda #1
        sta MusTim
        sta MusTim+1
        lda #<MusEnd
        sta MusPtr0
        sta MusPtr1
        lda #>MusEnd
        sta MusPtr0+1
        sta MusPtr1+1
        rts

MusEnd: .byte 62            ; an empty pattern: the first tick moves to each channel's first

  MAC CHANNEL               ; {1} channel (0/1), {2} Bass/Lead, {3} top volume, {4} floor
        dec MusTim+{1}
        bne .env
.next:
        ldy #0
        lda (MusPtr{1}),y
        cmp #62
        bne .note
        ldx MusOrd+{1}      ; end of pattern: the next one in the order list
        inx
        lda {2}Order,x
        bpl .pat
        ldx #{2}Loop        ; the end of the list: back to its loop position
        lda {2}Order,x
.pat:   stx MusOrd+{1}
        tax
        lda {2}PatLo,x
        sta MusPtr{1}
        lda {2}PatHi,x
        sta MusPtr{1}+1
        jmp .next
.note:  tax                 ; X = the code
        iny
        lda (MusPtr{1}),y
        sta MusTim+{1}      ; its length in frames
        lda MusPtr{1}
        clc
        adc #2
        sta MusPtr{1}
        bcc .nc
        inc MusPtr{1}+1
.nc:    cpx #63
        beq .rest
        cpx #61
        beq .env            ; a tie: no new attack (a slide carries on)
        lda #$FF
        sta MusSl+{1}
        lda #{3}
        sta MusVol+{1}
        cpx #48
        bcc .plain
        lda {2}Slide-48,x   ; a slide: its first step is taken below, this frame
        sta MusSl+{1}
        bcs .env            ; (carry is set)
.plain: lda {2}C,x
        sta AUDC0+{1}
        lda {2}F,x
        sta AUDF0+{1}
        jmp .env
.rest:  lda #0
        sta MusVol+{1}
        lda #$FF
        sta MusSl+{1}
.env:   ldx MusSl+{1}       ; a slide in progress: this frame's pitch
        cpx #$FF
        beq .dec
.rd:    lda {2}Slides,x
        cmp #$FE
        bcc .step
        beq .loop
        sta MusSl+{1}       ; $FF, its end: hold the last pitch
        bne .dec
.loop:  lda {2}Slides+1,x   ; $FE: go back (a repeating pattern, for pitch alternation)
        sta MusSl+{1}
        tax
        jmp .rd
.step:  tax
        lda {2}C,x
        sta AUDC0+{1}
        lda {2}F,x
        sta AUDF0+{1}
        inc MusSl+{1}
.dec:   lda MusFrame
        and #3
        bne .out
        lda MusVol+{1}
        cmp #{4}+1
        bcc .out            ; at the floor (or silent)
        dec MusVol+{1}
.out:   lda MusVol+{1}
        sta AUDV0+{1}
  ENDM

MusicTick:
        inc MusFrame
        CHANNEL 0, Bass, BASS_TOP, BASS_FLOOR
        CHANNEL 1, Lead, LEAD_TOP, LEAD_FLOOR
        rts

        include "frakmusic.inc"
