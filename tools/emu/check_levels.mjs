// Check the level loader: boot build/frak.ssd on an emulated BBC Master 128 (jsbeeb),
// visit every level that can be played (by finishing each one), and compare what the
// 6502 built - the platform, ladder, object and moving sprite tables, and every byte of
// the unrolled background in bank 7 - with what the converter expects (build/levels.json).
//
//   ./build.sh && cd tools/emu && npm install && node check_levels.mjs
//
// It reads the symbol addresses from the build's assembler output (build/assembler.txt).
import { MachineSession } from 'jsbeeb';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const out = readFileSync(REPO + '/build/assembler.txt', 'utf8');
const sym = {};
for (const [, k, v] of out.match(/SYMBOLS(.*)/)[1].matchAll(/(\w+)\s*&([0-9A-F]+)/g)) sym[k] = parseInt(v, 16);
const expect = JSON.parse(readFileSync(REPO + '/build/levels.json', 'utf8'));
const names = ['room_0', ...'ABCDEF'.split('').flatMap(c => [1,2,3,4,5,6,7,8,9].map(n => `room_${c}_${n}`))];
const s = new MachineSession('Master', { discImage: REPO + '/build/frak.ssd' });
await s.initialise(); await s.boot(30); await s.autoboot();
const cpu = s._machine.processor;
const bank = (b, a) => cpu.ramRomOs[cpu.romOffset + b * 16384 + a - 0x8000];
const r = a => a >= 0x8000 && a < 0xC000 ? bank(6, a) : cpu.readmem(a);
const w16 = (lo, hi, i) => r(sym[lo] + i) + 256 * r(sym[hi] + i);
const s16 = v => v >= 32768 ? v - 65536 : v;
// (wait for the attract screen: its tune starting says it's up)
// (until the game is running: its vertical sync counter counting, and the attract tune on)
for (let t = 0, v = -1; t < 100; t++) {
    if (r(sym.snd_tune) === 5 && r(sym.vsyncs) !== v && v >= 0) break;
    v = r(sym.vsyncs); await s.runFrames(20);
}
await s.runFrames(100);
// past the attract screen, then "Replay" on the menu starts the build's level
for (let i = 0; i < 2; i++) { s.keyDown('Space'); await s.runFrames(5); s.keyUp('Space'); await s.runFrames(60); }
await s.runFrames(300);
let bad = 0, checked = 0;
const only = process.env.ONLY ? process.env.ONLY.split(',') : null;
for (let li = 0; li < names.length; li++) {
  const e = expect[names[li]];
  if (only && !only.includes(names[li])) continue;
  if (r(sym.cur_level) !== li) {
    // the one before, then finish it (again, if Trogg was dying and that was lost)
    for (let t = 0; t < 400 && r(sym.cur_level) !== li; t++) {
      if (t % 40 === 0) { cpu.writemem(sym.cur_level, (li + 54) % 55); cpu.writemem(sym.won, 1); }
      await s.runFrames(5);
    }
    await s.runFrames(300);                 // (the biggest levels take about 3 seconds to load)
  }
  const errs = [];
  const cmp = (what, got, want) => { if (JSON.stringify(got) !== JSON.stringify(want)) errs.push(`${what}: got ${JSON.stringify(got)} want ${JSON.stringify(want)}`); };
  const np = r(sym.num_plats), nl = r(sym.num_ladders), nd = r(sym.num_draw), ns = r(sym.num_slow);
  const rng = n => [...Array(n).keys()];
  cmp('cur_level', r(sym.cur_level), li);
  cmp('counts', [np, nl, nd, ns], [e.plat_x.length, e.lad_x.length, e.draw_img.length, e.sl_kind.length]);
  cmp('trogg', [w16('trogg_x0', 'trogg_x0', 0) && (r(sym.trogg_x0) + 256 * r(sym.trogg_x0 + 1)), r(sym.trogg_y0) + 256 * r(sym.trogg_y0 + 1)], e.trogg);
  cmp('bg', r(sym.level_bg), e.bg);
  cmp('plat_x', rng(np).map(i => s16(w16('plat_x0l', 'plat_x0h', i))), e.plat_x);
  cmp('plat_y', rng(np).map(i => s16(w16('plat_y0l', 'plat_y0h', i))), e.plat_y);
  cmp('plat_w', rng(np).map(i => r(sym.plat_w + i)), e.plat_w);
  cmp('plat_moving', rng(np).map(i => r(sym.plat_moving + i)), e.plat_moving);
  cmp('plat_bouncy', rng(np).map(i => r(sym.plat_bouncy + i)), e.plat_bouncy);
  cmp('lad_x', rng(nl).map(i => w16('lad_xl', 'lad_xh', i)), e.lad_x);
  cmp('lad_y', rng(nl).map(i => s16(w16('lad_yl', 'lad_yh', i))), e.lad_y);
  cmp('lad_h', rng(nl).map(i => w16('lad_hl', 'lad_hh', i)), e.lad_h);
  cmp('lad_ext', rng(nl).map(i => r(sym.lad_ext + i)), e.lad_ext);
  cmp('draw_img', rng(nd).map(i => r(sym.draw_img + i)), e.draw_img);
  cmp('draw_x', rng(nd).map(i => w16('draw_xl', 'draw_xh', i)), e.draw_x);
  cmp('draw_y', rng(nd).map(i => w16('draw_yl', 'draw_yh', i)), e.draw_y);
  for (const k of ['kind', 'img', 'vy', 'plat', 'wait', 'simple']) cmp('sl_' + k, rng(ns).map(i => r(sym['sl_' + k] + i)), e['sl_' + k]);
  for (const k of ['x0', 'y0', 'amin', 'amax', 'bmin', 'bmax']) cmp('sl_' + k, rng(ns).map(i => s16(w16(`sl_${k}l`, `sl_${k}h`, i))), e['sl_' + k]);
  cmp('sl_v', rng(ns).map(i => r(sym.sl_vf + i) + 256 * r(sym.sl_vi + i)), e.sl_v);
  // the unrolled background: the line tables, the cell dictionary, the lines (columns or rows)
  const tables = Buffer.from(e.bg_tables, 'hex'), cells = Buffer.from(e.bg_cells, 'hex'), data = Buffer.from(e.bg_data, 'hex');
  const firstDiff = (what, n, got, want) => { for (let i = 0; i < n; i++) if (got(i) !== want(i)) { errs.push(`${what} differs at ${i} of ${n}: got ${got(i)} want ${want(i)}`); return; } };
  firstDiff('line tables', 512, i => bank(7, 0x8000 + i), i => tables[i]);
  firstDiff('dictionary', cells.length, i => { const n = i >> 3, l = i & 7; return bank(7, 0x8200 + (n >> 8) * 0x800 + l * 256 + (n & 255)); }, i => cells[i]);
  firstDiff('lines', data.length, i => bank(7, e.bg_start + i), i => data[i]);
  const want = { length: 512 + cells.length + data.length };
  checked++;
  if (errs.length) { bad++; console.log(names[li], 'FAIL'); for (const x of errs) console.log('   ', x.slice(0, 300)); }
  else console.log(names[li], 'ok', `(${np} platforms, ${nl} ladders, ${nd} objects, ${ns} moving, ${e.h > 256 ? 'rows' : 'columns'}, background ${want.length} bytes, ${cells.length / 8} distinct cells)`);
}
console.log(`${checked} levels checked, ${bad} failed`);
