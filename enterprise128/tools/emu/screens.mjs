// Phase 1's test: the screen. Both buffers' rings are filled with random bytes, then each is
// shown from a range of scroll positions (the ring's start, either side of its end, and where
// lines run on past the end, into the mirror), flipping between the two buffers every frame.
// Every frame must be exactly one buffer's picture: every pixel of its 320x256 the colour its
// byte in the ring gives it (line y, byte j from (scroll + y * 80 + j) MOD 20480; pixel k of a
// byte from its bits 7-k and 3-k, as in the CPC's Mode 1), in that buffer's palette (no black,
// so the border shows where the picture is), and the buffers must alternate.
//
// The screenshots are 2 pixels across for each 4-colour pixel: the picture is 640x256 in
// ephl's 768x288. This test is ephl's only: MAME's Nick moves on to the next LPB when port #83
// is written (its lph_w calls update_lpt), so a flip spoils the frame it's written in, and its
// screen is 280 lines starting where an LPB with VINT ends, not at the vertical sync.
//
//   ./build.sh && EP_ROMS=... node tools/emu/screens.mjs
import { symbols, run, boot, readPng, EMULATOR } from './harness.mjs';

if (EMULATOR !== 'ephl') {
    console.log(`screens.mjs runs on ephl only (not ${EMULATOR}): see the comment at its top`);
    process.exit(2);
}

const sym = symbols();
const RING = 20480, FRAMES = 4;
const positions = [[0, 20478], [2, 0], [128 * 80, 20480 - 80], [20480 - 78, 20480 - 80 * 3 + 6],
    [20480 - 80 * 255 + 2, 12346], [20478, 2]];
const word = (addr, v) => [`poke ${addr} ${v & 255}`, `poke ${addr + 1} ${v >> 8}`];

const steps = [...boot(), 'fill 252 0 20480 1', 'fill 253 4352 20480 2', 'sdump ring0 252 0 20480', 'sdump ring1 253 4352 20480'];
positions.forEach(([s0, s1], i) => {
    steps.push(`poke ${sym.flip_rate} 0`, ...word(sym.scroll0, s0), ...word(sym.scroll1, s1), `poke ${sym.t_apply} 1`, 'wait 3',
        `poke ${sym.flip_count} 1`, `poke ${sym.flip_rate} 1`, 'wait 3');
    for (let f = 0; f < FRAMES; f++) steps.push(`snap p${i}_${f}`, 'wait 1');
});
const r = run(steps);
const rings = [r.dump('ring0'), r.dump('ring1')];
const pals = [[0x49, 0x92, 0xDB, 0xFF], [0x24, 0x6D, 0xB6, 0x12]];

// Nick's colour byte as ep128emu shows it (Nick::convertPixelToRGB)
const rgb = c => [((c << 2) & 4 | (c >> 2) & 2 | (c >> 6) & 1) * 255 / 7, ((c << 1) & 4 | (c >> 3) & 2 | (c >> 7) & 1) * 255 / 7,
    ((c >> 1) & 2 | (c >> 5) & 1) * 255 / 3].map(Math.round);
const close = (a, b) => a.every((v, i) => Math.abs(v - b[i]) <= 12);

let failed = 0;
const fail = msg => { console.log('  FAIL ' + msg); failed++; };
positions.forEach(([s0, s1], i) => {
    console.log(`scroll positions ${s0} and ${s1}:`);
    let last = -1;
    for (let f = 0; f < FRAMES; f++) {
        const png = readPng(r.snaps[`p${i}_${f}`]);
        // where the picture starts: the first pixel that isn't border (black)
        let x0 = -1, y0 = -1;
        for (let y = 0; y < png.h && y0 < 0; y++) for (let x = 0; x < png.w; x++)
            if (png.px(x, y).some(v => v > 0)) { x0 = x; y0 = y; break; }
        // which buffer: the palette of the top-left pixel
        const first = png.px(x0, y0);
        const buf = [0, 1].find(b => pals[b].some(c => close(rgb(c), first)));
        if (buf === undefined) { fail(`frame ${f}: the picture's colours are no buffer's`); continue; }
        const scroll = buf ? s1 : s0, ring = rings[buf], cols = pals[buf].map(rgb);
        const rows = Math.min(256, png.h - y0);
        let wrong = 0, firstWrong = '';
        for (let y = 0; y < rows; y++) for (let j = 0; j < 80; j++) {
            const v = ring[(scroll + y * 80 + j) % RING];
            for (let k = 0; k < 4; k++) {
                const c = cols[(v >> (7 - k)) & 1 | ((v >> (3 - k)) & 1) << 1];
                for (const dx of [0, 1]) if (!close(png.px(x0 + 8 * j + 2 * k + dx, y0 + y), c)) {
                    if (!wrong++) firstWrong = `line ${y}, byte ${j}, pixel ${k}`;
                }
            }
        }
        // and nothing of the picture outside its 640 x 256
        const right = png.px(x0 + 640, y0 + 10), below = y0 + 256 < png.h ? png.px(x0 + 10, y0 + 256) : [0, 0, 0];
        if (f === 0) console.log(`  the picture at ${x0},${y0} in ${png.w}x${png.h}; ${rows} lines checked`);
        if (wrong) fail(`frame ${f} (buffer ${buf}): ${wrong} pixels wrong, the first at ${firstWrong}`);
        if (right.some(v => v > 0) || below.some(v => v > 0)) fail(`frame ${f}: the picture is bigger than 320x256`);
        if (buf === last) fail(`frame ${f}: buffer ${buf} again`);
        last = buf;
    }
});
console.log(failed ? `${failed} failures (${EMULATOR})` : `all passed (${EMULATOR}): every pixel right, the buffers alternating`);
process.exit(failed ? 1 : 0);
