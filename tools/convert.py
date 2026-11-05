#!/usr/bin/env python3
"""
Build BBC Master data for Frak! from the web version's data files.

Usage:
    python3 tools/convert.py ../steamfrak [room_name]

Reads (from the steamfrak repository):
    js/data/rooms.js, js/data/objects.js, js/data/sprites.js, assets/sprites/*.png

Writes:
    build/GFX4 ..               pre-shifted MODE 1 sprite data, one file per sideways RAM bank used
    build/SPANS                 collision spans: solid pixels per row of each image (bank 6)
    build/CACHE                 the level's platforms and ladders pre-rendered (sideways RAM bank 7)
    src/gen/sprites.asm         image directory (bank, address, size, origin per shift)
    src/gen/tables.asm          mask table and the jump/fall table
    src/gen/level.asm           the level: platforms, ladders and the draw list
    src/gen/disc.asm, boot.txt  the disc's file list and !BOOT (which banks to load)

Sprites are MODE 1 (2 bits per pixel, 4 pixels per byte). Logical colour 0 is the level
background and is always transparent, so masks are derived at run time from a 256-byte table.
Each image is stored once per needed horizontal pixel shift (0-3), column by column (each byte
column is "height" bytes, top to bottom), which is the order the plotter walks the screen.
"""
import json
import math
import os
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


def build_level(data, room_name):
    room = data.rooms[room_name]
    plats, ladders, draw, trogg = [], [], [], None
    for order, inst in enumerate(room['inst']):
        obj, x, y = inst[0], int(inst[1]), int(inst[2])
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
        draw.append((DEPTH[kind], order, spr, x, y, obj))
    # Ladders reach up to the platform above them (LadderAdd)
    for order, inst in enumerate(room['inst']):
        obj, x, y = inst[0], int(inst[1]), int(inst[2])
        if data.kind(obj) != 'oLadder':
            continue
        info = data.sprites[data.sprite_of(obj)]
        h = info['h'] + LADDER_EXTRA_LENGTH
        found = platform_find(plats, x, y - LADDER_EXTRA_LENGTH, y - 1)
        extra = 0 if found is None else y - found - 1
        ladders.append((x, y - extra, h + extra, extra))
    draw.sort(key=lambda d: (-d[0], d[1]))
    return {
        'w': room['w'], 'h': room['h'], 'bg': BG_PHYSICAL.get(room['bg'], 6),
        'trogg': trogg, 'plats': plats, 'ladders': ladders, 'draw': draw,
    }


# --- Pre-rendered background ---------------------------------------------------------------------

CACHE_BANK = 7
SPANS_BANK = 6                  # collision data
CACHE_BG_DEPTHS = (DEPTH['oPlatform'], DEPTH['oLadder'])     # things that never change


