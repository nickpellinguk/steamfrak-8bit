#!/bin/sh
# Build the CPC 6128 version: build/frak.dsk, and build/frak.sym (its symbols,
# for the test harness in tools/emu).
#
#   RASM=/path/to/rasm ./build.sh
#
# RASM is Edouard Berge's assembler (https://github.com/EdouardBERGE/rasm),
# built from its source: gcc -O2 -DNO_3RD_PARTIES -o rasm rasm.c -lm
# The graphics come from the BBC version's build (its converter's sprite bank and
# image directory): run ../build.sh first.
set -e
cd "$(dirname "$0")"
RASM=${RASM:-rasm}
mkdir -p build
if [ ! -f ../build/GFX4 ]; then
    echo "Build the BBC version first (../build.sh): this uses its graphics" >&2
    exit 1
fi
python3 tools/gfx.py
rm -f build/frak.dsk
"$RASM" src/frak.asm -o build/frak -s -sa -os build/frak.sym -eo
