// Phase 1's other test: the machine layer.
//   ticks  game ticks counted against the emulated clock: 50 a second (one a frame; a frame is
//          312 lines of 64us, so 50.08 a second)
//   banks  the program's own check of every RAM segment, #F8-#FF (bank_errors, which leaves
//          them as it found them), and that it puts the window's segment back afterwards
//   keys   every key of the keyboard matrix pressed in turn: the program's keys[] shows that
//          key and no other; and the KEY_ constants are where ep128emu's table of the matrix
//          (dave.hpp) puts each key
// The screen is screens.mjs's to check.
//
//   ./build.sh && EP_ROMS=... node tools/emu/machine.mjs
import { symbols, run, boot, EMULATOR } from './harness.mjs';

const sym = symbols();
const steps = [...boot()];
steps.push('time t0', `peek k0 ${sym.ticks} 2`, 'wait 1000', 'time t1', `peek k1 ${sym.ticks} 2`);
steps.push(`peek bank_errors ${sym.bank_errors} 1`, `peek win_seg ${sym.win_seg} 1`, 'pages pages');
steps.push(`peek none ${sym.keys} 10`);
// (MAME has no key where the keyboard has none: row 5 bits 1 and 7, row 6 bits 1 and 7, row 9
// bits 1, 6 and 7; ep128emu reads every position)
const holes = ['5,1', '5,7', '6,1', '6,7', '9,1', '9,6', '9,7'];
const matrix = [];
for (let row = 0; row < 10; row++) for (let bit = 0; bit < 8; bit++) {
    if (EMULATOR === 'mame' && holes.includes(`${row},${bit}`)) continue;
    matrix.push({ row, bit });
    steps.push(`key ${row} ${1 << bit} 1`, 'wait 2', `peek key_${row}_${bit} ${sym.keys} 10`, `key ${row} ${1 << bit} 0`, 'wait 2');
}
const r = run(steps);

let failed = 0;
const fail = msg => { console.log('  FAIL ' + msg); failed++; };
const word = b => b[0] | b[1] << 8;
const hex = n => '&' + n.toString(16).toUpperCase();

console.log('ticks:');
const n = word(r.peeks.k1) - word(r.peeks.k0), secs = r.times.t1 - r.times.t0, rate = n / secs;
console.log(`  ${n} ticks in ${secs.toFixed(3)} seconds: ${rate.toFixed(2)} a second`);
if (Math.abs(rate - 50.08) > 0.1) fail(`${rate.toFixed(2)} ticks a second, not 50.08`);

console.log('banks:');
console.log(`  bank_errors = ${r.peeks.bank_errors[0]}; the window holds ${hex(r.peeks.win_seg[0])}; pages ${r.peeks.pages.map(hex).join(' ')}`);
if (r.peeks.bank_errors[0] !== 0) fail(`bank_errors = ${r.peeks.bank_errors[0]}`);
if (r.peeks.pages[1] !== r.peeks.win_seg[0]) fail(`page 1 holds ${hex(r.peeks.pages[1])}, but win_seg says ${hex(r.peeks.win_seg[0])}`);
if (r.peeks.pages[0] !== 0xF8) fail(`page 0 holds ${hex(r.peeks.pages[0])}, not &F8`);

console.log('keys:');
if (r.peeks.none.some(b => b)) fail(`keys down with none pressed: ${r.peeks.none}`);
for (const { row, bit } of matrix) {
    const got = r.peeks[`key_${row}_${bit}`], want = Array(10).fill(0);
    want[row] = 1 << bit;
    if (got.join() !== want.join()) fail(`row ${row} bit ${bit}: keys = ${got}`);
}
// ep128emu's table of the matrix (dave.hpp), a row of 8 a line ('' where there's no key)
const table = [
    'N \\ B C V X Z SHIFT', 'H LOCK G D F S A CONTROL', 'U Q Y R T E W TAB', '7 1 6 4 5 3 2 ESC',
    'F4 F8 F3 F6 F5 F7 F2 F1', '8 - 9 MINUS 0 CARET ERASE -', 'J - K SEMICOLON L COLON RBRACKET -',
    'STOP DOWN RIGHT UP HOLD LEFT ENTER ALT', 'M DEL COMMA SLASH STOP_ SHIFT_R SPACE INS', 'I - O AT P LBRACKET - -'];
let checked = 0;
table.forEach((line, row) => line.split(' ').forEach((name, bit) => {
    if (name === '-' || name === '\\') return;
    const v = sym['key_' + name.toLowerCase()];
    if (v === undefined) return;
    checked++;
    if (v !== row * 8 + bit) fail(`KEY_${name} = ${v}, but the matrix has it at row ${row} bit ${bit}`);
}));
console.log(`  ${matrix.length} matrix positions, each seen alone; ${checked} KEY_ constants where the matrix has them`);

console.log(failed ? `${failed} failures (${EMULATOR})` : `all passed (${EMULATOR})`);
process.exit(failed ? 1 : 0);
