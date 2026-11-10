// The music checker: does the CPC player play the tunes as the Steam (HTML5) version does?
// (The CPC version of the BBC version's tools/emu/music8.mjs, with the same reference and checks.)
//
//   ./build.sh && CPC_ROMS=... node tools/emu/music.mjs [tune ...] [--detail] [--seconds=N] [--sfx]
//
// The reference is the steamfrak repository's js/audio.js itself (STEAMFRAK, default ../steamfrak
// alongside steamfrak-8bit), run here with its WebAudio calls replaced by ones that just remember
// each voice's pitch and gain, stepped at 60Hz as the game steps it.
//
// The CPC side is the game's own player (src/sound.asm): MAME boots the disc, the low RAM and the
// sound bank are copied, and snd_tick is run on the Z80 interpreter (cpuz80.mjs), 50 times a
// second, with the AY's register writes (through the PPI) caught and decoded.
//
// For each note of each tone track, it looks for that pitch on one of the AY's three channels
// (with its tone mixed in) while the note is sounding, and reports the notes that are missing
// (or only there an octave out) for each track; each drum hit should be a new attack of the
// noise on a channel within a tick or two.
import { symbols, run, boot } from './mame.mjs';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
import vm from 'vm';
import { CpuZ80 } from './cpuz80.mjs';

const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
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

// ---- The Z80 player, at 50Hz
const sym = symbols();
const r = run([...boot, 'dump all 0 65536', `bankdump snd ${sym.ram_bank + sym.sound_bank} 16384 16384 ${sym.ga_ram}`], { seconds: 300 });
const base = new Uint8Array(65536);
base.set(r.dump('all'), 0);
base.set(r.dump('snd'), 0x4000);
// (the AY's levels, as MAME has them, as the BBC chip's attenuations (2dB steps) for the checks)
const AY = [0, 0.00999, 0.01445, 0.02106, 0.03070, 0.04555, 0.06450, 0.10736, 0.12658, 0.20498, 0.29221,
            0.37283, 0.49253, 0.63532, 0.80558, 1.0];
const attOf = v => (v ? Math.min(15, Math.round(-10 * Math.log10(AY[v]))) : 15);

class AyCpu extends CpuZ80 {
    constructor(mem) { super(mem); this.porta = 0; this.sel = 0; this.ay = new Array(16).fill(0); }
    out(port, v) {
        const hi = port >> 8;
        if (hi === 0xF4) this.porta = v;
        else if (hi === 0xF6) {
            if ((v & 0xC0) === 0xC0) this.sel = this.porta & 15;
            else if ((v & 0xC0) === 0x80) this.ay[this.sel] = this.porta;
        }
    }
}

function cpcTune(index) {
    const mem = base.slice();
    const c = new AyCpu(mem);
    mem[sym.snd_music_req] = index; mem[sym.snd_sfx_req] = 0xFF; mem[sym.snd_sfx_req2] = 0xFF;
    mem[sym.snd_music_opt] = 0; mem[sym.snd_sfx_opt] = 0;
    const ticks = [];
    for (let t = 0; t < SECONDS * 50; t++) {
        // (with --sfx: a ching or a squeal every two seconds, as when playing)
        if (args.includes('--sfx') && t % 100 === 50) mem[sym.snd_sfx_req] = (t / 100) & 1;
        c.sp = 0x3F00; c.call(sym.snd_tick);
        const R = c.ay, row = [0, 1, 2].map(ch => {
            const tp = R[2 * ch] | (R[2 * ch + 1] & 15) << 8, vol = R[8 + ch] & 15;
            return vol && tp && !(R[7] & (1 << ch)) ? { p: Math.round(96 * Math.log2(62500 / tp / 100)), att: attOf(vol) } : null;
        });
        // (the noise: its loudest channel's level, as an attenuation)
        row.noise = Math.min(...[0, 1, 2].map(ch => (R[7] & (8 << ch)) ? 15 : attOf(R[8 + ch] & 15)));
        ticks.push(row);
    }
    return ticks;
}

// ---- Compare
const near = (a, b) => Math.abs(a - b) <= 3;
for (const [k, tune] of TUNES.entries()) {
    if (only.length && !only.includes(tune)) continue;
    const web = webTune(k + 1), beeb = cpcTune(k + 1);
    console.log(`${tune}:`);
    if (process.env.DUMP) {
        const other = null;
        for (let n = 0; n < +process.env.DUMP; n++) {
            const f = row => row.map(c => c ? `${c.p}/${c.att}` : '-').join(' ');
            const w = web.ticks[Math.floor(n * 60 / 50)].map(v => v ? `${v.p}:${v.g.toFixed(2)}` : '-').join(' ');
            console.log(n, '| cpc', f(beeb[n]), other ? '| interp ' + f(other[n]) : '', '| web', w);
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
