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
                ldd     #$78F6
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
                ldd     #$7F49
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
                ldd     #$7F6A
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
                ldd     #$3A9F
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
                ldd     #$27DA
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
                ldd     #$3113
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
                ldd     #$0393
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
                ldd     #$00C0
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
                ldd     #$FBE5
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
                ldd     #$8181
                jsr     Moveto_d
                ldx     #move_22
                jsr     vlist_d
dc_22_start
                ldx     #scrubbly_t_data+55
                lda     #24
                sta     <$06
                ldu     #$0120
                jsr     trim_up
dc_22_end
; poglet at (94, 60): trimmed columns 0-8 of 23
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$9F77
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
                fcb     1,55,-91,$00
                fcb     0,0
move_4
                fcb     2,103,54,$00
                fcb     0,0
move_5
                fcb     1,127,98,$00
                fcb     0,0
move_6
                fcb     2,103,11,$00
                fcb     0,0
move_7
                fcb     4,112,18,$00
                fcb     0,0
move_8
                fcb     1,73,-94,$00
                fcb     0,0
move_9
                fcb     1,81,-93,$00
                fcb     0,0
move_10
                fcb     0,0
move_11
                fcb     1,92,-59,$00
                fcb     0,0
move_12
                fcb     1,89,-25,$00
                fcb     0,0
move_13
                fcb     1,103,69,$00
                fcb     0,0
move_14
                fcb     1,66,-94,$00
                fcb     0,0
move_15
                fcb     0,0
move_16
                fcb     1,66,-109,$00
                fcb     0,0
move_17
                fcb     1,80,-120,$00
                fcb     0,0
move_18
                fcb     1,66,-4,$00
                fcb     0,0
move_19
                fcb     1,-86,-14,$00
                fcb     0,0
move_20
                fcb     1,66,-25,$00
                fcb     0,0
move_21
                fcb     1,-58,91,$00
                fcb     0,0
move_22
                fcb     3,-42,-96,$00
                fcb     0,0
move_23
                fcb     1,-93,22,$00
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
                fdb     td_slots+77             ; 1 bytes, lead-in 0
                fcb     $3A
                fdb     tu_slots+70             ; 2 bytes, lead-in 0
                fcb     $60
                fcb     $3E
                fdb     td_slots+69             ; 2 bytes, lead-in 1
                fcb     $5E
                fcb     $1E
                fdb     tu_slots+63             ; 3 bytes, lead-in 0
                fcb     $81,$E0
                fcb     $03
                fdb     td_slots+63             ; 3 bytes, lead-in 0
                fcb     $01,$5E
                fcb     $1F
                fdb     tu_slots+63             ; 3 bytes, lead-in 0
                fcb     $F8,$18
                fcb     $04
                fdb     td_slots+56             ; 4 bytes, lead-in 0
                fcb     $1C,$7C,$0E
                fcb     $2E
                fdb     tu_slots+55             ; 4 bytes, lead-in 1
                fcb     $1E,$17,$1A
                fcb     $78
                fdb     td_slots+55             ; 4 bytes, lead-in 1
                fcb     $44,$1E,$E2
                fcb     $41
                fdb     tu_slots+54             ; 4 bytes, lead-in 2
                fcb     $D0,$22,$1E
                fcb     $F0
                fdb     td_slots+54             ; 4 bytes, lead-in 2
                fcb     $C4,$09,$0A
                fcb     $17
                fdb     tu_slots+49             ; 5 bytes, lead-in 0
                fcb     $44,$0C,$47,$E0
                fcb     $01
                fdb     td_slots+49             ; 5 bytes, lead-in 0
                fcb     $F7,$F8,$08,$7E
                fcb     $16
                fdb     tu_slots+49             ; 5 bytes, lead-in 0
                fcb     $04,$01,$E7,$F0
                fcb     $03
                fdb     td_slots+49             ; 5 bytes, lead-in 0
                fcb     $EC,$00,$0C,$02
                fcb     $10
                fdb     tu_slots+49             ; 5 bytes, lead-in 0
                fcb     $3E,$00,$7B,$F8
                fcb     $07
                fdb     td_slots+49             ; 5 bytes, lead-in 0
                fcb     $18,$E0,$11,$FA
                fcb     $14
                fdb     tu_slots+49             ; 5 bytes, lead-in 0
                fcb     $03,$07,$0C,$18
                fcb     $06
                fdb     td_slots+49             ; 5 bytes, lead-in 0
                fcb     $17,$0C,$60,$12
                fcb     $1E
                fdb     tu_slots+49             ; 5 bytes, lead-in 0
                fcb     $00,$FF,$EA,$D8
                fcb     $8E
                fdb     td_slots+72             ; 1 bytes, lead-in 6
                fcb     $8E
                fcb     $36
                fdb     tu_slots+75             ; 1 bytes, lead-in 2
                fcb     $0A
                fdb     td_slots+77             ; 1 bytes, lead-in 0
                fcb     $14
                fdb     tu_slots+77             ; 1 bytes, lead-in 0
                fcb     $0A
                fdb     td_slots+77             ; 1 bytes, lead-in 0
                fcb     $1C
                fdb     tu_slots+77             ; 1 bytes, lead-in 0
