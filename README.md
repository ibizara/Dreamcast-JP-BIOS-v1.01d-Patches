# Dreamcast JP BIOS v1.01d Patches

Repository: https://github.com/ibizara/Dreamcast-JP-BIOS-v1.01d-Patches/

A collection of documented binary patches for the **Japanese Sega
Dreamcast Boot ROM v1.01d**.

The aim of this repository is to provide small, well-documented patches
that modify individual BIOS behaviours while leaving the remainder of
the ROM untouched.

------------------------------------------------------------------------

## Current patches

-   ✅ VMU copy-protection bypass
-   ⏳ Black loading swirl
-   ⏳ Region lock bypass

------------------------------------------------------------------------

# VMU Copy-Protection Bypass

## Summary

This patch removes the BIOS-side restriction that prevents copying VMU
saves marked as copy-protected.

Unlike game-specific hacks, this modifies the BIOS itself and therefore
applies to any title that relies on the standard BIOS VMU manager.

------------------------------------------------------------------------

## Original BIOS

  Property       Value
  -------------- ------------------------------------
  BIOS           Japanese Dreamcast Boot ROM v1.01d
  Original MD5   `e10c53c2f8b90bab96ead2d368858623`

------------------------------------------------------------------------

## Patched BIOS

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

## Credits

Reverse engineering and patch development by **ibizara**.

The VMU copy-protection behaviour was isolated through live SH-4
debugging using Flycast's integrated GDB server, followed by static
analysis of the retail Japanese v1.01d BIOS.
