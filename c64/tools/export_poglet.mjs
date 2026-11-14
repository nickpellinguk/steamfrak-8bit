// First pass: a classic Poglet level (A_2) from the BBC's, into the level format (../levels):
// poglet.json (the type's pieces) and A_2.txt. Redrawn for ECM's 8x4 halves (black on one
// background each):
//   - logs: 12 lines, their top line a half's first (so 3 halves); each end the BBC's single black
//     column with background above and below it, in a character of its own (black on cyan), the
//     body between on whole characters (black on magenta): the BBC's first and last 8 columns,
//     and between them a 3-character unit of its grain (the long log's most seamless 24: the
//     grain's 12-pixel period twice) repeated; the stubs under them dropped. log<N>: a body of N
//     characters, N + 2 with its ends
//   - ropes (the ladders): the BBC's black edges only (the yellow core needs a third colour), 4 wide
//     at columns 2-5 of a character, a kink every 16 lines; rope<N>: N halves
//   - the Poglet: its black outline in the characters, its yellow and magenta from a multicolour
//     sprite behind (yellow $d025, magenta $d026, y-expanded: 2x2 blocks), chosen block by block
//     against the BBC's (as infill.mjs). Its feet end on a half's last line, a line above the log
//     it sits on. poglet_rope: the rope baked in behind it, where a Poglet holds one (its rope 9
//     pixels in from its left, as the BBC draws them)
//   - the level squeezed: the BBC's lines 56-224 (the top logs' and the bottom ones' tops) to the
//     map's 36-188, so the Poglets on the top logs and the bottom logs fit the 200 lines
//   node export_poglet.mjs [room_A_2 A_2]
import { background, images } from '../../cpc6128/tools/emu/render.mjs';
import { readFileSync, writeFileSync } from 'fs';
const LV = new URL('../levels/', import.meta.url).pathname;
const ROOM = process.argv[2] || 'room_A_2', NAME = process.argv[3] || 'A_2', XOFF = 24, Y0 = 24;
const e = JSON.parse(readFileSync(new URL('../../build/levels.json', import.meta.url)))[ROOM];
const bg = background(ROOM), cols = Math.ceil(e.w / 4), rows = Math.ceil(e.h / 8), BW = cols * 4;
const src = new Uint8Array(BW * rows * 8);
for (let c = 0; c < cols; c++) for (let r = 0; r < rows; r++) { const cell = bg.vert ? bg.cell(r, c) : bg.cell(c, r); if (cell) for (let l = 0; l < 8; l++) for (let i = 0; i < 4; i++) src[(r * 8 + l) * BW + c * 4 + i] = ((cell[l] >> (7 - i)) & 1) << 1 | ((cell[l] >> (3 - i)) & 1); }
const P = (x, y) => src[y * BW + x];
const D = '0123';
const pieces = {}, place = [], ropePlace = [], notes = [];
// ---- The squeeze: BBC line y to the map's (before snapping)
const [A0, A1, B0, B1] = [56, 224, 36, 188];
const fy = y => B0 + (y - A0) * (B1 - B0) / (A1 - A0), snap4 = v => Math.round(v / 4) * 4;
// ---- Logs
const logs = e.plat_x.map((x, k) => ({ x, y: e.plat_y[k], w: e.plat_w[k] }));
const long = logs.reduce((a, b) => b.w > a.w ? b : a);
const rowsOf = (x0, x1, y) => Array.from({ length: 12 }, (_, l) => { let s = ''; for (let x = x0; x < x1; x++) s += D[P(x, y + l)]; return s; });
// (the BBC's logs: an end column, 2 start columns (magenta, black), 12-pixel units, 2 end columns
// (black, magenta), an end column; the units of 3 kinds, the same edge column on both sides so
// that any follow any: g grain, s grain with a stub hanging under it, k a knot; the rest the same
// with a rope under them. Each kind from the first unit of it found, 16 lines: the log's 12 and
// the stub's 4)
const rows16 = (x0, x1, y) => Array.from({ length: 16 }, (_, l) => { let s = ''; for (let x = x0; x < x1; x++) s += D[P(x, y + l)]; return s; });
const bbcUnits = {}, seqOf = new Map();
for (const g of logs) {
    const seq = [];
    for (let u = g.x + 4; u + 12 <= g.x + g.w - 4; u += 12) {
        const r = rows16(u, u + 12, g.y), stub = r[10].includes('0') || r[11].slice(0, 12).includes('0');
        const k = stub ? 's' : r[2].slice(3, 9) === '333333' ? 'k' : 'g';
        if (!bbcUnits[k] && !r.slice(12).join('').includes('1')) bbcUnits[k] = r;     // (one with nothing under it but its stub)
        seq.push(k);
    }
    seqOf.set(`${g.x},${g.y}`, seq);
}
// (each squeezed to 8 columns: its edge columns kept, the 4 interior columns most like the column
// before them dropped, one at a time)
const squeeze = (r, keep) => {
    let cols = [...Array(r[0].length).keys()];
    while (cols.length > keep) { let bi = -1, bs = 1e9;
        for (let i = 1; i < cols.length - 1; i++) { let d = 0; for (let l = 1; l < 11; l++) d += r[l][cols[i]] !== r[l][cols[i - 1]]; if (d < bs) { bs = d; bi = i; } }
        cols.splice(bi, 1); }
    return r.map(row => cols.map(c => row[c]).join(''));
};
const C8 = Object.fromEntries(Object.entries(bbcUnits).map(([k, r]) => [k, squeeze(r, 8)]));
// (the stub: under the log black on background (its magenta black), and the background in the
// log's last 2 lines, where it breaks off, black: each half 2 colours)
C8.s = C8.s.map((r, l) => l < 10 ? r : l < 12 ? r.replace(/0/g, '3') : r.replace(/2/g, '3').replace(/0/g, '-'));
// (the knot drawn for 8 columns, squeezing loses its middle: as the BBC's, no sides, a dash above
// (6 wide, row 2) and below (row 7) an elongated core (4 x 2, rows 4-5); the edge columns as
// every unit's)
C8.k = ['33333333', '22222222', '23333332', '32222223', '22333322', '32333323', '22222222', '23333332', '33222233', '22333322', '22222222', '33333333',
        '--------', '--------', '--------', '--------'];
