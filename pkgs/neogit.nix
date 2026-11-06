# `neogit [dir]`: neogit as a standalone git UI, the way `lazygit` starts: nvim opens straight into the
# status screen of the repo (full window) and `q` there quits nvim. Runs your nvim config
# (static/.config/nvim), so staging, diffview (`d`), telescope pickers and your keymaps all work.
{ writeShellApplication }:

writeShellApplication {
  name = "neogit";
  text = ''
    if [ -n "''${1:-}" ]; then cd "$1"; fi
    # g:neogit_standalone tells plugins/neogit.lua to make `q` on the status screen quit nvim.
    exec nvim --cmd 'let g:neogit_standalone = 1' +'Neogit kind=replace'
  '';
}
