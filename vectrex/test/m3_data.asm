; made by vectrex/tools/m3_gen.py: the sprites, the levels' strips and lists

spr_chain1
                fcb     8,5
                fdb     chain1_d,col5_down,col5_up,col5_down_l,col5_up_l
                fcb     40
                fdb     80
chain1_d
                fcb     $38,$7F,$FF,$FF,$E0
                fcb     $0C,$03,$30,$0A,$34
                fcb     $27,$A7,$E7,$9F,$90
                fcb     $0B,$15,$2A,$57,$24
                fcb     $24,$72,$54,$A8,$D0
                fcb     $09,$F3,$F3,$E0,$E4
                fcb     $2D,$88,$20,$10,$30
                fcb     $07,$FF,$FF,$FF,$1C
spr_chain2
                fcb     8,7
                fdb     chain2_d,col7_down,col7_up,col7_down_l,col7_up_l
                fcb     56
                fdb     112
chain2_d
                fcb     $38,$7F,$FF,$FF,$FF,$FF,$80
                fcb     $03,$00,$CC,$03,$30,$0A,$34
                fcb     $27,$A7,$E7,$9F,$9E,$7E,$40
                fcb     $02,$C5,$4A,$95,$2A,$57,$24
                fcb     $24,$72,$54,$A9,$52,$A3,$40
                fcb     $02,$7C,$FC,$F3,$F3,$E0,$E4
                fcb     $2D,$88,$20,$10,$80,$40,$C0
                fcb     $01,$FF,$FF,$FF,$FF,$FF,$1C
spr_chain3
                fcb     8,9
                fdb     chain3_d,col9_down,col9_up,col9_down_l,col9_up_l
                fcb     72
                fdb     144
chain3_d
                fcb     $38,$7F,$FF,$FF,$FF,$FF,$FF,$FE,$00
                fcb     $00,$C0,$33,$00,$CC,$03,$30,$0A,$34
                fcb     $27,$A7,$E7,$9F,$9E,$7E,$79,$F9,$00
                fcb     $00,$B1,$52,$A5,$4A,$95,$2A,$57,$24
                fcb     $24,$72,$54,$A9,$52,$A5,$4A,$8D,$00
                fcb     $00,$9F,$3F,$3C,$FC,$F3,$F3,$E0,$E4
                fcb     $2D,$88,$20,$10,$80,$42,$01,$03,$00
                fcb     $00,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$1C
spr_chain4
                fcb     8,10
                fdb     chain4_d,col10_down,col10_up,col10_down_l,col10_up_l
                fcb     80
                fdb     160
chain4_d
                fcb     $38,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8
                fcb     $30,$0C,$C0,$33,$00,$CC,$03,$30,$0A,$34
                fcb     $27,$A7,$E7,$9F,$9E,$7E,$79,$F9,$E7,$E4
                fcb     $2C,$54,$A9,$52,$A5,$4A,$95,$2A,$57,$24
                fcb     $24,$72,$54,$A9,$52,$A5,$4A,$95,$2A,$34
                fcb     $27,$CF,$CF,$3F,$3C,$FC,$F3,$F3,$E0,$E4
                fcb     $2D,$88,$20,$10,$80,$42,$01,$08,$04,$0C
                fcb     $1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1C
spr_gem
                fcb     11,2
                fdb     gem_d,col2_down,col2_up,col2_down_l,col2_up_l
                fcb     16
                fdb     32
gem_d
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
spr_hooter
                fcb     19,4
                fdb     hooter_d,col4_down,col4_up,col4_down_l,col4_up_l
                fcb     32
                fdb     64
hooter_d
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
rsp_key
                fcb     22,3,10
                fdb     18,key_d,rows3_10
key_d
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
spr_ladder1
                fcb     12,3
                fdb     ladder1_d,col3_down,col3_up,col3_down_l,col3_up_l
                fcb     24
                fdb     48
ladder1_d
                fcb     $0E,$1C,$00
                fcb     $00,$28,$50
                fcb     $0A,$14,$00
                fcb     $00,$28,$50
                fcb     $3F,$FF,$00
                fcb     $00,$10,$20
                fcb     $04,$08,$00
                fcb     $00,$FF,$FC
                fcb     $0A,$14,$00
                fcb     $00,$28,$50
                fcb     $0A,$14,$00
                fcb     $00,$38,$70
spr_ladder2
                fcb     12,4
                fdb     ladder2_d,col4_down,col4_up,col4_down_l,col4_up_l
                fcb     32
                fdb     64
ladder2_d
                fcb     $0E,$1C,$38,$70
                fcb     $0A,$14,$28,$50
                fcb     $0A,$14,$28,$50
                fcb     $0A,$14,$28,$50
                fcb     $3F,$FF,$FF,$FC
                fcb     $04,$08,$10,$20
                fcb     $04,$08,$10,$20
                fcb     $3F,$FF,$FF,$FC
                fcb     $0A,$14,$28,$50
                fcb     $0A,$14,$28,$50
                fcb     $0A,$14,$28,$50
                fcb     $0E,$1C,$38,$70
spr_ladder3
                fcb     12,6
                fdb     ladder3_d,col6_down,col6_up,col6_down_l,col6_up_l
                fcb     48
                fdb     96
ladder3_d
                fcb     $0E,$1C,$38,$70,$E1,$C0
                fcb     $02,$85,$0A,$14,$28,$50
                fcb     $0A,$14,$28,$50,$A1,$40
                fcb     $02,$85,$0A,$14,$28,$50
                fcb     $3F,$FF,$FF,$FF,$FF,$F0
                fcb     $01,$02,$04,$08,$10,$20
                fcb     $04,$08,$10,$20,$40,$80
                fcb     $0F,$FF,$FF,$FF,$FF,$FC
                fcb     $0A,$14,$28,$50,$A1,$40
                fcb     $02,$85,$0A,$14,$28,$50
                fcb     $0A,$14,$28,$50,$A1,$40
                fcb     $03,$87,$0E,$1C,$38,$70
spr_ladder4
                fcb     12,8
                fdb     ladder4_d,col8_down,col8_up,col8_down_l,col8_up_l
                fcb     64
                fdb     128
