#!/usr/bin/env bash
set -euo pipefail

file="${1:-dc_boot.bin}"

printf '\x57\xa3\x16\x60' | dd of="$file" bs=1 seek=$((0x00b9b8)) conv=notrunc
printf '\x02\xd0\x1c\xc2\xa7\xac\x09\x00\x30\x30\x33\x31' | dd of="$file" bs=1 seek=$((0x00c068)) conv=notrunc

echo "Applied Black Loading Swirl patch to $file"
