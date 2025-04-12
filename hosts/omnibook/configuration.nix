# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config, lib, pkgs, inputs, ... }:
{ 
  imports = with inputs.self.nixosModules; [ 
    ./hardware-configuration.nix 
    ./services.nix
    # move systemd and virtualization to a new file
  ];

  # TODO: Try and maybe remove these:
  security.soteria.enable = true;
  # security.polkit.extraConfig = ''
  #   polkit.addRule(function(action, subject) {
  #     if (action.id.indexOf("net.hadess.SensorProxy") == 0) { 
  #       return polkit.Result.YES; 
  #     }
  #   });
  # '';


  boot.loader.systemd-boot.enable = true; # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.configurationLimit = 25;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  nix.gc.automatic = true;
  nix.gc.dates = "monthly";
  nix.gc.options = "--delete-older-than 50d";

  nixpkgs.config.allowUnfree = true;
  # nixpkgs.config.allowUnfreePredicate = _: true;
  # nixpkgs.config.allowBroken = true;

  # Pick only one of the below networking options.
  # networking.wireless.enable = true; # Enables wireless support via wpa_supplicant. 
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  networking.hostName = "omnibook"; # Define your hostname.
  # Configure network proxy if necessary networking.proxy.default = "http://user:password@proxy:port/"; networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  systemd.services.NetworkManager-wait-online.enable = false; # Workaround for an update problem

  time.timeZone = "Europe/Amsterdam"; # Set your time zone.

  i18n.defaultLocale = "en_US.UTF-8";
  # console = { font = "Lat2-Terminus16"; keyMap = "us"; useXkbConfig = true; # use xkb.options in tty. };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.groups.input = {};
  # users.groups.bitbox = {};
  users.defaultUserShell = pkgs.zsh;
  users.users.izelnakri = { 
   isNormalUser = true; 
   password = "corazon";
   extraGroups = [ "wheel" "input" "bitbox" "uinput" "render" "video" ];
  };
  # users.users.bitbox = {
  #   group = "bitbox";
  #   description = "bitbox-bridge daemon user";
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" "input" "bitbox" ]; # Enable ‘sudo’ for the user.
  # };

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    users = import "${inputs.self}/users";
    extraSpecialArgs = {
      inherit inputs;
      headless = false;
    };
  };

  environment.variables = {
    EDITOR = "nvim";
  };
  # List packages installed in system profile. To search, run: $ nix search wget
  environment.systemPackages = with pkgs; [
    uv

    unstable.linuxKernel.packages.linux_6_14.iio-utils # is it needded for the sensor info?

    # unstable.ocl-icd # OpenCL ICD Loader for opencl-headers-2024.10.24
    # unstable.opencl-headers # opencl-headers-2024.10.24

    intel-gpu-tools # provides lsgpu
    # maybe vpl-gpu-rt for video processing
    unstable.llama-cpp

    unstable.openvino # has cudaSupport option! , TODO: research this further
    unstable.intel-compute-runtime
    python312Packages.optimum # trying to see if this converts to intel optimized models via optimum-cli

    neovim
    wget 
    curl
    kitty
    git
    home-manager
    brave
    script-directory # maybe required
    sd-switch
    unstable.iio-sensor-proxy # NOTE: check later if this is needed
    # inputs.iio-hyprland.packages.${pkgs.system}.default # check the version

    # https://github.com/nix-community/nix-ld?tab=readme-ov-file#my-pythonnodejsrubyinterpreter-libraries-do-not-find-the-libraries-configured-by-nix-ld
    (pkgs.writeShellScriptBin "python" ''
      export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
      exec ${pkgs.python3}/bin/python "$@"
    '')
  ];

  # Open ports in the firewall. 
  # networking.firewall.allowedTCPPorts = [ ... ]; 
  # networking.firewall.allowedUDPPorts = [ ... ]; 
  # Or disable the firewall altogether. 
  # networking.firewall.enable = false;

  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from, so changing it will NOT upgrade your system - see 
  # https://nixos.org/manual/nixos/stable/#sec-upgrading for how to actually do that.
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration, and migrated your data accordingly.
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11";

  powerManagement.powertop.enable = true;

  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;
  programs.iio-hyprland.enable = true;
  programs.zsh.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  programs.firefox.enable = true;
  programs.git.lfs.enable = true;
  programs.mdevctl.enable = true;
  programs.nix-ld = {
    enable = true;
    # NOTE: probably enable this:
    # libraries = with pkgs; [
    #   zlib zstd stdenv.cc.cc curl openssl attr libssh bzip2 libxml2 acl libsodium util-linux xz systemd
    # ];
  };

  services.btrfs.autoScrub = { 
    enable = true; 
    interval = "monthly"; 
    fileSystems = [ "/" ]; 
  };

  # TODO: maybe also need to add bitbox group or create user(s)
  services.udev.extraRules = ''
    # xremap needs this:
    KERNEL=="uinput", GROUP="input", TAG+="uaccess"
  '';

  # # BitBox2 needs BB01 rule:
  # SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2402", TAG+="uaccess", TAG+="udev-acl", SYMLINK+="dbb%n"
  # KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2402", TAG+="uaccess", TAG+="udev-acl", SYMLINK+="dbbf%n"
  #
  # # BitBox2 needs BB02 rule:
  # SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2403", TAG+="uaccess", TAG+="udev-acl", MODE="0660", GROUP="bitbox", SYMLINK+="bitbox02-%n"
  # KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2403", TAG+="uaccess", TAG+="udev-acl", MODE="0660", GROUP="bitbox", SYMLINK+="bitbox02-f%n"

  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  services.displayManager.autoLogin.user = "izelnakri";
  services.displayManager.defaultSession = "hyprland";
  services.displayManager.hiddenUsers = [ "root" ];

  services.printing.enable = true;

  # Enable sound. hardware.pulseaudio.enable = true; OR 
  services.pipewire = {
    enable = true; 
    pulse.enable = true;
  };

  services.libinput.enable = true; # Enable touchpad support (enabled default in most desktopManager).

  services = {
    # openssh.enable = true; # To enable openssh

    postgresql.enable = true;
    tailscale.enable = true;
    # taskchampion-sync-server.enable = true; # fails only on master branch
    # tlp.enable = true;
  };

  systemd.services = {
    tailscale-serve = {
      description = "Tailscale serve webserver";
      after = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.unstable.tailscale}/bin/tailscale funnel 9999";
        Restart = "always";
        RestartSec = "10";
      };
      wantedBy = [ "default.target" "webserver.service" ];
    };
  };

  # systemd.sockets = {
  #   tailscaled = {
  #     description = "timescaled Activation Socket";
  #     listenStreams = [ "/var/run/tailscale/tailscaled.sock" ];
  #   };
  # };

  virtualisation = {
    waydroid.enable = true;
  };
}
