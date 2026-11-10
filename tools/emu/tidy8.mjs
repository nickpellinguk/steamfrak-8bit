// Check the tidying of the buffer on show (tidy, chasing the raster while the buffer
// just drawn waits to be shown): boot build/frak.ssd on an emulated BBC Master 128
// (jsbeeb), play levels with keys pressed at random, and check every tidy leaves its
// buffer exactly as it was before that buffer's draw log was drawn - as at t_slow_done
// in its last frame, when the moving platforms and meanies are drawn and nothing logged
// yet. Also counts the tidies done while the other buffer was still waiting to be shown.
//
//   ./build.sh && cd tools/emu && npm install && node tidy8.mjs [room_A_1 ...] [--frames=N]
import { MachineSession } from 'jsbeeb';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const L = {};
for (const [, k, v] of readFileSync(REPO + '/build/labels.txt', 'utf8').matchAll(/'(\w+)':(\d+)L/g)) L[k] = +v;
const args = process.argv.slice(2);
const FRAMES = +((args.find(a => a.startsWith('--frames=')) || '--frames=150').split('=')[1]);
const NAMES = ['room_0', ...'ABCDEF'.split('').flatMap(c => [1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => `room_${c}_${n}`))];
const only = args.filter(a => a.startsWith('room'));
const rooms = only.length ? only : ['room_A_1', 'room_A_7', 'room_B_3', 'room_C_6', 'room_D_1', 'room_E_7', 'room_F_6', 'room_B_1'];

const s = new MachineSession('Master', { discImage: REPO + '/build/frak.ssd' });
await s.initialise(); await s.boot(30); await s.autoboot();
const cpu = s._machine.processor;
const m = cpu.ramRomOs;
const rd = a => cpu.readmem(a);
for (let t = 0, v = -1; t < 100; t++) { if (rd(L.snd_tune) === 5 && rd(L.vsyncs) !== v && v >= 0) break; v = rd(L.vsyncs); await s.runFrames(20); }
await s.runFrames(100);
for (let i = 0; i < 2; i++) { s.keyDown('Space'); await s.runFrames(5); s.keyUp('Space'); await s.runFrames(60); }
await s.runFrames(300);

// a buffer's 20K: buffer 0 in main RAM, buffer 1 in shadow RAM
const buffer = b => { const out = new Uint8Array(0x5000); for (let a = 0x3000; a < 0x8000; a++) out[a - 0x3000] = m[b ? a | 0x8000 : a]; return out; };
const snap = [null, null];
let checks = 0, chased = 0, bad = 0, tidying = -1, wasPending = 0;
cpu.debugInstruction.add(pc => {
    if (pc === L.t_slow_done) snap[rd(L.back)] = buffer(rd(L.back));
    else if (pc === L.redraw_all) { snap[0] = snap[1] = null; tidying = -1; }    // (both drawn afresh)
    else if (pc === L.tidy) {
        // (tidy skips a buffer the next frame won't be drawn in)
        const t = rd(L.back) ^ 1;
        tidying = rd(L.won) || (rd(L.dead) && rd(L.bfrak + t)) ? -1 : t;
        wasPending = rd(L.flip_pending);
    } else if (pc === L.main_loop && tidying >= 0) {
        if (snap[tidying]) {
            const now = buffer(tidying), want = snap[tidying];
            let diff = 0, first = -1;
            for (let i = 0; i < now.length; i++) if (now[i] !== want[i]) { diff++; if (first < 0) first = i; }
            checks++; if (wasPending) chased++;
            if (diff) { bad++; if (bad <= 5) console.log(`  buffer ${tidying}: ${diff} bytes differ after tidying (the first at &${(first + 0x3000).toString(16)})${wasPending ? ', chasing' : ''}`); }
        }
        tidying = -1;
    }
    return false;
});

const KEYS = ['KeyZ', 'KeyX', 'KeyO', 'KeyK', 'KeyP', 'Space'];
let seed = 12345;
const random = n => { seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF; return seed % n; };
for (const room of rooms) {
    const li = NAMES.indexOf(room);
    for (let t = 0; t < 400 && rd(L.cur_level) !== li; t++) {
        if (t % 40 === 0) { cpu.writemem(L.cur_level, (li + 54) % 55); cpu.writemem(L.won, 1); }
        await s.runFrames(5);
    }
    await s.runFrames(100);
    snap[0] = snap[1] = null;
    const c0 = checks, ch0 = chased, b0 = bad, l0 = rd(L.loops);
    let frames = 0, last = l0;
    while (frames < FRAMES) {
        const held = KEYS.filter(() => random(3) === 0);
        for (const k of held) s.keyDown(k);
        await s.runFrames(6);
        for (const k of held) s.keyUp(k);
        const l = rd(L.loops); frames += (l - last) & 255; last = l;
    }
    console.log(`${room}: ${checks - c0} tidies checked, ${chased - ch0} of them chasing the raster, ${bad - b0} wrong`);
}
console.log(bad ? `${bad} wrong` : 'all right');
process.exit(bad ? 1 : 0);
