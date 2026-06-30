#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  ./apply-vmu-black-swirl-jc1.031.sh <path-to-japanese-cake-1.031-bios> [--yes]

Example:
  ./apply-vmu-black-swirl-jc1.031.sh dc_boot.bin --yes

This script is intended only for Japanese Cake 1.031 retail BIOS.

It applies:
  - VMU copy-protection bypass at 0x000188D2
  - Black swirl hook at 0x0000B9B8
  - Black swirl stub at 0x0000C068

Do not use this as a finished/stable black swirl patch for the stock
Japanese Dreamcast Boot ROM v1.01d. The same black swirl method currently
breaks disc loading on the stock JP BIOS.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
    usage
    exit 0
fi

bios="$1"
yes="${2:-}"

if [[ ! -f "$bios" ]]; then
    echo "Error: file not found: $bios" >&2
    exit 1
fi

size="$(stat -c%s "$bios")"
if [[ "$size" -ne 2097152 ]]; then
    echo "Error: expected a 2 MiB Dreamcast BIOS image, got ${size} bytes." >&2
    exit 1
fi

read_hex() {
    local offset="$1"
    local length="$2"
    xxd -p -s "$offset" -l "$length" "$bios" | tr -d '\n'
}

require_one_of() {
    local name="$1"
    local actual="$2"
    shift 2
    local allowed
    for allowed in "$@"; do
        if [[ "$actual" == "$allowed" ]]; then
            return 0
        fi
    done

    echo "Error: unexpected bytes for $name: $actual" >&2
    echo "This does not look like an unpatched or already-patched Japanese Cake 1.031 target." >&2
    exit 1
}

vmu_bytes="$(read_hex $((0x188d2)) 2)"
hook_bytes="$(read_hex $((0x00b9b8)) 4)"
cave_bytes="$(read_hex $((0x00c068)) 12)"

require_one_of "VMU branch at 0x000188D2" "$vmu_bytes" \
    "1489" \
    "0900"

require_one_of "black swirl hook at 0x0000B9B8" "$hook_bytes" \
    "16601cc2" \
    "56a31660"

require_one_of "black swirl code cave at 0x0000C068" "$cave_bytes" \
    "000000000000000000000000" \
    "01d01cc2a6ac090030303331"

if [[ "$yes" != "--yes" ]]; then
    cat <<EOF
About to patch:

  $bios

This script is intended only for Japanese Cake 1.031 retail BIOS.

It will create a backup:

  ${bios}.bak

Continue? Type YES to continue:
EOF
    read -r answer
    if [[ "$answer" != "YES" ]]; then
        echo "Aborted."
        exit 1
    fi
fi

backup="${bios}.bak"
if [[ ! -f "$backup" ]]; then
    cp "$bios" "$backup"
    echo "Backup created: $backup"
else
    echo "Backup already exists, leaving it unchanged: $backup"
fi

# VMU copy-protection bypass
printf '\x09\x00' \
  | dd of="$bios" bs=1 seek=$((0x188d2)) conv=notrunc status=none

# Black swirl hook
printf '\x56\xa3\x16\x60' \
  | dd of="$bios" bs=1 seek=$((0x00b9b8)) conv=notrunc status=none

# Black swirl stub
printf '\x01\xd0\x1c\xc2\xa6\xac\x09\x00\x30\x30\x33\x31' \
  | dd of="$bios" bs=1 seek=$((0x00c068)) conv=notrunc status=none

echo
echo "Patch applied."
echo
echo "Verification:"
xxd -g1 -s $((0x188d2)) -l 2 "$bios"
xxd -g1 -s $((0x00b9b8)) -l 8 "$bios"
xxd -g1 -s $((0x00c068)) -l 12 "$bios"
echo
echo "MD5:"
md5sum "$bios"
