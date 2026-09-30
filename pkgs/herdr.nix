# herdr: terminal multiplexer for coding agents (Rust, embeds Ghostty's libghostty-vt terminal core).
# nixpkgs-unstable ships 0.9.0 (26.05 doesn't have it at all). 0.9.2/0.9.3 bring multiple prefix keys,
# native Kitty graphics passthrough, large CPU fixes & the Escape/Alt key fixes, so bump it here.
# Delete this file & use `unstable.herdr` directly once nixpkgs-unstable reaches >= 0.9.3.
# To bump: change `version`, set the 3 hashes (src, cargoDeps, zigDeps) to lib.fakeHash, build, and paste the hashes nix reports.
{ lib, unstable, fetchFromGitHub }:

unstable.herdr.overrideAttrs (finalAttrs: prev: {
  version = "0.9.3";

  src = fetchFromGitHub {
    owner = "herdrdev";
    repo = "herdr";
    tag = "v${finalAttrs.version}";
    hash = "sha256-uu452Xe23pSvFk7w7fKPjiaqY5QenUIljao2SFAxpc0=";
  };

  # NOTE: overrideAttrs can't just set `cargoHash`: buildRustPackage already turned it into `cargoDeps`.
  cargoDeps = unstable.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname version src;
    hash = "sha256-+gTWtEheyuI59yf2PqRbcbcFIW+/cYb7zZ2mPv2VN0Y=";
  };

  # 0.9.2+ vendors a libghostty-vt that requires Zig 0.16 (nixpkgs' 0.9.0 recipe uses zig_0_15):
  nativeBuildInputs = [ unstable.zig_0_16.hook ]
    ++ lib.filter (p: (p.name or "") != unstable.zig_0_15.hook.name) prev.nativeBuildInputs;

  zigDeps = unstable.zig_0_16.fetchDeps {
    inherit (finalAttrs) pname version;
    src = "${finalAttrs.src}/vendor/libghostty-vt";
    fetchAll = true;
    hash = "sha256-Cy0DdSvce+fhOFIfxHMQGF2b2j16UkS27UpGbfC42XI=";
  };
})
