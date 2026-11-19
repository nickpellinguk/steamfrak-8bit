; made by vectrex/tools/m1_gen.py: the test scene

draw_scene
; trogg at (-100, -100): columns 0-25 of 26, 5 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7F82
                jsr     Moveto_d
                ldx     #move_0
                jsr     vlist_d
                ldx     #trogg_data+0
                lda     #27
                sta     $C880
                jsr     col5_down
; trogg_s at (-72, -100), swept at 127: columns 0-25 of 26, 4 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7FA5
                jsr     Moveto_d
                ldx     #move_1
                jsr     vlist_d
                ldx     #trogg_s_data+0
                lda     #27
                sta     $C880
                jsr     col4s_down
; scrubbly at (-44, -108): columns 0-32 of 33, 6 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7FC8
                jsr     Moveto_d
                ldx     #move_2
                jsr     vlist_d
                ldx     #scrubbly_data+0
                lda     #34
                sta     $C880
                jsr     col6_down
; scrubbly_s at (-9, -108), swept at 127: columns 0-32 of 33, 4 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7FF5
                jsr     Moveto_d
                ldx     #move_3
                jsr     vlist_d
                ldx     #scrubbly_s_data+0
                lda     #34
                sta     $C880
                jsr     col4s_down
; ladder at (44, -100): columns 0-11 of 12, 10 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7F36
                jsr     Moveto_d
                ldx     #move_4
                jsr     vlist_d
                ldx     #ladder_data+0
                lda     #13
                sta     $C880
                jsr     col10_down
; ladder_s at (58, -100), swept at 127: columns 0-11 of 12, 7 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7F48
                jsr     Moveto_d
                ldx     #move_5
                jsr     vlist_d
                ldx     #ladder_s_data+0
                lda     #13
                sta     $C880
                jsr     col7s_down
; chain at (72, -100): columns 0-7 of 8, 10 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7F5A
                jsr     Moveto_d
                ldx     #move_6
                jsr     vlist_d
                ldx     #chain_data+0
                lda     #9
                sta     $C880
                jsr     col10_down
; chain_s at (84, -100), swept at 127: columns 0-7 of 8, 7 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7F69
                jsr     Moveto_d
                ldx     #move_7
                jsr     vlist_d
                ldx     #chain_s_data+0
                lda     #9
                sta     $C880
                jsr     col7s_down
; trogg_climb at (-100, -50): columns 0-19 of 20, 5 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$4182
                jsr     Moveto_d
                ldx     #move_8
                jsr     vlist_d
                ldx     #trogg_climb_data+0
                lda     #21
                sta     $C880
                jsr     col5_down
; trogg_climb_s at (-78, -50), swept at 127: columns 0-19 of 20, 4 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$439E
                jsr     Moveto_d
                ldx     #move_9
                jsr     vlist_d
                ldx     #trogg_climb_s_data+0
                lda     #21
                sta     $C880
                jsr     col4s_down
; poglet at (-56, -49): columns 0-22 of 23, 5 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$40B9
                jsr     Moveto_d
                ldx     #move_10
                jsr     vlist_d
                ldx     #poglet_data+0
                lda     #24
                sta     $C880
                jsr     col5_down
; poglet_s at (-31, -49), swept at 127: columns 0-22 of 23, 4 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$41D9
                jsr     Moveto_d
                ldx     #move_11
                jsr     vlist_d
                ldx     #poglet_s_data+0
                lda     #24
                sta     $C880
                jsr     col4s_down
; hooter at (-6, -39): columns 0-18 of 19, 4 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$33F8
                jsr     Moveto_d
                ldx     #move_12
                jsr     vlist_d
                ldx     #hooter_data+0
                lda     #20
                sta     $C880
                jsr     col4_down
; hooter_s at (15, -39), swept at 127: columns 0-18 of 19, 3 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$3512
                jsr     Moveto_d
                ldx     #move_13
                jsr     vlist_d
                ldx     #hooter_s_data+0
                lda     #20
                sta     $C880
                jsr     col3s_down
; gem at (-100, 0): columns 0-10 of 11, 2 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$0282
                jsr     Moveto_d
                ldx     #move_14
                jsr     vlist_d
                ldx     #gem_data+0
                lda     #12
                sta     $C880
                jsr     col2_down
