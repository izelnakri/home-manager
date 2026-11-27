{
  # Fairphone 6 / 6+ NixOS userspace scaffold.
  #
  # This is intentionally NOT a flashable image yet. Do not flash this
  # configuration to the phone until the device-specific boot integration,
  # kernel, DTBs, firmware, rootfs layout and installer have been implemented.

  networking.hostName = "fairphone-6-plus";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "@wheel" ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  users.mutableUsers = true;
  users.users.izelnakri = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "render" "input" ];
    shell = pkgs.zsh;
    # Set with passwd after boot, or use a secret-backed hashedPasswordFile.
  };

  programs.zsh.enable = true;
  security.sudo.wheelNeedsPassword = true;
  security.polkit.enable = true;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };

  environment.systemPackages = with pkgs; [
    git vim htop fastfetch usbutils pciutils
  ];

  # Do not choose linuxPackages_latest here. The FP6 requires its supported
  # device-specific kernel and matching DTBs, which are not integrated yet.
  hardware.enableRedistributableFirmware = true;

  system.stateVersion = "26.05";
}
