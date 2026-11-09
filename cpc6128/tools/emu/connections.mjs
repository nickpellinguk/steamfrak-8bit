// Phase 5's test: does the Z80 code move Trogg as the GameMaker original does? The CPC version
// of the BBC version's tools/emu/connections8.mjs.
//
//   ./build.sh && CPC_ROMS=... node tools/emu/connections.mjs [room_A_1 ...] [--detail]
//   node tools/emu/connections.mjs --trace=room_A_1,572,83,1       (one jump, tick by tick)
//
// It uses the steamfrak repository's tools/connections.js (STEAMFRAK, default ../steamfrak
// alongside this one): its port of the original's GraphFind search, and its transcription of
// the original's scripts (with GameMaker's epsilon comparisons), on the rooms of the GameMaker
// project (../gamemakerstudio-frak alongside that).
//
// The Z80 side is the game's own code: MAME runs the program, which loads each level
// (load_level, through the command mailbox), and the memory below #8000 is copied; then
// trogg_standing, trogg_falling and trogg_climbing are run on a small Z80 interpreter
// (cpuz80.mjs) against that copy, from every start, as the search asks. Moving platforms are
// put back where they start (as the search has them).
import { symbols, run, boot, ROOT } from './mame.mjs';
import { createRequire } from 'module';
import { readFileSync } from 'fs';
import { resolve, join } from 'path';
import { CpuZ80 } from './cpuz80.mjs';

const STEAMFRAK = process.env.STEAMFRAK || resolve(ROOT, '../../steamfrak');
const require = createRequire(import.meta.url);
const conn = require(resolve(STEAMFRAK, 'tools/connections.js'));
const args = process.argv.slice(2);
const opt = k => { const a = args.find(s => s.startsWith('--' + k)); return a ? (a.split('=')[1] ?? true) : undefined; };
const DETAIL = !!opt('detail');

const sym = symbols();
const ST = { STAND: 0, WALK: 1, FALL: 2, CLIMB: 3 };
const NAMES = ['room_0', ...'ABCDEF'.split('').flatMap(c => [1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => `room_${c}_${n}`))];
const expect = JSON.parse(readFileSync(join(ROOT, '../build/levels.json'), 'utf8'));

// ---- Load the levels asked for, on MAME, and copy the memory each plays from
const only = args.filter(a => a.startsWith('room'));
const rooms = opt('trace') ? [opt('trace').split(',')[0]] : (only.length ? only : NAMES);
const steps = [...boot, `poke ${sym.flip_rate} 0`];
let mode = 0;
const command = (cmd, arg) => steps.push(`poke ${sym.t_arg} ${arg}`, `poke ${sym.t_cmd} ${cmd}`, `waitfor ${sym.t_cmd} 0 3000`);
for (const room of rooms) {
    const li = NAMES.indexOf(room), m = expect[room].h > 256 ? 1 : 0;
    if (m !== mode) { steps.push(`poke ${sym.want_mode} ${m}`); command(9, m); mode = m; }
    command(11, li);
    steps.push(`dump m${li} 0 32768`);
}
const r = run(steps, { seconds: 1200 });
function levelMemory(li) {
    const m = new Uint8Array(65536);
    m.set(r.dump(`m${li}`), 0);
    // moving platforms back where they start
    for (let i = 0; i < m[sym.num_plats]; i++) {
        const p = sym.plats + i * sym.plt_size;
        m[p + sym.plt_xl] = m[p + sym.plt_x0l]; m[p + sym.plt_xh] = m[p + sym.plt_x0h];
        m[p + sym.plt_yl] = m[p + sym.plt_y0l]; m[p + sym.plt_yh] = m[p + sym.plt_y0h];
    }
    return m;
}

