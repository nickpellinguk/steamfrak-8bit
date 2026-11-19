; made by vectrex/tools/m1_rt_gen.py: sprites, a strip and the scene

spr_trogg                                  ; 26 columns of 5 bytes
                fcb     26,5
                fdb     trogg_data,col5_down,col5_up,col5_down_l,col5_up_l
                fcb     40
                fdb     80
spr_scrubbly                                  ; 33 columns of 6 bytes
                fcb     33,6
                fdb     scrubbly_data,col6_down,col6_up,col6_down_l,col6_up_l
                fcb     48
                fdb     96
spr_poglet                                  ; 23 columns of 5 bytes
                fcb     23,5
                fdb     poglet_data,col5_down,col5_up,col5_down_l,col5_up_l
                fcb     40
                fdb     80
spr_hooter                                  ; 19 columns of 4 bytes
                fcb     19,4
                fdb     hooter_data,col4_down,col4_up,col4_down_l,col4_up_l
                fcb     32
                fdb     64
spr_gem                                  ; 11 columns of 2 bytes
                fcb     11,2
                fdb     gem_data,col2_down,col2_up,col2_down_l,col2_up_l
                fcb     16
                fdb     32
spr_ladder                                  ; 12 columns of 10 bytes
                fcb     12,10
                fdb     ladder_data,col10_down,col10_up,col10_down_l,col10_up_l
                fcb     80
                fdb     160
rsp_key                                  ; 10 rows of 3 bytes
                fcb     22,3,10
                fdb     18,key_data,rows3_10
rsp_yoyo                                  ; 6 rows of 1 bytes
                fcb     7,1,6
                fdb     12,yoyo_data,rows1_6

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
key_data
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
yoyo_data
                fcb     $7C
                fcb     $63
                fcb     $F2
                fcb     $5F
                fcb     $FE
                fcb     $3E

stp_ledges                              ; 33 bytes a row
                fcb     33
                fdb     ledges_row0,ledges_row1
ledges_row0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$00,$00,$6F,$4D,$6F,$4D,$6F,$4D
                fcb     $00,$00,$6F,$4D,$6F,$4D,$6F,$4D,$00,$00,$6F,$4D,$6F,$4D,$6F,$4D
                fcb     $60
ledges_row1
                fcb     $02,$B2,$E2,$B2,$E2,$B2,$E2,$00,$00,$B2,$E2,$B2,$E2,$B2,$E2,$00
                fcb     $00,$B2,$E2,$B2,$E2,$B2,$E2,$00,$00,$B2,$E2,$B2,$E2,$B2,$E2,$B2
                fcb     $E2

scene
                fcb     1
                fdb     spr_trogg,-20,-60
                fcb     0
                fcb     1
                fdb     spr_trogg,10,-60
                fcb     1
                fcb     1
                fdb     spr_scrubbly,-100,-70
                fcb     0
                fcb     1
                fdb     spr_scrubbly,70,-70
                fcb     1
                fcb     1
                fdb     spr_poglet,-60,20
                fcb     1
                fcb     1
                fdb     spr_hooter,40,30
                fcb     0
                fcb     1
                fdb     spr_ladder,-5,0
                fcb     0
                fcb     1
                fdb     spr_gem,-90,60
                fcb     0
                fcb     1
                fdb     spr_gem,80,60
                fcb     0
                fcb     2
                fdb     rsp_key,-40,80
                fcb     0
                fcb     2
                fdb     rsp_yoyo,30,80
                fcb     0
                fcb     3
                fdb     stp_ledges,-130,100
                fcb     0
                fcb     0
