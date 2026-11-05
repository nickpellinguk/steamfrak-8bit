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
SCREEN_COLS = 80            \ byte columns visible across the screen (320 pixels)
WINDOW_W    = 320           \ visible width in level pixels

\ Frame rate: the screen is redrawn at 25 frames a second, and the game logic
\ runs one tick per vertical sync (50 a second): normally two per drawn frame.
FRAMES_PER_DRAW = 2             \ vertical syncs (1/50 s) per drawn frame
MAX_TICKS_PER_FRAME = 4         \ game logic runs one tick per vertical sync, up to this many per frame

MAX_LOG = 16                    \ draw-log entries per screen buffer
MAX_MOVERS = 12                 \ moving objects: balloons, daggers, meanies flying off

\ Save areas: 1KB per screen buffer for the backgrounds under moving things,
\ Part is kept for Trogg (8 columns of 34 rows), the yoyo (3 x 6) and its
\ string, plus the FRAK! bubble (14 x 19) when he's dead; the rest is for
\ balloons, daggers and meanies. Each sprite's save record has a 6-byte header
\ and a 2-byte screen address per column.
SAVE_SIZE = 1024
SAVE_RESERVE_ALIVE = 6 + 8 * 36 + 6 + 3 * 8 + 24
SAVE_RESERVE_DEAD = SAVE_RESERVE_ALIVE + 6 + 14 * 21

\ DIFFICULTY is set by build.sh (DIFFICULTY=n ./build.sh), as in the Steam version:
\ 0 = no balloons or daggers, 1 = Easy, 2 = Hard, 4 = Harder, 6 = Insane
\ (3 and 5 are the upside-down versions of 2 and 4, not done yet)
ASSERT DIFFICULTY >= 0 AND DIFFICULTY <= 6

\ Trogg states
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
.mask       SKIP 4          \ non-empty cells of a cached column
.pt         SKIP 2
.po         SKIP 2
.vsyncs     SKIP 1          \ incremented by the vertical sync event
.last_flip  SKIP 1          \ vsyncs at the last buffer flip
.firsty     SKIP 2
.bank       SKIP 1
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
.mv_i       SKIP 1
.bal_timer  SKIP 1          \ ticks until the next balloon
.dag_timer  SKIP 1          \ ticks until the next dagger
.rng        SKIP 2          \ random number generator state
.sp_slot    SKIP 1          \ spawning workspace
.sp_mid     SKIP 2
.sp_x       SKIP 2
.mul_a      SKIP 1
.mul_b      SKIP 1
.mul_lo     SKIP 1
.mvc_i      SKIP 1          \ mover collision loop
.view_l     SKIP 2          \ left edge of the window - 64, in level pixels
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
.lad_top    SKIP 2
.lad_len    SKIP 2
.tx         SKIP 2
.ty         SKIP 2
.tstate     SKIP 1
.tface      SKIP 1          \ 0 = right, 1 = left
.tclimb     SKIP 1          \ 0 = still, 1 = up, 2 = down
.xvel       SKIP 1          \ signed
.fallt      SKIP 1          \ index into fall_dy / fall_flags
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
.dy         SKIP 1
.fflags     SKIP 1


MAX_OBJECTS = 64
ASSERT NUM_DRAW <= MAX_OBJECTS
ASSERT MAX_LOG = 16                 \ (log_slot and restore_log multiply by 16)
.alive      SKIP MAX_OBJECTS        \ 1 = object not yet collected
.cp_alive   SKIP MAX_OBJECTS        \ checkpoint copy
.cp_tx      SKIP 2
.cp_ty      SKIP 2
.cp_face    SKIP 1
.cp_keys    SKIP 1
.cp_gems    SKIP 1
.cp_bal     SKIP 1
.cp_dag     SKIP 1
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

.start
{
    \ Disable Escape, set up MODE 1 with no cursor
    lda #229 : ldx #1 : ldy #0 : jsr OSBYTE
    ldx #0
.vdu_loop
    lda vdu_init,x : jsr OSWRCH
    inx : cpx #vdu_init_end - vdu_init : bne vdu_loop
    \ The level data lives in sideways RAM bank 6 and stays paged in while the
    \ game runs (routines that page in other banks put it back afterwards)
    lda #LEVEL_BANK : sta ROMSEL_COPY : sta ROMSEL
    jsr install_vsync_counter
}

\ Double buffering: the screen is drawn in whichever of main RAM (buffer 0) and
\ the Master's shadow RAM (buffer 1) is not being displayed, then the two are
\ swapped at vertical sync. Each buffer keeps its own scroll position and its
\ own copy of the background saved under Trogg.

