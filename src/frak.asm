\ ******************************************************************************
\ Frak! for the BBC Master 128 - assembled with BeebAsm
\
\ Milestone 1: one level (Read&Weep), Trogg walking, jumping, falling and climbing,
\ with hardware horizontal scrolling. Ported from the HTML5 version (steamfrak repo).
\
\ Screen: MODE 1, 320x256, 4 colours. Logical colour 0 = level background,
\ 1 = black, 2 = magenta, 3 = yellow.
\
\ Screen memory is addressed in *level* coordinates: the CRTC start address is
\ set so that level byte-column C, character row R always lives at
\     &3000 + ((C + R*80) MOD 2560) * 8
\ however far the screen has scrolled. So a scroll only needs the newly exposed
\ column drawing, and sprites can be drawn and erased using level coordinates.
\ ******************************************************************************

OSWRCH      = &FFEE
OSBYTE      = &FFF4
ROMSEL      = &FE30
ROMSEL_COPY = &F4
CRTC_REG    = &FE00
CRTC_DATA   = &FE01

SCREEN      = &3000
LEVEL_BANK  = 6             \ sideways RAM bank 6: game logic and level tables
SCREEN_COLS = 80            \ byte columns visible across the screen (320 pixels)
WINDOW_W    = 320           \ visible width in level pixels

INCLUDE "src/gen/consts.asm"
\ Where the packed front end and level loader go (tools/pack.py works these out
\ from the first pass, which only has to get their sizes)
IF PASS = 2
INCLUDE "src/gen/packed.asm"
ELSE
FRONTZ_ORG = IMGDIR_ORG
OVERLAYZ_ORG = &C000
ENDIF

\ Frame rate: the screen is redrawn at 25 frames a second, and the game logic
\ runs one tick per vertical sync (50 a second): normally two per drawn frame.
FRAMES_PER_DRAW = 2             \ vertical syncs (1/50 s) per drawn frame
MAX_TICKS_PER_FRAME = 4         \ game logic runs one tick per vertical sync, up to this many per frame

MAX_LOG = 48                    \ draw-log entries per screen buffer
LOG_SPRITE7 = 2                 \ (draw log kinds: 0 sprite, 1 line, 2 sprite saved in another bank)
MAX_MOVERS = 12                 \ moving objects: balloons, daggers, meanies flying off

\ Save areas: 1KB per screen buffer for the backgrounds under moving things,
\ Part is kept for Trogg (8 columns of 34 rows), the yoyo (3 x 6) and its
\ string, plus the FRAK! bubble (14 x 19) when he's dead; the rest is for
\ balloons, daggers and meanies. Each sprite's save record has a 6-byte header
\ and a 2-byte screen address per column.
SAVE_SIZE = 1024
SAVE_RESERVE_ALIVE = 6 + 8 * 36 + 6 + 8 * 2 + 6 + 3 * 8 + 24 + 6 + 8 * 10 + 6 + 5 * 17
\ (Trogg is two records: body and legs; then the yoyo and string, the timer and rating)
SAVE_RESERVE_DEAD = SAVE_RESERVE_ALIVE + 6 + 14 * 21

\ DIFFICULTY is set by build.sh (DIFFICULTY=n ./build.sh), as in the Steam version:
\ 0 = no balloons or daggers, 1 = Easy, 2 = Hard, 4 = Harder, 6 = Insane
\ (3 and 5 are the upside-down versions of 2 and 4, not done yet)
ASSERT DIFFICULTY >= 0 AND DIFFICULTY <= 6

\ Trogg states
JUMP_SPEED  = 25              \ Trogg's speeds in twentieths of a pixel a tick (gravity is 1)
TERMINAL_SPEED = 80
ST_STAND    = 0
ST_WALK     = 1
ST_FALL     = 2
ST_CLIMB    = 3
ST_YOYO_OUT = 4
ST_YOYO_BACK = 5

\ Plot modes
PM_PLOT     = 0             \ masked plot
PM_SAVE     = 1             \ masked plot, saving the background first
PM_RESTORE  = 2             \ put the saved background back
PM_SAVEONLY = 3             \ only save the background (into another bank)
PM_RAWPLOT  = 4             \ masked plot, but copy into the cells marked in rawbits

\ Keys (negative INKEY numbers, as OSBYTE &81 wants them)
KEY_Z       = &9E           \ -98
KEY_X       = &BD           \ -67
KEY_O       = &C9           \ -55
KEY_K       = &B9           \ -71
KEY_LEFT    = &E6           \ -26
KEY_RIGHT   = &86           \ -122
KEY_UP      = &C6           \ -58
KEY_DOWN    = &D6           \ -42
KEY_P       = &C8           \ -56
KEY_SPACE   = &9D           \ -99
KEY_RETURN  = &B6           \ -74
KEY_ESCAPE  = &8F           \ -113
KEY_Y       = &BB           \ -69

\ ------------------------------------------------------------------------------
\ Zero page
\ ------------------------------------------------------------------------------

ORG &00
GUARD &90

.ptr        SKIP 2          \ screen pointer to the current character cell
.tmp        SKIP 2
.tblptr     SKIP 2

\ plot() parameters
.p_img      SKIP 1
.p_x        SKIP 2          \ origin x (level pixels)
.p_y        SKIP 2          \ origin y
.p_mode     SKIP 1
.clip_l     SKIP 1          \ visible byte columns [clip_l, clip_r)
.clip_r     SKIP 1

\ plot() workspace
.left       SKIP 2
.top        SKIP 2
.col        SKIP 2          \ signed byte column of the image's left edge
.shift      SKIP 1
.wb         SKIP 1          \ width in bytes at this shift
.hgt        SKIP 1
.r0         SKIP 1          \ first visible row of the image
.rows       SKIP 1          \ number of visible rows
.colw       SKIP 1
.cidx       SKIP 1
.cend       SKIP 1
.dptr       SKIP 2          \ sprite data for the current column (+ r0)
.sptr       SKIP 2          \ save-buffer pointer
.dcol       SKIP 2          \ sprite data for the current column
.dp         SKIP 2
.sp         SKIP 2
.y0         SKIP 1          \ line within the first character cell
.yend       SKIP 1
.cells      SKIP 1          \ character cells per column
.cellsleft  SKIP 1
.first_end  SKIP 1
.last_end   SKIP 1
.sbase      SKIP 2          \ save buffer for the buffer being drawn
.front      SKIP 1          \ buffer on screen (0 = main, 1 = shadow)
.back       SKIP 1          \ buffer being drawn
.src        SKIP 2          \ background cache pointer
.mask       SKIP 8          \ a background column: its non-empty cells, then which have numbers >= 256
.pt         SKIP 2
.po         SKIP 2
.vsyncs     SKIP 1          \ incremented by the vertical sync event
.last_flip  SKIP 1          \ vsyncs at the last buffer flip
.firsty     SKIP 2
.bank       SKIP 1
.p_sbank    SKIP 1          \ save bank for PM_SAVEONLY
.oldbank    SKIP 1

\ Platform/ladder queries

\ Trogg

\ ------------------------------------------------------------------------------
\ Code
\ ------------------------------------------------------------------------------

