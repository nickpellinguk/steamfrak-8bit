// Phase 2's test: the Z80 unpacker (src/unpack.asm). The front end and the level loader, packed
// by tools/memmap.py with the BBC version's packer, are put where the front end will be kept,
// in segment #FF at #7000 (in the window), and the program unpacks each from there (with #FF at
// page 3) into segment #FB at #4000, where the front end will run. What it unpacks must be what
// was packed, byte for byte, and end where it should; the line parameter tables at the top of
// #FF must be untouched, and the time it takes is printed.
//
//   ./build.sh && EP_ROMS=... node tools/emu/unpack.mjs
import { symbols, run, boot, ROOT, EMULATOR } from './harness.mjs';
import { readFileSync } from 'fs';
import { join } from 'path';

const sym = symbols();
const names = ['FRONT', 'LOADER'];
const word = (addr, v) => [`poke ${addr} ${v & 255}`, `poke ${addr + 1} ${v >> 8}`];
const steps = [...boot(), 'sdump lpt_before 255 16128 256'];
for (const name of names) {
    const raw = readFileSync(join(ROOT, `build/${name}.bin`));
    steps.push(`sload 255 ${0x3000} ${join(ROOT, `build/${name}.lz`)}`, ...word(sym.t_unpack_src, 0xF000),
        `poke ${sym.t_unpack_seg} ${0xFB}`, `peek ${name}_done0 ${sym.t_done} 2`, 'time t0_' + name,
        `poke ${sym.t_unpack} 1`, `waitfor ${sym.t_unpack} 0 100`, 'time t1_' + name,
        `peek ${name}_end ${sym.t_unpack_end} 2`, `sdump ${name} 251 0 ${raw.length}`);
}
steps.push('sdump lpt_after 255 16128 256');
const r = run(steps);

let failed = 0;
const fail = msg => { console.log('  FAIL ' + msg); failed++; };
for (const name of names) {
    const raw = readFileSync(join(ROOT, `build/${name}.bin`)), lz = readFileSync(join(ROOT, `build/${name}.lz`));
    const got = r.dump(name), end = r.peeks[`${name}_end`][0] | r.peeks[`${name}_end`][1] << 8;
    const wrong = raw.findIndex((b, i) => got[i] !== b);
    const ms = (r.times[`t1_${name}`] - r.times[`t0_${name}`]) * 1000;
    console.log(`${name.toLowerCase()}: ${lz.length} bytes unpacked to ${raw.length}, in at most ${ms.toFixed(0)}ms`);
    if (wrong >= 0) fail(`wrong from byte ${wrong}: ${got[wrong]}, not ${raw[wrong]}`);
    if (end !== 0x4000 + raw.length) fail(`it ended at #${end.toString(16)}, not #${(0x4000 + raw.length).toString(16)}`);
}
if (!r.dump('lpt_before').equals(r.dump('lpt_after'))) fail('the line parameter tables changed');
console.log(failed ? `${failed} failures (${EMULATOR})` : `all passed (${EMULATOR})`);
process.exit(failed ? 1 : 0);