// ---- The Z80 engine (the same calls as connections.js's engines)
function cpcEngine(mem) {
    const c = new CpuZ80(mem);
    const r8 = a => mem[a], w8 = (a, v) => { mem[a] = v & 0xFF; };
    const r16 = a => mem[a] | mem[a + 1] << 8;
    const w16 = (a, v) => { mem[a] = v & 0xFF; mem[a + 1] = (v >> 8) & 0xFF; };
    const s8 = v => (v > 127 ? v - 256 : v);
    const s16 = v => (v > 32767 ? v - 65536 : v);
    // (y in pixels and twentieths: ty + tyf / 20)
    const tx = () => s16(r16(sym.tx)), ty = () => s16(r16(sym.ty)) + r8(sym.tyf) / 20;
    function setup(state, x, y, xm, ym) {
        const py = Math.floor(y + 1e-9);
        w8(sym.tstate, state); w16(sym.tx, x); w16(sym.ty, py); w8(sym.tyf, Math.round((y - py) * 20));
        w8(sym.xmove, xm); w8(sym.ymove, ym); w8(sym.doyoyo, 0); w8(sym.dead, 0);
        w8(sym.cur_plat, 255); w8(sym.res_found, 0);
    }
    const call = a => c.call(a, { sp: 0x4000 });
    const fallState = () => ({ x: tx(), y: ty(), xvel: s8(r8(sym.xvel)), tv: s8(r8(sym.tv)) });
    const n = mem[sym.num_plats], nl = mem[sym.num_ladders];
    const field = (base, size, k, lo, hi) => [...Array(k).keys()].map(i => s16(mem[base + i * size + lo] | (hi !== undefined ? mem[base + i * size + hi] << 8 : 0)));
    return {
        name: 'cpc',
        platforms: () => ({ n, x: field(sym.plats, sym.plt_size, n, sym.plt_xl, sym.plt_xh),
                            y: field(sym.plats, sym.plt_size, n, sym.plt_yl, sym.plt_yh),
                            w: field(sym.plats, sym.plt_size, n, sym.plt_w) }),
        ladders: () => ({ n: nl, x: field(sym.ladders, sym.l_size, nl, sym.l_xl, sym.l_xh),
                          y: field(sym.ladders, sym.l_size, nl, sym.l_yl, sym.l_yh),
                          h: field(sym.ladders, sym.l_size, nl, sym.l_hl, sym.l_hh) }),
        standing(x, y, xm, ym) {
            setup(ST.STAND, x, y, xm, ym);
            call(sym.trogg_standing);
            const st = r8(sym.tstate);
            return { x: tx(), y: ty(), state: fallState(), dofall: st === ST.FALL, doclimb: st === ST.CLIMB,
                     plat: st <= ST.WALK ? r8(sym.cur_plat) : -1, ladder: st === ST.CLIMB ? r8(sym.res_i) : -1 };
        },
        falling(f, xm, ym) {
            setup(ST.FALL, f.x, f.y, xm, ym);
            w8(sym.xvel, f.xvel); w8(sym.tv, f.tv);
            call(sym.trogg_falling);
            const st = r8(sym.tstate);
            return { x: tx(), y: ty(), state: fallState(), doclimb: st === ST.CLIMB, dostand: st === ST.STAND,
                     dodie: r8(sym.dead) !== 0, plat: st === ST.STAND ? r8(sym.res_i) : -1,
                     ladder: st === ST.CLIMB ? r8(sym.res_i) : -1 };
        },
        // (falling at 1.6 pixels a tick or faster)
        tooFast: f => f.tv <= -32,
        climbing(x, y, xm, ym) {
            setup(ST.CLIMB, x, y, xm, ym);
            call(sym.trogg_climbing);
            const st = r8(sym.tstate);
            const moved = r8(sym.res_found) && s16(r16(sym.res_y)) + r8(sym.res_yf) / 20 !== y;
            return { x: tx(), y: ty(), state: fallState(), dofall: st === ST.FALL, dostand: st === ST.STAND,
                     plat: st === ST.STAND ? r8(sym.res_i) : -1,
                     ladder: st === ST.CLIMB && moved ? r8(sym.res_i) : -1 };
        },
        cpu: c,
    };
}

// ---- Compare
if (opt('trace')) {
    const [room, x, y, dir] = opt('trace').split(',');
    const E = cpcEngine(levelMemory(NAMES.indexOf(room)));
    conn.trace([conn.gmsEngine(room), E], x, y, dir, +opt('ticks') || 200);
    process.exit(0);
}
let totals = { nOut: 0, nEnd: 0, nGrab: 0, nEdge: 0 }, instr = 0, t0 = Date.now();
for (const room of rooms) {
    const E = cpcEngine(levelMemory(NAMES.indexOf(room)));
    const c = conn.compare(conn.findConnections(conn.gmsEngine(room)), conn.findConnections(E), 'gms', 'cpc', DETAIL);
    for (const k in totals) totals[k] += c[k];
    instr += E.cpu.count;
    console.log(`${room}: ${c.summary}`);
    for (const l of c.lines) console.log(l);
}
console.log(`\nIn all: ${totals.nOut} starts differ (${totals.nEnd} end differently, ${totals.nGrab} grab differently) ` +
            `and ${totals.nEdge} connections differ (${(instr / 1e6).toFixed(0)}M Z80 instructions, ${((Date.now() - t0) / 1000).toFixed(0)}s)`);
process.exit(0);
