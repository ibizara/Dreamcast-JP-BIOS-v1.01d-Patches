# Japanese Cake 1.031 Combined Patch

## Summary

This patch set is for the **Japanese Cake 1.031 retail BIOS**.

It combines:

- VMU copy-protection bypass
- Black loading swirl patch

This is documented separately from the stock Japanese Dreamcast Boot ROM v1.01d patches because the same black swirl approach is **not safe on the stock retail BIOS**. On the stock JP BIOS it displays the black swirl, but currently breaks normal disc loading.

On Japanese Cake 1.031 retail, this combined patch has been confirmed in Flycast to:

- remove VMU copy protection in the BIOS VMU manager;
- display the hidden black boot swirl;
- boot Japanese games;
- boot European/PAL games.

No Dreamcast BIOS images are included in this repository.

## BIOS Base

| Property | Value |
|---|---|
| BIOS base | Japanese Cake 1.031 retail BIOS |
| EXS configuration block | Not present |
| Region checking | Already bypassed by Japanese Cake |
| Real-hardware integrity handling | Already handled by Japanese Cake |
| VMU copy-protection bypass | Added by this patch |
| Black loading swirl | Added by this patch |

## Status

| Item | Status |
|---|---|
| VMU copy-protection bypass | Confirmed working in Flycast |
| Black loading swirl | Confirmed working in Flycast |
| Japanese game boot | Confirmed working in Flycast |
| EU/PAL game boot | Confirmed working in Flycast |
| Real hardware | Not yet confirmed by this project |

## Important Notes

This patch is intended only for **Japanese Cake 1.031 retail BIOS**.

Do **not** apply this patch to the stock Japanese Dreamcast Boot ROM v1.01d as a finished/stable black swirl patch. The same black swirl method was tested on the stock JP BIOS and currently breaks disc loading there.

The useful distinction is:

| BIOS base | VMU patch | Black swirl patch | Disc loading |
|---|---:|---:|---:|
| Stock JP v1.01d | Works | Proof of concept only | Black swirl version currently breaks disc loading |
| Japanese Cake 1.031 retail | Works | Works | JP and EU games confirmed booting in Flycast |

## Patch 1: VMU Copy-Protection Bypass

### Purpose

Removes the BIOS-side restriction that prevents copying VMU saves marked as copy-protected.

### Offset

```text
0x000188D2
```

### Original bytes

```text
14 89
```

### Patched bytes

```text
09 00
```

### Command

```bash
printf '\x09\x00' | dd of=dc_boot.bin bs=1 seek=$((0x188d2)) conv=notrunc
```

## Patch 2: Black Loading Swirl Hook

### Purpose

Redirects the factory-cache store through a small stub so the swirl selector receives the black swirl factory word.

### Offset

```text
0x0000B9B8
```

### Original bytes

```text
16 60 1C C2
```

The surrounding bytes on Japanese Cake 1.031 retail were confirmed as:

```text
0000b9b8: 16 60 1c c2 10 60 74 c0
```

### Patched bytes

```text
56 A3 16 60
```

The surrounding bytes after patching are:

```text
0000b9b8: 56 a3 16 60 10 60 74 c0
```

### Command

```bash
printf '\x56\xa3\x16\x60' | dd of=dc_boot.bin bs=1 seek=$((0x00b9b8)) conv=notrunc
```

## Patch 3: Black Loading Swirl Stub

### Purpose

Stores the black swirl factory word and then returns to the original BIOS flow.

### Offset

```text
0x0000C068
```

### Original bytes

This area was confirmed to be an empty code cave in Japanese Cake 1.031 retail:

```text
0000c068: 00 00 00 00 00 00 00 00 00 00 00 00
```

### Patched bytes

```text
01 D0 1C C2 A6 AC 09 00 30 30 33 31
```

The final four bytes are the black swirl factory word:

```text
30 30 33 31
```

### Command

```bash
printf '\x01\xd0\x1c\xc2\xa6\xac\x09\x00\x30\x30\x33\x31' \
  | dd of=dc_boot.bin bs=1 seek=$((0x00c068)) conv=notrunc
```

## Full Patch Command Sequence

```bash
# VMU copy-protection bypass
printf '\x09\x00' \
  | dd of=dc_boot.bin bs=1 seek=$((0x188d2)) conv=notrunc

# Black swirl hook
printf '\x56\xa3\x16\x60' \
  | dd of=dc_boot.bin bs=1 seek=$((0x00b9b8)) conv=notrunc

# Black swirl stub
printf '\x01\xd0\x1c\xc2\xa6\xac\x09\x00\x30\x30\x33\x31' \
  | dd of=dc_boot.bin bs=1 seek=$((0x00c068)) conv=notrunc
```

## Verification

After patching, verify the bytes:

```bash
xxd -g1 -s $((0x188d2)) -l 2 dc_boot.bin
xxd -g1 -s $((0x00b9b8)) -l 8 dc_boot.bin
xxd -g1 -s $((0x00c068)) -l 12 dc_boot.bin
```

Expected output:

```text
000188d2: 09 00
0000b9b8: 56 a3 16 60 10 60 74 c0
0000c068: 01 d0 1c c2 a6 ac 09 00 30 30 33 31
```

## Runtime Verification

Testing was performed with Flycast using the automatic flash-region override disabled.

With a Japan flash region still present, the BIOS continued to read and cache the true region byte:

```text
FLASH REGION DIRECT READ size=4 addr=a021a000 off=1a000 value=31303030 PC=8c00b9bc PR=8c00b8e4
FLASH REGION DIRECT READ size=1 addr=a021a004 off=1a004 value=30 PC=8c00b9be PR=8c00b8e4
GBR REGION WRITE disp=116 addr=8c000074 value=30 PC=8c00b9c0 PR=8c00b8e4
GBR REGION READ disp=116 addr=8c000074 value=30 PC=8c00b9da PR=8c00b8e4
```

This confirms that the true cached region byte remained Japan (`0x30`) during testing.

## Behaviour Confirmed

The patched Japanese Cake 1.031 retail BIOS was confirmed to:

- boot to the BIOS menu;
- show the black loading swirl;
- allow copying a VMU save previously blocked by copy protection;
- boot a Japanese game;
- boot a European/PAL game.

## Relationship to Stock JP BIOS v1.01d

The stock Japanese Dreamcast Boot ROM v1.01d remains useful for isolated research.

The VMU copy-protection bypass is confirmed working on stock JP v1.01d.

The black swirl patch, however, should currently be treated as a stock-BIOS proof of concept only. On stock JP v1.01d it displays the black swirl but breaks disc loading. Japanese Cake 1.031 tolerates the same black factory-word patch because its boot, region and integrity behaviour already differs from stock.
