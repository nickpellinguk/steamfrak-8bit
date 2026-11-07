// A small 6502 interpreter (the documented NMOS instructions and the 65C02 ones the Master's
// 65SC12 has, binary arithmetic only), for
// running pieces of the game's own code against a snapshot of memory, much faster than a whole
// emulated machine. Used by connections8.mjs to run Trogg's movement routines.
//
//   const cpu = new Cpu6502(mem);       // mem: a Uint8Array(65536)
//   cpu.call(addr, { a, x, y });        // JSR addr; returns when it returns (RTS)
//
// Writes to &FC00-&FEFF (the Beeb's I/O) are ignored.

const C = 1, Z = 2, I = 4, D = 8, B = 16, V = 64, N = 128;

export class Cpu6502 {
    constructor(mem) {
        this.m = mem;
        this.a = 0; this.x = 0; this.y = 0; this.s = 0xFF; this.p = I | 0x20; this.pc = 0;
        this.count = 0;
    }
    rd(a) { return this.m[a & 0xFFFF]; }
    wr(a, v) { a &= 0xFFFF; if (a >= 0xFC00 && a < 0xFF00) return; this.m[a] = v & 0xFF; }
    rd16(a) { return this.rd(a) | this.rd(a + 1) << 8; }
    push(v) { this.m[0x100 + this.s] = v & 0xFF; this.s = (this.s - 1) & 0xFF; }
    pull() { this.s = (this.s + 1) & 0xFF; return this.m[0x100 + this.s]; }
    nz(v) { v &= 0xFF; this.p = (this.p & ~(N | Z)) | (v & N) | (v ? 0 : Z); return v; }
    flag(f, on) { this.p = on ? this.p | f : this.p & ~f; }

    // Call the routine at addr, as JSR would, and run until it returns
    call(addr, regs = {}, limit = 1e6) {
        const RET = 0xFFF0;                 // (a return address that's never executed)
        Object.assign(this, regs);
        this.s = 0xFF;
        this.push((RET - 1) >> 8); this.push((RET - 1) & 0xFF);
        this.pc = addr;
        for (let n = 0; this.pc !== RET; n++) {
            if (n > limit) throw new Error('runaway at &' + this.pc.toString(16));
            this.step();
        }
    }

    adc(v) {
        const c = this.p & C, r = this.a + v + c;
        this.flag(V, (~(this.a ^ v) & (this.a ^ r) & 0x80) !== 0);
        this.flag(C, r > 0xFF);
        this.a = this.nz(r);
    }
    cmp(r, v) { const d = r - v; this.flag(C, d >= 0); this.nz(d); }

