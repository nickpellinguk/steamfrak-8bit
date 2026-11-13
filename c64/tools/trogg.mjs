// Trogg as C64 sprites: every frame as two hardware sprites, a hi-res outline (black, in front)
// and a multicolour infill behind it (yellow and magenta, the shared multicolour registers, at
// double-width pixels), 24 wide. The standing and walking frames are 26 wide: their snout (lines
// 3-5) and back (lines 17-24) at opposite ends, so the head and the body are cut with different
// windows, 2 apart (cut1 for lines 0-16, toward the snout; cut2 for lines 6-33), and his sprites'
// x moves the 2 pixels partway down him, from somewhere in his lines 7-14 (trogg.asm).
//
// Trogg is 34 lines high, a sprite 21, so each sprite is used twice down the screen: its first
// instance from block P1 (Trogg's lines 0-20), its second (Y + 21) from block P2 (rows 0-12:
// lines 21-33). The pointer changes from P1 to P2 somewhere in his lines 13-20 (a row's tick
// always falls there): P2's rows 13-20 repeat lines 13-20, so the change can't be seen wherever
// it falls. But the second instance shows all 21 rows, so P2's rows 13-20 would show again below
// his feet: the pointer changes again, to P3 (P2's rows 0-12, then blank), somewhere in his lines
// 21-33 (the next row's tick always falls there). Checked here by drawing every frame as the VIC
// would, all 42 lines of the two instances, with the changes at each of those lines.
//
//   node trogg.mjs    (needs ../../cpc6128/build, see ../build.sh)
// writes, in ../build: trogg.png (each frame: the BBC original, the outline, the infill, the two
// together, what differs), trogg.txt (each frame's sprites as text), trogg.bin (the sprite
// blocks: per frame outline P1, P2, P3, infill P1, P2, P3, 64 bytes each) and trogg.json (the
// frames: name, x offset of the sprites' left edge from Trogg's x, block numbers, and the frame as
// shown, for checking screenshots)
import { refPlot, images, at } from '../../cpc6128/tools/emu/render.mjs';
import { writeFileSync, mkdirSync } from 'fs';
import { deflateSync } from 'zlib';

const OUT = new URL('../build', import.meta.url).pathname;
mkdirSync(OUT, { recursive: true });

// An image's pixels (-1 transparent, 0 background, 1 yellow, 2 magenta, 3 black)
function pixels(name) {
    const i = images.findIndex(m => m.name === name), im = images[i];
    const on = fill => { const b = Buffer.alloc(0x4000, fill); refPlot(b, 0, { l: 0, r: 64, t: 0, h: 0 }, i, 32 + im.xo, 64 + im.yo); return b; };
    const a = on(0), z = on(0xff);
    const px = (b, x, y) => { const v = b[at(0, (32 + x) >> 2, 64 + y)], k = (32 + x) & 3; return ((v >> (7 - k)) & 1) << 1 | ((v >> (3 - k)) & 1); };
    const g = [];
    for (let y = 0; y < im.h; y++) { const r = []; for (let x = 0; x < im.w; x++) { const p = px(a, x, y); r.push(p === px(z, x, y) ? p : -1); } g.push(r); }
    return { g, xo: im.xo, w: im.w, h: im.h };
}

// The frames: climbing and the yo-yo as they are; standing and walking a body over legs (the
// standing frame is walking frame 0)
const frames = [];
for (const n of ['cd_0', 'cd_1', 'cn', 'cu_0', 'cu_1', 'yl', 'yr']) frames.push({ name: 'Trogg_' + n, ...pixels('IMG_Trogg_' + n) });
for (const side of 'rl') {
    const body = pixels('IMG_TroggBody_' + side);
    for (let f = 0; f < 4; f++) {
        const legs = pixels(`IMG_TroggLegs_${side}_${f}`);
        frames.push({ name: `Trogg_w${side}_${f}${f ? '' : ' (and s' + side + ')'}`, g: [...body.g, ...legs.g], xo: body.xo, w: body.w, h: 34 });
    }
}

