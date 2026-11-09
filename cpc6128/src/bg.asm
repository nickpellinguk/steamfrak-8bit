; The background: a port of the BBC version's bg_items, unroll_bg, unroll_item,
; store_line and dict_find (unrolling a level's static platforms and ladders into
; the background cache when it loads), and seek_line, paint_line, copy_cell,
; repaint_column and repaint_row (painting the screen from it).
;
; The cache (extra bank CACHE_BANK at #4000, as the BBC version's bank 7 at
; #8000) is a dictionary of the level's different character cells, 8 bytes
; each (a cell is 8 lines of one byte column), and for each line of the level
; (a byte column of a level that scrolls sideways, 32 cells; a character row of
; one that scrolls up and down, 80) three bit-masks (its non-empty cells, and
; bits 8 and 9 of their numbers) and the low byte of each non-empty cell's
; number. bg_lo/bg_hi give each line's address; cell n's line l is at
; BG_DICT + (n >> 8) * #800 + l * #100 + (n AND 255).

CACHE_BANK = 3
BG_LO   = #4000
BG_HI   = #4100
BG_DICT = #4200
BG_TOP  = #6A00

; While a level loads, screen buffer 0 holds the unroller's workings
HASH_LO = #8000 : HASH_HI = #8100   ; per hash, the first cell with it (number + 1)
LINK_LO = #8200 : LINK_HI = #8600   ; per cell, the next with the same hash (number + 1)
OFF_LO  = #8A00 : OFF_HI = #8B00    ; where each line is, from DSTAGE
COLBUF  = #8C00                     ; one byte column of the level, 256 lines
ROWBUF  = #8D00                     ; one character row of an up-and-down level (80 x 8 bytes)
BGREC   = #9000                     ; the background items (bg_items)
DSTAGE  = #9400                     ; the lines, until the dictionary is complete
; a background item
B_IMG = 0 : B_XL = 1 : B_XH = 2 : B_YL = 3 : B_YH = 4 : B_WB = 5 : B_C0L = 6 : B_C0H = 7
B_SIZE = 8
ASSERT BGREC + MAX_BG * B_SIZE <= DSTAGE

; IX = background item A
bg_ix   ld hl,BGREC : ld c,B_SIZE : jp rec_ix

; The background: static platforms (and bouncy ones' springs), then ladders
; (GameMaker's drawing order), with their image, left and top
bg_items
        xor a : ld (num_bg),a : ld (ld_i),a
.plats  ld a,(num_plats) : ld b,a : ld a,(ld_i) : cp b : jr z,.plats_done
        call plat_ix : push ix : pop iy                 ; IY = the platform
        ld a,(iy+PLT_MOVING) : or a : jr nz,.next_plat
        ld a,(num_bg) : call bg_ix
        ld a,(iy+PLT_IMG) : ld (ix+B_IMG),a
        ld a,(iy+PLT_XL) : ld (ix+B_XL),a : ld a,(iy+PLT_XH) : ld (ix+B_XH),a
        ld a,(iy+PLT_YL) : ld (ix+B_YL),a : ld a,(iy+PLT_YH) : ld (ix+B_YH),a
        ld hl,num_bg : inc (hl)
        call spring_item
.next_plat
        ld hl,ld_i : inc (hl) : jr .plats
.plats_done
        xor a : ld (ld_i),a
.lads   ld a,(num_ladders) : ld b,a : ld a,(ld_i) : cp b : jr z,.lads_done
        call lad_ix : push ix : pop iy
        ld a,(num_bg) : call bg_ix
        ld a,(iy+L_IMG) : ld (ix+B_IMG),a
        ld a,(iy+L_XL) : ld (ix+B_XL),a : ld a,(iy+L_XH) : ld (ix+B_XH),a
        ; (drawn where it was placed, above its hidden extension)
        ld l,(iy+L_YL) : ld h,(iy+L_YH) : ld e,(iy+L_EXT) : ld d,0 : add hl,de
        ld (ix+B_YL),l : ld (ix+B_YH),h
        ld hl,num_bg : inc (hl)
        ld hl,ld_i : inc (hl) : jr .lads
.lads_done
        ; for each: left = x - xo, its byte columns [c0, c0 + wb), top = y - yo
        xor a : ld (ld_i),a
.geom   ld a,(num_bg) : ld b,a : ld a,(ld_i) : cp b : ret z
        call bg_ix
        ld a,(ix+B_IMG) : ld hl,img_xo : call look : ld e,a : ld d,0
        ld l,(ix+B_XL) : ld h,(ix+B_XH) : or a : sbc hl,de : ld (ix+B_XL),l : ld (ix+B_XH),h
        ld a,(ix+B_IMG) : ld hl,img_yo : call look : ld e,a
        ld l,(ix+B_YL) : ld h,(ix+B_YH) : or a : sbc hl,de : ld (ix+B_YL),l : ld (ix+B_YH),h
        ld a,(ix+B_IMG) : ld hl,img_w : call look
        ld b,a : ld a,(ix+B_XL) : and 3 : add a,b : add a,3 : rrca : rrca : and #3F
        ld (ix+B_WB),a
        ld l,(ix+B_XL) : ld h,(ix+B_XH) : sra h : rr l : sra h : rr l
        ld (ix+B_C0L),l : ld (ix+B_C0H),h
        ld hl,ld_i : inc (hl) : jr .geom

; Platform IY's spring, if it's bouncy, as the next background item
spring_item
        ld a,(iy+PLT_BOUNCY) : or a : ret z
        call spring_pos
        ld a,(num_bg) : call bg_ix
        ld (ix+B_IMG),IMG_Spring
        ld hl,(p_x) : ld (ix+B_XL),l : ld (ix+B_XH),h
        ld hl,(p_y) : ld (ix+B_YL),l : ld (ix+B_YH),h
        ld hl,num_bg : inc (hl)
        ret

; p_x, p_y = where platform IY's spring goes: under its middle (3 rows higher
; under a log)
spring_pos
        ld a,(iy+PLT_W) : srl a : ld e,a : ld d,0
        ld l,(iy+PLT_XL) : ld h,(iy+PLT_XH) : add hl,de : ld (p_x),hl
        ld a,(iy+PLT_IMG) : ld b,a : ld hl,img_h : call look
        ld c,a : ld a,b
        cp IMG_Log1 : jr c,.not_log : cp IMG_Log5 + 1 : jr nc,.not_log
        ld a,c : sub 3 : ld c,a
.not_log
        ld e,c : ld d,0 : ld l,(iy+PLT_YL) : ld h,(iy+PLT_YH) : add hl,de : ld (p_y),hl
        ret

; ------------------------------------------------------------------------------
; Unrolling the background into the cache, from the unshifted images of its
; platforms and ladders, shifting them as it goes. This runs only when a level
; loads, so it needn't be quick.
; ------------------------------------------------------------------------------
unroll_bg
        ; the dictionary's hash table starts empty
        ld hl,HASH_LO : ld de,HASH_LO + 1 : ld bc,#1FF : ld (hl),0 : ldir
        ld hl,DSTAGE : ld (po),hl                       ; the lines are built here first
        ld hl,0 : ld (u_cnt),hl
        xor a : ld (u_line),a
        ld a,(is_vert) : or a : jp nz,.row_loop

        ; A level that scrolls sideways: each byte column, from the top to line 255
        ld a,4 : ld (mb),a                              ; (columns have 4-byte masks)
.col_loop
        ld hl,COLBUF : ld de,COLBUF + 1 : ld bc,255 : ld (hl),0 : ldir
        ld hl,0 : ld (u_bl),hl : ld hl,256 : ld (u_bh),hl
        xor a : ld (u_i),a
.item_loop
        ld a,(num_bg) : ld b,a : ld a,(u_i) : cp b : jr z,.items_done
        call bg_ix
        ; j = u_line - c0, in [0, wb)?
        ld a,(u_line) : ld l,a : ld h,0 : ld e,(ix+B_C0L) : ld d,(ix+B_C0H) : or a : sbc hl,de
        ld a,h : or a : jr nz,.next_item
        ld a,l : cp (ix+B_WB) : jr nc,.next_item
        ld (u_j),a
        ld hl,COLBUF : ld (u_tb),hl
        call unroll_item
.next_item
        ld hl,u_i : inc (hl) : jr .item_loop
.items_done
        ld hl,COLBUF : ld (u_src),hl
        ld a,32 : ld (u_cells),a
        call store_line
        ld hl,u_line : inc (hl)
        ld a,(level_cols) : cp (hl) : jr nz,.col_loop
        jp .finish

        ; A level that scrolls up and down: each character row, all 80 byte columns
.row_loop
        ld a,10 : ld (mb),a                             ; (rows have 10-byte masks)
.row
        ld hl,ROWBUF : ld de,ROWBUF + 1 : ld bc,80 * 8 - 1 : ld (hl),0 : ldir
        ; the band of level lines [8R, 8R + 8)
        ld a,(u_line) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld (u_bl),hl
        ld de,8 : add hl,de : ld (u_bh),hl
        xor a : ld (u_i),a
.ritem_loop
        ld a,(num_bg) : ld b,a : ld a,(u_i) : cp b : jp z,.ritems_done
        call bg_ix
        ; does it reach the band? top < bh and top + h > bl (signed)
        ld l,(ix+B_YL) : ld h,(ix+B_YH) : ld de,(u_bh) : call signed_less : jr nc,.rnext
        ld a,(ix+B_IMG) : ld hl,img_h : call look : ld e,a : ld d,0
        ld l,(ix+B_YL) : ld h,(ix+B_YH) : add hl,de : ex de,hl
        ld hl,(u_bl) : call signed_less : jr nc,.rnext
        ; each of its byte columns that's on the level
        xor a : ld (u_j),a
.rcol   ld a,(u_j) : ld e,a : ld d,0
        ld l,(ix+B_C0L) : ld h,(ix+B_C0H) : add hl,de
        ld a,h : or a : jr nz,.rcol_next
        ld a,l : cp 80 : jr nc,.rcol_next
        ; tb = ROWBUF + column * 8 - 8R (where level line 0 would be)
        add hl,hl : add hl,hl : add hl,hl : ld de,ROWBUF : add hl,de
        ld de,(u_bl) : or a : sbc hl,de : ld (u_tb),hl
        push ix : call unroll_item : pop ix
.rcol_next
        ld hl,u_j : inc (hl)
        ld a,(ix+B_WB) : cp (hl) : jr nz,.rcol
.rnext  ld hl,u_i : inc (hl) : jp .ritem_loop
.ritems_done
        ld hl,ROWBUF : ld (u_src),hl
        ld a,80 : ld (u_cells),a
        call store_line
        ld hl,u_line : inc (hl)
        ld a,(level_rows) : cp (hl) : jp nz,.row

        ; Now the dictionary is complete, put the lines straight after it in the cache
.finish
        ld a,(ga_ram) : push af
        ld a,RAM_BANK + CACHE_BANK : call bank_select
        ; start = BG_DICT + pages * #800 (at least one page)
        ld hl,(u_cnt) : ld a,l : or a : ld a,h : jr z,.whole : inc a
.whole  or a : jr nz,.paged : inc a
.paged  ld b,a : dec a : ld (pages1),a
        ld a,b : add a,a : add a,a : add a,a : add a,BG_DICT >> 8 : ld d,a : ld e,0
        ld (u_start),de
        ; each line's address: start + its offset; none for lines past the end
        ld b,0
.addr   ld h,BG_LO >> 8 : ld l,b : ld (hl),0 : inc h : ld (hl),0
        ld a,(u_line) : ld c,a : ld a,b : cp c : jr nc,.no_line
        ld h,OFF_LO >> 8 : ld e,(hl) : inc h : ld d,(hl)
        ld hl,(u_start) : add hl,de : ex de,hl
        ld h,BG_LO >> 8 : ld l,b : ld (hl),e : inc h : ld (hl),d
.no_line
        inc b : jr nz,.addr
        ; copy them up
        ld hl,(po) : ld de,DSTAGE : or a : sbc hl,de
        ld a,h : or l : jr z,.copied
        ld b,h : ld c,l : ld hl,DSTAGE : ld de,(u_start) : ldir
.copied pop af : jp bank_select

; Plot byte column u_j of background item u_i into the line buffer at u_tb
unroll_item
        ld a,(u_i) : call bg_ix
        ld a,(ix+B_XL) : and 3 : ld (u_s),a
        ld b,a : ld a,4 : sub b : ld (u_s4),a
        ld a,(ix+B_IMG) : ld hl,img_h : call look : ld (u_h),a
        ; cur = the image's column u_j (if it has one), prev = the one before
        ld a,(ix+B_IMG) : ld hl,img_w : call look
        add a,3 : rrca : rrca : and #3F                  ; its byte columns
        ld b,a : ld a,(u_j) : cp b : ld a,0 : jr nc,.no_cur : inc a
.no_cur ld (u_cur),a
        ld a,(u_s) : or a : jr z,.no_prev
        ld a,(u_j) : or a : jr z,.no_prev
        ld a,1
.no_prev ld (u_prev),a
        ld a,(ix+B_IMG) : ld hl,img_lo0 : call look : ld e,a
        ld a,(ix+B_IMG) : ld hl,img_hi0 : call look : ld d,a
        ld a,(u_h) : ld c,a : ld b,0
        ld a,(u_j) : or a : jr z,.at_col
.mul    ex de,hl : add hl,bc : ex de,hl : dec a : jr nz,.mul
.at_col ld (u_dp),de                                    ; its column u_j's codes
        ex de,hl : or a : sbc hl,bc : ld (u_sp),hl      ; ... and the one before
        ; its rows [r0, r1) that are in the band [u_bl, u_bh)
        ld hl,(u_bl) : ld e,(ix+B_YL) : ld d,(ix+B_YH) : or a : sbc hl,de
        bit 7,h : ld a,0 : jr nz,.r0_ok
        ld a,h : or a : ret nz                          ; (the band starts 256 or more lines down it)
        ld a,l
.r0_ok  ld (u_r0),a : ld b,a : ld a,(u_h) : ld c,a : ld a,b : cp c : ret nc
        ld hl,(u_bh) : ld e,(ix+B_YL) : ld d,(ix+B_YH) : or a : sbc hl,de
        bit 7,h : ret nz
        ld a,h : or a : jr nz,.r1_h
        ld a,l : or a : ret z
        cp c : jr c,.r1_ok
.r1_h   ld a,c
.r1_ok  ld (u_r1),a : ld b,a : ld a,(u_r0) : cp b : ret nc
        ; pt = tb + top, so pt + Y is level line top + Y in the buffer
        ld l,(ix+B_YL) : ld h,(ix+B_YH) : ld de,(u_tb) : add hl,de : ld (u_pt),hl
        ld a,(ga_ram) : push af
        ld a,RAM_BANK + GFX_BANK : call bank_select
        ld a,(u_r0) : ld (u_y),a
.row    ld c,0                                          ; the byte
        ld a,(u_cur) : or a : jr z,.no_c
        ld hl,(u_dp) : ld a,(u_y) : call look           ; the code
        ld l,a : ld h,CODE_RPIX >> 8 : ld c,(hl)        ; (shift 0: its right 4 pixels)
        ld a,(u_s) : or a : jr z,.no_c
        ld b,a : ld a,c
.c_shift srl a : djnz .c_shift
        ld c,a : ld a,(u_s) : ld hl,keep_tab : call look : and c : ld c,a
.no_c   ld a,(u_prev) : or a : jr z,.no_p
        ld hl,(u_sp) : ld a,(u_y) : call look
        ld l,a : ld h,CODE_RPIX >> 8 : ld a,(hl)
        ld b,a : ld a,(u_s4) : ld e,a : ld a,b
.p_shift add a,a : dec e : jr nz,.p_shift
        ld b,a : ld a,(u_s) : ld hl,carry_tab : call look : and b
        or c : ld c,a
.no_p   ld a,c : or a : jr z,.skip
        ; (pt + Y) = its pixels over what's there: the mask is the pixels of C that are
        ; colour 0 (both bits clear)
        ld hl,(u_pt) : ld a,(u_y) : add a,l : ld l,a : jr nc,.nc : inc h
.nc     ld a,c : rrca : rrca : rrca : rrca : or c       ; (a pixel's bits, both halves)
        cpl : and (hl) : or c : ld (hl),a
.skip   ld hl,u_y : inc (hl)
        ld a,(u_r1) : cp (hl) : jr nz,.row
        pop af : jp bank_select

; Pixels kept from this byte, and those carried in from the byte to its left,
; when shifting an image right by 0-3 pixels
keep_tab  db #FF, #77, #33, #11
carry_tab db #00, #88, #CC, #EE

; Store line u_line of the background (u_cells cells at u_src, 8 bytes each) at
; po (which moves on): its 3 masks, then the low byte of each non-empty cell's
; number in the dictionary
store_line
        ld hl,(po) : ld de,DSTAGE : or a : sbc hl,de
        ld a,(u_line) : ld e,a : ld d,OFF_LO >> 8 : ex de,hl : ld (hl),e : inc h : ld (hl),d
        ld hl,cmask : ld de,cmask + 1 : ld bc,29 : ld (hl),0 : ldir
        ld a,(mb) : ld b,a : add a,a : add a,b : ld e,a : ld d,0
        ld hl,(po) : add hl,de : ld (u_np),hl           ; the numbers
        xor a : ld (u_x),a
.cell   ld hl,(u_src) : ld b,8 : xor a
.any    or (hl) : inc hl : djnz .any
        or a : jr z,.empty
        ld hl,(u_src) : call dict_find
        ld hl,(u_np) : ld a,(u_nl) : ld (hl),a : inc hl : ld (u_np),hl
        ; set its bits: non-empty, and bits 8 and 9 of its number
        ld a,(u_x) : and 7 : ld b,a : ld a,#80 : jr z,.bit
.sh     rrca : djnz .sh
.bit    ld c,a                                          ; the bit
        ld a,(u_x) : rrca : rrca : rrca : and 31 : ld e,a : ld d,0
        ld hl,cmask : add hl,de
        ld a,(hl) : or c : ld (hl),a
        ld a,(mb) : ld e,a
        add hl,de : ld a,(u_nh) : rrca : jr nc,.b8 : ld a,(hl) : or c : ld (hl),a
.b8     add hl,de : ld a,(u_nh) : and 2 : jr z,.empty : ld a,(hl) : or c : ld (hl),a
.empty  ld hl,(u_src) : ld de,8 : add hl,de : ld (u_src),hl
        ld hl,u_x : inc (hl)
        ld a,(u_cells) : cp (hl) : jr nz,.cell
        ; the masks, then on past the numbers
        ld a,(mb) : ld b,a : add a,a : add a,b : ld c,a : ld b,0
        ld hl,cmask : ld de,(po) : ldir
        ld hl,(u_np) : ld (po),hl
        ret

; The number (u_nl, u_nh) of the cell at HL in the dictionary, adding it if it's
; new
dict_find
        ld (u_cellp),hl
        ld a,(ga_ram) : push af
        ld a,RAM_BANK + CACHE_BANK : call bank_select
        ; hash: the sum of its bytes
        ld b,8 : xor a
.sum    add a,(hl) : inc hl : djnz .sum
        ld (u_h8),a
        ld l,a : ld h,HASH_LO >> 8 : ld e,(hl) : inc h : ld d,(hl)
.chain  ld a,d : or e : jr z,.new
        dec de : ld (u_nl),de                           ; (u_nl, u_nh)
        call cell_matches : jr z,.done                  ; found it
        ; the next with the same hash
        ld hl,(u_nl) : ld de,LINK_LO : add hl,de : ld e,(hl)
        ld bc,LINK_HI - LINK_LO : add hl,bc : ld d,(hl)
        jr .chain
.new    ; a new cell: the next number
        ld hl,(u_cnt) : ld (u_nl),hl : inc hl : ld (u_cnt),hl
        call cell_ptr : ex de,hl                        ; DE = its line 0 in the dictionary
        ld hl,(u_cellp) : ld b,8
.store  ld a,(hl) : ld (de),a : inc hl : inc d : djnz .store
        ; it goes at the front of its hash's chain
        ld a,(u_h8) : ld l,a : ld h,HASH_LO >> 8 : ld c,(hl) : inc h : ld b,(hl)   ; (the old front)
        push hl
        ld hl,(u_nl) : ld de,LINK_LO : add hl,de : ld (hl),c
        ld de,LINK_HI - LINK_LO : add hl,de : ld (hl),b
        pop hl
        ld de,(u_nl) : inc de : ld (hl),d : dec h : ld (hl),e
.done   pop af : jp bank_select

; HL = line 0 of dictionary cell (u_nl, u_nh); line L is L pages on
cell_ptr
        ld a,(u_nh) : add a,a : add a,a : add a,a : add a,BG_DICT >> 8 : ld h,a
        ld a,(u_nl) : ld l,a
        ret

; Z set if dictionary cell (u_nl, u_nh) is the same as the one at u_cellp
cell_matches
        call cell_ptr : ld de,(u_cellp) : ld b,8
.loop   ld a,(de) : cp (hl) : ret nz
        inc de : inc h : djnz .loop
        xor a                                           ; (Z: the same)
        ret

; ------------------------------------------------------------------------------
; Painting from the cache
; ------------------------------------------------------------------------------

; Find line pl_line's cells from pl_i0 on: load its masks into cmask; src = the
; number of the first non-empty cell at or after pl_i0; pl_x = its mask byte
; and curbit the bit for cell pl_i0. (The cache must be paged in.)
seek_line
        ld a,(pl_line) : ld l,a : ld h,BG_LO >> 8 : ld e,(hl) : inc h : ld d,(hl)
        ld a,(mb) : ld b,a : add a,a : add a,b : ld c,a : ld b,0     ; 3 masks
        ex de,hl : ld de,cmask : ldir
        push hl                                         ; (the numbers start here)
        ; skip the numbers of the non-empty cells before pl_i0 (count its mask bits)
        ld c,0                                          ; the count
        ld hl,cmask : ld a,(pl_i0) : ld b,a
.whole  ld a,b : cp 8 : jr c,.part
        ld a,(hl) : call add_bits : inc hl
        ld a,b : sub 8 : ld b,a : jr .whole
.part   ld a,(hl) : inc b
.top    dec b : jr z,.counted                           ; (only its top B bits)
        rla : jr nc,.top : inc c : jr .top
.counted
        pop hl : ld b,0 : add hl,bc : ld (pl_src),hl
        ld a,(pl_i0) : rrca : rrca : rrca : and 31 : ld (pl_x),a
        ld a,(pl_i0) : and 7 : ld b,a : ld a,#80 : jr z,.bit
.sh     rrca : djnz .sh
.bit    ld (curbit),a
        ret

; C += the number of bits set in A
add_bits
        or a : ret z
.loop   add a,a : jr nc,.no : inc c
.no     jr nz,.loop
        ret

; Paint cells pl_i0..pl_i1 of line pl_line on the screen, from pl_ptr (stepping
; down a column, or along a row)
paint_line
        ld a,(ga_ram) : push af
        ld a,RAM_BANK + CACHE_BANK : call bank_select
        call seek_line
        ld a,(pl_i0) : ld b,a : ld a,(pl_i1) : sub b : ld (cellk),a     ; cells left - 1
.cell   ld a,(pl_x) : ld e,a : ld d,0 : ld hl,cmask : add hl,de
        ld a,(curbit) : and (hl) : jr z,.empty
        ; its dictionary page, from the second and third masks (if the level has more than one)
        ld c,0
        ld a,(pages1) : or a : jr z,.page_ok
        ld a,(mb) : ld e,a : add hl,de
        ld a,(curbit) : and (hl) : jr z,.b8 : inc c
.b8     add hl,de : ld a,(curbit) : and (hl) : jr z,.page_ok : inc c : inc c
.page_ok
        ld hl,(pl_src) : ld e,(hl) : inc hl : ld (pl_src),hl            ; the cell's number
        ld a,c : add a,a : add a,a : add a,a : add a,BG_DICT >> 8 : ld d,a   ; DE = its line 0
        ld hl,(pl_ptr) : ld b,8
.copy   ld a,(de) : ld (hl),a : inc d : ld a,h : add a,8 : ld h,a : djnz .copy
        jr .next
.empty  ld hl,(pl_ptr) : ld b,8 : xor a
.clear  ld (hl),a : ld c,a : ld a,h : add a,8 : ld h,a : ld a,c : djnz .clear
.next   ld hl,curbit : rrc (hl) : jr nc,.same
        ld hl,pl_x : inc (hl)                           ; (rrc puts #80 back)
.same   ld hl,cellk : dec (hl) : jp m,.done
        ; the next cell: down a character row (g_w on), or along one (1 on), wrapping
        ; within the 2K
        ld hl,(pl_ptr) : ld a,(is_vert) : or a : ld e,1 : jr nz,.along
        ld a,(g_w) : ld e,a
.along  ld d,0 : ld a,h : and #F8 : ld b,a              ; (the page, and the line bits: 0)
        ld a,h : and 7 : ld h,a : add hl,de
        ld a,h : and 7 : or b : ld h,a
        ld (pl_ptr),hl
        jp .cell
.done   pop af : jp bank_select

; Repaint byte column A of a level that scrolls sideways, in buffer back_page,
; from the cache
repaint_column
        ld (pl_line),a
        ld l,a : ld h,0                                 ; (row 0: (0 * g_w + A) MOD #800)
        ld a,(back_page) : or h : ld h,a : ld (pl_ptr),hl
        xor a : ld (pl_i0),a : ld a,31 : ld (pl_i1),a
        jp paint_line

; Repaint character row A of a level that scrolls up and down (all 80 columns)
repaint_row
        ld (pl_line),a
        ld l,a : ld h,rowoff_lo >> 8 : ld a,(hl) : inc h : ld h,(hl) : ld l,a
        ld a,(back_page) : or h : ld h,a : ld (pl_ptr),hl
        xor a : ld (pl_i0),a : ld a,79 : ld (pl_i1),a
        jp paint_line
