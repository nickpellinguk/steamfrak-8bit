#!/bin/sh
# Build frak.ssd: convert the data from the web version, then assemble.
#   STEAMFRAK  path to the steamfrak repository (default ../steamfrak)
#   BEEBASM    path to the beebasm executable (default: beebasm on the PATH)
#   LEVEL      GameMaker room to start at (default room_A_1)
#   DIFFICULTY 0 = no balloons or daggers, 1 = Easy (default), 2 = Hard, 4 = Harder, 6 = Insane
#   INVINCIBLE 1 = Trogg can't die (for testing)
set -e
cd "$(dirname "$0")"
STEAMFRAK=${STEAMFRAK:-../steamfrak}
BEEBASM=${BEEBASM:-beebasm}
LEVEL=${LEVEL:-room_A_1}
DIFFICULTY=${DIFFICULTY:-1}
INVINCIBLE=${INVINCIBLE:-0}
python3 tools/convert.py "$STEAMFRAK" "$LEVEL"
"$BEEBASM" -D DIFFICULTY="$DIFFICULTY" -D INVINCIBLE="$INVINCIBLE" -i src/frak.asm -do build/frak.ssd -opt 3 -title FRAK \
    > build/assembler.txt
grep -v "^TIMING\|^SYMBOLS" build/assembler.txt     # (those two lines are for the test scripts)
echo "Built build/frak.ssd"
