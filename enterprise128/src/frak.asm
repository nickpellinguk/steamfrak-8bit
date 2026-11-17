; Steam Frak for the Enterprise 128 - assembled with RASM (see ../build.sh)
;
; Phase 0 (see ../PLAN.md): the program loads (as an EXOS type 5 file, at
; #0100), asks EXOS for every RAM segment it will give out (so the test harness
; can see what's free on a machine with EXDOS), takes the machine over from
; EXOS, and sets `ready` for the test harness.
;
; From phase 1 on, this grows into the CPC version's frak.asm, routine for
; routine (../cpc6128/src/frak.asm).

        BUILDZ80
        ORG #0100 - 16
; The EXOS header of a type 5 file (a new applications program): EXOS loads
; what follows it to #0100, in the segment at page 0, and jumps there
exos_header
        db 0, 5
        dw end_code - start
        defs 12, 0

start
        ; EXOS loaded this and called it, with EXOS still running. First, while
        ; EXOS can still say, which segments are paged in, and which it will give
        ; out (they're where the program's data will go, from phase 2)
        ld sp,stack_top
        ld c,PAGE0 : ld hl,pages
        ld b,4
.page   in a,(c) : ld (hl),a : inc hl : inc c
        djnz .page
        ld hl,segs : ld b,0
.alloc  push hl : push bc
        rst #30 : db EXOS_ALLOC_SEGMENT
        pop hl : ld b,h : pop hl                ; (B: the count so far)
        or a : jr nz,.alloc_done                ; (#7F: only a segment shared with EXOS)
        ld (hl),c : inc hl : inc b
        ld a,b : cp MAX_SEGS : jr c,.alloc
.alloc_done
        ld (alloc_status),a
        ld a,b : ld (num_segs),a
        ; then the machine is ours
        di
        call machine_init
        ld a,#A5 : ld (ready),a               ; (for the test harness)
.idle   jr .idle

        INCLUDE "machine.asm"

; ------------------------------------------------------------------------------
; Variables
; ------------------------------------------------------------------------------
MAX_SEGS = 8
ready        db 0                   ; #A5 once the program has the machine
pages        defs 4, 0              ; the segments at pages 0-3 when EXOS started it
num_segs     db 0                   ; how many segments EXOS gave out ...
segs         defs MAX_SEGS, 0       ; ... and which
alloc_status db 0                   ; ... and why it stopped (EXOS's status: #7F a shared one)
end_code

        defs 256, 0                 ; the stack, for now
stack_top
end_ram
        ASSERT end_ram <= #3F00

        SAVE 'build/FRAK.COM',exos_header,end_code-exos_header
        PRINT "Code from ",{hex}start," to ",{hex}end_code,", workspace to ",{hex}end_ram
