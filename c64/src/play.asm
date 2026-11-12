; ---- Playing: Trogg moved by the keys, a game tick a frame. The movement is the BBC version's
; (../src/frak.asm: trogg_update, trogg_standing, trogg_falling, trogg_climbing, platform_find,
; ladder_find), itself a port of the original's TroggStanding, TroggFalling, TroggClimbing,
; PlatformFind and LadderFind, here as plain 6502 (the BBC's 65C02 instructions replaced) on the
; platforms and ladders where the C64 draws them (geometry.inc, by build.mjs from mockup.mjs's
; geometry.json). As in the BBC version, his y is kept in pixels and twentieths of a pixel (ty,
; tyf), and his y velocity in twentieths of a pixel a tick (tv, + = up): everything the
; original's y and velocity can be (gravity 0.05, a jump 1.25, and y rounded to multiples of
; 0.05), as whole numbers. A_1 has no moving or bouncy platforms, so those parts are left out;
; and the yoyo is still to come.
;
; Death (landing at 1.6 pixels a tick or faster, or falling off the bottom) restarts the level
; after a second.

        .section high               ; (placed past the level map: frak64.asm)
        .include "geometry.inc"     ; NPLATS, NLADS, LEVEL_W, LEVEL_H, TSTARTX, TSTARTY, the tables
        .send high

JUMP_SPEED = 25                     ; (twentieths of a pixel a tick; gravity is 1)
TERMINAL_SPEED = 80
ST_STAND = 0
ST_WALK  = 1
ST_FALL  = 2
ST_CLIMB = 3
ST_YOYO_OUT = 4
ST_YOYO_BACK = 5
X_MAX    = LEVEL_W - 10

; ---- A game tick: the keys, then Trogg (or, dead, the count to the restart), then his frame
gametick
        .if CAMTEST
        jmp camtest
        .endif
        lda dead
        beq +
        dec dead
        bne ++
        jmp restart
