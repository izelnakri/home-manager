{ pkgs, lib }:
# On NixOS the OpenGL/Vulkan drivers live in the store (hardware.graphics.enable), so a
# nixGL wrapper is a no-op indirection — apps find their GL just by running directly.
# nixGL is only needed on generic-Linux / non-NixOS hosts where the driver isn't in Nix.
#
# The old wrapper also made the WHOLE flake impure: pkgs.nixgl.auto.nixGLDefault pulls in
# `time = builtins.currentTime` (nixGL.nix:224) to force GPU re-detection, which required
# `nixos-rebuild --impure` and defeated Nix's flake eval cache (~30s every rebuild).
#
# So on NixOS wrapNixGL is the identity function. All `(wrapNixGL pkg)` call sites stay
# intact, so flipping back to the real wrapper (for a generic-Linux host) is a one-liner.
pkg: pkg

# --- Real nixGL wrapper (re-enable for a non-NixOS host; also re-add nixGL.overlay in
# --- flake.nix and, ideally, pin nixGLIntel below instead of the impure `auto` variant):
#
# let
#   bins = "${pkg}/bin";
#   # `auto` is impure (builtins.currentTime); on a fixed-GPU box prefer a pinned variant:
#   #   nixGL = if pkgs.stdenv.hostPlatform.isx86_64
#   #           then pkgs.nixgl.nixGLIntel
#   #           else pkgs.nixgl.auto.nixGLDefault;
#   nixGL = pkgs.nixgl.auto.nixGLDefault;
# in pkgs.buildEnv {
#   name = "nixGL-${pkg.name}";
#   paths =
#     [ pkg ] ++
#     (map
#       (bin: lib.hiPrio (
#         pkgs.writeShellScriptBin bin ''
#           exec -a "$0" "${nixGL}/bin/nixGL" "${bins}/${bin}" "$@"
#         ''
#       ))
#       (builtins.attrNames (builtins.readDir bins)));
# }
