"""The front screen: Frak's speech bubble ("FRAK!") in black playfield blocks on green, with a yellow
fill (COLUBK switched at the bubble's edges), drawn by its own loop: a line per pass, INX / CPX /
BNE, no JSR / RTS (kernel()). Redrawn at block resolution (4 px) from Steam Frak's
sFrak_Beeb sprite: rounded outline, 3 x 7 letters, a tail to the lower left. Each design row is two
kernel rows (4 lines)."""
FONT = {
    'F': ['###', '#..', '#..', '##.', '#..', '#..', '#..'],
    'R': ['##.', '#.#', '#.#', '##.', '#.#', '#.#', '#.#'],
    'A': ['.#.', '#.#', '#.#', '###', '#.#', '#.#', '#.#'],
    'K': ['#.#', '#.#', '##.', '#..', '##.', '#.#', '#.#'],
    '!': ['#', '#', '#', '#', '#', '.', '#'],
}
TEXT = 'FRAK!'


def design():
    letters = ['.'.join(FONT[c][r] for c in TEXT) for r in range(7)]
    w = len(letters[0]) + 6                      # outline, two blocks of fill each side
    rows = [' ' + 'k' * (w - 2) + ' ', 'k' + '.' * (w - 2) + 'k']
    rows += ['k..' + l.replace('#', 'k') + '..k' for l in letters]
    rows += ['k' + '.' * (w - 2) + 'k', ' kk..' + 'k' * (w - 6) + ' ',
             '  k..k', ' k..k', 'k..k', 'kkk']
    return [r.ljust(w) for r in rows]


BG, INK, FILL = 0xC6, 0x00, 0x1E   # green background, black blocks, yellow fill
FIRST_ROW, ROWS_PER = 26, 2   # where it starts (kernel rows), kernel rows per design row
FIRST_BLOCK = 8               # blocks 8-30 (x 32-123): inside the usable 4-35, clear of PF0


def lit_rows():
    """{kernel row: set of lit blocks}"""
    out = {}
    for i, r in enumerate(design()):
        lit = {FIRST_BLOCK + k for k, c in enumerate(r) if c == 'k'}
        for j in range(ROWS_PER):
            out[FIRST_ROW + ROWS_PER * i + j] = lit
    return out


if __name__ == '__main__':
    for r in design():
        print(r.replace('.', ' ').replace('k', '#'))


import sys as _sys, os as _os
_sys.path.insert(0, _os.path.join(_os.path.dirname(_os.path.abspath(__file__)), '..', 'tools'))
import mirrorrows as _M  # noqa: E402

LINES_PER = 2 * ROWS_PER       # lines per design row
FILL_ROWS = range(1, 10)       # the design rows between the main bubble's top and bottom outlines
FILL_X = (36, 120)             # the fill: inside the outline columns (blocks 8 and 30)
TAIL_P1_X = 36                 # the tail's fill: P1, double width (2 px pixels, x 36-51), behind the
                               # playfield (CTRLPF priority), one GRP1 byte per line


def tail_interior(i):
    """x range of the tail's interior on design row i (the gap after its first outline block)"""
    r = design()[i]
    if i in FILL_ROWS or i == 0:
        return None
    a = r.find('k')
    b = r.find('.', a)
    if a < 0 or b < 0 or 'k' not in r[b:]:
        return None
    e = r.find('k', b)
    return 4 * (FIRST_BLOCK + b), 4 * (FIRST_BLOCK + e)


def tail_byte(i):
    span = tail_interior(i)
    if not span:
        return 0
    return sum(0x80 >> p for p in range(8) if span[0] <= TAIL_P1_X + 2 * p and TAIL_P1_X + 2 * p + 2 <= span[1])


def tables():
    """Per-line tables of the bubble's lines (index 0 = its first line)."""
    t = {k: [] for k in ('FL1', 'FL2', 'FR2', 'FR1', 'FBK1', 'FBK2', 'FG1')}
    for i, r in enumerate(design()):
        lit = {FIRST_BLOCK + k for k, c in enumerate(r) if c == 'k'}
        for _ in range(LINES_PER):
            t['FL1'].append(_M.value(lit, 'PF1', 'L'))
            t['FL2'].append(_M.value(lit, 'PF2', 'L'))
            t['FR2'].append(_M.value(lit, 'PF2', 'R'))
            t['FR1'].append(_M.value(lit, 'PF1', 'R'))
            t['FBK1'].append(FILL if i in FILL_ROWS else BG)
            t['FBK2'].append(BG)
            t['FG1'].append(tail_byte(i))
    # GRP1 is written at the end of a line, so it shows from the next: FG1[k] is line k + 1's
    t['FG1'] = t['FG1'][1:] + [0]
    return t


def kernel():
    """The front screen's 192 lines (as the level's call list: each line starts with a WSYNC).
    Measured timing: a PF write landing at T shows from a block at x if T <= (x + 66) // 3; COLUBK
    from pixel x if T <= (x + 68) // 3. Left PF1 by 7 and PF2 by 14; COLUBK yellow ends at 34 (from
    x 32-36: under the left outline); right PF1 at 41 (window 37-59), right PF2 at exactly 48;
    COLUBK green at 63 (from x 121-124: under the right outline); GRP1 (the tail's fill) at 66, for
    the next line; the loop ends by 73."""
    top = FIRST_ROW * 2
    n = LINES_PER * len(design())
    rest = 192 - top - n - 1
    return """        ldy #%d
FTop:   sta WSYNC
        dey
        bne FTop
        ldx #0
        jmp FLine           ; (over any alignment padding)
        IF (<.) > $C0
        ALIGN 256
        ENDIF
FLine:  sta WSYNC
        lda FL1,x           ; 4
        sta PF1             ; 7
        lda FL2,x           ; 11
        sta PF2             ; 14
        ldy FR1,x           ; 18
        lda FBK1,x          ; 22
        nop
        nop
        nop
        bit $80             ; 31
        sta COLUBK          ; 34: yellow from x 32-36
        lda FR2,x           ; 38
        sty PF1             ; 41: the right PF1
        nop
        nop                 ; 45
        sta PF2             ; 48: the right PF2
        lda FBK2,x          ; 52
        ldy FG1,x           ; 56: the tail's fill (P1) for the next line
        nop
        nop                 ; 60
        sta COLUBK          ; 63: green from x 121-124
        sty GRP1            ; 66
        inx                 ; 68
        cpx #%d             ; 70
        bne FLine           ; 73
        sta WSYNC
        lda #0
        sta PF1
        sta PF2
        ldy #%d
FBot:   sta WSYNC
        dey
        bne FBot""" % (top, n, rest)


def model():
    """Expected colour index (None: the green background) of each of the 192 lines."""
    img = [[None] * 160 for _ in range(192)]
    for r, lit in lit_rows().items():
        i = (r - FIRST_ROW) // ROWS_PER
        for y in (2 * r, 2 * r + 1):
            if i in FILL_ROWS:
                for x in range(FILL_X[0], FILL_X[1]):
                    img[y][x] = FILL
            v = tail_byte(i)
            for p in range(8):
                if v & (0x80 >> p):
                    for x in (TAIL_P1_X + 2 * p, TAIL_P1_X + 2 * p + 1):
                        img[y][x] = FILL
            for b in lit:
                for x in range(4 * b, 4 * b + 4):
                    img[y][x] = INK
    return img
