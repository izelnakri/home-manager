{
  description = "Izel's personal cluster of machines & system configurations";

  inputs = {
    disko.url = "github:nix-community/disko";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # iio-hyprland.url = "github:JeanSchoeller/iio-hyprland";
    ironbar.url = "github:JakeStanger/ironbar?ref=v0.16.1";

    nix-colors.url = "github:misterio77/nix-colors";
    nix-flatpak.url = "github:gmodena/nix-flatpak?ref=v0.6.0"; # unstable branch. Use github:gmodena/nix-flatpak/?ref=<tag> to pin releases.
    nixGL = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixinate = {
     url = "github:matthewcroughan/nixinate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # nixpkgs-fork.url = "git:/home/izelnakri/Github/nixpkgs";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    stylix.url = "github:danth/stylix/release-25.05";
    xremap-flake.url = "github:xremap/nix-flake";
  };

  # TODO: make mako & alacritty configured with base16 https://www.youtube.com/watch?v=jO2o0IN0LPE
  outputs = inputs@{ 
    self, nixinate, nixpkgs, nixpkgs-unstable, nixos-hardware, nix-flatpak, home-manager, nixGL, stylix, 
    ... 
  }:
    let
      allSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      system = "x86_64-linux";
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      # A function that provides a system-specific Nixpkgs for the desired systems
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
        # fork = import nixpkgs-fork {
        #   inherit system;
        #   config.allowUnfree = true;
        # };
      };
      x86Pkgs = nixpkgs.legacyPackages.x86_64-linux;
      armPkgs = nixpkgs.legacyPackages.aarch64-linux;
    in {
      apps = nixinate.nixinate.${system} self;

      devShells = forAllSystems ({ pkgs }: {
        default = let
          python = pkgs.python3.override {
            self = python;
            packageOverrides = pyfinal: pyprev: {
              # openvino_genai = pyfinal.callPackage ./build-openvino_genai.nix { };
            };
          };
        in pkgs.mkShell {
          name = "nix-default-develop-shell";
          buildInputs = [
            pkgs.pkg-config
            pkgs.meson
            pkgs.ninja

            pkgs.gnutls # could add: pkgs.curl, zlib, sqlite, freetype, libpng

            # (python.withPackages (python-pkgs: [
            #   # python-pkgs.openvino_genai
            # ]))
            # pkgs.python3Packages.virtualenv
            pkgs.openvino
            pkgs.zlib 
            pkgs.stdenv.cc.cc.lib
          ];

          PKG_CONFIG_PATH = pkgs.lib.makeLibraryPath [ # Optional: Make pkg-config see everything
            pkgs.gnutls # could add: pkgs.glib, curl, zlib, sqlite, freeype, libpng
          ] + "/pkgconfig";

          shellHook = ''
            echo "🧪 [nix develop] Ready to build with Meson. Run:"
            echo "    meson setup build"
            echo "    ninja -C build"
            export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${pkgs.zlib}/lib:${pkgs.stdenv.cc.cc.lib}/lib

            $SHELL
          '';
        };
      });

      # add libs

      # packages = forAllSystems ({ pkgs }: { # https://github.com/arsalanses/Nix-flake-for-docker/blob/master/flake.nix
      #   default = {
      #     # Package definition
      #   };
      # });
    
      images = {
        pi4-nas = (self.nixosConfigurations.pi4-nas.extendModules {
          modules = [
            ./modules/build-raspberry-pi-image.nix
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"
          ];
        }).config.system.build.sdImage;
      };

      nixosModules = import ./modules { lib = nixpkgs.lib; };

      nixosConfigurations = {
        omnibook = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [ overlay-unstable nixGL.overlay ];
            })
            # nix-flatpak.nixosModules.nix-flatpak
            home-manager.nixosModules.home-manager
            ./hosts/omnibook/configuration.nix
          ];
          specialArgs = { inherit inputs; };
        };

        # TODO: Implement btrfs with this: https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html
        pi4-nas = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [ overlay-unstable nixGL.overlay ];
            })
            nixos-hardware.nixosModules.raspberry-pi-4
            # nix-flatpak.nixosModules.nix-flatpak
            ./hosts/izels-pi4/configuration.nix
            home-manager.nixosModules.home-manager
            {
              _module.args.nixinate = {
                host = "pi4-nas.lan";
                sshUser = "izelnakri";
                buildOn = "remote";
                substituteOnTarget =
                  true; # if buildOn is "local" then it will substitute on the target, "-s"
                hermetic = false;
              };
            }
          ];
          specialArgs = { inherit inputs; };
        };
      };

      homeConfigurations = {
        izelnakri = home-manager.lib.homeManagerConfiguration {
          pkgs = x86Pkgs;
          modules = [
            {
              nixpkgs.overlays = [ overlay-unstable nixGL.overlay ];
            }
            ./users/izelnakri
          ];
          extraSpecialArgs = { inherit inputs; };
        };
      };
    };
}
