#!/usr/bin/env python3
"""
Write the test lists for test/vlist.asm and test/vlist_a.asm:

    python3 vectrex/tools/vlist_data.py              # test/vlist_data.asm
    python3 vectrex/tools/vlist_data.py --computed   # test/vlist_a_data.asm

A square wave of vectors, each with its own scale, about the same length (dx or dy x scale).
For vlist each vector carries the address of its wait (see vlist.asm); for vlist_a the wait is
worked out from the scale as it draws, and a scale of 0 ends the list. vlist() and vlist_a()
below are what a converter for the game's shapes would use.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEST = os.path.join(HERE, '..', 'test')

SCALES = [18, 19, 20, 21, 25, 32, 47, 64, 100, 127, 200, 255]
SCALES_A = [28, 29, 30, 31, 33, 40, 47, 64, 100, 127, 200, 255]
LENGTH = 2000           # beam units (DAC value x scale)


def wait(scale, last):
    """The assembler expression for a vector's wait address in vlist."""
    k = scale - 16
    if not 2 <= k <= 2 * 119 + 3:
        raise ValueError('scale %d out of range (18-257)' % scale)
    prefix = 'VL_LAST_' if last else 'VL_WAIT_'
    if k % 2 == 0:
        return '%sEVEN-%d' % (prefix, (k - 2) // 2)
    return '%sODD-%d' % (prefix, (k - 3) // 2)


def vlist(vectors, label):
    """vectors: (scale, dy, dx, spot on?). Returns assembler lines for vlist."""
    out = ['%s' % label]
    for i, (scale, dy, dx, on) in enumerate(vectors):
        assert -128 <= dy <= 127 and -128 <= dx <= 127
        out.append('                fcb     %d,%d,%d,$%02X' % (scale, dy, dx, 0xFF if on else 0))
        out.append('                fdb     %s' % wait(scale, i == len(vectors) - 1))
    return out


def vlist_a(vectors, label):
    """The same for vlist_a: 4 bytes a vector, then 0, 0."""
    out = ['%s' % label]
    for scale, dy, dx, on in vectors:
        assert 28 <= scale <= 255 and -128 <= dy <= 127 and -128 <= dx <= 127
        out.append('                fcb     %d,%d,%d,$%02X' % (scale, dy, dx, 0xFF if on else 0))
    out.append('                fcb     0,0')
    return out


def square_wave(scales):
    vectors = []
    up = True
    for s in scales:
        d = max(1, min(127, round(LENGTH / s)))
        vectors.append((s, 0, d, True))                       # along
        vectors.append((s, d if up else -d, 0, True))         # up or down
        up = not up
    return vectors


def main():
    computed = '--computed' in sys.argv
    scales = SCALES_A if computed else SCALES
    out = os.path.join(TEST, 'vlist_a_data.asm' if computed else 'vlist_data.asm')
    lines = ['; made by vectrex/tools/vlist_data.py%s: scales %s, about %d beam units each'
             % (' --computed' if computed else '', ', '.join(map(str, scales)), LENGTH)]
    lines += (vlist_a if computed else vlist)(square_wave(scales), 'test_list')
    open(out, 'w').write('\n'.join(lines) + '\n')
    print(out)


if __name__ == '__main__':
    main()
