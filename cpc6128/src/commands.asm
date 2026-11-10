; The keys, and the typed movement commands: a port of the BBC version's
; read_keys and its commands.asm (itself a port of the Steam version's command
; queue, troggProcessCommandQueue, UpdateKeyOverrides and StopKeyOverrides).
;
; The keys: Z or cursor left, X or cursor right, O or cursor up, K or cursor
; down, P or Space for the yoyo; Esc for the menus.
;
; L R U D J Y (left, right, up, down, jump, yoyo), after an optional count typed
; as digits, are queued as they're pressed. Whenever no key is held (neither
; really nor by a command), the next one is taken off the queue and holds the
; keys down for it: for the count's ticks, or until Trogg gets where it was
; going. Without a count, L and R walk to the end of the platform, U and D climb
; to the end of a ladder (U from standing jumps, or steps onto a ladder), J
; jumps the way he faces, and Y holds the yoyo key. L or R facing the other way
; just turns him round. Holding a real key stops a command and empties the queue.

O_LEFT = 1 : O_RIGHT = 2 : O_UP = 4 : O_DOWN = 8 : O_YOYO = 16  ; o_keys: the keys a command holds
CMD_FIRST = 1                       ; cmd_f: a command started this tick
CMD_JUMP = 2                        ; ... and it was a jump (U standing, or J)
CMD_QUEUE = 16                      ; (a power of 2)
SV_TX = 0 : SV_TY = 2 : SV_TYF = 4 : SV_STATE = 5 : SV_FACE = 6 : SV_CLIMB = 7  ; cmd_sv

; The keys held this tick -> xmove, ymove and doyoyo, with their debounces
read_keys
        ld a,KEY_Z : ld b,KEY_LEFT : call either : ld (k_left),a
        ld a,KEY_X : ld b,KEY_RIGHT : call either : ld (k_right),a
        ld a,KEY_O : ld b,KEY_UP : call either : ld (k_up),a
        ld a,KEY_K : ld b,KEY_DOWN : call either : ld (k_down),a
        ld a,KEY_P : ld b,KEY_SPACE : call either : ld (k_yoyo),a
        ; the typed commands (L R U D J Y) hold keys down too
        call cmd_keys
        ; doyoyo, with debounce: after the yoyo comes back, the key must be released
        ld a,(yo_db) : or a : jr z,.yo_live
        xor a : ld (doyoyo),a
        ld a,(k_yoyo) : or a : jr nz,.yo_done
        ld (yo_db),a : jr .yo_done
.yo_live
        ld a,(k_yoyo) : ld (doyoyo),a
.yo_done
        ; ymove (+1 = up), with debounce after landing or climbing
        ld a,(ud_db) : or a : jr z,.ud_live
        xor a : ld (ymove),a
        ld a,(k_up) : ld b,a : ld a,(k_down) : or b : jr nz,.ud_done
        ld (ud_db),a : jr .ud_done
.ud_live
        ld a,(k_down) : ld b,a : ld a,(k_up) : sub b : ld (ymove),a
.ud_done
        ld a,(lr_db) : or a : jr z,.lr_live
        xor a : ld (xmove),a
        ld a,(k_left) : ld b,a : ld a,(k_right) : or b : ret nz
        ld (lr_db),a : ret
.lr_live
        ld a,(k_left) : ld b,a : ld a,(k_right) : sub b : ld (xmove),a
        ret
; A = 1 if key A or key B is down, else 0
either  push bc : call key_pressed : pop bc
        ld c,a : ld a,b : call key_pressed
        or c : ret

; Internal key numbers of L R U D J Y, then 0-9
cmd_codes db KEY_L, KEY_R, KEY_U, KEY_D, KEY_J, KEY_Y
          db KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9
cmd_vecs  dw cmd_left, cmd_right, cmd_up, cmd_down, cmd_jumpk, cmd_yoyo

cmd_keys
        xor a : ld (cmd_f),a
        ld a,(cmd_live) : or a : jr nz,.live
        ; (the level starting or restarting: an empty queue, no count, and no keys
        ; queued that were held through it)
        xor a : ld (cmd_qh),a : ld (cmd_qt),a : ld (o_keys),a
        ld hl,0 : ld (cmd_cl),hl : ld (cmd_nl),hl
        ld hl,cmd_held : ld b,16 : ld a,1
.held   ld (hl),a : inc hl : djnz .held
        ld (cmd_live),a
.live   ; The real keys held. Pressing one stops any command, and empties the queue.
        ld hl,k_yoyo : ld b,5 : xor a
.phys   add a,a : or (hl) : dec hl : djnz .phys
        ld (cmd_t),a
        or a : jr z,.no_phys
        ld hl,0 : ld (cmd_cl),hl : ld (cmd_nl),hl
        xor a : ld (o_keys),a
        ld a,(cmd_qt) : ld (cmd_qh),a
