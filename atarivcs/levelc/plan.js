// Export a screen's row plan from the editor (its own analysis, so the ROM matches what the editor
// checked): node plan.js EDITOR_HTML OUT_JSON [PROJECT_JSON] [TYPE_INDEX] [SCREEN_INDEX]
const { chromium } = require('playwright');
const fs = require('fs');
(async () => {
  const [html, out, proj, ti, si] = process.argv.slice(2);
  const b = await chromium.launch(); const p = await b.newPage();
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  await p.goto('file://' + require('path').resolve(html));
  const plan = await p.evaluate(([projText, ti, si]) => {
    if (projText) P = normalise(JSON.parse(projText));
    typeI = +ti || 0; scrI = +si || 0;
    const s = scr(), g = P.graphics, T = P.types[typeI];
    const rows = analyzeScreen(s);
    const runs = [];
    for (let r = 0; r < ROWS; ) {
      let e = r; while (e < ROWS && rows[e].key === rows[r].key) e++;
      const A = rows[r];
      const lines = [];
      for (let y = 2 * r; y < 2 * e; y++) {
        const L = {}, rr = y >> 1;
        const plat = s.platforms.find(q => rr >= q.top && rr < q.top + q.rows);
        L.Stripe = plat ? g.stripes[Math.min(y - 2 * plat.top, g.stripes.length - 1)] : 0;
        for (const reg of ['PF1', 'PF2']) { L['L' + reg] = FrakMirror.value(A.lit, reg, 'L'); L['R' + reg] = FrakMirror.value(A.lit, reg, 'R'); }
        let k = 0;
        for (const o of A.objs) {
          if (o.t === 'L') { L.Lad = ladderByte(s.ladders[o.ref[1]], y); continue; }
          let gv = 0, cv = 0;
          if (o.ref[0] === 'ladder') gv = ladderByte(s.ladders[o.ref[1]], y);
          else { const it = s.items[o.ref[1]], d = itemDef(it.kind), [a] = itemLines(it); const i = y - a; if (i >= 0 && i < d.rows.length) { gv = d.rows[i]; cv = d.colours[i] ?? d.colour; } }
          L['G' + k] = gv; L['C' + k] = cv; k++;
        }
        lines.push(L);
      }
      runs.push({ r, n: e - r, key: A.key, way: A.way, tasks: A.tasks || null, errors: A.errors,
        objs: A.objs.map(o => ({ t: o.t, x: o.x, ref: o.ref })), lit: [...A.lit].sort((a, c) => a - c), lines });
      r = e;
    }
    return { name: s.name, background: g.background, trogg: { x: s.trogg.x, row: s.trogg.row, colour: g.trogg.colour, frames: g.trogg.frames },
      platforms: s.platforms, ladders: s.ladders, items: s.items.map(it => ({ ...it, top: itemLines(it)[0] })), runs };
  }, [proj ? fs.readFileSync(proj, 'utf8') : null, ti, si]);
  if (errs.length) { console.error(errs); process.exit(1); }
  fs.writeFileSync(out, JSON.stringify(plan));
  await b.close();
})();
