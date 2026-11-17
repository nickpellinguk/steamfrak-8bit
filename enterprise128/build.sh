#!/bin/sh
# Build the Enterprise 128 version: build/frak.img (an EXDOS disk image holding
# build/FRAK.COM), and build/frak.sym (its symbols, for the test harness in tools/emu).
#
#   RASM=/path/to/rasm ./build.sh
#
# RASM is Edouard Berge's assembler (https://github.com/EdouardBERGE/rasm), as for
# the CPC version: gcc -O2 -DNO_3RD_PARTIES -o rasm rasm.c -lm
set -e
cd "$(dirname "$0")"
RASM=${RASM:-rasm}
mkdir -p build
"$RASM" src/frak.asm -s -sa -os build/frak.sym -eo
python3 tools/mkdisk.py build/frak.img build/FRAK.COM
echo "Built build/frak.img"
