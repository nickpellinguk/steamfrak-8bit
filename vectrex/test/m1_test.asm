; Milestone 1: the raster engine's column routines (raster_engine.asm) drawing every kind of
; column-drawn object (m1_data.asm), two of them partly off the left and right edges, clipped by
; the column. Both made by vectrex/tools/m1_gen.py.
;
; asm6809 -B -o m1_test.bin m1_test.asm

Wait_Recal      equ     $F192
Intensity_a     equ     $F2AB
Reset0Ref       equ     $F354
Moveto_d        equ     $F312

VIA_port_b      equ     $00
VIA_port_a      equ     $01
VIA_t1_cnt_lo   equ     $04
VIA_t1_cnt_hi   equ     $05
VIA_shift_reg   equ     $0A
VIA_aux_cntl    equ     $0B

                org     0
                fcc     "g GCE 2026"
                fcb     $80
                fdb     $FD0D
                fcb     $F8,$50,$20,-$56
                fcc     "FRAK M1"
                fcb     $80
                fcb     0

main
                jsr     Wait_Recal
                lda     #$7F
                jsr     Intensity_a
                jsr     draw_scene
                bra     main

                include "vlist_d_routine.asm"
                include "raster_engine.asm"
                include "m1_data.asm"
