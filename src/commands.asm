\ ------------------------------------------------------------------------------
\ Typed movement commands (port of the Steam version's command queue,
\ troggProcessCommandQueue, UpdateKeyOverrides and StopKeyOverrides)
\
\ L R U D J Y (left, right, up, down, jump, yoyo), after an optional count typed
\ as digits, are queued as they're pressed. Whenever no key is held (neither
\ really nor by a command), the next one is taken off the queue and holds the
\ keys down for it: for the count's ticks, or until Trogg gets where it was
\ going. Without a count, L and R walk to the end of the platform, U and D climb
\ to the end of a ladder (U from standing jumps, or steps onto a ladder), J
\ jumps the way he faces, and Y holds the yoyo key. L or R facing the other way
\ just turns him round. Holding a real key stops a command.
\
\ In JIT_BANK, called through call5: cmd_keys from read_keys, and cmd_pre and
\ cmd_post either side of trogg_move.
\ ------------------------------------------------------------------------------

O_LEFT  = 1                         \ o_keys: the keys a command holds down
O_RIGHT = 2                         \ (in the order of k_left .. k_yoyo)
O_UP    = 4
O_DOWN  = 8
O_YOYO  = 16
CMD_FIRST = 1                       \ cmd_f: a command started this tick
CMD_JUMP  = 2                       \ ... and it was a jump (U standing, or J)
CMD_QUEUE = 16                      \ (a power of 2)

