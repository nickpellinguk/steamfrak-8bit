; Vectors and raster together: Trogg and the Scrubbly as vectors (vlist_d) with Trogg's head and
; the Scrubbly's eyes as raster patches; Trogg and the Scrubbly wholly as raster columns, from
; the BBC sprites; and a row of ledges as two raster lines, all from
; vectrex/tools/raster_test.py (raster_test_data.asm). The screen is 256 BBC pixels tall (a
; pixel = 160 beam units, ~1.26 x 127).
;
; asm6809 -B -o raster_test.bin raster_test.asm

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

PIXEL           equ     160                     ; beam units a BBC pixel
; where things are, in pixels from the middle of the screen (x right, y up); Moveto_d moves
; 127 units a step at scale $7F
TROGG_X         equ     -78                     ; vectors, with a raster head
TROGG_Y         equ     -10
TROGGR_X        equ     -40                     ; all raster (columns)
SCRUB_X         equ     12                      ; vectors, with raster eyes
SCRUB_Y         equ     -10
SCRUBR_X        equ     62                      ; all raster (columns)
LEDGE_X         equ     -96
LEDGE_Y         equ     -10

                org     0
                fcc     "g GCE 2026"
                fcb     $80
                fdb     $FD0D
                fcb     $F8,$50,$20,-$56
                fcc     "FRAK RASTER"
                fcb     $80
                fcb     0

main
                jsr     Wait_Recal
                lda     #$7F
                jsr     Intensity_a

                ; Trogg
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #((TROGG_Y*PIXEL/127)&$FF)*256+((TROGG_X*PIXEL/127)&$FF)
                jsr     Moveto_d
                ldx     #trogg_body
                jsr     vlist_d
                jsr     trogg_head

                ; the Scrubbly
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #((SCRUB_Y*PIXEL/127)&$FF)*256+((SCRUB_X*PIXEL/127)&$FF)
                jsr     Moveto_d
                ldx     #scrub_body
                jsr     vlist_d
                jsr     scrub_eyes

                ; Trogg, all raster
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #((TROGG_Y*PIXEL/127)&$FF)*256+((TROGGR_X*PIXEL/127)&$FF)
                jsr     Moveto_d
                ldx     #trogg_raster_start
                jsr     vlist_d
                jsr     trogg_raster

                ; the Scrubbly, all raster
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #((SCRUB_Y*PIXEL/127)&$FF)*256+((SCRUBR_X*PIXEL/127)&$FF)
                jsr     Moveto_d
                ldx     #scrub_raster_start
                jsr     vlist_d
                jsr     scrub_raster

                ; the ledges: the first row's left end half a pixel below their tops
                jsr     Reset0Ref
                lda     #$7F
                sta     <VIA_t1_cnt_lo
                ldd     #(((LEDGE_Y*PIXEL-PIXEL/2)/127)&$FF)*256+((LEDGE_X*PIXEL/127)&$FF)
                jsr     Moveto_d
                jsr     ledges

                jmp     main

                include "vlist_d_routine.asm"
                include "raster_test_data.asm"
