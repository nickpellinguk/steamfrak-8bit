#!/usr/bin/env python3
"""
The Vectrex version's converter (milestone 2): sprites to raster data, the 36 levels that scroll
sideways to a ROM format the game reads in place, and each level's drawing budget.

    python3 vectrex/tools/vconvert.py [../steamfrak]

writes vectrex/gen/sprites.asm, vectrex/gen/levels.asm, vectrex/preview/sprites.png and
vectrex/gen/budget.txt, and checks every level's data, decoded again, against the BBC
converter's build_level (../tools/convert.py), which the BBC and CPC versions are built from.

Sprites
-------
One bit a pixel, the lit pixels chosen per sprite (SPRITES: '#' black, 'y' yellow, 'm' magenta
or another colour). Columns (sweeping down and up) for most things, each column COL_PAD blank
pixels longer at each end, in sweep order (odd columns reversed); rows for keys, the yoyo and the
"FRAK!" bubble (odd rows reversed). Facing left is a facing-right frame drawn mirrored (the
column routines' _l entries): the converter checks the BBC version's left frames are mirror
images.

  column sprite  spr_NAME:  fcb width, bytes a column, frames, padded height (pixels)
                            fdb padded height x 160, the data (frames one after another),
                                the origin (x, y: fcb fcb)
  row sprite     rsp_NAME:  fcb width, bytes a row, rows, frames
                            fdb the data; fcb the origin (x, y)

Platforms are drawn as strips (two raster rows: their top two rows). Ledges and girders repeat a
tile, so a run of them touching on a line is drawn as one strip from a repeating buffer (PATTERNS:
pat_KIND_0 for row 0, pat_KIND_1 for row 1 reversed, each PERIOD bytes repeated to cover the
longest strip); logs are drawn piece by piece from their own rows (log_N_0, log_N_1). The Qiana
poles (thin and tall) are columns.

Levels
------
  levels:        fdb level, ... (in the order of LEVELS below)
  a level:       fdb width (pixels); fdb Trogg's start x; fcb his y; fcb flags (1: moving)
                 fcb pieces, ladders, things, slows, strips
                 then the tables, one after another:
  piece          (a platform, for the game's logic, in the original's order)
                 3 bytes: x (10 bits) y (8) sprite (5) bouncy (1)
  ladder         4 bytes: x (2), y (1: its drawn top), sprite << 4 | extension (its hidden part
                 up to the platform above)
  thing          (a gem, key, spring, Qiana pole or meanie that doesn't move: drawn, and
                 collected) 3 bytes: x (10 bits) sprite (6) y (8)
  slow           (a moving meanie or platform) kind, then by kind:
                 1 Scrubbly: x (2) y (1) amin (2) amax (2) v (2) plat (1)
                 2 Poglet:   x (2) y (1) amin (2) amax (2) v (2) yoff mode, min, max (1 each)
                 3 Hooter:   x (2) y (1) v (2) wait (1)
                 4 platform: piece (1) amin (2) amax (2) bmin (2) bmax (2) v (2) vy (1)
                             wait (1) flags (1)
  strip          (drawing: a run of ledges or girders touching on a line, or a log; not moving
                 platforms) 4 bytes: x (10 bits) pattern (4) length (9, pixels) y (8)

Sprite numbers are the indexes into SPRITE_IDS below (the same for every level).
"""
import math
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
VEC = os.path.join(HERE, '..')
sys.path.insert(0, os.path.join(VEC, '..', 'tools'))
sys.path.insert(0, HERE)
import convert  # noqa: E402  (the BBC converter)
import beam     # noqa: E402

UNIT = 41000 / 256                  # beam units a pixel (the screen 256 pixels tall)
COL_PAD = 2
WINDOW = 206                        # pixels across the screen

# --- the sprites ----------------------------------------------------------------------------------

