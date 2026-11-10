// Phase 6's test: every frame the game draws is what it should be. The program plays levels on
// MAME with t_lock set, so that it holds each frame once it's drawn (before showing it); the
// buffer is copied, with the low RAM and the logic bank, then keys are pressed (random, mostly
// purposeful: walking on, jumping, climbing, throwing the yoyo) and the game goes on.
//
// Each frame must be, byte for byte, what a reference renderer (render.mjs, written from the
// data formats) makes of the game's state: the window's background (from the converter's
// background data), the scenery not yet collected, each moving platform and meanie where the
// buffer says it drew it, then everything in the buffer's draw log - balloons, daggers, meanies
// flying off, the yoyo and its string, Trogg, the FRAK! bubble - in order. So anything left
// behind, erased wrongly, painted in the wrong place or not repainted when it should have been
// shows up.
//
//   ./build.sh && CPC_ROMS=... node tools/emu/frames.mjs [room_A_1 ...] [--frames=N] [--seed=N]
import { symbols, run, boot } from './mame.mjs';
import { refPlot, refLine, background, paintBackground, at, images } from './render.mjs';

const sym = symbols();
const args = process.argv.slice(2);
const opt = k => { const a = args.find(s => s.startsWith('--' + k)); return a ? (a.split('=')[1] ?? true) : undefined; };
const FRAMES = +(opt('frames') || 150);
let seed = +(opt('seed') || 1);
const NAMES = ['room_0', ...'ABCDEF'.split('').flatMap(c => [1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => `room_${c}_${n}`))];
const only = args.filter(a => a.startsWith('room'));
// (levels that scroll sideways, and up and down: C_2, C_6, D_7, E_6 and F_5)
const rooms = only.length ? only : ['room_A_1', 'room_A_5', 'room_B_3', 'room_C_2', 'room_C_6', 'room_D_4', 'room_D_7',
                                    'room_E_2', 'room_E_6', 'room_F_5', 'room_F_8'];
const rand = () => { seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF; return seed / 0x80000000; };
const KEYS = { left: ['key_z', 'key_left'], right: ['key_x', 'key_right'], up: ['key_o', 'key_up'],
               down: ['key_k', 'key_down'], yoyo: ['key_p', 'key_space'] };
const keyStep = (code, down) => `key ${code >> 3} ${1 << (code & 7)} ${down ? 1 : 0}`;

