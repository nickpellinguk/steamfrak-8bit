// The platform/ladder connection finder for the BBC Master version: does the 6502 code move
// Trogg as the GameMaker original does?
//
//   ./build.sh && cd tools/emu && node connections8.mjs [room_A_1 ...] [--detail]
//   node connections8.mjs --trace=room_A_1,572,83,1       (one jump, tick by tick)
//
// It uses the steamfrak repository's tools/connections.js (STEAMFRAK, default ../steamfrak
// alongside this one): its port of the original's GraphFind search, and its transcription of
// the original's scripts (with GameMaker's epsilon comparisons), on the rooms of the GameMaker
// project (../gamemakerstudio-frak alongside that).
//
// The 6502 side is the game's own code: for each level, jsbeeb boots the disc and loads the
// level, then the memory it's playing from (main RAM and bank 6) is copied, and trogg_standing,
// trogg_falling and trogg_climbing are run on a small 6502 interpreter (cpu6502.mjs) against
// that copy, from every start, as the search asks. Moving platforms are put back where they
// start (as the search has them).
//
// The 6502 version keeps Trogg's y in pixels and twentieths of a pixel, and his y velocity in
// twentieths of a pixel a tick: everything the original's y and velocity can be (gravity 0.05,
// a jump 1.25, and y rounded to multiples of 0.05), as whole numbers.
import { MachineSession } from 'jsbeeb';
import { readFileSync } from 'fs';
import { createRequire } from 'module';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
import { Cpu6502 } from './cpu6502.mjs';

const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const STEAMFRAK = process.env.STEAMFRAK || resolve(REPO, '../steamfrak');
const require = createRequire(import.meta.url);
const conn = require(resolve(STEAMFRAK, 'tools/connections.js'));
const args = process.argv.slice(2);
const opt = k => { const a = args.find(s => s.startsWith('--' + k)); return a ? (a.split('=')[1] ?? true) : undefined; };
const DETAIL = !!opt('detail');

const out = readFileSync(REPO + '/build/assembler.txt', 'utf8');
const sym = {};
for (const [, k, v] of out.match(/SYMBOLS(.*)/)[1].matchAll(/(\w+)\s*&([0-9A-F]+)/g)) sym[k] = parseInt(v, 16);
const ST = { STAND: 0, WALK: 1, FALL: 2, CLIMB: 3 };
const NAMES = ['room_0', ...'ABCDEF'.split('').flatMap(c => [1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => `room_${c}_${n}`))];

// ---- Boot the disc, and copy the memory each level plays from
const s = new MachineSession('Master', { discImage: REPO + '/build/frak.ssd' });
await s.initialise(); await s.boot(30); await s.autoboot();
const cpu = s._machine.processor;
const bank = (b, a) => cpu.ramRomOs[cpu.romOffset + b * 16384 + a - 0x8000];
// (until the game is running: its vertical sync counter counting, and the attract tune on)
for (let t = 0, v = -1; t < 100; t++) {
    if (cpu.readmem(sym.snd_tune) === 5 && cpu.readmem(sym.vsyncs) !== v && v >= 0) break;
    v = cpu.readmem(sym.vsyncs); await s.runFrames(20);
}
await s.runFrames(100);
for (let i = 0; i < 2; i++) { s.keyDown('Space'); await s.runFrames(5); s.keyUp('Space'); await s.runFrames(60); }
await s.runFrames(300);

async function levelMemory(li) {
    for (let t = 0; t < 400 && cpu.readmem(sym.cur_level) !== li; t++) {
        if (t % 40 === 0) { cpu.writemem(sym.cur_level, (li + 54) % 55); cpu.writemem(sym.won, 1); }
        await s.runFrames(5);
    }
    await s.runFrames(300);
    if (cpu.readmem(sym.cur_level) !== li) throw new Error('level ' + li + ' did not load');
    const m = new Uint8Array(65536);
    for (let a = 0; a < 0x8000; a++) m[a] = cpu.readmem(a);
    for (let a = 0x8000; a < 0xC000; a++) m[a] = bank(6, a);
    for (let a = 0xC000; a < 0x10000; a++) m[a] = cpu.readmem(a);
    // moving platforms back where they start
    for (let i = 0; i < m[sym.num_plats]; i++) {
        m[sym.plat_xl + i] = m[sym.plat_x0l + i]; m[sym.plat_xh + i] = m[sym.plat_x0h + i];
        m[sym.plat_yl + i] = m[sym.plat_y0l + i]; m[sym.plat_yh + i] = m[sym.plat_y0h + i];
    }
    return m;
}

