#!/usr/bin/env python3
"""Compress the front end (attract screen and menus) and the level loader for frak.ssd.

The front end is assembled to run at &8000 in bank 7, where the level's unrolled
background goes while a level is played. It's kept compressed in the emptier
sprite bank and unpacked into bank 7 (by fe_unpack) each time the menus come up.

The level loader is kept packed at the top of bank 7, and unpacked (by unpack) to
OVERLAY_RUN when a level loads.

    pack.py PASS1_SSD

reads FRONT and OVERLAY from the first-pass disc image, then writes build/FRONT.lz and
build/OVERLAY.lz, src/gen/packed.asm (their sizes and addresses) and the addresses into
src/gen/boot.txt.

The format (LZ77 with bit-level lengths, in the style of ZX0; unpacked by unpack in
src/frak.asm). Bits are read one at a time, from a byte that comes in the stream where its
first bit is needed (bit 7 first); literal and distance bytes are read from the stream as
they come. Numbers are interleaved Elias gamma codes: for n >= 1, for each bit of n after its
leading 1, a 0 then that bit, then a 1. The stream is blocks of:
    literals     n (gamma), then n bytes. Then 0: a copy from the last distance; 1: a new one
    last copy    n (gamma): copy n bytes from the last distance. Then 0: literals; 1: a new copy
    new copy     h (gamma), byte b: distance d + 1 where d = (h - 1) * 256 + b (h = 256: the end);
                 then n - 1 (gamma): copy n bytes. Then 0: literals; 1: another new copy
It starts with literals (with no bit before them).
"""
import os
import re
import sys

MAX_LIT = 1024              # (longest run of literals the compressor considers)
MAX_CANDS = 256             # (earlier places it tries to copy from, at each position)
STAGE_SIZE = 64             # room left below the data for fe_stage


def read_ssd(path, wanted):
    d = open(path, 'rb').read()
    count = d[0x105] // 8
    for i in range(count):
        name = d[8 + i * 8: 15 + i * 8].decode('latin-1').rstrip()
        info = d[0x108 + i * 8: 0x110 + i * 8]
        if name == wanted:
            length = info[4] | info[5] << 8 | ((info[6] >> 4) & 3) << 16
            sector = info[7] | (info[6] & 3) << 8
            return d[sector * 256: sector * 256 + length]
    raise SystemExit('%s not found in %s' % (wanted, path))


def gamma_bits(n):
    return 2 * (n.bit_length() - 1) + 1


class BitWriter:
    """Bytes and bits, interleaved the way unpack reads them: a byte of 8 bits (first bit in
    bit 7) goes into the stream at the point the first of them is needed"""
    def __init__(self):
        self.out = bytearray()
        self.bitpos = None
        self.nbits = 8

    def bit(self, b):
        if self.nbits == 8:
            self.bitpos = len(self.out)
            self.out.append(0)
            self.nbits = 0
        if b:
            self.out[self.bitpos] |= 0x80 >> self.nbits
        self.nbits += 1

    def byte(self, v):
        self.out.append(v)

    def gamma(self, n):
        # interleaved Elias gamma: for each bit after the leading 1, a 0 then the bit; then a 1
        for k in range(n.bit_length() - 2, -1, -1):
            self.bit(0)
            self.bit((n >> k) & 1)
        self.bit(1)


