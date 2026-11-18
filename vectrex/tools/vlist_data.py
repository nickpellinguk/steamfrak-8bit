#!/usr/bin/env python3
"""
Write vectrex/test/vlist_data.asm, the test list for test/vlist.asm:

    python3 vectrex/tools/vlist_data.py

A square wave of vectors, each with its own scale, about the same length (dx or dy x scale), and
each with the address of its wait in vlist (see vlist.asm). vlist() below is what a converter for
the game's shapes would use.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'test', 'vlist_data.asm')

SCALES = [18, 19, 20, 21, 25, 32, 47, 64, 100, 127, 200, 255]
LENGTH = 2000           # beam units (DAC value x scale)


def wait(scale, last):
    """The assembler expression for a vector's wait address."""
    k = scale - 16
    if not 2 <= k <= 2 * 119 + 3:
        raise ValueError('scale %d out of range (18-257)' % scale)
    prefix = 'VL_LAST_' if last else 'VL_WAIT_'
    if k % 2 == 0:
        return '%sEVEN-%d' % (prefix, (k - 2) // 2)
    return '%sODD-%d' % (prefix, (k - 3) // 2)


def vlist(vectors, label):
    """vectors: (scale, dy, dx, spot on?). Returns assembler lines."""
    out = ['%s' % label]
    for i, (scale, dy, dx, on) in enumerate(vectors):
        assert -128 <= dy <= 127 and -128 <= dx <= 127
        out.append('                fcb     %d,%d,%d,$%02X' % (scale, dy, dx, 0xFF if on else 0))
        out.append('                fdb     %s' % wait(scale, i == len(vectors) - 1))
    return out


def main():
    vectors = []
    up = True
    for s in SCALES:
        d = max(1, min(127, round(LENGTH / s)))
        vectors.append((s, 0, d, True))                       # along
        vectors.append((s, d if up else -d, 0, True))         # up or down
        up = not up
    lines = ['; made by vectrex/tools/vlist_data.py: scales %s, about %d beam units each'
             % (', '.join(map(str, SCALES)), LENGTH)] + vlist(vectors, 'test_list')
    open(OUT, 'w').write('\n'.join(lines) + '\n')
    print(OUT)


if __name__ == '__main__':
    main()