ladder4_d
                fcb     $0E,$1C,$38,$70,$E1,$C3,$87,$00
                fcb     $00,$A1,$42,$85,$0A,$14,$28,$50
                fcb     $0A,$14,$28,$50,$A1,$42,$85,$00
                fcb     $00,$A1,$42,$85,$0A,$14,$28,$50
                fcb     $3F,$FF,$FF,$FF,$FF,$FF,$FF,$C0
                fcb     $00,$40,$81,$02,$04,$08,$10,$20
                fcb     $04,$08,$10,$20,$40,$81,$02,$00
                fcb     $03,$FF,$FF,$FF,$FF,$FF,$FF,$FC
                fcb     $0A,$14,$28,$50,$A1,$42,$85,$00
                fcb     $00,$A1,$42,$85,$0A,$14,$28,$50
                fcb     $0A,$14,$28,$50,$A1,$42,$85,$00
                fcb     $00,$E1,$C3,$87,$0E,$1C,$38,$70
spr_poglet
                fcb     23,5
                fdb     poglet_d,col5_down,col5_up,col5_down_l,col5_up_l
                fcb     40
                fdb     80
poglet_d
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
spr_qiana1
                fcb     5,4
                fdb     qiana1_d,col4_down,col4_up,col4_down_l,col4_up_l
                fcb     32
                fdb     64
qiana1_d
                fcb     $3F,$9F,$83,$F0
                fcb     $00,$3E,$06,$00
                fcb     $00,$00,$00,$00
                fcb     $0F,$80,$F0,$FC
                fcb     $00,$F0,$FE,$00
spr_qiana2
                fcb     5,7
                fdb     qiana2_d,col7_down,col7_up,col7_down_l,col7_up_l
                fcb     56
                fdb     112
qiana2_d
                fcb     $3F,$9F,$83,$FF,$E7,$E0,$FC
                fcb     $00,$F8,$18,$00,$3E,$06,$00
                fcb     $00,$00,$00,$00,$00,$00,$00
                fcb     $3E,$03,$C3,$FF,$80,$F0,$FC
                fcb     $00,$F0,$FE,$00,$3C,$3F,$80
spr_qiana3
                fcb     5,11
                fdb     qiana3_d,col11_down,col11_up,col11_down_l,col11_up_l
                fcb     88
                fdb     176
qiana3_d
                fcb     $3F,$9F,$83,$FF,$E7,$E0,$FF,$F9,$F8,$3F,$00
                fcb     $00,$03,$E0,$60,$00,$F8,$18,$00,$3E,$06,$00
                fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                fcb     $00,$F8,$0F,$0F,$FE,$03,$C3,$FF,$80,$F0,$FC
                fcb     $00,$F0,$FE,$00,$3C,$3F,$80,$0F,$0F,$E0,$00
spr_scrubbly
                fcb     33,6
                fdb     scrubbly_d,col6_down,col6_up,col6_down_l,col6_up_l
                fcb     48
                fdb     96
scrubbly_d
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
spr_trogg_sr
                fcb     26,5
                fdb     trogg_sr_d,col5_down,col5_up,col5_down_l,col5_up_l
                fcb     40
                fdb     80
trogg_sr_d
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

levels
                fdb     lev_A_1
                fdb     lev_A_2
                fdb     lev_A_3
levels_end

stp_A_1_0
                fcb     2
                fdb     stp_A_1_0_0,stp_A_1_0_1
stp_A_1_0_0
                fcb     $6F,$4D
stp_A_1_0_1
                fcb     $B2,$E2
stp_A_1_1
                fcb     10
                fdb     stp_A_1_1_0,stp_A_1_1_1
stp_A_1_1_0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D
stp_A_1_1_1
                fcb     $B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2
stp_A_1_2
                fcb     12
                fdb     stp_A_1_2_0,stp_A_1_2_1
stp_A_1_2_0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D
stp_A_1_2_1
                fcb     $B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2
stp_A_1_3
                fcb     12
                fdb     stp_A_1_3_0,stp_A_1_3_1
stp_A_1_3_0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D
stp_A_1_3_1
                fcb     $B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2
stp_A_1_4
                fcb     2
                fdb     stp_A_1_4_0,stp_A_1_4_1
stp_A_1_4_0
                fcb     $6F,$4D
stp_A_1_4_1
                fcb     $B2,$E2
stp_A_1_5
                fcb     2
                fdb     stp_A_1_5_0,stp_A_1_5_1
stp_A_1_5_0
                fcb     $6F,$4D
stp_A_1_5_1
                fcb     $B2,$E2
stp_A_1_6
                fcb     2
                fdb     stp_A_1_6_0,stp_A_1_6_1
stp_A_1_6_0
                fcb     $6F,$4D
stp_A_1_6_1
                fcb     $B2,$E2
stp_A_1_7
                fcb     2
                fdb     stp_A_1_7_0,stp_A_1_7_1
stp_A_1_7_0
                fcb     $6F,$4D
stp_A_1_7_1
                fcb     $B2,$E2
stp_A_1_8
                fcb     2
                fdb     stp_A_1_8_0,stp_A_1_8_1
stp_A_1_8_0
                fcb     $6F,$4D
stp_A_1_8_1
                fcb     $B2,$E2
stp_A_1_9
                fcb     4
                fdb     stp_A_1_9_0,stp_A_1_9_1
stp_A_1_9_0
                fcb     $6F,$4D,$6F,$4D
stp_A_1_9_1
                fcb     $B2,$E2,$B2,$E2
stp_A_1_10
                fcb     2
                fdb     stp_A_1_10_0,stp_A_1_10_1
stp_A_1_10_0
                fcb     $6F,$4D
stp_A_1_10_1
                fcb     $B2,$E2
stp_A_1_11
                fcb     2
                fdb     stp_A_1_11_0,stp_A_1_11_1
stp_A_1_11_0
                fcb     $6F,$4D
stp_A_1_11_1
                fcb     $B2,$E2
stp_A_1_12
                fcb     4
                fdb     stp_A_1_12_0,stp_A_1_12_1
stp_A_1_12_0
                fcb     $6F,$4D,$6F,$4D
stp_A_1_12_1
                fcb     $B2,$E2,$B2,$E2
stp_A_1_13
                fcb     2
                fdb     stp_A_1_13_0,stp_A_1_13_1
stp_A_1_13_0
                fcb     $6F,$4D
stp_A_1_13_1
                fcb     $B2,$E2
stp_A_1_14
                fcb     2
                fdb     stp_A_1_14_0,stp_A_1_14_1
stp_A_1_14_0
                fcb     $6F,$4D
stp_A_1_14_1
                fcb     $B2,$E2
