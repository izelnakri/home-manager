{ pkgs, nixpkgs, config, lib, ... }:
{
  # This causes an overlay which causes a lot of rebuilding
  environment.noXlibs = lib.mkForce false;
  # "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" creates a
  # disk with this label on first boot. Therefore, we need to keep it. It is the
  # only information from the installer image that we need to keep persistent
  fileSystems."/" =
    { device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
    loader = {
      generic-extlinux-compatible.enable = lib.mkDefault true;
      grub.enable = lib.mkDefault false;
    };
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  sdImage.compressImage = false;

  nix.settings = {
    experimental-features = lib.mkDefault "nix-command flakes";
    trusted-users = [ "root" "@wheel" ];
  };
  nixpkgs.config.allowUnsupportedSystem = true;
  nixpkgs.hostPlatform.system = "aarch64-linux";
  nixpkgs.buildPlatform.system = "x86_64-linux"; #If you build on x86 other wise changes this.
}

# { pkgs, modulesPath, lib, ... }: {
#   imports = [
#     "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
#   ];

#   # use the latest Linux kernel
#   boot.kernelPackages = pkgs.linuxPackages_latest;

#   # Needed for https://github.com/NixOS/nixpkgs/issues/58959
#   boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];
# }
