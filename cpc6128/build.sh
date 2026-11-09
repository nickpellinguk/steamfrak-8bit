#!/bin/sh
# Build the CPC 6128 version: build/frak.dsk, and build/frak.sym (its symbols,
# for the test harness in tools/emu).
#
#   RASM=/path/to/rasm ./build.sh
#
# RASM is Edouard Berge's assembler (https://github.com/EdouardBERGE/rasm),
# built from its source: gcc -O2 -DNO_3RD_PARTIES -o rasm rasm.c -lm
set -e
cd "$(dirname "$0")"
RASM=${RASM:-rasm}
mkdir -p build
rm -f build/frak.dsk
"$RASM" src/frak.asm -o build/frak -s -sa -os build/frak.sym -eo
