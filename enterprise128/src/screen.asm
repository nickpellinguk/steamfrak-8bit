; The screen: Nick's line parameter tables (LPTs), one for each buffer (and a
; blank one), and the two screen buffers (see ../PLAN.md, "The idea").
;
; Each buffer is a ring of 20,480 bytes (80 bytes a line, 256 lines, 4 colours,
; 320 pixels across), shown from a start offset `scroll` (even: Nick fetches 2
; bytes a slot) in it: line y of the picture is the 80 bytes from
; (scroll + y * 80) MOD 20480. Nick doesn't wrap, so the playfield is split at
; the first line that starts back at the ring's start (the line before it may run
; on past the ring's end, into the mirror: the ring's first 80 bytes, copied
; there by copy_mirror). Every LPB loads its own LD1, so each block's address is
; worked out from the scroll position.
;
; It's split at lines 63, 64, 127, 128, 191 and 192 too: the 1-line blocks at 63,
; 127 and 191 have VINT, so Dave interrupts (as each ends) at lines 64, 128 and
; 192, and the program knows how far down the raster is (irq_band: restore_chase
; needs it, as the CPC version's needs the gate array's interrupts). The fourth
; interrupt in a frame, as the bottom border's VINT ends, is the vertical sync's.
;
; A table, 312 lines (16 bytes an LPB; Nick reads them in segment #FF):
;   the playfield: 256 lines in up to 8 LPBs, 4 colours, 40 slots (margins 11 and 51)
;   the bottom border, 12 lines, with VINT: Dave interrupts as it ends
;   vertical sync, 12 lines in 4 LPBs, as EXOS makes it
;   the top border, 32 lines; then Nick starts the table again
; The blank table (shown while a level loads) is the same, with border for the
; playfield (and the same VINTs).
;
; Never rewrite the table on show: Nick reads an LPB's line count once, as it
; starts it, but the rest as it goes, so changing the table it's drawing can
; make a frame the wrong length (a TV would roll). The game only sets the table
; of the buffer it's drawing.
;
; How the Z80 sees the buffers (paged in at pages 2 and 3 by screen_select):
;   buffer 0: Nick #0000-#4FFF, its mirror #5000; segments #FC and #FD, the ring at #8000
;   buffer 1: Nick #5100-#A0FF, its mirror #A100; segments #FD and #FE, the ring at #9100

; Nick's ports
NICK_FIXBIAS = #80
NICK_BORDER  = #81
NICK_LPL     = #82                  ; the table's address, bits 4-11
NICK_LPH     = #83                  ; ... bits 12-15 (bits 0-3); bits 6 and 7: see show_table

RING_SIZE  = 20480
LINE_BYTES = 80
LINES      = 256
RING0_NICK = #0000
RING1_NICK = #5100
RING0_Z80  = #8000
RING1_Z80  = #9100

LPT_NICK   = #FC00                  ; the tables, near the top of segment #FF (Nick's #FC00,
LPT_WIN    = #7C00                  ; #FD00 and #FE00), and in the window, with #FF paged in
LPT_BYTES  = #100                   ; (a table's room: 14 LPBs at most)
LPT_BLANK  = LPT_NICK + 2 * LPT_BYTES
LPT_SYNC   = LPT_NICK + 3 * LPT_BYTES   ; (one VINT a frame: see sync_bands)
LPB_BYTES  = 16
FONT_NICK  = #F480                  ; EXOS's font, in video RAM (see copy_font)

MARGIN_L   = 11
MARGIN_R   = 51
MB_PLAYFIELD = %00110010            ; 4 colours, VRES, pixel mode
MB_BORDER  = %00010010              ; (VRES, pixel mode: margins that show none of it)
MB_VINT    = %10000000
MB_RELOAD  = %00000001

; Put the blank table in place, and both buffers' tables from their scroll
; positions
lpt_init
        ld a,(win_seg) : push af
        ld a,SEG_TOP : call bank_select
        ld hl,blank_lpbs : ld de,LPT_BLANK - LPT_NICK + LPT_WIN : ld bc,7 * LPB_BYTES : ldir
        ld hl,lpt_fixed : ld bc,6 * LPB_BYTES : ldir
        ld hl,border_lpb : ld de,LPT_SYNC - LPT_NICK + LPT_WIN : ld bc,LPB_BYTES : ldir
        ld hl,lpt_fixed : ld bc,6 * LPB_BYTES : ldir
        pop af : call bank_select
        xor a : call lpt_set
        ld a,1 : jp lpt_set

; The blank table's playfield: border, with the VINTs at 63, 127 and 191
blank_lpbs
        db 256 - 63, MB_BORDER, #3F, #00 : defs 12, 0
        db 256 - 1, MB_BORDER + MB_VINT, #3F, #00 : defs 12, 0
        db 256 - 63, MB_BORDER, #3F, #00 : defs 12, 0
        db 256 - 1, MB_BORDER + MB_VINT, #3F, #00 : defs 12, 0
        db 256 - 63, MB_BORDER, #3F, #00 : defs 12, 0
        db 256 - 1, MB_BORDER + MB_VINT, #3F, #00 : defs 12, 0
        db 256 - 64, MB_BORDER, #3F, #00 : defs 12, 0

; The sync table's playfield: border, with no VINT
border_lpb
        db 0, MB_BORDER, #3F, #00 : defs 12, 0                      ; (256 lines)

; The LPBs after the playfield
lpt_fixed
        db 256 - 12, MB_BORDER + MB_VINT, #3F, #00 : defs 12, 0      ; bottom border, VINT
        db 256 - 3, #10, #3F, #00 : defs 12, 0                      ; vertical sync (EXOS's)
        db 256 - 4, #10, #06, #3F : defs 12, 0
        db 256 - 1, #10, #3F, #20 : defs 12, 0
        db 256 - 4, #12, #06, #3F : defs 12, 0
        db 256 - 32, MB_BORDER + MB_RELOAD, #3F, #00 : defs 12, 0   ; top border, then again

; Set buffer A's table from its scroll position (scroll0 or scroll1) and palette
; (pal0 or pal1), and copy its mirror
lpt_set
        ld (ls_buf),a
        ; the scroll position, the ring's Nick address, the palette
        or a
        ld hl,(scroll0) : ld de,RING0_NICK : ld ix,pal0
        jr z,.got
        ld hl,(scroll1) : ld de,RING1_NICK : ld ix,pal1
.got    ld (ls_scroll),hl : ld (ls_base),de
        ; k = the lines that start before the ring's end: ceil((RING_SIZE - scroll) / 80)
        ; (0: all 256 of them)
        ld b,h : ld c,l
        ld hl,RING_SIZE : or a : sbc hl,bc      ; HL = RING_SIZE - scroll (> 0)
        ld de,LINE_BYTES : ld c,0               ; C = k
.count  inc c
        or a : sbc hl,de
        jr z,.counted : jr nc,.count
.counted
        ld a,c : ld (ls_k),a
        ; the blocks, with #FF paged in
        ld a,(win_seg) : push af
        ld a,SEG_TOP : call bank_select
        ld a,(ls_buf) : or a
        ld hl,LPT_WIN : jr z,.lpt : ld hl,LPT_WIN + LPT_BYTES
.lpt    ld (ls_ptr),hl
        xor a : ld (ls_cur),a
        ld hl,ls_bounds
.bound  ld a,(hl) : inc hl : push hl
        ld (ls_end),a
        ; (k between the last boundary and this one: a block up to k first)
        ld a,(ls_k) : or a : jr z,.no_k         ; (no wrap)
        ld b,a : ld a,(ls_cur) : cp b : jr nc,.no_k
        ld a,(ls_end) : or a : jr z,.k_in       ; (256)
        cp b : jr c,.no_k : jr z,.no_k
.k_in   ld a,(ls_end) : push af
        ld a,b : ld (ls_end),a : call ls_block
        pop af : ld (ls_end),a
.no_k   call ls_block
        pop hl
        ld a,(ls_end) : or a : jr nz,.bound     ; (until 256)
        ; then the rest
        ld de,(ls_ptr) : ld hl,lpt_fixed : ld bc,6 * LPB_BYTES : ldir
        pop af : call bank_select
        ld a,(ls_buf) : jp copy_mirror
; (the playfield's boundaries, and 256 as 0)
ls_bounds db 63, 64, 127, 128, 191, 192, 0

; The block of lines ls_cur to ls_end (0: 256), at ls_ptr; ls_cur = ls_end after
ls_block
        ld hl,(ls_ptr)
        ld a,(ls_cur) : ld c,a : ld a,(ls_end) : sub c
        neg : ld (hl),a : inc hl                ; (256 - lines)
        ; VINT on the 1-line blocks at 63, 127 and 191
        ld b,MB_PLAYFIELD
        neg : dec a : jr nz,.mb
        ld a,c : and 63 : cp 63 : jr nz,.mb
        ld a,c : cp 255 : jr z,.mb
        ld b,MB_PLAYFIELD + MB_VINT
.mb     ld (hl),b : inc hl
        ld (hl),MARGIN_L : inc hl
        ld (hl),MARGIN_R : inc hl
        ; LD1 = the ring + (scroll + line * 80) MOD 20480
        push hl
        ld l,c : ld h,line_lo >> 8 : ld e,(hl) : inc h : ld d,(hl)
        ld hl,(ls_scroll) : add hl,de
        ld de,RING_SIZE : or a : sbc hl,de : jr nc,.wrapped
        add hl,de
.wrapped
        ld de,(ls_base) : add hl,de : ex de,hl
        pop hl
        ld (hl),e : inc hl : ld (hl),d : inc hl
        ld (hl),0 : inc hl : ld (hl),0 : inc hl
        push ix : pop de : ex de,hl
        ld bc,8 : ldir
        ld (ls_ptr),de
        ld a,(ls_end) : ld (ls_cur),a
        ret

; Copy buffer A's first 80 bytes to its mirror, after its ring's end, for the
; line that runs on past the end. (Puts the buffer being drawn back.)
copy_mirror
        ld c,a : ld a,(back) : push af
        ld a,c : call screen_select
        ld hl,(back_ring) : ld d,h : ld e,l
        ld a,d : add a,RING_SIZE >> 8 : ld d,a
        ld bc,LINE_BYTES : ldir
        pop af : jp screen_select

; Page buffer A in at pages 2 and 3, and set back_ring to where its ring is
screen_select
        ld (back),a
        or a
        ld a,SEG_VIDEO : ld hl,RING0_Z80
        jr z,.got
        ld a,SEG_VIDEO + 1 : ld hl,RING1_Z80
.got    out (PAGE2),a : inc a : out (PAGE3),a
        ld (back_ring),hl
        ret

; Point Nick at the table of buffer `front` (show_lpt), or the blank one
; (show_blank), from the start of the next frame. (Port #83's bits 6 and 7 stay
; set, as EXOS leaves them: then only the address changes, and Nick takes it when
; it next starts the table.)
show_lpt
        ld a,(front) : or a
        ld hl,LPT_NICK : jr z,show_table
        ld hl,LPT_NICK + LPT_BYTES
show_table
        ld a,l : rrca : rrca : rrca : rrca : and #0F : ld l,a
        ld a,h : rlca : rlca : rlca : rlca : and #F0 : or l
        out (NICK_LPL),a
        ld a,h : rrca : rrca : rrca : rrca : and #0F : or #C0 : out (NICK_LPH),a
        ret
show_blank
        ld hl,LPT_BLANK : jr show_table

; Start counting the interrupts in a frame in step (irq_band): show the sync
; table, whose only VINT is the bottom border's, until it's on show (every
; interrupt the vertical sync's: irq_single); then, just after a vertical sync,
; count from 0 and show buffer `front`'s table, which Nick starts at the next
; frame, before its first band. Call with interrupts on.
sync_bands
        ld a,1 : ld (irq_single),a
        ld hl,LPT_SYNC : call show_table
        call wait_vsync : call wait_vsync : call wait_vsync
        di
        xor a : ld (irq_band),a : ld (irq_single),a
        call show_lpt
        ei
        ret

; Copy EXOS's font from video RAM (where it puts it when it starts, at Nick's
; FONT_NICK in segment #FF, row by row: row r of character c at FONT_NICK +
; r * 128 + c; 9 rows) to fe_font in the low RAM: characters 32-127, 8 rows each,
; top first (for the front end; the timer's digits are among them: font_digits).
; Before anything is loaded into #FF over it. (The CPC version copies its own
; from its lower ROM.)
copy_font
        ld a,SEG_TOP : out (PAGE3),a
        ld de,fe_font : ld c,32
.char   ld b,0
.row    push de
        ld l,b : ld h,0
        add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl
        ld de,FONT_NICK : add hl,de             ; (#FF at page 3: Nick's #C000-#FFFF is the Z80's)
        ld e,c : ld d,0 : add hl,de             ; row * 128 + c
        pop de
        ld a,(hl) : ld (de),a : inc de
        inc b : ld a,b : cp 8 : jr nz,.row
        inc c : bit 7,c : jr z,.char
        ld a,(back) : jp screen_select