stp_A_1_15
                fcb     2
                fdb     stp_A_1_15_0,stp_A_1_15_1
stp_A_1_15_0
                fcb     $6F,$4D
stp_A_1_15_1
                fcb     $B2,$E2
stp_A_1_16
                fcb     2
                fdb     stp_A_1_16_0,stp_A_1_16_1
stp_A_1_16_0
                fcb     $6F,$4D
stp_A_1_16_1
                fcb     $B2,$E2
stp_A_1_17
                fcb     2
                fdb     stp_A_1_17_0,stp_A_1_17_1
stp_A_1_17_0
                fcb     $6F,$4D
stp_A_1_17_1
                fcb     $B2,$E2
stp_A_1_18
                fcb     4
                fdb     stp_A_1_18_0,stp_A_1_18_1
stp_A_1_18_0
                fcb     $6F,$4D,$6F,$4D
stp_A_1_18_1
                fcb     $B2,$E2,$B2,$E2
stp_A_1_19
                fcb     4
                fdb     stp_A_1_19_0,stp_A_1_19_1
stp_A_1_19_0
                fcb     $6F,$4D,$6F,$4D
stp_A_1_19_1
                fcb     $B2,$E2,$B2,$E2
stp_A_1_20
                fcb     2
                fdb     stp_A_1_20_0,stp_A_1_20_1
stp_A_1_20_0
                fcb     $6F,$4D
stp_A_1_20_1
                fcb     $B2,$E2
stp_A_1_21
                fcb     2
                fdb     stp_A_1_21_0,stp_A_1_21_1
stp_A_1_21_0
                fcb     $6F,$4D
stp_A_1_21_1
                fcb     $B2,$E2
stp_A_1_22
                fcb     2
                fdb     stp_A_1_22_0,stp_A_1_22_1
stp_A_1_22_0
                fcb     $6F,$4D
stp_A_1_22_1
                fcb     $B2,$E2
stp_A_1_23
                fcb     2
                fdb     stp_A_1_23_0,stp_A_1_23_1
stp_A_1_23_0
                fcb     $6F,$4D
stp_A_1_23_1
                fcb     $B2,$E2
stp_A_1_24
                fcb     4
                fdb     stp_A_1_24_0,stp_A_1_24_1
stp_A_1_24_0
                fcb     $6F,$4D,$6F,$4D
stp_A_1_24_1
                fcb     $B2,$E2,$B2,$E2
stp_A_1_25
                fcb     2
                fdb     stp_A_1_25_0,stp_A_1_25_1
stp_A_1_25_0
                fcb     $6F,$4D
stp_A_1_25_1
                fcb     $B2,$E2
stp_A_1_26
                fcb     4
                fdb     stp_A_1_26_0,stp_A_1_26_1
stp_A_1_26_0
                fcb     $6F,$4D,$6F,$4D
stp_A_1_26_1
                fcb     $B2,$E2,$B2,$E2
stp_A_1_27
                fcb     4
                fdb     stp_A_1_27_0,stp_A_1_27_1
stp_A_1_27_0
                fcb     $6F,$4D,$6F,$4D
stp_A_1_27_1
                fcb     $B2,$E2,$B2,$E2
stp_A_1_28
                fcb     2
                fdb     stp_A_1_28_0,stp_A_1_28_1
stp_A_1_28_0
                fcb     $6F,$4D
stp_A_1_28_1
                fcb     $B2,$E2
stp_A_1_29
                fcb     2
                fdb     stp_A_1_29_0,stp_A_1_29_1
stp_A_1_29_0
                fcb     $6F,$4D
stp_A_1_29_1
                fcb     $B2,$E2
stp_A_1_30
                fcb     2
                fdb     stp_A_1_30_0,stp_A_1_30_1
stp_A_1_30_0
                fcb     $6F,$4D
stp_A_1_30_1
                fcb     $B2,$E2
stp_A_1_31
                fcb     2
                fdb     stp_A_1_31_0,stp_A_1_31_1
stp_A_1_31_0
                fcb     $6F,$4D
stp_A_1_31_1
                fcb     $B2,$E2
stp_A_1_32
                fcb     2
                fdb     stp_A_1_32_0,stp_A_1_32_1
stp_A_1_32_0
                fcb     $6F,$4D
stp_A_1_32_1
                fcb     $B2,$E2
stp_A_1_33
                fcb     2
                fdb     stp_A_1_33_0,stp_A_1_33_1
stp_A_1_33_0
                fcb     $6F,$4D
stp_A_1_33_1
                fcb     $B2,$E2
stp_A_1_34
                fcb     2
                fdb     stp_A_1_34_0,stp_A_1_34_1
stp_A_1_34_0
                fcb     $6F,$4D
stp_A_1_34_1
                fcb     $B2,$E2
stp_A_1_35
                fcb     4
                fdb     stp_A_1_35_0,stp_A_1_35_1
stp_A_1_35_0
                fcb     $6F,$4D,$6F,$4D
stp_A_1_35_1
                fcb     $B2,$E2,$B2,$E2
stp_A_1_36
                fcb     2
                fdb     stp_A_1_36_0,stp_A_1_36_1
stp_A_1_36_0
                fcb     $6F,$4D
stp_A_1_36_1
                fcb     $B2,$E2
stp_A_1_37
                fcb     2
                fdb     stp_A_1_37_0,stp_A_1_37_1
stp_A_1_37_0
                fcb     $6F,$4D
stp_A_1_37_1
                fcb     $B2,$E2
stp_A_1_38
                fcb     2
                fdb     stp_A_1_38_0,stp_A_1_38_1
stp_A_1_38_0
                fcb     $6F,$4D
stp_A_1_38_1
                fcb     $B2,$E2
stp_A_1_39
                fcb     2
                fdb     stp_A_1_39_0,stp_A_1_39_1
stp_A_1_39_0
                fcb     $6F,$4D
stp_A_1_39_1
                fcb     $B2,$E2
stp_A_1_40
                fcb     2
                fdb     stp_A_1_40_0,stp_A_1_40_1
stp_A_1_40_0
                fcb     $6F,$4D
stp_A_1_40_1
                fcb     $B2,$E2
lev_A_1
                fdb     740
                fdb     strips_A_1,strips_A_1_end,sprites_A_1,sprites_A_1_end
                fdb     96,33
