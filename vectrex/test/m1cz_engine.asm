; made by vectrex/tools/m1_cavez_gen.py

; 8 rows ([0, 1, 4, 5, 7, 9, 11, 13] of the ledge) of any length: 128 x bytes + turns
cave_n
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
                ldy     #$8000                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed 0
                ldy     #$8150                  ;  4 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed 80
                ldx     ,u++                    ;  8 row 0's bytes
                ldb     $C880                   ;  5 
                decb                            ;  2 (bytes - 1 in the loop)
                ldy     #$8100                  ;  4 (for the ramp off)
                lda     #$01                    ;  2 
                sta     <VIA_port_b             ;  4 t = 0: ramp on
                nop                             ;  2 
cave_n_0
                lda     ,x+                     ;  6 t = 6 + 16i
                sta     >$D000+VIA_shift_reg    ;  5 t = 12 + 16i
                decb                            ;  2 
                bne     cave_n_0                ;  3 
                lda     ,x+                     ;  6 t = 16n - 10: the last byte
                sta     <VIA_shift_reg          ;  4 t = 16n - 4
                sty     <VIA_port_b             ;  6 t = 16n: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 16n + 12: spot off
                ldy     #$80D8                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -40 (a step of 1)
                ldy     #$8100                  ;  4 (the sample-and-hold settles)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed 0
                lda     #$01                    ;  2 
                ldb     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp on...
                stb     <VIA_port_b             ;  4 ...for 4 cycles: 1 pixel(s) down
                ldy     #$8000                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed 0
                ldy     #$81B0                  ;  4 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed -80
                ldx     ,u++                    ;  8 row 1's bytes
                ldb     $C880                   ;  5 
                decb                            ;  2 (bytes - 1 in the loop)
                ldy     #$8100                  ;  4 (for the ramp off)
                lda     #$01                    ;  2 
                sta     <VIA_port_b             ;  4 t = 0: ramp on
                nop                             ;  2 
cave_n_1
                lda     ,x+                     ;  6 t = 6 + 16i
                sta     >$D000+VIA_shift_reg    ;  5 t = 12 + 16i
                decb                            ;  2 
                bne     cave_n_1                ;  3 
                lda     ,x+                     ;  6 t = 16n - 10: the last byte
                sta     <VIA_shift_reg          ;  4 t = 16n - 4
                sty     <VIA_port_b             ;  6 t = 16n: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 16n + 12: spot off
                ldy     #$8088                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -120 (a step of 3)
                ldy     #$8100                  ;  4 (the sample-and-hold settles)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed 0
                lda     #$01                    ;  2 
                ldb     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp on...
                stb     <VIA_port_b             ;  4 ...for 4 cycles: 3 pixel(s) down
                ldy     #$8000                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed 0
                ldy     #$8150                  ;  4 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed 80
                ldx     ,u++                    ;  8 row 4's bytes
                ldb     $C880                   ;  5 
                decb                            ;  2 (bytes - 1 in the loop)
                ldy     #$8100                  ;  4 (for the ramp off)
                lda     #$01                    ;  2 
                sta     <VIA_port_b             ;  4 t = 0: ramp on
                nop                             ;  2 
cave_n_2
                lda     ,x+                     ;  6 t = 6 + 16i
                sta     >$D000+VIA_shift_reg    ;  5 t = 12 + 16i
                decb                            ;  2 
                bne     cave_n_2                ;  3 
                lda     ,x+                     ;  6 t = 16n - 10: the last byte
                sta     <VIA_shift_reg          ;  4 t = 16n - 4
                sty     <VIA_port_b             ;  6 t = 16n: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 16n + 12: spot off
                ldy     #$80D8                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -40 (a step of 1)
                ldy     #$8100                  ;  4 (the sample-and-hold settles)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed 0
                lda     #$01                    ;  2 
                ldb     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp on...
                stb     <VIA_port_b             ;  4 ...for 4 cycles: 1 pixel(s) down
                ldy     #$8000                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed 0
                ldy     #$81B0                  ;  4 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed -80
                ldx     ,u++                    ;  8 row 5's bytes
                ldb     $C880                   ;  5 
                decb                            ;  2 (bytes - 1 in the loop)
                ldy     #$8100                  ;  4 (for the ramp off)
                lda     #$01                    ;  2 
                sta     <VIA_port_b             ;  4 t = 0: ramp on
                nop                             ;  2 
