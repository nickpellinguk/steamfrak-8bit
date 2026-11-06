\ ------------------------------------------------------------------------------
\ Music and sound effects (in the emptier sprite bank, MUSIC_BANK)
\
\ snd_tick runs 50 times a second, from the vertical sync event (vsync_event
\ pages this bank in). It plays the Steam version's tunes the way that does: each
\ track's notes start on quarter beats, and each note has an amplitude envelope
\ (attack, decay, sustain, release, from the BBC Micro style ENVELOPEs) and a
\ pitch envelope, stepped every tick. Tracks share the sound chip's three tone
\ channels, given out each tick (see snd_output), and the drums have the noise
\ channel. Sound effects are notes on two more voices: one takes a tone channel
\ (the quietest, if none is free), the other the noise channel.
\
\ The game asks for things through main RAM (see play_music and play_sfx):
\ snd_music_req (a tune, 0 to stop), snd_sfx_req (a sound effect, SFX_STOP to
\ stop them), snd_music_opt (0 = all the tracks, 1 = just the first, 2 = off; M
\ changes it) and snd_sfx_opt (0 = on, 1 = off; S changes it). The tunes and
\ instruments are made by tools/music.py (src/gen/music.asm).
\ ------------------------------------------------------------------------------

INCLUDE "src/gen/music.asm"

\ One tick: requests and keys, then a quarter beat if one is due, then every voice
.snd_tick
{
    jsr snd_keys
    lda snd_music_req : bmi no_tune
    ldx #&FF : stx snd_music_req
    jsr snd_start_tune
.no_tune
    lda snd_sfx_req : bmi no_sfx
    ldx #&FF : stx snd_sfx_req
    jsr snd_start_sfx
.no_sfx
    lda snd_sfx_req2 : bmi no_sfx2
    ldx #&FF : stx snd_sfx_req2
    jsr snd_start_sfx
.no_sfx2
    \ sound effects are released after their length
    ldx #SFX_TONE
.sfx_len
    lda v_left,x : beq sfx_next
    dec v_left,x : bne sfx_next
    jsr snd_release
.sfx_next
    inx : cpx #NV : bne sfx_len
    \ quarter beats
    lda snd_tune : beq no_qb
    clc : lda snd_acc : adc snd_k : sta snd_acc
    lda snd_acc+1 : adc snd_k+1 : sta snd_acc+1
    bcc no_qb
    jsr snd_quarter_beat
.no_qb
    ldx #NV - 1
.voices
    jsr snd_voice
    dex : bpl voices
    jmp snd_output
}

\ M and S (as they go down) change the music and sound effects options
.snd_keys
{
    lda #INKEY_M : jsr snd_key : tay : beq m_up
    cmp snd_m_last : beq m_up
    ldx snd_music_opt : inx : cpx #3 : bcc m_ok : ldx #0 : .m_ok
    stx snd_music_opt
.m_up
    sty snd_m_last
    lda #INKEY_S : jsr snd_key : tay : beq s_up
    cmp snd_s_last : beq s_up
    lda snd_sfx_opt : eor #1 : sta snd_sfx_opt
    jsr snd_stop_sfx
.s_up
    sty snd_s_last
    rts
}

\ A = 1 if key A (internal number) is down, else 0
.snd_key
{
    ldx #3 : stx SYSVIA_ORB
    ldx #&7F : stx SYSVIA_DDRA
    sta SYSVIA_ORA
    lda SYSVIA_ORA_HS
    ldx #&0B : stx SYSVIA_ORB
    asl a : lda #0 : rol a
    rts
}

\ Start tune A (0: silence)
.snd_start_tune
{
    sta snd_tune
    ldx #MAX_TRACKS - 1
.off
    jsr snd_silence
    lda #0 : sta v_on,x
    dex : bpl off
    ldy snd_tune : beq done
    lda tune_k_lo,y : sta snd_k : lda tune_k_hi,y : sta snd_k+1
    lda tune_total_lo,y : sta snd_total : lda tune_total_hi,y : sta snd_total+1
    lda tune_intro_lo,y : sta snd_intro : lda tune_intro_hi,y : sta snd_intro+1
    lda #&FF : sta snd_acc : sta snd_acc+1      \ (so the first tick starts a quarter beat)
    lda #0 : sta snd_qb : sta snd_qb+1
    ldx #0
.tracks
    txa : clc : adc tune_first,y : tay
    lda #1 : sta v_on,x
    lda trk_ins,y : sta v_base,x
    lda trk_chan,y : sta v_chan,x
    lda trk_order_lo,y : sta v_ordl,x : lda trk_order_hi,y : sta v_ordh,x
    lda #0 : sta v_ord,x
    jsr snd_to_end
    ldy snd_tune
    inx : txa : cmp tune_ntracks,y : bne tracks
.done
    rts
}