strips_A_1
                fcb     3
                fdb     stp_A_1_0,29,208
                fcb     0
                fcb     3
                fdb     stp_A_1_1,31,131
                fcb     0
                fcb     3
                fdb     stp_A_1_2,32,68
                fcb     0
                fcb     3
                fdb     stp_A_1_3,160,68
                fcb     0
                fcb     3
                fdb     stp_A_1_4,160,131
                fcb     0
                fcb     3
                fdb     stp_A_1_5,160,208
                fcb     0
                fcb     3
                fdb     stp_A_1_6,180,138
                fcb     0
                fcb     3
                fdb     stp_A_1_7,200,145
                fcb     0
                fcb     3
                fdb     stp_A_1_8,220,152
                fcb     0
                fcb     3
                fdb     stp_A_1_9,236,208
                fcb     0
                fcb     3
                fdb     stp_A_1_10,240,131
                fcb     0
                fcb     3
                fdb     stp_A_1_11,240,159
                fcb     0
                fcb     3
                fdb     stp_A_1_12,295,208
                fcb     0
                fcb     3
                fdb     stp_A_1_13,303,131
                fcb     0
                fcb     3
                fdb     stp_A_1_14,319,110
                fcb     0
                fcb     3
                fdb     stp_A_1_15,319,139
                fcb     0
                fcb     3
                fdb     stp_A_1_16,335,89
                fcb     0
                fcb     3
                fdb     stp_A_1_17,335,118
                fcb     0
                fcb     3
                fdb     stp_A_1_18,351,68
                fcb     0
                fcb     3
                fdb     stp_A_1_19,351,97
                fcb     0
                fcb     3
                fdb     stp_A_1_20,383,89
                fcb     0
                fcb     3
                fdb     stp_A_1_21,383,118
                fcb     0
                fcb     3
                fdb     stp_A_1_22,399,110
                fcb     0
                fcb     3
                fdb     stp_A_1_23,399,139
                fcb     0
                fcb     3
                fdb     stp_A_1_24,411,208
                fcb     0
                fcb     3
                fdb     stp_A_1_25,415,131
                fcb     0
                fcb     3
                fdb     stp_A_1_26,482,208
                fcb     0
                fcb     3
                fdb     stp_A_1_27,483,68
                fcb     0
                fcb     3
                fdb     stp_A_1_28,491,128
                fcb     0
                fcb     3
                fdb     stp_A_1_29,518,113
                fcb     0
                fcb     3
                fdb     stp_A_1_30,518,137
                fcb     0
                fcb     3
                fdb     stp_A_1_31,545,98
                fcb     0
                fcb     3
                fdb     stp_A_1_32,545,148
                fcb     0
                fcb     3
                fdb     stp_A_1_33,572,83
                fcb     0
                fcb     3
                fdb     stp_A_1_34,574,160
                fcb     0
                fcb     3
                fdb     stp_A_1_35,598,68
                fcb     0
                fcb     3
                fdb     stp_A_1_36,601,173
                fcb     0
                fcb     3
                fdb     stp_A_1_37,601,209
                fcb     0
                fcb     3
                fdb     stp_A_1_38,671,68
                fcb     0
                fcb     3
                fdb     stp_A_1_39,671,130
                fcb     0
                fcb     3
                fdb     stp_A_1_40,672,209
                fcb     0
strips_A_1_end
sprites_A_1
                fcb     1
                fdb     spr_trogg_sr,25,175
                fcb     0
                fcb     1
                fdb     spr_ladder2,33,81
                fcb     0
                fcb     1
                fdb     spr_ladder4,33,144
                fcb     0
                fcb     1
                fdb     spr_gem,66,122
                fcb     0
                fcb     1
                fdb     spr_scrubbly,71,26
                fcb     0
                fcb     1
                fdb     spr_ladder2,161,81
                fcb     0
                fcb     1
                fdb     spr_ladder4,161,144
                fcb     0
                fcb     1
                fdb     spr_gem,163,200
                fcb     0
                fcb     1
                fdb     spr_scrubbly,191,26
                fcb     0
                fcb     1
                fdb     spr_scrubbly,191,103
                fcb     0
                fcb     2
                fdb     rsp_key,241,199
                fcb     0
                fcb     1
                fdb     spr_gem,243,59
                fcb     0
                fcb     1
                fdb     spr_ladder2,243,81
                fcb     0
                fcb     1
                fdb     spr_ladder1,243,173
                fcb     0
                fcb     1
                fdb     spr_scrubbly,294,166
                fcb     0
                fcb     1
                fdb     spr_gem,305,122
                fcb     0
                fcb     1
                fdb     spr_ladder4,306,144
                fcb     0
                fcb     1
                fdb     spr_ladder1,322,123
                fcb     0
                fcb     1
                fdb     spr_ladder1,338,102
                fcb     0
                fcb     1
                fdb     spr_ladder1,354,81
                fcb     0
                fcb     2
                fdb     rsp_key,357,59
                fcb     0
                fcb     1
                fdb     spr_ladder1,369,81
                fcb     0
                fcb     1
                fdb     spr_ladder1,385,102
                fcb     0
                fcb     1
                fdb     spr_ladder1,401,123
                fcb     0
                fcb     1
                fdb     spr_scrubbly,410,166
                fcb     0
                fcb     1
                fdb     spr_ladder4,417,143
                fcb     0
                fcb     1
                fdb     spr_gem,418,122
                fcb     0
                fcb     1
                fdb     spr_scrubbly,483,86
                fcb     0
                fcb     2
                fdb     rsp_key,488,199
                fcb     0
                fcb     1
                fdb     spr_ladder2,493,81
                fcb     0
                fcb     1
                fdb     spr_ladder4,493,142
                fcb     0
                fcb     1
                fdb     spr_ladder1,603,186
                fcb     0
                fcb     1
                fdb     spr_gem,604,201
                fcb     0
                fcb     1
                fdb     spr_scrubbly,662,26
                fcb     0
                fcb     2
                fdb     rsp_key,669,200
                fcb     0
                fcb     1
                fdb     spr_ladder2,674,82
                fcb     0
                fcb     1
                fdb     spr_gem,674,122
                fcb     0
                fcb     1
                fdb     spr_ladder3,674,144
                fcb     0
sprites_A_1_end

stp_A_2_0
                fcb     9
                fdb     stp_A_2_0_0,stp_A_2_0_1
stp_A_2_0_0
                fcb     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0
stp_A_2_0_1
                fcb     $03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8
