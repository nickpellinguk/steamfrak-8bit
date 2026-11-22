# Where does a single RESP1 strobe's 'two close' copy start appearing at the left edge?
# One strobe per line ending at cycle c (17-26); copy expected at x = 3c - 47.
ALL = True
S = []
for c in range(17, 27):
    S.append(("one strobe ending at cycle %d (expect copy x=%d)" % (c, 3 * c - 47), "lda #1\nsta NUSIZ1",
              pad(c - 3) + "\nsta RESP1", 2))
SECTIONS = S
