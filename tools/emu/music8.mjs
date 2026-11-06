// The music checker: does the 6502 player play the tunes as the Steam (HTML5) version does?
//
//   ./build.sh && cd tools/emu && node music8.mjs [tune ...] [--detail]
//
// The reference is the steamfrak repository's js/audio.js itself (STEAMFRAK, default ../steamfrak
// alongside this one), run here with its WebAudio calls replaced by ones that just remember each
// voice's pitch and gain, stepped at 60Hz as the game steps it.
//
// The 6502 side is the game's own player (src/sound.asm): jsbeeb boots the disc, then main RAM and
// the music bank are copied and snd_tick is run on a small 6502 interpreter (cpu6502.mjs), 50 times
// a second, with the sound chip writes caught and decoded.
//
// For each note of each tone track (the drums aren't checked), it looks for that pitch on one of
// the sound chip's three tone channels while the note is sounding, and reports the notes that
// are missing (or only there an octave out) for each track.
import { MachineSession } from 'jsbeeb';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
import vm from 'vm';
import { Cpu6502 } from './cpu6502.mjs';

const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const STEAMFRAK = process.env.STEAMFRAK || resolve(REPO, '../steamfrak');
const args = process.argv.slice(2);
const DETAIL = args.includes('--detail');
const TUNES = ['FRAK', 'WEED', 'MAN', 'VICTORY', 'INTRO', 'SELECT', 'LEVELS'];
const only = args.filter(a => TUNES.includes(a));
const SECONDS = +((args.find(a => a.startsWith('--seconds=')) || '').split('=')[1] || 100);

