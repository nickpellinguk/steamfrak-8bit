// Boot build/frak.ssd on an emulated BBC Master 128 (jsbeeb), run a script of key
// presses, and save screenshots as PNG files.
//
//   cd tools/emu && npm install
//   node run.mjs [script] [outdir]
//
// The script is a space-separated list of steps:
//   wait:N         run N frames (1/50 s each)
//   down:KeyX      press a key (KeyboardEvent.code names, e.g. KeyZ, KeyO, Space)
//   up:KeyX        release it
//   shot:name      save outdir/name.png
// Default: let it load, then walk right for 2 seconds.
import { MachineSession } from 'jsbeeb';
import { writeFileSync, mkdirSync } from 'fs';
import { deflateSync } from 'zlib';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const here = dirname(fileURLToPath(import.meta.url));
const disc = resolve(here, '../../build/frak.ssd');
const script = process.argv[2] || 'wait:1500 shot:start down:KeyX wait:100 up:KeyX shot:walked';
const outdir = resolve(process.argv[3] || 'screenshots');
mkdirSync(outdir, { recursive: true });

// Minimal PNG writer (RGB, no dependencies)
function png(width, height, rgb) {
    const crcTable = Array.from({ length: 256 }, (_, n) => {
        let c = n;
        for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
        return c >>> 0;
    });
    const crc = (buf) => { let c = 0xffffffff; for (const b of buf) c = crcTable[(c ^ b) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
    const chunk = (type, data) => {
        const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
        const td = Buffer.concat([Buffer.from(type), data]);
        const c = Buffer.alloc(4); c.writeUInt32BE(crc(td));
        return Buffer.concat([len, td, c]);
    };
    const raw = Buffer.alloc((width * 3 + 1) * height);
    for (let y = 0; y < height; y++) {
        raw[y * (width * 3 + 1)] = 0;
        rgb.copy(raw, y * (width * 3 + 1) + 1, y * width * 3, (y + 1) * width * 3);
    }
    const ihdr = Buffer.alloc(13);
    ihdr.writeUInt32BE(width, 0); ihdr.writeUInt32BE(height, 4);
    ihdr[8] = 8; ihdr[9] = 2;
    return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr),
        chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
}

const s = new MachineSession('Master', { discImage: disc });
await s.initialise();
await s.boot(30);
await s.autoboot();

function screenshot(name) {
    const v = s._video, W = 1024, H = 625;
    const l = v.leftBorder, t = v.topBorder, w = W - l - v.rightBorder, h = H - t - v.bottomBorder;
    const fb = s._completeFb8, rgb = Buffer.alloc(w * h * 3);
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
        const i = ((y + t) * W + x + l) * 4, o = (y * w + x) * 3;
        rgb[o] = fb[i]; rgb[o + 1] = fb[i + 1]; rgb[o + 2] = fb[i + 2];
    }
    writeFileSync(`${outdir}/${name}.png`, png(w, h, rgb));
    console.log('saved', `${outdir}/${name}.png`);
}

for (const step of script.trim().split(/\s+/)) {
    const [cmd, arg] = step.split(':');
    if (cmd === 'wait') await s.runFrames(+arg);
    else if (cmd === 'down') s.keyDown(arg);
    else if (cmd === 'up') s.keyUp(arg);
    else if (cmd === 'shot') screenshot(arg);
    else throw new Error('Unknown step ' + step);
}
