# https://github.com/danth/stylix?tab=readme-ov-file
# android runtime bin(zygote), android compile bin, android opened bin(xdg-open | snapd-xdg-open), 
# flatpak(bubblejail run|generate-desktop-entry) | ~/.local/share/applications/$NAME.desktop

# ~/.config/openxr/1/active_runtime.json.
# so path: /nix/store/yf6z5bgff90kixmnp3l67vr9cd3dr8aa-home-manager-path/share/openxr/1/openxr_monado.so
# ~/.nix-profile/share/openxr/1/openxr_monado.json

# add to flatpak Steam(for SteamVR)

# syncall -> gcal, gtasks <> taskwarrior synchonization cli in python

# Dbus debugging:
# - dbus-monitor "type=error,sender='org.freedesktop.DBus'" --system
# - Qt D-Bus Viewer -> shows the API calls, allows you to initiate calls with single / double clicks -> right-click to connect to msg then see it in the logs. (very good)
# - Another one what was the name?!
# - dbus-run-session gnome-session
# - dbus-daemon dconf load / < ${iniFile}

# Bluetooth debugging:
# - bluez-utils
# zerotier
# Polkit:
# - .policy -> /usr/share/polkit-1/actions
# - .rules -> /usr/share/polkit-1/rules.d 3rd party | /etc/polkit-1/rules.d local config
# Polkit debugging: polkit-explorer-git
# pkaction | each setting has 6 variant is it on 3 defaults(? -> allow_any, allow_inactive, allow_active)
# pkcheck -a 'org.freedesktop.udisks2.open-device' -u -p $$

# systemd.packages = [
#   pkgs.gnome-settings-daemon
# ];

# services makes it registered to systemd . YES -> home-manager module makes it registered! Where is the one for gnome-notification-daemon? 
# Compare services.syncthing to services.gnome-notification-daemon, networkmanager
# check systembus-notify, avahi

# syncthingtray.service . HOW?! From nixpkgs(?) also can overlay commands
# fusuma: multitouch gestures, what is signaturepdf, avahi
# TODO: add gtk4 to deps after checking gnome-settings issue
# also check cosmic: https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=cosmic
# remind shell command: https://opensource.com/article/22/1/linux-desktop-notifications#:~:text=To%20send%20notifications%20from%20the,your%20package%20manager%20of%20choice.

# NOTE: Application runner rofi-wayland, wofi(gtk rofi), tofi, anyrun
# Element/Matrix client notifications. Libindicator+notifications for desktop, discord, matrix, calendar, sms

# Check Geary gnome mail client

# carbonyl text based browser
# git cliff integration(for paper_trail, also check lsp this way)
# Gitui customization(needs Ctrl-D, drop staged/unstaged file, proper edit window)
# make it compatible with snowflake standard

# For application launcher use tofi or rofi-wayland or anyrun, do Hyprland desktop portal
# https://wiki.hyprland.org/Useful-Utilities/Clipboard-Managers/
# TODO: Fix nvim copy/paste yanked thing cannot be pasted currently, and copied thing doesnt go to yanked stuff, only copy/paste works in insert mode, also yank pase across panels dont work
# http://wiki.hyprland.org/Useful-Utilities/Other/#automatically-mounting-using-udiskie
# make lightdm & gnome work with home-manager
# implement latte-dock(?) for hyprland
# task-warrior, thesaurust

# implement git checkout

# implement touchscreen (do it on hosts/raspberry-pi)
# How to manage tokens secrets?(nixos-anywhere)

# lib = to define helper variables

# cmus media player? or other
# make timesync correct
# TODO: Make vimwiki a private separate git repo, git cloned or fetched on each switch and new version pushed 
# Also while git fetch & push, do this for ~/.password-store as well

# NOTE: NixOS has nice syncthing API but not available on home-manager
{ config, pkgs, inputs, lib, ... }:
let
  system = "x86_64-linux"; # move to self.system or smt
  HOSTNAME = "omnibook"; # TODO: This has to be dynamically generated
  overlay-unstable = final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  };
  wrapNixGL = import ../../modules/functions/wrap-nix-gl.nix { inherit pkgs; };
  replaceColorReferences =
    import ../../modules/functions/replace-color-references.nix;
