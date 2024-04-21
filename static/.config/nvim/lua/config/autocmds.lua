-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.cmd("command! -nargs=0 Name execute ':!echo % | wl-copy'")
vim.cmd("command! RmSwp execute '!rm /var/tmp/*.swp'")
vim.cmd("command! Errors execute ':Telescope notify'")

-- NOTE: This makes LSP activated for the buffer:
local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup("activate_lsp"),
  callback = function(event)
    vim.cmd([[filetype detect]])
  end,
})

-- TODO: Make rustacean open cargo --doc open $doc open that thing
-- file:///home/izelnakri/Github/poem-tutorial/target/doc/poem_tutorial/struct.CatApi.html#method.index

-- TODO: Make a function that opens in offline-mode browser(devdocs) whats on hover (cargo doc --open, (elixir version), (deno docs version))
-- :InspectTree shows TreeSitter tree

-- " Compile rmarkdown
-- autocmd FileType rmd map <F5> :!echo<space>"require(rmarkdown);<space>render('<c-r>%')"<space>\|<space>R<space>--vanilla<enter>

-- TODO: Run tests, Expand macros, renderDiagnostics(?), joinLines, view crate graph