trogg_climb_t_data
                fcb     $0E
                fdb     td_slots+77             ; 1 bytes, lead-in 0
                fcb     $6E
                fdb     tu_slots+76             ; 1 bytes, lead-in 1
                fcb     $78
                fdb     td_slots+63             ; 3 bytes, lead-in 0
                fcb     $FF,$C0
                fcb     $7C
                fdb     tu_slots+60             ; 3 bytes, lead-in 3
                fcb     $2E,$26
                fcb     $13
                fdb     td_slots+56             ; 4 bytes, lead-in 0
                fcb     $01,$04,$FE
                fcb     $34
                fdb     tu_slots+56             ; 4 bytes, lead-in 0
                fcb     $88,$30,$3E
                fcb     $FE
                fdb     td_slots+55             ; 4 bytes, lead-in 1
                fcb     $04,$08,$22
                fcb     $17
                fdb     tu_slots+49             ; 5 bytes, lead-in 0
                fcb     $C4,$08,$3F,$E0
                fcb     $07
                fdb     td_slots+47             ; 5 bytes, lead-in 2
                fcb     $FE,$30,$3E,$38
                fcb     $01
                fdb     tu_slots+51             ; 4 bytes, lead-in 6
                fcb     $01,$80,$67,$FE
                fcb     $1F
                fdb     td_slots+49             ; 5 bytes, lead-in 0
                fcb     $FF,$00,$3F,$F8
                fcb     $04
                fdb     tu_slots+49             ; 5 bytes, lead-in 0
                fcb     $91,$00,$0F,$FE
                fcb     $1F
                fdb     td_slots+49             ; 5 bytes, lead-in 0
                fcb     $F0,$00,$20,$28
                fcb     $05
                fdb     tu_slots+49             ; 5 bytes, lead-in 0
                fcb     $01,$01,$F1,$FC
                fcb     $FF
                fdb     td_slots+51             ; 4 bytes, lead-in 6
                fcb     $FF,$8C,$18,$FE
                fcb     $03
                fdb     tu_slots+53             ; 4 bytes, lead-in 3
                fcb     $F8,$C8,$F8
                fcb     $04
                fdb     td_slots+63             ; 3 bytes, lead-in 0
                fcb     $8F,$FC
                fcb     $01
                fdb     tu_slots+65             ; 2 bytes, lead-in 6
                fcb     $01,$96
                fcb     $66
                fdb     td_slots+74             ; 1 bytes, lead-in 3
                fcb     $1E
                fdb     tu_slots+76             ; 1 bytes, lead-in 1
