#!/usr/bin/env python3
"""
Build BBC Master data for Frak! from the web version's data files.

Usage:
    python3 tools/convert.py ../steamfrak [starting room, default room_A_1]

Reads (from the steamfrak repository):
    js/data/rooms.js, js/data/objects.js, js/data/sprites.js, assets/sprites/*.png

Writes:
    build/GFX4                  the sprites, coded (see below), and their tables, for sideways RAM bank 4
    build/SPANS                 collision spans: solid pixels per row of each image (bank 6)
    build/PACK                  every level, packed (copied into HAZEL and ANDY at boot)
    build/levels.json           what the level loader should build for each level (for tests)
    src/gen/sprites.asm         image directory (size and origin)
    src/gen/imgdir.asm, imgdir3.asm  image directory (bank and address per shift; banks 7 and 5)
    src/gen/collide.asm         collision boxes and spans, save sizes, what each image is
    src/gen/levels.asm          where each level is, and the moving meanies' settings
    src/gen/consts.asm          constants: table sizes, start level, save areas
    src/gen/tables.asm          mask and identity tables
    src/gen/disc.asm, boot.txt  the disc's file list and !BOOT

Sprites are MODE 1 (2 bits per pixel, 4 pixels per byte). Logical colour 0 is the level
background and is always transparent. A sprite drawn at pixel offset s (0-3) within a byte
needs, for each screen byte, 4 pixels that straddle two of its own bytes; rather than storing
it four times, pre-shifted, each byte is stored as a code for 5 pixels: in stream A, pixels
4k-1 to 4k+3 (the leftmost 4 are its byte k at shift 1, the rightmost 4 at shift 0); in stream
B, pixels 4k-3 to 4k+1 (shifts 3 and 2). The graphics use fewer than 256 different 5-pixel
values, so a code is a byte, and four tables (in bank 4, with all the sprites) give each
code's left and right 4 pixels as a screen byte, and the mask for each (both bits set for a
transparent pixel). Code 0 is 5 transparent pixels, 1-127 have some transparent, and 128-255
are 5 solid pixels, which the plotter stores without masking. The data is column by column (each byte
column is "height" codes, top to bottom), the order the plotter walks the screen.
"""
import json
import math
import os
import re
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BANKS = [4, 5]                  # Master 128 sideways RAM banks for sprites (6 = spans, 7 = level cache)
BANK_SIZE = 0x4000
CODE_TABLES = 0xBC00            # in bank 4, after the sprites: left pixels, left mask, right pixels, right mask
CODED = 0x80                    # (in an image's bank number: its data is 5-pixel codes, not screen bytes)

# MODE 1 logical colours (palette set per level): 0 = background, 1 = black, 2 = magenta, 3 = yellow
COLOURS = {(0, 0, 0): 1, (255, 0, 255): 2, (255, 255, 0): 3}
# Level background colours -> BBC physical colours
BG_PHYSICAL = {'#00f0f0': 6, '#00f000': 2, '#00e000': 2, '#be1f13': 1}

TROGG_FRAMES = ['sTrogg_%s_Beeb' % k for k in 'sr sl wr wl yr yl cn cu cd'.split()]
TROGG_SPLIT = {'sTrogg_%s_Beeb' % k for k in 'sr sl wr wl'.split()}     # drawn as body + legs
TROGG_BODY = 24                 # rows of Trogg's body (above his legs)
# Sprites drawn at any x position, so they need all four pre-shifted copies
BADGES = ['s%s_Beeb' % k for k in ('Rating_1', 'Rating_2', 'Rating_3', 'Rating_Tick', 'TrophyStand')]
# the menus' small icons, kept as plain data in the front end (drawn byte-aligned)
ICONS = ['s%s_Beeb' % k for k in ('Rating_1_Small', 'Rating_2_Small', 'Rating_3_Small', 'Rating_Tick_Small',
                                  'Rating_None_Small', 'Gem_Small', 'Gem_Outline_Small', 'Stopwatch_Small',
                                  'Stopwatch_Outline_Small')]
MOVING_SPRITES = TROGG_FRAMES + ['sBalloon_Beeb', 'sDaggerLR_Beeb', 'sDaggerUD_Beeb', 'sYoyo_Beeb',
                                 'sFrak_Beeb', 'sScrubbly_Beeb', 'sPoglet_Beeb', 'sHooter_Beeb',
                                 'sSpring_Beeb'] + \
    BADGES
MOVING_OBJECTS = {'oScrubbly', 'oPoglet', 'oHooter'}

# Draw order for scenery (GameMaker depth: higher drawn first)
DEPTH = {'oPlatform': 11, 'oLadder': 10, 'oBulb': 8, 'oKey': 7, 'oGem': 6, 'oMeanie': 5}

MAX_HEIGHT = 1024
LADDER_EXTRA_LENGTH = 16


def load_js(web, path):
    s = open(os.path.join(web, path), encoding='utf-8').read()
    s = s[s.index('= ') + 2:s.rstrip().rindex(';')]
    return json.loads(s)


class Data:
    def __init__(self, web):
        self.web = web
        self.rooms = load_js(web, 'js/data/rooms.js')
        self.objects = load_js(web, 'js/data/objects.js')
        self.sprites = load_js(web, 'js/data/sprites.js')

    def parents(self, obj):
        while obj:
            yield obj
            obj = self.objects[obj]['parent']

    def sprite_of(self, obj):
        for o in self.parents(obj):
            if self.objects[o]['sprite']:
                return self.objects[o]['sprite']
        return None

    def kind(self, obj):
        for o in self.parents(obj):
            if o in DEPTH:
                return o
        return None

    def props(self, inst):
        p = {}
        for o in reversed(list(self.parents(inst[0]))):
            p.update(self.objects[o]['props'])
        if len(inst) > 3:
            p.update(inst[3])
        return p


# --- Sprites -------------------------------------------------------------------------------------

def sprite_pixels(data, name):
    """Return list of frames, each a list of rows of logical colours."""
    info = data.sprites[name]
    im = Image.open(os.path.join(data.web, 'assets/sprites', name + '.png')).convert('RGBA')
    frames = []
    for f in range(info['n']):
        rows = []
        for y in range(info['h']):
            row = []
            for x in range(info['w']):
                r, g, b, a = im.getpixel((f * info['w'] + x, y))
                if a < 128:
                    row.append(0)
                elif (r, g, b) in COLOURS:
                    row.append(COLOURS[(r, g, b)])
                elif r > 150 and g > 150 and b < 80:
                    row.append(3)       # yellowish
                elif r > 150 and b > 150:
                    row.append(2)       # magentaish
                else:
                    row.append(1)
            rows.append(row)
        frames.append(rows)
    return frames