stp_A_2_1
                fcb     4
                fdb     stp_A_2_1_0,stp_A_2_1_1
stp_A_2_1_0
                fcb     $7F,$FF,$FF,$FE
stp_A_2_1_1
                fcb     $3F,$FF,$FF,$F8
stp_A_2_2
                fcb     12
                fdb     stp_A_2_2_0,stp_A_2_2_1
stp_A_2_2_0
                fcb     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0
stp_A_2_2_1
                fcb     $03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8
stp_A_2_3
                fcb     3
                fdb     stp_A_2_3_0,stp_A_2_3_1
stp_A_2_3_0
                fcb     $7F,$FF,$E0
stp_A_2_3_1
                fcb     $03,$FF,$F8
stp_A_2_4
                fcb     4
                fdb     stp_A_2_4_0,stp_A_2_4_1
stp_A_2_4_0
                fcb     $7F,$FF,$FF,$FE
stp_A_2_4_1
                fcb     $3F,$FF,$FF,$F8
stp_A_2_5
                fcb     4
                fdb     stp_A_2_5_0,stp_A_2_5_1
stp_A_2_5_0
                fcb     $7F,$FF,$FF,$FE
stp_A_2_5_1
                fcb     $3F,$FF,$FF,$F8
stp_A_2_6
                fcb     12
                fdb     stp_A_2_6_0,stp_A_2_6_1
stp_A_2_6_0
                fcb     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0
stp_A_2_6_1
                fcb     $03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8
stp_A_2_7
                fcb     3
                fdb     stp_A_2_7_0,stp_A_2_7_1
stp_A_2_7_0
                fcb     $7F,$FF,$E0
stp_A_2_7_1
                fcb     $03,$FF,$F8
stp_A_2_8
                fcb     3
                fdb     stp_A_2_8_0,stp_A_2_8_1
stp_A_2_8_0
                fcb     $7F,$FF,$E0
stp_A_2_8_1
                fcb     $03,$FF,$F8
stp_A_2_9
                fcb     4
                fdb     stp_A_2_9_0,stp_A_2_9_1
stp_A_2_9_0
                fcb     $7F,$FF,$FF,$FE
stp_A_2_9_1
                fcb     $3F,$FF,$FF,$F8
stp_A_2_10
                fcb     3
                fdb     stp_A_2_10_0,stp_A_2_10_1
stp_A_2_10_0
                fcb     $7F,$FF,$E0
stp_A_2_10_1
                fcb     $03,$FF,$F8
stp_A_2_11
                fcb     4
                fdb     stp_A_2_11_0,stp_A_2_11_1
stp_A_2_11_0
                fcb     $7F,$FF,$FF,$FE
stp_A_2_11_1
                fcb     $3F,$FF,$FF,$F8
stp_A_2_12
                fcb     3
                fdb     stp_A_2_12_0,stp_A_2_12_1
stp_A_2_12_0
                fcb     $7F,$FF,$E0
stp_A_2_12_1
                fcb     $03,$FF,$F8
stp_A_2_13
                fcb     9
                fdb     stp_A_2_13_0,stp_A_2_13_1
stp_A_2_13_0
                fcb     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0
stp_A_2_13_1
                fcb     $03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8
stp_A_2_14
                fcb     3
                fdb     stp_A_2_14_0,stp_A_2_14_1
stp_A_2_14_0
                fcb     $7F,$FF,$E0
stp_A_2_14_1
                fcb     $03,$FF,$F8
stp_A_2_15
                fcb     3
                fdb     stp_A_2_15_0,stp_A_2_15_1
stp_A_2_15_0
                fcb     $7F,$FF,$E0
stp_A_2_15_1
                fcb     $03,$FF,$F8
stp_A_2_16
                fcb     3
                fdb     stp_A_2_16_0,stp_A_2_16_1
stp_A_2_16_0
                fcb     $7F,$FF,$E0
stp_A_2_16_1
                fcb     $03,$FF,$F8
stp_A_2_17
                fcb     3
                fdb     stp_A_2_17_0,stp_A_2_17_1
stp_A_2_17_0
                fcb     $7F,$FF,$E0
stp_A_2_17_1
                fcb     $03,$FF,$F8
stp_A_2_18
                fcb     3
                fdb     stp_A_2_18_0,stp_A_2_18_1
stp_A_2_18_0
                fcb     $7F,$FF,$E0
stp_A_2_18_1
                fcb     $03,$FF,$F8
stp_A_2_19
                fcb     9
                fdb     stp_A_2_19_0,stp_A_2_19_1
stp_A_2_19_0
                fcb     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0
stp_A_2_19_1
                fcb     $03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8
stp_A_2_20
                fcb     18
                fdb     stp_A_2_20_0,stp_A_2_20_1
stp_A_2_20_0
                fcb     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
                fcb     $FF,$E0
stp_A_2_20_1
                fcb     $03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
                fcb     $FF,$F8
stp_A_2_21
                fcb     9
                fdb     stp_A_2_21_0,stp_A_2_21_1
stp_A_2_21_0
                fcb     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0
stp_A_2_21_1
                fcb     $03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8
stp_A_2_22
                fcb     3
                fdb     stp_A_2_22_0,stp_A_2_22_1
stp_A_2_22_0
                fcb     $7F,$FF,$E0
stp_A_2_22_1
                fcb     $03,$FF,$F8
stp_A_2_23
                fcb     9
                fdb     stp_A_2_23_0,stp_A_2_23_1
stp_A_2_23_0
                fcb     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0
stp_A_2_23_1
                fcb     $03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8
stp_A_2_24
                fcb     3
                fdb     stp_A_2_24_0,stp_A_2_24_1
stp_A_2_24_0
                fcb     $7F,$FF,$E0
stp_A_2_24_1
                fcb     $03,$FF,$F8
stp_A_2_25
                fcb     3
                fdb     stp_A_2_25_0,stp_A_2_25_1
stp_A_2_25_0
                fcb     $7F,$FF,$E0
stp_A_2_25_1
                fcb     $03,$FF,$F8
stp_A_2_26
                fcb     4
                fdb     stp_A_2_26_0,stp_A_2_26_1
stp_A_2_26_0
                fcb     $7F,$FF,$FF,$FE
stp_A_2_26_1
                fcb     $3F,$FF,$FF,$F8
stp_A_2_27
                fcb     12
                fdb     stp_A_2_27_0,stp_A_2_27_1
