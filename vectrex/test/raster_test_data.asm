; made by vectrex/tools/raster_test.py

; Trogg (sTrogg_wr_Beeb frame 0): body, then a move to the head's top left (6 polylines)
trogg_body
                fcb     29,123,-1,$00
                fcb     13,-21,-61,$FF
                fcb     17,-57,-31,$FF
                fcb     8,-53,39,$FF
                fcb     7,-68,0,$FF
                fcb     5,-43,-43,$FF
                fcb     8,0,-67,$FF
                fcb     5,43,-42,$FF
                fcb     5,64,0,$FF
                fcb     6,44,44,$FF
                fcb     8,0,60,$FF
                fcb     5,-42,43,$FF
                fcb     8,6,-113,$00
                fcb     7,61,-8,$FF
                fcb     7,39,46,$FF
                fcb     9,65,0,$FF
                fcb     15,53,32,$FF
                fcb     14,27,57,$FF
                fcb     15,-53,32,$FF
                fcb     14,-61,-19,$FF
                fcb     16,0,-63,$FF
                fcb     6,-125,26,$00
                fcb     8,-47,40,$FF
                fcb     16,0,63,$FF
                fcb     14,34,54,$FF
                fcb     9,66,0,$FF
                fcb     17,53,-35,$FF
                fcb     14,58,-30,$FF
                fcb     7,-1,-61,$FF
                fcb     18,-95,80,$00
                fcb     15,65,1,$FF
                fcb     6,56,-38,$FF
                fcb     23,-108,-70,$00
                fcb     15,-46,47,$FF
                fcb     8,-58,21,$FF
                fcb     6,-57,-29,$FF
                fcb     18,0,62,$FF
                fcb     8,60,1,$FF
                fcb     7,-23,-61,$FF
                fcb     12,63,0,$FF
                fcb     9,53,-42,$FF
                fcb     7,-54,-114,$00
                fcb     20,-59,-26,$FF
                fcb     14,1,64,$FF
                fcb     4,65,0,$FF
                fcb     4,0,-67,$FF
                fcb     11,58,24,$FF
                fcb     35,125,-31,$00
                fcb     0,0

