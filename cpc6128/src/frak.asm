; Steam Frak for the Amstrad CPC 6128 - assembled with RASM (see ../build.sh)
;
; Phase 3: the plotter (src/plot.asm). For now the program loads the graphics,
; takes the machine over (src/machine.asm), and then does what the test harness
; (tools/emu) asks: it pokes the plotter's parameters and a command into t_cmd,
; and the program runs it and counts it in t_done. It also still shows a test
; card in each screen buffer in turn (want_mode and flip_rate, for screens.mjs).
;
; Memory: the code from #0040 (below #4000, so it stays visible whichever extra
; bank is paged in at #4000), the screen buffers at #8000 and #C000, the
; graphics in extra bank 0 (GFX_BANK) and the compiled meanie in bank 1.

GFX_BANK = 0
JIT_TMP_SIZE = 2560                 ; bytes for jit_build's decoded image

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
        ; then the machine is ours
        di
        ld sp,#4000
        call machine_init
        call bank_test
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
        dec a : ret nz
        ld a,(t_arg) : jp load_level            ; 11

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

        INCLUDE "machine.asm"
        INCLUDE "plot.asm"
        INCLUDE "gen/images.asm"
        INCLUDE "level.asm"
        INCLUDE "gen/levels.asm"

; ------------------------------------------------------------------------------
; Variables
; ------------------------------------------------------------------------------
ready       db 0                    ; #A5 once the program has the machine
vsyncs      db 0                    ; counted by irq
ga_ram      db RAM_BASE             ; the RAM configuration paged in
keys        DEFS 10                 ; the keyboard: a bit set while a key is down
bank_errors db #FF                  ; bank_test's result
front       db 0                    ; buffer on show
back        db 1                    ; buffer being drawn (0 or 1)
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
log_kind    DEFS 2 * MAX_LOG
log_img     DEFS 2 * MAX_LOG
log_x       DEFS 4 * MAX_LOG
log_y       DEFS 4 * MAX_LOG
log_x1      DEFS 4 * MAX_LOG
log_sb      DEFS 4 * MAX_LOG
log_bank    DEFS 2 * MAX_LOG
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
end_code

        ALIGN 256
line_lo     DEFS 256
line_hi     DEFS 256
rowoff_lo   DEFS 256
rowoff_hi   DEFS 256
savebuf0                            ; save areas for the draw log, one per buffer
STAGE       DEFS 1024               ; (the first is also where a level is unpacked from)
savebuf1    DEFS 1024
jit_tmp     DEFS JIT_TMP_SIZE
plats       DEFS MAX_PLATS * PLT_SIZE     ; the level tables (see level.asm)
ladders     DEFS MAX_LADDERS * L_SIZE
draws       DEFS MAX_DRAW * D_SIZE
slows       DEFS MAX_SLOW * S_SIZE
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
        SAVE 'PACK.BIN',#4000,PACK_SIZE,DSK,'build/frak.dsk'