.no_phys
        ; UpdateKeyOverrides: count down, letting go at 0
        ld hl,(cmd_cl) : ld a,h : or l : jr z,.counted
        dec hl : ld (cmd_cl),hl
        ld a,h : or l : jr nz,.counted
        ld (o_keys),a
.counted
        ; Queue the command keys just pressed
        ld a,15 : ld (cmd_i),a
.scan   ld hl,cmd_codes : call look : call key_pressed : ld c,a
        ld a,(cmd_i) : ld hl,cmd_held : add a,l : ld l,a : jr nc,.nc1
        inc h
.nc1    ld a,c : cp (hl) : jr z,.next
        ld (hl),a
        or a : jr z,.next
        ld a,(cmd_qt) : ld b,a : inc a : and CMD_QUEUE - 1
        ld hl,cmd_qh : cp (hl) : jr z,.next     ; (full)
        ld (cmd_qt),a
        ld a,b : ld hl,cmd_q : add a,l : ld l,a : jr nc,.nc2
        inc h
.nc2    ld a,(cmd_i) : ld (hl),a
.next   ld a,(cmd_i) : dec a : ld (cmd_i),a : jp p,.scan

        ; The next command, if no key is held
        ld a,(o_keys) : ld hl,cmd_t : or (hl) : jr nz,cmd_apply
        ld a,(cmd_qt) : ld b,a : ld a,(cmd_qh) : cp b : jr z,cmd_apply
        ld b,a : ld hl,cmd_q : call look
        cp 2 : jr c,.wait                       ; (L, R and J wait while he falls: the
        cp 4 : jr nz,.take                      ; original drops a J then, so a J typed
.wait   ld c,a                                  ; while getting off a ladder was lost)
        ld a,(tstate) : cp ST_FALL : jr z,cmd_apply
        ld a,c
.take   ld c,a
        ld a,b : inc a : and CMD_QUEUE - 1 : ld (cmd_qh),a
        ld a,c : cp 6 : jr nc,.digit
        add a,a : ld e,a : ld d,0 : ld hl,cmd_vecs : add hl,de
        call word_hl : jp (hl)
.digit  ; the next count = count * 10 + digit
        sub 6 : ld c,a : ld b,0
        ld hl,(cmd_nl) : add hl,hl : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de
        add hl,bc : ld (cmd_nl),hl
        jr cmd_apply

; Each command ends here. Its keys are pressed afresh (typing it, they were let
; go), so no debounce holds them back.
cmd_done
        ld hl,cmd_f : set 0,(hl)                ; (CMD_FIRST)
        xor a : ld (ud_db),a : ld (lr_db),a : ld (yo_db),a
cmd_turned
        ld hl,0 : ld (cmd_nl),hl
cmd_apply
        ; the keys the command holds down
        ld a,(o_keys) : ld hl,k_left : ld b,5
.keys   rrca : jr nc,.not_held
        ld (hl),1
.not_held
        inc hl : djnz .keys
        ret

; L: facing right, standing or walking, he turns round; otherwise walks left
; (for the count, or 1000 ticks)
cmd_left
        ld a,(tstate) : cp ST_FALL : jr nc,.go
        ld a,(tface) : or a : jr nz,.go
        inc a : ld (tface),a : jr cmd_turned
.go     ld hl,1000 : call cmd_count
        ld a,O_LEFT
cmd_hold
        ld (o_keys),a : jr cmd_done

; R: as L, but for the count or 65535 ticks (in effect, until he stops)
cmd_right
        ld a,(tstate) : cp ST_FALL : jr nc,.go
        ld a,(tface) : or a : jr z,.go
        xor a : ld (tface),a : jr cmd_turned
.go     call cmd_forever
        ld a,O_RIGHT : jr cmd_hold

; U: standing or walking, jump straight up (or step onto a ladder); otherwise
; hold up (for the count)
cmd_up
        ld a,(tstate) : cp ST_FALL : jr nc,.go
        ld hl,cmd_f : set 1,(hl)                ; (CMD_JUMP)
        ld a,O_UP : jr cmd_hold
.go     call cmd_forever
        ld a,O_UP : jr cmd_hold

; D: standing or walking, hold down for 3 ticks (onto a ladder below);
; otherwise for the count
cmd_down
        ld a,(tstate) : cp ST_FALL : jr nc,.go
        ld hl,3 : ld (cmd_cl),hl
        jr .down
.go     call cmd_forever
.down   ld a,O_DOWN : jr cmd_hold

