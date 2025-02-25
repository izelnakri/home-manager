-- TODO: Add https://github.com/nvim-telescope/telescope-media-files.nvim AND OPEN.
-- Maybe: https://github.com/tamago324/telescope-openbrowser.nvim
-- Maybe: https://github.com/nvim-neorg/neorg-telescope
return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader><leader>",
        LazyVim.telescope("files", { cwd = false }),
        desc = "Find Files on project",
      },
      {
        "<leader>fp",
        function()
          require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root })
        end,
        desc = "Find Plugin File",
      },
      {
        "<leader>snn",
        function()
          vim.cmd.Telescope("notify")
        end,
        desc = "Search Notification history",
      },
    },
    opts = function()
      local actions = require("telescope.actions")

      return {
        defaults = {
          sorting_strategy = "ascending",
          layout_config = {
            prompt_position = "top",
          },
          mappings = {
            -- move_selection_better / move_selection_worse / results_scrolling_up / results_scrolling_down
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-d>"] = actions.results_scrolling_down,
              ["<C-u>"] = actions.results_scrolling_up,
              -- ["<C-gg>"] = actions.move_to_top,
              -- ["<C-G>"] = actions.move_to_bottom,
            },
            n = {
              ["<C-d>"] = actions.results_scrolling_down,
              ["<C-u>"] = actions.results_scrolling_up,
            },
          },
        },
      }
    end,
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  },
}
