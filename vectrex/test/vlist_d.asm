; vlist_d: vlist_c (vlist_c.asm) with every short scale drawn exactly too. Scales of 28 and
; over use vlist_a's exact wait. For scales under 28 the SUBA #28 sets the carry, and BLO goes
; to a table (made by vectrex/tools/vlist_d_short.py, in vlist_d_short.asm) that gives each scale
; its own small block of code, chosen before the timer starts:
;
;   - a fixed delay: spot on, a few NOPs and BRNs (scale - 4 cycles), spot off;
;   - or, where there's time for it, the timer polled with the reads lined up: spot on, a delay
;     of 0-8 cycles (by scale mod 7: the poll loop is 7 cycles a time), the BIT loop, spot off.
;
; The spot can't be on for less than 4 cycles (two stores), so scales 1-3 come out as 4.
;
; The test list (vlist_d_data.asm, made by vectrex/tools/vlist_data.py --all) has every scale
; from 1 to 29, then 40, 100 and 255.
;
; asm6809 -B -o vlist_d.bin vlist_d.asm

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
                fcc     "FRAK VLIST D"
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
                jsr     vlist_d
                jmp     main

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
                include "vlist_d_data.asm"