; Trogg's head, the black pixels: 9 rows of 24 pixels (3 bytes)
trogg_head
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 0, right: 00 3E 00
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$3E                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                stb     <VIA_port_b             ;  4 t = 48: ramp off (the beam stops at 61)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 60: spot off (shows at 62)
                lda     #-40                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                clr     <VIA_port_a             ;  6 X speed 0
                ldb     #$01                    ;  2 
                lda     #$81                    ;  2 
                stb     <VIA_port_b             ;  4 ramp on ...
                sta     <VIA_port_b             ;  4 ... for 4 cycles: a pixel down
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 1, left: 00 FF 00
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$FF                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                stb     <VIA_port_b             ;  4 t = 48: ramp off (the beam stops at 61)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 60: spot off (shows at 62)
                lda     #-40                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                clr     <VIA_port_a             ;  6 X speed 0
                ldb     #$01                    ;  2 
                lda     #$81                    ;  2 
                stb     <VIA_port_b             ;  4 ramp on ...
                sta     <VIA_port_b             ;  4 ... for 4 cycles: a pixel down
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 2, right: 03 F0 80
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$03                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$F0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$80                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                stb     <VIA_port_b             ;  4 t = 48: ramp off (the beam stops at 61)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 60: spot off (shows at 62)
                lda     #-40                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                clr     <VIA_port_a             ;  6 X speed 0
                ldb     #$01                    ;  2 
                lda     #$81                    ;  2 
                stb     <VIA_port_b             ;  4 ramp on ...
                sta     <VIA_port_b             ;  4 ... for 4 cycles: a pixel down
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 3, left: 1F 47 E0
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$1F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$47                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$E0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                stb     <VIA_port_b             ;  4 t = 48: ramp off (the beam stops at 61)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 60: spot off (shows at 62)
                lda     #-40                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                clr     <VIA_port_a             ;  6 X speed 0
                ldb     #$01                    ;  2 
                lda     #$81                    ;  2 
                stb     <VIA_port_b             ;  4 ramp on ...
                sta     <VIA_port_b             ;  4 ... for 4 cycles: a pixel down
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 4, right: 1F E2 08
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$1F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$E2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$08                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                stb     <VIA_port_b             ;  4 t = 48: ramp off (the beam stops at 61)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 60: spot off (shows at 62)
                lda     #-40                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                clr     <VIA_port_a             ;  6 X speed 0
                ldb     #$01                    ;  2 
                lda     #$81                    ;  2 
                stb     <VIA_port_b             ;  4 ramp on ...
                sta     <VIA_port_b             ;  4 ... for 4 cycles: a pixel down
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 5, left: 1F 87 FC
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$1F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$87                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$FC                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                stb     <VIA_port_b             ;  4 t = 48: ramp off (the beam stops at 61)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 60: spot off (shows at 62)
                lda     #-40                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                clr     <VIA_port_a             ;  6 X speed 0
                ldb     #$01                    ;  2 
                lda     #$81                    ;  2 
                stb     <VIA_port_b             ;  4 ramp on ...
                sta     <VIA_port_b             ;  4 ... for 4 cycles: a pixel down
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 6, right: 1F B7 80
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$1F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$B7                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$80                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                stb     <VIA_port_b             ;  4 t = 48: ramp off (the beam stops at 61)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 60: spot off (shows at 62)
                lda     #-40                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                clr     <VIA_port_a             ;  6 X speed 0
                ldb     #$01                    ;  2 
                lda     #$81                    ;  2 
                stb     <VIA_port_b             ;  4 ramp on ...
                sta     <VIA_port_b             ;  4 ... for 4 cycles: a pixel down
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 7, left: 00 9B 5C
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$9B                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$5C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                stb     <VIA_port_b             ;  4 t = 48: ramp off (the beam stops at 61)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 60: spot off (shows at 62)
                lda     #-40                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                clr     <VIA_port_a             ;  6 X speed 0
                ldb     #$01                    ;  2 
                lda     #$81                    ;  2 
                stb     <VIA_port_b             ;  4 ramp on ...
                sta     <VIA_port_b             ;  4 ... for 4 cycles: a pixel down
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 8, right: E1 6E 00
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$E1                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$6E                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                stb     <VIA_port_b             ;  4 t = 48: ramp off (the beam stops at 61)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 60: spot off (shows at 62)
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

; The Scrubbly: body, then a move to the eyes' top left (7 polylines)
scrub_body
                fcb     47,125,-26,$00
                fcb     8,37,50,$FF
                fcb     16,-20,61,$FF
                fcb     14,38,52,$FF
                fcb     5,-20,65,$FF
                fcb     4,-54,26,$FF
                fcb     11,19,-126,$00
                fcb     2,3,53,$FF
                fcb     9,-59,12,$FF
                fcb     34,-35,53,$FF
                fcb     12,10,-61,$FF
                fcb     34,-50,41,$FF
                fcb     7,-62,-1,$FF
                fcb     12,44,-45,$FF
                fcb     15,-64,0,$FF
                fcb     8,-40,54,$FF
                fcb     12,-62,9,$FF
                fcb     11,48,-39,$FF
                fcb     15,-64,-14,$FF
                fcb     11,-21,-58,$FF
                fcb     10,-9,-65,$FF
                fcb     20,0,-64,$FF
                fcb     19,17,-62,$FF
                fcb     14,61,-15,$FF
                fcb     11,-39,-48,$FF
                fcb     12,63,8,$FF
                fcb     9,47,48,$FF
                fcb     15,64,0,$FF
                fcb     11,-49,-39,$FF
                fcb     9,62,0,$FF
                fcb     32,46,43,$FF
                fcb     14,-15,-60,$FF
                fcb     32,37,53,$FF
                fcb     5,19,67,$FF
                fcb     29,-114,-52,$00
                fcb     47,0,64,$FF
                fcb     2,-1,-110,$00
                fcb     23,-62,-18,$FF
                fcb     23,62,-15,$FF
                fcb     15,0,-120,$00
                fcb     24,-62,13,$FF
                fcb     24,63,16,$FF
                fcb     17,-114,-60,$00
                fcb     4,-55,-27,$FF
                fcb     8,-53,40,$FF
                fcb     12,0,62,$FF
                fcb     7,60,16,$FF
                fcb     8,-13,120,$00
                fcb     6,-56,26,$FF
                fcb     13,0,63,$FF
                fcb     8,55,25,$FF
                fcb     4,54,-27,$FF
                fcb     34,100,-76,$00
                fcb     0,0

