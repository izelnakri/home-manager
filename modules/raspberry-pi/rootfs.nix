# Root filesystem of pi4-nas: ext4 (default, verified on the real Pi) or btrfs.
#
#   pi4.rootFs = "ext4";   # stock nixpkgs ext4 image + stock first-boot resize2fs
#   pi4.rootFs = "btrfs";  # zstd-compressed btrfs, built with ./make-btrfs-fs.nix (root-owned
#                          # files, see the "pi4:" comment there) + a btrfs first-boot resize
#
# flake.nix builds both: `images.pi4-nas` (ext4) and `images.pi4-nas-btrfs`. Deploys
# (nixosConfigurations.pi4-nas) must use the same value as the card that's in the Pi.
{ config, lib, options, pkgs, ... }:
let
  cfg = config.pi4;
  btrfs = cfg.rootFs == "btrfs";
in
{
  options.pi4.rootFs = lib.mkOption {
    type = lib.types.enum [ "ext4" "btrfs" ];
    default = "ext4";
    description = "Root filesystem type of the pi4-nas SD card.";
  };

  config = lib.mkMerge [
    {
      fileSystems."/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = lib.mkForce cfg.rootFs; # mkForce: sd-image.nix also sets it (ext4)
        options = if btrfs then [ "compress=zstd" "noatime" ] else [ "noatime" ];
      };
    }

    (lib.mkIf btrfs {
      boot.supportedFilesystems = [ "btrfs" ];
      boot.initrd.supportedFilesystems = [ "btrfs" ];

      # The stock sd-image expansion calls resize2fs (ext4 only): grow partition + btrfs here.
      # Device/partition come from sysfs, not lsblk (lsblk's PKNAME/PARTN come from the udev
      # database, which may not have the disk yet this early -> empty partNum).
      systemd.services.expand-root-partition = {
        description = "Expand Raspberry Pi btrfs root partition";
        unitConfig = {
          DefaultDependencies = false;
          ConditionPathExists = "/nix-path-registration";
        };
        wantedBy = [ "sysinit.target" ];
        before = [ "sysinit.target" "shutdown.target" "register-nix-paths.service" ];
        after = [ "local-fs.target" ];
        conflicts = [ "shutdown.target" ];
        restartIfChanged = false;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          rootPart="$(${lib.getExe' pkgs.util-linux "findmnt"} -nvo SOURCE /)"
          sys="/sys/class/block/$(basename "$rootPart")"
          partNum="$(cat "$sys/partition")"
          bootDevice="/dev/$(basename "$(readlink -f "$sys/..")")"
          echo "expanding $rootPart (partition $partNum of $bootDevice)"
          echo ",+," | ${lib.getExe' pkgs.util-linux "sfdisk"} -N"$partNum" --no-reread "$bootDevice"
          ${lib.getExe' pkgs.parted "partprobe"} "$bootDevice"
          ${lib.getExe' pkgs.btrfs-progs "btrfs"} filesystem resize max /
        '';
      };
    })

    # Only when building an SD image (sd-image module imported).
    (lib.optionalAttrs (options ? sdImage) (lib.mkIf btrfs {
      sdImage = {
        rootFilesystemCreator = ./make-btrfs-fs.nix;
        expandOnBoot = false;
      };
    }))
  ];
}
