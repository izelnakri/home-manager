-- # Global options
--
-- NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.have_nerd_font = true
vim.g.netrw_banner = 0

-- :let &fillchars = 'eob: ' -- removes left ~

-- vim.g.verbose = 16
-- vim.g.verbosefile = "~/.cache/nvim/messages.log"

-- vim.cmd("redir! @z")

vim.p = function(...)
  vim.print(vim.inspect(...))
end

-- NOTE: read about tabstop(indent) & shiftwidth
