{
  description = "Home Manager configuration of izelnakri";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # TODO: make home.nix, ~/.config/home-manager present in the repo downloaded from github and switched
  # Make everything run as btrfs after home-manager install is complete
  outputs = inputs@{ self, nixpkgs, nixos-hardware, nixos-generators, home-manager, ... }:
    let
      system = "x86_64-linux";
      x86Pkgs = nixpkgs.legacyPackages.x86_64-linux;
      armPkgs = nixpkgs.legacyPackages.aarch64-linux;
    in {
      images = {
        pi4-nas = (self.nixosConfigurations.pi4-nas.extendModules {
          modules = [
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"
          ];
        }).config.system.build.sdImage;
      };
      nixosConfigurations = {
        pi4-nas = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            nixos-hardware.nixosModules.raspberry-pi-4
            ./modules/build-raspberry-pi-image.nix
            ./hosts/izels-pi4/configuration.nix
          ];
          specialArgs = inputs;
        };
      };
      homeConfigurations = {
        admin = home-manager.lib.homeManagerConfiguration {
          pkgs = armPkgs;
          modules = [ ./home.nix ];
        };
        izelnakri = home-manager.lib.homeManagerConfiguration {
          pkgs = x86Pkgs;
          modules = [ ./home.nix ];
        };
      };
    };
}