// ---- The Steam version's music engine, at 60Hz
function webTune(index) {
    const ctx = { console, Math, Object, Array, Set, JSON };
    vm.createContext(ctx);
    const src = readFileSync(STEAMFRAK + '/js/audio.js', 'utf8');
    const engine = readFileSync(STEAMFRAK + '/js/engine.js', 'utf8');
    const fn = name => { const a = engine.indexOf('function ' + name + '('); return engine.slice(a, engine.indexOf('\n}', a) + 2); };
    const helpers = ['sign', 'clamp'].map(n => engine.match(new RegExp('^function ' + n + '\\(.*$', 'm'))[0]).join('\n') + '\n' + fn('gmlRound');
    vm.runInContext(src.replace(/'use strict';/, '') + '\n' + helpers + `
        var G = { MusicOption: 2, SoundsOption: 1 };
        Snd.ctx = { currentTime: 0 };
        function audioPlay(name, loop, pan) {
            const h = { name, ratio: 1, base: 1, level: 1, from: 1, to: 1, t0: 0, t1: 0, stopped: false,
                        gain: { gain: { cancelScheduledValues() {}, setValueAtTime() {}, linearRampToValueAtTime() {} } } };
            return h;
        }
        function audio_stop_sound(h) { if (h) h.stopped = true; }
        function audio_sound_pitch(h, ratio) { if (h && !h.stopped) h.ratio = ratio; }
        SetupMusic();
        StartMusic(${index}, false);
        var out = [];
        for (let t = 0; t < ${SECONDS * 60}; t++) {
            const before = M.voices.map(v => v.handle);
            StepMusic(false);
            out.push(M.voices.map((v, i) => {
                const h = v.handle;
                if (!h || h.stopped) return null;
                return { p: Math.round(Math.log2(h.ratio) * 96), g: audio_sound_get_gain(h), start: h !== before[i],
                         drum: /Noise|noise/.test(h.name) };
            }));
            Snd.ctx.currentTime += 1 / 60;
        }
        var trackNames = [];
    `, ctx);
    // the tracks' names, from StartMusic's source
    const name = ['', 'MUSIC_FRAKTHEME', 'MUSIC_ALITTLEBAGOFWEED', 'MUSIC_THEMANWHOONCEWASI', 'MUSIC_VICTORYTHEME',
                  'MUSIC_INTROSCREEN', 'MUSIC_SELECTSCREEN', 'MUSIC_LEVELSCREEN'][index];
    const start = src.indexOf('case ' + name + ':');
    const names = [...src.slice(start, src.indexOf('break;', start)).matchAll(/TrackSetup\(M\.(\w+)/g)].map(m => m[1]);
    return { ticks: ctx.out, names };
}

// ---- The 6502 player, at 50Hz
const out = readFileSync(REPO + '/build/assembler.txt', 'utf8');
const sym = {};
for (const [, k, v] of out.match(/SYMBOLS(.*)/)[1].matchAll(/(\w+)\s*&([0-9A-F]+)/g)) sym[k] = parseInt(v, 16);
const s = new MachineSession('Master', { discImage: REPO + '/build/frak.ssd' });
await s.initialise(); await s.boot(30); await s.autoboot();
const jcpu = s._machine.processor;
for (let t = 0; t < 100 && jcpu.readmem(sym.snd_tune) !== 5; t++) await s.runFrames(20);
await s.runFrames(50);
const base = new Uint8Array(65536);
for (let a = 0; a < 0x8000; a++) base[a] = jcpu.readmem(a);
for (let a = 0x8000; a < 0xC000; a++) base[a] = jcpu.ramRomOs[jcpu.romOffset + sym.MUSIC_BANK * 16384 + a - 0x8000];
for (let a = 0xC000; a < 0xFC00; a++) base[a] = jcpu.readmem(a);

class SnCpu extends Cpu6502 {
    constructor(mem) { super(mem); this.ora = 0; this.writes = []; }
    wr(a, v) {
        a &= 0xFFFF;
        if (a === 0xFE4F) this.ora = v & 0xFF;
        else if (a === 0xFE40 && (v & 15) === 0) this.writes.push(this.ora);
        super.wr(a, v);
    }
}

function beebTune(index) {
    const mem = base.slice();
    const c = new SnCpu(mem);
    mem[sym.snd_music_req] = index; mem[sym.snd_sfx_req] = 0xFF;
    mem[sym.snd_music_opt] = 0; mem[sym.snd_sfx_opt] = 0;
    const div = [0, 0, 0], att = [15, 15, 15, 15];
    let latch = 0;
    const ticks = [];
    for (let t = 0; t < SECONDS * 50; t++) {
        c.writes = [];
        // (with --sfx: a ching or a squeal every two seconds, as when playing)
        if (args.includes('--sfx') && t % 100 === 50) mem[sym.snd_sfx_req] = (t / 100) & 1;
        c.call(sym.snd_tick);
        for (const b of c.writes) {
            if (b & 0x80) {
                latch = (b >> 5) & 3;
                if (b & 0x10) att[latch] = b & 15;
                else if (latch < 3) div[latch] = (div[latch] & 0x3F0) | (b & 15);
            } else if (latch < 3) div[latch] = (div[latch] & 15) | (b & 0x3F) << 4;
        }
        const row = [0, 1, 2].map(ch => att[ch] < 15 && div[ch] ? { p: Math.round(96 * Math.log2(4e6 / 32 / div[ch] / 100)), att: att[ch] } : null);
        row.noise = att[3];
        ticks.push(row);
    }
    return ticks;
}

// ... or, with --live, as jsbeeb's own sound chip hears it, with the game running a level
const LIVE = args.includes('--live');
let pokes = null;
if (LIVE) {
    const NAMES = ['room_0', ...'ABCDEF'.split('').flatMap(c => [1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => `room_${c}_${n}`))];
    for (let i = 0; i < 2; i++) { s.keyDown('Space'); await s.runFrames(5); s.keyUp('Space'); await s.runFrames(60); }
    await s.runFrames(300);
    const li = NAMES.indexOf('room_A_2');
    for (let t = 0; t < 400 && jcpu.readmem(sym.cur_level) !== li; t++) {
        if (t % 40 === 0) { jcpu.writemem(sym.cur_level, (li + 54) % 55); jcpu.writemem(sym.won, 1); }
        await s.runFrames(5);
    }
    await s.runFrames(100);
    const chip = s._soundChip;
    pokes = [];
    const poke = chip.poke.bind(chip);
    chip.poke = v => { pokes.push([chip.scheduler.epoch, v]); poke(v); };
}
async function liveTune(index) {
    jcpu.writemem(sym.snd_music_req, 0);
    await s.runFrames(100);
    pokes.length = 0;
    jcpu.writemem(sym.snd_music_req, index);
    const t0 = s._soundChip.scheduler.epoch;
    await s.runFrames(SECONDS * 50);
    const div = [0, 0, 0], att = [15, 15, 15, 15];
    let latch = 0, k = 0;
    const ticks = [];
    // (the tune starts at the first tick after the request)
    const first = pokes.length ? pokes[0][0] : t0;
    for (let n = 0; n < SECONDS * 50; n++) {
        const end = first + (n + 1) * 40000 - 20000;
        for (; k < pokes.length && pokes[k][0] < end; k++) {
            const b = pokes[k][1];
            if (b & 0x80) {
                latch = (b >> 5) & 3;
                if (b & 0x10) att[latch] = b & 15;
                else if (latch < 3) div[latch] = (div[latch] & 0x3F0) | (b & 15);
            } else if (latch < 3) div[latch] = (div[latch] & 15) | (b & 0x3F) << 4;
        }
        const row = [0, 1, 2].map(ch => att[ch] < 15 && div[ch] ? { p: Math.round(96 * Math.log2(4e6 / 32 / div[ch] / 100)), att: att[ch] } : null);
        row.noise = att[3];
        ticks.push(row);
    }
    return ticks;
}

// ---- Compare
const near = (a, b) => Math.abs(a - b) <= 3;
for (const [k, tune] of TUNES.entries()) {
    if (only.length && !only.includes(tune)) continue;
    const web = webTune(k + 1), beeb = LIVE ? await liveTune(k + 1) : beebTune(k + 1);
    console.log(`${tune}:`);
    if (process.env.DUMP) {
        const other = LIVE ? beebTune(k + 1) : null;
        for (let n = 0; n < +process.env.DUMP; n++) {
            const f = row => row.map(c => c ? `${c.p}/${c.att}` : '-').join(' ');
            const w = web.ticks[Math.floor(n * 60 / 50)].map(v => v ? `${v.p}:${v.g.toFixed(2)}` : '-').join(' ');
            console.log(n, '| beeb', f(beeb[n]), other ? '| interp ' + f(other[n]) : '', '| web', w);
        }
    }
    const tuneLoud = Math.max(...web.ticks.flatMap(row => row.map(v => v && !v.drum ? v.g : 0)));
    for (const [i, name] of web.names.entries()) {
        let notes = 0, heard = 0, octave = 0;
        const missing = [];
        if (web.ticks.some(row => row[i] && row[i].drum)) {
            // drums: each hit should be a new attack on the noise channel within a tick or two
            let hits = 0, got = 0;
            const late = [];
            for (let t = 0; t < web.ticks.length; t++) {
                const v = web.ticks[t][i];
                if (!v || !v.start) continue;
                hits++;
                const n0 = Math.floor(t * 50 / 60);
                let ok = false;
                for (let n = Math.max(1, n0 - 1); n <= Math.min(beeb.length - 1, n0 + 2); n++)
                    if (beeb[n].noise < 15 && beeb[n].noise < beeb[n - 1].noise) ok = true;
                if (ok) got++; else late.push((t / 60).toFixed(2) + 's');
            }
            console.log(`  ${name}: ${hits} drum hits, ${got} heard${DETAIL && late.length ? ': missing ' + late.slice(0, 20).join(' ') : ''}`);
            continue;
        }
        for (let t = 0; t < web.ticks.length; t++) {
            const v = web.ticks[t][i];
            if (!v || !v.start) continue;
            notes++;
            // the 50Hz ticks while this note's first 0.1s sounds
            const n0 = Math.floor(t * 50 / 60), n1 = Math.min(beeb.length - 1, n0 + 5);
            let got = false, oct = false;
            for (let n = n0; n <= n1 && !got; n++) for (const ch of beeb[n]) {
                if (!ch) continue;
                if (near(ch.p, v.p)) got = true;
                else if (near(((ch.p - v.p) % 96 + 96) % 96, 0) || near(((ch.p - v.p) % 96 + 96) % 96, 96)) oct = true;
            }
            if (got) heard++;
            else if (oct) octave++;
            if (!got) missing.push(`${(t / 60).toFixed(2)}s p${v.p}${oct ? ' (octave out)' : ''}`);
        }
        // and while it sounds (above a tenth of its loudest): is it on a channel, tick by tick?
        const loud = Math.max(...web.ticks.map(row => row[i] ? row[i].g : 0));
        let on = 0, cov = 0, gap = 0;
        const gaps = [];
        for (let n = 0; n < beeb.length; n++) {
            const v = web.ticks[Math.floor(n * 60 / 50)][i];
            const sounding = v && v.g > loud / 10;
            const here = sounding && beeb[n].some(ch => ch && near(((ch.p - v.p) % 96 + 96) % 96 > 48 ? ((ch.p - v.p) % 96 + 96) % 96 - 96 : ((ch.p - v.p) % 96 + 96) % 96, 0));
            if (sounding) { on++; if (here) cov++; }
            if (sounding && !here) gap++;
            else { if (gap >= +(process.env.GAP || 10)) gaps.push(`${((n - gap) / 50).toFixed(2)}s-${(n / 50).toFixed(2)}s`); gap = 0; }
        }
        // loudness: when both sound, how the chip's level (dB below full) compares with the
        // web version's (dB below the track's loudest), in the first 12 seconds
        const diffs = [];
        let quiet = 0, sounding = 0;
        for (let n = 0; n < Math.min(beeb.length, 600); n++) {
            const v = web.ticks[Math.floor(n * 60 / 50)][i];
            if (!v || v.g <= 0) continue;
            const wdb = 20 * Math.log10(v.g / tuneLoud);
            if (wdb < -30) continue;
            sounding++;
            const ch = beeb[n].find(c => c && near(((c.p - v.p) % 96 + 96) % 96 > 48 ? ((c.p - v.p) % 96 + 96) % 96 - 96 : ((c.p - v.p) % 96 + 96) % 96, 0));
            if (!ch) continue;
            diffs.push(-2 * ch.att - wdb);
        }
        diffs.sort((a, b) => a - b);
        const q = f => diffs.length ? diffs[Math.floor(f * (diffs.length - 1))].toFixed(0) : '-';
        console.log(`  ${name}: chip dB minus web dB: 10%/50%/90% = ${q(0.1)}/${q(0.5)}/${q(0.9)}`);
        console.log(`  ${name}: ${notes} notes, ${heard} heard, ${octave} only an octave out, ${notes - heard - octave} missing; ` +
                    `on the chip ${on ? Math.round(100 * cov / on) : 100}% of the time it sounds, ${gaps.length} gaps of 0.2s or more`);
        if (DETAIL) {
            for (const m of missing.slice(0, 20)) console.log('      note', m);
            for (const g of gaps.slice(0, 20)) console.log('      gap', g);
        }
    }
}
process.exit(0);