+       jsr read_keys
        jsr trogg_update
        jsr collide                 ; (and what he's touching)
+       jmp trogg_frame

; The level from the start again: Trogg, the Scrubblies, no balloons or daggers
restart lda #<TSTARTX
        sta tx
        lda #>TSTARTX
        sta tx+1
        lda #<TSTARTY
        sta ty
        lda #>TSTARTY
        sta ty+1
        lda #0
        sta tyf
        sta tstate
        sta tface
        sta tclimb
        sta xvel
        sta tv
        sta xmove
        sta ymove
        sta doyoyo
        sta dead
        sta anim
        lda #1                      ; (a key held through the restart does nothing till let go)
        sta ud_db
        sta lr_db
        sta jumping                 ; (and the camera back to the start)
        lda #0
        sta yo_len
        sta yo_len+1
        jsr unknock                 ; (the Scrubblies back)
        ldx #NB - 1
-       lda #0
        sta oact,x
        dex
        bpl -
        jmp trogg_frame

; ---- The keys (the BBC version's: Z / X walk, O / K climb and jump, P or Space the yoyo; and
; joystick 2), with its debouncing: after landing or climbing off, up and down do nothing till
; they're let go; after stepping onto a ladder from a fall, left and right
read_keys
        lda #$ff                    ; joystick 2 (port A's lines, with no keyboard column chosen):
        sta $dc00                   ; bits 0 up, 1 down, 2 left, 3 right, 4 fire, set when pushed
        lda $dc00
        eor #$ff
        and #$1f
        sta joy
        lda #%11111101              ; and the keys into the same bits: Z (column 1, row 4) left
        sta $dc00
        lda $dc01
        and #%00010000
        bne +
        lda #4
        ora joy
        sta joy
+       lda #%11111011              ; X (column 2, row 7) right
        sta $dc00
        lda $dc01
        bmi +
        lda #8
        ora joy
        sta joy
+       lda #%11101111              ; O (column 4, row 6) up, K (row 5) down
        sta $dc00
        lda $dc01
        tax
        and #%01000000
        bne +
        lda #1
        ora joy
        sta joy
+       txa
        and #%00100000
        bne +
        lda #2
        ora joy
        sta joy
+       lda #%11011111              ; P (column 5, row 1) the yoyo
        sta $dc00
        lda $dc01
        and #%00000010
        bne +
        lda #16
        ora joy
        sta joy
+       lda #%01111111              ; Space (column 7, row 4) the yoyo
        sta $dc00
        lda $dc01
        and #%00010000
        bne +
        lda #16
        ora joy
        sta joy
+       lda joy                     ; (each key: 0 or 1)
        lsr a
        rol k_up
        lsr a
        rol k_down
        lsr a
        rol k_left
        lsr a
        rol k_right
        lsr a
        rol k_yoyo
        lda #1
        and k_up
        sta k_up
        lda #1
        and k_down
        sta k_down
        lda #1
        and k_left
        sta k_left
        lda #1
        and k_right
        sta k_right
        lda #1
        and k_yoyo
        sta k_yoyo
        lda #$ff
        sta $dc00
        .if KEYTEST
        jsr keytest                 ; (a test: the keys from a script)
        .endif
        ; doyoyo, with debounce: after the yoyo comes back, the key must be released
        lda yo_db
        beq _yo_live
        lda #0
        sta doyoyo
        lda k_yoyo
        bne _yo_done
        sta yo_db
        beq _yo_done
_yo_live
        lda k_yoyo
        sta doyoyo
_yo_done
        ; ymove (+1 = up), with debounce after landing or climbing
        lda ud_db
        beq _ud_live
        lda #0
        sta ymove
        lda k_up
        ora k_down
        bne _ud_done
        sta ud_db
        beq _ud_done
_ud_live
        lda k_up
        sec
        sbc k_down
        sta ymove
_ud_done
        lda lr_db
        beq _lr_live
        lda #0
        sta xmove
        lda k_left
        ora k_right
        bne _lr_done
        sta lr_db
        beq _lr_done
_lr_live
        lda k_right
        sec
        sbc k_left
        sta xmove
_lr_done
        rts

; ---- Trogg's movement for a tick
trogg_update
        lda tstate
        pha
        jsr trogg_move
        pla
        ; GameMaker puts him on whole pixels when he lands from a fall: rounded up onto a
        ; platform, rounded (halves to even) onto a ladder
        cmp #ST_FALL
        bne _moved
        ldx tyf
        beq _moved
        lda tstate
        cmp #ST_STAND
        beq _inc_y
        cmp #ST_CLIMB
        bne _moved
        cpx #10
        bcc _whole
        bne _inc_y
        lda ty                      ; (a half: to the even pixel)
        lsr a
        bcc _whole
_inc_y  inc ty
        bne _whole
        inc ty+1
_whole  lda #0
        sta tyf
_moved  rts

trogg_move
        lda tstate
        cmp #ST_FALL
        bne +
        jmp trogg_falling
+       cmp #ST_CLIMB
        bne +
        jmp trogg_climbing
+       cmp #ST_YOYO_OUT
        bne +
        jmp yoyo_out
+       cmp #ST_YOYO_BACK
        bne trogg_standing
        jmp yoyo_back

trogg_standing
        ; nx = tx + xmove; PlatformFind(nx, y, y + 1)
        lda xmove
        jsr add_x_signed
        jsr q1_is_y
        lda #20
        jsr q2_is_y_plus
        jsr platform_find_f
        ; on it only if exactly at its top (between pixels above it, he drops onto it)
        lda res_found
        beq _off
        lda tyf
        beq _on_platform
_off    jsr move_to_qx
        lda xmove
        sta xvel
        lda #0
        ldx ymove
        beq _start_fall
        bmi _start_fall
        lda #JUMP_SPEED
_start_fall
        sta tv
        ; (no up/down debounce: the Steam version's TroggStanding asks for one, but its caller
        ; ignores it, so holding up through a jump catches a ladder on the way)
        lda #ST_FALL
        sta tstate
        rts
_on_platform
        lda ymove
        beq _walk
        ; try a ladder: LadderFind(nx, y, y - ymove, onplat, jumping)
        jsr q1_is_y
        lda #256 - 20
        ldx ymove
        bpl +
        lda #20
+       jsr q2_is_y_plus
        lda #1
        sta q_onplat
        sta q_jump
        jsr ladder_find
        lda res_found
        beq _no_ladder
        jsr move_to_res
        jmp start_climbing
_no_ladder
        lda ymove
        bmi _walk
        ; jump
        jsr move_to_qx
        lda xmove
        sta xvel
        lda #JUMP_SPEED
        sta tv
        lda #ST_FALL
        sta tstate
        rts
_walk   jsr move_to_qx
        lda doyoyo
        beq +
        jmp start_yoyo
+       lda xmove
        beq _stand
        bmi _face_left
        lda #0
        sta tface
        beq _walking
_face_left
        lda #1
        sta tface
_walking
        lda #ST_WALK
        sta tstate
        jmp animate
_stand  lda #ST_STAND
        sta tstate
        rts

; q_x = tx + a (signed)
add_x_signed
        tay
        clc
        adc tx
        sta q_x
        tya
        bmi +
        lda tx+1
        adc #0
        sta q_x+1
        rts
+       lda tx+1
        adc #$ff
        sta q_x+1
        rts

move_to_qx
        lda q_x
        sta tx
        lda q_x+1
        sta tx+1
        rts

animate lda anim                    ; (about 7 frames a second, as in GameMaker)
        clc
        adc #30
        sta anim
        rts

trogg_falling
        ; x += xvel, kept in [12, LEVEL_W - 10]
        lda xvel
        jsr add_x_signed
        jsr move_to_qx
        lda tx
        cmp #12
        lda tx+1
        sbc #0
        bcs +
        lda #12
        sta tx
        lda #0
        sta tx+1
+       lda tx
        cmp #<X_MAX
        lda tx+1
        sbc #>X_MAX
        bcc +
        lda #<X_MAX
        sta tx
        lda #>X_MAX
        sta tx+1
+       lda tx
        sta q_x
        lda tx+1
        sta q_x+1
        ; gravity, down to terminal velocity
        lda tv
        sta tv_prev
        cmp #256 - TERMINAL_SPEED
        beq +
        dec tv
+
        ; grab a ladder? (up or down held, and not falling faster than 1.275 pixels a tick)
        lda ymove
        beq _no_grab
        lda tv
        clc
        adc #25
        bmi _no_grab
        ; LadderFind(x, y, y - yvel, false, true)
        jsr q1_is_y
        lda #0
        sec
        sbc tv
        jsr q2_is_y_plus
        lda #0
        sta q_onplat
        lda #1
        sta q_jump
        jsr ladder_find
        lda res_found
        beq _no_grab
        jsr move_to_res
        lda #0
        sta xvel
        sta tv
        lda #1
        sta lr_db
        jmp start_climbing
_no_grab
        ; y2 = y - yvel
        lda #0
        sec
        sbc tv
        jsr q2_is_y_plus
        lda tv
        bmi _falling
        jmp _to_y2                  ; (rising: nothing in the way)
_falling
        ; land on a platform between y and y2? PlatformFind(x, y, y2)
        lda q_y2
        sta fy2
        lda q_y2+1
        sta fy2+1
        lda q_y2f
        sta fy2f
        jsr q1_is_y
        jsr platform_find_f
        lda res_found
        bne _land
        lda fy2
        sta q_y2
        lda fy2+1
        sta q_y2+1
        lda fy2f
        sta q_y2f
_to_y2  lda q_y2
        sta ty
        lda q_y2+1
        sta ty+1
        lda q_y2f
        sta tyf
        jmp _bottom
_land   ; (he stays where he is: if that's between pixels above it, he drops onto it next)
        lda tv                      ; (landing at 1.6 pixels a tick or faster kills him)
        clc
        adc #32
        sta ptmp
        lda #0
        sta xvel
        sta tv
        lda #1
        sta ud_db
        lda #ST_STAND
        sta tstate
        lda ptmp
        beq _dies
        bpl _bottom
_dies   jsr trogg_dies
_bottom ; off the bottom of the level?
        lda ty
        cmp #<LEVEL_H
        lda ty+1
        sbc #>LEVEL_H
        bcc +
        lda #0
        sta xvel
        sta tyf
        lda #<(LEVEL_H - 1)
        sta ty
        lda #>(LEVEL_H - 1)
        sta ty+1
        jmp trogg_dies
+       rts

trogg_dies
        .if INVINCIBLE
        rts
        .endif
        lda dead
        bne +
        lda #50                     ; (the level restarts in a second: 50 ticks)
        sta dead
+       rts

; Enter the climbing state, its direction from ymove (tclimb 0 still, 1 up, 2 down)
start_climbing
        lda #ST_CLIMB
        sta tstate
        lda ymove
        beq _still
        bmi _down
        lda #1
        sta tclimb
        rts
_down   lda #2
        sta tclimb
        rts
_still  lda #0
        sta tclimb
        rts

; Start falling at y velocity a (twentieths of a pixel a tick), x velocity xvel
climb_to_fall
        sta tv
        lda #ST_FALL
        sta tstate
        lda xvel
        bmi +
        lda #0
        sta tface
        rts
+       lda #1
        sta tface
        rts

trogg_climbing
        lda #0
        sta xvel
        sta tv
        sta q_onplat
        sta q_jump
        lda tx
        sta q_x
        lda tx+1
        sta q_x+1
        lda ymove
        bne +
        jmp _still
+       bpl _up
        jmp _down
_up     ; LadderFind(x, y, y - 1)
        jsr q1_is_y
        lda #256 - 20
        jsr q2_is_y_plus
        jsr ladder_find
        jsr ladder_moved
        bcc _up_no
        jsr move_y_to_res
        jsr maybe_step_off
        bcc _climbing
        rts
_up_no  ; at the top: step off onto a platform if there is one, PlatformFind(x, y - 1, y + 2)
        jsr q1_is_y
        lda q_y1
        bne +
        dec q_y1+1
+       dec q_y1
        lda #40
        jsr q2_is_y_plus
        jsr platform_find_f
        lda #1
        sta ud_db
        lda res_found
        beq _climbing
        lda ty
        bne +
        dec ty+1
+       dec ty
        lda #0
        jmp climb_to_fall
_still  ; LadderFind(x, y, y + 2)
        jsr q1_is_y
        lda #40
        jsr q2_is_y_plus
        jsr ladder_find
        jsr ladder_moved
        bcc _still_no
        jsr maybe_step_off
        bcc _climbing
        rts
_still_no
        lda xmove
        beq _climbing
        sta xvel
        lda #0
        jmp climb_to_fall
_climbing
        jsr start_climbing
        lda tclimb
        beq +
        jmp animate
+       rts
_down   ; climbing down onto a platform? PlatformFind(x, y, y + 1)
        jsr q1_is_y
        lda #20
        jsr q2_is_y_plus
        jsr platform_find_f
        lda res_found
        beq _down_ladder
        lda #1
        sta ud_db
        lda #ST_STAND
        sta tstate
        lda #0
        sta tface
        rts
_down_ladder
        ; LadderFind(x, y, y + 1)
        jsr q1_is_y
        lda #20
        jsr q2_is_y_plus
        jsr ladder_find
        jsr ladder_moved
        bcc _down_no
        jsr move_y_to_res
        jsr maybe_step_off
        bcc _climbing
        rts
_down_no
        ; off the bottom of the ladder: y + 1, falling at a pixel a tick
        lda #0
        sta xvel
        inc ty
        bne +
        inc ty+1
+       lda #1
        sta ud_db
        lda #256 - 20
        jmp climb_to_fall

; After ladder_find: carry set if a ladder was found and its y isn't Trogg's. Also moves tx to
; res_x when found.
ladder_moved
        lda res_found
        beq _no
        lda res_y
        cmp ty
        bne _yes
        lda res_y+1
        cmp ty+1
        bne _yes
        lda res_yf
        cmp tyf
        beq _no
_yes    lda res_x
        sta tx
        lda res_x+1
        sta tx+1
        sec
        rts
_no     clc
        rts

; Moving sideways at or below the ladder's visible top lets Trogg step off it. Carry set if he
; did (and is now falling).
maybe_step_off
        lda xmove
        beq _no
        ldx res_i
        lda lad_yl,x
        clc
        adc lad_ext,x
        sta ptmp
        lda lad_yh,x
        adc #0
        sta ptmp+1
        lda ty
        cmp ptmp
        lda ty+1
        sbc ptmp+1
        bcc _no
        lda xmove
        sta xvel
        lda #0
        jsr climb_to_fall
        sec
        rts
_no     clc
        rts

; ---- Platforms and ladders (ports of PlatformFind and LadderFind)

; The highest platform top in [q_y1, q_y2) under column q_x (if two are at the same height, the
; first, as PlatformFind): res_found = 1, res_y its y and res_i which. Only the platforms over
; q_x's 8-pixel column are looked at (pcol, plist: the last first, as the BBC version goes)
platform_find
        lda #0
        sta res_found
        jsr xcolumn
        bcc +
        rts
+       lda pcol,y
        sta pbeg
        lda pcol+1,y
        tay
_loop   cpy pbeg
        bne +
        rts
+       dey
        ldx plist,y
        ; y1 <= py ?
        lda plat_yl,x
        cmp q_y1
        lda plat_yh,x
        sbc q_y1+1
        bcc _next
        ; py < y2 ?
        lda plat_yl,x
        cmp q_y2
        lda plat_yh,x
        sbc q_y2+1
        bcs _next
        ; px <= x ?
        lda q_x
        cmp plat_xl,x
        lda q_x+1
        sbc plat_xh,x
        bcc _next
        ; x < px + w ?
        lda plat_xl,x
        clc
        adc plat_w,x
        sta ptmp
        lda plat_xh,x
        adc #0
        sta ptmp+1
        lda q_x
        cmp ptmp
        lda q_x+1
        sbc ptmp+1
        bcs _next
        ; the highest (smallest y), and of those the first (going down the list)
        lda res_found
        beq _take
        lda plat_yl,x
        cmp res_y
        lda plat_yh,x
        sbc res_y+1
        bcc _take
        lda plat_yl,x
        cmp res_y
        bne _next
        lda plat_yh,x
        cmp res_y+1
        bne _next
_take   lda #1
        sta res_found
        lda plat_yl,x
        sta res_y
        lda plat_yh,x
        sta res_y+1
        stx res_i
_next   jmp _loop

; y = q_x's 8-pixel column, c clear (c set if it's off the level)
xcolumn lda q_x+1
        cmp #3
        bcs +
        asl a                       ; (x / 8: its high byte's 2 bits, then the low byte's top 5)
        asl a
        asl a
        asl a
        asl a
        sta pcx
        lda q_x
        lsr a
        lsr a
        lsr a
        ora pcx
        cmp #PCOLN
        tay
+       rts

; PlatformFind(x, y1, y2) with y1 and y2 in pixels and twentieths ((q_y1, q_y1f) and (q_y2,
; q_y2f)): the platforms at ceil(y1) <= y < y2 are those at whole pixels in [ceil(y1), ceil(y2)).
; (q_y1 and q_y2 become those.)
platform_find_f
        lda q_y1f
        beq +
        inc q_y1
        bne +
        inc q_y1+1
+       lda q_y2f
        beq +
        inc q_y2
        bne +
        inc q_y2+1
+       jmp platform_find

; (q_y1, q_y1f) = Trogg's y
q1_is_y lda ty
        sta q_y1
        lda ty+1
        sta q_y1+1
        lda tyf
        sta q_y1f
        rts

; (q_y2, q_y2f) = Trogg's y + a twentieths (signed)
q2_is_y_plus
        ldx ty
        stx q_y2
        ldx ty+1
        stx q_y2+1
        clc
        adc tyf
_neg    cmp #$80
        bcc _pos                    ; (below 0: a pixel less)
        adc #20 - 1                 ; (carry set: + 20)
        ldx q_y2
        bne +
        dec q_y2+1
+       dec q_y2
        jmp _neg
_pos    cmp #20
        bcc _done                   ; (20 or more: a pixel more)
        sbc #20
        inc q_y2
        bne _pos
        inc q_y2+1
        jmp _pos
_done   sta q_y2f
        rts

; Trogg's position = res_x, (res_y, res_yf)
move_to_res
        lda res_x
        sta tx
        lda res_x+1
        sta tx+1
move_y_to_res
        lda res_y
        sta ty
        lda res_y+1
        sta ty+1
        lda res_yf
        sta tyf
        rts

; Can Trogg at (q_x, y1) move along a ladder towards y2? (LadderFind, with y1 and y2 in pixels and
; twentieths: (q_y1, q_y1f) and (q_y2, q_y2f).) q_onplat and q_jump as its isOnPlatform and
; isJumping. Returns res_found, res_x, (res_y, res_yf) and res_i (which).
ladder_find
        lda #0
        sta res_found
        lda q_x
        sta res_x
        lda q_x+1
        sta res_x+1
        lda q_y1
        sta res_y
        lda q_y1+1
        sta res_y+1
        lda q_y1f
        sta res_yf
        ; going up (y2 < y1) or down? Nothing if they're the same
        lda #0
        sta lf_up
        lda q_y2
        cmp q_y1
        lda q_y2+1
        sbc q_y1+1
        bcc _is_up
        lda q_y2
        cmp q_y1
        bne _start
        lda q_y2+1
        cmp q_y1+1
        bne _start
        lda q_y2f
        cmp q_y1f
        bcc _is_up
        bne _start
        rts
_is_up  inc lf_up
_start  jsr xcolumn             ; (the ladders near q_x's 8-pixel column: lcol, llist)
        bcc +
        rts
+       lda lcol+1,y
        sta pend
        lda lcol,y
        tay
_loop   cpy pend
        bne _check
        rts
_check  ldx llist,y
        iny
        ; only ladders within 6 pixels of q_x
        lda q_x
        sec
        sbc lad_xl,x
        sta ptmp
        lda q_x+1
        sbc lad_xh,x
        beq _pos
        cmp #$ff
        bne _next
        lda ptmp
        cmp #$fa
        bcc _next
        bcs _near
_pos    lda ptmp
        cmp #7
        bcs _next
_near   lda lad_yl,x
        sta lad_top
        lda lad_yh,x
        sta lad_top+1
        lda lad_hl,x
        sta lad_len
        lda lad_hh,x
        sta lad_len+1
        lda lf_up
        bne _going_up
        jmp _going_down
_next   jmp _loop
_going_up
        ; (jumping: not the invisible part above the top)
        lda q_jump
        beq _up1
        lda lad_top
        clc
        adc lad_ext,x
        sta lad_top
        bcc +
        inc lad_top+1
+       lda lad_len
        sec
        sbc lad_ext,x
        sta lad_len
        bcs _up1
        dec lad_len+1
_up1    lda q_onplat
        beq _up2
        ; skip if lad_top > y1
        lda q_y1
        cmp lad_top
        lda q_y1+1
        sbc lad_top+1
        bcc _next
_up2    ; need res_y >= lad_top and y2 < lad_top + lad_len (whole-pixel tops: the twentieths
        ; don't matter)
        lda res_y
        cmp lad_top
        lda res_y+1
        sbc lad_top+1
        bcc _next
        lda lad_top
        clc
        adc lad_len
        sta ptmp
        lda lad_top+1
        adc lad_len+1
        sta ptmp+1
        lda q_y2
        cmp ptmp
        lda q_y2+1
        sbc ptmp+1
        bcs _next
        jsr _found_x
        ; res_y = max(y2, lad_top), and stop if that's y2
        lda q_y2
        cmp lad_top
        lda q_y2+1
        sbc lad_top+1
        bcs _use_y2
        lda lad_top
        sta res_y
        lda lad_top+1
        sta res_y+1
        lda #0
        sta res_yf
        jmp _next
_use_y2 lda q_y2
        sta res_y
        lda q_y2+1
        sta res_y+1
        lda q_y2f
        sta res_yf
        rts
_next_d jmp _next
_going_down
        lda q_onplat
        beq _dn1
        ; skip if lad_top < y1
        lda lad_top
        cmp q_y1
        lda lad_top+1
        sbc q_y1+1
        bcc _next_d
        lda lad_top
        cmp q_y1
        bne _dn1
        lda lad_top+1
        cmp q_y1+1
        bne _dn1
        lda q_y1f
        bne _next_d
_dn1    ; ptmp = lad_top + lad_len - 1 (the bottom)
        lda lad_top
        clc
        adc lad_len
        sta ptmp
        lda lad_top+1
        adc lad_len+1
        sta ptmp+1
        lda ptmp
        bne +
        dec ptmp+1
+       dec ptmp
        ; need res_y < bottom and y2 >= lad_top
        lda res_y
        cmp ptmp
        lda res_y+1
        sbc ptmp+1
        bcs _next_d
        lda q_y2
        cmp lad_top
        lda q_y2+1
        sbc lad_top+1
        bcc _next_d
        jsr _found_x
        ; res_y = min(y2, bottom), and stop if that's y2
        lda q_y2
        cmp ptmp
        lda q_y2+1
        sbc ptmp+1
        bcc _use_y2b
        lda q_y2
        cmp ptmp
        bne _bottom
        lda q_y2+1
        cmp ptmp+1
        bne _bottom
        lda q_y2f
        bne _bottom
_use_y2b
        jmp _use_y2
_bottom lda ptmp
        sta res_y
        lda ptmp+1
        sta res_y+1
        lda #0
        sta res_yf
        jmp _next_d
_found_x                            ; (res_x = x + sign(ladx - x))
        lda #1
        sta res_found
        stx res_i
        lda q_x
        sta res_x
        lda q_x+1
        sta res_x+1
        lda lad_xl,x
        cmp q_x
        lda lad_xh,x
        sbc q_x+1
        bcc _dec_x
        lda lad_xl,x
        cmp q_x
        bne _inc_x
        lda lad_xh,x
        cmp q_x+1
        beq _fx_done
_inc_x  inc res_x
        bne _fx_done
        inc res_x+1
        rts
_dec_x  lda res_x
        bne +
        dec res_x+1
+       dec res_x
_fx_done
        rts

; ---- His frame (tfr: trogg.inc's numbering), from his state, as the BBC version's trogg_image
trogg_frame
        lda tstate
        cmp #ST_WALK
        beq _walk
        cmp #ST_CLIMB
        beq _climb
        cmp #ST_YOYO_OUT
        bcc +
        lda tface                   ; (yoyoing: Trogg_yl, _yr)
        beq _yr
        lda #5
        .byte $2c
_yr     lda #6
        sta tfr
        rts
+        lda tface                   ; (standing, falling: the first walking frame)
        beq +
        lda #11                     ; (Trogg_wl_0)
        .byte $2c
+       lda #7                      ; (Trogg_wr_0)
        sta tfr
        rts
_walk   lda anim                    ; (its top two bits: frame 0-3)
        rol a
        rol a
        rol a
        and #3
        ldx tface
        beq +
        clc
        adc #11
        sta tfr
        rts
+       clc
        adc #7
        sta tfr
        rts
_climb  lda tclimb
        bne +
        lda #2                      ; (Trogg_cn)
        sta tfr
        rts
+       lda anim                    ; (its top bit: frame 0-1)
        asl a
        lda #0
        rol a
        ldx tclimb
        cpx #1
        beq +
        sta tfr                     ; (Trogg_cd_0, _1: 0, 1)
        rts
+       clc
        adc #3                      ; (Trogg_cu_0, _1: 3, 4)
        sta tfr
        rts

        .if KEYTEST
; (a test: the keys from a script, --keys in build.mjs: for so many ticks each, keys held (bits:
; 1 left, 2 right, 4 up, 8 down, 16 yoyo); then none)
        .include "keys.inc"         ; kscrn (ticks), kscrk (keys), KSCRN (steps)
keytest lda kstep
        cmp #KSCRN
        bcs _none
        tax
        lda kscrk,x
        ldx #0
-       lsr a
        pha
        lda #0
        rol a
        sta k_left,x
        pla
        inx
        cpx #5
        bne -
        inc kticks
        lda kticks
        ldx kstep
        cmp kscrn,x
        bcc +
        lda #0
        sta kticks
        inc kstep
+       rts
_none   lda #0
        ldx #4
-       sta k_left,x
        dex
        bpl -
        rts
kstep   .byte 0
kticks  .byte 0
        .endif

        .if CAMTEST
; (a test of the camera: Trogg walked across the level and back, a pixel a tick, turning round at
; each of camturn's x's in turn; the keys read and his movement worked out as well, for what they
; cost, but then left out)
camtest ldx #CAMSAVE - 1
-       lda tx,x
        sta camsv,x
        dex
        bpl -
        lda tstate
        sta camst
        jsr read_keys
        jsr trogg_update
        ldx #CAMSAVE - 1
-       lda camsv,x
        sta tx,x
        dex
        bpl -
        lda camst
        sta tstate
        ldx camti                   ; at the next turning point: turn round, and on to the next
        lda tx
        cmp camtl,x
        bne _cgo
        lda tx+1
        cmp camth,x
        bne _cgo
        lda camdir
        eor #$fe
        sta camdir
        inx
        cpx #CAMTN
        bcc _cnx
        ldx #0
_cnx    stx camti
_cgo    lda camdir                  ; a pixel on
        bmi _cleft
        inc tx
        bne _cw
        inc tx+1
        bne _cw
_cleft  lda tx
        bne _cdec
        dec tx+1
_cdec   dec tx
_cw     lda #ST_WALK
        sta tstate
        lda camdir
        lsr a
        and #1
        sta tface
        jsr animate
        jmp trogg_frame
CAMTURN = [400, 250, 700, 600, 650, 100, 300, 280, 320, 41]
CAMTN   = len(CAMTURN)
camtl   .byte <CAMTURN
camth   .byte >CAMTURN
camti   .byte 0
camdir  .byte 1
CAMSAVE = 4                         ; (tx, ty: saved)
camsv   .fill CAMSAVE
camst   .byte 0
        .endif

; ---- Data
tyf     .byte 0                     ; (his y's twentieths: tx, ty in trogg.asm)
tstate  .byte ST_STAND
tface   .byte 0                     ; (0 right, 1 left)
tclimb  .byte 0                     ; (0 still, 1 up, 2 down)
anim    .byte 0
xmove   .byte 0                     ; (the keys: -1, 0, 1)
ymove   .byte 0
doyoyo  .byte 0
xvel    .byte 0
tv      .byte 0
tv_prev .byte 0
dead    .byte 0                     ; (ticks to the restart)
ud_db   .byte 0                     ; (the debounces)
lr_db   .byte 0
yo_db   .byte 0
k_left  .byte 0
k_right .byte 0
k_up    .byte 0
k_down  .byte 0
k_yoyo  .byte 0
joy     .byte 0
ktmp    .byte 0
q_x     .word 0                     ; (the platform and ladder lookups')
q_y1    .word 0
q_y1f   .byte 0
q_y2    .word 0
q_y2f   .byte 0
q_onplat .byte 0
q_jump  .byte 0
res_found .byte 0
res_x   .word 0
res_y   .word 0
res_yf  .byte 0
res_i   .byte 0
lf_up   .byte 0
lad_top .word 0
lad_len .word 0
fy2     .word 0
fy2f    .byte 0
ptmp    .word 0
pbeg    .byte 0
pcx     .byte 0
pend    .byte 0
