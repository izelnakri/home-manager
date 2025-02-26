-- TODO: conform.lua, nvim-lint.lua, trouble.nvim

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- NOTE: opts ={} trrigger setup() call
  {
    dir = "~/Github/parrots-of-paradise",
    priority = 1000,
    opts = {},
  },
  "numToStr/Comment.nvim",
  -- tanvirtin/vgit.nvim

  -- Maybe needed alongside:
  -- {
  --   "JoosepAlviste/nvim-ts-context-commentstring",
  --   lazy = true,
  --   opts = {
  --     enable_autocmd = false,
  --   },
  -- },
  "rcarriga/nvim-notify",
  "tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically
  "tpope/vim-eunuch", -- SudoWrite & friends
  {
    -- "izelnakri/callback.nvim",
    dir = "~/Github/async.nvim",
    config = function()
      vim.print("CALLLING CONFIG")
      -- async_it = require("async.test").async_it
      Callback = require("callback")
      Promise = require("promise")
      Timers = require("timers")
      await = Promise.await
      --
      --   -- Callback = require("callback")
      --   -- Callback.run = function(...)
      --   --   function(params, callback)
      --   --   local func = Callback.build_iteratee(...)
      --   --
      --   --   return func(function(err, result)
      --   --     return function(err, result)
      --   --
      --   --     end
      --   --   end)
      --   -- end
    end,
  },

  -- NOTE: Automatically add closing tags for HTML and JSX
  -- {
  --   "windwp/nvim-ts-autotag",
  --   event = "LazyFile",
  --   opts = {},
  -- },
  {
    "lukas-reineke/indent-blankline.nvim", -- Add indentation guides even on blank lines
    main = "ibl",
    -- event = "LazyFile",
    -- opts = {
    --   indent = {
    --     char = "│",
    --     tab_char = "│",
    --   },
    --   scope = { enabled = false },
    --   exclude = {
    --     filetypes = {
    --       "help",
    --       "alpha",
    --       "dashboard",
    --       "neo-tree",
    --       "Trouble",
    --       "trouble",
    --       "lazy",
    --       "mason",
    --       "notify",
    --       "toggleterm",
    --       "lazyterm",
    --     },
    --   },
    -- },
  },
  { import = "izelnakri.plugins" },
  -- NOTE: neogit, CodeSnap, lspkind(?), vim-pencil(?), sg.nvim(?), obsidian.nvim(?), neorg, vim-obsession(?), nvim-tree(?)
  -- NOTE: vim-dadbod, git-worktree.nvim(?), noice, vim-surround, codi(?), colorizer, "rhysd/devdocs.vim"(?), "stevearc/dressing.nvim"(?)
  -- install = {
  --   colorscheme = { "parrots-of-paradise" },
  -- },
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🗝",
      plugin = "🔌",
      runtime = "💻",
      require = "🌙",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
  },
  -- change_detection = { notify = false }
})

-- https://github.com/moyiz/git-dev.nvim
