// Phase 2's test: the machine layer.
//   ticks  game ticks counted against MAME's emulated clock: 50 a second (one a frame; a CPC
//          frame is 312 lines of 64us, so 50.08 a second)
//   banks  the program's own check of the extra 64K (bank_errors), and the harness reading each
//          bank back itself: a different signature at #4000 and #7FFF of the base RAM and of
//          each of the four extra banks
//   keys   every key of the keyboard matrix pressed in turn (through MAME's keyboard rows): the
//          program's keys[] shows that key and no other, and the KEY_ constants agree with what
//          MAME calls each key
// Then the screen modes are screens.mjs's to check.
//
//   ./build.sh && CPC_ROMS=... node tools/emu/machine.mjs
import { symbols, run, boot } from './mame.mjs';

const sym = symbols();
const steps = [...boot];
// ticks over 20 seconds
steps.push('time t0', `peek k0 ${sym.ticks} 2`, 'wait 1000', 'time t1', `peek k1 ${sym.ticks} 2`);
// banks
const configs = [sym.ram_base, sym.ram_bank, sym.ram_bank + 1, sym.ram_bank + 2, sym.ram_bank + 3];
steps.push(`peek bank_errors ${sym.bank_errors} 1`);
for (const c of configs) steps.push(`bank first_${c} ${c} 16384 1 ${sym.ga_ram}`, `bank last_${c} ${c} 32767 1 ${sym.ga_ram}`);
// keys
steps.push(`peek none ${sym.keys} 10`);
const matrix = [];
for (let row = 0; row < 10; row++) for (let bit = 0; bit < 8; bit++) {
    if (row === 9 && bit === 6) continue;          // (no key there)
    matrix.push({ row, bit });
    steps.push(`key ${row} ${1 << bit} 1`, 'wait 2', `peek key_${row}_${bit} ${sym.keys} 10`, `key ${row} ${1 << bit} 0`, 'wait 2');
}
const r = run(steps);

let failed = 0;
const fail = msg => { console.log('  FAIL ' + msg); failed++; };
const word = b => b[0] | b[1] << 8;

console.log('ticks:');
const rate = (word(r.peeks.k1) - word(r.peeks.k0)) / (r.times.t1 - r.times.t0);
console.log(`  ${word(r.peeks.k1) - word(r.peeks.k0)} ticks in ${(r.times.t1 - r.times.t0).toFixed(3)} seconds: ${rate.toFixed(2)} a second`);
if (Math.abs(rate - 50.08) > 0.1) fail(`${rate.toFixed(2)} ticks a second, not 50.08`);

console.log('banks:');
if (r.peeks.bank_errors[0] !== 0) fail(`bank_errors = ${r.peeks.bank_errors[0]}`);
for (const c of configs) {
    const first = r.peeks[`first_${c}`][0], last = r.peeks[`last_${c}`][0];
    console.log(`  config #${c.toString(16).toUpperCase()}: #4000 = #${first.toString(16).toUpperCase()}, #7FFF = #${last.toString(16).toUpperCase()}`);
    if (first !== c || last !== (~c & 255)) fail(`config #${c.toString(16)}: its signature isn't there`);
}

console.log('keys:');
if (r.peeks.none.some(b => b)) fail(`keys down with none pressed: ${r.peeks.none}`);
// what MAME calls the keys the game uses, and their KEY_ constants
const named = {
    '↑': 'key_up', '→': 'key_right', '↓': 'key_down', '←': 'key_left', 'Enter': 'key_enter', 'Copy': 'key_copy',
    'Return': 'key_return', 'Shift': 'key_shift', 'Control': 'key_control', 'Space': 'key_space', 'Esc': 'key_esc',
    'Tab': 'key_tab', 'Caps Lock': 'key_caps', 'P1 Up': 'key_joy_up', 'P1 Down': 'key_joy_down',
    'P1 Left': 'key_joy_left', 'P1 Right': 'key_joy_right', 'P1 Button 1': 'key_fire1', 'P1 Button 2': 'key_fire2',
};
let checked = 0;
matrix.forEach(({ row, bit }, i) => {
    const got = r.peeks[`key_${row}_${bit}`], want = Array(10).fill(0);
    want[row] = 1 << bit;
    if (got.join() !== want.join()) fail(`row ${row} bit ${bit} (${r.keys[2 * i].name}): keys = ${got}`);
    const name = r.keys[2 * i].name, m = name.match(/^([a-z0-9]) /);
    const constant = named[name] || (m && `key_${m[1]}`);
    if (constant && sym[constant] !== undefined) {
        checked++;
        if (sym[constant] !== row * 8 + bit) fail(`${constant.toUpperCase()} = ${sym[constant]}, but MAME's "${name}" is row ${row} bit ${bit}`);
    }
});
console.log(`  ${matrix.length} keys, each seen alone; ${checked} KEY_ constants agree with MAME's names`);

console.log(failed ? `${failed} failures` : 'all passed');
process.exit(failed ? 1 : 0);
