; made by vectrex/tools/m1_trim_gen.py: the test scene

draw_scene
; trogg at (-100, -100): full columns 0-25 of 26, 5 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7F82
                jsr     Moveto_d
                ldx     #move_0
                jsr     vlist_d
dc_0_start
                ldx     #trogg_data+0
                lda     #27
                sta     $C880
                jsr     col5_down
dc_0_end
; trogg at (-72, -100): trimmed columns 0-25 of 26
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$68A6
                jsr     Moveto_d
                ldx     #move_1
                jsr     vlist_d
dc_1_start
                ldx     #trogg_t_data+0
                lda     #26
                sta     <$06
                ldu     #$0120
                jsr     trim_down
dc_1_end
; scrubbly at (-44, -108): full columns 0-32 of 33, 6 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7FC8
                jsr     Moveto_d
                ldx     #move_2
                jsr     vlist_d
dc_2_start
                ldx     #scrubbly_data+0
                lda     #34
                sta     $C880
                jsr     col6_down
dc_2_end
; scrubbly at (-9, -108): trimmed columns 0-32 of 33
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$6FF6
                jsr     Moveto_d
                ldx     #move_3
                jsr     vlist_d
dc_3_start
                ldx     #scrubbly_t_data+0
                lda     #33
                sta     <$06
                ldu     #$0120
                jsr     trim_down
dc_3_end
; ladder at (44, -100): full columns 0-11 of 12, 10 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7F36
                jsr     Moveto_d
                ldx     #move_4
                jsr     vlist_d
dc_4_start
                ldx     #ladder_data+0
                lda     #13
                sta     $C880
                jsr     col10_down
dc_4_end
; ladder at (58, -100): trimmed columns 0-11 of 12
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7C49
                jsr     Moveto_d
                ldx     #move_5
                jsr     vlist_d
dc_5_start
                ldx     #ladder_t_data+0
                lda     #12
                sta     <$06
                ldu     #$0120
                jsr     trim_down
dc_5_end
; chain at (72, -100): full columns 0-7 of 8, 10 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7F5A
                jsr     Moveto_d
                ldx     #move_6
                jsr     vlist_d
dc_6_start
                ldx     #chain_data+0
                lda     #9
                sta     $C880
                jsr     col10_down
dc_6_end
; chain at (84, -100): trimmed columns 0-7 of 8
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7E6A
                jsr     Moveto_d
                ldx     #move_7
                jsr     vlist_d
dc_7_start
                ldx     #chain_t_data+0
                lda     #8
                sta     <$06
                ldu     #$0120
                jsr     trim_down
dc_7_end
; trogg_climb at (-100, -50): full columns 0-19 of 20, 5 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$4182
                jsr     Moveto_d
                ldx     #move_8
                jsr     vlist_d
dc_8_start
                ldx     #trogg_climb_data+0
                lda     #21
                sta     $C880
                jsr     col5_down
dc_8_end
; trogg_climb at (-78, -50): trimmed columns 0-19 of 20
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$359F
                jsr     Moveto_d
                ldx     #move_9
                jsr     vlist_d
dc_9_start
                ldx     #trogg_climb_t_data+0
                lda     #20
                sta     <$06
                ldu     #$0120
                jsr     trim_down
dc_9_end
; poglet at (-56, -49): full columns 0-22 of 23, 5 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$40B9
                jsr     Moveto_d
                ldx     #move_10
                jsr     vlist_d
dc_10_start
                ldx     #poglet_data+0
                lda     #24
                sta     $C880
                jsr     col5_down
dc_10_end
; poglet at (-31, -49): trimmed columns 0-22 of 23
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$1EDA
                jsr     Moveto_d
                ldx     #move_11
                jsr     vlist_d
dc_11_start
                ldx     #poglet_t_data+0
                lda     #23
                sta     <$06
                ldu     #$0120
                jsr     trim_down
dc_11_end
; hooter at (-6, -39): full columns 0-18 of 19, 4 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$33F8
                jsr     Moveto_d
                ldx     #move_12
                jsr     vlist_d
