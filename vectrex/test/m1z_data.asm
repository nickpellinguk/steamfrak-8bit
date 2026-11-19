; made by vectrex/tools/m1_zig_gen.py: the test scene

draw_scene
; trogg at (-100, -100): full columns
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7F82
                jsr     Moveto_d
                ldx     #move_0
                jsr     vlist_d
dc_0_start
                ldx     #trogg_data
                lda     #27
                sta     $C880
                jsr     col5_down
dc_0_end
; trogg at (-70, -100): zigzag
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7EA8
                jsr     Moveto_d
                ldx     #move_1
                jsr     vlist_d
dc_1_start
                ldx     #trogg_z_data
                jsr     zig_trogg
dc_1_end
; scrubbly at (-40, -108): full columns
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7FCD
                jsr     Moveto_d
                ldx     #move_2
                jsr     vlist_d
dc_2_start
                ldx     #scrubbly_data
                lda     #34
                sta     $C880
                jsr     col6_down
dc_2_end
; scrubbly at (-3, -108): zigzag
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7FFD
                jsr     Moveto_d
                ldx     #move_3
                jsr     vlist_d
dc_3_start
                ldx     #scrubbly_z_data
                jsr     zig_scrubbly
dc_3_end
; ladder at (44, -100): full columns
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7F36
                jsr     Moveto_d
                ldx     #move_4
                jsr     vlist_d
dc_4_start
                ldx     #ladder_data
                lda     #13
                sta     $C880
                jsr     col10_down
dc_4_end
; ladder at (62, -100): zigzag
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7E4E
                jsr     Moveto_d
                ldx     #move_5
                jsr     vlist_d
dc_5_start
                ldx     #ladder_z_data
                jsr     zig_ladder
dc_5_end
; poglet at (-100, -40): full columns
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$3482
                jsr     Moveto_d
                ldx     #move_6
                jsr     vlist_d
dc_6_start
                ldx     #poglet_data
                lda     #24
                sta     $C880
                jsr     col5_down
dc_6_end
; poglet at (-72, -40): zigzag
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$32A6
                jsr     Moveto_d
                ldx     #move_7
                jsr     vlist_d
dc_7_start
                ldx     #poglet_z_data
                jsr     zig_poglet
dc_7_end
; hooter at (-44, -30): full columns
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$28C8
                jsr     Moveto_d
                ldx     #move_8
                jsr     vlist_d
dc_8_start
                ldx     #hooter_data
                lda     #20
                sta     $C880
                jsr     col4_down
dc_8_end
; hooter at (-20, -30): zigzag
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$25E7
                jsr     Moveto_d
                ldx     #move_9
                jsr     vlist_d
dc_9_start
                ldx     #hooter_z_data
                jsr     zig_hooter
dc_9_end
; gem at (10, -20): full columns
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$1B0B
                jsr     Moveto_d
                ldx     #move_10
                jsr     vlist_d
dc_10_start
                ldx     #gem_data
                lda     #12
                sta     $C880
                jsr     col2_down
dc_10_end
; gem at (26, -20): zigzag
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$1920
                jsr     Moveto_d
                ldx     #move_11
                jsr     vlist_d
dc_11_start
                ldx     #gem_z_data
                jsr     zig_gem
dc_11_end
; bulb at (44, -20): full columns
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$1B36
                jsr     Moveto_d
                ldx     #move_12
                jsr     vlist_d
dc_12_start
                ldx     #bulb_data
                lda     #11
                sta     $C880
                jsr     col3_down
dc_12_end
; bulb at (60, -20): zigzag
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$194B
                jsr     Moveto_d
                ldx     #move_13
                jsr     vlist_d
dc_13_start
                ldx     #bulb_z_data
                jsr     zig_bulb
dc_13_end
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
                fcb     10,117,-10,$00
                fcb     0,0
move_4
                fcb     2,103,54,$00
                fcb     0,0
move_5
                fcb     0,0
move_6
                fcb     1,123,-94,$00
                fcb     0,0
move_7
                fcb     1,56,-101,$00
                fcb     0,0
move_8
                fcb     1,45,-15,$00
                fcb     0,0
move_9
                fcb     1,106,-28,$00
                fcb     0,0
move_10
                fcb     1,94,124,$00
                fcb     0,0
move_11
                fcb     1,28,100,$00
                fcb     0,0
move_12
                fcb     1,94,109,$00
                fcb     0,0
move_13
                fcb     1,28,84,$00
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
trogg_z_data
                fcb     $00,$01,$F0,$1F,$E0,$1F,$84,$3E,$8F,$C0,$0F,$F1,$04,$3F,$0F,$F8
                fcb     $1F,$FF,$C0,$00,$ED,$0E,$C0,$92,$32,$C0,$68,$1E,$C8,$12,$6F,$10
                fcb     $18,$86,$68,$14,$21,$88,$11,$0C,$38,$18,$1F,$CC,$66,$00,$08,$10
                fcb     $00,$42,$5F,$00,$18,$0C,$01,$C6,$7F,$FF,$E0,$01,$83,$FE,$3E,$60
                fcb     $B0,$C0,$00,$0D,$08,$00,$00,$08,$88,$11,$98,$11,$CB,$B3,$CC,$00
                fcb     $00,$81,$04,$3F,$FF,$00,$00,$00
