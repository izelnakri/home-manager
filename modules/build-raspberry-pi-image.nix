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
    #
    # /var/run -> ../run and /var/lib/lastlog are baked in at build time: on first boot
    # /var/run ended up a real directory (tmpfiles' `L /var/run` never applied), so
    # sandboxed services got EROFS writing /var/run/... (nsncd: "Read-only file system"),
    # and /var/lib/lastlog was missing (pam_lastlog2 -> login "System error").
    populateRootCommands = lib.mkForce ''
      mkdir -p ./files/boot ./files/var/lib/lastlog
      mkdir -m 0555 ./files/var/empty   # sshd privilege separation dir
      ln -s ../run ./files/var/run
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

  # The installer profile auto-logs in a passwordless `nixos` user on every console.
  # That autologin looped with "System error" (seen in `make run-pi4`), so HDMI never
  # showed a usable prompt. Plain `pi4-nas login:` instead: log in as izelnakri, or
  # use SSH in parallel. Root has a password (host config) for the emergency shell.
  services.getty.autologinUser = lib.mkForce null;
  users.users.nixos.hashedPassword = lib.mkForce "!"; # locked; not a NAS account

  nix.settings = {
    experimental-features = lib.mkDefault "nix-command flakes repl-flake";
  };
  # Duplicated the host's nix.settings (trusted-users got listed twice):
  # nix.settings = {
  #   max-jobs = lib.mkDefault "auto";
  #   cores = lib.mkDefault 0;
  #   trusted-users = [ "root" "@wheel" ];
  # };

  # p11-kit overlay moved to hosts/izels-pi4/configuration.nix (shared with deploys):
  # nixpkgs = {
  #   overlays = [
  #     (final: super: {
  #       p11-kit = super.p11-kit.overrideAttrs(_: {
  #         doCheck = false;
  #         doInstallCheck = false;
  #       });
  #     })
  #   ];
  # };

  # Belt and braces for the first-boot tmpfiles problem above: re-apply every tmpfiles
  # rule (idempotent) before the services that died from missing /var/run, /var/empty,
  # /var/lib/lastlog. Cheap; can be dropped once the root cause is understood.
  systemd.services.tmpfiles-reapply = {
    description = "Re-apply tmpfiles rules before network services";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-tmpfiles-setup.service" "local-fs.target" ];
    before = [ "sshd.service" "nscd.service" "avahi-daemon.service" "systemd-user-sessions.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "-${config.systemd.package}/bin/systemd-tmpfiles --create";
    };
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

    # Device/partition come from sysfs, not lsblk: lsblk's PKNAME/PARTN come from the
    # udev database, which this early (before sysinit.target) may not have the disk
    # yet. Then partNum was empty, `-N"$partNum"` swallowed `--no-reread`, and the
    # unit failed ("sfdisk: failed to parse partition number"; seen in pi4-vm-test).
    # Old:
    # rootPart="$(${lib.getExe' pkgs.util-linux "findmnt"} -n -o SOURCE /)"
    # bootDevice="$(${lib.getExe' pkgs.util-linux "lsblk"} -npo PKNAME "$rootPart")"
    # partNum="$(${lib.getExe' pkgs.util-linux "lsblk"} -npo PARTN "$rootPart")"
    script = ''
      set -euo pipefail
      rootPart="$(${lib.getExe' pkgs.util-linux "findmnt"} -nvo SOURCE /)"   # -v: no btrfs [/subvol]
      sys="/sys/class/block/$(basename "$rootPart")"
      partNum="$(cat "$sys/partition")"
      bootDevice="/dev/$(basename "$(readlink -f "$sys/..")")"
      echo "expanding $rootPart (partition $partNum of $bootDevice)"

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
