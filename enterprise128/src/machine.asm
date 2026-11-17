; The machine layer: Dave's paging and interrupts, and (from phase 1) the
; keyboard and Nick's line parameter table. (The CPC version's equivalents, in
; ../cpc6128/src/machine.asm: the gate array's RAM configurations and
; interrupts, and the PPI and the sound chip's port A for the keyboard.)
;
; The ports, as MAME's Enterprise driver has them (src/devices/sound/dave.cpp,
; src/mame/enterprise/ep64.cpp and nick.cpp):

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

; Nick
NICK_FIXBIAS = #80
NICK_BORDER  = #81
NICK_LPL     = #82                  ; the line parameter table's address, bits 4-11
NICK_LPH     = #83                  ; ... bits 12-15 (bits 0-3); bit 6 then 7: load it

; Segments: the 128's own RAM is #F8-#FB; video RAM (which Nick reads) #FC-#FF
SEG_VIDEO = #FC

; EXOS calls (RST #30, then the function's number), while EXOS still runs
EXOS_ALLOC_SEGMENT = 24             ; out: C the segment; A 0 (or #7F: shared with EXOS)

; Take the machine over from EXOS: our interrupt handler at #0038, interrupt
; mode 1, and every Dave interrupt off (phase 1 turns Nick's on). Call with
; interrupts off; leaves them off.
machine_init
        xor a : out (DAVE_INT),a
        ld a,#C3 : ld (#0038),a
        ld hl,irq : ld (#0039),hl
        im 1
        ret

; Interrupts (none are turned on yet: phase 1 counts Nick's vertical syncs here)
irq
        push af
        ld a,%10101010 : out (DAVE_INT),a       ; (reset every latch)
        pop af
        ei
        ret
