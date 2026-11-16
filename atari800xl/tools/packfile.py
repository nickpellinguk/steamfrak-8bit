# packfile.py IN OUT: IN packed with the BBC version's packer (../tools/pack.py), unchanged data's
# packing kept (OUT.src): packing's slow
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'tools'))
from pack import compress, decompress
data, out = open(sys.argv[1], 'rb').read(), sys.argv[2]
if not (os.path.exists(out) and os.path.exists(out + '.src') and open(out + '.src', 'rb').read() == data):
    z = compress(data); assert decompress(z) == data
    open(out, 'wb').write(z); open(out + '.src', 'wb').write(data)
print(f'{os.path.basename(sys.argv[1])}: {len(data)} bytes packed in {os.path.getsize(out)}')
