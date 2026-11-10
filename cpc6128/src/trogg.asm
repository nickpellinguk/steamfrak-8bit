; Trogg's movement: a port of the BBC version's trogg_standing, trogg_falling and
; trogg_climbing (themselves ports of GameMaker's TroggStanding, TroggFalling and
; TroggClimbing), with ladder_find (LadderFind) and the platform_find of
; level.asm (PlatformFind).
;
; Trogg's y is kept in pixels (ty) and twentieths of a pixel (tyf), and his y
; velocity (tv, up is positive) in twentieths of a pixel a tick: everything the
; original's y and velocity can be (gravity 0.05, a jump 1.25, and y rounded to
; multiples of 0.05), as whole numbers. Comparisons are unsigned where the BBC
; version's are, so that the two move him the same.

JUMP_SPEED = 25                     ; twentieths of a pixel a tick (gravity is 1)
TERMINAL_SPEED = 80

; q_x = tx + A (A signed)
add_x_signed
        ld e,a : add a,a : sbc a,a : ld d,a
        ld hl,(tx) : add hl,de : ld (q_x),hl
        ret

; (q_y1, q_y1f) = Trogg's y
q1_is_y ld hl,(ty) : ld (q_y1),hl
        ld a,(tyf) : ld (q_y1f),a
        ret

; (q_y2, q_y2f) = Trogg's y + A twentieths (A signed)
q2_is_y_plus
        ld hl,(ty)
        ld b,a : ld a,(tyf) : add a,b
.neg    bit 7,a : jr z,.pos                 ; (below 0: a pixel less)
        add a,20 : dec hl : jr .neg
.pos    cp 20 : jr c,.done                  ; (20 or more: a pixel more)
        sub 20 : inc hl : jr .pos
.done   ld (q_y2),hl : ld (q_y2f),a
        ret

; PlatformFind(x, y1, y2) with y1 and y2 in pixels and twentieths: the platforms
; at ceil(y1) <= y < y2 are those at whole pixels in [ceil(y1), ceil(y2)). (q_y1
; and q_y2 become those.)
platform_find_f
        ld a,(q_y1f) : or a : jr z,.y1
        ld hl,(q_y1) : inc hl : ld (q_y1),hl
.y1     ld a,(q_y2f) : or a : jp z,platform_find
        ld hl,(q_y2) : inc hl : ld (q_y2),hl
        jp platform_find

; Trogg's position = res_x, (res_y, res_yf); or his x = q_x
move_to_res
        ld hl,(res_x) : ld (tx),hl
move_y_to_res
        ld hl,(res_y) : ld (ty),hl
        ld a,(res_yf) : ld (tyf),a
        ret
move_to_qx
        ld hl,(q_x) : ld (tx),hl
        ret

animate ld a,(anim) : add a,30 : ld (anim),a    ; ~7 frames a second, as in GameMaker
        ret

; Can Trogg at (q_x, y1) move along a ladder towards y2? (LadderFind, with y1 and
; y2 in pixels and twentieths: (q_y1, q_y1f) and (q_y2, q_y2f).) q_onplat and
; q_jump as its isOnPlatform and isJumping. Returns res_found, res_x, (res_y,
; res_yf) and res_i (which). IX lost.
ladder_find
        xor a : ld (res_found),a : ld (lf_up),a : ld (lf_i),a
        ld hl,(q_x) : ld (res_x),hl
        ld hl,(q_y1) : ld (res_y),hl : ld a,(q_y1f) : ld (res_yf),a
        ; going up (y2 < y1) or down? Nothing if they're the same
        ld hl,(q_y2) : ld de,(q_y1) : or a : sbc hl,de
        jr c,.is_up : jr nz,.loop
        ld a,(q_y1f) : ld b,a : ld a,(q_y2f) : cp b
        ret z : jr nc,.loop
.is_up  ld a,1 : ld (lf_up),a
.loop   ld a,(num_ladders) : ld b,a : ld a,(lf_i) : cp b : ret z
        call lad_ix
        ; only ladders within 6 pixels of q_x
        ld hl,(q_x) : ld e,(ix+L_XL) : ld d,(ix+L_XH) : or a : sbc hl,de
        ld a,h : or a : jr z,.pos
        inc a : jp nz,.next
        ld a,l : cp #FA : jp c,.next
        jr .near
