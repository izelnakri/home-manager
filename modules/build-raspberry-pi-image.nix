{ pkgs, nixpkgs, self, config, lib, ... }:
# SD-image-only settings for pi4-nas. Anything that must also hold on the running
# system (kernel, device tree, bootloader, filesystems) lives in
# hosts/izels-pi4/configuration.nix, so `make pi4-deploy` (nixinate) deploys
# exactly what the image booted.
{
  # Root is ext4 (sd-image.nix's default; label/options in the host config). It was btrfs:
  # nixpkgs' make-btrfs-fs.nix runs mkfs.btrfs, which reads file owners past fakeroot, so
  # the image's /, /var and /nix/store were owned by uid 1000 (the Nix build user). systemd
  # refused "unsafe path transitions" (tmpfiles skipped /var/run, /var/empty, /run/opengl-driver
  # -> sshd, nsncd, login "System error", Hyprland "dri_gbm.so") and NetworkManager skipped its
  # Wi-Fi plugin ("invalid owner"). Even chown inside fakeroot didn't stick for mkfs.btrfs.
  # fileSystems."/".fsType = lib.mkForce "btrfs";

  # swapDevices = [
  #   {
  #     device = "/var/lib/swapfile";
  #     size = 8500;
  #   }
  # ];

  sdImage = {
    compressImage = false;

    # Stock ext4 rootfs builder + stock first-boot resize (resize2fs). Previously:
    # rootFilesystemCreator = "${pkgs.path}/nixos/lib/make-btrfs-fs.nix";
    # expandOnBoot = false; # (+ a custom btrfs expand-root-partition service)

    # The FAT partition is mounted over /boot, so the kernel/initrd/extlinux.conf that
    # sd-image-aarch64.nix also copies into the root's /boot are dead weight nothing reads.
    # Boot files only go to FAT (modules/raspberry-pi/firmware.nix).
    populateRootCommands = lib.mkForce ''
      mkdir -p ./files/boot
    '';
    # Workaround for the btrfs ownership bug above, no longer needed with ext4:
    # mkdir -p ./files/boot ./files/var/lib/lastlog
    # mkdir -m 0555 ./files/var/empty
    # ln -s ../run ./files/var/run

    # THE "U-Boot can't find the partition" BUG: sd-image.nix marks the *root* partition
    # bootable, and U-Boot only scans bootable partitions when any is flagged. Boot files
    # live on FAT (partition 1), so flag that one only.
    postBuildCommands = ''
      sfdisk --activate "$img" 1
      sfdisk --dump "$img"
    '';
  };

  # The installer profile auto-logs in a passwordless `nixos` user on every console.
  # That autologin looped with "System error", so HDMI never showed a usable prompt.
  # Plain `pi4-nas login:` instead: log in as izelnakri, or use SSH in parallel.
  # Root has a password (host config) for the emergency shell.
  services.getty.autologinUser = lib.mkForce null;
  users.users.nixos.hashedPassword = lib.mkForce "!"; # locked; not a NAS account

  nix.settings = {
    experimental-features = lib.mkDefault "nix-command flakes repl-flake";
  };

  # Removed with the switch to ext4 (they only papered over the btrfs ownership bug):
  # systemd.services.tmpfiles-reapply  (re-ran systemd-tmpfiles --create before sshd/nscd)
  # systemd.services.expand-root-partition  (btrfs resize; ext4 uses the stock service)
}

# { pkgs, modulesPath, lib, ... }: {
#   imports = [
#     "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
#   ];

#   # Needed for https://github.com/NixOS/nixpkgs/issues/58959
#   boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];
# }