def mode1_byte(pixels):
    """Four logical colours (left to right) -> one MODE 1 screen byte."""
    b = 0
    for p, c in enumerate(pixels):
        b |= ((c >> 1) & 1) << (7 - p)
        b |= (c & 1) << (3 - p)
    return b


def shifted_columns(rows, shift):
    """Encode one frame at a horizontal pixel shift; return bytes, column-major."""
    h = len(rows)
    w = len(rows[0])
    wb = (shift + w + 3) // 4
    out = bytearray()
    for col in range(wb):
        for y in range(h):
            px = []
            for p in range(4):
                sx = col * 4 + p - shift
                px.append(rows[y][sx] if 0 <= sx < w else 0)
            out.append(mode1_byte(px))
    return bytes(out)


# The code for each 5-pixel value the graphics use (see number_windows)
WINDOWS = {}


def window_columns(rows, first, nb):
    """One frame as nb byte columns of 5-pixel values, window k being pixels first + 4k to
    first + 4k + 4 (see the module docstring), column by column"""
    w = len(rows[0])
    return [tuple(row[x] if 0 <= x < w else 0 for x in range(first + 4 * col, first + 4 * col + 5))
            for col in range(nb) for row in rows]


def number_windows(windows):
    """Code 0 for 5 transparent pixels, 1-127 for those with some transparent, 128-255 for 5
    solid pixels (which the plotter just stores, unmasked: it tests bit 7 first)"""
    empty = (0, 0, 0, 0, 0)
    some = [v for v in dict.fromkeys(windows) if v != empty and 0 in v]
    solid = [v for v in dict.fromkeys(windows) if 0 not in v]
    if len(some) > 127 or len(solid) > 128:
        raise SystemExit('The graphics use %d partly transparent and %d solid 5-pixel values; '
                         'at most 127 and 128 can be coded' % (len(some), len(solid)))
    WINDOWS[empty] = 0
    WINDOWS.update({v: 1 + i for i, v in enumerate(some)})
    WINDOWS.update({v: 128 + i for i, v in enumerate(solid)})


def code_tables():
    """Each code's left 4 pixels as a screen byte, their mask, then the same for its right 4"""
    mask = mask_table()
    lpix, rpix = [0] * 256, [0] * 256
    for v, c in WINDOWS.items():
        lpix[c], rpix[c] = mode1_byte(v[:4]), mode1_byte(v[1:])
    return bytes(lpix + [mask[b] for b in lpix] + rpix + [mask[b] for b in rpix])


def row_spans(rows):
    """Leftmost and rightmost solid pixel of each row ((255, 0) for an empty row)."""
    spans = []
    for row in rows:
        solid = [x for x, c in enumerate(row) if c]
        spans.append((solid[0], solid[-1]) if solid else (255, 0))
    return spans


def mask_table():
    """mask[d] has both bits set for every pixel of d that is colour 0 (transparent)."""
    t = []
    for d in range(256):
        m = 0
        for p in range(4):
            if not (d >> (7 - p)) & 1 and not (d >> (3 - p)) & 1:
                m |= (1 << (7 - p)) | (1 << (3 - p))
        t.append(m)
    return t


# --- Levels --------------------------------------------------------------------------------------

def needed_shifts(data):
    """
    Which of the four pixel-shifted copies of each sprite the game needs:
    * sprites that move get all four;
    * platforms that move (or that Trogg can move) get all four;
    * static platforms and ladders get none - they are in the pre-rendered background;
    * other static things (keys, gems, meanies that don't move) get only the shifts at
      which some level places them.
    """
    need = {s: {0, 1, 2, 3} for s in MOVING_SPRITES}
    for name, room in data.rooms.items():
        if not name.startswith('room_'):
            continue
        for inst in room['inst']:
            spr = data.sprite_of(inst[0])
            kind = data.kind(inst[0])
            if not spr or inst[0] in ('oRoom', 'oTrogg') or kind is None:
                continue
            p = data.props(inst)
            moving = inst[0] in MOVING_OBJECTS or any(p.get(k) for k in (
                'scan_left', 'scan_right', 'scan_up', 'scan_down', 'is_movable_by_trogg'))
            if moving:
                need.setdefault(spr, set()).update({0, 1, 2, 3})
            elif kind not in ('oPlatform', 'oLadder'):
                need.setdefault(spr, set()).add((int(inst[1]) - data.sprites[spr]['xo']) % 4)
    return need


def platform_find(plats, x, y1, y2):
    """Port of PlatformFind: first platform top in [ceil(y1), y2) under column x."""
    best = None
    for (px, py, pw, ph) in plats:
        if math.ceil(y1) <= py < y2 and px <= x < px + pw:
            if best is None or py < best:
                best = py
    return best


SL_SCRUBBLY, SL_POGLET, SL_HOOTER, SL_PLATFORM = 1, 2, 3, 4


def platform_find_index(plats, x, y1, y2):
    """PlatformFind: the platform whose top is first in [ceil(y1), y2) under column x, or None."""
    best = None
    for i, (px, py, pw, ph) in enumerate(plats):
        if math.ceil(y1) <= py < y2 and px <= x < px + pw:
            if best is None or py < plats[best][1]:
                best = i
    return best


def ladder_find_down(ladders, x, y1, y2):
    """LadderFind going down (not on a platform): the ladder index found, or None."""
    ry, found = y1, None
    for i, (lx, ly, lh, ext) in enumerate(ladders):
        if abs(x - lx) > 6:
            continue
        if ry < ly + lh - 1 and y2 >= ly:
            found = i
            ry = min(y2, ly + lh - 1)
            if ry == y2:
                break
    return found


def fixed88(v):
    return int(round(v * 256))


