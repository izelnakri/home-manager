# `cr`: tuicr review → running Claude Code session (tmux pane or herdr agent). Script & usage: ./cr.sh
# herdr is optional at runtime (used only when it's on PATH), so it isn't a runtimeInput.
# Inside nvim's terminal, `cr` puts ./nvim-shim.sh (named `nvim`) first on PATH so tuicr's `e` jumps the
# parent nvim to the line instead of nesting an editor (see static/.config/nvim/lua/izelnakri/tuicr.lua).
{ writeShellApplication, tuicr, git, tmux, jq, fzf, wl-clipboard, gawk, gnugrep, gnused, coreutils }:

let
  nvimShim = writeShellApplication {
    name = "nvim";
    text = builtins.readFile ./nvim-shim.sh;
  };
in
writeShellApplication {
  name = "cr";
  runtimeInputs = [ tuicr git tmux jq fzf wl-clipboard gawk gnugrep gnused coreutils ];
  text = builtins.replaceStrings [ "@nvimShim@" ] [ "${nvimShim}/bin" ] (builtins.readFile ./cr.sh);
  meta.mainProgram = "cr";
}
