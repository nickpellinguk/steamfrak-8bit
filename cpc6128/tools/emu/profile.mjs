// Where the time goes: the game played on the Z80 interpreter (cpuz80.mjs), timed as on a CPC.
// MAME starts a level (Trogg can't die) and holds it at the end of a frame (t_lock); the whole
// machine is copied (the base 64K, the extra banks, the screens), and the interpreter carries on
// from there: the frame loop, the gate array's bank switching, its interrupts (six a frame, the
// first at vertical sync, which counts it and reads the keyboard; a frame every 19,968 µs), and
// HALT waiting for the next.
//
// Prints the frame rate, and the time spent in each routine (by its label).
//
//   ./build.sh && CPC_ROMS=... node tools/emu/profile.mjs [room_A_1 ...] [--frames=N] [--walk] [--top=N] [--fine] [--check]
// (--fine: by local labels too. --check: keys pressed at random, and every tidy checked: it must
// leave its buffer exactly as it was before that buffer's draw log was drawn, as at
// frame_loop.slow_done in its last frame; it counts the tidies done while the other buffer
// was still waiting to be shown, chasing the raster.)
import { symbols, run, boot, ROOT } from './mame.mjs';
import { readFileSync } from 'fs';
import { join } from 'path';
import { CpuZ80 } from './cpuz80.mjs';

const sym = symbols();
const args = process.argv.slice(2);
const opt = k => { const a = args.find(s => s.startsWith('--' + k)); return a ? (a.split('=')[1] ?? true) : undefined; };
const FRAMES = +(opt('frames') || 200), WALK = !!opt('walk'), TOP = +(opt('top') || 25), CHECK = !!opt('check');
let allBad = 0;
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
    constructor(m, stores, cfg) { super(m); this.stores = stores; this.cfg = cfg; this.haltWaits = true; this.vsync = false; }
    in(port) { return (port >> 8) === 0xF5 ? (this.vsync ? 0xFF : 0xFE) : 0xFF; }     // (PPI port B: bit 0 = vertical sync)
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
    let held = WALK ? [[sym.key_x >> 3, 1 << (sym.key_x & 7)]] : [];
    // (--check: the tidy check, and keys at random)
    const KEYS = ['key_z', 'key_x', 'key_o', 'key_k', 'key_p', 'key_space'].map(k => [sym[k] >> 3, 1 << (sym[k] & 7)]);
    let seed = 12345, nextKeys = 0;
    const random = n => { seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF; return seed % n; };
    const page = b => (b ? 0xC000 : 0x8000), snap = [null, null];
    let checks = 0, chased = 0, bad = 0, tidying = -1, wasPending = 0;
    // (the logic bank's variables, wherever it is)
    const logicCfg = sym.logic_bank + 4;
    const lb = a => (c.cfg === logicCfg ? m[a] : stores[logicCfg][a - 0x4000]);
    const frames0 = lb(sym.frames_drawn) | lb(sym.frames_drawn + 1) << 8;
    const time = new Map();
    const VSYNC = 19968, BAND = VSYNC / 6;            // (an interrupt every 52 lines, the first 2 into vertical sync)
    let nextIrq = BAND, band = 1, inIrq = false, irqSp = 0;
    const frames = () => ((lb(sym.frames_drawn) | lb(sym.frames_drawn + 1) << 8) - frames0) & 0xFFFF;
    while (frames() < FRAMES) {
        if (!inIrq && c.us >= nextIrq) {              // the gate array's interrupt (IM 1)
            nextIrq += BAND; c.vsync = band === 0; band = (band + 1) % 6;
            if (c.halted) { c.halted = false; c.pc = (c.pc + 1) & 0xFFFF; }
            c.push(c.pc); c.pc = 0x38; inIrq = true; irqSp = c.sp;
        }
        const pc = c.pc, inBank = pc >= 0x4000 && pc < 0x8000;
        if (CHECK) {
            if (c.us >= nextKeys) {
                nextKeys = c.us + 6 * VSYNC;
                held = KEYS.filter(() => random(3) === 0); m[sym.keys_changed] = 1;
            }
            if (pc === sym['frame_loop.slow_done']) { const b = m[sym.back]; snap[b] = m.slice(page(b), page(b) + 0x4000); }
            else if (pc === sym.redraw) { snap[0] = snap[1] = null; tidying = -1; }
            else if (pc === sym.tidy) {
                const t = m[sym.back] ^ 1;
                tidying = lb(sym.won) || (lb(sym.dead) && lb(sym.bfrak + t)) ? -1 : t;
                wasPending = m[sym.flip_pending];
            } else if (pc === sym.frame_loop && tidying >= 0) {
                if (snap[tidying]) {
                    let diff = 0, first = -1;
                    for (let i = 0; i < 0x4000; i++) if (m[page(tidying) + i] !== snap[tidying][i]) { diff++; if (first < 0) first = i; }
                    checks++; if (wasPending) chased++;
                    if (diff) { bad++; if (bad <= 5) console.log(`  buffer ${tidying}: ${diff} bytes differ after tidying (the first at #${(page(tidying) + first).toString(16)})${wasPending ? ', chasing' : ''}`); }
                }
                tidying = -1;
            }
        }
        const t = c.timedStep();
        const key = inBank && c.cfg !== logicCfg ? `(code in bank ${c.cfg - 4})` : pc;
        time.set(key, (time.get(key) || 0) + t);
        if (inIrq && c.sp === irqSp + 2 && c.pc !== 0x38 && pc !== 0x38) {
            inIrq = false;
            for (const [row, mask] of held) m[sym.keys + row] |= mask;
        }
    }
    const total = c.us;
    if (CHECK) { console.log(`${room}: ${checks} tidies checked, ${chased} of them chasing the raster, ${bad} wrong`); allBad += bad; continue; }
    const byName = {};
    for (const [k, t] of time) { const n = typeof k === 'string' ? k : nameOf(k); byName[n] = (byName[n] || 0) + t; }
    console.log(`${room}${WALK ? ' (walking right)' : ''}: ${(FRAMES / (total / 1e6)).toFixed(1)} frames a second ` +
                `(${(total / FRAMES / 1000).toFixed(1)} ms a frame)`);
    for (const [n, t] of Object.entries(byName).sort((a, b) => b[1] - a[1]).slice(0, TOP))
        console.log(`  ${(100 * t / c.us).toFixed(1).padStart(5)}%  ${(t / FRAMES / 1000).toFixed(2).padStart(6)} ms a frame  ${n}`);
}
if (CHECK) { console.log(allBad ? `${allBad} wrong` : 'all right'); process.exit(allBad ? 1 : 0); }