; gem_s at (-87, 0), swept at 127: columns 0-10 of 11, 2 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$0492
                jsr     Moveto_d
                ldx     #move_15
                jsr     vlist_d
                ldx     #gem_s_data+0
                lda     #12
                sta     $C880
                jsr     col2s_down
; balloon at (-66, 0): columns 0-11 of 12, 2 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$02AD
                jsr     Moveto_d
                ldx     #move_16
                jsr     vlist_d
                ldx     #balloon_data+0
                lda     #13
                sta     $C880
                jsr     col2_down
; balloon_s at (-52, 0), swept at 127: columns 0-11 of 12, 2 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$04BE
                jsr     Moveto_d
                ldx     #move_17
                jsr     vlist_d
                ldx     #balloon_s_data+0
                lda     #13
                sta     $C880
                jsr     col2s_down
; dagger at (-36, 0): columns 0-10 of 11, 2 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$02D2
                jsr     Moveto_d
                ldx     #move_18
                jsr     vlist_d
                ldx     #dagger_data+0
                lda     #12
                sta     $C880
                jsr     col2_down
; dagger_s at (-22, 0), swept at 127: columns 0-10 of 11, 2 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$04E4
                jsr     Moveto_d
                ldx     #move_19
                jsr     vlist_d
                ldx     #dagger_s_data+0
                lda     #12
                sta     $C880
                jsr     col2s_down
; bulb at (-6, 0): columns 0-9 of 10, 3 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$02F8
                jsr     Moveto_d
                ldx     #move_20
                jsr     vlist_d
                ldx     #bulb_data+0
                lda     #11
                sta     $C880
                jsr     col3_down
; bulb_s at (8, 0), swept at 127: columns 0-9 of 10, 2 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$0409
                jsr     Moveto_d
                ldx     #move_21
                jsr     vlist_d
                ldx     #bulb_s_data+0
                lda     #11
                sta     $C880
                jsr     col2s_down
; key at (30, 0): 10 drifting rows of 3 bytes
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$0025
                jsr     Moveto_d
                ldx     #move_22
                jsr     vlist_d
                ldx     #key_data
                jsr     rows3_10
; scrubbly_s at (-112, 54), swept at 127: columns 9-32 of 33, 4 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$8181
                jsr     Moveto_d
                ldx     #move_23
                jsr     vlist_d
                ldx     #scrubbly_s_data+36
                lda     #25
                sta     $C880
                jsr     col4s_up
; poglet_s at (94, 60), swept at 127: columns 0-8 of 23, 4 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$B975
                jsr     Moveto_d
                ldx     #move_24
                jsr     vlist_d
                ldx     #poglet_s_data+0
                lda     #10
                sta     $C880
                jsr     col4s_down
; ledges at (-120, 30): bytes 2-27 of 30
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$DA81
                jsr     Moveto_d
                ldx     #move_ledges
                jsr     vlist_d
                ldx     #ledges_row1+2
                stx     $C882
                ldx     #ledges_row0+2
                ldb     #26
                jsr     strip
                rts

move_0
                fcb     2,103,-47,$00
                fcb     0,0
move_1
                fcb     4,99,-14,$00
                fcb     0,0
move_2
                fcb     12,124,-1,$00
                fcb     0,0
move_3
                fcb     14,120,-9,$00
                fcb     0,0
move_4
                fcb     2,103,54,$00
                fcb     0,0
move_5
                fcb     4,99,16,$00
                fcb     0,0
move_6
                fcb     2,103,11,$00
                fcb     0,0
move_7
                fcb     4,99,10,$00
                fcb     0,0
move_8
                fcb     1,73,-94,$00
                fcb     0,0
move_9
                fcb     1,7,-126,$00
                fcb     0,0
move_10
                fcb     0,0
move_11
                fcb     1,101,-92,$00
                fcb     0,0
move_12
                fcb     1,89,-25,$00
                fcb     0,0
move_13
                fcb     0,0
move_14
                fcb     1,66,-94,$00
                fcb     0,0
move_15
                fcb     1,0,-44,$00
                fcb     0,0
move_16
                fcb     1,66,-109,$00
                fcb     0,0
