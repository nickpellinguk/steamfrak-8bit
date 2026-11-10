; The level loader: the routines of level.asm and bg.asm only needed while a
; level loads, kept in the base RAM after the levels and run from screen buffer 1
; (see load_level in level.asm). Assembled to run at LOADER_RUN.

fetch_level
        ld hl,level_addr_lo : call look : ld e,a
        ld a,(cur_level) : ld hl,level_addr_hi : call look : ld d,a
        ld a,(ga_ram) : push af
        ld a,RAM_BASE : call bank_select
        ex de,hl : ld de,STAGE : ld bc,STAGE_SIZE : ldir
        pop af : jp bank_select

; The next 3-byte record at rec: x low, y low, then x high (bits 0-1), y high
; (bits 2-3) and palette entry (bits 4-7) -> rx, ry and rimg
next_rec
        ld hl,(rec)
        ld e,(hl) : inc hl : ld c,(hl) : inc hl : ld a,(hl) : inc hl
        ld (rec),hl
        ld b,a
        and 3 : ld d,a : ld (rx),de
        ld a,b : rrca : rrca : and 3 : ld b,a : ld (ry),bc
        dec hl : ld a,(hl)                              ; (the third byte again)
        rrca : rrca : rrca : rrca : and 15
        ld hl,STAGE + H_SIZE : call look : ld (rimg),a
        ret

