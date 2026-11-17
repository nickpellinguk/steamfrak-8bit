; The machine layer: Dave's paging, interrupts and keyboard. (The CPC version's
; equivalents, in ../cpc6128/src/machine.asm: the gate array's RAM
; configurations and interrupts, and the PPI and the sound chip's port A for the
; keyboard.) The screen, Nick's line parameter tables, is in screen.asm.
;
; The ports, as MAME's and ep128emu's Enterprise emulations have them:

; Dave
PAGE0    = #B0                      ; the segment at #0000-#3FFF (B1-B3: the other pages)
PAGE1    = #B1
PAGE2    = #B2
PAGE3    = #B3
DAVE_INT = #B4                      ; write: bits 0, 2, 4, 6 enable the 1kHz/50Hz, 1Hz, INT1
                                    ; (Nick's VINT) and INT2 interrupts; bits 1, 3, 5, 7
                                    ; reset their latches. Read: bits 1, 3, 5, 7 the latches
DAVE_KEY = #B5                      ; write: the keyboard row (bits 0-3); read: its keys (0: down)
DAVE_JKL = #B6                      ; read: bits 0-2 the external joystick's J, K, L lines
DAVE_SYS = #BF                      ; wait states and the clock

INT_VINT = %00110000                ; INT1 (VINT) enabled, and its latch reset

; Segments: the 128's own RAM is #F8-#FB; video RAM (which Nick reads) #FC-#FF
SEG_LOW   = #F8                     ; the program, at page 0
SEG_VIDEO = #FC
SEG_TOP   = #FF                     ; (the line parameter tables are here)

; EXOS calls (RST #30, then the function's number), while EXOS still runs
EXOS_ALLOC_SEGMENT = 24             ; out: C the segment; A 0 (or #7F: shared with EXOS)

; Keys: row * 8 + bit in the keyboard matrix (keys, below), as Dave reads them
KEY_N = 0 : KEY_BACKSLASH = 1 : KEY_B = 2 : KEY_C = 3 : KEY_V = 4 : KEY_X = 5 : KEY_Z = 6 : KEY_SHIFT = 7
KEY_H = 8 : KEY_LOCK = 9 : KEY_G = 10 : KEY_D = 11 : KEY_F = 12 : KEY_S = 13 : KEY_A = 14 : KEY_CONTROL = 15
KEY_U = 16 : KEY_Q = 17 : KEY_Y = 18 : KEY_R = 19 : KEY_T = 20 : KEY_E = 21 : KEY_W = 22 : KEY_TAB = 23
KEY_7 = 24 : KEY_1 = 25 : KEY_6 = 26 : KEY_4 = 27 : KEY_5 = 28 : KEY_3 = 29 : KEY_2 = 30 : KEY_ESC = 31
KEY_F4 = 32 : KEY_F8 = 33 : KEY_F3 = 34 : KEY_F6 = 35 : KEY_F5 = 36 : KEY_F7 = 37 : KEY_F2 = 38 : KEY_F1 = 39
KEY_8 = 40 : KEY_9 = 42 : KEY_MINUS = 43 : KEY_0 = 44 : KEY_CARET = 45 : KEY_ERASE = 46
KEY_J = 48 : KEY_K = 50 : KEY_SEMICOLON = 51 : KEY_L = 52 : KEY_COLON = 53 : KEY_RBRACKET = 54
KEY_STOP = 56 : KEY_DOWN = 57 : KEY_RIGHT = 58 : KEY_UP = 59 : KEY_HOLD = 60 : KEY_LEFT = 61 : KEY_ENTER = 62 : KEY_ALT = 63
KEY_M = 64 : KEY_DEL = 65 : KEY_COMMA = 66 : KEY_SLASH = 67 : KEY_STOP_ = 68 : KEY_SHIFT_R = 69 : KEY_SPACE = 70 : KEY_INS = 71
KEY_I = 72 : KEY_O = 74 : KEY_AT = 75 : KEY_P = 76 : KEY_LBRACKET = 77
; The CPC version's joystick (and its two fire buttons) is the Enterprise's own,
; built in: the cursor keys, with Space as fire. (The external joysticks, on port
; #B6, are for later.)
KEY_JOY_UP = KEY_UP : KEY_JOY_DOWN = KEY_DOWN : KEY_JOY_LEFT = KEY_LEFT : KEY_JOY_RIGHT = KEY_RIGHT
KEY_FIRE1 = KEY_SPACE : KEY_FIRE2 = KEY_SPACE

; Take the machine over from EXOS: the stack at the top of page 0, our interrupt
; handler at #0038, interrupt mode 1, the program's own segments paged in, and
; Nick's VINT the only interrupt. Call with interrupts off; leaves them off.
machine_init
        pop hl                                  ; (the stack moves)
        ld sp,#4000
        push hl
        xor a : out (DAVE_INT),a
        ld a,#C3 : ld (#0038),a
        ld hl,irq : ld (#0039),hl
        im 1
        ld a,SEG_TOP : call bank_select
        xor a : call screen_select
        ld a,INT_VINT : out (DAVE_INT),a
        ret

; ------------------------------------------------------------------------------
; Interrupts: only Nick's VINT, which Dave sees as INT1 and latches as VINT ends,
; once a frame, 12 lines after the playfield (see screen.asm). The handler counts
; the vertical sync, shows the buffer the game has finished drawing (if it asked:
; flip_pending), reads the keyboard and runs the sound (sound.asm).
; ------------------------------------------------------------------------------
irq
        push af : push bc : push hl
        ld a,INT_VINT : out (DAVE_INT),a        ; (reset the latch)
        ld hl,vsyncs : inc (hl)
        ld a,(flip_pending) : or a : call nz,.flip
        call scan_keys
        call snd_tick                           ; (the music and sound effects: stubs for now)
        pop hl : pop bc : pop af
        ei
        ret
; Show the buffer drawn: Nick starts its table at the start of the next frame,
; which the raster hasn't reached yet (44 lines on)
.flip   ld a,(flip_buf) : ld (front),a
        call show_lpt
        xor a : ld (flip_pending),a
        ret

; Wait for the next vertical sync
wait_vsync
        ld hl,vsyncs : ld a,(hl)
.wait   cp (hl) : jr z,.wait
        ret

; ------------------------------------------------------------------------------
; Paging. Page 0 is the program's (SEG_LOW), page 1 the window the program's
; other segments are paged into (as the CPC's #4000-#7FFF), and pages 2 and 3
; the screen buffer being drawn (screen_select). win_seg is the segment in the
; window, for anything (the interrupt handler, later) that pages another in and
; must put it back.
; ------------------------------------------------------------------------------
bank_select                         ; A = the segment for the window
        ld (win_seg),a
        out (PAGE1),a
        ret

; Check every RAM segment: a different byte near the start and end of each (clear of
; page 0's restart vectors and stack, as #F8 is checked too), then
; read back, then what was there put back. bank_errors = how many were wrong.
bank_test
        ld a,(win_seg) : push af
        ld hl,bank_kept : ld c,#F8
.write  ld a,c : call bank_select
        ld a,(#4100) : ld (hl),a : inc hl
        ld a,(#7EF0) : ld (hl),a : inc hl
        ld a,c : ld (#4100),a : cpl : ld (#7EF0),a
        inc c : jr nz,.write
        ld b,0 : ld c,#F8
.read   ld a,c : call bank_select
        ld a,(#4100) : cp c : jr z,.ok1 : inc b
.ok1    ld a,(#7EF0) : cpl : cp c : jr z,.ok2 : inc b
.ok2    inc c : jr nz,.read
        ld a,b : ld (bank_errors),a
        ld hl,bank_kept : ld c,#F8
.put    ld a,c : call bank_select
        ld a,(hl) : ld (#4100),a : inc hl
        ld a,(hl) : ld (#7EF0),a : inc hl
        inc c : jr nz,.put
        pop af : jp bank_select

; ------------------------------------------------------------------------------
; The keyboard: 10 rows of 8 keys, a row chosen by writing it to Dave's port
; #B5 and its keys read back from it (0: down). keys[row] has a bit set while
; that key is down.
; ------------------------------------------------------------------------------
scan_keys
        ld hl,keys
        xor a
.row    out (DAVE_KEY),a
        ld c,a
        in a,(DAVE_KEY) : cpl
        cp (hl) : jr z,.same
        ld (hl),a : ld a,1 : ld (keys_changed),a  ; (the game looks again)
.same   inc hl
        ld a,c : inc a
        cp 10 : jr nz,.row
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