scrubbly_t_data
                fcb     $01
                fdb     td_slots+63             ; 3 bytes, lead-in 0
                fcb     $F8,$7E
                fcb     $9F
                fdb     tu_slots+61             ; 3 bytes, lead-in 2
                fcb     $85,$E0
                fcb     $23
                fdb     td_slots+63             ; 3 bytes, lead-in 0
                fcb     $98,$E4
                fcb     $F1
                fdb     tu_slots+61             ; 3 bytes, lead-in 2
                fcb     $FC,$E6
                fcb     $33
                fdb     td_slots+56             ; 4 bytes, lead-in 0
                fcb     $80,$00,$F0
                fcb     $30
                fdb     tu_slots+53             ; 4 bytes, lead-in 3
                fcb     $00,$00,$DC
                fcb     $1F
                fdb     td_slots+49             ; 5 bytes, lead-in 0
                fcb     $80,$00,$01,$E0
                fcb     $06
                fdb     tu_slots+41             ; 6 bytes, lead-in 1
                fcb     $C0,$0C,$00,$6C,$70
                fcb     $06
                fdb     td_slots+42             ; 6 bytes, lead-in 0
                fcb     $99,$0F,$87,$80,$48
                fcb     $04
                fdb     tu_slots+42             ; 6 bytes, lead-in 0
                fcb     $83,$C4,$C6,$06,$2C
                fcb     $09
                fdb     td_slots+42             ; 6 bytes, lead-in 0
                fcb     $30,$30,$48,$1C,$68
                fcb     $05
                fdb     tu_slots+42             ; 6 bytes, lead-in 0
                fcb     $83,$C4,$F1,$01,$14
                fcb     $0B
                fdb     td_slots+42             ; 6 bytes, lead-in 0
                fcb     $60,$27,$C7,$80,$38
                fcb     $03
                fdb     tu_slots+42             ; 6 bytes, lead-in 0
                fcb     $00,$0C,$F9,$00,$E6
                fcb     $1D
                fdb     td_slots+42             ; 6 bytes, lead-in 0
                fcb     $C0,$33,$84,$00,$20
                fcb     $01
                fdb     tu_slots+42             ; 6 bytes, lead-in 0
                fcb     $00,$04,$3E,$00,$0A
                fcb     $10
                fdb     td_slots+42             ; 6 bytes, lead-in 0
                fcb     $00,$00,$04,$00,$20
                fcb     $01
                fdb     tu_slots+42             ; 6 bytes, lead-in 0
                fcb     $00,$04,$3E,$00,$0E
                fcb     $0C
                fdb     td_slots+42             ; 6 bytes, lead-in 0
                fcb     $C0,$33,$84,$00,$20
                fcb     $03
                fdb     tu_slots+42             ; 6 bytes, lead-in 0
                fcb     $00,$0C,$F9,$00,$E6
                fcb     $1B
                fdb     td_slots+42             ; 6 bytes, lead-in 0
                fcb     $60,$27,$C7,$80,$38
                fcb     $05
                fdb     tu_slots+42             ; 6 bytes, lead-in 0
                fcb     $83,$C4,$F1,$01,$12
                fcb     $16
                fdb     td_slots+42             ; 6 bytes, lead-in 0
                fcb     $30,$30,$48,$1C,$68
                fcb     $04
                fdb     tu_slots+42             ; 6 bytes, lead-in 0
                fcb     $83,$C4,$C6,$06,$32
                fcb     $19
                fdb     td_slots+42             ; 6 bytes, lead-in 0
                fcb     $19,$0F,$87,$80,$48
                fcb     $0D
                fdb     tu_slots+41             ; 6 bytes, lead-in 1
                fcb     $00,$18,$00,$D8,$78
                fcb     $01
                fdb     td_slots+44             ; 5 bytes, lead-in 6
                fcb     $01,$F8,$00,$00,$1E
                fcb     $18
                fdb     tu_slots+53             ; 4 bytes, lead-in 3
                fcb     $00,$00,$6E
                fcb     $0C
                fdb     td_slots+56             ; 4 bytes, lead-in 0
                fcb     $E0,$00,$3C
                fcb     $F1
                fdb     tu_slots+58             ; 3 bytes, lead-in 6
                fcb     $F1,$FC,$E6
                fcb     $47
                fdb     td_slots+60             ; 3 bytes, lead-in 3
                fcb     $31,$C8
                fcb     $4F
                fdb     tu_slots+63             ; 3 bytes, lead-in 0
                fcb     $C2,$F0
                fcb     $01
                fdb     td_slots+62             ; 3 bytes, lead-in 1
                fcb     $F8,$7E