; the Scrubbly's eyes, the yellow pixels: 6 rows of 16 pixels (2 bytes)
scrub_eyes
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 0, right: 70 70
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$70                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$70                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                stb     <VIA_port_b             ;  4 t = 32: ramp off (the beam stops at 45)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 44: spot off (shows at 46)
                lda     #-40                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                clr     <VIA_port_a             ;  6 X speed 0
                ldb     #$01                    ;  2 
                lda     #$81                    ;  2 
                stb     <VIA_port_b             ;  4 ramp on ...
                sta     <VIA_port_b             ;  4 ... for 4 cycles: a pixel down
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 1, left: 1F 1F
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$1F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$1F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                stb     <VIA_port_b             ;  4 t = 32: ramp off (the beam stops at 45)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 44: spot off (shows at 46)
                lda     #-40                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                clr     <VIA_port_a             ;  6 X speed 0
                ldb     #$01                    ;  2 
                lda     #$81                    ;  2 
                stb     <VIA_port_b             ;  4 ramp on ...
                sta     <VIA_port_b             ;  4 ... for 4 cycles: a pixel down
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 2, right: C8 9C
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$C8                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$9C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                stb     <VIA_port_b             ;  4 t = 32: ramp off (the beam stops at 45)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 44: spot off (shows at 46)
                lda     #-40                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                clr     <VIA_port_a             ;  6 X speed 0
                ldb     #$01                    ;  2 
                lda     #$81                    ;  2 
                stb     <VIA_port_b             ;  4 ramp on ...
                sta     <VIA_port_b             ;  4 ... for 4 cycles: a pixel down
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 3, left: 30 01
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$30                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$01                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                stb     <VIA_port_b             ;  4 t = 32: ramp off (the beam stops at 45)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 44: spot off (shows at 46)
                lda     #-40                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                clr     <VIA_port_a             ;  6 X speed 0
                ldb     #$01                    ;  2 
                lda     #$81                    ;  2 
                stb     <VIA_port_b             ;  4 ramp on ...
                sta     <VIA_port_b             ;  4 ... for 4 cycles: a pixel down
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 4, right: 80 0C
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$80                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$0C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                stb     <VIA_port_b             ;  4 t = 32: ramp off (the beam stops at 45)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 44: spot off (shows at 46)
                lda     #-40                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                clr     <VIA_port_a             ;  6 X speed 0
                ldb     #$01                    ;  2 
                lda     #$81                    ;  2 
                stb     <VIA_port_b             ;  4 ramp on ...
                sta     <VIA_port_b             ;  4 ... for 4 cycles: a pixel down
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 5, left: 10 01
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$10                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$01                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                stb     <VIA_port_b             ;  4 t = 32: ramp off (the beam stops at 45)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 44: spot off (shows at 46)
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

