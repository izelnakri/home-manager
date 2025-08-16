# Repo Layout

- `hosts/` - Machines/Hardware definitions.

  - `omnibook/` - My current laptop

  - `x1-carbon/` - My old laptop

  - `zfold-5/` - My android Samsung Z Fold 5

  - `pi4/` - My router, NAS, and other things.

  - `viture/` - My viture neckband.

- `modules/` - [Modules](https://nixos.wiki/wiki/Module) `nixosModules` that appear in the flake automatically.
  Individual files can be imported on imports = [ ... ];

  - `functions/` - Helper nix functions to accomplish certain tasks. Like (nixGL $program) etc.

- `secrets/` - [`age`](https://github.com/FiloSottile/age) encrypted secrets, made possible by
  [`agenix`](https://github.com/ryantm/agenix)

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

### Nix Debugging:

```bash
readlink -f `which waybar`

# Get the store path of a binary:
nix build nixpkgs#wl-clipboard --print-out-paths --no-link
# => /nix/store/ww2421123213123213-wl-clipboard-2.1.0
# cd /nix/store/ww2421123213123213-wl-clipboard-2.1.0 && exe --tree .
# => Shows whats inside

# There is also a way to get all related packages:
nix build "nixpkgs#openssl^*" --print-out-paths

# Dependency Tree Ops:
nix-store -q --tree `which hello` # tree of dependencies
nix-store -q --references `which hello` # runtime dependencies
nix-store -q --referrers `which hello` # all referrers that touches the binary
nix-instantiate hello.nix
nix-store -q --references /nix/store/z77vn965a59irqnrrjvbspiyl2rph0jp-hello.drv

nix-locate wl-copy # comes from nix-index-database
```

### Nix REPL Debugging:

To debug specific home-configuration:

```nix
:lf .
system = "x86_64-linux"
pkgs = inputs.nixpkgs.legacyPackages.${system} 
hm = inputs.home-manager.lib.homeManagerConfiguration { inherit pkgs; modules = [ ./users/izelnakri ]; extraSpecialArgs = { inherit inputs; }; };
hm.config.programs.<TAB>
hm.config.services.<TAB>
```

To debug specific nixos configuration:

```nix
:lf .
system = "x86_64-linux"
pkgs = inputs.nixpkgs.legacyPackages.${system} 
os = inputs.nixpkgs.lib.nixosSystem { 
  system = "x86_64-linux";
  modules = [ 
    ./hosts/izels-pi4/configuration.nix
    inputs.home-manager.nixosModules.home-manager
  ]; 
  specialArgs = { inherit inputs; };
}
```

To debug general nixos configuration:

```nix
:l <nixpkgs/nixos>
```

### Nix Modules Template example:

```shell
nix-template-module -p openrgb ./nixos/modules/services/openrgb
```

Inspect module type options:

```nix
:l <nixpkgs>
lib.types.<TAB>
# :doc doesn't work for these, but you can inspect the source code
```

#### Run nix as script:

```nix
# in script.nix:
let
  pkgs = import <nixpkgs> {};
  LS_COLORS = pkgs.fetchgit {
    url = "https://github.com/trapd00r/LS_COLORS";
    rev = "7d06cdb4a245640c3665fe312eb206ae758092be";
    sha256 = "ILT2tbJa6uOmxM0nzc4Vok8B6pF6MD1i+xJGgkehAuw=";
  };
  # LS_COLORS = pkgs.fetchurl {
  #   url = "https://raw.githubusercontent.com/trapd00r/LS_COLORS/280927e0ab14c6029ea32aa079e3fe9336c49264/LS_COLORS";
  #   sha256 = "+xUzEoUX9CcKQqrkN2tkecwKAXFtlAaf/mw4vCZh+aI=";
  # };
in
  pkgs.runCommand "ls-colors" {} ''
    mkdir -p $out/bin $out/share
    ln -s ${pkgs.coreutils}/share/ls $out/bin/ls
    ln -s ${pkgs.coreutils}/bin/dircolors $out/bin/dircolors
    cp ${LS_COLORS}/LS_COLORS $out/share/LS_COLORS
  ''
```

```sh
nix run -f ./script.nix
```

### Agenix with SSH keys

First create a `secrets.nix` file that references your public key. Ragenix knows from where to get the private key from the key type:
```nix {
  # Declare recipients for each secret file
  "supersecret.age".publicKeys = [
    # Replace this with your actual public key
    "ssh-ed25519 AAAAC3NzaZ1lZDI1NTE5ABBBIJwZQqIddghrteWbhR68RtHimKF27o24AuJAbEnAuMga contact@izelnakri.com"
  ];
}
```

Now you can create an encrypted non-existent file on for `supersecret.age` by executing this command, it will
open up the editor to put the contents that are to be encrypted:

```zsh
ragenix -e supersecret.age # since **only** supersecret.age declared in secrets.nix
```

Now supersecret.age exists in the filesystem and includes **only** the cyphertext. In order to decrypt it somewhere:

```zsh
rage -d -i ~/.ssh/id_ed25519 supersecret.age -o found.txt
```

### Agenix on Home-manager or NixOS:

- First add the agenix flake to your `nixosConfigurations.yourhostname` or `homeConfigurations.yourusername`.
- Then create the `secrets.nix` object/file so `agenix -e someSecretfile.age` works.
- Add/Check-in these encrypted files to nix store via: `age.secrets.example-secret.file = ../secrets/secret1.age;` Can even optionally have mode, owner, group.
- Reference these files now via: ```config.age.secrets.example-secret.path```
- By default secrets are mounted on NixOS at `/run/agenix.d`. Can be changed on: age.secretsMountPoint

Now the content you stored and previously encrypted is stored as raw text file on found.txt.

### PGP Encyption

Age, Rage, Agenix, Ragenix doesnt work with PGP directly. However if you want PGP to encrypt/decrypt files:

```zsh
# --recipient is your public PGP KEY:
# To encrypt, creates file.txt.gpg :
GPG_PUBLIC_KEY_ID=$(gpg --list-public-keys --with-colons | awk -F: '/^fpr/ {print $10; exit}')
gpg --encrypt --recipient $GPG_PUBLIC_KEY_ID file.txt
# To decrypt:
gpg --decrypt --recipient $GPG_PUBLIC_KEY_ID file.txt.gpg > file.txt
```

### PGP Export

```zsh
gpg --export-secret-keys --armor $PGP_PUBLIC_KEY_ID > ~/private.pgp

# Metadata of the private key:
gpg --show-keys ./private.pgp

# Import it to gpg:
gpg --import ./private.pgp
```

#### Miscellanous

```zsh
# Show the contents of a derivation!:
nix-tree --derivation 'nixpkgs#llvmPackages_20.libcxxStdenv'
# or for existing system:
nix-tree /nix/var/nix/profiles/system
# or for a flake:
nix-tree --derivation '.#'
# or:
nix-tree --derivation '.#devShells.x86_64-linux.default'
# or a visual svg:
nix-du -s=500MB | dot -Tsvg > store.svg # or -Tpng or simple .dot etc
# or:
nix-du --root ./result | dot -Tsvg > store.svg # could be from flake

# List linked dependencies:
objdump -p /home/izelnakri/.nix-profile/bin/deno | grep NEEDED
# or
ldd /home/izelnakri/.nix-profile/bin/deno
# or:
patchelf --print-needed masterpdfeditor4

# to set specific ldd interpreter
patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      masterpdfeditor4

# to set specific ldd dependencies:
$ nix repl '<nixpkgs>'
# .out can be omitted because this is the default output for all packages
# makeLibraryPath outputs the correct path for each package to use as rpath
nix-repl> with pkgs; lib.makeLibraryPath [ sane-backends libsForQt5.qt5.qtbase libsForQt5.qt5.qtsvg stdenv.cc.cc.lib ]
"/nix/store/7lbi3gn351j4hix3dqhis58adxbmvbxa-sane-backends-1.0.25/lib:/nix/store/0990ls1p2nnxq6605mr9lxpps8p7qvw7-qtbase-5.9.1/lib:/nix/store/qzhn2svk71886fz3a79vklps781ah0lb-qtsvg-5.9.1/lib:/nix/store/snc31f0alikhh3a835riyqhbsjm29vki-gcc-6.4.0-lib/lib"

# then apply the dependencies:
$ patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" --set-rpath /nix/store/7lbi3gn351j4hix3dqhis58adxbmvbxa-sane-backends-1.0.25/lib:/nix/store/0990ls1p2nnxq6605mr9lxpps8p7qvw7-qtbase-5.9.1/lib:/nix/store/qzhn2svk71886fz3a79vklps781ah0lb-qtsvg-5.9.1/lib:/nix/store/snc31f0alikhh3a835riyqhbsjm29vki-gcc-6.4.0-lib/lib   masterpdfeditor4
$ ./masterpdfeditor4
# SUCCESS!!!

# Send a notification from the command line:
notify-send "My title" "Description"

# Send a notification with progress bar:
notify-send -h int:value:99 "My title" "Description"

# Send a d-bus message:
dbus-send --system / net.nuetzlich.SystemNotifications.Notify "string:hello world"

# TODO: Find DBus history / debugging techniques, read mako source code(or find rust version)
````

%% console.colors = []

###### Websites for inspiration

```
https://laymonage.com/posts
```


#### Things not yet declared:

- I choose to not declare my agenix SSH public keys for post-quantum harvest now, decrypt later attacks.
- syncthing
- Brave extensions & Rabbit config
