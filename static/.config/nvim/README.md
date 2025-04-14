# My current neovim configuration

This configuration is already getting tuned & built with nix.

In lua in order to dynamically load some lua modules:

```lua
# in script.lua:

vim.o.runtimepath = vim.o.runtimepath
  .. ",~/Github/async.nvim"
  .. [[
,/home/izelnakri/.config/nvim,/home/izelnakri/.local/share/nvim/site,/home/izelnakri/.local/share/nvim/lazy/lazy.nvim,/home/izelnakri/.local/share/nvim/lazy/nvim-autopairs,/home/izelnakri/.local/share/nvim/lazy/persistence.nvim,/home/izelnak
ri/.local/share/nvim/lazy/nvim-lint,/home/izelnakri/.local/share/nvim/lazy/flash.nvim,/home/izelnakri/.local/share/nvim/lazy/which-key.nvim,/home/izelnakri/.local/share/nvim/lazy/bufferline.nvim,/home/izelnakri/.local/share/nvim/lazy/todo-c
omments.nvim,/home/izelnakri/.local/share/nvim/lazy/nvim-cmp,/home/izelnakri/.local/share/nvim/lazy/yanky.nvim,/home/izelnakri/.local/share/nvim/lazy/nvim-notify,/home/izelnakri/.local/share/nvim/lazy/vim-sleuth,/home/izelnakri/.local/share
/nvim/lazy/Comment.nvim,/home/izelnakri/Github/callback.nvim,/home/izelnakri/.local/share/nvim/lazy/nvim-dap-ui,/home/izelnakri/.local/share/nvim/lazy/nvim-dap,/home/izelnakri/.local/share/nvim/lazy/mason-nvim-dap.nvim,/home/izelnakri/.loca
l/share/nvim/lazy/neodev.nvim,/home/izelnakri/.local/share/nvim/lazy/fidget.nvim,/home/izelnakri/.local/share/nvim/lazy/mason-tool-installer.nvim,/home/izelnakri/.local/share/nvim/lazy/mason-lspconfig.nvim,/home/izelnakri/.local/share/nvim/
lazy/mason.nvim,/home/izelnakri/.local/share/nvim/lazy/nvim-lspconfig,/home/izelnakri/.local/share/nvim/lazy/vim-eunuch,/home/izelnakri/.local/share/nvim/lazy/indent-blankline.nvim,/home/izelnakri/.local/share/nvim/lazy/nvim-colorizer.lua,/
home/izelnakri/.local/share/nvim/lazy/conform.nvim,/home/izelnakri/.local/share/nvim/lazy/gp.nvim,/home/izelnakri/.local/share/nvim/lazy/gitsigns.nvim,/home/izelnakri/.local/share/nvim/lazy/nvim-nio,/home/izelnakri/.local/share/nvim/lazy/ne
otest-plenary,/home/izelnakri/.local/share/nvim/lazy/neotest-vitest,/home/izelnakri/.local/share/nvim/lazy/FixCursorHold.nvim,/home/izelnakri/.local/share/nvim/lazy/neotest,/home/izelnakri/.local/share/nvim/lazy/vim-dadbod-ui,/home/izelnakr
i/.local/share/nvim/lazy/vim-dadbod-completion,/home/izelnakri/.local/share/nvim/lazy/vim-dadbod,/home/izelnakri/.local/share/nvim/lazy/nvim-treesitter,/home/izelnakri/.local/share/nvim/lazy/telescope-fzf-native.nvim,/home/izelnakri/.local/
share/nvim/lazy/telescope.nvim,/home/izelnakri/.local/share/nvim/lazy/diffview.nvim,/home/izelnakri/.local/share/nvim/lazy/neogit,/home/izelnakri/.local/share/nvim/lazy/mini.nvim,/home/izelnakri/Github/parrots-of-paradise,/home/izelnakri/.l
ocal/share/nvim/lazy/nui.nvim,/home/izelnakri/.local/share/nvim/lazy/nvim-web-devicons,/home/izelnakri/.local/share/nvim/lazy/plenary.nvim,/home/izelnakri/.local/share/nvim/lazy/neo-tree.nvim,/nix/store/pyq71ibs4rz892fhib8x9dyqm0lvr5c8-neov
im-unwrapped-0.10.0/share/nvim/runtime,/nix/store/pyq71ibs4rz892fhib8x9dyqm0lvr5c8-neovim-unwrapped-0.10.0/share/nvim/runtime/pack/dist/opt/matchit,/nix/store/pyq71ibs4rz892fhib8x9dyqm0lvr5c8-neovim-unwrapped-0.10.0/lib/nvim,/home/izelnakri
/.local/share/nvim/lazy/indent-blankline.nvim/after,/home/izelnakri/.local/share/nvim/lazy/vim-dadbod-completion/after,/home/izelnakri/.config/nvim/after,/home/izelnakri/.local/state/nvim/lazy/readme
]]


```

Then run it:

```
nvim -l ./script.lua
```


