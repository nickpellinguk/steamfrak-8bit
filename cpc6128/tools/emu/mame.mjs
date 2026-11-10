// The CPC 6128 test harness: runs build/frak.dsk on MAME (its cpc6128 driver, headless and
// unthrottled), working through a list of steps (see steps.lua), and returns what they printed
// and the screenshots they took.
//
//   import { symbols, run, boot, readPng } from './mame.mjs';
//
// MAME needs the CPC 6128's ROMs: a directory holding cpc6128/cpc6128.rom (the OS and BASIC, 32K)
// and cpc6128/cpcados.rom (AMSDOS, 16K), named by CPC_ROMS (MAME checks them against its own
// checksums). MAME itself is found as MAME, else /usr/games/mame.
import { spawnSync } from 'child_process';
import { readFileSync, writeFileSync, mkdtempSync, readdirSync, existsSync } from 'fs';
import { inflateSync } from 'zlib';
import { tmpdir } from 'os';
import { join, resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const HERE = dirname(fileURLToPath(import.meta.url));
export const ROOT = resolve(HERE, '../..');

// The assembler's symbols (build/frak.sym: "NAME #ADDR B0 L"), by lower-case name
export function symbols(file = join(ROOT, 'build/frak.sym')) {
    const sym = {};
    for (const line of readFileSync(file, 'utf8').split('\n')) {
        const m = line.match(/^(\S+)\s+#([0-9A-F]+)/i);
        if (m) sym[m[1].toLowerCase()] = parseInt(m[2], 16);
    }
    return sym;
}

// Steps for the start: boot to BASIC, then RUN"FRAK.BIN, and wait until it has loaded and taken
// the machine over (it sets `ready` to READY)
export const READY = 0xA5;
export const boot = ['wait 100', 'type RUN"FRAK.BIN\\n', `waitfor ${symbols().ready} ${READY} 3000`, `poke ${symbols().t_harness} 1`, 'wait 2'];
// (... without the harness saying it's there: the game starts by itself, at the attract screen)
export const bootGame = ['wait 100', 'type RUN"FRAK.BIN\\n', `waitfor ${symbols().ready} ${READY} 3000`];

// Run the steps (strings, as steps.lua takes them; a final "quit" is added). Returns
// { peeks: {label: [bytes]}, snaps: {label: png file}, log }.
export function run(steps, { seconds = 120 } = {}) {
    const dir = mkdtempSync(join(tmpdir(), 'cpc-'));
    const stepsFile = join(dir, 'steps.txt');
    writeFileSync(stepsFile, [...steps, 'quit'].join('\n') + '\n');
    const roms = process.env.CPC_ROMS;
    if (!roms) throw new Error('CPC_ROMS must name the directory holding the cpc6128 ROMs');
    const args = ['cpc6128', '-rompath', roms, '-flop1', join(ROOT, 'build/frak.dsk'),
        '-video', 'none', '-sound', 'none', '-nothrottle', '-skip_gameinfo', '-nomouse',
        '-snapshot_directory', join(dir, 'snap'), '-snapname', 'shot%i',
        '-cfg_directory', join(dir, 'cfg'), '-nvram_directory', join(dir, 'nvram'),
        '-seconds_to_run', String(seconds), '-autoboot_script', join(HERE, 'steps.lua')];
    const r = spawnSync(process.env.MAME || '/usr/games/mame', args,
        { env: { ...process.env, CPC_STEPS: stepsFile }, encoding: 'utf8', maxBuffer: 1 << 26 });
    const log = (r.stdout || '') + (r.stderr || '');
    const timeout = log.match(/^OUT timeout (\d+) (\d+)/m);
    if (timeout) {
        const name = Object.entries(symbols()).find(([, v]) => v === Number(timeout[1]));
        const at = Number(timeout[2]);
        throw new Error(`Timed out waiting on ${name ? name[0] : timeout[1]}` +
            (name && name[0] === 'ready' ? ' (the program never got going)' : '') +
            `, at step ${at} (${(log.match(/^OUT stuck (.*)$/m) || [])[1]}); the steps before it:\n  ` + steps.slice(Math.max(0, at - 12), at + 1).join('\n  '));
    }
    if (!/^OUT done/m.test(log)) throw new Error('MAME stopped before the steps finished:\n' + log);
    const peeks = {}, snaps = {}, times = {}, keys = [];
    const shots = (existsSync(join(dir, 'snap')) ? readdirSync(join(dir, 'snap'), { recursive: true }) : []).filter(f => f.endsWith('.png'))
        .sort((a, b) => parseInt(a.match(/(\d+)\.png$/)[1]) - parseInt(b.match(/(\d+)\.png$/)[1]));
    let n = 0;
    for (const line of log.split('\n')) {
        let m;
        if ((m = line.match(/^OUT (?:peek|bank) (\S+) ?(.*)$/))) peeks[m[1]] = m[2].split(' ').filter(x => x).map(Number);
        else if ((m = line.match(/^OUT time (\S+) (\S+)/))) times[m[1]] = Number(m[2]);
        else if ((m = line.match(/^OUT key (\d+) (\d+) (.*)$/))) keys.push({ row: +m[1], mask: +m[2], name: m[3] });
        else if ((m = line.match(/^OUT snap (\S+)/))) snaps[m[1]] = join(dir, 'snap', shots[n++]);
    }
    // a dump step's bytes, as a Buffer
    const dump = label => readFileSync(join(dir, label + '.bin'));
    return { peeks, snaps, times, keys, dump, log, dir };
}

// A PNG (8-bit RGB or RGBA, as MAME writes them) as { w, h, px(x, y) -> [r, g, b] }
export function readPng(file) {
    const buf = readFileSync(file);
    let pos = 8, w, h, channels, idat = [];
    while (pos < buf.length) {
        const len = buf.readUInt32BE(pos), type = buf.toString('ascii', pos + 4, pos + 8);
        const data = buf.subarray(pos + 8, pos + 8 + len);
        if (type === 'IHDR') {
            w = data.readUInt32BE(0); h = data.readUInt32BE(4);
            if (data[8] !== 8 || (data[9] !== 2 && data[9] !== 6)) throw new Error('unsupported PNG');
            channels = data[9] === 6 ? 4 : 3;
        } else if (type === 'IDAT') idat.push(data);
        pos += 12 + len;
    }
    const raw = inflateSync(Buffer.concat(idat)), stride = w * channels;
    const out = Buffer.alloc(stride * h);
    for (let y = 0; y < h; y++) {
        const f = raw[y * (stride + 1)], line = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1));
        for (let x = 0; x < stride; x++) {
            const a = x >= channels ? out[y * stride + x - channels] : 0;
            const b = y > 0 ? out[(y - 1) * stride + x] : 0;
            const c = x >= channels && y > 0 ? out[(y - 1) * stride + x - channels] : 0;
            let v = line[x];
            if (f === 1) v += a;
            else if (f === 2) v += b;
            else if (f === 3) v += (a + b) >> 1;
            else if (f === 4) { const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c); v += pa <= pb && pa <= pc ? a : pb <= pc ? b : c; }
            out[y * stride + x] = v & 255;
        }
    }
    return { w, h, px: (x, y) => { const i = y * stride + x * channels; return [out[i], out[i + 1], out[i + 2]]; } };
}
