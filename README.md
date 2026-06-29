# Dreamcast JP BIOS v1.01d Patches

Repository: https://github.com/ibizara/Dreamcast-JP-BIOS-v1.01d-Patches/

Documented binary patches for the **Japanese Sega Dreamcast Boot ROM v1.01d**.

This repository is intended to document the reverse engineering work behind each patch, not simply provide unexplained byte changes. Each completed patch includes the reasoning, runtime observations, binary patch, and expected behaviour.

No BIOS images are included.

## Target BIOS

| Property | Value |
|---|---|
| BIOS | Japanese Sega Dreamcast Boot ROM v1.01d |
| Original MD5 | `e10c53c2f8b90bab96ead2d368858623` |

## Patches

| Patch | Status | Description |
|---|---:|---|
| [VMU Copy-Protection Bypass](patches/VMU-Copy-Protection-Bypass.md) | Done | Allows the BIOS VMU manager to copy saves marked as copy-protected. |
| [Black Loading Swirl](patches/Black-Loading-Swirl.md) | Done | Forces the hidden black boot swirl while preserving the console's true region. |
| [Region Lock Bypass](patches/Region-Lock-Bypass.md) | Planned | Work in progress. |

## Repository Layout

```text
README.md
Research.md
patches/
  VMU-Copy-Protection-Bypass.md
  Black-Loading-Swirl.md
  Region-Lock-Bypass.md
docs/
  Flycast-Instrumentation.md
scripts/
  apply-vmu-copy-protection-bypass.sh
  apply-black-loading-swirl.sh
```

## Patch Philosophy

The patches in this repository aim to be:

- minimal;
- individually documented;
- reproducible with standard command-line tools;
- independent where possible;
- based on observed BIOS behaviour rather than assumptions.

The notes intentionally include enough reverse engineering context to explain why each patch works and what it does **not** modify.

## Research Environment

The reverse engineering work was performed using a custom Flycast build with the SH-4 GDB server enabled, targeted instrumentation, live memory changes, binary comparison, and static disassembly.

See [Research.md](Research.md) and [Flycast Instrumentation](docs/Flycast-Instrumentation.md).

## Credits

Reverse engineering and patch development by **ibizara**.

The work used Flycast's integrated SH-4 GDB server and temporary Flycast instrumentation to observe BIOS memory access patterns.
