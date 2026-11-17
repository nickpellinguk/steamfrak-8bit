; The screen: Nick's line parameter tables (LPTs), one for each buffer, and the
; two screen buffers (see ../PLAN.md, "The idea").
;
; Each buffer is a ring of 20,480 bytes (80 bytes a line, 256 lines, 4 colours,
; 320 pixels across), shown from a start offset `scroll` (even: Nick fetches 2
; bytes a slot) in it: line y of the picture is the 80 bytes from
; (scroll + y * 80) MOD 20480. Nick doesn't wrap, so the playfield is two LPBs:
; the lines that start before the ring's end (the last of them may run on past
; it, into the mirror: the ring's first 80 bytes, copied there by copy_mirror),
; then the rest, from the ring's start.
;
; A table, 8 LPBs, 312 lines (16 bytes each; Nick reads them at the top of segment #FF):
;   0, 1  the playfield: 256 lines, 4 colours, 40 slots (margins 11 and 51)
;   2     the bottom border, 12 lines, with VINT: Dave interrupts as it ends
;   3-6   vertical sync, 12 lines, as EXOS makes it
;   7     the top border, 32 lines; then Nick starts the table again
;
; How the Z80 sees the buffers (paged in at pages 2 and 3 by screen_select):
;   buffer 0: Nick #0000-#4FFF, its mirror #5000; segments #FC and #FD, the ring at #8000
;   buffer 1: Nick #5100-#A0FF, its mirror #A100; segments #FD and #FE, the ring at #9100

; Nick's ports
NICK_FIXBIAS = #80
NICK_BORDER  = #81
NICK_LPL     = #82                  ; the table's address, bits 4-11
NICK_LPH     = #83                  ; ... bits 12-15 (bits 0-3); bits 6 and 7: see show_lpt

RING_SIZE  = 20480
LINE_BYTES = 80
LINES      = 256
RING0_NICK = #0000
RING1_NICK = #5100
RING0_Z80  = #8000
RING1_Z80  = #9100

LPT_NICK   = #FF00                  ; the tables, at the top of segment #FF (Nick's #FF00) ...
LPT_WIN    = #7F00                  ; ... and in the window, with #FF paged in
LPT_BYTES  = 8 * 16
LPB_BYTES  = 16

MARGIN_L   = 11
MARGIN_R   = 51
MB_PLAYFIELD = %00110010            ; 4 colours, VRES, pixel mode
MB_BORDER  = %00010010              ; (VRES, pixel mode: margins that show none of it)
MB_VINT    = %10000000
MB_RELOAD  = %00000001

; Put the parts of both tables that never change in place, and both buffers'
; playfields from their scroll positions. Call with interrupts off.
lpt_init
        ld a,(win_seg) : push af
        ld a,SEG_TOP : call bank_select
        ld de,LPT_WIN : call .fixed
        ld de,LPT_WIN + LPT_BYTES : call .fixed
        pop af : call bank_select
        xor a : call lpt_set
        ld a,1 : jp lpt_set
.fixed  ld hl,2 * LPB_BYTES : add hl,de : ex de,hl
        ld hl,lpt_fixed : ld bc,6 * LPB_BYTES : ldir
        ret

; The LPBs after the playfield
lpt_fixed
        db 256 - 12, MB_BORDER + MB_VINT, #3F, #00 : defs 12, 0      ; bottom border, VINT
        db 256 - 3, #10, #3F, #00 : defs 12, 0                      ; vertical sync (EXOS's)
        db 256 - 4, #10, #06, #3F : defs 12, 0
        db 256 - 1, #10, #3F, #20 : defs 12, 0
        db 256 - 4, #12, #06, #3F : defs 12, 0
        db 256 - 32, MB_BORDER + MB_RELOAD, #3F, #00 : defs 12, 0   ; top border, then again

; Set buffer A's playfield LPBs from its scroll position (scroll0 or scroll1) and
; palette (pal0 or pal1), and copy its mirror
lpt_set
        ld (ls_buf),a
        ; HL = the scroll position, DE = the ring's Nick address, IX = its palette
        or a
        ld hl,(scroll0) : ld de,RING0_NICK : ld ix,pal0
        jr z,.got
        ld hl,(scroll1) : ld de,RING1_NICK : ld ix,pal1
.got    ld (ls_ld1a),hl
        ; k = the lines that start before the ring's end: ceil((RING_SIZE - scroll) / 80)
        ex de,hl : ld (ls_base),hl : ex de,hl
        ld b,h : ld c,l
        ld hl,RING_SIZE : or a : sbc hl,bc      ; HL = RING_SIZE - scroll (> 0)
        ld de,LINE_BYTES : ld c,0               ; C = k (256 = 0)
.count  inc c
        or a : sbc hl,de
        jr z,.counted : jr nc,.count
.counted
        ; the rest start at -HL from the ring's start (HL = 0 - that, 0 to -79)
        ex de,hl : ld hl,0 : or a : sbc hl,de   ; HL = where the second LPB starts in the ring
        ld a,c : or a : jr nz,.split
        ; all 256 lines start before the end (scroll 0 to 78): split anywhere (at line 128)
        ld c,128 : ld hl,(ls_ld1a) : ld de,128 * LINE_BYTES : add hl,de
.split  ld de,(ls_base) : add hl,de : ld (ls_ld1b),hl
        ld hl,(ls_ld1a) : add hl,de : ld (ls_ld1a),hl
        ld a,c : ld (ls_k),a
        ; write them, with #FF paged in
        ld a,(win_seg) : push af
        ld a,SEG_TOP : call bank_select
        ld a,(ls_buf) : or a
        ld hl,LPT_WIN : jr z,.lpt : ld hl,LPT_WIN + LPT_BYTES
.lpt    ld a,(ls_k) : neg : ld (hl),a : inc hl          ; first LPB: k lines
        ld de,(ls_ld1a) : call .rest
        ld a,(ls_k) : ld (hl),a : inc hl                ; second: 256 - k lines
        ld de,(ls_ld1b) : call .rest
        pop af : call bank_select
        ld a,(ls_buf) : jp copy_mirror
.rest   ld (hl),MB_PLAYFIELD : inc hl
        ld (hl),MARGIN_L : inc hl
        ld (hl),MARGIN_R : inc hl
        ld (hl),e : inc hl : ld (hl),d : inc hl
        ld (hl),0 : inc hl : ld (hl),0 : inc hl
        push ix : pop de : ex de,hl
        ld bc,8 : ldir
        ex de,hl
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

; Point Nick at the table of buffer `front`, from the start of the next frame.
; (Port #83's bits 6 and 7 stay set, as EXOS leaves them: then only the address
; changes, and Nick takes it when it next starts the table.)
show_lpt
        ld a,(front) : or a
        ld a,(LPT_NICK >> 4) & #FF : jr z,.got
        ld a,((LPT_NICK + LPT_BYTES) >> 4) & #FF
.got    out (NICK_LPL),a
        ld a,(LPT_NICK >> 12) | #C0 : out (NICK_LPH),a
        ret
