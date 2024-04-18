return {
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
          i = {
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
          },
        },
      },
    }
  end,
}
