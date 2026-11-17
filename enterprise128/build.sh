#!/bin/sh
# Build the Enterprise 128 version: build/frak.img (an EXDOS disk image holding
# build/FRAK.COM), and build/frak.sym (its symbols, for the test harness in tools/emu).
#
#   RASM=/path/to/rasm ./build.sh
#
# tools/memmap.py measures the memory map from the CPC version first (src/gen/sizes.asm,
# and the front end and level loader, packed, in build/), so the BBC version must be built
# first (../build.sh), as for the CPC version.
#
# RASM is Edouard Berge's assembler (https://github.com/EdouardBERGE/rasm), as for
# the CPC version: gcc -O2 -DNO_3RD_PARTIES -o rasm rasm.c -lm
set -e
cd "$(dirname "$0")"
RASM=${RASM:-rasm}
mkdir -p build
# (measured again only when the CPC version or the packer have changed)
if [ ! -f src/gen/sizes.asm ] || [ -n "$(find ../cpc6128/src ../tools/pack.py tools/memmap.py -newer src/gen/sizes.asm)" ]; then
    RASM="$RASM" python3 tools/memmap.py > build/memmap.txt || { cat build/memmap.txt; exit 1; }
fi
# Two passes: the first assembles the front end (build/FRONT.BIN) for the BBC version's packer
# to pack (build/FRONT.lz), the second puts it, packed, in segment #FF's file (build/TOP.BIN)
"$RASM" src/frak.asm -DPASS=1 -eo > build/pass1.txt || { cat build/pass1.txt; exit 1; }
python3 -c "
import importlib.util, sys
spec = importlib.util.spec_from_file_location('pack', '../tools/pack.py'); pack = importlib.util.module_from_spec(spec); spec.loader.exec_module(pack)
data = open('build/FRONT.BIN', 'rb').read(); lz = pack.compress(data)
assert pack.decompress(lz) == data
open('build/FRONT.lz', 'wb').write(lz)
print('Front end packed:', len(data), '->', len(lz), 'bytes')"
"$RASM" src/frak.asm -DPASS=2 -s -sa -os build/frak.sym -eo
python3 tools/mkdisk.py build/frak.img build/FRAK.COM
echo "Built build/frak.img"
