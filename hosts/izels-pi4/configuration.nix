{ pkgs, config, lib, inputs, ... }:
{
  imports = with inputs.self.nixosModules; [
#     ./disks.nix
#     ./hardware-configuration.nix
#     users-izelnakri # This is NOT the /users/path
#     profiles-tailscale
#     profiles-sway
#     profiles-fail2ban
#     profiles-steam
#     profiles-wireless
#     profiles-pipewire
#     profiles-avahi
#     mixins-obs
#     mixins-v4l2loopback
#     mixins-common
#     mixins-i3status
#     mixins-fonts
#     mixins-bluetooth
#     mixins-vaapi-intel-hybrid-codec
#     mixins-zram
#     editor-nvim
  ];

  # nixpkgs.overlays = [
  #   (self: super: {
  #     mpv-unwrapped = super.mpv-unwrapped.override { ffmpeg_5 = super.ffmpeg_5-full; }; # Allows MPV to open /dev/video*
  #     sway-unwrapped = super.sway-unwrapped.override { stdenv = super.withCFlags [ "-funroll-loops" "-O3" "-march=x86-64-v3" ] super.llvmPackages_15.stdenv; };
  #     kitty = super.kitty.override { stdenv = super.withCFlags [ "-funroll-loops" "-O3" "-march=x86-64-v3" ] super.llvmPackages_15.stdenv; };
  #     nixUnstable = super.nixUnstable.override { stdenv = super.withCFlags [ "-funroll-loops" "-O3" "-march=x86-64-v3" ] super.llvmPackages_15.stdenv; };
  #   })
  # ];

  nix.settings = {
    experimental-features = lib.mkDefault "nix-command flakes repl-flake";
    max-jobs = lib.mkDefault "auto";
    cores = lib.mkDefault 0;
    trusted-users = [ "root" "@wheel" ];
  };

  nixpkgs = {
    config = {
      allowUnsupportedSystem = true;
      allowUnfree = true;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users = import "${inputs.self}/users";
    extraSpecialArgs = {
      inherit inputs;
      headless = false;
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4"; # lib.mkForce "btrfs" doesnt work for now?
  };

  environment.systemPackages = with pkgs; [
    libarchive
    gnumake
    vim
    git
    bat
    home-manager
    htop
    neofetch
    zsh
  ];

  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "en_US.UTF-8";
  sound.enable = true;

  hardware = {
    pulseaudio.enable = true;
    cpu.amd.updateMicrocode = true;
  };

  users = {
    users.izelnakri = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      password = "coolie";
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDP2YFXzWEAwbYvefJzHNw1yu6Z0ZgiBCBFA1pJQ5ajrK18auaOlvCZ6Jqvn/91/Erl6qxc2bHKYNfHPa8YL0U07dZYvEKZ4pqxcpC1aLX29vVTuBQL/e8JenpKtLm6E+/e6x8NKoTb1teADsY/0thZBZSpTWt5q+GeTAkOVYtIFqew5Q7V0pwk+liV6FGHv7XOiGwtG06+KrD1hOwBJIlsMBOPoeye88aKDYnZ864xDCzrOjBALeRCnfXc8RIvCzbMKL78kdsbiowQyPZrc6zPXK1xx0KUNSAeNY6u5U0C6SFf7VikPkNaW7q/YjbbxwSA9ejvAaPcl2TOZnVIh8XaBwCP6jxW9EFljCqwIgjnnk4xE0vIITgZtwff+lTJQ12SqMXBwlD4CpLTo2G9ecUbXgJ6hjt8hsrYyhP+JiGXV45bMOmAVDRcICcCLMfFQQp96RjRGIylXhpUJxjt4AA1K4Op0v5ugxCry5b4mkc7VNMQl1cRCCkj9WE1wCk/qrs= izelnakri@x1-carbon"
      ];
    };
  };

  programs = {
    zsh.enable = true;
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };

  security = {
    polkit.enable = true;
    # pam.enableSSHAgentAuth = true;
    # users.users.root.openssh.authorizedKeys.keys
  };

  boot = {
    binfmt.emulatedSystems = [ "x86_64-linux" ];
  };

  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking = {
    hostName = "pi4-nas";
    # networkmanager.enable = true;  # Requires networking.supplication default network declaration
    firewall.enable = false;
    enableIPv6 = false;
    interfaces."wlan0".useDHCP = true;
    wireless = {
      interfaces = [ "wlan0" ];
      enable = true;
      networks = {
        UC_wifi_2D.pskRaw = "f36173de86e72e79253b4350db006c1e6cc4187c3f30e18a727c41bb844e52a8";
      };
    };
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = lib.mkForce "no";
      };
    };
    timesyncd.enable = true;
    # flatpak.enable = true;
    # dbus.enable = true;

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

  system.stateVersion = "23.05";

  # users.users.matthew.extraGroups = [ "video" ];

  # nix = {
  #   # From flake-utils-plus
  #   generateNixPathFromInputs = true;
  #   generateRegistryFromInputs = true;
  #   linkInputs = true;
  # };

  # networking = {
  #   firewall = {
  #     # Syncthing ports
  #     allowedTCPPorts = [ 22000 ];
  #     allowedUDPPorts = [ 21027 22000 ];
  #   };
  #   hostName = "t480";
  #   useNetworkd = true;
  #   wireless = {
  #     userControlled.enable = true;
  #     enable = true;
  #     interfaces = [ "wlp3s0" ];
  #   };
  #   useDHCP = false;
  #   interfaces = {
  #     "enp0s31f6".useDHCP = true;
  #     "wlp3s0".useDHCP = true;
  #   };
  # };

  # services = {
  #   udev.extraRules = ''
  #     # Nreal Air Glasses
  #     SUBSYSTEMS=="usb", ATTRS{idVendor}=="3318", ATTRS{idProduct}=="0424", GROUP="input", MODE="0666"
  #     # Gamecube Controller Adapter
  #     SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", MODE="0666"
  #     # Xiaomi Mi 9 Lite
  #     SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="05c6", ATTRS{idProduct}=="9039", MODE="0666"
  #     SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="2717", ATTRS{idProduct}=="ff40", MODE="0666"
  #   '';
  #   thermald.enable = true;
  #   tlp = {
  #     enable = true;
  #     settings = {
  #       PCIE_ASPM_ON_BAT = "powersupersave";
  #       CPU_SCALING_GOVERNOR_ON_AC = "performance";
  #       CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
  #       CPU_MAX_PERF_ON_AC = "100";
  #       CPU_MAX_PERF_ON_BAT = "30";
  #       STOP_CHARGE_THRESH_BAT1 = "95";
  #       STOP_CHARGE_THRESH_BAT0 = "95";
  #     };
  #   };
  #   logind.killUserProcesses = true;
  # };

  # boot = {
  #   tmp.useTmpfs = true;
  #   kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  #   kernelParams = [
  #     "i915.modeset=1"
  #     "i915.fastboot=1"
  #     "i915.enable_guc=2"
  #     "i915.enable_psr=1"
  #     "i915.enable_fbc=1"
  #     "i915.enable_dc=2"
  #   ];
  #   loader = {
  #     systemd-boot = {
  #       enable = true;
  #       configurationLimit = 10;
  #     };
  #     efi = {
  #       canTouchEfiVariables = true;
  #     };
  #   };
  # };

  # i18n.defaultLocale = "en_GB.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # time.timeZone = "Europe/London";
  # location.provider = "geoclue2";

  # hardware = {
  #   opengl.enable = true;
  #   trackpoint = {
  #     enable = true;
  #     sensitivity = 255;
  #   };
  # };
}


