; Unpack data packed by ../tools/pack.py (the BBC version's packer: LZ77 with
; bit-level lengths, in the style of ZX0; the BBC version's unpacker is unpack
; in ../src/frak.asm). Bits are read one at a time, bit 7 first, from a byte that
; comes in the stream where its first bit is needed; literal and distance bytes
; come in the stream as they're needed. Numbers are interleaved Elias gamma
; codes: for n >= 1, for each bit of n after its leading 1, a 0 then that bit,
; then a 1. The stream is blocks of:
;   literals   n (gamma), then n bytes. Then 0: a copy from the last distance; 1: a new one
;   last copy  n (gamma): copy n bytes from the last distance. Then 0: literals; 1: a new copy
;   new copy   h (gamma), byte b: distance d + 1, where d = (h - 1) * 256 + b (h = 256: the
;              end); then n - 1 (gamma): copy n bytes. Then 0: literals; 1: another new copy
; It starts with literals (with no bit before them).
;
; HL = the packed data, DE = where to unpack it. Returns DE just after what was
; unpacked. (A, BC and HL are used.)
unpack
        ld a,#80 : ld (up_bits),a
.lit    call up_gamma : ldir                    ; literals
        call up_bit : jr c,.new
.rep    call up_gamma : call .copy              ; a copy from the last distance
        call up_bit : jr c,.new
        jr .lit
.new    call up_gamma                           ; a new distance
        ld a,b : or a : ret nz                  ; (h = 256: the end)
        dec c : ld a,c : ld (up_dist + 1),a
        ld a,(hl) : inc hl : ld (up_dist),a
        call up_gamma : inc bc : call .copy
        call up_bit : jr c,.new
        jr .lit
; copy BC bytes from up_dist + 1 bytes back
.copy   push hl
        ld hl,(up_dist) : inc hl
        ld a,e : sub l : ld l,a
        ld a,d : sbc a,h : ld h,a
        ldir
        pop hl
        ret

; Carry = the next bit of the stream (at HL)
up_bit
        ld a,(up_bits) : add a,a : jr nz,.got
        ld a,(hl) : inc hl : rla                ; (the carry, 1, shifts in as the marker)
.got    ld (up_bits),a
        ret

; BC = the next number (interleaved Elias gamma)
up_gamma
        ld bc,1
.bit    call up_bit : ret c
        call up_bit : rl c : rl b
        jr .bit