\ Voice X: silent, with nothing playing
.snd_silence
{
    lda #0 : sta v_phase,x : sta v_ampl,x : sta v_amph,x : sta v_left,x
    lda #15 : sta v_att,x
    rts
}

\ Track X: at the end of a pattern (so it starts the next in its order)
.snd_to_end
{
    lda #LO(end_byte) : sta v_patl,x : lda #HI(end_byte) : sta v_path,x
    rts
.end_byte EQUB PAT_END
}

\ Voice X: start its note (the attack)
.snd_trigger
{
    lda #0 : sta v_epos,x : sta v_ampl,x : sta v_amph,x
    lda #1 : sta v_phase,x
    rts
}

\ Voice X: let its note go (the release), if it's sounding
.snd_release
{
    lda v_phase,x : beq done : cmp #4 : beq done
    lda #4 : sta v_phase,x
.done
    rts
}

\ Sound effect A (SFX_STOP: stop them)
.snd_start_sfx
{
    cmp #SFX_STOP : beq snd_stop_sfx
    ldx snd_sfx_opt : bne done
    tay
    lda sfx_ins,y : sta snd_tmp
    tax : lda ins_noise,x
    ldx #SFX_TONE : cmp #0 : beq tone : ldx #SFX_NOISE : .tone
    lda snd_tmp : sta v_ins,x
    lda sfx_semi,y : sta v_semi,x
    lda sfx_env,y : sta v_env,x
    lda sfx_len,y : sta v_left,x
    jmp snd_trigger
.done
    rts
}
.snd_stop_sfx
{
    ldx #SFX_TONE : jsr snd_silence
    ldx #SFX_NOISE : jmp snd_silence
}

\ A quarter beat: each track's next note, if its last one is over. At the end of
\ the tune it goes round again, from the end of its introduction.
.snd_quarter_beat
{
    lda snd_qb : cmp snd_total : lda snd_qb+1 : sbc snd_total+1 : bcc go
    lda snd_intro : sta snd_qb : lda snd_intro+1 : sta snd_qb+1
    ldx #0
.again
    lda v_on,x : beq again_next
    jsr snd_silence
    txa : ldy snd_tune : clc : adc tune_first,y : tay
    lda trk_loop,y : sta v_ord,x
    jsr snd_to_end
.again_next
    inx : cpx #MAX_TRACKS : bne again
.go
    inc snd_qb : bne qb_ok : inc snd_qb+1 : .qb_ok
    ldx #MAX_TRACKS - 1
.tracks
    lda v_on,x : beq next
    jsr snd_track_step
.next
    dex : bpl tracks
    rts
}

\ Track X, at a quarter beat
.snd_track_step
{
    lda v_left,x : beq fetch
    dec v_left,x
    rts
.fetch
    jsr snd_byte : sta snd_tok
    and #&3F : cmp #PAT_END : bne token
    \ the next pattern in its order
    lda v_ordl,x : sta tblptr : lda v_ordh,x : sta tblptr+1
    ldy v_ord,x : inc v_ord,x
    lda (tblptr),y : tay
    lda pat_lo,y : sta v_patl,x : lda pat_hi,y : sta v_path,x
    jmp fetch
.token
    sta snd_semi
    lda #0 : sta snd_env
    lda snd_tok : and #&C0 : beq long
    asl a : rol a : rol a                   \ (its length, 1-3)
    sec : sbc #1 : sta v_left,x
    jmp decoded
.long
    jsr snd_byte : pha
    and #&1F : sta v_left,x
    pla : lsr a : lsr a : lsr a : lsr a : lsr a : sta snd_env
.decoded
    lda snd_semi
    cmp #PAT_EXTEND : beq extend : bcs rest
    \ a note
    sta v_semi,x
    lda snd_env : sta v_env,x
    lda v_base,x : cmp #255 : bne ins_ok
    lda v_semi,x : clc : adc #DRUM_INS      \ (in the drum kit, the semitone is the drum)
.ins_ok
    sta v_ins,x
    jmp snd_trigger
.rest
    lda #0 : sta v_env,x : sta v_epos,x
    jmp snd_release
.extend
    rts
}

