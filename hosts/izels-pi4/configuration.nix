{ pkgs, config, lib, inputs, ... }:
{
  imports = [
    ../../modules/raspberry-pi/firmware.nix
  ];

  disabledModules = [
    "${inputs.nixos-hardware}/raspberry-pi/common/firmware.nix"
  ];

  nix.settings = {
    experimental-features = lib.mkDefault "nix-command flakes repl-flake";
    max-jobs = lib.mkDefault "auto";
    cores = lib.mkDefault 0;
    trusted-users = [ "root" "@wheel" ];
  };

  nixpkgs.config = {
    allowUnsupportedSystem = true;
    allowUnfree = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  boot.initrd.supportedFilesystems = [ "btrfs" ];
  boot.supportedFilesystems = [ "btrfs" ];

  nixpkgs.overlays = [
    # Was only in modules/build-raspberry-pi-image.nix; here so nixinate deploys share the
    # image's (cross-built, already in the store) closure instead of rebuilding from p11-kit up.
    (final: super: {
      p11-kit = super.p11-kit.overrideAttrs (_: { doCheck = false; doInstallCheck = false; });
    })
    inputs.hyprland.overlays.hyprland-packages
    inputs.hyprland.overlays.hyprland-extras

    (final: prev: {
      xdg-desktop-portal-hyprland =
        prev.xdg-desktop-portal-hyprland.overrideAttrs (old: {
          buildInputs = (old.buildInputs or []) ++ [
            final.expat
          ];

          preConfigure = (old.preConfigure or "") + ''
            export PKG_CONFIG_PATH_aarch64_unknown_linux_gnu="\
            ${final.buildPackages.hyprwayland-scanner}/lib/pkgconfig\
            ''${PKG_CONFIG_PATH_aarch64_unknown_linux_gnu:+:$PKG_CONFIG_PATH_aarch64_unknown_linux_gnu}"
          '';
        });
        hyprland = prev.hyprland.overrideAttrs (old: {
          buildInputs =
            (builtins.filter
              (dep: final.lib.getName dep != "wayland-protocols")
              (old.buildInputs or []))
            ++ [
              final.unstable.wayland-protocols
              final.expat
            ];
        });
    })
  ];

  hardware.graphics.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = false;
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # services.greetd = {
  #   enable = true;
  #
  #   settings.default_session = {
  #     command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
  #     user = "greeter";
  #   };
  # };

  hardware.raspberry-pi = {
    firmware = {
      enable = true;
      path = "/boot";

      uboot = {
        enable = true;
        package = pkgs.ubootRaspberryPiAarch64.override {
          extraConfig = ''
            CONFIG_BOOTSTD=y
            CONFIG_BOOTSTD_FULL=y
            CONFIG_BOOTSTD_DEFAULTS=y
            CONFIG_BOOTSTD_BOOTCOMMAND=y
            CONFIG_BOOTMETH_EXTLINUX=y
            CONFIG_CMD_BOOTDEV=y
            CONFIG_CMD_BOOTFLOW=y
            CONFIG_CMD_BOOTFLOW_FULL=y
            CONFIG_CMD_BOOTMETH=y
            CONFIG_CMD_BOOTSTD=y
            # Must be explicit: with CMD_BOOTFLOW_FULL, plain "bootflow scan" only
            # *lists* bootflows and drops to the U-Boot> prompt (found in QEMU,
            # `make pi4-vm-test`). Kconfig would default to "-lb", but buildUBoot
            # appends extraConfig after the defconfig already set "bootflow scan".
            CONFIG_BOOTCOMMAND="bootflow scan -lb"
            # CONFIG_BOOTMETH_EFI_BOOTMGR is not set
            # CONFIG_BOOTMETH_EFILOADER is not set
          '';
        };
      };
    };

    # U-Boot hands Linux the *mainline* DTB (FDTDIR, see boot.loader below), so
    # firmware-applied overlays never reach the kernel. vc4-kms-v3d was also written
    # for the downstream DT/rpi kernel; with mainline 7.x it was the likely cause of
    # HDMI going black once vc4 took over from the firmware framebuffer. Mainline's
    # bcm2711-rpi-4-b.dtb already enables vc4/hdmi/v3d.
    configtxt.deviceTreeOverlays.all = lib.mkForce [ ];
    # configtxt.deviceTreeOverlays.all = lib.mkForce [
    #   { vc4-kms-v3d.noaudio = true; }
    # ];
  };

  boot = {
    # Mainline kernel (already cross-built in the store). Set here instead of the
    # image module so the image and nixinate deploys run the same kernel; without
    # it nixos-hardware would mkDefault the rpi vendor kernel on first deploy.
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest; # mkForce: sd-image *-new-kernel also sets it

    loader = {
      grub.enable = false;
      generic-extlinux-compatible = {
        enable = true;
        # true => extlinux.conf gets FDTDIR, U-Boot loads the kernel's own (mainline)
        # bcm2711-rpi-4-b.dtb: kernel and DT always match. (firmware.nix defaults it
        # to false to keep config.txt overlays, which only suits the vendor kernel.)
        useGenerationDeviceTree = true;
        configurationLimit = 10; # FAT partition is 512M; ~45M per generation
      };
    };
  };

  environment.systemPackages = with pkgs; [
    libarchive
    gnumake
    vim
    git
    bat
    htop
    fastfetch
    zsh
  ];

  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.izelnakri = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # full root via sudo
    # Pre-hashed (`openssl passwd -6 -salt Pi4nasSaltFixed1 testing`) instead of
    # initialPassword: that one is hashed at runtime on first boot by the cross-built
    # activation and gave "Incorrect password" on the real Pi. TEMPORARY password;
    # change with `passwd` or switch to a ragenix hashedPasswordFile.
    hashedPassword = "$6$Pi4nasSaltFixed1$cNl/40c57yX6T.sRmrTRYb/CNtsZxkwMzRb0viidPoYmLsK10iDk1xOZTYKjkYfDAvUVvK6htONWN.1VVYIGt1";
    # initialPassword = "testing";

    # Set locally with `passwd`, or use a secret-backed hashedPasswordFile.
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDP2YFXzWEAwbYvefJzHNw1yu6Z0ZgiBCBFA1pJQ5ajrK18auaOlvCZ6Jqvn/91/Erl6qxc2bHKYNfHPa8YL0U07dZYvEKZ4pqxcpC1aLX29vVTuBQL/e8JenpKtLm6E+/e6x8NKoTb1teADsY/0thZBZSpTWt5q+GeTAkOVYtIFqew5Q7V0pwk+liV6FGHv7XOiGwtG06+KrD1hOwBJIlsMBOPoeye88aKDYnZ864xDCzrOjBALeRCnfXc8RIvCzbMKL78kdsbiowQyPZrc6zPXK1xx0KUNSAeNY6u5U0C6SFf7VikPkNaW7q/YjbbxwSA9ejvAaPcl2TOZnVIh8XaBwCP6jxW9EFljCqwIgjnnk4xE0vIITgZtwff+lTJQ12SqMXBwlD4CpLTo2G9ecUbXgJ6hjt8hsrYyhP+JiGXV45bMOmAVDRcICcCLMfFQQp96RjRGIylXhpUJxjt4AA1K4Op0v5ugxCry5b4mkc7VNMQl1cRCCkj9WE1wCk/qrs= izelnakri@x1-carbon"
      # omnibook (this laptop): key auth for `make pi4-deploy` / `make run-pi4 ARGS=--ssh ...`
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwZQqINIghrteWbhRl9RtHimKF27o24AuJAbEnAuMgf contact@izelnakri.com"
    ];
  };

  # Root gets the same temporary password so the console emergency shell is usable
  # (empty root password gave "System error"). mkForce: the installer profile sets "".
  users.users.root.hashedPassword = lib.mkForce config.users.users.izelnakri.hashedPassword;
  users.users.root.initialHashedPassword = lib.mkForce null;

  # Console login said "System error" right after a correct password (VM and real Pi):
  #   pam_lastlog2(login:session): Cannot create/open database (/var/lib/lastlog/lastlog2.db)
  # pam_lastlog2 is a *required* session module, so a missing /var/lib/lastlog kills every
  # login. Last-login bookkeeping isn't worth that; off for console and SSH.
  security.pam.services.login.lastlog.enable = lib.mkForce false;
  security.pam.services.sshd.lastlog.enable = lib.mkForce false;

  programs.zsh.enable = true;
  security.polkit.enable = true;

  # boot.loader.systemd-boot.enable = true;
  # boot.loader.systemd-boot.configurationLimit = 25;
  # No EFI on this U-Boot/extlinux setup:
  # boot.loader.efi.canTouchEfiVariables = true;

  # boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
  # boot.kernelParams = [
  #   "console=tty0"
  # ];
  # The *last* console= becomes /dev/console (where systemd prints its status), so
  # the HDMI tty must come last. "serial0" only exists when the Pi firmware rewrites
  # cmdline.txt, which never happens under U-Boot, so it was a dead entry.
  # loglevel=7 already comes from sd-image-aarch64.nix (boot.consoleLogLevel).
  boot.kernelParams = [
    "console=ttyS1,115200" # mini-UART on GPIO14/15 (enable_uart=1) for a USB-TTL cable
    "console=tty1"
    # If the monitor still blanks when vc4 takes over, force a mode it surely supports:
    # "video=HDMI-A-1:1920x1080@60"
  ];
  # boot.kernelParams = [
  #   "console=tty0"
  #   "console=serial0,115200"
  #   "earlycon"
  #   "ignore_loglevel"
  #   "loglevel=7"
  # ];

  boot.initrd.verbose = true;

  networking = {
    hostName = "pi4-nas";

    networkmanager = {
      enable = true;
      ensureProfiles.profiles.home-wifi = {
        connection = {
          id = "home-wifi";
          type = "wifi";
          autoconnect = true;
        };
        wifi.ssid = "Urban Campus | Members";
        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "L0v31sth3k3y";
        };
        ipv4.method = "auto";
        ipv6.method = "auto";
      };
    };
  };

  # Local HDMI text console.
  systemd.defaultUnit = lib.mkForce "multi-user.target";

  # Preserve normal SSH startup when composing with the SD-card installer profile.
  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];
  # systemd.services."getty@tty1".wantedBy = [ "getty.target" ];

  system.stateVersion = "25.05";

  # services.xserver = {
  #   enable = true;
  #   videoDrivers = [ "modesetting" ]; # NOTE: should this be "intel-neo" instead?
  # };
  # services.displayManager.gdm.enable = true; # GDM supports Wayland; LightDM held DRM for its X greeter and made Hyprland abort with "Could not take device" on Lunar Lake.
  # services.desktopManager.gnome.enable = true;
  # services.displayManager.autoLogin.user = "izelnakri";
  # services.displayManager.defaultSession = "hyprland";
  # services.displayManager.hiddenUsers = [ "root" ];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = lib.mkForce "no";
  };

  services.timesyncd.enable = true;

  fonts = {
    packages = with pkgs; [
      noto-fonts 
      noto-fonts-color-emoji 
      font-awesome
      nerd-fonts.meslo-lg
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
}

# -----------------------------------------------------------------------------\n# ORIGINAL hosts/izels-pi4/configuration.nix (uploaded by user), retained below.\n# Secret values are redacted; the active configuration above is evaluated.\n# -----------------------------------------------------------------------------\n# { pkgs, config, lib, inputs, ... }:
# {
#   imports = with inputs.self.nixosModules; [
# #     ./hardware-configuration.nix
# #     users-izelnakri # This is NOT the /users/path
# #     profiles-tailscale
# #     profiles-sway
# #     profiles-fail2ban
# #     profiles-steam
# #     profiles-wireless
# #     profiles-pipewire
# #     profiles-avahi
# #     mixins-obs
# #     mixins-v4l2loopback
# #     mixins-common
# #     mixins-i3status
# #     mixins-fonts
# #     mixins-bluetooth
# #     mixins-vaapi-intel-hybrid-codec
# #     mixins-zram
# #     editor-nvim
#   ];
#\n#   # nixpkgs.overlays = [
#   #   (self: super: {
#   #     mpv-unwrapped = super.mpv-unwrapped.override { ffmpeg_5 = super.ffmpeg_5-full; }; # Allows MPV to open /dev/video*
#   #     sway-unwrapped = super.sway-unwrapped.override { stdenv = super.withCFlags [ "-funroll-loops" "-O3" "-march=x86-64-v3" ] super.llvmPackages_15.stdenv; };
#   #     kitty = super.kitty.override { stdenv = super.withCFlags [ "-funroll-loops" "-O3" "-march=x86-64-v3" ] super.llvmPackages_15.stdenv; };
#   #     nixUnstable = super.nixUnstable.override { stdenv = super.withCFlags [ "-funroll-loops" "-O3" "-march=x86-64-v3" ] super.llvmPackages_15.stdenv; };
#   #   })
#   # ];
#\n#   nix.settings = {
#     experimental-features = lib.mkDefault "nix-command flakes repl-flake";
#     max-jobs = lib.mkDefault "auto";
#     cores = lib.mkDefault 0;
#     trusted-users = [ "root" "@wheel" ];
#   };
#\n#   nixpkgs = {
#     config = {
#       allowUnsupportedSystem = true;
#       allowUnfree = true;
#     };
#   };
#\n#   home-manager = {
#     useGlobalPkgs = true;
#     useUserPackages = true;
#     users = import "${inputs.self}/users";
#     extraSpecialArgs = {
#       inherit inputs;
#       headless = false;
#     };
#   };
#\n#   fileSystems."/" = {
#     device = "/dev/disk/by-label/NIXOS_SD";
#     fsType = "ext4"; # lib.mkForce "btrfs" doesnt work for now?
#   };
#\n#   environment.systemPackages = with pkgs; [
#     libarchive
#     gnumake
#     vim
#     git
#     bat
#     home-manager
#     htop
#     fastfetch
#     zsh
#   ];
#\n#   time.timeZone = "Europe/Madrid";
#   i18n.defaultLocale = "en_US.UTF-8";
#   sound.enable = true;
#\n#   hardware = {
#     pulseaudio.enable = true;
#     cpu.amd.updateMicrocode = true;
#   };
#\n#   users = {
#     users.izelnakri = {
#       isNormalUser = true;
#       extraGroups = [ "wheel" ];
#       password = "<REDACTED: original plaintext password was present>";
#       shell = pkgs.zsh;
#       openssh.authorizedKeys.keys = [
#         "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDP2YFXzWEAwbYvefJzHNw1yu6Z0ZgiBCBFA1pJQ5ajrK18auaOlvCZ6Jqvn/91/Erl6qxc2bHKYNfHPa8YL0U07dZYvEKZ4pqxcpC1aLX29vVTuBQL/e8JenpKtLm6E+/e6x8NKoTb1teADsY/0thZBZSpTWt5q+GeTAkOVYtIFqew5Q7V0pwk+liV6FGHv7XOiGwtG06+KrD1hOwBJIlsMBOPoeye88aKDYnZ864xDCzrOjBALeRCnfXc8RIvCzbMKL78kdsbiowQyPZrc6zPXK1xx0KUNSAeNY6u5U0C6SFf7VikPkNaW7q/YjbbxwSA9ejvAaPcl2TOZnVIh8XaBwCP6jxW9EFljCqwIgjnnk4xE0vIITgZtwff+lTJQ12SqMXBwlD4CpLTo2G9ecUbXgJ6hjt8hsrYyhP+JiGXV45bMOmAVDRcICcCLMfFQQp96RjRGIylXhpUJxjt4AA1K4Op0v5ugxCry5b4mkc7VNMQl1cRCCkj9WE1wCk/qrs= izelnakri@x1-carbon"
#       ];
#     };
#   };
#\n#   programs = {
#     zsh.enable = true;
#     hyprland = {
#       enable = true;
#       xwayland.enable = true;
#     };
#   };
#\n#   security = {
#     polkit.enable = true;
#     # pam.enableSSHAgentAuth = true;
#     # users.users.root.openssh.authorizedKeys.keys
#   };
#\n#   boot = {
#     binfmt.emulatedSystems = [ "x86_64-linux" ];
#   };
#\n#   # boot.loader.systemd-boot.enable = true;
#   # boot.loader.efi.canTouchEfiVariables = true;
#   # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
#\n#   networking = {
#     hostName = "pi4-nas";
#     # networkmanager.enable = true;  # Requires networking.supplication default network declaration
#     firewall.enable = false;
#     enableIPv6 = false;
#     interfaces."wlan0".useDHCP = true;
#     wireless = {
#       interfaces = [ "wlan0" ];
#       enable = true;
#       networks = {
#         UC_wifi_2D.pskRaw = "<REDACTED: original Wi-Fi PSK was present>";
#       };
#     };
#   };
#\n#   services = {
#     openssh = {
#       enable = true;
#       settings = {
#         PermitRootLogin = lib.mkForce "no";
#       };
#     };
#     timesyncd.enable = true;
#     # flatpak.enable = true;
#   };
#\n#   # NOTE: Takes long, optimize it(?)
#   # zopflipng -y "build/quantized_pngs/emoji_u1f1ea_1f1ea.png" "build/compressed_pngs/emoji_u1f1ea_1f1ea.png" 1> /dev/null 2>&1
#   fonts = {
#     packages = with pkgs; [
#       noto-fonts
#       noto-fonts-color-emoji
#       font-awesome
#       (nerdfonts.override { fonts = [ "Meslo" ]; })
#     ];
#     fontconfig = {
#       enable = true;
#       defaultFonts = {
#         monospace = [ "Meslo LG M Regular Nerd Font Complete Mono" ];
#         serif = [ "Noto Serif" ];
#         sansSerif = [ "Noto Sans" ];
#       };
#     };
#   };
#\n#   # OpenSSH is forced to have an empty `wantedBy` on the installer system[1], this won't allow it
#   # to be automatically started. Override it with the normal value.
#   # [1] https://github.com/NixOS/nixpkgs/blob/9e5aa25/nixos/modules/profiles/installation-device.nix#L76
#   systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];
#\n#   system.stateVersion = "25.05";
#\n#   # users.users.matthew.extraGroups = [ "video" ];
#\n#   # nix = {
#   #   # From flake-utils-plus
#   #   generateNixPathFromInputs = true;
#   #   generateRegistryFromInputs = true;
#   #   linkInputs = true;
#   # };
#\n#   # networking = {
#   #   firewall = {
#   #     # Syncthing ports
#   #     allowedTCPPorts = [ 22000 ];
#   #     allowedUDPPorts = [ 21027 22000 ];
#   #   };
#   #   hostName = "t480";
#   #   useNetworkd = true;
#   #   wireless = {
#   #     userControlled.enable = true;
#   #     enable = true;
#   #     interfaces = [ "wlp3s0" ];
#   #   };
#   #   useDHCP = false;
#   #   interfaces = {
#   #     "enp0s31f6".useDHCP = true;
#   #     "wlp3s0".useDHCP = true;
#   #   };
#   # };
#\n#   # services = {
#   #   udev.extraRules = ''
#   #     # Nreal Air Glasses
#   #     SUBSYSTEMS=="usb", ATTRS{idVendor}=="3318", ATTRS{idProduct}=="0424", GROUP="input", MODE="0666"
#   #     # Gamecube Controller Adapter
#   #     SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", MODE="0666"
#   #     # Xiaomi Mi 9 Lite
#   #     SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="05c6", ATTRS{idProduct}=="9039", MODE="0666"
#   #     SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="2717", ATTRS{idProduct}=="ff40", MODE="0666"
#   #   '';
#   #   thermald.enable = true;
#   #   tlp = {
#   #     enable = true;
#   #     settings = {
#   #       PCIE_ASPM_ON_BAT = "powersupersave";
#   #       CPU_SCALING_GOVERNOR_ON_AC = "performance";
#   #       CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
#   #       CPU_MAX_PERF_ON_AC = "100";
#   #       CPU_MAX_PERF_ON_BAT = "30";
#   #       STOP_CHARGE_THRESH_BAT1 = "95";
#   #       STOP_CHARGE_THRESH_BAT0 = "95";
#   #     };
#   #   };
#   #   logind.killUserProcesses = true;
#   # };
#\n#   # hardware = {
#   #   opengl.enable = true;
#   #   trackpoint = {
#   #     enable = true;
#   #     sensitivity = 255;
#   #   };
#   # };
# }
#\n# # Enable dconf
# # programs.dconf.enable = true;
#\n# # environment.gnome.excludePackages = (with pkgs; [
# #   gnome-photos
# #   gnome-tour
# # ]) ++ (with pkgs.gnome; [
# #   cheese # webcam tool
# #   gnome-music
# #   gnome-terminal
# #   gedit # text editor
# #   epiphany # web browser
# #   geary # email reader
# #   evince # document viewer
# #   gnome-characters
# #   totem # video player
# #   tali # poker game
# #   iagno # go game
# #   hitori # sudoku game
# #   atomix # puzzle game
# # ]);
#\n# # Many applications rely heavily on having an icon theme available, GNOME’s Adwaita is a good choice but most recent icon themes should work as well.
# # environment.systemPackages = [ gnome.adwaita-icon-theme ];
# # Systray Icons
# # environment.systemPackages = with pkgs; [ gnomeExtensions.appindicator ];
# # services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
#\n# # gnome.gnome-tweaks
#\n# # gnome3.gnome-tweak-tool
# # gnome3.evince # pdf reader
# # # extensions
# # gnomeExtensions.appindicator
# # gnomeExtensions.dash-to-dock
# # gnomeExtensions.battery-status
#\n#\n# # systemd.services."getty@tty1".enable = false;
# # systemd.services."autovt@tty1".enable = false;
#\n# # Gnome cheatsheet:
# # https://wiki.gnome.org/Projects/GnomeShell/CheatSheet
#\n# # dconf watch /
# # dconf write /org/gnome/desktop/interface/color-scheme "'default'"
# # dconf.settings = {
# #   "org/gnome/desktop/interface" = {
# #     color-scheme = "prefer-dark";
# #   };
# # "org/gnome/shell" = {
# # disable-user-extensions = false;
#\n# # # `gnome-extensions list` for a list
# # enabled-extensions = [
# #   "user-theme@gnome-shell-extensions.gcampax.github.com"
# #   "trayIconsReloaded@selfmade.pl"
# #   "Vitals@CoreCoding.com"
# #   "dash-to-panel@jderose9.github.com"
# #   "sound-output-device-chooser@kgshank.net"
# #   "space-bar@luchrioh"
# # ];
# #   favorite-apps = [
# #     "firefox.desktop"
# #     "code.desktop"
# #     "org.gnome.Terminal.desktop"
# #     "spotify.desktop"
# #     "virt-manager.desktop"
# #     "org.gnome.Nautilus.desktop"
# #   ];
# # "org/gnome/shell/extensions/user-theme" = {
# #   name = "palenight";
# # };
# # };
# # };
# # Also download extension packages from gnomeExtensions.user-themes etc
#\n# # $ dconf dump / > dconf.settings
#\n# # { lib, ... }:
# # let
# #   mkTuple = lib.hm.gvariant.mkTuple;
# # in
# # {
# #   dconf.settings = {
# #     "org/gnome/desktop/peripherals/mouse" = {
# #       "natural-scroll" = false;
# #       "speed" = -0.5;
# #     };
#\n# #     "org/gnome/desktop/peripherals/touchpad" = {
# #       "tap-to-click" = false;
# #       "two-finger-scrolling-enabled" = true;
# #     };
#\n# #     "org/gnome/desktop/input-sources" = {
# #       "current" = "uint32 0";
# #       "sources" = [ (mkTuple [ "xkb" "us" ]) ];
# #       "xkb-options" = [ "terminate:ctrl_alt_bksp" "lv3:ralt_switch" "caps:ctrl_modifier" ];
# #     };
#\n# #     "org/gnome/desktop/screensaver" = {
# #       "picture-uri" = "file:///home/gvolpe/Pictures/nixos.png";
# #     };
# #   };
# # }
# # dconf2nix
#\n# # installGnomeSessionScript = pkgs.writeShellScriptBin "install-gnome-session" ''
# #   sudo ln -fs ${pkgs.gnome.gnome-session.sessions}/share/wayland-sessions/gnome.desktop /usr/share/wayland-sessions/gnome.desktop
# # '';
#\n# # home.packages = [ installGnomeSessionScript ];
#\n# # TODO: implement pipewire with wireplumber + alsa, pulse, jack etc
