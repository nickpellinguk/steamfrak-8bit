        processor 6502
VSYNC    = $00
VBLANK   = $01
WSYNC    = $02
NUSIZ0   = $04
NUSIZ1   = $05
COLUP0   = $06
COLUP1   = $07
COLUBK   = $09
CTRLPF   = $0A
REFP1    = $0C
RESP0    = $10
RESP1    = $11
RESM1    = $13
RESBL    = $14
GRP1     = $1C
ENAM1    = $1E
ENABL    = $1F
HMP1     = $21
HMM1     = $23
HMBL     = $24
VDELP1   = $26
HMOVE    = $2A
HMCLR    = $2B
HMP0 = $20
HMM0 = $22
REFP0 = $0B
INPT4 = $0C
SWCHA = $280
INTIM = $284
TIM64T = $296
H = 13
START_X = 57
START_ROW = 83
NLAD = 3
NIR = 5
NITEM = 4
HANDUP = 4
RunX = $C0
FRONT_BG = $C6
FRONT_INK = $00
FRONT_FILL = $1E
TOPROWS = 5
MUSRAM = $DB
AUDC0 = $15
AUDC1 = $16
AUDF0 = $17
AUDF1 = $18
AUDV0 = $19
AUDV1 = $1A
TWHITE = $0E
TAIL_X = 36
GRP0 = $1B
COLUP0 = $06
RESM0 = $12
ENAM0 = $1D
COLUPF = $08
PF0 = $0D
PF1 = $0E
PF2 = $0F
TrogPtr = $80
Buffer = $82
Lad          = $F000
C0           = $F100
G0           = $F200
Stripe       = $F100
LPF1         = $F000
RPF1         = $F08A
RPF2         = $F090
LPF2         = $F000
Font         = $F300
HMTab1       = $F000
FL1          = $F358
FL2          = $F394
FR2          = $F400
FR1          = $F43C
FBK1         = $F478
FBK2         = $F4A0
FG1          = $F2C4
TroggStrip   = $F500
TroggFrame   = $F000
PIdx         = $F00D
PPool        = $F02B
LIdx         = $F035
LPool        = $F055
FB           = $F069
Band3        = $F0CA
Mask8        = $F14A
TroggFrames  = $F152
LadL         = $F16C
RM1          = $F175
RM2          = $F00D
RXV          = $F17A
ItX          = $F18E
ItTop        = $F192
ItBot        = $F196
ItBit        = $F19A
ItKind       = $F19E
HMTab        = $F1A2
        seg bank0
        org $0000
        rorg $F000
        .byte $18,$3C,$7C,$6E,$7E,$38,$7C,$FE,$BD,$3C,$24,$24,$66,$00,$00,$00
        .byte $00,$00,$00,$00,$02,$00,$04,$00,$00,$00,$00,$00,$06,$00,$00,$00
        .byte $00,$02,$00,$00,$00,$00,$00,$00,$00,$08,$00,$00,$00,$F0,$00,$00
        .byte $3F,$00,$0F,$FF,$F0,$00,$00,$00,$00,$04,$04,$04,$00,$00,$00,$00
        .byte $00,$00,$08,$0C,$0C,$10,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$FF,$FF,$F0,$00,$00,$07
        .byte $F0,$00,$FF,$F7,$F0,$00,$FF,$F0,$00,$FF,$FF,$01,$FF,$FF,$02,$FF
        .byte $FF,$03,$FF,$FF,$04,$FF,$FF,$05,$FF,$FF,$06,$FF,$FF,$07,$FF,$FF
        .byte $08,$FF,$FF,$09,$FF,$FF,$0A,$FF,$FF,$0B,$FF,$FF,$0C,$FF,$FF,$0D
        .byte $FF,$FF,$0E,$FF,$FF,$0F,$FF,$FF,$10,$FF,$FF,$11,$FF,$FF,$12,$FF
        .byte $FF,$13,$FF,$FF,$14,$FF,$FF,$15,$FF,$FF,$16,$FF,$FF,$17,$FF,$FF
        .byte $18,$FF,$FF,$19,$FF,$FF,$1A,$FF,$FF,$1B,$FF,$FF,$1C,$FF,$FF,$1D
        .byte $FF,$FF,$1E,$FF,$FF,$1F,$FF,$FF,$20,$FF,$00,$00,$00,$01,$01,$01
        .byte $02,$02,$02,$03,$03,$03,$04,$04,$04,$05,$05,$05,$06,$06,$06,$07
        .byte $07,$07,$08,$08,$08,$09,$09,$09,$0A,$0A,$0A,$0B,$0B,$0B,$0C,$0C
        .byte $0C,$0D,$0D,$0D,$0E,$0E,$0E,$0F,$0F,$0F,$10,$10,$10,$11,$11,$11
        .byte $12,$12,$12,$13,$13,$13,$14,$14,$14,$15,$15,$15,$16,$16,$16,$17
        .byte $17,$17,$18,$18,$18,$19,$19,$19,$1A,$1A,$1A,$1B,$1B,$1B,$1C,$1C
        .byte $1C,$1D,$1D,$1D,$1E,$1E,$1E,$1F,$1F,$1F,$20,$20,$20,$21,$21,$21
        .byte $22,$22,$22,$23,$23,$23,$24,$24,$24,$25,$25,$25,$26,$26,$26,$27
        .byte $27,$27,$28,$28,$28,$29,$29,$29,$2A,$2A,$80,$40,$20,$10,$08,$04
        .byte $02,$01,$18,$3C,$7C,$6E,$7E,$38,$7C,$FE,$BD,$3C,$24,$24,$66,$18
        .byte $3C,$3C,$BC,$FE,$3C,$3C,$7E,$5A,$3C,$24,$66,$42,$1F,$15,$53,$3D
        .byte $18,$3B,$3A,$40,$51,$01,$08,$02,$04,$04,$22,$2A,$2A,$2A,$5C,$62
        .byte $62,$62,$7E,$86,$86,$86,$A8,$B4,$B4,$B4,$C0,$C4,$C4,$C4,$22,$58
        .byte $5E,$76,$11,$38,$4C,$2A,$14,$3B,$53,$2C,$01,$02,$04,$08,$00,$00
        .byte $01,$00,$60,$50,$40,$30,$20,$10,$00,$F0,$E0,$D0,$C0,$B0,$A0,$90
        .byte $80
