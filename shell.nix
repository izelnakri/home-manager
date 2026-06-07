# NOTE: Delete this later
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.meson
    pkgs.ninja
    pkgs.pkg-config
    pkgs.gnutls
  ];

  shellHook = ''
    echo "You're now in a dev shell with meson, ninja, and gnutls"
  '';
}
