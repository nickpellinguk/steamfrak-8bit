#!/bin/sh
# Fetch the Enterprise's ROMs for the test harness: ep128emu's ROM package (as its installer
# downloads it, from ep128.hu), unpacked with build/unpackroms (tools/ephl/build.sh builds it),
# and EXOS 2.1 and EXDOS 1.3 put where the harness looks for them, named as MAME names them:
#
#   tools/ephl/getroms.sh DIRECTORY      (then EP_ROMS=DIRECTORY)
#
# (ep128emu's copies aren't the dumps MAME lists, so MAME warns that their checksums are wrong,
# and runs them anyway.)
set -e
cd "$(dirname "$0")/../.."
DIR=${1:?usage: tools/ephl/getroms.sh DIRECTORY}
[ -x build/unpackroms ] || tools/ephl/build.sh
mkdir -p build/roms "$DIR/ep128" "$DIR/ep64_exdos"
[ -f build/roms/ep128emu_roms-2.0.11.bin ] ||
    curl -sSfL -o build/roms/ep128emu_roms-2.0.11.bin https://ep128.hu/Emu/ep128emu_roms-2.0.11.bin
build/unpackroms build/roms/ep128emu_roms-2.0.11.bin build/roms > /dev/null
cp build/roms/exos21.rom "$DIR/ep128/9256ds-0019_enter08-45-a.u2"
cp build/roms/exdos13.rom "$DIR/ep64_exdos/exdos13.rom"
# ... and for the disk's test (disk.mjs: ep128emu's own Enterprise 128 with EXDOS): EXOS 2.1, the
# BASIC 2.1 cartridge, and EXDOS 1.4
mkdir -p "$DIR/ep128emu"
cp build/roms/exos21.rom build/roms/basic21.rom build/roms/exdos14isdos10uk.rom "$DIR/ep128emu/"
python3 -c "import sys, zlib
for f, crc in (('ep128/9256ds-0019_enter08-45-a.u2', 0x34284877), ('ep64_exdos/exdos13.rom', 0xe0135929)):
    if zlib.crc32(open(sys.argv[1] + '/' + f, 'rb').read()) != crc: sys.exit(f + ': not the ROM expected')" "$DIR"
echo "The ROMs are in $DIR"