cave_n_3
                lda     ,x+                     ;  6 t = 6 + 16i
                sta     >$D000+VIA_shift_reg    ;  5 t = 12 + 16i
                decb                            ;  2 
                bne     cave_n_3                ;  3 
                lda     ,x+                     ;  6 t = 16n - 10: the last byte
                sta     <VIA_shift_reg          ;  4 t = 16n - 4
                sty     <VIA_port_b             ;  6 t = 16n: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 16n + 12: spot off
                ldy     #$80B0                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -80 (a step of 2)
                ldy     #$8100                  ;  4 (the sample-and-hold settles)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed 0
                lda     #$01                    ;  2 
                ldb     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp on...
                stb     <VIA_port_b             ;  4 ...for 4 cycles: 2 pixel(s) down
                ldy     #$8000                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed 0
                ldy     #$8150                  ;  4 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed 80
                ldx     ,u++                    ;  8 row 7's bytes
                ldb     $C880                   ;  5 
                decb                            ;  2 (bytes - 1 in the loop)
                ldy     #$8100                  ;  4 (for the ramp off)
                lda     #$01                    ;  2 
                sta     <VIA_port_b             ;  4 t = 0: ramp on
                nop                             ;  2 
cave_n_4
                lda     ,x+                     ;  6 t = 6 + 16i
                sta     >$D000+VIA_shift_reg    ;  5 t = 12 + 16i
                decb                            ;  2 
                bne     cave_n_4                ;  3 
                lda     ,x+                     ;  6 t = 16n - 10: the last byte
                sta     <VIA_shift_reg          ;  4 t = 16n - 4
                sty     <VIA_port_b             ;  6 t = 16n: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 16n + 12: spot off
                ldy     #$80B0                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -80 (a step of 2)
                ldy     #$8100                  ;  4 (the sample-and-hold settles)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed 0
                lda     #$01                    ;  2 
                ldb     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp on...
                stb     <VIA_port_b             ;  4 ...for 4 cycles: 2 pixel(s) down
                ldy     #$8000                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed 0
                ldy     #$81B0                  ;  4 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed -80
                ldx     ,u++                    ;  8 row 9's bytes
                ldb     $C880                   ;  5 
                decb                            ;  2 (bytes - 1 in the loop)
                ldy     #$8100                  ;  4 (for the ramp off)
                lda     #$01                    ;  2 
                sta     <VIA_port_b             ;  4 t = 0: ramp on
                nop                             ;  2 
cave_n_5
                lda     ,x+                     ;  6 t = 6 + 16i
                sta     >$D000+VIA_shift_reg    ;  5 t = 12 + 16i
                decb                            ;  2 
                bne     cave_n_5                ;  3 
                lda     ,x+                     ;  6 t = 16n - 10: the last byte
                sta     <VIA_shift_reg          ;  4 t = 16n - 4
                sty     <VIA_port_b             ;  6 t = 16n: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 16n + 12: spot off
                ldy     #$80B0                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -80 (a step of 2)
                ldy     #$8100                  ;  4 (the sample-and-hold settles)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed 0
                lda     #$01                    ;  2 
                ldb     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp on...
                stb     <VIA_port_b             ;  4 ...for 4 cycles: 2 pixel(s) down
                ldy     #$8000                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed 0
                ldy     #$8150                  ;  4 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed 80
                ldx     ,u++                    ;  8 row 11's bytes
                ldb     $C880                   ;  5 
                decb                            ;  2 (bytes - 1 in the loop)
                ldy     #$8100                  ;  4 (for the ramp off)
                lda     #$01                    ;  2 
                sta     <VIA_port_b             ;  4 t = 0: ramp on
                nop                             ;  2 
