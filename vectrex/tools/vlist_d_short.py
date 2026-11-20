#!/usr/bin/env python3
"""
Write vectrex/test/vlist_d_short.asm: the table and blocks that vlist_d (test/vlist_d.asm) uses
for scales under 28.

    python3 vectrex/tools/vlist_d_short.py [POLL_K]     (0: as measured in vecx)

Each block starts at t = 3 (t = 0: the timer starting), with B = the mode and A = $40. The
times below are when instructions start: in vecx (with beam.patch's 13-cycle analogue lag) a
write to the spot (the shift register) shows 6 cycles after its instruction starts, and the beam
moves from 13 to scale + 13, so the spot-on store must start at 7 and the spot-off at scale + 7.

- A fixed delay: spot on (STB <$0A, 4 cycles), scale - 4 cycles of NOPs and BRNs, spot off. For
  scale 5 the spot on is STB $D00A (5 cycles) with nothing after it; scales 1-3 can't be done
  (two stores are at least 4 cycles apart) and come out as 4.
- Polling, with the reads lined up: spot on, a delay d (0, 2, 3, 4, 5, 6 or 8: the poll loop is 7
  cycles a time, so 8 does for 1), then BITA <$0D / BEQ until timer 1's flag is set. A read
  that starts at r sees the flag if r >= scale + POLL_K; d is chosen so that one read starts
  exactly then, and the loop then takes 7 cycles to finish, so the spot off can start
  scale + POLL_K + 7 + P with P cycles of padding: P = -POLL_K puts it at scale + 7. (If POLL_K
  is positive, the spot goes off POLL_K cycles late.) It's used for a scale wherever there's
  time for the first read to come early enough; the fixed delay everywhere else.

The blocks for polling depend only on scale mod 7, so seven of them do for all the scales that
poll.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'test', 'vlist_d_short.asm')

SPOT_ON = 7         # the spot-on store's start
FIRST_READ = 11     # the poll loop's first read with no delay (the spot-on store ends at 11)
DELAYS = (0, 2, 3, 4, 5, 6, 8)


def delay(n):
    """Instructions taking exactly n cycles (n != 1)."""
    if n == 0:
        return []
    assert n >= 2, n
    out = []
    if n % 2:
        out.append(('brn     *', 3))
        n -= 3
    out += [('nop', 2)] * (n // 2)
    return out


def line(op, comment=''):
    return '                %-31s %s' % (op, ('; ' + comment) if comment else '')


def fixed_block(scale):
    s = max(4, scale)
    out = ['vs_fixed_%d' % scale]
    out += [line('nop', '2   5'), line('nop', '2   7')]
    if s == 5:
        out.append(line('stb     $D000+VIA_shift_reg', '5      spot on (starts at 7)'))
    else:
        out.append(line('stb     <VIA_shift_reg', '4      spot on (starts at 7)'))
        out += [line(op, '%d' % c) for op, c in delay(s - 4)]
    out.append(line('clr     <VIA_shift_reg', 'spot off (starts at %d = scale + 7)' % (s + 7)
                    + ('' if s == scale else ': scale %d is drawn as 4' % scale)))
    out.append(line('lbra    vs_next'))
    return out


def poll_choice(scale, k):
    """(d, number of reads before the one that sees the flag) or None if there isn't time."""
    target = scale + k
    for d in DELAYS:
        if (target - FIRST_READ - d) % 7 == 0 and target - FIRST_READ - d >= 0:
            return d
    return None


def poll_block(d, k):
    pad = max(0, -k)
    out = ['vs_poll_%d' % d]
    out += [line('nop', '2   5'), line('nop', '2   7')]
    out.append(line('stb     <VIA_shift_reg', '4  11  spot on (starts at 7)'))
    out += [line(op, '%d' % c) for op, c in delay(d)]
    out.append('vs_poll_%d_loop' % d)
    out.append(line('bita    <$0D', '4      reads start at %d + 7n' % (FIRST_READ + d)))
    out.append(line('beq     vs_poll_%d_loop' % d, '3'))
    out += [line(op, '%d' % c) for op, c in delay(pad)]
    out.append(line('clr     <VIA_shift_reg', 'spot off'))
    out.append(line('lbra    vs_next'))
    return out


def main():
    k = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    table, blocks, polls = [], [], {}
    for scale in range(1, 28):
        d = poll_choice(scale, k)
        if d is not None:
            polls.setdefault(d, []).append(scale)
            table.append(line('fdb     vs_poll_%d' % d, 'scale %d: polling' % scale))
        else:
            blocks.append(fixed_block(scale))
            table.append(line('fdb     vs_fixed_%d' % scale, 'scale %d: fixed delay' % scale))
    for d in sorted(polls):
        blocks.append(['; scales %s' % ', '.join(map(str, polls[d]))] + poll_block(d, k))
    out = ['; made by vectrex/tools/vlist_d_short.py %d (POLL_K = %d)' % (k, k), '',
           '; the blocks for scales 1-27, by scale']
    out += table + ['vs_table_end', '']
    for b in blocks:
        out += b + ['']
    open(OUT, 'w').write('\n'.join(out) + '\n')
    print('%s: fixed delay for %s; polling for %s' % (
        OUT, [s for s in range(1, 28) if all(s not in v for v in polls.values())],
        sorted(s for v in polls.values() for s in v)))


if __name__ == '__main__':
    main()
