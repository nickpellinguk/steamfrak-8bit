// Phase 8's test: the disk, as a real Enterprise 128 would run it. ephl is ep128emu's own Enterprise
// 128 with EXDOS (EXOS 2.1, the BASIC 2.1 cartridge, EXDOS 1.4), with build/frak.img in drive A, and
// nothing put in memory for it: at BASIC's prompt, LOAD (with no name: START) loads the program,
// which loads its files through EXOS into the segments EXOS gives it (GFX.BIN, LOGIC.BIN,
// LOADER.BIN, and TOP.BIN, by way of #FC), takes the machine over, and starts the game by itself.
// Then:
//   - every segment it loaded holds its file, byte for byte;
//   - the attract screen comes up (buffer 0, 32 pixels in);
//   - Space, Down, Space and Space choose Read&Weep from the Classic group, and it plays.
// With EP_COLD=1, the segments the program loads into are filled with garbage first, as a real
// machine's might be.
//
//   ./build.sh && EP_ROMS=... node tools/emu/disk.mjs
import { symbols, run, ROOT, EMULATOR } from './harness.mjs';
import { readFileSync, copyFileSync, mkdirSync } from 'fs';
import { join } from 'path';

if (EMULATOR !== 'ephl') { console.log('disk.mjs runs on ephl only (its BASIC and EXDOS 1.4 machine)'); process.exit(2); }
const sym = symbols();
const key = k => `${k >> 3} ${1 << (k & 7)}`;
const press = (k, n = 4) => [`key ${key(k)} 1`, `wait ${n}`, `key ${key(k)} 0`, 'wait 10'];
const COLD = process.env.EP_COLD ? [0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE].map((s, i) => `fill ${s} 0 16384 ${i + 7}`) : [];
const file = n => readFileSync(join(ROOT, 'build/disk', n));
const files = [['GFX.BIN', 0xF9, 0], ['LOGIC.BIN', 0xFA, 0], ['LOADER.BIN', 0xFE, sym.fe_spare], ['TOP.BIN', 0xFF, 0]];
// (the first key after EXOS's logo goes to BASIC; the first after a pause can be lost, so a space first)
const steps = ['wait 400', ...COLD, 'type  ', 'wait 150', 'type  load\\n', `waitfor ${sym.ready} ${0xA5} 3000`, 'time loaded'];
for (const [n, seg, off] of files) steps.push(`sdump ${n} ${seg} ${off} ${file(n).length}`);
steps.push('wait 200', `peek at ${sym.scroll0} 2`, `peek front ${sym.front} 1`, 'snap disk_attract',
    ...press(sym.key_space), 'wait 60', ...press(sym.key_k), 'wait 10', ...press(sym.key_space), 'wait 60',
    ...press(sym.key_space), 'wait 500', `peek level ${sym.cur_level} 1`,
    `speek frames ${sym.seg_logic} ${sym.frames_drawn - 0x4000} 2`, 'snap disk_level');
const r = run(steps, { seconds: 300, basic: true });
const shots = join(ROOT, 'build', 'shots');
mkdirSync(shots, { recursive: true });
for (const [k, f] of Object.entries(r.snaps)) copyFileSync(f, join(shots, k + '.png'));

let failed = 0;
const check = (ok, msg) => { console.log(`  ${ok ? 'ok' : 'FAIL'} ${msg}`); if (!ok) failed++; };
check(true, `LOAD loaded START, which loaded its files and took the machine over, ${r.times.loaded.toFixed(1)} seconds after power-on`);
for (const [n, seg, off] of files) {
    const want = file(n), got = r.dump(n), wrong = want.findIndex((b, i) => got[i] !== b);
    check(wrong < 0, `${n} (${want.length} bytes) in segment #${seg.toString(16).toUpperCase()}${off ? ' at ' + off : ''}` +
        (wrong < 0 ? ', byte for byte' : `: wrong from byte ${wrong}`));
}
const at = r.peeks.at[0] | r.peeks.at[1] << 8;
check(at === 20480 - 8 && r.peeks.front[0] === 0, 'the game started by itself: the attract screen, in buffer 0, 32 pixels in');
const frames = r.peeks.frames[0] | r.peeks.frames[1] << 8;
check(r.peeks.level[0] === 1 && frames > 20, `the menus chose Read&Weep, and it plays (${frames} frames drawn)`);
console.log(`screenshots: disk_attract.png, disk_level.png in build/shots`);
console.log(failed ? `${failed} failed` : `all passed${process.env.EP_COLD ? ' (from garbage)' : ''}`);
process.exit(failed ? 1 : 0);
