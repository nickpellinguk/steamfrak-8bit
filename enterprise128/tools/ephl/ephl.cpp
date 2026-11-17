// ephl: a headless Enterprise 128, for the test harness (../emu). It runs ep128emu's emulation
// (https://github.com/istvan-v/ep128emu, by Istvan Varga: Nick, Dave, the Z80 with video RAM's
// wait states, and EXDOS) with no window and no sound, as fast as it can, working through a
// list of steps, one a line, and printing what they say to standard output. The steps are the
// ones ../emu/steps.lua takes in MAME, so the tests can run on either:
//
//   wait N                 run N frames (20ms each)
//   waitfor ADDR VALUE MAX run until the byte at ADDR (the Z80's 64K) is VALUE, at most MAX
//                          frames (then stop: "OUT timeout ADDR STEP")
//   type TEXT              type TEXT on the keyboard ("\n" for Enter): letters, digits, space
//   poke ADDR VALUE        write a byte into the Z80's 64K, as it's paged
//   peek LABEL ADDR LEN    print LEN bytes: "OUT peek LABEL b1 b2 ..."
//   speek LABEL SEG OFF LEN
//                          print LEN bytes from segment SEG (as peek)
//   spoke SEG OFF VALUE    write a byte into segment SEG
//   load ADDR FILE         copy a file into the Z80's 64K at ADDR
//   sload SEG OFF FILE     copy a file into segment SEG (and on into the next segments)
//   dump LABEL ADDR LEN    write LEN bytes from ADDR to LABEL.bin (in the output directory)
//   sdump LABEL SEG OFF LEN
//                          likewise from segment SEG
//   fill SEG OFF LEN SEED  fill LEN bytes of segment SEG from OFF with pseudo-random ones
//   jump ADDR              set the Z80's PC to ADDR
//   regs LABEL             "OUT regs LABEL PC=.... SP=...."
//   pages LABEL            the segments at pages 0-3: "OUT peek LABEL s0 s1 s2 s3"
//   time LABEL             the emulated time in seconds: "OUT time LABEL secs"
//   key ROW MASK 1|0       press (1) or let go of (0) the key at that row (0-9) and bit mask
//                          of the keyboard matrix: "OUT key ROW MASK"
//   snap LABEL             write the last whole frame to shotN.png (in the output directory):
//                          "OUT snap LABEL"
//   quit                   stop: "OUT done"
//
//   ephl --exos FILE [--exdos FILE] [--disk IMAGE] --steps FILE --out DIR [--seconds N]
//
// --exos is EXOS 2.1 (32K, ROM segments 0-1), --exdos EXDOS 1.3 (32K, ROM segments #20-#21).
// The screenshots are 768 x 288: a Nick slot is 16 pixels across (so a 4-colour pixel is 2), and
// each line once (Nick doesn't interlace).
//
// This file is under the GNU General Public License, version 2 or later, as ep128emu is.

#include "ep128emu.hpp"
#include "display.hpp"
#include "soundio.hpp"
#include "ep128vm.hpp"
#include "nick.hpp"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <zlib.h>

static const int WIDTH = 768, HEIGHT = 288;

// The display: decodes each line Nick draws (ep128emu's compressed line format: a flag byte a
// slot, then that slot's colours) into palette indices, and keeps the last whole frame
class HeadlessDisplay : public Ep128Emu::VideoDisplay {
  Ep128Emu::VideoDisplay::DisplayParameters params;
  std::vector<uint8_t> cur, last;
  int line, vsyncCnt;
  bool vsyncState;
 public:
  long frames;
  HeadlessDisplay() : cur(WIDTH * HEIGHT), last(WIDTH * HEIGHT), line(0), vsyncCnt(0),
                      vsyncState(false), frames(0) {}
  virtual void setDisplayParameters(const DisplayParameters& dp) { params = dp; }
  virtual const DisplayParameters& getDisplayParameters() const { return params; }
  const std::vector<uint8_t>& frame() const { return last; }

