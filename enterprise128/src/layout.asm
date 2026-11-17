; The memory map (see ../PLAN.md, "Memory"): which segment holds what, and
; where, with ASSERTs that it all fits. tools/memmap.py measures the sizes
; (src/gen/sizes.asm) and prints the map.
;
; The Z80 sees page 0 (#0000-#3FFF) as the program's own segment, #F8; page 1
; (#4000-#7FFF) as the window, where the program's other segments are paged in,
; as the CPC's extra banks are at #4000; and pages 2 and 3 (#8000-#FFFF) as the
; screen buffer being drawn (screen.asm).

        INCLUDE "gen/sizes.asm"

SEG_GFX    = #F9                    ; sprites and code tables (the CPC version's bank 0)
SEG_LOGIC  = #FA                    ; the game logic (its bank 2)
SEG_JIT    = #FE                    ; the compiled meanie (JIT_ORG, below), in #FE's spare
SEG_CACHE  = #FB                    ; the background cache and slow save areas (its bank 3),
                                    ; or the front end, unpacked, while the menus are up
                                    ; (SEG_LOW, SEG_VIDEO and SEG_TOP: machine.asm)

; In SEG_TOP (#FF), in the window: the levels, packed (at #4000, as in the CPC
; version's base RAM), the front end, packed, and the line parameter tables
LEVELS_ORG       = #4000
FRONT_PACKED_ORG = #7000
        ASSERT LEVELS_ORG + LEVELS_SIZE <= FRONT_PACKED_ORG
        ASSERT FRONT_PACKED_ORG + FRONT_PACKED_SIZE <= LPT_WIN

; The front end runs in SEG_CACHE, from #4000, unpacked there when the menus come
; up (the level's background is built again when the next level starts); its
; records stay in the low RAM
FRONT_ORG = #4000
        ASSERT FRONT_ORG + FRONT_SIZE <= #6A00              ; (below the slow save areas)

; In segment #FE, after buffer 1's ring and its mirror (Nick #A1A0 on): the level
; loader, which runs there with #FE paged in at page 3, and the compiled meanie,
; in the window with #FE paged in there
FE_SPARE   = RING1_NICK + RING_SIZE + LINE_BYTES * 2 - #8000   ; (its offset in #FE)
LOADER_RUN = #C000 + FE_SPARE
JIT_ORG    = #7180                  ; (after the loader: frak.asm ASSERTs it is)
jit_tmp    = #8000                  ; (where jit_build decodes the image: buffer 0's ring, or,
JIT_TMP_SIZE = 2560                 ; while a level loads, the screen being blank, #FC)
        ASSERT FE_SPARE == #21A0
        ASSERT JIT_ORG + JIT_MAX <= #8000

; The low RAM: the CPC version's code and tables, moved up from #0040 to #0100,
; and the records, below the stack (#3F00)
        ASSERT #0100 + CPC_LOW_SIZE + RECORDS_SIZE <= #3F00
        ASSERT LOGIC_SIZE <= #4000
        ASSERT GFX_SIZE <= #4000
