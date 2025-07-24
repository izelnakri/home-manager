{ config, lib, pkgs, modulesPath, ... }:
{
  config = {
    programs.mouse-actions.enable = true; # To enable accessibility shortcuts with mouse etc
    programs.mouse-actions.autorun = true;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    services.printing.enable = true;
    services.printing.drivers = [ pkgs.hplip ];

    services.blueman.enable = true;
    services.fwupd.enable = true;
    services.bitbox-bridge.enable = true;
    services.flatpak.enable = true;
    services.geoclue2.enable = true;

    services.hercules-ci-agent.enable = true;

    services.spice-vdagentd.enable = true; # NOTE: For future VM work

    # NOTE: For meta quest 3 streaming server
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };

    # NOTE: Just added now for clipboard sharing with VM:
    systemd.user.services.copyq = rec {
      script = "${pkgs.copyq}/bin/copyq";
      postStart = "${script} config item_data_threshold 8192";
      serviceConfig.Restart = "on-failure";
      environment.QT_QPA_PLATFORM = "xcb";
      wantedBy = [ "graphical-session.target" ];
    };

    # NOTE: if you want to enable ttyd web terminal:
    # services.ttyd = {
    #   enable = true;
    #   port = 61116;
    #   entrypoint = [
    #     (lib.getExe pkgs.zsh)
    #   ];
    #   user = "izelnakri";
    #   writeable = true;
    # };

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
      # settings.options

      user = "izelnakri";
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
