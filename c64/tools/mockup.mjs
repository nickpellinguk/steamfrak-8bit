// Level A_1 ("FRAK!") as the C64 shows it: Extended Colour Mode with a forced bad line at line 4
// of every character row (4-line FLI), so each 8x8 cell has one foreground colour (colour RAM)
// and each 8x4 half its own glyph and its own background (one of the 4 ECM registers: Frak's 4
// colours). 200 lines (the level's character rows 3-27). The BBC art is juggled for the 8x4 grid:
//   - platforms: pieces snapped across to 8 and down to 4 (their top line the last line of a
//     half); the top line black on cyan, the next 4 magenta and black, the lattice black on cyan
//   - ladders: the BBC ladder's black on cyan, 12 wide, centred under a 16-pixel platform unit (a
//     character boundary), from the cones' points to a rung a half or two above the platform below
//   - Scrubblies (on the top and bottom rows of platforms): the BBC Scrubbly's black outline, its
//     eyes and teeth yellow (the yellow bleeding into the cells round them), all identical; the
//     body an expanded magenta sprite behind the characters, with holes over the eyes and teeth.
//     They replace what's behind them (OFF=1: yo-yoed off, what's behind showing)
//   - keys and gems: black on cyan, on their platform unit the same way every time (keys yellow
//     from a sprite behind when one's free; NOKEYS=1: without)
// Then each cell's foreground and each half's background chosen, the glyphs counted per row.
//
//   node mockup.mjs   (needs ../../build/levels.json and ../../cpc6128/build: see ../build.sh)
// writes, in ../build: mockup.png (the BBC original, the juggled art, as shown), scrubbly.txt,
// sprite.txt (the Scrubbly as shown and its sprite), glyphs.json (each row's glyphs), and for
// pack.mjs, level.json (each half's glyph and background, each cell's foreground) and chars.bin
// (the characters alone as shown, without sprites, for compare.py); with OFF=1, *_off.*
import { background, refPlot, images, at } from '../../cpc6128/tools/emu/render.mjs';
import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { deflateSync } from 'zlib';

const OUT = new URL('../build', import.meta.url).pathname, SUF = process.env.OFF ? '_off' : process.env.GONE ? '_gone' : '';   // (GONE: the gems and keys picked up)
mkdirSync(OUT, { recursive: true });
const name = 'room_A_1', DROP = [127, 144], ROW0 = 3, ROWS = 25;
const e = JSON.parse(readFileSync(new URL('../../build/levels.json', import.meta.url), 'utf8'))[name];
const bg = background(name);
const cols = Math.ceil(e.w / 4), rows = Math.ceil(e.h / 8);
const W = Math.ceil(cols * 4 / 8) * 8 + 8, H = rows * 8;
const at2 = (x, y) => y * W + x, inside = (x, y) => x >= 0 && y >= 0 && x < W && y < H;

// ---- The BBC background, as pixels (0 background, 1 yellow, 2 magenta, 3 black)
const src = new Uint8Array(W * H);
for (let c = 0; c < cols; c++) for (let r = 0; r < rows; r++) {
    const cell = bg.vert ? bg.cell(r, c) : bg.cell(c, r);
    if (cell) for (let l = 0; l < 8; l++) for (let i = 0; i < 4; i++)
        src[at2(c * 4 + i, r * 8 + l)] = ((cell[l] >> (7 - i)) & 1) << 1 | ((cell[l] >> (3 - i)) & 1);
}
// (a ledge's area: up to 13 lines below a magenta pixel)
const ledgeArea = img => { const a = new Uint8Array(W * H); for (let x = 0; x < W; x++) for (let y = 0; y < H; y++) if (img[at2(x, y)] === 2) for (let d = -4; d <= 13; d++) if (inside(x, y + d)) a[at2(x, y + d)] = 1; return a; };

// ---- The ladders out (outside the ledges)
const base = src.slice(), area0 = ledgeArea(src);
e.lad_x.forEach((lx, k) => {
    for (let y = e.lad_y[k] - 2; y < e.lad_y[k] + e.lad_h[k] + 2; y++) for (let x = lx - 5; x < lx + 9; x++)
        if (inside(x, y) && !area0[at2(x, y)]) base[at2(x, y)] = 0;
    // (and its top, inside the ledge's area: more than 12 lines below the column's first magenta)
    for (let x = lx - 5; x < lx + 9; x++) {
        let m = -1;
        for (let y = e.lad_y[k] - 16; y < e.lad_y[k] + 8; y++) if (inside(x, y) && src[at2(x, y)] === 2) { m = y; break; }
        if (m >= 0) for (let y = m + 13; y < m + 24; y++) if (inside(x, y)) base[at2(x, y)] = 0;
    }
});

