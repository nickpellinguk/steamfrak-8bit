; Steam Frak for the Enterprise 128 - assembled with RASM (see ../build.sh)
;
; Phase 3 (see ../PLAN.md): the machine layer (src/machine.asm: paging,
; interrupts, the keyboard), the screen (src/screen.asm: Nick's line parameter
; tables, the two ring buffers and their mirrors), the unpacker (src/unpack.asm)
; and the plotter (src/plot.asm). The program loads (as an EXOS type 5 file, at
; #0100), asks EXOS for every RAM segment it will give out, takes the machine
; over, and then does what the test harness (tools/emu) asks: it shows each
; buffer from the scroll position and palette the harness pokes (t_apply), and
; flips between them every flip_rate frames; and it runs the commands the
; harness pokes into t_cmd (the plotter's, as the CPC version's do: command).
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
        call make_lines
        xor a : out (NICK_BORDER),a
        call lpt_init
        xor a : ld (front),a : call show_lpt
        ld a,1 : call screen_select             ; (drawing into the other)
        ld a,(vsyncs) : ld (last_vsync),a
        ld a,#A5 : ld (ready),a                 ; (for the test harness)
        ei

main_loop
        ; a command from the test harness?
        ld a,(t_cmd) : or a : jr z,.no_cmd
        call command
        xor a : ld (t_cmd),a
        ld hl,(t_done) : inc hl : ld (t_done),hl
.no_cmd
        ; new scroll positions and palettes from the test harness?
        ld a,(t_apply) : or a : jr z,.no_apply
        call apply_both
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
        INCLUDE "plot.asm"
        INCLUDE "../../cpc6128/src/gen/images.asm"

; A command from the test harness (the CPC version's numbers; it has no mode 9)
command
        dec a : jp z,plot                       ; 1
        dec a : jp z,restore_saved              ; 2
        dec a : jp z,hline                      ; 3
        dec a : jr nz,.not4
        ld a,(t_arg) : jp jit_build             ; 4
.not4   dec a : jp z,plot_slow                  ; 5
        dec a : jp z,log_sprite                 ; 6
        dec a : jp z,log_line                   ; 7
        dec a : jp z,restore_log                ; 8
        dec a : dec a : jp z,log_sprite7        ; 10
        ret

; line_lo/line_hi[row] = row * 80: where ring row `row` starts in a ring
make_lines
        ld hl,0 : ld de,line_lo : ld bc,LINE_BYTES
.row    ld a,l : ld (de),a
        inc d : ld a,h : ld (de),a : dec d
        add hl,bc
        inc e : jr nz,.row
        ret

; Carry set if HL < DE, as signed numbers (HL, DE lost) (as the CPC version's, in level.asm)
signed_less
        ld a,h : xor #80 : ld h,a
        ld a,d : xor #80 : ld d,a
        or a : sbc hl,de
        ret

; For the test harness: set both buffers' playfield LPBs (from scroll0/1 and
; pal0/1) without ever writing the table on show: Nick reads an LPB's line count
; once, as it starts it, but the rest of the table as it goes, so rewriting the
; table it's drawing can make a frame the wrong length (a TV would roll). So the
; buffer not on show first; then show it (at the next vertical sync); then, once
; Nick has started that one's table (by the vertical sync after), the other.
; (The game only ever sets the table of the buffer it's drawing.)
apply_both
        ld a,(flip_pending) : or a : jr nz,apply_both   ; (no flip under way)
        ld a,(front) : xor 1 : push af : call lpt_set
        pop af : ld (flip_buf),a
        ld a,1 : ld (flip_pending),a
.wait   ld a,(flip_pending) : or a : jr nz,.wait        ; (shown at a vertical sync ...)
        call wait_vsync                                 ; (... and its table started)
        ld a,(front) : xor 1 : jp lpt_set

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
; the plotter's (as the CPC version's)
t_cmd       db 0                    ; a command from the test harness
t_arg       db 0
p_img       db 0
p_x         dw 0
p_y         dw 0
q_x         dw 0                    ; (hline's other end)
p_mode      db 0
p_sbank     db 0                    ; PM_SAVEONLY: the segment the save area is in
clip_l      db 0                    ; the window, in level coordinates
clip_r      db 80
clip_t      dw 0
clip_h      db 0
sbase       dw 0                    ; the save record
sptr        dw 0
hl_yel      db 0                    ; hline: #F0 for yellow, 0 for black
sfree       dw 0                    ; the back buffer's save area: free from sfree to send
send        dw 0
sfree7      dw 0                    ; ... and its slow save area (in segment p_sbank)
send7       dw 0
p_left      dw 0
p_top       dw 0
p_shift     db 0
p_col       dw 0
p_wb        db 0
p_hgt       db 0
p_r0        db 0
p_rows      db 0
p_firsty    dw 0
p_cidx      db 0
p_cend      db 0
p_dcol      dw 0
p_y0        db 0
p_row       db 0                    ; a column's first line: its ring row ...
p_r         db 0                    ; ... and byte in it
p_k         db 0                    ; ... and the lines from there to the ring's end (0 = 256)
p_tab       db 0
p_oldbank   db 0
p_oldbank0  db 0
hl_right    dw 0
hl_p0       db 0
hl_p1       db 0
hl_c0       db 0
hl_c1       db 0
hl_col      db 0
log_n       db 0, 0
log_recs    DEFS 2 * 40 * 16        ; (MAX_LOG records of LG_SIZE bytes each)
jit_img     db 255                  ; the image compiled (255: none)
jit_new     db 0
jit_h       db 0
jit_wb      db 0, 0                 ; its width in bytes at shifts 0 and 2
jit_w       db 0
jit_s       db 0
jit_r       db 0
jit_emit    dw 0
jit_vecs    dw 0, 0                 ; its code at shifts 0 and 2 (in SEG_JIT)
jit_count   dw 0                    ; times plot_slow used it (for the tests)
hud_image   DEFS 64                 ; the timer, as a raw image: 8 byte columns of 8 rows (see plot)
end_code

        ALIGN 256
line_lo     DEFS 256                ; row * 80 (make_lines)
line_hi     DEFS 256
savebuf0    DEFS 1024               ; save areas for the draw log, one per buffer
savebuf1    DEFS 1024
end_ram

        ASSERT end_ram <= #3F00     ; (the stack is from #3F00 to #3FFF)

        SAVE 'build/FRAK.COM',exos_header,end_code-exos_header
        PRINT "Code from ",{hex}start," to ",{hex}end_code,", workspace to ",{hex}end_ram