stp_A_2_27_0
                fcb     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0
stp_A_2_27_1
                fcb     $03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8
stp_A_2_28
                fcb     3
                fdb     stp_A_2_28_0,stp_A_2_28_1
stp_A_2_28_0
                fcb     $7F,$FF,$E0
stp_A_2_28_1
                fcb     $03,$FF,$F8
stp_A_2_29
                fcb     12
                fdb     stp_A_2_29_0,stp_A_2_29_1
stp_A_2_29_0
                fcb     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0
stp_A_2_29_1
                fcb     $03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8
stp_A_2_30
                fcb     3
                fdb     stp_A_2_30_0,stp_A_2_30_1
stp_A_2_30_0
                fcb     $7F,$FF,$E0
stp_A_2_30_1
                fcb     $03,$FF,$F8
stp_A_2_31
                fcb     9
                fdb     stp_A_2_31_0,stp_A_2_31_1
stp_A_2_31_0
                fcb     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0
stp_A_2_31_1
                fcb     $03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8
stp_A_2_32
                fcb     3
                fdb     stp_A_2_32_0,stp_A_2_32_1
stp_A_2_32_0
                fcb     $7F,$FF,$E0
stp_A_2_32_1
                fcb     $03,$FF,$F8
lev_A_2
                fdb     620
                fdb     strips_A_2,strips_A_2_end,sprites_A_2,sprites_A_2_end
                fdb     140,26
strips_A_2
                fcb     3
                fdb     stp_A_2_0,12,68
                fcb     0
                fcb     3
                fdb     stp_A_2_1,12,111
                fcb     0
                fcb     3
                fdb     stp_A_2_2,12,195
                fcb     0
                fcb     3
                fdb     stp_A_2_3,74,111
                fcb     0
                fcb     3
                fdb     stp_A_2_4,84,150
                fcb     0
                fcb     3
                fdb     stp_A_2_5,101,68
                fcb     0
                fcb     3
                fdb     stp_A_2_6,106,220
                fcb     0
                fcb     3
                fdb     stp_A_2_7,124,94
                fcb     0
                fcb     3
                fdb     stp_A_2_8,136,134
                fcb     0
                fcb     3
                fdb     stp_A_2_9,152,68
                fcb     0
                fcb     3
                fdb     stp_A_2_10,156,109
                fcb     0
                fcb     3
                fdb     stp_A_2_11,188,167
                fcb     0
                fcb     3
                fdb     stp_A_2_12,206,191
                fcb     0
                fcb     3
                fdb     stp_A_2_13,208,118
                fcb     0
                fcb     3
                fdb     stp_A_2_14,211,73
                fcb     0
                fcb     3
                fdb     stp_A_2_15,213,208
                fcb     0
                fcb     3
                fdb     stp_A_2_16,223,224
                fcb     0
                fcb     3
                fdb     stp_A_2_17,255,81
                fcb     0
                fcb     3
                fdb     stp_A_2_18,255,95
                fcb     0
                fcb     3
                fdb     stp_A_2_19,260,186
                fcb     0
                fcb     3
                fdb     stp_A_2_20,268,56
                fcb     0
                fcb     3
                fdb     stp_A_2_21,273,224
                fcb     0
                fcb     3
                fdb     stp_A_2_22,305,96
                fcb     0
                fcb     3
                fdb     stp_A_2_23,320,142
                fcb     0
                fcb     3
                fdb     stp_A_2_24,357,211
                fcb     0
                fcb     3
                fdb     stp_A_2_25,393,198
                fcb     0
                fcb     3
                fdb     stp_A_2_26,420,224
                fcb     0
                fcb     3
                fdb     stp_A_2_27,434,157
                fcb     0
                fcb     3
                fdb     stp_A_2_28,436,124
                fcb     0
                fcb     3
                fdb     stp_A_2_29,456,55
                fcb     0
                fcb     3
                fdb     stp_A_2_30,485,124
                fcb     0
                fcb     3
                fdb     stp_A_2_31,501,224
                fcb     0
                fcb     3
                fdb     stp_A_2_32,532,124
                fcb     0
strips_A_2_end
sprites_A_2
                fcb     2
                fdb     rsp_key,12,102
                fcb     0
                fcb     1
                fdb     spr_gem,25,59
                fcb     0
                fcb     1
                fdb     spr_trogg_sr,30,161
                fcb     0
                fcb     1
                fdb     spr_qiana1,56,80
                fcb     0
                fcb     1
                fdb     spr_poglet,77,97
                fcb     0
                fcb     1
                fdb     spr_qiana1,84,162
                fcb     0
                fcb     1
                fdb     spr_qiana2,87,53
                fcb     0
                fcb     1
                fdb     spr_qiana2,111,162
                fcb     0
                fcb     1
                fdb     spr_gem,128,85
                fcb     0
                fcb     1
                fdb     spr_qiana1,140,106
                fcb     0
                fcb     1
                fdb     spr_poglet,156,36
                fcb     0
                fcb     1
                fdb     spr_qiana1,164,80
                fcb     0
                fcb     1
                fdb     spr_poglet,179,187
                fcb     0
                fcb     1
                fdb     spr_qiana1,189,179
                fcb     0
                fcb     2
                fdb     rsp_key,201,180
                fcb     0
                fcb     1
                fdb     spr_qiana1,212,130
                fcb     0
                fcb     1
                fdb     spr_poglet,253,153
                fcb     0
                fcb     1
                fdb     spr_qiana2,264,130
                fcb     0
                fcb     1
                fdb     spr_poglet,276,23
                fcb     0
                fcb     1
                fdb     spr_qiana1,296,197
                fcb     0
                fcb     1
                fdb     spr_qiana1,313,68
                fcb     0
                fcb     1
                fdb     spr_qiana1,320,154
                fcb     0
                fcb     1
                fdb     spr_gem,375,47
                fcb     0
                fcb     1
                fdb     spr_poglet,391,104
                fcb     0
                fcb     1
                fdb     spr_qiana3,400,68
                fcb     0
                fcb     1
                fdb     spr_poglet,431,191
                fcb     0
                fcb     1
                fdb     spr_qiana1,441,169
                fcb     0
                fcb     1
                fdb     spr_qiana3,468,67
                fcb     0
                fcb     1
                fdb     spr_poglet,484,103
                fcb     0
                fcb     1
                fdb     spr_poglet,502,191
                fcb     0
                fcb     1
                fdb     spr_qiana1,512,169
                fcb     0
                fcb     1
                fdb     spr_qiana1,518,67
                fcb     0
                fcb     1
                fdb     spr_gem,527,46
                fcb     0
                fcb     2
                fdb     rsp_key,531,114
                fcb     0
                fcb     2
                fdb     rsp_key,547,214
                fcb     0