// ---- The ledges (the pieces left), snapped: left edge to 8, top to 4 mod 8
const label = new Int32Array(W * H).fill(-1), pieces = [];
for (let p = 0; p < W * H; p++) {
    if (!base[p] || label[p] >= 0) continue;
    const id = pieces.length, stack = [p], pix = [];
    label[p] = id;
    while (stack.length) {
        const q = stack.pop(); pix.push(q);
        const x = q % W, y = (q / W) | 0;
        for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
            const X = x + dx, Y = y + dy;
            if (inside(X, Y) && base[at2(X, Y)] && label[at2(X, Y)] < 0) { label[at2(X, Y)] = id; stack.push(at2(X, Y)); }
        }
    }
    pieces.push({ pix, x0: Math.min(...pix.map(q => q % W)), y0: Math.min(...pix.map(q => (q / W) | 0)) });
}
const snapTop = y => { let d = ((3 - y) % 4 + 4) % 4; if (d > 2) d -= 4; return y + d; };     // (nearest 3 mod 4: the last line of a half)
const art = new Uint8Array(W * H);
for (const pc of pieces) {
    const dx = Math.round(pc.x0 / 8) * 8 - pc.x0, dy = snapTop(pc.y0) - pc.y0;
    for (const q of pc.pix) { const x = q % W + dx, y = ((q / W) | 0) + dy; if (inside(x, y)) art[at2(x, y)] = base[q]; }
}
// ... their colours by line: the top black on background, the next 4 magenta and black, the rest
// black and background, to line 12 (each piece's lines from its own top)
for (const pc of pieces) {
    const dx = Math.round(pc.x0 / 8) * 8 - pc.x0, top = snapTop(pc.y0);
    for (const q of pc.pix) {
        const x = q % W + dx, y = ((q / W) | 0) + top - pc.y0;
        if (!inside(x, y)) continue;
        const v = art[at2(x, y)], l = y - top;
        art[at2(x, y)] = l === 0 ? (v === 3 ? 3 : 0) : l <= 4 ? (v === 0 ? 2 : v === 1 ? 2 : v) : l <= 12 ? (v === 3 ? 3 : v === 2 ? 3 : 0) : 0;   // (lines 13 on dropped: the piece ends on a half's boundary)
    }
}
// ... and the half below the magenta (lines 5-8), under the whole of the magenta's width: black
// on yellow
for (const pc of pieces) {
    const top = snapTop(pc.y0);
    for (let x = 0; x < W; x++) {
        let m = false;
        for (let l = 1; l <= 4 && !m; l++) if (inside(x, top + l) && art[at2(x, top + l)] === 2) m = true;
        if (m) for (let l = 5; l <= 8; l++) if (inside(x, top + l)) art[at2(x, top + l)] = art[at2(x, top + l)] === 3 ? 3 : 1;
    }
}

