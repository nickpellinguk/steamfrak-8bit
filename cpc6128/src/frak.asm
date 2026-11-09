; Steam Frak for the Amstrad CPC 6128 - assembled with RASM (see ../build.sh)
;
; Phase 1: the machine taken over from the firmware, the two screen modes, and
; double buffering at vertical sync. For now it draws a test card into each
; screen buffer (each in its own colour, outlined in white) and shows them in
; turn; the test harness (tools/emu) pokes want_mode and flip_rate to try both
; modes and flip speeds.
;
;   mode 0: 256x256, for levels that scroll sideways (64 bytes a line, 16K)
;   mode 1: 320x200, for levels that scroll up and down (80 bytes a line)
;
; Memory: the code from #0040 (below #4000, so it stays visible whichever extra
; bank is paged in at #4000), the screen buffers at #8000 and #C000.

GA      = #7F                       ; gate array (port B)
CRTC_SEL = #BC
CRTC_DAT = #BD
PPI_B   = #F5                       ; bit 0: vertical sync

; gate array: select mode 1, both ROMs off, reset its interrupt counter
GA_MODE1 = %10011101
GA_RAM0  = %11000000                ; the base 64K, as the firmware leaves it

        ORG #0040
start
        di
        ld sp,#4000
        ld bc,GA*256+GA_MODE1 : out (c),c
        ld bc,GA*256+GA_RAM0 : out (c),c
        ; our interrupt handler at the Z80's IM 1 address (RAM, the lower ROM is off)
        ld a,#C3 : ld (#0038),a
        ld hl,irq : ld (#0039),hl
        im 1
        call set_palette
        ld a,(want_mode) : call setup_mode
        ei

main_loop
        call wait_vsync
        ; a mode change asked for (by the test harness)?
        ld a,(want_mode) : ld hl,cur_mode : cp (hl)
        call nz,setup_mode
        ; show the other buffer every flip_rate frames
        ld hl,flip_count : dec (hl) : jr nz,main_loop
        ld a,(flip_rate) : ld (hl),a
        ld a,(front) : xor 1 : ld (front),a
        call set_screen_start
        jr main_loop

; The vertical sync: the gate array interrupts 300 times a second, and the one
; that comes 2 lines into vertical sync sees PPI port B's bit 0 set
irq
        push af : push bc
        ld b,PPI_B : in a,(c)
        rra : jr nc,.not_vsync
        ld a,(vsyncs) : inc a : ld (vsyncs),a
.not_vsync
        pop bc : pop af
        ei
        ret

wait_vsync
        ld hl,vsyncs : ld a,(hl)
.wait   cp (hl) : jr z,.wait
        ret

; Show buffer `front` (0: #8000, 1: #C000), from its start. The CRTC takes a new
; start address at the start of the next frame, so changing it just after
; vertical sync swaps whole frames.
set_screen_start
        ld a,(front) : rlca : rlca : rlca : rlca : or #20    ; R12: 10 = #8000, 11 = #C000
        ld bc,CRTC_SEL*256+12 : out (c),c
        ld b,CRTC_DAT : out (c),a
        ld bc,CRTC_SEL*256+13 : out (c),c
        ld bc,CRTC_DAT*256+0 : out (c),c
        ret

; A = 0 or 1: set the CRTC up for that mode and draw both buffers' test cards
setup_mode
        ld (cur_mode),a
        or a
        ld hl,crtc_h : ld a,64 : ld c,255
        jr z,.got
        ld hl,crtc_v : ld a,80 : ld c,199
.got    ld (g_w),a : ld a,c : ld (g_last),a
        call crtc_set
        call make_lines
        ld a,#80 : ld (cur_page),a : ld b,#F0 : call test_card     ; buffer 0: pen 1
        ld a,#C0 : ld (cur_page),a : ld b,#0F : call test_card     ; buffer 1: pen 2
        jr set_screen_start

; CRTC registers from a table of (register, value) pairs, ending with #FF
crtc_set
        ld a,(hl) : cp #FF : ret z
        ld b,CRTC_SEL : ld c,a : out (c),c
        inc hl : ld a,(hl)
        ld b,CRTC_DAT : ld c,a : out (c),c
        inc hl
        jr crtc_set

; 39 character rows of 8 lines (312 lines, 50Hz) in both; R2 and R7 centre the picture
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

; HL = the address of line A in buffer cur_page
line_ptr
        ld l,a : ld h,line_lo/256
        ld a,(hl) : inc h : ld h,(hl) : ld l,a
        ld a,(cur_page) : add a,h : ld h,a
        ret

; The test card: buffer cur_page filled with byte B, the screen's edge in white
; (pen 3), so a screenshot shows the size and position of the picture
test_card
        ld a,(cur_page) : ld h,a : ld l,0
        ld (hl),b
        ld d,h : ld e,1
        ld bc,#3FFF
        ldir
        xor a : call white_line
        ld a,(g_last) : call white_line
        ld c,0
.side   ld a,c : call line_ptr
        ld a,(hl) : or #88 : ld (hl),a              ; the leftmost pixel
        ld a,(g_w) : dec a : add a,l : ld l,a
        jr nc,.nc : inc h                           ; (an 80-byte line can cross a page)
.nc     ld a,(hl) : or #11 : ld (hl),a              ; the rightmost pixel
        ld a,(g_last) : cp c : ret z
        inc c
        jr .side

white_line
        call line_ptr
        ld (hl),#FF
        ld d,h : ld e,l : inc de
        ld a,(g_w) : dec a : ld c,a : ld b,0
        ldir
        ret

; Pens 0-3 and the border (hardware colour numbers)
set_palette
        ld hl,palette : ld e,0
        ld b,GA
.pen    out (c),e
        ld a,(hl) : out (c),a
        inc hl : inc e
        ld a,e : cp 4 : jr nz,.pen
        ld e,#10 : out (c),e                        ; the border
        ld a,(hl) : out (c),a
        ret
palette db #54, #4C, #56, #4B, #54                     ; black, red, green, white; black border

; ------------------------------------------------------------------------------
; Variables
; ------------------------------------------------------------------------------
vsyncs     db 0                     ; counted by irq
front      db 0                     ; buffer on show
want_mode  db 0                     ; (poked by the test harness)
cur_mode   db 0
flip_rate  db 25                    ; frames between flips (poked by the test harness)
flip_count db 25
g_w        db 64                    ; bytes a line
g_last     db 255                   ; the last line
cur_page   db #80
end_code

        ALIGN 256
line_lo    DEFS 256
line_hi    DEFS 256

        SAVE 'FRAK.BIN',start,end_code-start,DSK,'build/frak.dsk'
        PRINT "Code from ",{hex}start," to ",{hex}end_code