  static void decode(uint8_t *out, const uint8_t *in) {
    uint8_t *end = out + WIDTH;
    while (out < end) {
      switch (in[0]) {
      case 0x00: std::memset(out, 0, 16); in += 1; break;
      case 0x01: std::memset(out, in[1], 16); in += 2; break;
      case 0x02: std::memset(out, in[1], 8); std::memset(out + 8, in[2], 8); in += 3; break;
      case 0x03:                                  // 8 pixels (each 2 wide), 2 colours
        for (int k = 0; k < 8; k++) out[2 * k] = out[2 * k + 1] = (in[3] & (128 >> k)) ? in[2] : in[1];
        in += 4; break;
      case 0x04: for (int k = 0; k < 4; k++) std::memset(out + 4 * k, in[1 + k], 4); in += 5; break;
      case 0x06:                                  // 16 pixels, two lots of 2 colours
        for (int k = 0; k < 8; k++) out[k] = (in[3] & (128 >> k)) ? in[2] : in[1];
        for (int k = 0; k < 8; k++) out[8 + k] = (in[6] & (128 >> k)) ? in[5] : in[4];
        in += 7; break;
      case 0x08: for (int k = 0; k < 8; k++) out[2 * k] = out[2 * k + 1] = in[1 + k]; in += 9; break;
      default: std::memset(out, 0, end - out); return;
      }
      out += 16;
    }
  }
  // (the frame's lines counted from a vertical sync, as ep128emu's own display does)
  virtual void drawLine(const uint8_t *buf, size_t nBytes) {
    (void) nBytes;
    int y = line - EP128EMU_VSYNC_OFFSET;
    if (y >= 0 && y < HEIGHT) decode(&cur[y * WIDTH], buf);
    line++;
    if (vsyncCnt++ >= EP128EMU_VSYNC_MAX_LINES) endFrame();
  }
  virtual void vsyncStateChange(bool newState, unsigned int currentSlot) {
    (void) currentSlot;
    if (newState && !vsyncState && vsyncCnt >= EP128EMU_VSYNC_MIN_LINES) endFrame();
    vsyncState = newState;
  }
  void endFrame() {
    last.swap(cur);
    std::fill(cur.begin(), cur.end(), 0);
    line = 0; vsyncCnt = 0; frames++;
  }
};

class NullAudio : public Ep128Emu::AudioOutput {
 public:
  virtual void sendAudioData(const int16_t *buf, size_t nFrames) { (void) buf; (void) nFrames; }
};

static std::string outDir;
static int shotNum = 0;

static void put32(std::string& s, uint32_t v) {
  for (int k = 24; k >= 0; k -= 8) s += char((v >> k) & 255);
}
static void chunk(std::string& png, const char *type, const std::string& data) {
  std::string c(type, 4);
  c += data;
  put32(png, uint32_t(data.size()));
  png += c;
  put32(png, uint32_t(crc32(0, (const Bytef *) c.data(), uInt(c.size()))));
}
static void writePng(const std::string& file, const std::vector<uint8_t>& px) {
  std::string raw;
  for (int y = 0; y < HEIGHT; y++) {
    raw += char(0);
    for (int x = 0; x < WIDTH; x++) {
      float r, g, b;
      Ep128::Nick::convertPixelToRGB(px[y * WIDTH + x], r, g, b);
      raw += char(int(r * 255.0f + 0.5f)); raw += char(int(g * 255.0f + 0.5f)); raw += char(int(b * 255.0f + 0.5f));
    }
  }
  uLongf len = compressBound(uLong(raw.size()));
  std::string z(len, '\0');
  compress((Bytef *) &z[0], &len, (const Bytef *) raw.data(), uLong(raw.size()));
  z.resize(len);
  std::string png("\x89PNG\r\n\x1a\n", 8), ihdr;
  put32(ihdr, WIDTH); put32(ihdr, HEIGHT);
  ihdr += char(8); ihdr += char(2); ihdr += char(0); ihdr += char(0); ihdr += char(0);
  chunk(png, "IHDR", ihdr);
  chunk(png, "IDAT", z);
  chunk(png, "IEND", "");
  std::ofstream(file.c_str(), std::ios::binary) << png;
}

static std::string readFile(const std::string& file) {
  std::ifstream f(file.c_str(), std::ios::binary);
  if (!f) { std::cerr << "ephl: can't read " << file << "\n"; std::exit(2); }
  std::ostringstream s; s << f.rdbuf();
  return s.str();
}
static void writeFile(const std::string& label, const std::string& data) {
  std::ofstream(outDir + "/" + label + ".bin", std::ios::binary) << data;
}

