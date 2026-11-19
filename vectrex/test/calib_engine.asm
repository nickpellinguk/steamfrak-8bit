; made by vectrex/tools/calib_gen.py

; columns of 5 bytes (40 pixels): 115 cycles a column (118 after an up column)
; in: X = the first column's data, $C880 = the number of columns + 1, the beam at the
; first column's start (half a pixel left of it, at the top for _down, the bottom for _up)
col5_down
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
                ldy     #$80B0                  ;  4 Y speed down
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
col5_d_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col5_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$8050                  ;  4 the Y speed after this column (up)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = 40
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (the slide: a pixel across)
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28: byte 1
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60: byte 3
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                sty     <VIA_port_b             ;  6 t = 80 = e: ramp off, mux on, DAC = the next Y speed
col5_u_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col5_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$80B0                  ;  4 the Y speed after this column (down)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = 40
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (the slide: a pixel across)
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28: byte 1
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60: byte 3
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                sty     <VIA_port_b             ;  6 t = 80 = e: ramp off, mux on, DAC = the next Y speed
                bra     col5_d_loop             ;  3 (in the settling time)
col5_up
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
                ldy     #$8050                  ;  4 Y speed up
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
                bra     col5_u_loop             ;  3 
col5_out
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

; drifting rows of 3 bytes, 10 of them: 480 cycles; drift 3 (rows 144 units apart)
; in: X = the rows' data (in sweep order), the beam at the first row's left end
rows3_10
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldu     #$8150                  ;  3 (for the ramp off at the end)
                ldy     #$80FD                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed = the drift
                lda     ,x+                     ;  6 the first byte (the sample-and-hold settles...)
                ldb     #$B0                    ;  2 (X speed for row 1)
                ldy     #$0150                  ;  4 ...
                sty     <VIA_port_b             ;  6 t = 0: ramp on, mux off, X speed 80 (one store)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                stb     <VIA_port_a             ;  4 t = 48: row 1: X speed -80
                lda     ,x+                     ;  6 
                ldb     #$50                    ;  2 (X speed for the next row)
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_a             ;  4 t = 96: row 2: X speed +80
                lda     ,x+                     ;  6 
                ldb     #$B0                    ;  2 (X speed for the next row)
                sta     <VIA_shift_reg          ;  4 t = 108
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 124
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140
                stb     <VIA_port_a             ;  4 t = 144: row 3: X speed -80
                lda     ,x+                     ;  6 
                ldb     #$50                    ;  2 (X speed for the next row)
                sta     <VIA_shift_reg          ;  4 t = 156
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 188
                stb     <VIA_port_a             ;  4 t = 192: row 4: X speed +80
                lda     ,x+                     ;  6 
                ldb     #$B0                    ;  2 (X speed for the next row)
                sta     <VIA_shift_reg          ;  4 t = 204
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 220
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236
                stb     <VIA_port_a             ;  4 t = 240: row 5: X speed -80
                lda     ,x+                     ;  6 
                ldb     #$50                    ;  2 (X speed for the next row)
                sta     <VIA_shift_reg          ;  4 t = 252
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 284
                stb     <VIA_port_a             ;  4 t = 288: row 6: X speed +80
                lda     ,x+                     ;  6 
                ldb     #$B0                    ;  2 (X speed for the next row)
                sta     <VIA_shift_reg          ;  4 t = 300
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 316
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332
                stb     <VIA_port_a             ;  4 t = 336: row 7: X speed -80
                lda     ,x+                     ;  6 
                ldb     #$50                    ;  2 (X speed for the next row)
                sta     <VIA_shift_reg          ;  4 t = 348
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 380
                stb     <VIA_port_a             ;  4 t = 384: row 8: X speed +80
                lda     ,x+                     ;  6 
                ldb     #$B0                    ;  2 (X speed for the next row)
                sta     <VIA_shift_reg          ;  4 t = 396
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 412
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428
                stb     <VIA_port_a             ;  4 t = 432: row 9: X speed -80
                lda     ,x+                     ;  6 
                ldb     #$50                    ;  2 (X speed for the next row)
                sta     <VIA_shift_reg          ;  4 t = 444
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 476
                stu     <VIA_port_b             ;  5 t = 480: ramp off
                brn     *                       ;  3 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 492: spot off (the last bits are shown)
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; two rows of any length: 32 x bytes + ~140 cycles
strip
                stb     $C880                   ;  5 
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
                ldu     #$8100                  ;  3 (the ramp off)
                ldy     #$8000                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed 0
                ldy     #$8150                  ;  4 (the sample-and-hold settles)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, DAC (X speed) 80
                ldb     $C880                   ;  5 
                decb                            ;  2 (bytes - 1 in the loop)
                lda     #$01                    ;  2 
                sta     <VIA_port_b             ;  4 t = 0: ramp on
                nop                             ;  2 
strip_0
                lda     ,x+                     ;  6 t = 6 + 16i
                sta     >$D000+VIA_shift_reg    ;  5 t = 12 + 16i
                decb                            ;  2 
                bne     strip_0                 ;  3 
                lda     ,x+                     ;  6 t = 16n - 10: the last byte
                sta     <VIA_shift_reg          ;  4 t = 16n - 4
                stu     <VIA_port_b             ;  5 t = 16n: ramp off
                brn     *                       ;  3 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 16n + 12: spot off
                ldy     #$80D8                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -40
                ldy     #$8100                  ;  4 (the sample-and-hold settles)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, DAC (X speed) 0
                lda     #$01                    ;  2 
                ldb     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp on...
                stb     <VIA_port_b             ;  4 ...for 4 cycles: a pixel down
                ldx     $C882                   ;  6 row 1's bytes
                ldy     #$8000                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed 0
                ldy     #$81B0                  ;  4 (the sample-and-hold settles)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, DAC (X speed) -80
                ldb     $C880                   ;  5 
                decb                            ;  2 (bytes - 1 in the loop)
                lda     #$01                    ;  2 
                sta     <VIA_port_b             ;  4 t = 0: ramp on
                nop                             ;  2 
strip_1
                lda     ,x+                     ;  6 t = 6 + 16i
                sta     >$D000+VIA_shift_reg    ;  5 t = 12 + 16i
                decb                            ;  2 
                bne     strip_1                 ;  3 
                lda     ,x+                     ;  6 t = 16n - 10: the last byte
                sta     <VIA_shift_reg          ;  4 t = 16n - 4
                stu     <VIA_port_b             ;  5 t = 16n: ramp off
                brn     *                       ;  3 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 16n + 12: spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

