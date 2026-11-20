; made by vectrex/tools/vlist_d_short.py 0 (POLL_K = 0)

; the blocks for scales 1-27, by scale
                fdb     vs_fixed_1              ; scale 1: fixed delay
                fdb     vs_fixed_2              ; scale 2: fixed delay
                fdb     vs_fixed_3              ; scale 3: fixed delay
                fdb     vs_fixed_4              ; scale 4: fixed delay
                fdb     vs_fixed_5              ; scale 5: fixed delay
                fdb     vs_fixed_6              ; scale 6: fixed delay
                fdb     vs_fixed_7              ; scale 7: fixed delay
                fdb     vs_fixed_8              ; scale 8: fixed delay
                fdb     vs_fixed_9              ; scale 9: fixed delay
                fdb     vs_fixed_10             ; scale 10: fixed delay
                fdb     vs_poll_0               ; scale 11: polling
                fdb     vs_fixed_12             ; scale 12: fixed delay
                fdb     vs_poll_2               ; scale 13: polling
                fdb     vs_poll_3               ; scale 14: polling
                fdb     vs_poll_4               ; scale 15: polling
                fdb     vs_poll_5               ; scale 16: polling
                fdb     vs_poll_6               ; scale 17: polling
                fdb     vs_poll_0               ; scale 18: polling
                fdb     vs_poll_8               ; scale 19: polling
                fdb     vs_poll_2               ; scale 20: polling
                fdb     vs_poll_3               ; scale 21: polling
                fdb     vs_poll_4               ; scale 22: polling
                fdb     vs_poll_5               ; scale 23: polling
                fdb     vs_poll_6               ; scale 24: polling
                fdb     vs_poll_0               ; scale 25: polling
                fdb     vs_poll_8               ; scale 26: polling
                fdb     vs_poll_2               ; scale 27: polling
vs_table_end

vs_fixed_1
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4      spot on (starts at 7)
                clr     <VIA_shift_reg          ; spot off (starts at 11 = scale + 7): scale 1 is drawn as 4
                lbra    vs_next                 

vs_fixed_2
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4      spot on (starts at 7)
                clr     <VIA_shift_reg          ; spot off (starts at 11 = scale + 7): scale 2 is drawn as 4
                lbra    vs_next                 

vs_fixed_3
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4      spot on (starts at 7)
                clr     <VIA_shift_reg          ; spot off (starts at 11 = scale + 7): scale 3 is drawn as 4
                lbra    vs_next                 

vs_fixed_4
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4      spot on (starts at 7)
                clr     <VIA_shift_reg          ; spot off (starts at 11 = scale + 7)
                lbra    vs_next                 

vs_fixed_5
                nop                             ; 2   5
                nop                             ; 2   7
                stb     $D000+VIA_shift_reg     ; 5      spot on (starts at 7)
                clr     <VIA_shift_reg          ; spot off (starts at 12 = scale + 7)
                lbra    vs_next                 

vs_fixed_6
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4      spot on (starts at 7)
                nop                             ; 2
                clr     <VIA_shift_reg          ; spot off (starts at 13 = scale + 7)
                lbra    vs_next                 

vs_fixed_7
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4      spot on (starts at 7)
                brn     *                       ; 3
                clr     <VIA_shift_reg          ; spot off (starts at 14 = scale + 7)
                lbra    vs_next                 

vs_fixed_8
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4      spot on (starts at 7)
                nop                             ; 2
                nop                             ; 2
                clr     <VIA_shift_reg          ; spot off (starts at 15 = scale + 7)
                lbra    vs_next                 

vs_fixed_9
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4      spot on (starts at 7)
                brn     *                       ; 3
                nop                             ; 2
                clr     <VIA_shift_reg          ; spot off (starts at 16 = scale + 7)
                lbra    vs_next                 

vs_fixed_10
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4      spot on (starts at 7)
                nop                             ; 2
                nop                             ; 2
                nop                             ; 2
                clr     <VIA_shift_reg          ; spot off (starts at 17 = scale + 7)
                lbra    vs_next                 

vs_fixed_12
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4      spot on (starts at 7)
                nop                             ; 2
                nop                             ; 2
                nop                             ; 2
                nop                             ; 2
                clr     <VIA_shift_reg          ; spot off (starts at 19 = scale + 7)
                lbra    vs_next                 

; scales 11, 18, 25
vs_poll_0
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4  11  spot on (starts at 7)
vs_poll_0_loop
                bita    <$0D                    ; 4      reads start at 11 + 7n
                beq     vs_poll_0_loop          ; 3
                clr     <VIA_shift_reg          ; spot off
                lbra    vs_next                 

; scales 13, 20, 27
vs_poll_2
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4  11  spot on (starts at 7)
                nop                             ; 2
vs_poll_2_loop
                bita    <$0D                    ; 4      reads start at 13 + 7n
                beq     vs_poll_2_loop          ; 3
                clr     <VIA_shift_reg          ; spot off
                lbra    vs_next                 

; scales 14, 21
vs_poll_3
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4  11  spot on (starts at 7)
                brn     *                       ; 3
vs_poll_3_loop
                bita    <$0D                    ; 4      reads start at 14 + 7n
                beq     vs_poll_3_loop          ; 3
                clr     <VIA_shift_reg          ; spot off
                lbra    vs_next                 

; scales 15, 22
vs_poll_4
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4  11  spot on (starts at 7)
                nop                             ; 2
                nop                             ; 2
vs_poll_4_loop
                bita    <$0D                    ; 4      reads start at 15 + 7n
                beq     vs_poll_4_loop          ; 3
                clr     <VIA_shift_reg          ; spot off
                lbra    vs_next                 

; scales 16, 23
vs_poll_5
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4  11  spot on (starts at 7)
                brn     *                       ; 3
                nop                             ; 2
vs_poll_5_loop
                bita    <$0D                    ; 4      reads start at 16 + 7n
                beq     vs_poll_5_loop          ; 3
                clr     <VIA_shift_reg          ; spot off
                lbra    vs_next                 

; scales 17, 24
vs_poll_6
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4  11  spot on (starts at 7)
                nop                             ; 2
                nop                             ; 2
                nop                             ; 2
vs_poll_6_loop
                bita    <$0D                    ; 4      reads start at 17 + 7n
                beq     vs_poll_6_loop          ; 3
                clr     <VIA_shift_reg          ; spot off
                lbra    vs_next                 

; scales 19, 26
vs_poll_8
                nop                             ; 2   5
                nop                             ; 2   7
                stb     <VIA_shift_reg          ; 4  11  spot on (starts at 7)
                nop                             ; 2
                nop                             ; 2
                nop                             ; 2
                nop                             ; 2
vs_poll_8_loop
                bita    <$0D                    ; 4      reads start at 19 + 7n
                beq     vs_poll_8_loop          ; 3
                clr     <VIA_shift_reg          ; spot off
                lbra    vs_next                 

