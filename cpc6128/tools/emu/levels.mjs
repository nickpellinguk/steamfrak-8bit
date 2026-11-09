// Phase 4's test: the level loader. For every level, has the program load it (load_level, through
// the command mailbox), then compares the tables it built - the level's size, colour and Trogg's
// start, the platforms, ladders (with their hidden extensions), things to draw, moving meanies
// and moving platforms with their ranges and speeds - with what the BBC version's converter
// expects (../build/levels.json, as its check_levels.mjs does).
//
//   ./build.sh && CPC_ROMS=... node tools/emu/levels.mjs [room ...]
import { symbols, run, boot, ROOT } from './mame.mjs';
import { readFileSync } from 'fs';
import { join } from 'path';

const sym = symbols();
const expect = JSON.parse(readFileSync(join(ROOT, '../build/levels.json'), 'utf8'));
const names = ['room_0', ...'ABCDEF'.split('').flatMap(c => [1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => `room_${c}_${n}`))];
const only = process.argv.slice(2);
const tablesFrom = sym.plats, tablesTo = sym.end_ram, varsFrom = sym.cur_level, varsTo = sym.q_y1;

const steps = [...boot, `poke ${sym.flip_rate} 0`];
names.forEach((name, li) => {
    if (only.length && !only.includes(name)) return;
    steps.push(`poke ${sym.t_arg} ${li}`, `poke ${sym.t_cmd} 11`, `waitfor ${sym.t_cmd} 0 2000`,
        `dump t${li} ${tablesFrom} ${tablesTo - tablesFrom}`, `dump v${li} ${varsFrom} ${varsTo - varsFrom}`);
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
    checked++;
    if (errs.length) { bad++; console.log(name, 'FAIL'); for (const x of errs) console.log('   ', x.slice(0, 300)); }
});
console.log(`${checked} levels checked, ${bad} failed`);
process.exit(bad ? 1 : 0);
