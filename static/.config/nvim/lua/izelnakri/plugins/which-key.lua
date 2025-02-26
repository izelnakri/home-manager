return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      -- vim.o.timeout = true
      -- vim.o.timeoutlen = 500
    end,
    config = function()
      require("which-key").setup()
      require("which-key").add({
        { "<leader>c", group = "[C]ode" },
        { "<leader>d", group = "[D]ocument" },
        { "<leader>r", group = "[R]ename" },
        { "<leader>s", group = "[S]earch" },
        { "<leader>w", group = "[W]orkspace" },
        { "<leader>t", group = "[T]oggle" },
        { "<leader>h", group = "Git [H]unk", mode = { "n", "v" } }, -- NOTE: Check if this is working
      })
    end,
  },
}

-- NOTE: LazyVim config:

-- {
--   "folke/which-key.nvim",
--   event = "VeryLazy",
--   opts = {
--     plugins = { spelling = true },
--     defaults = {
--       mode = { "n", "v" },
--       ["g"] = { name = "+goto" },
--       ["gs"] = { name = "+surround" },
--       ["z"] = { name = "+fold" },
--       ["]"] = { name = "+next" },
--       ["["] = { name = "+prev" },
--       ["<leader><tab>"] = { name = "+tabs" },
--       ["<leader>b"] = { name = "+buffer" },
--       ["<leader>c"] = { name = "+code" },
--       ["<leader>f"] = { name = "+file/find" },
--       ["<leader>g"] = { name = "+git" },
--       ["<leader>gh"] = { name = "+hunks" },
--       ["<leader>q"] = { name = "+quit/session" },
--       ["<leader>s"] = { name = "+search" },
--       ["<leader>u"] = { name = "+ui" },
--       ["<leader>w"] = { name = "+windows" },
--       ["<leader>x"] = { name = "+diagnostics/quickfix" },
--     },
--   },
--   config = function(_, opts)
--     local wk = require("which-key")
--     wk.setup(opts)
--     wk.register(opts.defaults)
--   end,
-- },
--
