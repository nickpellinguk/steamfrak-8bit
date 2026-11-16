; ---- unpack: the BBC version's unpacker (LZ77 with interleaved Elias gamma lengths: tools/pack.py,
; as the C64 port's loader.asm has it), from usrc to udp. Here the level's map into the screen's,
; at the start (screen.py packs it: A_1's 7,680 bytes in 774).
usrc    = $78                       ; (2 each: where from, where to, a copy's source)
udp     = $7a
uptr    = $7c
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

utmp    .word 0
udist   .word 0
ubits   .byte 0
