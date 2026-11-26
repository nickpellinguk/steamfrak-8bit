"""The time since the start, "M:SS" (to 9:59), at the top left of the level screen (x 16-47, the
start of PF1), black on the level's background, 7 lines tall, the difficulty on the right: P0 and P1 both at two copies close (NUSIZ 1), P0 at x 16 and
P1 at x 24, interleaved, so four 8 px characters sit side by side; each line rewrites GRP0 and GRP1
between their first and second copies. The band is the screen's top 5 rows (10 lines): 7 lines of
digits, a line positioning the ball (the moving platform), then two lines that put P0 back at the Trogg's x (a coarse RESP0, then HMOVE: whose line
blanks its first 8 pixels) and park P1 for the kernel. Levels can't use rows 0-4."""
TOPROWS = 5


HMK = 8                        # the late HMOVE's extra move left


def _pad(n):
    import tiatest
    return '        ' + tiatest.pad(n).replace('\n', '\n        ')       # (ends at cycle 54)
WHITE = 0x00                   # (the digits: black)

# 3 x 7 glyphs, two to a byte: bit 7 a gap, one in bits 6-4, bit 3 a gap, one in bits 2-0
GLYPHS = {
    '0': ['XXX', 'X.X', 'X.X', 'X.X', 'X.X', 'X.X', 'XXX'],
    '1': ['.X.', 'XX.', '.X.', '.X.', '.X.', '.X.', 'XXX'],
    '2': ['XXX', '..X', '..X', 'XXX', 'X..', 'X..', 'XXX'],
    '3': ['XXX', '..X', '..X', '.XX', '..X', '..X', 'XXX'],
    '4': ['X.X', 'X.X', 'X.X', 'XXX', '..X', '..X', '..X'],
    '5': ['XXX', 'X..', 'X..', 'XXX', '..X', '..X', 'XXX'],
    '6': ['XXX', 'X..', 'X..', 'XXX', 'X.X', 'X.X', 'XXX'],
    '7': ['XXX', '..X', '..X', '.X.', '.X.', '.X.', '.X.'],
    '8': ['XXX', 'X.X', 'X.X', 'XXX', 'X.X', 'X.X', 'XXX'],
    '9': ['XXX', 'X.X', 'X.X', 'XXX', '..X', '..X', 'XXX'],
    ':': ['...', '...', '.X.', '...', '.X.', '...', '...'],
    'L': ['X..', 'X..', 'X..', 'X..', 'X..', 'X..', 'XXX'],
    'V': ['X.X', 'X.X', 'X.X', 'X.X', 'X.X', 'X.X', '.X.'],
    'E': ['XXX', 'X..', 'X..', 'XX.', 'X..', 'X..', 'XXX'],
    'A': ['.X.', 'X.X', 'X.X', 'XXX', 'X.X', 'X.X', 'X.X'],
    'S': ['.XX', 'X..', 'X..', '.X.', '..X', '..X', 'XX.'],
    'Y': ['X.X', 'X.X', 'X.X', '.X.', '.X.', '.X.', '.X.'],
    'H': ['X.X', 'X.X', 'X.X', 'XXX', 'X.X', 'X.X', 'X.X'],
    'R': ['XX.', 'X.X', 'X.X', 'XX.', 'X.X', 'X.X', 'X.X'],
    'D': ['XX.', 'X.X', 'X.X', 'X.X', 'X.X', 'X.X', 'XX.'],
    'B': ['XX.', 'X.X', 'X.X', 'XX.', 'X.X', 'X.X', 'XX.'],
    'T': ['XXX', '.X.', '.X.', '.X.', '.X.', '.X.', '.X.'],
    'N': ['X..X', 'XX.X', 'XX.X', 'X.XX', 'X.XX', 'X..X', 'X..X'],   # (4 wide: left half only, its gap too)
    'P': ['XX.', 'X.X', 'X.X', 'XX.', 'X..', 'X..', 'X..'],
    'c': ['...', '...', '.XX', 'X..', 'X..', 'X..', '.XX'],
    'e': ['...', '...', '.X.', 'X.X', 'XXX', 'X..', '.XX'],
    'l': ['XX.', '.X.', '.X.', '.X.', '.X.', '.X.', 'XXX'],
    'i': ['.X.', '...', 'XX.', '.X.', '.X.', '.X.', 'XXX'],
    'n': ['...', '...', 'XX.', 'X.X', 'X.X', 'X.X', 'X.X'],
    'g': ['...', '.XX', 'X.X', 'X.X', '.XX', '..X', 'XX.'],
    '(': ['..X', '.X.', 'X..', 'X..', 'X..', '.X.', '..X'],
    ')': ['X..', '.X.', '..X', '..X', '..X', '.X.', 'X..'],
    ' ': ['...'] * 7,
}
PAIRS = ['LV', 'L1', 'L2', 'L3', 'EA', 'SY', 'HA', 'RD', 'BE', 'ST']   # TPair + 8 x index
COPYRIGHT = ['  (c) 2026  ', '  N Pelling ']   # the front screen's last two lines: 12 glyphs each
_bits = lambda r: int(r.replace('X', '1').replace('.', '0'), 2)


def rows(left, right):
    """7 line bytes, top first, of two glyphs in one byte (None: blank)."""
    g = lambda c: GLYPHS[c] if c else ['...'] * 7
    assert len(g(right)[0]) == 3, 'a 4-wide glyph goes in a byte\'s left half'
    return [_bits(a) << (7 - len(a)) | _bits(b) for a, b in zip(g(left), g(right))]


