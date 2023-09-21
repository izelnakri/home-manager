{ pkgs, config, lib, ... }:
{
  system.stateVersion = "23.05";

  environment.systemPackages = with pkgs; [
    libarchive
    gnumake
    vim
    git
    bat
    home-manager
  ];

  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "en_US.UTF-8";
  sound.enable = true;

  hardware = {
    pulseaudio.enable = true;
    # cpu.amd.updateMicrocode = true;
  };

  users = {
    users.admin = {
      password = "coolie";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };

  # console = {
  #   packages=[ pkgs.terminus_font ];
  #   font="${pkgs.terminus_font}/share/consolefonts/ter-i22b.psf.gz";
  # };

  # security.polkit.enable = true;
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "pi4-nas";

    # networkmanager.enable = true;  # Easiest to use and most distros use this by default.
    firewall.enable = false;
    enableIPv6 = false;
    interfaces."wlan0".useDHCP = true;
    wireless = {
      interfaces = [ "wlan0" ];
      enable = true;
      networks = {
        UC_wifi_2D.psk = "L0v31sth3k3y-2D";
      };
    };
  };

  # programs = {
  # git = {
  #   enable = true;
  #   userName = "Jane Doe";
  #   userEmail = "jane.doe@example.org";
  # };
  # };

  services = {
    openssh.enable = true;
    timesyncd.enable = true;
    # flatpak.enable = true;
    # dbus.enable = true;

    # gpg-agent = {
    #   enable = true;
    #   defaultCacheTtl = 1800;
    #   enableSshSupport = true;
    # };
  };

  # fonts = {
  #   fonts = with pkgs; [
  #     noto-fonts
  #     noto-fonts-emoji
  #     font-awesome
  #     (nerdfonts.override { fonts = [ "Meslo" ]; })
  #   ];
  #   fontconfig = {
  #     enable = true;
  #     defaultFonts = {
	#       monospace = [ "Meslo LG M Regular Nerd Font Complete Mono" ];
	#       serif = [ "Noto Serif" ];
	#       sansSerif = [ "Noto Sans" ];
  #     };
  #   };
  # };

  # OpenSSH is forced to have an empty `wantedBy` on the installer system[1], this won't allow it
  # to be automatically started. Override it with the normal value.
  # [1] https://github.com/NixOS/nixpkgs/blob/9e5aa25/nixos/modules/profiles/installation-device.nix#L76
  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];
}
