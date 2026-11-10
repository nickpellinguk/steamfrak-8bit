// A small Z80 interpreter (the documented instructions, with the IX and IY halves), for running
// pieces of the game's own code against a snapshot of memory, much faster than a whole emulated
// machine. Used by connections.mjs to run Trogg's movement routines, as the BBC version's
// cpu6502.mjs is by its connections8.mjs.
//
//   const cpu = new CpuZ80(mem);        // mem: a Uint8Array(65536)
//   cpu.call(addr, { a, hl, ... });     // CALL addr; returns when it returns
//
// IN reads #FF (unless a subclass says otherwise) and OUT does nothing: the routines it runs don't page banks in. The flags' bits 3
// and 5 aren't kept.

const C = 1, N = 2, PV = 4, H = 16, Z = 64, S = 128;
const PARITY = new Uint8Array(256).map((_, v) => { let p = 0; for (let b = v; b; b >>= 1) p ^= b & 1; return p ? 0 : PV; });
const SZ = new Uint8Array(256).map((_, v) => (v & S) | (v ? 0 : Z));
const SZP = SZ.map((f, v) => f | PARITY[v]);

export class CpuZ80 {
    constructor(mem) {
        this.m = mem;
        this.a = this.f = this.b = this.c = this.d = this.e = this.h = this.l = 0;
        this.a_ = this.f_ = this.b_ = this.c_ = this.d_ = this.e_ = this.h_ = this.l_ = 0;
        this.ix = this.iy = 0; this.sp = 0x4000; this.pc = 0; this.i = this.r = 0;
        this.count = 0; this.us = 0;
    }
    get bc() { return this.b << 8 | this.c; } set bc(v) { this.b = v >> 8 & 255; this.c = v & 255; }
    get de() { return this.d << 8 | this.e; } set de(v) { this.d = v >> 8 & 255; this.e = v & 255; }
    get hl() { return this.h << 8 | this.l; } set hl(v) { this.h = v >> 8 & 255; this.l = v & 255; }
    get af() { return this.a << 8 | this.f; } set af(v) { this.a = v >> 8 & 255; this.f = v & 255; }

    out(port, v) {}                     // (OUT: nothing, unless a subclass wants it)
    in(port) { return 0xFF; }           // (IN r,(C): #FF, unless a subclass wants otherwise)
    rd(a) { return this.m[a & 0xFFFF]; }
    wr(a, v) { this.m[a & 0xFFFF] = v; }
    rd16(a) { return this.rd(a) | this.rd(a + 1) << 8; }
    wr16(a, v) { this.wr(a, v & 255); this.wr(a + 1, v >> 8 & 255); }
    fetch() { const v = this.m[this.pc]; this.pc = (this.pc + 1) & 0xFFFF; return v; }
    fetch16() { const v = this.fetch(); return v | this.fetch() << 8; }
    disp() { const d = this.fetch(); return d > 127 ? d - 256 : d; }
    push(v) { this.sp = (this.sp - 2) & 0xFFFF; this.wr16(this.sp, v); }
    pop() { const v = this.rd16(this.sp); this.sp = (this.sp + 2) & 0xFFFF; return v; }

    // Call the routine at addr, as CALL would, and run until it returns
    call(addr, regs = {}, limit = 1e7) {
        const RET = 0xFFF0;                 // (a return address that's never executed)
        Object.assign(this, regs);
        this.push(RET);
        this.pc = addr;
        for (let n = 0; this.pc !== RET; n++) {
            if (n > limit) throw new Error('runaway at #' + this.pc.toString(16));
            this.step();
        }
    }

