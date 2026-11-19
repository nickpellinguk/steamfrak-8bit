; Milestone 1 at run time: a scene of column sprites (facing either way), drifting rows and a
; strip of ledges, all clipped, positioned and moved between by the 6809 as it runs. The scene
; scrolls back and forth (40 pixels each way), so things cross both edges. The routines and the
; data are made by vectrex/tools/m1_rt_gen.py (m1_rt_engine.asm, m1_rt_data.asm).
;
; Positions are in BBC pixels (16 bits, from the middle of the screen, y down); the beam's in
; beam units (160 a pixel, y up). The window is the screen's width: x from WL to WR.
;
; asm6809 -B -o m1_rt.bin m1_rt.asm

Wait_Recal      equ     $F192
Intensity_a     equ     $F2AB
Reset0Ref       equ     $F354

VIA_port_b      equ     $00
VIA_port_a      equ     $01
VIA_t1_cnt_lo   equ     $04
VIA_t1_cnt_hi   equ     $05
VIA_t2_hi       equ     $09
VIA_shift_reg   equ     $0A
VIA_aux_cntl    equ     $0B
VIA_cntl        equ     $0C
VIA_int_flags   equ     $0D

WL              equ     -103                    ; the window, in pixels
WR              equ     103
COL_PAD         equ     2                       ; blank pixels at each end of a column
TOLERANCE       equ     40                      ; a move left this far short (beam units) isn't finished