; three ledges, the top two rows of sLedge1_Beeb repeated: 2 rows of 192 pixels (24 bytes)
ledges
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 0, right: 6F 4D 6F 4D 6F 4D 6F 4D 00 00 6F 4D 6F 4D 6F 4D 00 00 6F 4D 6F 4D 6F 4D
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$6F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$4D                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$6F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$4D                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$6F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$4D                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                lda     #$6F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108
                lda     #$4D                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 124
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 156
                lda     #$6F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172
                lda     #$4D                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 188
                lda     #$6F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204
                lda     #$4D                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 220
                lda     #$6F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236
                lda     #$4D                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 252
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 284
                lda     #$6F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300
                lda     #$4D                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 316
                lda     #$6F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332
                lda     #$4D                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 348
                lda     #$6F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364
                lda     #$4D                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 380
                stb     <VIA_port_b             ;  4 t = 384: ramp off (the beam stops at 397)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 396: spot off (shows at 398)
                lda     #-40                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                clr     <VIA_port_a             ;  6 X speed 0
                ldb     #$01                    ;  2 
                lda     #$81                    ;  2 
                stb     <VIA_port_b             ;  4 ramp on ...
                sta     <VIA_port_b             ;  4 ... for 4 cycles: a pixel down
                clr     <VIA_port_a             ;  6 DAC = 0
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
; row 1, left: B2 E2 B2 E2 B2 E2 00 00 B2 E2 B2 E2 B2 E2 00 00 B2 E2 B2 E2 B2 E2 B2 E2
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 X speed
                ldb     #$01                    ;  2 
                stb     <VIA_port_b             ;  4 t = 0: ramp on (the beam moves from 13)
                ldb     #$81                    ;  2 (for the ramp off)
                lda     #$B2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$E2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$B2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$E2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$B2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$E2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 124
                lda     #$B2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140
                lda     #$E2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 156
                lda     #$B2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172
                lda     #$E2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 188
                lda     #$B2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204
                lda     #$E2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 220
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 252
                lda     #$B2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268
                lda     #$E2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 284
                lda     #$B2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300
                lda     #$E2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 316
                lda     #$B2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332
                lda     #$E2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 348
                lda     #$B2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364
                lda     #$E2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 380
                stb     <VIA_port_b             ;  4 t = 384: ramp off (the beam stops at 397)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 396: spot off (shows at 398)
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

; sTrogg_wr_Beeb as columns: the move to the first column
trogg_raster_start
                fcb     47,119,-46,$00
                fcb     0,0

; sTrogg_wr_Beeb as columns, # lit: 26 columns of 40 pixels (5 bytes)
trogg_raster
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
; column 0, down: 00 00 0F E0 00
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$0F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$E0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 1, up: 00 0E 98 00 00
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$0E                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$98                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 2, down: 00 01 F2 F0 00
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$01                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$F2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$F0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 3, up: 00 0F 40 F0 00
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$0F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$40                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$F0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 4, down: 00 18 0A F0 00
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$18                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$0A                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$F0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 5, up: 00 0F FC 0C 00
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$0F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$FC                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$0C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 6, down: 00 20 E3 E0 70
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$20                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$E3                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$E0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$70                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 7, up: 0B 87 85 C6 80
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$0B                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$87                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$85                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$C6                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$80                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 8, down: 03 C2 20 F7 10
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$03                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$C2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$20                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$F7                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$10                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 9, up: 08 3A 04 43 C0
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$08                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$3A                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$04                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$43                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$C0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 10, down: 07 86 20 48 50
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$07                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$86                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$20                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$48                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$50                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 11, up: 0B A2 06 23 F0
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$0B                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$A2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$06                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$23                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$F0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 12, down: 0F BF C0 43 F0
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$0F                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$BF                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$C0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$43                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$F0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 13, up: 0B 02 00 F3 F8
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$0B                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$02                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$F3                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$F8                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 14, down: 1F 60 00 60 10
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$1F                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$60                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$60                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$10                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 15, up: 08 1F 00 3D FC
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$08                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$1F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$3D                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$FC                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 16, down: 38 C7 00 8F D0
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$38                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$C7                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$8F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$D0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 17, up: 0A 01 83 86 0C
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$0A                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$01                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$83                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$86                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$0C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 18, down: 30 B8 63 00 90
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$30                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$B8                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$63                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$90                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 19, up: 0F 00 7F F5 6C
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$0F                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$7F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$F5                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$6C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 20, down: 11 C0 00 00 00
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$11                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$C0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 21, up: 00 00 00 01 B0
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$01                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$B0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 22, down: 05 00 00 00 00
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$05                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 23, up: 00 00 00 00 A0
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$A0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 24, down: 05 00 00 00 00
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$05                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
; column 25, up: 00 00 00 00 E0
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$E0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                stb     <VIA_port_b             ;  4 t = 80: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 92: spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

; sScrubbly_Beeb as columns: the move to the first column
scrub_raster_start
                fcb     58,119,-46,$00
                fcb     0,0

