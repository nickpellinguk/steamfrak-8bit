; The level loader: a port of the BBC version's fetch_level, load_level and their
; helpers. All the levels are kept packed in the base RAM at #4000 (PACK, as the
; BBC version keeps them in HAZEL and ANDY; see pack_level in its converter for
; the format). load_level unpacks one into the level tables, working out what
; GameMaker worked out when a room started (ladders' hidden extensions, moving
; platforms' ranges, the platform each Scrubbly walks and the ladder each Poglet
; climbs).
;
; The tables are arrays of records (the BBC version's are separate arrays per
; field): IX points at one, (ix+PLT_XL) and so on are its fields, 16-bit ones low
; byte first.

; a platform
PLT_XL = 0 : PLT_XH = 1 : PLT_YL = 2 : PLT_YH = 3 : PLT_W = 4
PLT_X0L = 5 : PLT_X0H = 6 : PLT_Y0L = 7 : PLT_Y0H = 8 : PLT_MOVING = 9 : PLT_IMG = 10 : PLT_BOUNCY = 11
PLT_SIZE = 12
; a ladder, including its hidden extension
L_XL = 0 : L_XH = 1 : L_YL = 2 : L_YH = 3 : L_HL = 4 : L_HH = 5 : L_EXT = 6 : L_IMG = 7
L_SIZE = 8
; a key, gem, bulb or meanie that doesn't move, in drawing order
D_IMG = 0 : D_XL = 1 : D_XH = 2 : D_YL = 3 : D_YH = 4 : D_C0 = 5 : D_C1 = 6 : D_KIND = 7
D_LL = 8 : D_LH = 9 : D_TL = 10 : D_TH = 11
D_SIZE = 12
; a moving platform or meanie (a "slow sprite")
S_KIND = 0 : S_IMG = 1 : S_X0L = 2 : S_X0H = 3 : S_Y0L = 4 : S_Y0H = 5
S_AMINL = 6 : S_AMINH = 7 : S_AMAXL = 8 : S_AMAXH = 9 : S_BMINL = 10 : S_BMINH = 11
S_BMAXL = 12 : S_BMAXH = 13 : S_VF = 14 : S_VI = 15 : S_VY = 16 : S_PLAT = 17
S_WAIT = 18 : S_SIMPLE = 19
S_SIZE = 20

; the packed level's header (copied to STAGE, which is save area 0, free while loading)
H_COLS = 0 : H_CELLS = 1 : H_BG = 2 : H_TX = 3 : H_TY = 5 : H_FLAGS = 7
H_NPAL = 8 : H_NPLAT = 9 : H_NLAD = 10 : H_NDRAW = 11 : H_NMEAN = 12 : H_NMPLAT = 13
H_SIZE = 14
STAGE_SIZE = 1024                   ; (more than any level needs)

; IX = record A of the table at HL, of C bytes each
rec_ix
        ld e,c : ld d,0
        or a : jr z,.done
        ld b,a
.add    add hl,de : djnz .add
.done   push hl : pop ix
        ret
plat_ix ld hl,plats : ld c,PLT_SIZE : jr rec_ix       ; IX = platform A
lad_ix  ld hl,ladders : ld c,L_SIZE : jr rec_ix     ; IX = ladder A
draw_ix ld hl,draws : ld c,D_SIZE : jr rec_ix       ; IX = drawn thing A
slow_ix ld hl,slows : ld c,S_SIZE : jr rec_ix       ; IX = slow sprite A

; A = the byte at HL + A (a table lookup)
look    add a,l : ld l,a : ld a,h : adc a,0 : ld h,a
        ld a,(hl)
        ret

; Carry set if HL < DE, as signed numbers (HL, DE lost)
signed_less
        ld a,h : xor #80 : ld h,a
        ld a,d : xor #80 : ld d,a
        or a : sbc hl,de
        ret

; Copy level A from the pack to STAGE
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
platform_find
        xor a : ld (res_found),a
        ld a,(num_plats) : or a : ret z
        dec a : ld (pf_i),a
        call plat_ix
.loop   ; q_y1 <= y < q_y2, x <= q_x < x + w ?
        ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH)
        ld de,(q_y1) : or a : sbc hl,de : jr c,.next
        ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH)
        ld de,(q_y2) : or a : sbc hl,de : jr nc,.next
        ld hl,(q_x) : ld e,(ix+PLT_XL) : ld d,(ix+PLT_XH) : or a : sbc hl,de : jr c,.next
        ld a,(ix+PLT_W) : add a,e : ld e,a : jr nc,.nc : inc d
.nc     ld hl,(q_x) : or a : sbc hl,de : jr nc,.next
        ; keep the highest (smallest y), and of those the first (going down the list)
        ld a,(res_found) : or a : jr z,.take
        ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH) : ld de,(res_y) : or a : sbc hl,de
        jr c,.take : jr nz,.next
.take   ld a,1 : ld (res_found),a
        ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH) : ld (res_y),hl
        ld a,(pf_i) : ld (res_i),a
.next   ld de,-PLT_SIZE : add ix,de
        ld hl,pf_i : dec (hl)
        jp p,.loop
        ret

; Load level A
load_level
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
