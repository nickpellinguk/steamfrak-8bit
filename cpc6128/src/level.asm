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

; IX = record A of a table (by shifts and adds: the record sizes are 12, 8, 12 and
; 20 bytes). B and C kept; DE and HL lost.
plat_ix ld l,a : ld h,0 : add hl,hl : add hl,hl : ld d,h : ld e,l   ; IX = platform A (* 12)
        add hl,hl : add hl,de : ld de,plats : jr rec_ix
lad_ix  ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl         ; IX = ladder A (* 8)
        ld de,ladders : jr rec_ix
draw_ix ld l,a : ld h,0 : add hl,hl : add hl,hl : ld d,h : ld e,l   ; IX = drawn thing A (* 12)
        add hl,hl : add hl,de : ld de,draws : jr rec_ix
slow_ix ld l,a : ld h,0 : add hl,hl : add hl,hl : ld d,h : ld e,l   ; IX = slow sprite A (* 20)
        add hl,hl : add hl,hl : add hl,de : ld de,slows
rec_ix  add hl,de : push hl : pop ix
        ret
        ASSERT PLT_SIZE == 12 && L_SIZE == 8 && D_SIZE == 12 && S_SIZE == 20

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

; Load level A. The loader (loader.asm) is only needed then, so it's kept in the
; base RAM after the levels, at LOADER_STORE, and runs from screen buffer 1
; (LOADER_RUN), which is drawn afresh after a level loads anyway: this copies it
; there and runs it.
LOADER_STORE = #7000 : LOADER_RUN = #C000
load_level
        push af
        ld a,(ga_ram) : push af
        ld a,RAM_BASE : call bank_select
        ld hl,LOADER_STORE : ld de,LOADER_RUN : ld bc,loader_end - loader_start : ldir
        pop af : call bank_select
        pop af
        jp ovl_load_level
