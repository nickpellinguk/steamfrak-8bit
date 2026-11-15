// tour.mjs A8JS XEX OUTDIR SCRIPT: run a program on the WebAssembly atari800 (web/build_emulator.sh)
// with a joystick script, saving the screen (384 x 240 colour indices) and the 64K memory every
// EVERY frames: OUTDIR/NNNN.scr, NNNN.mem. SCRIPT: "frames:joy[:fire] ..." (joy: up 1, down 2,
// left 4, right 8). EVERY from the environment (default 7).
import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { createRequire } from 'module';
const [, , a8js, xex, out, script] = process.argv;
const EVERY = +(process.env.EVERY || 7);
const A = await createRequire(import.meta.url)(a8js)({ print: () => {}, printErr: () => {} });
A.FS.writeFile('/prog.xex', readFileSync(xex));
const frame = A.cwrap('web_frame', 'number', ['number', 'number', 'number', 'number']);
A.cwrap('web_start', 'number', ['string'])('/prog.xex');
mkdirSync(out, { recursive: true });
for (let i = 0; i < 100; i++) frame(0, 0, 0, 0);     // (loading and starting)
let n = 0, saved = 0;
for (const step of script.trim().split(/\s+/)) {
    const [f, joy, fire] = step.split(':').map(Number);
    for (let i = 0; i < f; i++) {
        frame(joy, fire || 0, 0, 0);
        if (++n % EVERY === 0) {
            const s = A._web_screen(), m = A._web_memory(), name = String(saved++).padStart(4, '0');
            writeFileSync(`${out}/${name}.scr`, A.HEAPU8.slice(s, s + 384 * 240));
            writeFileSync(`${out}/${name}.mem`, A.HEAPU8.slice(m, m + 65536));
        }
    }
}
console.log(`${n} frames, ${saved} saved`);
