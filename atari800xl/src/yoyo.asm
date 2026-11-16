; ---- The yoyo: the C64 port's (c64/src/yoyo.asm: start_yoyo, yoyo_out, yoyo_back, yoyo_longer,
; yoyo_position, yoyo_collide), itself the BBC version's. A_1 has no movable platforms, so the
; carrying is left out; the yoyo knocks Scrubblies off and pops balloons and daggers. yo_len is the
; string's length, tenths of a pixel then pixels: 1.3 a tick out while fire's held, to 80, then
; back at the same rate. The same code as the C64's but for the names (gy, the Scrubblies' corners
; and size, the hazards' sizes) and knock: here a bit in pick.asm's masks (the map put right by
; pkpatch and pkprog, the Scrubbly's infill and collisions gone with it; a restart or checkpoint
; brings it back as it does a gem). Drawn by yolist and strline (trogg8x4.asm): the yoyo at
; (yo_x, yo_y), its origin, one of 4 frames as the length goes; the string a line from his hand
; (tx + 12, or - 12) to yo_x, on level line yo_y - 1, as the BBC version's (the C64 has to draw it
; a character at a time).
YOYO_MAX = 80
start_yoyo
        lda #ST_YOYO_OUT
        sta tstate
        lda #0
        sta yo_len
        lda #1                      ; (length 1 for this tick's position)
        sta yo_len+1
        jsr yoyo_position
        jsr yoyo_collide
        bcc +
        lda #ST_YOYO_BACK
        sta tstate
        lda #1
        sta yo_db
+       lda #0                      ; (then it starts from 0)
        sta yo_len+1
        rts

yoyo_out
        lda #0
        sta yo_turn
        lda doyoyo
        beq _change
        lda yo_len+1
        cmp #YOYO_MAX
        bcs _change
        jsr yoyo_longer
        jmp _moved
_change lda #1                      ; (let go, or as long as it goes)
        sta yo_turn
_moved  jsr yoyo_position
        jsr yoyo_collide
        bcs _back
        lda yo_turn
        bne _back
        lda yo_x+1                  ; (the level's left edge: yo_x < 2, signed)
        bmi _back
        bne _done
        lda yo_x
        cmp #2
        bcs _done
_back   lda #ST_YOYO_BACK
        sta tstate
        lda #1
        sta yo_db
_done   rts

yoyo_back
        lda yo_len                  ; length - 1.3; home if that's 0 or less
        sec
        sbc #3
        bcs +
        adc #10
        clc
+       sta yo_len
        lda yo_len+1
        sbc #1
        sta yo_len+1
        bcc _home
        bmi _home
        ora yo_len
        beq _home
        jsr yoyo_position
        jmp yoyo_collide            ; (still knocks Scrubblies off on the way back)
_home   lda #ST_STAND
        sta tstate
        lda #0
        sta yo_len
        sta yo_len+1
        rts

yoyo_longer                         ; length + 1.3
        lda yo_len
        clc
        adc #3
        cmp #10
        bcc +
        sbc #10
+       sta yo_len
        lda yo_len+1
        adc #1
        sta yo_len+1
        rts

; yo_x = tx + (length + 12) * direction (rounded down), yo_y = gy - 11
yoyo_position
        lda yo_len+1
        clc
        adc #12
        sta ytmp
        lda tface
        bne _l
        lda tx
        clc
        adc ytmp
        sta yo_x
        lda tx+1
        adc #0
        sta yo_x+1
        jmp _y
_l      lda #0
        cmp yo_len                  ; (carry clear if there are tenths: one further)
        lda tx
        sbc ytmp
        sta yo_x
        lda tx+1
        sbc #0
        sta yo_x+1
_y      lda gy
        sec
        sbc #11
        sta yo_y
        lda gy+1
        sbc #0
        sta yo_y+1
        rts

; Did the yoyo hit a Scrubbly? The yoyo's square, x yo_x - 3 to yo_x + 3, y yo_y - 7 to yo_y
; (as the BBC version makes it), against each Scrubbly's 40 x 42 (its shape's corner: scil, scit). A
; Scrubbly hit is knocked off. Carry set if one was.
yoyo_collide
        lda #0
        sta yo_hit
        lda yo_x
        sec
        sbc #3
        sta yb_l
        lda yo_x+1
        sbc #0
        sta yb_l+1
        lda yo_x
        clc
        adc #3
        sta yb_r
        lda yo_x+1
        adc #0
        sta yb_r+1
        lda yo_y
        sec
        sbc #7
        sta yb_t
        lda yo_y+1
        sbc #0
        sta yb_t+1
        ldx #NSCR - 1
