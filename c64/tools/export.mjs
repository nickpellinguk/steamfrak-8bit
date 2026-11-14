// One-off: A_1 as mockup.mjs draws it, cut into the new level format (../levels): the pieces
// (named ledges and ladders, the Scrubbly: scrubbly.json; keys and gems: common.json) as strings
// of shown colours, and the level as a text file of "name x y" lines (A_1.txt).
//   EXPORT=full node mockup.mjs; OFF=1 GONE=1 EXPORT=scenery node mockup.mjs;
//   OFF=1 GONE=1 NOLADDERS=1 EXPORT=ledges node mockup.mjs; node export.mjs
// A piece is cut on the 8x4 grid: every half (8x4) it owns, whole, as shown (so a ladder's top
// carries the ledge round it, the Scrubbly's feet hide the ledge's top line under them). Colours:
//   - transparent (a half all "-" is no part of the piece; inside one of its halves, background)
//   0 1 2 3: cyan, yellow, magenta, black, the object's own pixels
//   c y m b: the same colours, scenery baked into the piece (not the object's shape)
//   S: a key's yellow, from a sprite behind (the characters show background)
import { readFileSync, writeFileSync, mkdirSync } from 'fs';
const B = new URL('../build/', import.meta.url).pathname, OUT = new URL('../levels/', import.meta.url).pathname;
mkdirSync(OUT, { recursive: true });
const ld = n => JSON.parse(readFileSync(`${B}export_${n}.json`));
const full = ld('full'), scen = ld('scenery'), ledg = ld('ledges');
const { W, HS, NC } = scen, NH = HS / 4, Y0 = scen.ROW0 * 8;
const px = (d, x, y) => d.shown[y * W + x];
const halfPix = (d, hr, c) => { const a = []; for (let y = hr * 4; y < hr * 4 + 4; y++) for (let x = c * 8; x < c * 8 + 8; x++) a.push(px(d, x, y)); return a; };
const empty = a => a.every(v => v === 0);
const same = (a, b) => a.every((v, i) => v === b[i]);

// ---- Ledges (the ledges-only run): each half to the ledge owning most of its pixels
const owner = (arr, hr, c) => { const n = new Map(); for (let y = hr * 4; y < hr * 4 + 4; y++) for (let x = c * 8; x < c * 8 + 8; x++) { const o = arr[y * W + x]; if (o >= 0) n.set(o, (n.get(o) || 0) + 1); } let b = -1, m = 0; for (const [o, k] of n) if (k > m) { m = k; b = o; } return b; };
const ledgeHalves = new Map(), ladHalves = new Map();
for (let hr = 0; hr < NH; hr++) for (let c = 0; c < NC; c++) {
    if (!empty(halfPix(ledg, hr, c))) { const o = owner(ledg.ledgeOwner, hr, c); if (o < 0) throw new Error(`half ${c},${hr}: a ledge's, but whose?`); (ledgeHalves.get(o) || ledgeHalves.set(o, []).get(o)).push([hr, c]); }
    const lo = owner(scen.ladOwner, hr, c);
    if (lo >= 0 && !empty(halfPix(scen, hr, c))) (ladHalves.get(lo) || ladHalves.set(lo, []).get(lo)).push([hr, c]);
}
// (checked: the scenery is the ledges, then the ladders over them, half for half)
const isLad = new Set([...ladHalves.values()].flat().map(([hr, c]) => hr * NC + c));
for (let hr = 0; hr < NH; hr++) for (let c = 0; c < NC; c++) if (!isLad.has(hr * NC + c) && !same(halfPix(ledg, hr, c), halfPix(scen, hr, c))) throw new Error(`half ${c},${hr}: the scenery isn't the ledges there`);

