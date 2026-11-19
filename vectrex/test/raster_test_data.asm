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

