# Packs a file with the BBC version's packer (../../tools/pack.py: LZ77 with interleaved Elias
# gamma lengths; unpacked on the C64 by unpack, loader.asm), checking it unpacks back.
#   python3 lz.py IN OUT
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'tools'))
from pack import compress, decompress
data = open(sys.argv[1], 'rb').read()
packed = compress(data)
if decompress(packed) != data: sys.exit(f'{sys.argv[1]}: does not unpack back')
open(sys.argv[2], 'wb').write(packed)
