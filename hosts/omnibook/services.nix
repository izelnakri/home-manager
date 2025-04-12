{ config, lib, pkgs, modulesPath, ... }:
{
  config = {
    programs.mouse-actions.enable = true;
    programs.mouse-actions.autorun = true;

    services.blueman.enable = true;
    services.fwupd.enable = true;
    # services.bitbox-bridge.enable = true; # waiting for next release of NixOS
    services.flatpak.enable = true;
    services.geoclue2.enable = true;

    services.syncthing = {
      enable = true; # "127.0.0.1:8384"
      dataDir = "/home/izelnakri";
      # extraFlags

      settings.devices = {
        x1-carbon.id = "VBFHH4Q-BGXEOZW-APCJYRX-WHNOR76-MHSDIJJ-U4VI3UI-KVS3OXE-5VPXUQD";
        iphone.id = "3T64G4I-PHKIMK5-INKV4ME-EYSCSMZ-R5SFOMW-QVHOKMK-ZMXL3XR-FSCZGQS";
        zfold-5.id = "Q5I5S2N-PXTFL2N-O66NZCK-MFV7RFH-6R6ZIMU-WYOVGHR-RCGU6PQ-4F4JVQV";
      };

      settings.folders = {
        "~/Camera" = {
          id = "sm-f946b_mhwt-photos";
          label = "Camera";
          type = "receiveonly";
        };
        "~/Dropbox" = {
          id = "yxnc2-w3szt";
          label = "Dropbox";
        };
        "~/Desktop/gifs" = {
          id = "rvqje-s2k7n";
          label = "GIFS";
        };
      };

      user = "izelnakri";
      # settings.options
    };

    systemd.extraConfig = ''
      DefaultCPUAccounting=yes
      DefaultIOAccounting=yes
      DefaultIPAccounting=yes
      DefaultMemoryAccounting=yes
      DefaultTasksAccounting=yes
    '';
  };
}