; Find the highest platform top in [q_y1, q_y2) under column q_x (if two are at
; the same height, the first, as PlatformFind): res_found = 1, res_y = its y and
; res_i = which. (Comparisons unsigned, as the BBC version's.) IX lost.
ovl_load_level
        ld (cur_level),a
        call fetch_level
        ; the level's size (and which way it scrolls), colour and Trogg's start
        ld a,(STAGE + H_CELLS) : ld (level_rows),a
        ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld (level_h),hl
        sub 32 : ld b,0 : jr z,.horizontal
        ld b,1 : add a,32 - 25                          ; (the window is 25 rows)
.horizontal
        ld (row_max),a : ld a,b : ld (is_vert),a
        ld a,(STAGE + H_COLS) : ld (level_cols),a
        ld l,a : ld h,0 : add hl,hl : add hl,hl : push hl   ; the width
        ld de,256 : ld a,b : or a : jr z,.w : ld de,320  ; (the window's)
.w      or a : sbc hl,de : ld (scroll_max),hl
        pop hl : ld de,-10 : add hl,de : ld (x_max),hl
        ld a,(STAGE + H_BG) : ld (level_bg),a
        ld hl,(STAGE + H_TX) : ld (trogg_x0),hl
        ld hl,(STAGE + H_TY) : ld (trogg_y0),hl
        ld a,(STAGE + H_NPLAT) : ld (num_plats),a
        ld a,(STAGE + H_NLAD) : ld (num_ladders),a
        ld a,(STAGE + H_NDRAW) : ld (num_draw),a
        ld a,(STAGE + H_NMEAN) : ld hl,STAGE + H_NMPLAT : add a,(hl) : ld (num_slow),a
        ; the records follow the palette
        ld a,(STAGE + H_NPAL) : ld hl,STAGE + H_SIZE : ld e,a : ld d,0 : add hl,de
        ld (rec),hl

        ; Platforms
        xor a : ld (ld_i),a
.plat_loop
        ld a,(num_plats) : ld b,a : ld a,(ld_i) : cp b : jr z,.plats_done
        call plat_ix
        call next_rec
        ld hl,(rx) : ld (ix+PLT_XL),l : ld (ix+PLT_XH),h : ld (ix+PLT_X0L),l : ld (ix+PLT_X0H),h
        ld hl,(ry) : ld (ix+PLT_YL),l : ld (ix+PLT_YH),h : ld (ix+PLT_Y0L),l : ld (ix+PLT_Y0H),h
        ld a,(rimg) : and #80 : ld (ix+PLT_BOUNCY),a     ; (the palette marks bouncy platforms)
        ld a,(rimg) : and #7F : ld (ix+PLT_IMG),a
        ld hl,img_w : call look : ld (ix+PLT_W),a
        ld (ix+PLT_MOVING),0
        ld hl,ld_i : inc (hl)
        jr .plat_loop
.plats_done

        ; Ladders, reaching up to a platform just above them (GameMaker's LadderAdd)
        xor a : ld (ld_i),a
.lad_loop
        ld a,(num_ladders) : ld b,a : ld a,(ld_i) : cp b : jp z,.lads_done
        call next_rec
        ld hl,(rx) : ld (q_x),hl
        ; a platform with its top in [y - 16, y - 1)?
        ld hl,(ry) : ld de,-LADDER_EXTRA_LENGTH : add hl,de : ld (q_y1),hl
        ld hl,(ry) : dec hl : ld (q_y2),hl
        call platform_find
        ld a,(ld_i) : call lad_ix
        ld hl,(rx) : ld (ix+L_XL),l : ld (ix+L_XH),h
        ld a,(rimg) : ld (ix+L_IMG),a
        ld c,0
        ld a,(res_found) : or a : jr z,.no_ext
        ld a,(ry) : ld hl,res_y : scf : sbc a,(hl) : ld c,a   ; y - top - 1
.no_ext ld (ix+L_EXT),c
        ld hl,(ry) : ld b,0 : or a : sbc hl,bc : ld (ix+L_YL),l : ld (ix+L_YH),h
        ld a,(rimg) : ld hl,img_h : call look
        ld l,a : ld h,0 : ld de,LADDER_EXTRA_LENGTH : add hl,de : add hl,bc
        ld (ix+L_HL),l : ld (ix+L_HH),h
        ld hl,ld_i : inc (hl)
        jp .lad_loop
.lads_done

        ; Keys, gems, bulbs and meanies that don't move, in drawing order
        xor a : ld (num_keys),a : ld (num_gems),a : ld (ld_i),a
.draw_loop
        ld a,(num_draw) : ld b,a : ld a,(ld_i) : cp b : jp z,.draws_done
        call draw_ix
        call next_rec
        ld a,(rimg) : ld (ix+D_IMG),a
        ld hl,img_kind : call look : ld (ix+D_KIND),a
        cp KIND_KEY : jr nz,.not_key : ld hl,num_keys : inc (hl) : .not_key
        cp KIND_GEM : jr nz,.not_gem : ld hl,num_gems : inc (hl) : .not_gem
        ld hl,(rx) : ld (ix+D_XL),l : ld (ix+D_XH),h
        ld hl,(ry) : ld (ix+D_YL),l : ld (ix+D_YH),h
        ; left = x - xo, top = y - yo
        ld a,(rimg) : ld hl,img_yo : call look : ld e,a : ld d,0
        ld hl,(ry) : or a : sbc hl,de : ld (ix+D_TL),l : ld (ix+D_TH),h
        ld a,(rimg) : ld hl,img_xo : call look : ld e,a : ld d,0
        ld hl,(rx) : or a : sbc hl,de : ld (ix+D_LL),l : ld (ix+D_LH),h
        ; byte columns [left >> 2, (left + w + 3) >> 2), within 0-255
        xor a : bit 7,h : jr nz,.c0_ok
        call shr2
.c0_ok  ld (ix+D_C0),a
        ld a,(rimg) : ld hl,img_w : call look
        ld l,(ix+D_LL) : ld h,(ix+D_LH)                 ; (left again: shr2 changed HL)
        ld e,a : ld d,0 : add hl,de : inc hl : inc hl : inc hl
        ld a,h : cp 4 : ld a,255 : jr nc,.c1_st
        call shr2
.c1_st  ld (ix+D_C1),a
        ld hl,ld_i : inc (hl)
        jp .draw_loop
.draws_done

        ; Moving meanies: their records (they come after the moving platforms in
        ; the slow sprite tables)...
        ld a,(STAGE + H_NMPLAT) : ld (ld_i),a
        xor a : ld (ld_j),a
.mean_loop
        ld a,(STAGE + H_NMEAN) : ld b,a : ld a,(ld_j) : cp b : jr z,.means_done
        call next_rec
        ld a,(ld_i) : call slow_ix
        ld a,(rimg) : ld (ix+S_IMG),a
        ld hl,(rx) : ld (ix+S_X0L),l : ld (ix+S_X0H),h
        ld hl,(ry) : ld (ix+S_Y0L),l : ld (ix+S_Y0H),h
        ld hl,ld_i : inc (hl) : ld hl,ld_j : inc (hl)
        jr .mean_loop
.means_done
        ; ... then their settings
        ld a,(STAGE + H_NMPLAT) : ld (ld_i),a
        xor a : ld (ld_j),a
.param_loop
        ld a,(STAGE + H_NMEAN) : ld b,a : ld a,(ld_j) : cp b : jr z,.params_done
        call meanie_settings
        ld hl,(rec) : inc hl : ld (rec),hl
        ld hl,ld_i : inc (hl) : ld hl,ld_j : inc (hl)
        jr .param_loop
.params_done

        ; Moving platforms
        xor a : ld (ld_i),a
.mplat_loop
        ld a,(STAGE + H_NMPLAT) : ld b,a : ld a,(ld_i) : cp b : jr z,.mplats_done
        call moving_platform
        ld hl,(rec) : inc hl : inc hl : ld (rec),hl
        ld hl,ld_i : inc (hl)
        jr .mplat_loop
.mplats_done

        ; Nothing in the unused slow sprite slots
        ld a,(num_slow) : ld (ld_i),a
.unused ld a,(ld_i) : cp MAX_SLOW : jr nc,.unused_done
        call slow_ix : ld (ix+S_KIND),0
        ld hl,ld_i : inc (hl)
        jr .unused
.unused_done

        ; its background, into the cache
        call bg_items
        call unroll_bg
        ; compile the level's moving meanie (no level has more than one kind): the
        ; last slow sprite that isn't a platform
        ld a,255 : ld (jit_img),a
        ld a,(num_slow)
.find   dec a : ret m
        ld (ld_i),a : call slow_ix
        ld a,(ix+S_KIND) : cp SL_PLATFORM : ld a,(ld_i) : jr z,.find
        ld a,(ix+S_IMG) : jp jit_build

; A = HL >> 2 (HL below 1024)
shr2    ld a,l : srl h : rra : srl h : rra
        ret

; The settings of moving meanie ld_i, from the byte at rec
meanie_settings
        ld a,(ld_i) : call slow_ix
        ld hl,(rec) : ld a,(hl)
        ld (ix+S_SIMPLE),0
        bit 7,a : jr z,.s0 : ld (ix+S_SIMPLE),1
.s0     and 127 : ld (ld_p),a
        ld hl,slp_kind : call look : ld (ix+S_KIND),a
        ld a,(ld_p) : ld hl,slp_vf : call look : ld (ix+S_VF),a
        ld a,(ld_p) : ld hl,slp_vi : call look : ld (ix+S_VI),a
        xor a
        ld (ix+S_VY),a : ld (ix+S_WAIT),a
        ld (ix+S_AMINL),a : ld (ix+S_AMINH),a : ld (ix+S_AMAXL),a : ld (ix+S_AMAXH),a
        ld (ix+S_BMINL),a : ld (ix+S_BMINH),a : ld (ix+S_BMAXL),a : ld (ix+S_BMAXH),a
        ld (ix+S_PLAT),255
        ld a,(ix+S_KIND)
        cp SL_SCRUBBLY : jr z,.scrubbly
        cp SL_POGLET : jr z,.poglet
        ; a Hooter
        ld a,(ld_p) : ld hl,slp_wait : call look : ld (ix+S_WAIT),a
        ret
.scrubbly
        ; the platform it's on: PlatformFind(x, y - 1, y + 3)
        ld l,(ix+S_X0L) : ld h,(ix+S_X0H) : ld (q_x),hl
        ld l,(ix+S_Y0L) : ld h,(ix+S_Y0H) : dec hl : ld (q_y1),hl
        inc hl : inc hl : inc hl : inc hl : ld (q_y2),hl
        push ix : call platform_find : pop iy               ; (IY = the Scrubbly)
        ld a,(res_i) : call plat_ix
        ; it walks between its left + 8 and right - 9
        ld l,(ix+PLT_XL) : ld h,(ix+PLT_XH) : ld de,8 : add hl,de
        ld (iy+S_AMINL),l : ld (iy+S_AMINH),h
        ld l,(ix+PLT_XL) : ld h,(ix+PLT_XH) : ld e,(ix+PLT_W) : ld d,0 : add hl,de
        ld de,-9 : add hl,de : ld (iy+S_AMAXL),l : ld (iy+S_AMAXH),h
        ld a,(ld_p) : ld hl,slp_flags : call look : and 1 : ret z
        ld a,(res_i) : ld (iy+S_PLAT),a
        ret
.poglet
        ld a,(ld_p) : ld hl,slp_flags : call look : and 2 : jr z,.on_ladder
        ; its range is set by yoff_min and yoff_max
        ld a,(ld_p) : ld hl,slp_ymin : call look : call y_plus_signed
        ld (ix+S_AMINL),l : ld (ix+S_AMINH),h
        ld a,(ld_p) : ld hl,slp_ymax : call look : call y_plus_signed
        ld (ix+S_AMAXL),l : ld (ix+S_AMAXH),h
        ret
.on_ladder
        ; the ladder it's on: from its top + 30 to its bottom + 13
        push ix : call ladder_below : pop iy
        ld a,(res_i) : call lad_ix
        ld l,(ix+L_YL) : ld h,(ix+L_YH) : ld de,30 : add hl,de
        ld (iy+S_AMINL),l : ld (iy+S_AMINH),h
        ld l,(ix+L_YL) : ld h,(ix+L_YH) : ld e,(ix+L_HL) : ld d,(ix+L_HH) : add hl,de
        ld de,13 : add hl,de : ld (iy+S_AMAXL),l : ld (iy+S_AMAXH),h
        ret

; HL = slow sprite IX's y0 + A (signed)
y_plus_signed
        ld e,a : ld d,0 : bit 7,a : jr z,.pos : dec d
.pos    ld l,(ix+S_Y0L) : ld h,(ix+S_Y0H) : add hl,de
        ret

; The ladder the Poglet at slow sprite IX is on (GameMaker's LadderFind going
; down from y - 16 to y + 4, within 6 pixels of x) -> res_i. IX lost.
ladder_below
        ld l,(ix+S_X0L) : ld h,(ix+S_X0H) : ld (q_x),hl
        ld l,(ix+S_Y0L) : ld h,(ix+S_Y0H) : ld de,-16 : add hl,de : ld (res_y),hl   ; ry
        ld de,16 + 4 : add hl,de : ld (q_y2),hl
        xor a : ld (pf_i),a
.loop   ld a,(num_ladders) : ld b,a : ld a,(pf_i) : cp b : ret z
        call lad_ix
        ; |x - lx| <= 6 ?
        ld hl,(q_x) : ld e,(ix+L_XL) : ld d,(ix+L_XH) : or a : sbc hl,de
        ld a,h : or a : jr z,.pos
        inc a : jr nz,.next
        ld a,l : cp #FA : jr c,.next
        jr .near
.pos    ld a,l : cp 7 : jr nc,.next
.near   ; bottom = ly + lh - 1
        ld l,(ix+L_YL) : ld h,(ix+L_YH) : ld e,(ix+L_HL) : ld d,(ix+L_HH) : add hl,de
        dec hl : ld (pf_bottom),hl
        ; ry < bottom and y2 >= ly ?
        ex de,hl : ld hl,(res_y) : or a : sbc hl,de : jr nc,.next
        ld hl,(q_y2) : ld e,(ix+L_YL) : ld d,(ix+L_YH) : or a : sbc hl,de : jr c,.next
        ld a,(pf_i) : ld (res_i),a
        ; ry = min(y2, bottom); stop if that's y2
        ld hl,(pf_bottom) : ld de,(q_y2) : or a : sbc hl,de : ret nc
        ld hl,(pf_bottom) : ld (res_y),hl
.next   ld hl,pf_i : inc (hl)
        jr .loop

; Moving platform ld_i, from the 2 bytes at rec: its range, found the way
; oPlatform's first step does (scanning for the nearest platforms)
moving_platform
        ld hl,(rec) : ld a,(hl) : ld (ld_p),a : inc hl : ld a,(hl) : ld (ld_f),a
        ld a,(ld_i) : call slow_ix : push ix : pop iy           ; IY = its slow sprite
        ld a,(ld_p) : call plat_ix                              ; IX = its platform
        ld a,(ld_f) : and 64 : ld a,1 : jr z,.m1 : inc a        ; (2: Trogg moves it)
.m1     ld (ix+PLT_MOVING),a
        ld (iy+S_KIND),SL_PLATFORM
        ld a,(ix+PLT_IMG) : ld (iy+S_IMG),a
        ld l,(ix+PLT_XL) : ld h,(ix+PLT_XH) : ld (px),hl
        ld (iy+S_X0L),l : ld (iy+S_X0H),h : ld (iy+S_AMINL),l : ld (iy+S_AMINH),h
        ld (iy+S_AMAXL),l : ld (iy+S_AMAXH),h
        ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH) : ld (py),hl
        ld (iy+S_Y0L),l : ld (iy+S_Y0H),h : ld (iy+S_BMINL),l : ld (iy+S_BMINH),h
        ld (iy+S_BMAXL),l : ld (iy+S_BMAXH),h
        ld a,(ld_p) : ld (iy+S_PLAT),a
        ld (iy+S_WAIT),5
        xor a : ld (iy+S_VF),a : ld (iy+S_VI),a : ld (iy+S_VY),a
        ld a,(ld_f) : rlca : and 1 : ld (iy+S_SIMPLE),a
        ld a,(ix+PLT_W) : ld (pw),a
        ld a,(ix+PLT_IMG) : ld hl,img_h : call look : ld (ph),a
        ; pr = px + pw (the column just right of it), pl = px - 1, pb = py + ph
        ld hl,(px) : ld a,(pw) : ld e,a : ld d,0 : add hl,de : ld (pr),hl
        ld hl,(px) : dec hl : ld (pl),hl
        ld hl,(py) : ld a,(ph) : ld e,a : add hl,de : ld (pb),hl
        ld a,(ld_f) : and 1 : call nz,scan_left
        ld a,(ld_f) : and 2 : call nz,scan_right
        ld a,(ld_f) : and 4 : call nz,scan_up
        ld a,(ld_f) : and 8 : call nz,scan_down
        ; x speed: +1 or -1 if it has a range, y speed likewise
        ld l,(iy+S_AMINL) : ld h,(iy+S_AMINH) : ld e,(iy+S_AMAXL) : ld d,(iy+S_AMAXH)
        or a : sbc hl,de : jr z,.x_still
        ld (iy+S_VI),#FF
        ld a,(ld_f) : and 16 : jr z,.x_still
        ld (iy+S_VI),1
.x_still
        ld l,(iy+S_BMINL) : ld h,(iy+S_BMINH) : ld e,(iy+S_BMAXL) : ld d,(iy+S_BMAXH)
        or a : sbc hl,de : ret z
        ld (iy+S_VY),#FF
        ld a,(ld_f) : and 32 : ret z
        ld (iy+S_VY),1
        ret

; Each scan goes through the platforms from the last to the first (IX), for
; slow sprite IY
scan_start
        xor a : ld (found),a
        ld a,(num_plats) : dec a : ld (pf_i),a
        jp plat_ix
; Next platform: Z set when there are none left
scan_next
        ld de,-PLT_SIZE : add ix,de
        ld hl,pf_i : dec (hl)
        ld a,(hl) : inc a
        ret

; Carry set if platform IX's top is in [py, pb) (unsigned): one PlatformFind(column,
; py, py + ph) would find
top_in_py_pb
        ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH) : ld de,(py) : or a : sbc hl,de : ccf : ret nc
        ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH) : ld de,(pb) : or a : sbc hl,de
        ret