// ---- The ladders, redrawn (where the ledges aren't)
const area = ledgeArea(art), ladMid = [];
e.lad_x.forEach((lx, k) => {
    // The BBC ladder's black pixels (its yellow now the background), 12 wide, on the 8x4 grid: its
    // middle on a character boundary (the middle of the 16-pixel platform unit above it: the units
    // run from the piece's left end, on a character boundary), from the line of the cones' points
    // (a half's first line) down to the top of the platform below (the end of the half holding its
    // top line): so a whole number of halves high, and a rung every 8 lines at the same place in
    // every ladder (lines 1-3 of each character row)
    const yt = e.lad_y[k], yb = e.lad_y[k] + e.lad_h[k];
    let cx = lx + 2, band = -1, band2 = -1;
    for (let y = yt - 8; y < yt + 24 && band < 0; y++) for (let d = -3; d <= 3 && band < 0; d++) if (inside(cx + d, y) && art[at2(cx + d, y)] === 2) band = y;
    for (let y = yb - 12; y < yb + 12 && band2 < 0; y++) for (let d = -3; d <= 3 && band2 < 0; d++) if (inside(cx + d, y) && art[at2(cx + d, y)] === 2) band2 = y;
    if (band >= 0) {
        let xl = cx; while (xl > 0 && art[at2(xl - 1, band)] !== 0) xl--;     // (the piece's left end)
        xl = Math.round(xl / 8) * 8;
        cx = xl + 8 + 16 * Math.round((cx - xl - 8) / 16);
    } else cx = Math.round(cx / 8) * 8;
    const from = band >= 0 ? band + 12 : Math.round(yt / 4) * 4;
    // (its foot: clear of the platform below, ending on a rung's last line at least one half above
    // the half holding the platform's top line: 3 or 7 lines of gap)
    let to = band2 >= 0 ? band2 - 4 : Math.round(yb / 4) * 4;
    if ((to & 7) !== 4) to -= 4;
    const POLE = '....#..#....', RUNG = ['#####..#####', '#...####...#', '#####..#####'];
    for (let y = from; y < to; y++) {
        const put = (x, v) => { if (inside(x, y) && !art[at2(x, y)] && (y < from + 4 || y >= to - 4 || !area[at2(x, y)])) art[at2(x, y)] = v; };
        const p = y & 7, row = p >= 1 && p <= 3 ? RUNG[p - 1] : POLE;
        for (let x = 0; x < 12; x++) if (row[x] === '#') put(cx - 6 + x, 3);
    }
    ladMid[k] = cx;
    console.log(`ladder ${k}: middle x ${cx} (mod 8: ${cx & 7}), lines ${from}-${to - 1} (from mod 4: ${from & 3}, ${to - from} high: ${(to - from) / 4} halves)`);
});

// ---- The geometry for Trogg's physics, where the C64 draws it (level coordinates, as the CPC
// port's): each platform as its piece was snapped (left end to 8, top to a half's last line); each
// ladder moved with the platform it hangs from (its top a line below that platform's top, as in
// the original, and its height the original's, so the physics sees the original's objects moved),
// its x to the middle of the ladder as redrawn, less 2; Trogg's start moved with the platform he
// starts on
const snapX = x => Math.round(x / 8) * 8;
const plats = e.plat_x.map((x, k) => ({ x: snapX(x), y: snapTop(e.plat_y[k]), w: e.plat_w[k] }));
const under = (x, y) => {            // (the platform under x whose top is nearest y, within 16)
    let best = -1;
    e.plat_x.forEach((px, i) => { if (px <= x && x < px + e.plat_w[i] && Math.abs(e.plat_y[i] - y) <= 16 && (best < 0 || Math.abs(e.plat_y[i] - y) < Math.abs(e.plat_y[best] - y))) best = i; });
    return best;
};
const lads = e.lad_x.map((x, k) => {
    const y = e.lad_y[k], t = under(x, y - 1);
    if (t < 0 || e.plat_y[t] !== y - 1) throw new Error(`ladder ${k}: no platform at its top`);
    return { x: ladMid[k] - 2, y: plats[t].y + 1, h: e.lad_h[k], ext: e.lad_ext[k], top: t, dx: ladMid[k] - 2 - x, dy: plats[t].y + 1 - y };
});
const start = e.trogg, sp = under(start[0], start[1]);
const troggStart = sp < 0 ? start : [start[0] + plats[sp].x - e.plat_x[sp], plats[sp].y + start[1] - e.plat_y[sp]];
if (!SUF) {
    writeFileSync(`${OUT}/geometry.json`, JSON.stringify({ plats, lads, trogg: troggStart, w: e.w, h: e.h, row0: ROW0 }, null, 1));
    console.log(`geometry: ${plats.length} platforms (moved ${[...new Set(plats.map((p, k) => `${p.x - e.plat_x[k]},${p.y - e.plat_y[k]}`))].join(' ')}), ` +
        `${lads.length} ladders (moved ${[...new Set(lads.map(l => `${l.dx},${l.dy}`))].join(' ')}), Trogg from ${start} to ${troggStart}`);
}