; RAM (the BIOS uses up to $C87F)
COUNT           equ     $C880                   ; (the column routines')
ROW1            equ     $C882                   ; (the strip's)
BEAM_X          equ     $C884                   ; where the beam is (beam units)
BEAM_Y          equ     $C886
TGT_X           equ     $C888                   ; where to move it
TGT_Y           equ     $C88A
DX              equ     $C88C
DY              equ     $C88E
OBJ_X           equ     $C890                   ; the thing being drawn: its left edge and top (pixels)
OBJ_Y           equ     $C892
FACING          equ     $C894
C0              equ     $C895                   ; its first column drawn, and one past the last
C1              equ     $C896
STRIP_N         equ     $C899                   ; (the strip's: bytes a row, masks)
M0F             equ     $C89A
M0L             equ     $C89B
M1F             equ     $C89C
M1L             equ     $C89D
SCROLL          equ     $C89E
DIRN            equ     $C8A0
T2_LEFT         equ     $C8A2                   ; timer 2's high byte after drawing (x 256: cycles left)
SPR             equ     $C8A4
TMP             equ     $C8A6
TMP2            equ     $C8A8
AX              equ     $C8AA
AY              equ     $C8AB
B0              equ     $C8AD
B1              equ     $C8AE
MULT            equ     $C8B0
X0              equ     $C8B2
YT              equ     $C8B4
MOVING          equ     $C8B6
COLS            equ     $C8B7
ROUTINE         equ     $C8B9

                org     0
                fcc     "g GCE 2026"
                fcb     $80
                fdb     $FD0D
                fcb     $F8,$50,$20,-$56
                fcc     "FRAK M1 RUN TIME"
                fcb     $80
                fcb     0

                ldd     #0                      ; (RAM starts with anything in it)
                std     SCROLL
                sta     DIRN
main
                jsr     Wait_Recal
                lda     #$7F
                jsr     Intensity_a
                jsr     Reset0Ref               ; the beam to the middle (and held there...
                lda     #$CE
                sta     <VIA_cntl               ; ...until let go: Moveto_d does this, move_to doesn't)
                ldd     #0
                std     BEAM_X
                std     BEAM_Y
                ; the scroll: back and forth, -40 to 40
                ldd     SCROLL
                tst     DIRN
                bne     sc_down
                addd    #1
                cmpd    #40
                blt     sc_set
                inc     DIRN
                bra     sc_set
sc_down         subd    #1
                cmpd    #-40
                bgt     sc_set
                clr     DIRN
sc_set          std     SCROLL
                ldx     #scene
sc_loop         lda     ,x+
                beq     sc_end
                ldu     ,x++
                pshs    a
                ldd     ,x++
                addd    SCROLL
                std     OBJ_X
                ldd     ,x++
                std     OBJ_Y
                ldb     ,x+
                stb     FACING
                puls    a
                pshs    x
                cmpa    #1
                bne     sc_2
                jsr     draw_cols
                bra     sc_next
sc_2            cmpa    #2
                bne     sc_3
                jsr     draw_rows
                bra     sc_next
sc_3            jsr     draw_strip
sc_next         puls    x
                bra     sc_loop
sc_end          lda     <VIA_t2_hi              ; (not the low byte: reading that would clear
                sta     T2_LEFT                 ;  the flag Wait_Recal waits for)
                jmp     main

; --- moving the beam -----------------------------------------------------------------------------

; move_to: from BEAM to TGT (beam units). A coarse vector at scale 128 (the distance / 128),
; then a fine one at scale 1 (its remainder: the distance's low 7 bits, in two's complement too),
; the fine one left out if within TOLERANCE (BEAM then where the beam really is). Moves of 128
; x 128 units (102 pixels) or more go in steps of 127 x 128 first.
move_to         bsr     move_start
                jmp     move_finish

; move_start: as move_to, but returns with the coarse vector under way (do other work, then
; move_finish)
move_start
                clr     <VIA_shift_reg          ; spot off
                lda     #$80
                sta     <VIA_t1_cnt_lo          ; scale 128
mt_again        ldd     TGT_X
                subd    BEAM_X
                std     DX
                ldd     TGT_Y
                subd    BEAM_Y
                std     DY
                lda     DX                      ; out of the coarse vector's reach
                adda    #$40                    ; (-16384..16383: high byte + $40 under $80)?
                cmpa    #$80
                bhs     mt_far_go
                lda     DY
                adda    #$40
                cmpa    #$80
                blo     mt_coarse
mt_far_go       ldd     DX
                jsr     mt_far
                stb     AX
                ldd     DY
                jsr     mt_far
                stb     AY
                lda     AY                      ; yes: a step of up to 127 x 128 that way first
                ldb     AX
                jsr     vec_blank
                ldb     AX
                jsr     mul128
                addd    BEAM_X
                std     BEAM_X
                ldb     AY
                jsr     mul128
                addd    BEAM_Y
                std     BEAM_Y
                bra     mt_again
mt_coarse       ldd     DX
                aslb
                rola
                sta     AX                      ; DX / 128
                ldd     DY
                aslb
                rola                            ; A = DY / 128
                ldb     AX
                bne     mt_c_go
                tsta
                beq     mt_fine                 ; (no coarse vector needed)
mt_c_go         jsr     vec_start               ; the coarse vector: start it...
                lda     #1
                sta     MOVING
                bra     mt_rest
mt_fine         clr     MOVING
mt_rest         lda     DX+1                    ; the rest: the low 7 bits
                anda    #$7F
                sta     AX
                lda     DY+1
                anda    #$7F
                sta     AY
                rts

; move_finish: wait for the coarse vector, then the fine one (or not)
move_finish     tst     MOVING
                beq     mt_f2
                jsr     vec_wait
mt_f2           lda     AX
                cmpa    #TOLERANCE
                bhi     mt_last
                lda     AY
                cmpa    #TOLERANCE
                bhi     mt_last
                ldb     AX                      ; near enough: the beam's that short
                clra
                std     DX
                ldd     TGT_X
                subd    DX
                std     BEAM_X
                ldb     AY
                clra
                std     DY
                ldd     TGT_Y
                subd    DY
                std     BEAM_Y
                rts
mt_last         lda     #1
                sta     <VIA_t1_cnt_lo          ; scale 1: exactly the rest
                lda     AY
                ldb     AX
                jsr     vec_blank
                ldd     TGT_X
                std     BEAM_X
                ldd     TGT_Y
                std     BEAM_Y
                rts

; mt_far: D -> B = 0 if within the coarse vector's reach (-16384..16383), else +-127
mt_far          cmpd    #16384
                blt     mf_a
                ldb     #127
                rts
mf_a            cmpd    #-16384
                bge     mf_b
                ldb     #-127
                rts
mf_b            clrb
                rts

; mul128: D = B x 128 (B signed)
mul128          tfr     b,a
                clrb
                asra
                rorb
                rts

; vec_blank: a vector with the spot off: A = Y speed, B = X speed, the scale in timer 1's latch.
; vec_start starts it and returns; vec_wait waits for it to finish.
vec_blank       jsr     vec_start
vec_wait        lda     #$40
vb_wait         bita    <VIA_int_flags
                beq     vb_wait
                rts
vec_start       sta     <VIA_port_a
                clr     <VIA_port_b             ; mux on: to Y
                nop
                nop
                nop
                inc     <VIA_port_b             ; mux off
                stb     <VIA_port_a
                clr     <VIA_t1_cnt_hi          ; go
                rts

; mul160: D = D x 160 (pixels to beam units), for D in -256..511: the low byte by MUL, then
; the high byte's part (+-40960)
mul160          sta     MULT
                lda     #160
                mul                             ; D = low byte x 160
                tst     MULT
                beq     m160_done
                bmi     m160_neg
                addd    #40960                  ; (high byte 1)
                rts
m160_neg        subd    #40960                  ; (high byte -1)
m160_done       rts

negd            coma
                comb
                addd    #1
                rts

; clamp_w: D -> B = D clamped to 0..TMP
clamp_w         tsta
                bpl     cw_pos
                clrb
                rts
cw_pos          cmpd    TMP
                bls     cw_ok
                ldb     TMP+1
cw_ok           rts

; --- column sprites ------------------------------------------------------------------------------

; draw_cols: U = the sprite's descriptor; OBJ_X, OBJ_Y, FACING. Positions: X0 = x x 160 and
; YT = the padded column's top (y up) once, the rest by MUL (column x 160) and the descriptor's
; column height in beam units.
draw_cols       stu     SPR
                ldb     ,u
                clra
                std     TMP                     ; its width
                tst     FACING
                bne     dc_left
                ldd     #WL                     ; facing right: column c at x + c
                subd    OBJ_X
                bsr     clamp_w
                stb     C0
                ldd     #WR
                subd    OBJ_X
                bsr     clamp_w
                stb     C1
                bra     dc_have
dc_left         ldd     OBJ_X                   ; facing left: column c at x + width - 1 - c
                addd    TMP
                subd    #WR
                bsr     clamp_w
                stb     C0
                ldd     OBJ_X
                addd    TMP
                subd    #WL
                bsr     clamp_w
                stb     C1
dc_have         ldb     C0
                cmpb    C1
                lbhs    dc_done                 ; (none in the window)
                ldd     OBJ_X
                jsr     mul160
                std     X0
                ldd     OBJ_Y
                subd    #COL_PAD
                jsr     mul160
                jsr     negd
                std     YT
                ; the start: half a pixel before the first column drawn
                tst     FACING
                bne     dc_sx_l
                lda     C0
                ldb     #160
                mul
                addd    X0
                subd    #80
                bra     dc_sx
dc_sx_l         lda     ,u                      ; (width - 1 - C0) x 160 + 80
                deca
                suba    C0
                ldb     #160
                mul
                addd    X0
                addd    #80
dc_sx           std     TGT_X
                ldb     C0                      ; at the top, or the bottom if the first
                lsrb                            ; column drawn goes up
                ldd     YT
                bcc     dc_sy
                subd    13,u
dc_sy           std     TGT_Y
                jsr     move_start              ; the move under way, meanwhile...
                ldu     SPR                     ; its data, from the first column drawn
                lda     C0
                ldb     1,u
                mul
                addd    2,u
                std     COLS
                lda     C1
                suba    C0
                inca
                sta     COUNT
                ldb     C0                      ; its routine: down or up, right or left
                andb    #1
                aslb
                tst     FACING
                beq     dc_r
                addb    #4
dc_r            addb    #4
                stb     ROUTINE
                jsr     move_finish
                ldu     SPR
                ldx     COLS
                ldb     ROUTINE
                jsr     [b,u]
                ; where the beam ends: the last column's middle, at its bottom or top
                ldu     SPR
                tst     FACING
                bne     dc_ex_l
                lda     C1
                deca
                ldb     #160
                mul
                addd    X0
                addd    #80
                bra     dc_ex
dc_ex_l         lda     ,u                      ; (width - C1) x 160 + 80
                suba    C1
                ldb     #160
                mul
                addd    X0
                addd    #80
dc_ex           std     BEAM_X
                ldb     C1
                lsrb                            ; (C1 odd: the last column went down)
                ldd     YT
                bcc     dc_ey
                subd    13,u
dc_ey           std     BEAM_Y
dc_done         rts

; --- drifting rows (keys, the yoyo) --------------------------------------------------------------

; draw_rows: U = the descriptor; OBJ_X, OBJ_Y. Partly off the window, drawn whole (the part
; outside is past the screen's edge); wholly off, not drawn.
draw_rows       stu     SPR
                ldd     OBJ_X
                cmpd    #WR
                lbge    dr_done
                ldb     ,u
                clra
                addd    OBJ_X
                cmpd    #WL
                lble    dr_done
                ldd     OBJ_X
                jsr     mul160
                std     TGT_X
                ldd     OBJ_Y
                jsr     mul160
                jsr     negd
                std     TGT_Y
                jsr     move_to
                ldu     SPR
                ldx     5,u
                jsr     [7,u]
                ldu     SPR                     ; it ends at the left (rows even) or right
                ldd     TGT_X
                std     BEAM_X
                lda     2,u
                lsra
                bcc     dr_ey
                lda     1,u                     ; + bytes x 8 pixels x 160
                ldb     #5
                mul
                tfr     b,a
                clrb
                addd    BEAM_X
                std     BEAM_X
dr_ey           ldd     TGT_Y                   ; and as far down as it drifted
                subd    3,u
                std     BEAM_Y
dr_done         rts

; --- strips (platforms) --------------------------------------------------------------------------

; draw_strip: U = the descriptor; OBJ_X (the strip's left end), OBJ_Y (its top row). Clipped to
; the window by the pixel: the bytes in it, the first and last masked.
draw_strip      stu     SPR
                ldb     ,u
                clra
                std     TMP                     ; bytes a row
                ldd     #WL                     ; B0 = (WL - x) / 8, rounded down, 0..bytes
                subd    OBJ_X
                jsr     asr3
                jsr     clamp_w
                stb     B0
                ldd     #WR                     ; B1 = (WR - x) / 8, rounded up, 0..bytes
                subd    OBJ_X
                addd    #7
                jsr     asr3
                jsr     clamp_w
                stb     B1
                subb    B0
                lbls    ds_done
                stb     STRIP_N
                ; k0 = pixels of byte B0 left of the window: (WL - x) - 8 x B0, 0..7
                ldb     B0
                clra
                jsr     asl3
                std     TMP2
                ldd     #WL
                subd    OBJ_X
                subd    TMP2
                jsr     clamp07
                lda     #$FF
                stb     TMP2
                ldb     #$FF
ds_k0           tst     TMP2
                beq     ds_k0d
                lsra
                aslb
                dec     TMP2
                bra     ds_k0
ds_k0d          sta     M0F                     ; row 0's first byte: the left pixels off
                stb     M1L                     ; row 1's last (reversed)
                ; k1 = pixels of byte B1-1 right of the window: x + 8 x B1 - WR, 0..7
                ldb     B1
                clra
                jsr     asl3
                addd    OBJ_X
                subd    #WR
                jsr     clamp07
                lda     #$FF
                stb     TMP2
                ldb     #$FF
ds_k1           tst     TMP2
                beq     ds_k1d
                lsra
                aslb
                dec     TMP2
                bra     ds_k1
ds_k1d          stb     M0L                     ; row 0's last byte
                sta     M1F                     ; row 1's first
                lda     STRIP_N
                cmpa    #1
                bne     ds_two
                lda     M0F                     ; one byte: both masks on it; and a second
                anda    M0L                     ; byte, masked out, as the routine needs 2
                sta     M0F
                clr     M0L
                lda     M1L
                anda    M1F
                sta     M1L
                clr     M1F
                lda     #2
                sta     STRIP_N
ds_two          ldb     B0                      ; the start: byte B0's left end, row 0
                clra
                jsr     asl3
                addd    OBJ_X
                jsr     mul160
                std     TGT_X
                ldd     OBJ_Y
                jsr     mul160
                addd    #80
                jsr     negd
                std     TGT_Y
                jsr     move_to
                ldu     SPR
                ldb     ,u                      ; row 1 (reversed): from byte bytes - B0 - n
                subb    B0
                subb    STRIP_N
                sex
                addd    3,u
                std     ROW1
                ldb     B0
                clra
                addd    1,u
                tfr     d,x
                jsr     strip_m
                ldd     TGT_X                   ; it ends at the left, a pixel lower
                std     BEAM_X
                ldd     TGT_Y
                subd    #160
                std     BEAM_Y
ds_done         rts

asr3            asra
                rorb
                asra
                rorb
                asra
                rorb
                rts

asl3            aslb
                rola
                aslb
                rola
                aslb
                rola
                rts

; clamp07: D -> B = D clamped to 0..7
clamp07         tsta
                bmi     c07_0
                bne     c07_7
                cmpb    #7
                bls     c07_ok
c07_7           ldb     #7
c07_ok          rts
c07_0           clrb
                rts

                include "vlist_d_routine.asm"
                include "m1_rt_engine.asm"
                include "m1_rt_data.asm"
