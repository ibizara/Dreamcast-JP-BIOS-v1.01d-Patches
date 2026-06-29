# Dreamcast JP BIOS v1.01d Patches

Repository: https://github.com/ibizara/Dreamcast-JP-BIOS-v1.01d-Patches/

A collection of documented binary patches for the **Japanese Sega
Dreamcast Boot ROM v1.01d**.

## Original BIOS

  Property       Value
  -------------- ------------------------------------
  BIOS           Japanese Dreamcast Boot ROM v1.01d
  Original MD5   `e10c53c2f8b90bab96ead2d368858623`

The aim of this repository is to provide small, well-documented patches
that modify individual BIOS behaviours while leaving the remainder of
the ROM untouched.

------------------------------------------------------------------------

## Current patches

-   ✅ VMU copy-protection bypass
-   ✅ Black loading swirl
-   ⏳ Region lock bypass

------------------------------------------------------------------------

# VMU Copy-Protection Bypass

## Summary

This patch removes the BIOS-side restriction that prevents copying VMU
saves marked as copy-protected.

Unlike game-specific hacks, this modifies the BIOS itself and therefore
applies to any title that relies on the standard BIOS VMU manager.

------------------------------------------------------------------------

## Patched BIOS VMU Copy-Protection Bypass only

  Property   Value
  ---------- ------------------------------------
  MD5        `5ec7afd8d21469aa1debc840d34ce1f1`

------------------------------------------------------------------------

## Binary Patch

Offset:

``` text
0x000188D2
```

Original bytes:

``` text
14 89
```

Patched bytes:

``` text
09 00
```

Equivalent command:

``` bash
printf '\x09\x00' | dd of=dc_boot.bin bs=1 seek=$((0x188d2)) conv=notrunc
```

------------------------------------------------------------------------

## Reverse Engineering Notes

During runtime the BIOS constructs an internal table describing each VMU
save.

For SoulCalibur the relevant structure contains:

``` text
Offset +0x20 = 00
Offset +0x21 = 03
Offset +0x22 = 00
Offset +0x23 = FF   ← Copy-protection flag
Offset +0x24 = 00
```

Changing only:

``` gdb
set {unsigned char}0x8c390e23 = 0x00
```

immediately enables copying, demonstrating that byte `+0x23` is the
protection flag.

The BIOS later performs the following check:

``` asm
mov.b   @(0x33,r3),r2
mov.w   #0x00ff,r3
extu.b  r2,r2
cmp/eq  r3,r2
bt      0x8c0188fe
```

This is equivalent to:

``` c
if (entry->copyProtect == 0xFF)
    reject_copy_operation();
```

Replacing the conditional branch (`BT`) with a `NOP` causes the BIOS to
continue normally regardless of the flag.

------------------------------------------------------------------------

## Behaviour

The patch:

-   Preserves the VMU directory entry.
-   Preserves the copy-protection flag in memory.
-   Does **not** modify save data.
-   Does **not** modify the VMU filesystem.
-   Simply removes the BIOS policy decision that prevents copying
    protected saves.

In other words, the BIOS still recognises the file as protected---it
simply no longer refuses the copy operation.

------------------------------------------------------------------------

## Black Loading Swirl

The BIOS normally derives the swirl from the factory region stored in
flash.

  Byte   Region     Swirl
  ------ ---------- -------
  0x30   Japan      Red
  0x31   USA        Red
  0x32   Europe     Blue
  0x33   Reserved   Black

Flash-only method:

``` bash
printf '\x30' | dd of=dc_nvmem.bin bs=1 seek=$((0x1a002)) conv=notrunc
printf '\x30' | dd of=dc_nvmem.bin bs=1 seek=$((0x1a0a2)) conv=notrunc
# 0x31 USA, 0x32 Europe, 0x33 Black (same offsets)
```

The repository patch instead leaves flash untouched and patches only the
swirl-selection path so the console still reports its genuine region
while always displaying the black swirl.

### BIOS patch

Offset **0x0000B9B8**

Original:

``` text
00 E0 4E D1
```

Patched:

``` text
57 A3 16 60
```

Install:

``` bash
printf '\x57\xa3\x16\x60' | dd of=dc_boot.bin bs=1 seek=$((0x00b9b8)) conv=notrunc
```

Stub at **0x0000C068**:

``` text
02 D0 1C C2 A7 AC 09 00 30 30 33 31
```

``` bash
printf '\x02\xd0\x1c\xc2\xa7\xac\x09\x00\x30\x30\x33\x31' | dd of=dc_boot.bin bs=1 seek=$((0x00c068)) conv=notrunc
```

## Patched BIOS Black Loading Swirl only

  Property   Value
  ---------- ------------------------------------
  MD5        `0cb7c3e7bcde48f9584ceb995a96caee`

Reverse engineering confirmed the true region byte is still read from
flash and cached in GBR+0x74; only the swirl-selection routine is
overridden.

## Credits

Reverse engineering and patch development by **ibizara**.

The VMU copy-protection behaviour was isolated through live SH-4
debugging using Flycast's integrated GDB server, followed by static
analysis of the retail Japanese v1.01d BIOS.
