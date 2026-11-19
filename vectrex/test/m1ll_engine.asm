; made by vectrex/tools/m1_ledgel_gen.py

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

; the lines: Y = $0050 and U = $0108 (the bottom turn), X = $80B0 and S = $0150 (the top
; turn), B = $F8 (X -8), A for the spot's bytes; the beam at the first line's top
hatch_5
                sts     $C8C8                   ;  7 (S: a value for the top turn while the lines are drawn)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
                ldy     #$80B0                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -80 (down)
                ldy     #$81F8                  ;  4 (the sample-and-hold settles)
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed -8
                ldy     #$0050                  ;  4 
                ldu     #$0108                  ;  3 
                ldx     #$80B0                  ;  3 
                lds     #$0150                  ;  4 
                ldd     #$FFF8                  ;  3 
                stb     <VIA_port_a             ;  4 (X -8)
                lda     #$01                    ;  2 
                sta     <VIA_port_b             ;  4 t = 0: ramp on
                lda     #%00111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 7: the spot's next 8 bits
                brn     *                       ;  3 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 24
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 32
                brn     *                       ;  3 
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 48
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 59
                stb     <VIA_port_a             ;  4 t = 65: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 71: the spot's next 8 bits
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 79: the spot's next 8 bits
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 85
                stu     <VIA_port_b             ;  5 t = 91
                lda     #%00111111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 98: the spot's next 8 bits
                brn     *                       ;  3 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 107: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 111
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 122
                stb     <VIA_port_a             ;  4 t = 128: X -8 (down)
                lda     #%00011100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 134: the spot's next 8 bits
                sty     <VIA_port_b             ;  6 t = 138
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 146
                brn     *                       ;  3 
                stx     <VIA_port_b             ;  5 t = 154
                lda     #%00000000              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 161: the spot's next 8 bits
                sts     <VIA_port_b             ;  6 t = 165
                stb     <VIA_port_a             ;  4 t = 171: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 177: the spot's next 8 bits
                lda     #%11111000              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 183: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 191
                stu     <VIA_port_b             ;  5 t = 197
                lda     #%00111111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: the spot's next 8 bits
                brn     *                       ;  3 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 213: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 217
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 228
                stb     <VIA_port_a             ;  4 t = 234: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 240: the spot's next 8 bits
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 248: the spot's next 8 bits
                sty     <VIA_port_b             ;  6 t = 252
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 260
                brn     *                       ;  3 
                nop                             ;  2 
                lda     #%00111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 272: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 276
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 287
                stb     <VIA_port_a             ;  4 t = 293: X -8 (down)
                lda     #%00010000              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 299: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 309
                stu     <VIA_port_b             ;  5 t = 315
                brn     *                       ;  3 
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 327: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 331
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 342
                stb     <VIA_port_a             ;  4 t = 348: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 354: the spot's next 8 bits
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 362: the spot's next 8 bits
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 368
                stu     <VIA_port_b             ;  5 t = 374
                lda     #%00111111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 381: the spot's next 8 bits
                brn     *                       ;  3 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 390: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 394
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 405
                stb     <VIA_port_a             ;  4 t = 411: X -8 (down)
                lda     #%00011100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 417: the spot's next 8 bits
                sty     <VIA_port_b             ;  6 t = 421
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 429
                brn     *                       ;  3 
                stx     <VIA_port_b             ;  5 t = 437
                lda     #%00000000              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 444: the spot's next 8 bits
                sts     <VIA_port_b             ;  6 t = 448
                stb     <VIA_port_a             ;  4 t = 454: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: the spot's next 8 bits
                lda     #%11111000              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 466: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 474
                stu     <VIA_port_b             ;  5 t = 480
                lda     #%00111111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 487: the spot's next 8 bits
                brn     *                       ;  3 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 496: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 500
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 511
                stb     <VIA_port_a             ;  4 t = 517: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 523: the spot's next 8 bits
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 531: the spot's next 8 bits
                sty     <VIA_port_b             ;  6 t = 535
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 543
                brn     *                       ;  3 
                nop                             ;  2 
                lda     #%00111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 555: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 559
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 570
                stb     <VIA_port_a             ;  4 t = 576: X -8 (down)
                lda     #%00010000              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 582: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 592
                stu     <VIA_port_b             ;  5 t = 598
                brn     *                       ;  3 
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 610: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 614
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 625
                stb     <VIA_port_a             ;  4 t = 631: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 637: the spot's next 8 bits
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 645: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 653
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 661
                lda     #%00111111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 668: the spot's next 8 bits
                brn     *                       ;  3 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 677: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 681
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 692
                stb     <VIA_port_a             ;  4 t = 698: X -8 (down)
                lda     #%00011100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 704: the spot's next 8 bits
                sty     <VIA_port_b             ;  6 t = 708
                stu     <VIA_port_b             ;  5 t = 714
                brn     *                       ;  3 
                nop                             ;  2 
                stx     <VIA_port_b             ;  5 t = 724
                lda     #%00000000              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 731: the spot's next 8 bits
                sts     <VIA_port_b             ;  6 t = 735
                stb     <VIA_port_a             ;  4 t = 741: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 747: the spot's next 8 bits
                lda     #%11111000              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 753: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 763
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 771
                lda     #%00111111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 778: the spot's next 8 bits
                brn     *                       ;  3 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 787: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 791
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 802
                stb     <VIA_port_a             ;  4 t = 808: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 814: the spot's next 8 bits
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 822: the spot's next 8 bits
                sty     <VIA_port_b             ;  6 t = 826
                stu     <VIA_port_b             ;  5 t = 832
                brn     *                       ;  3 
                nop                             ;  2 
                nop                             ;  2 
                lda     #%00111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 846: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 850
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 861
                stb     <VIA_port_a             ;  4 t = 867: X -8 (down)
                lda     #%00010000              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 873: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 883
                stu     <VIA_port_b             ;  5 t = 889
                brn     *                       ;  3 
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 901: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 905
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 916
                stb     <VIA_port_a             ;  4 t = 922: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 928: the spot's next 8 bits
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 936: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 944
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 952
                lda     #%00111111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 959: the spot's next 8 bits
                brn     *                       ;  3 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 968: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 972
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 983
                stb     <VIA_port_a             ;  4 t = 989: X -8 (down)
                lda     #%00011100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 995: the spot's next 8 bits
                sty     <VIA_port_b             ;  6 t = 999
                stu     <VIA_port_b             ;  5 t = 1005
                brn     *                       ;  3 
                nop                             ;  2 
                stx     <VIA_port_b             ;  5 t = 1015
                lda     #%00000000              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1022: the spot's next 8 bits
                sts     <VIA_port_b             ;  6 t = 1026
                stb     <VIA_port_a             ;  4 t = 1032: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1038: the spot's next 8 bits
                lda     #%11111000              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1044: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 1054
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 1062
                lda     #%00111111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1069: the spot's next 8 bits
                brn     *                       ;  3 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1078: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 1082
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 1093
                stb     <VIA_port_a             ;  4 t = 1099: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1105: the spot's next 8 bits
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1113: the spot's next 8 bits
                sty     <VIA_port_b             ;  6 t = 1117
                stu     <VIA_port_b             ;  5 t = 1123
                brn     *                       ;  3 
                nop                             ;  2 
                nop                             ;  2 
                lda     #%00111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1137: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 1141: ramp off
                clr     <VIA_shift_reg          ;  6 spot off
                lds     $C8C8                   ;  6 the stack back
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; the lines: Y = $0050 and U = $0108 (the bottom turn), X = $80B0 and S = $0150 (the top
; turn), B = $F8 (X -8), A for the spot's bytes; the beam at the first line's top
hatch_4
                sts     $C8C8                   ;  7 (S: a value for the top turn while the lines are drawn)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
                ldy     #$80B0                  ;  4 
                sty     <VIA_port_b             ;  6 mux on: Y speed -80 (down)
                ldy     #$81F8                  ;  4 (the sample-and-hold settles)
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 mux off, X speed -8
                ldy     #$0050                  ;  4 
                ldu     #$0108                  ;  3 
                ldx     #$80B0                  ;  3 
                lds     #$0150                  ;  4 
                ldd     #$FFF8                  ;  3 
                stb     <VIA_port_a             ;  4 (X -8)
                lda     #$01                    ;  2 
                sta     <VIA_port_b             ;  4 t = 0: ramp on
                lda     #%00111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 7: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 29
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 38
                lda     #%00111111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 45: the spot's next 8 bits
                brn     *                       ;  3 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 54: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 58
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 69
                nop                             ;  2 
                stb     <VIA_port_a             ;  4 t = 77: X -8 (down)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 89: the spot's next 8 bits
                sty     <VIA_port_b             ;  6 t = 93
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 101
                brn     *                       ;  3 
                nop                             ;  2 
                lda     #%00111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 113: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 117
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 128
                nop                             ;  2 
                stb     <VIA_port_a             ;  4 t = 136: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 142: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 156
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 164
                lda     #%11111111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 171: the spot's next 8 bits
                brn     *                       ;  3 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 180: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 184
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 195
                nop                             ;  2 
                stb     <VIA_port_a             ;  4 t = 203: X -8 (down)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 215: the spot's next 8 bits
                sty     <VIA_port_b             ;  6 t = 219
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 227
                brn     *                       ;  3 
                nop                             ;  2 
                lda     #%00111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 239: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 243
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 254
                nop                             ;  2 
                stb     <VIA_port_a             ;  4 t = 262: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 282
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 290
                lda     #%11111111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 297: the spot's next 8 bits
                brn     *                       ;  3 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 306: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 310
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 321
                nop                             ;  2 
                stb     <VIA_port_a             ;  4 t = 329: X -8 (down)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 341: the spot's next 8 bits
                sty     <VIA_port_b             ;  6 t = 345
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 353
                brn     *                       ;  3 
                nop                             ;  2 
                lda     #%00111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 365: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 369
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 380
                nop                             ;  2 
                stb     <VIA_port_a             ;  4 t = 388: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 394: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 408
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 416
                lda     #%11111111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 423: the spot's next 8 bits
                brn     *                       ;  3 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 432: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 436
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 447
                nop                             ;  2 
                stb     <VIA_port_a             ;  4 t = 455: X -8 (down)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 467: the spot's next 8 bits
                sty     <VIA_port_b             ;  6 t = 471
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 479
                brn     *                       ;  3 
                nop                             ;  2 
                lda     #%00111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 491: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 495
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 506
                nop                             ;  2 
                stb     <VIA_port_a             ;  4 t = 514: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 520: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 534
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 542
                lda     #%11111111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 549: the spot's next 8 bits
                brn     *                       ;  3 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 558: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 562
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 573
                nop                             ;  2 
                stb     <VIA_port_a             ;  4 t = 581: X -8 (down)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 593: the spot's next 8 bits
                sty     <VIA_port_b             ;  6 t = 597
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 605
                brn     *                       ;  3 
                nop                             ;  2 
                lda     #%00111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 617: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 621
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 632
                nop                             ;  2 
                stb     <VIA_port_a             ;  4 t = 640: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 646: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 660
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 668
                lda     #%11111111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 675: the spot's next 8 bits
                brn     *                       ;  3 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 684: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 688
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 699
                nop                             ;  2 
                stb     <VIA_port_a             ;  4 t = 707: X -8 (down)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 719: the spot's next 8 bits
                sty     <VIA_port_b             ;  6 t = 723
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 731
                brn     *                       ;  3 
                nop                             ;  2 
                lda     #%00111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 743: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 747
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 758
                nop                             ;  2 
                stb     <VIA_port_a             ;  4 t = 766: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 772: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 786
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 794
                lda     #%11111111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 801: the spot's next 8 bits
                brn     *                       ;  3 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 810: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 814
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 825
                nop                             ;  2 
                stb     <VIA_port_a             ;  4 t = 833: X -8 (down)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 845: the spot's next 8 bits
                sty     <VIA_port_b             ;  6 t = 849
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 857
                brn     *                       ;  3 
                nop                             ;  2 
                lda     #%00111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 869: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 873
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 884
                nop                             ;  2 
                stb     <VIA_port_a             ;  4 t = 892: X -8 (down)
                lda     #%00011111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 898: the spot's next 8 bits
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sty     <VIA_port_b             ;  6 t = 912
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 920
                lda     #%11111111              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 927: the spot's next 8 bits
                brn     *                       ;  3 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 936: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 940
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sts     <VIA_port_b             ;  6 t = 951
                nop                             ;  2 
                stb     <VIA_port_a             ;  4 t = 959: X -8 (down)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                lda     #%11111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 971: the spot's next 8 bits
                sty     <VIA_port_b             ;  6 t = 975
                nop                             ;  2 
                stu     <VIA_port_b             ;  5 t = 983
                brn     *                       ;  3 
                nop                             ;  2 
                lda     #%00111100              ;  2 
                sta     <VIA_shift_reg          ;  4 t = 995: the spot's next 8 bits
                stx     <VIA_port_b             ;  5 t = 999: ramp off
                clr     <VIA_shift_reg          ;  6 spot off
                lds     $C8C8                   ;  6 the stack back
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

