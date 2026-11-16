#!/bin/sh
# game.sh OUT [64tass options]: build/OUT.xex (and OUT.lbl), the game with its overlay: the program
# assembled (with the last overlay, or none: it's the program's last, so nothing resident moves),
# then the overlay against its labels (overlay.asm), packed, then the program again with it; the
# labels checked the same. Run from atari800xl/.
set -e
OUT=$1; shift
B=../build
cd src
[ -f $B/$OUT.ovl.lz ] || : > $B/$OUT.ovl.lz
64tass --atari-xex -q "$@" -D OVFILE=\"$B/$OUT.ovl.lz\" trogg8x4.asm -o $B/$OUT.xex --labels=$B/$OUT.lbl
64tass -b -q -D LBLFILE=\"$B/$OUT.lbl\" overlay.asm -o $B/$OUT.ovl --labels=$B/$OUT.ovl.lbl
python3 ../tools/packfile.py $B/$OUT.ovl $B/$OUT.ovl.lz
grep -v "^ovlz\b" $B/$OUT.lbl | sort > $B/$OUT.lbl.1
64tass --atari-xex -q "$@" -D OVFILE=\"$B/$OUT.ovl.lz\" trogg8x4.asm -o $B/$OUT.xex --labels=$B/$OUT.lbl
grep -v "^ovlz\b" $B/$OUT.lbl | sort | cmp -s - $B/$OUT.lbl.1 || { echo "game.sh: the program's labels moved"; exit 1; }
cat $B/$OUT.ovl.lbl >> $B/$OUT.lbl         # (the overlay's too, for the checks)
rm $B/$OUT.lbl.1
