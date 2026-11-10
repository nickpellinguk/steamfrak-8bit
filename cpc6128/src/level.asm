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
S_SR = 20                           ; (then its state while the level plays: SR_, in logic.asm)
S_SIZE = 36

; the packed level's header (copied to STAGE, which is save area 0, free while loading)
H_COLS = 0 : H_CELLS = 1 : H_BG = 2 : H_TX = 3 : H_TY = 5 : H_FLAGS = 7
H_NPAL = 8 : H_NPLAT = 9 : H_NLAD = 10 : H_NDRAW = 11 : H_NMEAN = 12 : H_NMPLAT = 13
H_SIZE = 14
STAGE_SIZE = 1024                   ; (more than any level needs)

; IX = record A of a table (by shifts and adds: the record sizes are 12, 8, 12 and
; 36 bytes). B and C kept; DE and HL lost.
plat_ix ld l,a : ld h,0 : add hl,hl : add hl,hl : ld d,h : ld e,l   ; IX = platform A (* 12)
        add hl,hl : add hl,de : ld de,plats : jr rec_ix
lad_ix  ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl         ; IX = ladder A (* 8)
        ld de,ladders : jr rec_ix
draw_ix ld l,a : ld h,0 : add hl,hl : add hl,hl : ld d,h : ld e,l   ; IX = drawn thing A (* 12)
        add hl,hl : add hl,de : ld de,draws : jr rec_ix
slow_ix ld l,a : ld h,0 : add hl,hl : add hl,hl : ld d,h : ld e,l   ; IX = slow sprite A (* 36)
        add hl,hl : add hl,hl : add hl,hl : add hl,de : ld de,slows
rec_ix  add hl,de : push hl : pop ix
        ret
        ASSERT PLT_SIZE == 12 && L_SIZE == 8 && D_SIZE == 12 && S_SIZE == 36

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

; Find the highest platform top in [q_y1, q_y2) under column q_x (if two are at
; the same height, the first, as PlatformFind): res_found = 1, res_y = its y and
; res_i = which. (Comparisons unsigned, as the BBC version's.) IX lost.
platform_find
        xor a : ld (res_found),a
        ld a,(num_plats) : or a : ret z
        ld b,a
        ; the tops looked for: y - q_y1 < q_y2 - q_y1 (unsigned)
        ld hl,(q_y2) : ld de,(q_y1) : or a : sbc hl,de : ret c : ret z     ; (none)
        ld a,h : or a : jr nz,.wide
        ld a,l : ld (.span + 1),a
        ld a,b : dec a : call plat_ix
        push ix : pop hl : inc hl : inc hl      ; HL = the last one's y (going down the list)
.loop   ld de,(q_y1)
        ld a,(hl) : sub e : ld e,a : inc hl
        ld a,(hl) : sbc a,d : dec hl            ; (y - q_y1, the high byte)
        jr nz,.next
        ld a,e
.span   cp 0 : call c,.candidate                ; (cp q_y2 - q_y1)
.next   ld de,-PLT_SIZE : add hl,de
        djnz .loop
        ret
; ... a top in range: under q_x? x <= q_x < x + w
.candidate
        push hl : push bc
        push hl : pop ix : dec ix : dec ix      ; IX = its record
        ld hl,(q_x) : ld e,(ix+PLT_XL) : ld d,(ix+PLT_XH) : or a : sbc hl,de : jr c,.no
        ld a,(ix+PLT_W) : add a,e : ld e,a : jr nc,.nc : inc d
.nc     ld hl,(q_x) : or a : sbc hl,de : jr nc,.no
        call .best
.no     pop bc : pop hl
        ret
; ... keep the highest (smallest y), and of those the first (going down the list)
.best   ld a,(res_found) : or a : jr z,.take
        ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH) : ld de,(res_y) : or a : sbc hl,de
        jr c,.take : ret nz
.take   ld a,1 : ld (res_found),a
        ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH) : ld (res_y),hl
        ld a,b : dec a : ld (res_i),a
        ret
; (a range of 256 or more: each platform in full)
.wide   ld a,b : dec a : call plat_ix
.wloop  ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH)
        ld de,(q_y1) : or a : sbc hl,de : jr c,.wnext
        ld l,(ix+PLT_YL) : ld h,(ix+PLT_YH)
        ld de,(q_y2) : or a : sbc hl,de : jr nc,.wnext
        ld hl,(q_x) : ld e,(ix+PLT_XL) : ld d,(ix+PLT_XH) : or a : sbc hl,de : jr c,.wnext
        ld a,(ix+PLT_W) : add a,e : ld e,a : jr nc,.wnc : inc d
.wnc    ld hl,(q_x) : or a : sbc hl,de : jr nc,.wnext
        call .best
.wnext  ld de,-PLT_SIZE : add ix,de
        djnz .wloop
        ret

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
