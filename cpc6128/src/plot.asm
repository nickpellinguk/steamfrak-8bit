; The plotter, the draw log, the yoyo string, and the compiled meanie: ports of
; the BBC version's plot, log_sprite/log_line/restore_log, hline, plot_slow and
; jit_build/jit_compile, for the CPC's screen.
;
; The timer (IMG_Hud) is a raw image instead: its bytes, in hud_image, are
; nibbles, 4 black pixels each, looked up in HUD_PIX and HUD_MASK (as codes 1-15).
;
; Images are 5-pixel codes (see tools/convert.py): a byte column of an image is
; its height in codes, top to bottom, each looked up in the code tables (in the
; graphics bank, after the sprites) for this shift's half: its left 4 pixels for
; an odd shift, its right 4 for an even one, with a mask (both bits set for a
; transparent pixel). Code 0 is 5 transparent pixels, 128-255 are 5 solid ones,
; which are stored without masking.
;
; Where things are on the screen: a level's byte column c and line y are always
; at the same address in a buffer,
;     page + (y MOD 8) * #800 + ((y / 8) * g_w + c) MOD #800
; (rowoff[y / 8] holds the (y / 8) * g_w MOD #800). The CRTC wraps each line's
; 2K block in the same way, so scrolling just moves the CRTC's start over it,
; as the BBC version scrolls over a screen that wraps at #8000. Down a column,
; the next line is #800 on; past a character row's 8th line, the next row's
; first line is g_w on from its first, wrapping within the 2K block.
;
; Positions and the clip window are in level coordinates: clip_l and clip_r are
; byte columns ([clip_l, clip_r)), clip_t a line and clip_h a number of lines
; (0 = 256).

PM_PLOT     = 0                     ; plot it
PM_SAVE     = 1                     ; plot it, saving the background first (at sbase)
PM_RESTORE  = 2                     ; put the background back (restore_saved, hline)
PM_SAVEONLY = 3                     ; only save the background (into bank p_sbank)

SAVE_HEADER = 2                     ; a save record: columns, rows, then each column's
                                    ; screen address and saved bytes

; ------------------------------------------------------------------------------
; plot: draw (or save the background under) image p_img with its origin at
; (p_x, p_y), in buffer back_page. Leaves sptr after the save record.
; ------------------------------------------------------------------------------
plot
        ld hl,(sbase) : ld (sptr),hl
        ld a,(ga_ram) : ld (p_oldbank),a
        ld a,(p_mode)
        cp PM_SAVE : jr z,.header
        cp PM_SAVEONLY : jr nz,.no_header
        ld a,(p_sbank) : call bank_select           ; (the save area is in another bank)
.header ld hl,(sptr) : ld (hl),0                    ; no columns (until we know better)
        inc hl : inc hl : ld (sptr),hl
.no_header
        ; left = x - xo, top = y - yo (signed 16-bit)
        ld a,(p_img) : ld e,a : ld d,0
        ld hl,img_xo : add hl,de : ld c,(hl) : ld b,0
        ld hl,(p_x) : or a : sbc hl,bc : ld (p_left),hl
        ld a,l : and 3 : ld (p_shift),a
        sra h : rr l : sra h : rr l : ld (p_col),hl ; col = left >> 2 (arithmetic)
        ld hl,img_yo : add hl,de : ld c,(hl)
        ld hl,(p_y) : or a : sbc hl,bc : ld (p_top),hl
        ld hl,img_w : add hl,de : ld a,(p_shift) : add a,(hl) : add a,3
        rrca : rrca : and #3F : ld (p_wb),a         ; width in bytes at this shift
        ld hl,img_h : add hl,de : ld a,(hl) : ld (p_hgt),a

        ; Rows: clip to clip_t .. clip_t + clip_h - 1 (clip_h = 0 means 256)
        xor a : ld (p_r0),a
        ld a,(p_hgt) : ld (p_rows),a
        ld hl,(p_top) : ld bc,(clip_t) : or a : sbc hl,bc : ld (p_top),hl
        ld a,h : or a : jr z,.top_ok
        inc a : jp nz,.exit                         ; far above or below
        ld a,l : or a : jp z,.exit
        ; above the window: skip -top rows
        neg : ld (p_r0),a : ld b,a
        ld a,(p_hgt) : sub b : jp c,.exit : jp z,.exit
        ld (p_rows),a
        ld a,(clip_h) : or a : jr z,.above_ok       ; (and no more than clip_h)
        ld b,a : ld a,(p_rows) : cp b : jr c,.above_ok
        ld a,b : ld (p_rows),a
.above_ok
        ld hl,(clip_t) : ld (p_firsty),hl
        jr .rows_done
.top_ok ; rows = min(hgt, clip_h - top)
        ld a,(clip_h) : sub l                       ; (clip_h = 0 gives 256 - top)
        jr z,.rows_cut : jr nc,.rows_avail
        ld a,(clip_h) : or a : jp nz,.exit          ; top >= clip_h
        xor a : sub l                               ; 256 - top
.rows_avail
        ld b,a : ld a,(p_rows) : cp b : jr c,.rows_cut
        ld a,b : ld (p_rows),a
.rows_cut
        ld a,(clip_h) : or a : jr z,.top_in
        ld b,a : ld a,l : cp b : jp nc,.exit
.top_in ld bc,(clip_t) : add hl,bc : ld (p_firsty),hl
.rows_done

        ; Only the byte columns inside [clip_l, clip_r):
        ; cidx = max(0, clip_l - col), cend = min(wb, clip_r - col)
        ld a,(clip_l) : ld l,a : ld h,0 : ld bc,(p_col) : or a : sbc hl,bc
        jp p,.start_pos
        xor a : jr .start_done
.start_pos
        ld a,h : or a : jp nz,.exit                 ; clip_l - col >= 256
        ld a,(p_wb) : ld b,a : ld a,l : cp b : jp nc,.exit
.start_done
        ld (p_cidx),a
        ld a,(clip_r) : ld l,a : ld h,0 : ld bc,(p_col) : or a : sbc hl,bc
        jp m,.exit
        ld a,h : or a : ld a,(p_wb)
        jr nz,.end_ok                               ; (clip_r - col >= 256: all of it)
        ld b,a : ld a,l : cp b : jr c,.end_ok
        ld a,b
.end_ok ld (p_cend),a
        ld b,a : ld a,(p_cidx) : cp b : jp nc,.exit

        ; The image's data at this shift, and its code tables
        ld a,(p_shift) : add a,a : ld e,a : ld d,0
        ld hl,dir_tables : add hl,de : ld e,(hl) : inc hl : ld d,(hl)   ; img_lo<shift>
        ld a,(p_img) : ld l,a : ld h,0 : add hl,de
        ld bc,NUM_IMAGES
        ld a,(hl) : add hl,bc : ld (p_dcol),a       ; lo
        ld a,(hl) : add hl,bc : ld (p_dcol+1),a     ; hi (img_hi<shift> follows img_lo)
        ld a,(hl) : and CODED + RAW : jp z,.exit    ; (img_bank<shift> follows that: none here?)
        and RAW : ld a,HUD_MASK >> 8 : jr nz,.tables    ; (a raw image: the timer's nibbles)
        ld a,(p_shift) : rrca
        ld a,CODE_RMASK>>8 : jr nc,.tables
        ld a,CODE_LMASK>>8
.tables ld (p_tab),a
        ; dcol = the first visible column's data, from row r0
        ld hl,(p_dcol) : ld a,(p_r0) : ld e,a : ld d,0 : add hl,de
        ld a,(p_hgt) : ld e,a
        ld a,(p_cidx) : or a : jr z,.skipped
        ld b,a
.skip   add hl,de : djnz .skip
.skipped
        ld (p_dcol),hl
        ; page the graphics in (or, for PM_SAVEONLY, keep the save bank)
        ld a,(p_mode) : cp PM_SAVEONLY : jr z,.paged
        ld a,RAM_BANK + GFX_BANK : call bank_select
.paged
        ; the first visible line's character row and line within it
        ld hl,(p_firsty)
        ld a,l : and 7 : ld (p_y0),a
        srl h : rr l : srl h : rr l : srl h : rr l
        ld a,l : ld (p_row),a
        ; the save record's header: columns, rows
        ld a,(p_mode) : cp PM_SAVE : jr z,.layout : cp PM_SAVEONLY : jr nz,.no_layout
.layout ld hl,(sbase)
        ld a,(p_cidx) : ld b,a : ld a,(p_cend) : sub b : ld (hl),a
        inc hl : ld a,(p_rows) : ld (hl),a
.no_layout
        ld a,(p_mode) : add a,a : ld e,a : ld d,0
        ld hl,col_routines : add hl,de
        ld a,(hl) : inc hl : ld h,(hl) : ld l,a
        ld (.do_col+1),hl

        ; the first column's screen address:
        ; back_page + y0 * #800 + (rowoff[row] + col + cidx) MOD #800
        ld hl,(p_col) : ld a,(p_cidx) : ld e,a : ld d,0 : add hl,de
        ex de,hl
        ld a,(p_row) : ld l,a : ld h,rowoff_lo>>8
        ld a,(hl) : inc h : ld h,(hl) : ld l,a
        add hl,de
        ld a,(p_y0) : add a,a : add a,a : add a,a : ld b,a
        ld a,h : and 7 : add a,b : ld b,a
        ld a,(back_page) : add a,b : ld b,a : ld c,l
        ld (.scr+1),bc
        ; (saving: each column's address goes in the save record)
        ld a,(p_mode) : cp PM_SAVE : jr z,.noting : cp PM_SAVEONLY : jr z,.noting
        ld a,.no_address - .notes_jr - 2 : jr .notes
.noting xor a
.notes  ld (.notes_jr+1),a
        ld hl,(p_dcol) : ld (.dat+1),hl
        ld a,(p_cidx) : ld b,a : ld a,(p_cend) : sub b : ld (.ncols+1),a
        ld a,(p_tab) : ld (.col_tab),a          ; (the column loop's constants, in its code)
        ld a,(p_rows) : ld (.col_rows),a
        ld a,(p_hgt) : ld (.col_hgt),a
        exx : ld hl,(sptr) : exx                ; (HL' is the save record's pointer throughout)
.col_loop
.scr    ld bc,0                                 ; (the column's screen address)
.notes_jr jr .no_address                        ; (jr $+2 when saving)
        ld a,c : exx : ld (hl),a : inc hl : exx
        ld a,b : exx : ld (hl),a : inc hl : exx
.no_address
.dat    ld de,0                                 ; (its data)
        ld h,0                                  ; (ld h,p_tab: set above)
.col_tab equ $ - 1
        ld ixl,0                                ; (ld ixl,p_rows)
.col_rows equ $ - 1
.do_col call 0                                  ; (the column routine for this mode)
        ; the next column: its data, and the next byte on the screen (within the 2K)
        ld hl,(.dat+1)
        ld a,0                                  ; (ld a,p_hgt)
.col_hgt equ $ - 1
        add a,l : ld l,a : jr nc,.data_ok
        inc h
.data_ok
        ld (.dat+1),hl
        ld hl,(.scr+1) : inc l : jr nz,.scr_ok
        ld a,h : and #F8 : ld b,a : ld a,h : inc a : and 7 : or b : ld h,a
.scr_ok ld (.scr+1),hl
.ncols  ld a,0 : dec a : ld (.ncols+1),a : jr nz,.col_loop
        exx : ld (sptr),hl : exx
.exit   ld a,(p_oldbank) : jp bank_select

; img_lo<shift> for each shift (img_hi<shift> and img_bank<shift> follow each)
dir_tables  dw img_lo0, img_lo1, img_lo2, img_lo3
col_routines dw col_plot, col_save, col_restore, col_saveonly

; ------------------------------------------------------------------------------
; Column routines: BC = the screen address of the column's first line, DE = its
; image data, H = its mask table's page (the pixels are the page before), IXL =
; the lines to do; save records via HL' (in the other register set).
; ------------------------------------------------------------------------------

; Each does the column's first character cell's lines (those left in it) in a
; loop, then whole cells (8 lines unrolled, no counting), then what's left. Each
; line is the same whatever the byte: every code goes through the masks (code 0's
; leaves the screen alone; a solid code's mask is 0), so there are no branches.

; IXH = the lines in the column's first cell (at most IXL), IXL = those after it
col_start
        ld a,b : rrca : rrca : rrca : and 7 : neg : add a,8     ; (lines left in the cell)
        ld ixh,a : ld a,ixl : sub ixh : jr nc,.more
        ld a,ixl : ld ixh,a : xor a                             ; (all in the first)
.more   ld ixl,a
        ret

; The next character row: #4000 back (past a cell's 8th line), then g_w on,
; wrapping within its 2K
next_row
        ld a,b : sub #40 : ld b,a
        ld a,c
next_row_w
        add a,64 : ld c,a                       ; (add a,g_w: set_mode sets it)
        jr nc,.nc : inc b
.nc     res 3,b                                 ; (wrapping within the 2K)
        ret

MACRO STEP                                      ; the next line down: #800 on
        ld a,b : add a,8 : ld b,a
MEND
MACRO PLOT_LINE                                 ; plot a byte
        ld a,(de) : inc de : ld l,a
        ld a,(bc) : and (hl) : dec h : or (hl) : inc h : ld (bc),a
        STEP
MEND
MACRO SAVE_LINE                                 ; save it first (reading the screen once)
        ld a,(de) : inc de : ld l,a
        ld a,(bc) : exx : ld (hl),a : inc hl : exx
        and (hl) : dec h : or (hl) : inc h : ld (bc),a
        STEP
MEND
MACRO SAVEONLY_LINE
        ld a,(bc) : exx : ld (hl),a : inc hl : exx
        STEP
MEND
MACRO RESTORE_LINE
        exx : ld a,(hl) : inc hl : exx : ld (bc),a
        STEP
MEND
MACRO FAST_RESTORE_LINE                         ; (from HL itself)
        ld a,(hl) : inc hl : ld (bc),a
        STEP
MEND

; A column routine doing line L (one of the macros above) for each line
MACRO COLUMN_ROUTINE line
        call col_start
@first  {line}
        dec ixh : jp nz,@first
        ld a,ixl : or a : ret z
        call next_row
@cells  ld a,ixl : sub 8 : jp c,@last
        ld ixl,a
        {line}
        {line}
        {line}
        {line}
        {line}
        {line}
        {line}
        {line}
        call next_row
        jp @cells
@last   ld a,ixl : or a : ret z
        ld ixh,a
@rest   {line}
        dec ixh : jp nz,@rest
        ret
MEND

col_plot     COLUMN_ROUTINE PLOT_LINE
col_save     COLUMN_ROUTINE SAVE_LINE
col_saveonly COLUMN_ROUTINE SAVEONLY_LINE
col_restore  COLUMN_ROUTINE RESTORE_LINE
col_restore_fast COLUMN_ROUTINE FAST_RESTORE_LINE

; Put back the background saved when an image was drawn with PM_SAVE (or
; PM_SAVEONLY), straight from its save record at sbase
restore_saved
        ld hl,(sbase)
        ld a,(hl) : or a : ret z
        ld (p_cidx),a
        inc hl : ld a,(hl) : ld (p_rows),a : inc hl
.column ld c,(hl) : inc hl : ld b,(hl) : inc hl
        ld a,(p_rows) : ld ixl,a
        call col_restore_fast
        ld a,(p_cidx) : dec a : ld (p_cidx),a
        jr nz,.column
        ret

; ------------------------------------------------------------------------------
; hline: a 1-pixel black (or, with hl_yel = #F0, yellow) line from (p_x, p_y) to
; (q_x, p_y), inclusive. PM_SAVE draws it saving the background at sbase;
; PM_RESTORE puts it back. Clipped to the window.
; ------------------------------------------------------------------------------
hline
        ld hl,(sbase) : ld (sptr),hl
        ; only rows in the window: 0 <= p_y - clip_t < clip_h (0 = 256)
        ld hl,(p_y) : ld bc,(clip_t) : or a : sbc hl,bc
        ld a,h : or a : ret nz
        ld a,(clip_h) : or a : jr z,.row_ok
        ld b,a : ld a,l : cp b : ret nc
.row_ok ; order the ends (signed: the yoyo can be a pixel or two left of the level):
        ; left in p_left, right in hl_right, the left clipped to the level's edge
        ld hl,(q_x) : ld de,(p_x) : call signed_less
        ld hl,(p_x) : ld de,(q_x)
        jr nc,.ordered
        ex de,hl
.ordered
        bit 7,d : ret nz                        ; (wholly left of the level)
        bit 7,h : jr z,.left_ok
        ld hl,0
.left_ok
        ld (p_left),hl : ld (hl_right),de
        ld a,l : and 3 : ld (hl_p0),a
        ld a,e : and 3 : ld (hl_p1),a
        ld a,h : cp 4 : ret nc                  ; off the level (beyond 1024, or negative)?
        srl h : rr l : srl h : rr l : ld a,l : ld (hl_c0),a
        ld a,255
        ex de,hl
        ld b,h : ld a,b : cp 4 : ld a,255 : jr nc,.c1_ok
        srl h : rr l : srl h : rr l : ld a,l
.c1_ok  ld (hl_c1),a
        ; the columns in the window: cs = max(c0, clip_l), ce = min(c1, clip_r - 1)
        ld a,(clip_r) : dec a : ld b,a : ld a,(hl_c1) : cp b : jr c,.ce_ok
        ld a,b
.ce_ok  ld e,a                                  ; E = ce
        ld a,(clip_l) : ld b,a : ld a,(hl_c0) : cp b : jr nc,.cs_ok
        ld a,b
.cs_ok  ld d,a                                  ; D = cs
        ld a,e : sub d : ret c
        ld a,e : sub d
        inc a : ld (.count+1),a                 ; bytes
        ; the masks of its first and last bytes (all of a byte between)
        ld c,#FF
        ld a,(hl_c0) : cp d : jr nz,.m0_ok
        ld a,(hl_p0) : ld hl,left_pixels : add a,l : ld l,a : ld a,h : adc a,0 : ld h,a : ld c,(hl)
.m0_ok  ld b,#FF
        ld a,(hl_c1) : cp e : jr nz,.m1_ok
        ld a,(hl_p1) : ld hl,right_pixels : add a,l : ld l,a : ld a,h : adc a,0 : ld h,a : ld b,(hl)
.m1_ok  ld a,b : ld (.last+1),a
        ; HL = the first byte's address: back_page + line * #800 + (rowoff[row] + cs) MOD #800
        ld a,c : push af                        ; (the first byte's mask)
        ld e,d : ld d,0
        ld hl,(p_y) : ld a,l : and 7 : add a,a : add a,a : add a,a : ld b,a
        srl h : rr l : srl h : rr l : srl h : rr l
        ld h,rowoff_lo>>8
        ld a,(hl) : inc h : ld h,(hl) : ld l,a
        add hl,de
        ld a,h : and 7 : add a,b : ld b,a
        ld a,(back_page) : add a,b : ld h,a
        ld de,(sptr)
.count  ld b,0
        ld a,(p_mode) : cp PM_RESTORE : jr z,.restore
        ; black is logical colour 3, both bits set in each masked pixel; yellow is
        ; colour 1, the low bit set and the high bit clear: new = old ^ ((old ^ col) & mask)
        ld a,(hl_yel) : xor #F0 : or #0F : ld (.col+1),a
        pop af                                  ; (A = the first byte's mask)
        ld c,a
.draw   djnz .not_last
.last   ld a,0 : and c : ld c,a                 ; (the last byte's mask too)
.not_last
        ld a,(hl) : ld (de),a : inc de
.col    xor 0 : and c : xor (hl) : ld (hl),a
        ld c,#FF
        inc b : dec b : jr z,.done
        inc l : jr nz,.draw
        inc h : ld a,h : and 7 : jr nz,.draw
        ld a,h : sub 8 : ld h,a : jr .draw
.restore pop af
.rloop  ld a,(de) : ld (hl),a : inc de
        dec b : jr z,.done
        inc l : jr nz,.rloop
        inc h : ld a,h : and 7 : jr nz,.rloop
        ld a,h : sub 8 : ld h,a : jr .rloop
.done   ld (sptr),de
        ret

; pixel masks (both bits of each pixel) for "pixel p and to its right" / "up to pixel p"
left_pixels  db #FF, #77, #33, #11
right_pixels db #88, #CC, #EE, #FF

; ------------------------------------------------------------------------------
; The draw log: what's been drawn in each buffer, with the backgrounds saved
; under it (in its save area, sfree to send), erased in reverse next time
; ------------------------------------------------------------------------------
MAX_LOG     = 40
LOGK_SPRITE = 0
LOGK_LINE   = 1
LOGK_SPRITE7 = 2                    ; saved in another bank (its LG_BANK)
LINE_SAVE   = 24                    ; bytes: the longest line is about 82 pixels

; a log record: kind, image, x, y, x1 (a line's other end), the save area, its bank;
; then, for restore_chase, the window's rows it covers and whether it's been erased
LG_KIND = 0 : LG_IMG = 1 : LG_X = 2 : LG_Y = 4 : LG_X1 = 6 : LG_SB = 8 : LG_BANK = 10
LG_R0 = 11 : LG_R1 = 12 : LG_DONE = 13
LG_SIZE = 16
ASSERT 2 * MAX_LOG * LG_SIZE == 2 * 40 * 16

; HL = the log record for a new entry in the back buffer (or carry set if it's full)
log_slot
        ld a,(back) : ld e,a : ld d,0 : ld hl,log_n : add hl,de
        ld a,(hl) : cp MAX_LOG : ccf : ret c
; HL = record A of buffer E (carry clear)
log_addr
        dec e : jr nz,.got : add a,MAX_LOG
.got    ld l,a : ld h,0
        add hl,hl : add hl,hl : add hl,hl : add hl,hl   ; (x 16)
        ld de,log_recs : add hl,de
        ret

; Record HL with kind A, the current p_* and the save area (sfree); HL is left at
; its LG_BANK
log_record
        ld (hl),a : inc hl
        ld a,(p_img) : ld (hl),a : inc hl
        ld de,(p_x) : ld (hl),e : inc hl : ld (hl),d : inc hl
        ld de,(p_y) : ld (hl),e : inc hl : ld (hl),d : inc hl
        ld de,(q_x) : ld (hl),e : inc hl : ld (hl),d : inc hl
        ld de,(sfree) : ld (hl),e : inc hl : ld (hl),d : inc hl
        ld (sbase),de
        ex de,hl
        ld a,(back) : ld c,a : ld b,0 : ld hl,log_n : add hl,bc : inc (hl)
        ex de,hl
        ld a,PM_SAVE : ld (p_mode),a
        ret

; Draw image p_img at (p_x, p_y), saving the background, if there's room
log_sprite
        ; room in the save area? sfree + img_sv <= send
        ld a,(p_img) : ld e,a : ld d,0
        call on_rows : ret nc                   ; (nothing logged if none of its rows are shown)
        ld hl,img_svl : add hl,de : ld c,(hl)
        ld hl,img_svh : add hl,de : ld b,(hl)
        ld hl,(sfree) : add hl,bc : ex de,hl
        ld hl,(send) : or a : sbc hl,de : ret c
        call log_slot : ret c
        ld a,LOGK_SPRITE : call log_record
        call plot
        ld hl,(sptr) : ld (sfree),hl

; Carry set if any of image DE's rows at p_y are in the window (as plot clips
; them: top - clip_t < clip_h, 0 meaning 256, and top - clip_t + its height > 0)
on_rows
        ld hl,img_yo : add hl,de : ld c,(hl) : ld b,0
        ld hl,(p_y) : or a : sbc hl,bc
        ld bc,(clip_t) : or a : sbc hl,bc       ; (HL = its top in the window)
        ld a,h : or a : jr nz,.above
        ld a,(clip_h) : or a : scf : ret z
        ld b,a : ld a,l : cp b
        ret
.above  inc a : jr nz,.no                       ; (more than 256 above)
        ld a,l : ld hl,img_h : add hl,de : add a,(hl)     ; (carry if top + height > 0:
        jr z,.no                                ; not = 0)
        ret
.no     or a
        ret

; Draw a black line from (p_x, p_y) to (q_x, p_y), saving the background
log_line
        ; (nothing logged for a line outside the window: its row, then its columns)
        ld hl,(p_y) : ld bc,(clip_t) : or a : sbc hl,bc
        ld a,h : or a : ret nz
        ld a,(clip_h) : or a : jr z,.row_ok
        ld b,a : ld a,l : cp b : ret nc
.row_ok ld hl,(p_x) : ld de,(q_x)
        ld a,h : or d : jp m,.cols_ok           ; (an end left of the level: hline sees to it)
        or a : sbc hl,de : add hl,de : jr c,.ordered
        ex de,hl
.ordered                                        ; (HL = the left end, DE = the right)
        srl d : rr e : srl d : rr e             ; (the right end's column: < clip_l?)
        ld a,(clip_l) : ld b,a : ld a,e : cp b : ret c
        srl h : rr l : srl h : rr l             ; (the left end's: >= clip_r?)
        ld a,(clip_r) : ld b,a : ld a,l : cp b : ret nc
.cols_ok
        ld hl,(sfree) : ld de,LINE_SAVE : add hl,de : ex de,hl
        ld hl,(send) : or a : sbc hl,de : ret c
        call log_slot : ret c
        ld a,LOGK_LINE : call log_record
        call hline
        ld hl,(sptr) : ld (sfree),hl
        ret

; Draw a big moving image (a meanie flying off) at (p_x, p_y): its background is
; saved in the back buffer's slow save area (sfree7 to send7, in bank p_sbank,
; which has far more room), then it is plotted
log_sprite7
        ld a,(p_img) : ld e,a : ld d,0
        call on_rows : ret nc
        ld hl,img_svl : add hl,de : ld c,(hl)
        ld hl,img_svh : add hl,de : ld b,(hl)
        ld hl,(sfree7) : add hl,bc : ex de,hl
        ld hl,(send7) : or a : sbc hl,de : ret c
        call log_slot : ret c
        ld de,(sfree) : push de
        ld de,(sfree7) : ld (sfree),de
        ld a,LOGK_SPRITE7 : call log_record
        ld a,(p_sbank) : ld (hl),a
        pop de : ld (sfree),de
        ld a,PM_SAVEONLY : ld (p_mode),a
        call plot
        ld hl,(sptr) : ld (sfree7),hl
        xor a : ld (p_mode),a                   ; PM_PLOT
        jp plot

; Erase everything logged in the back buffer, most recent first
restore_log
        ld a,(back) : ld e,a : ld d,0 : ld hl,log_n : add hl,de
        ld a,(hl) : or a : ret z
        dec (hl)
        ld a,(hl) : call log_addr
        push hl : pop ix
        call restore_entry
        jr restore_log

; Erase log record IX (IX lost)
restore_entry
        ld a,(ix+LG_IMG) : ld (p_img),a
        ld l,(ix+LG_X) : ld h,(ix+LG_X+1) : ld (p_x),hl
        ld l,(ix+LG_Y) : ld h,(ix+LG_Y+1) : ld (p_y),hl
        ld l,(ix+LG_X1) : ld h,(ix+LG_X1+1) : ld (q_x),hl
        ld l,(ix+LG_SB) : ld h,(ix+LG_SB+1) : ld (sbase),hl
        ld a,PM_RESTORE : ld (p_mode),a
        ld a,(ix+LG_KIND)
        cp LOGK_LINE : jp z,hline
        cp LOGK_SPRITE7 : jp nz,restore_saved
        ld a,(ga_ram) : push af                 ; (saved in another bank: page it in)
        ld a,(ix+LG_BANK) : call bank_select
        call restore_saved
        pop af : jp bank_select

; Erase everything logged in the back buffer while it's still on show, with the
; other buffer waiting to be shown at the next vertical sync (flip_pending):
; chasing the raster down the screen, each thing is erased once the raster has
; passed its last row for the last time (as far as irq_band tells), and once
; whatever was drawn after it on the same rows has been. When the other's
; shown, the rest, most recent first.
restore_chase
        ld a,(flip_pending) : or a : jp z,restore_log   ; (shown already: no need)
        ld a,(back) : ld e,a : ld d,0 : ld hl,log_n : add hl,de
        ld a,(hl) : or a : ret z
        ld (.count + 1),a
        dec a : call log_addr
        ld (.last + 2),hl
        ; each one's rows in the window, and not erased yet
        call .walk_start
.rows   push bc : call rc_rows : pop bc
        ld (ix+LG_DONE),0
        ld de,-LG_SIZE : add ix,de : djnz .rows
.pass   ld a,(flip_pending) : or a : jr z,.rest
        ; the window's lines the raster has passed for the last time: none unless the
        ; other buffer will be shown at the next vertical sync (FRAMES_PER_DRAW = 2)
        ld a,(last_flip) : ld b,a : ld a,(vsyncs) : cp b : ld a,0 : jr z,.safe
        ld a,(irq_band) : cp 6 : jr c,.band
        ld a,5
.band   ld e,a : ld d,0
        ld a,(cur_mode) : or a : ld hl,safe_lines_h : jr z,.table
        ld hl,safe_lines_v
.table  add hl,de : ld a,(hl)
.safe   ld (rc_safe),a
        xor a : ld (rc_ns),a
        call .walk_start
.walk   ld a,(ix+LG_DONE) : or a : jr nz,.next
        ld a,(rc_safe) : ld c,a : ld a,(ix+LG_R1) : cp c : jr nc,.skip
        push bc : call rc_overlaps : pop bc : jr c,.skip
        ld (ix+LG_DONE),1
        push ix : push bc : call restore_entry : pop bc : pop ix
        jr .next
.skip   ld a,(rc_ns) : add a,a : ld e,a : ld d,0 : ld hl,rc_skip : add hl,de
        push ix : pop de : ld (hl),e : inc hl : ld (hl),d
        ld hl,rc_ns : inc (hl)
.next   ld de,-LG_SIZE : add ix,de : djnz .walk
        ld a,(rc_ns) : or a : jr z,.done
        halt                                    ; (until the raster's moved on, or the flip)
        jp .pass
.rest   call .walk_start
.r      ld a,(ix+LG_DONE) : or a : jr nz,.rn
        push ix : push bc : call restore_entry : pop bc : pop ix
.rn     ld de,-LG_SIZE : add ix,de : djnz .r
.done   ld a,(back) : ld e,a : ld d,0 : ld hl,log_n : add hl,de : ld (hl),0
        ret
.walk_start                                     ; IX = the last record, B = how many
.last   ld ix,0
.count  ld b,0
        ret

; Record IX's first and last rows in the window (LG_R0, LG_R1: 0-255, clamped):
; its image's, or a line's row
rc_rows
        ld l,(ix+LG_Y) : ld h,(ix+LG_Y+1)
        ld bc,(clip_t) : or a : sbc hl,bc               ; (its y in the window)
        ld a,(ix+LG_KIND) : cp LOGK_LINE : ld d,h : ld e,l : jr z,.clamp
        ld a,(ix+LG_IMG) : ld c,a : ld b,0
        push hl : ld hl,img_yo : add hl,bc : ld e,(hl) : ld d,0 : pop hl
        or a : sbc hl,de                                ; HL = its top
        push hl : ld hl,img_h : add hl,bc : ld e,(hl) : pop hl
        ex de,hl : add hl,de : dec hl : ex de,hl        ; DE = its bottom
.clamp  ; (HL = the top, DE = the bottom)
        ld a,h : or a : jr z,.top_ok
        ld l,0 : jp m,.top_ok                           ; (above the window: 0)
        ld l,255
.top_ok ld (ix+LG_R0),l
        ld a,d : or a : jr z,.bot_ok
        ld e,0 : jp m,.bot_ok
        ld e,255
.bot_ok ld (ix+LG_R1),e
        ret

; Carry set if record IX's rows overlap one passed over (rc_skip)
rc_overlaps
        ld a,(rc_ns) : or a : ret z
        ld b,a : ld hl,rc_skip
.o      ld e,(hl) : inc hl : ld d,(hl) : inc hl
        push hl : push de : pop iy
        ld a,(iy+LG_R1) : cp (ix+LG_R0) : jr c,.no
        ld a,(ix+LG_R1) : cp (iy+LG_R0) : jr c,.no
        pop hl : scf : ret
.no     pop hl : djnz .o
        or a : ret

; The window's lines the raster has passed after each interrupt since the vertical
; sync's (the k-th is 2 + 52k lines into it; the window starts 40 lines into it
; at 256x256, 72 at 320x200), less 4 to spare
safe_lines_h db 0, 10, 62, 114, 166, 218
safe_lines_v db 0, 0, 30, 82, 134, 186

; ------------------------------------------------------------------------------
; The compiled meanie: the level's moving meanie compiled (by jit_build) into
; code that draws it a line at a time, with HL at its first byte and B the
; lines left in that character cell:
;   a solid byte:    LD (HL),pixels
;   a partial one:   LD A,(HL) : AND mask : OR pixels : LD (HL),A
;                    (no AND where every pixel drawn is black, colour 3, both
;                    of whose bits OR sets)
;   (a transparent one: nothing)
;   between bytes:   INC HL (a line can cross a 256-byte page)
;   between lines:   LD DE,#800 - bytes : ADD HL,DE : DJNZ same : CALL jit_row : .same
; and RET at the end. Shifts 0 and 2 only: plot_slow uses it where the meanie is
; at an even pixel, wholly in the window, and none of its lines crosses the
; wrap at the end of a 2K block (else plot).
; ------------------------------------------------------------------------------
JIT_BANK = 1                        ; the extra bank the code goes in (after the music player)
SOUND_BANK = JIT_BANK
FRONT_BANK = JIT_BANK                ; (the front end, from FRONT_ORG, above the compiled meanie)
FRONT_ORG = #6400
JIT_END  = FRONT_ORG                ; (the front end above it)
JIT_LAST = (JIT_END >> 8) - 1      ; (the code must start each row below this page)

; A = the image: compile it, at shifts 0 and 2 (jit_img = it, or 255 if it
; isn't coded at both or there wasn't room)
jit_build
        ld (jit_new),a
        ld a,(ga_ram) : ld (p_oldbank0),a
        ld a,255 : ld (jit_img),a
        ld a,(jit_new) : ld e,a : ld d,0
        ld hl,img_bank0 : add hl,de : ld a,(hl)
        ld hl,img_bank2 : add hl,de : and (hl) : and CODED : ret z
        ld hl,img_h : add hl,de : ld a,(hl) : ld (jit_h),a
        ld hl,img_w : add hl,de : ld a,(hl)
        add a,3 : rrca : rrca : and #3F : ld (jit_wb),a
        ld a,(hl) : add a,5 : rrca : rrca : and #3F : ld (jit_wb+1),a
        ; (the decoded image must fit jit_tmp: wb * h pairs of bytes)
        ld b,a : ld a,(jit_h) : ld e,a : ld d,0 : ld hl,0
.size   add hl,de : add hl,de : djnz .size
        ld de,JIT_TMP_SIZE + 1 : or a : sbc hl,de : ret nc
        ld hl,end_sound_bank : ld (jit_emit),hl  ; (after the music player)
        xor a : call jit_compile : ret c
        ld a,1 : call jit_compile : ret c
        ld a,(jit_new) : ld (jit_img),a
        ret

; Compile shift 0 (A = 0) or 2 (A = 1) at jit_emit: carry set if there wasn't room
jit_compile
        ld (jit_s),a
        ld e,a : ld d,0
        ld hl,jit_wb : add hl,de : ld a,(hl) : ld (jit_w),a
        ld hl,(jit_emit) : ex de,hl
        ld a,(jit_s) : add a,a : ld c,a : ld b,0
        ld hl,jit_vecs : add hl,bc : ld (hl),e : inc hl : ld (hl),d
        ; the image's data at this shift, decoded into (pixels, mask) pairs row by row
        ld a,(jit_new) : ld c,a : ld b,0
        ld hl,img_lo0 : ld a,(jit_s) : or a : jr z,.s0
        ld hl,img_lo2
.s0     add hl,bc : ld e,(hl)
        ld bc,NUM_IMAGES : add hl,bc : ld d,(hl)       ; DE = the data
        ld a,RAM_BANK + GFX_BANK : call bank_select
        ld ix,jit_tmp
        ld a,(jit_h) : ld c,a                           ; rows
        xor a : ld (jit_r),a
.drow   push de                                         ; (column 0 of this row)
        ld a,(jit_w) : ld b,a
.dcol   ld a,(de) : ld l,a : ld h,CODE_RPIX>>8 : ld a,(hl) : ld (ix+0),a
        ld h,CODE_RMASK>>8 : ld a,(hl) : ld (ix+1),a
        inc ix : inc ix
        ld a,(jit_h) : add a,e : ld e,a : jr nc,.dnc : inc d   ; the next column's code
.dnc    djnz .dcol
        pop de : inc de
        dec c : jr nz,.drow
        ; then the code, in the JIT bank
        ld a,RAM_BANK + JIT_BANK : call bank_select
        ld ix,jit_tmp
        ld hl,(jit_emit)
        ld a,(jit_h) : ld (jit_r),a
.row    ; room for another row? (at most 7 bytes a byte, and the line step)
        ld a,h : cp JIT_LAST : jr c,.room
        ld a,(p_oldbank0) : call bank_select
        scf : ret
.room   ld c,0                                          ; HL's column in the line
        ld b,0                                          ; this column
.byte   ld a,(ix+1) : cp #FF : jr z,.skip               ; transparent: nothing
        ; INC HL up to this column
.inc    ld a,c : cp b : jr z,.at
        ld (hl),#23 : inc hl : inc c                    ; INC HL
        jr .inc
.at     ld a,(ix+1) : or a : jr nz,.partial
        ld (hl),#36 : inc hl : ld a,(ix+0) : ld (hl),a : inc hl     ; LD (HL),pixels
        jr .skip
.partial ld (hl),#7E : inc hl                           ; LD A,(HL)
        ld a,(ix+0) : or (ix+1) : inc a : jr z,.no_and  ; (no AND if every pixel drawn is
        ld (hl),#E6 : inc hl : ld a,(ix+1) : ld (hl),a : inc hl     ; black: AND mask)
.no_and
        ld (hl),#F6 : inc hl : ld a,(ix+0) : ld (hl),a : inc hl     ; OR pixels
        ld (hl),#77 : inc hl                            ; LD (HL),A
.skip   inc ix : inc ix
        inc b : ld a,(jit_w) : cp b : jr nz,.byte
        ; the end of the line
        ld a,(jit_r) : dec a : ld (jit_r),a
        jr z,.last
        ld (hl),#11 : inc hl                            ; LD DE,#800 - bytes
        xor a : sub c : ld (hl),a : inc hl
        ld a,8 : sbc a,0 : ld (hl),a : inc hl
        ld (hl),#19 : inc hl                            ; ADD HL,DE
        ld (hl),#10 : inc hl : ld (hl),3 : inc hl       ; DJNZ same
        ld (hl),#CD : inc hl                            ; CALL jit_row
        ld (hl),jit_row AND 255 : inc hl : ld (hl),jit_row>>8 : inc hl
        jp .row
.last   ld (hl),#C9 : inc hl                            ; RET
        ld (jit_emit),hl
        ld a,(p_oldbank0) : call bank_select
        or a : ret

; Called by the compiled code past a character row's 8th line: HL (the cell's
; first line #4000 on) to the next row's first line, and B = 8 lines
jit_row
        ld a,h : sub #40 : ld h,a
        ld a,(g_w) : add a,l : ld l,a
        jr nc,.nc : inc h
.nc     res 3,h
        ld b,8
        ret

; Draw p_img at (p_x, p_y): with its compiled code if it's the compiled meanie
; and can be (see above), else with plot
plot_slow
        ld a,(jit_img) : ld b,a : ld a,(p_img) : cp b : jp nz,plot
        ld e,a : ld d,0
        ; left = p_x - xo (0-1023), at an even pixel; col = left / 4
        ld hl,img_xo : add hl,de : ld c,(hl) : ld b,0
        ld hl,(p_x) : or a : sbc hl,bc
        ld a,h : cp 4 : jp nc,plot
        ld a,l : rrca : jp c,plot
        and 1 : ld (jit_s),a                            ; (0: shift 0, 1: shift 2)
        srl h : rr l : srl h : rr l
        ld a,l : ld (hl_col),a
        ld b,a : ld a,(clip_l) : ld c,a : ld a,b : cp c : jp c,plot
        ld a,(jit_s) : ld e,a : ld d,0 : ld hl,jit_wb : add hl,de
        ld a,b : add a,(hl) : jp c,plot
        ld b,a : ld a,(clip_r) : cp b : jp c,plot
        ; top = p_y - yo; wholly in the window's rows: 0 <= top - clip_t <= clip_h - h
        ld a,(p_img) : ld e,a : ld d,0
        ld hl,img_yo : add hl,de : ld c,(hl) : ld b,0
        ld hl,(p_y) : or a : sbc hl,bc : ld (p_firsty),hl
        ld bc,(clip_t) : or a : sbc hl,bc
        ld a,h : or a : jp nz,plot
        ld a,(jit_h) : add a,l : ld b,a                 ; top - clip_t + h (B, and C = 1
        ld a,0 : adc a,0 : ld c,a                       ; if it's 256 or more)
        ld a,(clip_h) : or a : jr z,.h256
        inc c : dec c : jp nz,plot                      ; it must be at most clip_h
        cp b : jp c,plot
        jr .v_ok
.h256   inc c : dec c : jr z,.v_ok                      ; ... or at most 256
        ld a,b : or a : jp nz,plot
.v_ok   ; the character rows it covers: none of its lines may cross a 2K block's end
        ld hl,(p_firsty)
        ld a,l : and 7 : ld (p_y0),a
        srl h : rr l : srl h : rr l : srl h : rr l
        ld a,l : ld (p_row),a : ld c,a                  ; the first row
        ld a,(p_y0) : ld b,a : ld a,(jit_h) : add a,b : dec a
        rrca : rrca : rrca : and #1F : add a,c : ld (jit_r),a   ; the last
        ld a,(jit_s) : ld e,a : ld d,0 : ld hl,jit_wb : add hl,de : ld a,(hl) : ld (jit_w),a
.rows   ld a,c : call jit_row_offset                    ; HL = the row's offset at hl_col
        ld a,(jit_w) : add a,l : ld e,a : ld a,h : adc a,0 : ld d,a
        ld a,d : cp 8 : jr c,.row_ok : jp nz,plot
        ld a,e : or a : jp nz,plot                      ; (ending at #7FF is fine)
.row_ok ld a,(jit_r) : cp c : jr z,.rows_done
        inc c : jr .rows
.rows_done
        ld a,(p_row) : call jit_row_offset
        ld a,(p_y0) : add a,a : add a,a : add a,a : add a,h : ld h,a
        ld a,(back_page) : add a,h : ld h,a
        ld a,(p_y0) : ld b,a : ld a,8 : sub b : ld b,a  ; the lines left in the first cell
        ld a,(jit_s) : add a,a : ld e,a : ld d,0
        push hl : ld hl,jit_vecs : add hl,de : ld e,(hl) : inc hl : ld d,(hl) : pop hl
        ld (jit_jump+1),de
        ld de,(jit_count) : inc de : ld (jit_count),de
        ; call it with the JIT bank paged in
        ld a,(ga_ram) : push af
        ld a,RAM_BANK + JIT_BANK : call bank_select
        call jit_jump
        pop af : jp bank_select
jit_jump jp 0

; HL = (rowoff[A] + hl_col) MOD #800
jit_row_offset
        ld l,a : ld h,rowoff_lo>>8
        ld a,(hl) : inc h : ld h,(hl) : ld l,a
        ld a,(hl_col) : add a,l : ld l,a
        jr nc,.nc : inc h
.nc     ld a,h : and 7 : ld h,a
        ret
