-- # Options
-- For more options, you can see `:help vim.opt`, `:help option-list`

vim.opt.number = true -- Make line numbers default
vim.opt.mouse = "a"
vim.opt.showmode = false -- Don't show the mode, since it's already in the status line
vim.opt.clipboard = "unnamedplus" --  See `:help 'clipboard'`
vim.opt.breakindent = true
vim.opt.undofile = true -- Save undo history

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term:
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.signcolumn = "yes" -- Keep signcolumn on by default

vim.opt.updatetime = 50 -- Decrease update time

vim.opt.timeoutlen = 300 -- Displays which-key popup sooner

-- Configure how new splits should be opened:
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor:
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

vim.opt.inccommand = "split" -- Preview substitutions live, as you type!

vim.opt.cursorline = true -- Show which line your cursor is on

vim.opt.scrolloff = 10 -- Minimal number of screen lines to keep above and below the cursor.

vim.opt.hlsearch = true -- Set highlight on search, but clear on pressing <Esc> in normal mode

vim.lsp.inlay_hint.enable()

vim.opt.guicursor = ""

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.undofile = true
vim.opt.undolevels = 10000

vim.opt.colorcolumn = "120"

-- Don't have `o` to add a comment:
vim.opt.formatoptions:remove("o")

-- NOTE: Maybe adjust these in future:
-- vim.opt.swapfile = false
-- vim.opt.backup = false
-- vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
-- vim.opt.isfname:append("@-@")
