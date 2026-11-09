; The plotter, the draw log, the yoyo string, and the compiled meanie: ports of
; the BBC version's plot, log_sprite/log_line/restore_log, hline, plot_slow and
; jit_build/jit_compile, for the CPC's screen.
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
        ld a,(hl) : and CODED : jp z,.exit          ; (img_bank<shift> follows that: none here?)
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

.col_loop
        ; colw = col + cidx
        ld hl,(p_col) : ld a,(p_cidx) : ld e,a : ld d,0 : add hl,de
        ; BC = back_page + y0 * #800 + (rowoff[row] + colw) MOD #800
        ex de,hl
        ld a,(p_row) : ld l,a : ld h,rowoff_lo>>8
        ld a,(hl) : inc h : ld h,(hl) : ld l,a
        add hl,de
        ld a,(p_y0) : add a,a : add a,a : add a,a : ld b,a
        ld a,h : and 7 : add a,b : ld b,a
        ld a,(back_page) : add a,b : ld b,a : ld c,l
        ; when saving, note the column's screen address
        ld a,(p_mode) : cp PM_SAVE : jr z,.address : cp PM_SAVEONLY : jr nz,.no_address
.address ld hl,(sptr) : ld (hl),c : inc hl : ld (hl),b : inc hl : ld (sptr),hl
.no_address
        ld de,(p_dcol)
        ld a,(p_tab) : ld h,a
        ld a,(p_rows) : ld ixl,a
        exx : ld hl,(sptr) : exx
.do_col call 0                                  ; (the column routine for this mode)
        exx : ld (sptr),hl : exx
        ; next column
        ld hl,(p_dcol) : ld a,(p_hgt) : ld e,a : ld d,0 : add hl,de : ld (p_dcol),hl
        ld hl,p_cidx : inc (hl)
        ld a,(p_cend) : cp (hl) : jr nz,.col_loop
.exit   ld a,(p_oldbank) : jp bank_select

; img_lo<shift> for each shift (img_hi<shift> and img_bank<shift> follow each)
dir_tables  dw img_lo0, img_lo1, img_lo2, img_lo3
col_routines dw col_plot, col_save, col_restore, col_saveonly

; ------------------------------------------------------------------------------
; Column routines: BC = the screen address of the column's first line, DE = its
; image data, H = its mask table's page (the pixels are the page before), IXL =
; the lines to do; save records via HL' (in the other register set).
; ------------------------------------------------------------------------------

