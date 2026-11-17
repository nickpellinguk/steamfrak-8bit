// The frame rate on every level: frames drawn a second (the game runs at 50 ticks a second
// whatever the frame rate; 25 is the most, a frame every two vertical syncs). Trogg can't die,
// so nothing restarts; he stands still for 10 seconds (the meanies, balloons and daggers still
// moving), then walks right for 10 (the view scrolling as he goes, on a level that scrolls
// sideways). Prints a table (Markdown, for the README), with the game's speed walking: the ticks
// run, against 50 a second (below 100% the game slows down).
//
// (The CPC version's fps.mjs, for the Enterprise: on ephl, with the video RAM's wait states, the
// frame rates are the real machine's.)
//
//   ./build.sh && EP_ROMS=... node tools/emu/fps.mjs [room_A_1 ...]
import { symbols, run, boot, loadFiles } from './harness.mjs';

const sym = symbols();
const NAMES = ['room_0', ...'ABCDEF'.split('').flatMap(c => [1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => `room_${c}_${n}`))];
const only = process.argv.slice(2).filter(a => a.startsWith('room'));
const rooms = only.length ? only : NAMES;
const KEY_X = sym.key_x, SECONDS = 10;

const rows = [];
for (const room of rooms) {
    const li = NAMES.indexOf(room);
    const LOGIC = sym.seg_logic, fd = sym.frames_drawn - 0x4000, lt = sym.lvl_ticks - 0x4000;
    const steps = [...boot(), ...loadFiles(sym), `poke ${sym.t_arg} ${li}`,
        `spoke ${LOGIC} ${sym.trogg_dies - 0x4000} ${0xC9}`,
        `poke ${sym.t_cmd} 13`,
        // (the level loaded, and a second of play)
        'wait 500', 'wait 50',
        `speek f0 ${LOGIC} ${fd} 2`, `peek m0 ${sym.is_vert} 1`,
        `wait ${SECONDS * 50}`, `speek f1 ${LOGIC} ${fd} 2`, `speek t1 ${LOGIC} ${lt} 2`,
        `key ${KEY_X >> 3} ${1 << (KEY_X & 7)} 1`,
        `wait ${SECONDS * 50}`, `speek f2 ${LOGIC} ${fd} 2`, `speek t2 ${LOGIC} ${lt} 2`];
    const r = run(steps, { seconds: 600 });
    const f = k => r.peeks[k][0] | r.peeks[k][1] << 8;
    const still = (f('f1') - f('f0')) / SECONDS, walking = ((f('f2') - f('f1')) & 0xFFFF) / SECONDS;
    const speed = ((f('t2') - f('t1')) & 0xFFFF) / (SECONDS * 50) * 100;
    rows.push([room.replace('room_', ''), r.peeks.m0[0] ? 'up and down' : 'sideways', still.toFixed(1), walking.toFixed(1), speed.toFixed(0)]);
    console.error(rows.at(-1).join('  '));
}
console.log('| Level | Scrolls | Frames a second, standing | Walking right | Game speed walking (%) |');
console.log('| --- | --- | --- | --- | --- |');
for (const r of rows) console.log(`| ${r.join(' | ')} |`);
const avg = (k, m) => { const v = rows.filter(r => !m || r[1] === m).map(r => +r[k]); return (v.reduce((a, b) => a + b, 0) / v.length).toFixed(1); };
const avg0 = (k, m) => Math.round(+avg(k, m));
console.log(`| average | | ${avg(2)} | ${avg(3)} | ${avg0(4)} |`);
for (const m of ['sideways', 'up and down']) console.log(`| average | ${m} | ${avg(2, m)} | ${avg(3, m)} | ${avg0(4, m)} |`);
