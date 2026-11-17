; Steam Frak for the Enterprise 128 - assembled with RASM (see ../build.sh)
;
; Phase 4 (see ../PLAN.md): the machine layer (src/machine.asm: paging,
; interrupts, the keyboard), the screen (src/screen.asm: Nick's line parameter
; tables, the two ring buffers and their mirrors), the unpacker (src/unpack.asm),
; the plotter (src/plot.asm), and the level loader and background (src/level.asm,
; src/loader.asm, src/bg.asm). The program loads (as an EXOS type 5 file, at
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
        dw end_file - start
        defs 12, 0

start
        ld sp,#4000                             ; (its own stack, at the top of page 0: page 0
                                                ; is the program's, and EXOS's calls use it)
        ; EXOS loaded this and called it, with EXOS still running. First, while
        ; EXOS can still say, which segments are paged in, and which it will give
        ; out (they're where the program's data will go, from phase 2)
        ld c,PAGE0 : ld hl,pages
        ld b,4
.page   in a,(c) : ld (hl),a : inc hl : inc c
        djnz .page
        ; Load the program's files into their segments (but the test harness puts them
        ; there itself: t_noload), before taking the segments: EXOS needs a little
        ; RAM to open a channel, and has none once the program has all of it
        ld a,(t_noload) : or a : call z,load_files
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
        call make_popcount
        xor a : out (NICK_BORDER),a
        call copy_font                          ; (before anything's put over it)
        ld a,(t_noload) : or a : call z,copy_top        ; (then segment #FF's file into it)
        call lpt_init
        xor a : ld (front),a
        ld a,1 : call screen_select             ; (drawing into the other)
        ld a,(vsyncs) : ld (last_vsync),a
        ei
        call sync_bands                         ; (shows buffer 0)
        ld a,#A5 : ld (ready),a                 ; (for the test harness)

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
        ; (no word from the test harness a second after the start: the game itself)
        ld a,(t_harness) : or a : jr nz,.harness
        ld hl,auto_wait : dec (hl) : jr nz,.harness
        ld a,SEG_LOGIC : call bank_select
        jp game
.harness
        ; show the other buffer every flip_rate frames (0: never)
        ld a,(flip_rate) : or a : jr z,main_loop
        ld hl,flip_count : dec (hl) : jr nz,main_loop
        ld (hl),a
        ld a,(front) : xor 1 : ld (flip_buf),a
        ld a,1 : ld (flip_pending),a
        jp main_loop

        INCLUDE "machine.asm"
        INCLUDE "screen.asm"
        INCLUDE "layout.asm"
        INCLUDE "unpack.asm"
        INCLUDE "plot.asm"
        INCLUDE "../../cpc6128/src/gen/images.asm"
        INCLUDE "../../cpc6128/src/gen/levels.asm"
        INCLUDE "level.asm"
        INCLUDE "bg.asm"
        INCLUDE "../../cpc6128/src/gen/sounds.asm"
        INCLUDE "sound.asm"

; Call routine HL in the front end, A in and out; then whatever was paged in, in
; again. The front end is kept packed in segment #FF (FRONT_PACKED_ORG) and runs
; in SEG_CACHE (FRONT_ORG), where the level's background cache is: it's unpacked
; there unless it's still there since it last was (load_level builds the cache
; there again, and says it isn't: fe_unpacked).
front_call
        ld (.go + 1),hl
        ld (.a + 1),a
        ld a,(win_seg) : ld (.back + 1),a
        ld a,(fe_unpacked) : or a : call z,fe_unpack
        ld a,SEG_CACHE : call bank_select
.a      ld a,0
.go     call 0
        push af
.back   ld a,0 : call bank_select
        pop af
        ret
; ... unpacking it (from #FF, at page 3 meanwhile)
fe_unpack
        ld a,SEG_CACHE : call bank_select
        ld a,SEG_TOP : out (PAGE3),a
        ld hl,FRONT_PACKED_ORG - #4000 + #C000 : ld de,FRONT_ORG
        call unpack
        ld a,SEG_JIT : out (PAGE3),a            ; (and the font beside it)
        ld hl,FONT_STORE - #4000 + #C000 : ld de,fe_font : ld bc,96 * 8 : ldir
        ld a,(back) : call screen_select
        ld a,1 : ld (fe_unpacked),a
        ret

; Fill the back buffer's ring with 0 (the background colour)
fill_back
        ld hl,(back_ring) : ld d,h : ld e,l : inc de
        ld (hl),0 : ld bc,RING_SIZE - 1 : ldir
        ret

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
        dec a : jr nz,.not11
        ld a,(t_arg) : jp load_level            ; 11
.not11  dec a : jr z,.repaint                  ; 12: repaint the window from the cache
        dec a : ret nz                          ; 13: play, from level t_arg (never returns)
        ld a,SEG_LOGIC : call bank_select
        ld a,(t_arg) : jp play
.repaint
        ld a,(is_vert) : or a : jr nz,.rows
        xor a
.cols   push af : call repaint_column : pop af
        inc a : cp LINE_BYTES : jr nz,.cols
        ret
.rows   xor a
.row    push af : call repaint_row : pop af
        inc a : cp 32 : jr nz,.row
        ret

; line_lo/line_hi[row] = row * 80: where ring row `row` starts in a ring
make_lines
        ld hl,0 : ld de,line_lo : ld bc,LINE_BYTES
.row    ld a,l : ld (de),a
        inc d : ld a,h : ld (de),a : dec d
        add hl,bc
        inc e : jr nz,.row
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
flip_min     db 0                   ; vertical syncs between flips, at least (FRAMES_PER_DRAW playing)
last_flip    db 0                   ; vsyncs when a buffer was last shown
irq_band     db 0                   ; interrupts since the vertical sync's (0-3)
irq_single   db 0                   ; (sync_bands: every interrupt the vertical sync's)
scroll0      dw 0                   ; each buffer's scroll position (even, 0 to 20478)
scroll1      dw 0
pal0         db #49, #92, #DB, #FF, 0, 0, 0, 0      ; each buffer's palette
pal1         db #24, #6D, #B6, #12, 0, 0, 0, 0
ls_buf       db 0                   ; lpt_set's workings
ls_k         db 0
ls_base      dw 0
ls_scroll    dw 0
ls_ptr       dw 0
ls_cur       db 0
ls_end       db 0
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
t_lock      db 0                    ; playing: hold each frame for the test harness (see play.asm)
t_frame     db 0                    ; ... 1 while it's held
tick_vs     db 0                    ; vsyncs the game logic has been run for
fe_args                             ; for the front end (see front_call), from the logic segment:
fe_diff     db 1                    ; ... the difficulty (and back)
fe_last     db 1                    ; ... the last level played
fe_done_level db 0                  ; ... the level just finished: which, its time (game ticks),
fe_done_ticks dw 0                  ; ... the restarts, and whether all the gems were collected
fe_done_restarts db 0
fe_done_gems db 0
snd_music_req db #FF                ; sound (see sound.asm): a tune to start (#FF: none)
snd_sfx_req db #FF                  ; ... sound effects to start (#FF: none)
snd_sfx_req2 db #FF
snd_music_opt db 0                  ; ... 0 all the tracks, 1 the first only, 2 no music (M)
snd_sfx_opt db 0                    ; ... 0 sound effects on, 1 off (S)
snd_cur     db 0                    ; ... the tune last asked for
snd_m_last  db 0                    ; ... M and S as they were
snd_s_last  db 0
t_cmd       db 0                    ; a command from the test harness
t_arg       db 0
ll_level    db 0                    ; load_level's level
p_r         db 0                    ; (plot.asm: a column's first line's byte in its ring row ...)
p_k         db 0                    ; (... and the lines from there to the ring's end, 0 = 256)
; the plotter's parameters
p_img       db 0
p_x         dw 0
p_y         dw 0
q_x         dw 0                    ; (hline's other end)
p_mode      db 0
p_sbank     db 0                    ; PM_SAVEONLY: the bank the save area is in
clip_l      db 0                    ; the window, in level coordinates
clip_r      db 64
clip_t      dw 0
clip_h      db 0
sbase       dw 0                    ; the save record
sptr        dw 0
hl_yel      db 0                    ; hline: #F0 for yellow, 0 for black
sfree       dw 0                    ; the back buffer's save area: free from sfree to send
send        dw 0
sfree7      dw 0                    ; ... and its slow save area (in bank p_sbank)
send7       dw 0
; ... and its workings
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
p_row       db 0
p_tab       db 0
p_oldbank   db 0
p_oldbank0  db 0
hl_right    dw 0
hl_p0       db 0
hl_p1       db 0
hl_c0       db 0
hl_c1       db 0
hl_line     db 0
hl_row      db 0
hl_col      db 0
; the draw log, for each buffer (MAX_LOG entries each)
log_n       db 0, 0
log_recs    DEFS 2 * 40 * 16            ; (MAX_LOG records of LG_SIZE bytes each)
rc_safe     db 0                    ; restore_chase: the window's lines scanned for the last time
rc_ns       db 0                    ; ... how many entries are passed over
rc_skip     DEFS 2 * 40             ; ... and which
; the compiled meanie
jit_img     db 255                  ; the image compiled (255: none)
jit_new     db 0
jit_h       db 0
jit_wb      db 0, 0                 ; its width in bytes at shifts 0 and 2
jit_w       db 0
jit_s       db 0
jit_r       db 0
jit_emit    dw 0
jit_vecs    dw 0, 0                 ; its code at shifts 0 and 2 (in JIT_BANK)
jit_count   dw 0                    ; times plot_slow used it (for the tests)
; the level (see level.asm)
cur_level   db 0
level_rows  db 0                    ; its height, in character rows
level_h     dw 0                    ; ... and pixels
is_vert     db 0                    ; it scrolls up and down
row_max     db 0                    ; level_rows - the window's
level_cols  db 0                    ; its width, in byte columns
scroll_max  dw 0                    ; its width - the window's
x_max       dw 0                    ; its width - 10
level_bg    db 0                    ; its background colour
trogg_x0    dw 0                    ; where Trogg starts
trogg_y0    dw 0
num_plats   db 0
num_ladders db 0
num_draw    db 0
num_slow    db 0
num_keys    db 0
num_gems    db 0
; ... and the loader's workings
q_y1        dw 0                    ; platform_find's question (and q_x)
q_y2        dw 0
res_found   db 0                    ; ... and answer
res_y       dw 0
res_i       db 0
rx          dw 0                    ; a record
ry          dw 0
rimg        db 0
rec         dw 0                    ; the next record
ld_i        db 0
ld_j        db 0
ld_p        db 0
ld_f        db 0
pf_i        db 0
pf_left     db 0                    ; platform_find: the platforms left (for res_i)
pf_bottom   dw 0
px          dw 0                    ; a moving platform's edges
py          dw 0
pw          db 0
ph          db 0
pr          dw 0
pl          dw 0
pb          dw 0
found       db 0
best        dw 0
; Trogg (see trogg.asm)
tx          dw 0                    ; where he is: x, y in pixels and twentieths
ty          dw 0
tyf         db 0
tstate      db 0                    ; ST_
tv          db 0                    ; y velocity (up), twentieths of a pixel a tick
tv_prev     db 0                    ; ... before this tick's gravity
xvel        db 0                    ; x velocity, pixels a tick
xmove       db 0                    ; the keys: -1, 0 or 1 (left, right)
ymove       db 0                    ; ... (down, up)
doyoyo      db 0
tface       db 0                    ; 0 facing right, 1 left
tclimb      db 0                    ; 0 still on a ladder, 1 going up, 2 down
anim        db 0
cur_plat    db 255                  ; the platform he's on (255: none)
plat_hit    db 0
dead        db 0                    ; ticks until he restarts (0: alive)
won         db 0
ud_db       db 0                    ; up/down and left/right debounces
lr_db       db 0
; ... and the platform and ladder questions' workings
q_y1f       db 0
q_y2f       db 0
q_onplat    db 0
q_jump      db 0
res_x       dw 0
res_yf      db 0
lf_up       db 0
lf_i        db 0
lad_top     dw 0
lad_len     dw 0
lf_bot      dw 0
fy2         dw 0
fy2f        db 0
; the background (see bg.asm)
num_bg      db 0
mb          db 0                    ; bytes in each of a line's masks (4 or 10)
pages1      db 0                    ; dictionary pages - 1
po          dw 0
u_cnt       dw 0                    ; cells in the dictionary
u_line      db 0
u_bl        dw 0
u_bh        dw 0
u_i         db 0
u_j         db 0
u_tb        dw 0
u_src       dw 0
u_cells     db 0
u_s         db 0
u_s4        db 0
u_h         db 0
u_cur       db 0
u_prev      db 0
u_dp        dw 0
u_sp        dw 0
u_r0        db 0
u_r1        db 0
u_pt        dw 0
u_y         db 0
u_start     dw 0
u_np        dw 0
u_x         db 0
u_nl        db 0                    ; a cell's number (u_nh follows u_nl)
u_nh        db 0
u_h8        db 0
u_cellp     dw 0
cmask       DEFS 30                 ; a line's masks
pl_masks    dw 0                    ; seek_line: the line's masks
pl_line     db 0                    ; painting: the line, its cells [pl_i0, pl_i1]
pl_i0       db 0
pl_i1       db 0
pl_src      dw 0
pl_x        db 0
curbit      db 0
cellk       db 0
pl_ptr      dw 0
; The front end's variables (in the low RAM, so they last: the front end is
; unpacked afresh), the records, and the font
fe_sel     db 0                     ; the selected button
fe_top_sel db 0                     ; ... on the top menu
fe_group   db 0
fe_kind    db 0                     ; 0 the top menu, 1 a level group
fe_bx      db 0                     ; the button being drawn: its byte column and top row
fe_y0      db 0
fe_flash   db 0
fe_i       db 0
fe_i2      db 0
fe_n       db 0
fe_pat     db 0
fe_lev     db 0
fe_iw      db 0
fe_ih      db 0
fe_r       db 0
fe_wy      db 0                     ; (fe_win)
fe_wdy     db 0
fe_text    DEFS 9
txt_col    db 0                     ; print_char: where, and in what colour
txt_y      dw 0
txt_colour db 3
txt_src    dw 0
rec_best_lo DEFS NUM_LEVELS         ; the records: each level's best time (game ticks), #FFFF if none
rec_best_hi DEFS NUM_LEVELS
rec_gem    DEFS NUM_LEVELS          ; ... 1 if it's been completed with all the gems
rec_rate   DEFS NUM_LEVELS * 4      ; ... fewest restarts, at each difficulty (Easy, Hard, Harder, Insane), #FF if none
rec_rate0  DEFS NUM_LEVELS          ; ... and at Zero (no balloons or daggers: for speed runs)
font_digits DEFS 11 * 8            ; EXOS's font's 0-9 and colon, for the timer (copy_font)
fe_unpacked db 0                    ; the front end is unpacked in SEG_CACHE (front_call)
t_harness   db 0                    ; the test harness says it's here (else the game starts by itself)
t_noload    db 0                    ; the test harness puts the files in their segments itself
load_err    db 0                    ; load_files: EXOS's status, if a file wasn't loaded ...
load_at     dw 0                    ; ... and its entry in load_list
auto_wait   db 50                   ; ... after this many vertical syncs
end_code

savebuf0                            ; save areas for the draw log, one per buffer
STAGE                               ; (the first is also where a level is unpacked from)
; ------------------------------------------------------------------------------
; Loading. EXOS loads this program (START, on the disk: LOAD with no name loads
; it) into page 0's segment at #0100, and runs it. It then loads the rest
; through EXOS (opening each file on a channel, and reading it as a block),
; into the segments EXOS gave it: each file at its place, but segment #FF's
; (TOP.BIN: the levels and the front end, packed), which is EXOS's own while it
; runs, into #FC for now; copy_top copies it there once the machine is the
; program's (after copy_font has taken EXOS's font from it).
;
; This runs once, at the start, so it's in the first save area (savebuf0, also
; STAGE), which nothing uses until a level loads: it's in the file EXOS loads,
; and the space is the save area's after.
; ------------------------------------------------------------------------------
EXOS_OPEN = 1 : EXOS_CLOSE = 3 : EXOS_READ_BLOCK = 6
LOAD_CHANNEL = 1

load_files
        ld ix,load_list
.file   ld a,(ix+0) : or a : ret z
        out (PAGE1),a                           ; (its segment in the window)
        ld e,(ix+3) : ld d,(ix+4)               ; (its name)
        ld a,LOAD_CHANNEL : rst #30 : db EXOS_OPEN
        or a : jr nz,load_failed
        ld e,(ix+1) : ld d,(ix+2)               ; (where it goes, in the window)
        ld c,(ix+5) : ld b,(ix+6)               ; (its size)
        ld a,LOAD_CHANNEL : rst #30 : db EXOS_READ_BLOCK
        or a : jr nz,load_failed
        ld a,LOAD_CHANNEL : rst #30 : db EXOS_CLOSE
        ld de,7 : add ix,de
        jr .file
; (a file missing, or not read: a red border, and stop)
load_failed
        ld (load_err),a : ld (load_at),ix       ; (EXOS's status, and which file)
        di
        ld a,#49 : out (NICK_BORDER),a
.stop   jr .stop
; each file: its segment, its address in the window, its name, its size
load_list
        db SEG_GFX : dw #4000, name_gfx, GFX_SIZE
        db SEG_LOGIC : dw #4000, name_logic, end_logic_bank - #4000
        db SEG_JIT : dw #4000 + FE_SPARE, name_loader, loader_end - loader_start
        db SEG_VIDEO : dw #4000, name_top, front_packed_end - LEVELS_ORG
        db 0
name_gfx    db 7, "GFX.BIN"
name_logic  db 9, "LOGIC.BIN"
name_loader db 10, "LOADER.BIN"
name_top    db 7, "TOP.BIN"

; Copy segment #FF's file, loaded into #FC, to #FF (the machine is the program's)
copy_top
        ld a,SEG_VIDEO : out (PAGE1),a
        ld a,SEG_TOP : out (PAGE3),a
        ld hl,#4000 : ld de,#C000 : ld bc,front_packed_end - LEVELS_ORG : ldir
        ld a,(win_seg) : out (PAGE1),a
        ld a,(back) : jp screen_select

end_file                            ; (FRAK.COM ends here)
        DEFS savebuf0 + 1024 - $
savebuf1    DEFS 1024
        ALIGN 256
line_lo     DEFS 256                ; row * 80 (make_lines)
line_hi     DEFS 256
popcount    DEFS 256                ; the bits set in each byte (make_popcount)
plats       DEFS MAX_PLATS * PLT_SIZE     ; the level tables (see level.asm)
ladders     DEFS MAX_LADDERS * L_SIZE
draws       DEFS MAX_DRAW * D_SIZE
slows       DEFS MAX_SLOW * S_SIZE
hud_image   DEFS 64                 ; the timer, as a raw image: 8 byte columns of 8 rows (see plot)
; (EXOS's whole font, characters 32-127, is kept in segment #FE, after the
; compiled meanie's room, FONT_STORE; front_call copies it to fe_font, beside
; the front end in SEG_CACHE, when it unpacks it)
end_ram

        ASSERT end_ram <= #3F00     ; (the stack is from #3F00 to #3FFF)

        ASSERT end_file <= savebuf0 + 1024
        SAVE 'build/FRAK.COM',exos_header,end_file-exos_header
        PRINT "Code from ",{hex}start," to ",{hex}end_code,", workspace to ",{hex}end_ram

; The front end, for SEG_CACHE at FRONT_ORG (build/FRONT.BIN), where front_call
; unpacks it to, below the slow save areas; it's packed (build.sh: build/FRONT.lz)
; for segment #FF
        BANK
        ORG FRONT_ORG
front_start
        INCLUDE "front.asm"
front_end_
        ASSERT front_end_ <= fe_font && fe_font + 96 * 8 == BG_TOP
        SAVE 'build/FRONT.BIN',front_start,front_end_-front_start
        PRINT "Front end: ",front_end_ - front_start," bytes"

; Segment #FF (build/TOP.BIN): the levels, packed (the CPC version's, as they
; are), at #4000, and the front end, packed (by build.sh, after a first pass
; without it), at FRONT_PACKED_ORG. (The line parameter tables are made at
; LPT_WIN when the program starts.)
        BANK
        ORG LEVELS_ORG
        INCBIN "../../cpc6128/build/PACK"
levels_end
        ASSERT PACK_ORG == LEVELS_ORG && levels_end - LEVELS_ORG == PACK_SIZE
        ASSERT levels_end <= FRONT_PACKED_ORG
        ORG FRONT_PACKED_ORG
        IF PASS == 2
        INCBIN "../build/FRONT.lz"
        ENDIF
front_packed_end
        ASSERT front_packed_end <= LPT_WIN
        ASSERT front_packed_end - LEVELS_ORG <= #4000     ; (loaded into #FC first: load_files)
        SAVE 'build/TOP.BIN',LEVELS_ORG,front_packed_end-LEVELS_ORG
        PRINT "Segment #FF: the levels, and the front end packed, to ",{hex}front_packed_end

; The game's logic, for segment #FA at #4000 (as the CPC version's extra bank 2)
        BANK
        ORG #4000
        INCLUDE "logic.asm"
        ASSERT end_logic_bank <= #8000
        SAVE 'build/LOGIC.BIN',#4000,end_logic_bank-#4000          ; (with its variables' starting values)
        PRINT "Logic from ",{hex}#4000," to ",{hex}logic_vars,", its variables to ",{hex}end_logic_bank

; The level loader, for segment #FE after buffer 1's ring, where it runs (at page 3)
        BANK
        ORG LOADER_RUN
loader_start
        INCLUDE "loader.asm"
loader_end
        ASSERT loader_end - #8000 <= JIT_ORG                ; (in the window, where the JIT is)
        SAVE 'build/LOADER.BIN',loader_start,loader_end-loader_start
        PRINT "Loader: ",loader_end - loader_start," bytes, at ",{hex}LOADER_RUN