# Running GNOME:
# services.xserver.enable = true;
# services.xserver.displayManager.gdm.enable = true;
# services.xserver.desktopManager.gnome.enable = true;

# Enable dconf
# programs.dconf.enable = true;

# environment.gnome.excludePackages = (with pkgs; [
#   gnome-photos
#   gnome-tour
# ]) ++ (with pkgs.gnome; [
#   cheese # webcam tool
#   gnome-music
#   gnome-terminal
#   gedit # text editor
#   epiphany # web browser
#   geary # email reader
#   evince # document viewer
#   gnome-characters
#   totem # video player
#   tali # poker game
#   iagno # go game
#   hitori # sudoku game
#   atomix # puzzle game
# ]);

# Many applications rely heavily on having an icon theme available, GNOME’s Adwaita is a good choice but most recent icon themes should work as well.
# environment.systemPackages = [ gnome.adwaita-icon-theme ];
# Systray Icons
# environment.systemPackages = with pkgs; [ gnomeExtensions.appindicator ];
# services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

# gnome.gnome-tweaks

# gnome3.gnome-tweak-tool
# gnome3.evince # pdf reader
# # extensions
# gnomeExtensions.appindicator
# gnomeExtensions.dash-to-dock
# gnomeExtensions.battery-status


# Autologin
# services.xserver.displayManager.autoLogin.enable = true;
# services.xserver.displayManager.autoLogin.user = "account";
# systemd.services."getty@tty1".enable = false;
# systemd.services."autovt@tty1".enable = false;

