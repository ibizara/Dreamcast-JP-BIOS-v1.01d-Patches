# Flycast Instrumentation

Temporary Flycast modifications were used during reverse engineering. These were research tools only and are not required to use the final BIOS patches.

## Build

Flycast was built with the SH-4 GDB server enabled:

```bash
cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_GDB_SERVER=ON ..
```

## Disable Automatic Region Override

For flash-region research, Flycast's region override was temporarily disabled:

```cpp
// overwrite factory flash settings
if (config::Region <= 2)
{
    //sys_nvmem->data[0x1a002] = '0' + config::Region;
    //sys_nvmem->data[0x1a0a2] = '0' + config::Region;
}
```

Without this change, Flycast could rewrite the test flash region before the BIOS read it.

## Flash Region Logging

Direct reads around the factory settings block were logged.

The useful range was around:

```text
0xa021a000..0xa021a0ff
```

The most important read was the 32-bit value at `0xa021a000`, which contains the byte at flash offset `0x1a002` used for the swirl-region selector.

Example:

```text
FLASH REGION DIRECT READ size=4 addr=a021a000 off=1a000 value=31303030 PC=8c00b9bc PR=8c00b8e4
```

Changing flash byte `0x1a002` produced:

| Flash byte | 32-bit logged value | Result |
|---:|---|---|
| `0x30` | `31303030` | Red swirl |
| `0x31` | `31313030` | Red swirl |
| `0x32` | `31323030` | Blue swirl |
| `0x33` | `31333030` | Black swirl |

## Cached Region Logging

The BIOS caches the true region byte at `GBR+0x74`.

Useful events:

```text
GBR REGION WRITE disp=116 addr=8c000074 value=30 PC=8c00b9c0 PR=8c00b8e4
GBR REGION READ  disp=116 addr=8c000074 value=30 PC=8c00b9da PR=8c00b8e4
```

This confirmed that the black swirl BIOS patch preserves the true region byte.

## VMU Investigation Logging

For the VMU copy-protection patch, live GDB inspection and targeted logging were used to isolate the byte controlling copy permission.

The key finding was that a value of `0xFF` at offset `+0x23` in the BIOS' internal VMU save table marks a save as copy-protected.

Changing only that byte in RAM immediately enabled copying:

```gdb
set {unsigned char}0x8c390e23 = 0x00
```

That confirmed the protection flag before the final BIOS branch patch was made.
