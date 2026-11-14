; ---- The level loader: the level's own data, packed in the program (lvlpack.inc, made by
; build.mjs with tools/lz.py), unpacked where it goes at the start: its glyphs (each character
; set's from NCOMMON on, after the common ones: pack.mjs), its sprites (from LSPR, after the
; common ones), and its map (tops, bottoms). The common glyphs and sprites are in the program
; where they're shown.
;
; unpack: the BBC version's (../src/frak.asm), for the 6510 (no bra). The format, from
; ../tools/pack.py: LZ77 with bit-level lengths, in the style of ZX0. Bits are read one at a time,
; from a byte that comes in the stream where its first bit is needed (bit 7 first); literal and
; distance bytes are read from the stream as they come. Numbers are interleaved Elias gamma codes.
; The stream is blocks of: literals (n, then n bytes; then 0: a copy from the last distance, 1: a
; new one); a copy from the last distance (n bytes; then 0: literals, 1: a new copy); a new copy
; (h, then a byte b: distance (h - 1) * 256 + b + 1, h = 256 the end; then n - 1; then 0:
; literals, 1: another new copy). It starts with literals.
ubits   = $f0                       ; (zero page: free in the game, $7e-$fa)
usrc    = $f1
udp     = $f3
uptr    = $f5
utmp    = $f7
udist   = $f9

        .section high
loadlevel
        ldx #0
-       lda lvlstreams,x            ; (each stream: its packed data, where it goes)
        sta usrc
        lda lvlstreams + 1,x
        sta usrc + 1
        ora usrc
        beq _x
        lda lvlstreams + 2,x
        sta udp
        lda lvlstreams + 3,x
        sta udp + 1
        txa
        pha
        jsr unpack
        pla
        clc
        adc #4
        tax
        bne -
_x      rts

unpack  ldy #0
        lda #$80
        sta ubits
_lit    jsr _gamma                  ; literals
-       jsr _get
        jsr _put
        jsr _dec
        bne -
        jsr _bit
        bcs _new
        jsr _gamma                  ; a copy from the last distance
        jsr _copy
_after  jsr _bit
        bcc _lit
_new    jsr _gamma                  ; a new copy
        lda utmp + 1
        bne _done                   ; (a distance of 256 * 256 or more: the end)
        ldx utmp
        dex
        stx udist + 1
        jsr _get
        sta udist
        jsr _gamma
        inc utmp                    ; (the length - 1 was stored)
        bne +
        inc utmp + 1
+       jsr _copy
        jmp _after
_done   rts
_copy   clc                         ; (utmp bytes from udp - udist - 1)
        lda udp
        sbc udist
        sta uptr
        lda udp + 1
        sbc udist + 1
        sta uptr + 1
-       lda (uptr),y
        jsr _put
        inc uptr
        bne +
        inc uptr + 1
+       jsr _dec
        bne -
        rts
_dec    lda utmp                    ; (utmp - 1; Z set if that's 0)
        bne +
        dec utmp + 1
+       dec utmp
        lda utmp
        ora utmp + 1
        rts
_gamma  lda #1                      ; (an interleaved Elias gamma number: 1, then while the next
        sta utmp                    ;  bit is 0, doubled plus the bit after)
        lda #0
        sta utmp + 1
-       jsr _bit
        bcs +
        jsr _bit
        rol utmp
        rol utmp + 1
        jmp -
+       rts
_bit    asl ubits                   ; (C: the next bit; a new byte of them when those run out)
        bne +
        jsr _get
        sec
        rol a
        sta ubits
+       rts
_get    lda (usrc),y
        inc usrc
        bne +
        inc usrc + 1
+       rts
_put    sta (udp),y
        inc udp
        bne +
        inc udp + 1
+       rts

        .include "lvlpack.inc"
        .send high
