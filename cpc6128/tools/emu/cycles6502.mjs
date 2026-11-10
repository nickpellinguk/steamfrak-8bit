// The 65C02's (the Master's 65SC12's) cycles for each opcode, without the extra cycle for a
// page crossed (an indexed read, or a branch taken to another page): a branch taken is a cycle
// more, which timed() adds. For comparing the BBC version's timing with the CPC version's.
const T = new Uint8Array(256).fill(2);
for (let op = 0; op < 256; op++) {
    const a = op >> 5, b = (op >> 2) & 7, c = op & 3;
    if (c === 1) {                          // ORA AND EOR ADC STA LDA CMP SBC
        T[op] = [6, 3, 2, 4, 5, 4, 4, 4][b];
        if (a === 4) T[op] = [6, 3, 2, 4, 6, 4, 5, 5][b];     // STA
    } else if (c === 2) {                   // ASL ROL LSR ROR STX LDX DEC INC
        const rmw = a < 4 || a >= 6;
        T[op] = [2, rmw ? 5 : 3, 2, rmw ? 6 : 4, 5, rmw ? 6 : 4, 2, rmw ? 7 : 4][b];
    } else if (c === 0) {
        T[op] = [2, 3, 3, 4, 2, 4, 2, 4][b];
    }
}
// the others, and the 65C02's own
Object.assign(T, {
    0x00: 7, 0x20: 6, 0x40: 6, 0x60: 6, 0x4C: 3, 0x6C: 6, 0x7C: 6,
    0x08: 3, 0x28: 4, 0x48: 3, 0x68: 4, 0x5A: 3, 0x7A: 4, 0xDA: 3, 0xFA: 4,
    0x80: 3, 0x10: 2, 0x30: 2, 0x50: 2, 0x70: 2, 0x90: 2, 0xB0: 2, 0xD0: 2, 0xF0: 2,
    0x64: 3, 0x74: 4, 0x9C: 4, 0x9E: 5, 0x04: 5, 0x0C: 6, 0x14: 5, 0x1C: 6,
    0x89: 2, 0x34: 4, 0x3C: 4, 0x1A: 2, 0x3A: 2,
    0x12: 5, 0x32: 5, 0x52: 5, 0x72: 5, 0x92: 5, 0xB2: 5, 0xD2: 5, 0xF2: 5,
    0x24: 3, 0x2C: 4, 0x84: 3, 0x8C: 4, 0x94: 4, 0xA0: 2, 0xA4: 3, 0xAC: 4, 0xB4: 4, 0xBC: 4,
    0xC0: 2, 0xC4: 3, 0xCC: 4, 0xE0: 2, 0xE4: 3, 0xEC: 4,
    0x88: 2, 0xA8: 2, 0xC8: 2, 0xE8: 2, 0x98: 2, 0xB8: 2, 0x18: 2, 0x38: 2, 0x58: 2, 0x78: 2, 0xD8: 2, 0xF8: 2,
    0x8A: 2, 0x9A: 2, 0xAA: 2, 0xBA: 2, 0xCA: 2, 0xEA: 2,
    0x96: 4, 0xB6: 4, 0xBE: 4, 0x86: 3, 0x8E: 4, 0xA2: 2, 0xA6: 3, 0xAE: 4,
});
// A step of cpu, timed: returns its cycles
export function timed(cpu) {
    const pc = cpu.pc, op = cpu.rd(pc);
    cpu.step();
    let t = T[op];
    if ((op & 0x1F) === 0x10 && cpu.pc !== ((pc + 2) & 0xFFFF)) t++;        // (a branch taken)
    return t;
}
