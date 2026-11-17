/* A stand-in for PortAudio's header, for the WebAssembly build (build_emulator.sh): ep128emu's
   soundio.hpp declares its PortAudio output class with these types. That class isn't compiled
   (web/audio.cpp gives the plain AudioOutput the VM needs instead). */
#ifndef WEB_STUB_PORTAUDIO_H
#define WEB_STUB_PORTAUDIO_H
typedef void PaStream;
typedef unsigned long PaStreamCallbackFlags;
typedef double PaTime;
typedef struct { PaTime inputBufferAdcTime, currentTime, outputBufferDacTime; } PaStreamCallbackTimeInfo;
#endif
