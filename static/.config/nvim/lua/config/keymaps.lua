-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Replace on highlighted areas:
vim.cmd("nnoremap <Leader>r :%s///gc<left><left><left>")

-- keymap for C-j C-k cmp and others(?), pager for documentation etc

-- map <Leader>gb :Git blame<CR>
-- map <Leader>gs :Gstatus<CR>
-- map <Leader>gl :0Glog<CR>
-- map <Leader>gp :Glog<CR>
-- map <Leader>mg :Magit<CR>
-- map <Leader>q :q<CR>

-- map <Leader>r :reg<CR>

-- nnoremap <Leader>s :%s//gc<left><left><left>
-- nnoremap <Leader>/ :%s///gn<CR>
-- nnoremap ln :lnext<CR>
-- nnoremap lp :lprevious<CR>
-- nnoremap lr :lrewind<CR>
-- nnoremap lc :lclose<CR>
-- nnoremap <leader>lf :ALEFix<CR>

-- TODO: Neoclide Tab S-Tab Completion, does this even work?!?
-- imap <C-j> <Tab>
-- imap <C-k> <S-Tab>
-- inoremap <C-j> <ESC>:m .+1<CR>==gi
-- inoremap <C-k> <ESC>:m .-2<CR>==gi

-- Ale:
-- nnoremap ln :lnext<CR>
-- nnoremap lp :lprevious<CR>
-- nnoremap lr :lrewind<CR>
-- nnoremap lc :lclose<CR>
-- nnoremap <leader>lf :ALEFix<CR>

-- Gfigutive stuff:
-- map <Leader>gb :Git blame<CR>
-- map <Leader>gs :Gstatus<CR>
-- map <Leader>gl :0Glog<CR>
-- map <Leader>gp :Glog<CR>
-- map <Leader>mg :Magit<CR>,
-- map <Leader>q :q<CR>

-- buffers, registers, Rg, Files

-- LSP keybinds: definition, jumpToDefinition(?), type definition, implementation, references, ShowDocumentation(on hover or not)

-- Learn Keymaps for: Surround, Project file/replace,
