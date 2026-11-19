; made by vectrex/tools/calib_gen.py

draw_calib
; pat_a
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$5A9B
                jsr     Moveto_d
                ldx     #move_pat_a
                jsr     vlist_d
                ldx     #pat_a
                lda     #25
                sta     $C880
                jsr     col5_down
; pat_b
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$5A0B
                jsr     Moveto_d
                ldx     #move_pat_b
                jsr     vlist_d
                ldx     #pat_b
                lda     #25
                sta     $C880
                jsr     col5_down
; pat_c
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$F49C
                jsr     Moveto_d
                ldx     #move_pat_c
                jsr     vlist_d
                ldx     #pat_c
                jsr     rows3_10
; pat_d
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$F30C
                jsr     Moveto_d
                ldx     #move_pat_d
                jsr     vlist_d
                ldx     #pat_d1
                stx     $C882
                ldx     #pat_d0
                ldb     #12
                jsr     strip
                rts

move_pat_a
                fcb     1,101,-66,$00
                fcb     0,0
move_pat_b
                fcb     1,101,124,$00
                fcb     0,0
move_pat_c
                fcb     1,-78,-112,$00
                fcb     0,0
move_pat_d
                fcb     1,-31,78,$00
                fcb     0,0

pat_a
                fcb     $00,$00,$08,$00,$00
                fcb     $00,$00,$10,$00,$00
                fcb     $00,$00,$08,$00,$00
                fcb     $00,$00,$10,$00,$00
                fcb     $00,$00,$08,$00,$00
                fcb     $00,$00,$10,$00,$00
                fcb     $00,$00,$08,$00,$00
                fcb     $00,$00,$10,$00,$00
                fcb     $00,$00,$08,$00,$00
                fcb     $00,$00,$10,$00,$00
                fcb     $00,$00,$08,$00,$00
                fcb     $00,$00,$10,$00,$00
                fcb     $00,$00,$08,$00,$00
                fcb     $00,$00,$10,$00,$00
                fcb     $00,$00,$08,$00,$00
                fcb     $00,$00,$10,$00,$00
                fcb     $00,$00,$08,$00,$00
                fcb     $00,$00,$10,$00,$00
                fcb     $00,$00,$08,$00,$00
                fcb     $00,$00,$10,$00,$00
                fcb     $00,$00,$08,$00,$00
                fcb     $00,$00,$10,$00,$00
                fcb     $00,$00,$08,$00,$00
                fcb     $00,$00,$10,$00,$00
pat_b
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
                fcb     $20,$00,$00,$00,$04
pat_c
                fcb     $80,$00,$01
                fcb     $80,$00,$01
                fcb     $80,$00,$01
                fcb     $80,$00,$01
                fcb     $80,$00,$01
                fcb     $80,$00,$01
                fcb     $80,$00,$01
                fcb     $80,$00,$01
                fcb     $80,$00,$01
                fcb     $80,$00,$01
pat_d0
                fcb     $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
pat_d1
                fcb     $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
