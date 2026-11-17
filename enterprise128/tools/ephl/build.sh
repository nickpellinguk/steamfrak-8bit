#!/bin/sh
# Build ephl, the headless Enterprise 128 for the test harness: build/ephl.
#
# It fetches ep128emu's source (GPL v2) at a fixed commit into build/ep128emu-src, then compiles
# only its emulation (Nick, Dave, the Z80, memory, EXDOS's floppy controller), with none of its
# window, sound or configuration code, and links it with ephl.cpp. It needs a C++ compiler,
# git, and the headers ep128emu's emulation includes:
#
#   apt install g++ libsndfile1-dev portaudio19-dev zlib1g-dev
set -e
cd "$(dirname "$0")/../.."
EP128EMU_COMMIT=9054a7bcb7defb27e23390196c07152f387b3a37
SRC=build/ep128emu-src
OBJ=build/ephl-obj
mkdir -p build "$OBJ"
if [ ! -d "$SRC/.git" ] || [ "$(git -C "$SRC" rev-parse HEAD)" != "$EP128EMU_COMMIT" ]; then
    rm -rf "$SRC"
    git clone -q https://github.com/istvan-v/ep128emu "$SRC"
    git -C "$SRC" checkout -q "$EP128EMU_COMMIT"
fi
CXXFLAGS="-O2 -std=gnu++11 -DHAVE_STDINT_H -I$SRC/src -I$SRC/z80 -I$SRC -w"
OBJS=""
for f in src/bplist src/compress src/comprlib src/dave src/debuglib src/decompm2 src/display \
         src/ep128vm src/ep_fdd src/epmemcfg src/fileio src/ide src/ioports src/memory src/nick \
         src/snapshot src/snd_conv src/soundio src/system src/tape src/videorec src/vm src/wd177x \
         z80/z80 z80/z80funcs2; do
    o="$OBJ/$(basename $f).o"
    if [ ! -f "$o" ] || [ "$SRC/$f.cpp" -nt "$o" ]; then
        g++ $CXXFLAGS -c "$SRC/$f.cpp" -o "$o"
    fi
    OBJS="$OBJS $o"
done
g++ $CXXFLAGS -o build/ephl tools/ephl/ephl.cpp $OBJS -lsndfile -lportaudio -lz -lpthread
echo "Built build/ephl"