\ Other variables (not needed in zero page), in the free page area below the
\ program (&0E00-&10FF is free on a Master: the DFS workspace is elsewhere)
ORG &0E00
.initcol    SKIP 1
.yo_len     SKIP 2          \ yoyo string length, 8.8 fixed point
.yo_x       SKIP 2
.yo_y       SKIP 2
.yo_hit     SKIP 1
.yb_l       SKIP 2
.yb_r       SKIP 2
.yb_t       SKIP 2
.sfree      SKIP 2          \ next free byte in the back buffer's save area
.send       SKIP 2          \ end of that save area
.sfree7     SKIP 2          \ the same for the slow save area (in p_sbank)
.send7      SKIP 2
.mv_i       SKIP 1
.bal_timer  SKIP 1          \ ticks until the next balloon
.dag_timer  SKIP 1          \ ticks until the next dagger
.rng        SKIP 2          \ random number generator state
.sp_slot    SKIP 1          \ spawning workspace
.sp_mid     SKIP 2
.sp_x       SKIP 2
.sp_spread  SKIP 2
.mul_a      SKIP 1
.mul_b      SKIP 1
.mul_lo     SKIP 1
.mvc_i      SKIP 1          \ mover collision loop
.view_l     SKIP 2          \ left edge of the window - margin, in level pixels
.sl_i       SKIP 1
.cur_plat   SKIP 1          \ platform Trogg is standing on, 255 = none
.plat_hit   SKIP 1
.last_px    SKIP 2          \ where that platform was last tick
.last_py    SKIP 2
.hl_p0      SKIP 1          \ hline workspace
.hl_p1      SKIP 1
.hl_c0      SKIP 1
.hl_c1      SKIP 1
.hl_line    SKIP 1
.hl_row     SKIP 1
.hl_mask    SKIP 1
.keys_found SKIP 1
.gems_found SKIP 1
.won        SKIP 1          \ frames of the level-complete flash left, 0 = playing
.save_cp    SKIP 1          \ save a checkpoint when Trogg next stands still
.have_cp    SKIP 1
.restarts   SKIP 1          \ restarts from a checkpoint (for medals, later)
.pc_col     SKIP 1
.pc_end     SKIP 1
.ct_img     SKIP 1          \ collision workspace
.ct_l       SKIP 2
.ct_t       SKIP 2
.co_i       SKIP 1
.ct_c0      SKIP 1
.ct_c1      SKIP 1
.c_dx       SKIP 2
.c_dy       SKIP 1
.c_dxb      SKIP 1
.c_dyb      SKIP 1
.c_oimg     SKIP 1
.c_rs       SKIP 1
.c_rows     SKIP 1
.c_tl       SKIP 1
.loops      SKIP 1          \ main loop counter (for timing checks)
.ticks_left SKIP 1
.q_x        SKIP 2
.q_y1       SKIP 2
.q_y2       SKIP 2
.q_onplat   SKIP 1
.q_jump     SKIP 1
.res_x      SKIP 2
.res_y      SKIP 2
.res_i      SKIP 1
.res_found  SKIP 1
.res_yf     SKIP 1          \ ladder_find: res_y's twentieths
.q_y1f      SKIP 1          \ twentieths of q_y1 and q_y2 (platform_find_f, ladder_find)
.q_y2f      SKIP 1
.tv_prev    SKIP 1          \ trogg_falling: tv before this tick's gravity
.fy2        SKIP 2          \ ... and where he'd fall to (pixels, twentieths)
.fy2f       SKIP 1
.lad_top    SKIP 2
.lad_len    SKIP 2
.lf_up      SKIP 1          \ ladder_find: 1 if going up
.tx         SKIP 2
.ty         SKIP 2          \ (whole pixels: Trogg's y is ty + tyf / 20)
.tyf        SKIP 1          \ twentieths of a pixel, 0-19
.tstate     SKIP 1
.tface      SKIP 1          \ 0 = right, 1 = left
.tclimb     SKIP 1          \ 0 = still, 1 = up, 2 = down
.xvel       SKIP 1          \ signed
.tv         SKIP 1          \ y velocity, twentieths of a pixel a tick (+ = up), signed
.anim       SKIP 1
.xmove      SKIP 1          \ signed -1/0/1
.ymove      SKIP 1          \ signed, +1 = up
.ud_db      SKIP 1          \ up/down debounce
.lr_db      SKIP 1          \ left/right debounce
.k_left     SKIP 1
.k_right    SKIP 1
.k_up       SKIP 1
.k_down     SKIP 1
.k_yoyo     SKIP 1
.doyoyo     SKIP 1
.yo_db      SKIP 1          \ yoyo debounce
.dead       SKIP 1          \ frames until restart, 0 = alive
.scrollcol  SKIP 1
.newcol     SKIP 1
.cur_level  SKIP 1
.num_bg     SKIP 1          \ loading: background items, and workspace
.u_i        SKIP 1
.u_j        SKIP 1
.u_s        SKIP 1
.u_s4       SKIP 1
.u_h        SKIP 1
.u_cur      SKIP 1
.u_prev     SKIP 1
.u_bank     SKIP 1
.u_r0       SKIP 1
.u_r1       SKIP 1
.u_b        SKIP 1
.rx         SKIP 2
.ry         SKIP 2
.rimg       SKIP 1
.rimg2      SKIP 1
.ld_i       SKIP 1
.ld_j       SKIP 1
.ld_p       SKIP 1
.ld_f       SKIP 1
.px         SKIP 2
.py         SKIP 2
.pw         SKIP 1
.ph         SKIP 1
.pr         SKIP 2
.pl         SKIP 2
.pb         SKIP 2
.best       SKIP 2
.found      SKIP 1
.u_cntl     SKIP 1          \ cells in the background's dictionary so far
.u_cnth     SKIP 1
.u_cl       SKIP 1          \ dictionary search: a candidate (its number + 1)
.u_ch       SKIP 1
.u_nl       SKIP 1          \ ... a cell's number
.u_nh       SKIP 1
.u_h8       SKIP 1          \ ... and its hash
.u_x        SKIP 1          \ the cell's index in its line
.u_line     SKIP 1          \ unrolling: the line (column or row)
.u_cells    SKIP 1          \ ... its cells
.u_src      SKIP 2          \ ... and where they are
.u_bl       SKIP 2          \ unroll_item: the band of level rows [u_bl, u_bh)
.u_bh       SKIP 2
.u_tb       SKIP 2          \ ... and where level row 0 of this column would be
.dp_save    SKIP 2          \ the level being played (0 = Training)
.num_plats  SKIP 1          \ the level's size and contents (set by load_level)
.num_ladders SKIP 1
.num_draw   SKIP 1
.num_slow   SKIP 1
.num_keys   SKIP 1
.level_bg   SKIP 1
.level_cols SKIP 1
.trogg_x0   SKIP 2
.trogg_y0   SKIP 2
.scroll_max SKIP 2          \ LEVEL_W - WINDOW_W
.x_max      SKIP 2          \ LEVEL_W - 10
.dm_c0      SKIP 1          \ damage rectangle to record (byte columns, pixel rows, inclusive)
.dm_c1      SKIP 1
.dm_y0      SKIP 1
.dm_y1      SKIP 1
.rr_c0      SKIP 1          \ repaint_rect: byte columns and character cells (inclusive)
.rr_c1      SKIP 1
.rr_k0      SKIP 1
.rr_k1      SKIP 1
.cellk      SKIP 1
.curbit     SKIP 1
.clip_t     SKIP 2          \ drawing is clipped to rows clip_t .. clip_t + clip_h - 1
.clip_h     SKIP 1          \ (0 = 256)
.scrollrow  SKIP 1          \ character row at the top of the window (vertically scrolling levels)
.newrow     SKIP 1
.is_vert    SKIP 1          \ the level scrolls vertically
.level_rows SKIP 1          \ its height, in character rows
.level_h    SKIP 2          \ ... and pixels
.row_max    SKIP 1          \ level_rows - 32
.mb         SKIP 1          \ bytes in each of a background line's masks (4 or 10)
.pl_line    SKIP 1          \ paint_line: the line (column or row)
.pl_i0      SKIP 1          \ ... and its cells to paint
.pl_i1      SKIP 1
.cpage      SKIP 1
.difficulty SKIP 1          \ 1 Easy, 2 Hard, 4 Harder, 6 Insane (0: no balloons or daggers)
.snd_music_req SKIP 1       \ sound (see src/sound.asm): a tune to start (&FF: none)
.snd_sfx_req SKIP 1         \ ... sound effects to start (&FF: none)
.snd_sfx_req2 SKIP 1
.snd_music_opt SKIP 1       \ ... 0 all the tracks, 1 the first only, 2 no music (M)
.snd_sfx_opt SKIP 1         \ ... 0 sound effects on, 1 off (S)
.snd_cur    SKIP 1          \ ... the tune last asked for
.last_level SKIP 1          \ for "replay last level"
.fe_sel     SKIP 1          \ front end: the selected button
.fe_top_sel SKIP 1
.fe_group   SKIP 1
.fe_kind    SKIP 1          \ 0 top menu, 1 a level group
.fe_bx      SKIP 1          \ the button being drawn: its byte column and top row
.fe_y0      SKIP 1
.fe_flash   SKIP 1
.fe_i       SKIP 1
.fe_i2      SKIP 1
.fe_n       SKIP 1
.fe_n2      SKIP 1
.fe_pat     SKIP 1
.lvl_ticks  SKIP 2          \ the level's timer (game ticks, 50 a second)
.win_ticks  SKIP 2          \ ticks left of the level-complete pause
.hud_secs   SKIP 2          \ the seconds shown on the timer
.num_gems   SKIP 1
.done_valid SKIP 1          \ a finished level's result, for the front end's records
.done_level SKIP 1
.done_ticks SKIP 2
.done_restarts SKIP 1
.done_gems  SKIP 1
.txt_yh     SKIP 1
.txt_col    SKIP 1          \ text: where (byte column, pixel row) and colour
.txt_y      SKIP 1
.txt_colour SKIP 1
.txt_i      SKIP 1
.txt_i2     SKIP 1
.txt_glyph  SKIP 8
.t_part_b   SKIP 1          \ Trogg's second image (legs), 255 if none
.pages1     SKIP 1          \ non-zero if the background's dictionary has more than one page
.u_sx       SKIP 1
.cmask      SKIP 30         \ a background line's masks
.ds_base    SKIP 1          \ draw_slow: index of this buffer's drawn records
.rr_i       SKIP 1          \ the next Scrubbly in turn to move
.cm_left    SKIP 1
.cm_count   SKIP 1
.cm_q       SKIP 5          \ moves left this frame, per kind
.m_ncol     SKIP 1          \ raw_setup: the sprite's byte columns, first cell,
.m_wb       SKIP 1          \ and range of full cells
.m_ntop     SKIP 1
.m_nk0      SKIP 1
.m_kf0      SKIP 1
.m_kf1      SKIP 1
.rr_raw     SKIP 1          \ repaint_rect: skip (and note) raw cells
.rawcol     SKIP 1
MAX_RAW_COLS = 16
.rawbits    SKIP MAX_RAW_COLS
.nr_c0      SKIP 1          \ slow_rect results
.nr_c1      SKIP 1
.nr_y0      SKIP 1
.nr_y1      SKIP 1


MAX_OBJECTS = 64
ASSERT MAX_DRAW <= MAX_OBJECTS
.alive      SKIP MAX_OBJECTS        \ 1 = object not yet collected
.cp_alive   SKIP MAX_OBJECTS        \ checkpoint copy
.cp_tx      SKIP 2
.cp_ty      SKIP 2
.cp_tyf     SKIP 1
.cp_face    SKIP 1
.cp_keys    SKIP 1
.cp_gems    SKIP 1
.cp_bal     SKIP 1
.cp_dag     SKIP 1
.mv_active  SKIP MAX_MOVERS         \ moving objects: kind, or 0 if the slot is free
.mv_img     SKIP MAX_MOVERS
.mv_xf      SKIP MAX_MOVERS         \ position, 16.8 fixed point (fraction, low, high)
.mv_xl      SKIP MAX_MOVERS
.mv_xh      SKIP MAX_MOVERS
.mv_yf      SKIP MAX_MOVERS
.mv_yl      SKIP MAX_MOVERS
.mv_yh      SKIP MAX_MOVERS
.mv_vxf     SKIP MAX_MOVERS         \ velocity, 8.8 fixed point (fraction, signed whole part)
.mv_vxi     SKIP MAX_MOVERS
.mv_vyf     SKIP MAX_MOVERS
.mv_vyi     SKIP MAX_MOVERS
.mv_pause   SKIP MAX_MOVERS         \ ticks to wait before moving

ASSERT P% <= &1100

ORG &1100
GUARD SCREEN
.code_start
\ (the page-aligned tables first, so they need no padding)
INCLUDE "src/gen/tables.asm"

.start
{
    \ (the variables below the code aren't loaded, so start them all at 0)
    lda #0 : tax
.clear_vars
    sta &0E00,x : sta &0F00,x : sta &1000,x
    inx : bne clear_vars
    jsr bring_overlay
    jsr copy_pack                   \ (before MODE 1 clears the screen it was loaded into)
    \ Disable Escape, set up MODE 1 with no cursor
    lda #229 : ldx #1 : ldy #0 : jsr OSBYTE
    ldx #0
.vdu_loop
    lda vdu_init,x : jsr OSWRCH
    inx : cpx #vdu_init_end - vdu_init : bne vdu_loop
    \ The level data lives in sideways RAM bank 6 and stays paged in while the
    \ game runs (routines that page in other banks put it back afterwards)
    lda #LEVEL_BANK : sta ROMSEL_COPY : sta ROMSEL
    lda #&FF : sta snd_music_req : sta snd_sfx_req : sta snd_sfx_req2
    lda #0 : sta snd_music_opt : sta snd_sfx_opt : sta snd_cur
    jsr install_vsync_counter
    lda #DIFFICULTY : sta difficulty
    lda #START_LEVEL : sta last_level
    lda #0 : sta fe_top_sel
    lda #0 : jsr front_end          \ the attract screen and the menus
    jsr load_playable
}

\ Double buffering: the screen is drawn in whichever of main RAM (buffer 0) and
\ the Master's shadow RAM (buffer 1) is not being displayed, then the two are
\ swapped at vertical sync. Each buffer keeps its own scroll position and its
\ own copy of the background saved under Trogg.

\ Start (or restart) the level from scratch
.level_start
{
    ldx #MAX_OBJECTS - 1
.objs
    lda #0 : cpx num_draw : bcs gone : lda #1 : .gone
    sta alive,x : dex : bpl objs
    lda #0 : sta keys_found : sta gems_found : sta have_cp : sta save_cp : sta restarts
    sta lvl_ticks : sta lvl_ticks+1 : sta win_ticks : sta win_ticks+1
    sta bal_timer : sta dag_timer
    lda vsyncs : ora #1 : sta rng : lda #&5A : sta rng+1
    jsr slow_init
    lda trogg_x0 : sta tx : lda trogg_x0+1 : sta tx+1
    lda trogg_y0 : sta ty : lda trogg_y0+1 : sta ty+1
    lda #0 : sta tface : sta tyf : sta tv
    jmp redraw_all
}

\ Go back to the last checkpoint (the state saved after collecting a key)
.restore_checkpoint
{
    inc restarts
    ldx #MAX_OBJECTS - 1
.objs
    lda cp_alive,x : sta alive,x : dex : bpl objs
    lda cp_keys : sta keys_found
    lda cp_gems : sta gems_found
    lda cp_tx : sta tx : lda cp_tx+1 : sta tx+1
    lda cp_ty : sta ty : lda cp_ty+1 : sta ty+1 : lda cp_tyf : sta tyf
    lda cp_face : sta tface
    lda cp_bal : sta bal_timer : lda cp_dag : sta dag_timer
    jsr slow_restore_checkpoint
    lda #0 : sta save_cp
}
    \ fall through

\ Reset Trogg's movement state and redraw both screen buffers from scratch
.redraw_all
{
    jsr level_music
    lda #ST_STAND : sta tstate
    lda #0 : sta tclimb : sta xvel : sta anim : sta dead : sta won
    sta ud_db : sta lr_db : sta yo_db : sta yo_len : sta yo_len+1
    jsr set_palette
    \ No moving objects (e.g. meanies flying off after being yoyoed)
    ldx #MAX_MOVERS - 1
    lda #0
.movers
    sta mv_active,x : dex : bpl movers

    lda #0 : sta rr_raw
    lda #&FF : sta hud_secs : sta hud_secs+1
    jsr slow_reset_display
    jsr calc_scroll
    ldx #1
.init_buffer
    stx back
    jsr select_back
    lda newcol : sta scrollcol
    lda newrow : sta scrollrow
    jsr set_window_clip
    lda is_vert : bne init_rows
    lda #SCREEN_COLS - 1 : sta initcol
.init_col
    lda scrollcol : clc : adc initcol
    jsr repaint_column
    dec initcol : bpl init_col
    jmp init_done
.init_rows
    lda #31 : sta initcol
.init_row
    lda scrollrow : clc : adc initcol
    jsr repaint_row
    dec initcol : bpl init_row
.init_done
    ldx back
    lda newcol : sta bscroll,x
    lda newrow : sta brow,x
    lda #0 : sta log_n,x : sta bfrak,x : sta bwon,x : sta pend_hi,x
    lda #&FF : sta pend_lo,x
    dex : bpl init_buffer
    lda #1 : sta front              \ buffer 0 is drawn first
}

\ Each frame, in the buffer that isn't on screen:
\   1. erase everything drawn there last time (in reverse order), from the
\      backgrounds saved in that buffer's save area (see "draw log" below)
\   2. bring its scroll position up to date and repaint collected objects
\   3. draw the moving things - meanies flying off, the yoyo and its string,
\      Trogg, and his FRAK! bubble - saving the background under each
\ then show it at the next 25Hz frame, and run two ticks of game logic.
.main_loop
{
    lda front : eor #1 : sta back
    jsr select_back
    ldx back
    lda bscroll,x : sta scrollcol
    lda brow,x : sta scrollrow
    jsr set_window_clip

    \ Once Trogg is dead and this buffer already shows the FRAK! bubble, nothing
    \ changes until the restart, so don't redraw
    lda won : beq not_won
    lda bwon,x : beq redraw
    jmp show
.not_won
    lda dead : beq redraw
    lda bfrak,x : beq redraw
    jmp show
.redraw
    lda #0 : sta dmg_n : sta dmg_all       \ nothing repainted yet this frame
.^t_restore
    jsr restore_log

.^t_scroll
    jsr do_scroll
    ldx back
    lda scrollcol : sta bscroll,x
    lda scrollrow : sta brow,x
    jsr do_pending

.^t_draw
    ldx back
    lda savebuf_lo,x : sta sfree : lda savebuf_hi,x : sta sfree+1
    lda savebuf_end_lo,x : sta send : lda savebuf_end_hi,x : sta send+1

    \ Meanies flying off save their backgrounds in this buffer's slow save area
    ldx back
    lda slowsave_bank,x : sta p_sbank
    lda slowsave_lo,x : sta sfree7 : lda slowsave_hi,x : sta sfree7+1
    lda slowsave_end_lo,x : sta send7 : lda slowsave_end_hi,x : sta send7+1
    \ Moving platforms and meanies ("slow sprites") stay drawn in each buffer;
    \ only the ones that moved (or were painted over) are redrawn
.^t_slow
    jsr commit_slow
    jsr draw_slow
.^t_slow_done

    \ view_l = left edge of the window - 64, for skipping off-screen movers
    lda scrollcol : sta view_l : lda #0 : sta view_l+1
    asl view_l : rol view_l+1 : asl view_l : rol view_l+1
    lda view_l : sec : sbc #64 : sta view_l : lda view_l+1 : sbc #0 : sta view_l+1
    \ Moving objects (drawn behind Trogg, as meanies were in GameMaker). Keep
    \ enough of the save area for Trogg, the yoyo and the FRAK! bubble.
    lda dead : bne reserve_dead
    lda send : sec : sbc #LO(SAVE_RESERVE_ALIVE) : sta send
    lda send+1 : sbc #HI(SAVE_RESERVE_ALIVE) : sta send+1
    jmp reserved
.reserve_dead
    lda send : sec : sbc #LO(SAVE_RESERVE_DEAD) : sta send
    lda send+1 : sbc #HI(SAVE_RESERVE_DEAD) : sta send+1
.reserved
    lda #0 : sta mv_i
.movers
    ldx mv_i
    lda mv_active,x : beq next_mover
    \ skip it if it's well outside the window (x < view left - 64 or x >= view right + 64)
    lda mv_xl,x : sec : sbc view_l : sta tmp
    lda mv_xh,x : sbc view_l+1 : bmi next_mover     \ left of the window
    beq on_screen
    cmp #HI(WINDOW_W + 128) : bne next_mover
    lda tmp : cmp #LO(WINDOW_W + 128) : bcs next_mover
.on_screen
    lda mv_img,x : sta p_img
    lda mv_xl,x : sta p_x : lda mv_xh,x : sta p_x+1
    lda mv_yl,x : sta p_y : lda mv_yh,x : sta p_y+1
    lda mv_active,x : cmp #MV_FLYING : beq big
    jsr log_sprite
    jmp next_mover
.big
    jsr log_sprite7                 \ meanies are big: save in the slow save area
.next_mover
    inc mv_i : lda mv_i : cmp #MAX_MOVERS : beq movers_done
    jmp movers
.movers_done
    ldx back
    lda savebuf_end_lo,x : sta send : lda savebuf_end_hi,x : sta send+1

    \ The yoyo and its string
    lda tstate : cmp #ST_YOYO_OUT : bcc no_yoyo
    jsr yoyo_string_params
    jsr log_line
    jsr yoyo_image : sta p_img
    lda yo_x : sta p_x : lda yo_x+1 : sta p_x+1
    lda yo_y : sta p_y : lda yo_y+1 : sta p_y+1
    jsr log_sprite
.no_yoyo
    jsr draw_springs                \ (moving bouncy platforms' springs)

    \ Trogg (standing or walking, he's two images: his body and his legs)
    jsr trogg_image : tax
    lda img_part_b,x : sta t_part_b
    lda img_part_a,x : sta p_img
    lda tx : sta p_x : lda tx+1 : sta p_x+1
    lda ty : sta p_y : lda ty+1 : sta p_y+1
    jsr log_sprite
    lda t_part_b : cmp #255 : beq one_part
    sta p_img
    jsr log_sprite
.one_part

    \ the timer and rating (or, once the level is complete, its panel)
    jsr draw_hud

    \ ... and "FRAK!" at (x + 12, y - 26) if he's dead
    ldx back
    lda dead : sta bfrak,x : beq show
    lda #IMG_Frak : sta p_img
    lda tx : clc : adc #12 : sta p_x : lda tx+1 : adc #0 : sta p_x+1
    lda ty : sec : sbc #26 : sta p_y : lda ty+1 : sbc #0 : sta p_y+1
    jsr log_sprite

.^show
    \ Show it once FRAMES_PER_DRAW vertical syncs have passed since the last flip
    inc loops
.^t_vsync
.wait
    lda vsyncs : sec : sbc last_flip
    cmp #FRAMES_PER_DRAW : bcc wait
.^t_after_vsync
    jsr set_crtc_start
    jsr show_back
    lda back : sta front

    \ Run one tick of game logic per vertical sync since the last flip: normally
    \ two, but more if drawing overran, so the game speed stays at 50 ticks a
    \ second (capped, so a long pause such as a full redraw doesn't jump ahead)
    lda vsyncs : sec : sbc last_flip
    cmp #MAX_TICKS_PER_FRAME + 1 : bcc ticks_ok
    lda #MAX_TICKS_PER_FRAME
.ticks_ok
    sta ticks_left
    lda vsyncs : sta last_flip
.tick
.^t_logic
    jsr game_tick
.^t_logic_done
    beq next_tick
    cmp #TICK_WON : beq next_level
    cmp #TICK_QUIT : beq to_menu
    lda have_cp : beq from_scratch          \ TICK_DIED: restart
    jmp restore_checkpoint
.from_scratch
    jmp level_start
.next_level
    jsr record_result
    lda cur_level : clc : adc #1 : jsr load_playable
    jmp level_start
.to_menu
    lda cur_level : sta last_level
    lda #1 : jsr front_end          \ (Escape: back to the menus)
    jsr load_playable
    jmp level_start
.next_tick
    dec ticks_left : bne tick
    jmp main_loop
}

\ One tick of game logic. Returns A (and Z) = TICK_OK, TICK_DIED or TICK_WON.
TICK_OK = 0
TICK_DIED = 1
TICK_WON = 2
TICK_QUIT = 3
.game_tick
{
    lda dead : beq alive
    dec dead : beq died
    lda #TICK_OK : rts
.died
    lda #TICK_DIED : rts
.alive
    lda won : beq playing
    \ level complete: wait, then the next level
    lda win_ticks : ora win_ticks+1 : beq finished
    lda win_ticks : bne w1 : dec win_ticks+1 : .w1 : dec win_ticks
    lda #TICK_OK : rts
.finished
    lda #TICK_WON : rts
.playing
    inc lvl_ticks : bne t1 : inc lvl_ticks+1 : .t1
    jsr read_keys
    lda #KEY_ESCAPE : jsr key_pressed : beq stay
    lda #TICK_QUIT : rts
.stay
    jsr update_slow
    jsr trogg_update
    jsr footsteps
    jsr spawn_hazards
    jsr update_movers
    lda dead : bne done
    jsr check_collisions
    jsr check_checkpoint
.done
    lda #TICK_OK : rts
}

\ Trogg's footsteps (as the Steam version, not while all the music's tracks play)
.footsteps
{
    lda snd_music_opt : beq done
    lda lvl_ticks
    ldx tstate : cpx #ST_WALK : bne not_walking
    and #7 : bne done : beq thud        \ (walking: every 8 ticks)
.not_walking
    cpx #ST_CLIMB : bne done
    ldx tclimb : beq done
    and #15 : bne done                  \ (climbing: every 16)
.thud
    lda #SFX_THUD : jmp play_sfx
.done
    rts
}

\ Count vertical syncs (MOS event 4) so the main loop can pace itself
EVNTV = &0220
.vsync_event
{
    php
    cmp #4 : bne chain
    inc vsyncs
    \ ... and the music and sound effects (src/sound.asm, in MUSIC_BANK)
    pha : txa : pha : tya : pha
    lda tblptr : pha : lda tblptr+1 : pha
    lda #MUSIC_BANK : sta ROMSEL
    jsr snd_tick
    lda ROMSEL_COPY : sta ROMSEL
    pla : sta tblptr+1 : pla : sta tblptr
    pla : tay : pla : tax : pla
.chain
    plp
.^old_evntv
    jmp &FFFF                       \ (operand set to the previous EVNTV)
}

\ Start tune A (0: silence), even if it's already playing
.play_music
{
    sta snd_cur : sta snd_music_req
    rts
}

\ Start tune A unless it's the one playing
.play_music_new
{
    cmp snd_cur : bne play_music
    rts
}

\ Start sound effect A (X and Y kept)
.play_sfx
{
    bit snd_sfx_req : bpl second
    sta snd_sfx_req
    rts
.second
    sta snd_sfx_req2
    rts
}

\ Stop the music and the sound effects
.stop_sounds
{
    lda #0 : jsr play_music
    lda #SFX_STOP : jmp play_sfx
}

\ The level's tune (as the Steam version): with Poglets, "A Little Bag of Weed";
\ with Hooters, "The Man Who Once Was I"; else the Frak! theme
.level_music
{
    ldy #TUNE_WEED : lda #IMG_Poglet : jsr level_has : bcs play
    ldy #TUNE_MAN : lda #IMG_Hooter : jsr level_has : bcs play
    ldy #TUNE_FRAK
.play
    tya : jmp play_music
}

\ Carry set if image A is one of the level's objects or moving sprites
.level_has
{
    ldx num_draw : beq no_draw
.draw
    cmp draw_img - 1,x : beq yes
    dex : bne draw
.no_draw
    ldx num_slow : beq no
.slow
    cmp sl_img - 1,x : beq yes
    dex : bne slow
.no
    clc : rts
.yes
    sec : rts
}

.install_vsync_counter
{
    sei
    lda EVNTV : sta old_evntv+1 : lda EVNTV+1 : sta old_evntv+2
    lda #LO(vsync_event) : sta EVNTV : lda #HI(vsync_event) : sta EVNTV+1
    cli
    lda #14 : ldx #4 : jsr OSBYTE   \ enable the vertical sync event
    rts
}

\ Slow save areas (in sideways RAM) for meanies flying off
.slowsave_bank  EQUB SLOWSAVE0_BANK, LEVEL_BANK
.slowsave_lo    EQUB LO(SLOWSAVE0_START), LO(slowsave1)
.slowsave_hi    EQUB HI(SLOWSAVE0_START), HI(slowsave1)
.slowsave_end_lo EQUB LO(&C000), LO(slowsave1 + SLOWSAVE1_SIZE)
.slowsave_end_hi EQUB HI(&C000), HI(slowsave1 + SLOWSAVE1_SIZE)


\ ------------------------------------------------------------------------------
\ Draw log: everything moving that was drawn into a buffer, so it can be erased
\
\ Each buffer has a save area. As things are drawn, the background under each is
\ saved at the next free place in it (sfree), and an entry recorded. Next time
\ that buffer is drawn, the entries are erased in reverse order.
\ ------------------------------------------------------------------------------

LOG_SPRITE = 0
LOG_LINE = 1

\ Log index for entry log_n[back] of the back buffer -> X
.log_slot
{
    ldx back : lda log_base,x
    clc : adc log_n,x
    tax
    rts
}

\ Record entry X with kind A and the current p_* and save area (sfree)
.log_record
{
    sta log_kind,x
    lda p_img : sta log_img,x
    lda p_x : sta log_xl,x : lda p_x+1 : sta log_xh,x
    lda p_y : sta log_yl,x : lda p_y+1 : sta log_yh,x
    lda q_x : sta log_x1l,x : lda q_x+1 : sta log_x1h,x
    lda sfree : sta log_sbl,x : sta sbase : lda sfree+1 : sta log_sbh,x : sta sbase+1
    ldx back : inc log_n,x
    lda #PM_SAVE : sta p_mode
    rts
}

\ Draw image p_img at (p_x, p_y), saving the background, if there's room
.log_sprite
{
    ldx back : lda log_n,x : cmp #MAX_LOG : bcs no_room
    \ room in the save area? sfree + img_sv <= send
    ldx p_img
    lda sfree : clc : adc img_svl,x : sta tmp
    lda sfree+1 : adc img_svh,x : sta tmp+1
    lda send : cmp tmp : lda send+1 : sbc tmp+1 : bcc no_room
    jsr log_slot
    lda #LOG_SPRITE : jsr log_record
    jsr plot
    lda sptr : sta sfree : lda sptr+1 : sta sfree+1
.no_room
    rts
}

\ Draw a black line from (p_x, p_y) to (q_x, p_y), saving the background
LINE_SAVE = 24                      \ bytes: the longest line is about 82 pixels
.log_line
{
    ldx back : lda log_n,x : cmp #MAX_LOG : bcs no_room
    lda sfree : clc : adc #LINE_SAVE : sta tmp
    lda sfree+1 : adc #0 : sta tmp+1
    lda send : cmp tmp : lda send+1 : sbc tmp+1 : bcc no_room
    jsr log_slot
    lda #LOG_LINE : jsr log_record
    jsr hline
    lda sptr : sta sfree : lda sptr+1 : sta sfree+1
.no_room
    rts
}

\ Draw a big moving sprite (platform or meanie) at (p_x, p_y): its background is
\ saved in the back buffer's slow save area (another sideways RAM bank, which has
\ far more room), then it is plotted.
.log_sprite7
{
    ldx back : lda log_n,x : cmp #MAX_LOG : bcs no_room
    ldx p_img
    lda sfree7 : clc : adc img_svl,x : sta tmp
    lda sfree7+1 : adc img_svh,x : sta tmp+1
    lda send7 : cmp tmp : lda send7+1 : sbc tmp+1 : bcc no_room
    jsr log_slot
    lda #LOG_SPRITE7 : sta log_kind,x
    lda p_img : sta log_img,x
    lda sfree7 : sta log_sbl,x : sta sbase : lda sfree7+1 : sta log_sbh,x : sta sbase+1
    lda p_sbank : sta log_bank,x
    ldx back : inc log_n,x
    lda #PM_SAVEONLY : sta p_mode
    jsr plot
    lda sptr : sta sfree7 : lda sptr+1 : sta sfree7+1
    lda #PM_PLOT : sta p_mode
    jsr plot
.no_room
    rts
}

.log_base EQUB 0, MAX_LOG

\ Erase everything logged in the back buffer, most recent first
.restore_log
{
    ldx back
    lda log_n,x : beq done
.loop
    ldx back : dec log_n,x
    ldy back : lda log_base,y : clc : adc log_n,x : tax
    lda log_img,x : sta p_img
    lda log_xl,x : sta p_x : lda log_xh,x : sta p_x+1
    lda log_yl,x : sta p_y : lda log_yh,x : sta p_y+1
    lda log_x1l,x : sta q_x : lda log_x1h,x : sta q_x+1
    lda log_sbl,x : sta sbase : lda log_sbh,x : sta sbase+1
    lda #PM_RESTORE : sta p_mode
    lda log_kind,x : beq sprite
    cmp #LOG_SPRITE7 : bne line
    \ saved in another bank: page it in to put the background back
    lda ROMSEL_COPY : pha
    lda log_bank,x : sta ROMSEL_COPY : sta ROMSEL
    jsr restore_saved
    pla : sta ROMSEL_COPY : sta ROMSEL
    jmp next
.sprite
    jsr restore_saved
    jmp next
.line
    jsr hline
.next
    ldx back : lda log_n,x : bne loop
.done
    rts
}


ACCCON = &FE34                      \ Master: bit 0 = display shadow, bit 2 = CPU uses shadow

\ Make &3000-&7FFF refer to the back buffer
.select_back
{
    lda ACCCON : and #&FB
    ldx back : beq main
    ora #4
.main
    sta ACCCON
    rts
}

\ Display the back buffer
.show_back
{
    lda ACCCON : and #&FE
    ldx back : beq main
    ora #1
.main
    sta ACCCON
    rts
}

\ Fill the selected buffer with colour 0
.clear_screen
{
    lda #LO(SCREEN) : sta ptr : lda #HI(SCREEN) : sta ptr+1
    lda #0 : tay
.loop
    sta (ptr),y : iny : bne loop
    inc ptr+1 : ldx ptr+1 : cpx #&80 : bne loop
    rts
}

\ Save areas for the backgrounds under moving things, 1KB per screen buffer:
\ buffer 0's in BASIC's workspace (unused, since the game never returns to
\ BASIC), buffer 1's in pages &09-&0C (RS423/cassette buffers, soft keys and
\ user-defined characters, none of which the game uses)
savebuf0 = &0400
savebuf1 = &0900
.savebuf_lo     EQUB LO(savebuf0), LO(savebuf1)
.savebuf_hi     EQUB HI(savebuf0), HI(savebuf1)
.savebuf_end_lo EQUB LO(savebuf0 + SAVE_SIZE), LO(savebuf1 + SAVE_SIZE)
.savebuf_end_hi EQUB HI(savebuf0 + SAVE_SIZE), HI(savebuf1 + SAVE_SIZE)

.vdu_init
    EQUB 22, 1                              \ MODE 1
    EQUB 23, 1, 0, 0, 0, 0, 0, 0, 0, 0      \ cursor off
.vdu_colours
    EQUB 19, 1, 0, 0, 0, 0                  \ colour 1 = black
    EQUB 19, 2, 5, 0, 0, 0                  \ colour 2 = magenta
    EQUB 19, 3, 3, 0, 0, 0                  \ colour 3 = yellow
.vdu_init_end

\ ------------------------------------------------------------------------------
\ Scrolling
\ ------------------------------------------------------------------------------

\ newcol = clamp(tx - WINDOW_W/2, 0, LEVEL_W - WINDOW_W) / 4
.calc_scroll
{
    lda is_vert : bne vertical
    sec
    lda tx : sbc #LO(WINDOW_W/2) : sta tmp
    lda tx+1 : sbc #HI(WINDOW_W/2) : sta tmp+1
    bpl not_neg
    lda #0 : sta tmp : sta tmp+1
.not_neg
    lda tmp : cmp scroll_max
    lda tmp+1 : sbc scroll_max+1
    bcc in_range
    lda scroll_max : sta tmp
    lda scroll_max+1 : sta tmp+1
.in_range
    lsr tmp+1 : ror tmp
    lsr tmp+1 : ror tmp
    lda tmp : sta newcol
    lda #0 : sta newrow
    rts
.vertical
    \ newrow = clamp(ty - 128, 0, level_h - 256) / 8
    lda #0 : sta newcol
    sec
    lda ty : sbc #128 : sta tmp
    lda ty+1 : sbc #0 : sta tmp+1
    bpl v_pos
    lda #0 : sta tmp : sta tmp+1
.v_pos
    lsr tmp+1 : ror tmp : lsr tmp+1 : ror tmp : lsr tmp+1 : ror tmp
    lda tmp : cmp row_max : bcc v_ok : lda row_max
.v_ok
    sta newrow
    rts
}

.do_scroll
{
    jsr calc_scroll
    lda is_vert : bne vertical
.loop
    lda scrollcol : cmp newcol
    beq done
    bcs go_left
    \ Scroll right: expose the column at the right-hand edge
    inc scrollcol
    jsr set_window_clip
    lda scrollcol : clc : adc #SCREEN_COLS - 1
    jsr repaint_column
    jmp loop
.go_left
    dec scrollcol
    jsr set_window_clip
    lda scrollcol
    jsr repaint_column
    jmp loop
.done
    rts
.vertical
    lda scrollrow : cmp newrow
    beq done
    bcs go_up
    \ Scroll down: expose the row at the bottom
    inc scrollrow
    jsr set_window_clip
    lda scrollrow : clc : adc #31
    jsr repaint_row
    jmp vertical
.go_up
    dec scrollrow
    jsr set_window_clip
    lda scrollrow
    jsr repaint_row
    jmp vertical
}

.set_crtc_start
{
    \ start = (&3000 / 8) + (scrollrow MOD 32) * 80 + scrollcol
    lda scrollrow : and #31 : sta tmp : lda #0 : sta tmp+1
    asl tmp : asl tmp : asl tmp : asl tmp : rol tmp+1        \ * 16
    lda tmp : sta left : lda tmp+1 : sta left+1
    asl tmp : rol tmp+1 : asl tmp : rol tmp+1                \ * 64
    lda tmp : clc : adc left : sta tmp : lda tmp+1 : adc left+1 : sta tmp+1
    lda #13 : sta CRTC_REG
    lda tmp : clc : adc scrollcol : sta tmp : lda tmp+1 : adc #0 : sta tmp+1
    lda tmp : clc : adc #LO(SCREEN DIV 8) : sta CRTC_DATA
    lda #12 : sta CRTC_REG
    lda tmp+1 : adc #HI(SCREEN DIV 8) : sta CRTC_DATA
    rts
}

.set_window_clip
{
    lda scrollcol : sta clip_l
    clc : adc #SCREEN_COLS : sta clip_r
    lda #0 : sta clip_t+1 : sta clip_h
    lda scrollrow : asl a : rol clip_t+1 : asl a : rol clip_t+1 : asl a : rol clip_t+1 : sta clip_t
    rts
}

\ Repaint one byte column (A = level byte column): copy the pre-rendered
\ platforms and ladders from the background cache in sideways RAM bank 7,
\ then draw any keys, gems and meanies that overlap it.

.repaint_column
{
    sta colw : sta pl_line
    sta clip_l
    clc : adc #1 : sta clip_r
    \ ptr = address of the column at row 0
    lda #0 : sta tmp+1
    lda colw : asl a : rol tmp+1 : asl a : rol tmp+1 : asl a : rol tmp+1
    clc : adc #LO(SCREEN) : sta ptr
    lda tmp+1 : adc #HI(SCREEN) : sta ptr+1
    cmp #&80 : bcc ok : sbc #&50 : sta ptr+1
.ok
    lda #0 : sta pl_i0 : lda #31 : sta pl_i1
    jsr paint_in_bank7
    \ moving sprites in this column will need drawing again
    lda colw : sta dm_c0 : sta dm_c1
    lda #0 : sta dm_y0 : lda #255 : sta dm_y1
    jsr add_damage
    jsr draw_scenery
    jmp set_window_clip
}

\ Repaint character row A of a vertically scrolling level (all 80 columns),
\ then the scenery in it (clipped to the row)
.repaint_row
{
    sta pl_line
    tax : lda rowaddr_lo,x : sta ptr : lda rowaddr_hi,x : sta ptr+1
    lda #0 : sta pl_i0 : lda #79 : sta pl_i1
    jsr paint_in_bank7
    lda #0 : sta dm_c0 : lda #79 : sta dm_c1
    lda pl_line : asl a : sta dm_y0 : ora #1 : sta dm_y1
    jsr add_damage
    \ the scenery, clipped to this row
    lda #0 : sta clip_t+1
    lda pl_line : asl a : rol clip_t+1 : asl a : rol clip_t+1 : asl a : rol clip_t+1 : sta clip_t
    lda #8 : sta clip_h
    jsr draw_scenery
    jmp set_window_clip
}

\ paint_line with bank 7 paged in
.paint_in_bank7
{
    lda ROMSEL_COPY : pha
    lda #CACHE_BANK : sta ROMSEL_COPY : sta ROMSEL
    jsr paint_line
    pla : sta ROMSEL_COPY : sta ROMSEL
    rts
}

\ Repaint character cells [rr_k0, rr_k1] of byte columns [rr_c0, rr_c1] (all
\ visible) from the background cache, then the scenery over them. This is how
\ moving platforms and meanies are erased. Records damage for what it covers.
.repaint_rect
{
    lda ROMSEL_COPY : pha
    lda #CACHE_BANK : sta ROMSEL_COPY : sta ROMSEL
    lda is_vert : bne by_rows
    \ columns rr_c0..rr_c1, cells rr_k0..rr_k1 of each
    lda rr_k0 : sta pl_i0 : lda rr_k1 : sta pl_i1
    lda rr_c0 : sta colw
.col
    lda colw : sta pl_line
    \ ptr = rowaddr[k0] + colw * 8, wrapped
    lda #0 : sta tmp+1
    lda colw : asl a : rol tmp+1 : asl a : rol tmp+1 : asl a : rol tmp+1
    ldx rr_k0
    clc : adc rowaddr_lo,x : sta ptr
    lda tmp+1 : adc rowaddr_hi,x
    cmp #&80 : bcc ok : sbc #&50
.ok
    sta ptr+1
    jsr paint_line
    lda colw : cmp rr_c1 : beq done
    inc colw : jmp col
.by_rows
    \ rows rr_k0..rr_k1, columns rr_c0..rr_c1 of each (rows don't wrap)
    lda rr_c0 : sta pl_i0 : lda rr_c1 : sta pl_i1
    lda rr_k0 : sta pl_line
.row
    lda #0 : sta tmp+1
    lda rr_c0 : asl a : rol tmp+1 : asl a : rol tmp+1 : asl a : rol tmp+1
    ldx pl_line
    clc : adc rowaddr_lo,x : sta ptr
    lda tmp+1 : adc rowaddr_hi,x : sta ptr+1
    jsr paint_line
    lda pl_line : cmp rr_k1 : beq done
    inc pl_line : jmp row
.done
    pla : sta ROMSEL_COPY : sta ROMSEL
    \ the damage, then the scenery over it, clipped to it
    lda rr_c0 : sta dm_c0 : sta clip_l
    lda rr_c1 : sta dm_c1 : clc : adc #1 : sta clip_r
    lda rr_k0 : asl a : sta dm_y0
    lda rr_k1 : asl a : ora #1 : sta dm_y1
    jsr add_damage
    lda #0 : sta clip_t+1
    lda rr_k0 : asl a : rol clip_t+1 : asl a : rol clip_t+1 : asl a : rol clip_t+1 : sta clip_t
    lda rr_k1 : sec : sbc rr_k0 : clc : adc #1 : asl a : asl a : asl a : sta clip_h     \ (256 = 0)
    jsr draw_scenery
    lda #0 : sta rr_raw
    jmp set_window_clip
}

\ Moving a slow sprite that nothing else is ever drawn over (see slow_simple_flags
\ in the converter): the cells it will completely cover over empty background
\ ("raw" cells) needn't be erased first, and it can be copied into them without
\ masking. raw_setup works out where those could be for p_img at (p_x, p_y);
\ repaint_rect with rr_raw set skips them (noting each in rawbits, one byte per
\ byte column of the sprite, bit n = its nth character cell); then PM_RAWPLOT
\ copies the sprite into them and plots it masked everywhere else.
.raw_setup
{
    ldx p_img
    lda p_x : sec : sbc img_xo,x : sta tmp : lda p_x+1 : sbc #0 : sta tmp+1
    lda tmp : and #3 : clc : adc img_w,x : adc #3 : lsr a : lsr a : sta m_wb
    lsr tmp+1 : ror tmp : lsr tmp+1 : ror tmp
    lda tmp : sta m_ncol
    lda p_y : sec : sbc img_yo,x : sta m_ntop
    lsr a : lsr a : lsr a : sta m_nk0              \ the sprite's first cell
    lda m_ntop : clc : adc #7 : lsr a : lsr a : lsr a : sta m_kf0     \ first full cell
    lda m_ntop : clc : adc img_h,x                 \ (< 256: see the converter)
    lsr a : lsr a : lsr a : sta m_kf1              \ first cell past the last full one
    \ only the first 8 cells can be raw
    lda m_nk0 : clc : adc #8 : cmp m_kf1 : bcs k_ok : sta m_kf1
.k_ok
    ldx #MAX_RAW_COLS - 1 : lda #0
.clr
    sta rawbits,x : dex : bpl clr
    lda #1 : sta rr_raw
    rts
}



\ Draw every scenery item that overlaps [clip_l, clip_r)
.draw_scenery
{
    lda #PM_PLOT : sta p_mode
    ldx #0
.loop
    lda alive,x : beq skip                               \ already collected
    lda draw_c1,x : cmp clip_l : beq skip : bcc skip     \ ends at or before clip_l
    lda draw_c0,x : cmp clip_r : bcs skip                \ starts at or after clip_r
    \ rows: skip it if it ends above clip_t or starts at or below clip_t + clip_h
    ldy draw_img,x
    lda draw_tl,x : clc : adc img_h,y : sta tmp : lda draw_th,x : adc #0 : sta tmp+1
    lda clip_t : cmp tmp : lda clip_t+1 : sbc tmp+1 : bvc v1 : eor #&80 : .v1 : bpl skip
    lda clip_t : clc : adc clip_h : sta tmp : lda clip_t+1 : adc #0 : sta tmp+1
    lda clip_h : bne h_ok : inc tmp+1 : .h_ok                \ (0 = 256)
    lda draw_tl,x : cmp tmp : lda draw_th,x : sbc tmp+1 : bvc v2 : eor #&80 : .v2 : bpl skip
    lda draw_img,x : sta p_img
    lda draw_xl,x : sta p_x : lda draw_xh,x : sta p_x+1
    lda draw_yl,x : sta p_y : lda draw_yh,x : sta p_y+1
    txa : pha
    jsr plot
    pla : tax
.skip
    inx : cpx num_draw : bcs done
    jmp loop
.done
    rts
}


\ ptr += 640 (next character row), wrapping within screen memory; Y = 0
.next_cell
{
    ldy #0
    lda ptr : clc : adc #LO(640) : sta ptr
    lda ptr+1 : adc #HI(640)
    cmp #&80 : bcc ok
    sbc #&50
.ok
    sta ptr+1
    rts
}

\ ------------------------------------------------------------------------------
\ plot: draw (or save/restore under) image p_img with its origin at (p_x, p_y)
\ ------------------------------------------------------------------------------

.plot
{
    \ The save pointer starts at sbase even if nothing turns out to be visible
    \ (the draw log uses where it ends up as the next free save position)
    lda sbase : sta sptr : lda sbase+1 : sta sptr+1
    lda ROMSEL_COPY : sta oldbank
    \ PM_SAVEONLY saves the background into a save area in another sideways RAM
    \ bank (p_sbank), which stays paged in throughout
    lda p_mode : cmp #PM_SAVEONLY : bne not_saveonly
    lda p_sbank : sta ROMSEL_COPY : sta ROMSEL
    jmp header
.not_saveonly
    \ When saving, the save area starts with a record header (see restore_saved):
    \ column count (0 until we know better), y0, cells, first_end, last_end, rows
    cmp #PM_SAVE : bne no_header
.header
    ldy #0 : tya : sta (sptr),y
    lda sptr : clc : adc #SAVE_HEADER : sta sptr : bcc no_header : inc sptr+1
.no_header
    ldx p_img
    \ left = x - xo, top = y - yo (signed 16-bit)
    sec : lda p_x : sbc img_xo,x : sta left : lda p_x+1 : sbc #0 : sta left+1
    sec : lda p_y : sbc img_yo,x : sta top : lda p_y+1 : sbc #0 : sta top+1
    lda left : and #3 : sta shift
    \ col = left >> 2 (arithmetic)
    lda left : sta col : lda left+1 : sta col+1
    cmp #&80 : ror col+1 : ror col
    lda col+1 : cmp #&80 : ror col+1 : ror col
    \ width in bytes at this shift
    lda img_w,x : clc : adc shift : adc #3 : lsr a : lsr a : sta wb
    lda img_h,x : sta hgt

    \ Rows: clip to clip_t .. clip_t + clip_h - 1 (clip_h = 0 means 256)
    lda #0 : sta r0
    lda hgt : sta rows
    lda top : sec : sbc clip_t : sta top : lda top+1 : sbc clip_t+1 : sta top+1
    beq top_ok
    cmp #&FF : bne nothing          \ far above or below
    lda top : beq nothing
    \ above the window: skip -top rows
    lda #0 : sec : sbc top : sta r0
    lda hgt : sec : sbc r0 : bcc nothing : beq nothing : sta rows
    lda clip_h : beq above_ok       \ (and no more than clip_h)
    cmp rows : bcs above_ok : sta rows
.above_ok
    lda clip_t : sta firsty : lda clip_t+1 : sta firsty+1
    jmp rows_done
.nothing
    jmp exit
.top_ok
    \ rows = min(hgt, clip_h - top)
    lda clip_h : sec : sbc top      \ (clip_h = 0 gives 256 - top)
    beq rows_cut : bcs rows_avail
    lda clip_h : bne nothing        \ top >= clip_h
    lda #0 : sec : sbc top          \ 256 - top
.rows_avail
    cmp rows : bcs rows_cut
    sta rows
.rows_cut
    lda clip_h : beq top_in
    lda top : cmp clip_h : bcs nothing
.top_in
    lda top : clc : adc clip_t : sta firsty : lda clip_t+1 : adc #0 : sta firsty+1
.rows_done

    \ Only visit the byte columns inside [clip_l, clip_r):
    \ cidx = max(0, clip_l - col), cend = min(wb, clip_r - col)
    sec : lda clip_l : sbc col : sta tmp : lda #0 : sbc col+1
    bpl start_pos
    lda #0 : sta cidx : beq start_done
.start_pos
    bne none                        \ clip_l - col >= 256
    lda tmp : cmp wb : bcs none
    sta cidx
.start_done
    sec : lda clip_r : sbc col : sta tmp : lda #0 : sbc col+1
    bmi none
    bne end_wb
    lda tmp : cmp wb : bcc end_ok
.end_wb
    lda wb
.end_ok
    sta cend
    cmp cidx : beq none : bcs some
.none
    jmp exit
.some

    \ Sprite data address and bank for this shift (the image addresses are in
    \ DIR_BANK; ROMSEL_COPY too, in case an interrupt pages a ROM)
    ldy shift
    lda dir_bank_tab,y : sta ROMSEL_COPY : sta ROMSEL
    lda shift_lo_tab,y : sta tblptr : lda shift_lo_tab+4,y : sta tblptr+1
    ldy p_img
    lda (tblptr),y : sta dptr
    ldy shift
    lda shift_hi_tab,y : sta tblptr : lda shift_hi_tab+4,y : sta tblptr+1
    ldy p_img
    lda (tblptr),y : sta dptr+1
    ldy shift
    lda shift_bank_tab,y : sta tblptr : lda shift_bank_tab+4,y : sta tblptr+1
    ldy p_img
    lda (tblptr),y : sta bank
    \ dcol = data for the first column, from row r0
    lda dptr : clc : adc r0 : sta dcol : lda dptr+1 : adc #0 : sta dcol+1
    \ ... skipping the columns left of the clip window
    ldx cidx : beq skip_done
.skip_cols
    lda dcol : clc : adc hgt : sta dcol : bcc sk1 : inc dcol+1 : .sk1
    dex : bne skip_cols
.skip_done

    \ Page in the sprite bank (or, for PM_SAVEONLY, the save bank again)
    lda bank
    ldx p_mode : cpx #PM_SAVEONLY : bne bank_ok
    lda p_sbank
.bank_ok
    sta ROMSEL_COPY : sta ROMSEL

    \ Character row and line of the first visible row
    lda firsty : and #7 : sta y0
    lda firsty+1 : sta tmp+1 : lda firsty
    lsr tmp+1 : ror a : lsr tmp+1 : ror a : lsr tmp+1 : ror a
    sta first_row+1

    \ The cell layout is the same for every column, so work it out once:
    \ total = y0 + rows, cells = ceil(total / 8), last_end = total MOD 8 (or 8),
    \ first_end = total if it all fits in one cell, else 8
    lda y0 : clc : adc rows : sta tmp : lda #0 : adc #0 : sta tmp+1
    lda tmp : and #7 : bne le : lda #8 : .le : sta last_end
    lda tmp : clc : adc #7 : sta cells : lda tmp+1 : adc #0
    lsr a : ror cells : lsr a : ror cells : lsr a : ror cells
    lda #8 : sta first_end
    lda cells : cmp #1 : bne multi
    lda tmp : sta first_end
.multi
    \ Record the layout and column count in the save header
    lda p_mode : cmp #PM_SAVE : beq layout : cmp #PM_SAVEONLY : bne no_layout
.layout
    ldy #1
    lda y0 : sta (sbase),y : iny
    lda cells : sta (sbase),y : iny
    lda first_end : sta (sbase),y : iny
    lda last_end : sta (sbase),y : iny
    lda rows : sta (sbase),y
    lda cend : sec : sbc cidx : ldy #0 : sta (sbase),y
.no_layout
    \ Pick the column routine for this mode
    ldx p_mode
    lda col_routines_lo,x : sta do_col+1
    lda col_routines_hi,x : sta do_col+2

.col_loop
    lda col : clc : adc cidx : sta colw

    \ ptr = rowaddr[row] + colw * 8, wrapped
    lda #0 : sta tmp+1
    lda colw : asl a : rol tmp+1 : asl a : rol tmp+1 : asl a : rol tmp+1
.first_row
    ldx #0                          \ (operand set above)
    clc : adc rowaddr_lo,x : sta ptr
    lda tmp+1 : adc rowaddr_hi,x
    cmp #&80 : bcc addr_ok : sbc #&50
.addr_ok
    sta ptr+1
    lda dcol : sta dptr : lda dcol+1 : sta dptr+1
    \ when saving, record this column's screen address
    lda p_mode : cmp #PM_SAVE : beq address : cmp #PM_SAVEONLY : bne do_col
.address
    ldy #0 : lda ptr : sta (sptr),y : iny : lda ptr+1 : sta (sptr),y
    lda sptr : clc : adc #2 : sta sptr : bcc do_col : inc sptr+1
.do_col
    jsr &FFFF                       \ (column routine set above)
    \ the save buffer moves on by one column's worth of rows
    lda sptr : clc : adc rows : sta sptr : bcc sv : inc sptr+1 : .sv

.next_col
    \ next column of sprite data
    lda dcol : clc : adc hgt : sta dcol : bcc nc2 : inc dcol+1 : .nc2
    inc cidx
    lda cidx : cmp cend : bne col_loop

.exit
    lda oldbank : sta ROMSEL_COPY : sta ROMSEL
    rts
}

.dir_bank_tab   EQUB CACHE_BANK, CACHE_BANK, CACHE_BANK, DIR_BANK
.shift_lo_tab   EQUB LO(img_lo0), LO(img_lo1), LO(img_lo2), LO(img_lo3)
                EQUB HI(img_lo0), HI(img_lo1), HI(img_lo2), HI(img_lo3)
.shift_hi_tab   EQUB LO(img_hi0), LO(img_hi1), LO(img_hi2), LO(img_hi3)
                EQUB HI(img_hi0), HI(img_hi1), HI(img_hi2), HI(img_hi3)
.shift_bank_tab EQUB LO(img_bank0), LO(img_bank1), LO(img_bank2), LO(img_bank3)
                EQUB HI(img_bank0), HI(img_bank1), HI(img_bank2), HI(img_bank3)

\ Put back the background saved when a sprite was drawn with PM_SAVE, straight
\ from its save record at sbase (no need to redo the sprite's geometry):
\   header: column count, y0, cells, first_end, last_end, rows
\   then for each column: screen address (2 bytes) and the saved bytes
SAVE_HEADER = 6
.restore_saved
{
    ldy #0 : lda (sbase),y : beq done : sta cidx
    iny : lda (sbase),y : sta y0
    iny : lda (sbase),y : sta cells
    iny : lda (sbase),y : sta first_end
    iny : lda (sbase),y : sta last_end
    iny : lda (sbase),y : sta rows
    lda sbase : clc : adc #SAVE_HEADER : sta sptr
    lda sbase+1 : adc #0 : sta sptr+1
.column
    ldy #0 : lda (sptr),y : sta ptr : iny : lda (sptr),y : sta ptr+1
    lda sptr : clc : adc #2 : sta sptr : bcc nc : inc sptr+1 : .nc
    jsr col_restore
    lda sptr : clc : adc rows : sta sptr : bcc nc2 : inc sptr+1 : .nc2
    dec cidx : bne column
.done
    rts
}

.col_routines_lo EQUB LO(col_plot), LO(col_save), LO(col_restore), LO(col_saveonly), LO(col_rawplot)
.col_routines_hi EQUB HI(col_plot), HI(col_save), HI(col_restore), HI(col_saveonly), HI(col_rawplot)

\ Column routines: ptr = screen address of the column's first cell, dptr = its
\ sprite data, sptr = save buffer. y0, cells, first_end and last_end describe
\ which lines of which character cells are covered (set up once per plot).
\ Within a cell the screen, sprite data and save buffer are all indexed by Y,
\ so dp/sp point y0 bytes before the data and step by 8 per cell.

MACRO COLUMN_SETUP
    sec : lda dptr : sbc y0 : sta dp : lda dptr+1 : sbc #0 : sta dp+1
    sec : lda sptr : sbc y0 : sta sp : lda sptr+1 : sbc #0 : sta sp+1
    lda cells : sta cellsleft
    lda first_end : sta yend
    ldy y0
ENDMACRO

\ Move on to the next character cell down
MACRO STEP_CELL
    lda dp : clc : adc #8 : sta dp : bcc n1 : inc dp+1 : .n1
    lda sp : clc : adc #8 : sta sp : bcc n2 : inc sp+1 : .n2
    lda ptr : clc : adc #LO(640) : sta ptr
    lda ptr+1 : adc #HI(640) : cmp #&80 : bcc n3 : sbc #&50 : .n3 : sta ptr+1
    lda #8 : ldy cellsleft : cpy #1 : bne n4 : lda last_end : .n4 : sta yend
    ldy #0
ENDMACRO

.col_plot
{
    COLUMN_SETUP
.loop
    lda (dp),y : beq clear              \ fully transparent byte: leave the screen alone
    tax
    lda (ptr),y : and masktab,x : ora identity,x : sta (ptr),y
.clear
    iny : cpy yend : bne loop
    dec cellsleft : beq done
    STEP_CELL
    jmp loop
.done
    rts
}

.col_rawplot
{
    COLUMN_SETUP
    lda #0 : ldx cidx : cpx #MAX_RAW_COLS : bcs none : lda rawbits,x
.none
    sta rawcol
.cell
    lsr rawcol : bcs raw
.loop
    lda (dp),y : beq clear
    tax
    lda (ptr),y : and masktab,x : ora identity,x : sta (ptr),y
.clear
    iny : cpy yend : bne loop
.cell_done
    dec cellsleft : beq done
    STEP_CELL
    jmp cell
.raw
    \ a whole cell over empty background (so Y = 0): just copy it
    FOR n, 1, 8
    lda (dp),y : sta (ptr),y : iny
    NEXT
    jmp cell_done
.done
    rts
}

.col_save
{
    COLUMN_SETUP
.loop
    lda (dp),y : beq clear              \ fully transparent byte: just save the screen
    tax
    lda (ptr),y : sta (sp),y
    and masktab,x : ora identity,x : sta (ptr),y
    iny : cpy yend : bne loop
    beq cell_done
.clear
    lda (ptr),y : sta (sp),y
    iny : cpy yend : bne loop
.cell_done
    dec cellsleft : beq done
    STEP_CELL
    jmp loop
.done
    rts
}

.col_saveonly
{
    COLUMN_SETUP
.loop
    lda (ptr),y : sta (sp),y
    iny : cpy yend : bne loop
    dec cellsleft : beq done
    STEP_CELL
    jmp loop
.done
    rts
}

.col_restore
{
    COLUMN_SETUP
.loop
    lda (sp),y : sta (ptr),y
    iny : cpy yend : bne loop
    dec cellsleft : beq done
    STEP_CELL
    jmp loop
.done
    rts
}

\ ------------------------------------------------------------------------------
\ Palette
\ ------------------------------------------------------------------------------

.set_palette
    ldx #0
.colours
    lda vdu_colours,x : jsr OSWRCH : inx : cpx #vdu_init_end - vdu_colours : bne colours
    lda level_bg
\ Set logical colour 0 (the background) to physical colour A
.set_bg
{
    pha
    lda #19 : jsr OSWRCH : lda #0 : jsr OSWRCH
    pla : jsr OSWRCH
    lda #0 : jsr OSWRCH : jsr OSWRCH : jsr OSWRCH
    rts
}

\ ------------------------------------------------------------------------------
\ Collected objects: queued column repaints
\ ------------------------------------------------------------------------------

\ Queue byte columns [draw_c0,x, draw_c1,x) to be repainted in both buffers
.queue_repaint
{
    ldy #1
.loop
    lda draw_c0,x : cmp pend_lo,y : bcs lo_ok : sta pend_lo,y
.lo_ok
    lda draw_c1,x : cmp pend_hi,y : bcc hi_ok : sta pend_hi,y
.hi_ok
    dey : bpl loop
    rts
}

\ Repaint the back buffer's queued columns (the visible ones; the rest will be
\ repainted correctly when they scroll into view)
.do_pending
{
    ldx back
    lda pend_lo,x : cmp pend_hi,x : bcs none
    \ pc_col = max(pend_lo, scrollcol), pc_end = min(pend_hi, scrollcol + 80)
    cmp scrollcol : bcs lo_ok : lda scrollcol
.lo_ok
    sta pc_col
    lda scrollcol : clc : adc #SCREEN_COLS : sta pc_end
    lda pend_hi,x : cmp pc_end : bcs hi_ok : sta pc_end
.hi_ok
    lda #&FF : sta pend_lo,x
    lda #0 : sta pend_hi,x
    lda is_vert : beq loop
    \ (a vertically scrolling level: just the window's rows of those columns)
    lda pc_col : sta rr_c0
    lda pc_end : sec : sbc #1 : sta rr_c1
    lda scrollrow : sta rr_k0 : clc : adc #31 : sta rr_k1
    jmp repaint_rect
.loop
    lda pc_col : cmp pc_end : bcs none
    jsr repaint_column
    inc pc_col
    jmp loop
.none
    rts
}


\ ------------------------------------------------------------------------------
\ Keyboard
\ ------------------------------------------------------------------------------

\ ------------------------------------------------------------------------------
\ Text, in the MOS's font (characters 32-127 are in sideways ROM 15 at &B900,
\ 8 bytes each, top row first, leftmost pixel in bit 7). Each character is 8
\ pixels wide, so 2 bytes of MODE 1, drawn masked in colour txt_colour.
\ ------------------------------------------------------------------------------

FONT_ROM = 15
FONT = &B900

\ Print the string after the JSR: its byte column (0-79), pixel row, then the
\ characters, ending with 0. Returns to the code after it.
.print_inline
{
    pla : sta src : pla : sta src+1                 \ (the address of the last byte of the JSR)
    ldy #1 : lda (src),y : sta txt_col
    iny : lda (src),y : sta txt_y
    lda #0 : sta txt_yh
.loop
    iny : lda (src),y : beq done
    sty txt_i
    jsr print_char
    ldy txt_i
    inc txt_col : inc txt_col
    jmp loop
.done
    tya : clc : adc src : tax : lda src+1 : adc #0 : pha : txa : pha
    rts
}

\ Draw character A at byte column txt_col, pixel row txt_y
.print_char
{
    jsr get_glyph
    \ each row: 2 screen bytes, from the left and right 4 pixels
    lda #0 : sta txt_i2
.row
    lda txt_y : clc : adc txt_i2 : sta tmp : lda txt_yh : adc #0      \ the pixel row (16-bit)
    lsr a : ror tmp : lsr a : ror tmp : lsr a : ror tmp : ldx tmp     \ its character row
    lda txt_y : clc : adc txt_i2 : and #7 : sta tmp+1
    lda #0 : sta tmp
    lda txt_col : asl a : rol tmp : asl a : rol tmp : asl a : rol tmp
    clc : adc tmp+1 : adc rowaddr_lo,x : sta ptr
    lda tmp : adc rowaddr_hi,x : cmp #&80 : bcc ok : sbc #&50 : .ok : sta ptr+1
    ldx txt_i2 : lda txt_glyph,x
    pha : lsr a : lsr a : lsr a : lsr a : ldy #0 : jsr txt_nibble
    pla : and #15 : ldy #8 : jsr txt_nibble
    inc txt_i2 : lda txt_i2 : cmp #8 : bne row
    rts
}

\ txt_glyph = the 8 rows of character A, from the font in ROM 15
.get_glyph
{
    sec : sbc #32 : sta pt : lda #0 : sta pt+1
    asl pt : rol pt+1 : asl pt : rol pt+1 : asl pt : rol pt+1
    lda pt : clc : adc #LO(FONT) : sta pt : lda pt+1 : adc #HI(FONT) : sta pt+1
    sei
    lda #FONT_ROM : sta ROMSEL
    ldy #7
.fetch
    lda (pt),y : sta txt_glyph,y : dey : bpl fetch
    lda ROMSEL_COPY : sta ROMSEL
    cli
    rts
}

\ Draw 4 pixels (A = a nibble, leftmost in bit 3) at (ptr),Y in txt_colour
.txt_nibble
{
    sta tmp
    asl a : asl a : asl a : asl a : ora tmp : eor #&FF   \ mask: the 4 pixels' bits clear
    and (ptr),y : sta tmp+1
    lda txt_colour : lsr a : bcc no_lo : lda tmp : ora tmp+1 : sta tmp+1 : .no_lo
    lda txt_colour : and #2 : beq no_hi
    lda tmp : asl a : asl a : asl a : asl a : ora tmp+1 : sta tmp+1
.no_hi
    lda tmp+1 : sta (ptr),y
    rts
}

\ The front end: A = 0 for the attract screen and then the menus, 1 for just the
\ menus. Returns A = the level to play. It's kept packed in the emptier sprite
\ bank and unpacked into bank 7 (where the level's background goes) each time.
.front_end
{
    pha
    lda #FRONT_BANK : sta ROMSEL_COPY : sta ROMSEL
    jsr fe_stage                    \ (the packed front end to the hidden screen)
    lda #CACHE_BANK : sta ROMSEL_COPY : sta ROMSEL
    jsr fe_unpack                   \ (... and from there to &8000)
    pla : jsr fe_main
    sta last_level
    pha : lda #LEVEL_BANK : sta ROMSEL_COPY : sta ROMSEL : pla
    rts
}

\ Give the result of the level just finished (done_*) to the front end's records
.record_result
{
    lda done_valid : beq none
    lda #0 : sta done_valid
    lda #CACHE_BANK : sta ROMSEL_COPY : sta ROMSEL
    jsr fe_record
    lda #LEVEL_BANK : sta ROMSEL_COPY : sta ROMSEL
.none
    rts
}

\ Unpack the level loader from bank 7 to OVERLAY_RUN (in main RAM's screen
\ memory), blanking the screen first so it doesn't show
.bring_overlay
{
    ldx #0
.blank
    lda blank_vdu,x : jsr OSWRCH : inx : cpx #blank_end - blank_vdu : bne blank
    lda ROMSEL_COPY : pha
    lda #CACHE_BANK : sta ROMSEL_COPY : sta ROMSEL
    lda ACCCON : and #&FB : sta ACCCON      \ (the CPU uses main RAM there)
    lda #LO(OVERLAYZ_ORG) : sta src : lda #HI(OVERLAYZ_ORG) : sta src+1
    lda #LO(OVERLAY_RUN) : sta dp : lda #HI(OVERLAY_RUN) : sta dp+1
    jsr unpack
    pla : sta ROMSEL_COPY : sta ROMSEL
    rts
}
.blank_vdu
    EQUB 19, 0, 0, 0, 0, 0, 19, 1, 0, 0, 0, 0, 19, 2, 0, 0, 0, 0, 19, 3, 0, 0, 0, 0
.blank_end

\ ------------------------------------------------------------------------------
\ Data
\ ------------------------------------------------------------------------------

INCLUDE "src/gen/sprites.asm"
INCLUDE "src/sound_main.asm"

\ Screen address of each character row (level row R lives at char index R*80 MOD 2560)
.rowaddr_lo
FOR r, 0, 127
    EQUB LO(SCREEN + ((r * 80) MOD 2560) * 8)
NEXT
.rowaddr_hi
FOR r, 0, 127
    EQUB HI(SCREEN + ((r * 80) MOD 2560) * 8)
NEXT

.end

\ Draw logs (not saved to disc)
.log_n      SKIP 2                  \ draw log entries per buffer
.log_kind   SKIP 2 * MAX_LOG
.log_img    SKIP 2 * MAX_LOG
.log_xl     SKIP 2 * MAX_LOG
.log_xh     SKIP 2 * MAX_LOG
.log_yl     SKIP 2 * MAX_LOG
.log_yh     SKIP 2 * MAX_LOG
.log_x1l    SKIP 2 * MAX_LOG
.log_x1h    SKIP 2 * MAX_LOG
.log_sbl    SKIP 2 * MAX_LOG
.log_sbh    SKIP 2 * MAX_LOG
.log_bank   SKIP 2 * MAX_LOG          \ sideways RAM bank of the save record (LOG_SPRITE7)

\ Per-buffer state (not saved to disc)
.bscroll    SKIP 2
.brow       SKIP 2          \ scrollrow, per buffer
.bfrak      SKIP 2          \ FRAK! bubble drawn in this buffer
.bwon       SKIP 2          \ level-complete panel drawn in this buffer
.pend_lo    SKIP 2          \ columns waiting to be repainted, per buffer
.pend_hi    SKIP 2
.ram_top

SAVE "FRAK", code_start, end, start

\ ------------------------------------------------------------------------------
\ Sideways RAM bank 6: the collision spans and tables, the game logic and the
\ level loader, then the tables the loader fills in for the current level.
\
\ Bank 6 is paged in whenever the game runs, so the logic can live here,
\ leaving main RAM for the drawing code (which pages the sprite banks in).
\ ------------------------------------------------------------------------------

CLEAR &8000, &C000
ORG &8000
GUARD &C000
.bank6_start
INCBIN "build/SPANS"
INCLUDE "src/gen/collide.asm"
.logic_start

\ ------------------------------------------------------------------------------
\ Moving objects. For now these are meanies flying off after being yoyoed;
\ balloons, daggers and moving meanies will join them.
\ ------------------------------------------------------------------------------

MOVER_RANGE = 400                   \ removed this far from Trogg (as in GameMaker)

MV_FLYING = 1                       \ a meanie knocked flying by the yoyo
MV_BALLOON = 2
MV_DAGGER = 3

\ Find a free mover slot -> Y, carry clear; carry set if there isn't one
.find_mover
{
    ldy #MAX_MOVERS - 1
.find
    lda mv_active,y : beq free
    dey : bpl find
    sec : rts
.free
    lda #0
    sta mv_xf,y : sta mv_yf,y : sta mv_vxf,y : sta mv_vxi,y : sta mv_vyf,y : sta mv_vyi,y : sta mv_pause,y
    clc : rts
}

\ Start a meanie flying off: X = draw-list index, A = whole-pixel x velocity (signed)
.launch_meanie
{
    pha : lda #SFX_SQUEAL : jsr play_sfx : pla
    sta tmp
    jsr find_mover : bcs none       \ no free slot: it just vanishes
    lda #MV_FLYING : sta mv_active,y
    lda tmp : sta mv_vxi,y
    lda draw_img,x : sta mv_img,y
    lda draw_xl,x : sta mv_xl,y : lda draw_xh,x : sta mv_xh,y
    lda draw_yl,x : sta mv_yl,y : lda draw_yh,x : sta mv_yh,y
.none
    rts
}

\ Move everything one tick, removing what has gone
.update_movers
{
    ldx #MAX_MOVERS - 1
.loop
    lda mv_active,x : bne active
    jmp next
.active
    lda mv_pause,x : beq move
    dec mv_pause,x
    jmp next
.move
    \ x += vx, y += vy (16.8 + signed 8.8)
    ldy #0 : lda mv_vxi,x : bpl xs : dey : .xs : sty tmp
    clc
    lda mv_xf,x : adc mv_vxf,x : sta mv_xf,x
    lda mv_xl,x : adc mv_vxi,x : sta mv_xl,x
    lda mv_xh,x : adc tmp : sta mv_xh,x
    ldy #0 : lda mv_vyi,x : bpl ys : dey : .ys : sty tmp
    clc
    lda mv_yf,x : adc mv_vyf,x : sta mv_yf,x
    lda mv_yl,x : adc mv_vyi,x : sta mv_yl,x
    lda mv_yh,x : adc tmp : sta mv_yh,x

    lda mv_active,x
    cmp #MV_BALLOON : beq balloon
    cmp #MV_DAGGER : beq dagger

    \ Flying meanie: gone once it's MOVER_RANGE from Trogg (or off the left of the level)
    lda mv_xh,x : bmi gone
    lda mv_xl,x : sec : sbc tx : sta tmp : lda mv_xh,x : sbc tx+1
    bpl pos
    eor #&FF : sta tmp+1 : lda tmp : eor #&FF : clc : adc #1 : sta tmp
    lda tmp+1 : adc #0
.pos
    sta tmp+1
    lda tmp : cmp #LO(MOVER_RANGE) : lda tmp+1 : sbc #HI(MOVER_RANGE) : bcc next
    bcs gone

.balloon
    \ gone when it floats off the top (y < 0)
    lda mv_yh,x : bmi gone
    bpl next

.dagger
    \ gone at the bottom of the level, or once x <= -11
    lda mv_yl,x : cmp level_h : lda mv_yh,x : sbc level_h+1
    bvc nv : eor #&80 : .nv
    bpl gone
    lda mv_xl,x : cmp #LO(-10) : lda mv_xh,x : sbc #HI(-10)
    bvc nv2 : eor #&80 : .nv2
    bmi gone
    jmp next

.gone
    lda #0 : sta mv_active,x
.next
    dex : bmi done
    jmp loop
.done
    rts
}

\ ------------------------------------------------------------------------------
\ Balloons and daggers (port of the oRoom Step event, oBalloon and oDagger)
\ ------------------------------------------------------------------------------

\ Per-difficulty settings (from the Steam version's oRoom Create), in game ticks
\ and 8.8 fixed-point pixels a tick
MACRO DIFF_TABLE b0, b1, b2, b3, b4, b5, b6
    EQUB b0, b1, b2, b3, b4, b5, b6
ENDMACRO
.diff_balloon_time  DIFF_TABLE 0, 180, 120, 120, 90, 90, 60
.diff_dagger_time   DIFF_TABLE 0, 220, 132, 132, 110, 110, 75
.diff_pause         DIFF_TABLE 0, 60, 55, 55, 50, 50, 45
.diff_balloon_vf    DIFF_TABLE 0, LO(307), LO(333), LO(333), LO(358), LO(358), LO(384)     \ 1.2 .. 1.5
.diff_balloon_vi    DIFF_TABLE 0, HI(307), HI(333), HI(333), HI(358), HI(358), HI(384)
.diff_dagger_xf     DIFF_TABLE 0, LO(205), LO(225), LO(225), LO(246), LO(246), LO(266)     \ 0.8 * (1.0 .. 1.3)
.diff_dagger_xi     DIFF_TABLE 0, HI(205), HI(225), HI(225), HI(246), HI(246), HI(266)
.diff_dagger_yf     DIFF_TABLE 0, LO(154), LO(169), LO(169), LO(184), LO(184), LO(200)     \ 0.6 * (1.0 .. 1.3)
.diff_dagger_yi     DIFF_TABLE 0, HI(154), HI(169), HI(169), HI(184), HI(184), HI(200)
.diff_spread_l      DIFF_TABLE 0, LO(270), LO(280), LO(280), LO(290), LO(290), LO(300)
\ (vertically scrolling levels: balloons spread 1.25 times as wide, daggers 1.15)
.vdiff_bspread_l    DIFF_TABLE 0, LO(337), LO(350), LO(350), LO(362), LO(362), LO(375)
.vdiff_bspread_h    DIFF_TABLE 0, HI(337), HI(350), HI(350), HI(362), HI(362), HI(375)
.vdiff_dspread_l    DIFF_TABLE 0, LO(310), LO(322), LO(322), LO(333), LO(333), LO(345)
.vdiff_dspread_h    DIFF_TABLE 0, HI(310), HI(322), HI(322), HI(333), HI(333), HI(345)
.diff_spread_h      DIFF_TABLE 0, HI(270), HI(280), HI(280), HI(290), HI(290), HI(300)

\ Called once per tick while Trogg is alive
.spawn_hazards
{
    ldx difficulty
    lda diff_balloon_time,x : beq no_balloons
    lda bal_timer : beq spawn_b
    dec bal_timer : bne no_balloons
.spawn_b
    jsr spawn_balloon
    ldx difficulty
    lda diff_balloon_time,x : sta bal_timer
.no_balloons
    ldx difficulty
    lda diff_dagger_time,x : beq no_daggers
    lda dag_timer : beq spawn_d
    dec dag_timer : bne no_daggers
.spawn_d
    jsr spawn_dagger
    ldx difficulty
    lda diff_dagger_time,x : sta dag_timer
.no_daggers
    rts
}

\ A balloon at the bottom of the level, at a random x within spread/2 of Trogg
.spawn_balloon
{
    jsr find_mover : bcc have_slot
    rts
.have_slot
    sty sp_slot
    lda tx : sta sp_mid : lda tx+1 : sta sp_mid+1
    ldx difficulty
    lda is_vert : beq b_spread
    lda vdiff_bspread_l,x : sta sp_spread : lda vdiff_bspread_h,x : sta sp_spread+1
    jmp b_spread_ok
.b_spread
    lda diff_spread_l,x : sta sp_spread : lda diff_spread_h,x : sta sp_spread+1
.b_spread_ok
    jsr random_x
    ldy sp_slot : ldx difficulty
    lda #MV_BALLOON : sta mv_active,y
    lda #IMG_Balloon : sta mv_img,y
    lda sp_x : sta mv_xl,y : lda sp_x+1 : sta mv_xh,y
    lda level_h : sec : sbc #4 : sta mv_yl,y : lda level_h+1 : sbc #0 : sta mv_yh,y
    \ vy = -balloon speed
    lda #0 : sec : sbc diff_balloon_vf,x : sta mv_vyf,y
    lda #0 : sbc diff_balloon_vi,x : sta mv_vyi,y
    lda diff_pause,x : sta mv_pause,y
.none
    rts
}

\ A dagger at the top, aimed ahead of Trogg: the middle of its range is
\ x + h * 4/3, where h = max(0, y - 4), so that it arrives about where he is
.spawn_dagger
{
    jsr find_mover : bcc have_slot
    rts
.have_slot
    sty sp_slot
    lda ty : sec : sbc #4 : sta tmp : lda ty+1 : sbc #0 : sta tmp+1 : bpl h_ok
    lda #0 : sta tmp : sta tmp+1
.h_ok
    ldx difficulty
    lda is_vert : bne v_aim
    \ (horizontally scrolling levels are 256 high, so h fits in a byte)
    \ mid = tx + h + h * 85 / 256  (h * 1.332)
    lda tmp : sta mul_a : lda #85 : jsr mul8      \ A = high byte of h * 85
    clc : adc tmp : sta sp_mid : lda #0 : adc #0 : sta sp_mid+1
    lda diff_spread_l,x : sta sp_spread : lda diff_spread_h,x : sta sp_spread+1
    jmp aimed
.v_aim
    \ a vertically scrolling level: mid = tx + h * 0.75 (h - h / 4)
    lda tmp+1 : lsr a : sta sp_mid+1 : lda tmp : ror a : lsr sp_mid+1 : ror a : sta sp_mid
    lda tmp : sec : sbc sp_mid : sta sp_mid : lda tmp+1 : sbc sp_mid+1 : sta sp_mid+1
    lda vdiff_dspread_l,x : sta sp_spread : lda vdiff_dspread_h,x : sta sp_spread+1
.aimed
    lda sp_mid : clc : adc tx : sta sp_mid : lda sp_mid+1 : adc tx+1 : sta sp_mid+1
    jsr random_x
    ldy sp_slot : ldx difficulty
    lda #MV_DAGGER : sta mv_active,y
    lda sp_x : sta mv_xl,y : lda sp_x+1 : sta mv_xh,y
    lda #4 : sta mv_yl,y : lda #0 : sta mv_yh,y
    lda diff_pause,x : sta mv_pause,y
    lda is_vert : bne v_dagger
    lda #IMG_DaggerLR : sta mv_img,y
    \ down and to the left (x speed 0.8, y 0.6 of its speed)
    lda #0 : sec : sbc diff_dagger_xf,x : sta mv_vxf,y
    lda #0 : sbc diff_dagger_xi,x : sta mv_vxi,y
    lda diff_dagger_yf,x : sta mv_vyf,y
    lda diff_dagger_yi,x : sta mv_vyi,y
    rts
.v_dagger
    lda #IMG_DaggerUD : sta mv_img,y
    \ (x speed 0.6, y 0.8)
    lda #0 : sec : sbc diff_dagger_yf,x : sta mv_vxf,y
    lda #0 : sbc diff_dagger_yi,x : sta mv_vxi,y
    lda diff_dagger_xf,x : sta mv_vyf,y
    lda diff_dagger_xi,x : sta mv_vyi,y
.none
    rts
}

\ sp_x = sp_mid - spread/2 + random(0 .. spread)
.random_x
{
.retry
    jsr random
    lda rng+1 : and #1 : sta tmp+1 : lda rng : sta tmp       \ 0 .. 511
    lda sp_spread : cmp tmp : lda sp_spread+1 : sbc tmp+1 : bcc retry
    \ sp_x = sp_mid + tmp - spread / 2
    lda sp_spread+1 : lsr a : sta sp_x+1 : lda sp_spread : ror a : sta sp_x
    lda sp_mid : clc : adc tmp : sta tmp : lda sp_mid+1 : adc tmp+1 : sta tmp+1
    lda tmp : sec : sbc sp_x : sta sp_x : lda tmp+1 : sbc sp_x+1 : sta sp_x+1
    rts
}

\ 16-bit xorshift random numbers (John Metcalf's 7/9/8 version)
.random
{
    lda rng+1 : lsr a
    lda rng : ror a : eor rng+1 : sta rng+1
    ror a : eor rng : sta rng
    eor rng+1 : sta rng+1
    rts
}

\ A = high byte of mul_a * A
.mul8
{
    sta mul_b
    lda #0 : ldx #8
.loop
    lsr mul_b : bcc no_add
    clc : adc mul_a
.no_add
    ror a : ror mul_lo
    dex : bne loop
    rts
}

\ ------------------------------------------------------------------------------
\ Collisions between Trogg and keys, gems and meanies
\
\ Like GameMaker's precise collisions, but using the leftmost and rightmost solid
\ pixel of each row (the "spans", in sideways RAM bank 6): after a bounding-box
\ check, Trogg and the object collide if their spans overlap on any shared row.
\ ------------------------------------------------------------------------------

.check_collisions
{
    jsr trogg_image : sta ct_img : tax
    sec : lda tx : sbc img_xo,x : sta ct_l : lda tx+1 : sbc #0 : sta ct_l+1
    sec : lda ty : sbc img_yo,x : sta ct_t : lda ty+1 : sbc #0 : sta ct_t+1
    \ Trogg's byte columns: [ct_c0, ct_c0 + 8), for a quick first test
    lda ct_l+1 : bmi left_edge
    lda ct_l : sta tmp : lda ct_l+1
    lsr a : ror tmp : lsr a : ror tmp
    lda tmp : jmp have_c0
.left_edge
    lda #0
.have_c0
    sta ct_c0
    clc : adc #8 : sta ct_c1
    lda ROMSEL_COPY : pha
    lda #LEVEL_BANK : sta ROMSEL_COPY : sta ROMSEL
    lda #0 : sta co_i
.loop
    ldx co_i
    lda alive,x : beq next
    lda draw_c1,x : cmp ct_c0 : bcc next : beq next  \ object ends left of Trogg
    lda draw_c0,x : cmp ct_c1 : bcs next             \ object starts right of Trogg
    \ c_dx = object left - Trogg left; must be in -64..63
    sec : lda draw_ll,x : sbc ct_l : sta c_dx
    lda draw_lh,x : sbc ct_l+1
    jsr in_range_64 : bcc next
    \ c_dy = object top - Trogg top
    sec : lda draw_tl,x : sbc ct_t : sta c_dx+1
    lda draw_th,x : sbc ct_t+1
    sta tmp+1 : lda c_dx+1 : sta c_dy : lda tmp+1
    jsr in_range_64_dy : bcc next
    ldx co_i : lda draw_img,x : sta c_oimg
    jsr hit_test : bcc next
    ldx co_i
    jsr collide
.next
    inc co_i
    lda co_i : cmp num_draw : bcc loop

    \ Moving objects (balloons, daggers, meanies flying off) are all deadly
    lda #MAX_MOVERS - 1 : sta mvc_i
.mloop
    ldx mvc_i
    lda mv_active,x : bne m_on
    jmp mnext
.m_on
    ldy mv_img,x : sty c_oimg
    \ c_dx = (x - xo) - Trogg left, c_dy = (y - yo) - Trogg top
    lda mv_xl,x : sec : sbc img_xo,y : sta tmp : lda mv_xh,x : sbc #0 : sta tmp+1
    lda tmp : sec : sbc ct_l : sta c_dx : lda tmp+1 : sbc ct_l+1
    jsr in_range_64 : bcc mnext
    ldx mvc_i : ldy c_oimg
    lda mv_yl,x : sec : sbc img_yo,y : sta tmp : lda mv_yh,x : sbc #0 : sta tmp+1
    lda tmp : sec : sbc ct_t : sta c_dy : lda tmp+1 : sbc ct_t+1
    jsr in_range_64_dy : bcc mnext
    jsr hit_test : bcc mnext
    jsr trogg_dies
.mnext
    dec mvc_i : bmi m_done
    jmp mloop
.m_done
    jsr collide_slow
    pla : sta ROMSEL_COPY : sta ROMSEL
    rts
}

\ A = high byte, c_dx = low byte of a 16-bit difference: carry set if -64..63
.in_range_64
{
    beq pos
    cmp #&FF : bne no
    lda c_dx : cmp #&C0 : rts       \ carry set if >= -64
.pos
    lda c_dx : cmp #64 : bcs no
    sec : rts
.no
    clc : rts
}
.in_range_64_dy
{
    beq pos
    cmp #&FF : bne no
    lda c_dy : cmp #&C0 : rts
.pos
    lda c_dy : cmp #64 : bcs no
    sec : rts
.no
    clc : rts
}

\ Does Trogg (image ct_img) overlap object co_i at offset (c_dx, c_dy)?
\ Carry set if so. The spans bank must be paged in.
.hit_test
{
    \ Offsets biased by 128 so that everything is an unsigned compare
    lda c_dx : eor #&80 : sta c_dxb
    lda c_dy : eor #&80 : sta c_dyb
    \ Tight bounding boxes: object x0 + dx <= trogg x1  and  object x1 + dx >= trogg x0
    ldx c_oimg : ldy ct_img
    lda img_bx0,x : clc : adc c_dxb : sta tmp
    lda img_bx1,y : ora #&80 : cmp tmp : bcc early_miss
    lda img_bx1,x : clc : adc c_dxb : sta tmp
    lda img_bx0,y : ora #&80 : sta tmp+1
    lda tmp : cmp tmp+1 : bcc early_miss
    \ ... and the same vertically
    lda img_by0,x : clc : adc c_dyb : sta tmp
    lda img_by1,y : ora #&80 : cmp tmp : bcc early_miss
    lda img_by1,x : clc : adc c_dyb : sta tmp
    lda img_by0,y : ora #&80 : sta tmp+1
    lda tmp : cmp tmp+1 : bcc early_miss

    jmp rows
.early_miss
    clc : rts
.rows
    \ Shared rows, in Trogg's coordinates: rs = max(0, dy), re = min(trogg h, dy + object h)
    lda c_dy : bpl dy_pos
    lda #0
.dy_pos
    sta c_rs
    lda c_dy : clc : adc img_h,x            \ dy + object height (signed, -64..105)
    bmi early_miss
    cmp img_h,y : bcc re_ok : lda img_h,y
.re_ok
    sec : sbc c_rs : beq early_miss : bcc early_miss
    sta c_rows

    \ pT = trogg spans + rs*2, pO = object spans + (rs - dy)*2
    lda c_rs : asl a : clc : adc img_span_lo,y : sta pt
    lda img_span_hi,y : adc #0 : sta pt+1
    lda c_rs : sec : sbc c_dy : asl a : clc : adc img_span_lo,x : sta po
    lda img_span_hi,x : adc #0 : sta po+1

    ldy #0
.row
    lda (pt),y : cmp #255 : beq skip_row    \ Trogg's row is empty
    sta c_tl
    lda (po),y : cmp #255 : beq skip_row    \ object's row is empty
    clc : adc c_dxb : sta tmp               \ object left (biased)
    iny
    lda (pt),y : ora #&80 : cmp tmp : bcc row_miss     \ Trogg right < object left
    lda (po),y : clc : adc c_dxb : sta tmp             \ object right (biased)
    lda c_tl : ora #&80 : sta tmp+1
    lda tmp : cmp tmp+1 : bcs hit                      \ object right >= Trogg left
.row_miss
    iny
    jmp next_row
.skip_row
    iny : iny
.next_row
    dec c_rows : bne row
.miss
    clc : rts
.hit
    sec : rts
}

\ Trogg has touched object X
.collide
{
    lda draw_kind,x
    cmp #KIND_MEANIE : bne pickup
    jmp trogg_dies
.pickup
    lda #0 : sta alive,x
    lda #SFX_CHING : jsr play_sfx
    jsr queue_repaint
    lda draw_kind,x
    cmp #KIND_GEM : bne not_gem
    inc gems_found
    rts
.not_gem
    cmp #KIND_KEY : bne done
    inc keys_found
    lda keys_found : cmp num_keys : bne more_keys
    jmp level_complete                  \ all the keys!
.more_keys
    lda #1 : sta save_cp                \ checkpoint once Trogg is standing still
.done
    rts
}

\ Save a checkpoint after collecting a key, once Trogg is standing on a platform
.check_checkpoint
{
    lda save_cp : beq done
    lda tstate : cmp #ST_WALK + 1 : bcs done      \ standing or walking only
    \ ... on a platform that isn't moving
    ldx cur_plat : cpx #255 : beq done
    lda plat_moving,x : bne done
    lda #0 : sta save_cp
    lda #1 : sta have_cp
    ldx #MAX_OBJECTS - 1
.objs
    lda alive,x : sta cp_alive,x : dex : bpl objs
    lda keys_found : sta cp_keys
    lda gems_found : sta cp_gems
    lda tx : sta cp_tx : lda tx+1 : sta cp_tx+1
    lda ty : sta cp_ty : lda ty+1 : sta cp_ty+1 : lda tyf : sta cp_tyf
    lda tface : sta cp_face
    lda bal_timer : sta cp_bal : lda dag_timer : sta cp_dag
    jsr slow_save_checkpoint
.done
    rts
}

\ ------------------------------------------------------------------------------
\ Platforms and ladders (ports of PlatformFind and LadderFind)
\ ------------------------------------------------------------------------------

\ Find the highest platform top in [q_y1, q_y2) under column q_x (if two are at
\ the same height, the first, as PlatformFind). Returns res_found = 1, res_y =
\ its y and res_i = which.
.platform_find
{
    lda #0 : sta res_found
    ldx num_plats : bne some
    rts
.some
    dex
.loop
    \ y1 <= py ?
    lda plat_yl,x : cmp q_y1 : lda plat_yh,x : sbc q_y1+1 : bcc next
    \ py < y2 ?
    lda plat_yl,x : cmp q_y2 : lda plat_yh,x : sbc q_y2+1 : bcs next
    \ px <= x ?
    lda q_x : cmp plat_xl,x : lda q_x+1 : sbc plat_xh,x : bcc next
    \ x < px + w ?
    lda plat_xl,x : clc : adc plat_w,x : sta tmp
    lda plat_xh,x : adc #0 : sta tmp+1
    lda q_x : cmp tmp : lda q_x+1 : sbc tmp+1 : bcs next
    \ keep the highest (smallest y), and of those the first (going down the list)
    lda res_found : beq take
    lda plat_yl,x : cmp res_y : lda plat_yh,x : sbc res_y+1 : bcc take
    lda plat_yl,x : cmp res_y : bne next
    lda plat_yh,x : cmp res_y+1 : bne next
.take
    lda #1 : sta res_found
    lda plat_yl,x : sta res_y : lda plat_yh,x : sta res_y+1
    stx res_i
.next
    dex : bpl loop
.none
    rts
}

\ PlatformFind(x, y1, y2) with y1 and y2 in pixels and twentieths ((q_y1, q_y1f)
\ and (q_y2, q_y2f)): the platforms at ceil(y1) <= y < y2 are those at whole
\ pixels in [ceil(y1), ceil(y2)). (q_y1 and q_y2 become those.)
.platform_find_f
{
    lda q_y1f : beq y1_ok : inc q_y1 : bne y1_ok : inc q_y1+1
.y1_ok
    lda q_y2f : beq y2_ok : inc q_y2 : bne y2_ok : inc q_y2+1
.y2_ok
    jmp platform_find
}

\ (q_y1, q_y1f) = Trogg's y
.q1_is_y
{
    lda ty : sta q_y1 : lda ty+1 : sta q_y1+1 : lda tyf : sta q_y1f
    rts
}

\ (q_y2, q_y2f) = Trogg's y + A twentieths (signed)
.q2_is_y_plus
{
    ldx ty : stx q_y2 : ldx ty+1 : stx q_y2+1
    clc : adc tyf
.neg
    cmp #&80 : bcc pos                  \ (below 0: a pixel less)
    adc #20 - 1                         \ (carry set: + 20)
    ldx q_y2 : bne n1 : dec q_y2+1 : .n1 : dec q_y2
    jmp neg
.pos
    cmp #20 : bcc done                  \ (20 or more: a pixel more)
    sbc #20
    inc q_y2 : bne pos : inc q_y2+1 : jmp pos
.done
    sta q_y2f
    rts
}

\ Trogg's position = res_x, (res_y, res_yf)
.move_to_res
{
    lda res_x : sta tx : lda res_x+1 : sta tx+1
.^move_y_to_res
    lda res_y : sta ty : lda res_y+1 : sta ty+1 : lda res_yf : sta tyf
    rts
}

\ Can Trogg at (q_x, y1) move along a ladder towards y2? (LadderFind, with y1 and
\ y2 in pixels and twentieths: (q_y1, q_y1f) and (q_y2, q_y2f).) q_onplat and
\ q_jump as its isOnPlatform and isJumping. Returns res_found, res_x, (res_y,
\ res_yf) and res_i (which).
.ladder_find
{
    lda #0 : sta res_found
    lda q_x : sta res_x : lda q_x+1 : sta res_x+1
    lda q_y1 : sta res_y : lda q_y1+1 : sta res_y+1 : lda q_y1f : sta res_yf
    \ going up (y2 < y1) or down? Nothing if they're the same
    lda #0 : sta lf_up
    lda q_y2 : cmp q_y1 : lda q_y2+1 : sbc q_y1+1 : bcc is_up
    lda q_y2 : cmp q_y1 : bne start
    lda q_y2+1 : cmp q_y1+1 : bne start
    lda q_y2f : cmp q_y1f : bcc is_up : bne start
    rts
.is_up
    inc lf_up
.start
    ldx #0
.loop
    cpx num_ladders : bne check
    rts
.check
    \ only ladders within 6 pixels of q_x (5 to the left of one at x + 0.5)
    lda q_x : sec : sbc lad_xl,x : sta tmp
    lda q_x+1 : sbc lad_xh,x
    beq pos
    cmp #&FF : bne next
    lda tmp : cmp #&FA : bcc next
    bne near
    lda lad_half,x : bne next
    beq near
.pos
    lda tmp : cmp #7 : bcs next
.near
    lda lad_yl,x : sta lad_top : lda lad_yh,x : sta lad_top+1
    lda lad_hl,x : sta lad_len : lda lad_hh,x : sta lad_len+1
    lda lf_up : bne going_up
    jmp going_down
.next
    inx : jmp loop

.going_up
    \ (jumping: not the invisible part above the top)
    lda q_jump : beq up1
    lda lad_top : clc : adc lad_ext,x : sta lad_top : bcc nc1 : inc lad_top+1 : .nc1
    lda lad_len : sec : sbc lad_ext,x : sta lad_len : bcs nc2 : dec lad_len+1 : .nc2
.up1
    lda q_onplat : beq up2
    \ skip if lad_top > y1
    lda q_y1 : cmp lad_top : lda q_y1+1 : sbc lad_top+1 : bcc next
.up2
    \ need res_y >= lad_top and y2 < lad_top + lad_len (whole-pixel tops: the
    \ twentieths don't matter)
    lda res_y : cmp lad_top : lda res_y+1 : sbc lad_top+1 : bcc next
    lda lad_top : clc : adc lad_len : sta tmp
    lda lad_top+1 : adc lad_len+1 : sta tmp+1
    lda q_y2 : cmp tmp : lda q_y2+1 : sbc tmp+1 : bcs next
    jsr found_x
    \ res_y = max(y2, lad_top), and stop if that's y2
    lda q_y2 : cmp lad_top : lda q_y2+1 : sbc lad_top+1
    bcs use_y2
    lda lad_top : sta res_y : lda lad_top+1 : sta res_y+1
    lda #0 : sta res_yf
    jmp next
.use_y2
    lda q_y2 : sta res_y : lda q_y2+1 : sta res_y+1 : lda q_y2f : sta res_yf
    rts

.next_d
    jmp next

.going_down
    lda q_onplat : beq dn1
    \ skip if lad_top < y1
    lda lad_top : cmp q_y1 : lda lad_top+1 : sbc q_y1+1 : bcc next_d
    lda lad_top : cmp q_y1 : bne dn1
    lda lad_top+1 : cmp q_y1+1 : bne dn1
    lda q_y1f : bne next_d
.dn1
    \ tmp = lad_top + lad_len - 1 (bottom)
    lda lad_top : clc : adc lad_len : sta tmp
    lda lad_top+1 : adc lad_len+1 : sta tmp+1
    lda tmp : bne dn2 : dec tmp+1 : .dn2 : dec tmp
    \ need res_y < bottom and y2 >= lad_top
    lda res_y : cmp tmp : lda res_y+1 : sbc tmp+1 : bcs next_d
    lda q_y2 : cmp lad_top : lda q_y2+1 : sbc lad_top+1 : bcc next_d
    jsr found_x
    \ res_y = min(y2, bottom), and stop if that's y2
    lda q_y2 : cmp tmp : lda q_y2+1 : sbc tmp+1 : bcc use_y2b
    lda q_y2 : cmp tmp : bne bottom
    lda q_y2+1 : cmp tmp+1 : bne bottom
    lda q_y2f : bne bottom
.use_y2b
    jmp use_y2
.bottom
    lda tmp : sta res_y : lda tmp+1 : sta res_y+1
    lda #0 : sta res_yf
    jmp next_d

    \ res_x = x + sign(ladx - x)
.found_x
    lda #1 : sta res_found
    stx res_i
    lda q_x : sta res_x : lda q_x+1 : sta res_x+1
    lda lad_xl,x : cmp q_x : lda lad_xh,x : sbc q_x+1
    bcc dec_x
    lda lad_xl,x : cmp q_x : bne inc_x
    lda lad_xh,x : cmp q_x+1 : bne inc_x
    lda lad_half,x : beq fx_done          \ (at x of one at x + 0.5: right)
.inc_x
    inc res_x : bne fx_done : inc res_x+1
    rts
.dec_x
    lda res_x : bne dx1 : dec res_x+1 : .dx1 : dec res_x
.fx_done
    rts
}

\ ------------------------------------------------------------------------------
\ Trogg movement (ports of TroggStanding, TroggFalling and TroggClimbing)
\ ------------------------------------------------------------------------------

\ Trogg's movement for one tick. He is carried along by the platform he was
\ standing on (as in GameMaker, by however far it moved since last tick).
.trogg_update
{
    lda cur_plat : cmp #255 : beq no_ride
    tay
    lda plat_xl,y : sec : sbc last_px : sta tmp : lda plat_xh,y : sbc last_px+1 : sta tmp+1
    lda tx : clc : adc tmp : sta tx : lda tx+1 : adc tmp+1 : sta tx+1
    lda plat_yl,y : sec : sbc last_py : sta tmp : lda plat_yh,y : sbc last_py+1 : sta tmp+1
    lda ty : clc : adc tmp : sta ty : lda ty+1 : adc tmp+1 : sta ty+1
    lda #255 : sta cur_plat
.no_ride
    jsr trogg_move
    \ remember where his platform is now
    lda cur_plat : cmp #255 : beq done
    lda dead : bne done
    ldy cur_plat
    lda plat_xl,y : sta last_px : lda plat_xh,y : sta last_px+1
    lda plat_yl,y : sta last_py : lda plat_yh,y : sta last_py+1
.done
    rts
}

.trogg_move
{
    lda tstate
    cmp #ST_FALL : bne not_fall : jmp trogg_falling
.not_fall
    cmp #ST_CLIMB : bne not_climb : jmp trogg_climbing
.not_climb
    cmp #ST_YOYO_OUT : bne not_out : jmp yoyo_out
.not_out
    cmp #ST_YOYO_BACK : bne not_back : jmp yoyo_back
.not_back
    \ fall through to standing/walking
}

.trogg_standing
{
    \ nx = tx + xmove; PlatformFind(nx, y, y + 1)
    lda xmove : jsr add_x_signed       \ q_x = tx + A
    jsr q1_is_y : lda #20 : jsr q2_is_y_plus
    jsr platform_find_f
    lda res_i : sta plat_hit
    \ on it only if exactly at its top (between pixels above it, he drops onto it)
    lda res_found : beq off
    lda tyf : beq on_platform
.off
    jsr move_to_qx
    lda xmove : sta xvel
    lda #0
    ldx ymove : beq start_fall : bmi start_fall
    lda #JUMP_SPEED
.start_fall
    sta tv
    \ (no up/down debounce: the Steam version's TroggStanding asks for one, but its
    \ caller ignores it, so holding up through a jump catches a ladder on the way)
    lda #ST_FALL : sta tstate
    rts

.on_platform
    lda ymove : beq walk
    \ Try a ladder: LadderFind(nx, y, y - ymove, onplat, jumping)
    jsr q1_is_y
    lda #256 - 20 : ldx ymove : bpl updown : lda #20 : .updown
    jsr q2_is_y_plus
    lda #1 : sta q_onplat : sta q_jump
    jsr ladder_find
    lda res_found : beq no_ladder
    jsr move_to_res
    jmp start_climbing
.no_ladder
    lda ymove : bmi walk
    \ Jump
    jsr move_to_qx
    lda xmove : sta xvel
    lda #JUMP_SPEED : sta tv
    lda #ST_FALL : sta tstate
    rts

.walk
    lda plat_hit : sta cur_plat
    jsr move_to_qx
    lda doyoyo : beq no_yoyo
    jmp start_yoyo
.no_yoyo
    lda xmove : beq stand
    bmi face_left
    lda #0 : sta tface : beq walking
.face_left
    lda #1 : sta tface
.walking
    lda #ST_WALK : sta tstate
    jmp animate
.stand
    lda #ST_STAND : sta tstate
    rts
}

\ q_x = tx + A (A signed)
.add_x_signed
{
    tay
    clc : adc tx : sta q_x
    tya : bmi neg
    lda tx+1 : adc #0 : sta q_x+1
    rts
.neg
    lda tx+1 : adc #&FF : sta q_x+1
    rts
}

.move_to_qx
    lda q_x : sta tx : lda q_x+1 : sta tx+1
    rts

.animate
    lda anim : clc : adc #30 : sta anim     \ ~7 frames a second, as in GameMaker
    rts

\ p_x, p_y = where platform X's spring goes: under its middle (3 rows higher
\ under a log). X kept.
.spring_pos
{
    lda plat_w,x : lsr a : clc : adc plat_xl,x : sta p_x
    lda plat_xh,x : adc #0 : sta p_x+1
    stx tmp
    lda plat_img,x : tax : lda img_h,x
    cpx #IMG_Log1 : bcc not_log : cpx #IMG_Log5 + 1 : bcs not_log
    sbc #2                                          \ (carry clear: 3)
.not_log
    ldx tmp
    clc : adc plat_yl,x : sta p_y : lda plat_yh,x : adc #0 : sta p_y+1
    rts
}

\ For the level loader's bg_items: if platform X is bouncy, background item Y
\ (then Y + 1) is its spring. X kept.
.spring_item
{
    lda plat_bouncy,x : beq done
    jsr spring_pos
    lda #IMG_Spring : sta BG_IMG,y
    lda p_x : sta BG_XL,y : lda p_x+1 : sta BG_XH,y
    lda p_y : sta BG_YL,y : lda p_y+1 : sta BG_YH,y
    iny
.done
    rts
}

\ Draw (into the draw log) the springs of the bouncy platforms that move: they
\ can't be in the background like the others
.draw_springs
{
    ldx num_plats
.loop
    dex : bmi done
    lda plat_moving,x : beq loop
    lda plat_bouncy,x : beq loop
    jsr spring_pos
    lda #IMG_Spring : sta p_img
    txa : pha : jsr log_sprite : pla : tax
    jmp loop
.done
    rts
}

.trogg_falling
{
    \ x += xvel, clamped to [12, LEVEL_W - 10]
    lda xvel : jsr add_x_signed
    jsr move_to_qx
    lda tx : cmp #12 : lda tx+1 : sbc #0 : bcs x_ok1
    lda #12 : sta tx : lda #0 : sta tx+1
.x_ok1
    lda tx : cmp x_max : lda tx+1 : sbc x_max+1 : bcc x_ok2
    lda x_max : sta tx : lda x_max+1 : sta tx+1
.x_ok2
    lda tx : sta q_x : lda tx+1 : sta q_x+1

    \ gravity, down to terminal velocity
    lda tv : sta tv_prev
    cmp #256 - TERMINAL_SPEED : beq no_gravity
    dec tv
.no_gravity

    \ Grab a ladder? (up or down held, and not falling faster than 1.275 pixels a tick)
    lda ymove : beq no_grab
    lda tv : clc : adc #25 : bmi no_grab
    \ LadderFind(x, y, y - yvel, false, true)
    jsr q1_is_y
    lda #0 : sec : sbc tv : jsr q2_is_y_plus
    lda #0 : sta q_onplat : lda #1 : sta q_jump
    jsr ladder_find
    lda res_found : beq no_grab
    jsr move_to_res
    lda #0 : sta xvel : sta tv
    lda #1 : sta lr_db
    jmp start_climbing
.no_grab

    \ y2 = y - yvel
    lda #0 : sec : sbc tv : jsr q2_is_y_plus
    lda tv : bmi falling
    jmp to_y2                       \ (rising: nothing in the way)
.falling
    \ land on a platform between y and y2? PlatformFind(x, y, y2)
    lda q_y2 : sta fy2 : lda q_y2+1 : sta fy2+1 : lda q_y2f : sta fy2f
    jsr q1_is_y
    jsr platform_find_f
    lda res_found : bne hit
    lda fy2 : sta q_y2 : lda fy2+1 : sta q_y2+1 : lda fy2f : sta q_y2f
.to_y2
    lda q_y2 : sta ty : lda q_y2+1 : sta ty+1 : lda q_y2f : sta tyf
    jmp bottom
.hit
    ldx res_i : lda plat_bouncy,x : beq land
    \ a bouncy platform throws him back up from its top: the Steam version
    \ reverses his speed from before gravity, plus twice gravity
    lda res_y : sta ty : lda res_y+1 : sta ty+1
    lda #0 : sta tyf
    lda #2 : sec : sbc tv_prev : sta tv
    jmp bottom
.land
    \ (he stays where he is: if that's between pixels above it, he drops onto it next)
    lda tv : clc : adc #32 : sta tmp            \ (landing at 1.6 pixels a tick or faster kills him)
    lda #0 : sta xvel : sta tv
    lda #1 : sta ud_db
    lda #ST_STAND : sta tstate
    lda tmp : beq dies : bpl bottom
.dies
    jsr trogg_dies
.bottom
    \ off the bottom of the level?
    lda ty : cmp level_h : lda ty+1 : sbc level_h+1 : bcc done
    lda #0 : sta xvel : sta tyf
    lda level_h : sec : sbc #1 : sta ty : lda level_h+1 : sbc #0 : sta ty+1
    jmp trogg_dies
.done
    rts
}

.trogg_dies
{
IF INVINCIBLE
    rts                             \ (test builds: INVINCIBLE=1 ./build.sh)
ENDIF
    lda #50 : sta dead              \ restart in a second (50 game ticks)
    jmp stop_sounds
}

\ Enter the climbing state, direction from ymove
.start_climbing
{
    lda #ST_CLIMB : sta tstate
    lda ymove : beq still : bmi down
    lda #1 : sta tclimb : rts
.down
    lda #2 : sta tclimb : rts
.still
    lda #0 : sta tclimb : rts
}

\ Start falling at y velocity A (twentieths of a pixel a tick), x velocity xvel
.climb_to_fall
{
    sta tv
    lda #ST_FALL : sta tstate
    lda xvel : bmi left
    lda #0 : sta tface : rts
.left
    lda #1 : sta tface : rts
}

.trogg_climbing
{
    lda #0 : sta xvel : sta tv
    lda tx : sta q_x : lda tx+1 : sta q_x+1
    lda #0 : sta q_onplat : sta q_jump
    lda ymove : bne moving : jmp still
.moving
    bpl up : jmp down

.up
    \ LadderFind(x, y, y - 1)
    jsr q1_is_y : lda #256 - 20 : jsr q2_is_y_plus
    jsr ladder_find
    jsr ladder_moved : bcc up_no
    jsr move_y_to_res
    jsr maybe_step_off : bcc stay1 : rts
.stay1
    jmp climbing
.up_no
    \ At the top: step off onto a platform if there is one, PlatformFind(x, y - 1, y + 2)
    jsr q1_is_y
    lda q_y1 : bne u0 : dec q_y1+1 : .u0 : dec q_y1
    lda #40 : jsr q2_is_y_plus
    jsr platform_find_f
    lda #1 : sta ud_db
    lda res_found : beq climb_j
    lda ty : bne u1 : dec ty+1 : .u1 : dec ty
    lda #0 : jmp climb_to_fall

.climb_j
    jmp climbing

.still
    \ LadderFind(x, y, y + 2)
    jsr q1_is_y : lda #40 : jsr q2_is_y_plus
    jsr ladder_find
    jsr ladder_moved : bcc still_no
    jsr maybe_step_off : bcc stay2 : rts
.stay2
    jmp climbing
.still_no
    lda xmove : beq climb_j
    sta xvel
    lda #0 : jmp climb_to_fall

.down
    \ Climbing down onto a platform? PlatformFind(x, y, y + 1)
    jsr q1_is_y : lda #20 : jsr q2_is_y_plus
    jsr platform_find_f
    lda res_found : beq down_ladder
    lda #1 : sta ud_db
    lda #ST_STAND : sta tstate
    lda #0 : sta tface
    rts
.down_ladder
    \ LadderFind(x, y, y + 1)
    jsr q1_is_y : lda #20 : jsr q2_is_y_plus
    jsr ladder_find
    jsr ladder_moved : bcc down_no
    jsr move_y_to_res
    jsr maybe_step_off : bcc stay3 : rts
.stay3
    jmp climbing
.down_no
    \ Off the bottom of the ladder: y + 1, falling at a pixel a tick
    lda #0 : sta xvel
    inc ty : bne d1 : inc ty+1 : .d1
    lda #1 : sta ud_db
    lda #256 - 20 : jmp climb_to_fall

.climbing
    jsr start_climbing
    lda tclimb : beq no_anim
    jmp animate
.no_anim
    rts
}

\ After ladder_find: carry set if a ladder was found and its y isn't Trogg's.
\ Also moves tx to res_x when found.
.ladder_moved
{
    lda res_found : beq no
    lda res_y : cmp ty : bne yes
    lda res_y+1 : cmp ty+1 : bne yes
    lda res_yf : cmp tyf : beq no
.yes
    lda res_x : sta tx : lda res_x+1 : sta tx+1
    sec : rts
.no
    clc : rts
}

\ Moving sideways at or below the ladder's visible top lets Trogg step off it.
\ Carry set if he did (and is now falling).
.maybe_step_off
{
    lda xmove : beq no
    ldx res_i
    lda lad_yl,x : clc : adc lad_ext,x : sta tmp
    lda lad_yh,x : adc #0 : sta tmp+1
    lda ty : cmp tmp : lda ty+1 : sbc tmp+1 : bcc no
    lda xmove : sta xvel
    lda #0 : jsr climb_to_fall
    sec : rts
.no
    clc : rts
}

\ ------------------------------------------------------------------------------
\ The yoyo (port of the Yoyoing states of oTrogg and YoyoCollide)
\
\ yo_len is the string length in 8.8 fixed point: it grows by 1.3 pixels a tick
\ while the key is held, up to 80 pixels, then shrinks back at the same rate.
\ ------------------------------------------------------------------------------

YOYO_STEP = 333                     \ 1.3 * 256
YOYO_MAX = 80
YOYO_HIT_SPEED = 8                  \ pixels a tick that a yoyoed meanie flies off at

.start_yoyo
{
    lda #ST_YOYO_OUT : sta tstate
    lda #0 : sta yo_len : lda #1 : sta yo_len+1     \ length 1
    jsr yoyo_position
    jsr yoyo_collide : bcc done
    lda #ST_YOYO_BACK : sta tstate
    lda #1 : sta yo_db
.done
    rts
}

.yoyo_out
{
    jsr platform_under
    lda doyoyo : beq turn
    lda yo_len+1 : cmp #YOYO_MAX : bcs turn
    lda yo_len : clc : adc #LO(YOYO_STEP) : sta yo_len
    lda yo_len+1 : adc #HI(YOYO_STEP) : sta yo_len+1
    jsr yoyo_position
    jsr yoyo_collide : bcs turn
    \ reached the left edge of the level?
    lda yo_x+1 : bne done
    lda yo_x : cmp #2 : bcs done
.turn
    lda #ST_YOYO_BACK : sta tstate
    lda #1 : sta yo_db
    jmp yoyo_position
.done
    rts
}

.yoyo_back
{
    jsr platform_under
    lda yo_len : sec : sbc #LO(YOYO_STEP) : sta yo_len
    lda yo_len+1 : sbc #HI(YOYO_STEP) : sta yo_len+1
    bcc home : bmi home
    ora yo_len : beq home
    jsr yoyo_position
    jmp yoyo_collide                \ still knocks meanies off on the way back
.home
    lda #ST_STAND : sta tstate
    lda #0 : sta yo_len : sta yo_len+1
    rts
}

\ cur_plat = the platform Trogg is standing on (if any), so he rides it
.platform_under
{
    lda tx : sta q_x : lda tx+1 : sta q_x+1
    lda ty : sta q_y1 : lda ty+1 : sta q_y1+1
    lda ty : clc : adc #1 : sta q_y2 : lda ty+1 : adc #0 : sta q_y2+1
    lda tyf : bne none                  \ (between pixels: not on it)
    jsr platform_find
    lda res_found : beq none
    lda res_i : sta cur_plat
.none
    rts
}

\ yo_x = tx + (length + 12) * direction, yo_y = ty - 11
.yoyo_position
{
    lda yo_len+1 : clc : adc #12 : sta tmp
    lda tface : bne left
    lda tx : clc : adc tmp : sta yo_x : lda tx+1 : adc #0 : sta yo_x+1
    jmp have_x
.left
    lda tx : sec : sbc tmp : sta yo_x : lda tx+1 : sbc #0 : sta yo_x+1
.have_x
    lda ty : sec : sbc #11 : sta yo_y : lda ty+1 : sbc #0 : sta yo_y+1
    rts
}

\ Did the yoyo hit a meanie? GameMaker tested a circle of radius 3.5 at
\ (yo_x, yo_y - 3.5) against the meanies' rectangles; this uses the circle's
\ bounding square, x in [yo_x - 3, yo_x + 3] and y in [yo_y - 7, yo_y].
\ A meanie that's hit flies off. Carry set if anything was hit.
.yoyo_collide
{
    lda #0 : sta yo_hit
    \ yoyo box
    lda yo_x : sec : sbc #3 : sta yb_l : lda yo_x+1 : sbc #0 : sta yb_l+1
    lda yo_x : clc : adc #3 : sta yb_r : lda yo_x+1 : adc #0 : sta yb_r+1
    lda yo_y : sec : sbc #7 : sta yb_t : lda yo_y+1 : sbc #0 : sta yb_t+1
    ldx #MAX_OBJECTS - 1
.loop
    lda alive,x : beq next
    lda draw_kind,x : cmp #KIND_MEANIE : bne next
    \ meanie right edge (left + w - 1) >= yoyo left ?
    ldy draw_img,x
    lda draw_ll,x : clc : adc img_w,y : sta tmp : lda draw_lh,x : adc #0 : sta tmp+1
    lda yb_l : cmp tmp : lda yb_l+1 : sbc tmp+1 : bcs next          \ yoyo left >= meanie right + 1
    \ meanie left <= yoyo right ?
    lda yb_r : cmp draw_ll,x : lda yb_r+1 : sbc draw_lh,x : bcc next
    \ meanie bottom (top + h - 1) >= yoyo top ?
    lda draw_tl,x : clc : adc img_h,y : sta tmp : lda draw_th,x : adc #0 : sta tmp+1
    lda yb_t : cmp tmp : lda yb_t+1 : sbc tmp+1 : bcs next
    \ meanie top <= yoyo bottom ?
    lda yo_y : cmp draw_tl,x : lda yo_y+1 : sbc draw_th,x : bcc next
    \ Hit! It flies off in the yoyo's direction (launch_meanie squeals)
    lda #1 : sta yo_hit
    lda #0 : sta alive,x
    txa : pha
    jsr queue_repaint
    pla : tax : pha
    lda #YOYO_HIT_SPEED
    ldy tface : beq right
    lda #256 - YOYO_HIT_SPEED
.right
    jsr launch_meanie
    pla : tax
.next
    dex : bmi finished
    jmp loop
.finished
    \ Balloons and daggers are destroyed; a meanie already flying just bounces it back
    lda #MAX_MOVERS - 1 : sta mvc_i
.mloop
    ldx mvc_i
    lda mv_active,x : bne m_on
    jmp mnext
.m_on
    ldy mv_img,x
    \ tmp = left = x - xo; right = left + w - 1
    lda mv_xl,x : sec : sbc img_xo,y : sta tmp : lda mv_xh,x : sbc #0 : sta tmp+1
    lda yb_r : cmp tmp : lda yb_r+1 : sbc tmp+1 : bvc v1 : eor #&80 : .v1 : bmi mnext     \ yoyo right < left
    lda tmp : clc : adc img_w,y : sta tmp : lda tmp+1 : adc #0 : sta tmp+1
    lda yb_l : cmp tmp : lda yb_l+1 : sbc tmp+1 : bvc v2 : eor #&80 : .v2 : bpl mnext     \ yoyo left > right
    \ tmp = top = y - yo; bottom = top + h - 1
    lda mv_yl,x : sec : sbc img_yo,y : sta tmp : lda mv_yh,x : sbc #0 : sta tmp+1
    lda yo_y : cmp tmp : lda yo_y+1 : sbc tmp+1 : bvc v3 : eor #&80 : .v3 : bmi mnext     \ yoyo bottom < top
    lda tmp : clc : adc img_h,y : sta tmp : lda tmp+1 : adc #0 : sta tmp+1
    lda yb_t : cmp tmp : lda yb_t+1 : sbc tmp+1 : bvc v4 : eor #&80 : .v4 : bpl mnext     \ yoyo top > bottom
    lda #1 : sta yo_hit
    lda mv_active,x : cmp #MV_FLYING : beq mnext
    lda #SFX_DAGGER : ldy mv_img,x : cpy #IMG_Balloon : bne m_sfx : lda #SFX_POP : .m_sfx
    jsr play_sfx
    lda #0 : sta mv_active,x
.mnext
    dec mvc_i : bmi m_done
    jmp mloop
.m_done
    jsr yoyo_slow
    lda yo_hit : cmp #1             \ carry set if hit
    rts
}

\ ------------------------------------------------------------------------------
\ Moving platforms and meanies ("slow sprites"): ports of the Step events of
\ oPlatform, oScrubbly, oPoglet and oHooter. Their ranges were worked out by the
\ converter, the way the GameMaker objects did on their first step.
\ Positions are 16.8 fixed point, velocities 8.8.
\ ------------------------------------------------------------------------------

SLOW_PAUSE = 30                     \ platforms pause this long at each end
HOOTER_GRAVITY = 13                 \ 0.05 pixels/tick^2 in 8.8 fixed point

\ Start of level: everything at its starting position
.slow_init
{
    ldx #MAX_SLOW - 1
.loop
    lda #0 : cpx num_slow : bcs dead : lda #1 : .dead
    sta s_alive,x
    lda #0 : sta s_xf,x : sta s_yf,x
    lda sl_x0l,x : sta s_xl,x : lda sl_x0h,x : sta s_xh,x
    lda sl_y0l,x : sta s_yl,x : lda sl_y0h,x : sta s_yh,x
    lda sl_vf,x : sta s_vf,x : lda sl_vi,x : sta s_vi,x
    lda sl_kind,x : cmp #SL_HOOTER : bne vel_ok
    lda #0 : sta s_vf,x : sta s_vi,x        \ Hooters start still, then jump
.vel_ok
    lda sl_vy,x : sta s_vy,x
    lda sl_wait,x : sta s_wait,x
    dex : bpl loop
    ldx #MAX_PLATS - 1
.plats
    lda plat_x0l,x : sta plat_xl,x : lda plat_x0h,x : sta plat_xh,x
    lda plat_y0l,x : sta plat_yl,x : lda plat_y0h,x : sta plat_yh,x
    dex : bpl plats
    lda #255 : sta cur_plat
    rts
}

\ Checkpoints: copy the moving state (and platform positions) to / from the copies
MACRO COPY_SLOW from, to
    ldx #MAX_SLOW - 1
.loop
    lda from,x : sta to,x
    dex : bpl loop
ENDMACRO
MACRO COPY_PLATS from, to
    ldx #MAX_PLATS - 1
.loop
    lda from,x : sta to,x
    dex : bpl loop
ENDMACRO

.slow_save_checkpoint
    COPY_SLOW s_alive, cps_alive
    COPY_SLOW s_xf, cps_xf
    COPY_SLOW s_xl, cps_xl
    COPY_SLOW s_xh, cps_xh
    COPY_SLOW s_yf, cps_yf
    COPY_SLOW s_yl, cps_yl
    COPY_SLOW s_yh, cps_yh
    COPY_SLOW s_vf, cps_vf
    COPY_SLOW s_vi, cps_vi
    COPY_SLOW s_vy, cps_vy
    COPY_SLOW s_wait, cps_wait
    COPY_PLATS plat_xl, cpp_xl
    COPY_PLATS plat_xh, cpp_xh
    COPY_PLATS plat_yl, cpp_yl
    COPY_PLATS plat_yh, cpp_yh
    rts

.slow_restore_checkpoint
    COPY_SLOW cps_alive, s_alive
    COPY_SLOW cps_xf, s_xf
    COPY_SLOW cps_xl, s_xl
    COPY_SLOW cps_xh, s_xh
    COPY_SLOW cps_yf, s_yf
    COPY_SLOW cps_yl, s_yl
    COPY_SLOW cps_yh, s_yh
    COPY_SLOW cps_vf, s_vf
    COPY_SLOW cps_vi, s_vi
    COPY_SLOW cps_vy, s_vy
    COPY_SLOW cps_wait, s_wait
    COPY_PLATS cpp_xl, plat_xl
    COPY_PLATS cpp_xh, plat_xh
    COPY_PLATS cpp_yl, plat_yl
    COPY_PLATS cpp_yh, plat_yh
    lda #255 : sta cur_plat
    rts

\ tmp = |sl_v| (the default speed, as a positive 8.8 number) for slow sprite X
.abs_speed
{
    lda sl_vf,x : sta tmp : lda sl_vi,x : sta tmp+1
    bpl done
    lda #0 : sec : sbc tmp : sta tmp : lda #0 : sbc tmp+1 : sta tmp+1
.done
    rts
}

\ One tick of movement for every slow sprite
.update_slow
{
    ldx #MAX_SLOW - 1
.loop
    lda s_alive,x : beq next
    lda sl_kind,x
    cmp #SL_PLATFORM : bne not_plat
    jsr move_platform : jmp next
.not_plat
    cmp #SL_SCRUBBLY : bne not_scrub
    jsr move_scrubbly : jmp next
.not_scrub
    cmp #SL_POGLET : bne not_pog
    jsr move_poglet : jmp next
.not_pog
    jsr move_hooter
.next
    dex : bpl loop
    rts
}

.move_platform
{
    lda s_wait,x : beq go
    dec s_wait,x
    rts
.go
    \ x += vx (+1/-1), bouncing off the ends of its range with a pause
    lda s_vi,x : beq y_move : bmi left
    inc s_xl,x : bne nc1 : inc s_xh,x : .nc1
    lda sl_amaxl,x : cmp s_xl,x : lda sl_amaxh,x : sbc s_xh,x : bcs y_move
    lda sl_amaxl,x : sta s_xl,x : lda sl_amaxh,x : sta s_xh,x
    lda #&FF : sta s_vi,x : lda #SLOW_PAUSE : sta s_wait,x
    jmp y_move
.left
    lda s_xl,x : bne nb1 : dec s_xh,x : .nb1 : dec s_xl,x
    lda s_xl,x : cmp sl_aminl,x : lda s_xh,x : sbc sl_aminh,x : bcs y_move
    lda sl_aminl,x : sta s_xl,x : lda sl_aminh,x : sta s_xh,x
    lda #1 : sta s_vi,x : lda #SLOW_PAUSE : sta s_wait,x
.y_move
    \ y += vy likewise
    lda s_vy,x : beq store : bmi up
    inc s_yl,x : bne nc2 : inc s_yh,x : .nc2
    lda sl_bmaxl,x : cmp s_yl,x : lda sl_bmaxh,x : sbc s_yh,x : bcs store
    lda sl_bmaxl,x : sta s_yl,x : lda sl_bmaxh,x : sta s_yh,x
    lda #&FF : sta s_vy,x : lda #SLOW_PAUSE : sta s_wait,x
    jmp store
.up
    lda s_yl,x : bne nb2 : dec s_yh,x : .nb2 : dec s_yl,x
    lda s_yl,x : cmp sl_bminl,x : lda s_yh,x : sbc sl_bminh,x : bcs store
    lda sl_bminl,x : sta s_yl,x : lda sl_bminh,x : sta s_yh,x
    lda #1 : sta s_vy,x : lda #SLOW_PAUSE : sta s_wait,x
.store
    \ ... and update the platform table that Trogg stands on
    ldy sl_plat,x
    lda s_xl,x : sta plat_xl,y : lda s_xh,x : sta plat_xh,y
    lda s_yl,x : sta plat_yl,y : lda s_yh,x : sta plat_yh,y
    rts
}

\ Scrubbly: patrols its platform between amin and amax
.move_scrubbly
{
    ldy #0 : lda s_vi,x : bpl xs : dey : .xs : sty tmp
    clc
    lda s_xf,x : adc s_vf,x : sta s_xf,x
    lda s_xl,x : adc s_vi,x : sta s_xl,x
    lda s_xh,x : adc tmp : sta s_xh,x
    \ x < amin ?
    lda s_xl,x : cmp sl_aminl,x : lda s_xh,x : sbc sl_aminh,x : bcs not_low
    lda sl_aminl,x : sta s_xl,x : lda sl_aminh,x : sta s_xh,x : lda #0 : sta s_xf,x
    jsr abs_speed
    lda tmp : sta s_vf,x : lda tmp+1 : sta s_vi,x
    jmp follow
.not_low
    \ x > amax ?
    lda sl_amaxl,x : cmp s_xl,x : lda sl_amaxh,x : sbc s_xh,x : bcc high
    lda sl_amaxl,x : cmp s_xl,x : bne follow
    lda sl_amaxh,x : cmp s_xh,x : bne follow
    lda s_xf,x : beq follow
.high
    lda sl_amaxl,x : sta s_xl,x : lda sl_amaxh,x : sta s_xh,x : lda #0 : sta s_xf,x
    jsr abs_speed
    lda #0 : sec : sbc tmp : sta s_vf,x : lda #0 : sbc tmp+1 : sta s_vi,x
.follow
    \ some ride up and down with a moving platform
    ldy sl_plat,x : cpy #255 : beq done
    lda plat_yl,y : sta s_yl,x : lda plat_yh,y : sta s_yh,x
.done
    rts
}

\ Poglet: climbs up and down between amin and amax
.move_poglet
{
    ldy #0 : lda s_vi,x : bpl ys : dey : .ys : sty tmp
    clc
    lda s_yf,x : adc s_vf,x : sta s_yf,x
    lda s_yl,x : adc s_vi,x : sta s_yl,x
    lda s_yh,x : adc tmp : sta s_yh,x
    lda s_yl,x : cmp sl_aminl,x : lda s_yh,x : sbc sl_aminh,x : bcs not_low
    lda sl_aminl,x : sta s_yl,x : lda sl_aminh,x : sta s_yh,x : lda #0 : sta s_yf,x
    jsr abs_speed
    lda tmp : sta s_vf,x : lda tmp+1 : sta s_vi,x
    rts
.not_low
    lda sl_amaxl,x : cmp s_yl,x : lda sl_amaxh,x : sbc s_yh,x : bcc high
    lda sl_amaxl,x : cmp s_yl,x : bne done
    lda sl_amaxh,x : cmp s_yh,x : bne done
    lda s_yf,x : beq done
.high
    lda sl_amaxl,x : sta s_yl,x : lda sl_amaxh,x : sta s_yh,x : lda #0 : sta s_yf,x
    jsr abs_speed
    lda #0 : sec : sbc tmp : sta s_vf,x : lda #0 : sbc tmp+1 : sta s_vi,x
.done
    rts
}

\ Hooter: jumps up and down on the spot (after an initial sleep)
.move_hooter
{
    lda s_wait,x : beq go
    dec s_wait,x
    rts
.go
    \ v -= gravity; y -= v
    lda s_vf,x : sec : sbc #HOOTER_GRAVITY : sta s_vf,x
    lda s_vi,x : sbc #0 : sta s_vi,x
    ldy #0 : lda s_vi,x : bpl vs : dey : .vs : sty tmp      \ sign extension of v
    lda s_yf,x : sec : sbc s_vf,x : sta s_yf,x
    lda s_yl,x : sbc s_vi,x : sta s_yl,x
    lda s_yh,x : sbc tmp : sta s_yh,x
    \ below its base? land and jump again
    lda sl_y0l,x : cmp s_yl,x : lda sl_y0h,x : sbc s_yh,x : bcc land
    lda sl_y0l,x : cmp s_yl,x : bne done
    lda sl_y0h,x : cmp s_yh,x : bne done
    lda s_yf,x : beq done
.land
    lda sl_y0l,x : sta s_yl,x : lda sl_y0h,x : sta s_yh,x : lda #0 : sta s_yf,x
    lda sl_vf,x : sta s_vf,x : lda sl_vi,x : sta s_vi,x
.done
    rts
}

\ Trogg against moving meanies (they kill him)
.collide_slow
{
    lda #MAX_SLOW - 1 : sta mvc_i
.loop
    ldx mvc_i
    lda s_alive,x : beq next
    lda sl_kind,x : cmp #SL_PLATFORM : beq next
    ldy sl_img,x : sty c_oimg
    lda d_xl,x : sec : sbc img_xo,y : sta tmp : lda d_xh,x : sbc #0 : sta tmp+1
    lda tmp : sec : sbc ct_l : sta c_dx : lda tmp+1 : sbc ct_l+1
    jsr in_range_64 : bcc next
    ldx mvc_i : ldy c_oimg
    lda d_yl,x : sec : sbc img_yo,y : sta tmp : lda d_yh,x : sbc #0 : sta tmp+1
    lda tmp : sec : sbc ct_t : sta c_dy : lda tmp+1 : sbc ct_t+1
    jsr in_range_64_dy : bcc next
    jsr hit_test : bcc next
    jsr trogg_dies
.next
    dec mvc_i : bpl loop
    rts
}

\ The yoyo against moving meanies: a hit one flies off (as a mover). Sets yo_hit.
.yoyo_slow
{
    lda #MAX_SLOW - 1 : sta mvc_i
.loop
    ldx mvc_i
    lda s_alive,x : bne alive
    jmp next
.alive
    lda sl_kind,x : cmp #SL_PLATFORM : bne meanie
    jmp next
.meanie
    ldy sl_img,x
    lda d_xl,x : sec : sbc img_xo,y : sta tmp : lda d_xh,x : sbc #0 : sta tmp+1
    lda yb_r : cmp tmp : lda yb_r+1 : sbc tmp+1 : bvc v1 : eor #&80 : .v1 : bpl ok1
    jmp next
.ok1
    lda tmp : clc : adc img_w,y : sta tmp : lda tmp+1 : adc #0 : sta tmp+1
    lda yb_l : cmp tmp : lda yb_l+1 : sbc tmp+1 : bvc v2 : eor #&80 : .v2 : bmi ok2
    jmp next
.ok2
    lda d_yl,x : sec : sbc img_yo,y : sta tmp : lda d_yh,x : sbc #0 : sta tmp+1
    lda yo_y : cmp tmp : lda yo_y+1 : sbc tmp+1 : bvc v3 : eor #&80 : .v3 : bpl ok3
    jmp next
.ok3
    lda tmp : clc : adc img_h,y : sta tmp : lda tmp+1 : adc #0 : sta tmp+1
    lda yb_t : cmp tmp : lda yb_t+1 : sbc tmp+1 : bvc v4 : eor #&80 : .v4 : bmi ok4
    jmp next
.ok4
    \ Hit: it flies off in the yoyo's direction
    lda #SFX_SQUEAL : jsr play_sfx
    lda #1 : sta yo_hit
    lda #0 : sta s_alive,x
    jsr find_mover : bcc slot
    jmp next
.slot
    lda #MV_FLYING : sta mv_active,y
    lda sl_img,x : sta mv_img,y
    lda d_xl,x : sta mv_xl,y : lda d_xh,x : sta mv_xh,y
    lda d_yl,x : sta mv_yl,y : lda d_yh,x : sta mv_yh,y
    lda #YOYO_HIT_SPEED
    ldx tface : beq right
    lda #256 - YOYO_HIT_SPEED
.right
    sta mv_vxi,y
.next
    dec mvc_i : bmi done
    jmp loop
.done
    rts
}


\ ------------------------------------------------------------------------------
\ Drawing the slow sprites. They stay drawn in each screen buffer, which
\ remembers where it drew each one (dr_*). A slow sprite is only redrawn when it
\ has moved since that buffer last drew it, or something painted over it.
\
\ Erasing one repaints its character cells from the background cache (and the
\ scenery over them). Everything repainted in a frame - scrolled-in columns,
\ collected objects' columns, erased sprites - goes in the damage list, and every
\ slow sprite overlapping damage is plotted again, in order, so overlaps stay
\ right. Each one plotted is damage too, for the ones after it.
\
\ What is drawn (and collided with) is the display position d_*. Scrubblies near
\ the window catch up with their real position a few at a time per
\ drawn frame, taking turns; everything else catches up every frame.
\ ------------------------------------------------------------------------------

MAX_DMG = 40
DONE = &80                          \ n_chg: already redrawn this frame
\ Moves per drawn frame for each kind: none, Scrubbly, Poglet, Hooter, platform
.turn_quota EQUB 0, 1, 2, 3, 0
TURN_MOVES = 1 + 2 + 3

\ Record damage rectangle dm_c0..dm_c1, dm_y0..dm_y1. Preserves X.
.add_damage
{
    ldy dmg_n : cpy #MAX_DMG : bcs full
    lda dm_c0 : sta dmg_c0,y
    lda dm_c1 : sta dmg_c1,y
    lda dm_y0 : sta dmg_y0,y
    lda dm_y1 : sta dmg_y1,y
    inc dmg_n
    rts
.full
    lda #1 : sta dmg_all
    rts
}

\ After a restart: everything shown where it really is, and nothing drawn yet
.slow_reset_display
{
    ldx #MAX_SLOW - 1
.loop
    jsr commit_one
    lda #0 : sta dr_on,x : sta dr_on + SLOW_N,x
    dex : bpl loop
    rts
}

\ d = s for slow sprite X
.commit_one
    lda s_xl,x : sta d_xl,x : lda s_xh,x : sta d_xh,x
    lda s_yl,x : sta d_yl,x : lda s_yh,x : sta d_yh,x
    rts

\ Carry set if slow sprite X is a Scrubbly that takes turns to move: one near the
\ window (view_l .. view_l + WINDOW_W + 128) that isn't riding a moving platform
.takes_turns
{
    ldy sl_kind,x : lda turn_quota,y : beq no
    cpy #SL_SCRUBBLY : bne kind_ok
    lda sl_plat,x : cmp #255 : bne no        \ (one riding a moving platform keeps up)
.kind_ok
    lda s_xl,x : sec : sbc view_l : sta tmp
    lda s_xh,x : sbc view_l+1 : bmi no
    cmp #HI(WINDOW_W + 128) : bcc yes : bne no
    lda tmp : cmp #LO(WINDOW_W + 128) : bcs no
.yes
    sec : rts
.no
    clc : rts
}

\ Once per drawn frame: move the display positions on
.commit_slow
{
    \ view_l = left edge of the window - 64
    lda scrollcol : sta view_l : lda #0 : sta view_l+1
    asl view_l : rol view_l+1 : asl view_l : rol view_l+1
    lda view_l : sec : sbc #64 : sta view_l : lda view_l+1 : sbc #0 : sta view_l+1
    ldx #MAX_SLOW - 1
.loop
    jsr takes_turns : bcs next
    jsr commit_one
.next
    dex : bpl loop
    \ Meanies' turns
    ldy #4
.quotas
    lda turn_quota,y : sta cm_q,y : dey : bpl quotas
    lda #TURN_MOVES : sta cm_left
    lda #MAX_SLOW : sta cm_count
    ldx rr_i
.turn
    inx : cpx #MAX_SLOW : bcc in : ldx #0
.in
    lda s_alive,x : beq tnext
    jsr takes_turns : bcc tnext
    lda s_xl,x : cmp d_xl,x : bne move
    lda s_xh,x : cmp d_xh,x : bne move
    lda s_yl,x : cmp d_yl,x : bne move
    lda s_yh,x : cmp d_yh,x : beq tnext
.move
    ldy sl_kind,x : lda cm_q,y : beq tnext   \ this kind has had its moves
    sec : sbc #1 : sta cm_q,y
    jsr commit_one
    dec cm_left : beq tdone
.tnext
    dec cm_count : bne turn
.tdone
    stx rr_i
    rts
}

\ Work out where slow sprite X would be drawn (from d_*). Carry set if any of
\ it is in the window, with its byte columns in nr_c0..nr_c1 and rows in
\ nr_y0..nr_y1 (inclusive, clamped to the level)
.slow_rect
{
    lda s_alive,x : bne alive
    clc : rts
.alive
    ldy sl_img,x
    \ left = x - xo, right = left + w - 1 (16-bit signed), as byte columns
    lda d_xl,x : sec : sbc img_xo,y : sta left : lda d_xh,x : sbc #0 : sta left+1
    lda left : clc : adc img_w,y : sta tmp : lda left+1 : adc #0 : sta tmp+1
    lda tmp : bne r1 : dec tmp+1 : .r1 : dec tmp
    lda left+1 : cmp #&80 : ror left+1 : ror left
    lda left+1 : cmp #&80 : ror left+1 : ror left
    lda tmp+1 : cmp #&80 : ror tmp+1 : ror tmp
    lda tmp+1 : cmp #&80 : ror tmp+1 : ror tmp
    \ visible if right >= clip_l and left < clip_r
    lda tmp+1 : bmi out1 : bne r_ok
    lda tmp : cmp clip_l : bcc out1
.r_ok
    lda left+1 : bmi l_neg : bne out1
    lda left : cmp clip_r : bcs out1
    sta nr_c0 : jmp have_l
.l_neg
    lda #0 : sta nr_c0
.have_l
    lda tmp+1 : beq r_byte
    lda #255 : sta tmp
.r_byte
    lda tmp : sta nr_c1
    jmp rows_part
.out1
    clc : rts
.rows_part
    \ top = y - yo, bottom = top + h - 1; visible if bottom >= clip_t and top < clip_t + 256
    lda d_yl,x : sec : sbc img_yo,y : sta top : lda d_yh,x : sbc #0 : sta top+1
    lda top : clc : adc img_h,y : sta tmp : lda top+1 : adc #0 : sta tmp+1
    lda tmp : bne b1 : dec tmp+1 : .b1 : dec tmp
    lda tmp : cmp clip_t : lda tmp+1 : sbc clip_t+1 : bvc v1 : eor #&80 : .v1 : bmi out
    lda clip_t : clc : adc #0 : lda clip_t+1 : adc #1 : sta left+1      \ (clip_t + 256) high byte
    lda top : cmp clip_t : lda top+1 : sbc left+1 : bvc v2 : eor #&80 : .v2 : bpl out
    \ rows, in units of 4 pixels (0-1023)
    lda tmp+1 : lsr a : sta left : lda tmp : ror a : lsr left : ror a : sta nr_y1
    lda top+1 : bmi t_neg
    lsr a : sta left : lda top : ror a : lsr left : ror a : sta nr_y0
    sec : rts
.t_neg
    lda #0 : sta nr_y0
    sec : rts
.out
    clc
    rts
}

\ Bring the slow sprites in the back buffer up to date
.draw_slow
{
    lda #0 : ldx back : beq b0 : lda #SLOW_N : .b0 : sta ds_base
    \ 1. Erase the ones that have moved, or gone
    ldx #MAX_SLOW - 1
.erase_loop
    stx sl_i
    lda #0 : sta n_chg,x
    jsr slow_rect
    lda #0 : rol a : sta n_vis,x            \ carry: visible
    lda ds_base : clc : adc sl_i : tay
    lda n_vis,x : bne vis
    \ not visible: erase it if it was drawn
    lda dr_on,y : beq not_drawn
    jmp erase
.not_drawn
    jmp e_next
.vis
    lda dr_on,y : bne was_drawn
    jmp new
.was_drawn
    lda d_xl,x : cmp dr_xl,y : bne moved
    lda d_xh,x : cmp dr_xh,y : bne moved
    lda d_yl,x : cmp dr_yl,y : bne moved
    lda d_yh,x : cmp dr_yh,y : bne moved
    jmp e_next
.moved
    lda #1 : sta n_chg,x
    \ one nothing else is drawn over: skip erasing where it will be copied in
    lda sl_simple,x : beq erase
    lda sl_img,x : sta p_img
    lda d_xl,x : sta p_x : lda d_xh,x : sta p_x+1
    lda d_yl,x : sta p_y : lda d_yh,x : sta p_y+1
    jsr raw_setup
    ldy ds_base : tya : clc : adc sl_i : tay
    jsr erase_drawn                         \ (rr_raw is cleared again by it)
    lda #PM_RAWPLOT : sta p_mode
    jsr plot
    lda #PM_PLOT : sta p_mode
    lda #0 : sta rr_raw
    ldx sl_i
    lda ds_base : clc : adc sl_i : tay
    lda #DONE : sta n_chg,x                 \ (done: no need to plot it again)
    jmp store
.erase
    jsr erase_drawn
    ldx sl_i
    lda ds_base : clc : adc sl_i : tay
    lda n_chg,x : beq e_next                \ gone: nothing to draw
.new
    lda #1 : sta n_chg,x
.store
    \ it will be drawn here
    lda d_xl,x : sta dr_xl,y : lda d_xh,x : sta dr_xh,y
    lda d_yl,x : sta dr_yl,y : lda d_yh,x : sta dr_yh,y
    lda nr_c0 : sta dr_c0,y : lda nr_c1 : sta dr_c1,y
    lda nr_y0 : sta dr_y0,y : lda nr_y1 : sta dr_y1,y
    lda #1 : sta dr_on,y
.e_next
    ldx sl_i : dex : bmi erased
    jmp erase_loop
.erased
    \ 2. Plot, in order, the ones that moved and the ones painted over
    lda #PM_PLOT : sta p_mode
    ldx #0
.plot_loop
    stx sl_i
    lda n_vis,x : beq p_next
    lda ds_base : clc : adc sl_i : tay
    lda n_chg,x : bmi p_next                \ DONE
    bne plot_it
    lda dmg_all : bne plot_it
    jsr damaged : bcc p_next
.plot_it
    ldx sl_i
    lda sl_img,x : sta p_img
    lda d_xl,x : sta p_x : lda d_xh,x : sta p_x+1
    lda d_yl,x : sta p_y : lda d_yh,x : sta p_y+1
    jsr plot
    \ ... which is damage for the ones after it
    lda ds_base : clc : adc sl_i : tay
    lda dr_c0,y : sta dm_c0 : lda dr_c1,y : sta dm_c1
    lda dr_y0,y : sta dm_y0 : lda dr_y1,y : sta dm_y1
    jsr add_damage
.p_next
    ldx sl_i : inx : cpx #MAX_SLOW : bne plot_loop
    rts
}

\ Erase the slow sprite drawn at record Y (the visible part of it) and forget it
.erase_drawn
{
    lda #0 : sta dr_on,y
    lda dr_c0,y : cmp clip_l : bcs c0 : lda clip_l
.c0
    sta rr_c0
    lda clip_r : sec : sbc #1 : cmp dr_c1,y : bcc c1 : lda dr_c1,y
.c1
    sta rr_c1
    cmp rr_c0 : bcc none
    \ its character rows, within the window's (scrollrow .. scrollrow + 31)
    lda dr_y0,y : lsr a : cmp scrollrow : bcs k0 : lda scrollrow
.k0
    sta rr_k0
    lda scrollrow : clc : adc #31 : sta rr_k1
    lda dr_y1,y : lsr a : cmp rr_k1 : bcs k1 : sta rr_k1
.k1
    lda rr_k1 : cmp rr_k0 : bcc none
    jmp repaint_rect
.none
    rts
}

\ Carry set if drawn record Y overlaps any damage
.damaged
{
    ldx dmg_n : beq no
    dex
.loop
    lda dr_c1,y : cmp dmg_c0,x : bcc next      \ ends left of it
    lda dmg_c1,x : cmp dr_c0,y : bcc next      \ starts right of it
    lda dr_y1,y : cmp dmg_y0,x : bcc next      \ ends above it
    lda dmg_y1,x : cmp dr_y0,y : bcc next      \ starts below it
    sec : rts
.next
    dex : bpl loop
.no
    clc : rts
}

\ (These never page another bank in, so they can live here too)

\ A = negative INKEY code; returns A = 1 if pressed, else 0.
\ Reads the keyboard matrix directly through the system VIA, which is much
\ quicker than OSBYTE &81.
SYSVIA_ORB  = &FE40
SYSVIA_DDRA = &FE43
SYSVIA_ORA  = &FE4F                 \ port A without handshake
.key_pressed
{
    eor #&FF                        \ INKEY -n is internal key number n-1
    sei
    ldx #3 : stx SYSVIA_ORB         \ stop the keyboard auto-scan
    ldx #&7F : stx SYSVIA_DDRA      \ bits 0-6 select the key, bit 7 reads it
    sta SYSVIA_ORA
    lda SYSVIA_ORA                  \ bit 7 set if the key is down
    ldx #&0B : stx SYSVIA_ORB       \ restart the auto-scan
    cli
    asl a : lda #0 : rol a
    rts
}

.read_keys
{
    lda #KEY_Z : jsr key_pressed : sta k_left
    lda #KEY_LEFT : jsr key_pressed : ora k_left : sta k_left
    lda #KEY_X : jsr key_pressed : sta k_right
    lda #KEY_RIGHT : jsr key_pressed : ora k_right : sta k_right
    lda #KEY_O : jsr key_pressed : sta k_up
    lda #KEY_UP : jsr key_pressed : ora k_up : sta k_up
    lda #KEY_K : jsr key_pressed : sta k_down
    lda #KEY_DOWN : jsr key_pressed : ora k_down : sta k_down
    lda #KEY_P : jsr key_pressed : sta k_yoyo
    lda #KEY_SPACE : jsr key_pressed : ora k_yoyo : sta k_yoyo

    \ doyoyo, with debounce: after the yoyo comes back, the key must be released
    lda yo_db : beq yo_live
    lda #0 : sta doyoyo
    lda k_yoyo : bne yo_done
    sta yo_db
    beq yo_done
.yo_live
    lda k_yoyo : sta doyoyo
.yo_done

    \ ymove (+1 = up), with debounce after landing/climbing
    lda ud_db : beq ud_live
    lda #0 : sta ymove
    lda k_up : ora k_down : bne ud_done
    sta ud_db
    beq ud_done
.ud_live
    lda k_up : sec : sbc k_down : sta ymove
.ud_done
    lda lr_db : beq lr_live
    lda #0 : sta xmove
    lda k_left : ora k_right : bne lr_done
    sta lr_db
    beq lr_done
.lr_live
    lda k_right : sec : sbc k_left : sta xmove
.lr_done
    rts
}

\ The string runs from Trogg's hand (tx + 12 * direction) to the yoyo, on the
\ row just above the yoyo's base
.yoyo_string_params
{
    lda yo_x : sta q_x : lda yo_x+1 : sta q_x+1
    lda tface : bne left
    lda tx : clc : adc #12 : sta p_x : lda tx+1 : adc #0 : sta p_x+1
    jmp have_x
.left
    lda tx : sec : sbc #12 : sta p_x : lda tx+1 : sbc #0 : sta p_x+1
.have_x
    lda yo_y : sec : sbc #1 : sta p_y : lda yo_y+1 : sbc #0 : sta p_y+1
    rts
}

\ Yoyo frame: ((length * direction) >> 3) AND 3, as in GameMaker
.yoyo_image
{
    lda yo_len+1
    ldx tface : beq right
    eor #&FF : clc : adc #1                 \ negate
    cmp #&80 : ror a : cmp #&80 : ror a : cmp #&80 : ror a
    jmp frame
.right
    lsr a : lsr a : lsr a
.frame
    and #3 : clc : adc #IMG_Yoyo_0
    rts
}

\ Which image to draw for Trogg
.trogg_image
{
    lda tstate
    cmp #ST_WALK : beq walk
    cmp #ST_CLIMB : beq climb
    cmp #ST_YOYO_OUT : bcc stand
    lda tface : bne yl
    lda #IMG_Trogg_yr : rts
.yl
    lda #IMG_Trogg_yl : rts
.stand
    lda tface : bne sl
    lda #IMG_Trogg_sr : rts
.sl
    lda #IMG_Trogg_sl : rts
.walk
    lda anim : lsr a : lsr a : lsr a : lsr a : lsr a : lsr a   \ top two bits = frame 0..3
    ldx tface : beq wr
    clc : adc #IMG_Trogg_wl_0 : rts
.wr
    clc : adc #IMG_Trogg_wr_0 : rts
.climb
    lda tclimb : beq cn
    lda anim : asl a : lda #0 : rol a              \ top bit = frame 0..1
    ldx tclimb : cpx #1 : beq cu
    clc : adc #IMG_Trogg_cd_0 : rts
.cu
    clc : adc #IMG_Trogg_cu_0 : rts
.cn
    lda #IMG_Trogg_cn : rts
}


\ ------------------------------------------------------------------------------
\ hline: a 1-pixel black line from (p_x, p_y) to (q_x, p_y), inclusive.
\ PM_SAVE draws it saving the background at sbase; PM_RESTORE puts it back.
\ Clipped to the visible window and to the level's 256 rows.
\ ------------------------------------------------------------------------------

.hline
{
    lda sbase : sta sptr : lda sbase+1 : sta sptr+1
    \ Only rows in the window: 0 <= p_y - clip_t < 256
    lda p_y : sec : sbc clip_t : lda p_y+1 : sbc clip_t+1 : beq row_ok
    rts
.row_ok
    \ order the ends: left in left, right in tmp
    lda q_x : cmp p_x : lda q_x+1 : sbc p_x+1 : bcs ordered
    lda q_x : sta left : lda q_x+1 : sta left+1
    lda p_x : sta tmp : lda p_x+1 : sta tmp+1
    jmp have_ends
.ordered
    lda p_x : sta left : lda p_x+1 : sta left+1
    lda q_x : sta tmp : lda q_x+1 : sta tmp+1
.have_ends
    \ byte columns and the pixel within the first and last
    lda left : and #3 : sta hl_p0
    lda tmp : and #3 : sta hl_p1
    lda left+1 : lsr a : lda left : ror a : lsr a : sta hl_c0
    lda left+1 : lsr a : lsr a : beq on_level        \ off the level?
    rts
.on_level
    lda tmp+1 : lsr a : lda tmp : ror a : lsr a : sta hl_c1
    lda tmp+1 : lsr a : lsr a : beq c1_ok : lda #255 : sta hl_c1
.c1_ok
    \ screen address of the first column on this row
    lda p_y : and #7 : sta hl_line
    lda p_y+1 : lsr a : sta hl_row : lda p_y : ror a : lsr hl_row : ror a : lsr hl_row : ror a : sta hl_row
    lda hl_c0 : sta colw
.col
    lda colw : cmp clip_l : bcc next_col
    cmp clip_r : bcs next_col
    \ which pixels of this byte are on the line?
    lda #&FF : sta hl_mask
    lda colw : cmp hl_c0 : bne not_first
    ldx hl_p0 : lda left_pixels,x : sta hl_mask
.not_first
    lda colw : cmp hl_c1 : bne not_last
    ldx hl_p1 : lda right_pixels,x : and hl_mask : sta hl_mask
.not_last
    \ ptr = rowaddr[row] + colw * 8, wrapped; Y = line
    lda #0 : sta tmp+1
    lda colw : asl a : rol tmp+1 : asl a : rol tmp+1 : asl a : rol tmp+1
    ldx hl_row
    clc : adc rowaddr_lo,x : sta ptr
    lda tmp+1 : adc rowaddr_hi,x
    cmp #&80 : bcc ok : sbc #&50
.ok
    sta ptr+1
    ldy hl_line
    ldx #0
    lda p_mode : cmp #PM_RESTORE : beq restore
    lda (ptr),y : sta (sptr,x)
    \ black is logical colour 1: low bit set, high bit clear, in each masked pixel
    lda hl_mask : eor #&FF : and (ptr),y : sta tmp
    lda hl_mask : and #&0F : ora tmp
    sta (ptr),y
    jmp advance
.restore
    lda (sptr,x) : sta (ptr),y
.advance
    inc sptr : bne next_col : inc sptr+1
.next_col
    lda colw : cmp hl_c1 : beq done
    inc colw
    jmp col
.done
    rts
}

\ Pixel masks (both bits of each pixel) for "pixel p and to its right" / "up to pixel p"
.left_pixels  EQUB &FF, &77, &33, &11
.right_pixels EQUB &88, &CC, &EE, &FF

\ ------------------------------------------------------------------------------
\ The level timer (as the Steam version: it runs while Trogg is alive and the
\ level isn't complete) and his rating (gold, silver, bronze or a tick, for 0,
\ 1, 2 or more restarts from a checkpoint), drawn over the playfield like
\ sprites: the timer is an image (IMG_Hud) made from the font each second.
\ ------------------------------------------------------------------------------

.draw_hud
{
    lda won : beq playing
    jmp win_panel
.playing
    \ the seconds; a new timer image when they change
    lda lvl_ticks : sta tmp : lda lvl_ticks+1 : sta tmp+1
    lda #50 : jsr div16
    lda tmp : cmp hud_secs : bne new : lda tmp+1 : cmp hud_secs+1 : beq same
.new
    lda tmp : sta hud_secs : lda tmp+1 : sta hud_secs+1
    jsr time_digits
    ldx #0
.chars
    stx hud_k
    lda time_text,x : jsr get_glyph
    lda hud_k : asl a : asl a : asl a : asl a : tax     \ 2 byte columns of 8 rows each
    ldy #0
.rows
    lda txt_glyph,y : lsr a : lsr a : lsr a : lsr a : sta hud_image,x     \ black: colour 1
    lda txt_glyph,y : and #15 : sta hud_image + 8,x
    inx : iny : cpy #8 : bne rows
    ldx hud_k : inx : cpx #4 : bne chars
.same
    \ at the top left of the window, and the rating at the bottom right
    lda #IMG_Hud : sta p_img
    lda #0 : sta p_x+1
    lda scrollcol : asl a : rol p_x+1 : asl a : rol p_x+1 : clc : adc #4 : sta p_x : bcc x1 : inc p_x+1 : .x1
    lda clip_t : clc : adc #2 : sta p_y : lda clip_t+1 : adc #0 : sta p_y+1
    jsr log_sprite
    lda restarts : cmp #3 : bcc r_ok : lda #3 : .r_ok : clc : adc #IMG_Rating_1 : sta p_img
    lda p_x : clc : adc #LO(WINDOW_W - 12) : sta p_x : lda p_x+1 : adc #HI(WINDOW_W - 12) : sta p_x+1
    lda p_y : clc : adc #253 : sta p_y : lda p_y+1 : adc #0 : sta p_y+1
    jmp log_sprite
}

\ tmp (16-bit) = tmp / A, remainder in A
.div16
{
    sta hud_d : lda #0 : ldx #16
.loop
    asl tmp : rol tmp+1 : rol a
    cmp hud_d : bcc no : sbc hud_d : inc tmp : .no
    dex : bne loop
    rts
}

\ time_text = "m:ss" for tmp seconds (at most 9:59)
.time_digits
{
    lda tmp+1 : bne cap : lda tmp : cmp #LO(600) : lda tmp+1 : sbc #HI(600) : bcc ok
.cap
    lda #LO(599) : sta tmp : lda #HI(599) : sta tmp+1
.ok
    lda #60 : jsr div16 : sta hud_d2                \ tmp = minutes, A = seconds
    lda tmp : ora #'0' : sta time_text
    lda #':' : sta time_text + 1
    lda hud_d2 : ldx #'0' - 1
.tens
    inx : sec : sbc #10 : bcs tens
    adc #10 + '0' : sta time_text + 3 : stx time_text + 2
    rts
}

\ All the keys: the level is complete. Note the result for the records, and
\ pause for 7 seconds, less one for each restart (as the Steam version)
.level_complete
{
    lda #TUNE_VICTORY : jsr play_music
    lda #1 : sta won
    lda #0 : sta bwon : sta bwon + 1
    lda restarts : cmp #3 : bcc r : lda #3 : .r : tax
    lda win_len_lo,x : sta win_ticks : lda win_len_hi,x : sta win_ticks+1
    lda cur_level : sta done_level
    lda lvl_ticks : sta done_ticks : lda lvl_ticks+1 : sta done_ticks+1
    lda restarts : sta done_restarts
    lda #0 : sta done_gems
    lda num_gems : beq no_gems
    lda gems_found : cmp num_gems : bcc no_gems
    inc done_gems
.no_gems
    lda #1 : sta done_valid
    rts
}
.win_len_lo EQUB LO(7 * 50), LO(6 * 50), LO(5 * 50), LO(4 * 50)
.win_len_hi EQUB HI(7 * 50), HI(6 * 50), HI(5 * 50), HI(4 * 50)

\ The level-complete panel, drawn once into each buffer: the time, the gems,
\ the medal and a trophy over Trogg (the Steam version's, less its animation)
MACRO WIN_TEXT dy, text
    jsr win_text
    EQUB dy
    EQUS text, 0
ENDMACRO
.win_panel
{
    ldx back : lda #1 : sta bwon,x
    lda #1 : sta txt_colour
    \ the top line: 40 rows up from the middle (60 with a medal)
    lda #88 : ldx done_restarts : cpx #3 : bcs base : lda #68 : .base : sta hud_y
    WIN_TEXT 0, "We've done it!"
    \ the time, to a thousandth of a second
    lda done_ticks : sta tmp : lda done_ticks+1 : sta tmp+1
    lda #50 : jsr div16 : sta hud_r                 \ (the ticks over: 20 ms each)
    jsr time_digits
    \ milliseconds: r * 20, so the digits are r / 5, (r MOD 5) * 2 and 0
    lda #'.' : sta time_text + 4
    lda hud_r : ldx #'0' - 1
.fifths
    inx : sec : sbc #5 : bcs fifths
    adc #5 : asl a : ora #'0' : sta time_text + 6
    stx time_text + 5
    lda #'0' : sta time_text + 7
    lda #0 : sta time_text + 8
    lda #16 : jsr win_line
    lda #LO(time_text) : sta src : lda #HI(time_text) : sta src+1
    jsr win_print
    lda #32 : sta hud_dy
    lda done_gems : beq no_gems
    WIN_TEXT 32, "You collected all the gems!"
    lda #48 : sta hud_dy
.no_gems
    \ the medal
    lda done_restarts : cmp #3 : bcs no_medal
    lda hud_dy : clc : adc #32 : sta hud_dy
    lda done_restarts : asl a : tax
    lda medal_text,x : sta src : lda medal_text + 1,x : sta src+1
    lda hud_dy : jsr win_line
    jsr win_print
    \ ... and the trophy over Trogg
    lda done_restarts : clc : adc #IMG_Rating_1 : sta p_img
    lda tx : clc : adc #21 : sta p_x : lda tx+1 : adc #0 : sta p_x+1
    lda ty : sec : sbc #23 : sta p_y : lda ty+1 : sbc #0 : sta p_y+1
    lda #PM_PLOT : sta p_mode
    jsr plot
    lda #IMG_TrophyStand : sta p_img
    jsr plot
.no_medal
    rts
}
.medal_text EQUW t_gold, t_silver, t_bronze
.t_gold   EQUS "!!! Gold Medal !!!", 0
.t_silver EQUS "!!! Silver Medal !!!", 0
.t_bronze EQUS "!!! Bronze Medal !!!", 0


\ Print the string after the JSR (after a byte: its row below hud_y), centred
.win_text
{
    pla : sta src : pla : sta src+1
    ldy #1 : lda (src),y : jsr win_line
    inc src : bne s1 : inc src+1 : .s1
    inc src : bne s2 : inc src+1 : .s2
    jsr win_print
    tya : clc : adc src : tax : lda src+1 : adc #0 : pha : txa : pha
    rts
}
\ txt_y = the window's top + hud_y + A
.win_line
{
    clc : adc hud_y : adc clip_t : sta txt_y : lda clip_t+1 : adc #0 : sta txt_yh
    rts
}
\ Print the string at (src), centred in the window, at txt_y; Y ends at its 0
.win_print
{
    ldy #0
.len
    lda (src),y : beq got : iny : bne len
.got
    sty tmp
    lda scrollcol : clc : adc #40 : sec : sbc tmp : sta txt_col
    ldy #0
.loop
    lda (src),y : beq done
    sty txt_i
    jsr print_char
    ldy txt_i
    inc txt_col : inc txt_col
    iny : bne loop
.done
    rts
}

\ Choose the next level: A, or the first after it that can be played
.load_playable
{
    pha : jsr stop_sounds : jsr bring_overlay : pla
.try
    cmp #NUM_LEVELS : bcc in_range : lda #0 : .in_range
    jsr load_level : bcc done
    lda cur_level : clc : adc #1
    jmp try
.done
    rts
}

.logic_end

\ ------------------------------------------------------------------------------
\ The current level, filled in by load_level (not saved: these follow logic_end)
\ ------------------------------------------------------------------------------

.plat_xl    SKIP MAX_PLATS      \ platforms: where they are now
.plat_xh    SKIP MAX_PLATS
.plat_yl    SKIP MAX_PLATS
.plat_yh    SKIP MAX_PLATS
.plat_w     SKIP MAX_PLATS
.plat_x0l   SKIP MAX_PLATS      \ ... and where they start
.plat_x0h   SKIP MAX_PLATS
.plat_y0l   SKIP MAX_PLATS
.plat_y0h   SKIP MAX_PLATS
.plat_moving SKIP MAX_PLATS
.plat_img   SKIP MAX_PLATS
.plat_bouncy SKIP MAX_PLATS         \ 128 if Trogg bounces off it (it has a spring), else 0
.lad_xl     SKIP MAX_LADDERS    \ ladders, including their hidden extensions
.lad_xh     SKIP MAX_LADDERS
.lad_yl     SKIP MAX_LADDERS
.lad_yh     SKIP MAX_LADDERS
.lad_hl     SKIP MAX_LADDERS
.lad_hh     SKIP MAX_LADDERS
.lad_ext    SKIP MAX_LADDERS
.lad_img    SKIP MAX_LADDERS
.lad_half   SKIP MAX_LADDERS        \ 128 if the ladder is really half a pixel right of its x (one, in D_9)
.draw_img   SKIP MAX_DRAW       \ keys, gems, bulbs and static meanies, in drawing order
.draw_xl    SKIP MAX_DRAW
.draw_xh    SKIP MAX_DRAW
.draw_yl    SKIP MAX_DRAW
.draw_yh    SKIP MAX_DRAW
.draw_c0    SKIP MAX_DRAW       \ byte columns covered [c0, c1)
.draw_c1    SKIP MAX_DRAW
.draw_kind  SKIP MAX_DRAW
.draw_ll    SKIP MAX_DRAW       \ top-left corner
.draw_lh    SKIP MAX_DRAW
.draw_tl    SKIP MAX_DRAW
.draw_th    SKIP MAX_DRAW
.sl_kind    SKIP MAX_SLOW       \ moving platforms and meanies: how they move
.sl_img     SKIP MAX_SLOW
.sl_x0l     SKIP MAX_SLOW
.sl_x0h     SKIP MAX_SLOW
.sl_y0l     SKIP MAX_SLOW
.sl_y0h     SKIP MAX_SLOW
.sl_aminl   SKIP MAX_SLOW
.sl_aminh   SKIP MAX_SLOW
.sl_amaxl   SKIP MAX_SLOW
.sl_amaxh   SKIP MAX_SLOW
.sl_bminl   SKIP MAX_SLOW
.sl_bminh   SKIP MAX_SLOW
.sl_bmaxl   SKIP MAX_SLOW
.sl_bmaxh   SKIP MAX_SLOW
.sl_vf      SKIP MAX_SLOW
.sl_vi      SKIP MAX_SLOW
.sl_vy      SKIP MAX_SLOW
.sl_plat    SKIP MAX_SLOW
.sl_wait    SKIP MAX_SLOW
.sl_simple  SKIP MAX_SLOW
.slowsave1  SKIP SLOWSAVE1_SIZE     \ the second buffer's save area for meanies flying off
.hud_image  SKIP 64                 \ the timer, as an image: 8 byte columns of 8 rows
.time_text  SKIP 9
.hud_k      SKIP 1
.hud_d      SKIP 1
.hud_d2     SKIP 1
.hud_r      SKIP 1
.hud_y      SKIP 1
.hud_dy     SKIP 1
\ Moving platforms and meanies: current state, and copies for checkpoints
SLOW_N = MAX_SLOW
.s_alive    SKIP SLOW_N
.s_xf       SKIP SLOW_N
.s_xl       SKIP SLOW_N
.s_xh       SKIP SLOW_N
.s_yf       SKIP SLOW_N
.s_yl       SKIP SLOW_N
.s_yh       SKIP SLOW_N
.s_vf       SKIP SLOW_N
.s_vi       SKIP SLOW_N
.s_vy       SKIP SLOW_N
.s_wait     SKIP SLOW_N
.cps_alive  SKIP SLOW_N
.cps_xf     SKIP SLOW_N
.cps_xl     SKIP SLOW_N
.cps_xh     SKIP SLOW_N
.cps_yf     SKIP SLOW_N
.cps_yl     SKIP SLOW_N
.cps_yh     SKIP SLOW_N
.cps_vf     SKIP SLOW_N
.cps_vi     SKIP SLOW_N
.cps_vy     SKIP SLOW_N
.cps_wait   SKIP SLOW_N
.d_xl       SKIP SLOW_N             \ where they are shown (and collided with)
.d_xh       SKIP SLOW_N
.d_yl       SKIP SLOW_N
.d_yh       SKIP SLOW_N
.n_vis      SKIP SLOW_N             \ draw_slow workspace
.n_chg      SKIP SLOW_N
.dr_on      SKIP 2 * SLOW_N         \ where each buffer last drew them
.dr_xl      SKIP 2 * SLOW_N
.dr_xh      SKIP 2 * SLOW_N
.dr_yl      SKIP 2 * SLOW_N
.dr_yh      SKIP 2 * SLOW_N
.dr_c0      SKIP 2 * SLOW_N         \ ... and what that covered (byte columns, rows)
.dr_c1      SKIP 2 * SLOW_N
.dr_y0      SKIP 2 * SLOW_N
.dr_y1      SKIP 2 * SLOW_N
.dmg_n      SKIP 1                  \ damage: areas repainted in this frame
.dmg_all    SKIP 1
.dmg_c0     SKIP MAX_DMG
.dmg_c1     SKIP MAX_DMG
.dmg_y0     SKIP MAX_DMG
.dmg_y1     SKIP MAX_DMG
.cpp_xl     SKIP MAX_PLATS
.cpp_xh     SKIP MAX_PLATS
.cpp_yl     SKIP MAX_PLATS
.cpp_yh     SKIP MAX_PLATS
.bank6_end
SAVE "BANK6", bank6_start, logic_end
PRINT "Bank 6: spans and tables to", ~logic_start, ", logic to", ~logic_end, ", level tables to", ~bank6_end, "(", &C000 - bank6_end, "bytes free )"


\ ------------------------------------------------------------------------------
\ Sideways RAM bank 7: the current level's background, unrolled when it starts,
\ and the code that only needs bank 7 and main RAM
\
\ A horizontally scrolling level's background is stored as columns of character
\ cells, a vertically scrolling one's as rows ("lines" of cells, either way):
\   &8000/&8100  the address of each line
\   &8200        the cell dictionary: each distinct non-empty character cell of
\                the level, numbered 0-1023 in order of first use, in pages of
\                256. Line L of cell N is at BG_DICT + (N DIV 256) * &800 +
\                L * &100 + (N MOD 256). As many pages as the level needs.
\   then         the lines: three masks (4 bytes each for a column, 10 for a
\                row) of the non-empty cells (bit 7 of the first byte = the top
\                cell, or the leftmost), bit 8 of their numbers and bit 9, then
\                each non-empty cell's number (low byte)
\   BG_TOP       the front end's records, then this code, then where shifts 0-2
\                of each image are (img_bank0-2, img_lo0-2, img_hi0-2)
\   OVERLAYZ_ORG the level loader, packed (unpacked to OVERLAY_RUN when a level loads)
\ While the menus are up, the front end is unpacked to &8000 instead (it ends
\ before BG_TOP, so the records stay put).
\ ------------------------------------------------------------------------------

BG_LO = &8000
BG_HI = &8100

CLEAR &8000, &C000
ORG BG_TOP
GUARD OVERLAYZ_ORG
.bank7_start

\ ---- The part of the front end that stays: the records (they last until the
\ machine is switched off), adding a result to them, and unpacking the rest.
.rec_best_lo SKIP NUM_LEVELS        \ best time (game ticks), &FFFF if none
.rec_best_hi SKIP NUM_LEVELS
.rec_gem    SKIP NUM_LEVELS         \ 1 if completed with all the gems
.rec_rate   SKIP NUM_LEVELS * 4     \ fewest restarts, per difficulty (Easy, Hard, Harder, Insane), &FF if none
.fe_lev     SKIP 1

\ Add the result of the level just finished (done_*) to the records
.fe_record
{
    ldx done_level : stx fe_lev
    lda done_ticks : cmp rec_best_lo,x : lda done_ticks+1 : sbc rec_best_hi,x : bcs not_best
    lda done_ticks : sta rec_best_lo,x : lda done_ticks+1 : sta rec_best_hi,x
.not_best
    lda done_gems : beq no_gem : lda #1 : sta rec_gem,x : .no_gem
    jsr fe_rate_index
    lda done_restarts : cmp rec_rate,y : bcs done : sta rec_rate,y
.done
    rts
}

\ Y = the index in rec_rate of level fe_lev at this difficulty
.fe_rate_index
{
    ldx difficulty : lda fe_diff_index,x : sta tmp
    lda fe_lev : asl a : asl a : clc : adc tmp : tay
    rts
}
.fe_diff_index EQUB 0, 0, 1, 1, 2, 2, 3

\ Unpack the front end from SCREEN (put there by fe_stage, in whichever screen
\ buffer the CPU is using) to &8000. See tools/pack.py for the format.
.fe_unpack
    lda #0 : sta src : sta dp
    lda #HI(SCREEN) : sta src+1 : lda #&80 : sta dp+1
\ Unpack from (src) to (dp): see tools/pack.py for the format. Uses tmp (a
\ length), UDIST (the distance - 1) and UBITS (the bits left of the last byte
\ of them, with a 1 after them).
UDIST = tblptr
UBITS = p_x
.unpack
{
    ldy #0
    lda #&80 : sta UBITS
.literals
    jsr gamma
.lit_loop
    jsr get : jsr put
    jsr dec_len : bne lit_loop
    jsr bit : bcs new_copy
    jsr gamma                               \ a copy from the last distance
    jsr copy
.after_copy
    jsr bit : bcc literals
.new_copy
    jsr gamma
    lda tmp+1 : bne done                    \ (a distance of 256 * 256 or more: the end)
    ldx tmp : dex : stx UDIST+1
    jsr get : sta UDIST
    jsr gamma
    inc tmp : bne len_ok : inc tmp+1 : .len_ok   \ (the length - 1 was stored)
    jsr copy
    jmp after_copy
.done
    rts
\ copy tmp bytes from dp - UDIST - 1
.copy
    clc : lda dp : sbc UDIST : sta ptr
    lda dp+1 : sbc UDIST+1 : sta ptr+1
.copy_loop
    lda (ptr),y : jsr put
    inc ptr : bne same : inc ptr+1 : .same
    jsr dec_len : bne copy_loop
    rts
\ tmp = tmp - 1, Z set if that's 0
.dec_len
    lda tmp : bne dec_lo : dec tmp+1 : .dec_lo
    dec tmp
    lda tmp : ora tmp+1
    rts
\ tmp = an interleaved Elias gamma number: 1, then (while the next bit is 0)
\ doubled plus the bit after
.gamma
    lda #1 : sta tmp : lda #0 : sta tmp+1
.gamma_loop
    jsr bit : bcs gamma_done
    jsr bit : rol tmp : rol tmp+1
    jmp gamma_loop
.gamma_done
    rts
\ C = the next bit (a new byte of them when those run out)
.bit
    asl UBITS : bne bit_done
    jsr get : sec : rol a : sta UBITS
.bit_done
    rts
.get
    lda (src),y
    inc src : bne got : inc src+1 : .got
    rts
.put
    sta (dp),y
    inc dp : bne put_done : inc dp+1 : .put_done
    rts
}

\ Copy cell A of dictionary page X to the screen at (ptr). X, Y changed.
.copy_cell
{
    cpx #2 : bcs p23
    cpx #1 : beq p1
    tax : ldy #0
    FOR l, 0, 7
    lda BG_DICT + l * &100,x : sta (ptr),y : IF l < 7 : iny : ENDIF
    NEXT
    rts
.p1
    tax : ldy #0
    FOR l, 0, 7
    lda BG_DICT + &800 + l * &100,x : sta (ptr),y : IF l < 7 : iny : ENDIF
    NEXT
    rts
.p23
    bne p3
    tax : ldy #0
    FOR l, 0, 7
    lda BG_DICT + &1000 + l * &100,x : sta (ptr),y : IF l < 7 : iny : ENDIF
    NEXT
    rts
.p3
    tax : ldy #0
    FOR l, 0, 7
    lda BG_DICT + &1800 + l * &100,x : sta (ptr),y : IF l < 7 : iny : ENDIF
    NEXT
    rts
}

\ Find line pl_line's cells from pl_i0 on: load its masks into cmask; src = the
\ number of the first non-empty cell at or after pl_i0; X = the mask byte and
\ curbit the bit for cell pl_i0
.seek_line
{
    ldx pl_line
    lda BG_LO,x : sta src : lda BG_HI,x : sta src+1
    lda mb : asl a : adc mb : sta tmp+1 : tay : dey       \ 3 masks
.getmask
    lda (src),y : sta cmask,y : dey : bpl getmask
    \ skip the numbers of the non-empty cells before pl_i0 (count its mask bits)
    lda #0 : sta tmp
    ldx #0
    lda pl_i0
.whole
    cmp #8 : bcc part
    pha : lda cmask,x : jsr popcount_add : pla
    inx : sec : sbc #8 : jmp whole
.part
    tay : lda cmask,x : and topbits,y : jsr popcount_add
    lda tmp : clc : adc tmp+1 : adc src : sta src : bcc nc : inc src+1 : .nc
    lda pl_i0 : lsr a : lsr a : lsr a : tax
    lda pl_i0 : and #7 : tay : lda bitpos,y : sta curbit
    rts
}

\ Paint cells pl_i0..pl_i1 of line pl_line on the screen, from (ptr) (stepping
\ down a column, or along a row). With rr_raw set (columns only), cells that a
\ moving sprite will be copied into are left alone (see raw_setup).
.paint_line
{
    jsr seek_line
    lda pl_i1 : sec : sbc pl_i0 : sta cellk         \ cells left - 1
.cell
    lda cmask,x : and curbit : beq empty
    \ its dictionary page, from the second and third masks (if the level has more than one)
    stx u_sx
    lda #0 : sta cpage
    lda pages1 : beq page_ok
    txa : clc : adc mb : tay
    lda cmask,y : and curbit : beq b8 : inc cpage : .b8
    tya : clc : adc mb : tay
    lda cmask,y : and curbit : beq b9 : inc cpage : inc cpage : .b9
.page_ok
    ldy #0 : lda (src),y                            \ the cell's number
    inc src : bne nc : inc src+1 : .nc
    ldx cpage : jsr copy_cell
    ldx u_sx
    jmp next
.empty
    lda rr_raw : beq clear
    \ will the sprite cover this cell completely? (then leave it)
    lda pl_line : sec : sbc m_ncol : bcc clear
    cmp m_wb : bcs clear
    cmp #MAX_RAW_COLS : bcs clear
    tay
    lda pl_i1 : sec : sbc cellk                     \ this cell
    cmp m_kf0 : bcc clear
    cmp m_kf1 : bcs clear
    sec : sbc m_nk0 : stx tmp : tax
    lda bitpos_lo,x : ora rawbits,y : sta rawbits,y
    ldx tmp
    jmp next
.clear
    lda #0 : ldy #7
    sta (ptr),y : dey : sta (ptr),y : dey : sta (ptr),y : dey : sta (ptr),y : dey
    sta (ptr),y : dey : sta (ptr),y : dey : sta (ptr),y : dey : sta (ptr),y
.next
    lsr curbit : bcc same : ror curbit : inx : .same     \ (ror puts &80 back)
    dec cellk : bmi done
    lda is_vert : bne along
    lda ptr : clc : adc #LO(640) : sta ptr
    lda ptr+1 : adc #HI(640) : cmp #&80 : bcc nw : sbc #&50 : .nw : sta ptr+1
    jmp cell
.along
    lda ptr : clc : adc #8 : sta ptr : bcc cell_j : inc ptr+1
.cell_j
    jmp cell
.done
    rts
}

\ tmp += number of bits set in A
.popcount_add
    tay : lda bits_in,y : clc : adc tmp : sta tmp
    rts
.bits_in
FOR n, 0, 255
    EQUB (n AND 1) + ((n DIV 2) AND 1) + ((n DIV 4) AND 1) + ((n DIV 8) AND 1) + ((n DIV 16) AND 1) + ((n DIV 32) AND 1) + ((n DIV 64) AND 1) + ((n DIV 128) AND 1)
NEXT
.topbits EQUB &00, &80, &C0, &E0, &F0, &F8, &FC, &FE
.bitpos  EQUB &80, &40, &20, &10, &08, &04, &02, &01
.bitpos_lo EQUB &01, &02, &04, &08, &10, &20, &40, &80

\ Where shifts 0-2 of each image are (plot pages this bank in to look them up)
INCLUDE "src/gen/imgdir.asm"
.bank7_end
SAVE "BANK7", bank7_start, bank7_end
PRINT "Bank 7: background to", ~BG_TOP, ", code and image addresses to", ~bank7_end, "(", OVERLAYZ_ORG - bank7_end, "bytes free )"


\ ------------------------------------------------------------------------------
\ The level loader: code that only runs while a level is loading (or at boot).
\ It's kept in bank 7 and copied to the screen memory at &6000 to run (with
\ the screen blanked), so it takes no room in main RAM or bank 6.
\ ------------------------------------------------------------------------------

CLEAR &6000, &8000
ORG OVERLAY_RUN
GUARD &8000
.overlay_start
\ ------------------------------------------------------------------------------
\ Levels. All of them are kept packed in HAZEL and ANDY (see pack_level in the
\ converter for the format). load_level unpacks one into the tables at the end
\ of this bank, working out what GameMaker worked out when a room started
\ (ladders' hidden extensions, moving platforms' ranges, the platform each
\ Scrubbly walks and the ladder each Poglet climbs), then unrolls its
\ background into bank 7.
\ ------------------------------------------------------------------------------

STAGE = &0400                       \ the packed level is copied here (save area 0, free while loading)
H_COLS = 0 : H_CELLS = 1 : H_BG = 2 : H_TX = 3 : H_TY = 5 : H_FLAGS = 7
H_NPAL = 8 : H_NPLAT = 9 : H_NLAD = 10 : H_NDRAW = 11 : H_NMEAN = 12 : H_NMPLAT = 13
H_SIZE = 14
ACCCON_Y = 8                        \ ACCCON bit 3: HAZEL at &C000-&DFFF
ROMSEL_ANDY = &80                   \ ROMSEL bit 7: ANDY at &8000-&8FFF

\ Copy level A (1KB, more than any level needs) from HAZEL or ANDY to STAGE.
.fetch_level
{
    tax
    lda level_addr_lo,x : sta src : lda level_addr_hi,x : sta src+1
    lda #LO(STAGE) : sta dp : lda #HI(STAGE) : sta dp+1
    sei
    lda src+1 : cmp #&C0 : bcc andy
    lda ACCCON : ora #ACCCON_Y : sta ACCCON
    bne copy
.andy
    lda ROMSEL_COPY : ora #ROMSEL_ANDY : sta ROMSEL
.copy
    ldx #4 : ldy #0
.loop
    lda (src),y : sta (dp),y : iny : bne loop
    inc src+1 : inc dp+1
    dex : bne loop
    lda ACCCON : and #&FF - ACCCON_Y : sta ACCCON
    lda ROMSEL_COPY : sta ROMSEL
    cli
    rts
}

\ Load level A. Carry set if it can't be played yet (it scrolls vertically).
.load_level
{
    sta cur_level
    jsr fetch_level
    \ the level's size (and which way it scrolls), colour and Trogg's start
    lda STAGE + H_CELLS : sta level_rows
    lda #0 : sta level_h+1
    lda level_rows : asl a : rol level_h+1 : asl a : rol level_h+1 : asl a : rol level_h+1 : sta level_h
    ldx #0 : ldy #4                                 \ (columns have 4-byte masks)
    lda level_rows : sec : sbc #32 : beq horizontal
    ldx #1 : ldy #10                                \ (rows have 10-byte masks)
.horizontal
    sta row_max : stx is_vert : sty mb
    lda STAGE + H_COLS : sta level_cols
    lda #0 : sta tmp+1
    lda level_cols : asl a : rol tmp+1 : asl a : rol tmp+1 : sta tmp       \ width
    sec : sbc #LO(WINDOW_W) : sta scroll_max : lda tmp+1 : sbc #HI(WINDOW_W) : sta scroll_max+1
    lda tmp : sec : sbc #10 : sta x_max : lda tmp+1 : sbc #0 : sta x_max+1
    lda STAGE + H_BG : sta level_bg
    lda STAGE + H_TX : sta trogg_x0 : lda STAGE + H_TX + 1 : sta trogg_x0+1
    lda STAGE + H_TY : sta trogg_y0 : lda STAGE + H_TY + 1 : sta trogg_y0+1
    lda STAGE + H_NPLAT : sta num_plats
    lda STAGE + H_NLAD : sta num_ladders
    lda STAGE + H_NDRAW : sta num_draw
    lda STAGE + H_NMEAN : clc : adc STAGE + H_NMPLAT : sta num_slow
    \ the records follow the palette
    lda #LO(STAGE + H_SIZE) : clc : adc STAGE + H_NPAL : sta sp
    lda #HI(STAGE + H_SIZE) : adc #0 : sta sp+1

    \ Platforms
    ldx #0
.plat_loop
    cpx num_plats : beq plats_done
    jsr next_rec
    lda rx : sta plat_xl,x : sta plat_x0l,x : lda rx+1 : sta plat_xh,x : sta plat_x0h,x
    lda ry : sta plat_yl,x : sta plat_y0l,x : lda ry+1 : sta plat_yh,x : sta plat_y0h,x
    lda rimg : and #&80 : sta plat_bouncy,x           \ (the palette marks bouncy platforms)
    lda rimg : and #&7F : sta plat_img,x : tay
    lda img_w,y : sta plat_w,x
    lda #0 : sta plat_moving,x
    inx : bne plat_loop
.plats_done

    \ Ladders, reaching up to a platform just above them (GameMaker's LadderAdd)
    lda #0 : sta ld_i
.lad_loop
    ldx ld_i : cpx num_ladders : bne lad_one
    jmp lads_done
.lad_one
    jsr next_rec
    ldx ld_i
    lda rx : sta lad_xl,x : sta q_x : lda rx+1 : sta lad_xh,x : sta q_x+1
    lda rimg : and #&80 : sta lad_half,x             \ (the palette marks a ladder at x + 0.5)
    lda rimg : and #&7F : sta rimg : sta lad_img,x
    \ a platform with its top in [y - 16, y - 1)?
    lda ry : sec : sbc #LADDER_EXTRA_LENGTH : sta q_y1 : lda ry+1 : sbc #0 : sta q_y1+1
    lda ry : sec : sbc #1 : sta q_y2 : lda ry+1 : sbc #0 : sta q_y2+1
    jsr platform_find
    ldx ld_i
    lda #0 : sta tmp
    lda res_found : beq no_ext
    lda ry : clc : sbc res_y : sta tmp           \ y - top - 1
.no_ext
    lda tmp : sta lad_ext,x
    lda ry : sec : sbc tmp : sta lad_yl,x : lda ry+1 : sbc #0 : sta lad_yh,x
    ldy rimg
    lda img_h,y : clc : adc #LADDER_EXTRA_LENGTH : sta lad_hl,x : lda #0 : adc #0 : sta lad_hh,x
    lda lad_hl,x : clc : adc tmp : sta lad_hl,x : bcc nc_h : inc lad_hh,x : .nc_h
    inc ld_i : jmp lad_loop
.lads_done

    \ Keys, gems, bulbs and meanies that don't move, in drawing order
    lda #0 : sta num_keys : sta num_gems
    ldx #0
.draw_loop
    cpx num_draw : bne draw_one
    jmp draws_done
.draw_one
    jsr next_rec
    ldy rimg : tya : sta draw_img,x
    lda img_kind,y : sta draw_kind,x
    cmp #KIND_KEY : bne not_key : inc num_keys : .not_key
    cmp #KIND_GEM : bne not_gem : inc num_gems : .not_gem
    lda rx : sta draw_xl,x : lda rx+1 : sta draw_xh,x
    lda ry : sta draw_yl,x : lda ry+1 : sta draw_yh,x
    \ left = x - xo, top = y - yo
    lda rx : sec : sbc img_xo,y : sta draw_ll,x : sta tmp : lda rx+1 : sbc #0 : sta draw_lh,x : sta tmp+1
    lda ry : sec : sbc img_yo,y : sta draw_tl,x : lda ry+1 : sbc #0 : sta draw_th,x
    \ byte columns [left >> 2, (left + w + 3) >> 2), within 0-255
    lda #0
    ldy tmp+1 : bmi c0_ok
    jsr shr2
.c0_ok
    ldy rimg
    sta draw_c0,x
    lda tmp : clc : adc img_w,y : sta tmp : bcc c1a : inc tmp+1 : .c1a
    lda tmp : clc : adc #3 : sta tmp : bcc c1b : inc tmp+1 : .c1b
    lda tmp+1 : cmp #4 : bcc c1_ok
    lda #255 : bne c1_st
.c1_ok
    jsr shr2
.c1_st
    sta draw_c1,x
    inx : jmp draw_loop
.draws_done

    \ Moving meanies: their records (they come after the moving platforms in
    \ the slow sprite tables)
    lda STAGE + H_NMPLAT : sta ld_i
    lda #0 : sta ld_j
.mean_loop
    lda ld_j : cmp STAGE + H_NMEAN : beq means_done
    jsr next_rec
    ldx ld_i
    lda rimg : sta sl_img,x
    lda rx : sta sl_x0l,x : lda rx+1 : sta sl_x0h,x
    lda ry : sta sl_y0l,x : lda ry+1 : sta sl_y0h,x
    inc ld_i : inc ld_j : jmp mean_loop
.means_done
    \ ... then their settings
    lda STAGE + H_NMPLAT : sta ld_i
    lda #0 : sta ld_j
.param_loop
    lda ld_j : cmp STAGE + H_NMEAN : beq params_done
    jsr meanie_settings
    inc sp : bne pn : inc sp+1 : .pn
    inc ld_i : inc ld_j : jmp param_loop
.params_done

    \ Moving platforms
    lda #0 : sta ld_i
.mplat_loop
    lda ld_i : cmp STAGE + H_NMPLAT : beq mplats_done
    jsr moving_platform
    lda sp : clc : adc #2 : sta sp : bcc mp : inc sp+1 : .mp
    inc ld_i : jmp mplat_loop
.mplats_done

    \ Nothing in the unused slow sprite slots
    ldx num_slow
.unused
    cpx #MAX_SLOW : bcs unused_done
    lda #0 : sta sl_kind,x
    inx : bne unused
.unused_done

    jsr bg_items
    jsr unroll_bg
    clc
    rts
}

\ A = tmp >> 2 (tmp below 1024)
.shr2
{
    lda tmp+1 : sta rimg2 : lda tmp
    lsr rimg2 : ror a : lsr rimg2 : ror a
    rts
}

\ Read a 3-byte record at (sp): rx, ry and rimg (from the palette)
.next_rec
{
    ldy #2 : lda (sp),y : pha
    and #3 : sta rx+1
    pla : pha : lsr a : lsr a : and #3 : sta ry+1
    pla : lsr a : lsr a : lsr a : lsr a : tay
    lda STAGE + H_SIZE,y : sta rimg
    ldy #0 : lda (sp),y : sta rx
    iny : lda (sp),y : sta ry
    lda sp : clc : adc #3 : sta sp : bcc nc : inc sp+1 : .nc
    rts
}

\ The settings of moving meanie ld_i, from the byte at (sp)
.meanie_settings
{
    ldx ld_i
    ldy #0 : lda (sp),y : pha
    and #128 : beq s0 : lda #1 : .s0 : sta sl_simple,x
    pla : and #127 : tay
    lda slp_kind,y : sta sl_kind,x
    lda slp_vf,y : sta sl_vf,x : lda slp_vi,y : sta sl_vi,x
    lda #0 : sta sl_vy,x : sta sl_wait,x
    sta sl_aminl,x : sta sl_aminh,x : sta sl_amaxl,x : sta sl_amaxh,x
    sta sl_bminl,x : sta sl_bminh,x : sta sl_bmaxl,x : sta sl_bmaxh,x
    lda #255 : sta sl_plat,x
    lda sl_kind,x
    cmp #SL_SCRUBBLY : beq scrubbly
    cmp #SL_POGLET : bne hooter
    jmp poglet
.hooter
    lda slp_wait,y : sta sl_wait,x
    rts
.scrubbly
    \ the platform it's on: PlatformFind(x, y - 1, y + 3)
    sty ld_p
    lda sl_x0l,x : sta q_x : lda sl_x0h,x : sta q_x+1
    lda sl_y0l,x : sec : sbc #1 : sta q_y1 : lda sl_y0h,x : sbc #0 : sta q_y1+1
    lda sl_y0l,x : clc : adc #3 : sta q_y2 : lda sl_y0h,x : adc #0 : sta q_y2+1
    jsr platform_find
    ldx ld_i : ldy res_i
    \ it walks between its left + 8 and right - 9
    lda plat_xl,y : clc : adc #8 : sta sl_aminl,x : lda plat_xh,y : adc #0 : sta sl_aminh,x
    lda plat_xl,y : clc : adc plat_w,y : sta tmp : lda plat_xh,y : adc #0 : sta tmp+1
    lda tmp : sec : sbc #9 : sta sl_amaxl,x : lda tmp+1 : sbc #0 : sta sl_amaxh,x
    ldy ld_p
    lda slp_flags,y : and #1 : beq done
    lda res_i : sta sl_plat,x
.done
    rts
.poglet
    lda slp_flags,y : and #2 : beq on_ladder
    \ its range is set by yoff_min and yoff_max
    lda slp_ymin,y : jsr y_plus_signed : sta sl_aminl,x : lda tmp+1 : sta sl_aminh,x
    lda slp_ymax,y : jsr y_plus_signed : sta sl_amaxl,x : lda tmp+1 : sta sl_amaxh,x
    rts
.on_ladder
    \ the ladder it's on: from its top + 30 to its bottom + 13
    jsr ladder_below
    ldx ld_i : ldy res_i
    lda lad_yl,y : clc : adc #30 : sta sl_aminl,x : lda lad_yh,y : adc #0 : sta sl_aminh,x
    lda lad_yl,y : clc : adc lad_hl,y : sta tmp : lda lad_yh,y : adc lad_hh,y : sta tmp+1
    lda tmp : clc : adc #13 : sta sl_amaxl,x : lda tmp+1 : adc #0 : sta sl_amaxh,x
    rts
}

\ A = signed offset: returns A (and tmp+1) = sl_y0 of slow sprite X + it
.y_plus_signed
{
    sta tmp
    lda #0 : bit tmp : bpl pos : lda #&FF : .pos : sta tmp+1
    lda sl_y0l,x : clc : adc tmp : pha
    lda sl_y0h,x : adc tmp+1 : sta tmp+1
    pla
    rts
}

\ The ladder a Poglet at slow sprite ld_i is on (GameMaker's LadderFind going
\ down from y - 16 to y + 4, within 6 pixels of x) -> res_i
.ladder_below
{
    ldx ld_i
    lda sl_x0l,x : sta q_x : lda sl_x0h,x : sta q_x+1
    lda sl_y0l,x : sec : sbc #16 : sta res_y : lda sl_y0h,x : sbc #0 : sta res_y+1     \ ry
    lda sl_y0l,x : clc : adc #4 : sta q_y2 : lda sl_y0h,x : adc #0 : sta q_y2+1
    ldx #0
.loop
    cpx num_ladders : beq done
    \ |x - lx| <= 6 ?
    lda q_x : sec : sbc lad_xl,x : sta tmp : lda q_x+1 : sbc lad_xh,x
    beq pos
    cmp #&FF : bne next
    lda tmp : cmp #&FA : bcc next
    bcs near
.pos
    lda tmp : cmp #7 : bcs next
.near
    \ bottom = ly + lh - 1
    lda lad_yl,x : clc : adc lad_hl,x : sta tmp : lda lad_yh,x : adc lad_hh,x : sta tmp+1
    lda tmp : bne b1 : dec tmp+1 : .b1 : dec tmp
    \ ry < bottom and y2 >= ly ?
    lda res_y : cmp tmp : lda res_y+1 : sbc tmp+1 : bcs next
    lda q_y2 : cmp lad_yl,x : lda q_y2+1 : sbc lad_yh,x : bcc next
    stx res_i
    \ ry = min(y2, bottom); stop if that's y2
    lda tmp : cmp q_y2 : lda tmp+1 : sbc q_y2+1 : bcc use_bottom
    rts
.use_bottom
    lda tmp : sta res_y : lda tmp+1 : sta res_y+1
.next
    inx : jmp loop
.done
    rts
}

\ Moving platform ld_i, from the 2 bytes at (sp): its range, found the way
\ oPlatform's first step does (scanning for the nearest platforms)
.moving_platform
{
    ldy #0 : lda (sp),y : sta ld_p : tax           \ the platform
    iny : lda (sp),y : sta ld_f
    lda #1 : sta plat_moving,x
    ldy ld_i
    lda #SL_PLATFORM : sta sl_kind,y
    lda plat_img,x : sta sl_img,y
    lda plat_xl,x : sta sl_x0l,y : sta sl_aminl,y : sta sl_amaxl,y : sta px
    lda plat_xh,x : sta sl_x0h,y : sta sl_aminh,y : sta sl_amaxh,y : sta px+1
    lda plat_yl,x : sta sl_y0l,y : sta sl_bminl,y : sta sl_bmaxl,y : sta py
    lda plat_yh,x : sta sl_y0h,y : sta sl_bminh,y : sta sl_bmaxh,y : sta py+1
    txa : sta sl_plat,y
    lda #5 : sta sl_wait,y
    lda #0 : sta sl_vf,y : sta sl_vi,y : sta sl_vy,y
    lda ld_f : and #128 : beq s0 : lda #1 : .s0 : sta sl_simple,y
    lda plat_w,x : sta pw
    lda plat_img,x : tay : lda img_h,y : sta ph
    \ pr = px + pw (the column just right of it), pl = px - 1
    lda px : clc : adc pw : sta pr : lda px+1 : adc #0 : sta pr+1
    lda px : sec : sbc #1 : sta pl : lda px+1 : sbc #0 : sta pl+1
    \ py + ph
    lda py : clc : adc ph : sta pb : lda py+1 : adc #0 : sta pb+1

    lda ld_f : and #1 : beq no_left : jsr scan_left : .no_left
    lda ld_f : and #2 : beq no_right : jsr scan_right : .no_right
    lda ld_f : and #4 : beq no_up : jsr scan_up : .no_up
    lda ld_f : and #8 : beq no_down : jsr scan_down : .no_down

    \ x speed: +1 or -1 if it has a range, y speed likewise
    ldy ld_i
    lda sl_aminl,y : cmp sl_amaxl,y : bne x_moves
    lda sl_aminh,y : cmp sl_amaxh,y : beq x_still
.x_moves
    lda #&FF : sta sl_vi,y
    lda ld_f : and #16 : beq x_still
    lda #1 : sta sl_vi,y
.x_still
    lda sl_bminl,y : cmp sl_bmaxl,y : bne y_moves
    lda sl_bminh,y : cmp sl_bmaxh,y : beq y_still
.y_moves
    lda #&FF : sta sl_vy,y
    lda ld_f : and #32 : beq y_still
    lda #1 : sta sl_vy,y
.y_still
    rts
}

\ For each platform X: carry set if its top is in [py, pb) (a platform
\ "found" by PlatformFind(column, py, py + ph))
MACRO TOP_IN_PY_PB
    lda plat_yl,x : cmp py : lda plat_yh,x : sbc py+1 : bcc no
    lda plat_yl,x : cmp pb : lda plat_yh,x : sbc pb+1 : bcs no
ENDMACRO

\ amin = 1 + the rightmost column left of it covered by such a platform
\ (scanning left from px - 1); unchanged if there's none
.scan_left
{
    lda #0 : sta found
    ldx num_plats : dex
.loop
    TOP_IN_PY_PB
    \ it must start at or left of pl: qx <= pl
    lda pl : cmp plat_xl,x : lda pl+1 : sbc plat_xh,x : bcc no
    \ c = min(pl, qx + qw - 1)
    lda plat_xl,x : clc : adc plat_w,x : sta tmp : lda plat_xh,x : adc #0 : sta tmp+1
    lda tmp : bne d1 : dec tmp+1 : .d1 : dec tmp
    lda pl : cmp tmp : lda pl+1 : sbc tmp+1 : bcs have_c
    lda pl : sta tmp : lda pl+1 : sta tmp+1
.have_c
    \ keep the largest
    lda found : beq take
    lda best : cmp tmp : lda best+1 : sbc tmp+1 : bcs no
.take
    lda tmp : sta best : lda tmp+1 : sta best+1 : lda #1 : sta found
.no
    dex : bmi scanned
    jmp loop
.scanned
    lda found : beq none
    ldy ld_i
    lda best : clc : adc #1 : sta sl_aminl,y : lda best+1 : adc #0 : sta sl_aminh,y
.none
    rts
}

\ amax = the leftmost column from pr on covered by such a platform, - pw
.scan_right
{
    lda #0 : sta found
    ldx num_plats : dex
.loop
    TOP_IN_PY_PB
    \ it must end at or right of pr: qx + qw - 1 >= pr, i.e. qx + qw > pr
    lda plat_xl,x : clc : adc plat_w,x : sta tmp : lda plat_xh,x : adc #0 : sta tmp+1
    lda pr : cmp tmp : lda pr+1 : sbc tmp+1 : bcs no
    \ c = max(pr, qx)
    lda plat_xl,x : sta tmp : lda plat_xh,x : sta tmp+1
    lda tmp : cmp pr : lda tmp+1 : sbc pr+1 : bcs have_c
    lda pr : sta tmp : lda pr+1 : sta tmp+1
.have_c
    \ (only columns below 1000 are scanned)
    lda tmp : cmp #LO(1000) : lda tmp+1 : sbc #HI(1000) : bcs no
    \ keep the smallest
    lda found : beq take
    lda tmp : cmp best : lda tmp+1 : sbc best+1 : bcs no
.take
    lda tmp : sta best : lda tmp+1 : sta best+1 : lda #1 : sta found
.no
    dex : bmi scanned
    jmp loop
.scanned
    lda found : beq none
    ldy ld_i
    lda best : sec : sbc pw : sta sl_amaxl,y : lda best+1 : sbc #0 : sta sl_amaxh,y
.none
    rts
}

\ Carry set if platform X covers column pl or column pr
.covers_side
{
    \ qx <= pl < qx + qw ?
    lda pl : cmp plat_xl,x : lda pl+1 : sbc plat_xh,x : bcc try_r
    lda plat_xl,x : clc : adc plat_w,x : sta tmp : lda plat_xh,x : adc #0 : sta tmp+1
    lda pl : cmp tmp : lda pl+1 : sbc tmp+1 : bcc yes
.try_r
    lda pr : cmp plat_xl,x : lda pr+1 : sbc plat_xh,x : bcc no
    lda plat_xl,x : clc : adc plat_w,x : sta tmp : lda plat_xh,x : adc #0 : sta tmp+1
    lda pr : cmp tmp : lda pr+1 : sbc tmp+1 : bcc yes
.no
    clc : rts
.yes
    sec : rts
}

\ bmin = the top of the highest platform beside it (at pl or pr) with its
\ top at or above py - 2 (and at least -1)
.scan_up
{
    lda #0 : sta found
    \ limit = py - 2
    lda py : sec : sbc #2 : sta pt : lda py+1 : sbc #0 : sta pt+1
    ldx num_plats : dex
.loop
    jsr covers_side : bcc no
    \ qy <= py - 2 (signed) and qy >= -1
    lda pt : cmp plat_yl,x : lda pt+1 : sbc plat_yh,x : bvc v1 : eor #&80 : .v1 : bmi no
    lda plat_yh,x : bpl ok_low
    lda plat_yl,x : cmp #&FF : bne no
.ok_low
    \ keep the largest
    lda found : beq take
    lda best : cmp plat_yl,x : lda best+1 : sbc plat_yh,x : bvc v2 : eor #&80 : .v2 : bpl no
.take
    lda plat_yl,x : sta best : lda plat_yh,x : sta best+1 : lda #1 : sta found
.no
    dex : bmi scanned
    jmp loop
.scanned
    lda found : beq none
    ldy ld_i
    lda best : sta sl_bminl,y : lda best+1 : sta sl_bminh,y
.none
    rts
}

\ bmax = the top of the lowest platform beside it with its top at or below py
\ (and above 999)
.scan_down
{
    lda #0 : sta found
    ldx num_plats : dex
.loop
    jsr covers_side : bcc no
    \ qy >= py and qy <= 998
    lda plat_yl,x : cmp py : lda plat_yh,x : sbc py+1 : bcc no
    lda plat_yl,x : cmp #LO(999) : lda plat_yh,x : sbc #HI(999) : bcs no
    \ keep the smallest
    lda found : beq take
    lda plat_yl,x : cmp best : lda plat_yh,x : sbc best+1 : bcs no
.take
    lda plat_yl,x : sta best : lda plat_yh,x : sta best+1 : lda #1 : sta found
.no
    dex : bmi scanned
    jmp loop
.scanned
    lda found : beq none
    ldy ld_i
    lda best : sta sl_bmaxl,y : lda best+1 : sta sl_bmaxh,y
.none
    rts
}

\ The background: static platforms, then ladders (GameMaker's drawing order),
\ listed for unroll_bg with their image, left and top
.bg_items
{
    ldy #0
    ldx #0
.plats
    cpx num_plats : beq plats_done
    lda plat_moving,x : bne next_plat
    lda plat_img,x : sta BG_IMG,y
    lda plat_xl,x : sta BG_XL,y : lda plat_xh,x : sta BG_XH,y
    lda plat_yl,x : sta BG_YL,y : lda plat_yh,x : sta BG_YH,y
    iny
    jsr spring_item                                 \ (and a bouncy one's spring)
.next_plat
    inx : bne plats
.plats_done
    ldx #0
.lads
    cpx num_ladders : beq lads_done
    lda lad_img,x : sta BG_IMG,y
    lda lad_xl,x : sta BG_XL,y : lda lad_xh,x : sta BG_XH,y
    \ (drawn where it was placed, above its hidden extension)
    lda lad_yl,x : clc : adc lad_ext,x : sta BG_YL,y : lda lad_yh,x : adc #0 : sta BG_YH,y
    iny
    inx : bne lads
.lads_done
    sty num_bg
    \ for each: left = x - xo, its byte columns [c0, c0 + wb), top = y - yo
    ldx #0
.geom
    cpx num_bg : beq done
    ldy BG_IMG,x
    lda BG_XL,x : sec : sbc img_xo,y : sta BG_XL,x : lda BG_XH,x : sbc #0 : sta BG_XH,x
    lda BG_YL,x : sec : sbc img_yo,y : sta BG_YL,x : lda BG_YH,x : sbc #0 : sta BG_YH,x
    lda BG_XL,x : and #3 : clc : adc img_w,y : adc #3 : lsr a : lsr a : sta BG_WB,x
    lda BG_XL,x : sta tmp : lda BG_XH,x : sta tmp+1
    cmp #&80 : ror tmp+1 : ror tmp
    lda tmp+1 : cmp #&80 : ror tmp+1 : ror tmp
    lda tmp : sta BG_C0L,x : lda tmp+1 : sta BG_C0H,x
    inx : bne geom
.done
    rts
}

\ ------------------------------------------------------------------------------
\ Unrolling a level's background into bank 7 (see store_column for the format),
\ from the unshifted images of its platforms and ladders, shifting them as it
\ goes. This runs only when a level starts, so it needn't be quick. It's in main
\ RAM because it pages the sprite banks and bank 7 in.
\ ------------------------------------------------------------------------------

COLBUF = &0900                      \ one column of the level, 4 pixels by 256 (save area 1, free while loading)
\ (in the screen memory, which is free while loading)
HASH_LO = &3000 : HASH_HI = &3100   \ the dictionary's hash table: per hash, the first cell with it (number + 1)
LINK_LO = &3200 : LINK_HI = &3600   \ per cell, the next with the same hash (number + 1)
ROWBUF = &3A00                      \ one character row of a vertically scrolling level (640 bytes)
OFF_LO = &3D00 : OFF_HI = &3E00     \ where each line is, from DSTAGE
DSTAGE = &4000                      \ the lines, until the dictionary is complete
BG_IMG = &0A00                      \ the background items (from bg_items)
BG_XL = &0A50 : BG_XH = &0AA0       \ left edge
BG_YL = &0AF0 : BG_YH = &0B40       \ top edge
BG_WB = &0B90                       \ byte columns covered
BG_C0L = &0BE0 : BG_C0H = &0C30     \ first byte column (signed)
ASSERT MAX_BG <= &50

.unroll_bg
{
    \ the dictionary's hash table starts empty
    lda #0 : tax
.clear_hash
    sta HASH_LO,x : sta HASH_HI,x : inx : bne clear_hash
    lda #LO(DSTAGE) : sta po : lda #HI(DSTAGE) : sta po+1    \ the lines are built here first
    lda #0 : sta u_line : sta u_cntl : sta u_cnth
    lda is_vert : beq col_loop
    jmp row_loop

    \ A horizontally scrolling level: each byte column, from the top to row 255
.col_loop
    lda #0 : tax
.clr
    sta COLBUF,x : inx : bne clr
    lda #0 : sta u_bl : sta u_bl+1 : sta u_bh : lda #1 : sta u_bh+1
    lda #0 : sta u_i
.item_loop
    ldx u_i : cpx num_bg : beq items_done
    lda u_line : sec : sbc BG_C0L,x : sta u_j : lda #0 : sbc BG_C0H,x : bne next_item
    lda u_j : cmp BG_WB,x : bcs next_item
    lda #LO(COLBUF) : sta u_tb : lda #HI(COLBUF) : sta u_tb+1
    jsr unroll_item
.next_item
    inc u_i : jmp item_loop
.items_done
    lda #LO(COLBUF) : sta u_src : lda #HI(COLBUF) : sta u_src+1
    lda #32 : sta u_cells
    jsr store_line
    inc u_line : lda u_line : cmp level_cols : bne col_loop
    jmp finish

    \ A vertically scrolling level: each character row, all 80 byte columns
.row_loop
    ldx #0 : txa
.rclr
    sta ROWBUF,x : sta ROWBUF + &100,x : sta ROWBUF + &180,x : inx : bne rclr
    \ the band of level rows [8R, 8R + 8)
    lda #0 : sta u_bl+1
    lda u_line : asl a : rol u_bl+1 : asl a : rol u_bl+1 : asl a : rol u_bl+1 : sta u_bl
    clc : adc #8 : sta u_bh : lda u_bl+1 : adc #0 : sta u_bh+1
    lda #0 : sta u_i
.ritem_loop
    ldx u_i : cpx num_bg : bne ritem
    jmp ritems_done
.ritem
    \ does it reach the band? top < bh and top + h > bl
    lda BG_YL,x : cmp u_bh : lda BG_YH,x : sbc u_bh+1 : bvc v1 : eor #&80 : .v1 : bpl rskip
    ldy BG_IMG,x
    lda BG_YL,x : clc : adc img_h,y : sta tmp : lda BG_YH,x : adc #0 : sta tmp+1
    lda u_bl : cmp tmp : lda u_bl+1 : sbc tmp+1 : bvc v2 : eor #&80 : .v2 : bmi reaches
.rskip
    jmp rnext
.reaches
    \ each of its byte columns that's on the level
    lda #0 : sta u_j
.rcol
    lda BG_C0L,x : clc : adc u_j : sta tmp : lda BG_C0H,x : adc #0 : bne rcol_next
    lda tmp : cmp #80 : bcs rcol_next
    \ tb = ROWBUF + column * 8 - 8R (where level row 0 would be)
    lda #0 : sta u_tb+1
    lda tmp : asl a : rol u_tb+1 : asl a : rol u_tb+1 : asl a : rol u_tb+1
    clc : adc #LO(ROWBUF) : sta u_tb : lda u_tb+1 : adc #HI(ROWBUF) : sta u_tb+1
    lda u_tb : sec : sbc u_bl : sta u_tb : lda u_tb+1 : sbc u_bl+1 : sta u_tb+1
    jsr unroll_item
    ldx u_i
.rcol_next
    inc u_j : lda u_j : cmp BG_WB,x : bne rcol
.rnext
    inc u_i : jmp ritem_loop
.ritems_done
    lda #LO(ROWBUF) : sta u_src : lda #HI(ROWBUF) : sta u_src+1
    lda #80 : sta u_cells
    jsr store_line
    inc u_line : lda u_line : cmp level_rows : beq finish
    jmp row_loop

    \ Now the dictionary is complete, put the lines straight after it in bank 7
.finish
    lda #CACHE_BANK : sta ROMSEL_COPY : sta ROMSEL
    \ start = BG_DICT + pages * &800 (at least one page)
    lda u_cnth : ldx u_cntl : beq whole : clc : adc #1 : .whole
    cmp #0 : bne paged : lda #1
.paged
    pha : sec : sbc #1 : sta pages1 : pla
    asl a : asl a : asl a : clc : adc #HI(BG_DICT) : sta dp+1 : lda #LO(BG_DICT) : sta dp
    \ each line's address: start + its offset; none for lines past the end
    ldx #0
.addr
    lda #0 : sta BG_LO,x : sta BG_HI,x
    cpx u_line : bcs no_line
    lda OFF_LO,x : clc : adc dp : sta BG_LO,x
    lda OFF_HI,x : adc dp+1 : sta BG_HI,x
.no_line
    inx : bne addr
    \ copy them up
    lda #LO(DSTAGE) : sta src : lda #HI(DSTAGE) : sta src+1
.copy
    lda src : cmp po : lda src+1 : sbc po+1 : bcs copied
    ldy #0 : lda (src),y : sta (dp),y
    inc src : bne c1 : inc src+1 : .c1
    inc dp : bne copy : inc dp+1
    jmp copy
.copied
    lda #LEVEL_BANK : sta ROMSEL_COPY : sta ROMSEL
    rts
}

\ Pixels kept from this byte, and those carried in from the byte to its left,
\ when shifting an image right by 0-3 pixels
.keep_tab   EQUB &FF, &77, &33, &11
.carry_tab  EQUB &00, &88, &CC, &EE

\ Plot byte column u_j of background item X into COLBUF
.unroll_item
{
    ldy BG_IMG,x
    lda BG_XL,x : and #3 : sta u_s
    lda #4 : sec : sbc u_s : sta u_s4
    lda img_h,y : sta u_h
    \ cur = the image's column u_j (if it has one), prev = the one before
    lda img_w,y : clc : adc #3 : lsr a : lsr a        \ its byte columns
    ldx #0 : cmp u_j : beq no_cur : bcc no_cur : inx : .no_cur
    stx u_cur
    ldx #0 : lda u_s : beq no_prev : lda u_j : beq no_prev : inx : .no_prev
    stx u_prev
    lda #CACHE_BANK : sta ROMSEL_COPY : sta ROMSEL     \ (shift 0's address is in bank 7)
    lda img_lo0,y : sta dp : lda img_hi0,y : sta dp+1
    lda img_bank0,y : sta u_bank
    lda #LEVEL_BANK : sta ROMSEL_COPY : sta ROMSEL
    ldx u_j : beq at_col
.mul
    lda dp : clc : adc u_h : sta dp : bcc mnc : inc dp+1 : .mnc
    dex : bne mul
.at_col
    lda dp : sec : sbc u_h : sta sp : lda dp+1 : sbc #0 : sta sp+1
    \ its rows [r0, r1) that are in the band [u_bl, u_bh)
    ldx u_i
    lda u_bl : sec : sbc BG_YL,x : sta tmp : lda u_bl+1 : sbc BG_YH,x : bpl r0_pos
    lda #0 : beq r0_ok
.r0_pos
    bne off                                 \ (the band starts 256 or more rows down it)
    lda tmp
.r0_ok
    sta u_r0 : cmp u_h : bcs off
    lda u_bh : sec : sbc BG_YL,x : sta tmp : lda u_bh+1 : sbc BG_YH,x : bmi off
    bne r1_h
    lda tmp : beq off : cmp u_h : bcc r1_ok
.r1_h
    lda u_h
.r1_ok
    sta u_r1 : cmp u_r0 : beq off : bcs rows_ok
.off
    rts
.rows_ok
    \ pt = tb + top, so (pt),Y is level row top + Y in the target
    lda BG_YL,x : clc : adc u_tb : sta pt
    lda BG_YH,x : adc u_tb+1 : sta pt+1
    lda u_bank : sta ROMSEL_COPY : sta ROMSEL
    ldy u_r0
.row
    lda #0 : sta u_b
    lda u_cur : beq no_c
    lda (dp),y
    ldx u_s : beq c_ok
.c_shift
    lsr a : dex : bne c_shift
    ldx u_s : and keep_tab,x
.c_ok
    sta u_b
.no_c
    lda u_prev : beq no_p
    lda (sp),y
    ldx u_s4
.p_shift
    asl a : dex : bne p_shift
    ldx u_s : and carry_tab,x
    ora u_b : sta u_b
.no_p
    lda u_b : beq skip
    tax
    lda (pt),y : and masktab,x : ora identity,x : sta (pt),y
.skip
    iny : cpy u_r1 : bne row
    lda #LEVEL_BANK : sta ROMSEL_COPY : sta ROMSEL
    rts
}

\ At boot: the level pack (loaded at &3000) goes into HAZEL (8KB) and ANDY
\ (4KB less the page the MOS uses), with interrupts off while they're paged
\ in. Nothing uses the disc after this.
.copy_pack
{
    lda #&77 : jsr OSBYTE                   \ close the !BOOT file
    sei
    lda ACCCON : ora #ACCCON_Y : sta ACCCON
    lda #&30 : ldx #&C0 : ldy #&20 : jsr copy_pages
    lda ACCCON : and #&FF - ACCCON_Y : sta ACCCON
    lda ROMSEL_COPY : ora #ROMSEL_ANDY : sta ROMSEL
    lda #&50 : ldx #&80 : ldy #&08 : jsr copy_pages
    lda #&59 : ldx #&89 : ldy #&07 : jsr copy_pages    \ (not &8800-&88FF, which the MOS uses)
    lda ROMSEL_COPY : sta ROMSEL
    cli
    rts
}

\ Copy Y pages from page A to page X
.copy_pages
{
    sta src+1 : stx dp+1
    lda #0 : sta src : sta dp
    tya : tax
    ldy #0
.loop
    lda (src),y : sta (dp),y : iny : bne loop
    inc src+1 : inc dp+1
    dex : bne loop
    rts
}

\ Store line u_line of the background (u_cells cells at u_src, 8 bytes each) at
\ po (which moves on): its 3 masks, then the low byte of each non-empty cell's
\ number in the dictionary
.store_line
{
    ldx u_line : lda po : sec : sbc #LO(DSTAGE) : sta OFF_LO,x
    lda po+1 : sbc #HI(DSTAGE) : sta OFF_HI,x
    ldx #29 : lda #0
.clear
    sta cmask,x : dex : bpl clear
    lda mb : asl a : adc mb : clc : adc po : sta dp : lda po+1 : adc #0 : sta dp+1     \ the numbers
    lda #0 : sta u_x
.cell
    lda u_src : sta pt : lda u_src+1 : sta pt+1
    ldy #7 : lda #0
.any
    ora (pt),y : dey : bpl any
    cmp #0 : beq empty
    jsr dict_find
    ldy #0 : lda u_nl : sta (dp),y
    inc dp : bne nc : inc dp+1 : .nc
    \ set its bits: non-empty, and bits 8 and 9 of its number
    lda u_x : lsr a : lsr a : lsr a : tax
    lda u_x : and #7 : tay : lda bit_of,y : sta tmp
    ora cmask,x : sta cmask,x
    txa : clc : adc mb : tax
    lda u_nh : and #1 : beq b8 : lda tmp : ora cmask,x : sta cmask,x : .b8
    txa : clc : adc mb : tax
    lda u_nh : and #2 : beq empty : lda tmp : ora cmask,x : sta cmask,x
.empty
    lda u_src : clc : adc #8 : sta u_src : bcc nc2 : inc u_src+1 : .nc2
    inc u_x : lda u_x : cmp u_cells : beq all
    jmp cell
.all
    lda mb : asl a : adc mb : tay : dey
.out
    lda cmask,y : sta (po),y : dey : bpl out
    lda dp : sta po : lda dp+1 : sta po+1
    rts
}

.bit_of EQUB &80, &40, &20, &10, &08, &04, &02, &01

\ The number (u_nl, u_nh) of the cell at (pt) in the dictionary, adding it if
\ it's new (the dictionary is in bank 7)
.dict_find
{
    lda #CACHE_BANK : sta ROMSEL_COPY : sta ROMSEL
    \ hash: the sum of its bytes
    ldy #7 : lda #0
.sum
    clc : adc (pt),y : dey : bpl sum
    sta u_h8
    tay : lda HASH_LO,y : sta u_cl : lda HASH_HI,y : sta u_ch
.chain
    lda u_cl : ora u_ch : beq new
    lda u_cl : sec : sbc #1 : sta u_nl : lda u_ch : sbc #0 : sta u_nh
    jsr cell_matches : bcc next
    jmp done                                \ found it
.next
    jsr link_ptr
    ldy #0 : lda (sp),y : sta u_cl
    lda sp+1 : clc : adc #4 : sta sp+1 : lda (sp),y : sta u_ch
    jmp chain
.new
    \ a new cell: the next number
    lda u_cntl : sta u_nl : lda u_cnth : sta u_nh
    inc u_cntl : bne nc : inc u_cnth : .nc
    jsr cell_ptr
    ldy #0 : ldx #8
.store
    lda (pt),y : sta (tblptr),y
    inc pt : bne s1 : inc pt+1 : .s1
    inc tblptr+1
    dex : bne store
    lda pt : sec : sbc #8 : sta pt : bcs s2 : dec pt+1 : .s2
    \ it goes at the front of its hash's chain
    jsr link_ptr
    ldx u_h8 : ldy #0
    lda HASH_LO,x : sta (sp),y
    lda sp+1 : clc : adc #4 : sta sp+1 : lda HASH_HI,x : sta (sp),y
    lda u_nl : clc : adc #1 : sta HASH_LO,x : lda u_nh : adc #0 : sta HASH_HI,x
.done
    lda #LEVEL_BANK : sta ROMSEL_COPY : sta ROMSEL
    rts
}

\ tblptr = line 0 of dictionary cell (u_nl, u_nh); line L is L pages on
.cell_ptr
    lda u_nl : sta tblptr
    lda u_nh : asl a : asl a : asl a : clc : adc #HI(BG_DICT) : sta tblptr+1
    rts

\ Carry set if dictionary cell (u_nl, u_nh) is the same as the one at (pt)
.cell_matches
{
    jsr cell_ptr
    lda pt : sta dp_save : lda pt+1 : sta dp_save+1
    ldy #0 : ldx #8
.loop
    lda (tblptr),y : cmp (pt),y : bne no
    inc pt : bne c1 : inc pt+1 : .c1
    inc tblptr+1
    dex : bne loop
    lda dp_save : sta pt : lda dp_save+1 : sta pt+1
    sec : rts
.no
    lda dp_save : sta pt : lda dp_save+1 : sta pt+1
    clc : rts
}

\ sp = LINK_LO + the cell's number (LINK_HI is 4 pages on)
.link_ptr
    lda u_nl : sta sp : lda u_nh : clc : adc #HI(LINK_LO) : sta sp+1
    rts

\ Where each level is in the pack, and the moving meanies' settings (only the
\ loader needs them, so they're packed with it)
INCLUDE "src/gen/levels.asm"
.overlay_end
PRINT "Loader overlay:", overlay_end - overlay_start, "bytes"
IF PASS = 1
    SAVE "OVERLAY", overlay_start, overlay_end      \ (packed by tools/pack.py for the second pass)
ELSE
    ASSERT OVERLAY_SIZE = overlay_end - overlay_start
    CLEAR &8000, &C000
    ORG OVERLAYZ_ORG
    .overlayz_start
    INCBIN "build/OVERLAY.lz"
    .overlayz_end
    SAVE "LOADERZ", overlayz_start, overlayz_end
    PRINT "Packed loader:", overlayz_end - overlayz_start, "bytes at", ~OVERLAYZ_ORG, "in bank 7"
ENDIF

\ ------------------------------------------------------------------------------
\ The front end: the attract screen and the menus (simplified from the Steam
\ version's 3x3 button grids). It lives in the emptier sprite bank, which is
\ paged in while it runs; it uses only main RAM routines (the plotter, text,
\ the screen) apart from its own.
\ ------------------------------------------------------------------------------

CLEAR &8000, &C000
ORG &8000
GUARD BG_TOP
.front_start

\ A = 0: the attract screen, then the menus; 1: just the menus. Returns A = level.
.fe_main
{
    cmp #0 : bne menus
    \ (at the start: no records yet)
    ldx #NUM_LEVELS - 1
.clear
    lda #&FF : sta rec_best_lo,x : sta rec_best_hi,x
    lda #0 : sta rec_gem,x
    dex : bpl clear
    ldx #0 : lda #&FF
.clear_rates
    sta rec_rate,x : inx : cpx #NUM_LEVELS * 4 : bne clear_rates
    jsr fe_attract
.menus
    jmp fe_menus
}

\ A non-zero if key A (negative INKEY code) is pressed (as key_pressed, in bank 6)
.fe_key
{
    eor #&FF
    sei
    ldx #3 : stx SYSVIA_ORB
    ldx #&7F : stx SYSVIA_DDRA
    sta SYSVIA_ORA
    lda SYSVIA_ORA
    ldx #&0B : stx SYSVIA_ORB
    cli
    asl a : lda #0 : rol a
    rts
}

\ Main RAM's screen, unscrolled and cleared, on show, with background colour A
.fe_screen
{
    pha
    lda #0 : sta back : sta scrollcol : sta scrollrow
    jsr select_back : jsr clear_screen      \ (cleared before it's shown: it may hold the packed front end)
    jsr show_back : jsr set_crtc_start : jsr set_window_clip
    ldx #0
.colours
    lda vdu_colours,x : jsr OSWRCH : inx : cpx #vdu_init_end - vdu_colours : bne colours
    pla : jsr set_bg
    lda #PM_PLOT : sta p_mode
    lda #1 : sta txt_colour                         \ black text
    lda #0 : sta txt_yh
    rts
}

\ ---- The first attract screen ("The Cast", from the Steam version's oDemoBubble).
\ Its layout is the Steam version's 256-pixel-wide screen, centred (32 pixels in).

MACRO CAST_SPRITE img, x, y
    lda #img : sta p_img
    lda #LO(x + 32) : sta p_x : lda #HI(x + 32) : sta p_x+1
    lda #LO(y) : sta p_y : lda #HI(y) : sta p_y+1
    jsr plot
ENDMACRO
MACRO CAST_TEXT x, y, text
    jsr print_inline
    EQUB (x + 32) DIV 4, y
    EQUS text, 0
ENDMACRO
MACRO CAST_CENTRE y, text
    CAST_TEXT 128 - LEN(text) * 4, y, text
ENDMACRO

.fe_attract
{
    lda #TUNE_INTRO : jsr play_music_new
    lda #2 : jsr fe_screen                          \ green, as the Steam start room
    CAST_SPRITE IMG_Frak, 128 - 28, 8 * 3 + 6
    CAST_CENTRE 10 + 8 * 3, "The Cast"
    CAST_CENTRE 10 + 8 * 4, "--------"
    CAST_SPRITE IMG_TroggBody_r, 64, 8 * 10 + 4
    CAST_SPRITE IMG_TroggLegs_r_0, 64, 8 * 10 + 4
    CAST_TEXT 192 - 20, 10 + 8 * 7, "Trogg"
    CAST_CENTRE 10 + 8 * 10, "vs."
    CAST_SPRITE IMG_Scrubbly, 64, 8 * 17
    CAST_TEXT 192 - 32, 10 + 8 * 13, "Scrubbly"
    CAST_SPRITE IMG_Hooter, 64, 8 * 21 - 4
    CAST_TEXT 192 - 24, 10 + 8 * 17 + 4, "Hooter"
    CAST_SPRITE IMG_Poglet, 64, 8 * 25
    CAST_TEXT 192 - 24, 10 + 8 * 22, "Poglet"
    CAST_CENTRE 256 - 10 - 8 * 3, "Collect all the keys to win!"
    CAST_CENTRE 256 - 10 - 8 * 1, "(C) 1984-2026 Nick Pelling"
    jsr fe_release
.wait
    jsr fe_select_key : beq wait
    rts
}

\ ---- Keys

\ A non-zero if Space, Return, P or Y is pressed
.fe_select_key
{
    lda #KEY_SPACE : jsr fe_key : bne yes
    lda #KEY_RETURN : jsr fe_key : bne yes
    lda #KEY_P : jsr fe_key : bne yes
    lda #KEY_Y : jsr fe_key
.yes
    rts
}

\ Wait until none of the menu keys is pressed
.fe_release
{
.wait
    ldx #fe_keys_end - fe_keys - 1
.loop
    stx fe_i
    lda fe_keys,x : jsr fe_key : bne wait
    ldx fe_i : dex : bpl loop
    rts
}
.fe_keys
    EQUB KEY_SPACE, KEY_RETURN, KEY_P, KEY_Y, KEY_ESCAPE
    EQUB KEY_Z, KEY_LEFT, KEY_X, KEY_RIGHT, KEY_O, KEY_UP, KEY_K, KEY_DOWN
.fe_keys_end

\ ---- The menus

.fe_menus
{
.top
    lda #0 : sta fe_kind
    lda fe_top_sel : sta fe_sel
    jsr fe_grid
    lda fe_sel : sta fe_top_sel
    bcs top                                         \ (Escape: stay on the top menu)
    cmp #0 : bne not_replay
    lda last_level : rts                            \ replay the last level
.not_replay
    cmp #1 : bne not_difficulty
    \ the next difficulty: Easy, Hard, Harder, Insane (the Steam version's 1, 2, 4, 6)
    ldx difficulty : lda next_difficulty,x : sta difficulty
    jmp top
.not_difficulty
    cmp #2 : bne a_group
    lda #0 : rts                                    \ Training
.a_group
    sec : sbc #3 : sta fe_group
    lda #1 : sta fe_kind
    lda #0 : sta fe_sel
    jsr fe_grid
    bcs top                                         \ Escape: back to the top menu
    \ level = 1 + group * 9 + button
    lda fe_group : asl a : asl a : asl a : adc fe_group : adc fe_sel : adc #1
    rts
}
.next_difficulty EQUB 1, 2, 4, 4, 6, 6, 1
.fe_tunes EQUB TUNE_SELECT, TUNE_LEVELS

\ A 3x3 grid of buttons (fe_kind: the top menu or a level group), with button
\ fe_sel selected. Moved around with Z X O K (or the cursor keys); returns with
\ carry clear and A = fe_sel when one is chosen, carry set on Escape.
.fe_grid
{
    ldx fe_kind : lda fe_tunes,x : jsr play_music_new   \ (as the Steam version's select and level screens)
    lda #6 : jsr fe_screen                          \ cyan
    lda #8 : sta fe_i
.buttons
    lda fe_i : jsr fe_button
    lda #1 : ldx fe_i : jsr fe_frame
    dec fe_i : bpl buttons
    lda #255 : sta fe_flash
    jsr fe_release
.loop
    \ the selected button's border flashes yellow and magenta
    lda vsyncs : and #16 : beq yellow : lda #2 : bne colour : .yellow : lda #3 : .colour
    cmp fe_flash : beq keys
    sta fe_flash : ldx fe_sel : jsr fe_frame
.keys
    jsr fe_select_key : beq not_select
    lda fe_sel : clc : rts
.not_select
    lda #KEY_ESCAPE : jsr fe_key : beq not_escape
    sec : rts
.not_escape
    lda fe_sel : sta fe_i                           \ the new selection, if it moves
    lda #KEY_Z : jsr fe_key : bne left
    lda #KEY_LEFT : jsr fe_key : beq not_left
.left
    lda fe_i : jsr fe_col : beq loop2 : dec fe_i : jmp moved
.not_left
    lda #KEY_X : jsr fe_key : bne right
    lda #KEY_RIGHT : jsr fe_key : beq not_right
.right
    lda fe_i : jsr fe_col : cmp #2 : beq loop2 : inc fe_i : jmp moved
.not_right
    lda #KEY_O : jsr fe_key : bne up
    lda #KEY_UP : jsr fe_key : beq not_up
.up
    lda fe_i : cmp #3 : bcc loop2 : sbc #3 : sta fe_i : jmp moved
.not_up
    lda #KEY_K : jsr fe_key : bne down
    lda #KEY_DOWN : jsr fe_key : beq loop2
.down
    lda fe_i : cmp #6 : bcs loop2 : adc #3 : sta fe_i
.moved
    lda #1 : ldx fe_sel : jsr fe_frame              \ (the old one back to black)
    lda fe_i : sta fe_sel
    lda #255 : sta fe_flash
    jsr fe_release
.loop2
    jmp loop
}

\ A = A MOD 3 (0-8)
.fe_col
{
    cmp #3 : bcc done : sbc #3 : cmp #3 : bcc done : sbc #3
.done
    cmp #0
    rts
}

\ Set fe_bx, fe_y0 for button A (byte column and top row of its 80x82 box)
.fe_where
{
    pha : jsr fe_col : tax
    lda fe_bx_of,x : sta fe_bx
    pla : ldx #0
.row
    cmp #3 : bcc have_row : sbc #3 : inx : bne row
.have_row
    lda fe_y0_of,x : sta fe_y0
    rts
}
.fe_bx_of EQUB 8, 29, 50                            \ (32 + 84 * column) / 4
.fe_y0_of EQUB 1, 86, 171

\ The border of button X in colour A: 2 pixels wide
.fe_frame
{
    tay : lda fe_pattern,y : sta fe_pat
    txa : jsr fe_where
    \ top and bottom: 2 rows each of 20 bytes
    lda fe_y0 : jsr fe_hrow : lda fe_y0 : clc : adc #1 : jsr fe_hrow
    lda fe_y0 : clc : adc #80 : jsr fe_hrow : lda fe_y0 : clc : adc #81 : jsr fe_hrow
    \ sides: the left 2 pixels of the first byte, the right 2 of the last
    lda #81 : sta fe_n
.side
    lda fe_y0 : clc : adc fe_n : tax
    lda fe_bx : jsr fe_addr
    ldy #0 : lda #&CC : jsr fe_pixels
    ldy #19 * 8 : lda #&33 : jsr fe_pixels
    dec fe_n : bpl side
    rts
}
.fe_pattern EQUB &00, &0F, &F0, &FF                 \ a byte of colour 0-3

\ A row of the current button's border: 20 bytes at row A
.fe_hrow
{
    tax : lda fe_bx : jsr fe_addr
    ldy #0
.loop
    lda #&FF : jsr fe_pixels
    tya : clc : adc #8 : tay : cpy #20 * 8 : bne loop
    rts
}

\ Set pixels A (a mask) of the screen byte at (ptr),Y to fe_pat's colour
.fe_pixels
{
    sta tmp
    eor #&FF : and (ptr),y : sta tmp+1
    lda fe_pat : and tmp : ora tmp+1 : sta (ptr),y
    rts
}

\ ptr = the screen address of byte column A, row X (unscrolled)
.fe_addr
{
    sta tmp : lda #0 : sta tmp+1
    asl tmp : rol tmp+1 : asl tmp : rol tmp+1 : asl tmp : rol tmp+1
    txa : and #7 : clc : adc tmp : sta tmp : bcc nc : inc tmp+1 : .nc
    txa : lsr a : lsr a : lsr a : tax
    lda tmp : clc : adc rowaddr_lo,x : sta ptr
    lda tmp+1 : adc rowaddr_hi,x : sta ptr+1
    rts
}

\ Print the string after the JSR, centred in the current button, at its row + the
\ first byte after the JSR
.fe_title
{
    pla : sta src : pla : sta src+1
    ldy #1 : lda (src),y : clc : adc fe_y0 : sta txt_y
    \ its length
    ldx #0
.len
    iny : lda (src),y : beq got_len : inx : bne len
.got_len
    stx tmp
    lda fe_bx : clc : adc #10 : sec : sbc tmp : sta txt_col
    ldy #1
.loop
    iny : lda (src),y : beq done
    sty txt_i
    jsr print_char
    ldy txt_i
    inc txt_col : inc txt_col
    jmp loop
.done
    tya : clc : adc src : tax : lda src+1 : adc #0 : pha : txa : pha
    rts
}

\ Print level A's name centred in the current button, A + 66 rows down... (row in Y)
.fe_level_name
{
    sty txt_y
    \ src = level_names + level * 10
    sta tmp : lda #0 : sta tmp+1
    asl tmp : rol tmp+1 : lda tmp : sta fe_n : lda tmp+1 : sta fe_n2   \ * 2
    asl tmp : rol tmp+1 : asl tmp : rol tmp+1                        \ * 8
    lda tmp : clc : adc fe_n : sta tmp : lda tmp+1 : adc fe_n2 : sta tmp+1
    lda tmp : clc : adc #LO(level_names) : sta src : lda tmp+1 : adc #HI(level_names) : sta src+1
    ldy #0
.len
    lda (src),y : beq got_len : iny : cpy #9 : bne len
.got_len
    sty tmp
    lda fe_bx : clc : adc #10 : sec : sbc tmp : sta txt_col
    ldy #0
.loop
    lda (src),y : beq done
    sty txt_i
    jsr print_char
    ldy txt_i
    inc txt_col : inc txt_col
    iny : cpy #9 : bne loop
.done
    rts
}

\ Image A at (X, Y) in the current button
.fe_sprite
{
    sta p_img : stx fe_n : sty fe_n2
    lda fe_bx : sta p_x : lda #0 : sta p_x+1
    asl p_x : rol p_x+1 : asl p_x : rol p_x+1
    lda p_x : clc : adc fe_n : sta p_x : bcc nc : inc p_x+1 : .nc
    lda fe_y0 : clc : adc fe_n2 : sta p_y : lda #0 : adc #0 : sta p_y+1
    jmp plot
}
MACRO FE_SPRITE img, dx, dy
    lda #img : ldx #dx : ldy #dy : jsr fe_sprite
ENDMACRO

\ Draw button A's contents
.fe_button
{
    pha : jsr fe_where : pla
    ldx fe_kind : beq top_menu
    jmp fe_level_button
.top_menu
    asl a : tax
    lda top_buttons + 1,x : pha : lda top_buttons,x : pha
    rts                                             \ (to the button's routine)
.top_buttons
    EQUW b_replay - 1, b_difficulty - 1, b_training - 1, b_classic - 1, b_moving - 1
    EQUW b_vertical - 1, b_sliding - 1, b_placing - 1, b_bouncing - 1

.b_replay
    jsr fe_title : EQUB 6 : EQUS "Replay", 0
    lda fe_y0 : clc : adc #38 : tay : lda last_level
    jmp fe_level_name
.b_difficulty
    jsr fe_title : EQUB 6 : EQUS "Difficulty", 0
    \ a balloon for each level of difficulty, and its name
    ldx difficulty : lda diff_balloons,x : sta fe_i2
.balloons
    lda fe_i2 : beq named
    asl a : asl a : asl a : asl a : adc #2 : tax    \ x = 2 + 16 * n
    lda #IMG_Balloon : ldy #44 : jsr fe_sprite
    dec fe_i2 : jmp balloons
.named
    ldx difficulty : lda diff_name_lo,x : sta src : lda diff_name_hi,x : sta src+1
    jmp fe_print_centred
.b_training
    jsr fe_title : EQUB 6 : EQUS "Training", 0
    FE_SPRITE IMG_TroggBody_r, 40, 62
    FE_SPRITE IMG_TroggLegs_r_0, 40, 62
    rts
.b_classic
    jsr fe_title : EQUB 6 : EQUS "Classic", 0
    FE_SPRITE IMG_TroggBody_l, 40, 62
    FE_SPRITE IMG_TroggLegs_l_1, 40, 62
    rts
.b_moving
    jsr fe_title : EQUB 6 : EQUS "Moving", 0
    FE_SPRITE IMG_Scrubbly, 40, 66
    rts
.b_vertical
    jsr fe_title : EQUB 6 : EQUS "Vertical", 0
    FE_SPRITE IMG_Poglet, 40, 66
    rts
.b_sliding
    jsr fe_title : EQUB 6 : EQUS "Sliding", 0
    FE_SPRITE IMG_Log1, 8, 66
    FE_SPRITE IMG_Hooter, 40, 66
    rts
.b_placing
    jsr fe_title : EQUB 6 : EQUS "Placing", 0
    FE_SPRITE IMG_Girder3, 22, 48
    FE_SPRITE IMG_Girder3, 22, 66
    rts
.b_bouncing
    jsr fe_title : EQUB 6 : EQUS "Bouncing", 0
    FE_SPRITE IMG_Spring, 40, 66
    rts
}

\ Print the string at (src) centred in the current button, 50 rows down
.fe_print_centred
{
    ldy #0
.len
    lda (src),y : beq got_len : iny : bne len
.got_len
    sty tmp
    lda fe_bx : clc : adc #10 : sec : sbc tmp : sta txt_col
    lda fe_y0 : clc : adc #64 : sta txt_y
    ldy #0
.loop
    lda (src),y : beq done
    sty txt_i
    jsr print_char
    ldy txt_i
    inc txt_col : inc txt_col
    iny : bne loop
.done
    rts
}
.diff_balloons EQUB 0, 1, 2, 2, 3, 3, 4
.diff_name_lo EQUB LO(n_none), LO(n_easy), LO(n_hard), LO(n_hard), LO(n_harder), LO(n_harder), LO(n_insane)
.diff_name_hi EQUB HI(n_none), HI(n_easy), HI(n_hard), HI(n_hard), HI(n_harder), HI(n_harder), HI(n_insane)
.n_none   EQUS "None", 0
.n_easy   EQUS "Easy", 0
.n_hard   EQUS "Hard", 0
.n_harder EQUS "Harder", 0
.n_insane EQUS "Insane", 0

\ A level button: the column's meanie on its platform (as in the Steam version:
\ Scrubbly, Poglet, Hooter), and the level's name
.fe_level_button
{
    sta fe_i2
    jsr fe_col : beq scrubbly : cmp #1 : beq poglet
    FE_SPRITE IMG_Girder3, 7, 52
    FE_SPRITE IMG_Hooter, 23, 52
    jmp name
.scrubbly
    FE_SPRITE IMG_Ledge2, 7, 52
    FE_SPRITE IMG_Scrubbly, 23, 52
    jmp name
.poglet
    FE_SPRITE IMG_Log5, 7, 52
    FE_SPRITE IMG_Poglet, 23, 52
.name
    \ level = 1 + group * 9 + button
    lda fe_group : asl a : asl a : asl a : adc fe_group : adc fe_i2 : adc #1
    sta fe_lev
    pha : lda fe_y0 : clc : adc #70 : tay : pla
    jsr fe_level_name
    \ its "good" time at the top right, and the best so far below it
    ldx fe_lev
    lda level_good_lo,x : sta tmp : lda level_good_hi,x : sta tmp+1
    lda #7 : jsr fe_time_at
    ldx fe_lev
    lda rec_best_hi,x : cmp #&FF : beq no_best
    sta tmp+1 : lda rec_best_lo,x : sta tmp
    lda #43 : jsr fe_time_at
.no_best
    \ the medals: rating (for this difficulty), gems, speed
    jsr fe_rate_index
    lda rec_rate,y : cmp #3 : bcc rated : cmp #&FF : beq unrated : lda #3 : bne rated
.unrated
    lda #5
.rated
    asl a : tax
    lda fe_rating_icons,x : sta src : lda fe_rating_icons + 1,x : sta src+1
    lda #11 : jsr fe_icon_at
    ldx fe_lev : lda rec_gem,x : beq outline
    lda #LO(icon_Gem_Small) : ldy #HI(icon_Gem_Small) : jmp gem
.outline
    lda #LO(icon_Gem_Outline_Small) : ldy #HI(icon_Gem_Outline_Small)
.gem
    sta src : sty src+1
    lda #14 : jsr fe_icon_at
    \ the stopwatch: if the best time beats the good one
    lda #LO(icon_Stopwatch_Outline_Small) : sta src : lda #HI(icon_Stopwatch_Outline_Small) : sta src+1
    ldx fe_lev
    lda rec_best_lo,x : cmp level_good_lo,x : lda rec_best_hi,x : sbc level_good_hi,x : bcs slow
    lda #LO(icon_Stopwatch_Small) : sta src : lda #HI(icon_Stopwatch_Small) : sta src+1
.slow
    lda #17
    \ (falls through)
}

\ Draw the icon at (src) at byte column A of the current button, 62 rows down
.fe_icon_at
{
    clc : adc fe_bx : sta fe_n
    lda fe_y0 : clc : adc #62 : sta fe_n2
    ldy #0 : lda (src),y : sta fe_iw : iny : lda (src),y : sta fe_ih
    lda src : clc : adc #2 : sta src : bcc nc : inc src+1 : .nc
.col
    lda #0 : sta fe_r
.row
    lda fe_n2 : clc : adc fe_r : tax : lda fe_n : jsr fe_addr
    ldy #0 : lda (src),y : beq clear : tax
    lda (ptr),y : and masktab,x : ora identity,x : sta (ptr),y
.clear
    inc src : bne nc2 : inc src+1 : .nc2
    inc fe_r : lda fe_r : cmp fe_ih : bne row
    inc fe_n : dec fe_iw : bne col
    rts
}
.fe_rating_icons
    EQUW icon_Rating_1_Small, icon_Rating_2_Small, icon_Rating_3_Small, icon_Rating_Tick_Small
    EQUW icon_Rating_None_Small, icon_Stopwatch_Outline_Small


\ Print the time tmp (game ticks) as m:ss, at byte column 11 of the current
\ button, A rows down
.fe_time_at
{
    clc : adc fe_y0 : sta txt_y
    lda fe_bx : clc : adc #11 : sta txt_col
    lda #50 : jsr fe_div16                          \ seconds
    lda tmp+1 : bne cap : lda tmp : cmp #LO(600) : lda tmp+1 : sbc #HI(600) : bcc ok
.cap
    lda #LO(599) : sta tmp : lda #HI(599) : sta tmp+1
.ok
    lda #60 : jsr fe_div16 : sta fe_r               \ tmp = minutes, A = seconds
    lda tmp : ora #'0' : jsr fe_char
    lda #':' : jsr fe_char
    lda fe_r : ldx #'0' - 1
.tens
    inx : sec : sbc #10 : bcs tens
    adc #10 + '0' : pha : txa : jsr fe_char
    pla
    \ (falls through)
}
\ Print character A at txt_col, txt_y, and move on
.fe_char
{
    jsr print_char
    inc txt_col : inc txt_col
    rts
}

\ tmp (16-bit) = tmp / A, remainder in A
.fe_div16
{
    sta fe_d : lda #0 : ldx #16
.loop
    asl tmp : rol tmp+1 : rol a
    cmp fe_d : bcc no : sbc fe_d : inc tmp : .no
    dex : bne loop
    rts
}

INCLUDE "src/gen/names.asm"
.front_end_
IF PASS = 1
    SAVE "FRONT", front_start, front_end_   \ (packed by tools/pack.py for the second pass)
ENDIF
.fe_d       SKIP 1
.fe_r       SKIP 1
.fe_iw      SKIP 1
.fe_ih      SKIP 1
.fe_vars_end
PRINT "Front end:", front_end_ - front_start, "bytes, unpacked to &8000 in bank", CACHE_BANK, "(", BG_TOP - fe_vars_end, "bytes to spare )"

\ ---- Where shift 3 of each image is (bank and address; shifts 0-2 are in bank
\ 7). plot pages DIR_BANK in to read it. Just below the save area in the
\ emptier sprite bank.
CLEAR &8000, &C000
ORG IMGDIR_ORG
GUARD SLOWSAVE0_START
.imgdir_start
INCLUDE "src/gen/imgdir3.asm"
.imgdir_end
SAVE "IMGDIR", imgdir_start, imgdir_end
ASSERT imgdir_end = SLOWSAVE0_START

\ ---- The packed front end, at the top of the emptier sprite bank (below the
\ save area), and the routine that copies it to the screen for fe_unpack
IF PASS = 2
ASSERT FRONT_SIZE = front_end_ - front_start    \ (the first pass assembled the same front end)
CLEAR &8000, &C000
ORG FRONTZ_ORG
GUARD IMGDIR_ORG
.frontz_start
.front_packed
    INCBIN "build/FRONT.lz"
\ Copy it to SCREEN in the screen buffer that isn't on show
.fe_stage
{
    lda ACCCON : and #&FB : sta tmp
    and #1 : eor #1 : asl a : asl a : ora tmp : sta ACCCON
    lda #LO(front_packed) : sta src : lda #HI(front_packed) : sta src+1
    lda #0 : sta dp : lda #HI(SCREEN) : sta dp+1
    ldx #(FRONTZ_SIZE + 255) DIV 256 : ldy #0
.copy
    lda (src),y : sta (dp),y : iny : bne copy
    inc src+1 : inc dp+1 : dex : bne copy
    rts
}
.frontz_end
SAVE "FRONTZ", frontz_start, frontz_end
ASSERT FRONTZ_ORG >= SPRITES_END
PRINT "Packed front end:", frontz_end - frontz_start, "bytes at", ~FRONTZ_ORG, "in bank", FRONT_BANK, "(", FRONTZ_ORG - SPRITES_END, "bytes free below it )"
ELSE
fe_stage = &8000                    \ (a dummy for the first pass)
ENDIF

\ ---- The music and sound effects player and its data, after the sprites in the
\ emptier sprite bank (see src/sound.asm)
MUSIC_BANK = DIR_BANK
CLEAR &8000, &C000
ORG SPRITES_END
GUARD FRONTZ_ORG
.music_start
INCLUDE "src/sound.asm"
.music_end
SAVE "MUSIC", music_start, music_end
PRINT "Music:", music_end - music_start, "bytes at", ~SPRITES_END, "in bank", MUSIC_BANK, "(", FRONTZ_ORG - music_end, "bytes free after it )"

INCLUDE "src/gen/disc.asm"

PRINT "Code from", ~code_start, "to", ~end, "(", end - code_start, "bytes ), free:", SCREEN - ram_top
\ Addresses used by test scripts (profiling and poking variables)
PRINT "TIMING", ~main_loop, ~t_restore, ~t_scroll, ~t_draw, ~t_vsync, ~t_after_vsync, ~t_logic, ~t_logic_done, ~t_slow, ~t_slow_done
PRINT "SYMBOLS loops", ~loops, "trogg_standing", ~trogg_standing, "trogg_falling", ~trogg_falling, "trogg_climbing", ~trogg_climbing, "xmove", ~xmove, "ymove", ~ymove, "xvel", ~xvel, "tyf", ~tyf, "res_i", ~res_i, "res_found", ~res_found, "res_y", ~res_y, "res_yf", ~res_yf, "doyoyo", ~doyoyo, "tclimb", ~tclimb, "x_max", ~x_max, "level_h", ~level_h, "snd_tune", ~snd_tune, "snd_qb", ~snd_qb, "v_phase", ~v_phase, "v_left", ~v_left, "v_ord", ~v_ord, "v_on", ~v_on, "v_att", ~v_att, "snd_music_req", ~snd_music_req, "snd_cur", ~snd_cur, "snd_music_opt", ~snd_music_opt, "snd_sfx_opt", ~snd_sfx_opt, "snd_acc", ~snd_acc, "draw_kind", ~draw_kind, "num_keys", ~num_keys, "lvl_ticks", ~lvl_ticks, "done_valid", ~done_valid, "fe_sel", ~fe_sel, "cur_level", ~cur_level, "num_plats", ~num_plats, "num_ladders", ~num_ladders, "num_draw", ~num_draw, "num_slow", ~num_slow, "plat_w", ~plat_w, "plat_x0l", ~plat_x0l, "plat_x0h", ~plat_x0h, "plat_y0l", ~plat_y0l, "plat_y0h", ~plat_y0h, "plat_moving", ~plat_moving, "plat_bouncy", ~plat_bouncy, "lad_xl", ~lad_xl, "lad_xh", ~lad_xh, "lad_yl", ~lad_yl, "lad_yh", ~lad_yh, "lad_hl", ~lad_hl, "lad_hh", ~lad_hh, "lad_ext", ~lad_ext, "lad_half", ~lad_half, "draw_img", ~draw_img, "draw_xl", ~draw_xl, "draw_xh", ~draw_xh, "draw_yl", ~draw_yl, "draw_yh", ~draw_yh, "sl_kind", ~sl_kind, "sl_img", ~sl_img, "sl_x0l", ~sl_x0l, "sl_x0h", ~sl_x0h, "sl_y0l", ~sl_y0l, "sl_y0h", ~sl_y0h, "sl_aminl", ~sl_aminl, "sl_aminh", ~sl_aminh, "sl_amaxl", ~sl_amaxl, "sl_amaxh", ~sl_amaxh, "sl_bminl", ~sl_bminl, "sl_bminh", ~sl_bminh, "sl_bmaxl", ~sl_bmaxl, "sl_bmaxh", ~sl_bmaxh, "sl_vf", ~sl_vf, "sl_vi", ~sl_vi, "sl_vy", ~sl_vy, "sl_plat", ~sl_plat, "sl_wait", ~sl_wait, "sl_simple", ~sl_simple, "plat_yh", ~plat_yh, "level_bg", ~level_bg, "trogg_x0", ~trogg_x0, "trogg_y0", ~trogg_y0, "dmg_n", ~dmg_n, "s_alive", ~s_alive, "s_xl", ~s_xl, "s_xh", ~s_xh, "s_yl", ~s_yl, "s_yh", ~s_yh, "cur_plat", ~cur_plat, "plat_xl", ~plat_xl, "plat_xh", ~plat_xh, "plat_yl", ~plat_yl, "mv_img", ~mv_img, "mv_vxi", ~mv_vxi, "mv_vyi", ~mv_vyi, "mv_vyf", ~mv_vyf, "mv_yl", ~mv_yl, "mv_yh", ~mv_yh, "mv_pause", ~mv_pause, "bal_timer", ~bal_timer, "dag_timer", ~dag_timer, "bscroll", ~bscroll, "front", ~front, "vsyncs", ~vsyncs, "yo_len", ~yo_len, "mv_active", ~mv_active, "mv_xl", ~mv_xl, "mv_xh", ~mv_xh, "tface", ~tface, "keys_found", ~keys_found, "gems_found", ~gems_found, "won", ~won, "have_cp", ~have_cp, "restarts", ~restarts, "alive", ~alive, "newcol", ~newcol, "dead", ~dead, "tx", ~tx, "ty", ~ty, "tstate", ~tstate, "tv", ~tv, "dead", ~dead, "anim", ~anim, "p_img", ~p_img, "bank", ~bank, "oldbank", ~oldbank, "dptr", ~dptr, "scrollcol", ~scrollcol