dc_12_start
                ldx     #hooter_data+0
                lda     #20
                sta     $C880
                jsr     col4_down
dc_12_end
; hooter at (15, -39): trimmed columns 0-18 of 19
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$3013
                jsr     Moveto_d
                ldx     #move_13
                jsr     vlist_d
dc_13_start
                ldx     #hooter_t_data+0
                lda     #19
                sta     <$06
                ldu     #$0120
                jsr     trim_down
dc_13_end
; gem at (-100, 0): full columns 0-10 of 11, 2 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$0282
                jsr     Moveto_d
                ldx     #move_14
                jsr     vlist_d
dc_14_start
                ldx     #gem_data+0
                lda     #12
                sta     $C880
                jsr     col2_down
dc_14_end
; gem at (-87, 0): trimmed columns 0-10 of 11
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$FF93
                jsr     Moveto_d
                ldx     #move_15
                jsr     vlist_d
dc_15_start
                ldx     #gem_t_data+0
                lda     #11
                sta     <$06
                ldu     #$0120
                jsr     trim_down
dc_15_end
; balloon at (-66, 0): full columns 0-11 of 12, 2 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$02AD
                jsr     Moveto_d
                ldx     #move_16
                jsr     vlist_d
dc_16_start
                ldx     #balloon_data+0
                lda     #13
                sta     $C880
                jsr     col2_down
dc_16_end
; balloon at (-52, 0): trimmed columns 0-11 of 12
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$FFC0
                jsr     Moveto_d
                ldx     #move_17
                jsr     vlist_d
dc_17_start
                ldx     #balloon_t_data+0
                lda     #12
                sta     <$06
                ldu     #$0120
                jsr     trim_down
dc_17_end
; dagger at (-36, 0): full columns 0-10 of 11, 2 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$02D2
                jsr     Moveto_d
                ldx     #move_18
                jsr     vlist_d
dc_18_start
                ldx     #dagger_data+0
                lda     #12
                sta     $C880
                jsr     col2_down
dc_18_end
; dagger at (-22, 0): trimmed columns 0-10 of 11
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$F5E5
                jsr     Moveto_d
                ldx     #move_19
                jsr     vlist_d
dc_19_start
                ldx     #dagger_t_data+0
                lda     #11
                sta     <$06
                ldu     #$0120
                jsr     trim_down
dc_19_end
; bulb at (-6, 0): full columns 0-9 of 10, 3 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$02F8
                jsr     Moveto_d
                ldx     #move_20
                jsr     vlist_d
dc_20_start
                ldx     #bulb_data+0
                lda     #11
                sta     $C880
                jsr     col3_down
dc_20_end
; bulb at (8, 0): trimmed columns 0-9 of 10
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$F70A
                jsr     Moveto_d
                ldx     #move_21
                jsr     vlist_d
dc_21_start
                ldx     #bulb_t_data+0
                lda     #10
                sta     <$06
                ldu     #$0120
                jsr     trim_down
dc_21_end
; scrubbly at (-112, 54): trimmed columns 9-32 of 33
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$8281
                jsr     Moveto_d
                ldx     #move_22
                jsr     vlist_d
dc_22_start
                ldx     #scrubbly_t_data+59
                lda     #24
                sta     <$06
                ldu     #$0120
                jsr     trim_up
dc_22_end
; poglet at (94, 60): trimmed columns 0-8 of 23
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$9677
                jsr     Moveto_d
                ldx     #move_23
                jsr     vlist_d
dc_23_start
                ldx     #poglet_t_data+0
                lda     #9
                sta     <$06
                ldu     #$0120
                jsr     trim_down
dc_23_end
                rts

move_0
                fcb     2,103,-47,$00
                fcb     0,0
move_1
                fcb     0,0
move_2
                fcb     12,124,-1,$00
                fcb     0,0
move_3
                fcb     1,77,-91,$00
                fcb     0,0
move_4
                fcb     2,103,54,$00
                fcb     0,0
