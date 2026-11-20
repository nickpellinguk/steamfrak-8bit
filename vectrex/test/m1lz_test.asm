; Ledges as a textured top line and a drift zigzag for each block, beside the 8-row strip
; (tools/m1_ledgez_gen.py, which makes m1lz_engine.asm and m1lz_data.asm).
;
;
; asm6809 -B -o m1lz_test.bin m1lz_test.asm

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
                fcc     "FRAK M1LZ"
                fcb     $80
                fcb     0

main
                jsr     Wait_Recal
                lda     #$7F
                jsr     Intensity_a
                jsr     draw_scene
                bra     main

                include "vlist_d_routine.asm"
                include "m1lz_engine.asm"
                include "m1lz_data.asm"
