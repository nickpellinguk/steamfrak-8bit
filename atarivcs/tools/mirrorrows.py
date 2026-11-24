#!/usr/bin/env python3
"""
Mirrored-playfield rows (CTRLPF bit 0, PF0 always 0): the timed writes a row's platforms need,
from its actual lit blocks, with the rules measured in Stella (test/mirror_windows.py):

  * a playfield write landing at cycle T takes effect from pixel 3T - 66, block by block: a 4-pixel
    block shows the value the register holds when the block starts (at its first pixel x), so the
    block sees the new value if x >= 3T - 66, i.e. T <= (x + 66) // 3, and keeps the old one if
    T >= (x + 66) // 3 + 1;
  * a COLUPF write landing at T changes the colour from pixel 3T - 68: pixel x is new if
    T <= (x + 68) // 3, old if T >= (x + 68) // 3 + 1.

Layout (mirrored): left PF1 x 16-47 (blocks 4-11, bit 7 first), left PF2 x 48-79 (blocks 12-19,
bit 0 first), right PF2 x 80-111 (blocks 20-27, bit 7 first), right PF1 x 112-143 (blocks 28-35,
bit 0 first). PF0 (x 0-15, 144-159) is never written.

A row's registers start each line holding the previous line's end values (the line above's right
values, or for the first line of a run, those of the row above). Ways to draw a row:
  'rewrite': each register gets the left value early enough and is rewritten to the right value
             between the last left block and the first right block whose bits differ;
  'hide':    one-sided platforms only: the register keeps one value and COLUPF hides the unwanted
             copy (left platform: switch to the background between the platform and its mirror;
             right platform: background over the left copy, the stripe on before the platform).
tasks() returns, for each way that applies, the scheduler tasks (lo, hi, (load, cycles), register)
and the state the line ends in (colour, register values).
"""

BG = 0xAA
REGS = ('PF1', 'PF2')


def blocks_of(reg, side):
    """[(block, bit)] for a register on a side."""
    if reg == 'PF1':
        return [(4 + i, 7 - i) for i in range(8)] if side == 'L' else [(28 + i, i) for i in range(8)]
    return [(12 + i, i) for i in range(8)] if side == 'L' else [(20 + i, 7 - i) for i in range(8)]


def value(lit, reg, side):
    return sum(1 << b for k, b in blocks_of(reg, side) if k in lit)


def block_of(reg, side, bit):
    return next(k for k, b in blocks_of(reg, side) if b == bit)


def pf_new_by(x):        # last T at which a write still reaches a block starting at x
    return (x + 66) // 3


def pf_old_until(x):     # first T at which a write no longer reaches a block starting at x
    return (x + 66) // 3 + 1


def col_new_by(x):
    return (x + 68) // 3


def col_old_until(x):
    return (x + 68) // 3 + 1


def T(name, lo, hi, reg):
    return (lo, hi, ('lda %s,x' % name, 4), reg)


def IMM(v, lo, hi, reg):
    return (lo, hi, ('lda #$%02X' % v, 2), reg)


def tasks(lit, prev):
    """lit: set of lit blocks (4-35); prev: the previous row's end state {'col': 'bg'|'stripe',
    'PF1': v, 'PF2': v}, or None at the top of the screen (registers 0, colour background).
    Returns [(way, tasks, end_state)] for the ways that apply ([] for none)."""
    if prev is None:
        prev = {'col': 'bg', 'PF1': 0, 'PF2': 0}
    if any(k < 4 or k > 35 for k in lit):
        return []                                     # PF0: the screen edges are never drawn
    L = {r: value(lit, r, 'L') for r in REGS}
    R = {r: value(lit, r, 'R') for r in REGS}
    out = []
    lit_x = sorted(4 * k for k in lit)
    if not lit:
        # no platforms: whatever the row above left in the registers mustn't show
        vis = [4 * k for r in REGS for side in 'LR' for k, b in blocks_of(r, side) if prev[r] >> b & 1]
        if prev['col'] == 'stripe' and vis:
            out.append(('blank', [IMM(BG, 0, col_new_by(min(vis)), 'COLUPF')], {'col': 'bg', **prev_regs(prev)}))
        else:
            out.append(('blank', [], {'col': prev['col'], **prev_regs(prev)}))
        return out
    first = lit_x[0]
    # --- rewrite: both halves drawn from the registers, COLUPF the stripe all line
    tk = [T('Stripe', 0, col_new_by(first), 'COLUPF')]
    ok = True
    for r in REGS:
        for P in {prev[r], R[r]}:                      # the first line of a run, and the others
            diff = L[r] ^ P
            if diff:
                xs = [4 * block_of(r, 'L', b) for b in range(8) if diff >> b & 1]
                # the left value must be in place by the first left block whose bit changes
                tk.append(T('L' + r, 0, pf_new_by(min(xs)), r) if L[r] else IMM(0, 0, pf_new_by(min(xs)), r))
        if L[r] != R[r]:
            d = L[r] ^ R[r]
            lo = max(pf_old_until(4 * block_of(r, 'L', b)) for b in range(8) if d >> b & 1)
            hi = min(pf_new_by(4 * block_of(r, 'R', b)) for b in range(8) if d >> b & 1)
            if lo > hi:
                ok = False
            tk.append(T('R' + r, lo, hi, r) if R[r] else IMM(0, lo, hi, r))
    if ok:
        out.append(('rewrite', dedupe(tk), {'col': 'stripe', **R}))
    # --- hide: one-sided platforms, the register keeps one value, COLUPF hides the other copy
    if not any(R.values()):                           # left platform: switch to the background
        last = lit_x[-1] + 3
        mirror_first = min(4 * (39 - k) for k in lit)
        tk = [T('Stripe', 0, col_new_by(first), 'COLUPF'),
              IMM(BG, col_old_until(last), col_new_by(mirror_first), 'COLUPF')]
        for r in REGS:
            if L[r] != prev[r]:
                d = L[r] ^ prev[r]
                xs = [4 * block_of(r, 'L', b) for b in range(8) if d >> b & 1]
                tk.append(T('L' + r, 0, pf_new_by(min(xs)), r) if L[r] else IMM(0, 0, pf_new_by(min(xs)), r))
        out.append(('hide', dedupe(tk), {'col': 'bg', **L}))
    if not any(L.values()):                           # right platform: hide its left copy
        copy = sorted(4 * (39 - k) for k in lit)      # the left copy's lit pixels
        rfirst = lit_x[0]
        tk = [IMM(BG, 0, col_new_by(copy[0]), 'COLUPF'),
              T('Stripe', col_old_until(copy[-1] + 3), col_new_by(rfirst), 'COLUPF')]
        for r in REGS:
            if R[r] != prev[r]:
                d = R[r] ^ prev[r]
                xs = [4 * block_of(r, 'R', b) for b in range(8) if d >> b & 1]
                tk.append(T('R' + r, 0, pf_new_by(min(xs)), r) if R[r] else IMM(0, 0, pf_new_by(min(xs)), r))
        out.append(('hide', dedupe(tk), {'col': 'stripe', **R}))
    return out


def prev_regs(prev):
    return {r: prev[r] for r in REGS}


def dedupe(tk):
    """Merge tasks writing the same value to the same register (keep the tightest window)."""
    out = {}
    for lo, hi, ld, reg in tk:
        k = (ld, reg)
        if k in out:
            a, b = out[k]
            out[k] = (max(a, lo), min(b, hi))
        else:
            out[k] = (lo, hi)
    return [(lo, hi, ld, reg) for (ld, reg), (lo, hi) in out.items()]
