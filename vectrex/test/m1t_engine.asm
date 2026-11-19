; made by vectrex/tools/m1_trim_gen.py: milestone 1's column routines and the trimmed one

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

; trimmed columns, any length (1-12 bytes): 16n + 41 cycles a column
; in: X = the first column's data, timer 1's latch low ($D006) = the number of columns,
; U = $0120 (facing right) or $01E0 (left): the slide, the beam at the first column's start
trim_down
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$80B0                  ;  4 Y speed down
                sty     <VIA_port_b             ;  6 mux on
                jmp     tu_next                 ;  3 (the up run's turn: a down column next)
trim_up
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$8050                  ;  4 Y speed up
                sty     <VIA_port_b             ;  6 mux on
                jmp     td_next                 ;  3 (the down run's turn: an up column next)
; the down run: slot k for a column of 12 - k bytes
td_slots
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
                sta     <VIA_shift_reg          ;  4 t = 16n - 3: the last byte
                stu     <VIA_port_b             ;  5 t = 16n + 1: the slide (after the last bit)
                sty     <VIA_port_b             ;  6 t = 16n + 6 = e: ramp off, mux on, the next Y speed
                dec     <$06                    ;  6 e+6: the count
                beq     td_out                  ;  3 
td_next
                ldy     #$80B0                  ;  4 e+15: the speed after the next column
                ldd     #$8100                  ;  3 
                std     <VIA_port_b             ;  5 e+22: mux off, X speed 0
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 e+35 = t = 0: ramp on
                jmp     [,x++]                  ;  9 t = 4: into the up run
td_out
                lbra    trim_out                ;  5 
; the up run: slot k for a column of 12 - k bytes
tu_slots
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
                sta     <VIA_shift_reg          ;  4 t = 16n - 3: the last byte
                stu     <VIA_port_b             ;  5 t = 16n + 1: the slide (after the last bit)
                sty     <VIA_port_b             ;  6 t = 16n + 6 = e: ramp off, mux on, the next Y speed
                dec     <$06                    ;  6 e+6: the count
                beq     tu_out                  ;  3 
tu_next
                ldy     #$8050                  ;  4 e+15: the speed after the next column
                ldd     #$8100                  ;  3 
                std     <VIA_port_b             ;  5 e+22: mux off, X speed 0
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 e+35 = t = 0: ramp on
                jmp     [,x++]                  ;  9 t = 4: into the down run
tu_out
                lbra    trim_out                ;  5 
trim_out
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

