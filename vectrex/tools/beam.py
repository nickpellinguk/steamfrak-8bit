"""
A model of the Vectrex's beam, for pictures of what a frame would look like.

A line is (x0, y0, x1, y1, intensity, cycles), in vecx's beam units (the screen is 33000 wide and
41000 high, y down), with the intensity (0-127, the Z DAC) and how many cycles the beam took over
it. The energy the beam leaves on each bit of the line is intensity x time / length, i.e. it goes
as intensity / speed: a long line drawn in the same time as a short one is dimmer. A line with no
length is the beam standing still: a dot with all the energy in one place.

Where the beam stands still with the spot on (the bright dots at the ends of lines on a real
Vectrex), that's a line with no length. A capture from vecx (beamshot) has them already; for
shapes drawn here, polylines_to_lines adds them, as measured in vecx for the BIOS's Draw_VLc:
the spot is on for DWELL_START cycles before the beam moves and DWELL_END after it stops. The
phosphor's response saturates (1 - exp(-E / E0)), the spot is a
Gaussian SPOT units wide, and a little of the energy spreads wider (BLOOM).

None of the constants is measured: they're set so that a line at intensity 127 drawn at speed
REF_SPEED comes out at about REF_LEVEL of full brightness, and look plausible. Ratios between
lines (twice the speed, half the energy) are what the model is for.
"""
import math

import numpy as np
from PIL import Image

SCREEN_X, SCREEN_Y = 33000, 41000
DWELL_START, DWELL_END = 4, 15   # cycles the spot is on, still, before and after each vector
SPOT = 70.0                 # beam units, the spot's standard deviation
BLOOM, BLOOM_SPREAD = 0.06, 6.0
REF_SPEED, REF_LEVEL = 48.0, 0.8
COLOUR = (0.92, 0.96, 1.0)  # a slightly blue white


def line_cycles(length, speed):
    """How long the beam takes to draw a line of that length (beam units) at that DAC speed."""
    return length / speed


def _gauss_kernel(sigma):
    r = max(1, int(math.ceil(3 * sigma)))
    x = np.arange(-r, r + 1, dtype=np.float64)
    k = np.exp(-0.5 * (x / sigma) ** 2)
    return k / k.sum()


def _blur(img, sigma):
    k = _gauss_kernel(sigma)
    img = np.apply_along_axis(lambda m: np.convolve(m, k, mode='same'), 0, img)
    return np.apply_along_axis(lambda m: np.convolve(m, k, mode='same'), 1, img)


def _deposit(acc, upp, lines, ox, oy):
    h, w = acc.shape
    for x0, y0, x1, y1, z, cyc in lines:
        if z <= 0:
            continue
        length = math.hypot(x1 - x0, y1 - y0)
        n = max(1, int(math.ceil(length / (upp / 3))))
        e = z * cyc / n
        t = (np.arange(n) + 0.5) / n
        xs = (x0 + (x1 - x0) * t - ox) / upp
        ys = (y0 + (y1 - y0) * t - oy) / upp
        es = np.full(n, e)
        ix, iy = np.floor(xs).astype(int), np.floor(ys).astype(int)
        fx, fy = xs - ix, ys - iy
        for dx, dy, wgt in ((0, 0, (1 - fx) * (1 - fy)), (1, 0, fx * (1 - fy)),
                            (0, 1, (1 - fx) * fy), (1, 1, fx * fy)):
            jx, jy = ix + dx, iy + dy
            ok = (jx >= 0) & (jx < w) & (jy >= 0) & (jy < h)
            np.add.at(acc, (jy[ok], jx[ok]), (es * wgt)[ok])


_E0 = {}


def _e0(upp):
    """The energy (per pixel, after the spot) that comes out at 1 - 1/e, from the reference line."""
    if upp not in _E0:
        L = 40 * upp
        acc = np.zeros((41, 81))
        _deposit(acc, upp, [(20 * upp, 20 * upp, 20 * upp + L, 20 * upp, 127, L / REF_SPEED)], 0, 0)
        peak = _blur(acc, SPOT / upp)[20, 40]
        _E0[upp] = peak / -math.log(1 - REF_LEVEL)
    return _E0[upp]


def render(lines, path=None, width=660, view=None):
    """
    Picture of the lines: `view` is (x0, y0, x1, y1) in beam units (default the whole screen),
    `width` the picture's width in pixels. Returns the PIL image (and saves it if `path`).
    """
    vx0, vy0, vx1, vy1 = view or (0, 0, SCREEN_X, SCREEN_Y)
    upp = (vx1 - vx0) / width
    height = int(round((vy1 - vy0) / upp))
    acc = np.zeros((height, width))
    _deposit(acc, upp, lines, vx0, vy0)
    e = _blur(acc, max(0.5, SPOT / upp))
    if BLOOM:
        e = e + BLOOM * _blur(e, BLOOM_SPREAD * max(1.0, SPOT / upp))
    lum = 1 - np.exp(-e / _e0(upp))
    rgb = np.stack([lum * c for c in COLOUR], axis=-1)
    img = Image.fromarray((np.clip(rgb, 0, 1) * 255 + 0.5).astype(np.uint8), 'RGB')
    if path:
        img.save(path)
    return img


def polylines_to_lines(polys, ox, oy, unit, speed, intensity=127, blank_speed=127,
                       dwell=(DWELL_START, DWELL_END)):
    """
    Beam lines for a shape: `polys` is a list of polylines (lists of (x, y) in sprite pixels; a
    single point is a dot), placed with its origin at (ox, oy) beam units, `unit` beam units a
    pixel, drawn at `speed`, with `dwell` (before, after) cycles of the spot standing still at the
    ends of each vector. Returns (lines, cycles of beam time, drawn vectors, blank moves).
    """
    out, cycles, drawn, blanks = [], 0.0, 0, 0
    pos = None
    for poly in polys:
        pts = [(ox + x * unit, oy + y * unit) for x, y in poly]
        if pos is not None:
            cycles += math.dist(pos, pts[0]) / blank_speed
            blanks += 1
        if len(pts) == 1:
            stay = sum(dwell) + 1             # a dot: a vector of no length, so its dwell and a cycle
            out.append((pts[0][0], pts[0][1], pts[0][0], pts[0][1], intensity, stay))
            cycles += stay
            drawn += 1
        for a, b in zip(pts, pts[1:]):
            c = math.dist(a, b) / speed
            out.append((a[0], a[1], a[0], a[1], intensity, dwell[0]))
            out.append((a[0], a[1], b[0], b[1], intensity, c))
            out.append((b[0], b[1], b[0], b[1], intensity, dwell[1]))
            cycles += c
            drawn += 1
        pos = pts[-1]
    return out, cycles, drawn, blanks
