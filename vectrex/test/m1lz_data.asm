; made by vectrex/tools/m1_ledgez_gen.py: the test scene

draw_scene
; ledges: the 8-row strip
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$7F82
                jsr     Moveto_d
                ldx     #move_s
                jsr     vlist_d
dc_0_start
                ldu     #rows_s
                lda     #16
                sta     $C880
                jsr     cave_n
dc_0_end
; ledges: the top line, then each block as a zigzag, drift 2
                ldx     #move_t1
                jsr     vlist_d
dc_1_start
                ldu     #rows_t
                lda     #16
                sta     $C880
                jsr     cave_top
                ldx     #move_b1_0
                jsr     vlist_d
                ldx     #blk_2
                jsr     zig_blk_2
                ldx     #move_b1_1
                jsr     vlist_d
                ldx     #blk_2
                jsr     zig_blk_2
                ldx     #move_b1_2
                jsr     vlist_d
                ldx     #blk_2
                jsr     zig_blk_2
                ldx     #move_b1_3
                jsr     vlist_d
                ldx     #blk_2
                jsr     zig_blk_2
                ldx     #move_b1_4
                jsr     vlist_d
                ldx     #blk_2
                jsr     zig_blk_2
                ldx     #move_b1_5
                jsr     vlist_d
                ldx     #blk_2
                jsr     zig_blk_2
                ldx     #move_b1_6
                jsr     vlist_d
                ldx     #blk_2
                jsr     zig_blk_2
                ldx     #move_b1_7
                jsr     vlist_d
                ldx     #blk_2
                jsr     zig_blk_2
dc_1_end
; ledges: the top line, then each block as a zigzag, drift 3
                ldx     #move_t2
                jsr     vlist_d
dc_2_start
                ldu     #rows_t
                lda     #16
                sta     $C880
                jsr     cave_top
                ldx     #move_b2_0
                jsr     vlist_d
                ldx     #blk_3
                jsr     zig_blk_3
                ldx     #move_b2_1
                jsr     vlist_d
                ldx     #blk_3
                jsr     zig_blk_3
                ldx     #move_b2_2
                jsr     vlist_d
                ldx     #blk_3
                jsr     zig_blk_3
                ldx     #move_b2_3
                jsr     vlist_d
                ldx     #blk_3
                jsr     zig_blk_3
                ldx     #move_b2_4
                jsr     vlist_d
                ldx     #blk_3
                jsr     zig_blk_3
                ldx     #move_b2_5
                jsr     vlist_d
                ldx     #blk_3
                jsr     zig_blk_3
                ldx     #move_b2_6
                jsr     vlist_d
                ldx     #blk_3
                jsr     zig_blk_3
                ldx     #move_b2_7
                jsr     vlist_d
                ldx     #blk_3
                jsr     zig_blk_3
dc_2_end
; ledges: the top line, then each block as a zigzag, drift 4
                ldx     #move_t3
                jsr     vlist_d
dc_3_start
                ldu     #rows_t
                lda     #16
                sta     $C880
                jsr     cave_top
                ldx     #move_b3_0
                jsr     vlist_d
                ldx     #blk_4
                jsr     zig_blk_4
                ldx     #move_b3_1
                jsr     vlist_d
                ldx     #blk_4
                jsr     zig_blk_4
                ldx     #move_b3_2
                jsr     vlist_d
                ldx     #blk_4
                jsr     zig_blk_4
                ldx     #move_b3_3
                jsr     vlist_d
                ldx     #blk_4
                jsr     zig_blk_4
                ldx     #move_b3_4
                jsr     vlist_d
                ldx     #blk_4
                jsr     zig_blk_4
                ldx     #move_b3_5
                jsr     vlist_d
                ldx     #blk_4
                jsr     zig_blk_4
                ldx     #move_b3_6
                jsr     vlist_d
                ldx     #blk_4
                jsr     zig_blk_4
                ldx     #move_b3_7
                jsr     vlist_d
                ldx     #blk_4
                jsr     zig_blk_4
dc_3_end
; ledges: the top line, then each block as a zigzag, drift 5
                ldx     #move_t4
                jsr     vlist_d
dc_4_start
                ldu     #rows_t
                lda     #16
                sta     $C880
                jsr     cave_top
                ldx     #move_b4_0
                jsr     vlist_d
                ldx     #blk_5
                jsr     zig_blk_5
                ldx     #move_b4_1
                jsr     vlist_d
                ldx     #blk_5
                jsr     zig_blk_5
                ldx     #move_b4_2
                jsr     vlist_d
                ldx     #blk_5
                jsr     zig_blk_5
                ldx     #move_b4_3
                jsr     vlist_d
                ldx     #blk_5
                jsr     zig_blk_5
                ldx     #move_b4_4
                jsr     vlist_d
                ldx     #blk_5
                jsr     zig_blk_5
                ldx     #move_b4_5
                jsr     vlist_d
                ldx     #blk_5
                jsr     zig_blk_5
                ldx     #move_b4_6
                jsr     vlist_d
                ldx     #blk_5
                jsr     zig_blk_5
                ldx     #move_b4_7
                jsr     vlist_d
                ldx     #blk_5
                jsr     zig_blk_5
