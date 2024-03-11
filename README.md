# Repo Layout

- `hosts/` - Machines/Hardware definitions.

  - `x1-carbon/` - My laptop

  - `zfold-5/` - My android Samsung Z Fold 5

  - `pi4/` - My router, NAS, and other things.

  - `viture/` -  My viture neckband.

- `modules/` - [Modules](https://nixos.wiki/wiki/Module) `nixosModules` that appear in the flake automatically. Individual files can be
  imported on imports = [ ... ];

  - `functions/` - Helper nix functions to accomplish certain tasks. Like (nixGL $program) etc.

- `secrets/` - [`age`](https://github.com/FiloSottile/age) encrypted secrets,
  made possible by [`agenix`](https://github.com/ryantm/agenix)

- `static/` - static configuration files & folders that are copied to systems.
  - `ssot/` - Single Source of Truth, stuff like my SSH Keys, etc.

- `users/` - [home-manager](https://github.com/nix-community/home-manager) configuration per user.
  - `$username/` - home-manager configuration for a given user

  - `shared/` - shared home-manager configuration for all users

## Building cross compiled NixOS Image for RaspberryPi 4B

When running `$nix build .#images.pi`, by default `nix` uses `/tmp` directory to build the temporary artifacts which can
be a problem if you are running on a machine with limited space for `/tmp`. Compiling kernel requires more than 15GB of
space, when your `/tmp` is a `tmpfs` you might run into issues. If you have a swap or more memory you can increase the
space available to `/tmp` by running the following command:

```bash
sudo mount -o remount,size=32G,nr_inodes=0 /tmp
```

### Using NixGL

NixGL is necessary to set up the GL environment for the user. In order to utilize it as a function in home-manager, you
need to write this these your home-manger configuration:

```nix
# in flake.nix

outputs = { nixGL, ... }: {
  homeConfigurations = {
    izelnakri = home-manager.lib.homeManagerConfiguration {
      pkgs = x86Pkgs;
      modules = [
        { nixpkgs.overlays = [ nixGL.overlay ]; } # NOTE: This exposes pkgs.nixgl to be used in your modules
        ./users/$USER.nix
      ];
      extraSpecialArgs = { inherit inputs; };
    };
  };
}

# in ./users/izelnakri.nix
{ config, pkgs, inputs, nixosModules, ... }:
let
  nixGL = import ../modules/nix-gl.nix { inherit pkgs; }; # NOTE: loads nixGL function. Example: (nixGL alacritty)
in {
  # either load the package in home.packages or in program.$programName.package:

  home.packages = [
    (nixGL alacritty)
    neovim
  ];

  # or as:

  programs.alacritty = {
    enable = true;
    package = (nixGL alacritty);
  }
}
```

### Tips

Dynamically browse all evaluated options:

```bash
nix repl --file '<nixpkgs/nixos>' -I nixos-config=./hosts/izels-pi4/configuration.nix
```

Run a nix file:

```bash
nix eval --file ./entry.nix
```

Print an expression:

```bash
builtins.trace me "return value";
```

Run a file with an inner module:

```bash
echo '{ foo }: foo' > something.nix
echo 'import ./something.nix { foo = "bar"; }' > entry.nix
nix eval --file ./entry.nix
```

Generate a directory with the specified contents:

```bash
$ nix eval --write-to ./out --expr '{ foo = "bar"; subdir.bla = "123"; }'
$ cat ./out/foo
bar
$ cat ./out/subdir/bla
123
```

Pretty print a nix file:

```bash
nix eval --file ./entry.nix | nixfmt
# or
nix eval --file ./entry.nix --json | xq
# retract lambdas and repeated placeholders:
nix eval --file ./entry.nix | sed -r 's/<LAMBDA>/"LOL"/g' | sed -r 's/«repeated»/"REPEATED"/g' | nixfmt
# if the target file is a lambda, you can run it with:
nix eval --expr 'import ./target-file.nix' --impure | sed -r 's/<LAMBDA>/"LOL"/g' | sed -r 's/«repeated»/"REPEATED"/g' | nixfmt
```

## NixGL - home-manager GL support/mess

Add nixGL to registry:

```bash
nix registry add nixgl github:guibou/nixGL

nix run --impure nixgl#nixGLDefault -- alacritty
```


%% console.colors = []
