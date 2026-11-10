; The game's logic, in extra bank 2 (LOGIC_BANK, as the BBC version's is in its
; sideways RAM bank 6): one tick of the game (game_tick) and everything it does,
; ported routine by routine from the BBC version, with the keys and the typed
; commands (commands.asm). It runs with bank 2 paged in at #4000. Whatever it calls in the low RAM that pages another bank in (the
; plotter, say) puts bank 2 back before it returns.
;
; The bank starts with the collision spans (the BBC version's SPANS, at
; SPANS_ORG), then the collision tables, the code and its variables.
;
; The slow sprites' state while the level plays is in records of SR_SIZE bytes
; (srecs, IY), one for each of the level's slow sprite records (slows, IX); the
; moving objects (balloons, daggers and meanies flying off) are records of
; M_SIZE bytes (movers, IY).

LOGIC_BANK = 2
MAX_OBJECTS = 64                    ; (things to draw: alive is indexed by them)
MAX_MOVERS = 12
MOVER_RANGE = 400                   ; a meanie flying off is gone this far from Trogg
MV_FLYING = 1 : MV_BALLOON = 2 : MV_DAGGER = 3
YOYO_MAX = 80
YOYO_HIT_SPEED = 8                  ; pixels a tick that a yoyoed meanie flies off at
SLOW_PAUSE = 30                     ; moving platforms pause this long at each end
HOOTER_GRAVITY = 13                 ; 0.05 pixels a tick a tick, in 8.8 fixed point
REACH = 95                          ; how far either side a Scrubbly is relevant
TICK_OK = 0 : TICK_DIED = 1 : TICK_WON = 2 : TICK_QUIT = 3
ST_STAND = 0 : ST_WALK = 1 : ST_FALL = 2 : ST_CLIMB = 3 : ST_YOYO_OUT = 4 : ST_YOYO_BACK = 5

; a slow sprite's state (positions 16.8 fixed point, velocities 8.8)
SR_ALIVE = 0 : SR_XF = 1 : SR_XL = 2 : SR_XH = 3 : SR_YF = 4 : SR_YL = 5 : SR_YH = 6
SR_VF = 7 : SR_VI = 8 : SR_VY = 9 : SR_WAIT = 10
SR_DXL = 11 : SR_DXH = 12 : SR_DYL = 13 : SR_DYH = 14   ; where it's shown (and collided with)
SR_SIZE = 16
; a moving object
M_ACTIVE = 0 : M_IMG = 1 : M_XF = 2 : M_XL = 3 : M_XH = 4 : M_YF = 5 : M_YL = 6 : M_YH = 7
M_VXF = 8 : M_VXI = 9 : M_VYF = 10 : M_VYI = 11 : M_PAUSE = 12
M_SIZE = 16

spans   INCBIN "../build/SPANS"
        INCLUDE "gen/collide.asm"

; ------------------------------------------------------------------------------
; Records
; ------------------------------------------------------------------------------

; IY = slow sprite A's state (A kept)
sr_iy   push af
        ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl
        ld de,srecs : add hl,de : push hl : pop iy
        pop af : ret
; IX = slow sprite A's record and IY its state
slow_both
        call sr_iy
        push af : call slow_ix : pop af
        ret
; IY = mover A
mv_iy   ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl
        ld de,movers : add hl,de : push hl : pop iy
        ret
; The last slow sprite's record (IX) and state (IY), and the one before
slow_last
        ld ix,slows + (MAX_SLOW - 1) * S_SIZE : ld iy,srecs + (MAX_SLOW - 1) * SR_SIZE
        ret
slow_prev
        ld de,-S_SIZE : add ix,de : ld de,-SR_SIZE : add iy,de
        ret
; The last mover (IY), and the one before
mover_last
        ld iy,movers + (MAX_MOVERS - 1) * M_SIZE
        ret
mover_prev
        ld de,-M_SIZE : add iy,de
        ret
; HL = alive + A
alive_hl
        ld hl,alive : add a,l : ld l,a : ret nc
        inc h : ret
word_hl ld a,(hl) : inc hl : ld h,(hl) : ld l,a
        ret
; HL = -HL
neg_hl  xor a : sub l : ld l,a
        sbc a,a : sub h : ld h,a
        ret

; ------------------------------------------------------------------------------
; One tick of the game: A (and Z) = TICK_OK, TICK_DIED or TICK_WON
; ------------------------------------------------------------------------------
game_tick
        ld a,(dead) : or a : jr z,.alive
        dec a : ld (dead),a : jr z,.died
        xor a : ret
.died   ld a,TICK_DIED : or a : ret
.alive  ld a,(won) : or a : jr z,.playing
        ; level complete: wait, then the next level
        ld hl,(win_ticks) : ld a,h : or l : jr z,.finished
        dec hl : ld (win_ticks),hl
        xor a : ret
.finished
        ld a,TICK_WON : or a : ret
.playing
        ld hl,(lvl_ticks) : inc hl : ld (lvl_ticks),hl
        call read_keys
        ld a,KEY_ESC : call key_pressed : jr z,.stay
        ld a,TICK_QUIT : or a : ret
.stay   call update_slow
        call trogg_update
        call footsteps
        call spawn_hazards
        call update_movers
        ld a,(dead) : or a : jr nz,.done
        call check_collisions
        call check_checkpoint
.done   xor a : ret

; Trogg's footsteps (as the Steam version, not while all the music's tracks play)
footsteps
        ld a,(snd_music_opt) : or a : ret z
        ld a,(lvl_ticks) : ld b,a
        ld a,(tstate) : cp ST_WALK : jr nz,.not_walking
        ld a,b : and 7 : ret nz : jr .thud      ; (walking: every 8 ticks)
.not_walking
        cp ST_CLIMB : ret nz
        ld a,(tclimb) : or a : ret z
        ld a,b : and 15 : ret nz                ; (climbing: every 16)
.thud   ld a,SFX_THUD : jp play_sfx

; Sound requests, as the BBC version makes them (phase 7 plays them)
; Start sound effect A (BC, DE, HL, IX, IY kept)
play_sfx
        push hl
        ld hl,snd_sfx_req : bit 7,(hl) : jr nz,.first
        ld hl,snd_sfx_req2
.first  ld (hl),a
        pop hl : ret
; Start tune A (0: silence)
play_music
        ld (snd_cur),a : ld (snd_music_req),a
        ret
; Stop the music and the sound effects
stop_sounds
        xor a : call play_music
        ld a,SFX_STOP : jr play_sfx

; ------------------------------------------------------------------------------
; Trogg's movement for one tick. He's carried along by the platform he was
; standing on (as in GameMaker, by however far it moved since last tick).
; ------------------------------------------------------------------------------
trogg_update
        ld a,(cur_plat) : cp 255 : jr z,.no_ride
        call plat_ix
        ld l,(ix+PLT_XL) : ld h,(ix+PLT_XH) : ld de,(last_px) : or a : sbc hl,de
        ld de,(tx) : add hl,de : ld (tx),hl
        ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH) : ld de,(last_py) : or a : sbc hl,de
        ld de,(ty) : add hl,de : ld (ty),hl
        ld a,255 : ld (cur_plat),a
.no_ride
        call cmd_pre                            ; (the typed commands)
        ld a,(tstate) : push af
        call trogg_move
        call cmd_post
        pop af : cp ST_YOYO_OUT : jr nc,.moved  ; (the yoyo states carry a platform themselves)
        push af : call carry_above : pop af
        ; GameMaker puts him on whole pixels when he lands from a fall: rounded up onto
        ; a platform, rounded (halves to even) onto a ladder
        cp ST_FALL : jr nz,.moved
        ld a,(tyf) : or a : jr z,.moved
        ld b,a
        ld a,(tstate) : cp ST_STAND : jr z,.inc_y
        cp ST_CLIMB : jr nz,.moved
        ld a,b : cp 10 : jr c,.whole : jr nz,.inc_y
        ld a,(ty) : rra : jr nc,.whole          ; (a half: to the even pixel)
.inc_y  ld hl,(ty) : inc hl : ld (ty),hl
.whole  xor a : ld (tyf),a
.moved  ; remember where his platform is now
        ld a,(cur_plat) : cp 255 : ret z
        ld a,(dead) : or a : ret nz
        ld a,(cur_plat) : call plat_ix
        ld l,(ix+PLT_XL) : ld h,(ix+PLT_XH) : ld (last_px),hl
        ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH) : ld (last_py),hl
        ret

trogg_move
        ld a,(tstate)
        cp ST_FALL : jp z,trogg_falling
        cp ST_CLIMB : jp z,trogg_climbing
        cp ST_YOYO_OUT : jp z,yoyo_out
        cp ST_YOYO_BACK : jp z,yoyo_back
        jp trogg_standing

        INCLUDE "trogg.asm"
        INCLUDE "commands.asm"
        INCLUDE "play.asm"

; ------------------------------------------------------------------------------
; The yoyo (port of the Yoyoing states of oTrogg and YoyoCollide)
;
; yo_len is the string length, in pixels (yo_len+1) and tenths (yo_len): it grows
; by 1.3 pixels a tick while the key is held, until it's 80 pixels or more, then
; shrinks back at the same rate.
;
; Movable platforms: the yoyo picks one up (unless it dropped one on this
; throw), Trogg carries it above his head, and letting go of the yoyo key while
; the yoyo is going out drops it where the yoyo is.
; ------------------------------------------------------------------------------
start_yoyo
        ld a,ST_YOYO_OUT : ld (tstate),a
        xor a : ld (yo_len),a : ld (dropped),a
        inc a : ld (yo_len+1),a                 ; length 1 for this tick's position
        call yoyo_position
        call yoyo_collide : jr nc,.done
        ld a,ST_YOYO_BACK : ld (tstate),a
        ld a,1 : ld (yo_db),a