\ Start (or restart) the level from scratch
.level_start
{
    ldx #NUM_DRAW - 1
    lda #1
.objs
    sta alive,x : dex : bpl objs
    lda #0 : sta keys_found : sta gems_found : sta have_cp : sta save_cp : sta restarts
    sta bal_timer : sta dag_timer
    lda vsyncs : ora #1 : sta rng : lda #&5A : sta rng+1
    lda #LO(TROGG_START_X) : sta tx : lda #HI(TROGG_START_X) : sta tx+1
    lda #LO(TROGG_START_Y) : sta ty : lda #HI(TROGG_START_Y) : sta ty+1
    lda #0 : sta tface
    jmp redraw_all
}

\ Go back to the last checkpoint (the state saved after collecting a key)
.restore_checkpoint
{
    inc restarts
    ldx #NUM_DRAW - 1
.objs
    lda cp_alive,x : sta alive,x : dex : bpl objs
    lda cp_keys : sta keys_found
    lda cp_gems : sta gems_found
    lda cp_tx : sta tx : lda cp_tx+1 : sta tx+1
    lda cp_ty : sta ty : lda cp_ty+1 : sta ty+1
    lda cp_face : sta tface
    lda cp_bal : sta bal_timer : lda cp_dag : sta dag_timer
    lda #0 : sta save_cp
}
    \ fall through

\ Reset Trogg's movement state and redraw both screen buffers from scratch
.redraw_all
{
    lda #ST_STAND : sta tstate
    lda #0 : sta tclimb : sta xvel : sta anim : sta dead : sta won
    sta ud_db : sta lr_db : sta yo_db : sta yo_len : sta yo_len+1
    jsr set_palette
    \ No moving objects (e.g. meanies flying off after being yoyoed)
    ldx #MAX_MOVERS - 1
    lda #0
.movers
    sta mv_active,x : dex : bpl movers

    jsr calc_scroll
    ldx #1
.init_buffer
    stx back
    jsr select_back
    lda newcol : sta scrollcol
    lda #SCREEN_COLS - 1 : sta initcol
.init_col
    lda scrollcol : clc : adc initcol
    jsr repaint_column
    dec initcol : bpl init_col
    ldx back
    lda newcol : sta bscroll,x
    lda #0 : sta log_n,x : sta bfrak,x : sta pend_hi,x
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
    jsr set_window_clip

    \ Once Trogg is dead and this buffer already shows the FRAK! bubble, nothing
    \ changes until the restart, so don't redraw
    lda dead : beq redraw
    lda bfrak,x : beq redraw
    jmp show
.redraw
.^t_restore
    jsr restore_log

.^t_scroll
    jsr do_scroll
    ldx back
    lda scrollcol : sta bscroll,x
    jsr do_pending

.^t_draw
    ldx back
    lda savebuf_lo,x : sta sfree : lda savebuf_hi,x : sta sfree+1
    lda savebuf_end_lo,x : sta send : lda savebuf_end_hi,x : sta send+1

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
    jsr log_sprite
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

    \ Trogg
    jsr trogg_image : sta p_img
    lda tx : sta p_x : lda tx+1 : sta p_x+1
    lda ty : sta p_y : lda ty+1 : sta p_y+1
    jsr log_sprite

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
    cmp #TICK_WON : beq from_scratch
    lda have_cp : beq from_scratch          \ TICK_DIED: restart
    jmp restore_checkpoint
.from_scratch
    jmp level_start
.next_tick
    dec ticks_left : bne tick
    jmp main_loop
}

\ One tick of game logic. Returns A (and Z) = TICK_OK, TICK_DIED or TICK_WON.
TICK_OK = 0
TICK_DIED = 1
TICK_WON = 2
.game_tick
{
    lda dead : beq alive
    dec dead : beq died
    lda #TICK_OK : rts
.died
    lda #TICK_DIED : rts
.alive
    lda won : beq playing
    jsr win_tick : bcs finished
    lda #TICK_OK : rts
.finished
    lda #TICK_WON : rts
.playing
    jsr read_keys
    jsr trogg_update
    jsr spawn_hazards
    jsr update_movers
    lda dead : bne done
    jsr check_collisions
    jsr check_checkpoint
.done
    lda #TICK_OK : rts
}

