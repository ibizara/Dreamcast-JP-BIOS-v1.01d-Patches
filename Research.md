# Research Notes

This document describes the general reverse engineering method used to create the BIOS patches in this repository.

Patch-specific details are kept in the individual patch documents.

## Target BIOS

| Property | Value |
|---|---|
| BIOS | Japanese Sega Dreamcast Boot ROM v1.01d |
| Original MD5 | `e10c53c2f8b90bab96ead2d368858623` |

## Environment

A custom Flycast build was used with the integrated SH-4 GDB server enabled:

```bash
cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_GDB_SERVER=ON ..
```

The investigation used:

- Flycast SH-4 GDB server;
- live GDB breakpoints and memory edits;
- temporary Flycast instrumentation;
- BIOS disassembly;
- binary comparison;
- targeted runtime logging.

## Emulator Region Override

For region and swirl research it was essential that Flycast did not overwrite the Dreamcast flash region values during startup.

Flycast normally updates the factory flash settings from its own configuration. For testing, the region override was temporarily commented out:

```cpp
// overwrite factory flash settings
if (config::Region <= 2)
{
    //sys_nvmem->data[0x1a002] = '0' + config::Region;
    //sys_nvmem->data[0x1a0a2] = '0' + config::Region;
}
```

This allowed the BIOS to read the actual flash contents under test.

## Useful Runtime Logs

The most useful logging was narrowly targeted so the output remained readable:

- direct flash reads near the Dreamcast factory settings block;
- writes to the cached BIOS region byte;
- reads from the cached BIOS region byte;
- VMU copy-protection table reads during copy checks.

Example from the black swirl investigation:

```text
FLASH REGION DIRECT READ size=4 addr=a021a000 off=1a000 value=31303030 PC=8c00b9bc PR=8c00b8e4
FLASH REGION DIRECT READ size=1 addr=a021a004 off=1a004 value=30 PC=8c00b9be PR=8c00b8e4
GBR REGION WRITE disp=116 addr=8c000074 value=30 PC=8c00b9c0 PR=8c00b8e4
FLASH REGION DIRECT READ size=2 addr=a021a056 off=1a056 value=a659 PC=8c00b9c4 PR=8c00b8e4
FLASH REGION DIRECT READ size=2 addr=a021a058 off=1a058 value=3957 PC=8c00b9c8 PR=8c00b8e4
FLASH REGION DIRECT READ size=2 addr=a021a05a off=1a05a value=36c5 PC=8c00b9cc PR=8c00b8e4
FLASH REGION DIRECT READ size=2 addr=a021a05c off=1a05c value=0912 PC=8c00b9d0 PR=8c00b8e4
GBR REGION READ disp=116 addr=8c000074 value=30 PC=8c00b9da PR=8c00b8e4
```

This proved that the true region byte was still being read from flash and cached in `GBR+0x74`, even when the black swirl patch was active.

## Notes on Dead Ends

Some approaches were tested and rejected, including:

- forcing values with GDB too late in the boot process;
- modifying `dc_nvmem.bin` directly;
- copying Japanese Cake flash configuration blocks into stock BIOS flash;
- attempting to treat Japanese Cake's `EXS` settings block as native stock BIOS behaviour.

These helped rule out unsafe or misleading approaches. The final patches avoid changing the flash and instead patch the relevant BIOS decision point directly.
