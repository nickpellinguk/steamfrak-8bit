; made by vectrex/tools/m1_ledgel_gen.py: the test scene

draw_scene
; ledges: the 8-row strip
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7D82
                jsr     Moveto_d
                ldx     #move_s
                jsr     vlist_d
dc_0_start
                ldu     #rows_s
                lda     #16
                sta     $C880
                jsr     cave_n
dc_0_end
; ledges: the top line, then the lines, 5 a tile
                ldx     #move_t1
                jsr     vlist_d
dc_1_start
                ldu     #rows_t
                lda     #16
                sta     $C880
                jsr     cave_top
                ldx     #move_h1
                jsr     vlist_d
                jsr     hatch_5
dc_1_end
; ledges: the top line, then the lines, 4 a tile
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$3182
                jsr     Moveto_d
                ldx     #move_t2
                jsr     vlist_d
dc_2_start
                ldu     #rows_t
                lda     #16
                sta     $C880
                jsr     cave_top
                ldx     #move_h2
                jsr     vlist_d
                jsr     hatch_4
dc_2_end
                rts

move_s
                fcb     1,61,-14,$00
                fcb     0,0
move_t1
                fcb     22,-124,0,$00
                fcb     0,0
move_h1
                fcb     160,-4,-127,$00
                fcb     1,79,76,$00
                fcb     0,0
move_t2
                fcb     1,103,-14,$00
                fcb     0,0
move_h2
                fcb     159,-4,-127,$00
                fcb     1,75,13,$00
                fcb     0,0

rows_s
                fdb     row_s_0,row_s_1,row_s_2,row_s_3,row_s_4,row_s_5,row_s_6,row_s_7
row_s_0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D
row_s_1
                fcb     $4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D,$4D,$1D
row_s_2
                fcb     $0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E,$0F,$3E
row_s_3
                fcb     $D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF,$D7,$DF
row_s_4
                fcb     $6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A,$6B,$2A
row_s_5
                fcb     $34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8,$34,$A8
row_s_6
                fcb     $0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28,$0D,$28
row_s_7
                fcb     $09,$50,$09,$50,$09,$50,$09,$50,$09,$50,$09,$50,$09,$50,$09,$50
rows_t
                fdb     row_t_0
row_t_0
                fcb     $6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D,$6F,$4D
