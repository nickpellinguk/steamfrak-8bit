; Trogg control, after Steam Frak's TroggStanding / TroggFalling / TroggClimbing (js/trogg.js),
; scaled from its 34-pixel Trogg to ours (13 rows): 1 Frak pixel = 13/34 row.
;   standing: left/right walk a pixel every other frame (our pixels are twice Frak's); up climbs a ladder at the feet, or jumps (keeping
;     the walking direction); down climbs onto a ladder below the platform; nothing underfoot falls
;   falling: gravity to a terminal speed; up/down catches a ladder when not falling fast; landing
;     too fast, or reaching the bottom of the screen, kills him (he restarts at the level's start)
;   climbing: a row every other frame, sliding a pixel every fourth frame to the ladder's centre; left/right walks
;     off onto a platform, or falls; climbing down onto a platform stands; the top steps off
;   up/down are ignored after landing until released (Frak's updowndebounce)
; Movement is tested against the level's movement maps (atarivcs/PLAN.md, "Movement maps"):
;   PIdx (32 bands of 6 lines) -> byte offset into PPool (2 bytes: 16 cells of 8 px, x 16-143)
;   LIdx (36 columns of 3 px on the P1 grid, x 19-126) -> byte offset into LPool (4 bytes: 32
;     bands of 6 lines)
;   FB: feet row -> platform band right under the feet, or $FF; Band3: n -> n / 3 (rows to
;     6-line bands, and pixels to 3 px columns)
;   LadL: the level's ladders (x, top row, bottom row), NLAD of them. The map says whether there is
;     a ladder (to 6 lines); the list gives the one being climbed: its x (the climbing centre) and
;     its exact ends (a Frak ladder stops above the platform below: down off it drops)
; Included by levelc.py, which defines H, START_X, START_ROW and the data labels.

TX      = $A0           ; Trogg x (left edge, pixels)
TRow    = $A1           ; feet row (2-line rows)
TYF     = $A2           ; feet row fraction (1/256 row)
VYL     = $A3           ; vertical speed, rows/frame in 8.8, down positive
VYH     = $A4
XV      = $A5           ; horizontal speed in the air: -1, 0, 1
State   = $A6           ; 0 standing, 1 in the air, 2 climbing
Facing  = $A7           ; REFP0 value: 0 right, 8 left
Tmp     = $A8
Tmp2    = $A9
Joy     = $AA           ; SWCHA this frame (player 0 in bits 7-4, 0 = pressed)
HMV     = $AB           ; HMP0 for this frame's HMOVE
Frm     = $AC
Dead    = $AD           ; frames until the restart (0: alive)
XM      = $AE           ; joystick x this frame
Rows    = $AF
UDDeb   = $B0           ; 1: ignore up/down until both are released
Repos   = $B1           ; 1: position P0 from TX this frame (start, restart)
LTarget = $B2           ; the x of the ladder being climbed
LTop    = $B3           ; ... its top and bottom rows (feet)
LBot    = $B4
LRowQ   = $B5
YoLen   = $B6           ; yoyo: length (pixels) and fraction
YoF     = $B7
YoBack  = $B8           ; 1: coming back
YoDeb   = $B9           ; 1: fire must be released before the next throw
YoX     = $BA           ; the yoyo's x (M0)

ST_STAND = 0
ST_AIR   = 1
ST_CLIMB = 2
ST_YOYO  = 3
YOSPD   = 166           ; 1.3 Frak px/tick: 0.65 of our pixels a frame
YOMAX   = 40            ; 80 Frak px
GRAV    = 5             ; 0.05 px/tick^2
JUMPV   = 122           ; 1.25 px/tick
DIEV    = 157           ; landing at 1.6 px/tick or faster kills
TERMV   = 392           ; 4 px/tick
DROPV   = 98            ; dropping off a ladder's bottom: 1 px/tick
GRABV   = 125           ; ladders can be caught when falling no faster than 1.275 px/tick

; ---- position an object: A = x, X = 0 for P0 or 2 for M0 (pass x + 1 for M0: it lands a pixel left
; of P0 for the same strobe). Coarse RESx from a divide-by-15 loop, then HMOVE for the rest: the
; strobe ends at cycle 5n + 18 (n loop passes), so P0's coarse x is 15(n - 1) + 6 and HMTab moves
; it r - 6 (r = x mod 15). Takes three lines; HMCLR at the end. Kept within a page: a branch across
; one would add a cycle.
        IF (<.) > $E0
        ALIGN 256
        ENDIF
PosObj: sta WSYNC
        sec
PosL:   sbc #15
        bcs PosL
        adc #15
        tay
        lda HMTab,y
        bit $80
        nop
        sta RESP0,x
        sta HMP0,x
        sta WSYNC
        sta HMOVE
        sta WSYNC
        sta HMCLR
        rts

; ---- A = feet row; returns A != 0 when a platform is right under the feet (X, Y, Tmp used)
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
        lda Band3,y             ; 6-line band, 0-31
        sta Tmp2
        jsr Column
        bcs LadNo
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

; ---- Y = the 3 px column (P1 grid: x 19 + 3c) under the Trogg's centre; carry set when off the map
Column: lda TX
        sec
        sbc #15                 ; centre (TX + 4) - 19
        bcc ColOff
        tay
        lda Band3,y
        cmp #36
        tay
        rts
ColOff: sec
        rts

; ---- A = -1, 0, 1: move a pixel (within x 16-135), through this frame's HMOVE; only on even
; frames (our pixels are twice as wide as Frak's, so a pixel every other frame matches its speed)
MoveX:  tax
        beq MXDone
        lda Frm
        lsr
        bcs MXDone
        txa
        bmi MXLeft
        lda TX
        cmp #135
        bcs MXDone
        inc TX
        lda #$F0
        sta HMV
        rts
MXLeft: lda TX
        cmp #17
        bcc MXDone
        dec TX
        lda #$10
        sta HMV
MXDone: rts

; ---- joystick x: A = 1 right, -1 left, 0 (flags set)
JoyX:   lda Joy
        bpl JXR
        asl
        bpl JXL
        lda #0
        rts
JXR:    lda #1
        rts
JXL:    lda #$FF
        rts

; ---- A = -1 / 1: face that way
SetFacing:
        ldx #0
        cmp #1
        beq SF1
        ldx #8
SF1:    stx Facing
        rts

; ---- one frame of movement
Logic:  lda #0
        sta HMV
        lda Dead
        beq Alive
        dec Dead
        bne LRet
        lda #START_X            ; restart
        sta TX
        lda #START_ROW
        sta TRow
        lda #0
        sta TYF
        sta VYL
        sta VYH
        sta XV
        sta State
        sta Facing
        lda #1
        sta Repos
        sta UDDeb
LRet:   rts
Alive:  lda SWCHA
        sta Joy
        lda INPT4               ; fire released: the next throw is allowed
        bpl FireDn
        lda #0
        sta YoDeb
FireDn:
        lda UDDeb
        beq NoDeb
        lda Joy
        and #$30
        cmp #$30
        bne UDHeld
        lda #0
        sta UDDeb
        beq NoDeb
UDHeld: lda Joy
        ora #$30
        sta Joy
NoDeb:  lda State
        cmp #ST_YOYO
        bne L0
        jmp DoYoyo
L0:     cmp #ST_CLIMB
        bne L1
        jmp DoClimb
L1:     cmp #ST_AIR
        bne DoStand
        jmp DoAir

DoStand:
        jsr JoyX
        sta XM
        beq DS1
        jsr SetFacing
        lda XM
        jsr MoveX
DS1:    lda TRow
        jsr Floor
        bne DS2
        lda XM                  ; nothing underfoot: fall, still going the way he walked
        sta XV
        lda #0
        sta VYL
        sta VYH
        sta TYF
        lda #ST_AIR
        sta State
        rts
DS2:    lda INPT4               ; fire: throw the yoyo the way he faces (he stands still)
        bmi DS2a
        lda YoDeb
        bne DS2a
        lda #1
        sta YoDeb
        lda #0
        sta YoLen
        sta YoF
        sta YoBack
        lda #ST_YOYO
        sta State
        jmp YoPos
DS2a:   lda Joy
        and #$10
        bne DS3
        lda TRow                ; up: a ladder at the feet, or jump
        jsr TryLadder
        bne StartClimb
        lda XM
        sta XV
        lda #<(-JUMPV)
        sta VYL
        lda #$FF
        sta VYH
        lda #0
        sta TYF
        lda #ST_AIR
        sta State
        rts
DS3:    lda Joy
        and #$20
        bne DSRet
        lda TRow                ; down: a ladder below the platform
        cmp #94
        bcs DSRet
        adc #1
        jsr TryLadder
        beq DSRet
        inc TRow
StartClimb:
        lda #ST_CLIMB
        sta State
        lda #0
        sta TYF
        sta VYL
        sta VYH
        sta XV
DSRet:  rts

; ---- A = row: is there a ladder at it under the Trogg's centre? The map first, then the list for
; the exact ladder: sets LTarget / LTop / LBot and returns A != 0
TryLadder:
        sta LRowQ
        jsr Ladder
        beq TLNo
        ldx #0
TLLoop: cpx #3 * NLAD
        bcs TLNo
        lda TX
        clc
        adc #4 + 1
        sec
        sbc LadL,x              ; centre - ladder x, + 1: within 0-9 when over it (the map's
        cmp #10                 ; 3 px cells reach a pixel past its edges)
        bcs TLNext
        lda LRowQ
        cmp LadL+1,x
        bcc TLNext
        lda LadL+2,x
        cmp LRowQ
        bcc TLNext
        lda LadL,x
        sta LTarget
        lda LadL+1,x
        sta LTop
        lda LadL+2,x
        sta LBot
        lda #1
        rts
TLNext: inx
        inx
        inx
        bne TLLoop
TLNo:   lda #0
        rts


DoAir:  lda XV
        jsr MoveX
        lda VYH                 ; gravity, up to the terminal speed
        bmi Grav
        cmp #>TERMV
        bcc Grav
        bne NoGrav
        lda VYL
        cmp #<TERMV
        bcs NoGrav
Grav:   clc
        lda VYL
        adc #GRAV
        sta VYL
        lda VYH
        adc #0
        sta VYH
NoGrav: lda Joy                 ; up/down catches a ladder unless falling fast
        and #$30
        cmp #$30
        beq NoGrab
        lda VYH
        bmi Grab
        bne NoGrab
        lda VYL
        cmp #GRABV + 1
        bcs NoGrab
Grab:   lda TRow                ; rising: a ladder at the feet; falling: one carrying on below
        ldx VYH                 ; them (so dropping off a ladder's bottom isn't caught again)
        bmi GrabAt
        cmp #94
        bcs NoGrab
        adc #1
GrabAt: jsr TryLadder
        beq NoGrab
        jmp StartClimb
NoGrab: lda VYH
        bmi Rise
        clc                     ; falling: row by row, landing on the first platform crossed
        lda TYF
        adc VYL
        sta TYF
        lda VYH
        adc #0
        sta Rows
        beq AirRet
Down1:  lda TRow
        jsr Floor
        bne Land
        inc TRow
        lda TRow
        cmp #95
        bcs Die                 ; the bottom of the screen
        dec Rows
        bne Down1
AirRet: rts
Land:   lda #0
        sta TYF
        lda VYH                 ; too fast?
        bne Die
        lda VYL
        cmp #DIEV
        bcs Die
        lda #0
        sta VYL
        sta VYH
        sta XV
        sta State
        lda #1
        sta UDDeb
        rts
Die:    lda #90
        sta Dead
        rts
Rise:   clc
        lda TYF
        adc VYL
        sta TYF
        lda VYH
        adc #0
        beq AirRet              ; ($FF: up a row this frame)
        lda TRow
        cmp #H
        bcc AirRet
        dec TRow
        rts

DoClimb:
        lda Frm                 ; slide a pixel every fourth frame towards the ladder's centre
        and #2
        bne DC0
        lda LTarget
        cmp TX
        beq DC0
        lda #1
        bcs DCn
        lda #$FF
DCn:    jsr MoveX
DC0:    jsr JoyX
        beq DCV
        sta XM
        jsr SetFacing
        lda TRow
        jsr Floor
        beq DCFall
        lda #ST_STAND           ; on a platform: walk off the ladder
        sta State
        rts
DCFall: lda XM                  ; between platforms: walk off into a fall
        sta XV
DCDrop: lda #0
        sta VYL
        sta VYH
        sta TYF
        lda #ST_AIR
        sta State
        rts
DCV:    lda Joy
        and #$10
        bne DCDown
        lda TRow                ; up while the feet are on the ladder (its exact top)
        cmp LTop
        bcc DCTop
        lda Frm                 ; a row every other frame
        lsr
        bcs DCRet
        lda TRow
        cmp #H
        bcc DCRet
        dec TRow
        rts
DCTop:  lda TRow                ; the top: step off onto a platform, or hold on
        jsr Floor
        beq DCRet
DCStand: lda #ST_STAND
        sta State
        lda #1
        sta UDDeb
        rts
DCDown: lda Joy
        and #$20
        bne DCRet
        lda TRow
        jsr Floor
        bne DCStand             ; climbed down onto a platform
        lda TRow                ; down to its exact bottom, then off it
        cmp LBot
        bcs DCOff
        lda Frm
        lsr
        bcs DCRet
        inc TRow
DCRet:  rts
DCOff:  lda #0                  ; off the bottom of the ladder: drop, at Frak's 1 px/tick
        sta XV
        sta TYF
        sta VYH
        lda #DROPV
        sta VYL
        lda #ST_AIR
        sta State
        rts

; ---- the yoyo (Frak's YoyoingOut / YoyoingBack): out while fire is held, up to YOMAX; back when
; fire is released, at full length or at the screen's edge; then standing again. No collisions yet.
DoYoyo:
        IFCONST YOTEST          ; (picture checks: held out at YOTEST pixels)
        lda #YOTEST
        sta YoLen
        jmp YoPos
        ENDIF
        lda TRow
        jsr Floor
        bne DY1
        lda #0                  ; the floor has gone: fall
        sta XV
        sta VYL
        sta VYH
        sta TYF
        lda #ST_AIR
        sta State
        rts
DY1:    lda YoBack
        bne DYBack
        lda INPT4
        bmi DYTurn
        lda YoLen
        cmp #YOMAX
        bcs DYTurn
        clc
        lda YoF
        adc #YOSPD
        sta YoF
        lda YoLen
        adc #0
        sta YoLen
        jmp YoPos
DYTurn: lda #1
        sta YoBack
DYBack: sec
        lda YoF
        sbc #YOSPD
        sta YoF
        lda YoLen
        sbc #0
        sta YoLen
        bcs YoPos
        lda #ST_STAND           ; back in his hand
        sta State
        rts
; YoX from the length: right of his hand facing right (TX + 8 + len), left of it facing left
YoPos:  lda Facing
        bne YPL
        lda TX
        clc
        adc #8
        adc YoLen
        cmp #156
        bcs YPEdge
        sta YoX
        rts
YPL:    lda TX
        sec
        sbc #4
        sbc YoLen
        bcc YPEdge
        sta YoX
        rts
YPEdge: lda #1                  ; the screen's edge: come back
        sta YoBack
        rts
