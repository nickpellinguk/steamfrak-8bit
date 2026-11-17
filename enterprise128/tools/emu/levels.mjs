// Phase 4's test: the level loader and the background (the CPC version's levels.mjs, for the
// Enterprise's window and screen). For every level, has the program load it
// (load_level, through the command mailbox), then compares with what the BBC version's converter
// expects (../build/levels.json, as its check_levels.mjs does):
//   the tables it built - the level's size, colour and Trogg's start, the platforms, ladders (with
//     their hidden extensions), things to draw, moving meanies and moving platforms with their
//     ranges and speeds;
//   the background cache it unrolled (in segment #FB, at the BBC's bank 7 offsets): the line
//     tables, the cell dictionary and the lines;
//   the window repainted from the cache (all 80 byte columns of a level that scrolls sideways,
//     all 32 character rows of one that scrolls up and down: the BBC version's window), byte for
//     byte, in buffer 1's ring, against the screen the converter's background bytes describe.
// The program's graphics, levels and loader are put in their segments first (as the program
// will load them itself, in phase 8).
//
//   ./build.sh && EP_ROMS=... node tools/emu/levels.mjs [room ...]
import { symbols, run, boot, ROOT, EMULATOR } from './harness.mjs';
import { readFileSync } from 'fs';
import { join } from 'path';

const sym = symbols();
const expect = JSON.parse(readFileSync(join(ROOT, '../build/levels.json'), 'utf8'));
const names = ['room_0', ...'ABCDEF'.split('').flatMap(c => [1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => `room_${c}_${n}`))];
const only = process.argv.slice(2);
const tablesFrom = sym.plats, tablesTo = sym.end_ram, varsFrom = sym.cur_level, varsTo = sym.q_y1;

const CACHE = sym.seg_cache, RING_SEG = 0xFD, RING_OFF = 0x1100, RING = 20480;   // (buffer 1's ring)
const steps = [...boot(), `poke ${sym.flip_rate} 0`, `sload ${0xF9} 0 ${join(ROOT, 'build/cpc/GFX.BIN')}`,
    `sload ${0xFF} 0 ${join(ROOT, 'build/LEVELS.BIN')}`, `sload ${0xFE} ${sym.fe_spare} ${join(ROOT, 'build/LOADER.BIN')}`];
const command = (cmd, arg) => steps.push(`poke ${sym.t_arg} ${arg}`, `poke ${sym.t_cmd} ${cmd}`, `waitfor ${sym.t_cmd} 0 3000`);
names.forEach((name, li) => {
    if (only.length && !only.includes(name)) return;
    command(11, li);
    steps.push(`dump t${li} ${tablesFrom} ${tablesTo - tablesFrom}`, `dump v${li} ${varsFrom} ${varsTo - varsFrom}`,
        `sdump c${li} ${CACHE} 0 16384`);
    command(12, 0);
    steps.push(`sdump s${li} ${RING_SEG} ${RING_OFF} ${RING}`);
});
const r = run(steps, { seconds: 1200 });

