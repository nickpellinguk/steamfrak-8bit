// The headless display, shared by ephl (ephl.cpp) and the web page's emulator (../../web/web.cpp):
// it decodes each line Nick draws into palette indices and keeps the last whole frame, 768 x 288
// (a Nick slot 16 pixels across, so a 4-colour pixel is 2; each line once). And an audio output
// that drops the sound. GPL v2 or later, as ep128emu is.
#ifndef EPHL_HEADLESS_HPP
#define EPHL_HEADLESS_HPP

#include "ep128emu.hpp"
#include "display.hpp"
#include "soundio.hpp"

#include <cstring>
#include <vector>

static const int WIDTH = 768, HEIGHT = 288;

// The display: decodes each line Nick draws (ep128emu's compressed line format: a flag byte a
// slot, then that slot's colours) into palette indices, and keeps the last whole frame
class HeadlessDisplay : public Ep128Emu::VideoDisplay {
  Ep128Emu::VideoDisplay::DisplayParameters params;
  std::vector<uint8_t> cur, last;
  int curLine, vsyncCnt, linesSinceSync;
  bool vsyncState;
 public:
  long frames;
  std::vector<int> syncLines;               // (lines between vertical syncs, the last 16)
  HeadlessDisplay() : cur(WIDTH * HEIGHT), last(WIDTH * HEIGHT), curLine(0), vsyncCnt(0),
                      linesSinceSync(0), vsyncState(false), frames(0) {}
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
  // The frame's lines, counted as ep128emu's own display counts them (FLTKDisplay_::drawLine
  // and vsyncStateChange, in its src/fldisp.cpp), a line of the picture for each two of its
  // (it doubles them, for interlace)
  virtual void drawLine(const uint8_t *buf, size_t nBytes) {
    (void) nBytes;
    linesSinceSync++;
    if (curLine >= 0 && curLine < 2 * HEIGHT) decode(&cur[(curLine >> 1) * WIDTH], buf);
    if (vsyncCnt != 0) {
      curLine += 2;
      if (vsyncCnt >= (EP128EMU_VSYNC_MIN_LINES + 2 - EP128EMU_VSYNC_OFFSET) &&
          (vsyncState || vsyncCnt >= (EP128EMU_VSYNC_MAX_LINES + 2 - EP128EMU_VSYNC_OFFSET)))
        vsyncCnt = 2 - EP128EMU_VSYNC_OFFSET;
      vsyncCnt++;
    }
    else {
      curLine = 0;
      vsyncCnt++;
      endFrame();
    }
  }
  virtual void vsyncStateChange(bool newState, unsigned int currentSlot) {
    (void) currentSlot;
    if (newState && !vsyncState) {
      syncLines.push_back(linesSinceSync);
      if (syncLines.size() > 16) syncLines.erase(syncLines.begin());
      linesSinceSync = 0;
    }
    vsyncState = newState;
    if (newState && vsyncCnt >= (EP128EMU_VSYNC_MIN_LINES + 2 - EP128EMU_VSYNC_OFFSET))
      vsyncCnt = 2 - EP128EMU_VSYNC_OFFSET;
  }
  void endFrame() {
    last.swap(cur);
    std::fill(cur.begin(), cur.end(), 0);
    frames++;
  }
};

class NullAudio : public Ep128Emu::AudioOutput {
 public:
  virtual void sendAudioData(const int16_t *buf, size_t nFrames) { (void) buf; (void) nFrames; }
};

#endif
