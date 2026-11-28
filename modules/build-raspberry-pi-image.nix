{ pkgs, nixpkgs, self, config, lib, ... }:
{
  # "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" creates a
  # disk with this label on first boot. Therefore, we need to keep it. It is the
  # only information from the installer image that we need to keep persistent
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = lib.mkForce "btrfs";
    options = [
      "compress=zstd"
      "noatime"
    ];
  };
  # swapDevices = [
  #   {
  #     device = "/var/lib/swapfile";
  #     size = 8500;
  #   }
  # ];

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

    loader = {
      grub.enable = lib.mkForce false;

      generic-extlinux-compatible = {
        enable = lib.mkForce true;
        useGenerationDeviceTree = lib.mkForce false;
      };
    };
  };

  sdImage = {
    compressImage = false;

    rootFilesystemCreator =
      "${pkgs.path}/nixos/lib/make-btrfs-fs.nix";

    # The stock expansion service calls resize2fs, which is ext4-specific.
    expandOnBoot = false;
  };

  nix.settings = {
    experimental-features = lib.mkDefault "nix-command flakes repl-flake";
    max-jobs = lib.mkDefault "auto";
    cores = lib.mkDefault 0;
    trusted-users = [ "root" "@wheel" ];
  };

  nixpkgs = {
    overlays = [
      (final: super: {
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
