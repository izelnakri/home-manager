{
  description = "Izel's personal cluster of machines & system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixinate = {
      url = "github:matthewcroughan/nixinate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-colors.url = "github:misterio77/nix-colors";
    disko.url = "github:nix-community/disko";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixGL = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xremap-flake.url = "github:xremap/nix-flake";
  };

  # TODO: make ~/.config/home-manager present with git pulled
  # TODO: make mako & alacritty configured with base16 https://www.youtube.com/watch?v=jO2o0IN0LPE
  # Make everything run as btrfs after home-manager install is complete
  outputs = inputs@{ self, nixinate, nixpkgs, nixpkgs-unstable, nixos-hardware
    , home-manager, nixGL, ... }:
    let
      system = "x86_64-linux";
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
      x86Pkgs = nixpkgs.legacyPackages.x86_64-linux;
      armPkgs = nixpkgs.legacyPackages.aarch64-linux;
    in {
      apps = nixinate.nixinate.${system} self;
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
        # TODO: Implement btrfs with this: https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html
        pi4-nas = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [ overlay-unstable nixGL.overlay ];
            })
            nixos-hardware.nixosModules.raspberry-pi-4
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
            # hyprland.homeManagerModules.default
            ./users/izelnakri
          ];
          extraSpecialArgs = { inherit inputs; };
        };
      };
    };
}
