// Phase 5's second test: does the Z80 game logic do what the BBC version's does, tick for tick?
//
//   ./build.sh && CPC_ROMS=... node tools/emu/logic.mjs [room_A_1 ...] [--ticks=N] [--seed=N]
//
// For each level, both versions' memory is copied once the level has loaded: the BBC version's
// from jsbeeb (as its connections8.mjs does: main RAM, and sideways RAM bank 6, where its logic
// and level tables are), the CPC version's from MAME (the low RAM, and extra bank 2, where its
// logic is). Then both start the level (the CPC with its level_init; the BBC version's is gone
// by then, overwritten by the screen, so this does what it does) and run game_tick on small
// interpreters (cpu6502.mjs, cpuz80.mjs), with the same keys held - random, changing every few
// ticks - and the same difficulty and random seed. After every tick, everything the game logic
// keeps must be the same: Trogg, the yoyo, the platforms, the slow sprites, the moving objects
// (balloons, daggers and meanies flying off), what's been collected, the timers, the random
// number and the checkpoint. A death goes back to the checkpoint (restore_checkpoint) and
// finishing a level starts it again.
//
// Before each tick both show each slow sprite where it is (commit_one: the drawing does that,
// which comes in phase 6). The BBC version's keyboard and typed commands are left out (its
// read_keys, key_pressed and call5 return at once), and its redraw_all is left to this script.
import { symbols, run, boot, ROOT } from './mame.mjs';
import { readFileSync } from 'fs';
import { createRequire } from 'module';
import { resolve, join } from 'path';
import { pathToFileURL } from 'url';
import { CpuZ80 } from './cpuz80.mjs';

const BBC = resolve(ROOT, '..');
const { Cpu6502 } = await import(pathToFileURL(join(BBC, 'tools/emu/cpu6502.mjs')));
const jsbeebPath = createRequire(join(BBC, 'tools/emu/package.json')).resolve('jsbeeb');
const { MachineSession } = await import(pathToFileURL(jsbeebPath));

const args = process.argv.slice(2);
const opt = k => { const a = args.find(s => s.startsWith('--' + k)); return a ? (a.split('=')[1] ?? true) : undefined; };
const TICKS = +(opt('ticks') || 4000);
let seed = +(opt('seed') || 1);
const NAMES = ['room_0', ...'ABCDEF'.split('').flatMap(c => [1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => `room_${c}_${n}`))];
const only = args.filter(a => a.startsWith('room'));
const rooms = only.length ? only : NAMES;
const expect = JSON.parse(readFileSync(join(BBC, 'build/levels.json'), 'utf8'));

// ---- the symbols: the CPC's (build/frak.sym), the BBC's (beebasm -d -labels build/labels.txt)
const cs = symbols();
const bs = {};
for (const [, k, v] of readFileSync(join(BBC, 'build/labels.txt'), 'utf8').matchAll(/'(\w+)':(\d+)L/g)) bs[k] = +v;
const MAX_SLOW = cs.max_slow, MAX_PLATS = cs.max_plats, MAX_MOVERS = cs.max_movers, MAX_OBJECTS = cs.max_objects;

// ---- CPC: load each level on MAME, and copy the low RAM; and the logic bank, once
const steps = [...boot, `poke ${cs.flip_rate} 0`, `bankdump logic ${cs.ram_bank + cs.logic_bank} 16384 16384 ${cs.ga_ram}`];
let mode = 0;
const command = (cmd, arg) => steps.push(`poke ${cs.t_arg} ${arg}`, `poke ${cs.t_cmd} ${cmd}`, `waitfor ${cs.t_cmd} 0 3000`);
for (const room of rooms) {
    const li = NAMES.indexOf(room), m = expect[room].h > 256 ? 1 : 0;
    if (m !== mode) { steps.push(`poke ${cs.want_mode} ${m}`); command(9, m); mode = m; }
    command(11, li);
    steps.push(`dump m${li} 0 16384`);
}
const mame = run(steps, { seconds: 1200 });
const logicBank = mame.dump('logic');
function cpcMemory(li) {
    const m = new Uint8Array(65536);
    m.set(mame.dump(`m${li}`), 0);
    m.set(logicBank, 0x4000);
    return m;
}

