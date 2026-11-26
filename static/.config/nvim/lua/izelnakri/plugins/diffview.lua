-- Git review cockpit under <leader>g (status/commit/branch keys are in neogit.lua):
--   tuicr (GitHub-style review → Claude Code / GitHub):  gr changes, gR branch vs origin's default, gp a PR, gf this file,
--     gS branch review → its PR (`:submit` only works on PRs)
--     one review at a time in a float that only hides: <leader>gr toggles it; inside, `e` jumps here, <C-g> neogit
--   diffview (real nvim buffers: LSP, search, treesitter): gd changes, gD branch vs default, gh file history, gH repo history
return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    {
      "<leader>gr",
      function()
        require("izelnakri.tuicr").open({})
      end,
      desc = "[R]eview changes in tuicr / toggle open review",
    },
    {
      "<leader>gR",
      function()
        local tuicr = require("izelnakri.tuicr")
        tuicr.open({ tuicr.default_branch() })
      end,
      desc = "[R]eview branch vs default in tuicr",
    },
    {
      "<leader>gp",
      function()
        require("izelnakri.tuicr").pick_pr()
      end,
      desc = "Review GitHub [P]R in tuicr",
    },
    {
      "<leader>gS",
      function()
        require("izelnakri.tuicr").to_pr()
      end,
      desc = "[S]ubmit: move this branch review's comments to its PR",
    },
    {
      "<leader>gf",
      function()
        require("izelnakri.tuicr").review_file()
      end,
      desc = "Review this [F]ile in tuicr",
    },

    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "[D]iffview uncommitted changes" },
    {
      "<leader>gD",
      function()
        vim.cmd.DiffviewOpen(require("izelnakri.tuicr").default_branch() .. "...HEAD")
      end,
      desc = "[D]iffview branch vs default (PR diff)",
    },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File [h]istory" },
    { "<leader>gh", ":DiffviewFileHistory<cr>", mode = "v", desc = "Selection [h]istory" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Repo [H]istory" },
  },
  opts = function()
    local actions = require("diffview.actions")
    local close = { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } }

    return {
      enhanced_diff_hl = true, -- word-level highlights, deletions as DiffDelete instead of DiffAdd fillers
      show_help_hints = true,
      view = {
        default = { layout = "diff2_horizontal", winbar_info = true },
        merge_tool = { layout = "diff3_mixed", disable_diagnostics = true, winbar_info = true },
        file_history = { layout = "diff2_horizontal", winbar_info = true },
      },
      file_panel = {
        listing_style = "tree",
        tree_options = { flatten_dirs = true, folder_statuses = "only_folded" },
        win_config = { position = "left", width = 35 },
      },
      file_history_panel = {
        log_options = {
          git = { single_file = { diff_merges = "combined" }, multi_file = { diff_merges = "first-parent" } },
        },
        win_config = { position = "bottom", height = 16 },
      },
      keymaps = {
        -- Same file/hunk motions as tuicr ({ } files, [ ] hunks are vim's own ]c/[c here) & neogit:
        view = {
          close,
          { "n", "}", actions.select_next_entry, { desc = "Next file" } },
          { "n", "{", actions.select_prev_entry, { desc = "Previous file" } },
          { "n", "<leader>e", actions.toggle_files, { desc = "Toggle file panel" } },
        },
        file_panel = {
          close,
          { "n", "}", actions.select_next_entry, { desc = "Next file" } },
          { "n", "{", actions.select_prev_entry, { desc = "Previous file" } },
          { "n", "<leader>e", actions.toggle_files, { desc = "Toggle file panel" } },
        },
        file_history_panel = { close },
      },
    }
  end,
}