move_17
                fcb     0,0
move_18
                fcb     1,66,-4,$00
                fcb     0,0
move_19
                fcb     1,0,-48,$00
                fcb     0,0
move_20
                fcb     1,66,-25,$00
                fcb     0,0
move_21
                fcb     1,0,58,$00
                fcb     0,0
move_22
                fcb     1,0,106,$00
                fcb     0,0
move_23
                fcb     4,-35,-112,$00
                fcb     0,0
move_24
                fcb     1,-84,116,$00
                fcb     0,0
move_ledges
                fcb     5,-12,-105,$00
                fcb     0,0

trogg_data                                  ; 26 columns of 5 bytes
                fcb     $00,$00,$0F,$E0,$00
                fcb     $00,$0E,$98,$00,$00
                fcb     $00,$01,$F2,$F0,$00
                fcb     $00,$0F,$40,$F0,$00
                fcb     $00,$18,$0A,$F0,$00
                fcb     $00,$0F,$FC,$0C,$00
                fcb     $00,$20,$E3,$E0,$70
                fcb     $0B,$87,$85,$C6,$80
                fcb     $03,$C2,$20,$F7,$10
                fcb     $08,$3A,$04,$43,$C0
                fcb     $07,$86,$20,$48,$50
                fcb     $0B,$A2,$06,$23,$F0
                fcb     $0F,$BF,$C0,$43,$F0
                fcb     $0B,$02,$00,$F3,$F8
                fcb     $1F,$60,$00,$60,$10
                fcb     $08,$1F,$00,$3D,$FC
                fcb     $38,$C7,$00,$8F,$D0
                fcb     $0A,$01,$83,$86,$0C
                fcb     $30,$B8,$63,$00,$90
                fcb     $0F,$00,$7F,$F5,$6C
                fcb     $11,$C0,$00,$00,$00
                fcb     $00,$00,$00,$01,$B0
                fcb     $05,$00,$00,$00,$00
                fcb     $00,$00,$00,$00,$A0
                fcb     $05,$00,$00,$00,$00
                fcb     $00,$00,$00,$00,$E0
trogg_climb_data                                  ; 20 columns of 5 bytes
                fcb     $00,$38,$00,$00,$00
                fcb     $00,$00,$00,$37,$00
                fcb     $03,$C7,$FE,$00,$00
                fcb     $00,$07,$C2,$E2,$60
                fcb     $04,$C0,$41,$3F,$80
                fcb     $03,$48,$83,$03,$E0
                fcb     $1F,$C0,$81,$04,$40
                fcb     $02,$F8,$81,$07,$FC
                fcb     $3F,$F1,$81,$F1,$C0
                fcb     $00,$03,$00,$CF,$FC
                fcb     $3F,$FE,$00,$7F,$F0
                fcb     $09,$22,$00,$1F,$FC
                fcb     $3F,$E0,$00,$40,$50
                fcb     $0A,$02,$03,$E3,$F8
                fcb     $07,$FC,$60,$C7,$F0
                fcb     $00,$3F,$8C,$8F,$80
                fcb     $01,$23,$FF,$00,$00
                fcb     $00,$00,$00,$65,$80
                fcb     $00,$CC,$00,$00,$00
                fcb     $00,$00,$00,$1E,$00
