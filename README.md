# Repo Layout

- `hosts/` - Machines/Hardware definitions.

  - x1-carbon/` - My laptop

  - zfold-5/` - My android Samsung Z Fold 5

  - pi4/` - My router, NAS, and other things.

- `modules/` - [Modules](https://nixos.wiki/wiki/Module) `nixosModules` that
  appear in the flake, automatically.

  - `mixins/` - Dotfiles/Configurations. Instead of imperatively configuring
    `/etc/` or `~/.config`, everything in here is written in Nix instead. This
    nix code implements the changes I want that would traditionally be done by
    modifying something in `/etc/` or `~/.config` using `vim`.

  - `profiles/` - Configurations that are often comprised of mixins that are
    intended to be imported into a given system.

  - `ssot/` - Single Source of Truth, stuff like my SSH Keys, etc.

  - `users/` - [home-manager](https://github.com/nix-community/home-manager) configuration per user.

- `secrets/` - [`age`](https://github.com/FiloSottile/age) encrypted secrets,
  made possible by [`agenix`](https://github.com/ryantm/agenix)

## Building cross compiled NixOS Image for RaspberryPi 4B

When running `$nix build .#images.pi`, by default `nix` uses `/tmp` directory to build the temporary artifacts which can
be a problem if you are running on a machine with limited space for `/tmp`. Compiling kernel requires more than 15GB of
space, when your `/tmp` is a `tmpfs` you might run into issues. If you have a swap or more memory you can increase the
space available to `/tmp` by running the following command:

```bash
sudo mount -o remount,size=32G,nr_inodes=0 /tmp
```

### Tips

Dynamically browse all evaluated options:

```bash
nix repl --file '<nixpkgs/nixos>' -I nixos-config=./hosts/izels-pi4/configuration.nix
```