# name: (columns or rows, lit pixels, frames)
SPRITES = {
    'sTrogg_sr_Beeb': ('cols', '#', 1), 'sTrogg_wr_Beeb': ('cols', '#', 4),
    'sTrogg_yr_Beeb': ('cols', '#', 1),
    'sTrogg_sl_Beeb': ('cols', '#', 1), 'sTrogg_wl_Beeb': ('cols', '#', 4), 'sTrogg_yl_Beeb': ('cols', '#', 1),
    'sTrogg_cn_Beeb': ('cols', '#', 1),
    'sTrogg_cu_Beeb': ('cols', '#', 2), 'sTrogg_cd_Beeb': ('cols', '#', 2),
    'sScrubbly_Beeb': ('cols', '#', 1), 'sPoglet_Beeb': ('cols', '#', 1), 'sHooter_Beeb': ('cols', '#', 1),
    'sGem_Beeb': ('cols', '#', 1), 'sBalloon_Beeb': ('cols', '#', 1),
    'sDaggerLR_Beeb': ('cols', '#', 1), 'sDaggerUD_Beeb': ('cols', '#', 1), 'sSpring_Beeb': ('cols', '#', 1),
    'sLadder1_Beeb': ('cols', '#', 1), 'sLadder2_Beeb': ('cols', '#', 1), 'sLadder3_Beeb': ('cols', '#', 1),
    'sLadder4_Beeb': ('cols', '#', 1), 'sLadder5_Beeb': ('cols', '#', 1),
    'sChain1_Beeb': ('cols', '#', 1), 'sChain2_Beeb': ('cols', '#', 1), 'sChain3_Beeb': ('cols', '#', 1),
    'sChain4_Beeb': ('cols', '#', 1),
    'sQiana1_Beeb': ('cols', '#', 1), 'sQiana2_Beeb': ('cols', '#', 1), 'sQiana3_Beeb': ('cols', '#', 1),
    'sQiana4_Beeb': ('cols', '#', 1),
    'sKey_Beeb': ('rows', '#', 1), 'sYoyo_Beeb': ('rows', '#', 4), 'sFrak_Beeb': ('rows', '#', 1),
}
# the left frames against the right ones: not mirror images (the shading is lit from one side),
# so both are stored
MIRRORS = {'sTrogg_sl_Beeb': 'sTrogg_sr_Beeb', 'sTrogg_wl_Beeb': 'sTrogg_wr_Beeb',
           'sTrogg_yl_Beeb': 'sTrogg_yr_Beeb'}

# platforms drawn as strips: kind: (tile sprite, tile width, lit in row 0, lit in row 1)
PATTERNS = {'ledge': ('sLedge1_Beeb', 16, '#', 'm'), 'girder': ('sGirder1_Beeb', 12, '#', 'y')}
LOG_LIT = ('#', 'm')
LOGS = ['sLog%d_Beeb' % i for i in range(1, 7)]
MAX_STRIP = 512                     # pixels: the longest strip a pattern buffer covers

# every sprite a level can name, numbered: platforms (pieces, 5 bits) first
PLATFORM_SPRITES = (['sLedge%d_Beeb' % i for i in range(1, 8)] + ['sGirder%d_Beeb' % i for i in range(1, 8)] +
                    LOGS + ['sSpring_Beeb'])
SPRITE_IDS = PLATFORM_SPRITES + ['sLadder%d_Beeb' % i for i in range(1, 6)] + \
    ['sQiana%d_Beeb' % i for i in range(1, 5)] + \
    ['sChain%d_Beeb' % i for i in range(1, 5)] + \
    ['sGem_Beeb', 'sKey_Beeb', 'sBulb_Beeb', 'sScrubbly_Beeb', 'sPoglet_Beeb', 'sHooter_Beeb']
assert len(PLATFORM_SPRITES) <= 32 and len(SPRITE_IDS) <= 64
LADDER_SPRITES = ['sLadder%d_Beeb' % i for i in range(1, 6)] + ['sChain%d_Beeb' % i for i in range(1, 5)] + \
    ['sQiana%d_Beeb' % i for i in range(1, 5)]      # (the Qiana poles are ladders)
PATTERN_IDS = ['ledge', 'girder'] + LOGS     # a strip's pattern number


def grid_of(web, name, frame=0, frames=1):
    im = Image.open(os.path.join(web, 'assets', 'sprites', name + '.png')).convert('RGBA')
    fw = im.width // frames
    grid = []
    for y in range(im.height):
        row = ''
        for x in range(frame * fw, frame * fw + fw):
            r, g, b, a = im.getpixel((x, y))
            row += '.' if a < 128 else '#' if (r, g, b) == (0, 0, 0) else \
                'y' if (r > 200 and g > 200 and b < 100) else 'm'
        grid.append(row)
    return grid


def bits_to_bytes(bits):
    return [int(''.join(map(str, bits[i:i + 8])), 2) for i in range(0, len(bits), 8)]


