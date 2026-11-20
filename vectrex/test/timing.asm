; A Vectrex cartridge for measuring what drawing costs, run in vecx with beamshot
; (vectrex/emu) and read with vectrex/tools/timing.py. Each frame draws:
;
;   1. one long line across the top, with the BIOS's Draw_Line_d at scale $FF (is it solid?)
;   2. 16 short vectors with the BIOS's Draw_VLc, at scale $08 (on the left)
;   3. the same 16 at scale $20 (in the middle)
;   4. 8 separate dots, each with Reset0Ref, Moveto_d and Draw_Line_d (along the bottom)
;   5. the same 16 vectors as 2, with draw16 below: a loop that only does what's needed (right)
;
; timing.py works out the cost of each from the cycle each line starts at.
;
; asm6809 -B -o timing.bin timing.asm

Wait_Recal      equ     $F192
Intensity_a     equ     $F2AB
Reset0Ref       equ     $F354
Moveto_d        equ     $F312
Draw_Line_d     equ     $F3DF
Draw_VLc        equ     $F3CE

VIA_port_b      equ     $00
VIA_port_a      equ     $01
VIA_t1_cnt_lo   equ     $04
VIA_t1_cnt_hi   equ     $05
VIA_shift_reg   equ     $0A
VIA_int_flags   equ     $0D

                org     0
                fcc     "g GCE 2026"
                fcb     $80
                fdb     $FD0D                   ; the BIOS's start-up tune
                fcb     $F8,$50,$20,-$56        ; title: height, width, y, x
                fcc     "FRAK TIMING"
                fcb     $80
                fcb     0

main
                jsr     Wait_Recal              ; (DP = $D0 from here)
                lda     #$7F
                jsr     Intensity_a

                ; 1. a long line
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$6080                  ; y, x
                jsr     Moveto_d
                lda     #$FF
                sta     <VIA_t1_cnt_lo
                ldd     #$007F                  ; dy, dx
                jsr     Draw_Line_d

                ; 2. 16 short vectors, scale $08
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$2090
                jsr     Moveto_d
                lda     #$08
                sta     <VIA_t1_cnt_lo
                ldx     #list16
                jsr     Draw_VLc

                ; 3. the same, scale $20
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$20E0
                jsr     Moveto_d
                lda     #$20
                sta     <VIA_t1_cnt_lo
                ldx     #list16
                jsr     Draw_VLc

                ; 4. 8 dots, each from the centre
                ldu     #dots
                ldb     #8
dot_loop        pshs    b
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     ,u++
                jsr     Moveto_d
                lda     #$01
                sta     <VIA_t1_cnt_lo
                ldd     #$0001
                jsr     Draw_Line_d
                puls    b
                decb
                bne     dot_loop

                ; 5. the same 16 vectors as 2 with draw16, scale $08
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$2030
                jsr     Moveto_d
                lda     #$08
                sta     <VIA_t1_cnt_lo
                ldx     #list16+1
                ldb     #16
                bsr     draw16

                jmp     main

; draw16: B vectors from X (dy, dx pairs), at the scale already in the T1 latch.
; The same steps as the BIOS's Draw_VL, without its count in RAM, NOPs or LDD #$0040.
draw16
                stb     count
d16_next
                lda     ,x+
                sta     <VIA_port_a             ; dy to the DAC ...
                clr     <VIA_port_b             ; ... through the mux to the Y sample-and-hold
                lda     ,x+
                inc     <VIA_port_b             ; mux off
                sta     <VIA_port_a             ; dx to the DAC (straight to X)
                lda     #$FF
                sta     <VIA_shift_reg          ; beam on
                clr     <VIA_t1_cnt_hi          ; start the timer (and the ramp)
d16_wait        lda     <VIA_int_flags
                bita    #$40
                beq     d16_wait
                clr     <VIA_shift_reg          ; beam off
                dec     count
                bne     d16_next
                rts

count           equ     $C880                   ; (a byte of RAM the BIOS doesn't use)

list16          fcb     15
                fcb     0,16, 16,0, 0,-16, -16,0, 0,16, 16,0, 0,-16, -16,0
                fcb     0,16, 16,0, 0,-16, -16,0, 0,16, 16,0, 0,-16, -16,0

dots            fdb     $A0A0, $A0C0, $A0E0, $A000, $A020, $A040, $A060, $A070
