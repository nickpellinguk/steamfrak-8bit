#!/usr/bin/env python3
"""
Build BBC Master data for Frak! from the web version's data files.

Usage:
    python3 tools/convert.py ../steamfrak [starting room, default room_A_1]

Reads (from the steamfrak repository):
    js/data/rooms.js, js/data/objects.js, js/data/sprites.js, assets/sprites/*.png

Writes:
    build/GFX4, GFX5            pre-shifted MODE 1 sprite data for sideways RAM banks 4 and 5
    build/SPANS                 collision spans: solid pixels per row of each image (bank 6)
    build/PACK                  every level, packed (copied into HAZEL and ANDY at boot)
    build/levels.json           what the level loader should build for each level (for tests)
    src/gen/sprites.asm         image directory (bank, address, size, origin per shift)
    src/gen/collide.asm         collision boxes and spans, save sizes, what each image is
    src/gen/levels.asm          where each level is, and the moving meanies' settings
    src/gen/consts.asm          constants: table sizes, start level, save areas
    src/gen/tables.asm, fall.asm  mask table and the jump/fall table
    src/gen/disc.asm, boot.txt  the disc's file list and !BOOT

Sprites are MODE 1 (2 bits per pixel, 4 pixels per byte). Logical colour 0 is the level
background and is always transparent, so masks are derived at run time from a 256-byte table.
Each image is stored once per needed horizontal pixel shift (0-3), column by column (each byte
column is "height" bytes, top to bottom), which is the order the plotter walks the screen.
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

# MODE 1 logical colours (palette set per level): 0 = background, 1 = black, 2 = magenta, 3 = yellow
COLOURS = {(0, 0, 0): 1, (255, 0, 255): 2, (255, 255, 0): 3}
# Level background colours -> BBC physical colours
BG_PHYSICAL = {'#00f0f0': 6, '#00f000': 2, '#00e000': 2, '#be1f13': 1}

TROGG_FRAMES = ['sTrogg_%s_Beeb' % k for k in 'sr sl wr wl yr yl cn cu cd'.split()]
# Sprites drawn at any x position, so they need all four pre-shifted copies
MOVING_SPRITES = TROGG_FRAMES + ['sBalloon_Beeb', 'sDaggerLR_Beeb', 'sDaggerUD_Beeb', 'sYoyo_Beeb',
                                 'sFrak_Beeb', 'sScrubbly_Beeb', 'sPoglet_Beeb', 'sHooter_Beeb',
                                 'sSpring_Beeb']
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
    draw.sort(key=lambda d: (-d[0], d[1]))
    plat_moving = [1 if o in moving_orders else 0 for o in plat_order]
    return {
        'w': room['w'], 'h': room['h'], 'bg': BG_PHYSICAL.get(room['bg'], 6),
        'trogg': trogg, 'plats': plats, 'plat_moving': plat_moving, 'ladders': ladders,
        'plat_spr': plat_spr, 'ladder_spr': ladder_spr,
        'draw': draw, 'slow': slow, 'moving_enabled': moving_enabled,
    }


# --- Pre-rendered background ---------------------------------------------------------------------

CACHE_BANK = 7
SPANS_BANK = 6                  # collision data
CACHE_BG_DEPTHS = (DEPTH['oPlatform'], DEPTH['oLadder'])     # things that never change


def render_background(data, lev, frames_cache):
    """
    Composite the platforms and ladders into a level-sized image of logical colours, then pack
    it into bank 7 the way unroll_bg does (this is the reference the tests compare it with):
      &8000/&8100  the address of each byte column (low, high bytes; 0 past the level's end)
      &8200        the cell dictionary: each distinct non-empty character cell (8 bytes), numbered
                   in order of first use, column by column from the top; stored as 8 tables of
                   256 bytes, one per line of a cell (cells 256-511 from &8A00 likewise)
      &9200        the columns: a 4-byte mask of the non-empty cells (bit 7 of the first byte =
                   character row 0), a 4-byte mask of those whose number is 256 or more, then
                   each non-empty cell's number (low byte)
    Returns (column tables, the dictionary as a list of cells, the columns), and the image.
    """
    w, h = lev['w'], lev['h']
    cols = (w + 3) // 4
    img = [[0] * (cols * 4) for _ in range(h)]
    for depth, _, spr, x, y, _ in lev['draw']:
        if depth not in CACHE_BG_DEPTHS:
            continue
        info = data.sprites[spr]
        rows = frames_cache(spr)[0]
        left, top = x - info['xo'], y - info['yo']
        for sy, row in enumerate(rows):
            for sx, c in enumerate(row):
                px, py = left + sx, top + sy
                if c and 0 <= px < cols * 4 and 0 <= py < h:
                    img[py][px] = c
    blob = bytearray()
    offsets = []
    dictionary, number = [], {}
    for col in range(cols):
        offsets.append(BG_COLUMNS + len(blob))
        cells = (h + 7) // 8
        mask = high = 0
        nums = bytearray()
        for cell in range(cells):
            data_bytes = bytearray()
            for line in range(8):
                y = cell * 8 + line
                px = [img[y][col * 4 + p] if y < h else 0 for p in range(4)]
                data_bytes.append(mode1_byte(px))
            if any(data_bytes):
                key = bytes(data_bytes)
                if key not in number:
                    number[key] = len(dictionary)
                    dictionary.append(key)
                n = number[key]
                mask |= 1 << (31 - cell)
                if n >= 256:
                    high |= 1 << (31 - cell)
                nums.append(n & 0xFF)
        blob += mask.to_bytes(4, 'big') + high.to_bytes(4, 'big') + nums
    if cols > 256 or len(dictionary) > 512 or BG_COLUMNS + len(blob) > BG_TOP:
        raise SystemExit('Background too big: %d columns, %d distinct cells, %d bytes of columns'
                         % (cols, len(dictionary), len(blob)))
    tables = bytearray(0x200)
    for col, off in enumerate(offsets):
        tables[col] = off & 0xFF
        tables[0x100 + col] = off >> 8
    return (bytes(tables), dictionary, bytes(blob)), img


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
        ok = ok and not any(overlap(r, rects[j]) for j in range(len(sl)) if j != i)
        ok = ok and not any(overlap(r, it) for it in items)
        flags.append(1 if ok else 0)
    return flags


# --- Jump / fall table ---------------------------------------------------------------------------

def fall_table():
    """
    Simulate the Steam version's Trogg falling (gravity 0.05/tick, terminal velocity -4, y rounded
    to multiples of 0.05) and reduce it to whole-pixel steps.

    Index t is the state at the start of a tick, with upward velocity 1.25 - 0.05 * t:
    t = 0 is the start of a jump, t = 25 is stepping off a ledge, t = 45 is dropping off the
    bottom of a ladder. For each t we store the whole-pixel y change (positive = down), whether
    Trogg may still grab a ladder, and whether landing would kill him.
    """
    # Work in exact units of 1/20 pixel: gravity is 1 unit/tick, jump speed 25, terminal -80
    yvel = 25
    pos = 0             # 1/20ths of a pixel, positive = down
    ipos = 0
    dys, flags = [], []
    t = 0
    while True:
        if yvel > -80:
            yvel -= 1
        ladder_ok = yvel * 2 >= -51         # yvel >= -1.275 pixels/tick
        deadly = yvel <= -32                # yvel <= -1.60 pixels/tick
        pos -= yvel
        dy = (pos + 10) // 20 - ipos        # round to the nearest whole pixel
        ipos += dy
        dys.append(dy)
        flags.append((1 if ladder_ok else 0) | (2 if deadly else 0))
        t += 1
        if yvel <= -80 and t > 110:
            break
    return dys, flags


# --- Output --------------------------------------------------------------------------------------

def asm_bytes(label, values, per_line=16):
    lines = ['.%s' % label] if label else []
    for i in range(0, len(values), per_line):
        lines.append('    EQUB ' + ', '.join('&%02X' % (v & 0xFF) for v in values[i:i + per_line]))
    return '\n'.join(lines) + '\n'


def asm_ident(name):
    return ''.join(c if c.isalnum() else '_' for c in name)


LEVELS = ['room_0'] + ['room_%s_%d' % (c, n) for c in 'ABCDEF' for n in range(1, 10)]
# Where the level pack goes: HAZEL (&C000-&DFFF) and ANDY (&8000-&8FFF), except &8800-&88FF of
# ANDY, which the MOS uses. No level straddles two of these.
PACK_SEGMENTS = [(0xC000, 0x2000), (0x8000, 0x800), (0x8900, 0x700)]
SLOWSAVE1 = (7, 0xBA00)         # bank 7, above the background and the code kept there
BG_COLUMNS = 0x9200             # the unrolled background's columns, in bank 7 (see render_background)
BG_TOP = 0xA000                 # ... which must end here
MAX_PAL = 16


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
         'plat_moving': lev['plat_moving'],
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
      palette: the image of each sprite the level uses
      platforms, ladders, objects (in drawing order) and moving meanies: 3 bytes each,
              x low, y low, then x high (bits 0-1), y high (bits 2-3), palette entry (bits 4-7)
      moving meanies: a byte each, settings (index into sl_params) + 128 if drawn the simple way
      moving platforms: 2 bytes each, platform number, then scan and direction flags
              (bits 0-5: scan left, right, up, down, start right, start up; bit 7 = simple)
    """
    d = [item for item in lev['draw'] if item[0] not in CACHE_BG_DEPTHS]
    meanies = [v for v in lev['slow'] if v['kind'] != SL_PLATFORM]
    mplats = [v for v in lev['slow'] if v['kind'] == SL_PLATFORM]
    simple = slow_simple_flags(data, lev, d)
    pal = []
    def pe(spr):
        img = image_id[(spr, 0)]
        if img not in pal:
            pal.append(img)
        return pal.index(img)
    def rec(x, y, spr):
        assert 0 <= x < 1024 and 0 <= y < 1024, (x, y)
        return bytes((x & 0xFF, y & 0xFF, (x >> 8) | ((y >> 8) << 2) | (pe(spr) << 4)))
    body = bytearray()
    for (x, y, w, h), spr in zip(lev['plats'], lev['plat_spr']):
        body += rec(x, y, spr)
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
    directory = []  # per image: dict
    for spr in sorted(need):
        info = data.sprites[spr]
        frames = sprite_pixels(data, spr)
        for f, rows in enumerate(frames):
            entry = {'name': spr, 'frame': f, 'w': info['w'], 'h': info['h'], 'xo': info['xo'],
                     'yo': info['yo'], 'shift': {}, 'spans': None if spr in bg_only else row_spans(rows)}
            for shift in range(4):
                if shift not in need[spr]:
                    continue
                blob = shifted_columns(rows, shift)
                for bank_i in range(len(BANKS)):
                    if len(banks[bank_i]) + len(blob) <= BANK_SIZE:
                        break
                else:
                    raise SystemExit('Out of sideways RAM for sprites')
                entry['shift'][shift] = (BANKS[bank_i], 0x8000 + len(banks[bank_i]))
                banks[bank_i] += blob
            directory.append(entry)
    if len(directory) > 255:
        raise SystemExit('Too many images: %d' % len(directory))
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
        suffix = '' if data.sprites[e['name']]['n'] == 1 else '_%d' % e['frame']
        out.append('IMG_%s%s = %d' % (asm_ident(e['name'][1:].replace('_Beeb', '')), suffix, i))
    out.append('')
    for field in ('w', 'h', 'xo', 'yo'):
        out.append(asm_bytes('img_' + field, [e[field] for e in directory]))
    for shift in range(4):
        out.append(asm_bytes('img_bank%d' % shift, [e['shift'].get(shift, (0, 0))[0] for e in directory]))
        out.append(asm_bytes('img_lo%d' % shift, [e['shift'].get(shift, (0, 0))[1] & 0xFF for e in directory]))
        out.append(asm_bytes('img_hi%d' % shift, [e['shift'].get(shift, (0, 0))[1] >> 8 for e in directory]))
    open(os.path.join(gen, 'sprites.asm'), 'w').write('\n'.join(out) + '\n')
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
    open(os.path.join(gen, 'collide.asm'), 'w').write('\n'.join(out) + '\n')

    # ---- tables
    dys, flags = fall_table()
    out = ['\\ Lookup tables - GENERATED by tools/convert.py, do not edit', '']
    out.append('FALL_LEN = %d' % len(dys))
    out.append('FALL_JUMP = 0          \\ start of a jump (upward speed 1.25)')
    out.append('FALL_STEP_OFF = 25     \\ walking off a ledge (speed 0)')
    out.append('FALL_LADDER_DROP = 45  \\ dropping off the bottom of a ladder (speed -1)')
    out.append('')
    out.append('ALIGN &100')
    out.append(asm_bytes('masktab', mask_table()))
    out.append('ALIGN &100')
    out.append(asm_bytes('identity', list(range(256))))
    open(os.path.join(gen, 'tables.asm'), 'w').write('\n'.join(out) + '\n')
    fall = ['\\ Jump/fall table (in bank 6) - GENERATED by tools/convert.py, do not edit', '']
    fall.append('\\ y change per tick (positive = down)')
    fall.append(asm_bytes('fall_dy', dys))
    fall.append('\\ bit 0 = may grab a ladder, bit 1 = landing kills Trogg')
    fall.append(asm_bytes('fall_flags', flags))
    open(os.path.join(gen, 'fall.asm'), 'w').write('\n'.join(fall) + '\n')

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
        if lev['h'] == 256:
            (tables, cells, cols), _ = render_background(data, lev, lambda spr: sprite_pixels(data, spr))
            t['bg_tables'], t['bg_cells'], t['bg_cols'] = tables.hex(), b''.join(cells).hex(), cols.hex()
            maxima['bg_cells'] = max(maxima.get('bg_cells', 0), len(cells))
            maxima['bg_bytes'] = max(maxima.get('bg_bytes', 0), len(cols))
        expect[name] = t
        for k, n in (('plats', len(lev['plats'])), ('ladders', len(lev['ladders'])), ('slow', len(lev['slow'])),
                     ('draw', len(t['draw_img'])), ('bg', len(lev['plats']) + len(lev['ladders']))):
            maxima[k] = max(maxima.get(k, 0), n)
    segs = [bytearray() for _ in PACK_SEGMENTS]
    where = []
    seg = 0
    for name, blob in zip(LEVELS, packed):
        while seg < len(segs) and len(segs[seg]) + len(blob) > PACK_SEGMENTS[seg][1]:
            seg += 1
        if seg == len(segs):
            raise SystemExit('Levels too big for HAZEL and ANDY (at %s)' % name)
        where.append(PACK_SEGMENTS[seg][0] + len(segs[seg]))
        segs[seg] += blob
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

    spare = min(range(len(banks)), key=lambda i: len(banks[i]))
    consts = ['\\ Constants - GENERATED by tools/convert.py, do not edit',
              'NUM_LEVELS = %d' % len(LEVELS),
              'START_LEVEL = %d' % LEVELS.index(start_room),
              'MAX_PLATS = %d' % maxima['plats'], 'MAX_LADDERS = %d' % maxima['ladders'],
              'MAX_SLOW = %d' % maxima['slow'], 'MAX_DRAW = %d' % maxima['draw'], 'MAX_BG = %d' % maxima['bg'],
              'MAX_PAL = %d' % MAX_PAL,
              'SL_SCRUBBLY = %d' % SL_SCRUBBLY, 'SL_POGLET = %d' % SL_POGLET,
              'SL_HOOTER = %d' % SL_HOOTER, 'SL_PLATFORM = %d' % SL_PLATFORM,
              'KIND_KEY = 1', 'KIND_GEM = 2', 'KIND_MEANIE = 3', 'KIND_BULB = 4',
              'LADDER_EXTRA_LENGTH = %d' % LADDER_EXTRA_LENGTH,
              'CACHE_BANK = %d' % CACHE_BANK, 'CACHE_TOP = &%04X' % SLOWSAVE1[1],
              'BG_DICT = &8200', 'BG_COLUMNS = &%04X' % BG_COLUMNS, 'BG_TOP = &%04X' % BG_TOP,
              'SLOWSAVE0_BANK = %d' % BANKS[spare], 'SLOWSAVE0_START = &%04X' % (0x8000 + len(banks[spare])),
              'SLOWSAVE1_BANK = %d' % SLOWSAVE1[0], 'SLOWSAVE1_START = &%04X' % SLOWSAVE1[1],
              'SPANS_SIZE = %d' % len(spans_blob)]
    open(os.path.join(gen, 'consts.asm'), 'w').write('\n'.join(consts) + '\n')

    # Disc contents and !BOOT
    boot = ['*SRLOAD GFX%d 8000 %d Q' % (b, b) for b in BANKS]
    boot += ['*SRLOAD BANK6 8000 6 Q', '*SRLOAD BANK7 A000 7 Q', '*LOAD PACK 3000', '*RUN FRAK']
    open(os.path.join(gen, 'boot.txt'), 'w').write('\n'.join(boot) + '\n')
    disc = ['\\ Disc contents - GENERATED by tools/convert.py, do not edit',
            'PUTTEXT "src/gen/boot.txt", "!BOOT", 0']
    disc += ['PUTFILE "build/GFX%d", "GFX%d", &8000' % (b, b) for b in BANKS]
    disc += ['PUTFILE "build/PACK", "PACK", &3000']
    open(os.path.join(gen, 'disc.asm'), 'w').write('\n'.join(disc) + '\n')

    print('%d images, sprite banks %s bytes (%d free), spans %d bytes, %d levels packed in %d bytes '
          '(of %d), %d meanie settings' % (len(directory), [len(b) for b in banks],
                                           2 * BANK_SIZE - sum(len(b) for b in banks), len(spans_blob),
                                           len(LEVELS), pack_used, sum(v for _, v in PACK_SEGMENTS), len(params)))
    print('largest level: %s' % ', '.join('%s %d' % kv for kv in maxima.items()))


if __name__ == '__main__':
    main()
