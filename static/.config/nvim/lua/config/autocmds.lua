-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.cmd("command! -nargs=0 Name execute ':!echo % | wl-copy'")
vim.cmd("command! RmSwp execute '!rm /var/tmp/*.swp'")
vim.cmd("command! Colors execute 'so $VIMRUNTIME/syntax/hitest.vim'")
vim.cmd("command! Errors execute ':Telescope notify'")

-- :InspectTree shows TreeSitter tree

-- " Compile rmarkdown
-- autocmd FileType rmd map <F5> :!echo<space>"require(rmarkdown);<space>render('<c-r>%')"<space>\|<space>R<space>--vanilla<enter>
