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
    # polkit.enable = true;
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
}
