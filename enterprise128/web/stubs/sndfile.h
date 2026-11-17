/* A stand-in for libsndfile's header, for the WebAssembly build (build_emulator.sh): ep128emu's
   tape and sound-file code includes it, and the page uses neither, so opening a file always
   fails and nothing else is ever called. */
#ifndef WEB_STUB_SNDFILE_H
#define WEB_STUB_SNDFILE_H
#include <stdint.h>
#include <stdio.h>
typedef int64_t sf_count_t;
typedef struct SNDFILE_tag SNDFILE;
typedef struct { sf_count_t frames; int samplerate, channels, format, sections, seekable; } SF_INFO;
enum { SFM_READ = 0x10, SFM_WRITE = 0x20, SFM_RDWR = 0x30 };
enum { SF_FORMAT_WAV = 0x010000, SF_FORMAT_PCM_S8 = 1, SF_FORMAT_PCM_16 = 2, SF_FORMAT_PCM_24 = 3,
       SF_FORMAT_PCM_32 = 4, SF_FORMAT_PCM_U8 = 5, SF_FORMAT_FLOAT = 6, SF_FORMAT_DOUBLE = 7,
       SF_FORMAT_ULAW = 0x10, SF_FORMAT_ALAW = 0x11, SF_FORMAT_IMA_ADPCM = 0x12,
       SF_FORMAT_MS_ADPCM = 0x13, SF_FORMAT_SUBMASK = 0xFFFF };
static inline SNDFILE *sf_open(const char *p, int m, SF_INFO *i) { (void) p; (void) m; (void) i; return 0; }
static inline int sf_close(SNDFILE *f) { (void) f; return 0; }
static inline sf_count_t sf_seek(SNDFILE *f, sf_count_t n, int w) { (void) f; (void) n; (void) w; return -1; }
static inline sf_count_t sf_readf_short(SNDFILE *f, short *b, sf_count_t n) { (void) f; (void) b; (void) n; return 0; }
static inline sf_count_t sf_writef_short(SNDFILE *f, const short *b, sf_count_t n) { (void) f; (void) b; (void) n; return 0; }
#endif