Start:  sei
        cld
        ldx #$FF
        txs
        lda #0
Clear:  sta $00,x
        dex
        bne Clear
        lda #START_X
        sta TX
        lda #START_ROW
        sta TRow
        IFCONST YOTEST
        lda #ST_YOYO
        sta State
        lda #YOFACE
        sta Facing
        ENDIF
        IFCONST SKIPFRONT
        lda #1
        sta Mode
        ENDIF
        IFCONST START_COLL
        lda #START_COLL
        sta Collected
        ENDIF
        lda #1
        sta Repos           ; position P0 in the first frame
        sta CTRLPF          ; mirrored playfield
        sta NUSIZ1
        lda #$20
        sta NUSIZ0          ; single-width Trogg
Frame:  lda #2
        sta VSYNC
        sta WSYNC
        sta WSYNC
        sta WSYNC
        lda #0
        sta VSYNC
        lda #43
        sta TIM64T
        lda #2
        sta VBLANK
        sta HMCLR
        lda #$AA
        sta COLUBK
        sta COLUPF
        lda #$1E
        sta COLUP0
        lda #0
        sta COLUP1
        sta GRP1
        sta GRP0
        sta PF1
        sta PF2
        inc Frm
        lda Mode
        bne InGame
        lda #FRONT_BG       ; the front screen: green, black blocks, no Trogg, fire starts
        sta COLUBK
        lda #FRONT_INK
        sta COLUPF
        jsr FrontLogic
        jmp Shown
InGame: jsr Timer
        jsr MusicTick       ; the tune, a frame on
        jsr Logic
        jsr RunVars         ; the item runs' line indexes, from the collected bits
