# wifui: keyboard-driven Wi-Fi TUI written in Rust (ratatui), talks to NetworkManager over D-Bus (zbus).
# Not in nixpkgs yet (checked nixos-26.05 & nixpkgs-unstable on 2026-09-30), so it's packaged here.
# To bump: change `version`, set both hashes to lib.fakeHash, build, and paste the hashes nix reports.
{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "wifui";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "sohamw03";
    repo = "wifui";
    tag = version;
    hash = "sha256-XkuPu7V52UxHoNWdvySbJR3J7J9Uh+MQJ3Drg1gitSg=";
  };

  cargoHash = "sha256-jws3QnL7ldi4Qk5PafzwfB6wqmV9tqNGKr5ivOhjuQM=";

  meta = {
    description = "Keyboard-driven TUI for managing Wi-Fi connections through NetworkManager";
    homepage = "https://github.com/sohamw03/wifui";
    license = lib.licenses.mit;
    mainProgram = "wifui";
    platforms = lib.platforms.linux;
  };
}