_lp     ldy pby + NPK,x             ; (knocked off already: not looked at)
        lda pbm + NPK,x
        and pgone,y
        bne _nx
        lda scil,x                   ; yoyo left < its left + its width (the level's enemy's: ENW) ?
        clc
        adc #ENW
        sta ytmp
        lda scih,x
        adc #0
        sta ytmp+1
        lda yb_l
        cmp ytmp
        lda yb_l+1
        sbc ytmp+1
        bcs _nx
        lda yb_r                    ; yoyo right >= its left ?
        cmp scil,x
        lda yb_r+1
        sbc scih,x
        bcc _nx
        lda scit,x                   ; yoyo top < its top + its height (ENH) ?
        clc
        adc #ENH
        sta ytmp
        lda #0
        adc #0
        sta ytmp+1
        lda yb_t
        cmp ytmp
        lda yb_t+1
        sbc ytmp+1
        bcs _nx
        lda yo_y                    ; yoyo bottom >= its top ?
        cmp scit,x
        lda yo_y+1
        sbc #0
        bcc _nx
        lda #1                      ; hit
        sta yo_hit
        stx ysi
        jsr knock
        ldx ysi
_nx     dex
        bpl _lp
        .if !NOHAZ
        ldx #NHZ - 1                 ; the balloons and daggers: popped (their images' boxes)
_m      lda oact,x
        bne +
        jmp _mn
+
        tay
        dey                         ; (geom.py's tables: by kind - 1)
        lda oxl,x                   ; (left: its origin less kxo; right: + kw - 1)
        sec
        sbc kxo,y
        sta yhl
        lda oxh,x
        sbc #0
        sta yhl+1
        lda yb_r                    ; yoyo right >= its left ?
        sec
        sbc yhl
        lda yb_r+1
        sbc yhl+1
        bpl +
        jmp _mn
+
        lda yhl
        clc
        adc kw,y
        sta yhl
        lda yhl+1
        adc #0
        sta yhl+1                   ; (its right + 1)
        lda yb_l                    ; yoyo left < its right + 1 ?
        sec
        sbc yhl
        lda yb_l+1
        sbc yhl+1
        bmi +
        jmp _mn
+
        lda oy,x                    ; (top: its origin less kyo; bottom: + kh - 1)
        sec
        sbc kyo,y
        sta yhl
        lda oyh,x
        sbc #0
        sta yhl+1
        lda yo_y                    ; yoyo bottom >= its top ?
        sec
        sbc yhl
        lda yo_y+1
        sbc yhl+1
        bpl +
        jmp _mn
+
        lda yhl
        clc
        adc khz,y
        sta yhl
        lda yhl+1
        adc #0
        sta yhl+1
        lda yb_t                    ; yoyo top < its bottom + 1 ?
        sec
        sbc yhl
        lda yb_t+1
        sbc yhl+1
        bmi +
        jmp _mn
+
        lda #0                      ; popped
        sta oact,x
        lda #1
        sta yo_hit
_mn     dex
        bmi +
        jmp _m
+
        .endif
        lda yo_hit
        cmp #1                      ; (carry set if hit)
        rts


; Scrubbly x knocked off: its bit in the patch objects' gone (pick.asm: NPK on)
knock   ldy pby + NPK,x
        lda pbm + NPK,x
        ora pgone,y
        sta pgone,y
        rts

; The yoyo's frame: ((length * direction) >> 3) & 3 (the BBC version's yoyo_image), as a graphic
yoframe lda yo_len+1
        ldx tface
        beq +
        eor #$ff
        clc
        adc #1
        cmp #$80
        ror a
        cmp #$80
        ror a
        cmp #$80
        ror a
        jmp ++
+       lsr a
        lsr a
        lsr a
+       and #3
        clc
        adc #GR_YOYO0
        rts

yo_len  .word 0
yo_turn .byte 0
yo_x    .word 0
yo_y    .word 0
yb_l    .word 0
yb_r    .word 0
yb_t    .word 0
yo_hit  .byte 0
yhl     .word 0                     ; (a balloon's or dagger's edge)
ytmp    .word 0
ysi     .byte 0