scrubbly_z_data
                fcb     $00,$07,$DF,$80,$00,$00,$07,$E7,$8C,$00,$00,$00,$0C,$36,$24,$2F
                fcb     $01,$98,$00,$00,$00,$39,$87,$68,$00,$00,$00,$00,$C6,$18,$00,$E3
                fcb     $80,$00,$00,$00,$03,$80,$E0,$00,$00,$00,$0E,$00,$38,$78,$00,$3C
                fcb     $00,$00,$00,$38,$00,$03,$87,$00,$00,$1C,$00,$00,$00,$00,$0F,$C0
                fcb     $00,$7E,$CC,$00,$01,$98,$03,$00,$00,$18,$30,$F8,$F8,$60,$00,$00
                fcb     $00,$00,$61,$8D,$8C,$30,$1C,$60,$A0,$C7,$70,$8D,$58,$87,$C1,$3E
                fcb     $F9,$06,$00,$00,$00,$00,$60,$4F,$BE,$40,$F4,$37,$8F,$61,$6B,$07
                fcb     $C1,$F0,$68,$1E,$00,$00,$00,$F0,$09,$00,$00,$00,$48,$12,$2E,$AA
                fcb     $E8,$90,$01,$18,$EB,$8C,$40,$06,$11,$01,$10,$C0,$06,$08,$80,$88
                fcb     $30,$0C,$1B,$01,$B0,$60,$0C,$05,$00,$50,$18,$1A,$0A,$00,$A0,$B0
                fcb     $0F,$07,$00,$70,$78,$1B,$04,$00,$41,$B0,$09,$82,$00,$20,$C8,$11
                fcb     $00,$00,$01,$10,$04,$C0,$00,$01,$90,$00,$C0,$00,$0E,$00,$00,$3F
                fcb     $00,$7E,$00,$00,$47,$FF,$C4,$00,$00,$00,$61,$83,$0C,$1F,$80,$FC
                fcb     $00,$00,$00,$00
poglet_z_data
                fcb     $00,$3F,$00,$38,$40,$00,$1C,$10,$0F,$CC,$26,$00,$00,$36,$00,$00
                fcb     $00,$12,$F8,$1E,$4C,$13,$71,$F8,$80,$00,$14,$42,$31,$98,$B0,$09
                fcb     $EF,$78,$02,$64,$90,$09,$2F,$40,$00,$24,$A5,$BD,$6C,$12,$42,$09
                fcb     $32,$00,$00,$79,$E6,$3C,$03,$50,$04,$01,$C0,$34,$1E,$40,$2F,$61
                fcb     $00,$93,$99,$03,$F2,$6D,$FF,$9B,$59,$CC,$F4,$76,$1E,$37,$8F,$08
                fcb     $E2,$7D,$FF,$9F,$00
hooter_z_data
                fcb     $70,$01,$C0,$00,$00,$35,$EF,$58,$19,$9C,$CC,$02,$EE,$80,$03,$77
                fcb     $60,$00,$1C,$E7,$1B,$DE,$C0,$00,$30,$50,$5A,$44,$90,$19,$22,$48
                fcb     $00,$00,$00,$13,$5D,$6C,$24,$C6,$48,$12,$41,$24,$28,$C6,$28,$1C
                fcb     $3E,$1C,$08,$00,$20,$04,$00,$10,$0C,$00,$60,$00,$0C,$01,$80,$00
                fcb     $1F,$FC,$00,$00,$18,$88,$C0,$0C,$8A,$26,$7F,$DF,$F0,$00,$00,$00
                fcb     $00
gem_z_data
                fcb     $3F,$80,$00,$06,$0C,$6F,$B0,$0C,$06,$30,$60,$03,$18,$0D,$80,$00
                fcb     $E0,$00,$00,$00
ladder_z_data
                fcb     $00,$90,$09,$00,$0F,$9F,$8F,$10,$0F,$9F,$09,$00,$00,$90,$09,$00
                fcb     $00,$02,$40,$3E,$7C,$23,$C4,$3E,$7C,$02,$40,$02,$40,$24,$00,$03
                fcb     $E7,$C0,$00,$23,$C4,$3E,$7C,$02,$40,$02,$40,$24,$00,$03,$E7,$C0
                fcb     $00,$23,$C4,$3E,$7C,$02,$40,$02,$40,$24,$00,$03,$E7,$C0,$00,$23
                fcb     $C4,$3E,$7C,$02,$40,$02,$40,$24,$00,$03,$E7,$C0,$00,$23,$C4,$3E
                fcb     $7C,$02,$40,$02,$40,$24,$00,$03,$E7,$C0,$00,$23,$C4,$3E,$7C,$02
                fcb     $40,$02,$40,$24,$00,$03,$E7,$C0,$00,$23,$C4,$3E,$7C,$02,$40,$02
                fcb     $40,$24,$00,$03,$E7,$C0,$00,$23,$C4,$3E,$7C,$02,$40,$02,$40,$24
                fcb     $00,$03,$E7,$C0,$00,$23,$C4,$3E,$7C,$02,$40,$02,$40
bulb_z_data
                fcb     $1E,$00,$3F,$01,$E0,$07,$84,$80,$03,$30,$08,$4C,$30,$18,$18,$10
                fcb     $08,$10,$08,$18,$18,$0C,$30,$07,$E0,$00,$00,$00
