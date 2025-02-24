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