.done   xor a : ld (yo_len+1),a                 ; (then it starts from 0)
        ret

yoyo_out
        call platform_under
        xor a : ld (yo_turn),a
        ld a,(doyoyo) : or a : jr z,.change
        ld a,(yo_len+1) : cp YOYO_MAX : jr nc,.change
        call yoyo_longer
        jr .moved
.change ld a,1 : ld (yo_turn),a                 ; (let go, or as long as it goes)
.moved  call yoyo_position
        call yoyo_collide : push af
        call carry_on_yoyo
        pop af : jr c,.turn
        ld a,(yo_turn) : or a : jr nz,.turn
        ; reached the left edge of the level? (yo_x < 2, signed)
        ld hl,(yo_x) : bit 7,h : jr nz,.turn
        ld a,h : or a : ret nz
        ld a,l : cp 2 : ret nc
.turn   ld a,(yo_turn) : or a : jr z,.back
        ld a,(carry) : cp 255 : jr z,.back
        ld a,255 : ld (carry),a                 ; let go: drop the platform here
        ld a,1 : ld (dropped),a
.back   ld a,ST_YOYO_BACK : ld (tstate),a
        ld a,1 : ld (yo_db),a
        ret

yoyo_back
        call platform_under
        ; length -= 1.3; home if that's 0 or less
        ld a,(yo_len+1) : ld c,a : ld b,1
        ld a,(yo_len) : sub 3 : jr nc,.t_ok
        add a,10 : inc b
.t_ok   ld (yo_len),a
        ld a,c : sub b : ld (yo_len+1),a
        jr c,.home : jp m,.home
        ld hl,yo_len : or (hl) : jr z,.home
        call yoyo_position
        call yoyo_collide                       ; still knocks meanies off on the way back
        jp carry_on_yoyo
.home   ld a,ST_STAND : ld (tstate),a
        xor a : ld (yo_len),a : ld (yo_len+1),a
        ret

; length += 1.3
yoyo_longer
        ld a,(yo_len+1) : ld b,a
        ld a,(yo_len) : add a,3 : cp 10 : jr c,.t_ok
        sub 10 : inc b
.t_ok   ld (yo_len),a
        inc b : ld a,b : ld (yo_len+1),a
        ret

; cur_plat = the platform Trogg is standing on (if any), so he rides it
platform_under
        ld hl,(tx) : ld (q_x),hl
        ld hl,(ty) : ld (q_y1),hl : inc hl : ld (q_y2),hl
        ld a,(tyf) : or a : ret nz              ; (between pixels: not on it)
        call platform_find
        ld a,(res_found) : or a : ret z
        ld a,(res_i) : ld (cur_plat),a
        ret

; yo_x = tx + (length + 12) * direction (rounded down), yo_y = ty - 11
yoyo_position
        ld a,(yo_len+1) : add a,12 : ld e,a : ld d,0
        ld hl,(tx)
        ld a,(tface) : or a : jr nz,.left
        add hl,de : jr .have_x
.left   ld a,(yo_len) : or a : jr z,.whole
        inc de                                  ; (tenths: a pixel further)
.whole  or a : sbc hl,de
.have_x ld (yo_x),hl
        ld hl,(ty) : ld de,-11 : add hl,de : ld (yo_y),hl
        ret

; Did the yoyo hit a meanie? GameMaker tested a circle of radius 3.5 at
; (yo_x, yo_y - 3.5) against the meanies' rectangles; this uses the circle's
; bounding square, x in [yo_x - 3, yo_x + 3] and y in [yo_y - 7, yo_y].
; A meanie that's hit flies off. Carry set if anything was hit.
yoyo_collide
        xor a : ld (yo_hit),a
        ld hl,(yo_x) : ld de,-3 : add hl,de : ld (yb_l),hl
        ld de,6 : add hl,de : ld (yb_r),hl
        ld hl,(yo_y) : ld de,-7 : add hl,de : ld (yb_t),hl
        ld a,MAX_OBJECTS - 1 : ld (co_i),a
.loop   ld a,(co_i) : call alive_hl : ld a,(hl) : or a : jp z,.next
        ld a,(co_i) : call draw_ix
        ld a,(ix+D_KIND) : cp KIND_MEANIE : jp nz,.next
        ; yoyo left < meanie right + 1 ? (unsigned, as the BBC version)
        ld a,(ix+D_IMG) : ld hl,img_w : call look : ld e,a : ld d,0
        ld l,(ix+D_LL) : ld h,(ix+D_LH) : add hl,de : ex de,hl
        ld hl,(yb_l) : or a : sbc hl,de : jp nc,.next
        ; meanie left <= yoyo right ?
        ld e,(ix+D_LL) : ld d,(ix+D_LH) : ld hl,(yb_r) : or a : sbc hl,de : jp c,.next
        ; yoyo top < meanie bottom + 1 ?
        ld a,(ix+D_IMG) : ld hl,img_h : call look : ld e,a : ld d,0
        ld l,(ix+D_TL) : ld h,(ix+D_TH) : add hl,de : ex de,hl
        ld hl,(yb_t) : or a : sbc hl,de : jp nc,.next
        ; meanie top <= yoyo bottom ?
        ld e,(ix+D_TL) : ld d,(ix+D_TH) : ld hl,(yo_y) : or a : sbc hl,de : jp c,.next
        ; Hit! It flies off in the yoyo's direction (launch_meanie squeals)
        ld a,1 : ld (yo_hit),a
        ld a,(co_i) : call alive_hl : ld (hl),0
        call queue_repaint
        ld a,(tface) : or a : ld a,YOYO_HIT_SPEED : jr z,.right
        ld a,256 - YOYO_HIT_SPEED
.right  call launch_meanie
.next   ld hl,co_i : dec (hl) : jp p,.loop

        ; Balloons and daggers are destroyed; a meanie already flying just bounces it back
        ld a,MAX_MOVERS - 1 : ld (mvc_i),a : call mover_last
.mloop  ld a,(iy+M_ACTIVE) : or a : jp z,.mnext
        ld a,(iy+M_IMG) : call mover_box_x
        ex de,hl : ld hl,(yb_r) : call signed_less : jp c,.mnext       ; yoyo right < left
        ld hl,(box_r) : ex de,hl : ld hl,(yb_l) : call signed_less : jp nc,.mnext  ; yoyo left > right
        ld a,(iy+M_IMG) : call mover_box_y
        ex de,hl : ld hl,(yo_y) : call signed_less : jp c,.mnext       ; yoyo bottom < top
        ld hl,(box_r) : ex de,hl : ld hl,(yb_t) : call signed_less : jp nc,.mnext  ; yoyo top > bottom
        ld a,1 : ld (yo_hit),a
        ld a,(iy+M_ACTIVE) : cp MV_FLYING : jr z,.mnext
        ld a,(iy+M_IMG) : cp IMG_Balloon : ld a,SFX_DAGGER : jr nz,.sfx
        ld a,SFX_POP
.sfx    call play_sfx
        ld (iy+M_ACTIVE),0
.mnext  ld de,-M_SIZE : add iy,de : ld hl,mvc_i : dec (hl) : jp p,.mloop
        call yoyo_slow
        call pick_up
        ld a,(yo_hit) : cp 1 : ccf              ; (carry set if hit)
        ret

; Image A at (HL, ...): HL = its left (HL - xo) and box_r = its right + 1
; (the left + its width)
box_from_x
        push hl
        ld (box_img),a : ld hl,img_xo : call look : ld e,a : ld d,0
        pop hl : or a : sbc hl,de
        push hl
        ld a,(box_img) : ld hl,img_w : call look : ld e,a : ld d,0
        pop hl : push hl : add hl,de : ld (box_r),hl
        pop hl : ret
; ... and HL = its top, box_r = its bottom + 1
box_from_y
        push hl
        ld (box_img),a : ld hl,img_yo : call look : ld e,a : ld d,0
        pop hl : or a : sbc hl,de
        push hl
        ld a,(box_img) : ld hl,img_h : call look : ld e,a : ld d,0
        pop hl : push hl : add hl,de : ld (box_r),hl
        pop hl : ret
; mover IY (image A): its box across, and down
mover_box_x
        ld l,(iy+M_XL) : ld h,(iy+M_XH) : jr box_from_x
mover_box_y
        ld l,(iy+M_YL) : ld h,(iy+M_YH) : jr box_from_y

; The yoyo against moving meanies: a hit one flies off (as a mover). Sets yo_hit.
yoyo_slow
        ld a,MAX_SLOW - 1 : ld (mvc_i),a : call slow_last
