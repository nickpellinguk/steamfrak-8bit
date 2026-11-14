// A level for the C64, from its pieces: ../levels/<name>.txt ("name x y" lines, placing pieces from
// ../levels/common.json and the level type's ../levels/<type>.json), stamped half by half (8x4)
// into the map, later pieces' halves replacing earlier ones'. Each piece is strings of colours
// (export.mjs's legend: - transparent, 0 1 2 3 cyan yellow magenta black, c y m b the same as
// scenery baked in, S yellow from a sprite: background in the characters); its halves cut on
// its own 8x4 grid (a half all - is no part of it), and placed on the map's (x a multiple of 8,
// y of 4; an enemy, "rows": "even", on an even character row: y a multiple of 16).
//
// The glyphs are fixed by the level type, not the level: orthogonal, each a 4-line picture whose
// two halves of the character are the same (so a glyph is the same in a character row's top or
// bottom half); every half shown in one of them, black (the foreground, every cell's) on one of
// the 4 ECM backgrounds. Two character sets, by band (the set changes at a row's line 4: band k
// is row k - 1's bottoms and row k's tops): set 0 the even bands', set 1 the odd's. In both, the
// same first: 0 blank, 1-4 the yoyo's string, then the common pieces' glyphs (keys, gems: the
// same in every level type; NCOMMON after them), then the type's that can fall in either band;
// then each set's own (an enemy's, its halves always in the same bands). At most 64 in each.
//   node level.mjs [A_1]   ->  ../build: charsets.bin, bandset.bin, tops.bin, bottoms.bin,
//      scrpatch.inc, common.bin, levelcs.bin, level.inc, geometry.json, picks.json, scrub.json,
//      chars*.bin and charsspr*.bin (the characters as shown, for compare.py), level.png
import { readFileSync, writeFileSync } from 'fs';
import { deflateSync } from 'zlib';
const LV = new URL('../levels/', import.meta.url).pathname, DIR = new URL('../build/', import.meta.url).pathname;
const NAME = process.argv[2] || 'A_1', ROW0 = 3, Y0 = ROW0 * 8;
const fail = m => { throw new Error(`${NAME}: ${m}`); };