def stored(rws):
    """As the loops read them: (ptr),y with y 7 down to 1: bottom first, index 0 blank."""
    return [0] + rws[::-1]


def tables():
    """The display bank's glyph tables: letter pairs, digits in either half, the colon."""
    return {'TPair': [b for p in PAIRS for b in stored(rows(p[0], p[1]))],
            'DHi': [b for d in '0123456789' for b in stored(rows(d, None))],
            'DLo': [b for d in '0123456789' for b in stored(rows(None, d))],
            'TColon': stored(rows(None, ':')),
            **{'C%d%d' % (n, k): stored(rows(line[2 * k], line[2 * k + 1]))
               for n, line in enumerate(COPYRIGHT) for k in range(6)}}


def band(trogg_col):
    """The game bank's code for the band (shared by every level: the background from LvBg), run at
    the end of the vertical blank (in its last line) and ending part-way through the band's last
    line with the switch to the display bank (see levelc: the stub at $FFD0). P0 at x 40 and P1 at x 48, two copies wide (+64), as on the
    front screen: the time on the left (P0 "M:", P1 "SS", x 40-55), the difficulty on the right
    (their second copies, x 104-119). Each byte is two 3 x 7 glyphs; the time's are made as they're
    drawn (DHi | TColon, DHi | DLo). GRP0 by 36 and GRP1 by 38.7 (the first copies), then again
    after them (38.7, 41.3) and before the second copies (57.3, 60)."""
    return """        lda #0
        sta VBLANK
        lda LvBg
        sta COLUBK          ; the band: the level's background
        ldy #7
        jmp TLine           ; (over any alignment padding)
        IF (<.) > $D0
        ALIGN 256
        ENDIF
TLine:  sta WSYNC
        lda (TDig),y        ; 5: M
        ora TColonG,y       ; 9
        sta GRP0            ; 12: x 16
        lda (TDig+2),y      ; 17: S
        ora (TDig+4),y      ; 22: S
        sta GRP1            ; 25: x 24
        lda (TDig+6),y      ; 30: the difficulty's first pair
        tax                 ; 32
        lda (TTx),y         ; 37: its second
        stx GRP0            ; 40: x 104 (P0's first copy is done at 38.7)
        sta GRP1            ; 43: x 112 (P1's at 41.3)
        dey
        bne TLine           ; 47 (7 lines: index 0 is blank)
        lda Tmp2            ; 50: the ball (the moving platform): MvX + 1 + HMK (see the HMOVE below)
        nop
        nop
        nop
        nop                 ; 58
        sty GRP0            ; 61: after P0's second copy (to 60)
        sty GRP1            ; 64: after P1's (to 62.7)
        jmp TBall           ; (over any alignment padding: neither loop's branch crosses a page)
        IF (<.) > $C8
        ALIGN 256
        ENDIF
TBall:  sta WSYNC           ; (the band's 8th line)
        sec
TBalL:  sbc #15
        bcs TBalL
        adc #15
        tay
        lda HMTab,y
        bit $80
        nop
        sta.w RESBL
        sta HMBL            ; (71 at most: x up to 144)
TPos:   sta WSYNC           ; P0 back to TX: as PosObj (RESP0 ends at 5n + 18), from TX + HMK
        lda Tmp
        sec
TPosL:  sbc #15
        bcs TPosL
        adc #15
        tay
        lda HMTab,y
        nop
        sta.w RESP0
        sta HMP0
        sta WSYNC           ; (the HMOVE is at the end of this line, cycle 75: no blanked pixels,
        lda #$20            ; but every object moves HMK further left: P0 and the ball are positioned
        sta NUSIZ0          ; HMK right of where they go, and M0 and P1 get $80 to cancel it)
        lda Facing
        sta REFP0
        lda #$%02X
        sta COLUP0
        lda #0
        sta COLUP1          ; 21
        lda #$80
        sta HMM0
        sta HMP1            ; 29
        inc TrogPtr         ; 34: the first body's (entered after its WSYNC and inc)
        lda #1
        sta NUSIZ1          ; 39: P1 the kernel's two copies again
        jmp $FFD0           ; 42: to the display bank (bit $FFF9 there, 46; jmp BandEnd, 49):
                            ; BandEnd parks P1 at 57 and the call list does the late HMOVE""" % (trogg_col,)


def model_lines(minutes=0, seconds=0, hard=False):
    """The band's 10 lines as the checker expects them: colour index per pixel (None: background)."""
    img = [[None] * 160 for _ in range(10)]
    t = '%d:%02d' % (minutes, seconds)
    w = 'HARD' if hard else 'EASY'
    for x, rws in ((40, rows(t[0], t[1])), (48, rows(t[2], t[3])), (104, rows(w[0], w[1])), (112, rows(w[2], w[3]))):
        for y, v in enumerate(rws):
            for b in range(8):
                if v & (0x80 >> b):
                    img[y][x + b] = WHITE
    return img


def label_lines(level=1, hard=False):
    """The front screen's top 7 lines: LVLn at x 40-55, EASY / HARD at x 104-119."""
    img = [[None] * 160 for _ in range(7)]
    w = 'HARD' if hard else 'EASY'
    for x, rws in ((40, rows('L', 'V')), (48, rows('L', str(level))), (104, rows(w[0], w[1])), (112, rows(w[2], w[3]))):
        for y, v in enumerate(rws):
            for b in range(8):
                if v & (0x80 >> b):
                    img[y][x + b] = WHITE
    return img
