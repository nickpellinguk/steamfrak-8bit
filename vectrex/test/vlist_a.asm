; vlist_a: vlist (vlist.asm) with the wait worked out from the scale as it draws, instead of each
; vector carrying its wait's address: A = scale - 28, LSRA, LBCS to the next instruction (6
; cycles if the scale was odd, 5 if even), NEGA, then JMP A,U into a page-aligned run of NOPs
; (U at its end). 4 bytes a vector instead of 6.
;
; The test list (vlist_a_data.asm, made by vectrex/tools/vlist_data.py --computed) is the same
; square wave as vlist's, but from scale 28 (vlist_a's shortest).
;
; asm6809 -B -o vlist_a.bin vlist_a.asm

Wait_Recal      equ     $F192
Intensity_a     equ     $F2AB
Reset0Ref       equ     $F354
Moveto_d        equ     $F312

VIA_port_b      equ     $00
VIA_port_a      equ     $01
VIA_t1_cnt_lo   equ     $04
VIA_t1_cnt_hi   equ     $05
VIA_shift_reg   equ     $0A

VL_MIN          equ     28                      ; the shortest scale vlist_a can wait for

                org     0
                fcc     "g GCE 2026"
                fcb     $80
                fdb     $FD0D
                fcb     $F8,$50,$20,-$56
                fcc     "FRAK VLIST A"
                fcb     $80
                fcb     0

main
                jsr     Wait_Recal
                lda     #$7F
                jsr     Intensity_a
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$4090                  ; y, x
                jsr     Moveto_d
                ldx     #test_list
                jsr     vlist_a
                jmp     main

; vlist_a: draw the vectors at X, with DP = $D0, the spot off and the beam where the list starts.
; Each vector is 4 bytes: scale (28-255), dy, dx, mode ($FF: spot on; $00: off, a move). A
; scale of 0 (with dy 0) ends the list.
;
; Times: t = 0 when the timer starts (the end of CLR <VIA_t1_cnt_hi). The analogue side lags
; 13 cycles, so the beam moves from 13 to scale + 13: the spot goes on at 13 (written at 11) and
; off at scale + 13, and the next vector's values reach the DAC after scale.
vlist_a
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
                sta     <VIA_t1_cnt_lo          ;  4  the timer's low latch
                stb     <VIA_port_a             ;  4  dy to the DAC
                clr     <VIA_port_b             ;  6  mux on: to Y's sample-and-hold
                ldb     ,x+                     ;  6  dx (while the S/H settles)
                suba    #VL_MIN                 ;  2  the wait
                inc     <VIA_port_b             ;  6  mux off
                stb     <VIA_port_a             ;  4  dx to the DAC
                clr     <VIA_t1_cnt_hi          ;  6  t = 0: scale - 4 + 55 = scale + 51 after the last
                ldb     ,x+                     ;  6   6  mode
                stb     $D000+VIA_shift_reg     ;  5  11  spot on (extended: 5 cycles, not 4)
                lsra                            ;  2  13  A = (scale - 28) / 2, C = odd
                lbcs    vl_odd                  ;  5  18  (6 if it branches: 19)
vl_odd          nega                            ;  2  20
                jmp     a,u                     ;  4  24  back into the NOPs: 2 x (scale - 28) / 2,
                                                ;         so vl_setup at 24 + (scale - 28) = scale - 4
vl_done
                clr     <VIA_shift_reg          ;  6  spot off: scale + 13
                rts

                include "vlist_a_data.asm"
