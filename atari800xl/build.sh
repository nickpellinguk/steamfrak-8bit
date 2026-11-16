#!/bin/sh
# Build the 8x4 screen demo (build/screen8x4.xex), Trogg on it (build/trogg8x4.xex) and the
# 4-line row test (build/rows4.xex).
#   LEVEL    the level shown (default A_1: the C64 port's levels/<LEVEL>.txt)
#   STILLX   hold the scroll at this position (colour clocks) instead of moving
#   STEAMFRAK  the steamfrak repository, for Trogg's sprites (default ../../steamfrak)
# Needs node (for the C64 port's level.mjs), Python 3 with Pillow, and 64tass.
set -e
cd "$(dirname "$0")"
LEVEL=${LEVEL:-A_1}
[ -f ../c64/build/$LEVEL/chars.bin ] || (cd ../c64 && node tools/level.mjs $LEVEL --out $LEVEL)
python3 tools/screen.py $LEVEL
python3 tools/sprites.py
python3 tools/geom.py $LEVEL
OPT=""; [ -n "$STILLX" ] && OPT="-D STILLX=$STILLX"
(cd src && 64tass --atari-xex -q -D LEVEL=\"$LEVEL\" $OPT screen8x4.asm -o ../build/screen8x4.xex)
(cd src && 64tass --atari-xex -q -D LEVEL=\"$LEVEL\" trogg8x4.asm -o ../build/trogg8x4.xex --labels=../build/trogg8x4.lbl)
(cd test && 64tass --atari-xex -q -D MODE=1 -D DELAY=1 -D HSC=1 -D PMDMA=1 rows4.asm -o ../build/rows4.xex)
echo "Built build/screen8x4.xex, build/trogg8x4.xex ($LEVEL) and build/rows4.xex"
