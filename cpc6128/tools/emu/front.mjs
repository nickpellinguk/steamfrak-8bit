// Phase 8's test: the front end. MAME boots the disc without the test harness saying it's there,
// so the game starts by itself: the attract screen, then (Space) the menus. Down and Space choose
// the Classic group, Space its first level (Read&Weep), which must start; then the level is won
// (as level_complete leaves things: a time, all the gems, no restarts), so the level-complete
// screen must be drawn, with its text, and then the next level must start. Escape goes back to
// the menus, where the level's button now shows its best time and medals, and the joystick
// moves around them. Each step is a screenshot (build/shots/front_*.png).
// (CPC_COLD=1: from memory filled with garbage first, as a real machine's might be.)
//
//   ./build.sh && CPC_ROMS=... node tools/emu/front.mjs
import { symbols, run, bootGame, ROOT } from './mame.mjs';
import { mkdirSync, existsSync, copyFileSync } from 'fs';
import { join } from 'path';

const sym = symbols();
const key = k => `${k >> 3} ${1 << (k & 7)}`;
const press = (k, n = 3) => [`key ${key(k)} 1`, `wait ${n}`, `key ${key(k)} 0`, 'wait 10'];
const logic = sym.ram_bank + sym.logic_bank;
const lpeek = (label, a, n = 1) => `bank ${label} ${logic} ${a} ${n} ${sym.ga_ram}`;
const lpoke = (a, v) => `bankpoke ${logic} ${a} ${v} ${sym.ga_ram}`;
const shots = join(ROOT, 'build', 'shots');
if (!existsSync(shots)) mkdirSync(shots, { recursive: true });

const steps = [...bootGame, 'wait 150', `peek attract_mode ${sym.cur_mode} 1`, 'snap front_attract',
    ...press(sym.key_space), 'wait 60', 'snap front_menus',
    ...press(sym.key_k), 'wait 10', `peek top_sel ${sym.fe_sel} 1`,
    ...press(sym.key_space), 'wait 60', 'snap front_classic',
    ...press(sym.key_space), 'wait 400', `peek level ${sym.cur_level} 1`, lpeek('frames1', sym.frames_drawn, 2), 'snap front_level',
    // the level won, as level_complete leaves it (1:23.460, all the gems, no restarts)
    lpoke(sym.win_ticks, 150), lpoke(sym.win_ticks + 1, 0),
    lpoke(sym.done_level, 1), lpoke(sym.done_ticks, 4173 & 255), lpoke(sym.done_ticks + 1, 4173 >> 8),
    lpoke(sym.done_restarts, 0), lpoke(sym.done_gems, 1), lpoke(sym.done_valid, 1),
    `poke ${sym.won} 1`, 'wait 60', 'snap front_won',
    'wait 400', `peek level2 ${sym.cur_level} 1`, 'snap front_next',
    ...press(sym.key_esc), 'wait 80', `peek menu_kind ${sym.fe_kind} 1`,
    ...press(sym.key_space), 'wait 60', 'snap front_records',     // (the menus remember Classic)
    `bank best ${sym.ram_bank + sym.front_bank} ${sym.rec_best_lo + 1} 1 ${sym.ga_ram}`,
    `bank best_hi ${sym.ram_bank + sym.front_bank} ${sym.rec_best_hi + 1} 1 ${sym.ga_ram}`,
    `bank gem ${sym.ram_bank + sym.front_bank} ${sym.rec_gem + 1} 1 ${sym.ga_ram}`,
    // ... and the joystick moves around the menus (back to the top menu, then right)
    ...press(sym.key_esc), 'wait 60', ...press(sym.key_joy_right), `peek joy_sel ${sym.fe_sel} 1`];
const r = run(steps, { seconds: 600 });
for (const [k, f] of Object.entries(r.snaps)) copyFileSync(f, join(shots, k + '.png'));

let failed = 0;
const check = (ok, msg) => { console.log(`  ${ok ? 'ok' : 'FAIL'} ${msg}`); if (!ok) failed++; };
const pk = k => r.peeks[k];
check(pk('attract_mode')?.[0] === 0, 'the attract screen came up by itself, in the 256x256 mode');
check(pk('top_sel')?.[0] === 3, 'Down moved to the Classic group');
check(pk('level')?.[0] === 1, `Read&Weep (level 1) started from the menus (cur_level ${pk('level')?.[0]})`);
const f1 = pk('frames1'); check(f1 && (f1[0] | f1[1] << 8) > 20, `... and played (${f1 ? f1[0] | f1[1] << 8 : '?'} frames drawn)`);
check(pk('level2')?.[0] === 2, `won, the next level started (cur_level ${pk('level2')?.[0]})`);
check(pk('menu_kind')?.[0] === 0, 'Escape went back to the menus');
const best = (pk('best')?.[0] ?? 0) | (pk('best_hi')?.[0] ?? 0) << 8;
check(best === 4173, `the records: level 1's best time is the one won (${best} ticks)`);
check(pk('gem')?.[0] === 1, '... with all the gems');
check(pk('joy_sel')?.[0] === 4, `the joystick moved the selection from Classic to Moving (${pk('joy_sel')?.[0]})`);
console.log(`screenshots: ${['attract', 'menus', 'classic', 'level', 'won', 'next', 'records'].map(n => `front_${n}.png`).join(', ')} in build/shots`);
console.log(failed ? `${failed} failed` : 'all passed');
process.exit(failed ? 1 : 0);