def render_background(data, lev, frames_cache):
    """
    Composite the platforms and ladders into a level-sized image of logical colours, then pack
    it for fast column repainting: for each byte column, a 4-byte mask (bit 7 of the first byte
    = character row 0) of which character cells are non-empty, then 8 bytes per non-empty cell.
    Returns the bank image: column address tables at &8000 (low) / &8100 (high), data from &8200.
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
    for col in range(cols):
        offsets.append(0x8200 + len(blob))
        cells = (h + 7) // 8
        mask = 0
        body = bytearray()
        for cell in range(cells):
            data_bytes = bytearray()
            for line in range(8):
                y = cell * 8 + line
                px = [img[y][col * 4 + p] if y < h else 0 for p in range(4)]
                data_bytes.append(mode1_byte(px))
            if any(data_bytes):
                mask |= 1 << (31 - cell)
                body += data_bytes
        blob += mask.to_bytes(4, 'big') + body
    if cols > 256 or 0x200 + len(blob) > BANK_SIZE:
        raise SystemExit('Background cache too big: %d bytes' % len(blob))
    image = bytearray(0x200)
    for col, off in enumerate(offsets):
        image[col] = off & 0xFF
        image[0x100 + col] = off >> 8
    return bytes(image + blob)


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


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    web = sys.argv[1]
    room_name = sys.argv[2] if len(sys.argv) > 2 else 'room_A_1'
    data = Data(web)
    gen = os.path.join(ROOT, 'src', 'gen')
    build = os.path.join(ROOT, 'build')
    os.makedirs(gen, exist_ok=True)
    os.makedirs(build, exist_ok=True)

    # ---- graphics
    need = needed_shifts(data)
    images = []     # (sprite, frame) -> image id
    banks = [bytearray() for _ in BANKS]
    directory = []  # per image: dict
    bank_i = 0
    for spr in sorted(need):
        info = data.sprites[spr]
        frames = sprite_pixels(data, spr)
        for f, rows in enumerate(frames):
            entry = {'name': spr, 'frame': f, 'w': info['w'], 'h': info['h'],
                     'xo': info['xo'], 'yo': info['yo'], 'shift': {}, 'spans': row_spans(rows)}
            for shift in range(4):
                if shift not in need[spr]:
                    continue
                blob = shifted_columns(rows, shift)
                if len(banks[bank_i]) + len(blob) > BANK_SIZE:
                    bank_i += 1
                    if bank_i >= len(BANKS):
                        raise SystemExit('Out of sideways RAM for sprites')
                entry['shift'][shift] = (BANKS[bank_i], 0x8000 + len(banks[bank_i]))
                banks[bank_i] += blob
            images.append((spr, f))
            directory.append(entry)
    if len(directory) > 255:
        raise SystemExit('Too many images: %d' % len(directory))
    used_banks = [b for b, blob in zip(BANKS, banks) if blob]
    for b, blob in zip(BANKS, banks):
        if blob:
            open(os.path.join(build, 'GFX%d' % b), 'wb').write(bytes(blob))
    # Collision spans, in their own bank: 2 bytes (left, right) per row of each image
    spans_blob = bytearray()
    for e in directory:
        e['span_addr'] = 0x8000 + len(spans_blob)
        for l, r in e['spans']:
            spans_blob += bytes((l, r))
    if len(spans_blob) > 0x2000:       # the level data follows at &A000
        raise SystemExit('Collision spans too big')
    open(os.path.join(build, 'SPANS'), 'wb').write(bytes(spans_blob))

    # Disc contents and !BOOT
    boot = ['*SRLOAD GFX%d 8000 %d Q' % (b, b) for b in used_banks]
    boot += ['*SRLOAD SPANS 8000 %d Q' % SPANS_BANK, '*SRLOAD LEVEL A000 %d Q' % SPANS_BANK]
    boot += ['*SRLOAD CACHE 8000 %d Q' % CACHE_BANK, '*RUN FRAK']
    open(os.path.join(gen, 'boot.txt'), 'w').write('\n'.join(boot) + '\n')
    disc = ['\\ Disc contents - GENERATED by tools/convert.py, do not edit',
            'PUTTEXT "src/gen/boot.txt", "!BOOT", 0']
    disc += ['PUTFILE "build/GFX%d", "GFX%d", &8000' % (b, b) for b in used_banks]
    disc += ['PUTFILE "build/SPANS", "SPANS", &8000']
    disc += ['PUTFILE "build/CACHE", "CACHE", &8000']
    open(os.path.join(gen, 'disc.asm'), 'w').write('\n'.join(disc) + '\n')

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
    # Tight bounding box of the solid pixels, the collision spans and save sizes (level bank)
    out = ['\\ Collision tables (in the level bank) - GENERATED by tools/convert.py, do not edit', '']
    out.append('SPANS_BANK = %d' % SPANS_BANK)
    def bbox(e):
        rows = [i for i, (l, r) in enumerate(e['spans']) if l != 255]
        if not rows:
            return (255, 0, 255, 0)
        return (min(e['spans'][i][0] for i in rows), max(e['spans'][i][1] for i in rows), rows[0], rows[-1])
    boxes = [bbox(e) for e in directory]
    for i, field in enumerate(('bx0', 'bx1', 'by0', 'by1')):
        out.append(asm_bytes('img_' + field, [b[i] for b in boxes]))
    # Largest background save needed for each image (any shift)
    sv = [((e['w'] + 6) // 4) * e['h'] for e in directory]
    out.append(asm_bytes('img_svl', [v & 0xFF for v in sv]))
    out.append(asm_bytes('img_svh', [v >> 8 for v in sv]))
    out.append(asm_bytes('img_span_lo', [e['span_addr'] & 0xFF for e in directory]))
    out.append(asm_bytes('img_span_hi', [e['span_addr'] >> 8 for e in directory]))
    open(os.path.join(gen, 'collide.asm'), 'w').write('\n'.join(out) + '\n')
    image_id = {(e['name'], e['frame']): i for i, e in enumerate(directory)}

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
    fall = ['\\ Jump/fall table (in the level bank) - GENERATED by tools/convert.py, do not edit', '']
    fall.append('\\ y change per tick (positive = down)')
    fall.append(asm_bytes('fall_dy', dys))
    fall.append('\\ bit 0 = may grab a ladder, bit 1 = landing kills Trogg')
    fall.append(asm_bytes('fall_flags', flags))
    open(os.path.join(gen, 'fall.asm'), 'w').write('\n'.join(fall) + '\n')

    # ---- level
    lev = build_level(data, room_name)
    out = ['\\ Level %s - GENERATED by tools/convert.py, do not edit' % room_name, '']
    out.append('LEVEL_W = %d' % lev['w'])
    out.append('LEVEL_H = %d' % lev['h'])
    out.append('LEVEL_BG = %d' % lev['bg'])
    out.append('TROGG_START_X = %d' % lev['trogg'][0])
    out.append('TROGG_START_Y = %d' % lev['trogg'][1])
    out.append('NUM_PLATS = %d' % len(lev['plats']))
    out.append('NUM_LADDERS = %d' % len(lev['ladders']))
    out.append('')
    p = lev['plats']
    out.append(asm_bytes('plat_xl', [v[0] & 0xFF for v in p]))
    out.append(asm_bytes('plat_xh', [v[0] >> 8 for v in p]))
    out.append(asm_bytes('plat_yl', [v[1] & 0xFF for v in p]))
    out.append(asm_bytes('plat_yh', [v[1] >> 8 for v in p]))
    out.append(asm_bytes('plat_w', [v[2] for v in p]))
    lad = lev['ladders']
    out.append(asm_bytes('lad_xl', [v[0] & 0xFF for v in lad]))
    out.append(asm_bytes('lad_xh', [v[0] >> 8 for v in lad]))
    out.append(asm_bytes('lad_yl', [v[1] & 0xFF for v in lad]))
    out.append(asm_bytes('lad_yh', [(v[1] >> 8) & 0xFF for v in lad]))
    out.append(asm_bytes('lad_hl', [v[2] & 0xFF for v in lad]))
    out.append(asm_bytes('lad_hh', [v[2] >> 8 for v in lad]))
    out.append(asm_bytes('lad_ext', [v[3] for v in lad]))
    frames_cache = {}

    def frames_of(spr):
        if spr not in frames_cache:
            frames_cache[spr] = sprite_pixels(data, spr)
        return frames_cache[spr]

    cache = render_background(data, lev, frames_of)
    open(os.path.join(build, 'CACHE'), 'wb').write(cache)
    out.append('CACHE_BANK = %d' % CACHE_BANK)
    # Run-time draw list: only the things that aren't in the pre-rendered background
    d = [item for item in lev['draw'] if item[0] not in CACHE_BG_DEPTHS]
    out.append('NUM_DRAW = %d' % len(d))
    ids = [image_id[(spr, 0)] for (_, _, spr, _, _, _) in d]
    for (_, _, spr, x, _, _) in d:
        shift = (x - data.sprites[spr]['xo']) % 4
        if shift not in directory[image_id[(spr, 0)]]['shift']:
            raise SystemExit('%s at x=%d needs shift %d, which was not generated' % (spr, x, shift))
    out.append(asm_bytes('draw_img', ids))
    out.append(asm_bytes('draw_xl', [v[3] & 0xFF for v in d]))
    out.append(asm_bytes('draw_xh', [v[3] >> 8 for v in d]))
    out.append(asm_bytes('draw_yl', [v[4] & 0xFF for v in d]))
    out.append(asm_bytes('draw_yh', [v[4] >> 8 for v in d]))
    # byte columns each item covers, for redrawing one column after a scroll
    c0 = [(v[3] - data.sprites[v[2]]['xo']) >> 2 for v in d]
    c1 = [((v[3] - data.sprites[v[2]]['xo']) + data.sprites[v[2]]['w'] + 3) >> 2 for v in d]
    out.append(asm_bytes('draw_c0', [max(0, c) for c in c0]))
    out.append(asm_bytes('draw_c1', [min(255, c) for c in c1]))
    # What each object is, and its top-left corner (for collisions)
    kinds = {'oKey': 1, 'oGem': 2, 'oBulb': 4}
    kind = [kinds.get(v[5], 3 if data.kind(v[5]) == 'oMeanie' else 0) for v in d]
    out.append('KIND_KEY = 1')
    out.append('KIND_GEM = 2')
    out.append('KIND_MEANIE = 3')
    out.append('KIND_BULB = 4')
    out.append('NUM_KEYS = %d' % kind.count(1))
    out.append('NUM_GEMS = %d' % kind.count(2))
    out.append(asm_bytes('draw_kind', kind))
    lefts = [v[3] - data.sprites[v[2]]['xo'] for v in d]
    tops = [v[4] - data.sprites[v[2]]['yo'] for v in d]
    out.append(asm_bytes('draw_ll', [v & 0xFF for v in lefts]))
    out.append(asm_bytes('draw_lh', [(v >> 8) & 0xFF for v in lefts]))
    out.append(asm_bytes('draw_tl', [v & 0xFF for v in tops]))
    out.append(asm_bytes('draw_th', [(v >> 8) & 0xFF for v in tops]))
    open(os.path.join(gen, 'level.asm'), 'w').write('\n'.join(out) + '\n')

    used = [len(b) for b in banks if b]
    print('images: %d, sprite banks used: %s bytes, level %s: %d platforms, %d ladders, %d objects, '
          'background cache %d bytes' % (len(directory), used, room_name, len(p), len(lad), len(d), len(cache)))


if __name__ == '__main__':
    main()