def build_level(data, room_name):
    room = data.rooms[room_name]
    # (stray objects far outside the level are left out)
    insts = [inst for inst in room['inst'] if -256 <= int(inst[1]) < 2048 and -256 <= int(inst[2]) < 2048]
    plats, plat_order, plat_spr, ladders, ladder_spr, draw, trogg = [], [], [], [], [], [], None
    plat_bouncy = []
    moving_enabled = False
    for order, inst in enumerate(insts):
        obj, x, y = inst[0], int(inst[1]), int(inst[2])
        if obj == 'oRoom':
            moving_enabled = bool(data.props(inst).get('moving_enabled'))
        kind = data.kind(obj)
        spr = data.sprite_of(obj)
        if obj == 'oTrogg':
            trogg = (x, y)
            continue
        if kind is None or spr is None:
            continue
        info = data.sprites[spr]
        if kind == 'oPlatform':
            plats.append((x, y, info['w'], info['h']))
            plat_order.append(order)
            plat_spr.append(spr)
            plat_bouncy.append(1 if data.props(inst).get('is_bouncy') else 0)
        draw.append((DEPTH[kind], order, spr, x, y, obj))
    # Ladders reach up to the platform above them (LadderAdd)
    for order, inst in enumerate(insts):
        obj, x, y = inst[0], int(inst[1]), int(inst[2])
        if data.kind(obj) != 'oLadder':
            continue
        ladder_spr.append((data.sprite_of(obj), y))
        info = data.sprites[data.sprite_of(obj)]
        h = info['h'] + LADDER_EXTRA_LENGTH
        found = platform_find(plats, x, y - LADDER_EXTRA_LENGTH, y - 1)
        extra = 0 if found is None else y - found - 1
        ladders.append((x, y - extra, h + extra, extra))

    # "Slow sprites": moving platforms and meanies, with their motion worked out the way the
    # GameMaker objects did on their first step (oPlatform, oScrubbly, oPoglet, oHooter)
    slow = []
    moving_orders = set()
    for pi, (px, py, pw, ph) in enumerate(plats):
        inst = insts[plat_order[pi]]
        p = data.props(inst)
        if p.get('is_movable_by_trogg'):
            # Trogg moves it with his yoyo: a slow sprite that doesn't move by itself
            assert not any(p.get(k) for k in ('scan_left', 'scan_right', 'scan_up', 'scan_down')), inst
            moving_orders.add(plat_order[pi])
            slow.append({'kind': SL_PLATFORM, 'spr': data.sprite_of(inst[0]), 'x': px, 'y': py,
                         'amin': px, 'amax': px, 'bmin': py, 'bmax': py, 'v': 0, 'vy': 0,
                         'plat': pi, 'wait': 5, 'pflags': PF_MOVABLE, 'movable': True})
            continue
        if not any(p.get(k) for k in ('scan_left', 'scan_right', 'scan_up', 'scan_down')):
            continue
        xl = xr = px
        yu = yd = py
        if p.get('scan_left'):
            for xco in range(px - 1, -1, -1):
                if platform_find_index(plats, xco, py, py + ph) is not None:
                    xl = xco + 1
                    break
        if p.get('scan_right'):
            for xco in range(px + pw, 1000):
                if platform_find_index(plats, xco, py, py + ph) is not None:
                    xr = xco - pw
                    break
        hits = lambda yco: (platform_find_index(plats, px - 1, yco - 1, yco) is not None or
                            platform_find_index(plats, px + pw, yco - 1, yco) is not None)
        if p.get('scan_up'):
            for yco in range(py - 1, -1, -1):
                if hits(yco):
                    yu = yco - 1
                    break
        if p.get('scan_down'):
            for yco in range(py + 1, 1000):
                if hits(yco):
                    yd = yco - 1
                    break
        vx = (1 if p.get('start_moving_right') else -1) if xl != xr else 0
        vy = (1 if p.get('start_moving_up') else -1) if yu != yd else 0     # (sic: "up" = +1)
        if vx == 0 and vy == 0:
            continue
        moving_orders.add(plat_order[pi])
        slow.append({'kind': SL_PLATFORM, 'spr': data.sprite_of(inst[0]), 'x': px, 'y': py,
                     'amin': xl, 'amax': xr, 'bmin': yu, 'bmax': yd, 'v': vx * 256, 'vy': vy,
                     'plat': pi, 'wait': 5,
                     'pflags': sum(1 << i for i, k in enumerate(('scan_left', 'scan_right', 'scan_up', 'scan_down',
                                                                  'start_moving_right', 'start_moving_up')) if p.get(k))})
    if moving_enabled:
        for order, inst in enumerate(insts):
            obj, x, y = inst[0], int(inst[1]), int(inst[2])
            if data.kind(obj) != 'oMeanie':
                continue
            p = data.props(inst)
            spr = data.sprite_of(obj)
            item = None
            if obj == 'oScrubbly':
                pi = platform_find_index(plats, x, y - 1, y + 3)
                v = fixed88(p.get('default_x_velocity', 0))
                if pi is not None and v:
                    px, py, pw, ph = plats[pi]
                    item = {'kind': SL_SCRUBBLY, 'amin': px + 8, 'amax': px + pw - 1 - 8, 'v': v,
                            'plat': pi if p.get('follow_platform_y') else 255,
                            'param': (SL_SCRUBBLY, v, 0, 1 if p.get('follow_platform_y') else 0, 0, 0)}
            elif obj == 'oPoglet':
                v = fixed88(p.get('default_y_velocity', 0))
                lo = hi = None
                yoff = (0, 0, 0)
                if p.get('yoff_min', 0) or p.get('yoff_max', 0):
                    lo, hi = y + p.get('yoff_min', 0), y + p.get('yoff_max', 0)
                    yoff = (2, p.get('yoff_min', 0), p.get('yoff_max', 0))
                else:
                    li = ladder_find_down(ladders, x, y - 16, y + 4)
                    if li is not None:
                        lx, ly, lh, ext = ladders[li]
                        lo, hi = ly + 30, ly + lh - 1 + 14
                if lo is not None and v:
                    vv = -v if p.get('initially_go_down') else v
                    item = {'kind': SL_POGLET, 'amin': lo, 'amax': hi, 'v': vv,
                            'param': (SL_POGLET, vv, 0) + yoff}
            elif obj == 'oHooter':
                v = fixed88(p.get('initial_jump_velocity', 0))
                if v:
                    wait = min(255, int(p.get('initial_sleep_ticks', 0)))
                    item = {'kind': SL_HOOTER, 'v': v, 'wait': wait, 'param': (SL_HOOTER, v, wait, 0, 0, 0)}
            if item:
                base = {'spr': spr, 'x': x, 'y': y, 'amin': 0, 'amax': 0, 'bmin': 0, 'bmax': 0,
                        'vy': 0, 'plat': 255, 'wait': 0, 'order': order}
                base.update(item)
                slow.append(base)
                moving_orders.add(order)

    draw = [d for d in draw if d[1] not in moving_orders]
    # a spring under each bouncy platform that stays put (oPlatform's Draw event), drawn just
    # after it, into the background
    for (px, py, pw, ph), order, spr, bouncy in zip(plats, plat_order, plat_spr, plat_bouncy):
        if bouncy and order not in moving_orders:
            draw.append((DEPTH['oPlatform'], order + 0.5, 'sSpring_Beeb', px + pw // 2,
                         py + ph - (3 if re.match(r'sLog[1-5]_Beeb$', spr) else 0), 'spring'))
    draw.sort(key=lambda d: (-d[0], d[1]))
    movable = {plat_order[v['plat']] for v in slow if v.get('movable')}
    plat_moving = [2 if o in movable else 1 if o in moving_orders else 0 for o in plat_order]
    return {
        'w': room['w'], 'h': room['h'], 'bg': BG_PHYSICAL.get(room['bg'], 6),
        'trogg': trogg, 'plats': plats, 'plat_moving': plat_moving, 'ladders': ladders,
        'plat_spr': plat_spr, 'ladder_spr': ladder_spr, 'plat_bouncy': plat_bouncy,
        'draw': draw, 'slow': slow, 'moving_enabled': moving_enabled,
    }