.pos    ld a,l : cp 7 : jp nc,.next
.near   ld l,(ix+L_YL) : ld h,(ix+L_YH) : ld (lad_top),hl
        ld l,(ix+L_HL) : ld h,(ix+L_HH) : ld (lad_len),hl
        ld a,(lf_up) : or a : jr z,.going_down
        ; going up (jumping: not the invisible part above the top)
        ld a,(q_jump) : or a : jr z,.up1
        ld e,(ix+L_EXT) : ld d,0
        ld hl,(lad_top) : add hl,de : ld (lad_top),hl
        ld hl,(lad_len) : or a : sbc hl,de : ld (lad_len),hl
.up1    ld a,(q_onplat) : or a : jr z,.up2
        ld hl,(q_y1) : ld de,(lad_top) : or a : sbc hl,de : jp c,.next   ; (lad_top > y1)
.up2    ; need res_y >= lad_top and y2 < lad_top + lad_len (whole-pixel tops: the
        ; twentieths don't matter)
        ld hl,(res_y) : ld de,(lad_top) : or a : sbc hl,de : jp c,.next
        ld hl,(lad_top) : ld de,(lad_len) : add hl,de : ex de,hl
        ld hl,(q_y2) : or a : sbc hl,de : jp nc,.next
        call lf_found_x
        ; res_y = max(y2, lad_top), and stop if that's y2
        ld hl,(q_y2) : ld de,(lad_top) : or a : sbc hl,de : jr nc,.use_y2
        ld (res_y),de : xor a : ld (res_yf),a
.next   ld hl,lf_i : inc (hl)
        jp .loop
.use_y2 ld hl,(q_y2) : ld (res_y),hl
        ld a,(q_y2f) : ld (res_yf),a
        ret

.going_down
        ld a,(q_onplat) : or a : jr z,.dn1
        ; skip if lad_top < y1 (with its twentieths)
        ld hl,(lad_top) : ld de,(q_y1) : or a : sbc hl,de : jp c,.next : jr nz,.dn1
        ld a,(q_y1f) : or a : jp nz,.next
.dn1    ; lf_bot = lad_top + lad_len - 1; need res_y < lf_bot and y2 >= lad_top
        ld hl,(lad_top) : ld de,(lad_len) : add hl,de : dec hl : ld (lf_bot),hl
        ex de,hl : ld hl,(res_y) : or a : sbc hl,de : jp nc,.next
        ld hl,(q_y2) : ld de,(lad_top) : or a : sbc hl,de : jp c,.next
        call lf_found_x
        ; res_y = min(y2, lf_bot), and stop if that's y2
        ld hl,(q_y2) : ld de,(lf_bot) : or a : sbc hl,de : jr c,.use_y2 : jr nz,.bottom
        ld a,(q_y2f) : or a : jr z,.use_y2
.bottom ld (res_y),de : xor a : ld (res_yf),a
        jp .next

; ladder_find has found ladder lf_i (IX): res_found, res_i, and res_x = x +
; sign(its x - x)
lf_found_x
        ld a,1 : ld (res_found),a
        ld a,(lf_i) : ld (res_i),a
        ld e,(ix+L_XL) : ld d,(ix+L_XH)
        ld hl,(q_x) : or a : sbc hl,de
        ld hl,(q_x) : jr z,.done : jr c,.inc
        dec hl : jr .done
.inc    inc hl
.done   ld (res_x),hl
        ret

; ------------------------------------------------------------------------------
; Standing or walking
; ------------------------------------------------------------------------------
trogg_standing
        ; nx = tx + xmove; PlatformFind(nx, y, y + 1)
        ld a,(xmove) : call add_x_signed
        call q1_is_y : ld a,20 : call q2_is_y_plus
        call platform_find_f
        ld a,(res_i) : ld (plat_hit),a
        ; on it only if exactly at its top (between pixels above it, he drops onto it)
        ld a,(res_found) : or a : jr z,.off
        ld a,(tyf) : or a : jr z,.on_platform
.off    call move_to_qx
        ld a,(xmove) : ld (xvel),a
        ld b,0 : ld a,(ymove) : or a : jr z,.fall : jp m,.fall
        ld b,JUMP_SPEED
.fall   ld a,b : ld (tv),a
        ; (no up/down debounce: the Steam version's TroggStanding asks for one, but its
        ; caller ignores it, so holding up through a jump catches a ladder on the way)
        ld a,ST_FALL : ld (tstate),a
        ret

.on_platform
        ld a,(ymove) : or a : jr z,.walk
        ; Try a ladder: LadderFind(nx, y, y - ymove, onplat, jumping)
        call q1_is_y
        ld a,(ymove) : or a : ld a,256 - 20 : jp p,.updown
        ld a,20
.updown call q2_is_y_plus
        ld a,1 : ld (q_onplat),a : ld (q_jump),a
        call ladder_find
        ld a,(res_found) : or a : jr z,.no_ladder
        call move_to_res
        jp start_climbing
.no_ladder
        ld a,(ymove) : or a : jp m,.walk
        ; Jump
        call move_to_qx
        ld a,(xmove) : ld (xvel),a
        ld a,JUMP_SPEED : ld (tv),a
        ld a,ST_FALL : ld (tstate),a
        ret

.walk   ld a,(plat_hit) : ld (cur_plat),a
        call move_to_qx
        ld a,(doyoyo) : or a : jp nz,start_yoyo
        ld a,(xmove) : or a : jr z,.stand
        rlca : and 1 : ld (tface),a             ; (0 facing right, 1 left)
        ld a,ST_WALK : ld (tstate),a
        jp animate
.stand  ld a,ST_STAND : ld (tstate),a
        ret

; ------------------------------------------------------------------------------
; Falling (or jumping)
; ------------------------------------------------------------------------------
trogg_falling
        ; x += xvel, kept in [12, x_max]
        ld a,(xvel) : call add_x_signed
        ld de,12 : or a : sbc hl,de : jr nc,.x1
        ld hl,12 : ld (q_x),hl
.x1     ld hl,(q_x) : ld de,(x_max) : or a : sbc hl,de : jr c,.x2
        ld (q_x),de
.x2     ld hl,(q_x) : ld (tx),hl

        ; gravity, down to terminal velocity
        ld a,(tv) : ld (tv_prev),a
        cp 256 - TERMINAL_SPEED : jr z,.no_gravity
        dec a : ld (tv),a
.no_gravity

        ; Grab a ladder? (up or down held, and not falling faster than 1.275 pixels a tick)
        ld a,(ymove) : or a : jr z,.no_grab
        ld a,(tv) : add a,25 : jp m,.no_grab
        ; LadderFind(x, y, y - yvel, false, true)
        call q1_is_y
        ld a,(tv) : neg : call q2_is_y_plus
        xor a : ld (q_onplat),a : inc a : ld (q_jump),a
        call ladder_find
        ld a,(res_found) : or a : jr z,.no_grab
        call move_to_res
        xor a : ld (xvel),a : ld (tv),a
        inc a : ld (lr_db),a
        jp start_climbing
.no_grab

        ; y2 = y - yvel
        ld a,(tv) : neg : call q2_is_y_plus
        ld a,(tv) : or a : jp p,.to_y2          ; (rising: nothing in the way)
        ; land on a platform between y and y2? PlatformFind(x, y, y2)
        ld hl,(q_y2) : ld (fy2),hl : ld a,(q_y2f) : ld (fy2f),a
        call q1_is_y
        call platform_find_f
        ld a,(res_found) : or a : jr nz,.hit
        ld hl,(fy2) : ld (q_y2),hl : ld a,(fy2f) : ld (q_y2f),a
.to_y2  ld hl,(q_y2) : ld (ty),hl : ld a,(q_y2f) : ld (tyf),a
        jr .bottom
.hit    ld a,(res_i) : call plat_ix
        ld a,(ix+PLT_BOUNCY) : or a : jr z,.land
        ; a bouncy platform throws him back up from its top: the Steam version
        ; reverses his speed from before gravity, plus twice gravity
        ld hl,(res_y) : ld (ty),hl
        xor a : ld (tyf),a
        ld a,(tv_prev) : ld b,a : ld a,2 : sub b : ld (tv),a
        jr .bottom
.land   ; (he stays where he is: if that's between pixels above it, he drops onto it next)
        ld a,(tv) : add a,32 : ld b,a           ; (landing at 1.6 pixels a tick or faster kills him)
        xor a : ld (xvel),a : ld (tv),a
        inc a : ld (ud_db),a
        ld a,ST_STAND : ld (tstate),a
        ld a,b : or a : jr z,.dies : jp p,.bottom
.dies   call trogg_dies
.bottom ; off the bottom of the level?
        ld hl,(ty) : ld de,(level_h) : or a : sbc hl,de : ret c
        xor a : ld (xvel),a : ld (tyf),a
        dec de : ld (ty),de
        ; (and on, to die)

trogg_dies
        ld a,(won) : or a : ret nz              ; (nothing kills him once he's won, as in
                                                ; GameMaker: the last key and a meanie in
                                                ; the same tick win)
        ld a,50 : ld (dead),a                   ; restart in a second (50 game ticks)
        jp stop_sounds

; Enter the climbing state, its direction from ymove (tclimb 0 still, 1 up, 2 down)
start_climbing
        ld a,ST_CLIMB : ld (tstate),a
        ld a,(ymove) : or a : jr z,.set
        ld a,1 : jp p,.set
        inc a
.set    ld (tclimb),a
        ret

; Start falling at y velocity A (twentieths of a pixel a tick), x velocity xvel
climb_to_fall
        ld (tv),a
        ld a,ST_FALL : ld (tstate),a
        ld a,(xvel) : rlca : and 1 : ld (tface),a
        ret

; ------------------------------------------------------------------------------
; Climbing
; ------------------------------------------------------------------------------
trogg_climbing
        xor a : ld (xvel),a : ld (tv),a : ld (q_onplat),a : ld (q_jump),a
        ld hl,(tx) : ld (q_x),hl
        ld a,(ymove) : or a : jr z,.still : jp m,.down

        ; up: LadderFind(x, y, y - 1)
        call q1_is_y : ld a,256 - 20 : call q2_is_y_plus
        call ladder_find
        call ladder_moved : jr nc,.up_no
        call move_y_to_res
        call maybe_step_off : ret c
        jp .climbing
.up_no  ; At the top: step off onto a platform if there is one, PlatformFind(x, y - 1, y + 2)
        call q1_is_y
        ld hl,(q_y1) : dec hl : ld (q_y1),hl
        ld a,40 : call q2_is_y_plus
        call platform_find_f
        ld a,1 : ld (ud_db),a
        ld a,(res_found) : or a : jp z,.climbing
        ld hl,(ty) : dec hl : ld (ty),hl
        xor a : jp climb_to_fall

.still  ; LadderFind(x, y, y + 2)
        call q1_is_y : ld a,40 : call q2_is_y_plus
        call ladder_find
        call ladder_moved : jr nc,.still_no
        call maybe_step_off : ret c
        jp .climbing
.still_no
        ld a,(xmove) : or a : jp z,.climbing
        ld (xvel),a
        xor a : jp climb_to_fall

.down   ; Climbing down onto a platform? PlatformFind(x, y, y + 1)
        call q1_is_y : ld a,20 : call q2_is_y_plus
        call platform_find_f
        ld a,(res_found) : or a : jr z,.down_ladder
        ld a,1 : ld (ud_db),a
        xor a : ld (tstate),a : ld (tface),a    ; (ST_STAND)
        ret
.down_ladder
        ; LadderFind(x, y, y + 1)
        call q1_is_y : ld a,20 : call q2_is_y_plus
        call ladder_find
        call ladder_moved : jr nc,.down_no
        call move_y_to_res
        call maybe_step_off : ret c
        jp .climbing
.down_no
        ; Off the bottom of the ladder: y + 1, falling at a pixel a tick
        xor a : ld (xvel),a
        ld hl,(ty) : inc hl : ld (ty),hl
        inc a : ld (ud_db),a
        ld a,256 - 20 : jp climb_to_fall

.climbing
        call start_climbing
        ld a,(tclimb) : or a : ret z
        jp animate

; After ladder_find: carry set if a ladder was found and its y isn't Trogg's.
; Also moves tx to res_x when found.
ladder_moved
        ld a,(res_found) : or a : ret z         ; (carry clear)
        ld hl,(res_y) : ld de,(ty) : or a : sbc hl,de : jr nz,.yes
        ld a,(tyf) : ld b,a : ld a,(res_yf) : cp b : jr nz,.yes
        or a : ret
.yes    ld hl,(res_x) : ld (tx),hl
        scf : ret

; Moving sideways at or below the ladder's visible top lets Trogg step off it.
; Carry set if he did (and is now falling).
maybe_step_off
        ld a,(xmove) : or a : ret z
        ld a,(res_i) : call lad_ix
        ld l,(ix+L_YL) : ld h,(ix+L_YH) : ld e,(ix+L_EXT) : ld d,0 : add hl,de
        ex de,hl : ld hl,(ty) : or a : sbc hl,de
        ccf : ret nc                            ; (above the visible top: no)
        ld a,(xmove) : ld (xvel),a
        xor a : call climb_to_fall
        scf : ret
