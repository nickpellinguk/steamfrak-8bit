; made by vectrex/tools/m3_gen.py: the raster engine

; columns of 2 bytes (16 pixels): 67 cycles a column (70 after an up column)
; in: X = the first column's data, $C880 = the number of columns + 1, the beam at the
; first column's start (half a pixel left of it, at the top for _down, the bottom for _up)
; facing left: the same columns, drawn from the right, the slide going left
col2_down_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col2_down_c             ;  5 (not timed)
col2_up_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col2_up_c               ;  5 (not timed)
col2_down
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col2_down_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$80B0                  ;  4 Y speed down
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
col2_d_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col2_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$8050                  ;  4 the Y speed after this column (up)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (the slide: a pixel across)
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28: byte 1
                sty     <VIA_port_b             ;  6 t = 32 = e: ramp off, mux on, DAC = the next Y speed
col2_u_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col2_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$80B0                  ;  4 the Y speed after this column (down)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (the slide: a pixel across)
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28: byte 1
                sty     <VIA_port_b             ;  6 t = 32 = e: ramp off, mux on, DAC = the next Y speed
                bra     col2_d_loop             ;  3 (in the settling time)
col2_up
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col2_up_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$8050                  ;  4 Y speed up
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
                bra     col2_u_loop             ;  3 
col2_out
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

; columns of 3 bytes (24 pixels): 83 cycles a column (86 after an up column)
; in: X = the first column's data, $C880 = the number of columns + 1, the beam at the
; first column's start (half a pixel left of it, at the top for _down, the bottom for _up)
; facing left: the same columns, drawn from the right, the slide going left
col3_down_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col3_down_c             ;  5 (not timed)
col3_up_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col3_up_c               ;  5 (not timed)
col3_down
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col3_down_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$80B0                  ;  4 Y speed down
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
col3_d_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col3_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$8050                  ;  4 the Y speed after this column (up)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                sty     <VIA_port_b             ;  6 t = 48 = e: ramp off, mux on, DAC = the next Y speed
col3_u_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col3_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$80B0                  ;  4 the Y speed after this column (down)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                sty     <VIA_port_b             ;  6 t = 48 = e: ramp off, mux on, DAC = the next Y speed
                bra     col3_d_loop             ;  3 (in the settling time)
col3_up
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col3_up_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$8050                  ;  4 Y speed up
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
                bra     col3_u_loop             ;  3 
col3_out
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

; columns of 4 bytes (32 pixels): 99 cycles a column (102 after an up column)
; in: X = the first column's data, $C880 = the number of columns + 1, the beam at the
; first column's start (half a pixel left of it, at the top for _down, the bottom for _up)
; facing left: the same columns, drawn from the right, the slide going left
col4_down_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col4_down_c             ;  5 (not timed)
col4_up_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col4_up_c               ;  5 (not timed)
col4_down
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col4_down_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$80B0                  ;  4 Y speed down
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
col4_d_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col4_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$8050                  ;  4 the Y speed after this column (up)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                sty     <VIA_port_b             ;  6 t = 64 = e: ramp off, mux on, DAC = the next Y speed
col4_u_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col4_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$80B0                  ;  4 the Y speed after this column (down)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                sty     <VIA_port_b             ;  6 t = 64 = e: ramp off, mux on, DAC = the next Y speed
                bra     col4_d_loop             ;  3 (in the settling time)
col4_up
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col4_up_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$8050                  ;  4 Y speed up
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
                bra     col4_u_loop             ;  3 
col4_out
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

; columns of 5 bytes (40 pixels): 115 cycles a column (118 after an up column)
; in: X = the first column's data, $C880 = the number of columns + 1, the beam at the
; first column's start (half a pixel left of it, at the top for _down, the bottom for _up)
; facing left: the same columns, drawn from the right, the slide going left
col5_down_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col5_down_c             ;  5 (not timed)
col5_up_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col5_up_c               ;  5 (not timed)
col5_down
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col5_down_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$80B0                  ;  4 Y speed down
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
col5_d_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col5_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$8050                  ;  4 the Y speed after this column (up)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col5_up_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$8050                  ;  4 Y speed up
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
                bra     col5_u_loop             ;  3 
col5_out
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

; columns of 6 bytes (48 pixels): 131 cycles a column (134 after an up column)
; in: X = the first column's data, $C880 = the number of columns + 1, the beam at the
; first column's start (half a pixel left of it, at the top for _down, the bottom for _up)
; facing left: the same columns, drawn from the right, the slide going left
col6_down_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col6_down_c             ;  5 (not timed)
col6_up_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col6_up_c               ;  5 (not timed)
col6_down
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col6_down_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$80B0                  ;  4 Y speed down
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
col6_d_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col6_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$8050                  ;  4 the Y speed after this column (up)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92: byte 5
                sty     <VIA_port_b             ;  6 t = 96 = e: ramp off, mux on, DAC = the next Y speed
