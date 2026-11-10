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
import { readFileSync } from 'fs';
import { join } from 'path';
import { ROOT } from './mame.mjs';

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
// Trogg's image, as trogg_image works it out, and its two parts
const table = name => readFileSync(join(ROOT, 'src/gen/collide.asm'), 'utf8').split(name + '\n')[1].split(/\n(?!\s)/)[0]
    .match(/#[0-9A-F]{2}/g).map(v => parseInt(v.slice(1), 16));
const partA = table('img_part_a'), partB = table('img_part_b');
const IMG = Object.fromEntries(images.map((im, i) => [im.name.replace('IMG_', ''), i]));
function troggImage(state, face, anim, climb) {
    if (state === 1) return IMG[face ? 'Trogg_wl_0' : 'Trogg_wr_0'] + (anim >> 6);
    if (state === 3) return climb ? IMG[climb === 1 ? 'Trogg_cu_0' : 'Trogg_cd_0'] + (anim >> 7) : IMG.Trogg_cn;
    if (state >= 4) return IMG[face ? 'Trogg_yl' : 'Trogg_yr'];
    return IMG[face ? 'Trogg_sl' : 'Trogg_sr'];
}
// The timer: a raw image, nibbles of 4 black pixels, 8 byte columns of 8 rows
function refRaw(buf, mode, clip, data, x, y) {
    for (let j = 0; j < 8; j++) for (let r = 0; r < 8; r++) {
        const c = (x >> 2) + j, line = y + r, n = data[j * 8 + r];
        if (!n || c < clip.l || c >= clip.r || line < clip.t || line >= clip.t + (clip.h || 256)) continue;
        const i = at(mode, c, line);
        buf[i] = (buf[i] & ~(n * 17)) | (n * 17);
    }
}
const keyStep = (code, down) => `key ${code >> 3} ${1 << (code & 7)} ${down ? 1 : 0}`;

let failed = 0, frames = 0;
const seen = { won: 0, scrolls: 0, yoyo: 0, collected: 0, deaths: 0, movers: 0, slow: 0 };
const runs = rooms.flatMap(room => [{ room, immortal: false }, { room, immortal: true }]);
for (const { room, immortal } of runs) {
    const li = NAMES.indexOf(room);
    // ---- play it, holding each frame
    const steps = [...boot, `poke ${sym.t_lock} 1`, `poke ${sym.t_arg} ${li}`];
    // (the second run of each level: Trogg can't die, so he gets about, and the view scrolls)
    if (immortal) steps.push(`bankpoke ${sym.ram_bank + sym.logic_bank} ${sym.trogg_dies} ${0xC9} ${sym.ga_ram}`);
    steps.push(`bankdump font ${sym.ram_bank + sym.front_bank} ${sym.fe_font} 768 ${sym.ga_ram}`, `poke ${sym.t_cmd} 13`);
    let held = [], plan = 0;
    for (let f = 0; f < FRAMES; f++) {
        steps.push(`waitfor ${sym.t_frame} 1 1000`, `dump L${f} 0 16384`,
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
        // (the immortal run finishes the level at frame 60, as level_complete does, but with
        // a short wait, so the level-complete screen and the next level are drawn too)
        if (immortal && f === 60) {
            const bp = (a, v) => steps.push(`bankpoke ${sym.ram_bank + sym.logic_bank} ${a} ${v} ${sym.ga_ram}`);
            steps.push(`poke ${sym.won} 1`, `poke ${sym.dead} 0`);
            bp(sym.win_ticks, 100); bp(sym.win_ticks + 1, 0); bp(sym.bwon, 0); bp(sym.bwon + 1, 0); bp(sym.done_restarts, f & 3);
        }
        steps.push(`poke ${sym.t_frame} 0`);
    }
    const r = run(steps, { seconds: 1200 });
    const font = r.dump('font');

    // ---- check each frame
    const bgs = {};
    let bad = null, last = [null, null], alive0 = null, wasDead = 0;
    for (let f = 0; f < FRAMES && !bad; f++) {
        const L = r.dump(`L${f}`), B = r.dump(`B${f}`), S = r.dump(`S${f}`);
        const lo = a => L[a], b2 = a => B[a - 0x4000];
        const w = (rd, a) => { const v = rd(a) | rd(a + 1) << 8; return v > 32767 ? v - 65536 : v; };   // (signed)
        const level = NAMES[lo(sym.cur_level)];
        const bg = bgs[level] ||= background(level), mode = bg.vert ? 1 : 0;
        const back = lo(sym.back), page = back ? 0x4000 : 0;
        const shown = S.subarray(page, page + 0x4000);
        const scol = b2(sym.scrollcol), srow = b2(sym.scrollrow);
        const cols = mode ? 80 : 64, rows = mode ? 25 : 32;
        const clip = { l: scol, r: scol + cols, t: srow * 8, h: mode ? 200 : 0 };
        const want = Buffer.from(shown);
        const won = lo(sym.won), log = [], drawnSlow = [];
        if (won) {
            // the level-complete screen: Trogg (and the trophy) on the background colour
            for (let c = scol; c < scol + cols; c++) for (let y = srow * 8; y < srow * 8 + rows * 8; y++) want[at(mode, c, y)] = 0;
            const t = troggImage(lo(sym.tstate), lo(sym.tface), lo(sym.anim), lo(sym.tclimb));
            const tx = w(lo, sym.tx), ty = w(lo, sym.ty);
            refPlot(want, mode, clip, partA[t], tx, ty);
            if (partB[t] !== 255) refPlot(want, mode, clip, partB[t], tx, ty);
            const r = b2(sym.done_restarts);
            if (r < 3) { refPlot(want, mode, clip, IMG.Rating_1 + r, tx + 21, ty - 23); refPlot(want, mode, clip, IMG.TrophyStand, tx + 21, ty - 23); }
            // ... and its text, in black, centred, from 40 rows above the window's middle (60 with a
            // medal): "We've done it!", the time (m:ss.mmm), the gems, the medal
            const text = (dy, str) => {
                const y0 = clip.t + (mode ? 100 : 128) - 40 - (r < 3 ? 20 : 0) + dy;
                let c = scol + cols / 2 - str.length;
                for (const ch of str) {
                    for (let row = 0; row < 8; row++) {
                        const g = font[(ch.charCodeAt(0) - 32) * 8 + row];
                        for (const [k, n] of [[0, g >> 4], [1, g & 15]]) {
                            const i = at(mode, c + k, y0 + row), m = (n << 4 | n);
                            want[i] = want[i] & ~m | m;
                        }
                    }
                    c += 2;
                }
            };
            const ticks = b2(sym.done_ticks) | b2(sym.done_ticks + 1) << 8;
            const secs = Math.min(599, Math.floor(ticks / 50)), ms = (ticks % 50) * 20;
            text(0, "We've done it!");
            text(16, `${Math.floor(secs / 60)}:${String(secs % 60).padStart(2, '0')}.${String(ms).padStart(3, '0')}`);
            let dy = 32;
            if (b2(sym.done_gems)) { text(32, 'You collected all the gems!'); dy = 48; }
            if (r < 3) text(dy + 32, ['!!! Gold Medal !!!', '!!! Silver Medal !!!', '!!! Bronze Medal !!!'][r]);
            log.push('(the level-complete screen)');
            seen.won++;
        } else {
        paintBackground(want, bg, scol, cols, srow, rows);
        // the scenery not collected
        for (let i = 0; i < lo(sym.num_draw); i++) {
            if (!b2(sym.alive + i)) continue;
            const d = sym.draws + i * sym.d_size;
            refPlot(want, mode, clip, lo(d + sym.d_img), w(lo, d + sym.d_xl), w(lo, d + sym.d_yl));
        }
        // the slow sprites, where this buffer drew them
        for (let i = 0; i < sym.max_slow; i++) {
            const dr = sym.drecs + (back * sym.max_slow + i) * sym.dr_size;
            if (!b2(dr + sym.dr_on)) continue;
            const img = lo(sym.slows + i * sym.s_size + sym.s_img);
            refPlot(want, mode, clip, img, w(b2, dr + sym.dr_xl), w(b2, dr + sym.dr_yl));
            drawnSlow.push(images[img].name.replace('IMG_', ''));
        }
        // the draw log
        const n = lo(sym.log_n + back);
        for (let k = 0; k < n; k++) {
            const rec = sym.log_recs + (k + back * sym.max_log) * sym.lg_size, next_rec = rec + sym.lg_size;
            const kind = lo(rec + sym.lg_kind), img = lo(rec + sym.lg_img);
            const x = w(lo, rec + sym.lg_x), y = w(lo, rec + sym.lg_y), x1 = w(lo, rec + sym.lg_x1);
            if (kind === sym.logk_line) {
                // (the yoyo's string, black, is followed by the yoyo; a movable platform's line is yellow)
                const next = k + 1 < n ? images[lo(next_rec + sym.lg_img)].name : '';
                const yellow = !(lo(next_rec + sym.lg_kind) !== sym.logk_line && next.startsWith('IMG_Yoyo'));
                refLine(want, mode, clip, x, x1, y, yellow);
                log.push(`${yellow ? 'yellow ' : ''}line ${x}-${x1},${y}`);
            } else if (images[img].raw) {
                refRaw(want, mode, clip, L.subarray(sym.hud_image, sym.hud_image + 64), x, y);
                log.push(`Hud ${x},${y}`);
            } else { refPlot(want, mode, clip, img, x, y); log.push(`${images[img].name.replace('IMG_', '')} ${x},${y}`); }
        }
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
            `${seen.deaths} deaths, ${seen.won} level-complete screens)`);
process.exit(failed ? 1 : 0);
