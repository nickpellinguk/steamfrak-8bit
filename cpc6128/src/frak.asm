; Steam Frak for the Amstrad CPC 6128 - assembled with RASM (see ../build.sh)
;
; So far (phase 5): the plotter (src/plot.asm), the level loader and background
; (src/level.asm, src/bg.asm) and the game's logic (src/logic.asm, in extra bank
; 2, with src/trogg.asm). For now the program loads the graphics, the levels and
; the logic, takes the machine over
; (src/machine.asm), and then does what the test harness
; (tools/emu) asks: it pokes the plotter's parameters and a command into t_cmd,
; and the program runs it and counts it in t_done. It also still shows a test
; card in each screen buffer in turn (want_mode and flip_rate, for screens.mjs).
;
; Memory: the code from #0040 (below #4000, so it stays visible whichever extra
; bank is paged in at #4000), the screen buffers at #8000 and #C000, the
; graphics in extra bank 0 (GFX_BANK), the compiled meanie in bank 1, the
; game's logic in bank 2 and the background cache in bank 3. The levels are in
; the base RAM at #4000.

GFX_BANK = 0
JIT_TMP_SIZE = 2560                 ; bytes for jit_build's decoded image
jit_tmp = #8000                     ; (in screen buffer 0: it's only used while a level
                                    ; loads, after the background is unrolled)

        ORG #0040
start
        ; RUN"FRAK.BIN loads this with the firmware still running: use it to load
        ; the graphics into extra bank 0, at #4000. (Running a program resets the
        ; firmware to the cassette; KL INIT BACK starts the disc ROM, AMSDOS, again.)
        ld c,7 : ld de,#0040 : ld hl,#ABFF
        call #BCCE                              ; KL INIT BACK
        ld hl,gfx_name : ld b,gfx_name_end - gfx_name : ld c,RAM_BANK + GFX_BANK
        call load_file
        ; and the levels, packed, into the base RAM at #4000
        ld hl,pack_name : ld b,pack_name_end - pack_name : ld c,RAM_BASE
        call load_file
        ; and the game's logic into extra bank 2
        ld hl,logic_name : ld b,logic_name_end - logic_name : ld c,RAM_BANK + LOGIC_BANK
        call load_file
        ; and the music player into extra bank 1
        ld hl,sound_name : ld b,sound_name_end - sound_name : ld c,RAM_BANK + SOUND_BANK
        call load_file
        ; then the machine is ours
        di
        ld sp,#4000
        call machine_init
        call bank_test
        ld a,RAM_BANK + SOUND_BANK : call bank_select
        call snd_init
        ld a,RAM_BASE : call bank_select
        call copy_font
        call make_popcount
        ld hl,palette : call set_palette
        ld a,(want_mode) : call setup_mode
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
        ; count a game tick for each vertical sync since the last time round
        ld a,(last_vsync) : ld b,a
        ld a,(vsyncs) : cp b : jr z,main_loop
        ld (last_vsync),a
        sub b : ld e,a : ld d,0
        ld hl,(ticks) : add hl,de : ld (ticks),hl
        ; (no word from the test harness a second after the start: the game itself)
        ld a,(t_harness) : or a : jr nz,.harness
        ld hl,auto_wait : dec (hl) : jr nz,.harness
        ld a,RAM_BANK + LOGIC_BANK : call bank_select
        jp game
.harness
        ; a mode change asked for (by the test harness)?
        ld a,(want_mode) : ld hl,cur_mode : cp (hl)
        call nz,setup_mode
        ; show the other buffer every flip_rate frames (0: never)
        ld a,(flip_rate) : or a : jr z,main_loop
        ld hl,flip_count : dec (hl) : jr nz,main_loop
        ld (hl),a
        ld a,(front) : xor 1 : ld (front),a
        call show_front
        jr main_loop

; Load the file named at HL (B characters) to #4000, with RAM configuration C paged in
load_file
        push bc
        ld de,#9000                             ; (a 2K buffer for the firmware)
        call #BC77                              ; CAS IN OPEN
        jp nc,load_error
        pop bc : ld b,GA : out (c),c
        ld hl,#4000 : call #BC83                ; CAS IN DIRECT
        ld bc,#7F00 + RAM_BASE : out (c),c
        jp nc,load_error
        jp #BC7A                                ; CAS IN CLOSE