move_5
                fcb     1,27,98,$00
                fcb     0,0
move_6
                fcb     2,103,11,$00
                fcb     0,0
move_7
                fcb     1,94,71,$00
                fcb     0,0
move_8
                fcb     1,73,-94,$00
                fcb     0,0
move_9
                fcb     1,76,-93,$00
                fcb     0,0
move_10
                fcb     0,0
move_11
                fcb     1,114,-59,$00
                fcb     0,0
move_12
                fcb     1,89,-25,$00
                fcb     0,0
move_13
                fcb     1,70,69,$00
                fcb     0,0
move_14
                fcb     1,66,-94,$00
                fcb     0,0
move_15
                fcb     1,-113,-11,$00
                fcb     0,0
move_16
                fcb     1,66,-109,$00
                fcb     0,0
move_17
                fcb     1,-113,-120,$00
                fcb     0,0
move_18
                fcb     1,66,-4,$00
                fcb     0,0
move_19
                fcb     1,-124,-14,$00
                fcb     0,0
move_20
                fcb     1,66,-25,$00
                fcb     0,0
move_21
                fcb     1,-58,91,$00
                fcb     0,0
move_22
                fcb     3,-31,-96,$00
                fcb     0,0
move_23
                fcb     1,-71,22,$00
                fcb     0,0

trogg_data
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
trogg_climb_data
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
scrubbly_data
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
poglet_data
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
hooter_data
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
gem_data
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
balloon_data
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
dagger_data
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
bulb_data
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
ladder_data
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
chain_data
                fcb     $38,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8
                fcb     $30,$0C,$C0,$33,$00,$CC,$03,$30,$0A,$34
                fcb     $27,$A7,$E7,$9F,$9E,$7E,$79,$F9,$E7,$E4
                fcb     $2C,$54,$A9,$52,$A5,$4A,$95,$2A,$57,$24
                fcb     $24,$72,$54,$A9,$52,$A5,$4A,$95,$2A,$34
                fcb     $27,$CF,$CF,$3F,$3C,$FC,$F3,$F3,$E0,$E4
                fcb     $2D,$88,$20,$10,$80,$42,$01,$08,$04,$0C
                fcb     $1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1C
trogg_t_data
                fcb     $FE
                fdb     td_slots+77             ; 1 bytes
                fcb     $3A
                fdb     tu_slots+70             ; 2 bytes
                fcb     $60
                fcb     $1F
                fdb     td_slots+63             ; 3 bytes
                fcb     $2F,$00
                fcb     $00
                fdb     tu_slots+56             ; 4 bytes
                fcb     $3D,$03,$C0
                fcb     $01
                fdb     td_slots+56             ; 4 bytes
                fcb     $80,$AF,$00
                fcb     $00
                fdb     tu_slots+56             ; 4 bytes
                fcb     $3F,$F0,$30
                fcb     $02
                fdb     td_slots+49             ; 5 bytes
                fcb     $0E,$3E,$07,$00
                fcb     $00
                fdb     tu_slots+49             ; 5 bytes
                fcb     $2E,$1E,$17,$1A
                fcb     $3C
                fdb     td_slots+49             ; 5 bytes
                fcb     $22,$0F,$71,$00
                fcb     $00
                fdb     tu_slots+42             ; 6 bytes
                fcb     $20,$E8,$11,$0F,$00
                fcb     $00
                fdb     td_slots+42             ; 6 bytes
                fcb     $78,$62,$04,$85,$00
                fcb     $00
                fdb     tu_slots+42             ; 6 bytes
                fcb     $2E,$88,$18,$8F,$C0
                fcb     $00
                fdb     td_slots+42             ; 6 bytes
                fcb     $FB,$FC,$04,$3F,$00
                fcb     $00
                fdb     tu_slots+42             ; 6 bytes
                fcb     $2C,$08,$03,$CF,$E0
                fcb     $01
                fdb     td_slots+42             ; 6 bytes
                fcb     $F6,$00,$06,$01,$00
                fcb     $00
                fdb     tu_slots+42             ; 6 bytes
                fcb     $20,$7C,$00,$F7,$F0
                fcb     $03
                fdb     td_slots+42             ; 6 bytes
                fcb     $8C,$70,$08,$FD,$00
                fcb     $00
                fdb     tu_slots+42             ; 6 bytes
                fcb     $28,$06,$0E,$18,$30
                fcb     $03
                fdb     td_slots+42             ; 6 bytes
                fcb     $0B,$86,$30,$09,$00
                fcb     $00
                fdb     tu_slots+42             ; 6 bytes
                fcb     $3C,$01,$FF,$D5,$B0
                fcb     $01
                fdb     td_slots+70             ; 2 bytes
                fcb     $1C
                fcb     $06
                fdb     tu_slots+70             ; 2 bytes
                fcb     $C0
                fcb     $00
                fdb     td_slots+70             ; 2 bytes
                fcb     $50
                fcb     $02
                fdb     tu_slots+70             ; 2 bytes
                fcb     $80
                fcb     $00
                fdb     td_slots+70             ; 2 bytes
                fcb     $50
                fcb     $03
                fdb     tu_slots+70             ; 2 bytes
                fcb     $80