def column_bytes(grid, lit):
    h, w = len(grid), len(grid[0])
    nb = math.ceil((h + 2 * COL_PAD) / 8)
    cols = []
    for c in range(w):
        bits = [0] * (8 * nb)
        for r in range(h):
            bits[COL_PAD + r] = 1 if grid[r][c] in lit else 0
        cols.append(bits_to_bytes(bits if c % 2 == 0 else bits[::-1]))
    return nb, cols


def row_bytes(grid, lit):
    w = len(grid[0])
    nb = math.ceil(w / 8)
    rows = []
    for r, line in enumerate(grid):
        bits = [1 if ch in lit else 0 for ch in line] + [0] * (8 * nb - w)
        rows.append(bits_to_bytes(bits if r % 2 == 0 else bits[::-1]))
    return nb, rows


def asm_bytes(values, per=16):
    return ['                fcb     ' + ','.join('$%02X' % v for v in values[i:i + per])
            for i in range(0, len(values), per)]


def label(name):
    return name.replace('_Beeb', '')[1:]


def build_sprites(data, web):
    """(assembler lines, {name: info}) for SPRITES, the patterns and the logs."""
    out = ['; made by vectrex/tools/vconvert.py: the sprites (see that script for the format)', '']
    info = {}
    for name, (how, lit, frames) in SPRITES.items():
        spr = data.sprites[name]
        grids = [grid_of(web, name, f, frames) for f in range(frames)]
        if how == 'cols':
            nb, _ = column_bytes(grids[0], lit)
            allb = [b for g in grids for col in column_bytes(g, lit)[1] for b in col]
            w, h = len(grids[0][0]), len(grids[0])
            out += ['spr_%s                                  ; %d x %d, %d frame(s), columns of %d bytes'
                    % (label(name), w, h, frames, nb),
                    '                fcb     %d,%d,%d,%d' % (w, nb, frames, 8 * nb),
                    '                fdb     %d,%s_d' % (round(8 * nb * UNIT), label(name)),
                    '                fcb     %d,%d' % (spr['xo'], spr['yo']),
                    '%s_d' % label(name)] + asm_bytes(allb)
        else:
            nb, _ = row_bytes(grids[0], lit)
            allb = [b for g in grids for row in row_bytes(g, lit)[1] for b in row]
            w, h = len(grids[0][0]), len(grids[0])
            out += ['rsp_%s                                  ; %d x %d, %d frame(s), rows of %d bytes'
                    % (label(name), w, h, frames, nb),
                    '                fcb     %d,%d,%d,%d' % (w, nb, h, frames),
                    '                fdb     %s_d' % label(name),
                    '                fcb     %d,%d' % (spr['xo'], spr['yo']),
                    '%s_d' % label(name)] + asm_bytes(allb)
        info[name] = {'how': how, 'nb': nb, 'w': w, 'h': h, 'frames': frames, 'bytes': len(allb), 'data': allb,
                      'grids': grids, 'lit': lit}
        out.append('')
    # the patterns: each row PERIOD bytes repeated to cover MAX_STRIP pixels (+ a period, for
    # starting part way along)
    for kind, (tile, tw, lit0, lit1) in PATTERNS.items():
        g = grid_of(web, tile)
        period_px = tw * 8 // math.gcd(tw, 8)            # whole bytes and whole tiles
        n = (MAX_STRIP + period_px) // 8
        row0 = bits_to_bytes([1 if g[0][x % tw] in lit0 else 0 for x in range(8 * n)])
        row1 = bits_to_bytes([1 if g[1][x % tw] in lit1 else 0 for x in range(8 * n)])
        # row 1 is swept to the left: reversed, so it can be read from any end position
        rev1 = [int('{:08b}'.format(b)[::-1], 2) for b in reversed(row1)]
        out += ['pat_%s_period    equ     %d                ; bytes' % (kind, period_px // 8),
                'pat_%s_0' % kind] + asm_bytes(row0) + ['pat_%s_1' % kind] + asm_bytes(rev1) + ['']
        info['pattern:' + kind] = {'period': period_px // 8, 'row0': row0, 'rev1': rev1, 'tw': tw}
    for name in LOGS:
        g = grid_of(web, name)
        w = len(g[0])
        nb = math.ceil(w / 8)
        row0 = bits_to_bytes([1 if x < w and g[0][x] in LOG_LIT[0] else 0 for x in range(8 * nb)])
        row1 = bits_to_bytes([1 if x < w and g[1][x] in LOG_LIT[1] else 0 for x in range(8 * nb)])
        rev1 = [int('{:08b}'.format(b)[::-1], 2) for b in reversed(row1)]
        out += ['log_%s_0                                ; %d pixels' % (label(name), w)] + asm_bytes(row0) + \
            ['log_%s_1' % label(name)] + asm_bytes(rev1) + ['']
        info['log:' + name] = {'w': w, 'nb': nb, 'row0': row0, 'rev1': rev1}
    out.append('sprite_table                            ; by sprite number (0 for none)')
    for name in SPRITE_IDS:
        if name in SPRITES:
            out.append('                fdb     %s_%s' % ('spr' if SPRITES[name][0] == 'cols' else 'rsp', label(name)))
        else:
            out.append('                fdb     0                       ; %s (a strip)' % label(name))
    return out, info


def check_mirrors(web):
    out = []
    for left, right in MIRRORS.items():
        frames = 4 if 'w' in left[7:9] else 1
        for f in range(frames):
            gl, gr = grid_of(web, left, f, frames), grid_of(web, right, f, frames)
            same = all(a == b[::-1] for a, b in zip(gl, gr))
            out.append('%s frame %d %s %s' % (left, f, 'mirrors' if same else 'DOES NOT mirror', right))
    return out


def decode_sprite(i, frame):
    """A sprite's pixels (rows of 0/1) back out of its bytes."""
    nb, w, h, d = i['nb'], i['w'], i['h'], i['data']
    if i['how'] == 'cols':
        base = frame * w * nb
        px = [[0] * w for _ in range(h)]
        for c in range(w):
            bits = [int(ch) for b in d[base + c * nb:base + c * nb + nb] for ch in '{:08b}'.format(b)]
            if c % 2:
                bits = bits[::-1]
            for r in range(h):
                px[r][c] = bits[COL_PAD + r]
        return px
    base = frame * h * nb
    out = []
    for r in range(h):
        bits = [int(ch) for b in d[base + r * nb:base + r * nb + nb] for ch in '{:08b}'.format(b)]
        out.append((bits if r % 2 == 0 else bits[::-1])[:w])
    return out


def preview_sheet(sinfo, path, scale=4):
    """Every sprite frame, decoded from its bytes, lit pixels as the beam's dots (green on black),
    beside the BBC sprite in its colours; checked against the grid it came from."""
    from PIL import ImageDraw
    tiles = []
    for name, i in sinfo.items():
        if name.startswith(('pattern:', 'log:')):
            continue
        for f in range(i['frames']):
            px = decode_sprite(i, f)
            grid = i['grids'][f]
            assert px == [[1 if ch in i['lit'] else 0 for ch in row] for row in grid], name
            tiles.append((label(name) + ('' if i['frames'] == 1 else ' %d' % f), px, grid))
    colours = {'#': (40, 40, 40), 'y': (230, 210, 40), 'm': (200, 60, 200), '.': (255, 255, 255)}
    cw, per = 2 * 52 * scale + 3 * 8, 5
    rows = (len(tiles) + per - 1) // per
    heights = [max(len(t[2]) for t in tiles[r * per:r * per + per]) * scale + 24 for r in range(rows)]
    tops = [sum(heights[:r]) for r in range(rows)]
    im = Image.new('RGB', (per * cw, sum(heights)), (0, 0, 0))
    dr = ImageDraw.Draw(im)
    for k, (title, px, grid) in enumerate(tiles):
        ox, oy = (k % per) * cw + 8, tops[k // per] + 4
        dr.text((ox, oy), title, fill=(160, 160, 160))
        oy += 14
        for r, row in enumerate(grid):
            for c, chr_ in enumerate(row):
                dr.rectangle([ox + c * scale, oy + r * scale, ox + c * scale + scale - 1, oy + r * scale + scale - 1],
                             fill=colours[chr_])
        bx = ox + len(grid[0]) * scale + 8
        for r, row in enumerate(px):
            for c, on in enumerate(row):
                if on:
                    x0, y0 = bx + c * scale, oy + r * scale
                    dr.ellipse([x0, y0, x0 + scale, y0 + scale], fill=(120, 255, 140))
    im.save(path)
    return len(tiles)


# --- the levels ----------------------------------------------------------------------------------

def sideways_levels(data):
    return [n for n in convert.LEVELS if data.rooms[n]['h'] == 256]


def strips_of(lev, data):
    """The level's static platforms as strips: runs of ledges or girders touching on a line, and
    logs one by one. (x, y, pattern number, length)."""
    pieces = []
    for i, ((x, y, w, h), spr) in enumerate(zip(lev['plats'], lev['plat_spr'])):
        if lev['plat_moving'][i]:
            continue
        if spr.startswith('sLedge'):
            pieces.append((y, x, 'ledge', w))
        elif spr.startswith('sGirder'):
            pieces.append((y, x, 'girder', w))
        elif spr.startswith('sLog'):
            pieces.append((y, x, spr, w))
    pieces.sort()
    strips = []
    for y, x, kind, w in pieces:
        if strips and kind in PATTERNS and strips[-1][2] == kind and strips[-1][1] == y and \
                strips[-1][0] + strips[-1][3] == x:
            sx, sy, sk, sw = strips[-1]
            strips[-1] = (sx, sy, sk, sw + w)
        else:
            strips.append((x, y, kind, w))
    strips.sort()
    return [(x, y, PATTERN_IDS.index(k), w) for x, y, k, w in strips]


def things_of(lev):
    """Things drawn that don't move: gems, keys, meanies standing still, and the springs under
    bouncy platforms that stay put. (x, sprite, y), sorted by x."""
    out = []
    for depth, _, spr, x, y, obj in lev['draw']:
        if (depth not in convert.CACHE_BG_DEPTHS or spr == 'sSpring_Beeb') and spr in SPRITE_IDS:
            out.append((x, SPRITE_IDS.index(spr), y))
    return sorted(out)


def s16(v):
    assert -32768 <= v < 65536, v
    return [(v >> 8) & 0xFF, v & 0xFF]


def encode_level(lev, data):
    b = []
    tx, ty = lev['trogg']
    pieces, ladders, things, slows, strips = [], [], things_of(lev), lev['slow'], strips_of(lev, data)
    for (x, y, w, h), spr, bouncy in zip(lev['plats'], lev['plat_spr'], lev['plat_bouncy']):
        assert 0 <= x < 1024 and 0 <= y < 256, (x, y)
        v = x << 14 | y << 6 | PLATFORM_SPRITES.index(spr) << 1 | bouncy
        pieces += [v >> 16, (v >> 8) & 0xFF, v & 0xFF]
    for (spr, yorig), (lx, ly, lh, ext) in zip(lev['ladder_spr'], lev['ladders']):
        assert ext < 16 and 0 <= yorig < 256
        ladders += s16(lx) + [yorig, LADDER_SPRITES.index(spr) << 4 | ext]
    thingb = []
    for x, sid, y in things:
        assert 0 <= x < 1024 and 0 <= y < 256
        v = x << 6 | sid
        thingb += [v >> 8, v & 0xFF, y]
    slowb = []
    for v in slows:
        k = v['kind']
        slowb.append(k)
        if k == convert.SL_SCRUBBLY:
            slowb += s16(v['x']) + [v['y']] + s16(v['amin']) + s16(v['amax']) + s16(v['v']) + [v['plat']]
        elif k == convert.SL_POGLET:
            p = v['param']
            slowb += s16(v['x']) + [v['y']] + s16(v['amin']) + s16(v['amax']) + s16(v['v']) + \
                [p[3] & 0xFF, p[4] & 0xFF, p[5] & 0xFF]
        elif k == convert.SL_HOOTER:
            slowb += s16(v['x']) + [v['y']] + s16(v['v']) + [v['wait']]
        else:
            flags = v['pflags'] & 0x7F | (0x80 if v.get('movable') else 0)
            slowb += [v['plat']] + s16(v['amin']) + s16(v['amax']) + s16(v['bmin']) + s16(v['bmax']) + \
                s16(v['v']) + [v['vy'] & 0xFF, v['wait'], flags]
    stripb = []
    for x, y, pat, w in strips:
        assert w < 512 and x < 1024
        v = x << 13 | pat << 9 | w
        stripb += [v >> 16, (v >> 8) & 0xFF, v & 0xFF, y]
    for name, n in (('pieces', len(lev['plats'])), ('ladders', len(lev['ladders'])), ('things', len(things)),
                    ('slows', len(slows)), ('strips', len(strips))):
        assert n < 256, (name, n)
    b += s16(lev['w']) + s16(tx) + [ty, 1 if lev['moving_enabled'] else 0]
    b += [len(lev['plats']), len(lev['ladders']), len(things), len(slows), len(strips)]
    return b + pieces + ladders + thingb + slowb + stripb, (things, strips)


def decode_level(b):
    """The reverse of encode_level (for the check)."""
    def u16(i):
        return b[i] << 8 | b[i + 1]

    def i16(i):
        v = u16(i)
        return v - 65536 if v >= 32768 else v
    out = {'w': u16(0), 'trogg': (u16(2), b[4]), 'moving_enabled': bool(b[5] & 1)}
    npl, nla, nth, nsl, nst = b[6:11]
    i = 11
    out['plats'] = []
    for _ in range(npl):
        v = b[i] << 16 | b[i + 1] << 8 | b[i + 2]
        out['plats'].append((v >> 14, (v >> 6) & 0xFF, PLATFORM_SPRITES[(v >> 1) & 0x1F], v & 1))
        i += 3
    out['ladders'] = []
    for _ in range(nla):
        out['ladders'].append((u16(i), b[i + 2], LADDER_SPRITES[b[i + 3] >> 4], b[i + 3] & 15))
        i += 4
    out['things'] = []
    for _ in range(nth):
        v = u16(i)
        out['things'].append((v >> 6, v & 63, b[i + 2]))
        i += 3
    out['slows'] = []
    for _ in range(nsl):
        k = b[i]
        i += 1
        if k == convert.SL_SCRUBBLY:
            out['slows'].append({'kind': k, 'x': u16(i), 'y': b[i + 2], 'amin': i16(i + 3), 'amax': i16(i + 5),
                                 'v': i16(i + 7), 'plat': b[i + 9]})
            i += 10
        elif k == convert.SL_POGLET:
            out['slows'].append({'kind': k, 'x': u16(i), 'y': b[i + 2], 'amin': i16(i + 3), 'amax': i16(i + 5),
                                 'v': i16(i + 7), 'yoff': tuple(b[i + 9:i + 12])})
            i += 12
        elif k == convert.SL_HOOTER:
            out['slows'].append({'kind': k, 'x': u16(i), 'y': b[i + 2], 'v': i16(i + 3), 'wait': b[i + 5]})
            i += 6
        else:
            vy = b[i + 11]
            out['slows'].append({'kind': k, 'plat': b[i], 'amin': i16(i + 1), 'amax': i16(i + 3),
                                 'bmin': i16(i + 5), 'bmax': i16(i + 7), 'v': i16(i + 9),
                                 'vy': vy - 256 if vy >= 128 else vy, 'wait': b[i + 12],
                                 'pflags': b[i + 13] & 0x7F, 'movable': bool(b[i + 13] & 0x80)})
            i += 14
    out['strips'] = []
    for _ in range(nst):
        v = b[i] << 16 | b[i + 1] << 8 | b[i + 2]
        out['strips'].append((v >> 13, b[i + 3], (v >> 9) & 15, v & 511))
        i += 4
    assert i == len(b), (i, len(b))
    return out


def check_level(name, lev, data, dec, things, strips):
    """Everything the game needs from build_level comes back out of the bytes."""
    errs = []
    if dec['w'] != lev['w'] or dec['trogg'] != tuple(lev['trogg']) or dec['moving_enabled'] != lev['moving_enabled']:
        errs.append('header')
    for (x, y, w, h), spr, bouncy, d in zip(lev['plats'], lev['plat_spr'], lev['plat_bouncy'], dec['plats']):
        info = data.sprites[d[2]]
        if (d[0], d[1], info['w'], info['h'], d[2], d[3]) != (x, y, w, h, spr, bouncy):
            errs.append('platform %s' % (d,))
    for (spr, yorig), lad, d in zip(lev['ladder_spr'], lev['ladders'], dec['ladders']):
        lx, ly, lh, ext = lad
        info = data.sprites[d[2]]
        rebuilt = (d[0], d[1] - d[3], info['h'] + convert.LADDER_EXTRA_LENGTH + d[3], d[3])
        if rebuilt != tuple(lad) or d[2] != spr or d[1] != yorig:
            errs.append('ladder %s against %s' % (rebuilt, lad))
    if dec['things'] != things:
        errs.append('things')
    for v, d in zip(lev['slow'], dec['slows']):
        for key, val in d.items():
            if key == 'yoff':
                if tuple(p & 0xFF for p in v['param'][3:6]) != val:
                    errs.append('slow %s yoff' % v['kind'])
            elif key == 'movable':
                if bool(v.get('movable')) != val:
                    errs.append('slow movable')
            elif v[key] != val:
                errs.append('slow %d %s: %s against %s' % (v['kind'], key, val, v[key]))
    if dec['strips'] != strips:
        errs.append('strips')
    # the strips cover exactly the static ledges', girders' and logs' tops
    cover = set()
    for x, y, pat, w in dec['strips']:
        cover |= {(y, px) for px in range(x, x + w)}
    want = set()
    for i, ((x, y, w, h), spr) in enumerate(zip(lev['plats'], lev['plat_spr'])):
        if not lev['plat_moving'][i] and not spr.startswith('sSpring'):
            want |= {(y, px) for px in range(x, x + w)}
    if cover != want:
        errs.append('strips cover %d pixels, the platforms %d' % (len(cover), len(want)))
    return errs


# --- the budget ----------------------------------------------------------------------------------

# measured in milestone 1 (vecx): cycles
TURN, BRA_EXTRA = 35, 3
MOVE_CHAINED, MOVE_RUNTIME = 250, 900       # a move worked out by the converter / by the 6809
STRIP_FIXED = 150                           # a strip's turn, set-up and ending
ROWS_FIXED = 60
TROGG = 'sTrogg_wr_Beeb'
FLYING = 3                                  # balloons and daggers at once (the most, at Insane)
HUD = 1000
LOGIC = 5000                                # the game logic (a guess until milestone 4 measures it)
FRAME = 30000


HALF = [False]       # (Trogg stays at full resolution)       # half resolution (1x2): columns 2 pixels apart, rows 2 apart, strips one row


def cols_cost(info, ncols, half=None):
    """ncols: the pixel columns in view."""
    if HALF[0] if half is None else half:
        ncols = (ncols + 1) // 2
    return ncols * (16 * info['nb'] + TURN) + (ncols // 2) * BRA_EXTRA


def rows_cost(info):
    h = (info['h'] + 1) // 2 if HALF[0] else info['h']
    return 16 * info['nb'] * h + ROWS_FIXED


def strip_cost(npx):
    nb = math.ceil(npx / 8)
    return 16 * nb + STRIP_FIXED // 2 if HALF[0] else 32 * nb + STRIP_FIXED


CATEGORIES = ('platforms', 'ladders', 'things', 'moving', 'fixed')


def level_budget(name, lev, data, sinfo, things, strips):
    """The busiest window position: (cost in cycles, x, {category: cycles}). Moving things are
    counted wherever in their range is worst."""
    W = WINDOW
    items = []      # (category, x0, x1, cost function of the visible part, chained?)
    for x, y, pat, w in strips:
        items.append(('platforms', x, x + w, lambda a, b: strip_cost(b - a), True))
    for (spr, yorig), (lx, ly, lh, ext) in zip(lev['ladder_spr'], lev['ladders']):
        info = sinfo[spr]
        xo = data.sprites[spr]['xo']
        items.append(('ladders', lx - xo, lx - xo + info['w'], lambda a, b, i=info: cols_cost(i, b - a), True))
    for x, sid, y in things:
        spr = SPRITE_IDS[sid]
        info = sinfo[spr]
        xo = data.sprites[spr]['xo']
        f = (lambda a, b, i=info: cols_cost(i, b - a)) if info['how'] == 'cols' else (lambda a, b, i=info: rows_cost(i))
        items.append(('things', x - xo, x - xo + info['w'], f, True))
    for v in lev['slow']:
        if v['kind'] == convert.SL_PLATFORM:
            w = data.sprites[v['spr']]['w']
            items.append(('moving', v['amin'], v['amax'] + w,
                          lambda a, b, w=w: strip_cost(min(w, b - a)), False))
        else:
            info = sinfo[v['spr']]
            xo = data.sprites[v['spr']]['xo']
            lo = v['amin'] if v['kind'] == convert.SL_SCRUBBLY else v['x']
            hi = v['amax'] if v['kind'] == convert.SL_SCRUBBLY else v['x']
            items.append(('moving', lo - xo, hi - xo + info['w'],
                          lambda a, b, i=info: cols_cost(i, min(i['w'], b - a)), False))
    fixed = cols_cost(sinfo[TROGG], sinfo[TROGG]['w'], False) + MOVE_RUNTIME + \
        FLYING * (cols_cost(sinfo['sBalloon_Beeb'], 12) + MOVE_RUNTIME) + HUD + LOGIC
    best = (0, 0, {})
    for x0 in range(0, max(1, lev['w'] - W + 1), 4):
        cat = dict.fromkeys(CATEGORIES, 0)
        cat['fixed'] = fixed
        for k, a, b, f, chained in items:
            va, vb = max(a, x0), min(b, x0 + W)
            if va < vb:
                cat[k] += f(va, vb) + (MOVE_CHAINED if chained else MOVE_RUNTIME)
        c = sum(cat.values())
        if c > best[0]:
            best = (c, x0, cat)
    return best


# --- main ----------------------------------------------------------------------------------------

def main():
    web = sys.argv[1] if len(sys.argv) > 1 else os.path.join(VEC, '..', '..', 'steamfrak')
    data = convert.Data(web)
    gen = os.path.join(VEC, 'gen')
    os.makedirs(gen, exist_ok=True)

    sprite_asm, sinfo = build_sprites(data, web)
    open(os.path.join(gen, 'sprites.asm'), 'w').write('\n'.join(sprite_asm) + '\n')
    for line in check_mirrors(web):
        print(line)
    print('preview: %d frames, decoded from their bytes, checked' %
          preview_sheet(sinfo, os.path.join(VEC, 'preview', 'sprites.png')))

    names = sideways_levels(data)
    out = ['; made by vectrex/tools/vconvert.py: the %d levels that scroll sideways (see that script)'
           % len(names), '', 'levels']
    out += ['                fdb     level_%s' % n[5:] for n in names]
    total, failures, budget = 0, 0, []
    for n in names:
        lev = convert.build_level(data, n)
        b, (things, strips) = encode_level(lev, data)
        dec = decode_level(b)
        errs = check_level(n, lev, data, dec, things, strips)
        if errs:
            failures += 1
            print('%s: %s' % (n, '; '.join(errs[:5])))
        out += ['', 'level_%s                                 ; %d bytes' % (n[5:], len(b))] + asm_bytes(b)
        total += len(b)
        cost, at, cat = level_budget(n, lev, data, sinfo, things, strips)
        HALF[0] = True
        hcost = level_budget(n, lev, data, sinfo, things, strips)[0]
        HALF[0] = False
        budget.append((n, cost, at, cat, hcost))
    open(os.path.join(gen, 'levels.asm'), 'w').write('\n'.join(out) + '\n')

    sbytes = sum(i['bytes'] for k, i in sinfo.items() if not k.startswith(('pattern:', 'log:')))
    pbytes = sum(len(i['row0']) + len(i['rev1']) for k, i in sinfo.items() if k.startswith(('pattern:', 'log:')))
    lines = ['Levels: %d, %d bytes in all (%d a level on average); sprites %d bytes, platform patterns %d.'
             % (len(names), total, total // len(names), sbytes, pbytes),
             'Every level decoded and checked against build_level: %s.' % ('all match' if not failures else
                                                                          '%d FAIL' % failures),
             '',
             'The busiest window (%d pixels) of each level, in cycles a frame: drawing (milestone 1\'s' % WINDOW,
             'measured costs), moves (%d chained for scenery, %d at run time for things that move),' % (MOVE_CHAINED, MOVE_RUNTIME),
             'Trogg, %d balloons or daggers, the HUD (%d) and the game logic (%d, a guess): against %d.'
             % (FLYING, HUD, LOGIC, FRAME),
             'Each split into platforms, ladders (and chains and poles), things (gems, keys, meanies',
             'standing still, springs), moving things (meanies, platforms) and the fixed part (Trogg,',
             'balloons or daggers, HUD, logic), each with its moves.', '',
             'The last column: at half resolution (1x2: columns 2 pixels apart at full height, rows 2',
             'apart, platforms one row; moves cost the same), all but Trogg.', '',
             '  level   total   at x  ' + ''.join('%10s' % k for k in CATEGORIES) + '      half']
    fit = hfit = 0
    for n, cost, at, cat, hcost in budget:
        fit += cost <= FRAME
        hfit += hcost <= FRAME
        mark = lambda c: '%6d%s' % (c, ' ' if c <= FRAME else '*')
        lines.append('  %-6s %s  %4d  %s  %s' % (n[5:], mark(cost), at, ''.join('%10d' % cat[k] for k in CATEGORIES),
                                             mark(hcost)))
    lines += ['', '(* over %d.) Levels that fit: %d of %d at full resolution, %d at half (Trogg full).'
              % (FRAME, fit, len(names), hfit)]
    open(os.path.join(gen, 'budget.txt'), 'w').write('\n'.join(lines) + '\n')
    print('\n'.join(lines[:2] + lines[-1:]))
    return sinfo, data, web


if __name__ == '__main__':
    main()