for (const k of 'gk') C8[k] = C8[k].map((r, l) => l < 12 ? r : '--------');
notes.push(`log units: grain and stub the BBC's 12 columns squeezed to 8, the knot drawn for 8`);
// (the ends, as the BBC's: a single black column, lines 2-9, background above and below it. On
// the C64 each is a character to itself, the column at its inner edge, so the body, between
// them, starts on a character: the end characters black on cyan, the body black on magenta. The
// body's first character the 2 start columns and a grain squeezed to 6; its last the same mirrored)
const E = long.x; let RE = long.x + long.w - 1; while (![...Array(8)].some((_, l) => P(RE, long.y + 2 + l))) RE--;
const edge = x => Array.from({ length: 16 }, (_, l) => l >= 12 ? '-' : D[P(x, long.y + l)] === '0' ? '-' : '3');
const endL = edge(E).map(c => '-------' + c), endR = edge(RE).map(c => c + '-------');
const g6 = squeeze(bbcUnits.g, 6), st = rows16(E + 1, E + 3, long.y), en = rows16(RE - 2, RE, long.y);
const firstB = st.map((r, l) => l < 12 ? r + g6[l] : '--------'), lastB = en.map((r, l) => l < 12 ? g6[l] + r : '--------');
// (a log's middle characters: the BBC's units, by where each character's middle falls along it;
// a knot or stub only once if its unit covers two; a stub where a rope hangs, grain)
const middle = (g, n, ropeCols) => {
    const seq = seqOf.get(`${g.x},${g.y}`), out = [];
    for (let j = 0; j < n; j++) {
        const f = (j + 0.5) / n, u = Math.min(seq.length - 1, Math.floor(f * seq.length));
        let k = seq.length ? seq[u] : 'g';
        if (k !== 'g' && out.length && out[out.length - 1].u === u) k = 'g';
        if (k === 's' && (ropeCols.has(j) || g.Y + 16 > 200)) k = 'g';     // (nor where it would hang off the map)
        out.push({ k, u });
    }
    return out.map(o => o.k).join('');
};
const logPiece = mid => { const stubs = mid.includes('s'), H = stubs ? 16 : 12, a = [];
    for (let l = 0; l < H; l++) a.push(endL[l] + firstB[l] + [...mid].map(k => C8[k][l]).join('') + lastB[l] + endR[l]);
    return { art: a, plats: [[7, 0, (mid.length + 2) * 8 + 2]] }; };