poglet_t_data
                fcb     $01
                fdb     td_slots+70             ; 2 bytes, lead-in 0
                fcb     $EE
                fcb     $17
                fdb     tu_slots+63             ; 3 bytes, lead-in 0
                fcb     $30,$00
                fcb     $7F
                fdb     td_slots+63             ; 3 bytes, lead-in 0
                fcb     $02,$0A
                fcb     $13
                fdb     tu_slots+56             ; 4 bytes, lead-in 0
                fcb     $D1,$E0,$E0
                fcb     $07
                fdb     td_slots+56             ; 4 bytes, lead-in 0
                fcb     $00,$36,$BE
                fcb     $0E
                fdb     tu_slots+56             ; 4 bytes, lead-in 0
                fcb     $4A,$3F,$FE
                fcb     $74
                fdb     td_slots+56             ; 4 bytes, lead-in 0
                fcb     $31,$DF,$B6
                fcb     $8E
                fdb     tu_slots+53             ; 4 bytes, lead-in 3
                fcb     $1C,$10,$46
                fcb     $33
                fdb     td_slots+49             ; 5 bytes, lead-in 0
                fcb     $C7,$E4,$0C,$40
                fcb     $02
                fdb     tu_slots+47             ; 5 bytes, lead-in 2
                fcb     $60,$28,$1C,$6C
                fcb     $1B
                fdb     td_slots+49             ; 5 bytes, lead-in 0
                fcb     $0B,$BB,$01,$F0
                fcb     $02
                fdb     tu_slots+49             ; 5 bytes, lead-in 0
                fcb     $A0,$05,$E4,$12
                fcb     $12
                fdb     td_slots+49             ; 5 bytes, lead-in 0
                fcb     $09,$E8,$01,$50
                fcb     $02
                fdb     tu_slots+49             ; 5 bytes, lead-in 0
                fcb     $E0,$37,$74,$12
                fcb     $12
                fdb     td_slots+49             ; 5 bytes, lead-in 0
                fcb     $1E,$05,$01,$90
                fcb     $03
                fdb     tu_slots+49             ; 5 bytes, lead-in 0
                fcb     $7F,$27,$E3,$1E
                fcb     $08
                fdb     td_slots+51             ; 4 bytes, lead-in 6
                fcb     $08,$20,$78,$08
                fcb     $06
                fdb     tu_slots+56             ; 4 bytes, lead-in 0
                fcb     $01,$00,$84
                fcb     $0F
                fdb     td_slots+56             ; 4 bytes, lead-in 0
                fcb     $C0,$1F,$FC
                fcb     $09
                fdb     tu_slots+70             ; 2 bytes, lead-in 0
                fcb     $E8
                fcb     $04
                fdb     td_slots+70             ; 2 bytes, lead-in 0
                fcb     $14
                fcb     $0B
                fdb     tu_slots+70             ; 2 bytes, lead-in 0
                fcb     $98
                fcb     $03
                fdb     td_slots+70             ; 2 bytes, lead-in 0
                fcb     $DC
hooter_t_data
                fcb     $60
                fdb     td_slots+63             ; 3 bytes, lead-in 0
                fcb     $7E,$06
                fcb     $C0
                fdb     tu_slots+60             ; 3 bytes, lead-in 3
                fcb     $87,$0E
                fcb     $83
                fdb     td_slots+60             ; 3 bytes, lead-in 3
                fcb     $07,$CA
                fcb     $AC
                fdb     tu_slots+60             ; 3 bytes, lead-in 3
                fcb     $38,$E6
                fcb     $3C
                fdb     td_slots+60             ; 3 bytes, lead-in 3
                fcb     $E0,$36
                fcb     $48
                fdb     tu_slots+61             ; 3 bytes, lead-in 2
                fcb     $00,$66
                fcb     $5A
                fdb     td_slots+61             ; 3 bytes, lead-in 2
                fcb     $3C,$12
                fcb     $58
                fdb     tu_slots+61             ; 3 bytes, lead-in 2
                fcb     $6B,$5A
                fcb     $7F
                fdb     td_slots+61             ; 3 bytes, lead-in 2
                fcb     $22,$16
                fcb     $04
                fdb     tu_slots+62             ; 3 bytes, lead-in 1
                fcb     $22,$12
                fcb     $7F
                fdb     td_slots+62             ; 3 bytes, lead-in 1
                fcb     $22,$16
                fcb     $58
                fdb     tu_slots+61             ; 3 bytes, lead-in 2
                fcb     $6B,$5A
                fcb     $5A
                fdb     td_slots+61             ; 3 bytes, lead-in 2
                fcb     $3C,$12
                fcb     $48
                fdb     tu_slots+61             ; 3 bytes, lead-in 2
                fcb     $00,$66
                fcb     $3C
                fdb     td_slots+61             ; 3 bytes, lead-in 2
                fcb     $E0,$36
                fcb     $AC
                fdb     tu_slots+60             ; 3 bytes, lead-in 3
                fcb     $38,$E6
                fcb     $83
                fdb     td_slots+60             ; 3 bytes, lead-in 3
                fcb     $87,$CA
                fcb     $C0
                fdb     tu_slots+60             ; 3 bytes, lead-in 3
                fcb     $8E,$0E
                fcb     $60
                fdb     td_slots+60             ; 3 bytes, lead-in 3
                fcb     $3E,$06
