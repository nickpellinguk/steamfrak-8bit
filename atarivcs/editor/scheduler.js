// The renderer scheduler, ported from the Python one the Stella-verified tests use
// (atarivcs/test/fr_screen.py's schedule, as adapted in screens2.py and tools/feasibility.py:
// A and Y as working registers, X the line index, the ghost rule, one GRP1 write for consecutive
// objects with the same graphics, the spare (parking) strobe after a single object).
// tools/checkScheduler.py compares the two.
//
// schedule(objs, prevLastColour, prevHadObjs, prevLastX, t0, endLimit, extra)
//   objs: [{x, gfx, col}] in x order; gfx/col are ['imm', value] or ['tbl', name] (col also ['none', 0])
//   extra: [[lo, hi, [load, cycles], register]]: stores that must END within [lo, hi]
// Returns {end, strobes} (strobe end cycles) or null if nothing fits.
(function (root) {
  'use strict';
  const same = (a, b) => a[0] === b[0] && a[1] === b[1];
  const load = src => src[0] === 'imm' ? ['lda #$' + (src[1] & 255).toString(16).toUpperCase().padStart(2, '0'), 2] : ['lda ' + src[1] + ',x', 4];
  const ceilDiv3 = a => Math.ceil(a / 3);

  function schedule1(objs, prevLastColour, prevHadObjs, prevLastX, t0, endLimit, extra, park) {
    const tasks = [];                               // [lo, hi, ins, len, reg]
    objs = objs.slice();
    // a single object with no room to clear GRP1 and park P1 after it: an invisible copy at x 19
    // first (strobed in the horizontal blank, drawn with GRP1 = 0), so the row has two strobes
    if (objs.length === 1 && ceilDiv3(68 + objs[0].x + 8) + 3 > endLimit)
      objs.unshift({ x: 19, gfx: ['imm', 0], col: ['none', 0] });
    let afterMain = 0;
    if (prevLastX !== null && prevLastX !== undefined && objs.length) {
      const main = prevLastX - 16;
      const c0 = objs[0].col[0] === 'none' ? 3 : Math.floor((objs[0].x + 47) / 3);
      if (c0 >= Math.floor((prevLastX + 47) / 3)) {
        tasks.push([0, Math.floor((68 + main) / 3), 'lda #0', 2, 'GRP1']);
        afterMain = ceilDiv3(68 + main + 8);
      }
    }
    const strobes = [];
    let prevEnd = 0, prevCol = null;
    objs.forEach((o, k) => {
      let c = Math.floor((o.x + 47) / 3);
      if (o.col[0] === 'none') c = t0 + 3;
      const start = (68 + o.x) / 3;
      let hi = Math.floor(start);
      if (hi === start) hi -= 1;
      strobes.push(c);
      let lo = prevEnd;
      if (afterMain && (68 + o.x) / 3 > afterMain - 1) lo = Math.max(lo, afterMain);
      if (k === 0 || !same(o.gfx, objs[k - 1].gfx) || objs[k - 1].col[0] === 'none') {
        const [ins, len] = load(o.gfx); tasks.push([lo, hi, ins, len, 'GRP1']);
      }
      let need;
      if (o.col[0] === 'none' || o.col[0] === 'fake') need = false;
      else if (k === 0 || (prevCol && prevCol[0] === 'none')) {
        const startCol = objs[objs.length - 1].col;
        need = o.col[0] === 'tbl' || !same(o.col, startCol) || !prevLastColour || !same(o.col, prevLastColour);
      } else need = o.col[0] === 'tbl' || prevCol === null || !same(o.col, prevCol);
      if (need) { const [ins, len] = load(o.col); tasks.push([prevEnd, hi, ins, len, 'COLUP1']); }
      prevEnd = ceilDiv3(68 + o.x + 8);
      prevCol = o.col[0] !== 'none' && o.col[0] !== 'fake' ? o.col : prevCol;
    });
    if (objs.length === 1) tasks.push([prevEnd, endLimit, 'lda #0', 2, 'GRP1']);
    if (!objs.length && prevHadObjs) tasks.push([0, endLimit, 'lda #0', 2, 'GRP1']);
    for (const [lo, hi, [ins, len], reg] of extra) tasks.push([lo, hi, ins, len, reg]);

    const n = tasks.length, fail = new Set();
    function search(t, rem, si, ha, hx) {
      const key = t + '|' + rem + '|' + si + '|' + ha + '|' + hx;
      if (fail.has(key)) return null;
      if (rem === 0 && si === strobes.length) return t;
      const nxt = si < strobes.length ? strobes[si] : null;
      const limit = nxt !== null ? nxt - 3 : endLimit;
      for (let i = 0; i < n; i++) if (rem & (1 << i)) {
        const [lo, hi, ins, len] = tasks[i];
        const need = (ins === ha || ins === hx) ? 3 : len + 3;
        if (Math.max(t + need, lo) > hi) { fail.add(key); return null; }
      }
      const ok = end => end <= limit && (nxt === null || limit - end !== 1);
      const opts = [], loads = new Set();
      for (let i = 0; i < n; i++) if (rem & (1 << i)) {
        const [lo, hi, ins, len] = tasks[i];
        for (const r of ['a', 'x']) {
          const held = r === 'a' ? ha : hx;
          if (held === ins) {
            for (const st of [3, 4]) {
              const land = Math.max(t + st, lo);
              if (land - st - t === 1 || land > hi || !ok(land)) continue;
              opts.push([hi, 0, land, st, i, r, 'store']);
            }
          } else if (ins !== ha && ins !== hx && !loads.has(ins + r) && ok(t + len)) {
            loads.add(ins + r);
            opts.push([hi, 1, t + len, 0, i, r, 'load']);
          }
        }
      }
      opts.sort((p, q) => { for (let j = 0; j < 6; j++) { if (p[j] < q[j]) return -1; if (p[j] > q[j]) return 1; } return 0; });
      for (const [, , end, , i, r, what] of opts) {
        const ins = tasks[i][2];
        let res;
        if (what === 'store') res = search(end, rem & ~(1 << i), si, ha, hx);
        else res = search(end, rem, si, r === 'a' ? ins : ha, r === 'x' ? ins : hx);
        if (res !== null) return res;
      }
      if (nxt !== null && nxt - 3 - t >= 0) {
        const res = search(nxt, rem, si + 1, ha, hx);
        if (res !== null) return res;
      }
      fail.add(key);
      return null;
    }
    if (n > 30) return null;
    let end = search(t0, n ? (2 ** n - 1) : 0, 0, null, null);
    if (end === null) return null;
    // a single object: park P1 after its copy with one more strobe (GRP1 is already 0, so its copy
    // is invisible); the row's last strobe is then late, and the next renderer's first strobe
    // cancels the ghost (the Python scheduler's 'spare' strobe)
    let parked = false;
    if (objs.length === 1 && park) {
      let gap = Math.max(0, prevEnd + 3 - 3 - end);
      if (gap === 1) gap = 2;
      if (end + gap + 3 <= endLimit) { end += gap + 3; strobes.push(end); parked = true; }
      // (no room after a far-right object: the row still fits, unparked; the ghost rule then
      // applies at the next renderer change)
    }
    if (end > endLimit) return null;
    return { end, strobes, parked };
  }
  // parked where there's room, else unparked; a single object that still doesn't fit gets an
  // invisible copy (GRP1 = 0, 'fake') strobed at the first x from 19 to its x - 21 that fits
  function schedule(objs, prevLastColour, prevHadObjs, prevLastX, t0, endLimit, extra) {
    const a = [prevLastColour, prevHadObjs, prevLastX, t0, endLimit, extra];
    let r = schedule1(objs, ...a, true);
    if (r || objs.length !== 1) return r;
    for (let fx = 19; fx <= objs[0].x - 21; fx += 3) {
      r = schedule1([{ x: fx, gfx: ['imm', 0], col: ['fake', 0] }, objs[0]], ...a, false);
      if (r) return { ...r, fakeAt: fx };
    }
    return null;
  }
  if (typeof module !== 'undefined') module.exports = { schedule };
  else root.FrakScheduler = { schedule };
})(this);
