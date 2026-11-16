; ---- The level's start (in the overlay: overlay.asm): its block, character set and map unpacked,
; then lvderive. levelset is called through OVLSET.
; ---- levelset: level lvnum's block (its tables and numbers) to LVL, its character set to FONTA,
; its map to the screen's (levels.inc: each packed)
levelset ldx lvnum
        lda lvblo,x
        sta usrc
        lda lvbhi,x
        sta usrc+1
        lda #<LVL
        sta udp
        lda #>LVL
        sta udp+1
        jsr unpack
        ldx lvnum
        lda lvflo,x
        sta usrc
        lda lvfhi,x
        sta usrc+1
        lda #<FONTA
        sta udp
        lda #>FONTA
        sta udp+1
        jsr unpack
        ldx lvnum
        lda lvmlo,x
        sta usrc
        lda lvmhi,x
        sta usrc+1
        lda #<SCREEN
        sta udp
        lda #>SCREEN
        sta udp+1
        jsr unpack                  ; (then what levels.py left out of the block, worked out)

; ---- lvderive: the level block's tables that levels.py leaves out (they follow from the rest):
; the patch cells spread from 3 bytes to 4 (the 4th, the code with the object there: the map's, as
; just unpacked); each 8-pixel column's platforms (the last first) and ladders (within 6 pixels);
; the gems' and keys' boxes and players' places (from their corners: the kind's box); the enemies'
; boxes and infills' places (from their corners: the level's offsets)
lvderive lda #<(pkc + 3 * 0)        ; the cells, from the last down: from pkc + 3n to pkc + 4n
        sta sp1
        lda #>pkc
        sta sp1+1
        lda #<pkc
        sta sp2
        lda #>pkc
        sta sp2+1
        lda lv_ncell                ; (n: a word)
        sta lvc
        lda lv_ncell+1
        sta lvc+1
        ldx #3                      ; (sp1 += 3n, sp2 += 4n)
-       lda lvc
        clc
        adc sp1
        sta sp1
        lda lvc+1
        adc sp1+1
        sta sp1+1
        dex
        bne -
        ldx #4
-       lda lvc
        clc
        adc sp2
        sta sp2
        lda lvc+1
        adc sp2+1
        sta sp2+1
        dex
        bne -
ldc     lda lvc
        ora lvc+1
        beq ldcd
        lda lvc
        bne +
        dec lvc+1
+       dec lvc
        lda sp1                     ; (back a record each)
        sec
        sbc #3
        sta sp1
        bcs +
        dec sp1+1
+       lda sp2
        sec
        sbc #4
        sta sp2
        bcs +
        dec sp2+1
+       ldy #2
-       lda (sp1),y
        sta (sp2),y
        dey
        bpl -
        iny                         ; (y 0: the row) its code in the screen's map: SCREEN + row *
        lda (sp2),y                 ; 128 + 4 + the column
        lsr a
        pha
        lda #0
        ror a
        ora #4
        iny
        clc
        adc (sp2),y
        sta tmp
        pla
        adc #>SCREEN
        sta tmp+1
        ldy #0
        lda (tmp),y
        ldy #3
        sta (sp2),y
        jmp ldc
ldcd    lda #0                      ; each column's platforms and ladders (geom.py's lists)
        sta lvcc
        tay
ldp     tya                         ; (column lvcc: its lists start here)
        ldx lvcc
        sta pcol,x
        lda lvcc                    ; (its left, 8 * column, and right)
        asl a
        sta lvx0
        lda #0
        rol a
        asl lvx0
        rol a
        asl lvx0
        rol a
        sta lvx0+1
        ldx lv_nplat                ; the platforms over it, the last first: x <= right, x + w > left
        beq ldpn
-       dex
        lda lvx0                    ; (x <= left + 7)
        clc
        adc #7
        sta lvx1
        lda lvx0+1
        adc #0
        sta lvx1+1
        lda lvx1
        cmp plat_xl,x
        lda lvx1+1
        sbc plat_xh,x
        bcc +
        lda plat_xl,x               ; (x + w > left)
        clc
        adc plat_w,x
        sta lvx1
        lda plat_xh,x
        adc #0
        sta lvx1+1
        lda lvx0
        cmp lvx1
        lda lvx0+1
        sbc lvx1+1
        bcs +
        txa
        sta plist,y
        iny
