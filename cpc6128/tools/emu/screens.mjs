// Phase 1's test: the two screen modes and double buffering. For each mode it checks the test
// card's white outline (MAME's screenshots are 2 pixels wide per Mode 1 pixel, a line per line:
// 256x256 is 512x256 there, 320x200 is 640x200, and all of it on show), then flips the buffers
// every frame and checks that each frame shows one buffer whole (one fill colour: no tearing)
// and that they alternate.
//
//   ./build.sh && CPC_ROMS=... node tools/emu/screens.mjs
import { symbols, run, boot, readPng } from './mame.mjs';

const sym = symbols();
const FRAMES = 10;
const modes = [{ name: '256x256', mode: 0, w: 512, h: 256 }, { name: '320x200', mode: 1, w: 640, h: 200 }];

const steps = [...boot];
for (const m of modes) {
    steps.push(`poke ${sym.want_mode} ${m.mode}`, `poke ${sym.flip_rate} 1`, `poke ${sym.flip_count} 1`, 'wait 25');
    for (let f = 0; f < FRAMES; f++) steps.push(`snap m${m.mode}_${f}`, 'wait 1');
}
const r = run(steps);

// what each pixel is: white (the outline), red (buffer 0's fill), green (buffer 1's) or other
const kind = ([r, g, b]) => r > 200 && g > 200 && b > 200 ? 'white' : r > 150 && g < 80 ? 'red' : g > 60 && r < 80 && b < 80 ? 'green' : 'other';

let failed = 0;
const fail = msg => { console.log('  FAIL ' + msg); failed++; };
for (const m of modes) {
    console.log(`${m.name}:`);
    let last = null;
    for (let f = 0; f < FRAMES; f++) {
        const png = readPng(r.snaps[`m${m.mode}_${f}`]);
        let x0 = png.w, x1 = -1, y0 = png.h, y1 = -1;
        const count = { white: 0, red: 0, green: 0, other: 0 };
        for (let y = 0; y < png.h; y++) for (let x = 0; x < png.w; x++) {
            const k = kind(png.px(x, y));
            count[k]++;
            if (k === 'white') { x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
        }
        const w = x1 - x0 + 1, h = y1 - y0 + 1;
        const fill = count.red && !count.green ? 'red' : count.green && !count.red ? 'green' : 'both';
        if (f === 0) console.log(`  outline ${w}x${h} at ${x0},${y0} in ${png.w}x${png.h}`);
        if (w !== m.w || h !== m.h) fail(`frame ${f}: outline ${w}x${h}, not ${m.w}x${m.h}`);
        if (x0 === 0 || y0 === 0 || x1 === png.w - 1 || y1 === png.h - 1) fail(`frame ${f}: the picture reaches the edge of what's on show`);
        if (fill === 'both') fail(`frame ${f}: both buffers' colours (torn)`);
        if (fill === last) fail(`frame ${f}: the same buffer as the frame before`);
        last = fill;
    }
    console.log(`  ${FRAMES} frames, buffers alternating`);
}
console.log(failed ? `${failed} failures` : 'all passed');
process.exit(failed ? 1 : 0);