    // the 16-bit register pair p (0 BC, 1 DE, 2 HL or the index register, 3 SP)
    rp(p, x) { return p === 0 ? this.bc : p === 1 ? this.de : p === 3 ? this.sp : x === 1 ? this.ix : x === 2 ? this.iy : this.hl; }
    setRp(p, x, v) {
        v &= 0xFFFF;
        if (p === 0) this.bc = v; else if (p === 1) this.de = v; else if (p === 3) this.sp = v;
        else if (x === 1) this.ix = v; else if (x === 2) this.iy = v; else this.hl = v;
    }
    // the 8-bit register r (0 B, 1 C, 2 D, 3 E, 4 H, 5 L, 6 the byte at ea, 7 A); x the index prefix
    reg(r, x, ea) {
        switch (r) {
            case 0: return this.b; case 1: return this.c; case 2: return this.d; case 3: return this.e;
            case 4: return x === 1 ? this.ix >> 8 : x === 2 ? this.iy >> 8 : this.h;
            case 5: return x === 1 ? this.ix & 255 : x === 2 ? this.iy & 255 : this.l;
            case 6: return this.rd(ea); default: return this.a;
        }
    }
    setReg(r, x, ea, v) {
        v &= 255;
        switch (r) {
            case 0: this.b = v; break; case 1: this.c = v; break; case 2: this.d = v; break; case 3: this.e = v; break;
            case 4: if (x === 1) this.ix = (this.ix & 255) | v << 8; else if (x === 2) this.iy = (this.iy & 255) | v << 8; else this.h = v; break;
            case 5: if (x === 1) this.ix = (this.ix & 0xFF00) | v; else if (x === 2) this.iy = (this.iy & 0xFF00) | v; else this.l = v; break;
            case 6: this.wr(ea, v); break; default: this.a = v;
        }
    }
    // the address (HL), or (IX+d) / (IY+d), fetching d
    ea(x) { return x === 0 ? this.hl : ((x === 1 ? this.ix : this.iy) + this.disp()) & 0xFFFF; }
    cond(y) {
        const f = this.f;
        switch (y) {
            case 0: return !(f & Z); case 1: return !!(f & Z); case 2: return !(f & C); case 3: return !!(f & C);
            case 4: return !(f & PV); case 5: return !!(f & PV); case 6: return !(f & S); default: return !!(f & S);
        }
    }

    alu(op, v) {
        const a = this.a;
        let r;
        switch (op) {
            case 0: case 1: {                                   // ADD, ADC
                r = a + v + (op === 1 ? this.f & C : 0);
                this.f = SZ[r & 255] | ((a ^ v ^ r) & H) | (((a ^ ~v) & (a ^ r) & 0x80) ? PV : 0) | (r > 255 ? C : 0);
                this.a = r & 255; return;
            }
            case 2: case 3: case 7: {                           // SUB, SBC, CP
                r = a - v - (op === 3 ? this.f & C : 0);
                this.f = SZ[r & 255] | ((a ^ v ^ r) & H) | (((a ^ v) & (a ^ r) & 0x80) ? PV : 0) | N | (r < 0 ? C : 0);
                if (op !== 7) this.a = r & 255;
                return;
            }
            case 4: this.a = a & v; this.f = SZP[this.a] | H; return;
            case 5: this.a = a ^ v; this.f = SZP[this.a]; return;
            default: this.a = a | v; this.f = SZP[this.a]; return;
        }
    }
    inc8(v) { const r = (v + 1) & 255; this.f = (this.f & C) | SZ[r] | ((v & 15) === 15 ? H : 0) | (v === 0x7F ? PV : 0); return r; }
    dec8(v) { const r = (v - 1) & 255; this.f = (this.f & C) | SZ[r] | N | ((v & 15) === 0 ? H : 0) | (v === 0x80 ? PV : 0); return r; }
    rot(op, v) {                                                // the CB rotates and shifts
        let r, c;
        switch (op) {
            case 0: c = v >> 7; r = (v << 1 | c) & 255; break;                  // RLC
            case 1: c = v & 1; r = v >> 1 | c << 7; break;                      // RRC
            case 2: c = v >> 7; r = (v << 1 | (this.f & C)) & 255; break;       // RL
            case 3: c = v & 1; r = v >> 1 | (this.f & C) << 7; break;           // RR
            case 4: c = v >> 7; r = (v << 1) & 255; break;                      // SLA
            case 5: c = v & 1; r = v >> 1 | (v & 0x80); break;                  // SRA
            case 6: c = v >> 7; r = (v << 1 | 1) & 255; break;                  // SLL
            default: c = v & 1; r = v >> 1;                                     // SRL
        }
        this.f = SZP[r] | c;
        return r;
    }
    add16(a, b) { const r = a + b; this.f = (this.f & (S | Z | PV)) | (((a ^ b ^ r) >> 8) & H) | (r > 0xFFFF ? C : 0); return r & 0xFFFF; }