in rec {
  imports = [
    inputs.ironbar.homeManagerModules.default
    {
      programs.ironbar = {
        enable = true;
        # systemd = true; # probably remove
        config = "";
        # style = "";
        # package = inputs.ironbar; # NOTE: does this point to master branch(?)
        # features = [];
      }; # NOTE: Try to move this below
    }
    inputs.stylix.homeManagerModules.stylix
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
    # hyprland.homeManagerModules.default
    inputs.nix-colors.homeManagerModules.default
    inputs.xremap-flake.homeManagerModules.default
    # ../../modules/alacritty.nix
  ];

  colorScheme = inputs.nix-colors.lib.schemeFromYAML "parrots-of-paradise"
    (builtins.readFile ../../static/parrots-of-paradise.yaml);

  # TODO: add stylix | https://stylix.danth.me/configuration.html
  # stylix.base16Scheme = "../../static/parrots-of-paradise.yaml"

  targets.genericLinux.enable = true;

  home.username = "izelnakri";
  home.homeDirectory = "/home/izelnakri";
  home.stateVersion = "24.05";

  # home.activation = {
  #   # NOTE: This shouldnt be needed but unfortunately it is needed
  #   restartSystemdServices = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
  #     $DRY_RUN_CMD ${home.homeDirectory}/.nix-profile/bin/sd activation systemd-reset-services
  #   '';
  # };

  home.packages = with pkgs; [
    unstable.cowsay
    unstable.arion

    (wrapNixGL droidcam) # NOTE: maybe use scrcpy instead
    # libsForQt5.kdeconnect-kde
    # unstable.rustdesk # Build failed on unstable
    # unstable.rustdesk-server # Build failed on unstable

    unstable.flatpak

    # NOTE: Check pop-shell
    # (wrapNixGL unstable.gnome-online-accounts-gtk)
    unstable.systemctl-tui
    # calcurse (maybe use rust version) (daemon sends notifications)
    # Check: yt-dlp # maybe not needed due to ffmpeg feature
    (import ../../scripts/my-cowsay.nix { inherit pkgs; })
    d-spy
    unstable.dua
    libp11
    unstable.appimage-run

    alvr # streaming games
    steam

    # For scrcpy
    android-tools # for adb
    unstable.scrcpy
    # unstable.autoadb # this one is removed.
    unstable.wayvnc
    # === end scrcpy

    # For immersed:
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland

    unstable.krita

    obs-studio
    libva 
    vaapiVdpau 
    libvdpau-va-gl
    # === end immersed

    avahi # avahi-browse or avahi-resolve-host-name
    # adwaita-icon-theme
    (wrapNixGL unstable.gnome-shell)
    # gnome-shell-extensions
    # gnomeExtensions.gtk4-desktop-icons-ng-ding
    # gnome-desktop
    # gnome-settings-daemon
    # gnome-session-ctl
    (wrapNixGL unstable.gnome-session)
    # gnome-remote-desktop
    # gnome-notes
    # nettool, also sticky-notes, gnome-bluetooth(?), gnome-weather, smenu, d-spy, sysprof, devhelp
    unstable.gnome-calendar
    # gnome-clocks
    unstable.gnome-contacts
    unstable.gnome-control-center
    # dconf-editor
    # caribou # touchpad & pointers
    # gnome-maps
    # weather
    unstable.nautilus
    # gnome-bluetooth
    # gnome-backgrounds
    # gnome-applets
    # simple-scan
    # sushi
    # pomodoro
    # gnome-system-monitor
    # gnome-sound-recorder
    # gnome-software
    # gnome-settings-daemon43
    # maybe add system-monitor, image-viewer | switcheroo, document-viewer, VLC, document scanner, gaphor, graphs(?)/plots, health, khronos, secrets, warp
    lightdm

    acpi
    asdf-vm
    atuin
    # avahi (network discovery & connection)
    bat
    # unstable.batman
    unstable.brave # previous reference: inputs.nixpkgs.legacyPackages.x86_64-linux.brave-browser
    broot
    unstable.browsh
    buildah
    unstable.caddy
    unstable.code-cursor
    # cosmic-files | causes atuin crash
    podman
    podman-tui
    cmake
    cbfmt
    direnv
    # devdocs-desktop
    unstable.dprint
    # eww - Widget library for unix
    # flameshot # screenshot util, doesnt run yet on hyprland
    # chromium # THis increases master branch build, so ommitted
    comma
    unstable.deno
    unstable.elixir_1_17
    # helix
    (wrapNixGL unstable.hyprlock)
    unstable.hypridle
    fd
    ffsend
    flatpak-builder
    folks
    fontconfig
    unstable.fractal # Matrix messaging app
    freetype
    fx
    fzf
    gcc
    geoclue2
    gh
    gimp
    unstable.git-cliff
    unstable.gitui
    unstable.gleam
    gnumake
    gpsd
    grim
    # Should I have grimshot instead? or grimblast?
    # groff
    # joplin
    htop
    (wrapNixGL hyprland) # TODO: Maybe turn this for windowManager.hyprland
    hyprpicker
    # hyperfine # Command-line benchmarking tool
    # unstable.home-assistant # Build test fails 

    # inkspace
    inputs.xremap-flake.packages.${system}.default
    (wrapNixGL unstable.imagemagick)
    # immersed-vr
    unstable.appimage-run
    libva-utils
    iperf
    # unstable.ironbar
    unstable.jnv
    just
    kubectl
    # kubectl-tree
    kubernetes
    kubernetes-helm
    # ktop
    # lens
    libevdev
    libnotify
    (wrapNixGL libreoffice-fresh)
    # unstable.lmstudio
    localsend
    unstable.local-ai
    lsd
    lsof
    # lxc
    # lxcfs
    lxd-lts
    lua
    unstable.luajitPackages.luarocks
    # lutris # play all games on linux
    (wrapNixGL unstable.monado)
    magic-wormhole
    mpv # Default media player
    neofetch
    (nerdfonts.override { fonts = [ "Noto" ]; }) # maybe add Meslo
    networkmanagerapplet
    # nfs-utils
    ninja
    nixos-rebuild
    nix-init
    nix-index
    nix-prefetch-git
    nix-template
    ngrok
    unstable.nh # amazing nh nix helper, search, diff, switch etc, nom shell/nom develop
    nodejs
    noto-fonts
    noto-fonts-emoji
    mako
    unstable.manix
    # mpd

    # TODO: change this to normal ollama if nothing works
    # https://github.com/nix-community/nix-ld?tab=readme-ov-file#my-pythonnodejsrubyinterpreter-libraries-do-not-find-the-libraries-configured-by-nix-ld
    # zluda # Build fails: Check that zludas libcuda.so is in LD_LIBRARY_PATH | try stable one if unstable doesnt work 
    unstable.ollama

    openssl
    # openvino
    page
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
    qrtool
    # rofi - dmenu replacement, window switcher
    unstable.ripdrag
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
    # slumber -> terminal based http client that accepts files of routes
    statix
    swappy
    swaylock
    swww # wallpaper: maybe use programs.wpaperd instead(?)
    syncthing
    unstable.tailscale
    # taskchampion-sync-server
    taskopen # NOTE: how does this play with mail attachments/events(?)
    taskwarrior3 # https://github.com/flickerfly/taskwarrior-notifications # https://github.com/DCsunset/taskwarrior-webui
    taskwarrior-tui
    terminus-nerdfont
    timewarrior
    tree
    # timeshift
    unstable.tmux
    # touchegg
    # transmission
    # trash-cli
    unstable.tree-sitter

    # tui-journal

    qemu
    # playonlinux
    # variety
    unstable.ueberzugpp
    unzip
    unixtools.nettools
    # upower
    # unstable.xan # CSV chartmaker add this after nix flake update!
    xh # http tool
    xournalpp
    watchman
    wget
    wlr-randr # Monitor cli for wayland
    wl-clipboard
    wl-screenrec
    # wl-screenrec # high-perf screen recording tool
    unstable.wiper
    # vit
    viu # image viewer
    # visidata # => terminal based spreadsheet & DB tool
    vlc
    vnstat
    volta
    # unstable.wiper
    unstable.yazi

    zathura
    zeal
    # (wrapNixGL unstable.zed-editor)
    unstable.zenith

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
    (pkgs.writeShellScriptBin "meson-deps" ''
      grep -Po "dependency\(\s*'[^']+'" "meson.build" \
        | cut -d"'" -f2 \
        | sort -u \
        | while read -r dep; do
            if pkg-config --exists "$dep"; then
              echo "✅ $dep is available"
            else
              echo "❌ $dep is MISSING"
            fi
          done
    '')

    # Display manager options: SDDM, GDM, LightDM | run first without a DM, use LY or Lemurs for TTY login?
    # lightdm-webkit-theme-litarvan

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
    # NOTE: cbfmt shouldnt require this file and hopefully in future it moves to ~/.config/cbfmt
    ".cbfmt.toml".source =
      config.lib.file.mkOutOfStoreSymlink ../../static/.cbfmt.toml;
    # NOTE: Remove this when LSP formatting is correctly implemented with default new NeoVim versions:
    ".dprint.jsonc".source =
      config.lib.file.mkOutOfStoreSymlink ../../static/.dprint.jsonc;
    ".taskrc".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/home-manager/static/.taskrc";
    ".task/parrots-of-paradise.theme".source =
      config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.task/parrots-of-paradise.theme";

    # TODO: Move this xdg desktopEntries:
    "/.local/share/applications/Alacritty.desktop".text = ''
      [Desktop Entry]
      Terminal=false
      Type=Application
      Name=Alacritty Terminal
      Exec=/home/izelnakri/.nix-profile/bin/alacritty
    '';
    ".profile".source = ../../static/.profile;
    ".tmux.conf".source = ../../static/.config/tmux/tmux.conf;
    "scripts".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/home-manager/static/scripts";

    # "vimwiki".source = config.lib.file.mkOutOfStoreSymlink ../../static/vimwiki;

    # NOTE: make all dbus messages to be logged:
    # "../../etc/dbus-1/system-local.conf".text = ''
    #   <!DOCTYPE busconfig PUBLIC
    #   "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN"
    #   "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
    #   <busconfig>
    #       <policy user="root">
    #           <allow eavesdrop="true"/>
    #           <allow eavesdrop="true" send_destination="*"/>
    #       </policy>
    #   </busconfig>
    #   # sudo dbus-monitor "type=error,sender='org.freedesktop.DBus'" --system
    # '';

    # NOTE: Theming GTK:
    #
    # ".icons/bibata".source = "${pkgs.bibata-cursors}/share/icons/Bibata-Modern-Classic";
  };

  home.sessionVariables = rec {
    BROWSER = "brave";
    EDITOR = "nvim";
    OPENER = "xdg-open";
    ELIXIR_ERL_OPTIONS = "+fnu";
    ERL_AFLAGS =
      "-kernel shell_history enabled -kernel shell_history_file_bytes 1024000";
    FZF_DEFAULT_COMMAND = "fd --type f";
    GDK_SCALE = 2;
    LOL = "cool";
    # LANG = "en_US.UTF-8";
    # LC_ALL = "en_US.UTF-8";
    MANPAGER =
      "nvim +Man!"; # TODO: When vim.bo.filetype == man do page numbers & do fzf file search keybinding on <leader>-/ *ONLY ON MANPAGER*, also make Backspace end enter work like C-] and C-t:exe 'Lexplore ' . expand('$VIMRUNTIME') . '/syntax'
    MANWIDTH = 120;

    HISTTIMEFORMAT = "%d/%m/%y %T ";
    HISTFILE = "~/.cache/zsh/history";
    TERM = "xterm-256color";
    TERMINAL = "alacritty";
    BIN_PATHS =
      "$HOME/.local/share/nvim/mason/bin:$HOME/.volta/bin:$HOME/.cargo/bin:$HOME/.deno/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin";
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
    command-not-found.enable = true;
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
    # gpg.enable = true; # NOTE: publicKeys ?
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

    # ironbar = {
    #   enable = true;
    #   # package, style, config, features
    # };

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
    # neomutt.enable = true; # notmuchh build failed so commented out
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

    rofi = {
      enable = true;
      # cycle = null;
      # font = "Droid Sans Mono 14";"
      # location = "top-left"; # center
      # pass.enable = true;
      # pass.package = pkgs.rofi-pass-wayland;
      # extraConfig = ''
      # stores = []
      # plugins = [
      #
      # ]
    };

    mise = { # asdf replacement
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

    wlogout = { enable = true; };

    yt-dlp.enable = true;
    zathura.enable = true; # mappings, options

    # lieer, notmuch, mutt, mbsync, mu, msmtp, mujmap, senpai, swaylock, taskwarrior, waybar, wlogout, wofi, qt

    zsh = {
      enable = true;
      autosuggestion = { enable = true; };
      enableCompletion = true;
      defaultKeymap = "viins";
      # historySubstringSearch = {
      # enable = true;
      # searchDownKey = [ "^J" "^[[B" ]; # Ctrl-J, TODO: during insert up/down doesnt work(?) fix it
      # searchUpKey = [ "^K" "^[[A" ]; # Ctrl-K
      # };
      syntaxHighlighting.enable = true;
      syntaxHighlighting.highlighters = [ "main" ];
      plugins = [{
        name = "vi-mode";
        src = pkgs.unstable.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }];

      initExtra = ''
        source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh

        unsetopt INC_APPEND_HISTORY # Write to the history file immediately, not when the shell exits.
        setopt PROMPT_SUBST # Enable parameter expansion, command substitution and arithmetic expansion in the prompt.

        function cheat {
          curl cheat.sh/$argv
        }

        function display_jobs_count_if_needed {
          local job_count=$(jobs -s | wc -l | tr -d " ")

          if [ $job_count -gt 0 ]; then
            echo "%B%F{yellow}%j| ";
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

        # NOTE: This adds quit-to-directory functionality to yazi
        function yy() {
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
          yazi "$@" --cwd-file="$tmp"
          if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            cd -- "$cwd"
          fi
          rm -f -- "$tmp"
        }

        edit() {
          nvim <($@ 2>&1)
        }

        youtube() {
          local filename=''${2:-"last-video"}
          mpv --stream-record=$HOME/Youtube/$filename.mp4 $1
          # NOTE: in future I can edit this video with ffmpeg if I need to, trim parts etc
        }

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

        autoload -U colors && colors

        # NOTE: For gnome online accounts, then remove

        PROMPT='%F{blue}$(date +%H:%M:%S) $(display_jobs_count_if_needed)%B%F{green}%n %F{blue}%~%F{cyan}%F{yellow}$(parse_git_branch) %f%{$reset_color%}'
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#${config.colorScheme.palette.base03},bold";

        # TODO: Find another way to get ahead of /$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin in the future:
        export PATH="$BIN_PATHS:$PATH"

        # NOTE: Find all luarocks modules and add them to the path:
        eval "$(luarocks path --bin)"

        # NOTE: not needed due to check in its first line: source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
      '';

      shellAliases = {
        rotate-hyprland = "hyprctl keyword monitor eDP-1,preferred,auto,2,transform,1"; # 1, 2, 3, 4
        checkrepo =
          "git log --pretty=format: --name-only | sort | uniq -c | sort -rg | head -10";
        clip = "slurp | grim -g - - | wl-copy && wl-paste | swappy -f -";
        clip-record = ''wl-screenrec -g "$(slurp)" -f /tmp/recording.mp4'';
        colorpicker = "hyprpicker";
        csv = "tw";
        d = "sudo docker";
        diff = "diff --color=auto";
        dockerremoveall = "sudo docker system prune -a";
        e = "edit";
        find-devices = "avahi-browse"; # TODO: Make this work
        g = "yy";
        grep = "grep --color=auto";
        k = "kubectl";
        kube = "kubectl";
        ls = "ls --color=auto -F";
        lusd =
          "node /home/izelnakri/cron-jobs/curve-lusd.js"; # NOTE: maybe move to cmd
        m = "nvim +Man!";
        # TODO: add fzf and lookup to this, maybe open it up in nvim for all integration
        # check that links / backwards work in both scenarios
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
        query = "nix-store -q --references ";
        terminate = "lsof -ti:4200 | xargs kill";
        tt = "taskwarrior-tui";
        todo = "nvim ~/Dropbox/TODO.md";
        # update = "make -C ~/.config/home-manager";
        # update-all = "sudo make switch -C ~/.config/home-manager";
        v = "$EDITOR";
        vi = "nvim";
        vim = "nvim";
        weather = "curl http://wttr.in/";
        wireframe = "brave https://excalidraw.com/";
        YT = "youtube-viewer";
        x = "sxiv -ft *";
        gnome-wayland =
          "MOZ_ENABLE_WAYLAND=1 QT_QPA_PLATFORM=wayland XDG_SESSION_TYPE=wayland dbus-run-session gnome-session";
        gnome-wayland-systemd =
          "MOZ_ENABLE_WAYLAND=1 QT_QPA_PLATFORM=wayland XDG_SESSION_TYPE=wayland dbus-run-session gnome-session --systemd";

        gitfetch = "onefetch";
      };
      # shellGlobalAliases # => Similar to programs.zsh.shellAliases, but are substituted anywhere on a line.
    };
  };

  services.flatpak.enable = true;
  services.flatpak.packages = [
    "io.github.wivrn.wivrn" # SteamVR app streaming from linux
    "com.github.tchx84.Flatseal"
    "org.freedesktop.Bustle"
  ];

  services = {
    # flameshot.enable = true;
    # gpgagent = {
    #   enable = true;
    #   enableSSHSupport = true;
    #   enableZshIntegration = true;
    # }

    # $ syncthing cli --
    syncthing = {
      enable = true;
      # TODO: options for gui user, gui authentication, api key, folders(contacts, tasks, Photos, 
      # Videos, GIFs, Documents, emails, password-store, gpg keys, emails)
      # per device folder sharing config(?)
      # extraOptions = [ ]; # ["--gui-apikey=apiKey"]
      tray.enable = true;
    };

    mpris-proxy.enable = true;

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

    xremap = {
      watch = true;
      # mouse = true;
      withWlroots = true;
      # debug = true; # Logs everything
      yamlConfig = (builtins.readFile (builtins.toPath "${config.home.homeDirectory}/.config/home-manager/static/.config/xremap/${HOSTNAME}/config.yml"));

      # yamlConfig = builtins.readFile (builtins.toString ../../static/.config/xremap + "/" + (builtins.readFile "/proc/sys/kernel/hostname") + "/config.yml");
    };
  };

  # NOTE: Theming QT:
  #
  # qt = {
  #   enable = true;
  #   platformTheme = "gtk";
  #
  #   style = {
  #     name = "adwaita-dark";
  #     package = pkgs.adwaita-dark;
  #   };
  # };

  # TODO: Maybe use this:
  # pointerCursor = {
  #   gtk.enable = true;
  #   # x11.enable = true;
  #   package = pkgs.bibata-cursors;
  #   name = "Bibata-Modern-Classic";
  #   size = 16;
  # };

  gtk = {
    enable = true;

    # NOTE: Theming GTK:
    # cursorTheme.package = pkgs.bibata-cursors;
    # cursorTheme.name = "Bibata-Modern-Ice";
    #
    # theme.package = pkgs.adw-gtk3;
    # theme.name = "adw-gtk3";
    #
    # iconTheme.package = gruvboxPlus;
    # iconTheme.name = "GruvboxPlus";

    # font = {
    #   name = "Sans";
    #   size = 11;
    # };
  };

  # NOTE: This gets merged with gsettings list-recursively /etc/dconf/profile
  # default settings: gsettings list-recursively # saved location: ~/.config/dconf/$key
  # Get GSettings schema numbers have to be *casted* . dconf2nix | Also research GResources
  # DConf DB is stored in ~/.config/dconf/user(binary)
  # NOTE: Reset dconf db on each home-manager switch(lookup on impermanence)
  # dbus-daemon dconf load / < ${iniFile}
  dconf = {
    enable = true;

    # settings = {}
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
      webserver = {
        Unit = {
          Description = "Caddy HTTPS Server of /Public";
          After = [ "network-online.target" ];
        };

        Service = {
          ExecStart = "${pkgs.unstable.caddy}/bin/caddy file-server -l localhost:9999 --browse -a -r ${config.home.homeDirectory}/Public";
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
      "gitui".source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/.config/home-manager/static/.config/gitui";
      # NOTE: Theming GTK:
      # "gtk-4.0/gtk.css".text = (replaceColorReferences
      #   (builtins.readFile ../../static/.config/gtk-4.0/gtk.css)
      #   config.colorScheme.palette);
      #  Make it symlink instead of text:
      # "gtk-3.0/gtk.css".text = (replaceColorReferences
      #   (builtins.readFile ../../static/.config/gtk-4.0/gtk.css)
      #   config.colorScheme.palette);
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
      "swappy/config".source = ../../static/.config/swappy/config;
      "system-colors.json".text = (builtins.toJSON config.colorScheme.palette);
      "tmux/theme.conf".text = (replaceColorReferences
        (builtins.readFile ../../static/.config/tmux/theme.conf)
        config.colorScheme.palette);
      # "wlogout/config".source = ../../static/.config/wlogout/config; # https://github.com/nabakdev/dotfiles/blob/main/.config/wlogout/style.css
      "waybar".source = ../../static/.config/waybar;
      "wlogout".source = ../../static/.config/wlogout;
      "yazi".source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/.config/home-manager/static/.config/yazi";

    };

    mime.enable = true;
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
        "image/jpeg" = "brave-browser.desktop";
        "image/jpg" = "brave-browser.desktop";
        "image/png" = "brave-browser.desktop";
        "image/*" = "brave-browser.desktop";
        # NOTE: Location: ~/.nix-profile/share/applications

        "application/pdf" =
          "brave-browser.desktop"; # NOTE: make it zathura or other document viewer?
        "application/x-shellscript" = "Alacritty.desktop";

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
      # firefox = {
      #   name = "Firefox";
      #   genericName = "Web Browser";
      #   exec = "firefox %U";
      #   terminal = false;
      #   categories = [ "Application" "Network" "WebBrowser" ];
      #   mimeType = [ "text/html" "text/xml" ];
      #   # icon
      #   # actions(left list)
      #   # comment
      #   # noDisplay true/false
      #   # prefersNonDefaultGPU
      #   # settings = { Keywords = "calc;math"; DBusActivatable = "false"; }
      #   # startupNotify
      #   # type (“Application”, “Link”, “Directory”)
      # };

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
# gnome-tweak-tool
# control-center, applet, common, background, file-manager
# adwaita-icon-theme
# dconf.enable
# gnomeExtensions.appindicator
# gnome-settings-daemon

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
# Implement https://github.com/banister/method_source for TS, elixir

# https://heywoodlh.io/nixos-gnome-settings-and-keyboard-shortcuts

# clone if doesnt exist pattern: 	if [ -d ~/git/neovim ]; then echo "[nvim]: git/neovim Already found"; else git clone https://github.com/neovim/neovim ~/git/neovim; fi
# 	if [ -d ~/build/neovim ]; then cd ~/build/neovim && git pull; else git clone https://github.com/neovim/neovim ~/build/neovim; fi
## cd ~/build/neovim/ && make -j2 -s --no-print-directory && sudo make install -s

# NOTE: systemd timer instead of cron, read up on docs, how to view it easily
# systemd.user.timers = mapRemotes (name: remoteCfg: {
#   Unit = { Description = "muchsync periodic sync (${name})"; };
#   Timer = {
#     Unit = "muchsync-${name}.service";
#     OnCalendar = remoteCfg.frequency;
#     Persistent = true;
#   };
#   Install = { WantedBy = [ "timers.target" ]; };
# });

# battery monitoring, network monitoring, homescreen(check with anyrun), try running it also with bluetooth

# Ref: https://nixos.wiki/wiki/Home_Assistant#OCI_container
#   virtualisation = {
#     oci-containers = {
#       backend = "podman";
#       containers.homeassistant = {
# #        volumes = [ "home-assistant:/config" ];
#         volumes = [ "/srv/home-assistant:/config" ];
#         environment.TZ = "${timeZone}";
#         image = "ghcr.io/home-assistant/home-assistant:${imageTag}"; # Warning: if the tag does not change, the image will not be updated
#         extraOptions = [ 
#           "--network=host" 
#         ];
#       };
#     };
#   };

# disko example: https://gitlab.com/cryptochasm/nixos-home-assistant/-/tree/main?ref_type=heads
# for pdf markup: drawboard
# implement rustowl