\ Count vertical syncs (MOS event 4) so the main loop can pace itself
EVNTV = &0220
.vsync_event
{
    php
    cmp #4 : bne chain
    inc vsyncs
.chain
    plp
.^old_evntv
    jmp &FFFF                       \ (operand set to the previous EVNTV)
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
    lda back : asl a : asl a : asl a : asl a
    ldx back : clc : adc log_n,x
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

\ Erase everything logged in the back buffer, most recent first
.restore_log
{
    ldx back
    lda log_n,x : beq done
.loop
    ldx back : dec log_n,x
    lda back : asl a : asl a : asl a : asl a : clc : adc log_n,x : tax
    lda log_img,x : sta p_img
    lda log_xl,x : sta p_x : lda log_xh,x : sta p_x+1
    lda log_yl,x : sta p_y : lda log_yh,x : sta p_y+1
    lda log_x1l,x : sta q_x : lda log_x1h,x : sta q_x+1
    lda log_sbl,x : sta sbase : lda log_sbh,x : sta sbase+1
    lda #PM_RESTORE : sta p_mode
    lda log_kind,x : bne line
    jsr restore_saved
    jmp next
.line
    jsr hline
.next
    ldx back : lda log_n,x : bne loop
.done
    rts
}

\ ------------------------------------------------------------------------------
\ hline: a 1-pixel black line from (p_x, p_y) to (q_x, p_y), inclusive.
\ PM_SAVE draws it saving the background at sbase; PM_RESTORE puts it back.
\ Clipped to the visible window and to the level's 256 rows.
\ ------------------------------------------------------------------------------

.hline
{
    lda sbase : sta sptr : lda sbase+1 : sta sptr+1
    \ Only rows 0-255
    lda p_y+1 : beq row_ok
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
    lda p_y : lsr a : lsr a : lsr a : sta hl_row
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
    sec
    lda tx : sbc #LO(WINDOW_W/2) : sta tmp
    lda tx+1 : sbc #HI(WINDOW_W/2) : sta tmp+1
    bpl not_neg
    lda #0 : sta tmp : sta tmp+1
.not_neg
    lda tmp : cmp #LO(LEVEL_W - WINDOW_W)
    lda tmp+1 : sbc #HI(LEVEL_W - WINDOW_W)
    bcc in_range
    lda #LO(LEVEL_W - WINDOW_W) : sta tmp
    lda #HI(LEVEL_W - WINDOW_W) : sta tmp+1
.in_range
    lsr tmp+1 : ror tmp
    lsr tmp+1 : ror tmp
    lda tmp : sta newcol
    rts
}

.do_scroll
{
    jsr calc_scroll
.loop
    lda scrollcol : cmp newcol
    beq done
    bcs go_left
    \ Scroll right: expose the column at the right-hand edge
    inc scrollcol
    lda scrollcol : clc : adc #SCREEN_COLS - 1
    jsr repaint_column
    jmp loop
.go_left
    dec scrollcol
    lda scrollcol
    jsr repaint_column
    jmp loop
.done
    rts
}

.set_crtc_start
{
    \ start = (&3000 / 8) + scrollcol
    lda #13 : sta CRTC_REG
    lda scrollcol : clc : adc #LO(SCREEN DIV 8) : sta CRTC_DATA
    lda #12 : sta CRTC_REG
    lda #HI(SCREEN DIV 8) : adc #0 : sta CRTC_DATA
    rts
}

.set_window_clip
{
    lda scrollcol : sta clip_l
    clc : adc #SCREEN_COLS : sta clip_r
    rts
}

\ Repaint one byte column (A = level byte column): copy the pre-rendered
\ platforms and ladders from the background cache in sideways RAM bank 7,
\ then draw any keys, gems and meanies that overlap it.
CACHE_LO = &8000                    \ column address tables in the cache bank
CACHE_HI = &8100

.repaint_column
{
    sta colw
    sta clip_l
    clc : adc #1 : sta clip_r
    \ ptr = address of the column at row 0
    lda #0 : sta tmp+1
    lda colw : asl a : rol tmp+1 : asl a : rol tmp+1 : asl a : rol tmp+1
    clc : adc #LO(SCREEN) : sta ptr
    lda tmp+1 : adc #HI(SCREEN) : sta ptr+1
    cmp #&80 : bcc ok : sbc #&50 : sta ptr+1
.ok
    lda ROMSEL_COPY : pha
    lda #CACHE_BANK : sta ROMSEL_COPY : sta ROMSEL
    ldx colw
    lda CACHE_LO,x : sta src : lda CACHE_HI,x : sta src+1
    \ 32-bit mask of non-empty character cells, top cell first
    ldy #0 : lda (src),y : sta mask
    iny : lda (src),y : sta mask+1
    iny : lda (src),y : sta mask+2
    iny : lda (src),y : sta mask+3
    lda src : clc : adc #4 : sta src : bcc nc : inc src+1 : .nc
    ldx #32
.cell
    asl mask+3 : rol mask+2 : rol mask+1 : rol mask
    bcc empty
    ldy #7
.copy
    lda (src),y : sta (ptr),y : dey : bpl copy
    lda src : clc : adc #8 : sta src : bcc next : inc src+1
    jmp next
.empty
    lda #0 : ldy #7
.clear
    sta (ptr),y : dey : bpl clear
.next
    lda ptr : clc : adc #LO(640) : sta ptr
    lda ptr+1 : adc #HI(640) : cmp #&80 : bcc nw : sbc #&50 : .nw : sta ptr+1
    dex : bne cell
    pla : sta ROMSEL_COPY : sta ROMSEL
    jsr draw_scenery
    jmp set_window_clip
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
    lda draw_img,x : sta p_img
    lda draw_xl,x : sta p_x : lda draw_xh,x : sta p_x+1
    lda draw_yl,x : sta p_y : lda draw_yh,x : sta p_y+1
    txa : pha
    jsr plot
    pla : tax
.skip
    inx : cpx #NUM_DRAW : bne loop
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
    \ When saving, the save area starts with a record header (see restore_saved):
    \ column count (0 until we know better), y0, cells, first_end, last_end, rows
    lda p_mode : cmp #PM_SAVE : bne no_header
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

    \ Rows: clip to 0..255 (the level is 256 high)
    lda #0 : sta r0
    lda hgt : sta rows
    lda top+1 : beq top_ok
    bpl nothing                     \ top >= 256: off the bottom
    \ top < 0: skip -top rows
    lda #0 : sec : sbc top : sta r0
    lda hgt : sec : sbc r0 : bcc nothing : beq nothing : sta rows
    lda #0 : sta firsty : sta firsty+1
    jmp rows_done
.nothing
    rts
.top_ok
    lda top : sta firsty : lda #0 : sta firsty+1
    \ rows = min(hgt, 256 - top)
    lda #0 : sec : sbc top          \ 256 - top (as a byte; top = 0 gives 0 = 256)
    beq rows_done
    cmp rows : bcs rows_done
    sta rows
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
    rts
.some

    \ Sprite data address and bank for this shift
    ldy shift
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

    \ Page in the sprite bank
    lda ROMSEL_COPY : sta oldbank
    lda bank : sta ROMSEL_COPY : sta ROMSEL

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
    lda p_mode : cmp #PM_SAVE : bne no_layout
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
    lda p_mode : cmp #PM_SAVE : bne do_col
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

    lda oldbank : sta ROMSEL_COPY : sta ROMSEL
    rts
}

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

.col_routines_lo EQUB LO(col_plot), LO(col_save), LO(col_restore)
.col_routines_hi EQUB HI(col_plot), HI(col_save), HI(col_restore)

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
    lda #LEVEL_BG
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
.loop
    lda pc_col : cmp pc_end : bcs none
    jsr repaint_column
    inc pc_col
    jmp loop
.none
    rts
}

