// Where the time goes, playing (for the optimisation pass after the first milestone): ephl plays
// each level, Trogg unable to die, standing for 10 seconds then walking right for 10 (as
// fps.mjs), noting where the Z80 is every 32us (ephl's profile step: with the video RAM's wait
// states, so the real machine's timing). Each sample is put down to the routine it's in (the
// symbols of the low RAM, the front end, the logic segment or the loader, by the segment paged in
// where the PC is; the compiled meanie's code, in #FE's window, as "(compiled meanie)"), and the
// routines that take the most are listed, with the frames drawn a second.
//
//   ./build.sh && EP_ROMS=... node tools/emu/profile.mjs [room_A_1 ...] [--top=N] [--locals]
import { symbols, run, boot, loadFiles, ROOT } from './harness.mjs';
import { readFileSync } from 'fs';
import { join } from 'path';

const sym = symbols();
const args = process.argv.slice(2);
const opt = k => { const a = args.find(s => s.startsWith('--' + k)); return a ? (a.split('=')[1] ?? true) : undefined; };
const TOP = +(opt('top') || 25), LOCALS = !!opt('locals'), SECONDS = 10;
const NAMES = ['room_0', ...'ABCDEF'.split('').flatMap(c => [1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => `room_${c}_${n}`))];
const only = args.filter(a => a.startsWith('room'));
const rooms = only.length ? only : ['room_A_1', 'room_B_8', 'room_C_5', 'room_D_9', 'room_E_1'];

// ---- the symbols, by section (the symbol file is in the order they were assembled)
const all = [];
for (const line of readFileSync(join(ROOT, 'build/frak.sym'), 'utf8').split('\n')) {
    const m = line.match(/^(\S+)\s+#([0-9A-F]+)\s+B\d+\s+L/);
    if (m) all.push([m[1].toLowerCase(), parseInt(m[2], 16)]);
}
const idx = name => all.findIndex(([n]) => n === name);
const part = (from, to) => all.slice(from, to).filter(([n]) => LOCALS || !n.includes('.')).sort((a, b) => a[1] - b[1]);
const sections = {
    low: part(0, idx('front_start')),
    front: part(idx('front_start'), idx('front_end_') + 1),
    logic: part(idx('front_packed_end') + 1, idx('end_logic_bank') + 1),
    loader: part(idx('loader_start'), idx('loader_end') + 1),
};
function routine(pc, seg) {
    let table;
    if (pc < 0x4000) table = sections.low;
    else if (pc < 0x8000) {
        if (seg === sym.seg_logic) table = sections.logic;
        else if (seg === sym.seg_cache) table = sections.front;
        else if (seg === sym.seg_jit && pc >= sym.jit_org) return '(compiled meanie)';
        else return `(#${pc.toString(16)} in segment #${seg.toString(16)})`;
    } else if (seg === sym.seg_jit && pc >= sym.loader_start) table = sections.loader;
    else return `(#${pc.toString(16)} in segment #${seg.toString(16)})`;
    let best = null;
    for (const [n, a] of table) { if (a <= pc) best = n; else break; }
    return best || '?';
}

const totals = new Map();
let samples = 0;
for (const room of rooms) {
    const li = NAMES.indexOf(room), KEY_X = sym.key_x, fd = sym.frames_drawn - 0x4000;
    const steps = [...boot(), ...loadFiles(sym), `poke ${sym.t_arg} ${li}`,
        `spoke ${sym.seg_logic} ${sym.trogg_dies - 0x4000} ${0xC9}`, `poke ${sym.t_cmd} 13`,
        'wait 550', `speek f0 ${sym.seg_logic} ${fd} 2`, `profile standing ${SECONDS * 50}`,
        `speek f1 ${sym.seg_logic} ${fd} 2`, `key ${KEY_X >> 3} ${1 << (KEY_X & 7)} 1`,
        `profile walking ${SECONDS * 50}`, `speek f2 ${sym.seg_logic} ${fd} 2`];
    const r = run(steps, { seconds: 600 });
    const f = k => r.peeks[k][0] | r.peeks[k][1] << 8;
    const here = new Map();
    let n = 0;
    for (const label of ['standing', 'walking']) {
        const line = r.log.match(new RegExp(`^OUT profile ${label} (.*)$`, 'm'))[1];
        for (const item of line.split(' ')) {
            const [pc, seg, c] = item.split(',').map(Number);
            const name = routine(pc, seg);
            here.set(name, (here.get(name) || 0) + c);
            totals.set(name, (totals.get(name) || 0) + c);
            n += c;
        }
    }
    samples += n;
    const top = [...here].sort((a, b) => b[1] - a[1]).slice(0, 5).map(([k, v]) => `${k} ${(100 * v / n).toFixed(0)}%`).join(', ');
    console.log(`${room.replace('room_', '')}: ${((f('f1') - f('f0')) / SECONDS).toFixed(1)} frames a second standing, ` +
                `${(((f('f2') - f('f1')) & 0xFFFF) / SECONDS).toFixed(1)} walking; ${top}`);
}
console.log(`\nAll ${rooms.length} levels (${samples} samples, every 32us):`);
console.log('| Routine | Time |');
console.log('| --- | --- |');
for (const [k, v] of [...totals].sort((a, b) => b[1] - a[1]).slice(0, TOP)) console.log(`| ${k} | ${(100 * v / samples).toFixed(1)}% |`);
