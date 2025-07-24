# Maybe I need: pkgs.linux-firmware on hardware.firmware?
{ config, lib, pkgs, inputs, ... }:
{ 
  imports = with inputs.self.nixosModules; [ 
    ./hardware-configuration.nix 
    ./services.nix
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

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 25;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.package = pkgs.nixVersions.latest;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  nix.gc.automatic = true;
  nix.gc.dates = "monthly";
  nix.gc.options = "--delete-older-than 50d";

  nixpkgs.config.allowUnfree = true;

  # Pick only one of the below networking options.
  # networking.wireless.enable = true; # Enables wireless support via wpa_supplicant. 
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  networking.hostName = "omnibook";
  # Configure network proxy if necessary networking.proxy.default = "http://user:password@proxy:port/"; networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  systemd.services.NetworkManager-wait-online.enable = false; # Workaround for an update problem

  time.timeZone = "Europe/Amsterdam";

  i18n.defaultLocale = "en_US.UTF-8";
  # console = { font = "Lat2-Terminus16"; keyMap = "us"; useXkbConfig = true; # use xkb.options in tty. };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.groups.input = {};
  users.defaultUserShell = pkgs.zsh;
  users.users.izelnakri = { 
   isNormalUser = true; 
   password = "corazon";
   extraGroups = [ "kvm" "wheel" "input" "uinput" "render" "video" "scanner" "lp" ]; # NOTE: what if I removed "bitbox"
  };

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

  environment.systemPackages = with pkgs; [
    android-studio
    uv

    linuxKernel.packages.linux_6_15.iio-utils # is it needded for the sensor info?

    # unstable.ocl-icd # OpenCL ICD Loader for opencl-headers-2024.10.24
    # unstable.opencl-headers # opencl-headers-2024.10.24

    intel-gpu-tools # provides lsgpu
    # maybe vpl-gpu-rt for video processing
    # unstable.llama-cpp

    # unstable.openvino # has cudaSupport option! , TODO: research this further
    unstable.intel-compute-runtime
    # python312Packages.optimum # trying to see if this converts to intel optimized models via optimum-cli

    copyq # Temporarily added for VM clipboard share test
    wget 
    curl
    kitty
    git
    home-manager
    brave
    script-directory
    sd-switch
    unstable.iio-sensor-proxy # NOTE: check later if this is needed
    # inputs.iio-hyprland.packages.${pkgs.system}.default # check the version

    # https://github.com/nix-community/nix-ld?tab=readme-ov-file#my-pythonnodejsrubyinterpreter-libraries-do-not-find-the-libraries-configured-by-nix-ld
    # (pkgs.writeShellScriptBin "python" ''
    #   export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
    #   exec ${pkgs.python3}/bin/python "$@"
    # '')
  ];

  # Open ports in the firewall. 
  # networking.firewall.allowedTCPPorts = [ ... ]; 
  # networking.firewall.allowedUDPPorts = [ ... ]; 
  # networking.firewall.enable = false; # Or disable the firewall altogether.

  system.stateVersion = "25.05";

  powerManagement.powertop.enable = true;

  programs.alvr.enable = true;
  programs.alvr.openFirewall = true;

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
  programs.java.enable = true;
  programs.mdevctl.enable = true;
  programs.nix-ld = {
    enable = true;
    # NOTE: probably enable this:
    # libraries = with pkgs; [
    #   zlib zstd stdenv.cc.cc curl openssl attr libssh bzip2 libxml2 acl libsodium util-linux xz systemd
    # ];
  };

  # programs.steam = {
  #   enable = true;
  #   remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
  #   dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  #   localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  # };

  services.btrfs.autoScrub = { 
    enable = true; 
    interval = "monthly"; 
    fileSystems = [ "/" ]; 
  };

  services.udev.extraRules = ''
    # xremap needs this:
    KERNEL=="uinput", GROUP="input", TAG+="uaccess"
  '';

  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.gnome.enable = true;
    videoDrivers = [ "modesetting" ]; # NOTE: should this be "intel-neo" instead?
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
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true; # Create a `docker` alias for podman, to use it as a drop-in replacement
      defaultNetwork.settings.dns_enabled = true; # Required for containers under podman-compose to be able to talk to each other.
    };
    waydroid.enable = true;
  };

  # TODO: DO this with flake-project backend and test it on the systemd
  # virtualisation.oci-containers.backend = "podman";
  # virtualisation.oci-containers.containers = {
  #   container-name = {
  #     image = "container-image";
  #     autoStart = true;
  #     ports = [ "127.0.0.1:1234:1234" ];
  #   };
  # };
}