\ The next byte of track X's pattern
.snd_byte
{
    lda v_patl,x : sta tblptr : lda v_path,x : sta tblptr+1
    ldy #0 : lda (tblptr),y
    inc v_patl,x : bne done : inc v_path,x
.done
    rts
}

\ Voice X, every tick: its amplitude envelope, then its attenuation and pitch
.snd_voice
{
    lda v_phase,x : bne on
    lda #15 : sta v_att,x
    rts
.on
    ldy v_ins,x
    cmp #2 : beq decay : bcs sustain
    \ attack, up to ala
    clc : lda v_ampl,x : adc ins_atk_lo,y : sta v_ampl,x
    lda v_amph,x : adc ins_atk_hi,y : bcs to_ala
    cmp ins_ala,y : bcc set
.to_ala
    lda #2 : sta v_phase,x
    lda #0 : sta v_ampl,x
    lda ins_ala,y
    jmp set
.decay
    \ decay, down to ald
    sec : lda v_ampl,x : sbc ins_dec_lo,y : sta v_ampl,x
    lda v_amph,x : sbc ins_dec_hi,y : bcc to_ald
    cmp ins_ald,y : beq to_ald : bcs set
.to_ald
    lda #3 : sta v_phase,x
    lda #0 : sta v_ampl,x
    lda ins_ald,y
    jmp set
.sustain
    cmp #3 : bne release
    \ sustain, down to nothing
    sec : lda v_ampl,x : sbc ins_sus_lo,y : sta v_ampl,x
    lda v_amph,x : sbc ins_sus_hi,y : bcs set
.to_zero
    lda #0 : sta v_ampl,x : sta v_phase,x
    beq set
.release
    sec : lda v_ampl,x : sbc ins_rel_lo,y : sta v_ampl,x
    lda v_amph,x : sbc ins_rel_hi,y : bcc to_zero
.set
    sta v_amph,x
    \ attenuation: the instrument's plus the envelope's
    lsr a : tay : lda amptab,y
    ldy v_ins,x : clc : adc ins_att,y
    cmp #16 : bcc att_ok : lda #15 : .att_ok
    sta v_att,x
    lda ins_noise,y : beq tone
    rts
.tone
    \ pitch envelope: this tick's offset, then on to the next (or back to its loop)
    ldy v_env,x
    lda env_start,y : clc : adc v_epos,x : sta snd_tmp
    clc : adc #1 : cmp env_end,y : bcc advance
    lda env_loop,y
.advance
    sec : sbc env_start,y : sta v_epos,x
    \ p = semitone * 8 + offset (eighths of a semitone)
    lda v_semi,x : sta snd_p : lda #0 : sta snd_p+1
    asl snd_p : rol snd_p+1 : asl snd_p : rol snd_p+1 : asl snd_p : rol snd_p+1
    ldy snd_tmp : lda env_data,y : pha
    clc : adc snd_p : sta snd_p
    pla : bmi off_neg
    lda #0 : beq off_hi
.off_neg
    lda #&FF
.off_hi
    adc snd_p+1 : sta snd_p+1
    bpl p_ok
    lda #0 : sta snd_p : sta snd_p+1
.p_ok
    \ octave (Y) and the eighth of a semitone in it (snd_p)
    ldy #0
.octave
    lda snd_p : sec : sbc #96 : sta snd_tmp
    lda snd_p+1 : sbc #0 : bcc in_octave
    sta snd_p+1 : lda snd_tmp : sta snd_p
    iny : bne octave
.in_octave
    \ the chip's divider: ntab >> octave (and an octave up if it's too low for 10 bits)
    sty snd_tmp
    ldy snd_p
    lda ntab_lo,y : sta v_nl,x
    lda ntab_hi,y
    ldy snd_tmp : beq shifted
.shift
    lsr a : ror v_nl,x
    dey : bne shift
.shifted
    cmp #4 : bcc fits
    lsr a : ror v_nl,x
.fits
    sta v_nh,x
    rts
}