cave_n_6
                lda     ,x+                     ;  6 t = 6 + 16i
                sta     >$D000+VIA_shift_reg    ;  5 t = 12 + 16i
                decb                            ;  2 
                bne     cave_n_6                ;  3 
                lda     ,x+                     ;  6 t = 16n - 10: the last byte
                sta     <VIA_shift_reg          ;  4 t = 16n - 4
                sty     <VIA_port_b             ;  6 t = 16n: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 16n + 12: spot off
                ldy     #$80B0                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -80 (a step of 2)
                ldy     #$8100                  ;  4 (the sample-and-hold settles)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed 0
                lda     #$01                    ;  2 
                ldb     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp on...
                stb     <VIA_port_b             ;  4 ...for 4 cycles: 2 pixel(s) down
                ldy     #$8000                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed 0
                ldy     #$81B0                  ;  4 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed -80
                ldx     ,u++                    ;  8 row 13's bytes
                ldb     $C880                   ;  5 
                decb                            ;  2 (bytes - 1 in the loop)
                ldy     #$8100                  ;  4 (for the ramp off)
                lda     #$01                    ;  2 
                sta     <VIA_port_b             ;  4 t = 0: ramp on
                nop                             ;  2 
cave_n_7
                lda     ,x+                     ;  6 t = 6 + 16i
                sta     >$D000+VIA_shift_reg    ;  5 t = 12 + 16i
                decb                            ;  2 
                bne     cave_n_7                ;  3 
                lda     ,x+                     ;  6 t = 16n - 10: the last byte
                sta     <VIA_shift_reg          ;  4 t = 16n - 4
                sty     <VIA_port_b             ;  6 t = 16n: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 16n + 12: spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag band 64 x 14, drift 2, 9 rows: ramp on 1155 cycles
band_3_0
                ldx     #band_3_0_d             ;  3 
                ldy     #$80FE                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -2
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
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
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                sty     <VIA_port_b             ;  6 t = 128: row 1
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
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                stu     <VIA_port_b             ;  5 t = 256: row 2
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
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                sty     <VIA_port_b             ;  6 t = 384: row 3
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
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                stu     <VIA_port_b             ;  5 t = 512: row 4
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
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                sty     <VIA_port_b             ;  6 t = 640: row 5
                ldb     ,x+                     ;  6 t = 646: byte 41
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                lda     ,x+                     ;  6 t = 656: byte 42
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                stu     <VIA_port_b             ;  5 t = 768: row 6
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
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                sty     <VIA_port_b             ;  6 t = 896: row 7
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
                stu     <VIA_port_b             ;  5 t = 1024: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                ldb     ,x+                     ;  6 t = 1040: byte 65
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
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 1155: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                clr     <VIA_shift_reg          ;  6 spot off
                rts                             ;  5 

; a zigzag band 64 x 14, drift 2, 9 rows: ramp on 1155 cycles
band_4_0
                ldx     #band_4_0_d             ;  3 
                ldy     #$80FE                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -2
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
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
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                sty     <VIA_port_b             ;  6 t = 128: row 1
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
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                stu     <VIA_port_b             ;  5 t = 256: row 2
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
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                sty     <VIA_port_b             ;  6 t = 384: row 3
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
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                stu     <VIA_port_b             ;  5 t = 512: row 4
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
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                sty     <VIA_port_b             ;  6 t = 640: row 5
                ldb     ,x+                     ;  6 t = 646: byte 41
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                lda     ,x+                     ;  6 t = 656: byte 42
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                stu     <VIA_port_b             ;  5 t = 768: row 6
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
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                sty     <VIA_port_b             ;  6 t = 896: row 7
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
                stu     <VIA_port_b             ;  5 t = 1024: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                ldb     ,x+                     ;  6 t = 1040: byte 65
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
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 1155: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                clr     <VIA_shift_reg          ;  6 spot off
                rts                             ;  5 

