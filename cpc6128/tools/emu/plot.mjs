// Phase 3's test: the plotter, byte for byte. Each case loads the same random background into
// screen buffer 1 (#C000), has the program draw something, and compares the whole 16K with what a
// reference renderer (here, written from the data format, not from the Z80) says it should be.
//   plot      every image at every shift it has, wholly on screen, in both screen modes
//   clipped   random images, places and clip windows (left, right, top, bottom and the 2K wrap)
//   save      PM_SAVE draws the same as PM_PLOT, and restore_saved puts the background back
//   hline     the yoyo string, black and yellow, clipped, saved and put back
//   compiled  the meanies compiled (jit_build) and drawn by plot_slow: the same as plot, and the
//             compiled code used wherever it can be
//   (and nothing may have written over the program's code)
//   log       a frame's worth of the draw log (log_sprite, log_line, and log_sprite7, saving in
//             another bank), then restore_log: back to the background
//
//   ./build.sh && CPC_ROMS=... node tools/emu/plot.mjs [seed]
import { symbols, run, boot, ROOT } from './mame.mjs';
import { readFileSync, writeFileSync, mkdtempSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';

const sym = symbols();
const { images } = JSON.parse(readFileSync(join(ROOT, 'build/images.json'), 'utf8'));
const gfx = readFileSync(join(ROOT, 'build/GFX'));
const PAGE = 0xC000, SIZE = 0x4000;
const LPIX = 0x3C00, LMASK = 0x3D00, RPIX = 0x3E00, RMASK = 0x3F00;     // (in the bank)
const PM_PLOT = 0, PM_SAVE = 1, PM_RESTORE = 2;

// a repeatable random sequence
let seed = Number(process.argv[2] || 1);
const rnd = n => { seed = (seed * 1103515245 + 12345) >>> 0; return (seed >>> 8) % n; };
const background = Buffer.alloc(SIZE);
for (let i = 0; i < SIZE; i++) background[i] = rnd(256);
const tmp = mkdtempSync(join(tmpdir(), 'cpc-bg-'));
const bgFile = join(tmp, 'bg.bin');
writeFileSync(bgFile, background);

// ---- the reference renderer
const W = [64, 80];                                     // bytes a line in each mode
const at = (mode, c, y) => ((y & 7) << 11) | (((y >> 3) * W[mode] + c) & 0x7FF);
function refPlot(buf, mode, clip, img, x, y) {
    const im = images[img], left = x - im.xo, top = y - im.yo;
    const shift = ((left % 4) + 4) % 4, col = Math.floor(left / 4);
    const data = im.shift[shift];
    if (data === undefined) return;
    const wb = (im.w + shift + 3) >> 2, odd = shift & 1;
    for (let k = 0; k < wb; k++) for (let r = 0; r < im.h; r++) {
        const c = col + k, line = top + r;
        if (c < clip.l || c >= clip.r || line < clip.t || line >= clip.t + (clip.h || 256)) continue;
        const code = gfx[data - 0x4000 + k * im.h + r], i = at(mode, c, line);
        const pix = gfx[(odd ? LPIX : RPIX) + code], mask = gfx[(odd ? LMASK : RMASK) + code];
        if (code === 0) continue;
        buf[i] = code >= 128 ? pix : (buf[i] & mask) | pix;
    }
}
const LEFT = [0xFF, 0x77, 0x33, 0x11], RIGHT = [0x88, 0xCC, 0xEE, 0xFF];
function refLine(buf, mode, clip, x0, x1, y, yellow) {
    if (y - clip.t < 0 || y - clip.t >= (clip.h || 256)) return;
    let a = Math.min(x0, x1), b = Math.max(x0, x1);
    if (a >= 1024 || b < 0) return;
    a = Math.max(a, 0);                                 // (clipped to the level's left edge)
    const c0 = a >> 2, c1 = b >= 1024 ? 255 : b >> 2;
    for (let c = c0; c <= c1; c++) {
        if (c < clip.l || c >= clip.r) continue;
        let mask = 0xFF;
        if (c === c0) mask = LEFT[a & 3];
        if (c === c1) mask &= RIGHT[b & 3];
        const i = at(mode, c, y);
        buf[i] = (~mask & buf[i]) | ((yellow ? 0x0F : 0xFF) & mask);     // (black is colour 3, yellow 1)
    }
}

// ---- the cases
const cases = [];
const steps = [...boot, `poke ${sym.flip_rate} 0`, `dump code_before 64 ${sym.ready - 64}`];
let mode = 0;
// (a command, then wait until the program has done it: it clears t_cmd)
const command = cmd => steps.push(`poke ${sym.t_cmd} ${cmd}`, `waitfor ${sym.t_cmd} 0 1000`);
// (command 9 sets the mode up without drawing the test cards; want_mode too, or the program would)
const setMode = m => { if (m !== mode) { steps.push(`poke ${sym.want_mode} ${m}`, `poke ${sym.t_arg} ${m}`); command(9); mode = m; } };
const poke16 = (name, v) => steps.push(`poke ${sym[name]} ${v & 255}`, `poke ${sym[name] + 1} ${(v >> 8) & 255}`);
const setClip = clip => {
    steps.push(`poke ${sym.clip_l} ${clip.l}`, `poke ${sym.clip_r} ${clip.r}`, `poke ${sym.clip_h} ${clip.h}`);
    poke16('clip_t', clip.t);
};
const freshScreen = () => steps.push(`load ${PAGE} ${bgFile}`);
function plotCase(kind, m, clip, img, x, y, cmd = 1, pmode = PM_PLOT) {
    setMode(m); freshScreen(); setClip(clip);
    steps.push(`poke ${sym.p_img} ${img}`, `poke ${sym.p_mode} ${pmode}`);
    poke16('p_x', x); poke16('p_y', y); poke16('sbase', sym.savebuf0);
    command(cmd);
    const label = `c${cases.length}`;
    steps.push(`dump ${label} ${PAGE} ${SIZE}`);
    const want = Buffer.from(background);
    refPlot(want, m, clip, img, x, y);
    cases.push({ kind, label, want, what: `${images[img].name} at ${x},${y}, mode ${m}, clip ${JSON.stringify(clip)}` });
    return label;
}
const full = { l: 0, r: 255, t: 0, h: 0 };
const randomClip = m => {
    const l = rnd(120), r = Math.min(255, l + 1 + rnd(m ? 80 : 64)), t = rnd(m ? 900 : 200);
    return { l, r, t, h: rnd(3) ? 1 + rnd(255) : 0 };
};

// plot: every image at every shift, wholly on screen, both modes
for (const m of [0, 1]) images.forEach((im, i) => {
    for (const s of Object.keys(im.shift).map(Number)) plotCase('plot', m, full, i, 40 + s + im.xo, 8 + im.yo + 3 * m);
});
// clipped: random everything
const coded = images.map((im, i) => i).filter(i => Object.keys(images[i].shift).length);
for (let n = 0; n < 400; n++) {
    const m = rnd(2), clip = randomClip(m), img = coded[rnd(coded.length)];
    plotCase('clipped', m, clip, img, clip.l * 4 - 40 + rnd(400), clip.t - 60 + rnd(clip.h ? clip.h + 120 : 380));
}
// save: PM_SAVE draws as PM_PLOT does, and restore_saved puts the background back
for (let n = 0; n < 120; n++) {
    const m = rnd(2), clip = rnd(2) ? full : randomClip(m), img = coded[rnd(coded.length)];
    plotCase('save', m, clip, img, clip.l * 4 - 20 + rnd(300), clip.t - 40 + rnd(clip.h ? clip.h + 80 : 330), 1, PM_SAVE);
    command(2);
    const label = `c${cases.length}`;
    steps.push(`dump ${label} ${PAGE} ${SIZE}`);
    cases.push({ kind: 'restore', label, want: Buffer.from(background), what: cases.at(-1).what });
}
// hline: black and yellow, clipped, saved, then put back
for (let n = 0; n < 150; n++) {
    const m = rnd(2), clip = rnd(3) ? full : randomClip(m);
    const x0 = rnd(3) ? rnd(1100) : 65536 - rnd(30), x1 = rnd(3) ? (x0 + rnd(100)) & 0xFFFF : rnd(1100);
    const y = clip.t - 5 + rnd(clip.h ? clip.h + 10 : 266), yellow = rnd(2);
    setMode(m); freshScreen(); setClip(clip);
    steps.push(`poke ${sym.hl_yel} ${yellow ? 0xF0 : 0}`, `poke ${sym.p_mode} ${PM_SAVE}`);
    poke16('p_x', x0); poke16('q_x', x1); poke16('p_y', y); poke16('sbase', sym.savebuf0);
    command(3);
    let label = `c${cases.length}`;
    steps.push(`dump ${label} ${PAGE} ${SIZE}`);
    const want = Buffer.from(background);
    const signed = v => (v > 32767 ? v - 65536 : v);     // (the ends are signed: the yoyo can be left of the level)
    refLine(want, m, clip, signed(x0), signed(x1), y, yellow);
    const what = `line ${x0}-${x1} at ${y}, mode ${m}, clip ${JSON.stringify(clip)}`;
    cases.push({ kind: 'hline', label, want, what });
    steps.push(`poke ${sym.p_mode} ${PM_RESTORE}`);
    command(3);
    label = `c${cases.length}`;
    steps.push(`dump ${label} ${PAGE} ${SIZE}`);
    cases.push({ kind: 'hline restore', label, want: Buffer.from(background), what });
}
// compiled: each moving meanie compiled, then drawn by plot_slow
// whether plot_slow should use the compiled code: an even pixel, the meanie wholly in the
// window, and none of its lines crossing the end of a 2K block
function compilable(m, clip, img, x, y) {
    const im = images[img], left = x - im.xo, top = y - im.yo;
    if (left < 0 || left >= 1024 || left & 1) return false;
    const col = left >> 2, wb = (im.w + (left & 2) + 3) >> 2;
    if (col < clip.l || col + wb > clip.r || top < clip.t || top - clip.t + im.h > (clip.h || 256)) return false;
    for (let row = top >> 3; row <= (top + im.h - 1) >> 3; row++)
        if (((row * W[m] + col) & 0x7FF) + wb > 0x800) return false;
    return true;
}
let shouldCompile = 0;
const meanies = ['IMG_Scrubbly', 'IMG_Poglet', 'IMG_Hooter', 'IMG_Balloon'].map(n => images.findIndex(im => im.name === n));
const compiledCases = [];
for (const img of meanies) {
    steps.push(`poke ${sym.t_arg} ${img}`);
    command(4);
    steps.push(`peek jit_${img} ${sym.jit_img} 1`);
    for (let n = 0; n < 60; n++) {
        const m = rnd(2), clip = rnd(4) ? full : randomClip(m), im = images[img];
        let x = (clip.l * 4 - 20 + rnd(m ? 340 : 280)) & ~1, y = clip.t - 30 + rnd(clip.h ? clip.h + 60 : 300);
        if (n & 1 && clip === full) {         // (half of them wholly in the window, mostly compilable)
            x = im.xo + (rnd(4 * (60 - (im.w >> 2))) & ~1);
            y = im.yo + rnd(256 - im.h);
        }
        compiledCases.push(plotCase('compiled', m, clip, img, x, y, 5));
        if (compilable(m, clip, img, x, y)) shouldCompile++;
    }
}
steps.push(`peek jit_count ${sym.jit_count} 2`);
// log: a frame's worth of the draw log, then restore_log
for (let n = 0; n < 40; n++) {
    const m = rnd(2);
    setMode(m); freshScreen(); setClip(full);
    poke16('sfree', sym.savebuf1); poke16('send', sym.savebuf1 + 1024);
    poke16('sfree7', sym.bg_top); poke16('send7', 0x8000); steps.push(`poke ${sym.p_sbank} ${sym.ram_bank + sym.cache_bank}`);
    for (let k = 0; k < 6; k++) {
        if (rnd(4) === 0) {                     // (a big one: its background saved in bank 3, above the cache)
            steps.push(`poke ${sym.p_img} ${coded[rnd(coded.length)]}`);
            poke16('p_x', rnd(300)); poke16('p_y', rnd(250));
            command(10);
        } else if (rnd(3)) {
            steps.push(`poke ${sym.p_img} ${coded[rnd(coded.length)]}`);
            poke16('p_x', rnd(300)); poke16('p_y', rnd(250));
            command(6);
        } else {
            poke16('p_x', rnd(300)); poke16('q_x', rnd(300)); poke16('p_y', rnd(250));
            steps.push(`poke ${sym.hl_yel} ${rnd(2) ? 0xF0 : 0}`);
            command(7);
        }
    }
    command(8);
    const label = `c${cases.length}`;
    steps.push(`dump ${label} ${PAGE} ${SIZE}`);
    cases.push({ kind: 'log', label, want: Buffer.from(background), what: 'six logged things' });
}
steps.push(`peek t_done ${sym.t_done} 2`, `dump code_after 64 ${sym.ready - 64}`);

if (process.env.SHOW) { console.log(cases[Number(process.env.SHOW)].what); process.exit(0); }   // (a case's details)
const r = run(steps, { seconds: 600 });
const done = r.peeks.t_done[0] | r.peeks.t_done[1] << 8;
const asked = steps.filter(s => s.startsWith(`poke ${sym.t_cmd} `)).length;
let failed = 0;
const fail = msg => { if (failed++ < 20) console.log('  FAIL ' + msg); };
if (done !== asked) fail(`${done} commands done of ${asked}`);
const count = {};
for (const c of cases) {
    count[c.kind] = (count[c.kind] || 0) + 1;
    const got = r.dump(c.label);
    let first = -1, n = 0;
    for (let i = 0; i < SIZE; i++) if (got[i] !== c.want[i]) { if (first < 0) first = i; n++; }
    if (n) fail(`${c.kind}: ${c.what}: ${n} bytes differ, the first at #${(PAGE + first).toString(16).toUpperCase()} ` +
        `(#${got[first].toString(16)}, not #${c.want[first].toString(16)})`);
}
for (const img of meanies) if (r.peeks[`jit_${img}`][0] !== img) fail(`${images[img].name} wasn't compiled`);
// nothing may have written over the code (but for the operands it changes itself)
const own = [sym['plot.scr'] + 1, sym['plot.scr'] + 2, sym['plot.dat'] + 1, sym['plot.dat'] + 2, sym['plot.notes_jr'] + 1, sym['plot.ncols'] + 1,
             sym['hline.count'] + 1, sym['hline.last'] + 1, sym['hline.col'] + 1, sym['plot.do_col'] + 1, sym['plot.do_col'] + 2, sym.jit_jump + 1, sym.jit_jump + 2,
             sym['plot.col_tab'], sym['plot.col_rows'], sym['plot.col_hgt'], sym.next_row_w + 1];
const before = r.dump('code_before'), after = r.dump('code_after');
const changed = [...after].findIndex((b, i) => b !== before[i] && !own.includes(64 + i));
if (changed >= 0) fail(`the code at #${(64 + changed).toString(16)} was written over`);
const jitUsed = r.peeks.jit_count[0] | r.peeks.jit_count[1] << 8;
console.log(Object.entries(count).map(([k, v]) => `${v} ${k}`).join(', ') + ' cases');
console.log(`compiled code used for ${jitUsed} of ${compiledCases.length} compiled meanie draws (${shouldCompile} could be)`);
if (jitUsed !== shouldCompile) fail(`the compiled code was used ${jitUsed} times, not ${shouldCompile}`);
console.log(failed ? `${failed} failures` : 'all passed');
process.exit(failed ? 1 : 0);