col6_u_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col6_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$80B0                  ;  4 the Y speed after this column (down)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92: byte 5
                sty     <VIA_port_b             ;  6 t = 96 = e: ramp off, mux on, DAC = the next Y speed
                bra     col6_d_loop             ;  3 (in the settling time)
col6_up
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col6_up_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$8050                  ;  4 Y speed up
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
                bra     col6_u_loop             ;  3 
col6_out
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

; columns of 7 bytes (56 pixels): 147 cycles a column (150 after an up column)
; in: X = the first column's data, $C880 = the number of columns + 1, the beam at the
; first column's start (half a pixel left of it, at the top for _down, the bottom for _up)
; facing left: the same columns, drawn from the right, the slide going left
col7_down_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col7_down_c             ;  5 (not timed)
col7_up_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col7_up_c               ;  5 (not timed)
col7_down
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col7_down_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$80B0                  ;  4 Y speed down
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
col7_d_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col7_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$8050                  ;  4 the Y speed after this column (up)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                sty     <VIA_port_b             ;  6 t = 112 = e: ramp off, mux on, DAC = the next Y speed
col7_u_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col7_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$80B0                  ;  4 the Y speed after this column (down)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                sty     <VIA_port_b             ;  6 t = 112 = e: ramp off, mux on, DAC = the next Y speed
                lbra    col7_d_loop             ;  5 (in the settling time; too far for BRA)
col7_up
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col7_up_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$8050                  ;  4 Y speed up
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
                bra     col7_u_loop             ;  3 
col7_out
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

; columns of 8 bytes (64 pixels): 163 cycles a column (166 after an up column)
; in: X = the first column's data, $C880 = the number of columns + 1, the beam at the
; first column's start (half a pixel left of it, at the top for _down, the bottom for _up)
; facing left: the same columns, drawn from the right, the slide going left
col8_down_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col8_down_c             ;  5 (not timed)
col8_up_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col8_up_c               ;  5 (not timed)
col8_down
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col8_down_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$80B0                  ;  4 Y speed down
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
col8_d_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col8_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$8050                  ;  4 the Y speed after this column (up)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 124: byte 7
                sty     <VIA_port_b             ;  6 t = 128 = e: ramp off, mux on, DAC = the next Y speed
col8_u_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col8_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$80B0                  ;  4 the Y speed after this column (down)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 124: byte 7
                sty     <VIA_port_b             ;  6 t = 128 = e: ramp off, mux on, DAC = the next Y speed
                lbra    col8_d_loop             ;  5 (in the settling time; too far for BRA)
col8_up
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col8_up_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$8050                  ;  4 Y speed up
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
                bra     col8_u_loop             ;  3 
col8_out
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

; columns of 9 bytes (72 pixels): 179 cycles a column (182 after an up column)
; in: X = the first column's data, $C880 = the number of columns + 1, the beam at the
; first column's start (half a pixel left of it, at the top for _down, the bottom for _up)
; facing left: the same columns, drawn from the right, the slide going left
col9_down_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col9_down_c             ;  5 (not timed)
col9_up_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col9_up_c               ;  5 (not timed)
col9_down
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col9_down_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$80B0                  ;  4 Y speed down
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
col9_d_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col9_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$8050                  ;  4 the Y speed after this column (up)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 124: byte 7
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                sty     <VIA_port_b             ;  6 t = 144 = e: ramp off, mux on, DAC = the next Y speed
col9_u_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col9_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$80B0                  ;  4 the Y speed after this column (down)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 124: byte 7
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                sty     <VIA_port_b             ;  6 t = 144 = e: ramp off, mux on, DAC = the next Y speed
                lbra    col9_d_loop             ;  5 (in the settling time; too far for BRA)
col9_up
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col9_up_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$8050                  ;  4 Y speed up
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
                bra     col9_u_loop             ;  3 
col9_out
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

; columns of 10 bytes (80 pixels): 195 cycles a column (198 after an up column)
; in: X = the first column's data, $C880 = the number of columns + 1, the beam at the
; first column's start (half a pixel left of it, at the top for _down, the bottom for _up)
; facing left: the same columns, drawn from the right, the slide going left
col10_down_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col10_down_c            ;  5 (not timed)
col10_up_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col10_up_c              ;  5 (not timed)
col10_down
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col10_down_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$80B0                  ;  4 Y speed down
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
col10_d_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col10_out               ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$8050                  ;  4 the Y speed after this column (up)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 124: byte 7
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 156: byte 9
                sty     <VIA_port_b             ;  6 t = 160 = e: ramp off, mux on, DAC = the next Y speed
col10_u_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col10_out               ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$80B0                  ;  4 the Y speed after this column (down)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 124: byte 7
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 156: byte 9
                sty     <VIA_port_b             ;  6 t = 160 = e: ramp off, mux on, DAC = the next Y speed
                lbra    col10_d_loop            ;  5 (in the settling time; too far for BRA)
col10_up
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col10_up_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$8050                  ;  4 Y speed up
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
                bra     col10_u_loop            ;  3 
col10_out
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

