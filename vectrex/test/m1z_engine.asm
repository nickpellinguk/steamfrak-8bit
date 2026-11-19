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

; a zigzag sprite, 26 x 34: 139 rows (pitch 0.25 pixels), drift 1, 342 bytes: ramp on 5459 cycles
; in: X = the data, the beam at the sprite's top left
zig_trogg_1
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
                ldy     #$80FF                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -1 (the drift down)
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
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 66: row 2, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                ldb     ,x+                     ;  6 t = 80: byte 5
                sty     <VIA_port_b             ;  6 t = 86: row 3, X speed -80
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 t = 96: byte 6
                ldb     ,x+                     ;  6 t = 102: byte 7
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                stu     <VIA_port_b             ;  5 t = 112: row 4, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                lda     ,x+                     ;  6 t = 128: byte 8
                sty     <VIA_port_b             ;  6 t = 134: row 5, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                ldb     ,x+                     ;  6 t = 144: byte 9
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                stu     <VIA_port_b             ;  5 t = 160: row 6, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                ldb     ,x+                     ;  6 t = 176: byte 11
                sty     <VIA_port_b             ;  6 t = 182: row 7, X speed -80
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                lda     ,x+                     ;  6 t = 192: byte 12
                ldb     ,x+                     ;  6 t = 198: byte 13
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                stu     <VIA_port_b             ;  5 t = 208: row 8, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                lda     ,x+                     ;  6 t = 224: byte 14
                ldb     ,x+                     ;  6 t = 230: byte 15
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                sty     <VIA_port_b             ;  6 t = 240: row 9, X speed -80
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 436: row 15, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                lda     ,x+                     ;  6 t = 448: byte 28
                ldb     ,x+                     ;  6 t = 454: byte 29
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 468: row 16, X speed +80
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                lda     ,x+                     ;  6 t = 480: byte 30
                ldb     ,x+                     ;  6 t = 486: byte 31
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 500: row 17, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                lda     ,x+                     ;  6 t = 512: byte 32
                ldb     ,x+                     ;  6 t = 518: byte 33
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 532: row 18, X speed +80
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                lda     ,x+                     ;  6 t = 544: byte 34
                ldb     ,x+                     ;  6 t = 550: byte 35
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 564: row 19, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                lda     ,x+                     ;  6 t = 576: byte 36
                ldb     ,x+                     ;  6 t = 582: byte 37
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                lda     ,x+                     ;  6 t = 592: byte 38
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                stu     <VIA_port_b             ;  5 t = 608: row 20, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 656: row 21, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 704: row 22, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 752: row 23, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 800: row 24, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 848: row 25, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 896: row 26, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 944: row 27, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 992: row 28, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 1040: row 29, X speed -80
                lda     ,x+                     ;  6 t = 1046: byte 66
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                ldb     ,x+                     ;  6 t = 1056: byte 67
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                lda     ,x+                     ;  6 t = 1072: byte 68
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                stu     <VIA_port_b             ;  5 t = 1088: row 30, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                ldb     ,x+                     ;  6 t = 1104: byte 69
                lda     ,x+                     ;  6 t = 1110: byte 70
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1124: row 31, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                ldb     ,x+                     ;  6 t = 1136: byte 71
                lda     ,x+                     ;  6 t = 1142: byte 72
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1154: row 32, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                ldb     ,x+                     ;  6 t = 1168: byte 73
                lda     ,x+                     ;  6 t = 1174: byte 74
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                sty     <VIA_port_b             ;  6 t = 1184: row 33, X speed -80
                ldb     ,x+                     ;  6 t = 1190: byte 75
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                lda     ,x+                     ;  6 t = 1200: byte 76
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1218: row 34, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                ldb     ,x+                     ;  6 t = 1232: byte 77
                lda     ,x+                     ;  6 t = 1238: byte 78
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1250: row 35, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                ldb     ,x+                     ;  6 t = 1264: byte 79
                lda     ,x+                     ;  6 t = 1270: byte 80
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1282: row 36, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                ldb     ,x+                     ;  6 t = 1296: byte 81
                lda     ,x+                     ;  6 t = 1302: byte 82
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1314: row 37, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                ldb     ,x+                     ;  6 t = 1328: byte 83
                lda     ,x+                     ;  6 t = 1334: byte 84
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1346: row 38, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                ldb     ,x+                     ;  6 t = 1360: byte 85
                lda     ,x+                     ;  6 t = 1366: byte 86
                stb     <VIA_shift_reg          ;  4 t = 1372: byte 85
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1378: row 39, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1388: byte 86
                ldb     ,x+                     ;  6 t = 1392: byte 87
                lda     ,x+                     ;  6 t = 1398: byte 88
                stb     <VIA_shift_reg          ;  4 t = 1404: byte 87
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1412: row 40, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                ldb     ,x+                     ;  6 t = 1424: byte 89
                lda     ,x+                     ;  6 t = 1430: byte 90
                stb     <VIA_shift_reg          ;  4 t = 1436: byte 89
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1444: row 41, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1452: byte 90
                ldb     ,x+                     ;  6 t = 1456: byte 91
                lda     ,x+                     ;  6 t = 1462: byte 92
                stb     <VIA_shift_reg          ;  4 t = 1468: byte 91
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1476: row 42, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1484: byte 92
                ldb     ,x+                     ;  6 t = 1488: byte 93
                lda     ,x+                     ;  6 t = 1494: byte 94
                stb     <VIA_shift_reg          ;  4 t = 1500: byte 93
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1508: row 43, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1516: byte 94
                ldb     ,x+                     ;  6 t = 1520: byte 95
                lda     ,x+                     ;  6 t = 1526: byte 96
                stb     <VIA_shift_reg          ;  4 t = 1532: byte 95
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 1543: row 44, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 1548: byte 96
                ldb     ,x+                     ;  6 t = 1552: byte 97
                lda     ,x+                     ;  6 t = 1558: byte 98
                stb     <VIA_shift_reg          ;  4 t = 1564: byte 97
                ldb     ,x+                     ;  6 t = 1568: byte 99
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1580: byte 98
                sty     <VIA_port_b             ;  6 t = 1584: row 45, X speed -80
                lda     ,x+                     ;  6 t = 1590: byte 100
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
                stu     <VIA_port_b             ;  5 t = 1632: row 46, X speed +80
                nop                             ;  2 
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
                sty     <VIA_port_b             ;  6 t = 1680: row 47, X speed -80
                lda     ,x+                     ;  6 t = 1686: byte 106
                stb     <VIA_shift_reg          ;  4 t = 1692: byte 105
                ldb     ,x+                     ;  6 t = 1696: byte 107
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1708: byte 106
                lda     ,x+                     ;  6 t = 1712: byte 108
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1724: byte 107
                stu     <VIA_port_b             ;  5 t = 1728: row 48, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1740: byte 108
                ldb     ,x+                     ;  6 t = 1744: byte 109
                lda     ,x+                     ;  6 t = 1750: byte 110
                stb     <VIA_shift_reg          ;  4 t = 1756: byte 109
                ldb     ,x+                     ;  6 t = 1760: byte 111
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1772: byte 110
                sty     <VIA_port_b             ;  6 t = 1776: row 49, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 1824: row 50, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1836: byte 114
                ldb     ,x+                     ;  6 t = 1840: byte 115
                lda     ,x+                     ;  6 t = 1846: byte 116
                stb     <VIA_shift_reg          ;  4 t = 1852: byte 115
                ldb     ,x+                     ;  6 t = 1856: byte 117
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1868: byte 116
                sty     <VIA_port_b             ;  6 t = 1872: row 51, X speed -80
                lda     ,x+                     ;  6 t = 1878: byte 118
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
                stu     <VIA_port_b             ;  5 t = 1920: row 52, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 1968: row 53, X speed -80
                lda     ,x+                     ;  6 t = 1974: byte 124
                stb     <VIA_shift_reg          ;  4 t = 1980: byte 123
                ldb     ,x+                     ;  6 t = 1984: byte 125
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1996: byte 124
                lda     ,x+                     ;  6 t = 2000: byte 126
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2012: byte 125
                stu     <VIA_port_b             ;  5 t = 2016: row 54, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2028: byte 126
                ldb     ,x+                     ;  6 t = 2032: byte 127
                lda     ,x+                     ;  6 t = 2038: byte 128
                stb     <VIA_shift_reg          ;  4 t = 2044: byte 127
                ldb     ,x+                     ;  6 t = 2048: byte 129
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2060: byte 128
                sty     <VIA_port_b             ;  6 t = 2064: row 55, X speed -80
                lda     ,x+                     ;  6 t = 2070: byte 130
                stb     <VIA_shift_reg          ;  4 t = 2076: byte 129
                ldb     ,x+                     ;  6 t = 2080: byte 131
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2092: byte 130
                lda     ,x+                     ;  6 t = 2096: byte 132
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2108: byte 131
                stu     <VIA_port_b             ;  5 t = 2112: row 56, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2124: byte 132
                ldb     ,x+                     ;  6 t = 2128: byte 133
                lda     ,x+                     ;  6 t = 2134: byte 134
                stb     <VIA_shift_reg          ;  4 t = 2140: byte 133
                ldb     ,x+                     ;  6 t = 2144: byte 135
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2156: byte 134
                sty     <VIA_port_b             ;  6 t = 2160: row 57, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 2208: row 58, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2220: byte 138
                ldb     ,x+                     ;  6 t = 2224: byte 139
                lda     ,x+                     ;  6 t = 2230: byte 140
                stb     <VIA_shift_reg          ;  4 t = 2236: byte 139
                ldb     ,x+                     ;  6 t = 2240: byte 141
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2252: byte 140
                sty     <VIA_port_b             ;  6 t = 2256: row 59, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 2304: row 60, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2316: byte 144
                ldb     ,x+                     ;  6 t = 2320: byte 145
                lda     ,x+                     ;  6 t = 2326: byte 146
                stb     <VIA_shift_reg          ;  4 t = 2332: byte 145
                ldb     ,x+                     ;  6 t = 2336: byte 147
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2348: byte 146
                sty     <VIA_port_b             ;  6 t = 2352: row 61, X speed -80
                lda     ,x+                     ;  6 t = 2358: byte 148
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
                stu     <VIA_port_b             ;  5 t = 2400: row 62, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 2448: row 63, X speed -80
                lda     ,x+                     ;  6 t = 2454: byte 154
                stb     <VIA_shift_reg          ;  4 t = 2460: byte 153
                ldb     ,x+                     ;  6 t = 2464: byte 155
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2476: byte 154
                lda     ,x+                     ;  6 t = 2480: byte 156
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2492: byte 155
                stu     <VIA_port_b             ;  5 t = 2496: row 64, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2508: byte 156
                ldb     ,x+                     ;  6 t = 2512: byte 157
                lda     ,x+                     ;  6 t = 2518: byte 158
                stb     <VIA_shift_reg          ;  4 t = 2524: byte 157
                ldb     ,x+                     ;  6 t = 2528: byte 159
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2540: byte 158
                sty     <VIA_port_b             ;  6 t = 2544: row 65, X speed -80
                lda     ,x+                     ;  6 t = 2550: byte 160
                stb     <VIA_shift_reg          ;  4 t = 2556: byte 159
                ldb     ,x+                     ;  6 t = 2560: byte 161
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2572: byte 160
                lda     ,x+                     ;  6 t = 2576: byte 162
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2588: byte 161
                stu     <VIA_port_b             ;  5 t = 2592: row 66, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2604: byte 162
                ldb     ,x+                     ;  6 t = 2608: byte 163
                lda     ,x+                     ;  6 t = 2614: byte 164
                stb     <VIA_shift_reg          ;  4 t = 2620: byte 163
                ldb     ,x+                     ;  6 t = 2624: byte 165
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2636: byte 164
                sty     <VIA_port_b             ;  6 t = 2640: row 67, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 2688: row 68, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2700: byte 168
                ldb     ,x+                     ;  6 t = 2704: byte 169
                lda     ,x+                     ;  6 t = 2710: byte 170
                stb     <VIA_shift_reg          ;  4 t = 2716: byte 169
                ldb     ,x+                     ;  6 t = 2720: byte 171
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2732: byte 170
                sty     <VIA_port_b             ;  6 t = 2736: row 69, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 2784: row 70, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2796: byte 174
                ldb     ,x+                     ;  6 t = 2800: byte 175
                lda     ,x+                     ;  6 t = 2806: byte 176
                stb     <VIA_shift_reg          ;  4 t = 2812: byte 175
                ldb     ,x+                     ;  6 t = 2816: byte 177
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2828: byte 176
                sty     <VIA_port_b             ;  6 t = 2832: row 71, X speed -80
                lda     ,x+                     ;  6 t = 2838: byte 178
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
                stu     <VIA_port_b             ;  5 t = 2880: row 72, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 2928: row 73, X speed -80
                lda     ,x+                     ;  6 t = 2934: byte 184
                stb     <VIA_shift_reg          ;  4 t = 2940: byte 183
                ldb     ,x+                     ;  6 t = 2944: byte 185
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2956: byte 184
                lda     ,x+                     ;  6 t = 2960: byte 186
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2972: byte 185
                stu     <VIA_port_b             ;  5 t = 2976: row 74, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2988: byte 186
                ldb     ,x+                     ;  6 t = 2992: byte 187
                lda     ,x+                     ;  6 t = 2998: byte 188
                stb     <VIA_shift_reg          ;  4 t = 3004: byte 187
                ldb     ,x+                     ;  6 t = 3008: byte 189
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3020: byte 188
                sty     <VIA_port_b             ;  6 t = 3024: row 75, X speed -80
                lda     ,x+                     ;  6 t = 3030: byte 190
                stb     <VIA_shift_reg          ;  4 t = 3036: byte 189
                ldb     ,x+                     ;  6 t = 3040: byte 191
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3052: byte 190
                lda     ,x+                     ;  6 t = 3056: byte 192
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3068: byte 191
                stu     <VIA_port_b             ;  5 t = 3072: row 76, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 3084: byte 192
                ldb     ,x+                     ;  6 t = 3088: byte 193
                lda     ,x+                     ;  6 t = 3094: byte 194
                stb     <VIA_shift_reg          ;  4 t = 3100: byte 193
                ldb     ,x+                     ;  6 t = 3104: byte 195
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3116: byte 194
                sty     <VIA_port_b             ;  6 t = 3120: row 77, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 3168: row 78, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 3180: byte 198
                ldb     ,x+                     ;  6 t = 3184: byte 199
                lda     ,x+                     ;  6 t = 3190: byte 200
                stb     <VIA_shift_reg          ;  4 t = 3196: byte 199
                ldb     ,x+                     ;  6 t = 3200: byte 201
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3212: byte 200
                sty     <VIA_port_b             ;  6 t = 3216: row 79, X speed -80
                lda     ,x+                     ;  6 t = 3222: byte 202
                stb     <VIA_shift_reg          ;  4 t = 3228: byte 201
                ldb     ,x+                     ;  6 t = 3232: byte 203
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3244: byte 202
                lda     ,x+                     ;  6 t = 3248: byte 204
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3260: byte 203
                stu     <VIA_port_b             ;  5 t = 3264: row 80, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 3276: byte 204
                ldb     ,x+                     ;  6 t = 3280: byte 205
                lda     ,x+                     ;  6 t = 3286: byte 206
                stb     <VIA_shift_reg          ;  4 t = 3292: byte 205
                ldb     ,x+                     ;  6 t = 3296: byte 207
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3308: byte 206
                sty     <VIA_port_b             ;  6 t = 3312: row 81, X speed -80
                lda     ,x+                     ;  6 t = 3318: byte 208
                stb     <VIA_shift_reg          ;  4 t = 3324: byte 207
                ldb     ,x+                     ;  6 t = 3328: byte 209
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3340: byte 208
                lda     ,x+                     ;  6 t = 3344: byte 210
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3356: byte 209
                stu     <VIA_port_b             ;  5 t = 3360: row 82, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 3372: byte 210
                ldb     ,x+                     ;  6 t = 3376: byte 211
                lda     ,x+                     ;  6 t = 3382: byte 212
                stb     <VIA_shift_reg          ;  4 t = 3388: byte 211
                ldb     ,x+                     ;  6 t = 3392: byte 213
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3404: byte 212
                sty     <VIA_port_b             ;  6 t = 3408: row 83, X speed -80
                lda     ,x+                     ;  6 t = 3414: byte 214
                stb     <VIA_shift_reg          ;  4 t = 3420: byte 213
                ldb     ,x+                     ;  6 t = 3424: byte 215
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3436: byte 214
                lda     ,x+                     ;  6 t = 3440: byte 216
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3452: byte 215
                stu     <VIA_port_b             ;  5 t = 3456: row 84, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 3468: byte 216
                ldb     ,x+                     ;  6 t = 3472: byte 217
                lda     ,x+                     ;  6 t = 3478: byte 218
                stb     <VIA_shift_reg          ;  4 t = 3484: byte 217
                ldb     ,x+                     ;  6 t = 3488: byte 219
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3500: byte 218
                sty     <VIA_port_b             ;  6 t = 3504: row 85, X speed -80
                lda     ,x+                     ;  6 t = 3510: byte 220
                stb     <VIA_shift_reg          ;  4 t = 3516: byte 219
                ldb     ,x+                     ;  6 t = 3520: byte 221
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3532: byte 220
                lda     ,x+                     ;  6 t = 3536: byte 222
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3548: byte 221
                stu     <VIA_port_b             ;  5 t = 3552: row 86, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 3564: byte 222
                ldb     ,x+                     ;  6 t = 3568: byte 223
                lda     ,x+                     ;  6 t = 3574: byte 224
                stb     <VIA_shift_reg          ;  4 t = 3580: byte 223
                ldb     ,x+                     ;  6 t = 3584: byte 225
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3596: byte 224
                sty     <VIA_port_b             ;  6 t = 3600: row 87, X speed -80
                lda     ,x+                     ;  6 t = 3606: byte 226
                stb     <VIA_shift_reg          ;  4 t = 3612: byte 225
                ldb     ,x+                     ;  6 t = 3616: byte 227
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3628: byte 226
                lda     ,x+                     ;  6 t = 3632: byte 228
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3644: byte 227
                stu     <VIA_port_b             ;  5 t = 3648: row 88, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 3660: byte 228
                ldb     ,x+                     ;  6 t = 3664: byte 229
                lda     ,x+                     ;  6 t = 3670: byte 230
                stb     <VIA_shift_reg          ;  4 t = 3676: byte 229
                ldb     ,x+                     ;  6 t = 3680: byte 231
                sty     <VIA_port_b             ;  6 t = 3686: row 89, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 3692: byte 230
                lda     ,x+                     ;  6 t = 3696: byte 232
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3708: byte 231
                ldb     ,x+                     ;  6 t = 3712: byte 233
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3724: byte 232
                stu     <VIA_port_b             ;  5 t = 3728: row 90, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 3740: byte 233
                lda     ,x+                     ;  6 t = 3744: byte 234
                ldb     ,x+                     ;  6 t = 3750: byte 235
                sta     <VIA_shift_reg          ;  4 t = 3756: byte 234
                lda     ,x+                     ;  6 t = 3760: byte 236
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3772: byte 235
                sty     <VIA_port_b             ;  6 t = 3776: row 91, X speed -80
                ldb     ,x+                     ;  6 t = 3782: byte 237
                sta     <VIA_shift_reg          ;  4 t = 3788: byte 236
                lda     ,x+                     ;  6 t = 3792: byte 238
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3804: byte 237
                ldb     ,x+                     ;  6 t = 3808: byte 239
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3820: byte 238
                stu     <VIA_port_b             ;  5 t = 3824: row 92, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 3836: byte 239
                lda     ,x+                     ;  6 t = 3840: byte 240
                ldb     ,x+                     ;  6 t = 3846: byte 241
                sta     <VIA_shift_reg          ;  4 t = 3852: byte 240
                lda     ,x+                     ;  6 t = 3856: byte 242
                sty     <VIA_port_b             ;  6 t = 3862: row 93, X speed -80
                stb     <VIA_shift_reg          ;  4 t = 3868: byte 241
                ldb     ,x+                     ;  6 t = 3872: byte 243
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3884: byte 242
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 3895: row 94, X speed +80
                stb     <VIA_shift_reg          ;  4 t = 3900: byte 243
                lda     ,x+                     ;  6 t = 3904: byte 244
                ldb     ,x+                     ;  6 t = 3910: byte 245
                sta     <VIA_shift_reg          ;  4 t = 3916: byte 244
                lda     ,x+                     ;  6 t = 3920: byte 246
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3932: byte 245
                sty     <VIA_port_b             ;  6 t = 3936: row 95, X speed -80
                ldb     ,x+                     ;  6 t = 3942: byte 247
                sta     <VIA_shift_reg          ;  4 t = 3948: byte 246
                lda     ,x+                     ;  6 t = 3952: byte 248
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3964: byte 247
                ldb     ,x+                     ;  6 t = 3968: byte 249
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3980: byte 248
                stu     <VIA_port_b             ;  5 t = 3984: row 96, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 3996: byte 249
                lda     ,x+                     ;  6 t = 4000: byte 250
                ldb     ,x+                     ;  6 t = 4006: byte 251
                sta     <VIA_shift_reg          ;  4 t = 4012: byte 250
                lda     ,x+                     ;  6 t = 4016: byte 252
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4028: byte 251
                sty     <VIA_port_b             ;  6 t = 4032: row 97, X speed -80
                ldb     ,x+                     ;  6 t = 4038: byte 253
                sta     <VIA_shift_reg          ;  4 t = 4044: byte 252
                lda     ,x+                     ;  6 t = 4048: byte 254
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4060: byte 253
                ldb     ,x+                     ;  6 t = 4064: byte 255
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4076: byte 254
                stu     <VIA_port_b             ;  5 t = 4080: row 98, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 4092: byte 255
                lda     ,x+                     ;  6 t = 4096: byte 256
                ldb     ,x+                     ;  6 t = 4102: byte 257
                sta     <VIA_shift_reg          ;  4 t = 4108: byte 256
                lda     ,x+                     ;  6 t = 4112: byte 258
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4124: byte 257
                sty     <VIA_port_b             ;  6 t = 4128: row 99, X speed -80
                ldb     ,x+                     ;  6 t = 4134: byte 259
                sta     <VIA_shift_reg          ;  4 t = 4140: byte 258
                lda     ,x+                     ;  6 t = 4144: byte 260
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4156: byte 259
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 4167: row 100, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 4172: byte 260
                ldb     ,x+                     ;  6 t = 4176: byte 261
                lda     ,x+                     ;  6 t = 4182: byte 262
                stb     <VIA_shift_reg          ;  4 t = 4188: byte 261
                ldb     ,x+                     ;  6 t = 4192: byte 263
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4204: byte 262
                sty     <VIA_port_b             ;  6 t = 4208: row 101, X speed -80
                lda     ,x+                     ;  6 t = 4214: byte 264
                stb     <VIA_shift_reg          ;  4 t = 4220: byte 263
                ldb     ,x+                     ;  6 t = 4224: byte 265
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4236: byte 264
                lda     ,x+                     ;  6 t = 4240: byte 266
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4252: byte 265
                stu     <VIA_port_b             ;  5 t = 4256: row 102, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 4268: byte 266
                ldb     ,x+                     ;  6 t = 4272: byte 267
                lda     ,x+                     ;  6 t = 4278: byte 268
                stb     <VIA_shift_reg          ;  4 t = 4284: byte 267
                ldb     ,x+                     ;  6 t = 4288: byte 269
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4300: byte 268
                sty     <VIA_port_b             ;  6 t = 4304: row 103, X speed -80
                lda     ,x+                     ;  6 t = 4310: byte 270
                stb     <VIA_shift_reg          ;  4 t = 4316: byte 269
                ldb     ,x+                     ;  6 t = 4320: byte 271
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4332: byte 270
                stu     <VIA_port_b             ;  5 t = 4336: row 104, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 4348: byte 271
                lda     ,x+                     ;  6 t = 4352: byte 272
                ldb     ,x+                     ;  6 t = 4358: byte 273
                sta     <VIA_shift_reg          ;  4 t = 4364: byte 272
                sty     <VIA_port_b             ;  6 t = 4368: row 105, X speed -80
                lda     ,x+                     ;  6 t = 4374: byte 274
                stb     <VIA_shift_reg          ;  4 t = 4380: byte 273
                ldb     ,x+                     ;  6 t = 4384: byte 275
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4396: byte 274
                stu     <VIA_port_b             ;  5 t = 4400: row 106, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 4412: byte 275
                lda     ,x+                     ;  6 t = 4416: byte 276
                ldb     ,x+                     ;  6 t = 4422: byte 277
                sta     <VIA_shift_reg          ;  4 t = 4428: byte 276
                sty     <VIA_port_b             ;  6 t = 4432: row 107, X speed -80
                lda     ,x+                     ;  6 t = 4438: byte 278
                stb     <VIA_shift_reg          ;  4 t = 4444: byte 277
                ldb     ,x+                     ;  6 t = 4448: byte 279
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4460: byte 278
                stu     <VIA_port_b             ;  5 t = 4464: row 108, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 4476: byte 279
                lda     ,x+                     ;  6 t = 4480: byte 280
                ldb     ,x+                     ;  6 t = 4486: byte 281
                sta     <VIA_shift_reg          ;  4 t = 4492: byte 280
                sty     <VIA_port_b             ;  6 t = 4496: row 109, X speed -80
                lda     ,x+                     ;  6 t = 4502: byte 282
                stb     <VIA_shift_reg          ;  4 t = 4508: byte 281
                ldb     ,x+                     ;  6 t = 4512: byte 283
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4524: byte 282
                stu     <VIA_port_b             ;  5 t = 4528: row 110, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 4540: byte 283
                lda     ,x+                     ;  6 t = 4544: byte 284
                ldb     ,x+                     ;  6 t = 4550: byte 285
                sta     <VIA_shift_reg          ;  4 t = 4556: byte 284
                sty     <VIA_port_b             ;  6 t = 4560: row 111, X speed -80
                lda     ,x+                     ;  6 t = 4566: byte 286
                stb     <VIA_shift_reg          ;  4 t = 4572: byte 285
                ldb     ,x+                     ;  6 t = 4576: byte 287
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4588: byte 286
                stu     <VIA_port_b             ;  5 t = 4592: row 112, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 4604: byte 287
                lda     ,x+                     ;  6 t = 4608: byte 288
                ldb     ,x+                     ;  6 t = 4614: byte 289
                sta     <VIA_shift_reg          ;  4 t = 4620: byte 288
                sty     <VIA_port_b             ;  6 t = 4624: row 113, X speed -80
                lda     ,x+                     ;  6 t = 4630: byte 290
                stb     <VIA_shift_reg          ;  4 t = 4636: byte 289
                ldb     ,x+                     ;  6 t = 4640: byte 291
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4652: byte 290
                stu     <VIA_port_b             ;  5 t = 4656: row 114, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 4668: byte 291
                lda     ,x+                     ;  6 t = 4672: byte 292
                ldb     ,x+                     ;  6 t = 4678: byte 293
                sta     <VIA_shift_reg          ;  4 t = 4684: byte 292
                sty     <VIA_port_b             ;  6 t = 4688: row 115, X speed -80
                lda     ,x+                     ;  6 t = 4694: byte 294
                stb     <VIA_shift_reg          ;  4 t = 4700: byte 293
                ldb     ,x+                     ;  6 t = 4704: byte 295
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4716: byte 294
                stu     <VIA_port_b             ;  5 t = 4720: row 116, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 4732: byte 295
                lda     ,x+                     ;  6 t = 4736: byte 296
                ldb     ,x+                     ;  6 t = 4742: byte 297
                sta     <VIA_shift_reg          ;  4 t = 4748: byte 296
                sty     <VIA_port_b             ;  6 t = 4752: row 117, X speed -80
                lda     ,x+                     ;  6 t = 4758: byte 298
                stb     <VIA_shift_reg          ;  4 t = 4764: byte 297
                ldb     ,x+                     ;  6 t = 4768: byte 299
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4780: byte 298
                stu     <VIA_port_b             ;  5 t = 4784: row 118, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 4796: byte 299
                lda     ,x+                     ;  6 t = 4800: byte 300
                ldb     ,x+                     ;  6 t = 4806: byte 301
                sta     <VIA_shift_reg          ;  4 t = 4812: byte 300
                sty     <VIA_port_b             ;  6 t = 4816: row 119, X speed -80
                lda     ,x+                     ;  6 t = 4822: byte 302
                stb     <VIA_shift_reg          ;  4 t = 4828: byte 301
                ldb     ,x+                     ;  6 t = 4832: byte 303
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4844: byte 302
                stu     <VIA_port_b             ;  5 t = 4848: row 120, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 4860: byte 303
                lda     ,x+                     ;  6 t = 4864: byte 304
                ldb     ,x+                     ;  6 t = 4870: byte 305
                sta     <VIA_shift_reg          ;  4 t = 4876: byte 304
                sty     <VIA_port_b             ;  6 t = 4880: row 121, X speed -80
                lda     ,x+                     ;  6 t = 4886: byte 306
                stb     <VIA_shift_reg          ;  4 t = 4892: byte 305
                ldb     ,x+                     ;  6 t = 4896: byte 307
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4908: byte 306
                stu     <VIA_port_b             ;  5 t = 4912: row 122, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 4924: byte 307
                lda     ,x+                     ;  6 t = 4928: byte 308
                ldb     ,x+                     ;  6 t = 4934: byte 309
                sta     <VIA_shift_reg          ;  4 t = 4940: byte 308
                sty     <VIA_port_b             ;  6 t = 4944: row 123, X speed -80
                lda     ,x+                     ;  6 t = 4950: byte 310
                stb     <VIA_shift_reg          ;  4 t = 4956: byte 309
                ldb     ,x+                     ;  6 t = 4960: byte 311
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4972: byte 310
                stu     <VIA_port_b             ;  5 t = 4976: row 124, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 4988: byte 311
                lda     ,x+                     ;  6 t = 4992: byte 312
                ldb     ,x+                     ;  6 t = 4998: byte 313
                sta     <VIA_shift_reg          ;  4 t = 5004: byte 312
                sty     <VIA_port_b             ;  6 t = 5008: row 125, X speed -80
                lda     ,x+                     ;  6 t = 5014: byte 314
                stb     <VIA_shift_reg          ;  4 t = 5020: byte 313
                ldb     ,x+                     ;  6 t = 5024: byte 315
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5036: byte 314
                stu     <VIA_port_b             ;  5 t = 5040: row 126, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 5052: byte 315
                lda     ,x+                     ;  6 t = 5056: byte 316
                ldb     ,x+                     ;  6 t = 5062: byte 317
                sta     <VIA_shift_reg          ;  4 t = 5068: byte 316
                sty     <VIA_port_b             ;  6 t = 5072: row 127, X speed -80
                lda     ,x+                     ;  6 t = 5078: byte 318
                stb     <VIA_shift_reg          ;  4 t = 5084: byte 317
                ldb     ,x+                     ;  6 t = 5088: byte 319
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5100: byte 318
                stu     <VIA_port_b             ;  5 t = 5104: row 128, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 5116: byte 319
                lda     ,x+                     ;  6 t = 5120: byte 320
                ldb     ,x+                     ;  6 t = 5126: byte 321
                sta     <VIA_shift_reg          ;  4 t = 5132: byte 320
                sty     <VIA_port_b             ;  6 t = 5136: row 129, X speed -80
                lda     ,x+                     ;  6 t = 5142: byte 322
                stb     <VIA_shift_reg          ;  4 t = 5148: byte 321
                ldb     ,x+                     ;  6 t = 5152: byte 323
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5164: byte 322
                stu     <VIA_port_b             ;  5 t = 5168: row 130, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 5180: byte 323
                lda     ,x+                     ;  6 t = 5184: byte 324
                ldb     ,x+                     ;  6 t = 5190: byte 325
                sta     <VIA_shift_reg          ;  4 t = 5196: byte 324
                sty     <VIA_port_b             ;  6 t = 5200: row 131, X speed -80
                lda     ,x+                     ;  6 t = 5206: byte 326
                stb     <VIA_shift_reg          ;  4 t = 5212: byte 325
                ldb     ,x+                     ;  6 t = 5216: byte 327
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5228: byte 326
                stu     <VIA_port_b             ;  5 t = 5232: row 132, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 5244: byte 327
                lda     ,x+                     ;  6 t = 5248: byte 328
                ldb     ,x+                     ;  6 t = 5254: byte 329
                sta     <VIA_shift_reg          ;  4 t = 5260: byte 328
                sty     <VIA_port_b             ;  6 t = 5264: row 133, X speed -80
                lda     ,x+                     ;  6 t = 5270: byte 330
                stb     <VIA_shift_reg          ;  4 t = 5276: byte 329
                ldb     ,x+                     ;  6 t = 5280: byte 331
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5292: byte 330
                stu     <VIA_port_b             ;  5 t = 5296: row 134, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 5308: byte 331
                lda     ,x+                     ;  6 t = 5312: byte 332
                ldb     ,x+                     ;  6 t = 5318: byte 333
                sta     <VIA_shift_reg          ;  4 t = 5324: byte 332
                sty     <VIA_port_b             ;  6 t = 5328: row 135, X speed -80
                lda     ,x+                     ;  6 t = 5334: byte 334
                stb     <VIA_shift_reg          ;  4 t = 5340: byte 333
                ldb     ,x+                     ;  6 t = 5344: byte 335
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5356: byte 334
                stu     <VIA_port_b             ;  5 t = 5360: row 136, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 5372: byte 335
                lda     ,x+                     ;  6 t = 5376: byte 336
                ldb     ,x+                     ;  6 t = 5382: byte 337
                sta     <VIA_shift_reg          ;  4 t = 5388: byte 336
                sty     <VIA_port_b             ;  6 t = 5392: row 137, X speed -80
                lda     ,x+                     ;  6 t = 5398: byte 338
                stb     <VIA_shift_reg          ;  4 t = 5404: byte 337
                ldb     ,x+                     ;  6 t = 5408: byte 339
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5420: byte 338
                stu     <VIA_port_b             ;  5 t = 5424: row 138, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 5436: byte 339
                lda     ,x+                     ;  6 t = 5440: byte 340
                ldb     ,x+                     ;  6 t = 5446: byte 341
                sta     <VIA_shift_reg          ;  4 t = 5452: byte 340
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 5459: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5468: byte 341
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 26 x 34: 70 rows (pitch 0.49 pixels), drift 2, 172 bytes: ramp on 2739 cycles
; in: X = the data, the beam at the sprite's top left
zig_trogg_2
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
                sty     <VIA_port_b             ;  6 t = 48: row 1, X speed -80
                lda     ,x+                     ;  6 t = 54: byte 4
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 71: row 2, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                ldb     ,x+                     ;  6 t = 80: byte 5
                lda     ,x+                     ;  6 t = 86: byte 6
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                sty     <VIA_port_b             ;  6 t = 96: row 3, X speed -80
                ldb     ,x+                     ;  6 t = 102: byte 7
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                stu     <VIA_port_b             ;  5 t = 128: row 4, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                ldb     ,x+                     ;  6 t = 144: byte 9
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                sty     <VIA_port_b             ;  6 t = 160: row 5, X speed -80
                ldb     ,x+                     ;  6 t = 166: byte 11
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                stu     <VIA_port_b             ;  5 t = 192: row 6, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                ldb     ,x+                     ;  6 t = 208: byte 13
                lda     ,x+                     ;  6 t = 214: byte 14
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 226: row 7, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                ldb     ,x+                     ;  6 t = 240: byte 15
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 258: row 8, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                ldb     ,x+                     ;  6 t = 272: byte 17
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 290: row 9, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 327: row 10, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                ldb     ,x+                     ;  6 t = 336: byte 21
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                sty     <VIA_port_b             ;  6 t = 368: row 11, X speed -80
                lda     ,x+                     ;  6 t = 374: byte 24
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                ldb     ,x+                     ;  6 t = 384: byte 25
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                lda     ,x+                     ;  6 t = 400: byte 26
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                stu     <VIA_port_b             ;  5 t = 416: row 12, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                ldb     ,x+                     ;  6 t = 432: byte 27
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                sty     <VIA_port_b             ;  6 t = 464: row 13, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 512: row 14, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 560: row 15, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 608: row 16, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                ldb     ,x+                     ;  6 t = 624: byte 39
                lda     ,x+                     ;  6 t = 630: byte 40
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 642: row 17, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                ldb     ,x+                     ;  6 t = 656: byte 41
                lda     ,x+                     ;  6 t = 662: byte 42
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 674: row 18, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                ldb     ,x+                     ;  6 t = 688: byte 43
                lda     ,x+                     ;  6 t = 694: byte 44
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 706: row 19, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                ldb     ,x+                     ;  6 t = 720: byte 45
                lda     ,x+                     ;  6 t = 726: byte 46
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 740: row 20, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                ldb     ,x+                     ;  6 t = 752: byte 47
                lda     ,x+                     ;  6 t = 758: byte 48
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 772: row 21, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                ldb     ,x+                     ;  6 t = 784: byte 49
                lda     ,x+                     ;  6 t = 790: byte 50
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 807: row 22, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                ldb     ,x+                     ;  6 t = 816: byte 51
                lda     ,x+                     ;  6 t = 822: byte 52
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                sty     <VIA_port_b             ;  6 t = 848: row 23, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 896: row 24, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 944: row 25, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 992: row 26, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 1040: row 27, X speed -80
                lda     ,x+                     ;  6 t = 1046: byte 66
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                ldb     ,x+                     ;  6 t = 1056: byte 67
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                lda     ,x+                     ;  6 t = 1072: byte 68
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                stu     <VIA_port_b             ;  5 t = 1088: row 28, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                ldb     ,x+                     ;  6 t = 1104: byte 69
                lda     ,x+                     ;  6 t = 1110: byte 70
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                ldb     ,x+                     ;  6 t = 1120: byte 71
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                sty     <VIA_port_b             ;  6 t = 1136: row 29, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 1184: row 30, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                ldb     ,x+                     ;  6 t = 1200: byte 75
                lda     ,x+                     ;  6 t = 1206: byte 76
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                ldb     ,x+                     ;  6 t = 1216: byte 77
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                sty     <VIA_port_b             ;  6 t = 1232: row 31, X speed -80
                lda     ,x+                     ;  6 t = 1238: byte 78
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                ldb     ,x+                     ;  6 t = 1248: byte 79
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                lda     ,x+                     ;  6 t = 1264: byte 80
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                stu     <VIA_port_b             ;  5 t = 1280: row 32, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                ldb     ,x+                     ;  6 t = 1296: byte 81
                lda     ,x+                     ;  6 t = 1302: byte 82
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                ldb     ,x+                     ;  6 t = 1312: byte 83
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                sty     <VIA_port_b             ;  6 t = 1328: row 33, X speed -80
                lda     ,x+                     ;  6 t = 1334: byte 84
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
                stu     <VIA_port_b             ;  5 t = 1376: row 34, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 1424: row 35, X speed -80
                lda     ,x+                     ;  6 t = 1430: byte 90
                stb     <VIA_shift_reg          ;  4 t = 1436: byte 89
                ldb     ,x+                     ;  6 t = 1440: byte 91
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1452: byte 90
                lda     ,x+                     ;  6 t = 1456: byte 92
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1468: byte 91
                stu     <VIA_port_b             ;  5 t = 1472: row 36, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1484: byte 92
                ldb     ,x+                     ;  6 t = 1488: byte 93
                lda     ,x+                     ;  6 t = 1494: byte 94
                stb     <VIA_shift_reg          ;  4 t = 1500: byte 93
                ldb     ,x+                     ;  6 t = 1504: byte 95
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1516: byte 94
                sty     <VIA_port_b             ;  6 t = 1520: row 37, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 1568: row 38, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1580: byte 98
                ldb     ,x+                     ;  6 t = 1584: byte 99
                lda     ,x+                     ;  6 t = 1590: byte 100
                stb     <VIA_shift_reg          ;  4 t = 1596: byte 99
                ldb     ,x+                     ;  6 t = 1600: byte 101
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1612: byte 100
                sty     <VIA_port_b             ;  6 t = 1616: row 39, X speed -80
                lda     ,x+                     ;  6 t = 1622: byte 102
                stb     <VIA_shift_reg          ;  4 t = 1628: byte 101
                ldb     ,x+                     ;  6 t = 1632: byte 103
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1644: byte 102
                lda     ,x+                     ;  6 t = 1648: byte 104
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1660: byte 103
                stu     <VIA_port_b             ;  5 t = 1664: row 40, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1676: byte 104
                ldb     ,x+                     ;  6 t = 1680: byte 105
                lda     ,x+                     ;  6 t = 1686: byte 106
                stb     <VIA_shift_reg          ;  4 t = 1692: byte 105
                ldb     ,x+                     ;  6 t = 1696: byte 107
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1708: byte 106
                sty     <VIA_port_b             ;  6 t = 1712: row 41, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 1760: row 42, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1772: byte 110
                ldb     ,x+                     ;  6 t = 1776: byte 111
                lda     ,x+                     ;  6 t = 1782: byte 112
                stb     <VIA_shift_reg          ;  4 t = 1788: byte 111
                ldb     ,x+                     ;  6 t = 1792: byte 113
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1804: byte 112
                sty     <VIA_port_b             ;  6 t = 1808: row 43, X speed -80
                lda     ,x+                     ;  6 t = 1814: byte 114
                stb     <VIA_shift_reg          ;  4 t = 1820: byte 113
                ldb     ,x+                     ;  6 t = 1824: byte 115
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1836: byte 114
                lda     ,x+                     ;  6 t = 1840: byte 116
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1852: byte 115
                stu     <VIA_port_b             ;  5 t = 1856: row 44, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1868: byte 116
                ldb     ,x+                     ;  6 t = 1872: byte 117
                lda     ,x+                     ;  6 t = 1878: byte 118
                stb     <VIA_shift_reg          ;  4 t = 1884: byte 117
                ldb     ,x+                     ;  6 t = 1888: byte 119
                sty     <VIA_port_b             ;  6 t = 1894: row 45, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 1900: byte 118
                lda     ,x+                     ;  6 t = 1904: byte 120
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1916: byte 119
                ldb     ,x+                     ;  6 t = 1920: byte 121
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1932: byte 120
                stu     <VIA_port_b             ;  5 t = 1936: row 46, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1948: byte 121
                lda     ,x+                     ;  6 t = 1952: byte 122
                ldb     ,x+                     ;  6 t = 1958: byte 123
                sta     <VIA_shift_reg          ;  4 t = 1964: byte 122
                lda     ,x+                     ;  6 t = 1968: byte 124
                sty     <VIA_port_b             ;  6 t = 1974: row 47, X speed -80
                stb     <VIA_shift_reg          ;  4 t = 1980: byte 123
                ldb     ,x+                     ;  6 t = 1984: byte 125
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1996: byte 124
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 2007: row 48, X speed +80
                stb     <VIA_shift_reg          ;  4 t = 2012: byte 125
                lda     ,x+                     ;  6 t = 2016: byte 126
                ldb     ,x+                     ;  6 t = 2022: byte 127
                sta     <VIA_shift_reg          ;  4 t = 2028: byte 126
                lda     ,x+                     ;  6 t = 2032: byte 128
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2044: byte 127
                sty     <VIA_port_b             ;  6 t = 2048: row 49, X speed -80
                ldb     ,x+                     ;  6 t = 2054: byte 129
                sta     <VIA_shift_reg          ;  4 t = 2060: byte 128
                lda     ,x+                     ;  6 t = 2064: byte 130
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2076: byte 129
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 2087: row 50, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 2092: byte 130
                ldb     ,x+                     ;  6 t = 2096: byte 131
                lda     ,x+                     ;  6 t = 2102: byte 132
                stb     <VIA_shift_reg          ;  4 t = 2108: byte 131
                ldb     ,x+                     ;  6 t = 2112: byte 133
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2124: byte 132
                sty     <VIA_port_b             ;  6 t = 2128: row 51, X speed -80
                lda     ,x+                     ;  6 t = 2134: byte 134
                stb     <VIA_shift_reg          ;  4 t = 2140: byte 133
                ldb     ,x+                     ;  6 t = 2144: byte 135
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2156: byte 134
                stu     <VIA_port_b             ;  5 t = 2160: row 52, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2172: byte 135
                lda     ,x+                     ;  6 t = 2176: byte 136
                ldb     ,x+                     ;  6 t = 2182: byte 137
                sta     <VIA_shift_reg          ;  4 t = 2188: byte 136
                sty     <VIA_port_b             ;  6 t = 2192: row 53, X speed -80
                lda     ,x+                     ;  6 t = 2198: byte 138
                stb     <VIA_shift_reg          ;  4 t = 2204: byte 137
                ldb     ,x+                     ;  6 t = 2208: byte 139
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2220: byte 138
                stu     <VIA_port_b             ;  5 t = 2224: row 54, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2236: byte 139
                lda     ,x+                     ;  6 t = 2240: byte 140
                ldb     ,x+                     ;  6 t = 2246: byte 141
                sta     <VIA_shift_reg          ;  4 t = 2252: byte 140
                sty     <VIA_port_b             ;  6 t = 2256: row 55, X speed -80
                lda     ,x+                     ;  6 t = 2262: byte 142
                stb     <VIA_shift_reg          ;  4 t = 2268: byte 141
                ldb     ,x+                     ;  6 t = 2272: byte 143
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2284: byte 142
                stu     <VIA_port_b             ;  5 t = 2288: row 56, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2300: byte 143
                lda     ,x+                     ;  6 t = 2304: byte 144
                ldb     ,x+                     ;  6 t = 2310: byte 145
                sta     <VIA_shift_reg          ;  4 t = 2316: byte 144
                sty     <VIA_port_b             ;  6 t = 2320: row 57, X speed -80
                lda     ,x+                     ;  6 t = 2326: byte 146
                stb     <VIA_shift_reg          ;  4 t = 2332: byte 145
                ldb     ,x+                     ;  6 t = 2336: byte 147
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2348: byte 146
                stu     <VIA_port_b             ;  5 t = 2352: row 58, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2364: byte 147
                lda     ,x+                     ;  6 t = 2368: byte 148
                ldb     ,x+                     ;  6 t = 2374: byte 149
                sta     <VIA_shift_reg          ;  4 t = 2380: byte 148
                sty     <VIA_port_b             ;  6 t = 2384: row 59, X speed -80
                lda     ,x+                     ;  6 t = 2390: byte 150
                stb     <VIA_shift_reg          ;  4 t = 2396: byte 149
                ldb     ,x+                     ;  6 t = 2400: byte 151
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2412: byte 150
                stu     <VIA_port_b             ;  5 t = 2416: row 60, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2428: byte 151
                lda     ,x+                     ;  6 t = 2432: byte 152
                ldb     ,x+                     ;  6 t = 2438: byte 153
                sta     <VIA_shift_reg          ;  4 t = 2444: byte 152
                sty     <VIA_port_b             ;  6 t = 2448: row 61, X speed -80
                lda     ,x+                     ;  6 t = 2454: byte 154
                stb     <VIA_shift_reg          ;  4 t = 2460: byte 153
                ldb     ,x+                     ;  6 t = 2464: byte 155
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2476: byte 154
                stu     <VIA_port_b             ;  5 t = 2480: row 62, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2492: byte 155
                lda     ,x+                     ;  6 t = 2496: byte 156
                ldb     ,x+                     ;  6 t = 2502: byte 157
                sta     <VIA_shift_reg          ;  4 t = 2508: byte 156
                sty     <VIA_port_b             ;  6 t = 2512: row 63, X speed -80
                lda     ,x+                     ;  6 t = 2518: byte 158
                stb     <VIA_shift_reg          ;  4 t = 2524: byte 157
                ldb     ,x+                     ;  6 t = 2528: byte 159
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2540: byte 158
                stu     <VIA_port_b             ;  5 t = 2544: row 64, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2556: byte 159
                lda     ,x+                     ;  6 t = 2560: byte 160
                ldb     ,x+                     ;  6 t = 2566: byte 161
                sta     <VIA_shift_reg          ;  4 t = 2572: byte 160
                sty     <VIA_port_b             ;  6 t = 2576: row 65, X speed -80
                lda     ,x+                     ;  6 t = 2582: byte 162
                stb     <VIA_shift_reg          ;  4 t = 2588: byte 161
                ldb     ,x+                     ;  6 t = 2592: byte 163
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2604: byte 162
                stu     <VIA_port_b             ;  5 t = 2608: row 66, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2620: byte 163
                lda     ,x+                     ;  6 t = 2624: byte 164
                ldb     ,x+                     ;  6 t = 2630: byte 165
                sta     <VIA_shift_reg          ;  4 t = 2636: byte 164
                sty     <VIA_port_b             ;  6 t = 2640: row 67, X speed -80
                lda     ,x+                     ;  6 t = 2646: byte 166
                stb     <VIA_shift_reg          ;  4 t = 2652: byte 165
                ldb     ,x+                     ;  6 t = 2656: byte 167
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2668: byte 166
                stu     <VIA_port_b             ;  5 t = 2672: row 68, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2684: byte 167
                lda     ,x+                     ;  6 t = 2688: byte 168
                ldb     ,x+                     ;  6 t = 2694: byte 169
                sta     <VIA_shift_reg          ;  4 t = 2700: byte 168
                sty     <VIA_port_b             ;  6 t = 2704: row 69, X speed -80
                lda     ,x+                     ;  6 t = 2710: byte 170
                stb     <VIA_shift_reg          ;  4 t = 2716: byte 169
                ldb     ,x+                     ;  6 t = 2720: byte 171
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2732: byte 170
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 2739: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2748: byte 171
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 26 x 34: 45 rows (pitch 0.77 pixels), drift 3, 116 bytes: ramp on 1843 cycles
; in: X = the data, the beam at the sprite's top left
zig_trogg_3
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
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                sty     <VIA_port_b             ;  6 t = 48: row 1, X speed -80
                lda     ,x+                     ;  6 t = 54: byte 4
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 71: row 2, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                ldb     ,x+                     ;  6 t = 80: byte 5
                lda     ,x+                     ;  6 t = 86: byte 6
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                sty     <VIA_port_b             ;  6 t = 96: row 3, X speed -80
                ldb     ,x+                     ;  6 t = 102: byte 7
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                stu     <VIA_port_b             ;  5 t = 128: row 4, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                ldb     ,x+                     ;  6 t = 144: byte 9
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 162: row 5, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                ldb     ,x+                     ;  6 t = 176: byte 11
                lda     ,x+                     ;  6 t = 182: byte 12
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 199: row 6, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                ldb     ,x+                     ;  6 t = 208: byte 13
                lda     ,x+                     ;  6 t = 214: byte 14
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                sty     <VIA_port_b             ;  6 t = 240: row 7, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 288: row 8, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 336: row 9, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 384: row 10, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 420: row 11, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                ldb     ,x+                     ;  6 t = 432: byte 27
                lda     ,x+                     ;  6 t = 438: byte 28
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
                ldb     ,x+                     ;  6 t = 928: byte 59
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                stu     <VIA_port_b             ;  5 t = 944: row 22, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                lda     ,x+                     ;  6 t = 960: byte 60
                ldb     ,x+                     ;  6 t = 966: byte 61
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                lda     ,x+                     ;  6 t = 976: byte 62
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                sty     <VIA_port_b             ;  6 t = 992: row 23, X speed -80
                ldb     ,x+                     ;  6 t = 998: byte 63
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                lda     ,x+                     ;  6 t = 1008: byte 64
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                ldb     ,x+                     ;  6 t = 1024: byte 65
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                stu     <VIA_port_b             ;  5 t = 1040: row 24, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                lda     ,x+                     ;  6 t = 1056: byte 66
                ldb     ,x+                     ;  6 t = 1062: byte 67
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                lda     ,x+                     ;  6 t = 1072: byte 68
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                sty     <VIA_port_b             ;  6 t = 1088: row 25, X speed -80
                ldb     ,x+                     ;  6 t = 1094: byte 69
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                lda     ,x+                     ;  6 t = 1104: byte 70
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                lda     ,x+                     ;  6 t = 1168: byte 74
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                sty     <VIA_port_b             ;  6 t = 1184: row 27, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 1232: row 28, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                lda     ,x+                     ;  6 t = 1248: byte 78
                ldb     ,x+                     ;  6 t = 1254: byte 79
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1268: row 29, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                lda     ,x+                     ;  6 t = 1280: byte 80
                ldb     ,x+                     ;  6 t = 1286: byte 81
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                lda     ,x+                     ;  6 t = 1296: byte 82
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                stu     <VIA_port_b             ;  5 t = 1312: row 30, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                ldb     ,x+                     ;  6 t = 1328: byte 83
                lda     ,x+                     ;  6 t = 1334: byte 84
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                ldb     ,x+                     ;  6 t = 1344: byte 85
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                sty     <VIA_port_b             ;  6 t = 1360: row 31, X speed -80
                lda     ,x+                     ;  6 t = 1366: byte 86
                stb     <VIA_shift_reg          ;  4 t = 1372: byte 85
                ldb     ,x+                     ;  6 t = 1376: byte 87
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1388: byte 86
                lda     ,x+                     ;  6 t = 1392: byte 88
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1404: byte 87
                stu     <VIA_port_b             ;  5 t = 1408: row 32, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                ldb     ,x+                     ;  6 t = 1424: byte 89
                lda     ,x+                     ;  6 t = 1430: byte 90
                stb     <VIA_shift_reg          ;  4 t = 1436: byte 89
                ldb     ,x+                     ;  6 t = 1440: byte 91
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1452: byte 90
                sty     <VIA_port_b             ;  6 t = 1456: row 33, X speed -80
                lda     ,x+                     ;  6 t = 1462: byte 92
                stb     <VIA_shift_reg          ;  4 t = 1468: byte 91
                ldb     ,x+                     ;  6 t = 1472: byte 93
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1484: byte 92
                stu     <VIA_port_b             ;  5 t = 1488: row 34, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1500: byte 93
                lda     ,x+                     ;  6 t = 1504: byte 94
                ldb     ,x+                     ;  6 t = 1510: byte 95
                sta     <VIA_shift_reg          ;  4 t = 1516: byte 94
                sty     <VIA_port_b             ;  6 t = 1520: row 35, X speed -80
                lda     ,x+                     ;  6 t = 1526: byte 96
                stb     <VIA_shift_reg          ;  4 t = 1532: byte 95
                ldb     ,x+                     ;  6 t = 1536: byte 97
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1548: byte 96
                stu     <VIA_port_b             ;  5 t = 1552: row 36, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1564: byte 97
                lda     ,x+                     ;  6 t = 1568: byte 98
                ldb     ,x+                     ;  6 t = 1574: byte 99
                sta     <VIA_shift_reg          ;  4 t = 1580: byte 98
                sty     <VIA_port_b             ;  6 t = 1584: row 37, X speed -80
                lda     ,x+                     ;  6 t = 1590: byte 100
                stb     <VIA_shift_reg          ;  4 t = 1596: byte 99
                ldb     ,x+                     ;  6 t = 1600: byte 101
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1612: byte 100
                stu     <VIA_port_b             ;  5 t = 1616: row 38, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1628: byte 101
                lda     ,x+                     ;  6 t = 1632: byte 102
                ldb     ,x+                     ;  6 t = 1638: byte 103
                sta     <VIA_shift_reg          ;  4 t = 1644: byte 102
                sty     <VIA_port_b             ;  6 t = 1648: row 39, X speed -80
                lda     ,x+                     ;  6 t = 1654: byte 104
                stb     <VIA_shift_reg          ;  4 t = 1660: byte 103
                ldb     ,x+                     ;  6 t = 1664: byte 105
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1676: byte 104
                stu     <VIA_port_b             ;  5 t = 1680: row 40, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1692: byte 105
                lda     ,x+                     ;  6 t = 1696: byte 106
                ldb     ,x+                     ;  6 t = 1702: byte 107
                sta     <VIA_shift_reg          ;  4 t = 1708: byte 106
                sty     <VIA_port_b             ;  6 t = 1712: row 41, X speed -80
                lda     ,x+                     ;  6 t = 1718: byte 108
                stb     <VIA_shift_reg          ;  4 t = 1724: byte 107
                ldb     ,x+                     ;  6 t = 1728: byte 109
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1740: byte 108
                stu     <VIA_port_b             ;  5 t = 1744: row 42, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1756: byte 109
                lda     ,x+                     ;  6 t = 1760: byte 110
                ldb     ,x+                     ;  6 t = 1766: byte 111
                sta     <VIA_shift_reg          ;  4 t = 1772: byte 110
                sty     <VIA_port_b             ;  6 t = 1776: row 43, X speed -80
                lda     ,x+                     ;  6 t = 1782: byte 112
                stb     <VIA_shift_reg          ;  4 t = 1788: byte 111
                ldb     ,x+                     ;  6 t = 1792: byte 113
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1804: byte 112
                stu     <VIA_port_b             ;  5 t = 1808: row 44, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1820: byte 113
                lda     ,x+                     ;  6 t = 1824: byte 114
                ldb     ,x+                     ;  6 t = 1830: byte 115
                sta     <VIA_shift_reg          ;  4 t = 1836: byte 114
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 1843: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1852: byte 115
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 26 x 34: 35 rows (pitch 0.98 pixels), drift 4, 87 bytes: ramp on 1379 cycles
; in: X = the data, the beam at the sprite's top left
zig_trogg_4
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
                sty     <VIA_port_b             ;  6 t = 384: row 9, X speed -80
                ldb     ,x+                     ;  6 t = 390: byte 25
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                lda     ,x+                     ;  6 t = 400: byte 26
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 418: row 10, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                ldb     ,x+                     ;  6 t = 432: byte 27
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 452: row 11, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                ldb     ,x+                     ;  6 t = 464: byte 29
                lda     ,x+                     ;  6 t = 470: byte 30
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 487: row 12, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                ldb     ,x+                     ;  6 t = 496: byte 31
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                sty     <VIA_port_b             ;  6 t = 528: row 13, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 576: row 14, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 624: row 15, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 672: row 16, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 720: row 17, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 768: row 18, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 816: row 19, X speed -80
                lda     ,x+                     ;  6 t = 822: byte 52
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                stu     <VIA_port_b             ;  5 t = 864: row 20, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                ldb     ,x+                     ;  6 t = 880: byte 55
                lda     ,x+                     ;  6 t = 886: byte 56
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                ldb     ,x+                     ;  6 t = 896: byte 57
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                sty     <VIA_port_b             ;  6 t = 912: row 21, X speed -80
                lda     ,x+                     ;  6 t = 918: byte 58
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                ldb     ,x+                     ;  6 t = 928: byte 59
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                lda     ,x+                     ;  6 t = 944: byte 60
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                stu     <VIA_port_b             ;  5 t = 960: row 22, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                ldb     ,x+                     ;  6 t = 976: byte 61
                lda     ,x+                     ;  6 t = 982: byte 62
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 994: row 23, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                ldb     ,x+                     ;  6 t = 1008: byte 63
                lda     ,x+                     ;  6 t = 1014: byte 64
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1026: row 24, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                ldb     ,x+                     ;  6 t = 1040: byte 65
                lda     ,x+                     ;  6 t = 1046: byte 66
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1060: row 25, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                ldb     ,x+                     ;  6 t = 1072: byte 67
                lda     ,x+                     ;  6 t = 1078: byte 68
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1092: row 26, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                ldb     ,x+                     ;  6 t = 1104: byte 69
                lda     ,x+                     ;  6 t = 1110: byte 70
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1124: row 27, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                ldb     ,x+                     ;  6 t = 1136: byte 71
                lda     ,x+                     ;  6 t = 1142: byte 72
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                stu     <VIA_port_b             ;  5 t = 1152: row 28, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                ldb     ,x+                     ;  6 t = 1168: byte 73
                lda     ,x+                     ;  6 t = 1174: byte 74
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1186: row 29, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                ldb     ,x+                     ;  6 t = 1200: byte 75
                lda     ,x+                     ;  6 t = 1206: byte 76
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                stu     <VIA_port_b             ;  5 t = 1216: row 30, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                ldb     ,x+                     ;  6 t = 1232: byte 77
                lda     ,x+                     ;  6 t = 1238: byte 78
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                sty     <VIA_port_b             ;  6 t = 1248: row 31, X speed -80
                ldb     ,x+                     ;  6 t = 1254: byte 79
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                lda     ,x+                     ;  6 t = 1264: byte 80
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                stu     <VIA_port_b             ;  5 t = 1280: row 32, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                ldb     ,x+                     ;  6 t = 1296: byte 81
                lda     ,x+                     ;  6 t = 1302: byte 82
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                sty     <VIA_port_b             ;  6 t = 1312: row 33, X speed -80
                ldb     ,x+                     ;  6 t = 1318: byte 83
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                lda     ,x+                     ;  6 t = 1328: byte 84
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                stu     <VIA_port_b             ;  5 t = 1344: row 34, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                ldb     ,x+                     ;  6 t = 1360: byte 85
                lda     ,x+                     ;  6 t = 1366: byte 86
                stb     <VIA_shift_reg          ;  4 t = 1372: byte 85
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 1379: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1388: byte 86
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 23 x 33: 75 rows (pitch 0.44 pixels), drift 2, 167 bytes: ramp on 2659 cycles
; in: X = the data, the beam at the sprite's top left
zig_poglet_2
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
                sty     <VIA_port_b             ;  6 t = 32: row 1, X speed -80
                ldb     ,x+                     ;  6 t = 38: byte 3
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                stu     <VIA_port_b             ;  5 t = 48: row 2, X speed +80
                nop                             ;  2 
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
                sty     <VIA_port_b             ;  6 t = 118: row 5, X speed -80
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                lda     ,x+                     ;  6 t = 128: byte 8
                ldb     ,x+                     ;  6 t = 134: byte 9
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                stu     <VIA_port_b             ;  5 t = 144: row 6, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                lda     ,x+                     ;  6 t = 160: byte 10
                ldb     ,x+                     ;  6 t = 166: byte 11
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                sty     <VIA_port_b             ;  6 t = 176: row 7, X speed -80
                lda     ,x+                     ;  6 t = 182: byte 12
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                stu     <VIA_port_b             ;  5 t = 208: row 8, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                lda     ,x+                     ;  6 t = 224: byte 14
                ldb     ,x+                     ;  6 t = 230: byte 15
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                sty     <VIA_port_b             ;  6 t = 240: row 9, X speed -80
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                sty     <VIA_port_b             ;  6 t = 422: row 15, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                ldb     ,x+                     ;  6 t = 432: byte 27
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                stu     <VIA_port_b             ;  5 t = 448: row 16, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                ldb     ,x+                     ;  6 t = 464: byte 29
                sty     <VIA_port_b             ;  6 t = 470: row 17, X speed -80
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
                lda     ,x+                     ;  6 t = 528: byte 34
                sty     <VIA_port_b             ;  6 t = 534: row 19, X speed -80
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 564: row 20, X speed +80
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                lda     ,x+                     ;  6 t = 576: byte 36
                ldb     ,x+                     ;  6 t = 582: byte 37
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 594: row 21, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                lda     ,x+                     ;  6 t = 608: byte 38
                ldb     ,x+                     ;  6 t = 614: byte 39
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
                ldb     ,x+                     ;  6 t = 672: byte 43
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 690: row 24, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                lda     ,x+                     ;  6 t = 704: byte 44
                ldb     ,x+                     ;  6 t = 710: byte 45
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 722: row 25, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                lda     ,x+                     ;  6 t = 736: byte 46
                ldb     ,x+                     ;  6 t = 742: byte 47
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 754: row 26, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                lda     ,x+                     ;  6 t = 768: byte 48
                ldb     ,x+                     ;  6 t = 774: byte 49
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 786: row 27, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                lda     ,x+                     ;  6 t = 800: byte 50
                ldb     ,x+                     ;  6 t = 806: byte 51
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 818: row 28, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                lda     ,x+                     ;  6 t = 832: byte 52
                ldb     ,x+                     ;  6 t = 838: byte 53
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 850: row 29, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                lda     ,x+                     ;  6 t = 864: byte 54
                ldb     ,x+                     ;  6 t = 870: byte 55
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 884: row 30, X speed +80
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                lda     ,x+                     ;  6 t = 896: byte 56
                ldb     ,x+                     ;  6 t = 902: byte 57
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                lda     ,x+                     ;  6 t = 912: byte 58
                sty     <VIA_port_b             ;  6 t = 918: row 31, X speed -80
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                ldb     ,x+                     ;  6 t = 928: byte 59
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                lda     ,x+                     ;  6 t = 944: byte 60
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                stu     <VIA_port_b             ;  5 t = 960: row 32, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                ldb     ,x+                     ;  6 t = 976: byte 61
                lda     ,x+                     ;  6 t = 982: byte 62
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                ldb     ,x+                     ;  6 t = 992: byte 63
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                sty     <VIA_port_b             ;  6 t = 1008: row 33, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 1056: row 34, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                ldb     ,x+                     ;  6 t = 1072: byte 67
                lda     ,x+                     ;  6 t = 1078: byte 68
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                ldb     ,x+                     ;  6 t = 1088: byte 69
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                sty     <VIA_port_b             ;  6 t = 1104: row 35, X speed -80
                lda     ,x+                     ;  6 t = 1110: byte 70
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                ldb     ,x+                     ;  6 t = 1120: byte 71
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                lda     ,x+                     ;  6 t = 1136: byte 72
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                stu     <VIA_port_b             ;  5 t = 1152: row 36, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                ldb     ,x+                     ;  6 t = 1168: byte 73
                lda     ,x+                     ;  6 t = 1174: byte 74
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                ldb     ,x+                     ;  6 t = 1184: byte 75
                sty     <VIA_port_b             ;  6 t = 1190: row 37, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                lda     ,x+                     ;  6 t = 1200: byte 76
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1220: row 38, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                ldb     ,x+                     ;  6 t = 1232: byte 77
                lda     ,x+                     ;  6 t = 1238: byte 78
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                sty     <VIA_port_b             ;  6 t = 1248: row 39, X speed -80
                ldb     ,x+                     ;  6 t = 1254: byte 79
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                lda     ,x+                     ;  6 t = 1264: byte 80
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                stu     <VIA_port_b             ;  5 t = 1280: row 40, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                ldb     ,x+                     ;  6 t = 1296: byte 81
                lda     ,x+                     ;  6 t = 1302: byte 82
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                sty     <VIA_port_b             ;  6 t = 1312: row 41, X speed -80
                ldb     ,x+                     ;  6 t = 1318: byte 83
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                lda     ,x+                     ;  6 t = 1328: byte 84
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                stu     <VIA_port_b             ;  5 t = 1344: row 42, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                ldb     ,x+                     ;  6 t = 1360: byte 85
                lda     ,x+                     ;  6 t = 1366: byte 86
                stb     <VIA_shift_reg          ;  4 t = 1372: byte 85
                sty     <VIA_port_b             ;  6 t = 1376: row 43, X speed -80
                ldb     ,x+                     ;  6 t = 1382: byte 87
                sta     <VIA_shift_reg          ;  4 t = 1388: byte 86
                lda     ,x+                     ;  6 t = 1392: byte 88
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1404: byte 87
                stu     <VIA_port_b             ;  5 t = 1408: row 44, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                ldb     ,x+                     ;  6 t = 1424: byte 89
                lda     ,x+                     ;  6 t = 1430: byte 90
                stb     <VIA_shift_reg          ;  4 t = 1436: byte 89
                sty     <VIA_port_b             ;  6 t = 1440: row 45, X speed -80
                ldb     ,x+                     ;  6 t = 1446: byte 91
                sta     <VIA_shift_reg          ;  4 t = 1452: byte 90
                lda     ,x+                     ;  6 t = 1456: byte 92
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1468: byte 91
                stu     <VIA_port_b             ;  5 t = 1472: row 46, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1484: byte 92
                ldb     ,x+                     ;  6 t = 1488: byte 93
                lda     ,x+                     ;  6 t = 1494: byte 94
                stb     <VIA_shift_reg          ;  4 t = 1500: byte 93
                sty     <VIA_port_b             ;  6 t = 1504: row 47, X speed -80
                ldb     ,x+                     ;  6 t = 1510: byte 95
                sta     <VIA_shift_reg          ;  4 t = 1516: byte 94
                lda     ,x+                     ;  6 t = 1520: byte 96
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1532: byte 95
                stu     <VIA_port_b             ;  5 t = 1536: row 48, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1548: byte 96
                ldb     ,x+                     ;  6 t = 1552: byte 97
                lda     ,x+                     ;  6 t = 1558: byte 98
                stb     <VIA_shift_reg          ;  4 t = 1564: byte 97
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1570: row 49, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1580: byte 98
                ldb     ,x+                     ;  6 t = 1584: byte 99
                lda     ,x+                     ;  6 t = 1590: byte 100
                stb     <VIA_shift_reg          ;  4 t = 1596: byte 99
                stu     <VIA_port_b             ;  5 t = 1600: row 50, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1612: byte 100
                ldb     ,x+                     ;  6 t = 1616: byte 101
                lda     ,x+                     ;  6 t = 1622: byte 102
                stb     <VIA_shift_reg          ;  4 t = 1628: byte 101
                sty     <VIA_port_b             ;  6 t = 1632: row 51, X speed -80
                ldb     ,x+                     ;  6 t = 1638: byte 103
                sta     <VIA_shift_reg          ;  4 t = 1644: byte 102
                lda     ,x+                     ;  6 t = 1648: byte 104
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1660: byte 103
                stu     <VIA_port_b             ;  5 t = 1664: row 52, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1676: byte 104
                ldb     ,x+                     ;  6 t = 1680: byte 105
                lda     ,x+                     ;  6 t = 1686: byte 106
                stb     <VIA_shift_reg          ;  4 t = 1692: byte 105
                sty     <VIA_port_b             ;  6 t = 1696: row 53, X speed -80
                ldb     ,x+                     ;  6 t = 1702: byte 107
                sta     <VIA_shift_reg          ;  4 t = 1708: byte 106
                lda     ,x+                     ;  6 t = 1712: byte 108
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1724: byte 107
                stu     <VIA_port_b             ;  5 t = 1728: row 54, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1740: byte 108
                ldb     ,x+                     ;  6 t = 1744: byte 109
                lda     ,x+                     ;  6 t = 1750: byte 110
                stb     <VIA_shift_reg          ;  4 t = 1756: byte 109
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1762: row 55, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1772: byte 110
                ldb     ,x+                     ;  6 t = 1776: byte 111
                lda     ,x+                     ;  6 t = 1782: byte 112
                stb     <VIA_shift_reg          ;  4 t = 1788: byte 111
                stu     <VIA_port_b             ;  5 t = 1792: row 56, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1804: byte 112
                ldb     ,x+                     ;  6 t = 1808: byte 113
                lda     ,x+                     ;  6 t = 1814: byte 114
                stb     <VIA_shift_reg          ;  4 t = 1820: byte 113
                sty     <VIA_port_b             ;  6 t = 1824: row 57, X speed -80
                ldb     ,x+                     ;  6 t = 1830: byte 115
                sta     <VIA_shift_reg          ;  4 t = 1836: byte 114
                lda     ,x+                     ;  6 t = 1840: byte 116
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1852: byte 115
                stu     <VIA_port_b             ;  5 t = 1856: row 58, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1868: byte 116
                ldb     ,x+                     ;  6 t = 1872: byte 117
                lda     ,x+                     ;  6 t = 1878: byte 118
                stb     <VIA_shift_reg          ;  4 t = 1884: byte 117
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1892: row 59, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1900: byte 118
                ldb     ,x+                     ;  6 t = 1904: byte 119
                lda     ,x+                     ;  6 t = 1910: byte 120
                stb     <VIA_shift_reg          ;  4 t = 1916: byte 119
                ldb     ,x+                     ;  6 t = 1920: byte 121
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1932: byte 120
                stu     <VIA_port_b             ;  5 t = 1936: row 60, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1948: byte 121
                lda     ,x+                     ;  6 t = 1952: byte 122
                ldb     ,x+                     ;  6 t = 1958: byte 123
                sta     <VIA_shift_reg          ;  4 t = 1964: byte 122
                lda     ,x+                     ;  6 t = 1968: byte 124
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1980: byte 123
                sty     <VIA_port_b             ;  6 t = 1984: row 61, X speed -80
                ldb     ,x+                     ;  6 t = 1990: byte 125
                sta     <VIA_shift_reg          ;  4 t = 1996: byte 124
                lda     ,x+                     ;  6 t = 2000: byte 126
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2012: byte 125
                ldb     ,x+                     ;  6 t = 2016: byte 127
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2028: byte 126
                stu     <VIA_port_b             ;  5 t = 2032: row 62, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2044: byte 127
                lda     ,x+                     ;  6 t = 2048: byte 128
                ldb     ,x+                     ;  6 t = 2054: byte 129
                sta     <VIA_shift_reg          ;  4 t = 2060: byte 128
                lda     ,x+                     ;  6 t = 2064: byte 130
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2076: byte 129
                sty     <VIA_port_b             ;  6 t = 2080: row 63, X speed -80
                ldb     ,x+                     ;  6 t = 2086: byte 131
                sta     <VIA_shift_reg          ;  4 t = 2092: byte 130
                lda     ,x+                     ;  6 t = 2096: byte 132
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2108: byte 131
                ldb     ,x+                     ;  6 t = 2112: byte 133
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2124: byte 132
                stu     <VIA_port_b             ;  5 t = 2128: row 64, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2140: byte 133
                lda     ,x+                     ;  6 t = 2144: byte 134
                ldb     ,x+                     ;  6 t = 2150: byte 135
                sta     <VIA_shift_reg          ;  4 t = 2156: byte 134
                lda     ,x+                     ;  6 t = 2160: byte 136
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2172: byte 135
                sty     <VIA_port_b             ;  6 t = 2176: row 65, X speed -80
                ldb     ,x+                     ;  6 t = 2182: byte 137
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
                stu     <VIA_port_b             ;  5 t = 2224: row 66, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2236: byte 139
                lda     ,x+                     ;  6 t = 2240: byte 140
                ldb     ,x+                     ;  6 t = 2246: byte 141
                sta     <VIA_shift_reg          ;  4 t = 2252: byte 140
                lda     ,x+                     ;  6 t = 2256: byte 142
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2268: byte 141
                sty     <VIA_port_b             ;  6 t = 2272: row 67, X speed -80
                ldb     ,x+                     ;  6 t = 2278: byte 143
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
                stu     <VIA_port_b             ;  5 t = 2320: row 68, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2332: byte 145
                lda     ,x+                     ;  6 t = 2336: byte 146
                ldb     ,x+                     ;  6 t = 2342: byte 147
                sta     <VIA_shift_reg          ;  4 t = 2348: byte 146
                lda     ,x+                     ;  6 t = 2352: byte 148
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2364: byte 147
                sty     <VIA_port_b             ;  6 t = 2368: row 69, X speed -80
                ldb     ,x+                     ;  6 t = 2374: byte 149
                sta     <VIA_shift_reg          ;  4 t = 2380: byte 148
                lda     ,x+                     ;  6 t = 2384: byte 150
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2396: byte 149
                ldb     ,x+                     ;  6 t = 2400: byte 151
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2412: byte 150
                stu     <VIA_port_b             ;  5 t = 2416: row 70, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2428: byte 151
                lda     ,x+                     ;  6 t = 2432: byte 152
                ldb     ,x+                     ;  6 t = 2438: byte 153
                sta     <VIA_shift_reg          ;  4 t = 2444: byte 152
                lda     ,x+                     ;  6 t = 2448: byte 154
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2460: byte 153
                sty     <VIA_port_b             ;  6 t = 2464: row 71, X speed -80
                ldb     ,x+                     ;  6 t = 2470: byte 155
                sta     <VIA_shift_reg          ;  4 t = 2476: byte 154
                lda     ,x+                     ;  6 t = 2480: byte 156
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2492: byte 155
                ldb     ,x+                     ;  6 t = 2496: byte 157
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2508: byte 156
                stu     <VIA_port_b             ;  5 t = 2512: row 72, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2524: byte 157
                lda     ,x+                     ;  6 t = 2528: byte 158
                ldb     ,x+                     ;  6 t = 2534: byte 159
                sta     <VIA_shift_reg          ;  4 t = 2540: byte 158
                lda     ,x+                     ;  6 t = 2544: byte 160
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2556: byte 159
                sty     <VIA_port_b             ;  6 t = 2560: row 73, X speed -80
                ldb     ,x+                     ;  6 t = 2566: byte 161
                sta     <VIA_shift_reg          ;  4 t = 2572: byte 160
                lda     ,x+                     ;  6 t = 2576: byte 162
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2588: byte 161
                ldb     ,x+                     ;  6 t = 2592: byte 163
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2604: byte 162
                stu     <VIA_port_b             ;  5 t = 2608: row 74, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2620: byte 163
                lda     ,x+                     ;  6 t = 2624: byte 164
                ldb     ,x+                     ;  6 t = 2630: byte 165
                sta     <VIA_shift_reg          ;  4 t = 2636: byte 164
                lda     ,x+                     ;  6 t = 2640: byte 166
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2652: byte 165
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 2659: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2668: byte 166
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 23 x 33: 51 rows (pitch 0.66 pixels), drift 3, 113 bytes: ramp on 1795 cycles
; in: X = the data, the beam at the sprite's top left
zig_poglet_3
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
                sty     <VIA_port_b             ;  6 t = 32: row 1, X speed -80
                ldb     ,x+                     ;  6 t = 38: byte 3
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                stu     <VIA_port_b             ;  5 t = 48: row 2, X speed +80
                nop                             ;  2 
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
                sty     <VIA_port_b             ;  6 t = 118: row 5, X speed -80
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                lda     ,x+                     ;  6 t = 128: byte 8
                ldb     ,x+                     ;  6 t = 134: byte 9
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                stu     <VIA_port_b             ;  5 t = 144: row 6, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                lda     ,x+                     ;  6 t = 160: byte 10
                ldb     ,x+                     ;  6 t = 166: byte 11
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                sty     <VIA_port_b             ;  6 t = 176: row 7, X speed -80
                lda     ,x+                     ;  6 t = 182: byte 12
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                stu     <VIA_port_b             ;  5 t = 208: row 8, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                lda     ,x+                     ;  6 t = 224: byte 14
                ldb     ,x+                     ;  6 t = 230: byte 15
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                sty     <VIA_port_b             ;  6 t = 240: row 9, X speed -80
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                stu     <VIA_port_b             ;  5 t = 272: row 10, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                lda     ,x+                     ;  6 t = 288: byte 18
                sty     <VIA_port_b             ;  6 t = 294: row 11, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                stu     <VIA_port_b             ;  5 t = 320: row 12, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                ldb     ,x+                     ;  6 t = 336: byte 21
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 354: row 13, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                ldb     ,x+                     ;  6 t = 368: byte 23
                lda     ,x+                     ;  6 t = 374: byte 24
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                stu     <VIA_port_b             ;  5 t = 384: row 14, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                sty     <VIA_port_b             ;  6 t = 416: row 15, X speed -80
                ldb     ,x+                     ;  6 t = 422: byte 27
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                lda     ,x+                     ;  6 t = 432: byte 28
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                stu     <VIA_port_b             ;  5 t = 448: row 16, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                ldb     ,x+                     ;  6 t = 464: byte 29
                lda     ,x+                     ;  6 t = 470: byte 30
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                sty     <VIA_port_b             ;  6 t = 480: row 17, X speed -80
                ldb     ,x+                     ;  6 t = 486: byte 31
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 514: row 18, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                ldb     ,x+                     ;  6 t = 528: byte 33
                lda     ,x+                     ;  6 t = 534: byte 34
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 546: row 19, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                ldb     ,x+                     ;  6 t = 560: byte 35
                lda     ,x+                     ;  6 t = 566: byte 36
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 580: row 20, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                ldb     ,x+                     ;  6 t = 592: byte 37
                lda     ,x+                     ;  6 t = 598: byte 38
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                sty     <VIA_port_b             ;  6 t = 614: row 21, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 656: row 22, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 704: row 23, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 752: row 24, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                lda     ,x+                     ;  6 t = 768: byte 48
                ldb     ,x+                     ;  6 t = 774: byte 49
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                lda     ,x+                     ;  6 t = 784: byte 50
                sty     <VIA_port_b             ;  6 t = 790: row 25, X speed -80
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                ldb     ,x+                     ;  6 t = 800: byte 51
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 820: row 26, X speed +80
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                lda     ,x+                     ;  6 t = 832: byte 52
                ldb     ,x+                     ;  6 t = 838: byte 53
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                sty     <VIA_port_b             ;  6 t = 848: row 27, X speed -80
                lda     ,x+                     ;  6 t = 854: byte 54
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                ldb     ,x+                     ;  6 t = 864: byte 55
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                stu     <VIA_port_b             ;  5 t = 880: row 28, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                lda     ,x+                     ;  6 t = 896: byte 56
                ldb     ,x+                     ;  6 t = 902: byte 57
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                sty     <VIA_port_b             ;  6 t = 912: row 29, X speed -80
                lda     ,x+                     ;  6 t = 918: byte 58
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                ldb     ,x+                     ;  6 t = 928: byte 59
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                stu     <VIA_port_b             ;  5 t = 944: row 30, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                lda     ,x+                     ;  6 t = 960: byte 60
                ldb     ,x+                     ;  6 t = 966: byte 61
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                sty     <VIA_port_b             ;  6 t = 976: row 31, X speed -80
                lda     ,x+                     ;  6 t = 982: byte 62
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                ldb     ,x+                     ;  6 t = 992: byte 63
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                stu     <VIA_port_b             ;  5 t = 1008: row 32, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                lda     ,x+                     ;  6 t = 1024: byte 64
                ldb     ,x+                     ;  6 t = 1030: byte 65
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1042: row 33, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                lda     ,x+                     ;  6 t = 1056: byte 66
                ldb     ,x+                     ;  6 t = 1062: byte 67
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                stu     <VIA_port_b             ;  5 t = 1072: row 34, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                lda     ,x+                     ;  6 t = 1088: byte 68
                ldb     ,x+                     ;  6 t = 1094: byte 69
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                sty     <VIA_port_b             ;  6 t = 1104: row 35, X speed -80
                lda     ,x+                     ;  6 t = 1110: byte 70
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                ldb     ,x+                     ;  6 t = 1120: byte 71
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                stu     <VIA_port_b             ;  5 t = 1136: row 36, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                lda     ,x+                     ;  6 t = 1152: byte 72
                ldb     ,x+                     ;  6 t = 1158: byte 73
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1170: row 37, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                lda     ,x+                     ;  6 t = 1184: byte 74
                ldb     ,x+                     ;  6 t = 1190: byte 75
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                stu     <VIA_port_b             ;  5 t = 1200: row 38, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                lda     ,x+                     ;  6 t = 1216: byte 76
                ldb     ,x+                     ;  6 t = 1222: byte 77
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                sty     <VIA_port_b             ;  6 t = 1232: row 39, X speed -80
                lda     ,x+                     ;  6 t = 1238: byte 78
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                ldb     ,x+                     ;  6 t = 1248: byte 79
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 1271: row 40, X speed +80
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                lda     ,x+                     ;  6 t = 1280: byte 80
                ldb     ,x+                     ;  6 t = 1286: byte 81
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                lda     ,x+                     ;  6 t = 1296: byte 82
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1316: row 41, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                ldb     ,x+                     ;  6 t = 1328: byte 83
                lda     ,x+                     ;  6 t = 1334: byte 84
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                ldb     ,x+                     ;  6 t = 1344: byte 85
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1362: row 42, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1372: byte 85
                lda     ,x+                     ;  6 t = 1376: byte 86
                ldb     ,x+                     ;  6 t = 1382: byte 87
                sta     <VIA_shift_reg          ;  4 t = 1388: byte 86
                lda     ,x+                     ;  6 t = 1392: byte 88
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1404: byte 87
                sty     <VIA_port_b             ;  6 t = 1408: row 43, X speed -80
                ldb     ,x+                     ;  6 t = 1414: byte 89
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                lda     ,x+                     ;  6 t = 1424: byte 90
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1436: byte 89
                ldb     ,x+                     ;  6 t = 1440: byte 91
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1452: byte 90
                stu     <VIA_port_b             ;  5 t = 1456: row 44, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1468: byte 91
                lda     ,x+                     ;  6 t = 1472: byte 92
                ldb     ,x+                     ;  6 t = 1478: byte 93
                sta     <VIA_shift_reg          ;  4 t = 1484: byte 92
                lda     ,x+                     ;  6 t = 1488: byte 94
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1500: byte 93
                sty     <VIA_port_b             ;  6 t = 1504: row 45, X speed -80
                ldb     ,x+                     ;  6 t = 1510: byte 95
                sta     <VIA_shift_reg          ;  4 t = 1516: byte 94
                lda     ,x+                     ;  6 t = 1520: byte 96
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1532: byte 95
                ldb     ,x+                     ;  6 t = 1536: byte 97
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1548: byte 96
                stu     <VIA_port_b             ;  5 t = 1552: row 46, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1564: byte 97
                lda     ,x+                     ;  6 t = 1568: byte 98
                ldb     ,x+                     ;  6 t = 1574: byte 99
                sta     <VIA_shift_reg          ;  4 t = 1580: byte 98
                lda     ,x+                     ;  6 t = 1584: byte 100
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1596: byte 99
                sty     <VIA_port_b             ;  6 t = 1600: row 47, X speed -80
                ldb     ,x+                     ;  6 t = 1606: byte 101
                sta     <VIA_shift_reg          ;  4 t = 1612: byte 100
                lda     ,x+                     ;  6 t = 1616: byte 102
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1628: byte 101
                ldb     ,x+                     ;  6 t = 1632: byte 103
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1644: byte 102
                stu     <VIA_port_b             ;  5 t = 1648: row 48, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1660: byte 103
                lda     ,x+                     ;  6 t = 1664: byte 104
                ldb     ,x+                     ;  6 t = 1670: byte 105
                sta     <VIA_shift_reg          ;  4 t = 1676: byte 104
                lda     ,x+                     ;  6 t = 1680: byte 106
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1692: byte 105
                sty     <VIA_port_b             ;  6 t = 1696: row 49, X speed -80
                ldb     ,x+                     ;  6 t = 1702: byte 107
                sta     <VIA_shift_reg          ;  4 t = 1708: byte 106
                lda     ,x+                     ;  6 t = 1712: byte 108
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1724: byte 107
                ldb     ,x+                     ;  6 t = 1728: byte 109
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1740: byte 108
                stu     <VIA_port_b             ;  5 t = 1744: row 50, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1756: byte 109
                lda     ,x+                     ;  6 t = 1760: byte 110
                ldb     ,x+                     ;  6 t = 1766: byte 111
                sta     <VIA_shift_reg          ;  4 t = 1772: byte 110
                lda     ,x+                     ;  6 t = 1776: byte 112
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1788: byte 111
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 1795: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1804: byte 112
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 23 x 33: 38 rows (pitch 0.87 pixels), drift 4, 84 bytes: ramp on 1331 cycles
; in: X = the data, the beam at the sprite's top left
zig_poglet_4
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
                stu     <VIA_port_b             ;  5 t = 48: row 2, X speed +80
                nop                             ;  2 
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
                sty     <VIA_port_b             ;  6 t = 118: row 5, X speed -80
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                lda     ,x+                     ;  6 t = 128: byte 8
                ldb     ,x+                     ;  6 t = 134: byte 9
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                stu     <VIA_port_b             ;  5 t = 144: row 6, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                lda     ,x+                     ;  6 t = 160: byte 10
                ldb     ,x+                     ;  6 t = 166: byte 11
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                sty     <VIA_port_b             ;  6 t = 176: row 7, X speed -80
                lda     ,x+                     ;  6 t = 182: byte 12
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                stu     <VIA_port_b             ;  5 t = 208: row 8, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                lda     ,x+                     ;  6 t = 224: byte 14
                sty     <VIA_port_b             ;  6 t = 230: row 9, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                ldb     ,x+                     ;  6 t = 240: byte 15
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                stu     <VIA_port_b             ;  5 t = 256: row 10, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                ldb     ,x+                     ;  6 t = 272: byte 17
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 290: row 11, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                stu     <VIA_port_b             ;  5 t = 320: row 12, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                ldb     ,x+                     ;  6 t = 336: byte 21
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                sty     <VIA_port_b             ;  6 t = 352: row 13, X speed -80
                ldb     ,x+                     ;  6 t = 358: byte 23
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 386: row 14, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 418: row 15, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                ldb     ,x+                     ;  6 t = 432: byte 27
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 452: row 16, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                ldb     ,x+                     ;  6 t = 464: byte 29
                lda     ,x+                     ;  6 t = 470: byte 30
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                ldb     ,x+                     ;  6 t = 480: byte 31
                sty     <VIA_port_b             ;  6 t = 486: row 17, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                stu     <VIA_port_b             ;  5 t = 528: row 18, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                lda     ,x+                     ;  6 t = 544: byte 34
                ldb     ,x+                     ;  6 t = 550: byte 35
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                lda     ,x+                     ;  6 t = 560: byte 36
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                sty     <VIA_port_b             ;  6 t = 576: row 19, X speed -80
                ldb     ,x+                     ;  6 t = 582: byte 37
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                lda     ,x+                     ;  6 t = 592: byte 38
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                stu     <VIA_port_b             ;  5 t = 624: row 20, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                lda     ,x+                     ;  6 t = 640: byte 40
                ldb     ,x+                     ;  6 t = 646: byte 41
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 660: row 21, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                lda     ,x+                     ;  6 t = 672: byte 42
                ldb     ,x+                     ;  6 t = 678: byte 43
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                stu     <VIA_port_b             ;  5 t = 688: row 22, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                lda     ,x+                     ;  6 t = 704: byte 44
                ldb     ,x+                     ;  6 t = 710: byte 45
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                sty     <VIA_port_b             ;  6 t = 720: row 23, X speed -80
                lda     ,x+                     ;  6 t = 726: byte 46
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                ldb     ,x+                     ;  6 t = 736: byte 47
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                stu     <VIA_port_b             ;  5 t = 752: row 24, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                lda     ,x+                     ;  6 t = 768: byte 48
                ldb     ,x+                     ;  6 t = 774: byte 49
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                sty     <VIA_port_b             ;  6 t = 784: row 25, X speed -80
                lda     ,x+                     ;  6 t = 790: byte 50
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                ldb     ,x+                     ;  6 t = 800: byte 51
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                stu     <VIA_port_b             ;  5 t = 816: row 26, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                lda     ,x+                     ;  6 t = 832: byte 52
                ldb     ,x+                     ;  6 t = 838: byte 53
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                sty     <VIA_port_b             ;  6 t = 848: row 27, X speed -80
                lda     ,x+                     ;  6 t = 854: byte 54
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                ldb     ,x+                     ;  6 t = 864: byte 55
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                stu     <VIA_port_b             ;  5 t = 880: row 28, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                lda     ,x+                     ;  6 t = 896: byte 56
                ldb     ,x+                     ;  6 t = 902: byte 57
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 914: row 29, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                lda     ,x+                     ;  6 t = 928: byte 58
                ldb     ,x+                     ;  6 t = 934: byte 59
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 951: row 30, X speed +80
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                lda     ,x+                     ;  6 t = 960: byte 60
                ldb     ,x+                     ;  6 t = 966: byte 61
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                lda     ,x+                     ;  6 t = 976: byte 62
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 996: row 31, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                ldb     ,x+                     ;  6 t = 1008: byte 63
                lda     ,x+                     ;  6 t = 1014: byte 64
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                ldb     ,x+                     ;  6 t = 1024: byte 65
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1042: row 32, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                lda     ,x+                     ;  6 t = 1056: byte 66
                ldb     ,x+                     ;  6 t = 1062: byte 67
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                lda     ,x+                     ;  6 t = 1072: byte 68
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                sty     <VIA_port_b             ;  6 t = 1088: row 33, X speed -80
                ldb     ,x+                     ;  6 t = 1094: byte 69
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                lda     ,x+                     ;  6 t = 1104: byte 70
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                ldb     ,x+                     ;  6 t = 1120: byte 71
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                stu     <VIA_port_b             ;  5 t = 1136: row 34, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 1184: row 35, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 1232: row 36, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 1280: row 37, X speed -80
                ldb     ,x+                     ;  6 t = 1286: byte 81
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                lda     ,x+                     ;  6 t = 1296: byte 82
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                ldb     ,x+                     ;  6 t = 1312: byte 83
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 1331: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 19 x 23: 47 rows (pitch 0.50 pixels), drift 2, 119 bytes: ramp on 1891 cycles
; in: X = the data, the beam at the sprite's top left
zig_hooter_2
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
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 36: row 1, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                ldb     ,x+                     ;  6 t = 48: byte 3
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
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                stu     <VIA_port_b             ;  5 t = 272: row 6, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                lda     ,x+                     ;  6 t = 288: byte 18
                ldb     ,x+                     ;  6 t = 294: byte 19
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                lda     ,x+                     ;  6 t = 304: byte 20
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                sty     <VIA_port_b             ;  6 t = 320: row 7, X speed -80
                ldb     ,x+                     ;  6 t = 326: byte 21
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                lda     ,x+                     ;  6 t = 336: byte 22
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 354: row 8, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                ldb     ,x+                     ;  6 t = 368: byte 23
                lda     ,x+                     ;  6 t = 374: byte 24
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                sty     <VIA_port_b             ;  6 t = 384: row 9, X speed -80
                ldb     ,x+                     ;  6 t = 390: byte 25
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                lda     ,x+                     ;  6 t = 400: byte 26
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                stu     <VIA_port_b             ;  5 t = 416: row 10, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                ldb     ,x+                     ;  6 t = 432: byte 27
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                sty     <VIA_port_b             ;  6 t = 448: row 11, X speed -80
                ldb     ,x+                     ;  6 t = 454: byte 29
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                stu     <VIA_port_b             ;  5 t = 480: row 12, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                ldb     ,x+                     ;  6 t = 496: byte 31
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                sty     <VIA_port_b             ;  6 t = 512: row 13, X speed -80
                ldb     ,x+                     ;  6 t = 518: byte 33
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                lda     ,x+                     ;  6 t = 528: byte 34
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 546: row 14, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                ldb     ,x+                     ;  6 t = 560: byte 35
                lda     ,x+                     ;  6 t = 566: byte 36
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 578: row 15, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                ldb     ,x+                     ;  6 t = 592: byte 37
                lda     ,x+                     ;  6 t = 598: byte 38
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 610: row 16, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                ldb     ,x+                     ;  6 t = 624: byte 39
                lda     ,x+                     ;  6 t = 630: byte 40
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 644: row 17, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                ldb     ,x+                     ;  6 t = 656: byte 41
                lda     ,x+                     ;  6 t = 662: byte 42
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 679: row 18, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                ldb     ,x+                     ;  6 t = 688: byte 43
                lda     ,x+                     ;  6 t = 694: byte 44
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                ldb     ,x+                     ;  6 t = 704: byte 45
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                sty     <VIA_port_b             ;  6 t = 720: row 19, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 768: row 20, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 816: row 21, X speed -80
                lda     ,x+                     ;  6 t = 822: byte 52
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                stu     <VIA_port_b             ;  5 t = 864: row 22, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                ldb     ,x+                     ;  6 t = 880: byte 55
                lda     ,x+                     ;  6 t = 886: byte 56
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                ldb     ,x+                     ;  6 t = 896: byte 57
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                sty     <VIA_port_b             ;  6 t = 912: row 23, X speed -80
                lda     ,x+                     ;  6 t = 918: byte 58
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                ldb     ,x+                     ;  6 t = 928: byte 59
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                lda     ,x+                     ;  6 t = 944: byte 60
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                stu     <VIA_port_b             ;  5 t = 960: row 24, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                ldb     ,x+                     ;  6 t = 976: byte 61
                lda     ,x+                     ;  6 t = 982: byte 62
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                ldb     ,x+                     ;  6 t = 992: byte 63
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                sty     <VIA_port_b             ;  6 t = 1008: row 25, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 1056: row 26, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                ldb     ,x+                     ;  6 t = 1072: byte 67
                lda     ,x+                     ;  6 t = 1078: byte 68
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                ldb     ,x+                     ;  6 t = 1088: byte 69
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                sty     <VIA_port_b             ;  6 t = 1104: row 27, X speed -80
                lda     ,x+                     ;  6 t = 1110: byte 70
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                ldb     ,x+                     ;  6 t = 1120: byte 71
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                lda     ,x+                     ;  6 t = 1136: byte 72
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                stu     <VIA_port_b             ;  5 t = 1152: row 28, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                ldb     ,x+                     ;  6 t = 1168: byte 73
                lda     ,x+                     ;  6 t = 1174: byte 74
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                ldb     ,x+                     ;  6 t = 1184: byte 75
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                sty     <VIA_port_b             ;  6 t = 1200: row 29, X speed -80
                lda     ,x+                     ;  6 t = 1206: byte 76
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
                stu     <VIA_port_b             ;  5 t = 1248: row 30, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 1296: row 31, X speed -80
                lda     ,x+                     ;  6 t = 1302: byte 82
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                ldb     ,x+                     ;  6 t = 1312: byte 83
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 1335: row 32, X speed +80
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                lda     ,x+                     ;  6 t = 1344: byte 84
                ldb     ,x+                     ;  6 t = 1350: byte 85
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                lda     ,x+                     ;  6 t = 1360: byte 86
                sty     <VIA_port_b             ;  6 t = 1366: row 33, X speed -80
                stb     <VIA_shift_reg          ;  4 t = 1372: byte 85
                ldb     ,x+                     ;  6 t = 1376: byte 87
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1388: byte 86
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1396: row 34, X speed +80
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1404: byte 87
                lda     ,x+                     ;  6 t = 1408: byte 88
                ldb     ,x+                     ;  6 t = 1414: byte 89
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1426: row 35, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1436: byte 89
                lda     ,x+                     ;  6 t = 1440: byte 90
                ldb     ,x+                     ;  6 t = 1446: byte 91
                sta     <VIA_shift_reg          ;  4 t = 1452: byte 90
                stu     <VIA_port_b             ;  5 t = 1456: row 36, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1468: byte 91
                lda     ,x+                     ;  6 t = 1472: byte 92
                ldb     ,x+                     ;  6 t = 1478: byte 93
                sta     <VIA_shift_reg          ;  4 t = 1484: byte 92
                sty     <VIA_port_b             ;  6 t = 1488: row 37, X speed -80
                lda     ,x+                     ;  6 t = 1494: byte 94
                stb     <VIA_shift_reg          ;  4 t = 1500: byte 93
                ldb     ,x+                     ;  6 t = 1504: byte 95
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1516: byte 94
                stu     <VIA_port_b             ;  5 t = 1520: row 38, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1532: byte 95
                lda     ,x+                     ;  6 t = 1536: byte 96
                ldb     ,x+                     ;  6 t = 1542: byte 97
                sta     <VIA_shift_reg          ;  4 t = 1548: byte 96
                sty     <VIA_port_b             ;  6 t = 1552: row 39, X speed -80
                lda     ,x+                     ;  6 t = 1558: byte 98
                stb     <VIA_shift_reg          ;  4 t = 1564: byte 97
                ldb     ,x+                     ;  6 t = 1568: byte 99
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1580: byte 98
                stu     <VIA_port_b             ;  5 t = 1584: row 40, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1596: byte 99
                lda     ,x+                     ;  6 t = 1600: byte 100
                ldb     ,x+                     ;  6 t = 1606: byte 101
                sta     <VIA_shift_reg          ;  4 t = 1612: byte 100
                sty     <VIA_port_b             ;  6 t = 1616: row 41, X speed -80
                lda     ,x+                     ;  6 t = 1622: byte 102
                stb     <VIA_shift_reg          ;  4 t = 1628: byte 101
                ldb     ,x+                     ;  6 t = 1632: byte 103
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1644: byte 102
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1652: row 42, X speed +80
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1660: byte 103
                lda     ,x+                     ;  6 t = 1664: byte 104
                ldb     ,x+                     ;  6 t = 1670: byte 105
                sta     <VIA_shift_reg          ;  4 t = 1676: byte 104
                lda     ,x+                     ;  6 t = 1680: byte 106
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1692: byte 105
                sty     <VIA_port_b             ;  6 t = 1696: row 43, X speed -80
                ldb     ,x+                     ;  6 t = 1702: byte 107
                sta     <VIA_shift_reg          ;  4 t = 1708: byte 106
                lda     ,x+                     ;  6 t = 1712: byte 108
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1724: byte 107
                ldb     ,x+                     ;  6 t = 1728: byte 109
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1740: byte 108
                stu     <VIA_port_b             ;  5 t = 1744: row 44, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1756: byte 109
                lda     ,x+                     ;  6 t = 1760: byte 110
                ldb     ,x+                     ;  6 t = 1766: byte 111
                sta     <VIA_shift_reg          ;  4 t = 1772: byte 110
                lda     ,x+                     ;  6 t = 1776: byte 112
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1788: byte 111
                sty     <VIA_port_b             ;  6 t = 1792: row 45, X speed -80
                ldb     ,x+                     ;  6 t = 1798: byte 113
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
                stu     <VIA_port_b             ;  5 t = 1840: row 46, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1852: byte 115
                lda     ,x+                     ;  6 t = 1856: byte 116
                ldb     ,x+                     ;  6 t = 1862: byte 117
                sta     <VIA_shift_reg          ;  4 t = 1868: byte 116
                lda     ,x+                     ;  6 t = 1872: byte 118
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1884: byte 117
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 1891: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1900: byte 118
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 19 x 23: 31 rows (pitch 0.76 pixels), drift 3, 79 bytes: ramp on 1251 cycles
; in: X = the data, the beam at the sprite's top left
zig_hooter_3
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
                sty     <VIA_port_b             ;  6 t = 290: row 7, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                stu     <VIA_port_b             ;  5 t = 320: row 8, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                ldb     ,x+                     ;  6 t = 336: byte 21
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                sty     <VIA_port_b             ;  6 t = 352: row 9, X speed -80
                ldb     ,x+                     ;  6 t = 358: byte 23
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                stu     <VIA_port_b             ;  5 t = 384: row 10, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 418: row 11, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                ldb     ,x+                     ;  6 t = 432: byte 27
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 455: row 12, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                ldb     ,x+                     ;  6 t = 464: byte 29
                lda     ,x+                     ;  6 t = 470: byte 30
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                ldb     ,x+                     ;  6 t = 480: byte 31
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                sty     <VIA_port_b             ;  6 t = 496: row 13, X speed -80
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                lda     ,x+                     ;  6 t = 528: byte 34
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                stu     <VIA_port_b             ;  5 t = 544: row 14, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                ldb     ,x+                     ;  6 t = 560: byte 35
                lda     ,x+                     ;  6 t = 566: byte 36
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                ldb     ,x+                     ;  6 t = 576: byte 37
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                sty     <VIA_port_b             ;  6 t = 592: row 15, X speed -80
                lda     ,x+                     ;  6 t = 598: byte 38
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                stu     <VIA_port_b             ;  5 t = 640: row 16, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                ldb     ,x+                     ;  6 t = 656: byte 41
                lda     ,x+                     ;  6 t = 662: byte 42
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                ldb     ,x+                     ;  6 t = 672: byte 43
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                sty     <VIA_port_b             ;  6 t = 688: row 17, X speed -80
                lda     ,x+                     ;  6 t = 694: byte 44
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                ldb     ,x+                     ;  6 t = 704: byte 45
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                lda     ,x+                     ;  6 t = 720: byte 46
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                stu     <VIA_port_b             ;  5 t = 736: row 18, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                ldb     ,x+                     ;  6 t = 752: byte 47
                lda     ,x+                     ;  6 t = 758: byte 48
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                ldb     ,x+                     ;  6 t = 768: byte 49
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                sty     <VIA_port_b             ;  6 t = 784: row 19, X speed -80
                lda     ,x+                     ;  6 t = 790: byte 50
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                ldb     ,x+                     ;  6 t = 800: byte 51
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                lda     ,x+                     ;  6 t = 816: byte 52
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                stu     <VIA_port_b             ;  5 t = 832: row 20, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                ldb     ,x+                     ;  6 t = 848: byte 53
                lda     ,x+                     ;  6 t = 854: byte 54
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                ldb     ,x+                     ;  6 t = 864: byte 55
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                sty     <VIA_port_b             ;  6 t = 880: row 21, X speed -80
                lda     ,x+                     ;  6 t = 886: byte 56
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                ldb     ,x+                     ;  6 t = 896: byte 57
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 916: row 22, X speed +80
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                lda     ,x+                     ;  6 t = 928: byte 58
                ldb     ,x+                     ;  6 t = 934: byte 59
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 946: row 23, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                lda     ,x+                     ;  6 t = 960: byte 60
                ldb     ,x+                     ;  6 t = 966: byte 61
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                stu     <VIA_port_b             ;  5 t = 976: row 24, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                lda     ,x+                     ;  6 t = 992: byte 62
                ldb     ,x+                     ;  6 t = 998: byte 63
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                sty     <VIA_port_b             ;  6 t = 1008: row 25, X speed -80
                lda     ,x+                     ;  6 t = 1014: byte 64
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                ldb     ,x+                     ;  6 t = 1024: byte 65
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                stu     <VIA_port_b             ;  5 t = 1040: row 26, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                lda     ,x+                     ;  6 t = 1056: byte 66
                ldb     ,x+                     ;  6 t = 1062: byte 67
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                sty     <VIA_port_b             ;  6 t = 1072: row 27, X speed -80
                lda     ,x+                     ;  6 t = 1078: byte 68
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                ldb     ,x+                     ;  6 t = 1088: byte 69
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1108: row 28, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 1152: row 29, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 1200: row 30, X speed +80
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
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 1251: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 19 x 23: 24 rows (pitch 0.99 pixels), drift 4, 60 bytes: ramp on 947 cycles
; in: X = the data, the beam at the sprite's top left
zig_hooter_4
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
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 212: row 5, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                lda     ,x+                     ;  6 t = 224: byte 14
                ldb     ,x+                     ;  6 t = 230: byte 15
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                stu     <VIA_port_b             ;  5 t = 240: row 6, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                lda     ,x+                     ;  6 t = 256: byte 16
                ldb     ,x+                     ;  6 t = 262: byte 17
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                sty     <VIA_port_b             ;  6 t = 272: row 7, X speed -80
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                ldb     ,x+                     ;  6 t = 288: byte 19
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 306: row 8, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                lda     ,x+                     ;  6 t = 320: byte 20
                ldb     ,x+                     ;  6 t = 326: byte 21
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 340: row 9, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                lda     ,x+                     ;  6 t = 352: byte 22
                ldb     ,x+                     ;  6 t = 358: byte 23
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                stu     <VIA_port_b             ;  5 t = 384: row 10, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 432: row 11, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 480: row 12, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 528: row 13, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 576: row 14, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 624: row 15, X speed -80
                lda     ,x+                     ;  6 t = 630: byte 40
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                ldb     ,x+                     ;  6 t = 640: byte 41
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 660: row 16, X speed +80
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                lda     ,x+                     ;  6 t = 672: byte 42
                ldb     ,x+                     ;  6 t = 678: byte 43
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 690: row 17, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                lda     ,x+                     ;  6 t = 704: byte 44
                ldb     ,x+                     ;  6 t = 710: byte 45
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                stu     <VIA_port_b             ;  5 t = 720: row 18, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                lda     ,x+                     ;  6 t = 736: byte 46
                ldb     ,x+                     ;  6 t = 742: byte 47
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                sty     <VIA_port_b             ;  6 t = 752: row 19, X speed -80
                lda     ,x+                     ;  6 t = 758: byte 48
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                ldb     ,x+                     ;  6 t = 768: byte 49
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                stu     <VIA_port_b             ;  5 t = 784: row 20, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                lda     ,x+                     ;  6 t = 800: byte 50
                ldb     ,x+                     ;  6 t = 806: byte 51
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                sty     <VIA_port_b             ;  6 t = 816: row 21, X speed -80
                lda     ,x+                     ;  6 t = 822: byte 52
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 852: row 22, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 896: row 23, X speed -80
                ldb     ,x+                     ;  6 t = 902: byte 57
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                lda     ,x+                     ;  6 t = 912: byte 58
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                ldb     ,x+                     ;  6 t = 928: byte 59
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 947: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 33 x 42: 117 rows (pitch 0.36 pixels), drift 1, 422 bytes: ramp on 6739 cycles
; in: X = the data, the beam at the sprite's top left
zig_scrubbly_1
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
                ldy     #$80FF                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -1 (the drift down)
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
                sty     <VIA_port_b             ;  6 t = 50: row 1, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                lda     ,x+                     ;  6 t = 64: byte 4
                ldb     ,x+                     ;  6 t = 70: byte 5
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 82: row 2, X speed +80
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
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 151: row 4, X speed +80
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                lda     ,x+                     ;  6 t = 160: byte 10
                ldb     ,x+                     ;  6 t = 166: byte 11
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                sty     <VIA_port_b             ;  6 t = 192: row 5, X speed -80
                ldb     ,x+                     ;  6 t = 198: byte 13
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                lda     ,x+                     ;  6 t = 208: byte 14
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                stu     <VIA_port_b             ;  5 t = 240: row 6, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                lda     ,x+                     ;  6 t = 256: byte 16
                ldb     ,x+                     ;  6 t = 262: byte 17
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                sty     <VIA_port_b             ;  6 t = 288: row 7, X speed -80
                ldb     ,x+                     ;  6 t = 294: byte 19
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                lda     ,x+                     ;  6 t = 304: byte 20
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                stu     <VIA_port_b             ;  5 t = 336: row 8, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                lda     ,x+                     ;  6 t = 352: byte 22
                ldb     ,x+                     ;  6 t = 358: byte 23
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                sty     <VIA_port_b             ;  6 t = 384: row 9, X speed -80
                ldb     ,x+                     ;  6 t = 390: byte 25
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                lda     ,x+                     ;  6 t = 400: byte 26
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                stu     <VIA_port_b             ;  5 t = 432: row 10, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                lda     ,x+                     ;  6 t = 448: byte 28
                ldb     ,x+                     ;  6 t = 454: byte 29
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                sty     <VIA_port_b             ;  6 t = 480: row 11, X speed -80
                ldb     ,x+                     ;  6 t = 486: byte 31
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                stu     <VIA_port_b             ;  5 t = 528: row 12, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                lda     ,x+                     ;  6 t = 544: byte 34
                ldb     ,x+                     ;  6 t = 550: byte 35
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                lda     ,x+                     ;  6 t = 560: byte 36
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                sty     <VIA_port_b             ;  6 t = 576: row 13, X speed -80
                ldb     ,x+                     ;  6 t = 582: byte 37
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                lda     ,x+                     ;  6 t = 592: byte 38
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                stu     <VIA_port_b             ;  5 t = 624: row 14, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                lda     ,x+                     ;  6 t = 640: byte 40
                ldb     ,x+                     ;  6 t = 646: byte 41
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                lda     ,x+                     ;  6 t = 656: byte 42
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                sty     <VIA_port_b             ;  6 t = 672: row 15, X speed -80
                ldb     ,x+                     ;  6 t = 678: byte 43
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                lda     ,x+                     ;  6 t = 688: byte 44
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                ldb     ,x+                     ;  6 t = 704: byte 45
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                stu     <VIA_port_b             ;  5 t = 720: row 16, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                lda     ,x+                     ;  6 t = 736: byte 46
                ldb     ,x+                     ;  6 t = 742: byte 47
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                lda     ,x+                     ;  6 t = 752: byte 48
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                sty     <VIA_port_b             ;  6 t = 768: row 17, X speed -80
                ldb     ,x+                     ;  6 t = 774: byte 49
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                lda     ,x+                     ;  6 t = 784: byte 50
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                ldb     ,x+                     ;  6 t = 800: byte 51
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                stu     <VIA_port_b             ;  5 t = 816: row 18, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                lda     ,x+                     ;  6 t = 832: byte 52
                ldb     ,x+                     ;  6 t = 838: byte 53
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                sty     <VIA_port_b             ;  6 t = 864: row 19, X speed -80
                ldb     ,x+                     ;  6 t = 870: byte 55
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                lda     ,x+                     ;  6 t = 880: byte 56
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                ldb     ,x+                     ;  6 t = 896: byte 57
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                stu     <VIA_port_b             ;  5 t = 912: row 20, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                lda     ,x+                     ;  6 t = 928: byte 58
                ldb     ,x+                     ;  6 t = 934: byte 59
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                sty     <VIA_port_b             ;  6 t = 944: row 21, X speed -80
                lda     ,x+                     ;  6 t = 950: byte 60
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                ldb     ,x+                     ;  6 t = 960: byte 61
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                stu     <VIA_port_b             ;  5 t = 976: row 22, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                lda     ,x+                     ;  6 t = 992: byte 62
                ldb     ,x+                     ;  6 t = 998: byte 63
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                sty     <VIA_port_b             ;  6 t = 1008: row 23, X speed -80
                lda     ,x+                     ;  6 t = 1014: byte 64
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                ldb     ,x+                     ;  6 t = 1024: byte 65
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                stu     <VIA_port_b             ;  5 t = 1040: row 24, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                lda     ,x+                     ;  6 t = 1056: byte 66
                ldb     ,x+                     ;  6 t = 1062: byte 67
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1076: row 25, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                lda     ,x+                     ;  6 t = 1088: byte 68
                ldb     ,x+                     ;  6 t = 1094: byte 69
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                stu     <VIA_port_b             ;  5 t = 1104: row 26, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                lda     ,x+                     ;  6 t = 1120: byte 70
                ldb     ,x+                     ;  6 t = 1126: byte 71
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                sty     <VIA_port_b             ;  6 t = 1136: row 27, X speed -80
                lda     ,x+                     ;  6 t = 1142: byte 72
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                ldb     ,x+                     ;  6 t = 1152: byte 73
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                stu     <VIA_port_b             ;  5 t = 1168: row 28, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                lda     ,x+                     ;  6 t = 1184: byte 74
                ldb     ,x+                     ;  6 t = 1190: byte 75
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                sty     <VIA_port_b             ;  6 t = 1200: row 29, X speed -80
                lda     ,x+                     ;  6 t = 1206: byte 76
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                ldb     ,x+                     ;  6 t = 1216: byte 77
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1234: row 30, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                lda     ,x+                     ;  6 t = 1248: byte 78
                ldb     ,x+                     ;  6 t = 1254: byte 79
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1268: row 31, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                lda     ,x+                     ;  6 t = 1280: byte 80
                ldb     ,x+                     ;  6 t = 1286: byte 81
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 1303: row 32, X speed +80
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                lda     ,x+                     ;  6 t = 1312: byte 82
                ldb     ,x+                     ;  6 t = 1318: byte 83
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                lda     ,x+                     ;  6 t = 1328: byte 84
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                sty     <VIA_port_b             ;  6 t = 1344: row 33, X speed -80
                ldb     ,x+                     ;  6 t = 1350: byte 85
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                lda     ,x+                     ;  6 t = 1360: byte 86
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1372: byte 85
                ldb     ,x+                     ;  6 t = 1376: byte 87
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1388: byte 86
                stu     <VIA_port_b             ;  5 t = 1392: row 34, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1404: byte 87
                lda     ,x+                     ;  6 t = 1408: byte 88
                ldb     ,x+                     ;  6 t = 1414: byte 89
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                lda     ,x+                     ;  6 t = 1424: byte 90
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1436: byte 89
                sty     <VIA_port_b             ;  6 t = 1440: row 35, X speed -80
                ldb     ,x+                     ;  6 t = 1446: byte 91
                sta     <VIA_shift_reg          ;  4 t = 1452: byte 90
                lda     ,x+                     ;  6 t = 1456: byte 92
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1468: byte 91
                ldb     ,x+                     ;  6 t = 1472: byte 93
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1484: byte 92
                stu     <VIA_port_b             ;  5 t = 1488: row 36, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1500: byte 93
                lda     ,x+                     ;  6 t = 1504: byte 94
                ldb     ,x+                     ;  6 t = 1510: byte 95
                sta     <VIA_shift_reg          ;  4 t = 1516: byte 94
                lda     ,x+                     ;  6 t = 1520: byte 96
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1532: byte 95
                sty     <VIA_port_b             ;  6 t = 1536: row 37, X speed -80
                ldb     ,x+                     ;  6 t = 1542: byte 97
                sta     <VIA_shift_reg          ;  4 t = 1548: byte 96
                lda     ,x+                     ;  6 t = 1552: byte 98
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1564: byte 97
                ldb     ,x+                     ;  6 t = 1568: byte 99
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1580: byte 98
                stu     <VIA_port_b             ;  5 t = 1584: row 38, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1596: byte 99
                lda     ,x+                     ;  6 t = 1600: byte 100
                ldb     ,x+                     ;  6 t = 1606: byte 101
                sta     <VIA_shift_reg          ;  4 t = 1612: byte 100
                lda     ,x+                     ;  6 t = 1616: byte 102
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1628: byte 101
                sty     <VIA_port_b             ;  6 t = 1632: row 39, X speed -80
                ldb     ,x+                     ;  6 t = 1638: byte 103
                sta     <VIA_shift_reg          ;  4 t = 1644: byte 102
                lda     ,x+                     ;  6 t = 1648: byte 104
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1660: byte 103
                ldb     ,x+                     ;  6 t = 1664: byte 105
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1676: byte 104
                stu     <VIA_port_b             ;  5 t = 1680: row 40, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1692: byte 105
                lda     ,x+                     ;  6 t = 1696: byte 106
                ldb     ,x+                     ;  6 t = 1702: byte 107
                sta     <VIA_shift_reg          ;  4 t = 1708: byte 106
                lda     ,x+                     ;  6 t = 1712: byte 108
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1724: byte 107
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1730: row 41, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1740: byte 108
                ldb     ,x+                     ;  6 t = 1744: byte 109
                lda     ,x+                     ;  6 t = 1750: byte 110
                stb     <VIA_shift_reg          ;  4 t = 1756: byte 109
                ldb     ,x+                     ;  6 t = 1760: byte 111
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1772: byte 110
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1780: row 42, X speed +80
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1788: byte 111
                lda     ,x+                     ;  6 t = 1792: byte 112
                ldb     ,x+                     ;  6 t = 1798: byte 113
                sta     <VIA_shift_reg          ;  4 t = 1804: byte 112
                lda     ,x+                     ;  6 t = 1808: byte 114
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1820: byte 113
                ldb     ,x+                     ;  6 t = 1824: byte 115
                sty     <VIA_port_b             ;  6 t = 1830: row 43, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 1836: byte 114
                lda     ,x+                     ;  6 t = 1840: byte 116
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                stu     <VIA_port_b             ;  5 t = 1888: row 44, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1900: byte 118
                ldb     ,x+                     ;  6 t = 1904: byte 119
                lda     ,x+                     ;  6 t = 1910: byte 120
                stb     <VIA_shift_reg          ;  4 t = 1916: byte 119
                ldb     ,x+                     ;  6 t = 1920: byte 121
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1932: byte 120
                lda     ,x+                     ;  6 t = 1936: byte 122
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1948: byte 121
                sty     <VIA_port_b             ;  6 t = 1952: row 45, X speed -80
                ldb     ,x+                     ;  6 t = 1958: byte 123
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
                lda     ,x+                     ;  6 t = 2000: byte 126
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2012: byte 125
                stu     <VIA_port_b             ;  5 t = 2016: row 46, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2028: byte 126
                ldb     ,x+                     ;  6 t = 2032: byte 127
                lda     ,x+                     ;  6 t = 2038: byte 128
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
                sty     <VIA_port_b             ;  6 t = 2080: row 47, X speed -80
                ldb     ,x+                     ;  6 t = 2086: byte 131
                sta     <VIA_shift_reg          ;  4 t = 2092: byte 130
                lda     ,x+                     ;  6 t = 2096: byte 132
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                stu     <VIA_port_b             ;  5 t = 2144: row 48, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2156: byte 134
                ldb     ,x+                     ;  6 t = 2160: byte 135
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
                sty     <VIA_port_b             ;  6 t = 2208: row 49, X speed -80
                ldb     ,x+                     ;  6 t = 2214: byte 139
                sta     <VIA_shift_reg          ;  4 t = 2220: byte 138
                lda     ,x+                     ;  6 t = 2224: byte 140
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2236: byte 139
                ldb     ,x+                     ;  6 t = 2240: byte 141
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2252: byte 140
                lda     ,x+                     ;  6 t = 2256: byte 142
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2268: byte 141
                stu     <VIA_port_b             ;  5 t = 2272: row 50, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2284: byte 142
                ldb     ,x+                     ;  6 t = 2288: byte 143
                lda     ,x+                     ;  6 t = 2294: byte 144
                stb     <VIA_shift_reg          ;  4 t = 2300: byte 143
                ldb     ,x+                     ;  6 t = 2304: byte 145
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2316: byte 144
                lda     ,x+                     ;  6 t = 2320: byte 146
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2332: byte 145
                sty     <VIA_port_b             ;  6 t = 2336: row 51, X speed -80
                ldb     ,x+                     ;  6 t = 2342: byte 147
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
                stu     <VIA_port_b             ;  5 t = 2400: row 52, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 2464: row 53, X speed -80
                ldb     ,x+                     ;  6 t = 2470: byte 155
                sta     <VIA_shift_reg          ;  4 t = 2476: byte 154
                lda     ,x+                     ;  6 t = 2480: byte 156
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                stu     <VIA_port_b             ;  5 t = 2528: row 54, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2540: byte 158
                ldb     ,x+                     ;  6 t = 2544: byte 159
                lda     ,x+                     ;  6 t = 2550: byte 160
                stb     <VIA_shift_reg          ;  4 t = 2556: byte 159
                ldb     ,x+                     ;  6 t = 2560: byte 161
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2572: byte 160
                lda     ,x+                     ;  6 t = 2576: byte 162
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2588: byte 161
                sty     <VIA_port_b             ;  6 t = 2592: row 55, X speed -80
                ldb     ,x+                     ;  6 t = 2598: byte 163
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
                lda     ,x+                     ;  6 t = 2640: byte 166
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2652: byte 165
                stu     <VIA_port_b             ;  5 t = 2656: row 56, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2668: byte 166
                ldb     ,x+                     ;  6 t = 2672: byte 167
                lda     ,x+                     ;  6 t = 2678: byte 168
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
                sty     <VIA_port_b             ;  6 t = 2720: row 57, X speed -80
                ldb     ,x+                     ;  6 t = 2726: byte 171
                sta     <VIA_shift_reg          ;  4 t = 2732: byte 170
                lda     ,x+                     ;  6 t = 2736: byte 172
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                stu     <VIA_port_b             ;  5 t = 2784: row 58, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2796: byte 174
                ldb     ,x+                     ;  6 t = 2800: byte 175
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
                sty     <VIA_port_b             ;  6 t = 2848: row 59, X speed -80
                ldb     ,x+                     ;  6 t = 2854: byte 179
                sta     <VIA_shift_reg          ;  4 t = 2860: byte 178
                lda     ,x+                     ;  6 t = 2864: byte 180
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2876: byte 179
                ldb     ,x+                     ;  6 t = 2880: byte 181
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2892: byte 180
                lda     ,x+                     ;  6 t = 2896: byte 182
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2908: byte 181
                stu     <VIA_port_b             ;  5 t = 2912: row 60, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2924: byte 182
                ldb     ,x+                     ;  6 t = 2928: byte 183
                lda     ,x+                     ;  6 t = 2934: byte 184
                stb     <VIA_shift_reg          ;  4 t = 2940: byte 183
                ldb     ,x+                     ;  6 t = 2944: byte 185
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2956: byte 184
                lda     ,x+                     ;  6 t = 2960: byte 186
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2972: byte 185
                sty     <VIA_port_b             ;  6 t = 2976: row 61, X speed -80
                ldb     ,x+                     ;  6 t = 2982: byte 187
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
                stu     <VIA_port_b             ;  5 t = 3040: row 62, X speed +80
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
                sty     <VIA_port_b             ;  6 t = 3104: row 63, X speed -80
                ldb     ,x+                     ;  6 t = 3110: byte 195
                sta     <VIA_shift_reg          ;  4 t = 3116: byte 194
                lda     ,x+                     ;  6 t = 3120: byte 196
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                stu     <VIA_port_b             ;  5 t = 3168: row 64, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 3180: byte 198
                ldb     ,x+                     ;  6 t = 3184: byte 199
                lda     ,x+                     ;  6 t = 3190: byte 200
                stb     <VIA_shift_reg          ;  4 t = 3196: byte 199
                ldb     ,x+                     ;  6 t = 3200: byte 201
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3212: byte 200
                lda     ,x+                     ;  6 t = 3216: byte 202
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3228: byte 201
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 3234: row 65, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3244: byte 202
                ldb     ,x+                     ;  6 t = 3248: byte 203
                lda     ,x+                     ;  6 t = 3254: byte 204
                stb     <VIA_shift_reg          ;  4 t = 3260: byte 203
                ldb     ,x+                     ;  6 t = 3264: byte 205
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3276: byte 204
                lda     ,x+                     ;  6 t = 3280: byte 206
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3292: byte 205
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 3300: row 66, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 3308: byte 206
                ldb     ,x+                     ;  6 t = 3312: byte 207
                lda     ,x+                     ;  6 t = 3318: byte 208
                stb     <VIA_shift_reg          ;  4 t = 3324: byte 207
                ldb     ,x+                     ;  6 t = 3328: byte 209
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3340: byte 208
                lda     ,x+                     ;  6 t = 3344: byte 210
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3356: byte 209
                ldb     ,x+                     ;  6 t = 3360: byte 211
                sty     <VIA_port_b             ;  6 t = 3366: row 67, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 3372: byte 210
                lda     ,x+                     ;  6 t = 3376: byte 212
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3388: byte 211
                ldb     ,x+                     ;  6 t = 3392: byte 213
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3404: byte 212
                lda     ,x+                     ;  6 t = 3408: byte 214
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3420: byte 213
                ldb     ,x+                     ;  6 t = 3424: byte 215
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3436: byte 214
                stu     <VIA_port_b             ;  5 t = 3440: row 68, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 3452: byte 215
                lda     ,x+                     ;  6 t = 3456: byte 216
                ldb     ,x+                     ;  6 t = 3462: byte 217
                sta     <VIA_shift_reg          ;  4 t = 3468: byte 216
                lda     ,x+                     ;  6 t = 3472: byte 218
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3484: byte 217
                ldb     ,x+                     ;  6 t = 3488: byte 219
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3500: byte 218
                lda     ,x+                     ;  6 t = 3504: byte 220
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3516: byte 219
                sty     <VIA_port_b             ;  6 t = 3520: row 69, X speed -80
                ldb     ,x+                     ;  6 t = 3526: byte 221
                sta     <VIA_shift_reg          ;  4 t = 3532: byte 220
                lda     ,x+                     ;  6 t = 3536: byte 222
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3548: byte 221
                ldb     ,x+                     ;  6 t = 3552: byte 223
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3564: byte 222
                lda     ,x+                     ;  6 t = 3568: byte 224
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3580: byte 223
                ldb     ,x+                     ;  6 t = 3584: byte 225
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3596: byte 224
                stu     <VIA_port_b             ;  5 t = 3600: row 70, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 3612: byte 225
                lda     ,x+                     ;  6 t = 3616: byte 226
                ldb     ,x+                     ;  6 t = 3622: byte 227
                sta     <VIA_shift_reg          ;  4 t = 3628: byte 226
                lda     ,x+                     ;  6 t = 3632: byte 228
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3644: byte 227
                ldb     ,x+                     ;  6 t = 3648: byte 229
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3660: byte 228
                lda     ,x+                     ;  6 t = 3664: byte 230
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3676: byte 229
                sty     <VIA_port_b             ;  6 t = 3680: row 71, X speed -80
                ldb     ,x+                     ;  6 t = 3686: byte 231
                sta     <VIA_shift_reg          ;  4 t = 3692: byte 230
                lda     ,x+                     ;  6 t = 3696: byte 232
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3708: byte 231
                ldb     ,x+                     ;  6 t = 3712: byte 233
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3724: byte 232
                lda     ,x+                     ;  6 t = 3728: byte 234
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3740: byte 233
                ldb     ,x+                     ;  6 t = 3744: byte 235
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3756: byte 234
                stu     <VIA_port_b             ;  5 t = 3760: row 72, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 3772: byte 235
                lda     ,x+                     ;  6 t = 3776: byte 236
                ldb     ,x+                     ;  6 t = 3782: byte 237
                sta     <VIA_shift_reg          ;  4 t = 3788: byte 236
                lda     ,x+                     ;  6 t = 3792: byte 238
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3804: byte 237
                ldb     ,x+                     ;  6 t = 3808: byte 239
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3820: byte 238
                lda     ,x+                     ;  6 t = 3824: byte 240
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3836: byte 239
                sty     <VIA_port_b             ;  6 t = 3840: row 73, X speed -80
                ldb     ,x+                     ;  6 t = 3846: byte 241
                sta     <VIA_shift_reg          ;  4 t = 3852: byte 240
                lda     ,x+                     ;  6 t = 3856: byte 242
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3868: byte 241
                ldb     ,x+                     ;  6 t = 3872: byte 243
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3884: byte 242
                lda     ,x+                     ;  6 t = 3888: byte 244
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3900: byte 243
                ldb     ,x+                     ;  6 t = 3904: byte 245
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3916: byte 244
                stu     <VIA_port_b             ;  5 t = 3920: row 74, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 3932: byte 245
                lda     ,x+                     ;  6 t = 3936: byte 246
                ldb     ,x+                     ;  6 t = 3942: byte 247
                sta     <VIA_shift_reg          ;  4 t = 3948: byte 246
                lda     ,x+                     ;  6 t = 3952: byte 248
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3964: byte 247
                ldb     ,x+                     ;  6 t = 3968: byte 249
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3980: byte 248
                lda     ,x+                     ;  6 t = 3984: byte 250
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3996: byte 249
                sty     <VIA_port_b             ;  6 t = 4000: row 75, X speed -80
                ldb     ,x+                     ;  6 t = 4006: byte 251
                sta     <VIA_shift_reg          ;  4 t = 4012: byte 250
                lda     ,x+                     ;  6 t = 4016: byte 252
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4028: byte 251
                ldb     ,x+                     ;  6 t = 4032: byte 253
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4044: byte 252
                lda     ,x+                     ;  6 t = 4048: byte 254
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4060: byte 253
                ldb     ,x+                     ;  6 t = 4064: byte 255
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4076: byte 254
                stu     <VIA_port_b             ;  5 t = 4080: row 76, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 4092: byte 255
                lda     ,x+                     ;  6 t = 4096: byte 256
                ldb     ,x+                     ;  6 t = 4102: byte 257
                sta     <VIA_shift_reg          ;  4 t = 4108: byte 256
                lda     ,x+                     ;  6 t = 4112: byte 258
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4124: byte 257
                ldb     ,x+                     ;  6 t = 4128: byte 259
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4140: byte 258
                lda     ,x+                     ;  6 t = 4144: byte 260
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4156: byte 259
                sty     <VIA_port_b             ;  6 t = 4160: row 77, X speed -80
                ldb     ,x+                     ;  6 t = 4166: byte 261
                sta     <VIA_shift_reg          ;  4 t = 4172: byte 260
                lda     ,x+                     ;  6 t = 4176: byte 262
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4188: byte 261
                ldb     ,x+                     ;  6 t = 4192: byte 263
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4204: byte 262
                lda     ,x+                     ;  6 t = 4208: byte 264
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4220: byte 263
                ldb     ,x+                     ;  6 t = 4224: byte 265
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4236: byte 264
                stu     <VIA_port_b             ;  5 t = 4240: row 78, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 4252: byte 265
                lda     ,x+                     ;  6 t = 4256: byte 266
                ldb     ,x+                     ;  6 t = 4262: byte 267
                sta     <VIA_shift_reg          ;  4 t = 4268: byte 266
                lda     ,x+                     ;  6 t = 4272: byte 268
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4284: byte 267
                ldb     ,x+                     ;  6 t = 4288: byte 269
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4300: byte 268
                lda     ,x+                     ;  6 t = 4304: byte 270
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4316: byte 269
                sty     <VIA_port_b             ;  6 t = 4320: row 79, X speed -80
                ldb     ,x+                     ;  6 t = 4326: byte 271
                sta     <VIA_shift_reg          ;  4 t = 4332: byte 270
                lda     ,x+                     ;  6 t = 4336: byte 272
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4348: byte 271
                ldb     ,x+                     ;  6 t = 4352: byte 273
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4364: byte 272
                lda     ,x+                     ;  6 t = 4368: byte 274
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4380: byte 273
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 4388: row 80, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 4396: byte 274
                ldb     ,x+                     ;  6 t = 4400: byte 275
                lda     ,x+                     ;  6 t = 4406: byte 276
                stb     <VIA_shift_reg          ;  4 t = 4412: byte 275
                ldb     ,x+                     ;  6 t = 4416: byte 277
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4428: byte 276
                lda     ,x+                     ;  6 t = 4432: byte 278
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4444: byte 277
                sty     <VIA_port_b             ;  6 t = 4448: row 81, X speed -80
                ldb     ,x+                     ;  6 t = 4454: byte 279
                sta     <VIA_shift_reg          ;  4 t = 4460: byte 278
                lda     ,x+                     ;  6 t = 4464: byte 280
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4476: byte 279
                ldb     ,x+                     ;  6 t = 4480: byte 281
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4492: byte 280
                lda     ,x+                     ;  6 t = 4496: byte 282
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4508: byte 281
                stu     <VIA_port_b             ;  5 t = 4512: row 82, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 4524: byte 282
                ldb     ,x+                     ;  6 t = 4528: byte 283
                lda     ,x+                     ;  6 t = 4534: byte 284
                stb     <VIA_shift_reg          ;  4 t = 4540: byte 283
                ldb     ,x+                     ;  6 t = 4544: byte 285
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4556: byte 284
                lda     ,x+                     ;  6 t = 4560: byte 286
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4572: byte 285
                sty     <VIA_port_b             ;  6 t = 4576: row 83, X speed -80
                ldb     ,x+                     ;  6 t = 4582: byte 287
                sta     <VIA_shift_reg          ;  4 t = 4588: byte 286
                lda     ,x+                     ;  6 t = 4592: byte 288
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4604: byte 287
                ldb     ,x+                     ;  6 t = 4608: byte 289
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4620: byte 288
                lda     ,x+                     ;  6 t = 4624: byte 290
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4636: byte 289
                stu     <VIA_port_b             ;  5 t = 4640: row 84, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 4652: byte 290
                ldb     ,x+                     ;  6 t = 4656: byte 291
                lda     ,x+                     ;  6 t = 4662: byte 292
                stb     <VIA_shift_reg          ;  4 t = 4668: byte 291
                ldb     ,x+                     ;  6 t = 4672: byte 293
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4684: byte 292
                lda     ,x+                     ;  6 t = 4688: byte 294
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4700: byte 293
                sty     <VIA_port_b             ;  6 t = 4704: row 85, X speed -80
                ldb     ,x+                     ;  6 t = 4710: byte 295
                sta     <VIA_shift_reg          ;  4 t = 4716: byte 294
                lda     ,x+                     ;  6 t = 4720: byte 296
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4732: byte 295
                ldb     ,x+                     ;  6 t = 4736: byte 297
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4748: byte 296
                lda     ,x+                     ;  6 t = 4752: byte 298
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4764: byte 297
                stu     <VIA_port_b             ;  5 t = 4768: row 86, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 4780: byte 298
                ldb     ,x+                     ;  6 t = 4784: byte 299
                lda     ,x+                     ;  6 t = 4790: byte 300
                stb     <VIA_shift_reg          ;  4 t = 4796: byte 299
                ldb     ,x+                     ;  6 t = 4800: byte 301
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4812: byte 300
                lda     ,x+                     ;  6 t = 4816: byte 302
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4828: byte 301
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 4834: row 87, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4844: byte 302
                ldb     ,x+                     ;  6 t = 4848: byte 303
                lda     ,x+                     ;  6 t = 4854: byte 304
                stb     <VIA_shift_reg          ;  4 t = 4860: byte 303
                ldb     ,x+                     ;  6 t = 4864: byte 305
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4876: byte 304
                lda     ,x+                     ;  6 t = 4880: byte 306
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4892: byte 305
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 4900: row 88, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 4908: byte 306
                ldb     ,x+                     ;  6 t = 4912: byte 307
                lda     ,x+                     ;  6 t = 4918: byte 308
                stb     <VIA_shift_reg          ;  4 t = 4924: byte 307
                ldb     ,x+                     ;  6 t = 4928: byte 309
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 4940: byte 308
                lda     ,x+                     ;  6 t = 4944: byte 310
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4956: byte 309
                ldb     ,x+                     ;  6 t = 4960: byte 311
                sty     <VIA_port_b             ;  6 t = 4966: row 89, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 4972: byte 310
                lda     ,x+                     ;  6 t = 4976: byte 312
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 4988: byte 311
                ldb     ,x+                     ;  6 t = 4992: byte 313
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5004: byte 312
                lda     ,x+                     ;  6 t = 5008: byte 314
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5020: byte 313
                ldb     ,x+                     ;  6 t = 5024: byte 315
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5036: byte 314
                stu     <VIA_port_b             ;  5 t = 5040: row 90, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 5052: byte 315
                lda     ,x+                     ;  6 t = 5056: byte 316
                ldb     ,x+                     ;  6 t = 5062: byte 317
                sta     <VIA_shift_reg          ;  4 t = 5068: byte 316
                lda     ,x+                     ;  6 t = 5072: byte 318
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5084: byte 317
                ldb     ,x+                     ;  6 t = 5088: byte 319
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5100: byte 318
                lda     ,x+                     ;  6 t = 5104: byte 320
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5116: byte 319
                sty     <VIA_port_b             ;  6 t = 5120: row 91, X speed -80
                ldb     ,x+                     ;  6 t = 5126: byte 321
                sta     <VIA_shift_reg          ;  4 t = 5132: byte 320
                lda     ,x+                     ;  6 t = 5136: byte 322
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5148: byte 321
                ldb     ,x+                     ;  6 t = 5152: byte 323
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5164: byte 322
                lda     ,x+                     ;  6 t = 5168: byte 324
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5180: byte 323
                ldb     ,x+                     ;  6 t = 5184: byte 325
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5196: byte 324
                stu     <VIA_port_b             ;  5 t = 5200: row 92, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 5212: byte 325
                lda     ,x+                     ;  6 t = 5216: byte 326
                ldb     ,x+                     ;  6 t = 5222: byte 327
                sta     <VIA_shift_reg          ;  4 t = 5228: byte 326
                lda     ,x+                     ;  6 t = 5232: byte 328
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5244: byte 327
                ldb     ,x+                     ;  6 t = 5248: byte 329
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5260: byte 328
                lda     ,x+                     ;  6 t = 5264: byte 330
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5276: byte 329
                sty     <VIA_port_b             ;  6 t = 5280: row 93, X speed -80
                ldb     ,x+                     ;  6 t = 5286: byte 331
                sta     <VIA_shift_reg          ;  4 t = 5292: byte 330
                lda     ,x+                     ;  6 t = 5296: byte 332
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5308: byte 331
                ldb     ,x+                     ;  6 t = 5312: byte 333
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5324: byte 332
                lda     ,x+                     ;  6 t = 5328: byte 334
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5340: byte 333
                ldb     ,x+                     ;  6 t = 5344: byte 335
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5356: byte 334
                stu     <VIA_port_b             ;  5 t = 5360: row 94, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 5372: byte 335
                lda     ,x+                     ;  6 t = 5376: byte 336
                ldb     ,x+                     ;  6 t = 5382: byte 337
                sta     <VIA_shift_reg          ;  4 t = 5388: byte 336
                lda     ,x+                     ;  6 t = 5392: byte 338
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5404: byte 337
                ldb     ,x+                     ;  6 t = 5408: byte 339
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5420: byte 338
                lda     ,x+                     ;  6 t = 5424: byte 340
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5436: byte 339
                sty     <VIA_port_b             ;  6 t = 5440: row 95, X speed -80
                ldb     ,x+                     ;  6 t = 5446: byte 341
                sta     <VIA_shift_reg          ;  4 t = 5452: byte 340
                lda     ,x+                     ;  6 t = 5456: byte 342
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5468: byte 341
                ldb     ,x+                     ;  6 t = 5472: byte 343
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5484: byte 342
                lda     ,x+                     ;  6 t = 5488: byte 344
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5500: byte 343
                ldb     ,x+                     ;  6 t = 5504: byte 345
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5516: byte 344
                stu     <VIA_port_b             ;  5 t = 5520: row 96, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 5532: byte 345
                lda     ,x+                     ;  6 t = 5536: byte 346
                ldb     ,x+                     ;  6 t = 5542: byte 347
                sta     <VIA_shift_reg          ;  4 t = 5548: byte 346
                lda     ,x+                     ;  6 t = 5552: byte 348
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5564: byte 347
                ldb     ,x+                     ;  6 t = 5568: byte 349
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5580: byte 348
                lda     ,x+                     ;  6 t = 5584: byte 350
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5596: byte 349
                sty     <VIA_port_b             ;  6 t = 5600: row 97, X speed -80
                ldb     ,x+                     ;  6 t = 5606: byte 351
                sta     <VIA_shift_reg          ;  4 t = 5612: byte 350
                lda     ,x+                     ;  6 t = 5616: byte 352
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5628: byte 351
                ldb     ,x+                     ;  6 t = 5632: byte 353
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5644: byte 352
                lda     ,x+                     ;  6 t = 5648: byte 354
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5660: byte 353
                ldb     ,x+                     ;  6 t = 5664: byte 355
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5676: byte 354
                stu     <VIA_port_b             ;  5 t = 5680: row 98, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 5692: byte 355
                lda     ,x+                     ;  6 t = 5696: byte 356
                ldb     ,x+                     ;  6 t = 5702: byte 357
                sta     <VIA_shift_reg          ;  4 t = 5708: byte 356
                lda     ,x+                     ;  6 t = 5712: byte 358
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5724: byte 357
                ldb     ,x+                     ;  6 t = 5728: byte 359
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5740: byte 358
                lda     ,x+                     ;  6 t = 5744: byte 360
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5756: byte 359
                sty     <VIA_port_b             ;  6 t = 5760: row 99, X speed -80
                ldb     ,x+                     ;  6 t = 5766: byte 361
                sta     <VIA_shift_reg          ;  4 t = 5772: byte 360
                lda     ,x+                     ;  6 t = 5776: byte 362
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5788: byte 361
                ldb     ,x+                     ;  6 t = 5792: byte 363
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5804: byte 362
                lda     ,x+                     ;  6 t = 5808: byte 364
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5820: byte 363
                ldb     ,x+                     ;  6 t = 5824: byte 365
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5836: byte 364
                stu     <VIA_port_b             ;  5 t = 5840: row 100, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 5852: byte 365
                lda     ,x+                     ;  6 t = 5856: byte 366
                ldb     ,x+                     ;  6 t = 5862: byte 367
                sta     <VIA_shift_reg          ;  4 t = 5868: byte 366
                lda     ,x+                     ;  6 t = 5872: byte 368
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5884: byte 367
                ldb     ,x+                     ;  6 t = 5888: byte 369
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5900: byte 368
                lda     ,x+                     ;  6 t = 5904: byte 370
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5916: byte 369
                sty     <VIA_port_b             ;  6 t = 5920: row 101, X speed -80
                ldb     ,x+                     ;  6 t = 5926: byte 371
                sta     <VIA_shift_reg          ;  4 t = 5932: byte 370
                lda     ,x+                     ;  6 t = 5936: byte 372
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5948: byte 371
                ldb     ,x+                     ;  6 t = 5952: byte 373
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 5964: byte 372
                lda     ,x+                     ;  6 t = 5968: byte 374
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 5980: byte 373
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 5991: row 102, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 5996: byte 374
                ldb     ,x+                     ;  6 t = 6000: byte 375
                lda     ,x+                     ;  6 t = 6006: byte 376
                stb     <VIA_shift_reg          ;  4 t = 6012: byte 375
                ldb     ,x+                     ;  6 t = 6016: byte 377
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 6028: byte 376
                lda     ,x+                     ;  6 t = 6032: byte 378
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 6044: byte 377
                ldb     ,x+                     ;  6 t = 6048: byte 379
                sty     <VIA_port_b             ;  6 t = 6054: row 103, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 6060: byte 378
                lda     ,x+                     ;  6 t = 6064: byte 380
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 6076: byte 379
                ldb     ,x+                     ;  6 t = 6080: byte 381
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 6092: byte 380
                lda     ,x+                     ;  6 t = 6096: byte 382
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 6108: byte 381
                stu     <VIA_port_b             ;  5 t = 6112: row 104, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 6124: byte 382
                ldb     ,x+                     ;  6 t = 6128: byte 383
                lda     ,x+                     ;  6 t = 6134: byte 384
                stb     <VIA_shift_reg          ;  4 t = 6140: byte 383
                ldb     ,x+                     ;  6 t = 6144: byte 385
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 6156: byte 384
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 6162: row 105, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 6172: byte 385
                lda     ,x+                     ;  6 t = 6176: byte 386
                ldb     ,x+                     ;  6 t = 6182: byte 387
                sta     <VIA_shift_reg          ;  4 t = 6188: byte 386
                lda     ,x+                     ;  6 t = 6192: byte 388
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 6204: byte 387
                stu     <VIA_port_b             ;  5 t = 6208: row 106, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 6220: byte 388
                ldb     ,x+                     ;  6 t = 6224: byte 389
                lda     ,x+                     ;  6 t = 6230: byte 390
                stb     <VIA_shift_reg          ;  4 t = 6236: byte 389
                ldb     ,x+                     ;  6 t = 6240: byte 391
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 6252: byte 390
                sty     <VIA_port_b             ;  6 t = 6256: row 107, X speed -80
                lda     ,x+                     ;  6 t = 6262: byte 392
                stb     <VIA_shift_reg          ;  4 t = 6268: byte 391
                ldb     ,x+                     ;  6 t = 6272: byte 393
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 6284: byte 392
                lda     ,x+                     ;  6 t = 6288: byte 394
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 6300: byte 393
                stu     <VIA_port_b             ;  5 t = 6304: row 108, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 6316: byte 394
                ldb     ,x+                     ;  6 t = 6320: byte 395
                lda     ,x+                     ;  6 t = 6326: byte 396
                stb     <VIA_shift_reg          ;  4 t = 6332: byte 395
                ldb     ,x+                     ;  6 t = 6336: byte 397
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 6348: byte 396
                sty     <VIA_port_b             ;  6 t = 6352: row 109, X speed -80
                lda     ,x+                     ;  6 t = 6358: byte 398
                stb     <VIA_shift_reg          ;  4 t = 6364: byte 397
                ldb     ,x+                     ;  6 t = 6368: byte 399
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 6380: byte 398
                lda     ,x+                     ;  6 t = 6384: byte 400
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 6396: byte 399
                stu     <VIA_port_b             ;  5 t = 6400: row 110, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 6412: byte 400
                ldb     ,x+                     ;  6 t = 6416: byte 401
                lda     ,x+                     ;  6 t = 6422: byte 402
                stb     <VIA_shift_reg          ;  4 t = 6428: byte 401
                ldb     ,x+                     ;  6 t = 6432: byte 403
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 6444: byte 402
                sty     <VIA_port_b             ;  6 t = 6448: row 111, X speed -80
                lda     ,x+                     ;  6 t = 6454: byte 404
                stb     <VIA_shift_reg          ;  4 t = 6460: byte 403
                ldb     ,x+                     ;  6 t = 6464: byte 405
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 6476: byte 404
                lda     ,x+                     ;  6 t = 6480: byte 406
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 6492: byte 405
                stu     <VIA_port_b             ;  5 t = 6496: row 112, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 6508: byte 406
                ldb     ,x+                     ;  6 t = 6512: byte 407
                lda     ,x+                     ;  6 t = 6518: byte 408
                stb     <VIA_shift_reg          ;  4 t = 6524: byte 407
                ldb     ,x+                     ;  6 t = 6528: byte 409
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 6540: byte 408
                sty     <VIA_port_b             ;  6 t = 6544: row 113, X speed -80
                lda     ,x+                     ;  6 t = 6550: byte 410
                stb     <VIA_shift_reg          ;  4 t = 6556: byte 409
                ldb     ,x+                     ;  6 t = 6560: byte 411
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 6572: byte 410
                lda     ,x+                     ;  6 t = 6576: byte 412
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 6588: byte 411
                stu     <VIA_port_b             ;  5 t = 6592: row 114, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 6604: byte 412
                ldb     ,x+                     ;  6 t = 6608: byte 413
                lda     ,x+                     ;  6 t = 6614: byte 414
                stb     <VIA_shift_reg          ;  4 t = 6620: byte 413
                ldb     ,x+                     ;  6 t = 6624: byte 415
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 6636: byte 414
                sty     <VIA_port_b             ;  6 t = 6640: row 115, X speed -80
                lda     ,x+                     ;  6 t = 6646: byte 416
                stb     <VIA_shift_reg          ;  4 t = 6652: byte 415
                ldb     ,x+                     ;  6 t = 6656: byte 417
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 6668: byte 416
                lda     ,x+                     ;  6 t = 6672: byte 418
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 6684: byte 417
                stu     <VIA_port_b             ;  5 t = 6688: row 116, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 6700: byte 418
                ldb     ,x+                     ;  6 t = 6704: byte 419
                lda     ,x+                     ;  6 t = 6710: byte 420
                stb     <VIA_shift_reg          ;  4 t = 6716: byte 419
                ldb     ,x+                     ;  6 t = 6720: byte 421
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 6732: byte 420
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 6739: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 6748: byte 421
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 33 x 42: 59 rows (pitch 0.72 pixels), drift 2, 214 bytes: ramp on 3411 cycles
; in: X = the data, the beam at the sprite's top left
zig_scrubbly_2
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
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 87: row 2, X speed +80
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
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                stu     <VIA_port_b             ;  5 t = 272: row 6, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                lda     ,x+                     ;  6 t = 288: byte 18
                ldb     ,x+                     ;  6 t = 294: byte 19
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                lda     ,x+                     ;  6 t = 304: byte 20
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                sty     <VIA_port_b             ;  6 t = 320: row 7, X speed -80
                ldb     ,x+                     ;  6 t = 326: byte 21
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                lda     ,x+                     ;  6 t = 336: byte 22
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                stu     <VIA_port_b             ;  5 t = 368: row 8, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                lda     ,x+                     ;  6 t = 384: byte 24
                ldb     ,x+                     ;  6 t = 390: byte 25
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                lda     ,x+                     ;  6 t = 400: byte 26
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                sty     <VIA_port_b             ;  6 t = 416: row 9, X speed -80
                ldb     ,x+                     ;  6 t = 422: byte 27
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
                stu     <VIA_port_b             ;  5 t = 464: row 10, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                lda     ,x+                     ;  6 t = 480: byte 30
                ldb     ,x+                     ;  6 t = 486: byte 31
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                sty     <VIA_port_b             ;  6 t = 496: row 11, X speed -80
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                stu     <VIA_port_b             ;  5 t = 528: row 12, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                lda     ,x+                     ;  6 t = 544: byte 34
                ldb     ,x+                     ;  6 t = 550: byte 35
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 564: row 13, X speed -80
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                lda     ,x+                     ;  6 t = 576: byte 36
                ldb     ,x+                     ;  6 t = 582: byte 37
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                stu     <VIA_port_b             ;  5 t = 592: row 14, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                lda     ,x+                     ;  6 t = 608: byte 38
                ldb     ,x+                     ;  6 t = 614: byte 39
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                sty     <VIA_port_b             ;  6 t = 624: row 15, X speed -80
                lda     ,x+                     ;  6 t = 630: byte 40
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                ldb     ,x+                     ;  6 t = 640: byte 41
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 658: row 16, X speed +80
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
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 754: row 18, X speed +80
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
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 850: row 20, X speed +80
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
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 900: row 21, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                ldb     ,x+                     ;  6 t = 912: byte 57
                lda     ,x+                     ;  6 t = 918: byte 58
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                ldb     ,x+                     ;  6 t = 928: byte 59
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                lda     ,x+                     ;  6 t = 944: byte 60
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                stu     <VIA_port_b             ;  5 t = 960: row 22, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                ldb     ,x+                     ;  6 t = 976: byte 61
                lda     ,x+                     ;  6 t = 982: byte 62
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                ldb     ,x+                     ;  6 t = 992: byte 63
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                lda     ,x+                     ;  6 t = 1008: byte 64
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                sty     <VIA_port_b             ;  6 t = 1024: row 23, X speed -80
                ldb     ,x+                     ;  6 t = 1030: byte 65
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                lda     ,x+                     ;  6 t = 1040: byte 66
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                ldb     ,x+                     ;  6 t = 1056: byte 67
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                lda     ,x+                     ;  6 t = 1072: byte 68
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                stu     <VIA_port_b             ;  5 t = 1088: row 24, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                ldb     ,x+                     ;  6 t = 1104: byte 69
                lda     ,x+                     ;  6 t = 1110: byte 70
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                ldb     ,x+                     ;  6 t = 1120: byte 71
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                lda     ,x+                     ;  6 t = 1136: byte 72
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                sty     <VIA_port_b             ;  6 t = 1152: row 25, X speed -80
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
                lda     ,x+                     ;  6 t = 1200: byte 76
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                stu     <VIA_port_b             ;  5 t = 1216: row 26, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                ldb     ,x+                     ;  6 t = 1232: byte 77
                lda     ,x+                     ;  6 t = 1238: byte 78
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                ldb     ,x+                     ;  6 t = 1248: byte 79
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                lda     ,x+                     ;  6 t = 1264: byte 80
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                sty     <VIA_port_b             ;  6 t = 1280: row 27, X speed -80
                ldb     ,x+                     ;  6 t = 1286: byte 81
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                lda     ,x+                     ;  6 t = 1296: byte 82
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                ldb     ,x+                     ;  6 t = 1312: byte 83
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                lda     ,x+                     ;  6 t = 1328: byte 84
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                stu     <VIA_port_b             ;  5 t = 1344: row 28, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                ldb     ,x+                     ;  6 t = 1360: byte 85
                lda     ,x+                     ;  6 t = 1366: byte 86
                stb     <VIA_shift_reg          ;  4 t = 1372: byte 85
                ldb     ,x+                     ;  6 t = 1376: byte 87
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1388: byte 86
                lda     ,x+                     ;  6 t = 1392: byte 88
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1404: byte 87
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1410: row 29, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                ldb     ,x+                     ;  6 t = 1424: byte 89
                lda     ,x+                     ;  6 t = 1430: byte 90
                stb     <VIA_shift_reg          ;  4 t = 1436: byte 89
                ldb     ,x+                     ;  6 t = 1440: byte 91
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1452: byte 90
                lda     ,x+                     ;  6 t = 1456: byte 92
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1468: byte 91
                stu     <VIA_port_b             ;  5 t = 1472: row 30, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1484: byte 92
                ldb     ,x+                     ;  6 t = 1488: byte 93
                lda     ,x+                     ;  6 t = 1494: byte 94
                stb     <VIA_shift_reg          ;  4 t = 1500: byte 93
                ldb     ,x+                     ;  6 t = 1504: byte 95
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1516: byte 94
                lda     ,x+                     ;  6 t = 1520: byte 96
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1532: byte 95
                sty     <VIA_port_b             ;  6 t = 1536: row 31, X speed -80
                ldb     ,x+                     ;  6 t = 1542: byte 97
                sta     <VIA_shift_reg          ;  4 t = 1548: byte 96
                lda     ,x+                     ;  6 t = 1552: byte 98
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1564: byte 97
                ldb     ,x+                     ;  6 t = 1568: byte 99
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1580: byte 98
                lda     ,x+                     ;  6 t = 1584: byte 100
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1596: byte 99
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1602: row 32, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1612: byte 100
                ldb     ,x+                     ;  6 t = 1616: byte 101
                lda     ,x+                     ;  6 t = 1622: byte 102
                stb     <VIA_shift_reg          ;  4 t = 1628: byte 101
                ldb     ,x+                     ;  6 t = 1632: byte 103
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1644: byte 102
                lda     ,x+                     ;  6 t = 1648: byte 104
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1660: byte 103
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1668: row 33, X speed -80
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1676: byte 104
                ldb     ,x+                     ;  6 t = 1680: byte 105
                lda     ,x+                     ;  6 t = 1686: byte 106
                stb     <VIA_shift_reg          ;  4 t = 1692: byte 105
                ldb     ,x+                     ;  6 t = 1696: byte 107
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1708: byte 106
                lda     ,x+                     ;  6 t = 1712: byte 108
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1724: byte 107
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 1735: row 34, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 1740: byte 108
                ldb     ,x+                     ;  6 t = 1744: byte 109
                lda     ,x+                     ;  6 t = 1750: byte 110
                stb     <VIA_shift_reg          ;  4 t = 1756: byte 109
                ldb     ,x+                     ;  6 t = 1760: byte 111
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1772: byte 110
                lda     ,x+                     ;  6 t = 1776: byte 112
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1788: byte 111
                ldb     ,x+                     ;  6 t = 1792: byte 113
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1804: byte 112
                sty     <VIA_port_b             ;  6 t = 1808: row 35, X speed -80
                lda     ,x+                     ;  6 t = 1814: byte 114
                stb     <VIA_shift_reg          ;  4 t = 1820: byte 113
                ldb     ,x+                     ;  6 t = 1824: byte 115
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1836: byte 114
                lda     ,x+                     ;  6 t = 1840: byte 116
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                stu     <VIA_port_b             ;  5 t = 1888: row 36, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1900: byte 118
                ldb     ,x+                     ;  6 t = 1904: byte 119
                lda     ,x+                     ;  6 t = 1910: byte 120
                stb     <VIA_shift_reg          ;  4 t = 1916: byte 119
                ldb     ,x+                     ;  6 t = 1920: byte 121
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1932: byte 120
                lda     ,x+                     ;  6 t = 1936: byte 122
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1948: byte 121
                ldb     ,x+                     ;  6 t = 1952: byte 123
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1964: byte 122
                sty     <VIA_port_b             ;  6 t = 1968: row 37, X speed -80
                lda     ,x+                     ;  6 t = 1974: byte 124
                stb     <VIA_shift_reg          ;  4 t = 1980: byte 123
                ldb     ,x+                     ;  6 t = 1984: byte 125
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1996: byte 124
                lda     ,x+                     ;  6 t = 2000: byte 126
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                stu     <VIA_port_b             ;  5 t = 2048: row 38, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2060: byte 128
                ldb     ,x+                     ;  6 t = 2064: byte 129
                lda     ,x+                     ;  6 t = 2070: byte 130
                stb     <VIA_shift_reg          ;  4 t = 2076: byte 129
                ldb     ,x+                     ;  6 t = 2080: byte 131
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2092: byte 130
                lda     ,x+                     ;  6 t = 2096: byte 132
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2108: byte 131
                ldb     ,x+                     ;  6 t = 2112: byte 133
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2124: byte 132
                sty     <VIA_port_b             ;  6 t = 2128: row 39, X speed -80
                lda     ,x+                     ;  6 t = 2134: byte 134
                stb     <VIA_shift_reg          ;  4 t = 2140: byte 133
                ldb     ,x+                     ;  6 t = 2144: byte 135
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2156: byte 134
                lda     ,x+                     ;  6 t = 2160: byte 136
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2172: byte 135
                ldb     ,x+                     ;  6 t = 2176: byte 137
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2188: byte 136
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 2196: row 40, X speed +80
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2204: byte 137
                lda     ,x+                     ;  6 t = 2208: byte 138
                ldb     ,x+                     ;  6 t = 2214: byte 139
                sta     <VIA_shift_reg          ;  4 t = 2220: byte 138
                lda     ,x+                     ;  6 t = 2224: byte 140
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2236: byte 139
                ldb     ,x+                     ;  6 t = 2240: byte 141
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2252: byte 140
                sty     <VIA_port_b             ;  6 t = 2256: row 41, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 2320: row 42, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2332: byte 145
                lda     ,x+                     ;  6 t = 2336: byte 146
                ldb     ,x+                     ;  6 t = 2342: byte 147
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
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 2386: row 43, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2396: byte 149
                lda     ,x+                     ;  6 t = 2400: byte 150
                ldb     ,x+                     ;  6 t = 2406: byte 151
                sta     <VIA_shift_reg          ;  4 t = 2412: byte 150
                lda     ,x+                     ;  6 t = 2416: byte 152
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2428: byte 151
                ldb     ,x+                     ;  6 t = 2432: byte 153
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2444: byte 152
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 2452: row 44, X speed +80
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 2460: byte 153
                lda     ,x+                     ;  6 t = 2464: byte 154
                ldb     ,x+                     ;  6 t = 2470: byte 155
                sta     <VIA_shift_reg          ;  4 t = 2476: byte 154
                lda     ,x+                     ;  6 t = 2480: byte 156
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2492: byte 155
                ldb     ,x+                     ;  6 t = 2496: byte 157
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2508: byte 156
                lda     ,x+                     ;  6 t = 2512: byte 158
                sty     <VIA_port_b             ;  6 t = 2518: row 45, X speed -80
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
                ldb     ,x+                     ;  6 t = 2560: byte 161
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2572: byte 160
                lda     ,x+                     ;  6 t = 2576: byte 162
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2588: byte 161
                stu     <VIA_port_b             ;  5 t = 2592: row 46, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2604: byte 162
                ldb     ,x+                     ;  6 t = 2608: byte 163
                lda     ,x+                     ;  6 t = 2614: byte 164
                stb     <VIA_shift_reg          ;  4 t = 2620: byte 163
                ldb     ,x+                     ;  6 t = 2624: byte 165
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2636: byte 164
                lda     ,x+                     ;  6 t = 2640: byte 166
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2652: byte 165
                ldb     ,x+                     ;  6 t = 2656: byte 167
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2668: byte 166
                sty     <VIA_port_b             ;  6 t = 2672: row 47, X speed -80
                lda     ,x+                     ;  6 t = 2678: byte 168
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
                ldb     ,x+                     ;  6 t = 2720: byte 171
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2732: byte 170
                lda     ,x+                     ;  6 t = 2736: byte 172
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2748: byte 171
                stu     <VIA_port_b             ;  5 t = 2752: row 48, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2764: byte 172
                ldb     ,x+                     ;  6 t = 2768: byte 173
                lda     ,x+                     ;  6 t = 2774: byte 174
                stb     <VIA_shift_reg          ;  4 t = 2780: byte 173
                ldb     ,x+                     ;  6 t = 2784: byte 175
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2796: byte 174
                lda     ,x+                     ;  6 t = 2800: byte 176
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2812: byte 175
                ldb     ,x+                     ;  6 t = 2816: byte 177
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2828: byte 176
                sty     <VIA_port_b             ;  6 t = 2832: row 49, X speed -80
                lda     ,x+                     ;  6 t = 2838: byte 178
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
                ldb     ,x+                     ;  6 t = 2880: byte 181
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2892: byte 180
                lda     ,x+                     ;  6 t = 2896: byte 182
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2908: byte 181
                stu     <VIA_port_b             ;  5 t = 2912: row 50, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2924: byte 182
                ldb     ,x+                     ;  6 t = 2928: byte 183
                lda     ,x+                     ;  6 t = 2934: byte 184
                stb     <VIA_shift_reg          ;  4 t = 2940: byte 183
                ldb     ,x+                     ;  6 t = 2944: byte 185
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2956: byte 184
                lda     ,x+                     ;  6 t = 2960: byte 186
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2972: byte 185
                ldb     ,x+                     ;  6 t = 2976: byte 187
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2988: byte 186
                sty     <VIA_port_b             ;  6 t = 2992: row 51, X speed -80
                lda     ,x+                     ;  6 t = 2998: byte 188
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
                ldb     ,x+                     ;  6 t = 3040: byte 191
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3052: byte 190
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 3063: row 52, X speed +80
                stb     <VIA_shift_reg          ;  4 t = 3068: byte 191
                lda     ,x+                     ;  6 t = 3072: byte 192
                ldb     ,x+                     ;  6 t = 3078: byte 193
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
                sty     <VIA_port_b             ;  6 t = 3120: row 53, X speed -80
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
                stu     <VIA_port_b             ;  5 t = 3168: row 54, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 3180: byte 198
                ldb     ,x+                     ;  6 t = 3184: byte 199
                lda     ,x+                     ;  6 t = 3190: byte 200
                stb     <VIA_shift_reg          ;  4 t = 3196: byte 199
                ldb     ,x+                     ;  6 t = 3200: byte 201
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3212: byte 200
                sty     <VIA_port_b             ;  6 t = 3216: row 55, X speed -80
                lda     ,x+                     ;  6 t = 3222: byte 202
                stb     <VIA_shift_reg          ;  4 t = 3228: byte 201
                ldb     ,x+                     ;  6 t = 3232: byte 203
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3244: byte 202
                lda     ,x+                     ;  6 t = 3248: byte 204
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3260: byte 203
                stu     <VIA_port_b             ;  5 t = 3264: row 56, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 3276: byte 204
                ldb     ,x+                     ;  6 t = 3280: byte 205
                lda     ,x+                     ;  6 t = 3286: byte 206
                stb     <VIA_shift_reg          ;  4 t = 3292: byte 205
                ldb     ,x+                     ;  6 t = 3296: byte 207
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3308: byte 206
                sty     <VIA_port_b             ;  6 t = 3312: row 57, X speed -80
                lda     ,x+                     ;  6 t = 3318: byte 208
                stb     <VIA_shift_reg          ;  4 t = 3324: byte 207
                ldb     ,x+                     ;  6 t = 3328: byte 209
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3340: byte 208
                lda     ,x+                     ;  6 t = 3344: byte 210
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3356: byte 209
                stu     <VIA_port_b             ;  5 t = 3360: row 58, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 3372: byte 210
                ldb     ,x+                     ;  6 t = 3376: byte 211
                lda     ,x+                     ;  6 t = 3382: byte 212
                stb     <VIA_shift_reg          ;  4 t = 3388: byte 211
                ldb     ,x+                     ;  6 t = 3392: byte 213
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3404: byte 212
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 3411: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3420: byte 213
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 11 x 9: 18 rows (pitch 0.52 pixels), drift 3, 32 bytes: ramp on 499 cycles
; in: X = the data, the beam at the sprite's top left
zig_gem_3
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
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 19: row 1, X speed -80
                brn     *                       ;  3 
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
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 103: row 4, X speed +80
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
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 279: row 10, X speed +80
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                lda     ,x+                     ;  6 t = 288: byte 18
                ldb     ,x+                     ;  6 t = 294: byte 19
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                sty     <VIA_port_b             ;  6 t = 304: row 11, X speed -80
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 327: row 12, X speed +80
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                ldb     ,x+                     ;  6 t = 336: byte 21
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                sty     <VIA_port_b             ;  6 t = 352: row 13, X speed -80
                ldb     ,x+                     ;  6 t = 358: byte 23
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 386: row 14, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 419: row 15, X speed -80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                ldb     ,x+                     ;  6 t = 432: byte 27
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 450: row 16, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                ldb     ,x+                     ;  6 t = 464: byte 29
                lda     ,x+                     ;  6 t = 470: byte 30
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                sty     <VIA_port_b             ;  6 t = 480: row 17, X speed -80
                ldb     ,x+                     ;  6 t = 486: byte 31
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 499: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 11 x 9: 10 rows (pitch 0.91 pixels), drift 5, 19 bytes: ramp on 293 cycles
; in: X = the data, the beam at the sprite's top left
zig_gem_5
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
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 210: row 7, X speed -80
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                lda     ,x+                     ;  6 t = 224: byte 14
                ldb     ,x+                     ;  6 t = 230: byte 15
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                stu     <VIA_port_b             ;  5 t = 240: row 8, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                lda     ,x+                     ;  6 t = 256: byte 16
                ldb     ,x+                     ;  6 t = 262: byte 17
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                sty     <VIA_port_b             ;  6 t = 272: row 9, X speed -80
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                nop                             ;  2 
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 293: ramp off
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 10 x 15: 30 rows (pitch 0.50 pixels), drift 3, 51 bytes: ramp on 807 cycles
; in: X = the data, the beam at the sprite's top left
zig_bulb_3
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
                stu     <VIA_port_b             ;  5 t = 178: row 8, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                lda     ,x+                     ;  6 t = 192: byte 12
                sty     <VIA_port_b             ;  6 t = 198: row 9, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                ldb     ,x+                     ;  6 t = 208: byte 13
                lda     ,x+                     ;  6 t = 214: byte 14
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                stu     <VIA_port_b             ;  5 t = 224: row 10, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                ldb     ,x+                     ;  6 t = 240: byte 15
                sty     <VIA_port_b             ;  6 t = 246: row 11, X speed -80
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                lda     ,x+                     ;  6 t = 256: byte 16
                ldb     ,x+                     ;  6 t = 262: byte 17
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                stu     <VIA_port_b             ;  5 t = 272: row 12, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                lda     ,x+                     ;  6 t = 288: byte 18
                sty     <VIA_port_b             ;  6 t = 294: row 13, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                stu     <VIA_port_b             ;  5 t = 320: row 14, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                ldb     ,x+                     ;  6 t = 336: byte 21
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                sty     <VIA_port_b             ;  6 t = 352: row 15, X speed -80
                ldb     ,x+                     ;  6 t = 358: byte 23
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 375: row 16, X speed +80
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                lda     ,x+                     ;  6 t = 384: byte 24
                ldb     ,x+                     ;  6 t = 390: byte 25
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                sty     <VIA_port_b             ;  6 t = 400: row 17, X speed -80
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                stu     <VIA_port_b             ;  5 t = 432: row 18, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                lda     ,x+                     ;  6 t = 448: byte 28
                ldb     ,x+                     ;  6 t = 454: byte 29
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                sty     <VIA_port_b             ;  6 t = 464: row 19, X speed -80
                lda     ,x+                     ;  6 t = 470: byte 30
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                ldb     ,x+                     ;  6 t = 480: byte 31
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                stu     <VIA_port_b             ;  5 t = 496: row 20, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                lda     ,x+                     ;  6 t = 512: byte 32
                ldb     ,x+                     ;  6 t = 518: byte 33
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                sty     <VIA_port_b             ;  6 t = 528: row 21, X speed -80
                lda     ,x+                     ;  6 t = 534: byte 34
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                stu     <VIA_port_b             ;  5 t = 560: row 22, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                lda     ,x+                     ;  6 t = 576: byte 36
                ldb     ,x+                     ;  6 t = 582: byte 37
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                sty     <VIA_port_b             ;  6 t = 592: row 23, X speed -80
                lda     ,x+                     ;  6 t = 598: byte 38
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                stu     <VIA_port_b             ;  5 t = 624: row 24, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                lda     ,x+                     ;  6 t = 640: byte 40
                ldb     ,x+                     ;  6 t = 646: byte 41
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                sty     <VIA_port_b             ;  6 t = 656: row 25, X speed -80
                lda     ,x+                     ;  6 t = 662: byte 42
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                ldb     ,x+                     ;  6 t = 672: byte 43
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                stu     <VIA_port_b             ;  5 t = 688: row 26, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                lda     ,x+                     ;  6 t = 704: byte 44
                ldb     ,x+                     ;  6 t = 710: byte 45
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                sty     <VIA_port_b             ;  6 t = 720: row 27, X speed -80
                lda     ,x+                     ;  6 t = 726: byte 46
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                ldb     ,x+                     ;  6 t = 736: byte 47
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                stu     <VIA_port_b             ;  5 t = 752: row 28, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                lda     ,x+                     ;  6 t = 768: byte 48
                ldb     ,x+                     ;  6 t = 774: byte 49
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                sty     <VIA_port_b             ;  6 t = 784: row 29, X speed -80
                lda     ,x+                     ;  6 t = 790: byte 50
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                nop                             ;  2 
                nop                             ;  2 
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 807: ramp off
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 10 x 15: 16 rows (pitch 0.95 pixels), drift 6, 26 bytes: ramp on 407 cycles
; in: X = the data, the beam at the sprite's top left
zig_bulb_6
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
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 82: row 4, X speed +80
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 t = 96: byte 6
                ldb     ,x+                     ;  6 t = 102: byte 7
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                sty     <VIA_port_b             ;  6 t = 112: row 5, X speed -80
                lda     ,x+                     ;  6 t = 118: byte 8
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                nop                             ;  2 
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 132: row 6, X speed +80
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                ldb     ,x+                     ;  6 t = 144: byte 9
                sty     <VIA_port_b             ;  6 t = 150: row 7, X speed -80
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                lda     ,x+                     ;  6 t = 160: byte 10
                ldb     ,x+                     ;  6 t = 166: byte 11
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                stu     <VIA_port_b             ;  5 t = 176: row 8, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                lda     ,x+                     ;  6 t = 192: byte 12
                sty     <VIA_port_b             ;  6 t = 198: row 9, X speed -80
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                ldb     ,x+                     ;  6 t = 208: byte 13
                lda     ,x+                     ;  6 t = 214: byte 14
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                stu     <VIA_port_b             ;  5 t = 224: row 10, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                ldb     ,x+                     ;  6 t = 240: byte 15
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                sty     <VIA_port_b             ;  6 t = 256: row 11, X speed -80
                ldb     ,x+                     ;  6 t = 262: byte 17
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                stu     <VIA_port_b             ;  5 t = 288: row 12, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                sty     <VIA_port_b             ;  6 t = 320: row 13, X speed -80
                ldb     ,x+                     ;  6 t = 326: byte 21
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                lda     ,x+                     ;  6 t = 336: byte 22
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                stu     <VIA_port_b             ;  5 t = 352: row 14, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                ldb     ,x+                     ;  6 t = 368: byte 23
                lda     ,x+                     ;  6 t = 374: byte 24
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                sty     <VIA_port_b             ;  6 t = 384: row 15, X speed -80
                ldb     ,x+                     ;  6 t = 390: byte 25
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                nop                             ;  2 
                nop                             ;  2 
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 407: ramp off
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

