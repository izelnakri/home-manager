return {
  {
    "neo-tree.nvim",
    keys = {
      {
        "<leader>R",
        function()
          vim.cmd([[Neotree reveal reveal_force_cwd=true]])
        end,
        desc = "Reveal file & project tree in NeoTree",
      },
    },
    opts = {
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_hidden = false,
          -- hide_by_name = { "node_modules" },
        },
      },
    },
  },
}
