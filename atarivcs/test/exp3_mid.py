ALL = True
# Mid-line HMOVE after a RESP1 strobe, and RESP1/RESM1 interleaving. Every line repeats the
# same code, so the result is the steady state. 0+8 at the left is the HMOVE comb (if present).
S = []
HMS = globals().get("HMS", ("$70",))
NUS1 = "lda #1\nsta NUSIZ1\n"
S.append(("ref: RESP1 end cyc 29, no HMOVE", NUS1, pad(26) + "\nsta RESP1", 3))
for hm in HMS:
    for c in (32, 41, 50, 54, 58, 62, 66, 70):
        S.append(("RESP1 end 29, HMP1=%s, HMOVE end cyc %d" % (hm, c), NUS1 + "lda #%s\nsta HMP1" % hm,
                  pad(26) + "\nsta RESP1\n" + pad(c - 32) + ("\n" if c > 32 else "") + "sta HMOVE", 3))
SECTIONS = S
