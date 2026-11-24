#!/usr/bin/env python3
"""
The FR and A/K screens with the yoyo, a dagger and a balloon added:
  * the yoyo is missile 0 (8 px wide, Trogg's colour), its enable written on even lines;
  * the dagger is missile 1 (2 px wide; it has player 1's colour and NUSIZ1 copies), and the
    balloon is the ball (4 px wide, the playfield's colour), both written on odd lines.
Each enable comes from a table read with LDA (ptr),Y that never crosses a page: four 256-byte
pages per height hold the strip ($02 bytes) at offsets 0, 65, 130 and 195, and the frame code
picks the page so the pointer's low byte is 0-64 (Y is 0-191). The reads go at the end of the
line, just before the loop and STA WSYNC, and take effect from the next line:
    even lines: lda (YoPtr),y / sta ENAM0                         (8 cycles)
    odd lines:  lda (DagPtr),y / sta ENAM1 / lda (BalPtr),y / sta ENABL   (16 cycles)
So the scheduled part of an even line must end 8 cycles earlier than before, an odd line's 16.

Each run of lines becomes a two-line loop (an even-line and an odd-line version). That doesn't fit
in 4K, so the ROM is 8K (F8 bank switching): the tables are in both banks; the runs are split
between them, the switch made by the first bank-1 run (LDA $FFF9 straight after its STA WSYNC,
so that run's code starts at cycle 4).

    python3 atarivcs/test/moving.py fr|ak [OUT_DIR]

Runs the scheduler cannot fit are reported and drawn blank; the snapshot is checked against the
model with the yoyo's, dagger's and balloon's columns left out.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fr_screen as fr  # noqa: E402
import tiatest  # noqa: E402
from PIL import Image  # noqa: E402

pad = tiatest.pad
H = 8                                           # height of the yoyo, dagger and balloon (lines)
MODE = os.environ.get('ENABLE_MODE', 'end')     # 'end': reads just before the loop; 'anywhere'
STRIP_OFFSETS = (0, 65, 130, 195)
RAM = {'YoPtr': 0x80, 'DagPtr': 0x82, 'BalPtr': 0x84}
TAILS = {0: ['lda (YoPtr),y', 'sta ENAM0'],
         1: ['lda (DagPtr),y', 'sta ENAM1', 'lda (BalPtr),y', 'sta ENABL']}
TAIL_CYCLES = {0: 8, 1: 16}

# (x, top line) for each screen: (yoyo, dagger, balloon)
OBJECTS = {
    'fr': {'yoyo': (72, 158), 'dagger': (78, 44), 'balloon': (118, 120)},
    'ak': {'yoyo': (72, 158), 'dagger': (72, 60), 'balloon': (124, 128)},
}

SIZES = {'nop': 1, 'iny': 1}
SPLIT = [None]


def size(ins):
    ins = ins.strip()
    op = ins.split()[0]
    if op in SIZES:
        return SIZES[op]
    arg = ins.split()[1] if len(ins.split()) > 1 else ''
    if op.endswith('.w') or (',y' in arg and not arg.startswith('(')) or op == 'jmp':
        return 3
    return 2


def code_size(code):
    return sum(size(i) for chunk in code for i in chunk.split('\n') if i.strip())


def enable_pages():
    pages = []
    for off in STRIP_OFFSETS:
        p = [0] * 256
        for i in range(H):
            p[off + i] = 2
        pages.append(p)
    return pages


def pointer(top):
    """Pointer for an object visible from line `top`: written on line L, shows from L+1."""
    t = top - 1
    for k, off in enumerate(STRIP_OFFSETS):
        if 0 <= off - t <= 64:
            return 'Ena%d+%d' % (k, off - t), off - t
    return 'Ena3', 0                               # off screen: all zeros for Y 0-191


def build(screen, base):
    if screen == 'ak':
        import ak_screen  # noqa: F401  (sets fr's layout)
    lines, tables = fr.model()
    objs = OBJECTS[screen]
    rs = fr.runs(lines)

    failed = []
    blocks = []                                    # per run: (a, b, [(parity, code)])
    prev = dict(pf=((0, 0, 0), (0, 0, 0)), col=None, objs=False, x=None)
    for a, b, (pf, robjs) in rs:
        parities = [a % 2, 1 - a % 2] if b - a > 1 else [a % 2]
        versions = []
        for p in parities:
            versions.append([p, None])
        blocks.append([a, b, pf, list(robjs), versions, dict(prev)])
        prev = dict(pf=pf, col=robjs[-1][2] if robjs else prev['col'], objs=bool(robjs),
                    x=robjs[-1][0] if robjs else None)

    def sched(blk, p, t0, far, penalty=0):
        a, b, pf, robjs, versions, pv = blk
        far_c = (2 if far else 0) + penalty
        if MODE == 'end':
            # after the last store: tail, iny/cpy/branch (+1 page) [+ jmp 3], STA WSYNC by 75
            end_limit = 65 - TAIL_CYCLES[p] - far_c
            code, end = fr.schedule(pf, pv['pf'], list(robjs), pv['col'], pv['objs'], pv['x'],
                                    t0=t0, end_limit=end_limit)
            return code + TAILS[p], end
        # 'anywhere': the reads (fixed 5 cycles) are tasks the scheduler can place anywhere
        tail = TAILS[p]
        extra = [(0, 65 - far_c, (tail[k], 5), tail[k + 1].split()[1])
                 for k in range(0, len(tail), 2)]
        return fr.schedule(pf, pv['pf'], list(robjs), pv['col'], pv['objs'], pv['x'],
                           t0=t0, end_limit=65 - far_c, extra=extra)

    def schedule_block(blk, t0_first, penalty=0, force_far=False):
        a, b = blk[0], blk[1]
        res = []
        for vi, v in enumerate(blk[4]):
            p = v[0]
            t0 = t0_first if vi == 0 else 0
            code, err = None, None
            for far in ((True,) if force_far else (False, True)):
                try:
                    code, end = sched(blk, p, t0, far, penalty)
                except ValueError as e:
                    err, code = e, None
                    continue
                if not far and code_size(code) * len(blk[4]) > 110:
                    continue                       # the loop's branch back would be out of range
                break
            if code is None:
                failed.append((a, b, p, str(err)[:160]))
                code = []
            res.append((p, code, far if code else False))
        return res

    # first pass for sizes, then split the runs evenly between the two banks (both banks have
    # the tables at $F700-$FFFF, so about 1.7K of code each); the first bank-1 run starts its
    # code at cycle 4 (after the bank switch), so it's scheduled again with that
    sizes = []
    for blk in blocks:
        res = schedule_block(blk, 0)
        sizes.append(sum(code_size(c) + 10 for _, c, _ in res))
    base_failed = {(f[0], f[2]) for f in failed}
    failed.clear()
    total = sum(sizes) + 200
    split = None
    if total >= 1500:
        # candidates in order of how evenly they split the code; take the first whose switch costs
        # (bank-1 run starts at cycle 7 and loops through the stub; the run before exits with a
        # JMP) don't make a run fail that otherwise fits, and whose banks both fit
        cum, before = 200, []
        for n in sizes:
            before.append(cum)
            cum += n
        cands = sorted(range(1, len(blocks)), key=lambda i: abs(before[i] - total / 2))
        best = None
        for i in cands:
            if before[i] > 1700 or total - before[i] > 1650:
                continue
            failed.clear()
            schedule_block(blocks[i], 7, 0, force_far=True)
            schedule_block(blocks[i - 1], 0, 3)
            extra = len({(f[0], f[2]) for f in failed} - base_failed)
            if best is None or extra < best[0]:
                best = (extra, i)
            if extra == 0:
                break
        split = best[1] if best else None
        failed.clear()
    # the first bank-1 run starts at cycle 7 (STA WSYNC, LDA $FFF9 and JMP in the stub, every
    # line); the last bank-0 run's exit jumps to the stub (3 cycles)
    out_blocks = []
    for i, blk in enumerate(blocks):
        # (the first bank-1 run loops back through the stub with a JMP: schedule it as 'far')
        out_blocks.append((blk[0], blk[1], schedule_block(blk, 7 if i == split else 0,
                                                          3 if split is not None and i == split - 1 else 0,
                                                          force_far=(i == split))))

    o = ['        processor 6502']
    o += ['%-8s = $%02X' % (k, v) for k, v in tiatest.EQU.items()]
    o += ['GRP0     = $1B', 'COLUPF   = $08', 'PF0      = $0D', 'PF1      = $0E', 'PF2      = $0F',
          'RESM0    = $12', 'ENAM0    = $1D']
    o += ['%-8s = $%02X' % (k, v) for k, v in RAM.items()]

    def run_code(i, a, b, res, header):
        out = []
        labels = ['R%dv%d' % (i, k) for k in range(len(res))]
        for k, (p, code, far) in enumerate(res):
            if header and k == 0:
                # entered (and looped back to) through the stub at $F00C: STA WSYNC, LDA $FFF9,
                # JMP here, so this code starts at cycle 7
                out.append('%s = $F00C\nR%dbody:' % (labels[k], i))
                far = True
            else:
                out.append('%s:  sta WSYNC' % labels[k])
            out += ['        ' + s for chunk in code for s in chunk.split('\n') if s.strip()]
            if not code:
                out.append('        lda #0\n        sta GRP1\n        sta PF0\n        sta PF1\n        sta PF2')
            out.append('        iny\n        cpy #%d' % (b % 256))
            if k == len(res) - 1 and len(res) > 1:
                if far or header:
                    out.append('        beq R%dx\n        jmp %s' % (i, labels[0]))
                else:
                    out.append('        bne %s' % labels[0])
            elif len(res) > 1:
                out.append('        beq R%dx' % i)
            else:
                out.append('        bne %s' % labels[0] if not header
                           else '        beq R%dx\n        jmp %s' % (i, labels[0]))
        out.append('R%dx:' % i)
        return out

    def frame_setup():
        x = objs
        out = ['''Init:   sei
        cld
        ldx #$FF
        txs
        lda #0
Clear:  sta $00,x
        dex
        bne Clear
Frame:  lda #2
        sta VSYNC
        sta WSYNC
        sta WSYNC
        sta WSYNC
        lda #0
        sta VSYNC
        lda #2
        sta VBLANK
        lda #$%02X
        sta COLUBK
        lda #$%02X
        sta COLUP0
        lda #$20
        sta CTRLPF        ; ball 4 px; repeat mode; players in front
        lda #0
        sta PF0
        sta PF1
        sta PF2
        sta GRP1
        sta ENAM0
        sta ENAM1
        sta ENABL
        lda #$35
        sta NUSIZ0        ; Trogg double width, missile 0 (yoyo) 8 px
        lda #$11
        sta NUSIZ1        ; two copies close (each strobe gives one), missile 1 (dagger) 2 px''' % (fr.BG, fr.MAGENTA)]
        for name, ptr in (('yoyo', 'YoPtr'), ('dagger', 'DagPtr'), ('balloon', 'BalPtr')):
            expr, _ = pointer(x[name][1])
            out.append('        lda #<(%s)\n        sta %s\n        lda #>(%s)\n        sta %s+1'
                       % (expr, ptr, expr, ptr))
        for reg, xx in (('RESP0', fr.TROGG_X), ('RESM0', x['yoyo'][0]), ('RESM1', x['dagger'][0]),
                        ('RESBL', x['balloon'][0])):
            c = (xx + 63) // 3 if reg == 'RESP0' else (xx + 68) // 3
            out.append('        sta WSYNC')
            out.append('        ' + pad(c - 3).replace('\n', '\n        '))
            out.append('        sta %s' % reg)
        out.append('''        ldx #30
VB:     sta WSYNC
        dex
        bne VB
        ldy #0
        sta WSYNC
        lda #0
        sta VBLANK''')
        return out

    def tables_asm():
        out = ['        org $%04X\n        rorg $F700' % 0]  # placeholder, replaced per bank
        return out

    def bank(n, body):
        org = 0x0000 if n == 0 else 0x1000
        out = ['        seg bank%d' % n, '        org $%04X' % org, '        rorg $F000']
        if n == 0:
            out.append('B0Start: lda $FFF8\n        jmp Init\n        nop\n        nop\n        nop\n'
                       '        jmp Frame\n'
                       'Sw:      sta WSYNC         ; $F00C: from the last bank-0 run\n'
                       '        lda $FFF9         ; to bank 1, which continues at $F011\n'
                       '        nop\n        nop\n        nop')
        else:
            out.append('B1Start: lda $FFF8         ; to bank 0, which continues at $F003\n'
                       '        nop\n        nop\n        nop\n'
                       'Back:    lda $FFF8         ; to bank 0, which continues at $F009 (jmp Frame)\n'
                       '        nop\n        nop\n        nop\n'
                       '        sta WSYNC         ; $F00C: the first bank-1 run loops back here\n'
                       '        lda $FFF9\n'
                       '        jmp R%sbody' % SPLIT[0])
        out += body
        out.append('        org $%04X\n        rorg $F700' % (org + 0x700))
        for k, pg in enumerate(enable_pages()):
            out.append('Ena%d%s:' % (k, '' if n == 0 else '_b1'))
            for j in range(0, 256, 16):
                out.append('        .byte ' + ','.join('$%02X' % v for v in pg[j:j + 16]))
        for name in ('PCol', 'SCol', 'Trogg', 'Ladder', 'Item'):
            out.append('%s%s:' % (name, '' if n == 0 else '_b1'))
            for j in range(0, 192, 16):
                out.append('        .byte ' + ','.join('$%02X' % v for v in tables[name][j:j + 16]))
            if name != 'Item':
                out.append('        ds 64, 0')
        out.append('        org $%04X\n        rorg $FFFC\n        .word $F000\n        .word $F000' % (org + 0xFFC))
        return out

    body0 = frame_setup()
    body1 = []
    SPLIT[0] = split
    for i, (a, b, res) in enumerate(out_blocks):
        if split is not None and i >= split:
            body1 += run_code(i, a, b, res, i == split)
        else:
            body0 += run_code(i, a, b, res, False)
            if split is not None and i == split - 1:
                body0.append('        jmp Sw')
    if split is None:
        body0 += ['        jmp Overscan']
    body_tail = ['Overscan: sta WSYNC\n        lda #0\n        sta GRP0\n        sta GRP1\n        sta PF0\n'
                 '        sta PF1\n        sta PF2\n        sta ENAM0\n        sta ENAM1\n        sta ENABL\n'
                 '        lda #2\n        sta VBLANK\n        ldx #29\nOS:     sta WSYNC\n        dex\n'
                 '        bne OS']
    if split is None:
        body0 += body_tail + ['        jmp Frame']
        body1 = []
    else:
        body1 += body_tail + ['        jmp Back']
    o += bank(0, body0)
    o += bank(1, body1)
    asm = '\n'.join(o) + '\n'
    # bank 1 refers to the tables by their bank-1 names
    asm1 = asm.split('        seg bank1')
    b1 = asm1[1]
    for name in ('PCol', 'SCol', 'Trogg', 'Ladder', 'Item'):
        b1 = b1.replace(' %s,y' % name, ' %s_b1,y' % name)
    asm = asm1[0] + '        seg bank1' + b1
    open(base + '.asm', 'w').write(asm)
    r = subprocess.run(['dasm', base + '.asm', '-f3', '-o' + base + '.bin', '-l' + base + '.lst'],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if r.returncode:
        print(r.stdout[-1500:])
        sys.exit('dasm failed')
    return lines, tables, failed, split, len(rs)


def compare(png, lines, tables, objs):
    im = Image.open(png).convert('RGB')
    sx = im.width / 160
    bg = im.getpixel((im.width - 2, im.height // 2))
    first = next(r for r in range(im.height) if im.getpixel((im.width - 2, r)) == bg) + 1
    bad, found = 0, {}
    for y, ln in enumerate(lines):
        want = set()
        for b in range(40):
            if all(x in ln['pf'] for x in range(4 * b, 4 * b + 4)):
                want |= set(range(4 * b, 4 * b + 4))
        for x, g, c in ln['objs']:
            v = g[1] if g[0] == 'imm' else tables[g[1]][y]
            want |= {x + i for i in range(8) if v & (0x80 >> i)}
        got = {x for x in range(160) if im.getpixel((int((x + 0.5) * sx), first + y)) != bg}
        skip = set(range(fr.TROGG_X - 2, fr.TROGG_X + 18)) if tables['Trogg'][y] else set()
        for name, (ox, top) in objs.items():
            cols = set(range(ox - 4, ox + 12)) | (set(range(ox + 12, ox + 30)) if name == 'dagger' else set())
            if top - 3 <= y <= top + H + 2:
                found.setdefault(name, set()).update((got - want) & cols)
                skip |= cols
        if (want - skip) != (got - skip):
            bad += 1
            if bad <= 10:
                print('line %3d: missing %s extra %s' % (y, sorted(want - got - skip)[:10],
                                                          sorted(got - want - skip)[:10]))
    print('%d of 192 lines differ from the model (outside the yoyo/dagger/balloon areas)' % bad)
    for name, (ox, top) in objs.items():
        rows = [y for y in range(192)
                if any(im.getpixel((int((x + 0.5) * sx), first + y)) != bg and x not in
                       {xx for xx in range(160)} - set(range(ox - 4, ox + 30)) for x in range(ox - 4, ox + 12))]
        xs = sorted(found.get(name, []))
        print('  %-7s intended x=%d lines %d-%d; extra pixels seen at x %s' % (
            name, ox, top, top + H - 1, (xs[0], xs[-1]) if xs else 'none'))


if __name__ == '__main__':
    screen = sys.argv[1] if len(sys.argv) > 1 else 'fr'
    outdir = os.path.abspath(sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, 'out'))
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, 'moving_%s_%s' % (screen, MODE))
    lines, tables, failed, split, nruns = build(screen, base)
    print('%s (%s): %d runs, bank switch at run %s, %d run versions failed to schedule'
          % (screen, MODE, nruns, split, len(failed)))
    for a, b, p, e in failed:
        print('  lines %d-%d (%s lines): %s' % (a, b - 1, 'odd' if p else 'even', e))
    png = tiatest.snapshot(base + '.bin', outdir)
    if not png:
        sys.exit('no snapshot')
    os.replace(png, base + '.png')
    im = Image.open(base + '.png')
    im.resize((im.width * 2, im.height * 3), Image.NEAREST).save(base + '_big.png')
    print('snapshot', base + '.png', im.size)
    compare(base + '.png', lines, tables, OBJECTS[screen])