sprites_A_2_end

stp_A_3_0
                fcb     2
                fdb     stp_A_3_0_0,stp_A_3_0_1
stp_A_3_0_0
                fcb     $FF,$F0
stp_A_3_0_1
                fcb     $07,$FE
stp_A_3_1
                fcb     2
                fdb     stp_A_3_1_0,stp_A_3_1_1
stp_A_3_1_0
                fcb     $FF,$F0
stp_A_3_1_1
                fcb     $07,$FE
stp_A_3_2
                fcb     9
                fdb     stp_A_3_2_0,stp_A_3_2_1
stp_A_3_2_0
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
stp_A_3_2_1
                fcb     $7F,$E7,$FE,$7F,$E7,$FE,$7F,$E7,$FE
stp_A_3_3
                fcb     2
                fdb     stp_A_3_3_0,stp_A_3_3_1
stp_A_3_3_0
                fcb     $FF,$F0
stp_A_3_3_1
                fcb     $07,$FE
stp_A_3_4
                fcb     3
                fdb     stp_A_3_4_0,stp_A_3_4_1
stp_A_3_4_0
                fcb     $FF,$FF,$FF
stp_A_3_4_1
                fcb     $7F,$E7,$FE
stp_A_3_5
                fcb     3
                fdb     stp_A_3_5_0,stp_A_3_5_1
stp_A_3_5_0
                fcb     $FF,$FF,$FF
stp_A_3_5_1
                fcb     $7F,$E7,$FE
stp_A_3_6
                fcb     3
                fdb     stp_A_3_6_0,stp_A_3_6_1
stp_A_3_6_0
                fcb     $FF,$FF,$FF
stp_A_3_6_1
                fcb     $7F,$E7,$FE
stp_A_3_7
                fcb     3
                fdb     stp_A_3_7_0,stp_A_3_7_1
stp_A_3_7_0
                fcb     $FF,$FF,$FF
stp_A_3_7_1
                fcb     $7F,$E7,$FE
stp_A_3_8
                fcb     3
                fdb     stp_A_3_8_0,stp_A_3_8_1
stp_A_3_8_0
                fcb     $FF,$FF,$FF
stp_A_3_8_1
                fcb     $7F,$E7,$FE
stp_A_3_9
                fcb     6
                fdb     stp_A_3_9_0,stp_A_3_9_1
stp_A_3_9_0
                fcb     $FF,$FF,$FF,$FF,$FF,$FF
stp_A_3_9_1
                fcb     $7F,$E7,$FE,$7F,$E7,$FE
stp_A_3_10
                fcb     8
                fdb     stp_A_3_10_0,stp_A_3_10_1
stp_A_3_10_0
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0
stp_A_3_10_1
                fcb     $07,$FE,$7F,$E7,$FE,$7F,$E7,$FE
stp_A_3_11
                fcb     3
                fdb     stp_A_3_11_0,stp_A_3_11_1
stp_A_3_11_0
                fcb     $FF,$FF,$FF
stp_A_3_11_1
                fcb     $7F,$E7,$FE
stp_A_3_12
                fcb     2
                fdb     stp_A_3_12_0,stp_A_3_12_1
stp_A_3_12_0
                fcb     $FF,$F0
stp_A_3_12_1
                fcb     $07,$FE
stp_A_3_13
                fcb     2
                fdb     stp_A_3_13_0,stp_A_3_13_1
stp_A_3_13_0
                fcb     $FF,$F0
stp_A_3_13_1
                fcb     $07,$FE
stp_A_3_14
                fcb     11
                fdb     stp_A_3_14_0,stp_A_3_14_1
stp_A_3_14_0
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0
stp_A_3_14_1
                fcb     $07,$FE,$7F,$E7,$FE,$7F,$E7,$FE,$7F,$E7,$FE
stp_A_3_15
                fcb     5
                fdb     stp_A_3_15_0,stp_A_3_15_1
stp_A_3_15_0
                fcb     $FF,$FF,$FF,$FF,$F0
stp_A_3_15_1
                fcb     $07,$FE,$7F,$E7,$FE
stp_A_3_16
                fcb     3
                fdb     stp_A_3_16_0,stp_A_3_16_1
stp_A_3_16_0
                fcb     $FF,$FF,$FF
stp_A_3_16_1
                fcb     $7F,$E7,$FE
stp_A_3_17
                fcb     2
                fdb     stp_A_3_17_0,stp_A_3_17_1
stp_A_3_17_0
                fcb     $FF,$F0
stp_A_3_17_1
                fcb     $07,$FE
stp_A_3_18
                fcb     2
                fdb     stp_A_3_18_0,stp_A_3_18_1
stp_A_3_18_0
                fcb     $FF,$F0
stp_A_3_18_1
                fcb     $07,$FE
stp_A_3_19
                fcb     5
                fdb     stp_A_3_19_0,stp_A_3_19_1
stp_A_3_19_0
                fcb     $FF,$FF,$FF,$FF,$F0
stp_A_3_19_1
                fcb     $07,$FE,$7F,$E7,$FE
stp_A_3_20
                fcb     2
                fdb     stp_A_3_20_0,stp_A_3_20_1
stp_A_3_20_0
                fcb     $FF,$F0
stp_A_3_20_1
                fcb     $07,$FE
stp_A_3_21
                fcb     2
                fdb     stp_A_3_21_0,stp_A_3_21_1
stp_A_3_21_0
                fcb     $FF,$F0
stp_A_3_21_1
                fcb     $07,$FE
stp_A_3_22
                fcb     6
                fdb     stp_A_3_22_0,stp_A_3_22_1
stp_A_3_22_0
                fcb     $FF,$FF,$FF,$FF,$FF,$FF
stp_A_3_22_1
                fcb     $7F,$E7,$FE,$7F,$E7,$FE
stp_A_3_23
                fcb     2
                fdb     stp_A_3_23_0,stp_A_3_23_1
stp_A_3_23_0
                fcb     $FF,$F0
stp_A_3_23_1
                fcb     $07,$FE
