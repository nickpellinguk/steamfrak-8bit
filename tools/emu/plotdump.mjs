// The plotter check: plot every image at every shift it has, in each drawing mode (plain, saving
// the background, and copying whole cells raw), with the game's own plot, on the 6502 interpreter
// (with sideways RAM paging), over a patterned background, and print a digest of the screen (and
// the saved background) for each. Two builds that draw the same give the same output:
//
//   node plotdump.mjs ../.. > new.txt; node plotdump.mjs /path/to/other/build > old.txt; diff old.txt new.txt
//
// (Each line: mode, image, shift, non-zero bytes drawn, digest.)
import { MachineSession } from 'jsbeeb';
import { readFileSync } from 'fs';
import { createHash } from 'crypto';
import { Cpu6502 } from './cpu6502.mjs';
const dir = process.argv[2];
const out = readFileSync(dir + '/build/assembler.txt', 'utf8');
const sym = {};
for (const [, k, v] of out.match(/SYMBOLS(.*)/)[1].matchAll(/(\w+)\s*&([0-9A-F]+)/g)) sym[k] = parseInt(v, 16);
const nimg = +readFileSync(dir + '/src/gen/sprites.asm', 'utf8').match(/NUM_IMAGES = (\d+)/)[1];
const s = new MachineSession('Master', { discImage: dir + '/build/frak.ssd' });
await s.initialise(); await s.boot(30); await s.autoboot();
const j = s._machine.processor;
for (let t = 0; t < 100 && j.readmem(sym.snd_tune) !== 5; t++) await s.runFrames(20);
const mem = new Uint8Array(65536);
for (let a = 0; a < 0x8000; a++) mem[a] = j.readmem(a);
for (let a = 0xC000; a < 0xFC00; a++) mem[a] = j.readmem(a);
const banks = [];
for (let b = 0; b < 16; b++) banks[b] = j.ramRomOs.slice(j.romOffset + b * 16384, j.romOffset + (b + 1) * 16384);
class BankCpu extends Cpu6502 {
    constructor(m) { super(m); this.romsel = 6; }
    rd(a) { a &= 0xFFFF; return a >= 0x8000 && a < 0xC000 ? banks[this.romsel & 15][a - 0x8000] : this.m[a]; }
    wr(a, v) {
        a &= 0xFFFF;
        if (a === 0xFE30) { this.romsel = v; return; }
        if (a >= 0x8000 && a < 0xC000) { banks[this.romsel & 15][a - 0x8000] = v & 0xFF; return; }
        super.wr(a, v);
    }
}
const c = new BankCpu(mem);
const w16 = (a, v) => { mem[a] = v & 0xFF; mem[a + 1] = (v >> 8) & 0xFF; };
const addr = (col, row) => 0x3000 + ((col + (row >> 3) * 80) % 2560) * 8 + (row & 7);
const gentxt = readFileSync(dir + '/src/gen/imgdir.asm', 'utf8') + readFileSync(dir + '/src/gen/imgdir3.asm', 'utf8');
const dirs = [0, 1, 2, 3].map(sh => {
    const m = gentxt.match(new RegExp('\\.img_bank' + sh + '\\n((?:    EQUB .*\\n)+)'));
    return m[1].replace(/EQUB/g, '').split(/[,\s]+/).filter(Boolean).map(v => parseInt(v.replace('&', ''), 16));
});
const lines = [];
for (let i = 0; i < nimg; i++) {
    const has = [0, 1, 2, 3].map(sh => dirs[sh][i]);
    for (const mode of [0, 1, 4]) for (let sh = 0; sh < 4; sh++) {
        if (!has[sh]) continue;
        for (let a = 0x3000; a < 0x8000; a++) mem[a] = 0;
        mem[sym.clip_l] = 0; mem[sym.clip_r] = 80; w16(sym.clip_t, 0); mem[sym.clip_h] = 0;
        mem[sym.p_mode] = mode; mem[sym.p_img] = i;
        w16(sym.sbase, 0x0400); for (let a = 0x400; a < 0x800; a++) mem[a] = 0;
        for (let k = 0; k < 16; k++) mem[sym.rawbits + k] = 0xFF;
        // (a background to draw over, so masking shows)
        for (let row = 64; row < 160; row++) for (let col = 36; col < 64; col++) mem[addr(col, row)] = (row * 7 + col * 13) & 0xFF;
        w16(sym.p_x, 160 + sh + mem[sym.img_xo + i]); w16(sym.p_y, 64 + mem[sym.img_yo + i]);
        mem[0xF4] = 6; c.romsel = 6;
        c.call(sym.plot);
        let nz = 0; const h = createHash("md5");
        for (let row = 64; row < 64 + mem[sym.img_h + i]; row++) for (let col = 38; col < 64; col++) { h.update(Uint8Array.of(mem[addr(col, row)])); if (mem[addr(col, row)]) nz++; }
        for (let a = 0x400; a < 0x800; a++) h.update(Uint8Array.of(mem[a]));
        lines.push(`${mode} ${i} ${sh} ${nz} ${h.digest("hex")}`);
    }
}
console.log(lines.join('\n'));
process.exit(0);
