#!/bin/bash

RED='\033[0;31m'
NC='\033[0m' # No Color

printf "=========================================================\n"
printf "${RED}Consider downloading one from - https://macosicons.com/#/${NC}\n"
printf "${RED}Or using this app - https://github.com/alptugan/icns-creator${NC}\n"
printf "=========================================================\n"

set -e

test -n "$1"
name="${1%.*}"

iconset="${name}.iconset"
rm -rf "${iconset}"
mkdir -p "${iconset}"

for s in 16 32 128 256 512; do
  d=$(($s*2))
  sips -Z $s "$1" --out "${iconset}/icon_${s}x$s.png"
  sips -Z $d "$1" --out "${iconset}/icon_${s}x$s@2x.png"
done

iconutil -c icns "${iconset}" -o "${name}.icns"
rm -r "${iconset}"