load_error
        jr load_error                           ; (the disc is missing a file)

; Call routine HL in the front end (extra bank 1), A in and out; then whatever was
; paged in, in again
front_call
        ld (.go + 1),hl
        ld (.a + 1),a
        ld a,(ga_ram) : ld (.back + 1),a
        ld a,RAM_BANK + FRONT_BANK : call bank_select
.a      ld a,0
.go     call 0
        push af
.back   ld a,0 : call bank_select
        pop af
        ret

; Run test command t_cmd (see tools/emu/plot.mjs)
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
        dec a : jr nz,.not9
        ld a,(t_arg) : jp set_mode              ; 9: just the mode (no test cards)
.not9   dec a : jp z,log_sprite7                ; 10
        dec a : jr nz,.not11
        ld a,(t_arg) : jp load_level            ; 11
.not11  dec a : jr nz,.not12                    ; 12: repaint the window from the cache
        ld a,(is_vert) : or a : jr nz,.rows
        xor a
.cols   push af : call repaint_column : pop af
        inc a : cp 64 : jr nz,.cols
        ret
.rows   xor a
.row    push af : call repaint_row : pop af
        inc a : cp 25 : jr nz,.row
        ret
.not12  dec a : ret nz                          ; 13: play, from level t_arg (never returns)
        ld a,RAM_BANK + LOGIC_BANK : call bank_select
        ld a,(t_arg) : jp play

; A = 0 or 1: set that mode up and draw both buffers' test cards
setup_mode
        call set_mode
        ld a,#80 : ld (back_page),a : ld a,#F0 : call test_card     ; buffer 0: pen 1
        ld a,#C0 : ld (back_page),a : ld a,#0F : call test_card     ; buffer 1: pen 2
        jp show_front

; The test card: buffer back_page filled with byte A, the screen's edge in white
; (pen 3), so a screenshot shows the size and position of the picture
test_card
        call fill_back
        xor a : call white_line
        ld a,(g_last) : call white_line
        ld c,0
.side   ld a,c : call line_ptr
        ld a,(hl) : or #88 : ld (hl),a              ; the leftmost pixel
        ld a,(g_w) : dec a : add a,l : ld l,a
        jr nc,.nc : inc h                           ; (an 80-byte line can cross a page)
.nc     ld a,(hl) : or #11 : ld (hl),a              ; the rightmost pixel
        ld a,(g_last) : cp c : ret z
        inc c
        jr .side

white_line
        call line_ptr
        ld (hl),#FF
        ld d,h : ld e,l : inc de
        ld a,(g_w) : dec a : ld c,a : ld b,0
        ldir
        ret

palette  db #54, #4C, #56, #4B, #54                    ; black, red, green, white; black border
gfx_name db "GFX.BIN"
gfx_name_end
pack_name db "PACK.BIN"
pack_name_end
logic_name db "LOGIC.BIN"
logic_name_end
sound_name db "SOUND.BIN"
sound_name_end

        INCLUDE "machine.asm"
        INCLUDE "plot.asm"
        INCLUDE "gen/images.asm"
        INCLUDE "gen/levels.asm"
        INCLUDE "gen/sounds.asm"
        INCLUDE "level.asm"
        INCLUDE "bg.asm"

; ------------------------------------------------------------------------------
; Variables
; ------------------------------------------------------------------------------
ready       db 0                    ; #A5 once the program has the machine
vsyncs      db 0                    ; counted by irq
ga_ram      db RAM_BASE             ; the RAM configuration paged in
keys        DEFS 10                 ; the keyboard: a bit set while a key is down
keys_changed db 1                   ; ... set when it changes
t_harness   db 0                    ; the test harness says it's here (else the game starts by itself)
auto_wait   db 50                   ; ... after this many vertical syncs
fe_args                             ; for the front end (in bank 1; see front_call), from the logic bank:
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
bank_errors db #FF                  ; bank_test's result
front       db 0                    ; buffer on show
back        db 1                    ; buffer being drawn (0 or 1)
last_flip   db 0                    ; vsyncs when a buffer was last shown
flip_pending db 0                   ; the game's finished drawing flip_buf: irq shows it
flip_buf    db 0
flip_r12    db 0                    ; ... at this CRTC start
flip_r13    db 0
irq_band    db 0                    ; interrupts since the vertical sync's (0-5)
tick_vs     db 0                    ; vsyncs the game logic has been run for
back_page   db #C0                  ; ... its page (#80 or #C0)
cur_mode    db 0
g_w         db 64                   ; bytes a line
g_last      db 255                  ; the last line
ticks       dw 0                    ; game ticks run
last_vsync  db 0
want_mode   db 0                    ; (poked by the test harness)
flip_rate   db 25                   ; frames between flips (poked by the test harness)
flip_count  db 25
t_cmd       db 0                    ; a command from the test harness
t_arg       db 0
t_done      dw 0                    ; commands done
t_lock      db 0                    ; playing: hold each frame for the test harness (see play.asm)
t_frame     db 0                    ; ... 1 while it's held

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
end_code

        ALIGN 256
