# Retriggered P1 copies (NUSIZ1 = two close) with GRP1 rewritten between strobes, so each copy
# can show different graphics. Values: first $F0 (left half), then $0F (right half), then $3C.
# Sequence per strobe k: [pad d] write value k, then pad to the next strobe (gap g cycles apart,
# strobe to strobe). Value 0 is written before the first strobe as well, so 'before' is the
# value in GRP1 when strobe 0 happens.
ALL = True
S = []
VALS = ["$F0", "$0F", "$3C"]
REGS = ["a", "x", "a"]
def case(n, g, d, label):
    # (Y is the harness's line counter, so the third value is loaded into A just in time)
    code = ["ldx #%s" % VALS[1], "lda #$FF", "sta GRP1", "lda #%s" % VALS[0], pad(14)]
    used = 0
    for k in range(n):
        code.append("sta RESP1")
        rest = g - 3
        if d:
            code.append(pad(d)); rest -= d
        if k == 2:
            code.append("lda #%s" % VALS[2]); rest -= 2
        code.append("st%s GRP1" % REGS[k]); rest -= 3
        if k < n - 1 and rest:
            code.append(pad(rest))
    S.append((label, "lda #1\nsta NUSIZ1", "\n".join(code), 2))
for n in (2, 3):
    for g, d in ((8, 0), (8, 2), (9, 0), (9, 3), (10, 4), (12, 0), (12, 6)):
        case(n, g, d, "%d copies, strobes every %d, GRP1 write %d cycles after each strobe" % (n, g, d))
SECTIONS = S
