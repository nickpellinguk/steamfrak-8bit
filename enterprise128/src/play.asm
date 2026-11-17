; The game being played: the frame loop, scrolling and drawing. The CPC
; version's (../cpc6128/src/play.asm), a port of the BBC version's main_loop and
; what it calls (band_scroll, do_scroll, do_pending, draw_slow and the rest), in
; the logic segment with game_tick.
;
; Each frame, in the buffer that isn't on show:
;   1. bring its scroll position up to date, and repaint what's changed: columns
;      (or rows) scrolled into view, collected things
;   2. bring the moving platforms and meanies up to date (draw_slow)
;   3. draw the moving things - balloons, daggers and meanies flying off, the
;      yoyo and its string, Trogg, and his FRAK! bubble - saving the background
;      under each (the draw log)
; then ask for it to be shown (flag_flip: its line parameter table set from its
; scroll position, then irq points Nick at it at the next vertical sync, no
; sooner than FRAMES_PER_DRAW since the last, and Nick takes it at the next
; frame), so the switch is never part-way down the screen. Meanwhile, run a tick of game logic for each vertical
; sync since the last ticks, and then tidy the buffer still on show for the next
; frame - erase its draw log (restore_chase), chasing the raster down the screen
; until it's been replaced - then wait for the flip, and round again.
;
; The window is the BBC version's, 320x256 (80 byte columns, 32 character rows),
; for both kinds of level. Nick fetches 2 bytes a slot, so sideways the view
; moves 8 pixels (2 byte columns) at a time, as the CPC version's does, where the
; BBC version's moves 4.