// Each frame to 24 columns, then the two sprites: the head's window cut1, the body's cut2 (the
// same but for the 26-wide frames: facing right, the snout's end of the frame first, then the
// back's)
const W = 24, H = 34;
const out = [], blocks = [];
let lostAll = 0;
for (const fr of frames) {
    const wide = fr.w > W, right = !/w[l]_|_sl/.test(fr.name);
    const cut1 = wide ? (right ? fr.w - W : 0) : Math.floor((fr.w - W) / 2), cut2 = wide ? (right ? 0 : fr.w - W) : cut1;
    // (sprite column x shows the frame's column x + cut; its left edge is Trogg's x - (xo - cut))
    const at = cut => (x, y) => (fr.g[y] && fr.g[y][x + cut] !== undefined) ? fr.g[y][x + cut] : -1;
    let lost = 0;
    for (let y = 0; y < H; y++) for (let x = 0; x < fr.w; x++) if (fr.g[y][x] >= 0) {
        const fits = c => x - c >= 0 && x - c < W;
        if (!(y < 6 ? fits(cut1) : y > 16 ? fits(cut2) : fits(cut1) && fits(cut2))) lost++;
    }
    lostAll += lost;
    let clash = 0, leak = 0;
    const sprites = (cut, count) => {
        const at2 = at(cut), outline = [], infill = [];
        for (let y = 0; y < H; y++) {
            const o = [], f = [];
            for (let x = 0; x < W; x++) o.push(at2(x, y) === 3 ? 1 : 0);
            for (let x = 0; x < W; x += 2) {
                const a = at2(x, y), b = at2(x + 1, y);
                const cols = [a, b].filter(p => p === 1 || p === 2);
                let c = 0;                                          // (0 clear, 1 yellow, 2 magenta)
                if (cols.length) {
                    c = cols[0];
                    if (count && cols.length === 2 && cols[0] !== cols[1]) clash++;
                    // (a pixel of the pair outside Trogg would show the colour round him)
                    if (count && (a < 0 || b < 0)) leak++;
                }
                f.push(c);
            }
            outline.push(o); infill.push(f);
        }
        return { outline, infill };
    };
    const s1 = sprites(cut1, false), s2 = sprites(cut2, true);     // (the pairs counted once: the body's window)
    // the blocks: 21 rows of 3 bytes, and a spare
    const block = (rows, enc) => { const b = Buffer.alloc(64); rows.forEach((r, y) => { const bytes = enc(r); for (let k = 0; k < 3; k++) b[y * 3 + k] = bytes[k]; }); return b; };
    const hires = r => [0, 1, 2].map(k => r.slice(k * 8, k * 8 + 8).reduce((v, p) => v << 1 | p, 0));
    const MC = [0b00, 0b01, 0b11];                              // (clear; yellow: $d025; magenta: $d026)
    const multi = r => [0, 1, 2].map(k => r.slice(k * 4, k * 4 + 4).reduce((v, c) => v << 2 | MC[c], 0));
    const blank = rows => rows[0].map(() => 0);
    const p1 = rows => rows.slice(0, 21), p2 = rows => [...rows.slice(21, 34), ...rows.slice(13, 21)];
    const p3 = rows => [...rows.slice(21, 34), ...Array(8).fill(blank(rows))];
    // (per sprite: P1 the head's window; P1b, the same lines in the body's, from the x's move; P2,
    // P3 the body's)
    const base = blocks.length;
    blocks.push(block(p1(s1.outline), hires), block(p1(s2.outline), hires), block(p2(s2.outline), hires), block(p3(s2.outline), hires),
        block(p1(s1.infill), multi), block(p1(s2.infill), multi), block(p2(s2.infill), multi), block(p3(s2.infill), multi));
    // drawn as the VIC would, the two instances' 42 lines, in the frame's columns: the pointer to
    // P1b and the x moved at line m, the pointer to P2 at line s, to P3 at line t
    const FW = Math.max(W, fr.w);
    const draw = (m, s, t) => {
        const img = [];
        for (let y = 0; y < 42; y++) {
            const row = y < 21 ? y : y - 21, blk = y < m ? 0 : y < s ? 1 : y < t ? 2 : 3, cut = y < m ? cut1 : cut2;
            const o = blocks[base + blk], f = blocks[base + 4 + blk], r = Array(FW).fill(-1);
            for (let x = 0; x < W; x++) {
                const X = x + cut;
                if ((o[row * 3 + (x >> 3)] >> (7 - (x & 7))) & 1) { r[X] = 3; continue; }
                const xx = x >> 1, mm = (f[row * 3 + (xx >> 2)] >> (6 - 2 * (xx & 3))) & 3;
                r[X] = mm === 0b01 ? 1 : mm === 0b11 ? 2 : -1;
            }
            img.push(r);
        }
        return img;
    };
    // (the x's move in the tick before P2's: from his lines 7-14, P2 6 lines on; checked over his
    // lines 6-14 against every P2 and P3)
    const all = draw(8, 16, 24);
    for (let y = 34; y < 42; y++) if (all[y].some(p => p >= 0)) throw new Error(`${fr.name}: something shows below his feet`);
    for (let m = 6; m <= 14; m++) for (let s = Math.max(m, 13); s <= 21; s++) for (let t = 21; t <= 34; t++) {
        if (JSON.stringify(draw(m, s, t)) !== JSON.stringify(all)) throw new Error(`${fr.name}: the x moved at line ${m}, the pointer changes at lines ${s} and ${t} show`);
    }
    // (shown: in the frame's columns, its left edge Trogg's x - xo)
    const shown = all.slice(0, H);
    let differ = 0;
    for (let y = 0; y < H; y++) for (let x = 0; x < FW; x++) if (shown[y][x] !== (fr.g[y][x] ?? -1)) differ++;
    out.push({ ...fr, cut: cut1, cut1, cut2, lost, clash, leak, differ, outline: s1.outline, infill: s1.infill, shown, at2: at(cut1), base });
}

