; made by vectrex/tools/m1_cavez_gen.py: the test scene

draw_scene
; ledges at (-100, -100), 64 pixels: 8 rows
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7D82
                jsr     Moveto_d
                ldx     #move_s0
                jsr     vlist_d
dc_0_start
                ldu     #rows_0
                lda     #8
                sta     $C880
                jsr     cave_n
dc_0_end
; ledges at (-100, -70), 128 pixels: 8 rows
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$5782
                jsr     Moveto_d
                ldx     #move_s1
                jsr     vlist_d
dc_1_start
                ldu     #rows_1
                lda     #16
                sta     $C880
                jsr     cave_n
dc_1_end
; ledges at (-104, -26), 208 pixels: 8 rows
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$2081
                jsr     Moveto_d
                ldx     #move_s2
                jsr     vlist_d
dc_2_start
                ldu     #rows_2
                lda     #26
                sta     $C880
                jsr     cave_n
dc_2_end
; ledges at (-100, -10), 64 pixels: zigzag bands
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$0C82
                jsr     Moveto_d
                ldx     #move_z3
                jsr     vlist_d
dc_3_start
                lda     #$18
                sta     <VIA_aux_cntl
                jsr     band_3_0
                lda     #$98
                sta     <VIA_aux_cntl
dc_3_end
; ledges at (-100, 20), 128 pixels: zigzag bands
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$E782
                jsr     Moveto_d
                ldx     #move_z4
                jsr     vlist_d
dc_4_start
                lda     #$18
                sta     <VIA_aux_cntl
                jsr     band_4_0
                jsr     band_4_1
                lda     #$98
                sta     <VIA_aux_cntl
dc_4_end
; ledges at (-104, 50), 208 pixels: zigzag bands
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$C181
                jsr     Moveto_d
                ldx     #move_z5
                jsr     vlist_d
dc_5_start
                lda     #$18
                sta     <VIA_aux_cntl
                jsr     band_5_0
                jsr     band_5_1
                jsr     band_5_2
                jsr     band_5_3
                lda     #$98
                sta     <VIA_aux_cntl
dc_5_end
; the ladder at (60, -100): columns
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7F4B
                jsr     Moveto_d
                ldx     #move_l6
                jsr     vlist_d
dc_6_start
                ldx     #ladder_cols
                lda     #13
                sta     $C880
                jsr     col10_down
dc_6_end
; the ladder at (80, -100): zigzag, rows 16 pixels
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7E62
                jsr     Moveto_d
                ldx     #move_l7
                jsr     vlist_d
dc_7_start
                ldx     #ladder_z
                jsr     zig_ladder
dc_7_end
                rts

move_s0
                fcb     1,61,-14,$00
                fcb     0,0
move_s1
                fcb     1,82,-14,$00
                fcb     0,0
move_s2
                fcb     5,4,-105,$00
                fcb     0,0
move_z3
                fcb     1,78,-14,$00
                fcb     0,0
move_z4
                fcb     0,0
move_z5
                fcb     5,-1,-105,$00
                fcb     0,0
move_l6
                fcb     2,103,2,$00
                fcb     0,0
move_l7
                fcb     1,14,46,$00
                fcb     0,0

rows_0
                fdb     row_0_0,row_0_1,row_0_2,row_0_3,row_0_4,row_0_5,row_0_6,row_0_7
row_0_0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D
row_0_1
                fcb     $4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D
row_0_2
                fcb     $0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E
row_0_3
                fcb     $D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF
row_0_4
                fcb     $6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A
row_0_5
                fcb     $34,$A8,$34,$A8,$34,$A8,$34,$A8
row_0_6
                fcb     $0D,$28,$0D,$28,$0D,$28,$0D,$28
row_0_7
                fcb     $09,$50,$09,$50,$09,$50,$09,$50
rows_1
                fdb     row_1_0,row_1_1,row_1_2,row_1_3,row_1_4,row_1_5,row_1_6,row_1_7
row_1_0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D
row_1_1
                fcb     $4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D
row_1_2
                fcb     $0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E
row_1_3
                fcb     $D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF
row_1_4
                fcb     $6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A
row_1_5
                fcb     $34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8
row_1_6
                fcb     $0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28
row_1_7
                fcb     $09,$50,$09,$50,$09,$50,$09,$50,$09,$50,$09,$50,$09,$50,$09,$50
rows_2
                fdb     row_2_0,row_2_1,row_2_2,row_2_3,row_2_4,row_2_5,row_2_6,row_2_7
row_2_0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D
row_2_1
                fcb     $4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D
                fcb     $4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D
row_2_2
                fcb     $0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E
                fcb     $0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E
row_2_3
                fcb     $D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF
                fcb     $D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF
row_2_4
                fcb     $6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A
                fcb     $6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A
row_2_5
                fcb     $34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8
                fcb     $34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8
