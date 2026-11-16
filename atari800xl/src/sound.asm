; ---- Music and sound effects: the BBC version's player (../src/sound.asm), routine for routine,
; in plain 6502 (its 65C02's stz, bra and inc a replaced), with the CPC version's changes for a
; sound chip of three channels (../cpc6128/src/sound.asm): the bass played at its own pitch (the
; tracks the BBC version plays an octave up, for its chip's lowest note, down again), and the
; noise voice borrowing a channel while it sounds. The tunes, instruments and envelopes are the
; BBC version's (tools/music_a8.py: ../tools/music.py's), so all three play the same notes.
;
; snd_tick runs 50 times a second, from the VBI (and the front end's). It plays the Steam
; version's tunes the way that does: each track's notes start on quarter beats, and each note has
; an amplitude envelope (attack, decay, sustain, release) and a pitch envelope, stepped every
; tick. Sound effects are notes on two more voices, a tone and a noise one.
;
; The POKEY, as three channels: channel 0 its channels 1 and 2 joined, 16 bits on the 1.79MHz
; clock (exact for any pitch: the bass, at its own pitch, goes there first); channels 1 and 2 its
; channels 3 and 4, 8 bits on the 64kHz clock (down to 123Hz, a quarter of a semitone out at
; most up to 800Hz: the tunes are 106-898Hz, 96% of the time 126-800Hz; a note too low for them
; an octave up). The noise voice (the noise sound effect, else, with all the tracks, a drum that's
; sounding) borrows a channel while it sounds, a free one else the quietest: the 17-bit noise at
; the BBC chip's rate. The tone voices share out the rest each tick as on the BBC (snd_output).
; Loudness: the BBC chip's 2dB steps as the POKEY's nearest volume (pvol).
;
; The game asks for things through play_music, play_music_new, play_sfx: snd_music_req (a tune, 0
; to stop; $ff none), snd_sfx_req and snd_sfx_req2 (sound effects, SFX_STOP to stop them),
; snd_music_opt (0 all the tracks, 1 the first only, 2 off: M changes it) and snd_sfx_opt (0 on,
; 1 off: S changes it).
NV      = MAX_TRACKS + 2            ; voices: the tracks, then a tone and a noise sound effect
SFX_TONE = MAX_TRACKS
SFX_NOISE = MAX_TRACKS + 1
SFX_STOP = $7f
AUDF1   = $d200
AUDC1   = $d201
AUDCTL  = $d208
KEY_M   = $25                       ; (KBCODE's)
KEY_S   = $3e
sptr    = $b8                       ; (2: the pattern being read; the player's alone, in the VBI)
vbiv    = $ba                       ; (2: the VBI: the game's, or the front end's)

; One tick: requests and keys, then a quarter beat if one is due, then every voice
snd_tick
        jsr snd_keys
        lda snd_music_req
        bmi +
        ldx #$ff
        stx snd_music_req
        jsr snd_start_tune
+       lda snd_sfx_req
        bmi +
        ldx #$ff
        stx snd_sfx_req
        jsr snd_start_sfx
+       lda snd_sfx_req2
        bmi +
        ldx #$ff
        stx snd_sfx_req2
        jsr snd_start_sfx
+       ldx #SFX_TONE               ; sound effects released after their length
_sl     lda v_left,x
        beq _sn
        dec v_left,x
        bne _sn
        jsr snd_release
_sn     inx
        cpx #NV
        bne _sl
        lda snd_tune                ; quarter beats
        beq _nq
        clc
        lda snd_acc
        adc snd_k
        sta snd_acc
        lda snd_acc+1
        adc snd_k+1
        sta snd_acc+1
        bcc _nq
        jsr snd_quarter_beat
_nq     ldx #NV - 1
_v      jsr snd_voice
        dex
        bpl _v
        jmp snd_output

; M and S (as they go down) change the music and sound effects options
snd_keys
        lda #KEY_M
        jsr snd_key
        tay
        beq _mu
        cmp snd_m_last
        beq _mu
        ldx snd_music_opt
        inx
        cpx #3
        bcc +
        ldx #0
+       stx snd_music_opt
_mu     sty snd_m_last
        lda #KEY_S
        jsr snd_key
        tay
        beq _su
        cmp snd_s_last
        beq _su
        lda snd_sfx_opt
        eor #1
        sta snd_sfx_opt
        jsr snd_stop_sfx
_su     sty snd_s_last
        rts

; A = 1 if key A (KBCODE's) is down, else 0
snd_key sta snd_tmp
        lda SKSTAT                  ; (a key down: bit 2 0)
        and #4
        bne _no
        lda KBCODE
        and #$3f
        cmp snd_tmp
        bne _no
        lda #1
        rts
_no     lda #0
        rts

; Start tune A (0: silence)
snd_start_tune
        sta snd_tune
        ldx #MAX_TRACKS - 1
_off    jsr snd_silence
        lda #0
        sta v_on,x
        dex
        bpl _off
        ldy snd_tune
        beq _done
        lda tune_k_lo,y
        sta snd_k
        lda tune_k_hi,y
        sta snd_k+1
        lda tune_total_lo,y
        sta snd_total
        lda tune_total_hi,y
        sta snd_total+1
        lda tune_intro_lo,y
        sta snd_intro
        lda tune_intro_hi,y
        sta snd_intro+1
        lda #$ff                    ; (so the first tick starts a quarter beat)
        sta snd_acc
        sta snd_acc+1
        lda #0
        sta snd_qb
        sta snd_qb+1
        ldx #0
_tr     txa
        clc
        adc tune_first,y
        tay
        lda #1
        sta v_on,x
        lda trk_ins,y
        sta v_base,x
        lda trk_chan,y
        sta v_chan,x
        lda trk_raised,y            ; (the CPC version's: a track the BBC raised, down again)
        sta v_raised,x
        lda trk_order_lo,y
        sta v_ordl,x
        lda trk_order_hi,y
        sta v_ordh,x
        lda #0
        sta v_ord,x
        jsr snd_to_end
        ldy snd_tune
        inx
        txa
        cmp tune_ntracks,y
        bne _tr
_done   rts

; Voice X: silent, with nothing playing
snd_silence
        lda #0
        sta v_phase,x
        sta v_ampl,x
        sta v_amph,x
        sta v_left,x
        lda #15
        sta v_att,x
        rts

; Track X: at the end of a pattern (so it starts the next in its order)
snd_to_end
        lda #<_end
        sta v_patl,x
        lda #>_end
        sta v_path,x
        rts
_end    .byte PAT_END

; Voice X: start its note (the attack)
snd_trigger
        lda #0
        sta v_epos,x
        sta v_ampl,x
        sta v_amph,x
        lda #1
        sta v_phase,x
        rts

; Voice X: let its note go (the release), if it's sounding
snd_release
        lda v_phase,x
        beq +
        cmp #4
        beq +
        lda #4
        sta v_phase,x
+       rts

; Sound effect A (SFX_STOP: stop them)
snd_start_sfx
        cmp #SFX_STOP
        beq snd_stop_sfx
        ldx snd_sfx_opt
        bne _done
        tay
        lda sfx_ins,y
        sta snd_tmp
        tax
        lda ins_noise,x
        ldx #SFX_TONE
        cmp #0
        beq +
        ldx #SFX_NOISE
+       lda snd_tmp
        sta v_ins,x
        lda sfx_semi,y
        sta v_semi,x
        lda sfx_env,y
        sta v_env,x
        lda sfx_len,y
        sta v_left,x
        lda #0                      ; (no octave down)
        sta v_raised,x
        jmp snd_trigger
_done   rts
snd_stop_sfx
        ldx #SFX_TONE
        jsr snd_silence
        ldx #SFX_NOISE
        jmp snd_silence

; A quarter beat: each track's next note, if its last one is over. At the end of the tune it goes
; round again, from the end of its introduction.
snd_quarter_beat
        lda snd_qb
        cmp snd_total
        lda snd_qb+1
        sbc snd_total+1
        bcc _go
        lda snd_intro
        sta snd_qb
        lda snd_intro+1
        sta snd_qb+1
        ldx #0
_ag     lda v_on,x
        beq _agn
        jsr snd_silence
        txa
        ldy snd_tune
        clc
        adc tune_first,y
        tay
        lda trk_loop,y
        sta v_ord,x
        jsr snd_to_end
_agn    inx
        cpx #MAX_TRACKS
        bne _ag
_go     inc snd_qb
        bne +
        inc snd_qb+1
+       ldx #MAX_TRACKS - 1
_tr     lda v_on,x
        beq +
        jsr snd_track_step
+       dex
        bpl _tr
        rts

; Track X, at a quarter beat
snd_track_step
        lda v_left,x
        beq _fetch
        dec v_left,x
        rts
_fetch  jsr snd_byte
        sta snd_tok
        and #$3f
        cmp #PAT_END
        bne _token
        lda v_ordl,x                ; the next pattern in its order
        sta sptr
        lda v_ordh,x
        sta sptr+1
        ldy v_ord,x
        inc v_ord,x
        lda (sptr),y
        tay
        lda pat_lo,y
        sta v_patl,x
        lda pat_hi,y
        sta v_path,x
        jmp _fetch
_token  sta snd_semi
        lda #0
        sta snd_env
        lda snd_tok
        and #$c0
        beq _long
        asl a                       ; (its length, 1-3)
        rol a
        rol a
        sec
        sbc #1
        sta v_left,x
        jmp _dec
_long   jsr snd_byte
        pha
        and #$1f
        sta v_left,x
        pla
        lsr a
        lsr a
        lsr a
        lsr a
        lsr a
        sta snd_env
_dec    lda snd_semi
        cmp #PAT_EXTEND
        beq _ext
        bcs _rest
        sta v_semi,x                ; a note
        lda snd_env
        sta v_env,x
        lda v_base,x
        cmp #255
        bne +
        lda v_semi,x                ; (in the drum kit, the semitone is the drum)
        clc
        adc #DRUM_INS
+       sta v_ins,x
        jmp snd_trigger
_rest   lda #0
        sta v_env,x
        sta v_epos,x
        jmp snd_release
_ext    rts

; The next byte of track X's pattern
snd_byte
        lda v_patl,x
        sta sptr
        lda v_path,x
        sta sptr+1
        ldy #0
        lda (sptr),y
        inc v_patl,x
        bne +
        inc v_path,x
+       rts

; Voice X, every tick: its amplitude envelope, then its attenuation and pitch
snd_voice
        lda v_phase,x
        bne _on
        lda #15
        sta v_att,x
        rts
_on     ldy v_ins,x
        cmp #2
        beq _decay
        bcs _sus
        clc                         ; attack, up to ala
        lda v_ampl,x
        adc ins_atk_lo,y
        sta v_ampl,x
        lda v_amph,x
        adc ins_atk_hi,y
        bcs _toala
        cmp ins_ala,y
        bcc _set
_toala  lda #2
        sta v_phase,x
        lda #0
        sta v_ampl,x
        lda ins_ala,y
        jmp _set
_decay  sec                         ; decay, down to ald
        lda v_ampl,x
        sbc ins_dec_lo,y
        sta v_ampl,x
        lda v_amph,x
        sbc ins_dec_hi,y
        bcc _toald
        cmp ins_ald,y
        beq _toald
        bcs _set
_toald  lda #3
        sta v_phase,x
        lda #0
        sta v_ampl,x
        lda ins_ald,y
        jmp _set
_sus    cmp #3
        bne _rel
        sec                         ; sustain, down to nothing
        lda v_ampl,x
        sbc ins_sus_lo,y
        sta v_ampl,x
        lda v_amph,x
        sbc ins_sus_hi,y
        bcs _set
_tozero lda #0
        sta v_ampl,x
        sta v_phase,x
        beq _set
_rel    sec
        lda v_ampl,x
        sbc ins_rel_lo,y
        sta v_ampl,x
        lda v_amph,x
        sbc ins_rel_hi,y
        bcc _tozero
_set    sta v_amph,x
        lsr a                       ; attenuation: the instrument's plus the envelope's
        tay
        lda amptab,y
        ldy v_ins,x
        clc
        adc ins_att,y
        cmp #16
        bcc +
        lda #15
+       sta v_att,x
        lda ins_noise,y
        beq _tone
        rts
_tone   ldy v_env,x                 ; pitch envelope: this tick's offset, then on to the next (or
        lda env_start,y             ; back to its loop)
        clc
        adc v_epos,x
        sta snd_tmp
        clc
        adc #1
        cmp env_end,y
        bcc +
        lda env_loop,y
+       sec
        sbc env_start,y
        sta v_epos,x
        lda v_semi,x                ; p = semitone * 8 + offset (eighths of a semitone)
        sta snd_p
        lda #0
        sta snd_p+1
        asl snd_p
        rol snd_p+1
        asl snd_p
        rol snd_p+1
        asl snd_p
        rol snd_p+1
        ldy snd_tmp
        lda env_data,y
        pha
        clc
        adc snd_p
        sta snd_p
        pla
        bmi +
        lda #0
        beq ++
+       lda #$ff
+       adc snd_p+1
        sta snd_p+1
        bpl +
        lda #0
        sta snd_p
        sta snd_p+1
+       lda v_raised,x              ; (the CPC version's: a track the BBC version plays an octave
        beq +                       ;  up, for its chip's lowest note, down again)
        lda snd_p
        sec
        sbc #96
        tay
        lda snd_p+1
        sbc #0
        bcc +
        sta snd_p+1
        sty snd_p
+       ldy #0                      ; octave (Y) and the eighth of a semitone in it (snd_p)
_oct    lda snd_p
        sec
        sbc #96
        sta snd_tmp
        lda snd_p+1
        sbc #0
        bcc _in
        sta snd_p+1
        lda snd_tmp
        sta snd_p
        iny
        bne _oct
_in     sty snd_tmp                 ; its clock count: pt16 >> (octave + 2), rounded
        ldy snd_p
        lda pt16_lo,y
        sta v_nl,x
        lda pt16_hi,y
        sta v_nh,x
        ldy snd_tmp
        iny
_sh     lsr v_nh,x
        ror v_nl,x
        dey
        bne _sh
        lsr v_nh,x
        ror v_nl,x
        lda v_nl,x
        adc #0
        sta v_nl,x
        lda v_nh,x
        adc #0
        sta v_nh,x
        rts

; Give the POKEY's three channels to their voices, writing only what's changed (the CPC
; version's snd_output). The noise voice (the noise sound effect, else, with all the tracks, a
; drum that's sounding) has a channel to itself while it sounds: a free one, else the quietest.
; The tone voices share out the others each tick: a voice that's sounding keeps its channel; one
; that starts takes a free channel (a bass track channel 0 first, the others 2, 1, 0), else the
; channel of a voice at least 8dB quieter (the tail of a note, say); the tone sound effect takes a
; free channel, else the quietest.
snd_output
        lda #$ff                    ; the noise voice
        sta snd_nv
        ldy #SFX_NOISE
        lda v_att,y
        cmp #15
        bcc _ngot
        lda snd_music_opt
        bne _nnone
        ldy #0
_nf     lda v_on,y
        beq _nn
        lda v_chan,y
        cmp #3
        bne _nn
        lda v_att,y
        cmp #15
        bcc _ngot
_nn     iny
        cpy #MAX_TRACKS
        bne _nf
        beq _nnone
_ngot   sty snd_nv
_nnone  ldx #2                      ; 1. the channels of voices that have stopped (or aren't
_free   cpx snd_nch                 ;    wanted) are free; the noise channel the noise voice's
        bne _ft
        lda snd_nv
        sta snd_owner,x
        cmp #$ff
        bne _fn
        sta snd_nch
        beq _fn
_ft     ldy snd_owner,x
        bmi _fn
        jsr snd_wanted
        bcs _fn
        lda #$ff
        sta snd_owner,x
_fn     dex
        bpl _free
        lda snd_nv                  ; 2. the noise voice, if it hasn't a channel: a free one, else
        bmi _pt                     ;    the quietest
        lda snd_nch
        bpl _pt
        ldy #0                      ; (a free one: 2, 1, 0)
        jsr snd_freech
        bcc +
        jsr snd_quietest
+       stx snd_nch
        lda snd_nv
        sta snd_owner,x
_pt     ldy #SFX_TONE               ; 3. each tone voice that's wanted but has no channel: the
_place  jsr snd_wanted              ;    sound effect, then the tracks
        bcc _pn
        tya
        ldx #2
_has    cmp snd_owner,x
        beq _pn
        dex
        bpl _has
        sty snd_y
        lda v_raised,y              ; (a bass track: channel 0 first)
        tay
        jsr snd_freech
        ldy snd_y
        bcc _take
        jsr snd_quietest            ; (none free: the quietest, X, its attenuation snd_qa)
        cpy #SFX_TONE
        beq _take
        lda v_att,y
        clc
        adc #4
        cmp snd_qa
        beq _take
        bcs _pn
_take   tya
        sta snd_owner,x
_pn     cpy #SFX_TONE
        bne +
        ldy #$ff
+       iny
        cpy #MAX_TRACKS
        bne _place
        ldx #2                      ; 4. each channel: its voice's divider and volume
_ch     ldy snd_owner,x
        bpl +
        lda #0                      ; (none: silent)
        sta snd_c
        jmp _cc
+       lda v_att,y
        tay
        lda pvol,y
        sta snd_c
        ldy snd_owner,x
        cpx snd_nch
        bne _cton
        lda v_ins,y                 ; the noise: its rate's divider (64kHz), 17-bit noise
        tay
        lda ins_noise,y
        and #3
        tay
        lda pnoise,y
        sta snd_dl
        lda #0
        sta snd_dh
        lda snd_c
        ora #$80
        sta snd_c
        cpx #0
        bne _cf
        lda snd_dl                  ; (on the 16-bit channel: (N + 1) * 28 - 7)
        sec                         ; (+ 1, then * 28 = * 32 - * 4, then - 7)
        adc #0
        sta snd_dl
        jsr snd_x4
        lda snd_dl
        sta snd_ql
        lda snd_dh
        sta snd_qh
        jsr snd_x4
        jsr snd_x4
        jsr snd_x2
        lda snd_dl
        sec
        sbc snd_ql
        sta snd_dl
        lda snd_dh
        sbc snd_qh
        sta snd_dh
        jmp _c16
_cton   lda v_nl,y                  ; a tone: its clock count D
        sta snd_dl
        lda v_nh,y
        sta snd_dh
        lda snd_c
        ora #$a0
        sta snd_c
        cpx #0
        bne _c8
_c16    lda snd_dl                  ; (the 16-bit channel: D - 7)
        sec
        sbc #7
        sta snd_dl
        bcs _cf
        dec snd_dh
        jmp _cf
_c8     jsr snd_div28               ; (an 8-bit one: (D + 14) / 28 - 1, an octave up while that's
        lda snd_dh                  ;  over 255)
        beq +
        lsr snd_dh
        ror snd_dl
        jmp _c8
+       dec snd_dl
_cf     lda chf,x                   ; the divider, if it's changed
        tay
        lda snd_dl
        cmp last_fl,x
        beq +
        sta last_fl,x
        sta AUDF1,y
+       cpx #0
        bne _cc
        lda snd_dh
        cmp last_fh
        beq _cc
        sta last_fh
        sta AUDF1 + 2
_cc     lda chc,x                   ; the volume and distortion, if they've changed
        tay
        lda snd_c
        cmp last_c,x
        beq +
        sta last_c,x
        sta AUDF1,y
+       dex
        bmi +
        jmp _ch
+       rts
chf     .byte 0, 4, 6               ; (each channel's divider: AUDF1 (and AUDF2), AUDF3, AUDF4)
chc     .byte 3, 5, 7               ; (... its control: AUDC2, AUDC3, AUDC4)
snd_x4  jsr snd_x2
snd_x2  asl snd_dl
        rol snd_dh
        rts
; snd_dl/dh = (D + 14) / 28 (D in snd_dl/dh; whole)
snd_div28
        lda snd_dl
        clc
        adc #14
        sta snd_ql
        lda snd_dh
        adc #0
        sta snd_qh
        lda #0
        sta snd_dl
        sta snd_dh
        sta snd_y
        ldy #16
-       asl snd_ql
        rol snd_qh
        rol snd_y
        lda snd_y
        cmp #28
        bcc +
        sbc #28
        sta snd_y
+       rol snd_dl
        rol snd_dh
        dey
        bne -
        rts

; A free channel, X (carry clear), or carry set if none: the tone channels in the order for Y
; (0: 2, 1, 0; 1, a bass track: 0, 2, 1)
snd_freech
        lda chord,y
        sta snd_qc
        lda #3
        sta snd_qa
-       ldx snd_qc
        lda chseq,x
        tax
        lda snd_owner,x
        bmi +
        inc snd_qc
        dec snd_qa
        bne -
        sec
        rts
+       clc
        rts
chord   .byte 0, 3
chseq   .byte 2, 1, 0, 0, 2, 1

; The quietest channel, X (not the noise's), its attenuation snd_qa (Y kept)
snd_quietest
        sty snd_y
        lda #0
        sta snd_qa
        ldx #0
        stx snd_qc
-       cpx snd_nch
        beq +
        ldy snd_owner,x
        lda v_att,y
        cmp snd_qa
        bcc +
        sta snd_qa
        stx snd_qc
+       inx
        cpx #3
        bne -
        ldx snd_qc
        ldy snd_y
        rts

; Carry set if voice Y should be heard on a tone channel now: sounding, and the tone sound effect
; or a tone track that the music option lets play (X kept)
snd_wanted
        lda v_att,y
        cmp #15
        bcs _no
        cpy #SFX_TONE
        beq _yes
        lda v_on,y
        beq _no
        lda v_chan,y
        cmp #3
        beq _no
        lda snd_music_opt
        beq _yes
        cmp #2
        beq _no
        cpy #0                      ; (just the first track)
        bne _no
_yes    sec
        rts
_no     clc
        rts

; The POKEY as the player wants it, and nothing playing
snd_init
        ldx #42
        lda #0
-       sta SV,x
        dex
        bpl -
        lda #$50                    ; (channel 1 on 1.79MHz, joined to 2: 16 bits)
        sta AUDCTL
        ldx #7
        lda #0
-       sta AUDF1,x
        dex
        bpl -
        ldx #2
        lda #$ff
-       sta snd_owner,x
        sta last_fl,x
        sta last_c,x
        dex
        bpl -
        sta snd_nch
        sta snd_music_req
        sta snd_sfx_req
        sta snd_sfx_req2
        sta last_fh
        lda #0
        sta snd_tune
        sta snd_cur
        ldx #NV - 1
-       jsr snd_silence
        lda #0
        sta v_on,x
        dex
        bpl -
        rts

; The game's: start tune A (0: silence), even if it's playing; ... unless it's the one playing;
; start sound effect A (X and Y kept); stop the music and sound effects
play_music
        sta snd_cur
        sta snd_music_req
        rts
play_music_new
        cmp snd_cur
        bne play_music
        rts
play_sfx
        bit snd_sfx_req
        bpl +
        sta snd_sfx_req
        rts
+       sta snd_sfx_req2
        rts

snd_music_opt .byte 0               ; (the options: kept through the program's restarts)
snd_sfx_opt .byte 0
; the player's variables, in low memory free at run time (snd_init sets them): $04c0-$04ff ...
SV      = $04c0
snd_tune = SV
snd_k   = SV + 1                    ; (2)
snd_acc = SV + 3                    ; (2)
snd_qb  = SV + 5                    ; (2)
snd_total = SV + 7                  ; (2)
snd_intro = SV + 9                  ; (2)
snd_tok = SV + 11
snd_semi = SV + 12
snd_env = SV + 13
snd_tmp = SV + 14
snd_p   = SV + 15                   ; (2)
snd_m_last = SV + 17
snd_s_last = SV + 18
snd_owner = SV + 19                 ; (3: the voice each channel is playing: $ff none)
snd_nch = SV + 22                   ; (the noise voice's channel: $ff none)
snd_nv  = SV + 23                   ; (the noise voice this tick: $ff none)
last_fl = SV + 24                   ; (3: each channel's divider and control as last written)
last_fh = SV + 27
last_c  = SV + 28                   ; (3)
snd_y   = SV + 31
snd_qa  = SV + 32
snd_qc  = SV + 33
snd_c   = SV + 34
snd_dl  = SV + 35
snd_dh  = SV + 36
snd_ql  = SV + 37
snd_qh  = SV + 38
snd_music_req = SV + 39             ; (the game's requests)
snd_sfx_req = SV + 40
snd_sfx_req2 = SV + 41
snd_cur = SV + 42
        .cerror SV + 43 > $0500, "the player's variables reach OBJS"
; ... and $0730-$07ff: per voice (the tracks, then the two sound effects)
VV      = $0730
v_on    = VV + NV * 0
v_base  = VV + NV * 1
v_chan  = VV + NV * 2
v_raised= VV + NV * 3
v_ordl  = VV + NV * 4
v_ordh  = VV + NV * 5
v_ord   = VV + NV * 6
v_patl  = VV + NV * 7
v_path  = VV + NV * 8
v_left  = VV + NV * 9
v_ins   = VV + NV * 10
v_semi  = VV + NV * 11
v_env   = VV + NV * 12
v_epos  = VV + NV * 13
v_ampl  = VV + NV * 14
v_amph  = VV + NV * 15
v_phase = VV + NV * 16
v_att   = VV + NV * 17
v_nl    = VV + NV * 18
v_nh    = VV + NV * 19
        .cerror VV + NV * 20 > $0800, "the voices' variables reach the program"
        .include "../build/music.inc"
