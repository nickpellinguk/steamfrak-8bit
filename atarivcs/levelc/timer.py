"""The time since the start, "M:SS" (to 9:59), at the top left of the level screen (x 16-47, the
start of PF1), black on the level's background, 7 lines tall: P0 and P1 both at two copies close (NUSIZ 1), P0 at x 16 and
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


LETTERS = {                    # 3 x 6, for the difficulty word (two letters to a byte)
    'E': ['XXX', 'X..', 'XX.', 'X..', 'X..', 'XXX'],
    'A': ['.X.', 'X.X', 'X.X', 'XXX', 'X.X', 'X.X'],
    'S': ['.XX', 'X..', '.X.', '..X', '..X', 'XX.'],
    'Y': ['X.X', 'X.X', '.X.', '.X.', '.X.', '.X.'],
    'H': ['X.X', 'X.X', 'XXX', 'X.X', 'X.X', 'X.X'],
    'R': ['XX.', 'X.X', 'XX.', 'X.X', 'X.X', 'X.X'],
    'D': ['XX.', 'X.X', 'X.X', 'X.X', 'X.X', 'XX.'],
}
PAIRS = ['EA', 'SY', 'HA', 'RD']       # EASY (difficulty B), HARD (A): TFont + 8 x pair


def pair_rows(p):
    """A letter pair's 8 line bytes, top first: a blank line, 6 rows (bit 7 a gap, the letters in
    bits 6-4 and 2-0), a blank line."""
    bits = lambda r: int(r.replace('X', '1').replace('.', '0'), 2)
    return [0] + [bits(a) << 4 | bits(b) for a, b in zip(LETTERS[p[0]], LETTERS[p[1]])] + [0]


def text_font():
    """The pairs as the band reads them ((ptr),y, y 7 down to 1): each bottom first."""
    return [b for p in PAIRS for b in pair_rows(p)[::-1]]


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
    left over from the vertical blank). Six characters, x 16-63: P0 and P1 at three copies close
    (x 16, 32, 48 and 24, 40, 56), both vertically delayed (each shows its old graphic; a write to
    one player's GRP moves the other's new graphic to its old). Characters 1-3 are written ahead
    (the end of the line before; the first line's in the vertical blank), so only four stores are
    timed: GRP1 at 32 (P0's 2nd copy from 33.3 gets char 3), GRP0 at 35 (P1's 2nd copy from 36:
    char 4), GRP1 at 38 (P0's 3rd from 38.7: char 5), GRP0 at 41 (P1's 3rd from 41.3: char 6).
    The loop is cycle-exact, 76 cycles, no WSYNC: TLine is entered at cycle 2 of each line."""
    return """        lda (TDig),y        ; the first line's characters 1-3, ahead (Y = 7 = TLn: set in the
        sta GRP0            ; vertical blank), while VBLANK still hides them
        lda (TDig+2),y
        sta GRP1
        lda (TDig+4),y
        sta GRP0
        lda #0
        sta VBLANK
        lda #$%02X
        sta COLUBK          ; the band: the level's background
        jmp TEnter          ; (over any alignment padding: no branch in the loop crosses a page)
        IF (<.) > $A0
        ALIGN 256
        ENDIF
TEnter: sta WSYNC
        nop                 ; 2
TLine:  lda (TTx+2),y       ; 7: char 6 (the word's second pair)
        sta TTmp            ; 10
        lda (TTx),y         ; 15: char 5 (its first pair)
        tax                 ; 17
        lda (TDig+6),y      ; 22: char 4
        ldy TTmp            ; 25
        nop
        nop                 ; 29
        sta GRP1            ; 32
        stx GRP0            ; 35
        sty GRP1            ; 38
        sta GRP0            ; 41
        dec TLn             ; 46
        ldy TLn             ; 49
        beq TOut            ; 51 (52 taken: after the 7th line)
        lda (TDig),y        ; 56: the next line's char 1
        sta GRP0            ; 59
        lda (TDig+2),y      ; 64: char 2
        sta GRP1            ; 67
        lda (TDig+4),y      ; 72: char 3
        sta GRP0            ; 75
        jmp TLine           ; 78 = cycle 2 of the next line
TOut:   lda #0
        sta GRP1
        sta GRP0
        sta GRP1            ; 63: all four graphics clear
        lda Tmp2            ; the ball (the moving platform): MvX + 1 + HMK (see the HMOVE below)
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
        lda HMTab1,y
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
        lda HMTab1,y
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
        lda #0
        sta VDELP0
        sta VDELP1          ; 47: no vertical delay
%s
        sta RESP1           ; 57: P1 parked for the kernel""" % (level_bg, trogg_col, _pad(7))


def model_lines(minutes=0, seconds=0, hard=False):
    """The band's 10 lines as the checker expects them: colour index per pixel (None: background)."""
    img = [[None] * 160 for _ in range(10)]
    chars = [glyph_rows(c) for c in (minutes, 10, seconds // 10, seconds % 10)]
    chars += [pair_rows(p) for p in (PAIRS[2:] if hard else PAIRS[:2])]
    for k, rows in enumerate(chars):
        for y, v in enumerate(rows[:7]):
            for b in range(8):
                if v & (0x80 >> b):
                    img[y][16 + 8 * k + b] = WHITE
    return img
