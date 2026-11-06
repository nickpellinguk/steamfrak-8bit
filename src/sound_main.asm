\ ------------------------------------------------------------------------------
\ Music and sound effects: the part in main RAM (constants, the player's
\ variables, and the instrument, pitch and loudness tables). The player itself
\ and the tunes are in src/sound.asm.
\ ------------------------------------------------------------------------------

INCLUDE "src/gen/music_main.asm"

NV = MAX_TRACKS + 2                 \ voices: the tracks, then a tone and a noise sound effect
SFX_TONE = MAX_TRACKS
SFX_NOISE = MAX_TRACKS + 1
SFX_STOP = &7F                      \ (as a sound effect: stop them)
INKEY_M = &65                       \ (internal key numbers)
INKEY_S = &51
SYSVIA_ORA_HS = &FE41               \ port A with handshake


\ The player's variables
.snd_tune   EQUB 0
.snd_k      EQUW 0
.snd_acc    EQUW 0
.snd_qb     EQUW 0
.snd_total  EQUW 0
.snd_intro  EQUW 0
.snd_tok    EQUB 0
.snd_semi   EQUB 0
.snd_env    EQUB 0
.snd_tmp    EQUB 0
.snd_p      EQUW 0
.snd_m_last EQUB 0
.snd_s_last EQUB 0
.last_nl    EQUB 0, 0, 0
.last_nh    EQUB 0, 0, 0
.last_att   EQUB 0, 0, 0, 0             \ (not 15, so the first tick silences everything)
.last_noise EQUB 0
.v_on       SKIP NV                     \ per voice (the tracks, then the two sound effects)
.v_base     SKIP NV
.v_chan     SKIP NV
.v_ordl     SKIP NV
.v_ordh     SKIP NV
.v_ord      SKIP NV
.v_patl     SKIP NV
.v_path     SKIP NV
.v_left     SKIP NV
.v_ins      SKIP NV
.v_semi     SKIP NV
.v_env      SKIP NV
.v_epos     SKIP NV
.v_ampl     SKIP NV
.v_amph     SKIP NV
.v_phase    SKIP NV                     \ 0 off, 1 attack, 2 decay, 3 sustain, 4 release
.v_att      SKIP NV
.v_nl       SKIP NV
.v_nh       SKIP NV

