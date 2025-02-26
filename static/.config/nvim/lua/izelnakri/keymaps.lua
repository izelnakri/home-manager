-- # Basic keymaps
--
-- See `:help vim.keymap.set()`
--
-- :vnew|read !ls
--
--
-- From LazyVim = <l-c> Code <l-d> Debug <l-s> Search/Find <l-u> UI <l-x>Quickfix <l-w>Window funcs <l-b>Buffer stuff

vim.keymap.set("t", "<esc>", "<c-\\><c-n>") -- Make exit work for terminals
vim.cmd("nnoremap <leader>r :%s///gc<left><left><left>")
vim.cmd("nnoremap <leader><leader> :lua<space>")

-- TODO: Add a keymap for :lua <leader><leader>?

-------- RECONSIDER -----------------------

-- TODO: evtest should output this on 15(xremap), then I can map it(?) | showkey -a | decimal octal hex
-- To map a character by its decimal, octal or hexadecimal number the <Char>
-- construct can be used:
-- 	<Char-123>	character 123
-- 	<Char-033>	character 27
-- 	<Char-0x7f>	character 127
-- 	<S-Char-114>    character 114 ('r') shifted ('R')
--
-- 	<C-Char-(Decimal)
-- This is useful to specify a (multibyte) character in a 'keymap' file.
-- Upper and lowercase differences are ignored.

-- TODO : Check primeagen keymaps REALLY WELL & TJ Devries

local map = vim.keymap.set

map({ "x", "n", "s" }, "<leader>qq", "<cmd>qa<cr>", { nowait = true, desc = "Quit All" })
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- TODO: RE-ENABLE
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- TODO: Make <C-s> save file
-- TODO: Only TJ and Primeagen keymaps added NOT LazyVim or Mine!

-- TODO: Diagnostic keymaps, move them to trouble
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
-- vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- NOTE: Check if this actually works
-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
-- TODO: RE-ENABLE:
-- vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

--  Use CTRL+<hjkl> to switch between windows, see `:help wincmd` for a list of all window commands:
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- NOTE: Devries keymaps:
-- local set = vim.keymap.set
-- local k = vim.keycode
--
-- -- Basic movement keybinds, these make navigating splits easy for me
-- set("n", "<c-j>", "<c-w><c-j>")
-- set("n", "<c-k>", "<c-w><c-k>")
-- set("n", "<c-l>", "<c-w><c-l>")
-- set("n", "<c-h>", "<c-w><c-h>")
--
-- set("n", "<leader>x", "<cmd>.lua<CR>", { desc = "Execute the current line" })
-- set("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "Execute the current file" })
--
-- -- Toggle hlsearch if it's on, otherwise just do "enter"
-- set("n", "<CR>", function()
--   ---@diagnostic disable-next-line: undefined-field
--   if vim.v.hlsearch == 1 then
--     vim.cmd.nohl()
--     return ""
--   else
--     return k "<CR>"
--   end
-- end, { expr = true })
--
-- -- Normally these are not good mappings, but I have left/right on my thumb
-- -- cluster, so navigating tabs is quite easy this way.
-- set("n", "<left>", "gT")
-- set("n", "<right>", "gt")
--
-- -- There are builtin keymaps for this now, but I like that it shows
-- -- the float when I navigate to the error - so I override them.
-- set("n", "]d", vim.diagnostic.goto_next)
-- set("n", "[d", vim.diagnostic.goto_prev)
--
-- -- These mappings control the size of splits (height/width)
-- set("n", "<M-,>", "<c-w>5<")
-- set("n", "<M-.>", "<c-w>5>")
-- set("n", "<M-t>", "<C-W>+")
-- set("n", "<M-s>", "<C-W>-")
--
-- set("n", "<M-j>", function()
--   if vim.opt.diff:get() then
--     vim.cmd [[normal! ]c]]
--   else
--     vim.cmd [[m .+1<CR>==]]
--   end
-- end)
--
-- set("n", "<M-k>", function()
--   if vim.opt.diff:get() then
--     vim.cmd [[normal! [c]]
--   else
--     vim.cmd [[m .-2<CR>==]]
--   end
-- end)
--
-- set("n", "<space>tt", function()
--   vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = 0 }, { bufnr = 0 })
-- end)

-- TODO: Check Primeagen keymaps
--
--vim.g.mapleader = " "
-- vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
--
-- vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
-- vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
--
-- vim.keymap.set("n", "J", "mzJ`z")
-- vim.keymap.set("n", "<C-d>", "<C-d>zz")
-- vim.keymap.set("n", "<C-u>", "<C-u>zz")
-- vim.keymap.set("n", "n", "nzzzv")
-- vim.keymap.set("n", "N", "Nzzzv")
--
-- vim.keymap.set("n", "<leader>vwm", function()
--     require("vim-with-me").StartVimWithMe()
-- end)
-- vim.keymap.set("n", "<leader>svwm", function()
--     require("vim-with-me").StopVimWithMe()
-- end)
--
-- -- greatest remap ever
-- vim.keymap.set("x", "<leader>p", [["_dP]])
--
-- -- next greatest remap ever : asbjornHaland
-- vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
-- vim.keymap.set("n", "<leader>Y", [["+Y]])
--
-- vim.keymap.set({"n", "v"}, "<leader>d", [["_d]])
--
-- -- This is going to get me cancelled
-- vim.keymap.set("i", "<C-c>", "<Esc>")
--
-- vim.keymap.set("n", "Q", "<nop>")
-- vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
-- vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
--
-- vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
-- vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
-- vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
-- vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")
--
-- vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
-- vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })
--
-- vim.keymap.set(
--     "n",
--     "<leader>ee",
--     "oif err != nil {<CR>}<Esc>Oreturn err<Esc>"
-- )
--
-- vim.keymap.set("n", "<leader>vpp", "<cmd>e ~/.dotfiles/nvim/.config/nvim/lua/theprimeagen/packer.lua<CR>");
-- vim.keymap.set("n", "<leader>mr", "<cmd>CellularAutomaton make_it_rain<CR>");
--
-- vim.keymap.set("n", "<leader><leader>", function()
--     vim.cmd("so")
-- end)

-- TODO: Check this guys keymaps, treesitter: https://github.com/omerxx/dotfiles/tree/master/nvim .
-- Also his dadbod video: https://www.youtube.com/watch?v=NhTPVXP8n7w

-- <C-k> will run the documentation plugin/magic
-- According to chris@machine make <C-\> ToggleTerm