; HL = platform IX's right edge + 1 (x + w)
plat_right
        ld l,(ix+PLT_XL) : ld h,(ix+PLT_XH) : ld e,(ix+PLT_W) : ld d,0 : add hl,de
        ret

; amin = 1 + the rightmost column left of it covered by such a platform
; (scanning left from px - 1); unchanged if there's none
scan_left
        call scan_start
.loop   call top_in_py_pb : jr nc,.no
        ; it must start at or left of pl: qx <= pl
        ld hl,(pl) : ld e,(ix+PLT_XL) : ld d,(ix+PLT_XH) : or a : sbc hl,de : jr c,.no
        ; c = min(pl, qx + qw - 1)
        call plat_right : dec hl : ex de,hl
        ld hl,(pl) : or a : sbc hl,de : jr nc,.have_c
        ld de,(pl)
.have_c ; keep the largest
        ld a,(found) : or a : jr z,.take
        ld hl,(best) : or a : sbc hl,de : jr nc,.no
.take   ld (best),de : ld a,1 : ld (found),a
.no     call scan_next : jr nz,.loop
        ld a,(found) : or a : ret z
        ld hl,(best) : inc hl : ld (iy+S_AMINL),l : ld (iy+S_AMINH),h
        ret

; amax = the leftmost column from pr on covered by such a platform, - pw
scan_right
        call scan_start
