# Black Loading Swirl

## Summary

This patch forces the hidden black Dreamcast boot swirl while preserving the console's true hardware region.

The final patch is BIOS-only. It does **not** require modifying `dc_nvmem.bin` or changing the machine's flash region.

## Target BIOS

| Property | Value |
|---|---|
| BIOS | Japanese Dreamcast Boot ROM v1.01d |
| Original MD5 | `e10c53c2f8b90bab96ead2d368858623` |

## Patched BIOS

| Patch set | MD5 |
|---|---|
| Black Loading Swirl only | `0cb7c3e7bcde48f9584ceb995a96caee` |

## Flash Region Discovery

The BIOS normally derives the swirl colour from the factory region stored in flash.

The tested mapping is:

| Flash byte | Region | Swirl |
|---:|---|---|
| `0x30` | Japan | Red |
| `0x31` | USA | Red |
| `0x32` | Europe | Blue |
| `0x33` | Reserved / invalid | Black |

The flash-only method is:

```bash
# Japan / red
printf '\x30' | dd of=dc_nvmem.bin bs=1 seek=$((0x1a002)) conv=notrunc
printf '\x30' | dd of=dc_nvmem.bin bs=1 seek=$((0x1a0a2)) conv=notrunc

# USA / red
printf '\x31' | dd of=dc_nvmem.bin bs=1 seek=$((0x1a002)) conv=notrunc
printf '\x31' | dd of=dc_nvmem.bin bs=1 seek=$((0x1a0a2)) conv=notrunc

# Europe / blue
printf '\x32' | dd of=dc_nvmem.bin bs=1 seek=$((0x1a002)) conv=notrunc
printf '\x32' | dd of=dc_nvmem.bin bs=1 seek=$((0x1a0a2)) conv=notrunc

# Reserved / black
printf '\x33' | dd of=dc_nvmem.bin bs=1 seek=$((0x1a002)) conv=notrunc
printf '\x33' | dd of=dc_nvmem.bin bs=1 seek=$((0x1a0a2)) conv=notrunc
```

This was useful for research but is **not** the final solution, because changing flash also changes the console's reported region.

## BIOS-Only Patch

The BIOS patch intercepts only the swirl-selection path and feeds it the black swirl value (`0x33`), while allowing the BIOS to continue reading and caching the real flash region.

### Patch 1

Offset:

```text
0x0000B9B8
```

Original bytes:

```text
00 E0 4E D1
```

Patched bytes:

```text
57 A3 16 60
```

Command:

```bash
printf '\x57\xa3\x16\x60' | dd of=dc_boot.bin bs=1 seek=$((0x00b9b8)) conv=notrunc
```

### Patch 2: Stub

Offset:

```text
0x0000C068
```

Bytes:

```text
02 D0 1C C2 A7 AC 09 00 30 30 33 31
```

Command:

```bash
printf '\x02\xd0\x1c\xc2\xa7\xac\x09\x00\x30\x30\x33\x31' | dd of=dc_boot.bin bs=1 seek=$((0x00c068)) conv=notrunc
```

## Verification

With a Japanese flash region still present, runtime logging showed:

```text
FLASH REGION DIRECT READ size=4 addr=a021a000 off=1a000 value=31303030 PC=8c00b9bc PR=8c00b8e4
FLASH REGION DIRECT READ size=1 addr=a021a004 off=1a004 value=30 PC=8c00b9be PR=8c00b8e4
GBR REGION WRITE disp=116 addr=8c000074 value=30 PC=8c00b9c0 PR=8c00b8e4
GBR REGION READ disp=116 addr=8c000074 value=30 PC=8c00b9da PR=8c00b8e4
```

This confirms that the true region byte remains `0x30` and is still cached at `GBR+0x74`.

Only the swirl selection is overridden.

## Behaviour

The patch:

- shows the black boot swirl;
- does not modify flash;
- does not require `dc_nvmem.bin` changes;
- preserves the actual console region;
- avoids Japanese Cake's configurable `EXS` flash settings system;
- keeps the patch local to the boot-animation path.

## Notes

Japanese Cake BIOS can also display a black swirl, but it stores configuration in an `EXS` block in flash. Stock BIOS does not understand that block. For this project, the goal was a minimal stock BIOS patch that always displays the black swirl without adding a flash configuration system.

## Related Notes

See:

- [Research Notes](../Research.md)
- [Flycast Instrumentation](../docs/Flycast-Instrumentation.md)
