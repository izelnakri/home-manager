# Fairphone 6 / 6+ NixOS integration

This directory currently defines an AArch64 NixOS userspace configuration.
It is not a flashable image.

## Hardware foundation to investigate

The community Catcrafts `fp6-img` project is the starting point for the
Fairphone-specific Linux kernel and boot integration:

https://forgejo.catcrafts.net/Catcrafts/fp6-img

Before adapting it, pin a specific revision and audit its install scripts,
kernel source/config, DTBs/DTBO, firmware extraction, partition handling,
boot image format, initramfs and modem-NV handling. Do not assume its image
can be replaced by a generic NixOS SD image.

## Flake target

```sh
nix eval .#nixosConfigurations.fairphone-6-plus.pkgs.stdenv.hostPlatform.system
nix build .#nixosConfigurations.fairphone-6-plus.config.system.build.toplevel
```

This builds/evaluates an AArch64 NixOS system closure only. It does not create
a bootable Fairphone image.

## Required next work

1. Pin and audit the upstream FP6 Linux project.
2. Package the exact device kernel, config, DTBs and required firmware.
3. Reproduce the boot/rootfs layout expected by the device boot chain.
4. Adapt the installer safely, preserving modem NV, EFS and calibration data.
5. Keep recovery on the internal display; DisplayLink must remain optional
   userspace functionality, never an initramfs/boot dependency.
6. Validate on a fully backed-up device before attempting daily use.

Do not relock the bootloader with an unsupported custom image.