line_lo     DEFS 256
line_hi     DEFS 256
rowoff_lo   DEFS 256
rowoff_hi   DEFS 256
popcount    DEFS 256                ; the bits set in each byte (make_popcount)
savebuf0                            ; save areas for the draw log, one per buffer
STAGE       DEFS 1024               ; (the first is also where a level is unpacked from)
savebuf1    DEFS 1024
plats       DEFS MAX_PLATS * PLT_SIZE     ; the level tables (see level.asm)
ladders     DEFS MAX_LADDERS * L_SIZE
draws       DEFS MAX_DRAW * D_SIZE
slows       DEFS MAX_SLOW * S_SIZE
hud_image   DEFS 64                 ; the timer, as a raw image: 8 byte columns of 8 rows (see plot)
end_ram
        ASSERT end_ram <= #3F00     ; (the stack is below #4000)

        SAVE 'FRAK.BIN',start,end_code-start,DSK,'build/frak.dsk'
        PRINT "Code from ",{hex}start," to ",{hex}end_code,", workspace to ",{hex}end_ram

; The graphics, for extra bank 0
        BANK
        ORG #4000
gfx     INCBIN "../build/GFX"
        SAVE 'GFX.BIN',#4000,#4000,DSK,'build/frak.dsk'

; The levels, packed, for the base RAM at #4000
        BANK
        ORG #4000
pack    INCBIN "../build/PACK"
; ... and after them, the level loader, to run in screen buffer 1 (see load_level)
        ASSERT PACK_ORG + PACK_SIZE <= LOADER_STORE
        ORG LOADER_RUN, LOADER_STORE
loader_start
        INCLUDE "loader.asm"
loader_end
        ASSERT LOADER_STORE + loader_end - loader_start <= #8000
        SAVE 'PACK.BIN',#4000,LOADER_STORE + loader_end - loader_start - #4000,DSK,'build/frak.dsk'
        PRINT "Loader: ",loader_end - loader_start," bytes, at ",{hex}LOADER_STORE," (run at ",{hex}LOADER_RUN,")"

; The game's logic, for extra bank 2 (see logic.asm)
        BANK
        ORG #4000
        INCLUDE "logic.asm"
        ASSERT end_logic_bank <= #8000
        SAVE 'LOGIC.BIN',#4000,end_logic_bank-#4000,DSK,'build/frak.dsk'   ; (with its variables' starting values)
        PRINT "Logic from ",{hex}#4000," to ",{hex}logic_vars,", its variables to ",{hex}end_logic_bank

; The music player, its tunes and variables, for extra bank 1; then the compiled
; meanie (from end_sound_bank to FRONT_ORG), then the front end
        BANK
        ORG #4000
        INCLUDE "sound.asm"
        INCLUDE "gen/music.asm"
end_sound_bank
        ASSERT FRONT_ORG - end_sound_bank >= #B80     ; (the biggest compiled meanie, the Scrubbly's: #B6F)
        ORG FRONT_ORG
        INCLUDE "front.asm"
end_bank1
        ASSERT end_bank1 <= #8000
        SAVE 'SOUND.BIN',#4000,end_bank1-#4000,DSK,'build/frak.dsk'
        PRINT "Sound from ",{hex}#4000," to ",{hex}end_sound_bank,", the front end from ",{hex}FRONT_ORG," to ",{hex}end_bank1
