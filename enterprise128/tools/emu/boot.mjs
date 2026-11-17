// Phase 0's test: the program loads, asks EXOS for the segments it will give out, takes the
// machine over and sets `ready`. Prints the segments, for planning the memory map.
//
//   EP_ROMS=/path/to/roms node tools/emu/boot.mjs
import { symbols, run, boot } from './mame.mjs';

const sym = symbols();
const hex = n => '&' + n.toString(16).toUpperCase().padStart(2, '0');
const r = run([...boot(), 'wait 10',
    `peek pages ${sym.pages} 4`, `peek num ${sym.num_segs} 1`, `peek segs ${sym.segs} 8`,
    `peek status ${sym.alloc_status} 1`, 'pages after', 'regs idle', 'snap exos']);
const pages = r.peeks.pages, n = r.peeks.num[0], segs = r.peeks.segs.slice(0, n);
console.log(`EXOS ran the program with segments ${pages.map(hex).join(' ')} at pages 0-3`);
console.log(`It gave out ${n} segment${n === 1 ? '' : 's'}: ${segs.map(hex).join(' ') || 'none'}` +
    ` (then status ${hex(r.peeks.status[0])})`);
console.log(`Afterwards: pages ${r.peeks.after.map(hex).join(' ')}; ${r.log.match(/^OUT regs idle (.*)$/m)[1]}`);
let ok = true;
const fail = msg => { console.log('FAIL: ' + msg); ok = false; };
const pc = parseInt(r.log.match(/PC=([0-9A-F]+)/)[1], 16);
if (pc < sym.start || pc >= sym.end_code) fail(`the program isn't idling in its own code (PC ${pc.toString(16)})`);
if (segs.some(s => s < 0xF8)) fail('EXOS gave out a segment that is not RAM on a 128');
console.log(ok ? 'PASS' : 'FAILED');
process.exit(ok ? 0 : 1);
