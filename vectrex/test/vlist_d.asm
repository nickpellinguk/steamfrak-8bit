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

                include "vlist_d_routine.asm"
                include "vlist_d_data.asm"
