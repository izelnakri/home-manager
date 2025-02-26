return {
  {
    "folke/todo-comments.nvim", -- Highlight todo, notes, etc in comments
    event = "VimEnter",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = false },
  },
}

-- NOTE: From LazyVim config:
-- {
--   "folke/todo-comments.nvim",
--   cmd = { "TodoTrouble", "TodoTelescope" },
--   event = "LazyFile",
--   config = true,
--   -- stylua: ignore
--   keys = {
--     { "]t", function() require("todo-comments").jump_next() end, desc = "Next Todo Comment" },
--     { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous Todo Comment" },
--     { "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
--     { "<leader>xT", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
--     { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Todo" },
--     { "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme" },
--   },
-- },