// ---- The objects
function imagePixels(i) {
    const im = images[i], out = [];
    const on = fill => { const b = Buffer.alloc(0x4000, fill); refPlot(b, 0, { l: 0, r: 64, t: 0, h: 0 }, i, 32 + im.xo, 64 + im.yo); return b; };
    const a = on(0), z = on(0xFF);
    const px = (b, x, y) => { const v = b[at(0, (32 + x) >> 2, 64 + y)], k = (32 + x) & 3; return ((v >> (7 - k)) & 1) << 1 | ((v >> (3 - k)) & 1); };
    for (let y = 0; y < im.h; y++) { const row = []; for (let x = 0; x < im.w; x++) { const p = px(a, x, y); row.push(p === px(z, x, y) ? p : -1); } out.push(row); }
    return { im, out };
}
// the Scrubbly juggled: 44 lines (its body a line longer, so its feet have the 4 lines 40-43)
const scrub0 = imagePixels(images.findIndex(m => m.name === 'IMG_Scrubbly')).out;
import { existsSync } from 'fs';
// (SCRUBBLY=file: the Scrubbly drawn from a text grid like scrubbly.txt, checked against the rules)
const TXT = process.env.SCRUBBLY || `${OUT}/scrubbly.txt`, fromTxt = !!process.env.SCRUBBLY && existsSync(TXT);
let SCRUB = [...scrub0.slice(0, 38), scrub0[37], scrub0[38], scrub0[39], scrub0[40], scrub0[41], scrub0[0].map(() => -1)].map(r => [...r, ...Array(40 - r.length).fill(-1)]);
{
    // The BBC Scrubbly's black pixels; everything else the background, but the eyes' yellow
    // (lines 14-24, columns 8-24)
    SCRUB = scrub0.map((r, y) => [...r, ...Array(40 - r.length).fill(-1)].map((p, x) =>
        p < 0 ? -1 : p === 3 ? 3 : (p === 1 && y >= 14 && y < 33 && x >= 8 && x <= 24) ? 1 : 0));   // (the eyes' and teeth's yellow; not the feet's)
    // (moved right 4 pixels when SX=4: its middle then mid-character, so the magenta can step 8, 24 wide)
    const SXp = +(process.env.SX || 0);
    SCRUB = SCRUB.map(r => [...Array(SXp).fill(-1), ...r].slice(0, 40));
}
if (fromTxt) SCRUB = readFileSync(TXT, 'utf8').split('\n').filter(l => /^\s*\d+ /.test(l)).map(l => [...l.replace(/^\s*\d+ /, '').replace(/\|/g, '').padEnd(40)].slice(0, 40).map(c => ' .YM#'.indexOf(c) - 1));
const tag = new Uint8Array(W * H), ovl = new Int8Array(W * H).fill(-1);   // (ovl: the keys' yellow, a sprite behind them when one's free)
const SH = SCRUB.length, placed = [];   // (tag: 1 a Scrubbly's, 2 its teeth's yellow, 4 its eyes')         // 1 a Scrubbly's, 2 its teeth's cells (lines 24-31, columns 8-23), 3 its feet (lines 40-43)
// (each gem's and key's place, as drawn, and its tight box: the solid pixels' extent; picks.json)
const picks = [], pickGrids = {}, tightBox = g => { let x0 = 99, x1 = -1, y0 = 99, y1 = -1; g.forEach((r, y) => r.forEach((p, x) => { if (p >= 0) { x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); } })); return { x0, x1, y0, y1 }; };
e.draw_img.forEach((img, k) => {
    const { im, out } = imagePixels(img);
    let pix = out, left = Math.round((e.draw_x[k] - im.xo) / 8) * 8, top = Math.round((e.draw_y[k] - im.yo) / 4) * 4;
    const scrub = im.name === 'IMG_Scrubbly';
    if (scrub) {
        if (DROP.includes(e.draw_y[k]) || process.env.OFF) return;      // (OFF: the Scrubblies yo-yoed off, what's behind them showing)
        pix = SCRUB; top = snapTop(e.draw_y[k] + 1) - SH;                 // (its feet just above its ledge's top line)
        placed.push({ left, top: top - ROW0 * 8 });
        // (nothing behind it: a ladder's top or bottom between its feet, say)
        for (let y = 0; y < SH; y++) for (let x = 0; x < 40; x++) if (inside(left + x, top + y)) art[at2(left + x, top + y)] = 0;   // (its 5 characters' width, its 42 lines)
    } else {
        if (process.env.GONE) return;                                    // (GONE: picked up, what's behind showing)
        // A key or gem: centred on the 16-pixel platform unit nearest it (the units from the piece's
        // left end, on a character boundary), its last line just above the platform's top line; so
        // each sits the same way on every platform (x mod 16 from the unit, y mod 4)
        const cx0 = e.draw_x[k] - im.xo + (im.w >> 1), yb0 = e.draw_y[k] - im.yo + im.h;
        let band = -1;
        for (let y = yb0 - 4; y < yb0 + 16 && band < 0; y++) for (let d = -6; d <= 6 && band < 0; d++) if (inside(cx0 + d, y) && art[at2(cx0 + d, y)] === 2) band = y;
        if (band >= 0) {
            let xl = cx0; while (xl > 0 && art[at2(xl - 1, band)] !== 0) xl--;
            xl = Math.round(xl / 8) * 8;
            const unit = xl + 16 * Math.round((cx0 - xl - 8) / 16);
            left = unit + Math.floor((16 - im.w) / 2); top = band - 1 - im.h;
        }
        // (nothing behind it either: a ladder's foot, say)
        for (let y = 0; y < im.h; y++) for (let x = 0; x < im.w; x++) if (inside(left + x, top + y)) art[at2(left + x, top + y)] = 0;
        picks.push({ name: im.name, left, top, box: tightBox(pix) });
        pickGrids[im.name] = pix;                    // (its pixels: -1 clear; for the collision spans)
        console.log(`${im.name} ${k}: left ${left} (from its unit ${band >= 0 ? left - (left - Math.floor((16 - im.w) / 2)) : '?'}, mod 8 ${left & 7}), top ${top} (mod 4 ${top & 3})`);
    }
    pix.forEach((row, y) => row.forEach((p, x) => {
        const X = left + x, Y = top + y;
        if (p < 0 || !inside(X, Y)) return;
        if (scrub) { art[at2(X, Y)] = p; tag[at2(X, Y)] = p === 1 ? 4 : scrub0[y]?.[x] === 2 ? 5 : 1; } else { if (p === 3) art[at2(X, Y)] = 3; if (p === 1 && im.name === 'IMG_Key') ovl[at2(X, Y)] = 1; }   // (keys and gems: their black on cyan)
    }));
});