# Gnome cheatsheet:
# https://wiki.gnome.org/Projects/GnomeShell/CheatSheet

# dconf watch /
# dconf write /org/gnome/desktop/interface/color-scheme "'default'"
# dconf.settings = {
#   "org/gnome/desktop/interface" = {
#     color-scheme = "prefer-dark";
#   };
# "org/gnome/shell" = {
# disable-user-extensions = false;

# # `gnome-extensions list` for a list
# enabled-extensions = [
#   "user-theme@gnome-shell-extensions.gcampax.github.com"
#   "trayIconsReloaded@selfmade.pl"
#   "Vitals@CoreCoding.com"
#   "dash-to-panel@jderose9.github.com"
#   "sound-output-device-chooser@kgshank.net"
#   "space-bar@luchrioh"
# ];
#   favorite-apps = [
#     "firefox.desktop"
#     "code.desktop"
#     "org.gnome.Terminal.desktop"
#     "spotify.desktop"
#     "virt-manager.desktop"
#     "org.gnome.Nautilus.desktop"
#   ];
# "org/gnome/shell/extensions/user-theme" = {
#   name = "palenight";
# };
# };
# };
# Also download extension packages from gnomeExtensions.user-themes etc

# $ dconf dump / > dconf.settings

# { lib, ... }:
# let
#   mkTuple = lib.hm.gvariant.mkTuple;
# in
# {
#   dconf.settings = {
#     "org/gnome/desktop/peripherals/mouse" = {
#       "natural-scroll" = false;
#       "speed" = -0.5;
#     };

#     "org/gnome/desktop/peripherals/touchpad" = {
#       "tap-to-click" = false;
#       "two-finger-scrolling-enabled" = true;
#     };

#     "org/gnome/desktop/input-sources" = {
#       "current" = "uint32 0";
#       "sources" = [ (mkTuple [ "xkb" "us" ]) ];
#       "xkb-options" = [ "terminate:ctrl_alt_bksp" "lv3:ralt_switch" "caps:ctrl_modifier" ];
#     };

#     "org/gnome/desktop/screensaver" = {
#       "picture-uri" = "file:///home/gvolpe/Pictures/nixos.png";
#     };
#   };
# }
# dconf2nix


# installGnomeSessionScript = pkgs.writeShellScriptBin "install-gnome-session" ''
#   sudo ln -fs ${pkgs.gnome.gnome-session.sessions}/share/wayland-sessions/gnome.desktop /usr/share/wayland-sessions/gnome.desktop
# '';

# home.packages = [ installGnomeSessionScript ];

# TODO: implement pipewire with wireplumber + alsa, pulse, jack etc
