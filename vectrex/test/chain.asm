; chain16: a polyline drawn by counting cycles instead of polling the timer, compared with the
; BIOS's Draw_VLc at the same scale. Run in vecx with beamshot (which models the analogue side
; lagging the VIA by 13 cycles, as MAME does) and read with vectrex/tools/timing.py.
;
; Each frame: the same 16-vector square-wave list, (1) with Draw_VLc at scale 16 on the left,
; (2) with chain16 on the right.
;
; asm6809 -B -o chain.bin chain.asm

Wait_Recal      equ     $F192
Intensity_a     equ     $F2AB
Reset0Ref       equ     $F354
Moveto_d        equ     $F312
Draw_VLc        equ     $F3CE

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
                fcc     "FRAK CHAIN"
                fcb     $80
                fcb     0

main
                jsr     Wait_Recal
                lda     #$7F
                jsr     Intensity_a

                ; 1. Draw_VLc, scale 16
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$2090
                jsr     Moveto_d
                lda     #16
                sta     <VIA_t1_cnt_lo
                ldx     #list
                jsr     Draw_VLc

                ; 2. chain16, scale 16
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #$2010
                jsr     Moveto_d
                lda     #16
                sta     <VIA_t1_cnt_lo
                ldx     #list+1
                ldy     #16
                bsr     chain16

                jmp     main

; chain16: draw Y connected vectors from X (dy, dx pairs) at scale 16 (already in the timer's
; low latch), with DP = $D0, the spot off and the beam where the polyline starts.
;
; Times are cycles from the timer starting (the end of the CLR <VIA_t1_cnt_hi). The analogue side
; lags 13 cycles: the beam moves from 13 to 29, so the spot goes on at 13 and off at 29, and the
; next vector's values may reach the DAC any time after 16 (they arrive at 29 or later).
chain16
                lda     ,x+                     ; the first vector's dy, dx
                ldb     ,x+
                sta     <VIA_port_a
                clr     <VIA_port_b             ; mux on: dy to Y's sample-and-hold
                nop                             ; (settling, as the BIOS allows)
                nop
                nop
                inc     <VIA_port_b             ; mux off
                stb     <VIA_port_a             ; dx
                ldb     #$FF
                clr     <VIA_t1_cnt_hi          ; t = 0
                bra     c16_ramp
c16_loop
                ldb     #$FF                    ;  2  58
                clr     <VIA_t1_cnt_hi          ;  6  64 = 0  (so the loop is 67 a vector)
                bra     c16_ramp                ;  3        3
c16_ramp
                lda     ,x                      ;  4        7  next dy
                stb     <VIA_shift_reg          ;  4       11  spot on (it takes 2 cycles to show)
                leay    -1,y                    ;  5       16
                beq     c16_last                ;  3       19
                leax    1,x                     ;  5       24
                clr     <VIA_shift_reg          ;  6       30  spot off
                sta     <VIA_port_a             ;  4       34  next dy (reaches the analogue side at 47)
                clr     <VIA_port_b             ;  6       40  mux on
                ldb     ,x+                     ;  6       46  next dx (while the S/H settles)
                inc     <VIA_port_b             ;  6       52  mux off
                stb     <VIA_port_a             ;  4       56  dx
                bra     c16_loop                ;  3 (+3 here: the loop's three instructions above
                                                ;     are timed as if they followed on)
c16_last
                nop                             ;  2       21
                nop                             ;  2       23
                clr     <VIA_shift_reg          ;  6       29  spot off
                rts

list            fcb     15
                fcb     0,16, 16,0, 0,16, -16,0, 0,16, 16,0, 0,16, -16,0
                fcb     0,16, 16,0, 0,16, -16,0, 0,16, 16,0, 0,16, -16,0
