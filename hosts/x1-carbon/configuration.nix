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
    users.izelnakri = {
      password = "coolie";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };

  # security.polkit.enable = true;
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking = {
    hostName = "x1-carbon";
    # networkmanager.enable = true;  # Requires networking.supplication default network declaration
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

  services = {
    openssh.enable = true;
    timesyncd.enable = true;
    flatpak.enable = true;
    dbus.enable = true;
    # gpg-agent = {
    #   enable = true;
    #   defaultCacheTtl = 1800;
    #   enableSshSupport = true;
    # };
  };

  # NOTE: Takes long, optimize it(?)
  # zopflipng -y "build/quantized_pngs/emoji_u1f1ea_1f1ea.png" "build/compressed_pngs/emoji_u1f1ea_1f1ea.png" 1> /dev/null 2>&1
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      font-awesome
      (nerdfonts.override { fonts = [ "Meslo" ]; })
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "Meslo LG M Regular Nerd Font Complete Mono" ];
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
      };
    };
  };

  # OpenSSH is forced to have an empty `wantedBy` on the installer system[1], this won't allow it
  # to be automatically started. Override it with the normal value.
  # [1] https://github.com/NixOS/nixpkgs/blob/9e5aa25/nixos/modules/profiles/installation-device.nix#L76
  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];
}
