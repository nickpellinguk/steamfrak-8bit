ALL = True
# Sprite positioned once in setup, then moved by HMOVE at the start of each line.
# HMP1 starts each line at $70 (7 left, the longest motion); $80 (8 right) is written at a
# varying cycle to see when it cuts the motion short. 0+8 is the HMOVE comb.
SET = "lda #1\nsta NUSIZ1\nlda #$70\nsta HMP1\n" + pad(14) + "\nsta RESP1\nldx #$80"
S = []
S.append(("calib: HMOVE@0, HMP1=$70 every line", SET, "sta HMOVE", 2))
for c in (3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25):
    S.append(("HMOVE@0 with $70, STX $80 ending at cyc %d" % (c + 3), SET,
              "sta HMOVE\n" + (pad(c - 3) + "\n" if c > 3 else "") + "stx HMP1\n" + pad(30) + "\nlda #$70\nsta HMP1", 2))
SECTIONS = S
