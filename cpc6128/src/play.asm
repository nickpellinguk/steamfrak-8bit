; The game being played: the frame loop, scrolling and drawing. A port of the
; BBC version's main_loop and what it calls (band_scroll, do_scroll, do_pending,
; draw_slow and the rest), in the logic bank with game_tick.
;
; Each frame, in the buffer that isn't on show:
;   1. erase everything drawn there last time (restore_log), and repaint what's
;      changed under it: columns (or rows) scrolled into view, collected things
;   2. bring the moving platforms and meanies up to date (draw_slow)
;   3. draw the moving things - balloons, daggers and meanies flying off, the
;      yoyo and its string, Trogg, and his FRAK! bubble - saving the background
;      under each (the draw log)
; then show it once two vertical syncs have passed since the last flip, and run
; a tick of game logic for each vertical sync since then.
;
; The CPC's window is 256x256 for a level that scrolls sideways (64 byte columns,
; 32 character rows) and 320x200 for one that scrolls up and down (80 columns,
; 25 rows). The CRTC starts the screen on a word, so sideways the view moves 8
; pixels (2 byte columns) at a time, where the BBC version's moves 4.

FRAMES_PER_DRAW = 2                 ; vertical syncs per drawn frame
MAX_TICKS_PER_FRAME = 4
VIEW_L = 96 : VIEW_R = 160          ; the band Trogg moves in without the view scrolling,
VIEW_T = 72 : VIEW_B = 136          ; across a 256-pixel window, down a 200-line one
STEP_X = 8                          ; (pixels a sideways scroll step moves)
MAX_DMG = 40
SLOWSAVE0 = #6A00                   ; the slow save areas, in the cache bank above the cache
SLOWSAVE1 = #7500
SLOWSAVE_SIZE = #0B00
SAVE_SIZE = 1024
; a slow sprite as drawn in a buffer
DR_ON = 0 : DR_XL = 1 : DR_XH = 2 : DR_YL = 3 : DR_YH = 4
DR_C0 = 5 : DR_C1 = 6 : DR_Y0 = 7 : DR_Y1 = 8                ; its byte columns, and 4-line rows
DR_SIZE = 9