.loop   ld a,(iy+SR_ALIVE) : or a : jp z,.next
        ld a,(ix+S_KIND) : cp SL_PLATFORM : jp z,.next
        ld a,(ix+S_IMG) : ld l,(iy+SR_DXL) : ld h,(iy+SR_DXH) : call box_from_x
        ex de,hl : ld hl,(yb_r) : call signed_less : jp c,.next
        ld hl,(box_r) : ex de,hl : ld hl,(yb_l) : call signed_less : jp nc,.next
        ld a,(ix+S_IMG) : ld l,(iy+SR_DYL) : ld h,(iy+SR_DYH) : call box_from_y
        ex de,hl : ld hl,(yo_y) : call signed_less : jp c,.next
        ld hl,(box_r) : ex de,hl : ld hl,(yb_t) : call signed_less : jp nc,.next
        ; Hit: it flies off in the yoyo's direction
        ld a,SFX_SQUEAL : call play_sfx
        ld a,1 : ld (yo_hit),a
        ld (iy+SR_ALIVE),0
        ld a,1 : ld (clist_dirty),a             ; (one less to collide with)
        ld l,(iy+SR_DXL) : ld h,(iy+SR_DXH) : ld (lm_x),hl
        ld l,(iy+SR_DYL) : ld h,(iy+SR_DYH) : ld (lm_y),hl
        ld a,(ix+S_IMG) : ld (lm_img),a
        push iy
        call find_mover : jr c,.none
        ld (iy+M_ACTIVE),MV_FLYING
        ld a,(lm_img) : ld (iy+M_IMG),a
        ld hl,(lm_x) : ld (iy+M_XL),l : ld (iy+M_XH),h
        ld hl,(lm_y) : ld (iy+M_YL),l : ld (iy+M_YH),h
        ld a,(tface) : or a : ld a,YOYO_HIT_SPEED : jr z,.right
        ld a,256 - YOYO_HIT_SPEED
.right  ld (iy+M_VXI),a
.none   pop iy
.next   ld de,-S_SIZE : add ix,de : ld de,-SR_SIZE : add iy,de : ld hl,mvc_i : dec (hl) : jp p,.loop
        ret

; Nothing hit: pick up a movable platform the yoyo is in (the first), unless
; carrying one, or one was dropped on this throw
pick_up
        ld a,(yo_hit) : or a : ret nz
        ld a,(dropped) : or a : ret nz
        ld a,(carry) : or a : ret p
        xor a : ld (pk_i),a
.find   ld a,(num_plats) : ld b,a : ld a,(pk_i) : cp b : ret nc
        call plat_ix
        ld a,(ix+PLT_MOVING) : cp 2 : jr nz,.next
        ; x <= yo_x < x + w, and y <= yo_y < y + h ? (signed)
        ld e,(ix+PLT_XL) : ld d,(ix+PLT_XH) : ld hl,(yo_x) : call signed_less : jr c,.next
        ld l,(ix+PLT_XL) : ld h,(ix+PLT_XH) : ld e,(ix+PLT_W) : ld d,0 : add hl,de
        ex de,hl : ld hl,(yo_x) : call signed_less : jr nc,.next
        ld e,(ix+PLT_YL) : ld d,(ix+PLT_YH) : ld hl,(yo_y) : call signed_less : jr c,.next
        ld a,(ix+PLT_IMG) : ld hl,img_h : call look : ld e,a : ld d,0
        ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH) : add hl,de
        ex de,hl : ld hl,(yo_y) : call signed_less : jr c,.got
.next   ld hl,pk_i : inc (hl) : jr .find
.got    ld a,(pk_i) : ld (carry),a
        ld a,1 : ld (yo_hit),a
        ret

; Move platform A to (p_x, p_y), and the slow sprite that draws it
plat_move_to
        ld (pm_i),a
        call plat_ix
        ld hl,(p_x) : ld (ix+PLT_XL),l : ld (ix+PLT_XH),h
        ld hl,(p_y) : ld (ix+PLT_YL),l : ld (ix+PLT_YH),h
        ld a,MAX_SLOW - 1 : ld (pm_j),a : call slow_last
.find   ld a,(ix+S_KIND) : cp SL_PLATFORM : jr nz,.next
        ld a,(pm_i) : cp (ix+S_PLAT) : jr z,.found
.next   ld de,-S_SIZE : add ix,de : ld de,-SR_SIZE : add iy,de : ld hl,pm_j : dec (hl) : jp p,.find
        ret
.found  ld hl,(p_x) : ld (iy+SR_XL),l : ld (iy+SR_XH),h
        ld hl,(p_y) : ld (iy+SR_YL),l : ld (iy+SR_YH),h
        ret

; The platform Trogg's carrying goes above his head: centred on him, its top 14
; pixels above his feet
carry_above
        ld a,(carry) : or a : ret m
        call plat_ix
        ld a,(ix+PLT_W) : srl a : ld e,a : ld d,0
        ld hl,(tx) : or a : sbc hl,de : ld (p_x),hl
        ld hl,(ty) : ld de,-14 : add hl,de : ld (p_y),hl
        ld a,(carry) : jp plat_move_to

; ... or, while yoyoing, on the yoyo: 3 pixels in from the yoyo's x, on the side
; towards Trogg, rounded to the nearest pixel (halves to even, as GameMaker's
; round), at the same height
carry_on_yoyo
        ld a,(carry) : or a : ret m
        ld a,(tface) : or a : jr nz,.left
        ; tx + 9 + length
        ld a,(yo_len+1) : add a,9 : ld e,a : ld d,0
        ld hl,(tx) : add hl,de : ld (p_x),hl
        call round_away : jr nc,.have_x
        ld hl,(p_x) : inc hl : ld (p_x),hl
        jr .have_x
.left   ; tx - 8 - w - length
        ld a,(carry) : call plat_ix
        ld e,(ix+PLT_W) : ld d,0 : ld hl,8 : add hl,de
        ld a,(yo_len+1) : ld e,a : add hl,de
        ex de,hl : ld hl,(tx) : or a : sbc hl,de : ld (p_x),hl
        call round_away : jr nc,.have_x
        ld hl,(p_x) : dec hl : ld (p_x),hl
.have_x ld hl,(ty) : ld de,-14 : add hl,de : ld (p_y),hl
        ld a,(carry) : jp plat_move_to
; carry set if the length's tenths take p_x a pixel further from Trogg: more
; than a half, or a half when p_x is odd
round_away
        ld a,(yo_len) : cp 5 : jr nz,.ra
        ld a,(p_x) : rra
        ret
.ra     ccf : ret

; ------------------------------------------------------------------------------
; Moving objects: balloons, daggers and meanies flying off
; ------------------------------------------------------------------------------

; Find a free mover: IY, carry clear; carry set if there isn't one. IX kept.
find_mover
        ld a,MAX_MOVERS - 1
.find   ld (fm_i),a : call mv_iy
        ld a,(iy+M_ACTIVE) : or a : jr z,.free
        ld a,(fm_i) : dec a : jp p,.find
        scf : ret
.free   ld (iy+M_XF),a : ld (iy+M_YF),a : ld (iy+M_VXF),a : ld (iy+M_VXI),a
        ld (iy+M_VYF),a : ld (iy+M_VYI),a : ld (iy+M_PAUSE),a
        ret

; Start the meanie drawn by record IX flying off, at whole-pixel x velocity A (signed)
launch_meanie
        ld (lm_v),a
        ld a,SFX_SQUEAL : call play_sfx
        call find_mover : ret c                 ; (no free slot: it just vanishes)
        ld (iy+M_ACTIVE),MV_FLYING
        ld a,(lm_v) : ld (iy+M_VXI),a
        ld a,(ix+D_IMG) : ld (iy+M_IMG),a
        ld a,(ix+D_XL) : ld (iy+M_XL),a : ld a,(ix+D_XH) : ld (iy+M_XH),a
        ld a,(ix+D_YL) : ld (iy+M_YL),a : ld a,(ix+D_YH) : ld (iy+M_YH),a
        ret

; Move everything one tick, removing what has gone
update_movers
        ld a,MAX_MOVERS - 1 : ld (mv_i),a : call mover_last
.loop   ld a,(iy+M_ACTIVE) : or a : jp z,.next
        ld a,(iy+M_PAUSE) : or a : jr z,.move
        dec (iy+M_PAUSE) : jp .next
.move   ; x += vx, y += vy (16.8 + signed 8.8)
        ld a,(iy+M_VXI) : ld c,a : add a,a : sbc a,a : ld b,a
        ld a,(iy+M_XF) : add a,(iy+M_VXF) : ld (iy+M_XF),a
        ld a,(iy+M_XL) : adc a,c : ld (iy+M_XL),a
        ld a,(iy+M_XH) : adc a,b : ld (iy+M_XH),a
        ld a,(iy+M_VYI) : ld c,a : add a,a : sbc a,a : ld b,a
        ld a,(iy+M_YF) : add a,(iy+M_VYF) : ld (iy+M_YF),a
        ld a,(iy+M_YL) : adc a,c : ld (iy+M_YL),a
        ld a,(iy+M_YH) : adc a,b : ld (iy+M_YH),a
        ld a,(iy+M_ACTIVE)
        cp MV_BALLOON : jr z,.balloon
        cp MV_DAGGER : jr z,.dagger
        ; a meanie flying off: gone once it's MOVER_RANGE from Trogg (or off the left)
        ld a,(iy+M_XH) : or a : jp m,.gone
        ld h,a : ld l,(iy+M_XL) : ld de,(tx) : or a : sbc hl,de
        bit 7,h : call nz,neg_hl
        ld de,MOVER_RANGE : or a : sbc hl,de : jr c,.next
        jr .gone
.balloon
        ; gone when it floats off the top (y < 0)
        ld a,(iy+M_YH) : or a : jp m,.gone
        jr .next
.dagger ; gone at the bottom of the level, or once x <= -11
        ld l,(iy+M_YL) : ld h,(iy+M_YH) : ld de,(level_h) : call signed_less : jr nc,.gone
        ld l,(iy+M_XL) : ld h,(iy+M_XH) : ld de,-10 : call signed_less : jr c,.gone
        jr .next
