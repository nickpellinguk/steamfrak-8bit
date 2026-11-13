// Assembles the demo (../build/frak64.prg, for a real C64 or an emulator with its ROMs) with
// 64tass, and the stand-in ROMs for testing it in a VICE without Commodore's (basic.rom,
// kernal.rom, chargen.rom); with --run, runs VICE (x64sc, headless) and takes a screenshot.
// TS (cycles from the stable raster to starting the row timer) is found by sweeping it in VICE
// with compare.py: the earliest that works. --measure, --hist and --test build the demo's
// MEASURE, HIST and TEST versions (see ../src/frak64.asm); --jm sets the slide's constant (the
// smallest skip, 2, when the interrupt is taken at once); --probemask measures a mask of sprites.
//   node build.mjs [--ts N] [--measure] [--hist] [--test SEED] [--probemask M --d D] [--nopack]
//                  [--run] [--cycles N] [--shot file.png]
import { execFileSync } from 'child_process';
import { readFileSync, writeFileSync, existsSync, unlinkSync } from 'fs';
const DIR = new URL('../build/', import.meta.url).pathname, SRC = new URL('../src/', import.meta.url).pathname;
const TOOLS = new URL('.', import.meta.url).pathname;
const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i < 0 ? d : process.argv[i + 1]; };
// a delay of n cycles as a dey loop (5k+1 cycles), nops (2) and a bit zp (3)
function split(n) {
    for (let k = Math.floor((n - 1) / 5); k >= 0; k--) {
        let r = k ? n - (5 * k + 1) : n;
        if (r < 0 || r === 1) continue;
        const b = r & 1; r -= 3 * b; if (r < 0) continue;
        return { K: k, N: r / 2, B: b };
    }
    throw new Error(`no delay of ${n}`);
}
export const PARAMS = { TS: +arg('ts', 98) };
const defs = [];
for (const [name, n] of Object.entries(PARAMS)) {
    const s = split(n);
    if (s.N < 0) throw new Error(`no delay of ${n}`);
    defs.push('-D', `${name}K=${s.K}`, '-D', `${name}N=${s.N}`, '-D', `${name}B=${s.B}`);
}
defs.push('-D', `MEASURE=${process.argv.includes('--measure') ? 1 : 0}`, '-D', `HIST=${process.argv.includes('--hist') ? 1 : 0}`);

