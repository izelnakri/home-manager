# TODO: ollama-sycl & llama.cpp implementation: https://github.com/MordragT/nixos/blob/master/pkgs/by-name/ollama-sycl/default.nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "xe" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/1a0e7a3d-8422-41d1-a83f-3b4e3e20bcec";
      fsType = "btrfs";
      options = [ "subvol=root" "compress=zstd" ];
    };

  boot.initrd.luks.devices."nixos".device = "/dev/disk/by-uuid/0237a834-9730-44de-8c10-b80c026935b5";

  fileSystems."/home" = { 
    device = "/dev/disk/by-uuid/1a0e7a3d-8422-41d1-a83f-3b4e3e20bcec";
    fsType = "btrfs";
    options = [ "subvol=home" "compress=zstd" ];
  };

  fileSystems."/nix" = { 
    device = "/dev/disk/by-uuid/1a0e7a3d-8422-41d1-a83f-3b4e3e20bcec";
    fsType = "btrfs";
    options = [ "subvol=nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/boot" = { 
    device = "/dev/disk/by-uuid/907B-E2B5";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/f14963b8-32dd-4ff6-86fa-9dd7c75cee09"; } ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.enableAllFirmware = true;

  # NOTE: clinfo
  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = [ 
    # pkgs.unstable.intel-media-driver # configuration.nix suggests
    # maybe add also what doc suggests and check npu toggle
    # pkgs.intel-ocl # I found it on nixpkgs
    pkgs.unstable.intel-compute-runtime # This exposes intel graphic drivers to clinfo, check the build recipe
    pkgs.unstable.intel-compute-runtime.drivers # NOTE: Probably absolutely necessary
    pkgs.unstable.intel-media-driver # Needed from nixos-hardware lunar-lake, check the build recipe
    pkgs.unstable.vpl-gpu-rt # Needed from nixos-hardware lunar-lake, check the build recipe
    pkgs.intel-graphics-compiler # ChatGPT recommends: # Required by intel-compute-runtime

    # libvdpau-va-gl # Do I need this?

    (pkgs.callPackage ./intel-npu-driver.nix {})
  ];

  hardware.cpu.intel.updateMicrocode = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  hardware.sane.enable = true;

  hardware.sensor.iio.enable = true; # Trying out gyroscope sensor for screen rotation on the covertible laptop

  # NOTE: This adds to latest npu driver to my Lunar Lake processor until we have intel-npu-driver in nixpkgs:
  hardware.firmware = [
    # NOTE: Does this actually work? Try removing it and check the dmesg | grep vpu
    (
      let
        model = "40xx";
        version = "1";

        firmware = pkgs.fetchurl {
          url = "https://github.com/intel/linux-npu-driver/raw/v1.19.0/firmware/bin/vpu_${model}_v${version}.bin";
          hash = "sha256-KPQxenmwvliOFLiYP5l5D4aSdia13JQIzounj9qs+UY=";
        };
      in
      pkgs.runCommand "intel-vpu-firmware-${model}-${version}" { } ''
        mkdir -p "$out/lib/firmware/intel/vpu"
        cp '${firmware}' "$out/lib/firmware/intel/vpu/vpu_${model}_v${version}.bin"
      ''
    )
  ];
}