Shown:
        lda #$FE            ; the frame's bit 0 (the hand row's yoyo, M0) only while it's out
        ldx State
        cpx #ST_YOYO
        bne CFm
        lda #$FF
CFm:    ldx Mode
        bne CFm2
        lda #0              ; (front screen: an empty Trogg buffer)
CFm2:   sta Tmp
        ldx #0              ; the Trogg's frame (walking, or climbing) into the buffer
        lda State
        cmp #ST_CLIMB
        bne CF0
        ldx #H
CF0:    ldy #1
CopyF:  lda TroggFrames,x
        and Tmp
        sta Buffer,y
        inx
        iny
        cpy #H+1
        bne CopyF
        lda Facing
        sta REFP0
        lda #<(TroggStrip+94+H+TOPROWS)   ; (the kernel's first body is row TOPROWS)
        sec
        sbc TRow
        sta TrogPtr
        lda #>TroggStrip
        sta TrogPtr+1
        lda Repos           ; a new position (start, restart): RESP0 and HMOVE from TX
        beq NoRep
        lda #0
        sta Repos
        lda TX
        ldx #0
        jsr PosObj
        jmp Moved
NoRep:  lda HMV             ; otherwise this frame's pixel of movement
        sta HMP0
        sta WSYNC
        sta HMOVE
        sta WSYNC
        sta HMCLR
Moved:  lda State           ; the yoyo: M0 to YoX
        cmp #ST_YOYO
        bne NoYo
        ldx YoX
        inx
        txa
        ldx #2
        jsr PosObj
NoYo:   sta WSYNC
        bit $80
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta RESP1
        sta HMCLR
        lda Mode            ; playing: P0 and P1 for the timer (the band puts P0 back)
        beq NoTime
        lda #16
        ldx #0
        jsr PosObj
        lda #24
        ldx #1
        jsr PosObj
        lda #1
        sta NUSIZ0          ; two copies close: x 16 and 32 (P1: 24 and 40)
        lda #TWHITE
        sta COLUP0
        sta COLUP1
        lda #0
        sta REFP0
NoTime: lda Mode            ; the front screen: P1 is the tail's fill (double width, yellow,
        bne NoTail          ; behind the playfield)
        lda #TAIL_X - 1     ; (a double-width player starts a pixel later)
        ldx #1
        jsr PosObj
        lda #5
        sta NUSIZ1
        sta CTRLPF          ; mirrored playfield, over the players
        lda #FRONT_FILL
        sta COLUP1
NoTail:
WaitVB: lda INTIM
        bne WaitVB
        sta WSYNC
        lda #0
        sta VBLANK
        jmp $FFE0           ; to the display bank: the kernel
Overscan:
        lda #2
        sta VBLANK
        ldx #29
OS:     sta WSYNC
        dex
        bne OS
        jmp Frame
        include "/home/user/steamfrak-8bit/atarivcs/levelc/game.asm"
        include "musicdrv_c.asm"   ; the Frak tune, compact (atarivcs/music), 13 bytes of RAM at MUSRAM
