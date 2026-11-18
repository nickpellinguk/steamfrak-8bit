; vlist_c: vlist_a (vlist_a.asm), with scales under 28 drawn by polling the timer instead (the
; BIOS's way), so any scale from 1 to 255 can be drawn: the SUBA #28 that works out the wait
; sets the carry for those, and BLO picks the polling path, before the timer starts.
;
; The test list (vlist_c_data.asm, made by vectrex/tools/vlist_data.py --short) is a square wave
; of scales 1 to 255.
;
; asm6809 -B -o vlist_c.bin vlist_c.asm

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
                fcc     "FRAK VLIST C"
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
                jsr     vlist_c
                jmp     main

; vlist_c: draw the vectors at X, with DP = $D0, the spot off and the beam where the list starts.
; Each vector is 4 bytes: scale (1-255), dy, dx, mode ($FF: spot on; $00: off, a move). A
; scale of 0 (with dy 0) ends the list.
;
; Times: t = 0 when the timer starts (the end of CLR <VIA_t1_cnt_hi). The analogue side lags
; 13 cycles, so the beam moves from 13 to scale + 13: the spot goes on at 13 (written at 11) and
; off at scale + 13, and the next vector's values reach the DAC after scale.
vlist_c
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

; Scales under 28: poll the timer, as the BIOS does
vs_short
                inc     <VIA_port_b             ;  6  mux off
                stb     <VIA_port_a             ;  4  dx to the DAC
                ldb     ,x+                     ;  6  mode
                lda     #$40                    ;  2  (timer 1's flag)
                clr     <VIA_t1_cnt_hi          ;  6  t = 0
                nop                             ;  2   2
                nop                             ;  2   4
                nop                             ;  2   6
                stb     $D000+VIA_shift_reg     ;  5  11  spot on
vs_poll         bita    <$0D                    ;  4      has the timer run out?
                beq     vs_poll                 ;  3
                nop                             ;  2      the beam is still moving (13-cycle lag):
                nop                             ;  2      3 NOPs is the fewest that never cuts a
                nop                             ;  2      line short (polling is 7 cycles a time)
                clr     <VIA_shift_reg          ;  6      spot off
                ldd     ,x++                    ;  8  scale, dy
                beq     vl_done                 ;  3
                bra     vl_common               ;  3
vl_done
                clr     <VIA_shift_reg          ;  6  spot off: scale + 13
                rts

                include "vlist_c_data.asm"
