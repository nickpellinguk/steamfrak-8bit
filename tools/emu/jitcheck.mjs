// The compiled meanie check: for each level given (by number), load it in jsbeeb, then draw its
// moving meanie with plot and with plot_slow (its compiled code, or plot where that can't be used:
// partly outside the window, or over the end of screen memory) at positions across the window and
// beyond its edges, on the 6502 interpreter, and compare the screens.
//
//   node jitcheck.mjs 10 11 12 19        (B_1 Scrubbly, B_2 Poglet, B_3 Hooter, C_1 vertical)
import { MachineSession } from 'jsbeeb';
import { readFileSync } from 'fs';
import { Cpu6502 } from './cpu6502.mjs';
const dir = '../..';
const out = readFileSync(dir + '/build/assembler.txt', 'utf8');
const sym = {};
for (const [, k, v] of out.match(/SYMBOLS(.*)/)[1].matchAll(/(\w+)\s*&([0-9A-F]+)/g)) sym[k] = parseInt(v, 16);
const s = new MachineSession('Master', { discImage: dir + '/build/frak.ssd' });
await s.initialise(); await s.boot(30); await s.autoboot();
const j = s._machine.processor, r8 = a => j.readmem(a), w8 = (a, v) => j.writemem(a, v);
for (let t = 0, v = -1; t < 100; t++) { if (r8(sym.snd_tune) === 5 && r8(sym.vsyncs) !== v && v >= 0) break; v = r8(sym.vsyncs); await s.runFrames(20); }
await s.runFrames(100);
for (let i = 0; i < 2; i++) { s.keyDown('Space'); await s.runFrames(5); s.keyUp('Space'); await s.runFrames(60); }
await s.runFrames(300);
for (const li of process.argv.slice(2).map(Number)) {
    for (let t = 0; t < 400 && r8(sym.cur_level) !== li; t++) { if (t % 40 === 0) { w8(sym.cur_level, li - 1); w8(sym.won, 1); } await s.runFrames(5); }
    await s.runFrames(400);
    const mem = new Uint8Array(65536);
    for (let a = 0; a < 0x8000; a++) mem[a] = r8(a);
    for (let a = 0xC000; a < 0xFC00; a++) mem[a] = r8(a);
    const banks = [];
    for (let b = 0; b < 16; b++) banks[b] = j.ramRomOs.slice(j.romOffset + b * 16384, j.romOffset + (b + 1) * 16384);
    class BankCpu extends Cpu6502 {
        constructor(m) { super(m); this.romsel = 6; }
        rd(a) { a &= 0xFFFF; return a >= 0x8000 && a < 0xC000 ? banks[this.romsel & 15][a - 0x8000] : this.m[a]; }
        wr(a, v) { a &= 0xFFFF; if (a === 0xFE30) { this.romsel = v; return; } if (a >= 0x8000 && a < 0xC000) { banks[this.romsel & 15][a - 0x8000] = v & 0xFF; return; } super.wr(a, v); }
    }
    const c = new BankCpu(mem);
    const img = mem[sym.jit_img];
    if (img === 255) { console.log('level', li, ': nothing compiled'); continue; }
    const w16 = (a, v) => { mem[a] = v & 0xFF; mem[a + 1] = (v >> 8) & 0xFF; };
    const xo = mem[sym.img_xo + img], yo = mem[sym.img_yo + img], h = mem[sym.img_h + img];
    // (the whole window, as when drawing a frame: the game may have been part-way through a repaint)
    const clipL = mem[sym.scrollcol], clipT = mem[sym.scrollrow] * 8;
    mem[sym.clip_l] = clipL; mem[sym.clip_r] = clipL + 80; w16(sym.clip_t, clipT); mem[sym.clip_h] = 0;
    const draw = (entry, x, y) => {
        for (let a = 0x3000; a < 0x8000; a++) mem[a] = (a * 37 >> 3) & 0xFF;      // a pattern to draw over
        mem[sym.p_mode] = 0; mem[sym.p_img] = img; w16(sym.p_x, x); w16(sym.p_y, y);
        mem[0xF4] = 6; c.romsel = 6; c.count = 0;
        c.call(entry);
        return { screen: mem.slice(0x3000, 0x8000), cycles: c.count };
    };
    let n = 0, bad = 0, fast = 0, cyclesP = 0, cyclesJ = 0;
    // (across the whole window and a little beyond each edge, at many heights)
    for (let dx = -48; dx < 360; dx += 6) for (let dy = -30; dy < 262; dy += 7) {
        const x = clipL * 4 + dx + xo, y = clipT + dy + yo;
        if (x < 0 || y < 0) continue;
        const a = draw(sym.plot, x, y), b = draw(sym.plot_slow, x, y);
        n++; cyclesP += a.cycles; cyclesJ += b.cycles;
        if (b.cycles < a.cycles / 1.5) fast++;
        if (a.screen.some((v, k) => v !== b.screen[k])) bad++;
    }
    console.log(`level ${li}: image ${img} (${mem[sym.jit_wb + 0]}/${mem[sym.jit_wb + 1]} bytes x ${h}): ${n} positions, ${bad} differ, ${fast} took the compiled path; ` +
                `instructions per draw: plot ${(cyclesP / n).toFixed(0)}, compiled ${(cyclesJ / n).toFixed(0)}`);
}
process.exit(0);
