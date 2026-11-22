# Missile 1 (same colour as player 1) retriggered alongside player 1. NUSIZ1 bits 4-5 = missile
# width ($30 = 8 px); bits 0-2 = copies. Steady state per line.
S = []
def strobes(seq, gap=0):
    out = []
    for k, r in enumerate(seq):
        out.append("sta " + r)
        if gap and k < len(seq) - 1:
            out.append(pad(gap))
    return "\n".join(out)
M = "lda #2\nsta ENAM1\n"
S.append(("M1 only, NUSIZ1=$30, 1 strobe", M + "lda #$30\nsta NUSIZ1\nlda #0\nsta GRP1", pad(26) + "\n" + strobes(["RESM1"]), 3))
S.append(("M1 only, NUSIZ1=$31, x4 every 6", M + "lda #$31\nsta NUSIZ1\nlda #0\nsta GRP1",
          pad(26) + "\n" + strobes(["RESM1"] * 4, 3), 3))
S.append(("M1 only, NUSIZ1=$31, x6 every 3", M + "lda #$31\nsta NUSIZ1\nlda #0\nsta GRP1",
          pad(26) + "\n" + strobes(["RESM1"] * 6), 3))
S.append(("P1+M1, NUSIZ1=$31, P M P M P M P M every 3", M + "lda #$31\nsta NUSIZ1",
          pad(26) + "\n" + strobes(["RESP1", "RESM1"] * 4), 3))
S.append(("P1+M1, NUSIZ1=$31, M P M P M P M P every 3", M + "lda #$31\nsta NUSIZ1",
          pad(26) + "\n" + strobes(["RESM1", "RESP1"] * 4), 3))
S.append(("P1+M1, NUSIZ1=$21 (M 4px), P M x4 every 3", M + "lda #$21\nsta NUSIZ1",
          pad(26) + "\n" + strobes(["RESP1", "RESM1"] * 4), 3))
S.append(("P1+M1, NUSIZ1=$31, P M x3, gap 3 between pairs", M + "lda #$31\nsta NUSIZ1",
          pad(26) + "\n" + "\n".join(["sta RESP1\nsta RESM1\n" + pad(3)] * 2 + ["sta RESP1\nsta RESM1"]), 3))
S.append(("P1 only, NUSIZ1=$01, GRP1=$FF, x4 every 6 (ref)", "lda #$01\nsta NUSIZ1",
          pad(26) + "\n" + strobes(["RESP1"] * 4, 3), 3))
SECTIONS = S
ALL = True