FRAMES_PER_DRAW = 2                 ; vertical syncs per drawn frame
MAX_TICKS_PER_FRAME = 4             ; (as the BBC version: below 12.5 frames a second the game slows)
VIEW_L = 120 : VIEW_R = 200         ; the band Trogg moves in without the view scrolling,
VIEW_T = 96 : VIEW_B = 176          ; across the 320-pixel window, down the 256-line one (the BBC's)
STEP_X = 8                          ; (pixels a sideways scroll step moves)
MAX_DMG = 40
W_COLS = 80 : W_ROWS = 32       ; (the window: byte columns, character rows)
SLOWSAVE0 = #6A00                   ; the slow save areas, in the cache segment above the cache
SLOWSAVE1 = #7500
SLOWSAVE_SIZE = #0B00
SAVE_SIZE = 1024
; a slow sprite as drawn in a buffer
DR_ON = 0 : DR_XL = 1 : DR_XH = 2 : DR_YL = 3 : DR_YH = 4
DR_C0 = 5 : DR_C1 = 6 : DR_Y0 = 7 : DR_Y1 = 8                ; its byte columns, and 4-line rows
DR_SIZE = 9

; Play, from level A (the test harness's command 13). Never returns.
play    push af : ld a,FRAMES_PER_DRAW : ld (flip_min),a : pop af
        call begin_level
        jr frame_loop
; The game, from the start: the attract screen and the menus, then the level chosen
game    ld a,FRAMES_PER_DRAW : ld (flip_min),a
        xor a : call front_end
        call begin_level
frame_loop
        call wait_flip                          ; (the buffer to draw in mustn't be on show)
        ld a,(front) : xor 1 : ld (back),a
        call back_setup
        ; Once Trogg has won, or is dead and this buffer already shows the FRAK!
        ; bubble, nothing changes, so don't redraw
        ld a,(won) : or a : jr z,.not_won
        ld a,(back) : ld hl,bwon : call look : or a : call z,win_screen   ; (once in each buffer)
        jp .show
.not_won
        ld a,(dead) : or a : jr z,.redraw
        ld a,(back) : ld hl,bfrak : call look : or a : jp nz,.show
.redraw xor a : ld (dmg_n),a : ld (dmg_all),a  ; nothing repainted yet this frame
        call restore_log                        ; (restore_chase has normally done it)
        call band_scroll
        call do_scroll
        ld a,(back) : ld e,a : ld d,0
        ld hl,bscroll : add hl,de : ld a,(scrollcol) : ld (hl),a
        ld hl,brow : add hl,de : ld a,(scrollrow) : ld (hl),a
        call do_pending
        ; the save areas: this buffer's, and its slow save area (in the cache bank)
        ld a,(back) : or a
        ld hl,savebuf0 : ld de,SLOWSAVE0 : jr z,.save_set
        ld hl,savebuf1 : ld de,SLOWSAVE1
.save_set
        ld (sfree),hl : ld (sfree7),de
        ld bc,SAVE_SIZE : add hl,bc : ld (send),hl : ld (save_end),hl
        ex de,hl : ld bc,SLOWSAVE_SIZE : add hl,bc : ld (send7),hl
        ld a,SEG_CACHE : ld (p_sbank),a
        ; moving platforms and meanies stay drawn in each buffer: only the ones that
        ; moved (or were painted over) are drawn again
        call commit_all
        call draw_slow
.slow_done                                      ; (tidy.mjs: nothing logged yet)
        ; moving objects (drawn behind Trogg, as meanies were in GameMaker), keeping
        ; enough of the save area for Trogg, the yoyo and the FRAK! bubble
        ld hl,(send) : ld de,SAVE_RESERVE_ALIVE
        ld a,(dead) : or a : jr z,.reserve
        ld de,SAVE_RESERVE_DEAD
.reserve
        or a : sbc hl,de : ld (send),hl
        call draw_movers
        ld hl,(save_end) : ld (send),hl
        ; the yoyo and its string
        ld a,(tstate) : cp ST_YOYO_OUT : jr c,.no_yoyo
        call yoyo_string_params
        call log_line
        call yoyo_image : ld (p_img),a
        ld hl,(yo_x) : ld (p_x),hl : ld hl,(yo_y) : ld (p_y),hl
        call log_sprite
.no_yoyo
        call draw_springs                       ; (moving bouncy platforms' springs)
        ; Trogg (standing or walking, he's two images: his body and his legs)
        call trogg_image : ld e,a : ld d,0
        ld hl,img_part_b : add hl,de : ld a,(hl) : ld (t_part_b),a
        ld hl,img_part_a : add hl,de : ld a,(hl) : ld (p_img),a
        ld hl,(tx) : ld (p_x),hl : ld hl,(ty) : ld (p_y),hl
        call log_sprite
        ld a,(t_part_b) : cp 255 : jr z,.one_part
        ld (p_img),a
        ld hl,(tx) : ld (p_x),hl : ld hl,(ty) : ld (p_y),hl
        call log_sprite
.one_part
        call draw_hud                           ; the timer and rating
        ; ... and "FRAK!" at (x + 12, y - 26) if he's dead
        ld a,(back) : ld e,a : ld d,0 : ld hl,bfrak : add hl,de
        ld a,(dead) : ld (hl),a : or a : jr z,.show
        ld a,IMG_Frak : ld (p_img),a
        ld hl,(tx) : ld de,12 : add hl,de : ld (p_x),hl
        ld hl,(ty) : ld de,-26 : add hl,de : ld (p_y),hl
        call log_sprite

.show   ld hl,(frames_drawn) : inc hl : ld (frames_drawn),hl
        ; (the test harness can hold each frame to look at it, and then the game
        ; runs two ticks a frame)
        ld a,(t_lock) : or a : jr z,.flag
        ld a,1 : ld (t_frame),a
.hold   ld a,(t_frame) : or a : jr nz,.hold
.flag   ; it's drawn: shown at the next vertical sync (irq does it)
        call flag_flip
        ; meanwhile, a tick of game logic for each vertical sync since the last ticks
        ; (at most MAX_TICKS_PER_FRAME, so a long pause such as a full redraw doesn't
        ; jump ahead)...
        ld a,(tick_vs) : ld b,a
        ld a,(vsyncs) : ld (tick_vs),a
        sub b : cp MAX_TICKS_PER_FRAME + 1 : jr c,.owed
        ld a,MAX_TICKS_PER_FRAME
.owed   ld c,a
        ld a,(t_lock) : or a : ld a,c : jr z,.ticks
        ld a,FRAMES_PER_DRAW
.ticks  ld (ticks_left),a : ld (frame_ticks),a
        or a : jr z,.tidy
.tick   call game_tick
        jr z,.next_tick
        cp TICK_WON : jr z,.next_level
        cp TICK_QUIT : jr z,.quit
        call restore_checkpoint                 ; TICK_DIED: back to the checkpoint
        call redraw
        jp frame_loop
.next_level
        call record_result
        ld a,(cur_level) : inc a : call begin_level
        jp frame_loop
.quit   ld a,1 : call front_end                 ; (Escape: back to the menus)
        call begin_level
        jp frame_loop

.next_tick
        ld hl,ticks_left : dec (hl) : jr nz,.tick
.tidy   ; ... and then the other buffer, still on show, tidied for the next frame
        call tidy
        jp frame_loop

; The front end (in bank 1: see front.asm): A = 0 for the attract screen and then
; the menus, 1 for just the menus; A = the level chosen
front_end
        push af
        call cancel_flip
        ld a,(difficulty) : ld (fe_diff),a
        ld a,(last_level) : ld (fe_last),a
        pop af
        ld hl,fe_main : call front_call
        ld (last_level),a
        push af : ld a,(fe_diff) : ld (difficulty),a : pop af
        ret
; Give the result of the level just finished (done_*) to the front end's records
record_result
        ld a,(done_valid) : or a : ret z
        xor a : ld (done_valid),a
        call fe_done
        ld hl,fe_record : jp front_call
; ... the result, and the difficulty, for the front end
fe_done ld a,(difficulty) : ld (fe_diff),a
        ld a,(done_level) : ld (fe_done_level),a
        ld hl,(done_ticks) : ld (fe_done_ticks),hl
        ld a,(done_restarts) : ld (fe_done_restarts),a
        ld a,(done_gems) : ld (fe_done_gems),a
        ret

; Erase what's drawn in the buffer on show (which the next frame is drawn in),
; chasing the raster while the one just drawn waits to be shown; not if the next
; frame won't be drawn there (as frame_loop decides: once Trogg has won, or is
; dead and it already shows the FRAK! bubble)
tidy    ld a,(won) : or a : ret nz
        ld a,(back) : xor 1 : ld (back),a
        ld a,(dead) : or a : jr z,.tidy
        ld a,(back) : ld hl,bfrak : call look : or a : ret nz
.tidy   call back_setup
        jp restore_chase

; The back buffer's paging, scroll position and window
back_setup
        call set_back_page
        ld a,(back) : ld hl,bscroll : call look : ld (scrollcol),a
        ld a,(back) : ld hl,brow : call look : ld (scrollrow),a
        jp set_window_clip

; The back buffer, scrolled to its position (its table set: it isn't on show),
; to be shown at the next vertical sync (irq shows it, setting front)
flag_flip
        call set_back_table
        ld a,(back) : ld (flip_buf),a
        ld a,1 : ld (flip_pending),a
        ret
; ... or no longer
cancel_flip
        xor a : ld (flip_pending),a
        ret
; Wait until it's been shown
wait_flip
        ld a,(flip_pending) : or a : ret z
        halt
        jr wait_flip

; Show the back buffer, scrolled to its position, from the next frame (the
; blank table is on show while both are drawn afresh: see begin_level and redraw)
flip    call set_back_table
        ld a,(back) : ld (front),a
        jp show_lpt
; The back buffer's table from its scroll position: its offset in the ring,
; ((scrollrow * 8) MOD 256) * 80 + scrollcol, MOD 20480
set_back_table
        ld a,(scrollrow) : add a,a : add a,a : add a,a
        ld l,a : ld h,line_lo >> 8 : ld e,(hl) : inc h : ld d,(hl)
        ld a,(scrollcol) : ld l,a : ld h,0 : add hl,de
        ld de,RING_SIZE : or a : sbc hl,de : jr nc,.in
        add hl,de
.in     ld a,(back) : or a : jr nz,.b1
        ld (scroll0),hl : jp lpt_set
.b1     ld (scroll1),hl : ld a,1 : jp lpt_set

; Page the back buffer in (its ring at back_ring)
set_back_page
        ld a,(back) : jp screen_select

; ------------------------------------------------------------------------------
; Starting a level, and drawing it from scratch
; ------------------------------------------------------------------------------

; Load level A (the first if it's past the last), and start it
begin_level
        push af : call cancel_flip : pop af
        cp NUM_LEVELS : jr c,.in_range
        xor a
.in_range
        push af : call level_init_blank : pop af        ; (hide the loading)
        call load_level
        call level_init
        ; (and on)

; Draw both buffers from scratch, centred on Trogg (the state part of the BBC
; version's redraw_all is reset_play, which restore_checkpoint and level_init end with),
; with the blank table on show meanwhile
redraw
        call cancel_flip
        call level_init_blank
        call level_music
        call set_level_palette
        ld hl,#FFFF : ld (hud_secs),hl          ; (the timer to be drawn afresh)
        ; nothing drawn in either buffer
        ld hl,drecs : ld de,drecs + 1 : ld bc,2 * MAX_SLOW * DR_SIZE - 1 : ld (hl),0 : ldir
        call centre_scroll
        ld a,1
.buffer ld (back),a
        call set_back_page
        ld a,(newcol) : ld (scrollcol),a
        ld a,(newrow) : ld (scrollrow),a
        call set_window_clip
        xor a : ld (rd_i),a
.line   ld a,(is_vert) : or a : jr nz,.row
        ld a,(scrollcol) : ld hl,rd_i : add a,(hl) : call repaint_col
        ld a,(win_cols) : jr .next
.row    ld a,(scrollrow) : ld hl,rd_i : add a,(hl) : call repaint_rowf
        ld a,(win_rows)
.next   ld hl,rd_i : inc (hl) : cp (hl) : jr nz,.line
        ld a,(back) : ld e,a : ld d,0
        ld hl,bscroll : add hl,de : ld a,(newcol) : ld (hl),a
        ld hl,brow : add hl,de : ld a,(newrow) : ld (hl),a
        ld hl,log_n : add hl,de : ld (hl),0
        ld hl,bfrak : add hl,de : ld (hl),0
        ld hl,bwon : add hl,de : ld (hl),0
        ld hl,pend_hi : add hl,de : ld (hl),0
        ld hl,pend_lo : add hl,de : ld (hl),#FF
        ld a,(back) : dec a : jp p,.buffer
        ld a,1 : ld (back),a : call flip        ; (buffer 1 on show: buffer 0 is drawn first)
        call wait_vsync                         ; (and its table started)
        ld a,(vsyncs) : ld (last_flip),a : ld (tick_vs),a
        ret

; The level's tune (as the Steam version): with Poglets, "A Little Bag of Weed";
; with Hooters, "The Man Who Once Was I"; else the Frak! theme
level_music
        ld c,TUNE_WEED : ld a,IMG_Poglet : call level_has : jr c,.play
        ld c,TUNE_MAN : ld a,IMG_Hooter : call level_has : jr c,.play
        ld c,TUNE_FRAK
.play   ld a,c : jp play_music
; Carry set if image A is one of the level's objects or moving sprites (C kept)
level_has
        ld e,a
        ld a,(num_draw) : or a : jr z,.slows
        ld b,a : ld ix,draws
.draw   ld a,(ix+D_IMG) : cp e : scf : ret z
        push de : ld de,D_SIZE : add ix,de : pop de
        djnz .draw
.slows  ld a,(num_slow) : or a : ret z
        ld b,a : ld ix,slows
.slow   ld a,(ix+S_IMG) : cp e : scf : ret z
        push de : ld de,S_SIZE : add ix,de : pop de
        djnz .slow
        or a
        ret

; The level's palette: the BBC version's (its background colour, yellow, magenta
; and black), in each buffer's LPBs (pal0, pal1: lpt_set puts them there). Nick
; takes a pixel's two bits as the CPC's Mode 1 does, the other way round from a
; BBC byte, so the BBC's colour 1 (yellow) is colour 2 here, and its colour 2
; (magenta) colour 1, as on the CPC. (Nick's colour bytes: screen.asm.)
set_level_palette
        ld a,(level_bg) : and 7 : ld hl,bbc_colours : call look
        ld (pal0),a : ld (pal1),a
        ld hl,level_colours : ld de,pal0 + 1 : ld bc,3 : ldir
        ld hl,level_colours : ld de,pal1 + 1 : ld bc,3 : ldir
        ret
bbc_colours   db #00, #49, #92, #DB, #24, #6D, #B6, #FF ; black, red, green, yellow, blue, magenta, cyan, white
level_colours db #6D, #DB, #00          ; (colours 1-3: magenta, yellow, black)
; Show the blank table (from the next frame), and wait until it's on show, so that
; both buffers' tables can be set
level_init_blank
        call show_blank
        call wait_vsync : jp wait_vsync

; ------------------------------------------------------------------------------
; Scrolling
; ------------------------------------------------------------------------------

; The view centred on Trogg (at a level's start, or a restart)
centre_scroll
        xor a : ld (scroll_dir),a
        ld hl,(scroll_max) : srl h : rr l : srl h : rr l
        ld a,l : and #FE : ld (col_max),a       ; (a word at a time)
        ; view_col = clamp(tx - 160, 0, scroll_max) / 4
        ld hl,(tx) : ld de,-160 : add hl,de
        bit 7,h : jr z,.x_pos
        ld hl,0
.x_pos  ld de,(scroll_max) : push hl : or a : sbc hl,de : pop hl : jr c,.x_ok
        ld hl,(scroll_max)
.x_ok   srl h : rr l : srl h : rr l
        ld a,l : and #FE : ld (view_col),a
        ; view_row = clamp(ty - 128, 0, ...) / 8, at most row_max
        ld hl,(ty) : ld de,-128 : add hl,de
        bit 7,h : jr z,.y_pos
        ld hl,0
.y_pos  srl h : rr l : srl h : rr l : srl h : rr l
        ld a,h : or a : ld a,l : jr z,.y_byte
        ld a,255
.y_byte ld b,a : ld a,(row_max) : cp b : jr c,.y_ok
        ld a,b
.y_ok   ld (view_row),a
        ; (and on)
; newcol (newrow) = the column (row) the view is to scroll to
calc_scroll
        ld a,(is_vert) : or a : jr nz,.vertical
        ld a,(view_col) : ld (newcol),a
        xor a : ld (newrow),a
        ret
.vertical
        xor a : ld (newcol),a
        ld a,(view_row) : ld (newrow),a
        ret

; Banded scrolling, once per drawn frame: the view stays put while Trogg is
; between VIEW_L and VIEW_R across the window; once he's past one end, it scrolls
; a step (8 pixels) a frame (two if the frame took 4 ticks) until he's at the
; other (or the level's edge is).
band_scroll
        ; (not once he's dead: the two buffers are each drawn once more, with the
        ; FRAK! bubble, then shown in turn, so they must be at the same place)
        ld a,(dead) : or a : ret nz
        ld a,(is_vert) : or a : jp nz,band_scroll_v
        ; HL = his x in the window (signed): tx - view_col * 4
        ld a,(view_col) : ld l,a : ld h,0 : add hl,hl : add hl,hl : ex de,hl
        ld hl,(tx) : or a : sbc hl,de
        ld a,(frame_ticks) : srl a : srl a : jr nz,.n_ok
        inc a
.n_ok   ld (bs_n),a
        ld a,(scroll_dir) : or a : jp m,.left : jr nz,.right
        ; not scrolling: past either end of the band?
        bit 7,h : jr nz,.start_left
        ld a,h : or a : jr nz,.start_right
        ld a,l : cp VIEW_R + 1 : jr nc,.start_right
        cp VIEW_L : jr c,.start_left
        ret
.start_right
        ld a,1 : ld (scroll_dir),a
.right  ; (until he's at VIEW_L: not past it, or he'd set it scrolling back)
        bit 7,h : jr nz,.stop
        ld a,h : or a : jr nz,.go_right
        ld a,l : cp VIEW_L + STEP_X : jr c,.stop
.go_right
        ld a,(col_max) : ld b,a : ld a,(view_col) : cp b : jr nc,.stop
        add a,2 : ld (view_col),a
        ld de,-STEP_X : add hl,de
        ld a,(bs_n) : dec a : ld (bs_n),a : jr nz,.right
        ret
.start_left
        ld a,#FF : ld (scroll_dir),a
.left   ; (until he's at VIEW_R)
        bit 7,h : jr nz,.go_left
        ld a,h : or a : jr nz,.stop
        ld a,l : cp VIEW_R - STEP_X + 1 : jr nc,.stop
.go_left
        ld a,(view_col) : or a : jr z,.stop
        sub 2 : ld (view_col),a
        ld de,STEP_X : add hl,de
        ld a,(bs_n) : dec a : ld (bs_n),a : jr nz,.left
        ret
.stop   xor a : ld (scroll_dir),a
        ret

; ... and up and down, a character row (8 lines) at a time: the view stays put
; while his feet are between VIEW_T and VIEW_B down the window; once he's past one
; end, it scrolls a row a tick (at most 4 a frame) until he's at the other end,
; or the level's.
band_scroll_v
        ; HL = his y in the window (signed): ty - view_row * 8
        ld a,(view_row) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ex de,hl
        ld hl,(ty) : or a : sbc hl,de
        ld a,(frame_ticks) : or a : jr nz,.n_some
        inc a
.n_some cp 5 : jr c,.n_ok
        ld a,4
.n_ok   ld (bs_n),a
        ld a,(scroll_dir) : or a : jp m,.up : jr nz,.down
        bit 7,h : jr nz,.start_up
        ld a,h : or a : jr nz,.start_down
        ld a,l : cp VIEW_B + 1 : jr nc,.start_down
        cp VIEW_T : jr c,.start_up
        ret
.start_down
        ld a,1 : ld (scroll_dir),a
.down   bit 7,h : jr nz,.stop
        ld a,h : or a : jr nz,.go_down
        ld a,l : cp VIEW_T + 8 : jr c,.stop
.go_down
        ld a,(row_max) : ld b,a : ld a,(view_row) : cp b : jr nc,.stop
        inc a : ld (view_row),a
        ld de,-8 : add hl,de
        ld a,(bs_n) : dec a : ld (bs_n),a : jr nz,.down
        ret
.start_up
        ld a,#FF : ld (scroll_dir),a
.up     bit 7,h : jr nz,.go_up
        ld a,h : or a : jr nz,.stop
        ld a,l : cp VIEW_B - 8 + 1 : jr nc,.stop
.go_up  ld a,(view_row) : or a : jr z,.stop
        dec a : ld (view_row),a
        ld de,8 : add hl,de
        ld a,(bs_n) : dec a : ld (bs_n),a : jr nz,.up
        ret
.stop   xor a : ld (scroll_dir),a
        ret

; Scroll the back buffer to newcol (newrow), repainting what comes into view
do_scroll
        call calc_scroll
        ld a,(is_vert) : or a : jr nz,.vertical
.loop   ld a,(newcol) : ld b,a : ld a,(scrollcol) : cp b : ret z
        jr nc,.go_left
        ; right: the column at the right-hand edge comes into view
        inc a : ld (scrollcol),a : call set_window_clip
        ld a,(scrollcol) : add a,W_COLS - 1 : call repaint_col
        jr .loop
.go_left
        dec a : ld (scrollcol),a : call set_window_clip
        ld a,(scrollcol) : call repaint_col
        jr .loop
.vertical
        ld a,(newrow) : ld b,a : ld a,(scrollrow) : cp b : ret z
        jr nc,.go_up
        ; down: the row at the bottom comes into view
        inc a : ld (scrollrow),a : call set_window_clip
        ld a,(scrollrow) : add a,W_ROWS - 1 : call repaint_rowf
        jr .vertical
.go_up  dec a : ld (scrollrow),a : call set_window_clip
        ld a,(scrollrow) : call repaint_rowf
        jr .vertical

; The clip window = the window
set_window_clip
        ld a,(scrollcol) : ld (clip_l),a
        ld b,a : ld a,(win_cols) : add a,b : ld (clip_r),a
        ld a,(scrollrow) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld (clip_t),hl
        ld a,(win_lines) : ld (clip_h),a        ; (0: 256)
        ret

; Repaint byte column A (of a level that scrolls sideways) from the cache, then
; the scenery over it; and the moving sprites over it will need drawing again
repaint_col
        ld (pc_c),a
        call repaint_column
        ld a,(pc_c) : ld (dm_c0),a : ld (dm_c1),a
        xor a : ld (dm_y0),a : dec a : ld (dm_y1),a
        call add_damage
        ld a,(pc_c) : ld (clip_l),a : inc a : ld (clip_r),a
        call draw_scenery
        jp set_window_clip

; ... and character row A of a level that scrolls up and down (all 80 columns)
repaint_rowf
        ld (pc_c),a
        call repaint_row
        xor a : ld (dm_c0),a : ld a,79 : ld (dm_c1),a
        ld a,(pc_c) : add a,a : ld (dm_y0),a : or 1 : ld (dm_y1),a
        call add_damage
        ld a,(pc_c) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld (clip_t),hl
        ld a,8 : ld (clip_h),a
        call draw_scenery
        jp set_window_clip

; Repaint the back buffer's queued columns (collected things'): the visible ones
; (the rest will be repainted when they scroll into view)
do_pending
        ld a,(back) : ld e,a : ld d,0
        ld hl,pend_lo : add hl,de : ld b,(hl)
        ld hl,pend_hi : add hl,de : ld c,(hl)
        ld a,b : cp c : ret nc
        ; pc_col = max(pend_lo, scrollcol), pc_end = min(pend_hi, scrollcol + the window)
        ld a,(scrollcol) : cp b : jr c,.lo_ok
        ld b,a
.lo_ok  ld a,b : ld (pc_col),a
        ld a,(scrollcol) : ld b,a : ld a,(win_cols) : add a,b : ld b,a
        ld a,c : cp b : jr nc,.hi_ok
        ld b,a
.hi_ok  ld a,b : ld (pc_end),a
        ld hl,pend_lo : add hl,de : ld (hl),#FF
        ld hl,pend_hi : add hl,de : ld (hl),0
        ld a,(is_vert) : or a : jr z,.loop
        ; (a level that scrolls up and down: just the window's rows of those columns)
        ld a,(pc_col) : ld (rr_c0),a
        ld a,(pc_end) : dec a : ld (rr_c1),a
        ld a,(scrollrow) : ld (rr_k0),a : add a,W_ROWS - 1 : ld (rr_k1),a
        jp repaint_rect
.loop   ld a,(pc_end) : ld b,a : ld a,(pc_col) : cp b : ret nc
        call repaint_col
        ld hl,pc_col : inc (hl)
        jr .loop

; Repaint character cells [rr_k0, rr_k1] of byte columns [rr_c0, rr_c1] (all
; visible) from the cache, then the scenery over them. This is how moving
; platforms and meanies are erased. Records damage for what it covers.
repaint_rect
        ld a,(is_vert) : or a : jr nz,.by_rows
        ld a,(rr_k0) : ld (pl_i0),a : ld a,(rr_k1) : ld (pl_i1),a
        ld a,(rr_c0)
.col    ld (rr_i),a : ld (pl_line),a
        ld a,(rr_k0) : ld l,a : ld a,(rr_i) : call cell_at
        call paint_line
        ld a,(rr_c1) : ld b,a : ld a,(rr_i) : cp b : jr z,.done
        inc a : jr .col
.by_rows
        ld a,(rr_c0) : ld (pl_i0),a : ld a,(rr_c1) : ld (pl_i1),a
        ld a,(rr_k0)
.row    ld (rr_i),a : ld (pl_line),a
        ld l,a : ld a,(rr_c0) : call cell_at
        call paint_line
        ld a,(rr_k1) : ld b,a : ld a,(rr_i) : cp b : jr z,.done
        inc a : jr .row
.done   ; the damage, then the scenery over it, clipped to it
        ld a,(rr_c0) : ld (dm_c0),a : ld (clip_l),a
        ld a,(rr_c1) : ld (dm_c1),a : inc a : ld (clip_r),a
        ld a,(rr_k0) : add a,a : ld (dm_y0),a
        ld a,(rr_k1) : add a,a : or 1 : ld (dm_y1),a
        call add_damage
        ld a,(rr_k0) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld (clip_t),hl
        ld a,(rr_k0) : ld b,a : ld a,(rr_k1) : sub b : inc a
        add a,a : add a,a : add a,a : ld (clip_h),a     ; (256 = 0)
        call draw_scenery
        jp set_window_clip
; pl_ptr = the back buffer's address of character row L's first line, byte
; column A (plot.asm's col_place and col_addr: the ring's row and byte for it)
cell_at push af
        ld a,l : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld (p_firsty),hl
        pop af : call col_place : call col_addr
        ld (pl_ptr),bc
        ret

; Draw every scenery item (key, gem, bulb, meanie that doesn't move) that
; overlaps the clip window
draw_scenery
        ld a,PM_PLOT : ld (p_mode),a
        ld a,(num_draw) : or a : ret z
        ld b,a
        ld a,(clip_r) : ld (.cr + 1),a          ; (the byte columns, in the compares below)
        ld a,(clip_l) : ld (.cl + 1),a
        ld hl,alive : ld de,dcols : ld ix,draws
.loop   ld a,(hl) : or a : jr z,.skip           ; (collected)
        ld a,(de)                               ; its first byte column ...
.cr     cp 0 : jr nc,.skip                      ; (at or after clip_r)
        inc de : ld a,(de) : dec de             ; ... and the one after its last
.cl     cp 0 : jr c,.skip : jr z,.skip          ; (at or before clip_l)
        push bc : push de : push hl
        call .rows
        pop hl : pop de : pop bc
.skip   inc hl : inc de : inc de
        push de : ld de,D_SIZE : add ix,de : pop de
        djnz .loop
        ret
; ... in the rows too? (skip it if it ends above clip_t, or starts at or below
; clip_t + clip_h) Then plot it.
.rows   ld a,(ix+D_IMG) : ld hl,img_h : call look : ld e,a : ld d,0
        ld l,(ix+D_TL) : ld h,(ix+D_TH) : add hl,de : ex de,hl
        ld hl,(clip_t) : call signed_less : ret nc
        ld a,(clip_h) : ld e,a : ld d,0 : or a : jr nz,.h_ok
        inc d                                   ; (0 = 256)
.h_ok   ld hl,(clip_t) : add hl,de : ex de,hl
        ld l,(ix+D_TL) : ld h,(ix+D_TH) : call signed_less : ret nc
        ld a,(ix+D_IMG) : ld (p_img),a
        ld l,(ix+D_XL) : ld h,(ix+D_XH) : ld (p_x),hl
        ld l,(ix+D_YL) : ld h,(ix+D_YH) : ld (p_y),hl
        push ix : call plot : pop ix
        ret

; Note damage dm_c0..dm_c1, dm_y0..dm_y1 (byte columns, 4-line rows)
add_damage
        ld a,(dmg_n) : cp MAX_DMG : jr nc,.full
        inc a : ld (dmg_n),a : dec a
        add a,a : add a,a : ld e,a : ld d,0 : ld hl,dmg_list : add hl,de
        ld a,(dm_c0) : ld (hl),a : inc hl
        ld a,(dm_c1) : ld (hl),a : inc hl
        ld a,(dm_y0) : ld (hl),a : inc hl
        ld a,(dm_y1) : ld (hl),a
        ret
.full   ld a,1 : ld (dmg_all),a
        ret

; ------------------------------------------------------------------------------
; Drawing the slow sprites. They stay drawn in each screen buffer, which
; remembers where it drew each one (drecs). A slow sprite is only redrawn when it
; has moved since that buffer last drew it, or something painted over it.
;
; Erasing one repaints its character cells from the background cache (and the
; scenery over them). Everything repainted in a frame - scrolled-in columns,
; collected objects' columns, erased sprites - goes in the damage list, and every
; slow sprite overlapping damage is plotted again, in order, so overlaps stay
; right. Each one plotted is damage too, for the ones after it.
; ------------------------------------------------------------------------------

; IY = slow sprite A's drawn record in the back buffer
dr_iy   ld l,a : ld a,(back) : or a : ld a,l : jr z,.b0
        add a,MAX_SLOW
.b0     ld l,a : ld h,0 : ld d,h : ld e,l
        add hl,hl : add hl,hl : add hl,hl : add hl,de
        ld de,drecs : add hl,de : push hl : pop iy
        ret
; HL = n_vis + A, n_chg + A
nvis_hl ld hl,n_vis : jr idx_hl
nchg_hl ld hl,n_chg
idx_hl  add a,l : ld l,a : ret nc
        inc h : ret

; Where slow sprite IX/IY would be drawn (from where it's shown). Carry set if
; any of it is in the window, with its byte columns in nr_c0..nr_c1 and rows in
; nr_y0..nr_y1 (4-line rows, inclusive, clamped to the level)
slow_rect
        ld a,(ix+SR_ALIVE) : or a : ret z
        ld a,(ix+S_IMG) : ld l,(ix+SR_DXL) : ld h,(ix+SR_DXH) : call box_from_x
        ld de,(box_r) : dec de
        sra h : rr l : sra h : rr l             ; left and right, as byte columns
        sra d : rr e : sra d : rr e
        ; visible if right >= clip_l and left < clip_r
        bit 7,d : jp nz,.out
        ld a,d : or a : jr nz,.r_ok
        ld a,(clip_l) : ld b,a : ld a,e : cp b : jr c,.out
.r_ok   bit 7,h : jr nz,.l_neg
        ld a,h : or a : jr nz,.out
        ld a,(clip_r) : ld b,a : ld a,l : cp b : jr nc,.out
        ld (nr_c0),a : jr .have_l
.l_neg  xor a : ld (nr_c0),a
.have_l ld a,d : or a : ld a,e : jr z,.r_byte
        ld a,255
.r_byte ld (nr_c1),a
        ; top and bottom: visible if bottom >= clip_t and top < clip_t + 256
        ld a,(ix+S_IMG) : ld l,(ix+SR_DYL) : ld h,(ix+SR_DYH) : call box_from_y
        ld (sr_top),hl
        ld hl,(box_r) : dec hl : ld (sr_bot),hl
        ld de,(clip_t) : call signed_less : jr c,.out
        ld de,(clip_t) : inc d : ld hl,(sr_top) : call signed_less : jr nc,.out
        ld hl,(sr_bot) : srl h : rr l : srl h : rr l : ld a,l : ld (nr_y1),a
        ld hl,(sr_top) : xor a : bit 7,h : jr nz,.t_neg
        srl h : rr l : srl h : rr l : ld a,l
.t_neg  ld (nr_y0),a
        scf : ret
.out    or a : ret

; Bring the slow sprites in the back buffer up to date
draw_slow
        ; (just the level's slow sprites: no others are ever drawn)
        ld a,(num_slow) : or a : ret z
        ; 1. Erase the ones that have moved, or gone
        dec a : ld (sl_i),a
.erase_loop
        ld a,(sl_i) : call nchg_hl : ld (hl),0
        ld a,(sl_i) : call slow_both
        call slow_rect : ld a,0 : rla : ld b,a  ; (carry: visible)
        ld a,(sl_i) : call nvis_hl : ld (hl),b
        ld a,(sl_i) : call dr_iy
        ld a,b : or a : jr nz,.vis
        ; not visible: erase it if it was drawn
        ld a,(iy+DR_ON) : or a : jp z,.e_next
        jr .erase
.vis    ld a,(iy+DR_ON) : or a : jr z,.new
        ld a,(ix+SR_DXL) : cp (iy+DR_XL) : jr nz,.moved
        ld a,(ix+SR_DXH) : cp (iy+DR_XH) : jr nz,.moved
        ld a,(ix+SR_DYL) : cp (iy+DR_YL) : jr nz,.moved
        ld a,(ix+SR_DYH) : cp (iy+DR_YH) : jr nz,.moved
        jr .e_next
.moved  ld a,(sl_i) : call nchg_hl : ld (hl),1
.erase  call erase_drawn
        ld a,(sl_i) : call nchg_hl : ld a,(hl) : or a : jr z,.e_next   ; gone: nothing to draw
.new    ld a,(sl_i) : call nchg_hl : ld (hl),1
        ; it will be drawn here
        ld a,(sl_i) : call slow_both : ld a,(sl_i) : call dr_iy
        ld a,(ix+SR_DXL) : ld (iy+DR_XL),a : ld a,(ix+SR_DXH) : ld (iy+DR_XH),a
        ld a,(ix+SR_DYL) : ld (iy+DR_YL),a : ld a,(ix+SR_DYH) : ld (iy+DR_YH),a
        ld a,(nr_c0) : ld (iy+DR_C0),a : ld a,(nr_c1) : ld (iy+DR_C1),a
        ld a,(nr_y0) : ld (iy+DR_Y0),a : ld a,(nr_y1) : ld (iy+DR_Y1),a
        ld (iy+DR_ON),1
.e_next ld hl,sl_i : dec (hl) : jp p,.erase_loop

        ; 2. Plot, in order, the ones that moved and the ones painted over
        xor a : ld (sl_i),a
.plot_loop
        ld a,(sl_i) : call nvis_hl : ld a,(hl) : or a : jr z,.p_next
        ld a,(sl_i) : call nchg_hl : ld a,(hl) : or a : jr nz,.plot_it
        ld a,(dmg_all) : or a : jr nz,.plot_it
        ld a,(sl_i) : call dr_iy : call damaged : jr nc,.p_next
.plot_it
        ld a,(sl_i) : call slow_both
        ld a,(ix+S_IMG) : ld (p_img),a
        ld l,(ix+SR_DXL) : ld h,(ix+SR_DXH) : ld (p_x),hl
        ld l,(ix+SR_DYL) : ld h,(ix+SR_DYH) : ld (p_y),hl
        ld a,PM_PLOT : ld (p_mode),a
        call plot_slow
        ; ... which is damage for the ones after it
        ld a,(sl_i) : call dr_iy
        ld a,(iy+DR_C0) : ld (dm_c0),a : ld a,(iy+DR_C1) : ld (dm_c1),a
        ld a,(iy+DR_Y0) : ld (dm_y0),a : ld a,(iy+DR_Y1) : ld (dm_y1),a
        call add_damage
.p_next ld a,(num_slow) : ld b,a
        ld hl,sl_i : inc (hl) : ld a,(hl) : cp b : jr nz,.plot_loop
        ret

; Erase the slow sprite drawn at record IX (the visible part of it) and forget it
erase_drawn
        ld (iy+DR_ON),0
        ld a,(clip_l) : ld b,a : ld a,(iy+DR_C0) : cp b : jr nc,.c0
        ld a,b
.c0     ld (rr_c0),a
        ld a,(clip_r) : dec a : ld b,a : ld a,(iy+DR_C1) : cp b : jr c,.c1
        ld a,b
.c1     ld (rr_c1),a
        ld b,a : ld a,(rr_c0) : ld c,a : ld a,b : cp c : ret c
        ; its character rows, within the window's
        ld a,(iy+DR_Y0) : srl a : ld b,a : ld a,(scrollrow) : cp b : jr nc,.k0
        ld a,b
.k0     ld (rr_k0),a
        ld a,(win_rows) : dec a : ld b,a : ld a,(scrollrow) : add a,b : ld b,a
        ld a,(iy+DR_Y1) : srl a : cp b : jr c,.k1
        ld a,b
.k1     ld (rr_k1),a
        ld b,a : ld a,(rr_k0) : ld c,a : ld a,b : cp c : ret c
        jp repaint_rect

; Carry set if drawn record IX overlaps any damage
damaged ld a,(dmg_n) : or a : ret z
        ld b,a : ld hl,dmg_list
.loop   ld a,(iy+DR_C1) : cp (hl) : jr c,.n0            ; ends left of it
        inc hl : ld a,(hl) : cp (iy+DR_C0) : jr c,.n1   ; starts right of it
        inc hl : ld a,(iy+DR_Y1) : cp (hl) : jr c,.n2   ; ends above it
        inc hl : ld a,(hl) : cp (iy+DR_Y0) : jr c,.n3   ; starts below it
        scf : ret
.n0     inc hl
.n1     inc hl
.n2     inc hl
.n3     inc hl
        djnz .loop
        or a : ret

; ------------------------------------------------------------------------------
; The HUD, springs, and the level-complete screen
; ------------------------------------------------------------------------------

; The timer at the top left of the window, and the rating at the bottom right.
; The timer is an image (IMG_Hud, raw: see plot) made from the font each second.
draw_hud
        ld hl,(lvl_ticks) : ld a,50 : call div16        ; (seconds)
        ld de,(hud_secs) : or a : sbc hl,de : add hl,de : jr z,.same
        ld (hud_secs),hl
        call time_digits
        ; each character two byte columns of 8 rows: the glyph's left and right nibbles
        ld hl,hud_image : ld ix,time_text : ld b,4
.char   ld a,(ix+0) : sub '0' : add a,a : add a,a : add a,a
        ld e,a : ld d,0 : push hl : ld hl,font_digits : add hl,de : ex de,hl : pop hl
        ld c,8
.row    ld a,(de) : rrca : rrca : rrca : rrca : and 15 : ld (hl),a
        push hl : ld a,l : add a,8 : ld l,a : jr nc,.nc
        inc h
.nc     ld a,(de) : and 15 : ld (hl),a : pop hl
        inc hl : inc de : dec c : jr nz,.row
        ld de,8 : add hl,de
        inc ix : djnz .char
.same   ld a,IMG_Hud : ld (p_img),a
        ld a,(scrollcol) : ld l,a : ld h,0 : add hl,hl : add hl,hl
        ld de,4 : add hl,de : ld (p_x),hl
        ld hl,(clip_t) : inc hl : inc hl : ld (p_y),hl
        call log_sprite
        ld a,(restarts) : cp 3 : jr c,.r_ok
        ld a,3
.r_ok   add a,IMG_Rating_1 : ld (p_img),a
        ld hl,(p_x) : ld de,(win_w128) : add hl,de : ld de,-128 - 12 : add hl,de : ld (p_x),hl
        ld a,(win_lines) : dec a : ld e,a : ld d,0      ; (the window's last line: 255)
        ld hl,(clip_t) : add hl,de : ld (p_y),hl
        jp log_sprite

; HL = HL / A, the remainder in A
div16   ld c,a : xor a : ld b,16
.loop   add hl,hl : rla : cp c : jr c,.no
        sub c : inc l
.no     djnz .loop
        ret

; time_text = "m:ss" for HL seconds (at most 9:59)
time_digits
        ld de,600 : push hl : or a : sbc hl,de : pop hl : jr c,.ok
        ld hl,599
.ok     ld a,60 : call div16 : ld b,a                   ; (HL = minutes, B = seconds)
        ld a,l : add a,'0' : ld (time_text),a
        ld a,':' : ld (time_text + 1),a
        ld a,b : ld c,'0' - 1
.tens   inc c : sub 10 : jr nc,.tens
        add a,10 + '0' : ld (time_text + 3),a
        ld a,c : ld (time_text + 2),a
        ret

; The springs of the bouncy platforms that move (they can't be in the background
; like the others), and the yellow line under a platform Trogg can move
draw_springs
        ld a,(num_plats) : or a : ret z
        ld (spr_i),a : dec a : call plat_ix : push ix : pop iy     ; (IY: the last, going down)
.loop   ld a,(iy+PLT_MOVING) : or a : jr z,.next
        cp 2 : jr nz,.spring
        ; the line, from x to x + w - 1, on the row under it
        ld l,(iy+PLT_XL) : ld h,(iy+PLT_XH) : ld (p_x),hl
        ld e,(iy+PLT_W) : ld d,0 : add hl,de : dec hl : ld (q_x),hl
        ld a,(iy+PLT_IMG) : ld hl,img_h : call look : ld e,a : ld d,0
        ld l,(iy+PLT_YL) : ld h,(iy+PLT_YH) : add hl,de : ld (p_y),hl
        ld a,#F0 : ld (hl_yel),a
        call log_line
        xor a : ld (hl_yel),a
.spring ld a,(iy+PLT_BOUNCY) : or a : jr z,.next
        call spring_pos
        ld a,IMG_Spring : ld (p_img),a
        call log_sprite
.next   ld de,-PLT_SIZE : add iy,de
        ld hl,spr_i : dec (hl) : jr nz,.loop
        ret

; The level-complete screen, drawn once into each buffer: just Trogg (and his
; trophy if there's a medal) on the background colour; then the time, the gems
; and the medal's text (the front end's fe_win, in phase 7). Both buffers are put at
; the view's scroll position first, as they're then shown in turn.
win_screen
        call calc_scroll
        ld a,(back) : ld e,a : ld d,0
        ld a,(newcol) : ld (scrollcol),a : ld hl,bscroll : add hl,de : ld (hl),a
        ld a,(newrow) : ld (scrollrow),a : ld hl,brow : add hl,de : ld (hl),a
        ld hl,bwon : add hl,de : ld (hl),1
        ld hl,log_n : add hl,de : ld (hl),0     ; (nothing to erase from it now)
        call set_window_clip
        call fill_back
        ld a,PM_PLOT : ld (p_mode),a
        call trogg_image : ld e,a : ld d,0
        ld hl,img_part_b : add hl,de : ld a,(hl) : ld (t_part_b),a
        ld hl,img_part_a : add hl,de : ld a,(hl) : ld (p_img),a
        ld hl,(tx) : ld (p_x),hl : ld hl,(ty) : ld (p_y),hl
        call plot
        ld a,(t_part_b) : cp 255 : jr z,.one_part
        ld (p_img),a : call plot
.one_part
        ld a,(done_restarts) : cp 3 : jr nc,.text
        add a,IMG_Rating_1 : ld (p_img),a
        ld hl,(tx) : ld de,21 : add hl,de : ld (p_x),hl
        ld hl,(ty) : ld de,-23 : add hl,de : ld (p_y),hl
        call plot
        ld a,IMG_TrophyStand : ld (p_img),a
        call plot
.text   ; then the time, the gems and the medal (the front end's fe_win)
        call fe_done
        ld hl,fe_win : jp front_call

; ------------------------------------------------------------------------------
; The moving objects, the yoyo
; ------------------------------------------------------------------------------

; Balloons, daggers and meanies flying off, in the draw log (skipping any well
; outside the window)
draw_movers
        ; mv_left = the window's left edge - 64
        ld a,(scrollcol) : ld l,a : ld h,0 : add hl,hl : add hl,hl
        ld de,-64 : add hl,de : ld (mv_left),hl
        xor a : ld (dm_i),a
.loop   ld a,(dm_i) : call mv_iy
        ld a,(iy+M_ACTIVE) : or a : jr z,.next
        ; skip it unless mv_left <= x < mv_left + the window + 128
        ld l,(iy+M_XL) : ld h,(iy+M_XH) : ld de,(mv_left) : or a : sbc hl,de
        bit 7,h : jr nz,.next
        ld de,(win_w128) : or a : sbc hl,de : jr nc,.next
        ld a,(iy+M_IMG) : ld (p_img),a
        ld l,(iy+M_XL) : ld h,(iy+M_XH) : ld (p_x),hl
        ld l,(iy+M_YL) : ld h,(iy+M_YH) : ld (p_y),hl
        ld a,(iy+M_ACTIVE) : cp MV_FLYING : jr z,.big
        call log_sprite
        jr .next
.big    call log_sprite7                        ; (meanies are big: saved in the slow save area)
.next   ld hl,dm_i : inc (hl) : ld a,(hl) : cp MAX_MOVERS : jr nz,.loop
        ret

; The string runs from Trogg's hand (tx + 12 * direction) to the yoyo, on the
; row just above the yoyo's base
yoyo_string_params
        ld hl,(yo_x) : ld (q_x),hl
        ld hl,(tx) : ld de,12
        ld a,(tface) : or a : jr z,.right
        ld de,-12
.right  add hl,de : ld (p_x),hl
        ld hl,(yo_y) : dec hl : ld (p_y),hl
        ret

; The yoyo's frame: ((length * direction) >> 3) AND 3, as in GameMaker
yoyo_image
        ld a,(yo_len+1) : ld b,a
        ld a,(tface) : or a : ld a,b : jr z,.right
        neg : sra a : sra a : sra a
        jr .frame
.right  srl a : srl a : srl a
.frame  and 3 : add a,IMG_Yoyo_0
        ret