\ Level complete: flash the background, then start again. Carry set when done.
WIN_FRAMES = 150                    \ (game ticks)
.win_tick
{
    dec won : beq finished
    lda won : and #7 : bne not_yet
    lda won : and #8 : beq bg
    lda #7 : jsr set_bg                 \ white
    clc : rts
.bg
    jsr set_palette
.not_yet
    clc : rts
.finished
    jsr set_palette
    sec : rts
}

\ ------------------------------------------------------------------------------
\ Keyboard
\ ------------------------------------------------------------------------------

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
\ Data
\ ------------------------------------------------------------------------------

INCLUDE "src/gen/tables.asm"
INCLUDE "src/gen/sprites.asm"

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

\ Per-buffer state (not saved to disc)
.bscroll    SKIP 2
.bfrak      SKIP 2          \ FRAK! bubble drawn in this buffer
.pend_lo    SKIP 2          \ columns waiting to be repainted, per buffer
.pend_hi    SKIP 2
.ram_top

SAVE "FRAK", start, end, start

\ ------------------------------------------------------------------------------
\ Game logic, in sideways RAM bank 6 (&A000-&BFFF)
\
\ Bank 6 is paged in whenever the game logic runs, so the logic can live there,
\ leaving main RAM for the drawing code (which pages the sprite banks in).
\ ------------------------------------------------------------------------------

LOGIC_CODE = &A000
CLEAR &8000, &C000
ORG LOGIC_CODE
GUARD &C000
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
    lda mv_yl,x : cmp #LO(LEVEL_H) : lda mv_yh,x : sbc #HI(LEVEL_H)
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
.diff_spread_h      DIFF_TABLE 0, HI(270), HI(280), HI(280), HI(290), HI(290), HI(300)

