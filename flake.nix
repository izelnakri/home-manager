# NixOS-generator must be used
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

  outputs = inputs@{ self, nixpkgs, nixos-hardware, nixos-generators, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
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

      # TODO: each machine is a different configuration
      # homeConfigurations = {
      #   izelnakri = home-manager.lib.homeManagerConfiguration {
      #     inherit pkgs;

      #     # Specify your home configuration modules here, for example,
      #     # the path to your home.nix.
      #     modules = [ ./home.nix ];

      #     # Optionally, use home-manager.extraSpecialArgs to pass
      #     # to pass through arguments to home.nix
      #   };
      # };
    };
}
