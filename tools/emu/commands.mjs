// Typed commands (L R U D J Y, with counts): types them on a level and prints what Trogg does.
//
//   ./build.sh && cd tools/emu && node commands.mjs room_0 'R:200 12L:100 @300,100,0:5 U:200'
//
// Each step is: characters to type, frames to watch, and a note; or @x,y,face:frames to put Trogg
// somewhere, standing; or a physical key held (+KeyX:frames); or !symbol=value to poke a variable.
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
// (until the game is running: its vertical sync counter counting, and the attract tune on)
for (let t = 0, v = -1; t < 100; t++) {
    if (r8(sym.snd_tune) === 5 && r8(sym.vsyncs) !== v && v >= 0) break;
    v = r8(sym.vsyncs); await s.runFrames(20);
}
await s.runFrames(100);
for (let i = 0; i < 2; i++) { s.keyDown('Space'); await s.runFrames(5); s.keyUp('Space'); await s.runFrames(60); }
await s.runFrames(300);

const room = process.argv[2] || 'room_0', li = NAMES.indexOf(room);
for (let t = 0; t < 400 && r8(sym.cur_level) !== li; t++) {
    if (t % 40 === 0) { cpu.writemem(sym.cur_level, (li + 54) % 55); cpu.writemem(sym.won, 1); }
    await s.runFrames(5);
}
await s.runFrames(300);
if (r8(sym.cur_level) !== li) throw new Error('level did not load');

const b5 = a => cpu.ramRomOs[cpu.romOffset + 5 * 16384 + a - 0x8000];   // (the command variables are in bank 5)
const state = () => `cp ${r8(sym.save_cp)}/${r8(sym.have_cp)}@${r16(sym.cp_tx)},${r16(sym.cp_ty)} keys ${r8(sym.keys_found)} trogg ${r16(sym.tx)},${r16(sym.ty)}+${r8(sym.tyf)}/20 state ${r8(sym.tstate)} face ${r8(sym.tface)} ` +
    `o ${b5(sym.o_keys)} count ${b5(sym.cmd_cl) | b5(sym.cmd_ch) << 8} next ${b5(sym.cmd_nl) | b5(sym.cmd_nh) << 8} q ${b5(sym.cmd_qh)}-${b5(sym.cmd_qt)} dead ${r8(sym.dead)}`;
console.log(room, '|', state());
if (process.env.GEO) {
    const bank6 = a => a >= 0x8000 && a < 0xC000 ? cpu.ramRomOs[cpu.romOffset + 6 * 16384 + a - 0x8000] : r8(a);
    const s16 = v => (v > 32767 ? v - 65536 : v);
    for (let i = 0; i < r8(sym.num_plats); i++) console.log('plat', i, s16(bank6(sym.plat_xl + i) | bank6(sym.plat_xh + i) << 8), s16(bank6(sym.plat_yl + i) | bank6(sym.plat_yh + i) << 8), 'w', bank6(sym.plat_w + i));
    const bk = a => cpu.ramRomOs[cpu.romOffset + 6 * 16384 + a - 0x8000];
    for (let i = 0; i < r8(sym.num_draw); i++) if (bk(sym.draw_kind + i) === 1) console.log('key', i, s16(bk(sym.draw_xl + i) | bk(sym.draw_xh + i) << 8), s16(bk(sym.draw_yl + i) | bk(sym.draw_yh + i) << 8));
    for (let i = 0; i < r8(sym.num_ladders); i++) console.log('ladder', i, bank6(sym.lad_xl + i) | bank6(sym.lad_xh + i) << 8, bank6(sym.lad_yl + i) | bank6(sym.lad_yh + i) << 8, 'h', bank6(sym.lad_hl + i) | bank6(sym.lad_hh + i) << 8);
}
if (process.env.WATCH) cpu.debugWrite.add((addr, b) => { if (addr === sym[process.env.WATCH]) console.log('    write', process.env.WATCH, b, 'pc', cpu.pc.toString(16), 'ret', ((cpu.readmem(0x101 + cpu.s) | cpu.readmem(0x102 + cpu.s) << 8) + 1).toString(16), 'state', r8(sym.tstate)); return false; });
if (process.env.AT) cpu.debugInstruction.add(addr => { if (addr === parseInt(process.env.AT, 16)) console.log('    at', process.env.AT, 'k', [0, 1, 2, 3, 4].map(i => r8(sym.k_left + i)).join(''), 'A', cpu.a, 'X', cpu.x, 'Y', cpu.y); return false; });
const steps = (process.argv[3] || 'R:200').split(' ').map(t => t.split(':'));
const name = c => /[0-9]/.test(c) ? 'Digit' + c : 'Key' + c.toUpperCase();
for (const [keys, frames, note] of steps) {
    if (keys.startsWith('@')) {
        const [x, y, f] = keys.slice(1).split(',').map(Number);
        cpu.writemem(sym.tx, x & 255); cpu.writemem(sym.tx + 1, x >> 8);
        cpu.writemem(sym.ty, y & 255); cpu.writemem(sym.ty + 1, y >> 8);
        cpu.writemem(sym.tyf, 0); cpu.writemem(sym.tstate, 0); cpu.writemem(sym.tface, f || 0);
        await s.runFrames(+frames || 2);
        console.log(`@ ${state()}`);
        continue;
    }
    if (keys.startsWith('!')) {          // !symbol=value: poke a variable
        const [k, v] = keys.slice(1).split('=');
        cpu.writemem(sym[k], +v);
        continue;
    }
    let held = [];
    if (keys.startsWith('+')) { held = keys.slice(1).split('+'); held.forEach(k => s.keyDown(k)); }
    else for (const c of keys) {
        s.keyDown(name(c));
        for (let f = 0; f < 6; f++) {
            if (f === 3) s.keyUp(name(c));
            await s.runFrames(1);
            if (process.env.TRACE) console.log('  ', c, f, state(), 'k', [0, 1, 2, 3, 4].map(i => r8(sym.k_left + i)).join(''), 'xm', r8(sym.xmove), 'lr', r8(sym.lr_db));
        }
    }
    let last = '';
    for (let f = 0; f < +frames; f += 2) {
        await s.runFrames(2);
        const st = state();
        if (st !== last) { console.log(`${note || keys} ${f}: ${st}`); last = st; }
    }
    held.forEach(k => s.keyUp(k));
}
process.exit(0);