const s16 = v => (v >= 32768 ? v - 65536 : v);
let bad = 0, checked = 0;
names.forEach((name, li) => {
    if (only.length && !only.includes(name)) return;
    const e = expect[name], t = r.dump(`t${li}`), v = r.dump(`v${li}`);
    const tb = a => t[a - tablesFrom], vb = a => v[a - varsFrom];
    const vw = a => vb(a) | vb(a + 1) << 8;
    // record n's field f (and f + 1, for a 16-bit one) of the table at base
    const field = (base, size, n, f) => tb(base + n * size + sym[f]);
    const word = (base, size, n, f) => field(base, size, n, f) | tb(base + n * size + sym[f] + 1) << 8;
    const errs = [];
    const cmp = (what, got, want) => { if (JSON.stringify(got) !== JSON.stringify(want)) errs.push(`${what}: got ${JSON.stringify(got)} want ${JSON.stringify(want)}`); };
    const np = vb(sym.num_plats), nl = vb(sym.num_ladders), nd = vb(sym.num_draw), ns = vb(sym.num_slow);
    const rng = n => [...Array(n).keys()];
    const P = (f, w = false, signed = false) => rng(np).map(i => { const x = w ? word(sym.plats, sym.plt_size, i, f) : field(sym.plats, sym.plt_size, i, f); return signed ? s16(x) : x; });
    const L = (f, w = false, signed = false) => rng(nl).map(i => { const x = w ? word(sym.ladders, sym.l_size, i, f) : field(sym.ladders, sym.l_size, i, f); return signed ? s16(x) : x; });
    const D = (f, w = false) => rng(nd).map(i => w ? word(sym.draws, sym.d_size, i, f) : field(sym.draws, sym.d_size, i, f));
    const S = (f, w = false, signed = false) => rng(ns).map(i => { const x = w ? word(sym.slows, sym.s_size, i, f) : field(sym.slows, sym.s_size, i, f); return signed ? s16(x) : x; });
    cmp('cur_level', vb(sym.cur_level), li);
    cmp('counts', [np, nl, nd, ns], [e.plat_x.length, e.lad_x.length, e.draw_img.length, e.sl_kind.length]);
    cmp('trogg', [vw(sym.trogg_x0), vw(sym.trogg_y0)], e.trogg);
    cmp('bg', vb(sym.level_bg), e.bg);
    cmp('plat_x', P('plt_x0l', true, true), e.plat_x);
    cmp('plat_y', P('plt_y0l', true, true), e.plat_y);
    cmp('plat_w', P('plt_w'), e.plat_w);
    cmp('plat_moving', P('plt_moving'), e.plat_moving);
    cmp('plat_bouncy', P('plt_bouncy'), e.plat_bouncy);
    cmp('lad_x', L('l_xl', true), e.lad_x);
    cmp('lad_y', L('l_yl', true, true), e.lad_y);
    cmp('lad_h', L('l_hl', true), e.lad_h);
    cmp('lad_ext', L('l_ext'), e.lad_ext);
    cmp('draw_img', D('d_img'), e.draw_img);
    cmp('draw_x', D('d_xl', true), e.draw_x);
    cmp('draw_y', D('d_yl', true), e.draw_y);
    for (const k of ['kind', 'img', 'vy', 'plat', 'wait', 'simple']) cmp('sl_' + k, S('s_' + k), e['sl_' + k]);
    for (const k of ['x0', 'y0', 'amin', 'amax', 'bmin', 'bmax']) cmp('sl_' + k, S(`s_${k}l`, true, true), e['sl_' + k]);
    cmp('sl_v', rng(ns).map(i => field(sym.slows, sym.s_size, i, 's_vf') + 256 * field(sym.slows, sym.s_size, i, 's_vi')), e.sl_v);
    // the background cache: the line tables, the cell dictionary, the lines (BBC addresses are #4000 on)
    const c = r.dump(`c${li}`);
    const tables = Buffer.from(e.bg_tables, 'hex'), cells = Buffer.from(e.bg_cells, 'hex'), data = Buffer.from(e.bg_data, 'hex');
    const firstDiff = (what, n, got, want) => { for (let i = 0; i < n; i++) if (got(i) !== want(i)) { errs.push(`${what} differs at ${i} of ${n}: got ${got(i)} want ${want(i)}`); return; } };
    firstDiff('line tables', 512, i => c[i], i => (i >= 256 && tables[i] ? tables[i] - 0x40 : tables[i]));
    firstDiff('dictionary', cells.length, i => { const n = i >> 3, l = i & 7; return c[0x200 + (n >> 8) * 0x800 + l * 256 + (n & 255)]; }, i => cells[i]);
    firstDiff('lines', data.length, i => c[e.bg_start - 0x8000 + i], i => data[i]);
    // the window, repainted: each cell of each line, from the expected lines and dictionary
    const vert = e.h > 256, mb = vert ? 10 : 4;
    const want = Buffer.from(r.dump(`s${li}`)), shown = r.dump(`s${li}`);
    const nLines = vert ? 32 : 80, nCells = vert ? 80 : 32;
    const ringAt = (y, c) => ((y & 255) * 80 + c) % RING;      // (a level's line y, byte column c, in the ring)
    for (let line = 0; line < nLines; line++) {
        const addr = tables[line] | tables[256 + line] << 8;
        const at = addr - e.bg_start;           // (where its masks are in the expected lines)
        let k = 0;
        for (let cell = 0; cell < nCells; cell++) {
            const byte = cell >> 3, bit = 0x80 >> (cell & 7);
            let n = -1;
            if (data[at + byte] & bit) {
                n = data[at + 3 * mb + k++];
                if (data[at + mb + byte] & bit) n += 256;
                if (data[at + 2 * mb + byte] & bit) n += 512;
            }
            for (let l = 0; l < 8; l++) want[vert ? ringAt(8 * line + l, cell) : ringAt(8 * cell + l, line)] = n < 0 ? 0 : cells[n * 8 + l];
        }
    }
    let diff = 0, first = -1;
    for (let i = 0; i < RING; i++) if (shown[i] !== want[i]) { diff++; if (first < 0) first = i; }
    if (diff) errs.push(`repainted window: ${diff} bytes differ, the first at ring offset ${first} (line ${first / 80 | 0}, byte ${first % 80})`);
    checked++;
    if (errs.length) { bad++; console.log(name, 'FAIL'); for (const x of errs) console.log('   ', x.slice(0, 300)); }
});
console.log(`${checked} levels checked, ${bad} failed (${EMULATOR})`);
process.exit(bad ? 1 : 0);
