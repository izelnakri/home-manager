{
  description = "Izel's personal cluster of machines & system configurations";

  inputs = {
    disko.url = "github:nix-community/disko";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # iio-hyprland.url = "github:JeanSchoeller/iio-hyprland";
    ironbar.url = "github:JakeStanger/ironbar?ref=v0.16.1";
    hyprland.url = "github:hyprwm/Hyprland?ref=v0.57.2";

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
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Content-aware diff viewer; `git review` (users/izelnakri) opens branch diffs in it.
    omnidiff.url = "github:ivankovic/omnidiff";
    # Disabled: a `path:` input copies the whole ~/Github/nixpkgs working tree into the
    # store on every lock/eval (slow) and it was only consumed by the dead `fork` overlay
    # below. For hacking on packages/modules use `make module-dev` instead, which does
    # `nixos-rebuild --override-input nixpkgs ~/Github/nixpkgs`.
    # nixpkgs-fork.url = "path:/home/izelnakri/Github/nixpkgs";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    ragenix.url = "github:yaxitech/ragenix";
    stylix.url = "github:danth/stylix/release-26.05";
    xremap-flake.url = "github:xremap/nix-flake/1924f2dc1a7c219b5323050a7fb27920e3a225d4";
    intel-npu-driver.url = "github:intel/linux-npu-driver/v1.24.0"; # NOTE: v1.28 doesnt work
  };

  # TODO: make mako & alacritty configured with base16 https://www.youtube.com/watch?v=jO2o0IN0LPE
  outputs = inputs@{
    self, nixinate, nixpkgs, nixpkgs-unstable, nixos-hardware, nix-flatpak, home-manager, ragenix,
    hyprland, stylix, ...
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
        # Use the consuming host's own platform so this overlay is correct on aarch64
        # (pi4) too, instead of the hardcoded x86_64-linux `system` above.
        unstable = import nixpkgs-unstable {
          localSystem = {
            system = prev.stdenv.buildPlatform.system;
          };
          crossSystem = {
            config = prev.stdenv.hostPlatform.config;
          };
          config.allowUnfree = true;
        };

        # DisplayLink 6.3 from nixpkgs-unstable.
        displaylink = final.unstable.displaylink;

        # Disabled together with the nixpkgs-fork input above (was unused — only referenced
        # in commented-out `pkgs.fork.*` lines). Re-enable both to use a local nixpkgs fork.
        # fork = import nixpkgs-fork {
        #   system = prev.stdenv.hostPlatform.system;
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
        # Existing Raspberry Pi image target is intentionally retained unchanged.
        pi4-nas = (self.nixosConfigurations.pi4-nas.extendModules {
          modules = [
            ./modules/build-raspberry-pi-image.nix
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"
          ];
        }).config.system.build.sdImage;

        # Same image with a zstd btrfs root (modules/raspberry-pi/rootfs.nix). To run it for
        # real, also set pi4.rootFs = "btrfs" in hosts/izels-pi4 so deploys match the card.
        pi4-nas-btrfs = (self.nixosConfigurations.pi4-nas.extendModules {
          modules = [
            { pi4.rootFs = "btrfs"; }
            ./modules/build-raspberry-pi-image.nix
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"
          ];
        }).config.system.build.sdImage;
      };

      # `nix run .#run-pi4 [-- --ssh pi4-nas.local | --reboot | --tier uboot | --run CMD ...]`:
      # tests images.pi4-nas in QEMU (raspi4b: real U-Boot -> extlinux -> kernel; virt: system
      # to login + checks), or the running Pi over SSH. See scripts/run-pi4.ts / `make run-pi4`.
      # Pinned toolchain (Deno + QEMU + tools); `deno run -A scripts/run-pi4.ts` works too.
      packages.x86_64-linux.run-pi4 = x86Pkgs.writeShellApplication {
        name = "run-pi4";
        runtimeInputs = with x86Pkgs; [ deno qemu dtc mtools util-linux openssh sshpass ];
        # Deno runs the TypeScript directly (no build step); node: built-ins only, all I/O async.
        text = ''exec deno run --allow-all --quiet --no-prompt ${./scripts/run-pi4.ts} "$@"'';
      };

      nixosModules = import ./modules { lib = nixpkgs.lib; };

      nixosConfigurations = {
        omnibook = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ({ config, pkgs, ... }: {
              # nixGL.overlay dropped: redundant on NixOS (hardware.graphics provides GL
              # from the store) and its `auto` variant pulled in builtins.currentTime,
              # forcing --impure and defeating the flake eval cache. wrapNixGL is now a
              # no-op passthrough (see modules/functions/wrap-nix-gl.nix). Re-add
              # `nixGL.overlay` here (and restore the input + real wrapper) for a
              # generic-Linux / non-NixOS host.
              nixpkgs.overlays = [ overlay-unstable ]; # [ overlay-unstable nixGL.overlay ];
            })
            # nix-flatpak.nixosModules.nix-flatpak
            home-manager.nixosModules.home-manager
            ragenix.nixosModules.default
            ./hosts/omnibook/configuration.nix
          ];
          specialArgs = { inherit inputs; };
        };

        # TODO: Implement btrfs with this: https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html
        pi4-nas = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ({ config, pkgs, ... }: {
              # nixGL.overlay dropped: redundant on NixOS (hardware.graphics provides GL
              # from the store) and its `auto` variant pulled in builtins.currentTime,
              # forcing --impure and defeating the flake eval cache. wrapNixGL is now a
              # no-op passthrough (see modules/functions/wrap-nix-gl.nix). Re-add
              # `nixGL.overlay` here (and restore the input + real wrapper) for a
              # generic-Linux / non-NixOS host.
              nixpkgs.hostPlatform = "aarch64-linux";
              nixpkgs.buildPlatform = "x86_64-linux";
              nixpkgs.overlays = [ overlay-unstable ]; # [ overlay-unstable nixGL.overlay ];
            })
            nixos-hardware.nixosModules.raspberry-pi-4
            # nix-flatpak.nixosModules.nix-flatpak
            ./hosts/izels-pi4/configuration.nix
            # home-manager.nixosModules.home-manager # commented out due to image build error from x86
            {
              _module.args.nixinate = {
                # Tailscale MagicDNS name (after `tailscale up --hostname=izels-pi4` on the Pi).
                # Was "pi4-nas.local" (mDNS: blocked on campus Wi-Fi) / "pi4-nas.lan" (router DNS, works on the LAN).
                host = "izels-pi4";
                sshUser = "izelnakri";
                buildOn = "local"; # cross-build on the laptop, reusing the image's store paths; was "remote" (Pi compiles everything)
                substituteOnTarget = true; # if buildOn is "local" then it will substitute on the target, "-s"
                hermetic = false;
              };
            }
          ];
          specialArgs = { inherit inputs; };
        };
      };

        # Fairphone 6 / 6+ AArch64 NixOS userspace scaffold.
        # This is NOT yet a flashable device image: device kernel, DTBs, firmware,
        # boot image integration and installer are tracked in hosts/fairphone-6-plus/.
        fairphone-6-plus = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [ overlay-unstable ];
            })
            ./hosts/fairphone-6-plus/configuration.nix
          ];
          specialArgs = { inherit inputs; };
        };
        homeConfigurations = {
        izelnakri = home-manager.lib.homeManagerConfiguration {
          pkgs = x86Pkgs;
          modules = [
            {
              # nixGL.overlay dropped: redundant on NixOS (hardware.graphics provides GL
              # from the store) and its `auto` variant pulled in builtins.currentTime,
              # forcing --impure and defeating the flake eval cache. wrapNixGL is now a
              # no-op passthrough (see modules/functions/wrap-nix-gl.nix). Re-add
              # `nixGL.overlay` here (and restore the input + real wrapper) for a
              # generic-Linux / non-NixOS host.
              nixpkgs.overlays = [ overlay-unstable ]; # [ overlay-unstable nixGL.overlay ];
            }
            ./users/izelnakri
          ];
          extraSpecialArgs = { inherit inputs; };
        };
      };
    };
}
