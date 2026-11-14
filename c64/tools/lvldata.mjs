// Each level's own tables and numbers, for the level block (LVL: loader.asm unpacks the chosen
// level's there): from level.mjs's files in a level's directory (geometry.json, picks.json,
// scrub.json, patch.json). The tables are the ones build.mjs used to write into geometry.inc,
// collide.inc, masks.inc and scrpatch.inc for the one level; now each at a fixed place in the
// block, as long as the longest level's (layout), so the program's code is the same for any.
// Enemies have NS slots and gems and keys NP, whatever a level has: an enemy slot not used is
// knocked off for good (knock0), a gem's or key's never in the column masks. The masks are 24
// bits: bit k enemy k, bit NS + k gem or key k.
import { readFileSync } from 'fs';
export const NS = 9, NP = 12, Y0 = 24;
const BG = { cyan: 3, green: 5, red: 2 };
export function levelTables(dir, hiddenNC) {
    const J = f => JSON.parse(readFileSync(dir + f, 'utf8'));
    const g = J('geometry.json'), pj = J('picks.json'), sc = J('scrub.json'), pt = J('patch.json');
    const T = {}, S = {};
    const lo = v => v & 255, hi = v => (v >> 8) & 255;
    // (the platforms and ladders, as geometry.inc's; each 8-pixel column's lists)
    const P = g.plats, L = g.lads;
    Object.assign(T, { plat_xl: P.map(p => lo(p.x)), plat_xh: P.map(p => hi(p.x)), plat_yl: P.map(p => lo(p.y)), plat_yh: P.map(p => hi(p.y)), plat_w: P.map(p => p.w),
        lad_xl: L.map(l => lo(l.x)), lad_xh: L.map(l => hi(l.x)), lad_yl: L.map(l => lo(l.y)), lad_yh: L.map(l => hi(l.y)), lad_hl: L.map(l => lo(l.h)), lad_hh: L.map(l => hi(l.h)), lad_ext: L.map(l => l.ext) });
    const cols = items => { const NCOL = Math.ceil(g.w / 8) + 2, idx = [], lst = [];
        for (let c = 0; c < NCOL; c++) { idx.push(lst.length); for (const [a, b, i] of items) if (a <= c * 8 + 7 && b >= c * 8) lst.push(i); }
        idx.push(lst.length); if (lst.length > 255) throw new Error(`${dir}: a column list too long`); return { NCOL, idx, lst }; };
    const pc = cols(P.map((p, i) => [p.x, p.x + p.w - 1, i]).sort((a, b) => b[2] - a[2])), lc = cols(L.map((l, i) => [l.x - 6, l.x + 6, i]));
    Object.assign(T, { pcol: pc.idx, plist: pc.lst, lcol: lc.idx, llist: lc.lst });
    // (the enemies, as collide.inc's and masks.inc's: their boxes, their corners, their sprites' places)
    const sbx = pj.scrubBox || { x0: 0, x1: 0, y0: 0, y1: 0 }, E = sc.placed;
    if (E.length > NS) throw new Error(`${dir}: ${E.length} enemies, more than ${NS}`);
    const sl = E.map(p => p.ax + sbx.x0), sr = E.map(p => p.ax + sbx.x1);
    Object.assign(T, { scbll: sl.map(lo), scblh: sl.map(hi), scbrl: sr.map(lo), scbrh: sr.map(hi), scbc0: sl.map(v => v >> 3), scbc1: sr.map(v => v >> 3),
        scbt: E.map(p => p.ay + Y0 + sbx.y0), scbb: E.map(p => p.ay + Y0 + sbx.y1), scil: E.map(p => lo(p.ax)), scih: E.map(p => hi(p.ax)), scit: E.map(p => p.ay + Y0),
        scruby: E.map(p => 50 + p.sy), scl: E.map(p => lo(p.ax)), sch: E.map(p => hi(p.ax)), sct: E.map(p => p.ay + Y0), sxlo: E.map(p => lo(31 + p.sx)), sxhi: E.map(p => hi(31 + p.sx)),
        knock0: Array.from({ length: NS }, (_, k) => k < E.length ? 0 : 1) });
    // (the gems and keys)
    const pk = pj.picks;
    if (pk.length > NP) throw new Error(`${dir}: ${pk.length} gems and keys, more than ${NP}`);
    Object.assign(T, { pkll: pk.map(p => lo(p.left + p.box.x0)), pklh: pk.map(p => hi(p.left + p.box.x0)), pkrl: pk.map(p => lo(p.left + p.box.x1)), pkrh: pk.map(p => hi(p.left + p.box.x1)),
        pkc0: pk.map(p => (p.left + p.box.x0) >> 3), pkc1: pk.map(p => (p.left + p.box.x1) >> 3), pkt: pk.map(p => p.top + p.box.y0), pkb: pk.map(p => p.top + p.box.y1),
        pkkind: pk.map(p => p.name === 'IMG_Key' ? 2 : 1), pkil: pk.map(p => lo(p.left)), pkih: pk.map(p => hi(p.left)), pkit: pk.map(p => p.top), pkh: pk.map(p => pj.grids[p.name].length) });
    // (each column's objects and each band's of 32 lines, bit k: enemy k, NS + k gem or key k)
    const m = Array(100).fill(0), bm = Array(8).fill(0);
    const objs = [...E.map((p, k) => ({ bit: k, c: [sl[k] >> 3, sr[k] >> 3], y: [p.ay + Y0 + sbx.y0, p.ay + Y0 + sbx.y1] })),
        ...pk.map((p, k) => ({ bit: NS + k, c: [(p.left + p.box.x0) >> 3, (p.left + p.box.x1) >> 3], y: [p.top + p.box.y0, p.top + p.box.y1] }))];
    for (const o of objs) { for (let c = o.c[0]; c <= o.c[1]; c++) m[c] |= 1 << o.bit; for (let b = o.y[0] >> 5; b <= o.y[1] >> 5; b++) bm[b] |= 1 << o.bit; }
    Object.assign(T, { colml: m.map(v => v & 255), colmh: m.map(v => (v >> 8) & 255), colmx: m.map(v => (v >> 16) & 255), bandml: bm.map(v => v & 255), bandmh: bm.map(v => (v >> 8) & 255), bandmx: bm.map(v => (v >> 16) & 255) });
    // (the enemy's spans: each row's leftmost and rightmost solid pixel, 255 for an empty row)
    const spans = gr => gr.flatMap(r => { const xs = r.map((p, x) => p >= 0 ? x : -1).filter(x => x >= 0); return xs.length ? [xs[0], xs[xs.length - 1]] : [255, 255]; });
    T.scrsp = pj.grids.IMG_Scrubbly ? spans(pj.grids.IMG_Scrubbly) : [];
    // (the patches, as scrpatch.inc's)
    Object.assign(T, { scrpn: pt.scrpn, scrpi: pt.scrpi, pkpn: pt.pkpn, pkpi: pt.pkpi, scrplo: pt.cells.map(lo), scrphi: pt.cells.map(hi), scrpr: pt.scrpr, scrpc: pt.scrpc, scrpt: pt.scrpt, scrpb: pt.scrpb });
    // (the numbers: words as two bytes)
    const MAXX = (g.nc - 40) * 8, X_MAX = g.w - 10;
    Object.assign(S, { lv_nkeys: [pk.filter(p => p.name === 'IMG_Key').length], lv_tstartx: [lo(g.trogg[0]), hi(g.trogg[0])], lv_tstarty: [lo(g.trogg[1]), hi(g.trogg[1])],
        lv_levh: [lo(g.h), hi(g.h)], lv_levh1: [lo(g.h - 1), hi(g.h - 1)], lv_maxx: [lo(MAXX), hi(MAXX)], lv_maxc: [MAXX / 8], lv_xmax: [lo(X_MAX), hi(X_MAX)],
        lv_pcoln: [pc.NCOL], lv_scrh: [pj.grids.IMG_Scrubbly ? pj.grids.IMG_Scrubbly.length : 0], lv_enw: [sc.w], lv_enh: [sc.h], lv_enmc: [sc.mc ? 1 : 0],
        lv_encol: [sc.mc ? 0 : 4], lv_bg: [BG[sc.background]] });
    return { T, S, npatch: pt.cells.length };
}
// The layout: each table as long as the longest level's (enemy and gem tables NS and NP long), the
// numbers first; and each level's block
export function layout(levels, base) {
    const fixed = { scbll: NS, scblh: NS, scbrl: NS, scbrh: NS, scbc0: NS, scbc1: NS, scbt: NS, scbb: NS, scil: NS, scih: NS, scit: NS, scruby: NS, scl: NS, sch: NS, sct: NS, sxlo: NS, sxhi: NS, knock0: NS, scrpn: NS, scrpi: NS,
        pkll: NP, pklh: NP, pkrl: NP, pkrh: NP, pkc0: NP, pkc1: NP, pkt: NP, pkb: NP, pkkind: NP, pkil: NP, pkih: NP, pkit: NP, pkh: NP, pkpn: NP, pkpi: NP };
    const sNames = Object.keys(levels[0].S), tNames = Object.keys(levels[0].T);
    const size = n => fixed[n] ?? Math.max(...levels.map(l => l.T[n].length));
    let off = 0; const at = {};
    for (const n of sNames) { at[n] = off; off += levels[0].S[n].length; }
    for (const n of tNames) { at[n] = off; off += Math.max(1, size(n)); }
    const blocks = levels.map(l => { const b = Buffer.alloc(off);
        for (const n of sNames) l.S[n].forEach((v, i) => b[at[n] + i] = v);
        for (const n of tNames) { if (l.T[n].length > Math.max(1, size(n))) throw new Error(`${n}: too long`); l.T[n].forEach((v, i) => b[at[n] + i] = v); }
        return b; });
    const inc = `; made by tools/build.mjs (lvldata.mjs): the level block's layout, at LVL (each level's unpacked there: loader.asm)\n` +
        `LVLSIZE = ${off}\nNS = ${NS}\nNP = ${NP}\nNPATCH = ${Math.max(...levels.map(l => l.npatch))}\n` +
        [...sNames, ...tNames].map(n => `${n.padEnd(10)}= LVL + ${at[n]}`).join('\n') + '\n';
    return { inc, blocks, size: off };
}
