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
; trogg_h at (-72, -100), half resolution: columns 0-12 of 13, 5 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7FA4
                jsr     Moveto_d
                ldx     #move_1
                jsr     vlist_d
                ldx     #trogg_h_data+0
                lda     #14
                sta     $C880
                jsr     col5h_down
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
; scrubbly_h at (-9, -108), half resolution: columns 0-16 of 17, 6 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7FF4
                jsr     Moveto_d
                ldx     #move_3
                jsr     vlist_d
                ldx     #scrubbly_h_data+0
                lda     #18
                sta     $C880
                jsr     col6h_down
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
; ladder_h at (58, -100), half resolution: columns 0-5 of 6, 10 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7F47
                jsr     Moveto_d
                ldx     #move_5
                jsr     vlist_d
                ldx     #ladder_h_data+0
                lda     #7
                sta     $C880
                jsr     col10h_down
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
; chain_h at (84, -100), half resolution: columns 0-3 of 4, 10 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7F68
                jsr     Moveto_d
                ldx     #move_7
                jsr     vlist_d
                ldx     #chain_h_data+0
                lda     #5
                sta     $C880
                jsr     col10h_down
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
; trogg_climb_h at (-78, -50), half resolution: columns 0-9 of 10, 5 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$419D
                jsr     Moveto_d
                ldx     #move_9
                jsr     vlist_d
                ldx     #trogg_climb_h_data+0
                lda     #11
                sta     $C880
                jsr     col5h_down
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
; poglet_h at (-31, -49), half resolution: columns 0-11 of 12, 5 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$40D8
                jsr     Moveto_d
                ldx     #move_11
                jsr     vlist_d
                ldx     #poglet_h_data+0
                lda     #13
                sta     $C880
                jsr     col5h_down
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
; hooter_h at (15, -39), half resolution: columns 0-9 of 10, 4 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$3311
                jsr     Moveto_d
                ldx     #move_13
                jsr     vlist_d
                ldx     #hooter_h_data+0
                lda     #11
                sta     $C880
                jsr     col4h_down
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
; gem_h at (-87, 0), half resolution: columns 0-5 of 6, 2 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$0292
                jsr     Moveto_d
                ldx     #move_15
                jsr     vlist_d
                ldx     #gem_h_data+0
                lda     #7
                sta     $C880
                jsr     col2h_down
; balloon at (-74, 0): columns 0-11 of 12, 2 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$02A3
                jsr     Moveto_d
                ldx     #move_16
                jsr     vlist_d
                ldx     #balloon_data+0
                lda     #13
                sta     $C880
                jsr     col2_down
; balloon_h at (-60, 0), half resolution: columns 0-5 of 6, 2 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$02B4
                jsr     Moveto_d
                ldx     #move_17
                jsr     vlist_d
                ldx     #balloon_h_data+0
                lda     #7
                sta     $C880
                jsr     col2h_down
; dagger at (-46, 0): columns 0-10 of 11, 2 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$02C6
                jsr     Moveto_d
                ldx     #move_18
                jsr     vlist_d
                ldx     #dagger_data+0
                lda     #12
                sta     $C880
                jsr     col2_down
; dagger_h at (-33, 0), half resolution: columns 0-5 of 6, 2 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$02D6
                jsr     Moveto_d
                ldx     #move_19
                jsr     vlist_d
                ldx     #dagger_h_data+0
                lda     #7
                sta     $C880
                jsr     col2h_down
; key at (-18, 0): 10 drifting rows of 3 bytes
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$00EA
                jsr     Moveto_d
                ldx     #move_20
                jsr     vlist_d
                ldx     #key_data
                jsr     rows3_10
; key_h at (6, 2): 5 drifting rows of 3 bytes
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$FE07
                jsr     Moveto_d
                ldx     #move_21
                jsr     vlist_d
                ldx     #key_h_data
                jsr     rows3_5h
; yoyo at (32, 0): 6 drifting rows of 1 bytes
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$0028
                jsr     Moveto_d
                ldx     #move_22
                jsr     vlist_d
                ldx     #yoyo_data
                jsr     rows1_6
; yoyo_h at (42, 1): 3 drifting rows of 1 bytes
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$FF34
                jsr     Moveto_d
                ldx     #move_23
                jsr     vlist_d
                ldx     #yoyo_h_data
                jsr     rows1_3h
; scrubbly_h at (-112, 54), half resolution: columns 5-16 of 17, 6 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$8281
                jsr     Moveto_d
                ldx     #move_24
                jsr     vlist_d
                ldx     #scrubbly_h_data+30
                lda     #13
                sta     $C880
                jsr     col6h_up
