# VMU Copy-Protection Bypass

## Summary

This patch removes the BIOS-side restriction that prevents copying VMU saves marked as copy-protected.

Unlike a game-specific patch, this modifies the BIOS VMU manager itself. It therefore applies to saves handled through the standard Dreamcast BIOS file manager.

## Target BIOS

| Property | Value |
|---|---|
| BIOS | Japanese Dreamcast Boot ROM v1.01d |
| Original MD5 | `e10c53c2f8b90bab96ead2d368858623` |

## Patched BIOS

| Patch set | MD5 |
|---|---|
| VMU Copy-Protection Bypass only | `5ec7afd8d21469aa1debc840d34ce1f1` |

## Binary Patch

Offset:

```text
0x000188D2
```

Original bytes:

```text
14 89
```

Patched bytes:

```text
09 00
```

Equivalent command:

```bash
printf '\x09\x00' | dd of=dc_boot.bin bs=1 seek=$((0x188d2)) conv=notrunc
```

## What Changes

The original BIOS checks whether a VMU save is marked copy-protected and refuses the copy operation if the flag is `0xFF`.

The patch replaces the conditional branch with a NOP so execution continues normally.

## Reverse Engineering Notes

During runtime the BIOS constructs an internal table describing each VMU save.

For SoulCalibur, the relevant table entry contained:

```text
Offset +0x20 = 00
Offset +0x21 = 03
Offset +0x22 = 00
Offset +0x23 = FF   <- copy-protection flag
Offset +0x24 = 00
```

Changing only the copy-protection flag in RAM immediately allowed the save to be copied:

```gdb
set {unsigned char}0x8c390e23 = 0x00
```

This demonstrated that byte `+0x23` is the BIOS copy-protection flag.

The BIOS later performs this check:

```asm
mov.b   @(0x33,r3),r2
mov.w   #0x00ff,r3
extu.b  r2,r2
cmp/eq  r3,r2
bt      0x8c0188fe
```

Equivalent logic:

```c
if (entry->copyProtect == 0xFF)
    reject_copy_operation();
```

The patch changes the branch instruction to a NOP:

```text
14 89 -> 09 00
```

## Behaviour

The patch:

- preserves the VMU directory entry;
- preserves the save file contents;
- preserves the copy-protection flag in memory;
- does not modify the VMU filesystem;
- removes only the BIOS policy decision that refuses the copy.

The BIOS may still recognise the save as protected; it simply no longer refuses the copy operation.

## Related Notes

See:

- [Research Notes](../Research.md)
- [Flycast Instrumentation](../docs/Flycast-Instrumentation.md)