dc_4_end
                rts

move_s
                fcb     4,112,-3,$00
                fcb     0,0
move_t1
                fcb     19,-126,0,$00
                fcb     0,0
move_b1_0
                fcb     162,-3,-127,$00
                fcb     1,-75,74,$00
                fcb     0,0
move_b1_1
                fcb     26,64,108,$00
                fcb     0,0
move_b1_2
                fcb     26,64,108,$00
                fcb     0,0
move_b1_3
                fcb     26,64,108,$00
                fcb     0,0
move_b1_4
                fcb     26,64,108,$00
                fcb     0,0
move_b1_5
                fcb     26,64,108,$00
                fcb     0,0
move_b1_6
                fcb     26,64,108,$00
                fcb     0,0
move_b1_7
                fcb     26,64,108,$00
                fcb     0,0
move_t2
                fcb     140,-16,-126,$00
                fcb     1,-14,-58,$00
                fcb     0,0
move_b2_0
                fcb     162,-3,-127,$00
                fcb     1,-75,74,$00
                fcb     0,0
move_b2_1
                fcb     13,126,-18,$00
                fcb     0,0
move_b2_2
                fcb     13,126,-18,$00
                fcb     0,0
move_b2_3
                fcb     13,126,-18,$00
                fcb     0,0
move_b2_4
                fcb     13,126,-18,$00
                fcb     0,0
move_b2_5
                fcb     13,126,-18,$00
                fcb     0,0
move_b2_6
                fcb     13,126,-18,$00
                fcb     0,0
move_b2_7
                fcb     13,126,-18,$00
                fcb     0,0
move_t3
                fcb     164,-14,-126,$00
                fcb     1,13,-74,$00
                fcb     0,0
move_b3_0
                fcb     162,-3,-127,$00
                fcb     1,-75,74,$00
                fcb     0,0
move_b3_1
                fcb     14,120,-17,$00
                fcb     0,0
move_b3_2
                fcb     14,120,-17,$00
                fcb     0,0
move_b3_3
                fcb     14,120,-17,$00
                fcb     0,0
move_b3_4
                fcb     14,120,-17,$00
                fcb     0,0
move_b3_5
                fcb     14,120,-17,$00
                fcb     0,0
move_b3_6
                fcb     14,120,-17,$00
                fcb     0,0
move_b3_7
                fcb     14,120,-17,$00
                fcb     0,0
move_t4
                fcb     164,-14,-126,$00
                fcb     1,48,-74,$00
                fcb     0,0
move_b4_0
                fcb     162,-3,-127,$00
                fcb     1,-75,74,$00
                fcb     0,0
move_b4_1
                fcb     14,127,-17,$00
                fcb     0,0
move_b4_2
                fcb     14,127,-17,$00
                fcb     0,0
move_b4_3
                fcb     14,127,-17,$00
                fcb     0,0
move_b4_4
                fcb     14,127,-17,$00
                fcb     0,0
move_b4_5
                fcb     14,127,-17,$00
                fcb     0,0
move_b4_6
                fcb     14,127,-17,$00
                fcb     0,0
move_b4_7
                fcb     14,127,-17,$00
                fcb     0,0

blk_2
                fcb     $00,$00,$7C,$F0,$00,$00,$D7,$DF,$00,$00,$00,$00,$B4,$D5,$00,$00
                fcb     $6B,$2A,$00,$00,$00,$00,$2B,$5C,$00,$00,$34,$A8,$00,$00,$00,$00
                fcb     $1A,$D8,$00,$00,$0D,$28,$00,$00,$00,$00,$0B,$90,$00,$00,$09,$50
                fcb     $00,$00,$00,$00,$00
blk_3
                fcb     $0F,$3E,$00,$00,$FB,$EB,$00,$00,$B4,$D5,$54,$D6,$00,$00,$2B,$5C
                fcb     $00,$00,$34,$A8,$1A,$D8,$00,$00,$0D,$28,$00,$00,$09,$D0,$09,$50
                fcb     $00,$00,$00
blk_4
                fcb     $0F,$3E,$D7,$DF,$00,$00,$AB,$2D,$6B,$2A,$2B,$5C,$15,$2C,$00,$00
                fcb     $1A,$D8,$14,$B0,$09,$D0,$09,$50,$00,$00,$00
blk_5
                fcb     $0F,$3E,$D7,$DF,$B4,$D5,$54,$D6,$3A,$D4,$34,$A8,$1A,$D8,$14,$B0
                fcb     $09,$D0,$09,$50,$00,$00,$00
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
