; Steam Frak for the Amstrad CPC 6128 - assembled with RASM (see ../build.sh)
;
; Phase 2: the machine layer (src/machine.asm). For now the program checks the
; extra 64K, counts game ticks (one a vertical sync, as the game logic will
; run), reads the keyboard, and shows a test card in each screen buffer (each
; in its own colour, outlined in white) in turn; the test harness (tools/emu)
; pokes want_mode and flip_rate to try both modes and flip speeds.
;
; Memory: the code from #0040 (below #4000, so it stays visible whichever extra
; bank is paged in at #4000), the screen buffers at #8000 and #C000.

        ORG #0040
start
        di
        ld sp,#4000
        call machine_init
        call bank_test
        ld hl,palette : call set_palette
        ld a,(want_mode) : call setup_mode
        ld a,(vsyncs) : ld (last_vsync),a
        ei

main_loop
        call wait_vsync
        ; run a game tick for each vertical sync since the last time round (for now,
        ; just count them)
        ld a,(last_vsync) : ld b,a
        ld a,(vsyncs) : ld (last_vsync),a
        sub b : ld e,a : ld d,0
        ld hl,(ticks) : add hl,de : ld (ticks),hl
        ; a mode change asked for (by the test harness)?
        ld a,(want_mode) : ld hl,cur_mode : cp (hl)
        call nz,setup_mode
        ; show the other buffer every flip_rate frames
        ld hl,flip_count : dec (hl) : jr nz,main_loop
        ld a,(flip_rate) : ld (hl),a
        ld a,(front) : xor 1 : ld (front),a
        call show_front
        jr main_loop

; A = 0 or 1: set that mode up and draw both buffers' test cards
setup_mode
        call set_mode
        ld a,#80 : ld (back_page),a : ld a,#F0 : call test_card     ; buffer 0: pen 1
        ld a,#C0 : ld (back_page),a : ld a,#0F : call test_card     ; buffer 1: pen 2
        jp show_front

; The test card: buffer back_page filled with byte A, the screen's edge in white
; (pen 3), so a screenshot shows the size and position of the picture
test_card
        call fill_back
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

palette db #54, #4C, #56, #4B, #54                     ; black, red, green, white; black border

        INCLUDE "machine.asm"

; ------------------------------------------------------------------------------
; Variables
; ------------------------------------------------------------------------------
vsyncs      db 0                    ; counted by irq
ga_ram      db RAM_BASE             ; the RAM configuration paged in
keys        DEFS 10                 ; the keyboard: a bit set while a key is down
bank_errors db #FF                  ; bank_test's result
front       db 0                    ; buffer on show
back_page   db #80                  ; the buffer being drawn (#80 or #C0)
cur_mode    db 0
g_w         db 64                   ; bytes a line
g_last      db 255                  ; the last line
ticks       dw 0                    ; game ticks run
last_vsync  db 0
want_mode   db 0                    ; (poked by the test harness)
flip_rate   db 25                   ; frames between flips (poked by the test harness)
flip_count  db 25
end_code

        ALIGN 256
line_lo     DEFS 256
line_hi     DEFS 256

        SAVE 'FRAK.BIN',start,end_code-start,DSK,'build/frak.dsk'
        PRINT "Code from ",{hex}start," to ",{hex}end_code