scrubbly_data                                  ; 33 columns of 6 bytes
                fcb     $00,$00,$03,$F0,$FC,$00
                fcb     $00,$4F,$C2,$F0,$00,$00
                fcb     $00,$01,$1C,$C7,$20,$00
                fcb     $00,$1E,$3F,$9C,$C0,$00
                fcb     $00,$06,$70,$00,$1E,$00
                fcb     $00,$C0,$00,$03,$70,$00
                fcb     $00,$1F,$80,$00,$01,$E0
                fcb     $0D,$80,$18,$00,$D8,$E0
                fcb     $0D,$32,$1F,$0F,$00,$90
                fcb     $09,$07,$89,$8C,$0C,$58
                fcb     $12,$60,$60,$90,$38,$D0
                fcb     $0B,$07,$89,$E2,$02,$28
                fcb     $16,$C0,$4F,$8F,$00,$70
                fcb     $06,$00,$19,$F2,$01,$CC
                fcb     $3B,$80,$67,$08,$00,$40
                fcb     $02,$00,$08,$7C,$00,$14
                fcb     $20,$00,$00,$08,$00,$40
                fcb     $02,$00,$08,$7C,$00,$1C
                fcb     $19,$80,$67,$08,$00,$40
                fcb     $06,$00,$19,$F2,$01,$CC
                fcb     $36,$C0,$4F,$8F,$00,$70
                fcb     $0B,$07,$89,$E2,$02,$24
                fcb     $2C,$60,$60,$90,$38,$D0
                fcb     $09,$07,$89,$8C,$0C,$64
                fcb     $32,$32,$1F,$0F,$00,$90
                fcb     $0D,$00,$18,$00,$D8,$78
                fcb     $00,$1F,$80,$00,$01,$E0
                fcb     $00,$C0,$00,$03,$70,$00
                fcb     $00,$06,$70,$00,$1E,$00
                fcb     $00,$1E,$3F,$9C,$C0,$00
                fcb     $00,$01,$1C,$C7,$20,$00
                fcb     $00,$4F,$C2,$F0,$00,$00
                fcb     $00,$00,$03,$F0,$FC,$00
poglet_data                                  ; 23 columns of 5 bytes
                fcb     $00,$00,$00,$1E,$E0
                fcb     $05,$CC,$00,$00,$00
                fcb     $00,$07,$F0,$20,$A0
                fcb     $04,$F4,$78,$38,$00
                fcb     $00,$70,$03,$6B,$E0
                fcb     $03,$92,$8F,$FF,$80
                fcb     $07,$43,$1D,$FB,$60
                fcb     $04,$70,$E0,$82,$30
                fcb     $19,$E3,$F2,$06,$20
                fcb     $04,$C0,$50,$38,$D8
                fcb     $36,$17,$76,$03,$E0
                fcb     $05,$40,$0B,$C8,$24
                fcb     $24,$13,$D0,$02,$A0
                fcb     $05,$C0,$6E,$E8,$24
                fcb     $24,$3C,$0A,$03,$20
                fcb     $06,$FE,$4F,$C6,$3C
                fcb     $00,$41,$03,$C0,$40
                fcb     $03,$00,$80,$42,$00
                fcb     $00,$7E,$00,$FF,$E0
                fcb     $04,$F4,$00,$00,$00
                fcb     $00,$00,$00,$20,$A0
                fcb     $05,$CC,$00,$00,$00
                fcb     $00,$00,$00,$1E,$E0
hooter_data                                  ; 19 columns of 4 bytes
                fcb     $18,$1F,$81,$80
                fcb     $01,$81,$0E,$1C
                fcb     $20,$C1,$F2,$80
                fcb     $01,$58,$71,$CC
                fcb     $0F,$38,$0D,$80
                fcb     $01,$20,$01,$98
                fcb     $16,$8F,$04,$80
                fcb     $01,$61,$AD,$68
                fcb     $1F,$C8,$85,$80
                fcb     $00,$21,$10,$90
                fcb     $1F,$C8,$85,$80
                fcb     $01,$61,$AD,$68
                fcb     $16,$8F,$04,$80
                fcb     $01,$20,$01,$98
                fcb     $0F,$38,$0D,$80
                fcb     $01,$58,$71,$CC
                fcb     $20,$E1,$F2,$80
                fcb     $01,$81,$1C,$1C
                fcb     $18,$0F,$81,$80
gem_data                                  ; 11 columns of 2 bytes
                fcb     $0C,$00
                fcb     $00,$78
                fcb     $33,$00
                fcb     $01,$94
                fcb     $28,$C0
                fcb     $06,$14
                fcb     $28,$C0
                fcb     $01,$94
                fcb     $33,$00
                fcb     $00,$78
                fcb     $0C,$00
balloon_data                                  ; 12 columns of 2 bytes
                fcb     $0F,$80
                fcb     $02,$08
                fcb     $10,$40
                fcb     $04,$04
                fcb     $20,$20
                fcb     $0C,$04
                fcb     $20,$30
                fcb     $04,$04
                fcb     $20,$20
                fcb     $02,$08
                fcb     $10,$40
                fcb     $01,$F0