let failed = 0, frames = 0;
const seen = { scrolls: 0, yoyo: 0, collected: 0, deaths: 0, movers: 0, slow: 0 };
const runs = rooms.flatMap(room => [{ room, immortal: false }, { room, immortal: true }]);
for (const { room, immortal } of runs) {
    const li = NAMES.indexOf(room);
    // ---- play it, holding each frame
    const steps = [...boot, `poke ${sym.t_lock} 1`, `poke ${sym.t_arg} ${li}`];
    // (the second run of each level: Trogg can't die, so he gets about, and the view scrolls)
    if (immortal) steps.push(`bankpoke ${sym.ram_bank + sym.logic_bank} ${sym.trogg_dies} ${0xC9} ${sym.ga_ram}`);
    steps.push(`poke ${sym.t_cmd} 13`);
    let held = [], plan = 0;
    for (let f = 0; f < FRAMES; f++) {
        steps.push(`waitfor ${sym.t_frame} 1 ${f ? 200 : 1000}`, `dump L${f} 0 16384`,
                   `bankdump B${f} ${sym.ram_bank + sym.logic_bank} 16384 16384 ${sym.ga_ram}`, `dump S${f} 32768 32768`);
        if (plan-- <= 0) {                  // new keys, held for 5 to 30 frames
            plan = 5 + Math.floor(rand() * 26);
            for (const k of held) steps.push(keyStep(k, false));
            const r = rand();
            const pick = name => sym[KEYS[name][rand() < 0.5 ? 0 : 1]];
            held = [];
            const x = rand(); if (x < 0.4) held.push(pick('right')); else if (x < 0.75) held.push(pick('left'));
            if (r < 0.25) held.push(pick('up')); else if (r < 0.4) held.push(pick('down'));
            if (rand() < 0.25) held.push(pick('yoyo'));
            for (const k of held) steps.push(keyStep(k, true));
        }
        steps.push(`poke ${sym.t_frame} 0`);
    }
    const r = run(steps, { seconds: 1200 });

    // ---- check each frame
    const bg = background(room), mode = bg.vert ? 1 : 0;
    let bad = null, last = [null, null], alive0 = null, wasDead = 0;
    for (let f = 0; f < FRAMES && !bad; f++) {
        const L = r.dump(`L${f}`), B = r.dump(`B${f}`), S = r.dump(`S${f}`);
        const lo = a => L[a], b2 = a => B[a - 0x4000];
        const w = (rd, a) => { const v = rd(a) | rd(a + 1) << 8; return v > 32767 ? v - 65536 : v; };   // (signed)
        const back = lo(sym.back), page = back ? 0x4000 : 0;
        const shown = S.subarray(page, page + 0x4000);
        const scol = b2(sym.scrollcol), srow = b2(sym.scrollrow);
        const cols = mode ? 80 : 64, rows = mode ? 25 : 32;
        const clip = { l: scol, r: scol + cols, t: srow * 8, h: mode ? 200 : 0 };
        const want = Buffer.from(shown);
        paintBackground(want, bg, scol, cols, srow, rows);
        // the scenery not collected
        for (let i = 0; i < lo(sym.num_draw); i++) {
            if (!b2(sym.alive + i)) continue;
            const d = sym.draws + i * sym.d_size;
            refPlot(want, mode, clip, lo(d + sym.d_img), w(lo, d + sym.d_xl), w(lo, d + sym.d_yl));
        }
        // the slow sprites, where this buffer drew them
        const drawnSlow = [];
        for (let i = 0; i < sym.max_slow; i++) {
            const dr = sym.drecs + (back * sym.max_slow + i) * sym.dr_size;
            if (!b2(dr + sym.dr_on)) continue;
            const img = lo(sym.slows + i * sym.s_size + sym.s_img);
            refPlot(want, mode, clip, img, w(b2, dr + sym.dr_xl), w(b2, dr + sym.dr_yl));
            drawnSlow.push(images[img].name.replace('IMG_', ''));
        }
        // the draw log
        const n = lo(sym.log_n + back), log = [];
        for (let k = 0; k < n; k++) {
            const slot = k + back * sym.max_log;
            const kind = lo(sym.log_kind + slot), img = lo(sym.log_img + slot);
            const x = w(lo, sym.log_x + 2 * slot), y = w(lo, sym.log_y + 2 * slot), x1 = w(lo, sym.log_x1 + 2 * slot);
            if (kind === sym.logk_line) { refLine(want, mode, clip, x, x1, y); log.push(`line ${x}-${x1},${y}`); }
            else { refPlot(want, mode, clip, img, x, y); log.push(`${images[img].name.replace('IMG_', '')} ${x},${y}`); }
        }
        // compare the window
        const diffs = [];
        for (let c = scol; c < scol + cols; c++) for (let y = srow * 8; y < srow * 8 + rows * 8; y++) {
            const i = at(mode, c, y);
            if (shown[i] !== want[i]) diffs.push([c, y, shown[i], want[i]]);
        }
        frames++;
        // (what the run covered)
        const pos = scol * 256 + srow;
        if (last[back] !== null && last[back] !== pos) seen.scrolls++;
        last[back] = pos;
        if (log.some(l => l.startsWith('line'))) seen.yoyo++;
        seen.movers += log.filter(l => /Balloon|Dagger|Scrubbly|Poglet|Hooter/.test(l)).length ? 1 : 0;
        seen.slow += drawnSlow.length ? 1 : 0;
        let nAlive = 0;
        for (let i = 0; i < lo(sym.num_draw); i++) nAlive += b2(sym.alive + i);
        if (alive0 !== null && nAlive < alive0) seen.collected += alive0 - nAlive;
        alive0 = nAlive;
        if (lo(sym.dead) && !wasDead) seen.deaths++;
        wasDead = lo(sym.dead);
        if (diffs.length) {
            const tx = w(lo, sym.tx), ty = w(lo, sym.ty);
            const cs = diffs.map(d => d[0]), ys = diffs.map(d => d[1]);
            bad = [`frame ${f}: ${diffs.length} bytes differ, in byte columns ${Math.min(...cs)}-${Math.max(...cs)}, ` +
                   `lines ${Math.min(...ys)}-${Math.max(...ys)} (the window: columns ${scol}-${scol + cols - 1}, rows ${srow}-${srow + rows - 1}; buffer ${back})`,
                   `the first few (column, line, shown, wanted): ${diffs.slice(0, 6).map(d => d.join(',')).join('  ')}`,
                   `Trogg at ${tx},${ty} state ${lo(sym.tstate)} dead ${lo(sym.dead)}`,
                   `slow sprites drawn: ${drawnSlow.join(' ')}`, `log: ${log.join('; ')}`];
        }
    }
    const name = room + (immortal ? ' (immortal)' : '');
    if (bad) { failed++; console.log(`${name}: FAIL`); for (const l of bad) console.log('    ' + l); }
    else console.log(`${name}: ${FRAMES} frames right`);
}
console.log(`\n${runs.length - failed} of ${runs.length} runs: every frame right (${frames} frames checked: ` +
            `${seen.scrolls} with the view scrolled, ${seen.yoyo} with the yoyo out, ${seen.slow} with moving platforms ` +
            `or meanies, ${seen.movers} with balloons, daggers or meanies flying off, ${seen.collected} things collected, ` +
            `${seen.deaths} deaths)`);
process.exit(failed ? 1 : 0);
