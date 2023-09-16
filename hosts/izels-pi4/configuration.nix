{ pkgs, config, lib, ... }:
{
  environment.systemPackages = with pkgs; [ vim git bat ];
  users = {
    users.izelspi = {
      password = "coolie";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };
  networking = {
    hostName = "izels-pi4";
    interfaces."wlan0".useDHCP = true;
    wireless = {
      interfaces = [ "wlan0" ];
      enable = true;
      networks = {
        UC_wifi_2d.psk = "L0v31sth3k3y-2D";
      };
    };
  };
  services = {
    openssh.enable = true;
    timesyncd.enable = true;
  };

  system.stateVersion = "23.05";

  # OpenSSH is forced to have an empty `wantedBy` on the installer system[1], this won't allow it
  # to be automatically started. Override it with the normal value.
  # [1] https://github.com/NixOS/nixpkgs/blob/9e5aa25/nixos/modules/profiles/installation-device.nix#L76
  # systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];
}