; sScrubbly_Beeb as columns, # lit: 33 columns of 48 pixels (6 bytes)
scrub_raster
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
; column 0, down: 00 00 03 F0 FC 00
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$03                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$F0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$FC                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 1, up: 00 4F C2 F0 00 00
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$4F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$C2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$F0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 2, down: 00 01 1C C7 20 00
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$01                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$1C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$C7                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$20                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 3, up: 00 1E 3F 9C C0 00
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$1E                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$3F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$9C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$C0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 4, down: 00 06 70 00 1E 00
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$06                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$70                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$1E                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 5, up: 00 C0 00 03 70 00
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$C0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$03                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$70                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 6, down: 00 1F 80 00 01 E0
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$1F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$80                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$01                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$E0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 7, up: 0D 80 18 00 D8 E0
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$0D                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$80                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$18                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$D8                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$E0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 8, down: 0D 32 1F 0F 00 90
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$0D                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$32                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$1F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$0F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$90                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 9, up: 09 07 89 8C 0C 58
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$09                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$07                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$89                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$8C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$0C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$58                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 10, down: 12 60 60 90 38 D0
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$12                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$60                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$60                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$90                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$38                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$D0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 11, up: 0B 07 89 E2 02 28
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$0B                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$07                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$89                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$E2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$02                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$28                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 12, down: 16 C0 4F 8F 00 70
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$16                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$C0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$4F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$8F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$70                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 13, up: 06 00 19 F2 01 CC
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$06                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$19                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$F2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$01                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$CC                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 14, down: 3B 80 67 08 00 40
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$3B                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$80                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$67                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$08                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$40                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 15, up: 02 00 08 7C 00 14
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$02                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$08                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$7C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$14                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 16, down: 20 00 00 08 00 40
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$20                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$08                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$40                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 17, up: 02 00 08 7C 00 1C
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$02                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$08                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$7C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$1C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 18, down: 19 80 67 08 00 40
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$19                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$80                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$67                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$08                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$40                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 19, up: 06 00 19 F2 01 CC
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$06                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$19                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$F2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$01                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$CC                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 20, down: 36 C0 4F 8F 00 70
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$36                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$C0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$4F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$8F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$70                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 21, up: 0B 07 89 E2 02 24
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$0B                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$07                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$89                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$E2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$02                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$24                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 22, down: 2C 60 60 90 38 D0
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$2C                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$60                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$60                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$90                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$38                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$D0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 23, up: 09 07 89 8C 0C 64
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$09                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$07                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$89                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$8C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$0C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$64                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 24, down: 32 32 1F 0F 00 90
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$32                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$32                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$1F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$0F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$90                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 25, up: 0D 00 18 00 D8 78
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$0D                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$18                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$D8                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$78                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 26, down: 00 1F 80 00 01 E0
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$1F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$80                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$01                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$E0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 27, up: 00 C0 00 03 70 00
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$C0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$03                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$70                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 28, down: 00 06 70 00 1E 00
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$06                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$70                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$1E                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 29, up: 00 1E 3F 9C C0 00
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$1E                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$3F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$9C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$C0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 30, down: 00 01 1C C7 20 00
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$01                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$1C                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$C7                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$20                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 31, up: 00 4F C2 F0 00 00
                lda     #80                     ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$4F                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$C2                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$F0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
; column 32, down: 00 00 03 F0 FC 00
                lda     #-80                    ;  2 
                sta     <VIA_port_a             ;  4 DAC
                lda     #$80                    ;  2 
                sta     <VIA_port_b             ;  4 mux on: to Y (ramp off)
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 (settling)
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off, ramp off
                lda     #40                     ;  2 
                sta     <VIA_port_a             ;  4 X speed: the slide across
                ldb     #$01                    ;  2 
                lda     #$00                    ;  2 (the first byte)
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (after 4 cycles: a pixel across)
                ldb     #$81                    ;  2 (for the ramp off)
                sta     <VIA_shift_reg          ;  4 t = 12
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28
                lda     #$03                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44
                lda     #$F0                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60
                lda     #$FC                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76
                lda     #$00                    ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92
                stb     <VIA_port_b             ;  4 t = 96: ramp off
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                clr     <VIA_shift_reg          ;  6 t = 108: spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