dagger_data                                  ; 11 columns of 2 bytes
                fcb     $00,$08
                fcb     $0C,$00
                fcb     $00,$50
                fcb     $05,$88
                fcb     $1A,$40
                fcb     $02,$30
                fcb     $06,$80
                fcb     $00,$F0
                fcb     $3D,$80
                fcb     $03,$18
                fcb     $08,$00
bulb_data                                  ; 10 columns of 3 bytes
                fcb     $00,$3E,$00
                fcb     $00,$C6,$00
                fcb     $11,$C1,$80
                fcb     $01,$00,$FC
                fcb     $3C,$00,$80
                fcb     $01,$00,$3C
                fcb     $3F,$00,$80
                fcb     $01,$83,$88
                fcb     $00,$63,$00
                fcb     $00,$7C,$00
ladder_data                                  ; 12 columns of 10 bytes
                fcb     $0E,$1C,$38,$70,$E1,$C3,$87,$0E,$1C,$00
                fcb     $00,$28,$50,$A1,$42,$85,$0A,$14,$28,$50
                fcb     $0A,$14,$28,$50,$A1,$42,$85,$0A,$14,$00
                fcb     $00,$28,$50,$A1,$42,$85,$0A,$14,$28,$50
                fcb     $3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
                fcb     $00,$10,$20,$40,$81,$02,$04,$08,$10,$20
                fcb     $04,$08,$10,$20,$40,$81,$02,$04,$08,$00
                fcb     $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FC
                fcb     $0A,$14,$28,$50,$A1,$42,$85,$0A,$14,$00
                fcb     $00,$28,$50,$A1,$42,$85,$0A,$14,$28,$50
                fcb     $0A,$14,$28,$50,$A1,$42,$85,$0A,$14,$00
                fcb     $00,$38,$70,$E1,$C3,$87,$0E,$1C,$38,$70
chain_data                                  ; 8 columns of 10 bytes
                fcb     $38,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8
                fcb     $30,$0C,$C0,$33,$00,$CC,$03,$30,$0A,$34
                fcb     $27,$A7,$E7,$9F,$9E,$7E,$79,$F9,$E7,$E4
                fcb     $2C,$54,$A9,$52,$A5,$4A,$95,$2A,$57,$24
                fcb     $24,$72,$54,$A9,$52,$A5,$4A,$95,$2A,$34
                fcb     $27,$CF,$CF,$3F,$3C,$FC,$F3,$F3,$E0,$E4
                fcb     $2D,$88,$20,$10,$80,$42,$01,$08,$04,$0C
                fcb     $1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1C
key_data                                  ; 10 rows of 3 bytes
                fcb     $00,$00,$F0
                fcb     $19,$80,$00
                fcb     $00,$03,$0C
                fcb     $2C,$7F,$FF
                fcb     $80,$00,$34
                fcb     $2C,$7F,$FF
                fcb     $42,$03,$0C
                fcb     $19,$80,$42
                fcb     $5A,$00,$F0
                fcb     $00,$00,$66
yoyo_data                                  ; 6 rows of 1 bytes
                fcb     $7C
                fcb     $63
                fcb     $F2
                fcb     $5F
                fcb     $FE
                fcb     $3E
trogg_s_data                                  ; 26 columns of 4 bytes
                fcb     $00,$07,$C0,$00
                fcb     $00,$03,$B0,$00
                fcb     $00,$3B,$C0,$00
                fcb     $00,$03,$C7,$00
                fcb     $01,$87,$C0,$00
                fcb     $00,$03,$F0,$80
                fcb     $01,$3B,$C6,$00
                fcb     $00,$73,$96,$E0
                fcb     $0E,$49,$DA,$00
                fcb     $00,$4F,$12,$70
                fcb     $1C,$C8,$A6,$00
                fcb     $00,$79,$19,$78
                fcb     $1D,$F0,$9E,$00
                fcb     $00,$71,$07,$7C
                fcb     $3F,$00,$C2,$00
                fcb     $00,$47,$81,$BC
                fcb     $36,$E1,$3E,$00
                fcb     $00,$60,$8C,$C4
                fcb     $25,$9B,$0A,$00
                fcb     $00,$70,$7F,$BC
                fcb     $26,$00,$00,$00
                fcb     $00,$00,$00,$28
                fcb     $14,$00,$00,$00
                fcb     $00,$00,$00,$28
                fcb     $14,$00,$00,$00
                fcb     $00,$00,$00,$38
