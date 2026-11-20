; made by vectrex/tools/m1_cave_gen.py: the test scene

draw_scene
; ledges at (-100, -90), 64 pixels: rows [0, 1]
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7082
                jsr     Moveto_d
                ldx     #move_c0
                jsr     vlist_d
dc_0_start
                ldu     #rows_0
                lda     #8
                sta     $C880
                jsr     cave_2
dc_0_end
; ledges at (-100, -40), 128 pixels: rows [0, 1]
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$3182
                jsr     Moveto_d
                ldx     #move_c1
                jsr     vlist_d
dc_1_start
                ldu     #rows_1
                lda     #16
                sta     $C880
                jsr     cave_2
dc_1_end
; ledges at (-103, 20), 206 pixels: rows [0, 1]
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$E781
                jsr     Moveto_d
                ldx     #move_c2
                jsr     vlist_d
dc_2_start
                ldu     #rows_2
                lda     #26
                sta     $C880
                jsr     cave_2
dc_2_end
; ledges at (-100, -70), 64 pixels: rows [0, 1, 4, 5, 7, 9, 11, 13]
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$5782
                jsr     Moveto_d
                ldx     #move_c3
                jsr     vlist_d
dc_3_start
                ldu     #rows_3
                lda     #8
                sta     $C880
                jsr     cave_n
dc_3_end
; ledges at (-100, -10), 128 pixels: rows [0, 1, 4, 5, 7, 9, 11, 13]
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$0B82
                jsr     Moveto_d
                ldx     #move_c4
                jsr     vlist_d
dc_4_start
                ldu     #rows_4
                lda     #16
                sta     $C880
                jsr     cave_n
dc_4_end
; ledges at (-103, 60), 206 pixels: rows [0, 1, 4, 5, 7, 9, 11, 13]
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$B481
                jsr     Moveto_d
                ldx     #move_c5
                jsr     vlist_d
dc_5_start
                ldu     #rows_5
                lda     #26
                sta     $C880
                jsr     cave_n
dc_5_end
                rts

move_c0
                fcb     1,110,-14,$00
                fcb     0,0
move_c1
                fcb     1,103,-14,$00
                fcb     0,0
move_c2
                fcb     3,-36,-122,$00
                fcb     0,0
move_c3
                fcb     1,82,-14,$00
                fcb     0,0
move_c4
                fcb     1,124,-14,$00
                fcb     0,0
move_c5
                fcb     3,-12,-122,$00
                fcb     0,0

rows_0
                fdb     row_0_0,row_0_1
row_0_0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D
row_0_1
                fcb     $B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2
rows_1
                fdb     row_1_0,row_1_1
row_1_0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D
row_1_1
                fcb     $B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2
rows_2
                fdb     row_2_0,row_2_1
row_2_0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4C
row_2_1
                fcb     $32,$E2,$B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2
                fcb     $B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2,$B2,$E2
rows_3
                fdb     row_3_0,row_3_1,row_3_2,row_3_3,row_3_4,row_3_5,row_3_6,row_3_7
row_3_0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D
row_3_1
                fcb     $4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D
row_3_2
                fcb     $0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E
row_3_3
                fcb     $D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF
row_3_4
                fcb     $6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A
row_3_5
                fcb     $34,$A8,$34,$A8,$34,$A8,$34,$A8
row_3_6
                fcb     $0D,$28,$0D,$28,$0D,$28,$0D,$28
row_3_7
                fcb     $09,$50,$09,$50,$09,$50,$09,$50
rows_4
                fdb     row_4_0,row_4_1,row_4_2,row_4_3,row_4_4,row_4_5,row_4_6,row_4_7
row_4_0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D
row_4_1
                fcb     $4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D
row_4_2
                fcb     $0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E
row_4_3
                fcb     $D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF
row_4_4
                fcb     $6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A
row_4_5
                fcb     $34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8
row_4_6
                fcb     $0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28
row_4_7
                fcb     $09,$50,$09,$50,$09,$50,$09,$50,$09,$50,$09,$50,$09,$50,$09,$50
rows_5
                fdb     row_5_0,row_5_1,row_5_2,row_5_3,row_5_4,row_5_5,row_5_6,row_5_7
row_5_0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4C
row_5_1
                fcb     $0D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D
                fcb     $4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D
row_5_2
                fcb     $0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E
                fcb     $0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3C
row_5_3
                fcb     $17,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF
                fcb     $D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF
row_5_4
                fcb     $6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A
                fcb     $6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$28
row_5_5
                fcb     $34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8
                fcb     $34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8
row_5_6
                fcb     $0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28
                fcb     $0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28
row_5_7
                fcb     $09,$50,$09,$50,$09,$50,$09,$50,$09,$50,$09,$50,$09,$50,$09,$50
                fcb     $09,$50,$09,$50,$09,$50,$09,$50,$09,$50