// ---- 200 lines: character rows ROW0 to ROW0 + 24
for (const a of [src, art, tag, ovl]) { a.copyWithin(0, ROW0 * 8 * W, (ROW0 + ROWS) * 8 * W); a.fill(a === ovl ? -1 : 0, ROWS * 8 * W); }
const HS = ROWS * 8;

// ---- As ECM + 4-line FLI shows it
const NC = W / 8, cellF = new Uint8Array(ROWS * NC), halfPat = [[], []], halfB = [new Uint8Array(ROWS * NC), new Uint8Array(ROWS * NC)];
const fgm = new Uint8Array(W * H), shown = new Uint8Array(W * H), rowT = Array.from({ length: ROWS }, () => new Set()), rowB = Array.from({ length: ROWS }, () => new Set());
const tops = new Set(), bottoms = new Set();
let wrong = 0;
for (let cy = 0; cy < HS; cy += 8) for (let cx = 0; cx < W; cx += 8) {
    const n = [0, 4].map(a => { const c = [0, 0, 0, 0]; for (let y = a; y < a + 4; y++) for (let x = 0; x < 8; x++) c[art[at2(cx + x, cy + y)]]++; return c; });
    const kind = [0, 4].map(a => {
        let t = new Set(), bgPix = false;
        for (let y = a; y < a + 4; y++) for (let x = 0; x < 8; x++) { const q = at2(cx + x, cy + y); if (tag[q] && tag[q] !== 5) t.add(tag[q]); if (!art[q]) bgPix = true; }
        return t.has(4) ? 'eyes1' : t.has(2) ? 'teeth' : '';
    });
    // the background for half i given the foreground F: the colour that loses least (a lost
    // background pixel counts a tenth; none at all in yellow and black without magenta, a ladder)
    const bgFor = (i, F) => { let b = -1, best = 1e9; for (const c of [0, 1, 2, 3]) { if (c === F) continue; let l = 0; for (const d of [0, 1, 2, 3]) if (d !== F && d !== c) l += n[i][d] * (d === 0 ? (n[i][1] && n[i][3] && !n[i][2] ? 0 : 0.1) : 1); if (l < best) { best = l; b = c; } } return { b, l: best }; };
    let F, bgs;
    // (the eyes: black on yellow, the sprite's holes showing the yellow; the teeth: yellow in front
    // of the sprite, their black lost to it; eyes win a cell with both)
    // (a Scrubbly's cells: all the same whichever half of a character row it starts in. Black in
    // front; each half's background yellow where the eyes or teeth are, magenta where a platform's
    // top is, else cyan; nothing but black drawn in front)
    let scrubCell = false;
    for (let y = 0; y < 8 && !scrubCell; y++) for (let x = 0; x < 8; x++) if (tag[at2(cx + x, cy + y)]) { scrubCell = true; break; }
    if (scrubCell) { F = 3; bgs = [0, 1].map(i => kind[i] === 'eyes1' ? 1 : n[i][2] ? 2 : 0); kind[0] = kind[0] || 'scrub'; kind[1] = kind[1] || 'scrub'; }
    else if (kind.includes('eyes1')) { F = 3; bgs = kind.map((k, i) => k === 'eyes1' ? 1 : bgFor(i, 3).b); }
    else if (kind.includes('teeth')) {
        // (only the yellow in front; each half's background black or cyan, whichever is more of what
        // the sprite won't cover: the pixels where the BBC Scrubbly isn't magenta)
        F = 1; bgs = [0, 4].map(a => { let b = 0, c = 0; for (let y = a; y < a + 4; y++) for (let x = 0; x < 8; x++) { const q = at2(cx + x, cy + y); if (tag[q] === 5) continue; if (art[q] === 3) b++; else if (art[q] === 0) c++; } return b > c ? 3 : 0; });
        kind[0] = kind[1] = 'teeth';
    }
    else if (kind.includes('feet')) { F = 1; bgs = kind.map((k, i) => k === 'feet' ? (n[i][2] ? 2 : 0) : bgFor(i, 1).b); }
    else if (kind.includes('eyes1') || kind.includes('eyes2')) { F = 3; bgs = kind.map((k, i) => k === 'eyes1' ? 1 : k === 'eyes2' ? 2 : bgFor(i, 3).b); }
    else {
        let best = null;
        for (const f of [3, 1, 2, 0]) { const r = [0, 1].map(i => bgFor(i, f)), l = r[0].l + r[1].l; if (!best || l < best.l) best = { f, bgs: r.map(x => x.b), l }; }
        F = best.f; bgs = best.bgs;
    }
    cellF[(cy >> 3) * NC + (cx >> 3)] = F;
    [0, 1].forEach(i => {
        const B = bgs[i], used = n[i].filter(v => v).length, kk = kind[i];
        let pat = '';
        for (let y = 4 * i; y < 4 * i + 4; y++) {
            let byte = 0;
            for (let x = 0; x < 8; x++) {
                const p = art[at2(cx + x, cy + y)];
                // (in the fringe, anything not background is black; the teeth: yellow; the feet: their
                // black on yellow; otherwise a pixel neither colour: the background colour bleeds into
                // whichever of the two isn't black, another shows as black if the foreground is)
                const fg = kk === 'teeth' || kk === 'feet' ? p === 1 : kk === 'eyes1' || kk === 'eyes2' || kk === 'scrub' ? p === 3 :
                    used > 1 && (p === F || (p !== B && (p !== 0 ? F === 3 : B === 3)));
                byte = byte << 1 | (fg ? 1 : 0);
                shown[at2(cx + x, cy + y)] = fg ? F : B; fgm[at2(cx + x, cy + y)] = fg ? 1 : 0;
                if ((fg ? F : B) !== p) wrong++;
            }
            pat += byte.toString(16).padStart(2, '0');
        }
        (i ? bottoms : tops).add(pat);
        halfPat[i][(cy >> 3) * NC + (cx >> 3)] = pat; halfB[i][(cy >> 3) * NC + (cx >> 3)] = B;
        (i ? rowB : rowT)[cy >> 3].add(pat);
    });
}
{
    // the first Scrubbly kept: where it is, as shown (or, from scrubbly.txt, as drawn: checked)
    const k0 = 0; const k = e.draw_img.findIndex((img, k) => images[img].name === 'IMG_Scrubbly' && !DROP.includes(e.draw_y[k]));
    const left = Math.round((e.draw_x[k] - images[e.draw_img[k]].xo) / 8) * 8, top = snapTop(e.draw_y[k] + 1) - SH - ROW0 * 8;
    const lines = ['; The Scrubbly, 40 x ' + SH + ' (. background, Y yellow, M magenta, # black, space transparent), as shown.', '; | marks the characters, the blank lines their halves (4 lines).', '; In ECM + 4-line FLI each 8x8 character has one foreground colour for both halves, each 4-line', '; half one background: so each half 2 colours at most, one of them its character\'s foreground.', '; Its last line is just above the ledge\'s top (black) line.', ''];
    const bad = [];
    for (let y = 0; y < SH; y++) {
        let l = '';
        for (let x = 0; x < 40; x++) {
            if (x && x % 8 === 0) l += '|';
            const v = fromTxt ? SCRUB[y][x] : (SCRUB[y][x] < 0 ? -1 : shown[at2(left + x, top + y)]);
            l += ' .YM#'[v + 1];
        }
        lines.push(String(y).padStart(3) + ' ' + l);
        if (((top + y) & 3) === 3 && y < SH - 1) lines.push('');
    }
    if (fromTxt) {
        for (let cy = 0; cy < SH - 3; cy += 8) for (let cx = 0; cx < 40; cx += 8) {
            const hs = [cy, cy + 4].filter(y => y < SH).map(a => { const s = new Set(); for (let y = a; y < a + 4; y++) for (let x = 0; x < 8; x++) if (SCRUB[y][cx + x] >= 0) s.add(SCRUB[y][cx + x]); return s; });
            if (hs.some(h => h.size > 2)) bad.push(`character ${cx / 8},${cy / 8}: a half with 3 colours or more`);
            else { const two = hs.filter(h => h.size === 2); if (two.length === 2 && ![...two[0]].some(c => two[1].has(c))) bad.push(`character ${cx / 8},${cy / 8}: its halves share no colour (one foreground for both)`); }
        }
        console.log(bad.length ? 'scrubbly.txt breaks the rules: ' + bad.join('; ') : 'scrubbly.txt keeps the rules');
    } else if (!SUF) writeFileSync(`${OUT}/scrubbly.txt`, lines.join('\n') + '\n');
}
const sets = [], order = rowT.map((t, r) => r).sort((a, b) => (rowT[b].size + rowB[b].size) - (rowT[a].size + rowB[a].size));
for (const r of order) {
    let s = sets.find(s => new Set([...s.T, ...rowT[r]]).size <= 64 && new Set([...s.B, ...rowB[r]]).size <= 64);
    if (!s) sets.push(s = { T: new Set(), B: new Set(), rows: [] });
    rowT[r].forEach(p => s.T.add(p)); rowB[r].forEach(p => s.B.add(p)); s.rows.push(r);
}
console.log('glyph halves each character row needs (tops/bottoms): ' + rowT.map((t, r) => r + ':' + t.size + '/' + rowB[r].size).join(' '));
sets.forEach((s, k) => console.log(`character set ${k}: rows ${s.rows.sort((a, b) => a - b).join(' ')} (${s.T.size} tops, ${s.B.size} bottoms)`));
const allG = new Map(); for (const set of [...rowT, ...rowB]) for (const p of set) allG.set(p, (allG.get(p) || 0) + 1);
writeFileSync(`${OUT}/glyphs${SUF}.json`, JSON.stringify({ T: rowT.map(t => [...t]), B: rowB.map(b => [...b]), G: [...allG.keys()] }));
console.log(`(all together: ${tops.size} glyph tops, ${bottoms.size} bottoms; ${wrong} of the 200 lines' pixels differ from the juggled art)`);