; poglet_h at (94, 60), half resolution: columns 0-3 of 12, 5 bytes each
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$B775
                jsr     Moveto_d
                ldx     #move_25
                jsr     vlist_d
                ldx     #poglet_h_data+0
                lda     #5
                sta     $C880
                jsr     col5h_down
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
; ledges at (-120, 40), half resolution: one row, bytes 2-27
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$CD81
                jsr     Moveto_d
                ldx     #move_ledges_h
                jsr     vlist_d
                ldx     #ledges_row0+2
                ldb     #26
                jsr     strip1
                rts

move_0
                fcb     2,103,-47,$00
                fcb     0,0
move_1
                fcb     2,103,-4,$00
                fcb     0,0
move_2
                fcb     12,124,-1,$00
                fcb     0,0
move_3
                fcb     12,124,-6,$00
                fcb     0,0
move_4
                fcb     2,103,54,$00
                fcb     0,0
move_5
                fcb     2,103,56,$00
                fcb     0,0
move_6
                fcb     2,103,11,$00
                fcb     0,0
move_7
                fcb     2,103,42,$00
                fcb     0,0
move_8
                fcb     1,73,-94,$00
                fcb     0,0
move_9
                fcb     1,73,-79,$00
                fcb     0,0
move_10
                fcb     0,0
move_11
                fcb     1,40,-45,$00
                fcb     0,0
move_12
                fcb     1,89,-25,$00
                fcb     0,0
move_13
                fcb     1,89,83,$00
                fcb     0,0
move_14
                fcb     1,66,-94,$00
                fcb     0,0
move_15
                fcb     1,66,-124,$00
                fcb     0,0
move_16
                fcb     1,66,-121,$00
                fcb     0,0
move_17
                fcb     1,66,-118,$00
                fcb     0,0
move_18
                fcb     1,66,-81,$00
                fcb     0,0
move_19
                fcb     1,66,-111,$00
                fcb     0,0
move_20
                fcb     1,0,-89,$00
                fcb     0,0
move_21
                fcb     1,-66,72,$00
                fcb     0,0
move_22
                fcb     1,0,45,$00
                fcb     0,0
move_23
                fcb     1,-33,123,$00
                fcb     0,0
move_24
                fcb     3,-5,-122,$00
                fcb     0,0
move_25
                fcb     0,0
move_ledges
                fcb     5,-12,-105,$00
                fcb     0,0
move_ledges_h
                fcb     5,-2,-105,$00
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
trogg_h_data                                  ; 13 columns of 5 bytes
                fcb     $00,$00,$1F,$F0,$00
                fcb     $00,$0F,$4F,$F0,$00
                fcb     $00,$38,$3F,$F0,$00
                fcb     $0F,$87,$C7,$C6,$80
                fcb     $03,$C2,$20,$FF,$10
                fcb     $0B,$B2,$06,$63,$F0
                fcb     $1F,$FF,$C0,$43,$F0
                fcb     $08,$1F,$00,$3F,$FC
                fcb     $38,$E7,$C1,$8F,$D0
                fcb     $0F,$00,$FF,$FD,$6C
                fcb     $1D,$C0,$00,$00,$00
                fcb     $00,$00,$00,$00,$A0
                fcb     $07,$00,$00,$00,$00
trogg_climb_h_data                                  ; 10 columns of 5 bytes
                fcb     $00,$FC,$00,$00,$00
                fcb     $00,$07,$FF,$E3,$E0
                fcb     $07,$C0,$C1,$3F,$C0
                fcb     $02,$F8,$81,$07,$FC
                fcb     $3F,$F3,$81,$F1,$C0
                fcb     $0F,$FE,$00,$7F,$FC
                fcb     $3F,$E7,$C0,$40,$50
                fcb     $0F,$FF,$8E,$BF,$E0
                fcb     $01,$A7,$FF,$00,$00
                fcb     $00,$00,$00,$3F,$00
scrubbly_h_data                                  ; 17 columns of 6 bytes
                fcb     $00,$00,$0F,$F3,$FE,$00
                fcb     $00,$1E,$FF,$BC,$C0,$00
                fcb     $00,$0E,$F0,$00,$1F,$00
                fcb     $0F,$80,$18,$01,$F8,$E0
                fcb     $1F,$32,$3F,$9F,$E0,$90
                fcb     $0B,$1F,$89,$E6,$06,$68
                fcb     $37,$C0,$4F,$9F,$00,$70
                fcb     $02,$00,$18,$FE,$01,$DC
                fcb     $38,$00,$3E,$18,$00,$40
                fcb     $06,$00,$19,$F6,$01,$DC
                fcb     $36,$C0,$4F,$9F,$E0,$F0
                fcb     $0B,$1F,$89,$8E,$0E,$74
                fcb     $3E,$3B,$1F,$1F,$00,$B0
                fcb     $07,$C0,$00,$03,$F8,$00
                fcb     $00,$07,$79,$FC,$7E,$00
                fcb     $00,$4F,$E3,$F8,$80,$00
                fcb     $00,$00,$03,$F0,$FC,$00