// ---- BBC: boot the disc in jsbeeb, and copy the memory each level plays from
const s = new MachineSession('Master', { discImage: join(BBC, 'build/frak.ssd') });
await s.initialise(); await s.boot(30); await s.autoboot();
const cpu = s._machine.processor;
const bank = (b, a) => cpu.ramRomOs[cpu.romOffset + b * 16384 + a - 0x8000];
for (let t = 0, v = -1; t < 100; t++) {
    if (cpu.readmem(bs.snd_tune) === 5 && cpu.readmem(bs.vsyncs) !== v && v >= 0) break;
    v = cpu.readmem(bs.vsyncs); await s.runFrames(20);
}
await s.runFrames(100);
for (let i = 0; i < 2; i++) { s.keyDown('Space'); await s.runFrames(5); s.keyUp('Space'); await s.runFrames(60); }
await s.runFrames(300);
async function bbcMemory(li) {
    for (let t = 0; t < 400 && cpu.readmem(bs.cur_level) !== li; t++) {
        if (t % 40 === 0) { cpu.writemem(bs.cur_level, (li + 54) % 55); cpu.writemem(bs.won, 1); }
        await s.runFrames(5);
    }
    await s.runFrames(100);
    if (cpu.readmem(bs.cur_level) !== li) throw new Error('BBC: level ' + li + ' did not load');
    const m = new Uint8Array(65536);
    for (let a = 0; a < 0x8000; a++) m[a] = cpu.readmem(a);
    for (let a = 0x8000; a < 0xC000; a++) m[a] = bank(6, a);
    for (let a = 0xC000; a < 0x10000; a++) m[a] = cpu.readmem(a);
    // (no keyboard, typed commands or redrawing)
    m[bs.read_keys] = 0x60; m[bs.call5] = 0x60; m[bs.redraw_all] = 0x60;
    m.set([0xA9, 0x00, 0x60], bs.key_pressed);
    return m;
}