// (the Poglets always on the same row phase, ROWS: even, their piece's top a multiple of 16, or
// odd, 8 more; so a log a Poglet sits on has its top 36 below that, and every log in the BBC's row
// of one with it. ROWS from the argument, or whichever moves those logs least)
const pogY = []; e.draw_img.forEach((i, k) => { if (images[i].name === 'IMG_Poglet') pogY.push(e.draw_y[k]); });
const carried = new Set(logs.filter(g => pogY.includes(g.y - 1)).map(g => g.y));
const phaseSnap = (v, P) => { const b = Math.round((v - P) / 16) * 16 + P; return b; };
const cost = P => [...carried].reduce((a, y) => a + Math.abs(phaseSnap(fy(y), P) - fy(y)), 0);
const ROWS = process.argv[4] || (cost(4) <= cost(12) ? 'even' : 'odd'), PHASE = ROWS === "even" ? 4 : 12;
notes.push(`Poglets on ${ROWS} rows: the logs they sit on moved ${[...carried].map(y => (phaseSnap(fy(y), PHASE) - fy(y)).toFixed(1)).join(', ')} lines from the squeeze (even ${cost(4).toFixed(1)}, odd ${cost(12).toFixed(1)} in all)`);
const rowOf = y => [...carried].find(c => Math.abs(c - y) <= 2);       // (a log within 2 lines of a Poglet's row goes with it)
const logY = y => rowOf(y) !== undefined ? phaseSnap(fy(rowOf(y)), PHASE) : snap4(fy(y));
const L = logs.map(g => {
    // (its body, between its end columns, to the nearest characters; the piece a character left of it)
    const x0 = Math.round((g.x + 1 + XOFF) / 8) * 8, x1 = Math.round((g.x + g.w - 1 + XOFF) / 8) * 8, n = Math.max(2, (x1 - x0) / 8), y = logY(g.y);
    return { ...g, X: x0, N: n, Y: y, ropes: new Set() };
});
// ---- Ropes: from the bottom of the log they hang from (or their own top) to their end
const ROPE = (() => { const r = []; for (let l = 0; l < 16; l++) r.push(l === 10 || l === 13 ? '--3---3-' : l === 11 || l === 12 ? '---3--3-' : '--3--3--'); return r; })();
const ropePiece = n => ({ art: Array.from({ length: n * 4 }, (_, l) => ROPE[l % 16]) });
const ropeAt = [], pogBox = [];
e.lad_x.forEach((lx, k) => {
    const ly = e.lad_y[k], lh = e.lad_h[k], ext = e.lad_ext[k];
    const g = L.find(g => g.y === ly - 1 && lx >= g.x - 2 && lx <= g.x + g.w + 2);
    // (its x from its place along its log, the log as snapped: so it stays under it)
    const cx = g ? Math.min(g.X + g.N * 8 - 8, Math.max(g.X, g.X + Math.round((lx - 4 - g.x) / 8) * 8)) : Math.round((lx - 2 + XOFF - 2) / 8) * 8;
    const top = g ? g.Y + 12 : snap4(fy(ly)), bot = Math.max(top + 4, snap4(fy(ly + lh)));
    const n = (bot - top) / 4, name = `rope${n}`;
    const h = Math.round(lh * (B1 - B0) / (A1 - A0)), ly2 = g ? g.Y + 1 : top;
    pieces[name + '_' + h + '_' + ext] = { ...ropePiece(n), ladder: [4, ly2 - top, h, ext] };
    ropePlace.push([name + '_' + h + '_' + ext, cx, top]);
    ropeAt.push({ cx, top, bot, lx });
    if (g) g.ropes.add((cx - g.X) / 8 - 1);          // (the middle character it hangs from)
    if (g && (cx + 2 < g.X || cx + 6 > g.X + g.N * 8)) notes.push(`rope ${k} at ${cx}: not under its log (${g.X}-${g.X + g.N * 8})`);
});
// ---- The logs' pieces, now the ropes are known: log_<first, middle, last>
for (const g of L) { const mid = middle(g, Math.max(0, g.N - 2), g.ropes), name = `log_${mid}`;
    if (!pieces[name]) pieces[name] = logPiece(mid);
    place.unshift([name, g.X - 8, g.Y]); }