    // A step, timed as on a CPC: each instruction takes a whole number of microseconds (the gate
    // array holds the Z80 to 4 T-state boundaries; about its T-states / 4, rounded up). Adds them
    // to this.us.
    timedStep() {
        const pc0 = this.pc, m = this.m, bc0 = this.bc;
        let i = pc0, x = 0, op = m[i];
        while (op === 0xDD || op === 0xFD) { x = 1; op = m[(++i) & 0xFFFF]; }
        this.step();
        const len = n => (this.pc !== ((i + n) & 0xFFFF));                 // (a branch taken?)
        let t;
        if (op === 0xCB) {
            const cb = m[(i + (x ? 2 : 1)) & 0xFFFF];
            t = x ? ((cb >> 6) === 1 ? 6 : 7) : ((cb & 7) === 6 ? ((cb >> 6) === 1 ? 3 : 4) : 2);
        } else if (op === 0xED) {
            const e = m[(i + 1) & 0xFFFF], z = e & 7, q = (e >> 3) & 1;
            if (e >> 6 === 2) t = (e & 0x10) ? 6 * ((bc0 || 65536) - 1) + 5 : 5;     // (LDIR/LDDR: per byte)
            else t = [4, 4, 4, 6, 2, 4, 2, 3][z] + (z === 7 && e >= 0x67 && e <= 0x6F ? 2 : 0);
            if (e >> 6 === 2 && (e & 3) === 1) t = (e & 0x10) ? 6 * ((bc0 || 65536) - this.bc) - 1 : 4;   // (CPIR, CPI)
            void q;
        } else {
            const y = (op >> 3) & 7, z = op & 7, p = y >> 1, q = y & 1, hl6 = (y === 6 || z === 6);
            switch (op >> 6) {
                case 1: t = hl6 ? (x ? 5 : 2) : (x ? 2 : 1); break;
                case 2: t = z === 6 ? (x ? 5 : 2) : (x ? 2 : 1); break;
                case 0:
                    switch (z) {
                        case 0: t = y < 2 ? 1 : y === 2 ? (len(2) ? 4 : 3) : y === 3 ? 3 : (len(2) ? 3 : 2); break;
                        case 1: t = 3 + x; break;
                        case 2: t = y < 4 ? 2 : y < 6 ? 5 + x : 4; break;
                        case 3: t = 2 + x; break;
                        case 4: case 5: t = y === 6 ? (x ? 6 : 3) : (x ? 2 : 1); break;
                        case 6: t = y === 6 ? (x ? 6 : 3) : (x ? 3 : 2); break;
                        default: t = 1;
                    }
                    break;
                default:
                    switch (z) {
                        case 0: t = len(1) ? 4 : 2; break;
                        case 1: t = q === 0 ? 3 + x : [3, 1, 1 + x, 2 + x][p]; break;
                        case 2: t = 3; break;
                        case 3: t = [3, 0, 3, 3, 6 + x, 1, 1, 1][y]; break;
                        case 4: t = len(3) ? 5 : 3; break;
                        case 5: t = q === 0 ? 4 + x : 5; break;
                        case 6: t = 2; break;
                        default: t = 4;
                    }
            }
        }
        this.us += t;
        return t;
    }