ASSERT k_yoyo = k_left + 4
ASSERT tv = tx + 9                  \ (cmd_pre's snapshot: tx .. tv)
SV_TY = 2 : SV_TYF = 4 : SV_STATE = 5
ASSERT ty = tx + SV_TY AND tyf = tx + SV_TYF AND tstate = tx + SV_STATE

\ Internal key numbers of L R U D J Y, then 0-9
.cmd_codes  EQUB 86, 51, 53, 50, 69, 68, 39, 48, 49, 17, 18, 19, 52, 36, 21, 38
.cmd_jump   EQUW cmd_left, cmd_right, cmd_up, cmd_down, cmd_jumpk, cmd_yoyo

.cmd_keys
{
    stz cmd_f
    lda cmd_live : bne live
    \ (the level starting or restarting: an empty queue, no count, and no keys
    \ queued that were held through it)
    stz cmd_qh : stz cmd_qt : stz o_keys : stz cmd_cl : stz cmd_ch : stz cmd_nl : stz cmd_nh
    ldx #15 : lda #1
.held
    sta cmd_held,x : dex : bpl held
    sta cmd_live
.live
    \ The real keys held (bits as o_keys). Pressing one stops a command, and
    \ (as releasing it does in the Steam version) lets go of that key.
    lda #0 : ldx #4
.phys
    asl a : ora k_left,x : dex : bpl phys
    tay : sta cmd_t
    beq no_phys
    jsr cmd_stop
    lda cmd_t : eor #&FF : and o_keys : sta o_keys
.no_phys
    \ UpdateKeyOverrides: count down, letting go at 0
    lda cmd_cl : ora cmd_ch : beq counted
    lda cmd_cl : bne c1 : dec cmd_ch : .c1 : dec cmd_cl
    lda cmd_cl : ora cmd_ch : bne counted
    stz o_keys
.counted
    \ Queue the command keys just pressed
    ldy #15
.scan
    lda cmd_codes,y
    sei : jsr snd_key : cli         \ (A = 1 if down; X lost)
    cmp cmd_held,y : beq next
    sta cmd_held,y
    tax : beq next
    ldx cmd_qt : txa : inc a : and #CMD_QUEUE - 1
    cmp cmd_qh : beq next           \ (full)
    sta cmd_qt
    tya : sta cmd_q,x
.next
    dey : bpl scan

    \ The next command, if no key is held
    lda cmd_t : ora o_keys : bne hold
    ldx cmd_qh : cpx cmd_qt : beq hold
    lda cmd_q,x
    cmp #2 : bcs take               \ (L and R wait while he falls)
    ldy tstate : cpy #ST_FALL : beq hold
.take
    pha
    txa : inc a : and #CMD_QUEUE - 1 : sta cmd_qh
    pla
    cmp #6 : bcs digit
    asl a : tax
    jmp (cmd_jump,x)

.digit
    sbc #6 : pha                    \ (carry set) the next count = count * 10 + digit
    lda cmd_nl : ldx cmd_nh
    asl cmd_nl : rol cmd_nh : asl cmd_nl : rol cmd_nh
    clc : adc cmd_nl : sta cmd_nl : txa : adc cmd_nh : sta cmd_nh
    asl cmd_nl : rol cmd_nh
    pla : clc : adc cmd_nl : sta cmd_nl : bcc hold : inc cmd_nh
    bra hold

\ Each command ends here
.^cmd_done
    lda #CMD_FIRST : tsb cmd_f
.^cmd_turned
    stz cmd_nl : stz cmd_nh
.hold
    \ the keys the command holds down
    lda o_keys : sta cmd_t : ldx #0
.keys
    lsr cmd_t : bcc not_held
    lda #1 : sta k_left,x
.not_held
    inx : cpx #5 : bne keys
    rts
}

\ L: facing right, standing or walking, he turns round; otherwise walks left
\ (for the count, or 1000 ticks)
.cmd_left
{
    lda tstate : cmp #ST_FALL : bcs go
    lda tface : bne go
    inc tface : bra cmd_turned
.go
    lda #LO(1000) : ldy #HI(1000) : jsr cmd_count
    lda #O_LEFT
}
.cmd_hold
    sta o_keys : bra cmd_done

\ R: as L, but for the count or 1000000 ticks (in effect, until he stops)
.cmd_right
{
    lda tstate : cmp #ST_FALL : bcs go
    lda tface : beq go
    stz tface : bra cmd_turned
.go
    jsr cmd_forever
    lda #O_RIGHT : bra cmd_hold
}

\ U: standing or walking, jump straight up (or step onto a ladder); otherwise
\ hold up (for the count)
.cmd_up
{
    lda tstate : cmp #ST_FALL : bcs go
    lda #CMD_JUMP : tsb cmd_f
    lda #O_UP : bra cmd_hold
.go
    jsr cmd_forever
    lda #O_UP : bra cmd_hold
}

\ D: standing or walking, hold down for 3 ticks (onto a ladder below);
\ otherwise for the count
.cmd_down
{
    lda tstate : cmp #ST_FALL : bcs go
    lda #3 : sta cmd_cl : stz cmd_ch
    bra down
.go
    jsr cmd_forever
.down
    lda #O_DOWN : bra cmd_hold
}

\ J: standing or walking, jump the way he faces
.cmd_jumpk
{
    lda tstate : cmp #ST_FALL : bcs done
    lda #CMD_JUMP : tsb cmd_f
    lda tface : beq right
    lda #O_UP + O_LEFT : bra cmd_hold
.right
    lda #O_UP + O_RIGHT : bra cmd_hold
.done
    jmp cmd_done
}

\ Y: hold the yoyo key (for the count)
.cmd_yoyo
    jsr cmd_forever
    lda #O_YOYO : bra cmd_hold

\ The count: as typed, or else YA
.cmd_forever
    lda #&FF : tay                  \ (1000000 there: 65535 here is as good)
.cmd_count
{
    ldx cmd_nl : bne typed
    ldx cmd_nh : bne typed
    sta cmd_cl : sty cmd_ch
    rts
.typed
    lda cmd_nl : sta cmd_cl : lda cmd_nh : sta cmd_ch
    rts
}

\ StopKeyOverrides: if counting, stop, letting go of the keys
.cmd_stop
{
    lda cmd_cl : ora cmd_ch : beq done
    stz cmd_cl : stz cmd_ch : stz o_keys
.done
    rts
}

\ Before Trogg moves: remember where he is, and his debounces
.cmd_pre
{
    ldx #9
.copy
    lda tx,x : sta cmd_sv,x : dex : bpl copy
    lda ud_db : sta cmd_ud : lda lr_db : sta cmd_lr
    rts
}

\ After he moves: what the Steam version's troggMove does about commands
.cmd_post
{
    ldx cmd_sv + SV_STATE           \ (the state he was in)
    cpx #ST_YOYO_OUT : bcs done
    \ a command never leaves a debounce behind it
    lda cmd_cl : ora cmd_ch : beq no_count
    lda cmd_ud : sta ud_db : lda cmd_lr : sta lr_db
.no_count
    cpx #ST_FALL : beq from_fall : bcs from_climb

    \ Standing or walking. A counted command never takes him off a ledge, nor
    \ (unless it's a jump) onto a ladder.
    lda tstate : cmp #ST_FALL : beq s_fall
    cmp #ST_CLIMB : bne done
    lda cmd_f : and #CMD_JUMP : bne s_climb
    jsr can_cancel : bcs cancel
.s_climb
    jsr cmd_stop
    lda cmd_f : cmp #CMD_FIRST + CMD_JUMP : beq let_go
    rts
.s_fall
    jsr can_cancel : bcs cancel
    lda cmd_f : and #CMD_JUMP : beq stop
.let_go
    lda o_keys : and #O_YOYO : sta o_keys
.stop
    jmp cmd_stop
.cancel
    jsr restore
    stz cmd_cl : stz cmd_ch
    bra let_go

.from_fall
    lda tstate : beq stop           \ landed
    cmp #ST_CLIMB : beq stop        \ caught a ladder
.done
    rts

.from_climb
    \ A counted climb that gets nowhere (at the top of a ladder) stops
    lda cmd_cl : ora cmd_ch : beq c_off
    lda xmove : bne c_off
    lda ymove : beq c_off
    lda tstate : beq c_off
    lda ty : cmp cmd_sv + SV_TY : bne c_off
    lda ty+1 : cmp cmd_sv + SV_TY + 1 : bne c_off
    lda tyf : cmp cmd_sv + SV_TYF : bne c_off
    jsr restore
    bra stop
.c_off
    lda tstate : beq stop           \ off the ladder
    cmp #ST_FALL : beq stop
    rts
    \ (The Steam version also stops a counted climb that falls off without moving
    \ sideways or asking for a debounce, but every such fall asks for one.)

\ Carry set if counting, and not on the command's first tick
.can_cancel
    clc
    lda cmd_cl : ora cmd_ch : beq no
    lda cmd_f : eor #CMD_FIRST : lsr a
.no
    rts

\ Back where he was, still
.restore
    ldx #9
.copy
    lda cmd_sv,x : sta tx,x : dex : bpl copy
    stz xvel : stz tv
    rts
}

.cmd_q      SKIP CMD_QUEUE          \ the queue: 0-5 L R U D J Y, 6-15 the digits
.cmd_qh     SKIP 1                  \ its head and tail
.cmd_qt     SKIP 1
.cmd_held   SKIP 16                 \ the command keys down last tick
.cmd_cl     SKIP 1                  \ ticks left for the command (currentcount)
.cmd_ch     SKIP 1
.cmd_nl     SKIP 1                  \ the count being typed (nextcount)
.cmd_nh     SKIP 1
.o_keys     SKIP 1
.cmd_f      SKIP 1
.cmd_t      SKIP 1
.cmd_sv     SKIP 10                 \ (cmd_pre: tx .. tv)
.cmd_ud     SKIP 1
.cmd_lr     SKIP 1
