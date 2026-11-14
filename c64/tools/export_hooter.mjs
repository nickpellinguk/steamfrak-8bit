// First pass: a classic Hooter level (A_3) from the BBC's, into the level format (../levels):
// hooter.json (the type's pieces) and A_3.txt. Redrawn for ECM's 8x4 halves (black on one
// background each):
//   - girders: 16 lines: 4 black on yellow (a bar), 8 black on the background (red on Hooter
//     levels: the X's arms as outlines, their yellow gone, its holes see-through), 4 black on yellow.
//     The BBC's 12-pixel unit (an X between thin bars, its own black edge on both sides, so units
//     abut with a double line) drawn 16 wide, in the BBC's proportion. A girder of k BBC
//     units centred where it was, an even number of characters nearest 1.5k. girder<N>: N characters
//   - chains (the ladders): a cap (a half, black on yellow) under the girder they hang from, then
//     the BBC's links (8 wide, 14 lines a cycle) stretched to 16 by a hole row more in each link,
//     each half's background whichever of yellow and magenta most of it is (so the links seen
//     edge on magenta, face on yellow, as the BBC's); chain<N>: the cap and N - 1 halves
//   - the Hooter: its black outline in the characters, its magenta and yellow from a multicolour
//     sprite behind (y-expanded: 2x2 blocks) chosen block by block against the BBC's (as the
//     Poglet's); its feet end on a half's last line, a line above the girder it stands on
//   - the level squeezed: the BBC's lines 49-229 (the top girder's and the bottom ones' tops) to
//     the map's 12-184
//   node export_hooter.mjs [room_A_3 A_3]
import { background, images } from '../../cpc6128/tools/emu/render.mjs';
import { readFileSync, writeFileSync } from 'fs';
const LV = new URL('../levels/', import.meta.url).pathname;
const ROOM = process.argv[2] || 'room_A_3', NAME = process.argv[3] || 'A_3', XOFF = 24;
const e = JSON.parse(readFileSync(new URL('../../build/levels.json', import.meta.url)))[ROOM];
const bg = background(ROOM), cols = Math.ceil(e.w / 4), rows = Math.ceil(e.h / 8), BW = cols * 4;
const src = new Uint8Array(BW * rows * 8);
for (let c = 0; c < cols; c++) for (let r = 0; r < rows; r++) { const cell = bg.vert ? bg.cell(r, c) : bg.cell(c, r); if (cell) for (let l = 0; l < 8; l++) for (let i = 0; i < 4; i++) src[(r * 8 + l) * BW + c * 4 + i] = ((cell[l] >> (7 - i)) & 1) << 1 | ((cell[l] >> (3 - i)) & 1); }
const P = (x, y) => src[y * BW + x];
const D = '0123';
const pieces = {}, place = [], chainPlace = [], notes = [];
const [A0, A1, B0, B1] = [49, 229, 12, 184];
const fy = y => B0 + (y - A0) * (B1 - B0) / (A1 - A0), snap4 = v => Math.round(v / 4) * 4;
// ---- Girders: the unit, 8 wide, 16 lines (Y yellow, # black, . hole)
// (16 wide, 2 characters: a bar (4 lines, black on yellow, its last where the X's arms start), the
// X (8 lines, black on the background: its arms' outlines, their yellow gone, the holes
// see-through), a bar; the X's arms from the corners to a 4-wide middle, as the BBC's)
const UNIT = ['################', '#YYYYYYYYYYYYYY#', '#Y############Y#', '##Y##YYYYYY##Y##',
    '.##.##....##.##.', '..##.##..##.##..', '...##.####.##...', '....##....##....',
    '....##....##....', '...##.####.##...', '..##.##..##.##..', '.##.##....##.##.',
    '##Y##YYYYYY##Y##', '#Y############Y#', '#YYYYYYYYYYYYYY#', '################'];
