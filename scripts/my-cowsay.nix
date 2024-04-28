{ pkgs }:
pkgs.writeShellScriptBin "my-cowsay" ''
  #!/usr/bin/env bash
  echo $1 | ${pkgs.cowsay}/bin/cowsay | ${pkgs.lolcat}/bin/lolcat
''