// ---- The level file
const lines = readFileSync(`${LV}${NAME}.txt`, 'utf8').split('\n').map(l => l.replace(/#.*/, '').trim()).filter(Boolean);
const meta = {}, placed = [];
for (const l of lines) {
    const f = l.split(/\s+/);
    if (['type', 'size', 'width', 'height', 'trogg'].includes(f[0])) { meta[f[0]] = f.slice(1); continue; }
    if (f.length !== 3 || !/^-?\d+$/.test(f[1]) || !/^-?\d+$/.test(f[2])) fail(`a line not "name x y": ${l}`);
    placed.push({ name: f[0], x: +f[1], y: +f[2] });
}
for (const k of ['type', 'size', 'width', 'height', 'trogg']) if (!meta[k]) fail(`no "${k}" line`);
const [NC, ROWS] = meta.size.map(Number), NHR = ROWS * 2, W = NC * 8, HS = ROWS * 8;
const common = JSON.parse(readFileSync(LV + 'common.json')).pieces, typed = JSON.parse(readFileSync(`${LV}${meta.type[0]}.json`)).pieces;
const pieceOf = n => typed[n] || common[n] || fail(`no piece "${n}"`);

// ---- Pieces' halves as tiles: a glyph (4 bytes, black set) and a background (0-3)
const COL = { '-': 0, S: 0, 0: 0, 1: 1, 2: 2, 3: 3, c: 0, y: 1, m: 2, b: 3 };
const tilesOf = new Map();          // (piece name -> [{ i, j, tile }]: half row i, column j)
const tileKey = t => t.g + ':' + t.b;
function tiles(name) {
    if (tilesOf.has(name)) return tilesOf.get(name);
    const p = pieceOf(name), a = p.art, hh = a.length / 4, ww = a[0].length / 8;
    if (!Number.isInteger(hh) || !Number.isInteger(ww) || a.some(r => r.length !== a[0].length)) fail(`piece ${name}: not whole halves (${a[0].length} x ${a.length})`);
    const out = [];
    for (let i = 0; i < hh; i++) for (let j = 0; j < ww; j++) {
        let any = false, g = '', bg = new Set();
        for (let y = 0; y < 4; y++) { let v = 0; for (let x = 0; x < 8; x++) { const ch = a[i * 4 + y][j * 8 + x]; if (!(ch in COL)) fail(`piece ${name}: "${ch}"`); if (ch !== '-') any = true; const c = COL[ch]; if (c === 3) v |= 0x80 >> x; else bg.add(c); } g += v.toString(16).padStart(2, '0'); }
        if (!any) continue;
        if (bg.size > 1) fail(`piece ${name}: half ${j},${i} has ${[...bg].join(' and ')} as well as black (one background a half)`);
        out.push({ i, j, tile: { g, b: bg.size ? [...bg][0] : 0 } });
    }
    tilesOf.set(name, out);
    return out;
}

// ---- Placed: on the grid; stamped into three maps (all; the Scrubblies off; the gems and keys picked up)
const halfAt = (o, t) => ((o.y >> 2) + t.i) * NC + (o.x >> 3) + t.j;
const bandOf = hr => (hr + 1) >> 1;          // (half row hr: row hr >> 1's top or bottom)
for (const o of placed) {
    const p = pieceOf(o.name);
    if (o.x & 7 || o.y & 3) fail(`${o.name} at ${o.x},${o.y}: not on the 8x4 grid`);
    if (p.rows === 'even' && o.y & 15) fail(`${o.name} at ${o.x},${o.y}: not on an even character row (y a multiple of 16)`);
    for (const t of tiles(o.name)) { const hr = (o.y >> 2) + t.i, c = (o.x >> 3) + t.j; if (hr < 0 || hr >= NHR || c < 0 || c >= NC) fail(`${o.name} at ${o.x},${o.y}: off the map`); }
}
const isEnemy = o => !!pieceOf(o.name).enemy, isPick = o => !!pieceOf(o.name).pick;
const stamp = keep => { const m = new Array(NHR * NC).fill(null), who = new Int16Array(NHR * NC).fill(-1); placed.forEach((o, k) => { if (keep(o)) for (const t of tiles(o.name)) { m[halfAt(o, t)] = t.tile; who[halfAt(o, t)] = k; } }); return { m, who }; };
const full = stamp(() => true), off = stamp(o => !isEnemy(o)), gone = stamp(o => !isPick(o));
// (an object's halves are all its own: nothing of it under another piece placed later)
placed.forEach((o, k) => { if (isEnemy(o) || isPick(o)) for (const t of tiles(o.name)) if (full.who[halfAt(o, t)] !== k) fail(`${o.name} at ${o.x},${o.y}: covered by ${placed[full.who[halfAt(o, t)]].name}`); });

// ---- The glyphs: common, the type's either-band ones, each set's own
const BLANK = '00000000', STRING = 1;
const glyphs = [new Map(), new Map()];       // (set -> glyph -> index)
const add = (set, g) => { if (!glyphs[set].has(g)) glyphs[set].set(g, glyphs[set].size); };
for (const s of [0, 1]) { add(s, BLANK); for (let l = 0; l < 4; l++) glyphs[s].set('string' + l, glyphs[s].size); }
// (the common pieces' glyphs in every level; then the type's, as the type file lists them: each
// tile's bands, either if the piece can go on any row)
const bandsOf = (name, t) => pieceOf(name).rows === 'even' ? [bandOf(t.i) & 1] : [0, 1];
for (const n of Object.keys(common)) for (const t of tiles(n)) for (const s of [0, 1]) add(s, t.tile.g);
const NCOMMON = glyphs[0].size;
for (const n of Object.keys(typed)) for (const t of tiles(n)) if (bandsOf(n, t).length === 2) for (const s of [0, 1]) add(s, t.tile.g);
const NBOTH = glyphs[0].size;
for (const n of Object.keys(typed)) for (const t of tiles(n)) { const b = bandsOf(n, t); if (b.length === 1) add(b[0], t.tile.g); }
for (const s of [0, 1]) if (glyphs[s].size > 64) fail(`character set ${s} needs ${glyphs[s].size} glyphs`);
// (checked: each placed half's glyph is in its band's set, as it must be by its piece's rows)
const cs = Buffer.alloc(1024);
for (const s of [0, 1]) for (const [g, i] of glyphs[s]) for (let l = 0; l < 4; l++) {
    const v = g.startsWith('string') ? (l === +g.slice(6) ? 0xff : 0) : parseInt(g.slice(l * 2, l * 2 + 2), 16);
    cs[s * 512 + i * 8 + l] = v; cs[s * 512 + i * 8 + 4 + l] = v;
}
const bandset = new Uint8Array(ROWS + 1).map((_, b) => b & 1);
const codes = st => {
    const t = Buffer.alloc(ROWS * NC), b = Buffer.alloc(ROWS * NC);
    for (let hr = 0; hr < NHR; hr++) for (let c = 0; c < NC; c++) {
        const tile = st.m[hr * NC + c] || { g: BLANK, b: 0 }, set = bandOf(hr) & 1, i = glyphs[set].get(tile.g);
        if (i === undefined) fail(`half ${c},${hr} (${placed[st.who[hr * NC + c]].name}): its glyph isn't in set ${set}`);
        (hr & 1 ? b : t)[(hr >> 1) * NC + c] = i | tile.b << 6;
    }
    return [t, b];
};
const [tops, bottoms] = codes(full), [topsOff, bottomsOff] = codes(off), [topsGone, bottomsGone] = codes(gone);

// ---- The patches: each Scrubbly's cells, knocking it off, then each gem's and key's, picking it
// up (cells as map offsets; new codes from the map without it)
const cellsOf = o => [...new Set(tiles(o.name).map(t => (((o.y >> 2) + t.i) >> 1) * NC + (o.x >> 3) + t.j))].sort((a, b) => a - b);
const enemies = placed.filter(isEnemy), picks = placed.filter(isPick);
const sp = enemies.map(cellsOf), pp = picks.map(cellsOf);
const used = new Map();
[...sp, ...pp].forEach((cl, k) => cl.forEach(q => { if (used.has(q)) fail(`cell ${q % NC},${(q / NC) | 0}: two objects' (${used.get(q)} and ${k})`); used.set(q, k); }));
const cells = [...sp.flat(), ...pp.flat()], ns = sp.flat().length;
if (cells.length > 256) fail('more than 256 patch cells');
const isP = new Set(pp.flat());
const newT = q => isP.has(q) ? topsGone[q] : topsOff[q], newB = q => isP.has(q) ? bottomsGone[q] : bottomsOff[q];
const starts = (gs, base) => gs.reduce((a, g) => (a.push(a[a.length - 1] + g.length), a), [base]).slice(0, -1);
let inc = `; made by tools/level.mjs from levels/${NAME}.txt: each Scrubbly's patch knocking it off, then each gem's and\n; key's picking it up: cells as level map offset, row, column, new top code, new bottom code\nSTRING = ${STRING}\nNCOMMON = ${NCOMMON}\nNPATCH = ${cells.length}\n`;
inc += `scrpn   .byte ${sp.map(g => g.length).join(', ')}\nscrpi   .byte ${starts(sp, 0).join(', ')}\n`;
inc += `pkpn    .byte ${pp.map(g => g.length).join(', ')}\npkpi    .byte ${starts(pp, ns).join(', ')}\n`;
inc += `scrplo  .byte ${cells.map(q => q & 255).join(', ')}\nscrphi  .byte ${cells.map(q => q >> 8).join(', ')}\n`;
inc += `scrpr   .byte ${cells.map(q => (q / NC) | 0).join(', ')}\nscrpc   .byte ${cells.map(q => q % NC).join(', ')}\n`;
inc += `scrpt   .byte ${cells.map(newT).join(', ')}\nscrpb   .byte ${cells.map(newB).join(', ')}\n`;
writeFileSync(DIR + 'scrpatch.inc', inc);
writeFileSync(DIR + 'charsets.bin', cs); writeFileSync(DIR + 'bandset.bin', bandset);
writeFileSync(DIR + 'common.bin', cs.subarray(0, NCOMMON * 8));
writeFileSync(DIR + 'levelcs.bin', Buffer.concat([cs.subarray(NCOMMON * 8, 512), cs.subarray(512 + NCOMMON * 8, 1024)]));
writeFileSync(DIR + 'tops.bin', tops); writeFileSync(DIR + 'bottoms.bin', bottoms);
writeFileSync(DIR + 'level.inc', `NC = ${NC}\nROWS = ${ROWS}\n`);

// ---- The objects' shapes (their own pixels: digits and S), the physics, the sprites
const shape = name => {      // (the grid from its first row and column with any of its own pixels)
    const a = pieceOf(name).art, own = ch => /[0-3S]/.test(ch);
    const r0 = a.findIndex(r => [...r].some(own)), c0 = Math.min(...a.map(r => { const i = [...r].findIndex(own); return i < 0 ? 99 : i; }));
    const r1 = a.length - 1 - [...a].reverse().findIndex(r => [...r].some(own));
    const g = a.slice(r0, name === 'scrubbly' ? r1 + 1 : a.length).map(r => [...r.slice(c0)].map(ch => !own(ch) && ch !== '0' ? -1 : ch === 'S' ? 1 : +ch));
    return { g, dx: c0, dy: r0 };
};
const tightBox = g => { let x0 = 99, x1 = -1, y0 = 99, y1 = -1; g.forEach((r, y) => r.forEach((p, x) => { if (p >= 0) { x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); } })); return { x0, x1, y0, y1 }; };
const IMG = { key: 'IMG_Key', gem: 'IMG_Gem' }, grids = {};
const pickOut = picks.map(o => { const s = shape(o.name); grids[IMG[o.name]] = s.g; return { name: IMG[o.name], left: o.x + s.dx, top: o.y + s.dy + Y0, box: tightBox(s.g) }; });
const sc = enemies.length ? shape(enemies[0].name) : null;
if (sc) { if (sc.g[0].length > 40) sc.g = sc.g.map(r => r.slice(0, 40)); while (sc.g[0].length < 40) sc.g.forEach(r => r.push(-1)); grids.IMG_Scrubbly = sc.g; }
const scrubPlaced = enemies.map(o => ({ x: o.x + sc.dx - 8, top: o.y + sc.dy }));
const hz = JSON.parse(readFileSync(LV + 'hazards.json')).images;
const hazards = Object.fromEntries(Object.entries(hz).map(([k, v]) => [k, { xo: v.xo, yo: v.yo, grid: v.grid.map(r => [...r].map(ch => ch === '-' ? -1 : +ch)) }]));
writeFileSync(DIR + 'picks.json', JSON.stringify({ picks: pickOut, scrubBox: sc ? tightBox(sc.g) : null, grids, hazards }));
const spr = sc ? pieceOf(enemies[0].name).sprite : Array(21).fill('.'.repeat(24));
writeFileSync(DIR + 'scrub.json', JSON.stringify({ placed: scrubPlaced, sprite: spr.map(r => r.replace(/#/g, '1').replace(/\./g, '0')) }));
const plats = [], lads = [];
for (const o of placed) { const p = pieceOf(o.name);
    for (const [dx, dy, w] of p.plats || []) plats.push({ x: o.x + dx, y: o.y + dy + Y0, w });
    if (p.ladder) { const [dx, dy, h, ext] = p.ladder; lads.push({ x: o.x + dx, y: o.y + dy + Y0, h, ext }); } }
const [tx, ty] = meta.trogg.map(Number);
writeFileSync(DIR + 'geometry.json', JSON.stringify({ plats, lads, trogg: [tx, ty + Y0], w: +meta.width[0], h: +meta.height[0], row0: ROW0 }, null, 1));

// ---- The characters as shown (each map), with the Scrubblies' sprites behind, and a picture
const shown = (st, withSpr) => {
    const px = new Uint8Array(W * HS);
    for (let hr = 0; hr < NHR; hr++) for (let c = 0; c < NC; c++) { const t = st.m[hr * NC + c] || { g: BLANK, b: 0 };
        for (let l = 0; l < 4; l++) { const v = parseInt(t.g.slice(l * 2, l * 2 + 2), 16); for (let x = 0; x < 8; x++) px[(hr * 4 + l) * W + c * 8 + x] = v & 0x80 >> x ? 3 : t.b; } }
    if (withSpr) for (const s of (st === off ? [] : scrubPlaced)) for (let y = 0; y < 42; y++) for (let x = 0; x < 48; x++) {
        const X = s.x + x, Y = s.top + y;
        if (spr[y >> 1][x >> 1] === '#' && X >= 0 && X < W && Y < HS) { const q = Y * W + X, hr = Y >> 2, c = X >> 3, t = st.m[hr * NC + c] || { g: BLANK }; if (!(parseInt(t.g.slice((Y & 3) * 2, (Y & 3) * 2 + 2), 16) & 0x80 >> (X & 7))) px[q] = 2; }
    }
    return px;
};
for (const [suf, st] of [['', full], ['_off', off], ['_gone', gone]]) { writeFileSync(`${DIR}chars${suf}.bin`, shown(st, false)); writeFileSync(`${DIR}charsspr${suf}.bin`, shown(st, true)); }
{
    const img = shown(full, true), pal = [[0, 200, 200], [255, 255, 0], [255, 0, 255], [0, 0, 0]], S = 2, IW = W * S, IH = HS * S;
    const raw = Buffer.alloc((IW * 3 + 1) * IH);
    for (let y = 0; y < IH; y++) for (let x = 0; x < IW; x++) raw.set(pal[img[(y / S | 0) * W + (x / S | 0)]], y * (IW * 3 + 1) + 1 + x * 3);
    const crcT = Array.from({ length: 256 }, (_, n) => { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c >>> 0; });
    const crc = b => { let c = 0xffffffff; for (const x of b) c = crcT[(c ^ x) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
    const chunk = (t, d) => { const l = Buffer.alloc(4); l.writeUInt32BE(d.length); const td = Buffer.concat([Buffer.from(t), d]); const c = Buffer.alloc(4); c.writeUInt32BE(crc(td)); return Buffer.concat([l, td, c]); };
    const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(IW, 0); ihdr.writeUInt32BE(IH, 4); ihdr[8] = 8; ihdr[9] = 2;
    writeFileSync(DIR + 'level.png', Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
}
console.log(`${NAME} (${meta.type[0]}): ${placed.length} pieces placed; glyphs: ${NCOMMON} common (blank, string, keys, gems), ${NBOTH - NCOMMON} the type's in either band, ` +
    `then set 0 ${glyphs[0].size - NBOTH} and set 1 ${glyphs[1].size - NBOTH} of their own: ${glyphs[0].size} and ${glyphs[1].size} of 64; ` +
    `patches ${sp.map(g => g.length).join(' ')} / ${pp.map(g => g.length).join(' ')}; ${plats.length} platforms, ${lads.length} ladders`);
