// record.mjs A8JS XEX OUT.wav SCRIPT: run a program (as tour.mjs, the same script) and save its
// sound (the emulator's POKEY: 16-bit mono at its rate) as a WAV
import { readFileSync, writeFileSync } from 'fs';
import { createRequire } from 'module';
const [, , a8js, xex, out, script] = process.argv;
const A = await createRequire(import.meta.url)(a8js)({ print: () => {}, printErr: () => {} });
A.FS.writeFile('/prog.xex', readFileSync(xex));
const frame = A.cwrap('web_frame', 'number', ['number', 'number', 'number', 'number']);
A.cwrap('web_start', 'number', ['string'])('/prog.xex');
const chunks = [];
for (let i = 0; i < 100; i++) frame(0, 0, 0, 0);
for (const step of script.trim().split(/\s+/)) {
    const [f, joy, fire, key, cons] = step.split(':').map(Number);
    for (let i = 0; i < f; i++) {
        frame(joy, fire || 0, key || 0, cons || 0);
        const p = A._web_sound(), n = A._web_sound_len();
        chunks.push(Buffer.from(A.HEAPU8.slice(p, p + n)));
    }
}
const data = Buffer.concat(chunks), frames = script.trim().split(/\s+/).reduce((t, s) => t + +s.split(':')[0], 0);
const rate = 44100;                       // (web.c: -dsprate 44100)
const h = Buffer.alloc(44);
h.write('RIFF', 0); h.writeUInt32LE(36 + data.length, 4); h.write('WAVEfmt ', 8); h.writeUInt32LE(16, 16);
h.writeUInt16LE(1, 20); h.writeUInt16LE(1, 22); h.writeUInt32LE(rate, 24); h.writeUInt32LE(rate * 2, 28);
h.writeUInt16LE(2, 32); h.writeUInt16LE(16, 34); h.write('data', 36); h.writeUInt32LE(data.length, 40);
writeFileSync(out, Buffer.concat([h, data]));
console.log(`${frames} frames, ${data.length} bytes of sound: ${rate}Hz`);
