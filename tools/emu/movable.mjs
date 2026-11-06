// Movable platforms in play: on room_E_1, Trogg yoyos the movable platform, carries it, walks,
// drops it with a second throw, and climbs onto it. Prints what happens tick by tick, and saves
// screenshots (in screenshots/) along the way.
//
//   ./build.sh && cd tools/emu && node movable.mjs
import { MachineSession } from 'jsbeeb';
import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { deflateSync } from 'zlib';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const out = readFileSync(REPO + '/build/assembler.txt', 'utf8');
const sym = {};
for (const [, k, v] of out.match(/SYMBOLS(.*)/)[1].matchAll(/(\w+)\s*&([0-9A-F]+)/g)) sym[k] = parseInt(v, 16);
const NAMES = ['room_0', ...'ABCDEF'.split('').flatMap(c => [1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => `room_${c}_${n}`))];
const shotdir = resolve(REPO, 'tools/emu/screenshots');
mkdirSync(shotdir, { recursive: true });

const s = new MachineSession('Master', { discImage: REPO + '/build/frak.ssd' });
await s.initialise(); await s.boot(30); await s.autoboot();
const cpu = s._machine.processor;
const r8 = a => cpu.readmem(a), r16 = a => { const v = r8(a) | r8(a + 1) << 8; return v > 32767 ? v - 65536 : v; };
for (let t = 0; t < 100 && r8(sym.snd_tune) !== 5; t++) await s.runFrames(20);
await s.runFrames(100);
for (let i = 0; i < 2; i++) { s.keyDown('Space'); await s.runFrames(5); s.keyUp('Space'); await s.runFrames(60); }
await s.runFrames(300);

const room = process.argv[2] || 'room_E_1', li = NAMES.indexOf(room);
for (let t = 0; t < 400 && r8(sym.cur_level) !== li; t++) {
    if (t % 40 === 0) { cpu.writemem(sym.cur_level, (li + 54) % 55); cpu.writemem(sym.won, 1); }
    await s.runFrames(5);
}
await s.runFrames(300);
if (r8(sym.cur_level) !== li) throw new Error('level did not load');

const s16 = v => (v > 32767 ? v - 65536 : v);
const plat = i => `P${i}(${s16(r8(sym.plat_xl + i) | r8(sym.plat_xh + i) << 8)},${s16(r8(sym.plat_yl + i) | r8(sym.plat_yh + i) << 8)})`;
const movable = [...Array(r8(sym.num_plats)).keys()].filter(i => r8(sym.plat_moving + i) === 2);
const state = () => `trogg ${r16(sym.tx)},${r16(sym.ty)}+${r8(sym.tyf)}/20 state ${r8(sym.tstate)} yoyo ${r8(sym.yo_len + 1)}.${r8(sym.yo_len)} ` +
    `carry ${r8(sym.carry)} dropped ${r8(sym.dropped)} ${movable.map(plat).join(' ')} dead ${r8(sym.dead)}`;
console.log(room, 'movable', movable.join(','), '|', state());

function screenshot(name) {
    const v = s._video, W = 1024, H = 625;
    const l = v.leftBorder, t = v.topBorder, w = W - l - v.rightBorder, h = H - t - v.bottomBorder;
    const fb = s._completeFb8, rgb = Buffer.alloc(w * h * 3);
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
        const i = ((y + t) * W + x + l) * 4, o = (y * w + x) * 3;
        rgb[o] = fb[i]; rgb[o + 1] = fb[i + 1]; rgb[o + 2] = fb[i + 2];
    }
    const crcT = Array.from({ length: 256 }, (_, n) => { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c >>> 0; });
    const crc = b => { let c = 0xffffffff; for (const x of b) c = crcT[(c ^ x) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
    const chunk = (ty, d) => { const n = Buffer.alloc(4); n.writeUInt32BE(d.length); const td = Buffer.concat([Buffer.from(ty), d]); const c = Buffer.alloc(4); c.writeUInt32BE(crc(td)); return Buffer.concat([n, td, c]); };
    const raw = Buffer.alloc((w * 3 + 1) * h);
    for (let y = 0; y < h; y++) rgb.copy(raw, y * (w * 3 + 1) + 1, y * w * 3, (y + 1) * w * 3);
    const ih = Buffer.alloc(13); ih.writeUInt32BE(w, 0); ih.writeUInt32BE(h, 4); ih[8] = 8; ih[9] = 2;
    writeFileSync(`${shotdir}/${name}.png`, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ih), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
}

// steps: [keys held, frames, note]
const steps = (process.argv[3] || 'Space:150:throw KeyX:20:face Space:60:drop :50:wait').split(' ').map(t => t.split(':'));
let n = 0;
for (const [keys, frames, note] of steps) {
    const held = keys ? keys.split('+') : [];
    held.forEach(k => s.keyDown(k));
    let last = '';
    for (let f = 0; f < +frames; f += 2) {
        await s.runFrames(2);
        const st = state();
        if (st !== last) { console.log(`${note || ''} ${f}: ${st}`); last = st; }
    }
    held.forEach(k => s.keyUp(k));
    await s.runFrames(2);
    screenshot(`${room}_${n++}_${note || 'step'}`);
}
process.exit(0);