; a zigzag band 64 x 14, drift -2, 11 rows: ramp on 1411 cycles
band_4_1
                ldx     #band_4_1_d             ;  3 
                ldy     #$8002                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed 2
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
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
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                sty     <VIA_port_b             ;  6 t = 128: row 1
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
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                stu     <VIA_port_b             ;  5 t = 256: row 2
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
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                sty     <VIA_port_b             ;  6 t = 384: row 3
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
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                stu     <VIA_port_b             ;  5 t = 512: row 4
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
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                sty     <VIA_port_b             ;  6 t = 640: row 5
                ldb     ,x+                     ;  6 t = 646: byte 41
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                lda     ,x+                     ;  6 t = 656: byte 42
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                stu     <VIA_port_b             ;  5 t = 768: row 6
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
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                sty     <VIA_port_b             ;  6 t = 896: row 7
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
                stu     <VIA_port_b             ;  5 t = 1024: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                ldb     ,x+                     ;  6 t = 1040: byte 65
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
                sty     <VIA_port_b             ;  6 t = 1152: row 9
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
                stu     <VIA_port_b             ;  5 t = 1280: row 10
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
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 1411: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                clr     <VIA_shift_reg          ;  6 spot off
                rts                             ;  5 

; a zigzag band 64 x 14, drift 2, 9 rows: ramp on 1155 cycles
band_5_0
                ldx     #band_5_0_d             ;  3 
                ldy     #$80FE                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -2
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
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
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                sty     <VIA_port_b             ;  6 t = 128: row 1
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
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                stu     <VIA_port_b             ;  5 t = 256: row 2
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
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                sty     <VIA_port_b             ;  6 t = 384: row 3
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
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                stu     <VIA_port_b             ;  5 t = 512: row 4
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
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                sty     <VIA_port_b             ;  6 t = 640: row 5
                ldb     ,x+                     ;  6 t = 646: byte 41
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                lda     ,x+                     ;  6 t = 656: byte 42
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                stu     <VIA_port_b             ;  5 t = 768: row 6
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
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                sty     <VIA_port_b             ;  6 t = 896: row 7
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
                stu     <VIA_port_b             ;  5 t = 1024: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                ldb     ,x+                     ;  6 t = 1040: byte 65
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
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 1155: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                clr     <VIA_shift_reg          ;  6 spot off
                rts                             ;  5 

; a zigzag band 64 x 14, drift -2, 11 rows: ramp on 1411 cycles
band_5_1
                ldx     #band_5_1_d             ;  3 
                ldy     #$8002                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed 2
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
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
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                sty     <VIA_port_b             ;  6 t = 128: row 1
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
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                stu     <VIA_port_b             ;  5 t = 256: row 2
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
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                sty     <VIA_port_b             ;  6 t = 384: row 3
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
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                stu     <VIA_port_b             ;  5 t = 512: row 4
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
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                sty     <VIA_port_b             ;  6 t = 640: row 5
                ldb     ,x+                     ;  6 t = 646: byte 41
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                lda     ,x+                     ;  6 t = 656: byte 42
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                stu     <VIA_port_b             ;  5 t = 768: row 6
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
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                sty     <VIA_port_b             ;  6 t = 896: row 7
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
                stu     <VIA_port_b             ;  5 t = 1024: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                ldb     ,x+                     ;  6 t = 1040: byte 65
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
                sty     <VIA_port_b             ;  6 t = 1152: row 9
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
                stu     <VIA_port_b             ;  5 t = 1280: row 10
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
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 1411: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                clr     <VIA_shift_reg          ;  6 spot off
                rts                             ;  5 

; a zigzag band 64 x 14, drift 2, 11 rows: ramp on 1411 cycles
band_5_2
                ldx     #band_5_2_d             ;  3 
                ldy     #$80FE                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -2
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
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
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                sty     <VIA_port_b             ;  6 t = 128: row 1
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
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                stu     <VIA_port_b             ;  5 t = 256: row 2
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
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                sty     <VIA_port_b             ;  6 t = 384: row 3
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
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                stu     <VIA_port_b             ;  5 t = 512: row 4
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
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                sty     <VIA_port_b             ;  6 t = 640: row 5
                ldb     ,x+                     ;  6 t = 646: byte 41
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                lda     ,x+                     ;  6 t = 656: byte 42
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                stu     <VIA_port_b             ;  5 t = 768: row 6
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
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                sty     <VIA_port_b             ;  6 t = 896: row 7
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
                stu     <VIA_port_b             ;  5 t = 1024: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                ldb     ,x+                     ;  6 t = 1040: byte 65
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
                sty     <VIA_port_b             ;  6 t = 1152: row 9
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
                stu     <VIA_port_b             ;  5 t = 1280: row 10
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
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 1411: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                clr     <VIA_shift_reg          ;  6 spot off
                rts                             ;  5 

