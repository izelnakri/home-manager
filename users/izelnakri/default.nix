# do the base color consistency

# Add alacritty, nvim, tmux, zsh config
{ config, pkgs, inputs, ... }:
{
  imports = [
    inputs.nix-colors.homeManagerModules.default
  ];

  colorScheme = inputs.nix-colors.colorSchemes.gruvbox-dark-medium;

  # targets.genericLinux.enable = true;
  nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = (_: true);

  home.username = "izelnakri";
  home.homeDirectory = "/home/izelnakri";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [
    # alacritty
    # bspwm
    # dmenu
    # elinks - text based web browser, is it the best(?)
    # eww - Widget library for unix
    # flameshot
    inputs.nixpkgs.legacyPackages.x86_64-linux.brave
    chromium
    comma
    deno
    # dunst
    # dwm
    # emacs29
    # emacs-doom
    elixir_1_15
    # helix
    flatpak
    fontconfig
    freetype
    gcc
    gh
    gimp
    # groff
    # joplin
    htop
    # hyprland
    # inkspace
    iperf
    kubectl
    # kubectl-tree
    kubernetes
    kubernetes-helm
    # ktop
    # lens
    lf
    lsd
    lsof
    lxc
    lxcfs
    lxd
    # lutris
    ripgrep
    rsync
    fd
    fx
    bat
    fzf
    # w3m
    magic-wormhole
    mpv
    neofetch
    neovim
    # nfs-utils
    ninja
    nixos-rebuild
    ngrok
    nodejs
    mako
    # manix
    openssl
    # pavucontrol
    # pgmodeler
    # postman
    pass
    postgresql
    python3Full
    # python.pkgs.pip
    # rofi - dmenu replacement, window switcher
    rpiplay
    ruby
    rustup
    # sc
    # sxiv
    # synergy
    # swaycons
    syncthing
    terminus-nerdfont
    tldr
    # timeshift
    tmux
    # touchegg
    # transmission
    # trash-cli
    qemu
    # playonlinux
    # variety
    unzip
    unixtools.nettools
    wget
    vlc
    # xfce.thunar
    zathura

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
    # (pkgs.runCommand "ls-colors" {} ''
    #  mkdir -p $out/bin $out/share
    #  ln -s ${pkgs.coreutils}/bin/ls $out/bin/ls
    #  ln -s ${pkgs.coreutils}/bin/dircolors $out/bin/dircolors
    #  cp ${../../static/LS_COLORS} $out/share/LS_COLORS
    # '')
  ];

  #  nixpkgs.overlays = [
  #   (final: prev: {
  #     dwm = prev.dwm.overrideAttrs (old: { src = /home/titus/GitHub/dwm-titus ;});
  #   })
  # ];

  home.file = {
    # TODO: add colors file for other programs & reference.
    # source to copy or file
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
    BROWSER = "brave";
    EDITOR = "nvim";
    ELIXIR_ERL_OPTIONS = "+fnu";
    ERL_AFLAGS = "-kernel shell_history enabled -kernel shell_history_file_bytes 1024000";
    FZF_DEFAULT_COMMAND = "fd --type f";
    GDK_SCALE = 2;
    # LF_ICONS
    MANPAGER= "bat -l man -p";
    HISTTIMEFORMAT= "%d/%m/%y %T ";
    HISTFILE= "~/.cache/zsh/history";
    TERMINAL = "alacritty";
    POSTGRES_USER = "postgres";
    POSTGRES_PASSWORD = "postgres";
    POSTGRES_HOST = "localhost";
    POSTGRES_PORT = 5432;
    # PGUSER= $POSTGRES_USER
    # PGPASSWORD= $POSTGRES_PASSWORD
    # PGHOST= $POSTGRES_HOST
    # PGPORT= $POSTGRES_PORT
    VOLTA_HOME = "$HOME/.volta";
    PATH = "$HOME/.rbenv/shims:$HOME/.rbenv/bin:$HOME/.cargo/bin:$HOME/.deno/bin:$HOME/.local/bin:/usr/local/bin:/usr/sbin:$PATH";
    TERM = "xterm-256color";
    # ZSH_AUTOSUGGEST_STRATEGY = (history completion)
  };

  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      userName = "Izel Nakri";
      userEmail = "contact@izelnakri.com";
      aliases = {
        pu = "push";
        co = "checkout";
        cm = "commit";
      };
    };

    # gtk = {
    #   enable = true;
    #   theme.name = "adw-gtk3";
    #   cursorTheme.name = "Bibata-Modern-Ice";
    #   iconTheme.name = "GruvboxPlus";
    # };

    # xdg.mimeApps.defaultApplications = {
    #   "text/plain" = [ "neovide.desktop" ];
    #   "application/pdf" = [ "zathura.desktop" ];
    #   "image/*" = [ "sxiv.desktop" ];
    #   "video/png" = [ "mpv.desktop" ];
    #   "video/jpg" = [ "mpv.desktop" ];
    #   "video/*" = [ "mpv.desktop" ];
    # }

    zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      initExtra = ''
        unsetopt INC_APPEND_HISTORY # Write to the history file immediately, not when the shell exits.
        setopt PROMPT_SUBST # Enable parameter expansion, command substitution and arithmetic expansion in the prompt.

        function cheat {
          curl cheat.sh/$argv
        }

        function display_jobs_count_if_needed {
          local job_count=$(jobs -s | wc -l | tr -d " ")

          if [ $job_count -gt 0 ]; then
            echo "%B%{$fg[yellow]%}|%j| ";
          fi
        }

        # As in "delpod default"
        # As in "delpod <namespace>"
        function delpod {
          kubectl delete po --all -n $argv
        }

        function extract() {
            case "$1" in
                *.tar.bz|*.tar.bz2|*.tbz|*.tbz2) tar xjf "$1";;
                *.tar.gz|*.tgz) tar xzf "$1";;
                *.tar.xz|*.txz) tar xJf "$1";;
                *.zip) unzip "$1";;
                *.rar) unrar x "$1";;
                *.7z) 7z x "$1";;
            esac
        }

        # kill everything in a namespace
        function fuck {
          kubectl delete all --all -n $argv
        }

        function ix() {
            local opts
            local OPTIND
            [ -f "$HOME/.netrc" ] && opts='-n'
            while getopts ":hd:i:n:" x; do
                case $x in
                    h) echo "ix [-d ID] [-i ID] [-n N] [opts]"; return;;
                    d) $echo curl $opts -X DELETE ix.io/$OPTARG; return;;
                    i) opts="$opts -X PUT"; local id="$OPTARG";;
                    n) opts="$opts -F read:1=$OPTARG";;
                esac
            done
            shift $(($OPTIND - 1))
            [ -t 0 ] && {
                local filename="$1"
                shift
                [ "$filename" ] && {
                    curl $opts -F f:1=@"$filename" $* ix.io/$id
                    return
                }
                echo "^C to cancel, ^D to send."
            }
            curl $opts -F f:1='<-' $* ix.io/$id
        }

        function parse_git_branch {
          git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\ ->\ \1/'
        }

        autoload -U colors && colors
        # PS1 = '[\u@\h \W]\$ ';
        PROMPT='%{$fg[blue]%}$(date +%H:%M:%S) $(display_jobs_count_if_needed)%B%{$fg[green]%}%n %{$fg[blue]%}%~%{$fg[yellow]%}$(parse_git_branch) %{$reset_color%}';
      ''; # => .zshrc.
      shellAliases = {
        bitbox-bridge="/opt/bitbox-bridge/bin/bitbox-bridge"; # NOTE: is this still needed?
        checkrepo = "git log --pretty=format: --name-only | sort | uniq -c | sort -rg | head -10";
        d = "sudo docker";
        diff = "diff --color=auto";
        dockerremoveall = "sudo docker system prune -a";
        e = "helix";
        g = "git";
        grep = "grep --color=auto";
        home-manager-docs = "chromium ~/Desktop/gifs/home-manager.html";
        k = "kubectl";
        kube = "kubectl";
        ls = "ls --color=auto -F";
        lf = "lfub";
        lusd = "node /home/izelnakri/cron-jobs/curve-lusd.js"; # NOTE: maybe move to cmd
        onport = "ps aux | grep";
        open = "xdg-open";
        pbcopy = "xclip -selection clipboard"; # TODO: move away from xclip
        pbpaste = "xclip -selection clipboard -o";
        scitutor = "sc /usr/share/doc/sc/tutorial.sc";
        server = "mix phoenix.server";
        SS = "sudo systemctl";
        speedtest = "curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -";
        terminate = "lsof -ti:4200 | xargs kill";
        todo = "nvim ~/Dropbox/TODO.md";
        v = "$EDITOR";
        vi = "nvim";
        vim = "nvim";
        weather = "curl http://wttr.in/";
        YT = "youtube-viewer";
        x = "sxiv -ft *";
      };
      # shellGlobalAliases = {

      # }; # => Similar to programs.zsh.shellAliases, but are substituted anywhere on a line.
      # envExta = ''
      #   export SOMEZSHVARIABLE="something"
      # '';
    };
  };

  # services.mako = with config.colorScheme.colors; {
  #   enable = true;
  #   backgroundColor = "#${base01}";
  #   borderColor = "#${base0E}";
  #   borderRadius = 5;
  #   borderSize = 2;
  #   textColor = "#${base04}";
  #   layer = "overlay";
  # };
}