trogg_climb_s_data                                  ; 20 columns of 4 bytes
                fcb     $01,$80,$00,$00
                fcb     $00,$00,$01,$E0
                fcb     $0E,$FE,$00,$00
                fcb     $00,$03,$CF,$58
                fcb     $16,$11,$78,$00
                fcb     $00,$3A,$8C,$78
                fcb     $3E,$21,$14,$00
                fcb     $00,$3E,$84,$FC
                fcb     $3F,$21,$CC,$00
                fcb     $00,$01,$86,$FC
                fcb     $3F,$C0,$FE,$00
                fcb     $00,$59,$01,$FC
                fcb     $3F,$00,$86,$00
                fcb     $00,$61,$0F,$7C
                fcb     $1F,$99,$9E,$00
                fcb     $00,$0F,$94,$E0
                fcb     $05,$7F,$00,$00
                fcb     $00,$00,$03,$A0
                fcb     $06,$80,$00,$00
                fcb     $00,$00,$01,$C0
scrubbly_s_data                                  ; 33 columns of 4 bytes
                fcb     $00,$03,$CF,$80
                fcb     $01,$79,$E0,$00
                fcb     $00,$2D,$9A,$00
                fcb     $00,$EF,$B6,$00
                fcb     $00,$D8,$03,$80
                fcb     $03,$00,$0F,$00
                fcb     $01,$E0,$00,$70
                fcb     $0A,$06,$07,$B8
                fcb     $15,$4F,$38,$50
                fcb     $0A,$72,$90,$9C
                fcb     $2B,$19,$43,$70
                fcb     $0E,$72,$E8,$4C
                fcb     $3E,$17,$38,$30
                fcb     $0C,$06,$E8,$34
                fcb     $3C,$1F,$20,$20
                fcb     $04,$02,$70,$0C
                fcb     $20,$00,$20,$20
                fcb     $04,$02,$70,$0C
                fcb     $34,$1F,$20,$20
                fcb     $0C,$06,$E8,$34
                fcb     $3E,$17,$38,$30
                fcb     $0E,$72,$E8,$4C
                fcb     $33,$19,$43,$70
                fcb     $0A,$72,$90,$9C
                fcb     $29,$4F,$38,$50
                fcb     $0A,$06,$07,$9C
                fcb     $01,$E0,$00,$70
                fcb     $03,$00,$0F,$00
                fcb     $00,$D8,$03,$80
                fcb     $00,$EF,$B6,$00
                fcb     $00,$2D,$9A,$00
                fcb     $01,$79,$E0,$00
                fcb     $00,$03,$CF,$80
poglet_s_data                                  ; 23 columns of 4 bytes
                fcb     $00,$00,$7E,$00
                fcb     $00,$5A,$00,$00
                fcb     $00,$F8,$4A,$00
                fcb     $00,$5E,$71,$80
                fcb     $03,$03,$FE,$00
                fcb     $00,$35,$9F,$E0
                fcb     $1E,$6D,$FE,$00
                fcb     $00,$4C,$E4,$48
                fcb     $37,$7A,$12,$00
                fcb     $00,$58,$61,$BC
                fcb     $39,$FE,$1E,$00
                fcb     $00,$58,$1E,$8C
                fcb     $31,$78,$1A,$00
                fcb     $00,$58,$7F,$8C
                fcb     $31,$86,$1A,$00
                fcb     $00,$7F,$5E,$CC
                fcb     $02,$23,$84,$00
                fcb     $00,$30,$82,$40
                fcb     $03,$C1,$FE,$00
                fcb     $00,$5E,$00,$00
                fcb     $00,$00,$4A,$00
                fcb     $00,$5A,$00,$00
                fcb     $00,$00,$7E,$00
