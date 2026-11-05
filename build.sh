#!/bin/sh
# Build frak.ssd: convert the data from the web version, then assemble.
#   STEAMFRAK  path to the steamfrak repository (default ../steamfrak)
#   BEEBASM    path to the beebasm executable (default: beebasm on the PATH)
#   LEVEL      GameMaker room to build (default room_A_1)
set -e
cd "$(dirname "$0")"
STEAMFRAK=${STEAMFRAK:-../steamfrak}
BEEBASM=${BEEBASM:-beebasm}
LEVEL=${LEVEL:-room_A_1}
python3 tools/convert.py "$STEAMFRAK" "$LEVEL"
"$BEEBASM" -i src/frak.asm -do build/frak.ssd -opt 3 -title FRAK
echo "Built build/frak.ssd"