trogg_climb_t_data
                fcb     $E0
                fdb     td_slots+77             ; 1 bytes
                fcb     $03
                fdb     tu_slots+70             ; 2 bytes
                fcb     $70
                fcb     $0F
                fdb     td_slots+63             ; 3 bytes
                fcb     $1F,$F8
                fcb     $7C
                fdb     tu_slots+63             ; 3 bytes
                fcb     $2E,$26
                fcb     $13
                fdb     td_slots+56             ; 4 bytes
                fcb     $01,$04,$FE
                fcb     $34
                fdb     tu_slots+56             ; 4 bytes
                fcb     $88,$30,$3E
                fcb     $7F
                fdb     td_slots+49             ; 5 bytes
                fcb     $02,$04,$11,$00
                fcb     $00
                fdb     tu_slots+42             ; 6 bytes
                fcb     $2F,$88,$10,$7F,$C0
                fcb     $00
                fdb     td_slots+42             ; 6 bytes
                fcb     $FF,$C6,$07,$C7,$00
                fcb     $00
                fdb     tu_slots+42             ; 6 bytes
                fcb     $00,$30,$0C,$FF,$C0
                fcb     $00
                fdb     td_slots+42             ; 6 bytes
                fcb     $FF,$F8,$01,$FF,$C0
                fcb     $00
                fdb     tu_slots+42             ; 6 bytes
                fcb     $92,$20,$01,$FF,$C0
                fcb     $00
                fdb     td_slots+42             ; 6 bytes
                fcb     $FF,$80,$01,$01,$40
                fcb     $00
                fdb     tu_slots+42             ; 6 bytes
                fcb     $A0,$20,$3E,$3F,$80
                fcb     $00
                fdb     td_slots+42             ; 6 bytes
                fcb     $1F,$F1,$83,$1F,$C0
                fcb     $00
                fdb     tu_slots+49             ; 5 bytes
                fcb     $03,$F8,$C8,$F8
                fcb     $04
                fdb     td_slots+63             ; 3 bytes
                fcb     $8F,$FC
                fcb     $00
                fdb     tu_slots+63             ; 3 bytes
                fcb     $06,$58
                fcb     $03
                fdb     td_slots+70             ; 2 bytes
                fcb     $30
                fcb     $01
                fdb     tu_slots+70             ; 2 bytes
                fcb     $E0