const girderPiece = n => ({ art: UNIT.map(r => [...r].map(c => c === '#' ? '3' : c === 'Y' ? '1' : '0').join('').repeat(n / 2)), plats: [[0, 0, n * 8]] });
// (a girder of k BBC units: 2 characters a unit of 16, as near 12k as an even number of characters gets)
const G = e.plat_x.map((x, k) => {
    const w = e.plat_w[k], u = Math.round(w / 12), n = Math.max(2, 2 * Math.round(0.75 * u)), X = Math.round((x + w / 2 + XOFF - n * 4) / 8) * 8, Y = snap4(fy(e.plat_y[k]));
    const name = `girder${n}`; if (!pieces[name]) pieces[name] = girderPiece(n);
    place.push([name, X, Y]);
    return { x, y: e.plat_y[k], w, X, N: n, Y };
});
// ---- Chains: the BBC's link cycle, from the long chain (rows of it 8 wide)
const ch0 = e.lad_x.findIndex((_, k) => e.lad_h[k] === Math.max(...e.lad_h)), cx0 = e.lad_x[ch0] - 4;
let cyc = null;     // (14 lines repeating, from below the chain's start)
for (let y = e.lad_y[ch0] + 20; y < e.lad_y[ch0] + e.lad_h[ch0] - 28 && !cyc; y++) {
    let ok = true; for (let l = 0; l < 14 && ok; l++) for (let x = 0; x < 8; x++) if (P(cx0 + x, y + l) !== P(cx0 + x, y + l + 14)) ok = false;
    if (ok && [0, 1, 2, 3, 4, 5, 6, 7].some(x => P(cx0 + x, y) === 1) && P(cx0 + 3, y + 4) === 0) cyc = y;     // (from a row the 2-hole rows follow)
}
if (cyc === null) throw new Error('no chain cycle found');
let link = Array.from({ length: 14 }, (_, l) => { let s = ''; for (let x = 0; x < 8; x++) s += '.YM#'[P(cx0 + x, cyc + l)]; return s; });
// (stretched to 16: each run of hole rows one row longer)
const holeRows = link.map((r, l) => r.includes('.') ? l : -1).filter(l => l >= 0);
const firsts = holeRows.filter(l => !holeRows.includes(l - 1));
const L16 = []; link.forEach((r, l) => { L16.push(r); if (firsts.includes(l)) L16.push(r); });
if (L16.length !== 16) throw new Error(`chain cycle stretched to ${L16.length}`);
// (each half's background: whichever of yellow and magenta most of it is; holes and the other colour then that too)
const LINK = []; for (let h = 0; h < 4; h++) { const rs = L16.slice(h * 4, h * 4 + 4), y = rs.join('').split('Y').length, m = rs.join('').split('M').length, b = y >= m ? '1' : '2';
    for (const r of rs) LINK.push([...r].map(c => c === '#' ? '3' : b).join('')); }
