-- bootstrap lazy.nvim, LazyVim and your plugins
vim.cmd("source ~/.config/nvim/snippets.vim")

function R(name)
  require("plenary.reload").reload_module(name)
end

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

require("config.lazy")
