// A_1 for the C64 demo, from the mock-up's export (../build/level.json, by mockup.mjs): two
// 64-character sets, each character holding a top glyph (rows 0-3, shown from the first FLI
// screen) and a bottom glyph (rows 4-7, from the second); the screen codes (glyph | the half's
// ECM background << 6), row by row, 97 columns. Every cell's foreground is black.
// The character set changes at the forced bad line (line 4 of a row), so a set serves a band:
// band k is row k-1's bottoms and row k's tops (band 0 row 0's tops, band 25 row 24's bottoms).
// The bands are packed into the sets, with the level's yo-yoed-off variant (level_off.json, by
// OFF=1 mockup.mjs) in the same sets, and characters 60-63 of each set kept for the yoyo's string
// (a black line at line 0-3 of both halves).
//   node pack.mjs  ->  ../build: charsets.bin (2 x 512), bandset.bin (26), tops.bin, bottoms.bin,
//                      scrpatch.inc (each Scrubbly's cells knocked off, each gem's and key's picked up,
//                      and STRING)
//                      (25 x 97), level.inc
import { readFileSync, writeFileSync } from 'fs';
const DIR = new URL('../build/', import.meta.url).pathname;
const d = JSON.parse(readFileSync(DIR + 'level.json'));
const { NC, ROWS } = d;
if (d.F.some(f => f !== 3)) throw new Error('a cell whose foreground is not black: colour RAM would have to scroll');
// (the level with the Scrubblies yo-yoed off, mockup.mjs's OFF=1: its glyphs in the same sets, so
// a Scrubbly knocked off is only new screen codes)
const off = JSON.parse(readFileSync(DIR + 'level_off.json'));
if (off.NC !== NC || off.ROWS !== ROWS) throw new Error('level_off.json is another size');
// (and with the gems and keys picked up, mockup.mjs's GONE=1: a gem or key picked up is only new
// screen codes too)
const gone = JSON.parse(readFileSync(DIR + 'level_gone.json'));
if (gone.NC !== NC || gone.ROWS !== ROWS) throw new Error('level_gone.json is another size');
const STRING = 60, CAP = STRING;      // (characters 60-63 of every set: the yoyo's string)
const rowT = [], rowB = [];
for (let r = 0; r < ROWS; r++) {
    rowT.push(new Set([...d.T.slice(r * NC, r * NC + NC), ...off.T.slice(r * NC, r * NC + NC), ...gone.T.slice(r * NC, r * NC + NC)]));
    rowB.push(new Set([...d.B.slice(r * NC, r * NC + NC), ...off.B.slice(r * NC, r * NC + NC), ...gone.B.slice(r * NC, r * NC + NC)]));
}
const bandT = [...rowT, new Set()], bandB = [new Set(), ...rowB];
const sets = [], order = bandT.map((t, k) => k).sort((a, b) => (bandT[b].size + bandB[b].size) - (bandT[a].size + bandB[a].size));
for (const k of order) {
    let s = sets.find(s => new Set([...s.T, ...bandT[k]]).size <= CAP && new Set([...s.B, ...bandB[k]]).size <= CAP);
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
    for (let l = 0; l < 4; l++) {     // (the string's: a line at line l of either half)
        cs[k * 512 + (STRING + l) * 8 + l] = 0xff; cs[k * 512 + (STRING + l) * 8 + 4 + l] = 0xff;
    }
    console.log(`character set ${k}: bands ${s.bands.sort((a, b) => a - b).join(' ')} (${s.T.size} tops, ${s.B.size} bottoms)`);
});
const codes = v => {
    const t = Buffer.alloc(ROWS * NC), b = Buffer.alloc(ROWS * NC);
    for (let r = 0; r < ROWS; r++) for (let c = 0; c < NC; c++) {
        const q = r * NC + c;
        t[q] = sets[bandset[r]].Ti.get(v.T[q]) | v.TB[q] << 6;
        b[q] = sets[bandset[r + 1]].Bi.get(v.B[q]) | v.BB[q] << 6;
    }
    // (checked: each code read back through its band's set gives the glyph and background)
    for (let r = 0; r < ROWS; r++) for (let c = 0; c < NC; c++) {
        const q = r * NC + c, gl = (k, i, h) => [0, 1, 2, 3].map(l => cs[k * 512 + i * 8 + h + l].toString(16).padStart(2, '0')).join('');
        if (gl(bandset[r], t[q] & 63, 0) !== v.T[q] || t[q] >> 6 !== v.TB[q] || gl(bandset[r + 1], b[q] & 63, 4) !== v.B[q] || b[q] >> 6 !== v.BB[q])
            throw new Error(`cell ${c},${r} doesn't read back`);
    }
    return [t, b];
};
const [tops, bottoms] = codes(d), [topsOff, bottomsOff] = codes(off), [topsGone, bottomsGone] = codes(gone);