; a zigzag band 16 x 14, drift -8, 11 rows: ramp on 355 cycles
band_5_3
                ldx     #band_5_3_d             ;  3 
                ldy     #$8008                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed 8
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
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
                sty     <VIA_port_b             ;  6 t = 32: row 1
                ldb     ,x+                     ;  6 t = 38: byte 3
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                stu     <VIA_port_b             ;  5 t = 64: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                ldb     ,x+                     ;  6 t = 80: byte 5
                lda     ,x+                     ;  6 t = 86: byte 6
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                sty     <VIA_port_b             ;  6 t = 96: row 3
                ldb     ,x+                     ;  6 t = 102: byte 7
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                stu     <VIA_port_b             ;  5 t = 128: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                ldb     ,x+                     ;  6 t = 144: byte 9
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                sty     <VIA_port_b             ;  6 t = 160: row 5
                ldb     ,x+                     ;  6 t = 166: byte 11
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                stu     <VIA_port_b             ;  5 t = 192: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                ldb     ,x+                     ;  6 t = 208: byte 13
                lda     ,x+                     ;  6 t = 214: byte 14
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                sty     <VIA_port_b             ;  6 t = 224: row 7
                ldb     ,x+                     ;  6 t = 230: byte 15
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                stu     <VIA_port_b             ;  5 t = 256: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                ldb     ,x+                     ;  6 t = 272: byte 17
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                sty     <VIA_port_b             ;  6 t = 288: row 9
                ldb     ,x+                     ;  6 t = 294: byte 19
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                lda     ,x+                     ;  6 t = 304: byte 20
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                stu     <VIA_port_b             ;  5 t = 320: row 10
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                ldb     ,x+                     ;  6 t = 336: byte 21
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 355: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                clr     <VIA_shift_reg          ;  6 spot off
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

