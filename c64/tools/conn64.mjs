// Does the C64's 6502 code move Trogg as the GameMaker original does, on the C64's A_1?
//
//   node conn64.mjs [--detail] [--trace=X,Y,DIR [--ticks=N]]     (after build.mjs)
//
// The other side is the steamfrak repository's tools/connections.js (STEAMFRAK, default
// ../../../steamfrak), as for the BBC version (../../tools/emu/connections8.mjs): its port of the
// original's GraphFind search, and its transcription of the original's scripts (with GameMaker's
// epsilon comparisons), run on a GameMaker room. Here that's a copy of A_1's room (from the
// GameMaker project, GMS, default ../../../gamemakerstudio-frak) with each platform and ladder
// moved to where the C64 has it (build/geometry.json): so the original's own rules, on the C64's
// level. The C64 side is the game's code itself: build/frak64.prg in a 64K memory, its
// trogg_standing, trogg_falling and trogg_climbing run on a small 6502 interpreter
// (../../tools/emu/cpu6502.mjs) from every start the search asks for: every pixel of every
// platform and every point of every ladder, holding every key.
import { readFileSync, writeFileSync, mkdirSync, symlinkSync, existsSync, rmSync } from 'fs';
import { createRequire } from 'module';
import { fileURLToPath } from 'url';
import { dirname, resolve, join } from 'path';
import { tmpdir } from 'os';
import { Cpu6502 } from '../../tools/emu/cpu6502.mjs';

const C64 = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const STEAMFRAK = process.env.STEAMFRAK || resolve(C64, '../../steamfrak');
const GMS = process.env.GMS || resolve(STEAMFRAK, '../gamemakerstudio-frak');
const args = process.argv.slice(2);
const opt = k => { const a = args.find(s => s.startsWith('--' + k)); return a ? (a.split('=')[1] ?? true) : undefined; };
const ROOM = 'room_A_1';

// ---- The room, moved: platforms to the C64's places, ladders with them
const loadYY = f => JSON.parse(readFileSync(f, 'utf8').replace(/,(\s*[}\]])/g, '$1'));
const parentOf = name => {
    for (let n = name; n; ) {
        const o = loadYY(join(GMS, 'objects', n, n + '.yy'));
        const p = o.parentObjectId ? o.parentObjectId.name : null;
        if (p === 'oPlatform' || p === 'oLadder') return p;
        n = p;
    }
    return null;
};
const lv = JSON.parse(readFileSync(resolve(C64, '../build/levels.json'), 'utf8'))[ROOM];
const geo = JSON.parse(readFileSync(join(C64, 'build/geometry.json'), 'utf8'));
const roomText = readFileSync(join(GMS, 'rooms', ROOM, ROOM + '.yy'), 'utf8');
const room = loadYY(join(GMS, 'rooms', ROOM, ROOM + '.yy'));
let nP = 0, nL = 0;
for (const layer of room.layers || []) for (const inst of layer.instances || []) {
    const p = parentOf(inst.objectId.name);
    if (p === 'oPlatform') {
        const k = lv.plat_x.findIndex((x, i) => x === Math.floor(inst.x) && lv.plat_y[i] === Math.floor(inst.y));
        if (k < 0) throw new Error(`platform at ${inst.x},${inst.y} not in levels.json`);
        inst.x = geo.plats[k].x; inst.y = geo.plats[k].y; nP++;
    } else if (p === 'oLadder') {
        const k = lv.lad_x.findIndex((x, i) => x === Math.floor(inst.x) && lv.lad_y[i] + lv.lad_ext[i] === Math.floor(inst.y));
        if (k < 0) throw new Error(`ladder at ${inst.x},${inst.y} not in levels.json`);
        inst.x = geo.lads[k].x; inst.y = geo.lads[k].y + geo.lads[k].ext; nL++;
    }
}
if (nP !== geo.plats.length || nL !== geo.lads.length) throw new Error(`moved ${nP} platforms and ${nL} ladders, not ${geo.plats.length} and ${geo.lads.length}`);
const G = join(tmpdir(), 'frak64-gms');
if (existsSync(G)) rmSync(G, { recursive: true });
mkdirSync(join(G, 'rooms', ROOM), { recursive: true });
for (const d of ['objects', 'sprites']) symlinkSync(join(GMS, d), join(G, d));
writeFileSync(join(G, 'rooms', ROOM, ROOM + '.yy'), JSON.stringify(room));
process.argv = [process.argv[0], process.argv[1], G];          // (connections.js: the project)
const conn = createRequire(import.meta.url)(resolve(STEAMFRAK, 'tools/connections.js'));

