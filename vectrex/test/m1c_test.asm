; Cave platforms (the ledges) as rows: two rows (milestone 1's strip) against more rows
; (tools/m1_cave_gen.py, which makes m1c_engine.asm and m1c_data.asm).
;
;
; asm6809 -B -o m1c_test.bin m1c_test.asm

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
                fcc     "FRAK M1C"
                fcb     $80
                fcb     0

main
                jsr     Wait_Recal
                lda     #$7F
                jsr     Intensity_a
                jsr     draw_scene
                bra     main

                include "vlist_d_routine.asm"
                include "m1c_engine.asm"
                include "m1c_data.asm"
