#!/bin/sh
# tours.sh A8JS: the checks: builds (default, STRESS, HWOUT; INVINCIBLE ones for the long walks)
# and joystick tours on each, every screen checked colour for colour (checktrogg.py), Trogg's state
# listed (state.py), the collisions checked against a reference where he can die (collcheck.py);
# and the front end's screen (frontcheck.py).
# Run from atari800xl/ after build.sh; screens in $OUT (default /tmp/tours).
set -e
A8=$1; OUT=${OUT:-/tmp/tours}; LV=${LEVEL:-A_1}
build() { sh tools/game.sh $1 -D FRONTEND=${FR:-0} $2 >/dev/null; }
tour() {   # name build script [c: the collisions checked too (not for the INVINCIBLE builds)] [level]
    TL=${5:-$LV}
    rm -rf $OUT/$1; node test/tour.mjs $A8 build/$2.xex $OUT/$1 "$3" >/dev/null
    cp build/$2.lbl build/trogg8x4.lbl.tmp; cp build/trogg8x4.lbl build/trogg8x4.lbl.keep; cp build/$2.lbl build/trogg8x4.lbl
    python3 test/checktrogg.py $OUT/$1 $TL | sed "s/^/$1: /" | tail -2 || FAIL=1
    python3 test/state.py $OUT/$1 | tail -1 | sed "s/^/$1: end /"
    [ "$4" = c ] && { LEVEL=$TL python3 test/collcheck.py $OUT/$1 | tail -1 | sed "s/^/$1: /" || FAIL=1; }
    cp build/trogg8x4.lbl.keep build/trogg8x4.lbl; rm build/trogg8x4.lbl.tmp build/trogg8x4.lbl.keep
}
FAIL=0
build t_def ""; build t_inv "-D INVINCIBLE=1"; build t_str "-D INVINCIBLE=1 -D STRESS=1"; build t_hw "-D INVINCIBLE=1 -D HWOUT=1"
build t_key "-D STARTX=280 -D STARTY=211"
GEM="30:0 100:1 50:8 50:4 100:1 200:8 100:0"            # up the F, the gem, up again, into a Scrubbly
KEY="30:0 40:4 30:0 60:8 300:0"                          # a key at once, off the edge: back at the checkpoint
YOYO="30:0 100:1 50:8 50:4 100:1 20:8 60:0:1 60:0 150:8 100:0"   # up the F, the yoyo at its Scrubbly, through where it was
WALK="100:1 60:8 30:9 60:8 40:10 100:8 60:9 200:8 60:6 200:8 80:5 200:8 100:4 200:8"   # across the level, jumping
build t_l2 "-D LSTART=1"; build t_l3 "-D LSTART=2"
LWALK="60:0 200:8 60:9 100:8 100:0 200:4 60:5 200:4 100:0 300:8"     # (A_2, A_3: about the start)
tour l2 t_l2 "$LWALK" c A_2; tour l3 t_l3 "$LWALK" c A_3
python3 test/lvlcheck.py $OUT/l2 build/t_l2.lbl A_2 | sed "s/^/l2: /" || FAIL=1   # (the levels' blocks as
python3 test/lvlcheck.py $OUT/l3 build/t_l3.lbl A_3 | sed "s/^/l3: /" || FAIL=1   #  lvderive leaves them)
tour gem t_def "$GEM" c; tour key t_key "$KEY" c
python3 test/lvlcheck.py $OUT/gem build/t_def.lbl A_1 | sed "s/^/gem: /" || FAIL=1
 tour yoyo t_def "$YOYO" c; tour walk t_inv "$WALK"; tour stress t_str "$WALK"; tour hwout t_hw "$WALK"
# the front end (a FRONTEND build): its screen, colour for colour, while it's up
FR=1 build t_fe ""
rm -rf $OUT/front; node test/tour.mjs $A8 build/t_fe.xex $OUT/front "100:0" >/dev/null
cp build/trogg8x4.lbl build/trogg8x4.lbl.keep; cp build/t_fe.lbl build/trogg8x4.lbl
python3 test/frontcheck.py $OUT/front | sed "s/^/front: /" || FAIL=1
cp build/trogg8x4.lbl.keep build/trogg8x4.lbl; rm build/trogg8x4.lbl.keep
exit $FAIL