.loop   call top_in_py_pb : jr nc,.no
        ; it must end at or right of pr: qx + qw > pr
        call plat_right : ex de,hl
        ld hl,(pr) : or a : sbc hl,de : jr nc,.no
        ; c = max(pr, qx)
        ld l,(ix+PLT_XL) : ld h,(ix+PLT_XH) : ld de,(pr) : or a : sbc hl,de
        jr c,.have_c                                    ; (qx < pr: DE = pr)
        ld e,(ix+PLT_XL) : ld d,(ix+PLT_XH)
.have_c ; (only columns below 1000 are scanned)
        ld hl,999 : or a : sbc hl,de : jr c,.no
        ; keep the smallest
        ld a,(found) : or a : jr z,.take
        ex de,hl : ld de,(best) : push hl : or a : sbc hl,de : pop de : jr nc,.no
.take   ld (best),de : ld a,1 : ld (found),a
.no     call scan_next : jr nz,.loop
        ld a,(found) : or a : ret z
        ld hl,(best) : ld a,(pw) : ld e,a : ld d,0 : or a : sbc hl,de
        ld (iy+S_AMAXL),l : ld (iy+S_AMAXH),h
        ret

; Carry set if platform IX covers column pl or column pr
covers_side
        ld hl,(pl) : ld e,(ix+PLT_XL) : ld d,(ix+PLT_XH) : or a : sbc hl,de : jr c,.try_r
        call plat_right : ex de,hl : ld hl,(pl) : or a : sbc hl,de : ret c