scrubbly_t_data
                fcb     $FC
                fdb     td_slots+63             ; 3 bytes
                fcb     $3F,$00
                fcb     $00
                fdb     tu_slots+56             ; 4 bytes
                fcb     $4F,$C2,$F0
                fcb     $47
                fdb     td_slots+63             ; 3 bytes
                fcb     $31,$C8
                fcb     $1E
                fdb     tu_slots+56             ; 4 bytes
                fcb     $3F,$9C,$C0
                fcb     $01
                fdb     td_slots+49             ; 5 bytes
                fcb     $9C,$00,$07,$80
                fcb     $00
                fdb     tu_slots+49             ; 5 bytes
                fcb     $C0,$00,$03,$70
                fcb     $07
                fdb     td_slots+49             ; 5 bytes
                fcb     $E0,$00,$00,$78
                fcb     $0D
                fdb     tu_slots+42             ; 6 bytes
                fcb     $80,$18,$00,$D8,$E0
                fcb     $03
                fdb     td_slots+42             ; 6 bytes
                fcb     $4C,$87,$C3,$C0,$24
                fcb     $09
                fdb     tu_slots+42             ; 6 bytes
                fcb     $07,$89,$8C,$0C,$58
                fcb     $04
                fdb     td_slots+42             ; 6 bytes
                fcb     $98,$18,$24,$0E,$34
                fcb     $0B
                fdb     tu_slots+42             ; 6 bytes
                fcb     $07,$89,$E2,$02,$28
                fcb     $05
                fdb     td_slots+42             ; 6 bytes
                fcb     $B0,$13,$E3,$C0,$1C
                fcb     $06
                fdb     tu_slots+42             ; 6 bytes
                fcb     $00,$19,$F2,$01,$CC
                fcb     $0E
                fdb     td_slots+42             ; 6 bytes
                fcb     $E0,$19,$C2,$00,$10
                fcb     $02
                fdb     tu_slots+42             ; 6 bytes
                fcb     $00,$08,$7C,$00,$14
                fcb     $08
                fdb     td_slots+42             ; 6 bytes
                fcb     $00,$00,$02,$00,$10
                fcb     $02
                fdb     tu_slots+42             ; 6 bytes
                fcb     $00,$08,$7C,$00,$1C
                fcb     $06
                fdb     td_slots+42             ; 6 bytes
                fcb     $60,$19,$C2,$00,$10
                fcb     $06
                fdb     tu_slots+42             ; 6 bytes
                fcb     $00,$19,$F2,$01,$CC
                fcb     $0D
                fdb     td_slots+42             ; 6 bytes
                fcb     $B0,$13,$E3,$C0,$1C
                fcb     $0B
                fdb     tu_slots+42             ; 6 bytes
                fcb     $07,$89,$E2,$02,$24
                fcb     $0B
                fdb     td_slots+42             ; 6 bytes
                fcb     $18,$18,$24,$0E,$34
                fcb     $09
                fdb     tu_slots+42             ; 6 bytes
                fcb     $07,$89,$8C,$0C,$64
                fcb     $0C
                fdb     td_slots+42             ; 6 bytes
                fcb     $8C,$87,$C3,$C0,$24
                fcb     $0D
                fdb     tu_slots+42             ; 6 bytes
                fcb     $00,$18,$00,$D8,$78
                fcb     $00
                fdb     td_slots+42             ; 6 bytes
                fcb     $07,$E0,$00,$00,$78
                fcb     $00
                fdb     tu_slots+49             ; 5 bytes
                fcb     $C0,$00,$03,$70
                fcb     $01
                fdb     td_slots+49             ; 5 bytes
                fcb     $9C,$00,$07,$80
                fcb     $00
                fdb     tu_slots+49             ; 5 bytes
                fcb     $1E,$3F,$9C,$C0
                fcb     $00
                fdb     td_slots+56             ; 4 bytes
                fcb     $47,$31,$C8
                fcb     $4F
                fdb     tu_slots+63             ; 3 bytes
                fcb     $C2,$F0
                fcb     $00
                fdb     td_slots+56             ; 4 bytes
                fcb     $FC,$3F,$00
