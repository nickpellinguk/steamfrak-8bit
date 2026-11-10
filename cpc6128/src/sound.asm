; ------------------------------------------------------------------------------
; Music and sound effects: a port of the BBC version's player (src/sound.asm), in
; extra bank 1 (SOUND_BANK), below the compiled meanie.
;
; snd_tick runs 50 times a second, from the vertical sync's interrupt (irq pages
; this bank in, after reading the keyboard). It plays the Steam version's tunes
; the way that does: each track's notes start on quarter beats, and each note has
; an amplitude envelope (attack, decay, sustain, release, from the BBC Micro style
; ENVELOPEs) and a pitch envelope, stepped every tick. Sound effects are notes on
; two more voices: a tone and a noise one. The tunes, instruments and envelopes
; are the BBC version's (tools/music.py's, src/gen/music.asm), so both play the
; same notes.
;
; The BBC's sound chip has three tone channels and a noise channel of its own; the
; CPC's AY-3-8912 has three channels, each of which can have the tone and the
; noise mixed in. So the noise voice (the noise sound effect, or else the drums)
; borrows a channel while it sounds: a free one, else the quietest. The tone
; voices share out the rest each tick as on the BBC (see snd_output). Pitches are
; the AY's dividers (its clock is 1MHz / 16 to the BBC chip's 4MHz / 32: half the
; BBC's, and 12 bits, so the tracks the BBC version plays an octave up for its
; chip's lowest note, trk_raised, go down again), loudness the AY's nearest level
; to the BBC's 2dB steps (att_vol).
;
; The game asks for things through the low RAM (see play_music and play_sfx in
; logic.asm): snd_music_req (a tune, 0 to stop; #FF none), snd_sfx_req and
; snd_sfx_req2 (sound effects, SFX_STOP to stop them), snd_music_opt (0 = all the
; tracks, 1 = just the first, 2 = off; M changes it) and snd_sfx_opt (0 = on,
; 1 = off; S changes it).
; ------------------------------------------------------------------------------

NV = MAX_TRACKS + 2                 ; voices: the tracks, then a tone and a noise sound effect
SFX_TONE = MAX_TRACKS
SFX_NOISE = MAX_TRACKS + 1
; A voice's fields: each an array of NV bytes in vtab, reached from IX = vtab +
; VOFF + the voice (so every field is in reach of IX's displacement)
VOFF = 9 * NV
V_ON = 0 * NV - VOFF : V_BASE = 1 * NV - VOFF : V_CHAN = 2 * NV - VOFF
V_ORDL = 3 * NV - VOFF : V_ORDH = 4 * NV - VOFF : V_ORD = 5 * NV - VOFF
V_PATL = 6 * NV - VOFF : V_PATH = 7 * NV - VOFF : V_LEFT = 8 * NV - VOFF
V_INS = 9 * NV - VOFF : V_SEMI = 10 * NV - VOFF : V_ENV = 11 * NV - VOFF
V_EPOS = 12 * NV - VOFF : V_AMPL = 13 * NV - VOFF : V_AMPH = 14 * NV - VOFF
V_PHASE = 15 * NV - VOFF : V_ATT = 16 * NV - VOFF                ; (phase: 0 off, 1 attack,
V_NL = 17 * NV - VOFF : V_NH = 18 * NV - VOFF                    ; 2 decay, 3 sustain, 4 release)
V_PL = 19 * NV - VOFF : V_PH = 20 * NV - VOFF                    ; (the pitch V_NL/V_NH are for)
V_PFLAT = 21 * NV - VOFF            ; (its note's pitch is worked out, and its pitch envelope flat)
V_FIELDS = 22
ASSERT V_PFLAT < 128

; A = table HL's entry E (D = 0)
MACRO TLOOK table
        ld hl,{table} : add hl,de : ld a,(hl)
MEND

; Channel N's registers, from the voice that has it (if any): its divider (or the noise
; period) and its volume, if they've changed, and its bits in the mixer (snd_mix)
MACRO CHANNEL n
        ld a,(snd_owner + {n}) : cp #FF : ld a,15 : jr z,@vol
        ld a,(snd_owner + {n}) : ld e,a : ld d,0 : ld ix,vtab + VOFF : add ix,de
        ld a,(snd_nch) : cp {n} : jr z,@noise
        ld a,(ix+V_NL) : ld hl,last_tp + 2 * {n} : cp (hl) : jr nz,@tp
        ld a,(ix+V_NH) : inc hl : cp (hl) : jr z,@tone
@tp     ld a,(ix+V_NL) : ld (last_tp + 2 * {n}),a : ld e,2 * {n} : call psg_write
        ld a,(ix+V_NH) : ld (last_tp + 2 * {n} + 1),a : ld e,2 * {n} + 1 : call psg_write
@tone   ld a,(snd_mix) : and (1 << {n}) ^ #FF : ld (snd_mix),a
        jr @att
@noise  ld e,(ix+V_INS) : ld d,0 : TLOOK ins_noise
        and 3 : ld e,a : TLOOK noise_period
        ld hl,last_np : cp (hl) : jr z,@nmix
        ld (hl),a : ld e,6 : call psg_write
@nmix   ld a,(snd_mix) : and (8 << {n}) ^ #FF : ld (snd_mix),a
@att    ld a,(ix+V_ATT)
@vol    ld e,a : ld d,0 : TLOOK att_vol
        ld hl,last_vol + {n} : cp (hl) : jr z,@same
        ld (hl),a : ld e,8 + {n} : call psg_write
@same
MEND

; One tick: requests and keys, then a quarter beat if one is due, then every voice
snd_tick
        call snd_keys
        ld a,(snd_music_req) : or a : jp m,.no_tune
        ld hl,snd_music_req : ld (hl),#FF
        call snd_start_tune
.no_tune
        ld a,(snd_sfx_req) : or a : jp m,.no_sfx
        ld hl,snd_sfx_req : ld (hl),#FF
        call snd_start_sfx
.no_sfx
        ld a,(snd_sfx_req2) : or a : jp m,.no_sfx2
        ld hl,snd_sfx_req2 : ld (hl),#FF
        call snd_start_sfx
.no_sfx2
        ; sound effects are released after their length
        ld ix,vtab + VOFF + SFX_TONE : call .sfx_len
        ld ix,vtab + VOFF + SFX_NOISE : call .sfx_len
        ; quarter beats
        ld a,(snd_tune) : or a : jr z,.no_qb
        ld hl,(snd_acc) : ld de,(snd_k) : add hl,de : ld (snd_acc),hl
        call c,snd_quarter_beat
.no_qb
        ld ix,vtab + VOFF + NV - 1 : ld b,NV
.voices ld a,(ix+V_PHASE) : or a : jr z,.silent ; (a silent voice's attenuation is 15 already)
        push bc : call snd_voice : pop bc
.silent dec ix : djnz .voices
        jp snd_output
.sfx_len
        ld a,(ix+V_LEFT) : or a : ret z
        dec (ix+V_LEFT) : ret nz
        jp snd_release

; IX = voice A (BC, DE kept)
voice_ix
        ld ix,vtab + VOFF
        push bc : ld c,a : ld b,0 : add ix,bc : pop bc
        ret

; M and S (as they go down) change the music and sound effects options
snd_keys
        ld a,(keys + (KEY_M >> 3)) : and 1 << (KEY_M & 7) : ld b,a
        jr z,.m_up
        ld a,(snd_m_last) : or a : jr nz,.m_up
        ld a,(snd_music_opt) : inc a : cp 3 : jr c,.m_ok
        xor a
.m_ok   ld (snd_music_opt),a
        push bc : call snd_masks : pop bc
.m_up   ld a,b : ld (snd_m_last),a
        ld a,(keys + (KEY_S >> 3)) : and 1 << (KEY_S & 7) : ld b,a
        jr z,.s_up
        ld a,(snd_s_last) : or a : jr nz,.s_up
        ld a,(snd_sfx_opt) : xor 1 : ld (snd_sfx_opt),a
        push bc : call snd_stop_sfx : pop bc
.s_up   ld a,b : ld (snd_s_last),a
        ret

; Start tune A (0: silence)
snd_start_tune
        ld (snd_tune),a
        ld b,MAX_TRACKS - 1
.off    ld a,b : call voice_ix
        call snd_silence : ld (ix+V_ON),0
        dec b : jp p,.off
        ld a,(snd_tune) : or a : jp z,snd_masks
        ld e,a : ld d,0
        TLOOK tune_k_lo : ld (snd_k),a
        TLOOK tune_k_hi : ld (snd_k + 1),a
        TLOOK tune_total_lo : ld (snd_total),a
        TLOOK tune_total_hi : ld (snd_total + 1),a
        TLOOK tune_intro_lo : ld (snd_intro),a
        TLOOK tune_intro_hi : ld (snd_intro + 1),a
        ld hl,#FFFF : ld (snd_acc),hl           ; (so the first tick starts a quarter beat)
        ld hl,0 : ld (snd_qb),hl
        ld b,0
.tracks ld a,b : call voice_ix
        call track_row                          ; E = the track's row
        ld (ix+V_ON),1
        TLOOK trk_ins : ld (ix+V_BASE),a
        TLOOK trk_chan : ld c,a
        TLOOK trk_raised : rrca : or c : ld (ix+V_CHAN),a     ; (bit 7: played an octave down)
        TLOOK trk_order_lo : ld (ix+V_ORDL),a
        TLOOK trk_order_hi : ld (ix+V_ORDH),a
        ld (ix+V_ORD),0
        call snd_to_end
        inc b
        ld a,(snd_tune) : ld e,a : TLOOK tune_ntracks
        cp b : jr nz,.tracks
        jp snd_masks

; E = the row of the tune's track B (D = 0)
track_row
        ld a,(snd_tune) : ld e,a : ld d,0
        TLOOK tune_first
        add a,b : ld e,a
        ret

; Voice IX: silent, with nothing playing
snd_silence
        xor a
        ld (ix+V_PHASE),a : ld (ix+V_AMPL),a : ld (ix+V_AMPH),a : ld (ix+V_LEFT),a
        ld (ix+V_ATT),15
        ret

; Track IX: at the end of a pattern (so it starts the next in its order)
snd_to_end
        ld (ix+V_PATL),end_byte & 255 : ld (ix+V_PATH),end_byte >> 8
        ret
end_byte db PAT_END

; Voice IX: start its note (the attack)
snd_trigger
        xor a : ld (ix+V_EPOS),a : ld (ix+V_AMPL),a : ld (ix+V_AMPH),a : ld (ix+V_PFLAT),a
        ld (ix+V_PHASE),1
        ret

; Voice IX: let its note go (the release), if it's sounding
snd_release
        ld a,(ix+V_PHASE) : or a : ret z
        cp 4 : ret z
        ld (ix+V_PHASE),4
        ret

; Sound effect A (SFX_STOP: stop them)
snd_start_sfx
        cp SFX_STOP : jr z,snd_stop_sfx
        ld c,a
        ld a,(snd_sfx_opt) : or a : ret nz
        ld e,c : ld d,0
        TLOOK sfx_ins : ld (snd_tmp),a
        push de : ld e,a : TLOOK ins_noise : pop de
        or a : ld a,SFX_TONE : jr z,.tone
        ld a,SFX_NOISE
.tone   call voice_ix
        ld a,(snd_tmp) : ld (ix+V_INS),a
        TLOOK sfx_semi : ld (ix+V_SEMI),a
        TLOOK sfx_env : ld (ix+V_ENV),a
        TLOOK sfx_len : ld (ix+V_LEFT),a
        jp snd_trigger
snd_stop_sfx
        ld ix,vtab + VOFF + SFX_TONE : call snd_silence
        ld ix,vtab + VOFF + SFX_NOISE : jp snd_silence

; A quarter beat: each track's next note, if its last one is over. At the end of
; the tune it goes round again, from the end of its introduction.
snd_quarter_beat
        ld hl,(snd_qb) : ld de,(snd_total) : or a : sbc hl,de : jr c,.go
        ld hl,(snd_intro) : ld (snd_qb),hl
        ld b,0
.again  ld a,b : call voice_ix
        ld a,(ix+V_ON) : or a : jr z,.again_next
        call snd_silence
        call track_row : TLOOK trk_loop : ld (ix+V_ORD),a
        call snd_to_end
.again_next
        inc b : ld a,b : cp MAX_TRACKS : jr nz,.again
.go     ld hl,(snd_qb) : inc hl : ld (snd_qb),hl
        ld ix,vtab + VOFF + MAX_TRACKS - 1 : ld b,MAX_TRACKS
.tracks ld a,(ix+V_ON) : or a : call nz,snd_track_step
        dec ix : djnz .tracks
        ret

; Track IX, at a quarter beat (B kept)
snd_track_step
        ld a,(ix+V_LEFT) : or a : jr z,.fetch
        dec (ix+V_LEFT)
        ret
.fetch  call snd_byte : ld (snd_tok),a
        and #3F : cp PAT_END : jr nz,.token
        ; the next pattern in its order
        ld l,(ix+V_ORDL) : ld h,(ix+V_ORDH)
        ld e,(ix+V_ORD) : ld d,0 : add hl,de
        inc (ix+V_ORD)
        ld e,(hl)
        TLOOK pat_lo : ld (ix+V_PATL),a
        TLOOK pat_hi : ld (ix+V_PATH),a
        jr .fetch
.token  ld (snd_semi),a
        xor a : ld (snd_env),a
        ld a,(snd_tok) : and #C0 : jr z,.long
        rlca : rlca : dec a : ld (ix+V_LEFT),a  ; (its length, 1-3)
        jr .decoded
.long   call snd_byte : ld c,a
        and #1F : ld (ix+V_LEFT),a
        ld a,c : rlca : rlca : rlca : and 7 : ld (snd_env),a
.decoded
        ld a,(snd_semi)
        cp PAT_EXTEND : ret z
        jr nc,.rest
        ; a note
        ld (ix+V_SEMI),a
        ld a,(snd_env) : ld (ix+V_ENV),a
        ld a,(ix+V_BASE) : cp 255 : jr nz,.ins_ok
        ld a,(ix+V_SEMI) : add a,DRUM_INS       ; (in the drum kit, the semitone is the drum)
.ins_ok ld (ix+V_INS),a
        jp snd_trigger
.rest   xor a : ld (ix+V_ENV),a : ld (ix+V_EPOS),a
        jp snd_release

; The next byte of track IX's pattern
snd_byte
        ld l,(ix+V_PATL) : ld h,(ix+V_PATH)
        ld a,(hl) : inc hl
        ld (ix+V_PATL),l : ld (ix+V_PATH),h
        ret

; Voice IX, every tick: its amplitude envelope, then its attenuation and pitch
snd_voice
        ld a,(ix+V_PHASE) : or a : jr nz,.on
        ld (ix+V_ATT),15
        ret
.on     ld e,(ix+V_INS) : ld d,0
        cp 2 : jr z,.decay : jr nc,.sustain
        ; attack, up to ala
        ld hl,ins_atk_lo : add hl,de : ld a,(ix+V_AMPL) : add a,(hl) : ld (ix+V_AMPL),a
        ld hl,ins_atk_hi : add hl,de : ld a,(ix+V_AMPH) : adc a,(hl) : jr c,.to_ala
        ld hl,ins_ala : add hl,de : cp (hl) : jr c,.set
.to_ala ld (ix+V_PHASE),2 : ld (ix+V_AMPL),0
        TLOOK ins_ala
        jr .set
.decay  ; decay, down to ald
        ld hl,ins_dec_lo : add hl,de : ld a,(ix+V_AMPL) : sub (hl) : ld (ix+V_AMPL),a
        ld hl,ins_dec_hi : add hl,de : ld a,(ix+V_AMPH) : sbc a,(hl) : jr c,.to_ald
        ld hl,ins_ald : add hl,de : cp (hl) : jr z,.to_ald : jr nc,.set
.to_ald ld (ix+V_PHASE),3 : ld (ix+V_AMPL),0
        TLOOK ins_ald
        jr .set
.sustain
        cp 3 : jr nz,.release
        ; sustain, down to nothing
        ld hl,ins_sus_lo : add hl,de : ld a,(ix+V_AMPL) : sub (hl) : ld (ix+V_AMPL),a
        ld hl,ins_sus_hi : add hl,de : ld a,(ix+V_AMPH) : sbc a,(hl) : jr nc,.set
.to_zero
        xor a : ld (ix+V_AMPL),a : ld (ix+V_PHASE),a
        jr .set
.release
        ld hl,ins_rel_lo : add hl,de : ld a,(ix+V_AMPL) : sub (hl) : ld (ix+V_AMPL),a
        ld hl,ins_rel_hi : add hl,de : ld a,(ix+V_AMPH) : sbc a,(hl) : jr c,.to_zero
.set    ld (ix+V_AMPH),a
        ; attenuation: the instrument's plus the envelope's
        srl a : ld c,a : ld b,0 : ld hl,amptab : add hl,bc : ld a,(hl)
        ld hl,ins_att : add hl,de : add a,(hl)
        cp 16 : jr c,.att_ok
        ld a,15
.att_ok ld (ix+V_ATT),a
        TLOOK ins_noise : or a : ret nz
        ld a,(ix+V_PFLAT) : or a : ret nz       ; (the pitch can't have changed)
        ; pitch envelope: this tick's offset, then on to the next (or back to its loop)
        ld e,(ix+V_ENV)
        TLOOK env_start : add a,(ix+V_EPOS) : ld (snd_tmp),a
        inc a
        ld hl,env_end : add hl,de : cp (hl) : jr c,.advance
        ; (at its end: a flat one if it's one long, so the note's pitch won't change)
        ld a,(ix+V_EPOS) : or a : jr nz,.loop
        inc (ix+V_PFLAT)
.loop   TLOOK env_loop
.advance
        ld hl,env_start : add hl,de : sub (hl) : ld (ix+V_EPOS),a
        ; p = semitone * 8 + offset (eighths of a semitone), at least 0
        ld a,(snd_tmp) : ld e,a : TLOOK env_data
        ld c,a : rla : sbc a,a : ld b,a
        ld l,(ix+V_SEMI) : ld h,0 : add hl,hl : add hl,hl : add hl,hl
        add hl,bc
        bit 7,h : jr z,.p_ok
        ld hl,0
.p_ok   ; (a track the BBC version plays an octave up, for its chip's lowest note: down again)
        bit 7,(ix+V_CHAN) : jr z,.p_down
        ld de,96 : or a : sbc hl,de : jr nc,.p_down
        add hl,de
.p_down ; (the same as last tick: the same divider)
        ld a,l : cp (ix+V_PL) : jr nz,.new_p
        ld a,h : cp (ix+V_PH) : ret z
.new_p  ld (ix+V_PL),l : ld (ix+V_PH),h
        ; its octave (B) and the eighth of a semitone in it (L)
        ld b,0 : ld de,96
.octave or a : sbc hl,de : jr c,.in_octave
        inc b : jr .octave
.in_octave
        add hl,de
        ; the AY's divider: the BBC's (ntab) >> (octave + 1), rounded
        ld e,l : ld d,0
        TLOOK ntab_lo : ld c,a
        TLOOK ntab_hi : ld h,a : ld l,c
        inc b
.shift  srl h : rr l : djnz .shift
        ld a,l : adc a,0 : ld (ix+V_NL),a
        ld a,h : adc a,0 : ld (ix+V_NH),a
        ret

; Give the AY's channels to their voices, writing only what's changed. The noise
; voice (the noise sound effect, else - with all the tracks - a drum that's
; sounding) has a channel to itself while it sounds: a free one, else the quietest.
; The tone voices share out the others each tick: a voice that's sounding keeps
; its channel; one that starts takes a free channel, else the channel of a voice at
; least 8dB quieter (the tail of a note, say); the tone sound effect takes a free
; channel, else the quietest.
snd_output
        ; which voices are sounding (a bit each, voice 0 the lowest)
        ASSERT NV == 9
        ld ix,vtab + VOFF : ld hl,0
        ld a,(ix+V_ATT+8) : sub 15 : adc hl,hl
        ld a,(ix+V_ATT+7) : sub 15 : adc hl,hl
        ld a,(ix+V_ATT+6) : sub 15 : adc hl,hl
        ld a,(ix+V_ATT+5) : sub 15 : adc hl,hl
        ld a,(ix+V_ATT+4) : sub 15 : adc hl,hl
        ld a,(ix+V_ATT+3) : sub 15 : adc hl,hl
        ld a,(ix+V_ATT+2) : sub 15 : adc hl,hl
        ld a,(ix+V_ATT+1) : sub 15 : adc hl,hl
        ld a,(ix+V_ATT+0) : sub 15 : adc hl,hl
        ld (snd_on),hl
        ; the noise voice: the noise sound effect if it's sounding, else (with all the
        ; tracks) the first drum that is
        ld a,SFX_NOISE : bit SFX_NOISE - 8,h : jr nz,.n_got
        ld a,#FF
        ld bc,(snd_drums) : ld a,l : and c : ld c,a : ld a,h : and b : or c
        ld a,#FF : jr z,.n_got
        ld a,(snd_music_opt) : or a : ld a,#FF : jr nz,.n_got
        ld a,c : ld c,0                         ; (the lowest bit of the drums: none above 7)
.lowest rrca : jr c,.n_low
        inc c : jr .lowest
.n_low  ld a,c
.n_got  ld (snd_nv),a
        ; those that want a tone channel: sounding, and allowed one (snd_allow)
        ld bc,(snd_allow) : ld a,l : and c : ld l,a : ld a,h : and b : ld h,a
        ; the channels as last tick, if neither that nor the noise voice has changed
        ld de,(snd_want) : or a : sbc hl,de : add hl,de : jr nz,.changed
        ld a,(snd_nv) : ld b,a : ld a,(snd_lastnv) : cp b : jr nz,.changed
        ld a,(snd_pend) : or a : jp z,.output   ; (and no voice was left waiting)
.changed
        xor a : ld (snd_pend),a
        ld (snd_want),hl
        ld a,(snd_nv) : ld (snd_lastnv),a
        ld de,want : ld b,NV                    ; (as a byte each)
.bits   xor a : srl h : rr l : rla : ld (de),a : inc de : djnz .bits
        ; 1. the channels of voices that have stopped (or aren't wanted) are free: the
        ; noise voice's if there isn't one now (else it's the new one's)
        ld b,2
.free   call owner_hl
        ld a,(hl) : cp #FF : jr z,.free_next
        ld a,(snd_nch) : cp b : jr nz,.free_tone
        ld a,(snd_nv) : ld (hl),a : cp #FF : jr nz,.free_next
        ld (snd_nch),a
        jr .free_next
.free_tone
        push hl : call want_a : pop hl : or a : jr nz,.free_next
        ld (hl),#FF
.free_next
        dec b : jp p,.free
        ; 2. the noise voice, if it hasn't a channel: a free one, else the quietest
        ld a,(snd_nv) : cp #FF : jr z,.place_tones
        ld a,(snd_nch) : cp #FF : jr nz,.place_tones
        call free_channel : jr nc,.n_take
        call quietest
.n_take ld a,b : ld (snd_nch),a
        call owner_hl : ld a,(snd_nv) : ld (hl),a
.place_tones
        ; 3. each tone voice that's wanted but has no channel: the sound effect, then the tracks
        ld c,SFX_TONE
.place  ld a,c : call want_a : or a : jr z,.place_next
        ld b,2                                  ; (has it one?)
.has    ld a,(snd_nch) : cp b : jr z,.has_next
        call owner_hl : ld a,(hl) : cp c : jr z,.place_next
.has_next
        dec b : jp p,.has
        call free_channel : jr nc,.take
        call quietest                           ; B = the quietest channel, A its attenuation
        ld e,a
        ld a,c : cp SFX_TONE : jr z,.take
        call voice_ix : ld a,(ix+V_ATT) : add a,4 : cp e : jr z,.take : jr nc,.wait
.take   call owner_hl : ld (hl),c
        jr .place_next
.wait   ld a,1 : ld (snd_pend),a                ; (it waits for a channel: look again next tick)
.place_next
        ld a,c : cp SFX_TONE : jr nz,.next_track
        ld c,#FF
.next_track
        inc c : ld a,c : cp MAX_TRACKS : jr nz,.place
        ; 4. each channel: its voice's pitch (or the noise's period), its loudness, and the mixer
.output ld a,#3F : ld (snd_mix),a               ; (nothing mixed in: and port A, the keyboard, input)
        CHANNEL 0
        CHANNEL 1
        CHANNEL 2
        ; the mixer, if it's changed
        ld a,(snd_mix) : ld hl,last_mix : cp (hl) : ret z
        ld (hl),a
        ld e,7 : jp psg_write


; HL = the owner of channel B (DE kept)
owner_hl
        ld hl,snd_owner
        ld a,l : add a,b : ld l,a : ret nc
        inc h
        ret

; B = a channel with no voice, carry clear (else carry set)
free_channel
        ld b,2
.free   call owner_hl : ld a,(hl) : cp #FF : ret z
        dec b : jp p,.free
        scf
        ret

; B = the quietest channel that isn't the noise's (the highest attenuation), A = its
; attenuation (C kept)
quietest
        xor a : ld (snd_qa),a : ld (snd_qc),a
        ld b,2
.quiet  ld a,(snd_nch) : cp b : jr z,.next
        call owner_hl : ld a,(hl) : cp #FF : jr z,.next
        call voice_ix : ld a,(ix+V_ATT)
        ld hl,snd_qa : cp (hl) : jr c,.next
        ld (hl),a : ld a,b : ld (snd_qc),a
.next   dec b : jp p,.quiet
        ld a,(snd_qc) : ld b,a
        ld a,(snd_qa)
        ret

; snd_allow: the voices that may have a tone channel (the tone sound effect, and the
; tone tracks that the music option lets play); snd_drums: the drum tracks. (When a
; tune starts or the option changes.)
snd_masks
        ld hl,1 << SFX_TONE : ld de,0           ; (HL: allowed, DE: the drums)
        ld ix,vtab + VOFF
        ld bc,1                                 ; (BC: this track's bit)
        xor a : ld (snd_mb),a                   ; (the track)
.track  ld a,(ix+V_ON) : or a : jr z,.next
        ld a,(ix+V_CHAN) : and #7F : cp 3 : jr nz,.tone
        ld a,e : or c : ld e,a : ld a,d : or b : ld d,a
        jr .next
.tone   ld a,(snd_music_opt) : or a : jr z,.allow
        cp 2 : jr z,.next
        ld a,(snd_mb) : or a : jr nz,.next      ; (just the first track)
.allow  ld a,l : or c : ld l,a : ld a,h : or b : ld h,a
.next   inc ix : sla c : rl b
        ld a,(snd_mb) : inc a : ld (snd_mb),a
        cp MAX_TRACKS : jr nz,.track
        ld (snd_allow),hl : ld (snd_drums),de
        ret

; A = want for voice A (BC, DE kept)
want_a  ld hl,want : add a,l : ld l,a : adc a,h : sub l : ld h,a
        ld a,(hl)
        ret

; Write A to the AY's register E (through the PPI: port A the data, port C bits 6
; and 7 the AY's BDIR and BC1)
psg_write
        ld b,#F4 : out (c),e                    ; the register...
        ld bc,#F6C0 : out (c),c                 ; ... selected
        ld c,0 : out (c),c
        ld b,#F4 : out (c),a                    ; the value...
        ld bc,#F680 : out (c),c                 ; ... written
        ld c,0 : out (c),c
        ret

; Silence the AY, and forget what was written (start-up: snd_tick then writes
; everything it needs)
snd_init
        ld e,7 : ld a,#3F : call psg_write      ; (nothing mixed in, port A input)
        ld e,8 : xor a : call psg_write
        ld e,9 : xor a : call psg_write
        ld e,10 : xor a : call psg_write
        ld hl,vtab : ld de,vtab + 1 : ld bc,V_FIELDS * NV - 1 : ld (hl),0 : ldir
        ld b,NV - 1
.voices ld a,b : call voice_ix : call snd_silence
        ld (ix+V_PH),#FF                        ; (no pitch worked out yet)
        ld (ix+V_PFLAT),0
        dec b : jp p,.voices
        ld hl,snd_owner : ld (hl),#FF : inc hl : ld (hl),#FF : inc hl : ld (hl),#FF
        ld a,#FF : ld (snd_nch),a
        ld a,#3F : ld (last_mix),a
        xor a : ld (last_vol),a : ld (last_vol + 1),a : ld (last_vol + 2),a
        ld (snd_tune),a
        ld hl,last_tp : ld b,6
.tp     ld (hl),#FF : inc hl : djnz .tp
        ld a,#FF : ld (last_np),a
        jp snd_masks

; The player's variables
snd_tune   db 0
snd_k      dw 0
snd_acc    dw 0
snd_qb     dw 0
snd_total  dw 0
snd_intro  dw 0
snd_tok    db 0
snd_semi   db 0
snd_env    db 0
snd_tmp    db 0
snd_m_last db 0
snd_s_last db 0
snd_owner  db #FF, #FF, #FF         ; the voice each channel is playing (#FF: none)
snd_nv     db #FF                   ; the noise voice this tick (#FF: none)
snd_nch    db #FF                   ; ... its channel (#FF: none)
snd_qa     db 0
snd_qc     db 0
snd_mix    db 0
want       DEFS NV                  ; each voice wants a tone channel (see snd_output)
snd_on     dw 0                     ; the voices sounding (a bit each)
snd_want   dw #FFFF                 ; ... wanting a tone channel, last tick
snd_lastnv db #FE                   ; ... and the noise voice then
snd_allow  dw 1 << SFX_TONE         ; (see snd_masks)
snd_drums  dw 0
snd_mb     db 0
snd_pend   db 0                     ; a voice was left waiting for a channel
last_tp    DEFS 6                   ; what was last written: each channel's divider,
last_vol   DEFS 3                   ; ... its volume,
last_np    db 0                     ; ... the noise period,
last_mix   db 0                     ; ... and the mixer
vtab       DEFS V_FIELDS * NV       ; the voices' fields (see V_ON)