// ---- The two machines, seen the same way
function bbcSide(m) {
    const c = new Cpu6502(m);
    const at = (name, i = 0) => bs[name] + i;
    return {
        name: 'BBC', cpu: c, m,
        v: name => at(name),
        slow: (i, f) => at('s_' + f, i), plat: (i, f) => at('plat_' + f, i),
        cps: (i, f) => at('cps_' + f, i), cpp: (i, f) => at('cpp_' + f, i),
        mover: (i, f) => at('mv_' + f, i),
        cp: name => at('cp_' + name),
        level: (i, f) => at('sl_' + f, i),
        tick() { c.call(bs.game_tick); return c.a; },
        commit() { for (let x = 0; x < MAX_SLOW; x++) c.call(bs.commit_one, { x }); },
        restore() {
            c.call(bs.restore_checkpoint);
            this.resetPlay();
        },
        // (redraw_all's state part)
        resetPlay() {
            for (const k of ['tstate', 'tclimb', 'xvel', 'anim', 'dead', 'won', 'ud_db', 'lr_db', 'yo_db', 'cmd_live']) m[bs[k]] = 0;
            m[bs.yo_len] = m[bs.yo_len + 1] = 0;
            for (let i = 0; i < MAX_MOVERS; i++) m[bs.mv_active + i] = 0;
            this.commit();
        },
        // (level_init, then redraw_all)
        start() {
            const nd = m[bs.num_draw], ns = m[bs.num_slow];
            for (let i = 0; i < MAX_OBJECTS; i++) m[bs.alive + i] = i < nd ? 1 : 0;
            for (const k of ['keys_found', 'gems_found', 'have_cp', 'save_cp', 'restarts', 'bal_timer', 'dag_timer']) m[bs[k]] = 0;
            for (const k of ['lvl_ticks', 'win_ticks']) m[bs[k]] = m[bs[k] + 1] = 0;
            for (let x = 0; x < MAX_SLOW; x++) {
                m[bs.s_alive + x] = x < ns ? 1 : 0;
                m[bs.s_xf + x] = m[bs.s_yf + x] = 0;
                for (const [a, b] of [['s_xl', 'sl_x0l'], ['s_xh', 'sl_x0h'], ['s_yl', 'sl_y0l'], ['s_yh', 'sl_y0h'],
                                      ['s_vf', 'sl_vf'], ['s_vi', 'sl_vi'], ['s_vy', 'sl_vy'], ['s_wait', 'sl_wait']]) m[bs[a] + x] = m[bs[b] + x];
                if (m[bs.sl_kind + x] === cs.sl_hooter) m[bs.s_vf + x] = m[bs.s_vi + x] = 0;
            }
            for (let x = 0; x < MAX_PLATS; x++)
                for (const f of ['xl', 'xh', 'yl', 'yh']) m[bs['plat_' + f] + x] = m[bs['plat_' + f[0] + '0' + f[1]] + x];
            m[bs.cur_plat] = m[bs.carry] = 255; m[bs.dropped] = 0;
            m[bs.tx] = m[bs.trogg_x0]; m[bs.tx + 1] = m[bs.trogg_x0 + 1];
            m[bs.ty] = m[bs.trogg_y0]; m[bs.ty + 1] = m[bs.trogg_y0 + 1];
            m[bs.tface] = m[bs.tyf] = m[bs.tv] = 0;
            c.call(bs.save_checkpoint);
            this.resetPlay();
        },
    };
}
function cpcSide(m) {
    const c = new CpuZ80(m);
    const call = a => c.call(a, { sp: 0x4000 });
    // (the CPC keeps a checkpoint's keys, gems, carry, dropped, balloon and dagger timers together)
    const cpOff = { keys: 0, gems: 1, carry: 2, dropped: 3, bal: 4, dag: 5 };
    const srOff = { alive: cs.sr_alive, xf: cs.sr_xf, xl: cs.sr_xl, xh: cs.sr_xh, yf: cs.sr_yf, yl: cs.sr_yl, yh: cs.sr_yh,
                    vf: cs.sr_vf, vi: cs.sr_vi, vy: cs.sr_vy, wait: cs.sr_wait };
    const mvOff = { active: cs.m_active, img: cs.m_img, xf: cs.m_xf, xl: cs.m_xl, xh: cs.m_xh, yf: cs.m_yf, yl: cs.m_yl,
                    yh: cs.m_yh, vxf: cs.m_vxf, vxi: cs.m_vxi, vyf: cs.m_vyf, vyi: cs.m_vyi, pause: cs.m_pause };
    const pOff = { xl: cs.plt_xl, xh: cs.plt_xh, yl: cs.plt_yl, yh: cs.plt_yh };
    return {
        name: 'CPC', cpu: c, m,
        v: name => cs[name],
        slow: (i, f) => cs.srecs + i * cs.sr_size + srOff[f], plat: (i, f) => cs.plats + i * cs.plt_size + pOff[f],
        cps: (i, f) => cs.cp_srecs + i * cs.sr_size + srOff[f], cpp: (i, f) => cs.cp_plats + i * 4 + pOff[f],
        mover: (i, f) => cs.movers + i * cs.m_size + mvOff[f],
        cp: name => (name in cpOff ? cs.cp_keys + cpOff[name] : cs['cp_' + name]),
        tick() { call(cs.game_tick); return c.a; },
        commit() { call(cs.commit_all); },
        restore() { call(cs.restore_checkpoint); },
        start() { call(cs.level_init); },
    };
}

// ---- What must be the same
const BYTES = ['tyf', 'tstate', 'tface', 'tclimb', 'xvel', 'tv', 'anim', 'dead', 'won', 'cur_plat', 'carry',
               'dropped', 'keys_found', 'gems_found', 'have_cp', 'save_cp', 'restarts', 'bal_timer', 'dag_timer', 'ud_db',
               'lr_db', 'yo_db', 'yo_turn', 'done_valid', 'done_restarts', 'done_gems'];
