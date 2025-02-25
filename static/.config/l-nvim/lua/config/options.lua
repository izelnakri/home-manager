-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.relativenumber = false
vim.opt.showcmd = true -- Enable showing the command line in the status bar
vim.opt.colorcolumn = "120"

vim.g.vimwiki_list = { { path = "~/vimwiki/", syntax = "markdown", ext = "md" } }

-- let g:vimwiki_ext2syntax = {'.md': 'markdown', '.markdown': 'markdown', '.mdown': 'markdown'}
--
-- Makes vimwiki markdown links as [text](text.md) instead of [text](text)
-- let g:vimwiki_markdown_link_ext = 1
--
-- let g:vimwiki_markup_syntax = 'markdown'
-- let g:markdown_folding = 1

vim.g.vimwiki_global_ext = 0
-- TODO: check fix on save for linter errors, also show on save linter errors down panel
--
-- TODO: RESEARCH: expandtab, shiftwidth, tabstop