    step() {
        const op = this.rd(this.pc);
        this.pc = (this.pc + 1) & 0xFFFF;
        this.count++;
        // addressing modes: each returns an address
        const imm = () => { const a = this.pc; this.pc = (this.pc + 1) & 0xFFFF; return a; };
        const zp = () => this.rd(imm());
        const zpx = () => (this.rd(imm()) + this.x) & 0xFF;
        const zpy = () => (this.rd(imm()) + this.y) & 0xFF;
        const abs = () => { const a = this.rd16(this.pc); this.pc = (this.pc + 2) & 0xFFFF; return a; };
        const abx = () => (abs() + this.x) & 0xFFFF;
        const aby = () => (abs() + this.y) & 0xFFFF;
        const izx = () => { const z = (this.rd(imm()) + this.x) & 0xFF; return this.rd(z) | this.rd((z + 1) & 0xFF) << 8; };
        const izy = () => { const z = this.rd(imm()); return ((this.rd(z) | this.rd((z + 1) & 0xFF) << 8) + this.y) & 0xFFFF; };
        const izp = () => { const z = this.rd(imm()); return this.rd(z) | this.rd((z + 1) & 0xFF) << 8; };
        const branch = cond => { const o = this.rd(imm()); if (cond) this.pc = (this.pc + (o < 128 ? o : o - 256)) & 0xFFFF; };
        // read-modify-write helpers
        const asl = v => { this.flag(C, v & 0x80); return this.nz(v << 1); };
        const lsr = v => { this.flag(C, v & 1); return this.nz(v >> 1); };
        const rol = v => { const c = this.p & C; this.flag(C, v & 0x80); return this.nz(v << 1 | c); };
        const ror = v => { const c = this.p & C; this.flag(C, v & 1); return this.nz(v >> 1 | c << 7); };
        const rmw = (mode, f) => { const a = mode(); this.wr(a, f(this.rd(a))); };
        let a;
        switch (op) {
            // loads and stores
            case 0xA9: this.a = this.nz(this.rd(imm())); break;
            case 0xA5: this.a = this.nz(this.rd(zp())); break;
            case 0xB5: this.a = this.nz(this.rd(zpx())); break;
            case 0xAD: this.a = this.nz(this.rd(abs())); break;
            case 0xBD: this.a = this.nz(this.rd(abx())); break;
            case 0xB9: this.a = this.nz(this.rd(aby())); break;
            case 0xA1: this.a = this.nz(this.rd(izx())); break;
            case 0xB1: this.a = this.nz(this.rd(izy())); break;
            case 0xA2: this.x = this.nz(this.rd(imm())); break;
            case 0xA6: this.x = this.nz(this.rd(zp())); break;
            case 0xB6: this.x = this.nz(this.rd(zpy())); break;
            case 0xAE: this.x = this.nz(this.rd(abs())); break;
            case 0xBE: this.x = this.nz(this.rd(aby())); break;
            case 0xA0: this.y = this.nz(this.rd(imm())); break;
            case 0xA4: this.y = this.nz(this.rd(zp())); break;
            case 0xB4: this.y = this.nz(this.rd(zpx())); break;
            case 0xAC: this.y = this.nz(this.rd(abs())); break;
            case 0xBC: this.y = this.nz(this.rd(abx())); break;
            case 0x85: this.wr(zp(), this.a); break;
            case 0x95: this.wr(zpx(), this.a); break;
            case 0x8D: this.wr(abs(), this.a); break;
            case 0x9D: this.wr(abx(), this.a); break;
            case 0x99: this.wr(aby(), this.a); break;
            case 0x81: this.wr(izx(), this.a); break;
            case 0x91: this.wr(izy(), this.a); break;
            case 0x86: this.wr(zp(), this.x); break;
            case 0x96: this.wr(zpy(), this.x); break;
            case 0x8E: this.wr(abs(), this.x); break;
            case 0x84: this.wr(zp(), this.y); break;
            case 0x94: this.wr(zpx(), this.y); break;
            case 0x8C: this.wr(abs(), this.y); break;
            // transfers and stack
            case 0xAA: this.x = this.nz(this.a); break;
            case 0xA8: this.y = this.nz(this.a); break;
            case 0x8A: this.a = this.nz(this.x); break;
            case 0x98: this.a = this.nz(this.y); break;
            case 0xBA: this.x = this.nz(this.s); break;
            case 0x9A: this.s = this.x; break;
            case 0x48: this.push(this.a); break;
            case 0x68: this.a = this.nz(this.pull()); break;
            case 0x08: this.push(this.p | B | 0x20); break;
            case 0x28: this.p = this.pull() | 0x20; break;
            // arithmetic
            case 0x69: this.adc(this.rd(imm())); break;
            case 0x65: this.adc(this.rd(zp())); break;
            case 0x75: this.adc(this.rd(zpx())); break;
            case 0x6D: this.adc(this.rd(abs())); break;
            case 0x7D: this.adc(this.rd(abx())); break;
            case 0x79: this.adc(this.rd(aby())); break;
            case 0x61: this.adc(this.rd(izx())); break;
            case 0x71: this.adc(this.rd(izy())); break;
            case 0xE9: this.adc(this.rd(imm()) ^ 0xFF); break;
            case 0xE5: this.adc(this.rd(zp()) ^ 0xFF); break;
            case 0xF5: this.adc(this.rd(zpx()) ^ 0xFF); break;
            case 0xED: this.adc(this.rd(abs()) ^ 0xFF); break;
            case 0xFD: this.adc(this.rd(abx()) ^ 0xFF); break;
            case 0xF9: this.adc(this.rd(aby()) ^ 0xFF); break;
            case 0xE1: this.adc(this.rd(izx()) ^ 0xFF); break;
            case 0xF1: this.adc(this.rd(izy()) ^ 0xFF); break;
            case 0xC9: this.cmp(this.a, this.rd(imm())); break;
            case 0xC5: this.cmp(this.a, this.rd(zp())); break;
            case 0xD5: this.cmp(this.a, this.rd(zpx())); break;
            case 0xCD: this.cmp(this.a, this.rd(abs())); break;
            case 0xDD: this.cmp(this.a, this.rd(abx())); break;
            case 0xD9: this.cmp(this.a, this.rd(aby())); break;
            case 0xC1: this.cmp(this.a, this.rd(izx())); break;
            case 0xD1: this.cmp(this.a, this.rd(izy())); break;
            case 0xE0: this.cmp(this.x, this.rd(imm())); break;
            case 0xE4: this.cmp(this.x, this.rd(zp())); break;
            case 0xEC: this.cmp(this.x, this.rd(abs())); break;
            case 0xC0: this.cmp(this.y, this.rd(imm())); break;
            case 0xC4: this.cmp(this.y, this.rd(zp())); break;
            case 0xCC: this.cmp(this.y, this.rd(abs())); break;
            // logic
            case 0x29: this.a = this.nz(this.a & this.rd(imm())); break;
            case 0x25: this.a = this.nz(this.a & this.rd(zp())); break;
            case 0x35: this.a = this.nz(this.a & this.rd(zpx())); break;
            case 0x2D: this.a = this.nz(this.a & this.rd(abs())); break;
            case 0x3D: this.a = this.nz(this.a & this.rd(abx())); break;
            case 0x39: this.a = this.nz(this.a & this.rd(aby())); break;
            case 0x21: this.a = this.nz(this.a & this.rd(izx())); break;
            case 0x31: this.a = this.nz(this.a & this.rd(izy())); break;
            case 0x09: this.a = this.nz(this.a | this.rd(imm())); break;
            case 0x05: this.a = this.nz(this.a | this.rd(zp())); break;
            case 0x15: this.a = this.nz(this.a | this.rd(zpx())); break;
            case 0x0D: this.a = this.nz(this.a | this.rd(abs())); break;
            case 0x1D: this.a = this.nz(this.a | this.rd(abx())); break;
            case 0x19: this.a = this.nz(this.a | this.rd(aby())); break;
            case 0x01: this.a = this.nz(this.a | this.rd(izx())); break;
            case 0x11: this.a = this.nz(this.a | this.rd(izy())); break;
            case 0x49: this.a = this.nz(this.a ^ this.rd(imm())); break;
            case 0x45: this.a = this.nz(this.a ^ this.rd(zp())); break;
            case 0x55: this.a = this.nz(this.a ^ this.rd(zpx())); break;
            case 0x4D: this.a = this.nz(this.a ^ this.rd(abs())); break;
            case 0x5D: this.a = this.nz(this.a ^ this.rd(abx())); break;
            case 0x59: this.a = this.nz(this.a ^ this.rd(aby())); break;
            case 0x41: this.a = this.nz(this.a ^ this.rd(izx())); break;
            case 0x51: this.a = this.nz(this.a ^ this.rd(izy())); break;
            case 0x24: a = this.rd(zp()); this.flag(Z, !(this.a & a)); this.flag(N, a & N); this.flag(V, a & V); break;
            case 0x2C: a = this.rd(abs()); this.flag(Z, !(this.a & a)); this.flag(N, a & N); this.flag(V, a & V); break;
            // shifts and increments
            case 0x0A: this.a = asl(this.a); break;
            case 0x4A: this.a = lsr(this.a); break;
            case 0x2A: this.a = rol(this.a); break;
            case 0x6A: this.a = ror(this.a); break;
            case 0x06: rmw(zp, asl); break;
            case 0x16: rmw(zpx, asl); break;
            case 0x0E: rmw(abs, asl); break;
            case 0x1E: rmw(abx, asl); break;
            case 0x46: rmw(zp, lsr); break;
            case 0x56: rmw(zpx, lsr); break;
            case 0x4E: rmw(abs, lsr); break;
            case 0x5E: rmw(abx, lsr); break;
            case 0x26: rmw(zp, rol); break;
            case 0x36: rmw(zpx, rol); break;
            case 0x2E: rmw(abs, rol); break;
            case 0x3E: rmw(abx, rol); break;
            case 0x66: rmw(zp, ror); break;
            case 0x76: rmw(zpx, ror); break;
            case 0x6E: rmw(abs, ror); break;
            case 0x7E: rmw(abx, ror); break;
            case 0xE6: rmw(zp, v => this.nz(v + 1)); break;
            case 0xF6: rmw(zpx, v => this.nz(v + 1)); break;
            case 0xEE: rmw(abs, v => this.nz(v + 1)); break;
            case 0xFE: rmw(abx, v => this.nz(v + 1)); break;
            case 0xC6: rmw(zp, v => this.nz(v - 1)); break;
            case 0xD6: rmw(zpx, v => this.nz(v - 1)); break;
            case 0xCE: rmw(abs, v => this.nz(v - 1)); break;
            case 0xDE: rmw(abx, v => this.nz(v - 1)); break;
            case 0xE8: this.x = this.nz(this.x + 1); break;
            case 0xCA: this.x = this.nz(this.x - 1); break;
            case 0xC8: this.y = this.nz(this.y + 1); break;
            case 0x88: this.y = this.nz(this.y - 1); break;
            // jumps and branches
            case 0x4C: this.pc = abs(); break;
            case 0x6C: { const p = abs(); this.pc = this.rd(p) | this.rd((p & 0xFF00) | ((p + 1) & 0xFF)) << 8; break; }
            case 0x20: { const t = abs(); const r = (this.pc - 1) & 0xFFFF; this.push(r >> 8); this.push(r & 0xFF); this.pc = t; break; }
            case 0x60: this.pc = ((this.pull() | this.pull() << 8) + 1) & 0xFFFF; break;
            case 0x40: this.p = this.pull() | 0x20; this.pc = this.pull() | this.pull() << 8; break;
            case 0x10: branch(!(this.p & N)); break;
            case 0x30: branch(this.p & N); break;
            case 0x50: branch(!(this.p & V)); break;
            case 0x70: branch(this.p & V); break;
            case 0x90: branch(!(this.p & C)); break;
            case 0xB0: branch(this.p & C); break;
            case 0xD0: branch(!(this.p & Z)); break;
            case 0xF0: branch(this.p & Z); break;
            // flags
            case 0x18: this.p &= ~C; break;
            case 0x38: this.p |= C; break;
            case 0x58: this.p &= ~I; break;
            case 0x78: this.p |= I; break;
            case 0xB8: this.p &= ~V; break;
            case 0xD8: this.p &= ~D; break;
            case 0xF8: throw new Error('SED (decimal mode isn\'t supported) at &' + ((this.pc - 1) & 0xFFFF).toString(16));
            case 0xEA: break;
            // the 65C02 (65SC12) instructions the Master has
            case 0x80: branch(true); break;                                         // BRA
            case 0xDA: this.push(this.x); break;                                    // PHX
            case 0xFA: this.x = this.nz(this.pull()); break;                        // PLX
            case 0x5A: this.push(this.y); break;                                    // PHY
            case 0x7A: this.y = this.nz(this.pull()); break;                        // PLY
            case 0x64: this.wr(zp(), 0); break;                                     // STZ
            case 0x74: this.wr(zpx(), 0); break;
            case 0x9C: this.wr(abs(), 0); break;
            case 0x9E: this.wr(abx(), 0); break;
            case 0x1A: this.a = this.nz(this.a + 1); break;                         // INC A
            case 0x3A: this.a = this.nz(this.a - 1); break;                         // DEC A
            case 0x12: this.a = this.nz(this.a | this.rd(izp())); break;            // (zp)
            case 0x32: this.a = this.nz(this.a & this.rd(izp())); break;
            case 0x52: this.a = this.nz(this.a ^ this.rd(izp())); break;
            case 0x72: this.adc(this.rd(izp())); break;
            case 0x92: this.wr(izp(), this.a); break;
            case 0xB2: this.a = this.nz(this.rd(izp())); break;
            case 0xD2: this.cmp(this.a, this.rd(izp())); break;
            case 0xF2: this.adc(this.rd(izp()) ^ 0xFF); break;
            case 0x89: this.flag(Z, !(this.a & this.rd(imm()))); break;             // BIT #
            case 0x34: a = this.rd(zpx()); this.flag(Z, !(this.a & a)); this.flag(N, a & N); this.flag(V, a & V); break;
            case 0x3C: a = this.rd(abx()); this.flag(Z, !(this.a & a)); this.flag(N, a & N); this.flag(V, a & V); break;
            case 0x04: rmw(zp, v => { this.flag(Z, !(this.a & v)); return v | this.a; }); break;    // TSB
            case 0x0C: rmw(abs, v => { this.flag(Z, !(this.a & v)); return v | this.a; }); break;
            case 0x14: rmw(zp, v => { this.flag(Z, !(this.a & v)); return v & ~this.a; }); break;   // TRB
            case 0x1C: rmw(abs, v => { this.flag(Z, !(this.a & v)); return v & ~this.a; }); break;
            case 0x7C: this.pc = this.rd16(abx()); break;                           // JMP (abs,X)
            case 0x00: throw new Error('BRK at &' + ((this.pc - 1) & 0xFFFF).toString(16));
            default: throw new Error('unknown opcode &' + op.toString(16) + ' at &' + ((this.pc - 1) & 0xFFFF).toString(16));
        }
    }
}