hooter_s_data                                  ; 19 columns of 3 bytes
                fcb     $31,$E1,$00
                fcb     $00,$84,$CC
                fcb     $26,$3B,$00
                fcb     $00,$F3,$34
                fcb     $1D,$85,$00
                fcb     $00,$A0,$2C
                fcb     $3C,$E5,$00
                fcb     $00,$E5,$BC
                fcb     $3E,$A5,$00
                fcb     $00,$25,$28
                fcb     $3E,$A5,$00
                fcb     $00,$E5,$BC
                fcb     $3C,$E5,$00
                fcb     $00,$A0,$2C
                fcb     $1D,$85,$00
                fcb     $00,$F3,$34
                fcb     $27,$3B,$00
                fcb     $00,$85,$8C
                fcb     $30,$E1,$00
gem_s_data                                  ; 11 columns of 2 bytes
                fcb     $10,$00
                fcb     $00,$1C
                fcb     $2C,$00
                fcb     $00,$2C
                fcb     $36,$00
                fcb     $00,$CC
                fcb     $36,$00
                fcb     $00,$2C
                fcb     $2C,$00
                fcb     $00,$1C
                fcb     $10,$00
balloon_s_data                                  ; 12 columns of 2 bytes
                fcb     $1C,$00
                fcb     $00,$44
                fcb     $22,$00
                fcb     $00,$84
                fcb     $21,$00
                fcb     $00,$84
                fcb     $21,$00
                fcb     $00,$84
                fcb     $21,$00
                fcb     $00,$44
                fcb     $22,$00
                fcb     $00,$38
dagger_s_data                                  ; 11 columns of 2 bytes
                fcb     $00,$80
                fcb     $00,$80
                fcb     $03,$00
                fcb     $00,$A4
                fcb     $3A,$00
                fcb     $00,$48
                fcb     $1C,$00
                fcb     $00,$38
                fcb     $34,$00
                fcb     $00,$6C
                fcb     $10,$00
bulb_s_data                                  ; 10 columns of 2 bytes
                fcb     $01,$C0
                fcb     $06,$C0
                fcb     $26,$20
                fcb     $04,$3C
                fcb     $30,$20
                fcb     $04,$0C
                fcb     $3C,$20
                fcb     $04,$64
                fcb     $03,$60
                fcb     $03,$80
ladder_s_data                                  ; 12 columns of 7 bytes
                fcb     $19,$8C,$CE,$67,$33,$38,$00
                fcb     $00,$14,$CC,$A6,$53,$31,$98
                fcb     $19,$8C,$CA,$65,$33,$28,$00
                fcb     $00,$14,$CC,$A6,$53,$31,$98
                fcb     $3F,$FF,$FF,$FF,$FF,$FC,$00
                fcb     $00,$08,$84,$42,$22,$11,$08
                fcb     $10,$88,$44,$42,$21,$10,$00
                fcb     $00,$3F,$FF,$FF,$FF,$FF,$FC
                fcb     $19,$8C,$CA,$65,$33,$28,$00
                fcb     $00,$14,$CC,$A6,$53,$31,$98
                fcb     $19,$8C,$CA,$65,$33,$28,$00
                fcb     $00,$1C,$CC,$E6,$73,$31,$98
chain_s_data                                  ; 8 columns of 7 bytes
                fcb     $33,$FF,$FF,$FF,$FF,$FF,$80
                fcb     $03,$05,$86,$83,$41,$A0,$CC
                fcb     $3D,$FF,$7B,$BD,$DE,$EF,$40
                fcb     $03,$9D,$B6,$EB,$76,$BB,$EC
                fcb     $33,$5D,$6E,$D7,$6D,$B9,$C0
                fcb     $02,$F7,$B7,$BB,$DD,$EF,$3C
                fcb     $34,$88,$48,$24,$12,$08,$C0
                fcb     $01,$FF,$FF,$FF,$FF,$FF,$EC
ledges_row0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$00,$00,$6F,$4D,$6F,$4D,$6F,$4D
                fcb     $00,$00,$6F,$4D,$6F,$4D,$6F,$4D,$00,$00,$6F,$4D,$6F,$4D
ledges_row1                             ; (reversed: swept to the left)
                fcb     $B2,$E2,$B2,$E2,$00,$00,$B2,$E2,$B2,$E2,$B2,$E2,$00,$00,$B2,$E2
                fcb     $B2,$E2,$B2,$E2,$00,$00,$B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2
