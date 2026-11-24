# NUSIZ1 changed straight after (or a few cycles after) a RESP1 strobe. Each line starts with
# NUSIZ1 = A, strobes RESP1 (ending at cycle 29), then writes NUSIZ1 = B after a delay.
ALL = True
S = []
def case(a, b, d, label):
    code = "lda #%d\nsta NUSIZ1\nldx #%d\n" % (a, b) + pad(21) + "\nsta RESP1\n" + (pad(d) + "\n" if d else "") + "stx NUSIZ1"
    S.append((label, "", code, 2))
S.append(("ref: NUSIZ 5 (double), no change", "", "lda #5\nsta NUSIZ1\n" + pad(21) + "\nsta RESP1", 2))
S.append(("ref: NUSIZ 1 (two close), no change", "", "lda #1\nsta NUSIZ1\n" + pad(21) + "\nsta RESP1", 2))
for d in (0, 2, 3, 5, 6, 9):
    case(5, 1, d, "double -> two close, %d cycles after RESP1" % d)
for d in (0, 3, 6):
    case(1, 5, d, "two close -> double, %d cycles after RESP1" % d)
for d in (0, 3, 6):
    case(7, 1, d, "quad -> two close, %d cycles after RESP1" % d)
SECTIONS = S
