-- # Basic Autocommands
--
--  See `:help lua-guide-autocommands`, `:help autocmd-events`

local set = vim.opt_local

-- Highlight when yanking (copying) text. Try it with `yap` in normal mode. See `:help vim.highlight.on_yank()`:
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),

  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("custom-term-open", {}),
  callback = function()
    set.number = false
    set.relativenumber = false
    set.scrolloff = 0

    vim.bo.filetype = "terminal"
  end,
})

-- TODO: VERY/MOST IMPORTANT: how can I query nvim windows

-- TODO: make it immediately in insert mode. However not if there is test or other results. Read docs
-- TODO: open it on the right side if its not taken, otherwise open it on the floating window(read lazy.nvim)
--   vim.cmd.new() -- opens new window
--   vim.cmd.wincmd "J" -- moves it to bottom
--   vim.api.nvim_win_set_height(0, 12) -- sets the height
--   vim.wo.winfixheight = true -- this pins a window
--   vim.cmd.term()

-- TODO: Investigate how I can grab the stdout and stderr of the terminal last command and exit.