LogicEnd:
        org $0FE0
        rorg $FFE0
        bit $FFF9           ; $FFE0: -> bank 1 (which carries on at $FFE3: jmp Kernel)
        .byte 0,0,0
        .byte 0,0,0         ; $FFE6: (bank 1: bit $FFF8)
        jmp Overscan        ; $FFE9: back from the kernel
        bit $FFF8           ; $FFEC: reset, in either bank -> bank 0
        jmp Start           ; $FFEF
        org $0FFC
        rorg $FFFC
        .word $FFEC
        .word $FFEC
        seg bank1
        org $1000
        rorg $F000
        .byte $60,$50,$40,$30,$20,$10,$00,$F0,$E0,$D0,$C0,$B0,$A0,$90,$80,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$7E,$42,$42,$42,$7E,$42,$42,$42
        .byte $7E,$42,$42,$42,$7E,$42,$42,$42,$7E,$42,$42,$42,$7E,$42,$42,$42
        .byte $7E,$42,$42,$42,$7E,$42,$42,$42,$7E,$42,$42,$42,$7E,$42,$42,$42
        .byte $7E,$42,$7E,$42,$42,$42,$7E,$42,$42,$42,$7E,$42,$42,$42,$7E,$42
        .byte $42,$42,$7E,$42,$42,$42,$7E,$42,$42,$42,$7E,$42,$42,$42,$7E,$42
        .byte $42,$42,$7E,$42,$42,$42,$7E,$42,$42,$42,$7E,$42,$42,$42,$42,$42
        .byte $7E,$42,$42,$42,$7E,$42,$42,$42,$7E,$42,$42,$42,$7E,$42,$42,$42
        .byte $7E,$42,$42,$42,$7E,$42,$42,$42,$7E,$42,$42,$42,$7E,$42,$42,$42
        .byte $7E,$42,$42,$42,$7E,$42,$42,$42,$7E,$42,$42,$42,$7E,$42,$42,$42
        .byte $7E,$42,$42,$42,$7E,$42,$42,$42,$FF,$FF,$FF,$FF,$FF,$FF,$0F,$0F
        .byte $0F,$0F,$0F,$0F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$58,$58,$00,$A4,$A4,$00,$00,$00,$00,$00,$00,$00,$58
        .byte $58,$00,$A4,$A4,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$1E,$1E,$1E
        .byte $1E,$1E,$00,$1E,$1E,$1E,$1E,$1E,$00,$58,$58,$00,$A4,$A4,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$58,$58,$58,$58,$58,$58,$58,$58
        .byte $58,$58,$58,$58,$58,$58,$58,$58,$58,$58,$58,$58,$58,$58,$58,$58
        .byte $58,$58,$58,$58,$58,$58,$58,$58,$00,$58,$58,$00,$A4,$A4,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$18,$24,$42,$81,$42,$24,$18,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$60,$90,$9F
        .byte $95,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$18
        .byte $24,$42,$81,$42,$24,$18,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$3C,$7E,$DB,$FF,$FF,$66,$FF,$BD
        .byte $FF,$FF,$7E,$7E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $24,$24,$66,$E7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0F,$0F,$0F,$0F,$0F
        .byte $0F,$0F,$0F,$3C,$3C,$3C,$3C,$F0,$F0,$F0,$F0,$00,$00,$00,$00,$00
        .byte $00,$3C,$66,$76,$7E,$6E,$66,$3C,$00,$3C,$18,$18,$18,$18,$38,$18
        .byte $00,$7E,$60,$30,$1C,$06,$66,$3C,$00,$3C,$66,$06,$1C,$06,$66,$3C
        .byte $00,$0C,$0C,$7E,$6C,$3C,$1C,$0C,$00,$3C,$66,$06,$06,$7C,$60,$7E
        .byte $00,$3C,$66,$66,$7C,$60,$30,$1C,$00,$30,$30,$30,$18,$0C,$06,$7E
        .byte $00,$3C,$66,$66,$3C,$66,$66,$3C,$00,$38,$0C,$06,$3E,$66,$66,$3C
        .byte $00,$00,$18,$18,$00,$18,$18,$00,$07,$07,$07,$07,$08,$08,$08,$08
        .byte $09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09
        .byte $09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$08,$08,$08,$08
        .byte $06,$06,$06,$06,$02,$02,$02,$02,$04,$04,$04,$04,$09,$09,$09,$09
        .byte $0E,$0E,$0E,$0E,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$1B,$1B,$1B,$1B
        .byte $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$99,$99,$99,$99,$A8,$A8,$A8,$A8
        .byte $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$00,$00,$00,$00,$FE,$FE,$FE,$FE
        .byte $02,$02,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $FF,$FF,$FF,$FF,$00,$00,$00,$00,$95,$95,$95,$95,$55,$55,$55,$55
        .byte $59,$59,$59,$59,$D1,$D1,$D1,$D1,$59,$59,$59,$59,$54,$54,$54,$54
        .byte $55,$55,$55,$55,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$03,$03
        .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
        .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
        .byte $04,$04,$04,$04,$03,$03,$03,$03,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$C6,$C6,$C6,$C6,$1E,$1E,$1E,$1E
        .byte $1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E
        .byte $1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E
        .byte $C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6
        .byte $C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6
        .byte $C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6
        .byte $C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