const CAP = ['33333333', '31111113', '33111133', '33333333'];
const chainPiece = (n, lad) => ({ art: [...CAP, ...Array.from({ length: (n - 1) * 4 }, (_, l) => LINK[l % 16])], ladder: lad });
const chainAt = [];
e.lad_x.forEach((lx, k) => {
    const ly = e.lad_y[k], lh = e.lad_h[k], ext = e.lad_ext[k];
    const g = G.find(g => g.y === ly - 1 && lx >= g.x - 2 && lx <= g.x + g.w + 2);
    const cx = g ? Math.min(g.X + g.N * 8 - 8, Math.max(g.X, g.X + Math.round((lx - 4 - g.x) / 8) * 8)) : Math.round((lx - 4 + XOFF) / 8) * 8;
    const top = g ? g.Y + 16 : snap4(fy(ly)), bot = Math.min(200, Math.max(top + 8, snap4(fy(ly + lh))));   // (not past the map)
    const n = (bot - top) / 4, h = Math.round(lh * (B1 - B0) / (A1 - A0)), ly2 = g ? g.Y + 1 : top, name = `chain${n}_${h}_${ext}`;
    pieces[name] = chainPiece(n, [4, ly2 - top, h, ext]);
    chainPlace.push([name, cx, top]); chainAt.push({ cx, top, bot });
    if (g && (cx < g.X || cx + 8 > g.X + g.N * 8)) notes.push(`chain ${k} at ${cx}: not under its girder`);
});
// ---- The Hooter: art at the piece's column 2, row 1 (its feet end on the piece's last line)
const HZ = JSON.parse(readFileSync(LV + 'hazards.json')).images.IMG_Hooter, HG = HZ.grid, HH = HG.length;
const PX = 2, PY = 24 - HH;
const art = Array.from({ length: 24 }, (_, y) => { let s = ''; for (let x = 0; x < 24; x++) { const g = HG[y - PY]?.[x - PX]; s += g === undefined || g === '-' ? '-' : g === '3' ? '3' : '0'; } return s; });
const infill = (ox, oy) => {
    const shown = (x, y) => art[y]?.[x] === '3' ? 3 : 0, target = (x, y) => { const g = HG[y - PY]?.[x - PX]; return g === undefined || g === '-' ? 0 : +g; };
    const spr = []; let wrong = 0;
    for (let by = 0; by < 21; by++) { let row = ''; for (let bx = 0; bx < 12; bx++) {
        const cost = { '.': 0, Y: 0, M: 0 };
        for (let dy = 0; dy < 2; dy++) for (let dx = 0; dx < 2; dx++) { const x = ox + bx * 2 + dx, y = oy + by * 2 + dy; if (shown(x, y) === 3) continue; const t = target(x, y); cost['.'] += t !== 0; cost.Y += t !== 1; cost.M += t !== 2; }
        row += Object.keys(cost).reduce((a, b) => cost[b] < cost[a] ? b : a);
    } spr.push(row); }
    for (let y = 0; y < 24; y++) for (let x = 0; x < 24; x++) { if (shown(x, y) === 3) continue; const ch = spr[Math.floor((y - oy) / 2)]?.[Math.floor((x - ox) / 2)] ?? '.'; if ({ '.': 0, Y: 1, M: 2 }[ch] !== target(x, y)) wrong++; }
    return { spr, wrong };
};
let bi = null;
for (let ox = -3; ox <= 2; ox++) for (let oy = -2; oy <= 1; oy++) { const r = infill(ox, oy); if (!bi || r.wrong < bi.wrong) bi = { ...r, ox, oy }; }
notes.push(`Hooter infill: sprite at piece ${bi.ox},${bi.oy}; ${bi.wrong} pixels unlike the BBC's`);
pieces.hooter = { art, enemy: 'hooter', mcsprite: bi.spr, spriteAt: [bi.ox, bi.oy] };
const hootBox = [];
e.draw_img.forEach((i, k) => {
    if (images[i].name !== 'IMG_Hooter') return;
    const dx = e.draw_x[k], dy = e.draw_y[k], left = dx - HZ.xo;
    const g = G.filter(g => dx >= g.x - 4 && dx < g.x + g.w + 4 && g.y >= dy - 2).sort((a, b) => a.y - b.y)[0];
    const y = (g ? g.Y : snap4(fy(dy + 1))) - 24, x = Math.round((left + XOFF - PX) / 8) * 8;
    place.push(['hooter', x, y]); hootBox.push([x, y]);
});
// ---- Keys and gems: on the girder under them, their pieces' last line a line above its top
const hits = (x, y, w) => hootBox.some(([px, py]) => x < px + 24 && x + w > px && y < py + 24 && y + 12 > py);
e.draw_img.forEach((i, k) => {
    const nm = images[i].name === 'IMG_Key' ? 'key' : images[i].name === 'IMG_Gem' ? 'gem' : null; if (!nm) return;
    const dx = e.draw_x[k], dy = e.draw_y[k];
    const g = G.filter(g => dx >= g.x - 4 && dx < g.x + g.w + 4 && g.y >= dy).sort((a, b) => a.y - b.y)[0];
    const x = nm === 'key' ? Math.round((dx - 11 + XOFF) / 8) * 8 : Math.round((dx - 5 + XOFF - 2) / 8) * 8;
    const y = (g ? g.Y : snap4(fy(dy + 1))) - 12, w = nm === 'key' ? 24 : 16;
    const nx = [0, 8, -8, 16, -16].map(d => x + d).find(v => !hits(v, y, w) && (!g || (v + w / 2 >= g.X && v + w / 2 <= g.X + g.N * 8)));
    if (nx === undefined) notes.push(`${nm} at ${x},${y}: on a Hooter, nowhere clear`); else if (nx !== x) notes.push(`${nm} at ${x},${y}: moved ${nx - x} off a Hooter`);
    place.push([nm, nx ?? x, y]);
});
const tg = G.find(g => g.y === e.trogg[1] && e.trogg[0] >= g.x && e.trogg[0] < g.x + g.w) || G.find(g => g.y === e.trogg[1] + 1 && e.trogg[0] >= g.x && e.trogg[0] < g.x + g.w);
const trogg = [e.trogg[0] + XOFF + (tg ? tg.X - (tg.x + XOFF) : 0), tg ? tg.Y - 1 : snap4(fy(e.trogg[1]))];
const sorted = Object.fromEntries(Object.keys(pieces).sort((a, b) => a.localeCompare(b, 'en', { numeric: true })).map(k => [k, pieces[k]]));
const json = o => JSON.stringify(o, null, 1).replace(/\[\s+([^\[\]{}]*?)\s+\]/g, (m, inner) => inner.includes('"') && inner.length > 60 ? m : '[' + inner.replace(/\s*\n\s*/g, ' ') + ']');
writeFileSync(LV + 'hooter.json', json({ background: 'red', colours: '- transparent; 0 1 2 3 background (red) yellow magenta black (the object); c y m b the same, scenery baked in; mcsprite: . clear, Y yellow ($d025), M magenta ($d026), 2x2 blocks', type: 'hooter', pieces: sorted }) + '\n');
const NC = Math.ceil((e.w + XOFF) / 8) + 1;
writeFileSync(LV + `${NAME}.txt`, [`# ${NAME}, first pass from the BBC's ${ROOM}: squeezed (its lines ${A0}-${A1} to the map's ${B0}-${B1}), girders and chains on the 8x4 grid`,
    'type hooter', `size ${NC} 25`, `width ${e.w + XOFF}`, `height ${e.h}`, `trogg ${trogg[0]} ${trogg[1]}`, '',
    ...chainPlace.map(p => p.join(' ')), ...place.map(p => p.join(' '))].join('\n') + '\n');
console.log(notes.join('\n'));
console.log(`${Object.keys(pieces).length} pieces, ${place.length + chainPlace.length} placed`);