// Each Scrubbly's patch, knocking it off: the cells that change (a connected group of them for
// each, in the order of scrub.json's placed), as offset in the level map, top code, bottom code
const diff = new Set();
for (let q = 0; q < ROWS * NC; q++) if (tops[q] !== topsOff[q] || bottoms[q] !== bottomsOff[q]) diff.add(q);
const groups = [];
for (const q0 of diff) {
    if (groups.some(g => g.includes(q0))) continue;
    const g = [], stack = [q0];
    while (stack.length) {
        const q = stack.pop(); if (g.includes(q)) continue; g.push(q);
        for (const n of [q - 1, q + 1, q - NC, q + NC, q - NC - 1, q - NC + 1, q + NC - 1, q + NC + 1]) if (diff.has(n) && !g.includes(n)) stack.push(n);
    }
    groups.push(g.sort((a, b) => a - b));
}
const placed = JSON.parse(readFileSync(DIR + 'scrub.json')).placed;
const patches = placed.map(p => {
    const col = (p.x + 8) >> 3, g = groups.find(g => g.some(q => Math.abs(q % NC - col) <= 5 && Math.abs(((q / NC) | 0) - (p.top >> 3)) <= 6));
    if (!g) throw new Error(`no cells for the Scrubbly at ${p.x}`);
    return g;
});
if (patches.flat().length !== diff.size || new Set(patches.flat()).size !== diff.size) throw new Error('the patches and the Scrubblies don\'t match one to one');
// Each gem's and key's patch, picking it up, the same way (in the order of picks.json's picks)
const gdiff = new Set();
for (let q = 0; q < ROWS * NC; q++) if (tops[q] !== topsGone[q] || bottoms[q] !== bottomsGone[q]) gdiff.add(q);
for (const q of gdiff) if (diff.has(q)) throw new Error(`cell ${q % NC},${(q / NC) | 0} is a Scrubbly's and a gem's or key's`);
const picks = JSON.parse(readFileSync(DIR + 'picks.json')).picks;
const ppatches = picks.map(p => [...gdiff].filter(q => { const c = q % NC, y = ((q / NC) | 0) * 8 + 24; return c >= (p.left >> 3) - 1 && c <= (p.left + 22) >> 3 && y + 8 > p.top - 8 && y < p.top + 18; }).sort((a, b) => a - b));
if (ppatches.flat().length !== gdiff.size || new Set(ppatches.flat()).size !== gdiff.size) throw new Error('the patches and the gems and keys don\'t match one to one');
// (one set of cell tables: the Scrubblies' patches, then the gems' and keys'; scrpi, pkpi index it)
const cells = [...patches.flat(), ...ppatches.flat()], ns = patches.flat().length;
const newT = q => gdiff.has(q) ? topsGone[q] : topsOff[q], newB = q => gdiff.has(q) ? bottomsGone[q] : bottomsOff[q];
const starts = (gs, base) => gs.reduce((a, g) => (a.push(a[a.length - 1] + g.length), a), [base]).slice(0, -1);
if (cells.length > 256) throw new Error('more than 256 patch cells');
let inc = `; made by tools/pack.mjs: each Scrubbly's patch knocking it off, then each gem's and key's\n; picking it up (in picks.json's order): cells as level map offset, row, column, new top code,\n; new bottom code\nSTRING = ${STRING}\nNPATCH = ${cells.length}\n`;
inc += `scrpn   .byte ${patches.map(g => g.length).join(', ')}\nscrpi   .byte ${starts(patches, 0).join(', ')}\n`;
inc += `pkpn    .byte ${ppatches.map(g => g.length).join(', ')}\npkpi    .byte ${starts(ppatches, ns).join(', ')}\n`;
inc += `scrplo  .byte ${cells.map(q => q & 255).join(', ')}\nscrphi  .byte ${cells.map(q => q >> 8).join(', ')}\n`;
inc += `scrpr   .byte ${cells.map(q => (q / NC) | 0).join(', ')}\nscrpc   .byte ${cells.map(q => q % NC).join(', ')}\n`;
inc += `scrpt   .byte ${cells.map(newT).join(', ')}\nscrpb   .byte ${cells.map(newB).join(', ')}\n`;
writeFileSync(DIR + 'scrpatch.inc', inc);
console.log(`Scrubbly patches: ${patches.map(g => g.length).join(', ')} cells; gems' and keys': ${ppatches.map(g => g.length).join(', ')}`);
writeFileSync(DIR + 'charsets.bin', cs); writeFileSync(DIR + 'bandset.bin', bandset);
writeFileSync(DIR + 'tops.bin', tops); writeFileSync(DIR + 'bottoms.bin', bottoms);
writeFileSync(DIR + 'level.inc', `NC = ${NC}\nROWS = ${ROWS}\n`);
console.log(`${NC} columns x ${ROWS} rows`);
