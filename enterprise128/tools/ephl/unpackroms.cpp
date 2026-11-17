// unpackroms: unpack ep128emu's ROM package (ep128emu_roms-2.0.11.bin, as its installer
// downloads it from ep128.hu) into a directory, as the installer does: the package is compressed
// with ep128emu's own compressor, and holds a count of files, a 32-byte entry for each (its size,
// then its name), then the files.
//
//   unpackroms PACKAGE DIRECTORY
//
// This file is under the GNU General Public License, version 2 or later, as ep128emu is.

#include "ep128emu.hpp"
#include "decompm2.hpp"

#include <cstdio>
#include <fstream>
#include <iostream>
#include <iterator>
#include <string>
#include <vector>

int main(int argc, char **argv) {
  if (argc != 3) { std::cerr << "usage: unpackroms PACKAGE DIRECTORY\n"; return 2; }
  std::ifstream in(argv[1], std::ios::binary);
  std::vector<unsigned char> packed((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
  if (packed.size() < 4) { std::cerr << "unpackroms: can't read " << argv[1] << "\n"; return 1; }
  std::vector<unsigned char> buf;
  try {
    Ep128Emu::decompressData(buf, &packed.front(), packed.size());
  }
  catch (std::exception& e) { std::cerr << "unpackroms: " << e.what() << "\n"; return 1; }
  size_t n = (size_t(buf[0]) << 24) | (size_t(buf[1]) << 16) | (size_t(buf[2]) << 8) | buf[3];
  size_t offs = 4 + n * 32;
  for (size_t i = 0; i < n; i++) {
    const unsigned char *e = &buf[4 + i * 32];
    size_t size = (size_t(e[0]) << 24) | (size_t(e[1]) << 16) | (size_t(e[2]) << 8) | e[3];
    std::string name;
    for (int j = 0; j < 28 && e[4 + j]; j++) {
      char c = char(e[4 + j]);
      if (c >= 'A' && c <= 'Z') c = char(c | 0x20);
      name += c;
    }
    if (offs + size > buf.size() || name.empty() || name.find('/') != std::string::npos) {
      std::cerr << "unpackroms: the package is damaged\n"; return 1;
    }
    std::ofstream(std::string(argv[2]) + "/" + name, std::ios::binary)
        .write(reinterpret_cast<const char *>(&buf[offs]), std::streamsize(size));
    std::cout << name << " " << size << "\n";
    offs += size;
  }
  return 0;
}