// ---- Sprite fetches and the row interrupt. The VIC fetches the sprites shown on a line at the
// end of the line before (sprites 0-2: their first s-access on cycle 58, 60, 62) and the start
// of the line (3-7: cycles 1, 3, 5, 7, 9), holding BA low from 3 cycles before each sprite's
// first s-access to its last; the CPU stops at its next read while it's low. The row interrupt
// reads the timer in line 2 and from then on only reads until its $d018 write, through line 3's
// fetches, so they cost it the cycles BA is low (counting from line 3's cycle 0: sprite n's first
// s-access on -5, -3, -1, 1, 3 ... 9); its slide skips that many more (maskjm). From the $d018
// write on line 3's cycle 55, the tail only reads (a delay of d cycles, then sta $d011's three
// reads) through line 4's fetches (58, 60, 62, then line 4's 1-9: 64 ... 72) to the $d011 write,
// which must land on line 4's cycle W (14; or W + 1 where nothing reaches W: a character more of
// the FLI bug, under the cover sprite). Sprite 0, the cover, is always shown.
const PA = [-5, -3, -1, 1, 3, 5, 7, 9], PB = [58, 60, 62, 64, 66, 68, 70, 72];
const lowAt = P => (m, t) => P.some((p, n) => (m >> n & 1) && t >= p - 3 && t <= p + 1);
const lowA = lowAt(PA), lowB = lowAt(PB);
let stallA = m => { let c = 0; for (let t = -20; t < 20; t++) if (lowA(m, t)) c++; return c; };
const writeAt = (m, d) => { let t = 56, r = d + 3; while (r > 0) { if (!lowB(m, t)) r--; t++; } return t - 63; };
const W = +arg('w', 14), JM0 = +arg('jm', 4), COVER = 1;
const tailFor = [], jmFor = [];
for (let m = 0; m < 256; m++) {
    let d = -1;
    for (const want of [W, W + 1]) { for (let k = 0; k <= 30 && d < 0; k++) if (k !== 1 && writeAt(m | COVER, k) === want) d = k; if (d >= 0) break; }
    if (d < 0) throw new Error(`no tail for sprites ${m.toString(2)}`);
    tailFor.push(d);
    jmFor.push(JM0 + stallA(m | COVER) - stallA(COVER));
}
// --probemask M --d D: sprites M (1-7), expanded, on rows 3-8 (lines 3 and 4 alike), every row's
// tail D cycles long: where the garbage lands then (tools/garbage.py) says how late the write is
const PM = arg('probemask', null), PD = +arg('d', 0);
if (PM !== null) tailFor.fill(PD);
const delays = [...new Set(tailFor)].sort((a, b) => a - b);
const delayCode = d => { const out = []; let r = d; if (r & 1) { out.push('bit $ea'); r -= 3; } while (r > 0) { out.push('nop'); r -= 2; } return out; };
let inc = '; made by tools/build.mjs: for each mask of sprites shown (0, the cover, always), the row\n; interrupt\'s tail (line 4\'s fetches) and its slide\'s constant (line 3\'s); the tails\n';
// Every mask has bit 0 (the cover) set, so only the odd entries are ever read: each pair of tables
// shares one block, interleaved (masktl's at the even bytes, read as masktl = block - 1; maskth's
// at the odd, maskth = block); maskjm's even bytes are spare
const pair = (a, b, fa, fb) => `${b}  .byte ` + tailFor.flatMap((d, m) => m & 1 ? [] : [fa(m + 1), fb(m + 1)]).join(', ') + `\n${a} = ${b} - 1\n`;
inc += pair('masktl', 'maskth', m => `<tail${tailFor[m]}`, m => `>tail${tailFor[m]}`);
// (the same tails, then Trogg's second instances (a: y + 21 and P2) or third blocks (b: P3), for
// the rows whose ticks change his sprites)
for (const v of 'ab') inc += pair(`masktl${v}`, `maskth${v}`, m => `<tail${tailFor[m]}${v}`, m => `>tail${tailFor[m]}${v}`);
inc += 'maskjm  .byte ' + jmFor.filter((j, m) => m & 1).map(j => `0, ${j}`).join(', ') + '\n';
for (const [v, to] of [['', 'tailend'], ['a', 'trogga'], ['b', 'troggb']])
    for (const d of delays) inc += `tail${d}${v}  stx $d018\n` + delayCode(d).map(c => `        ${c}\n`).join('') + `        sta $d011\n        jmp ${to}\n`;
writeFileSync(DIR + 'tails.inc', inc);

// ---- The sprites shown on each row's lines 3 and 4. A sprite whose y is Y shows on lines
// Y + CONV to Y + CONV + 20 (41 expanded). The Scrubblies' (3-7: expanded, y the line before
// their top), from the mock-up (../build/scrub.json); or, --test SEED, sprites 1-7 in the left
// border (unseen, but fetched) at random heights
const CONV = +arg('conv', 1), TEST = process.argv.includes('--test') || PM !== null;
const scrub = JSON.parse(readFileSync(DIR + 'scrub.json', 'utf8'));
let seed = +arg('test', 1) || 1;
const rnd = () => (seed = (seed * 1103515245 + 12345) & 0x7fffffff) / 0x80000000;
let spr = [];                                       // (sprite, y, expanded)
if (TEST) for (let n = 1; n < 8; n++) spr.push({ n, y: 30 + Math.floor(rnd() * 220), exp: rnd() < 0.3 });
else scrub.placed.forEach((p, i) => spr.push({ n: 3 + i, y: 50 + p.top, exp: true }));
if (PM !== null) spr = [1, 2, 3, 4, 5, 6, 7].map(n => ({ n, y: (+PM >> n & 1) ? 77 : 0, exp: !!(+PM >> n & 1) }));
const maskOn = line => spr.reduce((m, s) => line >= s.y + CONV && line < s.y + CONV + (s.exp ? 42 : 21) ? m | 1 << s.n : m, COVER);
const masks = [], masks3 = [];
for (let r = 0; r < 25; r++) { masks3.push(maskOn(54 + 8 * r)); masks.push(maskOn(55 + 8 * r)); }
defs.push('-D', `TEST=${TEST ? 1 : 0}`, '-D', `BALLTEST=${process.argv.includes('--balltest') ? 1 : 0}`, '-D', `NOBALLS=${process.argv.includes('--noballs') ? 1 : 0}`, '-D', `MUXTIME=${process.argv.includes('--muxtime') ? 1 : 0}`, '-D', `SLACK=${process.argv.includes('--slack') ? 1 : 0}`, '-D', `INSANE=${process.argv.includes('--insane') ? 1 : 0}`, '-D', `TROGGX=${arg('troggx', 0)}`, '-D', `TROGGY=${arg('troggy', 0)}`, '-D', `TROGGF=${arg('troggf', 7)}`, '-D', `KEYTEST=${process.argv.includes('--keys') ? 1 : 0}`, '-D', `SCROLLDEMO=${process.argv.includes('--scrolldemo') ? 1 : 0}`, '-D', `CAMTEST=${process.argv.includes('--camtest') ? 1 : 0}`, '-D', `INVINCIBLE=${process.argv.includes('--invincible') ? 1 : 0}`);
const testy = TEST ? spr.map(s => s.y) : [0];
const sx = scrub.placed.map(p => 31 + p.x);
writeFileSync(DIR + 'masks.inc', `; made by tools/build.mjs\nmasks   .byte ${masks.join(', ')}\nmasks3  .byte ${masks3.join(', ')}\n` +
    `testy   .byte ${testy.join(', ')}\nTESTEXP = ${spr.reduce((m, s) => s.exp ? m | 1 << s.n : m, COVER)}\n` +
    `scruby  .byte ${scrub.placed.map(p => 50 + p.top).join(', ')}\nscl     .byte ${scrub.placed.map(p => (p.x + 8) & 255).join(', ')}\nsch     .byte ${scrub.placed.map(p => (p.x + 8) >> 8).join(', ')}\nsct     .byte ${scrub.placed.map(p => p.top + 24).join(', ')}\nsxlo    .byte ${sx.map(v => v & 255).join(', ')}\nsxhi    .byte ${sx.map(v => v >> 8).join(', ')}\n`);