# --- Pre-rendered background ---------------------------------------------------------------------

CACHE_BANK = 7
SPANS_BANK = 6                  # collision data
CACHE_BG_DEPTHS = (DEPTH['oPlatform'], DEPTH['oLadder'])     # things that never change


def render_background(data, lev, frames_cache):
    """
    Composite the platforms and ladders into a level-sized image of logical colours, then pack
    it into bank 7 the way the level loader does (this is the reference the tests compare it with).
    A horizontally scrolling level is stored as columns of character cells, a vertically
    scrolling one (320 pixels wide) as rows:
      &8000/&8100  the address of each column (or row): low, high bytes; 0 past the level's end
      &8200        the cell dictionary: each distinct non-empty character cell (8 bytes), numbered
                   in order of first use, in pages of 256 cells (2KB each, as many as needed).
                   Line L of cell N is at &8200 + (N DIV 256) * &800 + L * &100 + (N MOD 256)
      then         the columns (or rows), straight after the dictionary: three masks, of the
                   non-empty cells (bit 7 of the first byte = the top cell, or the leftmost),
                   then bit 8 and bit 9 of their numbers, then each non-empty cell's number's
                   low byte. The masks are 4 bytes each for a column, 10 for a row.
    Returns (tables, dictionary as a list of cells, the column or row data, where it starts).
    """
    w, h = lev['w'], lev['h']
    cols = (w + 3) // 4
    cells_down = (h + 7) // 8
    rows = h > 256
    img = [[0] * (cols * 4) for _ in range(cells_down * 8)]
    for depth, _, spr, x, y, _ in lev['draw']:
        if depth not in CACHE_BG_DEPTHS:
            continue
        info = data.sprites[spr]
        frows = frames_cache(spr)[0]
        left, top = x - info['xo'], y - info['yo']
        for sy, row in enumerate(frows):
            for sx, c in enumerate(row):
                px, py = left + sx, top + sy
                if c and 0 <= px < cols * 4 and 0 <= py < h:
                    img[py][px] = c
    def cell(col, crow):
        return bytes(mode1_byte([img[crow * 8 + line][col * 4 + p] for p in range(4)]) for line in range(8))
    lines = [[cell(c, r) for r in range(cells_down)] for c in range(cols)] if not rows else \
            [[cell(c, r) for c in range(cols)] for r in range(cells_down)]
    dictionary, number = [], {}
    for line in lines:
        for key in line:
            if any(key) and key not in number:
                number[key] = len(dictionary)
                dictionary.append(key)
    pages = max(1, (len(dictionary) + 255) // 256)
    start = BG_DICT + pages * 0x800
    blob = bytearray()
    offsets = []
    mbytes = (len(lines[0]) + 7) // 8
    for line in lines:
        offsets.append(start + len(blob))
        mask = b8 = b9 = 0
        nums = bytearray()
        for i, key in enumerate(line):
            if any(key):
                n = number[key]
                bit = 1 << (mbytes * 8 - 1 - i)
                mask |= bit
                b8 |= bit if n & 256 else 0
                b9 |= bit if n & 512 else 0
                nums.append(n & 0xFF)
        blob += mask.to_bytes(mbytes, 'big') + b8.to_bytes(mbytes, 'big') + b9.to_bytes(mbytes, 'big') + nums
    if len(lines) > 256 or len(dictionary) > 1024 or start + len(blob) > BG_TOP:
        raise SystemExit('Background too big: %d lines, %d distinct cells, data to &%04X'
                         % (len(lines), len(dictionary), start + len(blob)))
    tables = bytearray(0x200)
    for i, off in enumerate(offsets):
        tables[i] = off & 0xFF
        tables[0x100 + i] = off >> 8
    return (bytes(tables), dictionary, bytes(blob), start), img


def slow_swept(data, v):
    """The pixel rectangle (left, top, right, bottom) a slow sprite can ever cover, with its
    columns widened to whole bytes."""
    info = data.sprites[v['spr']]
    x0, x1, y0, y1 = v['x'], v['x'], v['y'], v['y']
    if v['kind'] == SL_PLATFORM:
        x0, x1 = min(v['x'], v['amin']), max(v['x'], v['amax'])
        y0, y1 = min(v['y'], v['bmin']), max(v['y'], v['bmax'])
    elif v['kind'] == SL_SCRUBBLY:
        x0, x1 = v['amin'], v['amax']
    elif v['kind'] == SL_POGLET:
        y0, y1 = v['amin'], v['amax']
    elif v['kind'] == SL_HOOTER:
        # simulate a jump (as move_hooter does) to find how high it goes
        vel, y = v['v'], v['y'] * 256
        while True:
            vel -= 13
            y -= vel
            if y >= v['y'] * 256:
                break
            y0 = min(y0, y // 256)
    left = ((x0 - info['xo']) // 4) * 4
    right = ((x1 - info['xo'] + info['w'] - 1) // 4) * 4 + 3
    return left, y0 - info['yo'], right, y1 - info['yo'] + info['h'] - 1


def slow_simple_flags(data, lev, draw):
    """For each slow sprite, 1 if nothing else is ever drawn in the character cells it can
    cover: no keys, gems, static meanies or other slow sprites (platforms and ladders are
    fine, being in the background cache). Those can be redrawn in one pass over their cells,
    copying the sprite straight in where the background is empty (move_redraw)."""
    sl = lev['slow']
    cells = lambda r: (r[0], r[1] // 8 * 8, r[2], r[3] // 8 * 8 + 7)
    rects = [cells(slow_swept(data, v)) for v in sl]
    overlap = lambda a, b: a[0] <= b[2] and b[0] <= a[2] and a[1] <= b[3] and b[1] <= a[3]
    items = []
    for (_, _, spr, x, y, _) in draw:
        info = data.sprites[spr]
        items.append((x - info['xo'], y - info['yo'], x - info['xo'] + info['w'] - 1, y - info['yo'] + info['h'] - 1))
    flags = []
    for i, (v, r) in enumerate(zip(sl, rects)):
        raw = slow_swept(data, v)
        ok = (v['plat'] == 255 or v['kind'] == SL_PLATFORM) and raw[0] >= 0 and raw[1] >= 0 and raw[3] <= 254
        ok = ok and not v.get('movable')    # (it can go anywhere)
        ok = ok and lev['h'] == 256         # (only for horizontally scrolling levels)
        ok = ok and not any(overlap(r, rects[j]) for j in range(len(sl)) if j != i)
        ok = ok and not any(overlap(r, it) for it in items)
        flags.append(1 if ok else 0)
    return flags


# --- Jump / fall table ---------------------------------------------------------------------------

# --- Output --------------------------------------------------------------------------------------

def asm_bytes(label, values, per_line=16):
    lines = ['.%s' % label] if label else []
    for i in range(0, len(values), per_line):
        lines.append('    EQUB ' + ', '.join(v if isinstance(v, str) else '&%02X' % (v & 0xFF)
                                               for v in values[i:i + per_line]))
    return '\n'.join(lines) + '\n'


def asm_ident(name):
    return ''.join(c if c.isalnum() else '_' for c in name)


LEVELS = ['room_0'] + ['room_%s_%d' % (c, n) for c in 'ABCDEF' for n in range(1, 10)]
# Where the level pack goes: HAZEL (&C000-&DFFF) and ANDY (&8000-&8FFF), except &8800-&88FF of
# ANDY, which the MOS uses. No level straddles two of these.
PACK_SEGMENTS = [(0xC000, 0x2000), (0x8000, 0x800), (0x8900, 0x700)]
SLOWSAVE1_SIZE = 0x400          # the second save area for meanies flying off is in bank 6
BG_DICT = 0x8200                # the unrolled background, in bank 7 (see render_background)
BG_TOP = 0xAA00                 # ... which must end here (the front end's records follow it)
MAX_PAL = 16
PF_MOVABLE = 64                 # a moving platform that Trogg moves (is_movable_by_trogg)


def bg_sprites(data):
    """Sprites drawn as static platforms or ladders in some level (unrolled at run time)."""
    out = set()
    for name in LEVELS:
        for inst in data.rooms[name]['inst']:
            if data.kind(inst[0]) in ('oPlatform', 'oLadder'):
                out.add(data.sprite_of(inst[0]))
    return out


def level_tables(data, lev, image_id, simple):
    """What the 6502 loader should build for a level (for tests/check_levels.mjs)."""
    p, lad, sl = lev['plats'], lev['ladders'], lev['slow']
    d = [item for item in lev['draw'] if item[0] not in CACHE_BG_DEPTHS]
    info = lambda spr: data.sprites[spr]
    t = {'plat_x': [v[0] for v in p], 'plat_y': [v[1] for v in p], 'plat_w': [v[2] for v in p],
         'plat_moving': lev['plat_moving'], 'plat_bouncy': [128 * b for b in lev['plat_bouncy']],
         'lad_x': [v[0] for v in lad], 'lad_y': [v[1] for v in lad], 'lad_h': [v[2] for v in lad],
         'lad_ext': [v[3] for v in lad],
         'draw_img': [image_id[(spr, 0)] for (_, _, spr, _, _, _) in d],
         'draw_x': [v[3] for v in d], 'draw_y': [v[4] for v in d],
         'sl_kind': [v['kind'] for v in sl], 'sl_img': [image_id[(v['spr'], 0)] for v in sl],
         'sl_x0': [v['x'] for v in sl], 'sl_y0': [v['y'] for v in sl],
         'sl_amin': [v['amin'] for v in sl], 'sl_amax': [v['amax'] for v in sl],
         'sl_bmin': [v['bmin'] for v in sl], 'sl_bmax': [v['bmax'] for v in sl],
         'sl_v': [v['v'] & 0xFFFF for v in sl], 'sl_vy': [v['vy'] & 0xFF for v in sl],
         'sl_plat': [v['plat'] for v in sl], 'sl_wait': [v['wait'] for v in sl], 'sl_simple': simple,
         'trogg': list(lev['trogg']), 'w': lev['w'], 'h': lev['h'], 'bg': lev['bg']}
    return t


def pack_level(data, lev, image_id, params):
    """
    A level in its packed form (unpacked by load_level in frak.asm):
      header: byte columns, character rows, background colour, Trogg's x and y (2 bytes each),
              flags (bit 0 = meanies move), then counts of: palette entries, platforms, ladders,
              objects, moving meanies, moving platforms
      palette: the image of each sprite the level uses (+ 128 for a bouncy platform's)
      platforms, ladders, objects (in drawing order) and moving meanies: 3 bytes each,
              x low, y low, then x high (bits 0-1), y high (bits 2-3), palette entry (bits 4-7)
      moving meanies: a byte each, settings (index into sl_params) + 128 if drawn the simple way
      moving platforms: 2 bytes each, platform number, then scan and direction flags
              (bits 0-5: scan left, right, up, down, start right, start up; bit 6: moved by
              Trogg (with his yoyo) instead; bit 7 = simple)
    """
    d = [item for item in lev['draw'] if item[0] not in CACHE_BG_DEPTHS]
    meanies = [v for v in lev['slow'] if v['kind'] != SL_PLATFORM]
    mplats = [v for v in lev['slow'] if v['kind'] == SL_PLATFORM]
    simple = slow_simple_flags(data, lev, d)
    pal = []
    def pe(spr, flag=0):
        img = image_id[(spr, 0)] | flag
        if img not in pal:
            pal.append(img)
        return pal.index(img)
    def rec(x, y, spr, flag=0):
        assert 0 <= x < 1024 and 0 <= y < 1024, (x, y)
        return bytes((x & 0xFF, y & 0xFF, (x >> 8) | ((y >> 8) << 2) | (pe(spr, flag) << 4)))
    body = bytearray()
    for (x, y, w, h), spr, bouncy in zip(lev['plats'], lev['plat_spr'], lev['plat_bouncy']):
        body += rec(x, y, spr, 128 if bouncy else 0)
    for spr, y in lev['ladder_spr']:
        lx = lev['ladders'][len(body) // 3 - len(lev['plats'])][0]
        body += rec(lx, y, spr)
    for (_, _, spr, x, y, _) in d:
        body += rec(x, y, spr)
    for v in meanies:
        body += rec(v['x'], v['y'], v['spr'])
    sflags = simple[len(mplats):]
    for v, sf in zip(meanies, sflags):
        if v['param'] not in params:
            params.append(v['param'])
        body.append(params.index(v['param']) | (128 if sf else 0))
    for v, sf in zip(mplats, simple):
        body += bytes((v['plat'], v['pflags'] | (128 if sf else 0)))
    if len(pal) > MAX_PAL:
        raise SystemExit('Too many sprites in one level: %d' % len(pal))
    tx, ty = lev['trogg']
    head = bytes(((lev['w'] + 3) // 4, (lev['h'] + 7) // 8, lev['bg'], tx & 0xFF, tx >> 8, ty & 0xFF, ty >> 8,
                  1 if lev['moving_enabled'] else 0, len(pal), len(lev['plats']), len(lev['ladders']),
                  len(d), len(meanies), len(mplats)))
    return head + bytes(pal) + bytes(body), simple


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    web = sys.argv[1]
    start_room = sys.argv[2] if len(sys.argv) > 2 else 'room_A_1'
    data = Data(web)
    gen = os.path.join(ROOT, 'src', 'gen')
    build = os.path.join(ROOT, 'build')
    os.makedirs(gen, exist_ok=True)
    os.makedirs(build, exist_ok=True)

    # ---- graphics: every sprite any level needs, in sprite banks 4 and 5 (first fit)
    need = needed_shifts(data)
    bg_only = set()
    for spr in bg_sprites(data):
        if spr not in need:
            bg_only.add(spr)
        need.setdefault(spr, set()).add(0)          # the background is unrolled from these
    banks = [bytearray() for _ in BANKS]
    stored = {}     # sprite data already stored (identical images share it)
    streams = []    # (entry, the shifts it's for, its 5-pixel values), coded once they're all known
    def store(entry, rows, shifts):
        # (two streams of 5-pixel codes: A for shifts 0 and 1, B for 2 and 3; all in bank 4,
        # where the code tables are)
        w = len(rows[0])
        for first, pair in ((-1, (0, 1)), (-3, (2, 3))):
            used = [sh for sh in pair if sh in shifts]
            if used:
                streams.append((entry, used, window_columns(rows, first, max((sh + w + 3) // 4 for sh in used))))
    directory = []  # per image: dict
    frames_of = {}
    for spr in sorted(need):
        info = data.sprites[spr]
        frames = frames_of[spr] = sprite_pixels(data, spr)
        for f, rows in enumerate(frames):
            entry = {'name': spr, 'frame': f, 'frames': len(frames), 'w': info['w'], 'h': info['h'],
                     'xo': info['xo'], 'yo': info['yo'], 'shift': {},
                     'spans': None if spr in bg_only or spr in BADGES else row_spans(rows), 'parts': None}
            if spr not in TROGG_SPLIT:
                store(entry, rows, sorted(need[spr]))
            directory.append(entry)
    # Trogg standing and walking: these frames are only collision outlines. They are drawn as a
    # body (the top TROGG_BODY rows, the same in all of them) and legs (one of four sets)
    for side in 'rl':
        walk, stand = 'sTrogg_w%s_Beeb' % side, 'sTrogg_s%s_Beeb' % side
        w, info = frames_of[walk], data.sprites[walk]
        assert frames_of[stand][0] == w[0] and data.sprites[stand]['xo'] == info['xo'] and \
            data.sprites[stand]['yo'] == info['yo'], 'Trogg standing should be walking frame 0'
        assert all(f[:TROGG_BODY] == w[0][:TROGG_BODY] for f in w), 'Trogg walking: the body should not change'
        body = {'name': 'sTroggBody_%s_Beeb' % side, 'frame': 0, 'frames': 1, 'w': info['w'], 'h': TROGG_BODY,
                'xo': info['xo'], 'yo': info['yo'], 'shift': {}, 'spans': None, 'parts': None}
        store(body, w[0][:TROGG_BODY], range(4))
        body_id = len(directory)
        directory.append(body)
        for f in range(len(w)):
            leg = {'name': 'sTroggLegs_%s_Beeb' % side, 'frame': f, 'frames': len(w), 'w': info['w'],
                   'h': info['h'] - TROGG_BODY, 'xo': info['xo'], 'yo': info['yo'] - TROGG_BODY, 'shift': {},
                   'spans': None, 'parts': None}
            store(leg, w[f][TROGG_BODY:], range(4))
            directory.append(leg)
        for e in directory:
            if e['name'] == walk:
                e['parts'] = (body_id, body_id + 1 + e['frame'])
            elif e['name'] == stand:
                e['parts'] = (body_id, body_id + 1)
    number_windows([v for _, _, wins in streams for v in wins])
    for entry, used, wins in streams:
        blob = bytes(WINDOWS[v] for v in wins)
        if blob not in stored:
            if len(banks[0]) + len(blob) > CODE_TABLES - 0x8000:
                raise SystemExit('Out of room for sprites in bank %d' % BANKS[0])
            stored[blob] = (BANKS[0] | CODED, 0x8000 + len(banks[0]))
            banks[0] += blob
        for sh in used:
            entry['shift'][sh] = stored[blob]
    # The timer shown while playing: 4 characters (m:ss), drawn by the game into hud_image
    directory.append({'name': 'sHud_Beeb', 'frame': 0, 'frames': 1, 'w': 32, 'h': 8, 'xo': 0, 'yo': 0,
                      'shift': {0: (6, 'hud_image')}, 'spans': None, 'parts': None})
    if len(directory) > 255:
        raise SystemExit('Too many images: %d' % len(directory))
    sprite_bytes = len(banks[0])
    banks[0] += bytes(CODE_TABLES - 0x8000 - len(banks[0])) + code_tables()
    for b, blob in zip(BANKS, banks):
        open(os.path.join(build, 'GFX%d' % b), 'wb').write(bytes(blob))
    # Collision spans (assembled at the start of bank 6): 2 bytes (left, right) per row of each
    # image that can be collided with
    spans_blob = bytearray()
    for e in directory:
        e['span_addr'] = 0x8000 + len(spans_blob)
        for l, r in (e['spans'] or []):
            spans_blob += bytes((l, r))
    open(os.path.join(build, 'SPANS'), 'wb').write(bytes(spans_blob))
    image_id = {(e['name'], e['frame']): i for i, e in enumerate(directory)}

    out = ['\\ Image directory - GENERATED by tools/convert.py, do not edit', '']
    out.append('NUM_IMAGES = %d' % len(directory))
    for i, e in enumerate(directory):
        suffix = '' if e['frames'] == 1 else '_%d' % e['frame']
        out.append('IMG_%s%s = %d' % (asm_ident(e['name'][1:].replace('_Beeb', '')), suffix, i))
    out.append('')
    for field in ('w', 'h', 'xo', 'yo'):
        out.append(asm_bytes('img_' + field, [e[field] for e in directory]))
    open(os.path.join(gen, 'sprites.asm'), 'w').write('\n'.join(out) + '\n')
    # where each image's data is, for each shift: shifts 0-2 in bank 7 (with the background's
    # code), shift 3 just below the save area in the emptier sprite bank (see IMGDIR_ORG)
    for name, shifts in (('imgdir.asm', range(3)), ('imgdir3.asm', [3])):
        out = ['\\ Image addresses - GENERATED by tools/convert.py, do not edit', '']
        for shift in shifts:
            out.append(asm_bytes('img_bank%d' % shift, [e['shift'].get(shift, (0, 0))[0] for e in directory]))
            addr = [e['shift'].get(shift, (0, 0))[1] for e in directory]
            out.append(asm_bytes('img_lo%d' % shift, ['LO(%s)' % a if isinstance(a, str) else a & 0xFF for a in addr]))
            out.append(asm_bytes('img_hi%d' % shift, ['HI(%s)' % a if isinstance(a, str) else a >> 8 for a in addr]))
        open(os.path.join(gen, name), 'w').write('\n'.join(out) + '\n')
    imgdir_org = 0xC000 - SLOWSAVE1_SIZE - 3 * len(directory)
    # Tight bounding box of the solid pixels, the collision spans and save sizes (bank 6)
    out = ['\\ Collision tables (in bank 6) - GENERATED by tools/convert.py, do not edit', '']
    def bbox(e):
        rows = [i for i, (l, r) in enumerate(e['spans'] or []) if l != 255]
        if not rows:
            return (255, 0, 255, 0)
        return (min(e['spans'][i][0] for i in rows), max(e['spans'][i][1] for i in rows), rows[0], rows[-1])
    boxes = [bbox(e) for e in directory]
    for i, field in enumerate(('bx0', 'bx1', 'by0', 'by1')):
        out.append(asm_bytes('img_' + field, [b[i] for b in boxes]))
    # Largest background save needed for each image (any shift)
    # (a 6-byte header, then for each byte column a 2-byte screen address and the bytes)
    sv = [6 + ((e['w'] + 6) // 4) * (e['h'] + 2) for e in directory]
    out.append(asm_bytes('img_svl', [v & 0xFF for v in sv]))
    out.append(asm_bytes('img_svh', [v >> 8 for v in sv]))
    out.append(asm_bytes('img_span_lo', [e['span_addr'] & 0xFF for e in directory]))
    out.append(asm_bytes('img_span_hi', [e['span_addr'] >> 8 for e in directory]))
    # What each image is, when it's a collectable or static object (KIND_*)
    kinds = {}
    for name in LEVELS:
        for inst in data.rooms[name]['inst']:
            k = data.kind(inst[0])
            spr = data.sprite_of(inst[0])
            if spr is None or k in (None, 'oPlatform', 'oLadder'):
                continue
            kv = {'oKey': 1, 'oGem': 2, 'oBulb': 4}.get(inst[0], 3 if k == 'oMeanie' else 0)
            for f in range(data.sprites[spr]['n']):
                if (spr, f) in image_id:
                    kinds[image_id[(spr, f)]] = kv
    out.append(asm_bytes('img_kind', [kinds.get(i, 0) for i in range(len(directory))]))
    # How each image is drawn: as image A, then image B unless that's 255 (Trogg's standing and
    # walking frames are a body and legs)
    out.append(asm_bytes('img_part_a', [e['parts'][0] if e['parts'] else i for i, e in enumerate(directory)]))
    out.append(asm_bytes('img_part_b', [e['parts'][1] if e['parts'] else 255 for e in directory]))
    open(os.path.join(gen, 'collide.asm'), 'w').write('\n'.join(out) + '\n')

    # ---- tables
    out = ['\\ Lookup tables - GENERATED by tools/convert.py, do not edit', '']
    out.append('')
    out.append('ALIGN &100')
    out.append(asm_bytes('masktab', mask_table()))
    out.append('ALIGN &100')
    out.append(asm_bytes('identity', list(range(256))))
    open(os.path.join(gen, 'tables.asm'), 'w').write('\n'.join(out) + '\n')

    # ---- levels: all of them, packed, for HAZEL and ANDY
    params, packed, expect, maxima = [], [], {}, {}
    for name in LEVELS:
        lev = build_level(data, name)
        for (_, _, spr, x, _, _) in lev['draw']:
            if spr in bg_only:
                continue
            shift = (x - data.sprites[spr]['xo']) % 4
            if shift not in directory[image_id[(spr, 0)]]['shift']:
                raise SystemExit('%s: %s at x=%d needs shift %d, which was not generated' % (name, spr, x, shift))
        blob, simple = pack_level(data, lev, image_id, params)
        packed.append(blob)
        t = level_tables(data, lev, image_id, simple)
        (tables, cells, bgdata, start), _ = render_background(data, lev, lambda spr: sprite_pixels(data, spr))
        t['bg_tables'], t['bg_cells'], t['bg_data'], t['bg_start'] = tables.hex(), b''.join(cells).hex(), bgdata.hex(), start
        maxima['bg_cells'] = max(maxima.get('bg_cells', 0), len(cells))
        # (how high any Hooter jumps, from its base: for working out which meanies can reach Trogg)
        for v in lev['slow']:
            if v['kind'] == SL_HOOTER:
                info = data.sprites[v['spr']]
                maxima['hooter_peak'] = max(maxima.get('hooter_peak', 0), v['y'] - info['yo'] - slow_swept(data, v)[1])
        maxima['bg_end'] = max(maxima.get('bg_end', 0), start + len(bgdata))
        expect[name] = t
        for k, n in (('plats', len(lev['plats'])), ('ladders', len(lev['ladders'])), ('slow', len(lev['slow'])),
                     ('draw', len(t['draw_img'])), ('bg', len(lev['plats']) + len(lev['ladders']) + sum(lev['plat_bouncy']))):
            maxima[k] = max(maxima.get(k, 0), n)
    # (each level goes where it fits best, biggest first)
    segs = [bytearray() for _ in PACK_SEGMENTS]
    where = [None] * len(packed)
    for i in sorted(range(len(packed)), key=lambda i: -len(packed[i])):
        room = [(PACK_SEGMENTS[k][1] - len(segs[k]) - len(packed[i]), k) for k in range(len(segs))]
        fits = [r for r in room if r[0] >= 0]
        if not fits:
            raise SystemExit('Levels too big for HAZEL and ANDY (at %s)' % LEVELS[i])
        k = min(fits)[1]
        where[i] = PACK_SEGMENTS[k][0] + len(segs[k])
        segs[k] += packed[i]
    # The PACK file is loaded at &3000 and copied by copy_pack: 8KB to HAZEL, then 4KB to ANDY
    pack = bytearray()
    for (addr, size), blob in zip(PACK_SEGMENTS, segs):
        base = 0 if addr == 0xC000 else 0x2000 + addr - 0x8000
        pack += bytes(base - len(pack)) + blob
    pack_used = sum(len(b) for b in segs)
    open(os.path.join(build, 'PACK'), 'wb').write(bytes(pack))
    json.dump(expect, open(os.path.join(build, 'levels.json'), 'w'))
    out = ['\\ Levels - GENERATED by tools/convert.py, do not edit', '']
    out.append(asm_bytes('level_addr_lo', [a & 0xFF for a in where]))
    out.append(asm_bytes('level_addr_hi', [a >> 8 for a in where]))
    # Settings shared by the moving meanies: kind, speed (8.8), sleep ticks, flags (bit 0 =
    # follows its platform up and down, bit 1 = Poglet range set by yoff), yoff min, yoff max
    while len(params) < 1:
        params.append((0, 0, 0, 0, 0, 0))
    out.append(asm_bytes('slp_kind', [v[0] for v in params]))
    out.append(asm_bytes('slp_vf', [v[1] & 0xFF for v in params]))
    out.append(asm_bytes('slp_vi', [(v[1] >> 8) & 0xFF for v in params]))
    out.append(asm_bytes('slp_wait', [v[2] for v in params]))
    out.append(asm_bytes('slp_flags', [v[3] for v in params]))
    out.append(asm_bytes('slp_ymin', [v[4] & 0xFF for v in params]))
    out.append(asm_bytes('slp_ymax', [v[5] & 0xFF for v in params]))
    open(os.path.join(gen, 'levels.asm'), 'w').write('\n'.join(out) + '\n')

    # (the first save area for meanies flying off is the top 1KB of the emptier sprite bank)
    spare = min(range(len(banks)), key=lambda i: len(banks[i]))
    # Level names, from the Steam version's level table (js/render.js), 10 bytes each
    src = open(os.path.join(web, 'js/render.js')).read()
    names = dict(re.findall(r"\['(room_\w+)', '([^']*)'", src))
    good = {r: eval(t) for r, t in re.findall(r"\['(room_\w+)', '[^']*', ([0-9 *+]+)\]", src)}
    out = ['\\ Level names - GENERATED by tools/convert.py, do not edit', '.level_names']
    for name in LEVELS:
        n = names[name][:9]
        out.append('    EQUS "%s" : EQUB %s' % (n.replace('"', ''), ', '.join(['0'] * (10 - len(n)))))
    # the menus' icons: each is (width in bytes, height), then its bytes, a column at a time
    for spr in ICONS:
        rows = sprite_pixels(data, spr)[0]
        blob = shifted_columns(rows, 0)
        out.append(asm_bytes('icon_' + asm_ident(spr[1:].replace('_Beeb', '')),
                             [(len(rows[0]) + 3) // 4, len(rows)] + list(blob)))
    # each level's "good" time (for the stopwatch medal), in game ticks (50 a second)
    out.append(asm_bytes('level_good_lo', [good[n] * 50 & 0xFF for n in LEVELS]))
    out.append(asm_bytes('level_good_hi', [good[n] * 50 >> 8 for n in LEVELS]))
    open(os.path.join(gen, 'names.asm'), 'w').write('\n'.join(out) + '\n')
    consts = ['\\ Constants - GENERATED by tools/convert.py, do not edit',
              'NUM_LEVELS = %d' % len(LEVELS),
              'START_LEVEL = %d' % LEVELS.index(start_room),
              'MAX_PLATS = %d' % maxima['plats'], 'MAX_LADDERS = %d' % maxima['ladders'],
              'MAX_SLOW = %d' % maxima['slow'], 'HOOTER_PEAK = %d' % maxima.get('hooter_peak', 0), 'MAX_DRAW = %d' % maxima['draw'], 'MAX_BG = %d' % maxima['bg'],
              'MAX_PAL = %d' % MAX_PAL,
              'SL_SCRUBBLY = %d' % SL_SCRUBBLY, 'SL_POGLET = %d' % SL_POGLET,
              'SL_HOOTER = %d' % SL_HOOTER, 'SL_PLATFORM = %d' % SL_PLATFORM,
              'KIND_KEY = 1', 'KIND_GEM = 2', 'KIND_MEANIE = 3', 'KIND_BULB = 4',
              'LADDER_EXTRA_LENGTH = %d' % LADDER_EXTRA_LENGTH,
              'CACHE_BANK = %d' % CACHE_BANK,
              'BG_DICT = &%04X' % BG_DICT, 'BG_TOP = &%04X' % BG_TOP,
              'OVERLAY_RUN = &6000',
              'SLOWSAVE0_BANK = %d' % BANKS[spare], 'SLOWSAVE0_START = &%04X' % (0xC000 - SLOWSAVE1_SIZE),
              'FRONT_BANK = %d' % BANKS[spare], 'SPRITES_END = &%04X' % (0x8000 + len(banks[spare])),
              'DIR_BANK = %d' % BANKS[spare], 'IMGDIR_ORG = &%04X' % imgdir_org,
              'SLOWSAVE1_SIZE = &%04X' % SLOWSAVE1_SIZE,
              'SPANS_SIZE = %d' % len(spans_blob),
              'CODE_LPIX = &%04X' % CODE_TABLES, 'CODE_LMASK = &%04X' % (CODE_TABLES + 0x100),
              'CODE_RPIX = &%04X' % (CODE_TABLES + 0x200), 'CODE_RMASK = &%04X' % (CODE_TABLES + 0x300),
              'CODED = &%02X' % CODED]
    open(os.path.join(gen, 'consts.asm'), 'w').write('\n'.join(consts) + '\n')

    # Disc contents and !BOOT
    boot = ['*SRLOAD GFX%d 8000 %d Q' % (b, b) for b, blob in zip(BANKS, banks) if blob]
    boot += ['*SRLOAD BANK6 8000 6 Q', '*SRLOAD BANK7 %X 7 Q' % BG_TOP, '*SRLOAD LOADERZ OVERLAYZ_ORG 7 Q',
             '*SRLOAD IMGDIR %X %d Q' % (imgdir_org, BANKS[spare]),
             '*SRLOAD MUSIC %X %d Q' % (0x8000 + len(banks[spare]), BANKS[spare]),
             '*SRLOAD FRONTZ %s %d Q' % ('FRONTZ_ORG', BANKS[spare]),   # (tools/pack.py fills in the address)
             '*LOAD PACK 3000', '*RUN FRAK']
    open(os.path.join(gen, 'boot.txt'), 'w').write('\n'.join(boot) + '\n')
    disc = ['\\ Disc contents - GENERATED by tools/convert.py, do not edit',
            'PUTTEXT "src/gen/boot.txt", "!BOOT", 0']
    disc += ['PUTFILE "build/GFX%d", "GFX%d", &8000' % (b, b) for b, blob in zip(BANKS, banks) if blob]
    disc += ['PUTFILE "build/PACK", "PACK", &3000']
    open(os.path.join(gen, 'disc.asm'), 'w').write('\n'.join(disc) + '\n')

    print('%d images, %d bytes of sprites in bank %d (%d free), %d different 5-pixel values, spans %d bytes, '
          '%d levels packed in %d bytes (of %d), %d meanie settings' % (len(directory), sprite_bytes, BANKS[0],
                                           CODE_TABLES - 0x8000 - sprite_bytes, len(WINDOWS), len(spans_blob),
                                           len(LEVELS), pack_used, sum(v for _, v in PACK_SEGMENTS), len(params)))
    print('largest level: %s' % ', '.join('%s %d' % kv for kv in maxima.items()))


if __name__ == '__main__':
    main()
