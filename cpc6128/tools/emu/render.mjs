// A reference renderer for the CPC screen, written from the data formats (not from the Z80): the
// level's background, from what the BBC version's converter describes (../build/levels.json),
// and images and the yoyo string drawn on it, clipped to a window. For frames.mjs.
//
// A buffer's byte column c of line y (level coordinates) is at
//     (y MOD 8) * #800 + ((y / 8) * w + c) MOD #800, w = 64 (sideways levels) or 80
import { readFileSync } from 'fs';
import { join } from 'path';
import { ROOT } from './mame.mjs';

const { images } = JSON.parse(readFileSync(join(ROOT, 'build/images.json'), 'utf8'));
const gfx = readFileSync(join(ROOT, 'build/GFX'));
const levels = JSON.parse(readFileSync(join(ROOT, '../build/levels.json'), 'utf8'));
const LPIX = 0x3C00, LMASK = 0x3D00, RPIX = 0x3E00, RMASK = 0x3F00;     // (in the graphics bank)
export const W = [64, 80];
export const at = (mode, c, y) => ((y & 7) << 11) | (((y >> 3) * W[mode] + c) & 0x7FF);
export { images };

// Image img with its origin at (x, y)
export function refPlot(buf, mode, clip, img, x, y) {
    const im = images[img], left = x - im.xo, top = y - im.yo;
    const shift = ((left % 4) + 4) % 4, col = Math.floor(left / 4);
    const data = im.shift[shift];
    if (data === undefined) return;
    const wb = (im.w + shift + 3) >> 2, odd = shift & 1;
    for (let k = 0; k < wb; k++) for (let r = 0; r < im.h; r++) {
        const c = col + k, line = top + r;
        if (c < clip.l || c >= clip.r || line < clip.t || line >= clip.t + (clip.h || 256)) continue;
        const code = gfx[data - 0x4000 + k * im.h + r], i = at(mode, c, line);
        const pix = gfx[(odd ? LPIX : RPIX) + code], mask = gfx[(odd ? LMASK : RMASK) + code];
        if (code === 0) continue;
        buf[i] = code >= 128 ? pix : (buf[i] & mask) | pix;
    }
}

// A line from x0 to x1 on line y, black (colour 3) or yellow (colour 1)
const LEFT = [0xFF, 0x77, 0x33, 0x11], RIGHT = [0x88, 0xCC, 0xEE, 0xFF];
export function refLine(buf, mode, clip, x0, x1, y, yellow = false) {
    if (y - clip.t < 0 || y - clip.t >= (clip.h || 256)) return;
    let a = Math.min(x0, x1), b = Math.max(x0, x1);
    if (a >= 1024 || b < 0) return;
    a = Math.max(a, 0);                                 // (clipped to the level's left edge)
    const c0 = a >> 2, c1 = b >= 1024 ? 255 : b >> 2;
    for (let c = c0; c <= c1; c++) {
        if (c < clip.l || c >= clip.r) continue;
        let mask = 0xFF;
        if (c === c0) mask = LEFT[a & 3];
        if (c === c1) mask &= RIGHT[b & 3];
        const i = at(mode, c, y);
        buf[i] = (~mask & buf[i]) | ((yellow ? 0x0F : 0xFF) & mask);
    }
}

// The background of level `name`: cell(line, k) = its dictionary cell's 8 bytes (or null if
// empty), where a line is a byte column of a sideways level (k its character row) or a
// character row of an up-and-down one (k its byte column)
export function background(name) {
    const e = levels[name];
    const vert = e.h > 256, mb = vert ? 10 : 4;
    const tables = Buffer.from(e.bg_tables, 'hex'), cells = Buffer.from(e.bg_cells, 'hex'), data = Buffer.from(e.bg_data, 'hex');
    const lines = new Map();
    function line(n) {
        if (lines.has(n)) return lines.get(n);
        const at0 = (tables[n] | tables[256 + n] << 8) - e.bg_start, nCells = vert ? 80 : 32, out = [];
        let k = 0;
        for (let cell = 0; cell < nCells; cell++) {
            const byte = cell >> 3, bit = 0x80 >> (cell & 7);
            let c = -1;
            if (data[at0 + byte] & bit) {
                c = data[at0 + 3 * mb + k++];
                if (data[at0 + mb + byte] & bit) c += 256;
                if (data[at0 + 2 * mb + byte] & bit) c += 512;
            }
            out.push(c < 0 ? null : cells.subarray(c * 8, c * 8 + 8));
        }
        lines.set(n, out);
        return out;
    }
    return { vert, cell: (n, k) => line(n)[k] };
}

// Paint the window's background into buf: byte columns [c0, c0 + cols) of character rows
// [r0, r0 + rows)
export function paintBackground(buf, bg, c0, cols, r0, rows) {
    const mode = bg.vert ? 1 : 0;
    for (let c = c0; c < c0 + cols; c++) for (let r = r0; r < r0 + rows; r++) {
        const cell = bg.vert ? bg.cell(r, c) : bg.cell(c, r);
        for (let l = 0; l < 8; l++) buf[at(mode, c, r * 8 + l)] = cell ? cell[l] : 0;
    }
}