// The collision boxes (collide.asm): each of Trogg's frames' solid pixels' extent as shown, from
// (tx, ty) (trogg.json: the frame's left at tx - left, its top at ty - 34); each Scrubbly's, gem's
// and key's in the level, as the mock-up drew them (picks.json; the level's y is the mock-up's,
// the map's line + 24); the balloon's and dagger's from their image's corner
{
    const tj = JSON.parse(readFileSync(DIR + 'trogg.json')), pj = JSON.parse(readFileSync(DIR + 'picks.json'));
    const box = g => { let x0 = 99, x1 = -1, y0 = 99, y1 = -1; g.forEach((r, y) => r.forEach((p, x) => { if (p >= 0) { x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); } })); return { x0, x1, y0, y1 }; };
    const tb = tj.map(f => { const b = box(f.shown); return { x0: b.x0 - f.left, x1: b.x1 - f.left, y0: b.y0 - 34, y1: b.y1 - 34 }; });
    const sgn = v => v & 255, B = (n, a) => `${n.padEnd(8)}.byte ${a.join(', ')}\n`;
    const sbx = pj.scrubBox, sl = scrub.placed.map(p => p.x + 8 + sbx.x0), sr = scrub.placed.map(p => p.x + 8 + sbx.x1);
    const pk = pj.picks;
    writeFileSync(DIR + 'collide.inc', '; made by tools/build.mjs: the collision boxes (collide.asm)\n' +
        B('tbx0', tb.map(b => sgn(b.x0))) + B('tbx1', tb.map(b => sgn(b.x1))) + B('tby0', tb.map(b => sgn(b.y0))) + B('tby1', tb.map(b => sgn(b.y1))) +
        B('scbll', sl.map(v => v & 255)) + B('scblh', sl.map(v => v >> 8)) + B('scbrl', sr.map(v => v & 255)) + B('scbrh', sr.map(v => v >> 8)) +
        B('scbc0', sl.map(v => v >> 3)) + B('scbc1', sr.map(v => v >> 3)) + B('scbt', scrub.placed.map(p => p.top + 24 + sbx.y0)) + B('scbb', scrub.placed.map(p => p.top + 24 + sbx.y1)) +
        `NP      = ${pk.length}\nNKEYS   = ${pk.filter(p => p.name === 'IMG_Key').length}\n` + B('pkll', pk.map(p => (p.left + p.box.x0) & 255)) + B('pklh', pk.map(p => (p.left + p.box.x0) >> 8)) +
        B('pkrl', pk.map(p => (p.left + p.box.x1) & 255)) + B('pkrh', pk.map(p => (p.left + p.box.x1) >> 8)) +
        B('pkc0', pk.map(p => (p.left + p.box.x0) >> 3)) + B('pkc1', pk.map(p => (p.left + p.box.x1) >> 3)) + B('pkt', pk.map(p => p.top + p.box.y0)) + B('pkb', pk.map(p => p.top + p.box.y1)) + B('pkkind', pk.map(p => p.name === 'IMG_Key' ? 2 : 1)) +
        // (each column's objects, bit k: Scrubbly k, then gem or key k - NS: the quick first test)
        (() => { const m = Array(96).fill(0), rng = [...sl.map((l, i) => [l >> 3, sr[i] >> 3]), ...pk.map(p => [(p.left + p.box.x0) >> 3, (p.left + p.box.x1) >> 3])];
                 if (rng.length > 16) throw new Error('more than 16 static objects for the column masks');
                 rng.forEach(([a, b], k) => { for (let c = a; c <= b; c++) m[c] |= 1 << k; });
                 // (and each band of 32 lines' objects: his columns' and his bands' in common)
                 const bm = Array(8).fill(0), ys = [...scrub.placed.map(p => [p.top + 24 + sbx.y0, p.top + 24 + sbx.y1]), ...pk.map(p => [p.top + p.box.y0, p.top + p.box.y1])];
                 ys.forEach(([t, b], k) => { for (let c = t >> 5; c <= b >> 5; c++) bm[c] |= 1 << k; });
                 return B('colml', m.map(v => v & 255)) + B('colmh', m.map(v => v >> 8)) + B('bandml', bm.map(v => v & 255)) + B('bandmh', bm.map(v => v >> 8)); })() +
        // (the second stage: each image's spans, a row's leftmost and rightmost solid pixel, 255
        // for an empty row; and each object's image's corner)
        (() => { const sp = g => g.flatMap(r => { const xs = r.map((p, x) => p >= 0 ? x : -1).filter(x => x >= 0); return xs.length ? [xs[0], xs[xs.length - 1]] : [255, 255]; });
                 const g = pj.grids, kinds = { IMG_Key: 'keysp', IMG_Gem: 'gemsp' };
                 // (frames with the same spans share them: tsU, each different one once; tsAt, each frame's)
                 const tsU = [], tsAt = tj.map(f => { const v = sp(f.shown), k = tsU.findIndex(u => u.join() === v.join()); return k >= 0 ? k : tsU.push(v) - 1; });
                 return B('tleft', tj.map(f => f.left)) + `tspl    .byte ${tsAt.map(i => `<(tspan + ${i * 68})`).join(', ')}\ntsph    .byte ${tsAt.map(i => `>(tspan + ${i * 68})`).join(', ')}\n` +
                     B('tspan', tsU.flat()) + B('scrsp', sp(g.IMG_Scrubbly)) + `SCRH    = ${g.IMG_Scrubbly.length}\n` +
                     B('keysp', sp(g.IMG_Key)) + B('gemsp', sp(g.IMG_Gem)) +
                     B('scil', scrub.placed.map(p => (p.x + 8) & 255)) + B('scih', scrub.placed.map(p => (p.x + 8) >> 8)) + B('scit', scrub.placed.map(p => p.top + 24)) +
                     B('pkil', pk.map(p => p.left & 255)) + B('pkih', pk.map(p => p.left >> 8)) + B('pkit', pk.map(p => p.top)) +
                     `pkspl   .byte ${pk.map(p => '<' + kinds[p.name]).join(', ')}\npksph   .byte ${pk.map(p => '>' + kinds[p.name]).join(', ')}\n` +
                     B('pkh', pk.map(p => g[p.name].length)); })() +
        // (the balloon (kind 1) and the dagger (2): their sprites, hi-res, the image at the sprite's
        // corner; their origin in the image, size, tight box from the image's corner, spans)
        (() => { const H = [pj.hazards.IMG_Balloon, pj.hazards.IMG_DaggerLR], hb = H.map(h => box(h.grid));
                 const spr = H.flatMap(h => { const b = Array(64).fill(0); h.grid.forEach((r, y) => r.forEach((p, x) => { if (p >= 0) b[y * 3 + (x >> 3)] |= 0x80 >> (x & 7); })); return b; });
                 const sp = gr => gr.flatMap(r => { const xs = r.map((p, x) => p >= 0 ? x : -1).filter(x => x >= 0); return xs.length ? [xs[0], xs[xs.length - 1]] : [255, 255]; });
                 const K = (n, f) => B(n, [0, ...H.map(f)]);
                 writeFileSync(DIR + 'hazspr.bin', Buffer.from(spr));
                 return K('kxo', h => h.xo) + K('kyo', h => h.yo) + K('kw', h => h.grid[0].length) + K('kh', h => h.grid.length) +
                     B('kbx0', [0, ...hb.map(b => b.x0)]) + B('kbx1', [0, ...hb.map(b => b.x1)]) + B('kby0', [0, ...hb.map(b => b.y0)]) + B('kby1', [0, ...hb.map(b => b.y1)]) +
                     B('balsp', sp(H[0].grid)) + B('dagsp', sp(H[1].grid)) + `kspl    .byte 0, <balsp, <dagsp\nksph    .byte 0, >balsp, >dagsp\n`; })() +
        // (the FRAK! bubble, redrawn at half width, 24 x 19, for two x-expanded sprites: its black, and
        // its yellow where the black isn't (so either can be in front). The letters from the BBC's
        // image, each stroke (2 pixels) one pixel: its F on even columns, the rest on odd ones (a
        // pixel's gap between); the F 3 wide (its arms one shorter), so the bubble fits 24; the
        // outline, corners and tail drawn here)
        (() => { const F = pj.hazards.IMG_Frak, R = F.grid.map(r => r.map(p => ' .YMB'[p + 1]).join(''));
                 const half = (row, a, b) => { let o = ''; for (let x = a; x < b; x += 2) { const p = row.slice(x, x + 2); o += p.includes('B') ? 'B' : p.includes('Y') ? 'Y' : ' '; } return o; };
                 const letters = y => { const f = half(R[y], 6, 14); return f[0] + f[1] + f[3] + 'Y' + half(R[y], 15, 49).slice(0, -1); };
                 const n = ['  ' + 'B'.repeat(20) + '  ', ' BB' + 'Y'.repeat(18) + 'BB ', ' B' + 'Y'.repeat(20) + 'B ',
                            ...[3, 4, 5, 6, 7, 8, 9, 10, 11].map(y => 'BY' + letters(y) + 'YB'),
                            ' B' + 'Y'.repeat(20) + 'B ', ' BB' + 'Y'.repeat(18) + 'BB ', '  BBYY' + 'B'.repeat(16) + '  ',
                            '   BYBB' + ' '.repeat(17), '   BYB' + ' '.repeat(18), '  BYB' + ' '.repeat(19), ' BBB' + ' '.repeat(20)];
                 if (n.some(r => r.length !== 24) || n.length !== F.grid.length) throw new Error('the FRAK! bubble is not 24 x ' + F.grid.length);
                 writeFileSync(DIR + 'frak.txt', '; the FRAK! bubble as the C64 shows it: 24 wide, each pixel shown 2 wide (build.mjs)\n' + n.join('\n') + '\n');
                 const blk = col => { const b = Array(64).fill(0); n.forEach((r, y) => { for (let x = 0; x < 24; x++) if (r[x] === col) b[y * 3 + (x >> 3)] |= 0x80 >> (x & 7); }); return b; };
                 writeFileSync(DIR + 'frakspr.bin', Buffer.from([...blk('B'), ...blk('Y')]));
                 return `FRAKXO  = ${F.xo}\nFRAKYO  = ${F.yo}\n`; })());
}
const sb = Buffer.alloc(64);
scrub.sprite.forEach((row, y) => { for (let k = 0; k < 3; k++) sb[y * 3 + k] = parseInt(row.slice(k * 8, k * 8 + 8), 2); });
writeFileSync(DIR + 'scrubspr.bin', sb);
console.log(`row masks (line 3/4): ${masks.map((m, r) => masks3[r] === m ? m.toString(16) : masks3[r].toString(16) + '/' + m.toString(16)).join(' ')}; tails ${masks.map(m => tailFor[m]).join(' ')}`);
if (!process.argv.includes('--nopack')) execFileSync('node', [TOOLS + 'pack.mjs'], { stdio: 'inherit' });
// (--keys T:K,T:K...: for a test build, the keys held for T ticks each, K of L R U D Y or -)
{
    const steps = String(arg('keys', '1:-')).split(',').map(s => s.split(':'));
    const bit = k => [...k].reduce((v, c) => v | ({ L: 1, R: 2, U: 4, D: 8, Y: 16 }[c] || 0), 0);
    writeFileSync(DIR + 'keys.inc', `; made by tools/build.mjs (--keys)\nKSCRN = ${steps.length}\n` +
        `kscrn   .byte ${steps.map(s => +s[0]).join(', ')}\nkscrk   .byte ${steps.map(s => bit(s[1])).join(', ')}\n`);
}
// (the platforms and ladders for Trogg's physics, as the BBC version's tables: geometry.json, by
// mockup.mjs)
{
    const g = JSON.parse(readFileSync(DIR + 'geometry.json', 'utf8'));
    const t = (name, v) => `${name.padEnd(8)}.byte ${v.join(', ')}\n`;
    const P = g.plats, L = g.lads;
    writeFileSync(DIR + 'geometry.inc', `; made by tools/build.mjs from geometry.json (mockup.mjs)\nNPLATS = ${P.length}\nNLADS = ${L.length}\n` +
        `LEVEL_W = ${g.w}\nLEVEL_H = ${g.h}\nTSTARTX = ${g.trogg[0]}\nTSTARTY = ${g.trogg[1]}\n` +
        t('plat_xl', P.map(p => p.x & 255)) + t('plat_xh', P.map(p => p.x >> 8)) + t('plat_yl', P.map(p => p.y & 255)) +
        t('plat_yh', P.map(p => p.y >> 8)) + t('plat_w', P.map(p => p.w)) +
        t('lad_xl', L.map(l => l.x & 255)) + t('lad_xh', L.map(l => l.x >> 8)) + t('lad_yl', L.map(l => l.y & 255)) +
        t('lad_yh', L.map(l => l.y >> 8)) + t('lad_hl', L.map(l => l.h & 255)) + t('lad_hh', L.map(l => l.h >> 8)) + t('lad_ext', L.map(l => l.ext)) +
        cols('pcol', 'plist', P.map((p, i) => [p.x, p.x + p.w - 1, i]).sort((a, b) => b[2] - a[2])) +
        cols('lcol', 'llist', L.map((l, i) => [l.x - 6, l.x + 6, i])));
    // (by 8-pixel column, the platforms over it (last first, as platform_find goes), and the
    // ladders within 6 pixels of it (first first): each column's from xcol[c] to xcol[c + 1] in
    // the list)
    function cols(xcol, list, items) {
        const NCOL = Math.ceil(g.w / 8) + 2, idx = [], lst = [];
        for (let c = 0; c < NCOL; c++) { idx.push(lst.length); for (const [a, b, i] of items) if (a <= c * 8 + 7 && b >= c * 8) lst.push(i); }
        idx.push(lst.length);
        if (lst.length > 255) throw new Error(`${list}: too long`);
        return `NCOL = ${NCOL}\n`.replace('NCOL', xcol.toUpperCase() + 'N') + t(xcol, idx) + t(list, lst);
    }
}
execFileSync('64tass', ['-q', '-a', '-C', ...defs, '-I', DIR, '--labels=' + DIR + 'frak64.lbl', '-L', DIR + 'frak64.lst', '-o', DIR + 'frak64.prg', SRC + 'frak64.asm'], { cwd: DIR, stdio: 'inherit' });
const lbl = Object.fromEntries(readFileSync(DIR + 'frak64.lbl', 'utf8').split('\n').map(l => l.match(/^(\w+)\s*=\s*\$([0-9a-f]+)/i)).filter(Boolean).map(m => [m[1], parseInt(m[2], 16)]));
// The release: frak64.prg packed by Exomizer into a self-unpacking program (frak64.exo.prg, started
// by RUN like the original), on a disk image (frak64.d64), for a plain build only. --packtest puts
// the packed program in the test cartridge instead, so a run in VICE checks the unpacking.
const EXO = process.env.EXOMIZER || '/opt/frak-tools/exomizer-src/src/exomizer';
const plain = process.argv.slice(2).every(a => a === '--nopack');
const packtest = process.argv.includes('--packtest');
if ((plain || packtest) && existsSync(EXO)) {
    execFileSync(EXO, ['sfx', 'sys', '-q', '-o', DIR + 'frak64.exo.prg', DIR + 'frak64.prg'], { stdio: 'inherit' });
    const n = readFileSync(DIR + 'frak64.exo.prg').length - 2;
    if (plain) {
        if (existsSync(DIR + 'frak64.d64')) unlinkSync(DIR + 'frak64.d64');
        execFileSync('c1541', ['-format', 'frak64,64', 'd64', DIR + 'frak64.d64', '-write', DIR + 'frak64.exo.prg', 'frak64'], { stdio: 'ignore' });
        console.log(`frak64.d64: FRAK64, packed to ${n} bytes (${Math.ceil(n / 254)} blocks)`);
    }
} else if (plain || packtest) console.log(`(no Exomizer at ${EXO}: frak64.d64 not made)`);
if (packtest && !existsSync(DIR + 'frak64.exo.prg')) throw new Error('--packtest needs Exomizer');
const prg = readFileSync(DIR + (packtest ? 'frak64.exo.prg' : 'frak64.prg'));
const sysAt = p => { const i = p.indexOf(0x9e, 6); return parseInt(p.subarray(i + 1, i + 8).toString('latin1').match(/\d+/)[0], 10); };
if (packtest) lbl.start = sysAt(prg);
console.log(`frak64.prg: $0801-$${(0x0801 + prg.length - 3).toString(16)} (${prg.length - 2} bytes), start $${lbl.start.toString(16)}, row interrupt $${lbl.rowirq.toString(16)}; TS ${PARAMS.TS}`);
writeFileSync(DIR + 'rom.inc', `START = $${lbl.start.toString(16)}\nPAGES = ${Math.ceil((prg.length - 2) / 256)}\n`);
// (the cartridge for the stand-in ROMs: a Magic Desk CRT, the PRG in 8K banks)
{
    const body = prg.subarray(2), banks = Math.ceil(body.length / 0x2000), hd = Buffer.alloc(0x40);
    if (Math.ceil(body.length / 256) > 255) throw new Error('the program is too long for the stand-in loader');
    hd.write('C64 CARTRIDGE   ', 0, 'latin1'); hd.writeUInt32BE(0x40, 0x10); hd.writeUInt16BE(0x0100, 0x14);
    hd.writeUInt16BE(19, 0x16); hd[0x18] = 0; hd[0x19] = 1; hd.write('FRAK64', 0x20, 'latin1');
    const chips = [];
    for (let b = 0; b < banks; b++) {
        const c = Buffer.alloc(0x10 + 0x2000); c.write('CHIP', 0, 'latin1'); c.writeUInt32BE(0x2010, 4);
        c.writeUInt16BE(0, 8); c.writeUInt16BE(b, 10); c.writeUInt16BE(0x8000, 12); c.writeUInt16BE(0x2000, 14);
        body.copy(c, 0x10, b * 0x2000, Math.min(body.length, (b + 1) * 0x2000)); chips.push(c);
    }
    writeFileSync(DIR + 'frak64.crt', Buffer.concat([hd, ...chips]));
}
execFileSync('64tass', ['-q', '-a', '-C', '-b', '-I', DIR, '-o', DIR + 'rom.bin', SRC + 'rom.asm'], { cwd: DIR, stdio: 'inherit' });
const rom = readFileSync(DIR + 'rom.bin');          // $a000-$bfff, then $e000-$ffff
writeFileSync(DIR + 'basic.rom', rom.subarray(0, 0x2000)); writeFileSync(DIR + 'kernal.rom', rom.subarray(0x2000, 0x4000));
writeFileSync(DIR + 'chargen.rom', Buffer.alloc(0x1000));
if (process.argv.includes('--run')) {
    const shot = arg('shot', DIR + 'shot.png');
    if (existsSync(shot)) unlinkSync(shot);
    try {
        execFileSync('xvfb-run', ['-a', 'x64sc', '-default', '-kernal', DIR + 'kernal.rom', '-basic', DIR + 'basic.rom', '-chargen', DIR + 'chargen.rom', '-cartcrt', DIR + 'frak64.crt',
            '-drive8type', '0', '-sounddev', 'dummy', '-VICIIfilter', '0', '-limitcycles', arg('cycles', '800000'), '-exitscreenshot', shot],
            { cwd: DIR, stdio: ['ignore', 'pipe', 'pipe'], timeout: 120000 });
    } catch (e) { if (!existsSync(shot)) { console.log(String(e.stderr || e).slice(-2000)); throw e; } }
    console.log('screenshot: ' + shot);
}