def compress(data):
    """The cheapest encoding (in bits) of data, by dynamic programming over (position, whether
    the last block was literals). See the module docstring for the format."""
    n = len(data)
    INF = 1 << 60
    # best[i][s] = (bits, previous (i, s), token, last distance); s = 0 after literals, 1 after
    # a copy (or at the start)
    best = [[None, None] for _ in range(n + 1)]
    best[0][1] = (0, None, None, None)
    chains = {}
    for i in range(n):
        # the longest copy at each distance class (same gamma cost) from here
        cands = {}
        key = bytes(data[i:i + 2])
        for j in reversed(chains.get(key, [])[-MAX_CANDS:]):
            d = i - j - 1
            l = 0
            while i + l < n and data[j + l] == data[i + l]:
                l += 1
            h = (d >> 8) + 1
            if l > cands.get(h, (0, 0))[0]:
                cands[h] = (l, d)
        chains.setdefault(key, []).append(i)

        def relax(j, s, cost, prev, token, last):
            cur = best[j][s]
            if cur is None or cost < cur[0]:
                best[j][s] = (cost, prev, token, last)

        for s in (0, 1):
            here = best[i][s]
            if here is None:
                continue
            c0, _, _, last = here
            if s == 1:
                flag = 0 if i == 0 else 1
                for l in range(1, min(MAX_LIT, n - i) + 1):
                    relax(i + l, 0, c0 + flag + gamma_bits(l) + 8 * l, (i, s), ('lit', l), last)
            else:
                if last is not None:
                    l = 0
                    while i + l < n and data[i + l] == data[i + l - last - 1]:
                        l += 1
                    for k in range(1, l + 1):
                        relax(i + k, 1, c0 + 1 + gamma_bits(k), (i, s), ('rep', k), last)
            for h, (l, d) in cands.items():
                base = c0 + 1 + gamma_bits(h) + 8
                for k in range(2, l + 1):
                    relax(i + k, 1, base + gamma_bits(k - 1), (i, s), ('new', k, d), d)
    # (the end: a new distance with a high part of 256)
    end = min((best[n][s][0] + 1 + gamma_bits(256), s) for s in (0, 1) if best[n][s])
    tokens = []
    at = (n, end[1])
    while best[at[0]][at[1]][1] is not None:
        _, prev, token, _ = best[at[0]][at[1]]
        tokens.append(token)
        at = prev
    tokens.reverse()
    w = BitWriter()
    pos = 0
    for k, t in enumerate(tokens):
        if t[0] == 'lit':
            if k:
                w.bit(0)                    # (after a copy: literals)
            w.gamma(t[1])
            for b in data[pos:pos + t[1]]:
                w.byte(b)
            pos += t[1]
        elif t[0] == 'rep':
            w.bit(0)                        # (after literals: a copy from the last distance)
            w.gamma(t[1])
            pos += t[1]
        else:
            _, l, d = t
            w.bit(1)                        # a copy from a new distance
            w.gamma((d >> 8) + 1)
            w.byte(d & 0xFF)
            w.gamma(l - 1)
            pos += l
    w.bit(1)
    w.gamma(256)
    return bytes(w.out)


def decompress(packed):
    """As unpack (in src/frak.asm) does it, step for step"""
    src = [0]
    bits = [0x80]
    out = bytearray()

    def byte():
        v = packed[src[0]]
        src[0] += 1
        return v

    def bit():
        bits[0] <<= 1
        c = bits[0] >> 8
        bits[0] &= 0xFF
        if bits[0] == 0:
            v = byte()
            c = v >> 7
            bits[0] = ((v << 1) | 1) & 0xFF
        return c

    def gamma():
        g = 1
        while not bit():
            g = g * 2 + bit()
        return g

    d = 0
    state = 'lit'
    while True:
        if state == 'lit':
            for _ in range(gamma()):
                out.append(byte())
            state = 'new' if bit() else 'rep'
        if state == 'rep':
            for _ in range(gamma()):
                out.append(out[-d - 1])
            state = 'new' if bit() else 'lit'
            continue
        if state == 'new':
            h = gamma()
            if h >= 256:
                return bytes(out)
            d = (h - 1) << 8 | byte()
            for _ in range(gamma() + 1):
                out.append(out[-d - 1])
            state = 'new' if bit() else 'lit'


def main():
    consts = open('src/gen/consts.asm').read()
    top = int(re.search(r'IMGDIR_ORG = &(\w+)', consts).group(1), 16)     # (the image addresses are above)
    out = ['\\ The packed front end and level loader - GENERATED by tools/pack.py, do not edit']
    boot = open('src/gen/boot.txt').read()
    for name, disc, end in (('FRONT', 'FRONTZ', top - STAGE_SIZE), ('OVERLAY', 'LOADERZ', 0xC000)):
        data = read_ssd(sys.argv[1], name)
        packed = compress(data)
        assert decompress(packed) == data
        open('build/%s.lz' % name, 'wb').write(packed)
        org = end - len(packed)
        out += ['%sZ_ORG = &%04X' % (name, org), '%s_SIZE = %d' % (name, len(data)), '%sZ_SIZE = %d' % (name, len(packed))]
        boot = re.sub(r'(\*SRLOAD %s )\w+' % disc, r'\g<1>%X' % org, boot)
        print('%s: %d bytes, packed to %d (%d%%)' % (name, len(data), len(packed), 100 * len(packed) // len(data)))
    open('src/gen/packed.asm', 'w').write('\n'.join(out) + '\n')
    open('src/gen/boot.txt', 'w').write(boot)


if __name__ == '__main__':
    main()