+       cpx #0
        bne -
ldpn    inc lvcc
        lda lvcc
        cmp lv_pcoln
        bcc ldp
        tya
        ldx lvcc
        sta pcol,x
        lda #0
        sta lvcc
        tay
ldl     tya                         ; the ladders: x - 6 <= left + 7 and x + 6 >= left, in order
        ldx lvcc
        sta lcol,x
        lda lvcc
        asl a
        sta lvx0
        lda #0
        rol a
        asl lvx0
        rol a
        asl lvx0
        rol a
        sta lvx0+1
        ldx #0
-       cpx lv_nlad
        bcs ldln
        lda lvx0                    ; (x <= left + 13)
        clc
        adc #13
        sta lvx1
        lda lvx0+1
        adc #0
        sta lvx1+1
        lda lvx1
        cmp lad_xl,x
        lda lvx1+1
        sbc lad_xh,x
        bcc +
        lda lad_xl,x                ; (x + 6 >= left)
        clc
        adc #6
        sta lvx1
        lda lad_xh,x
        adc #0
        sta lvx1+1
        lda lvx1
        cmp lvx0
        lda lvx1+1
        sbc lvx0+1
        bcc +
        txa
        sta llist,y
        iny
+       inx
        bne -
ldln    inc lvcc
        lda lvcc
        cmp lv_pcoln
        bcc ldl
        tya
        ldx lvcc
        sta lcol,x
        ldx lv_npk                  ; the gems and keys: boxes and players' places from the corners
        beq ldkd
-       dex
        ldy pkkey,x                 ; (0 a gem, 1 a key)
        lda pkil,x
        clc
        adc pkbx0,y
        sta pkll,x
        lda pkih,x
        adc #0
        sta pklh,x
        lda pkil,x
        clc
        adc pkbx1,y
        sta pkrl,x
        lda pkih,x
        adc #0
        sta pkrh,x
        lda pkit,x
        clc
        adc pkby0,y
        sta pkt,x
        lda pkit,x
        clc
        adc pkby1,y
        sta pkb,x
        lda pkil,x                  ; (a key's yellow's players: KXOFF, KPDOFF from its corner)
        clc
        adc #<KXOFF
        sta pkxl,x
        lda pkih,x
        adc #>KXOFF
        sta pkxh,x
        lda pkit,x
        clc
        adc #<KPDOFF
        sta pkpd,x
        cpx #0
        bne -
ldkd    ldx lv_nscr                 ; the enemies: boxes and infills' places from the corners
        beq ldsd
-       dex
        lda scil,x
        clc
        adc lv_sx0
        sta scbll,x
        lda scih,x
        adc #0
        sta scblh,x
        lda scil,x
        clc
        adc lv_sx1
        sta scbrl,x
        lda scih,x
        adc #0
        sta scbrh,x
        lda scit,x
        clc
        adc lv_sy0
        sta scbt,x
        lda scit,x
        clc
        adc lv_sy1
        sta scbb,x
        ldy #0                      ; (the infill's left: + lv_dxs, signed)
        lda lv_dxs
        bpl +
        dey
+       clc
        adc scil,x
        sta scr_xl,x
        tya
        adc scih,x
        sta scr_xh,x
        lda scit,x                  ; (its top: + lv_dys, signed; its lines on the screen, clipped)
        clc
        adc lv_dys
        sta scr_pd,x
        cmp #TOPL
        bcs +
        lda #TOPL
+       sta scrT,x
        lda scr_pd,x
        clc
        adc lv_scrh
        sec
        sbc #1
        cmp #LASTL
        bcc +
        lda #LASTL
+       sta scrB,x
        cpx #0
        bne -
ldsd    rts
lvc     .word 0                     ; (lvderive's)
lvcc    .byte 0
lvx0    .word 0
lvx1    .word 0
