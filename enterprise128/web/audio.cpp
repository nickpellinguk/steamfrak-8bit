// The WebAssembly build's AudioOutput (ep128emu's soundio.cpp, which also holds the PortAudio
// output and needs PortAudio, isn't compiled): the base class the VM sends its sound to, doing
// nothing (the page plays no sound yet: the game has none). GPL v2 or later, as ep128emu is.
#include "ep128emu.hpp"
#include "soundio.hpp"

namespace Ep128Emu {
  AudioOutput::AudioOutput() : soundFile((SNDFILE *) 0), deviceNumber(-1), sampleRate(48000.0f),
      totalLatency(0.1f), nPeriodsHW(4), nPeriodsSW(4) {}
  AudioOutput::~AudioOutput() {}
  void AudioOutput::setParameters(int d, float s, float t, int h, int w) {
    deviceNumber = d; sampleRate = s; totalLatency = t; nPeriodsHW = h; nPeriodsSW = w;
  }
  void AudioOutput::setOutputFile(const std::string& fileName) { outputFileName = fileName; }
  void AudioOutput::sendAudioData(const int16_t *buf, size_t nFrames) { (void) buf; (void) nFrames; }
  void AudioOutput::closeDevice() {}
  std::vector< std::string > AudioOutput::getDeviceList() { return std::vector< std::string >(); }
  void AudioOutput::openDevice() {}
}