// ---- The report, the data
const T = [];
for (const f of out) {
    T.push(`; ${f.name}: sprites' left edge ${f.xo - f.cut1} left of Trogg's x (from his line 6-16, ${f.xo - f.cut2}); ${f.lost} pixels cut off, ` +
        `${f.clash} pixel pairs wanting both yellow and magenta, ${f.differ - f.lost < 0 ? 0 : f.differ} pixels differ in all`);
    T.push(';   outline (# black)            infill (Y yellow, M magenta, double width)');
    for (let y = 0; y < H; y++) T.push(`${String(y).padStart(3)} ${f.outline[y].map(p => p ? '#' : '.').join('')}   ${f.infill[y].map(c => '.YM'[c].repeat(2)).join('')}`);
    T.push('');
    console.log(`${f.name.padEnd(22)} left ${String(f.xo - f.cut1).padStart(2)}${f.cut1 !== f.cut2 ? ' then ' + String(f.xo - f.cut2).padStart(2) : '        '}: cut off ${f.lost}, yellow/magenta pairs ${f.clash}, colour outside ${f.leak}, differ ${f.differ}`);
}
writeFileSync(`${OUT}/trogg.txt`, T.join('\n'));
// (the blocks once each: frames share many; tblk, each frame's eight blocks, outline P1, P1b, P2,
// P3, infill likewise; trdx, the x's move partway down him)
const uniq = [], key = new Map(), blk = blocks.map(b => { const k = b.toString('hex'); if (!key.has(k)) { key.set(k, uniq.length); uniq.push(b); } return key.get(k); });
writeFileSync(`${OUT}/trogg.bin`, Buffer.concat(uniq));
writeFileSync(`${OUT}/trogg.inc`, `; made by tools/trogg.mjs: Trogg's frames (each 8 sprite blocks in trogg.bin): ${out.map((f, k) => `${k} ${f.name}`).join(', ')}\n` +
    `TFRAMES = ${out.length}\ntrleft  .byte ${out.map(f => f.xo - f.cut1).join(', ')}       ; (the sprites' left edge, left of his x)\n` +
    `trdx    .byte ${out.map(f => (f.cut2 - f.cut1) & 255).join(', ')}       ; (and its move partway down him)\n` +
    `tblk    .byte ${blk.map(b => `TROGGP + ${b}`).join(', ')}\n`);
