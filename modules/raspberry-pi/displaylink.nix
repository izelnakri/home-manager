# DisplayLink USB docks/adapters on the Pi (extra screens besides HDMI): evdi kernel module +
# DisplayLinkManager (dlm.service), via nixos/modules/hardware/video/displaylink.nix.
#
#   pi4.displaylink.enable = true;
#
# Off by default only because of build cost: evdi needs the kernel's `dev` output, i.e. one full
# cross rebuild of the kernel, which in turn needs a cross rustc (the kernel is built with Rust
# support). After that one-time build it's cached like everything else.
{ config, lib, inputs, ... }:
let
  cfg = config.pi4.displaylink;
in
{
  options.pi4.displaylink.enable = lib.mkEnableOption "DisplayLink (evdi + DisplayLinkManager) on the Pi";

  config = lib.mkIf cfg.enable {
    # mkAfter: must come after the flake-wide overlay-unstable, which maps displaylink to
    # nixpkgs-unstable (cross-building that would need a second, unstable toolchain). The stable
    # 26.05 definition supports aarch64-linux and shares this config's cross toolchain; it gets
    # the 6.3 driver zip the omnibook uses (already in the store; requireFile can't download it).
    nixpkgs.overlays = lib.mkAfter [
      (final: prev: {
        # evdi: placeholder like all-packages.nix; the NixOS module overrides it with the Pi kernel's.
        displaylink = (prev.callPackage "${inputs.nixpkgs}/pkgs/os-specific/linux/displaylink" {
          inherit (final.linuxPackages) evdi;
        }).overrideAttrs (_: {
          version = "6.3.0-48";
          src = prev.requireFile {
            name = "displaylink-630.zip";
            hash = "sha256-cmmFbHUnBgxRMhXOG1o2/vB02Oicq4m8qxPfNCrM4Jg=";
            url = "https://www.synaptics.com/products/displaylink-usb-graphics-software-ubuntu";
          };
        });
      })
    ];

    # The module keys off videoDrivers; no X server is enabled by this. Hyprland drives the evdi
    # DRM card directly (the tty1 launcher lists every card with connectors in AQ_DRM_DEVICES).
    services.xserver.videoDrivers = [ "displaylink" "modesetting" ];

    # One evdi card exists from boot, so Hyprland, started at login, already includes it; the
    # adapter attaches to it when plugged in. Same as the omnibook.
    boot.extraModprobeConfig = "options evdi initial_device_count=1";
  };
}