// ---- The 6502 engine (the same calls as connections.js's engines)
function beebEngine(mem) {
    const c = new Cpu6502(mem);
    const r8 = a => mem[a], w8 = (a, v) => { mem[a] = v & 0xFF; };
    const r16 = (lo, hi) => mem[lo] | mem[hi] << 8;
    const w16 = (a, v) => { mem[a] = v & 0xFF; mem[a + 1] = (v >> 8) & 0xFF; };
    const s8 = v => (v > 127 ? v - 256 : v);
    const s16 = v => (v > 32767 ? v - 65536 : v);
    // (y in pixels and twentieths: ty + tyf / 20)
    const tx = () => s16(r16(sym.tx, sym.tx + 1)), ty = () => s16(r16(sym.ty, sym.ty + 1)) + r8(sym.tyf) / 20;
    function setup(state, x, y, xm, ym) {
        const py = Math.floor(y + 1e-9);
        w8(sym.tstate, state); w16(sym.tx, x); w16(sym.ty, py); w8(sym.tyf, Math.round((y - py) * 20));
        w8(sym.xmove, xm); w8(sym.ymove, ym); w8(sym.doyoyo, 0); w8(sym.dead, 0);
        w8(sym.cur_plat, 255); w8(sym.res_found, 0);
    }
    const fallState = () => ({ x: tx(), y: ty(), xvel: s8(r8(sym.xvel)), tv: s8(r8(sym.tv)) });
    const n = mem[sym.num_plats], nl = mem[sym.num_ladders];
    const arr = (k, lo, hi) => [...Array(k).keys()].map(i => s16(mem[lo + i] | (hi ? mem[hi + i] << 8 : 0)));
    return {
        name: 'beeb',
        platforms: () => ({ n, x: arr(n, sym.plat_xl, sym.plat_xh), y: arr(n, sym.plat_yl, sym.plat_yh), w: arr(n, sym.plat_w) }),
        ladders: () => ({ n: nl, x: arr(nl, sym.lad_xl, sym.lad_xh),
                          y: arr(nl, sym.lad_yl, sym.lad_yh), h: arr(nl, sym.lad_hl, sym.lad_hh) }),
        standing(x, y, xm, ym) {
            setup(ST.STAND, x, y, xm, ym);
            c.call(sym.trogg_standing);
            const st = r8(sym.tstate);
            return { x: tx(), y: ty(), state: fallState(), dofall: st === ST.FALL, doclimb: st === ST.CLIMB,
                     plat: st <= ST.WALK ? r8(sym.cur_plat) : -1, ladder: st === ST.CLIMB ? r8(sym.res_i) : -1 };
        },
        falling(f, xm, ym) {
            setup(ST.FALL, f.x, f.y, xm, ym);
            w8(sym.xvel, f.xvel); w8(sym.tv, f.tv);
            c.call(sym.trogg_falling);
            const st = r8(sym.tstate);
            return { x: tx(), y: ty(), state: fallState(), doclimb: st === ST.CLIMB, dostand: st === ST.STAND,
                     dodie: r8(sym.dead) !== 0, plat: st === ST.STAND ? r8(sym.res_i) : -1,
                     ladder: st === ST.CLIMB ? r8(sym.res_i) : -1 };
        },
        // (falling at 1.6 pixels a tick or faster)
        tooFast: f => f.tv <= -32,
        climbing(x, y, xm, ym) {
            setup(ST.CLIMB, x, y, xm, ym);
            c.call(sym.trogg_climbing);
            const st = r8(sym.tstate);
            const moved = r8(sym.res_found) && s16(r16(sym.res_y, sym.res_y + 1)) + r8(sym.res_yf) / 20 !== y;
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
    const E = beebEngine(await levelMemory(NAMES.indexOf(room)));
    conn.trace([conn.gmsEngine(room), E], x, y, dir, +opt('ticks') || 200);
    process.exit(0);
}
const only = args.filter(a => a.startsWith('room'));
let totals = { nOut: 0, nEnd: 0, nGrab: 0, nEdge: 0 }, instr = 0, t0 = Date.now();
for (const room of (only.length ? only : NAMES)) {
    const E = beebEngine(await levelMemory(NAMES.indexOf(room)));
    const c = conn.compare(conn.findConnections(conn.gmsEngine(room)), conn.findConnections(E), 'gms', 'beeb', DETAIL);
    for (const k in totals) totals[k] += c[k];
    instr += E.cpu.count;
    console.log(`${room}: ${c.summary}`);
    for (const l of c.lines) console.log(l);
}
console.log(`\nIn all: ${totals.nOut} starts differ (${totals.nEnd} end differently, ${totals.nGrab} grab differently) ` +
            `and ${totals.nEdge} connections differ (${(instr / 1e6).toFixed(0)}M 6502 instructions, ${((Date.now() - t0) / 1000).toFixed(0)}s)`);
process.exit(0);