const D = '0123', L = 'cymb';
const cut = (d, halves, own) => {      // (a piece from halves of run d: its origin, its rows)
    const r0 = Math.min(...halves.map(h => h[0])), r1 = Math.max(...halves.map(h => h[0])), c0 = Math.min(...halves.map(h => h[1])), c1 = Math.max(...halves.map(h => h[1]));
    const set = new Set(halves.map(([hr, c]) => hr * NC + c)), rows = [];
    for (let y = r0 * 4; y < r1 * 4 + 4; y++) { let s = ''; for (let x = c0 * 8; x < c1 * 8 + 8; x++) {
        if (!set.has((y >> 2) * NC + (x >> 3))) { s += '-'; continue; }
        const v = px(d, x, y); s += own ? own(x, y, v) : v === 0 ? '-' : D[v]; } rows.push(s); }
    return { x: c0 * 8, y: r0 * 4, art: rows };
};
const pieces = {}, placeList = [], key = p => JSON.stringify([p.art, p.plats, p.ladder]);
const byArt = new Map();
const add = (prefix, p, x, y) => {
    const k = key(p);
    let name = byArt.get(k);
    if (!name) { name = `${prefix}${[...byArt.values()].filter(n => n.startsWith(prefix) && /\d$/.test(n)).length + 1}`; byArt.set(k, name); pieces[name] = p; }
    placeList.push([name, x, y]);
};
// (each BBC platform, as snapped, to the ledge under its top line; the physics relative to the piece)
const ledgeOf = pl => { const y = pl.y - Y0; const n = new Map(); for (let x = pl.x; x < pl.x + pl.w; x++) for (let l = 1; l <= 4; l++) { const o = ledg.ledgeOwner[(y + l) * W + x]; if (o >= 0) n.set(o, (n.get(o) || 0) + 1); } let b = -1, m = 0; for (const [o, k] of n) if (k > m) { m = k; b = o; } return b; };
const platsBy = new Map();
scen.plats.forEach((pl, i) => { if (scen.bbcPlats[i].moving || scen.bbcPlats[i].bouncy) throw new Error(`platform ${i}: moving or bouncy`); const o = ledgeOf(pl); if (o < 0) throw new Error(`platform ${i} at ${pl.x},${pl.y}: no ledge`); (platsBy.get(o) || platsBy.set(o, []).get(o)).push(pl); });
for (const [o, hs] of [...ledgeHalves].sort((a, b) => a[0] - b[0])) {
    const p = cut(ledg, hs);
    p.plats = (platsBy.get(o) || []).map(pl => [pl.x - p.x, pl.y - Y0 - p.y, pl.w]);
    add('ledge', { art: p.art, plats: p.plats }, p.x, p.y);
}
for (const [k, hs] of [...ladHalves].sort((a, b) => a[0] - b[0])) {
    const l = scen.lads[k], p = cut(scen, hs);
    add('ladder', { art: p.art, ladder: [l.x - p.x, l.y - Y0 - p.y, l.h, l.ext] }, p.x, p.y);
}
// ---- Keys and gems (common.json): from their grids, as placed (map coordinates: the picks' less
// the rows above the map), their origin a half's first line, x on a character
const common = {};
for (const name of ['IMG_Key', 'IMG_Gem']) {
    const p = full.picks.find(p => p.name === name), g = full.pickGrids[name], ox = p.left & ~7, oy = (p.top - Y0) & ~3;
    const dx = p.left - ox, dy = p.top - Y0 - oy, rows = [];
    const hh = Math.ceil((dy + g.length) / 4) * 4, ww = Math.ceil((dx + g[0].length) / 8) * 8;
    for (let y = 0; y < hh; y++) { let s = ''; for (let x = 0; x < ww; x++) {
        const gv = g[y - dy]?.[x - dx] ?? -1, v = px(full, ox + x, oy + y);
        s += gv < 0 ? (v === 0 ? '-' : (() => { throw new Error(`${name}: a pixel not its own in its halves`); })()) : gv === 1 && v !== 1 ? 'S' : D[v];
    } rows.push(s); }
    const nm = name === 'IMG_Key' ? 'key' : 'gem';
    common[nm] = { art: rows, pick: nm };
}
for (const p of full.picks) {
    const nm = p.name === 'IMG_Key' ? 'key' : 'gem', dx = nm === 'key' ? 0 : 2, dy = (p.top - Y0) & 3;
    placeList.push([nm, p.left - dx, p.top - Y0 - dy]);
}
// ---- The Scrubbly: its halves (5 characters, from the half its top's in to the one its last line's
// in), as shown, the ledge's line under its feet baked in; its sprite (the body's magenta)
const scrubs = full.placed.map(({ left, top }) => {
    const r0 = top >> 2, r1 = (top + full.SH) >> 2, hs = [];
    for (let hr = r0; hr <= r1; hr++) for (let c = left >> 3; c < (left >> 3) + 5; c++) hs.push([hr, c]);
    return cut(full, hs, (x, y, v) => (full.SCRUB[y - top]?.[x - left] ?? -1) >= 0 ? D[v] : '-');   // (its own pixels only: the ledge's line under its feet hidden while it's there)
});
scrubs.forEach((s, k) => { const d = s.art.reduce((n, r, y) => n + [...r].filter((ch, x) => ch !== scrubs[0].art[y][x]).length, 0); if (d) console.log(`Scrubbly ${k} at ${s.x},${s.y}: ${d} pixels differ from Scrubbly 0 (the ledge under it)`); });
pieces.scrubbly = { art: scrubs[0].art, enemy: 'scrubbly', rows: 'even', sprite: full.SPR.map(r => r.map(v => v ? '#' : '.').join('')) };
for (const s of scrubs) placeList.push(['scrubbly', s.x, s.y]);

const ordered = Object.fromEntries(Object.keys(pieces).sort((a, b) => a.localeCompare(b, 'en', { numeric: true })).map(k => [k, pieces[k]]));
const json = o => JSON.stringify(o, null, 1).replace(/\[\s+([^\[\]{}]*?)\s+\]/g, (m, inner) => inner.includes('"') && inner.length > 60 ? m : '[' + inner.replace(/\s*\n\s*/g, ' ') + ']');
const head = { colours: '- transparent (a half all - is no part of the piece; in one of its halves, background); 0 1 2 3 cyan yellow magenta black (the object); c y m b the same, scenery baked in; S a key\'s yellow from a sprite (background in the characters)' };
writeFileSync(OUT + 'scrubbly.json', json({ ...head, type: 'scrubbly', pieces: ordered }) + '\n');
writeFileSync(OUT + 'common.json', json({ ...head, pieces: common }) + '\n');
const txt = [`# A_1 ("FRAK!"), from the BBC's: pieces as "name x y" (x, y: the piece's top left in the map, pixels and lines)`,
    `type scrubbly`, `size ${NC} ${HS / 8}`, `width ${scen.w}`, `trogg ${scen.trogg[0]} ${scen.trogg[1] - Y0}`, '',
    ...placeList.map(([n, x, y]) => `${n} ${x} ${y}`)];
writeFileSync(OUT + 'A_1.txt', txt.join('\n') + '\n');
console.log(`${Object.keys(pieces).length} pieces (${Object.keys(pieces).filter(k => k.startsWith('ledge')).length} ledges, ${Object.keys(pieces).filter(k => k.startsWith('ladder')).length} ladders, the Scrubbly), ${placeList.length} placed`);