    step() {
        this.count++;
        let op = this.fetch(), x = 0;
        while (op === 0xDD || op === 0xFD) { x = op === 0xDD ? 1 : 2; op = this.fetch(); }
        if (op === 0xCB) return this.cb(x);
        if (op === 0xED) return this.ed();
        const y = op >> 3 & 7, z = op & 7, p = y >> 1, q = y & 1;
        switch (op >> 6) {
            case 1: {                                           // LD r,r' (and HALT)
                if (op === 0x76) {                              // (HALT: only if a subclass says it waits)
                    if (!this.haltWaits) throw new Error('HALT at #' + ((this.pc - 1) & 0xFFFF).toString(16));
                    this.pc = (this.pc - 1) & 0xFFFF; this.halted = true; return;
                }
                if (y === 6 || z === 6) { const ea = this.ea(x); this.setReg(y, 0, ea, this.reg(z, 0, ea)); }
                else this.setReg(y, x, 0, this.reg(z, x, 0));
                return;
            }
            case 2: { const ea = z === 6 ? this.ea(x) : 0; this.alu(y, this.reg(z, x, ea)); return; }
            case 0:
                switch (z) {
                    case 0:
                        if (y === 0) return;
                        if (y === 1) { [this.a, this.a_] = [this.a_, this.a]; [this.f, this.f_] = [this.f_, this.f]; return; }
                        if (y === 2) { const d = this.disp(); this.b = (this.b - 1) & 255; if (this.b) this.pc = (this.pc + d) & 0xFFFF; return; }
                        { const d = this.disp(); if (y === 3 || this.cond(y - 4)) this.pc = (this.pc + d) & 0xFFFF; return; }
                    case 1:
                        if (q === 0) this.setRp(p, x, this.fetch16());
                        else this.setRp(2, x, this.add16(this.rp(2, x), this.rp(p, x)));
                        return;
                    case 2:
                        switch (y) {
                            case 0: this.wr(this.bc, this.a); return;
                            case 1: this.a = this.rd(this.bc); return;
                            case 2: this.wr(this.de, this.a); return;
                            case 3: this.a = this.rd(this.de); return;
                            case 4: this.wr16(this.fetch16(), this.rp(2, x)); return;
                            case 5: this.setRp(2, x, this.rd16(this.fetch16())); return;
                            case 6: this.wr(this.fetch16(), this.a); return;
                            default: this.a = this.rd(this.fetch16()); return;
                        }
                    case 3: this.setRp(p, x, this.rp(p, x) + (q ? -1 : 1)); return;
                    case 4: case 5: {
                        const ea = y === 6 ? this.ea(x) : 0, v = this.reg(y, x, ea);
                        this.setReg(y, x, ea, z === 4 ? this.inc8(v) : this.dec8(v));
                        return;
                    }
                    case 6: { const ea = y === 6 ? this.ea(x) : 0; this.setReg(y, x, ea, this.fetch()); return; }
                    default: {
                        const a = this.a, keep = this.f & (S | Z | PV);
                        switch (y) {
                            case 0: this.a = (a << 1 | a >> 7) & 255; this.f = keep | (a >> 7); return;
                            case 1: this.a = a >> 1 | (a & 1) << 7; this.f = keep | (a & 1); return;
                            case 2: this.a = (a << 1 | (this.f & C)) & 255; this.f = keep | (a >> 7); return;
                            case 3: this.a = a >> 1 | (this.f & C) << 7; this.f = keep | (a & 1); return;
                            case 4: {                                           // DAA
                                let corr = 0, c = this.f & C;
                                if ((this.f & H) || (a & 15) > 9) corr = 6;
                                if (c || a > 0x99) { corr |= 0x60; c = C; }
                                const r = (this.f & N) ? a - corr : a + corr;
                                this.f = SZP[r & 255] | c | (this.f & N) | ((a ^ r) & H);
                                this.a = r & 255; return;
                            }
                            case 5: this.a = a ^ 255; this.f |= H | N; return;
                            case 6: this.f = keep | C; return;
                            default: this.f = keep | ((this.f & C) ? H : C); return;
                        }
                    }
                }
            default:
                switch (z) {
                    case 0: if (this.cond(y)) this.pc = this.pop(); return;
                    case 1:
                        if (q === 0) { const v = this.pop(); if (p === 3) this.af = v; else this.setRp(p, x, v); return; }
                        switch (p) {
                            case 0: this.pc = this.pop(); return;
                            case 1:
                                [this.b, this.b_] = [this.b_, this.b]; [this.c, this.c_] = [this.c_, this.c];
                                [this.d, this.d_] = [this.d_, this.d]; [this.e, this.e_] = [this.e_, this.e];
                                [this.h, this.h_] = [this.h_, this.h]; [this.l, this.l_] = [this.l_, this.l];
                                return;
                            case 2: this.pc = this.rp(2, x); return;
                            default: this.sp = this.rp(2, x); return;
                        }
                    case 2: { const a = this.fetch16(); if (this.cond(y)) this.pc = a; return; }
                    case 3:
                        switch (y) {
                            case 0: this.pc = this.fetch16(); return;
                            case 2: { const n = this.fetch(); this.out(this.a << 8 | n, this.a); return; }   // OUT (n),A
                            case 3: this.fetch(); this.a = 0xFF; return;                // IN A,(n)
                            case 4: { const v = this.rd16(this.sp); this.wr16(this.sp, this.rp(2, x)); this.setRp(2, x, v); return; }
                            case 5: { const v = this.de; this.de = this.hl; this.hl = v; return; }
                            default: return;                                            // DI, EI
                        }
                    case 4: { const a = this.fetch16(); if (this.cond(y)) { this.push(this.pc); this.pc = a; } return; }
                    case 5:
                        if (q === 0) { this.push(p === 3 ? this.af : this.rp(p, x)); return; }
                        { const a = this.fetch16(); this.push(this.pc); this.pc = a; return; }   // CALL nn
                    case 6: this.alu(y, this.fetch()); return;
                    default: this.push(this.pc); this.pc = y * 8; return;            // RST
                }
        }
    }

