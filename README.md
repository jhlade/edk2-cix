# edk2-cix — Orion O6 LSI/Broadcom Option ROM workaround

[![Build & Release](https://github.com/jhlade/edk2-cix/actions/workflows/release.yaml/badge.svg)](https://github.com/jhlade/edk2-cix/actions/workflows/release.yaml)

> [!CAUTION]
> **AI-assisted, unofficial firmware.** The workaround, integration code,
> documentation, and release preparation in this fork were generated with the
> help of the OpenAI Codex AI coding assistant. They were locally build-tested,
> but have not been independently audited or validated on every Orion O6/HBA
> combination. This is not an official Radxa release. Flashing firmware can
> make a board unbootable; keep a hardware recovery path available.

This personal fork adds an Orion O6 UEFI setting that can skip the legacy
Option ROM exposed by an LSI/Broadcom HBA. It exists as a practical workaround;
there is no intention to submit it upstream as a pull request.

![Orion O6 EDK2 ASSERT while initializing the HBA Option ROM](https://raw.githubusercontent.com/jhlade/edk2-cix/main/docs/assets/orion-o6-lsi-option-rom-assert.webp)

_The failure this workaround targets: an EDK2 ASSERT in
`MdePkg/Library/BaseLib/String.c` while the problematic HBA is installed._

## What changes

The new setting is available at:

`Platform Configuration > Advanced Configuration > Ignore LSI/Broadcom HBA Option ROM`

- Default: `Disabled`
- Scope: Orion O6 only; O6N keeps the original behavior
- Current match: PCI Vendor ID `0x1000` and Mass Storage base class `0x01`
- Effect: the device is still enumerated and receives BAR/resources, but
  `PciBusDxe` does not probe its Option ROM

With the setting enabled, UEFI cannot boot from disks behind the skipped HBA.
An operating system can still use the controller and disks through its own
driver.

## Source patch

The complete `edk2-platforms` patch is:

[`patches/orion-o6-lsi-option-rom.patch`](patches/orion-o6-lsi-option-rom.patch)

The repository keeps the official Radxa submodule URL. Before each build,
[`scripts/apply-edk2-platforms-patches.sh`](scripts/apply-edk2-platforms-patches.sh)
applies the patch idempotently, so a normal recursive clone remains
reproducible without maintaining a second submodule fork.

## Build

```sh
git clone --recurse-submodules https://github.com/jhlade/edk2-cix.git
cd edk2-cix
make deb
```

The patch is applied automatically by the build. Release `1.3.1-1` is based
on upstream wrapper release `1.3.1` and produces both Orion O6 and O6N
packages, while the workaround itself is enabled only for O6.

## Flashing release 1.3.1-1

Download `cix_flash_all.bin` and the UEFI flash utilities from the
[1.3.1-1 release](https://github.com/jhlade/edk2-cix/releases/tag/1.3.1-1).

For the first flash:

1. Fully power off the Orion O6 and remove the problematic HBA. The new setting
   defaults to `Disabled`, so leaving the HBA installed can reproduce the
   original failure.
2. Place the flash files on a FAT32 USB drive and run `startup.nsh` from the
   UEFI Shell.
3. Keep power stable until the update finishes, then physically disconnect all
   power.
4. Boot without the HBA and enable the new setting in UEFI Setup.
5. Save, fully power off again, install the HBA, and boot.

The current match intentionally covers all LSI/Broadcom Mass Storage devices
with Vendor ID `0x1000`. Once the exact PCI Device ID is known from
`lspci -nn`, the policy should be narrowed.

## Verification

- Full RELEASE builds for Orion O6N and Orion O6 completed successfully.
- The final firmware contains version `1.3.1-1` and the new HII setting.
- O6 `FVMAIN` fits with 16 bytes free; `FVMAIN_COMPACT` has 322,040 bytes
  free.
- Hardware flashing and board-level behavior still require validation by the
  person performing the update.

## Upstream and license

Original project: [radxa-pkg/edk2-cix](https://github.com/radxa-pkg/edk2-cix).
This fork remains under the repository's existing [GPL-3.0 license](LICENSE).
