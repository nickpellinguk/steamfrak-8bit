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
ASSERT B_SIZE == 8                   ; (bg_ix multiplies by it with shifts)

; IX = background item A
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
seek_line
        ld a,(pl_line) : ld l,a : ld h,BG_LO >> 8 : ld e,(hl) : inc h : ld d,(hl)
        ld (pl_masks),de                                ; (its masks, read where they are)
        ld a,(mb) : ld l,a : add a,a : add a,l : ld l,a : ld h,0 : add hl,de
        push hl                                         ; (the numbers start after the 3 masks)
        ; skip the numbers of the non-empty cells before pl_i0 (count its mask bits)
        ex de,hl : ld c,0                               ; (HL = the first mask; C = the count)
        ld d,popcount >> 8
        ld a,(pl_i0) : rrca : rrca : rrca : and 31 : jr z,.part
        ld b,a
.whole  ld e,(hl) : ld a,(de) : add a,c : ld c,a : inc hl
        djnz .whole
.part   ld a,(pl_i0) : and 7 : jr z,.counted
        ld e,a : ld a,(hl) : push hl
        ld hl,topbits : ld d,0 : add hl,de : and (hl)   ; (only its top bits)
        pop hl : ld e,a : ld d,popcount >> 8 : ld a,(de) : add a,c : ld c,a
.counted
        pop hl : ld b,0 : add hl,bc : ld (pl_src),hl
        ld a,(pl_i0) : rrca : rrca : rrca : and 31 : ld (pl_x),a
        ld a,(pl_i0) : and 7 : ld b,a : ld a,#80 : jr z,.bit
.sh     rrca : djnz .sh
.bit    ld (curbit),a
        ret
topbits db #00, #80, #C0, #E0, #F0, #F8, #FC, #FE

; popcount: the number of bits set in each byte
make_popcount
        ld hl,popcount
.byte   ld a,l : ld c,0
.bit    or a : jr z,.done
        add a,a : jr nc,.bit
        inc c : jr .bit
.done   ld (hl),c
        inc l : jr nz,.byte
        ret

; Paint cells pl_i0..pl_i1 of line pl_line on the screen, from pl_ptr (stepping
; down a column, or along a row)
paint_line
        ld a,(ga_ram) : push af
        ld a,RAM_BANK + CACHE_BANK : call bank_select
        call seek_line
        ; the step to the next cell: down a character row (g_w on) or along one (1 on)
        ld a,(is_vert) : or a : ld a,1 : jr nz,.step
        ld a,(g_w)
.step   ld (.adv + 1),a
        ; the main registers: B = cells to do, C = the current mask bit, DE = the next
        ; cell number, HL = the masks' byte; the others: HL = the screen, C = its page
        ld a,(pl_i0) : ld b,a : ld a,(pl_i1) : sub b : inc a : ld b,a
        ld a,(curbit) : ld c,a
        ld de,(pl_src)
        ld hl,(pl_masks) : ld a,(pl_x) : add a,l : ld l,a : jr nc,.nc0
        inc h
.nc0    exx
        ld hl,(pl_ptr) : ld a,h : and #F8 : ld c,a
        exx
.cell   ld a,(hl) : and c : jr z,.empty
        ; its dictionary page, from the second and third masks (if the level has more than one)
        ld a,(pages1) : or a : ld a,BG_DICT >> 8 : jr z,.page_ok
        push de : push hl
        ld a,(mb) : ld e,a : ld d,0 : add hl,de
        ld a,(hl) : and c : add hl,de : ld a,BG_DICT >> 8 : jr z,.b8
        add a,8
.b8     ld e,a : ld a,(hl) : and c : ld a,e : jr z,.b9
        add a,16
.b9     pop hl : pop de
.page_ok
        ex af,af'
        ld a,(de) : inc de                      ; the cell's number
        exx
        ld e,a : ex af,af' : ld d,a             ; DE = its line 0 in the dictionary
        ld a,h : ld b,a
        ld a,(de) : ld (hl),a : inc d : ld a,h : add a,8 : ld h,a
        ld a,(de) : ld (hl),a : inc d : ld a,h : add a,8 : ld h,a
        ld a,(de) : ld (hl),a : inc d : ld a,h : add a,8 : ld h,a
        ld a,(de) : ld (hl),a : inc d : ld a,h : add a,8 : ld h,a
        ld a,(de) : ld (hl),a : inc d : ld a,h : add a,8 : ld h,a
        ld a,(de) : ld (hl),a : inc d : ld a,h : add a,8 : ld h,a
        ld a,(de) : ld (hl),a : inc d : ld a,h : add a,8 : ld h,a
        ld a,(de) : ld (hl),a
        jr .next
.empty  exx
        ld a,h : ld b,a
        ld (hl),0 : add a,8 : ld h,a
        ld (hl),0 : add a,8 : ld h,a
        ld (hl),0 : add a,8 : ld h,a
        ld (hl),0 : add a,8 : ld h,a
        ld (hl),0 : add a,8 : ld h,a
        ld (hl),0 : add a,8 : ld h,a
        ld (hl),0 : add a,8 : ld h,a
        ld (hl),0
.next   ; the next cell on the screen, wrapping within the 2K (the line bits back to 0)
        ld h,b
        ld a,l
.adv    add a,0                                 ; (the step: set above)
        ld l,a : jr nc,.same_page
        ld a,h : inc a : and 7 : or c : ld h,a
.same_page
        exx
        rrc c : jr nc,.same_byte                ; (rrc puts #80 back)
        inc hl
.same_byte
        dec b : jp nz,.cell
        pop af : jp bank_select

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
