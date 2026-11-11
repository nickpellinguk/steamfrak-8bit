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
export const PARAMS = { TS: +arg('ts', 24), RD: +arg('rd', 0) };
const JM = +arg('jm', 5);
const defs = [];
for (const [name, n] of Object.entries(PARAMS)) {
    // (RD in nops and a bit zp only: no loop, as the interrupt has no register free for one)
    const s = name === 'RD' ? { K: 0, B: n & 1, N: (n - 3 * (n & 1)) / 2 } : split(n);
    if (s.N < 0) throw new Error(`no delay of ${n}`);
    defs.push('-D', `${name}K=${s.K}`, '-D', `${name}N=${s.N}`, '-D', `${name}B=${s.B}`);
}
defs.push('-D', `JM=${JM}`, '-D', `MEASURE=${process.argv.includes('--measure') ? 1 : 0}`, '-D', `HIST=${process.argv.includes('--hist') ? 1 : 0}`);
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