// The keyboard matrix position (row * 8 + bit, as Dave counts them) of a character to type
static int keyFor(char c) {
  static const char *rows[10] = { "N\\BCVXZ~", "H~GDFSA~", "UQYRTEW~", "7164532~", "~~~~~~~~",
      "8~9-0^~~", "J~K;L:]~", "~~~~~~~~", "M~,/.~ ~", "I~O@P[~~" };   // (~: not typed)
  if (c == '\n') return 0x3E;
  if (c >= 'a' && c <= 'z') c = char(c - 32);
  for (int r = 0; r < 10; r++)
    for (int b = 0; b < 8; b++)
      if (rows[r][b] == c && c != '~') return r * 8 + b;
  return -1;
}

int main(int argc, char **argv) {
  std::string exos, exdos, disk, stepsFile;
  double seconds = 120;
  for (int k = 1; k + 1 < argc; k += 2) {
    std::string a = argv[k], v = argv[k + 1];
    if (a == "--exos") exos = v;
    else if (a == "--exdos") exdos = v;
    else if (a == "--disk") disk = v;
    else if (a == "--steps") stepsFile = v;
    else if (a == "--out") outDir = v;
    else if (a == "--seconds") seconds = std::atof(v.c_str());
    else { std::cerr << "ephl: unknown option " << a << "\n"; return 2; }
  }
  if (exos.empty() || stepsFile.empty() || outDir.empty()) {
    std::cerr << "usage: ephl --exos FILE [--exdos FILE] [--disk IMAGE] --steps FILE --out DIR [--seconds N]\n";
    return 2;
  }
  std::vector<std::string> steps;
  {
    std::istringstream in(readFile(stepsFile));
    std::string line;
    while (std::getline(in, line)) if (!line.empty()) steps.push_back(line);
  }

  HeadlessDisplay display;
  NullAudio audio;
  Ep128::Ep128VM *vm = new Ep128::Ep128VM(display, audio);
  vm->setEnableMemoryTimingEmulation(true);
  vm->resetMemoryConfiguration(128);
  vm->loadROMSegment(0x00, exos.c_str(), 0);
  vm->loadROMSegment(0x01, exos.c_str(), 16384);
  if (!exdos.empty()) {
    vm->loadROMSegment(0x20, exdos.c_str(), 0);
    vm->loadROMSegment(0x21, exdos.c_str(), 16384);
  }
  if (!disk.empty()) vm->setDiskImageFile(0, disk);
  vm->reset(true);

  const size_t FRAME_US = 20000;
  double now = 0;
  int waiting = 0;
  bool waitingFor = false;
  int waitAddr = 0, waitValue = 0, waitMax = 0;
  std::string typing;               // characters still to type ...
  int typeHeld = -1, typeFrames = 0;  // ... and the key held now, and for how long
  size_t i = 0;
  while (true) {
    // the steps that don't need time to pass
    while (i < steps.size() && !waiting && !waitingFor) {
      std::istringstream s(steps[i++]);
      std::string op; s >> op;
      if (op == "wait") s >> waiting;
      else if (op == "waitfor") { s >> waitAddr >> waitValue >> waitMax; waitingFor = true; }
      else if (op == "type") {
        std::string rest; std::getline(s, rest);
        if (!rest.empty() && rest[0] == ' ') rest.erase(0, 1);
        for (size_t k = 0; k < rest.size(); k++) {
          if (rest[k] == '\\' && k + 1 < rest.size() && rest[k + 1] == 'n') { typing += '\n'; k++; }
          else typing += rest[k];
        }
      }
      else if (op == "poke") { int a, v; s >> a >> v; vm->writeMemory(uint32_t(a), uint8_t(v), true); }
      else if (op == "peek" || op == "speek") {
        std::string label; int seg = 0, a, n; s >> label;
        if (op == "speek") s >> seg;
        s >> a >> n;
        std::cout << "OUT peek " << label;
        for (int k = 0; k < n; k++)
          std::cout << " " << int(op == "peek" ? vm->readMemory(uint32_t((a + k) & 0xFFFF), true)
                                               : vm->readMemory(uint32_t(seg * 16384 + a + k)));
        std::cout << "\n";
      }
      else if (op == "spoke") { int seg, a, v; s >> seg >> a >> v; vm->writeMemory(uint32_t(seg * 16384 + a), uint8_t(v)); }
      else if (op == "load" || op == "sload") {
        int seg = 0, a; std::string file;
        if (op == "sload") s >> seg;
        s >> a >> file;
        std::string data = readFile(file);
        for (size_t k = 0; k < data.size(); k++) {
          if (op == "load") vm->writeMemory(uint32_t((a + k) & 0xFFFF), uint8_t(data[k]), true);
          else vm->writeMemory(uint32_t(seg * 16384 + a + k), uint8_t(data[k]));
        }
      }
      else if (op == "dump" || op == "sdump") {
        std::string label, data; int seg = 0, a, n; s >> label;
        if (op == "sdump") s >> seg;
        s >> a >> n;
        for (int k = 0; k < n; k++)
          data += char(op == "dump" ? vm->readMemory(uint32_t((a + k) & 0xFFFF), true)
                                    : vm->readMemory(uint32_t(seg * 16384 + a + k)));
        writeFile(label, data);
      }
      else if (op == "fill") {
        long seg, a, n, x; s >> seg >> a >> n >> x;
        for (long k = 0; k < n; k++) {
          x = (x * 1103515245L + 12345L) % 2147483648L;
          vm->writeMemory(uint32_t(seg * 16384 + a + k), uint8_t((x >> 16) & 255));
        }
      }
      else if (op == "jump") { int a; s >> a; vm->setProgramCounter(uint16_t(a)); }
      else if (op == "regs") {
        std::string label; s >> label;
        char buf[64];
        std::snprintf(buf, sizeof buf, "PC=%04X SP=%04X", vm->getProgramCounter(),
                      unsigned(vm->getZ80Registers().SP.W));
        std::cout << "OUT regs " << label << " " << buf << "\n";
      }
      else if (op == "pages") {
        std::string label; s >> label;
        std::cout << "OUT peek " << label;
        for (int p = 0; p < 4; p++) std::cout << " " << int(vm->getMemoryPage(p));
        std::cout << "\n";
      }
      else if (op == "time") {
        std::string label; s >> label;
        char buf[32]; std::snprintf(buf, sizeof buf, "%.6f", now);
        std::cout << "OUT time " << label << " " << buf << "\n";
      }
      else if (op == "key") {
        int row, mask, v; s >> row >> mask >> v;
        int bit = 0;
        while (bit < 8 && !(mask & (1 << bit))) bit++;
        vm->setKeyboardState(row * 8 + bit, v);
        std::cout << "OUT key " << row << " " << mask << "\n";
      }
      else if (op == "snap") {
        std::string label; s >> label;
        char name[32]; std::snprintf(name, sizeof name, "shot%d.png", shotNum++);
        writePng(outDir + "/" + name, display.frame());
        std::cout << "OUT snap " << label << " " << name << "\n";
      }
      else if (op == "quit") { std::cout << "OUT done\n"; std::cout.flush(); return 0; }
      else { std::cerr << "ephl: unknown step: " << steps[i - 1] << "\n"; return 2; }
    }
    if (i >= steps.size() && !waiting && !waitingFor) { std::cout << "OUT done\n"; return 0; }
    // a frame, typing a key at a time (each held for 3 frames, then 3 frames up)
    if (typeHeld < 0 && !typing.empty() && typeFrames == 0) {
      typeHeld = keyFor(typing[0]);
      typing.erase(0, 1);
      if (typeHeld >= 0) vm->setKeyboardState(typeHeld, 1);
      typeFrames = 3;
    }
    vm->run(FRAME_US);
    now += FRAME_US / 1e6;
    if (typeFrames > 0 && --typeFrames == 0 && typeHeld >= 0) {
      vm->setKeyboardState(typeHeld, 0); typeHeld = -1; typeFrames = -3;
    }
    else if (typeFrames < 0) typeFrames++;
    if (waiting) waiting--;
    if (waitingFor) {
      if (vm->readMemory(uint32_t(waitAddr), true) == waitValue) waitingFor = false;
      else if (--waitMax <= 0) {
        char buf[64];
        std::snprintf(buf, sizeof buf, "PC=%04X SP=%04X", vm->getProgramCounter(),
                      unsigned(vm->getZ80Registers().SP.W));
        std::cout << "OUT stuck " << buf << "\nOUT timeout " << waitAddr << " " << (i - 1) << "\n";
        return 1;
      }
    }
    if (now > seconds) { std::cout << "OUT out of time\n"; return 1; }
  }
}