\ Called once per tick while Trogg is alive
.spawn_hazards
{
    ldx #DIFFICULTY
    lda diff_balloon_time,x : beq no_balloons
    lda bal_timer : beq spawn_b
    dec bal_timer : bne no_balloons
.spawn_b
    jsr spawn_balloon
    ldx #DIFFICULTY
    lda diff_balloon_time,x : sta bal_timer
.no_balloons
    ldx #DIFFICULTY
    lda diff_dagger_time,x : beq no_daggers
    lda dag_timer : beq spawn_d
    dec dag_timer : bne no_daggers
.spawn_d
    jsr spawn_dagger
    ldx #DIFFICULTY
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
    jsr random_x
    ldy sp_slot : ldx #DIFFICULTY
    lda #MV_BALLOON : sta mv_active,y
    lda #IMG_Balloon : sta mv_img,y
    lda sp_x : sta mv_xl,y : lda sp_x+1 : sta mv_xh,y
    lda #LO(LEVEL_H - 4) : sta mv_yl,y : lda #HI(LEVEL_H - 4) : sta mv_yh,y
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
    lda ty : sec : sbc #4 : sta tmp : lda ty+1 : sbc #0 : bpl h_ok
    lda #0 : sta tmp
.h_ok
    \ (horizontally scrolling levels are 256 high, so h fits in a byte)
    \ mid = tx + h + h * 85 / 256  (h * 1.332)
    lda tmp : sta mul_a : lda #85 : jsr mul8      \ A = high byte of h * 85
    clc : adc tmp : sta sp_mid : lda #0 : adc #0 : sta sp_mid+1
    lda sp_mid : clc : adc tx : sta sp_mid : lda sp_mid+1 : adc tx+1 : sta sp_mid+1
    jsr random_x
    ldy sp_slot : ldx #DIFFICULTY
    lda #MV_DAGGER : sta mv_active,y
    lda #IMG_DaggerLR : sta mv_img,y
    lda sp_x : sta mv_xl,y : lda sp_x+1 : sta mv_xh,y
    lda #4 : sta mv_yl,y : lda #0 : sta mv_yh,y
    \ down and to the left
    lda #0 : sec : sbc diff_dagger_xf,x : sta mv_vxf,y
    lda #0 : sbc diff_dagger_xi,x : sta mv_vxi,y
    lda diff_dagger_yf,x : sta mv_vyf,y
    lda diff_dagger_yi,x : sta mv_vyi,y
    lda diff_pause,x : sta mv_pause,y
.none
    rts
}

\ sp_x = sp_mid - spread/2 + random(0 .. spread)
.random_x
{
    ldx #DIFFICULTY
.retry
    jsr random
    lda rng+1 : and #1 : sta tmp+1 : lda rng : sta tmp       \ 0 .. 511
    lda diff_spread_l,x : cmp tmp : lda diff_spread_h,x : sbc tmp+1 : bcc retry
    \ sp_x = sp_mid + tmp - spread / 2
    lda diff_spread_h,x : lsr a : sta sp_x+1 : lda diff_spread_l,x : ror a : sta sp_x
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
    lda #SPANS_BANK : sta ROMSEL_COPY : sta ROMSEL
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
    lda co_i : cmp #NUM_DRAW : bne loop

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
    jsr queue_repaint
    lda draw_kind,x
    cmp #KIND_GEM : bne not_gem
    inc gems_found
    rts
.not_gem
    cmp #KIND_KEY : bne done
    inc keys_found
    lda keys_found : cmp #NUM_KEYS : bne more_keys
    lda #WIN_FRAMES : sta won           \ all the keys: level complete!
    rts
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
    lda #0 : sta save_cp
    lda #1 : sta have_cp
    ldx #NUM_DRAW - 1
.objs
    lda alive,x : sta cp_alive,x : dex : bpl objs
    lda keys_found : sta cp_keys
    lda gems_found : sta cp_gems
    lda tx : sta cp_tx : lda tx+1 : sta cp_tx+1
    lda ty : sta cp_ty : lda ty+1 : sta cp_ty+1
    lda tface : sta cp_face
    lda bal_timer : sta cp_bal : lda dag_timer : sta cp_dag
.done
    rts
}

\ ------------------------------------------------------------------------------
\ Platforms and ladders (ports of PlatformFind and LadderFind)
\ ------------------------------------------------------------------------------

\ Find the highest platform top in [q_y1, q_y2) under column q_x.
\ Returns res_found = 1 and res_y = its y.
.platform_find
{
    lda #0 : sta res_found
    ldx #NUM_PLATS - 1
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
    \ keep the highest (smallest y)
    lda res_found : beq take
    lda plat_yl,x : cmp res_y : lda plat_yh,x : sbc res_y+1 : bcs next
.take
    lda #1 : sta res_found
    lda plat_yl,x : sta res_y : lda plat_yh,x : sta res_y+1
    stx res_i
.next
    dex : bpl loop
    rts
}

