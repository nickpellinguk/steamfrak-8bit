; vlist: a vector list drawn with an exact software wait for each vector, so each one can have
; its own scale (18-255), with the spot on just while the beam moves. Run in vecx with beamshot
; (the analogue side lagging the VIA by 13 cycles, as MAME has it) and read with
; vectrex/tools/timing.py.
;
; The test list (vlist_data.asm, made by vectrex/tools/vlist_data.py) is a square wave whose
; vectors have a range of scales from 18 to 255, with dx and dy scaled to keep the vectors about
; the same length.
;
; asm6809 -B -o vlist.bin vlist.asm

Wait_Recal      equ     $F192
Intensity_a     equ     $F2AB
Reset0Ref       equ     $F354
Moveto_d        equ     $F312

VIA_port_b      equ     $00
VIA_port_a      equ     $01
VIA_t1_cnt_lo   equ     $04
VIA_t1_cnt_hi   equ     $05
VIA_shift_reg   equ     $0A

                org     0
                fcc     "g GCE 2026"
                fcb     $80
                fdb     $FD0D
                fcb     $F8,$50,$20,-$56
                fcc     "FRAK VLIST"
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
                jsr     vlist
                jmp     main

; vlist: draw the vectors at X, with DP = $D0, the spot off and the beam where the list starts.
; Each vector is 6 bytes:
;
;   scale, dy, dx, mode ($FF: spot on; $00: off, a move), wait (2 bytes)
;
; where wait is the address to jump to for this vector's wait: with k = scale - 16,
; VL_WAIT_EVEN - n for k = 2n + 2, VL_WAIT_ODD - n for k = 2n + 3 (n = 0..119), or the same in
; VL_LAST_EVEN / VL_LAST_ODD for the last vector. vlist_data.py works it out.
;
; Times: t = 0 when the timer starts (the end of CLR <VIA_t1_cnt_hi). The analogue side lags
; 13 cycles, so the beam moves from 13 to scale + 13: the spot goes on at 13 (written at 12: in
; vecx it shows a cycle or two after the write) and off at scale + 13, and the next vector's
; values reach the DAC after scale (so they arrive after the beam has stopped).
vlist
                lbra    vl_setup                ; (once a list: its time doesn't matter)

                fill    $12,119                 ; 119 NOPs
VL_WAIT_ODD     bra     vl_setup                ;  3
                fill    $12,119                 ; 119 NOPs
VL_WAIT_EVEN    nop                             ;  2, falling into vl_setup
                                                ; (so vl_setup starts at 15 + 2n + 2 or 3,
                                                ;  which is scale - 1)
vl_setup
                ldd     ,x++                    ;  8  scale, dy
                clr     <VIA_shift_reg          ;  6  spot off: scale + 13
                sta     <VIA_t1_cnt_lo          ;  4  the timer's low latch
                stb     <VIA_port_a             ;  4  dy to the DAC
                clr     <VIA_port_b             ;  6  mux on: to Y's sample-and-hold
                ldd     ,x++                    ;  8  dx, mode (while the S/H settles)
                inc     <VIA_port_b             ;  6  mux off
                sta     <VIA_port_a             ;  4  dx to the DAC
                clr     <VIA_t1_cnt_hi          ;  6  t = 0 (scale - 1 + 52 after the last t = 0)
                ldu     ,x++                    ;  8  t =  8  where to wait to
                stb     <VIA_shift_reg          ;  4      12  spot on (mode)
                jmp     ,u                      ;  3      15

; The same waits for the last vector, ending in vl_done instead
                fill    $12,119                 ; 119 NOPs
VL_LAST_ODD     bra     vl_done                 ;  3
                fill    $12,119                 ; 119 NOPs
VL_LAST_EVEN    nop                             ;  2
vl_done                                         ; (scale - 1)
                ldd     ,x++                    ;  8  (for the time it takes)
                clr     <VIA_shift_reg          ;  6  spot off: scale + 13
                rts

                include "vlist_data.asm"
