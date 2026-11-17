; Music and sound effects: for now (see ../PLAN.md, "Sound"), stubs with the CPC
; version's interface (../cpc6128/src/sound.asm), so the game's logic is as it
; is. The player itself, ported to Dave, comes after the first milestone.
;
; The game asks for things through the low RAM (see play_music and play_sfx in
; logic.asm): snd_music_req (a tune, 0 to stop; #FF none), snd_sfx_req and
; snd_sfx_req2 (sound effects, SFX_STOP to stop them), snd_music_opt (0 = all the
; tracks, 1 = just the first, 2 = off; M changes it) and snd_sfx_opt (0 = on,
; 1 = off; S changes it). snd_tick, from the vertical sync's interrupt, takes each
; request as the player would (and plays nothing), and the M and S keys change
; the options as they do on the CPC (the logic's footsteps depend on the music's).

snd_tick
        call snd_keys
        ld a,#FF : ld (snd_music_req),a
        ld a,#FF : ld (snd_sfx_req),a : ld (snd_sfx_req2),a
        ret

; M and S (as they go down) change the music and sound effects options
snd_keys
        ld a,(keys + (KEY_M >> 3)) : and 1 << (KEY_M & 7) : ld b,a
        jr z,.m_up
        ld a,(snd_m_last) : or a : jr nz,.m_up
        ld a,(snd_music_opt) : inc a : cp 3 : jr c,.m_ok
        xor a
.m_ok   ld (snd_music_opt),a
.m_up   ld a,b : ld (snd_m_last),a
        ld a,(keys + (KEY_S >> 3)) : and 1 << (KEY_S & 7) : ld b,a
        jr z,.s_up
        ld a,(snd_s_last) : or a : jr nz,.s_up
        ld a,(snd_sfx_opt) : xor 1 : ld (snd_sfx_opt),a
.s_up   ld a,b : ld (snd_s_last),a
        ret