; Play, from level A (the test harness's command 13). Never returns.
play    call begin_level
frame_loop
        ld a,(front) : xor 1 : ld (back),a
        call set_back_page
        ld a,(back) : ld hl,bscroll : call look : ld (scrollcol),a
        ld a,(back) : ld hl,brow : call look : ld (scrollrow),a
        call set_window_clip
        ; Once Trogg has won, or is dead and this buffer already shows the FRAK!
        ; bubble, nothing changes, so don't redraw
        ld a,(won) : or a : jp nz,.show         ; (phase 6b: the level-complete screen)
        ld a,(dead) : or a : jr z,.redraw
        ld a,(back) : ld hl,bfrak : call look : or a : jp nz,.show
.redraw xor a : ld (dmg_n),a : ld (dmg_all),a  ; nothing repainted yet this frame
        call restore_log
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
        ld a,RAM_BANK + CACHE_BANK : ld (p_sbank),a
        ; moving platforms and meanies stay drawn in each buffer: only the ones that
        ; moved (or were painted over) are drawn again
        call commit_all
        call draw_slow
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
        ; ... and "FRAK!" at (x + 12, y - 26) if he's dead
        ld a,(back) : ld e,a : ld d,0 : ld hl,bfrak : add hl,de
        ld a,(dead) : ld (hl),a : or a : jr z,.show
        ld a,IMG_Frak : ld (p_img),a
        ld hl,(tx) : ld de,12 : add hl,de : ld (p_x),hl
        ld hl,(ty) : ld de,-26 : add hl,de : ld (p_y),hl
        call log_sprite

.show   ; (the test harness can hold each frame to look at it, and then the game
        ; runs two ticks a frame)
        ld a,(t_lock) : or a : jr z,.wait
        ld a,1 : ld (t_frame),a
.hold   ld a,(t_frame) : or a : jr nz,.hold
        call flip
        ld a,(vsyncs) : ld (last_flip),a
        ld a,FRAMES_PER_DRAW : jr .ticks
.wait   ; show it once FRAMES_PER_DRAW vertical syncs have passed since the last flip
        ld a,(last_flip) : ld b,a
        ld a,(vsyncs) : sub b : cp FRAMES_PER_DRAW : jr c,.wait
        call flip
        ; run a tick of game logic for each vertical sync since the last flip (at most
        ; MAX_TICKS_PER_FRAME, so a long pause such as a full redraw doesn't jump ahead)
        ld a,(last_flip) : ld b,a
        ld a,(vsyncs) : ld (last_flip),a
        sub b : cp MAX_TICKS_PER_FRAME + 1 : jr c,.ticks
        ld a,MAX_TICKS_PER_FRAME
.ticks  ld (ticks_left),a : ld (frame_ticks),a
.tick   call game_tick
        jr z,.next_tick
        cp TICK_WON : jr z,.next_level
        cp TICK_QUIT : jr z,.quit
        call restore_checkpoint                 ; TICK_DIED: back to the checkpoint
        call redraw
        jp frame_loop
.next_level
        ld a,(cur_level) : inc a : call begin_level
        jp frame_loop
.quit   ld a,(cur_level) : call begin_level     ; (phase 8: back to the menus)
        jp frame_loop
.next_tick
        ld hl,ticks_left : dec (hl) : jr nz,.tick
        jp frame_loop

; Show the back buffer, scrolled to its position, at the next frame
flip    ld a,(scrollrow) : ld l,a : ld h,rowoff_lo >> 8 : ld e,(hl) : inc h : ld d,(hl)
        ld a,(scrollcol) : ld l,a : ld h,0 : add hl,de
        ld a,h : and 7 : ld h,a
        ld a,(back) : call show_at
        ld a,(back) : ld (front),a
        ret

set_back_page
        ld a,(back) : or a : ld a,#80 : jr z,.page
        ld a,#C0
.page   ld (back_page),a
        ret

; ------------------------------------------------------------------------------
; Starting a level, and drawing it from scratch
; ------------------------------------------------------------------------------

; Load level A (the first if it's past the last), and start it
begin_level
        cp NUM_LEVELS : jr c,.in_range
        xor a
.in_range
        push af : ld hl,black_palette : call set_palette : pop af   ; (hide the loading)
        call load_level
        ld a,(is_vert) : call set_mode
        ld a,(is_vert) : or a
        ld a,64 : ld b,0 : ld de,256 + 128 : ld c,32 : jr z,.window
        ld a,80 : ld b,200 : ld de,320 + 128 : ld c,25
.window ld (win_cols),a : ld a,b : ld (win_lines),a : ld (win_w128),de
        ld a,c : ld (win_rows),a
        call level_init
        ; (and on)

; Draw both buffers from scratch, centred on Trogg (the state part of the BBC
; version's redraw_all is reset_play, which restore_checkpoint and level_init end with)
redraw
        call set_level_palette
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
        ld a,1 : ld (front),a                   ; buffer 0 is drawn first
        ret

; The level's palette: the BBC version's (its background colour, yellow, magenta
; and black)
set_level_palette
        ld a,(level_bg) : and 7 : ld hl,bbc_colours : call look
        ld (level_palette),a
        ld hl,level_palette : jp set_palette
bbc_colours   db #54, #4C, #52, #4A, #55, #4D, #53, #4B ; black, red, green, yellow, blue, magenta, cyan, white
level_palette db 0, #4A, #4D, #54, #54
black_palette db #54, #54, #54, #54, #54

; ------------------------------------------------------------------------------
; Scrolling
; ------------------------------------------------------------------------------

; The view centred on Trogg (at a level's start, or a restart)
centre_scroll
        xor a : ld (scroll_dir),a
        ld hl,(scroll_max) : srl h : rr l : srl h : rr l
        ld a,l : and #FE : ld (col_max),a       ; (a word at a time)
        ; view_col = clamp(tx - 128, 0, scroll_max) / 4
        ld hl,(tx) : ld de,-128 : add hl,de
        bit 7,h : jr z,.x_pos
        ld hl,0
.x_pos  ld de,(scroll_max) : push hl : or a : sbc hl,de : pop hl : jr c,.x_ok
        ld hl,(scroll_max)
.x_ok   srl h : rr l : srl h : rr l
        ld a,l : and #FE : ld (view_col),a
        ; view_row = clamp(ty - 100, 0, ...) / 8, at most row_max
        ld hl,(ty) : ld de,-100 : add hl,de
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
        ld a,(scrollcol) : add a,63 : call repaint_col
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
        ld a,(scrollrow) : add a,24 : call repaint_rowf
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
        ld a,(scrollrow) : ld (rr_k0),a : add a,24 : ld (rr_k1),a
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
; pl_ptr = the back buffer's address of character row L, byte column A
cell_at ld h,rowoff_lo >> 8 : ld e,(hl) : inc h : ld d,(hl)
        add a,e : ld e,a : jr nc,.nc
        inc d
.nc     ld a,d : and 7 : ld d,a
        ld a,(back_page) : or d : ld d,a
        ld (pl_ptr),de
        ret

; Draw every scenery item (key, gem, bulb, meanie that doesn't move) that
; overlaps the clip window
draw_scenery
        ld a,PM_PLOT : ld (p_mode),a
        xor a : ld (ds_i),a
.loop   ld a,(ds_i) : call alive_hl : ld a,(hl) : or a : jr z,.skip   ; (collected)
        ld a,(ds_i) : call draw_ix
        ld a,(clip_l) : ld b,a : ld a,(ix+D_C1) : cp b : jr c,.skip : jr z,.skip
        ld a,(clip_r) : ld b,a : ld a,(ix+D_C0) : cp b : jr nc,.skip
        ; rows: skip it if it ends above clip_t, or starts at or below clip_t + clip_h
        ld a,(ix+D_IMG) : ld hl,img_h : call look : ld e,a : ld d,0
        ld l,(ix+D_TL) : ld h,(ix+D_TH) : add hl,de : ex de,hl
        ld hl,(clip_t) : call signed_less : jr nc,.skip
        ld a,(clip_h) : ld e,a : ld d,0 : or a : jr nz,.h_ok
        inc d                                   ; (0 = 256)
.h_ok   ld hl,(clip_t) : add hl,de : ex de,hl
        ld l,(ix+D_TL) : ld h,(ix+D_TH) : call signed_less : jr nc,.skip
        ld a,(ix+D_IMG) : ld (p_img),a
        ld l,(ix+D_XL) : ld h,(ix+D_XH) : ld (p_x),hl
        ld l,(ix+D_YL) : ld h,(ix+D_YH) : ld (p_y),hl
        call plot
.skip   ld a,(num_draw) : ld b,a
        ld a,(ds_i) : inc a : ld (ds_i),a : cp b : jp c,.loop
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

; IX = slow sprite A's drawn record in the back buffer
dr_ix   ld l,a : ld a,(back) : or a : ld a,l : jr z,.b0
        add a,MAX_SLOW
.b0     ld l,a : ld h,0 : ld d,h : ld e,l
        add hl,hl : add hl,hl : add hl,hl : add hl,de
        ld de,drecs : add hl,de : push hl : pop ix
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
        ld a,(iy+SR_ALIVE) : or a : ret z
        ld a,(ix+S_IMG) : ld l,(iy+SR_DXL) : ld h,(iy+SR_DXH) : call box_from_x
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
        ld a,(ix+S_IMG) : ld l,(iy+SR_DYL) : ld h,(iy+SR_DYH) : call box_from_y
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
        ; 1. Erase the ones that have moved, or gone
        ld a,MAX_SLOW - 1 : ld (sl_i),a
.erase_loop
        ld a,(sl_i) : call nchg_hl : ld (hl),0
        ld a,(sl_i) : call slow_both
        call slow_rect : ld a,0 : rla : ld b,a  ; (carry: visible)
        ld a,(sl_i) : call nvis_hl : ld (hl),b
        ld a,(sl_i) : call dr_ix
        ld a,b : or a : jr nz,.vis
        ; not visible: erase it if it was drawn
        ld a,(ix+DR_ON) : or a : jp z,.e_next
        jr .erase
.vis    ld a,(ix+DR_ON) : or a : jr z,.new
        ld a,(iy+SR_DXL) : cp (ix+DR_XL) : jr nz,.moved
        ld a,(iy+SR_DXH) : cp (ix+DR_XH) : jr nz,.moved
        ld a,(iy+SR_DYL) : cp (ix+DR_YL) : jr nz,.moved
        ld a,(iy+SR_DYH) : cp (ix+DR_YH) : jr nz,.moved
        jr .e_next
.moved  ld a,(sl_i) : call nchg_hl : ld (hl),1
.erase  call erase_drawn
        ld a,(sl_i) : call nchg_hl : ld a,(hl) : or a : jr z,.e_next   ; gone: nothing to draw
.new    ld a,(sl_i) : call nchg_hl : ld (hl),1
        ; it will be drawn here
        ld a,(sl_i) : call slow_both : ld a,(sl_i) : call dr_ix
        ld a,(iy+SR_DXL) : ld (ix+DR_XL),a : ld a,(iy+SR_DXH) : ld (ix+DR_XH),a
        ld a,(iy+SR_DYL) : ld (ix+DR_YL),a : ld a,(iy+SR_DYH) : ld (ix+DR_YH),a
        ld a,(nr_c0) : ld (ix+DR_C0),a : ld a,(nr_c1) : ld (ix+DR_C1),a
        ld a,(nr_y0) : ld (ix+DR_Y0),a : ld a,(nr_y1) : ld (ix+DR_Y1),a
        ld (ix+DR_ON),1
.e_next ld hl,sl_i : dec (hl) : jp p,.erase_loop

        ; 2. Plot, in order, the ones that moved and the ones painted over
        xor a : ld (sl_i),a
.plot_loop
        ld a,(sl_i) : call nvis_hl : ld a,(hl) : or a : jr z,.p_next
        ld a,(sl_i) : call nchg_hl : ld a,(hl) : or a : jr nz,.plot_it
        ld a,(dmg_all) : or a : jr nz,.plot_it
        ld a,(sl_i) : call dr_ix : call damaged : jr nc,.p_next
.plot_it
        ld a,(sl_i) : call slow_both
        ld a,(ix+S_IMG) : ld (p_img),a
        ld l,(iy+SR_DXL) : ld h,(iy+SR_DXH) : ld (p_x),hl
        ld l,(iy+SR_DYL) : ld h,(iy+SR_DYH) : ld (p_y),hl
        ld a,PM_PLOT : ld (p_mode),a
        call plot_slow
        ; ... which is damage for the ones after it
        ld a,(sl_i) : call dr_ix
        ld a,(ix+DR_C0) : ld (dm_c0),a : ld a,(ix+DR_C1) : ld (dm_c1),a
        ld a,(ix+DR_Y0) : ld (dm_y0),a : ld a,(ix+DR_Y1) : ld (dm_y1),a
        call add_damage
.p_next ld hl,sl_i : inc (hl) : ld a,(hl) : cp MAX_SLOW : jr nz,.plot_loop
        ret

; Erase the slow sprite drawn at record IX (the visible part of it) and forget it
erase_drawn
        ld (ix+DR_ON),0
        ld a,(clip_l) : ld b,a : ld a,(ix+DR_C0) : cp b : jr nc,.c0
        ld a,b
.c0     ld (rr_c0),a
        ld a,(clip_r) : dec a : ld b,a : ld a,(ix+DR_C1) : cp b : jr c,.c1
        ld a,b
.c1     ld (rr_c1),a
        ld b,a : ld a,(rr_c0) : ld c,a : ld a,b : cp c : ret c
        ; its character rows, within the window's
        ld a,(ix+DR_Y0) : srl a : ld b,a : ld a,(scrollrow) : cp b : jr nc,.k0
        ld a,b
.k0     ld (rr_k0),a
        ld a,(win_rows) : dec a : ld b,a : ld a,(scrollrow) : add a,b : ld b,a
        ld a,(ix+DR_Y1) : srl a : cp b : jr c,.k1
        ld a,b
.k1     ld (rr_k1),a
        ld b,a : ld a,(rr_k0) : ld c,a : ld a,b : cp c : ret c
        jp repaint_rect

; Carry set if drawn record IX overlaps any damage
damaged ld a,(dmg_n) : or a : ret z
        ld b,a : ld hl,dmg_list
.loop   ld a,(ix+DR_C1) : cp (hl) : jr c,.n0            ; ends left of it
        inc hl : ld a,(hl) : cp (ix+DR_C0) : jr c,.n1   ; starts right of it
        inc hl : ld a,(ix+DR_Y1) : cp (hl) : jr c,.n2   ; ends above it
        inc hl : ld a,(hl) : cp (ix+DR_Y0) : jr c,.n3   ; starts below it
        scf : ret
.n0     inc hl
.n1     inc hl
.n2     inc hl
.n3     inc hl
        djnz .loop
        or a : ret

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
