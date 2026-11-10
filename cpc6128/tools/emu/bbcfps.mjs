// The BBC version's frame rate, measured as fps.mjs measures the CPC version's: on jsbeeb, each
// level, Trogg unable to die, standing still for 10 seconds (counting the frames it draws: its
// loops counter), for comparing the two.
//
//   (cd .. && ./build.sh) && node tools/emu/bbcfps.mjs [room_A_1 ...]
import { readFileSync } from 'fs';
import { createRequire } from 'module';
import { join, resolve } from 'path';
import { pathToFileURL, fileURLToPath } from 'url';

const BBC = resolve(fileURLToPath(import.meta.url), '../../../..');
const jsbeebPath = createRequire(join(BBC, 'tools/emu/package.json')).resolve('jsbeeb');
const { MachineSession } = await import(pathToFileURL(jsbeebPath));
const bs = {};
for (const [, k, v] of readFileSync(join(BBC, 'build/labels.txt'), 'utf8').matchAll(/'(\w+)':(\d+)L/g)) bs[k] = +v;
const NAMES = ['room_0', ...'ABCDEF'.split('').flatMap(c => [1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => `room_${c}_${n}`))];
const only = process.argv.slice(2).filter(a => a.startsWith('room'));
const rooms = only.length ? only : ['room_A_1', 'room_B_3', 'room_C_6', 'room_D_1', 'room_D_3', 'room_B_1'];

const s = new MachineSession('Master', { discImage: join(BBC, 'build/frak.ssd') });
await s.initialise(); await s.boot(30); await s.autoboot();
const cpu = s._machine.processor;
const bank6 = a => cpu.romOffset + 6 * 16384 + a - 0x8000;
for (let t = 0, v = -1; t < 100; t++) {
    if (cpu.readmem(bs.snd_tune) === 5 && cpu.readmem(bs.vsyncs) !== v && v >= 0) break;
    v = cpu.readmem(bs.vsyncs); await s.runFrames(20);
}
await s.runFrames(100);
for (let i = 0; i < 2; i++) { s.keyDown('Space'); await s.runFrames(5); s.keyUp('Space'); await s.runFrames(60); }
await s.runFrames(300);
// (Trogg can't die: trogg_dies returns at once)
cpu.ramRomOs[bank6(bs.trogg_dies)] = 0x60;
for (const room of rooms) {
    const li = NAMES.indexOf(room);
    for (let t = 0; t < 400 && cpu.readmem(bs.cur_level) !== li; t++) {
        if (t % 40 === 0) { cpu.writemem(bs.cur_level, (li + 54) % 55); cpu.writemem(bs.won, 1); }
        await s.runFrames(5);
    }
    await s.runFrames(100);
    const l0 = cpu.readmem(bs.loops);
    let frames = 0, last = l0;
    for (let i = 0; i < 50; i++) {          // (10 seconds, counting the 8-bit counter's wraps)
        await s.runFrames(10);
        const l = cpu.readmem(bs.loops);
        frames += (l - last) & 255; last = l;
    }
    console.log(`${room.replace('room_', '')}: ${(frames / 10).toFixed(1)} frames a second`);
}
process.exit(0);
