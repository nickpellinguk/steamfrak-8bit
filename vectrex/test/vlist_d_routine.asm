; vlist_d's drawing routine, included by vlist_d.asm and raster_test.asm: see vlist_d.asm.
; Needs VIA_port_b, VIA_port_a, VIA_t1_cnt_lo, VIA_t1_cnt_hi and VIA_shift_reg defined.

VL_MIN          equ     28                      ; the shortest scale vlist_d waits for exactly

; vlist_d: draw the vectors at X, with DP = $D0, the spot off and the beam where the list starts.
; Each vector is 4 bytes: scale (1-255), dy, dx, mode ($FF: spot on; $00: off, a move). A
; scale of 0 (with dy 0) ends the list.
;
; Times: t = 0 when the timer starts (the end of CLR <VIA_t1_cnt_hi). The analogue side lags
; 13 cycles, so the beam moves from 13 to scale + 13: the spot goes on at 13 (written at 11) and
; off at scale + 13, and the next vector's values reach the DAC after scale.
vlist_d
                ldu     #vl_nops_end
                lbra    vl_setup                ; (once a list)

; The NOPs fall into the setup, the setup into the timer start and the wait, and the wait jumps
; back into the NOPs: no branches on the way round.
                align   256
vl_nops         fill    $12,128                 ; 128 NOPs, page-aligned
vl_nops_end                                     ; (t = scale - 4 for the vector before)
vl_setup
                ldd     ,x++                    ;  8  scale, dy
                beq     vl_done                 ;  3  (the end of the list)
                clr     <VIA_shift_reg          ;  6  spot off: scale + 13
vl_common
                sta     <VIA_t1_cnt_lo          ;  4  the timer's low latch
                stb     <VIA_port_a             ;  4  dy to the DAC
                clr     <VIA_port_b             ;  6  mux on: to Y's sample-and-hold
                ldb     ,x+                     ;  6  dx (while the S/H settles)
                suba    #VL_MIN                 ;  2  the wait (carry: a scale under 28)
                blo     vs_short                ;  3  (still settling)
                inc     <VIA_port_b             ;  6  mux off
                stb     <VIA_port_a             ;  4  dx to the DAC
                clr     <VIA_t1_cnt_hi          ;  6  t = 0: scale - 4 + 58 = scale + 54 after the last
                ldb     ,x+                     ;  6   6  mode
                stb     $D000+VIA_shift_reg     ;  5  11  spot on (extended: 5 cycles, not 4)
                lsra                            ;  2  13  A = (scale - 28) / 2, C = odd
                lbcs    vl_odd                  ;  5  18  (6 if it branches: 19)
vl_odd          nega                            ;  2  20
                jmp     a,u                     ;  4  24  back into the NOPs: 2 x (scale - 28) / 2,
                                                ;         so vl_setup at 24 + (scale - 28) = scale - 4

; Scales under 28: each has its own block (vlist_d_short.asm), which starts at t = 3 with Y
; pointing to it, A = $40 (timer 1's flag, for the blocks that poll) and B = the mode
vs_short                                        ;     (A = scale - 28: -27..-1)
                lsla                            ;  2  the table's entries are 2 bytes
                ldy     #vs_table_end           ;  4
                ldy     a,y                     ;  7  this scale's block
                inc     <VIA_port_b             ;  6  mux off
                stb     <VIA_port_a             ;  4  dx to the DAC
                ldb     ,x+                     ;  6  mode
                lda     #$40                    ;  2
                clr     <VIA_t1_cnt_hi          ;  6  t = 0
                jmp     ,y                      ;  3  t = 3

; after a short vector's spot off: the next vector, without vl_setup's spot off
vs_next
                ldd     ,x++                    ;  8  scale, dy
                lbeq    vl_done                 ;  6
                lbra    vl_common               ;  5

vl_done
                clr     <VIA_shift_reg          ;  6  spot off: scale + 13
                rts

                include "vlist_d_short.asm"