poglet_h_data                                  ; 12 columns of 5 bytes
                fcb     $00,$00,$00,$3F,$E0
                fcb     $05,$F4,$7F,$F8,$00
                fcb     $01,$FF,$F3,$6B,$E0
                fcb     $06,$FF,$F8,$C2,$F0
                fcb     $1B,$FF,$FA,$07,$20
                fcb     $07,$C0,$6F,$E8,$6C
                fcb     $24,$17,$F6,$03,$A0
                fcb     $06,$FE,$5F,$FE,$3C
                fcb     $00,$43,$03,$C0,$C0
                fcb     $07,$FF,$00,$7E,$00
                fcb     $00,$00,$00,$33,$A0
                fcb     $07,$78,$00,$00,$00
hooter_h_data                                  ; 10 columns of 4 bytes
                fcb     $38,$7F,$81,$80
                fcb     $01,$5F,$F3,$CC
                fcb     $1F,$B8,$0D,$80
                fcb     $01,$61,$FD,$68
                fcb     $1F,$C8,$85,$80
                fcb     $01,$E1,$BF,$F8
                fcb     $1F,$8F,$04,$80
                fcb     $01,$F8,$7D,$FC
                fcb     $38,$F9,$F3,$80
                fcb     $01,$81,$F0,$18
gem_h_data                                  ; 6 columns of 2 bytes
                fcb     $1E,$00
                fcb     $01,$DC
                fcb     $28,$E0
                fcb     $03,$94
                fcb     $3F,$00
                fcb     $00,$30
balloon_h_data                                  ; 6 columns of 2 bytes
                fcb     $1F,$C0
                fcb     $06,$0C
                fcb     $20,$30
                fcb     $0C,$04
                fcb     $30,$60
                fcb     $03,$F8
dagger_h_data                                  ; 6 columns of 2 bytes
                fcb     $00,$38
                fcb     $0F,$88
                fcb     $1E,$40
                fcb     $01,$F0
                fcb     $3D,$C0
                fcb     $00,$10
bulb_h_data                                  ; 5 columns of 3 bytes
                fcb     $00,$7F,$00
                fcb     $01,$83,$FC
                fcb     $3C,$00,$80
                fcb     $01,$83,$FC
                fcb     $00,$7F,$00
ladder_h_data                                  ; 6 columns of 10 bytes
                fcb     $0E,$1C,$38,$70,$E1,$C3,$87,$0E,$1C,$00
                fcb     $00,$28,$50,$A1,$42,$85,$0A,$14,$28,$50
                fcb     $3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
                fcb     $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FC
                fcb     $0A,$14,$28,$50,$A1,$42,$85,$0A,$14,$00
                fcb     $00,$38,$70,$E1,$C3,$87,$0E,$1C,$38,$70
chain_h_data                                  ; 4 columns of 10 bytes
                fcb     $3C,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FC
                fcb     $2F,$F7,$BF,$DE,$FF,$7B,$FD,$EF,$F7,$E4
                fcb     $27,$77,$DF,$EF,$7F,$BD,$FE,$F7,$FB,$F4
                fcb     $3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$BC
key_h_data                                  ; 5 rows of 3 bytes
                fcb     $00,$01,$F8
                fcb     $3C,$FF,$FF
                fcb     $FF,$FE,$34
                fcb     $39,$C0,$42
                fcb     $7E,$00,$F0
yoyo_h_data                                  ; 3 rows of 1 bytes
                fcb     $FE
                fcb     $5F
                fcb     $FE
ledges_row0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$00,$00,$6F,$4D,$6F,$4D,$6F,$4D
                fcb     $00,$00,$6F,$4D,$6F,$4D,$6F,$4D,$00,$00,$6F,$4D,$6F,$4D
ledges_row1                             ; (reversed: swept to the left)
                fcb     $B2,$E2,$B2,$E2,$00,$00,$B2,$E2,$B2,$E2,$B2,$E2,$00,$00,$B2,$E2
                fcb     $B2,$E2,$B2,$E2,$00,$00,$B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2
