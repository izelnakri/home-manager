{ pkgs, nixpkgs, self, config, lib, ... }:
# SD-image-only settings for pi4-nas. Anything that must also hold on the running
# system (kernel, device tree, bootloader, filesystems) lives in
# hosts/izels-pi4/configuration.nix, so `nix run .#pi4-nas` (nixinate) deploys
# exactly what the image booted.
{
  # sd-image.nix defaults the root to ext4; the label (NIXOS_SD) and the rest of
  # the mount come from the host config.
  fileSystems."/".fsType = lib.mkForce "btrfs";
  # Previously duplicated the host's fileSystems."/" (device/options merged twice):
  # fileSystems."/" = {
  #   device = "/dev/disk/by-label/NIXOS_SD";
  #   fsType = lib.mkForce "btrfs";
  #   options = [
  #     "compress=zstd"
  #     "noatime"
  #   ];
  # };

  # swapDevices = [
  #   {
  #     device = "/var/lib/swapfile";
  #     size = 8500;
  #   }
  # ];

  # Kernel + extlinux settings moved to the host config (see header):
  # boot = {
  #   kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  #
  #   loader = {
  #     grub.enable = lib.mkForce false;
  #
  #     generic-extlinux-compatible = {
  #       enable = lib.mkForce true;
  #       useGenerationDeviceTree = lib.mkForce false;
  #     };
  #   };
  # };

  sdImage = {
    compressImage = false;

    rootFilesystemCreator =
      "${pkgs.path}/nixos/lib/make-btrfs-fs.nix";

    # The stock expansion service calls resize2fs, which is ext4-specific.
    expandOnBoot = false;

    # The FAT partition is mounted over /boot, so the kernel/initrd/extlinux.conf
    # that sd-image-aarch64.nix copies into the btrfs /boot were dead weight that
    # nothing could ever read. Boot files only go to FAT (modules/raspberry-pi/firmware.nix).
    populateRootCommands = lib.mkForce ''
      mkdir -p ./files/boot
    '';

    # THE "U-Boot can't find the partition" BUG: sd-image.nix marks the *root*
    # partition bootable, and U-Boot only scans bootable partitions when any is
    # flagged. Our root is btrfs and this U-Boot has no btrfs driver, so it never
    # looked at the FAT partition holding extlinux/extlinux.conf. Flag FAT only.
    postBuildCommands = ''
      sfdisk --activate "$img" 1
      sfdisk --dump "$img"
    '';
  };

  nix.settings = {
    experimental-features = lib.mkDefault "nix-command flakes repl-flake";
  };
  # Duplicated the host's nix.settings (trusted-users got listed twice):
  # nix.settings = {
  #   max-jobs = lib.mkDefault "auto";
  #   cores = lib.mkDefault 0;
  #   trusted-users = [ "root" "@wheel" ];
  # };

  nixpkgs = {
    overlays = [
      (final: super: {
        # Kept: changing this would invalidate the whole cross-built closure.
        p11-kit = super.p11-kit.overrideAttrs(_: {
          doCheck = false;
          doInstallCheck = false;
        });
      })
    ];
  };

  systemd.services.expand-root-partition = {
    description = "Expand Raspberry Pi Btrfs root partition";

    unitConfig = {
      DefaultDependencies = false;
      ConditionPathExists = "/nix-path-registration";
    };

    wantedBy = [ "sysinit.target" ];
    before = [
      "sysinit.target"
      "shutdown.target"
      "register-nix-paths.service"
    ];
    after = [ "local-fs.target" ];
    conflicts = [ "shutdown.target" ];
    restartIfChanged = false;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      rootPart="$(${lib.getExe' pkgs.util-linux "findmnt"} -n -o SOURCE /)"
      bootDevice="$(${lib.getExe' pkgs.util-linux "lsblk"} -npo PKNAME "$rootPart")"
      partNum="$(${lib.getExe' pkgs.util-linux "lsblk"} -npo PARTN "$rootPart")"

      echo ",+," | ${lib.getExe' pkgs.util-linux "sfdisk"} \
        -N"$partNum" --no-reread "$bootDevice"

      ${lib.getExe' pkgs.parted "partprobe"} "$bootDevice"

      ${lib.getExe' pkgs.btrfs-progs "btrfs"} filesystem resize max /
    '';
  };
}

# { pkgs, modulesPath, lib, ... }: {
#   imports = [
#     "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
#   ];

#   # Needed for https://github.com/NixOS/nixpkgs/issues/58959
#   boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];
# }
