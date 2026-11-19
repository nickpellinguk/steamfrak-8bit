; made by vectrex/tools/dagger.py

draw_daggers
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$088E
                jsr     Moveto_d
                ldx     #move_raster
                jsr     vlist_d
dg_raster_start
                ldx     #dagger_data
                lda     #12
                sta     $C880
                jsr     col2_down
dg_raster_end
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$00D7
                jsr     Moveto_d
                ldx     #move_right
                jsr     vlist_d
dg_right_start
                ldx     #shape_right
                jsr     vlist_d
dg_right_end
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$0010
                jsr     Moveto_d
                ldx     #move_left
                jsr     vlist_d
dg_left_start
                ldx     #shape_left
                jsr     vlist_d
dg_left_end
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$FD25
                jsr     Moveto_d
                ldx     #move_up
                jsr     vlist_d
dg_up_start
                ldx     #shape_up
                jsr     vlist_d
dg_up_end
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$033F
                jsr     Moveto_d
                ldx     #move_down
                jsr     vlist_d
dg_down_start
                ldx     #shape_down
                jsr     vlist_d
dg_down_end
                rts

move_raster
                fcb     1,105,-16,$00
                fcb     0,0
move_right
                fcb     1,0,-78,$00
                fcb     0,0
shape_right                              ; pointing right: 6 vectors
                fcb     28,0,26,$FF
                fcb     28,17,0,$FF
                fcb     28,-10,0,$FF
                fcb     28,-7,48,$FF
                fcb     28,-7,-48,$FF
                fcb     28,-10,0,$FF
                fcb     0,0
move_left
                fcb     1,0,50,$00
                fcb     0,0
shape_left                              ; pointing left: 6 vectors
                fcb     28,0,-26,$FF
                fcb     28,-17,0,$FF
                fcb     28,10,0,$FF
                fcb     28,7,-48,$FF
                fcb     28,7,48,$FF
                fcb     28,10,0,$FF
                fcb     0,0
move_up
                fcb     1,-99,106,$00
                fcb     0,0
shape_up                              ; pointing up: 6 vectors
                fcb     28,26,0,$FF
                fcb     28,0,-17,$FF
                fcb     28,0,10,$FF
                fcb     28,48,7,$FF
                fcb     28,-48,7,$FF
                fcb     28,0,10,$FF
                fcb     0,0
move_down
                fcb     1,99,7,$00
                fcb     0,0
shape_down                              ; pointing down: 6 vectors
                fcb     28,-26,0,$FF
                fcb     28,0,17,$FF
                fcb     28,0,-10,$FF
                fcb     28,-48,-7,$FF
                fcb     28,48,-7,$FF
                fcb     28,0,-10,$FF
                fcb     0,0
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