; columns of 11 bytes (88 pixels): 211 cycles a column (214 after an up column)
; in: X = the first column's data, $C880 = the number of columns + 1, the beam at the
; first column's start (half a pixel left of it, at the top for _down, the bottom for _up)
; facing left: the same columns, drawn from the right, the slide going left
col11_down_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col11_down_c            ;  5 (not timed)
col11_up_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col11_up_c              ;  5 (not timed)
col11_down
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col11_down_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$80B0                  ;  4 Y speed down
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
col11_d_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col11_out               ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$8050                  ;  4 the Y speed after this column (up)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 124: byte 7
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 156: byte 9
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                sty     <VIA_port_b             ;  6 t = 176 = e: ramp off, mux on, DAC = the next Y speed
col11_u_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col11_out               ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$80B0                  ;  4 the Y speed after this column (down)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
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
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 124: byte 7
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 156: byte 9
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                sty     <VIA_port_b             ;  6 t = 176 = e: ramp off, mux on, DAC = the next Y speed
                lbra    col11_d_loop            ;  5 (in the settling time; too far for BRA)
col11_up
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col11_up_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$8050                  ;  4 Y speed up
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
                bra     col11_u_loop            ;  3 
col11_out
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

; two rows of 2-28 bytes, the first and last bytes of each masked: 32 x bytes + ~150
; in: X = row 0's first byte, $C882 = row 1's, STRIP_N = bytes a row (2 or more),
; M0F, M0L, M1F, M1L = the masks for rows 0 and 1's first and last bytes, the beam at
; row 0's left end
strip_m
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
                ldy     #$8000                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed 0
                ldy     #$8150                  ;  4 (the sample-and-hold settles)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, DAC (X speed) 80
                ldy     #strip_entries          ;  4 
                ldb     $C899                   ;  5 
                aslb                            ;  2 
                ldu     b,y                     ;  6 where in the run of slots to start
                ldy     #$C89B                  ;  4 the last byte's mask
                lda     ,x+                     ;  6 
                anda    $C89A                   ;  5 the first byte, masked
                ldb     #$01                    ;  2 
                stb     >$D000+VIA_port_b       ;  5 t = 0: ramp on
                jsr     ,u                      ;  7 t = 5: the slots (the first store at 12)
                brn     *                       ;  3 t = 16n + 9 (back)
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
                ldy     #strip_entries          ;  4 
                ldb     $C899                   ;  5 
                aslb                            ;  2 
                ldu     b,y                     ;  6 where in the run of slots to start
                ldy     #$C89D                  ;  4 the last byte's mask
                lda     ,x+                     ;  6 
                anda    $C89C                   ;  5 the first byte, masked
                ldb     #$01                    ;  2 
                stb     >$D000+VIA_port_b       ;  5 t = 0: ramp on
                jsr     ,u                      ;  7 t = 5: the slots (the first store at 12)
                brn     *                       ;  3 t = 16n + 9 (back)
                clr     <VIA_shift_reg          ;  6 t = 16n + 12: spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 
; the slots: each stores the byte in A (t = 12 + 16k) and loads the next
strip_slots
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
strip_and
                sta     <VIA_shift_reg          ;  4 
                lda     ,x+                     ;  6 the last byte...
                anda    ,y                      ;  4 ...masked
                ldb     #$81                    ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12 + 16(n - 1): the last byte
                stb     <VIA_port_b             ;  4 t = 16n: ramp off
                rts                             ;  5 
strip_entries
                fdb     strip_and-0          ; 0 bytes
                fdb     strip_and-0          ; 1 bytes
                fdb     strip_and-0          ; 2 bytes
                fdb     strip_and-7          ; 3 bytes
                fdb     strip_and-14          ; 4 bytes
                fdb     strip_and-21          ; 5 bytes
                fdb     strip_and-28          ; 6 bytes
                fdb     strip_and-35          ; 7 bytes
                fdb     strip_and-42          ; 8 bytes
                fdb     strip_and-49          ; 9 bytes
                fdb     strip_and-56          ; 10 bytes
                fdb     strip_and-63          ; 11 bytes
                fdb     strip_and-70          ; 12 bytes
                fdb     strip_and-77          ; 13 bytes
                fdb     strip_and-84          ; 14 bytes
                fdb     strip_and-91          ; 15 bytes
                fdb     strip_and-98          ; 16 bytes
                fdb     strip_and-105          ; 17 bytes
                fdb     strip_and-112          ; 18 bytes
                fdb     strip_and-119          ; 19 bytes
                fdb     strip_and-126          ; 20 bytes
                fdb     strip_and-133          ; 21 bytes
                fdb     strip_and-140          ; 22 bytes
                fdb     strip_and-147          ; 23 bytes
                fdb     strip_and-154          ; 24 bytes
                fdb     strip_and-161          ; 25 bytes
                fdb     strip_and-168          ; 26 bytes
                fdb     strip_and-175          ; 27 bytes
                fdb     strip_and-182          ; 28 bytes