writeFileSync(`${OUT}/trogg.json`, JSON.stringify(out.map(f => ({ name: f.name, left: f.xo, outline: blk.slice(f.base, f.base + 4), infill: blk.slice(f.base + 4, f.base + 8), shown: f.shown })), null, 1));
console.log(`${out.length} frames, ${blocks.length} blocks, ${uniq.length} different (${uniq.length * 64} bytes); ${lostAll} pixels cut off in all; every x move (lines 6-14) and pair of pointer changes (13-21, 21-34) checked, nothing below his feet`);

// ---- The picture: per frame, BBC original | outline | infill | together | differences, 6x
const S = 6, GAP = 2, PW = 26, CW = (PW + GAP) * 5 + 6, CH = H + 4, PER = 5;
const pal = { '-1': [0, 200, 200], 0: [0, 200, 200], 1: [255, 255, 0], 2: [255, 0, 255], 3: [0, 0, 0] };
const rowsN = Math.ceil(out.length / PER), IW = PER * CW * S, IH = rowsN * CH * S;
const raw = Buffer.alloc((IW * 3 + 1) * IH, 60);
for (let y = 0; y < IH; y++) raw[y * (IW * 3 + 1)] = 0;
const put = (X, Y, c) => { for (let dy = 0; dy < S; dy++) for (let dx = 0; dx < S; dx++) raw.set(c, (Y * S + dy) * (IW * 3 + 1) + 1 + (X * S + dx) * 3); };
out.forEach((f, k) => {
    const ox = (k % PER) * CW, oy = Math.floor(k / PER) * CH + 2;
    for (let y = 0; y < H; y++) {
        for (let x = 0; x < PW; x++) put(ox + x, oy + y, pal[x < f.w ? f.g[y][x] : -1]);
        for (let x = 0; x < W; x++) {
            put(ox + (PW + GAP) + x + 1, oy + y, f.outline[y][x] ? [0, 0, 0] : [0, 200, 200]);
            put(ox + 2 * (PW + GAP) + x + 1, oy + y, pal[[-1, 1, 2][f.infill[y][x >> 1]]]);
        }
        for (let x = 0; x < f.shown[y].length && x < PW; x++) {             // (together, and what differs: the frame's columns)
            put(ox + 3 * (PW + GAP) + x, oy + y, pal[f.shown[y][x]]);
            const d = f.shown[y][x] !== (f.g[y][x] ?? -1);
            put(ox + 4 * (PW + GAP) + x, oy + y, d ? [255, 0, 0] : pal[f.shown[y][x]].map(v => (v + 2 * 200) / 3 | 0));
        }
    }
});
const crcT = Array.from({ length: 256 }, (_, n) => { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c >>> 0; });
const crc = b => { let c = 0xffffffff; for (const x of b) c = crcT[(c ^ x) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
const chunk = (t, d) => { const l = Buffer.alloc(4); l.writeUInt32BE(d.length); const td = Buffer.concat([Buffer.from(t), d]); const c = Buffer.alloc(4); c.writeUInt32BE(crc(td)); return Buffer.concat([l, td, c]); };
const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(IW, 0); ihdr.writeUInt32BE(IH, 4); ihdr[8] = 8; ihdr[9] = 2;
writeFileSync(`${OUT}/trogg.png`, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