.gone   ld (iy+M_ACTIVE),0
.next   ld de,-M_SIZE : add iy,de : ld hl,mv_i : dec (hl) : jp p,.loop
        ret

; ------------------------------------------------------------------------------
; Balloons and daggers (port of the oRoom Step event, oBalloon and oDagger)
; ------------------------------------------------------------------------------

; Per-difficulty settings (from the Steam version's oRoom Create), in game ticks
; and 8.8 fixed-point pixels a tick
diff_balloon_time db 0, 180, 120, 120, 90, 90, 60
diff_dagger_time  db 0, 220, 132, 132, 110, 110, 75
diff_pause        db 0, 60, 55, 55, 50, 50, 45
diff_balloon_v    dw 0, 307, 333, 333, 358, 358, 384       ; 1.2 .. 1.5
diff_dagger_x     dw 0, 205, 225, 225, 246, 246, 266       ; 0.8 * (1.0 .. 1.3)
diff_dagger_y     dw 0, 154, 169, 169, 184, 184, 200       ; 0.6 * (1.0 .. 1.3)
diff_spread       dw 0, 270, 280, 280, 290, 290, 300
; (levels that scroll up and down: balloons spread 1.25 times as wide, daggers 1.15)
vdiff_bspread     dw 0, 337, 350, 350, 362, 362, 375
vdiff_dspread     dw 0, 310, 322, 322, 333, 333, 345

; HL = word table HL's entry for the difficulty
diff_word
        ld a,(difficulty) : add a,a : ld e,a : ld d,0 : add hl,de
        jp word_hl
; A = byte table HL's entry for the difficulty
diff_byte
        ld a,(difficulty) : jp look

; Called once per tick while Trogg is alive
spawn_hazards
        ld hl,diff_balloon_time : call diff_byte : or a : jr z,.no_balloons
        ld a,(bal_timer) : or a : jr z,.spawn_b
        dec a : ld (bal_timer),a : jr nz,.no_balloons
.spawn_b
        call spawn_balloon
        ld hl,diff_balloon_time : call diff_byte : ld (bal_timer),a
.no_balloons
        ld hl,diff_dagger_time : call diff_byte : or a : ret z
        ld a,(dag_timer) : or a : jr z,.spawn_d
        dec a : ld (dag_timer),a : ret nz
.spawn_d
        call spawn_dagger
        ld hl,diff_dagger_time : call diff_byte : ld (dag_timer),a
        ret

; A balloon at the bottom of the level, at a random x within spread/2 of Trogg
spawn_balloon
        call find_mover : ret c
        ld hl,(tx) : ld (sp_mid),hl
        ld hl,diff_spread
        ld a,(is_vert) : or a : jr z,.spread
        ld hl,vdiff_bspread
.spread call diff_word : ld (sp_spread),hl
        call random_x
        ld (iy+M_ACTIVE),MV_BALLOON
        ld (iy+M_IMG),IMG_Balloon
        ld hl,(sp_x) : ld (iy+M_XL),l : ld (iy+M_XH),h
        ld hl,(level_h) : ld de,-4 : add hl,de : ld (iy+M_YL),l : ld (iy+M_YH),h
        ld hl,diff_balloon_v : call diff_word : call neg_hl     ; (up)
        ld (iy+M_VYF),l : ld (iy+M_VYI),h
        ld hl,diff_pause : call diff_byte : ld (iy+M_PAUSE),a
        ret

; A dagger at the top, aimed ahead of Trogg: the middle of its range is
; x + h * 4/3, where h = max(0, y - 4), so that it arrives about where he is
spawn_dagger
        call find_mover : ret c
        ld hl,(ty) : ld de,-4 : add hl,de
        bit 7,h : jr z,.h_ok
        ld hl,0
.h_ok   ld a,(is_vert) : or a : jr nz,.v_aim
        ; (levels that scroll sideways are 256 high, so h fits in a byte)
        ; mid = h + h * 85 / 256  (h * 1.332)
        ld a,l : ld (sp_h),a : ld e,85 : call mul8
        ld e,a : ld d,0 : ld a,(sp_h) : ld l,a : ld h,d : add hl,de
        ld (sp_mid),hl
        ld hl,diff_spread : jr .aimed
.v_aim  ; a level that scrolls up and down: mid = h * 0.75 (h - h / 4)
        ld d,h : ld e,l : srl d : rr e : srl d : rr e
        or a : sbc hl,de : ld (sp_mid),hl
        ld hl,vdiff_dspread
.aimed  call diff_word : ld (sp_spread),hl
        ld hl,(sp_mid) : ld de,(tx) : add hl,de : ld (sp_mid),hl
        call random_x
        ld (iy+M_ACTIVE),MV_DAGGER
        ld hl,(sp_x) : ld (iy+M_XL),l : ld (iy+M_XH),h
        ld (iy+M_YL),4 : ld (iy+M_YH),0
        ld hl,diff_pause : call diff_byte : ld (iy+M_PAUSE),a
        ld a,(is_vert) : or a : jr nz,.v_dagger
        ld (iy+M_IMG),IMG_DaggerLR
        ; down and to the left (x speed 0.8, y 0.6 of its speed)
        ld hl,diff_dagger_x : call diff_word : call neg_hl
        ld (iy+M_VXF),l : ld (iy+M_VXI),h
        ld hl,diff_dagger_y : call diff_word
        ld (iy+M_VYF),l : ld (iy+M_VYI),h
        ret
.v_dagger
        ld (iy+M_IMG),IMG_DaggerUD
        ; (x speed 0.6, y 0.8)
        ld hl,diff_dagger_y : call diff_word : call neg_hl
        ld (iy+M_VXF),l : ld (iy+M_VXI),h
        ld hl,diff_dagger_x : call diff_word
        ld (iy+M_VYF),l : ld (iy+M_VYI),h
        ret

; sp_x = sp_mid - spread/2 + random(0 .. spread)
random_x
.retry  call random
        ld hl,(rng) : ld a,h : and 1 : ld h,a   ; 0 .. 511
        ex de,hl : ld hl,(sp_spread) : or a : sbc hl,de : jr c,.retry
        ld hl,(sp_mid) : add hl,de : ex de,hl
        ld hl,(sp_spread) : srl h : rr l
        ex de,hl : or a : sbc hl,de : ld (sp_x),hl
        ret

; 16-bit xorshift random numbers (John Metcalf's 7/9/8 version, as the BBC version)
random  ld hl,(rng)
        ld a,l : and 1 : rrca : ld c,a          ; (L's bit 0, for the second rotate)
        ld a,h : rra : ld a,l : rra             ; A = (H:L) >> 1, low byte
        xor h : ld h,a
        srl a : or c                            ; ... rotated right, L's bit 0 in
        xor l : ld l,a
        xor h : ld h,a
        ld (rng),hl
        ret

; A = the high byte of A * E
mul8    ld h,a : ld l,0 : ld d,l : ld b,8
.loop   add hl,hl : jr nc,.no_add
        add hl,de
.no_add djnz .loop
        ld a,h
        ret

; ------------------------------------------------------------------------------
; Moving platforms and meanies ("slow sprites"): ports of the Step events of
; oPlatform, oScrubbly, oPoglet and oHooter
; ------------------------------------------------------------------------------

; One tick of movement for every slow sprite
update_slow
        ld a,MAX_SLOW - 1 : ld (sl_i),a : call slow_last
.loop   ld a,(iy+SR_ALIVE) : or a : jr z,.next
        ld a,(ix+S_KIND)
        cp SL_PLATFORM : jr nz,.not_plat
        call move_platform : jr .next
.not_plat
        cp SL_SCRUBBLY : jr nz,.not_scrub
        ; (a Scrubbly moves only while it's relevant to Trogg; Poglets and Hooters always
        ; move, as levels' timing puzzles depend on them)
        call relevant : call c,move_scrubbly : jr .next
.not_scrub
        cp SL_POGLET : jr nz,.hooter
        call move_poglet : jr .next
.hooter call move_hooter
.next   ld de,-S_SIZE : add ix,de : ld de,-SR_SIZE : add iy,de : ld hl,sl_i : dec (hl) : jp p,.loop
        ret

; Carry set if Scrubbly IX/IY is relevant to Trogg: the box it walks in (amin to
; amax, at y) is above or below him, or level with him and within his yoyo's
; reach. (One riding a moving platform always is: it keeps up with it.)
relevant
        ld a,(ix+S_PLAT) : cp 255 : jr z,.look
.yes    scf : ret
.look   ld a,(ix+S_IMG) : ld (rl_img),a
        ; across: it walks from amin to amax
        ld l,(ix+S_AMINL) : ld h,(ix+S_AMINH) : ld (rl_l),hl
        ld l,(ix+S_AMAXL) : ld h,(ix+S_AMAXH) : ld (rl_r),hl
        ; its edges, from tx: left = l - xo - tx, right = r - xo + w - 1 - tx
        ld hl,img_w : call rl_look : dec a : ld (rl_a),a
        ld hl,img_xo : call rl_look : ld e,a : ld d,0
        ld hl,(tx) : add hl,de : call box
        ; above or below him (within 12 pixels of his middle)?
        ld a,12 : call within : jr c,.yes
        ld a,REACH : call within : ret nc
        ; level with him? Down: it's at y
        ld l,(iy+SR_YL) : ld h,(iy+SR_YH) : ld (rl_l),hl : ld (rl_r),hl
        ; edges from his middle (17 pixels above his feet)
        ld hl,img_h : call rl_look : dec a : ld (rl_a),a
        ld hl,img_yo : call rl_look : ld e,a : ld d,0
        ld hl,(ty) : add hl,de : ld de,-17 : add hl,de : call box
        ld a,17 : jp within                     ; (his 34 rows)
rl_look ld a,(rl_img) : jp look
; rl_l -= HL; rl_r += rl_a - HL
box     ex de,hl
        ld hl,(rl_l) : or a : sbc hl,de : ld (rl_l),hl
        ld a,(rl_a) : ld c,a : ld b,0
        ld hl,(rl_r) : add hl,bc : or a : sbc hl,de : ld (rl_r),hl
        ret
; Carry set if rl_l..rl_r (signed) reaches within A of 0: rl_r >= -A and rl_l <= A
within  ld (rl_a),a : ld c,a : ld b,0
        ld hl,(rl_r) : add hl,bc : bit 7,h : jr nz,.no
        ld h,b : ld l,c : ld de,(rl_l) : or a : sbc hl,de : bit 7,h : jr nz,.no
        scf : ret
.no     or a : ret

; HL = |its default speed| (8.8), for slow sprite IX
abs_speed
        ld l,(ix+S_VF) : ld h,(ix+S_VI)
        bit 7,h : ret z
        jp neg_hl

move_platform
        ld a,(iy+SR_WAIT) : or a : jr z,.go
        dec (iy+SR_WAIT) : ret
.go     ; x += vx (+1/-1), bouncing off the ends of its range with a pause
        ld a,(iy+SR_VI) : or a : jr z,.y_move : jp m,.left
        ld l,(iy+SR_XL) : ld h,(iy+SR_XH) : inc hl : ld (iy+SR_XL),l : ld (iy+SR_XH),h
        ex de,hl : ld l,(ix+S_AMAXL) : ld h,(ix+S_AMAXH) : or a : sbc hl,de : jr nc,.y_move
        ld a,(ix+S_AMAXL) : ld (iy+SR_XL),a : ld a,(ix+S_AMAXH) : ld (iy+SR_XH),a
        ld (iy+SR_VI),#FF : ld (iy+SR_WAIT),SLOW_PAUSE
        jr .y_move
.left   ld l,(iy+SR_XL) : ld h,(iy+SR_XH) : dec hl : ld (iy+SR_XL),l : ld (iy+SR_XH),h
        ld e,(ix+S_AMINL) : ld d,(ix+S_AMINH) : or a : sbc hl,de : jr nc,.y_move
        ld (iy+SR_XL),e : ld (iy+SR_XH),d
        ld (iy+SR_VI),1 : ld (iy+SR_WAIT),SLOW_PAUSE
.y_move ; y += vy likewise
        ld a,(iy+SR_VY) : or a : jr z,.store : jp m,.up
        ld l,(iy+SR_YL) : ld h,(iy+SR_YH) : inc hl : ld (iy+SR_YL),l : ld (iy+SR_YH),h
        ex de,hl : ld l,(ix+S_BMAXL) : ld h,(ix+S_BMAXH) : or a : sbc hl,de : jr nc,.store
        ld a,(ix+S_BMAXL) : ld (iy+SR_YL),a : ld a,(ix+S_BMAXH) : ld (iy+SR_YH),a
        ld (iy+SR_VY),#FF : ld (iy+SR_WAIT),SLOW_PAUSE
        jr .store
.up     ld l,(iy+SR_YL) : ld h,(iy+SR_YH) : dec hl : ld (iy+SR_YL),l : ld (iy+SR_YH),h
        ld e,(ix+S_BMINL) : ld d,(ix+S_BMINH) : or a : sbc hl,de : jr nc,.store
        ld (iy+SR_YL),e : ld (iy+SR_YH),d
        ld (iy+SR_VY),1 : ld (iy+SR_WAIT),SLOW_PAUSE
.store  ; ... and update the platform table that Trogg stands on
        push ix
        ld a,(ix+S_PLAT) : call plat_ix
        ld a,(iy+SR_XL) : ld (ix+PLT_XL),a : ld a,(iy+SR_XH) : ld (ix+PLT_XH),a
        ld a,(iy+SR_YL) : ld (ix+PLT_YL),a : ld a,(iy+SR_YH) : ld (ix+PLT_YH),a
        pop ix
        ret

; Scrubbly: patrols its platform between amin and amax
move_scrubbly
        ld a,(iy+SR_VI) : ld c,a : add a,a : sbc a,a : ld b,a
        ld a,(iy+SR_XF) : add a,(iy+SR_VF) : ld (iy+SR_XF),a
        ld a,(iy+SR_XL) : adc a,c : ld (iy+SR_XL),a
        ld a,(iy+SR_XH) : adc a,b : ld (iy+SR_XH),a
        ; x < amin ?
        ld l,(iy+SR_XL) : ld h,(iy+SR_XH) : ld e,(ix+S_AMINL) : ld d,(ix+S_AMINH)
        or a : sbc hl,de : jr nc,.not_low
        ld (iy+SR_XL),e : ld (iy+SR_XH),d : ld (iy+SR_XF),0
        call abs_speed : ld (iy+SR_VF),l : ld (iy+SR_VI),h
        jr .follow
.not_low
        ; x > amax ?
        ld l,(iy+SR_XL) : ld h,(iy+SR_XH) : ld e,(ix+S_AMAXL) : ld d,(ix+S_AMAXH)
        or a : sbc hl,de : jr c,.follow : jr nz,.high
        ld a,(iy+SR_XF) : or a : jr z,.follow
.high   ld (iy+SR_XL),e : ld (iy+SR_XH),d : ld (iy+SR_XF),0
        call abs_speed : call neg_hl : ld (iy+SR_VF),l : ld (iy+SR_VI),h
.follow ; some ride up and down with a moving platform
        ld a,(ix+S_PLAT) : cp 255 : ret z
        push ix
        call plat_ix
        ld a,(ix+PLT_YL) : ld (iy+SR_YL),a : ld a,(ix+PLT_YH) : ld (iy+SR_YH),a
        pop ix
        ret

; Poglet: climbs up and down between amin and amax
move_poglet
        ld a,(iy+SR_VI) : ld c,a : add a,a : sbc a,a : ld b,a
        ld a,(iy+SR_YF) : add a,(iy+SR_VF) : ld (iy+SR_YF),a
        ld a,(iy+SR_YL) : adc a,c : ld (iy+SR_YL),a
        ld a,(iy+SR_YH) : adc a,b : ld (iy+SR_YH),a
        ld l,(iy+SR_YL) : ld h,(iy+SR_YH) : ld e,(ix+S_AMINL) : ld d,(ix+S_AMINH)
        or a : sbc hl,de : jr nc,.not_low
        ld (iy+SR_YL),e : ld (iy+SR_YH),d : ld (iy+SR_YF),0
        call abs_speed : ld (iy+SR_VF),l : ld (iy+SR_VI),h
        ret
.not_low
        ld l,(iy+SR_YL) : ld h,(iy+SR_YH) : ld e,(ix+S_AMAXL) : ld d,(ix+S_AMAXH)
        or a : sbc hl,de : ret c : jr nz,.high
        ld a,(iy+SR_YF) : or a : ret z
.high   ld (iy+SR_YL),e : ld (iy+SR_YH),d : ld (iy+SR_YF),0
        call abs_speed : call neg_hl : ld (iy+SR_VF),l : ld (iy+SR_VI),h
        ret

; Hooter: jumps up and down on the spot (after an initial sleep)
move_hooter
        ld a,(iy+SR_WAIT) : or a : jr z,.go
        dec (iy+SR_WAIT) : ret
.go     ; v -= gravity; y -= v
        ld l,(iy+SR_VF) : ld h,(iy+SR_VI) : ld de,-HOOTER_GRAVITY : add hl,de
        ld (iy+SR_VF),l : ld (iy+SR_VI),h
        ld a,h : rla : sbc a,a : ld c,a                 ; (v's sign)
        ld a,(iy+SR_YF) : sub l : ld (iy+SR_YF),a
        ld a,(iy+SR_YL) : sbc a,h : ld (iy+SR_YL),a : ld l,a
        ld a,(iy+SR_YH) : sbc a,c : ld (iy+SR_YH),a : ld h,a
        ; below its base? land and jump again
        ld e,(ix+S_Y0L) : ld d,(ix+S_Y0H)
        or a : sbc hl,de : ret c : jr nz,.land
        ld a,(iy+SR_YF) : or a : ret z
.land   ld (iy+SR_YL),e : ld (iy+SR_YH),d : ld (iy+SR_YF),0
        ld a,(ix+S_VF) : ld (iy+SR_VF),a : ld a,(ix+S_VI) : ld (iy+SR_VI),a
        ret

; Where slow sprite IX/IY is shown (and collided with) = where it is. (A meanie
; is shown with its left edge at an even pixel, so the compiled code for it
; only needs two pixel offsets: x takes the parity of the image's x origin.)
commit_one
        ld a,(ix+S_KIND) : cp SL_PLATFORM : ld a,(iy+SR_XL) : jr z,.exact
        ld b,a
        ld a,(ix+S_IMG) : ld hl,img_xo : call look : ld c,a
        ld a,b : xor c : and #FE : xor c
.exact  ld (iy+SR_DXL),a
        ld a,(iy+SR_XH) : ld (iy+SR_DXH),a
        ld a,(iy+SR_YL) : ld (iy+SR_DYL),a : ld a,(iy+SR_YH) : ld (iy+SR_DYH),a
        ret
; ... for all of them
commit_all
        call slow_last : ld b,MAX_SLOW
.loop   push bc : call commit_one : ld de,-S_SIZE : add ix,de : ld de,-SR_SIZE : add iy,de : pop bc
        djnz .loop
        jp build_clist

; ------------------------------------------------------------------------------
; Collisions between Trogg and keys, gems and meanies
;
; Like GameMaker's precise collisions, but using the leftmost and rightmost solid
; pixel of each row (the "spans"): after a bounding-box check, Trogg and the
; object collide if their spans overlap on any shared row.
; ------------------------------------------------------------------------------
check_collisions
        call trogg_image : ld (ct_img),a
        ld hl,img_xo : call look : ld e,a : ld d,0
        ld hl,(tx) : or a : sbc hl,de : ld (ct_l),hl
        ld a,(ct_img) : ld hl,img_yo : call look : ld e,a : ld d,0
        ld hl,(ty) : or a : sbc hl,de : ld (ct_t),hl
        ; Trogg's byte columns: [ct_c0, ct_c0 + 8), for a quick first test
        ld hl,(ct_l) : xor a : bit 7,h : jr nz,.have_c0
        srl h : rr l : srl h : rr l : ld a,l
.have_c0
        ld (ct_c0),a : add a,8 : ld (ct_c1),a
        ; the things drawn: a quick pass over their byte columns (dcols, which
        ; level_init makes), and the full test for those in Trogg's
        ld a,(ct_c1) : ld (.c1 + 1),a
        ld a,(ct_c0) : ld (.c0 + 1),a
        ld a,(num_draw) : or a : jr z,.movers
        ld b,a : ld hl,alive : ld de,dcols
.loop   ld a,(hl) : inc hl : or a : jr z,.dead
        ld a,(de) : inc de                      ; its first column
.c1     cp 0 : jr nc,.far                       ; (starts right of him: cp ct_c1)
        ld a,(de)                               ; ... and the column after its last
.c0     cp 0 : jr c,.far : jr z,.far            ; (ends left of him: cp ct_c0)
        push bc : push de : push hl
        ld a,(num_draw) : sub b : ld (co_i),a : call draw_ix
        ld l,(ix+D_LL) : ld h,(ix+D_LH) : ld de,(ct_l) : or a : sbc hl,de
        call in_range_64 : jr nc,.next : ld (c_dx),a
        ld l,(ix+D_TL) : ld h,(ix+D_TH) : ld de,(ct_t) : or a : sbc hl,de
        call in_range_64 : jr nc,.next : ld (c_dy),a
        ld a,(ix+D_IMG) : ld (c_oimg),a
        call hit_test : jr nc,.next
        call collide
.next   pop hl : pop de : pop bc
.far    inc de : djnz .loop
        jr .movers
.dead   inc de : inc de : djnz .loop
.movers

        ; Moving objects (balloons, daggers, meanies flying off) are all deadly
        ld a,MAX_MOVERS - 1 : ld (mvc_i),a : call mover_last
.mloop  ld a,(iy+M_ACTIVE) : or a : jr z,.mnext
        ld a,(iy+M_IMG) : ld (c_oimg),a
        ld l,(iy+M_XL) : ld h,(iy+M_XH) : ld e,(iy+M_YL) : ld d,(iy+M_YH)
        call trogg_overlap : call c,trogg_dies
.mnext  ld de,-M_SIZE : add iy,de : ld hl,mvc_i : dec (hl) : jp p,.mloop

        ; ... and so are the moving meanies (the list of them where they're shown)
        ld a,(clist_dirty) : or a : call nz,build_clist
        ld a,(clist_n) : or a : ret z
        ld b,a : ld hl,clist
.sloop  push bc
        ld a,(hl) : ld (c_oimg),a : inc hl
        ld e,(hl) : inc hl : ld d,(hl) : inc hl         ; DE = its left
        ld c,(hl) : inc hl : ld b,(hl) : inc hl         ; BC = its top
        push hl
        ex de,hl : ld de,(ct_l) : or a : sbc hl,de
        call in_range_64 : jr nc,.snext
        ld (c_dx),a
        ld h,b : ld l,c : ld de,(ct_t) : or a : sbc hl,de
        call in_range_64 : jr nc,.snext
        ld (c_dy),a
        call hit_test : call c,trogg_dies
.snext  pop hl : pop bc : djnz .sloop
        ret

; The moving meanies where they're shown, for check_collisions: for each one alive
; (clist_n of them), its image, then its left and top (from its origin), made each
; time they're shown somewhere new (commit_all), or one's knocked off by the yoyo
build_clist
        xor a : ld (clist_n),a : ld (clist_dirty),a
        ld hl,clist : ld (cl_ptr),hl
        call slow_last : ld b,MAX_SLOW
.loop   ld a,(iy+SR_ALIVE) : or a : jr z,.next
        ld a,(ix+S_KIND) : cp SL_PLATFORM : jr z,.next
        push bc
        ld a,(ix+S_IMG) : ld c,a
        ld l,(iy+SR_DXL) : ld h,(iy+SR_DXH) : call box_from_x : ex de,hl      ; DE = left
        push de
        ld a,c : ld l,(iy+SR_DYL) : ld h,(iy+SR_DYH) : call box_from_y       ; HL = top
        pop de
        ld b,h : ld a,l : ld hl,(cl_ptr)
        ld (hl),c : inc hl : ld (hl),e : inc hl : ld (hl),d : inc hl : ld (hl),a : inc hl : ld (hl),b : inc hl
        ld (cl_ptr),hl
        ld hl,clist_n : inc (hl)
        pop bc
.next   ld de,-S_SIZE : add ix,de : ld de,-SR_SIZE : add iy,de
        djnz .loop
        ret

; Does image c_oimg at (HL, DE) overlap Trogg? Carry set if so.
trogg_overlap
        ; (more than 127 pixels from Trogg either way: no. Every image's origin is less
        ; than 64 pixels from its edges, and the offsets between them must be -64..63)
        push hl
        ld bc,(tx) : or a : sbc hl,bc : ld bc,128 : add hl,bc : ld a,h
        ld h,d : ld l,e : ld bc,(ty) : or a : sbc hl,bc : ld bc,128 : add hl,bc : or h
        pop hl
        ret nz
        ld (to_y),de
        push hl : ld a,(c_oimg) : ld hl,img_xo : call look : pop hl
        ld e,a : ld d,0 : or a : sbc hl,de
        ld de,(ct_l) : or a : sbc hl,de
        call in_range_64 : ret nc
        ld (c_dx),a
        ld a,(c_oimg) : ld hl,img_yo : call look : ld e,a : ld d,0
        ld hl,(to_y) : or a : sbc hl,de
        ld de,(ct_t) : or a : sbc hl,de
        call in_range_64 : ret nc
        ld (c_dy),a
        jp hit_test

; HL = a 16-bit difference: carry set (and A = its low byte) if it's in -64..63
in_range_64
        ld a,h : or a : jr z,.pos
        inc a : jr nz,.no
        ld a,l : cp #C0 : ccf
        ret
.pos    ld a,l : cp 64
        ret
.no     or a : ret

; Does Trogg (image ct_img) overlap object c_oimg at offset (c_dx, c_dy)?
; Carry set if so.
hit_test
        ; offsets biased by 128 so that everything is an unsigned compare
        ld a,(c_dx) : xor #80 : ld (c_dxb),a
        ld a,(c_dy) : xor #80 : ld (c_dyb),a
        ld a,(c_oimg) : ld e,a : ld d,0                 ; DE = the object
        ld a,(ct_img) : ld c,a : ld b,0                 ; BC = Trogg
        ; tight bounding boxes: object x0 + dx <= Trogg x1 and object x1 + dx >= Trogg x0
        ld hl,img_bx0 : add hl,de : ld a,(c_dxb) : add a,(hl) : ld (ht_t),a
        ld hl,img_bx1 : add hl,bc : ld a,(hl) : or #80
        ld hl,ht_t : cp (hl) : jp c,.miss
        ld hl,img_bx1 : add hl,de : ld a,(c_dxb) : add a,(hl) : ld (ht_t),a
        ld hl,img_bx0 : add hl,bc : ld a,(hl) : or #80 : ld (ht_u),a
        ld a,(ht_t) : ld hl,ht_u : cp (hl) : jp c,.miss
        ; ... and the same down
        ld hl,img_by0 : add hl,de : ld a,(c_dyb) : add a,(hl) : ld (ht_t),a
        ld hl,img_by1 : add hl,bc : ld a,(hl) : or #80
        ld hl,ht_t : cp (hl) : jp c,.miss
        ld hl,img_by1 : add hl,de : ld a,(c_dyb) : add a,(hl) : ld (ht_t),a
        ld hl,img_by0 : add hl,bc : ld a,(hl) : or #80 : ld (ht_u),a
        ld a,(ht_t) : ld hl,ht_u : cp (hl) : jp c,.miss
        ; shared rows, in Trogg's coordinates: rs = max(0, dy), re = min(Trogg's h, dy + object's h)
        ld a,(c_dy) : bit 7,a : jr z,.dy_pos
        xor a
.dy_pos ld (c_rs),a
        ld hl,img_h : add hl,de : ld a,(c_dy) : add a,(hl)     ; (signed, -64..105)
        jp m,.miss
        ld hl,img_h : add hl,bc : cp (hl) : jr c,.re_ok
        ld a,(hl)
.re_ok  ld hl,c_rs : sub (hl) : jr z,.miss : jr c,.miss
        ld (c_rows),a
        ; HL = Trogg's spans + rs * 2, DE = the object's + (rs - dy) * 2
        push de
        ld hl,img_span_lo : add hl,bc : ld a,(hl)
        ld hl,img_span_hi : add hl,bc : ld h,(hl) : ld l,a
        ld a,(c_rs) : add a,a : add a,l : ld l,a : jr nc,.nc1
        inc h
.nc1    pop de : push hl
        ld hl,img_span_lo : add hl,de : ld a,(hl)
        ld hl,img_span_hi : add hl,de : ld d,(hl) : ld e,a
        ld a,(c_dy) : ld b,a : ld a,(c_rs) : sub b : add a,a : add a,e : ld e,a : jr nc,.nc2
        inc d
.nc2    pop hl
.row    ld a,(hl) : cp 255 : jr z,.skip_row     ; Trogg's row is empty
        ld (c_tl),a
        ld a,(de) : cp 255 : jr z,.skip_row     ; the object's row is empty
        ld b,a : ld a,(c_dxb) : add a,b : ld c,a        ; object left (biased)
        inc hl : inc de
        ld a,(hl) : or #80 : cp c : jr c,.row_miss      ; Trogg right < object left
        ld a,(de) : ld b,a : ld a,(c_dxb) : add a,b : ld c,a    ; object right (biased)
        ld a,(c_tl) : or #80 : ld b,a
        ld a,c : cp b : jr nc,.hit                      ; object right >= Trogg left
.row_miss
        inc hl : inc de
        jr .next_row
.skip_row
        inc hl : inc hl : inc de : inc de
.next_row
        ld a,(c_rows) : dec a : ld (c_rows),a : jr nz,.row
.miss   or a : ret
.hit    scf : ret

; Trogg has touched the object drawn by record IX (co_i)
collide
        ld a,(ix+D_KIND) : cp KIND_MEANIE : jp z,trogg_dies
        ld a,(co_i) : call alive_hl : ld (hl),0
        ld a,SFX_CHING : call play_sfx
        call queue_repaint
        ld a,(ix+D_KIND) : cp KIND_GEM : jr nz,.not_gem
        ld hl,gems_found : inc (hl)
        ret
.not_gem
        cp KIND_KEY : ret nz
        ld hl,keys_found : inc (hl)
        ld a,(num_keys) : cp (hl) : jp z,level_complete     ; all the keys!
        ld a,1 : ld (save_cp),a                 ; checkpoint once Trogg is standing still
        ret

; Repaint the columns of the object drawn by record IX, in both buffers
queue_repaint
        ld hl,pend_lo : ld de,pend_hi : ld b,2
.loop   ld a,(ix+D_C0) : cp (hl) : jr nc,.lo_ok
        ld (hl),a
.lo_ok  ld a,(de) : ld c,a : ld a,(ix+D_C1) : cp c : jr c,.hi_ok
        ld (de),a
.hi_ok  inc hl : inc de : djnz .loop
        ret

; A = Trogg's image now
trogg_image
        ld a,(tstate)
        cp ST_WALK : jr z,.walk
        cp ST_CLIMB : jr z,.climb
        cp ST_YOYO_OUT : jr c,.stand
        ld a,(tface) : or a : ld a,IMG_Trogg_yr : ret z
        ld a,IMG_Trogg_yl : ret
.stand  ld a,(tface) : or a : ld a,IMG_Trogg_sr : ret z
        ld a,IMG_Trogg_sl : ret
.walk   ld a,(anim) : rlca : rlca : and 3 : ld b,a      ; (the top two bits: frame 0..3)
        ld a,(tface) : or a : ld a,IMG_Trogg_wr_0 : jr z,.add
        ld a,IMG_Trogg_wl_0
.add    add a,b : ret
.climb  ld a,(tclimb) : or a : ld a,IMG_Trogg_cn : ret z
        ld a,(anim) : rlca : and 1 : ld b,a             ; (the top bit: frame 0..1)
        ld a,(tclimb) : cp 1 : ld a,IMG_Trogg_cu_0 : jr z,.add
        ld a,IMG_Trogg_cd_0 : jr .add

; ------------------------------------------------------------------------------
; Checkpoints, the start of a level, and its end
; ------------------------------------------------------------------------------

; Save a checkpoint after collecting a key, once Trogg is standing on a platform
check_checkpoint
        ld a,(save_cp) : or a : ret z
        ld a,(dead) : or a : ret nz             ; (not if he touched a meanie too)
        ld a,(tstate) : cp ST_WALK + 1 : ret nc ; standing or walking only
        ; ... on a platform that isn't moving
        ld a,(cur_plat) : cp 255 : ret z
        call plat_ix
        ld a,(ix+PLT_MOVING) : cp 1 : ret z     ; (Trogg moves the movable ones)
        xor a : ld (save_cp),a
        inc a : ld (have_cp),a
        ; (and on)

; Save the checkpoint (also at the start of a level, for a death before the first key)
save_checkpoint
        ld hl,alive : ld de,cp_alive : ld bc,MAX_OBJECTS : ldir
        ld hl,keys_found : ld de,cp_keys : ld bc,CP_VARS : ldir
        ld hl,(tx) : ld (cp_tx),hl : ld hl,(ty) : ld (cp_ty),hl
        ld a,(tyf) : ld (cp_tyf),a : ld a,(tface) : ld (cp_face),a
        ld hl,srecs : ld de,cp_srecs : ld bc,MAX_SLOW * SR_SIZE : ldir
        ; the platforms' positions
        ld hl,plats : ld de,cp_plats : ld b,MAX_PLATS
.plat   push bc : ld bc,4 : ldir
        ld bc,PLT_SIZE - 4 : add hl,bc : pop bc
        djnz .plat
        ret

; Go back to the last checkpoint (the state saved after collecting a key)
restore_checkpoint
        ld a,(have_cp) : or a : jr nz,.counted
        ; (no key yet: back to the start of the level, saved when it began, as if it
        ; had just started, as GameMaker restarts the room)
        ld (restarts),a : ld hl,0 : ld (lvl_ticks),hl
        jr .restore
.counted
        ld hl,restarts : inc (hl)
.restore
        ld hl,cp_alive : ld de,alive : ld bc,MAX_OBJECTS : ldir
        ld hl,cp_keys : ld de,keys_found : ld bc,CP_VARS : ldir
        ld hl,(cp_tx) : ld (tx),hl : ld hl,(cp_ty) : ld (ty),hl
        ld a,(cp_tyf) : ld (tyf),a : ld a,(cp_face) : ld (tface),a
        ld hl,cp_srecs : ld de,srecs : ld bc,MAX_SLOW * SR_SIZE : ldir
        ld hl,cp_plats : ld de,plats : ld b,MAX_PLATS
.plat   push bc : ld bc,4 : ldir
        ex de,hl : ld bc,PLT_SIZE - 4 : add hl,bc : ex de,hl : pop bc
        djnz .plat
        ld a,255 : ld (cur_plat),a
        xor a : ld (save_cp),a
        ; (and on)

; Reset Trogg's movement state, and the moving objects (the state part of the
; BBC version's redraw_all)
reset_play
        xor a
        ld (tstate),a : ld (tclimb),a : ld (xvel),a : ld (anim),a : ld (dead),a : ld (won),a
        ld (ud_db),a : ld (lr_db),a : ld (yo_db),a : ld (yo_len),a : ld (yo_len+1),a
        ld (cmd_live),a
        ; no moving objects
        ld b,MAX_MOVERS
.mv     ld a,b : dec a : call mv_iy : ld (iy+M_ACTIVE),0
        djnz .mv
        jp commit_all

; A level's start, once it's loaded: its objects, Trogg, the timer and the
; moving things, saved as a checkpoint for a death before the first key (which
; isn't counted as a restart). Then reset_play.
level_init
        ld hl,alive : ld b,0
        ld a,(num_draw) : ld c,a
.obj    ld a,b : cp c : ld a,0 : jr nc,.gone
        inc a
.gone   ld (hl),a : inc hl
        inc b : ld a,b : cp MAX_OBJECTS : jr nz,.obj
        ; each thing's byte columns, for check_collisions' quick pass
        ld a,(num_draw) : or a : jr z,.no_draws
        ld b,a : ld ix,draws : ld hl,dcols : ld de,D_SIZE
.dcols  ld a,(ix+D_C0) : ld (hl),a : inc hl
        ld a,(ix+D_C1) : ld (hl),a : inc hl
        add ix,de : djnz .dcols
.no_draws
        xor a
        ld (keys_found),a : ld (gems_found),a : ld (have_cp),a : ld (save_cp),a : ld (restarts),a
        ld (bal_timer),a : ld (dag_timer),a
        ld hl,0 : ld (lvl_ticks),hl : ld (win_ticks),hl
        ld a,(vsyncs) : or 1 : ld (rng),a : ld a,#5A : ld (rng+1),a
        call slow_init
        ld hl,(trogg_x0) : ld (tx),hl
        ld hl,(trogg_y0) : ld (ty),hl
        xor a : ld (tface),a : ld (tyf),a : ld (tv),a
        call save_checkpoint
        jp reset_play

; Start of level: everything at its starting position
slow_init
        ld a,MAX_SLOW - 1 : ld (sl_i),a : call slow_last
.loop   ld b,0 : ld a,(num_slow) : ld c,a : ld a,(sl_i) : cp c : jr nc,.dead
        inc b
.dead   ld (iy+SR_ALIVE),b
        xor a : ld (iy+SR_XF),a : ld (iy+SR_YF),a
        ld a,(ix+S_X0L) : ld (iy+SR_XL),a : ld a,(ix+S_X0H) : ld (iy+SR_XH),a
        ld a,(ix+S_Y0L) : ld (iy+SR_YL),a : ld a,(ix+S_Y0H) : ld (iy+SR_YH),a
        ld a,(ix+S_VF) : ld (iy+SR_VF),a : ld a,(ix+S_VI) : ld (iy+SR_VI),a
        ld a,(ix+S_KIND) : cp SL_HOOTER : jr nz,.vel_ok
        xor a : ld (iy+SR_VF),a : ld (iy+SR_VI),a       ; Hooters start still, then jump
.vel_ok ld a,(ix+S_VY) : ld (iy+SR_VY),a
        ld a,(ix+S_WAIT) : ld (iy+SR_WAIT),a
        ld de,-S_SIZE : add ix,de : ld de,-SR_SIZE : add iy,de : ld hl,sl_i : dec (hl) : jp p,.loop
        ld ix,plats : ld b,MAX_PLATS : ld de,PLT_SIZE
.plat   ld a,(ix+PLT_X0L) : ld (ix+PLT_XL),a : ld a,(ix+PLT_X0H) : ld (ix+PLT_XH),a
        ld a,(ix+PLT_Y0L) : ld (ix+PLT_YL),a : ld a,(ix+PLT_Y0H) : ld (ix+PLT_YH),a
        add ix,de : djnz .plat
        ld a,255 : ld (cur_plat),a : ld (carry),a
        xor a : ld (dropped),a
        ret

; All the keys: the level is complete. Note the result for the records, and
; pause for 7 seconds, less one for each restart (as the Steam version)
level_complete
        ld a,TUNE_VICTORY : call play_music
        ld a,1 : ld (won),a
        xor a : ld (dead),a                     ; (a meanie touched earlier in this tick doesn't count)
        ld (bwon),a : ld (bwon+1),a
        ld a,(restarts) : cp 3 : jr c,.r
        ld a,3
.r      add a,a : ld e,a : ld d,0 : ld hl,win_len : add hl,de : call word_hl
        ld (win_ticks),hl
        ld a,(cur_level) : ld (done_level),a
        ld hl,(lvl_ticks) : ld (done_ticks),hl
        ld a,(restarts) : ld (done_restarts),a
        xor a : ld (done_gems),a
        ld a,(num_gems) : or a : jr z,.no_gems
        ld b,a : ld a,(gems_found) : cp b : jr c,.no_gems
        ld a,1 : ld (done_gems),a
.no_gems
        ld a,1 : ld (done_valid),a
        ret
win_len dw 7 * 50, 6 * 50, 5 * 50, 4 * 50

; ------------------------------------------------------------------------------
; The logic's variables (in this bank)
; ------------------------------------------------------------------------------
logic_vars
difficulty  db 1
snd_music_opt db 1
snd_sfx_req db #FF
snd_sfx_req2 db #FF
snd_cur     db 0
snd_music_req db 0
cmd_live    db 0
k_left      db 0                    ; the keys held this tick (real, or held by a command)
k_right     db 0
k_up        db 0
k_down      db 0
k_yoyo      db 0
cmd_q       DEFS CMD_QUEUE          ; the commands queue: 0-5 L R U D J Y, 6-15 the digits
cmd_qh      db 0                    ; its head and tail
cmd_qt      db 0
cmd_held    DEFS 16                 ; the command keys down last tick
cmd_cl      dw 0                    ; ticks left for the command (currentcount)
cmd_nl      dw 0                    ; the count being typed (nextcount)
o_keys      db 0                    ; the keys the command holds (O_)
cmd_f       db 0
cmd_t       db 0
cmd_i       db 0
cmd_kp      dw 0
cmd_rescan  db 1
keys_last   DEFS 10                 ; the keyboard last tick
cmd_sv      DEFS 8                  ; cmd_pre: where Trogg was (SV_)
cmd_ud      db 0                    ; ... and his debounces
cmd_lr      db 0
last_px     dw 0                    ; where Trogg's platform was last tick
last_py     dw 0
yo_len      dw 0                    ; the yoyo's string: tenths, then pixels
yo_turn     db 0
yo_db       db 0
yo_x        dw 0
yo_y        dw 0
yo_hit      db 0
yb_l        dw 0                    ; the yoyo's box
yb_r        dw 0
yb_t        dw 0
box_img     db 0
box_r       dw 0
lm_v        db 0
lm_x        dw 0
lm_y        dw 0
lm_img      db 0
fm_i        db 0
mv_i        db 0
mvc_i       db 0
co_i        db 0
sl_i        db 0
pk_i        db 0
pm_i        db 0
pm_j        db 0
sp_mid      dw 0                    ; spawning a balloon or dagger
sp_spread   dw 0
sp_x        dw 0
sp_h        db 0
rng         dw 1
rl_img      db 0                    ; relevant's workings
rl_l        dw 0
rl_r        dw 0
rl_a        db 0
ct_img      db 0                    ; collisions' workings
ct_l        dw 0
ct_t        dw 0
ct_c0       db 0
ct_c1       db 0
c_dx        db 0
c_dy        db 0
c_dxb       db 0
c_dyb       db 0
c_oimg      db 0
c_rs        db 0
c_rows      db 0
c_tl        db 0
ht_t        db 0
ht_u        db 0
to_y        dw 0
lvl_ticks   dw 0
; the frame loop's (see play.asm)
scrollcol   db 0                    ; the back buffer's scroll position
scrollrow   db 0
view_col    db 0                    ; where the view is (going)
view_row    db 0
col_max     db 0
newcol      db 0
newrow      db 0
scroll_dir  db 0
bs_n        db 0
frame_ticks db 2
ticks_left  db 0
last_flip   db 0
bscroll     db 0, 0                 ; each buffer's scroll position
brow        db 0, 0
bfrak       db 0, 0                 ; each buffer shows the FRAK! bubble
win_cols    db 64                   ; the window: byte columns, lines (0: 256), rows
win_lines   db 0
win_rows    db 32
win_w128    dw 256 + 128            ; (its width in pixels + 128)
mv_left     dw 0
save_end    dw 0
t_part_b    db 0
rd_i        db 0
ds_i        db 0
dm_i        db 0
pc_c        db 0
pc_col      db 0
pc_end      db 0
rr_c0       db 0                    ; repaint_rect's cells
rr_c1       db 0
rr_k0       db 0
rr_k1       db 0
rr_i        db 0
dm_c0       db 0                    ; damage to note
dm_c1       db 0
dm_y0       db 0
dm_y1       db 0
dmg_n       db 0
dmg_all     db 0
nr_c0       db 0                    ; slow_rect's answer
nr_c1       db 0
nr_y0       db 0
nr_y1       db 0
sr_top      dw 0
sr_bot      dw 0
hud_secs    dw #FFFF                ; the time the timer image shows
time_text   DEFS 4                  ; ... as "m:ss"
spr_i       db 0
frames_drawn dw 0                   ; (for the frame rate)
font_digits DEFS 11 * 8             ; the font's 0-9 and colon (copy_font)
win_ticks   dw 0
have_cp     db 0
save_cp     db 0
restarts    db 0
done_valid  db 0
done_level  db 0
done_ticks  dw 0
done_restarts db 0
done_gems   db 0
bwon        db 0, 0
pend_lo     db #FF, #FF             ; the columns to repaint in each buffer: [pend_lo, pend_hi)
pend_hi     db 0, 0
; what a checkpoint saves (cp_keys has the CP_VARS bytes from keys_found; Trogg's
; position and facing, in the low RAM, are copied one by one)
keys_found  db 0
gems_found  db 0
carry       db 255                  ; the platform Trogg's carrying (255: none)
dropped     db 0
bal_timer   db 0
dag_timer   db 0
CP_VARS = $ - keys_found
alive       DEFS MAX_OBJECTS        ; things to draw that haven't been collected or knocked off
srecs       DEFS MAX_SLOW * SR_SIZE
movers      DEFS MAX_MOVERS * M_SIZE
cp_keys     DEFS CP_VARS
cp_tx       dw 0
cp_ty       dw 0
cp_tyf      db 0
cp_face     db 0
cp_alive    DEFS MAX_OBJECTS
cp_srecs    DEFS MAX_SLOW * SR_SIZE
cp_plats    DEFS MAX_PLATS * 4
clist       DEFS MAX_SLOW * 5           ; the moving meanies to collide with (build_clist)
clist_n     db 0
clist_dirty db 1
cl_ptr      dw 0
dcols       DEFS MAX_DRAW * 2       ; each thing drawn's byte columns: c0, c1 (level_init)
dmg_list    DEFS MAX_DMG * 4        ; damage this frame: byte columns c0, c1, 4-line rows y0, y1
n_vis       DEFS MAX_SLOW           ; draw_slow's: each slow sprite in the window
n_chg       DEFS MAX_SLOW           ; ... and moved
drecs       DEFS 2 * MAX_SLOW * DR_SIZE     ; where each buffer drew each slow sprite
end_logic_bank