\ Give the sound chip's channels to their voices, writing only what's changed.
\ The three tone channels are shared out each tick: a voice that's sounding keeps
\ its channel; one that starts takes a free channel, else the channel of a voice
\ at least 8dB quieter (the tail of a note, say); the tone sound effect takes a
\ free channel, else the quietest. (The drums have the noise channel.)
.snd_output
{
    \ 1. the channels of voices that have stopped (or aren't wanted) are free
    ldx #2
.free
    ldy snd_owner,x : bmi free_next
    jsr snd_wanted : bcs free_next
    lda #&FF : sta snd_owner,x
.free_next
    dex : bpl free
    \ 2. each voice that's wanted but has no channel: the sound effect, then the tracks
    ldy #SFX_TONE
.place
    jsr snd_wanted : bcc place_next
    tya : ldx #2
.has
    cmp snd_owner,x : beq place_next
    dex : bpl has
    ldx #2
.free_ch
    lda snd_owner,x : bmi take
    dex : bpl free_ch
    \ none free: the quietest channel (the highest attenuation)
    sty snd_y
    lda #0 : sta snd_qa
    ldx #2
.quiet
    ldy snd_owner,x : lda v_att,y : cmp snd_qa : bcc quiet_next
    sta snd_qa : stx snd_qc
.quiet_next
    dex : bpl quiet
    ldy snd_y : ldx snd_qc
    cpy #SFX_TONE : beq take
    lda v_att,y : clc : adc #4 : cmp snd_qa : beq take : bcs place_next
.take
    tya : sta snd_owner,x
.place_next
    cpy #SFX_TONE : bne next_track : ldy #&FF
.next_track
    iny : cpy #MAX_TRACKS : bne place
    \ 3. each channel: its voice's pitch and attenuation
    ldx #0
.channel
    ldy snd_owner,x : bpl got
    lda #15 : bne set_att
.got
    lda v_nl,y : cmp last_nl,x : bne new_n
    lda v_nh,y : cmp last_nh,x : beq same_n
.new_n
    lda v_nl,y : sta last_nl,x
    and #15 : ora chan_bits,x : ora #&80 : jsr sn_write     \ 1 cc 0 nnnn
    lda v_nh,y : sta last_nh,x
    asl a : asl a : asl a : asl a : sta snd_tmp
    lda v_nl,y : lsr a : lsr a : lsr a : lsr a : ora snd_tmp
    jsr sn_write                                             \ 0 0 nnnnnn
.same_n
    lda v_att,y
.set_att
    cmp last_att,x : beq same_att
    sta last_att,x
    ora chan_bits,x : ora #&90 : jsr sn_write               \ 1 cc 1 aaaa
.same_att
    inx : cpx #3 : bne channel

    \ the noise channel: the noise sound effect, else the drums (only with all the tracks)
    ldy #SFX_NOISE : lda v_att,y : cmp #15 : bcc n_got
    lda snd_music_opt : bne n_none
    ldy #0
.n_find
    lda v_on,y : beq n_next
    lda v_chan,y : cmp #3 : bne n_next
    lda v_att,y : cmp #15 : bcc n_got
.n_next
    iny : cpy #MAX_TRACKS : bne n_find
.n_none
    lda #15 : bne n_set
.n_got
    sty snd_tmp
    lda v_ins,y : tay : lda ins_noise,y
    ldy snd_tmp
    cmp last_noise : beq n_same
    sta last_noise : jsr sn_write                           \ 1 11 0 f rr
.n_same
    lda v_att,y
.n_set
    cmp last_att + 3 : beq n_done
    sta last_att + 3
    ora #&F0 : jsr sn_write
.n_done
    rts
.chan_bits EQUB &00, &20, &40
}

\ Carry set if voice Y should be heard on a tone channel now: sounding, and the
\ tone sound effect or a tone track that the music option lets play. X kept.
.snd_wanted
{
    lda v_att,y : cmp #15 : bcs no
    cpy #SFX_TONE : beq yes
    lda v_on,y : beq no
    lda v_chan,y : cmp #3 : beq no
    lda snd_music_opt : beq yes
    cmp #2 : beq no
    cpy #0 : bne no                     \ (just the first track)
.yes
    sec : rts
.no
    clc : rts
}

\ Write A to the sound chip
.sn_write
{
    pha : lda #&FF : sta SYSVIA_DDRA : pla
    sta SYSVIA_ORA
    lda #0 : sta SYSVIA_ORB             \ (sound chip write enable on ...)
    pha : pla : pha : pla
    lda #8 : sta SYSVIA_ORB             \ (... and off)
    rts
}