poglet_t_data
                fcb     $F7
                fdb     td_slots+70             ; 2 bytes
                fcb     $00
                fcb     $00
                fdb     tu_slots+56             ; 4 bytes
                fcb     $2E,$60,$00
                fcb     $3F
                fdb     td_slots+56             ; 4 bytes
                fcb     $81,$05,$00
                fcb     $00
                fdb     tu_slots+49             ; 5 bytes
                fcb     $27,$A3,$C1,$C0
                fcb     $03
                fdb     td_slots+49             ; 5 bytes
                fcb     $80,$1B,$5F,$00
                fcb     $00
                fdb     tu_slots+49             ; 5 bytes
                fcb     $1C,$94,$7F,$FC
                fcb     $3A
                fdb     td_slots+49             ; 5 bytes
                fcb     $18,$EF,$DB,$00
                fcb     $00
                fdb     tu_slots+42             ; 6 bytes
                fcb     $23,$87,$04,$11,$80
                fcb     $00
                fdb     td_slots+42             ; 6 bytes
                fcb     $CF,$1F,$90,$31,$00
                fcb     $00
                fdb     tu_slots+42             ; 6 bytes
                fcb     $26,$02,$81,$C6,$C0
                fcb     $01
                fdb     td_slots+42             ; 6 bytes
                fcb     $B0,$BB,$B0,$1F,$00
                fcb     $00
                fdb     tu_slots+42             ; 6 bytes
                fcb     $2A,$00,$5E,$41,$20
                fcb     $01
                fdb     td_slots+42             ; 6 bytes
                fcb     $20,$9E,$80,$15,$00
                fcb     $00
                fdb     tu_slots+42             ; 6 bytes
                fcb     $2E,$03,$77,$41,$20
                fcb     $01
                fdb     td_slots+42             ; 6 bytes
                fcb     $21,$E0,$50,$19,$00
                fcb     $00
                fdb     tu_slots+42             ; 6 bytes
                fcb     $37,$F2,$7E,$31,$E0
                fcb     $00
                fdb     td_slots+49             ; 5 bytes
                fcb     $02,$08,$1E,$02
                fcb     $18
                fdb     tu_slots+56             ; 4 bytes
                fcb     $04,$02,$10
                fcb     $03
                fdb     td_slots+49             ; 5 bytes
                fcb     $F0,$07,$FF,$00
                fcb     $00
                fdb     tu_slots+63             ; 3 bytes
                fcb     $27,$A0
                fcb     $01
                fdb     td_slots+63             ; 3 bytes
                fcb     $05,$00
                fcb     $00
                fdb     tu_slots+63             ; 3 bytes
                fcb     $2E,$60
                fcb     $00
                fdb     td_slots+63             ; 3 bytes
                fcb     $F7,$00
hooter_t_data
                fcb     $C0
                fdb     td_slots+63             ; 3 bytes
                fcb     $FC,$0C
                fcb     $0C
                fdb     tu_slots+56             ; 4 bytes
                fcb     $08,$70,$E0
                fcb     $01
                fdb     td_slots+56             ; 4 bytes
                fcb     $06,$0F,$94
                fcb     $0A
                fdb     tu_slots+56             ; 4 bytes
                fcb     $C3,$8E,$60
                fcb     $00
                fdb     td_slots+56             ; 4 bytes
                fcb     $79,$C0,$6C
                fcb     $09
                fdb     tu_slots+56             ; 4 bytes
                fcb     $00,$0C,$C0
                fcb     $00
                fdb     td_slots+56             ; 4 bytes
                fcb     $B4,$78,$24
                fcb     $0B
                fdb     tu_slots+56             ; 4 bytes
                fcb     $0D,$6B,$40
                fcb     $00
                fdb     td_slots+56             ; 4 bytes
                fcb     $FE,$44,$2C
                fcb     $01
                fdb     tu_slots+56             ; 4 bytes
                fcb     $08,$84,$80
                fcb     $00
                fdb     td_slots+56             ; 4 bytes
                fcb     $FE,$44,$2C
                fcb     $0B
                fdb     tu_slots+56             ; 4 bytes
                fcb     $0D,$6B,$40
                fcb     $00
                fdb     td_slots+56             ; 4 bytes
                fcb     $B4,$78,$24
                fcb     $09
                fdb     tu_slots+56             ; 4 bytes
                fcb     $00,$0C,$C0
                fcb     $00
                fdb     td_slots+56             ; 4 bytes
                fcb     $79,$C0,$6C
                fcb     $0A
                fdb     tu_slots+56             ; 4 bytes
                fcb     $C3,$8E,$60
                fcb     $01
                fdb     td_slots+56             ; 4 bytes
                fcb     $07,$0F,$94
                fcb     $0C
                fdb     tu_slots+56             ; 4 bytes
                fcb     $08,$E0,$E0
                fcb     $00
                fdb     td_slots+56             ; 4 bytes
                fcb     $C0,$7C,$0C