gem_t_data
                fcb     $0C
                fdb     td_slots+77             ; 1 bytes, lead-in 0
                fcb     $1E
                fdb     tu_slots+77             ; 1 bytes, lead-in 0
                fcb     $66
                fdb     td_slots+76             ; 1 bytes, lead-in 1
                fcb     $CA
                fdb     tu_slots+75             ; 1 bytes, lead-in 2
                fcb     $14
                fdb     td_slots+70             ; 2 bytes, lead-in 0
                fcb     $60
                fcb     $03
                fdb     tu_slots+70             ; 2 bytes, lead-in 0
                fcb     $0A
                fcb     $14
                fdb     td_slots+70             ; 2 bytes, lead-in 0
                fcb     $60
                fcb     $00
                fdb     tu_slots+70             ; 2 bytes, lead-in 0
                fcb     $CA
                fcb     $66
                fdb     td_slots+75             ; 1 bytes, lead-in 2
                fcb     $1E
                fdb     tu_slots+76             ; 1 bytes, lead-in 1
                fcb     $0C
                fdb     td_slots+77             ; 1 bytes, lead-in 0
balloon_t_data
                fcb     $3E
                fdb     td_slots+77             ; 1 bytes, lead-in 0
                fcb     $82
                fdb     tu_slots+75             ; 1 bytes, lead-in 2
                fcb     $82
                fdb     td_slots+74             ; 1 bytes, lead-in 3
                fcb     $20
                fdb     tu_slots+70             ; 2 bytes, lead-in 0
                fcb     $20
                fcb     $08
                fdb     td_slots+67             ; 2 bytes, lead-in 3
                fcb     $08
                fcb     $0C
                fdb     tu_slots+70             ; 2 bytes, lead-in 0
                fcb     $04
                fcb     $08
                fdb     td_slots+70             ; 2 bytes, lead-in 0
                fcb     $0C
                fcb     $04
                fdb     tu_slots+70             ; 2 bytes, lead-in 0
                fcb     $04
                fcb     $08
                fdb     td_slots+70             ; 2 bytes, lead-in 0
                fcb     $08
                fcb     $82
                fdb     tu_slots+72             ; 1 bytes, lead-in 6
                fcb     $82
                fcb     $82
                fdb     td_slots+74             ; 1 bytes, lead-in 3
                fcb     $3E
                fdb     tu_slots+75             ; 1 bytes, lead-in 2
dagger_t_data
                fcb     $04
                fdb     td_slots+77             ; 1 bytes, lead-in 0
                fcb     $06
                fdb     tu_slots+77             ; 1 bytes, lead-in 0
                fcb     $50
                fdb     td_slots+76             ; 1 bytes, lead-in 1
                fcb     $01
                fdb     tu_slots+70             ; 2 bytes, lead-in 0
                fcb     $62
                fcb     $D2
                fdb     td_slots+74             ; 1 bytes, lead-in 3
                fcb     $46
                fdb     tu_slots+75             ; 1 bytes, lead-in 2
                fcb     $1A
                fdb     td_slots+76             ; 1 bytes, lead-in 1
                fcb     $1E
                fdb     tu_slots+76             ; 1 bytes, lead-in 1
                fcb     $F6
                fdb     td_slots+76             ; 1 bytes, lead-in 1
                fcb     $C6
                fdb     tu_slots+75             ; 1 bytes, lead-in 2
                fcb     $08
                fdb     td_slots+77             ; 1 bytes, lead-in 0
