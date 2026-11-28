{ pkgs, config, lib, inputs, ... }:
{
  imports = [
    ../../modules/raspberry-pi/firmware.nix
    ../../modules/raspberry-pi/rootfs.nix # fileSystems."/": pi4.rootFs = "ext4" | "btrfs"
    ../../modules/raspberry-pi/bt-autopair.nix # pi4.bluetooth.autoPair
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

  # ext4, not btrfs: nixpkgs builds btrfs images with mkfs.btrfs, which reads file owners
  # past fakeroot, so the image's /, /var and /nix/store were owned by uid 1000. systemd and
  # NetworkManager reject that (no tmpfiles, no Wi-Fi plugin, broken logins/Hyprland). The
  # ext4 builder (standard NixOS SD image path) produces root-owned files.
  # (fileSystems."/" now comes from modules/raspberry-pi/rootfs.nix; ext4 by default.
  #  btrfs works again via a fixed builder: images.pi4-nas-btrfs / pi4.rootFs = "btrfs".)
  # fileSystems."/" = {
  #   device = "/dev/disk/by-label/NIXOS_SD";
  #   fsType = "ext4";
  #   options = [ "noatime" ];
  # };
  # fileSystems."/" = {
  #   device = "/dev/disk/by-label/NIXOS_SD";
  #   fsType = "btrfs";
  #   options = [
  #     "compress=zstd"
  #     "noatime"
  #   ];
  # };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  # boot.initrd.supportedFilesystems = [ "btrfs" ];
  # boot.supportedFilesystems = [ "btrfs" ];

  nixpkgs.overlays = [
    # DisplayLink: the flake-wide overlay maps displaylink to nixpkgs-unstable (6.3). On the Pi
    # that would cross-build a second (unstable) toolchain. Instead: the stable 26.05 package
    # definition (shares this config's cross toolchain; it supports aarch64-linux) fed the same
    # 6.3 driver zip the omnibook uses (already in the store; requireFile can't download it).
    (final: prev: {
      displaylink = (prev.callPackage "${inputs.nixpkgs}/pkgs/os-specific/linux/displaylink" { }).overrideAttrs (_: {
        version = "6.3.0-48";
        src = prev.requireFile {
          name = "displaylink-630.zip";
          hash = "sha256-cmmFbHUnBgxRMhXOG1o2/vB02Oicq4m8qxPfNCrM4Jg=";
          url = "https://www.synaptics.com/products/displaylink-usb-graphics-software-ubuntu";
        };
      });
    })
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

  # DisplayLink USB docks/adapters (extra screens besides HDMI). nixos/modules/hardware/video/
  # displaylink.nix keys off videoDrivers: evdi kernel module + DisplayLinkManager (dlm.service).
  # No X server is enabled by this; Hyprland drives the evdi DRM card directly.
  services.xserver.videoDrivers = [ "displaylink" "modesetting" ];
  # (evdi initial_device_count=1 is in boot.extraModprobeConfig below.)

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

  # Log in on the HDMI console (tty1) and Hyprland starts. Not `exec`: if Hyprland exits
  # or crashes you drop back into this shell instead of a login loop. Ctrl+Alt+F2 = plain
  # console. (greetd/tuigreet would be nicer, but they're Rust: cross-building them pulls a
  # whole cross rustc + cups/ghostscript/ffmpeg chain, ~200 extra derivations.)
  # Config: ~/.config/hypr/hyprland.lua if you made one, else /etc/hypr/hyprland.lua
  # (static/.config/hypr/hyprland.conf adapted for the Pi: hosts/izels-pi4/files/).
  # start-hyprland is Hyprland's watchdog launcher (plain `Hyprland` warns about it).
  programs.zsh.loginShellInit = ''
    if [ "$(tty)" = /dev/tty1 ] && [ -z "$WAYLAND_DISPLAY" ] && [ -z "$NO_HYPRLAND" ]; then
      hyprcfg=~/.config/hypr/hyprland.lua
      [ -f "$hyprcfg" ] || hyprcfg=/etc/hypr/hyprland.lua
      # Pi 4 has two DRM cards: v3d (render-only, no outputs) and vc4 (HDMI). Hyprland may
      # grab v3d and fail with "can't open drm", so point it at the card with connectors.
      # Pi 4: card0 = v3d (render-only), card1 = vc4 (HDMI), evdi = DisplayLink. List every card
      # that has connectors (vc4 first = primary), skipping v3d.
      cards=""
      for c in /sys/class/drm/card[0-9]; do
        if ls -d "$c"/"''${c##*/}"-* >/dev/null 2>&1; then
          cards="''${cards:+$cards:}/dev/dri/''${c##*/}"
        fi
      done
      [ -n "$cards" ] && export AQ_DRM_DEVICES="$cards"
      echo "Starting Hyprland on ''${AQ_DRM_DEVICES:-?} with $hyprcfg (log: ~/.hyprland.log; NO_HYPRLAND=1 skips)"
      start-hyprland -- --config "$hyprcfg" >~/.hyprland.log 2>&1
      echo "Hyprland exited ($?). Last lines of ~/.hyprland.log:"; tail -n 15 ~/.hyprland.log
    fi
  '';
  # Lua: Hyprland 0.57's native config format, ported from static/.config/hypr/hyprland.lua
  # (the laptop runs it without config errors; the legacy .conf port showed an error overlay).
  environment.etc."hypr/hyprland.lua".source = ./files/hyprland.lua;
  # (the legacy hyprland.conf port was removed: 0.57 parses configs as Lua, "#" comments fail)
  # services.greetd = {
  #   enable = true;
  #   settings.default_session = {
  #     command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --cmd Hyprland";
  #     user = "greeter";
  #   };
  # };
  # ~/.zshrc stops zsh's interactive new-user menu on first login (created only if missing).
  systemd.tmpfiles.rules = [
    "f /home/izelnakri/.zshrc 0644 izelnakri users - # yours to edit; created on first boot"
  ];

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
    foot # terminal (Wayland-native, light: good fit for the Pi 4 GPU)
    tmux
    bluez # bluetoothctl
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
    # networkmanager: polkit lets this group manage connections, so nmtui/nmcli work without
    # sudo (on the Pi nmtui needed sudo).
    extraGroups = [ "wheel" "networkmanager" ]; # wheel: full root via sudo
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
  # mkForce: sd-image-aarch64.nix adds console=ttyS0 + console=ttyAMA0. On the Pi 4, ttyAMA0
  # is the PL011 UART wired to the Bluetooth chip; a kernel console + serial getty on it broke
  # Bluetooth ("hci0: command tx timeout ... Failed to set baudrate"). Everything else that
  # ended up in APPEND is kept explicitly (root=fstab: systemd initrd; loglevel: console log
  # level; lsm: security defaults).
  boot.kernelParams = lib.mkForce [
    "console=ttyS1,115200" # mini-UART on GPIO14/15 (enable_uart=1) for a USB-TTL cable
    "console=tty1" # HDMI, last = /dev/console
    "root=fstab"
    "loglevel=7"
    "lsm=landlock,yama,bpf"
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

  # Wi-Fi via NetworkManager (`nmtui` / `nmcli`). Do NOT force networking.wireless off: the
  # NetworkManager module enables it itself in D-Bus-controlled mode, and that's where its
  # wpa_supplicant comes from ("Failed to D-Bus activate wpa_supplicant service" otherwise).
  # networking.wireless.enable = lib.mkForce false;
  networking.networkmanager.wifi.powersave = false; # brcmfmac power-save drops connections
  # In the VM test NetworkManager listed Wi-Fi devices as "unmanaged", which also matches
  # nmtui refusing them on the Pi. Always manage Wi-Fi explicitly.
  networking.networkmanager.settings."device-wifi-managed" = {
    match-device = "type:wifi";
    managed = 1;
  };
  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=ES
    # One evdi (DisplayLink) card exists from boot, so Hyprland, started at login, already
    # includes it; the adapter attaches to it when plugged in. Same as the omnibook.
    options evdi initial_device_count=1
  '';

  # Bluetooth (BCM4345C0 on the PL011 UART; the mainline DTB already describes it and the
  # firmware ships in raspberrypi-wireless-firmware). Use `bluetoothctl`.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  # Paired to the Quest 3 as "Bluetooth 5.1 Keyboard" (classic BR/EDR). First time: put it in
  # pairing mode near the Pi; it pairs + trusts itself, then reconnects on its own afterwards.
  pi4.bluetooth.autoPair = [ "E6:7A:00:00:2C:8E" ];

  # Writes a hardware/network report to the FAT partition 2 min after boot, so it can be read
  # from the laptop's SD reader (no second screen or typing needed): /boot/pi4-diagnostics.txt
  systemd.timers.pi4-diagnostics = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnBootSec = "2min";
  };
  systemd.services.pi4-diagnostics = {
    description = "Write boot diagnostics to /boot/pi4-diagnostics.txt";
    path = with pkgs; [ coreutils gnugrep util-linux iproute2 networkmanager bluez systemd kmod ];
    serviceConfig.Type = "oneshot";
    script = ''
      # NixOS runs unit scripts with `set -e`; a grep without matches must not kill the report.
      set +e
      out=/boot/pi4-diagnostics.txt
      {
        echo "== $(date -Is) $(uname -r) boot $(cat /proc/sys/kernel/random/boot_id)"
        echo "== nmcli dev"; nmcli dev 2>&1
        echo "== nmcli -f GENERAL.STATE,GENERAL.REASON,GENERAL.DRIVER dev show wlan0"; nmcli -f GENERAL.STATE,GENERAL.REASON,GENERAL.DRIVER dev show wlan0 2>&1
        echo "== nmcli dev wifi list"; nmcli dev wifi list 2>&1 | head -15
        echo "== ip -br link"; ip -br link 2>&1
        echo "== lsmod (wifi/bt)"; lsmod | grep -iE 'brcm|bt|hci|cfg80211|sdhci|gpio' 2>&1
        echo "== dmesg (wifi/bt/mmc/firmware)"; dmesg | grep -iE 'brcm|mmc|wlan|firmware|hci|blue|pwrseq|gpio' | tail -60
        echo "== bluetoothctl list"; timeout 10 bluetoothctl list 2>&1
        echo "== systemctl --failed"; systemctl --failed --no-legend --plain 2>&1
        echo "== journal NetworkManager/wpa_supplicant/bluetooth"; journalctl -b -u NetworkManager -u wpa_supplicant -u bluetooth -o short-monotonic --no-pager 2>&1 | tail -60
        echo "== ~izelnakri/.hyprland.log"; tail -n 40 /home/izelnakri/.hyprland.log 2>&1
      } > "$out.tmp" 2>&1
      mv "$out.tmp" "$out"; sync
    '';
  };

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

  # Stable address on your tailnet, from any network (no LAN/mDNS needed): after first boot run
  # once `sudo tailscale up --hostname=izels-pi4` and open the printed login URL. Then
  # `ssh izelnakri@izels-pi4` works from every tailnet device (laptop, Fairphone, Omnibook).
  # FOSS alternative later: point the same client at a self-hosted Headscale (--login-server).
  services.tailscale = {
    enable = true;
    openFirewall = true; # WireGuard UDP port, for direct (non-relayed) connections
  };

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