stp_A_3_24
                fcb     6
                fdb     stp_A_3_24_0,stp_A_3_24_1
stp_A_3_24_0
                fcb     $FF,$FF,$FF,$FF,$FF,$FF
stp_A_3_24_1
                fcb     $7F,$E7,$FE,$7F,$E7,$FE
stp_A_3_25
                fcb     8
                fdb     stp_A_3_25_0,stp_A_3_25_1
stp_A_3_25_0
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0
stp_A_3_25_1
                fcb     $07,$FE,$7F,$E7,$FE,$7F,$E7,$FE
stp_A_3_26
                fcb     8
                fdb     stp_A_3_26_0,stp_A_3_26_1
stp_A_3_26_0
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0
stp_A_3_26_1
                fcb     $07,$FE,$7F,$E7,$FE,$7F,$E7,$FE
stp_A_3_27
                fcb     2
                fdb     stp_A_3_27_0,stp_A_3_27_1
stp_A_3_27_0
                fcb     $FF,$F0
stp_A_3_27_1
                fcb     $07,$FE
stp_A_3_28
                fcb     2
                fdb     stp_A_3_28_0,stp_A_3_28_1
stp_A_3_28_0
                fcb     $FF,$F0
stp_A_3_28_1
                fcb     $07,$FE
stp_A_3_29
                fcb     5
                fdb     stp_A_3_29_0,stp_A_3_29_1
stp_A_3_29_0
                fcb     $FF,$FF,$FF,$FF,$F0
stp_A_3_29_1
                fcb     $07,$FE,$7F,$E7,$FE
stp_A_3_30
                fcb     2
                fdb     stp_A_3_30_0,stp_A_3_30_1
stp_A_3_30_0
                fcb     $FF,$F0
stp_A_3_30_1
                fcb     $07,$FE
lev_A_3
                fdb     680
                fdb     strips_A_3,strips_A_3_end,sprites_A_3,sprites_A_3_end
                fdb     84,26
strips_A_3
                fcb     3
                fdb     stp_A_3_0,6,111
                fcb     0
                fcb     3
                fdb     stp_A_3_1,6,155
                fcb     0
                fcb     3
                fdb     stp_A_3_2,7,211
                fcb     0
                fcb     3
                fdb     stp_A_3_3,27,91
                fcb     0
                fcb     3
                fdb     stp_A_3_4,56,124
                fcb     0
                fcb     3
                fdb     stp_A_3_5,78,91
                fcb     0
                fcb     3
                fdb     stp_A_3_6,98,134
                fcb     0
                fcb     3
                fdb     stp_A_3_7,118,217
                fcb     0
                fcb     3
                fdb     stp_A_3_8,136,208
                fcb     0
                fcb     3
                fdb     stp_A_3_9,138,68
                fcb     0
                fcb     3
                fdb     stp_A_3_10,146,142
                fcb     0
                fcb     3
                fdb     stp_A_3_11,151,199
                fcb     0
                fcb     3
                fdb     stp_A_3_12,216,199
                fcb     0
                fcb     3
                fdb     stp_A_3_13,235,102
                fcb     0
                fcb     3
                fdb     stp_A_3_14,252,67
                fcb     0
                fcb     3
                fdb     stp_A_3_15,268,141
                fcb     0
                fcb     3
                fdb     stp_A_3_16,269,200
                fcb     0
                fcb     3
                fdb     stp_A_3_17,270,102
                fcb     0
                fcb     3
                fdb     stp_A_3_18,312,180
                fcb     0
                fcb     3
                fdb     stp_A_3_19,332,229
                fcb     0
                fcb     3
                fdb     stp_A_3_20,359,87
                fcb     0
                fcb     3
                fdb     stp_A_3_21,373,159
                fcb     0
                fcb     3
                fdb     stp_A_3_22,381,219
                fcb     0
                fcb     3
                fdb     stp_A_3_23,442,49
                fcb     0
                fcb     3
                fdb     stp_A_3_24,445,208
                fcb     0
                fcb     3
                fdb     stp_A_3_25,469,99
                fcb     0
                fcb     3
                fdb     stp_A_3_26,513,196
                fcb     0
                fcb     3
                fdb     stp_A_3_27,560,158
                fcb     0
                fcb     3
                fdb     stp_A_3_28,561,128
                fcb     0
                fcb     3
                fdb     stp_A_3_29,567,99
                fcb     0
                fcb     3
                fdb     stp_A_3_30,597,141
                fcb     0
strips_A_3_end
sprites_A_3
                fcb     1
                fdb     spr_trogg_sr,19,178
                fcb     0
                fcb     1
                fdb     spr_chain4,29,105
                fcb     0
                fcb     2
                fdb     rsp_key,57,114
                fcb     0
                fcb     1
                fdb     spr_hooter,80,68
                fcb     0
                fcb     1
                fdb     spr_hooter,100,111
                fcb     0
                fcb     1
                fdb     spr_chain1,139,82
                fcb     0
                fcb     1
                fdb     spr_hooter,153,176
                fcb     0
                fcb     1
                fdb     spr_gem,174,59
                fcb     0
                fcb     1
                fdb     spr_chain2,176,82
                fcb     0
                fcb     1
                fdb     spr_hooter,214,177
                fcb     0
                fcb     1
                fdb     spr_chain2,254,81
                fcb     0
                fcb     1
                fdb     spr_hooter,276,119
                fcb     0
                fcb     2
                fdb     rsp_key,281,57
                fcb     0
                fcb     1
                fdb     spr_chain1,282,155
                fcb     0
                fcb     1
                fdb     spr_chain2,314,194
                fcb     0
                fcb     1
                fdb     spr_gem,344,220
                fcb     0
                fcb     1
                fdb     spr_chain4,376,63
                fcb     0
                fcb     1
                fdb     spr_chain1,396,159
                fcb     0
                fcb     1
                fdb     spr_chain3,397,63
                fcb     0
                fcb     1
                fdb     spr_chain2,420,63
                fcb     0
                fcb     1
                fdb     spr_gem,443,40
                fcb     0
                fcb     1
                fdb     spr_chain1,444,63
                fcb     0
                fcb     1
                fdb     spr_hooter,478,77
                fcb     0
                fcb     2
                fdb     rsp_key,503,89
                fcb     0
                fcb     1
                fdb     spr_gem,579,89
                fcb     0
                fcb     1
                fdb     spr_chain4,581,113
                fcb     0
sprites_A_3_end