// ---- The Poglet: art at the piece's column 1, row 3 (its feet end on the piece's last line)
const H = JSON.parse(readFileSync(LV + 'hazards.json')).images.IMG_Poglet, PG0 = H.grid;
// (the C64's Poglet: the BBC's with pixels made black (x, y in its image), each completing an
// infill block that a pixel needing another colour shared)
const BLACK = [[18, 21], [20, 29]];
const PG = PG0.map((r, y) => [...r].map((c, x) => BLACK.some(([bx, by]) => bx === x && by === y) ? '3' : c).join('')), PH = PG.length, PW = PG[0].length;
const PX = 1, PY = 36 - PH, RX = 10;              // (the rope's left, in the piece: columns 2-5 of its second character)
const pogArt = rope => Array.from({ length: 36 }, (_, y) => { let s = ''; for (let x = 0; x < 24; x++) {
    const g = PG[y - PY]?.[x - PX];
    if (g !== undefined && g !== '-') { s += g === '3' ? '3' : '0'; continue; }     // (its own: black, or cyan with the sprite behind)
    if (rope) { const r = ROPE[y % 16][x - RX + 2]; if (x >= RX - 2 && x < RX + 6 && r === '3') { s += 'b'; continue; } }
    s += '-'; } return s; });
// (the infill: 12 x 21 multicolour blocks of 2 x 2, from (OX, OY) in the piece; . clear, Y $d025, M $d026)
const infill = (art, ox, oy) => {
    const shown = (x, y) => { const c = art[y]?.[x]; return c === undefined ? 0 : c === '3' || c === 'b' ? 3 : 0; };
    const target = (x, y) => { const g = PG[y - PY]?.[x - PX]; return g === undefined || g === '-' ? 0 : +g; };
    const spr = []; let wrong = 0;
    for (let by = 0; by < 21; by++) { let row = ''; for (let bx = 0; bx < 12; bx++) {
        const cost = { '.': 0, Y: 0, M: 0 };
        for (let dy = 0; dy < 2; dy++) for (let dx = 0; dx < 2; dx++) { const x = ox + bx * 2 + dx, y = oy + by * 2 + dy; if (shown(x, y) === 3) continue; const t = target(x, y); cost['.'] += t !== 0; cost.Y += t !== 1; cost.M += t !== 2; }
        const k = Object.keys(cost).reduce((a, b) => cost[b] < cost[a] ? b : a); row += k;
    } spr.push(row); }
    // (what's wrong, over every pixel of the piece: those the sprite doesn't reach count too)
    for (let y = 0; y < art.length; y++) for (let x = 0; x < art[0].length; x++) { if (shown(x, y) === 3) continue;
        const bx = Math.floor((x - ox) / 2), by = Math.floor((y - oy) / 2), ch = spr[by]?.[bx] ?? '.';
        if ({ '.': 0, Y: 1, M: 2 }[ch] !== target(x, y)) wrong++; }
    return { spr, wrong };
};
const pa = pogArt(false);
let bi = null;
for (let ox = -3; ox <= 2; ox++) for (let oy = PY - 3; oy <= PY + 1; oy++) { const r = infill(pa, ox, oy); if (!bi || r.wrong < bi.wrong) bi = { ...r, ox, oy }; }
notes.push(`Poglet infill: sprite at piece ${bi.ox},${bi.oy}; ${bi.wrong} pixels unlike the BBC's`);
const pogPieces = () => { pieces.poglet = { art: pa, enemy: 'poglet', rows: ROWS, mcsprite: bi.spr, spriteAt: [bi.ox, bi.oy] };
    pieces.poglet_rope = { art: pogArt(true), enemy: 'poglet', rows: ROWS, mcsprite: bi.spr, spriteAt: [bi.ox, bi.oy] }; };
