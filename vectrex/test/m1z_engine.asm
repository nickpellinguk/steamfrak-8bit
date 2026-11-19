; made by vectrex/tools/m1_zig_gen.py

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

; a zigzag sprite, 26 x 34: 34 rows (pitch 1.02 pixels), drift 4, 88 bytes: ramp on 1395 cycles
; in: X = the data, the beam at the sprite's top left
zig_trogg
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
                ldy     #$80FC                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -4 (the drift down)
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 bytes 0 and 1
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                sty     <VIA_port_b             ;  6 t = 48: row 1, X speed -80
                lda     ,x+                     ;  6 t = 54: byte 4
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                stu     <VIA_port_b             ;  5 t = 80: row 2, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 t = 96: byte 6
                ldb     ,x+                     ;  6 t = 102: byte 7
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 116: row 3, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                lda     ,x+                     ;  6 t = 128: byte 8
                ldb     ,x+                     ;  6 t = 134: byte 9
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 t = 144: byte 10
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                stu     <VIA_port_b             ;  5 t = 160: row 4, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                ldb     ,x+                     ;  6 t = 176: byte 11
                lda     ,x+                     ;  6 t = 182: byte 12
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                sty     <VIA_port_b             ;  6 t = 208: row 5, X speed -80
                lda     ,x+                     ;  6 t = 214: byte 14
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                stu     <VIA_port_b             ;  5 t = 256: row 6, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                ldb     ,x+                     ;  6 t = 272: byte 17
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                ldb     ,x+                     ;  6 t = 288: byte 19
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                sty     <VIA_port_b             ;  6 t = 304: row 7, X speed -80
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                lda     ,x+                     ;  6 t = 336: byte 22
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                stu     <VIA_port_b             ;  5 t = 352: row 8, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                ldb     ,x+                     ;  6 t = 368: byte 23
                lda     ,x+                     ;  6 t = 374: byte 24
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 386: row 9, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 423: row 10, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                ldb     ,x+                     ;  6 t = 432: byte 27
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                sty     <VIA_port_b             ;  6 t = 464: row 11, X speed -80
                lda     ,x+                     ;  6 t = 470: byte 30
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                ldb     ,x+                     ;  6 t = 480: byte 31
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                stu     <VIA_port_b             ;  5 t = 512: row 12, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                ldb     ,x+                     ;  6 t = 528: byte 33
                lda     ,x+                     ;  6 t = 534: byte 34
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                sty     <VIA_port_b             ;  6 t = 560: row 13, X speed -80
                lda     ,x+                     ;  6 t = 566: byte 36
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                ldb     ,x+                     ;  6 t = 576: byte 37
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                lda     ,x+                     ;  6 t = 592: byte 38
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                stu     <VIA_port_b             ;  5 t = 608: row 14, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                ldb     ,x+                     ;  6 t = 624: byte 39
                lda     ,x+                     ;  6 t = 630: byte 40
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                ldb     ,x+                     ;  6 t = 640: byte 41
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                sty     <VIA_port_b             ;  6 t = 656: row 15, X speed -80
                lda     ,x+                     ;  6 t = 662: byte 42
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                ldb     ,x+                     ;  6 t = 672: byte 43
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                lda     ,x+                     ;  6 t = 688: byte 44
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                stu     <VIA_port_b             ;  5 t = 704: row 16, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                ldb     ,x+                     ;  6 t = 720: byte 45
                lda     ,x+                     ;  6 t = 726: byte 46
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                ldb     ,x+                     ;  6 t = 736: byte 47
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                sty     <VIA_port_b             ;  6 t = 752: row 17, X speed -80
                lda     ,x+                     ;  6 t = 758: byte 48
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                ldb     ,x+                     ;  6 t = 768: byte 49
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                lda     ,x+                     ;  6 t = 784: byte 50
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                stu     <VIA_port_b             ;  5 t = 800: row 18, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                ldb     ,x+                     ;  6 t = 816: byte 51
                lda     ,x+                     ;  6 t = 822: byte 52
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                sty     <VIA_port_b             ;  6 t = 848: row 19, X speed -80
                lda     ,x+                     ;  6 t = 854: byte 54
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                ldb     ,x+                     ;  6 t = 864: byte 55
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                lda     ,x+                     ;  6 t = 880: byte 56
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                stu     <VIA_port_b             ;  5 t = 896: row 20, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                ldb     ,x+                     ;  6 t = 912: byte 57
                lda     ,x+                     ;  6 t = 918: byte 58
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                ldb     ,x+                     ;  6 t = 928: byte 59
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                sty     <VIA_port_b             ;  6 t = 944: row 21, X speed -80
                lda     ,x+                     ;  6 t = 950: byte 60
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                ldb     ,x+                     ;  6 t = 960: byte 61
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                lda     ,x+                     ;  6 t = 976: byte 62
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                stu     <VIA_port_b             ;  5 t = 992: row 22, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                ldb     ,x+                     ;  6 t = 1008: byte 63
                lda     ,x+                     ;  6 t = 1014: byte 64
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1028: row 23, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                ldb     ,x+                     ;  6 t = 1040: byte 65
                lda     ,x+                     ;  6 t = 1046: byte 66
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 1063: row 24, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                ldb     ,x+                     ;  6 t = 1072: byte 67
                lda     ,x+                     ;  6 t = 1078: byte 68
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                ldb     ,x+                     ;  6 t = 1088: byte 69
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                sty     <VIA_port_b             ;  6 t = 1104: row 25, X speed -80
                lda     ,x+                     ;  6 t = 1110: byte 70
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                ldb     ,x+                     ;  6 t = 1120: byte 71
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                stu     <VIA_port_b             ;  5 t = 1136: row 26, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                lda     ,x+                     ;  6 t = 1152: byte 72
                ldb     ,x+                     ;  6 t = 1158: byte 73
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                sty     <VIA_port_b             ;  6 t = 1168: row 27, X speed -80
                lda     ,x+                     ;  6 t = 1174: byte 74
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                ldb     ,x+                     ;  6 t = 1184: byte 75
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                stu     <VIA_port_b             ;  5 t = 1200: row 28, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                lda     ,x+                     ;  6 t = 1216: byte 76
                ldb     ,x+                     ;  6 t = 1222: byte 77
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                sty     <VIA_port_b             ;  6 t = 1232: row 29, X speed -80
                lda     ,x+                     ;  6 t = 1238: byte 78
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                ldb     ,x+                     ;  6 t = 1248: byte 79
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                stu     <VIA_port_b             ;  5 t = 1264: row 30, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                lda     ,x+                     ;  6 t = 1280: byte 80
                ldb     ,x+                     ;  6 t = 1286: byte 81
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                sty     <VIA_port_b             ;  6 t = 1296: row 31, X speed -80
                lda     ,x+                     ;  6 t = 1302: byte 82
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                ldb     ,x+                     ;  6 t = 1312: byte 83
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                stu     <VIA_port_b             ;  5 t = 1328: row 32, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                lda     ,x+                     ;  6 t = 1344: byte 84
                ldb     ,x+                     ;  6 t = 1350: byte 85
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                sty     <VIA_port_b             ;  6 t = 1360: row 33, X speed -80
                lda     ,x+                     ;  6 t = 1366: byte 86
                stb     <VIA_shift_reg          ;  4 t = 1372: byte 85
                ldb     ,x+                     ;  6 t = 1376: byte 87
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1388: byte 86
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 1395: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1404: byte 87
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 33 x 42: 54 rows (pitch 0.78 pixels), drift 2, 212 bytes: ramp on 3379 cycles
; in: X = the data, the beam at the sprite's top left
zig_scrubbly
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
                ldy     #$80FE                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -2 (the drift down)
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 bytes 0 and 1
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 52: row 1, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                lda     ,x+                     ;  6 t = 64: byte 4
                ldb     ,x+                     ;  6 t = 70: byte 5
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                stu     <VIA_port_b             ;  5 t = 96: row 2, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                ldb     ,x+                     ;  6 t = 112: byte 7
                lda     ,x+                     ;  6 t = 118: byte 8
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                ldb     ,x+                     ;  6 t = 128: byte 9
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                sty     <VIA_port_b             ;  6 t = 144: row 3, X speed -80
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                stu     <VIA_port_b             ;  5 t = 192: row 4, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                ldb     ,x+                     ;  6 t = 208: byte 13
                lda     ,x+                     ;  6 t = 214: byte 14
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                sty     <VIA_port_b             ;  6 t = 240: row 5, X speed -80
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                stu     <VIA_port_b             ;  5 t = 288: row 6, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                sty     <VIA_port_b             ;  6 t = 336: row 7, X speed -80
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                stu     <VIA_port_b             ;  5 t = 384: row 8, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                sty     <VIA_port_b             ;  6 t = 432: row 9, X speed -80
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                stu     <VIA_port_b             ;  5 t = 480: row 10, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                ldb     ,x+                     ;  6 t = 496: byte 31
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                sty     <VIA_port_b             ;  6 t = 528: row 11, X speed -80
                lda     ,x+                     ;  6 t = 534: byte 34
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                lda     ,x+                     ;  6 t = 560: byte 36
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                stu     <VIA_port_b             ;  5 t = 576: row 12, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                ldb     ,x+                     ;  6 t = 592: byte 37
                lda     ,x+                     ;  6 t = 598: byte 38
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                sty     <VIA_port_b             ;  6 t = 624: row 13, X speed -80
                lda     ,x+                     ;  6 t = 630: byte 40
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                ldb     ,x+                     ;  6 t = 640: byte 41
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                lda     ,x+                     ;  6 t = 656: byte 42
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                stu     <VIA_port_b             ;  5 t = 672: row 14, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                ldb     ,x+                     ;  6 t = 688: byte 43
                lda     ,x+                     ;  6 t = 694: byte 44
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                ldb     ,x+                     ;  6 t = 704: byte 45
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                sty     <VIA_port_b             ;  6 t = 720: row 15, X speed -80
                lda     ,x+                     ;  6 t = 726: byte 46
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                ldb     ,x+                     ;  6 t = 736: byte 47
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                lda     ,x+                     ;  6 t = 752: byte 48
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                stu     <VIA_port_b             ;  5 t = 768: row 16, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                ldb     ,x+                     ;  6 t = 784: byte 49
                lda     ,x+                     ;  6 t = 790: byte 50
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                ldb     ,x+                     ;  6 t = 800: byte 51
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 818: row 17, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                lda     ,x+                     ;  6 t = 832: byte 52
                ldb     ,x+                     ;  6 t = 838: byte 53
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 871: row 18, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                ldb     ,x+                     ;  6 t = 880: byte 55
                lda     ,x+                     ;  6 t = 886: byte 56
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                ldb     ,x+                     ;  6 t = 896: byte 57
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                lda     ,x+                     ;  6 t = 912: byte 58
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                sty     <VIA_port_b             ;  6 t = 928: row 19, X speed -80
                ldb     ,x+                     ;  6 t = 934: byte 59
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                lda     ,x+                     ;  6 t = 944: byte 60
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                ldb     ,x+                     ;  6 t = 960: byte 61
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                lda     ,x+                     ;  6 t = 976: byte 62
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                stu     <VIA_port_b             ;  5 t = 992: row 20, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                ldb     ,x+                     ;  6 t = 1008: byte 63
                lda     ,x+                     ;  6 t = 1014: byte 64
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                ldb     ,x+                     ;  6 t = 1024: byte 65
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                lda     ,x+                     ;  6 t = 1040: byte 66
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                sty     <VIA_port_b             ;  6 t = 1056: row 21, X speed -80
                ldb     ,x+                     ;  6 t = 1062: byte 67
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                lda     ,x+                     ;  6 t = 1072: byte 68
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                ldb     ,x+                     ;  6 t = 1088: byte 69
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                lda     ,x+                     ;  6 t = 1104: byte 70
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                stu     <VIA_port_b             ;  5 t = 1120: row 22, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                ldb     ,x+                     ;  6 t = 1136: byte 71
                lda     ,x+                     ;  6 t = 1142: byte 72
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                ldb     ,x+                     ;  6 t = 1152: byte 73
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                lda     ,x+                     ;  6 t = 1168: byte 74
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                sty     <VIA_port_b             ;  6 t = 1184: row 23, X speed -80
                ldb     ,x+                     ;  6 t = 1190: byte 75
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                lda     ,x+                     ;  6 t = 1200: byte 76
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                ldb     ,x+                     ;  6 t = 1216: byte 77
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                lda     ,x+                     ;  6 t = 1232: byte 78
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                stu     <VIA_port_b             ;  5 t = 1248: row 24, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                ldb     ,x+                     ;  6 t = 1264: byte 79
                lda     ,x+                     ;  6 t = 1270: byte 80
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                ldb     ,x+                     ;  6 t = 1280: byte 81
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                lda     ,x+                     ;  6 t = 1296: byte 82
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                sty     <VIA_port_b             ;  6 t = 1312: row 25, X speed -80
                ldb     ,x+                     ;  6 t = 1318: byte 83
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                lda     ,x+                     ;  6 t = 1328: byte 84
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                ldb     ,x+                     ;  6 t = 1344: byte 85
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                lda     ,x+                     ;  6 t = 1360: byte 86
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1372: byte 85
                stu     <VIA_port_b             ;  5 t = 1376: row 26, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1388: byte 86
                ldb     ,x+                     ;  6 t = 1392: byte 87
                lda     ,x+                     ;  6 t = 1398: byte 88
                stb     <VIA_shift_reg          ;  4 t = 1404: byte 87
                ldb     ,x+                     ;  6 t = 1408: byte 89
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                lda     ,x+                     ;  6 t = 1424: byte 90
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1436: byte 89
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1442: row 27, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1452: byte 90
                ldb     ,x+                     ;  6 t = 1456: byte 91
                lda     ,x+                     ;  6 t = 1462: byte 92
                stb     <VIA_shift_reg          ;  4 t = 1468: byte 91
                ldb     ,x+                     ;  6 t = 1472: byte 93
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1484: byte 92
                lda     ,x+                     ;  6 t = 1488: byte 94
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1500: byte 93
                stu     <VIA_port_b             ;  5 t = 1504: row 28, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1516: byte 94
                ldb     ,x+                     ;  6 t = 1520: byte 95
                lda     ,x+                     ;  6 t = 1526: byte 96
                stb     <VIA_shift_reg          ;  4 t = 1532: byte 95
                ldb     ,x+                     ;  6 t = 1536: byte 97
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1548: byte 96
                lda     ,x+                     ;  6 t = 1552: byte 98
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1564: byte 97
                sty     <VIA_port_b             ;  6 t = 1568: row 29, X speed -80
                ldb     ,x+                     ;  6 t = 1574: byte 99
                sta     <VIA_shift_reg          ;  4 t = 1580: byte 98
                lda     ,x+                     ;  6 t = 1584: byte 100
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1596: byte 99
                ldb     ,x+                     ;  6 t = 1600: byte 101
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1612: byte 100
                lda     ,x+                     ;  6 t = 1616: byte 102
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1628: byte 101
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1634: row 30, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1644: byte 102
                ldb     ,x+                     ;  6 t = 1648: byte 103
                lda     ,x+                     ;  6 t = 1654: byte 104
                stb     <VIA_shift_reg          ;  4 t = 1660: byte 103
                ldb     ,x+                     ;  6 t = 1664: byte 105
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1676: byte 104
                lda     ,x+                     ;  6 t = 1680: byte 106
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1692: byte 105
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1700: row 31, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1708: byte 106
                ldb     ,x+                     ;  6 t = 1712: byte 107
                lda     ,x+                     ;  6 t = 1718: byte 108
                stb     <VIA_shift_reg          ;  4 t = 1724: byte 107
                ldb     ,x+                     ;  6 t = 1728: byte 109
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1740: byte 108
                lda     ,x+                     ;  6 t = 1744: byte 110
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1756: byte 109
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 1767: row 32, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 1772: byte 110
                ldb     ,x+                     ;  6 t = 1776: byte 111
                lda     ,x+                     ;  6 t = 1782: byte 112
                stb     <VIA_shift_reg          ;  4 t = 1788: byte 111
                ldb     ,x+                     ;  6 t = 1792: byte 113
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1804: byte 112
                lda     ,x+                     ;  6 t = 1808: byte 114
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1820: byte 113
                ldb     ,x+                     ;  6 t = 1824: byte 115
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1836: byte 114
                sty     <VIA_port_b             ;  6 t = 1840: row 33, X speed -80
                lda     ,x+                     ;  6 t = 1846: byte 116
                stb     <VIA_shift_reg          ;  4 t = 1852: byte 115
                ldb     ,x+                     ;  6 t = 1856: byte 117
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1868: byte 116
                lda     ,x+                     ;  6 t = 1872: byte 118
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1884: byte 117
                ldb     ,x+                     ;  6 t = 1888: byte 119
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1900: byte 118
                lda     ,x+                     ;  6 t = 1904: byte 120
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1916: byte 119
                stu     <VIA_port_b             ;  5 t = 1920: row 34, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1932: byte 120
                ldb     ,x+                     ;  6 t = 1936: byte 121
                lda     ,x+                     ;  6 t = 1942: byte 122
                stb     <VIA_shift_reg          ;  4 t = 1948: byte 121
                ldb     ,x+                     ;  6 t = 1952: byte 123
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1964: byte 122
                lda     ,x+                     ;  6 t = 1968: byte 124
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1980: byte 123
                ldb     ,x+                     ;  6 t = 1984: byte 125
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1996: byte 124
                sty     <VIA_port_b             ;  6 t = 2000: row 35, X speed -80
                lda     ,x+                     ;  6 t = 2006: byte 126
                stb     <VIA_shift_reg          ;  4 t = 2012: byte 125
                ldb     ,x+                     ;  6 t = 2016: byte 127
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2028: byte 126
                lda     ,x+                     ;  6 t = 2032: byte 128
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2044: byte 127
                ldb     ,x+                     ;  6 t = 2048: byte 129
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2060: byte 128
                lda     ,x+                     ;  6 t = 2064: byte 130
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2076: byte 129
                stu     <VIA_port_b             ;  5 t = 2080: row 36, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2092: byte 130
                ldb     ,x+                     ;  6 t = 2096: byte 131
                lda     ,x+                     ;  6 t = 2102: byte 132
                stb     <VIA_shift_reg          ;  4 t = 2108: byte 131
                ldb     ,x+                     ;  6 t = 2112: byte 133
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2124: byte 132
                lda     ,x+                     ;  6 t = 2128: byte 134
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2140: byte 133
                ldb     ,x+                     ;  6 t = 2144: byte 135
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2156: byte 134
                sty     <VIA_port_b             ;  6 t = 2160: row 37, X speed -80
                lda     ,x+                     ;  6 t = 2166: byte 136
                stb     <VIA_shift_reg          ;  4 t = 2172: byte 135
                ldb     ,x+                     ;  6 t = 2176: byte 137
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2188: byte 136
                lda     ,x+                     ;  6 t = 2192: byte 138
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2204: byte 137
                ldb     ,x+                     ;  6 t = 2208: byte 139
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2220: byte 138
                lda     ,x+                     ;  6 t = 2224: byte 140
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2236: byte 139
                stu     <VIA_port_b             ;  5 t = 2240: row 38, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2252: byte 140
                ldb     ,x+                     ;  6 t = 2256: byte 141
                lda     ,x+                     ;  6 t = 2262: byte 142
                stb     <VIA_shift_reg          ;  4 t = 2268: byte 141
                ldb     ,x+                     ;  6 t = 2272: byte 143
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2284: byte 142
                lda     ,x+                     ;  6 t = 2288: byte 144
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2300: byte 143
                ldb     ,x+                     ;  6 t = 2304: byte 145
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2316: byte 144
                sty     <VIA_port_b             ;  6 t = 2320: row 39, X speed -80
                lda     ,x+                     ;  6 t = 2326: byte 146
                stb     <VIA_shift_reg          ;  4 t = 2332: byte 145
                ldb     ,x+                     ;  6 t = 2336: byte 147
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2348: byte 146
                lda     ,x+                     ;  6 t = 2352: byte 148
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2364: byte 147
                ldb     ,x+                     ;  6 t = 2368: byte 149
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2380: byte 148
                lda     ,x+                     ;  6 t = 2384: byte 150
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2396: byte 149
                stu     <VIA_port_b             ;  5 t = 2400: row 40, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2412: byte 150
                ldb     ,x+                     ;  6 t = 2416: byte 151
                lda     ,x+                     ;  6 t = 2422: byte 152
                stb     <VIA_shift_reg          ;  4 t = 2428: byte 151
                ldb     ,x+                     ;  6 t = 2432: byte 153
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2444: byte 152
                lda     ,x+                     ;  6 t = 2448: byte 154
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2460: byte 153
                ldb     ,x+                     ;  6 t = 2464: byte 155
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2476: byte 154
                sty     <VIA_port_b             ;  6 t = 2480: row 41, X speed -80
                lda     ,x+                     ;  6 t = 2486: byte 156
                stb     <VIA_shift_reg          ;  4 t = 2492: byte 155
                ldb     ,x+                     ;  6 t = 2496: byte 157
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2508: byte 156
                lda     ,x+                     ;  6 t = 2512: byte 158
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2524: byte 157
                ldb     ,x+                     ;  6 t = 2528: byte 159
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2540: byte 158
                lda     ,x+                     ;  6 t = 2544: byte 160
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2556: byte 159
                stu     <VIA_port_b             ;  5 t = 2560: row 42, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2572: byte 160
                ldb     ,x+                     ;  6 t = 2576: byte 161
                lda     ,x+                     ;  6 t = 2582: byte 162
                stb     <VIA_shift_reg          ;  4 t = 2588: byte 161
                ldb     ,x+                     ;  6 t = 2592: byte 163
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2604: byte 162
                lda     ,x+                     ;  6 t = 2608: byte 164
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2620: byte 163
                ldb     ,x+                     ;  6 t = 2624: byte 165
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2636: byte 164
                sty     <VIA_port_b             ;  6 t = 2640: row 43, X speed -80
                lda     ,x+                     ;  6 t = 2646: byte 166
                stb     <VIA_shift_reg          ;  4 t = 2652: byte 165
                ldb     ,x+                     ;  6 t = 2656: byte 167
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2668: byte 166
                lda     ,x+                     ;  6 t = 2672: byte 168
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2684: byte 167
                ldb     ,x+                     ;  6 t = 2688: byte 169
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2700: byte 168
                lda     ,x+                     ;  6 t = 2704: byte 170
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2716: byte 169
                stu     <VIA_port_b             ;  5 t = 2720: row 44, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2732: byte 170
                ldb     ,x+                     ;  6 t = 2736: byte 171
                lda     ,x+                     ;  6 t = 2742: byte 172
                stb     <VIA_shift_reg          ;  4 t = 2748: byte 171
                ldb     ,x+                     ;  6 t = 2752: byte 173
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2764: byte 172
                lda     ,x+                     ;  6 t = 2768: byte 174
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2780: byte 173
                ldb     ,x+                     ;  6 t = 2784: byte 175
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2796: byte 174
                sty     <VIA_port_b             ;  6 t = 2800: row 45, X speed -80
                lda     ,x+                     ;  6 t = 2806: byte 176
                stb     <VIA_shift_reg          ;  4 t = 2812: byte 175
                ldb     ,x+                     ;  6 t = 2816: byte 177
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2828: byte 176
                lda     ,x+                     ;  6 t = 2832: byte 178
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2844: byte 177
                ldb     ,x+                     ;  6 t = 2848: byte 179
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2860: byte 178
                lda     ,x+                     ;  6 t = 2864: byte 180
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2876: byte 179
                stu     <VIA_port_b             ;  5 t = 2880: row 46, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2892: byte 180
                ldb     ,x+                     ;  6 t = 2896: byte 181
                lda     ,x+                     ;  6 t = 2902: byte 182
                stb     <VIA_shift_reg          ;  4 t = 2908: byte 181
                ldb     ,x+                     ;  6 t = 2912: byte 183
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2924: byte 182
                lda     ,x+                     ;  6 t = 2928: byte 184
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2940: byte 183
                ldb     ,x+                     ;  6 t = 2944: byte 185
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2956: byte 184
                sty     <VIA_port_b             ;  6 t = 2960: row 47, X speed -80
                lda     ,x+                     ;  6 t = 2966: byte 186
                stb     <VIA_shift_reg          ;  4 t = 2972: byte 185
                ldb     ,x+                     ;  6 t = 2976: byte 187
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2988: byte 186
                lda     ,x+                     ;  6 t = 2992: byte 188
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3004: byte 187
                ldb     ,x+                     ;  6 t = 3008: byte 189
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3020: byte 188
                lda     ,x+                     ;  6 t = 3024: byte 190
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3036: byte 189
                stu     <VIA_port_b             ;  5 t = 3040: row 48, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 3052: byte 190
                ldb     ,x+                     ;  6 t = 3056: byte 191
                lda     ,x+                     ;  6 t = 3062: byte 192
                stb     <VIA_shift_reg          ;  4 t = 3068: byte 191
                ldb     ,x+                     ;  6 t = 3072: byte 193
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3084: byte 192
                lda     ,x+                     ;  6 t = 3088: byte 194
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3100: byte 193
                ldb     ,x+                     ;  6 t = 3104: byte 195
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3116: byte 194
                sty     <VIA_port_b             ;  6 t = 3120: row 49, X speed -80
                lda     ,x+                     ;  6 t = 3126: byte 196
                stb     <VIA_shift_reg          ;  4 t = 3132: byte 195
                ldb     ,x+                     ;  6 t = 3136: byte 197
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3148: byte 196
                lda     ,x+                     ;  6 t = 3152: byte 198
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3164: byte 197
                ldb     ,x+                     ;  6 t = 3168: byte 199
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3180: byte 198
                stu     <VIA_port_b             ;  5 t = 3184: row 50, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 3196: byte 199
                lda     ,x+                     ;  6 t = 3200: byte 200
                ldb     ,x+                     ;  6 t = 3206: byte 201
                sta     <VIA_shift_reg          ;  4 t = 3212: byte 200
                lda     ,x+                     ;  6 t = 3216: byte 202
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3228: byte 201
                sty     <VIA_port_b             ;  6 t = 3232: row 51, X speed -80
                ldb     ,x+                     ;  6 t = 3238: byte 203
                sta     <VIA_shift_reg          ;  4 t = 3244: byte 202
                lda     ,x+                     ;  6 t = 3248: byte 204
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3260: byte 203
                ldb     ,x+                     ;  6 t = 3264: byte 205
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3276: byte 204
                stu     <VIA_port_b             ;  5 t = 3280: row 52, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 3292: byte 205
                lda     ,x+                     ;  6 t = 3296: byte 206
                ldb     ,x+                     ;  6 t = 3302: byte 207
                sta     <VIA_shift_reg          ;  4 t = 3308: byte 206
                lda     ,x+                     ;  6 t = 3312: byte 208
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3324: byte 207
                sty     <VIA_port_b             ;  6 t = 3328: row 53, X speed -80
                ldb     ,x+                     ;  6 t = 3334: byte 209
                sta     <VIA_shift_reg          ;  4 t = 3340: byte 208
                lda     ,x+                     ;  6 t = 3344: byte 210
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3356: byte 209
                ldb     ,x+                     ;  6 t = 3360: byte 211
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3372: byte 210
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 3379: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3388: byte 211
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 23 x 33: 37 rows (pitch 0.91 pixels), drift 4, 85 bytes: ramp on 1347 cycles
; in: X = the data, the beam at the sprite's top left
zig_poglet
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
                ldy     #$80FC                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -4 (the drift down)
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 bytes 0 and 1
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                sty     <VIA_port_b             ;  6 t = 32: row 1, X speed -80
                ldb     ,x+                     ;  6 t = 38: byte 3
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 50: row 2, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                lda     ,x+                     ;  6 t = 64: byte 4
                sty     <VIA_port_b             ;  6 t = 70: row 3, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                ldb     ,x+                     ;  6 t = 80: byte 5
                lda     ,x+                     ;  6 t = 86: byte 6
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                stu     <VIA_port_b             ;  5 t = 96: row 4, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                ldb     ,x+                     ;  6 t = 112: byte 7
                lda     ,x+                     ;  6 t = 118: byte 8
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                sty     <VIA_port_b             ;  6 t = 128: row 5, X speed -80
                ldb     ,x+                     ;  6 t = 134: byte 9
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 t = 144: byte 10
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                stu     <VIA_port_b             ;  5 t = 160: row 6, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                ldb     ,x+                     ;  6 t = 176: byte 11
                lda     ,x+                     ;  6 t = 182: byte 12
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                sty     <VIA_port_b             ;  6 t = 192: row 7, X speed -80
                ldb     ,x+                     ;  6 t = 198: byte 13
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                lda     ,x+                     ;  6 t = 208: byte 14
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                stu     <VIA_port_b             ;  5 t = 224: row 8, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                ldb     ,x+                     ;  6 t = 240: byte 15
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                sty     <VIA_port_b             ;  6 t = 256: row 9, X speed -80
                ldb     ,x+                     ;  6 t = 262: byte 17
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                stu     <VIA_port_b             ;  5 t = 288: row 10, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                sty     <VIA_port_b             ;  6 t = 320: row 11, X speed -80
                ldb     ,x+                     ;  6 t = 326: byte 21
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                lda     ,x+                     ;  6 t = 336: byte 22
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 354: row 12, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                ldb     ,x+                     ;  6 t = 368: byte 23
                lda     ,x+                     ;  6 t = 374: byte 24
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 386: row 13, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 420: row 14, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                ldb     ,x+                     ;  6 t = 432: byte 27
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                sty     <VIA_port_b             ;  6 t = 454: row 15, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                ldb     ,x+                     ;  6 t = 480: byte 31
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                stu     <VIA_port_b             ;  5 t = 496: row 16, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                lda     ,x+                     ;  6 t = 512: byte 32
                ldb     ,x+                     ;  6 t = 518: byte 33
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                lda     ,x+                     ;  6 t = 528: byte 34
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                sty     <VIA_port_b             ;  6 t = 544: row 17, X speed -80
                ldb     ,x+                     ;  6 t = 550: byte 35
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                lda     ,x+                     ;  6 t = 560: byte 36
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                ldb     ,x+                     ;  6 t = 576: byte 37
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                stu     <VIA_port_b             ;  5 t = 592: row 18, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                lda     ,x+                     ;  6 t = 608: byte 38
                ldb     ,x+                     ;  6 t = 614: byte 39
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                lda     ,x+                     ;  6 t = 624: byte 40
                sty     <VIA_port_b             ;  6 t = 630: row 19, X speed -80
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                ldb     ,x+                     ;  6 t = 640: byte 41
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 660: row 20, X speed +80
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                lda     ,x+                     ;  6 t = 672: byte 42
                ldb     ,x+                     ;  6 t = 678: byte 43
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                sty     <VIA_port_b             ;  6 t = 688: row 21, X speed -80
                lda     ,x+                     ;  6 t = 694: byte 44
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                ldb     ,x+                     ;  6 t = 704: byte 45
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                stu     <VIA_port_b             ;  5 t = 720: row 22, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                lda     ,x+                     ;  6 t = 736: byte 46
                ldb     ,x+                     ;  6 t = 742: byte 47
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 754: row 23, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                lda     ,x+                     ;  6 t = 768: byte 48
                ldb     ,x+                     ;  6 t = 774: byte 49
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                stu     <VIA_port_b             ;  5 t = 784: row 24, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                lda     ,x+                     ;  6 t = 800: byte 50
                ldb     ,x+                     ;  6 t = 806: byte 51
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                sty     <VIA_port_b             ;  6 t = 816: row 25, X speed -80
                lda     ,x+                     ;  6 t = 822: byte 52
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                stu     <VIA_port_b             ;  5 t = 848: row 26, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                lda     ,x+                     ;  6 t = 864: byte 54
                ldb     ,x+                     ;  6 t = 870: byte 55
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 882: row 27, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                lda     ,x+                     ;  6 t = 896: byte 56
                ldb     ,x+                     ;  6 t = 902: byte 57
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 919: row 28, X speed +80
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                lda     ,x+                     ;  6 t = 928: byte 58
                ldb     ,x+                     ;  6 t = 934: byte 59
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                lda     ,x+                     ;  6 t = 944: byte 60
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 964: row 29, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                ldb     ,x+                     ;  6 t = 976: byte 61
                lda     ,x+                     ;  6 t = 982: byte 62
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                ldb     ,x+                     ;  6 t = 992: byte 63
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1010: row 30, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                lda     ,x+                     ;  6 t = 1024: byte 64
                ldb     ,x+                     ;  6 t = 1030: byte 65
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                lda     ,x+                     ;  6 t = 1040: byte 66
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                sty     <VIA_port_b             ;  6 t = 1056: row 31, X speed -80
                ldb     ,x+                     ;  6 t = 1062: byte 67
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                lda     ,x+                     ;  6 t = 1072: byte 68
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                ldb     ,x+                     ;  6 t = 1088: byte 69
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                stu     <VIA_port_b             ;  5 t = 1104: row 32, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                lda     ,x+                     ;  6 t = 1120: byte 70
                ldb     ,x+                     ;  6 t = 1126: byte 71
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                lda     ,x+                     ;  6 t = 1136: byte 72
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                sty     <VIA_port_b             ;  6 t = 1152: row 33, X speed -80
                ldb     ,x+                     ;  6 t = 1158: byte 73
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                lda     ,x+                     ;  6 t = 1168: byte 74
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                ldb     ,x+                     ;  6 t = 1184: byte 75
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                stu     <VIA_port_b             ;  5 t = 1200: row 34, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                lda     ,x+                     ;  6 t = 1216: byte 76
                ldb     ,x+                     ;  6 t = 1222: byte 77
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                lda     ,x+                     ;  6 t = 1232: byte 78
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                sty     <VIA_port_b             ;  6 t = 1248: row 35, X speed -80
                ldb     ,x+                     ;  6 t = 1254: byte 79
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                lda     ,x+                     ;  6 t = 1264: byte 80
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                ldb     ,x+                     ;  6 t = 1280: byte 81
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                stu     <VIA_port_b             ;  5 t = 1296: row 36, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                lda     ,x+                     ;  6 t = 1312: byte 82
                ldb     ,x+                     ;  6 t = 1318: byte 83
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                lda     ,x+                     ;  6 t = 1328: byte 84
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 1347: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 19 x 23: 31 rows (pitch 0.78 pixels), drift 3, 81 bytes: ramp on 1283 cycles
; in: X = the data, the beam at the sprite's top left
zig_hooter
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
                ldy     #$80FD                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -3 (the drift down)
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 bytes 0 and 1
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                sty     <VIA_port_b             ;  6 t = 38: row 1, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                stu     <VIA_port_b             ;  5 t = 80: row 2, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 t = 96: byte 6
                ldb     ,x+                     ;  6 t = 102: byte 7
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                sty     <VIA_port_b             ;  6 t = 128: row 3, X speed -80
                ldb     ,x+                     ;  6 t = 134: byte 9
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 t = 144: byte 10
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                stu     <VIA_port_b             ;  5 t = 176: row 4, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                lda     ,x+                     ;  6 t = 192: byte 12
                ldb     ,x+                     ;  6 t = 198: byte 13
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                lda     ,x+                     ;  6 t = 208: byte 14
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                sty     <VIA_port_b             ;  6 t = 224: row 5, X speed -80
                ldb     ,x+                     ;  6 t = 230: byte 15
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 263: row 6, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                ldb     ,x+                     ;  6 t = 272: byte 17
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 292: row 7, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 324: row 8, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                ldb     ,x+                     ;  6 t = 336: byte 21
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 356: row 9, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                ldb     ,x+                     ;  6 t = 368: byte 23
                lda     ,x+                     ;  6 t = 374: byte 24
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 388: row 10, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                sty     <VIA_port_b             ;  6 t = 422: row 11, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                lda     ,x+                     ;  6 t = 432: byte 28
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                stu     <VIA_port_b             ;  5 t = 464: row 12, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                lda     ,x+                     ;  6 t = 480: byte 30
                ldb     ,x+                     ;  6 t = 486: byte 31
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                sty     <VIA_port_b             ;  6 t = 512: row 13, X speed -80
                ldb     ,x+                     ;  6 t = 518: byte 33
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                lda     ,x+                     ;  6 t = 528: byte 34
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                stu     <VIA_port_b             ;  5 t = 560: row 14, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                lda     ,x+                     ;  6 t = 576: byte 36
                ldb     ,x+                     ;  6 t = 582: byte 37
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                lda     ,x+                     ;  6 t = 592: byte 38
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                sty     <VIA_port_b             ;  6 t = 608: row 15, X speed -80
                ldb     ,x+                     ;  6 t = 614: byte 39
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                ldb     ,x+                     ;  6 t = 640: byte 41
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                stu     <VIA_port_b             ;  5 t = 656: row 16, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                lda     ,x+                     ;  6 t = 672: byte 42
                ldb     ,x+                     ;  6 t = 678: byte 43
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                lda     ,x+                     ;  6 t = 688: byte 44
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                sty     <VIA_port_b             ;  6 t = 704: row 17, X speed -80
                ldb     ,x+                     ;  6 t = 710: byte 45
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                lda     ,x+                     ;  6 t = 720: byte 46
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                ldb     ,x+                     ;  6 t = 736: byte 47
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                stu     <VIA_port_b             ;  5 t = 752: row 18, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                lda     ,x+                     ;  6 t = 768: byte 48
                ldb     ,x+                     ;  6 t = 774: byte 49
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                lda     ,x+                     ;  6 t = 784: byte 50
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                sty     <VIA_port_b             ;  6 t = 800: row 19, X speed -80
                ldb     ,x+                     ;  6 t = 806: byte 51
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                lda     ,x+                     ;  6 t = 816: byte 52
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                stu     <VIA_port_b             ;  5 t = 848: row 20, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                lda     ,x+                     ;  6 t = 864: byte 54
                ldb     ,x+                     ;  6 t = 870: byte 55
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                lda     ,x+                     ;  6 t = 880: byte 56
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                sty     <VIA_port_b             ;  6 t = 896: row 21, X speed -80
                ldb     ,x+                     ;  6 t = 902: byte 57
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                lda     ,x+                     ;  6 t = 912: byte 58
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 935: row 22, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                ldb     ,x+                     ;  6 t = 944: byte 59
                lda     ,x+                     ;  6 t = 950: byte 60
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                ldb     ,x+                     ;  6 t = 960: byte 61
                sty     <VIA_port_b             ;  6 t = 966: row 23, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                lda     ,x+                     ;  6 t = 976: byte 62
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 996: row 24, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                ldb     ,x+                     ;  6 t = 1008: byte 63
                lda     ,x+                     ;  6 t = 1014: byte 64
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1026: row 25, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                ldb     ,x+                     ;  6 t = 1040: byte 65
                lda     ,x+                     ;  6 t = 1046: byte 66
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                stu     <VIA_port_b             ;  5 t = 1056: row 26, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                ldb     ,x+                     ;  6 t = 1072: byte 67
                lda     ,x+                     ;  6 t = 1078: byte 68
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1090: row 27, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                ldb     ,x+                     ;  6 t = 1104: byte 69
                lda     ,x+                     ;  6 t = 1110: byte 70
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                ldb     ,x+                     ;  6 t = 1120: byte 71
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                stu     <VIA_port_b             ;  5 t = 1136: row 28, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                lda     ,x+                     ;  6 t = 1152: byte 72
                ldb     ,x+                     ;  6 t = 1158: byte 73
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                lda     ,x+                     ;  6 t = 1168: byte 74
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                sty     <VIA_port_b             ;  6 t = 1184: row 29, X speed -80
                ldb     ,x+                     ;  6 t = 1190: byte 75
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                lda     ,x+                     ;  6 t = 1200: byte 76
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                ldb     ,x+                     ;  6 t = 1216: byte 77
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                stu     <VIA_port_b             ;  5 t = 1232: row 30, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                lda     ,x+                     ;  6 t = 1248: byte 78
                ldb     ,x+                     ;  6 t = 1254: byte 79
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                lda     ,x+                     ;  6 t = 1264: byte 80
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 1283: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 11 x 9: 10 rows (pitch 0.96 pixels), drift 5, 20 bytes: ramp on 307 cycles
; in: X = the data, the beam at the sprite's top left
zig_gem
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
                ldy     #$80FB                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -5 (the drift down)
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 bytes 0 and 1
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 20: row 1, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                lda     ,x+                     ;  6 t = 32: byte 2
                ldb     ,x+                     ;  6 t = 38: byte 3
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                stu     <VIA_port_b             ;  5 t = 48: row 2, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                lda     ,x+                     ;  6 t = 64: byte 4
                ldb     ,x+                     ;  6 t = 70: byte 5
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                sty     <VIA_port_b             ;  6 t = 80: row 3, X speed -80
                lda     ,x+                     ;  6 t = 86: byte 6
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                stu     <VIA_port_b             ;  5 t = 112: row 4, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                lda     ,x+                     ;  6 t = 128: byte 8
                ldb     ,x+                     ;  6 t = 134: byte 9
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                sty     <VIA_port_b             ;  6 t = 144: row 5, X speed -80
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                stu     <VIA_port_b             ;  5 t = 176: row 6, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                lda     ,x+                     ;  6 t = 192: byte 12
                ldb     ,x+                     ;  6 t = 198: byte 13
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                sty     <VIA_port_b             ;  6 t = 208: row 7, X speed -80
                lda     ,x+                     ;  6 t = 214: byte 14
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                stu     <VIA_port_b             ;  5 t = 240: row 8, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                lda     ,x+                     ;  6 t = 256: byte 16
                ldb     ,x+                     ;  6 t = 262: byte 17
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 276: row 9, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                lda     ,x+                     ;  6 t = 288: byte 18
                ldb     ,x+                     ;  6 t = 294: byte 19
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 307: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 12 x 70: 80 rows (pitch 0.88 pixels), drift 5, 141 bytes: ramp on 2245 cycles
; in: X = the data, the beam at the sprite's top left
zig_ladder
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
                ldy     #$80FB                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -5 (the drift down)
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 bytes 0 and 1
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                sty     <VIA_port_b             ;  6 t = 16: row 1, X speed -80
                lda     ,x+                     ;  6 t = 22: byte 2
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                stu     <VIA_port_b             ;  5 t = 32: row 2, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                ldb     ,x+                     ;  6 t = 48: byte 3
                lda     ,x+                     ;  6 t = 54: byte 4
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                sty     <VIA_port_b             ;  6 t = 64: row 3, X speed -80
                ldb     ,x+                     ;  6 t = 70: byte 5
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                stu     <VIA_port_b             ;  5 t = 96: row 4, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                ldb     ,x+                     ;  6 t = 112: byte 7
                lda     ,x+                     ;  6 t = 118: byte 8
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                sty     <VIA_port_b             ;  6 t = 128: row 5, X speed -80
                ldb     ,x+                     ;  6 t = 134: byte 9
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 t = 144: byte 10
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                stu     <VIA_port_b             ;  5 t = 160: row 6, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                ldb     ,x+                     ;  6 t = 176: byte 11
                lda     ,x+                     ;  6 t = 182: byte 12
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                sty     <VIA_port_b             ;  6 t = 192: row 7, X speed -80
                ldb     ,x+                     ;  6 t = 198: byte 13
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                lda     ,x+                     ;  6 t = 208: byte 14
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                stu     <VIA_port_b             ;  5 t = 224: row 8, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                ldb     ,x+                     ;  6 t = 240: byte 15
                sty     <VIA_port_b             ;  6 t = 246: row 9, X speed -80
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                lda     ,x+                     ;  6 t = 256: byte 16
                ldb     ,x+                     ;  6 t = 262: byte 17
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                stu     <VIA_port_b             ;  5 t = 272: row 10, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                lda     ,x+                     ;  6 t = 288: byte 18
                ldb     ,x+                     ;  6 t = 294: byte 19
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                sty     <VIA_port_b             ;  6 t = 304: row 11, X speed -80
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                stu     <VIA_port_b             ;  5 t = 336: row 12, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                lda     ,x+                     ;  6 t = 352: byte 22
                ldb     ,x+                     ;  6 t = 358: byte 23
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                sty     <VIA_port_b             ;  6 t = 368: row 13, X speed -80
                lda     ,x+                     ;  6 t = 374: byte 24
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                ldb     ,x+                     ;  6 t = 384: byte 25
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                stu     <VIA_port_b             ;  5 t = 400: row 14, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                lda     ,x+                     ;  6 t = 416: byte 26
                ldb     ,x+                     ;  6 t = 422: byte 27
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                sty     <VIA_port_b             ;  6 t = 432: row 15, X speed -80
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 452: row 16, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                sty     <VIA_port_b             ;  6 t = 464: row 17, X speed -80
                ldb     ,x+                     ;  6 t = 470: byte 29
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                lda     ,x+                     ;  6 t = 480: byte 30
                ldb     ,x+                     ;  6 t = 486: byte 31
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                stu     <VIA_port_b             ;  5 t = 496: row 18, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                lda     ,x+                     ;  6 t = 512: byte 32
                ldb     ,x+                     ;  6 t = 518: byte 33
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 532: row 19, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                lda     ,x+                     ;  6 t = 544: byte 34
                ldb     ,x+                     ;  6 t = 550: byte 35
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                stu     <VIA_port_b             ;  5 t = 560: row 20, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                lda     ,x+                     ;  6 t = 576: byte 36
                ldb     ,x+                     ;  6 t = 582: byte 37
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                sty     <VIA_port_b             ;  6 t = 592: row 21, X speed -80
                lda     ,x+                     ;  6 t = 598: byte 38
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                stu     <VIA_port_b             ;  5 t = 624: row 22, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                lda     ,x+                     ;  6 t = 640: byte 40
                ldb     ,x+                     ;  6 t = 646: byte 41
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                sty     <VIA_port_b             ;  6 t = 656: row 23, X speed -80
                lda     ,x+                     ;  6 t = 662: byte 42
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 676: row 24, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                sty     <VIA_port_b             ;  6 t = 688: row 25, X speed -80
                ldb     ,x+                     ;  6 t = 694: byte 43
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                lda     ,x+                     ;  6 t = 704: byte 44
                ldb     ,x+                     ;  6 t = 710: byte 45
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                stu     <VIA_port_b             ;  5 t = 720: row 26, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                lda     ,x+                     ;  6 t = 736: byte 46
                ldb     ,x+                     ;  6 t = 742: byte 47
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 756: row 27, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                lda     ,x+                     ;  6 t = 768: byte 48
                ldb     ,x+                     ;  6 t = 774: byte 49
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                stu     <VIA_port_b             ;  5 t = 784: row 28, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                lda     ,x+                     ;  6 t = 800: byte 50
                ldb     ,x+                     ;  6 t = 806: byte 51
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                sty     <VIA_port_b             ;  6 t = 816: row 29, X speed -80
                lda     ,x+                     ;  6 t = 822: byte 52
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                stu     <VIA_port_b             ;  5 t = 848: row 30, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                lda     ,x+                     ;  6 t = 864: byte 54
                ldb     ,x+                     ;  6 t = 870: byte 55
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                sty     <VIA_port_b             ;  6 t = 880: row 31, X speed -80
                lda     ,x+                     ;  6 t = 886: byte 56
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 900: row 32, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                sty     <VIA_port_b             ;  6 t = 912: row 33, X speed -80
                ldb     ,x+                     ;  6 t = 918: byte 57
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                lda     ,x+                     ;  6 t = 928: byte 58
                ldb     ,x+                     ;  6 t = 934: byte 59
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                stu     <VIA_port_b             ;  5 t = 944: row 34, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                lda     ,x+                     ;  6 t = 960: byte 60
                ldb     ,x+                     ;  6 t = 966: byte 61
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 980: row 35, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                lda     ,x+                     ;  6 t = 992: byte 62
                ldb     ,x+                     ;  6 t = 998: byte 63
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                stu     <VIA_port_b             ;  5 t = 1008: row 36, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                lda     ,x+                     ;  6 t = 1024: byte 64
                ldb     ,x+                     ;  6 t = 1030: byte 65
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                sty     <VIA_port_b             ;  6 t = 1040: row 37, X speed -80
                lda     ,x+                     ;  6 t = 1046: byte 66
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                ldb     ,x+                     ;  6 t = 1056: byte 67
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                stu     <VIA_port_b             ;  5 t = 1072: row 38, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                lda     ,x+                     ;  6 t = 1088: byte 68
                ldb     ,x+                     ;  6 t = 1094: byte 69
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                sty     <VIA_port_b             ;  6 t = 1104: row 39, X speed -80
                lda     ,x+                     ;  6 t = 1110: byte 70
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1124: row 40, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                sty     <VIA_port_b             ;  6 t = 1136: row 41, X speed -80
                ldb     ,x+                     ;  6 t = 1142: byte 71
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                lda     ,x+                     ;  6 t = 1152: byte 72
                ldb     ,x+                     ;  6 t = 1158: byte 73
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                stu     <VIA_port_b             ;  5 t = 1168: row 42, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                lda     ,x+                     ;  6 t = 1184: byte 74
                ldb     ,x+                     ;  6 t = 1190: byte 75
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1204: row 43, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                lda     ,x+                     ;  6 t = 1216: byte 76
                ldb     ,x+                     ;  6 t = 1222: byte 77
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                stu     <VIA_port_b             ;  5 t = 1232: row 44, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                lda     ,x+                     ;  6 t = 1248: byte 78
                ldb     ,x+                     ;  6 t = 1254: byte 79
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                sty     <VIA_port_b             ;  6 t = 1264: row 45, X speed -80
                lda     ,x+                     ;  6 t = 1270: byte 80
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                ldb     ,x+                     ;  6 t = 1280: byte 81
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                stu     <VIA_port_b             ;  5 t = 1296: row 46, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                lda     ,x+                     ;  6 t = 1312: byte 82
                ldb     ,x+                     ;  6 t = 1318: byte 83
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                sty     <VIA_port_b             ;  6 t = 1328: row 47, X speed -80
                lda     ,x+                     ;  6 t = 1334: byte 84
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1348: row 48, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                sty     <VIA_port_b             ;  6 t = 1360: row 49, X speed -80
                ldb     ,x+                     ;  6 t = 1366: byte 85
                stb     <VIA_shift_reg          ;  4 t = 1372: byte 85
                lda     ,x+                     ;  6 t = 1376: byte 86
                ldb     ,x+                     ;  6 t = 1382: byte 87
                sta     <VIA_shift_reg          ;  4 t = 1388: byte 86
                stu     <VIA_port_b             ;  5 t = 1392: row 50, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1404: byte 87
                lda     ,x+                     ;  6 t = 1408: byte 88
                ldb     ,x+                     ;  6 t = 1414: byte 89
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1428: row 51, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1436: byte 89
                lda     ,x+                     ;  6 t = 1440: byte 90
                ldb     ,x+                     ;  6 t = 1446: byte 91
                sta     <VIA_shift_reg          ;  4 t = 1452: byte 90
                stu     <VIA_port_b             ;  5 t = 1456: row 52, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1468: byte 91
                lda     ,x+                     ;  6 t = 1472: byte 92
                ldb     ,x+                     ;  6 t = 1478: byte 93
                sta     <VIA_shift_reg          ;  4 t = 1484: byte 92
                sty     <VIA_port_b             ;  6 t = 1488: row 53, X speed -80
                lda     ,x+                     ;  6 t = 1494: byte 94
                stb     <VIA_shift_reg          ;  4 t = 1500: byte 93
                ldb     ,x+                     ;  6 t = 1504: byte 95
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1516: byte 94
                stu     <VIA_port_b             ;  5 t = 1520: row 54, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1532: byte 95
                lda     ,x+                     ;  6 t = 1536: byte 96
                ldb     ,x+                     ;  6 t = 1542: byte 97
                sta     <VIA_shift_reg          ;  4 t = 1548: byte 96
                sty     <VIA_port_b             ;  6 t = 1552: row 55, X speed -80
                lda     ,x+                     ;  6 t = 1558: byte 98
                stb     <VIA_shift_reg          ;  4 t = 1564: byte 97
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1572: row 56, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1580: byte 98
                sty     <VIA_port_b             ;  6 t = 1584: row 57, X speed -80
                ldb     ,x+                     ;  6 t = 1590: byte 99
                stb     <VIA_shift_reg          ;  4 t = 1596: byte 99
                lda     ,x+                     ;  6 t = 1600: byte 100
                ldb     ,x+                     ;  6 t = 1606: byte 101
                sta     <VIA_shift_reg          ;  4 t = 1612: byte 100
                stu     <VIA_port_b             ;  5 t = 1616: row 58, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1628: byte 101
                lda     ,x+                     ;  6 t = 1632: byte 102
                ldb     ,x+                     ;  6 t = 1638: byte 103
                sta     <VIA_shift_reg          ;  4 t = 1644: byte 102
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1652: row 59, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1660: byte 103
                lda     ,x+                     ;  6 t = 1664: byte 104
                ldb     ,x+                     ;  6 t = 1670: byte 105
                sta     <VIA_shift_reg          ;  4 t = 1676: byte 104
                stu     <VIA_port_b             ;  5 t = 1680: row 60, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1692: byte 105
                lda     ,x+                     ;  6 t = 1696: byte 106
                ldb     ,x+                     ;  6 t = 1702: byte 107
                sta     <VIA_shift_reg          ;  4 t = 1708: byte 106
                sty     <VIA_port_b             ;  6 t = 1712: row 61, X speed -80
                lda     ,x+                     ;  6 t = 1718: byte 108
                stb     <VIA_shift_reg          ;  4 t = 1724: byte 107
                ldb     ,x+                     ;  6 t = 1728: byte 109
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1740: byte 108
                stu     <VIA_port_b             ;  5 t = 1744: row 62, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1756: byte 109
                lda     ,x+                     ;  6 t = 1760: byte 110
                ldb     ,x+                     ;  6 t = 1766: byte 111
                sta     <VIA_shift_reg          ;  4 t = 1772: byte 110
                sty     <VIA_port_b             ;  6 t = 1776: row 63, X speed -80
                lda     ,x+                     ;  6 t = 1782: byte 112
                stb     <VIA_shift_reg          ;  4 t = 1788: byte 111
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1796: row 64, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1804: byte 112
                sty     <VIA_port_b             ;  6 t = 1808: row 65, X speed -80
                ldb     ,x+                     ;  6 t = 1814: byte 113
                stb     <VIA_shift_reg          ;  4 t = 1820: byte 113
                lda     ,x+                     ;  6 t = 1824: byte 114
                ldb     ,x+                     ;  6 t = 1830: byte 115
                sta     <VIA_shift_reg          ;  4 t = 1836: byte 114
                stu     <VIA_port_b             ;  5 t = 1840: row 66, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1852: byte 115
                lda     ,x+                     ;  6 t = 1856: byte 116
                ldb     ,x+                     ;  6 t = 1862: byte 117
                sta     <VIA_shift_reg          ;  4 t = 1868: byte 116
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1876: row 67, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1884: byte 117
                lda     ,x+                     ;  6 t = 1888: byte 118
                ldb     ,x+                     ;  6 t = 1894: byte 119
                sta     <VIA_shift_reg          ;  4 t = 1900: byte 118
                stu     <VIA_port_b             ;  5 t = 1904: row 68, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1916: byte 119
                lda     ,x+                     ;  6 t = 1920: byte 120
                ldb     ,x+                     ;  6 t = 1926: byte 121
                sta     <VIA_shift_reg          ;  4 t = 1932: byte 120
                sty     <VIA_port_b             ;  6 t = 1936: row 69, X speed -80
                lda     ,x+                     ;  6 t = 1942: byte 122
                stb     <VIA_shift_reg          ;  4 t = 1948: byte 121
                ldb     ,x+                     ;  6 t = 1952: byte 123
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1964: byte 122
                stu     <VIA_port_b             ;  5 t = 1968: row 70, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1980: byte 123
                lda     ,x+                     ;  6 t = 1984: byte 124
                ldb     ,x+                     ;  6 t = 1990: byte 125
                sta     <VIA_shift_reg          ;  4 t = 1996: byte 124
                sty     <VIA_port_b             ;  6 t = 2000: row 71, X speed -80
                lda     ,x+                     ;  6 t = 2006: byte 126
                stb     <VIA_shift_reg          ;  4 t = 2012: byte 125
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 2020: row 72, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2028: byte 126
                sty     <VIA_port_b             ;  6 t = 2032: row 73, X speed -80
                ldb     ,x+                     ;  6 t = 2038: byte 127
                stb     <VIA_shift_reg          ;  4 t = 2044: byte 127
                lda     ,x+                     ;  6 t = 2048: byte 128
                ldb     ,x+                     ;  6 t = 2054: byte 129
                sta     <VIA_shift_reg          ;  4 t = 2060: byte 128
                stu     <VIA_port_b             ;  5 t = 2064: row 74, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2076: byte 129
                lda     ,x+                     ;  6 t = 2080: byte 130
                ldb     ,x+                     ;  6 t = 2086: byte 131
                sta     <VIA_shift_reg          ;  4 t = 2092: byte 130
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 2100: row 75, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2108: byte 131
                lda     ,x+                     ;  6 t = 2112: byte 132
                ldb     ,x+                     ;  6 t = 2118: byte 133
                sta     <VIA_shift_reg          ;  4 t = 2124: byte 132
                stu     <VIA_port_b             ;  5 t = 2128: row 76, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2140: byte 133
                lda     ,x+                     ;  6 t = 2144: byte 134
                ldb     ,x+                     ;  6 t = 2150: byte 135
                sta     <VIA_shift_reg          ;  4 t = 2156: byte 134
                sty     <VIA_port_b             ;  6 t = 2160: row 77, X speed -80
                lda     ,x+                     ;  6 t = 2166: byte 136
                stb     <VIA_shift_reg          ;  4 t = 2172: byte 135
                ldb     ,x+                     ;  6 t = 2176: byte 137
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2188: byte 136
                stu     <VIA_port_b             ;  5 t = 2192: row 78, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2204: byte 137
                lda     ,x+                     ;  6 t = 2208: byte 138
                ldb     ,x+                     ;  6 t = 2214: byte 139
                sta     <VIA_shift_reg          ;  4 t = 2220: byte 138
                sty     <VIA_port_b             ;  6 t = 2224: row 79, X speed -80
                lda     ,x+                     ;  6 t = 2230: byte 140
                stb     <VIA_shift_reg          ;  4 t = 2236: byte 139
                nop                             ;  2 
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 2245: ramp off
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2252: byte 140
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 10 x 15: 16 rows (pitch 1.02 pixels), drift 6, 28 bytes: ramp on 435 cycles
; in: X = the data, the beam at the sprite's top left
zig_bulb
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
                ldy     #$80FA                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -6 (the drift down)
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 bytes 0 and 1
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                sty     <VIA_port_b             ;  6 t = 16: row 1, X speed -80
                lda     ,x+                     ;  6 t = 22: byte 2
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                stu     <VIA_port_b             ;  5 t = 32: row 2, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                ldb     ,x+                     ;  6 t = 48: byte 3
                sty     <VIA_port_b             ;  6 t = 54: row 3, X speed -80
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                lda     ,x+                     ;  6 t = 64: byte 4
                ldb     ,x+                     ;  6 t = 70: byte 5
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                stu     <VIA_port_b             ;  5 t = 80: row 4, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 t = 96: byte 6
                sty     <VIA_port_b             ;  6 t = 102: row 5, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                ldb     ,x+                     ;  6 t = 112: byte 7
                lda     ,x+                     ;  6 t = 118: byte 8
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                stu     <VIA_port_b             ;  5 t = 128: row 6, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                ldb     ,x+                     ;  6 t = 144: byte 9
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                sty     <VIA_port_b             ;  6 t = 160: row 7, X speed -80
                ldb     ,x+                     ;  6 t = 166: byte 11
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 183: row 8, X speed +80
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                lda     ,x+                     ;  6 t = 192: byte 12
                ldb     ,x+                     ;  6 t = 198: byte 13
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                sty     <VIA_port_b             ;  6 t = 208: row 9, X speed -80
                lda     ,x+                     ;  6 t = 214: byte 14
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                stu     <VIA_port_b             ;  5 t = 240: row 10, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                lda     ,x+                     ;  6 t = 256: byte 16
                ldb     ,x+                     ;  6 t = 262: byte 17
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                sty     <VIA_port_b             ;  6 t = 272: row 11, X speed -80
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                ldb     ,x+                     ;  6 t = 288: byte 19
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                stu     <VIA_port_b             ;  5 t = 304: row 12, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                lda     ,x+                     ;  6 t = 320: byte 20
                ldb     ,x+                     ;  6 t = 326: byte 21
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                sty     <VIA_port_b             ;  6 t = 336: row 13, X speed -80
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                stu     <VIA_port_b             ;  5 t = 368: row 14, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                lda     ,x+                     ;  6 t = 384: byte 24
                ldb     ,x+                     ;  6 t = 390: byte 25
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                sty     <VIA_port_b             ;  6 t = 400: row 15, X speed -80
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 435: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

