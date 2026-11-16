#!/bin/sh
# Build the 8x4 screen demo (build/screen8x4.xex), the game (build/trogg8x4.xex: A_1, A_2 and A_3,
# the front end's 1, 2, 3) and the 4-line row test (build/rows4.xex).
#   LEVEL    the screen demo's level (default A_1: the C64 port's levels/<LEVEL>.txt)
#   STILLX   hold the scroll at this position (colour clocks) instead of moving
#   STEAMFRAK  the steamfrak repository, for Trogg's sprites (default ../../steamfrak)
# Needs node (for the C64 port's level.mjs), Python 3 with Pillow, and 64tass.
set -e
cd "$(dirname "$0")"
LEVEL=${LEVEL:-A_1}
python3 tools/sprites.py
for L in A_1 A_2 A_3; do            # (the game carries the three: levels.py packs them)
    [ -f ../c64/build/$L/chars.bin ] || (cd ../c64 && node tools/level.mjs $L --out $L)
    python3 tools/screen.py $L
    python3 tools/geom.py $L
done
python3 tools/levels.py
python3 tools/screen.py $LEVEL >/dev/null        # (screen8x4.asm's level's, left built)
# (the front end: the same for every level, and slow to pack: only when front.py's changed)
[ build/front.inc -nt tools/front.py ] || python3 tools/front.py
OPT=""; [ -n "$STILLX" ] && OPT="-D STILLX=$STILLX"
(cd src && 64tass --atari-xex -q -D LEVEL=\"$LEVEL\" $OPT screen8x4.asm -o ../build/screen8x4.xex)
sh tools/game.sh trogg8x4 >/dev/null     # (the game: its overlay assembled and packed too)
(cd test && 64tass --atari-xex -q -D MODE=1 -D DELAY=1 -D HSC=1 -D PMDMA=1 rows4.asm -o ../build/rows4.xex)
echo "Built build/screen8x4.xex ($LEVEL), build/trogg8x4.xex (A_1, A_2, A_3) and build/rows4.xex"
