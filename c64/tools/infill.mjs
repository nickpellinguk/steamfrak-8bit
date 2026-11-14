// The Scrubbly's infill: its magenta body as a hi-res sprite, expanded both ways (24 x 21 blocks of
// 2 x 2 pixels), behind the characters: it shows wherever a character pixel is background (any
// ECM background), never through black. Each block chosen alone, on or off, whichever gets more of
// its visible pixels right against the BBC Scrubbly (levels/hazards.json): on, its background
// pixels show magenta; off, their own background colour (cyan, or yellow in the eyes' and teeth's
// halves). Black pixels hide the sprite either way, so they don't count.
// The sprite's top left at the piece's (OX, OY): 8 pixels left of it, a line down (the BBC grid's
// first row is the piece's second); written into levels/<type>.json's enemy piece.
//   node infill.mjs [scrubbly [piece]]
import { readFileSync, writeFileSync } from 'fs';
const LV = new URL('../levels/', import.meta.url).pathname;
const TYPE = process.argv[2] || 'scrubbly', NAME = process.argv[3] || 'scrubbly', OX = -8, OY = 1, GY = 1;
const file = `${LV}${TYPE}.json`, src = readFileSync(file, 'utf8'), d = JSON.parse(src);
const art = d.pieces[NAME].art, H = art.length, W = art[0].length;
const T = JSON.parse(readFileSync(LV + 'hazards.json')).images.IMG_Scrubbly.grid;
const COL = { '-': 0, S: 0, 0: 0, 1: 1, 2: 2, 3: 3, c: 0, y: 1, m: 2, b: 3 };
// (the characters as shown: black, else the half's background)
const shown = art.map(r => [...r].map(() => 0));
for (let i = 0; i < H / 4; i++) for (let j = 0; j < W / 8; j++) {
    const bg = new Set(); for (let y = 0; y < 4; y++) for (let x = 0; x < 8; x++) { const c = COL[art[i * 4 + y][j * 8 + x]]; if (c !== 3) bg.add(c); }
    const b = bg.size ? [...bg][0] : 0;
    for (let y = 0; y < 4; y++) for (let x = 0; x < 8; x++) shown[i * 4 + y][j * 8 + x] = COL[art[i * 4 + y][j * 8 + x]] === 3 ? 3 : b;
}
const target = (x, y) => { const ch = T[y - GY]?.[x]; return ch === undefined || ch === '-' ? 0 : +ch; };
const spr = [];
let wrong = 0;
for (let by = 0; by < 21; by++) { let row = ''; for (let bx = 0; bx < 24; bx++) {
    let on = 0, off = 0;
    for (let dy = 0; dy < 2; dy++) for (let dx = 0; dx < 2; dx++) {
        const x = OX + bx * 2 + dx, y = OY + by * 2 + dy, s = x >= 0 && x < W && y >= 0 && y < H ? shown[y][x] : 0;
        if (s === 3) continue;
        const t = x >= 0 && x < W && y >= 0 && y < H ? target(x, y) : 0;
        on += t !== 2; off += s !== t;
    }
    row += on < off ? '#' : '.'; wrong += Math.min(on, off);
} spr.push(row); }
// (what's still wrong, by kind: the BBC colour and what shows)
const kinds = {};
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    let s = shown[y][x]; const bx = (x - OX) >> 1, by = (y - OY) >> 1;
    if (s !== 3 && spr[by]?.[bx] === '#') s = 2;
    const t = target(x, y); if (s !== t) { const k = `${'cymb'[t]} shown ${'cymb'[s]}`; kinds[k] = (kinds[k] || 0) + 1; }
}
const old = d.pieces[NAME].sprite;
// (the file's layout kept: the old rows swapped for the new, in order)
let out = src; old.forEach((r, k) => { out = out.replace(`"${r}"`, `"@@${k}@@"`); }); spr.forEach((r, k) => { out = out.replace(`"@@${k}@@"`, `"${r}"`); });
if (JSON.stringify(JSON.parse(out).pieces[NAME].sprite) !== JSON.stringify(spr)) throw new Error('the sprite didn\'t go in');
writeFileSync(file, out);
console.log(`${TYPE}.json ${NAME}: sprite written, ${old.reduce((n, r, k) => n + [...r].filter((c, i) => c !== spr[k][i]).length, 0)} blocks changed; pixels still unlike the BBC's: ${JSON.stringify(kinds)}`);
