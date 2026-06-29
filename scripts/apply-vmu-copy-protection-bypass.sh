#!/usr/bin/env bash
set -euo pipefail

file="${1:-dc_boot.bin}"

printf '\x09\x00' | dd of="$file" bs=1 seek=$((0x188d2)) conv=notrunc
echo "Applied VMU Copy-Protection Bypass to $file"