Kernel: lda Mode         ; 0: the front screen
        beq KFront
        jmp KLevel
KFront:
        ldy #52
FTop:   sta WSYNC
        dey
        bne FTop
        ldx #0
        jmp FLine           ; (over any alignment padding)
        IF (<.) > $C0
        ALIGN 256
        ENDIF
FLine:  sta WSYNC
        lda FL1,x           ; 4
        sta PF1             ; 7
        lda FL2,x           ; 11
        sta PF2             ; 14
        ldy FR1,x           ; 18
        lda FBK1,x          ; 22
        nop
        nop
        nop
        bit $80             ; 31
        sta COLUBK          ; 34: yellow from x 32-36
        lda FR2,x           ; 38
        sty PF1             ; 41: the right PF1
        nop
        nop                 ; 45
        sta PF2             ; 48: the right PF2
        lda FBK2,x          ; 52
        ldy FG1,x           ; 56: the tail's fill (P1) for the next line
        nop
        nop                 ; 60
        sta COLUBK          ; 63: green from x 121-124
        sty GRP1            ; 66
        inx                 ; 68
        cpx #60             ; 70
        bne FLine           ; 73
        sta WSYNC
        lda #0
        sta PF1
        sta PF2
        ldy #79
FBot:   sta WSYNC
        dey
        bne FBot
        jmp KEnd
KLevel:
        lda #$00
        sta COLUBK          ; the band: black
        ldy #7
        jmp TLine           ; (over any alignment padding)
        IF (<.) > $D0
        ALIGN 256
        ENDIF
TLine:  sta WSYNC
        lda (TDig),y        ; 5
        sta GRP0            ; 8: P0's first copy (x 16)
        lda (TDig+2),y      ; 13
        sta GRP1            ; 16: P1's first copy (x 24)
        lda (TDig+4),y      ; 21
        tax                 ; 23
        lda (TDig+6),y      ; 28
        stx GRP0            ; 31: P0's second copy (x 32)
        sta GRP1            ; 34: P1's second copy (x 40)
        dey
        bpl TLine
        lda #0
        sta GRP0
        sta GRP1
        lda #$20
        sta NUSIZ0          ; the Trogg again: one copy, a 4 px yoyo
        lda Facing
        sta REFP0
        lda #$1E
        sta COLUP0
        lda #0
        sta COLUP1
        lda TX
        jmp TPos
        IF (<.) > $E0
        ALIGN 256
        ENDIF
TPos:   sta WSYNC           ; P0 back to TX: as PosObj (RESP0 ends at 5n + 18)
        sec
