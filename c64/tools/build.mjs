// Assembles the demo (../build/frak64.prg, for a real C64 or an emulator with its ROMs) with
// 64tass, and the stand-in ROMs for testing it in a VICE without Commodore's (basic.rom,
// kernal.rom, chargen.rom); with --run, runs VICE (x64sc, headless) and takes a screenshot.
// TS (cycles from the stable raster to starting the row timer) and RD (cycles at the start of
// the timer's interrupt before it reads the timer; not 1) are found by sweeping them in VICE
// with compare.py (see ../src/frak64.asm). --measure and --hist build its MEASURE and HIST
// versions.
//   node build.mjs [--ts N] [--rd N] [--measure] [--hist] [--nopack] [--run] [--cycles N] [--shot file.png]
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
export const PARAMS = { TS: +arg('ts', 37), RD: +arg('rd', 0) };
const JM = +arg('jm', 5);
const defs = [];
for (const [name, n] of Object.entries(PARAMS)) {
    // (RD in nops and a bit zp only: no loop, as the interrupt has no register free for one)
    const s = name === 'RD' ? { K: 0, B: n & 1, N: (n - 3 * (n & 1)) / 2 } : split(n);
    if (s.N < 0) throw new Error(`no delay of ${n}`);
    defs.push('-D', `${name}K=${s.K}`, '-D', `${name}N=${s.N}`, '-D', `${name}B=${s.B}`);
}
defs.push('-D', `JM=${JM}`, '-D', `MEASURE=${process.argv.includes('--measure') ? 1 : 0}`, '-D', `HIST=${process.argv.includes('--hist') ? 1 : 0}`);

// ---- The row interrupt's tails. The VIC fetches the sprites shown on a row's line 4 at the end
// of line 3 (sprites 0-2: their first s-access on cycle 58, 60, 62) and the start of line 4
// (3-7: line 4's cycles 1, 3, 5, 7, 9), holding BA low from 3 cycles before each sprite's first
// s-access to its last: the CPU stops at its next read while it's low. From the $d018 write on
// line 3's cycle 55, a tail does nothing but read (a delay of d cycles, then sta $d011's three
// reads) before the $d011 write, which must land on line 4's cycle 14 (or 15 where nothing can
// reach 14: one character more of the FLI bug, under the cover sprite). Sprite 7, the cover, is
// always fetched. Counting cycles from line 3's 0 (line 4's cycle c is 63 + c):
const P = [58, 60, 62, 64, 66, 68, 70, 72];
const low = (m, t) => P.some((p, n) => (m >> n & 1) && t >= p - 3 && t <= p + 1);
const writeAt = (m, d) => { let t = 56, r = d + 3; while (r > 0) { if (!low(m, t)) r--; t++; } return t - 63; };
const tailFor = [];
for (let m = 0; m < 128; m++) {
    let d = -1;
    for (const want of [14, 15]) { for (let k = 0; k <= 30 && d < 0; k++) if (k !== 1 && writeAt(m | 128, k) === want) d = k; if (d >= 0) break; }
    if (d < 0) throw new Error(`no tail for sprites ${m.toString(2)}`);
    tailFor.push(d);
}
// (--probe N --d D: sprite N alone, covering rows 6-10, those rows with a tail of D cycles)
const PROBE = arg('probe', null), PD = +arg('d', 0);
if (PROBE !== null) tailFor.forEach((_, m) => { if (m) tailFor[m] = PD; });
if (arg('d0', null) !== null) tailFor[0] = +arg('d0', 0);
if (arg('masktest', null) !== null) tailFor.fill(PD);
const delays = [...new Set(tailFor)].sort((a, b) => a - b);
const delayCode = d => { const out = []; let r = d; if (r & 1) { out.push('bit $ea'); r -= 3; } while (r > 0) { out.push('nop'); r -= 2; } return out; };
let inc = '; made by tools/build.mjs: the row interrupt\'s tails, one for each delay, and which\n; tail for each mask of sprites 0-6 fetched for line 4 (sprite 7 always)\n';
inc += 'masktl  .byte ' + tailFor.map(d => `<tail${d}`).join(', ') + '\n';
inc += 'maskth  .byte ' + tailFor.map(d => `>tail${d}`).join(', ') + '\n';
for (const d of delays) inc += `tail${d}  stx $d018\n` + delayCode(d).map(c => `        ${c}\n`).join('') + '        sta $d011\n        jmp tailend\n';
writeFileSync(DIR + 'tails.inc', inc);

