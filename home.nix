{ config, pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  home.username = "izelnakri";
  home.homeDirectory = "/home/izelnakri";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [
    # alacritty
    emacs29
    ripgrep
    fd
    bat
    fzf
    wget
    chromium
    neovim
    tmux
    mpv
    # gnumake
    htop
    # git
    # playonlinux
    lxc
    lxd
    lxcfs

    # inputs.agenix.packages.x86_64-linux.default

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    (pkgs.writeShellScriptBin "flash-card" ''
      set -e

      #Configuration
      FILE="''$HOME/Dropbox/flashcard.csv"

      main() {
        IFS=''$'||'; read -a q <<<$(shuf -n 1 "''$FILE")
        echo "========================================"
        echo "Category: ''${q[0]}"
        echo "Question: ''${q[2]}"
        read _
        echo "Answer: ''${q[4]}"
        echo ""
      }

      while true; do
        main
      done
    '')

    # TODO: Fetch LS_COLORS remotely and then copy it to the Nix Store, how to do this sequential or parallel
    (pkgs.runCommand "ls-colors" {} ''
     mkdir -p $out/bin $out/share
     ln -s ${pkgs.coreutils}/bin/ls $out/bin/ls
     ln -s ${pkgs.coreutils}/bin/dircolors $out/bin/dircolors
     cp ${./static/LS_COLORS} $out/share/LS_COLORS
    '')
  ];

  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh or /etc/profiles/per-user/izelnakri/etc/profile.d/hm-session-vars.sh
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.home-manager.enable = true;
}