gem_t_data
                fcb     $C0
                fdb     td_slots+77             ; 1 bytes
                fcb     $01
                fdb     tu_slots+70             ; 2 bytes
                fcb     $E0
                fcb     $03
                fdb     td_slots+70             ; 2 bytes
                fcb     $30
                fcb     $06
                fdb     tu_slots+70             ; 2 bytes
                fcb     $50
                fcb     $02
                fdb     td_slots+70             ; 2 bytes
                fcb     $8C
                fcb     $18
                fdb     tu_slots+70             ; 2 bytes
                fcb     $50
                fcb     $02
                fdb     td_slots+70             ; 2 bytes
                fcb     $8C
                fcb     $06
                fdb     tu_slots+70             ; 2 bytes
                fcb     $50
                fcb     $03
                fdb     td_slots+70             ; 2 bytes
                fcb     $30
                fcb     $01
                fdb     tu_slots+70             ; 2 bytes
                fcb     $E0
                fcb     $00
                fdb     td_slots+70             ; 2 bytes
                fcb     $C0
balloon_t_data
                fcb     $F8
                fdb     td_slots+77             ; 1 bytes
                fcb     $08
                fdb     tu_slots+70             ; 2 bytes
                fcb     $20
                fcb     $01
                fdb     td_slots+70             ; 2 bytes
                fcb     $04
                fcb     $10
                fdb     tu_slots+70             ; 2 bytes
                fcb     $10
                fcb     $02
                fdb     td_slots+70             ; 2 bytes
                fcb     $02
                fcb     $30
                fdb     tu_slots+70             ; 2 bytes
                fcb     $10
                fcb     $02
                fdb     td_slots+63             ; 3 bytes
                fcb     $03,$00
                fcb     $00
                fdb     tu_slots+63             ; 3 bytes
                fcb     $10,$10
                fcb     $02
                fdb     td_slots+70             ; 2 bytes
                fcb     $02
                fcb     $08
                fdb     tu_slots+70             ; 2 bytes
                fcb     $20
                fcb     $01
                fdb     td_slots+70             ; 2 bytes
                fcb     $04
                fcb     $07
                fdb     tu_slots+70             ; 2 bytes
                fcb     $C0
dagger_t_data
                fcb     $80
                fdb     td_slots+77             ; 1 bytes
                fcb     $00
                fdb     tu_slots+70             ; 2 bytes
                fcb     $30
                fcb     $05
                fdb     td_slots+70             ; 2 bytes
                fcb     $00
                fcb     $00
                fdb     tu_slots+63             ; 3 bytes
                fcb     $16,$20
                fcb     $01
                fdb     td_slots+70             ; 2 bytes
                fcb     $A4
                fcb     $08
                fdb     tu_slots+70             ; 2 bytes
                fcb     $C0
                fcb     $00
                fdb     td_slots+70             ; 2 bytes
                fcb     $68
                fcb     $03
                fdb     tu_slots+70             ; 2 bytes
                fcb     $C0
                fcb     $03
                fdb     td_slots+70             ; 2 bytes
                fcb     $D8
                fcb     $0C
                fdb     tu_slots+70             ; 2 bytes
                fcb     $60
                fcb     $00
                fdb     td_slots+70             ; 2 bytes
                fcb     $80
