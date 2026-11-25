; Trogg control, first version: walk, fall off edges, jump (fire), climb ladders (up/down).
; Everything is tested against the level's movement maps (atarivcs/PLAN.md, "Movement maps"):
;   PIdx (32 bands of 6 lines) -> byte offset into PPool (2 bytes: 16 cells of 8 px, x 16-143)
;   LIdx (32 columns of 4 px)  -> byte offset into LPool (4 bytes: 32 bands of 6 lines)
;   FB: feet row -> platform band right under the feet, or $FF when the row below isn't a top
; Included by levelc.py, which defines H (frame height), JUMPLEN and the data labels.

TX      = $A0           ; Trogg x (left edge, pixels)
TRow    = $A1           ; feet row (2-line rows, 0-95)
JumpT   = $A2           ; frames left in a jump (0: not jumping)
Climb   = $A3           ; 1 while on a ladder
Facing  = $A4           ; REFP0 value: 0 right, 8 left
Tmp     = $A5
Tmp2    = $A6
FireOld = $A7           ; INPT4 last frame (bit 7 clear: fire was held)
Joy     = $A8           ; SWCHA this frame (player 0 in bits 7-4, 0 = pressed)
HMV     = $A9           ; HMP0 for this frame's HMOVE
Frm     = $AA           ; frame counter

; ---- A = feet row; returns A != 0 when a platform is right under the feet (X, Y used)
Floor:  tay
        lda FB,y
        bmi FloorNo
        tay
        lda PIdx,y
        sta Tmp
        lda TX
        sec
        sbc #12                 ; the Trogg's centre (TX + 4) - 16
        bcc FloorNo
        cmp #128
        bcs FloorNo
        lsr
        lsr
        lsr                     ; 8 px cell, 0-15
        tax
        lsr
        lsr
        lsr                     ; its byte in the entry, 0-1
        clc
        adc Tmp
        tay
        txa
        and #7
        tax
        lda PPool,y
        and Mask8,x
        rts
FloorNo: lda #0
        rts

; ---- A = row; returns A != 0 when a ladder cell is under the Trogg's centre on that row
Ladder: tay
        lda Band3,y             ; 6-line band, 0-31 (the platform grid)
        sta Tmp2
        lda TX
        clc
        adc #4
        lsr
        lsr                     ; 4 px column
        cmp #32
        bcs LadNo
        tay
        lda LIdx,y
        sta Tmp
        lda Tmp2
        lsr
        lsr
        lsr
        clc
        adc Tmp
        tay
        lda Tmp2
        and #7
        tax
        lda LPool,y
        and Mask8,x
        rts
LadNo:  lda #0
        rts

; ---- one frame of movement
Logic:  lda #0
        sta HMV
        lda SWCHA
        sta Joy
        lda Climb
        beq NotClimb
        ; on a ladder: left or right while standing on a platform steps off it
        lda Joy
        and #$C0
        cmp #$C0
        beq ClimbV
        lda TRow
        jsr Floor
        beq ClimbV
        lda #0
        sta Climb
        jmp NotClimb
ClimbV: lda Frm
        and #1                  ; climb a row every other frame
        bne CDone
        lda Joy
        and #$10
        bne CDown
        lda TRow
        jsr Ladder
        bne CUp
        lda TRow                ; the top of the ladder: step off onto a platform, or stay
        jsr Floor
        bne COff
        rts
CUp:        lda TRow
        cmp #H
        bcc CDone
        dec TRow
        rts
CDown:  lda Joy
        and #$20
        bne CDone
        lda TRow
        cmp #94
        bcs CDone
        adc #1
        jsr Ladder
        beq COff                ; off the bottom
        inc TRow
        rts
COff:   lda #0
        sta Climb
CDone:  rts

NotClimb:
        ; up with a ladder at the feet, or down with one just below them, starts climbing
        lda JumpT
        bne Walk
        lda Joy
        and #$10
        bne NC1
        lda TRow
        jsr Ladder
        bne StartC
NC1:    lda Joy
        and #$20
        bne Walk
        lda TRow
        cmp #94
        bcs Walk
        adc #1
        jsr Ladder
        beq Walk
StartC: lda #1
        sta Climb
        rts
Walk:   lda Joy
        bmi NoRight
        lda TX
        cmp #135
        bcs NoRight
        inc TX
        lda #$F0                ; HMP0 -1: one pixel right
        sta HMV
        lda #0
        sta Facing
NoRight: bit Joy
        bvs NoLeft
        lda TX
        cmp #17
        bcc NoLeft
        dec TX
        lda #$10                ; one pixel left
        sta HMV
        lda #8
        sta Facing
NoLeft: lda JumpT
        beq NoJump
        dec JumpT
        tax
        lda JumpDY-1,x          ; 1: up a row this frame
        beq JDone
        lda TRow
        cmp #H
        bcc JDone
        dec TRow
JDone:  rts
NoJump: lda TRow
        jsr Floor
        beq Fall
        lda INPT4               ; on a platform: fire (newly pressed) jumps
        bmi FireUp
        lda FireOld
        bpl FireUp
        lda #JUMPLEN
        sta JumpT
FireUp: lda INPT4
        sta FireOld
        rts
Fall:   lda TRow
        cmp #94
        bcs FireUp
        inc TRow
        jmp FireUp
