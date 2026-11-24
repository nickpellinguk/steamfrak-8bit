# HMOVE / HMP1 / NUSIZ1 interactions. HMP1 upper nibble: $70 = 7 px left, $80 = 8 px right.
S = []
# control: the reset position alone
S.append(("ctrl: NUSIZ1=1, RESP1 @cyc 30, no HMOVE", "lda #1\nsta NUSIZ1", pad(30) + "\nsta RESP1", 4))
# the user's sequence without HMOVE: HMP1 writes alone should do nothing
S.append(("HMP1=$80, RESP1 @30, STX HMP1 ($70), no HMOVE", "lda #1\nsta NUSIZ1\nldx #$70",
          "lda #$80\nsta HMP1\n" + pad(25) + "\nsta RESP1\nstx HMP1", 4))
# with HMOVE at the start of each line (HMP1 = $80 then), RESP1 @30, then +7 written after
S.append(("HMOVE@0 (HMP1=$80), RESP1 @30, STX HMP1 $70", "lda #1\nsta NUSIZ1\nldx #$70\nlda #$80\nsta HMP1",
          "sta HMOVE\n" + pad(27) + "\nsta RESP1\nstx HMP1\nlda #$80\nsta HMP1", 6))
# HMOVE@0, then rewrite HMP1 at various cycles during the motion window (RESP1 @40 each line)
for c in (3, 6, 9, 12, 15, 18):
    S.append(("HMOVE@0 HMP1=$80, write $70 at cyc %d, RESP1 @40" % c,
              "lda #1\nsta NUSIZ1\nldx #$70",
              "sta HMOVE\n" + (pad(c - 3) + "\n" if c > 3 else "") + "stx HMP1\n" + pad(40 - c - 3)
              + "\nsta RESP1\nlda #$80\nsta HMP1", 3))
SECTIONS = S
