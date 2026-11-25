"""The front screen: Frak's speech bubble ("FRAK!") in black playfield blocks on green, drawn by the
ordinary mirrored-playfield row renderers. Redrawn at block resolution (4 px) from Steam Frak's
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


BG, INK = 0xC6, 0x00          # green background, black blocks
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
