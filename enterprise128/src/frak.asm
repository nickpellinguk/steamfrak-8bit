; Steam Frak for the Enterprise 128 - assembled with RASM (see ../build.sh)
;
; Phase 1 (see ../PLAN.md): the machine layer (src/machine.asm: paging,
; interrupts, the keyboard) and the screen (src/screen.asm: Nick's line
; parameter tables, the two ring buffers and their mirrors). The program loads
; (as an EXOS type 5 file, at #0100), asks EXOS for every RAM segment it will give
; out, takes the machine over, and then does what the test harness (tools/emu)
; asks: it shows each buffer from the scroll position and palette the harness
; pokes (t_apply), and flips between them every flip_rate frames.
;
; From here on, this grows into the CPC version's frak.asm, routine for routine
; (../cpc6128/src/frak.asm).

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
        call bank_test
        xor a : out (NICK_BORDER),a
        call lpt_init
        xor a : ld (front),a : call show_lpt
        ld a,1 : call screen_select             ; (drawing into the other)
        ld a,(vsyncs) : ld (last_vsync),a
        ld a,#A5 : ld (ready),a                 ; (for the test harness)
        ei

main_loop
        ; new scroll positions and palettes from the test harness?
        ld a,(t_apply) : or a : jr z,.no_apply
        xor a : call lpt_set
        ld a,1 : call lpt_set
        xor a : ld (t_apply),a
        ld hl,(t_done) : inc hl : ld (t_done),hl
.no_apply
        ld a,(t_unpack) : or a : jr z,.no_unpack
        call t_unpack_cmd
        xor a : ld (t_unpack),a
        ld hl,(t_done) : inc hl : ld (t_done),hl
.no_unpack
        ; count a game tick for each vertical sync since the last time round
        ld a,(last_vsync) : ld b,a
        ld a,(vsyncs) : cp b : jr z,main_loop
        ld (last_vsync),a
        sub b : ld e,a : ld d,0
        ld hl,(ticks) : add hl,de : ld (ticks),hl
        ; show the other buffer every flip_rate frames (0: never)
        ld a,(flip_rate) : or a : jr z,main_loop
        ld hl,flip_count : dec (hl) : jr nz,main_loop
        ld (hl),a
        ld a,(front) : xor 1 : ld (flip_buf),a
        ld a,1 : ld (flip_pending),a
        jr main_loop

        INCLUDE "machine.asm"
        INCLUDE "screen.asm"
        INCLUDE "layout.asm"
        INCLUDE "unpack.asm"

; For the test harness: unpack the data packed at t_unpack_src (an address at page
; 3, with segment #FF paged in there) into segment t_unpack_seg, from #4000
t_unpack_cmd
        ld a,SEG_TOP : out (PAGE3),a
        ld a,(t_unpack_seg) : call bank_select
        ld hl,(t_unpack_src) : ld de,#4000
        call unpack
        ld (t_unpack_end),de
        ld a,SEG_TOP : call bank_select
        ld a,(back) : jp screen_select

; ------------------------------------------------------------------------------
; Variables
; ------------------------------------------------------------------------------
MAX_SEGS = 8
ready        db 0                   ; #A5 once the program has the machine
pages        defs 4, 0              ; the segments at pages 0-3 when EXOS started it
num_segs     db 0                   ; how many segments EXOS gave out ...
segs         defs MAX_SEGS, 0       ; ... and which
alloc_status db 0                   ; ... and why it stopped (EXOS's status: #7F a shared one)
vsyncs       db 0                   ; counted by irq
last_vsync   db 0
ticks        dw 0                   ; game ticks (a vertical sync each)
win_seg      db SEG_TOP             ; the segment in the window (page 1)
bank_errors  db 0                   ; bank_test's answer
bank_kept    defs 16, 0
keys         defs 10, 0             ; a bit set for each key down, by row
keys_changed db 0
front        db 0                   ; the buffer on show (0 or 1)
back         db 1                   ; the buffer paged in at pages 2 and 3
back_ring    dw RING1_Z80           ; ... and where its ring is
flip_pending db 0                   ; show flip_buf at the next vertical sync
flip_buf     db 0
scroll0      dw 0                   ; each buffer's scroll position (even, 0 to 20478)
scroll1      dw 0
pal0         db #49, #92, #DB, #FF, 0, 0, 0, 0      ; each buffer's palette
pal1         db #24, #6D, #B6, #12, 0, 0, 0, 0
ls_buf       db 0                   ; lpt_set's workings
ls_k         db 0
ls_base      dw 0
ls_ld1a      dw 0
ls_ld1b      dw 0
up_bits      db 0                   ; unpack's workings
up_dist      dw 0
; for the test harness
t_apply      db 0                   ; 1: set both buffers' LPBs from scroll0/1 and pal0/1
t_done       dw 0                   ; ... counted when done
t_unpack     db 0                   ; 1: unpack (see t_unpack_cmd) ...
t_unpack_src dw 0
t_unpack_seg db 0
t_unpack_end dw 0                   ; ... and where it ended
flip_rate    db 0                   ; flip the buffers every flip_rate frames (0: never)
flip_count   db 1
end_code

        ASSERT end_code <= #3F00    ; (the stack is from #3F00 to #3FFF)

        SAVE 'build/FRAK.COM',exos_header,end_code-exos_header
        PRINT "Code from ",{hex}start," to ",{hex}end_code