bulb_t_data
                fcb     $F8
                fdb     td_slots+77             ; 1 bytes
                fcb     $0C
                fdb     tu_slots+70             ; 2 bytes
                fcb     $60
                fcb     $47
                fdb     td_slots+70             ; 2 bytes
                fcb     $06
                fcb     $10
                fdb     tu_slots+63             ; 3 bytes
                fcb     $0F,$C0
                fcb     $00
                fdb     td_slots+63             ; 3 bytes
                fcb     $F0,$02
                fcb     $10
                fdb     tu_slots+63             ; 3 bytes
                fcb     $03,$C0
                fcb     $00
                fdb     td_slots+63             ; 3 bytes
                fcb     $FC,$02
                fcb     $18
                fdb     tu_slots+63             ; 3 bytes
                fcb     $38,$80
                fcb     $00
                fdb     td_slots+63             ; 3 bytes
                fcb     $01,$8C
                fcb     $07
                fdb     tu_slots+70             ; 2 bytes
                fcb     $C0
ladder_t_data
                fcb     $E1
                fdb     td_slots+21             ; 9 bytes
                fcb     $C3,$87,$0E,$1C,$38,$70,$E1,$C0
                fcb     $00
                fdb     tu_slots+14             ; 10 bytes
                fcb     $A1,$42,$85,$0A,$14,$28,$50,$A1,$40
                fcb     $00
                fdb     td_slots+14             ; 10 bytes
                fcb     $A1,$42,$85,$0A,$14,$28,$50,$A1,$40
                fcb     $00
                fdb     tu_slots+14             ; 10 bytes
                fcb     $A1,$42,$85,$0A,$14,$28,$50,$A1,$40
                fcb     $03
                fdb     td_slots+14             ; 10 bytes
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0
                fcb     $00
                fdb     tu_slots+14             ; 10 bytes
                fcb     $40,$81,$02,$04,$08,$10,$20,$40,$80
                fcb     $00
                fdb     td_slots+14             ; 10 bytes
                fcb     $40,$81,$02,$04,$08,$10,$20,$40,$80
                fcb     $03
                fdb     tu_slots+14             ; 10 bytes
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0
                fcb     $00
                fdb     td_slots+14             ; 10 bytes
                fcb     $A1,$42,$85,$0A,$14,$28,$50,$A1,$40
                fcb     $00
                fdb     tu_slots+14             ; 10 bytes
                fcb     $A1,$42,$85,$0A,$14,$28,$50,$A1,$40
                fcb     $00
                fdb     td_slots+14             ; 10 bytes
                fcb     $A1,$42,$85,$0A,$14,$28,$50,$A1,$40
                fcb     $00
                fdb     tu_slots+14             ; 10 bytes
                fcb     $E1,$C3,$87,$0E,$1C,$38,$70,$E1,$C0
chain_t_data
                fcb     $E1
                fdb     td_slots+14             ; 10 bytes
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0
                fcb     $03
                fdb     tu_slots+7             ; 11 bytes
                fcb     $00,$CC,$03,$30,$0C,$C0,$33,$00,$A3,$40
                fcb     $00
                fdb     td_slots+7             ; 11 bytes
                fcb     $9E,$9F,$9E,$7E,$79,$F9,$E7,$E7,$9F,$90
                fcb     $02
                fdb     tu_slots+7             ; 11 bytes
                fcb     $C5,$4A,$95,$2A,$54,$A9,$52,$A5,$72,$40
                fcb     $00
                fdb     td_slots+7             ; 11 bytes
                fcb     $91,$C9,$52,$A5,$4A,$95,$2A,$54,$A8,$D0
                fcb     $02
                fdb     tu_slots+7             ; 11 bytes
                fcb     $7C,$FC,$F3,$F3,$CF,$CF,$3F,$3E,$0E,$40
                fcb     $00
                fdb     td_slots+7             ; 11 bytes
                fcb     $B6,$20,$80,$42,$01,$08,$04,$20,$10,$30
                fcb     $01
                fdb     tu_slots+7             ; 11 bytes
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F1,$C0
