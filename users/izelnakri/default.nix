# Gitui customization(needs Ctrl-D, drop staged/unstaged file, proper edit window)
# make it compatible with snowflake standard

# For application launcher use tofi or rofi-wayland or anyrun, do Hyprland desktop portal
# https://wiki.hyprland.org/Useful-Utilities/Clipboard-Managers/
# TODO: Fix nvim copy/paste yanked thing cannot be pasted currently, and copied thing doesnt go to yanked stuff, only copy/paste works in insert mode, also yank pase across panels dont work
# http://wiki.hyprland.org/Useful-Utilities/Other/#automatically-mounting-using-udiskie
# make lightdm & gnome work with home-manager
# implement latte-dock(?) for hyprland

# implement git checkout

# implement touchscreen (do it on hosts/raspberry-pi)
# TODO: How to manage tokens secrets
# lazyvim

# do the base color consistency
# lib = to define helper variables

# cmus media player? or other
{ config, pkgs, inputs, lib, ... }: # nixosModules
let
  wrapNixGL = import ../../modules/functions/wrap-nix-gl.nix { inherit pkgs; };
  replaceColorReferences =
    import ../../modules/functions/replace-color-references.nix;
in rec {
  imports = [
    inputs.nix-colors.homeManagerModules.default
    inputs.xremap-flake.homeManagerModules.default
    # ../../modules/alacritty.nix
  ];

  colorScheme = inputs.nix-colors.lib.schemeFromYAML "parrots-of-paradise"
    (builtins.readFile ../../static/parrots-of-paradise.yaml);

  targets.genericLinux.enable = true;
  nixpkgs.config.allowBroken = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = (_: true);

  home.username = "izelnakri";
  home.homeDirectory = "/home/izelnakri";
  home.stateVersion = "23.11";
  home.activation = {
    # NOTE: This shouldnt be needed but unfortunately it is needed
    restartSystemdServices = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
      $DRY_RUN_CMD ${home.homeDirectory}/.nix-profile/bin/sd activation systemd-reset-services
    '';
  };
  home.packages = with pkgs; [
    # gnome.gnome-session
    (wrapNixGL gnome.gnome-shell) # NOTE: exclude packages(?)
    unstable.ripdrag
    # calcurse (maybe use rust version) (daemon sends notifications)
    lightdm
    asdf-vm
    atuin
    # avahi (network discovery & connection)
    bat
    unstable.brave # previous reference: inputs.nixpkgs.legacyPackages.x86_64-linux.brave-browser
    unstable.browsh
    direnv
    # devdocs-desktop
    # eww - Widget library for unix
    # flameshot # screenshot util, doesnt run yet on hyprland
    chromium
    comma
    # deno
    unstable.elixir_1_16
    # helix
    (wrapNixGL unstable.hyprlock)
    unstable.hypridle
    fd
    flatpak
    folks
    fontconfig
    freetype
    fx
    fzf
    gcc
    geoclue2
    gh
    gimp
    unstable.git-cliff
    unstable.gitui
    gpsd
    grim
    # groff
    # joplin
    htop
    (wrapNixGL unstable.hyprland)
    hyprpicker

    # inkspace
    inputs.xremap-flake.packages.${system}.default
    (wrapNixGL unstable.imagemagick)
    iperf
    unstable.ironbar
    kubectl
    # kubectl-tree
    kubernetes
    kubernetes-helm
    # ktop
    # lens
    libevdev
    libnotify
    localsend
    lsd
    lsof
    lxc
    lxcfs
    lxd
    lua
    unstable.luajitPackages.luarocks
    # lutris # play all games on linux
    monado
    magic-wormhole
    mpv # Default media player
    neofetch
    (nerdfonts.override { fonts = [ "Noto" ]; }) # maybe add Meslo
    networkmanagerapplet
    # nfs-utils
    ninja
    nixos-rebuild
    ngrok
    unstable.nh # amazing nh nix helper, search, diff, switch etc, nom shell/nom develop
    nodejs
    noto-fonts
    noto-fonts-emoji
    mako
    unstable.manix
    # mpd
    unstable.ollama
    openssl
    # pavucontrol
    # pgmodeler
    # postman
    pass
    # pipewire
    playerctl
    postgresql
    # unstable.pulumi-bin
    pspg
    python3Full
    # python.pkgs.pip
    # rofi - dmenu replacement, window switcher
    ripgrep
    rsync
    # w3m
    rpiplay
    ruby
    rustup
    # sc
    sd-switch
    # sxiv
    # synergy
    # swaycons
    slurp
    swappy
    swaylock
    swww # wallpaper: maybe use programs.wpaperd instead(?)
    syncthing
    terminus-nerdfont
    tree
    # timeshift
    unstable.tmux
    # touchegg
    # transmission
    # trash-cli
    unstable.tree-sitter
    qemu
    # playonlinux
    # variety
    unstable.ueberzugpp
    unzip
    unixtools.nettools
    xh # http tool
    watchman
    wget
    wl-clipboard
    wl-screenrec
    # wl-screenrec # high-perf screen recording tool
    viu # image viewer
    vlc
    vnstat
    volta
    # xfce.thunar
    unstable.yazi
    zathura
    zeal

    # inputs.agenix.packages.x86_64-linux.default

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    (pkgs.writeShellScriptBin "flash-card" ''
      set -e

      #Configuration
      FILE="$HOME/Dropbox/flashcard.csv"

      main() {
        IFS=$'||'; read -a q <<<$(shuf -n 1 "$FILE")
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

    # Display manager options: SDDM, GDM, LightDM | run first without a DM, use LY or Lemurs for TTY login?
    # lightdm-webkit-theme-litarvan

    # TODO: instead just do ls-colors git checkout to ~/.nix-profile/share/LS_COLORS
    # TODO: also checkout/pull this repo master branch to ~/.config/home-manager
    # TODO: check if this could be done offline
    # TODO: Fetch LS_COLORS remotely and then copy it to the Nix Store, how to do this sequential or parallel
    (pkgs.runCommand "ls-colors" { } ''
      mkdir -p $out/bin $out/share
      cp ${../../static/LS_COLORS} $out/share/LS_COLORS
    '')
  ];

  #  nixpkgs.overlays = [
  #   (final: prev: {
  #     dwm = prev.dwm.overrideAttrs (old: { src = /home/titus/GitHub/dwm-titus ;});
  #   })
  # ];

  home.file = {
    "/.local/share/applications/Alacritty.desktop".text = ''
      [Desktop Entry]
      Terminal=false
      Type=Application
      Name=Alacritty Terminal
      Exec=/home/izelnakri/.nix-profile/bin/alacritty
    '';
    ".profile".source = ../../static/.profile;
    ".tmux.conf".source = ../../static/.config/tmux/tmux.conf;
    "scripts".source = ../../static/scripts;

    # TODO: add colors file for other programs & reference.

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh or /etc/profiles/per-user/izelnakri/etc/profile.d/hm-session-vars.sh
  home.sessionVariables = rec {
    BROWSER = "brave-browser";
    EDITOR = "nvim";
    OPENER = "xdg-open";
    ELIXIR_ERL_OPTIONS = "+fnu";
    ERL_AFLAGS =
      "-kernel shell_history enabled -kernel shell_history_file_bytes 1024000";
    FZF_DEFAULT_COMMAND = "fd --type f";
    GDK_SCALE = 2;
    # LANG = "en_US.UTF-8";
    # LC_ALL = "en_US.UTF-8";
    MANPAGER = "bat -l man -p";
    HISTTIMEFORMAT = "%d/%m/%y %T ";
    HISTFILE = "~/.cache/zsh/history";
    TERM = "xterm-256color";
    TERMINAL = "alacritty";
    BIN_PATHS =
      "$HOME/.volta/bin:$HOME/.cargo/bin:$HOME/.deno/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin";
    IZEL = "test";
    PATH = "${config.home.sessionVariables.BIN_PATHS}:$PATH";
    POSTGRES_USER = "postgres";
    POSTGRES_PASSWORD = "postgres";
    POSTGRES_HOST = "localhost";
    POSTGRES_PORT = 5432;
    PGUSER = POSTGRES_USER;
    PGPASSWORD = POSTGRES_PASSWORD;
    PGHOST = POSTGRES_HOST;
    PGPORT = POSTGRES_PORT;
    VOLTA_HOME = "$HOME/.volta";

    # ZSH_AUTOSUGGEST_STRATEGY = (history completion)

    # Hint electron apps to use wayland, this probably blurs the text for now
    NIXOS_OZONE_WL = "1";
  };

  fonts.fontconfig.enable = true;

  programs = {
    alacritty = {
      enable = true;
      package = (wrapNixGL pkgs.unstable.alacritty);
    };

    atuin = {
      enable = true;
      enableZshIntegration = true;
      # flags & settings
    };
    # autorandr(?) -> probably not needed
    bat.enable = true;
    # borgmatic(?) -> probably not needed
    bottom.enable = true;
    browserpass.enable = true; # => just trying
    # chromium & settings(if needed, for extension & config)
    # comodoro # => check this
    dircolors = {
      enable = true;
      enableZshIntegration = true;
    };
    direnv = {
      enable = true;
      enableZshIntegration = true;
    };
    # eww -> use for building your own widgets
    # foot -> terminal, investigate

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    gh = {
      enable = true;
      settings.git_protocol = "ssh";
    };

    git = {
      enable = true;

      delta = {
        enable = true;
        options = {
          features = "decorations line-numbers";
          decorations = {
            hunk-header-style = "omit";
            line-numbers-left-format = "";
            line-numbers-right-format = "{np:^4}";
            file-style = "#EFAA32 #0d372d bold";
            file-decoration-style = "";
            hunk-header-decoration-style = "";
            navigate = true;
            hyperlinks = true;
            paging = "always";
            pager = "bat";
            # maybe add pager
            # tabs [maybe, default: 8]
          };
        };
      };
      attributes = [ "*.sqlite diff=sqlite3" ];
      userName = "Izel Nakri";
      userEmail = "contact@izelnakri.com";
      aliases = {
        pu = "push";
        co = "checkout";
        cm = "commit";
      };
      extraConfig = {
        diff = {
          colorMoved = "default";
          sqlite3 = {
            binary = true;
            textconv = "echo .dump | sqlite3";
          };
        };
      };
      # signing = {
      #   # key = "";
      #   signByDefault = true;
      # };
      # commit = {

      # };
      # TODO: enable signed commits
    };

    go.enable = true;
    gpg.enable = true; # NOTE: publicKeys ?
    helix.enable = true; # configure if needed
    home-manager.enable = true;
    htop.enable = true;

    xplr = {
      enable = true;
      extraConfig = ''
        require("wl-clipboard").setup {
          copy_command = "wl-copy -t text/uri-list",
          paste_command = "wl-paste",
          keep_selection = true,
        }
      '';
      # extraConfig, plugins
    };
    joshuto = { # TODO: instead maybe use xplr
      enable = true;
      # keymap
      # mimetype
      # settings, theme
    };
    jq.enable = true;
    lazygit = {
      enable = true;
      package = pkgs.unstable.lazygit;
      # settings
    };
    ledger = {
      enable = true; # learn this, very interesting
      extraConfig = ''
        --sort date
        --effective
        --date-format %Y-%m-%d'';
      # settings = {
      #  date-format = "%Y-%m-%d";
      #  file = [
      #    "~/finances/journal.ledger"
      #    "~/finances/assets.ledger"
      #    "~/finances/income.ledger"
      #  ];
      #  sort = "date";
      #  strict = true;
      # };
    };

    less.enable = true;

    lsd.enable = true;
    man.enable = true;
    mpv = { enable = true; };
    ncspot.enable = true;
    neomutt.enable = true;
    neovim = { # TODO: BIG CONFIG DO it here from nixcfg
      enable = true;
      package = pkgs.unstable.neovim-unwrapped;
      # coc.enable = true;
      # coc.settings , suggest.enablePreview, languageserver
      defaultEditor = true;
      # extraLuaPackages
      # plugins
      viAlias = true;
      vimAlias = true;
      withNodeJs = true;
    };
    noti.enable = true; # also configure
    # obs-stuudio
    pandoc.enable = true;
    # password-store, settings,
    # pidgin, pistol, wcal, rbw/bitwarden, rio, vdirsyncer(calendar, contact sync)
    ripgrep.enable = true;
    rio = {
      enable = true;
      settings = { performance = "Low"; };
    };

    # rofi vs dmenu
    rtx = { # asdf replacement
      enable = true;
      enableZshIntegration = true;
      # settings
    };
    script-directory = {
      enable = true;
      settings = {
        SD_ROOT = "${config.home.homeDirectory}/scripts";
        SD_EDITOR = "nvim";
        SD_CAT = "bat";
      };
    };
    # fzf replacement: skim?
    skim = {
      enable = true;
      enableZshIntegration = true;
    };

    swaylock = { enable = true; };

    tealdeer.enable = true;

    tiny = {
      enable = true;
      settings = {
        servers = [{
          addr = "irc.libera.chat";
          port = 6697;
          tls = true;
          realname = "Izel Nakri";
          nicks = [ "izelnakri" ];
        }];
        defaults = {
          nicks = [ "izelnakri" ];
          realname = "Izel Nakri";
          join = [ ];
          tls = true;
        };
      };
    };

    translate-shell = {
      enable = true;
      settings = {
        hl = "en";
        tl = [ "es" "fr" ];
      };
    };

    waybar =
      { # Inspiration: https://forum.garudalinux.org/uploads/default/optimized/2X/d/d8407cbcc1d56f99f37bd7da681348ace09058e1_2_1380x862.jpeg
        enable = true;
        # package
        # battery, bluetooth, clock, CPU, Disk, Memory, MPD, Network, PulseAudio, Temperature/Weather,
        # Hyprland, idle_inhibitor(!?), sndio(?), sway, check tray, taskbar(?)
        # On left: Workspaces
        # also add flux indicator
        # onclick pavucontrol(?) -> pulseaudio
        # start_hidden = true;
        # height, spacing,
        # modules-left = ["sway/workspaces" "sway/mode"];
        # modules-center = ["sway/window"];
        # modules hyprland  https://github.com/Alexays/Waybar/wiki/Module:-Hyprland
        # sway/window = {
        #     "max-length": 50;
        # };
        # battery = {
        #     format = "{capacity}% {icon}";
        #     format-icons = ["" "" "" "" ""];
        # };
        # clock = {
        #   format-alt = "{:%a, %d. %b  %H:%M}";
        # };
        settings = [
          (builtins.fromJSON
            (builtins.readFile ../../static/.config/waybar/config))
        ];
        style = builtins.readFile ../../static/.config/waybar/style.css;
        systemd.enable = true;
      };

    wlogout = { enable = true; };

    yt-dlp.enable = true;
    zathura.enable = true; # mappings, options

    # lieer, notmuch, mutt, mbsync, mu, msmtp, mujmap, senpai, swaylock, taskwarrior, waybar, wlogout, wofi, qt

    zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      defaultKeymap = "viins";
      # historySubstringSearch = {
      # enable = true;
      # searchDownKey = [ "^J" "^[[B" ]; # Ctrl-J, TODO: during insert up/down doesnt work(?) fix it
      # searchUpKey = [ "^K" "^[[A" ]; # Ctrl-K
      # };
      syntaxHighlighting.enable = true;
      plugins = [{
        name = "vi-mode";
        src = pkgs.unstable.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }];

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

        PROMPT='%{$fg[blue]%}$(date +%H:%M:%S) $(display_jobs_count_if_needed)%B%{$fg[green]%}%n %{$fg[blue]%}%~%{$fg[yellow]%}$(parse_git_branch) %{$reset_color%}';
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#${config.colorScheme.palette.base03},bold";

        # NOTE: This adds quit-to-directory functionality to yazi
        function yy() {
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
          yazi "$@" --cwd-file="$tmp"
          if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            cd -- "$cwd"
          fi
          rm -f -- "$tmp"
        }

        # TODO: Find another way to get ahead of /$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin in the future:
        export PATH="$BIN_PATHS:$PATH"

        eval $(dircolors ~/.nix-profile/share/LS_COLORS)
        eval "$(direnv hook zsh)"

        # Maybe move this above: Edit line in vim with ctrl-e:
        autoload edit-command-line; zle -N edit-command-line
        bindkey '^e' edit-command-line

        # Temporary zvm hacks for yanking & history search stuff until zsh implements them:
        zvm_vi_yank () {
          zvm_yank
          echo "$CUTBUFFER" | wl-copy -n
          zvm_exit_visual_mode
        }
        zvm_after_lazy_keybindings() {
          bindkey -M vicmd '^k' up-line-or-search
          bindkey -M vicmd '^j' down-line-or-search
        }
        zvm_after_init_commands+=("bindkey '^k' up-line-or-search" "bindkey '^j' down-line-or-search")
      '';

      shellAliases = {
        bitbox-bridge = "/opt/bitbox-bridge/bin/bitbox-bridge";
        checkrepo =
          "git log --pretty=format: --name-only | sort | uniq -c | sort -rg | head -10";
        clip = "slurp | grim -g - - | wl-copy && wl-paste | swappy -f -";
        clip-record = ''wl-screenrec -g "$(slurp)" -f /tmp/recording.mp4'';
        colorpicker = "hyprpicker";
        d = "sudo docker";
        diff = "diff --color=auto";
        dockerremoveall = "sudo docker system prune -a";
        e = "helix";
        g = "yy";
        grep = "grep --color=auto";
        k = "kubectl";
        kube = "kubectl";
        ls = "ls --color=auto -F";
        lusd =
          "node /home/izelnakri/cron-jobs/curve-lusd.js"; # NOTE: maybe move to cmd
        onport = "ps aux | grep";
        open = "xdg-open";
        pbcopy = "xclip -selection clipboard"; # TODO: move away from xclip
        pbpaste = "xclip -selection clipboard -o";
        scitutor = "sc /usr/share/doc/sc/tutorial.sc";
        server = "mix phoenix.server";
        SS = "sudo systemctl";
        speedtest =
          "curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -";
        screenshot =
          "grim - | convert - -shave 1x1 PNG:- | wl-copy && wl-paste | swappy -f -";
        terminate = "lsof -ti:4200 | xargs kill";
        todo = "nvim ~/Dropbox/TODO.md";
        v = "$EDITOR";
        vi = "nvim";
        vim = "nvim";
        weather = "curl http://wttr.in/";
        YT = "youtube-viewer";
        x = "sxiv -ft *";
        gnome-wayland =
          "dbus-run-session -- gnome-shell --display-server --wayland";
        gitfetch = "onefetch";
      };
      # shellGlobalAliases # => Similar to programs.zsh.shellAliases, but are substituted anywhere on a line.
    };
  };

  services = {
    # flameshot.enable = true;
    # gpgagent = {
    #   enable = true;
    #   enableSSHSupport = true;
    #   enableZshIntegration = true;
    # }
    # syncthing

    # autorandr|kanshi, avizo|dunst|fnott|mako(?) - notification daemon, batsignal, betterlockscreen, borgmatic, comodoro
    # dropbox, dunst, dwm, etesync-dav(cal, contacts, tasks, notes), flameshot,fusuma(touchpad), gammastep(flux)|sctd|wlsunset,
    # getmail, git-sync, gpgp-agent, gromit, himalaya, kbfs, nextcloud|owncloud, pantalaimon
    # pass-secret-service, password-store-sync, pasystrat(pluseaudio tray), pbgopy(copy/paste between devices), plex
    # polybar(?), poweralertd, pueue, random-background, rsibreak|safeeyes, ssh-agent, swayidle, taskwarrior, unclutter
    # volnoti, xcape

    # mako = with config.colorScheme.colors; {
    #   enable = true;
    #   backgroundColor = "#${base01}";
    #   borderColor = "#${base0E}";
    #   borderRadius = 5;
    #   borderSize = 2;
    #   textColor = "#${base04}";
    #   layer = "overlay";
    # };

    avizo = {
      enable = true;
      # settings
    };

    # hypridle = {
    #   enable = true;

    #   listeners = [
    #     {
    #       timeout = 10;
    #       onTimeout = "${pkgs.unstable.hyprlock}";
    #     }
    #     {
    #       timeout = 20;
    #       onTimeout = "systemctl suspend";
    #     }
    #   ];
    # };

    # swayidle = {
    #   enable = true;
    #   # timeouts = [
    #   #   { timeout = 30000; command = "${pkgs.swaylock}/bin/swaylock -fF"; }
    #   # ];
    # };

    xremap = {
      watch = true;
      withWlroots = true;
      # debug = true;
      yamlConfig = builtins.readFile ../../static/.config/xremap/config.yml;
    };
  };

  gtk = {
    enable = true;
    # theme.name = "adw-gtk3";
    # cursorTheme.name = "Bibata-Modern-Ice";
    # iconTheme.name = "GruvboxPlus";
  };

  systemd = {
    user.startServices = "sd-switch";
    user.services = {
      hypridle = {
        Unit = {
          Description = "Hypridle deamon";
          After = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.unstable.hypridle}/bin/hypridle";
          Restart = "always";
          RestartSec = "10";
        };

        Install.WantedBy = [ "default.target" ];
      };
    };
    # user.services.example = {
    #   Unit = {
    #     Description = "Service example";
    #     PartOf = [];
    #     After = [];
    #   };
    #   Service = {
    #     Type = "simple";
    #     ExecStart = pkgs.writeShellScript "example.sh" ''
    #       #!/bin/sh
    #       while true; do sleep 5; echo 'hello'; exit 0;done
    #    '';
    #     Restart = "always";
    #   };
    #   Install.WantedBy = [];
    # };
  };

  # TODO: FIX SOUND for hyprland

  wayland = {
    windowManager.sway = {
      enable = true;
      package = (wrapNixGL pkgs.sway);
      # config
      # config.assigns, config.bars.*.colors.activeWorkspace
      # bars.*.colors.background
      # config.bars.*.command (fully customizable)
      # config.keybindings
      # config.keycodebindings
      # config.menu #-> launcher
      # config.modes
      # config.modifier, config.output
      # config.seat
      # config.startup
      # config.terminal
      # config.window
      # swaynag
    };
  };

  # TODO: Research this more
  xdg = {
    enable = true;

    configFile = {
      "alacritty/alacritty.toml".text = (replaceColorReferences
        (builtins.readFile ../../static/.config/alacritty/alacritty.toml)
        config.colorScheme.palette);
      "hypr" = {
        source = ../../static/.config/hypr;
        onChange = "~/.nix-profile/bin/hyprctl reload";
      };
      "ironbar".source = ../../static/.config/ironbar;
      "lazygit".source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/.config/home-manager/static/.config/lazygit";
      "mako/config".text = (replaceColorReferences
        (builtins.readFile ../../static/.config/mako/config)
        config.colorScheme.palette);

      "nvim".source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/.config/home-manager/static/.config/nvim";
      "gitui".source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/.config/home-manager/static/.config/gitui";
      "swappy/config".source = ../../static/.config/swappy/config;
      "system-colors.json".text = (builtins.toJSON config.colorScheme.palette);
      # "wlogout/config".source = ../../static/.config/wlogout/config; # https://github.com/nabakdev/dotfiles/blob/main/.config/wlogout/style.css
      "tmux/theme.conf".text = (replaceColorReferences
        (builtins.readFile ../../static/.config/tmux/theme.conf)
        config.colorScheme.palette);
      "waybar".source = ../../static/.config/waybar;
      "wlogout".source = ../../static/.config/wlogout;
      "yazi".source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/.config/home-manager/static/.config/yazi";
    };

    mimeApps = {
      enable = true;
      defaultApplications = {
        # TODO: js, css should open in brave
        # markdown should open in standalone markdown viewer app

        "text/plain" = "brave-browser.desktop";
        "text/html" = "brave-browser.desktop";
        "text/javascript" = "brave-browser.desktop";
        "text/css" = "brave-browser.desktop";
        "text/markdown" = "brave-browser.desktop";
        "application/json" = "brave-browser.desktop";
        "application/yaml" = "brave-browser.desktop";
        "application/toml" = "brave-browser.desktop";
        "text/*" = [ "brave-browser.desktop" ];
        "text/vnd.trolltech.linguist" = "brave-browser.desktop";
        # NOTE: Location: ~/.nix-profile/share/applications

        "application/pdf" =
          "brave-browser.desktop"; # NOTE: make it zathura or other document viewer?
        # "image/*" = [ "sxiv.desktop" ]; # NOTE: probably change sxiv to new one
        # "video/png" = [ "mpv.desktop" ];
        # "video/jpg" = [ "mpv.desktop" ];
        # "video/*" = [ "mpv.desktop" ];
        # "audio/*" = "org.gnome.Lollypop.desktop";
        # TOOO: office documents

        "x-scheme-handler/tg" = "telegramdesktop.desktop";
        "x-scheme-handler/http" = "brave-browser.desktop";
        "x-scheme-handler/https" = "brave-browser.desktop";
        "x-scheme-handler/ftp" = "brave-browser.desktop";
        "x-scheme-handler/chrome" = "brave-browser.desktop";
        "x-scheme-handler/about" = "brave-browser.desktop";
        "x-scheme-handler/unknown" = "brave-browser.desktop";
        "application/x-extension-htm" = "brave-browser.desktop";
        "application/x-extension-html" = "brave-browser.desktop";
        "application/x-extension-shtml" = "brave-browser.desktop";
        "application/xhtml+xml" = "brave-browser.desktop";
        "application/x-extension-xhtml" = "brave-browser.desktop";
        "application/x-extension-xht" = "brave-browser.desktop";
      };
    };

    # portal = {
    #   enable = true;
    #   extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    # };
    desktopEntries = {
      # alacritty = {
      #   name = "Alacritty";
      #   genericName = "GPU Terminal";
      #   exec = "nix run github:guibou/nixGL#nixGLIntel -- alacritty";
      #   actions = {
      #     "New Window" = {
      #       exec = "nix run github:guibou/nixGL#nixGLIntel -- alacritty";
      #     };
      #   };

      #   # actions.<name>.exec|icon|name
      #   # icon
      #   terminal = false;
      #   # categories = [ "Application" "Terminal" ];
      # };
    };
  };
  # Xft.dpi: 144
  # Xft.antialias: true
  # Xft.hinting: true
  # Xft.rgba: rgb
  # Xft.autohint: true
  # Xft.hintstyle: hintslight
  # Xft.lcdfilter: lcddefault

  #  builtins.readFile (
  #   pkgs.fetchFromGitHub {
  #     owner = "solarized";
  #     repo = "xresources";
  #     rev = "025ceddbddf55f2eb4ab40b05889148aab9699fc";
  #     sha256 = "0lxv37gmh38y9d3l8nbnsm1mskcv10g3i83j0kac0a2qmypv1k9f";
  #   } + "/Xresources.dark"
  # )

  manual.html.enable = true;
}

# check these:
# gnome3.gnome-tweak-tool
# control-center, applet, common, background, file-manager
# gnome.adwaita-icon-theme
# dconf.enable
# gnomeExtensions.appindicator
# gnome.gnome-settings-daemon

# # extensions
# gnomeExtensions.appindicator
# gnomeExtensions.dash-to-dock
# gdm or lightdm

# https://wiki.gnome.org/Projects/GnomeShell/CheatSheet
# Super+m: show notification list
# Super+a: show application grid
# Alt+Tab: cycle active applications
# Alt+` (the key above Tab on US keyboard layouts): cycle windows of the application in the foreground
# Alt+F2, then enter r or restart: restart the shell in case of graphical shell problems (only in X/legacy mode, not in Wayland mode).

# maybe add polkit-kde-agent as heavily suggested by hyprland, Qt Wayland support(?), xdg-desktop-portal-hyprland https://wiki.hyprland.org/Useful-Utilities/Hyprland-desktop-portal

# [Unit]
# Description=WPA supplicant
# Before=network.target
# After=dbus.service
# Wants=network.target
# IgnoreOnIsolate=true

# [Service]
# Type=dbus
# BusName=fi.w1.wpa_supplicant1
# ExecStart=/usr/bin/wpa_supplicant -u -s -O /run/wpa_supplicant

# [Install]
# WantedBy=multi-user.target
# Alias=dbus-fi.w1.wpa_supplicant1.service

# Sound configuration done outside of home-manager due to complex pipewire, alsa, pulse, jack setup with avizo
# bluez try this in nix first
# polkit might be necessary for swaylock(?)
