// The web page (build/frak-ep128.html: web/build_page.py) in a real browser: headless Chromium,
// through Playwright. The page starts the game with no ROMs; this checks the attract screen is
// drawn, then plays through the menus as front.mjs does (Space for the menus, K down to the
// Classic group, Space, Space for its first level) with the browser's own key events, and checks
// the game's variables (the page leaves the emulator at window.enterprise): level 1 started, its
// frames drawn at the real machine's rate, and Trogg climbing the ladder he starts at while O is held. Screenshots in
// build/shots/web_*.png.
//
//   web/build_emulator.sh && python3 web/build_page.py && node tools/emu/web.mjs
import { createRequire } from 'module';
import { existsSync, mkdirSync } from 'fs';
import { join } from 'path';
import { symbols, ROOT } from './harness.mjs';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const sym = symbols();
const shots = join(ROOT, 'build', 'shots');
if (!existsSync(shots)) mkdirSync(shots, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1000, height: 1200 } });
const errors = [];
page.on('pageerror', e => errors.push(e.message));
page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
await page.goto('file://' + join(ROOT, 'build', 'frak-ep128.html'));

// a byte of the game's: the low RAM (#F8) or, from #4000, the logic segment (#FA)
const peek = (a, n = 1) => page.evaluate(([a, n, logic]) => {
    const E = window.enterprise, out = [];
    for (let k = 0; k < n; k++) out.push(a + k < 0x4000 ? E._web_peek(0xF8, a + k) : E._web_peek(logic, a + k - 0x4000));
    return out;
}, [a, n, sym.seg_logic]);
const word = async a => { const [lo, hi] = await peek(a, 2); return lo | hi << 8; };
const lit = () => page.evaluate(() => {
    const d = document.getElementById('tv').getContext('2d').getImageData(0, 0, 768, 288).data;
    let n = 0; for (let i = 0; i < d.length; i += 4) if (d[i] | d[i + 1] | d[i + 2]) n++;
    return n;
});
const press = async (code, ms = 120) => { await page.keyboard.down(code); await page.waitForTimeout(ms); await page.keyboard.up(code); };
let failed = 0;
const check = (ok, msg) => { console.log(`  ${ok ? 'ok' : 'FAIL'} ${msg}`); if (!ok) failed++; };

await page.waitForTimeout(3000);
check(await page.locator('#status').textContent() === 'Running', 'the page says the emulator is running');
const px = await lit();
check(px > 100000, `the attract screen is drawn (${px} pixels lit)`);
await page.locator('#tv').screenshot({ path: join(shots, 'web_attract.png') });

await page.click('#tv');
await press('Space'); await page.waitForTimeout(1500);
await page.locator('#tv').screenshot({ path: join(shots, 'web_menus.png') });
await press('KeyK'); await page.waitForTimeout(500);
check((await peek(sym.fe_sel))[0] === 3, `K moved down to the Classic group (fe_sel ${(await peek(sym.fe_sel))[0]})`);
await press('Space'); await page.waitForTimeout(1500);
await press('Space'); await page.waitForTimeout(8000);
check((await peek(sym.cur_level))[0] === 1, `level 1 started (cur_level ${(await peek(sym.cur_level))[0]})`);
const f0 = await word(sym.frames_drawn), t0 = Date.now();
await page.waitForTimeout(3000);
const f1 = await word(sym.frames_drawn), secs = (Date.now() - t0) / 1000;
const fps = (f1 - f0) / secs;
check(fps > 8 && fps <= 26, `frames drawn: ${fps.toFixed(1)} a second (A_1: about 16 on the real machine)`);
// (he starts at the foot of a ladder, on a ledge his own width: O climbs it)
const y0 = await word(sym.ty);
await page.keyboard.down('KeyO'); await page.waitForTimeout(1000); await page.keyboard.up('KeyO');
const y1 = await word(sym.ty);
check(y1 < y0 - 20, `Trogg climbed with O held (y ${y0} to ${y1})`);
await page.locator('#tv').screenshot({ path: join(shots, 'web_level.png') });
await page.screenshot({ path: join(shots, 'web_page.png'), fullPage: true });

check(errors.length === 0, `no errors on the page${errors.length ? ': ' + errors.join('; ') : ''}`);
await browser.close();
console.log(failed ? `${failed} failed` : 'all passed');
process.exit(failed ? 1 : 0);