const shownChars = shown.slice();   // (the characters alone, before any sprite)
writeFileSync(`${OUT}/chars${SUF}.bin`, shownChars.subarray(0, W * HS));
// ---- The Scrubbly's sprite: hi-res, expanded both ways (48 x 42), magenta, behind the characters:
// it shows wherever a character pixel is a background one (glyph bit 0, whichever ECM colour).
// Each 2x2 block solid where the BBC Scrubbly is magenta (2 or more of its 4 pixels, none of them
// outside it), but a hole where it touches the eyes' or teeth's yellow. (Its feet: clear, so cyan.) Its left 8 pixels left of the Scrubbly's (centred).
const SPR = [];
for (let sy = 0; sy < 21; sy++) { const r = []; for (let sx = 0; sx < 24; sx++) {
    let n = 0, eye = false;
    for (let dy = 0; dy < 2; dy++) for (let dx = 0; dx < 2; dx++) { const x = sx * 2 + dx - 8, y = sy * 2 + dy, q = (x >= 0 && x < 40 && y < SH) ? (scrub0[y][x] ?? -1) : -1, p = (x >= 0 && x < 40 && y < SH) ? SCRUB[y][x] : -1; if (q === 2) n++; if (q < 0) n -= 9; if (p === 1) eye = true; }
    r.push(n >= 2 && !eye ? 1 : 0); } SPR.push(r); }
