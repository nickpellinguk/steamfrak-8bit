# Two or three P1 'ladders' on a line by retriggering RESP1 with NUSIZ1 = two close (1).
# GRP1 alternates rails (%10000001) and rungs ($FF) per line. Strobes start at cycle 26.
ALL = True
S = []
def lad(n, gap, label):
    seq = []
    for k in range(n):
        seq.append("sta RESP1")
        if k < n - 1 and gap > 3:
            seq.append(pad(gap - 3))
    code = "lda #$81\nsta GRP1\n" + pad(18) + "\n" + "\n".join(seq)
    S.append((label, "lda #1\nsta NUSIZ1", code, 2))
for n in (2, 3):
    for g in (6, 7, 8, 9, 12):
        lad(n, g, "%d ladders, strobes every %d cycles" % (n, g))
SECTIONS = S
