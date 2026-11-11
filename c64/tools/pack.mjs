// A_1 for the C64 demo, from the mock-up's export (../build/level.json, by mockup.mjs): two
// 64-character sets, each character holding a top glyph (rows 0-3, shown from the first FLI
// screen) and a bottom glyph (rows 4-7, from the second); the screen codes (glyph | the half's
// ECM background << 6), row by row, 94 columns. Every cell's foreground is black.
// The character set changes at the forced bad line (line 4 of a row), so a set serves a band:
// band k is row k-1's bottoms and row k's tops (band 0 row 0's tops, band 25 row 24's bottoms).
// The bands are packed into the sets.
//   node pack.mjs  ->  ../build: charsets.bin (2 x 512), bandset.bin (26), tops.bin, bottoms.bin
//                      (25 x 94), level.inc
import { readFileSync, writeFileSync } from 'fs';
const DIR = new URL('../build/', import.meta.url).pathname;
const d = JSON.parse(readFileSync(DIR + 'level.json'));
const { NC, ROWS } = d;
if (d.F.some(f => f !== 3)) throw new Error('a cell whose foreground is not black: colour RAM would have to scroll');
const rowT = [], rowB = [];
for (let r = 0; r < ROWS; r++) { rowT.push(new Set(d.T.slice(r * NC, r * NC + NC))); rowB.push(new Set(d.B.slice(r * NC, r * NC + NC))); }
const bandT = [...rowT, new Set()], bandB = [new Set(), ...rowB];
const sets = [], order = bandT.map((t, k) => k).sort((a, b) => (bandT[b].size + bandB[b].size) - (bandT[a].size + bandB[a].size));
for (const k of order) {
    let s = sets.find(s => new Set([...s.T, ...bandT[k]]).size <= 64 && new Set([...s.B, ...bandB[k]]).size <= 64);
    if (!s) sets.push(s = { T: new Set(), B: new Set(), bands: [] });
    bandT[k].forEach(p => s.T.add(p)); bandB[k].forEach(p => s.B.add(p)); s.bands.push(k);
}
if (sets.length > 2) throw new Error(`needs ${sets.length} character sets`);
while (sets.length < 2) sets.push({ T: new Set(), B: new Set(), bands: [] });
const bandset = new Uint8Array(ROWS + 1), cs = Buffer.alloc(1024);
sets.forEach((s, k) => {
    s.Ti = new Map([...s.T].map((p, i) => [p, i])); s.Bi = new Map([...s.B].map((p, i) => [p, i]));
    for (const [p, i] of s.Ti) for (let l = 0; l < 4; l++) cs[k * 512 + i * 8 + l] = parseInt(p.slice(l * 2, l * 2 + 2), 16);
    for (const [p, i] of s.Bi) for (let l = 0; l < 4; l++) cs[k * 512 + i * 8 + 4 + l] = parseInt(p.slice(l * 2, l * 2 + 2), 16);
    for (const b of s.bands) bandset[b] = k;
    console.log(`character set ${k}: bands ${s.bands.sort((a, b) => a - b).join(' ')} (${s.T.size} tops, ${s.B.size} bottoms)`);
});
const tops = Buffer.alloc(ROWS * NC), bottoms = Buffer.alloc(ROWS * NC);
for (let r = 0; r < ROWS; r++) for (let c = 0; c < NC; c++) {
    const q = r * NC + c;
    tops[q] = sets[bandset[r]].Ti.get(d.T[q]) | d.TB[q] << 6;
    bottoms[q] = sets[bandset[r + 1]].Bi.get(d.B[q]) | d.BB[q] << 6;
}
writeFileSync(DIR + 'charsets.bin', cs); writeFileSync(DIR + 'bandset.bin', bandset);
writeFileSync(DIR + 'tops.bin', tops); writeFileSync(DIR + 'bottoms.bin', bottoms);
writeFileSync(DIR + 'level.inc', `NC = ${NC}\nROWS = ${ROWS}\n`);
console.log(`${NC} columns x ${ROWS} rows`);
