# Setting Fast Boot as Default Option for GDMENUCardManager v1.5.5

This guide documents how to modify the bundled openMenu build used by **GDMENUCardManager v1.5.5** so that the default boot mode is **Fast Boot**, meaning both the Dreamcast boot animation and Sega licence screen are disabled by default.

## 1. Clone the source repository

Clone the openMenu Virtual Folder Bundle source repository:

```bash
cd ~/Git
git clone https://github.com/DerekPascarella/openMenu-Virtual-Folder-Bundle.git
cd openMenu-Virtual-Folder-Bundle
```

If the repository has already been cloned, just enter the existing folder:

```bash
cd ~/Git/openMenu-Virtual-Folder-Bundle
```

## 3. Locate the openMenu source

Start from the root of the bundle source tree:

```bash
cd ~/Git/openMenu-Virtual-Folder-Bundle
```

Search for the existing boot mode setting:

```bash
grep -ri sf_boot_mode
```

The important files are:

```text
openMenu/src/openmenu_settings/src/openmenu_settings.c
openMenu/src/openmenu_settings/src/openmenu_savefile.c
openMenu/src/openmenu_settings/include/openmenu_settings.h
openMenu/src/openmenu/src/backend/gdemu_control.c
```

## 3. Understand the boot mode values

The boot modes are defined in:

```text
openMenu/src/openmenu_settings/include/openmenu_settings.h
```

The relevant enum is:

```c
typedef enum CFG_BOOT_MODE {
    BOOT_MODE_START = 0,
    BOOT_MODE_FULL = BOOT_MODE_START, // boot_intro=1, sega_license=1
    BOOT_MODE_LICENSE,                // boot_intro=0, sega_license=1
    BOOT_MODE_ANIMATION,              // boot_intro=1, sega_license=0
    BOOT_MODE_FAST,                   // boot_intro=0, sega_license=0
    BOOT_MODE_END = BOOT_MODE_FAST
} CFG_BOOT_MODE;
```

The behaviour is applied in:

```text
openMenu/src/openmenu/src/backend/gdemu_control.c
```

```c
param.boot_intro = (sf_boot_mode[0] == BOOT_MODE_FULL || sf_boot_mode[0] == BOOT_MODE_ANIMATION) ? 1 : 0;
param.sega_license = (sf_boot_mode[0] == BOOT_MODE_FULL || sf_boot_mode[0] == BOOT_MODE_LICENSE) ? 1 : 0;
```

So setting the default to `BOOT_MODE_FAST` gives:

```text
boot_intro = 0
sega_license = 0
```

## 4. Change the default boot mode

Do not change the menu text array:

```c
static const char* boot_mode_choice_text[] = {"Full Boot", "License Only", "Animation Only", "Fast Boot"};
```

That only changes the displayed labels.

Instead, replace the default assignments of:

```c
sf_boot_mode[0] = BOOT_MODE_FULL;
```

with:

```c
sf_boot_mode[0] = BOOT_MODE_FAST;
```

Run:

```bash
sed -i 's/sf_boot_mode\[0\] = BOOT_MODE_FULL;/sf_boot_mode[0] = BOOT_MODE_FAST;/g' \
  openMenu/src/openmenu_settings/src/openmenu_settings.c \
  openMenu/src/openmenu_settings/src/openmenu_savefile.c
```

Confirm the change:

```bash
grep -R "sf_boot_mode\[0\] = BOOT_MODE_" \
  openMenu/src/openmenu_settings/src/openmenu_settings.c \
  openMenu/src/openmenu_settings/src/openmenu_savefile.c
```

Expected result: the default assignments should now use `BOOT_MODE_FAST`.

## 5. Install Docker on Debian Trixie

The Dreamcast-side openMenu binary needs the KallistiOS/Dreamcast cross-compilation environment. The easiest method is to use the existing openMenu Docker image.

On Debian Trixie, install Docker from the default repository:

```bash
sudo apt update
sudo apt install docker.io docker-cli
```

Enable and start Docker:

```bash
sudo systemctl enable --now docker
```

Test Docker:

```bash
sudo docker run hello-world
```

## 6. Build openMenu inside Docker

Create an output directory:

```bash
cd ~/Git/openMenu-Virtual-Folder-Bundle
mkdir -p openMenu-build-output
sudo chmod 777 openMenu-build-output
```

Run the Dreamcast build:

```bash
sudo docker run --rm -i \
  --user 0:0 \
  -e HOST_UID="$(id -u)" \
  -e HOST_GID="$(id -g)" \
  -v "$PWD/openMenu:/src:ro" \
  -v "$PWD/openMenu-build-output:/out" \
  docker.io/sbstnc/openmenu-dev:0.2.2 \
  bash <<'EOF'
set -eo pipefail

source /opt/toolchains/dc/kos/environ.sh

KOSFAT_LIB="$(find "$KOS_BASE/addons" -name libkosfat.a -print -quit || true)"

if [ -z "$KOSFAT_LIB" ]; then
  echo "libkosfat.a not found; building libkosfat..."
  make -C "$KOS_BASE/addons/libkosfat"
  KOSFAT_LIB="$(find "$KOS_BASE/addons" -name libkosfat.a -print -quit || true)"
fi

KOSFAT_DIR="$(dirname "$KOSFAT_LIB")"
echo "Using libkosfat: $KOSFAT_LIB"

rm -rf /tmp/openmenu-build
mkdir -p /tmp/openmenu-build

cmake -S /src -B /tmp/openmenu-build -G Ninja \
  -DBUILD_DREAMCAST=ON \
  -DBUILD_PC=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE=/opt/toolchains/dc/kos/utils/cmake/dreamcast.toolchain.cmake \
  -DCMAKE_EXE_LINKER_FLAGS="-L$KOSFAT_DIR"

cmake --build /tmp/openmenu-build -j"$(nproc)"

cp -v /tmp/openmenu-build/bin/1ST_READ.BIN /out/1ST_READ.BIN
chown "$HOST_UID:$HOST_GID" /out/1ST_READ.BIN 2>/dev/null || true

ls -lh /out/1ST_READ.BIN
EOF
```

A successful build should produce:

```text
openMenu-build-output/1ST_READ.BIN
```

## 7. Copy the rebuilt openMenu binary into GDMENUCardManager

Copy the newly built Dreamcast binary into the Card Manager tool data:

```bash
cp -v \
  openMenu-build-output/1ST_READ.BIN \
  "GD MENU Card Manager/src/GDMENUCardManager.Core/tools/openMenu/menu_data/1ST_READ.BIN"
```

Verify it exists:

```bash
ls -lh "GD MENU Card Manager/src/GDMENUCardManager.Core/tools/openMenu/menu_data/1ST_READ.BIN"
```

## 8. Install the .NET SDK

GDMENUCardManager is a .NET/Avalonia application.

Install Microsoft’s package source for Debian 13/Trixie:

```bash
wget https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

sudo apt update
sudo apt install -y dotnet-sdk-8.0
```

Check the install:

```bash
dotnet --info
```

## 9. Publish GDMENUCardManager for Linux x64

Enter the Card Manager folder:

```bash
cd ~/Git/openMenu-Virtual-Folder-Bundle/"GD MENU Card Manager"
```

Create the release output folder name:

```bash
VERSION="$(tr -d '\r\n' < src/version.txt)"
OUT="_releases/GDMENUCardManager.${VERSION}-linux-x64"
```

Clean and publish:

```bash
rm -rf "$OUT"
mkdir -p "$OUT"

dotnet restore src/GDMENUCardManager.sln

dotnet publish \
  src/GDMENUCardManager.AvaloniaUI/GDMENUCardManager.AvaloniaUI.csproj \
  -c Release \
  -r linux-x64 \
  --self-contained true \
  -p:PublishSingleFile=false \
  -p:IncludeNativeLibrariesForSelfExtract=true \
  -o "$OUT"
```

Copy the tools folder into the release output:

```bash
cp -a src/GDMENUCardManager.Core/tools "$OUT/"
```

Make the application executable:

```bash
chmod +x "$OUT/GDMENUCardManager"
```

## 10. Run the custom build

Run it like the official release:

```bash
cd "$OUT"
./GDMENUCardManager
```

The rebuilt application now includes the modified openMenu `1ST_READ.BIN`, with **Fast Boot** as the default boot mode.

## 11. Optional: create a release archive

From the `GD MENU Card Manager` folder:

```bash
cd ~/Git/openMenu-Virtual-Folder-Bundle/"GD MENU Card Manager"

VERSION="$(tr -d '\r\n' < src/version.txt)"
OUT_NAME="GDMENUCardManager.${VERSION}-linux-x64"

tar -czf "_releases/${OUT_NAME}.tar.gz" \
  -C _releases \
  "$OUT_NAME"

ls -lh "_releases/${OUT_NAME}.tar.gz"
```

## 12. Important note about existing settings

This change affects the default value used by openMenu.

If an SD card already has saved openMenu settings, those saved settings may override the new default. For a clean test, use a fresh settings state, reset the openMenu settings, or manually change the boot mode once in openMenu and save it.
