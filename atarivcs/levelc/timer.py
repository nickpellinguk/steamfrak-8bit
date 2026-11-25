"""The time since the start, "M:SS" (to 9:59), at the top left of the level screen (x 16-47, the
start of PF1), white on a black band: P0 and P1 both at two copies close (NUSIZ 1), P0 at x 16 and
P1 at x 24, interleaved, so four 8 px characters sit side by side; each line rewrites GRP0 and GRP1
between their first and second copies. The band is the screen's top 5 rows (10 lines): 8 lines of
digits, then two lines that put P0 back at the Trogg's x (a coarse RESP0, then HMOVE: whose line
blanks its first 8 pixels) and park P1 for the kernel. Levels can't use rows 0-4."""
TOPROWS = 5


def _pad(n):
    import tiatest
    return '        ' + tiatest.pad(n).replace('\n', '\n        ')       # (ends at cycle 54)
WHITE, BAND = 0x0E, 0x00

GLYPHS = [                     # 0-9, then the colon; 7 rows (the 8th blank), in bits 6-1
    ['.XXXX.', 'XX..XX', 'XX.XXX', 'XXXXXX', 'XXX.XX', 'XX..XX', '.XXXX.'],
    ['..XX..', '.XXX..', '..XX..', '..XX..', '..XX..', '..XX..', '.XXXX.'],
    ['.XXXX.', 'XX..XX', '....XX', '..XXX.', '.XX...', 'XX....', 'XXXXXX'],
    ['.XXXX.', 'XX..XX', '....XX', '..XXX.', '....XX', 'XX..XX', '.XXXX.'],
    ['...XX.', '..XXX.', '.XXXX.', 'XX.XX.', 'XXXXXX', '...XX.', '...XX.'],
    ['XXXXXX', 'XX....', 'XXXXX.', '....XX', '....XX', 'XX..XX', '.XXXX.'],
    ['..XXX.', '.XX...', 'XX....', 'XXXXX.', 'XX..XX', 'XX..XX', '.XXXX.'],
    ['XXXXXX', '....XX', '...XX.', '..XX..', '.XX...', '.XX...', '.XX...'],
    ['.XXXX.', 'XX..XX', 'XX..XX', '.XXXX.', 'XX..XX', 'XX..XX', '.XXXX.'],
    ['.XXXX.', 'XX..XX', 'XX..XX', '.XXXXX', '....XX', '...XX.', '.XXX..'],
    ['......', '..XX..', '..XX..', '......', '..XX..', '..XX..', '......'],
]


def glyph_rows(i):
    """The 8 line bytes of glyph i, top first."""
    return [int('0' + g.replace('X', '1').replace('.', '0') + '0', 2) for g in GLYPHS[i]] + [0]


def font():
    """The font as the kernel reads it: (ptr),y with y from 7 down to 0, so each glyph bottom first."""
    out = []
    for i in range(len(GLYPHS)):
        out += glyph_rows(i)[::-1]
    return out


def band(level_bg, trogg_col):
    """The display bank's code for the band, run at the start of the level's kernel (in the line
    left over from the vertical blank). Timing: GRP0 by 8 and GRP1 by 16 (the first copies, x 16 and
    24, are drawn from cycles 28 and 31); GRP0 again at 31 (its first copy is done at 30.3, the
    second starts at 33.3) and GRP1 at 34 (window 33-36)."""
    return """        lda #$%02X
        sta COLUBK          ; the band: black
        ldy #7
        jmp TLine           ; (over any alignment padding)
        IF (<.) > $D0
        ALIGN 256
        ENDIF
TLine:  sta WSYNC
        lda (TDig),y        ; 5
        sta GRP0            ; 8: P0's first copy (x 16)
        lda (TDig+2),y      ; 13
        sta GRP1            ; 16: P1's first copy (x 24)
        lda (TDig+4),y      ; 21
        tax                 ; 23
        lda (TDig+6),y      ; 28
        stx GRP0            ; 31: P0's second copy (x 32)
        sta GRP1            ; 34: P1's second copy (x 40)
        dey
        bpl TLine
        lda #0
        sta GRP0
        sta GRP1
        lda #$20
        sta NUSIZ0          ; the Trogg again: one copy, a 4 px yoyo
        lda Facing
        sta REFP0
        lda #$%02X
        sta COLUP0
        lda #0
        sta COLUP1
        lda TX
        jmp TPos
        IF (<.) > $E0
        ALIGN 256
        ENDIF
TPos:   sta WSYNC           ; P0 back to TX: as PosObj (RESP0 ends at 5n + 18)
        sec
TPosL:  sbc #15
        bcs TPosL
        adc #15
        tay
        lda HMTab1,y
        bit $80
        nop
        sta.w RESP0
        sta HMP0
        sta WSYNC
        sta HMOVE           ; 3 (this line's first 8 pixels are blanked)
        lda #$%02X          ; 5
        sta COLUBK          ; 8: the level's background from this line's start
%s
        sta RESP1           ; 57: P1 parked for the kernel
        sta HMCLR           ; 60""" % (BAND, trogg_col, level_bg, _pad(46))


def model_lines(minutes=0, seconds=0):
    """The band's 10 lines as the checker expects them: colour index per pixel (None: background)."""
    img = [[BAND] * 160 for _ in range(9)] + [[BAND] * 8 + [None] * 152]
    chars = [minutes, 10, seconds // 10, seconds % 10]
    for k, c in enumerate(chars):
        for y, v in enumerate(glyph_rows(c)):
            for b in range(8):
                if v & (0x80 >> b):
                    img[y][16 + 8 * k + b] = WHITE
    return img
