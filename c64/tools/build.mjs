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
export const PARAMS = { TS: +arg('ts', 99) };
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
// the FLI bug, under the cover sprite). Sprite 7, the cover, is always shown.
const PA = [-5, -3, -1, 1, 3, 5, 7, 9], PB = [58, 60, 62, 64, 66, 68, 70, 72];
const lowAt = P => (m, t) => P.some((p, n) => (m >> n & 1) && t >= p - 3 && t <= p + 1);
const lowA = lowAt(PA), lowB = lowAt(PB);
let stallA = m => { let c = 0; for (let t = -20; t < 20; t++) if (lowA(m, t)) c++; return c; };
const writeAt = (m, d) => { let t = 56, r = d + 3; while (r > 0) { if (!lowB(m, t)) r--; t++; } return t - 63; };
const W = +arg('w', 14), JM0 = +arg('jm', 4);
const tailFor = [], jmFor = [];
for (let m = 0; m < 128; m++) {
    let d = -1;
    for (const want of [W, W + 1]) { for (let k = 0; k <= 30 && d < 0; k++) if (k !== 1 && writeAt(m | 128, k) === want) d = k; if (d >= 0) break; }
    if (d < 0) throw new Error(`no tail for sprites ${m.toString(2)}`);
    tailFor.push(d);
    jmFor.push(JM0 + stallA(m | 128) - stallA(128));
}
// --probemask M --d D: sprites M (0-6), expanded, on rows 3-8 (lines 3 and 4 alike), every row's
// tail D cycles long: where the garbage lands then (tools/garbage.py) says how late the write is
const PM = arg('probemask', null), PD = +arg('d', 0);
if (PM !== null) tailFor.fill(PD);
const delays = [...new Set(tailFor)].sort((a, b) => a - b);
const delayCode = d => { const out = []; let r = d; if (r & 1) { out.push('bit $ea'); r -= 3; } while (r > 0) { out.push('nop'); r -= 2; } return out; };
let inc = '; made by tools/build.mjs: for each mask of sprites 0-6 (7 always shown), the row\n; interrupt\'s tail (line 4\'s fetches) and its slide\'s constant (line 3\'s); the tails\n';
inc += 'masktl  .byte ' + tailFor.map(d => `<tail${d}`).join(', ') + '\n';
inc += 'maskth  .byte ' + tailFor.map(d => `>tail${d}`).join(', ') + '\n';
inc += 'maskjm  .byte ' + jmFor.join(', ') + '\n';
for (const d of delays) inc += `tail${d}  stx $d018\n` + delayCode(d).map(c => `        ${c}\n`).join('') + '        sta $d011\n        jmp tailend\n';
writeFileSync(DIR + 'tails.inc', inc);

// ---- Which sprites are shown on each row's lines 3 and 4 (7 left out: always). A sprite whose
// y is Y shows on lines Y + CONV to Y + CONV + 20 (41 expanded). --test SEED: sprites 0-6 in the
// left border (unseen, but fetched) at random heights
const CONV = +arg('conv', 1), TEST = process.argv.includes('--test') || PM !== null;
let seed = +arg('test', 1) || 1;
const rnd = () => (seed = (seed * 1103515245 + 12345) & 0x7fffffff) / 0x80000000;
const testy = [], testexp = [];
for (let n = 0; n < 7; n++) { testy.push(30 + Math.floor(rnd() * 220)); testexp.push(rnd() < 0.3 ? 1 : 0); }
if (PM !== null) for (let n = 0; n < 7; n++) { testy[n] = (+PM >> n & 1) ? 77 : 0; testexp[n] = (+PM >> n & 1); }
const maskOn = line => { let m = 0; if (TEST) for (let n = 0; n < 7; n++) { const h = testexp[n] ? 42 : 21; if (line >= testy[n] + CONV && line < testy[n] + CONV + h) m |= 1 << n; } return m; };
const masks = [], masks3 = [];
for (let r = 0; r < 25; r++) { masks3.push(maskOn(54 + 8 * r)); masks.push(maskOn(55 + 8 * r)); }
defs.push('-D', `TEST=${TEST ? 1 : 0}`);
writeFileSync(DIR + 'masks.inc', `; made by tools/build.mjs\nmasks   .byte ${masks.join(', ')}\nmasks3  .byte ${masks3.join(', ')}\ntesty   .byte ${testy.join(', ')}\nTESTEXP = ${testexp.reduce((s, e, n) => s | e << n, 0) | 0x80}\n`);
if (TEST) console.log(`row masks (line 3/4): ${masks.map((m, r) => masks3[r] === m ? m.toString(16) : masks3[r].toString(16) + '/' + m.toString(16)).join(' ')}; tails ${masks.map(m => tailFor[m]).join(' ')}`);
if (!process.argv.includes('--nopack')) execFileSync('node', [TOOLS + 'pack.mjs'], { stdio: 'inherit' });
execFileSync('64tass', ['-q', '-a', '-C', ...defs, '-I', DIR, '--labels=' + DIR + 'frak64.lbl', '-o', DIR + 'frak64.prg', SRC + 'frak64.asm'], { cwd: DIR, stdio: 'inherit' });
const lbl = Object.fromEntries(readFileSync(DIR + 'frak64.lbl', 'utf8').split('\n').map(l => l.match(/^(\w+)\s*=\s*\$([0-9a-f]+)/i)).filter(Boolean).map(m => [m[1], parseInt(m[2], 16)]));
const prg = readFileSync(DIR + 'frak64.prg');
console.log(`frak64.prg: $0801-$${(0x0801 + prg.length - 3).toString(16)} (${prg.length - 2} bytes), start $${lbl.start.toString(16)}, row interrupt $${lbl.rowirq.toString(16)}; TS ${PARAMS.TS}`);
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
