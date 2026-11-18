#!/bin/sh
# Fetch vecx (a Vectrex emulator, GPL v3) at a fixed commit, add beam.patch (it reports how long
# the beam took over each line) and build beamshot, which runs it without a window and writes
# down the lines it draws. The result is in vectrex/emu/vecx/ (not part of this repository).
set -e
cd "$(dirname "$0")"
VECX_COMMIT=9b2894cacf73bdacaba32cb505289c658d981fd9
if [ ! -d vecx ]; then
	git clone -q https://github.com/jhawthorn/vecx vecx
	git -C vecx checkout -q "$VECX_COMMIT"
	git -C vecx apply ../beam.patch
fi
${CC:-cc} -O2 -Wall -I vecx -o vecx/beamshot beamshot.c vecx/vecx.c vecx/e6809.c
echo "built vectrex/emu/vecx/beamshot (BIOS: vectrex/emu/vecx/rom.dat)"