const WORDS = ['tx', 'ty', 'yo_len', 'yo_x', 'yo_y', 'lvl_ticks', 'win_ticks', 'rng', 'last_px', 'last_py', 'done_ticks'];
const SLOW = ['alive', 'xf', 'xl', 'xh', 'yf', 'yl', 'yh', 'vf', 'vi', 'vy', 'wait'];
const MOVER = ['img', 'xf', 'xl', 'xh', 'yf', 'yl', 'yh', 'vxf', 'vxi', 'vyf', 'vyi', 'pause'];
function state(S, nd, ns, np) {
    const m = S.m, b = a => m[a], w = a => m[a] | m[a + 1] << 8, o = {};
    for (const k of BYTES) o[k] = b(S.v(k));
    for (const k of WORDS) o[k] = w(S.v(k));
    o.pend = [b(S.v('pend_lo')), b(S.v('pend_lo') + 1), b(S.v('pend_hi')), b(S.v('pend_hi') + 1)];
    o.alive = [...Array(nd).keys()].map(i => b(S.v('alive') + i));
    o.cp_alive = [...Array(nd).keys()].map(i => b(S.v('cp_alive') + i));
    for (let i = 0; i < ns; i++) {
        o['slow' + i] = SLOW.map(f => b(S.slow(i, f)));
        o['cps' + i] = SLOW.map(f => b(S.cps(i, f)));
    }
    for (let i = 0; i < np; i++) {
        o['plat' + i] = ['xl', 'xh', 'yl', 'yh'].map(f => b(S.plat(i, f)));
        o['cpp' + i] = ['xl', 'xh', 'yl', 'yh'].map(f => b(S.cpp(i, f)));
    }
    for (let i = 0; i < MAX_MOVERS; i++) {
        const a = b(S.mover(i, 'active'));
        o['mover' + i] = a ? [a, ...MOVER.map(f => b(S.mover(i, f)))] : [0];
    }
    o.cp = ['keys', 'gems', 'carry', 'dropped', 'bal', 'dag', 'tyf', 'face'].map(k => b(S.cp(k)));
    o.cp_txy = [w(S.cp('tx')), w(S.cp('ty'))];
    return o;
}
function diffs(a, b) {
    const out = [];
    for (const k in a) if (JSON.stringify(a[k]) !== JSON.stringify(b[k])) out.push(`${k}: BBC ${JSON.stringify(a[k])} CPC ${JSON.stringify(b[k])}`);
    return out;
}

