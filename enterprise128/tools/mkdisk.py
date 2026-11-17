#!/usr/bin/env python3
"""Make an EXDOS disk image: a 720K double-sided, double-density disk with an MS-DOS (FAT12)
file system, which is the format EXDOS reads and writes.

    mkdisk.py IMAGE FILE...

The files go in the root directory under their own names, which must be 8.3 names.
"""
import os
import sys

SECTOR = 512
SECTORS = 1440                  # 80 tracks, 2 sides, 9 sectors a track
PER_CLUSTER = 2
RESERVED = 1
FATS = 2
FAT_SECTORS = 3
ROOT_ENTRIES = 112
MEDIA = 0xF9

def boot_sector():
    b = bytearray(SECTOR)
    b[0:3] = b'\xEB\x3C\x90'
    b[3:11] = b'EXDOS   '
    b[11:13] = SECTOR.to_bytes(2, 'little')
    b[13] = PER_CLUSTER
    b[14:16] = RESERVED.to_bytes(2, 'little')
    b[16] = FATS
    b[17:19] = ROOT_ENTRIES.to_bytes(2, 'little')
    b[19:21] = SECTORS.to_bytes(2, 'little')
    b[21] = MEDIA
    b[22:24] = FAT_SECTORS.to_bytes(2, 'little')
    b[24:26] = (9).to_bytes(2, 'little')        # sectors a track
    b[26:28] = (2).to_bytes(2, 'little')        # sides
    b[510:512] = b'\x55\xAA'
    return b

def name83(path):
    base = os.path.basename(path).upper()
    stem, _, ext = base.partition('.')
    if not (1 <= len(stem) <= 8 and len(ext) <= 3):
        raise SystemExit(f'{base} is not an 8.3 name')
    return stem.ljust(8).encode('ascii') + ext.ljust(3).encode('ascii')

def make(image, files):
    root_sectors = ROOT_ENTRIES * 32 // SECTOR
    data_start = RESERVED + FATS * FAT_SECTORS + root_sectors
    clusters = (SECTORS - data_start) // PER_CLUSTER
    disk = bytearray(SECTORS * SECTOR)
    disk[0:SECTOR] = boot_sector()
    fat = [0] * (clusters + 2)
    fat[0], fat[1] = 0xF00 | MEDIA, 0xFFF
    root = bytearray(root_sectors * SECTOR)
    nxt = 2
    for i, path in enumerate(files):
        data = open(path, 'rb').read()
        need = max(1, -(-len(data) // (SECTOR * PER_CLUSTER)))
        if nxt + need > clusters + 2:
            raise SystemExit('the disk is full')
        first = nxt
        for k in range(need):
            fat[nxt + k] = nxt + k + 1 if k < need - 1 else 0xFFF
        pos = (data_start + (first - 2) * PER_CLUSTER) * SECTOR
        disk[pos:pos + len(data)] = data
        nxt += need
        e = bytearray(32)
        e[0:11] = name83(path)
        e[11] = 0x20                            # archive
        e[24:26] = ((1985 - 1980) << 9 | 1 << 5 | 1).to_bytes(2, 'little')   # 1 January 1985
        e[26:28] = (first if data else 0).to_bytes(2, 'little')
        e[28:32] = len(data).to_bytes(4, 'little')
        root[i * 32:(i + 1) * 32] = e
    packed = bytearray(FAT_SECTORS * SECTOR)
    for n in range(0, len(fat) - 1, 2):
        a, b = fat[n], fat[n + 1]
        packed[n * 3 // 2:n * 3 // 2 + 3] = bytes([a & 255, (a >> 8) | ((b & 15) << 4), b >> 4])
    for f in range(FATS):
        pos = (RESERVED + f * FAT_SECTORS) * SECTOR
        disk[pos:pos + len(packed)] = packed
    pos = (RESERVED + FATS * FAT_SECTORS) * SECTOR
    disk[pos:pos + len(root)] = root
    open(image, 'wb').write(disk)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    make(sys.argv[1], sys.argv[2:])
