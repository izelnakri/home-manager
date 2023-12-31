{ pkgs, nixpkgs, self, config, lib, ... }:
{
  # "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" creates a
  # disk with this label on first boot. Therefore, we need to keep it. It is the
  # only information from the installer image that we need to keep persistent
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4"; # lib.mkForce "btrfs" doesnt work for now?
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
      generic-extlinux-compatible.enable = lib.mkDefault true;
      grub.enable = lib.mkDefault false;
    };
  };

  sdImage.compressImage = false;

  nix.settings = {
    experimental-features = lib.mkDefault "nix-command flakes repl-flake";
    max-jobs = lib.mkDefault "auto";
    cores = lib.mkDefault 0;
    trusted-users = [ "root" "@wheel" ];
  };

  nixpkgs = {
    hostPlatform.system = "aarch64-linux";
    buildPlatform.system = "x86_64-linux";

    overlays = [
      (final: super: {
        p11-kit = super.p11-kit.overrideAttrs(_: {
          doCheck = false;
          doInstallCheck = false;
        });
      })
    ];
  };
}

# { pkgs, modulesPath, lib, ... }: {
#   imports = [
#     "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
#   ];

#   # Needed for https://github.com/NixOS/nixpkgs/issues/58959
#   boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];
# }
