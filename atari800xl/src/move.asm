; ---- Trogg's movement: the C64 port's (c64/src/play.asm: trogg_update to ladder_find, and
; trogg_frame), itself the BBC version's, a port of the original's TroggStanding, TroggFalling,
; TroggClimbing, PlatformFind and LadderFind. The same code on the same platforms and ladders
; (build/<level>_geom.inc, by tools/geom.py from the C64 build's geometry.json), in the same
; level coordinates: x in pixels (tx), y in pixels and twentieths of a pixel (gy, tyf: the C64's
; ty, 24 more than the Atari map's line), y velocity in twentieths a tick (tv, + up). Only the
; keys (the joystick here) and what's around it (gametick, restart) are the Atari's own. Fire
; throws the yoyo (yoyo.asm).
;
; Death (landing at 1.6 pixels a tick or faster, falling off the bottom, or touching a Scrubbly,
; balloon or dagger: collide) restarts him after a second, at the last checkpoint (a key picked up) or the start.

TX0     = STARTX ? STARTX : TSTARTX
TY0     = STARTX ? STARTY : TSTARTY
JUMP_SPEED = 25                     ; (twentieths of a pixel a tick; gravity is 1)
TERMINAL_SPEED = 80
ST_STAND = 0
ST_WALK  = 1
ST_FALL  = 2
ST_CLIMB = 3
ST_YOYO_OUT = 4
ST_YOYO_BACK = 5
Y0      = 24                        ; (the C64's y less the Atari map's line)

; ---- A game tick: the joystick, then Trogg (or, dead, the count to the restart), then his frame
gametick
        lda dead                    ; dead: everything still, then back to the checkpoint
        beq _alive
        dec dead
        bne _still
        jsr restart
        jmp _still
_alive  lda won                     ; the level complete (all the keys): everything still, then
        beq _play                   ; the level again from the start
        lda wint
        bne _wd
        dec wint+1
_wd     dec wint
        lda wint
        ora wint+1
        bne _still
        jsr newlevel
        jmp _still
_play
      .if FRONTEND
        lda SKSTAT                  ; Escape: back to the front end (the program from its start)
        and #4
        bne +
        lda KBCODE
        and #$3f
        cmp #$1c
        bne +
        sei
        jmp start
+
      .endif
        jsr read_keys
        jsr trogg_update
      .if !NOHAZ
        jsr hazards                 ; (the balloons and daggers: hazards.asm)
      .endif
        jsr collide                 ; (what he's touching: the Scrubblies, balloons, daggers, gems
                                    ; and keys)
        jsr checkcp                 ; (a checkpoint, if one's due)
_still  jsr trogg_frame
        ldx tfr                     ; (the C64's frame numbering to sprites.py's)
        lda c2a,x
        sta tf
        rts
c2a     .byte TF_CD0, TF_CD1, TF_CN, TF_CU0, TF_CU1, TF_YL, TF_YR, TF_WR0, TF_WR1, TF_WR2, TF_WR3
        .byte TF_WL0, TF_WL1, TF_WL2, TF_WL3

; The level from the start: no checkpoint, every gem and key back
newlevel
        lda #0
        sta havecp
        sta savecp
        sta restarts
        sta won

; Back to the last checkpoint (the state saved after a key, not the last), or with none the start
; (every gem and key back). His movement reset, no balloons or daggers, the camera on him.
restart lda havecp
        bne _cp
        lda #<TX0
        sta tx
        lda #>TX0
        sta tx+1
        lda #<TY0
        sta gy
        lda #>TY0
        sta gy+1
        lda #0
        sta tyf
        sta tface
        sta btim                    ; (a balloon and a dagger at once)
        sta dtim
        sta pgone0                  ; (the gems, keys and Scrubblies back, as of the start)
        sta pgone0+1
        sta pgone0+2
        beq _all
_cp     inc restarts
        lda cptx
        sta tx
        lda cptx+1
        sta tx+1
        lda cpty
        sta gy
        lda cpty+1
        sta gy+1
        lda cptyf
        sta tyf
        lda cpface
        sta tface
        lda cpbtim
        sta btim
        lda cpdtim
        sta dtim
        ldx #2                      ; (the gems, keys and Scrubblies gone as of the checkpoint)
-       lda cpgone,x
        sta pgone0,x
        dex
        bpl -
_all    jsr pkreset                 ; (the map to match: pick.asm)
        lda tx                      ; the camera on him: the scroll (colour clocks) (x - 160) / 2,
        sec                         ; kept to 0-XMAX
        sbc #160
        tay
        lda tx+1
        sbc #0
        bpl +
        lda #0
        tay
+       lsr a
        tya
        ror a
        cmp #XMAX
        bcc +
        lda #XMAX
+       sta nscrx
        lda #0
        sta tstate
        sta tclimb
        sta xvel
        sta tv
        sta xmove
        sta ymove
        sta doyoyo
        sta dead
        sta anim
        sta animf
        sta won
        sta yo_len                  ; (the yoyo in)
        sta yo_len+1
        lda #1                      ; (a stick held through the restart does nothing till let go)
        sta ud_db
        sta lr_db
        ldx #NHZ - 1                 ; (no balloons or daggers)
        lda #0
-       sta oact,x
        dex
        bpl -
        rts

; A checkpoint (the BBC version's): once one's due (a key picked up, not the last), when he's
; standing or walking and not dying: his place and what's gone
checkcp lda savecp
        beq _x
        lda dead
        bne _x
        lda tstate
        cmp #ST_WALK + 1
        bcs _x
        lda #0
        sta savecp
        lda #1
        sta havecp
        lda tx
        sta cptx
        lda tx+1
        sta cptx+1
        lda gy
        sta cpty
        lda gy+1
        sta cpty+1
        lda tyf
        sta cptyf
        lda tface
        sta cpface
        lda btim
        sta cpbtim
        lda dtim
        sta cpdtim
        ldx #2
-       lda pgone,x
        sta cpgone,x
        dex
        bpl -
_x      rts

; The joystick (port 1: PORTA's low 4 bits, 0 when pushed; the trigger TRIG0), with the C64's
; debouncing: after landing or climbing off, up and down do nothing till they're let go; after
; stepping onto a ladder from a fall, left and right
read_keys
        lda PORTA
        eor #15
        tax
        and #1
        sta k_up
        txa
        lsr a
        and #1
        sta k_down
        txa
        lsr a
        lsr a
        and #1
        sta k_left
        txa
        lsr a
        lsr a
        lsr a
        and #1
        sta k_right
        lda TRIG0
        eor #1
        and #1
        sta k_yoyo
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
        lda gy                      ; (a half: to the even pixel)
        lsr a
        bcc _whole
_inc_y  inc gy
        bne _whole
        inc gy+1
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

animate lda animf                   ; (7 frames a second at GameMaker's 60 ticks: 7 x 64 / 60 =
        clc                         ; 7.465 a tick, 7 + 119 / 256; a frame each 64. The BBC
        adc #119                    ; version's 30 a tick was 4 times that)
        sta animf
        lda anim
        adc #7
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
        cmp lv_xmax
        lda tx+1
        sbc lv_xmax+1
        bcc +
        lda lv_xmax
        sta tx
        lda lv_xmax+1
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
        sta gy
        lda q_y2+1
        sta gy+1
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
        lda gy
        cmp lv_levh
        lda gy+1
        sbc lv_levh+1
        bcc +
        lda #0
        sta xvel
        sta tyf
        lda lv_levh1
        sta gy
        lda lv_levh1+1
        sta gy+1
        jmp trogg_dies
+       rts

trogg_dies
      .if INVINCIBLE
        rts
      .endif
        lda won                     ; (nothing kills him once he's won: the last key and a balloon
        bne +                       ; in the same tick win, as in GameMaker)
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
        lda gy
        bne +
        dec gy+1
+       dec gy
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
        inc gy
        bne +
        inc gy+1
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
        cmp gy
        bne _yes
        lda res_y+1
        cmp gy+1
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
        lda gy
        cmp ptmp
        lda gy+1
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
        cmp lv_pcoln
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
q1_is_y lda gy
        sta q_y1
        lda gy+1
        sta q_y1+1
        lda tyf
        sta q_y1f
        rts

; (q_y2, q_y2f) = Trogg's y + a twentieths (signed)
q2_is_y_plus
        ldx gy
        stx q_y2
        ldx gy+1
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
        sta gy
        lda res_y+1
        sta gy+1
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
+       lda anim                    ; (its bit 6: frame 0-1, at the walk's rate, 7 a second as in
        asl a                       ; GameMaker)
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


; The level complete (the last key): a pause of 7 seconds (less one for each restart from a
; checkpoint, to 4), then the level from the start
level_complete
        lda #1
        sta won
        lda #0
        sta dead
        ldy restarts
        cpy #3
        bcc +
        ldy #3
+       lda winlo,y
        sta wint
        lda winhi,y
        sta wint+1
        rts
winlo   .byte <(7 * 50), <(6 * 50), <(5 * 50), <(4 * 50)
winhi   .byte >(7 * 50), >(6 * 50), >(5 * 50), >(4 * 50)

; ---- Data
tyf     .byte 0                     ; (his y's twentieths: tx, gy in trogg.asm)
tstate  .byte ST_STAND
tface   .byte 0                     ; (0 right, 1 left)
tclimb  .byte 0                     ; (0 still, 1 up, 2 down)
anim    .byte 0
animf   .byte 0                     ; (its fraction)
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
k_esc   .byte 0                     ; (Escape: just pressed)
kescn   .byte 0
kesch   .byte 0
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
gy      .word 0                     ; (his y: the C64's gy, level lines + 24)
tfr     .byte 0                     ; (his frame, the C64's numbering)
won     .byte 0
wint    .word 0
havecp  .byte 0                     ; (a checkpoint saved)
savecp  .byte 0                     ; (one due: a key picked up)
restarts .byte 0
cptx    .word 0
cpty    .word 0
cptyf   .byte 0
cpface  .byte 0
cpbtim  .byte 0
cpdtim  .byte 0
cpgone  .fill 3
