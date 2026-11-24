// Mirrored-playfield rows: the timed writes a row's platforms need, from its actual lit blocks.
// A port of atarivcs/tools/mirrorrows.py (see there for the measured rules); checkScheduler.py
// compares the two.
(function (root) {
  'use strict';
  const BG = 0xAA, REGS = ['PF1', 'PF2'];
  function blocksOf(reg, side) {
    const out = [];
    for (let i = 0; i < 8; i++) {
      if (reg === 'PF1') out.push(side === 'L' ? [4 + i, 7 - i] : [28 + i, i]);
      else out.push(side === 'L' ? [12 + i, i] : [20 + i, 7 - i]);
    }
    return out;
  }
  const value = (lit, reg, side) => blocksOf(reg, side).reduce((v, [k, b]) => lit.has(k) ? v | (1 << b) : v, 0);
  const blockOf = (reg, side, bit) => blocksOf(reg, side).find(([, b]) => b === bit)[0];
  const pfNewBy = x => Math.floor((x + 66) / 3), pfOldUntil = x => Math.floor((x + 66) / 3) + 1;
  const colNewBy = x => Math.floor((x + 68) / 3), colOldUntil = x => Math.floor((x + 68) / 3) + 1;
  const hex = v => '$' + (v & 255).toString(16).toUpperCase().padStart(2, '0');
  const T = (name, lo, hi, reg) => [lo, hi, ['lda ' + name + ',x', 4], reg];
  const IMM = (v, lo, hi, reg) => [lo, hi, ['lda #' + hex(v), 2], reg];
  const bits = d => { const o = []; for (let b = 0; b < 8; b++) if (d >> b & 1) o.push(b); return o; };
  function dedupe(tk) {
    const m = new Map();
    for (const [lo, hi, ld, reg] of tk) {
      const k = ld[0] + '|' + reg;
      if (m.has(k)) { const e = m.get(k); e[0] = Math.max(e[0], lo); e[1] = Math.min(e[1], hi); }
      else m.set(k, [lo, hi, ld, reg]);
    }
    return [...m.values()];
  }
  // lit: Set of lit blocks; prev: {col: 'bg'|'stripe', PF1, PF2} or null. Returns [[way, tasks, endState]].
  function tasks(lit, prev) {
    if (!prev) prev = { col: 'bg', PF1: 0, PF2: 0 };
    for (const k of lit) if (k < 4 || k > 35) return [];
    const L = {}, R = {};
    for (const r of REGS) { L[r] = value(lit, r, 'L'); R[r] = value(lit, r, 'R'); }
    const out = [], litX = [...lit].map(k => 4 * k).sort((a, b) => a - b);
    const regsOf = o => ({ PF1: o.PF1, PF2: o.PF2 });
    if (!lit.size) {
      const vis = [];
      for (const r of REGS) for (const side of 'LR') for (const [k, b] of blocksOf(r, side)) if (prev[r] >> b & 1) vis.push(4 * k);
      if (prev.col === 'stripe' && vis.length) out.push(['blank', [IMM(BG, 0, colNewBy(Math.min(...vis)), 'COLUPF')], { col: 'bg', ...regsOf(prev) }]);
      else out.push(['blank', [], { col: prev.col, ...regsOf(prev) }]);
      return out;
    }
    const first = litX[0];
    let tk = [T('Stripe', 0, colNewBy(first), 'COLUPF')], ok = true;
    for (const r of REGS) {
      for (const P of new Set([prev[r], R[r]])) {
        const diff = L[r] ^ P;
        if (diff) {
          const xs = bits(diff).map(b => 4 * blockOf(r, 'L', b));
          tk.push(L[r] ? T('L' + r, 0, pfNewBy(Math.min(...xs)), r) : IMM(0, 0, pfNewBy(Math.min(...xs)), r));
        }
      }
      if (L[r] !== R[r]) {
        const d = bits(L[r] ^ R[r]);
        const lo = Math.max(...d.map(b => pfOldUntil(4 * blockOf(r, 'L', b))));
        const hi = Math.min(...d.map(b => pfNewBy(4 * blockOf(r, 'R', b))));
        if (lo > hi) ok = false;
        tk.push(R[r] ? T('R' + r, lo, hi, r) : IMM(0, lo, hi, r));
      }
    }
    if (ok) out.push(['rewrite', dedupe(tk), { col: 'stripe', ...R }]);
    if (!R.PF1 && !R.PF2) {
      const last = litX[litX.length - 1] + 3, mirrorFirst = Math.min(...[...lit].map(k => 4 * (39 - k)));
      tk = [T('Stripe', 0, colNewBy(first), 'COLUPF'), IMM(BG, colOldUntil(last), colNewBy(mirrorFirst), 'COLUPF')];
      for (const r of REGS) if (L[r] !== prev[r]) {
        const xs = bits(L[r] ^ prev[r]).map(b => 4 * blockOf(r, 'L', b));
        tk.push(L[r] ? T('L' + r, 0, pfNewBy(Math.min(...xs)), r) : IMM(0, 0, pfNewBy(Math.min(...xs)), r));
      }
      out.push(['hide', dedupe(tk), { col: 'bg', ...L }]);
    }
    if (!L.PF1 && !L.PF2) {
      const copy = [...lit].map(k => 4 * (39 - k)).sort((a, b) => a - b), rfirst = litX[0];
      tk = [IMM(BG, 0, colNewBy(copy[0]), 'COLUPF'), T('Stripe', colOldUntil(copy[copy.length - 1] + 3), colNewBy(rfirst), 'COLUPF')];
      for (const r of REGS) if (R[r] !== prev[r]) {
        const xs = bits(R[r] ^ prev[r]).map(b => 4 * blockOf(r, 'R', b));
        tk.push(R[r] ? T('R' + r, 0, pfNewBy(Math.min(...xs)), r) : IMM(0, 0, pfNewBy(Math.min(...xs)), r));
      }
      out.push(['hide', dedupe(tk), { col: 'stripe', ...R }]);
    }
    return out;
  }
  const api = { tasks, value, REGS };
  if (typeof module !== 'undefined') module.exports = api; else root.FrakMirror = api;
})(this);