; The next line down: #800 on, or past a character row's 8th line, the next row
; (the cell's first line, #4000 back, then g_w on, wrapping within its 2K)
MACRO NEXT_LINE loop
        dec ixl : ret z
        ld a,b : add a,8 : ld b,a
        and #38 : jr nz,{loop}
        call next_row
        jr {loop}
MEND

next_row
        ld a,b : sub #40 : ld b,a
        ld a,(g_w) : add a,c : ld c,a
        jr nc,.nc : inc b
.nc     res 3,b                                 ; (wrapping within the 2K)
        ret

col_plot
.loop   ld a,(de) : inc de
        or a : jp m,.solid                      ; 5 solid pixels: just store them
        jr z,.next                              ; 5 transparent: leave the screen alone
        ld l,a
        ld a,(bc) : and (hl) : dec h : or (hl) : inc h : ld (bc),a
.next   NEXT_LINE .loop
.solid  ld l,a : dec h : ld a,(hl) : inc h : ld (bc),a
        jr .next

col_save
.loop   ld a,(bc) : exx : ld (hl),a : inc hl : exx
        ld a,(de) : inc de
        or a : jr z,.next
        ld l,a
        ld a,(bc) : and (hl) : dec h : or (hl) : inc h : ld (bc),a
.next   NEXT_LINE .loop

col_saveonly
.loop   ld a,(bc) : exx : ld (hl),a : inc hl : exx
        NEXT_LINE .loop

col_restore
.loop   exx : ld a,(hl) : inc hl : exx : ld (bc),a
        NEXT_LINE .loop

; Put back the background saved when an image was drawn with PM_SAVE (or
; PM_SAVEONLY), straight from its save record at sbase
restore_saved
        ld hl,(sbase)
        ld a,(hl) : or a : ret z
        ld (p_cidx),a
        inc hl : ld a,(hl) : ld (p_rows),a : inc hl
.column ld c,(hl) : inc hl : ld b,(hl) : inc hl
        push hl : exx : pop hl : exx
        ld a,(p_rows) : ld ixl,a
        call col_restore
        exx : push hl : exx : pop hl
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
.row_ok ; order the ends: left in p_left, right in hl_right
        ld hl,(q_x) : ld de,(p_x) : or a : sbc hl,de
        ld hl,(p_x) : ld de,(q_x)
        jr nc,.ordered
        ex de,hl
.ordered ld (p_left),hl : ld (hl_right),de
        ld a,l : and 3 : ld (hl_p0),a
        ld a,e : and 3 : ld (hl_p1),a
        ld a,h : cp 4 : ret nc                  ; off the level (beyond 1024, or negative)?
        srl h : rr l : srl h : rr l : ld a,l : ld (hl_c0),a
        ld a,255
        ex de,hl
        ld b,h : ld a,b : cp 4 : ld a,255 : jr nc,.c1_ok
        srl h : rr l : srl h : rr l : ld a,l
.c1_ok  ld (hl_c1),a
        ; the line's row and line in it
        ld hl,(p_y) : ld a,l : and 7 : add a,a : add a,a : add a,a : ld (hl_line),a
        srl h : rr l : srl h : rr l : srl h : rr l : ld a,l : ld (hl_row),a
        ld a,(hl_c0) : ld (hl_col),a
.col    ld a,(hl_col) : ld b,a
        ld a,(clip_l) : ld c,a : ld a,b : cp c : jr c,.next_col
        ld a,(clip_r) : ld c,a : ld a,b : cp c : jr nc,.next_col
        ; which pixels of this byte are on the line?
        ld c,#FF
        ld a,(hl_c0) : cp b : jr nz,.not_first
        ld a,(hl_p0) : ld e,a : ld d,0 : ld hl,left_pixels : add hl,de : ld c,(hl)
.not_first
        ld a,(hl_c1) : cp b : jr nz,.not_last
        ld a,(hl_p1) : ld e,a : ld d,0 : ld hl,right_pixels : add hl,de : ld a,(hl) : and c : ld c,a
.not_last
        ; HL = its address: back_page + line * #800 + (rowoff[row] + col) MOD #800
        ld e,b : ld d,0
        ld a,(hl_row) : ld l,a : ld h,rowoff_lo>>8
        ld a,(hl) : inc h : ld h,(hl) : ld l,a
        add hl,de
        ld a,h : and 7 : ld h,a
        ld a,(hl_line) : add a,h : ld h,a
        ld a,(back_page) : add a,h : ld h,a
        ld de,(sptr)
        ld a,(p_mode) : cp PM_RESTORE : jr z,.restore
        ld a,(hl) : ld (de),a
        ; black is logical colour 1: low bit set, high bit clear, in each masked pixel
        ld a,c : cpl : and (hl) : ld b,a
        ld a,(hl_yel) : or #0F : and c : or b   ; (yellow, colour 3, has both bits)
        ld (hl),a
        jr .advance
.restore ld a,(de) : ld (hl),a
.advance inc de : ld (sptr),de
.next_col
        ld a,(hl_col) : ld b,a : ld a,(hl_c1) : cp b : ret z
        ld hl,hl_col : inc (hl)
        jp .col

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
LOGK_SPRITE7 = 2                    ; saved in another bank (log_bank)
LINE_SAVE   = 24                    ; bytes: the longest line is about 82 pixels

; HL = the log slot for a new entry in the back buffer (or carry set if it's full)
log_slot
        ld a,(back) : ld e,a : ld d,0 : ld hl,log_n : add hl,de
        ld a,(hl) : cp MAX_LOG : ccf : ret c
        ld b,a
        ld a,e : or a : ld a,b : jr z,.got : add a,MAX_LOG
.got    ld l,a : ld h,0                         ; (the slot's index; carry clear)
        ret

; Record slot HL (an index) with kind A, the current p_* and the save area (sfree)
log_record
        push hl
        ld de,log_kind : add hl,de : ld (hl),a
        pop hl : push hl : ld de,log_img : add hl,de : ld a,(p_img) : ld (hl),a
        pop hl : push hl : add hl,hl : ld de,log_x : add hl,de : ld de,(p_x) : ld (hl),e : inc hl : ld (hl),d
        pop hl : push hl : add hl,hl : ld de,log_y : add hl,de : ld de,(p_y) : ld (hl),e : inc hl : ld (hl),d
        pop hl : push hl : add hl,hl : ld de,log_x1 : add hl,de : ld de,(q_x) : ld (hl),e : inc hl : ld (hl),d
        pop hl : add hl,hl : ld de,log_sb : add hl,de : ld de,(sfree) : ld (hl),e : inc hl : ld (hl),d
        ld (sbase),de
        ld a,(back) : ld e,a : ld d,0 : ld hl,log_n : add hl,de : inc (hl)
        ld a,PM_SAVE : ld (p_mode),a
        ret

; Draw image p_img at (p_x, p_y), saving the background, if there's room
log_sprite
        ; room in the save area? sfree + img_sv <= send
        ld a,(p_img) : ld e,a : ld d,0
        ld hl,img_svl : add hl,de : ld c,(hl)
        ld hl,img_svh : add hl,de : ld b,(hl)
        ld hl,(sfree) : add hl,bc : ex de,hl
        ld hl,(send) : or a : sbc hl,de : ret c
        call log_slot : ret c
        ld a,LOGK_SPRITE : call log_record
        call plot
        ld hl,(sptr) : ld (sfree),hl
        ret

; Draw a black line from (p_x, p_y) to (q_x, p_y), saving the background
log_line
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
        ld hl,img_svl : add hl,de : ld c,(hl)
        ld hl,img_svh : add hl,de : ld b,(hl)
        ld hl,(sfree7) : add hl,bc : ex de,hl
        ld hl,(send7) : or a : sbc hl,de : ret c
        call log_slot : ret c
        push hl
        ld de,(sfree) : push de
        ld de,(sfree7) : ld (sfree),de
        ld a,LOGK_SPRITE7 : call log_record
        pop de : ld (sfree),de
        pop hl : ld de,log_bank : add hl,de : ld a,(p_sbank) : ld (hl),a
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
        ld b,(hl)
        ld a,e : or a : ld a,b : jr z,.got : add a,MAX_LOG
.got    ld l,a : ld h,0
        push hl : ld de,log_img : add hl,de : ld a,(hl) : ld (p_img),a
        pop hl : push hl : add hl,hl : ld de,log_x : add hl,de : ld e,(hl) : inc hl : ld d,(hl) : ld (p_x),de
        pop hl : push hl : add hl,hl : ld de,log_y : add hl,de : ld e,(hl) : inc hl : ld d,(hl) : ld (p_y),de
        pop hl : push hl : add hl,hl : ld de,log_x1 : add hl,de : ld e,(hl) : inc hl : ld d,(hl) : ld (q_x),de
        pop hl : push hl : add hl,hl : ld de,log_sb : add hl,de : ld e,(hl) : inc hl : ld d,(hl) : ld (sbase),de
        pop hl : push hl : ld de,log_kind : add hl,de
        ld a,PM_RESTORE : ld (p_mode),a
        ld a,(hl) : pop hl
        cp LOGK_LINE : jr z,.line
        cp LOGK_SPRITE7 : jr z,.other_bank
        call restore_saved
        jr restore_log
.other_bank                                     ; saved in another bank: page it in
        ld de,log_bank : add hl,de
        ld a,(ga_ram) : push af
        ld a,(hl) : call bank_select
        call restore_saved
        pop af : call bank_select
        jp restore_log
.line   call hline
        jp restore_log

; ------------------------------------------------------------------------------
; The compiled meanie: the level's moving meanie compiled (by jit_build) into
; code that draws it a line at a time, with HL at its first byte and B the
; lines left in that character cell:
;   a solid byte:    LD (HL),pixels
;   a partial one:   LD A,(HL) : AND mask : OR pixels : LD (HL),A
;   (a transparent one: nothing)
;   between bytes:   INC HL (a line can cross a 256-byte page)
;   between lines:   LD DE,#800 - bytes : ADD HL,DE : DJNZ same : CALL jit_row : .same
; and RET at the end. Shifts 0 and 2 only: plot_slow uses it where the meanie is
; at an even pixel, wholly in the window, and none of its lines crosses the
; wrap at the end of a 2K block (else plot).
; ------------------------------------------------------------------------------
JIT_BANK = 1                        ; the extra bank the code goes in
JIT_END  = #8000
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
        ld hl,#4000 : ld (jit_emit),hl
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
        ld (hl),#E6 : inc hl : ld a,(ix+1) : ld (hl),a : inc hl     ; AND mask
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
        jr .row
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
