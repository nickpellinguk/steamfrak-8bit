// The browser's side of the emulator: ep128emu's emulation (as ephl, ../tools/ephl, runs it, with
// the same display: headless.hpp), compiled with emscripten, run a frame at a time by the page.
//
// No Enterprise ROMs: the machine starts as EXOS and EXDOS would have left it once they'd loaded
// the game from its disk, as the test harness's quick start does (tools/emu/harness.mjs), and the
// program then takes the machine over as it always does. The page writes the program (START, at
// #0100 in segment #F8: web_load) and its four files where the program's load_files would put
// them (GFX.BIN in #F9, LOGIC.BIN in #FA, LOADER.BIN in #FE, TOP.BIN in #FC), and a font in video
// RAM where EXOS keeps its own (#FF, at Nick's #F480: copy_font copies it from there); web_start
// puts a stand-in for EXOS's calls at RST #30, as the program only makes four (frak.asm):
// open, read a block and close a file, which it answers "done" (the files are there already),
// and allocate a segment, which gives out #F9-#FE in turn, as EXOS does on a 128 with EXDOS,
// then says there are no more (#7F).
//
// GPL v2 or later, as ep128emu is.

#include "ep128emu.hpp"
#include "ep128vm.hpp"
#include "nick.hpp"
#include "headless.hpp"

#include <cstdlib>
#include <cstring>

static HeadlessDisplay *display = 0;
static NullAudio *audio = 0;
static Ep128::Ep128VM *vm = 0;
static uint8_t *buffer = 0;
static size_t bufferSize = 0;
static int palette[256];

// The stand-in for EXOS's calls: RST #30 (a function number in the byte after it) jumps to
// #0060, which steps past the function number; allocate a segment (24) gives out the next of
// #F9-#FE in C (A = 0), then A = #7F; anything else is done (A = 0)
static const uint8_t rst30[] = { 0xC3, 0x60, 0x00 };          // #0030: jp #0060
static const uint8_t exos[] = {
  0xE3,                   // #0060: ex (sp),hl
  0x7E,                   //        ld a,(hl)      (the function number)
  0x23,                   //        inc hl
  0xE3,                   //        ex (sp),hl
  0xFE, 0x18,             //        cp 24
  0x28, 0x02,             //        jr z,alloc
  0xAF,                   //        xor a
  0xC9,                   //        ret
  0x3A, 0x80, 0x00,       // alloc: ld a,(#0080)   (the next segment to give out)
  0xFE, 0xFF,             //        cp #FF
  0x28, 0x07,             //        jr z,none
  0x4F,                   //        ld c,a
  0x3C,                   //        inc a
  0x32, 0x80, 0x00,       //        ld (#0080),a
  0xAF,                   //        xor a
  0xC9,                   //        ret
  0x3E, 0x7F,             // none:  ld a,#7F
  0xC9,                   //        ret
};

extern "C" {

// Switch on (again): ep128emu's 128K Enterprise, with the video RAM's wait states, reset, paged
// as EXOS leaves a program it's loaded (page 0 the program's segment, #F8), and the stand-in for
// EXOS's calls put in. The page then loads the files (web_load) and starts it (web_go)
int web_start(void)
{
  if (!vm) {
    display = new HeadlessDisplay();
    audio = new NullAudio();
    vm = new Ep128::Ep128VM(*display, *audio);
  }
  vm->setEnableMemoryTimingEmulation(true);
  vm->resetMemoryConfiguration(128);
  vm->reset(true);
  for (int k = 0; k < 4 * 16384; k++) vm->writeMemory(uint32_t(0xF8 * 16384 + k), 0);  // (#F8-#FB)
  static const uint8_t pages[4] = { 0xF8, 0xF9, 0xFA, 0xFF };
  for (int p = 0; p < 4; p++) vm->writeIOPort(uint16_t(0xB0 + p), pages[p]);
  vm->writeIOPort(0xB4, 0x00);            // (Dave's interrupts off)
  vm->writeIOPort(0xBF, 0x04);            // (as EXOS sets it at a reset)
  for (size_t k = 0; k < sizeof rst30; k++) vm->writeMemory(uint32_t(0xF8 * 16384 + 0x30 + k), rst30[k]);
  for (size_t k = 0; k < sizeof exos; k++) vm->writeMemory(uint32_t(0xF8 * 16384 + 0x60 + k), exos[k]);
  vm->writeMemory(uint32_t(0xF8 * 16384 + 0x80), 0xF9);
  return 1;
}

// A buffer for the page to put a file's bytes in (at least n), then web_load
uint8_t *web_buffer(int n)
{
  if (size_t(n) > bufferSize) {
    std::free(buffer);
    buffer = (uint8_t *) std::malloc(size_t(n));
    bufferSize = size_t(n);
  }
  return buffer;
}

// Copy the buffer's first n bytes into segment seg from offset off (and on into the next ones)
void web_load(int seg, int off, int n)
{
  for (int k = 0; k < n; k++) vm->writeMemory(uint32_t(seg * 16384 + off + k), buffer[k]);
}

// Write a byte into segment seg
void web_poke(int seg, int off, int value) { vm->writeMemory(uint32_t(seg * 16384 + off), uint8_t(value)); }
int web_peek(int seg, int off) { return vm->readMemory(uint32_t(seg * 16384 + off)); }

// Start the Z80 at pc (EXOS jumps to a type 5 program at #0100)
void web_go(int pc) { vm->setProgramCounter(uint16_t(pc)); }

// Where the Z80 is (for tests)
int web_pc(void) { return vm->getProgramCounter(); }

// Run a frame (20ms: the PAL frame); the frames Nick has finished so far
int web_frame(void)
{
  vm->run(20000);
  return int(display->frames);
}

// A key of the keyboard matrix (row * 8 + bit, as Dave scans it: machine.asm's KEY_ numbers)
// pressed (1) or let go (0)
void web_key(int code, int down) { vm->setKeyboardState(code, down != 0); }

// The last whole frame: 768 x 288 palette indices, and the palette (256 x 0xRRGGBB)
const uint8_t *web_screen(void) { return &display->frame()[0]; }
const int *web_palette(void)
{
  for (int i = 0; i < 256; i++) {
    float r, g, b;
    Ep128::Nick::convertPixelToRGB(uint8_t(i), r, g, b);
    palette[i] = int(r * 255.0f + 0.5f) << 16 | int(g * 255.0f + 0.5f) << 8 | int(b * 255.0f + 0.5f);
  }
  return palette;
}

}