; J: standing or walking, jump the way he faces
cmd_jumpk
        ld a,(tstate) : cp ST_FALL : jp nc,cmd_done
        ld hl,cmd_f : set 1,(hl)
        ld a,(tface) : or a : ld a,O_UP + O_RIGHT : jr z,cmd_hold
        ld a,O_UP + O_LEFT : jr cmd_hold

; Y: hold the yoyo key (for the count)
cmd_yoyo
        call cmd_forever
        ld a,O_YOYO : jr cmd_hold

; The count: as typed, or else HL
cmd_forever
        ld hl,#FFFF
cmd_count
        ld de,(cmd_nl) : ld a,d : or e : jr z,.set
        ex de,hl
.set    ld (cmd_cl),hl
        ret

; StopKeyOverrides: if counting, stop, letting go of the keys
cmd_stop
        ld hl,(cmd_cl) : ld a,h : or l : ret z
        ld hl,0 : ld (cmd_cl),hl
        xor a : ld (o_keys),a
        ret

; Before Trogg moves: remember where he is, and his debounces
cmd_pre
        ld hl,(tx) : ld (cmd_sv + SV_TX),hl
        ld hl,(ty) : ld (cmd_sv + SV_TY),hl
        ld a,(tyf) : ld (cmd_sv + SV_TYF),a
        ld a,(tstate) : ld (cmd_sv + SV_STATE),a
        ld a,(tface) : ld (cmd_sv + SV_FACE),a
        ld a,(tclimb) : ld (cmd_sv + SV_CLIMB),a
        ld a,(ud_db) : ld (cmd_ud),a
        ld a,(lr_db) : ld (cmd_lr),a
        ret

; ... back where he was, still
cmd_restore
        ld hl,(cmd_sv + SV_TX) : ld (tx),hl
        ld hl,(cmd_sv + SV_TY) : ld (ty),hl
        ld a,(cmd_sv + SV_TYF) : ld (tyf),a
        ld a,(cmd_sv + SV_STATE) : ld (tstate),a
        ld a,(cmd_sv + SV_FACE) : ld (tface),a
        ld a,(cmd_sv + SV_CLIMB) : ld (tclimb),a
        xor a : ld (xvel),a : ld (tv),a
        ret

; After he moves: what the Steam version's troggMove does about commands
cmd_post
        ld a,(cmd_sv + SV_STATE) : ld c,a       ; (the state he was in)
        cp ST_YOYO_OUT : ret nc
        ; a command never leaves a debounce behind it
        ld hl,(cmd_cl) : ld a,h : or l : jr z,.no_count
        ld a,(cmd_ud) : ld (ud_db),a
        ld a,(cmd_lr) : ld (lr_db),a
.no_count
        ld a,c : cp ST_FALL : jr z,.from_fall : jr nc,.from_climb
        ; Standing or walking. A counted command never takes him off a ledge, nor
        ; (unless it's a jump) onto a ladder.
        ld a,(tstate) : cp ST_FALL : jr z,.s_fall
        cp ST_CLIMB : ret nz
        ld a,(cmd_f) : and CMD_JUMP : jr nz,.s_climb
        call can_cancel : jr c,.cancel
.s_climb
        call cmd_stop
        ld a,(cmd_f) : cp CMD_FIRST + CMD_JUMP : jr z,.let_go
        ret
.s_fall call can_cancel : jr c,.cancel
        ld a,(cmd_f) : and CMD_JUMP : jr z,.stop
.let_go ld a,(o_keys) : and O_YOYO : ld (o_keys),a
.stop   jp cmd_stop
.cancel call cmd_restore
        ld hl,0 : ld (cmd_cl),hl
        jr .let_go
.from_fall
        ld a,(tstate) : or a : jr z,.stop       ; landed
        cp ST_CLIMB : jr z,.stop                ; caught a ladder
        ret
.from_climb
        ; A counted climb that gets nowhere (at the top of a ladder) stops
        ld hl,(cmd_cl) : ld a,h : or l : jr z,.c_off
        ld a,(xmove) : or a : jr nz,.c_off
        ld a,(ymove) : or a : jr z,.c_off
        ld a,(tstate) : or a : jr z,.c_off
        ld hl,(ty) : ld de,(cmd_sv + SV_TY) : or a : sbc hl,de : jr nz,.c_off
        ld a,(cmd_sv + SV_TYF) : ld b,a : ld a,(tyf) : cp b : jr nz,.c_off
        call cmd_restore
        jr .stop
.c_off  ld a,(tstate) : or a : jr z,.stop       ; off the ladder
        cp ST_FALL : jr z,.stop
        ret

; Carry set if counting, and not on the command's first tick
can_cancel
        ld hl,(cmd_cl) : ld a,h : or l : ret z  ; (carry clear)
        ld a,(cmd_f) : xor CMD_FIRST : rra
        ret