    cb(x) {
        let ea, op;
        if (x) { ea = this.ea(x); op = this.fetch(); } else { op = this.fetch(); ea = this.hl; }
        const y = op >> 3 & 7, z = op & 7;
        const r = x ? 6 : z;                    // (the undocumented copies to a register aren't kept)
        const v = this.reg(r, 0, ea);
        switch (op >> 6) {
            case 0: this.setReg(r, 0, ea, this.rot(y, v)); return;
            case 1: this.f = (this.f & C) | H | ((v >> y) & 1 ? 0 : Z | PV) | (y === 7 && (v & 0x80) ? S : 0); return;
            case 2: this.setReg(r, 0, ea, v & ~(1 << y)); return;
            default: this.setReg(r, 0, ea, v | 1 << y); return;
        }
    }

    ed() {
        const op = this.fetch(), y = op >> 3 & 7, z = op & 7, p = y >> 1, q = y & 1;
        if (op >> 6 === 1) {
            switch (z) {
                case 0: { const v = this.in(this.bc) & 0xFF; if (y !== 6) this.setReg(y, 0, 0, v); this.f = (this.f & C) | SZP[v]; return; }
                case 1: this.out(this.bc, y === 6 ? 0 : this.reg(y, 0, 0)); return;    // OUT (C),r
                case 2: {
                    const hl = this.hl, v = this.rp(p, 0), c = this.f & C;
                    let r;
                    if (q === 0) {                                              // SBC HL,rr
                        r = hl - v - c;
                        this.f = N | ((r & 0x8000) ? S : 0) | ((r & 0xFFFF) ? 0 : Z) | (((hl ^ v ^ r) >> 8) & H) |
                                 (((hl ^ v) & (hl ^ r) & 0x8000) ? PV : 0) | (r < 0 ? C : 0);
                    } else {                                                    // ADC HL,rr
                        r = hl + v + c;
                        this.f = ((r & 0x8000) ? S : 0) | ((r & 0xFFFF) ? 0 : Z) | (((hl ^ v ^ r) >> 8) & H) |
                                 (((hl ^ ~v) & (hl ^ r) & 0x8000) ? PV : 0) | (r > 0xFFFF ? C : 0);
                    }
                    this.hl = r & 0xFFFF;
                    return;
                }
                case 3: { const a = this.fetch16(); if (q === 0) this.wr16(a, this.rp(p, 0)); else this.setRp(p, 0, this.rd16(a)); return; }
                case 4: { const v = this.a; this.a = 0; this.alu(2, v); return; }   // NEG
                case 5: this.pc = this.pop(); return;                                  // RETN, RETI
                case 6: return;                                                        // IM
                default:
                    switch (y) {
                        case 0: this.i = this.a; return;
                        case 1: this.r = this.a; return;
                        case 2: case 3: this.a = y === 2 ? this.i : this.r; this.f = (this.f & C) | SZ[this.a]; return;
                        case 4: {                                                      // RRD
                            const m = this.rd(this.hl);
                            this.wr(this.hl, (this.a << 4 | m >> 4) & 255);
                            this.a = (this.a & 0xF0) | (m & 15); this.f = (this.f & C) | SZP[this.a]; return;
                        }
                        case 5: {                                                      // RLD
                            const m = this.rd(this.hl);
                            this.wr(this.hl, (m << 4 | (this.a & 15)) & 255);
                            this.a = (this.a & 0xF0) | (m >> 4); this.f = (this.f & C) | SZP[this.a]; return;
                        }
                        default: return;
                    }
            }
        }
        if (op >> 6 === 2 && y >= 4 && z <= 1) {
            const dir = y & 1 ? -1 : 1, rep = y >= 6;
            for (;;) {
                if (z === 0) {                                                  // LDI, LDD
                    this.wr(this.de, this.rd(this.hl));
                    this.de = (this.de + dir) & 0xFFFF; this.hl = (this.hl + dir) & 0xFFFF; this.bc = (this.bc - 1) & 0xFFFF;
                    this.f = (this.f & (S | Z | C)) | (this.bc ? PV : 0);
                    if (!rep || !this.bc) return;
                } else {                                                        // CPI, CPD
                    const v = this.rd(this.hl), r = (this.a - v) & 255;
                    this.hl = (this.hl + dir) & 0xFFFF; this.bc = (this.bc - 1) & 0xFFFF;
                    this.f = (this.f & C) | SZ[r] | ((this.a ^ v ^ r) & H) | N | (this.bc ? PV : 0);
                    if (!rep || !this.bc || !r) return;
                }
                this.count++;
            }
        }
        throw new Error('unknown instruction #ED' + op.toString(16) + ' at #' + ((this.pc - 2) & 0xFFFF).toString(16));
    }
}
