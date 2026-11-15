#!/bin/sh
# Build the emulator for the web page: atari800 5.0's libatari800, compiled with emscripten, and
# web/web.c, linked into one JavaScript file with the WebAssembly inside (a8.js, in OUT).
#   ATARI800_SRC  atari800 5.0's source (e.g. "apt-get source atari800" on Ubuntu, or a release
#                 from github.com/atari800/atari800)
#   OUT           where a8.js goes (default build/)
# Needs emscripten (3.1.6 was used: Ubuntu's "emscripten" package).
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=${OUT:-$HERE/../build}
cd "$ATARI800_SRC"
if [ ! -f src/libatari800.a ]; then
    # (configure can't run wasm programs, so it's told it's cross-compiling to a stand-in host;
    # the R: device needs a serial port, and libatari800/main.c calls a function it doesn't declare)
    CFLAGS="-O2 -Wno-error=implicit-function-declaration" emconfigure ./configure \
        --host=i686-pc-linux-gnu --target=libatari800 --without-readline --disable-riodevice
    emmake make -j8
fi
cd src
emcc -O2 -I. "$HERE/web.c" libatari800.a -o "$OUT/a8.js" \
    -s MODULARIZE=1 -s EXPORT_NAME=Atari800 -s SINGLE_FILE=1 -s ALLOW_MEMORY_GROWTH=1 \
    -s FORCE_FILESYSTEM=1 -s ENVIRONMENT=web,node \
    -s EXPORTED_FUNCTIONS='["_web_start","_web_reboot","_web_frame","_web_screen","_web_palette","_web_sound","_web_sound_len","_web_memory"]' \
    -s EXPORTED_RUNTIME_METHODS='["FS","cwrap","HEAPU8","HEAP16","HEAP32"]'
echo "Built $OUT/a8.js"