e.draw_img.forEach((i, k) => {
    if (images[i].name !== 'IMG_Poglet') return;
    const dx = e.draw_x[k], dy = e.draw_y[k];
    const g = L.find(g => g.y === dy + 1 && dx >= g.x && dx < g.x + g.w);
    const r = ropeAt.find(r => Math.abs(r.lx - dx) <= 4 && r.top < fy(dy) && r.bot > fy(dy - 32));   // (a rope through its height)
    const y = g ? g.Y - 36 : phaseSnap(fy(dy + 1) - 36, PHASE - 4);
    const x = r ? r.cx - 8 : Math.round((dx - 11 + XOFF - PX) / 8) * 8;
    place.push([r ? 'poglet_rope' : 'poglet', x, y]); pogBox.push([x, y]);
});
// ---- Keys and gems (common.json): on the log under them, their pieces' last line a line above its top
const picks = [], hitsPog = (x, y, w) => pogBox.some(([px, py]) => x < px + 24 && x + w > px && y < py + 36 && y + 12 > py);
e.draw_img.forEach((i, k) => {
    const nm = images[i].name === 'IMG_Key' ? 'key' : images[i].name === 'IMG_Gem' ? 'gem' : null; if (!nm) return;
    const dx = e.draw_x[k], dy = e.draw_y[k];
    const g = L.filter(g => dx >= g.x - 4 && dx < g.x + g.w + 4 && g.y >= dy).sort((a, b) => a.y - b.y)[0];
    const x = nm === 'key' ? Math.round((dx - 11 + XOFF) / 8) * 8 : Math.round((dx - 5 + XOFF - 2) / 8) * 8;
    const y = (g ? g.Y : snap4(fy(dy + 1))) - 12, w = nm === 'key' ? 24 : 16;
    // (not on a Poglet's cells: along its log a character at a time, while still over it)
    const nx = [0, 8, -8, 16, -16].map(d => x + d).find(v => !hitsPog(v, y, w) && (!g || (v + w / 2 >= g.X && v + w / 2 <= g.X + g.N * 8)));
    if (nx === undefined) notes.push(`${nm} at ${x},${y}: on a Poglet, nowhere clear along its log`); else if (nx !== x) notes.push(`${nm} at ${x},${y}: moved ${nx - x} off a Poglet`);
    place.push([nm, nx ?? x, y]);
});
// ---- Trogg: on the log under him
const tg = L.find(g => g.y === e.trogg[1] + 1 && e.trogg[0] >= g.x && e.trogg[0] < g.x + g.w);
const trogg = [e.trogg[0] + XOFF + (tg ? tg.X - (tg.x + XOFF) : 0), (tg ? tg.Y - 1 : snap4(fy(e.trogg[1]))) ];
pogPieces();
const sorted = Object.fromEntries(Object.keys(pieces).sort((a, b) => a.localeCompare(b, 'en', { numeric: true })).map(k => [k, pieces[k]]));
const json = o => JSON.stringify(o, null, 1).replace(/\[\s+([^\[\]{}]*?)\s+\]/g, (m, inner) => inner.includes('"') && inner.length > 60 ? m : '[' + inner.replace(/\s*\n\s*/g, ' ') + ']');
writeFileSync(LV + 'poglet.json', json({ background: 'green', colours: '- transparent; 0 1 2 3 background (green) yellow magenta black (the object); c y m b the same, scenery baked in; mcsprite: . clear, Y yellow ($d025), M magenta ($d026), 2x2 blocks', type: 'poglet', pieces: sorted }) + '\n');
const NC = Math.ceil((e.w + XOFF) / 8) + 1;
writeFileSync(LV + `${NAME}.txt`, [`# ${NAME}, first pass from the BBC's ${ROOM}: squeezed (its lines 56-224 to the map's 36-188), logs and ropes on the 8x4 grid`,
    'type poglet', `size ${NC} 25`, `width ${e.w + XOFF}`, `height ${e.h}`, `trogg ${trogg[0]} ${trogg[1]}`, '',
    ...ropePlace.map(p => p.join(' ')), ...place.map(p => p.join(' '))].join('\n') + '\n');
console.log(notes.join('\n'));
console.log(`${Object.keys(pieces).length} pieces, ${place.length} placed`);
