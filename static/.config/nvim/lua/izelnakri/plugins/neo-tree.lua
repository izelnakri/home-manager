-- TODO: Customize from scratch
-- NOTE: make cwd change automatically without asking on bufenter(?) / windowenter(?)
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    init = function()
      if vim.fn.argc(-1) == 1 then
        local stat = vim.uv.fs_stat(vim.fn.argv(0))
        if stat and stat.type == "directory" then
          require("neo-tree")
        end
      end
    end,
    keys = {
      { "\\", ":Neotree reveal<CR>", { desc = "NeoTree reveal" } },
      -- {
      --   "<leader>R",
      --   function()
      --     vim.cmd([[Neotree reveal reveal_force_cwd=true]])
      --   end,
      --   desc = "Reveal file & project tree in NeoTree",
      -- },
    },
    opts = {
      enable_git_status = false,
      enable_diagnostics = false,
      window = {
        mapping = {
          ["<C-b>"] = "none",
          ["<C-f>"] = "none",
          ["<C-k>"] = { "scroll_preview", config = { direction = 10 } },
          ["<C-j>"] = { "scroll_preview", config = { direction = -10 } },
        },
      },
      -- window -- remove it here the <C-b>, <C-f>
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_hidden = false,
          -- hide_by_name = { "node_modules" },
        },
        window = {
          position = "left",
          -- mapping_options = {
          --   noremap = true,
          --   nowait = false,
          -- },
          mappings = {
            ["\\"] = "close_window",
            ["<C-b>"] = "none",
            ["<C-f>"] = "none",
            ["<C-k>"] = { "scroll_preview", config = { direction = 10 } },
            ["<C-j>"] = { "scroll_preview", config = { direction = -10 } },
          },
        },
      },
    },
  },
}