TPosL:  sbc #15
        bcs TPosL
        adc #15
        tay
        lda HMTab1,y
        bit $80
        nop
        sta.w RESP0
        sta HMP0
        sta WSYNC
        sta HMOVE           ; 3 (this line's first 8 pixels are blanked)
        lda #$AA          ; 5
        sta COLUBK          ; 8: the level's background from this line's start
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta RESP1           ; 57: P1 parked for the kernel
        sta HMCLR           ; 60
        ldx #10
        jsr B0
        jsr B0_i
        jsr B0_i
        jsr B0_i
        jsr B0_i
        jsr B0_i
        jsr B0_i
        jsr B0_i
        jsr B0_i
        jsr B0_i
        jsr B0_i
        jsr B0_i
        ldx RunX+0
        jsr B1
        jsr B1_i
        jsr B1_i
        jsr B1_i
        ldx #50
        jsr B2
        jsr B2_i
        jsr B2_i
        ldx #56
        jsr B3
        jsr B3_i
        jsr B3_i
        ldx #62
        jsr B4
        jsr B4_i
        jsr B4_i
        ldx #68
        jsr B5
        jsr B5_i
        jsr B5_i
        jsr B5_i
        jsr B5_i
        jsr B5_i
        jsr B5_i
        jsr B5_i
        jsr B5_i
        jsr B5_i
        jsr B5_i
        jsr B5_i
        ldx RunX+1
        jsr B6
        jsr B6_i
        jsr B6_i
        ldx #104
        jsr B7
        jsr B7_i
        jsr B7_i
        ldx #110
        jsr B5
        jsr B5_i
        jsr B5_i
        jsr B5_i
        jsr B5_i
        jsr B5_i
        jsr B5_i
        jsr B5_i
        ldx RunX+2
        jsr B8
        jsr B8_i
        jsr B8_i
        jsr B8_i
        ldx #50
        jsr B2
        jsr B2_i
        jsr B2_i
        ldx #142
        jsr B9
        ldx #144
        jsr B10
        jsr B10_i
        jsr B10_i
        jsr B10_i
        jsr B10_i
        jsr B10_i
        jsr B10_i
        jsr B10_i
        jsr B10_i
        jsr B10_i
        jsr B10_i
        jsr B10_i
        ldx RunX+3
        jsr B11
        jsr B11_i
        jsr B11_i
        jsr B11_i
        jsr B11_i
        jsr B11_i
        ldx RunX+4
        jsr B12
        jsr B12_i
        ldx #200
        jsr B13
        jsr B13_i
        jsr B13_i
        ldx #206
        jsr B14
        jsr B14_i
        jsr B14_i
        jsr B14_i
        jsr B14_i
        jsr B14_i
        jsr B14_i
        jsr B14_i
        jsr B14_i
KEnd:
        sta WSYNC
        lda #2              ; blank at once (in the horizontal blank), not part-way along the line
        sta VBLANK
        lda #0
        sta PF1
        sta PF2
        sta GRP1
        sta GRP0
        sta ENAM0
        jmp $FFE6           ; back to the game bank: overscan
        IF (<.) + 55 > 256
        ALIGN 256
        ENDIF
B0_i:
        inx
B0:
        sta WSYNC
        inc TrogPtr
        sec
        bit $80
B0_s:
        lda #0
        sta GRP1
        bcs B0_e
        rts
B0_e:
        ldy #0
        lda (TrogPtr),y
        tay
        lda Buffer,y
        inx
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta GRP0
        asl
        sta ENAM0
        clc
        jmp B0_s
        IF (<.) + 61 > 256
        ALIGN 256
        ENDIF
B1_i:
        inx
B1:
        sta WSYNC
        inc TrogPtr
        sec
        bit $80
B1_s:
        lda #0
        sta.w GRP1
        lda G0,x
        ldy C0,x
        sta RESP1
        sty COLUP1
        sta GRP1
        lda #0
        sta GRP1
        sta RESP1
        bcs B1_e
        rts
B1_e:
        ldy #0
        lda (TrogPtr),y
        tay
        lda Buffer,y
        inx
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta GRP0
        asl
        sta ENAM0
        clc
        jmp B1_s
        IF (<.) + 60 > 256
        ALIGN 256
        ENDIF
B2_i:
        inx
B2:
        sta WSYNC
        inc TrogPtr
        sec
        bit $80
B2_s:
        lda LPF1,x
        sta PF1
        lda Stripe,x
        sta COLUPF
        lda #0
        sta GRP1
        lda #$00
        bit $80
        sta PF1
        bcs B2_e
        rts
B2_e:
        ldy #0
        lda (TrogPtr),y
        tay
        lda Buffer,y
        inx
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta GRP0
        asl
        sta ENAM0
        clc
        jmp B2_s
        IF (<.) + 59 > 256
        ALIGN 256
        ENDIF
B3_i:
        inx
B3:
        sta WSYNC
        inc TrogPtr
        sec
        bit $80
B3_s:
        lda #$00
        sta COLUP1
        lda Lad,x
        sta.w GRP1
        sta RESP1
        bit $80
        nop
        nop
        sta RESP1
        bcs B3_e
        rts
B3_e:
        ldy #0
        lda (TrogPtr),y
        tay
        lda Buffer,y
        inx
        bit $80
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta GRP0
        asl
        sta ENAM0
        clc
        jmp B3_s
        IF (<.) + 63 > 256
        ALIGN 256
        ENDIF
B4_i:
        inx
B4:
        sta WSYNC
        inc TrogPtr
        sec
        bit $80
B4_s:
        lda #$00
        sta PF1
        ldy Lad,x
        sty.w GRP1
        sta RESP1
        sta PF2
        lda Stripe,x
        sta RESP1
        sta COLUPF
        lda RPF2,x
        sta PF2
        lda RPF1,x
        sta PF1
        bcs B4_e
        rts
B4_e:
        ldy #0
        lda (TrogPtr),y
        tay
        lda Buffer,y
        inx
        nop
        sta GRP0
        asl
        sta ENAM0
        clc
        jmp B4_s
        IF (<.) + 59 > 256
        ALIGN 256
        ENDIF
B5_i:
        inx
B5:
        sta WSYNC
        inc TrogPtr
        sec
        bit $80
B5_s:
        lda #$AA
        sta COLUPF
        lda Lad,x
        sta.w GRP1
        sta RESP1
        bit $80
        nop
        nop
        sta RESP1
        bcs B5_e
        rts
B5_e:
        ldy #0
        lda (TrogPtr),y
        tay
        lda Buffer,y
        inx
        bit $80
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta GRP0
        asl
        sta ENAM0
        clc
        jmp B5_s
        IF (<.) + 63 > 256
        ALIGN 256
        ENDIF
B6_i:
        inx
B6:
        sta WSYNC
        inc TrogPtr
        sec
        bit $80
B6_s:
        lda #$00
        sta COLUP1
        lda Lad,x
        sta.w GRP1
        sta RESP1
        lda G0,x
        bit $80
        sta RESP1
        lda C0,x
        ldy G0,x
        sty GRP1
        sta COLUP1
        nop
        sta RESP1
        bcs B6_e
        rts
B6_e:
        ldy #0
        lda (TrogPtr),y
        tay
        lda Buffer,y
        inx
        sta GRP0
        asl
        sta ENAM0
        clc
        jmp B6_s
        IF (<.) + 63 > 256
        ALIGN 256
        ENDIF
B7_i:
        inx
B7:
        sta WSYNC
        inc TrogPtr
        sec
        bit $80
B7_s:
        lda #$00
        sta PF1
        sta.w COLUP1
        ldy Lad,x
        sta RESP1
        sty GRP1
        sta.w PF2
        sta RESP1
        lda RPF1,x
        sta PF1
        lda Stripe,x
        sta COLUPF
        bcs B7_e
        rts
B7_e:
        ldy #0
        lda (TrogPtr),y
        tay
        lda Buffer,y
        inx
        bit $80
        nop
        sta GRP0
        asl
        sta ENAM0
        clc
        jmp B7_s
        IF (<.) + 62 > 256
        ALIGN 256
        ENDIF
B8_i:
        inx
B8:
        sta WSYNC
        inc TrogPtr
        sec
        bit $80
B8_s:
        lda #$00
        sta COLUP1
        lda Lad,x
        sta.w GRP1
        sta RESP1
        lda G0,x
        bit $80
        sta RESP1
        ldy C0,x
        nop
        sta RESP1
        sta GRP1
        sty COLUP1
        bcs B8_e
        rts
B8_e:
        ldy #0
        lda (TrogPtr),y
        tay
        lda Buffer,y
        inx
        nop
        nop
        sta GRP0
        asl
        sta ENAM0
        clc
        jmp B8_s
        IF (<.) + 62 > 256
        ALIGN 256
        ENDIF
B9_i:
        inx
B9:
        sta WSYNC
        inc TrogPtr
        sec
        bit $80
B9_s:
        lda #0
        sta GRP1
        lda #$00
        lda Lad,x
        ldy #$00
        sta RESP1
        sty COLUP1
        sta GRP1
        lda #0
        sta GRP1
        sta RESP1
        bcs B9_e
        rts
B9_e:
        ldy #0
        lda (TrogPtr),y
        tay
        lda Buffer,y
        inx
        bit $80
        nop
        nop
        nop
        nop
        nop
        nop
        sta GRP0
        asl
        sta ENAM0
        clc
        jmp B9_s
        IF (<.) + 56 > 256
        ALIGN 256
        ENDIF
B10_i:
        inx
B10:
        sta WSYNC
        inc TrogPtr
        sec
        bit $80
B10_s:
        lda Lad,x
        sta GRP1
        nop
        nop
        nop
        sta RESP1
        nop
        nop
        nop
        sta RESP1
        bcs B10_e
        rts
B10_e:
        ldy #0
        lda (TrogPtr),y
        tay
        lda Buffer,y
        inx
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta GRP0
        asl
        sta ENAM0
        clc
        jmp B10_s
        IF (<.) + 62 > 256
        ALIGN 256
        ENDIF
B11_i:
        inx
B11:
        sta WSYNC
        inc TrogPtr
        sec
        bit $80
B11_s:
        lda #$00
        sta COLUP1
        lda Lad,x
        sta.w GRP1
        sta RESP1
        lda G0,x
        nop
        sta RESP1
        ldy C0,x
        bit $80
        nop
        sta RESP1
        sta GRP1
        sty COLUP1
        bcs B11_e
        rts
B11_e:
        ldy #0
        lda (TrogPtr),y
        tay
        lda Buffer,y
        inx
        nop
        sta GRP0
        asl
        sta ENAM0
        clc
        jmp B11_s
        IF (<.) + 62 > 256
        ALIGN 256
        ENDIF
B12_i:
        inx
B12:
        sta WSYNC
        inc TrogPtr
        sec
        bit $80
B12_s:
        lda #$00
        sta COLUP1
        lda Lad,x
        sta.w GRP1
        sta RESP1
        lda G0,x
        bit $80
        sta GRP1
        lda C0,x
        sta.w COLUP1
        sta RESP1
        bcs B12_e
        rts
B12_e:
        ldy #0
        lda (TrogPtr),y
        tay
        lda Buffer,y
        inx
        nop
        nop
        nop
        nop
        sta GRP0
        asl
        sta ENAM0
        clc
        jmp B12_s
        IF (<.) + 61 > 256
        ALIGN 256
        ENDIF
B13_i:
        inx
B13:
        sta WSYNC
        inc TrogPtr
        sec
        bit $80
B13_s:
        lda LPF1,x
        sta PF1
        lda Stripe,x
        sta COLUPF
        lda LPF2,x
        sta PF2
        lda #0
        sta GRP1
        lda #$00
        sta PF1
        bcs B13_e
        rts
B13_e:
        ldy #0
        lda (TrogPtr),y
        tay
        lda Buffer,y
        inx
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta GRP0
        asl
        sta ENAM0
        clc
        jmp B13_s
        IF (<.) + 57 > 256
        ALIGN 256
        ENDIF
B14_i:
        inx
B14:
        sta WSYNC
        inc TrogPtr
        sec
        bit $80
B14_s:
        lda #$AA
        sta COLUPF
        lda #0
        sta GRP1
        bcs B14_e
        rts
B14_e:
        ldy #0
        lda (TrogPtr),y
        tay
        lda Buffer,y
        inx
        bit $80
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        sta GRP0
        asl
        sta ENAM0
        clc
        jmp B14_s
CodeEnd:
        org $1FE0
        rorg $FFE0
        .byte 0,0,0         ; $FFE0: (bank 0: bit $FFF9)
        jmp Kernel          ; $FFE3
        bit $FFF8           ; $FFE6: -> bank 0 (which carries on at $FFE9: jmp Overscan)
        .byte 0,0,0
        bit $FFF8           ; $FFEC: reset -> bank 0 (jmp Start at $FFEF there)
        org $1FFC
        rorg $FFFC
        .word $FFEC
        .word $FFEC
