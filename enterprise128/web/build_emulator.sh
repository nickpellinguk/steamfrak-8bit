#!/bin/sh
# Build the emulator for the web page: ep128emu's emulation (as ephl compiles it: the source
# fetched at the same commit, by ../tools/ephl/build.sh's rules) with emscripten, and web/web.cpp,
# linked into one JavaScript file with the WebAssembly inside: build/ep.js.
#
# ep128emu's sound and tape code includes libsndfile's and PortAudio's headers: web/stubs has
# stand-ins (the page opens no sound files and plays no sound yet), and web/audio.cpp is the plain
# AudioOutput the VM sends its sound to, in place of soundio.cpp. Needs emscripten (3.1.6 was used:
# Ubuntu's "emscripten" package) and git.
set -e
cd "$(dirname "$0")/.."
EP128EMU_COMMIT=$(sed -n 's/^EP128EMU_COMMIT=//p' tools/ephl/build.sh)
SRC=build/ep128emu-src
OBJ=build/web-obj
mkdir -p build "$OBJ"
if [ ! -d "$SRC/.git" ] || [ "$(git -C "$SRC" rev-parse HEAD)" != "$EP128EMU_COMMIT" ]; then
    rm -rf "$SRC"
    git clone -q https://github.com/istvan-v/ep128emu "$SRC"
    git -C "$SRC" checkout -q "$EP128EMU_COMMIT"
fi
# (CPC_LSB_FIRST: WebAssembly is little-endian, but ep128emu's Z80 only knows x86 and ARM are, and
# would otherwise lay its register pairs out high byte first)
CXXFLAGS="-O2 -std=gnu++11 -DHAVE_STDINT_H -DCPC_LSB_FIRST=1 -Iweb/stubs -I$SRC/src -I$SRC/z80 -I$SRC -Itools/ephl -w"
OBJS=""
for f in src/bplist src/compress src/comprlib src/dave src/debuglib src/decompm2 src/display \
         src/ep128vm src/ep_fdd src/epmemcfg src/fileio src/ide src/ioports src/memory src/nick \
         src/snapshot src/snd_conv src/system src/tape src/videorec src/vm src/wd177x \
         z80/z80 z80/z80funcs2; do
    o="$OBJ/$(basename $f).o"
    if [ ! -f "$o" ] || [ "$SRC/$f.cpp" -nt "$o" ]; then
        em++ $CXXFLAGS -c "$SRC/$f.cpp" -o "$o"
    fi
    OBJS="$OBJS $o"
done
em++ $CXXFLAGS -o build/ep.js web/web.cpp web/audio.cpp $OBJS \
    -s MODULARIZE=1 -s EXPORT_NAME=Enterprise -s SINGLE_FILE=1 -s ALLOW_MEMORY_GROWTH=1 \
    -s ENVIRONMENT=web,node \
    -s EXPORTED_FUNCTIONS='["_web_start","_web_buffer","_web_load","_web_poke","_web_peek","_web_go","_web_pc","_web_frame","_web_key","_web_screen","_web_palette"]' \
    -s EXPORTED_RUNTIME_METHODS='["HEAPU8","HEAP32"]'
echo "Built build/ep.js"