row_2_6
                fcb     $0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28
                fcb     $0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28
row_2_7
                fcb     $09,$50,$09,$50,$09,$50,$09,$50,$09,$50,$09,$50,$09,$50,$09,$50
                fcb     $09,$50,$09,$50,$09,$50,$09,$50,$09,$50
band_3_0_d
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00
                fcb     $0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3F,$FC,$3F,$FC,$3F,$FC,$3F,$FC
                fcb     $1A,$D8,$1A,$D8,$1A,$D8,$1A,$D8,$1F,$B0,$1F,$B0,$1F,$B0,$1F,$B0
                fcb     $0A,$90,$0A,$90,$0A,$90,$0A,$90,$00
band_4_0_d
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00
                fcb     $0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3F,$FC,$3F,$FC,$3F,$FC,$3F,$FC
                fcb     $1A,$D8,$1A,$D8,$1A,$D8,$1A,$D8,$1F,$B0,$1F,$B0,$1F,$B0,$1F,$B0
                fcb     $0A,$90,$0A,$90,$0A,$90,$0A,$90,$00
band_4_1_d
                fcb     $15,$20,$15,$20,$15,$20,$15,$20,$0F,$D8,$0F,$D8,$0F,$D8,$0F,$D8
                fcb     $35,$B0,$35,$B0,$35,$B0,$35,$B0,$1F,$FE,$1F,$FE,$1F,$FE,$1F,$FE
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$6B,$EF,$EB,$EF,$EB,$EF,$EB,$EF
                fcb     $1E,$7C,$1E,$7C,$1E,$7C,$1E,$7C,$00,$00,$00,$00,$00,$00,$00,$00
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$00,$00,$00,$00,$00,$00,$00,$00
                fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00
band_5_0_d
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00
                fcb     $0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3F,$FC,$3F,$FC,$3F,$FC,$3F,$FC
                fcb     $1A,$D8,$1A,$D8,$1A,$D8,$1A,$D8,$1F,$B0,$1F,$B0,$1F,$B0,$1F,$B0
                fcb     $0A,$90,$0A,$90,$0A,$90,$0A,$90,$00
band_5_1_d
                fcb     $15,$20,$15,$20,$15,$20,$15,$20,$0F,$D8,$0F,$D8,$0F,$D8,$0F,$D8
                fcb     $35,$B0,$35,$B0,$35,$B0,$35,$B0,$1F,$FE,$1F,$FE,$1F,$FE,$1F,$FE
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$EB,$EF,$EB,$EF,$EB,$EF,$EB,$EF
                fcb     $1E,$7C,$1E,$7C,$1E,$7C,$1E,$7C,$00,$00,$00,$00,$00,$00,$00,$00
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00
                fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00
band_5_2_d
                fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00
                fcb     $79,$F0,$79,$F0,$79,$F0,$79,$F0,$FA,$FB,$FA,$FB,$FA,$FB,$FA,$FB
                fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$87,$FF,$87,$FF,$87,$FF,$87,$FF
                fcb     $D6,$C0,$D6,$C0,$D6,$C0,$D6,$C0,$03,$F6,$03,$F6,$03,$F6,$03,$F6
                fcb     $54,$80,$54,$80,$54,$80,$54,$80,$00
band_5_3_d
                fcb     $A9,$00,$01,$FB,$AD,$80,$03,$FF,$FF,$F0,$0D,$7D,$F3,$E0,$00,$00
                fcb     $FF,$F0,$00,$00,$00,$00,$00
ladder_cols
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
ladder_z
                fcb     $02,$40,$02,$40,$3E,$7C,$23,$C4,$3E,$7C,$02,$40,$02,$40,$02,$40
                fcb     $02,$40,$3E,$7C,$23,$C4,$3E,$7C,$02,$40,$02,$40,$02,$40,$02,$40
                fcb     $3E,$7C,$23,$C4,$3E,$7C,$02,$40,$02,$40,$02,$40,$02,$40,$3E,$7C
                fcb     $23,$C4,$3E,$7C,$02,$40,$02,$40,$02,$40,$02,$40,$3E,$7C,$23,$C4
                fcb     $3E,$7C,$02,$40,$02,$40,$02,$40,$02,$40,$3E,$7C,$23,$C4,$3E,$7C
                fcb     $02,$40,$02,$40,$02,$40,$02,$40,$3E,$7C,$23,$C4,$3E,$7C,$02,$40
                fcb     $02,$40,$02,$40,$02,$40,$3E,$7C,$23,$C4,$3E,$7C,$02,$40,$02,$40
                fcb     $02,$40,$02,$40,$3E,$7C,$23,$C4,$3E,$7C,$02,$40,$02,$40,$02,$40
                fcb     $02,$40,$3E,$7C,$23,$C4,$3E,$7C,$02,$40,$02,$40,$00,$00,$00
