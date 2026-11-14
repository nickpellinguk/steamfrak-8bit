# A stand-in character ROM for testing in a VICE that hasn't Commodore's (build.mjs writes
# build/chargen.rom with it, if Pillow is there; else zeros): readable 8 x 8 glyphs, drawn from
# Pillow's own font, in the C64's layout, so the front end's text (copied from the ROM: front.asm)
# shows in tests. Not the C64's font: on a C64, or a VICE with its ROMs, the real one is used.
#   python3 standinfont.py OUT
import sys
from PIL import Image, ImageDraw, ImageFont
f = ImageFont.load_default(size=8)
def glyph(ch):
    im = Image.new('1', (8, 12), 0)
    ImageDraw.Draw(im).text((1, 0), ch, font=f, fill=1)
    rows = [sum(0x80 >> x for x in range(8) if im.getpixel((x, y))) for y in range(12)]
    top = next((y for y, r in enumerate(rows) if r), 0)       # (letters from their top, so 8 rows hold them)
    top = min(top, 1) if ch.islower() or ch in ',.;:_' else top
    return bytes((rows[top:top + 8] + [0] * 8)[:8])
rom = bytearray(0x1000)
def put(base, code, ch):
    rom[base + code * 8: base + code * 8 + 8] = glyph(ch)
for base in (0, 0x800):                                       # (both sets: upper case, then lower/upper)
    put(base, 0, '@')
    for i in range(26):
        put(base, 1 + i, chr((0x61 if base else 0x41) + i))
        if base: put(base, 65 + i, chr(0x41 + i))
    for code, ch in ((27, '['), (28, '#'), (29, ']'), (30, '^'), (31, '_')): put(base, code, ch)
    for code in range(33, 64): put(base, code, chr(code))
open(sys.argv[1], 'wb').write(rom)