for (const { left, top } of placed) for (let y = 0; y < 42; y++) for (let x = 0; x < 48; x++) {
    const X = left - 8 + x, Y = top + y;
    if (SPR[y >> 1][x >> 1] && inside(X, Y) && Y < HS && !fgm[at2(X, Y)]) shown[at2(X, Y)] = 2;
}
writeFileSync(`${OUT}/sprite.txt`, '; The Scrubbly\'s sprite, 24 x 21 (# solid magenta, . clear), shown expanded to 48 x 42\n' + SPR.map(r => r.map(v => v ? '#' : '.').join('')).join('\n') + '\n');
// (for the demo: where the Scrubblies' sprites go, the sprite, and the picture with them but
// without the keys' sprites)
// (and the balloon and dagger: their pixels, and their origins' place in them)
const hazards = Object.fromEntries(['IMG_Balloon', 'IMG_DaggerLR'].map(n => { const { im, out } = imagePixels(images.findIndex(m => m.name === n)); return [n, { grid: out, xo: im.xo, yo: im.yo }]; }));
if (!SUF) writeFileSync(`${OUT}/picks.json`, JSON.stringify({ picks, scrubBox: tightBox(SCRUB), grids: { IMG_Scrubbly: SCRUB, ...pickGrids }, hazards }));
writeFileSync(`${OUT}/scrub${SUF}.json`, JSON.stringify({ placed: placed.map(({ left, top }) => ({ x: left - 8, top })), sprite: SPR.map(r => r.join('')) }));
writeFileSync(`${OUT}/charsspr${SUF}.bin`, shown.subarray(0, W * HS));
// ---- The picture (the keys and gems drawn over the juggled art and the result)
const KEYS = !process.env.NOKEYS;
if (KEYS) for (let q = 0; q < W * H; q++) if (ovl[q] === 1 && !fgm[q]) shown[q] = 1;   // (the keys' yellow sprites, behind)
const pal = [[0, 200, 200], [255, 255, 0], [255, 0, 255], [0, 0, 0]], GAP = 6, IH = HS * 3 + GAP * 2;
const raw = Buffer.alloc((W * 3 + 1) * IH);
[src, art, shown].forEach((img, k) => { for (let y = 0; y < HS; y++) for (let x = 0; x < W; x++) raw.set(pal[img[at2(x, y)]], (k * (HS + GAP) + y) * (W * 3 + 1) + 1 + x * 3); });
for (const k of [1, 2]) for (let y = k * (HS + GAP) - GAP; y < k * (HS + GAP); y++) for (let x = 0; x < W; x++) raw.set([60, 60, 60], y * (W * 3 + 1) + 1 + x * 3);
const crcT = Array.from({ length: 256 }, (_, n) => { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c >>> 0; });
const crc = b => { let c = 0xffffffff; for (const x of b) c = crcT[(c ^ x) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
const chunk = (t, d) => { const l = Buffer.alloc(4); l.writeUInt32BE(d.length); const td = Buffer.concat([Buffer.from(t), d]); const c = Buffer.alloc(4); c.writeUInt32BE(crc(td)); return Buffer.concat([l, td, c]); };
const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(IH, 4); ihdr[8] = 8; ihdr[9] = 2;
writeFileSync(`${OUT}/mockup${SUF}.png`, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
// (check: the Scrubblies as shown, each 48 x 42 from its sprite's corner, compared with the first)
if (process.env.CHECK) {
    const grab = ({ left, top }) => { const g = []; for (let y = 0; y < 42; y++) for (let x = 0; x < 48; x++) { const X = left - 8 + x, Y = top + y; g.push(inside(X, Y) && Y < HS ? shown[at2(X, Y)] : 9); } return g; };
    const g0 = grab(placed[0]);
    placed.forEach((p, k) => { const g = grab(p), d = []; g.forEach((v, i) => { if (v !== g0[i]) d.push(`${i % 48},${(i / 48) | 0}:${g0[i]}->${v}`); }); console.log(`Scrubbly ${k} at x ${p.left} (mod 8 ${p.left & 7}), y ${p.top} (mod 4 ${p.top & 3}, mod 8 ${p.top & 7}): ${d.length} pixels differ from Scrubbly 0 ${d.slice(0, 12).join(' ')}`); });
}

// ---- The C64 data, for pack.mjs: the halves as glyphs and ECM backgrounds, every cell's foreground
writeFileSync(`${OUT}/level${SUF}.json`, JSON.stringify({ NC, ROWS, F: [...cellF], T: halfPat[0], B: halfPat[1], TB: [...halfB[0]], BB: [...halfB[1]] }));
