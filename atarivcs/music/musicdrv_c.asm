; Frak music driver, compact: the same tune and sound as musicdrv.asm (equiv_test.py compares
; their register writes frame by frame), from frakmusic_c.inc (compact.py), with one routine for
; both channels. Called once per frame (in vertical blank or overscan).
;
;   jsr MusicInit       ; once
;   jsr MusicTick       ; every frame
;
; A pattern is a list of one-byte notes: bits 0-5 the code, bits 6-7 the length (8, 16, 24 or 32
; frames). Codes: below SLIDE0 a note (MusNote: AUDF in bits 0-4, bit 7 set for AUDC 4, else 12),
; SLIDE0 on a pitch slide (MusSlide: its offset into MusSlides, one pitch a frame, ended by $FF:
; the last pitch is held), 61 tie (carry on, no new attack), 62 end of pattern, 63 rest. Each
; channel has an order list in MusOrder (ended by $FF) and a loop position (MusLoop). A new note
; starts at the channel's top volume and falls by one every 2 (bass) or 4 (lead) frames to its floor.
;
; RAM (MUSRAM defined by the includer, 13 bytes): each channel's variables are 2 bytes apart, so
; X = 0 (bass) or 2 (lead) indexes them all, its pattern pointer read with (MusPtr,x).
MusPtr   = MUSRAM           ; 0-1 bass, 2-3 lead
MusTim   = MUSRAM + 4       ; frames left of the note (bass +4, lead +6)
MusVol   = MUSRAM + 5       ; volume (bass +5, lead +7)
MusOrd   = MUSRAM + 8       ; position in MusOrder (bass +8, lead +10)
MusSl    = MUSRAM + 9       ; position in MusSlides, $FF: none (bass +9, lead +11)
MusFrame = MUSRAM + 12      ; frame counter (the envelope)

MusicInit:
        ldx #12
MIL:    lda MusInit,x
        sta MUSRAM,x
        dex
        bpl MIL
        rts
MusInit: .byte <MusEnd,>MusEnd,<MusEnd,>MusEnd, 1,0,1,0
        .byte $FF,$FF,MUSORD1,$FF, 0   ; (order positions: just before each channel's list)
MusEnd: .byte 62            ; an empty pattern: the first tick moves to each channel's first
MusTop:   .byte 12,15       ; top volume (bass, lead)
MusFloor: .byte 2+1,3+1     ; floor + 1
MusRate:  .byte 1,3         ; a step down every 2 (bass) / 4 (lead) frames

MusicTick:
        inc MusFrame
        ldx #2
MTL:    jsr MusChan
        dex
        dex
        bpl MTL
        rts

; ---- A = a MusNote byte: AUDF and AUDC for channel X / 2
SetPitch:
        pha
        txa
        lsr
        tay
        pla
        pha
        and #$1F
        sta AUDF0,y
        pla
        asl
        lda #12
        bcc SP1
        lda #4
SP1:    sta AUDC0,y
        rts

MusChan:
        dec MusTim,x
        bne MEnv
MNext:  lda (MusPtr,x)
        cmp #62
        bne MNote
        inc MusOrd,x        ; end of pattern: the next one in the order list
        ldy MusOrd,x
        lda MusOrder,y
        bpl MPat
        txa                 ; the end of the list: back to its loop position
        lsr
        tay
        lda MusLoop,y
        sta MusOrd,x
        tay
        lda MusOrder,y
MPat:   tay
        lda MusPatLo,y
        sta MusPtr,x
        lda MusPatHi,y
        sta MusPtr+1,x
        jmp MNext
MNote:  inc MusPtr,x
        bne MN1
        inc MusPtr+1,x
MN1:    tay
        and #$C0            ; the length: 8 x (bits 6-7, + 1)
        lsr
        lsr
        lsr
        adc #8              ; (carry is clear)
        sta MusTim,x
        tya
        and #$3F
        cmp #63
        beq MRest
        cmp #61
        beq MEnv            ; a tie: no new attack (a slide carries on)
        pha
        lda #$FF
        sta MusSl,x
        txa
        lsr
        tay
        lda MusTop,y
        sta MusVol,x
        pla
        cmp #SLIDE0
        bcc MPlain
        tay
        lda MusSlide-SLIDE0,y   ; a slide: its first step is taken below, this frame
        sta MusSl,x
        bcs MEnv            ; (carry is set)
MPlain: tay
        lda MusNote,y
        jsr SetPitch
        jmp MEnv
MRest:  lda #0
        sta MusVol,x
        lda #$FF
        sta MusSl,x
MEnv:   ldy MusSl,x         ; a slide in progress: this frame's pitch
        cpy #$FF
        beq MDec
        lda MusSlides,y
        cmp #$FF
        bne MStep
        sta MusSl,x         ; its end: hold the last pitch
        bcs MDec            ; (carry is set: equal)
MStep:  inc MusSl,x
        tay
        lda MusNote,y
        jsr SetPitch
MDec:   txa
        lsr
        tay
        lda MusFrame
        and MusRate,y
        bne MOut
        lda MusVol,x
        cmp MusFloor,y
        bcc MOut            ; at the floor (or silent)
        dec MusVol,x
MOut:   lda MusVol,x
        sta AUDV0,y
        rts

        include "frakmusic_c.inc"