.try_r  ld hl,(pr) : ld e,(ix+PLT_XL) : ld d,(ix+PLT_XH) : or a : sbc hl,de : ccf : ret nc
        call plat_right : ex de,hl : ld hl,(pr) : or a : sbc hl,de
        ret

; bmin = the top of the highest platform beside it (at pl or pr) with its top at
; or above py - 2 (and at least -1)
scan_up
        call scan_start
.loop   call covers_side : jr nc,.no
        ; qy <= py - 2 (signed) and qy >= -1
        ld hl,(py) : dec hl : dec hl : ld e,(ix+PLT_YL) : ld d,(ix+PLT_YH)
        call signed_less : jr c,.no
        ld a,(ix+PLT_YH) : bit 7,a : jr z,.ok_low
        ld a,(ix+PLT_YL) : cp #FF : jr nz,.no
.ok_low ; keep the largest (signed)
        ld a,(found) : or a : jr z,.take
        ld hl,(best) : ld e,(ix+PLT_YL) : ld d,(ix+PLT_YH)
        call signed_less : jr nc,.no
.take   ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH) : ld (best),hl : ld a,1 : ld (found),a
.no     call scan_next : jr nz,.loop
        ld a,(found) : or a : ret z
        ld hl,(best) : ld (iy+S_BMINL),l : ld (iy+S_BMINH),h
        ret

; bmax = the top of the lowest platform beside it with its top at or below py
; (and above 999)
scan_down
        call scan_start
.loop   call covers_side : jr nc,.no
        ; qy >= py and qy <= 998 (unsigned)
        ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH) : ld de,(py) : or a : sbc hl,de : jr c,.no
        ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH) : ld de,999 : or a : sbc hl,de : jr nc,.no
        ; keep the smallest
        ld a,(found) : or a : jr z,.take
        ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH) : ld de,(best) : or a : sbc hl,de : jr nc,.no
.take   ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH) : ld (best),hl : ld a,1 : ld (found),a
.no     call scan_next : jr nz,.loop
        ld a,(found) : or a : ret z
        ld hl,(best) : ld (iy+S_BMAXL),l : ld (iy+S_BMAXH),h
        ret


bg_ix   ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl   ; (* B_SIZE)
        ld de,BGREC : jp rec_ix

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

        INCLUDE "gen/level_tables.asm"
