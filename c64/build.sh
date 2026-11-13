#!/bin/sh
# Build the C64 demo: build/frak64.prg (LOAD and RUN it), and stand-in ROMs for testing it in a
# VICE that hasn't Commodore's (see tools/build.mjs). With --run, also runs it in VICE and takes a
# screenshot (build/shot.png); tools/compare.py checks one against the mock-up.
#
#   ./build.sh [--run]
#
# Needs node and 64tass (https://sourceforge.net/projects/tass64/); --run needs VICE's x64sc and
# xvfb-run. The level comes from the BBC version's converter and its images through the CPC
# port's graphics converter: run ../build.sh first.
set -e
cd "$(dirname "$0")"
if [ ! -f ../build/levels.json ]; then
    echo "Build the BBC version first (../build.sh): this uses its levels and graphics" >&2
    exit 1
fi
if [ ! -f ../cpc6128/build/images.json ]; then
    (cd ../cpc6128 && mkdir -p build && python3 tools/gfx.py)
fi
node tools/mockup.mjs > /dev/null
OFF=1 node tools/mockup.mjs > /dev/null      # (the Scrubblies yo-yoed off: their glyphs packed too)
GONE=1 node tools/mockup.mjs > /dev/null     # (the gems and keys picked up: likewise)
node tools/build.mjs "$@"