; a zigzag sprite, 16 x 70: 71 rows (pitch 1.00 pixels), drift 5, 143 bytes: ramp on 2275 cycles
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
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                sty     <VIA_port_b             ;  6 t = 32: row 1, X speed -80
                ldb     ,x+                     ;  6 t = 38: byte 3
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                stu     <VIA_port_b             ;  5 t = 64: row 2, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
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
                sty     <VIA_port_b             ;  6 t = 224: row 7, X speed -80
                ldb     ,x+                     ;  6 t = 230: byte 15
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                stu     <VIA_port_b             ;  5 t = 256: row 8, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                ldb     ,x+                     ;  6 t = 272: byte 17
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                sty     <VIA_port_b             ;  6 t = 288: row 9, X speed -80
                ldb     ,x+                     ;  6 t = 294: byte 19
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                lda     ,x+                     ;  6 t = 304: byte 20
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                stu     <VIA_port_b             ;  5 t = 320: row 10, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                ldb     ,x+                     ;  6 t = 336: byte 21
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                sty     <VIA_port_b             ;  6 t = 352: row 11, X speed -80
                ldb     ,x+                     ;  6 t = 358: byte 23
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                stu     <VIA_port_b             ;  5 t = 384: row 12, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                sty     <VIA_port_b             ;  6 t = 416: row 13, X speed -80
                ldb     ,x+                     ;  6 t = 422: byte 27
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                lda     ,x+                     ;  6 t = 432: byte 28
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                stu     <VIA_port_b             ;  5 t = 448: row 14, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                ldb     ,x+                     ;  6 t = 464: byte 29
                lda     ,x+                     ;  6 t = 470: byte 30
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                sty     <VIA_port_b             ;  6 t = 480: row 15, X speed -80
                ldb     ,x+                     ;  6 t = 486: byte 31
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                stu     <VIA_port_b             ;  5 t = 512: row 16, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                ldb     ,x+                     ;  6 t = 528: byte 33
                lda     ,x+                     ;  6 t = 534: byte 34
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                sty     <VIA_port_b             ;  6 t = 544: row 17, X speed -80
                ldb     ,x+                     ;  6 t = 550: byte 35
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                lda     ,x+                     ;  6 t = 560: byte 36
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                stu     <VIA_port_b             ;  5 t = 576: row 18, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                ldb     ,x+                     ;  6 t = 592: byte 37
                lda     ,x+                     ;  6 t = 598: byte 38
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                sty     <VIA_port_b             ;  6 t = 608: row 19, X speed -80
                ldb     ,x+                     ;  6 t = 614: byte 39
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                stu     <VIA_port_b             ;  5 t = 640: row 20, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                ldb     ,x+                     ;  6 t = 656: byte 41
                lda     ,x+                     ;  6 t = 662: byte 42
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                sty     <VIA_port_b             ;  6 t = 672: row 21, X speed -80
                ldb     ,x+                     ;  6 t = 678: byte 43
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
                sty     <VIA_port_b             ;  6 t = 736: row 23, X speed -80
                ldb     ,x+                     ;  6 t = 742: byte 47
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                lda     ,x+                     ;  6 t = 752: byte 48
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                stu     <VIA_port_b             ;  5 t = 768: row 24, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                ldb     ,x+                     ;  6 t = 784: byte 49
                lda     ,x+                     ;  6 t = 790: byte 50
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                sty     <VIA_port_b             ;  6 t = 800: row 25, X speed -80
                ldb     ,x+                     ;  6 t = 806: byte 51
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                lda     ,x+                     ;  6 t = 816: byte 52
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                stu     <VIA_port_b             ;  5 t = 832: row 26, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                ldb     ,x+                     ;  6 t = 848: byte 53
                lda     ,x+                     ;  6 t = 854: byte 54
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                sty     <VIA_port_b             ;  6 t = 864: row 27, X speed -80
                ldb     ,x+                     ;  6 t = 870: byte 55
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                lda     ,x+                     ;  6 t = 880: byte 56
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                stu     <VIA_port_b             ;  5 t = 896: row 28, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                ldb     ,x+                     ;  6 t = 912: byte 57
                lda     ,x+                     ;  6 t = 918: byte 58
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                sty     <VIA_port_b             ;  6 t = 928: row 29, X speed -80
                ldb     ,x+                     ;  6 t = 934: byte 59
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                lda     ,x+                     ;  6 t = 944: byte 60
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                stu     <VIA_port_b             ;  5 t = 960: row 30, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                ldb     ,x+                     ;  6 t = 976: byte 61
                lda     ,x+                     ;  6 t = 982: byte 62
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                sty     <VIA_port_b             ;  6 t = 992: row 31, X speed -80
                ldb     ,x+                     ;  6 t = 998: byte 63
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                lda     ,x+                     ;  6 t = 1008: byte 64
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                stu     <VIA_port_b             ;  5 t = 1024: row 32, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                ldb     ,x+                     ;  6 t = 1040: byte 65
                lda     ,x+                     ;  6 t = 1046: byte 66
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                sty     <VIA_port_b             ;  6 t = 1056: row 33, X speed -80
                ldb     ,x+                     ;  6 t = 1062: byte 67
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                lda     ,x+                     ;  6 t = 1072: byte 68
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                stu     <VIA_port_b             ;  5 t = 1088: row 34, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                ldb     ,x+                     ;  6 t = 1104: byte 69
                lda     ,x+                     ;  6 t = 1110: byte 70
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                sty     <VIA_port_b             ;  6 t = 1120: row 35, X speed -80
                ldb     ,x+                     ;  6 t = 1126: byte 71
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
                sty     <VIA_port_b             ;  6 t = 1184: row 37, X speed -80
                ldb     ,x+                     ;  6 t = 1190: byte 75
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                lda     ,x+                     ;  6 t = 1200: byte 76
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                stu     <VIA_port_b             ;  5 t = 1216: row 38, X speed +80
                nop                             ;  2 
                nop                             ;  2 
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
                sty     <VIA_port_b             ;  6 t = 1568: row 49, X speed -80
                ldb     ,x+                     ;  6 t = 1574: byte 99
                sta     <VIA_shift_reg          ;  4 t = 1580: byte 98
                lda     ,x+                     ;  6 t = 1584: byte 100
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                sty     <VIA_port_b             ;  6 t = 1760: row 55, X speed -80
                ldb     ,x+                     ;  6 t = 1766: byte 111
                sta     <VIA_shift_reg          ;  4 t = 1772: byte 110
                lda     ,x+                     ;  6 t = 1776: byte 112
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
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
                sty     <VIA_port_b             ;  6 t = 1888: row 59, X speed -80
                ldb     ,x+                     ;  6 t = 1894: byte 119
                sta     <VIA_shift_reg          ;  4 t = 1900: byte 118
                lda     ,x+                     ;  6 t = 1904: byte 120
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1916: byte 119
                stu     <VIA_port_b             ;  5 t = 1920: row 60, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1932: byte 120
                ldb     ,x+                     ;  6 t = 1936: byte 121
                lda     ,x+                     ;  6 t = 1942: byte 122
                stb     <VIA_shift_reg          ;  4 t = 1948: byte 121
                sty     <VIA_port_b             ;  6 t = 1952: row 61, X speed -80
                ldb     ,x+                     ;  6 t = 1958: byte 123
                sta     <VIA_shift_reg          ;  4 t = 1964: byte 122
                lda     ,x+                     ;  6 t = 1968: byte 124
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1980: byte 123
                stu     <VIA_port_b             ;  5 t = 1984: row 62, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1996: byte 124
                ldb     ,x+                     ;  6 t = 2000: byte 125
                lda     ,x+                     ;  6 t = 2006: byte 126
                stb     <VIA_shift_reg          ;  4 t = 2012: byte 125
                sty     <VIA_port_b             ;  6 t = 2016: row 63, X speed -80
                ldb     ,x+                     ;  6 t = 2022: byte 127
                sta     <VIA_shift_reg          ;  4 t = 2028: byte 126
                lda     ,x+                     ;  6 t = 2032: byte 128
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2044: byte 127
                stu     <VIA_port_b             ;  5 t = 2048: row 64, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2060: byte 128
                ldb     ,x+                     ;  6 t = 2064: byte 129
                lda     ,x+                     ;  6 t = 2070: byte 130
                stb     <VIA_shift_reg          ;  4 t = 2076: byte 129
                sty     <VIA_port_b             ;  6 t = 2080: row 65, X speed -80
                ldb     ,x+                     ;  6 t = 2086: byte 131
                sta     <VIA_shift_reg          ;  4 t = 2092: byte 130
                lda     ,x+                     ;  6 t = 2096: byte 132
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2108: byte 131
                stu     <VIA_port_b             ;  5 t = 2112: row 66, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2124: byte 132
                ldb     ,x+                     ;  6 t = 2128: byte 133
                lda     ,x+                     ;  6 t = 2134: byte 134
                stb     <VIA_shift_reg          ;  4 t = 2140: byte 133
                sty     <VIA_port_b             ;  6 t = 2144: row 67, X speed -80
                ldb     ,x+                     ;  6 t = 2150: byte 135
                sta     <VIA_shift_reg          ;  4 t = 2156: byte 134
                lda     ,x+                     ;  6 t = 2160: byte 136
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2172: byte 135
                stu     <VIA_port_b             ;  5 t = 2176: row 68, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2188: byte 136
                ldb     ,x+                     ;  6 t = 2192: byte 137
                lda     ,x+                     ;  6 t = 2198: byte 138
                stb     <VIA_shift_reg          ;  4 t = 2204: byte 137
                sty     <VIA_port_b             ;  6 t = 2208: row 69, X speed -80
                ldb     ,x+                     ;  6 t = 2214: byte 139
                sta     <VIA_shift_reg          ;  4 t = 2220: byte 138
                lda     ,x+                     ;  6 t = 2224: byte 140
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2236: byte 139
                stu     <VIA_port_b             ;  5 t = 2240: row 70, X speed +80
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2252: byte 140
                ldb     ,x+                     ;  6 t = 2256: byte 141
                lda     ,x+                     ;  6 t = 2262: byte 142
                stb     <VIA_shift_reg          ;  4 t = 2268: byte 141
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 2275: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2284: byte 142
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

