; The machine layer: interrupts and ticks, bank paging, the keyboard, and the two
; screen modes. (The BBC version's equivalents: the vertical sync event, ROMSEL
; and ROMSEL_COPY, key_pressed reading the system VIA, and MODE 1.)

GA       = #7F                      ; gate array (port B)
CRTC_SEL = #BC
CRTC_DAT = #BD
PPI_A    = #F4
PPI_B    = #F5                      ; bit 0: vertical sync
PPI_C    = #F6
PPI_CTRL = #F7

; gate array: select mode 1, both ROMs off, reset its interrupt counter
GA_MODE1 = %10011101

; RAM configurations (gate array %11xxxxxx). RAM_BASE is the base 64K; RAM_BANK
; + n puts extra bank n (0-3, the 6128's second 64K) at #4000-#7FFF instead.
RAM_BASE = %11000000
RAM_BANK = %11000100

; Keys: row * 8 + bit in the keyboard matrix (keys, below)
KEY_UP = 0 : KEY_RIGHT = 1 : KEY_DOWN = 2 : KEY_ENTER = 6
KEY_LEFT = 8 : KEY_COPY = 9
KEY_RETURN = 18 : KEY_SHIFT = 21 : KEY_CONTROL = 23
KEY_P = 27
KEY_0 = 32 : KEY_9 = 33 : KEY_O = 34 : KEY_I = 35 : KEY_L = 36 : KEY_K = 37 : KEY_M = 38
KEY_8 = 40 : KEY_7 = 41 : KEY_U = 42 : KEY_Y = 43 : KEY_H = 44 : KEY_J = 45 : KEY_N = 46 : KEY_SPACE = 47
KEY_6 = 48 : KEY_5 = 49 : KEY_R = 50 : KEY_T = 51 : KEY_G = 52 : KEY_F = 53 : KEY_B = 54 : KEY_V = 55
KEY_4 = 56 : KEY_3 = 57 : KEY_E = 58 : KEY_W = 59 : KEY_S = 60 : KEY_D = 61 : KEY_C = 62 : KEY_X = 63
KEY_1 = 64 : KEY_2 = 65 : KEY_ESC = 66 : KEY_Q = 67 : KEY_TAB = 68 : KEY_A = 69 : KEY_CAPS = 70 : KEY_Z = 71
KEY_JOY_UP = 72 : KEY_JOY_DOWN = 73 : KEY_JOY_LEFT = 74 : KEY_JOY_RIGHT = 75 : KEY_FIRE1 = 76 : KEY_FIRE2 = 77

; Take the machine over from the firmware: both ROMs off (so #0000-#3FFF and
; #C000-#FFFF read RAM), the base 64K, and our interrupt handler at #0038. Call
; with interrupts off; leaves them off.
machine_init
        ld bc,GA*256+GA_MODE1 : out (c),c
        ld a,RAM_BASE : call bank_select
        ld a,#C3 : ld (#0038),a
        ld hl,irq : ld (#0039),hl
        im 1
        ret

; ------------------------------------------------------------------------------
; Interrupts. The gate array interrupts 300 times a second; the one 2 lines into
; vertical sync is the only one that sees PPI port B's bit 0 set. At that one
; the handler counts the vertical sync and reads the keyboard (here, because
; the keyboard is read through the sound chip, which the music player will
; also drive from here).
; ------------------------------------------------------------------------------
irq
        push af : push bc : push de : push hl
        ld b,PPI_B : in a,(c)
        rra : jr nc,.done
        ld hl,vsyncs : inc (hl)
        call scan_keys
.done   pop hl : pop de : pop bc : pop af
        ei
        ret

; Wait for the next vertical sync
wait_vsync
        ld hl,vsyncs : ld a,(hl)
.wait   cp (hl) : jr z,.wait
        ret

; ------------------------------------------------------------------------------
; Bank paging. ga_ram is the RAM configuration paged in (as the BBC's
; ROMSEL_COPY), for anything (the interrupt handler, later) that pages another
; bank in and must put it back.
; ------------------------------------------------------------------------------
bank_select                         ; A = RAM_BASE, or RAM_BANK + n
        ld (ga_ram),a
        push bc
        ld b,GA : out (c),a
        pop bc
        ret

; Check the extra 64K: a different byte at the start and end of each bank and
; of the base RAM at #4000, then read back, then what was there put back (the
; graphics are already loaded). bank_errors = how many were wrong.
bank_test
        ld hl,bank_configs : ld de,bank_kept
.write  ld a,(hl) : or a : jr z,.check
        call bank_select
        ld a,(#4000) : ld (de),a : inc de
        ld a,(#7FFF) : ld (de),a : inc de
        ld a,(hl) : ld (#4000),a : cpl : ld (#7FFF),a
        inc hl : jr .write
.check  ld hl,bank_configs : ld c,0
.read   ld a,(hl) : or a : jr z,.done
        call bank_select
        ld b,a
        ld a,(#4000) : cp b : jr z,.ok1 : inc c
.ok1    ld a,(#7FFF) : cpl : cp b : jr z,.ok2 : inc c
.ok2    inc hl : jr .read
.done   ld a,c : ld (bank_errors),a
        ld hl,bank_configs : ld de,bank_kept
.put    ld a,(hl) : or a : jr z,.base
        call bank_select
        ld a,(de) : ld (#4000),a : inc de
        ld a,(de) : ld (#7FFF),a : inc de
        inc hl : jr .put
.base   ld a,RAM_BASE : jr bank_select
bank_configs db RAM_BASE, RAM_BANK, RAM_BANK + 1, RAM_BANK + 2, RAM_BANK + 3, 0
bank_kept    DEFS 10

; ------------------------------------------------------------------------------
; The keyboard: 10 rows of 8 keys, read through the sound chip's port A (its
; register 14) with the row in PPI port C's low 4 bits. keys[row] has a bit set
; while that key is down.
; ------------------------------------------------------------------------------
scan_keys
        ld bc,PPI_A*256+14 : out (c),c          ; sound chip register 14
        ld bc,PPI_C*256+#C0 : out (c),c         ; ... selected
        ld bc,PPI_C*256+#00 : out (c),c
        ld bc,PPI_CTRL*256+#92 : out (c),c      ; PPI port A as an input
        ld hl,keys
        ld a,#40                                ; read, row 0
.row    ld b,PPI_C : out (c),a
        ld b,PPI_A : in e,(c)
        ld d,a : ld a,e : cpl : cp (hl) : jr z,.same
        ld (hl),a : ld a,1 : ld (keys_changed),a  ; (cmd_keys looks again)
.same   ld a,d
        inc hl : inc a
        cp #4A : jr nz,.row
        ld bc,PPI_CTRL*256+#82 : out (c),c      ; port A an output again
        ld bc,PPI_C*256+#00 : out (c),c
        ret

; A = a key (KEY_...): returns A = 1 if it's down, else 0 (and Z set if up)
key_pressed
        push bc : push hl
        ld c,a : and 7 : ld hl,bit_masks : add a,l : ld l,a
        jr nc,.nc1 : inc h
.nc1    ld b,(hl)                               ; the bit
        ld a,c : rrca : rrca : rrca : and 15    ; the row
        ld hl,keys : add a,l : ld l,a
        jr nc,.nc2 : inc h
.nc2    ld a,(hl) : and b
        pop hl : pop bc
        ret z
        ld a,1 : ret
bit_masks db 1, 2, 4, 8, 16, 32, 64, 128

; ------------------------------------------------------------------------------
; The screen. Two modes, both 39 character rows of 8 lines a frame (312 lines,
; 50Hz) and fitting a 16K buffer:
;   mode 0: 256x256 (32 x 32 characters, 64 bytes a line), sideways levels
;   mode 1: 320x200 (40 x 25 characters, 80 bytes a line), up-and-down levels
; Buffer 0 is at #8000, buffer 1 at #C000.
; ------------------------------------------------------------------------------

; A = 0 or 1: set the CRTC up for that mode and build its line table
set_mode
        ld (cur_mode),a
        or a
        ld hl,crtc_h : ld a,64 : ld c,255
        jr z,.got
        ld hl,crtc_v : ld a,80 : ld c,199
.got    ld (g_w),a : ld (next_row_w + 1),a : ld a,c : ld (g_last),a
        call crtc_set
        call make_rowoff
        jr make_lines

; CRTC registers from a table of (register, value) pairs, ending with #FF
crtc_set
        ld a,(hl) : cp #FF : ret z
        ld b,CRTC_SEL : ld c,a : out (c),c
        inc hl : ld a,(hl)
        ld b,CRTC_DAT : ld c,a : out (c),c
        inc hl
        jr crtc_set

; R2 and R7 centre the picture
crtc_h  db 0,63, 1,32, 2,42, 3,#8E, 4,38, 5,0, 6,32, 7,34, 9,7, #FF
crtc_v  db 0,63, 1,40, 2,46, 3,#8E, 4,38, 5,0, 6,25, 7,30, 9,7, #FF

; line_lo/line_hi[y] = line y's offset in a buffer: (y / 8) * g_w + (y MOD 8) * #800
make_lines
        ld hl,0
        ld de,line_lo
        ld c,32
.row    push hl
        ld b,8
.line   ld a,l : ld (de),a
        inc d : ld a,h : ld (de),a : dec d
        inc e
        ld a,h : add a,8 : ld h,a
        djnz .line
        pop hl
        ld a,(g_w) : add a,l : ld l,a
        jr nc,.nc : inc h
.nc     dec c : jr nz,.row
        ret

; rowoff_lo/rowoff_hi[r] = (r * g_w) MOD #800: where character row r of a level is
; in each line's 2K block (see plot.asm)
make_rowoff
        ld hl,0
        ld de,rowoff_lo
.row    ld a,l : ld (de),a
        inc d : ld a,h : ld (de),a : dec d
        ld a,(g_w) : add a,l : ld l,a
        jr nc,.nc : inc h
.nc     ld a,h : and 7 : ld h,a
        inc e : jr nz,.row
        ret

; HL = the address of line A in the buffer whose page (#80 or #C0) is in back_page
line_ptr
        ld l,a : ld h,line_lo>>8
        ld a,(hl) : inc h : ld h,(hl) : ld l,a
        ld a,(back_page) : add a,h : ld h,a
        ret

; Show buffer `front` (0: #8000, 1: #C000), from its start. The CRTC takes a new
; start address at the start of the next frame, so changing it just after
; vertical sync swaps whole frames.
show_front
        ld a,(front) : rlca : rlca : rlca : rlca : or #20    ; R12: 10 = #8000, 11 = #C000
        ld bc,CRTC_SEL*256+12 : out (c),c
        ld b,CRTC_DAT : out (c),a
        ld bc,CRTC_SEL*256+13 : out (c),c
        ld bc,CRTC_DAT*256+0 : out (c),c
        ret

; Copy the font's digits and colon from the lower ROM (its characters are at #3800,
; 8 bytes each, top row first) to font_digits in the logic bank. The lower ROM
; overlays #0000-#3FFF, where this code is, so a copier in screen buffer 0 does it.
FONT_TMP = #9800 : FONT_COPIER = #9F00
copy_font
        ld hl,.copier : ld de,FONT_COPIER : ld bc,.copier_end - .copier : ldir
        call FONT_COPIER
        ld a,(ga_ram) : push af
        ld a,RAM_BANK + LOGIC_BANK : call bank_select
        ld hl,FONT_TMP : ld de,font_digits : ld bc,11 * 8 : ldir
        pop af : jp bank_select
.copier ld bc,GA*256 + (GA_MODE1 AND #FB) : out (c),c     ; (the lower ROM in)
        ld hl,#3800 + '0' * 8 : ld de,FONT_TMP : ld bc,11 * 8 : ldir
        ld bc,GA*256 + GA_MODE1 : out (c),c                ; (and out)
        ret
.copier_end

; Show buffer A (0 or 1) from byte offset HL (even, 0-#7FE) in it, at the next frame
show_at
        rlca : rlca : rlca : rlca : or #20 : ld d,a     ; R12: 10 = #8000, 11 = #C000
        srl h : rr l                                    ; (in words)
        ld a,h : and 3 : or d
        ld bc,CRTC_SEL*256+12 : out (c),c
        ld b,CRTC_DAT : out (c),a
        ld bc,CRTC_SEL*256+13 : out (c),c
        ld b,CRTC_DAT : out (c),l
        ret

; Fill the buffer at back_page with byte A
fill_back
        ld b,a
        ld a,(back_page) : ld h,a : ld l,0
        ld (hl),b
        ld d,h : ld e,1
        ld bc,#3FFF
        ldir
        ret

; Pens 0-3 and the border from the hardware colours at HL
set_palette
        ld e,0
        ld b,GA
.pen    out (c),e
        ld a,(hl) : out (c),a
        inc hl : inc e
        ld a,e : cp 4 : jr nz,.pen
        ld e,#10 : out (c),e                    ; the border
        ld a,(hl) : out (c),a
        ret