// ---- Which sprites are shown on each row's line 4 (sprite 7 left out: always). A sprite whose
// y is Y shows on lines Y + CONV to Y + CONV + 20 (41 expanded). --test SEED: sprites 0-6 in the
// left border at random heights, to try the tails
const CONV = +arg('conv', 1), TEST = process.argv.includes('--test') || PROBE !== null || arg('masktest', null) !== null;
let seed = +arg('test', 1) || 1;
const rnd = () => (seed = (seed * 1103515245 + 12345) & 0x7fffffff) / 0x80000000;
const testy = [], testexp = [];
for (let n = 0; n < 7; n++) { testy.push(30 + Math.floor(rnd() * 220)); testexp.push(rnd() < 0.3 ? 1 : 0); }
if (PROBE !== null) for (let n = 0; n < 7; n++) { testy[n] = n === +PROBE ? 55 + 8 * 6 - 12 : 0; testexp[n] = n === +PROBE ? 1 : 0; }
const masks = [];
for (let r = 0; r < 25; r++) {
    const line = 55 + 8 * r;
    let m = 0;
    if (TEST) for (let n = 0; n < 7; n++) { const h = testexp[n] ? 42 : 21; if (line >= testy[n] + CONV && line < testy[n] + CONV + h) m |= 1 << n; }
    masks.push(m);
}
// --masktest K: rows 1, 4, 7 ... 22 show masks 8K to 8K+7 (the sprites set from the row before,
// each for 21 lines from the line before the row's line 4), every row's tail TD (--d) long
const MT = arg('masktest', null);
let mty = Array.from({ length: 7 }, () => Array(25).fill(0));
if (MT !== null) {
    const rowsT = [1, 4, 7, 10, 13, 16, 19, 22];
    for (let r = 0; r < 25; r++) masks[r] = 0;
    rowsT.forEach((R, j) => {
        const m = (8 * +MT + j) & 127;
        for (let n = 0; n < 7; n++) if (m >> n & 1) mty[n][R - 1] = 53 + 8 * R;
        for (let k = 0; k < 3 && R + k < 25; k++) masks[R + k] = m;
    });
    for (let r = 0; r < 25; r++) tailFor[masks[r]] = PD;
    testy.fill(0); testexp.fill(0);
}
defs.push('-D', `MASKTEST=${MT !== null ? 1 : 0}`);
writeFileSync(DIR + 'mty.inc', mty.map((t, n) => `mty${n}    .byte ${t.join(', ')}`).join('\n') + '\n');
writeFileSync(DIR + 'masks.inc', `; made by tools/build.mjs\nmasks   .byte ${masks.join(', ')}\ntesty   .byte ${testy.join(', ')}\nTESTEXP = ${testexp.reduce((s, e, n) => s | e << n, 0) | 0x80}\n`);
defs.push('-D', `TEST=${TEST ? 1 : 0}`, '-D', `STALL=${process.argv.includes('--stall') ? 1 : 0}`);
if (TEST) console.log(`test sprites at y ${testy.join(' ')} (expanded: ${testexp.join('')}); row masks ${masks.map(m => m.toString(16)).join(' ')}; tails ${masks.map(m => tailFor[m]).join(' ')}`);
if (!process.argv.includes('--nopack')) execFileSync('node', [TOOLS + 'pack.mjs'], { stdio: 'inherit' });
execFileSync('64tass', ['-q', '-a', '-C', ...defs, '-I', DIR, '--labels=' + DIR + 'frak64.lbl', '-o', DIR + 'frak64.prg', SRC + 'frak64.asm'], { cwd: DIR, stdio: 'inherit' });
const lbl = Object.fromEntries(readFileSync(DIR + 'frak64.lbl', 'utf8').split('\n').map(l => l.match(/^(\w+)\s*=\s*\$([0-9a-f]+)/i)).filter(Boolean).map(m => [m[1], parseInt(m[2], 16)]));
const prg = readFileSync(DIR + 'frak64.prg');
console.log(`frak64.prg: $0801-$${(0x0801 + prg.length - 3).toString(16)} (${prg.length - 2} bytes), start $${lbl.start.toString(16)}, row interrupt $${lbl.rowirq.toString(16)}; TS ${PARAMS.TS} RD ${PARAMS.RD}`);
writeFileSync(DIR + 'rom.inc', `START = $${lbl.start.toString(16)}\nLENGTH = ${prg.length - 2}\n`);
execFileSync('64tass', ['-q', '-a', '-C', '-b', '-I', DIR, '-o', DIR + 'rom.bin', SRC + 'rom.asm'], { cwd: DIR, stdio: 'inherit' });
const rom = readFileSync(DIR + 'rom.bin');          // $a000-$bfff, then $e000-$ffff
writeFileSync(DIR + 'basic.rom', rom.subarray(0, 0x2000)); writeFileSync(DIR + 'kernal.rom', rom.subarray(0x2000, 0x4000));
writeFileSync(DIR + 'chargen.rom', Buffer.alloc(0x1000));
if (process.argv.includes('--run')) {
    const shot = arg('shot', DIR + 'shot.png');
    if (existsSync(shot)) unlinkSync(shot);
    try {
        execFileSync('xvfb-run', ['-a', 'x64sc', '-default', '-kernal', DIR + 'kernal.rom', '-basic', DIR + 'basic.rom', '-chargen', DIR + 'chargen.rom',
            '-drive8type', '0', '-sounddev', 'dummy', '-VICIIfilter', '0', '-limitcycles', arg('cycles', '800000'), '-exitscreenshot', shot],
            { cwd: DIR, stdio: ['ignore', 'pipe', 'pipe'], timeout: 120000 });
    } catch (e) { if (!existsSync(shot)) { console.log(String(e.stderr || e).slice(-2000)); throw e; } }
    console.log('screenshot: ' + shot);
}
