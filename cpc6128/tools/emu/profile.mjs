// Where the time goes: the game played on the Z80 interpreter (cpuz80.mjs), timed as on a CPC.
// MAME starts a level (Trogg can't die) and holds it at the end of a frame (t_lock); the whole
// machine is copied (the base 64K, the extra banks, the screens), and the interpreter carries on
// from there: the frame loop, the gate array's bank switching, an interrupt each vertical sync
// (counting it, and reading the keyboard), and a vertical sync every 19,968 µs.
//
// Prints the frame rate, and the time spent in each routine (by its label).
//
//   ./build.sh && CPC_ROMS=... node tools/emu/profile.mjs [room_A_1 ...] [--frames=N] [--walk] [--top=N] [--fine]
// (--fine: by local labels too)
import { symbols, run, boot, ROOT } from './mame.mjs';
import { readFileSync } from 'fs';
import { join } from 'path';
import { CpuZ80 } from './cpuz80.mjs';

const sym = symbols();
const args = process.argv.slice(2);
const opt = k => { const a = args.find(s => s.startsWith('--' + k)); return a ? (a.split('=')[1] ?? true) : undefined; };
const FRAMES = +(opt('frames') || 200), WALK = !!opt('walk'), TOP = +(opt('top') || 25);
const NAMES = ['room_0', ...'ABCDEF'.split('').flatMap(c => [1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => `room_${c}_${n}`))];
const only = args.filter(a => a.startsWith('room'));
const rooms = only.length ? only : ['room_A_1', 'room_B_3', 'room_C_6', 'room_D_1'];

// the labels, for naming where the time goes (the low RAM's, and the logic bank's)
const labels = [];
for (const line of readFileSync(join(ROOT, 'build/frak.sym'), 'utf8').split('\n')) {
    const m = line.match(/^(\S+)\s+#([0-9A-F]+)\s+B\d+\s+L/i);
    if (m && (opt('fine') || !m[1].includes('.'))) labels.push([parseInt(m[2], 16), m[1].toLowerCase()]);
}
labels.sort((a, b) => a[0] - b[0]);
const nameOf = pc => { let n = '?'; for (const [a, l] of labels) { if (a <= pc) n = l; else break; } return n; };

// A CPC: the base 64K, with an extra bank (or the base RAM's) at #4000-#7FFF as the gate array says
class Cpc extends CpuZ80 {
    constructor(m, stores, cfg) { super(m); this.stores = stores; this.cfg = cfg; }
    out(port, v) {
        if ((port >> 8) !== 0x7F || (v & 0xC0) !== 0xC0) return;
        const cfg = v & 7 ? (v & 7) : 0;
        if (cfg === this.cfg) return;
        this.stores[this.cfg].set(this.m.subarray(0x4000, 0x8000));
        this.m.set(this.stores[cfg], 0x4000);
        this.cfg = cfg;
    }
}

for (const room of rooms) {
    const li = NAMES.indexOf(room);
    const cfgOf = n => sym.ram_bank + n;
    const steps = [...boot, `poke ${sym.t_lock} 1`, `poke ${sym.t_arg} ${li}`,
        `bankpoke ${cfgOf(sym.logic_bank)} ${sym.trogg_dies} ${0xC9} ${sym.ga_ram}`, `poke ${sym.t_cmd} 13`];
    for (let f = 0; f < 30; f++) steps.push(`waitfor ${sym.t_frame} 1 1000`, `poke ${sym.t_frame} 0`);
    steps.push(`waitfor ${sym.t_frame} 1 1000`, 'dump all 0 65536', `bankdump base 192 16384 16384 ${sym.ga_ram}`);
    for (let b = 0; b < 4; b++) steps.push(`bankdump b${b} ${cfgOf(b)} 16384 16384 ${sym.ga_ram}`);
    const r = run(steps, { seconds: 600 });
    const m = new Uint8Array(65536);
    m.set(r.dump('all'), 0);
    const stores = { 0: new Uint8Array(r.dump('base')) };
    for (let b = 0; b < 4; b++) stores[4 + b] = new Uint8Array(r.dump(`b${b}`));
    const cfg0 = m[sym.ga_ram] & 7;
    const c = new Cpc(m, stores, cfg0);
    m[sym.t_lock] = 0; m[sym.t_frame] = 0;
    c.pc = sym['frame_loop.hold'];
    c.sp = 0x3FF0;
    // (walking right: X held down, put back after each keyboard scan)
    const held = WALK ? [[sym.key_x >> 3, 1 << (sym.key_x & 7)]] : [];
    // (the logic bank's variables, wherever it is)
    const logicCfg = sym.logic_bank + 4;
    const lb = a => (c.cfg === logicCfg ? m[a] : stores[logicCfg][a - 0x4000]);
    const frames0 = lb(sym.frames_drawn) | lb(sym.frames_drawn + 1) << 8;
    const time = new Map();
    const VSYNC = 19968;
    let nextSync = VSYNC, inIrq = false, irqSp = 0;
    const frames = () => ((lb(sym.frames_drawn) | lb(sym.frames_drawn + 1) << 8) - frames0) & 0xFFFF;
    while (frames() < FRAMES) {
        if (!inIrq && c.us >= nextSync) {             // the vertical sync's interrupt (IM 1)
            nextSync += VSYNC;
            c.push(c.pc); c.pc = 0x38; inIrq = true; irqSp = c.sp;
        }
        const pc = c.pc, inBank = pc >= 0x4000 && pc < 0x8000;
        const t = c.timedStep();
        const key = inBank && c.cfg !== logicCfg ? `(code in bank ${c.cfg - 4})` : pc;
        time.set(key, (time.get(key) || 0) + t);
        if (inIrq && c.sp === irqSp + 2 && c.pc !== 0x38 && pc !== 0x38) {
            inIrq = false;
            for (const [row, mask] of held) m[sym.keys + row] |= mask;
        }
    }
    // the other five interrupts each frame (they only look for vertical sync): about 30 µs each
    const total = c.us + 5 * 30 * (c.us / VSYNC);
    const byName = {};
    for (const [k, t] of time) { const n = typeof k === 'string' ? k : nameOf(k); byName[n] = (byName[n] || 0) + t; }
    console.log(`${room}${WALK ? ' (walking right)' : ''}: ${(FRAMES / (total / 1e6)).toFixed(1)} frames a second ` +
                `(${(total / FRAMES / 1000).toFixed(1)} ms a frame)`);
    for (const [n, t] of Object.entries(byName).sort((a, b) => b[1] - a[1]).slice(0, TOP))
        console.log(`  ${(100 * t / c.us).toFixed(1).padStart(5)}%  ${(t / FRAMES / 1000).toFixed(2).padStart(6)} ms a frame  ${n}`);
}
