// The Enterprise 128 test harness: runs the program on MAME (its ep128 driver, with an EXDOS
// card, headless and unthrottled), working through a list of steps (see steps.lua), and returns
// what they printed and the screenshots they took. As the CPC version's mame.mjs.
//
//   import { symbols, run, boot, readPng } from './mame.mjs';
//
// MAME needs the Enterprise's ROMs, from a directory named by EP_ROMS (MAME checks them against
// its own checksums):
//   ep128/9256ds-0019_enter08-45-a.u2   EXOS 2.1 and the word processor (32K)
//   ep64_exdos/exdos13.rom              EXDOS 1.3 (32K)
// MAME itself is found as MAME, else /usr/games/mame.
//
// Until the disk image starts the program by itself (phase 8), `boot` puts FRAK.COM where EXOS
// would load it, at #0100 in the segment at page 0, once EXOS has started, and jumps to it.
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

// FRAK.COM without its EXOS header (16 bytes), as EXOS would load it at #0100
function program() {
    const com = readFileSync(join(ROOT, 'build/FRAK.COM'));
    if (com[0] !== 0 || com[1] !== 5) throw new Error('build/FRAK.COM is not an EXOS type 5 file');
    const file = join(mkdtempSync(join(tmpdir(), 'ep-')), 'frak.bin');
    writeFileSync(file, com.subarray(16, 16 + com.readUInt16LE(2)));
    return file;
}

// Steps for the start: wait for EXOS to start up, then load the program and run it, and wait
// until it has taken the machine over (it sets `ready` to READY)
export const READY = 0xA5;
export const EXOS_FRAMES = Number(process.env.EP_EXOS_FRAMES || 400);
export function boot() {
    return [`wait ${EXOS_FRAMES}`, `load 256 ${program()}`, 'jump 256', `waitfor ${symbols().ready} ${READY} 500`];
}

// Run the steps (strings, as steps.lua takes them; a final "quit" is added). Returns
// { peeks: {label: [bytes]}, snaps: {label: png file}, times, keys, dump(label), log, dir }.
export function run(steps, { seconds = 120, disk = true } = {}) {
    const dir = mkdtempSync(join(tmpdir(), 'ep-'));
    const stepsFile = join(dir, 'steps.txt');
    writeFileSync(stepsFile, [...steps, 'quit'].join('\n') + '\n');
    const roms = process.env.EP_ROMS;
    if (!roms) throw new Error('EP_ROMS must name the directory holding the Enterprise ROMs (see mame.mjs)');
    const args = ['ep128', '-rompath', roms, '-exp', 'exdos',
        ...(disk ? ['-flop1', join(ROOT, 'build/frak.img')] : []),
        '-video', 'none', '-sound', 'none', '-nothrottle', '-skip_gameinfo', '-nomouse',
        '-snapshot_directory', join(dir, 'snap'), '-snapname', 'shot%i',
        '-cfg_directory', join(dir, 'cfg'), '-nvram_directory', join(dir, 'nvram'),
        '-seconds_to_run', String(seconds), '-autoboot_script', join(HERE, 'steps.lua')];
    const r = spawnSync(process.env.MAME || '/usr/games/mame', args,
        { env: { ...process.env, EP_STEPS: stepsFile }, encoding: 'utf8', maxBuffer: 1 << 26 });
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
        if ((m = line.match(/^OUT peek (\S+) ?(.*)$/))) peeks[m[1]] = m[2].split(' ').filter(x => x).map(Number);
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