// ---- Run
const rand = () => { seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF; return seed / 0x80000000; };
let failed = 0, totalTicks = 0;
const events = { died: 0, won: 0, keys: 0, gems: 0, knocked: 0, carried: 0, checkpoints: 0, balloons: 0, daggers: 0 };
const runs = [];
for (const room of rooms) for (const immortal of [false, true]) runs.push({ room, immortal });
for (const { room, immortal } of runs) {
    const li = NAMES.indexOf(room);
    const B = bbcSide(await bbcMemory(li)), C = cpcSide(cpcMemory(li));
    // (the second run of each level: Trogg can't die, and starts two keys short of
    // finishing, so that he gets about the level, to checkpoints and to its end)
    if (immortal) { B.m[bs.trogg_dies] = 0x60; C.m[cs.trogg_dies] = 0xC9; }
    const nd = B.m[bs.num_draw], ns = B.m[bs.num_slow], np = B.m[bs.num_plats];
    const difficulty = li % 7;              // (0: no balloons or daggers .. 6: Insane)
    const begin = () => {
        for (const S of [B, C]) {
            S.m[S.v('difficulty')] = difficulty;
            // (scratch the logic only reads after writing it, but which the comparison sees)
            for (const k of ['yo_x', 'yo_y', 'last_px', 'last_py', 'done_ticks']) S.m[S.v(k)] = S.m[S.v(k) + 1] = 0;
            for (const k of ['yo_turn', 'plat_hit', 'tv', 'done_valid', 'done_restarts', 'done_gems', 'cmd_live']) S.m[S.v(k)] = 0;
            S.m[S.v('pend_lo')] = S.m[S.v('pend_lo') + 1] = 0xFF; S.m[S.v('pend_hi')] = S.m[S.v('pend_hi') + 1] = 0;
            S.start();
            S.m[S.v('rng')] = 0x35; S.m[S.v('rng') + 1] = 0x5A;
            if (immortal) S.m[S.v('keys_found')] = Math.max(0, S.m[S.v('num_keys')] - 2);
        }
    };
    begin();
    let bad = diffs(state(B, nd, ns, np), state(C, nd, ns, np)), t = 0, held = 0, keys = [0, 0, 0];
    if (bad.length) bad.unshift('after the level started:');
    const log = [];
    for (; t < TICKS && !bad.length; t++) {
        if (held-- <= 0) {                  // new keys, held for 1 to 60 ticks: mostly
            held = 1 + Math.floor(rand() * 60); // walking on the same way, with jumps,
            const r = rand();                   // climbs and throws of the yoyo
            const x = rand() < 0.7 && keys[0] ? keys[0] : Math.floor(rand() * 3) - 1;
            keys = [x, r < 0.3 ? 1 : r < 0.5 ? -1 : 0, rand() < 0.25 ? 1 : 0];
        }
        for (const S of [B, C]) {
            S.m[S.v('xmove')] = keys[0] & 255; S.m[S.v('ymove')] = keys[1] & 255; S.m[S.v('doyoyo')] = keys[2];
            S.commit();
        }
        const before = state(B, nd, ns, np);
        const rb = B.tick(), rc = C.tick();
        log.push(`tick ${t}: keys ${keys} -> ${rb}`);
        bad = diffs(state(B, nd, ns, np), state(C, nd, ns, np));
        if (rb !== rc) bad.unshift(`game_tick returned BBC ${rb} CPC ${rc}`);
        if (bad.length) { bad.unshift(`tick ${t} (keys ${keys}); before it: tx ${before.tx} ty ${before.ty}.${before.tyf} state ${before.tstate}:`); break; }
        // (what happened, to show what the run covered)
        const after = state(B, nd, ns, np);
        events.keys += Math.max(0, after.keys_found - before.keys_found);
        events.gems += Math.max(0, after.gems_found - before.gems_found);
        events.checkpoints += after.have_cp > before.have_cp ? 1 : 0;
        if (after.carry !== 255 && before.carry === 255) events.carried++;
        for (let i = 0; i < MAX_MOVERS; i++) {
            const a = after['mover' + i][0];
            if (a && a !== before['mover' + i][0]) events[['', 'knocked', 'balloons', 'daggers'][a]]++;
        }
        if (rb === 1) { B.restore(); C.restore(); events.died++; }
        else if (rb === 2) { begin(); events.won++; }
        if (rb === 1) {
            bad = diffs(state(B, nd, ns, np), state(C, nd, ns, np));
            if (bad.length) { bad.unshift(`after restore_checkpoint at tick ${t}:`); break; }
        }
    }
    totalTicks += t;
    if (bad.length) {
        failed++;
        console.log(`${room}${immortal ? ' (immortal)' : ''}: FAIL`);
        for (const l of log.slice(-5)) console.log('    ' + l);
        for (const l of bad.slice(0, 20)) console.log('    ' + l);
    } else console.log(`${room}${immortal ? ' (immortal)' : ''}: ${t} ticks the same (difficulty ${difficulty})`);
}
console.log(`\n${runs.length - failed} of ${runs.length} runs the same for ${TICKS} ticks; ${totalTicks} ticks in all, ` +
            Object.entries(events).map(([k, v]) => `${v} ${k}`).join(', '));
process.exit(failed ? 1 : 0);