bulb_t_data
                fcb     $F8
                fdb     td_slots+77             ; 1 bytes, lead-in 0
                fcb     $0C
                fdb     tu_slots+70             ; 2 bytes, lead-in 0
                fcb     $60
                fcb     $47
                fdb     td_slots+70             ; 2 bytes, lead-in 0
                fcb     $06
                fcb     $80
                fdb     tu_slots+67             ; 2 bytes, lead-in 3
                fcb     $7E
                fcb     $F0
                fdb     td_slots+67             ; 2 bytes, lead-in 3
                fcb     $02
                fcb     $80
                fdb     tu_slots+67             ; 2 bytes, lead-in 3
                fcb     $1E
                fcb     $FC
                fdb     td_slots+67             ; 2 bytes, lead-in 3
                fcb     $02
                fcb     $60
                fdb     tu_slots+68             ; 2 bytes, lead-in 2
                fcb     $E2
                fcb     $00
                fdb     td_slots+69             ; 2 bytes, lead-in 1
                fcb     $C6
                fcb     $3E
                fdb     tu_slots+75             ; 1 bytes, lead-in 2
ladder_t_data
                fcb     $1C
                fdb     td_slots+21             ; 9 bytes, lead-in 0
                fcb     $38,$70,$E1,$C3,$87,$0E,$1C,$38
                fcb     $05
                fdb     tu_slots+21             ; 9 bytes, lead-in 0
                fcb     $0A,$14,$28,$50,$A1,$42,$85,$0A
                fcb     $14
                fdb     td_slots+21             ; 9 bytes, lead-in 0
                fcb     $28,$50,$A1,$42,$85,$0A,$14,$28
                fcb     $05
                fdb     tu_slots+21             ; 9 bytes, lead-in 0
                fcb     $0A,$14,$28,$50,$A1,$42,$85,$0A
                fcb     $7F
                fdb     td_slots+21             ; 9 bytes, lead-in 0
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
                fcb     $08
                fdb     tu_slots+19             ; 9 bytes, lead-in 2
                fcb     $10,$20,$40,$81,$02,$04,$08,$10
                fcb     $02
                fdb     td_slots+21             ; 9 bytes, lead-in 0
                fcb     $04,$08,$10,$20,$40,$81,$02,$04
                fcb     $7F
                fdb     tu_slots+21             ; 9 bytes, lead-in 0
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
                fcb     $05
                fdb     td_slots+21             ; 9 bytes, lead-in 0
                fcb     $0A,$14,$28,$50,$A1,$42,$85,$0A
                fcb     $14
                fdb     tu_slots+21             ; 9 bytes, lead-in 0
                fcb     $28,$50,$A1,$42,$85,$0A,$14,$28
                fcb     $05
                fdb     td_slots+21             ; 9 bytes, lead-in 0
                fcb     $0A,$14,$28,$50,$A1,$42,$85,$0A
                fcb     $1C
                fdb     tu_slots+21             ; 9 bytes, lead-in 0
                fcb     $38,$70,$E1,$C3,$87,$0E,$1C,$38
chain_t_data
                fcb     $1C
                fdb     td_slots+14             ; 10 bytes, lead-in 0
                fcb     $3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FC
                fcb     $18
                fdb     tu_slots+14             ; 10 bytes, lead-in 0
                fcb     $06,$60,$19,$80,$66,$01,$98,$05,$1A
                fcb     $13
                fdb     td_slots+14             ; 10 bytes, lead-in 0
                fcb     $D3,$F3,$CF,$CF,$3F,$3C,$FC,$F3,$F2
                fcb     $16
                fdb     tu_slots+14             ; 10 bytes, lead-in 0
                fcb     $2A,$54,$A9,$52,$A5,$4A,$95,$2B,$92
                fcb     $12
                fdb     td_slots+14             ; 10 bytes, lead-in 0
                fcb     $39,$2A,$54,$A9,$52,$A5,$4A,$95,$1A
                fcb     $13
                fdb     tu_slots+14             ; 10 bytes, lead-in 0
                fcb     $E7,$E7,$9F,$9E,$7E,$79,$F9,$F0,$72
                fcb     $16
                fdb     td_slots+14             ; 10 bytes, lead-in 0
                fcb     $C4,$10,$08,$40,$21,$00,$84,$02,$06
                fcb     $0F
                fdb     tu_slots+14             ; 10 bytes, lead-in 0
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$8E
