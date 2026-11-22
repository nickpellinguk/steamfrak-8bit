# 4-6 retriggered P1 copies on a line (NUSIZ1 = two close), each with its own GRP1 value written
# straight after its strobe, plus same-graphics runs for comparison. Values are 1-2 pixel marks at
# different offsets so each copy can be identified: copy k lights bit (7-k) and bit 0.
ALL = True
S = []
def val(k): return "$%02X" % ((0x80 >> k) | 1)
def case(n, g, label, same=False, pre=16):
    code = ["lda #$FF", "sta GRP1", "lda #%s" % val(0)] + ([pad(pre)] if pre else [])
    for k in range(n):
        code.append("sta RESP1")
        rest = g - 3
        if not same:
            if k > 0:
                code.append("lda #%s" % val(k)); rest -= 2
            code.append("sta GRP1"); rest -= 3
        if k < n - 1 and rest:
            code.append(pad(rest))
    S.append((label + " (first strobe ends cyc %d)" % (10 + pre), "lda #1\nsta NUSIZ1", "\n".join(code), 2))
case(5, 8, "5 copies, every 8 cycles, own graphics")
case(6, 8, "6 copies, every 8 cycles, own graphics", pre=6)
case(7, 8, "7 copies, every 8 cycles, own graphics", pre=0)
case(5, 10, "5 copies, every 10 cycles, own graphics", pre=6)
case(6, 7, "6 copies, every 7 cycles, same graphics", same=True, pre=6)
case(8, 7, "8 copies, every 7 cycles, same graphics", same=True, pre=4)
SECTIONS = S