// ---- The C64 side
const sym = {};
for (const l of readFileSync(join(C64, 'build/frak64.lbl'), 'utf8').split('\n')) {
    const m = l.match(/^(\w+)\s*=\s*(\$?)([0-9a-fA-F]+)/);
    if (m) sym[m[1]] = parseInt(m[3], m[2] ? 16 : 10);
}
const ST = { STAND: 0, WALK: 1, FALL: 2, CLIMB: 3 };
function c64Engine() {
    const prg = readFileSync(join(C64, 'build/frak64.prg')), mem = new Uint8Array(65536);
    mem.set(prg.subarray(2), prg[0] | prg[1] << 8);
    const c = new Cpu6502(mem);
    const r8 = a => mem[a], w8 = (a, v) => { mem[a] = v & 0xFF; };
    const r16 = a => mem[a] | mem[a + 1] << 8, w16 = (a, v) => { mem[a] = v & 0xFF; mem[a + 1] = (v >> 8) & 0xFF; };
    const s8 = v => (v > 127 ? v - 256 : v), s16 = v => (v > 32767 ? v - 65536 : v);
    const tx = () => s16(r16(sym.tx)), ty = () => s16(r16(sym.ty)) + r8(sym.tyf) / 20;
    function setup(state, x, y, xm, ym) {
        const py = Math.floor(y + 1e-9);
        w8(sym.tstate, state); w16(sym.tx, x); w16(sym.ty, py); w8(sym.tyf, Math.round((y - py) * 20));
        w8(sym.xmove, xm); w8(sym.ymove, ym); w8(sym.doyoyo, 0); w8(sym.dead, 0); w8(sym.res_found, 0);
    }
    const fallState = () => ({ x: tx(), y: ty(), xvel: s8(r8(sym.xvel)), tv: s8(r8(sym.tv)) });
    const n = sym.NPLATS, nl = sym.NLADS;
    const arr = (k, lo, hi) => [...Array(k).keys()].map(i => s16(mem[lo + i] | (hi ? mem[hi + i] << 8 : 0)));
    return {
        name: 'c64',
        platforms: () => ({ n, x: arr(n, sym.plat_xl, sym.plat_xh), y: arr(n, sym.plat_yl, sym.plat_yh), w: arr(n, sym.plat_w) }),
        ladders: () => ({ n: nl, x: arr(nl, sym.lad_xl, sym.lad_xh), y: arr(nl, sym.lad_yl, sym.lad_yh), h: arr(nl, sym.lad_hl, sym.lad_hh) }),
        standing(x, y, xm, ym) {
            setup(ST.STAND, x, y, xm, ym);
            c.call(sym.trogg_standing);
            const st = r8(sym.tstate);
            return { x: tx(), y: ty(), state: fallState(), dofall: st === ST.FALL, doclimb: st === ST.CLIMB,
                     plat: st <= ST.WALK ? r8(sym.res_i) : -1, ladder: st === ST.CLIMB ? r8(sym.res_i) : -1 };
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
        tooFast: f => f.tv <= -32,          // (falling at 1.6 pixels a tick or faster)
        climbing(x, y, xm, ym) {
            setup(ST.CLIMB, x, y, xm, ym);
            c.call(sym.trogg_climbing);
            const st = r8(sym.tstate);
            const moved = r8(sym.res_found) && s16(r16(sym.res_y)) + r8(sym.res_yf) / 20 !== y;
            return { x: tx(), y: ty(), state: fallState(), dofall: st === ST.FALL, dostand: st === ST.STAND,
                     plat: st === ST.STAND ? r8(sym.res_i) : -1,
                     ladder: st === ST.CLIMB && moved ? r8(sym.res_i) : -1 };
        },
        cpu: c,
    };
}

const E = c64Engine();
if (opt('trace')) {
    const [x, y, dir] = opt('trace').split(',');
    conn.trace([conn.gmsEngine(ROOM), E], x, y, dir, +opt('ticks') || 200);
    process.exit(0);
}
const t0 = Date.now();
const c = conn.compare(conn.findConnections(conn.gmsEngine(ROOM)), conn.findConnections(E), 'gms', 'c64', !!opt('detail'));
console.log(`${ROOM} (moved: ${nP} platforms, ${nL} ladders): ${c.summary}`);
for (const l of c.lines) console.log(l);
console.log(`(${(E.cpu.count / 1e6).toFixed(1)}M 6502 instructions, ${((Date.now() - t0) / 1000).toFixed(0)}s)`);