\ Can Trogg at (q_x, q_y1) move along a ladder towards q_y2?
\ q_onplat / q_jump as LadderFind's isOnPlatform / isJumping.
\ Returns res_found, res_x, res_y, res_i.
.ladder_find
{
    lda #0 : sta res_found
    lda q_x : sta res_x : lda q_x+1 : sta res_x+1
    lda q_y1 : sta res_y : lda q_y1+1 : sta res_y+1
    ldx #0
.loop
    cpx #NUM_LADDERS : bne check
    rts
.check
    \ only ladders within 6 pixels of q_x
    lda q_x : sec : sbc lad_xl,x : sta tmp
    lda q_x+1 : sbc lad_xh,x
    beq pos
    cmp #&FF : bne next
    lda tmp : cmp #&FA : bcc next
    bcs near
.pos
    lda tmp : cmp #7 : bcs next
.near
    \ lad_top / lad_len, minus the invisible extension if jumping upwards
    lda lad_yl,x : sta lad_top : lda lad_yh,x : sta lad_top+1
    lda lad_hl,x : sta lad_len : lda lad_hh,x : sta lad_len+1
    \ going up?  (q_y2 < q_y1)
    lda q_y2 : cmp q_y1 : lda q_y2+1 : sbc q_y1+1
    bcc going_up
    jmp going_down
.next
    inx : jmp loop

.going_up
    lda q_jump : beq up1
    lda lad_top : clc : adc lad_ext,x : sta lad_top : bcc nc1 : inc lad_top+1 : .nc1
    lda lad_len : sec : sbc lad_ext,x : sta lad_len : bcs nc2 : dec lad_len+1 : .nc2
.up1
    lda q_onplat : beq up2
    \ skip if lad_top > y1
    lda q_y1 : cmp lad_top : lda q_y1+1 : sbc lad_top+1 : bcc next
.up2
    \ need res_y >= lad_top
    lda res_y : cmp lad_top : lda res_y+1 : sbc lad_top+1 : bcc next
    \ and y2 < lad_top + lad_len
    lda lad_top : clc : adc lad_len : sta tmp
    lda lad_top+1 : adc lad_len+1 : sta tmp+1
    lda q_y2 : cmp tmp : lda q_y2+1 : sbc tmp+1 : bcs next
    jsr found_x
    \ res_y = max(y2, lad_top)
    lda q_y2 : cmp lad_top : lda q_y2+1 : sbc lad_top+1
    bcs use_y2
    lda lad_top : sta res_y : lda lad_top+1 : sta res_y+1
    jmp next
.use_y2
    lda q_y2 : sta res_y : lda q_y2+1 : sta res_y+1
    rts                             \ reached y2: stop searching

.next_d
    jmp next

.going_down
    lda q_onplat : beq dn1
    \ skip if lad_top < y1
    lda lad_top : cmp q_y1 : lda lad_top+1 : sbc q_y1+1 : bcc next_d
.dn1
    \ tmp = lad_top + lad_len - 1 (bottom)
    lda lad_top : clc : adc lad_len : sta tmp
    lda lad_top+1 : adc lad_len+1 : sta tmp+1
    lda tmp : bne dn2 : dec tmp+1 : .dn2 : dec tmp
    \ need res_y < bottom
    lda res_y : cmp tmp : lda res_y+1 : sbc tmp+1 : bcs next_d
    \ and y2 >= lad_top
    lda q_y2 : cmp lad_top : lda q_y2+1 : sbc lad_top+1 : bcc next_d
    jsr found_x
    \ res_y = min(y2, bottom)
    lda q_y2 : cmp tmp : lda q_y2+1 : sbc tmp+1
    bcc use_y2
    lda tmp : sta res_y : lda tmp+1 : sta res_y+1
    jmp next_d

    \ res_x = x + sign(ladx - x)
.found_x
    lda #1 : sta res_found
    stx res_i
    lda q_x : sta res_x : lda q_x+1 : sta res_x+1
    lda lad_xl,x : cmp q_x : lda lad_xh,x : sbc q_x+1
    bcc dec_x
    lda lad_xl,x : cmp q_x : bne inc_x
    lda lad_xh,x : cmp q_x+1 : beq fx_done
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

.trogg_update
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
    \ nx = tx + xmove
    lda xmove : jsr add_x_signed       \ q_x = tx + A
    lda ty : sta q_y1 : lda ty+1 : sta q_y1+1
    lda ty : clc : adc #1 : sta q_y2 : lda ty+1 : adc #0 : sta q_y2+1
    jsr platform_find
    lda res_found : bne on_platform
    \ walked off the edge
    jsr move_to_qx
    lda xmove : sta xvel
    lda #FALL_STEP_OFF
    ldx ymove : beq start_fall : bmi start_fall
    lda #FALL_JUMP
.start_fall
    sta fallt
    lda #1 : sta ud_db
    lda #ST_FALL : sta tstate
    rts

.on_platform
    lda ymove : beq walk
    \ Try a ladder: LadderFind(nx, y, y - ymove, onplat, jumping)
    jsr set_q_y2_minus_ymove
    lda #1 : sta q_onplat : sta q_jump
    jsr ladder_find
    lda res_found : beq no_ladder
    lda res_x : sta tx : lda res_x+1 : sta tx+1
    lda res_y : sta ty : lda res_y+1 : sta ty+1
    jmp start_climbing
.no_ladder
    lda ymove : bmi walk
    \ Jump
    jsr move_to_qx
    lda xmove : sta xvel
    lda #FALL_JUMP : sta fallt
    lda #1 : sta ud_db
    lda #ST_FALL : sta tstate
    rts

.walk
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

\ q_y2 = ty - ymove; q_y1 = ty; q_x already set
.set_q_y2_minus_ymove
{
    lda ty : sta q_y1 : lda ty+1 : sta q_y1+1
    lda ymove : bmi down
    lda ty : sec : sbc ymove : sta q_y2 : lda ty+1 : sbc #0 : sta q_y2+1
    rts
.down
    lda ty : clc : adc #1 : sta q_y2 : lda ty+1 : adc #0 : sta q_y2+1
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

.trogg_falling
{
    \ x += xvel, clamped to [12, LEVEL_W - 10]
    lda xvel : jsr add_x_signed
    jsr move_to_qx
    lda tx : cmp #12 : lda tx+1 : sbc #0 : bcs x_ok1
    lda #12 : sta tx : lda #0 : sta tx+1
.x_ok1
    lda tx : cmp #LO(LEVEL_W - 10) : lda tx+1 : sbc #HI(LEVEL_W - 10) : bcc x_ok2
    lda #LO(LEVEL_W - 10) : sta tx : lda #HI(LEVEL_W - 10) : sta tx+1
.x_ok2
    lda tx : sta q_x : lda tx+1 : sta q_x+1

    ldx fallt
    lda fall_dy,x : sta dy
    lda fall_flags,x : sta fflags
    cpx #FALL_LEN - 1 : bcs no_inc
    inc fallt
.no_inc

    \ Grab a ladder?
    lda ymove : beq no_grab
    lda fflags : and #1 : beq no_grab
    lda ty : sta q_y1 : lda ty+1 : sta q_y1+1
    jsr set_q_y2_ty_plus_dy
    lda #0 : sta q_onplat : lda #1 : sta q_jump
    jsr ladder_find
    lda res_found : beq no_grab
    lda res_x : sta tx : lda res_x+1 : sta tx+1
    lda res_y : sta ty : lda res_y+1 : sta ty+1
    lda #0 : sta xvel
    lda #1 : sta lr_db
    jmp start_climbing
.no_grab

    lda dy : beq done : bmi rising
    \ Falling: land on a platform between y and y + dy?
    lda ty : sta q_y1 : lda ty+1 : sta q_y1+1
    jsr set_q_y2_ty_plus_dy
    jsr platform_find
    lda res_found : beq keep_falling
    lda res_y : sta ty : lda res_y+1 : sta ty+1
    lda #0 : sta xvel
    lda #1 : sta ud_db
    lda #ST_STAND : sta tstate
    lda fflags : and #2 : beq done
    jmp trogg_dies                  \ landed too fast!
.keep_falling
    lda q_y2 : sta ty : lda q_y2+1 : sta ty+1
    \ off the bottom of the level?
    lda ty : cmp #LO(LEVEL_H) : lda ty+1 : sbc #HI(LEVEL_H) : bcc done
    lda #LO(LEVEL_H - 1) : sta ty : lda #HI(LEVEL_H - 1) : sta ty+1
    jmp trogg_dies
.rising
    clc : adc ty : sta ty : lda ty+1 : adc #&FF : sta ty+1
.done
    rts
}

\ q_y2 = ty + dy (dy signed)
.set_q_y2_ty_plus_dy
{
    lda dy : bmi neg
    clc : adc ty : sta q_y2 : lda ty+1 : adc #0 : sta q_y2+1
    rts
.neg
    clc : adc ty : sta q_y2 : lda ty+1 : adc #&FF : sta q_y2+1
    rts
}

.trogg_dies
{
IF INVINCIBLE
    rts                             \ (test builds: INVINCIBLE=1 ./build.sh)
ENDIF
    lda #50 : sta dead              \ restart in a second (50 game ticks)
    rts
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

\ Start falling with fall-table index A and x velocity xvel
.climb_to_fall
{
    sta fallt
    lda #ST_FALL : sta tstate
    lda xvel : bmi left
    lda #0 : sta tface : rts
.left
    lda #1 : sta tface : rts
}

.trogg_climbing
{
    lda #0 : sta xvel
    lda tx : sta q_x : lda tx+1 : sta q_x+1
    lda #0 : sta q_onplat : sta q_jump
    lda ymove : bne moving : jmp still
.moving
    bpl up : jmp down

.up
    \ LadderFind(x, y, y - 1)
    lda ty : sta q_y1 : lda ty+1 : sta q_y1+1
    lda ty : sec : sbc #1 : sta q_y2 : lda ty+1 : sbc #0 : sta q_y2+1
    jsr ladder_find
    jsr ladder_moved : bcc up_no
    lda res_y : sta ty : lda res_y+1 : sta ty+1
    jsr maybe_step_off : bcc stay1 : rts
.stay1
    jmp climbing
.up_no
    \ At the top: step off onto a platform if there is one
    lda ty : sec : sbc #1 : sta q_y1 : lda ty+1 : sbc #0 : sta q_y1+1
    lda ty : clc : adc #2 : sta q_y2 : lda ty+1 : adc #0 : sta q_y2+1
    jsr platform_find
    lda #1 : sta ud_db
    lda res_found : beq climb_j
    lda ty : bne u1 : dec ty+1 : .u1 : dec ty
    lda #FALL_STEP_OFF : jmp climb_to_fall

.climb_j
    jmp climbing

.still
    \ LadderFind(x, y, y + 2)
    lda ty : sta q_y1 : lda ty+1 : sta q_y1+1
    lda ty : clc : adc #2 : sta q_y2 : lda ty+1 : adc #0 : sta q_y2+1
    jsr ladder_find
    jsr ladder_moved : bcc still_no
    jsr maybe_step_off : bcc stay2 : rts
.stay2
    jmp climbing
.still_no
    lda xmove : beq climb_j
    sta xvel
    lda #FALL_STEP_OFF : jmp climb_to_fall

.down
    \ Climbing down onto a platform?
    lda ty : sta q_y1 : lda ty+1 : sta q_y1+1
    lda ty : clc : adc #1 : sta q_y2 : lda ty+1 : adc #0 : sta q_y2+1
    jsr platform_find
    lda res_found : beq down_ladder
    lda #1 : sta ud_db
    lda #ST_STAND : sta tstate
    lda #0 : sta tface
    rts
.down_ladder
    jsr ladder_find
    jsr ladder_moved : bcc down_no
    lda res_y : sta ty : lda res_y+1 : sta ty+1
    jsr maybe_step_off : bcc stay3 : rts
.stay3
    jmp climbing
.down_no
    \ Off the bottom of the ladder
    lda #0 : sta xvel
    inc ty : bne d1 : inc ty+1 : .d1
    lda #1 : sta ud_db
    lda #FALL_LADDER_DROP : jmp climb_to_fall


.climbing
    jsr start_climbing
    lda tclimb : beq no_anim
    jmp animate
.no_anim
    rts
}

\ After ladder_find: carry set if a ladder was found and res_y differs from ty.
\ Also moves tx to res_x when found.
.ladder_moved
{
    lda res_found : beq no
    lda res_y : cmp ty : bne yes
    lda res_y+1 : cmp ty+1 : beq no
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
    lda #FALL_STEP_OFF : jsr climb_to_fall
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
    ldx #NUM_DRAW - 1
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
    \ Hit! It flies off in the yoyo's direction
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
    lda #0 : sta mv_active,x
.mnext
    dec mvc_i : bmi m_done
    jmp mloop
.m_done
    lda yo_hit : cmp #1             \ carry set if hit
    rts
}

.logic_end
SAVE "LOGIC", logic_start, logic_end
PRINT "Game logic:", logic_end - logic_start, "bytes in bank", LEVEL_BANK, "at", ~LOGIC_CODE

\ ------------------------------------------------------------------------------
\ Level data, in sideways RAM bank 6 (&9000-&9FFF), between the collision spans
\ and the game logic
\ ------------------------------------------------------------------------------

LEVEL_BANK = 6                      \ (the same bank as the collision spans)
LEVEL_DATA = &9000
CLEAR &8000, &C000
ORG LEVEL_DATA
GUARD LOGIC_CODE
.level_data
INCLUDE "src/gen/level.asm"
INCLUDE "src/gen/fall.asm"
INCLUDE "src/gen/collide.asm"
.level_data_end
SAVE "LEVEL", level_data, level_data_end
PRINT "Level data:", level_data_end - level_data, "bytes in bank", LEVEL_BANK

INCLUDE "src/gen/disc.asm"

PRINT "Code from", ~start, "to", ~end, "(", end - start, "bytes ), free:", SCREEN - ram_top
\ Addresses used by test scripts (profiling and poking variables)
PRINT "TIMING", ~main_loop, ~t_restore, ~t_scroll, ~t_draw, ~t_vsync, ~t_after_vsync, ~t_logic, ~t_logic_done
PRINT "SYMBOLS loops", ~loops, "mv_img", ~mv_img, "mv_vxi", ~mv_vxi, "mv_vyi", ~mv_vyi, "mv_vyf", ~mv_vyf, "mv_yl", ~mv_yl, "mv_yh", ~mv_yh, "mv_pause", ~mv_pause, "bal_timer", ~bal_timer, "dag_timer", ~dag_timer, "bscroll", ~bscroll, "front", ~front, "vsyncs", ~vsyncs, "yo_len", ~yo_len, "mv_active", ~mv_active, "mv_xl", ~mv_xl, "mv_xh", ~mv_xh, "tface", ~tface, "keys_found", ~keys_found, "gems_found", ~gems_found, "won", ~won, "have_cp", ~have_cp, "restarts", ~restarts, "alive", ~alive, "newcol", ~newcol, "dead", ~dead, "tx", ~tx, "ty", ~ty, "tstate", ~tstate, "fallt", ~fallt, "dead", ~dead, "anim", ~anim, "p_img", ~p_img, "bank", ~bank, "oldbank", ~oldbank, "dptr", ~dptr, "scrollcol", ~scrollcol
