; made by vectrex/tools/m1_ledgez_gen.py

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

; 1 rows ([0] of the ledge) of any length: 16 x bytes + turns
cave_top
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
cave_top_0
                lda     ,x+                     ;  6 t = 6 + 16i
                sta     >$D000+VIA_shift_reg    ;  5 t = 12 + 16i
                decb                            ;  2 
                bne     cave_top_0              ;  3 
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

; a zigzag sprite, 16 x 10: 26 rows (pitch 0.40 pixels), drift 2, 53 bytes: ramp on 835 cycles
; in: X = the data, the beam at the sprite's top left
zig_blk_2
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
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 835: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 16 x 10: 17 rows (pitch 0.60 pixels), drift 3, 35 bytes: ramp on 547 cycles
; in: X = the data, the beam at the sprite's top left
zig_blk_3
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
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 547: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 16 x 10: 13 rows (pitch 0.80 pixels), drift 4, 27 bytes: ramp on 419 cycles
; in: X = the data, the beam at the sprite's top left
zig_blk_4
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
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 419: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a zigzag sprite, 16 x 10: 11 rows (pitch 1.01 pixels), drift 5, 23 bytes: ramp on 355 cycles
; in: X = the data, the beam at the sprite's top left
zig_blk_5
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
                ldx     #$8100                  ;  3 
                stx     <VIA_port_b             ;  5 t = 355: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

