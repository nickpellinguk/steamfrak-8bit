// The frame rate on every level: frames drawn a second (the game runs at 50 ticks a second
// whatever the frame rate; 25 is the most, a frame every two vertical syncs). Trogg can't die,
// so nothing restarts; he stands still for 10 seconds (the meanies, balloons and daggers still
// moving), then walks right for 10 (the view scrolling as he goes, on a level that scrolls
// sideways). Prints a table (Markdown, for the README).
//
//   ./build.sh && CPC_ROMS=... node tools/emu/fps.mjs [room_A_1 ...]
import { symbols, run, boot } from './mame.mjs';

const sym = symbols();
const NAMES = ['room_0', ...'ABCDEF'.split('').flatMap(c => [1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => `room_${c}_${n}`))];
const only = process.argv.slice(2).filter(a => a.startsWith('room'));
const rooms = only.length ? only : NAMES;
const KEY_X = sym.key_x, SECONDS = 10;

const rows = [];
for (const room of rooms) {
    const li = NAMES.indexOf(room);
    const steps = [...boot, `poke ${sym.t_arg} ${li}`,
        `bankpoke ${sym.ram_bank + sym.logic_bank} ${sym.trogg_dies} ${0xC9} ${sym.ga_ram}`,
        `poke ${sym.t_cmd} 13`,
        // (the level loaded, and a second of play)
        'wait 500', 'wait 50',
        `bank f0 ${sym.ram_bank + sym.logic_bank} ${sym.frames_drawn} 2 ${sym.ga_ram}`, `peek m0 ${sym.is_vert} 1`,
        `wait ${SECONDS * 50}`, `bank f1 ${sym.ram_bank + sym.logic_bank} ${sym.frames_drawn} 2 ${sym.ga_ram}`,
        `key ${KEY_X >> 3} ${1 << (KEY_X & 7)} 1`,
        `wait ${SECONDS * 50}`, `bank f2 ${sym.ram_bank + sym.logic_bank} ${sym.frames_drawn} 2 ${sym.ga_ram}`];
    const r = run(steps, { seconds: 600 });
    const f = k => r.peeks[k][0] | r.peeks[k][1] << 8;
    const still = (f('f1') - f('f0')) / SECONDS, walking = ((f('f2') - f('f1')) & 0xFFFF) / SECONDS;
    rows.push([room.replace('room_', ''), r.peeks.m0[0] ? '320x200' : '256x256', still.toFixed(1), walking.toFixed(1)]);
    console.error(rows.at(-1).join('  '));
}
console.log('| Level | Window | Frames a second, standing | Walking right |');
console.log('| --- | --- | --- | --- |');
for (const r of rows) console.log(`| ${r.join(' | ')} |`);
const avg = (k, m) => { const v = rows.filter(r => !m || r[1] === m).map(r => +r[k]); return (v.reduce((a, b) => a + b, 0) / v.length).toFixed(1); };
console.log(`| average | | ${avg(2)} | ${avg(3)} |`);
for (const m of ['256x256', '320x200']) console.log(`| average | ${m} | ${avg(2, m)} | ${avg(3, m)} |`);
