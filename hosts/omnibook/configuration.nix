# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config, lib, pkgs, inputs, ... }:
{ 
  imports = with inputs.self.nixosModules; [ 
    ./hardware-configuration.nix 
    # move systemd and virtualization to a new file
  ];

  boot.loader.systemd-boot.enable = true; # Use the systemd-boot EFI boot loader.
  boot.loader.efi.canTouchEfiVariables = true;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
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
  users.groups.bitbox = {};
  users.defaultUserShell = pkgs.zsh;
  users.users.izelnakri = { 
   isNormalUser = true; 
   password = "corazon";
   extraGroups = [ "wheel" "input" "bitbox" ]; # Enable ‘sudo’ for the user.
  };

  home-manager = {
    useGlobalPkgs = true;
    users = import "${inputs.self}/users";
    extraSpecialArgs = {
      inherit inputs;
      headless = false;
    };
  };

  programs.firefox.enable = true;

  environment.variables = {
    EDITOR = "nvim";
  };

  # List packages installed in system profile. To search, run: $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget 
    curl
    kitty
    git
    home-manager
    brave
    script-directory # maybe required
    sd-switch
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

  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;
  programs.zsh.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  powerManagement.powertop.enable = true;

  services.btrfs.autoScrub = { 
    enable = true; 
    interval = "monthly"; 
    fileSystems = [ "/" ]; 
  };

  # TODO: maybe also need to add bitbox group or create user(s)
  services.udev.extraRules = ''
    # xremap needs this:
    KERNEL=="uinput", GROUP="input", TAG+="uaccess"

    # BitBox2 needs BB01 rule:
    SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2402", TAG+="uaccess", TAG+="udev-acl", SYMLINK+="dbb%n"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2402", TAG+="uaccess", TAG+="udev-acl", SYMLINK+="dbbf%n"

    # BitBox2 needs BB02 rule:
    SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2403", TAG+="uaccess", TAG+="udev-acl", MODE="0660", GROUP="bitbox", SYMLINK+="bitbox02-%n"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2403", TAG+="uaccess", TAG+="udev-acl", MODE="0660", GROUP="bitbox", SYMLINK+="bitbox02-f%n"
  '';

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
    taskchampion-sync-server.enable = true;
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
